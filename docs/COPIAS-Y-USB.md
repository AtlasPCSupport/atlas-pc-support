# Copias y USB: alcance de los resultados

## Copia e incremental

Robocopy y FastCopy conservan el origen y los extras del destino en sus modos de
copia. Mover y sincronizar permanecen bloqueados. Revisa siempre la ruta final.

1. Elige origen y destino. La carpeta fechada sigue siendo el valor predeterminado.
2. En incremental puedes escribir la ruta exacta de un respaldo existente para
   continuarlo, también si se creó otro día. Elige la carpeta del respaldo, no su
   padre. Enter conserva la carpeta fechada: una carpeta nueva es otro respaldo.
3. Elige exclusiones. El censo es opcional: escribe COUNT para recorrer el origen
   o pulsa Enter para omitirlo. Incluye ocultos/sistema y aplica exclusiones por
   nombre; no sigue enlaces. Un acceso fallido deja el censo incompleto.
4. Si no hay censo completo se muestra N/D, sin total ni ETA inventados. No se ha
   demostrado que quepa todo en el destino: revisa el espacio y el log del motor.
5. Revisa la preview y confirma la copia. El log nativo decide el resultado.

La comparación previa de FastCopy solo identifica candidatos por tamaño/fecha;
«mismos metadatos» no equivale a contenido íntegro. Los filtros avanzados del
motor y archivos que cambien durante el recorrido pueden diferir de esa preview.
FastCopy copia las carpetas bajo su nombre; la muestra comprueba esa misma ruta.

La muestra SHA-256 elige las primeras rutas en orden ordinal y conserva como
máximo el número solicitado en memoria. Recorre el árbol para contabilizar su
alcance, pero no ordena ni conserva todos sus archivos. Enlaces o rutas ilegibles
no se certifican; tampoco una muestra vacía. No es certificación de copia completa.

Robocopy conserva MT:32 y /J como perfil, sin garantizar velocidad. Se retira /FFT
del valor predeterminado para conservar precisión temporal; no se aplica a todos
los destinos la tolerancia FAT de dos segundos. Un destino con menor precisión
puede necesitar tratamiento específico o recopiar archivos. No se cambian esos
perfiles para prometer rendimiento sin un ensayo del medio.

## Preparar USB

El código Atlas se verifica como un release completo antes de activarse. El
estado de sus aplicaciones opcionales se muestra y guarda aparte en
`usb-dependency-status.json`:

- `MissingOrIncomplete`: falta el ejecutable o un directorio de recursos requerido.
- `PresentNotEvaluated`: existe, pero falta evidencia verificada de esta copia.
- `CopiedAndHashVerified`: se verificaron los miembros copiados en este intento.
- `RecordedFilesVerified`: los archivos aún coinciden con la evidencia guardada.
- `ChangedOrNotEvaluated` / `FailedAttempt`: hubo cambio, fallo o falta de cobertura.

GPU-Z solo no completa el grupo GPU. CPU-Z, batería, HWiNFO y recursos Crystal se
evalúan por separado. FurMark y Crystal conservan sus árboles de recursos y se
comprueban todos los archivos copiados; los archivos extra del destino se conservan.
Los hashes del registro permiten detectar cambios respecto de la copia observada;
no sustituyen la autenticación del proveedor, sus licencias ni una prueba real de
esa versión. Para herramientas de un solo ejecutable la cobertura se limita a ese
archivo. Una versión no informada permanece desconocida.

Un fallo/timeout de extracción FastCopy no lanza otro instalador. Se conservan
los restos para inspección. Se retira la descarga Store antigua sin consumidor;
la herramienta Store registra un paquete existente y respeta las políticas de la
edición. No se promete instalar Store en LTSC/IoT ni un fallback inexistente.

El MSI opcional de PowerShell es 7.6.9, con pin de hash de Microsoft y comprobación
de su firma al usarlo. Las rutas de instalación rechazan un downgrade. Preparar
el MSI no significa instalarlo ni homologar Windows 10. Las 27 herramientas
mantienen sus contratos de runtime; 5.1 sigue siendo el predeterminado.

Fuentes: [Robocopy](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy),
[FastCopy](https://fastcopy.jp/help/fastcopy_eng.htm),
[PowerShell 7.6.9](https://github.com/PowerShell/PowerShell/releases/tag/v7.6.9).
