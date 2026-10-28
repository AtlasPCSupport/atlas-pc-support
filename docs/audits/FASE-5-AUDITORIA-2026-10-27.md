# Fase 5: mantenimiento y claridad — 1.5.17

Atiende A12–A15 del informe integral con cambios conservadores y evidencia local.

## Inicio y recursos

Las capacidades se consultan fuera del dispatcher después del primer pintado.
Las tarjetas permanecen en «Comprobando…», deshabilitadas, hasta una respuesta
válida. Un fallo no las habilita. El proceso hijo conserva las verificaciones de
plataforma, identidad y hashes antes de ejecutar. Se conservan WPF y runtime 5.1.

Cinco procesos nuevos antes y cinco después: mediana de primer pintado **5,79 s →
2,33 s**; percentil 95 por rango más cercano con n=5 **6,16 s → 2,59 s**. Mediana
de dispatcher idle **5,83 s → 2,37 s**. Son muestras pequeñas en este host, con
caché del sistema existente, sin descarga/bootstrap ni arranque desde apagado.
Primer pintado/dispatcher libre no significa todas las tarjetas evaluadas.
No predicen minutos o segundos en un PC de cliente. No se vacía caché del host.
[Muestras y alcance](INICIO-FASE-5-2026-10-27.json); script reproducible
`tests/Measure-AtlasStartup.ps1`, una ventana y cierre automático, cero tools.

El ejecutor nativo drena stdout/stderr en bloques, conserva por defecto una cola
máxima de 65.536 caracteres por canal y marca truncamiento. Mantiene códigos,
cancelación y timeout; no interpreta cola como salida completa. Un log nuevo y
explícito conserva toda la salida con etiquetas de canal; puede contener datos
sensibles y consumir disco. No se crea un log completo sin pedirlo.

Master ofrece aplicaciones al final por elección y espera al cierre de cada
proceso, en vez de lanzar cuatro de golpe. No cierra aplicaciones ajenas.
Consultas CIM existentes que no pasan por este flujo no quedan universalmente
acotadas por tener un wrapper; su revisión gradual continúa.

## Simplificación y documentación

Se eliminan el helper sin consumidor Invoke-SelfElevate (incluía Unblock-File),
el backend sin uso de limpieza masiva de temporales y su opción visible. Se
rechaza ejecución inline: las 27 entradas usan el hijo verificado. No se reactivan
presets ni borrados globales. Fase 0 rotula sus opciones como inspección/guía.

Plantilla y guía de branding solo ofrecen campos consumidos, sin autoelevación
o rutas configurables ficticias; se retira el esquema inexistente. README remite
a ubicaciones por herramienta y ADDING-TOOLS deja de inventar /Json para Crystal.
Matriz separa EnterpriseS de IoTEnterpriseS. Especificaciones de mayo se marcan
históricas/sustituidas. Se indexan fechas, versiones, propuestas no adoptadas y
aceptación pendiente, conservando archivos y referencias históricas.

## Worker

Plazo de 15 s por descarga upstream, cubriendo conexión y cuerpo; cancela y falla
con 504 si se agota. El camino público puede requerir manifiesto y miembro (dos
descargas), no se promete que toda ruta tarde menos de 15 s. Mantiene límites de
tamaño, hash previo al servicio de código, pins independientes y no-store privado.
No se añaden framework, servicios ni nodejs_compat. Compatibilidad de julio se
conserva para evitar migraciones no comprobadas.

Wrangler 4.152.0 → 4.154.0, pin/lock juntos, notas oficiales revisadas y sin update
indiscriminado. 27 pruebas Worker aprobadas (tres nuevas de timeout/cuerpo/timer),
npm audit sin vulnerabilidades conocidas y dry-run aprobado. Tipos oficiales
5.20261027.1 consultados fuera del repo; no se añade dependencia de tipos.

Pruebas nuevas: salida grande simultánea y log, protección de log previo, tarjetas
de capacidades lentas/fallidas y rechazo inline. Las suites completas 5.1/7 y CI
del SHA exacto preceden a promoción; evidencia final pública en PR.

Resultado local: **400 pruebas aprobadas en cada runtime** (5.1.26100.9711 y
7.6.9), cero fallos/omitidas/errores del analizador. Cinco regresiones nuevas;
guards, build reproducible y WPF aprobados. Política CI 9/9; barrido de enlaces
locales en 49 archivos Markdown sin rutas faltantes (ejemplos de código excluidos).
Manifiesto: f251e2e0ecbef7b54bc00d6c173709b1bcdee2328d4b38fd58c9d72614399577.
Las muestras después del cambio se tomaron antes del incremento de versión de
la candidata; no se confunden con la publicación anterior 1.5.16.

## Límite del cierre autónomo

Las cinco fases tienen implementación y comprobaciones de software. No cierran
homologación Windows 10 por edición/parche, recuperación tras reinicio, instalación
real de apps/drivers, estrés/sensores ni permisos comerciales. VMs pausadas,
Defender activo, firma aplazada y aplicaciones conservadas. El detalle por tool
del informe contiene además mejoras futuras (por ejemplo Router/BitLocker), que
no se convierten automáticamente en operaciones reales aprobadas o ensayadas.

Fuentes: [Workers](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/),
[streams](https://developers.cloudflare.com/workers/runtime-apis/streams/readablestreamdefaultreader/),
[Wrangler 4.154.0](https://github.com/cloudflare/workers-sdk/releases/tag/wrangler%404.154.0).
