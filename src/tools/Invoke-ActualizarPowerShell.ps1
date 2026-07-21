# ============================================================
# Invoke-ActualizarPowerShell  ->  Install / Update PowerShell 7
#
# i18n: Option A (en default + full es secondary). Tool-internal
# function name kept as Invoke-ActualizarPowerShell so tools.json
# registry and existing config.json files keep working.
#
# Atlas PC Support
# ============================================================

function Invoke-ActualizarPowerShell {
    <#
    .SYNOPSIS
      Install or update PowerShell 7 for the Atlas PC Support panel.

    .DESCRIPTION
      Detects the current version. If PS 7 is not installed, it downloads
      from GitHub (Microsoft's official channel) and installs silently via
      msiexec. If a local MSI exists in deps\ (offline USB mode), it uses
      that instead of downloading.

      After install, every tool launched from the panel runs in pwsh.exe
      automatically thanks to ToolRunner.

      IMPORTANT: this tool runs in an isolated window (temp .ps1) — it
      does NOT have access to the launcher's libs, so all helpers (admin
      check, detection, install) are inlined below. Do not remove.
    #>

    $ErrorActionPreference = 'Stop'

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

    # --- Localized strings ---
    $T = @{
        en = @{
            Title             = 'Install / Update PowerShell 7'
            CurrentConsole    = 'Current console version: {0}'
            CurrentEdition    = 'Edition: {0}'
            AlreadyInstalled  = '[OK] PowerShell 7 already installed: {0}'
            AlreadyDetected   = '[OK] pwsh.exe detected: {0}'
            PathLabel         = '     Path: {0}'
            ToolsRunInPS7     = 'Panel tools already launch in PS 7 automatically.'
            ReinstallPrompt   = 'Press [R] to reinstall / upgrade. Any other key to exit.'
            Option            = 'Option'
            NeedAdmin         = '[!] Administrator is required to install PowerShell 7.'
            NeedAdminHint     = '    Close this window and relaunch the panel as admin.'
            FoundOfflineMsi   = '[i] Local MSI found: {0}'
            WillInstallLocal  = '    Will install without downloading.'
            NoOfflineMsi      = '[i] No local MSI found. Will download from github.com/PowerShell/PowerShell (~120 MB).'
            VersionToInstall  = '    Version to install: {0}'
            ConfirmContinue   = 'Continue? [Y/n]'
            Cancelled         = 'Cancelled.'
            UsingLocalMsi     = '[>] Using local MSI: {0}'
            Downloading       = '[>] Downloading PowerShell {0} (~120 MB)...'
            Installing        = '[>] Installing MSI (silent msiexec)...'
            InstallOK         = '[OK] PowerShell 7 installed: {0}'
            InstalledHeader   = 'PowerShell 7 installed successfully.'
            RouteLabel        = 'Path: {0}'
            RecommendRestart  = 'RECOMMENDED: restart the panel so ToolRunner picks up PS 7.'
            CloseAndReopen    = 'Close this window and reopen the panel from the short URL.'
            InstallError      = '[X] Install error: {0}'
            ManualAlt         = 'Manual alternative:'
            ManualWinget      = '  winget install --id Microsoft.PowerShell --source winget'
            ManualOr          = 'or download the MSI from:'
            ManualUrl         = '  https://github.com/PowerShell/PowerShell/releases/latest'
            DownloadFailed    = 'PS 7 download failed: {0}'
            MsiExitCode       = 'msiexec exited with code {0}'
            InstalledButLost  = 'Install reported OK but pwsh.exe not found. Restart your session.'
        }
        es = @{
            Title             = 'Instalar / Actualizar PowerShell 7'
            CurrentConsole    = 'Version actual de la consola: {0}'
            CurrentEdition    = 'Edicion: {0}'
            AlreadyInstalled  = '[OK] PowerShell 7 ya instalado: {0}'
            AlreadyDetected   = '[OK] pwsh.exe detectado: {0}'
            PathLabel         = '     Ruta: {0}'
            ToolsRunInPS7     = 'Las tools del panel ya se lanzan en PS 7 automaticamente.'
            ReinstallPrompt   = 'Pulsa [R] para reinstalar / actualizar. Cualquier otra tecla para salir.'
            Option            = 'Opcion'
            NeedAdmin         = '[!] Se requiere Administrador para instalar PowerShell 7.'
            NeedAdminHint     = '    Cierra esta ventana y relanza el panel en modo admin.'
            FoundOfflineMsi   = '[i] MSI local encontrado: {0}'
            WillInstallLocal  = '    Se instalara sin descargar nada de internet.'
            NoOfflineMsi      = '[i] MSI local NO encontrado. Se descargara de github.com/PowerShell/PowerShell (~120 MB).'
            VersionToInstall  = '    Version a instalar: {0}'
            ConfirmContinue   = 'Continuar? [S/n]'
            Cancelled         = 'Cancelado.'
            UsingLocalMsi     = '[>] Usando MSI local: {0}'
            Downloading       = '[>] Descargando PowerShell {0} (~120 MB)...'
            Installing        = '[>] Instalando MSI (msiexec silencioso)...'
            InstallOK         = '[OK] PowerShell 7 instalado: {0}'
            InstalledHeader   = 'PowerShell 7 instalado correctamente.'
            RouteLabel        = 'Ruta: {0}'
            RecommendRestart  = 'RECOMENDADO: reinicia el panel para que ToolRunner detecte PS 7.'
            CloseAndReopen    = 'Cierra esta ventana y vuelve a abrir el panel desde la URL corta.'
            InstallError      = '[X] Error durante la instalacion: {0}'
            ManualAlt         = 'Alternativa manual:'
            ManualWinget      = '  winget install --id Microsoft.PowerShell --source winget'
            ManualOr          = 'o descarga el MSI desde:'
            ManualUrl         = '  https://github.com/PowerShell/PowerShell/releases/latest'
            DownloadFailed    = 'Fallo descarga de PS 7: {0}'
            MsiExitCode       = 'msiexec salio con codigo {0}'
            InstalledButLost  = 'Instalacion reportada OK pero pwsh.exe no se encuentra. Reinicia la sesion.'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    # ----- Constants (mirrored from src/lib/PS7.ps1, self-contained) -----
    $PS7_VERSION  = '7.5.0'
    $PS7_URL_X64  = "https://github.com/PowerShell/PowerShell/releases/download/v$PS7_VERSION/PowerShell-$PS7_VERSION-win-x64.msi"
    $PS7_MSI_NAME = "PowerShell-$PS7_VERSION-win-x64.msi"

    # ----- Inline helpers (no dependency on launcher libs) -----
    function _Write-AtlasHeader {
        param([string]$Title, [ConsoleColor]$Color = [ConsoleColor]::Cyan)
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title $Title -Color $Color
            return
        }
        Write-Host ''
        Write-Host '================================================================' -ForegroundColor $Color
        Write-Host ('  ' + $Title) -ForegroundColor $Color
        Write-Host '================================================================' -ForegroundColor $Color
        Write-Host ''
    }

    function _Write-AtlasStepCompat {
        param([string]$Message)
        if ($atlasToolkitReady) { Write-AtlasStep $Message; return }
        Write-Host ('  ' + $Message) -ForegroundColor Cyan
    }

    function _Write-AtlasOkCompat {
        param([string]$Message)
        if ($atlasToolkitReady) { Write-AtlasSuccess $Message; return }
        Write-Host ('  ' + $Message) -ForegroundColor Green
    }

    function _Write-AtlasWarnCompat {
        param([string]$Message)
        if ($atlasToolkitReady) { Write-AtlasWarn $Message; return }
        Write-Host ('  ' + $Message) -ForegroundColor Yellow
    }

    function _Write-AtlasErrCompat {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Write-AtlasFailure -ErrorAction SilentlyContinue)) {
            Write-AtlasFailure $Message
            return
        }
        Write-Host ('  ' + $Message) -ForegroundColor Red
    }

    function _Test-IsAdmin {
        try {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            $p  = New-Object Security.Principal.WindowsPrincipal($id)
            return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch { return $false }
    }

    function _Get-PS7Path {
        $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Path) { return $cmd.Path }
        $candidates = @(
            "$env:ProgramFiles\PowerShell\7\pwsh.exe",
            "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
            "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
        )
        foreach ($c in $candidates) {
            if (Test-Path -LiteralPath $c) {
                return (Resolve-Path -LiteralPath $c).Path
            }
        }
        return $null
    }

    function _Find-OfflineMsi {
        $searchDirs = @()
        # Walk up from the current script in case we're launched from USB
        # (the launcher typically runs from %TEMP%\AtlasPC, so we also
        # check standard USB locations).
        try {
            $invocPath = $MyInvocation.MyCommand.Path
            if ($invocPath) {
                $parent = Split-Path -Parent $invocPath
                $searchDirs += (Join-Path $parent 'deps')
                $gp = Split-Path -Parent $parent
                if ($gp) { $searchDirs += (Join-Path $gp 'deps') }
            }
        } catch {}
        $searchDirs += (Join-Path $env:LOCALAPPDATA 'AtlasPC\deps')
        # Also try every removable drive (USB) in case the panel was
        # launched from a URL but the client plugged the USB in parallel.
        try {
            Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
                $root = $_.Root
                if ($root) {
                    $searchDirs += (Join-Path $root 'ATLAS_PC_SUPPORT\deps')
                    $searchDirs += (Join-Path $root 'deps')
                }
            }
        } catch {}
        foreach ($dir in ($searchDirs | Select-Object -Unique)) {
            if (Test-Path -LiteralPath $dir) {
                $msi = Get-ChildItem -Path $dir -Filter 'PowerShell-*-win-x64.msi' -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending | Select-Object -First 1
                if ($msi) { return $msi.FullName }
            }
        }
        return $null
    }

    function _Install-PS7 {
        param([string]$OfflineSource, $L, [string]$Version, [string]$Url, [string]$MsiName)
        $msi = $null
        if ($OfflineSource -and (Test-Path -LiteralPath $OfflineSource)) {
            $msi = (Resolve-Path -LiteralPath $OfflineSource).Path
            _Write-AtlasStepCompat ($L.UsingLocalMsi -f $msi)
        }
        if (-not $msi) {
            $cacheDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\deps'
            if (-not (Test-Path -LiteralPath $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            $msi = Join-Path $cacheDir $MsiName
            _Write-AtlasStepCompat ($L.Downloading -f $Version)
            try {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $Url -OutFile $msi -UseBasicParsing -TimeoutSec 900
            } catch {
                throw ($L.DownloadFailed -f $_.Exception.Message)
            }
        }

        # SHA-256 Check & Authenticode Verification
        if (Test-Path -LiteralPath $msi) {
            try {
                $sig = Get-AuthenticodeSignature -FilePath $msi -ErrorAction SilentlyContinue
                if ($sig -and $sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -like '*Microsoft*') {
                    _Write-AtlasOkCompat "Microsoft Authenticode signature verified for $($MsiName)."
                } else {
                    _Write-AtlasWarnCompat "Signature verification notice: $($sig.StatusMessage)"
                }
            } catch {}

            if (Get-Command Get-AtlasPS7ExpectedHash -ErrorAction SilentlyContinue) {
                try {
                    $expectedHash = Get-AtlasPS7ExpectedHash
                    $actualHash = (Get-FileHash -LiteralPath $msi -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
                    if ($expectedHash -and $actualHash -ne $expectedHash) {
                        Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
                        throw "SHA-256 hash mismatch for $MsiName. Expected: $expectedHash, Got: $actualHash"
                    }
                    _Write-AtlasOkCompat "SHA-256 checksum verified ($actualHash)."
                } catch {
                    _Write-AtlasWarnCompat "SHA-256 check skipped: $($_.Exception.Message)"
                }
            }
        }

        $msiArgs = @('/i', "`"$msi`"", '/qn', '/norestart', 'ADD_PATH=1', 'ENABLE_PSREMOTING=0', 'REGISTER_MANIFEST=1')
        _Write-AtlasStepCompat $L.Installing
        $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
        if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
            throw ($L.MsiExitCode -f $p.ExitCode)
        }
        $path = _Get-PS7Path
        if (-not $path) {
            throw $L.InstalledButLost
        }
        _Write-AtlasOkCompat ($L.InstallOK -f $path)
        return $path
    }

    # ----- UI -----
    Clear-Host
    _Write-AtlasHeader -Title $L.Title -Color Cyan

    $current = "{0}.{1}" -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
    Write-Host ('  ' + ($L.CurrentConsole -f $current)) -ForegroundColor White
    Write-Host ('  ' + ($L.CurrentEdition -f $PSVersionTable.PSEdition)) -ForegroundColor White
    Write-Host ''

    $ps7Path = _Get-PS7Path
    if ($ps7Path) {
        try {
            $verOutput = & $ps7Path -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
            Write-Host ('  ' + ($L.AlreadyInstalled -f $verOutput)) -ForegroundColor Green
            Write-Host ('  ' + ($L.PathLabel -f $ps7Path)) -ForegroundColor DarkGray
        } catch {
            Write-Host ('  ' + ($L.AlreadyDetected -f $ps7Path)) -ForegroundColor Green
        }
        Write-Host ''
        Write-Host ('  ' + $L.ToolsRunInPS7) -ForegroundColor DarkGray
        Write-Host ('  ' + $L.ReinstallPrompt) -ForegroundColor DarkGray
        $ans = Read-Host ('  ' + $L.Option)
        if ($ans -notmatch '^[Rr]') { return }
    }

    if (-not (_Test-IsAdmin)) {
        _Write-AtlasErrCompat $L.NeedAdmin
        Write-Host ('  ' + $L.NeedAdminHint) -ForegroundColor DarkGray
        return
    }

    $offline = _Find-OfflineMsi
    if ($offline) {
        _Write-AtlasStepCompat ($L.FoundOfflineMsi -f $offline)
        Write-Host ('  ' + $L.WillInstallLocal) -ForegroundColor DarkGray
    } else {
        _Write-AtlasStepCompat $L.NoOfflineMsi
        Write-Host ('  ' + ($L.VersionToInstall -f $PS7_VERSION)) -ForegroundColor DarkGray
    }

    Write-Host ''
    $go = Read-Host ('  ' + $L.ConfirmContinue)
    # Accept Spanish 'n' and English 'n' identically; everything else continues.
    if ($go -match '^[Nn]') {
        _Write-AtlasWarnCompat $L.Cancelled
        return
    }

    Write-Host ''
    try {
        $installed = _Install-PS7 -OfflineSource $offline -L $L -Version $PS7_VERSION -Url $PS7_URL_X64 -MsiName $PS7_MSI_NAME
        Write-Host ''
        Write-Host '  ================================================================' -ForegroundColor Green
        Write-Host ('  ' + $L.InstalledHeader) -ForegroundColor Green
        Write-Host '  ================================================================' -ForegroundColor Green
        Write-Host ''
        Write-Host ('  ' + ($L.RouteLabel -f $installed)) -ForegroundColor White
        Write-Host ''
        Write-Host ('  ' + $L.RecommendRestart) -ForegroundColor Yellow
        Write-Host ('  ' + $L.CloseAndReopen) -ForegroundColor DarkGray
    } catch {
        Write-Host ''
        _Write-AtlasErrCompat ($L.InstallError -f $_.Exception.Message)
        Write-Host ''
        Write-Host ('  ' + $L.ManualAlt) -ForegroundColor DarkGray
        Write-Host ('  ' + $L.ManualWinget) -ForegroundColor White
        Write-Host ('  ' + $L.ManualOr) -ForegroundColor DarkGray
        Write-Host ('  ' + $L.ManualUrl) -ForegroundColor White
    }
}
