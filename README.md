# Hefesto Métricas — Umami + Supabase
Kit de despliegue de Umami 3.4.0 para ofrecer analítica web administrada: visitas, páginas, fuentes de tráfico y eventos de interacción. Incluye Compose para Coolify/VPS, arranque privado, rol SQL dedicado, TLS, respaldo/restauración y plantillas de instrumentación.

## Stack y alcance
- Imagen oficial Umami fijada por digest; PostgreSQL 16/17 en proyecto Supabase exclusivo.
- PostgreSQL almacena los datos de aplicación; no se requieren volúmenes de negocio en este kit.
- Login y 2FA propios de Umami; no se integra Supabase Auth, Storage ni Data API.
- Las claves APP_SECRET y TWO_FACTOR_ENCRYPTION_KEY se generan y deben conservarse para recuperar la instancia.
- No se han creado sitios en una cuenta, insertado trackers en Hefesto/KraftDo ni capturado visitas reales.

Empiece por docs/instalacion.md. Requiere Docker, Compose v2, Python 3.11+, HTTPS y acceso a Supabase.

**Estado:** validaciones estáticas y pruebas locales de scripts; no se ejecutó Docker, Prisma ni Supabase. Falta la aceptación en infraestructura real antes de producción.

## Despliegue en Coolify (MVP Hefesto)
Coolify importa el directorio y despliega con build pack Docker Compose; Traefik pone TLS y el dominio. Variables nuevas para uso compartido del Postgres:

| Variable          | Default                                                       | Notas                                                                                                  |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `DB_NAME`         | `postgres`                                                    | Base de datos propia (`mvp_hefesto_metricas_umami_supabase`) en el Postgres compartido de Supabase.     |
| `DB_SSLMODE`      | `verify-full`                                                 | `verify-full` exige `certs/ca.crt`; `disable` la vuelve opcional (red interna Docker, sin TLS).         |
| `PGSSLROOTCERT`   | `/certs/ca.crt`                                               | Solo se usa si `DB_SSLMODE` exige verificación del certificado.                                        |
| `COMPOSE_PROJECT_NAME` | (Coolify lo asigna)                                       | Coolify asigna el nombre del proyecto; no se fija en `compose.yaml`.                                   |

El kit conserva el comportamiento original por defecto: sin Coolify, las variables caen a `postgres` y `verify-full` y `certs/ca.crt` sigue siendo obligatorio. Use `bash scripts/coolify-check.sh` para verificar el contrato antes de desplegar.

### Pasos operativos antes del primer arranque en Coolify

Coolify publica el dominio vía Traefik y no expone puertos propios, por lo que `compose.bootstrap.yaml` (que publica `127.0.0.1:8097:3000`) no puede usarse para el cambio de contraseña inicial. Realice los siguientes pasos en este orden:

1. **Crear la base propia en el Postgres compartido de Supabase.** Conéctese al proyecto y cree la base `mvp_hefesto_metricas_umami_supabase` (o el slug acordado). El rol `umami_app` ya debe existir y tener asignada la clave de `DB_PASSWORD`.
2. **Ejecutar `sql/01-supabase-app.sql` conectado a esa base.** El script fija `DATABASE postgres` en `GRANT CONNECT` y en los `ALTER ROLE ... IN DATABASE`; antes de correrlo reemplace `postgres` por el nombre real de `DB_NAME`. Si lo deja en `postgres`, el rol no tendrá permisos en su base y `ops/preflight.sql` fallará con «Faltan permisos» o se rechazará la conexión.
3. **Cambiar la contraseña de la cuenta `admin` por defecto antes del primer despliegue público.** La imagen crea un usuario `admin` con clave `umami`; `ops/guard.mjs:11-12` bloquea el arranque mientras esa clave siga activa. En Coolify no se puede levantar `compose.bootstrap.yaml` (publica un puerto). Hágalo así:
   - Levante una base temporal local con `bash scripts/backup.py` o un Postgres propio, importe `mvp_hefesto_metricas_umami_supabase` con `bash scripts/restore_db.py`, cambie la clave (`/api/auth/change-password` o el panel de Umami), exporte el SQL actualizado y restáurelo en la base compartida.
   - Como alternativa operativa: haga el cambio dentro del propio Supabase mediante `psql` contra `mvp_hefesto_metricas_umami_supabase`, aplicando el hash que devuelve `bcrypt.hash(contraseña, 10)` sobre `public."user"."passwordHash"` de la cuenta `admin` (revise el nombre exacto de la columna en la migración nativa de Umami 3.4.0 antes de ejecutarlo).
   Documente el procedimiento elegido y conserve la nueva clave fuera del repo.
4. **Definir las variables obligatorias en Coolify.** El despliegue no arranca sin:
   - `SUPABASE_DEDICATED_CONFIRMED=true` y `SUPABASE_DATA_API_DISABLED=true` (exigidas por `ops/preflight.sh:3-4`).
   - `DB_NAME`, `DB_USER` (solo si el rol no es `umami_app`), `DB_PASSWORD`, `DB_HOST`, `APP_SECRET`, `TWO_FACTOR_ENCRYPTION_KEY`.
   - `DB_SSLMODE=disable` si la red interna de Docker no entrega la CA de Supabase; en ese caso `PGSSLROOTCERT` puede omitirse.
