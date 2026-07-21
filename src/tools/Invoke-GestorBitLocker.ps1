# ============================================================
# Invoke-GestorBitLocker
# Migrado de: GestorBitLocker.ps1
# Atlas PC Support — v1.0
# ============================================================

function Invoke-GestorBitLocker {
    [CmdletBinding()]
    param(
        [ValidateSet("Extract","Status","")]
        [string]$Action = "",
        [string]$Output = "",
        [string]$MountPoint = ""
    )
# =======================================================
# Gestor de BitLocker v3 - Atlas PC Support
# TPM + Progreso + Backup USB + QR + Health Check + Log
# AD/Azure backup + CLI mode + Alerta disks sin proteger
# =======================================================

# (auto-elevación gestionada por Atlas Launcher)


[console]::BackgroundColor = "Black"
[console]::ForegroundColor = "Gray"
$Host.UI.RawUI.WindowTitle = "ATLAS PC SUPPORT - BitLocker Manager v3"
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(105, 48) } catch {}
$atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

# Log file
$logFile = Join-Path $PSScriptRoot "ATLAS_bitlocker.log"

# ==================== FUNCIONES BASE ====================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $user = "$env:USERDOMAIN\$env:USERNAME"
    $pc = $env:COMPUTERNAME
    $entry = "${timestamp} | ${Level} | ${pc} | ${user} | ${Message}"
    try { $entry | Out-File -FilePath $script:logFile -Append -Encoding UTF8 } catch {}
}

function Escribir-Centrado {
    param([string]$Texto, [ConsoleColor]$Color = "Gray")
    $AnchoVentana = $Host.UI.RawUI.WindowSize.Width
    if ($Texto.Length -lt $AnchoVentana) {
        $Espacios = [Math]::Floor(($AnchoVentana - $Texto.Length) / 2)
        Write-Host (" " * $Espacios + $Texto) -ForegroundColor $Color
    } else {
        Write-Host $Texto -ForegroundColor $Color
    }
}

function Write-AtlasHeaderCompat {
    param([string]$Title, [string]$Subtitle = "")
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title $Title -Color Yellow
        if ($Subtitle) { Write-AtlasStep $Subtitle }
        Write-Host ''
        return
    }
    Write-Host "`n"
    Escribir-Centrado "===================================================" "DarkGray"
    Escribir-Centrado "         BITLOCKER MANAGER v3" "Yellow"
    Escribir-Centrado "  Encrypt · Backup Keys · Health Check · AD Sync" "DarkGray"
    Escribir-Centrado "===================================================" "DarkGray"
}

function Wait-AtlasReturnCompat {
    param([string]$Message = "    ENTER to go back...")
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message ($Message.Trim())
        return
    }
    $null = Read-Host $Message
}

function Show-DiskTable {
    param([switch]$OnlyEncrypted, [switch]$Silent)
    
    $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
    if (-not $volumes) {
        if (-not $Silent) { Write-Host "    Could not access BitLocker." -ForegroundColor Red }
        return $null
    }
    
    if ($OnlyEncrypted) {
        $volumes = $volumes | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' }
        if (-not $volumes) {
            if (-not $Silent) { Write-Host "    No disks with BitLocker active." -ForegroundColor Yellow }
            return $null
        }
    }
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "    DISK    STATUS                  ENCRYPTED    SIZE      METHOD" -ForegroundColor DarkGray
        Write-Host "    -----   ------                  ----------   ------    ------" -ForegroundColor DarkGray
        
        foreach ($v in $volumes) {
            $mount = $v.MountPoint
            $status = $v.VolumeStatus.ToString()
            $pct = "$($v.EncryptionPercentage)%"
            $capGB = if ($v.CapacityGB) { "{0:N1} GB" -f $v.CapacityGB } else { "N/A" }
            $method = if ($v.EncryptionMethod) { $v.EncryptionMethod.ToString() } else { "-" }
            
            $statusColor = switch ($status) {
                "FullyEncrypted" { "Green" }
                "FullyDecrypted" { "Gray" }
                "EncryptionInProgress" { "Yellow" }
                "DecryptionInProgress" { "Yellow" }
                default { "White" }
            }
            $statusLabel = switch ($status) {
                "FullyEncrypted" { "ENCRYPTED" }
                "FullyDecrypted" { "FREE" }
                "EncryptionInProgress" { "ENCRYPTING..." }
                "DecryptionInProgress" { "DECRYPTING..." }
                default { $status }
            }
            $icon = switch ($status) {
                "FullyEncrypted" { "[X]" }
                "FullyDecrypted" { "[ ]" }
                "EncryptionInProgress" { "[~]" }
                "DecryptionInProgress" { "[~]" }
                default { "[?]" }
            }
            
            Write-Host "    ${icon} ${mount}" -NoNewline -ForegroundColor $statusColor
            Write-Host ("   " + $statusLabel.PadRight(24)) -NoNewline -ForegroundColor $statusColor
            Write-Host ($pct.PadRight(13)) -NoNewline -ForegroundColor White
            Write-Host ($capGB.PadRight(10)) -NoNewline -ForegroundColor Gray
            Write-Host $method -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    return $volumes
}

function Validate-DriveLetter {
    param([string]$Input, [array]$ValidVolumes)
    if ([string]::IsNullOrWhiteSpace($Input)) { return $null }
    $clean = $Input.Trim().ToUpper().Replace(":", "")
    if ($clean.Length -ne 1 -or $clean -notmatch "^[A-Z]$") {
        Write-Host "    Invalid letter. Use a single letter (e.g.: C, D, E)." -ForegroundColor Red
        return $null
    }
    $disk = "${clean}:"
    $found = $ValidVolumes | Where-Object { $_.MountPoint -eq $disk }
    if (-not $found) {
        Write-Host "    El disk ${disk} no existe." -ForegroundColor Red
        return $null
    }
    return @{ Letter = $disk; Volume = $found }
}

function Get-TPMStatus {
    $result = @{ HasTPM = $false; IsReady = $false; Version = "N/A"; Summary = "" }
    try {
        $tpm = Get-Tpm -ErrorAction Stop
        $result.HasTPM = $tpm.TpmPresent
        $result.IsReady = $tpm.TpmReady
        try {
            $tpmWMI = Get-CimInstance -Namespace "root\cimv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction Stop
            if ($tpmWMI.SpecVersion) { $result.Version = ($tpmWMI.SpecVersion -split ',')[0].Trim() }
        } catch { }
        if ($result.HasTPM -and $result.IsReady) { $result.Summary = "TPM $($result.Version) presente y listo" }
        elseif ($result.HasTPM) { $result.Summary = "TPM present but NOT ready" }
        else { $result.Summary = "No TPM detected" }
    } catch { $result.Summary = "Could not query TPM" }
    return $result
}

function Show-EncryptionProgress {
    param([string]$MountPoint, [string]$Mode = "Encrypting")
    $label = if ($Mode -eq "Encrypting") { "ENCRYPTING" } else { "DECRYPTING" }
    $color = if ($Mode -eq "Encrypting") { "Cyan" } else { "Magenta" }
    Write-Host ""
    Escribir-Centrado "Monitoring (CTRL+C to leave running in background)..." "DarkGray"
    Write-Host ""
    $lastPct = -1
    try {
        while ($true) {
            $vol = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction SilentlyContinue
            if (-not $vol) { break }
            $pct = $vol.EncryptionPercentage; $status = $vol.VolumeStatus.ToString()
            if ($pct -ne $lastPct) {
                $barWidth = 40; $filled = [math]::Floor($pct / 100 * $barWidth); $empty = $barWidth - $filled
                $bar = ("#" * $filled) + ("-" * $empty)
                Write-Host "`r    ${label} ${MountPoint}: [${bar}] ${pct}%   " -NoNewline -ForegroundColor $color
                $lastPct = $pct
            }
            if ($status -eq "FullyEncrypted" -or $status -eq "FullyDecrypted") {
                Write-Host ""; Write-Host ""
                $doneMsg = if ($Mode -eq "Encrypting") { "Encryption complete." } else { "Decryption complete." }
                Escribir-Centrado $doneMsg "Green"
                Write-Log "${doneMsg} Disk: ${MountPoint}"
                break
            }
            Start-Sleep -Seconds 3
        }
    } catch { Write-Host ""; Write-Host ""; Escribir-Centrado "Monitoring stopped. Continues in background." "Yellow" }
}

# ==================== HEALTH CHECK PRE-ENCRIPTACION ====================

function Test-PreEncryptionHealth {
    param([string]$MountPoint)
    
    $issues = @(); $warnings = @(); $canProceed = $true
    $driveLetter = $MountPoint.TrimEnd(':')
    
    Write-Host ""
    Escribir-Centrado "PRE-ENCRYPTION HEALTH CHECK" "Yellow"
    Write-Host ""
    
    # 1. BATERIA (critico en laptops)
    Write-Host "    [1/5] Battery..." -NoNewline -ForegroundColor DarkGray
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $charge = $battery.EstimatedChargeRemaining
        $plugged = $battery.BatteryStatus -eq 2
        if ($charge -lt 30 -and -not $plugged) {
            $issues += "BATERIA CRITICA: ${charge}% sin cargador. Conecta el cargador antes de encriptar."
            $canProceed = $false
            Write-Host " FALLO (${charge}%)" -ForegroundColor Red
        } elseif ($charge -lt 50 -and -not $plugged) {
            $warnings += "Battery al ${charge}%. Se recomienda conectar el cargador."
            Write-Host " WARNING (${charge}%)" -ForegroundColor Yellow
        } elseif ($plugged) {
            Write-Host " OK (${charge}%, cargador conectado)" -ForegroundColor Green
        } else {
            Write-Host " OK (${charge}%)" -ForegroundColor Green
        }
    } else {
        Write-Host " N/A (desktop)" -ForegroundColor Gray
    }
    
    # 2. ESPACIO EN DISCO
    Write-Host "    [2/5] Disk space..." -NoNewline -ForegroundColor DarkGray
    $logDisk = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -eq $MountPoint }
    if ($logDisk) {
        $freeGB = [math]::Round($logDisk.FreeSpace / 1GB, 1)
        $totalGB = [math]::Round($logDisk.Size / 1GB, 1)
        $usedPct = [math]::Round((($logDisk.Size - $logDisk.FreeSpace) / $logDisk.Size) * 100, 0)
        if ($freeGB -lt 1) {
            $issues += "DISCO CASI LLENO: Only ${freeGB}GB libre. BitLocker necesita espacio para metadatos."
            $canProceed = $false
            Write-Host " FALLO (${freeGB}GB libre)" -ForegroundColor Red
        } elseif ($usedPct -gt 95) {
            $warnings += "Disk al ${usedPct}% de capacidad. Recomendado liberar espacio."
            Write-Host " WARNING (${usedPct}%)" -ForegroundColor Yellow
        } else {
            Write-Host " OK (${freeGB}GB libre de ${totalGB}GB)" -ForegroundColor Green
        }
    } else {
        Write-Host " N/A" -ForegroundColor Gray
    }
    
    # 3. ESTADO SMART DEL DISCO
    Write-Host "    [3/5] Disk health (SMART)..." -NoNewline -ForegroundColor DarkGray
    try {
        $partition = Get-Partition -DriveLetter $driveLetter -ErrorAction Stop
        $physDisk = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $partition.DiskNumber.ToString() }
        if (-not $physDisk) {
            $physDisk = Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($physDisk) {
            $health = $physDisk.HealthStatus.ToString()
            if ($health -ne "Healthy") {
                $issues += "DISCO CON PROBLEMAS: Estado SMART = ${health}. Encriptar un disk danado puede causar perdida total."
                $canProceed = $false
                Write-Host " FALLO (${health})" -ForegroundColor Red
            } else {
                $opStatus = if ($physDisk.OperationalStatus) { $physDisk.OperationalStatus.ToString() } else { "OK" }
                Write-Host " OK (${health}, ${opStatus})" -ForegroundColor Green
            }
        } else {
            Write-Host " No verificable" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " No verificable" -ForegroundColor Yellow
    }
    
    # 4. SISTEMA DE ARCHIVOS
    Write-Host "    [4/5] File system..." -NoNewline -ForegroundColor DarkGray
    try {
        $vol = Get-Volume -DriveLetter $driveLetter -ErrorAction Stop
        $fs = if ($vol.FileSystem) { $vol.FileSystem } else { "Desconocido" }
        if ($fs -ne "NTFS" -and $fs -ne "ReFS") {
            $issues += "SISTEMA DE ARCHIVOS INCOMPATIBLE: ${fs}. BitLocker requiere NTFS o ReFS."
            $canProceed = $false
            Write-Host " FALLO (${fs})" -ForegroundColor Red
        } else {
            Write-Host " OK (${fs})" -ForegroundColor Green
        }
    } catch {
        Write-Host " No verificable" -ForegroundColor Yellow
    }
    
    # 5. PROCESOS CRITICOS
    Write-Host "    [5/5] Critical processes..." -NoNewline -ForegroundColor DarkGray
    $chkdsk = Get-Process -Name "chkdsk" -ErrorAction SilentlyContinue
    $defrag = Get-Process -Name "defrag" -ErrorAction SilentlyContinue
    if ($chkdsk -or $defrag) {
        $procName = if ($chkdsk) { "chkdsk" } else { "defrag" }
        $warnings += "${procName} en execution. Espera a que termine antes de encriptar."
        Write-Host " WARNING (${procName} activo)" -ForegroundColor Yellow
    } else {
        Write-Host " OK" -ForegroundColor Green
    }
    
    # RESUMEN
    Write-Host ""
    if ($issues.Count -gt 0) {
        Escribir-Centrado "CRITICAL ISSUES (not recommended to continue):" "Red"
        foreach ($issue in $issues) { Write-Host "    [X] ${issue}" -ForegroundColor Red }
    }
    if ($warnings.Count -gt 0) {
        Write-Host ""
        Escribir-Centrado "WARNINGS:" "Yellow"
        foreach ($warn in $warnings) { Write-Host "    [!] ${warn}" -ForegroundColor Yellow }
    }
    if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
        Escribir-Centrado "ALL CHECKS PASSED" "Green"
    }
    
    Write-Log "HealthCheck ${MountPoint}: Issues=${issues.Count}, Warnings=${warnings.Count}, CanProceed=${canProceed}"
    
    return @{ CanProceed = $canProceed; Issues = $issues; Warnings = $warnings }
}

# ==================== ALERTA DISCOS SIN PROTEGER ====================

function Show-UnprotectedAlert {
    $allVols = Get-BitLockerVolume -ErrorAction SilentlyContinue
    if (-not $allVols) { return }
    
    $unprotected = @()
    foreach ($v in $allVols) {
        # Only alertar disks del sistema y datos (no removibles)
        $driveLetter = $v.MountPoint.TrimEnd(':')
        try {
            $volInfo = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
            if ($volInfo -and $volInfo.DriveType -eq 'Fixed' -and $v.VolumeStatus -eq 'FullyDecrypted') {
                $capGB = if ($v.CapacityGB) { "{0:N0}" -f $v.CapacityGB } else { "?" }
                $unprotected += "${driveLetter}: (${capGB}GB)"
            }
        } catch { }
    }
    
    if ($unprotected.Count -gt 0) {
        Write-Host ""
        $alertLine = "ALERTA: $($unprotected.Count) disk(s) fijo(s) UNPROTECTED: $($unprotected -join ', ')"
        Escribir-Centrado $alertLine "Red"
    }
}

# ==================== GENERAR QR ====================

function Generate-QRCode {
    param([string]$Data, [string]$OutputPath, [string]$Label = "")
    
    # Generar QR como HTML con tabla (funciona sin dependencias externas)
    # Usa una representación simple que se puede imprimir
    
    $qrSize = 21  # QR Version 1
    
    # Método alternativo: generar imagen BMP usando .NET
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        
        $cellSize = 10
        $margin = 40
        $textHeight = if ($Label) { 60 } else { 0 }
        
        # Generar patrón QR simplificado (encode como texto legible en imagen)
        $lines = @()
        $lines += "ATLAS PC SUPPORT"
        $lines += "BITLOCKER RECOVERY KEY"
        $lines += ""
        if ($Label) { $lines += $Label; $lines += "" }
        
        # Dividir la clave en grupos legibles
        $lines += "CLAVE:"
        if ($Data.Length -gt 20) {
            $chunks = [regex]::Matches($Data, '.{1,12}') | ForEach-Object { $_.Value }
            foreach ($chunk in $chunks) { $lines += "  $chunk" }
        } else {
            $lines += "  $Data"
        }
        $lines += ""
        $lines += "Date: $(Get-Date -Format 'dd/MM/yyyy')"
        $lines += "PC: $env:COMPUTERNAME"
        
        # Crear imagen
        $imgWidth = 500
        $lineHeight = 22
        $imgHeight = ($lines.Count * $lineHeight) + 80
        
        $bmp = New-Object System.Drawing.Bitmap($imgWidth, $imgHeight)
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.Clear([System.Drawing.Color]::White)
        
        # Borde
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 2)
        $gfx.DrawRectangle($pen, 5, 5, $imgWidth - 10, $imgHeight - 10)
        
        # Texto
        $fontTitle = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $fontNormal = New-Object System.Drawing.Font("Consolas", 12)
        $fontKey = New-Object System.Drawing.Font("Consolas", 13, [System.Drawing.FontStyle]::Bold)
        $brush = [System.Drawing.Brushes]::Black
        $brushRed = [System.Drawing.Brushes]::DarkRed
        
        $y = 20
        foreach ($line in $lines) {
            $font = $fontNormal
            $b = $brush
            if ($line -match "^ATLAS|^BITLOCKER") { $font = $fontTitle }
            if ($line -match "^\s{2}\d" -or $line -match "^\s{2}[A-F0-9]") { $font = $fontKey; $b = $brushRed }
            $gfx.DrawString($line, $font, $b, 20, $y)
            $y += $lineHeight
        }
        
        $gfx.Dispose()
        $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        
        return $true
    } catch {
        # Fallback: guardar como texto formateado para imprimir
        $txtPath = $OutputPath -replace '\.png$', '.txt'
        $border = "+" + ("-" * 48) + "+"
        $content = @()
        $content += $border
        $content += "|  ATLAS PC SUPPORT - BITLOCKER RECOVERY KEY    |"
        $content += $border
        if ($Label) { $content += "|  ${Label}".PadRight(49) + "|" }
        $content += "|  CLAVE:".PadRight(49) + "|"
        $content += "|  ${Data}".PadRight(49) + "|"
        $content += "|  PC: $env:COMPUTERNAME | $(Get-Date -Format 'dd/MM/yyyy')".PadRight(49) + "|"
        $content += $border
        $content += "  Cut out and stick on the computer case."
        
        $content -join "`r`n" | Out-File -FilePath $txtPath -Encoding UTF8
        return $txtPath
    }
}

# ==================== BACKUP A AD / AZURE ====================

function Backup-KeyToAD {
    param([string]$MountPoint)
    
    $vol = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction SilentlyContinue
    if (-not $vol) { return $false }
    
    $recoveryKeys = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
    if (-not $recoveryKeys) {
        Write-Host "    No recovery keys to back up." -ForegroundColor Yellow
        return $false
    }
    
    $success = $false
    
    foreach ($key in $recoveryKeys) {
        $keyId = $key.KeyProtectorId
        
        # Intentar AD On-Premise
        Write-Host "    Trying backup to Active Directory..." -ForegroundColor DarkGray
        try {
            Backup-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $keyId -ErrorAction Stop
            Write-Host "    [OK] Key backed up to Active Directory." -ForegroundColor Green
            Write-Log "AD Backup OK: ${MountPoint} KeyID: ${keyId}"
            $success = $true
        } catch {
            $adError = $_.Exception.Message
            if ($adError -match "not joined|domain|directory") {
                Write-Host "    [--] Computer is not joined to AD domain." -ForegroundColor DarkGray
            } else {
                Write-Host "    [--] AD not available: $adError" -ForegroundColor DarkGray
            }
        }
        
        # Intentar Azure AD
        Write-Host "    Trying backup to Azure AD / Entra ID..." -ForegroundColor DarkGray
        try {
            $dsregStatus = dsregcmd /status 2>&1
            $isAzureJoined = ($dsregStatus | Select-String "AzureAdJoined\s*:\s*YES" -Quiet)
            
            if ($isAzureJoined) {
                BackupToAAD-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $keyId -ErrorAction Stop
                Write-Host "    [OK] Key backed up to Azure AD / Entra ID." -ForegroundColor Green
                Write-Log "Azure AD Backup OK: ${MountPoint} KeyID: ${keyId}"
                $success = $true
            } else {
                Write-Host "    [--] Computer is not joined to Azure AD." -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "    [--] Azure AD not available." -ForegroundColor DarkGray
        }
    }
    
    return $success
}

# ==================== MODO CLI ====================

if ($Action -ne "") {
    switch ($Action) {
        "Extract" {
            $VolumenesBL = Get-BitLockerVolume -ErrorAction SilentlyContinue | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' }
            if (-not $VolumenesBL) { Write-Host "No protected disks."; exit 1 }
            
            $outputPath = if ($Output) { $Output } else { Join-Path ([Environment]::GetFolderPath("Desktop")) "BL_$env:COMPUTERNAME_$(Get-Date -Format 'yyyyMMdd_HHmm').txt" }
            
            $content = "ATLAS PC SUPPORT - BITLOCKER KEYS`r`nPC: $env:COMPUTERNAME`r`nDate: $(Get-Date)`r`n---`r`n"
            foreach ($Vol in $VolumenesBL) {
                $keys = $Vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
                foreach ($k in $keys) {
                    $content += "$($Vol.MountPoint) -> $($k.RecoveryPassword)`r`n"
                    Write-Host "$($Vol.MountPoint) -> $($k.RecoveryPassword)"
                }
            }
            $content | Out-File -FilePath $outputPath -Encoding UTF8
            Write-Host "Saved to: ${outputPath}"
            Write-Log "CLI Extract: ${outputPath}"
            return
        }
        "Status" {
            $vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
            foreach ($v in $vols) {
                $status = $v.VolumeStatus.ToString()
                $pct = $v.EncryptionPercentage
                Write-Host "$($v.MountPoint) | ${status} | ${pct}%"
            }
            return
        }
    }
}

# ==================== MENU PRINCIPAL ====================

Clear-Host

while ($true) {
    Clear-Host
    Write-AtlasHeaderCompat -Title "BITLOCKER MANAGER v3" -Subtitle "Encrypt · Backup Keys · Health Check · AD Sync"
    
    # TPM status
    Write-Host ""
    $tpmInfo = Get-TPMStatus
    $tpmColor = if ($tpmInfo.HasTPM -and $tpmInfo.IsReady) { "Green" } elseif ($tpmInfo.HasTPM) { "Yellow" } else { "Red" }
    Escribir-Centrado "TPM: $($tpmInfo.Summary)" $tpmColor
    
    # Disks protegidos
    $blVolumes = Get-BitLockerVolume -ErrorAction SilentlyContinue | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' }
    $blCount = if ($blVolumes) { @($blVolumes).Count } else { 0 }
    Escribir-Centrado "Disks protegidos: ${blCount}" $(if ($blCount -gt 0) { "Cyan" } else { "DarkGray" })
    
    # ALERTA DISCOS SIN PROTEGER
    Show-UnprotectedAlert
    
    Write-Host ""
    Escribir-Centrado "[ 1 ] Escanear y Guardar Claves" "White"
    Escribir-Centrado "[ 2 ] Activar BitLocker" "White"
    Escribir-Centrado "[ 3 ] Desactivar BitLocker" "White"
    Escribir-Centrado "[ 4 ] Ver Estado Completo" "White"
    Escribir-Centrado "[ 5 ] Ver Historial de Operaciones" "White"
    Escribir-Centrado "[ S ] Salir" "DarkGray"
    Write-Host ""
    Escribir-Centrado "===================================================" "DarkGray"
    Write-Host ""
    
    $Option = Read-Host "  Option"

    switch ($Option.ToUpper()) {
        # =============================================
        # 1. EXTRAER CLAVES (+ USB + QR + AD + Clipboard)
        # =============================================
        "1" {
            Clear-Host
            Write-Host "`n"
            Escribir-Centrado "=== EXTRACCION DE CLAVES BITLOCKER ===" "DarkYellow"
            Write-Host ""
            
            $NombreComputer = $env:COMPUTERNAME
            $UserActual = $env:USERNAME
            $FechaHora = Get-Date -Format 'dd-MM-yyyy_HHmm'
            $NombreArchivo = "BL_${NombreComputer}_${FechaHora}.txt"
            
            Write-Host "    Scanning disks protegidos..." -ForegroundColor DarkGray
            $VolumenesBL = Get-BitLockerVolume -ErrorAction SilentlyContinue | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' }
            
            if (-not $VolumenesBL) {
                Escribir-Centrado "No disks with BitLocker active found." "Red"
            } else {
                $Contenido = "===================================================`r`n"
                $Contenido += "      ATLAS PC SUPPORT - RESPALDO DE BITLOCKER`r`n"
                $Contenido += "===================================================`r`n"
                $Contenido += "Fecha               : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`r`n"
                $Contenido += "Nombre del Computer   : ${NombreComputer}`r`n"
                $Contenido += "User Activo      : ${UserActual}`r`n"
                $Contenido += "---------------------------------------------------`r`n`r`n"
                
                $ClavesEncontradas = 0
                $clavesParaClipboard = @()
                $clavesParaQR = @()
                
                foreach ($Vol in $VolumenesBL) {
                    $Claves = $Vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
                    if ($Claves) {
                        foreach ($Clave in $Claves) {
                            $mount = $Vol.MountPoint
                            $key = $Clave.RecoveryPassword
                            $keyId = $Clave.KeyProtectorId
                            
                            $Contenido += "UNIDAD: ${mount}`r`n"
                            $Contenido += "ID:     ${keyId}`r`n"
                            $Contenido += "CLAVE:  ${key}`r`n`r`n"
                            
                            $clavesParaClipboard += "${mount} -> ${key}"
                            $clavesParaQR += @{ Mount = $mount; Key = $key; KeyId = $keyId }
                            
                            Write-Host "    [OK] ${mount} -> ${key}" -ForegroundColor Green
                            $ClavesEncontradas++
                        }
                    }
                }
                
                if ($ClavesEncontradas -eq 0) {
                    Escribir-Centrado "No se encontraron recovery keys." "Red"
                } else {
                    $Contenido += "===================================================`r`n"
                    $Contenido += "TOTAL: ${ClavesEncontradas} clave(s)`r`n"
                    
                    Write-Host ""
                    Escribir-Centrado "${ClavesEncontradas} clave(s) found(s)" "Green"
                    Write-Log "Extraccion: ${ClavesEncontradas} claves de ${NombreComputer}"
                    
                    $rutasGuardadas = @()
                    
                    # Guardar en desktop
                    $RutaDesktop = [Environment]::GetFolderPath("Desktop")
                    $RutaCompleta = Join-Path $RutaDesktop $NombreArchivo
                    try {
                        $Contenido | Out-File -FilePath $RutaCompleta -Encoding UTF8
                        Write-Host "    [OK] Desktop: ${NombreArchivo}" -ForegroundColor Cyan
                        $rutasGuardadas += $RutaCompleta
                    } catch { Write-Host "    [ERROR] Could not save to desktop." -ForegroundColor Red }
                    
                    # USB
                    $usbs = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter -and $_.Size -gt 0 }
                    if ($usbs) {
                        Write-Host ""
                        Write-Host "    USB detectado(s). Guardar copia? [Y/N]" -ForegroundColor Yellow
                        $usbSel = Read-Host "    >"
                        if ($usbSel -match '^[SsYy]$') {
                            foreach ($u in $usbs) {
                                try {
                                    $usbPath = Join-Path ($u.DriveLetter + ":\") $NombreArchivo
                                    $Contenido | Out-File -FilePath $usbPath -Encoding UTF8
                                    Write-Host "    [OK] USB $($u.DriveLetter): ${NombreArchivo}" -ForegroundColor Green
                                    $rutasGuardadas += $usbPath
                                } catch { Write-Host "    [ERROR] USB $($u.DriveLetter): $($_.Exception.Message)" -ForegroundColor Red }
                            }
                        }
                    }
                    
                    # QR / Imagen imprimible
                    Write-Host ""
                    Write-Host "    [!] SECURITY WARNING: Saving plaintext recovery keys as images on Desktop" -ForegroundColor Red
                    Write-Host "        creates a physical security risk. Do NOT leave this file on client desktop." -ForegroundColor Yellow
                    Write-Host "    Generate printable card image of keys? [Y/N]" -ForegroundColor Yellow
                    $qrSel = Read-Host "    >"
                    if ($qrSel -match '^[SsYy]$') {
                        foreach ($kInfo in $clavesParaQR) {
                            $qrFileName = "BL_KEY_${NombreComputer}_$($kInfo.Mount.TrimEnd(':'))_${FechaHora}.png"
                            $qrPath = Join-Path $RutaDesktop $qrFileName
                            $label = "Disk: $($kInfo.Mount) | PC: ${NombreComputer}"
                            $qrResult = Generate-QRCode -Data $kInfo.Key -OutputPath $qrPath -Label $label
                            if ($qrResult -eq $true) {
                                Write-Host "    [OK] Imagen: ${qrFileName}" -ForegroundColor Green
                                $rutasGuardadas += $qrPath
                            } elseif ($qrResult) {
                                Write-Host "    [OK] Texto imprimible: $(Split-Path $qrResult -Leaf)" -ForegroundColor Green
                                $rutasGuardadas += $qrResult
                            } else {
                                Write-Host "    [ERROR] No se genero imagen." -ForegroundColor Red
                            }
                        }
                        Write-Host ""
                        Escribir-Centrado "Print the image and stick it on the computer case." "Cyan"
                    }
                    
                    # AD / Azure AD backup
                    Write-Host ""
                    Write-Host "    Intentar backup a Active Directory / Azure AD? [Y/N]" -ForegroundColor Yellow
                    $adSel = Read-Host "    >"
                    if ($adSel -match '^[SsYy]$') {
                        foreach ($Vol in $VolumenesBL) {
                            $adOk = Backup-KeyToAD -MountPoint $Vol.MountPoint
                        }
                    }
                    
                    # Clipboard
                    Write-Host ""
                    Write-Host "    Copy keys to clipboard? [Y/N]" -ForegroundColor DarkGray
                    $clipSel = Read-Host "    >"
                    if ($clipSel -match '^[SsYy]$') {
                        try {
                            ($clavesParaClipboard -join "`r`n") | Set-Clipboard
                            Write-Host "    [OK] Copied to clipboard." -ForegroundColor Green
                        } catch { Write-Host "    [ERROR] Clipboard no disponible." -ForegroundColor Red }
                    }
                    
                    # Summary
                    Write-Host ""
                    Escribir-Centrado "RESUMEN DE BACKUPS:" "White"
                    foreach ($ruta in $rutasGuardadas) { Write-Host "    -> ${ruta}" -ForegroundColor Gray }
                }
            }
            Write-Host "`n"; Wait-AtlasReturnCompat -Message "    ENTER to go back..."
        }

        # =============================================
        # 2. ACTIVAR BITLOCKER (con Health Check)
        # =============================================
        "2" {
            Clear-Host
            Write-Host "`n"
            Escribir-Centrado "=== ACTIVAR BITLOCKER ===" "DarkYellow"
            Write-Host ""
            
            # TPM check
            $tpm = Get-TPMStatus
            $tpmColor = if ($tpm.HasTPM -and $tpm.IsReady) { "Green" } elseif ($tpm.HasTPM) { "Yellow" } else { "Red" }
            Write-Host "    TPM: $($tpm.Summary)" -ForegroundColor $tpmColor
            
            if (-not $tpm.HasTPM) {
                Write-Host "    No TPM = password required at every boot." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "    [C] Continue with password  [B] Back" -ForegroundColor White
                $tpmChoice = Read-Host "    >"
                if ($tpmChoice -ne "C" -and $tpmChoice -ne "c") { continue }
            } elseif (-not $tpm.IsReady) {
                Write-Host "    May require activation in BIOS." -ForegroundColor Yellow
            }
            
            Write-Host ""
            $allVolumes = Show-DiskTable
            if (-not $allVolumes) { Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue }
            
            Write-Host "    Disk to encrypt (or [B] to go back):" -ForegroundColor White
            $input = Read-Host "    >"
            if ($input -eq "B" -or $input -eq "b") { continue }
            
            $validated = Validate-DriveLetter -Input $input -ValidVolumes $allVolumes
            if (-not $validated) { Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue }
            
            $disk = $validated.Letter; $vol = $validated.Volume
            
            if ($vol.VolumeStatus -eq 'FullyEncrypted') {
                Write-Host "    ${disk} YA esta encriptado." -ForegroundColor Yellow
                Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue
            }
            if ($vol.VolumeStatus -eq 'EncryptionInProgress') {
                Write-Host "    ${disk} ya se esta encriptando." -ForegroundColor Yellow
                Show-EncryptionProgress -MountPoint $disk -Mode "Encrypting"
                Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue
            }
            
            # HEALTH CHECK
            $health = Test-PreEncryptionHealth -MountPoint $disk
            
            if (-not $health.CanProceed) {
                Write-Host ""
                Escribir-Centrado "NO SE RECOMIENDA ENCRIPTAR EN ESTE ESTADO." "Red"
                Write-Host ""
                Write-Host "    [F] Force anyway  [B] Back (recommended)" -ForegroundColor Yellow
                $forceChoice = Read-Host "    >"
                if ($forceChoice -ne "F" -and $forceChoice -ne "f") {
                    Write-Log "Encryption cancelled por HealthCheck: ${disk}"
                    continue
                }
                Write-Log "HealthCheck FORZADO por user: ${disk}"
            }
            
            # Confirmación
            $capGB = if ($vol.CapacityGB) { "{0:N1}" -f $vol.CapacityGB } else { "?" }
            Write-Host ""
            Escribir-Centrado "CONFIRMAR: Activar BitLocker en ${disk} (${capGB} GB)?" "Yellow"
            Write-Host "    [S] Encriptar  [N] Cancelar" -ForegroundColor White
            $confirm = Read-Host "    >"
            if ($confirm -ne "S" -and $confirm -ne "s") { continue }
            
            Write-Host ""
            Write-Host "    Activating BitLocker on ${disk}..." -ForegroundColor Yellow
            
            try {
                if ($tpm.HasTPM -and $tpm.IsReady) {
                    Enable-BitLocker -MountPoint $disk -EncryptionMethod XtsAes256 -RecoveryPasswordProtector -ErrorAction Stop
                } else {
                    Write-Host "    Enter boot password:" -ForegroundColor Cyan
                    $secPwd = Read-Host "    Password" -AsSecureString
                    Enable-BitLocker -MountPoint $disk -EncryptionMethod XtsAes256 -PasswordProtector -Password $secPwd -ErrorAction Stop
                    Add-BitLockerKeyProtector -MountPoint $disk -RecoveryPasswordProtector -ErrorAction Stop
                }
                
                Write-Host ""
                Escribir-Centrado "BitLocker ACTIVADO en ${disk}" "Green"
                Escribir-Centrado "USA OPCION [1] PARA GUARDAR LA CLAVE!" "Cyan"
                Write-Log "BitLocker ACTIVADO: ${disk} (XtsAes256)"
                
                # AD backup automatico
                Write-Host ""
                Backup-KeyToAD -MountPoint $disk
                
                Write-Host ""
                Write-Host "    [M] Monitorear progreso  [ENTER] Volver" -ForegroundColor DarkGray
                $monSel = Read-Host "    >"
                if ($monSel -eq "M" -or $monSel -eq "m") {
                    Show-EncryptionProgress -MountPoint $disk -Mode "Encrypting"
                }
            } catch {
                Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "ERROR activando BitLocker ${disk}: $($_.Exception.Message)" "ERROR"
                
                $msg = $_.Exception.Message
                if ($msg -match "TPM") {
                    Write-Host "    SUGGESTION: Enable TPM in BIOS." -ForegroundColor Yellow
                }
                if ($msg -match "policy|Group Policy") {
                    Write-Host "    SUGERENCIA: gpedit.msc > Computer Config > Admin Templates > BitLocker" -ForegroundColor Yellow
                }
            }
            Write-Host ""; Wait-AtlasReturnCompat -Message "    ENTER to go back..."
        }

        # =============================================
        # 3. DESACTIVAR BITLOCKER
        # =============================================
        "3" {
            Clear-Host
            Write-Host "`n"
            Escribir-Centrado "=== DESACTIVAR BITLOCKER ===" "DarkYellow"
            Write-Host ""
            
            $encVolumes = Show-DiskTable -OnlyEncrypted
            if (-not $encVolumes) { Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue }
            
            Write-Host "    Disk a desencriptar (o [B]):" -ForegroundColor White
            $input = Read-Host "    >"
            if ($input -eq "B" -or $input -eq "b") { continue }
            
            $validated = Validate-DriveLetter -Input $input -ValidVolumes $encVolumes
            if (-not $validated) { Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue }
            
            $disk = $validated.Letter; $vol = $validated.Volume
            
            if ($vol.VolumeStatus -eq 'DecryptionInProgress') {
                Write-Host "    Already being decrypted." -ForegroundColor Yellow
                Show-EncryptionProgress -MountPoint $disk -Mode "Decrypting"
                Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue
            }
            
            $capGB = if ($vol.CapacityGB) { "{0:N1}" -f $vol.CapacityGB } else { "?" }
            Write-Host ""
            Escribir-Centrado "CONFIRMAR: Desactivar BitLocker en ${disk} (${capGB} GB)?" "Red"
            Write-Host "    WARNING: Data will be left unprotected." -ForegroundColor Yellow
            Write-Host "    [S] Desencriptar  [N] Cancelar" -ForegroundColor White
            $confirm = Read-Host "    >"
            if ($confirm -ne "S" -and $confirm -ne "s") { continue }
            
            try {
                Disable-BitLocker -MountPoint $disk -ErrorAction Stop
                Escribir-Centrado "Decryption iniciada en ${disk}." "Green"
                Write-Log "BitLocker DESACTIVADO: ${disk}"
                
                Write-Host "    [M] Monitorear  [ENTER] Volver" -ForegroundColor DarkGray
                $monSel = Read-Host "    >"
                if ($monSel -eq "M" -or $monSel -eq "m") {
                    Show-EncryptionProgress -MountPoint $disk -Mode "Decrypting"
                }
            } catch {
                Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "ERROR desactivando ${disk}: $($_.Exception.Message)" "ERROR"
            }
            Write-Host ""; Wait-AtlasReturnCompat -Message "    ENTER to go back..."
        }

        # =============================================
        # 4. ESTADO COMPLETO
        # =============================================
        "4" {
            Clear-Host
            Write-Host "`n"
            Escribir-Centrado "=== ESTADO COMPLETO ===" "DarkYellow"
            Write-Host ""
            
            $tpm = Get-TPMStatus
            $tpmColor = if ($tpm.HasTPM -and $tpm.IsReady) { "Green" } elseif ($tpm.HasTPM) { "Yellow" } else { "Red" }
            Write-Host "    TPM: $($tpm.Summary)" -ForegroundColor $tpmColor
            
            Show-DiskTable | Out-Null
            
            # Alerta
            Show-UnprotectedAlert
            
            # Protectores
            Write-Host ""
            Write-Host "    PROTECTORES ACTIVOS:" -ForegroundColor DarkGray
            Write-Host "    --------------------" -ForegroundColor DarkGray
            $allVols = Get-BitLockerVolume -ErrorAction SilentlyContinue
            $hasProtectors = $false
            foreach ($v in $allVols) {
                if ($v.VolumeStatus -ne 'FullyDecrypted' -and $v.KeyProtector) {
                    foreach ($kp in $v.KeyProtector) {
                        $kpType = $kp.KeyProtectorType.ToString()
                        $kpId = if ($kp.KeyProtectorId) { $kp.KeyProtectorId.Substring(0, [math]::Min(20, $kp.KeyProtectorId.Length)) + "..." } else { "" }
                        $typeLabel = switch ($kpType) {
                            "RecoveryPassword" { "Clave Recovery" }
                            "Tpm" { "TPM" }
                            "TpmPin" { "TPM + PIN" }
                            "Password" { "Password" }
                            "ExternalKey" { "Llave Externa" }
                            default { $kpType }
                        }
                        Write-Host "    $($v.MountPoint) -> ${typeLabel} ${kpId}" -ForegroundColor Gray
                        $hasProtectors = $true
                    }
                }
            }
            if (-not $hasProtectors) { Write-Host "    (none)" -ForegroundColor DarkGray }
            
            Write-Host "`n"; Wait-AtlasReturnCompat -Message "    ENTER to go back..."
        }

        # =============================================
        # 5. HISTORIAL
        # =============================================
        "5" {
            Clear-Host
            Write-Host "`n"
            Escribir-Centrado "=== HISTORIAL DE OPERACIONES ===" "DarkYellow"
            Write-Host ""
            
            if (Test-Path $logFile) {
                $logContent = Get-Content $logFile -Tail 50 -ErrorAction SilentlyContinue
                if ($logContent) {
                    Write-Host "    Last operations (max 50):" -ForegroundColor DarkGray
                    Write-Host "    " + ("-" * 80) -ForegroundColor DarkGray
                    Write-Host ""
                    foreach ($line in $logContent) {
                        $lineColor = "Gray"
                        if ($line -match "ERROR") { $lineColor = "Red" }
                        elseif ($line -match "ACTIVADO") { $lineColor = "Green" }
                        elseif ($line -match "DESACTIVADO") { $lineColor = "Yellow" }
                        elseif ($line -match "Extraccion|Extract") { $lineColor = "Cyan" }
                        elseif ($line -match "FORZADO") { $lineColor = "Red" }
                        Write-Host "    ${line}" -ForegroundColor $lineColor
                    }
                } else {
                    Write-Host "    Log vacio." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "    No hay historial aun." -ForegroundColor DarkGray
                Write-Host "    Created automatically with each operation." -ForegroundColor DarkGray
            }
            
            Write-Host ""
            Write-Host "    File: ${logFile}" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "    [L] Limpiar historial  [ENTER] Volver" -ForegroundColor DarkGray
            $logAction = Read-Host "    >"
            if ($logAction -eq "L" -or $logAction -eq "l") {
                Write-Host "    Seguro? [Y/N]" -ForegroundColor Yellow
                $logConfirm = Read-Host "    >"
                if ($logConfirm -match '^[SsYy]$') {
                    Remove-Item $logFile -Force -ErrorAction SilentlyContinue
                    Write-Host "    Historial limpiado." -ForegroundColor Green
                    Start-Sleep 1
                }
            }
        }

        "S" {
            Write-Host ""
            Escribir-Centrado "Cerrando..." "DarkYellow"
            Write-Log "Sesion cerrada"
            Start-Sleep -Seconds 1
            [console]::ResetColor()
            Clear-Host
            return
        }

        default {
            Escribir-Centrado "Option no valida." "Red"
            Start-Sleep -Seconds 1
        }
    }
}
}
