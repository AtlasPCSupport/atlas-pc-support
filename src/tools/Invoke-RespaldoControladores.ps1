# ============================================================
# Invoke-RespaldoControladores
# Atlas PC Support
# Native Windows Driver Backup via DISM / Export-WindowsDriver.
# ============================================================

function Invoke-RespaldoControladores {
    [CmdletBinding()]
    param(
        [string]$DestinationPath
    )

    $toolTitle = 'Driver Backup (Native DISM)'

    function _Write-Title {
        if (Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue) {
            Write-Host ''
            Write-AtlasHeader -Title $toolTitle -Color Yellow
            Write-Host ''
            return
        }
        Write-Host ''
        Write-Host '============================================' -ForegroundColor Cyan
        Write-Host "  $toolTitle" -ForegroundColor Yellow
        Write-Host '============================================' -ForegroundColor Cyan
        Write-Host ''
    }

    _Write-Title

    # Ensure running as Administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host '[!] Administrator privileges are required to export system drivers.' -ForegroundColor Red
        Write-Host '    Please restart the panel as Administrator.' -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $defaultFolder = Join-Path $desktopPath "DriverBackup_$timestamp"
        
        Write-Host "Default backup location: $defaultFolder" -ForegroundColor Cyan
        $userPath = Read-Host "Press ENTER to use default, or enter custom destination directory"
        if ([string]::IsNullOrWhiteSpace($userPath)) {
            $DestinationPath = $defaultFolder
        } else {
            $DestinationPath = $userPath.Trim().Trim('"').Trim("'")
        }
    }

    try {
        if (-not (Test-Path -LiteralPath $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        }
    } catch {
        Write-Host "[X] Could not create destination directory '$DestinationPath': $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    Write-Host "[*] Exporting third-party drivers to: $DestinationPath" -ForegroundColor Cyan
    Write-Host '    Please wait, this operation may take a few minutes...' -ForegroundColor Gray

    $exportSuccess = $false
    $exportedCount = 0

    # Primary method: Export-WindowsDriver cmdlet
    if (Get-Command Export-WindowsDriver -ErrorAction SilentlyContinue) {
        try {
            $drivers = Export-WindowsDriver -Online -Destination $DestinationPath -ErrorAction Stop
            $exportedCount = $drivers.Count
            $exportSuccess = $true
            Write-Host "[+] Successfully exported $exportedCount driver package(s) via Export-WindowsDriver." -ForegroundColor Green
        } catch {
            Write-Host "[!] Export-WindowsDriver failed: $($_.Exception.Message). Falling back to DISM.exe..." -ForegroundColor Yellow
        }
    }

    # Fallback method: DISM.exe CLI
    if (-not $exportSuccess) {
        try {
            $dismArgs = @('/Online', '/Export-Driver', "/Destination:$DestinationPath")
            $proc = Start-Process -FilePath 'dism.exe' -ArgumentList $dismArgs -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                $exportSuccess = $true
                $infFiles = Get-ChildItem -Path $DestinationPath -Filter '*.inf' -Recurse -ErrorAction SilentlyContinue
                $exportedCount = $infFiles.Count
                Write-Host "[+] DISM.exe completed successfully. Found $exportedCount driver INF file(s)." -ForegroundColor Green
            } else {
                Write-Host "[X] DISM.exe failed with exit code $($proc.ExitCode)." -ForegroundColor Red
            }
        } catch {
            Write-Host "[X] Failed to launch DISM.exe: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($exportSuccess) {
        # Generate manifest inventory
        try {
            $manifestPath = Join-Path $DestinationPath 'driver-backup-manifest.json'
            $infList = Get-ChildItem -Path $DestinationPath -Filter '*.inf' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                [ordered]@{
                    Name = $_.Name
                    RelativePath = $_.FullName.Substring($DestinationPath.Length).TrimStart('\', '/')
                    Size = $_.Length
                    LastWriteTime = $_.LastWriteTime.ToString('o')
                }
            }

            $manifest = [ordered]@{
                BackupDate = (Get-Date).ToString('o')
                MachineName = $env:COMPUTERNAME
                OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
                TotalDrivers = $exportedCount
                Drivers = $infList
            }

            $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
            [System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 5), $utf8NoBom)
            Write-Host "[+] Backup manifest saved to: $manifestPath" -ForegroundColor Cyan
        } catch {
            Write-Host "[!] Manifest creation warning: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "Driver backup completed successfully at: $DestinationPath" -ForegroundColor Green
    }
}
