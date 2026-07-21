# ============================================================
# Invoke-Robocopy  ->  Robocopy Mirror
#
# i18n: Option A (en default + full es secondary). Function name
# kept as Invoke-Robocopy for tools.json compatibility.
#
# Atlas PC Support
# ============================================================

function Invoke-Robocopy {
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
            WinTitle    = 'ATLAS PC SUPPORT - Robocopy Mirror v8'
            HeaderBar   = '=========================================================='
            HeaderTitle = '|     ATLAS PC SUPPORT - ROBOCOPY MIRROR v8              |'
            DriveUSB    = 'USB Removable'
            DriveUSBExt = 'External USB'
            DriveSSD    = 'SSD/NVMe'
            DriveHDD    = 'Mechanical HDD'
            DriveUnk    = 'Unknown'
            FolderDlg   = 'Select a folder'
            FolderDlgT  = 'Select {0} folder'
            FileDlgT    = 'Select a file'
            AllFilesFlt = 'All files (*.*)|*.*'
            DragHint    = '  DRAG here, type the path, or use the explorer:'
            OpenExpl    = '      [E] Open file explorer'
            BackExit    = '      [B] Back  [S] Quit'
            FolderOrFile= '      [1] Folder  [2] File'
            Verifying   = 'VERIFYING INTEGRITY...'
            FilesLine   = '    Files - Source: {0} | Dest: {1}'
            SizeLine    = '    Size  - Source: {0} | Dest: {1}'
            CountMatch  = 'MATCHES'
            CountDiff   = 'DIFFERENT (normal if files were excluded)'
            CountLine   = '    Count: {0}'
            MD5Line     = '    MD5 verification (sample of {0})...'
            NoFilesVerif= '    No files to verify.'
            CheckProg   = "`r    [{0}%] Verifying {1}/{2}..."
            MissingTag  = 'MISSING: {0}'
            CorruptTag  = 'CORRUPT: {0}'
            ErrorTag    = 'ERROR: {0}'
            IntegrityOK = '    [OK] MD5 INTEGRITY: {0}/{1} files verified'
            IntegrityKO = '    [!!] PROBLEMS: OK={0} | FAILED={1} | MISSING={2}'
            CopyingHdr  = 'COPYING... ({0} | MT:{1} | {2})'
            ResNoChange = 'NO CHANGES - Already copied'
            ResCopied   = 'COPIED SUCCESSFULLY'
            ResExtras   = 'Extra files in destination'
            ResCopyExtra= 'Copied + extras in destination'
            ResMismatch = 'Some files do not match'
            ResCopyMis  = 'Copied + mismatches'
            ResDone     = 'Completed (code {0})'
            ResError    = 'ERROR (code {0})'
            ResultLine  = '    RESULT: {0}'
            TimeLine    = '    Time:     {0}'
            CopiedLine  = '    Copied:   {0}'
            SpeedLine   = '    Speed:    {0} MB/s'
            LogLine     = '    Log:      {0}'
            Step1Src    = '  [1] SOURCE (drag, type path, or explorer):'
            Step1Prompt = 'SOURCE'
            ErrNotExist = '      [ERROR] Does not exist: {0}'
            FileTag     = '      [OK] FILE: {0} ({1})'
            FolderScan  = '      Scanning...'
            FolderTag   = '      [OK] FOLDER: {0}'
            FolderInfo  = '      {0} files | {1}'
            Step2Dst    = '  [2] DESTINATION:'
            Step2Prompt = 'DESTINATION'
            ErrUnreach  = '      [ERROR] Not accessible: {0}'
            ErrSameDir  = '      [ERROR] Source and destination are the same!'
            ErrRecursion= '      [ERROR] Destination inside source = recursion!'
            DiskTag     = '      [OK] Disk: {0}{1}'
            FreeTag     = '      Free: {0}'
            NoSpace     = '      [!!!] INSUFFICIENT SPACE'
            NeedHave    = '      Needed: {0} | Available: {1}'
            ForceBack   = '      [F] Force  [B] Back'
            Step3Name   = '  [3] Project name (ENTER = Backup):'
            NamePrompt  = '      NAME'
            DefaultName = 'Backup'
            Step4Mode   = '  [4] COPY MODE:'
            ModeFull    = '      [1] FULL - Copy everything (first time)'
            ModeIncr    = '      [2] INCREMENTAL - Only new/modified'
            BackOpt     = '      [B] Back'
            ModeFullL   = 'FULL'
            ModeIncrL   = 'INCREMENTAL'
            Step5Excl   = '  [5] EXCLUSIONS:'
            Excl1       = '      [1] None (copy everything)'
            Excl2       = '      [2] Temporary files (.tmp, .log, .bak, cache)'
            Excl3       = '      [3] ISOs and VMs (.iso, .vhd, .wim)'
            Excl4       = '      [4] Custom (write extensions)'
            ExclTmpOk   = '      [OK] Excluding temporary files and cache'
            ExclIsoOk   = '      [OK] Excluding ISOs and VMs'
            ExclCustom  = '      Extensions separated by comma (e.g. .mp4,.avi,.mkv):'
            ExclCustOk  = '      [OK] Excluding: {0}'
            PreviewHdr  = '==================== PREVIEW ===================='
            PrevType    = '    TYPE:      Single file'
            PrevType2   = '    TYPE:      Folder'
            PrevFile    = '    FILE:      {0}'
            PrevSize    = '    SIZE:      {0}'
            PrevSrc     = '    SOURCE:    {0}'
            PrevFiles   = '    FILES:     {0} | {1}'
            PrevDest    = '    DEST:      {0}'
            PrevDisk    = '    DISK:      {0}'
            PrevThreads = '    THREADS:   MT:{0} (auto)'
            PrevMode    = '    MODE:      {0}'
            PrevExcl    = '    EXCLUDE:   {0} file type(s) + {1} folder(s)'
            PrevETA     = '    ETA:       ~{0} (estimated for {1})'
            PreviewSep  = '================================================='
            PreviewAct  = '    [S] START COPY  [B] Back  [N] Cancel'
            VerifyAsk   = '    Verify MD5 integrity? [Y/N]'
            PostSep     = '    --------------------------------------------------------'
            PostA       = '    [A] Open destination folder'
            PostR       = '    [R] REPEAT with another destination (same source)'
            PostN       = '    [N] New copy (different source)'
            PostL       = '    [L] View log'
            PostS       = '    [S] Quit'
            FolderNotFnd= '    Folder not found.'
            NewDestHdr  = '    New DESTINATION:'
            UnreachShort= '    Path not accessible.'
            NewDiskLine = '    Disk: {0}{1} | MT:{2}'
            NewDestLine = '    Destination: {0}'
            CopyOrCancel= '    [S] Copy  [N] Cancel'
            VerifyMD5Q  = '    Verify MD5? [Y/N]'
            LogNotFnd   = '    Log not found.'
            ContinueY   = 'sS'
        }
        es = @{
            WinTitle    = 'ATLAS PC SUPPORT - Copia Inteligente v8'
            HeaderBar   = '=========================================================='
            HeaderTitle = '|     ATLAS PC SUPPORT - COPIA INTELIGENTE v8            |'
            DriveUSB    = 'USB Removible'
            DriveUSBExt = 'USB Externo'
            DriveSSD    = 'SSD/NVMe'
            DriveHDD    = 'HDD Mecanico'
            DriveUnk    = 'No detectado'
            FolderDlg   = 'Selecciona una carpeta'
            FolderDlgT  = 'Selecciona carpeta de {0}'
            FileDlgT    = 'Selecciona un archivo'
            AllFilesFlt = 'Todos los archivos (*.*)|*.*'
            DragHint    = '  ARRASTRA aqui, escribe la ruta, o usa el explorador:'
            OpenExpl    = '      [E] Abrir explorador de archivos'
            BackExit    = '      [B] Volver  [S] Salir'
            FolderOrFile= '      [1] Carpeta  [2] Archivo'
            Verifying   = 'VERIFICANDO INTEGRIDAD...'
            FilesLine   = '    Archivos - Origen: {0} | Destino: {1}'
            SizeLine    = '    Tamano   - Origen: {0} | Destino: {1}'
            CountMatch  = 'COINCIDE'
            CountDiff   = 'DIFERENTE (normal si se excluyeron archivos)'
            CountLine   = '    Conteo:  {0}'
            MD5Line     = '    Verificacion MD5 (muestra de {0})...'
            NoFilesVerif= '    Sin archivos para verificar.'
            CheckProg   = "`r    [{0}%] Verificando {1}/{2}..."
            MissingTag  = 'FALTA: {0}'
            CorruptTag  = 'CORRUPTO: {0}'
            ErrorTag    = 'ERROR: {0}'
            IntegrityOK = '    [OK] INTEGRIDAD MD5: {0}/{1} archivos verificados'
            IntegrityKO = '    [!!] PROBLEMAS: OK={0} | FALLOS={1} | FALTANTES={2}'
            CopyingHdr  = 'COPIANDO... ({0} | MT:{1} | {2})'
            ResNoChange = 'SIN CAMBIOS - Todo ya estaba copiado'
            ResCopied   = 'COPIADO EXITOSAMENTE'
            ResExtras   = 'Archivos extras en destino'
            ResCopyExtra= 'Copiado + extras en destino'
            ResMismatch = 'Algunos archivos no coinciden'
            ResCopyMis  = 'Copiado + no coincidencias'
            ResDone     = 'Completado (codigo {0})'
            ResError    = 'ERROR (codigo {0})'
            ResultLine  = '    RESULTADO: {0}'
            TimeLine    = '    Tiempo:    {0}'
            CopiedLine  = '    Copiado:   {0}'
            SpeedLine   = '    Velocidad: {0} MB/s'
            LogLine     = '    Log:       {0}'
            Step1Src    = '  [1] ORIGEN (arrastra, escribe ruta, o explorador):'
            Step1Prompt = 'ORIGEN'
            ErrNotExist = '      [ERROR] No existe: {0}'
            FileTag     = '      [OK] ARCHIVO: {0} ({1})'
            FolderScan  = '      Escaneando...'
            FolderTag   = '      [OK] CARPETA: {0}'
            FolderInfo  = '      {0} archivos | {1}'
            Step2Dst    = '  [2] DESTINO:'
            Step2Prompt = 'DESTINO'
            ErrUnreach  = '      [ERROR] No accesible: {0}'
            ErrSameDir  = '      [ERROR] Origen y destino son iguales!'
            ErrRecursion= '      [ERROR] Destino dentro del origen = recursion!'
            DiskTag     = '      [OK] Disco: {0}{1}'
            FreeTag     = '      Libre: {0}'
            NoSpace     = '      [!!!] ESPACIO INSUFICIENTE'
            NeedHave    = '      Necesitas: {0} | Disponible: {1}'
            ForceBack   = '      [F] Forzar  [B] Volver'
            Step3Name   = '  [3] Nombre del proyecto (ENTER = Respaldo):'
            NamePrompt  = '      NOMBRE'
            DefaultName = 'Respaldo'
            Step4Mode   = '  [4] MODO DE COPIA:'
            ModeFull    = '      [1] COMPLETA - Copia todo (primera vez)'
            ModeIncr    = '      [2] INCREMENTAL - Solo nuevos/modificados'
            BackOpt     = '      [B] Volver'
            ModeFullL   = 'COMPLETA'
            ModeIncrL   = 'INCREMENTAL'
            Step5Excl   = '  [5] EXCLUSIONES:'
            Excl1       = '      [1] Ninguna (copiar todo)'
            Excl2       = '      [2] Temporales (.tmp, .log, .bak, cache)'
            Excl3       = '      [3] ISOs y VMs (.iso, .vhd, .wim)'
            Excl4       = '      [4] Personalizado (escribir extensiones)'
            ExclTmpOk   = '      [OK] Excluyendo temporales y cache'
            ExclIsoOk   = '      [OK] Excluyendo ISOs y VMs'
            ExclCustom  = '      Extensiones separadas por coma (ej: .mp4,.avi,.mkv):'
            ExclCustOk  = '      [OK] Excluyendo: {0}'
            PreviewHdr  = '==================== PREVIEW ===================='
            PrevType    = '    TIPO:      Archivo suelto'
            PrevType2   = '    TIPO:      Carpeta'
            PrevFile    = '    ARCHIVO:   {0}'
            PrevSize    = '    TAMANO:    {0}'
            PrevSrc     = '    ORIGEN:    {0}'
            PrevFiles   = '    ARCHIVOS:  {0} | {1}'
            PrevDest    = '    DESTINO:   {0}'
            PrevDisk    = '    DISCO:     {0}'
            PrevThreads = '    HILOS:     MT:{0} (auto)'
            PrevMode    = '    MODO:      {0}'
            PrevExcl    = '    EXCLUIR:   {0} tipo(s) archivo + {1} carpeta(s)'
            PrevETA     = '    ETA:       ~{0} (estimado para {1})'
            PreviewSep  = '================================================='
            PreviewAct  = '    [S] INICIAR COPIA  [B] Volver  [N] Cancelar'
            VerifyAsk   = '    Verificar integridad MD5? [S/N]'
            PostSep     = '    --------------------------------------------------------'
            PostA       = '    [A] Abrir carpeta destino'
            PostR       = '    [R] REPETIR con OTRO destino (mismo origen)'
            PostN       = '    [N] Nueva copia (otro origen)'
            PostL       = '    [L] Ver log'
            PostS       = '    [S] Salir'
            FolderNotFnd= '    Carpeta no encontrada.'
            NewDestHdr  = '    Nuevo DESTINO:'
            UnreachShort= '    Ruta no accesible.'
            NewDiskLine = '    Disco: {0}{1} | MT:{2}'
            NewDestLine = '    Destino: {0}'
            CopyOrCancel= '    [S] Copiar  [N] Cancelar'
            VerifyMD5Q  = '    Verificar MD5? [S/N]'
            LogNotFnd   = '    Log no encontrado.'
            ContinueY   = 'sS'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Gray"
$Host.UI.RawUI.WindowTitle = $L.WinTitle
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 45) } catch {}
$ErrorActionPreference = "Continue"

function Write-Centered {
    param ([string]$Text, [string]$Color = "White")
    $W = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
    $Pad = [math]::Max(0, [math]::Floor(($W - $Text.Length) / 2))
    Write-Host (" " * $Pad + $Text) -ForegroundColor $Color
}

function _Write-AtlasHeaderCompat {
    param([string]$Title)
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title $Title -Color Yellow
        Write-Host ''
        return
    }
    Write-Host "`n"
    Write-Centered $L.HeaderBar "Cyan"
    Write-Centered $L.HeaderTitle "Yellow"
    Write-Centered $L.HeaderBar "Cyan"
    Write-Host ""
}

function _Write-AtlasStepCompat {
    param([string]$Message, [ConsoleColor]$FallbackColor = 'White')
    if ($atlasToolkitReady) {
        Write-AtlasStep $Message
        return
    }
    Write-Centered $Message $FallbackColor
}

function Clean-Path {
    param([string]$RawPath)
    return $RawPath.Trim().Trim('"').Trim("'").TrimEnd('\')
}

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N0} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Format-Duration {
    param([TimeSpan]$Duration)
    if ($Duration.TotalHours -ge 1) { return "{0}h {1}m {2}s" -f [int]$Duration.TotalHours, $Duration.Minutes, $Duration.Seconds }
    if ($Duration.TotalMinutes -ge 1) { return "{0}m {1}s" -f [int]$Duration.TotalMinutes, $Duration.Seconds }
    return "{0:N1}s" -f $Duration.TotalSeconds
}

function Get-FolderStats {
    param([string]$Path)
    $items = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
    $totalSize = ($items | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum
    if (-not $totalSize) { $totalSize = 0 }
    return @{ Files = $items.Count; Size = $totalSize; SizeMB = [math]::Round($totalSize / 1MB, 1) }
}

function Detect-DriveType {
    param([string]$DriveLetter)
    $letter = $DriveLetter.TrimEnd(':', '\')
    try {
        $vol = Get-Volume -DriveLetter $letter -ErrorAction Stop
        if ($vol.DriveType -eq 'Removable') {
            return @{ Type = "USB"; MT = 2; Desc = $L.DriveUSB; Color = "Yellow"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
        }
        $part = Get-Partition -DriveLetter $letter -ErrorAction Stop
        $disk = Get-Disk -Number $part.DiskNumber -ErrorAction Stop
        $phys = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $disk.Number.ToString() }

        if ($disk.BusType -eq 'USB') {
            return @{ Type = "USB"; MT = 2; Desc = $L.DriveUSBExt; Color = "Yellow"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
        }
        if ($disk.BusType -eq 'NVMe' -or ($phys -and $phys.MediaType -match 'SSD')) {
            return @{ Type = "SSD"; MT = 32; Desc = $L.DriveSSD; Color = "Green"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
        }
        return @{ Type = "HDD"; MT = 8; Desc = $L.DriveHDD; Color = "Cyan"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
    } catch {
        return @{ Type = "UNKNOWN"; MT = 8; Desc = $L.DriveUnk; Color = "Gray"; Label = ""; FreeBytes = 0 }
    }
}

function Select-FolderDialog {
    param([string]$Description = $L.FolderDlg)
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

function Select-FileDialog {
    param([string]$Title = $L.FileDlgT)
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = $L.AllFilesFlt
    $dialog.Multiselect = $false
    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

function Get-PathFromUser {
    param([string]$Prompt = $L.Step1Prompt, [string]$Mode = "any")

    Write-Host ""
    Write-Host $L.DragHint -ForegroundColor White
    Write-Host $L.OpenExpl -ForegroundColor Cyan
    Write-Host $L.BackExit -ForegroundColor DarkGray
    Write-Host ""
    $input = Read-Host "      ${Prompt}"

    if ($input -eq "S" -or $input -eq "s") { return "EXIT" }
    if ($input -eq "B" -or $input -eq "b") { return "BACK" }

    if ($input -eq "E" -or $input -eq "e") {
        if ($Mode -eq "folder") {
            $path = Select-FolderDialog -Description ($L.FolderDlgT -f $Prompt)
        } else {
            Write-Host $L.FolderOrFile -ForegroundColor White
            $tipo = Read-Host "      >"
            if ($tipo -eq "2") {
                $path = Select-FileDialog -Title $L.FileDlgT
            } else {
                $path = Select-FolderDialog -Description $L.FolderDlg
            }
        }
        if (-not $path) { return "BACK" }
        return $path
    }

    return Clean-Path $input
}

function Test-CopyIntegrity {
    param([string]$Origen, [string]$Destino, [int]$SampleSize = 15)

    Write-Host ""
    _Write-AtlasStepCompat -Message $L.Verifying -FallbackColor Yellow
    Write-Host ""

    $srcStats = Get-FolderStats $Origen
    $dstStats = Get-FolderStats $Destino

    Write-Host ($L.FilesLine -f $srcStats.Files, $dstStats.Files) -ForegroundColor Gray
    Write-Host ($L.SizeLine  -f (Format-Size $srcStats.Size), (Format-Size $dstStats.Size)) -ForegroundColor Gray

    $countMatch = ($srcStats.Files -eq $dstStats.Files)
    $countColor = if ($countMatch) { "Green" } else { "Yellow" }
    $countText  = if ($countMatch) { $L.CountMatch } else { $L.CountDiff }
    Write-Host ($L.CountLine -f $countText) -ForegroundColor $countColor

    Write-Host ""
    Write-Host ($L.MD5Line -f $SampleSize) -ForegroundColor DarkGray

    $srcFiles = Get-ChildItem -Path $Origen -Recurse -File -ErrorAction SilentlyContinue
    if (-not $srcFiles -or $srcFiles.Count -eq 0) {
        Write-Host $L.NoFilesVerif -ForegroundColor Gray
        return @{ OK = $true; Checked = 0; Passed = 0; Failed = 0; Missing = 0 }
    }

    $bySize = $srcFiles | Sort-Object Length -Descending | Select-Object -First 5
    $byDate = $srcFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    $randomCount = [math]::Min([math]::Max(1, $SampleSize - 10), $srcFiles.Count)
    $random = $srcFiles | Get-Random -Count $randomCount
    $sample = @($bySize) + @($byDate) + @($random) | Sort-Object FullName -Unique | Select-Object -First $SampleSize

    $checked = 0; $passed = 0; $failed = 0; $missing = 0; $failedFiles = @()

    foreach ($srcFile in $sample) {
        $checked++
        $relPath = $srcFile.FullName.Substring($Origen.Length).TrimStart('\')
        $dstFile = Join-Path $Destino $relPath

        $pct = [math]::Round(($checked / $sample.Count) * 100, 0)
        Write-Host ($L.CheckProg -f $pct, $checked, $sample.Count) -NoNewline -ForegroundColor DarkGray

        if (-not (Test-Path $dstFile)) {
            $missing++; $failedFiles += ($L.MissingTag -f $relPath); continue
        }
        try {
            $hashSrc = (Get-FileHash -Path $srcFile.FullName -Algorithm MD5 -ErrorAction Stop).Hash
            $hashDst = (Get-FileHash -Path $dstFile -Algorithm MD5 -ErrorAction Stop).Hash
            if ($hashSrc -eq $hashDst) { $passed++ }
            else { $failed++; $failedFiles += ($L.CorruptTag -f $relPath) }
        } catch { $failed++; $failedFiles += ($L.ErrorTag -f $relPath) }
    }

    Write-Host ""; Write-Host ""

    if ($failed -eq 0 -and $missing -eq 0) {
        Write-Host ($L.IntegrityOK -f $passed, $checked) -ForegroundColor Green
    } else {
        Write-Host ($L.IntegrityKO -f $passed, $failed, $missing) -ForegroundColor Red
        foreach ($f in $failedFiles) { Write-Host "         $f" -ForegroundColor Red }
    }

    return @{ OK = ($failed -eq 0 -and $missing -eq 0); Checked = $checked; Passed = $passed; Failed = $failed; Missing = $missing }
}

function Start-SmartCopy {
    param(
        [string]$Origen, [string]$Destino, [bool]$IsFile, [string]$FileName,
        [int]$MT, [string]$DiskType, [string]$Mode,
        [array]$ExcludeDirs, [array]$ExcludeFiles
    )

    Write-Host ""
    _Write-AtlasStepCompat -Message ($L.CopyingHdr -f $DiskType, $MT, $Mode) -FallbackColor Yellow
    Write-Host ""

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $roboArgs = @()
    if ($IsFile) {
        $srcDir = Split-Path $Origen -Parent
        $roboArgs += "`"${srcDir}`""
        $roboArgs += "`"${Destino}`""
        $roboArgs += "`"${FileName}`""
    } else {
        $roboArgs += "`"${Origen}`""
        $roboArgs += "`"${Destino}`""
        $roboArgs += "/E"
    }

    $roboArgs += "/J"; $roboArgs += "/MT:${MT}"; $roboArgs += "/R:2"; $roboArgs += "/W:2"
    $roboArgs += "/FFT"; $roboArgs += "/ETA"; $roboArgs += "/NP"; $roboArgs += "/TEE"; $roboArgs += "/DCOPY:DAT"

    if (-not $IsFile) {
        $roboArgs += "/XJ"
        if ($Mode -eq $L.ModeIncrL -or $Mode -eq 'INCREMENTAL') { $roboArgs += "/XO" }
    }

    $logFile = Join-Path ([Environment]::GetFolderPath("Desktop")) "Log_Atlas_$(Get-Date -Format 'yyyy-MM-dd_HHmm').txt"
    $roboArgs += "/LOG+:`"${logFile}`""

    $defaultXD = @("System Volume Information", "`$RECYCLE.BIN", "Recovery")
    $allXD = $defaultXD + $ExcludeDirs
    if ($allXD.Count -gt 0 -and -not $IsFile) {
        $roboArgs += "/XD"
        foreach ($xd in $allXD) { $roboArgs += "`"${xd}`"" }
    }

    $defaultXF = @("Pagefile.sys", "Hiberfil.sys", "swapfile.sys", "Thumbs.db")
    $allXF = $defaultXF + $ExcludeFiles
    if ($allXF.Count -gt 0 -and -not $IsFile) {
        $roboArgs += "/XF"
        foreach ($xf in $allXF) { $roboArgs += "`"${xf}`"" }
    }

    $argString = $roboArgs -join " "

    $preSize = 0
    if (Test-Path $Destino) {
        try { $preSize = (Get-ChildItem $Destino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {}
        if (-not $preSize) { $preSize = 0 }
    }

    $process = Start-Process -FilePath "robocopy" -ArgumentList $argString -NoNewWindow -PassThru -Wait
    $exitCode = $process.ExitCode
    $sw.Stop(); $elapsed = $sw.Elapsed

    $postSize = 0
    if (Test-Path $Destino) {
        try { $postSize = (Get-ChildItem $Destino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {}
        if (-not $postSize) { $postSize = 0 }
    }
    $bytesCopied = [math]::Max(0, $postSize - $preSize)
    $speedMBps = if ($elapsed.TotalSeconds -gt 0) { [math]::Round(($bytesCopied / 1MB) / $elapsed.TotalSeconds, 1) } else { 0 }

    Write-Host ""
    Write-Host "    ========================================================" -ForegroundColor White
    $resultMsg = switch ($exitCode) {
        0 { $L.ResNoChange }
        1 { $L.ResCopied }
        2 { $L.ResExtras }
        3 { $L.ResCopyExtra }
        4 { $L.ResMismatch }
        5 { $L.ResCopyMis }
        default { if ($exitCode -le 7) { $L.ResDone -f $exitCode } else { $L.ResError -f $exitCode } }
    }
    $resultColor = if ($exitCode -le 3) { "Green" } elseif ($exitCode -le 7) { "Yellow" } else { "Red" }

    Write-Host ($L.ResultLine -f $resultMsg) -ForegroundColor $resultColor
    Write-Host "    ========================================================" -ForegroundColor White
    Write-Host ""
    Write-Host ($L.TimeLine    -f (Format-Duration $elapsed)) -ForegroundColor Gray
    Write-Host ($L.CopiedLine  -f (Format-Size $bytesCopied)) -ForegroundColor Gray
    Write-Host ($L.SpeedLine   -f $speedMBps) -ForegroundColor Gray
    Write-Host ($L.LogLine     -f (Split-Path $logFile -Leaf)) -ForegroundColor DarkGray

    return @{
        ExitCode = $exitCode; OK = ($exitCode -le 7); Elapsed = $elapsed
        BytesCopied = $bytesCopied; SpeedMBps = $speedMBps; LogFile = $logFile
    }
}

# ==================== MAIN LOOP ====================

do {
    Clear-Host
    _Write-AtlasHeaderCompat -Title $L.WinTitle

    $origen = $null; $isFile = $false; $srcName = ""; $srcStats = $null

    :askSource while ($true) {
        Write-Host ""
        Write-Host $L.Step1Src -ForegroundColor White

        $pathResult = Get-PathFromUser -Prompt $L.Step1Prompt -Mode "any"

        if ($pathResult -eq "EXIT") { return }
        if ($pathResult -eq "BACK") { break }

        if (-not (Test-Path $pathResult)) {
            Write-Host ($L.ErrNotExist -f $pathResult) -ForegroundColor Red
            continue
        }

        $origen = $pathResult
        $isFile = -not (Test-Path $origen -PathType Container)

        if ($isFile) {
            $srcFileObj = Get-Item $origen
            $srcName = $srcFileObj.Name
            $srcStats = @{ Files = 1; Size = $srcFileObj.Length; SizeMB = [math]::Round($srcFileObj.Length / 1MB, 1) }
            Write-Host ""
            Write-Host ($L.FileTag -f $srcName, (Format-Size $srcFileObj.Length)) -ForegroundColor Green
        } else {
            $srcName = Split-Path $origen -Leaf
            Write-Host $L.FolderScan -ForegroundColor DarkGray
            $srcStats = Get-FolderStats $origen
            Write-Host ($L.FolderTag -f $srcName) -ForegroundColor Green
            Write-Host ($L.FolderInfo -f $srcStats.Files, (Format-Size $srcStats.Size)) -ForegroundColor Gray
        }
        break
    }

    if (-not $origen) { continue }

    $destino = $null; $driveInfo = $null

    :askDest while ($true) {
        Write-Host ""
        Write-Host $L.Step2Dst -ForegroundColor White

        $pathResult = Get-PathFromUser -Prompt $L.Step2Prompt -Mode "folder"

        if ($pathResult -eq "EXIT") { return }
        if ($pathResult -eq "BACK") { break }

        $destBase = $pathResult
        if (-not (Test-Path $destBase)) {
            Write-Host ($L.ErrUnreach -f $destBase) -ForegroundColor Red
            continue
        }

        try {
            $fullOrigen = (Resolve-Path $origen).Path
            $fullDest = (Resolve-Path $destBase).Path
            if ($fullOrigen -eq $fullDest) {
                Write-Host $L.ErrSameDir -ForegroundColor Red
                continue
            }
            if ($fullDest.StartsWith($fullOrigen + "\")) {
                Write-Host $L.ErrRecursion -ForegroundColor Red
                continue
            }
        } catch {}

        $destDriveLetter = $destBase.Substring(0, 1)
        $driveInfo = Detect-DriveType $destDriveLetter

        $labelDisplay = if ($driveInfo.Label) { " ($($driveInfo.Label))" } else { "" }
        Write-Host ($L.DiskTag -f $driveInfo.Desc, $labelDisplay) -ForegroundColor $driveInfo.Color
        Write-Host ($L.FreeTag -f (Format-Size $driveInfo.FreeBytes)) -ForegroundColor Gray

        if ($driveInfo.FreeBytes -gt 0 -and $srcStats.Size -gt $driveInfo.FreeBytes) {
            Write-Host ""
            Write-Host $L.NoSpace -ForegroundColor Red
            Write-Host ($L.NeedHave -f (Format-Size $srcStats.Size), (Format-Size $driveInfo.FreeBytes)) -ForegroundColor Red
            Write-Host $L.ForceBack -ForegroundColor Yellow
            $espOp = Read-Host "      >"
            if ($espOp -ne "F" -and $espOp -ne "f") { continue }
        }

        $destino = $destBase
        break
    }

    if (-not $destino) { continue }

    Write-Host ""
    Write-Host $L.Step3Name -ForegroundColor White
    $cliente = Read-Host $L.NamePrompt
    if ([string]::IsNullOrWhiteSpace($cliente)) { $cliente = $L.DefaultName }
    $cliente = $cliente -replace '[\\/:*?"<>|]', '_'

    $fechaHoy = Get-Date -Format 'yyyy-MM-dd'
    $rutaFinal = Join-Path $destino "${cliente}_${fechaHoy}"

    Write-Host ""
    Write-Host $L.Step4Mode -ForegroundColor Cyan
    Write-Host $L.ModeFull -ForegroundColor White
    Write-Host $L.ModeIncr -ForegroundColor White
    Write-Host $L.BackOpt -ForegroundColor DarkGray
    Write-Host ""
    $modoSel = Read-Host "      >"
    if ($modoSel -eq "B" -or $modoSel -eq "b") { continue }
    $modo = if ($modoSel -eq "2") { $L.ModeIncrL } else { $L.ModeFullL }

    $extraXD = @(); $extraXF = @()

    if (-not $isFile) {
        Write-Host ""
        Write-Host $L.Step5Excl -ForegroundColor Cyan
        Write-Host $L.Excl1 -ForegroundColor White
        Write-Host $L.Excl2 -ForegroundColor White
        Write-Host $L.Excl3 -ForegroundColor White
        Write-Host $L.Excl4 -ForegroundColor White
        Write-Host $L.BackOpt -ForegroundColor DarkGray
        Write-Host ""
        $exclSel = Read-Host "      >"
        if ($exclSel -eq "B" -or $exclSel -eq "b") { continue }

        switch ($exclSel) {
            "2" {
                $extraXF = @("*.tmp", "*.log", "*.bak", "*.cache", "*.temp", "~*")
                $extraXD = @("Temp", "tmp", "Cache", "__pycache__", "node_modules", ".git")
                Write-Host $L.ExclTmpOk -ForegroundColor Green
            }
            "3" {
                $extraXF = @("*.iso", "*.vhd", "*.vhdx", "*.wim", "*.esd", "*.vmdk")
                Write-Host $L.ExclIsoOk -ForegroundColor Green
            }
            "4" {
                Write-Host $L.ExclCustom -ForegroundColor White
                $customExcl = Read-Host "      >"
                if (-not [string]::IsNullOrWhiteSpace($customExcl)) {
                    $extraXF = ($customExcl -split ',') | ForEach-Object {
                        $ext = $_.Trim()
                        if ($ext -notmatch '^\*') { $ext = "*${ext}" }
                        $ext
                    }
                    Write-Host ($L.ExclCustOk -f ($extraXF -join ', ')) -ForegroundColor Green
                }
            }
        }
    }

    Clear-Host
    Write-Host "`n"
    Write-Centered $L.PreviewHdr "White"
    Write-Host ""

    if ($isFile) {
        Write-Host $L.PrevType -ForegroundColor Gray
        Write-Host ($L.PrevFile -f $srcName) -ForegroundColor White
        Write-Host ($L.PrevSize -f (Format-Size $srcStats.Size)) -ForegroundColor Gray
    } else {
        Write-Host $L.PrevType2 -ForegroundColor Gray
        Write-Host ($L.PrevSrc -f $srcName) -ForegroundColor White
        Write-Host ($L.PrevFiles -f $srcStats.Files, (Format-Size $srcStats.Size)) -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host ($L.PrevDest -f $rutaFinal) -ForegroundColor White
    Write-Host ($L.PrevDisk -f $driveInfo.Desc) -ForegroundColor $driveInfo.Color
    Write-Host ($L.PrevThreads -f $driveInfo.MT) -ForegroundColor Gray
    Write-Host ($L.PrevMode -f $modo) -ForegroundColor Cyan

    if ($extraXF.Count -gt 0 -or $extraXD.Count -gt 0) {
        Write-Host ($L.PrevExcl -f $extraXF.Count, $extraXD.Count) -ForegroundColor DarkGray
    }

    $avgSpeed = switch ($driveInfo.Type) { "USB" { 25 } "HDD" { 80 } "SSD" { 300 } default { 50 } }
    if ($srcStats.SizeMB -gt 0) {
        $etaSec = $srcStats.SizeMB / $avgSpeed
        $etaSpan = [TimeSpan]::FromSeconds($etaSec)
        Write-Host ($L.PrevETA -f (Format-Duration $etaSpan), $driveInfo.Type) -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Centered $L.PreviewSep "White"
    Write-Host ""
    Write-Host $L.PreviewAct -ForegroundColor White
    Write-Host ""
    $confirmar = Read-Host "    >"
    if ($confirmar -ne "S" -and $confirmar -ne "s") { continue }

    Clear-Host
    Write-Host "`n"

    $fileName = if ($isFile) { $srcName } else { "" }

    $result = Start-SmartCopy -Origen $origen -Destino $rutaFinal -IsFile $isFile -FileName $fileName `
        -MT $driveInfo.MT -DiskType $driveInfo.Type -Mode $modo `
        -ExcludeDirs $extraXD -ExcludeFiles $extraXF

    if ($result.OK -and -not $isFile) {
        Write-Host ""
        Write-Host $L.VerifyAsk -ForegroundColor DarkGray
        $verSel = Read-Host "    >"
        if ($verSel -match '^[SsYy]$') {
            $integrity = Test-CopyIntegrity -Origen $origen -Destino $rutaFinal
        }
    }

    :postMenu while ($true) {
        Write-Host ""
        Write-Host $L.PostSep -ForegroundColor DarkGray
        Write-Host $L.PostA -ForegroundColor Cyan
        Write-Host $L.PostR -ForegroundColor Green
        Write-Host $L.PostN -ForegroundColor White
        Write-Host $L.PostL -ForegroundColor DarkGray
        Write-Host $L.PostS -ForegroundColor DarkGray
        Write-Host $L.PostSep -ForegroundColor DarkGray
        Write-Host ""
        $postOp = Read-Host "    >"

        switch ($postOp.ToUpper()) {
            "A" {
                if (Test-Path $rutaFinal) { Invoke-Item $rutaFinal }
                else { Write-Host $L.FolderNotFnd -ForegroundColor Red }
            }
            "R" {
                Write-Host ""
                Write-Host $L.NewDestHdr -ForegroundColor White

                $newPath = Get-PathFromUser -Prompt $L.Step2Prompt -Mode "folder"
                if ($newPath -eq "BACK" -or $newPath -eq "EXIT" -or -not $newPath) { continue }

                $newDestBase = $newPath
                if (-not (Test-Path $newDestBase)) {
                    Write-Host $L.UnreachShort -ForegroundColor Red
                    continue
                }

                $newDriveInfo = Detect-DriveType ($newDestBase.Substring(0, 1))
                $newRutaFinal = Join-Path $newDestBase "${cliente}_${fechaHoy}"

                $newLabelDisplay = if ($newDriveInfo.Label) { " ($($newDriveInfo.Label))" } else { "" }
                Write-Host ($L.NewDiskLine -f $newDriveInfo.Desc, $newLabelDisplay, $newDriveInfo.MT) -ForegroundColor $newDriveInfo.Color
                Write-Host ($L.NewDestLine -f $newRutaFinal) -ForegroundColor White
                Write-Host ""
                Write-Host $L.CopyOrCancel -ForegroundColor White
                $repConf = Read-Host "    >"

                if ($repConf -match '^[SsYy]$') {
                    Clear-Host; Write-Host "`n"
                    $result2 = Start-SmartCopy -Origen $origen -Destino $newRutaFinal -IsFile $isFile -FileName $fileName `
                        -MT $newDriveInfo.MT -DiskType $newDriveInfo.Type -Mode $modo `
                        -ExcludeDirs $extraXD -ExcludeFiles $extraXF

                    if ($result2.OK -and -not $isFile) {
                        Write-Host ""; Write-Host $L.VerifyMD5Q -ForegroundColor DarkGray
                        $v2 = Read-Host "    >"
                        if ($v2 -match '^[SsYy]$') { Test-CopyIntegrity -Origen $origen -Destino $newRutaFinal | Out-Null }
                    }
                }
            }
            "N" { break }
            "L" {
                if (Test-Path $result.LogFile) { Start-Process notepad $result.LogFile }
                else { Write-Host $L.LogNotFnd -ForegroundColor Red }
            }
            "S" { return }
        }

        if ($postOp -eq "N" -or $postOp -eq "n") { break }
    }

} while ($true)
}
