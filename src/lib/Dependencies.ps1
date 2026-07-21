# ============================================================
# Atlas PC Support - Dependency manager
# Resuelve y descarga dependencias externas (FastCopy, etc.)
# a %LOCALAPPDATA%\AtlasPC\bin\ bajo demanda.
# ============================================================

$script:AtlasDepsRegistry = @{
    'FastCopy' = @{
        DisplayName    = 'FastCopy'
        ExecutableName = 'FastCopy.exe'
        WingetId       = 'FastCopy.FastCopy'
        DownloadUrl    = 'https://fastcopy.jp/archive/FastCopy5.11.2_installer.exe'
        DownloadSha256 = '70b273dd08c15d40fac59a217b93be195bacfa47acabd031463a6df800d29fea'
        SearchPaths    = @(
            'C:\Program Files\FastCopy\FastCopy.exe',
            'C:\Program Files (x86)\FastCopy\FastCopy.exe',
            '%LOCALAPPDATA%\FastCopy\FastCopy.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\FastCopy\FastCopy.exe'
        )
    }
    'winget' = @{
        DisplayName    = 'Windows Package Manager'
        ExecutableName = 'winget.exe'
        SearchPaths    = @(
            '%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe'
        )
    }
    'GPUZ' = @{
        DisplayName    = 'TechPowerUp GPU-Z'
        ExecutableName = 'GPU-Z.exe'
        WingetId       = 'TechPowerUp.GPU-Z'
        SearchPaths    = @(
            'C:\Program Files (x86)\GPU-Z\GPU-Z.exe',
            'C:\Program Files\GPU-Z\GPU-Z.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\GPU-Z.exe'
        )
    }
    'FurMark2' = @{
        DisplayName    = 'Geeks3D FurMark 2'
        ExecutableName = 'furmark.exe'
        WingetId       = 'Geeks3D.FurMark.2'
        SearchPaths    = @(
            'C:\Program Files\Geeks3D\FurMark2_x64\furmark.exe',
            'C:\Program Files (x86)\Geeks3D\FurMark2_x64\furmark.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\FurMark2_x64\furmark.exe'
        )
    }
    'HWiNFO' = @{
        DisplayName    = 'HWiNFO64'
        ExecutableName = 'HWiNFO64.exe'
        WingetId       = 'REALiX.HWiNFO'
        SearchPaths    = @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\HWiNFO64.exe'
        )
    }
    'CPUZ' = @{
        DisplayName    = 'CPUID CPU-Z'
        ExecutableName = 'cpuz.exe'
        WingetId       = 'CPUID.CPU-Z'
        SearchPaths    = @(
            'C:\Program Files\CPUID\CPU-Z\cpuz_x64.exe',
            'C:\Program Files\CPUID\CPU-Z\cpuz_x32.exe',
            'C:\Program Files\CPUID\CPU-Z\cpuz.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x64.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x32.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\cpuz.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\cpuz_x64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\cpuz_x32.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\cpuz.exe'
        )
    }
    'BlueScreenView' = @{
        DisplayName    = 'NirSoft BlueScreenView'
        ExecutableName = 'BlueScreenView.exe'
        WingetId       = 'NirSoft.BlueScreenView'
        SearchPaths    = @(
            'C:\Program Files\NirSoft\BlueScreenView\BlueScreenView.exe',
            'C:\Program Files (x86)\NirSoft\BlueScreenView\BlueScreenView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\bluescreenview.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\BlueScreenView.exe'
        )
    }
    'BatteryInfoView' = @{
        DisplayName    = 'NirSoft BatteryInfoView'
        ExecutableName = 'BatteryInfoView.exe'
        WingetId       = 'NirSoft.BatteryInfoView'
        SearchPaths    = @(
            'C:\Program Files\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            'C:\Program Files (x86)\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\batteryinfoview.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\BatteryInfoView.exe'
        )
    }
    'CrystalDiskInfo' = @{
        DisplayName    = 'CrystalDiskInfo'
        ExecutableName = 'DiskInfo64.exe'
        WingetId       = 'CrystalDewWorld.CrystalDiskInfo'
        SearchPaths    = @(
            'C:\Program Files\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files\CrystalDiskInfo\DiskInfo32.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo32.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskinfo.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\CrystalDiskInfo\DiskInfo64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\CrystalDiskInfo\DiskInfo32.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\DiskInfo64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\DiskInfo32.exe'
        )
    }
    'CrystalDiskMark' = @{
        DisplayName    = 'CrystalDiskMark'
        ExecutableName = 'DiskMark64.exe'
        WingetId       = 'CrystalDewWorld.CrystalDiskMark'
        SearchPaths    = @(
            'C:\Program Files\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark\DiskMark64.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskmark.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\CrystalDiskMark\DiskMark64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\DiskMark64.exe'
        )
    }
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
                if ($dep.DownloadSha256) {
                    if (-not (Test-AtlasDependencyHash -Path $installerFile -ExpectedSha256 $dep.DownloadSha256)) {
                        throw "Hash SHA-256 invalido para el instalador de $Name."
                    }
                }
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
