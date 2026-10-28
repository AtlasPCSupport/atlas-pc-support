# Install Microsoft Store — Design Spec

> Histórico, sustituido: este diseño de mayo no es el contrato vigente ni un
> plan pendiente autorizado. Store registra paquetes existentes y respeta la
> edición/políticas; no hay cascada de descarga/instalación universal. Runtimes
> usa selección y comprobaciones de capacidades. Consultar [matriz actual](../../SUPPORT-MATRIX.md)
> y [trabajo/aceptación](../../TRABAJO-AUTONOMO-Y-ACEPTACION.md).

## Goal

Add a new tool `Invoke-InstalarMicrosoftStore` to the **Software** tab that installs the Microsoft Store on systems where it is absent by default (Windows 10/11 IoT Enterprise LTSC, corporate images, etc.).

## Architecture

Single self-contained PowerShell tool following the existing Atlas tool pattern (own i18n block, `_Atlas-DetectLang`, no shared launcher dependencies). Registered in `config/tools.json` under category `software`. Requires admin.

## Execution Flow — 3-method cascade

```
[1] Detection
    └─ Get-AppxPackage Microsoft.WindowsStore
    └─ If present → inform user, exit gracefully

[2] wsreset -i  (official Microsoft method, W11 22000+)
    └─ Start-Process wsreset -ArgumentList '-i' -Wait -WindowStyle Hidden
    └─ Wait up to 90 s polling Get-AppxPackage every 5 s
    └─ On success → done
    └─ On timeout/fail → fall through to [3]

[3] Appx bundle install from Microsoft CDN
    Dependencies installed in order:
      a. VCLibs x64 14.00 Desktop
         URL: https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
      b. Microsoft.UI.Xaml 2.8 x64
         URL: https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx
      c. Microsoft WindowsStore bundle
         URL: resolved at runtime from current-version API or hardcoded stable URL
         Stable fallback: https://storeedgefd.dsx.mp.microsoft.com/v9.0/packageManifests/9wzdncrfjbmp
         (tool resolves download URL via winget REST or uses direct appxbundle link)
    Each file:
      - Check offline USB cache first: $env:ATLAS_OFFLINE_ROOT\deps\MicrosoftStore\
      - Check local cache: $env:LOCALAPPDATA\AtlasPC\bin\MicrosoftStore\
      - Download to local cache if not found
    Install: Add-AppxPackage -Path $file -ForceApplicationShutdown -ErrorAction Stop
    On failure → print manual steps, exit with error
```

## Offline USB support

`Invoke-PrepararUSB` gets a new optional step: download the 3 bundle files to `deps\MicrosoftStore\` on the USB. The tool detects this folder via `$env:ATLAS_OFFLINE_ROOT` (set by `run-launcher.ps1`). Estimated download: ~55 MB total.

## Windows version detection

```powershell
$build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
$isW11  = $build -ge 22000
$isLTSC = (Get-CimInstance Win32_OperatingSystem).Caption -match 'LTSC|IoT'
```

- W11 non-LTSC (build ≥ 22000): try wsreset first, then bundle
- W10/W11 LTSC or IoT: skip wsreset (known to fail), go directly to bundle
- Already installed: detect and exit with info message

## i18n

Two language blocks (`en` / `es`) inside the tool. Language detected via `_Atlas-DetectLang` (same pattern as all other tools).

Key strings: title, detection result, each step label, progress lines, success/failure messages, manual-steps fallback text.

## Output format (console)

```
============================================================
   INSTALL MICROSOFT STORE
   Windows 11 IoT Enterprise LTSC (Build 26100)
============================================================

[1/3] Checking current Store status...
  [!] Microsoft Store not found on this system.

[2/3] Skipping wsreset -i (LTSC/IoT detected — not reliable).

[3/3] Downloading Store bundle from Microsoft CDN...
  [>] VCLibs.x64.14.00.Desktop.appx  (~6 MB)... [OK]
  [>] Microsoft.UI.Xaml.2.8.x64.appx (~17 MB)... [OK]
  [>] Microsoft.WindowsStore bundle  (~28 MB)... [OK]
  Installing packages...
  [OK] Microsoft Store installed successfully.

Press Enter to exit...
```

## Error handling

- Network failure during download: show which package failed, suggest USB offline method
- Add-AppxPackage failure: show exact error + manual steps (Settings > Apps > Optional features, or DISM)
- Already installed: green message, no action taken
- Partial install (deps OK, store fails): leave deps in place (they are valid system components)

## Files changed

| File | Change |
|---|---|
| `src/tools/Invoke-InstalarMicrosoftStore.ps1` | New |
| `config/tools.json` | New entry: id `instalar-ms-store`, category `software` |
| `src/tools/Invoke-PrepararUSB.ps1` | New optional step: download Store bundle to `deps\MicrosoftStore\` on USB |
| `src/tools/Invoke-InstalarPaquetes.ps1` | Fix WhatsApp entry: `WhatsApp.WhatsApp` → `9NKSQGP7F2NH` (msstore source) |

## Out of scope

- Installing apps from the Store (that is winget's job)
- Modifying Group Policy or registry
- Reboot orchestration
- Windows Server support
