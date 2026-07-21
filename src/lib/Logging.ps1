# ============================================================
# Atlas PC Support - Central logging
# ============================================================

$script:AtlasLogFile = $null

function Initialize-AtlasLog {
    [CmdletBinding()]
    param(
        [string]$LogPath = (Expand-AtlasPath "%LOCALAPPDATA%\AtlasPC\logs")
    )

    $resolvedLogPath = Initialize-AtlasSecureDirectory -Path $LogPath
    if (-not $resolvedLogPath) {
        $resolvedLogPath = Expand-AtlasPath $LogPath
        if (-not (Test-Path -LiteralPath $resolvedLogPath)) {
            New-Item -ItemType Directory -Path $resolvedLogPath -Force | Out-Null
        }
    }

    $date = Get-Date -Format "yyyy-MM-dd"
    $script:AtlasLogFile = Join-Path $resolvedLogPath "atlas-$date.log"

    $header = @"

================================================================
 Atlas PC Support — sesión iniciada $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
 Equipo : $env:COMPUTERNAME
 Usuario: $env:USERNAME
================================================================
"@
    Add-Content -Path $script:AtlasLogFile -Value $header -Encoding UTF8
    [void](Set-AtlasPathAcl -Path $script:AtlasLogFile)
    return $script:AtlasLogFile
}

function Write-AtlasLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)] [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')] [string]$Level = 'INFO',
        [string]$Tool = ''
    )
    if (-not $script:AtlasLogFile) { Initialize-AtlasLog | Out-Null }
    $ts   = Get-Date -Format "HH:mm:ss"
    $tool = if ($Tool) { "[$Tool] " } else { "" }
    $line = "[$ts] [$Level] $tool$Message"
    try {
        Add-Content -Path $script:AtlasLogFile -Value $line -Encoding UTF8
    } catch {
        # no op — logging nunca debe romper la tool
    }
}

function Get-AtlasLogPath {
    if (-not $script:AtlasLogFile) { Initialize-AtlasLog | Out-Null }
    return $script:AtlasLogFile
}
