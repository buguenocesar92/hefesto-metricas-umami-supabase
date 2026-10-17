# Respaldo, restauración y actualización
`python3 scripts/backup.py` detiene app, exporta public en formato custom y conserva .env, Compose y manifiesto SHA-256; reinicia si estaba activa. Reserve una ventana de mantenimiento: durante la pausa no se recogen eventos y no hay cola de recuperación garantizada. Evite otras instancias y escrituras concurrentes.

Guarde los respaldos cifrados fuera del VPS: incluyen credenciales, claves 2FA y datos analíticos. Configure retención, programación y alertas en el servidor según el servicio; el kit no registra tareas automáticas. Una copia sin manifest completed es incompleta. Hashes verifican integridad, no autenticidad frente a un atacante.

## Restaurar
1. Prepare proyecto Supabase nuevo vacío con el rol y CA; use exactamente Umami 3.4.0 y mantenga app detenida.
2. Cree .env destino con host/clave de DB nuevos. Recupere APP_SECRET y TWO_FACTOR_ENCRYPTION_KEY originales por un canal seguro; cambiar esta última puede impedir descifrar secretos 2FA. No copie ciegamente el host del respaldo.
3. `docker compose run --rm preflight`
4. `python3 scripts/restore_db.py /ruta/respaldo`
5. `docker compose up -d app` SIN bootstrap. Entre con las credenciales vigentes al hacer la copia.
6. Verifique sitios, permisos, eventos, 2FA y rangos de fechas; cambie DNS solo tras aceptar. Si cambia el dominio de métricas, actualice los trackers de los sitios.

La restauración rechaza public con tablas; no borra ni fusiona. Si falla parcialmente, investigue y use otro destino vacío. No elimine el origen para reintentar. Se respalda solo public, no Supabase Auth/Storage ni todo el proyecto. No hay archivos de negocio locales que restaurar en este kit; conserve además ZIP, CA vigente, DNS/proxy y configuraciones de instrumentación.

## Actualizaciones y operación
Antes de actualizar: copia, ensayo en clon y revisión de migraciones upstream. Revertir imagen no revierte esquema; restablecer backup en destino nuevo cuando proceda. Mantenga versiones/digests y claves en el inventario. postgres:17-alpine puede recibir parches; registre su digest en el servidor si requiere congelar la herramienta.

Supervise heartbeat, respuestas de api/send, espacio/crecimiento de DB y copias. Defina retención con el cliente; no se ejecuta una purga automática ni SQL destructivo en este kit. Las cuentas administrativas tienen alcance amplio: para mayor aislamiento use una instalación y proyecto Supabase por cliente.
