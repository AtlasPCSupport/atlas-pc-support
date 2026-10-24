#Requires -Version 5.1
[CmdletBinding()]
param([string]$RepoRoot = (Join-Path $PSScriptRoot '..'))
$ErrorActionPreference = 'Stop'
$names = @('get.ps1','launcher.ps1','launcher.ps1.sha256','config/tool-hashes.json','release-manifest.json')
$before = @{}
foreach ($name in $names) {
    $before[$name] = (Get-FileHash -LiteralPath (Join-Path $RepoRoot $name) -Algorithm SHA256 -ErrorAction Stop).Hash
}
& (Join-Path $RepoRoot 'build.ps1') | Out-Null
foreach ($name in $names) {
    $after = (Get-FileHash -LiteralPath (Join-Path $RepoRoot $name) -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($before[$name] -cne $after) { throw "Stale distribution artifact: $name. Rebuild and commit the complete release." }
    Write-Host "[OK] Reproducible distribution artifact: $name"
}
