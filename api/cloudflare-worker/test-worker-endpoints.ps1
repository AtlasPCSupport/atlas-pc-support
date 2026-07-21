param(
    [string]$BaseUrl = 'https://toolspanel.atlaspcsupport.com',
    [int]$TimeoutSec = 30
)

$ErrorActionPreference = 'Stop'

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
            'bootstrap'    { $ok = $ok -and ($bodyText -match '(?m)^\s*#\s*Atlas PC Support - get\.ps1') }
            'launcher_sha' { $ok = $ok -and (Test-ShaLine -Text $first -FileName 'launcher.ps1') }
            'tools_sha'    { $ok = $ok -and (Test-ShaLine -Text $first -FileName 'tool-hashes.json') }
            'install_bat'  {
                $ok = $ok -and ($bodyText -match '(?im)^@echo off')
            }
            'install_ps1'  { $ok = $ok -and ($bodyText -match '(?m)^#') }
            'install_sha'  { $ok = $ok -and ($first -match '^[a-f0-9]{64}\s+install-rustdesk\.ps1') }
            'healthz'      { $ok = $ok -and ($first -eq 'ok') }
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

$results | Format-Table -AutoSize

if ($failed) {
    throw "Cloudflare worker validation failed. Review failing route(s) above."
}

Write-Host "[OK] Worker endpoints validated." -ForegroundColor Green
