# ============================================================
# Invoke-PrepararUSB  ->  Build Offline USB
#
# i18n: Option A (en default + full es secondary). Function name
# kept as Invoke-PrepararUSB for tools.json compatibility.
#
# Atlas PC Support
# ============================================================

function Invoke-PrepararUSB {
    [CmdletBinding()]
    param()

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
            WinTitle    = 'ATLAS PC SUPPORT - Build Offline USB'
            HeaderL1    = '   ATLAS PC SUPPORT - BUILD OFFLINE USB'
            HeaderSub   = 'Copy the panel to a USB to use it without internet.'
            NoUSB       = '[!] No USB detected.'
            ConnectUSB  = 'Connect a USB and press ENTER to retry, or [Q] to quit.'
            DetectedHdr = '--- DETECTED USB DRIVES ---'
            UnnamedLbl  = 'Unnamed'
            DriveLine   = '[{0}] {1}:\ - {2} ({3} total / {4} free)'
            QuitOpt     = '[Q] Quit'
            USBNumber   = '  USB number'
            BadSel      = '[!] Invalid selection.'
            DLLauncher  = '--- Downloading launcher ---'
            Trying      = 'Trying: {0}'
            DLOk        = '[OK] Downloaded ({0})'
            DLFail      = '[!] Failed: {0}'
            DLNoLnch    = '[X] Could not download launcher.'
            DLFastCopy  = '--- Downloading FastCopy (optional) ---'
            FCInstOk    = '[OK] FastCopy installer downloaded ({0})'
            FCExtract   = 'Extracting to USB with /EXTRACT64 ...'
            FCExtractOk = '[OK] FastCopy extracted to USB.'
            FCExtractF  = '[!] Could not extract; installer left for manual install.'
            FCDLFail    = '[!] FastCopy download failed: {0}'
            DLPS7Hdr    = '--- Downloading PowerShell 7 MSI (~120 MB, optional) ---'
            DLPS7Note   = 'Lets the client install PS7 without internet from this USB.'
            PS7Exists   = '[OK] Already exists: {0}'
            PS7Ok       = '[OK] PS7 MSI downloaded ({0})'
            PS7Partial  = '[!] Download seems incomplete ({0})'
            PS7Fail     = '[!] PS7 download failed: {0}'
            USBSelected = 'USB selected: {0} ({1})'
            TargetDir   = 'Target folder: {0}'
            ExistsHdr   = '[!] Folder {0} already exists.'
            UpdOpt      = '[A] Update (overwrite launcher and scripts)'
            CancelOpt   = '[C] Cancel'
            Cancelled   = 'Cancelled.'
            BootOk      = '[OK] bootstrap.ps1 written.'
            RunOk       = '[OK] run.bat written.'
            ReadmeOk    = '[OK] README.txt written.'
            AskFC       = 'Download portable FastCopy on the USB? [Y/N] (recommended)'
            AskPS7      = 'Download PowerShell 7 MSI on the USB? [Y/N] (~120 MB)'
            AskPS7Note  = 'Lets the client install PS7 without internet via the "Install/Update PowerShell 7" tool.'
            AskGPUDeps      = 'Prepare offline GPU Check dependencies on USB? [Y/N] (recommended)'
            AskGPUDepsNote  = 'Copies GPU-Z / FurMark 2 bundle / HWiNFO when available. Missing items are installed when possible.'
            GPUDepsHeader   = '--- Preparing GPU Check offline dependencies ---'
            GPUDepsDone     = '[OK] GPU Check offline dependencies prepared.'
            GPUDepsNone     = '[!] GPU Check dependencies could not be prepared.'
            AskDiagDeps      = 'Prepare offline Full System Report dependencies on USB? [Y/N] (recommended)'
            AskDiagDepsNote  = 'Copies CPU-Z / HWiNFO64 / CrystalDiskInfo / CrystalDiskMark / BlueScreenView / BatteryInfoView when available. Missing items are installed when possible.'
            DiagDepsHeader   = '--- Preparing Full System Report offline dependencies ---'
            DiagDepsDone     = '[OK] Full System Report offline dependencies prepared.'
            DiagDepsNone     = '[!] Full System Report dependencies could not be prepared.'
            AskTools         = 'Download tool scripts to USB for offline use? [Y/N] (recommended)'
            AskToolsNote     = 'Lets all tools run without internet. ToolRunner checks this folder first.'
            ToolsHeader      = '--- Downloading tool scripts (deps\tools\) ---'
            ToolsDone        = '[OK] Tool scripts on USB: {0} downloaded, {1} already present.'
            ToolsPartial     = '[!] Tool scripts: {0} ok, {1} failed (check internet).'
            StageETA         = '[ETA] {0}: {1}'
            StageReal        = '[REAL] {0}: {1}'
            StageLblLauncher = 'Launcher download'
            StageLblFastCopy = 'FastCopy package'
            StageLblPS7      = 'PowerShell 7 MSI'
            StageLblGPU      = 'GPU Check dependencies'
            StageLblDiag     = 'Full System Report dependencies'
            StageLblTools    = 'Tool scripts'
            UpdAll      = '[1] Copy this complete Atlas release + refresh optional packages'
            UpdMissing  = '[2] Copy this complete Atlas release + fill missing optional packages'
            DepSkipped  = '[=] Already on USB, skipped: {0}'
            DLLnchFatal = '[X] Could not download launcher. Aborting.'
            EnterExit   = '  ENTER to exit'
            DoneSep     = '============================================================'
            DoneTitle   = '   ATLAS RELEASE VERIFIED (see optional package results above)'
            DonePath    = 'Path: {0}'
            DoneUsage   = 'Usage: connect USB to target PC, double-click run.bat'
            BootTitle   = '# Atlas PC Support - Bootstrap (USB offline)'
            BootDesc1   = '# Checks if launcher.ps1 exists and is fresh (< {0} days).'
            BootDesc2   = '# If not, tries to download it. If no internet, uses the local copy.'
            BootNoLocal = '  [i] No local launcher. Downloading...'
            BootStale   = '  [i] Launcher is {0} days old. Updating...'
            BootFresh   = '  [OK] Local launcher is fresh ({0} days).'
            BootDLOk    = '  [OK] Launcher downloaded from {0}'
            BootDLFail  = '  [!] Failed: {0}'
            BootNoNet   = '  [!] No internet; using local launcher.'
            BootNoBoth  = '  [X] No internet and no local launcher. Cannot continue.'
            RunFail     = 'echo [!] Could not prepare launcher. Check connection or retry.'
        }
        es = @{
            WinTitle    = 'ATLAS PC SUPPORT - Preparar USB Offline'
            HeaderL1    = '   ATLAS PC SUPPORT - PREPARAR USB OFFLINE'
            HeaderSub   = 'Copia el panel a una USB para usarlo sin internet.'
            NoUSB       = '[!] No se detecto ninguna USB conectada.'
            ConnectUSB  = 'Conecta una USB y presiona ENTER para reintentar, o [Q] para salir.'
            DetectedHdr = '--- USB DETECTADAS ---'
            UnnamedLbl  = 'SinNombre'
            DriveLine   = '[{0}] {1}:\ - {2} ({3} total / {4} libres)'
            QuitOpt     = '[Q] Salir'
            USBNumber   = '  Numero de USB'
            BadSel      = '[!] Seleccion no valida.'
            DLLauncher  = '--- Descargando launcher ---'
            Trying      = 'Intentando: {0}'
            DLOk        = '[OK] Descargado ({0})'
            DLFail      = '[!] Fallo: {0}'
            DLNoLnch    = '[X] No se pudo descargar el launcher.'
            DLFastCopy  = '--- Descargando FastCopy (opcional) ---'
            FCInstOk    = '[OK] Installer FastCopy descargado ({0})'
            FCExtract   = 'Extrayendo a la USB con /EXTRACT64 ...'
            FCExtractOk = '[OK] FastCopy extraido en la USB.'
            FCExtractF  = '[!] No se pudo extraer; queda el installer para instalacion manual.'
            FCDLFail    = '[!] Fallo descarga FastCopy: {0}'
            DLPS7Hdr    = '--- Descargando PowerShell 7 MSI (~120 MB, opcional) ---'
            DLPS7Note   = 'Permite que el cliente instale PS7 sin internet desde esta USB.'
            PS7Exists   = '[OK] Ya existe: {0}'
            PS7Ok       = '[OK] PS7 MSI descargado ({0})'
            PS7Partial  = '[!] Descarga parece incompleta ({0})'
            PS7Fail     = '[!] Fallo descarga PS7: {0}'
            USBSelected = 'USB seleccionada: {0} ({1})'
            TargetDir   = 'Carpeta destino : {0}'
            ExistsHdr   = '[!] La carpeta {0} ya existe.'
            UpdOpt      = '[A] Actualizar (sobrescribir launcher y scripts)'
            CancelOpt   = '[C] Cancelar'
            Cancelled   = 'Cancelado.'
            BootOk      = '[OK] bootstrap.ps1 escrito.'
            RunOk       = '[OK] run.bat escrito.'
            ReadmeOk    = '[OK] README.txt escrito.'
            AskFC       = 'Descargar FastCopy portable en la USB? [S/N] (recomendado)'
            AskPS7      = 'Descargar PowerShell 7 MSI en la USB? [S/N] (~120 MB)'
            AskPS7Note  = 'Permite al cliente instalar PS7 sin internet con la tool "Actualizar PowerShell".'
            AskGPUDeps      = 'Preparar dependencias offline de GPU Check en la USB? [S/N] (recomendado)'
            AskGPUDepsNote  = 'Copia GPU-Z / bundle FurMark 2 / HWiNFO cuando estan disponibles. Si faltan, intenta instalarlos.'
            GPUDepsHeader   = '--- Preparando dependencias offline de GPU Check ---'
            GPUDepsDone     = '[OK] Dependencias offline de GPU Check preparadas.'
            GPUDepsNone     = '[!] No se pudieron preparar dependencias de GPU Check.'
            AskDiagDeps      = 'Preparar dependencias offline de Full System Report en la USB? [S/N] (recomendado)'
            AskDiagDepsNote  = 'Copia CPU-Z / HWiNFO64 / CrystalDiskInfo / CrystalDiskMark / BlueScreenView / BatteryInfoView cuando estan disponibles. Si faltan, intenta instalarlos.'
            DiagDepsHeader   = '--- Preparando dependencias offline de Full System Report ---'
            DiagDepsDone     = '[OK] Dependencias offline de Full System Report preparadas.'
            DiagDepsNone     = '[!] No se pudieron preparar dependencias de Full System Report.'
            AskTools         = 'Descargar scripts de tools en la USB para uso offline? [S/N] (recomendado)'
            AskToolsNote     = 'Permite que todas las tools funcionen sin internet. ToolRunner busca primero en esta carpeta.'
            ToolsHeader      = '--- Descargando scripts de tools (deps\tools\) ---'
            ToolsDone        = '[OK] Scripts de tools en USB: {0} descargados, {1} ya estaban.'
            ToolsPartial     = '[!] Scripts de tools: {0} ok, {1} fallaron (verifica internet).'
            StageETA         = '[ETA] {0}: {1}'
            StageReal        = '[REAL] {0}: {1}'
            StageLblLauncher = 'Descarga de launcher'
            StageLblFastCopy = 'Paquete FastCopy'
            StageLblPS7      = 'MSI de PowerShell 7'
            StageLblGPU      = 'Dependencias de GPU Check'
            StageLblDiag     = 'Dependencias de Full System Report'
            StageLblTools    = 'Scripts de tools'
            UpdAll      = '[1] Copiar este release completo de Atlas + renovar paquetes opcionales'
            UpdMissing  = '[2] Copiar este release completo de Atlas + completar opcionales ausentes'
            DepSkipped  = '[=] Ya existe en la USB, omitido: {0}'
            DLLnchFatal = '[X] No se pudo descargar el launcher. Cancelando.'
            EnterExit   = '  ENTER para salir'
            DoneSep     = '============================================================'
            DoneTitle   = '   RELEASE ATLAS VERIFICADO (revisar resultados opcionales arriba)'
            DonePath    = 'Ruta: {0}'
            DoneUsage   = 'Uso : Conecta la USB en el PC objetivo, doble click en run.bat'
            BootTitle   = '# Atlas PC Support - Bootstrap (USB offline)'
            BootDesc1   = '# Comprueba si launcher.ps1 existe y esta fresco (< {0} dias).'
            BootDesc2   = '# Si no, intenta descargarlo. Si tampoco hay internet, usa el local.'
            BootNoLocal = '  [i] No hay launcher local. Descargando...'
            BootStale   = '  [i] Launcher tiene {0} dias. Actualizando...'
            BootFresh   = '  [OK] Launcher local esta fresco ({0} dias).'
            BootDLOk    = '  [OK] Launcher descargado desde {0}'
            BootDLFail  = '  [!] Fallo: {0}'
            BootNoNet   = '  [!] Sin internet; usando launcher local existente.'
            BootNoBoth  = '  [X] Sin internet y sin launcher local. No se puede continuar.'
            RunFail     = 'echo [!] No se pudo preparar el launcher. Revisa tu conexion o reintenta.'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    function Wait-PrepararUSBCompat {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

    # README content per language (keeps existing UX; one heredoc per lang)
    $READMES = @{
    en = @"
ATLAS PC SUPPORT - verified offline release
Run run.bat. All 27 Atlas scripts belong to one approved commit and are verified before startup.
Startup never downloads individual updates. To update the complete bundle, use Prepare USB again.
The current and previous release are retained under releases/. Optional vendor packages remain in apps/ and deps/ and have separate installation/licensing requirements.
To roll back offline: powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\get.ps1 -OfflineRoot . -Rollback
Defender must remain enabled. No exclusions or execution-policy bypass are needed.
"@
    es = @"
ATLAS PC SUPPORT - release offline verificado
Ejecuta run.bat. Los 27 scripts de Atlas pertenecen a un commit aprobado y se verifican antes de iniciar.
El inicio no descarga actualizaciones individuales. Para actualizar el conjunto, usa Preparar USB de nuevo.
Se conservan las versiones actual y anterior en releases/. Los paquetes opcionales siguen en apps/ y deps/ y tienen requisitos propios de instalacion/licencia.
Para volver atras sin red: powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\get.ps1 -OfflineRoot . -Rollback
Mantener Defender activo. No hacen falta exclusiones ni bypass de politica.
"@
}

    $ErrorActionPreference = 'Continue'
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'Gray'
    $Host.UI.RawUI.WindowTitle = 'Build Offline USB - Atlas PC Support'
    try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 40) } catch {}
    Clear-Host

    function Write-Centered {
        param([string]$Text, [string]$Color = 'White')
        $w = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
        $pad = [Math]::Max(0, [Math]::Floor(($w - $Text.Length) / 2))
        Write-Host ((' ' * $pad) + $Text) -ForegroundColor $Color
    }

    function Format-Size { param([double]$Bytes)
        if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
        if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
        if ($Bytes -ge 1KB) { return ('{0:N0} KB' -f ($Bytes / 1KB)) }
        return ("$Bytes B")
    }



    function Format-Duration {
        param([double]$TotalSeconds)

        $seconds = [Math]::Max(0, [int][Math]::Round($TotalSeconds))
        if ($seconds -lt 60) { return ('{0}s' -f $seconds) }

        $minutes = [Math]::Floor($seconds / 60)
        $secRem = $seconds % 60
        if ($minutes -lt 60) { return ('{0}m {1:D2}s' -f $minutes, $secRem) }

        $hours = [Math]::Floor($minutes / 60)
        $minRem = $minutes % 60
        return ('{0}h {1:D2}m {2:D2}s' -f $hours, $minRem, $secRem)
    }

    function Format-EstimateRange {
        param([int]$MinSeconds, [int]$MaxSeconds)

        if ($MinSeconds -lt 0) { $MinSeconds = 0 }
        if ($MaxSeconds -lt $MinSeconds) { $MaxSeconds = $MinSeconds }

        if ($MaxSeconds -lt 60) {
            if ($MinSeconds -eq $MaxSeconds) { return ('{0}s' -f $MinSeconds) }
            return ('{0}-{1}s' -f $MinSeconds, $MaxSeconds)
        }

        $minMinutes = [Math]::Max(1, [Math]::Floor($MinSeconds / 60))
        $maxMinutes = [Math]::Max($minMinutes, [Math]::Ceiling($MaxSeconds / 60))
        if ($minMinutes -eq $maxMinutes) { return ('{0} min' -f $minMinutes) }
        return ('{0}-{1} min' -f $minMinutes, $maxMinutes)
    }

    function Get-StageEstimate {
        param(
            [Parameter(Mandatory)][string]$StageKey,
            [bool]$UseDeltaProfile
        )

        $profile = if ($UseDeltaProfile) { 'delta' } else { 'full' }
        $estimates = @{
            full = @{
                Launcher = @{ Min = 8;   Max = 30  }
                FastCopy = @{ Min = 30;  Max = 150 }
                PS7      = @{ Min = 120; Max = 480 }
                GPU      = @{ Min = 30;  Max = 180 }
                Diag     = @{ Min = 120; Max = 600 }
                Tools    = @{ Min = 20;  Max = 90  }
            }
            delta = @{
                Launcher = @{ Min = 8;   Max = 30  }
                FastCopy = @{ Min = 15;  Max = 60  }
                PS7      = @{ Min = 60;  Max = 240 }
                GPU      = @{ Min = 20;  Max = 120 }
                Diag     = @{ Min = 60;  Max = 300 }
                Tools    = @{ Min = 10;  Max = 45  }
            }
        }

        $entry = $estimates[$profile][$StageKey]
        if (-not $entry) { return @{ Min = 10; Max = 60 } }
        return $entry
    }

    function Invoke-StageWithTelemetry {
        param([Parameter(Mandatory)][string]$StageName,[Parameter(Mandatory)][int]$EstimateMinSec,
            [Parameter(Mandatory)][int]$EstimateMaxSec,[string[]]$MeasurePaths,[Parameter(Mandatory)][scriptblock]$Action)
        Write-Centered ($L.StageETA -f $StageName,(Format-EstimateRange -MinSeconds $EstimateMinSec -MaxSeconds $EstimateMaxSec)) 'DarkGray'
        $sw=[Diagnostics.Stopwatch]::StartNew()
        try {$result=& $Action}
        catch {Write-Centered ("[X] $StageName incomplete: "+$_.Exception.Message) 'Red';$result=$false}
        finally {$sw.Stop();Write-Centered ($L.StageReal -f $StageName,(Format-Duration -TotalSeconds $sw.Elapsed.TotalSeconds)) 'DarkGray'}
        return $result
    }

    $script:AtlasUsbVerifiedPackages=@{}
    $script:AtlasUsbVerifiedFiles=@{}
    $script:AtlasUsbAttemptFailures=@{}
    # Canonical URLs
    $FASTCOPY_URL = (Get-AtlasDependencyDefinition -Name 'FastCopy').DownloadUrl
    $PS7_VERSION = (Get-AtlasDependencyDefinition -Name 'PowerShell7').Version
    $PS7_URL = (Get-AtlasDependencyDefinition -Name 'PowerShell7').DownloadUrl
    $USB_ROOT_NAME          = 'ATLAS_PC_SUPPORT'

    function Show-Header {
        Clear-Host
        Write-Host ''
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title ($L.HeaderL1.Trim()) -Color Yellow
            Write-AtlasStep $L.HeaderSub
            Write-Host ''
            return
        }
        Write-Centered '============================================================' 'DarkGray'
        Write-Centered '        BUILD OFFLINE USB' 'Yellow'
        Write-Centered '  Pack the panel + deps onto a USB for offline use' 'DarkGray'
        Write-Centered '============================================================' 'DarkGray'
        Write-Host ''
    }

    function Select-USB {
        while ($true) {
            $usbs = @(Get-Volume -ErrorAction SilentlyContinue | Where-Object {
                $_.DriveType -eq 'Removable' -and $_.DriveLetter -and $_.Size -gt 0
            })

            if (-not $usbs -or $usbs.Count -eq 0) {
                Write-Host ''
                Write-Centered $L.NoUSB 'Red'
                Write-Host ''
                Write-Centered $L.ConnectUSB 'DarkGray'
                $r = Read-Host '  '
                if ($r -match '^[Qq]$') { return $null }
                continue
            }

            Write-Host ''
            Write-Centered $L.DetectedHdr 'Yellow'
            Write-Host ''

            $map = @{}
            $i = 1
            foreach ($u in $usbs) {
                $label   = if ($u.FileSystemLabel) { $u.FileSystemLabel } else { $L.UnnamedLbl }
                $sizeTxt = Format-Size $u.Size
                $freeTxt = Format-Size $u.SizeRemaining
                $line    = ($L.DriveLine -f $i, $u.DriveLetter, $label, $sizeTxt, $freeTxt)
                Write-Centered $line 'Cyan'
                $map[$i] = $u
                $i++
            }

            Write-Host ''
            Write-Centered $L.QuitOpt 'DarkGray'
            Write-Host ''
            $sel = Read-Host $L.USBNumber
            if ($sel -match '^[Qq]$') { return $null }
            if ($sel -as [int] -and $map.ContainsKey([int]$sel)) {
                return $map[[int]$sel]
            }
            Write-Centered $L.BadSel 'Red'
            Start-Sleep 1
        }
    }



    function Invoke-ExternalProcessWithTimeout {
        param([Parameter(Mandatory)][string]$FilePath,[string[]]$ArgumentList=@(),[int]$TimeoutSec=180)
        try {
            $result=Invoke-AtlasNativeProcess -FilePath $FilePath -Arguments ($ArgumentList -join ' ') -TimeoutSeconds $TimeoutSec
            return @{Started=$result.Started;Completed=$result.Completed;TimedOut=$result.TimedOut;ExitCode=$result.ExitCode;Error=$(if($result.State -eq 'Correct'){$null}else{$result.State})}
        } catch { return @{Started=$false;Completed=$false;TimedOut=$false;ExitCode=$null;Error=$_.Exception.Message} }
    }

    function Download-FastCopy {
        param([string]$AppsDir)
        New-Item -ItemType Directory -Path $AppsDir -Force -ErrorAction Stop|Out-Null
        Assert-AtlasPlainDirectory $AppsDir
        $installer=Join-Path $AppsDir ('FastCopy-installer-'+[guid]::NewGuid().ToString('N')+'.exe')
        try {
            Invoke-WebRequest -Uri $FASTCOPY_URL -OutFile $installer -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            Assert-AtlasInstaller -Path $installer -ExpectedSha256 ((Get-AtlasDependencyDefinition -Name FastCopy).DownloadSha256)
            $result=Invoke-AtlasNativeProcess -FilePath $installer -ArgumentList @('/EXTRACT64','/NOSUBDIR','/AGREE_LICENSE',("/DIR=$AppsDir")) -TimeoutSeconds 180
            if($result.State -ne 'Correct' -or -not (Test-Path -LiteralPath (Join-Path $AppsDir 'FastCopy.exe') -PathType Leaf)){throw "Extraction $($result.State), exit $($result.ExitCode); inspect this partial attempt. No second installer will run."}
            Remove-Item -LiteralPath $installer -ErrorAction Stop
            Register-UsbInstallerFiles -Key FastCopy -Directory $AppsDir
            return $true
        } catch {
            $script:AtlasUsbAttemptFailures['FastCopy']=$true
            Write-Centered ("[X] FastCopy not prepared: "+$_.Exception.Message) 'Red'
            return $false
        }
    }

    function Download-PS7 {
        param(
            [string]$DepsDir,
            [switch]$ForceRedownload
        )

        Write-Host ''
        Write-Centered $L.DLPS7Hdr 'Yellow'
        Write-Centered $L.DLPS7Note 'DarkGray'

        if (-not (Test-Path $DepsDir)) {
            New-Item -ItemType Directory -Path $DepsDir -Force | Out-Null
        }
        $msiFile = Join-Path $DepsDir "PowerShell-$PS7_VERSION-win-x64.msi"
        $tmpFile = "$msiFile.download.msi"
        try {
            if (-not (Get-Command Assert-AtlasInstaller -ErrorAction SilentlyContinue)) {
                throw 'Close and reopen the updated Atlas panel before preparing installers.'
            }
            $expectedHash = (Get-AtlasDependencyDefinition -Name PowerShell7).DownloadSha256
            if ($expectedHash -cnotmatch '^[a-f0-9]{64}$') { throw 'Missing pinned PowerShell SHA-256.' }
            if (-not $ForceRedownload -and (Test-Path -LiteralPath $msiFile)) {
                Assert-AtlasInstaller -Path $msiFile -ExpectedSha256 $expectedHash -MicrosoftSignature
                [IO.File]::WriteAllText("$msiFile.sha256", $expectedHash, [Text.UTF8Encoding]::new($false))
                Register-UsbInstallerFiles -Key PowerShell7 -SingleFile $msiFile
                Write-Centered ($L.PS7Exists -f $msiFile) 'Green'
                return $true
            }
            $ProgressPreference = 'SilentlyContinue'
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
            Invoke-WebRequest -Uri $PS7_URL -OutFile $tmpFile -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
            $sz = (Get-Item $tmpFile).Length
            if ($sz -gt 50MB) {
                Assert-AtlasInstaller -Path $tmpFile -ExpectedSha256 $expectedHash -MicrosoftSignature
                Move-Item -LiteralPath $tmpFile -Destination $msiFile -Force
                [IO.File]::WriteAllText("$msiFile.sha256", $expectedHash, [Text.UTF8Encoding]::new($false))
                Register-UsbInstallerFiles -Key PowerShell7 -SingleFile $msiFile
                Write-Centered ($L.PS7Ok -f (Format-Size $sz)) 'Green'
                return $true
            } else {
                Write-Centered ($L.PS7Partial -f (Format-Size $sz)) 'Yellow'
                Remove-Item -LiteralPath $tmpFile -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Centered ($L.PS7Fail -f $_.Exception.Message) 'Yellow'
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
        }
        return $false
    }

    function Prepare-GPUCheckDeps {
        param([string]$GpuToolsDir)

        Write-Host ''
        Write-Centered $L.GPUDepsHeader 'Yellow'

        if (-not (Test-Path -LiteralPath $GpuToolsDir)) {
            New-Item -ItemType Directory -Path $GpuToolsDir -Force | Out-Null
        }



        function Resolve-DepPath {
    param([string]$DepName,[string[]]$FallbackPaths)
    return Resolve-AtlasDependency -Name $DepName -AdditionalSearchPaths $FallbackPaths -InstallIfMissing
}

        $copiedCount = 0

        $gpuzSrc = Resolve-DepPath -DepName 'GPUZ' -FallbackPaths @(
            'C:\Program Files (x86)\GPU-Z\GPU-Z.exe',
            'C:\Program Files\GPU-Z\GPU-Z.exe'
        )
        if ($gpuzSrc -and (Test-Path -LiteralPath $gpuzSrc)) {
            Copy-AtlasUsbExecutable -Source $gpuzSrc -Destination (Join-Path $GpuToolsDir 'GPU-Z.exe') -PackageKey 'GPU/GPUZ'
            $copiedCount++
        }

        $hwSrc = Resolve-DepPath -DepName 'HWiNFO' -FallbackPaths @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe'
        )
        if ($hwSrc -and (Test-Path -LiteralPath $hwSrc)) {
            Copy-AtlasUsbExecutable -Source $hwSrc -Destination (Join-Path $GpuToolsDir 'HWiNFO64.exe') -PackageKey 'GPU/HWiNFO'
            $copiedCount++
        }

        $furExe = Resolve-DepPath -DepName 'FurMark2' -FallbackPaths @(
            'C:\Program Files\Geeks3D\FurMark2_x64\furmark.exe',
            'C:\Program Files (x86)\Geeks3D\FurMark2_x64\furmark.exe'
        )
        if ($furExe -and (Test-Path -LiteralPath $furExe)) {
            $furSrcDir = Split-Path -Parent $furExe
            $furDstDir = Join-Path $GpuToolsDir 'FurMark2_x64'
            if (-not (Test-Path -LiteralPath $furDstDir)) {
                New-Item -ItemType Directory -Path $furDstDir -Force | Out-Null
            }
            Copy-AtlasDependencyTree -SourceDir $furSrcDir -DestinationDir $furDstDir -PackageKey 'GPU/FurMark2' | Out-Null
            if (Test-Path -LiteralPath (Join-Path $furDstDir 'furmark.exe')) {
                $copiedCount++
            }
        }

        $hasGpuZ = Test-Path -LiteralPath (Join-Path $GpuToolsDir 'GPU-Z.exe')
        $hasFur = Test-Path -LiteralPath (Join-Path $GpuToolsDir 'FurMark2_x64\furmark.exe')
        $hasHw = Test-Path -LiteralPath (Join-Path $GpuToolsDir 'HWiNFO64.exe')

        if ($hasGpuZ -and $hasFur -and $hasHw) {
            Write-Centered $L.GPUDepsDone 'Green'
            return $true
        }

        if ($copiedCount -gt 0 -or $hasHw) {
            Write-Centered ($L.GPUDepsDone + ' (partial)') 'Yellow'
            return $false
        }

        Write-Centered $L.GPUDepsNone 'Yellow'
        return $false
    }

    function Prepare-DiagnosticoMasterDeps {
        param([string]$DiagToolsDir)

        Write-Host ''
        Write-Centered $L.DiagDepsHeader 'Yellow'

        if (-not (Test-Path -LiteralPath $DiagToolsDir)) {
            New-Item -ItemType Directory -Path $DiagToolsDir -Force | Out-Null
        }



        function Resolve-DepPath {
    param([string]$DepName,[string[]]$FallbackPaths)
    return Resolve-AtlasDependency -Name $DepName -AdditionalSearchPaths $FallbackPaths -InstallIfMissing
}

        function Copy-TreeSafely {
            param([Parameter(Mandatory)][string]$SourceDir,[Parameter(Mandatory)][string]$DestinationDir,[string]$PackageKey)
            Copy-AtlasDependencyTree -SourceDir $SourceDir -DestinationDir $DestinationDir -PackageKey $PackageKey
        }

        $copiedCount = 0

        $cpuzSrc = Resolve-DepPath -DepName 'CPUZ' -FallbackPaths @(
            'C:\Program Files\CPUID\CPU-Z\cpuz_x64.exe',
            'C:\Program Files\CPUID\CPU-Z\cpuz_x32.exe',
            'C:\Program Files\CPUID\CPU-Z\cpuz.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x64.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x32.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\cpuz.exe'
        )
        if ($cpuzSrc -and (Test-Path -LiteralPath $cpuzSrc)) {
            $cpuzDstName = Split-Path -Leaf $cpuzSrc
            Copy-AtlasUsbExecutable -Source $cpuzSrc -Destination (Join-Path $DiagToolsDir $cpuzDstName) -PackageKey 'Diag/CPUZ'
            $copiedCount++
        }

        $bsodSrc = Resolve-DepPath -DepName 'BlueScreenView' -FallbackPaths @(
            'C:\Program Files\NirSoft\BlueScreenView\BlueScreenView.exe',
            'C:\Program Files (x86)\NirSoft\BlueScreenView\BlueScreenView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\bluescreenview.exe'
        )
        if ($bsodSrc -and (Test-Path -LiteralPath $bsodSrc)) {
            Copy-AtlasUsbExecutable -Source $bsodSrc -Destination (Join-Path $DiagToolsDir 'BlueScreenView.exe') -PackageKey 'Diag/BlueScreenView'
            $copiedCount++
        }

        $batSrc = Resolve-DepPath -DepName 'BatteryInfoView' -FallbackPaths @(
            'C:\Program Files\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            'C:\Program Files (x86)\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\batteryinfoview.exe'
        )
        if ($batSrc -and (Test-Path -LiteralPath $batSrc)) {
            Copy-AtlasUsbExecutable -Source $batSrc -Destination (Join-Path $DiagToolsDir 'BatteryInfoView.exe') -PackageKey 'Diag/BatteryInfoView'
            $copiedCount++
        }

        $hwSrc = Resolve-DepPath -DepName 'HWiNFO' -FallbackPaths @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe'
        )
        if ($hwSrc -and (Test-Path -LiteralPath $hwSrc)) {
            Copy-AtlasUsbExecutable -Source $hwSrc -Destination (Join-Path $DiagToolsDir 'HWiNFO64.exe') -PackageKey 'Diag/HWiNFO'
            $copiedCount++
        }

        $cdiSrc = Resolve-DepPath -DepName 'CrystalDiskInfo' -FallbackPaths @(
            'C:\Program Files\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files\CrystalDiskInfo\DiskInfo32.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo32.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskinfo.exe'
        )
        if ($cdiSrc -and (Test-Path -LiteralPath $cdiSrc)) {
            $cdiDir = Split-Path -Parent $cdiSrc
            $cdiDstDir = Join-Path $DiagToolsDir 'CrystalDiskInfo'
            if (Test-Path $cdiDir) {
                $ok = Copy-TreeSafely -SourceDir $cdiDir -DestinationDir $cdiDstDir -PackageKey 'Diag/CrystalDiskInfo'
                if ($ok -and (
                    (Test-Path -LiteralPath (Join-Path $cdiDstDir 'DiskInfo64.exe')) -or
                    (Test-Path -LiteralPath (Join-Path $cdiDstDir 'DiskInfo32.exe'))
                )) {
                    $copiedCount++
                }
            }
        }

        $cdmSrc = Resolve-DepPath -DepName 'CrystalDiskMark' -FallbackPaths @(
            'C:\Program Files\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark\DiskMark64.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskmark.exe'
        )
        if ($cdmSrc -and (Test-Path -LiteralPath $cdmSrc)) {
            $cdmDir = Split-Path -Parent $cdmSrc
            $cdmDstDir = Join-Path $DiagToolsDir 'CrystalDiskMark'
            if (Test-Path $cdmDir) {
                $ok = Copy-TreeSafely -SourceDir $cdmDir -DestinationDir $cdmDstDir -PackageKey 'Diag/CrystalDiskMark'
                if ($ok -and (Test-Path -LiteralPath (Join-Path $cdmDstDir 'DiskMark64.exe'))) {
                    $copiedCount++
                }
            }
        }

        $hasCpuZ = (Test-Path -LiteralPath (Join-Path $DiagToolsDir 'cpuz_x64.exe')) -or
            (Test-Path -LiteralPath (Join-Path $DiagToolsDir 'cpuz_x32.exe')) -or
            (Test-Path -LiteralPath (Join-Path $DiagToolsDir 'cpuz.exe'))
        $hasBsod = Test-Path -LiteralPath (Join-Path $DiagToolsDir 'BlueScreenView.exe')
        $hasBat = Test-Path -LiteralPath (Join-Path $DiagToolsDir 'BatteryInfoView.exe')
        $hasCdi = (Test-Path -LiteralPath (Join-Path $DiagToolsDir 'CrystalDiskInfo\DiskInfo64.exe')) -or
            (Test-Path -LiteralPath (Join-Path $DiagToolsDir 'CrystalDiskInfo\DiskInfo32.exe'))
        $hasCdm = (Test-Path -LiteralPath (Join-Path $DiagToolsDir 'CrystalDiskMark\DiskMark64.exe'))
        $hasHw = Test-Path -LiteralPath (Join-Path $DiagToolsDir 'HWiNFO64.exe')

        if ($hasCpuZ -and $hasBsod -and $hasBat -and $hasCdi -and $hasCdm -and $hasHw) {
            Write-Centered $L.DiagDepsDone 'Green'
            return $true
        }

        if ($copiedCount -gt 0) {
            Write-Centered ($L.DiagDepsDone + ' (partial)') 'Yellow'
            return $false
        }

        Write-Centered $L.DiagDepsNone 'Yellow'
        return $false
    }











    function Write-Readme {
        param([string]$Path, [string]$DriveLetter)
        $body = $READMES[$lang]
        if (-not $body) { $body = $READMES['en'] }
        [System.IO.File]::WriteAllText($Path, $body, [System.Text.UTF8Encoding]::new($true))
    }

    function Register-UsbInstallerFiles {
        param([Parameter(Mandatory)][string]$Key,[string]$Directory,[string]$SingleFile)
        $files=if($SingleFile){@(Get-Item -LiteralPath $SingleFile -Force -ErrorAction Stop)}else{@(Get-AtlasPlainTreeFiles -Root $Directory)}
        $script:AtlasUsbVerifiedFiles[$Key]=@($files|ForEach-Object {@{Path=$_.FullName;Sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()}})
        $script:AtlasUsbVerifiedPackages[$Key]=$true
    }

    function Get-UsbDependencyRows {
        param([Parameter(Mandatory)][string]$Root)
        $definitions=@(
            @{Key='FastCopy';Group='FastCopy';Any=@('apps/FastCopy/FastCopy.exe');Resources=@();Scope='Verified installer extraction inventory, not runtime qualification'},
            @{Key='PowerShell7';Group='PS7';Any=@("deps/PowerShell-$PS7_VERSION-win-x64.msi");Resources=@();Scope='Pinned Microsoft MSI, not an installed runtime'},
            @{Key='GPU/GPUZ';Group='GPU';Any=@('deps/GPUCheck/tools/GPU-Z.exe');Resources=@();Scope='Executable copy only; sensors/runtime not qualified'},
            @{Key='GPU/HWiNFO';Group='GPU';Any=@('deps/GPUCheck/tools/HWiNFO64.exe');Resources=@();Scope='Executable copy only; sensors/runtime not qualified'},
            @{Key='GPU/FurMark2';Group='GPU';Any=@('deps/GPUCheck/tools/FurMark2_x64/furmark.exe');Resources=@();Scope='Recorded source tree copy, not runtime qualification'},
            @{Key='Diag/CPUZ';Group='Diag';Any=@('deps/DiagnosticoMaster/tools/cpuz_x64.exe','deps/DiagnosticoMaster/tools/cpuz_x32.exe','deps/DiagnosticoMaster/tools/cpuz.exe');Resources=@();Scope='Executable copy only; runtime not qualified'},
            @{Key='Diag/BlueScreenView';Group='Diag';Any=@('deps/DiagnosticoMaster/tools/BlueScreenView.exe');Resources=@();Scope='Executable copy only; runtime not qualified'},
            @{Key='Diag/BatteryInfoView';Group='Diag';Any=@('deps/DiagnosticoMaster/tools/BatteryInfoView.exe');Resources=@();Scope='Executable copy only; runtime not qualified'},
            @{Key='Diag/HWiNFO';Group='Diag';Any=@('deps/DiagnosticoMaster/tools/HWiNFO64.exe');Resources=@();Scope='Executable copy only; runtime not qualified'},
            @{Key='Diag/CrystalDiskInfo';Group='Diag';Any=@('deps/DiagnosticoMaster/tools/CrystalDiskInfo/DiskInfo64.exe','deps/DiagnosticoMaster/tools/CrystalDiskInfo/DiskInfo32.exe');Resources=@('deps/DiagnosticoMaster/tools/CrystalDiskInfo/CdiResource');Scope='Recorded source tree copy, not disk qualification'},
            @{Key='Diag/CrystalDiskMark';Group='Diag';Any=@('deps/DiagnosticoMaster/tools/CrystalDiskMark/DiskMark64.exe');Resources=@('deps/DiagnosticoMaster/tools/CrystalDiskMark/CdmResource');Scope='Recorded source tree copy, no benchmark executed'}
        )
        $rootPath=(Get-Item -LiteralPath $Root -Force -ErrorAction Stop).FullName.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        $previous=@()
        $statusPath=Join-Path $Root 'usb-dependency-status.json'
        if(Test-Path -LiteralPath $statusPath){
            try {Assert-AtlasPlainFile $statusPath;if((Get-Item -LiteralPath $statusPath).Length -gt 16MB){throw 'Oversized dependency evidence'};$p=[IO.File]::ReadAllText($statusPath,[Text.Encoding]::UTF8)|ConvertFrom-Json -ErrorAction Stop;if($p.SchemaVersion -eq 1){$previous=@($p.Packages)}}
            catch {Write-Warning 'Previous USB dependency evidence not evaluated.'}
        }
        foreach($definition in $definitions) {
            $state='MissingOrIncomplete';$version=$null;$files=@()
            $executable=@($definition.Any | ForEach-Object {Join-Path $Root $_} | Where-Object {Test-Path -LiteralPath $_ -PathType Leaf})|Select-Object -First 1
            $resources=$true
            foreach($resource in $definition.Resources) {
                $resourcePath=Join-Path $Root $resource
                if(-not (Test-Path -LiteralPath $resourcePath -PathType Container)){$resources=$false;continue}
                if(-not @(Get-ChildItem -LiteralPath $resourcePath -Force -ErrorAction Stop|Select-Object -First 1).Count){$resources=$false}
            }
            if($executable -and $resources) {
                $state='PresentNotEvaluated'
                try {
                    Assert-AtlasPlainFile $executable
                    $version=(Get-Item -LiteralPath $executable -Force -ErrorAction Stop).VersionInfo.FileVersion
                    $old=@($previous|Where-Object Key -eq $definition.Key)|Select-Object -First 1
                    $records=if($script:AtlasUsbVerifiedFiles.ContainsKey($definition.Key)) {@($script:AtlasUsbVerifiedFiles[$definition.Key])} elseif($old.State -in @('CopiedAndHashVerified','RecordedFilesVerified')) {@($old.Files)} else {@()}
                    foreach($record in $records) {
                        $path=if([IO.Path]::IsPathRooted([string]$record.Path)){[string]$record.Path}else{Join-Path $Root $record.Path}
                        $path=[IO.Path]::GetFullPath($path)
                        if(-not $path.StartsWith($rootPath,[StringComparison]::OrdinalIgnoreCase) -or $record.Sha256 -cnotmatch '^[a-f0-9]{64}$'){throw 'Invalid recorded package path/hash.'}
                        Assert-AtlasPlainFile $path
                        if((Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() -cne $record.Sha256){throw 'Recorded dependency member changed.'}
                        $files+=@{Path=$path.Substring($rootPath.Length).Replace('\','/');Sha256=$record.Sha256}
                    }
                    $exeRelative=$executable.Substring($rootPath.Length).Replace('\','/')
                    if($files.Count -and @($files|Where-Object Path -eq $exeRelative).Count) {
                        $state=if($script:AtlasUsbVerifiedPackages.ContainsKey($definition.Key)){'CopiedAndHashVerified'}else{'RecordedFilesVerified'}
                    }
                } catch {$state='ChangedOrNotEvaluated';$files=@()}
            }
            if($script:AtlasUsbAttemptFailures.ContainsKey($definition.Key)){$state='FailedAttempt'}
            [pscustomobject]@{Key=$definition.Key;Group=$definition.Group;State=$state;Version=$version;Scope=$definition.Scope;Files=@($files)}
        }
    }

    # ====================== MAIN ======================

    Show-Header

    $usb = Select-USB
    if (-not $usb) {
        Write-Host ''
        Write-Centered $L.Cancelled 'DarkGray'
        return
    }

    $drive     = "$($usb.DriveLetter):"
    $targetDir = Join-Path $drive $USB_ROOT_NAME

    Write-Host ''
    Write-Centered ($L.USBSelected -f $drive, (Format-Size $usb.Size)) 'Cyan'
    Write-Centered ($L.TargetDir -f $targetDir) 'Cyan'
    Write-Host ''

    # ---- Determine mode (fresh install vs. update) ----
    $isUpdate  = Test-Path $targetDir
    $updateAll = $false   # only relevant when $isUpdate

    if ($isUpdate) {
        Write-Centered ($L.ExistsHdr -f $targetDir) 'Yellow'
        Write-Host ''
        Write-Centered $L.UpdAll     'White'
        Write-Centered $L.UpdMissing 'White'
        Write-Centered $L.CancelOpt  'White'
        Write-Host ''
        $o = Read-Host '  '
        switch -Regex ($o.Trim()) {
            '^1$'       { $updateAll = $true }
            '^2$'       { $updateAll = $false }
            default     { Write-Centered $L.Cancelled 'DarkGray'; return }
        }
    } else {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $appsDir = Join-Path $targetDir 'apps'
    if (-not (Test-Path $appsDir)) {
        New-Item -ItemType Directory -Path $appsDir -Force | Out-Null
    }

    # Helper: skip a dep unless updating all or the file is absent
    function Test-NeedsDownload {
        param([string]$PresencePath)
        if ($updateAll) { return $true }
        return (-not (Test-Path $PresencePath))
    }

    $useDeltaEstimate = ($isUpdate -and -not $updateAll)

    # The code bundle is always complete; optional vendor packages are separate.
    try {
        $descriptor = if ($script:AtlasReleaseCommit -and $script:AtlasManifestSha256) {
            [pscustomobject]@{ schemaVersion=1; commit=$script:AtlasReleaseCommit; manifestSha256=$script:AtlasManifestSha256 }
        } else { Get-AtlasPublishedRelease }
        $sourceDirectory = if ($script:AtlasReleaseCommit -and -not $script:AtlasDevelopmentMode) { $script:AtlasRoot } else { $null }
        $release = Install-AtlasRelease -Root $targetDir -Descriptor $descriptor -SourceDirectory $sourceDirectory -PrepareOfflineEntry
        Write-Centered ("[OK] Release $($release.Commit.Substring(0,12)): all 27 tools verified; offline entry ready.") 'Green'
        Write-Readme -Path (Join-Path $targetDir 'README.txt') -DriveLetter $drive
    } catch {
        Write-Centered ("[X] Complete release not activated: $($_.Exception.Message)") 'Red'
        Wait-PrepararUSBCompat -Message $L.EnterExit
        return
    }
    # ---- Dependencies ----
    # On fresh install: ask per-dep. On update: honour the chosen mode silently.
    $fcDir        = Join-Path $appsDir 'FastCopy'
    $fcExe        = Join-Path $fcDir 'FastCopy.exe'
    $depsDir      = Join-Path $targetDir 'deps'
    $ps7Msi       = Join-Path $depsDir "PowerShell-$PS7_VERSION-win-x64.msi"
    $gpuToolsDir  = Join-Path $targetDir 'deps\GPUCheck\tools'
    $diagToolsDir = Join-Path $targetDir 'deps\DiagnosticoMaster\tools'

    # FastCopy
    if ($isUpdate) {
        if ($updateAll -or @(Get-UsbDependencyRows -Root $targetDir | Where-Object {$_.Group -eq 'FastCopy' -and $_.State -notin @('CopiedAndHashVerified','RecordedFilesVerified')}).Count) {
            $fcEst = Get-StageEstimate -StageKey 'FastCopy' -UseDeltaProfile:$useDeltaEstimate
            Invoke-StageWithTelemetry -StageName $L.StageLblFastCopy `
                -EstimateMinSec $fcEst.Min -EstimateMaxSec $fcEst.Max `
                -MeasurePaths @($fcDir) `
                -Action { Download-FastCopy -AppsDir $fcDir } | Out-Null
        } else {
            Write-Centered ($L.DepSkipped -f 'FastCopy') 'DarkGray'
        }
    } else {
        Write-Host ''
        Write-Centered $L.AskFC 'Yellow'
        $dfc = Read-Host '  '
        if ($dfc -match '^[SsYy]$') {
            $fcEst = Get-StageEstimate -StageKey 'FastCopy' -UseDeltaProfile:$false
            Invoke-StageWithTelemetry -StageName $L.StageLblFastCopy `
                -EstimateMinSec $fcEst.Min -EstimateMaxSec $fcEst.Max `
                -MeasurePaths @($fcDir) `
                -Action { Download-FastCopy -AppsDir $fcDir } | Out-Null
        }
    }

    # PowerShell 7 MSI
    if ($isUpdate) {
        if ($updateAll -or @(Get-UsbDependencyRows -Root $targetDir | Where-Object {$_.Group -eq 'PS7' -and $_.State -notin @('CopiedAndHashVerified','RecordedFilesVerified')}).Count) {
            $ps7Est = Get-StageEstimate -StageKey 'PS7' -UseDeltaProfile:$useDeltaEstimate
            Invoke-StageWithTelemetry -StageName $L.StageLblPS7 `
                -EstimateMinSec $ps7Est.Min -EstimateMaxSec $ps7Est.Max `
                -MeasurePaths @($ps7Msi) `
                -Action { Download-PS7 -DepsDir $depsDir -ForceRedownload:$updateAll } | Out-Null
        } else {
            Write-Centered ($L.DepSkipped -f 'PowerShell 7 MSI') 'DarkGray'
        }
    } else {
        Write-Host ''
        Write-Centered $L.AskPS7 'Yellow'
        Write-Centered $L.AskPS7Note 'DarkGray'
        $dps = Read-Host '  '
        if ($dps -match '^[SsYy]$') {
            $ps7Est = Get-StageEstimate -StageKey 'PS7' -UseDeltaProfile:$false
            Invoke-StageWithTelemetry -StageName $L.StageLblPS7 `
                -EstimateMinSec $ps7Est.Min -EstimateMaxSec $ps7Est.Max `
                -MeasurePaths @($ps7Msi) `
                -Action { Download-PS7 -DepsDir $depsDir } | Out-Null
        }
    }

    # GPU Check deps
    if ($isUpdate) {
        if ($updateAll -or @(Get-UsbDependencyRows -Root $targetDir | Where-Object {$_.Group -eq 'GPU' -and $_.State -notin @('CopiedAndHashVerified','RecordedFilesVerified')}).Count) {
            $gpuEst = Get-StageEstimate -StageKey 'GPU' -UseDeltaProfile:$useDeltaEstimate
            Invoke-StageWithTelemetry -StageName $L.StageLblGPU `
                -EstimateMinSec $gpuEst.Min -EstimateMaxSec $gpuEst.Max `
                -MeasurePaths @($gpuToolsDir) `
                -Action { Prepare-GPUCheckDeps -GpuToolsDir $gpuToolsDir } | Out-Null
        } else {
            Write-Centered ($L.DepSkipped -f 'GPU Check deps') 'DarkGray'
        }
    } else {
        Write-Host ''
        Write-Centered $L.AskGPUDeps 'Yellow'
        Write-Centered $L.AskGPUDepsNote 'DarkGray'
        $dgd = Read-Host '  '
        if ($dgd -match '^[SsYy]$') {
            $gpuEst = Get-StageEstimate -StageKey 'GPU' -UseDeltaProfile:$false
            Invoke-StageWithTelemetry -StageName $L.StageLblGPU `
                -EstimateMinSec $gpuEst.Min -EstimateMaxSec $gpuEst.Max `
                -MeasurePaths @($gpuToolsDir) `
                -Action { Prepare-GPUCheckDeps -GpuToolsDir $gpuToolsDir } | Out-Null
        }
    }

    # Full System Report deps
    if ($isUpdate) {
        if ($updateAll -or @(Get-UsbDependencyRows -Root $targetDir | Where-Object {$_.Group -eq 'Diag' -and $_.State -notin @('CopiedAndHashVerified','RecordedFilesVerified')}).Count) {
            $diagEst = Get-StageEstimate -StageKey 'Diag' -UseDeltaProfile:$useDeltaEstimate
            Invoke-StageWithTelemetry -StageName $L.StageLblDiag `
                -EstimateMinSec $diagEst.Min -EstimateMaxSec $diagEst.Max `
                -MeasurePaths @($diagToolsDir) `
                -Action { Prepare-DiagnosticoMasterDeps -DiagToolsDir $diagToolsDir } | Out-Null
        } else {
            Write-Centered ($L.DepSkipped -f 'Full System Report deps') 'DarkGray'
        }
    } else {
        Write-Host ''
        Write-Centered $L.AskDiagDeps 'Yellow'
        Write-Centered $L.AskDiagDepsNote 'DarkGray'
        $ddd = Read-Host '  '
        if ($ddd -match '^[SsYy]$') {
            $diagEst = Get-StageEstimate -StageKey 'Diag' -UseDeltaProfile:$false
            Invoke-StageWithTelemetry -StageName $L.StageLblDiag `
                -EstimateMinSec $diagEst.Min -EstimateMaxSec $diagEst.Max `
                -MeasurePaths @($diagToolsDir) `
                -Action { Prepare-DiagnosticoMasterDeps -DiagToolsDir $diagToolsDir } | Out-Null
        }
    }

    Write-Host ''
    Write-Centered $L.DoneSep 'Cyan'
    Write-Centered 'Atlas code ready; optional packages listed separately / Codigo Atlas listo; revisar paquetes opcionales.' 'Green'
    $rows=@(Get-UsbDependencyRows -Root $targetDir)
    $rows|Format-Table Key,State,Version,Scope -AutoSize|Out-Host
    $status=[ordered]@{SchemaVersion=1;ObservedUtc=[datetime]::UtcNow.ToString('o');AtlasCodeVerified=$true;ReleaseCommit=$release.Commit;Packages=$rows;VendorRuntimeQualified=$false}
    [IO.File]::WriteAllText((Join-Path $targetDir 'usb-dependency-status.json'),($status|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    Write-Centered $L.DoneSep 'Cyan'
    Write-Host ''
    Write-Centered ($L.DonePath -f $targetDir) 'White'
    Write-Centered $L.DoneUsage 'Gray'
    Write-Host ''

    try { Start-Process explorer.exe $targetDir } catch {}
}
