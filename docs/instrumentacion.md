# Instrumentación y verificación
Cree un sitio desde la interfaz de Umami; copie su UUID real en templates/tracker.html y cambie el dominio de métricas y la lista data-domains. El ID de sitio es público, no es una clave administrativa. La lista de dominios limita el navegador, no autentica solicitudes ni evita todo tráfico falso.

- WordPress/WooCommerce: insertar una sola vez en el head mediante el mecanismo del tema o plugin elegido; excluir sesiones de administración según su política y comprobar caché/CSP.
- Laravel/Blade: colocar en layout compartido de páginas autorizadas. No emitir visitas en cada componente.
- Nuxt/Vue: cargar solo una vez en cliente, verificar navegación SPA y evitar duplicar pageviews con otro middleware de seguimiento.
- Odoo Website: instalar en la plantilla web mediante un módulo/versionado compatible y probar su política de recursos. No se incluye un módulo Odoo en este ZIP.

Se incluye plantilla de eventos. Clic en WhatsApp o cotización mide intención, no una conversación ni una venta. Emita formulario_enviado tras respuesta exitosa del backend; no al pulsar enviar. No envíe nombres, RUT, emails, contraseñas, tokens o contenido de formularios como propiedades.

La plantilla excluye query y fragmentos; revise también rutas que incluyan datos personales. Al excluir query pierde parte de la información de campañas/UTM: si la necesita, diseñe una lista permitida mediante before-send y compruebe que no filtra parámetros sensibles. No se incluye esa transformación ni identificación individual.

El tracker no se ha insertado en sitios reales. No se configuran grabaciones de sesión, mapas de calor ni píxeles de correo. El modelo nativo crea sitios con recorderEnabled=false; manténgalo así para este alcance y compruébelo en UI. Los administradores pueden cambiarlo después.

Configure la carga del script según las preferencias y política de privacidad de cada sitio. La tecnología elegida no certifica cumplimiento legal. Si una CMP debe controlar analítica, haga que cargue el script únicamente cuando corresponda; el HTML de ejemplo no es una CMP.

## Prueba práctica
En un sitio de ensayo, comprobar script.js y api/send en red, registrar una visita y un evento conocido, contrastar filtros/fecha/zona horaria. Repetir navegación SPA si aplica y verificar ausencia de duplicados. Respetar Do Not Track, excluir visitas internas y probar con la caché del sitio activa. Bloqueadores y rechazos de usuarios pueden reducir los conteos; no son cifras contables.
