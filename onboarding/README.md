# Onboarding de acceso remoto

Instala/configura RustDesk mediante el instalador aprobado del servicio, durante
una intervención asistida y autorizada por el cliente. El endpoint disponible no
demuestra una instalación ni una conexión correcta al servidor.

## Uso

1. Descargar `install.bat` desde [Atlas](https://toolspanel.atlaspcsupport.com/install.bat).
2. Revisar origen, alcance y avisos de Windows. La persona presente acepta UAC;
   cancelarlo detiene la operación con error.
3. El wrapper verifica SHA-256 antes de ejecutar el archivo local. Cada intento
   tiene una carpeta GUID bajo `%ProgramFiles%\AtlasPC\onboarding`, restringida a
   Administradores/SYSTEM. Rechaza enlaces, propietarios y permisos inesperados.
   Un lock impide repetir/solapar el mismo intento; los bytes verificados permanecen
   abiertos sin permiso de escritura/borrado mientras corre el instalador.
4. Se conserva la política efectiva de PowerShell. Si Restricted, AllSigned, MotW,
   AppLocker, WDAC o una política empresarial bloquean el archivo, detener y revisar
   con el responsable del equipo. La instalación automática puede no estar disponible;
   usar el procedimiento oficial aprobado de RustDesk o un instalador firmado
   autorizado. No eliminar procedencia ni bajar protecciones para ejecutarlo.
5. Comprobar versión, servicio, configuración persistente, ID y conexión autorizada.
   Registrar resultados saneados. Instalación limpia, repetición, upgrade y reinicio
   siguen siendo escenarios distintos.

Los intentos se conservan para diagnosticar fallos. Retirar manualmente una carpeta
GUID solo después de revisarla y confirmar que ya no está en uso. Los archivos de
recuperación/credenciales creados por el instalador requieren custodia separada.

## Publicación

El BAT pertenece al manifiesto de la release. El Worker verifica sus miembros contra
commit y manifiesto aprobados. `/install.ps1` y su checksum son públicos por diseño;
el origen privado de GitHub no vuelve confidencial lo que se entrega al cliente.
El checksum se deriva de los bytes verificados, no de otro sidecar mutable.

Pins: `ATLAS_RELEASE_COMMIT`, `ATLAS_RELEASE_MANIFEST_SHA256`,
`ATLAS_ONBOARDING_COMMIT`, `ATLAS_ONBOARDING_SHA256`. `GITHUB_PAT` permanece como
secreto del Worker: permisos mínimos de lectura, caducidad y rotación revisadas por
su propietario. No imprimirlo ni incorporarlo a Git.

Tras cambiar el origen, actualizar sus pins mediante revisión y seguir la
[publicación de Atlas](../docs/RELEASES.md):

```powershell
pwsh -NoProfile -File ./api/cloudflare-worker/publish-release.ps1 -Commit <SHA-completo-comprobado>
```

La promoción exige checkout limpio y los tres jobs de CI aprobados sobre ese SHA.
Un push por sí solo no modifica el enlace público.

## Diagnóstico

| Resultado | Acción |
|---|---|
| UAC cancelado/no disponible | Detener y coordinar con la persona presente. |
| Política/firma/procedencia bloqueada | Revisar el mensaje con el administrador y conservar las protecciones. |
| Antivirus bloquea un archivo | Revisar detección, origen, hash y firma cuando exista; acudir al proveedor si corresponde. No permitir carpetas temporales completas ni desactivar Defender/AMSI. |
| Hash inválido o endpoint 502/503 | No ejecutar; revisar pins y publicación. No aceptar bytes desconocidos recalculando su hash. |
| Propietario, ACL o enlace inesperado | Investigar; no tomar posesión ni reparar la carpeta automáticamente. |
| Servicio/ID/conexión no verificados | Conservar evidencia saneada y revisar instalación/servidor. No declarar enrolamiento correcto por terminar el proceso. |

Atlas no promete eliminar avisos de SmartScreen. La compra de firma está aplazada;
comprar un certificado no garantiza reputación. La asistencia con otros productos
debe respetar su licencia: AnyDesk gratuito es para uso personal; consultar
[uso profesional](https://anydesk.com/en/professional-use).

Las pruebas aisladas cubren integridad, sustitución, concurrencia, rutas y fallos.
La instalación/conexión real y el código/servidor privado requieren aceptación aparte.
