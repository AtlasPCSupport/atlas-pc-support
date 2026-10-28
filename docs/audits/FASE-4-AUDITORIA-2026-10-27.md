# Fase 4: USB, dependencias y copias — 1.5.16

Atiende A08/A10 del informe integral. Guía vigente:
[copias y USB](../COPIAS-Y-USB.md).

- Enumeración progresiva con iteradores por profundidad y muestra ordinal de
  tamaño acotado, sin guardar/ordenar todos los archivos. Preview opcional,
  ocultos, exclusiones y consulta incompleta explícitos; sin censo se omite ETA.
- Incremental puede continuar una carpeta existente elegida expresamente, aunque
  tenga otra fecha. La carpeta fechada nueva se mantiene como alternativa visible.
- Comparación FastCopy por tamaño/fecha corregida y rotulada como metadatos;
  muestra alineada con su estructura de destino. Todos los orígenes se validan
  antes de crear el destino. No se habilitan mover/sincronizar.
- Resolver de dependencias: una aplicación real, selección determinista,
  verificación de recursos Crystal y versión/procedencia observadas en log. No se
  exige firma a todas las apps legítimas ni se afirma que estén actualizadas.
- USB: evidencia por componente, hashes de los miembros copiados, revisión de
  registros previos y recursos completos para FurMark/Crystal; los grupos no se
  saltan por encontrar solo un ejecutable. Código Atlas y paquetes opcionales se
  informan separadamente. El inventario no certifica ejecución o derechos de uso.
- Se retira la descarga Store sin consumidor y el segundo intento de instalación
  FastCopy tras extracción fallida. La telemetría mide duración; no llama velocidad
  de transferencia al crecimiento del destino. Se conservan aplicaciones y extras.
- MSI opcional PowerShell actualizado a 7.6.9. Digest del activo y hashes.sha256
  oficiales coinciden: 50d33c7494aaf82b987cfd4de3f232d04f91fdd4c0deeca8a669cced3e7cf8f9.
  Se conserva firma Microsoft y se rechaza downgrade en ambos instaladores. La
  lectura de versión tiene límite temporal; resultado instalado se lee de nuevo.

Fixtures: más de mil archivos y muestra de cinco, ocultos, exclusiones, acceso
denegado, censo omitido, continuidad entre fechas, carpeta FastCopy real simulada,
metadatos discordantes, dos aplicaciones en PATH, recursos ausentes, evidencia USB
alterada y timeout sin segundo instalador. Los procesos de instalación/descarga se
simulan; no se utiliza una memoria USB física para esta entrega.

No se invalidan las copias/restauración pequeñas ya aceptadas. No se instalan apps,
no se ejecutan benchmarks o VMs, ni se cambian protección, red o datos del host.
Windows 10 sigue sin homologación completa. CI del SHA exacto y comprobación
pública son condiciones de promoción; la evidencia final se conserva en el PR.

Validación local: 395 pruebas por runtime, cero fallos/omitidas y cero errores
del analizador. Guards, reproducción y carga WPF sin abrir ventana aprobados.
