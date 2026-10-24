# ============================================================
# Atlas PC Support - Dependency manager
# Resuelve y descarga dependencias externas (FastCopy, etc.)
# a %LOCALAPPDATA%\AtlasPC\bin\ bajo demanda.
# ============================================================

$script:AtlasDepsRegistry = @{}
foreach ($entry in $script:AtlasDependencyCatalog.PSObject.Properties) {
    $script:AtlasDepsRegistry[$entry.Name] = ConvertTo-AtlasHashtable $entry.Value
}

function Resolve-SymlinkPath {
    param([string]$Path)
    if (-not $Path) { return $Path }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($item.Attributes -match "ReparsePoint") {
            if ($item.LinkTarget) { return $item.LinkTarget }
            elseif ($item.Target) {
                if ($item.Target -is [array]) { return $item.Target[0] }
                return [string]$item.Target
            }
        }
    } catch {}
    return $Path
}

function Test-AtlasDependencyHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedSha256
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if (-not $ExpectedSha256) { return $true }

    $expected = $ExpectedSha256.ToLowerInvariant()
    if ($expected -notmatch '^[a-f0-9]{64}$') {
        Write-AtlasLog "Hash esperado invalido para dependencia: $ExpectedSha256" -Level WARN -Tool 'Deps'
        return $false
    }

    try {
        $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
        return ($actual -eq $expected)
    } catch {
        Write-AtlasLog "No se pudo calcular SHA256 para '$Path': $_" -Level WARN -Tool 'Deps'
        return $false
    }
}

function Resolve-AtlasDependency {
    <#
    .SYNOPSIS
    Busca una dependencia en el sistema; si no la encuentra,
    intenta instalarla con winget o descargarla.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Name,
        [switch]$InstallIfMissing
    )

    if (-not $script:AtlasDepsRegistry.ContainsKey($Name)) {
        Write-AtlasLog "Dependencia desconocida: $Name" -Level ERROR -Tool 'Deps'
        return $null
    }
    $dep = $script:AtlasDepsRegistry[$Name]

    foreach ($p in $dep.SearchPaths) {
        $expanded = Expand-AtlasPath $p
        if (Test-Path $expanded) {
            # Ensure CrystalDiskInfo and CrystalDiskMark have their resource folders
            if ($Name -eq 'CrystalDiskInfo') {
                $parent = Split-Path -Parent $expanded
                if (-not (Test-Path -LiteralPath (Join-Path $parent 'CdiResource'))) {
                    Write-AtlasLog "Ignorando $Name en $expanded porque falta CdiResource" -Level WARN -Tool 'Deps'
                    continue
                }
            }
            if ($Name -eq 'CrystalDiskMark') {
                $parent = Split-Path -Parent $expanded
                if (-not (Test-Path -LiteralPath (Join-Path $parent 'CdmResource'))) {
                    Write-AtlasLog "Ignorando $Name en $expanded porque falta CdmResource" -Level WARN -Tool 'Deps'
                    continue
                }
            }
            Write-AtlasLog "Encontrada $Name en $expanded" -Tool 'Deps'
            return Resolve-SymlinkPath $expanded
        }
    }
    $inPath = Get-Command $dep.ExecutableName -ErrorAction SilentlyContinue
    if ($inPath) { return Resolve-SymlinkPath $inPath.Source }

    if (-not $InstallIfMissing) {
        Write-AtlasLog "$Name no encontrada (no se pidió instalar)." -Level WARN -Tool 'Deps'
        return $null
    }

    if ($dep.WingetId -and (Get-Command 'winget' -ErrorAction SilentlyContinue)) {
        Write-AtlasLog "Instalando $Name vía winget ($($dep.WingetId))" -Tool 'Deps'
        try {
            winget install --id $dep.WingetId --exact --accept-source-agreements --accept-package-agreements --silent | Out-Null
        } catch {
            Write-AtlasLog "winget falló: $_" -Level WARN -Tool 'Deps'
        }
        foreach ($p in $dep.SearchPaths) {
            $expanded = Expand-AtlasPath $p
            if (Test-Path $expanded) { return Resolve-SymlinkPath $expanded }
        }
    }

    # Fallback: direct download via DownloadUrl when winget is unavailable or failed
    if ($dep.DownloadUrl) {
        Write-AtlasLog "Intentando descarga directa de $Name ($($dep.DownloadUrl))" -Tool 'Deps'
        $cacheDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\bin'
        if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
        $installerFile = Join-Path $cacheDir ("$Name-installer-" + [guid]::NewGuid().ToString('N').Substring(0,8) + '.exe')
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $dep.DownloadUrl -OutFile $installerFile -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            if ((Get-Item $installerFile).Length -gt 100KB) {
                Assert-AtlasInstaller -Path $installerFile -ExpectedSha256 ([string]$dep.DownloadSha256)
                $targetDir = Join-Path $env:LOCALAPPDATA "AtlasPC\bin\$Name"
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                $p = Start-Process -FilePath $installerFile -ArgumentList @('/EXTRACT64', '/NOSUBDIR', '/AGREE_LICENSE', "/DIR=`"$targetDir`"") -Wait -PassThru -ErrorAction SilentlyContinue
                if (-not ($p -and $p.ExitCode -eq 0)) {
                    Start-Process -FilePath $installerFile -ArgumentList @('/SILENT', '/AGREE_LICENSE', "/DIR=`"$targetDir`"") -Wait -ErrorAction SilentlyContinue
                }
                Remove-Item $installerFile -ErrorAction SilentlyContinue
                foreach ($sp in $dep.SearchPaths) {
                    $expanded = Expand-AtlasPath $sp
                    if (Test-Path $expanded) { return Resolve-SymlinkPath $expanded }
                }
                $found = Get-ChildItem -Path $targetDir -Filter $dep.ExecutableName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) { return Resolve-SymlinkPath $found.FullName }
            }
        } catch {
            Write-AtlasLog "Descarga directa falló: $_" -Level WARN -Tool 'Deps'
            Remove-Item $installerFile -ErrorAction SilentlyContinue
        }
    }

    Write-AtlasLog "No se pudo resolver $Name. Revisa la ruta manualmente." -Level ERROR -Tool 'Deps'
    return $null
}

function Register-AtlasDependency {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [hashtable]$Definition
    )
    $script:AtlasDepsRegistry[$Name] = $Definition
}
