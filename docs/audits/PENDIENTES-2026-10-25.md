# Aceptación pendiente y trabajo sin VMs

Las fases de implementación y publicación se completaron con entregas por commit.
Eso no cierra la aceptación operativa ni equivale a ejecutar todas las acciones
con clientes reales. El seguimiento de cambios está en
[SEGUIMIENTO](SEGUIMIENTO-2026-10-25.md); esta lista actualiza los pendientes de la
fotografía 1.4.1 sin confundirlos con código todavía sin implementar.

La continuación sin VMs está detallada en [SIN-VM](SIN-VM-2026-10-25.md): se
corrigieron detección WinGet, límites de dependencias, cobertura/HTML del triaje
GPU, consultas heredadas de IA, accesibilidad básica y el checker público.
Dos ensayos de Robocopy real sobre archivos ficticios comprobaron copia incremental
y fallo de archivo bloqueado. Estos resultados no cierran la aceptación de
hardware, recuperación, USB ni instalaciones reales de terceros.

| Prioridad | Pendiente | Qué falta demostrar | Cómo se puede cerrar |
|---|---|---|---|
| Pausado | Windows 10 real | Home/Pro 19045 y LTSC 19044; WPF, capacidades y entrada verificada con Defender activo | El usuario pausó expresamente las VMs. Home mostró 240 pruebas locales aprobadas en una captura aportada por el usuario; el resumen general no se generó y la tarea terminó con 0xC000013A. No equivale a homologar Home, Pro, Enterprise LTSC ni IoT. No reanudar controladores ni consolas automáticamente. |
| 1 | Base parcheada y edición exacta | Repetir sobre la revisión acumulativa vigente y distinguir Enterprise LTSC de IoT Enterprise LTSC | Registrar build + UBR, canal, activación observada y cobertura de actualizaciones. Una ISO antigua o una VM IoT no certifican automáticamente otro nivel de parche ni Enterprise LTSC. No se inscriben cuentas ni compran licencias/ESU automáticamente. |
| 1 | Cuentas y UAC | Otra identidad durante elevación, administrador de recuperación realmente utilizable, fallos de grupo/permisos | VM con snapshot y cuentas ficticias; fixtures ya aprobados no sustituyen inicio de sesión/recuperación. |
| 1 | BitLocker | vTPM, reinicio, recuperación desde otro disco, datos/OS, fallo de respaldo y políticas/escrow | VM Pro con vTPM y volumen de prueba; recuperación probada y evidencia redactada. No cifrar el host ni discos de cliente. |
| 1 | Restauraciones del sistema | DNS IPv4/IPv6 DHCP/estático, dependientes de servicios, Hosts multialias, cola/Spooler y fallos parciales | Ensayos en snapshot y reversión observada. Impresoras físicas y configuraciones AD/Entra requieren su propio entorno. |
| 1 | Copias y USB | Disco lleno/bloqueo, interrupción, múltiples orígenes, ACL y destinos existentes; USB NTFS/exFAT/FAT32 y pérdida de energía | VHDs desechables para fallos de archivos y USB física para el medio real. Mover/sincronizar FastCopy siguen restringidos. |
| 1 | RustDesk real | Instalación limpia, repetida, upgrade EXE/MSI, criterio histórico de fecha, servicio, conexión al servidor y configuración persistente | VM y validación del servidor autorizado. Script/download/ACL y CLI ya reforzados; 14 pruebas aisladas por runtime y CI no son una instalación real. |
| 1 | Aplicaciones | Instalar las aplicaciones usadas, fuentes/Store, versión instalada, reinicios y requisitos OS del paquete entregado | Pruebas por paquete y edición. La instantánea contiene 56 manifiestos WinGet y dos entradas Store; no garantiza las versiones futuras ni licencias. |
| 2 | Identidad y confianza de Atlas | Authenticode y confianza offline frente a sustitución de toda la USB | Certificado/identidad confiable y política de distribución. Un certificado autofirmado sin confianza previa no resuelve el problema. |
| 2 | Licencias y permisos externos | Uso laboral/redistribución de terceros, custodia/retención de informes y alcance efectivo del PAT privado | Decisión del propietario y revisión por proveedor. No comprar ni rotar credenciales a ciegas. FastCopy de respaldo ya está actualizado a 5.12.0. |
| 2 | Diagnósticos, UI y deuda | Sensores/CPU/GPU/batería reales, interpretación de eventos, lector de pantalla/DPI/monitores y otras invocaciones heredadas | Equipos representativos y revisión por impacto. Tras los cambios quedan 294/320 avisos en 5.1/7.6.9 y 124 catches vacíos; requieren distinguir tolerancia intencional de fallo ocultado. Se eliminó el fallback Get-WmiObject sin suprimir reglas. |
| 2 | Deduplicador | Backend y borrado reversible, si se decide ofrecer esa capacidad | La tarjeta ya está deshabilitada y explica la ausencia. Integrarlo es alcance adicional; no existe un motor verificado que pueda activarse sin más. |

## Orden práctico

1. Corregir problemas reproducibles sin VMs: detección de dependencias, errores
   ocultos y conclusiones que exceden la evidencia del diagnóstico.
2. Ejecutar regresiones aisladas en PowerShell 5.1/7 y comprobaciones de
   distribución; publicar por bloque y volver a verificar el mismo enlace.
3. Mantener explícitas las dependencias de hardware, instalaciones reales,
   licencias e identidad de firma. No sustituirlas con mocks aprobados.
4. Retomar el laboratorio y sus snapshots solo cuando el usuario lo solicite.
   Cuentas, BitLocker, red, servicios y recuperación real siguen pendientes.
5. Revisar deuda por impacto sin suprimir avisos para presentar una cifra cero.

## Autonomía y dependencias

Después de la base de VMs puedo continuar con cuentas ficticias, permisos locales,
Hosts, DNS, servicios y colas virtuales, copias con fallos sobre discos desechables,
informes y entrega ficticia. BitLocker con vTPM/volúmenes de prueba también se puede
ensayar dentro del laboratorio; las claves de recuperación se conservan fuera de
los informes públicos. Cada ensayo necesita su snapshot, reversión y evidencia.

Quedan intervenciones externas concretas: aceptar los prompts UAC cuando Windows
los exija; aportar USB/hardware físico representativo; escoger las aplicaciones
prioritarias y sus condiciones de licencia; confirmar el escenario/servidor de
RustDesk; definir identidad de firma, custodia y retención; revisar permisos del
PAT con su propietario. No se inventan AD/Entra, licencias, hardware ni pruebas de
consentimiento usando fixtures. El acceso a Hyper-V por sí solo no resuelve esas
dependencias.

El laboratorio guarda contraseñas aleatorias solo para sus cuentas desechables,
en medios de instalación restringidos y credenciales DPAPI locales. Nunca se
incluyen en Git, logs públicos, issues o evidencias compartidas. Los discos físicos,
la configuración de Defender y la publicación existente quedan fuera de sus
mutaciones. Una VM de Windows sin activar se identifica como tal; no se ejecutan
activadores ni se inventan derechos de licencia.

Referencias: [PowerShell Direct](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/powershell-direct),
[AutoLogon de despliegue](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon),
[matriz objetivo](../SUPPORT-MATRIX.md).

Consulta del 25/10/2026: Microsoft publica 19045.7807 y 19044.7807 como revisiones
de octubre de 2026 en su [historial de Windows 10](https://learn.microsoft.com/en-us/windows/release-health/release-information).
Su página actual de [ESU de consumo](https://www.microsoft.com/en-us/windows/extended-security-updates)
indica cobertura hasta el 12/10/2027 para equipos inscritos elegibles y excluye
escenarios comerciales. Para un cliente empresarial corresponde revisar el canal
y programa aplicables. La ejecución de Atlas y la protección de Defender no
demuestran por sí solas esa cobertura del sistema operativo.
