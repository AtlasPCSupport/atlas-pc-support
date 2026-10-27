# Propuesta de uso profesional y entrega a clientes

Estado: propuesta no adoptada; consulta de fuentes oficiales del 26/10/2026.
El propietario solicita conservar todas las apps y funciones actuales. No se
implementa el paquete base alternativo ni se retiran opcionales. La revision de
derechos profesionales/redistribucion sigue pendiente y no se da por aprobada.
No cambia herramientas, descargas, publicacion, licencias ni archivos de la USB.
No acredita derechos adquiridos ni aprueba un paquete de terceros completo.

Actualizacion tecnica 27/10, 1.5.12: se incluye solamente el aviso MIT propio de
Atlas en el bundle verificado y el artefacto CI. No adopta el paquete base
alternativo, no retira apps y no resuelve permisos de terceros.

## Separar tres conceptos

1. Ejecutar un programa durante un servicio tecnico.
2. Entregar al cliente una copia del programa dentro de la USB/paquete.
3. Incluir una clave o licencia profesional en esa copia.

Un permiso para el primer caso no concede automaticamente los otros dos.
La licencia MIT del codigo de Atlas no cubre los ejecutables de otros autores.

## Revision inicial

| Componente | Lo comprobado | Tratamiento propuesto |
|---|---|---|
| Atlas | LICENSE del repositorio es MIT y exige conservar aviso y licencia | Incluir LICENSE y avisos aplicables en el entregable; comprobar que el preparador los conserve |
| HWiNFO64 | Uso comercial requiere Engineer/Corporate; empaquetar en software de terceros necesita aprobacion expresa; la clave no se entrega a sujetos ajenos a la licencia | Excluirlo del paquete base de clientes. Mantenerlo como opcion profesional separada si se obtienen los derechos aplicables |
| FastCopy 5.12 | La EULA exige Pro en entornos laborales; la pagina de compra indica una licencia por PC y la EULA prohibe transferir/prestar/sublicenciar la licencia | Usar el flujo Robocopy existente como base. No presuponer que una licencia del tecnico cubra PCs de clientes ni incluir claves en la USB |
| BatteryInfoView | Su licencia restringe la distribucion dentro de un producto comercial | No incluirlo en el paquete comercial base mientras no se resuelva ese permiso. Preparar el informe nativo con powercfg y conservar datos ausentes como tales |
| BlueScreenView | Redistribucion gratuita, paquete completo y sin modificaciones; no convertirlo en una licencia propia de Atlas | Verificar todos los archivos/avisos del paquete y las condiciones de la entrega concreta antes de incluirlo; copiar solo el EXE no demuestra cumplimiento |
| CrystalDiskInfo / CrystalDiskMark | El autor permite redistribuir sus programas; los avisos del paquete y de sus componentes deben revisarse | Candidatos para conservar en edicion estandar, con sus archivos y avisos; no tratar temas, marcas o DLL externas como si tuvieran automaticamente la misma licencia |
| CPU-Z | La pagina oficial lo identifica como freeware; eso por si solo no resuelve el empaquetado comercial | Pendiente revisar la licencia de la version exacta antes de redistribuir; no se concluye que este prohibido o autorizado solo por esa etiqueta |
| GPU-Z / FurMark 2 | Las paginas del proveedor no pudieron consultarse por robots.txt | Pendientes; no sustituir la licencia por afirmaciones de foros, mirrors o manifiestos WinGet |
| Otros instaladores, runtimes y RustDesk | Fuera de esta revision inicial; cada paquete mantiene condiciones propias | Revisar por version/forma de entrega. No distribuir claves, configuracion privada ni material de clientes |

Fuentes:

- HWiNFO: [licencias](https://www.hwinfo.com/licenses/) y
  [EULA](https://www.hwinfo.com/files/license.pdf).
- FastCopy: [EULA 5.12](https://fastcopy.jp/help/fastcopy_eng.htm#license) y
  [licencias por PC](https://fastcopy.jp/pro/).
- NirSoft: [BlueScreenView](https://www.nirsoft.net/utils/blue_screen_view.html)
  y [BatteryInfoView](https://www.nirsoft.net/utils/battery_information_view.html),
  apartados License.
- Crystal Dew World: [redistribucion](https://crystalmark.info/en/information/about/).
- CPUID: [CPU-Z](https://www.cpuid.com/softwares/cpu-z.html).

## Cambio tecnico que se propone preparar

- Conservar las tarjetas y flujos actuales para no eliminar capacidades adquiridas
  por otros usuarios; separar explicitamente su uso del paquete base entregable.
- Base sin dependencias profesionales pagadas: copias con Robocopy ya existente,
  inventario CIM/Windows y observaciones nativas. No prometer sensores,
  temperatura, comparativas de rendimiento o diagnosticos que esas fuentes no dan.
- Corregir el modo nativo del informe: hoy su resolucion de herramientas puede
  copiar/instalar opcionales antes de generarlo. Cambiar la etiqueta del menu no
  basta para conseguir un flujo nativo sin esas dependencias.
- Preparar la USB base sin copiar automaticamente HWiNFO/FastCopy/BatteryInfoView
  y sin borrar copias existentes. Las incorporaciones futuras se verifican por
  producto/version y con sus avisos. Instalar desde una fuente oficial tampoco
  concede derechos de uso o de redistribucion.
- Conservar LICENSE/avisos de Atlas en el bundle y verificar su presencia real.
  La firma Authenticode es otra fase: identidad del firmante y servicio/certificado
  por definir; una licencia de utilidad no resuelve la confianza de Atlas.
- Regresiones aisladas 5.1/7, distribucion reproducible, CI y comprobacion del
  enlace antes de publicar cualquier cambio de comportamiento.

## Alternativa conservada para una revision futura

Elegir entre preparar primero la base sin dependencias profesionales pagadas,
dejando los opcionales separados, o evaluar antes adquisicion/permisos concretos
para conservar esos componentes en el flujo profesional. Ninguna opcion significa
que todas las licencias o pruebas reales ya esten resueltas.
