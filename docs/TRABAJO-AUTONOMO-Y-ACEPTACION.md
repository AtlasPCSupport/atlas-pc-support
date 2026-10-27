# Trabajo autonomo y aceptacion pendiente

Estado: 27/10/2026. Las VMs permanecen pausadas; Windows 10 no esta homologado
por completo. Las pruebas en PowerShell 5.1 sobre el host no certifican una
edicion o parche de Windows 10.

| Area | Trabajo que puede completar el agente ahora | Que necesita al propietario |
|---|---|---|
| Deuda y errores | Reproducir fallos con fixtures, corregir codigo, comprobar 5.1/7, build/CI, push y publicacion autorizada | Aceptacion de comportamiento fisico cuando el fixture no lo demuestra |
| Instaladores | Revisar argumentos, fuentes, integridad, errores, reinicios pendientes y preparar matriz de ensayos | Elegir aplicaciones prioritarias; habilitar un entorno desechable para instalacion/upgrade reales |
| Recuperacion | Revisar backups/validacion y ensayar operaciones de archivos dentro de directorios de prueba | Retomar entorno desechable para cuentas, UAC, BitLocker, red, servicios y recuperacion tras reinicio |
| USB/hardware | Verificar datos ficticios y bundle en la carpeta QA expresamente autorizada, con identidad comprobada | Aportar medios/equipos adicionales y realizar manipulaciones fisicas; ensayos de interrupcion se preparan aparte |
| Firma | Revisar el flujo de integridad existente y preparar opciones de integracion | Identidad del firmante, certificado/servicio elegido y acceso autorizado; no se compra ni inventa confianza |
| Licencias | Inventariar dependencias/versiones y referencias oficiales; registrar dudas y requisitos | Confirmar uso profesional/redistribucion, titularidad y derechos contratados; una descarga no concede licencia |
| Informes | Mantener redaccion, metadatos y controles contra HTML externo | Definir custodia, destinatarios, consentimiento y plazo de retencion de datos reales |

## Lo que se ha comprobado

- 1.5.3–1.5.9: dependencias y limites de procesos, evidencia GPU/IA,
  accesibilidad basica, exportaciones nuevas, copias de recursos USB,
  interpretacion RAM/CPU y texto HTML. Cada bloque conserva sus pruebas y pins.
- USB NTFS: copia de fixtures, hashes, bloqueo, reconexion reportada por el
  usuario, entradas offline y rollback. La carpeta QA se actualizo a 1.5.9 y
  conserva 1.5.7; los resultados se documentan por intento. No significa que
  todas las carpetas offline del dispositivo se actualicen automaticamente.
- 1.5.10: cobertura y capacidad del inventario de almacenamiento; consultar
  [su evidencia](audits/ALMACENAMIENTO-2026-10-26.md) y CI de la entrega.
- Robocopy 1.5.10: copia completa e incremental ejecutadas manualmente desde
  Atlas con archivos ficticios del host, contrastadas con SHA-256 y log nativo.
  La incremental copio dos archivos, omitio cuatro y conservo el extra; cero
  fallos. [Evidencia y limites](audits/COPIA-MANUAL-2026-10-27.md).
- Robocopy 1.5.11: restauracion manual desde ese respaldo a una carpeta nueva.
  Siete archivos copiados, siete hashes y longitudes verificados por separado,
  carpeta vacia restaurada, origen y respaldo intactos; cero fallos nativos.
  [Evidencia](audits/RESTAURACION-ARCHIVOS-2026-10-27.json). No certifica
  recuperacion del sistema, ACL, perdida de energia o Windows 10.

## Decisiones ya tomadas

- Se conservan las herramientas y funciones actuales; la
  [propuesta alternativa de uso profesional](audits/PROPUESTA-USO-PROFESIONAL-2026-10-26.md)
  no fue adoptada. Los permisos de uso profesional/redistribucion de terceros
  siguen pendientes; la disponibilidad de las apps no los acredita.
- La [adquisicion de firma publica](audits/FIRMA-OPCIONES-2026-10-26.md) esta
  aplazada. No se generan certificados ni se cambia la confianza del host.
- El ensayo basico de copia completa, incremental y restauracion aislada de
  archivos ya tiene evidencia. No sustituye recuperacion del sistema, BitLocker
  o recuperacion tras reinicio, que siguen pendientes de un entorno desechable.

## Una decision por vez para retomar lo manual

1. Cuando se quiera retomar Windows 10/recuperacion, indicar **retomar laboratorio**.
   Se verifica una sola VM y snapshot; se prepara un paquete QA nuevo de la
   release aprobada. No se reutiliza una tarea antigua ni se abren varias consolas.
2. Para instalaciones, indicar una lista corta de aplicaciones y el objetivo de
   RustDesk. El agente prepara comandos y criterios de exito para ese entorno;
   no se instalan aplicaciones en el PC del usuario como sustituto de una prueba.
3. Firma/licencias: el uso como servicio tecnico y entrega a clientes ya esta
   definido. Conservar las decisiones anteriores; retomar proveedores/permisos
   solo cuando el propietario quiera revisar esos pendientes. No solicitar
   otra vez datos de identidad ni iniciar compras o solicitudes automaticamente.

No hace falta resolver esas decisiones para continuar corrigiendo fallos aislados.
No se da por aprobada una instalacion, recuperacion, licencia o prueba fisica
solo porque el codigo, un mock o la descarga hayan pasado.

Detalle operativo: [Operacion y recuperacion](OPERACION-Y-RECUPERACION.md).
Lista completa de escenarios: [Pendientes](audits/PENDIENTES-2026-10-25.md).
