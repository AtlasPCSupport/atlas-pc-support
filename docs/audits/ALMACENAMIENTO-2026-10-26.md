# Almacenamiento: cobertura y capacidad — 26/10/2026

Distribucion 1.5.10. Revision autonoma sin iniciar VMs, examinar discos del host,
ejecutar benchmarks ni modificar configuracion de almacenamiento.

## Cambios

- Consultas de discos fisicos y volumenes separadas: un fallo no elimina los
  resultados disponibles de la otra fuente. Se distingue Observed, Empty y
  Unavailable por fuente; el resumen distingue Observed, Partial y NotEvaluated.
  Inventario vacio no se presenta como una evaluacion fisica satisfactoria.
- Cada volumen conserva sus cifras observadas o valores nulos. Capacidad total
  ausente/cero, espacio libre ausente/negativo/mayor que el total, texto no
  numerico e infinito/NaN no generan un porcentaje ni una barra verde.
- CriticalSpace permanece nulo cuando no se puede descartar espacio insuficiente;
  un volumen critico valido se conserva aunque otro no sea evaluable. Solo se
  devuelve false cuando todos los volumenes reportados tienen cifras validas y
  ninguno alcanza el umbral. Discos sin capacidad reportada no muestran 0 GB.
- El umbral de ocupacion usa el porcentaje sin redondear. Un 89,6 % mostrado
  redondeado no se convierte por ello en un aviso critico de 90 %. El color usa
  tambien el valor original. Las cifras se interpretan con cultura invariante.
- HDD/SATA/NVMe se presentan como tipos reportados, con color neutral; no como
  resultados medidos de velocidad. Health conserva el estado del proveedor,
  con alcance explicito: no se ejecuta prueba de salud fisica.
- CIM de volumenes tiene timeout de operacion de 10 s. La API Get-PhysicalDisk
  sigue dependiendo de su proveedor; no se afirma un limite estricto de espera.

## Comprobaciones

Diecisiete regresiones nuevas junto con dos existentes: permisos, vacio,
resultados parciales, datos numericos incoherentes, umbral exacto, capacidad
fisica ausente y caso completo valido. La primera ejecucion agrego 15 casos
que fallaron con la implementacion anterior; las 19 pruebas finales aprobaron.
Los mocks bloquean las consultas reales. No certifican disco, USB o RAID real,
SMART, rendimiento, espacio agotado durante escritura ni recuperacion de datos.

Suite final: 319 aprobadas, cero fallidas/omitidas en PowerShell 5.1.26100.9711
y 7.6.9 (host build 26100). Cero errores del analizador, 292/318 avisos
conservados; AST UTF-8, guardas, hashes, inventario generado y distribucion
reproducible correctos. Informes locales en Temp:
`atlas-local-checks-4d43d1fe69124a00b81cd0bff42714ff` y
`atlas-local-checks-a3ca11a300944614832f4beb41a0d8c5`.
Worker: 24 aprobadas; politica CI: 9 aprobadas; auditoria npm sin vulnerabilidades.
La fuente UTF-8 sin BOM se carga por el contrato verificado del runner;
el parseo directo ANSI de esa fuente con ParseFile de 5.1 no es ese contrato,
como ya documenta tests/README.md. No se cambia la politica de ejecucion.

El asesor conserva hallazgos disponibles y no vuelve a introducir una nota global
de salud. El cierre operativo sigue en [PENDIENTES](PENDIENTES-2026-10-25.md).

Referencias: [Get-PhysicalDisk](https://learn.microsoft.com/en-us/powershell/module/storage/get-physicaldisk)
describe objetos visibles mediante proveedores de almacenamiento;
[Win32_LogicalDisk](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-logicaldisk)
documenta Size y FreeSpace en bytes. No se sustituye un dato ausente por cero.
