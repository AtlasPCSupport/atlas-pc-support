# Auditoría técnica de Atlas PC Support

**Fecha de cierre:** 24 de octubre de 2026, America/Lima.
**Código revisado:** `2b3efafc327ac9bd84e9ae316fb24281c95db08b`.
**Objetivo:** evaluar las herramientas, detectar prácticas desactualizadas o incorrectas y definir una modernización compatible con Windows 10 donde sea razonable.
**Tipo de trabajo:** revisión de código, comprobaciones locales no destructivas y contraste con documentación oficial consultada el 23–24 de octubre. No se aplicaron correcciones funcionales ni se desplegaron cambios.

**Navegación:** [Dictamen](#dictamen) · [Evidencia](#evidencia) · [Hallazgos](#hallazgos) · [Windows 10](#windows10) · [27 herramientas](#herramientas) · [Dependencias y catálogo](#dependencias) · [Arquitectura y entrega](#arquitectura) · [Plan de trabajo](#plan) · [Decisiones](#decisiones).

<a id="dictamen"></a>

## 1. Dictamen

**El proyecto merece evolucionar. La mayor parte de sus funciones puede funcionar en Windows 10, pero todavía no hay evidencia suficiente para presentar el conjunto como una suite validada de mantenimiento y diagnóstico.**

La base es apropiada para un taller: PowerShell, WPF, herramientas nativas de Windows, manifiesto de herramientas y posibilidad de trabajo desde USB. No veo una necesidad técnica de reescribir el panel en Electron, convertirlo en una aplicación web o introducir un servicio residente para resolver los problemas encontrados.

El problema más importante es la confianza en los resultados y en las operaciones con privilegios. Existen funciones que anuncian éxito sin comprobar el estado final, diagnósticos que convierten datos ausentes en conclusiones favorables y verificaciones de instaladores que permiten continuar cuando no se pudo verificar. En BitLocker y administración de cuentas, un fallo puede comprometer la recuperación del equipo; en copias y diagnóstico, puede inducir al técnico a entregar un equipo o borrar un origen antes de tiempo.

Mis recomendaciones principales son:

1. **Corregir primero recuperación, cuentas, ejecución de instaladores y resultados falsamente positivos.**
2. **Definir Windows 10 por edición, compilación y capacidades**, con Windows 10 22H2 x64 como objetivo principal y LTSC como perfil específico.
3. **Conservar Windows PowerShell 5.1 cuando una función lo necesite** y usar PowerShell 7 actualizado donde esté probado. La presencia de `pwsh.exe` no demuestra compatibilidad de una herramienta.
4. **Publicar conjuntos completos e inmutables:** launcher, scripts, manifiestos y dependencias de una misma versión, con verificación y actualización atómica.
5. **Cambiar la filosofía de “optimizar todo” por “medir, explicar, aplicar y comprobar”**, con reversión en las acciones que la permiten.
6. **Mantener una función básica nativa y opcionales externos explícitos**, incluyendo sus requisitos de licencia, conexión y arquitectura.

### Lo que conviene conservar

- Separación entre fuentes y launcher generado; comprobación de que el artefacto no esté desactualizado.
- Manifiesto central con 27 herramientas y hashes SHA-256 de sus fuentes.
- Uso extendido de CIM, DISM, SFC, Robocopy y cmdlets del sistema.
- Comprobaciones de administrador y algunas confirmaciones de operaciones sensibles.
- Uso de SID para grupos locales en varias herramientas, que evita depender del idioma de Windows.
- Soporte de rutas sin conexión en parte del código, reportes HTML y traducciones.
- Diferenciación correcta de los códigos 0–7 de Robocopy frente a errores de copia.
- Escapado HTML ya presente en varios reportes y ocultación parcial de claves en el informe de entrega.

### Cómo leer las prioridades

| Prioridad | Significado en este informe |
|---|---|
| P0 | Corregir o restringir la acción afectada antes de recomendar su uso en equipos de clientes. No implica que se haya observado un ataque o pérdida real. |
| P1 | Resolver en el siguiente bloque de estabilización: funcionamiento incorrecto, diagnóstico engañoso, compatibilidad o distribución. |
| P2 | Mejora de mantenimiento, experiencia, rendimiento o documentación; puede programarse después. |

Las conclusiones se distinguen entre **confirmadas por código**, **reproducidas en una comprobación aislada** y **pendientes de pruebas reales**. Las propuestas de compatibilidad son objetivos de trabajo, no certificaciones de ejecución.

<a id="evidencia"></a>

## 2. Alcance y evidencia

Se revisaron los caminos principales de las **27 herramientas**, las **8 bibliotecas**, el launcher de desarrollo y el generado, interfaz WPF/XAML, bootstrap, generación de hashes, catálogo de aplicaciones, preparación USB, pruebas, workflows, Worker de Cloudflare y onboarding público. Las fuentes PowerShell bajo `src` suman **24 868 líneas**, incluidas traducciones, comentarios y espacios.

El catálogo del instalador contiene **52 aplicaciones más una acción de limpieza**. Su presencia y forma de instalación se revisaron; no se instalaron las 52 aplicaciones ni se verificó experimentalmente cada versión que sus proveedores publican. Más adelante se diferencian los requisitos contrastados y los pendientes.

No forman parte del material disponible el backend `app_deduplicar.py` ni el contenido privado de `install-rustdesk.ps1`. No se han inspeccionado políticas reales de protección de ramas, configuración desplegada de Cloudflare, credenciales, licencias comerciales adquiridas ni una flota de equipos de clientes. Por tanto, no se atribuyen al proyecto filtraciones o incumplimientos no demostrados.

### Comprobaciones realizadas

| Comprobación | Resultado | Qué demuestra y qué no |
|---|---|---|
| `tests/Test-SecurityGuards.ps1`, PowerShell 7 | Pasa | Se cumplen los guardas estáticos incluidos; no cubre toda la cadena de confianza. |
| `tests/Test-ToolSources.ps1`, PowerShell 7 | Pasa, 27 herramientas | Sintaxis, correspondencia de manifiesto y hashes. |
| Mismo verificador con Windows PowerShell 5.1 y rutas explícitas | Pasa | Compatibilidad de análisis de las fuentes. No ejecuta operaciones de las herramientas. |
| `tests/Lib.Tests.ps1`, Pester 5.8.0 | **13 pruebas pasan** | Helpers y escenarios cubiertos por los mocks existentes. No son 13 pruebas completas de herramientas. |
| `tests/Assert-LauncherFresh.ps1` | Pasa en copia temporal | Launcher y hashes corresponden a las fuentes después de las normalizaciones previstas. No se reconstruyeron los originales. |
| PSScriptAnalyzer 1.25.0 sobre `src`, con configuración del proyecto | **0 errores, 399 advertencias, 280 informativos** | Hay deuda estática; esas cifras no equivalen a 399 vulnerabilidades. |
| `npm audit --json`, lock del Worker | **4 paquetes afectados, gravedad alta; salida 1** | Afecta la cadena de desarrollo Wrangler → Miniflare → Sharp/Undici. No prueba explotación del Worker publicado. |
| Pruebas aisladas de funciones y argumentos | Fallos reproducidos | WHEA no encontrado con proveedor real; `Unhealthy` coincide con `healthy`; verificación vacía devuelve OK; ruta de script sin comillas falla. |
| Metadatos de `Set-LocalUser` | No existe `-NoPassword` | Confirma un error de llamada en Entrega PC sin modificar cuentas. |
| Worker con `fetch` simulado | Conductas reproducidas | Ruta desconocida devuelve 200, ref inexistente cae a `main`, checksum usa el mismo repositorio y ruta de script privado responde sin autenticación del solicitante. |

El host de comprobación tiene compilación **26100**, PowerShell **7.6.6** y Windows PowerShell **5.1.26100.9711**. **No es una validación sobre Windows 10 22H2.** El nombre textual `ProductName` del registro no es suficiente para identificar Windows 10/11; este mismo host ilustra por qué deben usarse build, edición y capacidades.

La ejecución inicial del verificador con Windows PowerShell estuvo afectada por la política de ejecución local y, después, por sus rutas predeterminadas basadas en `$PSScriptRoot` en parámetros. Se ejecutó correctamente con política limitada al proceso y rutas explícitas. No se cambió la política permanente del equipo. Este detalle corresponde al arnés de pruebas, no demuestra por sí solo que una herramienta falle en Windows 10.

No se activó BitLocker, cambiaron usuarios, limpiaron colas, alteraron DNS/servicios, instalaron paquetes ni ejecutaron pruebas de estrés. Las reproducciones se hicieron en carpetas temporales, con funciones aisladas o respuestas de red simuladas.

<a id="hallazgos"></a>

## 3. Hallazgos transversales prioritarios

### H01 — Verificación de ejecutables que permite continuar ante un fallo · P0

En [Actualizar PowerShell](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-ActualizarPowerShell.ps1:253>), una firma ausente o inválida genera un aviso y la ejecución puede continuar. El hash solo se comprueba si existe una función auxiliar que normalmente no se inyecta en el proceso hijo. Además, la excepción de verificación se captura como “check skipped”. Un hash incorrecto intenta borrar el archivo, lo que suele impedir instalarlo, pero la seguridad no debe depender de que ese borrado tenga éxito.

La [biblioteca PS7](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/PS7.ps1:162>) comprueba el hash cuando lo tiene, pero permite instalar un MSI local sin sidecar. [Preparar USB](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrepararUSB.ps1:675>) tiene caminos que aceptan descargas por tamaño y ejecutan el instalador de FastCopy sin la comprobación que sí existe en el gestor central.

**Cambio:** una única adquisición de dependencias con versión, arquitectura, URL, digest esperado y política de firma. Archivo incompleto, digest ausente cuando es obligatorio o firma no aceptada deben impedir ejecutar. La decisión debe ser idéntica en instalación normal, actualización y USB. Probar redirección, descarga parcial, firma inválida, hash incorrecto y ausencia de conexión.

### H02 — BitLocker: recuperación y protectores incompletos · P0

La [rama que detecta TPM](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GestorBitLocker.ps1:803>) activa con `-RecoveryPasswordProtector`, sin crear explícitamente un protector TPM. La rama sin TPM reutiliza una contraseña sin distinguir adecuadamente volumen del sistema y de datos. La recomendación de exportar la recuperación aparece después de iniciar el cifrado y el backup a AD no condiciona el éxito anunciado.

El flujo también ofrece guardar claves en texto en el escritorio y propone pegar una imagen de recuperación en el equipo. Esto último anula buena parte de la protección frente al robo físico. La presencia de una clave no prueba que esté respaldada o que pueda recuperarse.

**Cambio:** separar sistema/datos/extraíble; consultar protectores y políticas existentes; añadir el protector de uso y recuperación adecuado; verificar custodia externa antes de dar por completada la operación; comprobar estado posterior y reinicio pendiente. Microsoft documenta los protectores como decisiones explícitas y recomienda un protector principal más recuperación para datos. [Guía oficial de operaciones BitLocker](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/operations-guide?tabs=powershell).

### H03 — Riesgo de quedarse sin un administrador utilizable · P0

[Menor Privilegio](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-MenorPrivilegio.ps1:517>) acepta cualquier otro nombre en Administradores, incluso una cuenta local deshabilitada. También toma `$env:USERNAME` como objetivo: al elevar con otras credenciales puede representar al técnico y no al usuario que inició la operación.

[Entrega PC](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-EntregaPC.ps1:375>) permite la ruta de creación sin contraseña combinada con pertenencia a Administradores. La eliminación no tiene una defensa equivalente contra el último administrador habilitado. Varias operaciones usan `try/catch` sin forzar errores terminantes.

**Cambio:** identificar cuentas por SID, distinguir identidad interactiva y elevada, bloquear la eliminación/degradación del último administrador habilitado, verificar la cuenta de recuperación y exigir contraseña en cuentas administrativas creadas por el panel. No basta con que exista otro miembro nominal del grupo.

### H04 — Integridad de descarga confundida con autenticidad de publicación · P1

El [Worker](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/api/cloudflare-worker/src/index.js:77>) obtiene `launcher.ps1.sha256` del mismo repositorio que contiene el launcher y calcula el digest del manifiesto descargado desde ese mismo origen. Sus comentarios lo llaman canal independiente basado en secretos, pero la implementación es un proxy vivo del repositorio. Esto detecta determinadas inconsistencias de transporte o caché; **no constituye una autoridad independiente si se modifica maliciosamente ese repositorio**.

Además, [el launcher de desarrollo](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/Launcher.ps1:64>) configura un digest obligatorio y el [build](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/build.ps1:149>) no reproduce esas asignaciones en su bootstrap. El artefacto compilado incluye las funciones, pero no activa la misma exigencia. La prueba de frescura pasa porque esa divergencia está en el propio generador.

**Cambio:** publicar un release completo, con identificación inmutable y manifiesto autenticado por una clave de publicación confiable. Si se mantiene el canal independiente, debe depender realmente de otro control de publicación. El bootstrap inicial también necesita un modelo de confianza explícito: verificar lo que descarga después no autentica retrospectivamente un `get.ps1` ejecutado con `irm | iex`.

### H05 — Launcher y herramientas pueden pertenecer a versiones distintas · P1

Las descargas apuntan ampliamente a `main`. El runner puede refrescar hashes para aceptar scripts más recientes mientras conserva un launcher anterior. La USB actualiza componentes por caminos separados. Un `?ref=` en el Worker no fija todo el conjunto: el bootstrap descargado contiene sus propias URLs a `main`; si no existe el ref, el Worker además cae silenciosamente a `main`.

**Cambio:** identificar cada distribución por versión y commit; resolver todos los archivos desde esa identidad; descargar y verificar en staging; activar la carpeta completa de forma atómica; conservar la anterior. Un ref solicitado que no existe debe fallar claramente. No hacen falta microservicios ni una base de datos para hacerlo.

### H06 — El contrato de ejecución de herramientas está incompleto · P1

[ToolRunner](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/ToolRunner.ps1:517>) inyecta ToolKit, pero no Dependencies ni PS7. Por ello las funciones compartidas disponibles en el launcher no están necesariamente disponibles en la herramienta. FastCopy intenta recurrir a `Resolve-AtlasDependency` y luego solo busca un ejecutable existente; el autorresolutor puede quedar inaccesible en su ventana normal.

[El lanzamiento](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/ToolRunner.ps1:579>) selecciona cualquier PowerShell 7 detectado para todas las herramientas. No hay runtime ni capacidades exigidas por herramienta. El argumento de ruta temporal se pasa sin comillas: la reproducción con un directorio con espacios falló; con comillas salió con código cero. El wrapper captura excepciones y muestra texto, sin devolver al panel un resultado estructurado de éxito o fallo.

**Cambio:** definir un contexto pequeño y explícito: runtime/arquitectura, bibliotecas requeridas, rutas, modo offline, identidad y resultado. Resolver dependencias antes del lanzamiento o importarlas de forma coherente en el hijo. Probar espacios, tildes, apóstrofos, idioma, usuario estándar y elevación con credenciales distintas.

### H07 — Falta una semántica común de resultado · P1

Un proceso que terminó no necesariamente tuvo éxito. Un `catch {}` puede convertir error de lectura en lista vacía. Un dispositivo no medido no está sano. Un comando nativo no lanza automáticamente una excepción de PowerShell por cada código de salida distinto de cero.

Este problema aparece en mantenimiento, diagnóstico, dependencias, servicios, impresoras e instaladores. El caso más concreto está en [Instalar Paquetes](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-InstalarPaquetes.ps1:1399>): `-1978335212` es `0x8A150014`, **NO_APPLICATIONS_FOUND**, pero se cuenta como “ya instalado”. La lista también incluye representaciones sin signo de errores de manifiesto, argumentos de source y conversión ICU; sus comentarios no coinciden con el contrato oficial. [Códigos de error de WinGet](https://raw.githubusercontent.com/microsoft/winget-cli/master/src/AppInstallerSharedLib/Public/AppInstallerErrors.h).

**Cambio:** resultado uniforme con estado `Correcto`, `Advertencia`, `Fallido`, `NoEvaluado`, `NoCompatible` o `Cancelado`, además de código nativo, evidencia, duración y reinicio pendiente. Comprobar la condición final relevante: paquete instalado y versión, servicio en su estado, archivo copiado, protector creado, etc.

### H08 — Los diagnósticos sobreafirman · P1

Hay ejemplos comprobables: GPUCheck puede concluir APTO sin telemetría; AI Readiness no penaliza `Unhealthy` por una expresión regular sin anclaje; el analizador de eventos no encuentra su tabla WHEA con el nombre real del proveedor; el escaneo de puertos WAN desde la propia LAN no certifica exposición desde Internet.

**Cambio:** cada conclusión debe mostrar fuente, cobertura, momento y limitación. Separar dato observado, hipótesis y recomendación. No reemplazar esas reglas por un modelo de IA sin antes corregir la calidad y trazabilidad de los datos.

### H09 — Exposición del instalador privado en el Worker · P1, condicionada al contenido

La [ruta `/install.ps1`](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/api/cloudflare-worker/src/index.js:114>) no autentica al solicitante y entrega contenido del repositorio privado con `Cache-Control: public`. Se reprodujo con un contenido ficticio. Eso puede ser deliberado para onboarding público; **el hecho de que el repositorio sea privado no hace privado el endpoint**. El PAT se usa hacia GitHub y no se devuelve en el código revisado.

**Cambio:** si el instalador es público, documentarlo y garantizar que no contenga credenciales ni configuración sensible por cliente. Si es privado, usar autorización apropiada y `private/no-store`, eliminar la caché compartida para ese contenido y fijar versiones permitidas. Revisar el instalador real es trabajo pendiente, no una filtración ya demostrada.

### H10 — Las pruebas actuales no representan el riesgo de las operaciones · P1

El [workflow Windows](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/.github/workflows/build.yml:107>) analiza sintaxis y XML. `windows-latest` no es una matriz de Windows 10 Home/Pro/LTSC, y parsear XML no crea ni interactúa con la ventana WPF. Las pruebas de bibliotecas no ejercitan cifrado, rollback, colas, cuentas o copias interrumpidas.

El [automerge](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/.github/workflows/auto-merge.yml:82>) no depende del job que recalcula la etiqueta de autorización. Esto deja una carrera con etiquetas previas; además, las rutas sensibles omiten `src/tools` y el Worker. La exigencia de aprobación y reglas del servidor podrían limitar el efecto, pero no se inspeccionaron y no deben suponerse.

**Cambio:** comprobación sobre el SHA actual, dependencias explícitas entre jobs y revisión de rutas sensibles completas; pruebas comportamentales dirigidas a los fallos descritos; VMs de cliente Windows. Incluir cambios de bootstrap, tests, Worker y workflows en los disparadores pertinentes; publicar todos los artefactos coherentes del release.

<a id="windows10"></a>

## 4. Compatibilidad con Windows 10: propuesta concreta

### 4.1 Alcance recomendado

| Plataforma | Compromiso propuesto | Observaciones |
|---|---|---|
| Windows 10 22H2 x64, Home y Pro | Objetivo principal de compatibilidad técnica | Build 19045; distinguir edición, políticas, App Installer, TPM y funciones instaladas. |
| Windows 10 Enterprise LTSC 2021 / IoT LTSC 2021 x64 | Perfil adicional explícito | Build 19044; no suponer Store ni todos los componentes de una instalación de consumo. |
| Windows 10 LTSC 2019 / builds anteriores | Soporte limitado y evaluado por necesidad de clientes | No prometer los mismos proveedores, runtimes o funcionalidades actuales. |
| Windows 10 x86 y ARM64 | Fuera del primer compromiso | Hay rutas y descargas x64 codificadas; requieren trabajo y pruebas propios. |
| Windows 11 | Mantener y probar en paralelo | Las opciones exclusivas de 11 deben aparecer solo cuando correspondan. |

“Funciona en Windows 10” y “Microsoft sigue dando soporte a esa configuración” son cosas distintas. El soporte general de Windows 10 terminó el **14 de octubre de 2025**. La página oficial consultada ahora indica protección mediante **Consumer ESU hasta el 12 de octubre de 2027**, sujeta a inscripción y condiciones; no debe reutilizarse una fecha antigua de ESU sin revisar la modalidad. El panel debe informar edición, build y estado conocido de mantenimiento, sin afirmar que instalar Atlas restablece soporte. [Estado y opciones oficiales de Windows 10](https://support.microsoft.com/en-us/windows/deployment/updates-lifecycle/windows-10-support-has-ended-on-october-14-2025).

LTSC tampoco es una sola fecha: Enterprise LTSC 2021 termina su ciclo en **enero de 2027**, mientras IoT Enterprise LTSC 2021 tiene soporte extendido hasta **enero de 2032**. Esas condiciones no se transfieren automáticamente de una edición a otra. [Enterprise LTSC 2021](https://learn.microsoft.com/en-us/lifecycle/products/windows-10-enterprise-ltsc-2021), [IoT Enterprise LTSC 2021](https://learn.microsoft.com/en-us/lifecycle/products/windows-10-iot-enterprise-ltsc-2021).

### 4.2 Runtime y detección

Mantener un launcher WPF en Windows PowerShell 5.1 x64 es razonable para equipos existentes. Añadir al manifiesto un runtime preferido y alternativas probadas por herramienta; comprobar `Get-Command`, disponibilidad de módulos, edición, build y políticas antes de habilitar una acción. Para módulos específicos puede resultar necesario un proceso 5.1 o la compatibilidad Windows de PowerShell 7; no deben darse por incompatibles todos los módulos ni asumir que todos funcionarán por instalar 7.

PowerShell 7 debe actualizarse por canal y parche, no por una constante repartida entre scripts. A la fecha contrastada, Microsoft publica **7.6.6 como LTS**, con ciclo de 7.6 hasta noviembre de 2028; 7.4 y 7.5 terminan en noviembre de 2026. La versión fijada **7.5.0** está atrasada en parches y su rama cerca del final. Recomiendo homologar 7.6 LTS, comprobando el soporte de la combinación Windows/.NET y sin usarlo para “certificar” un OS fuera de soporte. [Ciclo de PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle?view=powershell-7.5).

Hay un cambio de distribución importante: desde 7.6, WinGet instala MSIX por defecto; la documentación aún permite seleccionar MSI. Atlas depende de rutas y comportamiento de MSI, por lo que debe elegir deliberadamente el tipo de instalador y probar detección, elevación y actualización. [Instalación oficial de PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6).

### 4.3 Funciones que deben variar por plataforma

| Función | Windows 10 | Decisión |
|---|---|---|
| WPF, CIM, eventos, Robocopy, DISM, SFC, exportación de drivers | Base viable | Conservar; probar permisos y módulos en cada edición. |
| DNS clásico | Viable | Restaurar DHCP/estático, IPv4 e IPv6 correctamente. |
| DoH del cliente del sistema | No prometerlo mediante claves de registro en Windows 10 estándar | Detectar capacidad real y ocultar lo no disponible. La documentación de seguridad del cliente lo presenta para Windows 11. [Microsoft](https://learn.microsoft.com/en-us/windows/security/book/operating-system-security-network-security). |
| Barra de tareas centrada, widgets y pestañas del Explorer | Funciones de Windows 11 | No ofrecer como tweaks equivalentes en 10. |
| BitLocker completo | Depende de edición y capacidades | No equiparar Home/Device Encryption con administración completa de BitLocker. |
| Store y App Installer | Depende de imagen y políticas | Separar ambos; no hacer de Store un requisito universal de Atlas. |
| WinGet | Compatible desde Windows 10 1809, pero no garantizado instalado/registrado | Detectar y reparar por vías oficiales; comprobar arquitectura y contexto del usuario. [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/). |
| IA local | Depende de runtime, GPU, driver y modelo | Ollama documenta Windows 10 22H2 o posterior; LTSC 2021 no cumple ese mínimo nominal. [Ollama Windows](https://docs.ollama.com/windows). |

<a id="herramientas"></a>

## 5. Auditoría herramienta por herramienta

### 01. Fase 0 — Desactivar túneles IPv6 heredados · P2

**Evidencia:** [operaciones netsh y restauración](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Fase0.ps1:233>).

La herramienta actúa sobre Teredo, 6to4 e ISATAP. Es un ajuste puntual de tecnologías de transición, no un endurecimiento universal ni una mejora demostrada de velocidad. No verifica todos los códigos de salida y “restaurar” aplica valores fijos en vez del estado anterior: puede habilitar lo que ya estaba deshabilitado por diseño.

**Propuesta:** consultar estado y políticas; explicar para qué escenario se recomienda; guardar snapshot antes de cambiar; restaurar exactamente ese snapshot y confirmar el estado final. Mantener la acción opcional. No ampliar su alcance a desactivar IPv6 nativo.

**Windows 10:** viable con `netsh` y elevación, previa detección. **Aceptación:** ejecutar dos veces no añade efectos, un equipo administrado no se sobrescribe silenciosamente y la reversión reproduce el estado previo.

### 02. Parts Upgrade Advisor · P1

**Evidencia:** [RAM/CPU](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PartsUpgrade.ps1:374>), [clasificación de almacenamiento](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PartsUpgrade.ps1:554>).

El asesor tiene valor como inventario inicial, pero infiere demasiado: usa capacidad del disco para decidir SSD/HDD cuando faltan datos; mantiene una tabla limitada de sockets; interpreta denominaciones comerciales de CPU como generaciones; puede presentar un socket como confirmado por ausencia de evidencia BGA. Los límites SMBIOS y número de slots no certifican memoria ampliable ni descartan RAM soldada. `AdapterRAM` no es una fuente suficiente para VRAM moderna.

**Propuesta:** fuentes por nivel de confianza: datos del sistema, SPD/OEM cuando estén disponibles y verificación manual del modelo exacto. Devolver “desconocido” cuando no haya evidencia. Separar observaciones de recomendaciones de compra; no recomendar un componente hasta validar placa, BIOS, formato, potencia y compatibilidad.

**Windows 10:** viable para inventario CIM/Storage. **Aceptación:** fixtures de NVMe grande, HDD pequeño, RAM soldada, varios arrays y GPU con más de 4 GB no producen afirmaciones inventadas.

### 03. Diagnóstico Master · P1

**Evidencia:** [espera de procesos](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoMaster.ps1:614>), [dependencias](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoMaster.ps1:1265>), [informe](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoMaster.ps1:1632>).

Consolida mucha información útil, pero duplica parte del asesor de ampliación y su lógica de dependencias. La espera de proceso considera éxito que este termine, sin interpretar su código. Algunas utilidades se localizan sin que eso equivalga a haber ejecutado su medición. El reporte CPU-Z depende de formato/idioma y su argumento de ruta necesita robustez ante espacios. Hay inserciones HTML que requieren escapado uniforme.

**Propuesta:** recolectores pequeños que devuelvan datos y errores explícitos, con fecha y procedencia; un solo motor de recomendaciones de hardware; renderizado HTML común. BlueScreenView debe aportar indicios y acceso al dump, no identificar automáticamente al culpable. Benchmarks y estrés deben ser acciones separadas de la lectura inicial.

**Windows 10:** ampliamente viable, con opcionales limitados por proveedor/licencia. **Aceptación:** si falta CPU-Z, un módulo o permiso, el informe conserva las demás secciones y marca la afectada como no evaluada.

### 04. Analizador de eventos · P1

**Evidencia:** [base de interpretación y lookup](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoEventos.ps1:188>), [lectura de registros](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoEventos.ps1:258>).

Las reglas `*|*|ID` confunden eventos de proveedores distintos. Las claves WHEA usan `WHEA-Logger`, pero el proveedor real es `Microsoft-Windows-WHEA-Logger`; se reprodujo el fallo de búsqueda. Existen explicaciones excesivamente específicas para IDs y sugerencias como resetear el repositorio WMI ante un fallo de dependencia de servicio. Un error al leer Security puede terminar como lista vacía; eventos desconocidos no deben rebajarse automáticamente a INFO.

**Propuesta:** clave por canal/proveedor/ID y, cuando importe, versión del evento; preservar nivel numérico, XML y mensaje original. Las causas deben ser hipótesis correlacionadas con síntomas, no diagnósticos definitivos. Leer registros protegidos con elevación opcional y declarar acceso denegado.

**Windows 10:** viable. **Aceptación:** eventos del mismo ID y distinto proveedor se distinguen; WHEA real se reconoce; acceso denegado no se presenta como ausencia de errores.

### 05. Printer Doctor · P1

**Evidencia:** [hallazgos de cola](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrinterDoctor.ps1:415>), [reparaciones](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrinterDoctor.ps1:474>).

La combinación CIM/PrintManagement es aprovechable. Sin embargo, tener trabajos en cola no significa que estén atascados. La reparación para el spooler y borra archivos de todas las colas, sin garantizar en `finally` la recuperación del servicio si falla el borrado. El manifiesto no exige administrador y la reparación no incorpora una elevación acotada. El resultado de imprimir página de prueba necesita interpretar su código.

**Propuesta:** diagnosticar por estado y antigüedad del trabajo; permitir seleccionar cola/trabajos; mostrar alcance exacto antes de vaciar; preservar y restaurar estado del spooler; registrar resultado real. Los reportes pueden contener nombres de documentos y propietarios: ocultarlos en la vista compartible por defecto.

**Windows 10:** viable. **Aceptación:** un fallo de acceso al directorio no deja el spooler detenido ni comunica reparación exitosa.

### 06. Keyboard Doctor · P1

**Evidencia:** [eventos y batería](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-KeyboardDoctor.ps1:395>), [captura y accesibilidad](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-KeyboardDoctor.ps1:512>).

La detección de dispositivos y las instrucciones de aislamiento son útiles. El porcentaje de desgaste de batería no demuestra hinchazón ni presión sobre el teclado. El monitor usa `GetAsyncKeyState` global con sondeo; no identifica el teclado físico que originó cada pulsación y puede perder eventos. Los filtros por nombres localizados de severidad son incompletos. Los cambios de accesibilidad aplican valores fijos sin snapshot del usuario.

**Propuesta:** prueba enfocada en una ventana propia, indicador visible y salida inmediata; identificar dispositivos mediante Raw Input si esa distinción es necesaria. No inferir una avería física por desgaste de batería. Usar niveles numéricos de eventos, preservar configuración de accesibilidad y ofrecer reversión. El usuario ya recibe una confirmación de monitorización; conservarla y aclarar su alcance.

**Windows 10:** viable. **Aceptación:** pruebas con dos teclados, teclado virtual, accesibilidad activa y sin batería; no generar diagnóstico de hinchazón a partir del desgaste.

### 07. AI Readiness · P1

**Evidencia:** [catálogo de modelos](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AIReadiness.ps1:367>), [puntuación y disco](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AIReadiness.ps1:451>).

`Unhealthy` pasa el patrón que acepta `healthy`: se reprodujo. La puntuación concede puntos cuando faltan discos, usa una microprueba de PowerShell como indicio de CPU para IA y asigna capacidad de GPU por VRAM sin probar backend/driver. Alcanzar un endpoint, incluso con 401/403, solo demuestra cierta conectividad; no acredita acceso autorizado. Las recomendaciones de modelos son una tabla fija, sin cuantización, contexto ni presupuesto de memoria explícitos.

**Propuesta:** separar IA en nube de ejecución local. Mostrar hardware detectado, memoria utilizable, backend disponible, driver y modelos candidatos; ensayo optativo pequeño con tokens/s y memoria reales. Catálogo versionado con fecha, tamaño, cuantización y contexto. Quitar el fallback WMI innecesario si se mantiene el mínimo PS 5.1 con CIM.

**Windows 10:** el inventario es viable; el runtime local depende del proveedor. Ollama requiere 22H2 o posterior y drivers/backend compatibles. No todos los AMD/NVIDIA se clasifican solo por GB de VRAM. [Requisitos de Ollama](https://docs.ollama.com/windows).

### 08. GPU Check · P1

**Evidencia:** [estrés y sensores](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GPUCheck.ps1:337>), [ejecución](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GPUCheck.ps1:572>), [veredicto](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GPUCheck.ps1:645>).

Puede acabar en APTO sin telemetría útil. La temperatura ACPI genérica no equivale a temperatura de GPU/hotspot. Se acumulan penalizaciones NVIDIA por muestra, de modo que duración y frecuencia afectan al veredicto; una limitación de potencia bajo carga puede ser normal. La llamada de espera no recibe el proceso de estrés aunque su función permite vigilarlo. Existe limpieza posterior del proceso: el defecto no es que nunca se detenga, sino que no se comprueba bien su ejecución durante la espera.

**Propuesta:** inventario primero; estrés separado y explícito; sensor correcto y cobertura mínima; timeout también al consultar opciones del ejecutable; cancelación y seguimiento del proceso. Emitir “no concluyente” si no hay datos. Normalizar métricas por tiempo y distinguir límites operativos de fallos.

**Windows 10:** condicionado al driver y versiones homologadas de GPU-Z/FurMark/HWiNFO. **Aceptación:** GPU sin sensores, herramienta que sale inmediatamente y cancelación nunca generan un APTO global.

### 09. Mantenimiento PRO · P1

**Evidencia:** [envoltorio de tareas](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-MantenimientoPRO.ps1:464>), [acciones de mantenimiento](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-MantenimientoPRO.ps1:615>).

DISM, SFC y Defender siguen siendo herramientas válidas. El defecto es ejecutar demasiadas acciones como rutina: limpiar cachés, vaciar papelera, resetear red y reparar componentes no responden al mismo problema. La función que envuelve tareas puede declarar éxito pese a errores no terminantes o códigos nativos. La manipulación de servicios y descargas de Windows Update requiere restauración garantizada. Detener un job no demuestra que un escaneo de Defender haya terminado correctamente.

**Propuesta:** perfil de lectura y chequeo por defecto; reparación seleccionada según hallazgos; estimación y consentimiento para pérdida de cachés/papelera; comprobación de cada código y estado final; seguimiento del reinicio. Separar reset de red porque puede cortar soporte remoto. No desactivar Defender ni ampliar excepciones para hacer que una tarea pase.

**Windows 10:** viable con permisos y políticas adecuados. **Aceptación:** fallos de DISM/SFC, Defender deshabilitado por otro antivirus y reinicio pendiente quedan reflejados sin éxito genérico.

### 10. Instalador de paquetes · P1

**Evidencia:** [bootstrap de WinGet](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-InstalarPaquetes.ps1:944>), [limpieza](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-InstalarPaquetes.ps1:1316>), [instalación/códigos](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-InstalarPaquetes.ps1:1361>).

La UI por lotes y los perfiles son útiles. El bootstrap mezcla dependencias de versiones fijas con un App Installer móvil desde `aka.ms`, y presupone x64. Los argumentos del perfil se unen como texto sin un contrato estricto para ID/source; esto permite errores o introducción de opciones, sin que se haya demostrado ejecución arbitraria de shell. El timeout mata al padre WinGet, no necesariamente a todos los instaladores que puso en marcha. No se conservan stdout/stderr de la instalación. El código de “no aplicaciones encontradas” se cuenta como “ya instalado”.

**Propuesta:** adquisición oficial coherente de App Installer y dependencias; perfil JSON con esquema y valores permitidos; argumentos correctamente delimitados; estado por paquete y log; tratar cancelación/timeout como estado pendiente de comprobar. Retirar borrado de Prefetch de la limpieza rutinaria. Añadir mínimo de OS y arquitectura por paquete.

**Windows 10:** viable si App Installer/WinGet están disponibles y la aplicación concreta lo admite. **Aceptación:** paquete inexistente falla; uno ya presente verifica su versión; una operación que sigue en segundo plano no da paso engañosamente a un estado “terminado”.

### 11. Instalar Microsoft Store · P1

**Evidencia:** [implementación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-InstalarMicrosoftStore.ps1:1>), [descripción publicada](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/config/tools.json:109>).

La descripción promete instalación sobre LTSC/IoT/imagen corporativa y descarga Appx desde CDN, pero el flujo real usa detección, `wsreset -i` en ciertos Windows 11 y WinGet/msstore. Si falta Store y falta App Installer, las instrucciones pueden terminar en una dependencia circular. Una imagen administrada puede carecer de Store por decisión de política.

**Propuesta:** renombrar como “Comprobar/reparar Store y App Installer”; separar existencia del paquete, registro para el usuario, servicio, edición y bloqueo de políticas. Ofrecer reparación soportada cuando aplique. No prometer agregar Store de forma soportada a cualquier LTSC mediante paquetes extraídos de terceros.

**Windows 10:** parcial y dependiente de edición. **Aceptación:** distinguir “no instalado”, “sin registro”, “bloqueado por política” y “no soportado”; App Installer se puede atender sin exigir que Store funcione primero.

### 12. Instalar runtimes · P1

**Evidencia:** [requisito global WinGet y perfiles](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-InstalarRuntimes.ps1:107>).

El perfil llamado mínimo instala VC++ 2013, .NET 3.5 y DirectX heredado aunque no exista una aplicación que los necesite. Detectar un runtime instalado y omitirlo no asegura que esté actualizado. WinGet se exige incluso para el camino nativo de .NET 3.5. VC++ 2013 es legado fuera de soporte; el runtime v14 actual no sustituye todas las generaciones antiguas. [Política de runtimes de Microsoft](https://learn.microsoft.com/en-us/lifecycle/faq/visual-c-faq).

**Propuesta:** perfil moderno con VC++ v14 x64/x86 cuando corresponda y .NET Desktop de una rama vigente si lo requiere una aplicación; perfil heredado explícito por necesidad. No desinstalar bibliotecas antiguas de las que dependan aplicaciones existentes. Para .NET 3.5, admitir origen offline de la misma compilación y registrar reinicio pendiente; no depender de WinGet para ese paso.

**Windows 10:** viable según runtime/versión. **Aceptación:** instalar o actualizar idempotentemente, sin anunciar una versión vulnerable existente como “lista”.

### 13. Instalar/actualizar PowerShell · P0 en verificación; P1 en actualización

**Evidencia:** [versión central fija](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/PS7.ps1:16>), [verificación del instalador](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-ActualizarPowerShell.ps1:231>).

Hay tres caminos de adquisición que divergen: biblioteca, herramienta y USB. La versión 7.5.0 se repite. Encontrar `pwsh` no significa que sea el parche recomendado y ordenar nombres de MSI alfabéticamente no es comparar versiones. Los fallos de autenticidad descritos en H01 requieren prioridad inmediata.

**Propuesta:** catálogo único de canal, versión y arquitectura; comparación semántica; MSI/MSIX elegido conscientemente; actualización y rollback probados; verificar versión efectiva después del instalador. Conservar 5.1 como componente del OS, no intentar sustituirlo.

**Windows 10:** instalación condicionada a la combinación soportada OS/runtime; el panel debe poder operar sus funciones nativas sin instalar 7 obligatoriamente. **Aceptación:** un MSI local sin evidencia de confianza no se ejecuta y una versión ya instalada no se reinstala o rebaja accidentalmente.

### 14. Personalización de Windows · P2

**Evidencia:** [tweaks de barra y búsqueda](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Personalizacion.ps1:244>), [aplicar conjunto](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Personalizacion.ps1:333>).

Tema, fondo y parte del color son reutilizables, pero varias claves son específicas de Windows 11. El cambio de búsqueda crea la rama `Search` y escribe el valor en `Advanced`, lo que no representa correctamente el ajuste de Windows 10. Aplicar todo reinicia Explorer varias veces. `PaintDesktopVersion` es información de versión del escritorio; no elimina una marca de activación.

**Propuesta:** tabla de ajustes por build, comprobación después del cambio, snapshot y restauración, y un único refresco de Explorer cuando sea necesario. Mostrar solo opciones aplicables y describir el efecto real. Evitar prometer estabilidad futura de claves no documentadas.

**Windows 10:** parcial; conservar las opciones demostradas y ocultar las exclusivas de 11. **Aceptación:** aplicar/revertir un perfil conserva valores previos y no interrumpe innecesariamente otras sesiones.

### 15. Stop Services / Service Optimizer · P1

**Evidencia:** [listas SAFE/MODERATE](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-StopServices.ps1:187>), [aplicación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-StopServices.ps1:268>).

Una lista “SAFE” no es universal: informes de errores, compatibilidad, impresión, biometría, Bluetooth, búsqueda o sensores pueden ser esenciales para ese cliente. No hay medición que demuestre la mejora. El snapshot existente es un buen comienzo, pero parar con `-Force` puede afectar dependientes que no se restauran completamente; la función puede devolver éxito aunque las acciones fallen.

**Propuesta:** convertirla en diagnóstico y gestión de servicios por necesidad concreta. Mostrar uso, estado y dependencias; aplicar el mínimo cambio; comprobar el snapshot antes de tocar el servicio; restaurar estado y configuración exactos. Retirar la etiqueta de optimización segura general.

**Windows 10:** viable técnicamente, con perfiles por edición/rol. **Aceptación:** un equipo con impresora, lector biométrico o soporte remoto no pierde la función por una selección genérica.

### 16. FastCopy · P1

**Evidencia:** [resolución](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-FastCopy.ps1:25>), [verificación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-FastCopy.ps1:549>), [argumentos](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-FastCopy.ps1:606>).

El parámetro `ExcludeDirs` se recibe y se transmite desde la UI, pero no se utiliza al construir la ejecución. Por ello el usuario puede creer que excluyó directorios que se copian. El verificador muestrea hasta 15 archivos con MD5; no acredita integridad de todo el conjunto. Con cero archivos devuelve `OK=true`, reproducido. Las tasas calculadas por diferencia de tamaño del destino no representan bytes escritos al sobrescribir. La búsqueda manual y el gestor central no usan exactamente las mismas rutas.

**Propuesta:** corregir exclusiones; apoyarse en verificación nativa de FastCopy o en un manifiesto completo, y llamar “muestreo” a la opción rápida. Previsualización y confirmación diferenciada de mover/sincronizar; pruebas con varios orígenes y destino existente. Resolver coherentemente dependencias y licencias.

**Windows 10:** el proveedor lo contempla. La versión publicada consultada es **5.12.0**, frente a 5.11.2 fija en Atlas; el uso laboral actual exige licencia Pro. Mantener Robocopy como alternativa nativa y no congelar una versión vieja solo para evitar condiciones de licencia. [Manual y licencia de FastCopy](https://fastcopy.jp/help/fastcopy_eng.htm).

### 17. Preparar USB offline · P1

**Evidencia:** [descarga de launcher](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrepararUSB.ps1:572>), [dependencias](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrepararUSB.ps1:675>), [lista de herramientas](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrepararUSB.ps1:1080>), [actualización](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrepararUSB.ps1:1467>).

Mantiene una lista manual de 26 herramientas y omite Respaldo de Controladores, aunque el manifiesto tiene 27. Acepta herramientas existentes sin verificar y nuevas por tamaño mínimo. El endpoint raíz del Worker devuelve `get.ps1`, pero esta rutina espera un launcher grande, lo rechaza por tamaño y recurre a otra URL. PowerShell, FastCopy y dependencias tienen adquisiciones duplicadas. El bootstrap offline puede actualizar launcher sin hash cuando no consigue el esperado y sin actualizar todo el conjunto asociado.

**Propuesta:** generar la USB desde un release verificado y el manifiesto único; inventario de todos los archivos, hashes, licencias y versiones; validación completa antes de declarar terminada la preparación; launcher offline que no necesite refrescarse. Actualización optativa y atómica del paquete entero. Declarar por herramienta “offline completo”, “offline parcial” o “requiere conexión”.

**Windows 10:** viable. **Aceptación:** arrancar en VM desconectada, desde letra variable y ruta con espacios; detectar USB incompleta/corrupta; las 27 entradas tienen fuente o explicación clara de indisponibilidad.

### 18. Respaldo de controladores · P1

**Evidencia:** [exportación y fallback](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-RespaldoControladores.ps1:59>).

La implementación actual es nativa con `Export-WindowsDriver`/DISM, pero el manifiesto sigue anunciando un BAT externo. Es una mejora real que la documentación no refleja. El fallback de DISM necesita delimitar correctamente destinos con espacios; rutas relativas requieren normalización antes de calcular el inventario. Contar INF no prueba que se haya exportado todo lo esperado.

**Propuesta:** mantener el camino nativo; guardar proveedor, versión, clase, ID y hash de cada paquete; comprobar código DISM y coherencia del inventario. Aclarar que exporta controladores de terceros, no una imagen completa del sistema ni necesariamente todos los componentes OEM. La restauración debe seleccionar lo apropiado al hardware, sin reinstalar masivamente drivers antiguos.

**Windows 10:** viable con elevación. **Aceptación:** destino con espacios, exportación vacía y DISM fallido producen resultados inequívocos.

### 19. Robocopy · P1

**Evidencia:** [ejecución](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Robocopy.ps1:474>), [validación de rutas](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Robocopy.ps1:631>).

El manifiesto lo llama “Mirror”, pero el comando usa `/E` y no `/MIR`. No se encontró un borrado espejo provocado por esa opción: el problema es la promesa equivocada. Tiene buenas decisiones como reintentos limitados, exclusión de junctions y manejo de códigos 0–7. Comparte el muestreo MD5 y las métricas por crecimiento del destino. `/FFT` se aplica siempre aunque no todos los destinos necesitan tolerancia FAT de tiempo.

**Propuesta:** conservar como motor básico de copia y renombrar su modo real. No añadir `/MIR` para hacer coincidir el nombre sin diseñar antes previsualización y protección ante borrado. Configurar timestamps/ACL según origen y destino; medir desde resultados de copia; verificación completa opcional y muestreo claramente identificado. Validar solapamientos y rutas con diferencias de mayúsculas, UNC y reparse points.

**Windows 10:** excelente candidato a base nativa. **Aceptación:** pruebas de sobrescritura, disco lleno, archivo bloqueado, interrupción, SMB y copia incremental, sin falso “respaldo completo”.

### 20. Selector DNS · P1

**Evidencia:** [aplicación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-SelectorDNS.ps1:333>), [backup/restore/estado](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-SelectorDNS.ps1:452>), [inicio automático](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-SelectorDNS.ps1:572>).

Escribe configuración DoH sin comprobar OS/capacidad y deduce “activo” desde el registro. El backup contiene IPv4 e IPv6, pero restore solo aplica IPv4 y no conserva adecuadamente el origen DHCP/estático ni DoH. Ping ICMP mide otra cosa que la latencia de resolución DNS. La tarea de inicio apunta a un archivo que define la función, sin invocarla.

**Propuesta:** DNS clásico interoperable; DoH solo mediante capacidades documentadas y comprobación real; respaldo por GUID de interfaz, origen de configuración, ambas familias y valores previos. Medir consultas DNS con caché controlada. Revisar si el inicio automático es necesario: normalmente Windows conserva DNS. Eliminarlo si no aporta valor.

**Windows 10:** viable para DNS clásico, con límites explícitos para cifrado. **Aceptación:** restaurar una interfaz originalmente DHCP vuelve a DHCP; no anunciar DNS cifrado por una clave presente.

### 21. Hosts Manager · P1

**Evidencia:** [alta y borrado](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-HostsManager.ps1:243>).

El borrado busca una coincidencia de texto y elimina la línea completa: un dominio parcial puede afectar otro dominio o varios alias de la misma línea. Alta y borrado no hacen siempre el backup prometido. Las listas externas se agregan sin un bloque gestionado que pueda sustituirse limpiamente, generando duplicación con el tiempo. Faltan validación de IP/hostname y límites del contenido importado.

**Propuesta:** parser sencillo por tokens que preserve comentarios y alias; backup previo a cada mutación; escritura atómica y preservación de ACL; bloque delimitado para listas gestionadas; validar formato y tamaño de la descarga; vaciar caché DNS cuando corresponda. Deshacer la operación concreta, sin borrar cambios ajenos posteriores.

**Windows 10:** viable. **Aceptación:** borrar `example.com` conserva `notexample.com` y otros alias; importar dos veces produce el mismo resultado.

### 22. Auditoría de router · P1

**Evidencia:** [subred y gateway](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AuditoriaRouter.ps1:572>), [escaneo](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AuditoriaRouter.ps1:780>), [WAN](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AuditoriaRouter.ps1:1105>), [Wi-Fi](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AuditoriaRouter.ps1:1675>).

El escaneo presupone `/24` y direcciones 1–254, ignorando el prefijo real. ICMP ausente no demuestra que no exista un equipo. La selección de gateway puede verse afectada por VPN/métricas. Probar la IP pública desde la misma LAN depende de NAT loopback/CGNAT y no acredita exposición desde Internet; por ello “router bien configurado” es una conclusión excesiva. El parser Wi-Fi mezcla frases de distintos idiomas y puede interpretar falta de clave leída como red abierta.

**Propuesta:** derivar rangos de prefijo e interfaz elegida; limitar alcance y concurrencia; marcar cobertura incompleta; distinguir configuración local, accesibilidad LAN y observación externa. Validación WAN solo desde un punto externo autorizado o como no concluyente. Preferir APIs/datos estructurados y manejar permisos en perfiles Wi-Fi. No exportar contraseñas salvo elección explícita; el consentimiento que ya existe debe mantenerse.

**Windows 10:** viable para auditoría local; pruebas externas requieren conexión y alcance definido. **Aceptación:** `/25`, `/16`, VPN, CGNAT, ICMP filtrado y Windows en español no generan garantías falsas.

### 23. Gestor BitLocker · P0

**Evidencia:** [mapeo de disco](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GestorBitLocker.ps1:209>), [imagen de clave](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GestorBitLocker.ps1:363>), [exportación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GestorBitLocker.ps1:650>), [activación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GestorBitLocker.ps1:803>).

Además de H02, la comprobación de salud puede asociar incorrectamente el volumen con `Get-PhysicalDisk` y terminar examinando el primer disco. Una comprobación positiva de otro dispositivo no debe autorizar cifrado. `Generate-QRCode` genera una imagen de texto, no un QR real. El manifiesto promete suspensión pero el menú se centra en activar/desactivar; desactivar cifra inversamente el contenido y no equivale a suspender protectores.

**Propuesta:** antes de ampliar funciones, rediseñar el flujo de recuperación y la distinción sistema/datos; vincular discos mediante asociaciones fiables, respetar políticas organizativas, separar suspensión/reanudación/descifrado y confirmar estado final. Quitar la sugerencia de pegar la recuperación al chasis y evitar persistencia en escritorio o logs por defecto.

**Windows 10:** administración completa condicionada a edición y módulos; Home requiere detección específica de Device Encryption. **Aceptación:** pruebas en VM con vTPM, sin TPM, volumen de datos y backup fallido; nunca declarar custodia verificada sin evidencia.

### 24. Menor Privilegio · P0 en cuentas; P2 en simplificación

**Evidencia:** [creación de administrador](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-MenorPrivilegio.ps1:501>), [degradación de cuenta](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-MenorPrivilegio.ps1:517>).

El uso de SID de grupos es correcto. La comprobación de otro administrador es insuficiente y la identidad del usuario elevado puede no ser el usuario original. Crear cuentas con `PasswordNeverExpires` por defecto no constituye una estrategia completa de administración: necesita un mecanismo de custodia y ciclo de vida, no simplemente forzar cambios de contraseña periódicos sin motivo. Los cambios de UAC deben respetar GPO/MDM y registrar el estado anterior.

**Propuesta:** acciones pequeñas con precondiciones verificables y resultado posterior; distinguir local, Microsoft y dominio; preservar una vía administrativa operativa. Para dispositivos gestionados, evaluar la política corporativa de administración local, por ejemplo Windows LAPS donde aplique, sin implantarla automáticamente en equipos domésticos.

**Windows 10:** viable con runtime x64 y módulo LocalAccounts disponible. **Aceptación:** un Administrador integrado deshabilitado no permite degradar al único administrador habilitado.

### 25. Extraer licencias · P1

**Evidencia:** [OA3 y portapapeles](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-ExtraerLicencias.ps1:89>), [clasificación de activación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-ExtraerLicencias.ps1:229>), [Office legado](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-ExtraerLicencias.ps1:505>).

No encontrar OA3 en firmware no demuestra que el equipo no viniera con Windows. RETAIL/OEM/MAK no prueban autenticidad y KMS no prueba emulación: puede ser activación empresarial legítima. La presencia de claves antiguas de registro tampoco acredita activación actual de Office. La licencia digital o suscripción no siempre tiene una clave completa recuperable y reutilizable. Copiar al portapapeles no es una operación confidencial por definición.

**Propuesta:** renombrar “Inventario de activación y licencias”; informar canal, estado y limitaciones con fuentes nativas; ocultar claves por defecto y exportar solo con elección expresa. Para Microsoft 365 separar suscripción/identidad/activación de claves de versiones perpetuas. No emitir veredictos “original/pirata” a partir del canal.

**Windows 10:** viable para consulta nativa, condicionado al producto Office. **Aceptación:** licencia digital sin OA3, KMS corporativo y Microsoft 365 no se clasifican erróneamente.

### 26. Deduplicador y conversor · P1, componente incompleto

**Evidencia:** [wrapper](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Deduplicador.ps1:1>), [ruta personal y proceso](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Deduplicador.ps1:161>).

El repositorio contiene el wrapper, pero no `app_deduplicar.py`. No es posible auditar su algoritmo, borrado, seguridad HTTP ni conversión. Instala Pillow mediante `pip` global sin fijación ni entorno aislado y puede resolver un Python distinto o un alias de Store. Hay una ruta personal codificada. La gestión por título de ventana y puerto ocupado no identifica de forma fiable el proceso propio; se puede abrir el navegador aunque el backend no haya arrancado.

**Propuesta:** incorporar/versionar el backend y sus requisitos o retirar temporalmente la promesa de herramienta integrada. Usar un entorno privado o distribución autocontenida, `python -m pip` si se usa pip, PID propio y healthcheck con identidad de sesión. Duplicados exactos requieren hash completo; similitud perceptual requiere revisión; borrado mediante cuarentena reversible. La dependencia real de conversión debe confirmarse en el backend antes de elegir FFmpeg u otra librería.

**Windows 10:** pendiente hasta disponer de ese componente y homologar Python/librerías. **Aceptación:** usuario sin Python, puerto ocupado por otra app, archivos grandes y cancelación no borran datos ni se confunden con arranque correcto.

### 27. Entrega PC · P0 en administración; P1 en informe

**Evidencia:** [cuentas](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-EntregaPC.ps1:330>), [parámetro inexistente](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-EntregaPC.ps1:514>), [BitLocker en reporte](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-EntregaPC.ps1:676>), [checklist](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-EntregaPC.ps1:892>).

Se mezcla protocolo de entrega con creación/eliminación de usuarios y cambios de contraseña. Se confirmó que `Set-LocalUser -NoPassword` no existe. Deben bloquearse administradores sin contraseña y operaciones sobre el último administrador utilizable. El HTML enmascara claves, lo cual es positivo, pero el texto de fallback “Escrow Active” no demuestra un respaldo. Los checkboxes del HTML cambian en el navegador sin persistencia de los resultados; marcar todo no equivale a haber realizado las pruebas.

**Propuesta:** separar gestión de cuentas y entrega; registrar qué pruebas se ejecutaron, cuáles fueron manuales y cuáles quedaron pendientes. El acta debe guardar selección final, fecha, versión de Atlas, estado de actualizaciones, reinicio, respaldo y custodia de recuperación realmente verificados. Evitar resets administrativos de contraseña sin explicar el impacto sobre datos protegidos de ese usuario.

**Windows 10:** viable. **Aceptación:** reapertura del acta conserva su estado, no muestra escrow sin comprobación y las operaciones de cuenta fallidas no figuran como completadas.

<a id="dependencias"></a>

## 6. Dependencias externas y prácticas desactualizadas

### 6.1 Herramientas auxiliares del panel

El registro central está en [Dependencies](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/Dependencies.ps1:7>). Ya ayuda a localizar ejecutables, pero cada herramienta vuelve a implementar parte de esa tarea. Encontrar un archivo por nombre o en PATH no acredita identidad, versión, arquitectura ni integridad. Los ejecutables instalados legítimamente no necesitan tener el mismo hash para todas sus versiones, pero sí una política de confianza y versión admitida.

| Dependencia | Situación observada | Recomendación y límite Windows 10 |
|---|---|---|
| PowerShell 7 | 7.5.0 fija en varios caminos | Homologar 7.6 LTS al parche vigente, con selección de instalador y capacidad por herramienta. Conservar 5.1 para operaciones nativas que lo requieran. |
| FastCopy | Descarga directa 5.11.2 con hash en el registro; USB usa otro flujo | Evaluar 5.12.0 actual, licencia de taller y verificación nativa. Windows 10 figura en requisitos oficiales. |
| WinGet/App Installer | Detección e instalación duplicadas; mezcla de releases | Usar distribución oficial y paquetes dependientes de una misma versión; registro por usuario y arquitectura. No confundir presencia de Store con disponibilidad de WinGet. |
| CPU-Z | ID WinGet y rutas diversas; parser textual del informe | Conservar como opcional y homologar formato/parámetros de la versión elegida; verificar firma y driver incluido. El sitio consultado publica 3.01. No deducir compatibilidad de cada binario solo por el ID WinGet. [CPUID](https://www.cpuid.com/softwares/cpu-z.html). |
| BlueScreenView | Apoya lectura de minidumps | Conservar como visor opcional; aclarar que un módulo listado no prueba causa raíz. Para casos complejos, análisis específico del dump. Validar formatos y permisos en Windows 10. |
| BatteryInfoView | Detección/ejecución externa para información de batería | Mantener como complemento, con fallback a información nativa; comparar wear/capacidad con incertidumbre. No usarlo para certificar ausencia de hinchazón. |
| CrystalDiskInfo | Requiere ejecutable y carpeta `CdiResource`; hay comprobación útil | Conservar el paquete completo y su procedencia. SMART/NVMe con significado por fabricante, USB/RAID y dispositivos no observables explícitos. No homologar salud por porcentaje genérico. |
| CrystalDiskMark | Búsqueda de varias generaciones y recursos | Benchmark opcional; dimensionar escrituras y no usarlo como comprobación rutinaria de salud. Homologar salida y runtime del paquete en Windows 10. |
| GPU-Z | Identificado por nombre/WinGet | Conservar para inventario/telemetría cuando aplique; guardar versión y cobertura. No supone soporte de cualquier GPU/driver. |
| FurMark 2 | Se examina ayuda para decidir argumentos | Versión y CLI probadas; límite de tiempo, cancelación y sensores fiables. La documentación web de Geeks3D no pudo leerse por restricción del sitio en esta auditoría: no se certifica aquí el último binario sobre Windows 10. |
| HWiNFO64 | Dependencia de diagnóstico/GPU | La edición gratuita es personal/no comercial; la automatización por línea de comandos y uso de taller requieren revisar licencia Pro adecuada. El proveedor distingue Engineer/Corporate de Personal. No asumir que instalar con WinGet concede esos derechos. [Licencias HWiNFO](https://www.hwinfo.com/licenses/). |
| Python/Pillow | Backend ausente, instalación global y sin fijación | Distribuir backend completo con entorno privado y versiones probadas. Python 3.12 está en mantenimiento de seguridad con releases de código fuente, no es la mejor nueva base binaria para un cliente de Windows. Elegir una rama con instaladores mantenidos y compatibilidad de Pillow comprobada. [Calendario Python 3.12](https://peps.python.org/pep-0693/). |
| RustDesk/onboarding | Se descarga script de repositorio privado no incluido | Pendiente auditar instalador real, versión, firma, configuración y autorización de acceso remoto. El BAT público verifica SHA, pero la autenticidad depende de la cadena de publicación. |
| Listas Hosts, servicios de IP pública y sitios de prueba de red | Fuentes de datos externas | Catálogo de dominios/propósito, límites, timeout y errores diferenciados. Pérdida del proveedor no debe producir un resultado favorable. |

No se propone sustituir cada herramienta por “la más nueva”. Primero hay que homologar una versión concreta en el flujo que utiliza Atlas, revisar licencia y conservar un mecanismo de actualización. Es particularmente importante cuando un ejecutable incorpora controladores o se redistribuye en USB.

### 6.2 Catálogo de 52 aplicaciones

La tabla cubre todos los elementos del catálogo. **“Validar paquete” significa que el wrapper puede gestionarlo, pero no se certificó la versión actual del proveedor en una VM Windows 10.** La validación deberá capturar `MinimumOSVersion`, arquitectura, tipo de instalador, ámbito usuario/equipo, versión, fuente y reinicio. La compatibilidad de WinGet no se transmite automáticamente al software que instala.

| Aplicación del catálogo | Decisión propuesta |
|---|---|
| Google Chrome | Mantener optativo; validar paquete/OS y no modificar navegador predeterminado por sorpresa. |
| Mozilla Firefox | Mantener optativo; validar rama, arquitectura y políticas del cliente. |
| Brave | Mantener optativo; validar paquete y evitar varios navegadores por defecto. |
| Opera | Mantener optativo; misma validación. |
| VLC | Mantener; validar versión y asociaciones solicitadas. |
| Spotify | Mantener opcional; verificar contexto de instalación por usuario y licencia/cuenta. |
| OBS Studio | Mantener opcional; compatibilidad real depende también de GPU y driver. |
| Audacity | Mantener opcional; validar paquete y runtime. |
| Free Download Manager | Mantener optativo, según necesidad del cliente. |
| qBittorrent | Mantener optativo, sin instalarlo como parte de un paquete básico universal. |
| Microsoft 365 | Condicionar a licencia, cuenta y soporte del OS; no presentar instalación como activación. Ver la situación específica de Office en la fuente oficial de Windows 10 citada antes. |
| LibreOffice | Alternativa optativa de oficina; validar versión, formatos y asociaciones. |
| ONLYOFFICE Desktop Editors | Alternativa optativa; no instalar varios suites salvo petición. |
| Adobe Acrobat Reader 64-bit | Mantener con detección x64; no ofrecer a x86. Validar paquete vigente. |
| Notion | Mantener opcional; requiere también servicio/cuenta, no basta instalar. |
| Obsidian | Mantener opcional; validar paquete. |
| Simple Sticky Notes | Mantener opcional; considerar exportación previa si reemplaza una instalación. |
| LanguageTool Desktop | Verificar existencia y mantenimiento del ID antes de conservarlo como opción estable. |
| Zoom | Mantener optativo; validar variante usuario/equipo y políticas. |
| Microsoft Teams | Validar cliente actual y requisitos; no ofrecer paquetes de generaciones retiradas por similitud de nombre. |
| Discord | Mantener optativo; validar paquete y actualizador por usuario. |
| Signal | Mantener optativo; la instalación no vincula automáticamente una cuenta. |
| Telegram Desktop | Mantener optativo; validar paquete. |
| WhatsApp Desktop | Entrada `msstore`: comprobar Store, región, cuenta y aplicabilidad antes de encolar. |
| JW Library | Entrada `msstore`: mismas precondiciones; no prometerlo para LTSC sin Store. |
| 7-Zip | Mantener como opción de archivo; comprobar versión mantenida. |
| WinRAR | Mantener optativo con nota de licencia; no equiparar trial a licencia adquirida. |
| PowerToys | Requisito contrastado: Windows 10 2004/build 19041 o posterior y x64/ARM64; requiere WebView2. [Microsoft](https://learn.microsoft.com/en-us/windows/powertoys/install). |
| Everything | Mantener; explicar ámbito del índice/servicio y validar instalación. |
| Greenshot | Mantener como alternativa de captura; evitar duplicidad por defecto con ShareX. |
| ShareX | Mantener como alternativa; conservar preferencias del usuario y validar runtime. |
| WinDirStat | Mantener como análisis de espacio; no asociarlo a borrado automático. |
| Rufus | Mantener optativo; instalarlo no autoriza formatear una unidad. Homologar OS/arquitectura. |
| CPU-Z | Reutilizar la dependencia central; no mantener dos criterios de adquisición. |
| GPU-Z | Reutilizar la dependencia central y versión homologada. |
| CrystalDiskInfo | Reutilizar la dependencia central, recursos y política de versión. |
| Seafile Client | Mantener solo cuando el cliente tenga un servidor/cuenta; validar el ID y variante de cliente. |
| Explorer Tab Utility | **No ofrecer en Windows 10.** El proyecto exige Windows 11 22H2/build 22621 o posterior y pestañas del Explorador. [Requisitos del autor](https://github.com/w4po/ExplorerTabUtility/blob/master/README.md). |
| Visual Studio Code | Mantener para perfil de desarrollo, validar paquete/OS y ámbito. |
| Git | Mantener para desarrollo; no necesario para usar el panel distribuido. |
| GitHub Desktop | Mantener optativo de desarrollo; no requisito de Atlas. |
| Node.js LTS | Mantener para desarrollo, resolver rama LTS compatible y registrar versión. No lo requiere el cliente del panel para tareas PowerShell. |
| Python 3.12 | Sustituir la selección fija por una rama binaria mantenida y probada; preservar entornos existentes. |
| PowerShell 7 | Unificar con la herramienta de actualización y especificar tipo de instalador. |
| Windows Terminal | Optativo, no prerrequisito del launcher ni sustituto de PowerShell. Validar distribución según OS/App Installer. |
| Malwarebytes | Optativo y compatible con política del cliente; distinguir análisis bajo demanda de protección residente. |
| Bitdefender Antivirus Free | Validar ID/edición/disponibilidad actual; no instalar junto a otro motor residente sin evaluación. |
| Bitwarden | Alternativa optativa de gestor; instalación no realiza migración de secretos. |
| KeePassXC | Alternativa optativa local; no crear base o contraseña maestra automáticamente. |
| WireGuard | Optativo; instalación no acredita conectividad, requiere configuración autorizada. |
| Steam | Perfil gaming optativo; validar instalador y recursos del equipo. |
| Epic Games Launcher | Perfil gaming optativo; mismas condiciones. |

La acción adicional `__action:clean-temp` no es un paquete. Debe salir del catálogo de instalación o presentarse como una acción distinta, con alcance y resultado propios. Se recomienda retirar de ella el borrado rutinario de Prefetch.

### 6.3 Qué está realmente obsoleto y qué no

| Práctica | Evaluación |
|---|---|
| Fijar PowerShell 7.5.0 en varios scripts | Desactualizado y próximo al fin de ciclo de su rama; sustituir por catálogo/canal homologado. |
| Recomendar Node 20+ para desarrollar el Worker | Desactualizado: el lock de Wrangler ya exige Node >=22 y Node 20 está EOL. Usar una LTS mantenida, por ejemplo 24, con versión fijada para CI. [Calendario oficial Node](https://github.com/nodejs/Release/blob/main/README.md). |
| Instalar VC++ 2013/XNA/DirectX legado como mínimo universal | Enfoque heredado; mantener solo por dependencia concreta, no retirar a ciegas lo que una aplicación usa. |
| Vaciar Prefetch, resetear red y parar servicios como optimización universal | Práctica injustificada sin evidencia del problema; reemplazar por diagnóstico y acciones selectivas. |
| Inferir SSD por tamaño, avería por un evento aislado o GPU sana sin datos | Heurísticas incorrectas; no se corrigen actualizando únicamente versiones. |
| `Get-WmiObject` como fallback donde CIM ya es requisito | Deuda prescindible y problemática para PS7; usar CIM con errores explícitos. |
| Windows PowerShell 5.1 | No es automáticamente una mala elección: es componente de Windows y útil para compatibilidad de módulos. |
| WPF | No es el origen de los principales defectos; conservar mientras cumpla la experiencia requerida. |
| DISM, SFC, Robocopy y Export-WindowsDriver | Herramientas nativas válidas; modernizar su invocación, alcance y verificación. |
| MD5 para muestreo de copia | No adecuado como garantía de autenticidad; para copia el problema mayor es prometer integridad total de una muestra. Etiquetar alcance y ofrecer verificación completa con algoritmo actual. |
| JSON de manifiestos y scripts separados | Diseño razonable; falta coherencia de publicación y un contrato único. |
| TOML del Worker | No hay necesidad de migrarlo solo por estética; evaluar JSONC si una capacidad concreta lo necesita. |

<a id="arquitectura"></a>

## 7. Bibliotecas, interfaz, Worker y entrega del software

### 7.1 Responsabilidades de las bibliotecas

| Biblioteca | Conservar | Cambio recomendado |
|---|---|---|
| Branding | Configuración de marca, rutas y paleta | Separar creación de directorios privilegiados del tema. Comprobar salida de `icacls`; un intento de ACL no es garantía de que se aplicó. [Implementación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/Branding.ps1:138>). |
| Strings | Diccionarios y selección de idioma | Validar claves faltantes y placeholders; reutilizar textos comunes. Buscar por nombre/descripción traducidos. |
| Admin | Detección y elevación | Citar rutas; devolver código/resultado del hijo cuando se espera; distinguir usuario original y elevado. [Implementación](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/Admin.ps1:1>). |
| Logging | Destino común y niveles | ID de ejecución, eventos estructurados, rotación y política de datos sensibles. Las herramientas aún escriben muchos logs por su cuenta. |
| ToolKit | Helpers sencillos de UI/reportes | Establecer su API y hacer que las herramientas realmente lo reutilicen; no capturar errores de importación para continuar como si nada en funciones indispensables. |
| Dependencies | Registro por nombre e instalación bajo demanda | Añadir versión/arquitectura/licencia/firma/capacidades; resolver recursos de los paquetes completos; eliminar las copias divergentes. |
| PS7 | Detección y gestión del runtime | Unificar adquisición, versiones, instalación y verificación con la herramienta y USB. |
| ToolRunner | Obtención, hash, caché y ventana por herramienta | Runtime por manifiesto, comillas, resultado al panel, bibliotecas disponibles y activación atómica. No modificar el archivo de fuente para añadir BOM; preparar una copia de ejecución verificada. [BOM](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/ToolRunner.ps1:494>). |

Los directorios bajo el usuario y sus ACL son una mejora frente a un temporal abierto a todos, pero no separan automáticamente un proceso elevado del código modificable por el mismo usuario. La estrategia debe verificar y preparar el artefacto definitivo en el contexto apropiado, y fallar si no se puede garantizar la precondición. No se presenta esto como una explotación UAC demostrada.

Hay también una rama de fallback a caché inválida en [ToolRunner](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/ToolRunner.ps1:430>). Su alcance depende de que el archivo rechazado siga existiendo después del intento de eliminación. Debe desaparecer como posibilidad: solo una copia validada puede servir de fallback. Se trata de una condición estática identificada, no de un ataque reproducido.

### 7.2 Interfaz y experiencia del técnico

La ventana difiere algunas consultas hasta después de renderizar, lo cual ayuda al arranque, pero el [DispatcherTimer](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/GUI/MainWindow.ps1:579>) sigue ejecutando consultas sincrónicas en el hilo de UI. El [clic de ejecución](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/GUI/MainWindow.ps1:790>) también puede bloquear mientras obtiene scripts. Si WMI, red o un proveedor tarda, el panel puede parecer congelado.

Recomiendo un worker/runspace para obtención y consultas, con actualizaciones mínimas mediante Dispatcher, cancelación y un límite de tiempo. No hace falta convertir todo el proyecto en asíncrono: empezar por las operaciones observadas que bloquean la ventana.

Cada tarjeta debería mostrar, antes de ejecutar: compatibilidad, administrador si corresponde, conexión necesaria, estado de dependencia y alcance de la acción. “Lanzada” debe diferenciarse de “completada”. Los reportes deberían abrirse desde el panel y poder generarse en versión técnica o compartible sin claves, SSID, nombres de documentos o identificadores innecesarios.

Para Windows 10 son importantes la prueba a 1366×768, escalado 125/150/200 %, alto contraste, navegación por teclado, texto largo en español y rutas de perfil redirigidas. No se realizó auditoría visual interactiva exhaustiva; esas pruebas están en el plan. La documentación de cambio de idioma en caliente tampoco coincide plenamente con el mensaje actual que pide reiniciar.

### 7.3 Worker de Cloudflare

El Worker es pequeño y se puede mantener así. Usa Web Crypto para el digest, espera sus llamadas de red y no se observó estado mutable por solicitud almacenado globalmente. La configuración tiene observabilidad habilitada y `compatibility_date = 2026-07-01`; no es una configuración olvidada durante años.

Además de la confianza de los hashes, referencias y privacidad ya descritas, propongo:

- Rutas y métodos explícitos; 404/405 para lo que no corresponda. Actualmente una ruta desconocida devuelve bootstrap.
- Timeout y captura de fallos upstream; respuestas de error consistentes sin filtrar detalles internos innecesarios.
- Límite de tamaño y/o streaming para respuestas que no requieren transformarse; el digest sí necesita un tratamiento controlado del cuerpo.
- Health de proceso separado de readiness de dependencias. `/healthz = ok` solo demuestra que responde esa función.
- Logs estructurados de versión/ruta/estado/duración; nunca cuerpos de instaladores privados, PAT o claves de cliente.
- Tests de upstream caído, digest, ref inexistente, caché y autorización. Las reproducciones con mocks de esta auditoría no validan el comportamiento real del caché de Cloudflare.

Estas recomendaciones corresponden a manejo explícito de errores, límites, streaming y observabilidad de la [guía oficial de Workers](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/). Se contrastaron los tipos actuales de Workers y el esquema publicado de Wrangler. No se necesita habilitar APIs Node en el Worker actual por el mero hecho de usar Node para desarrollar.

**Dependencias:** `package.json` declara `wrangler ^4.24.3`, mientras el lock fija **4.107.0**. El registro npm consultado ofrece **4.152.0**, con Node >=22. `npm audit` devuelve cuatro paquetes afectados de gravedad alta: **Wrangler, Miniflare, Sharp y Undici**. Son cuatro nodos del árbol, no cuatro defectos independientes del código de Atlas; contienen varios avisos transitivos. Los avisos incluyen [Sharp/libvips](https://github.com/advisories/GHSA-f88m-g3jw-g9cj) y [Undici/validación TLS](https://github.com/advisories/GHSA-w293-vg96-wgc3).

**Acción:** actualizar Wrangler y regenerar lock en rama, usar `npm ci`, ejecutar pruebas del Worker y repetir auditoría después del cambio. 4.152.0 es una candidata actual a homologar, no una versión que se haya instalado y probado aquí. Node de desarrollo y Worker de producción son entornos distintos; estos paquetes no aparecen importados por el handler de producción revisado.

El [helper de secretos](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/api/cloudflare-worker/set-worker-secrets.ps1:1>) debe comprobar el código nativo antes de mostrar éxito. No se ejecutó ni se leyeron secretos. Revisar permisos mínimos del PAT forma parte de la configuración futura, sin dar por hecho que ahora son excesivos.

### 7.4 CI, publicación y documentación

La prioridad de CI debe ser detectar fallos de comportamiento, no lograr cero advertencias cosméticas de golpe. De las 399 advertencias locales, **178 son catches vacíos**, **133 verbos no aprobados**, **19 ShouldProcess** y **16 asignaciones a variables automáticas**. Empezaría por catches que ocultan errores, variables automáticas y funciones que mutan estado; después estilo.

Fijar versiones de Pester/PSScriptAnalyzer y acciones; usar SHA revisados para acciones externas y una política periódica de actualización. La publicación debería adjuntar paquete completo, manifiesto, checksums y evidencia de pruebas, no solo `launcher.ps1`. Versionar el producto realmente: el `1.0.0` constante no permite trazar qué conjunto recibió el cliente.

Las copias de workflows en `docs/ci` deben eliminarse o generarse desde la fuente real para no dar instrucciones divergentes. El README tiene inventario desactualizado; corregir también “Driver Backup External BAT”, “Robocopy Mirror”, promesas de Store y “offline”. Documentar cada herramienta con una ficha breve generada desde el manifiesto y enlaces a casos/limitaciones.

### 7.5 Simplificación de complejidad

Esta subsección aplica el criterio de la skill ponytail-audit únicamente a duplicación y tamaño; los problemas de seguridad y corrección se evaluaron por separado. Estimación conservadora, no una reducción medida después de implementar:

- `shrink:` consolidar adquisición de PowerShell y dependencias repetida en USB, actualizador y biblioteca. Reemplazo: catálogo y funciones existentes compartidas, aproximadamente 200 líneas netas. [PS7](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/PS7.ps1:1>).
- `shrink:` consolidar inventario/heurísticas de ampliación duplicadas. Reemplazo: un recolector usado por Parts Upgrade y Diagnóstico Master, aproximadamente 150 líneas netas. [Parts Upgrade](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PartsUpgrade.ps1:374>).
- `delete:` quitar recetas de workflows duplicadas. Reemplazo: enlaces a `.github/workflows`, aproximadamente 100 líneas netas según documentación que se conserve. [Documentación CI](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/docs/ci/README.md:1>).
- `native:` retirar tarea de reaplicación DNS si solo repite configuración persistente de Windows. Reemplazo: persistencia nativa y restauración bajo demanda, aproximadamente 30 líneas netas. [Selector DNS](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-SelectorDNS.ps1:572>).
- `shrink:` eliminar lista USB de herramientas mantenida manualmente. Reemplazo: iterar `tools.json`, aproximadamente 20 líneas netas. [Preparar USB](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrepararUSB.ps1:1080>).

`net: -500 lines, -0 deps possible.` La cifra es un orden de magnitud para planificar; no incluye pruebas nuevas ni se suma al ahorro de la eventual elección de Robocopy como único motor. No recomiendo retirar dependencias útiles solo para mejorar una métrica.

<a id="plan"></a>

## 8. Plan de trabajo propuesto

### 8.1 Orden de ejecución y esfuerzo

Las estimaciones son **días efectivos de ingeniería**, de una persona familiarizada con PowerShell/Windows, sin tiempos de compra de licencias o de conseguir hardware. No son un compromiso contractual. Hay incertidumbre adicional en backend ausente, imágenes LTSC y paquetes de terceros.

| Fase | Entrega | Trabajo principal | Estimación |
|---|---|---|---|
| 0 — Base y restricciones | Matriz de soporte y pruebas reproducibles | Adoptar 22H2 x64/Home-Pro y LTSC 2021; definir acciones temporalmente restringidas; convertir reproducciones críticas en tests; fijar entorno CI. | 2–3 días |
| 1 — Operaciones críticas | Versión de estabilización | H01/H02/H03: verificaciones obligatorias, protección de cuentas, flujo de recuperación BitLocker; corregir argumentos y códigos WinGet; impedir APTO sin datos. | 5–8 días |
| 2 — Distribución y runtime | Release coherente online/offline | H04/H05/H06: manifiesto único, versión inmutable, contrato de runtime/dependencias, staging y rollback; USB completa. | 5–8 días |
| 3 — Compatibilidad Windows 10 | Matriz ejecutada y UI por capacidades | PS5/PS7 por herramienta; Store/LTSC; DoH y tweaks; arquitectura; catálogo de aplicaciones; prueba WPF real. | 4–7 días |
| 4 — Calidad de herramientas | Diagnóstico y reparación verificables | Copias/exclusiones, DNS/Hosts/servicios/spooler con reversión, eventos/hardware/IA/router y reportes con cobertura; decidir backend del deduplicador. | 8–12 días |
| 5 — Operación y entrega | Release candidata documentada | Worker/lock/CI, privacidad de reportes, acta persistente, docs generadas, manual de recuperación, pruebas de regresión. | 4–6 días |

**Total orientativo de ingeniería: 28–44 días.** Añadir **6–10 días de QA técnica** sobre VMs/hardware, parte solapable. Un primer hito de estabilización puede revisarse aproximadamente al completar fases 0–1, sin esperar la modernización completa. La estimación excluye desarrollar desde cero un deduplicador/conversor que actualmente no está en el repositorio.

No conviene abrir un único cambio con las 27 herramientas. Recomiendo PRs pequeños: protección de cuentas; BitLocker; ejecutor de procesos; validación de dependencias; códigos WinGet; releases; USB; compatibilidad; familias de herramientas. Cada PR debe llevar evidencia proporcional al riesgo.

### 8.2 Backlog con criterios de aceptación

| ID | Trabajo | Prioridad | Criterio de terminado | Dependencia |
|---|---|---|---|---|
| A01 | Validación común de instaladores | P0 | Ningún camino normal/offline ejecuta un archivo con firma/hash requerido ausente o inválido; casos negativos probados. | — |
| A02 | Cuentas y elevación | P0 | Último admin habilitado protegido; SID correcto; sin admin vacío; error real propagado; prueba con elevación de otro usuario. | — |
| A03 | BitLocker recuperable | P0 | Protector correcto según volumen/política; respaldo verificado; suspensión distinta de descifrado; fallo de escrow no figura como éxito. | A02 |
| A04 | Ejecutor común de procesos | P1 | Comillas, timeout, captura de salida/código, cancelación y estado posterior; soporta rutas complejas. | — |
| A05 | Resultado y cobertura comunes | P1 | Estado no evaluado para falta de datos; WinGet, GPU, eventos y disco no producen los falsos positivos identificados. | A04 |
| A06 | Release y cadena de confianza | P1 | Bootstrap, launcher, herramientas y hashes de una misma versión; autenticidad documentada; ref inexistente falla. | A01 |
| A07 | Registro único de dependencias | P1 | Versiones, runtime, arquitectura, firma y licencia; funciones disponibles en hijo o resueltas antes de lanzarlo. | A01, A04 |
| A08 | USB verificable | P1 | Las 27 herramientas coinciden con manifiesto; prueba desconectada; actualización completa o ninguna; detección de corrupción. | A06, A07 |
| A09 | Capa de capacidades Windows | P1 | OS/build/edición/módulos/usuario probados; funciones no aplicables explicadas antes de ejecutar. | A04 |
| A10 | Copias confiables | P1 | Excluir carpetas funciona; copia interrumpida no queda “OK”; muestreo se distingue de verificación completa. | A04, A05 |
| A11 | Reversión de cambios del sistema | P1 | DNS ambas familias/origen; servicios y dependientes; spooler; Hosts exacto; snapshot válido antes de mutar. | A04, A09 |
| A12 | Diagnósticos basados en evidencia | P1 | Provider+ID; salud desconocida visible; rangos de red correctos; ninguna certificación WAN desde LAN; recomendaciones de hardware con confianza. | A05, A09 |
| A13 | Paquetes/runtimes y catálogo | P1 | Esquema de perfiles, OS mínimo, fuentes coherentes, no Prefetch, versiones y reinicio comprobados por paquete. | A07, A09 |
| A14 | Worker y dependencia de desarrollo | P1 | Rutas/métodos, errores y caché probados; finalidad pública/privada definida; lock auditado tras actualización. | A06 |
| A15 | CI y revisión de cambios sensibles | P1 | Gate sobre SHA actual; rutas sensibles completas; pruebas funcionales seleccionadas y paquete íntegro publicado. | A01–A14 de forma incremental |
| A16 | Deduplicador: integrar o retirar temporalmente | P1 | Backend disponible, runtime reproducible, health propio y borrado reversible probado, o tarjeta marcada no disponible. | Decisión de alcance |
| A17 | Reportes y entrega | P1 | Datos sensibles ocultos por defecto; hallazgos trazables; checklist persiste; no se afirma escrow ni activación sin prueba. | A03, A05, A12 |
| A18 | UI, simplificación y documentación | P2 | Panel responde mientras consulta; idioma/búsqueda coherentes; inventario/documentación generados; duplicación reducida. | A07, A09, A17 |

### 8.3 Matriz de pruebas para aceptar Windows 10

| Eje | Casos mínimos |
|---|---|
| OS y edición | Windows 10 22H2 Home x64; Pro x64; LTSC 2021 correspondiente a clientes reales; Windows 11 como control. |
| Runtime | Windows PowerShell 5.1 x64 sin PS7; PS7 LTS homologado junto a 5.1; versión antigua detectada pero no seleccionada silenciosamente. |
| Cuenta | Estándar; admin con UAC; elevar con otra cuenta; último admin; administrador integrado deshabilitado; nombres localizados. |
| Instalación de apps | Con/sin App Installer; Store ausente/bloqueada; registro pendiente de usuario; paquete incompatible; fuente caída; timeout/reinicio. |
| Rutas | Espacios, tildes, apóstrofos, perfil redirigido/OneDrive, UNC, unidad extraíble, ruta larga y cambio de letra USB. |
| Red | Sin conexión, proxy, DNS fallido, TLS inválido, portal cautivo, VPN, IPv6, DHCP y estático, `/25` y `/16`. |
| Hardware | Sin batería/sensores; iGPU+dGPU; GPU AMD/NVIDIA/Intel; SSD/HDD/NVMe; USB/RAID; RAM soldada; equipo con recursos modestos. |
| Archivos | Origen vacío, destinos existentes, exclusiones, bloqueo, disco lleno, ACL, junctions y cancelación a mitad de copia. |
| Acciones sensibles | Snapshots de VM; vTPM y sin TPM; volumen de datos; respaldo de recuperación fallido; spooler que no arranca; servicio dependiente. |
| UI y salida | Español/inglés, escalado/DPI, navegación por teclado, no datos, error parcial, exportación y reapertura del acta. |

Automatizar la lógica con mocks/fixtures; reservar VMs para integración y hardware real para sensores, drivers, batería y rendimiento. No ejecutar pruebas de cifrado, cuentas o limpieza sobre el PC de trabajo del técnico. La suite debe registrar exactamente qué combinación aprobó cada release, sin extrapolar “parsea en PS5” a “funciona en Windows 10”.

### 8.4 Criterios de publicación

Un release candidato debería satisfacer simultáneamente:

1. Ningún P0 abierto en las acciones que se habilitan al cliente.
2. Matriz de capacidades y versión de fuentes incluidas en el paquete.
3. Verificación obligatoria de artefactos y actualización atómica probada con interrupción.
4. Pruebas de cuentas, BitLocker, copias, DNS y servicios con casos negativos, no solo caminos felices.
5. Herramientas sin datos/devices/dependencias en estado explícito no evaluado o no disponible.
6. USB ensayada sin conexión, con inventario completo y licencias de redistribución consideradas.
7. Dependencias de desarrollo actualizadas/auditadas, excepciones justificadas y no confundidas con exposición de producción.
8. Documentación y reportes que describan lo que el código realmente hace.

<a id="decisiones"></a>

## 9. Decisiones de producto recomendadas

Estas son mis preferencias para iniciar el trabajo; no se necesita bloquear las correcciones verificadas mientras se discuten:

- **Conservar PowerShell/WPF.** El retorno está en robustez y cobertura antes que en un cambio de framework.
- **Windows 10 22H2 x64 como primera matriz**, con LTSC 2021 explícita si forma parte de los equipos atendidos. Evitar el compromiso ambiguo “cualquier Windows 10”.
- **Robocopy como motor básico de copia y FastCopy optativo con licencia**, compartiendo perfiles, resultados y pruebas donde aporte valor.
- **Diagnóstico de lectura por defecto; reparación por acción seleccionada.** No un botón que aplique limpiezas y modificaciones no relacionadas.
- **Versiones estables y probadas**, con revisión periódica, frente a “latest” descargado al momento en un PC de cliente.
- **Un paquete USB auditable**, con capacidades offline declaradas. No intentar prometer instalación offline de cualquier aplicación del catálogo.
- **Separar reporte de entrega de administración de usuarios**, reutilizando un módulo seguro común para cuentas.
- **Deduplicador fuera del compromiso de herramienta completa hasta tener su backend.** Integrarlo tiene sentido solo si hay uso real y un flujo de recuperación de archivos.
- **Un único informe técnico con niveles de detalle**, para que Diagnóstico Master, IA, GPU y Entrega compartan hechos en vez de recopilar y reinterpretar todo por separado.

La primera inversión debe convertir Atlas en una herramienta que sabe distinguir **hecho, hipótesis, fallo y no evaluado**. Esa mejora hará más útil el proyecto tanto en Windows 10 como en Windows 11 y reducirá la necesidad de añadir excepciones por equipo.

## 10. Evidencias conservadas y límites del informe

Se adjunta [EVIDENCIA-2026-10-24.json](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/docs/audits/EVIDENCIA-2026-10-24.json:1>) con versión auditada, resultados resumidos, métricas del analizador y salidas de las reproducciones aisladas. La evidencia técnica de la revisión se refiere al commit señalado; las líneas y versiones externas pueden cambiar después.

Las afirmaciones sobre el código tienen enlaces a ubicaciones concretas. Las recomendaciones de producto y estimaciones están identificadas como tales. Las fuentes externas relevantes se enlazan junto a sus afirmaciones; se priorizaron Microsoft, autores de herramientas, Cloudflare y repositorios oficiales. No se verificó en ejecución real todo binario de tercero ni el contenido privado del onboarding.

Esta auditoría permite preparar el backlog y comenzar por los riesgos demostrados. La declaración de compatibilidad final de Windows 10 queda supeditada a ejecutar la matriz propuesta sobre esas ediciones y builds.
