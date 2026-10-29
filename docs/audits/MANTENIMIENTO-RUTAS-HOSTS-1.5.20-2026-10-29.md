# Mantenimiento de rutas, hosts y variables — 1.5.20

Bloque acotado posterior a 1.5.19. Conserva herramientas, dominio, PowerShell 5.1,
Defender y decisiones del propietario. No reanuda VMs ni realiza copias sobre
datos de uso, cambios de hosts/DNS, instalaciones o estrés del equipo de trabajo.
Las operaciones de archivos de las pruebas quedan dentro de directorios ficticios.

## Cambios

| Área | Cambio | Motivo y alcance |
|---|---|---|
| FastCopy y Robocopy | La selección de destino exige una carpeta literal accesible y utiliza Assert-AtlasCopyDestination, igual que la ejecución. Un error vuelve a pedir destino y muestra el motivo. | Sustituir comprobaciones duplicadas con catches vacíos; validar todos los orígenes antes de continuar con la vista previa. La validación final de ejecución se conserva. |
| Hosts Manager | Aplicar el bloque administrado y restaurar su respaldo usan Clear-AtlasDnsCache, con ipconfig /flushdns mediante ejecutor nativo y plazo de 15 s. | El resultado del archivo se informa separado del estado de caché. Timeout, cancelación, fallo y lanzamiento no evaluado no se convierten en refresco completado. No se promete una medición de toda la resolución DNS por obtener exit 0. |
| Variables | Nombres locales propios sustituyen profile en FastCopy/USB/SelectorDNS, args en GPU e input en Robocopy; se actualizan todas sus referencias por AST. | Evitar colisiones con variables automáticas sin cambiar argumentos, selección ni rutas. Se mantienen los parámetros de eventos .NET cuyo nombre es deliberado. |
| Entrega PC | Se retira la consulta BIOS cuyo resultado no se consumía y una asignación de Desktop sin uso. | Menos consultas innecesarias y un posible fallo de inventario menos; los campos privados siguen redactados. No se afirma una mejora de tiempo medida. |
| Código sin consumidor | Se eliminan variables sin uso de FastCopy y la tabla DoH sin consumidor. | Reducir mantenimiento, sin añadir capacidades DoH ni activar registro/configuración de red. |
| Selector DNS | Se retira la sonda de latencia Mullvad 6 heredada. Los perfiles clásicos admitidos permanecen iguales. | Completar la retirada del proveedor que aún aparecía en el listado de sondas. ICMP no certifica servicio DNS ni privacidad. |

Mullvad anunció el cierre de su DNS público cifrado para el 2/11/2026. No se
modifica una VPN instalada ni se cambia la configuración DNS del usuario:
[anuncio oficial](https://mullvad.net/de/blog/2026/9/3/shutting-down-our-public-encrypted-dns-servers-and-sponsoring-quad9-instead).
[ipconfig y Windows 10](https://learn.microsoft.com/windows-server/administration/windows-commands/ipconfig)
documenta flushdns como vaciado de la caché del cliente.

## Pruebas y evidencia

Trece regresiones nuevas ejercitan los bucles reales de destino de ambas tools:
destino recursivo, origen desaparecido, acceso denegado y cancelación posterior.
Incluyen rutas literales con espacios/corchetes. No se inicia una copia ni se
consulta el disco después de una validación fallida.

Las acciones reales de aplicar/restaurar hosts se ejecutan solo sobre archivos
ficticios y con descarga/proceso nativo simulados. Verifican bytes exactos del
respaldo, incluido BOM, y resultados separados si falla o expira el refresco DNS.
Los tests de variables conservan argumentos/duración/directorio de GPU, selección
de perfil de FastCopy sin alterar PROFILE, entradas/cancelación de Robocopy,
estimaciones USB y entradas DNS admitidas. No se lanzan procesos gráficos externos.

Suites completas 5.1/7, distribución reproducible, guards y CI del SHA exacto
preceden a la promoción. El número de versión del informe no prueba publicación:
la evidencia final de CI, Worker y verificación pública queda en la PR de entrega.

Resultado local: **447 pruebas aprobadas por runtime**, 5.1.26100.9711 y 7.6.5;
cero fallos, omitidas o errores del analizador y artefactos sin cambios durante
ambas suites. Worker 27/27, política CI 9/9, npm audit sin vulnerabilidades conocidas,
dry-run y enlaces locales de 53 documentos aprobados. Quedan 248/266 advertencias
del analizador, respectivamente, frente a 265/283 en 1.5.19; no se suprimen reglas.
[Evidencia estructurada](MANTENIMIENTO-RUTAS-HOSTS-1.5.20-2026-10-29.json).
Manifiesto: `a6ac49d1e9522970ef7110b1b2fe06ea0e821762cc33033ec44d57b2008fd848`.

## Límites conservados

La aceptación de Windows 10 por edición/parche, instalaciones, recuperación tras
reinicio y hardware adicional permanece pendiente. VMs pausadas. El USB físico
no se actualiza al publicar. Firma pública aplazada y permisos comerciales de
terceros conservan su estado. La deuda del analizador se revisa por impacto;
no todos sus avisos representan defectos y no se suprimen reglas para dar cero.

[Guía de aceptación](../TRABAJO-AUTONOMO-Y-ACEPTACION.md).
