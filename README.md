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
