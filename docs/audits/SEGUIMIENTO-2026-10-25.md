# Seguimiento autónomo del plan

Se continúa desde 1.4.1. Se conserva el dominio y Defender activo. Las pruebas de
mutaciones usan fixtures; no se atribuye homologación Windows 10 al host 26100.

## Bloque 1 — Ejecución y contratos (1.5.0)

- Se corrige un defecto de 1.4.0/1.4.1: el manifiesto declaraba Reports pero
  ToolRunner lo rechazaba. Eso podía impedir abrir las herramientas. La prueba
  nueva resuelve los 27 contratos reales y verifica sus bibliotecas. Las pruebas
  previas de ventana y wrapper simulado no cubrían este desajuste.
- Operations se declara en los contratos y ambos validadores admiten las mismas
  bibliotecas. El wrapper generado se prueba con los helpers reales.
- Ejecutor compartido: argumentos como tokens con quoting compatible con 5.1,
  directorio de trabajo, timeout, cancelación antes/durante el proceso, captura
  asíncrona de stdout/stderr y terminación acotada del árbol que creó. Las copias
  con salida masiva pueden heredar la consola y conservar el log nativo, evitando
  acumular toda su salida en memoria.
- Se migran MSI de PowerShell, dependencias, extractor USB, copias de recursos USB,
  Robocopy/FastCopy, DISM de exportación, dxdiag y búsquedas/instalaciones WinGet.
  El cierre de la ventana de paquetes solicita cancelación y espera el resultado
  de su trabajador sin bloquear el dispatcher. Una instalación cancelada puede
  dejar cambios parciales: no se presenta como revertida.
- Un fallo/timeout de instalación de dependencias no inicia automáticamente otro
  instalador ni usa inmediatamente los archivos parciales como éxito. El código
  MSI 3010 se comunica como reinicio requerido. La lectura de presencia sigue sin
  certificar toda versión o estado de instalación: queda QA por paquete.
- Se mantienen las ventanas interactivas de herramientas y la telemetría GPU
  como procesos de sesión; no se les aplica un timeout arbitrario de operación.
  La espera del panel principal representa su vida interactiva, no una reparación.
- Se retiran tasas calculadas con el crecimiento del destino: sobrescribir puede
  escribir muchos bytes sin aumentar tamaño. Cantidad/rendimiento quedan sin medir
  por Atlas; se consulta el log nativo. El reporte distingue muestreo SHA-256 de
  certificación integral y redacta sus rutas y cliente.

La evidencia final del bloque se guarda en FASE-6-EVIDENCIA-2026-10-25.json.
La publicación exige CI sobre el SHA completo y comprobación posterior del dominio.
Volver a 1.4.1 no corrige el desajuste de bibliotecas: para ese defecto usar 1.5.0+.

## Trabajo siguiente, sin depender de VMs

1. Consultar manifiestos actuales de las aplicaciones y registrar versiones,
   fuentes, arquitectura y mínimo OS explícito. Un manifiesto no sustituye el
   soporte del fabricante ni una instalación en Windows 10.
2. Revisar dependencias existentes, versiones y licencia de FastCopy; sin compras
   automáticas ni inventar derechos comerciales o garantías de autenticidad.
3. Revisar el onboarding privado accesible y su autoridad de publicación; conservar
   los endpoints y no imprimir tokens ni secretos.
4. Completar fallos de interpretación/privacidad que se puedan reproducir sin
   hardware, y reducir advertencias de mayor impacto.

Permanecen externas: acceso a VMs Windows 10, recuperación BitLocker real, hardware,
credenciales/permisos no disponibles y una identidad/certificado confiable para
firma. No se crea un certificado autofirmado y se lo presenta como confianza ya
instalada en equipos de clientes.

Referencias técnicas: [Process y espera](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.waitforexit),
[argumentos de procesos PowerShell](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-5.1),
[códigos de Windows Installer](https://learn.microsoft.com/en-us/windows/win32/msi/error-codes).
