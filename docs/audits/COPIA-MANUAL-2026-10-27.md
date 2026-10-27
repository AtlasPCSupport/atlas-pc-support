# Robocopy: aceptacion manual de archivos ficticios

Ejecuciones manuales desde el panel Atlas 1.5.10 del 26 y 27/10/2026.
El agente preparo fixtures aislados y verifico los resultados por separado.
No se utilizaron documentos de clientes ni VMs.

## Copia completa, 26/10

- Cinco archivos: texto, nombre con espacios y acentos, CSV, binario de 64 KiB
  y archivo de longitud cero; 65 693 bytes en total. Una subcarpeta vacia.
- El destino contenia un archivo ficticio extra para comprobar su conservacion.
- Atlas mostro `Copied + extras in destination` y muestra SHA-256 5/5, sin
  fallos ni faltantes. Una comprobacion independiente de origen/destino contra
  el baseline confirmo los cinco hashes y longitudes, el extra y la carpeta vacia.
- Se conservaron seis archivos en destino: cinco copiados y el extra previo.

## Copia incremental, 27/10

- Se modifico un archivo del origen y se anadio otro; cuatro permanecieron iguales.
- El panel genera una carpeta con fecha actual. Como cambio el dia, antes de
  confirmar se preparo el destino del 27 con una copia verificada del baseline
  del 26, conservando los tiempos de modificacion y la carpeta original intacta.
  No se presenta como reutilizacion automatica de la carpeta de otro dia.
- Atlas mostro muestra SHA-256 6/6, sin fallos ni faltantes.
- El log nativo `Log_Atlas_2026-10-27_1337.txt` registro: seis archivos de
  origen, dos copiados (176 bytes), cuatro omitidos, cero discrepancias, cero
  fallos y un extra (59 bytes). Los dos copiados fueron el modificado y el nuevo.
- La comprobacion independiente confirmo los seis hashes y longitudes contra
  el origen esperado, los tiempos de modificacion de los cuatro sin cambios,
  el extra, la carpeta vacia y la copia original del 26 intacta.
- Se conservaron siete archivos en destino: seis del origen y el extra previo.

Las evidencias locales se conservan en Temp con los nombres
`atlas-manual-copy-result-f382e0cb41984d548ebcbe3e88cb15ec.json`,
`atlas-manual-copy-incremental-20261027-f382e0cb41984d548ebcbe3e88cb15ec.json` y
`atlas-manual-copy-incremental-result-20261027-f382e0cb41984d548ebcbe3e88cb15ec.json`.
Este documento publica un resumen, sin rutas personales del host.

## Correccion de interfaz, 1.5.11

Los prompts de verificacion de copia inicial y repetida decian MD5, aunque el
verificador compartido ya utilizaba SHA-256. Se corrigen ambos idiomas y se
explicita que es una muestra. No cambia el algoritmo, el tamano de muestra ni
los argumentos de Robocopy. Las pruebas manuales anteriores son de 1.5.10,
no se atribuyen a una ejecucion manual de 1.5.11.

## Limites y siguiente paso

Ambas copias usaron el mismo volumen del host y archivos pequenos. Los 0,1 s
mostrados no son un benchmark de velocidad ni permiten predecir otro equipo.
No cubren ACL, disco lleno, cortes de energia, USB adicional, restauracion del
sistema, instalaciones reales o Windows 10. Las VMs siguen pausadas.

Siguiente ensayo: restaurar el contenido de la copia verificada (los seis archivos
del origen y el extra ficticio conservado) a una carpeta nueva, sin borrar ni
sobrescribir el origen, y contrastar los siete hashes.
La recuperacion de archivos en ese alcance tampoco certifica recuperar Windows.
