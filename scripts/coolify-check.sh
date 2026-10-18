#!/usr/bin/env bash
# Aceptacion del contrato Coolify para hefesto-metricas-umami-supabase.
# Renderiza compose.yaml con valores ficticios no secretos y verifica:
#  - Contrato (sin poderes sobre el host, sin name fijo, sin Traefik local).
#  - Postgres Supabase compartido: DB_NAME y DB_SSLMODE parametrizables.
#
# Salida: 0 si pasa, 1 si falla. Errores a stderr: "servicio: motivo".
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

compose_file="compose.yaml"

# Extrae las variables ${VAR} (sin required, sin default) que aparecen en un archivo.
extract_vars() {
    grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*' "$1" \
        | sed 's/^\${//' \
        | sort -u
}

# Construye un env-file con placeholders ficticios no secretos.
# DB_HOST -> https://ejemplo.invalid; DB_SSLMODE/DB_NAME parametrizables.
build_env() {
    local sslmode="$1" dbname="$2"
    local env_file
    env_file="$(mktemp)"
    local var
    while IFS= read -r var; do
        case "$var" in
            DB_HOST) echo "DB_HOST=https://ejemplo.invalid" >> "$env_file" ;;
            DB_SSLMODE) echo "DB_SSLMODE=${sslmode}" >> "$env_file" ;;
            DB_NAME) echo "DB_NAME=${dbname}" >> "$env_file" ;;
            *) echo "${var}=x1234567890abcdef" >> "$env_file" ;;
        esac
    done < <(extract_vars "$compose_file")
    echo "$env_file"
}

# Renderiza el compose a JSON. Falla con mensaje claro si no resuelve.
render() {
    local env_file="$1" err_file rc
    err_file="$(mktemp -p "${TMPDIR:-/tmp}" coolify-check.err.XXXXXX)"
    docker compose --project-directory "$repo_root" -f "$compose_file" \
            --env-file "$env_file" config --format json 2>"$err_file"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "servicio: compose no rinde con valores ficticios (rc=${rc})" >&2
        rm -f "$err_file"
        return 1
    fi
    rm -f "$err_file"
}

# Verifica puntos 1 y 2 del contrato en servicios sin profiles.
check_contract() {
    local json="$1"
    local failures=()

    # 2.1: name fijo a nivel raiz en el archivo fuente. docker compose siempre
    # rellena el campo en el render desde --project-directory, asi que el
    # contrato se verifica contra el YAML.
    if grep -qE '^name:[[:space:]]*[^$[:space:]]' "$repo_root/$compose_file"; then
        failures+=("raiz:name-fijo")
    fi

    # 2.2: name fijo en redes y volumenes del archivo fuente. Coolify asigna
    # el nombre de proyecto y exige que ${VOLUME_PREFIX} quede con valor por
    # defecto; cualquier red/volumen con name explicito falla el contrato.
    local name_failures
    name_failures="$(awk '
        /^networks:/ { section="networks"; in_item=""; next }
        /^volumes:/ { section="volumes"; in_item=""; next }
        /^[a-zA-Z_]/ { section=""; in_item=""; next }
        section != "" && /^  [A-Za-z0-9_.-]+:$/ {
            in_item = $1; sub(/:$/, "", in_item); next
        }
        section != "" && /^    name:/ {
            value = $0
            sub(/^    name:[[:space:]]*/, "", value)
            gsub(/^["\047]/, "", value)
            gsub(/["\047]$/, "", value)
            if (value !~ /^\$\{/) {
                if (section == "networks") print "red:" in_item ":name-fijo"
                else print "volumen:" in_item ":name-fijo"
            }
            next
        }
    ' "$repo_root/$compose_file")" || {
        echo "servicio: awk fallo chequeando name en redes y volumenes" >&2
        return 1
    }
    if [ -n "$name_failures" ]; then
        while IFS= read -r line; do
            failures+=("$line")
        done <<< "$name_failures"
    fi

    # 2.2: campos prohibidos en servicios sin profiles.
    local bad_fields
    bad_fields="$(printf '%s' "$json" | jq -r '
        .services | to_entries[]
        | select((.value.profiles // []) | length == 0)
        | .key as $svc | .value
        | [
            (if has("ports") and (.ports|length>0) then "ports" else empty end),
            (if has("container_name") then "container_name" else empty end),
            (if (.privileged // false) then "privileged" else empty end),
            (if (.cap_add // []) | length > 0 then "cap_add" else empty end),
            (if (.devices // []) | length > 0 then "devices" else empty end),
            (if (.network_mode // "") == "host" then "network_mode=host" else empty end),
            (if (.pid // "") == "host" then "pid=host" else empty end),
            (if (.ipc // "") == "host" then "ipc=host" else empty end),
            (if (.security_opt // []) | any(. == "unconfined" or (test("=unconfined"))) then "security_opt=unconfined" else empty end)
          ]
        | select(length > 0)
        | "\($svc):\(. | join(","))"
    ')" || {
        echo "servicio: jq fallo chequeando campos prohibidos" >&2
        return 1
    }
    if [ -n "$bad_fields" ]; then
        while IFS= read -r line; do
            failures+=("$line")
        done <<< "$bad_fields"
    fi

    # 2.3: docker.sock en cualquier bind.
    local docker_sock
    docker_sock="$(printf '%s' "$json" | jq -r '
        .services | to_entries[]
        | select((.value.profiles // []) | length == 0)
        | .key as $svc
        | .value.volumes // []
        | .[] | select(.type == "bind")
        | select(.source | test("docker\\.sock"))
        | $svc
    ')" || {
        echo "servicio: jq fallo chequeando docker.sock" >&2
        return 1
    }
    if [ -n "$docker_sock" ]; then
        while IFS= read -r line; do
            failures+=("${line}:bind-docker-sock")
        done <<< "$docker_sock"
    fi

    # 2.4: binds con rutas absolutas fuera del repo. Comparar contra $root + "/"
    # para no dar por bueno un prefijo compartido (p.ej. repo-other).
    local abs_binds
    abs_binds="$(printf '%s' "$json" | jq -r --arg root "$repo_root" '
        .services | to_entries[]
        | select((.value.profiles // []) | length == 0)
        | .key as $svc
        | .value.volumes // []
        | .[] | select(.type == "bind")
        | select(.source | test("^/"))
        | select((.source == $root) or (.source | startswith($root + "/")) | not)
        | $svc
    ')" || {
        echo "servicio: jq fallo chequeando binds absolutos" >&2
        return 1
    }
    if [ -n "$abs_binds" ]; then
        while IFS= read -r line; do
            failures+=("${line}:bind-fuera-repo")
        done <<< "$abs_binds"
    fi

    if [ ${#failures[@]} -gt 0 ]; then
        printf 'servicio: %s\n' "${failures[@]}" >&2
        return 1
    fi
}

# Verifica que el render con DB_SSLMODE=disable y DB_NAME=mvp_prueba los
# contiene en el entorno del servicio web (HEFESTO_DB_NAME/HEFESTO_DB_SSLMODE de
# app) y, ademas, en el preflight (PGDATABASE/PGSSLMODE). Falla si jq no puede
# parsear o si las variables no fluyen.
check_supabase_pg() {
    local json="$1" rc

    printf '%s' "$json" | jq -e '
        [.services | to_entries[]
         | select(.key == "app")
         | .value.environment // {}
         | to_entries[]
         | select(.key == "HEFESTO_DB_NAME" and .value == "mvp_prueba")]
        | length > 0
    ' >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "supabase-pg: DB_NAME=mvp_prueba no llega al servicio app (HEFESTO_DB_NAME)" >&2
        return 1
    fi

    printf '%s' "$json" | jq -e '
        [.services | to_entries[]
         | select(.key == "app")
         | .value.environment // {}
         | to_entries[]
         | select(.key == "HEFESTO_DB_SSLMODE" and .value == "disable")]
        | length > 0
    ' >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "supabase-pg: DB_SSLMODE=disable no llega al servicio app (HEFESTO_DB_SSLMODE)" >&2
        return 1
    fi

    printf '%s' "$json" | jq -e '
        [.services | to_entries[]
         | select(.key == "preflight")
         | .value.environment // {}
         | to_entries[]
         | select(.key == "PGDATABASE" and .value == "mvp_prueba")]
        | length > 0
    ' >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "supabase-pg: DB_NAME=mvp_prueba no llega al entorno del preflight (PGDATABASE)" >&2
        return 1
    fi

    printf '%s' "$json" | jq -e '
        [.services | to_entries[]
         | select(.key == "preflight")
         | .value.environment // {}
         | to_entries[]
         | select(.key == "PGSSLMODE" and .value == "disable")]
        | length > 0
    ' >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "supabase-pg: DB_SSLMODE=disable no llega al entorno del preflight (PGSSLMODE)" >&2
        return 1
    fi
}

main() {
    local exit_code=0 rendered rendered_disable env_default env_disable

    env_default="$(build_env verify-full postgres)"
    if rendered="$(render "$env_default")"; then
        if ! check_contract "$rendered"; then
            exit_code=1
        fi
    else
        exit_code=1
    fi

    env_disable="$(build_env disable mvp_prueba)"
    if rendered_disable="$(render "$env_disable")"; then
        if ! check_supabase_pg "$rendered_disable"; then
            exit_code=1
        fi
    else
        exit_code=1
    fi

    rm -f "$env_default" "$env_disable"
    exit "$exit_code"
}

main "$@"