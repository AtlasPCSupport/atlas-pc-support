# Preferencia de idioma — 1.5.21

Revisión acotada de deuda con un fallo reproducido sobre archivos ficticios.
No cambia herramientas, dominio público ni configuración real del propietario.

## Problema y corrección

Al seleccionar otro idioma, el guardado ignoraba un error al leer `config.json`
y podía reemplazarlo por un objeto que solo contenía el idioma. Además, serializar
con profundidad 5 truncaba ajustes anidados ajenos al selector. La UI anunciaba
que había que reiniciar incluso si el guardado devolvía falso.

Ahora un JSON ilegible o cuya raíz no sea un objeto se conserva sin sobrescribir.
Se valida el idioma y se serializa el objeto completo antes de escribir; la
profundidad admitida es 100 y una advertencia de truncamiento detiene la operación.
Se escribe en un temporal de la misma carpeta y se reemplaza el archivo mediante
las operaciones de .NET ya usadas por otros guardados de Atlas. Un error devuelve
falso y limpia el temporal si es posible. No se añaden dependencias ni un nuevo
sistema de configuración. Leer una preferencia ausente ya no crea carpetas.

El panel restaura la selección del idioma en uso y muestra una advertencia
traducida si falla el guardado. Solo muestra el mensaje de reinicio si se guardó.
Se mantienen los siete idiomas y el formato `config.json` existente.

## Verificación y límites

Nueve regresiones comprueban creación/lectura, preservación de valores anidados,
JSON dañado, raíz array/null, idioma no admitido, escritura denegada y las dos
ramas del handler real del selector. El test del handler sustituye únicamente
la llamada estática al diálogo para evitar interacción; el bloqueo de escritura
se ensaya con un archivo de prueba abierto en Windows. No se toca el perfil real.

Las suites completas, resultados del analizador y manifiesto se registran en
[la evidencia estructurada](PREFERENCIA-IDIOMA-1.5.21-2026-10-29.json). CI, commit
publicado, Worker y verificación del dominio se registran en la PR de entrega;
las pruebas locales por sí solas no demuestran publicación.

Resultado local: **456 pruebas aprobadas conjuntamente en cada runtime**,
PowerShell 5.1.26100.9711 y 7.6.5; cero fallos u omitidas. El comprobador completo
previo aprobó los 447 casos anteriores, guardas, distribución reproducible y
artefactos sin cambios; el nuevo fichero de nueve casos ya está incluido en ese
runner para CI y próximas ejecuciones. Analizador: cero errores y 253/264
advertencias, respectivamente. No se suprimen reglas ni se afirma cero deuda.

El cambio no repara automáticamente un archivo ya dañado ni certifica apagados
inesperados, escrituras concurrentes de otros procesos o cualquier sistema de
archivos. Un formato no admitido se conserva para revisión del propietario.
VMs pausadas; Windows 10 sigue sin homologación completa. Firma, licencias,
hardware e instalaciones/recuperaciones reales mantienen sus pendientes.
