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
    if (-not $ExpectedSha256) { return $false }

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

function Get-AtlasDependencyCandidate {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string]$Path,[string]$Origin='configured path')
    try {
        $resolved=Resolve-SymlinkPath $Path
        if(-not [IO.Path]::IsPathRooted($resolved)){$resolved=Join-Path (Split-Path -Parent $Path) $resolved}
        $item=Get-Item -LiteralPath $resolved -Force -ErrorAction Stop
        if($item.PSIsContainer -or $item.Extension -ine '.exe'){return $null}
        $resource=switch($Name){'CrystalDiskInfo'{'CdiResource'};'CrystalDiskMark'{'CdmResource'}}
        if($resource) {
            $folder=Join-Path $item.DirectoryName $resource
            if(-not (Test-Path -LiteralPath $folder -PathType Container) -or -not @(Get-ChildItem -LiteralPath $folder -Force -ErrorAction Stop | Select-Object -First 1).Count){return $null}
        }
        $version=$item.VersionInfo.FileVersion
        if(-not $version){$version='not reported'}
        Write-AtlasLog "Found $Name; origin=$Origin; path=$($item.FullName); file version=$version; installed version/support not certified." -Tool Deps
        return $item.FullName
    } catch {Write-AtlasLog "Candidate for $Name could not be read; origin=$Origin." -Level WARN -Tool Deps;return $null}
}

function Resolve-AtlasDependency {
    <#
    .SYNOPSIS
    Busca una dependencia en el sistema; si no la encuentra,
    intenta instalarla con winget o descargarla.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$')][string]$Name,
        [switch]$InstallIfMissing
    )

    if (-not $script:AtlasDepsRegistry.ContainsKey($Name)) {
        Write-AtlasLog "Dependencia desconocida: $Name" -Level ERROR -Tool 'Deps'
        return $null
    }
    $dep = $script:AtlasDepsRegistry[$Name]

    foreach ($p in $dep.SearchPaths) {
        $expanded = Expand-AtlasPath $p
        foreach($file in @(Get-ChildItem -Path $expanded -File -ErrorAction SilentlyContinue | Sort-Object FullName)) {
            $candidate=Get-AtlasDependencyCandidate -Name $Name -Path $file.FullName
            if($candidate){return $candidate}
        }
    }
    foreach($command in @(Get-Command $dep.ExecutableName -CommandType Application -ErrorAction SilentlyContinue)) {
        $candidate=Get-AtlasDependencyCandidate -Name $Name -Path $command.Source -Origin PATH
        if($candidate){return $candidate}
    }

    if (-not $InstallIfMissing) {
        Write-AtlasLog "$Name no encontrada (no se pidió instalar)." -Level WARN -Tool 'Deps'
        return $null
    }

    if ($dep.WingetId -and (Get-Command 'winget' -ErrorAction SilentlyContinue)) {
        Write-AtlasLog "Instalando $Name vía winget ($($dep.WingetId))" -Tool 'Deps'
        try {
            $result = Invoke-AtlasNativeProcess -FilePath 'winget.exe' -ArgumentList @('install','--id',$dep.WingetId,'--exact','--source','winget','--accept-source-agreements','--accept-package-agreements','--silent') -TimeoutSeconds 1800
            if ($result.State -ne 'Correct') { Write-AtlasLog "Dependency installation $($result.State), exit $($result.ExitCode); no second installer is started." -Level ERROR -Tool Deps; return $null }
        } catch {
            Write-AtlasLog "winget failed: $_; no second installer is started." -Level ERROR -Tool Deps
            return $null
        }
        return Resolve-AtlasDependency -Name $Name
    }

    # Direct download is allowed only when no package-manager attempt was made.
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
                if ($Name -ne 'FastCopy') { throw 'No direct extraction contract is defined for this dependency.' }
                $result = Invoke-AtlasNativeProcess -FilePath $installerFile -ArgumentList @('/EXTRACT64','/NOSUBDIR','/AGREE_LICENSE',("/DIR=$targetDir")) -TimeoutSeconds 180
                if ($result.State -ne 'Correct') { throw "Dependency extraction $($result.State), exit $($result.ExitCode). No alternative installer was started." }
                Remove-Item -LiteralPath $installerFile -ErrorAction Stop
                return Resolve-AtlasDependency -Name $Name
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
        [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$')][string]$Name,
        [Parameter(Mandatory)] [hashtable]$Definition
    )
    $script:AtlasDepsRegistry[$Name] = $Definition
}
