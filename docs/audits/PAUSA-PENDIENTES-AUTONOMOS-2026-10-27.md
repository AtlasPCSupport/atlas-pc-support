# Punto de pausa solicitado por el propietario

Registro histórico del punto de pausa. El propietario autorizó retomar el bloque
el 29/10/2026. Estado posterior en
[cierre de herramientas 1.5.19](CIERRE-HERRAMIENTAS-1.5.19-2026-10-29.md).
Las secciones siguientes describen lo pendiente al pausar, no el estado vigente.

## Publicación estable

- Atlas 1.5.18 sigue publicada en el mismo dominio.
- Fuente publicada: d82f03bd36e3d2ab49f92f6f56d1907d8c84da2d.
- Manifiesto: 84a429f8aa5f3b282fb2bb06fe997800652479b9df77128b75881cf12b9505ec.
- PR 180 integrada; main base: 4b1874859998a361e60dce663909ffa2f995f000.
- VMs pausadas; Defender y datos del host se conservan. No se ejecutaron consultas
  de claves reales, escaneos LAN, instalaciones, cifrado ni recuperación reales.

## Trabajo local sin terminar

Rama: codex/pendientes-autonomos-herramientas. Tres fuentes modificadas y todavía
sin commit: Invoke-AuditoriaRouter.ps1, Invoke-GestorBitLocker.ps1 e
Invoke-InstalarRuntimes.ps1. No confundir estas candidatas con la publicación.

- Router: comparación pura por IP/MAC con cambios y MAC desconocida separados;
  parser de firmware con etiquetas explícitas, sin inferir firmware de hardware;
  ARP mediante ejecutor nativo con plazo; mensajes de MAC repetida corregidos;
  preservación de referencia en escaneos vacíos/con errores y escritura de
  referencia mediante temporal, lectura posterior y reemplazo.
- BitLocker: CLI y menú llaman a un exportador común con destino .txt explícito;
  validación de disco físico diferente para todos los registros antes de escribir;
  archivo nuevo y lectura posterior; valores ocultos por defecto, REVEAL/COPY
  explícitos, tarjetas solo por elección en la carpeta seleccionada; helper
  New-AtlasRecoveryCard sustituye el nombre QR; disposición de recursos gráficos;
  consulta dsregcmd mediante ejecutor nativo con plazo y rechazo de truncamiento.
- Runtimes: selección individual 1–5 para los componentes antiguos, cancelación
  vacía, validación antes de instalar y parada tras timeout/cancelación.

Única comprobación realizada sobre estas candidatas: AST válido y nombres de
funciones sin duplicados en las tres fuentes, antes de los últimos ajustes
pequeños de referencia/Entra. No hay aceptación de regresiones ni de publicación.
Los artefactos generados todavía corresponden a 1.5.18: no ejecutar el publicador
con estas modificaciones ni afirmar que están listos.

## Próximos pasos al recibir autorización para continuar

1. Revisar el diff y completar el tratamiento de errores y mensajes. Confirmar
   sustitución del bloque antiguo de guardado del módulo B de Router, contador
   de errores y disposición de Ping. Revisar que los mensajes AD/Entra distingan
   solicitud aceptada de escrow realmente verificado.
2. Actualizar tests/BitLocker.Tests.ps1: Save-AtlasRecoveryBackup ahora depende
   de Get-AtlasRecoveryBackupFolder y Write-AtlasRecoveryText; cargar las
   definiciones reales y Release para Assert-AtlasPlainDirectory. Añadir fixtures
   para exportación CLI/menú sin revelado implícito, destino requerido, prevalidación
   de todos los registros, archivos previos, lectura fallida y tarjeta opcional.
3. Añadir regresiones en Quality.Tests.ps1 para comparación IP/MAC, MAC desconocida,
   firmware/hardware/ambigüedad, ARP fallido/truncado, referencia anterior preservada,
   selección de runtimes y timeout. No ejecutar acciones reales en el host.
4. Revisar deuda por impacto: en BitLocker siguen asignaciones a $input que pueden
   renombrarse junto con su parámetro/callers. Limpiar espacios solo en archivos
   tocados. No renombrar indiscriminadamente verbos ni parámetros de eventos .NET
   para bajar cifras del analizador. Documentar deuda restante con recuento nuevo.
5. Revisar documentación vigente, preparar release siguiente, regenerar artefactos
   y ejecutar suites completas PS5.1/PS7, guards, build reproducible y enlaces.
6. Solo tras aprobar: commit/push, crear y adjuntar PR, CI del SHA exacto, promover
   en el Worker existente y verificar bootstrap, hashes, 34 miembros, entrada
   offline NoLaunch y Defender. Integrar main y comprobar pins tras merge.

## Notas para evitar repetir errores de edición

Los scripts temporales atlas-tools-followup-edit.ps1 y atlas-router-followup-edit.ps1
son scripts de mutación de una sola ejecución, NO controladores ni pruebas. No
volver a ejecutarlos sobre fuentes ya modificadas: pueden duplicar definiciones.
El segundo ahora carga solo la definición del helper de edición, sin ejecutar
el primero. No hay procesos de laboratorio iniciados por este bloque.

Los informes anteriores permanecen históricos. Windows 10 sigue sin homologación
completa; pruebas físicas, instalaciones/recuperación reales y firma/licencias
mantienen el estado acordado. Nada de eso se reanuda por este punto de pausa.
