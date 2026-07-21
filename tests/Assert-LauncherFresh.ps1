#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Detecta un launcher.ps1 / tool-hashes.json "stale": commiteados sin
    reconstruir desde src/. Insensible a diferencias volatiles (fecha de
    build embebida y fin de linea CRLF/LF).

.DESCRIPTION
    El launcher distribuible (launcher.ps1) y config/tool-hashes.json son
    AUTOGENERADOS por build.ps1 a partir de src/. Si alguien edita src/ pero
    olvida reconstruir y commitear, los usuarios reciben (via irm | iex) una
    version desincronizada del codigo fuente. Este check lo bloquea en CI.

    Estrategia:
      1. Toma snapshot normalizado de los artefactos commiteados.
      2. Reconstruye con build.ps1 (sobre-escribe en sitio; el checkout de CI
         es efimero).
      3. Compara el contenido normalizado. Diferencia = stale.

    Las lineas de fecha de build y el campo generatedAt cambian en cada build,
    asi que se neutralizan antes de comparar. Tambien se normaliza CRLF -> LF
    para evitar falsos positivos entre Windows y Linux.

    Exit 0 = en sync. Exit 1 = stale (ejecutar `pwsh -File build.ps1` y commitear).
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

function Get-AtlasNormalizedArtifact {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $t = $Text -replace "`r`n", "`n"
    $t = $t -replace "`r", "`n"
    # Neutralizar campos volatiles (cambian en cada build).
    $t = $t -replace '(?m)^#\s+Build:.*$',                  '#  Build: <normalized>'
    $t = $t -replace '(?m)^\$script:AtlasBuildDate\s*=.*$',  '$script:AtlasBuildDate = <normalized>'
    $t = $t -replace '"generatedAt"\s*:\s*"[^"]*"',          '"generatedAt": "<normalized>"'
    return $t
}

$launcherPath  = Join-Path $RepoRoot 'launcher.ps1'
$hashesPath    = Join-Path $RepoRoot 'config/tool-hashes.json'
$buildScript   = Join-Path $RepoRoot 'build.ps1'

foreach ($p in @($launcherPath, $hashesPath, $buildScript)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "No existe ruta requerida: $p" }
}

$committedLauncher = Get-AtlasNormalizedArtifact ([System.IO.File]::ReadAllText($launcherPath, [System.Text.Encoding]::UTF8))
$committedHashes   = Get-AtlasNormalizedArtifact ([System.IO.File]::ReadAllText($hashesPath, [System.Text.Encoding]::UTF8))

Write-Host '[..] Reconstruyendo launcher desde src/ para comparar...' -ForegroundColor Cyan
& $buildScript | Out-Null

$rebuiltLauncher = Get-AtlasNormalizedArtifact ([System.IO.File]::ReadAllText($launcherPath, [System.Text.Encoding]::UTF8))
$rebuiltHashes   = Get-AtlasNormalizedArtifact ([System.IO.File]::ReadAllText($hashesPath, [System.Text.Encoding]::UTF8))

$stale = $false

if ($committedLauncher -ne $rebuiltLauncher) {
    Write-Host '::error file=launcher.ps1::launcher.ps1 esta desactualizado respecto a src/. Ejecuta `pwsh -File build.ps1` y commitea el resultado.'
    Write-Host '[FAIL] launcher.ps1 stale.' -ForegroundColor Red
    $stale = $true
} else {
    Write-Host '[OK]   launcher.ps1 coincide con src/.' -ForegroundColor Green
}

if ($committedHashes -ne $rebuiltHashes) {
    Write-Host '::error file=config/tool-hashes.json::tool-hashes.json esta desactualizado respecto a src/tools/. Ejecuta `pwsh -File build.ps1` y commitea el resultado.'
    Write-Host '[FAIL] config/tool-hashes.json stale.' -ForegroundColor Red
    $stale = $true
} else {
    Write-Host '[OK]   config/tool-hashes.json coincide con src/tools/.' -ForegroundColor Green
}

if ($stale) {
    Write-Host ''
    Write-Host '=== RESULTADO: artefactos compilados DESACTUALIZADOS ===' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '=== RESULTADO: artefactos compilados en sync con src/ ===' -ForegroundColor Green
exit 0
