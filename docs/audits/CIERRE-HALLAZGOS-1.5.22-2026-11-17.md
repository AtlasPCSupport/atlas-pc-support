# Resolución de hallazgos de la auditoría 1.5.21

Alcance autorizado: A01–A12 del [informe del 17/11](AUDITORIA-INTEGRAL-1.5.21-2026-11-17.md).
Windows 10 queda fuera de este ciclo por instrucción del propietario. No se
reanuda el laboratorio ni se altera su aceptación histórica.

Verificación posterior: **1.5.23** completa A07 con una regresión adicional para
consultas de eventos realmente vacías: se muestran cero elementos, conservando
`NotEvaluated` solo para fallos de consulta. El caso nuevo falló antes del cambio y
pasó después. La entrega adicional se registra en
[PR 186](https://github.com/AtlasPCSupport/atlas-pc-support/pull/186); los resultados
de 1.5.22 de este documento/JSON conservan su versión y alcance originales.

## Cambios por hallazgo

| Hallazgo | Resolución implementada | Evidencia y límite |
|---|---|---|
| A01 | WHEA 19/46 corregidos en ambos idiomas; revisión conservadora de 1/17/18; retirada de explicaciones por ID genérico y de Kernel-Boot 134 sin contrato fiable. La búsqueda manual pide proveedor; eventos desconocidos conservan sus datos originales. | Tablas reales y lookup en `Reports.Tests.ps1`; HTML mantiene la severidad del evento, independiente de la tabla. No diagnostica automáticamente una pieza defectuosa. |
| A02 | El BAT no usa Bypass/Unrestricted ni elimina MotW; el archivo descargado se ejecuta respetando la política efectiva. | Guardas y regresiones del payload real. Un equipo que exige firma puede bloquearlo; no se elude su política. |
| A03 | Guía de onboarding reescrita: pins actuales, promoción por SHA, custodia y diagnóstico sin exclusiones AV ni promesas de SmartScreen; derechos de AnyDesk aclarados. | `onboarding/README.md`. No se cambia una política ni se compra firma/licencia. |
| A04 | Cada intento usa GUID bajo Program Files; se validan propietario/ACL y ausencia de enlaces en ancestros. ACL final solo Administradores/SYSTEM. Lock de intento y apertura de solo lectura compartida durante la ejecución. | Regresiones de directorios, hash alterado, concurrencia/repetición y rechazo de escritura sobre bytes verificados. Otra identidad UAC e instalación real siguen siendo aceptación externa. No constituye aislamiento frente a otro administrador. |
| A05 | La ruta del BAT se transporta como variable de entorno y se lee como dato; no se inserta en código PowerShell entre comillas simples. | La llamada real de elevación se extrae y ejecuta con frontera de proceso simulada y ruta con apóstrofe/espacios/ampersand. No se acepta UAC automáticamente. |
| A06 | Estado separado para idioma aplicado y preferencia pendiente. Volver al idioma original guarda la elección; si falla otra escritura se restaura la última selección guardada. | Secuencia real del handler en `Language.Tests.ps1`; almacenamiento existente preservado. |
| A07 | Entrega muestra `NotEvaluated` para fallos de red/Defender; ausencia observada y protección desactivada tienen estados diferentes. Eventos HTML también identifica fallo de lectura de Security. | Consultas reales aisladas con dobles; HTML del informe de eventos generado y comprobado sin datos privados. |
| A08 | Campos estructurados de versión y versiones explícitamente etiquetadas en texto/HTML se conservan; IPv4/IPv6 e identificadores siguen redactándose. | Regresiones positivas/negativas de JSON y texto. El texto libre requiere revisión antes de compartir. |
| A09 | Etiquetas de cola seleccionada, ajustes de accesibilidad, monitor de conteo con foco, ajustes Wi-Fi y dashboard bajo demanda alineadas con la acción. | Revisión de consumidores en español/inglés; sin volver a habilitar acciones antiguas. |
| A10 | `netsh` usa plazo de 10 s y resultado evaluable. GPU Check confirma salida del proceso propio con esperas limitadas; fallo de cierre se registra y no permite una sesión limpia. | Dobles de cierre denegado y cierre real de un hijo inofensivo; no se ejecuta estrés de GPU. |
| A11 | La guarda analiza el payload del BAT y rechaza eliminación de procedencia/política débil. Regresiones ejecutan la lógica con descarga/ejecución aisladas: hash, bloqueo, concurrencia y propagación del error. | `Test-SecurityGuards.ps1` + `Execution.Tests.ps1`. Las verificaciones no equivalen a instalación/conexión RustDesk real. |
| A12 | README de Wrangler coherente con pin/lock; repositorio público canónico en Worker, transporte y branding; README del dashboard y guía de nuevas herramientas actualizados. | Se conserva Wrangler 4.154.0: la auditoría no informó vulnerabilidades conocidas; 4.164.0 es una actualización revisable, no un arreglo obligatorio. El lock no se altera sin motivo. Informes históricos conservados. |

## Verificación

Las pruebas completas, CI y publicación de esta entrega se registran por commit
en la [PR de entrega](https://github.com/AtlasPCSupport/atlas-pc-support/pull/185).
El descriptor del dominio identifica la publicación efectiva; un commit o esta
nota no la sustituyen. El [JSON de cierre](CIERRE-HALLAZGOS-1.5.22-2026-11-17.json)
conserva las comprobaciones locales por intento. La publicación se promueve solo
después de los jobs `build`, `windows-compat` y `worker` aprobados sobre el mismo SHA.

Se conserva el enlace `https://toolspanel.atlaspcsupport.com`. Defender/AMSI permanecen
activos; no hay nuevas exclusiones, cambios de grupos, formateos ni uso de discos
físicos para suplir pruebas del laboratorio.

## Pendientes externos y decisiones conservadas

Este cierre corrige los defectos de software/documentación enumerados. Las
instalaciones, reinicios, recuperaciones, identidad alternativa de UAC, AD/Entra y
sensores/hardware reales necesitan sus propios escenarios autorizados. No se dan
por realizados con mocks. Windows 10 fue excluido expresamente de este objetivo.

La firma de pago sigue aplazada. HWiNFO/FastCopy y redistribución de GPU-Z conservan
sus condiciones de proveedor; usar pocas veces una app no acredita licencia
profesional. No se compran permisos ni se sustituye software automáticamente.

Las advertencias de estilo continúan como deuda gradual; este trabajo no promete
cero avisos ni una reescritura. Las mejoras opcionales del informe —hardware lento,
benchmark amplio, VSS, firma o backend del deduplicador— no se convierten en
funcionalidades implementadas por cerrar A01–A12.
