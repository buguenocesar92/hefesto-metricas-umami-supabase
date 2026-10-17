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
