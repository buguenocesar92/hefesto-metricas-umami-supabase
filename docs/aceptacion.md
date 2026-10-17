# Aceptación pendiente
Verificado en la preparación: YAML, sintaxis Python/JavaScript, generación de secretos sin sobrescritura, construcción de URLs sin imprimir contraseñas e integridad ZIP. Revisados Dockerfile, arranque, adaptador PG, esquema y credenciales iniciales de la versión 3.4.0.

No ejecutado aquí: imagen Docker, imports en su filesystem, conexión real, migraciones, TLS real, login y captura de eventos. Antes de producción:
- [ ] Preflight pasa con el rol correcto y falla con CA incorrecta.
- [ ] Migraciones concluyen; verificar TLS tanto en runtime como en Prisma.
- [ ] Guard carga sus dependencias desde la imagen y bloquea contraseña de fábrica.
- [ ] Bootstrap local por túnel, contraseña cambiada, 2FA y recuperación comprobados.
- [ ] Producción sin puerto 8097 ni override; HTTPS y heartbeat correctos.
- [ ] Cuenta cliente solo ve sitios/equipo autorizado; no dar rol admin general.
- [ ] Tracker envía una visita y un evento esperado sin duplicados ni datos sensibles.
- [ ] Grabación de sesiones desactivada; privacidad y retención definidas.
- [ ] Restaurar en otra DB y validar login, 2FA, sitios y conteos de eventos.
- [ ] Registrar responsables, versiones exactas, RPO/RTO medidos y aceptación.
