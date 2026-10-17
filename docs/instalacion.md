# Instalación
1. Cree proyecto Supabase exclusivo PostgreSQL 16/17. Desactive Data API. Ejecute sql/01-supabase-app.sql como administrador en SQL Editor; aborta si public contiene tablas. El rol umami_app recibe solo permisos necesarios en public; UTC para sus sesiones.
2. Ejecute `python3 scripts/configure.py`. Edite .env con DB_HOST y DB_USER. Asigne DB_PASSWORD al rol mediante `\password umami_app` en psql administrativo. No copie claves a tickets ni logs.
3. Descargue la CA como certs/ca.crt. Use conexión directa 5432 con IPv6 o complemento IPv4. Alternativa Session pooler 5432: host exacto del panel y usuario `umami_app.REFERENCIA`. Este kit usa la misma ruta para aplicación y migraciones, no Transaction pooler 6543. Para respaldo/migración se prefiere conexión directa; pruebe conectividad desde el VPS.
4. Marque SUPABASE_DEDICATED_CONFIRMED y SUPABASE_DATA_API_DISABLED true después de cumplirlas. Los flags son confirmaciones del operador; no comprueban ajustes del panel automáticamente.
5. `docker compose config --quiet` y `docker compose run --rm preflight`.
6. `docker compose -f compose.yaml -f compose.bootstrap.yaml up -d app`. Revise logs. El arranque ejecuta migraciones oficiales, verifica cuentas y prepara el tracker. Nunca interrumpa una migración.
7. En su equipo: `ssh -L 8097:127.0.0.1:8097 usuario@servidor`. Visite http://localhost:8097. El instalador oficial crea admin / umami. Cambie la contraseña inmediatamente en la interfaz, cree su cuenta nominativa si corresponde y configure 2FA con sus códigos de recuperación.
8. `docker compose up -d --force-recreate app` SIN override. El guard rechaza el inicio productivo si alguna cuenta activa conserva contraseña umami. Es una comprobación de arranque; no una política que impida cambios posteriores desde la aplicación.
9. Configure dominio HTTPS del servicio app al puerto interno 3000. Confirme que 8097 ya no está publicado. Agregue un sitio y complete docs/aceptacion.md antes de colocar el tracker en producción.

## Coolify
Importe el directorio completo. Cargue .env como secretos y mantenga montajes ops y certs. Use el mismo proyecto Compose durante bootstrap y despliegue definitivo. Respete preflight como dependencia completada. No exponga inicialmente el dominio con la contraseña de fábrica. Coolify sirve HTTPS y debe transmitir Host y X-Forwarded-Proto correctamente.

No cubra todo el dominio con una autenticación extra que bloquee script.js o api/send, porque el tracker del sitio necesita esos endpoints. El panel conserva el login de Umami; limite administradores y permisos de equipos. Configure red/proxy sin aceptar cabeceras de IP arbitrarias de Internet.

## Detalles TLS
ops/urls.mjs construye URLs sin imprimir secretos. Node-postgres usa sslmode=verify-full y sslrootcert; Prisma Migrate utiliza DIRECT_DATABASE_URL con sslmode=require, sslaccept=strict y sslcert. No son intercambiables. Cambiar DB_HOST/DB_USER/DB_PASSWORD requiere recrear app. No use NODE_TLS_REJECT_UNAUTHORIZED=0 ni SKIP_DB_CHECK para eludir fallos.

El pool de conexiones conserva el comportamiento de la versión nativa; no se promete que connection_limit de Prisma controle pg en esta versión con adaptador. Revise el consumo con carga y dimensione Supabase antes de añadir sitios o réplicas. Inicialmente use una sola réplica.
