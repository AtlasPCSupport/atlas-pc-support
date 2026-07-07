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
            AskStore         = 'Download Microsoft Store bundle to USB for offline install? [Y/N] (recommended for LTSC/IoT)'
            AskStoreNote     = 'Allows installing the Store without internet (~55 MB: VCLibs + UI.Xaml + Store bundle).'
            StoreHeader      = '--- Downloading Microsoft Store bundle (deps\MicrosoftStore\) ---'
            StoreDone        = '[OK] Store bundle on USB: {0} downloaded, {1} already present.'
            StorePartial     = '[!] Store bundle: {0} ok, {1} failed (check internet).'
            StorePartialSoft = '[!] Store bundle: {0} ok, {1} unavailable (source restrictions).'
            StoreMixed       = '[!] Store bundle: {0} ok, {1} unavailable, {2} failed.'
            StoreManifestAuth= '[!] {0}: source returned manifest/auth-required; skipping (best effort).'
            StoreMirrorHint  = '  [i] Optional: set ATLAS_STORE_BUNDLE_URL to a direct .appxbundle mirror.'
            StoreOnlineAuto  = '  [i] Store offline bundle unavailable: target tool will use automatic online install (winget).'
            StageETA         = '[ETA] {0}: {1}'
            StageReal        = '[REAL] {0}: {1}'
            StageRealSpeed   = '[REAL] {0}: {1} @ {2}'
            StageLblLauncher = 'Launcher download'
            StageLblFastCopy = 'FastCopy package'
            StageLblPS7      = 'PowerShell 7 MSI'
            StageLblGPU      = 'GPU Check dependencies'
            StageLblDiag     = 'Full System Report dependencies'
            StageLblTools    = 'Tool scripts'
            StageLblStore    = 'Microsoft Store bundle'
            UpdAll      = '[1] Update all  — re-download launcher + all dependencies'
            UpdMissing  = '[2] Fill missing  — launcher + only download what is absent'
            DepSkipped  = '[=] Already on USB, skipped: {0}'
            DLLnchFatal = '[X] Could not download launcher. Aborting.'
            EnterExit   = '  ENTER to exit'
            DoneSep     = '============================================================'
            DoneTitle   = '   USB PREPARED SUCCESSFULLY'
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
            AskStore         = 'Descargar bundle de Microsoft Store en USB para instalar offline? [S/N] (recomendado para LTSC/IoT)'
            AskStoreNote     = 'Permite instalar la Store sin internet (~55 MB: VCLibs + UI.Xaml + bundle Store).'
            StoreHeader      = '--- Descargando bundle de Microsoft Store (deps\MicrosoftStore\) ---'
            StoreDone        = '[OK] Bundle Store en USB: {0} descargados, {1} ya estaban.'
            StorePartial     = '[!] Bundle Store: {0} ok, {1} fallaron (verifica internet).'
            StorePartialSoft = '[!] Bundle Store: {0} ok, {1} no disponibles (restricciones del origen).'
            StoreMixed       = '[!] Bundle Store: {0} ok, {1} no disponibles, {2} fallaron.'
            StoreManifestAuth= '[!] {0}: la fuente devolvio manifest/auth-required; se omite (best effort).'
            StoreMirrorHint  = '  [i] Opcional: define ATLAS_STORE_BUNDLE_URL con un mirror .appxbundle directo.'
            StoreOnlineAuto  = '  [i] Bundle offline no disponible: la tool destino usara instalacion online automatica (winget).'
            StageETA         = '[ETA] {0}: {1}'
            StageReal        = '[REAL] {0}: {1}'
            StageRealSpeed   = '[REAL] {0}: {1} a {2}'
            StageLblLauncher = 'Descarga de launcher'
            StageLblFastCopy = 'Paquete FastCopy'
            StageLblPS7      = 'MSI de PowerShell 7'
            StageLblGPU      = 'Dependencias de GPU Check'
            StageLblDiag     = 'Dependencias de Full System Report'
            StageLblTools    = 'Scripts de tools'
            StageLblStore    = 'Bundle de Microsoft Store'
            UpdAll      = '[1] Actualizar todo  — re-descargar launcher + todas las dependencias'
            UpdMissing  = '[2] Completar lo que falta  — launcher + solo descargar lo ausente'
            DepSkipped  = '[=] Ya existe en la USB, omitido: {0}'
            DLLnchFatal = '[X] No se pudo descargar el launcher. Cancelando.'
            EnterExit   = '  ENTER para salir'
            DoneSep     = '============================================================'
            DoneTitle   = '   USB PREPARADA CORRECTAMENTE'
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
ATLAS PC SUPPORT - OFFLINE USB
==============================

This USB contains the Atlas PC Support panel ready to use.

BASIC USAGE
-----------
1. Plug the USB into the target PC.
2. Open the "{ROOT}" folder.
3. Double-click "run.bat".
4. If you have internet and the local launcher is older than {DAYS} days,
   bootstrap.ps1 updates it automatically before launching the panel.
5. If you have no internet, the local copy is used as-is.

LAYOUT
------
{LETTER}\{ROOT}\
    run.bat            Double-click here.
    bootstrap.ps1      Updates launcher if needed.
    run-launcher.ps1   Wrapper (captures errors + writes atlas-offline.log).
    launcher.ps1       Compiled panel (auto-updates).
    atlas-offline.log  Transcript of the latest run (errors + stack trace).
    apps\FastCopy\     Portable FastCopy copy (if downloaded).
    deps\tools\        Tool scripts for offline use (Invoke-*.ps1).
    deps\GPUCheck\tools\  Optional offline dependencies for GPU Check.
    deps\DiagnosticoMaster\tools\  Optional offline dependencies for Full System Report.
    README.txt         This file.

TROUBLESHOOTING
---------------
If run.bat closes without showing a clear error, open
atlas-offline.log next to run.bat. It captures everything the
panel printed, including any fatal initialization errors.

UPDATE THE PANEL FROM ANOTHER PC
--------------------------------
Run the "Build Offline USB" tool again on any PC with internet, and
select the same USB. launcher.ps1 will be overwritten with the latest.

REQUIREMENTS ON TARGET PC
-------------------------
- Windows 10 / 11.
- PowerShell 5.1 (ships with Windows).
- Admin privileges (tools ask when needed).

NO INTERNET
-----------
If the PC has no internet, the local launcher will still work. It
just cannot pull updated launcher/FastCopy/etc.

Generated by Atlas PC Support - Build Offline USB
"@
        es = @"
ATLAS PC SUPPORT - USB OFFLINE
===============================

Esta USB contiene el panel Atlas PC Support listo para usar.

USO BASICO
----------
1. Conecta la USB al PC objetivo.
2. Abre la carpeta "{ROOT}".
3. Doble click en "run.bat".
4. Si tienes internet y el launcher local esta viejo (mas de {DAYS} dias),
   bootstrap.ps1 lo actualiza automaticamente antes de lanzar el panel.
5. Si no tienes internet, se usa la copia local tal cual.

ESTRUCTURA
----------
{LETTER}\{ROOT}\
    run.bat            Doble click aqui.
    bootstrap.ps1      Actualiza launcher si hace falta.
    run-launcher.ps1   Wrapper (captura errores + escribe atlas-offline.log).
    launcher.ps1       Panel compilado (se auto-actualiza).
    atlas-offline.log  Transcript de la ultima ejecucion (errores + stack).
    apps\FastCopy\     Copia portable de FastCopy (si se descargo).
    deps\tools\        Scripts de tools para uso offline (Invoke-*.ps1).
    deps\GPUCheck\tools\  Dependencias offline opcionales para GPU Check.
    deps\DiagnosticoMaster\tools\  Dependencias offline opcionales para Full System Report.
    README.txt         Este archivo.

SOLUCION DE PROBLEMAS
---------------------
Si run.bat se cierra sin mostrar un error claro, abre
atlas-offline.log al lado de run.bat. Captura todo lo que
imprimio el panel, incluyendo errores fatales de inicio.

ACTUALIZAR EL PANEL DESDE OTRO PC
---------------------------------
Lanza de nuevo la tool "Preparar USB Offline" en cualquier PC con internet
y seleccciona esta misma USB. Se sobrescribira launcher.ps1 con la version
mas reciente.

REQUISITOS EN EL PC OBJETIVO
----------------------------
- Windows 10 / 11.
- PowerShell 5.1 (ya viene con Windows).
- Permisos de administrador (las tools lo piden cuando toca).

SIN INTERNET
------------
Si el PC no tiene internet, el launcher local seguira funcionando. Solo
no podra descargar versiones actualizadas de launcher, FastCopy, etc.

Generado por Atlas PC Support - Preparar USB Offline
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

    function Get-PathSizeBytes {
        param([string[]]$Paths)

        [int64]$total = 0
        foreach ($path in @($Paths)) {
            if ([string]::IsNullOrWhiteSpace($path)) { continue }
            if (-not (Test-Path -LiteralPath $path)) { continue }
            try {
                $item = Get-Item -LiteralPath $path -ErrorAction Stop
                if ($item -is [System.IO.FileInfo]) {
                    $total += [int64]$item.Length
                } else {
                    $sum = (Get-ChildItem -LiteralPath $path -Recurse -File -Force -ErrorAction SilentlyContinue |
                            Measure-Object -Property Length -Sum).Sum
                    if ($sum) { $total += [int64]$sum }
                }
            } catch {}
        }
        return $total
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
                Store    = @{ Min = 90;  Max = 420 }
            }
            delta = @{
                Launcher = @{ Min = 8;   Max = 30  }
                FastCopy = @{ Min = 15;  Max = 60  }
                PS7      = @{ Min = 60;  Max = 240 }
                GPU      = @{ Min = 20;  Max = 120 }
                Diag     = @{ Min = 60;  Max = 300 }
                Tools    = @{ Min = 10;  Max = 45  }
                Store    = @{ Min = 30;  Max = 180 }
            }
        }

        $entry = $estimates[$profile][$StageKey]
        if (-not $entry) { return @{ Min = 10; Max = 60 } }
        return $entry
    }

    function Invoke-StageWithTelemetry {
        param(
            [Parameter(Mandatory)][string]$StageName,
            [Parameter(Mandatory)][int]$EstimateMinSec,
            [Parameter(Mandatory)][int]$EstimateMaxSec,
            [string[]]$MeasurePaths,
            [Parameter(Mandatory)][scriptblock]$Action
        )

        Write-Centered ($L.StageETA -f $StageName, (Format-EstimateRange -MinSeconds $EstimateMinSec -MaxSeconds $EstimateMaxSec)) 'DarkGray'

        $beforeBytes = Get-PathSizeBytes -Paths $MeasurePaths
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $Action
        $sw.Stop()
        $afterBytes = Get-PathSizeBytes -Paths $MeasurePaths

        [int64]$transferred = [int64]($afterBytes - $beforeBytes)
        if ($transferred -le 0 -and $beforeBytes -eq 0 -and $afterBytes -gt 0) {
            $transferred = $afterBytes
        }

        $realTime = Format-Duration -TotalSeconds $sw.Elapsed.TotalSeconds
        if ($transferred -gt 0 -and $sw.Elapsed.TotalSeconds -gt 0.01) {
            $speedMBps = ($transferred / 1MB) / $sw.Elapsed.TotalSeconds
            if ($speedMBps -ge 1) {
                $speedTxt = ('{0:N2} MB/s' -f $speedMBps)
            } else {
                $speedKBps = ($transferred / 1KB) / $sw.Elapsed.TotalSeconds
                $speedTxt = ('{0:N0} KB/s' -f $speedKBps)
            }
            Write-Centered ($L.StageRealSpeed -f $StageName, $realTime, $speedTxt) 'DarkGray'
        } else {
            Write-Centered ($L.StageReal -f $StageName, $realTime) 'DarkGray'
        }

        return $result
    }

    # Canonical URLs
    $LAUNCHER_URL_PRIMARY   = 'https://toolspanel.atlaspcsupport.com/'
    $LAUNCHER_URL_FALLBACK  = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/launcher.ps1'
    $TOOLS_BASE_URL         = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/src/tools'
    $FASTCOPY_URL           = 'https://fastcopy.jp/archive/FastCopy5.11.2_installer.exe'
    $PS7_VERSION            = '7.5.0'
    $PS7_URL                = "https://github.com/PowerShell/PowerShell/releases/download/v$PS7_VERSION/PowerShell-$PS7_VERSION-win-x64.msi"
    $USB_ROOT_NAME          = 'ATLAS_PC_SUPPORT'
    $MAX_LAUNCHER_AGE_DAYS  = 7
    $STORE_PACKAGES = @(
        @{ Name = 'VCLibs.x64.14.00.Desktop.appx';     Url = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'; SizeMB = 6 },
        @{ Name = 'Microsoft.UI.Xaml.2.8.x64.appx';    Url = 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx'; SizeMB = 17 },
        @{ Name = 'Microsoft.WindowsStore.appxbundle'; Url = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0/packageManifests/9WZDNCRFJBMP'; SizeMB = 28 }
    )

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

    function Download-Launcher {
        param([string]$TargetFile)

        Write-Host ''
        Write-Centered $L.DLLauncher 'Yellow'

        # Cache-bust both URLs. toolspanel.atlaspcsupport.com goes through a
        # Cloudflare Worker that has aggressively cached older builds in
        # the past — appending a random ?v= guarantees a fresh fetch from
        # origin (or at least bypasses edge cache for this request).
        $bust = [Guid]::NewGuid().ToString('N')
        $urls = @(
            ("$LAUNCHER_URL_PRIMARY"  + (& { if ($LAUNCHER_URL_PRIMARY  -match '\?') { '&' } else { '?' } }) + 'v=' + $bust),
            ("$LAUNCHER_URL_FALLBACK" + (& { if ($LAUNCHER_URL_FALLBACK -match '\?') { '&' } else { '?' } }) + 'v=' + $bust)
        )
        $headers = @{ 'Cache-Control' = 'no-cache'; 'Pragma' = 'no-cache' }
        foreach ($u in $urls) {
            Write-Centered ($L.Trying -f $u) 'DarkGray'
            try {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $u -OutFile $TargetFile -UseBasicParsing -TimeoutSec 60 -Headers $headers -ErrorAction Stop
                $sz = (Get-Item $TargetFile).Length
                if ($sz -gt 100KB) {
                    Write-Centered ($L.DLOk -f (Format-Size $sz)) 'Green'
                    return $true
                }
            } catch {
                Write-Centered ($L.DLFail -f $_.Exception.Message) 'Yellow'
            }
        }
        Write-Centered $L.DLNoLnch 'Red'
        return $false
    }

    function Invoke-ExternalProcessWithTimeout {
        param(
            [Parameter(Mandatory)][string]$FilePath,
            [string[]]$ArgumentList = @(),
            [int]$TimeoutSec = 180
        )

        try {
            $proc = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -ErrorAction Stop
        } catch {
            return @{
                Started   = $false
                Completed = $false
                TimedOut  = $false
                ExitCode  = $null
                Error     = $_.Exception.Message
            }
        }

        $timedOut = $false
        try {
            Wait-Process -Id $proc.Id -Timeout $TimeoutSec -ErrorAction Stop
        } catch {
            if ($proc -and -not $proc.HasExited) {
                $timedOut = $true
            }
        }

        if ($timedOut) {
            try {
                # Kill process tree to avoid orphan installer children.
                & taskkill.exe /PID $proc.Id /T /F > $null 2>&1
            } catch {}
            return @{
                Started   = $true
                Completed = $false
                TimedOut  = $true
                ExitCode  = $null
                Error     = 'timeout'
            }
        }

        $exitCode = $null
        try {
            $proc.Refresh()
            $exitCode = $proc.ExitCode
        } catch {}

        return @{
            Started   = $true
            Completed = $true
            TimedOut  = $false
            ExitCode  = $exitCode
            Error     = $null
        }
    }

    function Download-FastCopy {
        param([string]$AppsDir)

        Write-Host ''
        Write-Centered $L.DLFastCopy 'Yellow'

        if (-not (Test-Path $AppsDir)) {
            New-Item -ItemType Directory -Path $AppsDir -Force | Out-Null
        }
        $installer = Join-Path $AppsDir 'FastCopy_installer.exe'
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $FASTCOPY_URL -OutFile $installer -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            $sz = (Get-Item $installer).Length
            if ($sz -gt 200KB) {
                Write-Centered ($L.FCInstOk -f (Format-Size $sz)) 'Green'
                Write-Centered $L.FCExtract 'DarkGray'
                $extractResult = Invoke-ExternalProcessWithTimeout -FilePath $installer -ArgumentList @(
                    '/EXTRACT64', '/NOSUBDIR', '/AGREE_LICENSE', ("/DIR=`"$AppsDir`"")
                ) -TimeoutSec 180
                if ($extractResult.TimedOut) {
                    Write-Centered '[!] FastCopy extraction timed out (>180s). Trying /SILENT ...' 'Yellow'
                } elseif (-not $extractResult.Started) {
                    Write-Centered ("[!] Could not start extractor: {0}" -f $extractResult.Error) 'Yellow'
                }

                if ($extractResult.Completed -and $extractResult.ExitCode -eq 0 -and (Test-Path (Join-Path $AppsDir 'FastCopy.exe'))) {
                    Write-Centered $L.FCExtractOk 'Green'
                    Remove-Item $installer -ErrorAction SilentlyContinue
                } else {
                    # /EXTRACT64 failed or not supported — retry with /SILENT install
                    Write-Centered $L.FCExtractF 'Yellow'
                    $silentResult = Invoke-ExternalProcessWithTimeout -FilePath $installer -ArgumentList @(
                        '/SILENT', '/AGREE_LICENSE', ("/DIR=`"$AppsDir`"")
                    ) -TimeoutSec 180
                    if ($silentResult.TimedOut) {
                        Write-Centered '[!] /SILENT install timed out (>180s). Leaving installer for manual run.' 'Yellow'
                    } elseif (-not $silentResult.Started) {
                        Write-Centered ("[!] Could not start /SILENT install: {0}" -f $silentResult.Error) 'Yellow'
                    }
                    if ($silentResult.Completed -and $silentResult.ExitCode -eq 0 -and (Test-Path (Join-Path $AppsDir 'FastCopy.exe'))) {
                        Write-Centered $L.FCExtractOk 'Green'
                        Remove-Item $installer -ErrorAction SilentlyContinue
                        return $true
                    }
                    # Keep installer on USB for manual install when auto-mode fails.
                    Write-Centered ("[!] Installer kept for manual install: {0}" -f $installer) 'DarkGray'
                    return $false
                }
                return $true
            }
        } catch {
            Write-Centered ($L.FCDLFail -f $_.Exception.Message) 'Yellow'
        }
        return $false
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
        if (-not $ForceRedownload -and (Test-Path $msiFile) -and ((Get-Item $msiFile).Length -gt 50MB)) {
            Write-Centered ($L.PS7Exists -f $msiFile) 'Green'
            return $true
        }
        $tmpFile = "$msiFile.download"
        try {
            $ProgressPreference = 'SilentlyContinue'
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
            Invoke-WebRequest -Uri $PS7_URL -OutFile $tmpFile -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
            $sz = (Get-Item $tmpFile).Length
            if ($sz -gt 50MB) {
                Move-Item -LiteralPath $tmpFile -Destination $msiFile -Force
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

        function Find-FirstExistingPath {
            param([string[]]$Candidates)
            foreach ($c in $Candidates) {
                if ([string]::IsNullOrWhiteSpace($c)) { continue }
                $p = [Environment]::ExpandEnvironmentVariables($c)
                if (Test-Path -LiteralPath $p) { return $p }
            }
            return $null
        }

        function Resolve-DepPath {
            param(
                [string]$DepName,
                [string[]]$FallbackPaths
            )
            $resolved = $null
            if (Get-Command Resolve-AtlasDependency -ErrorAction SilentlyContinue) {
                try { $resolved = Resolve-AtlasDependency -Name $DepName -InstallIfMissing } catch {}
            }
            if (-not $resolved) {
                $resolved = Find-FirstExistingPath -Candidates $FallbackPaths
            }
            return $resolved
        }

        $copiedCount = 0

        $gpuzSrc = Resolve-DepPath -DepName 'GPUZ' -FallbackPaths @(
            'C:\Program Files (x86)\GPU-Z\GPU-Z.exe',
            'C:\Program Files\GPU-Z\GPU-Z.exe'
        )
        if ($gpuzSrc -and (Test-Path -LiteralPath $gpuzSrc)) {
            Copy-Item -LiteralPath $gpuzSrc -Destination (Join-Path $GpuToolsDir 'GPU-Z.exe') -Force
            $copiedCount++
        }

        $hwSrc = Resolve-DepPath -DepName 'HWiNFO' -FallbackPaths @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe'
        )
        if ($hwSrc -and (Test-Path -LiteralPath $hwSrc)) {
            Copy-Item -LiteralPath $hwSrc -Destination (Join-Path $GpuToolsDir 'HWiNFO64.exe') -Force
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
            robocopy $furSrcDir $furDstDir /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            if (Test-Path -LiteralPath (Join-Path $furDstDir 'furmark.exe')) {
                $copiedCount++
            }
        }

        $hasGpuZ = Test-Path -LiteralPath (Join-Path $GpuToolsDir 'GPU-Z.exe')
        $hasFur = Test-Path -LiteralPath (Join-Path $GpuToolsDir 'FurMark2_x64\furmark.exe')
        $hasHw = Test-Path -LiteralPath (Join-Path $GpuToolsDir 'HWiNFO64.exe')

        if ($hasGpuZ -and $hasFur) {
            Write-Centered $L.GPUDepsDone 'Green'
            return $true
        }

        if ($copiedCount -gt 0 -or $hasHw) {
            Write-Centered ($L.GPUDepsDone + ' (partial)') 'Yellow'
            return $true
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

        function Find-FirstExistingPath {
            param([string[]]$Candidates)
            foreach ($c in $Candidates) {
                if ([string]::IsNullOrWhiteSpace($c)) { continue }
                $p = [Environment]::ExpandEnvironmentVariables($c)
                if (Test-Path -LiteralPath $p) { return $p }
            }
            return $null
        }

        function Resolve-DepPath {
            param(
                [string]$DepName,
                [string[]]$FallbackPaths
            )
            $resolved = $null
            if (Get-Command Resolve-AtlasDependency -ErrorAction SilentlyContinue) {
                try { $resolved = Resolve-AtlasDependency -Name $DepName -InstallIfMissing } catch {}
            }
            if (-not $resolved) {
                $resolved = Find-FirstExistingPath -Candidates $FallbackPaths
            }
            return $resolved
        }

        function Copy-TreeSafely {
            param(
                [Parameter(Mandatory)][string]$SourceDir,
                [Parameter(Mandatory)][string]$DestinationDir
            )

            if (-not (Test-Path -LiteralPath $SourceDir)) { return $false }

            if (-not (Test-Path -LiteralPath $DestinationDir)) {
                New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
            }

            $copyOk = $false
            $robo = Get-Command robocopy.exe -ErrorAction SilentlyContinue
            if ($robo) {
                # Delta sync (size/date) to avoid recopying unchanged trees.
                # /XJ avoids junction loops and /FFT improves compatibility across filesystems.
                & $robo.Source $SourceDir $DestinationDir /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP /XJ /FFT /COPY:DAT /DCOPY:DAT | Out-Null
                $rc = $LASTEXITCODE
                if ($rc -ge 0 -and $rc -lt 8) {
                    $copyOk = $true
                }
            }

            if (-not $copyOk) {
                try {
                    # Fallback delta sync using date/size, and SHA256 only when needed.
                    $sourceRoot = (Resolve-Path -LiteralPath $SourceDir -ErrorAction Stop).Path
                    $destRoot = (Resolve-Path -LiteralPath $DestinationDir -ErrorAction Stop).Path
                    $sourceFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Force -ErrorAction Stop

                    foreach ($srcFile in $sourceFiles) {
                        $relative = $srcFile.FullName.Substring($sourceRoot.Length).TrimStart('\')
                        $dstPath = Join-Path $destRoot $relative
                        $dstDir = Split-Path -Parent $dstPath
                        if (-not (Test-Path -LiteralPath $dstDir)) {
                            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
                        }

                        $needsCopy = $true
                        if (Test-Path -LiteralPath $dstPath) {
                            $dstFile = Get-Item -LiteralPath $dstPath -ErrorAction SilentlyContinue
                            if ($dstFile -and $dstFile.Length -eq $srcFile.Length) {
                                if ($dstFile.LastWriteTimeUtc -eq $srcFile.LastWriteTimeUtc) {
                                    $needsCopy = $false
                                } else {
                                    $srcHash = (Get-FileHash -LiteralPath $srcFile.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                                    $dstHash = (Get-FileHash -LiteralPath $dstFile.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                                    if ($srcHash -and $dstHash -and $srcHash -eq $dstHash) {
                                        $needsCopy = $false
                                    }
                                }
                            }
                        }

                        if ($needsCopy) {
                            Copy-Item -LiteralPath $srcFile.FullName -Destination $dstPath -Force -ErrorAction Stop
                            try { (Get-Item -LiteralPath $dstPath -ErrorAction SilentlyContinue).LastWriteTimeUtc = $srcFile.LastWriteTimeUtc } catch {}
                        }
                    }
                    $copyOk = $true
                } catch {
                    $copyOk = $false
                }
            }

            return $copyOk
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
            Copy-Item -LiteralPath $cpuzSrc -Destination (Join-Path $DiagToolsDir $cpuzDstName) -Force
            $copiedCount++
        }

        $bsodSrc = Resolve-DepPath -DepName 'BlueScreenView' -FallbackPaths @(
            'C:\Program Files\NirSoft\BlueScreenView\BlueScreenView.exe',
            'C:\Program Files (x86)\NirSoft\BlueScreenView\BlueScreenView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\bluescreenview.exe'
        )
        if ($bsodSrc -and (Test-Path -LiteralPath $bsodSrc)) {
            Copy-Item -LiteralPath $bsodSrc -Destination (Join-Path $DiagToolsDir 'BlueScreenView.exe') -Force
            $copiedCount++
        }

        $batSrc = Resolve-DepPath -DepName 'BatteryInfoView' -FallbackPaths @(
            'C:\Program Files\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            'C:\Program Files (x86)\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\batteryinfoview.exe'
        )
        if ($batSrc -and (Test-Path -LiteralPath $batSrc)) {
            Copy-Item -LiteralPath $batSrc -Destination (Join-Path $DiagToolsDir 'BatteryInfoView.exe') -Force
            $copiedCount++
        }

        $hwSrc = Resolve-DepPath -DepName 'HWiNFO' -FallbackPaths @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe'
        )
        if ($hwSrc -and (Test-Path -LiteralPath $hwSrc)) {
            Copy-Item -LiteralPath $hwSrc -Destination (Join-Path $DiagToolsDir 'HWiNFO64.exe') -Force
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
                $ok = Copy-TreeSafely -SourceDir $cdiDir -DestinationDir $cdiDstDir
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
                $ok = Copy-TreeSafely -SourceDir $cdmDir -DestinationDir $cdmDstDir
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
            return $true
        }

        Write-Centered $L.DiagDepsNone 'Yellow'
        return $false
    }

    function Save-AtlasTools {
        param(
            [string]$ToolsDir,
            [switch]$ForceRedownload
        )

        Write-Host ''
        Write-Centered $L.ToolsHeader 'Yellow'

        if (-not (Test-Path -LiteralPath $ToolsDir)) {
            New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
        }

        $toolNames = @(
            'Invoke-ActualizarPowerShell',
            'Invoke-AIReadiness',
            'Invoke-AuditoriaRouter',
            'Invoke-Deduplicador',
            'Invoke-DiagnosticoEventos',
            'Invoke-DiagnosticoMaster',
            'Invoke-EntregaPC',
            'Invoke-ExtraerLicencias',
            'Invoke-FastCopy',
            'Invoke-Fase0',
            'Invoke-GestorBitLocker',
            'Invoke-GPUCheck',
            'Invoke-HostsManager',
            'Invoke-InstalarPaquetes',
            'Invoke-InstalarRuntimes',
            'Invoke-KeyboardDoctor',
            'Invoke-MantenimientoPRO',
            'Invoke-MenorPrivilegio',
            'Invoke-PartsUpgrade',
            'Invoke-Personalizacion',
            'Invoke-PrepararUSB',
            'Invoke-PrinterDoctor',
            'Invoke-Robocopy',
            'Invoke-SelectorDNS',
            'Invoke-StopServices',
            'Invoke-InstalarMicrosoftStore'
        )

        $ok = 0; $skipped = 0; $failed = 0
        $bust = [Guid]::NewGuid().ToString('N')
        $ProgressPreference = 'SilentlyContinue'

        foreach ($name in $toolNames) {
            $dest = Join-Path $ToolsDir "$name.ps1"
            if ((-not $ForceRedownload) -and (Test-Path -LiteralPath $dest)) {
                $skipped++
                continue
            }
            $tmp = "$dest.download"
            $url = "$TOOLS_BASE_URL/$name.ps1?v=$bust"
            try {
                if (Test-Path -LiteralPath $tmp) {
                    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
                }
                Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
                if ((Get-Item $tmp).Length -gt 100) {
                    Move-Item -LiteralPath $tmp -Destination $dest -Force
                    $ok++
                } else {
                    Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
                    $failed++
                }
            } catch {
                $failed++
                if (Test-Path -LiteralPath $tmp) {
                    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
                }
                Write-Centered "  [!] $name : $($_.Exception.Message)" 'Yellow'
            }
        }

        if ($failed -eq 0) {
            Write-Centered ($L.ToolsDone -f $ok, $skipped) 'Green'
        } else {
            Write-Centered ($L.ToolsPartial -f ($ok + $skipped), $failed) 'Yellow'
        }
        return ($failed -eq 0)
    }

    function Save-MicrosoftStoreBundle {
        param(
            [string]$BundleDir,
            [switch]$ForceRedownload
        )

        Write-Host ''
        Write-Centered $L.StoreHeader 'Yellow'

        if (-not (Test-Path -LiteralPath $BundleDir)) {
            New-Item -ItemType Directory -Path $BundleDir -Force | Out-Null
        }

        $onlineOnlyFlag = Join-Path $BundleDir 'ONLINE_MODE_REQUIRED.flag'
        $ok = 0; $skipped = 0; $failed = 0; $unavailable = 0
        $storeBundleUnavailable = $false
        $ProgressPreference = 'SilentlyContinue'

        foreach ($pkg in $STORE_PACKAGES) {
            $dest = Join-Path $BundleDir $pkg.Name
            if ((-not $ForceRedownload) -and (Test-Path -LiteralPath $dest)) {
                $skipped++
                continue
            }
            Write-Centered ("  [>] $($pkg.Name) (~$($pkg.SizeMB) MB)...") 'Gray'

            $candidateUrls = @()
            $mirrorUrl = [string]$env:ATLAS_STORE_BUNDLE_URL
            if ($pkg.Name -ieq 'Microsoft.WindowsStore.appxbundle' -and -not [string]::IsNullOrWhiteSpace($mirrorUrl)) {
                $candidateUrls += $mirrorUrl.Trim()
            }
            if ($pkg.Url) { $candidateUrls += [string]$pkg.Url }
            $candidateUrls = @($candidateUrls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

            $downloaded = $false
            $manifestBlocked = $false
            $lastError = $null

            foreach ($url in $candidateUrls) {
                $tmp = "$dest.download"
                try {
                    if (Test-Path -LiteralPath $tmp) {
                        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
                    }

                    $resp = Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
                    $len = (Get-Item -LiteralPath $tmp).Length
                    $contentType = ''
                    try { $contentType = [string]$resp.Headers['Content-Type'] } catch {}

                    $isManifestResponse = $false
                    if ($pkg.Name -ieq 'Microsoft.WindowsStore.appxbundle') {
                        if ($contentType -match 'application/json') {
                            $isManifestResponse = $true
                        } elseif ($len -lt 100KB) {
                            try {
                                $probe = Get-Content -Raw -LiteralPath $tmp -Encoding UTF8
                                $jsonProbe = $probe | ConvertFrom-Json -ErrorAction Stop
                                if ($jsonProbe.Data -and $jsonProbe.Data.PackageIdentifier) {
                                    $isManifestResponse = $true
                                }
                            } catch {}
                        }
                    }

                    if ($isManifestResponse) {
                        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
                        $manifestBlocked = $true
                        Write-Centered ($L.StoreManifestAuth -f $pkg.Name) 'Yellow'
                        continue
                    }

                    if ($len -gt 10KB) {
                        Move-Item -LiteralPath $tmp -Destination $dest -Force
                        $ok++
                        $downloaded = $true
                        break
                    } else {
                        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
                        $lastError = 'download incomplete'
                    }
                } catch {
                    $lastError = $_.Exception.Message
                    if (Test-Path -LiteralPath $tmp) {
                        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            if (-not $downloaded) {
                if ($manifestBlocked -and $pkg.Name -ieq 'Microsoft.WindowsStore.appxbundle') {
                    $unavailable++
                    $storeBundleUnavailable = $true
                    if ([string]::IsNullOrWhiteSpace([string]$env:ATLAS_STORE_BUNDLE_URL)) {
                        Write-Centered $L.StoreMirrorHint 'DarkGray'
                    }
                } else {
                    $failed++
                    if ($lastError) {
                        Write-Centered "  [!] $($pkg.Name): $lastError" 'Yellow'
                    }
                }
            }
        }

        if ($failed -eq 0 -and $unavailable -eq 0) {
            Write-Centered ($L.StoreDone -f $ok, $skipped) 'Green'
        } elseif ($failed -eq 0) {
            Write-Centered ($L.StorePartialSoft -f ($ok + $skipped), $unavailable) 'Yellow'
        } elseif ($unavailable -eq 0) {
            Write-Centered ($L.StorePartial -f ($ok + $skipped), $failed) 'Yellow'
        } else {
            Write-Centered ($L.StoreMixed -f ($ok + $skipped), $unavailable, $failed) 'Yellow'
        }

        if ($storeBundleUnavailable) {
            $flagBody = @(
                '# Atlas PC Support - Microsoft Store online fallback required'
                '# Store appxbundle could not be obtained from source (manifest/auth-required).'
                '# Invoke-InstalarMicrosoftStore will skip offline expectation and use winget online mode.'
                ('# Generated: ' + (Get-Date).ToString('s'))
            ) -join [Environment]::NewLine
            [System.IO.File]::WriteAllText($onlineOnlyFlag, $flagBody, [System.Text.UTF8Encoding]::new($true))
            Write-Centered $L.StoreOnlineAuto 'DarkGray'
        } elseif (Test-Path -LiteralPath $onlineOnlyFlag) {
            Remove-Item -LiteralPath $onlineOnlyFlag -Force -ErrorAction SilentlyContinue
        }

        return ($failed -eq 0)
    }

    function Write-RunBat {
        param([string]$Path, [string]$FailMsg)
        # run.bat delegates the heavy lifting to run-launcher.ps1 (which
        # handles Start-Transcript + exception trap + pause-on-error). That
        # way when launcher.ps1 throws before reaching the WPF ShowDialog,
        # the user still sees the exception and a log file is left on the
        # USB next to run.bat for post-mortem.
        $lines = @(
            '@echo off',
            'setlocal',
            'chcp 65001 > nul 2>&1',
            'title ATLAS PC SUPPORT - Offline Launcher',
            'cd /d "%~dp0"',
            '',
            'echo.',
            'echo ============================================================',
            'echo    ATLAS PC SUPPORT - Offline Launcher',
            'echo ============================================================',
            'echo.',
            'echo Log file: %~dp0atlas-offline.log',
            'echo.',
            '',
            'echo [1/2] Checking / updating launcher ...',
            'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap.ps1"',
            'if errorlevel 1 (',
            '    echo.',
            ('    ' + $FailMsg),
            '    pause',
            '    exit /b 1',
            ')',
            '',
            'echo.',
            'echo [2/2] Launching panel ...',
            'echo.',
            'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-launcher.ps1"',
            'set "RC=%errorlevel%"',
            'if not "%RC%"=="0" (',
            '    echo.',
            '    echo ============================================================',
            '    echo [!] launcher.ps1 exited with error code %RC%.',
            '    echo [!] See the error above and the log: %~dp0atlas-offline.log',
            '    echo ============================================================',
            '    pause',
            '    exit /b %RC%',
            ')',
            '',
            'endlocal'
        )
        [System.IO.File]::WriteAllLines($Path, $lines, [System.Text.ASCIIEncoding]::new())
    }

    function Write-RunLauncherWrapper {
        param([string]$Path)
        $utf8 = [System.Text.UTF8Encoding]::new($true)
        $content = @'
# ============================================================
# Atlas PC Support - Run launcher wrapper (USB offline)
# Captures transcript + traps exceptions so the user actually
# sees errors when launcher.ps1 fails before ShowDialog.
# ============================================================

$here        = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher    = Join-Path $here 'launcher.ps1'
$transcript  = Join-Path $here 'atlas-offline.log'
$env:ATLAS_OFFLINE_ROOT = $here

if (-not (Test-Path -LiteralPath $launcher)) {
    Write-Host ''
    Write-Host ('[X] launcher.ps1 not found at: ' + $launcher) -ForegroundColor Red
    Write-Host 'Press ENTER to exit.' -ForegroundColor Yellow
    [void](Read-Host)
    exit 2
}

try { Stop-Transcript | Out-Null } catch {}
try {
    Start-Transcript -Path $transcript -Append -ErrorAction SilentlyContinue | Out-Null
} catch {}

$ok = $false
try {
    & $launcher
    $ok = $true
} catch {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '  [X] Fatal error while loading the Atlas panel:' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host ('  ' + $_.Exception.Message) -ForegroundColor Yellow
    if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) {
        Write-Host ''
        Write-Host ('  at: ' + $_.InvocationInfo.PositionMessage) -ForegroundColor DarkGray
    }
    if ($_.ScriptStackTrace) {
        Write-Host ''
        Write-Host '  Stack trace:' -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host ('  Full log: ' + $transcript) -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Press ENTER to exit.' -ForegroundColor Yellow
    [void](Read-Host)
} finally {
    try { Stop-Transcript | Out-Null } catch {}
}

if (-not $ok) { exit 1 }
exit 0
'@
        [System.IO.File]::WriteAllText($Path, $content, $utf8)
    }

    function Write-Bootstrap {
        param([string]$Path, [int]$MaxAgeDays)
        $utf8 = [System.Text.UTF8Encoding]::new($true)
        $msgNoLocal = $L.BootNoLocal
        $msgStale   = $L.BootStale
        $msgFresh   = $L.BootFresh
        $msgDLOk    = $L.BootDLOk
        $msgDLFail  = $L.BootDLFail
        $msgNoNet   = $L.BootNoNet
        $msgNoBoth  = $L.BootNoBoth
        $title      = $L.BootTitle
        $desc1      = ($L.BootDesc1 -f $MaxAgeDays)
        $desc2      = $L.BootDesc2
        $content = @"
# ============================================================
$title
$desc1
$desc2
# ============================================================

`$ErrorActionPreference = 'Continue'
`$here = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$launcher = Join-Path `$here 'launcher.ps1'
`$maxAge = [TimeSpan]::FromDays($MaxAgeDays)

`$needsDownload = `$false
if (-not (Test-Path `$launcher)) {
    `$needsDownload = `$true
    Write-Host '$msgNoLocal' -ForegroundColor Yellow
} else {
    try {
        `$age = (Get-Date) - (Get-Item `$launcher).LastWriteTime
        if (`$age -gt `$maxAge) {
            `$needsDownload = `$true
            Write-Host ("$msgStale" -f [int]`$age.TotalDays) -ForegroundColor Yellow
        } else {
            Write-Host ("$msgFresh" -f [int]`$age.TotalDays) -ForegroundColor Green
        }
    } catch {
        `$needsDownload = `$true
    }
}

if (`$needsDownload) {
    # Cache-bust to defeat any stale Cloudflare/CDN edge cache.
    `$bust = [Guid]::NewGuid().ToString('N')
    `$urls = @(
        ('https://toolspanel.atlaspcsupport.com/?v=' + `$bust),
        ('https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/launcher.ps1?v=' + `$bust)
    )
    `$noCacheHdr = @{ 'Cache-Control' = 'no-cache'; 'Pragma' = 'no-cache' }
    `$ok = `$false
    foreach (`$u in `$urls) {
        try {
            `$ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri `$u -OutFile `$launcher -UseBasicParsing -TimeoutSec 60 -Headers `$noCacheHdr -ErrorAction Stop
            if ((Get-Item `$launcher).Length -gt 100KB) {
                Write-Host ("$msgDLOk" -f `$u) -ForegroundColor Green
                `$ok = `$true; break
            }
        } catch {
            Write-Host ("$msgDLFail" -f `$_.Exception.Message) -ForegroundColor Yellow
        }
    }
    if (-not `$ok) {
        if (Test-Path `$launcher) {
            Write-Host '$msgNoNet' -ForegroundColor Yellow
            # Fall through to BOM repair below.
        } else {
            Write-Host '$msgNoBoth' -ForegroundColor Red
            exit 1
        }
    }
}

# --- BOM repair ---
# Windows PowerShell 5.1 reads BOM-less .ps1 as CP1252, which mojibakes
# accents and emojis embedded in the launcher (e.g. "Diagnóstico" ->
# "DiagnÃ³stico") and makes the whole script fail to parse. GitHub raw
# serves the committed bytes verbatim, and earlier build.ps1 versions
# omitted the BOM on pwsh 7+, so USBs in the field may have a BOM-less
# copy. Self-heal by prepending the BOM if it's missing.
try {
    if (Test-Path `$launcher) {
        `$stream = [System.IO.File]::OpenRead(`$launcher)
        `$head = New-Object byte[] 3
        `$read = `$stream.Read(`$head, 0, 3)
        `$stream.Close()
        `$hasBom = (`$read -ge 3 -and `$head[0] -eq 0xEF -and `$head[1] -eq 0xBB -and `$head[2] -eq 0xBF)
        if (-not `$hasBom) {
            `$bytes = [System.IO.File]::ReadAllBytes(`$launcher)
            `$bom = [byte[]](0xEF, 0xBB, 0xBF)
            `$new = New-Object byte[] (`$bom.Length + `$bytes.Length)
            [Array]::Copy(`$bom, 0, `$new, 0, `$bom.Length)
            [Array]::Copy(`$bytes, 0, `$new, `$bom.Length, `$bytes.Length)
            [System.IO.File]::WriteAllBytes(`$launcher, `$new)
            Write-Host '  [OK] Added UTF-8 BOM to launcher.ps1 (PS 5.1 compatibility).' -ForegroundColor DarkGray
        }
    }
} catch {
    Write-Host ('  [!] BOM repair skipped: ' + `$_.Exception.Message) -ForegroundColor DarkGray
}

exit 0
"@
        [System.IO.File]::WriteAllText($Path, $content, $utf8)
    }

    function Write-Readme {
        param([string]$Path, [string]$DriveLetter)
        $body = $READMES[$lang]
        if (-not $body) { $body = $READMES['en'] }
        $body = $body.Replace('{ROOT}', $USB_ROOT_NAME).Replace('{DAYS}', $MAX_LAUNCHER_AGE_DAYS).Replace('{LETTER}', $DriveLetter)
        [System.IO.File]::WriteAllText($Path, $body, [System.Text.UTF8Encoding]::new($true))
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

    # ---- Launcher + bootstrap scripts (always refreshed) ----
    $launcherDest = Join-Path $targetDir 'launcher.ps1'
    $launcherEst = Get-StageEstimate -StageKey 'Launcher' -UseDeltaProfile:$useDeltaEstimate
    $ok = Invoke-StageWithTelemetry -StageName $L.StageLblLauncher `
        -EstimateMinSec $launcherEst.Min -EstimateMaxSec $launcherEst.Max `
        -MeasurePaths @($launcherDest) `
        -Action { Download-Launcher -TargetFile $launcherDest }
    if (-not $ok) {
        Write-Host ''
        Write-Centered $L.DLLnchFatal 'Red'
        Wait-PrepararUSBCompat -Message $L.EnterExit
        return
    }

    $bootstrapDest = Join-Path $targetDir 'bootstrap.ps1'
    Write-Bootstrap -Path $bootstrapDest -MaxAgeDays $MAX_LAUNCHER_AGE_DAYS
    Write-Centered $L.BootOk 'Green'

    $runBatDest = Join-Path $targetDir 'run.bat'
    Write-RunBat -Path $runBatDest -FailMsg $L.RunFail
    Write-Centered $L.RunOk 'Green'

    $wrapperDest = Join-Path $targetDir 'run-launcher.ps1'
    Write-RunLauncherWrapper -Path $wrapperDest

    $readmeDest = Join-Path $targetDir 'README.txt'
    Write-Readme -Path $readmeDest -DriveLetter $drive
    Write-Centered $L.ReadmeOk 'Green'

    # ---- Dependencies ----
    # On fresh install: ask per-dep. On update: honour the chosen mode silently.
    $fcDir        = Join-Path $appsDir 'FastCopy'
    $fcExe        = Join-Path $fcDir 'FastCopy.exe'
    $depsDir      = Join-Path $targetDir 'deps'
    $ps7Msi       = Join-Path $depsDir "PowerShell-$PS7_VERSION-win-x64.msi"
    $gpuToolsDir  = Join-Path $targetDir 'deps\GPUCheck\tools'
    $gpuPresence  = Join-Path $gpuToolsDir 'GPU-Z.exe'
    $diagToolsDir = Join-Path $targetDir 'deps\DiagnosticoMaster\tools'
    $diagPresence = Join-Path $diagToolsDir 'BlueScreenView.exe'
    $usbToolsDir  = Join-Path $targetDir 'deps\tools'

    # FastCopy
    if ($isUpdate) {
        if (Test-NeedsDownload $fcExe) {
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
        if (Test-NeedsDownload $ps7Msi) {
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
        if (Test-NeedsDownload $gpuPresence) {
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
        $hasCdiOffline = (Test-Path (Join-Path $diagToolsDir 'CrystalDiskInfo\DiskInfo64.exe')) -or (Test-Path (Join-Path $diagToolsDir 'DiskInfo64.exe'))
        $hasCdmOffline = (Test-Path (Join-Path $diagToolsDir 'CrystalDiskMark\DiskMark64.exe')) -or (Test-Path (Join-Path $diagToolsDir 'DiskMark64.exe'))
        $hasHwOffline = Test-Path (Join-Path $diagToolsDir 'HWiNFO64.exe')
        if ((Test-NeedsDownload $diagPresence) -or -not $hasCdiOffline -or -not $hasCdmOffline -or -not $hasHwOffline) {
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

    # Tool scripts (deps\tools\) — for ToolRunner USB offline mode
    $toolsPresence = Join-Path $usbToolsDir 'Invoke-MantenimientoPRO.ps1'
    if ($isUpdate) {
        if (Test-NeedsDownload $toolsPresence) {
            $toolsEst = Get-StageEstimate -StageKey 'Tools' -UseDeltaProfile:$useDeltaEstimate
            Invoke-StageWithTelemetry -StageName $L.StageLblTools `
                -EstimateMinSec $toolsEst.Min -EstimateMaxSec $toolsEst.Max `
                -MeasurePaths @($usbToolsDir) `
                -Action { Save-AtlasTools -ToolsDir $usbToolsDir -ForceRedownload:$updateAll } | Out-Null
        } else {
            Write-Centered ($L.DepSkipped -f 'tool scripts') 'DarkGray'
        }
    } else {
        Write-Host ''
        Write-Centered $L.AskTools 'Yellow'
        Write-Centered $L.AskToolsNote 'DarkGray'
        $dtl = Read-Host '  '
        if ($dtl -match '^[SsYy]$') {
            $toolsEst = Get-StageEstimate -StageKey 'Tools' -UseDeltaProfile:$false
            Invoke-StageWithTelemetry -StageName $L.StageLblTools `
                -EstimateMinSec $toolsEst.Min -EstimateMaxSec $toolsEst.Max `
                -MeasurePaths @($usbToolsDir) `
                -Action { Save-AtlasTools -ToolsDir $usbToolsDir } | Out-Null
        }
    }

    # Microsoft Store bundle (deps\MicrosoftStore\) — for Invoke-InstalarMicrosoftStore offline mode
    $storeBundleDir  = Join-Path $targetDir 'deps\MicrosoftStore'
    $storePresence   = Join-Path $storeBundleDir 'Microsoft.WindowsStore.appxbundle'
    if ($isUpdate) {
        if (Test-NeedsDownload $storePresence) {
            $storeEst = Get-StageEstimate -StageKey 'Store' -UseDeltaProfile:$useDeltaEstimate
            Invoke-StageWithTelemetry -StageName $L.StageLblStore `
                -EstimateMinSec $storeEst.Min -EstimateMaxSec $storeEst.Max `
                -MeasurePaths @($storeBundleDir) `
                -Action { Save-MicrosoftStoreBundle -BundleDir $storeBundleDir -ForceRedownload:$updateAll } | Out-Null
        } else {
            Write-Centered ($L.DepSkipped -f 'Microsoft Store bundle') 'DarkGray'
        }
    } else {
        Write-Host ''
        Write-Centered $L.AskStore 'Yellow'
        Write-Centered $L.AskStoreNote 'DarkGray'
        $dms = Read-Host '  '
        if ($dms -match '^[SsYy]$') {
            $storeEst = Get-StageEstimate -StageKey 'Store' -UseDeltaProfile:$false
            Invoke-StageWithTelemetry -StageName $L.StageLblStore `
                -EstimateMinSec $storeEst.Min -EstimateMaxSec $storeEst.Max `
                -MeasurePaths @($storeBundleDir) `
                -Action { Save-MicrosoftStoreBundle -BundleDir $storeBundleDir } | Out-Null
        }
    }

    Write-Host ''
    Write-Centered $L.DoneSep 'Cyan'
    Write-Centered $L.DoneTitle 'Green'
    Write-Centered $L.DoneSep 'Cyan'
    Write-Host ''
    Write-Centered ($L.DonePath -f $targetDir) 'White'
    Write-Centered $L.DoneUsage 'Gray'
    Write-Host ''

    try { Start-Process explorer.exe $targetDir } catch {}
}
