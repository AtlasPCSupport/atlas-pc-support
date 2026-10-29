# Comprobaciones locales de Atlas

## USB fisica (solo con un medio identificado y autorizado)

`Invoke-UsbAcceptance.ps1` es una prueba opt-in separada de CI. Requiere letra,
numero e identidad SHA-256 del disco/volumen USB observados previamente; no
selecciona automaticamente discos ni permite el volumen de sistema. Crea una
carpeta GUID nueva y fixtures locales, no formatea ni llena el medio, conserva
logs y evidencia. Usa la publicacion aprobada y entradas offline con `-NoLaunch`.
No prueba desconexion, perdida electrica ni Windows 10. Consultar la
[evidencia y limites](../docs/audits/USB-2026-10-26.md) antes de ejecutarlo.

## Suite local

El runner no instala dependencias, no descarga el panel ni ejecuta sus herramientas.
Necesita **Pester 5.8.0** y **PSScriptAnalyzer 1.25.0** ya disponibles para el runtime usado.
Ejecutar desde Windows PowerShell 5.1 x64 o PowerShell 7 en Windows, en STA:

```powershell
pwsh -NoProfile -STA -File ./tests/Invoke-LocalChecks.ps1
powershell -NoProfile -STA -ExecutionPolicy RemoteSigned -File ./tests/Invoke-LocalChecks.ps1
```

El estado de Defender y la política permanente de ejecución no se modifican.
Si la política del equipo impide el script, conservar el error y resolver la
política autorizada del entorno; no añadir una excepción antivirus.

El runner verifica fuentes, manifiesto, hashes, guardas y pruebas. La reconstrucción
se realiza en una copia temporal con espacios en la ruta; comprueba que los cinco
artefactos de distribución originales conservaron su SHA-256. Guarda `summary.json`,
`analyzer.json` y `pester.xml` en la carpeta temporal que imprime.

En Windows crea la ventana WPF y todas las tarjetas sin mostrarlas, iniciar timers
ni conectar botones. En Linux los casos que requieren Windows se omiten explícitamente. Esto no
valida la experiencia visual ni equivale a probar Windows 10 en una VM.
Las fuentes Unicode se leen como UTF-8 y se cargan desde copias con BOM en TestDrive
para 5.1; no se altera el encoding de los originales. Esta prueba no certifica la
invocación directa de fuentes sin BOM ni la descarga del bootstrap.

`Language.Tests.ps1` comprueba el guardado de idioma sobre carpetas ficticias:
preserva JSON inválido y valores anidados, distingue errores de escritura y
ejercita el handler real sustituyendo únicamente el diálogo. No modifica las
preferencias del perfil del operador. Está incluido en la suite local y CI.

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
El bootstrap, launcher, wrapper y runner anteponen los módulos nativos de 5.1 antes
de cargarlos. El cambio es solo del proceso: no se eliminan módulos ni se escribe
configuración persistente. La regresión de herencia inicia un 5.1 real con rutas
PS7 delante, valida la entrada offline y bloquea cualquier herramienta real.

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

## Medición de primer pintado

Desde la raíz, en Windows, tras build y sobre una copia de confianza:

```powershell
powershell -NoProfile -STA -ExecutionPolicy RemoteSigned -File tests/Measure-AtlasStartup.ps1 -RepoRoot (Get-Location).Path -Output "$env:TEMP\atlas-startup.json"
```

Abre una ventana y la cierra automáticamente después del primer pintado/dispatcher
idle; no pulsa herramientas. Valida el bundle y usa las definiciones generadas,
instrumentando solo ese proceso. Incluye inicialización local y verificación,
excluye red/bootstrap, inicio del proceso PowerShell y arranque desde apagado.
No vacía cachés. Las tarjetas siguen comprobándose en segundo plano: ventana
dibujada no significa todas las herramientas listas. Repetir secuencialmente y
guardar los resultados para comparar; no ejecutar ventanas concurrentes.
