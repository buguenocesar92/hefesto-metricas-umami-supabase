# Oferta y traspaso
Servicio sugerido: instalación, instrumentación de sitios, definición de eventos, panel por cliente, capacitación, mantenimiento e informe periódico. Vender claridad sobre páginas y acciones que generan interés, sin prometer ventas ni atribución perfecta.

Umami complementa Metabase: el primero recoge comportamiento web; el segundo analiza datos de negocio conectados. Se puede usar en sitios WordPress, WooCommerce, Laravel/Nuxt u Odoo mediante el tracker. No es una migración del historial de Google Analytics ni una conexión de ventas Odoo instalada.

## Entrega al cliente
Documentar dominio, alojamiento, Supabase, propietario, usuarios/equipos, IDs de sitios, eventos y exclusiones, retención, versión/digest, claves y prueba de restauración. Transferir secretos por gestor y rotar los accesos del operador saliente. El cliente debe conservar códigos de recuperación 2FA.

Para mover el servidor, restaurar PostgreSQL y claves, mantener el dominio/UUIDs o actualizar los trackers. Para reportar en Odoo, especificar una integración API agregada de visitas/eventos por periodo; el dump no se importa en la base de Odoo. No se incluye ese conector ni una integración n8n ya activa.

Una instalación por cliente es la opción del kit. Si comparte VPS, establezca COMPOSE_PROJECT_NAME distinto en cada .env y conserve el nombre en los scripts. La imagen upstream es MIT; conservar avisos aplicables y la identidad de Umami, sin presentar el motor como desarrollado desde cero por Hefesto.

Plantilla manual de informe: periodo y zona horaria, visitas/páginas, principales entradas, eventos relevantes, comparación con periodo equivalente, limitaciones de datos y siguiente experimento. No hay paneles ni informes precargados ficticios.
