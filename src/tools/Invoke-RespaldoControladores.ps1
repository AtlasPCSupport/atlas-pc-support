# ============================================================
# Invoke-RespaldoControladores
# Atlas PC Support
# Launches an external BAT/CMD script used for driver backup.
# ============================================================

function Invoke-RespaldoControladores {
    [CmdletBinding()]
    param()

    $toolTitle = 'Driver Backup (External BAT)'
    $configDir = Join-Path $env:LOCALAPPDATA 'AtlasPC'
    $configPath = Join-Path $configDir 'external-tools.json'

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

    function _Normalize-Path {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
        $trimmed = $Value.Trim().Trim('"').Trim("'")
        if ([string]::IsNullOrWhiteSpace($trimmed)) { return $null }
        return [Environment]::ExpandEnvironmentVariables($trimmed)
    }

    function _Get-SavedPath {
        if (-not (Test-Path -LiteralPath $configPath)) { return $null }
        try {
            $raw = Get-Content -Raw -LiteralPath $configPath -Encoding UTF8 -ErrorAction Stop
            $obj = $raw | ConvertFrom-Json -ErrorAction Stop
            if ($obj.driverBackupBat) {
                return _Normalize-Path -Value ([string]$obj.driverBackupBat)
            }
        } catch {}
        return $null
    }

    function _Save-Path {
        param([Parameter(Mandatory)][string]$Path)
        try {
            if (-not (Test-Path -LiteralPath $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            }

            $payload = [ordered]@{ driverBackupBat = $Path }
            if (Test-Path -LiteralPath $configPath) {
                try {
                    $existing = Get-Content -Raw -LiteralPath $configPath -Encoding UTF8 | ConvertFrom-Json
                    foreach ($p in $existing.PSObject.Properties) {
                        if ($p.Name -ne 'driverBackupBat') {
                            $payload[$p.Name] = $p.Value
                        }
                    }
                } catch {}
            }

            $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
            [System.IO.File]::WriteAllText(
                $configPath,
                (($payload | ConvertTo-Json -Depth 6) -replace "`r`n", "`n"),
                $utf8NoBom
            )
        } catch {
            Write-Host "[WARN] Could not save external tool path: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    function _Resolve-ExistingPath {
        param([string[]]$Candidates)
        $seen = @{}
        foreach ($candidate in $Candidates) {
            $normalized = _Normalize-Path -Value $candidate
            if (-not $normalized) { continue }
            $key = $normalized.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            if (Test-Path -LiteralPath $normalized) {
                try {
                    return (Resolve-Path -LiteralPath $normalized -ErrorAction Stop).Path
                } catch {
                    return $normalized
                }
            }
        }
        return $null
    }

    _Write-Title

    $savedPath = _Get-SavedPath
    $desktopPath = $null
    $publicDesktopPath = $null
    try { $desktopPath = [Environment]::GetFolderPath('Desktop') } catch {}
    try { $publicDesktopPath = [Environment]::GetFolderPath('CommonDesktopDirectory') } catch {}
    $offlineRoot = _Normalize-Path -Value $env:ATLAS_OFFLINE_ROOT

    $candidatePaths = @(
        $env:ATLAS_DRIVER_BACKUP_BAT,
        $savedPath,
        (if ($desktopPath) { Join-Path $desktopPath 'Herramientas\Respaldo-Controladores.bat' }),
        (if ($desktopPath) { Join-Path $desktopPath 'Respaldo-Controladores.bat' }),
        (if ($publicDesktopPath) { Join-Path $publicDesktopPath 'Herramientas\Respaldo-Controladores.bat' }),
        (if ($publicDesktopPath) { Join-Path $publicDesktopPath 'Respaldo-Controladores.bat' }),
        (if ($offlineRoot) { Join-Path $offlineRoot 'Herramientas\Respaldo-Controladores.bat' }),
        (if ($offlineRoot) { Join-Path $offlineRoot 'deps\Herramientas\Respaldo-Controladores.bat' }),
        (if ($offlineRoot) { Join-Path $offlineRoot 'deps\external\Respaldo-Controladores.bat' })
    )

    $batPath = _Resolve-ExistingPath -Candidates $candidatePaths
    if (-not $batPath) {
        Write-Host 'Configured paths not found.' -ForegroundColor Yellow
        Write-Host 'Common expected locations:' -ForegroundColor DarkGray
        if ($desktopPath) {
            Write-Host ("  - " + (Join-Path $desktopPath 'Herramientas\Respaldo-Controladores.bat')) -ForegroundColor DarkGray
        }
        if ($publicDesktopPath) {
            Write-Host ("  - " + (Join-Path $publicDesktopPath 'Herramientas\Respaldo-Controladores.bat')) -ForegroundColor DarkGray
        }
        Write-Host ''
        $manualPath = Read-Host "Type the full path to your .bat/.cmd file (or press ENTER to cancel)"
        if ([string]::IsNullOrWhiteSpace($manualPath)) {
            Write-Host 'Cancelled by user.' -ForegroundColor DarkGray
            return
        }

        $manualNormalized = _Normalize-Path -Value $manualPath
        if (-not $manualNormalized -or -not (Test-Path -LiteralPath $manualNormalized)) {
            Write-Host "Path not found: $manualPath" -ForegroundColor Red
            return
        }

        $ext = [System.IO.Path]::GetExtension($manualNormalized).ToLowerInvariant()
        if ($ext -ne '.bat' -and $ext -ne '.cmd') {
            Write-Host 'Only .bat or .cmd files are allowed.' -ForegroundColor Red
            return
        }

        try {
            $batPath = (Resolve-Path -LiteralPath $manualNormalized -ErrorAction Stop).Path
        } catch {
            $batPath = $manualNormalized
        }
        _Save-Path -Path $batPath
    }

    Write-Host "Launching: $batPath" -ForegroundColor Cyan
    try { Unblock-File -LiteralPath $batPath -ErrorAction SilentlyContinue } catch {}

    try {
        $proc = Start-Process -FilePath 'cmd.exe' `
            -ArgumentList @('/c', "`"$batPath`"") `
            -WorkingDirectory (Split-Path -Parent $batPath) `
            -Wait -PassThru -ErrorAction Stop

        if ($proc.ExitCode -ne 0) {
            Write-Host "Completed with exit code $($proc.ExitCode)." -ForegroundColor Yellow
        } else {
            Write-Host 'Completed successfully.' -ForegroundColor Green
        }

        _Save-Path -Path $batPath
    } catch {
        Write-Host "Failed to launch script: $($_.Exception.Message)" -ForegroundColor Red
    }
}
