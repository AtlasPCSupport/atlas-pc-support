# Operación, informes y recuperación

## Publicación y acceso

El acceso habitual se mantiene:

```powershell
irm https://toolspanel.atlaspcsupport.com | iex
```

Reabrir selecciona la publicación aprobada. Una ventana abierta mantiene su release
verificado. El procedimiento para promover y revertir código está en
[RELEASES.md](RELEASES.md): commit limpio, los tres jobs aprobados sobre ese SHA,
promoción de Worker conservando variables/secretos y comprobación del dominio.
No se promueve únicamente porque el push o el build local hayan terminado.

El onboarding tiene autoridad separada en `api/cloudflare-worker/onboarding-release.json`:
commit y hash exacto de su fuente privada. Hacer push a ese repositorio no altera
el endpoint hasta promover los nuevos pins. Ambos endpoints verifican los mismos
bytes y no usan caché compartida. Un fallo de credenciales o integridad aborta;
no se desactivan controles de Windows para continuar.

Defender/AMSI permanecen activos; no se añaden exclusiones, `Unblock-File`, comandos
codificados ni cambios permanentes de ExecutionPolicy. La reputación de SmartScreen
y una detección futura no se pueden garantizar con una prueba de descarga.

## Informes compartidos

Los escritores integrados de Entrega, licencias, diagnóstico, eventos, GPU,
teclado, impresoras, ampliaciones, IA y exportación de observaciones del router
aplican redacción y metadatos de herramienta/versión/commit/fecha/cobertura.
Se ocultan patrones de claves, recuperación, IP/MAC, SID, correo y rutas de usuario;
campos estructurados de identidad/serial y valores explícitos se ocultan también.
Entrega omite nombres de cuentas, seriales y claves; impresoras omite propietario
y documento del trabajo. El filtrado no identifica toda información privada que
pueda aparecer en texto libre: revisar antes de compartir. No equivale a anonimato
garantizado de logs o salidas arbitrarias de programas externos.

Los logs de operación, perfiles de clientes, manifiestos de backup y snapshots de
restauración son datos locales de trabajo. No se alteran para redactar un informe,
ya que eso podría impedir la recuperación. Los backups explícitos de claves de
BitLocker contienen secretos y se custodian por separado, fuera del equipo.
Atlas no sube informes automáticamente ni prescribe conservarlos indefinidamente.

BitLocker solicita un archivo .txt nuevo en otro disco físico; comprueba todos los
volúmenes seleccionados antes de escribir y relee el archivo. No guarda claves
automáticamente en el Escritorio ni en todos los USB. En CLI, Extract exige Output
y mantiene valores ocultos salvo Reveal. En el menú, REVEAL/COPY/CARD son acciones
explícitas; las tarjetas son texto imprimible, no QR. BACKUP solicita respaldo en
AD/Entra; su aceptación no prueba recuperación remota. El archivo y las tarjetas
contienen secretos: custodiar fuera del equipo protegido y revisar el historial
del portapapeles si se eligió COPY. No se publican esas claves como evidencia.

Runtimes permite seleccionar individualmente VC++ 2013 x64/x86, DirectX, XNA y
OpenAL. Instalar solo lo requerido por una aplicación; selección vacía cancela.
Timeout o cancelación detiene el resto; conservar evidencia de una instalación
parcial antes de repetir. NetFx3 usa la característica Windows y medios compatibles.

Licencias muestra estado local y exporta inventario sin claves completas. La clave
OEM requiere `REVEAL`; copiarla exige además `COPY`. No hay copia implícita al
portapapeles ni se interpreta una clave genérica/decodificada como activación.
Las suscripciones Microsoft 365 y el derecho de transferencia requieren validación
por los procedimientos del proveedor.

## Acta de entrega

La opción de checklist de Entrega PC crea un ID y guarda su JSON en
`Documents\AtlasPC\reports\Handover`. Se puede continuar indicando ese ID. Cada
cambio se guarda inmediatamente; el anterior queda como `.previous`. No se usa el
nombre del cliente ni el del equipo como nombre del archivo.

Cada punto comienza `NotVerified`. `ManualConfirmed` y `NotApplicable` requieren
motivo/evidencia sin secretos y fecha UTC. El HTML es una instantánea de ese JSON;
los controles están deshabilitados y no hay «marcar todo». Para cambiar evidencia,
volver a Entrega y regenerar el informe. Una confirmación manual no demuestra por
sí sola escrow, activación ni recuperación ensayada. Un esquema, idioma o listado
de requisitos diferente no hereda confirmaciones anteriores silenciosamente.

## Recuperación de operaciones

| Operación | Recuperación y límite |
|---|---|
| Código/USB | `get.ps1 -Rollback` selecciona solo una versión anterior íntegra; no deshace cambios del sistema. Ver RELEASES. |
| DNS | Restaurar el snapshot creado antes del cambio. GUID y familia evitan confundir renombres de adaptador; se conserva origen DHCP/estático. Un backup viejo sin origen conocido se rechaza. |
| Servicios | Elegir el snapshot de `ServiceSnapshots`; restauración comprueba inicio, estado y arranque diferido. Si falla, conservar evidencia y consultar Windows; no forzar dependientes. |
| Hosts | Conservar el `.bak` de bytes originales. La importación de texto usa UTF-8; restauración usa los bytes exactos del backup. Al aplicar/restaurar el bloque administrado, el resultado del archivo y el refresco de caché DNS se muestran separados. Un fallo de caché no deshace una restauración de archivo completada. |
| Impresión | Vaciar elimina solo trabajos de la cola elegida; los documentos eliminados se deben reenviar. Reiniciar Spooler es una acción distinta y afecta al servicio compartido. |
| Cuentas | Confirmar acceso de un administrador alternativo antes de cambios. Un rollback de código no recupera datos de un perfil eliminado ni secretos EFS perdidos por reset de contraseña. |
| BitLocker | Usar la clave respaldada externamente y el procedimiento Windows. La solicitud de cifrado no prueba que haya finalizado ni que se haya ensayado recuperación. |
| Copias | Revisar código y log. Muestreo no es certificación integral; mover/sincronizar FastCopy permanece restringido. |

Antes de probar reparaciones, utilizar una VM con snapshot y datos ficticios.
Los casos de aceptación pendientes y sus responsables de evidencia se enumeran en
el [cierre del plan](audits/CIERRE-PLAN-2026-10-24.md).
