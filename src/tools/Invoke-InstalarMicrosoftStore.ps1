# ============================================================
# Invoke-InstalarMicrosoftStore  ->  Install Microsoft Store
#
# Installs the Microsoft Store on systems where it is absent
# (Windows 10/11 IoT Enterprise LTSC, corporate images, etc.)
# Uses a 3-method cascade:
#   1. Detect (already installed -> done)
#   2. wsreset -i  (official method, W11 22000+ non-LTSC only)
#   3. winget install --source msstore (works on all builds, needs internet)
#
# i18n: Option A (en default + full es secondary).
# Atlas PC Support
# ============================================================

function Invoke-InstalarMicrosoftStore {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Continue'

    # --- Language detection (env var -> config.json -> system culture -> en) ---
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
            Title           = 'INSTALL MICROSOFT STORE'
            Separator       = '============================================================'
            CheckingStore   = '[1/3] Checking current Store status...'
            AlreadyInstalled= '  [OK] Microsoft Store is already installed ({0}). No action needed.'
            NotFound        = '  [!] Microsoft Store not found on this system.'
            SkipWsreset     = '[2/3] Skipping wsreset -i (LTSC/IoT build detected -- not reliable).'
            SkipWsresetOnline = '[2/3] Skipping wsreset -i (online fallback mode enabled).'
            OnlineFallback  = '  [i] Offline Store bundle unavailable on this USB. Using automatic online install (winget).'
            TryWsreset      = '[2/3] Trying wsreset -i (official Microsoft method)...'
            WsresetWait     = '  [i] Waiting up to 90 s for Store to appear...'
            WsresetOk       = '  [OK] Microsoft Store installed via wsreset.'
            WsresetFail     = '  [!] wsreset did not install the Store. Trying winget method.'
            WingetHeader    = '[3/3] Installing Microsoft Store via winget (msstore source)...'
            WingetInstalling= '  [>] Running: winget install 9WZDNCRFJBMP --source msstore'
            WingetOk        = '  [OK] Microsoft Store installed successfully.'
            WingetFail      = '  [X] winget install failed (exit code {0}).'
            WingetNotFound  = '[3/3] winget not found on this system.'
            InstallOk       = '  [OK] Microsoft Store installed successfully.'
            ManualSteps     = '  Manual alternative:'
            ManualStep1     = '    Run as admin: winget install 9WZDNCRFJBMP --source msstore --accept-package-agreements'
            ManualStep2     = '    Or: wsreset -i  (on supported Windows 11 non-LTSC builds)'
            ManualStep3     = '    Or: Settings > Apps > Optional features > Add a feature > "Microsoft Store"'
            NeedAdmin       = '[!] Administrator privileges are required. Relaunch as admin.'
            EnterExit       = 'Press Enter to exit...'
        }
        es = @{
            Title           = 'INSTALAR MICROSOFT STORE'
            Separator       = '============================================================'
            CheckingStore   = '[1/3] Verificando estado de la Store...'
            AlreadyInstalled= '  [OK] Microsoft Store ya esta instalada ({0}). No se requiere accion.'
            NotFound        = '  [!] Microsoft Store no encontrada en este sistema.'
            SkipWsreset     = '[2/3] Omitiendo wsreset -i (build LTSC/IoT detectado -- no es confiable).'
            SkipWsresetOnline = '[2/3] Omitiendo wsreset -i (modo fallback online activado).'
            OnlineFallback  = '  [i] Bundle offline no disponible en esta USB. Usando instalacion online automatica (winget).'
            TryWsreset      = '[2/3] Intentando wsreset -i (metodo oficial de Microsoft)...'
            WsresetWait     = '  [i] Esperando hasta 90 s para que aparezca la Store...'
            WsresetOk       = '  [OK] Microsoft Store instalada via wsreset.'
            WsresetFail     = '  [!] wsreset no instalo la Store. Intentando metodo winget.'
            WingetHeader    = '[3/3] Instalando Microsoft Store via winget (fuente msstore)...'
            WingetInstalling= '  [>] Ejecutando: winget install 9WZDNCRFJBMP --source msstore'
            WingetOk        = '  [OK] Microsoft Store instalada correctamente.'
            WingetFail      = '  [X] winget install fallo (codigo de salida {0}).'
            WingetNotFound  = '[3/3] winget no encontrado en este sistema.'
            InstallOk       = '  [OK] Microsoft Store instalada correctamente.'
            ManualSteps     = '  Alternativa manual:'
            ManualStep1     = '    Ejecutar como admin: winget install 9WZDNCRFJBMP --source msstore --accept-package-agreements'
            ManualStep2     = '    O: wsreset -i  (en builds Windows 11 no-LTSC compatibles)'
            ManualStep3     = '    O: Configuracion > Aplicaciones > Caracteristicas opcionales > "Microsoft Store"'
            NeedAdmin       = '[!] Se requieren privilegios de administrador. Relanza como admin.'
            EnterExit       = 'Presiona Enter para salir...'
        }
    }

    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    function Wait-StoreCompat {
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
    try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(80, 35) } catch {}
    Clear-Host

    # --- Admin check ---
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host $L.NeedAdmin -ForegroundColor Red
        Wait-StoreCompat -Message $L.EnterExit
        return
    }

    # --- OS / build detection ---
    $osInfo  = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $build   = [int]$osInfo.BuildNumber
    $caption = $osInfo.Caption
    $isW11   = $build -ge 22000
    $isLTSC  = $caption -match 'LTSC|IoT'

    # --- Header ---
    Write-Host ''
    if ($atlasToolkitReady) {
        Write-AtlasHeader -Title $L.Title -Color Yellow
        Write-AtlasStep ("{0} (Build {1})" -f $caption, $build)
        Write-Host ''
    } else {
        Write-Host $L.Separator -ForegroundColor DarkGray
        Write-Host "   $($L.Title)" -ForegroundColor Yellow
        Write-Host "   $caption (Build $build)" -ForegroundColor Gray
        Write-Host $L.Separator -ForegroundColor DarkGray
        Write-Host ''
    }

    # --- Step 1: Detect ---
    Write-Host $L.CheckingStore -ForegroundColor Cyan
    $storeApp = Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue
    if ($storeApp) {
        Write-Host ($L.AlreadyInstalled -f $storeApp.Version) -ForegroundColor Green
        Write-Host ''
        Wait-StoreCompat -Message $L.EnterExit
        return
    }
    Write-Host $L.NotFound -ForegroundColor Yellow
    Write-Host ''

    # If the USB prep tool marked Store bundle as unavailable, jump directly
    # to online install path (winget) without waiting on wsreset probes.
    $forceOnlineMode = $false
    if (-not [string]::IsNullOrWhiteSpace([string]$env:ATLAS_OFFLINE_ROOT)) {
        $onlineFlag = Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\MicrosoftStore\ONLINE_MODE_REQUIRED.flag'
        if (Test-Path -LiteralPath $onlineFlag) {
            $forceOnlineMode = $true
            Write-Host $L.OnlineFallback -ForegroundColor DarkGray
            Write-Host ''
        }
    }

    # --- Step 2: wsreset -i (W11 non-LTSC only) ---
    $installedViaWsreset = $false
    if ($isW11 -and -not $isLTSC -and -not $forceOnlineMode) {
        Write-Host $L.TryWsreset -ForegroundColor Cyan
        Write-Host $L.WsresetWait -ForegroundColor Gray
        try {
            Start-Process 'wsreset.exe' -ArgumentList '-i' -WindowStyle Hidden -ErrorAction Stop
            $deadline = (Get-Date).AddSeconds(90)
            while ((Get-Date) -lt $deadline) {
                Start-Sleep -Seconds 5
                $check = Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue
                if ($check) {
                    Write-Host $L.WsresetOk -ForegroundColor Green
                    $installedViaWsreset = $true
                    break
                }
            }
        } catch {}
        if (-not $installedViaWsreset) {
            Write-Host $L.WsresetFail -ForegroundColor Yellow
        }
        Write-Host ''
    } else {
        if ($forceOnlineMode) {
            Write-Host $L.SkipWsresetOnline -ForegroundColor Gray
        } else {
            Write-Host $L.SkipWsreset -ForegroundColor Gray
        }
        Write-Host ''
    }

    if ($installedViaWsreset) {
        Wait-StoreCompat -Message $L.EnterExit
        return
    }

    # --- Step 3: winget install --source msstore ---
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Host $L.WingetNotFound -ForegroundColor Red
        Write-Host ''
        Write-Host $L.ManualSteps -ForegroundColor Yellow
        Write-Host $L.ManualStep1 -ForegroundColor Gray
        Write-Host $L.ManualStep2 -ForegroundColor Gray
        Write-Host $L.ManualStep3 -ForegroundColor Gray
        Write-Host ''
        Wait-StoreCompat -Message $L.EnterExit
        return
    }

    Write-Host $L.WingetHeader -ForegroundColor Cyan
    Write-Host $L.WingetInstalling -ForegroundColor Gray
    Write-Host ''

    $proc = Start-Process -FilePath $winget.Source `
        -ArgumentList 'install', '--id', '9WZDNCRFJBMP', '--source', 'msstore',
                      '--accept-package-agreements', '--accept-source-agreements' `
        -Wait -PassThru -NoNewWindow

    Write-Host ''
    if ($proc.ExitCode -eq 0) {
        $storeCheck = Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue
        if ($storeCheck) {
            Write-Host $L.InstallOk -ForegroundColor Green
        } else {
            Start-Sleep -Seconds 5
            $storeCheck = Get-AppxPackage -Name 'Microsoft.WindowsStore' -ErrorAction SilentlyContinue
            if ($storeCheck) {
                Write-Host $L.InstallOk -ForegroundColor Green
            } else {
                Write-Host $L.WingetOk -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host ($L.WingetFail -f $proc.ExitCode) -ForegroundColor Red
        Write-Host ''
        Write-Host $L.ManualSteps -ForegroundColor Yellow
        Write-Host $L.ManualStep1 -ForegroundColor Gray
        Write-Host $L.ManualStep2 -ForegroundColor Gray
        Write-Host $L.ManualStep3 -ForegroundColor Gray
    }

    Write-Host ''
    Wait-StoreCompat -Message $L.EnterExit
}
