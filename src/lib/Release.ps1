# Atlas release transport and activation. Shared by get.ps1, launcher and USB.
# Trust starts at the HTTPS bootstrap from the existing Cloudflare domain.
# Cloudflare pins the commit AND manifest digest independently of repository reads.

function Get-AtlasTextHash {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $canonical = $Text.TrimStart([char]0xFEFF).Replace("`r`n", "`n").Replace("`r", "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical)))).Replace('-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

function Assert-AtlasReleaseDescriptor {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Descriptor)
    if ($Descriptor.schemaVersion -ne 1 -or [string]$Descriptor.commit -cnotmatch '^[a-f0-9]{40}$' -or
        [string]$Descriptor.manifestSha256 -cnotmatch '^[a-f0-9]{64}$') {
        throw 'Invalid Atlas publication descriptor. No mutable-ref fallback is permitted.'
    }
}

function Get-AtlasPublishedRelease {
    [CmdletBinding()]
    param()
    $descriptor = Invoke-RestMethod -Uri ('https://toolspanel.atlaspcsupport.com/release.json?v=' + [guid]::NewGuid().ToString('N')) -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    Assert-AtlasReleaseDescriptor $descriptor
    return $descriptor
}

function Save-AtlasReleaseFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Commit, [Parameter(Mandatory)][string]$RelativePath, [Parameter(Mandatory)][string]$Destination)
    # Every transport fallback is bound to the SAME full commit. Never fall back to main.
    $repository = 'mikepchelper-spec/atlas-pc-support'
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$repository/$Commit/$RelativePath" -OutFile $Destination -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    } catch {
        $headers = @{ 'User-Agent' = 'AtlasPCSupport-Release'; Accept = 'application/vnd.github+json' }
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/contents/${RelativePath}?ref=$Commit" -Headers $headers -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
        if ($response.encoding -ne 'base64' -or -not $response.content) { throw 'Commit-bound API download did not contain file bytes.' }
        [IO.File]::WriteAllBytes($Destination, [Convert]::FromBase64String(($response.content -replace '\s', '')))
    }
}

function Assert-AtlasPlainDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (-not $item.PSIsContainer) { throw "Not a directory: $Path" }
    while ($null -ne $item) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Release paths cannot cross reparse points: $Path" }
        $item = $item.Parent
    }
}

function Test-AtlasRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][string]$ExpectedManifestSha256)
    Assert-AtlasPlainDirectory $Directory
    if ($ExpectedManifestSha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'A trusted manifest digest is required.' }
    $manifestPath = Join-Path $Directory 'release-manifest.json'
    $manifestItem = Get-Item -LiteralPath $manifestPath -Force -ErrorAction Stop
    if ($manifestItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Manifest cannot be a link.' }
    $actual = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    if ($actual -cne $ExpectedManifestSha256) { throw 'Atlas manifest digest mismatch.' }
    $manifest = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop
    if ($manifest.schemaVersion -ne 1 -or $manifest.algorithm -ne 'SHA256-UTF8-LF' -or -not $manifest.version) { throw 'Unsupported Atlas manifest.' }
    $names = @($manifest.files.PSObject.Properties.Name)
    $required = @('get.ps1', 'launcher.ps1', 'config/tools.json', 'config/dependencies.json', 'config/tool-hashes.json', 'onboarding/install.bat')
    foreach ($name in $required) { if ($names -cnotcontains $name) { throw "Missing release member: $name" } }
    $seen = @{}
    foreach ($entry in $manifest.files.PSObject.Properties) {
        $name = $entry.Name
        if (($required -cnotcontains $name -and $name -cnotmatch '^src/tools/Invoke-[A-Za-z0-9-]+\.ps1$') -or $seen.ContainsKey($name)) {
            throw "Invalid or duplicate release path: $name"
        }
        $seen[$name] = $true
        if ([string]$entry.Value -cnotmatch '^[a-f0-9]{64}$') { throw "Invalid release hash: $name" }
        $file = Join-Path $Directory $name
        Assert-AtlasPlainDirectory (Split-Path -Parent $file)
        $item = Get-Item -LiteralPath $file -Force -ErrorAction Stop
        if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Release member is not a plain file: $name" }
        if ($item.Length -gt 10MB) { throw "Oversized release member: $name" }
        if ((Get-AtlasTextHash ([IO.File]::ReadAllText($file, [Text.Encoding]::UTF8))) -cne [string]$entry.Value) { throw "Release member digest mismatch: $name" }
    }
    $tools = @(([IO.File]::ReadAllText((Join-Path $Directory 'config/tools.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop).tools)
    $toolNames = @{}
    foreach ($tool in $tools) {
        $name = [string]$tool.source
        if ($name -cnotmatch '^Invoke-[A-Za-z0-9-]+\.ps1$' -or $toolNames.ContainsKey($name) -or $names -cnotcontains "src/tools/$name") { throw "Missing or duplicated tool: $name" }
        if ($tool.function -cne [IO.Path]::GetFileNameWithoutExtension($name) -or
            $tool.runtime.engine -notin @('windows-powershell','pwsh') -or $tool.runtime.architecture -ne 'x64' -or
            [string]$tool.runtime.minimumVersion -notmatch '^\d+\.\d+(?:\.\d+){0,2}$' -or @($tool.runtime.libraries).Count -eq 0) { throw "Missing tool execution contract: $name" }
        foreach ($library in @($tool.runtime.libraries)) { if ($library -notin @('ToolKit','Dependencies','PS7','Release')) { throw "Unknown tool library: $library" } }
        $toolNames[$name] = $true
    }
    if ($tools.Count -eq 0 -or $names.Count -ne ($required.Count + $tools.Count)) { throw 'Release members and tool manifest do not match.' }
    return $manifest
}

function Get-AtlasInstalledRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root, [switch]$Previous)
    $pointerFile = if ($Previous) { 'previous.json' } else { 'current.json' }
    Assert-AtlasPlainDirectory $Root
    $pointerPath = Join-Path $Root $pointerFile
    if ((Get-Item -LiteralPath $pointerPath -Force -ErrorAction Stop).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Release pointer cannot be a link.' }
    $pointer = [IO.File]::ReadAllText($pointerPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop
    Assert-AtlasReleaseDescriptor $pointer
    if ([string]$pointer.directory -cnotmatch '^[a-f0-9]{40}(?:-[a-f0-9]{32})?$') { throw 'Invalid installed release directory.' }
    if (-not ([string]$pointer.directory).StartsWith([string]$pointer.commit, [StringComparison]::Ordinal)) { throw 'Release directory and commit differ.' }
    $directory = Join-Path (Join-Path $Root 'releases') $pointer.directory
    $manifest = Test-AtlasRelease -Directory $directory -ExpectedManifestSha256 $pointer.manifestSha256
    return [pscustomobject]@{ Directory = $directory; Commit = $pointer.commit; ManifestSha256 = $pointer.manifestSha256; Manifest = $manifest }
}

function Set-AtlasReleasePointer {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)]$Release)
    $pointer = [ordered]@{ schemaVersion = 1; commit = $Release.Commit; manifestSha256 = $Release.ManifestSha256; directory = Split-Path -Leaf $Release.Directory }
    $current = Join-Path $Root 'current.json'
    $temporary = Join-Path $Root ('pointer-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($pointer | ConvertTo-Json -Compress))
        $stream = [IO.FileStream]::new($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if (Test-Path -LiteralPath $current) {
            # Same-volume atomic replacement. If unsupported, leave the current release alone.
            [IO.File]::Replace($temporary, $current, (Join-Path $Root 'previous.json'), $true)
        } else { [IO.File]::Move($temporary, $current) }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction Stop }
    }
}

function Install-AtlasRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)]$Descriptor, [string]$SourceDirectory, [switch]$PrepareOfflineEntry)
    Assert-AtlasReleaseDescriptor $Descriptor
    if (-not (Test-Path -LiteralPath $Root)) { New-Item -ItemType Directory -Path $Root -ErrorAction Stop | Out-Null }
    Assert-AtlasPlainDirectory $Root
    $releases = Join-Path $Root 'releases'
    if (-not (Test-Path -LiteralPath $releases)) { New-Item -ItemType Directory -Path $releases -ErrorAction Stop | Out-Null }
    Assert-AtlasPlainDirectory $releases
    $lock = [IO.FileStream]::new((Join-Path $Root '.update.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $stage = Join-Path $releases ('.staging-' + [guid]::NewGuid().ToString('N'))
    try {
        try {
            $current = Get-AtlasInstalledRelease -Root $Root
            if ($current.Commit -ceq $Descriptor.commit -and $current.ManifestSha256 -ceq $Descriptor.manifestSha256) {
                if ($PrepareOfflineEntry) { Initialize-AtlasOfflineEntry -Root $Root -Release $current }
                return $current
            }
        } catch { Write-Verbose "No matching verified current release: $_" }
        New-Item -ItemType Directory -Path $stage -ErrorAction Stop | Out-Null
        $manifestPath = Join-Path $stage 'release-manifest.json'
        if ($SourceDirectory) {
            Test-AtlasRelease -Directory $SourceDirectory -ExpectedManifestSha256 $Descriptor.manifestSha256 | Out-Null
            Copy-Item -LiteralPath (Join-Path $SourceDirectory 'release-manifest.json') -Destination $manifestPath -ErrorAction Stop
        } else {
            Save-AtlasReleaseFile -Commit $Descriptor.commit -RelativePath 'release-manifest.json' -Destination $manifestPath
        }
        if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() -cne $Descriptor.manifestSha256) { throw 'Downloaded manifest is not the approved publication.' }
        $manifest = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop
        if ($manifest.schemaVersion -ne 1 -or $manifest.algorithm -ne 'SHA256-UTF8-LF') { throw 'Unsupported release manifest.' }
        foreach ($entry in $manifest.files.PSObject.Properties) {
            $name = $entry.Name
            if ($name -cnotmatch '^(get\.ps1|launcher\.ps1|onboarding/install\.bat|config/(tools|dependencies|tool-hashes)\.json|src/tools/Invoke-[A-Za-z0-9-]+\.ps1)$') { throw "Unsafe release path: $name" }
            $destination = Join-Path $stage $name
            $parent = Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
            if ($SourceDirectory) { Copy-Item -LiteralPath (Join-Path $SourceDirectory $name) -Destination $destination -ErrorAction Stop }
            else { Save-AtlasReleaseFile -Commit $Descriptor.commit -RelativePath $name -Destination $destination }
        }
        $verified = Test-AtlasRelease -Directory $stage -ExpectedManifestSha256 $Descriptor.manifestSha256
        $name = [string]$Descriptor.commit
        $destination = Join-Path $releases $name
        if (Test-Path -LiteralPath $destination) { $destination = Join-Path $releases ($name + '-' + [guid]::NewGuid().ToString('N')) }
        [IO.Directory]::Move($stage, $destination)
        $release = [pscustomobject]@{ Directory = $destination; Commit = $Descriptor.commit; ManifestSha256 = $Descriptor.manifestSha256; Manifest = $verified }
        if ($PrepareOfflineEntry) { Initialize-AtlasOfflineEntry -Root $Root -Release $release }
        Set-AtlasReleasePointer -Root $Root -Release $release
        return $release
    } finally {
        $lock.Dispose()
        if (Test-Path -LiteralPath $stage) {
            # This GUID child was created above, under the already checked releases directory.
            Assert-AtlasPlainDirectory $stage
            if ([IO.Path]::GetFullPath((Split-Path -Parent $stage)) -ne [IO.Path]::GetFullPath($releases) -or (Split-Path -Leaf $stage) -notmatch '^\.staging-[a-f0-9]{32}$') { throw 'Unsafe staging cleanup refused.' }
            Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop
        }
    }
}

function Restore-AtlasPreviousRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)
    Assert-AtlasPlainDirectory $Root
    $lock = [IO.FileStream]::new((Join-Path $Root '.update.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $previous = Get-AtlasInstalledRelease -Root $Root -Previous
        Set-AtlasReleasePointer -Root $Root -Release $previous
        return $previous
    } finally { $lock.Dispose() }
}

function Initialize-AtlasOfflineEntry {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)]$Release)
    Assert-AtlasPlainDirectory $Root
    Test-AtlasRelease -Directory $Release.Directory -ExpectedManifestSha256 $Release.ManifestSha256 | Out-Null
    # A generic offline entry; never refresh individual components on startup.
    $entry = Join-Path $Root 'get.ps1'
    $temporary = Join-Path $Root ('entry-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($temporary, [IO.File]::ReadAllText((Join-Path $Release.Directory 'get.ps1'), [Text.Encoding]::UTF8), [Text.UTF8Encoding]::new($true))
        if (Test-Path -LiteralPath $entry) { [IO.File]::Replace($temporary, $entry, (Join-Path $Root 'get.previous.ps1'), $true) }
        else { [IO.File]::Move($temporary, $entry) }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction Stop }
    }
    $bat = @('@echo off', 'setlocal', 'cd /d "%~dp0"', 'powershell.exe -NoProfile -Sta -ExecutionPolicy RemoteSigned -File "%~dp0get.ps1" -OfflineRoot "%~dp0."', 'set "RC=%errorlevel%"', 'if not "%RC%"=="0" pause', 'exit /b %RC%') -join "`r`n"
    [IO.File]::WriteAllText((Join-Path $Root 'run.bat'), $bat + "`r`n", [Text.Encoding]::ASCII)
}

function Start-AtlasRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Release, [string]$OfflineAssetsRoot = '')
    Assert-AtlasReleaseDescriptor ([pscustomobject]@{ schemaVersion=1; commit=$Release.Commit; manifestSha256=$Release.ManifestSha256 })
    Test-AtlasRelease -Directory $Release.Directory -ExpectedManifestSha256 $Release.ManifestSha256 | Out-Null
    $engine = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { $engine = Join-Path $env:SystemRoot 'Sysnative/WindowsPowerShell/v1.0/powershell.exe' }
    if (-not [Environment]::Is64BitOperatingSystem -or -not (Test-Path -LiteralPath $engine)) { throw 'Atlas requires Windows PowerShell 5.1 x64.' }
    $arguments = @('-NoProfile','-Sta','-ExecutionPolicy','RemoteSigned','-File', ('"{0}"' -f (Join-Path $Release.Directory 'launcher.ps1')), '-AtlasReleaseCommit',$Release.Commit,'-AtlasManifestSha256',$Release.ManifestSha256)
    # PS 5.1 drops empty native arguments. Omit an absent optional path entirely.
    if ($OfflineAssetsRoot) { $arguments += @('-AtlasOfflineRoot', ('"{0}"' -f $OfflineAssetsRoot)) }
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -NoNewWindow -Wait -PassThru -ErrorAction Stop
    if ($process.ExitCode -ne 0) { throw "Atlas launcher exited with code $($process.ExitCode)." }
}
