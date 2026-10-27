# Política de tratamiento de datos personales — Métricas (Umami) (Hefesto Studio)

Estado: vigente desde 2026-10-20. Responsable del tratamiento: el cliente que
opera el kit. Este documento describe qué datos guarda el kit, por qué, cuánto
tiempo los retiene y cómo se ejercen los derechos del titular (Ley 21.719).

## 1. Qué datos guarda este kit

El kit de métricas (Umami) es analítica web y **sí** trata datos
personales:

- **Eventos de navegación**: URL visitada, `referrer`, `user_agent`, marca de
  tiempo y **dirección IP** del visitante.
- **Identificadores de sesión**: identificador de sesión y de visitante, que
  permiten reconstruir el recorrido de una persona durante la sesión.
- **Cuentas del panel**: usuario, correo, hash de contraseña y **clave de
  cifrado de 2FA** (`TWO_FACTOR_ENCRYPTION_KEY`).
- **Copias locales de respaldo**: `backups/<timestamp>/` con el dump de
  PostgreSQL (`public.dump`) y la configuración del kit.

Sin cookies de seguimiento ni identificador persistente entre sesiones, la IP
sigue siendo un dato personal: puede identificar a una persona en un entorno
cerrado (por ejemplo, una intranet de una-Chile).

## 2. Qué datos NO guarda este kit

- El `.env` **no** se copia en claro al respaldo: solo sus nombres de variable
  (`env.vars`) y, si hay un receptor `age` configurado, el `.env` cifrado
  (`env.age`). Ver `docs/CONTRATO-RESPALDO.md`, regla 5.
- El kit no guarda datos de tarjetas, ni contactos, ni credenciales de terceros.

## 3. Base legal y deberes

- **Minimización**: la analítica guarda URL, referrer, user agent e IP porque son lo mínimo para medir. No se guardan cookies de seguimiento, ni nombres, ni correos de los visitantes: el panel no identifica a las personas, salvo por la IP y el identificador de sesión.
- **Finalidad**: medir el uso del sitio del cliente. Los datos no se usan para otros fines ni se ceden a terceros. La configuración de IP y su retención las decide el operador.
- **Seguridad**: los respaldos se cifran en reposo hacia el destino del
  operador, la clave privada no está en este servidor y el `.env` nunca sale
  en claro.
- **Auditoría**: cada respaldo y cada restauración dejan registro en
  `logs/restore.log` con origen, sha256 verificado, destino y resultado. Es
  registro de actividades de tratamiento: no guarda valores de secretos.

## 4. Retención

| Dato | Dónde | Retención por defecto | Quién lo borra |
|---|---|---|---|
| Eventos e IP | PostgreSQL (volumen `public`) | **a definir por el operador** (por defecto, 90 días en las opciones de Umami) | el operador, desde el panel |
| Sesiones y visitantes | PostgreSQL (volumen `public`) | mientras Umami los conserve | el operador |
| Cuentas del panel | PostgreSQL (volumen `public`) | mientras la cuenta exista | el operador |
| Clave de 2FA | `.env` (nunca en el respaldo en claro) | mientras el kit exista | el operador |
| Respaldos en disco | `backups/<timestamp>/` | **a definir por el operador**; el kit no borra nada por su cuenta | el operador |
| Registro de auditoría | `logs/restore.log` | append-only; se trunca por política del cliente | el operador |

**El kit no borra respaldos ni datos por su cuenta.** Borrar es una decisión del
operador, porque un respaldo borrado no se recupera.

## 5. Derechos del titular (acceso, rectificación y supresión)

1. **Acceso**: entregar los datos de un titular concreto desde la interfaz del
   kit o desde el dump de la base.
2. **Rectificación**: corregir los datos desde la interfaz del kit.
3. **Supresión**: eliminar el registro y dejar constancia de la supresión en el
   registro de auditoría.
4. **Revocación del consentimiento**: si el tratamiento depende del
   consentimiento, eliminar el registro.

El kit garantiza que los datos son localizables, corregibles y borrables; el
cliente es quien conoce la identidad de los titulares.

## 6. Verificación

- `bats tests/backup_restore.bats` comprueba, con datos sintéticos, que el
  `.env` no queda en claro, que el manifiesto lleva las cinco claves, que un
  artefacto alterado se rechaza y que un destino no vacío aborta la
  restauración.
- `gitleaks` corre en CI sobre el repositorio y su historial.
