# This entry is embedded in get.ps1 by build.ps1. Do not download and execute libraries separately.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$publishedCommit = '__ATLAS_RELEASE_COMMIT__'
$publishedManifest = '__ATLAS_RELEASE_MANIFEST_SHA256__'

if ($OfflineRoot) {
    $root = [IO.Path]::GetFullPath($OfflineRoot)
    $release = if ($Rollback) { Restore-AtlasPreviousRelease -Root $root } else { Get-AtlasInstalledRelease -Root $root }
} else {
    $root = if ($InstallRoot) { [IO.Path]::GetFullPath($InstallRoot) } else { Join-Path $env:LOCALAPPDATA 'AtlasPC' }
    if ($Rollback) { $release = Restore-AtlasPreviousRelease -Root $root }
    else {
        $descriptor = if ($publishedCommit -cmatch '^[a-f0-9]{40}$') {
            [pscustomobject]@{ schemaVersion = 1; commit = $publishedCommit; manifestSha256 = $publishedManifest }
        } else { Get-AtlasPublishedRelease }
        Write-Host '  [>] Downloading and verifying the complete Atlas release...' -ForegroundColor Cyan
        $release = Install-AtlasRelease -Root $root -Descriptor $descriptor
    }
}
Write-Host ("  [OK] Atlas {0}, commit {1}; {2} tools verified." -f $release.Manifest.version, $release.Commit.Substring(0,12), @($release.Manifest.files.PSObject.Properties | Where-Object Name -like 'src/tools/*').Count) -ForegroundColor Green
if ($NoLaunch) { return $release }

$offlineAssets = if ($OfflineRoot) { $root } else { '' }
Start-AtlasRelease -Release $release -OfflineAssetsRoot $offlineAssets
