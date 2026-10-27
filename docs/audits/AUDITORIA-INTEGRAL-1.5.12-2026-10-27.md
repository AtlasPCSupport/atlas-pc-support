# Auditoría integral de Atlas PC Support 1.5.12

Fecha de corte: **27 de octubre de 2026**. Revisión del código en
`e19256ffa3c499ec884b1e546571f2506df49326` y de la publicación 1.5.12,
cuya fuente es `7537149aaae109993022de3a4a8840fc0509c35e`.

## 1. Dictamen y alcance

**Atlas puede seguir mejorándose por cambios pequeños. No recomiendo una
reescritura, sustituir todas las aplicaciones ni exigir PowerShell 7 para todo.**
La distribución tiene controles útiles: commit aprobado, manifiesto independiente,
hashes, comprobaciones de capacidades, procesos con límites y separación de
operaciones destructivas. Eso merece conservarse.

El problema principal pendiente es la **consistencia de las conclusiones**:
varias correcciones de Diagnóstico Master no alcanzaron a otras herramientas que
interpretan los mismos datos. También quedan informes que no aplican la misma
redacción y consumidores que siguen leyendo esquemas anteriores.

Hay una actualización con fecha concreta: **Mullvad anuncia el cierre de su DNS
público cifrado el 2/11/2026**. Conviene atenderlo antes de volver a recomendar ese
perfil. Su documentación también aclara que esas IP no son resolutores DNS
convencionales sobre el puerto 53. [Aviso del proveedor](https://mullvad.net/en/blog/2026/9/3/shutting-down-our-public-encrypted-dns-servers-and-sponsoring-quad9-instead),
[especificaciones](https://mullvad.net/en/help/dns-over-https-and-dns-over-tls).

Se revisaron las **27 entradas**, sus fuentes mediante AST UTF-8, sus flujos y
ayudantes pertinentes, bibliotecas compartidas, manifiestos, distribución, GUI,
CI, Worker y documentación. Las fuentes oficiales se consultaron para contrastar
afirmaciones que pueden cambiar. La revisión combina lectura estática y
reproducciones pequeñas; **no equivale a ejecutar cada función en hardware real**.

No se ejecutaron herramientas de reparación, instaladores, cifrado, cambios de
cuentas/red, escaneos de LAN ni ensayos de estrés. No se arrancaron VMs ni se
escribió en USB. Defender permaneció activo. Este cambio entrega **informe y
evidencia**, sin modificar el producto o promover otra publicación.

**Windows 10 sigue sin homologación completa.** PowerShell 5.1 en el host Windows
11 no prueba Home, Pro, Enterprise LTSC ni IoT. Las decisiones anteriores sobre
conservar aplicaciones, aplazar firma y pausar VMs se mantienen.

## 2. Prioridades propuestas

P1 significa corregir antes de recomendar ese resultado o flujo a clientes;
P2, siguiente mantenimiento; P3, limpieza opcional. No se ha demostrado una
incidencia crítica que justifique declarar todo el panel inutilizable.
S/M describe tamaño relativo, no una promesa de horas.

| ID | Prioridad | Propuesta | Motivo principal | Tamaño |
|---|---|---|---|---|
| A01 | P1 | Actualizar perfiles y explicaciones DNS | Mullvad cierra; DNS clásico no sirve para esas IP | S |
| A02 | P1 | Corregir PartsUpgrade reutilizando criterios ya corregidos | Generación, XMP, soldadura y capacidad pueden aconsejar mal | M |
| A03 | P1 | Completar privacidad y nombres de carpetas de informes | Nombres reconocidos por una herramienta no se redactan en otra | S–M |
| A04 | P1 | Comprobar resultado real de políticas de cuentas | `net accounts` puede fallar y el menú contar cambios aplicados | S–M |
| A05 | P1 | Revisar clasificación y cobertura GPU | El nivel alto es inalcanzable con la puntuación actual | M |
| A06 | P2 | Alinear monitor de teclado y sus consumidores | Cero teclas puede producir una observación de un evento | S |
| A07 | P2 | Distinguir vacío, fallo y no evaluado en diagnósticos auxiliares | Evitar diagnósticos falsos cuando Windows deniega una consulta | M |
| A08 | P2 | Afinar previsualización, incremental y muestra de copias | Más claridad y menos memoria en árboles grandes | M |
| A09 | P2 | Hacer verificable el inventario del respaldo de controladores | Contar INF no prueba integridad ni restaurabilidad del paquete | S–M |
| A10 | P2 | Unificar resolución y estado de dependencias/USB | Rutas múltiples, paquetes parciales y componentes antiguos | M |
| A11 | P2 | Completar prevalidación de restauración DNS y bloques hosts | Reducir cambios parciales y duplicación de listas | M |
| A12 | P2 | Medir inicio y limitar memoria de salida de procesos | Mejorar PCs modestos con mediciones, conservando verificaciones | M |
| A13 | P2 | Alinear guías vigentes con el código actual | Hay instrucciones que prometen comportamientos retirados | S–M |
| A14 | P3 | Eliminar ramas sin uso y opciones bloqueadas | Menos código que mantener y menos confusión | S |
| A15 | P3 | Mantenimiento conservador del Worker y su CLI | Límites temporales y actualizaciones comprobadas, sin migración | S |

## 3. Hallazgos y justificación

### A01. Selector DNS: catálogo, transporte y medición

**Evidencia:** `Invoke-SelectorDNS.ps1`, perfiles aproximadamente 130–190,
aplicación 268–301, latencia 334–374 y enlace 583–585. Windows 10 utiliza DNS
clásico en este flujo; el contrato ya limita DoH nativo a Windows 11.

Los perfiles Mullvad pueden dejar una configuración sin resolución utilizable.
Además del cierre anunciado, el proveedor restringe esas IP a DoH/DoT. No basta
con escribirlas en un adaptador de Windows 10. Los nombres de filtros deben
coincidir con el proveedor: `base` incluye malware y `extended` añade redes
sociales; no son simplemente «tracker» y «social» independientes.

**Propuesta:** marcar esos perfiles como retirados/no aplicables, conservar una
explicación y permitir al técnico elegir otro proveedor. No sustituir el DNS de
un equipo que ya lo usa sin revisar su configuración. Mantener DNS clásico en
Windows 10 y no instalar un proxy adicional solo para conservar Mullvad.

La «latencia DNS» se calcula con ping ICMP: mide respuesta ICMP, no tiempo de
resolución. Renombrarla o añadir consultas DNS controladas con límite temporal,
varias muestras y aviso sobre caché. Retirar «máxima velocidad» sin medición.
El enlace «ESNI» merece actualizarse a documentación de ECH, sin prometer que
un cambio DNS active ECH. [Cloudflare ECH](https://developers.cloudflare.com/ssl/edge-certificates/ech/).

**Aceptación:** fixtures de transporte/build, catálogo fechado y sin perfiles
retirados elegibles; pruebas DNS reales solamente en el entorno autorizado.

### A02. PartsUpgrade conserva interpretaciones antiguas

**Evidencia:** `Invoke-PartsUpgrade.ps1:366–400,463–485,519–531,737`.
El patrón actual interpreta **i7-8700 como generación 87**; se reprodujo con la
expresión extraída del AST en ambos runtimes.

Otros puntos de lectura estática:

- Menor velocidad configurada que nominal se etiqueta «XMP OFF». Esa diferencia
  por sí sola no establece el estado XMP.
- `UpgradeMethod = 6` suma evidencia de BGA y puede concluir «soldado».
  Microsoft lo define como `None`; no demuestra BGA. Core Ultra y familias Ryzen
  tampoco deben convertirse en generaciones universales mediante el nombre.
- El cálculo usa `MaxCapacity` y presupone una sola matriz de memoria. Falta
  considerar `MaxCapacityEx`, múltiples matrices y capacidad desconocida.
- Campos desconocidos pueden convertirse en cero; un estado de disco numérico
  cero puede perderse en un condicional booleano.

**Propuesta:** trasladar solamente los pequeños lectores/normalizadores que ya
demostraron utilidad en Master a una biblioteca de inventario compartida, o
aplicar los mismos contratos con pruebas equivalentes antes de extraerla.
Conservar datos originales, fuente y estado «desconocido»; dejar la ampliación
física sujeta al manual del modelo. No construir otro motor de puntuación.

El hash del informe (`779–785,878–881`) se calcula sobre texto anterior al HTML y
a su redacción: no acredita el archivo final. Renombrar su alcance o producir
un digest externo del archivo realmente guardado; evitar un hash del propio
documento incrustado dentro de sí mismo.

**Aceptación:** generaciones de distintas familias, cero/una/varias matrices,
capacidad ausente, enum cero y datos de velocidad discordantes. Los mismos
fixtures deben cubrir PartsUpgrade y Master. [Win32_Processor](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor),
[PhysicalMemoryArray](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-physicalmemoryarray).

### A03. Privacidad de informes y carpetas

**Evidencia:** `Reports.ps1:49`; `Invoke-AIReadiness.ps1:505–508,537–559,625–626`;
`Invoke-MenorPrivilegio.ps1:755–790`.

El redactor reconoce `Client`/`Cliente`/`Customer`, pero IA guarda `ClientName` y
`ConsultantName` sin pasar sus valores a `SensitiveValues`. Una prueba con nombres
ficticios mantiene ambos, aunque el campo de control `Client` sí se redacta.
Menor Privilegio genera su TXT directamente con nombres de cuentas, en lugar de
usar el escritor compartido. No significa que esos archivos se hayan enviado
a Internet: el riesgo aparece al compartirlos confiando en la redacción general.

El saneamiento de carpeta IA permite `..`. La normalización sale de la carpeta
`AIReadiness`; se comprobó sin escribir fuera de ningún directorio. No se
demostró ejecución de código ni acceso remoto mediante ese nombre.

**Propuesta:** reconocer los campos reales y pasar explícitamente nombres
conocidos; usar ID aleatorio para carpetas y separar metadatos locales de la
exportación compartible. Validar contención después de normalizar, nombres
reservados y colisiones. Los respaldos de recuperación conservan sus secretos,
con destino y custodia explícitos: no deben redactarse como un informe común.

**Aceptación:** JSON, HTML y TXT con nombres ficticios, escapes HTML, nombres
cortos y carpetas `..`/reservadas. Cero datos de clientes en fixtures públicos.

### A04. Menor Privilegio: resultado de políticas y reversibilidad

**Evidencia:** `Invoke-MenorPrivilegio.ps1:590–604,615–638,711–740`.

Tres llamadas a `net accounts` descartan salida y aumentan `$cambios` sin
comprobar código nativo ni leer la política resultante. En Windows PowerShell
5.1 un código nativo no cero no se convierte automáticamente en excepción de
`try/catch`. Un rechazo por permisos, dominio o valor inválido puede presentarse
como política aplicada. La lectura previa también filtra texto inglés, aunque
Windows puede estar en español.

**Propuesta:** usar el ejecutor nativo existente, validar rangos y contexto local/
dominio, mostrar antes/después y comprobar cada resultado. Capturar valores
previos antes del preset UAC y ofrecer una restauración acotada; no rebajar UAC
para facilitar la prueba. Identificar administradores por SID también en el
informe, no solo al modificar grupos, para evitar homónimos local/dominio.

**Aceptación:** mocks de salida no cero, denegación y cambio parcial; aplicación y
restauración reales quedan reservadas al laboratorio. Mantener los bloqueos ya
existentes contra retirar al último administrador y contra tocar la cuenta actual.

### A05. GPU Check: escala y cobertura

**Evidencia:** `Invoke-GPUCheck.ps1:375–395,409–415,601–658`.

Con las ramas actuales los máximos son eventos 90, GPU-Z 30 y NVIDIA 50.
La combinación `90×0,50 + 30×0,35 + 50×0,15` da **63**, pero «RIESGO ALTO»
empieza en 70. Ese nivel es inalcanzable. Es un cálculo sobre código, no una
prueba física ni una calibración médica del hardware.

El recuento de errores usa nombres de severidad en inglés; conviene usar `Level`
numérico para Windows en español. El vigilante consulta zonas térmicas ACPI del
sistema: no demuestra disponer de temperatura de la GPU. Ya distingue sesión
incompleta y falta de telemetría, lo cual debe conservarse.

**Propuesta:** antes de mover umbrales, definir reglas explicables de hallazgos y
su cobertura. Un evento WHEA no debe atribuirse automáticamente a la GPU. Mostrar
qué sensor existe, de qué dispositivo y durante cuánto tiempo; el estrés sigue
siendo explícito, con salida del proceso y límites comprobables. No prometer
protección térmica universal con ACPI ni añadir aplicaciones obligatorias.

**Aceptación:** extremos de puntuación, eventos españoles/ingleses, ausencia de
sensor, salida anticipada y reposo. La validación de estrés/temperatura con GPU
real requiere hardware y supervisión.

### A06. Keyboard Doctor: productor y consumidores desalineados

**Evidencia:** `Invoke-KeyboardDoctor.ps1:439,519–525,593,639,656`.

El monitor guarda un registro con `Scope`, `Count`, `CapturedText` y `AtUtc`.
El diagnóstico usa `.Monitor.Count`, que cuenta registros, no teclas; con cero
teclas y un registro produce uno. HTML/TXT todavía esperan `Time/Key/Code`.

**Propuesta:** mantener el monitor limitado a su ventana y sin texto capturado;
actualizar resumen y exportaciones al esquema agregado. No restaurar captura de
teclas global ni nombres/códigos solo para hacer coincidir la guía antigua.

**Aceptación:** cero, una y varias pulsaciones ficticias, cierre/Escape, informe
con campos agregados y ausencia de contenido escrito. La interacción con teclado
real sigue siendo otra prueba.

### A07. Desconocido no equivale a ausente o averiado

**Evidencia:** Printer Doctor `276–396,410–420`; Keyboard Doctor `297–403,419–420`;
IA `432–480`; Master `1651–1655,1748–1752,1777–1784`.

Algunas consultas capturan fallos y devuelven una lista vacía. Después se informa
«sin impresora», «sin teclado», «sin eventos» o «sin trabajos», aunque la causa
puede ser acceso denegado o proveedor no disponible. Algunas secciones simples
de Master conservan cero como sustituto de capacidad ausente y un encabezado de
BSOD sin diferenciar herramienta no ejecutada de exportación sin hallazgos.

Keyboard Doctor además junta la primera capacidad de diseño y la primera
capacidad completa de batería sin emparejar identificadores (`358–385`). En
equipos con varias baterías puede mezclarlas. La corrección de Master 1.5.12
no corrige automáticamente este lector independiente.

**Propuesta:** un resultado pequeño `{State, Items, Source, Error}` por consulta,
sin un framework nuevo. Reutilizar el emparejamiento de baterías ya probado y
valores anulables. Para eventos usar filtros del proveedor y `-MaxEvents`,
evitando leer todo el registro y filtrar al final.

**Aceptación:** consulta vacía válida, excepción, batería incompleta/múltiple y
capacidad cero real. Ningún fallo de consulta debe generar recomendación de
compra, reparación o ausencia de dispositivo por sí solo.

### A08. Copias: claridad y escala, conservando lo probado

**Evidencia:** `Operations.ps1:91–124`; Robocopy `317–322,431–498` y construcción
del destino en su flujo principal; FastCopy `481–648`.

La muestra SHA-256 está correctamente identificada como parcial. Sin embargo,
para seleccionar 15 archivos se almacena y ordena toda la lista. En árboles muy
grandes el coste de memoria y espera puede ser desproporcionado. Las previews
usan recorridos que omiten ocultos o silencian accesos fallidos: no siempre
representan el conjunto que intentará copiar el motor.

El destino incorpora fecha. «Incremental» funciona sobre el destino elegido;
si al día siguiente se crea otra carpeta, no es una continuación automática del
respaldo anterior. Proponer selección explícita de respaldo existente y mostrar
esa diferencia antes de copiar.

**Propuesta:** enumeración con memoria acotada y muestra claramente definida;
preview con exclusiones/cobertura coherentes y opción de omitir un censo costoso.
Conservar códigos Robocopy diferenciados, extras en destino y restricciones de
mover/sincronizar. `MT:32` y `/J` son decisiones de perfil, no garantía de velocidad:
medir con archivos grandes/pequeños antes de cambiar valores predeterminados.
`/FFT` reduce precisión temporal; documentar cuándo se necesita y valorar dejarlo
para destinos que lo requieran. [Opciones oficiales de Robocopy](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy).

**Aceptación:** ocultos, acceso denegado, enlaces excluidos, muchos archivos,
colisiones y continuidad entre fechas. La copia completa, incremental y
restauración pequeña ya documentadas no se invalidan por estas propuestas.

### A09. Respaldo de controladores: evidencia del paquete

**Evidencia:** `Invoke-RespaldoControladores.ps1:68–127`.

El respaldo emplea mecanismos nativos y comprueba la salida CLI, pero su
inventario cuenta INF y registra tamaño/fecha. No verifica hashes de CAT/DLL y
otros miembros ni distingue suficientemente archivos que ya estaban en el
destino. La ruta relativa se calcula con la longitud del argumento recibido,
que puede no estar normalizado.

**Propuesta:** normalizar el destino, usar carpeta nueva por intento o declarar
mezcla explícita, inventariar los archivos exportados y sus SHA-256. Informar
«exportación comprobada» separado de «restauración probada». Un manifiesto
fallido no debe finalizar con la misma señal de éxito que uno completo.

**Aceptación:** fixtures de rutas relativas, destino previo, archivo ausente o
modificado; exportación/reinstalación real solo en entorno desechable.

### A10. Dependencias y preparación USB

**Evidencia:** `Dependencies.ps1:71–94`; Preparar USB `487–545,885–1013,1075–1078,
1158–1234`; catálogo `dependencies.json`.

La resolución genérica de comandos todavía admite resultados múltiples sin
seleccionar una aplicación. Con dos resultados simulados produce una ruta
concatenada en vez de una ruta ejecutable única. La corrección reciente de la
búsqueda de PowerShell no alcanza automáticamente a este resolver.

**Propuesta:** `-CommandType Application` y una selección determinista, comprobar
archivo y registrar versión/procedencia de binarios encontrados. Un binario
existente no acredita su versión o que traiga todos sus recursos. No bloquear
indiscriminadamente aplicaciones legítimas sin firma.

La preparación USB considera presente un grupo GPU por GPU-Z y otro diagnóstico
por algunos ejecutables. Puede omitir componentes restantes. El bundle Atlas
se verifica completo, pero el resumen final no agrega de la misma manera el
estado de cada paquete opcional. Separar «código Atlas listo» de «dependencias
opcionales disponibles/no evaluadas/fallidas», con comprobación por miembro.

El preparador conserva una ruta de extracción FastCopy que puede continuar con
otro modo de instalación después de fallar/agotar tiempo (`521–525`), mientras
el resolver compartido ya evita un segundo instalador. Unificar el contrato:
tras un estado parcial, inspeccionar antes de reintentar.

Hay además un flujo antiguo de descarga Store que acepta tamaño/tipo orientativo
y un mirror configurable, aunque **la herramienta Store actual solamente registra
un paquete existente** y no consume ese supuesto instalador offline. Su texto
todavía recomienda Store en LTSC/IoT y promete fallback automático inexistente.
Retirar la opción de preparación obsoleta es preferible a desarrollar un nuevo
instalador Store para justificarla. No forzar Store ni eludir políticas de LTSC.

**Aceptación:** dos comandos coincidentes, recursos incompletos, componente
opcional fallido y timeout sin segunda ejecución. No ensayar instaladores sobre
el PC de trabajo como sustituto del laboratorio.

### A11. Restauración DNS y hosts

**Evidencia:** `Operations.ps1:199–217`; `Invoke-HostsManager.ps1:235,347–384`.

La restauración DNS resuelve adaptadores dentro del bucle de cambios. Si el
segundo ya no existe, el primero puede haber cambiado antes del fallo.
Prevalidar todos los adaptadores y familias de dirección, registrar estado por
paso y ofrecer recuperación acotada. No prometer atomicidad que Windows no ofrece.

La lista hosts se obtiene de una rama mutable, se valida principalmente por
tamaño y se añade al archivo. Repetir la operación puede duplicar contenido.
Usar bloque administrado con límites, fuente/fecha/digest observados y sustitución
idempotente. No confundir datos de una lista de bloqueo con ejecución remota de
código ni exigir fijarla para siempre: necesita poder actualizarse.
Aplicar errores terminantes a copias que se anuncian como backup exitoso.

**Aceptación:** segundo adaptador ausente sin cambios previos, mezcla IPv4/IPv6,
lista malformada, doble aplicación y restauración byte por byte.

### A12. Inicio del panel y consumo en máquinas lentas

No hay evidencia para afirmar que 4 segundos en este PC equivalgan a minutos en
otro, ni para prometer 4 segundos universalmente. El perfil anterior de 1.5.10
midió fases internas con caché y sin primer pintado visible: capacidades consumió
aproximadamente 4,14 s; **no fue una medición completa de arranque en frío**.

**Propuesta:** medir primer pintado/ventana utilizable en frío y caliente,
percentiles y etapas; diferir consultas que no necesita el primer dibujo.
La comprobación del hijo antes de ejecutar mantiene autoridad aunque una tarjeta
muestre temporalmente «comprobando». Conservar verificación de hashes y Defender;
no usar exclusiones como optimización.

`Operations.ps1:74–81` captura salida entera con `ReadToEndAsync`; el tiempo está
limitado, el volumen en memoria no. Añadir límite/tail y log de archivo para
comandos verbosos, sin perder códigos ni diagnóstico. Algunas consultas CIM y
DNS síncronas de herramientas aún requieren límites explícitos; no declarar
tiempos estrictamente acotados para todas por tener un wrapper nativo.

El modo completo de Master puede abrir cuatro aplicaciones al final
(`1867–1885`). Para PCs modestos, ofrecer apertura seleccionada o una por vez;
no cerrar aplicaciones ajenas ni añadir un supervisor permanente.

**Aceptación:** medición reproducible del inicio, cancelación y salida sintética
grande con memoria limitada; prueba en PC lento cuando esté disponible.

### A13. Documentación vigente frente a historia

No se encontraron enlaces locales Markdown rotos en el barrido de los README y
`docs/` previo a añadir este informe. **Eso no valida enlaces externos ni garantiza
que el texto sea correcto.** El inventario generado está vigente.

| Documento | Desajuste observado | Propuesta y motivo |
|---|---|---|
| `AI-READINESS-ASSESSMENT.md` | Promete benchmark CPU; el score actual usa inventario. Describe copia de launcher como USB completo | Describir heurística, límites de VRAM y release verificado completo |
| `KEYBOARD-DOCTOR.md` | Dice nombres/códigos de teclas y desactivar flags; hoy se guarda agregado y se abren ajustes | Documentar privacidad y acciones que realmente ocurren |
| `PRINTER-DOCTOR.md` | Anuncia vaciar todas las colas; revisar frente al menú restringido actual | Retirar promesas de reparación no implementadas y documentar alcance del reinicio |
| `BRANDING.md` y plantilla | Ofrecen `autoElevate`, `dependenciesPath`, `defaultCategory`, `showSearch`, `showFooter`, `useSystemAccent` sin consumidores que apliquen esos campos | Marcar como no implementados o retirar del ejemplo. No activar autoelevación para cumplir una guía vieja |
| `SUPPORT-MATRIX.md` | Encabezado candidato 1.5.2; agrupa Enterprise/IoT aunque falta evidencia separada | Actualizar contexto/fecha y separar celdas de edición sin inventar aprobaciones |
| README inglés/español | Ruta única de reportes en Documents, pero varias herramientas usan Desktop u otras carpetas; ejemplo abreviado de registro puede divergir | Referencia breve a ubicación por herramienta y una sola guía de esquema |
| `ADDING-TOOLS.md` | Ejemplo CrystalDiskInfo con `/Json` no acredita un argumento real de ese programa | Usar ejemplo genérico válido o argumento contrastado; no copiar interfaces ficticias |
| `docs/superpowers/` | Especificaciones/plan de mayo proponen cascadas Store y runtimes ya sustituidas | Aviso «histórico/sustituido» y enlace a contrato vigente; conservar evidencia |
| `docs/audits/` | Muchos cierres y propuestas con fechas distintas | Índice por fecha/versión/estado. Una propuesta rechazada no es un pendiente aprobado |

No conviene mover o borrar masivamente informes históricos y romper referencias.
La guía de trabajo autónomo ya conserva las decisiones sobre licencia/firma y
debe seguir siendo la entrada para aceptación pendiente. `docs/ci/README.md` y
`CLOUDFLARE-DOMAIN.md` están alineados con la promoción fijada; no necesitan una
reescritura por antigüedad aparente.

**Aceptación:** revisar afirmaciones contra funciones actuales y comprobar links,
ejemplos, esquema e inventario; ninguna guía debe declarar QA de Windows 10 pasada.

### A14. Simplificación justificable

Revisión con el enfoque Ponytail Audit; propuestas, sin eliminaciones aplicadas:

- **`delete` — `Admin.ps1:14–35`:** `Invoke-SelfElevate` no tiene llamadas de
  producción encontradas y contiene `Unblock-File`. Eliminarlo elimina también
  una posibilidad futura de quitar MOTW que contradice el contrato. No se afirma
  que el flujo actual lo ejecute ni que Defender esté desactivado.
- **`delete` — `Invoke-InstalarPaquetes.ps1:1176–1205,1214–1218`:** limpieza global
  de temporales y rama asociada, ya rechazadas antes de instalar/exportar un
  perfil. Quitar también la opción visible bloqueada; no reactivar borrado masivo.
- **`yagni` — `ToolRunner.ps1:203–218`:** ejecución inline sin consumidor actual:
  las 27 entradas piden ventana nueva. Retirarla o definir/probar sus garantías
  antes de admitirla, porque evita parte del contrato del hijo.
- **`shrink` — inventario de RAM/CPU/batería repetido:** compartir únicamente
  normalización probada. La repetición ya produjo divergencias A02/A07; extraer
  por semejanza de aspecto sin contrato común sería prematuro.
- **`shrink` — preparación Store antigua:** A10; retirar la vía que ya no tiene
  consumidor, en lugar de mantener descargas sin utilidad actual.

No se cuantifica un ahorro neto de líneas sin implementar y medir el diff; no se
propone retirar WPF, convertir todo a clases, añadir una base de datos o migrar
27 menús por motivos estéticos.

### A15. Worker, publicación y herramientas de desarrollo

El Worker es pequeño, usa Web APIs, limita cuerpos, comprueba hashes y falla
cerrado. No hay razón observada para añadir `nodejs_compat`, un framework,
Durable Objects, D1 ni migrarlo obligatoriamente a TypeScript.

`publicFile` y la consulta privada no especifican un plazo propio de `fetch`.
Proponer cancelación con tiempo total que abarque también lectura del cuerpo;
probar conexión lenta y cuerpo detenido. Los límites de tamaño actuales hacen
razonable acumular archivos pequeños antes de verificarlos: sustituir todo por
streaming no elimina la obligación de verificar antes de servir código.

Wrangler fijado: **4.152.0**. Registro npm consultado: **4.154.0**. Actualización
opcional tras notas, lockfile, pruebas y dry-run, no `npm update` indiscriminado.
`npm audit` devolvió cero vulnerabilidades conocidas. Fecha de compatibilidad
`2026-07-01`: no cambiarla solo porque existe una posterior; ensayar su efecto.
La forma de `fetch(request, env)` sigue siendo válida según los tipos oficiales
consultados `@cloudflare/workers-types 5.20261027.1`.

Mantener dominio, pins, ausencia de caché privada y separación onboarding/público.
Una fuente en repositorio privado no vuelve autenticada la URL pública de
instalación; esto ya está documentado correctamente.
[Buenas prácticas de Cloudflare](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/),
[releases oficiales de Wrangler](https://github.com/cloudflare/workers-sdk/releases),
[registro del paquete Wrangler](https://www.npmjs.com/package/wrangler).

## 4. Resultado herramienta por herramienta

«Mantener» significa sin cambio estructural propuesto; no certificación de todas
sus operaciones. Las líneas citadas arriba se refieren a esta instantánea.

| # | Herramienta / fuente en `src/tools/` | Apreciación y acción razonable |
|---|---|---|
| 1 | `Invoke-Fase0.ps1` | Mantener inspección. Renombrar opciones antiguas de aplicar/restaurar que hoy solo inspeccionan; no reactivar presets sin snapshot |
| 2 | `Invoke-PartsUpgrade.ps1` | A02 prioritaria; criterios de ampliación y hash del informe |
| 3 | `Invoke-DiagnosticoMaster.ps1` | Conservar mejoras 1.5.8–1.5.12; A07 para secciones simples, A12 para consultas y apertura múltiple |
| 4 | `Invoke-DiagnosticoEventos.ps1` | Mantener filtro acotado y separación fallo/sin eventos. KB como hipótesis por proveedor+ID, nunca diagnóstico concluyente |
| 5 | `Invoke-PrinterDoctor.ps1` | A07: cobertura de consultas. Mantener consentimiento y código de retorno de página de prueba; corregir guía A13 |
| 6 | `Invoke-KeyboardDoctor.ps1` | A06/A07: esquema del monitor y lector de batería; mantener captura solo en ventana |
| 7 | `Invoke-AIReadiness.ps1` | A03/A07: redacción e inventario incompleto. Modelos como ejemplos fechados, no garantía de rendimiento |
| 8 | `Invoke-GPUCheck.ps1` | A05: escala, idioma y cobertura térmica; estrés requiere aceptación física |
| 9 | `Invoke-MantenimientoPRO.ps1` | Mantener DISM/SFC explícitos y sus límites. No venderlos como aceleración universal ni ampliar limpieza automática |
| 10 | `Invoke-InstalarPaquetes.ps1` | Conservar validación de ID/fuente, cancelación y trabajo fuera de UI. A14 para limpieza bloqueada; QA real de apps pendiente |
| 11 | `Invoke-InstalarMicrosoftStore.ps1` | Mantener registro de paquete existente para usuario correcto y respeto de políticas; eliminar promesas del viejo preparador USB |
| 12 | `Invoke-InstalarRuntimes.ps1` | Mantener VC++ actual y NetFx3 bajo petición. Seleccionar cada legado necesario en vez de instalar todos los cinco componentes antiguos juntos |
| 13 | `Invoke-ActualizarPowerShell.ps1` | Mantener hash+firma Microsoft y reinicio pendiente. Actualizar pin con validación y evitar reinstalar una versión inferior por mera presencia de MSI |
| 14 | `Invoke-Personalizacion.ps1` | Mantener apertura de ajustes nativos. No reconstruir presets de registro ni opciones de marca de agua |
| 15 | `Invoke-StopServices.ps1` | Mantener lista acotada, dependientes y lectura posterior; no convertirlo en optimizador ni parar todo en lote |
| 16 | `Invoke-FastCopy.ps1` | Mantener copia y verificación parcial claramente rotulada; A08/A10. Licencia profesional sigue siendo asunto separado |
| 17 | `Invoke-PrepararUSB.ps1` | Mantener release completo, pins y recursos asociados; A10: estado por dependencia y retirar preparación Store sin consumidor |
| 18 | `Invoke-RespaldoControladores.ps1` | A09: carpeta por intento y manifiesto de todos los miembros; no prometer restauración por contar INF |
| 19 | `Invoke-Robocopy.ps1` | Mantener resultados y evidencia manual ya reunida; A08 para preview, perfil de copia y continuidad del destino |
| 20 | `Invoke-SelectorDNS.ps1` | A01/A11. Alta prioridad por Mullvad y precisión de mediciones |
| 21 | `Invoke-HostsManager.ps1` | A11: bloque idempotente y backup verificable; mantener eliminación de alias exacta y copia de bytes |
| 22 | `Invoke-AuditoriaRouter.ps1` | Corregir «sin cambios» cuando cambia MAC bajo misma IP. Una MAC vista en varias IP no demuestra conflicto. Firmware regex puede confundir hardware con software (`1291`) |
| 23 | `Invoke-GestorBitLocker.ps1` | Mantener backup en otro disco físico antes de cifrar. Exportación antigua: elegir un destino concreto; hoy ofrece copiar a todos los removibles y guarda en Desktop. Evitar mostrar todas las claves por defecto |
| 24 | `Invoke-MenorPrivilegio.ps1` | A03/A04: TXT, errores nativos y snapshot de preset; conservar barreras de último administrador |
| 25 | `Invoke-ExtraerLicencias.ps1` | Mantener ocultación y revelado/copiar explícitos. Aclarar que clave o activación local no acredita derechos comerciales |
| 26 | `Invoke-Deduplicador.ps1` | Mantener no disponible mientras falte backend. No inventar uno; se puede ocultar o marcar como función futura |
| 27 | `Invoke-EntregaPC.ps1` | Mantener checklist persistente, SID, confirmaciones y advertencia de reset de contraseña. Usar desconocido neutral en salud/capacidad ausentes y validar recuperación real fuera del host |

En Router, además: limitar resolución inversa síncrona y no prometer «90 segundos»
sin cubrir ese coste; un HTTP 204 solo prueba ese endpoint, no conexión libre de
interceptación; distinguir timeout de puerto cerrado. La prueba WAN ya advierte
correctamente que se origina en LAN. No añadir escáner externo por defecto.

En BitLocker, `Generate-QRCode` produce una tarjeta de texto en imagen, y el menú
actual ya la llama tarjeta imprimible. Basta renombrar helper/comentarios y
retirar variables QR sin uso; no hace falta añadir una dependencia QR. Un respaldo
de secretos legible es deliberado, pero su destino y conservación deben ser
explícitos. No se generaron ni consultaron claves reales durante esta auditoría.

## 5. Dependencias: qué actualizar y qué conservar

Un canal gestionado por WinGet no permite afirmar la versión instalada por mirar
el JSON de Atlas. La instantánea del catálogo del 25/10 sigue siendo evidencia
fechada, no un sensor de «última versión» ni homologación del fabricante.

| Dependencia | Estado observado | Propuesta y motivo |
|---|---|---|
| PowerShell 7 | Pin 7.6.8; release oficial 7.6.9 del 25/10 | Actualizar MSI/hash juntos y verificar firma, detección y no downgrade. No es necesario cambiar runtime de las 27 tools |
| FastCopy | Pin directo 5.12.0, coincidente con web oficial | No declarar obsoleto. Unificar extracción y preservar recursos/licencia |
| HWiNFO | Canal WinGet, versión no fijada | Registrar versión real y capacidades exportadas; no presuponer funciones Pro o derecho laboral |
| CPU-Z | Canal WinGet | Mantener exportación con output nuevo, comprobar argumentos/versiones y parser por fixtures |
| GPU-Z | Canal WinGet | Registrar formato/columnas, versión y cobertura; no dar por completa una sesión con log insuficiente |
| FurMark 2 | Canal WinGet | Mantener directorio completo y comprobar interfaz CLI. No deducir argumentos de otra generación sin prueba |
| CrystalDiskInfo | Canal WinGet | Conservar `CdiResource`; datos de salud del proveedor no certifican todo el disco |
| CrystalDiskMark | Canal WinGet | Conservar `CdmResource`; benchmark de escritura solo bajo acción explícita, no ejecutar para inventario |
| BlueScreenView | Canal WinGet | Distinguir exportación nueva/vacía/no ejecutada; no atribuir causa definitiva a un driver nombrado |
| BatteryInfoView | Canal WinGet, fallback en Master | Mantener opcional; no descargarlo si datos nativos bastan; reutilizar emparejamiento de batería |
| WinGet / App Installer | Disponibilidad según usuario/edición/política | Mantener comprobación de capacidades; no asumir que Store implica WinGet ni forzar instalación en LTSC |

[PowerShell 7.6.9 oficial](https://github.com/PowerShell/PowerShell/releases/tag/v7.6.9),
[ciclo de soporte](https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle),
[FastCopy oficial](https://fastcopy.jp/).
La página de ciclo de PowerShell consultada todavía mostraba un parche anterior
al release de GitHub: se usa GitHub para la versión y el ciclo para las condiciones
de soporte. Que PowerShell arranque en Windows 10 no extiende el soporte del OS.

Para IA, Llama 3.2, Qwen 2.5 y Phi-3 siguen existiendo: no es correcto llamarlos
inservibles solo por edad. Sí conviene fechar ejemplos y ofrecer modelos más
recientes cuando exista beneficio probado en ese equipo. `AdapterRAM` es un campo
de 32 bits y no acredita VRAM grande; RAM/VRAM total tampoco basta sin backend,
cuantización y contexto. [Win32_VideoController](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-videocontroller),
[biblioteca Ollama](https://ollama.com/library),
[memoria y contexto](https://docs.ollama.com/context-length).

**Licencias y firma:** se mantienen las aplicaciones y la firma aplazada, según
decisión del propietario. Eso no acredita derechos de uso laboral/redistribución
de terceros. No se inicia ninguna compra, solicitud ni sustitución. La licencia
MIT propia ya se incluye en la distribución 1.5.12.

## 6. Comprobaciones y límites de evidencia

Evidencia estructurada: [AUDITORIA-INTEGRAL-1.5.12-2026-10-27.json](AUDITORIA-INTEGRAL-1.5.12-2026-10-27.json).
Los hashes de cada herramienta vinculan la observación al código revisado.

Comprobaciones ejecutadas durante esta revisión:

- AST de las 27 fuentes, sin invocar sus puntos de entrada.
- **7 observaciones reproducidas en PowerShell 5.1 y 7.6.9**: regex de generación,
  conteo del monitor, redacción de nombres, contención de carpeta, resolver con
  dos comandos simulados, límite matemático GPU y comparación de MAC/IP.
- Worker: **24/24**; política CI: **9/9**; `npm audit`: **0** conocidas.
- Inventario generado vigente, guards de seguridad y reproducción de artefactos
  correctos. Manifiesto: `4b01287480ec9b0b0a8adcfb70364f0c5c0a7179ae8b27d960a443df6d046eb6`.
- Descriptor público leído de nuevo: conserva el commit y digest de 1.5.12.
  Estado consultado de Defender: antivirus, tiempo real, servicio y monitor de
  comportamiento activos.

Las siete observaciones reproducen comportamiento aislado o su cálculo. No son
siete ensayos físicos, ni siete nuevas herramientas probadas de extremo a extremo.
La resolución de dos comandos usa un mock; no afirma que todos los PCs tengan
dos ejecutables en PATH. El cálculo de ruta no escribió fuera de un directorio.

La suite completa de la entrega anterior pasó **344 pruebas por runtime** en host
y CI de su SHA; se conserva como antecedente. No se renombra como una ejecución
nueva de este informe ni como homologación Windows 10. Las advertencias del
analizador siguen siendo deuda gradual; convertirlas todas en bloqueantes de
golpe produciría ruido sin resolver primero los errores funcionales.

## 7. Plan de trabajo que recomiendo

| Fase propuesta | Contenido | Agente por su cuenta | Intervención necesaria para cierre real |
|---|---|---|---|
| 1. Corrección próxima | A01, A03 y A06: DNS retirado, redacción/rutas, esquema teclado | Código, fixtures, build 5.1/7, CI, push y promoción autorizada por fase | Aceptación física de red/teclado cuando se retome, sin fingirla con mocks |
| 2. Diagnóstico coherente | A02, A05, A07: PartsUpgrade, GPU y cobertura | Normalizadores pequeños, extremos/errores simulados y reportes | RAM/batería/GPU reales para validar interpretación y sensores |
| 3. Operaciones verificables | A04, A09, A11: cuentas, controladores, DNS/hosts | Validación, códigos, snapshots y pruebas sintéticas | Entorno desechable para aplicar/restaurar, instalar drivers y reiniciar |
| 4. USB y copias | A08/A10: estado por paquete, preview, memoria y dependencias | Fixtures y directorios sintéticos, paquetes/versiones contrastados | USB identificado si se ensayan interrupción, recursos físicos o reinstalación |
| 5. Mantenimiento y claridad | A12–A15: perfil de inicio, docs, código muerto y Worker | Medición local autorizada, informe, limpieza acotada y CI | PC lento para comprobar impacto; autenticación solo si una promoción la exige |

Esta tabla es una propuesta posterior a la auditoría, no una afirmación de que
esas correcciones ya estén aplicadas. Cada fase debería tener diff pequeño,
criterio de aceptación, push y lectura posterior de la publicación; conservar el
enlace actual y Defender activo. No mezclar una actualización de proveedor con
una gran refactorización de 27 herramientas.

Quedan fuera de un cierre autónomo: homologación Windows 10 por edición/parche,
instalaciones y recuperación reales, estrés/hardware adicional y decisiones de
licencia/firma. La copia y restauración pequeña de archivos ya tienen evidencia;
no hace falta repetirlas por costumbre. Retomar lo demás cuando el propietario
quiera, con **una sola VM** y pasos preparados, como acordado.

**Mi apreciación:** el mayor rendimiento del siguiente ciclo vendrá de que Atlas
diga con precisión qué comprobó y qué desconoce. Actualizar nombres de versiones
o sumar más herramientas tendría menos valor inmediato que corregir esos
resultados y mantener sencilla su implementación.
