# Auditoría integral de Atlas PC Support 1.5.21

Fecha: **17 de noviembre de 2026**. Informe de revisión y propuestas; **las correcciones propuestas aquí todavía no están implementadas**.

## 1. Dictamen

Atlas tiene una base de distribución y pruebas bastante más sólida que la de sus primeras versiones. La publicación fija commit y manifiesto, comprueba los miembros de la release, conserva una versión anterior y distingue varias operaciones no evaluadas de resultados satisfactorios. Mantener PowerShell 5.1, WPF, Robocopy y las capacidades nativas de Windows sigue siendo una decisión razonable para este proyecto. No recomiendo una reescritura, migrar a Electron ni instalar PowerShell 7 obligatoriamente en cada cliente.

**Sí quedan defectos concretos que justifican trabajo adicional.** Los más importantes son una interpretación incorrecta de eventos WHEA y un onboarding que conserva `Bypass`/`Unblock-File`, acompañado de instrucciones desactualizadas sobre antivirus. Después vienen errores de interfaz y presentación de evidencia, y mejoras acotadas de pruebas y mantenibilidad.

No encontré evidencia que justifique declarar comprometida la publicación o desactivar el panel completo. Tampoco sería correcto dar por aceptadas todas sus operaciones porque pase la suite. **Windows 10 sigue sin homologación completa; las VMs permanecen pausadas.** Las instalaciones, recuperaciones y pruebas físicas pendientes conservan su estado.

### Fotografía exacta

| Elemento | Valor observado |
|---|---|
| Checkout auditado | `b8e2c8c33cb7a72cd171dd3edb0aaca2ec4865ec`, rama `main` |
| Versión pública | `1.5.21` |
| Commit servido | `972592be193d3f2b42f9a0b6a9a3ac854870cd7d` |
| SHA-256 del manifiesto | `7b65e879639f8104f4bc9b030ead468eaec26e967314fa9104b039a3903321e2` |
| Inventario | 27 entradas; una deshabilitada expresamente: Deduplicador |
| Distribución | 34 miembros verificados |
| Dependencias declaradas | 11 |
| Tamaño orientativo | 172 archivos versionados al iniciar; 18.864 líneas no vacías de PowerShell bajo `src`; 4.661 bajo `tests`; 76 archivos bajo `docs` |
| Publicación | [Dominio actual](https://toolspanel.atlaspcsupport.com), conservado |

El commit de integración y el commit aprobado de distribución son distintos. La diferencia por sí sola no es un fallo: se contrastó la publicación con sus pins, no con la suposición de que `main` siempre es lo que se sirve.

## 2. Alcance y método

Se revisaron el catálogo de 27 herramientas, sus rutas de ejecución relevantes, bibliotecas compartidas, bootstrap, build, manifiestos, Worker, automatización de CI, pruebas, documentación operativa, dependencias y limitaciones de uso profesional. La revisión se concentró en operaciones con efectos, tratamiento de errores, confianza en ejecutables, recuperación, privacidad y fidelidad de los diagnósticos.

Se repitió la suite local en ambos runtimes; se ejecutaron pruebas del Worker y de la política de CI; se consultó `npm audit`; se verificaron endpoints y se descargó una distribución completa a una carpeta temporal nueva. Se reprodujeron casos aislados de idioma, privacidad y rutas con apóstrofe. Para WHEA se comparó la tabla de Atlas con los metadatos del proveedor instalado de Windows, sin leer registros personales ni generar errores de hardware.

No se ejecutaron instalaciones de terceros, estrés de GPU, cifrado, cambios de cuentas/UAC, red, servicios, recuperación, escrituras en USB física ni controladores de VMs. No se inspeccionaron contraseñas, claves de recuperación ni secretos de Cloudflare. El código privado del instalador RustDesk, el servidor remoto y sus permisos efectivos no quedan certificados por esta revisión del repositorio público y de su transporte.

La revisión es amplia, pero no es una prueba exhaustiva de todos los caminos de ejecución, una auditoría completa del historial de secretos, un pentest externo ni una certificación legal o de hardware.

## 3. Comprobaciones repetidas y evidencia

| Comprobación | Resultado nuevo | Lo que demuestra |
|---|---|---|
| `tests/Invoke-LocalChecks.ps1`, Windows PowerShell `5.1.26100.9818` | **456 aprobadas, 0 fallidas, 0 omitidas** | Regresiones, sintaxis, distribución y carga WPF incluidas en la suite, en este host |
| Mismo runner, PowerShell `7.6.9` | **456 aprobadas, 0 fallidas, 0 omitidas** | Compatibilidad de las comprobaciones con ese runtime |
| PSScriptAnalyzer | **0 errores**; 253 advertencias en PS5 y 264 en PS7 | El análisis configurado no encuentra errores bloqueantes; queda deuda |
| Otras observaciones del analizador | 89 informativas en PS5 y 93 en PS7 | No deben sumarse a las advertencias como si todas fueran fallos |
| Artefactos reproducibles | Sin modificaciones en ambas ejecuciones | Build coherente con los artefactos versionados |
| Worker, `npm.cmd test` | **27/27** | Contrato probado de rutas, integridad, límites y errores |
| Política CI, `node --test tests/ci-policy.test.cjs` | **9/9** | Regresiones aisladas del filtro de integración |
| `npm.cmd audit --json` | **0 vulnerabilidades conocidas reportadas**, 91 dependencias contabilizadas | Resultado del registro consultado; no auditoría de todas las aplicaciones descargables |
| Checker público con commit y digest esperados | **7 rutas aprobadas** | Respuestas y pins esperados; no instalación efectiva de RustDesk |
| Descarga nueva y comprobación completa | **34 miembros**, versión 1.5.21 | Integridad del paquete público descargado |
| Entrada offline sobre esa descarga | **`-NoLaunch` aprobado en PS5 y PS7** | Verificación de entrada; deliberadamente no abre el panel ni ejecuta herramientas |
| Defender del host | Antivirus, servicio y protección en tiempo real: **activos** | Estado observado; no garantía de ausencia de futuros falsos positivos |

El host informa Windows `10.0.26100.0`: corresponde a la familia Windows 11. Estos resultados **no son resultados nuevos de Home, Pro, Enterprise LTSC o IoT Windows 10**. El CI `windows-latest` tampoco lo es.

La descarga y comprobación en la carpeta temporal tardó **10,85 segundos en una sola observación**. No mide el tiempo hasta que el panel es utilizable, no es un percentil y no predice el rendimiento en un HDD lento.

La evidencia resumida, resultados de reproducciones y nombres de los logs temporales están en el [JSON de esta auditoría](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/docs/audits/AUDITORIA-INTEGRAL-1.5.21-2026-11-17.json>). Los logs completos quedan fuera del repositorio para no incorporar datos del host innecesarios.

## 4. Hallazgos priorizados

P1: corregir antes de confiar en ese flujo en nuevas intervenciones de clientes. P2: corrección concreta en una siguiente fase. P3: mantenimiento oportunista. Ninguna de estas etiquetas significa que se haya demostrado una intrusión.

| ID | Prioridad | Hallazgo | Evidencia | Responsable posible |
|---|---|---|---|---|
| A01 | P1 | La tabla WHEA confunde el evento 46 de memoria con temperatura y el 19 de procesador con PCIe | Tabla real + metadatos del proveedor de Windows | Código y fixtures autónomos; validación de eventos reales después |
| A02 | P1 | Onboarding mantiene `Bypass` y elimina MotW | Código servido y fuente | Autónomo, con prueba posterior de instalación asistida |
| A03 | P1 | Guía recomienda permitir la carpeta temporal en antivirus y contiene instrucciones de publicación antiguas | Documentación operativa vigente en el árbol | Autónomo; sin cambiar Defender ni comprar nada |
| A04 | P2 | Onboarding usa nombres fijos en carpeta ordinaria y cruza un límite de elevación | Inspección estática; riesgo de carrera/enlaces, sin explotación probada | Diseño y pruebas de rutas/concurrencia autónomos |
| A05 | P2 | La autoelevación del BAT falla con un apóstrofe en la ruta | Error de parser reproducido sin ejecutar el comando | Autónomo |
| A06 | P2 | Volver al idioma original antes del reinicio deja otra preferencia guardada | Cuerpo real del evento con dobles en memoria | Autónomo |
| A07 | P2 | Entrega PC deja secciones vacías si fallan red o Defender | `catch {}` y composición posterior del HTML | Autónomo |
| A08 | P2 | El filtro de privacidad oculta versiones con forma de IPv4 | Función real con texto ficticio | Autónomo |
| A09 | P2 | Textos de menús prometen acciones que ahora tienen otro alcance | Interfaz frente a implementación | Autónomo |
| A10 | P2 | Quedan rutas de espera/cierre sin resultado verificable | `netsh` directo y cierre de estrés con errores silenciados | Parte autónoma; aceptación GPU requiere hardware |
| A11 | P2 | Las guardas del BAT no verifican las propiedades de seguridad que sugieren | Solo buscan un patrón de ejecución y presencia de hash | Autónomo, junto con A02–A05 |
| A12 | P3 | Documentación/versiones/rutas de repositorio todavía duplicadas | README de Worker, README principal y referencias antiguas | Autónomo |

### A01. Corregir la base de conocimientos de eventos

Ubicación: [Invoke-DiagnosticoEventos.ps1:175](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoEventos.ps1:175>) y [tabla española:209](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-DiagnosticoEventos.ps1:209>).

La entrada `Microsoft-Windows-WHEA-Logger|46` tiene `Level=INFO` y describe una reducción de frecuencia por temperatura. El proveedor de Windows del host describe el evento 46, versión 0, como **error fatal de hardware, componente memoria**. La entrada 19 se presenta como PCIe, mientras su plantilla observada dice **Processor Core**, con tipo y origen del error en los datos del evento.

Se ejecutó el lookup real sobre la tabla española aislada; devuelve esos títulos y causas. No es una cadena antigua sin uso: las consultas de hardware incluyen esos IDs. La consola y el HTML calculan el nivel mostrado a partir del evento original, por lo que **no he demostrado que un evento fatal se dibuje como informativo**; el `INFO` incorrecto pertenece a la tabla. El título y las recomendaciones incorrectos sí se consumen. El lookup por proveedor es una mejora correcta, pero no garantiza que el contenido de la tabla lo sea.

**Por qué importa:** puede minimizar una observación grave o conducir a mantenimiento térmico/revisión PCIe sin evidencia correspondiente. El dato tampoco permite concluir automáticamente que haya que cambiar RAM o CPU: los detalles del evento siguen siendo necesarios.

**Propuesta:** corregir 19 y 46 en ambos idiomas; revisar las demás entradas activas contra proveedor, canal y versión; conservar la severidad/origen original; separar “observación”, “posibles causas” y “siguiente comprobación”. La búsqueda manual todavía consulta entradas genéricas `*|*|ID`; debe pedir o mostrar el proveedor aplicable para no presentar un número de evento como diagnóstico universal. No añadir un fallback genérico a los informes por comodidad.

**Aceptación:** fixtures con eventos de distintos proveedores que comparten ID; casos WHEA 19/46; evento desconocido sin diagnóstico inventado; representación correcta tanto en consola como en HTML. No hace falta provocar un fallo físico para esta corrección.

### A02. Alinear el onboarding con la política de ejecución

Ubicación: [onboarding/install.bat:42](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/onboarding/install.bat:42>), llamadas de las líneas 83, 96 y 98.

El BAT usa `-ExecutionPolicy Bypass`, elimina MotW de sí mismo y ejecuta `Unblock-File` sobre el instalador descargado. El archivo pertenece al manifiesto y el endpoint público comprobado entrega esos bytes.

**Precisión importante:** esto no demuestra que se esté apagando Defender o AMSI, ni cambia por sí solo la política de ejecución permanentemente. Sí elimina información de procedencia y contradice el criterio de conservar las protecciones que ya se aplicó al resto del proyecto.

El SHA-256 previo a la ejecución y los pins independientes del Worker son controles válidos que deben conservarse. No conviene resolver la inconsistencia quitando hashes o sustituyéndolos por confianza en un nombre de archivo.

**Propuesta:** retirar la eliminación automática de MotW y las invocaciones Bypass; adaptar el flujo para que respete la política efectiva del equipo y comunique claramente un bloqueo. Mantener la elevación explícita y la verificación del archivo. Si una política empresarial exige firma, devolver una limitación comprensible, sin intentar eludirla.

**Aceptación:** parser PS5, descarga alterada rechazada, política restrictiva respetada, cancelación UAC correctamente comunicada y ausencia de cambios en Defender. La instalación y conexión RustDesk reales seguirán necesitando su ensayo aparte.

### A03. Reescribir las instrucciones operativas de onboarding

Ubicación: [onboarding/README.md:159](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/onboarding/README.md:159>).

La resolución de problemas propone permitir la carpeta temporal en el antivirus. También sugiere un PAT sin caducidad por comodidad y comprar un certificado de precio aproximado para firmar el BAT y eliminar permanentemente SmartScreen. Esta última promesa no es un criterio fiable de aceptación; pagar por un certificado no garantiza ese resultado.

Además, la guía describe sidecars privados y variables antiguas `ATLAS_LAUNCHER_SHA256`/`ATLAS_TOOL_HASHES_SHA256`, mientras el Worker actual usa pins de commit/manifiesto y deriva el checksum de onboarding de bytes previamente verificados. Recomendar editar el instalador y recalcular un archivo no explica la promoción fijada por commit.

**Por qué importa:** una guía puede deshacer las mejoras del código cuando el técnico sigue sus instrucciones durante un fallo. No es solo una diferencia estética.

**Propuesta:** eliminar la recomendación de exclusión; documentar diagnóstico del bloqueo y revisión del archivo/proveedor; describir las variables y el comando de promoción vigentes; mantener caducidad/rotación del PAT como decisión operativa revisable, sin exponerlo. Retirar precios y promesas de SmartScreen. La firma de pago permanece aplazada por decisión del propietario.

La modalidad sugerida de AnyDesk gratuito también debe corregirse para el uso profesional: sus términos distinguen uso personal de soporte laboral. Tener pocos clientes no transforma ese uso en personal. La propia documentación del proveedor lo explica en [uso profesional](https://anydesk.com/en/professional-use) y [licencias](https://support.anydesk.com/licensing-usage). Esto no autoriza compras ni cambios de acceso remoto.

### A04. Endurecer el área temporal del onboarding

Ubicación: [onboarding/install.bat:86](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/onboarding/install.bat:86>).

El flujo elevado crea `%LOCALAPPDATA%\AtlasPC\onboarding` con un `New-Item` ordinario y usa nombres fijos `.download`/`.ps1`; no implementa en esa ruta el control explícito de enlaces/ancestros ni un bloqueo por ejecución. Después de comprobar el hash mueve el archivo y lo ejecuta por nombre.

**Por qué importa:** dos ejecuciones pueden interferirse, y la ruta local mutable forma parte de la confianza entre verificación y ejecución. Es un riesgo identificado por estructura del código, **no una escalada de privilegios explotada ni demostrada en esta auditoría**. Una ACL que concede escritura al mismo usuario tampoco elimina por sí sola todas las carreras entre procesos de ese usuario.

**Propuesta:** directorio único por intento, comprobaciones de rutas y enlaces, permisos acordes con la identidad que ejecuta, exclusión de concurrencia y manejo explícito del cambio de usuario al elevar. Definir qué amenazas locales se pretenden cubrir, en lugar de llamar “seguro” a un directorio por su nombre.

**Aceptación:** dos intentos simultáneos no comparten archivos; rutas redirigidas son rechazadas; el archivo que se ejecuta corresponde al intento verificado; fallos dejan evidencia sin ejecutar un reemplazo. Probar otra identidad de UAC requiere el laboratorio pendiente.

### A05. Evitar insertar la ruta del BAT dentro de código PowerShell

Ubicación: [onboarding/install.bat:51](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/onboarding/install.bat:51>); también afecta a la línea 42.

`%~f0` se inserta entre comillas simples dentro de `-Command`. Con la ruta ficticia `C:\Users\O'Neil\Downloads\install.bat`, el parser devuelve `TerminatorExpectedAtEndOfString`. Se analizó la cadena; **no se lanzó la elevación**.

**Propuesta:** transportar la ruta como dato, por ejemplo mediante una variable de entorno leída desde PowerShell, sin interpolarla como código. No basta con añadir otra capa de comillas sin probar las reglas de ambos shells.

**Aceptación:** espacios, apóstrofes, acentos y caracteres válidos del sistema de archivos; cancelación y códigos de salida preservados. Integrarlo con A02/A04 evita tres reescrituras del mismo wrapper.

### A06. Distinguir idioma aplicado e idioma pendiente

Ubicación: [MainWindow.ps1:823](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/gui/MainWindow.ps1:823>).

La interfaz compara la nueva selección con `AtlasCurrentLang`, que representa el idioma aplicado al abrir el panel. Si se abre en inglés, se elige español y luego inglés sin reiniciar, la segunda selección retorna antes de guardar. Resultado reproducido: selector `en`, preferencia guardada `es`, una sola llamada de guardado.

**Por qué importa:** el usuario intenta deshacer una elección y el reinicio aplica algo distinto de lo que ve. La corrección de 1.5.21 sobre preservación de configuración ante errores sigue siendo útil; este es otro caso de secuencia.

**Propuesta:** mantener separados el idioma aplicado y la preferencia persistida/pendiente; comparar y restaurar el selector contra esta última. No hace falta traducción en caliente ni rehacer la ventana.

**Aceptación:** `en → es → en`, varios cambios seguidos, fallo al guardar después de un cambio válido y reapertura. Conservar las nueve regresiones de idioma existentes.

### A07. Marcar secciones no evaluadas en Entrega PC

Ubicación: [Invoke-EntregaPC.ps1:805](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-EntregaPC.ps1:805>).

Si `Get-NetIPAddress` falla, `redHtml` queda vacío. Si `Get-MpComputerStatus` falla, `defenderRows` queda vacío. Ambos bloques silencian la excepción. El informe continúa sin una indicación inequívoca del fallo en esas secciones.

**Por qué importa:** un informe de entrega necesita distinguir “no hay adaptadores”, “no se pudo consultar” y “protección desactivada”. Un cuadro vacío no explica cuál ocurrió. No afirmo que el código convierta explícitamente ese fallo en `True`.

**Propuesta:** estados `Observed`/`NotEvaluated`, mensaje breve y causa saneada; mostrar las tres propiedades de Defender solo cuando la consulta sea válida. Reutilizar el patrón de cobertura que ya existe en Printer Doctor y otros módulos. Revisar también el HTML de Diagnóstico Eventos: su consulta a Security está en un `catch {}` y puede omitir la sección si falla, aunque la consulta interactiva sí comunica el error.

**Aceptación:** comando ausente, acceso denegado, respuesta vacía y protección realmente desactivada producen salidas distintas; ninguna excepción incorpora secretos al HTML.

### A08. Conservar versiones en informes redactados

Ubicación: [Reports.ps1:11](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/lib/Reports.ps1:11>).

La expresión general de IPv4 también reconoce `10.2.3.4`. Prueba con la función real: `DriverVersion=10.2.3.4; IP=192.0.2.10` termina con ambos valores redactados.

**Por qué importa:** se pierde evidencia útil para comparar drivers o dependencias. Es un falso positivo del saneamiento; no demuestra una filtración. No todas las versiones son afectadas, porque el patrón limita la longitud de cada segmento.

**Propuesta:** privilegiar campos estructurados y clasificación semántica; preservar campos de versión conocidos y seguir redactando direcciones. Mantener un filtro conservador para texto libre y revisión humana antes de compartir. No resolverlo desactivando la privacidad global.

**Aceptación:** versiones de cuatro componentes preservadas, IPv4/IPv6/MAC/SID/rutas/secretos todavía ocultos, y pruebas de texto HTML/JSON que no rompan su estructura.

### A09. Corregir textos que quedaron atrás de las restricciones

Ejemplos actuales:

- Printer Doctor ofrece “limpiar **todas** las colas”, pero pide el nombre exacto y limpia solo una. La implementación acotada es preferible; debe actualizarse la etiqueta.
- Keyboard Doctor ofrece “desactivar atajos” y conserva textos de un monitor que registra nombres de teclas. Ahora abre ajustes nativos y el monitor WPF solo cuenta eventos con foco, sin guardar el texto.
- Router conserva la etiqueta “Passwords WiFi”, aunque la acción abre ajustes Wi-Fi y ya no extrae claves.
- El README principal describe el dashboard como “live”; después aclara correctamente que las lecturas son bajo demanda. Unificar el mensaje.

Fuentes: [PrinterDoctor:68](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-PrinterDoctor.ps1:68>), [KeyboardDoctor:1](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-KeyboardDoctor.ps1:1>) y [Router:1627](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-AuditoriaRouter.ps1:1627>).

**Por qué importa:** el técnico no debería tener que ejecutar una opción para descubrir qué hace realmente. La diferencia aumenta la confusión que ya experimentó el propietario durante las pruebas manuales.

**Propuesta:** una revisión de textos de todas las pantallas afectadas, español/inglés primero, catálogo y guías incluidos. Retirar cadenas muertas de esas mismas acciones; no reestructurar todo el sistema de idiomas para cambiar unas etiquetas.

**Aceptación:** tarjeta, menú, confirmación, acción y resultado describen el mismo alcance. No volver a habilitar operaciones restringidas para que coincidan con textos antiguos.

### A10. Completar los límites de procesos y la confirmación de cierre

Fuentes: [Fase0:250](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-Fase0.ps1:250>) y [GPUCheck:249](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/src/tools/Invoke-GPUCheck.ps1:249>).

Fase 0 aún llama directamente a `netsh` sin el helper común de plazo/salida. Es una consulta de bajo riesgo, pero puede prolongar o bloquear la consola sin un resultado clasificado. La mayoría de los otros procesos relevantes ya usa `Invoke-AtlasNativeProcess`.

En GPUCheck, `Stop-Proc` intenta cerrar y detener el proceso, pero oculta errores y no devuelve si el cierre quedó confirmado. El watchdog puede devolver `ThermalStop` después del intento sin acreditar que el proceso terminó. **No se observó una GPU en carga ni un fallo real de cierre durante esta auditoría.**

El mensaje que distingue las zonas térmicas ACPI de sensores GPU **ya está presente y es correcto**. No propongo eliminar ese aviso ni presentar su umbral de 93 °C como límite OEM.

**Propuesta:** aplicar el runner acotado a `netsh`; devolver y verificar el estado de cierre del proceso propio de estrés, con espera limitada y advertencia clara si continúa. Conservar PID/identidad del proceso propio; nunca matar procesos por nombre indiscriminadamente.

**Aceptación:** fixtures de comando lento, salida errónea y cierre denegado; informe distingue “se pidió detener” de “se confirmó detenido”. La validación térmica y de herramientas externas requiere hardware representativo.

### A11. Hacer que las guardas prueben el comportamiento relevante

Ubicación: [Test-SecurityGuards.ps1:118](<C:/Users/FMS/Desktop/BEDROCK/LOCAL REPOS/atlas-pc-support/tests/Test-SecurityGuards.ps1:118>).

Para el BAT, la guarda comprueba la ausencia de un patrón literal `iex(iwr...)` y la presencia de `Get-FileHash`. No verifica que no haya Bypass/Unblock, que el archivo ejecutado sea el verificado, ni el aislamiento de intentos. Por eso puede aprobar el archivo de A02–A05.

**Por qué importa:** el nombre “security guards” y el mensaje de éxito pueden hacer atribuir al control más cobertura de la que tiene. Una búsqueda textual es útil como alarma, pero no equivale a comprobar el flujo.

**Propuesta:** mantener las guardas simples como primera capa; añadir regresiones del wrapper que sustituyan descarga/ejecución por dobles controlados y prueben hash incorrecto, rutas especiales y concurrencia. Si se normaliza el BAT para analizarlo, hacerlo con una función pequeña y casos representativos, sin construir un parser genérico innecesario.

**Aceptación:** una variante deliberadamente defectuosa falla por la propiedad violada, no solo porque cambió un texto. El pipeline no debe decir que el sistema está homologado por aprobar estas pruebas.

### A12. Reducir pequeñas divergencias documentales y de mantenimiento

El README del Worker dice Wrangler **4.152.0**, pero `package.json` y lock usan **4.154.0**. `npm outdated` ofrece **4.164.0** en esta consulta. No hay vulnerabilidades conocidas reportadas que obliguen a una actualización urgente: revisar cambios y probar antes de subir la versión; conservar el pin y el lock. No ejecutar `npm audit fix --force` por rutina.

Hay rutas de repositorio antiguas bajo `mikepchelper-spec` en el Worker y descargas. Funcionan ahora mediante redirección, pero el nombre canónico actual es `AtlasPCSupport`. Actualizarlas reduce una dependencia evitable de redirecciones; los hashes deben seguir siendo obligatorios.

Los informes históricos y los planes de `docs/superpowers` no son documentación “mala” por ser antiguos. El índice de auditorías ya los identifica como fotografías. Mantenerlos y enlazar una guía operativa actual es preferible a borrarlos o actualizar retrospectivamente su evidencia. Las cifras de 1.5.20 en el seguimiento están explícitamente fechadas: no las contabilizo como un defecto nuevo.

**Aceptación:** documentación operativa coherente con manifiestos y scripts; historial conservado; misma URL pública y mismos contratos de seguridad. Es trabajo autónomo de baja prioridad.

## 5. Revisión herramienta por herramienta

“Mantener” significa que no encontré una razón concreta para sustituir esa herramienta en esta revisión; no significa que haya ejecutado todos sus flujos reales.

| Herramienta | Lo que está bien o conviene conservar | Propuesta y por qué | Aceptación pendiente |
|---|---|---|---|
| 1. Inspección IPv6 / Fase 0 | Presets de hardening/reset restringidos; consulta visible | A10: acotar `netsh`; revisar si la consulta necesita elevación en todos los casos | Red y políticas representativas; sin reactivar presets |
| 2. Parts Upgrade | SMBIOS con desconocidos, advertencia OEM, sin inventar XMP o capacidad física accesible | Mantener. Homogeneizar cobertura de inventario general; describir selección del primer procesador frente al inventario múltiple de otros informes | Equipos con RAM soldada, varios sockets y controladoras distintas; manual OEM antes de recomendar compras |
| 3. Diagnóstico Master | Exportaciones por intento, lectura parcial diferenciada, HTML escapado, fuentes externas separadas | Mantener; registrar versión exacta de cada exportador y probar cambios de formato. Un minidump señalado no demuestra culpabilidad de un driver | Exportadores reales, batería ausente/dañada, RAID/NVMe, métricas térmicas |
| 4. Diagnóstico Eventos | Consulta acotada y lookup por proveedor; errores de consulta diferenciados | **A01**: corregir conocimiento técnico y revisar entradas activas; no sustituirlo por una tabla más grande sin fuentes | Fixtures ahora; contraste con casos reales anonimizados después |
| 5. Printer Doctor | Cobertura por fuente, trabajos pendientes no equivalen a atasco, limpieza de cola seleccionada | A09 y comprobar estado tras reiniciar Spooler; mensaje de éxito debe describir lo observado | Impresora física, página de prueba y fallos de cola/servicio |
| 6. Keyboard Doctor | Monitor con foco y consentimiento, no captura global de texto; ajustes nativos | A09; revisar umbrales de eventos como heurística, sin diagnóstico automático de hardware por un contador | Teclado interno/USB, foco, distribución, IME y accesibilidad |
| 7. AI Readiness | Inventario declarado heurístico; conectividad HTTP no equivale a autorización API | Mantener como orientación. Versionar criterios y backend/modelo de referencia cuando haya mediciones, no prometer ejecución por VRAM sola | Modelo, cuantización, backend, carga y memoria reales |
| 8. GPU Check | No mezcla falta de telemetría con salud; cobertura y límite ACPI explícitos | A10; registrar cierre y fallo de telemetría. No tratar puntuación como probabilidad ni umbral genérico como especificación OEM | GPU AMD/Intel/NVIDIA, sensores, estrés controlado y refrigeración |
| 9. Mantenimiento PRO | Diagnóstico antes de reparación, confirmación, runner acotado y archivos nuevos | Mantener. Un código SFC/DISM no debe convertirse en certificado de sistema sano; documentar logs operativos sin redactar | Windows dañado/reinicio/medios de reparación en snapshot |
| 10. Instalar paquetes | IDs/fuentes validados, procesos con plazo y cancelación, no instala acciones de mantenimiento | Actualizar inventario de versiones/minimum OS cuando se toque el catálogo; distinguir resultado del gestor y verificación posterior de instalación | Instalación limpia, ya instalada, upgrade, reinicio, cancelación y Store por usuario |
| 11. Microsoft Store | Respeta política y edición, registra un paquete existente sin forzar LTSC | Mantener. El nombre y mensajes deben dejar claro que no aporta Store donde no existe un paquete admisible | Usuario estándar/administrador alternativo; paquete presente, ausente y política restrictiva |
| 12. Runtimes | Componentes explícitos, fuentes conocidas, reinicio no forzado y verificación | Mantener; matriz por componente y arquitectura, .NET 3.5 con medio matching cuando corresponda | Pruebas reales de instalación/repair/reboot y medios offline |
| 13. Actualizar PowerShell | MSI fijado, SHA y firma Microsoft, rechazo de downgrade, comprobación posterior | Mantener 7.6.9 fijado hasta revisar una actualización. No sustituir automáticamente PS5 como runtime de todas las herramientas | Instalación/upgrade en cada edición objetivo y política de firma |
| 14. Personalización | Abre ajustes nativos; no aplica recetas opacas de registro | Mantener; confirmar etiquetas por URI en Windows 10/11 | Acceso a ajustes según edición/política; no necesita una reescritura |
| 15. Servicios | Lista pequeña, un servicio, snapshot y rollback; dependientes protegidos | Añadir identidad/fecha al snapshot si se amplía el flujo, para no restaurar inadvertidamente en otro equipo. No detener indexación/cache por defecto | Restauración real, dependientes y estados transitorios |
| 16. FastCopy | Mover/sincronizar restringidos; verificación nativa y resultado de copia honesto | Mantener copia; licencia profesional y redistribución por separado. No confundir copia de archivos con imagen recuperable del sistema | Instalación real, varias fuentes, disco lleno, interrupción, ACL/ADS y archivos abiertos |
| 17. Preparar USB | Release completa, hashes, rutas acotadas, inventario de dependencias con alcance declarado | Mantener; separar procedencia del ejecutable de integridad de su copia y conservar avisos/licencias del proveedor | NTFS ya tiene evidencia histórica; exFAT/FAT32, espacio/pérdida de energía y versión actual siguen aparte |
| 18. Respaldo controladores | Exportación en directorio propio, hashes y manifiesto; fallos parciales visibles | Conservar. Exportar no equivale a restaurar ni incluye toda app/firmware OEM. Revisar plazo del cmdlet nativo si se confirman bloqueos | Importación/reinicio y funcionamiento real de dispositivos |
| 19. Robocopy | No presenta crecimiento del destino como velocidad; muestra SHA-256 identificada; códigos diferenciados | Mantener como base nativa. Añadir un identificador por intento a logs si se necesita separar repeticiones dentro del mismo minuto | Disco lleno, ACL, archivo abierto, enlaces, rutas largas y recuperación real; las copias ficticias anteriores tienen alcance limitado |
| 20. Selector DNS | Snapshot IPv4/IPv6 y origen automático/estático; DoH solo según capacidades; sin nueva tarea persistente | Mantener. Llamar al test “latencia ICMP”, no rapidez completa de resolución DNS; no elegir proveedor automáticamente por ping | DHCP/estático, varias interfaces, VPN, políticas y continuidad del soporte remoto |
| 21. Hosts | Escritura controlada, bloque administrado, eliminación de alias exacto y respaldo | Mantener; diferenciar la edición libre en Notepad de la ruta transaccional de Atlas y explicar cómo volver atrás | Hosts multialias, permisos, bloqueo, fallo parcial y restauración real |
| 22. Auditoría Router | Plazos, alcance LAN limitado, WAN desde LAN no certificado, sin extracción automática de claves Wi-Fi | A09; conservar limitación /24 y aclarar pruebas externas de velocidad/portal. No añadir escaneo agresivo | Router autorizado, NAT/IPv6, redes distintas, firmware y pruebas desde un punto externo cuando correspondan |
| 23. BitLocker | Respaldo fuera del disco físico antes de cifrar, secretos ocultos, TPM/edición y escrow diferenciados | Mantener restricciones. No dar AD/Entra o recuperación por confirmados solo por un comando. Los backups explícitos contienen secretos y son otra clase de archivo | vTPM, reinicio, recuperación, políticas, otro disco, AD/Entra en entorno autorizado |
| 24. Menor privilegio | SID para grupos, política local/snapshots, recuperación y restauración UAC acotadas | Mantener; verificar el acceso real del administrador de recuperación y otra identidad UAC antes de aceptar el flujo | Inicio de sesión, restauración y casos dominio/Entra; no en el host |
| 25. Extraer licencias | Lectura local, claves parciales/ocultas, revelación/copia explícitas | Mantener. Nombre/documentación deben separar clave observada, activación y derecho de uso; no recupera toda licencia de software | Sistemas OEM/retail/volumen representativos sin publicar claves |
| 26. Deduplicador | Deshabilitado con motivo | Dejarlo así o retirarlo del catálogo visible si se decide; implementarlo es funcionalidad nueva, no una corrección pendiente de seguridad | Backend, vista previa y recuperación reversible antes de habilitar |
| 27. Entrega PC | Checklist persistente manual, trazabilidad y HTML escapado | **A07/A08**; cobertura visible y conservación de versiones. No convertir confirmaciones manuales en pruebas automáticas | Entrega real, lectura del cliente, privacidad, impresión y aceptación registrada |

## 6. Dependencias, actualidad y licencias

Hay dos modelos distintos: versiones fijadas en Atlas y aplicaciones resueltas por WinGet/instalación local. En el segundo caso, `Version=null` no significa necesariamente obsolescencia: significa que Atlas no fija la versión. El coste es que un cambio externo puede alterar parámetros, salida, mínimos de Windows o recursos requeridos sin cambiar la versión de Atlas.

| Dependencia | Evaluación y propuesta razonable |
|---|---|
| CrystalDiskInfo | Mantener como fuente auxiliar, sin universalizar SMART a todos los puentes/controladoras. El proveedor publica compatibilidad con Windows 10. Conservar recursos y avisos al copiar; su licencia MIT exige preservar el aviso. [Requisitos](https://crystalmark.info/en/software/CrystalDiskInfo/) y [licencia](https://crystalmark.info/en/software/crystaldiskinfo/crystaldiskinfo-license/). |
| CrystalDiskMark | Mantener como benchmark opcional y explícito, no como examen de salud. Registrar versión, tamaño/carga y disco ensayado. El proveedor permite redistribución de sus programas; conservar condiciones de la edición concreta. [Distribución](https://crystalmark.info/en/information/about/). |
| CPU-Z | Mantener para inventario; probar exportación de texto por versión. “Freeware” no sustituye revisar condiciones del paquete/SDK y redistribución. No hace falta comprar un SDK para leer el reporte de la app. [Proveedor](https://www.cpuid.com/softwares/cpu-z.html). |
| BlueScreenView | Herramienta antigua, útil para triaje. La página sigue mostrando 1.55; no considero que la edad por sí sola obligue a quitarla. No elevar un módulo señalado a causa confirmada; para casos complejos usar análisis de dumps especializado. [Descripción y versión](https://www.nirsoft.net/utils/blue_screen_view.html). |
| BatteryInfoView | Mantener exportador opcional con fixtures de formato/unidades; ausencia de dato no implica batería sana. Verificar condiciones de la distribución concreta y acompañar sus avisos. |
| HWiNFO | Separar uso personal de uso profesional y derechos de redistribución. El propietario no dispone de licencia comercial; esa dependencia sigue abierta aunque la herramienta funcione. No tramitar compra ni sustituirla automáticamente. [Licencias oficiales](https://www.hwinfo.com/licenses/). |
| GPU-Z | El proveedor permite uso personal y comercial, pero restringe su inclusión en un paquete comercial. Usarlo en una intervención y entregar una USB comercial con él son escenarios diferentes. Registrar esa diferencia en el inventario. [Condiciones del proveedor](https://www.techpowerup.com/gpuz/). |
| FurMark 2 | Conservar como estrés opcional con límites y cierre verificado; ensayo de CLI por versión. No se consiguió recuperar su página oficial en esta sesión: no afirmo aquí una licencia ni una versión más reciente. |
| FastCopy | Fallback fijado a 5.12.0 con hash; WinGet puede entregar otra versión. El proveedor exige Pro para uso continuado en el trabajo; revisar versión y derechos de distribución. La alternativa nativa Robocopy ya existe, sin imponer una sustitución no elegida. [Condiciones](https://fastcopy.jp/pro/license). |
| WinGet | Mantener IDs exactos y fuentes explícitas; comprobar capacidades y contexto del usuario. No reparar Store/App Installer mediante descargas opacas ni aceptar cualquier ID externo sin validar. |
| PowerShell 7 | 7.6.9 coincide con la publicación estable consultada; el MSI de Atlas está fijado y exige firma Microsoft. No recomendar una preview solo por ser más nueva. [Release oficial](https://github.com/PowerShell/PowerShell/releases/tag/v7.6.9). |

Node 22, Wrangler y Undici pertenecen al desarrollo/publicación; no son requisitos que deba instalar el cliente para abrir Atlas. `npm audit` no evalúa HWiNFO, RustDesk, FastCopy ni los ejecutables encontrados localmente.

**Mejora propuesta:** guardar por dependencia usada en un ensayo `versión observada + origen + hash + resultado de firma, cuando exista + edición/build de Windows + fecha + alcance probado`. Completar metadatos de licencia y enlaces oficiales. Una etiqueta `package-manager` no demuestra la firma de un EXE encontrado antes en PATH o en una carpeta local.

No recomiendo exigir Authenticode válido a todos los freeware de manera indiscriminada: podría romper herramientas legítimas sin firma. Primero definir políticas por proveedor, distinguir procedencia verificada de presencia local y probar versiones concretas.

La licencia MIT de Atlas no concede derechos sobre sus dependencias. La decisión del propietario de aplazar gastos se conserva; el informe deja visibles los límites en lugar de inventar una excepción por facturación reducida.

## 7. Seguridad, privacidad y recuperación

### Controles que conviene preservar

- Dominio HTTPS como entrada de confianza; commit/manifiesto fijados fuera de los checksums mutables del repositorio.
- Verificación del paquete entero y de herramientas; ningún fallback silencioso a `main` si una referencia no está aprobada.
- Staging y punteros de publicación, bloqueo de actualización y versión anterior; pruebas de paquete alterado.
- Runtime declarado, capacidades de plataforma y nueva comprobación en el proceso hijo.
- URLs upstream fijas en el Worker, tamaños limitados y plazo que incluye el cuerpo; rutas/métodos acotados y secretos en bindings.
- Pipeline con permisos de lectura para build, acciones fijadas por SHA y política de merge de documentación que no ejecuta el código del PR con token de escritura.
- Operaciones sensibles acotadas, confirmaciones y snapshots; redacción de informes y separación de backups que contienen secretos.

El Worker es pequeño y no necesita una base de datos, colas, autenticación de clientes o un framework adicional para servir este paquete público. Su lectura en memoria está limitada por tamaño para verificar hashes: no es la lectura ilimitada que las [buenas prácticas de Workers](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/) desaconsejan. Cambiarlo a streaming sin conservar la verificación previa sería una regresión.

### Límites que siguen abiertos

El primer `irm | iex` confía en el dominio/canal HTTPS que entrega el bootstrap. Los hashes posteriores no constituyen una identidad de firma independiente si el origen de confianza completo resulta sustituido. La USB también necesita una referencia externa confiable para detectar sustitución de todo el paquete y su descriptor. Esto está en el modelo de confianza; no se soluciona fingiendo que un hash local equivale a un certificado.

No se ha comprado ni desplegado firma. Se pueden mantener distribución por URL conocida, hashes verificables, trazabilidad y rechazo de cambios sin hacer ese gasto ahora. No prometer que Defender o SmartScreen nunca intervendrán.

Los informes compartibles saneados, logs operativos nativos, dumps, snapshots y claves de BitLocker tienen sensibilidad diferente. Los filtros no garantizan anonimización de cualquier texto libre. La decisión de cuánto conservar, quién accede y cómo se entrega al cliente sigue siendo del servicio técnico; puede prepararse una guía sencilla, sin borrar automáticamente evidencia o claves necesarias.

Los formularios/checklists manuales ayudan a recordar y registrar una aceptación. No demuestran que se haya recuperado un sistema, que una clave esté custodiada en AD/Entra ni que el cliente haya dado consentimiento fuera de esa confirmación.

## 8. Windows 10 y soporte vigente

Mantener Windows PowerShell 5.1 x64 es apropiado para compatibilidad con los módulos nativos usados. WPF tampoco está obsoleto por existir interfaces más nuevas. Cambiar todos los runtimes a PS7 añadiría incompatibilidades con módulos, encoding, APIs y Appx que tendrían que volver a ensayarse.

| Plataforma | Estado que corresponde comunicar |
|---|---|
| Home 22H2 19045 x64 | Objetivo de código; prueba histórica parcial; **no homologado completamente** |
| Pro 22H2 19045 x64 | Objetivo; BitLocker y recuperación requieren pruebas propias; **no homologado completamente** |
| Enterprise LTSC 2021 / `EnterpriseS` 19044 | Objetivo sin presuponer Store; **no homologado completamente** |
| IoT Enterprise LTSC 2021 / `IoTEnterpriseS` 19044 | Edición y licencia independientes; medios/pruebas pendientes; **no homologado completamente** |
| Windows 11 x64 del host | Suite actual aprobada; no acredita todos los equipos/políticas/hardware |
| Server, ARM64, x86 y anteriores al baseline | Fuera del contrato actual; no ampliar por inferencia |

La condición del código `build >=19044` acepta un conjunto más amplio que las ediciones concretas de la matriz, por ejemplo Home/Pro 21H2. Propongo clasificar esos casos como fuera de la matriz ensayada, sin confundir capacidad técnica con soporte del proveedor. No hace falta bloquear toda función de lectura por esa diferencia.

Windows 10 22H2 terminó el soporte ordinario el 14/10/2025; la cobertura posterior depende de condiciones/programas aplicables. LTSC e IoT tienen ciclos distintos: no debe atribuirse automáticamente a Enterprise LTSC el horizonte de IoT hasta 2032. Las páginas oficiales consultadas sitúan el soporte principal de LTSC 2021 en enero de 2027; cualquier extensión debe comprobarse por edición/programa, sin inferir inscripción o licencia. [Microsoft: 22H2](https://learn.microsoft.com/en-us/windows/release-health/status-windows-10-22h2), [LTSC 2021](https://learn.microsoft.com/en-us/windows/release-health/status-windows-10-21h2) e [historial IoT](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/whats-new/release-history).

**Para una futura homologación mínima:** una sola VM activa, snapshot, build/UBR/edición y runtime registrados, Defender activo y actualizado, paquete con SHA, entrada online/offline, WPF, UAC con ambas identidades, capacidades faltantes y operación/reversión de cada módulo sensible. No reanudar las VMs hasta que el propietario lo pida.

## 9. Rendimiento y experiencia de uso

La mejora histórica a aproximadamente cuatro segundos en una reapertura fue una observación del usuario, no una medición universal. El tiempo depende de descarga, TLS/DNS, verificación, disco, carga del runtime y WPF. Un primer arranque y una reapertura de caché no son comparables directamente.

La descarga actual sigue obteniendo miembros secuencialmente; cada transporte tiene su plazo y el fallback añade otro. Bajo una red mala, la espera puede ser mucho mayor que en el host de desarrollo. Eso justifica **medir y comunicar progreso**, no quitar controles de integridad para ganar unos milisegundos.

Propuesta de bajo coste:

1. Medir por separado resolución/descarga, comprobación, carga de módulos y `ContentRendered`, con varias repeticiones y mediana/percentil solo cuando haya muestras suficientes.
2. Mostrar fase y número de archivos, y permitir cancelar de forma limpia sin convertir staging incompleto en release vigente.
3. Ensayar SSD/HDD, equipo de poca RAM, red lenta y caché fría/caliente. La observación nueva de 10,85 s solo cubre descarga/verificación en este equipo.
4. Considerar concurrencia **pequeña y limitada** para descargas únicamente si la medición la justifica; evitar lanzar decenas de procesos o cambiar el esquema de confianza.
5. Mantener la lectura del dashboard bajo demanda y fuera del hilo de UI.

La accesibilidad ya tiene algunos nombres de automatización, foco y zonas con scroll. Queda aceptación con teclado, alto contraste, lector de pantalla, 125–200 % de escala y pantallas pequeñas. Las consolas que fuerzan tamaño merecen comprobarse en el equipo limitado del propietario; no abrir varias por defecto. No afirmo que esas pruebas visuales se hayan completado hoy.

Prioridad lingüística: español/inglés consistentes en las acciones reales. Tener siete idiomas en el panel no significa que las 27 herramientas estén traducidas a los siete; el README ya reconoce cobertura variable.

## 10. Pruebas, arquitectura y deuda

La suite tiene valor: valida escenarios negativos, integridad de distribución, flujos sensibles aislados y compatibilidad de sintaxis. No es solo un contador decorativo. Sus puntos ciegos demostrados son la semántica de la tabla WHEA, una secuencia de UI y el BAT antiguo. Mejor añadir esas regresiones que perseguir una cifra arbitraria de cobertura.

Parte de las pruebas extrae funciones o handlers con AST para evitar efectos reales. Es apropiado para cálculos y manejo de errores, pero puede dejar sin probar el pegamento entre menú, wrapper, identidad elevada, ejecución y reporte. Conservar pruebas pequeñas más un número reducido de ensayos de integración por flujo.

Las advertencias no son 253/264 vulnerabilidades. Entre las reglas más frecuentes aparecen verbos no aprobados, catches vacíos, parámetros posicionales y tipos de salida. La prioridad es el efecto: un `catch` del tamaño de ventana puede tolerarse; uno que oculta un fallo de Defender o un proceso de estrés merece atención. No recomiendo silenciar reglas para presentar cero advertencias.

Hay módulos grandes: Router, Diagnóstico Master e Instalar paquetes concentran interfaz, datos y operaciones. La estrategia razonable es extraer lógica pura cuando se corrija un defecto concreto, retirar traducciones/rutas muertas de la acción tocada y reutilizar los helpers ya existentes. No crear una arquitectura de plugins, un bus de eventos o veinte capas nuevas para este catálogo.

La documentación de integración de herramientas debería enfatizar también tiempos límite, resultado verificable, cobertura de informe y clasificación de efectos; registrar una función en JSON no basta para aceptarla. El runtime y el catálogo deben seguir siendo la fuente principal para documentación generable.

Mejoras de CI proporcionadas:

- Añadir las regresiones de A01–A11 y verificar coherencia de textos relevantes con el comportamiento.
- Conservar módulos de prueba, acciones y herramientas de build fijados; revisar actualizaciones de forma periódica.
- Incorporar un control sencillo de enlaces locales y metadatos/versiones en documentación activa, con exclusiones explícitas para ejemplos.
- Mantener evidencia por SHA y `Windows10Validated=false` cuando no haya ensayo real.
- No añadir otro pipeline pesado ni ejecutar reparaciones del host para “ampliar cobertura”.

## 11. Plan propuesto, sin compras ni VMs automáticas

| Fase | Alcance | Qué puede hacerse de forma autónoma | Criterio de cierre |
|---|---|---|---|
| 1. Diagnósticos fiables | A01, A07, A08 | Corregir WHEA, cobertura de entrega y privacidad con fixtures; revisar consumidores | Casos nuevos fallan antes y pasan después; suite PS5/PS7, artefactos y Worker aprobados |
| 2. Onboarding coherente | A02–A05, A11, guía A03 | Rehacer el wrapper mínimo, endurecer rutas/intentos, ampliar guardas y actualizar documentación | Hash alterado bloqueado, políticas respetadas, rutas especiales/concurrencia probadas; instalación real continúa explícitamente pendiente |
| 3. Interfaz y esperas | A06, A09, parte autónoma de A10 | Estado de idioma, menús/confirmaciones, `netsh` acotado y resultado de cierre de proceso | Secuencias UI y dobles de procesos aprobados; sin reactivar funciones restringidas |
| 4. Mantenimiento proporcionado | A12, metadatos de dependencias, documentación activa y deuda por impacto | Coherencia documental, origen/versiones, evaluación de Wrangler y medición instrumentada | Actualizar solo con motivo y pruebas; sin nueva versión si solo cambian documentos |
| 5. Aceptación externa, cuando se retome | Windows 10, instalaciones, recuperaciones y hardware | Preparar un guion de una acción por paso y evidencia por intento | Resultados reales por edición/escenario, reversión y limitaciones documentadas |

Para cada fase de código, conservar el flujo que pidió el propietario: commit/PR, checks, push al finalizar, promoción del SHA probado y verificación pública del **mismo enlace**. Un push no equivale a publicación. Este informe **no ha ejecutado esas fases ni promovido una nueva versión**.

### Lo que depende del propietario o de un entorno externo

- Retomar expresamente una VM cuando quiera; aceptar UAC/autenticación si Windows lo exige. Una sola activa y sin consolas duplicadas.
- Aportar hardware/medios representativos y autorizar escenarios concretos de escritura, instalación o recuperación. No utilizar datos o discos de cliente como laboratorio improvisado.
- Definir el servidor y escenario autorizado para comprobar una conexión RustDesk real; permisos y credenciales permanecen fuera del informe.
- Decidir custodia/retención y entrega de datos reales. Puedo preparar plantillas, pero no inventar consentimiento del cliente.
- Firma y derechos comerciales/de redistribución: decisiones ya expresadas permanecen vigentes; no se comprará nada ni se volverán a pedir esas decisiones por rutina.

### Qué no recomiendo hacer ahora

No reescribir el panel, imponer PS7, quitar Defender/AMSI, eliminar verificaciones por velocidad, comprar certificados para “hacer desaparecer” avisos, prometer Windows 10 homologado, reemplazar todas las dependencias por ser antiguas, habilitar el deduplicador sin backend ni borrar el historial de auditorías para que el proyecto parezca terminado.

Mi valoración es que el proyecto necesita **cerrar estas inconsistencias y demostrar sus operaciones de mayor riesgo**, no una modernización masiva. Las mejoras con mayor retorno inmediato son corregir la información que guía al técnico, unificar el onboarding con las protecciones existentes y hacer que los mensajes reflejen exactamente lo que se ejecutó y verificó.
