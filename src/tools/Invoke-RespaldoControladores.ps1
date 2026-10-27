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
    $isAdmin = Test-IsAdmin
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
            New-Item -ItemType Directory -Path $DestinationPath -Force -ErrorAction Stop | Out-Null
        }
        $root=[IO.Path]::GetFullPath((Get-Item -LiteralPath $DestinationPath -Force -ErrorAction Stop).FullName)
        Assert-AtlasPlainDirectory $root
        $DestinationPath=Join-Path $root ('Export-'+[datetime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $DestinationPath -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "[X] Could not create destination directory '$DestinationPath': $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    Write-Host "[*] Exporting third-party drivers to: $DestinationPath" -ForegroundColor Cyan
    Write-Host '    Please wait, this operation may take a few minutes...' -ForegroundColor Gray

    $exportSuccess = $false

    # Primary method: Export-WindowsDriver cmdlet
    if (Get-Command Export-WindowsDriver -ErrorAction SilentlyContinue) {
        try {
            Export-WindowsDriver -Online -Destination $DestinationPath -ErrorAction Stop | Out-Null
            $exportSuccess = $true
        } catch {
            Write-Host "[X] Export-WindowsDriver failed: $($_.Exception.Message). Partial attempt preserved at $DestinationPath; no automatic second export." -ForegroundColor Red
            return
        }
    }

    # Fallback method: DISM.exe CLI
    if (-not $exportSuccess) {
        try {
            $dismArgs = @('/Online', '/Export-Driver', ('/Destination:{0}' -f $DestinationPath))
            $proc = Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32/dism.exe') -ArgumentList $dismArgs -TimeoutSeconds 3600
            if ($proc.State -eq 'Correct') {
                $exportSuccess = $true
            } else {
                Write-Host "[X] DISM.exe $($proc.State), exit $($proc.ExitCode). Inspect any partial export before retrying." -ForegroundColor Red
            }
        } catch {
            Write-Host "[X] Failed to launch DISM.exe: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($exportSuccess) {
        # Generate manifest inventory
        try {
            $manifestPath = Write-AtlasDriverManifest -Directory $DestinationPath
            Write-Host "[+] Backup manifest saved to: $manifestPath" -ForegroundColor Cyan
        } catch {
            Write-Host "[X] Export inventory not verified: $($_.Exception.Message). Preserve this attempt for inspection." -ForegroundColor Red
            return
        }

        Write-Host ""
        Write-Host "Driver export and file hashes verified at: $DestinationPath. Restoration has NOT been tested." -ForegroundColor Green
    }
}
