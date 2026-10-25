# Cierre de implementación y aceptación pendiente

Continuación: [seguimiento autónomo del 25 de octubre](SEGUIMIENTO-2026-10-25.md).
El estado de esta fotografía 1.4.1 se conserva; las correcciones posteriores se
documentan en el seguimiento y sus evidencias.

Fecha: 24 de octubre de 2026. Candidata: **Atlas 1.4.1**. Informe de origen:
[auditoría](AUDITORIA-2026-10-24.md). Se han recorrido las fases 0–5 con entregas
separadas. Los controles implementados y las restricciones reducen los fallos
identificados, pero **la aceptación integral del plan no está completada**:
faltan VMs Windows 10, pruebas de operaciones reales y decisiones de terceros.

## Entregas trazables

| Fase | Entrega / PR | Evidencia |
|---|---|---|
| 0 | [Base y restricciones, #149](https://github.com/AtlasPCSupport/atlas-pc-support/pull/149) | 15 regresiones base y 4 casos rojos críticos, conservados después como aceptación |
| 1 | [Operaciones críticas, #150](https://github.com/AtlasPCSupport/atlas-pc-support/pull/150) | 95 pruebas por runtime; instaladores, cuentas y recuperación previa a cifrado |
| 2 | [Distribución, #151](https://github.com/AtlasPCSupport/atlas-pc-support/pull/151) | Conjunto íntegro online/offline, runtime y publicación por commit |
| 3 | [Windows 10 por capacidades, #152](https://github.com/AtlasPCSupport/atlas-pc-support/pull/152) | 150 pruebas por runtime; WPF real en host 26100, fixtures Windows 10 |
| 4 | [Operaciones y diagnóstico, #153](https://github.com/AtlasPCSupport/atlas-pc-support/pull/153) | 176 pruebas por runtime; CI final 40141920150 y main 40142297667 correctos; 47 comprobaciones HTTP |
| 5 | [Operación y entrega](FASE-5-2026-10-24.md) | Evidencia final en FASE-5-EVIDENCIA; CI y publicación se identifican en la entrega del PR |

La fase 4 promovió `75731b29a4c2f26c0508d017af56563e17324c11`, manifiesto
`298addd09fe4b69dac709ca08f5f861883d3aee55b24d9f7a14f165bdec5a603`, Worker
`8a2cb9a2-a71a-46de-a014-81574f08e3e7`. El commit de publicación puede diferir del
merge: se publica el SHA probado explícitamente. La fase 5 conserva este mecanismo.

La fase 5 se integró en [#154](https://github.com/AtlasPCSupport/atlas-pc-support/pull/154)
como 1.4.0; la revisión 1.4.1 corrige únicamente el indicador de carga del monitor
que mostraba una clave sin traducción. Se conserva el flujo y sus comprobaciones.
Se detectó Hyper-V en este host, pero la sesión no tiene permiso para inventariar
sus máquinas; eso no aporta evidencia de una VM Windows 10 ejecutada.

## Aceptación por criterio

«Implementado» se refiere al código y pruebas indicadas; no equivale a haber
ejecutado una mutación en un PC cliente. El inventario de las 27 herramientas está
en [INVENTARIO](../INVENTARIO.md); diferencias y restricciones en la
[matriz](../SUPPORT-MATRIX.md).

| ID | Implementado o restringido | Falta para aceptación completa |
|---|---|---|
| A01 | Hash obligatorio y firma Microsoft para MSI PS7, mismo contrato offline; fallos negativos bloquean ejecución | Instalación real/upgrade en VM; autenticidad y versión de binarios de terceros ya instalados requieren evaluación adicional |
| A02 | SID, último admin habilitado, protección de cuenta del proceso y errores reales; regresiones | UAC con otra identidad y acceso de recuperación comprobado en VM |
| A03 | Protector correcto y archivo externo verificado antes de solicitar cifrado; no se presume escrow | vTPM, reinicio, recuperación ensayada, AD/Entra/políticas y configuraciones de almacenamiento reales |
| A04 | Ejecutor común con salida/código/timeout y árbol propio; rutas con espacios en runners | No todas las invocaciones heredadas están migradas; cancelación y contratos de cada binario requieren más integración |
| A05 | Falsos éxitos concretos de WinGet/GPU/copia/eventos/IA corregidos; cobertura y no evaluado visibles | Heurísticas restantes, mensajes localizados de herramientas externas y todos sus estados no se homologaron exhaustivamente |
| A06 | Release completo e inmutable, autoridad de despliegue independiente y refs inválidos fallan | Firma Authenticode de Atlas y confianza offline frente a sustitución de toda la USB necesitan un esquema de firma/clave confiable; hashes solos no resuelven ese escenario |
| A07 | Catálogo central fijado/source-managed, runtime y helpers en hijo | Revisar derechos laborales/redistribución por proveedor y actualizar FastCopy 5.11.2 después de decidir edición/licencia; no se declara actualizado a 5.12 |
| A08 | Staging, verificación de 33 miembros/27 scripts, puntero atómico, rollback y corrupción probada | USB física, NTFS/exFAT/FAT32 y cortes de energía; sistemas sin File.Replace fallan conservando el puntero previo |
| A09 | Builds/ediciones/arquitecturas/comandos y UI por capacidades; fixtures Home/Pro/LTSC | Matriz Windows 10 19044/19045 ejecutada; compatibilidad PS7 positiva por herramienta cuando se habilite |
| A10 | Exclusiones reales, muestra vacía/corrupta fallan, cobertura parcial explícita, verificación nativa FastCopy | Copias grandes/interrumpidas, ACL/enlaces, varios orígenes y destino existente en VM/USB; mover/sincronizar FastCopy restringido |
| A11 | Snapshots DNS IPv4/IPv6/origen y servicios; Hosts exacto con backup; una cola | Interrupciones, fallo parcial y restauración reales; reinicio Spooler/impresoras físicas y tareas DNS antiguas revisadas |
| A12 | Provider+ID, fallo de consulta no es log sano, /24 estricto, WAN desde LAN no concluyente, confianza de hardware limitada | Sensores/proveedores/hardware reales; validación del catálogo de interpretación de eventos y recomendaciones aún manual |
| A13 | IDs/fuentes validados, Store por usuario/LTSC, runtimes separados, NetFx3 nativo y sin Prefetch | Comprobar OS mínimo, disponibilidad, versión y reinicio de las 52 apps del catálogo vigente en los perfiles objetivo |
| A14 | 21 tests Worker, lock fijado y npm audit sin vulnerabilidades, rutas/caché/refs comprobados | El repositorio privado de onboarding y alcance efectivo de su PAT requieren auditoría separada; no se imprimieron secretos |
| A15 | Gate de publicación sobre SHA actual, los tres jobs, diff sensible completo/renombres; 9 regresiones de política y CODEOWNERS | Revisión humana continuada y configuración de protección de rama; no se modificaron reglas de organización ni se las supone más fuertes de lo observado |
| A16 | Tarjeta deshabilitada con causa; backend ausente no se ejecuta | Decidir si se integra backend reproducible con borrado reversible o se retira definitivamente |
| A17 | Reportes compartidos redactados y trazables; checklist persistente; sin escrow/activación inferidos | Revisar texto libre y reportes externos; ensayo de entrega completo con cliente ficticio y custodia/retención acordadas |
| A18 | Lecturas del monitor fuera del dispatcher, tarjetas ES/EN y búsqueda coherente; inventario generado; menos código duplicado y docs CI únicas | Pruebas de interacción en VMs y accesibilidad; otras traducciones y consolidación restante de inventarios son deuda explícita |

## Próxima aceptación práctica

1. Preparar VMs licenciadas 19045 Home, 19045 Pro y 19044 LTSC/IoT, con snapshots y
   datos ficticios. Registrar build exacta y parches, sin extrapolar `windows-latest`.
2. En cada VM, ejecutar el runner 5.1, abrir el panel con Defender activo, comprobar
   tarjetas y cancelaciones, identidad UAC, Store/WinGet y funciones no aplicables.
3. En Pro con vTPM y segundo disco, ensayar activación, reinicio y recuperación de
   BitLocker. Repetir fallos de backup/política; nunca usar un disco de cliente.
4. Probar DNS DHCP/estático dual, dependientes de servicios, Hosts multialias, colas,
   copias interrumpidas y USB offline. Conservar estado anterior y resultado real.
5. Homologar las apps realmente usadas y licencias de terceros; el número 52 es
   inventario del catálogo, no una certificación. Elegir edición FastCopy o usar
   Robocopy nativo según derechos y necesidades.
6. Revisar onboarding privado, esquema de firma y advertencias del analizador por
   impacto. Mantener hallazgos sin resolver en vez de silenciarlos para publicar.

No se crearon VMs ni se ejecutaron reparaciones, cifrado, limpieza de colas o
cambios de cuentas sobre este host. La evidencia real disponible es host 26100,
fixtures, WPF, procesos hijos inocuos, CI y publicación verificada. El manual de
[operación y recuperación](../OPERACION-Y-RECUPERACION.md) permite continuar la QA
sin depender del historial de este chat.
