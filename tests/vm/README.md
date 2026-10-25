# Laboratorio Windows 10

`Invoke-Win10Lab.ps1` se ejecuta desde **Windows PowerShell 5.1 elevado mediante
UAC**. No necesita agregar la cuenta a grupos ni reiniciar Codex como administrador.
Usa Hyper-V existente y su Default Switch. Requiere Pester 5.8.0/PSScriptAnalyzer
1.25.0 ya disponibles, 85 GB libres y al menos 3 GB de RAM libres antes de cada VM.
Cada VM usa dos CPU virtuales, 2 GB de RAM mínima/inicial y un máximo dinámico
de 3 GB. Se evita reducir Windows x64 a 1 GB después del arranque.
`LTSC` selecciona **Enterprise LTSC 2021 / EnterpriseS**, incluida en la ISO
indicada en el ejemplo. IoT Enterprise LTSC queda como caso independiente: la
imagen base de 2021 no acepta el selector KMS IoT que exige 19044.2905 o posterior
según [Microsoft](https://learn.microsoft.com/en-us/windows/iot/iot-enterprise/deployment/volume-license).

Ejemplo, desde la raíz del repositorio, en una consola elevada:

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tests\vm\Invoke-Win10Lab.ps1 `
  -Windows10Iso "$env:USERPROFILE\Desktop\Win10_22H2_Spanish_Mexico_x64v1.iso" `
  -LtscIso "$env:USERPROFILE\Desktop\en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso" `
  -LabRoot D:\Atlas-QA-Win10-run01 `
  -TestModuleRoot "$env:USERPROFILE\Documents\PowerShell\Modules"
```

La carpeta debe ser nueva y llamarse `Atlas-QA-Win10-*`. `-Profiles Home`, `Pro` o
`LTSC` permite una ejecución individual. El script conserva VMs/discos y snapshots;
no tiene borrado recursivo automático. Una sola VM está encendida por vez.

El host no recibe formateos, nuevas cuentas/grupos, exclusiones de Defender,
puentes de red, cambios permanentes de ExecutionPolicy o activadores. Windows
Setup dentro de la VM recibe un único VHDX nuevo de 64 GB; nunca un disco físico.
Secure Boot y vTPM se mantienen habilitados. Las ISOs originales no se modifican:
se registra su hash y se comprueba la firma Microsoft de setup.exe, sin afirmar
que eso autentique independientemente cada byte de la ISO local.

La plantilla utiliza selectores de edición públicos para Windows Setup. La
[selección de edición no activa Windows](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/work-with-product-keys-and-activation-auth-phases).
No usa claves personales/OEM del host ni instala una clave de activación en
`Microsoft-Windows-Shell-Setup`. Los derechos de uso de cada Windows siguen siendo
responsabilidad del propietario; el resultado registra el estado de activación
observado. No publicar medios de instalación ni contraseñas del laboratorio.

Se crea AtlasLab con contraseña aleatoria para cada VM, autologon de laboratorio
y credencial DPAPI para PowerShell Direct. XML e ISO de respuesta se guardan en
`private/` con ACL de Administradores/SYSTEM y lectura del medio solo para su VM.
No son artefactos de publicación y nunca se deben agregar a Git.
El autologon nuevo contempla tres inicios para los reinicios de Setup. Los módulos
de pruebas se comprimen sin pérdida, se verifica el SHA-256 recibido y se expanden
en la VM. Se rechazan módulos con Zone.Identifier: el laboratorio no elimina la
marca. Una prueba con los módulos reales comparó los 69 archivos después de
expandirlos; 286,6 MiB se transportan como 14,3 MiB.

La tarea interactiva del invitado comprueba build/edición/modelo, Defender,
regresiones de la suite y WPF, capacidades/Store, entrada online/offline verificada,
visibilidad y cierre del panel, sin pulsar herramientas ni ejecutar reparaciones.
`results-<perfil>-<intento>/summary.json`, logs y panel.png contienen evidencia real;
`status.json` indica el directorio del intento. Las primeras ejecuciones del
controlador usaban `results-<perfil>`. El
campo `Windows10SuiteExecuted` no equivale a `FullWindows10Qualification`: faltan
operaciones sensibles, hardware/USB y homologación por aplicación.

Los timeouts y fallos quedan registrados, sin transformar una instalación o
prueba fallida en éxito. `status.json` permite seguir la ejecución. Un fallo de
instalación conserva la VM para inspección; corregir la plantilla antes de repetir
en otra carpeta, evitando reutilizar datos parciales como si fueran una base limpia.

Si se interrumpe el controlador, `Resume-Win10Lab.ps1 -LabRoot <carpeta> -VMId
<guid> -TestModuleRoot <módulos>` retoma una VM específica del laboratorio.
Comprueba nombre/ID, carpeta, único disco virtual y publicación antes de usar la
credencial DPAPI ya existente. No reconstruye el disco ni reanuda un conjunto
arbitrario de VMs. Una matriz debe haber terminado antes de repetir uno de sus
perfiles y se rechaza arrancar mientras otra VM Atlas está encendida. Se conservan
el estado anterior y los resultados de intentos anteriores. La copia y el inicio
de pruebas esperan a OOBE completo y Explorer; la mera existencia de NTUSER.DAT
durante Setup no demuestra que el escritorio esté listo. Registrar las
interrupciones junto al resultado de la prueba.
