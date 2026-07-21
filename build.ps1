#Requires -Version 5.1
<#
.SYNOPSIS
  Compila el launcher distribuible `launcher.ps1` (raíz del repo) a partir
  de los módulos en src/. Embebe: lib, gui, manifiesto y XAML.
  Las tools (Invoke-*.ps1) NO se embeben — se descargan bajo demanda.

.DESCRIPTION
  Ejecuta este script con:
      pwsh -File build.ps1
#>
[CmdletBinding()]
param(
    [string]$OutFile = (Join-Path $PSScriptRoot 'launcher.ps1')
)

$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'src'
if (-not (Test-Path $src)) { throw "No existe $src" }
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Get-EmbeddedContent {
    param([string]$Path)
    $content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    # Normaliza saltos de línea
    return $content -replace "`r`n", "`n"
}

function Get-AtlasNormalizedTextSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    # Canonical UTF-8 + LF hash to avoid CRLF/LF drift across environments.
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $normalized = ($text -replace "`r`n", "`n") -replace "`r", "`n"
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

$version      = '1.0.0'
$buildDate    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$manifest     = Get-EmbeddedContent (Join-Path $PSScriptRoot 'config\tools.json')
$xamlTemplate = Get-EmbeddedContent (Join-Path $src 'gui\MainWindow.xaml')
$toolkitSource = Get-EmbeddedContent (Join-Path $src 'lib\ToolKit.ps1')
$toolsBaseUrl = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/src/tools'

# Mapa de hashes SHA-256 de herramientas (integridad en ToolRunner).
$toolHashMap = [ordered]@{}
Get-ChildItem -Path (Join-Path $src 'tools') -Filter 'Invoke-*.ps1' -File |
    Sort-Object -Property { $_.Name.ToLowerInvariant() } |
    ForEach-Object {
        $toolHashMap[$_.Name] = Get-AtlasNormalizedTextSha256 -Path $_.FullName
    }

# Validaciones de coherencia: manifest <-> source files <-> hash map.
try {
    $manifestBuildObj = $manifest | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "config/tools.json invalido: $($_.Exception.Message)"
}
$manifestTools = @($manifestBuildObj.tools)
if ($manifestTools.Count -eq 0) {
    throw "config/tools.json no contiene tools."
}

$manifestSourceMap = @{}
foreach ($tool in $manifestTools) {
    $toolId = [string]$tool.id
    $toolSource = [string]$tool.source
    $toolFunction = [string]$tool.function
    if (-not $toolId) { throw "Tool sin 'id' en config/tools.json." }
    if (-not $toolSource) { throw "Tool '$toolId' sin 'source' en config/tools.json." }
    if (-not $toolFunction) { throw "Tool '$toolId' sin 'function' en config/tools.json." }
    if ($manifestSourceMap.ContainsKey($toolSource)) {
        throw "Source duplicado en manifest: $toolSource"
    }
    $manifestSourceMap[$toolSource] = $toolId

    $expectedFunction = [System.IO.Path]::GetFileNameWithoutExtension($toolSource)
    if ($toolFunction -ne $expectedFunction) {
        throw "Tool '$toolId': function '$toolFunction' debe coincidir con '$expectedFunction'."
    }

    $toolSourcePath = Join-Path $src "tools\$toolSource"
    if (-not (Test-Path -LiteralPath $toolSourcePath)) {
        throw "Tool '$toolId' apunta a source inexistente: $toolSource"
    }
}

foreach ($toolSource in $manifestSourceMap.Keys) {
    if (-not $toolHashMap.Contains($toolSource)) {
        throw "Falta hash para tool en manifest: $toolSource"
    }
}
foreach ($toolFileName in $toolHashMap.Keys) {
    if (-not $manifestSourceMap.ContainsKey([string]$toolFileName)) {
        Write-Warning "Tool source sin entrada en manifest: $toolFileName"
    }
}

$toolHashEnvelope = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    algorithm   = 'SHA256'
    files       = $toolHashMap
}
$toolHashesJson = ($toolHashEnvelope | ConvertTo-Json -Depth 6)

$libFiles = @(
    'lib\Branding.ps1'
    'lib\Strings.ps1'
    'lib\Admin.ps1'
    'lib\Logging.ps1'
    'lib\ToolKit.ps1'
    'lib\Dependencies.ps1'
    'lib\PS7.ps1'
    'lib\ToolRunner.ps1'
)
$libContent = foreach ($f in $libFiles) {
    $path = Join-Path $src $f
    "# ---- $f ----`n" + (Get-EmbeddedContent $path)
}
$libContent = $libContent -join "`n`n"

$guiContent = Get-EmbeddedContent (Join-Path $src 'gui\MainWindow.ps1')


$banner = (@"
# ============================================================
#  Atlas PC Support — launcher.ps1 (compilado)
#  Versión: $version
#  Build:   $buildDate
#  Repo:    https://github.com/mikepchelper-spec/atlas-pc-support
#
#  Uso:
#      Save get.ps1 locally and run: pwsh -ExecutionPolicy Bypass -File get.ps1
#
#  Este archivo es AUTOGENERADO por build.ps1. NO lo edites a mano.
#  Las fuentes están en src/.
# ============================================================
"@) -replace "`r`n", "`n"

$epilog = @'

# ============================================================
#  BOOTSTRAP
# ============================================================

$ErrorActionPreference = 'Stop'

$branding = Get-AtlasBranding
# Preferencia guardada por el usuario (selector de idioma) manda sobre branding / auto-detect.
$savedLang = Get-AtlasLanguagePref
if ($savedLang) {
    $currentLang = Set-AtlasLanguage $savedLang
} else {
    $currentLang = Set-AtlasLanguage $branding.language
}
Initialize-AtlasLog | Out-Null
Write-AtlasLog "Atlas PC Support iniciado (launcher compilado v$script:AtlasVersion, lang=$currentLang, savedPref=$savedLang)"

# Detectar PS 7 y cachear la ruta (ToolRunner lo usa para lanzar tools en pwsh).
$ps7 = Initialize-AtlasPS7
if ($ps7) {
    Write-AtlasLog "PowerShell 7 disponible: $ps7"
} else {
    Write-AtlasLog "PowerShell 7 NO instalado; tools correran en Windows PowerShell 5.1. Usar la tool 'Actualizar PowerShell'."
}

try {
    $toolHashesObj = ConvertFrom-AtlasJson $script:AtlasToolHashesJson
    if ($toolHashesObj.files -is [hashtable]) {
        $script:AtlasToolHashes = $toolHashesObj.files
        Write-AtlasLog "Hashes embebidos cargados: $($script:AtlasToolHashes.Count)" -Tool 'Launcher'
    } else {
        $script:AtlasToolHashes = @{}
        Write-AtlasLog "Hash map embebido invalido; continuando sin validacion fuerte." -Level WARN -Tool 'Launcher'
    }
} catch {
    $script:AtlasToolHashes = @{}
    Write-AtlasLog "No se pudo parsear hash map embebido: $_" -Level WARN -Tool 'Launcher'
}

try {
    $manifestObj = ConvertFrom-AtlasJson $script:AtlasToolsManifest
    $tools = @($manifestObj.tools)
} catch {
    throw "No se pudo parsear el manifiesto embebido: $_"
}

Show-AtlasWindow -Branding $branding -Tools $tools -XamlTemplate $script:AtlasXamlTemplate
'@
$epilog = $epilog -replace "`r`n", "`n"

$manifestEscaped = $manifest.Replace("'", "''")
$xamlEscaped     = $xamlTemplate.Replace("'", "''")
$toolHashesEscaped = $toolHashesJson.Replace("'", "''")
$toolkitEscaped  = $toolkitSource

$embeddedData = (@"

# ============================================================
#  DATOS EMBEBIDOS
# ============================================================

`$script:AtlasVersion = '$version'
`$script:AtlasBuildDate = '$buildDate'
`$script:AtlasToolsBaseUrl = '$toolsBaseUrl'

`$script:AtlasToolsManifest = @'
$manifestEscaped
'@

`$script:AtlasToolHashesJson = @'
$toolHashesEscaped
'@

`$script:AtlasXamlTemplate = @'
$xamlEscaped
'@

`$script:AtlasToolKitSource = @'
$toolkitEscaped
'@
"@) -replace "`r`n", "`n"

$output = @(
    $banner
    ""
    "#Requires -Version 5.1"
    ""
    $embeddedData
    ""
    "# ============================================================"
    "#  LIBRERÍAS (lib/)"
    "# ============================================================"
    ""
    $libContent
    ""
    "# ============================================================"
    "#  GUI"
    "# ============================================================"
    ""
    $guiContent
    ""
    $epilog
) -join "`n"

# Write UTF-8 WITHOUT BOM.
#
# Two competing requirements:
#   (a) Windows PowerShell 5.1 reads BOM-less .ps1 files as ANSI/CP1252,
#       which mojibakes accents/emojis if the launcher is loaded by file
#       path (e.g. via run.bat → run-launcher.ps1 → launcher.ps1).
#   (b) PS 5.1's `irm <url> | iex` keeps the UTF-8 BOM as a literal U+FEFF
#       at the start of the string, which the PS 5.1 parser then chokes on
#       with: "The term '﻿#' is not recognized as a name of a cmdlet ...".
#
# We chose path (b) wins: file in the repo / on raw.githubusercontent.com
# stays BOM-less so `irm | iex` works for everyone. The offline USB path
# already has self-healing BOM repair in bootstrap.ps1 (PR #53), so when
# BOM-less variant on both Windows and Linux pwsh.
[System.IO.File]::WriteAllText($OutFile, $output, $utf8NoBom)

# Persistir hash map de tools para launcher DEV / tests.
$toolHashesPath = Join-Path $PSScriptRoot 'config\tool-hashes.json'
[System.IO.File]::WriteAllText($toolHashesPath, $toolHashesJson, $utf8NoBom)

# Sidecar de integridad del launcher distribuible (consumido por get.ps1).
$launcherHash = (Get-FileHash -LiteralPath $OutFile -Algorithm SHA256).Hash.ToLowerInvariant()
$toolHashesFileSha = (Get-FileHash -LiteralPath $toolHashesPath -Algorithm SHA256).Hash.ToLowerInvariant()
$launcherName = Split-Path -Leaf $OutFile
$launcherShaPath = "$OutFile.sha256"
[System.IO.File]::WriteAllText(
    $launcherShaPath,
    ("{0}  {1}{2}" -f $launcherHash, $launcherName, [Environment]::NewLine),
    $utf8NoBom
)

Write-Host ""
Write-Host "  Atlas PC Support - build completado" -ForegroundColor Green
Write-Host "  Archivo: $OutFile" -ForegroundColor Gray
$fi = Get-Item $OutFile
Write-Host ("  Tamano:  {0} KB ({1} MB)" -f [math]::Round($fi.Length / 1KB, 1), [math]::Round($fi.Length / 1MB, 2)) -ForegroundColor Gray
Write-Host "  Build:   $buildDate" -ForegroundColor Gray
Write-Host "  Hash:    $launcherHash" -ForegroundColor Gray
Write-Host "  Hashes:  $toolHashesFileSha  (config/tool-hashes.json)" -ForegroundColor Gray
Write-Host "  SHA256:  $launcherShaPath" -ForegroundColor Gray
Write-Host "  Tools:   $toolHashesPath" -ForegroundColor Gray
Write-Host "  OOB tip: set Worker secrets ATLAS_LAUNCHER_SHA256 and ATLAS_TOOL_HASHES_SHA256 with values above." -ForegroundColor DarkGray
Write-Host ""
