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
#   - Debe ser 100% autonomo (no depende de otras funciones de lib/).
#   - Nunca debe lanzar al cargarse (solo define funciones).
#   - Cambios aqui afectan a TODAS las tools: mantener minimo y robusto.
# ============================================================

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
