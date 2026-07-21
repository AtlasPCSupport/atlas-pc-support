#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Valida coherencia de launcher, manifest y hashes de tools.

.DESCRIPTION
    Checks incluidos:
      - Parse AST de launcher.ps1.
      - Parse AST de todos los Invoke-*.ps1 (manifest + disco).
      - Coherencia manifest (ids/sources/functions requeridos y sin duplicados).
      - Coherencia de config/tool-hashes.json (llaves, formato y hash real por archivo).

    Exit code 0 = todo OK, 1 = hubo errores.
#>
[CmdletBinding()]
param(
    [string]$LauncherPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'launcher.ps1'),
    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config\tools.json'),
    [string]$ToolHashesPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config\tool-hashes.json'),
    [string]$ToolsDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'src\tools')
)

$ErrorActionPreference = 'Stop'
$script:FailCount = 0

function Write-CheckOk {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-CheckFail {
    param([string]$Message)
    $script:FailCount++
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Get-AstParseErrors {
    param([Parameter(Mandatory)][string]$Path)
    $errs = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errs)
    return @($errs)
}

function Get-ManifestHashesMap {
    param($FilesNode)
    $map = @{}
    if ($FilesNode -is [hashtable]) {
        foreach ($k in $FilesNode.Keys) { $map[[string]$k] = [string]$FilesNode[$k] }
        return $map
    }

    if ($FilesNode -and $FilesNode.PSObject -and $FilesNode.PSObject.Properties) {
        foreach ($p in $FilesNode.PSObject.Properties) {
            $map[[string]$p.Name] = [string]$p.Value
        }
    }
    return $map
}

function Get-NormalizedToolSha256 {
    param([Parameter(Mandatory)][string]$Path)
    $text = Get-Content -Raw -LiteralPath $Path -Encoding UTF8
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

foreach ($path in @($LauncherPath, $ManifestPath, $ToolHashesPath, $ToolsDir)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "No existe ruta requerida: $path"
    }
}

# 1) launcher AST parse
$launcherErrs = Get-AstParseErrors -Path $LauncherPath
if ($launcherErrs.Count -gt 0) {
    Write-CheckFail "launcher.ps1 tiene $($launcherErrs.Count) errores de parse."
    foreach ($e in ($launcherErrs | Select-Object -First 10)) {
        Write-Host ("       line {0} col {1}: {2}" -f $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message) -ForegroundColor DarkRed
    }
} else {
    Write-CheckOk "launcher.ps1 parsea correctamente (AST)."
}

# 2) cargar manifest + hashes
try {
    $manifestObj = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    $tools = @($manifestObj.tools)
} catch {
    throw "No se pudo parsear tools.json: $_"
}

try {
    $hashObj = Get-Content -LiteralPath $ToolHashesPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    $hashMap = Get-ManifestHashesMap -FilesNode $hashObj.files
} catch {
    throw "No se pudo parsear tool-hashes.json: $_"
}

if ($tools.Count -eq 0) {
    Write-CheckFail "tools.json no contiene tools."
} else {
    Write-CheckOk "tools.json contiene $($tools.Count) tools."
}

if ($hashMap.Count -eq 0) {
    Write-CheckFail "tool-hashes.json no contiene hashes."
} else {
    Write-CheckOk "tool-hashes.json contiene $($hashMap.Count) hashes."
}

# 3) duplicados en manifest
$dupIds = $tools | Group-Object -Property id | Where-Object { $_.Name -and $_.Count -gt 1 }
foreach ($g in $dupIds) {
    Write-CheckFail "ID duplicado en manifest: '$($g.Name)' (x$($g.Count))."
}
if (-not $dupIds) { Write-CheckOk "No hay IDs duplicados en manifest." }

$dupSources = $tools | Group-Object -Property source | Where-Object { $_.Name -and $_.Count -gt 1 }
foreach ($g in $dupSources) {
    Write-CheckFail "source duplicado en manifest: '$($g.Name)' (x$($g.Count))."
}
if (-not $dupSources) { Write-CheckOk "No hay source duplicados en manifest." }

$dupFunctions = $tools | Group-Object -Property function | Where-Object { $_.Name -and $_.Count -gt 1 }
foreach ($g in $dupFunctions) {
    Write-CheckFail "function duplicada en manifest: '$($g.Name)' (x$($g.Count))."
}
if (-not $dupFunctions) { Write-CheckOk "No hay function duplicadas en manifest." }

# 4) validar cada tool del manifest
$manifestSourcesSet = @{}
$manifestFunctionsSet = @{}
foreach ($tool in $tools) {
    $id = [string]$tool.id
    $source = [string]$tool.source
    $function = [string]$tool.function

    if (-not $id) { Write-CheckFail "Tool sin id detectada."; continue }
    if (-not $source) { Write-CheckFail "Tool '$id' no tiene source."; continue }
    if (-not $function) { Write-CheckFail "Tool '$id' no tiene function."; continue }

    $manifestSourcesSet[$source] = $true
    $manifestFunctionsSet[$function] = $true

    if ($source -notmatch '^Invoke-[A-Za-z0-9_-]+\.ps1$') {
        Write-CheckFail "Tool '$id': source invalido '$source'."
    }

    $expectedFn = [System.IO.Path]::GetFileNameWithoutExtension($source)
    if ($function -ne $expectedFn) {
        Write-CheckFail "Tool '$id': function '$function' no coincide con source '$source'."
    }

    $toolPath = Join-Path $ToolsDir $source
    if (-not (Test-Path -LiteralPath $toolPath)) {
        Write-CheckFail "Tool '$id': no existe archivo '$toolPath'."
        continue
    }

    $toolErrs = Get-AstParseErrors -Path $toolPath
    if ($toolErrs.Count -gt 0) {
        Write-CheckFail "Tool '$id': '$source' tiene $($toolErrs.Count) errores de parse."
        foreach ($e in ($toolErrs | Select-Object -First 3)) {
            Write-Host ("       line {0} col {1}: {2}" -f $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message) -ForegroundColor DarkRed
        }
        continue
    }

    $astErr = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($toolPath, [ref]$null, [ref]$astErr)
    $fnNode = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq $function
        }, $false) | Select-Object -First 1
    if (-not $fnNode) {
        Write-CheckFail "Tool '$id': no se encontro funcion '$function' dentro de '$source'."
    }

    if (-not $hashMap.ContainsKey($source)) {
        Write-CheckFail "Tool '$id': falta hash en tool-hashes.json para '$source'."
        continue
    }

    $hash = [string]$hashMap[$source]
    if ($hash -notmatch '^[a-f0-9]{64}$') {
        Write-CheckFail "Tool '$id': hash invalido para '$source'."
        continue
    }

    $actualHash = Get-NormalizedToolSha256 -Path $toolPath
    if ($actualHash -ne $hash.ToLowerInvariant()) {
        Write-CheckFail "Tool '$id': hash desactualizado para '$source'. Esperado=$hash Actual=$actualHash"
    }
}

# 5) hashes huerfanos
foreach ($hashSource in $hashMap.Keys) {
    if (-not $manifestSourcesSet.ContainsKey([string]$hashSource)) {
        Write-CheckFail "Hash huerfano sin tool en manifest: '$hashSource'."
    }
    $path = Join-Path $ToolsDir $hashSource
    if (-not (Test-Path -LiteralPath $path)) {
        Write-CheckFail "Hash apunta a archivo inexistente: '$hashSource'."
    }
}

# 6) scripts Invoke-* en disco no registrados en manifest
$allInvokeFiles = Get-ChildItem -LiteralPath $ToolsDir -Filter 'Invoke-*.ps1' -File -ErrorAction Stop
foreach ($file in $allInvokeFiles) {
    if (-not $manifestSourcesSet.ContainsKey($file.Name)) {
        Write-CheckFail "Archivo Invoke-* no registrado en tools.json: '$($file.Name)'."
    }
    $errs = Get-AstParseErrors -Path $file.FullName
    if ($errs.Count -gt 0) {
        Write-CheckFail "Archivo '$($file.Name)' con errores de parse ($($errs.Count))."
    }
}

Write-Host ""
if ($script:FailCount -gt 0) {
    Write-Host "=== RESULTADO: $($script:FailCount) fallo(s) ===" -ForegroundColor Red
    exit 1
}

Write-Host "=== RESULTADO: TODO OK ===" -ForegroundColor Green
exit 0
