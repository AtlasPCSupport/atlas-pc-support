# Comprobaciones locales de Atlas

El runner no instala dependencias, no descarga el panel ni ejecuta sus herramientas.
Necesita **Pester 5.8.0** y **PSScriptAnalyzer 1.25.0** ya disponibles para el runtime usado.
Ejecutar desde Windows PowerShell 5.1 x64 o PowerShell 7 en Windows, en STA:

```powershell
rtk proxy pwsh -NoProfile -STA -File ./tests/Invoke-LocalChecks.ps1
rtk proxy powershell -NoProfile -STA -ExecutionPolicy RemoteSigned -File ./tests/Invoke-LocalChecks.ps1
```

El estado de Defender y la política permanente de ejecución no se modifican.
Si la política del equipo impide el script, conservar el error y resolver la
política autorizada del entorno; no añadir una excepción antivirus.

El runner verifica fuentes, manifiesto, hashes, guardas y pruebas. La reconstrucción
se realiza en una copia temporal con espacios en la ruta; comprueba que los cinco
artefactos de distribución originales conservaron su SHA-256. Guarda `summary.json`,
`analyzer.json` y `pester.xml` en la carpeta temporal que imprime.

En Windows crea la ventana WPF y todas las tarjetas sin mostrarlas, iniciar timers
ni conectar botones. En Linux esas dos pruebas se omiten explícitamente. Esto no
valida la experiencia visual ni equivale a probar Windows 10 en una VM.
Las fuentes Unicode se leen como UTF-8 y se cargan desde copias con BOM en TestDrive
para 5.1; no se altera el encoding de los originales. Esta prueba no certifica la
invocación directa de fuentes sin BOM ni la descarga del bootstrap.

`Accounts.Tests.ps1` es parte de la comprobación obligatoria y del CI. Cubre
retención de administradores habilitados, identidad por SID, creación y asignación
de grupo, cancelaciones, contraseñas y errores. Las operaciones de cuentas/procesos
están bloqueadas por stubs y sustituidas por mocks; no actúan sobre usuarios reales.

## Regresiones de la fase 1

Los cuatro casos rojos de la fase 0 se conservaron en `Accounts.Tests.ps1` y
`Installers.Tests.ps1`; ahora forman parte del grupo obligatorio y deben pasar.
Los instaladores son texto ficticio y firma/proceso/red están simulados. Se prueban
también hash inválido, firma no confiable, resultados nativos y preparación USB.

`BitLocker.Tests.ps1` bloquea operaciones reales y comprueba protectores, orden de
backup antes del cifrado, errores y la escritura/lectura de una clave ficticia en
TestDrive con discos simulados. `Execution.Tests.ps1` comprueba los argumentos del
runner real y clasificaciones de diagnóstico sin lanzar las herramientas.

`-IncludeKnownIssues` se mantiene compatible: solo añade el fichero de pendientes
si existe. Ya no hay casos deliberadamente rojos en esta entrega. Esto no sustituye
la matriz Windows 10 ni una prueba de recuperación BitLocker en VM. El CI de
cliente corre sobre `windows-latest`.

## Windows PowerShell iniciado desde PowerShell 7

Un proceso 5.1 puede heredar un `PSModulePath` que antepone módulos de PowerShell 7.
Si faltan comandos nativos como `Get-FileHash`, comprobar primero el módulo cargado
y ejecutar desde una consola nativa 5.1. No instalar una implementación alternativa
del comando ni eliminar módulos del equipo para esconder el problema.

## Distribución y runtime (fase 2)

`Release.Tests.ps1` comprueba staging, manifiesto aprobado, corrupción, conjunto
incompleto, rutas inválidas, fallo de activación atómica, bloqueo concurrente y
rollback verificado sin red. Copia el bundle real a TestDrive y ejecuta su entrada
offline con `-NoLaunch`: no abre el panel ni instala/cifra/modifica cuentas.

`Execution.Tests.ps1` ejecuta también un wrapper real con una función ficticia,
comprueba helpers/catálogo y rutas con espacios, tildes y apóstrofos. Las acciones
de las herramientas reales continúan bloqueadas. El build aislado compara los
cinco artefactos byte a byte entre PowerShell 5.1 y 7, sin normalizar diferencias.

El Worker usa `node --test` con fetch simulado: pins, refs, errores, límites de
respuesta, métodos, caché y compatibilidad del onboarding. CI añade `npm audit` y
una compilación Wrangler sin despliegue. La verificación pública posterior a la
promoción es de lectura; el ensayo online/offline usa `-NoLaunch` y carpetas
temporales. No equivale a una homologación de Windows 10 o medios FAT/exFAT reales.
