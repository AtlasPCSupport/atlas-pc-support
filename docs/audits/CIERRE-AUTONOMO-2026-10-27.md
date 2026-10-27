# Cierre del bloque autonomo y limites de aceptacion

Fecha: 27/10/2026. Entrega: Atlas 1.5.12. Este cierre recoge el trabajo
revisable sin reanudar VMs ni trasladar operaciones de sistema al host. No declara
que todo el software carezca de defectos ni que la aceptacion integral este terminada.
La version publica efectiva y sus pins se verifican en la PR de la entrega.

## Trabajo terminado y trazable

| Bloque | Resultado y referencia |
|---|---|
| Implementacion del plan inicial | Fases y alcance en [cierre inicial](CIERRE-PLAN-2026-10-24.md) y [seguimiento](SEGUIMIENTO-2026-10-25.md); esas fotografias historicas no se reescriben como resultados nuevos |
| Dependencias, procesos e informes | [Sin VMs](SIN-VM-2026-10-25.md), [operacion y recuperacion](../OPERACION-Y-RECUPERACION.md) y contratos del [inventario de las 27 herramientas](../INVENTARIO.md) |
| RAM, CPU/red y almacenamiento | [RAM](RAM-2026-10-26.md), [CPU/asesor](CPU-Y-ASESOR-2026-10-26.md), [almacenamiento](ALMACENAMIENTO-2026-10-26.md): datos ausentes/parciales y limites de las inferencias |
| USB propia NTFS | [Ensayos](USB-2026-10-26.md), [reconexion](USB-RECONEXION-2026-10-26.json) y [upgrade/rollback 1.5.9](USB-1.5.9-2026-10-26.json); esto no actualiza por si solo las copias fisicas a 1.5.12 |
| Copias desde el panel | [Completa, incremental y restauracion](COPIA-MANUAL-2026-10-27.md), [siete hashes de restauracion](RESTAURACION-ARCHIVOS-2026-10-27.json); origen y respaldo conservados |
| Bateria y paquete propio | [1.5.12](BATERIA-Y-DISTRIBUCION-2026-10-27.md): valores desconocidos, parejas por bateria, estado de carga, fallback y LICENSE propio verificado |
| Firma y permisos | [Firma aplazada](FIRMA-OPCIONES-2026-10-26.md) y [alternativa profesional no adoptada](PROPUESTA-USO-PROFESIONAL-2026-10-26.md); apps conservadas, permisos externos pendientes |

## Arranque observado

El propietario observo 15–20 s en una apertura y unos 4 s en la segunda apertura
de 1.5.10. Un perfil local separado encontro unos 4,14 s en la deteccion de
capacidades; las otras etapas se midieron individualmente con cache existente.
Ese perfil no midio primer pintado ni arranque frio completo y no predice tiempos
en PCs de clientes. No se redujeron verificaciones ni protecciones para mejorar
la cifra. El arranque en hardware lento sigue siendo una observacion practica
pendiente, no un compromiso de cuatro segundos en cualquier equipo.

## Dependencias externas que siguen abiertas

| Dependencia | Aceptacion pendiente | Lo que puede continuar el agente cuando exista el entorno |
|---|---|---|
| VM desechable autorizada y elevaciones del propietario | Windows 10 Home/Pro, Enterprise LTSC e IoT por separado; build/parches; instalaciones, cuentas/UAC, BitLocker, red, servicios y reinicios | Preparar paquete QA nuevo, una VM a la vez, snapshot, ejecutar casos y verificar la reversion |
| Otro extremo autorizado | Instalacion/upgrade y conexion real de RustDesk con el servidor y equipo de prueba previstos | Preparar comandos y contrastar version, servicio, configuracion persistente y resultado de la sesion |
| Hardware/medios y manipulacion fisica | Otros equipos, baterias/sensores, NTFS/exFAT/FAT32, ACL, espacio agotado y cortes de energia en medios desechables | Preparar fixtures y verificadores; comprobar identidad antes de escribir y recoger resultados reales |
| Decisiones y permisos del propietario/proveedores | Custodia, destinatarios, consentimiento/retencion de informes y derechos de uso/redistribucion de terceros | Documentar el criterio elegido y revisar cada proveedor/version sin publicar credenciales o datos de clientes |

Las VMs permanecen pausadas. Windows 10 no esta homologado por completo.
La firma publica queda aplazada; no se inicia una compra o solicitud. La
disponibilidad gratuita de una app no se presenta como aprobacion de sus derechos
para servicio tecnico o entrega a clientes. Las decisiones ya dadas no se vuelven
a preguntar como si estuvieran sin responder.

## Deuda que conserva su alcance

Los avisos del analizador, catches tolerantes y llamadas heredadas se mantienen
visibles para mantenimiento gradual. Un aviso no demuestra por si solo un defecto
ni se silencia para anunciar cero deuda. La revision de esta entrega se limita a
los fallos reproducidos y contratos comprobados; una nueva incidencia concreta
puede justificar otra correccion autonoma. No hace falta repetir copias pequenas
para declarar que terminaron esos ensayos, ni sustituir pruebas de recuperacion
real por mas mocks.

Guia vigente: [trabajo autonomo y aceptacion](../TRABAJO-AUTONOMO-Y-ACEPTACION.md).
Escenarios completos: [pendientes](PENDIENTES-2026-10-25.md).
