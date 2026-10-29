# Compatibilidad y homologación

Estado del ciclo 1.5.13–1.5.19, 29 de octubre de 2026. «Objetivo» describe el contrato del
código, no una prueba ejecutada en ese sistema. La compatibilidad de Atlas tampoco
extiende el ciclo de soporte de Microsoft ni sustituye la licencia de Windows.

| Plataforma | Contrato de Atlas | Evidencia disponible | QA pendiente |
|---|---|---|---|
| Windows 10 22H2 Home x64, 19045 | Objetivo; funciones según capacidades | Fixtures de build/edición y casos negativos | VM, UAC, panel, Store/WinGet, red y copias |
| Windows 10 22H2 Pro x64, 19045 | Objetivo; BitLocker depende de módulos y política | Fixtures y regresiones aisladas | Lo anterior + TPM, reinicio y recuperación desde otro disco |
| Enterprise LTSC 2021 x64, EnterpriseS 19044 | Objetivo sin presuponer Store | Fixtures LTSC; instalación de laboratorio observada, sin aceptación completa | VM, App Installer/NetFx3 matching, operación/restauración real |
| IoT Enterprise LTSC 2021 x64, IoTEnterpriseS 19044 | Objetivo independiente de EnterpriseS | Fixtures; medios de laboratorio pendientes | Medio/licencia apropiados, VM y matriz independiente |
| Cliente Windows 11 x64 | Objetivo según capacidades | Host real 26100: PS5/PS7, WPF, entrada online/offline | Equipos y políticas adicionales; hardware real |
| Server, x86, ARM64, build <19044 | No admitido por este contrato | Fixtures de rechazo | No se promociona como compatible |

Todas las herramientas declaran Windows PowerShell 5.1 x64 como runtime. PowerShell
7 se puede instalar con validación, pero no se selecciona como sustituto universal.
CI `windows-latest` comprueba WPF y PowerShell 5.1; no es un runner Windows 10.
El ensayo Home previo y sus resultados parciales no liberan esta matriz. Las VMs
siguen pausadas por decisión del propietario.

## Diferencias visibles

- DNS clásico está disponible en Windows 10. El acceso a ajustes DoH exige Windows
  11 y comandos pertinentes; una clave de registro no demuestra tráfico cifrado.
- Home/Device Encryption no se equipara a administración BitLocker completa.
- Store se comprueba en el usuario correcto. Solo se registra un paquete existente;
  no se fuerza Store en LTSC ni se eluden políticas. App Installer es independiente.
- El catálogo WinGet valida IDs/fuentes, pero el mínimo OS y la disponibilidad final
  de cada aplicación dependen de su manifiesto vigente y se deben comprobar en VM.
  La [instantánea del catálogo](audits/CATALOGO-2026-10-25.json) registra versiones,
  arquitecturas, mínimos declarados y fuentes inmutables; ausencia de mínimo queda
  como no verificada. La presencia de una app x86 no la excluye de Windows x64.
- Las tarjetas no disponibles explican el motivo antes de ejecutar; el proceso hijo
  repite la comprobación, incluida la identidad posterior a UAC.

## Alcance restringido

- Deduplicador/conversor: backend ausente, tarjeta deshabilitada.
- FastCopy: mover/sincronizar restringido; la muestra SHA-256 se identifica como
  parcial. Respaldo fijado a 5.12.0 con hash comprobado; requiere licencia laboral
  del fabricante. Robocopy es alternativa nativa. Se rechazan rutas redirigidas y
  enlaces no evaluados no producen un resultado de muestra verificada.
- Fase 0: inspección; presets de hardening/reset sin snapshot restringidos.
- Servicios: lista acotada, un servicio por operación y dependientes protegidos.
- Personalización: ajustes nativos, sin presets de registro ni marca de agua.
- Router: escaneo heredado solo /24; la prueba desde LAN no certifica exposición WAN.
- Tareas DNS: no se crean nuevas tareas de reaplicación; revisar manualmente las
  antiguas `AtlasDNSSelector` antes de retirarlas desde Windows.
- IA, GPU, eventos y hardware: observaciones con cobertura limitada, nunca una
  garantía de salud, capacidad para un modelo o compatibilidad de una ampliación.

Para liberar una celda pendiente, registrar imagen/build/edición, runtime, identidad
antes/después de UAC, SHA probado, escenario, resultado y evidencia. No copiar claves
de recuperación ni datos del cliente a issues, PRs o este repositorio.
