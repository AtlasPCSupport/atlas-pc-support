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
se realiza en una copia temporal con espacios en la ruta; comprueba que los tres
artefactos de distribución originales conservaron su SHA-256. Guarda `summary.json`,
`analyzer.json` y `pester.xml` en la carpeta temporal que imprime.

En Windows crea la ventana WPF y todas las tarjetas sin mostrarlas, iniciar timers
ni conectar botones. En Linux esas dos pruebas se omiten explícitamente. Esto no
valida la experiencia visual ni equivale a probar Windows 10 en una VM.
Las fuentes Unicode se leen como UTF-8 y se cargan desde copias con BOM en TestDrive
para 5.1; no se altera el encoding de los originales. Esta prueba no certifica la
invocación directa de fuentes sin BOM ni la descarga del bootstrap.

## Fallos conocidos

Las pruebas de aceptación de `KnownIssues.Tests.ps1` son **rojas hasta que se corrijan
los defectos**. Se ejecutan por separado de la comprobación básica:

```powershell
rtk proxy pwsh -NoProfile -STA -File ./tests/Invoke-LocalChecks.ps1 -IncludeKnownIssues
```

En la fase 0 hay cuatro casos: MSI sin firma, MSI offline sin hash requerido,
administrador sin contraseña y degradación con solo otro administrador deshabilitado.
Usan archivos de texto ficticios y operaciones simuladas, sin instalar ni cambiar
cuentas. El runner devuelve error cuando una expectativa no se cumple. Una excepción
de preparación de la prueba debe investigarse y no contarse como reproducción.

Al corregir cada caso, mover esa prueba al grupo normal de regresión y conservarla
en CI. No borrar la expectativa ni invertirla para hacer pasar el comportamiento
defectuoso. BitLocker y los demás casos del backlog requieren pruebas adicionales.

La comprobación básica verde **no autoriza una publicación mientras existan P0**.
El CI de cliente corre sobre `windows-latest`; se necesita además la matriz real de
Windows 10 del plan de fase 0.

## Windows PowerShell iniciado desde PowerShell 7

Un proceso 5.1 puede heredar un `PSModulePath` que antepone módulos de PowerShell 7.
Si faltan comandos nativos como `Get-FileHash`, comprobar primero el módulo cargado
y ejecutar desde una consola nativa 5.1. No instalar una implementación alternativa
del comando ni eliminar módulos del equipo para esconder el problema.
