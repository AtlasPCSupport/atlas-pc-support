#Requires -Version 5.1
<#
.SYNOPSIS
    Promotes a tested, clean Git commit to the existing Worker, with immutable publication pins.
    -DryRun checks the local bundle and compiles the Worker without publishing.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$Commit, [switch]$DryRun)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'src/lib/Release.ps1')
$digest = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'release-manifest.json') -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
Test-AtlasRelease -Directory $repoRoot -ExpectedManifestSha256 $digest | Out-Null
$npx = if ($env:OS -eq 'Windows_NT') { 'npx.cmd' } else { 'npx' }
Push-Location $repoRoot
try {
    $head = (& git rev-parse HEAD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $head -cne $Commit) { throw 'Publication must use the checked-out full commit.' }
    if (-not $DryRun) {
        $dirty = & git status --porcelain
        if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'Commit all release files before publishing.' }
        $runs = & gh run list --commit $Commit --workflow build.yml --limit 1 --json databaseId,headSha,status,conclusion
        if ($LASTEXITCODE -ne 0) { throw 'Cannot verify GitHub checks.' }
        $run = @($runs | ConvertFrom-Json)[0]
        if (-not $run -or $run.headSha -cne $Commit -or $run.status -ne 'completed' -or $run.conclusion -ne 'success') { throw 'The latest CI run for this commit must pass before promotion.' }
        $details = & gh run view $run.databaseId --json headSha,jobs
        if ($LASTEXITCODE -ne 0) { throw 'Cannot verify CI jobs.' }
        $details = $details | ConvertFrom-Json
        foreach ($name in @('build','windows-compat','worker')) {
            $job = @($details.jobs | Where-Object name -eq $name)
            if ($details.headSha -cne $Commit -or $job.Count -ne 1 -or $job[0].conclusion -ne 'success') { throw "Missing successful CI job on this commit: $name" }
        }
        $temporary = Join-Path ([IO.Path]::GetTempPath()) ('atlas-publication-' + [guid]::NewGuid().ToString('N') + '.json')
        try {
            Save-AtlasReleaseFile -Commit $Commit -RelativePath 'release-manifest.json' -Destination $temporary
            if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant() -cne $digest) { throw 'Remote commit manifest differs from the tested local bundle.' }
        } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force } }
    }
    $arguments = @('wrangler','deploy','--keep-vars','--var',"ATLAS_RELEASE_COMMIT:$Commit",'--var',"ATLAS_RELEASE_MANIFEST_SHA256:$digest")
    if ($DryRun) { $arguments += @('--dry-run','--outdir','.wrangler/dry-run') }
    else {
        try { $previous = Get-AtlasPublishedRelease } catch { $previous = $null }
        if ($previous -and $previous.commit -cne $Commit) {
            $arguments += @('--var',"ATLAS_PREVIOUS_RELEASE_COMMIT:$($previous.commit)",'--var',"ATLAS_PREVIOUS_RELEASE_MANIFEST_SHA256:$($previous.manifestSha256)")
        }
    }
    Set-Location $PSScriptRoot
    & $npx @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Worker publication failed. Do not update the public branch until publication has been verified.' }
} finally { Pop-Location }
