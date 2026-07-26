param(
    [string]$GithubPat = $env:GITHUB_PAT
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx not found. Install Node.js 20+ first."
}

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

Write-Host "[OK] GITHUB_PAT updated." -ForegroundColor Green
