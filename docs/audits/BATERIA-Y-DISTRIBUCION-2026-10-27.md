# Bateria y aviso propio de distribucion — 1.5.12

Revision autonoma del 27/10/2026, posterior a las pruebas manuales de archivos.
No se arrancan VMs ni se ejecutan exportadores, instaladores o reparaciones en
el host para aparentar una validacion fisica. Los procesos de bateria de las
regresiones son mocks que escriben unicamente reportes ficticios nuevos.

## Datos de bateria

- El parseo anterior podia truncar `57,000 mWh` a 57 y presentaba ciclos ausentes
  como cero. Ahora acepta valores enteros completos con agrupacion explicita;
  formatos ambiguos, negativos, no numericos y el valor uint32 desconocido se
  conservan como desconocidos. Cero ciclos requiere un cero reportado.
- Se prioriza XML de `powercfg /batteryreport`; BatteryInfoView sigue siendo
  un fallback si el reporte nativo falla. La utilidad y sus capacidades no se
  retiran. El texto del fallback detecta BOM y rechaza campos duplicados que
  no permiten atribuir capacidades a una sola bateria.
- Cada bateria conserva sus capacidades de diseno/carga completa y ciclos.
  No se suman valores parciales de dispositivos distintos ni se toma el mayor
  contador como si fuera el de un unico dispositivo. Sin una pareja utilizable
  no se calcula relacion; cero capacidad no se convierte en medicion de salud.
- El porcentaje se etiqueta como relacion reportada, no como una prueba de salud,
  edad, autenticidad o autonomia. Una relacion superior al 100 % no se recorta
  ni produce acusaciones por un contador cero/desconocido. Se conserva el aviso
  de que una prueba de descarga controlada tiene un alcance diferente.
- El estado CIM 2 significa CA disponible sin confirmar carga; 9 conserva
  carga, 10 queda desconocido y 11 indica carga parcial. Carga ausente o fuera
  de 0–100 no se muestra como 0 %. Los estados se listan aparte, sin asignarlos
  por posicion a baterias de otra fuente. La consulta solicita timeout de 10 s.
- Se conserva el limite de 15 s y salida nueva por intento para ambos exportadores.
  El XML rechaza DTD/entidades externas. Fabricante y quimica se codifican en HTML.

## Distribucion

El build incluye LICENSE de Atlas en el manifiesto, los instaladores online/offline
y el artefacto CI. El conjunto pasa a 34 miembros con los mismos 27 scripts.
La verificacion exige ese miembro desde 1.5.12 y conserva el contrato de versiones
anteriores para rollback. Se prueban el rechazo de una nueva distribucion sin
LICENSE, copia del aviso completo y vuelta a una release anterior sin ese miembro.
La lista de rutas permitidas sigue siendo explicita; no se permiten archivos
arbitrarios por incorporar un aviso.

No cambia la licencia de Atlas, no compra certificados y no concede permisos de
uso profesional o redistribucion sobre HWiNFO, FastCopy u otros componentes.

## Comprobaciones y alcance

Las regresiones cubren numeros completos/ambiguos/ausentes, ciclos cero/desconocidos,
varias baterias, XML namespaced, filas parciales, estados CIM, porcentaje invalido,
fallback UTF-16, fallos de exportacion, salida nueva y codificacion HTML.
El bloque de calidad/distribucion completo aprobo 174 pruebas en PowerShell 7.
Las suites integrales por runtime y la publicacion se identifican en la PR de esta
entrega. No equivalen a ejecutar esos proveedores en baterias reales o Windows 10.

Fuentes consultadas:

- [Win32_Battery](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-battery):
  estados y campos reportados; no se infiere carga para estado 2.
- [powercfg /batteryreport](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options#batteryreport):
  exportacion XML nativa.
- [BatteryInfoView](https://www.nirsoft.net/utils/battery_information_view.html):
  exportacion y disponibilidad condicionada del contador de ciclos.
