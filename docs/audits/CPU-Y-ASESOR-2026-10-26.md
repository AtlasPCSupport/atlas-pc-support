# CPU, asesor y perfil de red — 26/10/2026

Distribucion: 1.5.9, posterior al bloque RAM 1.5.8.

## Evidencia y cambio

La reproduccion aislada del codigo anterior produjo estos resultados:

| Entrada ficticia | Interpretacion anterior |
|---|---|
| CPU desconocida con 8 nucleos | Clasificacion aceptable, pero recomendacion critica de CPU obsoleta |
| Intel Core i7-8700 | Generacion 87, clasificacion buena |
| AMD Ryzen 7 5800X | Generacion 5, clasificacion antigua |

El inventario no ejecutaba un benchmark ni acreditaba compatibilidad de placa,
BIOS o refrigeracion. Se retiran la extraccion de generaciones por regex,
la equivalencia entre series de fabricantes y la nota global de 0 a 100.
No se sustituye por otra clasificacion comercial ni por un benchmark inventado.

- CPU conserva todos los registros reportados: nombre, designacion del socket,
  codigo UpgradeMethod del firmware, nucleos e hilos disponibles. Datos ausentes
  quedan nulos; los codigos sin interpretar no se convierten en sockets supuestos.
- Un sufijo movil, un chasis portatil o UpgradeMethod None no prueban BGA.
  Reemplazo/soldadura y compatibilidad se dejan sin verificar y se remite al
  manual de servicio. No se propone sustituir un equipo por su nombre de CPU.
- Error o inventario vacio deja CPU como NotEvaluated, sin ocultarlo como
  generacion cero. Las consultas CPU/red tienen timeout de operacion CIM de
  10 segundos; esto no demuestra un limite estricto de pared del proveedor.
- El asesor conserva observaciones de capacidad RAM/espacio y tipos de discos,
  sin prometer salud, segundos de arranque ni mejoras porcentuales medidas.
  Se retiran cotizaciones fijas de piezas/licencias y la recomendacion de compra
  automatica por clasificacion de CPU. Los limites de RAM del bloque anterior
  siguen pendientes de verificacion fisica por modelo.
- Windows 10 por Caption no implica que todas sus ediciones esten fuera de
  soporte. Se solicita revisar edicion, build/UBR, canal, actualizaciones y
  derechos aplicables; Enterprise LTSC e IoT se mantienen separados. No se
  audita ni se modifica la licencia o cobertura ESU del host.
- El perfil de red conserva todas las direcciones y puertas de enlace reportadas
  en ambas familias. Un error no se presenta como ausencia de adaptadores.
  Nombre/socket CPU y todos los campos de red se codifican al generar HTML.
- Se corrige tambien la insercion de texto en las lineas CPU-Z (incluidas
  temperaturas), inventario nativo, identificador de volumen, fabricante/quimica
  de bateria, titulo, cliente/equipo y resumen del sistema. Solo el marcado
  propio conserva etiquetas HTML; el texto externo no se interpreta como ellas.

## Comprobaciones y limites

Las 13 regresiones nuevas fallaron sobre el codigo anterior y aprobaron tras
el cambio. Bloquean hardware real y cubren nombres no reconocidos, Intel/AMD,
codigos de firmware, sufijo/chasis, denegacion/vacio, varios procesadores,
HTML, red dual y dos ediciones Windows 10. Los 15 casos RAM siguen cubiertos.
Cuatro regresiones adicionales reproducen la insercion de etiquetas en las
ramas reales del renderizado y aprueban tras codificar el texto, conservando
cabeceras y colores propios. La prueba de almacenamiento cubre tambien el
identificador del volumen. No se depende de la redaccion de identidad para
neutralizar HTML.
No se ejecuta instalacion, benchmark, cambio de firmware ni diagnostico sobre
el host. Se elimina tambien el texto bilingue ya sin consumidores de la
clasificacion retirada, sin suprimir reglas del analizador.

Validacion final: 302 aprobadas, cero fallidas/omitidas en PowerShell
5.1.26100.9711 y 7.6.9 (host build 26100). Cero errores de analizador,
292/318 avisos conservados; guardas, sintaxis, hashes, inventario generado y
reproduccion de distribucion correctos. Informes locales en Temp:
`atlas-local-checks-4b9a306e77dc465281d4d355570368d0` y
`atlas-local-checks-ed39fac442ab464c84cbdcf3997d508b`.
El ensayo anterior de 298 casos se repitio tras ampliar las fronteras HTML;
los resultados finales corresponden al bundle reconstruido, no al anterior.

La revision sigue siendo gradual: otros exportadores y limites de interpretacion
requieren su revision y la aceptacion con hardware real. Los ensayos de cuentas,
UAC, BitLocker, restauracion e instalaciones siguen en el entorno desechable
pendiente; las VMs estan pausadas. Windows 10 no queda homologado.

## Publicacion y USB

CI 40402441946 aprobo build, windows-compat y worker en el commit exacto
`8c0c899fd3f808604d072c8c5cfff4082d163b3e`. Manifiesto
`3c34ab517bf2693075aacbfc16f4e98b1dc7416cb7f822ed44bcf08ecd2dec55`;
Worker `b08dcba4-061f-4572-85e8-2caf2ba1dad2`. Los siete endpoints se
comprobaron con 5.1/7; bootstrap, manifiesto, sidecars, 33 miembros, probes
negativos y entrada offline sin lanzar herramientas aprobaron. Defender activo.
Evidencia local `atlas-public-check-456f875029674c93a9488e8ffeab83f7` en Temp.
El enlace publico conserva su direccion y la promocion retiene 1.5.8 anterior.

La carpeta QA de la misma USB NTFS autorizada se actualizo de 1.5.7 a 1.5.9,
se comprobo con NoLaunch en 5.1/7, se volvio a 1.5.7 y se restauro 1.5.9.
Evidencia publicable: [USB 1.5.9](USB-1.5.9-2026-10-26.json).
El primer intento fallo por seleccion multiple de rutas del helper, despues
de pasar 5.1. No se conto como aprobado. Se verificaron ambos pointers antes
de retomar, se selecciono un solo ejecutable existente y la repeticion aprobo.
Log final local `atlas-usb-latest-37ea2c6c8f8248218c42f344f80e1d65` en Temp.
No se formatea ni se modifica la particion auxiliar; no se ensaya desconexion
durante escritura ni perdida de alimentacion. La reconexion anterior de 1.5.7
conserva su evidencia separada.

Referencia: [Win32_Processor](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor)
documenta inventario, una instancia por procesador y UpgradeMethod como
enumeracion SMBIOS. La aplicacion conserva el dato reportado sin presentarlo
como prueba de rendimiento o compatibilidad fisica.
