# Install Runtimes Implementation Plan

> Histórico, sustituido: este diseño de mayo no es el contrato vigente ni un
> plan pendiente autorizado. Store registra paquetes existentes y respeta la
> edición/políticas; no hay cascada de descarga/instalación universal. Runtimes
> usa selección y comprobaciones de capacidades. Consultar [matriz actual](../../SUPPORT-MATRIX.md)
> y [trabajo/aceptación](../../TRABAJO-AUTONOMO-Y-ACEPTACION.md).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `Invoke-InstalarRuntimes` — a self-contained PowerShell tool that installs common Windows runtime dependencies (VC++ Redistributables, .NET 3.5, DirectX, XNA, OpenAL) in two modes: Minimum and Full/Gaming.

**Architecture:** Single `.ps1` file following the Atlas tool pattern (inner `_Atlas-DetectLang`, `$T` i18n hashtable with `en`/`es` blocks, `$L = $T[$lang]`). Mode menu at runtime selects package set. winget handles all packages except .NET 3.5 (DISM). Per-package skip detection before install. Non-fatal per-package failures; summary printed at end. Registered in `config/tools.json` under `software`.

**Tech Stack:** PowerShell 5.1+, winget CLI, DISM (`Enable-WindowsOptionalFeature`)

---

### Task 1: Create `Invoke-InstalarRuntimes.ps1` — full implementation

**Files:**
- Create: `src/tools/Invoke-InstalarRuntimes.ps1`

- [ ] **Step 1: Create the file with full implementation**

Write `src/tools/Invoke-InstalarRuntimes.ps1` with the exact content below:

```powershell
# ============================================================
# Invoke-InstalarRuntimes  ->  Install Runtime Dependencies
#
# Installs common Windows runtime packages in two modes:
#   Minimum  : VC++ 2015+ x64/x86, VC++ 2013 x64/x86, .NET 3.5, DirectX
#   Full/Gaming: Minimum + XNA Redistributable + OpenAL
#
# i18n: Option A (en default + full es secondary).
# Atlas PC Support
# ============================================================

function Invoke-InstalarRuntimes {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Continue'

    # --- Language detection ---
    function _Atlas-DetectLang {
        if ($env:ATLAS_LANG) { return [string]$env:ATLAS_LANG }
        try {
            $cfg = Join-Path $env:LOCALAPPDATA 'AtlasPC\config.json'
            if (Test-Path -LiteralPath $cfg) {
                $obj = Get-Content -Raw -LiteralPath $cfg -Encoding UTF8 | ConvertFrom-Json
                if ($obj.language) { return [string]$obj.language }
            }
        } catch {}
        $sys = (Get-Culture).TwoLetterISOLanguageName
        if ($sys -eq 'es') { return 'es' }
        return 'en'
    }

    $T = @{
        en = @{
            Title          = 'INSTALL RUNTIME DEPENDENCIES'
            Separator      = '============================================================'
            BuildLine      = '{0} (Build {1})'
            MenuHeader     = '  Select installation mode:'
            MenuOption1    = '  [1] PC Normal (Minimum)'
            MenuOption2    = '  [2] PC Games  (Full)'
            MenuQuit       = '  [Q] Exit'
            MenuPrompt     = 'Choice'
            InvalidChoice  = '  [!] Invalid choice. Enter 1, 2, or Q.'
            NeedAdmin      = '[!] Administrator privileges are required. Relaunch as admin.'
            WingetNotFound = '[!] winget not found. Install App Installer from the Microsoft Store first.'
            ManualSteps    = '  Manual alternative: use the Microsoft Store or Visual C++ download center.'
            Checking       = '  Checking {0}...'
            AlreadyInst    = '[{0}/{1}] {2} {3} [SKIP] Already installed'
            Installing     = '[{0}/{1}] {2} {3} Installing...'
            PkgOk          = '[{0}/{1}] {2} {3} [OK]'
            PkgFail        = '[{0}/{1}] {2} {3} [FAIL] {4}'
            SummaryHeader  = ''
            SummaryLine    = '  Summary: {0} installed, {1} skipped, {2} failed'
            EnterExit      = 'Press Enter to exit...'
        }
        es = @{
            Title          = 'INSTALAR DEPENDENCIAS DE RUNTIME'
            Separator      = '============================================================'
            BuildLine      = '{0} (Build {1})'
            MenuHeader     = '  Selecciona modo de instalacion:'
            MenuOption1    = '  [1] PC Normal (Minimo)'
            MenuOption2    = '  [2] PC Juegos (Completo)'
            MenuQuit       = '  [Q] Salir'
            MenuPrompt     = 'Opcion'
            InvalidChoice  = '  [!] Opcion invalida. Ingresa 1, 2 o Q.'
            NeedAdmin      = '[!] Se requieren privilegios de administrador. Relanza como admin.'
            WingetNotFound = '[!] winget no encontrado. Instala App Installer desde la Microsoft Store primero.'
            ManualSteps    = '  Alternativa manual: usa la Microsoft Store o el centro de descarga de Visual C++.'
            Checking       = '  Verificando {0}...'
            AlreadyInst    = '[{0}/{1}] {2} {3} [OMITIR] Ya instalado'
            Installing     = '[{0}/{1}] {2} {3} Instalando...'
            PkgOk          = '[{0}/{1}] {2} {3} [OK]'
            PkgFail        = '[{0}/{1}] {2} {3} [FALLO] {4}'
            SummaryHeader  = ''
            SummaryLine    = '  Resumen: {0} instalados, {1} omitidos, {2} fallidos'
            EnterExit      = 'Presiona Enter para salir...'
        }
    }

    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]

    # --- Console setup ---
    try { $Host.UI.RawUI.WindowTitle = $L.Title } catch {}
    try { $Host.UI.RawUI.BackgroundColor = 'Black'; $Host.UI.RawUI.ForegroundColor = 'Gray' } catch {}
    try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(80, 40) } catch {}
    Clear-Host

    # --- Admin check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host $L.NeedAdmin -ForegroundColor Red
        Read-Host $L.EnterExit
        return
    }

    # --- winget check ---
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Host $L.WingetNotFound -ForegroundColor Red
        Write-Host $L.ManualSteps -ForegroundColor Yellow
        Write-Host ''
        Read-Host $L.EnterExit
        return
    }

    # --- OS info ---
    $osInfo  = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $build   = [int]$osInfo.BuildNumber
    $caption = $osInfo.Caption

    # --- Header ---
    Write-Host ''
    Write-Host $L.Separator -ForegroundColor DarkGray
    Write-Host "   $($L.Title)" -ForegroundColor Yellow
    Write-Host "   $($L.BuildLine -f $caption, $build)" -ForegroundColor Gray
    Write-Host $L.Separator -ForegroundColor DarkGray
    Write-Host ''

    # --- Package definitions ---
    # Each entry: @{ Label; WingetId (or $null for DISM); IsDism }
    $pkgsMinimum = @(
        @{ Label = 'Microsoft.VCRedist.2015+.x64'; WingetId = 'Microsoft.VCRedist.2015+.x64'; IsDism = $false }
        @{ Label = 'Microsoft.VCRedist.2015+.x86'; WingetId = 'Microsoft.VCRedist.2015+.x86'; IsDism = $false }
        @{ Label = 'Microsoft.VCRedist.2013.x64';  WingetId = 'Microsoft.VCRedist.2013.x64';  IsDism = $false }
        @{ Label = 'Microsoft.VCRedist.2013.x86';  WingetId = 'Microsoft.VCRedist.2013.x86';  IsDism = $false }
        @{ Label = '.NET Framework 3.5 (DISM)';    WingetId = $null;                           IsDism = $true  }
        @{ Label = 'Microsoft.DirectX';            WingetId = 'Microsoft.DirectX';             IsDism = $false }
    )
    $pkgsGaming = $pkgsMinimum + @(
        @{ Label = 'Microsoft.XNARedist'; WingetId = 'Microsoft.XNARedist'; IsDism = $false }
        @{ Label = 'OpenAL.OpenAL';       WingetId = 'OpenAL.OpenAL';       IsDism = $false }
    )

    # --- Mode menu ---
    $selectedPkgs = $null
    while ($null -eq $selectedPkgs) {
        Write-Host $L.MenuHeader -ForegroundColor Cyan
        Write-Host $L.MenuOption1 -ForegroundColor White
        Write-Host $L.MenuOption2 -ForegroundColor White
        Write-Host $L.MenuQuit   -ForegroundColor DarkGray
        Write-Host ''
        $choice = (Read-Host $L.MenuPrompt).Trim().ToUpper()
        Write-Host ''
        switch ($choice) {
            '1' { $selectedPkgs = $pkgsMinimum }
            '2' { $selectedPkgs = $pkgsGaming  }
            'Q' { return }
            default {
                Write-Host $L.InvalidChoice -ForegroundColor Yellow
                Write-Host ''
            }
        }
    }

    $total   = $selectedPkgs.Count
    $cntOk   = 0
    $cntSkip = 0
    $cntFail = 0

    for ($i = 0; $i -lt $total; $i++) {
        $pkg   = $selectedPkgs[$i]
        $idx   = $i + 1
        $label = $pkg.Label
        $pad   = ' ' * [Math]::Max(0, 45 - $label.Length)

        if ($pkg.IsDism) {
            # --- .NET Framework 3.5 via DISM ---
            try {
                $feat = Get-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -ErrorAction Stop
                if ($feat.State -eq 'Enabled') {
                    Write-Host ($L.AlreadyInst -f $idx, $total, $label, $pad) -ForegroundColor DarkGray
                    $cntSkip++
                    continue
                }
            } catch {}

            Write-Host ($L.Installing -f $idx, $total, $label, $pad) -ForegroundColor Cyan -NoNewline
            try {
                $result = Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -NoRestart -ErrorAction Stop
                # RestartNeeded = True means exit 3010 equivalent — still success
                Write-Host ' [OK]' -ForegroundColor Green
                $cntOk++
            } catch {
                Write-Host (' [FAIL] ' + $_.Exception.Message) -ForegroundColor Red
                $cntFail++
            }
        } else {
            # --- winget package ---
            $alreadyInstalled = $false
            try {
                $listOut = & $winget.Source list --id $pkg.WingetId --exact --accept-source-agreements 2>&1
                if ($LASTEXITCODE -eq 0 -and ($listOut -match [regex]::Escape($pkg.WingetId))) {
                    $alreadyInstalled = $true
                }
            } catch {}

            if ($alreadyInstalled) {
                Write-Host ($L.AlreadyInst -f $idx, $total, $label, $pad) -ForegroundColor DarkGray
                $cntSkip++
                continue
            }

            Write-Host ($L.Installing -f $idx, $total, $label, $pad) -ForegroundColor Cyan
            $proc = Start-Process -FilePath $winget.Source `
                -ArgumentList 'install', '--id', $pkg.WingetId, '--exact',
                              '--accept-package-agreements', '--accept-source-agreements' `
                -Wait -PassThru -NoNewWindow

            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
                Write-Host ($L.PkgOk -f $idx, $total, $label, $pad) -ForegroundColor Green
                $cntOk++
            } else {
                Write-Host ($L.PkgFail -f $idx, $total, $label, $pad, $proc.ExitCode) -ForegroundColor Red
                $cntFail++
            }
        }
    }

    # --- Summary ---
    Write-Host ''
    Write-Host $L.Separator -ForegroundColor DarkGray
    $summaryColor = if ($cntFail -gt 0) { 'Yellow' } else { 'Green' }
    Write-Host ($L.SummaryLine -f $cntOk, $cntSkip, $cntFail) -ForegroundColor $summaryColor
    Write-Host $L.Separator -ForegroundColor DarkGray
    Write-Host ''
    Read-Host $L.EnterExit
}
```

- [ ] **Step 2: Verify file was created**

```
Test-Path "src/tools/Invoke-InstalarRuntimes.ps1"
```
Expected: True

- [ ] **Step 3: Syntax check**

```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path "src/tools/Invoke-InstalarRuntimes.ps1").Path,
    [ref]$null, [ref]$errors
)
$errors.Count
```
Expected: 0 parse errors

---

### Task 2: Register `instalar-runtimes` in `config/tools.json`

**Files:**
- Modify: `config/tools.json` (add new entry after `instalar-ms-store`)

- [ ] **Step 1: Add entry to tools.json**

Open `config/tools.json`. After the `instalar-ms-store` block (which ends at the closing `}`), add a comma and this new entry:

```json
    {
      "id": "instalar-runtimes",
      "name": "Install Runtime Dependencies",
      "description": "Installs common Windows runtime packages in bulk: VC++ 2015+ and 2013 (x64/x86), .NET Framework 3.5, DirectX, and optionally XNA and OpenAL for gaming. Two modes: Minimum and Full/Gaming.",
      "category": "software",
      "function": "Invoke-InstalarRuntimes",
      "source": "Invoke-InstalarRuntimes.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    }
```

Insert it between `instalar-ms-store` and `actualizar-powershell` (or at the end of the software tools, whichever keeps the JSON valid).

- [ ] **Step 2: Validate JSON**

```powershell
Get-Content -Raw "config/tools.json" | ConvertFrom-Json | Select-Object -ExpandProperty tools | Select-Object id | Where-Object id -eq 'instalar-runtimes'
```
Expected: one row with `id = instalar-runtimes`

---

### Task 3: Commit and push

- [ ] **Step 1: Stage and commit spec + plan + implementation**

```bash
git add docs/superpowers/specs/2026-05-12-instalar-runtimes-design.md \
        docs/superpowers/plans/2026-05-12-instalar-runtimes.md \
        src/tools/Invoke-InstalarRuntimes.ps1 \
        config/tools.json
git commit -m "feat: Install Runtime Dependencies tool (Minimum + Full/Gaming modes)"
```

- [ ] **Step 2: Push and open PR**

```bash
git push -u origin feat/instalar-runtimes
gh pr create --title "feat: Install Runtime Dependencies tool" \
  --body "Adds Invoke-InstalarRuntimes to the Software tab.

Two modes: Minimum (VC++ 2015+/2013 x64/x86, .NET 3.5, DirectX) and Full/Gaming (adds XNA + OpenAL).

- Skip detection before each package (winget list + DISM feature check)
- Non-fatal per-package failures with summary at end
- Full en/es i18n

Registered in config/tools.json as instalar-runtimes."
```
