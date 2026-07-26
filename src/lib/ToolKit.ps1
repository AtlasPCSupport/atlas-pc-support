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
        $candidates = Get-ChildItem -Path 'C:\Program Files\WindowsApps' `
                                    -Filter 'winget.exe' -Recurse -ErrorAction SilentlyContinue |
                      Where-Object { $_.DirectoryName -like '*Microsoft.DesktopAppInstaller*' } |
                      Sort-Object -Property FullName -Descending

        if ($candidates) { return $candidates[0].FullName }
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
    }

    if (-not $WingetPath -or -not (Test-Path -LiteralPath $WingetPath)) { return $caps }

    $caps.Available = $true

    $raw = try { (& $WingetPath --version 2>$null | Select-Object -First 1) } catch { $null }
    if (-not $raw) { return $caps }

    $text = ([string]$raw).Trim().TrimStart('v')
    $caps.Version = $text

    $parsed = $null
    if ([version]::TryParse(($text -split '-')[0], [ref]$parsed)) {
        $caps.SupportsNoInteract = ($parsed -ge [version]'1.3')
        $caps.SupportsMsStore    = ($parsed -ge [version]'1.2')
    } else {
        $caps.SupportsNoInteract = $true
        $caps.SupportsMsStore    = $true
    }

    return $caps
}

function Install-AtlasWingetUnattended {
    [CmdletBinding()]
    param(
        [System.Collections.Concurrent.ConcurrentQueue[string]]$LogQueue
    )

    $ErrorActionPreference = 'Stop'

    function _InstallAppxPackage {
        param(
            [string]$Path,
            [string]$StepLabel
        )
        try {
            Add-AppxPackage -Path $Path -ErrorAction Stop
        } catch {
            $msg = $_.Exception.Message
            if ($msg -match '0x80073D06' -or $msg -match 'higher version' -or $msg -match 'versión superior' -or $msg -match 'already installed' -or $msg -match 'ya está instalada' -or $msg -match 'ya esta instalada') {
                _Log ("{0} Ya hay una version igual o superior instalada." -f $StepLabel)
            } else {
                throw $_
            }
        }
    }

    try {
        _Log '[1/3] Descargando dependencia VCLibs UWP...'
        $vclibsPath = Join-Path $env:TEMP 'Microsoft.VCLibs.x64.14.00.Desktop.appx'
        Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile $vclibsPath -UseBasicParsing -TimeoutSec 120

        _Log '[1/3] Instalando VCLibs...'
        _InstallAppxPackage -Path $vclibsPath -StepLabel '[1/3]'
        Remove-Item -LiteralPath $vclibsPath -Force -ErrorAction SilentlyContinue

        _Log '[2/3] Descargando dependencia UI.Xaml 2.8...'
        $uiXamlPath = Join-Path $env:TEMP 'Microsoft.UI.Xaml.2.8.x64.appx'
        Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile $uiXamlPath -UseBasicParsing -TimeoutSec 120

        _Log '[2/3] Instalando UI.Xaml...'
        _InstallAppxPackage -Path $uiXamlPath -StepLabel '[2/3]'
        Remove-Item -LiteralPath $uiXamlPath -Force -ErrorAction SilentlyContinue

        _Log '[3/3] Descargando App Installer (winget) msixbundle...'
        $wingetBundlePath = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller.msixbundle'
        Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $wingetBundlePath -UseBasicParsing -TimeoutSec 180

        _Log '[3/3] Instalando App Installer (winget)...'
        _InstallAppxPackage -Path $wingetBundlePath -StepLabel '[3/3]'
        Remove-Item -LiteralPath $wingetBundlePath -Force -ErrorAction SilentlyContinue

        _Log '[OK] Instalacion desatendida de winget completada exitosamente.'
        return $true
    } catch {
        _Log ("[X] Error al instalar winget desatendido: {0}" -f $_.Exception.Message)
        return $false
    }
}


