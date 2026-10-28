# Informes: ubicación y custodia

No hay una carpeta única para todas las herramientas. La ruta mostrada al guardar
es la referencia; las carpetas de Windows pueden estar redirigidas.

| Origen | Ubicación habitual y alcance |
|---|---|
| Get-AtlasReportDir/Path | Documents/AtlasPC/reports y subcarpeta de herramienta |
| IA | Subcarpeta AIReadiness con ID aleatorio; reutilización explícita para comparar |
| Master | Carpeta elegida/mostrada por el flujo, habitualmente Desktop |
| GPU Check | LocalAppData/AtlasPC/reports/GPUCheck, intento fechado |
| Robocopy/FastCopy | Logs nativos en Desktop; destino elegido por el operador |
| Drivers | Export-* nuevo dentro del destino elegido y manifiesto completo |
| USB | usb-dependency-status.json en la raíz del pack; no homologación de proveedores |
| Logs Atlas | LocalAppData/AtlasPC/logs; logs operativos locales sin redacción |

Los exportadores compartidos añaden trazabilidad y redactan identificadores
reconocidos. Revisar texto libre antes de compartir. Redacción no implica cifrado
ni eliminación de los originales. Logs nativos/captura explícita de procesos pueden
contener datos sin redactar.

Snapshots, claves BitLocker y backups conservan datos necesarios para restaurar:
no redactarlos. Custodiarlos aparte, con destinatario/destino acordado; no subirlos
a issues, PRs o este repositorio.

[Aceptación pendiente](TRABAJO-AUTONOMO-Y-ACEPTACION.md),
[copias y USB](COPIAS-Y-USB.md), [releases](RELEASES.md).
