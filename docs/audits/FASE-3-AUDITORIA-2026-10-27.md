# Fase 3: operaciones verificables — 1.5.15

Implementa A04, A09 y A11 del informe integral. Mantiene las 27 herramientas,
el enlace actual y Windows PowerShell 5.1. No cambia políticas del PC de trabajo.

- Cuentas: lectura local independiente del idioma con NetUserModalsGet, rangos
  comprobados antes de escribir, rechazo de cambios de política en equipos de
  dominio y snapshot previo. Cada ejecución de net.exe tiene límite temporal,
  comprueba salida y lectura posterior. Un fallo parcial detiene los pasos
  restantes y muestra cuántos se verificaron y dónde están los valores previos.
  Cero días de expiración se traduce a UNLIMITED; no se impone un preset universal.
  Administradores locales identificados por SID también en las vistas/informes.
- UAC: el preset exige APPLY UAC, guarda los cuatro valores originales y su
  presencia/tipo antes de escribir y comprueba el resultado. La opción 9 permite
  restaurar solo esos valores en el mismo equipo, con confirmación explícita y
  advertencia de posible reducción de protección/reinicio. Se corrige el texto:
  Admin=2 solicita consentimiento en escritorio seguro, no credenciales.
- Drivers: carpeta nueva por intento dentro del destino elegido. Un exportador
  iniciado que falle deja el intento parcial y no dispara otro exportador.
  Manifiesto v2 con ruta normalizada, tamaño y SHA-256 de todos los miembros,
  incluidos CAT/SYS/DLL; lectura posterior verifica el árbol completo. Un fallo
  del manifiesto impide anunciar éxito. Exportación verificada no equivale a
  restauración ensayada ni certifica firmas/licencias de cada controlador.
- DNS: valida direcciones/familias, duplicados, todos los adaptadores y sus filas
  antes de la primera escritura. Los fallos posteriores informan progreso y fila
  afectada. No se promete atomicidad: Windows puede cambiar durante la operación.
- Hosts: bloque administrado reemplazable, fuente HTTPS, fecha y digest del texto
  normalizado observado; validación de entradas de bloqueo y desduplicación.
  Reaplicar la misma lista no añade otra copia. Conserva aliases personales fuera
  del bloque; un antiguo apéndice sin límites exige restaurar su backup, sin
  adivinar qué entradas eran personales. Restauración de backup byte por byte.
  Backups/exportaciones que se anuncian correctos usan errores terminantes.

Las regresiones usan políticas, registro, exportadores y adaptadores simulados,
y archivos propios de TestDrive. Se comprueban rechazo antes de mutaciones,
salida nativa fallida, verificación discordante, cambio parcial, UAC ausente,
CAT alterado sin cambiar tamaño, ruta relativa, lista inválida, doble aplicación,
restauración de bytes y adaptador/familia inválidos. La lectura NetUserModalsGet
se comprueba además sin escribir ni mostrar valores del host.

Las suites completas 5.1/7 y CI del SHA exacto son requisitos de promoción.
La evidencia de publicación se conserva en el PR. No se ejecutan net accounts
de escritura, cambios UAC, exportación/reinstalación real de drivers ni cambios
DNS/hosts sobre el host durante esta entrega.

Quedan pruebas físicas/destructivas en entorno desechable. Windows 10 sigue sin
homologación completa; VMs pausadas. No se modifican Defender, grupos o discos
físicos. Las fases 4 y 5 se entregan por separado.

Fuentes del contrato:
[NetUserModalsGet](https://learn.microsoft.com/en-us/windows/win32/api/lmaccess/nf-lmaccess-netusermodalsget),
[parámetros de contraseña](https://learn.microsoft.com/en-us/windows/win32/api/lmaccess/ns-lmaccess-user_modals_info_0),
[bloqueo](https://learn.microsoft.com/en-us/windows/win32/api/lmaccess/ns-lmaccess-user_modals_info_3),
[UAC](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/settings-and-configuration?tabs=reg),
[lista StevenBlack](https://github.com/StevenBlack/hosts).
