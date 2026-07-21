# ============================================================
# Atlas PC Support - get.ps1
# Downloads the launcher to a temp file and runs it with -File.
# Save locally and run:  pwsh -ExecutionPolicy Bypass -File get.ps1
# ============================================================

$ErrorActionPreference = 'Stop'

$launcherUrl  = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/launcher.ps1'
$launcherShaUrl = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/launcher.ps1.sha256'
$launcherOutOfBandShaUrl = 'https://toolspanel.atlaspcsupport.com/launcher.sha256'
$requireLauncherOutOfBandSha = $true
$codeloadZipUrl = 'https://codeload.github.com/mikepchelper-spec/atlas-pc-support/zip/refs/heads/main'
$launcherApiUrl = 'https://api.github.com/repos/mikepchelper-spec/atlas-pc-support/contents/launcher.ps1?ref=main'
$launcherShaApiUrl = 'https://api.github.com/repos/mikepchelper-spec/atlas-pc-support/contents/launcher.ps1.sha256?ref=main'
$githubApiHeaders = @{
    'User-Agent' = 'AtlasPCSupport-Bootstrap'
    'Accept'     = 'application/vnd.github+json'
}
$script:CodeloadExtractRoot = $null

function Get-CodeloadFilePath {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    if (-not $script:CodeloadExtractRoot) {
        $zipPath = Join-Path $env:TEMP ('atlaspc-main-' + [guid]::NewGuid().ToString('N') + '.zip')
        $extractRoot = Join-Path $env:TEMP ('atlaspc-main-' + [guid]::NewGuid().ToString('N'))
        Invoke-WebRequest -Uri ($codeloadZipUrl + '?v=' + [guid]::NewGuid().ToString('N')) `
            -OutFile $zipPath -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force -ErrorAction Stop
        Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
        $script:CodeloadExtractRoot = Join-Path $extractRoot 'atlas-pc-support-main'
    }

    return (Join-Path $script:CodeloadExtractRoot $RelativePath)
}

function Save-RemoteFileWithFallback {
    param(
        [Parameter(Mandatory = $true)][string]$RawUrl,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ApiUrl,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][hashtable]$Headers
    )

    try {
        Invoke-WebRequest -Uri $RawUrl -OutFile $OutFile -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
        return
    } catch {
        Write-Warning "Direct download via raw.githubusercontent.com failed. Retrying via codeload.github.com..."
    }

    try {
        $codeloadPath = Get-CodeloadFilePath -RelativePath $RelativePath
        if (-not (Test-Path -LiteralPath $codeloadPath)) {
            throw "File not found in codeload snapshot: $RelativePath"
        }
        Copy-Item -LiteralPath $codeloadPath -Destination $OutFile -Force -ErrorAction Stop
        return
    } catch {
        Write-Warning "Download via codeload.github.com failed. Retrying via GitHub API..."
    }

    $apiResponse = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    if (-not $apiResponse.content) {
        throw "GitHub API fallback did not return file content."
    }
    $decodedBytes = [Convert]::FromBase64String(($apiResponse.content -replace '\s', ''))
    [System.IO.File]::WriteAllBytes($OutFile, $decodedBytes)
}

function Get-RemoteTextWithFallback {
    param(
        [Parameter(Mandatory = $true)][string]$RawUrl,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ApiUrl,
        [Parameter(Mandatory = $true)][hashtable]$Headers
    )

    try {
        return (Invoke-WebRequest -Uri $RawUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop).Content
    } catch {
        Write-Warning "Checksum download via raw.githubusercontent.com failed. Retrying via codeload.github.com..."
    }

    try {
        $codeloadPath = Get-CodeloadFilePath -RelativePath $RelativePath
        if (-not (Test-Path -LiteralPath $codeloadPath)) {
            throw "File not found in codeload snapshot: $RelativePath"
        }
        return [System.IO.File]::ReadAllText($codeloadPath, [System.Text.Encoding]::UTF8)
    } catch {
        Write-Warning "Checksum via codeload.github.com failed. Retrying via GitHub API..."
    }

    $apiResponse = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    if (-not $apiResponse.content) {
        throw "GitHub API fallback did not return checksum content."
    }
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($apiResponse.content -replace '\s', '')))
}

function Get-Sha256FromText {
    param([string]$Text)
    if (-not $Text) { return $null }
    $sha = (($Text -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
    if ($sha -and $sha -match '^[a-f0-9]{64}$') { return $sha }
    return $null
}

function Get-DirectRemoteText {
    param([Parameter(Mandatory = $true)][string]$Url)
    return (Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop).Content
}

# Keep launcher at a stable path so ToolRunner can read its AST at runtime.
$atlasDir     = Join-Path $env:LOCALAPPDATA 'AtlasPC'
if (-not (Test-Path $atlasDir)) { New-Item -ItemType Directory -Path $atlasDir -Force | Out-Null }
$launcherPath = Join-Path $atlasDir 'launcher.ps1'
$launcherTempPath = "$launcherPath.download"
if (Test-Path -LiteralPath $launcherTempPath) {
    Remove-Item -LiteralPath $launcherTempPath -Force -ErrorAction SilentlyContinue
}

Write-Host '  [>] Downloading Atlas PC Support...' -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'
Save-RemoteFileWithFallback `
    -RawUrl ($launcherUrl + '?v=' + [guid]::NewGuid().ToString('N')) `
    -RelativePath 'launcher.ps1' `
    -ApiUrl $launcherApiUrl `
    -OutFile $launcherTempPath `
    -Headers $githubApiHeaders

Write-Host '  [>] Verifying launcher integrity (SHA-256)...' -ForegroundColor Cyan
$shaRaw = Get-RemoteTextWithFallback `
    -RawUrl ($launcherShaUrl + '?v=' + [guid]::NewGuid().ToString('N')) `
    -RelativePath 'launcher.ps1.sha256' `
    -ApiUrl $launcherShaApiUrl `
    -Headers $githubApiHeaders
$expectedHash = Get-Sha256FromText -Text $shaRaw
if (-not $expectedHash -or $expectedHash -notmatch '^[a-f0-9]{64}$') {
    throw "Invalid checksum metadata from server."
}

try {
    $oobRaw = Get-DirectRemoteText -Url ($launcherOutOfBandShaUrl + '?v=' + [guid]::NewGuid().ToString('N'))
    $oobHash = Get-Sha256FromText -Text $oobRaw
    if (-not $oobHash) {
        if ($requireLauncherOutOfBandSha) {
            throw "Out-of-band launcher checksum is invalid or unavailable."
        }
        Write-Warning "Out-of-band launcher checksum invalid/unavailable. Continuing with repo checksum."
    } elseif ($oobHash -ne $expectedHash) {
        throw "Checksum mismatch between repo and out-of-band channel. Repo=$expectedHash OOB=$oobHash"
    } else {
        Write-Host "  [OK] Out-of-band SHA-256 matched." -ForegroundColor Green
    }
} catch {
    if ($requireLauncherOutOfBandSha) { throw }
    Write-Warning "Out-of-band checksum check failed: $($_.Exception.Message)"
}

$actualHash = (Get-FileHash -LiteralPath $launcherTempPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) {
    Remove-Item -LiteralPath $launcherTempPath -Force -ErrorAction SilentlyContinue
    throw "Integrity check failed. Expected SHA256=$expectedHash, got $actualHash."
}

if ($script:CodeloadExtractRoot) {
    $cleanupRoot = Split-Path -Parent $script:CodeloadExtractRoot
    Remove-Item -LiteralPath $cleanupRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Move-Item -LiteralPath $launcherTempPath -Destination $launcherPath -Force
Unblock-File -LiteralPath $launcherPath -ErrorAction SilentlyContinue
Write-Host "  [OK] SHA-256: $actualHash" -ForegroundColor Green

# PS 5.1 reads BOM-less .ps1 files as ANSI when invoked with -File,
# which mojibakes UTF-8 accents and emojis. Prepend BOM if absent.
$bytes = [System.IO.File]::ReadAllBytes($launcherPath)
if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
    $bom = [byte[]](0xEF, 0xBB, 0xBF)
    $withBom = New-Object byte[] ($bom.Length + $bytes.Length)
    [System.Buffer]::BlockCopy($bom, 0, $withBom, 0, $bom.Length)
    [System.Buffer]::BlockCopy($bytes, 0, $withBom, $bom.Length, $bytes.Length)
    [System.IO.File]::WriteAllBytes($launcherPath, $withBom)
}

Write-Host '  [OK] Launching...' -ForegroundColor Green
& powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -Sta -File $launcherPath
