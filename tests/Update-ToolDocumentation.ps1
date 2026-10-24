#Requires -Version 5.1
[CmdletBinding()]
param([string]$RepoRoot, [switch]$Check)
$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
$tools = @((Get-Content -LiteralPath (Join-Path $RepoRoot 'config/tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json).tools)
$dependencies = Get-Content -LiteralPath (Join-Path $RepoRoot 'config/dependencies.json') -Raw -Encoding UTF8 | ConvertFrom-Json
function ConvertTo-TableCell([object]$Value) { return ([string]$Value).Replace('|','\|').Replace("`r",' ').Replace("`n",' ') }
$lines = @(
    '# Inventario generado de Atlas PC Support',
    '',
    'Generado desde `config/tools.json` y `config/dependencies.json`. No editar a mano.',
    'Regenerar: `pwsh -NoProfile -File tests/Update-ToolDocumentation.ps1`.',
    '',
    ('Entradas: **' + $tools.Count + '**. Plataforma base: cliente Windows x64 build 19044+.'),
    'El contrato describe requisitos; no certifica todas las operaciones en cada edición.',
    'PowerShell 5.1 es el runtime predeterminado. Las pruebas Win10 en VM figuran pendientes en el cierre del plan.',
    '',
    '| ID / herramienta | Función y alcance | Requisitos | Disponibilidad |',
    '|---|---|---|---|'
)
foreach ($tool in $tools) {
    $runtime = $tool.runtime
    $requirements = "x64; $($runtime.engine) >= $($runtime.minimumVersion); build >= $($tool.availability.minimumBuild)"
    if ($tool.requiresAdmin) { $requirements += '; admin' }
    if ($tool.availability.commands) { $requirements += '; ' + (@($tool.availability.commands) -join ', ') }
    $availability = if ($tool.availability.disabledReason) { $tool.availability.disabledReason } else { 'Según capacidades; comprobar políticas y permisos de la operación.' }
    $lines += '| ' + (ConvertTo-TableCell "$($tool.id) / $($tool.nameEs) / $($tool.name)") + ' | ' + (ConvertTo-TableCell $tool.descriptionEs) + ' | ' + (ConvertTo-TableCell $requirements) + ' | ' + (ConvertTo-TableCell $availability) + ' |'
}
$lines += @('', '## Dependencias', '', 'Cada proveedor conserva su licencia. MIT de Atlas no autoriza redistribuir binarios de terceros.', '', '| Dependencia | Versión/origen | Arquitectura | Validación | Licencia |', '|---|---|---|---|---|')
foreach ($property in $dependencies.PSObject.Properties) {
    $entry = $property.Value
    $lines += '| ' + (ConvertTo-TableCell $property.Name) + ' | ' + (ConvertTo-TableCell "$($entry.Version) / $($entry.VersionSource)") + ' | ' + (ConvertTo-TableCell $entry.Architecture) + ' | ' + (ConvertTo-TableCell $entry.SignaturePolicy) + ' | ' + (ConvertTo-TableCell $entry.License) + ' |'
}
$text = ($lines -join "`n") + "`n"
$path = Join-Path $RepoRoot 'docs/INVENTARIO.md'
if ($Check) {
    if (-not (Test-Path -LiteralPath $path) -or [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8).Replace("`r`n","`n") -cne $text) { throw 'Stale docs/INVENTARIO.md. Run tests/Update-ToolDocumentation.ps1 and commit the result.' }
    Write-Host 'Generated tool/dependency inventory is current.'
} else { [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
