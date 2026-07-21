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
            AlreadyInst    = '[{0}/{1}] {2} [SKIP] Already installed'
            Installing     = '[{0}/{1}] {2} Installing...'
            PkgOk          = '[{0}/{1}] {2} [OK]'
            PkgFail        = '[{0}/{1}] {2} [FAIL] exit {3}'
            DismFail       = '[{0}/{1}] {2} [FAIL] {3}'
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
            AlreadyInst    = '[{0}/{1}] {2} [OMITIR] Ya instalado'
            Installing     = '[{0}/{1}] {2} Instalando...'
            PkgOk          = '[{0}/{1}] {2} [OK]'
            PkgFail        = '[{0}/{1}] {2} [FALLO] codigo {3}'
            DismFail       = '[{0}/{1}] {2} [FALLO] {3}'
            SummaryLine    = '  Resumen: {0} instalados, {1} omitidos, {2} fallidos'
            EnterExit      = 'Presiona Enter para salir...'
        }
    }

    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    function Wait-InstalarRuntimesCompat {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

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
        Wait-InstalarRuntimesCompat -Message $L.EnterExit
        return
    }

    # --- winget check ---
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Host $L.WingetNotFound -ForegroundColor Red
        Write-Host $L.ManualSteps -ForegroundColor Yellow
        Write-Host ''
        Wait-InstalarRuntimesCompat -Message $L.EnterExit
        return
    }

    # --- OS info ---
    $osInfo  = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $build   = [int]$osInfo.BuildNumber
    $caption = $osInfo.Caption

    # --- Header ---
    Write-Host ''
    if ($atlasToolkitReady) {
        Write-AtlasHeader -Title $L.Title -Color Yellow
        Write-AtlasStep ($L.BuildLine -f $caption, $build)
        Write-Host ''
    } else {
        Write-Host $L.Separator -ForegroundColor DarkGray
        Write-Host "   $($L.Title)" -ForegroundColor Yellow
        Write-Host "   $($L.BuildLine -f $caption, $build)" -ForegroundColor Gray
        Write-Host $L.Separator -ForegroundColor DarkGray
        Write-Host ''
    }

    # --- Package definitions ---
    # IsDism=$true entries use Enable-WindowsOptionalFeature instead of winget
    $pkgsMinimum = @(
        [ordered]@{ Label = 'Microsoft.VCRedist.2015+.x64'; WingetId = 'Microsoft.VCRedist.2015+.x64'; IsDism = $false }
        [ordered]@{ Label = 'Microsoft.VCRedist.2015+.x86'; WingetId = 'Microsoft.VCRedist.2015+.x86'; IsDism = $false }
        [ordered]@{ Label = 'Microsoft.VCRedist.2013.x64';  WingetId = 'Microsoft.VCRedist.2013.x64';  IsDism = $false }
        [ordered]@{ Label = 'Microsoft.VCRedist.2013.x86';  WingetId = 'Microsoft.VCRedist.2013.x86';  IsDism = $false }
        [ordered]@{ Label = '.NET Framework 3.5 (DISM)';    WingetId = $null;                          IsDism = $true  }
        [ordered]@{ Label = 'Microsoft.DirectX';            WingetId = 'Microsoft.DirectX';            IsDism = $false }
    )
    $pkgsGaming = $pkgsMinimum + @(
        [ordered]@{ Label = 'Microsoft.XNARedist'; WingetId = 'Microsoft.XNARedist'; IsDism = $false }
        [ordered]@{ Label = 'OpenAL.OpenAL';       WingetId = 'OpenAL.OpenAL';       IsDism = $false }
    )

    # --- Mode menu ---
    $selectedPkgs = $null
    while ($null -eq $selectedPkgs) {
        Write-Host $L.MenuHeader -ForegroundColor Cyan
        Write-Host $L.MenuOption1 -ForegroundColor White
        Write-Host $L.MenuOption2 -ForegroundColor White
        Write-Host $L.MenuQuit    -ForegroundColor DarkGray
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

        if ($pkg.IsDism) {
            # --- .NET Framework 3.5 via DISM ---
            $isEnabled = $false
            try {
                $feat = Get-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -ErrorAction Stop
                $isEnabled = ($feat.State -eq 'Enabled')
            } catch {}

            if ($isEnabled) {
                Write-Host ($L.AlreadyInst -f $idx, $total, $label) -ForegroundColor DarkGray
                $cntSkip++
                continue
            }

            Write-Host ($L.Installing -f $idx, $total, $label) -ForegroundColor Cyan
            try {
                Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -NoRestart -ErrorAction Stop | Out-Null
                Write-Host ($L.PkgOk -f $idx, $total, $label) -ForegroundColor Green
                $cntOk++
            } catch {
                Write-Host ($L.DismFail -f $idx, $total, $label, $_.Exception.Message) -ForegroundColor Red
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
                Write-Host ($L.AlreadyInst -f $idx, $total, $label) -ForegroundColor DarkGray
                $cntSkip++
                continue
            }

            Write-Host ($L.Installing -f $idx, $total, $label) -ForegroundColor Cyan
            $proc = Start-Process -FilePath $winget.Source `
                -ArgumentList 'install', '--id', $pkg.WingetId, '--exact',
                              '--accept-package-agreements', '--accept-source-agreements' `
                -Wait -PassThru -NoNewWindow

            # -1978335189 = WINGET_ERROR_ALREADY_INSTALLED
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
                Write-Host ($L.PkgOk -f $idx, $total, $label) -ForegroundColor Green
                $cntOk++
            } else {
                Write-Host ($L.PkgFail -f $idx, $total, $label, $proc.ExitCode) -ForegroundColor Red
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
    Wait-InstalarRuntimesCompat -Message $L.EnterExit
}
