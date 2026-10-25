# ============================================================
# Invoke-FastCopy
# Migrado de: FastCopy.ps1
# Atlas PC Support — v1.0
# ============================================================

function Invoke-FastCopy {
    [CmdletBinding()]
    param()
# ========================================================
# ATLAS PC SUPPORT - FASTCOPY EDITION v3 (PowerShell)
# Multi-origen + Perfiles + Comparar + Notificacion
# MD5 + Speed adapt + Summary exportable + Exclusiones
# ========================================================

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Gray"
$Host.UI.RawUI.WindowTitle = "FastCopy Edition v3 - Atlas PC Support"
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 48) } catch {}
$ErrorActionPreference = "Continue"
$atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

# ==================== BUSCAR FASTCOPY ====================

function Find-FastCopy {
    $searchPaths = @(
        "C:\Program Files\FastCopy\FastCopy.exe",
        "C:\Program Files (x86)\FastCopy\FastCopy.exe",
        (Join-Path $env:LOCALAPPDATA "FastCopy\FastCopy.exe"),
        (Join-Path $env:LOCALAPPDATA 'AtlasPC\apps\FastCopy\FastCopy.exe')
    )
    # USB offline root (set by run-launcher.ps1 on USB launch)
    if ($env:ATLAS_OFFLINE_ROOT) {
        $searchPaths += (Join-Path $env:ATLAS_OFFLINE_ROOT 'apps\FastCopy\FastCopy.exe')
    }
    foreach ($path in $searchPaths) {
        if ($path -and (Test-Path $path)) { return (Resolve-Path $path).Path }
    }
    $inPath = Get-Command "FastCopy.exe" -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }
    return $null
}

function Install-FastCopyAuto {
    # Resolve FastCopy via dependency manager with SHA-256 validation
    if (Get-Command Resolve-AtlasDependency -ErrorAction SilentlyContinue) {
        try {
            $depPath = Resolve-AtlasDependency -Name 'FastCopy' -InstallIfMissing
            if ($depPath -and (Test-Path $depPath)) { return $depPath }
        } catch {
            Write-Host "    [!] Dependency manager notice: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    $existing = Find-FastCopy
    if ($existing) { return $existing }
    throw "FastCopy dependency could not be resolved."
}

# ==================== FUNCIONES BASE ====================

function Write-Centered {
    param ([string]$Text, [string]$Color = "White")
    $W = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
    $Pad = [math]::Max(0, [math]::Floor(($W - $Text.Length) / 2))
    Write-Host (" " * $Pad + $Text) -ForegroundColor $Color
}

function _Write-AtlasHeaderCompat {
    param([string]$Title, [string]$Subtitle = '')
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title $Title -Color Yellow
        if (-not [string]::IsNullOrWhiteSpace($Subtitle)) { Write-AtlasStep $Subtitle }
        Write-Host ''
        return
    }
    Write-Host "`n"
    Write-Centered "==========================================================" "Cyan"
    Write-Centered "           FASTCOPY EDITION v3" "Yellow"
    Write-Centered "     Multi-source Copy · Profiles · MD5 Verify" "DarkGray"
    Write-Centered "==========================================================" "Cyan"
    Write-Host ""
}

function _Write-AtlasStepCompat {
    param([string]$Message, [ConsoleColor]$FallbackColor = 'Yellow')
    if ($atlasToolkitReady) { Write-AtlasStep $Message; return }
    Write-Centered $Message $FallbackColor
}

function _Wait-AtlasExitCompat {
    param([string]$Message)
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message $Message
        return
    }
    $null = Read-Host $Message
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
            return @{ Type = "USB"; Speed = "autoslow"; Desc = "USB Removible"; Color = "Yellow"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
        }
        $part = Get-Partition -DriveLetter $letter -ErrorAction Stop
        $disk = Get-Disk -Number $part.DiskNumber -ErrorAction Stop
        $phys = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $disk.Number.ToString() }
        if ($disk.BusType -eq 'USB') {
            return @{ Type = "USB"; Speed = "autoslow"; Desc = "USB Externo"; Color = "Yellow"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
        }
        if ($disk.BusType -eq 'NVMe' -or ($phys -and $phys.MediaType -match 'SSD')) {
            return @{ Type = "SSD"; Speed = "full"; Desc = "SSD/NVMe"; Color = "Green"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
        }
        return @{ Type = "HDD"; Speed = "full"; Desc = "HDD Mecanico"; Color = "Cyan"; Label = $vol.FileSystemLabel; FreeBytes = $vol.SizeRemaining }
    } catch {
        return @{ Type = "UNKNOWN"; Speed = "autoslow"; Desc = "No detectado"; Color = "Gray"; Label = ""; FreeBytes = 0 }
    }
}

# ==================== EXPLORADOR DE ARCHIVOS ====================

function Select-FolderDialog {
    param([string]$Description = "Select a folder")
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dialog.SelectedPath }
    return $null
}

function Select-FileDialog {
    param([string]$Title = "Selecciona un archivo")
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = "All files (*.*)|*.*"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dialog.FileName }
    return $null
}

function Get-PathFromUser {
    param([string]$Prompt = "RUTA", [string]$Mode = "any")
    Write-Host ""
    Write-Host "  DRAG, type a path, or use the explorer:" -ForegroundColor White
    Write-Host "      [E] Abrir explorador" -ForegroundColor Cyan
    Write-Host "      [B] Volver  [S] Salir" -ForegroundColor DarkGray
    Write-Host ""
    $userInput = Read-Host "      ${Prompt}"
    if ($userInput -eq "S" -or $userInput -eq "s") { return "EXIT" }
    if ($userInput -eq "B" -or $userInput -eq "b") { return "BACK" }
    if ($userInput -eq "E" -or $userInput -eq "e") {
        if ($Mode -eq "folder") {
            $path = Select-FolderDialog -Description "Selecciona carpeta"
        } else {
            Write-Host "      [1] Carpeta  [2] Archivo" -ForegroundColor White
            $tipo = Read-Host "      >"
            if ($tipo -eq "2") { $path = Select-FileDialog } else { $path = Select-FolderDialog }
        }
        if (-not $path) { return "BACK" }
        return $path
    }
    return Clean-Path $userInput
}

# ==================== PERFILES DE RESPALDO ====================

function Get-UserProfile {
    $userRoot = [Environment]::GetFolderPath("UserProfile")
    
    $profiles = @{
        "1" = @{
            Name = "RESPALDO COMPLETO DE USER"
            Desc = "Desktop + Documentos + Fotos + Videos + Descargas + Favoritos"
            Paths = @(
                (Join-Path $userRoot "Desktop"),
                (Join-Path $userRoot "Documents"),
                (Join-Path $userRoot "Pictures"),
                (Join-Path $userRoot "Videos"),
                (Join-Path $userRoot "Downloads"),
                (Join-Path $userRoot "Favorites")
            )
        }
        "2" = @{
            Name = "SOLO DOCUMENTOS Y ESCRITORIO"
            Desc = "Desktop + Documentos (lo mas critico)"
            Paths = @(
                (Join-Path $userRoot "Desktop"),
                (Join-Path $userRoot "Documents")
            )
        }
        "3" = @{
            Name = "FOTOS Y VIDEOS"
            Desc = "Pictures + Videos"
            Paths = @(
                (Join-Path $userRoot "Pictures"),
                (Join-Path $userRoot "Videos")
            )
        }
        "4" = @{
            Name = "OUTLOOK + CORREO"
            Desc = "PST/OST de Outlook + Signatures"
            Paths = @(
                (Join-Path $userRoot "Documents\Outlook Files"),
                (Join-Path $env:LOCALAPPDATA "Microsoft\Outlook"),
                (Join-Path $env:APPDATA "Microsoft\Signatures")
            )
        }
        "5" = @{
            Name = "NAVEGADORES (Favoritos/Bookmarks)"
            Desc = "Chrome + Edge + Firefox bookmarks"
            Paths = @(
                (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default"),
                (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default"),
                (Join-Path $env:APPDATA "Mozilla\Firefox\Profiles")
            )
        }
    }
    return $profiles
}

function Show-ProfileMenu {
    Write-Host ""
    Write-Centered "=== PERFILES DE RESPALDO RAPIDO ===" "DarkYellow"
    Write-Host ""
    
    $profiles = Get-UserProfile
    foreach ($key in ($profiles.Keys | Sort-Object)) {
        $p = $profiles[$key]
        Write-Host "      [${key}] $($p.Name)" -ForegroundColor White
        Write-Host "          $($p.Desc)" -ForegroundColor DarkGray
        
        # Contar carpetas que existen
        $existCount = ($p.Paths | Where-Object { Test-Path $_ }).Count
        $totalCount = $p.Paths.Count
        $existColor = if ($existCount -eq $totalCount) { "Green" } elseif ($existCount -gt 0) { "Yellow" } else { "Red" }
        Write-Host "          Carpetas: ${existCount}/${totalCount} found" -ForegroundColor $existColor
        Write-Host ""
    }
    
    Write-Host "      [B] Volver" -ForegroundColor DarkGray
    Write-Host ""
    $sel = Read-Host "      >"
    
    if ($sel -eq "B" -or $sel -eq "b") { return $null }
    if ($profiles.ContainsKey($sel)) {
        $selected = $profiles[$sel]
        $validPaths = @($selected.Paths | Where-Object { Test-Path $_ })
        if ($validPaths.Count -eq 0) {
            Write-Host "      [ERROR] No folder from profile exists." -ForegroundColor Red
            return $null
        }
        return @{ Name = $selected.Name; Paths = $validPaths }
    }
    Write-Host "      Option no valida." -ForegroundColor Red
    return $null
}

# ==================== MULTI-ORIGEN ====================

function Get-MultipleOrigins {
    $origins = @()
    Write-Host ""
    Write-Centered "=== MULTI-ORIGEN ===" "DarkYellow"
    Write-Host ""
    Write-Host "      Add folders/files one by one." -ForegroundColor DarkGray
    Write-Host "      Type [OK] when done." -ForegroundColor DarkGray
    
    while ($true) {
        Write-Host ""
        Write-Host "      Origenes agregados: $($origins.Count)" -ForegroundColor $(if ($origins.Count -gt 0) { "Green" } else { "Gray" })
        if ($origins.Count -gt 0) {
            foreach ($o in $origins) {
                $oName = Split-Path $o -Leaf
                Write-Host "        -> ${oName}" -ForegroundColor Cyan
            }
        }
        
        $pathResult = Get-PathFromUser -Prompt "ADD (or [OK] to continue)" -Mode "any"
        
        if ($pathResult -eq "EXIT") { return "EXIT" }
        if ($pathResult -eq "BACK") {
            if ($origins.Count -gt 0) { return $origins }
            return "BACK"
        }
        if ($pathResult -eq "OK" -or $pathResult -eq "ok") {
            if ($origins.Count -eq 0) {
                Write-Host "      [ERROR] Add at least one source." -ForegroundColor Red
                continue
            }
            return $origins
        }
        
        if (-not (Test-Path $pathResult)) {
            Write-Host "      [ERROR] No existe: ${pathResult}" -ForegroundColor Red
            continue
        }
        
        if ($origins -contains $pathResult) {
            Write-Host "      [!] Already in list." -ForegroundColor Yellow
            continue
        }
        
        $origins += $pathResult
        $itemName = Split-Path $pathResult -Leaf
        $itemType = if (Test-Path $pathResult -PathType Container) { "CARPETA" } else { "ARCHIVO" }
        Write-Host "      [+] ${itemType}: ${itemName}" -ForegroundColor Green
    }
}

# ==================== COMPARAR ANTES DE COPIAR ====================

function Compare-BeforeCopy {
    param([string[]]$Origins, [string]$Destino)
    
    Write-Host ""
    _Write-AtlasStepCompat -Message "ANALIZANDO DIFERENCIAS..." -FallbackColor Yellow
    Write-Host ""
    
    $totalNew = 0; $totalModified = 0; $totalEqual = 0; $totalSizeNew = 0; $totalSizeMod = 0
    
    foreach ($origen in $Origins) {
        Assert-AtlasCopyDestination -Source $origen -Destination $Destino
        $srcName = Split-Path $origen -Leaf
        $isFile = -not (Test-Path $origen -PathType Container)
        
        if ($isFile) {
            $srcFile = Get-Item $origen
            $dstFile = Join-Path $Destino $srcFile.Name
            if (-not (Test-Path $dstFile)) {
                $totalNew++; $totalSizeNew += $srcFile.Length
            } elseif ($srcFile.LastWriteTime -gt (Get-Item $dstFile).LastWriteTime) {
                $totalModified++; $totalSizeMod += $srcFile.Length
            } else {
                $totalEqual++
            }
        } else {
            $dstSubFolder = Join-Path $Destino $srcName
            $srcFiles = Get-ChildItem -Path $origen -Recurse -File -ErrorAction SilentlyContinue
            
            foreach ($sf in $srcFiles) {
                $relPath = $sf.FullName.Substring($origen.Length).TrimStart('\')
                $df = Join-Path $dstSubFolder $relPath
                
                if (-not (Test-Path $df)) {
                    $totalNew++; $totalSizeNew += $sf.Length
                } elseif ($sf.LastWriteTime -gt (Get-Item $df -ErrorAction SilentlyContinue).LastWriteTime) {
                    $totalModified++; $totalSizeMod += $sf.Length
                } else {
                    $totalEqual++
                }
            }
        }
    }
    
    $totalTransfer = $totalSizeNew + $totalSizeMod
    
    Write-Host "    NUEVOS:      ${totalNew} archivos ($(Format-Size $totalSizeNew))" -ForegroundColor Green
    Write-Host "    MODIFICADOS: ${totalModified} archivos ($(Format-Size $totalSizeMod))" -ForegroundColor Yellow
    Write-Host "    EQUAL:       ${totalEqual} files (unchanged)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    TRANSFERIR:  $($totalNew + $totalModified) archivos ($(Format-Size $totalTransfer))" -ForegroundColor Cyan
    
    return @{
        New = $totalNew; Modified = $totalModified; Equal = $totalEqual
        SizeNew = $totalSizeNew; SizeModified = $totalSizeMod; SizeTotal = $totalTransfer
    }
}

# ==================== EXCLUSIONES ====================

function Get-Exclusions {
    Write-Host ""
    Write-Host "  [?] EXCLUSIONES:" -ForegroundColor Cyan
    Write-Host "      [1] None (copiar todo)" -ForegroundColor White
    Write-Host "      [2] Temporales (.tmp, .log, .bak, cache)" -ForegroundColor White
    Write-Host "      [3] ISOs y VMs (.iso, .vhd, .wim)" -ForegroundColor White
    Write-Host "      [4] Personalizado (escribir extensiones)" -ForegroundColor White
    Write-Host "      [B] Volver" -ForegroundColor DarkGray
    Write-Host ""
    $sel = Read-Host "      >"
    
    switch ($sel) {
        "2" {
            Write-Host "      [OK] Excluyendo temporales y cache" -ForegroundColor Green
            return @{ 
                Files = @("*.tmp", "*.log", "*.bak", "*.cache", "*.temp", "~*")
                Dirs = @("Temp", "tmp", "Cache", "__pycache__", "node_modules", ".git")
                Label = "Temporales/Cache"
            }
        }
        "3" {
            Write-Host "      [OK] Excluyendo ISOs y VMs" -ForegroundColor Green
            return @{
                Files = @("*.iso", "*.vhd", "*.vhdx", "*.wim", "*.esd", "*.vmdk")
                Dirs = @()
                Label = "ISOs/VMs"
            }
        }
        "4" {
            Write-Host "      Extensions separated by comma (e.g.: .mp4,.avi,.mkv):" -ForegroundColor White
            $custom = Read-Host "      >"
            if (-not [string]::IsNullOrWhiteSpace($custom)) {
                $exts = ($custom -split ',') | ForEach-Object {
                    $e = $_.Trim()
                    if ($e -notmatch '^\*') { $e = "*${e}" }
                    $e
                }
                Write-Host "      [OK] Excluyendo: $($exts -join ', ')" -ForegroundColor Green
                return @{ Files = $exts; Dirs = @(); Label = "Personalizado" }
            }
            return @{ Files = @(); Dirs = @(); Label = "None" }
        }
        "B" { return "BACK" }
        default { return @{ Files = @(); Dirs = @(); Label = "None" } }
    }
}

# ==================== NOTIFICACION ====================

function Send-Notification {
    param([string]$Title, [string]$Message, [bool]$Success = $true)
    
    # Sonido
    if ($Success) {
        [Console]::Beep(800, 200); [Console]::Beep(1000, 200); [Console]::Beep(1200, 300)
    } else {
        [Console]::Beep(400, 500); [Console]::Beep(300, 500)
    }
    
    # Toast notification de Windows
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText = $Message
        $notify.BalloonTipIcon = if ($Success) { "Info" } else { "Error" }
        $notify.Visible = $true
        $notify.ShowBalloonTip(5000)
        
        Start-Sleep -Seconds 6
        $notify.Dispose()
    } catch {}
}

# ==================== RESUMEN EXPORTABLE ====================

function Export-CopyReport {
    param(
        [string[]]$Origins, [string]$Destino, [string]$Mode, [string]$DiskType,
        [hashtable]$Result, [hashtable]$Integrity, [hashtable]$Comparison,
        [string]$ExclusionLabel, [string]$Cliente
    )
    
    $reportFile = Join-Path ([Environment]::GetFolderPath("Desktop")) ("Summary_Atlas_$(Get-Date -Format 'yyyy-MM-dd_HHmm')_" + [guid]::NewGuid().ToString('N') + '.txt')
    
    $r = @()
    $r += "================================================================"
    $r += "  ATLAS PC SUPPORT - COPY SUMMARY"
    $r += "================================================================"
    $r += ""
    $r += "DATE:        $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    $r += "COMPUTER:    $env:COMPUTERNAME"
    $r += "USER:        $env:USERNAME"
    $r += 'PROJECT:     [REDACTED]'
    $r += ""
    $r += "--- CONFIGURATION ---"
    $r += "ENGINE:      FastCopy"
    $r += "MODE:        ${Mode}"
    $r += "DISK:        ${DiskType}"
    $r += "EXCLUSIONS:  ${ExclusionLabel}"
    $r += ""
    $r += "--- SOURCES ---"
    foreach ($o in $Origins) { $r += "  -> ${o}" }
    $r += ""
    $r += "--- TARGET ---"
    $r += "  -> ${Destino}"
    $r += ""
    $r += "--- RESULT ---"
    $r += "NATIVE STATUS: $(if ($Result.OK) { 'PROCESS COMPLETED WITHOUT NATIVE ERROR; NOT FULL CONTENT CERTIFICATION' } else { 'WITH ERRORS' })"
    $r += "TIME:        $(Format-Duration $Result.Elapsed)"
    $r += "WRITTEN BYTES: not measured by Atlas; inspect native log"
    $r += "THROUGHPUT: not measured by Atlas"
    
    if ($Comparison) {
        $r += ""
        $r += "--- PRE-COPY ANALYSIS ---"
        $r += "NEW:         $($Comparison.New) files"
        $r += "MODIFIED:    $($Comparison.Modified) files"
        $r += "EQUAL:       $($Comparison.Equal) files"
    }
    
    if ($Integrity) {
        $r += ""
        $r += "--- SHA256 SAMPLE ---"
        $r += "COVERAGE:    $($Integrity.Coverage)"
        $r += "VERIFIED:    $($Integrity.Checked) files"
        $r += "OK:          $($Integrity.Passed)"
        $r += "FAILED:      $($Integrity.Failed)"
        $r += "MISSING:     $($Integrity.Missing)"
        $r += "RESULT:      $($Integrity.State)"
    }
    
    $r += ""
    $r += "--- LOG ---"
    $r += "FILE:        $(if ($Result.LogFile) { $Result.LogFile } else { 'N/A' })"
    $r += ""
    $r += "================================================================"
    $r += "  Generated by ATLAS PC SUPPORT - FastCopy v3"
    $r += "================================================================"
    
    Write-AtlasShareableReport -Path $reportFile -Content ($r -join "`r`n") -Tool 'FastCopy observations' -SensitiveValues (@($Origins) + @($Destino,$Cliente))
    return $reportFile
}

# ==================== MUESTREO SHA-256 ====================

function Test-CopyIntegrity {
    param([string]$Origen,[string]$Destino,[int]$SampleSize=15,[string[]]$ExcludeFiles=@(),[string[]]$ExcludeDirs=@())
    $result=Test-AtlasCopySample -Source $Origen -Destination $Destino -SampleSize $SampleSize -ExcludeFiles $ExcludeFiles -ExcludeDirs $ExcludeDirs
    Write-Host $result.Coverage
    Write-Host "Checked=$($result.Checked); passed=$($result.Passed); failed=$($result.Failed); missing=$($result.Missing)"
    return $result
}

# ==================== EJECUTAR FASTCOPY ====================

function Start-FastCopy {
    param(
        [string]$FastCopyExe, [string[]]$Origins, [string]$Destino,
        [string]$Mode, [string]$SpeedMode, [string]$DiskType,
        [array]$ExcludeFiles, [array]$ExcludeDirs
    )

    Write-Host ""
    _Write-AtlasStepCompat -Message "EJECUTANDO FASTCOPY (${DiskType} | ${Mode} | speed=${SpeedMode})" -FallbackColor Yellow
    Write-Host ""

    if ($Mode -in @('MOVER','SINCRONIZAR')) { throw 'Destructive move/sync requires a separately verified backup and preview; use copy-only in this release.' }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $allResults = @()
    $allOK = $true
    $logFile = Join-Path ([Environment]::GetFolderPath("Desktop")) "Log_FastCopy_$(Get-Date -Format 'yyyy-MM-dd_HHmm').log"

    foreach ($origen in $Origins) {
        $srcName = Split-Path $origen -Leaf
        Write-Host "    Copiando: ${srcName}..." -ForegroundColor Cyan
        
        $fcArgs = @()
        switch ($Mode) {
            "COMPLETA"    { $fcArgs += "/cmd=force_copy" }
            "INCREMENTAL" { $fcArgs += "/cmd=diff" }
            "MOVER"       { $fcArgs += "/cmd=move" }
            "SINCRONIZAR" { $fcArgs += "/cmd=sync" }
            default       { $fcArgs += "/cmd=force_copy" }
        }

        $fcArgs += "/speed=${SpeedMode}"
        $fcArgs += "/estimate"
        $fcArgs += "/verify"
        $fcArgs += "/auto_close"
        $fcArgs += "/error_stop=FALSE"
        $fcArgs += "/log"
        $fcArgs += "/logfile=`"${logFile}`""

        if (-not (Test-Path $Destino)) {
            New-Item -ItemType Directory -Path $Destino -Force | Out-Null
        }

        # Exclusiones
        if ($ExcludeFiles.Count -gt 0 -or $ExcludeDirs.Count -gt 0) {
            $directoryFilters = @($ExcludeDirs | ForEach-Object { ([string]$_).TrimEnd([char]92) + [char]92 })
            $filters = @($ExcludeFiles) + $directoryFilters
            if (@($filters | Where-Object { $_ -match '[";\r\n]' }).Count) { throw 'Invalid copy exclusion filter.' }
            $exclStr = ($filters -join ";")
            $fcArgs += "/exclude=`"${exclStr}`""
        }

        $fcArgs += "`"${origen}`""
        $fcArgs += "/to=`"${Destino}\`""

        $argString = $fcArgs -join " "

        $process = Invoke-AtlasNativeProcess -FilePath $FastCopyExe -Arguments $argString -TimeoutSeconds 86400
        if ($process.State -ne 'Correct') { $allOK = $false }
        if ($process.State -notin @('Correct','Failed')) { throw "FastCopy $($process.State). Copy may be partial; inspect the log before retrying." }
        $exitCode = $process.ExitCode

        if ($exitCode -ne 0) { $allOK = $false }

        $statusIcon = if ($exitCode -eq 0) { "[OK]" } else { "[!!]" }
        $statusColor = if ($exitCode -eq 0) { "Green" } else { "Red" }
        Write-Host "    ${statusIcon} ${srcName} - consultar log nativo" -ForegroundColor $statusColor
    }

    $sw.Stop(); $elapsed = $sw.Elapsed

    Write-Host ""
    Write-Host "    ========================================================" -ForegroundColor White
    $resultColor = if ($allOK) { "Green" } else { "Red" }
    $resultMsg = if ($allOK) { "PROCESO FINALIZADO SIN ERROR NATIVO; revisar log y cobertura de verificacion" } else { "COMPLETADO CON ERRORES - revisa el log" }
    Write-Host "    RESULTADO: ${resultMsg}" -ForegroundColor $resultColor
    Write-Host "    ========================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "    Origenes:  $($Origins.Count)" -ForegroundColor Gray
    Write-Host "    Tiempo:    $(Format-Duration $elapsed)" -ForegroundColor Gray
    Write-Host "    Bytes escritos: no medidos aqui; consultar log nativo." -ForegroundColor Gray
    Write-Host "    Rendimiento: no medido por Atlas." -ForegroundColor Gray
    Write-Host "    Log:       $(Split-Path $logFile -Leaf)" -ForegroundColor DarkGray

    return @{
        ExitCode = $(if ($allOK) { 0 } else { 1 }); OK = $allOK; Elapsed = $elapsed
        BytesCopied = $null; SpeedMBps = $null; MeasurementBasis = 'Native log; not measured by Atlas'; LogFile = $logFile
    }
}

# ==================== INICIO ====================

Clear-Host

$fastCopyExe = Find-FastCopy

if (-not $fastCopyExe) {
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title "FASTCOPY NO ENCONTRADO" -Color Red
        Write-Host ''
    } else {
        Write-Host ""
        Write-Centered "============================================" "Red"
        Write-Centered "FASTCOPY NO ENCONTRADO" "Red"
        Write-Centered "============================================" "Red"
        Write-Host ""
    }
    Write-Host "    Searched in:" -ForegroundColor DarkGray
    Write-Host "    - Script folder ($PSScriptRoot)" -ForegroundColor DarkGray
    Write-Host "    - Program Files" -ForegroundColor DarkGray
    Write-Host "    - System PATH" -ForegroundColor DarkGray
    Write-Host "    - $env:LOCALAPPDATA\AtlasPC\apps\FastCopy" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Options:" -ForegroundColor Yellow
    Write-Host "      [D] Download automatically from fastcopy.jp (recommended)" -ForegroundColor White
    Write-Host "      [S] Salir e instalarlo manualmente" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "    Seleccion [D/S]"

    if ($choice -match '^[Dd]$') {
        Write-Host ""
        Write-Host "    Downloading FastCopy..." -ForegroundColor Cyan
        try {
            $fastCopyExe = Install-FastCopyAuto
            Write-Host ""
            Write-Host "    FastCopy installed: $fastCopyExe" -ForegroundColor Green
            Start-Sleep -Seconds 1
        } catch {
            Write-Host ""
            Write-Host "    Download ERROR: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "    Descarga manual: https://fastcopy.jp" -ForegroundColor Yellow
            _Wait-AtlasExitCompat -Message "    ENTER to exit"
            return
        }
    } else {
        Write-Host "    Open https://fastcopy.jp and place FastCopy.exe at:" -ForegroundColor Gray
        Write-Host "      $env:LOCALAPPDATA\AtlasPC\apps\FastCopy\" -ForegroundColor Gray
        _Wait-AtlasExitCompat -Message "    ENTER to exit"
        return
    }
}

# ==================== BUCLE PRINCIPAL ====================

do {
    Clear-Host
    _Write-AtlasHeaderCompat -Title "FASTCOPY EDITION v3" -Subtitle "Multi-source Copy · Profiles · MD5 Verify"
    Write-Host "    Motor: $(Split-Path $fastCopyExe -Leaf)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Centered "[ 1 ] Copia normal (un origen)" "White"
    Write-Centered "[ 2 ] Multi-origen (varias carpetas)" "White"
    Write-Centered "[ 3 ] Perfil rapido (respaldo de user)" "Cyan"
    Write-Centered "[ S ] Salir" "DarkGray"
    Write-Host ""
    
    $menuSel = Read-Host "      >"
    if ($menuSel -eq "S" -or $menuSel -eq "s") { exit }

    # =============================================
    # OBTENER ORIGENES
    # =============================================
    $origenes = @()
    $isMulti = $false
    $isProfile = $false
    $profileName = ""

    switch ($menuSel) {
        "1" {
            # Un only origen
            :askSingle while ($true) {
                Write-Host ""
                Write-Host "  [1] ORIGEN:" -ForegroundColor White
                $pathResult = Get-PathFromUser -Prompt "ORIGEN" -Mode "any"
                if ($pathResult -eq "EXIT") { exit }
                if ($pathResult -eq "BACK") { break }
                if (-not (Test-Path $pathResult)) {
                    Write-Host "      [ERROR] No existe: ${pathResult}" -ForegroundColor Red
                    continue
                }
                $origenes = @($pathResult)
                break
            }
        }
        "2" {
            $multiResult = Get-MultipleOrigins
            if ($multiResult -eq "EXIT") { exit }
            if ($multiResult -eq "BACK") { continue }
            $origenes = @($multiResult)
            $isMulti = $true
        }
        "3" {
            $profile = Show-ProfileMenu
            if (-not $profile) { continue }
            $origenes = @($profile.Paths)
            $isProfile = $true
            $profileName = $profile.Name
        }
        default { continue }
    }

    if ($origenes.Count -eq 0) { continue }

    # Mostrar origenes selecteds
    Write-Host ""
    $totalSize = 0; $totalFiles = 0
    foreach ($o in $origenes) {
        $oName = Split-Path $o -Leaf
        if (Test-Path $o -PathType Container) {
            $stats = Get-FolderStats $o
            $totalSize += $stats.Size; $totalFiles += $stats.Files
            Write-Host "      [OK] ${oName} ($($stats.Files) archivos, $(Format-Size $stats.Size))" -ForegroundColor Green
        } else {
            $fi = Get-Item $o
            $totalSize += $fi.Length; $totalFiles++
            Write-Host "      [OK] ${oName} ($(Format-Size $fi.Length))" -ForegroundColor Green
        }
    }
    $srcStats = @{ Files = $totalFiles; Size = $totalSize; SizeMB = [math]::Round($totalSize / 1MB, 1) }
    Write-Host ""
    Write-Host "      TOTAL: ${totalFiles} archivos | $(Format-Size $totalSize)" -ForegroundColor White

    # =============================================
    # DESTINO
    # =============================================
    $destino = $null; $driveInfo = $null

    :askDest while ($true) {
        Write-Host ""
        Write-Host "  [2] DESTINO:" -ForegroundColor White
        $pathResult = Get-PathFromUser -Prompt "DESTINO" -Mode "folder"
        if ($pathResult -eq "EXIT") { exit }
        if ($pathResult -eq "BACK") { break }
        if (-not (Test-Path $pathResult)) {
            Write-Host "      [ERROR] No accesible: ${pathResult}" -ForegroundColor Red
            continue
        }

        # Validar que ningun origen sea el destino
        $conflict = $false
        foreach ($o in $origenes) {
            try {
                $fO = (Resolve-Path $o).Path; $fD = (Resolve-Path $pathResult).Path
                if ($fO -eq $fD) { Write-Host "      [ERROR] Origen = Target: $o" -ForegroundColor Red; $conflict = $true; break }
            } catch {}
        }
        if ($conflict) { continue }

        $destDriveLetter = $pathResult.Substring(0, 1)
        $driveInfo = Detect-DriveType $destDriveLetter
        $labelDisplay = if ($driveInfo.Label) { " ($($driveInfo.Label))" } else { "" }
        Write-Host "      [OK] Disk: $($driveInfo.Desc)${labelDisplay}" -ForegroundColor $driveInfo.Color
        Write-Host "      Libre: $(Format-Size $driveInfo.FreeBytes)" -ForegroundColor Gray

        if ($driveInfo.FreeBytes -gt 0 -and $totalSize -gt $driveInfo.FreeBytes) {
            Write-Host "      [!!!] ESPACIO INSUFICIENTE" -ForegroundColor Red
            Write-Host "      Necesitas: $(Format-Size $totalSize) | Disponible: $(Format-Size $driveInfo.FreeBytes)" -ForegroundColor Red
            Write-Host "      [F] Forzar  [B] Volver" -ForegroundColor Yellow
            $espOp = Read-Host "      >"
            if ($espOp -ne "F" -and $espOp -ne "f") { continue }
        }
        $destino = $pathResult; break
    }
    if (-not $destino) { continue }

    # =============================================
    # NOMBRE
    # =============================================
    Write-Host ""
    Write-Host "  [3] Project name (ENTER = Backup):" -ForegroundColor White
    $cliente = Read-Host "      NOMBRE"
    if ([string]::IsNullOrWhiteSpace($cliente)) {
        if ($isProfile) { $cliente = $profileName -replace '\s+', '_' }
        else { $cliente = "Respaldo" }
    }
    $cliente = $cliente -replace '[\\/:*?"<>|]', '_'
    $fechaHoy = Get-Date -Format 'yyyy-MM-dd'
    $rutaFinal = Join-Path $destino "${cliente}_${fechaHoy}"

    # =============================================
    # MODO
    # =============================================
    Write-Host ""
    Write-Host "  [4] MODO DE COPIA:" -ForegroundColor Cyan
    Write-Host "      [1] COMPLETA     - Copia todo" -ForegroundColor White
    Write-Host "      [2] INCREMENTAL  - Only nuevos/modificados" -ForegroundColor White
    Write-Host "      [3] SINCRONIZAR  - Espejo exacto" -ForegroundColor White
    Write-Host "      [4] MOVER        - Mueve (borra origen)" -ForegroundColor Red
    Write-Host "      [B] Volver" -ForegroundColor DarkGray
    Write-Host ""
    $modoSel = Read-Host "      >"
    if ($modoSel -eq "B" -or $modoSel -eq "b") { continue }
    $modo = switch ($modoSel) {
        "2" { "INCREMENTAL" }
        "3" { "SINCRONIZAR" }
        "4" {
            Write-Host "      [!!!] Will delete files from SOURCE. Sure? [Y/N]" -ForegroundColor Red
            $mc = Read-Host "      >"
            if ($mc -match '^[SsYy]$') { "MOVER" } else { "SKIP" }
        }
        default { "COMPLETA" }
    }
    if ($modo -eq "SKIP") { continue }

    # =============================================
    # EXCLUSIONES
    # =============================================
    $exclusions = @{ Files = @(); Dirs = @(); Label = "None" }
    if ($origenes.Count -ge 1) {
        $exclResult = Get-Exclusions
        if ($exclResult -eq "BACK") { continue }
        if ($exclResult) { $exclusions = $exclResult }
    }

    # =============================================
    # COMPARAR (only incremental o si hay destino previo)
    # =============================================
    $comparison = $null
    if (Test-Path $rutaFinal) {
        Write-Host ""
        Write-Host "      Destino ya existe. Analizar diferencias? [Y/N]" -ForegroundColor Yellow
        $compSel = Read-Host "      >"
        if ($compSel -match '^[SsYy]$') {
            $comparison = Compare-BeforeCopy -Origins $origenes -Destino $rutaFinal
        }
    }

    # =============================================
    # PREVIEW
    # =============================================
    Clear-Host
    Write-Host "`n"
    Write-Centered "==================== PREVIEW ====================" "White"
    Write-Host ""
    
    if ($isProfile) {
        Write-Host "    PERFIL:    ${profileName}" -ForegroundColor Cyan
    }
    Write-Host "    ORIGENES:  $($origenes.Count)" -ForegroundColor Gray
    foreach ($o in $origenes) {
        Write-Host "               $(Split-Path $o -Leaf)" -ForegroundColor White
    }
    Write-Host "    TOTAL:     ${totalFiles} archivos | $(Format-Size $totalSize)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    DESTINO:   ${rutaFinal}" -ForegroundColor White
    Write-Host "    DISCO:     $($driveInfo.Desc)" -ForegroundColor $driveInfo.Color
    Write-Host "    MODO:      ${modo}" -ForegroundColor $(if ($modo -eq "MOVER") { "Red" } elseif ($modo -eq "SINCRONIZAR") { "Yellow" } else { "Cyan" })
    Write-Host "    SPEED:     $($driveInfo.Speed) (auto)" -ForegroundColor Gray
    Write-Host "    EXCLUIR:   $($exclusions.Label)" -ForegroundColor DarkGray

    if ($comparison) {
        Write-Host ""
        Write-Host "    ANALISIS:  $($comparison.New) nuevos, $($comparison.Modified) modificados, $($comparison.Equal) iguales" -ForegroundColor Cyan
        Write-Host "    TRANSFERIR: $(Format-Size $comparison.SizeTotal)" -ForegroundColor Cyan
    }

    $avgSpeed = switch ($driveInfo.Type) { "USB" { 30 } "HDD" { 100 } "SSD" { 400 } default { 50 } }
    $estSize = if ($comparison) { $comparison.SizeTotal } else { $totalSize }
    if ($estSize -gt 0) {
        $etaSec = ($estSize / 1MB) / $avgSpeed
        $etaSpan = [TimeSpan]::FromSeconds($etaSec)
        Write-Host "    ETA:       ~$(Format-Duration $etaSpan)" -ForegroundColor DarkGray
    }

    if ($modo -eq "MOVER") { Write-Host ""; Write-Host "    [!!!] ARCHIVOS SE ELIMINARAN DEL ORIGEN" -ForegroundColor Red }
    if ($modo -eq "SINCRONIZAR") { Write-Host ""; Write-Host "    [!] Extras en destino seran ELIMINADOS" -ForegroundColor Yellow }

    Write-Host ""
    Write-Centered "=================================================" "White"
    Write-Host ""
    Write-Host "    [S] INICIAR  [B] Volver  [N] Cancelar" -ForegroundColor White
    Write-Host ""
    $confirmar = Read-Host "    >"
    if ($confirmar -ne "S" -and $confirmar -ne "s") { continue }

    # =============================================
    # EJECUTAR
    # =============================================
    Clear-Host
    Write-Host "`n"

    $result = Start-FastCopy -FastCopyExe $fastCopyExe -Origins $origenes -Destino $rutaFinal `
        -Mode $modo -SpeedMode $driveInfo.Speed -DiskType $driveInfo.Type `
        -ExcludeFiles $exclusions.Files -ExcludeDirs $exclusions.Dirs

    # NOTIFICACION
    $notifMsg = "Proceso terminado en $(Format-Duration $result.Elapsed); revisar log y cobertura"
    if ($result.OK) {
        Send-Notification -Title "Atlas - Copia Completada" -Message $notifMsg -Success $true
    } else {
        Send-Notification -Title "Atlas - Copy with Errors" -Message "Revisa el log" -Success $false
    }

    # =============================================
    # VERIFICACION MD5
    # =============================================
    $integrity = $null
    if ($result.OK -and $modo -ne "MOVER") {
        Write-Host ""
        Write-Host "    Verificar integridad MD5? [Y/N]" -ForegroundColor DarkGray
        $verSel = Read-Host "    >"
        if ($verSel -match '^[SsYy]$') {
            # Verificar el primer origen (el más importante)
            $integrity = Test-CopyIntegrity -Origen $origenes[0] -Destino $rutaFinal -ExcludeFiles $exclusions.Files -ExcludeDirs $exclusions.Dirs
        }
    }

    # =============================================
    # POST-COPIA
    # =============================================
    :postMenu while ($true) {
        Write-Host ""
        Write-Host "    --------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "    [A] Abrir carpeta destino" -ForegroundColor Cyan
        Write-Host "    [R] REPEAT with another target" -ForegroundColor Green
        Write-Host "    [X] Export summary for ticket" -ForegroundColor Yellow
        Write-Host "    [N] Nueva copia" -ForegroundColor White
        Write-Host "    [L] Ver log" -ForegroundColor DarkGray
        Write-Host "    [S] Salir" -ForegroundColor DarkGray
        Write-Host "    --------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        $postOp = Read-Host "    >"

        switch ($postOp.ToUpper()) {
            "A" {
                if (Test-Path $rutaFinal) { Invoke-Item $rutaFinal }
                else { Write-Host "    No found." -ForegroundColor Red }
            }
            "R" {
                Write-Host ""
                $newPath = Get-PathFromUser -Prompt "DESTINO" -Mode "folder"
                if ($newPath -eq "BACK" -or $newPath -eq "EXIT" -or -not $newPath) { continue }
                if (-not (Test-Path $newPath)) { Write-Host "    No accesible." -ForegroundColor Red; continue }

                $newDriveInfo = Detect-DriveType ($newPath.Substring(0, 1))
                $newRutaFinal = Join-Path $newPath "${cliente}_${fechaHoy}"
                $newLabel = if ($newDriveInfo.Label) { " ($($newDriveInfo.Label))" } else { "" }
                Write-Host "    Disk: $($newDriveInfo.Desc)${newLabel}" -ForegroundColor $newDriveInfo.Color
                Write-Host "    Target: ${newRutaFinal}" -ForegroundColor White
                Write-Host "    [S] Copiar  [N] Cancelar" -ForegroundColor White
                $rc = Read-Host "    >"

                if ($rc -match '^[SsYy]$') {
                    Clear-Host; Write-Host "`n"
                    $r2 = Start-FastCopy -FastCopyExe $fastCopyExe -Origins $origenes -Destino $newRutaFinal `
                        -Mode $modo -SpeedMode $newDriveInfo.Speed -DiskType $newDriveInfo.Type `
                        -ExcludeFiles $exclusions.Files -ExcludeDirs $exclusions.Dirs
                    
                    $n2Msg = "Proceso terminado en $(Format-Duration $r2.Elapsed); revisar log y cobertura"
                    Send-Notification -Title "Atlas - Copia $(if ($r2.OK) {'OK'} else {'Error'})" -Message $n2Msg -Success $r2.OK

                    if ($r2.OK -and $modo -ne "MOVER") {
                        Write-Host "    Verificar MD5? [Y/N]" -ForegroundColor DarkGray
                        $v2 = Read-Host "    >"
                        if ($v2 -match '^[SsYy]$') { Test-CopyIntegrity -Origen $origenes[0] -Destino $newRutaFinal -ExcludeFiles $exclusions.Files -ExcludeDirs $exclusions.Dirs | Out-Null }
                    }
                }
            }
            "X" {
                $reportFile = Export-CopyReport -Origins $origenes -Destino $rutaFinal -Mode $modo `
                    -DiskType $driveInfo.Type -Result $result -Integrity $integrity `
                    -Comparison $comparison -ExclusionLabel $exclusions.Label -Cliente $cliente
                Write-Host "    [OK] Summary: $(Split-Path $reportFile -Leaf)" -ForegroundColor Green
                Write-Host "    Ready to attach to ticket." -ForegroundColor Cyan
                
                Write-Host "    Abrir? [Y/N]" -ForegroundColor DarkGray
                $openReport = Read-Host "    >"
                if ($openReport -match '^[SsYy]$') { Start-Process notepad $reportFile }
            }
            "N" { break }
            "L" {
                if ($result.LogFile -and (Test-Path $result.LogFile)) { Start-Process notepad $result.LogFile }
                else { Write-Host "    Log no found." -ForegroundColor Red }
            }
            "S" { exit }
        }
        if ($postOp -eq "N" -or $postOp -eq "n") { break }
    }

} while ($true)
}
