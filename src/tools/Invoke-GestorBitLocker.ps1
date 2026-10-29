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
        [string]$MountPoint = "",
        [switch]$Reveal
    )
# =======================================================
# Gestor de BitLocker v3 - Atlas PC Support
# TPM + Progreso + Backup elegido + tarjeta imprimible + Health Check + Log
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
    try { $entry | Out-File -FilePath $logFile -Append -Encoding UTF8 -ErrorAction Stop } catch {Write-Warning 'BitLocker operation log could not be written; no password values were logged.'}
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
    param([string]$DriveInput, [array]$ValidVolumes)
    if ([string]::IsNullOrWhiteSpace($DriveInput)) { return $null }
    $clean = $DriveInput.Trim().ToUpper().Replace(":", "")
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
            $tpmWMI = Get-CimInstance -OperationTimeoutSec 10 -Namespace "root\cimv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction Stop
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

function Get-AtlasRecoveryBackupFolder {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$MountPoint,[Parameter(Mandatory)][string]$Directory)
    $folder=Get-Item -LiteralPath $Directory -ErrorAction Stop
    if($MountPoint -notmatch '^[A-Za-z]:$' -or -not $folder.PSIsContainer -or $folder.PSProvider.Name -ne 'FileSystem' -or $folder.FullName -notmatch '^[A-Za-z]:\\'){
        throw 'Select an existing folder on a separate local backup disk.'
    }
    $ancestor=$folder
    while($ancestor){if($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Recovery backup folders must not contain junctions or symbolic links.'};$ancestor=$ancestor.Parent}
    $sourceDisk=@(Get-Partition -DriveLetter $MountPoint.Substring(0,1) -ErrorAction Stop)
    $backupDisk=@(Get-Partition -DriveLetter $folder.FullName.Substring(0,1) -ErrorAction Stop)
    if($sourceDisk.Count -ne 1 -or $backupDisk.Count -ne 1 -or $null -eq $sourceDisk[0].DiskNumber -or $null -eq $backupDisk[0].DiskNumber -or $sourceDisk[0].DiskNumber -eq $backupDisk[0].DiskNumber){
        throw 'The recovery backup must be on a different physical disk from the encrypted volume.'
    }
    return $folder.FullName
}

function Write-AtlasRecoveryText {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Content)
    Assert-AtlasPlainDirectory (Split-Path -Parent $Path)
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes($Content)
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
    if([IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8) -cne $Content){throw 'Recovery backup read-back failed; do not rely on this file.'}
    return $Path
}

function Save-AtlasRecoveryBackup {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$MountPoint,[Parameter(Mandatory)][string]$Directory,[Parameter(Mandatory)]$Protector)
    if(-not $Protector.KeyProtectorId -or $Protector.RecoveryPassword -notmatch '^\d{6}(-\d{6}){7}$'){throw 'A readable recovery password and protector ID are required.'}
    $folder=Get-AtlasRecoveryBackupFolder -MountPoint $MountPoint -Directory $Directory
    $path=Join-Path $folder ('BitLocker-Recovery-'+[guid]::NewGuid().ToString('N')+'.txt')
    $content="BitLocker recovery / recuperacion`r`nVolume: $MountPoint`r`nKey ID: $($Protector.KeyProtectorId)`r`nRecovery password: $($Protector.RecoveryPassword)`r`n"
    return Write-AtlasRecoveryText -Path $path -Content $content
}

function Get-AtlasRecoveryRecords {
    [CmdletBinding()]
    param([string]$MountPoint)
    $query=@{ErrorAction='Stop'}
    if($MountPoint){if($MountPoint -notmatch '^[A-Za-z]:$'){throw 'Invalid volume letter.'};$query.MountPoint=$MountPoint}
    foreach($volume in @(Get-BitLockerVolume @query)) {
        if($volume.VolumeStatus -eq 'FullyDecrypted'){continue}
        foreach($key in @($volume.KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'})) {
            if(-not $key.KeyProtectorId -or $key.RecoveryPassword -notmatch '^\d{6}(-\d{6}){7}$'){throw 'A recovery protector could not be read. No complete export can be claimed.'}
            [pscustomobject]@{MountPoint=[string]$volume.MountPoint;KeyId=[string]$key.KeyProtectorId;RecoveryPassword=[string]$key.RecoveryPassword}
        }
    }
}

function Export-AtlasRecoveryKeys {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Records,[Parameter(Mandatory)][string]$OutputPath)
    if(-not $Records.Count){throw 'No readable recovery passwords to export.'}
    if($OutputPath -notmatch '^[A-Za-z]:\\' -or [IO.Path]::GetExtension($OutputPath) -ine '.txt'){throw 'Choose an explicit absolute .txt destination on a separate local disk.'}
    $path=[IO.Path]::GetFullPath($OutputPath);$directory=Split-Path -Parent $path
    # Validate every source and secret before the first write.
    foreach($record in $Records){
        if(-not $record.KeyId -or $record.RecoveryPassword -notmatch '^\d{6}(-\d{6}){7}$'){throw 'A readable recovery password and protector ID are required.'}
        $null=Get-AtlasRecoveryBackupFolder -MountPoint $record.MountPoint -Directory $directory
    }
    $lines=@('ATLAS PC SUPPORT - BITLOCKER RECOVERY','Keep separately from the protected device.',('UTC: '+[datetime]::UtcNow.ToString('o')))
    foreach($record in $Records){$lines+=@(('Volume: '+$record.MountPoint),('Key ID: '+$record.KeyId),('Recovery password: '+$record.RecoveryPassword),'')}
    return Write-AtlasRecoveryText -Path $path -Content ($lines -join "`r`n")
}

function Invoke-AtlasRecoveryExportMenu {
    $mount=Read-Host 'Volume to export, for example C:; Enter selects all; B cancels'
    if($mount -ieq 'B'){return}
    $records=@(Get-AtlasRecoveryRecords -MountPoint $mount)
    if(-not $records.Count){Write-Host 'No readable recovery passwords observed.' -ForegroundColor Yellow;return}
    Write-Host "$($records.Count) recovery password(s) found; values hidden."
    $outputPath=Read-Host 'Full NEW .txt path on another physical disk; Enter cancels'
    if([string]::IsNullOrWhiteSpace($outputPath)){return}
    $saved=Export-AtlasRecoveryKeys -Records $records -OutputPath $outputPath
    Write-Host "Verified recovery file: $saved" -ForegroundColor Green
    Write-Log "Recovery export verified: $($records.Count) password(s); values omitted."
    if((Read-Host 'Type REVEAL to show passwords here; Enter keeps them hidden') -ceq 'REVEAL'){
        foreach($record in $records){Write-Host "$($record.MountPoint) -> $($record.RecoveryPassword)"}
    }
    if((Read-Host 'Type CARD to create printable cards in the chosen folder; Enter skips') -ceq 'CARD'){
        foreach($record in $records){
            $card=Join-Path (Split-Path -Parent $saved) ('BitLocker-Card-'+[guid]::NewGuid().ToString('N')+'.png')
            $file=New-AtlasRecoveryCard -Data $record.RecoveryPassword -OutputPath $card -Label ("Volume: "+$record.MountPoint+" | Key ID: "+$record.KeyId)
            Write-Host "Printable card saved: $file"
        }
    }
    if((Read-Host 'Type BACKUP to request AD/Entra backup; Enter skips') -ceq 'BACKUP'){
        foreach($letter in @($records.MountPoint|Select-Object -Unique)){$null=Backup-KeyToAD -MountPoint $letter}
    }
    if((Read-Host 'Type COPY to place passwords on the clipboard; Enter skips') -ceq 'COPY'){
        ($records|ForEach-Object {"$($_.MountPoint) -> $($_.RecoveryPassword)"}) -join "`r`n" | Set-Clipboard -ErrorAction Stop
        Write-Host 'Passwords copied. Clear clipboard history after use.'
    }
}

function Enable-AtlasBitLockerSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$MountPoint,
        [Parameter(Mandatory)][string]$RecoveryDirectory,
        [securestring]$Password
    )
    if ($MountPoint -notmatch '^[A-Za-z]:$') { throw 'A drive-letter volume is required.' }
    $volume = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction Stop
    if ($volume.VolumeStatus.ToString() -ne 'FullyDecrypted' -or $volume.LockStatus.ToString() -ne 'Unlocked') {
        throw 'Only an unlocked, fully decrypted volume can be enabled here. Existing encryption is preserved.'
    }
    $isOS = $volume.VolumeType.ToString() -eq 'OperatingSystem'
    if ($isOS) {
        $tpm = Get-Tpm -ErrorAction Stop
        if (-not $tpm.TpmPresent -or -not $tpm.TpmReady) {
            throw 'OS encryption here requires a ready TPM. Use the Windows BitLocker wizard for a policy-approved non-TPM setup.'
        }
    } elseif ($volume.VolumeType.ToString() -notin @('FixedData','RemovableData')) {
        throw 'Unsupported or unknown BitLocker volume type.'
    } elseif (-not $Password -or $Password.Length -eq 0) {
        throw 'A non-empty unlock password is required for a data volume.'
    }
    $recovery = @($volume.KeyProtector | Where-Object { $_.KeyProtectorType.ToString() -eq 'RecoveryPassword' })
    if ($recovery.Count -eq 0) {
        Add-BitLockerKeyProtector -MountPoint $MountPoint -RecoveryPasswordProtector -ErrorAction Stop | Out-Null
        $volume = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction Stop
        $recovery = @($volume.KeyProtector | Where-Object { $_.KeyProtectorType.ToString() -eq 'RecoveryPassword' })
    }
    if ($recovery.Count -eq 0) { throw 'No recovery protector was created. Encryption was not started.' }
    $backup = Save-AtlasRecoveryBackup -MountPoint $MountPoint -Directory $RecoveryDirectory -Protector $recovery[0]
    # No key is printed, written to logs or inferred to be escrowed in AD.
    if ($isOS) {
        Enable-BitLocker -MountPoint $MountPoint -EncryptionMethod XtsAes256 -TpmProtector -ErrorAction Stop | Out-Null
    } else {
        Enable-BitLocker -MountPoint $MountPoint -EncryptionMethod XtsAes256 -PasswordProtector -Password $Password -ErrorAction Stop | Out-Null
    }
    $after = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction Stop
    $types = @($after.KeyProtector | ForEach-Object { $_.KeyProtectorType.ToString() })
    $primary = if ($isOS) { 'Tpm' } else { 'Password' }
    if ($types -notcontains $primary -or $types -notcontains 'RecoveryPassword') {
        throw 'BitLocker did not report the required primary and recovery protectors. Keep the backup and inspect Windows BitLocker status.'
    }
    return [pscustomobject]@{
        MountPoint=$MountPoint; RecoveryBackup=$backup; VolumeStatus=[string]$after.VolumeStatus
        ProtectionStatus=[string]$after.ProtectionStatus; RebootMayBeRequired=$isOS
    }
}

function Test-PreEncryptionHealth {
    param([string]$MountPoint)

    $issues = @(); $warnings = @(); $canProceed = $true
    $driveLetter = $MountPoint.TrimEnd(':')

    Write-Host ""
    Escribir-Centrado "PRE-ENCRYPTION HEALTH CHECK" "Yellow"
    Write-Host ""

    # 1. BATERIA (critico en laptops)
    Write-Host "    [1/5] Battery..." -NoNewline -ForegroundColor DarkGray
    $battery = Get-CimInstance -OperationTimeoutSec 10 Win32_Battery -ErrorAction SilentlyContinue
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
    $logDisk = Get-CimInstance -OperationTimeoutSec 10 Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -eq $MountPoint }
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
        $physDisk = Get-Partition -DriveLetter $driveLetter -ErrorAction Stop | Get-Disk -ErrorAction Stop
        if ($physDisk) {
            $health = [string]$physDisk.HealthStatus
            if ($health -ne "Healthy") {
                $issues += "DISCO CON PROBLEMAS: Estado SMART = ${health}. Encriptar un disk danado puede causar perdida total."
                $canProceed = $false
                Write-Host " FALLO (${health})" -ForegroundColor Red
            } else {
                $opStatus = if ($physDisk.OperationalStatus) { $physDisk.OperationalStatus.ToString() } else { "OK" }
                Write-Host " OK (${health}, ${opStatus})" -ForegroundColor Green
            }
        } else {
            $warnings += 'Disk health could not be evaluated for this volume.'
            Write-Host " No verificable" -ForegroundColor Yellow
        }
    } catch {
        $warnings += 'Disk health could not be evaluated for this volume.'
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

# ==================== TARJETA IMPRIMIBLE ====================

function New-AtlasRecoveryCard {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Data,[Parameter(Mandatory)][string]$OutputPath,[string]$Label='')
    if($Data -notmatch '^\d{6}(-\d{6}){7}$' -or [IO.Path]::GetExtension($OutputPath) -ine '.png'){throw 'A readable recovery password and new .png path are required.'}
    Assert-AtlasPlainDirectory (Split-Path -Parent $OutputPath)
    if(Test-Path -LiteralPath $OutputPath){throw 'Printable card destination already exists.'}
    $lines=@('ATLAS PC SUPPORT','BITLOCKER RECOVERY PASSWORD',$Label,'')
    $groups=$Data -split '-'
    for($i=0;$i -lt $groups.Count;$i+=2){$lines+=($groups[$i]+'-'+$groups[$i+1])}
    $lines+=@('','Keep separately from the protected device.')
    $bitmap=$graphics=$font=$stream=$null;$created=$false;$complete=$false
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $bitmap=[Drawing.Bitmap]::new(800,($lines.Count*25+40))
        $graphics=[Drawing.Graphics]::FromImage($bitmap);$graphics.Clear([Drawing.Color]::White)
        $font=[Drawing.Font]::new('Consolas',12)
        $y=15;foreach($line in $lines){$graphics.DrawString($line,$font,[Drawing.Brushes]::Black,15,$y);$y+=25}
        $stream=[IO.File]::Open($OutputPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$created=$true
        $bitmap.Save($stream,[Drawing.Imaging.ImageFormat]::Png);$stream.Flush($true);$complete=$true
    } catch {Write-Warning 'Image could not be generated; attempting a new printable text file in the same folder.'}
    finally {foreach($resource in @($stream,$font,$graphics,$bitmap)){if($null -ne $resource){$resource.Dispose()}}}
    if($complete){return $OutputPath}
    if($created){Remove-Item -LiteralPath $OutputPath -ErrorAction Stop}
    return Write-AtlasRecoveryText -Path ([IO.Path]::ChangeExtension($OutputPath,'.txt')) -Content ($lines -join "`r`n")
}

# ==================== BACKUP A AD / AZURE ====================

function Backup-KeyToAD {
    param([string]$MountPoint)

    $vol = Get-BitLockerVolume -MountPoint $MountPoint -ErrorAction Stop
    if (-not $vol) { return $false }

    $recoveryKeys = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
    if (-not $recoveryKeys) {
        Write-Host "    No recovery keys to back up." -ForegroundColor Yellow
        return $false
    }

    $allAccepted = $true

    foreach ($key in $recoveryKeys) {
        $keyId = $key.KeyProtectorId

        $accepted=$false
        # La aceptación de una solicitud no comprueba recuperación ni escrow remoto.
        Write-Host "    Trying backup to Active Directory..." -ForegroundColor DarkGray
        try {
            Backup-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $keyId -ErrorAction Stop | Out-Null
            Write-Host "    AD backup request accepted; confirm remote recovery separately." -ForegroundColor Yellow
            Write-Log "AD backup request accepted: ${MountPoint}; remote recovery not verified."
            $accepted = $true
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
            $joinProbe=Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32\dsregcmd.exe') -ArgumentList @('/status') -TimeoutSeconds 10
            if($joinProbe.State -ne 'Correct' -or $joinProbe.StdoutTruncated){throw 'Entra join status was not evaluated.'}
            $isAzureJoined = ([string]$joinProbe.Stdout -match 'AzureAdJoined\s*:\s*YES')

            if ($isAzureJoined) {
                BackupToAAD-BitLockerKeyProtector -MountPoint $MountPoint -KeyProtectorId $keyId -ErrorAction Stop | Out-Null
                Write-Host "    Entra backup request accepted; confirm remote recovery separately." -ForegroundColor Yellow
                Write-Log "Entra backup request accepted: ${MountPoint}; remote recovery not verified."
                $accepted = $true
            } else {
                Write-Host "    [--] Computer is not joined to Azure AD." -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "    [--] Azure AD not available." -ForegroundColor DarkGray
        }
        if(-not $accepted){$allAccepted=$false}
    }
    return $allAccepted
}

# ==================== MODO CLI ====================

if ($Action -ne "") {
    switch ($Action) {
        "Extract" {
            if([string]::IsNullOrWhiteSpace($Output)){throw 'Extract requires an explicit -Output .txt path on another physical disk.'}
            $records=@(Get-AtlasRecoveryRecords -MountPoint $MountPoint)
            $saved=Export-AtlasRecoveryKeys -Records $records -OutputPath $Output
            Write-Host "Verified recovery file: $saved; password values hidden by default."
            if($Reveal){foreach($record in $records){Write-Host "$($record.MountPoint) -> $($record.RecoveryPassword)"}}
            Write-Log "CLI recovery export verified: $($records.Count) password(s); values omitted."
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
    Escribir-Centrado "[ 3 ] Descifrar unidad (no suspende protectores) / Decrypt drive" "White"
    Escribir-Centrado "[ 4 ] Ver Estado Completo" "White"
    Escribir-Centrado "[ 5 ] Ver Historial de Operaciones" "White"
    Escribir-Centrado "[ S ] Salir" "DarkGray"
    Write-Host ""
    Escribir-Centrado "===================================================" "DarkGray"
    Write-Host ""

    $Option = Read-Host "  Option"

    switch ($Option.ToUpper()) {
        # =============================================
        # 1. EXTRAER CLAVES (destino explicito; revelado/copia opcionales)
        # =============================================
        "1" {
            try {Invoke-AtlasRecoveryExportMenu}
            catch {Write-Warning 'Recovery export was not completed. Check the chosen destination, permissions and readable protectors; do not rely on unverified files.';Write-Log 'Recovery export interrupted; values omitted.' -Level ERROR}
            Wait-AtlasReturnCompat -Message 'ENTER to go back...'
        }
        "2" {
            Clear-Host
            Write-Host "`n"
            Escribir-Centrado "=== ACTIVAR BITLOCKER ===" "DarkYellow"
            Write-Host ""

            Write-Host ""
            $allVolumes = Show-DiskTable
            if (-not $allVolumes) { Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue }

            Write-Host "    Disk to encrypt (or [B] to go back):" -ForegroundColor White
            $driveInput = Read-Host "    >"
            if ($driveInput -ieq "B") { continue }

            $validated = Validate-DriveLetter -DriveInput $driveInput -ValidVolumes $allVolumes
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
                Escribir-Centrado "CORRIGE LOS PROBLEMAS ANTES DE CIFRAR / FIX ISSUES BEFORE ENCRYPTING." "Red"
                Write-Log "Encryption blocked by HealthCheck: ${disk}"
                Wait-AtlasReturnCompat -Message '    ENTER to go back...'
                continue
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
                Write-Host '    Guarda la recuperacion en OTRO disco y retiralo despues / Use a SEPARATE backup disk.' -ForegroundColor Yellow
                $recoveryDir = Read-Host '    Carpeta existente de respaldo (vacio cancela) / Existing backup folder'
                if ([string]::IsNullOrWhiteSpace($recoveryDir)) { continue }
                $secPwd = $null
                $actualVolume = Get-BitLockerVolume -MountPoint $disk -ErrorAction Stop
                if ($actualVolume.VolumeType.ToString() -ne 'OperatingSystem') {
                    $secPwd = Read-Host '    Clave de desbloqueo del volumen de datos / Data unlock password' -AsSecureString
                }
                $enabled = Enable-AtlasBitLockerSafely -MountPoint $disk -RecoveryDirectory $recoveryDir -Password $secPwd
                Write-Host ""
                Escribir-Centrado "Solicitud BitLocker verificada / Request verified: ${disk}" "Green"
                Write-Host ("    Status: {0}; Protection: {1}" -f $enabled.VolumeStatus,$enabled.ProtectionStatus)
                Write-Host ("    Recovery backup verified: {0}" -f $enabled.RecoveryBackup) -ForegroundColor Cyan
                if ($enabled.RebootMayBeRequired) { Write-Host '    Windows puede requerir reinicio y prueba de hardware / Restart and hardware check may be required.' -ForegroundColor Yellow }
                Write-Log "BitLocker request verified: ${disk}; Status=$($enabled.VolumeStatus)"

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
            Escribir-Centrado "=== DESCIFRAR BITLOCKER / DECRYPT DRIVE ===" "DarkYellow"
            Write-Host ""

            $encVolumes = Show-DiskTable -OnlyEncrypted
            if (-not $encVolumes) { Wait-AtlasReturnCompat -Message "    ENTER to go back..."; continue }

            Write-Host "    Disk a desencriptar (o [B]):" -ForegroundColor White
            $driveInput = Read-Host "    >"
            if ($driveInput -ieq "B") { continue }

            $validated = Validate-DriveLetter -DriveInput $driveInput -ValidVolumes $encVolumes
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
            Write-Host '    Para suspender temporalmente, usa la administracion BitLocker de Windows.' -ForegroundColor Yellow
            Write-Host '    Escribe DESCIFRAR / Type DECRYPT to remove encryption. Any other answer cancels.' -ForegroundColor White
            $confirm = Read-Host "    >"
            if ($confirm -notin @('DESCIFRAR','DECRYPT')) { continue }

            try {
                Disable-BitLocker -MountPoint $disk -ErrorAction Stop | Out-Null
                $after = Get-BitLockerVolume -MountPoint $disk -ErrorAction Stop
                if ($after.VolumeStatus.ToString() -notin @('DecryptionInProgress','FullyDecrypted')) {
                    throw 'Windows did not confirm decryption in progress or completed.'
                }
                Escribir-Centrado "Decryption iniciada en ${disk}." "Green"
                Write-Log "BitLocker decryption requested: ${disk}; Status=$($after.VolumeStatus)"

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
