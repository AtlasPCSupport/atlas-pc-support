# Inventario generado de Atlas PC Support

Generado desde `config/tools.json` y `config/dependencies.json`. No editar a mano.
Regenerar: `pwsh -NoProfile -File tests/Update-ToolDocumentation.ps1`.

Entradas: **27**. Plataforma base: cliente Windows x64 build 19044+.
El contrato describe requisitos; no certifica todas las operaciones en cada edición.
PowerShell 5.1 es el runtime predeterminado. Las pruebas Win10 en VM figuran pendientes en el cierre del plan.

| ID / herramienta | Función y alcance | Requisitos | Disponibilidad |
|---|---|---|---|
| fase-0 / Inspeccionar túneles IPv6 / Legacy IPv6 Tunnel Inspection | Consulta de túneles heredados. Presets de cambio y restauración restringidos hasta validar reversión exacta. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| parts-upgrade / Inventario para ampliaciones / Parts Upgrade Advisor | Observaciones de RAM, CPU y almacenamiento. Confirmar compatibilidad y posibilidades de ampliación con el fabricante. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| diagnostico-master / Informe del sistema / Full System Report | Inventario y observaciones de sistema, hardware, eventos y red. Reporte redactado; no certifica salud completa. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| diagnostico-eventos / Analizar eventos / Event Log Analyzer | Correlaciona proveedor e ID y conserva nivel numérico. Acceso denegado se muestra como no evaluado. | x64; windows-powershell >= 5.1; build >= 19044; Get-WinEvent | Según capacidades; comprobar políticas y permisos de la operación. |
| printer-doctor / Diagnóstico de impresoras / Printer Doctor | Consulta impresoras, puertos, trabajos y eventos. Vacía una cola elegida y comprueba el resultado. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| keyboard-doctor / Diagnóstico de teclado / Keyboard Doctor | Observaciones de dispositivos y eventos. Prueba con foco y consentimiento que cuenta pulsaciones sin guardar texto. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| ai-readiness / Inventario para IA / AI Readiness Inventory | Inventario y heurísticas orientativas. Datos ausentes quedan sin evaluar; no se certifica un modelo ni servicio. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| gpu-check / Observaciones de GPU / GPU Check | Inventario, telemetría NVIDIA disponible y eventos. Prueba de carga opcional; resultados con cobertura limitada. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| mantenimiento-pro / Comprobar y reparar Windows / Inspect and Repair Windows | Inspecciona Defender y reinicio pendiente. DISM/SFC elegidos; sin limpieza masiva ni reset de red automático. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| instalar-paquetes / Instalar aplicaciones con WinGet / Bulk App Installer (WinGet) | Catálogo y perfiles con IDs/fuentes validados. Compatibilidad final sujeta al manifiesto vigente de cada paquete. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| instalar-ms-store / Comprobar Store y App Installer / Store and App Installer Check | Distingue paquete, registro, usuario y políticas. Solo registra una Store existente; no instala Store genérica en LTSC. | x64; windows-powershell >= 5.1; build >= 19044; Get-AppxPackage, Add-AppxPackage | Según capacidades; comprobar políticas y permisos de la operación. |
| instalar-runtimes / Dependencias de ejecución / Runtime Dependencies | VC++ v14 separado de legado. NetFx3 mediante Windows con origen opcional; indica código y reinicio requerido. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| actualizar-powershell / Instalar PowerShell 7 / Install PowerShell 7 | Instala la versión x64 fijada tras verificar SHA-256 y firma Microsoft. Las herramientas conservan su runtime declarado. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| mod-personalizacion / Ajustes de Windows / Windows Settings | Abre fondo, colores, barra y menú Inicio nativos. Sin presets de registro, marca de agua ni reinicio de Explorer. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| stop-services / Servicios con respaldo / Services with Snapshots | Inspecciona una lista restringida; cambia uno con snapshot previo y restaura inicio, ejecución y arranque diferido. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| fastcopy / Copiar con FastCopy / FastCopy | Copia con verificación nativa y muestreo SHA-256 identificado. Mover/sincronizar restringido; revisar licencia del proveedor. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| preparar-usb / Preparar USB offline / Build Verified Offline USB | Copia el release íntegro y verificado de 27 herramientas. Actualización atómica explícita; paquetes de terceros opcionales. | x64; windows-powershell >= 5.1; build >= 19044 | Según capacidades; comprobar políticas y permisos de la operación. |
| respaldo-controladores / Respaldar controladores / Driver Backup (DISM) | Exporta controladores con DISM a un destino elegido. No ejecuta un BAT externo elegido desde el escritorio. | x64; windows-powershell >= 5.1; build >= 19044; admin; Export-WindowsDriver | Según capacidades; comprobar políticas y permisos de la operación. |
| robocopy / Copiar con Robocopy / Robocopy Copy | Copia con exclusiones y códigos de resultado. La muestra SHA-256 no equivale a verificación integral del contenido. | x64; windows-powershell >= 5.1; build >= 19044; robocopy.exe | Según capacidades; comprobar políticas y permisos de la operación. |
| selector-dns / DNS con restauración / DNS with Restoration | Perfiles DNS clásicos, snapshot IPv4/IPv6 y origen automático/estático. DoH solo si Windows y cmdlets lo permiten. | x64; windows-powershell >= 5.1; build >= 19044; admin; Get-NetAdapter, Get-DnsClientServerAddress, Set-DnsClientServerAddress | Según capacidades; comprobar políticas y permisos de la operación. |
| hosts / Editar Hosts / Hosts File Editor | Cambios de alias exactos y reemplazo con respaldo de bytes originales. Importaciones requieren revisión. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| auditoria-router / Observaciones de router y LAN / Router and LAN Observations | Escaneo heredado solo de /24. La prueba desde LAN no certifica exposición WAN; sin exportación de claves Wi-Fi. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| gestor-bitlocker / Administrar BitLocker / BitLocker Manager | Activación exige respaldo de recuperación verificado en otro disco. Suspensión delegada a Windows; escrow no se presume. | x64; windows-powershell >= 5.1; build >= 19044; admin; Get-BitLockerVolume, Enable-BitLocker | Según capacidades; comprobar políticas y permisos de la operación. |
| menor-privilegio / Cuentas con mínimo privilegio / Local Account Hardening | Audita cuentas locales y protege al último administrador habilitado. Cambios y fallos se comprueban por SID. | x64; windows-powershell >= 5.1; build >= 19044; admin; Get-LocalUser, Get-LocalGroupMember | Según capacidades; comprobar políticas y permisos de la operación. |
| extraer-licencias / Inventario de licencias / License Inventory | Estado local Windows/Office y reportes redactados. Revelar clave OEM y copiarla son acciones explícitas separadas. | x64; windows-powershell >= 5.1; build >= 19044; admin | Según capacidades; comprobar políticas y permisos de la operación. |
| deduplicador / Deduplicador no disponible / Deduplicator Unavailable | Backend no incluido. No se ejecuta conversión ni borrado hasta integrar y probar recuperación. | x64; windows-powershell >= 5.1; build >= 19044 | Backend is absent from this release. No unverified localhost service or global Python installation will be started. |
| entrega-pc / Entrega del equipo / PC Handover Report | Checklist manual persistente, informe redactado y trazabilidad de versión. No certifica activación ni escrow de recuperación. | x64; windows-powershell >= 5.1; build >= 19044; admin; Get-LocalUser | Según capacidades; comprobar políticas y permisos de la operación. |

## Dependencias

Cada proveedor conserva su licencia. MIT de Atlas no autoriza redistribuir binarios de terceros.

| Dependencia | Versión/origen | Arquitectura | Validación | Licencia |
|---|---|---|---|---|
| CrystalDiskMark |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| CPUZ |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| BlueScreenView |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| HWiNFO |  / winget/source-managed | x64 | package-manager | Vendor personal/non-commercial and Pro/commercial terms differ; workplace/redistribution rights must be reviewed. Not licensed by Atlas. |
| FurMark2 |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| GPUZ |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| CrystalDiskInfo |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| FastCopy | 5.11.2 / pinned-direct-fallback; winget source may be newer | x64 | sha256-required | Workplace use requires vendor commercial/Pro licensing; review the exact installed version and redistribution rights. Not licensed by Atlas. |
| winget |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| BatteryInfoView |  / winget/source-managed | x64 | package-manager | Vendor terms; redistribution not approved by Atlas |
| PowerShell7 | 7.6.6 / pinned | x64 | sha256-and-microsoft-authenticode | MIT; third-party notices apply |
