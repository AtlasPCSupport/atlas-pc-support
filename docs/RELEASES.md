# Publicación y recuperación de Atlas

El enlace de entrada sigue siendo:

```powershell
irm https://toolspanel.atlaspcsupport.com | iex
```

## Qué se aprueba

El Worker mantiene `ATLAS_RELEASE_COMMIT` (SHA completo de Git) y
`ATLAS_RELEASE_MANIFEST_SHA256` (digest de `release-manifest.json`) como variables
del despliegue. No calcula la autoridad de publicación leyendo hashes de `main`.
El manifiesto enumera bootstrap, launcher, catálogo de dependencias, contratos de
herramientas, hashes, instalador batch público y los 27 scripts. Desde 1.5.12
incluye tambien LICENSE de Atlas como miembro verificado (34 miembros en total).
Las versiones anteriores completas siguen siendo verificables para rollback;
no se presume que sus paquetes contengan ese archivo. El aviso MIT propio no
concede licencias sobre utilidades de otros autores. Los textos usan
SHA-256 sobre UTF-8/LF sin BOM; el propio manifiesto tiene digest de bytes exactos.

Una entrada guardada de una version anterior conserva su lista estricta de
miembros y puede rechazar la adquisicion de 1.5.12. Para actualizar, reabrir el
enlace HTTPS habitual; para una USB, volver a prepararla desde el panel actualizado.
La entrada y release antiguas siguen pudiendo verificar su propio conjunto sin
conexion. El verificador nuevo permite seleccionar una release anterior completa.

El Worker verifica el manifiesto contra su pin y el bootstrap contra el manifiesto
antes de servirlo. Inserta el commit y digest aprobados en dos literales del
bootstrap. Cada descarga posterior usa ese mismo commit, incluso el fallback API.
Una sesión abierta no refresca hashes ni herramientas desde otra versión.

El launcher nuevo también acepta la invocación sin parámetros del `get.ps1`
anterior: adquiere el conjunto aprobado y lo vuelve a iniciar con su contexto.
Las ventanas antiguas que ya estaban abiertas no se pueden corregir remotamente;
cerrarlas y reabrir el enlace al terminar esta migración.

`?ref=main` significa la publicación aprobada actual. `?ref=<SHA completo>` solo
admite la actual o la anterior aprobadas en el Worker. Un branch, tag o SHA que no
esté publicado produce 404; una sintaxis inválida produce 400. `?v=` sigue siendo
un parámetro inocuo para compatibilidad. No se cae silenciosamente a otra versión.

## Confianza y límites

La confianza inicial es el bootstrap servido por HTTPS desde el dominio controlado
en Cloudflare. Un checksum descargado del mismo repositorio no crea esa confianza.
El acceso para promover el Worker es distinto del permiso para hacer push: no hay
un token de Cloudflare en el repositorio ni promoción automática por cambiar `main`.

Esto no es una firma Authenticode de Atlas. No autentica retrospectivamente un
bootstrap obtenido de otra fuente ni protege contra el reemplazo de **todo** el
contenido de una USB, incluido su punto de entrada y ancla local de confianza.
La USB debe prepararse desde una sesión verificada y mantenerse bajo custodia.
Una firma de código gestionada puede añadirse sin sustituir esta coherencia de
versiones; no se ha generado ni almacenado una clave privada dentro del proyecto.

Defender/AMSI siguen analizando el código. Este mecanismo no añade exclusiones,
ofuscación, `EncodedCommand`, eliminación de MOTW ni cambios permanentes de política.
La reputación de SmartScreen y la homologación en VMs Windows 10 se prueban aparte.

## Preparar y promover

1. Modificar fuentes/configuración. Cada herramienta declara runtime, versión
   mínima, arquitectura y bibliotecas. La base actual es Windows PowerShell 5.1 x64;
   la selección adicional de PS7 se homologa por herramienta en la fase 3.
   Las entradas normalizan la precedencia de módulos nativos dentro del proceso
   Desktop, también cuando se inicia desde PS7; no requieren cambiar el entorno
   persistente del equipo.
2. Ejecutar `pwsh -NoProfile -File ./build.ps1` y los checks de
   [tests/README.md](../tests/README.md). El build es reproducible en 5.1 y 7.
3. Commitear juntos `get.ps1`, `launcher.ps1`, su sidecar, `config/tool-hashes.json`,
   `release-manifest.json` y sus fuentes. Hacer push y esperar `build`,
   `windows-compat` y `worker` en el **mismo SHA**.
4. Desde un checkout limpio de ese commit, promover:

```powershell
pwsh -NoProfile -File ./api/cloudflare-worker/publish-release.ps1 -Commit <SHA-completo-aprobado>
```

El script verifica checkout, bundle local, CI del SHA y manifiesto del commit remoto.
Despliega código y pins en una sola versión del Worker, conservando las variables
y secretos existentes. Si ya existe una publicación aprobada, retiene su descriptor
como anterior. `-DryRun` compila sin publicar y permite revisar cambios locales.

En la migración inicial puede promoverse el commit de la PR una vez aprobada por CI,
verificar el dominio y después integrar la PR: así el Worker anterior no llega a
servir el bootstrap nuevo con su protocolo antiguo. El SHA publicado identifica el
commit probado; no tiene por qué ser el SHA del commit de merge.

Después se verifican `/`, `/release.json`, `/release-manifest.json`, los sidecars,
los 27 scripts del commit, un ref inexistente y los métodos HTTP. El artefacto CI
`atlas-release` contiene el conjunto completo; el build de CI no hace un commit
automático ni cambia por sí solo la publicación.

El antiguo `set-worker-secrets.ps1` puede mantener `GITHUB_PAT` para onboarding.
Sus dos pins SHA antiguos ya no promueven Atlas. Usar `publish-release.ps1`.

## Almacenamiento y vuelta atrás

La instalación online usa `%LOCALAPPDATA%\AtlasPC` y la USB `ATLAS_PC_SUPPORT`:

```text
current.json                 puntero activado después de verificar todo
previous.json                puntero anterior, cuando exista
releases/<commit>/           conjunto completo; nunca se modifica para actualizar
releases/.staging-<guid>/     descarga incompleta, no ejecutable como release activo
get.ps1 + run.bat            entrada estable solo en la USB
get.previous.ps1             backup de la entrada al volver a preparar la USB
apps/ y deps/                paquetes de terceros opcionales, separados del código
```

La adquisición tiene un bloqueo exclusivo. Verifica todos los miembros en staging,
renombra la carpeta completa y reemplaza el puntero en el mismo volumen mediante
`File.Replace`; el puntero anterior queda como backup. Si el sistema de archivos no
permite ese reemplazo, la actualización falla y mantiene el puntero previo. No se
afirma resistencia a una pérdida eléctrica en cualquier firmware/sistema de archivos.

Cada inicio offline vuelve a comprobar el conjunto y no consulta la red. Para
validar sin abrir el panel o para volver al anterior:

```powershell
# USB, desde su carpeta:
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\get.ps1 -OfflineRoot . -NoLaunch
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\get.ps1 -OfflineRoot . -Rollback

# Online: guardar primero el bootstrap HTTPS localmente y ejecutarlo con -Rollback.
# -NoLaunch permite comprobar/descargar el bundle sin ejecutar el launcher.
```

La versión previa también se verifica antes de seleccionarla. No hay rollback si
todavía no existe una versión anterior válida; la primera instalación de este
protocolo establece esa base. Una USB antigua conserva sus archivos heredados, pero
estos no se consideran una versión autenticada ni se seleccionan automáticamente.
Los releases no se borran automáticamente; se puede retirar manualmente uno que ya
no figure en los punteros y no esté siendo usado por una sesión.

El rollback restaura código y contratos de Atlas. No desinstala paquetes de terceros
ni revierte operaciones de cuentas, cifrado o reparación realizadas por las tools.
Los opcionales pueden requerir red, permisos y licencias propias aunque el panel y
los 27 scripts estén disponibles sin conexión.

Para recuperar la publicación del servidor, promover de nuevo un commit completo
ya comprobado o desplegar una versión del Worker compatible con este protocolo.
No hacer rollback a un Worker anterior a esta migración después de cambiar `main`:
ese Worker dependía del bootstrap mutable antiguo.
