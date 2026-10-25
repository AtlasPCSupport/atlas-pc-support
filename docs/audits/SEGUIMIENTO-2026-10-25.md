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

## Bloque 2 — Catálogo y publicación privada (1.5.1)

- Instantánea completa en CATALOGO-2026-10-25.json: 52 aplicaciones y seis
  dependencias adicionales, 56 manifiestos WinGet y dos fichas Store pendientes.
  Las referencias y los blobs pertenecen al mismo commit de winget-pkgs.
  Los instaladores x86 se consideran candidatos para Windows x64; no se descartan
  por no tener una fila x64. Un mínimo OS ausente queda como no declarado.
- El panel muestra esa incertidumbre; los mínimos explícitos de Windows 10 se
  consultan por ID y los perfiles no pueden sustituirlos por un valor inferior.
  WinGet continúa resolviendo la versión disponible: esta instantánea no fija
  las 52 versiones ni garantiza soporte futuro del fabricante.
- PowerShell opcional pasa a 7.6.8, publicación oficial del 22/10/2026. Su MSI
  x64 tiene SHA-256 fijado en el catálogo verificado y exige además una firma
  Microsoft válida. La copia USB y sus sidecars no pueden cambiar esa autoridad.
  La aplicación conserva PowerShell 5.1 como runtime predeterminado.
- FastCopy de respaldo pasa a 5.12.0. Se descargaron sus bytes sin ejecutarlos:
  coinciden con el manifiesto WinGet y la firma Authenticode de FastCopy Lab es
  válida en este host. No se compraron ni concedieron licencias. Robocopy es la
  alternativa nativa; la página del fabricante exige licencia Pro en el trabajo.
- El onboarding conserva sus endpoints y exactamente los bytes previamente
  publicados. Ahora usa un commit y hash independientes; el Worker verifica
  el script antes de servirlo y deriva su checksum de esos mismos bytes. Ya no
  sigue main ni acepta una suma mutable como autoridad. El publicador comprueba
  también la fuente privada sin imprimir su contenido ni la credencial.
- Revisión privada, sin ejecutar el instalador: descarga la última release de
  RustDesk sin verificar todavía el digest/firma del ejecutable. Esta protección
  debe completarse en su fuente privada; fijar el script no certifica ese binario.
- La regla protect-main 15496177 exige ahora build, windows-compat y worker,
  conservando el resto de políticas; evidencia en PROTECCION-MAIN-2026-10-25.json.

Fuentes: [PowerShell 7.6.8](https://github.com/PowerShell/PowerShell/releases/tag/v7.6.8),
[FastCopy: versión y licencia](https://fastcopy.jp/help/fastcopy_eng.htm),
[Web Crypto del Worker](https://developers.cloudflare.com/workers/runtime-apis/web-crypto/).

## Pendientes después del bloque 2

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
