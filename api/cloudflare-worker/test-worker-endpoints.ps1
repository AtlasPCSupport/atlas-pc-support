[CmdletBinding()]
param(
    [string]$BaseUrl = 'https://toolspanel.atlaspcsupport.com',
    [int]$TimeoutSec = 30,
    [string]$ExpectedCommit,
    [string]$ExpectedManifestSha256
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repoRoot 'src/bootstrap/Runtime.ps1')
. (Join-Path $repoRoot 'src/lib/Release.ps1')

function Test-AtlasServedBootstrap {
    param([string]$Text, [object]$Descriptor, [object]$Manifest)
    if (-not $Text.Contains("'$($Descriptor.commit)'") -or -not $Text.Contains("'$($Descriptor.manifestSha256)'")) { return $false }
    $canonical = $Text.Replace("'$($Descriptor.commit)'", "'__ATLAS_RELEASE_COMMIT__'").Replace("'$($Descriptor.manifestSha256)'", "'__ATLAS_RELEASE_MANIFEST_SHA256__'")
    return (Get-AtlasTextHash $canonical) -ceq $Manifest.files.'get.ps1'
}

function Get-FirstLine {
    param([string]$Text)
    if (-not $Text) { return '' }
    return (($Text -split "`r?`n") | Select-Object -First 1)
}

function Convert-ToText {
    param($Value)
    if ($null -eq $Value) { return '' }
    if ($Value -is [byte[]]) {
        return [System.Text.Encoding]::UTF8.GetString($Value)
    }
    return [string]$Value
}

function Test-ShaLine {
    param([string]$Text, [string]$FileName)
    if (-not $Text) { return $false }
    return ($Text -match "^[a-f0-9]{64}\s+$([regex]::Escape($FileName))")
}

$descriptor = Invoke-RestMethod ($BaseUrl.TrimEnd('/') + '/release.json?v=' + [guid]::NewGuid().ToString('N')) -TimeoutSec $TimeoutSec
Assert-AtlasReleaseDescriptor $descriptor
if (($ExpectedCommit -and $descriptor.commit -cne $ExpectedCommit) -or
    ($ExpectedManifestSha256 -and $descriptor.manifestSha256 -cne $ExpectedManifestSha256)) { throw 'Unexpected published commit or manifest digest.' }
$manifestPath = Join-Path ([IO.Path]::GetTempPath()) ('atlas-endpoint-manifest-' + [guid]::NewGuid().ToString('N') + '.json')
try {
    Invoke-WebRequest ($BaseUrl.TrimEnd('/') + '/release-manifest.json?v=' + [guid]::NewGuid().ToString('N')) -UseBasicParsing -TimeoutSec $TimeoutSec -OutFile $manifestPath
    if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $descriptor.manifestSha256) { throw 'Public manifest digest mismatch.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
} finally { if (Test-Path -LiteralPath $manifestPath) { Remove-Item -LiteralPath $manifestPath -Force } }

$tests = @(
    @{ Path = '/';                    ExpectStatus = 200; Kind = 'bootstrap'    },
    @{ Path = '/launcher.sha256';     ExpectStatus = 200; Kind = 'launcher_sha' },
    @{ Path = '/tool-hashes.sha256';  ExpectStatus = 200; Kind = 'tools_sha'    },
    @{ Path = '/install.bat';         ExpectStatus = 200; Kind = 'install_bat'  },
    @{ Path = '/install.ps1';         ExpectStatus = 200; Kind = 'install_ps1'  },
    @{ Path = '/install.ps1.sha256';  ExpectStatus = 200; Kind = 'install_sha'  },
    @{ Path = '/healthz';             ExpectStatus = 200; Kind = 'healthz'      }
)

$results = @()
$failed = $false

foreach ($t in $tests) {
    $url = ($BaseUrl.TrimEnd('/') + $t.Path + '?v=' + [guid]::NewGuid().ToString('N'))
    try {
        $res = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        $ok = ($res.StatusCode -eq $t.ExpectStatus)
        $bodyText = Convert-ToText -Value $res.Content
        $first = Get-FirstLine -Text $bodyText

        switch ($t.Kind) {
            'bootstrap'    { $ok = $ok -and (Test-AtlasServedBootstrap -Text $bodyText -Descriptor $descriptor -Manifest $manifest) }
            'launcher_sha' { $ok = $ok -and (Test-ShaLine -Text $first -FileName 'launcher.ps1') }
            'tools_sha'    { $ok = $ok -and (Test-ShaLine -Text $first -FileName 'tool-hashes.json') }
            'install_bat'  {
                $ok = $ok -and ((Get-AtlasTextHash $bodyText) -ceq $manifest.files.'onboarding/install.bat')
            }
            'install_ps1'  { $ok = $ok -and ($bodyText -match '(?m)^#') }
            'install_sha'  { $ok = $ok -and ($first -match '^[a-f0-9]{64}\s+install-rustdesk\.ps1') }
            'healthz'      { $ok = $ok -and ($first -eq 'ok') }
        }
        if ($t.Kind -notin @('install_ps1','install_sha','healthz')) {
            $ok = $ok -and ([string]$res.Headers['X-Atlas-Source-Ref'] -ceq $descriptor.commit) -and
                ([string]$res.Headers['X-Atlas-Manifest-Sha256'] -ceq $descriptor.manifestSha256)
        }

        $results += [pscustomobject]@{
            Path      = $t.Path
            Status    = $res.StatusCode
            FirstLine = $first
            Pass      = $ok
        }
        if (-not $ok) { $failed = $true }
    } catch {
        $results += [pscustomobject]@{
            Path      = $t.Path
            Status    = 'ERR'
            FirstLine = $_.Exception.Message
            Pass      = $false
        }
        $failed = $true
    }
}

# Do not echo private installer content or upstream exception details.
$results | Select-Object Path,Status,Pass | Format-Table -AutoSize

if ($failed) {
    throw "Cloudflare worker validation failed. Review failing route(s) above."
}

Write-Host "[OK] Worker endpoints validated." -ForegroundColor Green
