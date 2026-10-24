#Requires -Version 5.1
<#
.SYNOPSIS
    Runs local checks without downloading or executing the distributed panel.
.DESCRIPTION
    Requires Pester 5.8.0 and PSScriptAnalyzer 1.25.0 already installed.
    Rebuilds only an isolated copy. Reports remain in a new temporary directory.
    -IncludeKnownIssues also runs any pending acceptance tests when that file exists.
#>
[CmdletBinding()]
param([switch]$IncludeKnownIssues)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'src/bootstrap/Runtime.ps1')
$engine = (Get-Process -Id $PID).Path
if ($env:OS -eq 'Windows_NT' -and [Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw 'Run this script with -STA for the WPF smoke tests.'
}
Import-Module Pester -RequiredVersion 5.8.0 -Force -ErrorAction Stop
Import-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Force -ErrorAction Stop

$reportDir = Join-Path ([IO.Path]::GetTempPath()) ('atlas-local-checks-' + [guid]::NewGuid().ToString('N'))
$staging = Join-Path $reportDir 'repo with spaces'
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Write-Host "Local check reports: $reportDir"

function Invoke-CheckScript {
    param([string]$Path, [string[]]$ScriptArguments = @())
    $engineArguments = @('-NoLogo', '-NoProfile')
    if ($env:OS -eq 'Windows_NT') { $engineArguments += @('-ExecutionPolicy', 'RemoteSigned') }
    & $engine @engineArguments -File $Path @ScriptArguments
    if ($LASTEXITCODE -ne 0) { throw "Check failed (exit $LASTEXITCODE): $Path" }
}

# Keep the build away from the public launcher/checksums in the working tree.
foreach ($relative in @('src', 'config', 'onboarding', 'build.ps1', 'get.ps1', 'release-manifest.json', 'launcher.ps1', 'launcher.ps1.sha256')) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $staging -Recurse -Force
}
$artifacts = @('get.ps1', 'release-manifest.json', 'launcher.ps1', 'launcher.ps1.sha256', 'config/tool-hashes.json')
$before = @{}
foreach ($relative in $artifacts) {
    $before[$relative] = (Get-FileHash -LiteralPath (Join-Path $repoRoot $relative) -Algorithm SHA256).Hash
}

Invoke-CheckScript -Path (Join-Path $PSScriptRoot 'Test-SecurityGuards.ps1') -ScriptArguments @('-RepoRoot', $repoRoot)
Invoke-CheckScript -Path (Join-Path $PSScriptRoot 'Test-ToolSources.ps1')
Invoke-CheckScript -Path (Join-Path $PSScriptRoot 'Assert-LauncherFresh.ps1') -ScriptArguments @('-RepoRoot', $staging)

$findings = @(Invoke-ScriptAnalyzer -Path (Join-Path $repoRoot 'src') -Recurse -Settings (Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'))
$errors = @($findings | Where-Object Severity -eq 'Error')
$findings | Select-Object ScriptName, Line, Severity, RuleName, Message |
    ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $reportDir 'analyzer.json') -Encoding UTF8
Write-Host "PSScriptAnalyzer: $($errors.Count) errors; $(@($findings | Where-Object Severity -eq 'Warning').Count) warnings."
if ($errors.Count) { $errors | Format-Table -AutoSize | Out-Host; throw 'Script analyzer errors found.' }

$testPaths = @(
    (Join-Path $PSScriptRoot 'Lib.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Platform.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Accounts.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Installers.Tests.ps1'),
    (Join-Path $PSScriptRoot 'BitLocker.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Execution.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Release.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Compatibility.Tests.ps1'),
    (Join-Path $PSScriptRoot 'Quality.Tests.ps1')
)
$knownIssuesPath = Join-Path $PSScriptRoot 'KnownIssues.Tests.ps1'
if ($IncludeKnownIssues -and (Test-Path -LiteralPath $knownIssuesPath)) { $testPaths += $knownIssuesPath }
$config = New-PesterConfiguration
$config.Run.Path = $testPaths
$config.Run.PassThru = $true
$config.Run.Exit = $false
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path $reportDir 'pester.xml'
$config.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $config

foreach ($relative in $artifacts) {
    if ($before[$relative] -ne (Get-FileHash -LiteralPath (Join-Path $repoRoot $relative) -Algorithm SHA256).Hash) {
        throw "Working-tree artifact changed during local checks: $relative"
    }
}
$summary = [ordered]@{
    Runtime = $PSVersionTable.PSVersion.ToString()
    OSVersion = [Environment]::OSVersion.Version.ToString()
    Windows10Validated = $false
    IncludeKnownIssues = [bool]$IncludeKnownIssues
    Passed = $result.PassedCount; Failed = $result.FailedCount; Skipped = $result.SkippedCount
    AnalyzerErrors = $errors.Count
    DistributionArtifactsUnchanged = $true
}
$summary | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $reportDir 'summary.json') -Encoding UTF8
Write-Host "Reports saved: $reportDir"
if ($result.Result -ne 'Passed') { throw 'Pester failed. Inspect pester.xml and the diagnostics above.' }
if (-not $IncludeKnownIssues -and (Test-Path -LiteralPath $knownIssuesPath)) {
    Write-Warning 'Baseline only: known critical acceptance tests are not included. This does not approve a release.'
}
