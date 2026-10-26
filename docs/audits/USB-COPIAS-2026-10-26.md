# Recursos de herramientas en USB — Atlas 1.5.7

La revision del preparador USB encontro una ruta alternativa que aceptaba una
copia por tamano/fecha si Robocopy fallaba, sin validar todos sus bytes. Tambien
faltaban comprobaciones de destino recursivo y enlaces en descendientes.

Se mantiene Robocopy nativo como unico motor de estas copias de carpetas
(recursos de CrystalDiskInfo y CrystalDiskMark). Se elimina el fallback manual.
Un codigo nativo no aceptado aborta con su estado, sin reintentar con otro motor.
Antes de copiar se verifican origen/destino, cada directorio seleccionado y
archivos existentes; se rechazan reparse points sin recorrerlos. Tras copiar se
comparan hashes SHA-256 de todos los archivos de recursos enumerados, incluso
cuando tamano/fecha coinciden. Una carpeta sin archivos no se declara completada.

No se eliminan extras del destino ni se instalan programas para estas pruebas.
La verificacion no instala confianza Authenticode ni elimina carreras si otro
proceso cambia rutas o archivos durante la operacion. Solo certifica igualdad de
los bytes observados de esos recursos, no una USB completa ni su recuperacion.

## Evidencia

Seis regresiones fallaron con el codigo anterior y las siete pasaron despues:
salida nativa correcta sin archivos, corrupcion con metadatos identicos, fallo
nativo, destino recursivo, junction de origen, junction en descendiente destino,
y copia completa con un archivo extra conservado. Todos los casos usan TestDrive
y un proceso simulado; no modifican ubicaciones del cliente.

Ademas se ejecuto la funcion de produccion aislada con Robocopy real en una nueva
carpeta de la USB NTFS. Copio correctamente, verifico todos los fixtures y rechazo
una alteracion de igual tamano y fecha; conservo el extra ficticio. Evidencia:
[USB-DEPENDENCY-COPY-2026-10-26.json](USB-DEPENDENCY-COPY-2026-10-26.json).

Suite completa: 270 aprobadas por runtime Windows PowerShell 5.1.26100.9711 y
PowerShell 7.6.9, cero fallos/omisiones y cero errores del analizador; 292/318
avisos conservados. Build reproducible 1.5.7, 27 herramientas y 33 miembros.
Los informes XML/JSON locales estan en Temp, carpetas
`atlas-local-checks-2488f58202b44ad597be2981196209a8` y
`atlas-local-checks-fb26f62affc745dcb97e4478bb06221d`.

La aceptacion general previa de la llave y sus limites estan en
[USB-2026-10-26.md](USB-2026-10-26.md). No se ejecutaron CrystalDiskInfo,
CrystalDiskMark, VMs, cifrado, cambios de red, instalaciones ni formateos.

Referencia: [Robocopy y sus opciones/codigos](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy).
