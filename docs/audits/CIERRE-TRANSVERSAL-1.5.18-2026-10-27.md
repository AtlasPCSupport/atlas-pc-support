# Cierre transversal del plan de auditoría — 1.5.18

Completa las rutas de software que seguían pendientes después de las cinco fases
de la [auditoría integral](AUDITORIA-INTEGRAL-1.5.12-2026-10-27.md). La revisión
posterior detectó que un helper corregido no garantizaba que todos sus consumidores
lo usaran. Este cierre incorpora esos consumidores y regresiones que los ejercitan.

## Cambios y motivo

| Ruta pendiente | Cambio aplicado | Por qué |
|---|---|---|
| Master, resumen inicial e inventario simple | Reutiliza el resumen de memoria; capacidades y velocidades desconocidas son N/D; conserva capacidades fraccionarias y reutiliza la consulta de módulos | Un módulo sin capacidad no demuestra 0 GB; un dato parcial no permite sumar un total completo |
| Master, GPU Check, FastCopy y los dos grupos del preparador USB | Todos resuelven mediante Resolve-AtlasDependency, con candidatos locales/offline adicionales y nombres alternativos | Evitar rutas que aceptaban cualquier archivo o ignoraban recursos y resultados de instalación |
| Recursos de aplicaciones | Master/GPU usan el ejecutable validado en su ubicación original, con sus recursos; desaparecen copias intermedias sin verificación | No separar Crystal/FurMark de sus archivos auxiliares ni escribir archivos innecesarios |
| GPU Check y dependencias | Se elimina el winget directo; el contrato común usa el ejecutor nativo, el WinGet resuelto, fuente explícita, plazo y resultado | Evitar instalaciones incondicionales o esperas sin el contrato de operación |
| Fallo de instalador | USB y FastCopy no vuelven a aceptar por otra ruta archivos dejados por una instalación fallida; los candidatos adicionales se conservan al resolver después de un éxito | Un archivo parcial no prueba una instalación terminada |
| PATH, IA y NVIDIA | Selección de una aplicación real, descartando directorios y funciones; telemetría incompleta no se interpreta | Evitar arrays de rutas y colas de salida confundidas con respuestas completas |
| Consultas CIM | Se añaden plazos operativos de 10 s a las 32 llamadas restantes de inventario y snapshot de servicios; guard AST transversal | Cubrir las rutas simples y auxiliares, además de los diagnósticos avanzados |
| DNS del Router | Las tres consultas síncronas usan espera acotada; las búsquedas inversas son opcionales durante los primeros 10 s del escaneo, con 300 ms por espera y máximo cuatro tareas pendientes | Un nombre de equipo no debe detener el inventario; un timeout no demuestra corrupción de DNS ni caída de Internet |
| Políticas locales y versión de PowerShell | Se saca Get-AtlasPowerShellVersion del texto C# y se deja como función real; prueba de compilación del C# de políticas | El bloque anterior no compilaba y el helper no estaba definido; los mocks previos no lo detectaban |
| Salida nativa truncada | Versiones de PowerShell/WinGet, búsqueda de paquetes, verificación de runtimes, activación y NVIDIA rechazan respuestas incompletas; GPU no analiza ayuda truncada | El límite de memoria no debe convertir la cola conservada en una respuesta completa |
| Menú y textos | El menú final de Master consulta correctamente la propiedad de su objeto de dependencias; FastCopy anuncia muestra SHA-256 | Corregir un fallo del consumidor y textos MD5 desfasados |

No se añaden dependencias ni un segundo sistema de instalación. Se conservan las
27 herramientas, el contrato PowerShell 5.1/x64, el dominio público y las decisiones
del propietario sobre aplicaciones y firma. El USB físico no cambia por publicar:
su actualización sigue siendo una operación explícita de Preparar USB.

## Qué comprueban las regresiones

Se cargan las funciones reales por AST sin ejecutar sus menús. Los fixtures prueban
Master con recursos vacíos, GPU en reposo sin instalación de FurMark, rutas offline,
archivos parciales tras timeout, resolución después de éxito y FastCopy sin reintento
alternativo. También ejercitan cantidades desconocidas, el acceso real del menú,
aplicaciones de PATH, el informe DNS con timeout y la salida NVIDIA truncada.

Una comprobación transversal recorre todos los scripts de producción: no permite
Get-WmiObject, llamadas CIM sin plazo (salvo el splat explícitamente comprobado de
IA), winget directo ni DNS síncrono. La prueba de políticas compila el texto C# real
bajo un namespace de prueba; no llama a la API de cuentas ni cambia políticas del
host. La prueba de versión ejecuta el helper real con el proceso externo simulado.

La suite completa comprueba además distribución reproducible, manifiesto,
hashes, wrappers, WPF, compatibilidad sintáctica y regresiones anteriores. Los
resultados definitivos y la promoción del SHA exacto se registran en la PR de esta
entrega, después de las suites locales y CI.

Resultado local: **411 pruebas aprobadas en cada runtime**, PowerShell
5.1.26100.9711 y 7.6.9, cero fallos, omitidas o errores del analizador. Permanecen
280/298 advertencias del analizador respectivamente; no se presentan como cero
deuda. Los artefactos quedaron reproducibles y sin cambios durante ambas suites.
Los enlaces locales de 50 archivos Markdown pasaron. Se comprobó además la lectura
real de políticas y la consulta de versión desde 5.1, sin modificar políticas.
[Evidencia de comprobaciones](CIERRE-TRANSVERSAL-1.5.18-2026-10-27.json).
Manifiesto: `84a429f8aa5f3b282fb2bb06fe997800652479b9df77128b75881cf12b9505ec`.

## Límites que se conservan explícitos

OperationTimeoutSec limita la operación CIM; no constituye una garantía universal
de tiempo de pared para cualquier proveedor o reconexión de Windows. La API DNS
compatible con .NET Framework permite limitar la espera del llamador, pero no
cancelar la resolución subyacente; por eso también se limita la acumulación de
tareas pendientes. Un resultado TimedOut/NotEvaluated no se presenta como éxito.
Referencias: [Get-CimInstance en 5.1](https://learn.microsoft.com/powershell/module/cimcmdlets/get-ciminstance?view=powershell-5.1)
y [Dns.GetHostEntryAsync](https://learn.microsoft.com/dotnet/api/system.net.dns.gethostentryasync?view=netframework-4.8).

Las [mediciones de inicio](FASE-5-AUDITORIA-2026-10-27.md) siguen siendo procesos
nuevos con caché del host existente. No se reinicia ni vacía la caché del PC para
simular un arranque frío. No se promete el mismo tiempo en equipos de clientes.

El plan de software queda separado de la aceptación física: Windows 10 continúa
sin homologación completa, VMs pausadas, instalaciones/recuperaciones reales y
hardware adicional pendientes de entorno apropiado. Firma pública aplazada y
derechos comerciales/redistribución no acreditados. Las observaciones futuras del
informe por herramienta no autorizan por sí solas operaciones reales sobre discos,
cifrado, cuentas, seguridad o red. Véase la [guía de aceptación](../TRABAJO-AUTONOMO-Y-ACEPTACION.md).
