# ============================================================
# Atlas PC Support - Tool toolkit (helpers compartidos para TOOLS)
#
# A diferencia del resto de lib/, este archivo esta pensado para estar
# disponible DENTRO de cada tool, que corre aislada en su propia ventana.
# El ToolRunner inyecta el contenido de este archivo (embebido en el launcher
# y por tanto cubierto por launcher.ps1.sha256) al principio del wrapper
# temporal de cada tool. Asi se deduplican los banners, el calculo de carpeta
# de reportes y el armado de HTML que hoy cada tool reimplementa.
#
# REGLAS para este archivo:
#   - El runner aporta Operations para ejecutar consultas nativas con limite.
#   - Nunca debe lanzar al cargarse (solo define funciones).
#   - Cambios aqui afectan a TODAS las tools: mantener minimo y robusto.
# ============================================================

function Get-AtlasDependencyDefinition {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    if (-not $script:AtlasDependencyCatalog) {
        throw 'Dependency catalog unavailable. Reopen the current Atlas release.'
    }
    $entry = $script:AtlasDependencyCatalog.PSObject.Properties[$Name]
    if (-not $entry) { throw "Unknown dependency: $Name" }
    return $entry.Value
}

function Get-AtlasCurrentUserSid {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try { return $identity.User.Value } finally { $identity.Dispose() }
}

function Assert-AtlasLocalAdminRetention {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$TargetSid)

    # Read afresh immediately before a destructive account change. Domain groups
    # and disabled accounts do not establish a usable local recovery account.
    $users = @(Get-LocalUser -ErrorAction Stop)
    $target = @($users | Where-Object { [string]$_.SID -eq $TargetSid })
    if ($target.Count -ne 1) { throw 'The selected local account could not be verified.' }
    if ($target[0].Enabled -isnot [bool]) { throw 'The selected account enabled state could not be verified.' }
    $adminSids = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop |
        ForEach-Object { [string]$_.SID })
    if ($target[0].Enabled -and $adminSids -contains $TargetSid) {
        $otherAdmins = @($users | Where-Object {
            $_.Enabled -is [bool] -and $_.Enabled -and
            ($null -eq $_.AccountExpires -or $_.AccountExpires -gt (Get-Date)) -and
            [string]$_.SID -ne $TargetSid -and $adminSids -contains [string]$_.SID
        })
        if ($otherAdmins.Count -eq 0) {
            throw 'Another enabled local administrator must remain. Verify a recovery account first.'
        }
    }
}

function Get-AtlasReleaseFileHash {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$HashesUrl,
        [Parameter(Mandatory)][string]$FileName
    )
    $response = Invoke-WebRequest -Uri $HashesUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    if ($response.Content -is [byte[]]) {
        # Release checksum assets can be UTF-16 with a BOM and octet-stream MIME.
        $stream = [IO.MemoryStream]::new([byte[]]$response.Content)
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true)
        try { $raw = $reader.ReadToEnd() } finally { $reader.Dispose() }
    } else {
        $raw = [string]$response.Content
    }
    $pattern = '^\s*([a-fA-F0-9]{64})\s+\*?' + [regex]::Escape($FileName) + '\s*$'
    $matchesForFile = @(($raw -split '\r?\n') | Where-Object { $_ -match $pattern })
    if ($matchesForFile.Count -ne 1) { throw "Missing or ambiguous SHA-256 for $FileName." }
    $null = $matchesForFile[0] -match $pattern
    return $Matches[1].ToLowerInvariant()
}

function Assert-AtlasInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ExpectedSha256,
        [switch]$MicrosoftSignature
    )
    if ($ExpectedSha256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'A valid expected SHA-256 is required before executing the installer.' }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($actual -ine $ExpectedSha256) { throw 'Installer SHA-256 mismatch. Installation blocked.' }
    if ($MicrosoftSignature) {
        $signature = Get-AuthenticodeSignature -FilePath $Path -ErrorAction Stop
        if ($signature.Status -ne 'Valid' -or
            $signature.SignerCertificate.Subject -notmatch '(?:^|,\s*)O=Microsoft Corporation(?:,|$)') {
            throw 'A valid Microsoft Authenticode signature is required. Installation blocked.'
        }
    }
}

function Write-AtlasHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)] [string]$Title,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )
    $line = '=' * ([Math]::Min(60, [Math]::Max(12, $Title.Length + 6)))
    Write-Host ''
    Write-Host $line -ForegroundColor $Color
    Write-Host ("  {0}" -f $Title) -ForegroundColor $Color
    Write-Host $line -ForegroundColor $Color
}

function Write-AtlasStep {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [>] {0}" -f $Message) -ForegroundColor Cyan
}

function Write-AtlasSuccess {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [OK] {0}" -f $Message) -ForegroundColor Green
}

function Write-AtlasWarn {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [!] {0}" -f $Message) -ForegroundColor Yellow
}

function Write-AtlasFailure {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [X] {0}" -f $Message) -ForegroundColor Red
}

function Wait-AtlasExit {
    [CmdletBinding()]
    param([string]$Message = 'Presiona ENTER para cerrar')
    Write-Host ''
    [void](Read-Host $Message)
}

function Get-AtlasReportDir {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$SubFolder)
    $base = Join-Path $env:USERPROFILE 'Documents\AtlasPC\reports'
    $dir  = if ($SubFolder) { Join-Path $base $SubFolder } else { $base }
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function Get-AtlasReportPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$Prefix,
        [string]$Extension = 'html',
        [string]$SubFolder
    )
    $dir   = Get-AtlasReportDir -SubFolder $SubFolder
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $ext   = $Extension.TrimStart('.')
    return (Join-Path $dir ("{0}_{1}.{2}" -f $Prefix, $stamp, $ext))
}

function ConvertTo-AtlasHtmlEncoded {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][string]$Text)
    process {
        if ($null -eq $Text) { return '' }
        return [System.Net.WebUtility]::HtmlEncode($Text)
    }
}

function ConvertTo-AtlasHtmlDocument {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$BodyHtml,
        [string]$AccentColor = '#0078D4',
        [string]$Subtitle
    )
    $safeTitle    = ConvertTo-AtlasHtmlEncoded $Title
    $safeSubtitle = if ($Subtitle) { ConvertTo-AtlasHtmlEncoded $Subtitle } else { '' }
    $generated    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $subtitleHtml = if ($safeSubtitle) { "<p class='subtitle'>$safeSubtitle</p>" } else { '' }
    return @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
  :root { --accent: $AccentColor; }
  * { box-sizing: border-box; }
  body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 0; color: #1b1b1b; background: #f3f3f3; }
  header { background: var(--accent); color: #fff; padding: 24px 32px; }
  header h1 { margin: 0; font-size: 22px; }
  header .subtitle { margin: 6px 0 0; opacity: .9; font-size: 14px; }
  main { padding: 24px 32px; max-width: 1100px; margin: 0 auto; }
  section { background: #fff; border: 1px solid #e1e1e1; border-radius: 8px; padding: 16px 20px; margin-bottom: 16px; }
  h2 { font-size: 16px; border-bottom: 2px solid var(--accent); padding-bottom: 6px; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #eee; }
  th { background: #fafafa; }
  footer { text-align: center; color: #888; font-size: 12px; padding: 16px; }
  .ok { color: #107c10; } .warn { color: #c19c00; } .err { color: #d13438; }
</style>
</head>
<body>
<header>
  <h1>$safeTitle</h1>
  $subtitleHtml
</header>
<main>
$BodyHtml
</main>
<footer>Atlas PC Support &middot; generado $generated</footer>
</body>
</html>
"@
}

function Get-AtlasWingetPath {
    [CmdletBinding()]
    param()

    # 1) PATH normal
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
        return $cmd.Source
    }

    # 2) Ruta real del paquete Appx (evita el alias de WindowsApps de 0 bytes o faltante en admin elevacion)
    try {
        $pkg = Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' -ErrorAction SilentlyContinue |
               Sort-Object -Property Version -Descending |
               Select-Object -First 1

        if ($pkg -and $pkg.InstallLocation) {
            $exe = Join-Path $pkg.InstallLocation 'winget.exe'
            if (Test-Path -LiteralPath $exe) { return $exe }
        }
    } catch {}

    # 3) Elevado: buscar en Program Files\WindowsApps (si corre como admin diferente)
    try {
        $candidates = Get-ChildItem -LiteralPath 'C:\Program Files\WindowsApps' `
                                    -Filter 'Microsoft.DesktopAppInstaller_*' -Directory -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -match '^Microsoft\.DesktopAppInstaller_\d+\.\d+\.\d+\.\d+_x64__8wekyb3d8bbwe$' } |
                      Sort-Object { [version]($_.Name -split '_')[1] } -Descending
        foreach ($candidate in $candidates) {
            $exe = Join-Path $candidate.FullName 'winget.exe'
            if (Test-Path -LiteralPath $exe -PathType Leaf) { return $exe }
        }
    } catch {}

    return $null
}

function Get-AtlasWingetCapabilities {
    [CmdletBinding()]
    param([string]$WingetPath)

    $caps = [ordered]@{
        Available          = $false
        Version            = $null
        SupportsNoInteract = $false
        SupportsMsStore    = $false
        ProbeState         = 'Missing'
    }

    if (-not $WingetPath -or -not (Test-Path -LiteralPath $WingetPath)) { return $caps }

    $caps.ProbeState = 'NotEvaluated'
    try {
        $probe = Invoke-AtlasNativeProcess -FilePath $WingetPath -ArgumentList @('--version') -TimeoutSeconds 10
        $caps.ProbeState = $probe.State
        if ($probe.State -ne 'Correct') { return $caps }
        # Accept only WinGet's version response, never an error/banner or exit failure.
        $text = ([string]$probe.Stdout).Trim()
        $parsed = $null
        if ($text -notmatch '^v?(\d+\.\d+(?:\.\d+){0,2})(?:-[A-Za-z0-9.-]+)?$' -or
            -not [version]::TryParse($Matches[1], [ref]$parsed)) {
            $caps.ProbeState = 'NotEvaluated'
            return $caps
        }
        $caps.Available = $true
        $caps.Version = $text.TrimStart('v')
        $caps.SupportsNoInteract = ($parsed -ge [version]'1.4')
        $caps.SupportsMsStore = ($parsed -ge [version]'1.2')
    } catch {
        $caps.ProbeState = 'Failed'
    }

    return $caps
}
