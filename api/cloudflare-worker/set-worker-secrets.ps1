param(
    [string]$GithubPat = $env:GITHUB_PAT,
    [string]$LauncherShaPath = '..\..\launcher.ps1.sha256',
    [string]$ToolHashesPath = '..\..\config\tool-hashes.json'
)

$ErrorActionPreference = 'Stop'

function Get-ShaFromShaFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "SHA sidecar not found: $Path"
    }
    $line = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path))
    $sha = (($line -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
    if ($sha -notmatch '^[a-f0-9]{64}$') {
        throw "Invalid SHA file format at $Path"
    }
    return $sha
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx not found. Install Node.js 20+ first."
}

$launcherSha = Get-ShaFromShaFile -Path $LauncherShaPath
if (-not (Test-Path -LiteralPath $ToolHashesPath)) {
    throw "tool-hashes.json not found: $ToolHashesPath"
}
$toolHashesSha = (Get-FileHash -LiteralPath (Resolve-Path -LiteralPath $ToolHashesPath) -Algorithm SHA256).Hash.ToLowerInvariant()

if (-not $GithubPat) {
    $securePat = Read-Host -AsSecureString "Enter GITHUB_PAT secret for Worker"
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePat)
    try {
        $GithubPat = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

if (-not $GithubPat) {
    throw "GITHUB_PAT is required."
}

Write-Host "Setting Worker secrets..." -ForegroundColor Cyan

$GithubPat | npx wrangler secret put GITHUB_PAT | Out-Null
$launcherSha | npx wrangler secret put ATLAS_LAUNCHER_SHA256 | Out-Null
$toolHashesSha | npx wrangler secret put ATLAS_TOOL_HASHES_SHA256 | Out-Null

Write-Host "[OK] Secrets updated." -ForegroundColor Green
Write-Host "ATLAS_LAUNCHER_SHA256 = $launcherSha"
Write-Host "ATLAS_TOOL_HASHES_SHA256 = $toolHashesSha"
