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
    # Descarga el installer oficial de FastCopy (fastcopy.jp redirige a GitHub),
    # lo ejecuta silenciosamente a %LOCALAPPDATA%\AtlasPC\apps\FastCopy y
    # devuelve la ruta al .exe.
    $targetDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\apps\FastCopy'
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # URLs en orden de preferencia (version mas reciente primero).
    # fastcopy.jp hace redirect 302 a GitHub/FastCopyLab.
    $urls = @(
        'https://fastcopy.jp/archive/FastCopy5.11.2_installer.exe',
        'https://github.com/FastCopyLab/FastCopyDist2/raw/main/FastCopy5.11.2_installer.exe',
        'https://fastcopy.jp/archive/FastCopy5.9.0_installer.exe'
    )

    $installerPath = Join-Path $env:TEMP ("FastCopy-installer-" + [guid]::NewGuid().ToString('N').Substring(0,8) + ".exe")
    $ok = $false
    foreach ($url in $urls) {
        Write-Host "    Descargando: $url" -ForegroundColor Gray
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            if ((Get-Item $installerPath).Length -gt 200KB) { $ok = $true; break }
        } catch {
            Write-Host "    Fallo: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    if (-not $ok) { throw "No se pudo descargar el installer de FastCopy." }

    # El installer oficial de FastCopy NO es InnoSetup; es custom.
    # Switches (segun el propio installedr):
    #   /SILENT ... silent install
    #   /DIR=<dir> ... target dir
    #   /EXTRACT64 ... extraer only archivos (sin instalar)
    #   /NOSUBDIR ... no crear subcarpeta
    #   /AGREE_LICENSE ... aceptar licencia
    # Usamos /EXTRACT64 para only dejar los archivos en $targetDir
    # sin modificar menu inicio / Program Files / registro.
    Write-Host "    Extracting FastCopy a $targetDir ..." -ForegroundColor Gray
    $procArgs = @('/EXTRACT64', '/NOSUBDIR', '/AGREE_LICENSE', ("/DIR=`"$targetDir`""))
    try {
        $p = Start-Process -FilePath $installerPath -ArgumentList $procArgs -Wait -PassThru -ErrorAction Stop
        if ($p.ExitCode -ne 0) {
            Write-Host "    /EXTRACT64 finished with code $($p.ExitCode). Trying /SILENT install..." -ForegroundColor Yellow
            $p2 = Start-Process -FilePath $installerPath -ArgumentList @('/SILENT', '/AGREE_LICENSE', ("/DIR=`"$targetDir`"")) -Wait -PassThru -ErrorAction Stop
            if ($p2.ExitCode -ne 0) {
                Write-Host "    /SILENT also failed. Running in interactive mode..." -ForegroundColor Yellow
                Start-Process -FilePath $installerPath -Wait
            }
        }
    } catch {
        throw "Fallo ejecutando el installedr: $($_.Exception.Message)"
    } finally {
        Remove-Item $installerPath -ErrorAction SilentlyContinue
    }

    # Buscar el .exe en target (el installer puede poner FastCopy.exe directo o en subcarpeta).
    $exe = Get-ChildItem -Path $targetDir -Filter 'FastCopy.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $exe) {
        # Si el user eligio el default (Program Files), buscar ahi.
        $fallbacks = @(
            "$env:ProgramFiles\FastCopy\FastCopy.exe",
            "${env:ProgramFiles(x86)}\FastCopy\FastCopy.exe"
        )
        foreach ($fb in $fallbacks) {
            if (Test-Path $fb) { $exe = Get-Item $fb; break }
        }
    }
    if (-not $exe) { throw "FastCopy.exe not found after installation." }
    return $exe.FullName
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
    
    $reportFile = Join-Path ([Environment]::GetFolderPath("Desktop")) "Summary_Atlas_${Cliente}_$(Get-Date -Format 'yyyy-MM-dd_HHmm').txt"
    
    $r = @()
    $r += "================================================================"
    $r += "  ATLAS PC SUPPORT - COPY SUMMARY"
    $r += "================================================================"
    $r += ""
    $r += "DATE:        $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    $r += "COMPUTER:    $env:COMPUTERNAME"
    $r += "USER:        $env:USERNAME"
    $r += "PROJECT:     ${Cliente}"
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
    $r += "STATUS:      $(if ($Result.OK) { 'SUCCESS' } else { 'WITH ERRORS' })"
    $r += "TIME:        $(Format-Duration $Result.Elapsed)"
    $r += "COPIED:      $(Format-Size $Result.BytesCopied)"
    $r += "SPEED:       $($Result.SpeedMBps) MB/s"
    
    if ($Comparison) {
        $r += ""
        $r += "--- PRE-COPY ANALYSIS ---"
        $r += "NEW:         $($Comparison.New) files"
        $r += "MODIFIED:    $($Comparison.Modified) files"
        $r += "EQUAL:       $($Comparison.Equal) files"
    }
    
    if ($Integrity) {
        $r += ""
        $r += "--- MD5 VERIFICATION ---"
        $r += "VERIFIED:    $($Integrity.Checked) files"
        $r += "OK:          $($Integrity.Passed)"
        $r += "FAILED:      $($Integrity.Failed)"
        $r += "MISSING:     $($Integrity.Missing)"
        $r += "RESULT:      $(if ($Integrity.OK) { 'INTEGRITY VERIFIED' } else { 'ISSUES DETECTED' })"
    }
    
    $r += ""
    $r += "--- LOG ---"
    $r += "FILE:        $(if ($Result.LogFile) { $Result.LogFile } else { 'N/A' })"
    $r += ""
    $r += "================================================================"
    $r += "  Generated by ATLAS PC SUPPORT - FastCopy v3"
    $r += "================================================================"
    
    ($r -join "`r`n") | Out-File -FilePath $reportFile -Encoding UTF8
    return $reportFile
}

# ==================== VERIFICACIÓN MD5 ====================

function Test-CopyIntegrity {
    param([string]$Origen, [string]$Destino, [int]$SampleSize = 15)
    Write-Host ""
    _Write-AtlasStepCompat -Message "VERIFYING MD5 INTEGRITY..." -FallbackColor Yellow
    Write-Host ""

    $srcStats = Get-FolderStats $Origen
    $dstStats = Get-FolderStats $Destino
    Write-Host "    Files    - Source: $($srcStats.Files) | Target: $($dstStats.Files)" -ForegroundColor Gray
    Write-Host "    Size     - Source: $(Format-Size $srcStats.Size) | Target: $(Format-Size $dstStats.Size)" -ForegroundColor Gray

    $countMatch = ($srcStats.Files -eq $dstStats.Files)
    Write-Host "    Count:   $(if ($countMatch) { 'MATCH' } else { 'DIFFERENT (may be normal)' })" -ForegroundColor $(if ($countMatch) { "Green" } else { "Yellow" })

    $srcFiles = Get-ChildItem -Path $Origen -Recurse -File -ErrorAction SilentlyContinue
    if (-not $srcFiles -or $srcFiles.Count -eq 0) {
        Write-Host "    Sin archivos." -ForegroundColor Gray
        return @{ OK = $true; Checked = 0; Passed = 0; Failed = 0; Missing = 0 }
    }

    Write-Host ""; Write-Host "    Hash MD5 (muestra de ${SampleSize})..." -ForegroundColor DarkGray

    $bySize = $srcFiles | Sort-Object Length -Descending | Select-Object -First 5
    $byDate = $srcFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    $randomCount = [math]::Min([math]::Max(1, $SampleSize - 10), $srcFiles.Count)
    $random = $srcFiles | Get-Random -Count $randomCount
    $sample = @($bySize) + @($byDate) + @($random) | Sort-Object FullName -Unique | Select-Object -First $SampleSize

    $checked = 0; $passed = 0; $failed = 0; $missing = 0; $failedFiles = @()

    foreach ($sf in $sample) {
        $checked++
        $relPath = $sf.FullName.Substring($Origen.Length).TrimStart('\')
        $dstFile = Join-Path $Destino $relPath
        $pct = [math]::Round(($checked / $sample.Count) * 100, 0)
        Write-Host "`r    [${pct}%] ${checked}/$($sample.Count)..." -NoNewline -ForegroundColor DarkGray

        if (-not (Test-Path $dstFile)) { $missing++; $failedFiles += "FALTA: ${relPath}"; continue }
        try {
            $h1 = (Get-FileHash $sf.FullName -Algorithm MD5 -ErrorAction Stop).Hash
            $h2 = (Get-FileHash $dstFile -Algorithm MD5 -ErrorAction Stop).Hash
            if ($h1 -eq $h2) { $passed++ } else { $failed++; $failedFiles += "CORRUPTO: ${relPath}" }
        } catch { $failed++; $failedFiles += "ERROR: ${relPath}" }
    }

    Write-Host ""; Write-Host ""
    if ($failed -eq 0 -and $missing -eq 0) {
        Write-Host "    [OK] INTEGRIDAD: ${passed}/${checked} verificados" -ForegroundColor Green
    } else {
        Write-Host "    [!!] OK=${passed} | FALLOS=${failed} | FALTANTES=${missing}" -ForegroundColor Red
        foreach ($f in $failedFiles) { Write-Host "         $f" -ForegroundColor Red }
    }
    return @{ OK = ($failed -eq 0 -and $missing -eq 0); Checked = $checked; Passed = $passed; Failed = $failed; Missing = $missing }
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

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $allResults = @()
    $totalBytesCopied = 0
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
        $fcArgs += "/auto_close"
        $fcArgs += "/error_stop=FALSE"
        $fcArgs += "/log"
        $fcArgs += "/logfile=`"${logFile}`""

        if (-not (Test-Path $Destino)) {
            New-Item -ItemType Directory -Path $Destino -Force | Out-Null
        }

        # Exclusiones
        if ($ExcludeFiles -and $ExcludeFiles.Count -gt 0) {
            $exclStr = ($ExcludeFiles -join ";")
            $fcArgs += "/exclude=`"${exclStr}`""
        }

        $fcArgs += "`"${origen}`""
        $fcArgs += "/to=`"${Destino}\`""

        $argString = $fcArgs -join " "

        $preSize = 0
        if (Test-Path $Destino) {
            try { $preSize = (Get-ChildItem $Destino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {}
            if (-not $preSize) { $preSize = 0 }
        }

        $process = Start-Process -FilePath $FastCopyExe -ArgumentList $argString -PassThru -Wait
        $exitCode = $process.ExitCode

        $postSize = 0
        if (Test-Path $Destino) {
            try { $postSize = (Get-ChildItem $Destino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {}
            if (-not $postSize) { $postSize = 0 }
        }
        $copied = [math]::Max(0, $postSize - $preSize)
        $totalBytesCopied += $copied

        if ($exitCode -ne 0) { $allOK = $false }

        $statusIcon = if ($exitCode -eq 0) { "[OK]" } else { "[!!]" }
        $statusColor = if ($exitCode -eq 0) { "Green" } else { "Red" }
        Write-Host "    ${statusIcon} ${srcName} - $(Format-Size $copied)" -ForegroundColor $statusColor
    }

    $sw.Stop(); $elapsed = $sw.Elapsed
    $speedMBps = if ($elapsed.TotalSeconds -gt 0) { [math]::Round(($totalBytesCopied / 1MB) / $elapsed.TotalSeconds, 1) } else { 0 }

    Write-Host ""
    Write-Host "    ========================================================" -ForegroundColor White
    $resultColor = if ($allOK) { "Green" } else { "Red" }
    $resultMsg = if ($allOK) { "COMPLETADO EXITOSAMENTE" } else { "COMPLETADO CON ERRORES - revisa el log" }
    Write-Host "    RESULTADO: ${resultMsg}" -ForegroundColor $resultColor
    Write-Host "    ========================================================" -ForegroundColor White
    Write-Host ""
    Write-Host "    Origenes:  $($Origins.Count)" -ForegroundColor Gray
    Write-Host "    Tiempo:    $(Format-Duration $elapsed)" -ForegroundColor Gray
    Write-Host "    Copiado:   $(Format-Size $totalBytesCopied)" -ForegroundColor Gray
    Write-Host "    Velocidad: ${speedMBps} MB/s" -ForegroundColor Gray
    Write-Host "    Log:       $(Split-Path $logFile -Leaf)" -ForegroundColor DarkGray

    return @{
        ExitCode = $(if ($allOK) { 0 } else { 1 }); OK = $allOK; Elapsed = $elapsed
        BytesCopied = $totalBytesCopied; SpeedMBps = $speedMBps; LogFile = $logFile
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
    $notifMsg = "$(Format-Size $result.BytesCopied) en $(Format-Duration $result.Elapsed) a $($result.SpeedMBps) MB/s"
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
            $integrity = Test-CopyIntegrity -Origen $origenes[0] -Destino $rutaFinal
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
                    
                    $n2Msg = "$(Format-Size $r2.BytesCopied) en $(Format-Duration $r2.Elapsed)"
                    Send-Notification -Title "Atlas - Copia $(if ($r2.OK) {'OK'} else {'Error'})" -Message $n2Msg -Success $r2.OK

                    if ($r2.OK -and $modo -ne "MOVER") {
                        Write-Host "    Verificar MD5? [Y/N]" -ForegroundColor DarkGray
                        $v2 = Read-Host "    >"
                        if ($v2 -match '^[SsYy]$') { Test-CopyIntegrity -Origen $origenes[0] -Destino $newRutaFinal | Out-Null }
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
