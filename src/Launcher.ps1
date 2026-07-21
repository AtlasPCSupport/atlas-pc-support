# ============================================================
# Atlas PC Support — Launcher (DEV / modo código fuente)
# Para desarrollo local. Carga módulos desde src/.
# El launcher.ps1 de distribución (en raíz del repo) se genera
# con build.ps1 y tiene todo embebido para `irm | iex`.
# ============================================================

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# --- Descubrir rutas ---
if ($PSScriptRoot) {
    $script:AtlasRoot = Split-Path -Parent $PSScriptRoot
    $script:AtlasSrc  = $PSScriptRoot
} else {
    $script:AtlasRoot = (Get-Location).Path
    $script:AtlasSrc  = Join-Path $script:AtlasRoot 'src'
}

# --- Cargar librerías base ---
. (Join-Path $script:AtlasSrc 'lib\Branding.ps1')
. (Join-Path $script:AtlasSrc 'lib\Strings.ps1')
. (Join-Path $script:AtlasSrc 'lib\Admin.ps1')
. (Join-Path $script:AtlasSrc 'lib\Logging.ps1')
. (Join-Path $script:AtlasSrc 'lib\ToolKit.ps1')
. (Join-Path $script:AtlasSrc 'lib\Dependencies.ps1')
. (Join-Path $script:AtlasSrc 'lib\PS7.ps1')
. (Join-Path $script:AtlasSrc 'lib\ToolRunner.ps1')

# Fuente del ToolKit para que ToolRunner la inyecte en tools aisladas (modo dev).
$script:AtlasToolKitSource = Get-Content -Raw (Join-Path $script:AtlasSrc 'lib\ToolKit.ps1')

# --- Cargar todas las tools ---
$toolsDir = Join-Path $script:AtlasSrc 'tools'
Get-ChildItem -Path $toolsDir -Filter 'Invoke-*.ps1' | ForEach-Object { . $_.FullName }

# --- Cargar branding + manifiesto ---
$branding = Get-AtlasBranding
# Preferencia guardada por el usuario (selector de idioma) manda sobre branding / auto-detect.
$savedLang = Get-AtlasLanguagePref
if ($savedLang) {
    $currentLang = Set-AtlasLanguage $savedLang
} else {
    $currentLang = Set-AtlasLanguage $branding.language
}
Initialize-AtlasLog | Out-Null
Write-AtlasLog "Atlas PC Support iniciado ($($branding.brand.name) v$($branding.brand.version), lang=$currentLang)"

# Detectar PS 7 y cachear la ruta (ToolRunner la usa para lanzar tools en pwsh).
$ps7 = Initialize-AtlasPS7
if ($ps7) {
    Write-AtlasLog "PowerShell 7 disponible: $ps7"
} else {
    Write-AtlasLog "PowerShell 7 NO instalado; tools correran en Windows PowerShell 5.1. Recomendado: usar tool 'Actualizar PowerShell'."
}

# Fuente remota para scripts de herramientas (fallback cuando no hay USB/cache).
$script:AtlasToolsBaseUrl = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/src/tools'

# Optional out-of-band digest channel for config/tool-hashes.json.
# Use a separate control plane (e.g. Cloudflare Worker secret route) and set
# DigestRequired=$true once the route is deployed and maintained on each release.
$script:AtlasToolHashesDigestUrl = 'https://toolspanel.atlaspcsupport.com/tool-hashes.sha256'
$script:AtlasToolHashesDigestRequired = $true

# Tabla de hashes esperados para validar integridad de tools descargadas.
$script:AtlasToolHashes = @{}
$toolHashesPath = Join-Path $script:AtlasRoot 'config\tool-hashes.json'
if (Test-Path -LiteralPath $toolHashesPath) {
    try {
        $toolHashesObj = ConvertFrom-AtlasJson (Get-Content -Raw -LiteralPath $toolHashesPath -Encoding UTF8)
        if ($toolHashesObj.files -is [hashtable]) {
            $script:AtlasToolHashes = $toolHashesObj.files
            Write-AtlasLog "Hashes de tools cargados: $($script:AtlasToolHashes.Count)" -Tool 'Launcher'
        } else {
            Write-AtlasLog "tool-hashes.json no contiene bloque 'files' valido." -Level WARN -Tool 'Launcher'
        }
    } catch {
        Write-AtlasLog "No se pudo cargar tool-hashes.json: $_" -Level WARN -Tool 'Launcher'
    }
} else {
    Write-AtlasLog "tool-hashes.json no encontrado; ToolRunner funcionara sin validacion fuerte de hash." -Level WARN -Tool 'Launcher'
}

$toolsManifestPath = Join-Path $script:AtlasRoot 'config\tools.json'
$manifest = ConvertFrom-AtlasJson (Get-Content -Raw $toolsManifestPath)
$tools = @($manifest.tools)

# --- Cargar XAML GUI ---
. (Join-Path $script:AtlasSrc 'gui\MainWindow.ps1')
$xamlTemplate = Get-Content -Raw (Join-Path $script:AtlasSrc 'gui\MainWindow.xaml')

# --- Lanzar GUI ---
Show-AtlasWindow -Branding $branding -Tools $tools -XamlTemplate $xamlTemplate
