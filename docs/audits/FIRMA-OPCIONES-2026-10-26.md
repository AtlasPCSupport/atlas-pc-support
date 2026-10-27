# Firma de Atlas: opciones y dependencias

Consulta: 26/10/2026. Borrador tecnico para decidir; sin compra, solicitud,
certificado nuevo, cambio de confianza del host ni modificacion de publicacion.
Las herramientas de terceros se conservan como solicito el propietario;
su disponibilidad no demuestra licencias de uso profesional/redistribucion.

## Identidad y opciones

- Existen certificados de firma de codigo para personas naturales. SSL.com
  ofrece Individual Validation con el nombre personal verificado. Su pagina
  muestra US$129/anio para un anio; servicio de firma o token/HSM y otros cargos
  se revisan aparte. No se ha confirmado admision en Peru, nombre exacto que
  mostraria, documentos aceptados ni coste final para este solicitante.
- Certum tambien anuncia certificados para individuos y empresas. Condiciones
  de verificacion, territorio, custodia de clave y coste necesitan confirmacion.
- Microsoft Artifact Signing Public Trust limita desarrolladores individuales
  a EE.UU./Canada; Peru no aparece entre los paises de organizaciones admitidos
  en el quickstart consultado. Una region de Azure en Brasil no equivale a
  admision de identidad peruana.
- SignPath Foundation ofrece una via OSS condicionada a aceptacion. No debe
  presentarse como certificado gratuito ya disponible: impone restricciones
  sobre componentes propietarios y funciones de seguridad, aprobaciones por
  release y el editor es la fundacion. La presencia de utilidades de exploracion
  de red y componentes externos de Atlas requiere evaluacion explicita. No se
  solicita acceso ni se retiran funciones para aparentar que cumple.
- Una firma autofirmada no da confianza publica por si sola. No se distribuye
  una raiz propia ni se instala en los clientes como sustituto de validacion.

## Hallazgo del flujo actual

`api/cloudflare-worker/src/index.js` verifica el bootstrap y luego usa
`replaceAll` para insertar commit y manifiesto aprobados antes de devolverlo.
Una firma del get.ps1 plantilla no seguiria siendo valida tras esa sustitucion.
La invocacion actual con `irm ... | iex` tampoco solicita una comprobacion
Authenticode de archivo antes de ejecutar el texto.

El build calcula hashes de la distribucion reproducible y el runner entrega
fuentes verificadas por su contrato. Firmar despues de calcular los hashes
cambiaria los miembros; firmar y luego reconstruir tambien invalidaria firmas.
No basta con comprar certificado ni anadir un comentario de firma al repositorio.

## Preparacion tecnica que puede hacerse sin datos de identidad

1. Definir el artefacto publico estable a firmar, y los limites entre entrada,
   descriptor y bundle aprobado. Conservar la direccion publica.
2. Mantener compilacion reproducible sin firma; firmar artefactos finales
   mediante identidad/clave protegida y sellado de tiempo, antes de cerrar
   hashes/manifiesto correspondientes. La reproducibilidad se comprueba antes
   de la firma; la firma y procedencia de los bytes distribuidos se verifican
   aparte. Evitar dependencias circulares entre hash, commit y firma.
3. Definir verificacion Authenticode y confianza del editor para el punto de
   entrada y contenido firmado. Un hash canonico no sustituye esa verificacion.
4. Probar manipulacion, certificado no confiable, sellado de tiempo, descarga
   alterada, arranque offline y rollback en 5.1/7; Windows 10 requiere sus ensayos.
5. Integrar el proveedor elegido y sus aprobaciones en CI sin claves en Git,
   logs o USB. La fase final necesita certificado/servicio y validacion real.

La firma aporta identidad/integridad, no garantiza ausencia de alertas de
SmartScreen ni evita analisis Defender/AMSI. Se mantienen las protecciones.

## Decision del propietario

El propietario aplaza la adquisicion de certificados y solicita continuar las
pruebas funcionales. No se generan certificados ni se inicia una contratacion.
La firma publica queda pendiente, sin bloquear las comprobaciones actuales.
Si en el futuro se elige contratar: confirmar
admisibilidad del solicitante, identidad publica que aparecera, coste total y
custodia de clave antes de pagar. DNI, RUC, claves y documentos de validacion
no se solicitan ni se publican en este repositorio/chat.

## Fuentes consultadas

- [SSL.com IV](https://www.ssl.com/products/software-integrity/code-signing/iv/).
- [Certum Code Signing](https://www.certum.eu/en/code-signing-certificates/).
- [Microsoft Artifact Signing: requisitos](https://learn.microsoft.com/en-us/azure/artifact-signing/quickstart).
- [SignPath Foundation: condiciones](https://signpath.org/terms).
- [Microsoft: opciones de firma y limites SmartScreen](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options).
