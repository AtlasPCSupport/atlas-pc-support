# Install Runtimes — Design Spec

> Histórico, sustituido: este diseño de mayo no es el contrato vigente ni un
> plan pendiente autorizado. Store registra paquetes existentes y respeta la
> edición/políticas; no hay cascada de descarga/instalación universal. Runtimes
> usa selección y comprobaciones de capacidades. Consultar [matriz actual](../../SUPPORT-MATRIX.md)
> y [trabajo/aceptación](../../TRABAJO-AUTONOMO-Y-ACEPTACION.md).

## Goal

Add a new tool `Invoke-InstalarRuntimes` to the **Software** tab that installs the most common Windows runtime dependencies in bulk — Visual C++ Redistributables, .NET Framework 3.5, DirectX, and gaming-specific packages.

## Architecture

Single self-contained PowerShell tool following the existing Atlas tool pattern (own i18n block, `_Atlas-DetectLang`, no shared launcher dependencies). Registered in `config/tools.json` under category `software`. Does not require admin at launch but elevation is requested if not already admin.

## Modes

| Mode | Label | Packages |
|------|-------|---------|
| 1 | PC Normal (Minimum) | VCRedist 2015+ x64, VCRedist 2015+ x86, VCRedist 2013 x64, VCRedist 2013 x86, .NET Framework 3.5, DirectX |
| 2 | PC Games (Full) | All of Minimum + XNA Framework Redistributable + OpenAL |

User sees a menu `[1] PC Normal (Minimum)  [2] PC Games (Full)  [Q] Salir/Exit` and picks once. Tool then installs all packages for the chosen mode.

## Package List

### Minimum set (6 packages)

| # | winget ID | Note |
|---|-----------|------|
| 1 | `Microsoft.VCRedist.2015+.x64` | winget |
| 2 | `Microsoft.VCRedist.2015+.x86` | winget |
| 3 | `Microsoft.VCRedist.2013.x64` | winget |
| 4 | `Microsoft.VCRedist.2013.x86` | winget |
| 5 | *(DISM)* | .NET Framework 3.5 via `Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -NoRestart` |
| 6 | `Microsoft.DirectX` | winget |

### Full/Gaming additions (2 more packages)

| # | winget ID | Note |
|---|-----------|------|
| 7 | `Microsoft.XNARedist` | winget |
| 8 | `OpenAL.OpenAL` | winget |

## Skip Detection

- **winget packages**: run `winget list --id <id> --exact --accept-source-agreements` — if exit code 0 and output contains the ID, skip with `[SKIP]` message.
- **.NET Framework 3.5**: `(Get-WindowsOptionalFeature -Online -FeatureName NetFx3).State -eq 'Enabled'` → skip.

## Install Commands

- **winget packages**: `winget install --id <id> --exact --accept-package-agreements --accept-source-agreements`
  - Uses `Start-Process -FilePath $winget.Source -ArgumentList ... -Wait -PassThru -NoNewWindow` to capture exit code while showing native progress.
  - Accepted exit codes: `0` (OK) and `-1978335189` (already installed, treated as skip).
- **.NET Framework 3.5**: `Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -NoRestart`
  - Exit code `3010` (reboot pending) treated as success.

## Error Handling

- Each package failure is non-fatal: log `[FAIL]` with error message, continue to next package.
- After all packages: print a summary table showing OK / SKIP / FAIL per package.
- If winget is not available: print error, show manual instructions, exit.
- Admin check: if not admin, print warning and offer to relaunch as admin via `Start-Process pwsh -Verb RunAs -ArgumentList ...`.

## Output Format (console)

```
============================================================
   INSTALL RUNTIME DEPENDENCIES
   Windows 11 IoT Enterprise LTSC (Build 26100)
============================================================

  [1] PC Normal (Minimum)
  [2] PC Games (Full)
  [Q] Exit

  Choice: 2

[1/8] Microsoft.VCRedist.2015+.x64 .......................... [OK]
[2/8] Microsoft.VCRedist.2015+.x86 .......................... [OK]
[3/8] Microsoft.VCRedist.2013.x64 ........................... [SKIP] Already installed
[4/8] Microsoft.VCRedist.2013.x86 ........................... [OK]
[5/8] .NET Framework 3.5 (DISM) ............................. [OK]
[6/8] Microsoft.DirectX ..................................... [OK]
[7/8] Microsoft.XNARedist .................................... [OK]
[8/8] OpenAL.OpenAL .......................................... [OK]

============================================================
  Summary: 7 installed, 1 skipped, 0 failed
============================================================

Press Enter to exit...
```

## i18n

Two language blocks (`en` / `es`). Language detected via `_Atlas-DetectLang`.

Key strings: Title, Separator, MenuHeader, MenuOption1, MenuOption2, MenuQuit, MenuPrompt, InvalidChoice, NeedAdmin, CheckingPkg, Installing, AlreadyInstalled, InstallOk, InstallFail, InstallSkip, DismLabel, SummaryHeader, SummaryLine, WingetNotFound, ManualSteps, ManualStep1, EnterExit.

## Files Changed

| File | Change |
|------|--------|
| `src/tools/Invoke-InstalarRuntimes.ps1` | New |
| `config/tools.json` | New entry: id `instalar-runtimes`, category `software` |
