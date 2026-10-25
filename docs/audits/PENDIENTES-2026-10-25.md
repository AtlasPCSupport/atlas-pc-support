# Aceptación que falta después de Atlas 1.5.2

Las fases de implementación y publicación se completaron con entregas por commit.
Eso no cierra la aceptación operativa ni equivale a ejecutar todas las acciones
con clientes reales. El seguimiento de cambios está en
[SEGUIMIENTO](SEGUIMIENTO-2026-10-25.md); esta lista actualiza los pendientes de la
fotografía 1.4.1 sin confundirlos con código todavía sin implementar.

| Prioridad | Pendiente | Qué falta demostrar | Cómo se puede cerrar |
|---|---|---|---|
| 1 | Windows 10 real | Home/Pro 19045 y LTSC 19044; WPF, capacidades y entrada verificada con Defender activo | Laboratorio Hyper-V secuencial, con ISOs locales y logs por edición. La elevación UAC normal permite administrar Hyper-V sin cambiar grupos. En ejecución; los resultados se registrarán por escenario, no como certificación universal. |
| 1 | Cuentas y UAC | Otra identidad durante elevación, administrador de recuperación realmente utilizable, fallos de grupo/permisos | VM con snapshot y cuentas ficticias; fixtures ya aprobados no sustituyen inicio de sesión/recuperación. |
| 1 | BitLocker | vTPM, reinicio, recuperación desde otro disco, datos/OS, fallo de respaldo y políticas/escrow | VM Pro con vTPM y volumen de prueba; recuperación probada y evidencia redactada. No cifrar el host ni discos de cliente. |
| 1 | Restauraciones del sistema | DNS IPv4/IPv6 DHCP/estático, dependientes de servicios, Hosts multialias, cola/Spooler y fallos parciales | Ensayos en snapshot y reversión observada. Impresoras físicas y configuraciones AD/Entra requieren su propio entorno. |
| 1 | Copias y USB | Disco lleno/bloqueo, interrupción, múltiples orígenes, ACL y destinos existentes; USB NTFS/exFAT/FAT32 y pérdida de energía | VHDs desechables para fallos de archivos y USB física para el medio real. Mover/sincronizar FastCopy siguen restringidos. |
| 1 | RustDesk real | Instalación limpia, repetida, upgrade EXE/MSI, criterio histórico de fecha, servicio, conexión al servidor y configuración persistente | VM y validación del servidor autorizado. Script/download/ACL y CLI ya reforzados; 14 pruebas aisladas por runtime y CI no son una instalación real. |
| 1 | Aplicaciones | Instalar las aplicaciones usadas, fuentes/Store, versión instalada, reinicios y requisitos OS del paquete entregado | Pruebas por paquete y edición. La instantánea contiene 56 manifiestos WinGet y dos entradas Store; no garantiza las versiones futuras ni licencias. |
| 2 | Identidad y confianza de Atlas | Authenticode y confianza offline frente a sustitución de toda la USB | Certificado/identidad confiable y política de distribución. Un certificado autofirmado sin confianza previa no resuelve el problema. |
| 2 | Licencias y permisos externos | Uso laboral/redistribución de terceros, custodia/retención de informes y alcance efectivo del PAT privado | Decisión del propietario y revisión por proveedor. No comprar ni rotar credenciales a ciegas. FastCopy de respaldo ya está actualizado a 5.12.0. |
| 2 | Diagnósticos, UI y deuda | Sensores/CPU/GPU/batería reales, interpretación de eventos, accesibilidad/DPI/teclado y otras invocaciones heredadas | Equipos representativos y revisión por impacto. Persisten 310/329 avisos del analizador en 5.1/7; 131 catches vacíos y nombres de verbos son grupos que requieren distinguir tolerancia intencional de fallo ocultado. |
| 2 | Deduplicador | Backend y borrado reversible, si se decide ofrecer esa capacidad | La tarjeta ya está deshabilitada y explica la ausencia. Integrarlo es alcance adicional; no existe un motor verificado que pueda activarse sin más. |

## Orden práctico

1. Terminar la matriz de VMs y corregir cualquier fallo reproducible que aparezca.
2. Usar sus snapshots para cuentas, BitLocker, red, servicios y copias con fallos.
3. Validar RustDesk y un conjunto de aplicaciones realmente usadas antes de ampliar
   a todo el catálogo. Registrar casos bloqueados por cuentas/Store/licencias.
4. Completar hardware/USB física, licencias, identidad de firma y entrega ficticia.
5. Revisar heurísticas y deuda restante sin eliminar comprobaciones ni silenciar
   avisos para presentar una cifra cero.

El laboratorio guarda contraseñas aleatorias solo para sus cuentas desechables,
en medios de instalación restringidos y credenciales DPAPI locales. Nunca se
incluyen en Git, logs públicos, issues o evidencias compartidas. Los discos físicos,
la configuración de Defender y la publicación existente quedan fuera de sus
mutaciones. Una VM de Windows sin activar se identifica como tal; no se ejecutan
activadores ni se inventan derechos de licencia.

Referencias: [PowerShell Direct](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct),
[AutoLogon de despliegue](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon),
[matriz objetivo](../SUPPORT-MATRIX.md).
