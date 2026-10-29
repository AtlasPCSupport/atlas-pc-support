# Router, recuperación y runtimes — 1.5.19

Retoma el bloque pausado del 27/10 y cierra los ajustes adicionales de software
identificados después de 1.5.18. No reanuda VMs ni ejecuta reparaciones en el host.

## Cambios terminados

| Área | Cambio y motivo |
|---|---|
| Router: comparación | La misma IP con otra MAC es un cambio observado. MAC desconocida queda no comparable; una MAC con distinto separador/case conserva identidad. No se afirma que toda la red permanezca igual ni se identifica la causa del cambio. |
| Router: referencias | Un escaneo vacío o con errores conserva la referencia anterior. Escritura mediante archivo temporal, lectura posterior y reemplazo; si falla, no se anuncia persistencia. Sigue siendo una referencia de respuestas observadas, no inventario completo. |
| Router: ARP y firmware | ARP usa proceso acotado a 2 s, dirección exacta y salida completa; descarta MAC nula/broadcast. Firmware requiere etiqueta explícita y valor no ambiguo; hardware o «Version» genérica no lo acreditan. Sin recomendación automática por antigüedad no medida. |
| BitLocker: menú y CLI | Un solo exportador, destino .txt nuevo y explícito, validación de todos los volúmenes contra el disco físico de destino antes de escribir y lectura posterior. Se elimina el guardado automático en Desktop y la copia en todos los removibles. No se cifran ni descifran volúmenes para comprobar este cambio. |
| BitLocker: secretos | Claves ocultas por defecto. REVEAL, CARD, BACKUP y COPY son elecciones explícitas del menú; CLI exige Output y solo muestra valores con Reveal. No se incluyen claves en logs de operación. Un respaldo deliberado contiene secretos y debe custodiarse. |
| Tarjetas imprimibles | New-AtlasRecoveryCard reemplaza el nombre QR engañoso. No es un QR. Libera objetos gráficos; no sobrescribe una tarjeta previa y usa texto nuevo en la misma carpeta si el renderizado falla. |
| AD/Entra | Consulta dsregcmd con plazo de 10 s y rechazo de salida truncada. Mensajes distinguen solicitud aceptada de recuperación remota verificada; no basta un protector aceptado para informar que todos lo fueron. |
| Runtimes | Selección individual de los cinco componentes antiguos, sin repetición de IDs. Vacío cancela y entrada inválida no instala parcialmente. Timeout/cancelación detiene el resto. NetFx3 mantiene su ruta nativa independiente de WinGet. |
| Deuda por impacto | Se eliminan asignaciones a la variable automática input en BitLocker y se alinean sus consumidores. Se corrigen errores silenciosos de persistencia y el ámbito del log de BitLocker. Se limpia whitespace en las tres herramientas tocadas sin suprimir reglas del analizador. |

## Verificación y publicación

Las regresiones cargan definiciones reales por AST. Bloquean lectura de secretos,
cifrado, instalación, directorio corporativo, portapapeles y red reales. Incluyen
el flujo CLI y menú, archivos nuevos/previos, prevalidación de varios volúmenes,
cancelación, ocultación por defecto, fallback de impresión y compilación/ejecución
de consumidores. En Windows se genera una imagen real con una clave ficticia.

Las suites completas 5.1/7, guards, distribución reproducible, CI del commit exacto
y verificación pública preceden al cierre de la entrega. Los resultados definitivos
se incorporan aquí y a la PR, sin convertir mocks en homologación física.

Resultado local del 29/10: **434 pruebas aprobadas por runtime**, PowerShell
5.1.26100.9711 y 7.6.5 (runtime disponible en esta sesión), cero fallos, omitidas o
errores del analizador. Los artefactos permanecieron sin cambios durante ambas
suites. Worker 27/27, política CI 9/9, auditoría npm sin vulnerabilidades conocidas
y dry-run aprobados; enlaces locales de 52 archivos Markdown correctos.
Quedan **265/283 advertencias del analizador**, respectivamente; no se suprimieron
reglas para reducirlas. La reducción respecto de 1.5.18 no equivale a cero deuda.

La comprobación pública de la versión anterior confirmó las siete rutas y pins de
1.5.18, con Defender/tiempo real/servicio/antimanipulación activos. La promoción
de 1.5.19 requiere acceso GitHub/Cloudflare y CI remoto del SHA exacto; el número
de versión de esta nota no acredita que ya se haya publicado. La evidencia final
de push, CI y promoción se incorpora a la PR de esta entrega cuando se complete.
[Evidencia local estructurada](CIERRE-HERRAMIENTAS-1.5.19-2026-10-29.json).

## Qué sigue abierto

- Windows 10 por edición y parche, instalaciones/actualizaciones reales, reinicios,
  recuperación BitLocker, AD/Entra, drivers y hardware: requieren el entorno
  correspondiente. VMs siguen pausadas; Defender activo.
- Inicio en frío y rendimiento en equipos lentos adicionales: no medidos por esta
  entrega. Los datos anteriores siguen siendo procesos nuevos con caché del host.
- Firma pública aplazada y permisos comerciales/redistribución de terceros:
  mantienen las decisiones del propietario. No se compra ni solicita nada.
- Deuda gradual de las otras herramientas: quedan avisos de verbos, tolerancia
  deliberada de UI/sondas y otros catches que requieren evaluar su impacto. No se
  promete cero deuda ni se renombran APIs/eventos para bajar cifras.
- Deduplicador sin backend y mover/sincronizar FastCopy: conservan las restricciones;
  no se implementan como ampliación automática del producto.
- El USB físico no se actualiza al publicar. Preparar USB es una operación explícita
  y su reconexión/otros medios tienen aceptación separada.

[Guía de trabajo y aceptación](../TRABAJO-AUTONOMO-Y-ACEPTACION.md).
Fuentes oficiales consultadas: [respaldo de recuperación](https://support.microsoft.com/windows/security/encryption/back-up-your-bitlocker-recovery-key),
[BackupToAAD](https://learn.microsoft.com/powershell/module/bitlocker/backuptoaad-bitlockerkeyprotector),
[WinGet install](https://learn.microsoft.com/windows/package-manager/winget/install)
y [File.Replace](https://learn.microsoft.com/dotnet/api/system.io.file.replace).
