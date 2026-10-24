# ============================================================
# Atlas PC Support - Tool runner
# Ejecuta una herramienta en una nueva ventana de PowerShell.
#
# Distribution uses only the verified release directory. No mutable cache or
# hot hash refresh. Explicit development mode permits a source checkout.
# Child wrappers include the declared runtime context and all shared libraries.

if (-not $script:AtlasToolHashes) { $script:AtlasToolHashes = @{} }

function Get-AtlasSecureRunDir {
    [CmdletBinding()]
    param()

    if ($script:AtlasSecureRunDir -and (Test-Path -LiteralPath $script:AtlasSecureRunDir)) {
        return $script:AtlasSecureRunDir
    }

    $dir = Initialize-AtlasSecureDirectory -Path '%LOCALAPPDATA%\AtlasPC\secure-run'
    if (-not $dir) {
        $dir = Expand-AtlasPath '%LOCALAPPDATA%\AtlasPC\secure-run'
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    $script:AtlasSecureRunDir = $dir
    return $script:AtlasSecureRunDir
}

function Get-AtlasSHA256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    try {
        # Tool scripts are text. Hash in canonical UTF-8 + LF form so checks are
        # stable across CRLF/LF differences between local checkout and GitHub raw.
        $text = Get-Content -Raw -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        $normalized = ($text -replace "`r`n", "`n") -replace "`r", "`n"
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($normalized)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $sha.ComputeHash($bytes)
            return ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
        } finally {
            $sha.Dispose()
        }
    } catch {
        Write-AtlasLog "No se pudo calcular SHA256 de '$Path': $_" -Level WARN -Tool 'Runner'
        return $null
    }
}

function Get-AtlasToolExpectedHash {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FileName)

    if (-not $script:AtlasToolHashes) { return $null }
    if ($script:AtlasToolHashes -is [hashtable]) {
        if ($script:AtlasToolHashes.ContainsKey($FileName)) {
            return [string]$script:AtlasToolHashes[$FileName]
        }
        return $null
    }

    try {
        $prop = $script:AtlasToolHashes.PSObject.Properties[$FileName]
        if ($prop) { return [string]$prop.Value }
    } catch {}

    return $null
}

function Test-AtlasToolFileIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$FileName,
        [string]$SourceLabel = 'unknown'
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }

    try {
        $fi = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($fi.Length -lt 128) {
            Write-AtlasLog "Archivo tool demasiado corto (sospechoso): $Path" -Level ERROR -Tool 'Runner'
            return $false
        }
    } catch {
        Write-AtlasLog "No se pudo inspeccionar archivo tool '$Path': $_" -Level ERROR -Tool 'Runner'
        return $false
    }

    $expected = Get-AtlasToolExpectedHash -FileName $FileName
    if (-not $expected) {
        if ($SourceLabel -eq 'local-src') {
            Write-AtlasLog "Sin hash esperado para '$FileName' en local-src; permitido solo para desarrollo." -Level WARN -Tool 'Runner'
            return $true
        }
        Write-AtlasLog "Sin hash esperado para '$FileName' (origen=$SourceLabel). Bloqueado por politica fail-closed." -Level ERROR -Tool 'Runner'
        return $false
    }

    $actual = Get-AtlasSHA256 -Path $Path
    if (-not $actual) { return $false }
    if ($actual -ne $expected.ToLowerInvariant()) {
        Write-AtlasLog "Hash invalido para '$FileName' (origen=$SourceLabel). Esperado=$expected Actual=$actual" -Level ERROR -Tool 'Runner'
        return $false
    }

    return $true
}

function Invoke-AtlasRunnerTempCleanup {
    [CmdletBinding()]
    param(
        [string]$TempDir,
        [int]$MaxAgeHours = 24
    )

    if (-not $TempDir) { $TempDir = Get-AtlasSecureRunDir }
    if (-not (Test-Path -LiteralPath $TempDir)) { return }

    $cutoff = (Get-Date).AddHours(-1 * [math]::Abs($MaxAgeHours))
    try {
        Get-ChildItem -LiteralPath $TempDir -File -ErrorAction SilentlyContinue |
            Where-Object {
                ($_.Name -like 'run-*.ps1' -or $_.Name -like 'run-*.cmd' -or $_.Name -like 'atlas-tool-hashes-*.json') -and
                $_.LastWriteTime -lt $cutoff
            } |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    } catch {
        Write-AtlasLog "Limpieza de temporales fallo: $_" -Level WARN -Tool 'Runner'
    }
}

function Get-AtlasToolScript {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FunctionName)
    if ($FunctionName -cnotmatch '^Invoke-[A-Za-z0-9-]+$') { throw 'Invalid tool function name.' }
    if (-not $script:AtlasRoot) { throw 'Atlas release directory is not configured.' }
    $fileName = "$FunctionName.ps1"
    $path = Join-Path $script:AtlasRoot "src/tools/$fileName"
    $label = if ($script:AtlasDevelopmentMode) { 'local-src' } else { 'release' }
    if (-not $script:AtlasDevelopmentMode -and (-not $script:AtlasReleaseCommit -or -not $script:AtlasManifestSha256)) {
        throw 'An approved release context is required. Reopen Atlas from the published link.'
    }
    if (Test-AtlasToolFileIntegrity -Path $path -FileName $fileName -SourceLabel $label) { return $path }
    throw "Tool $fileName is absent or corrupt in this release. Restore the previous release or reinstall the complete bundle."
}

function Get-AtlasToolRuntime {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Tool)
    if (-not $Tool.runtime -or $Tool.runtime.architecture -ne 'x64' -or -not $Tool.runtime.minimumVersion -or @($Tool.runtime.libraries).Count -eq 0) { throw 'A supported x64 runtime contract is required.' }
    foreach ($library in @($Tool.runtime.libraries)) {
        if ($library -notin @('ToolKit','Dependencies','PS7','Release')) { throw "Unknown child library: $library" }
    }
    if ($Tool.runtime.engine -eq 'windows-powershell') {
        if ([version]$Tool.runtime.minimumVersion -gt [version]'5.1') { throw 'This contract requires a newer Windows PowerShell.' }
        $relative = if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { 'Sysnative' } else { 'System32' }
        $path = Join-Path $env:SystemRoot "$relative/WindowsPowerShell/v1.0/powershell.exe"
        if (-not [Environment]::Is64BitOperatingSystem -or -not (Test-Path -LiteralPath $path)) { throw 'Windows PowerShell 5.1 x64 is unavailable.' }
        return $path
    }
    if ($Tool.runtime.engine -eq 'pwsh') {
        $path = $script:AtlasPS7CachedPath
        if (-not $path -or -not (Test-Path -LiteralPath $path)) { throw 'The declared PowerShell 7 runtime is unavailable.' }
        $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($path)
        if ($info.ProductVersion -notmatch '^(\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]$Tool.runtime.minimumVersion) { throw 'The detected PowerShell 7 version does not satisfy this tool.' }
        $stream = [IO.File]::OpenRead($path)
        $reader = [IO.BinaryReader]::new($stream)
        try {
            $stream.Position = 0x3c
            $stream.Position = $reader.ReadInt32() + 4
            if ($reader.ReadUInt16() -ne 0x8664) { throw 'The declared runtime requires an x64 executable.' }
        } finally { $reader.Dispose() }
        return $path
    }
    throw 'Unknown runtime engine; no silent fallback is permitted.'
}

function Invoke-AtlasTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Tool,
        [hashtable]$Branding
    )

    Invoke-AtlasRunnerTempCleanup
    Write-AtlasLog "Ejecutando: $($Tool.name) [$($Tool.id)]" -Tool 'Runner'

    $function = $Tool.function

    $runInNew = $true
    if ($Tool.ContainsKey('runsInNewWindow')) {
        $runInNew = [bool]$Tool.runsInNewWindow
    }

    if (-not $runInNew) {
        # Inline (sin nueva ventana): cargar el script en el scope actual y llamar la funcion.
        $toolPath = Get-AtlasToolScript -FunctionName $function
        if (-not $toolPath) {
            $msg = "No se pudo obtener la tool '$function'."
            [System.Windows.MessageBox]::Show($msg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
            return
        }
        try {
            . $toolPath
            & $function
        } catch {
            Write-AtlasLog "Error en ${function}: $_" -Level ERROR -Tool 'Runner'
            [System.Windows.MessageBox]::Show("Error: $_", 'Atlas PC Support', 'OK', 'Error') | Out-Null
        }
        return
    }

    # ----------- Obtener ruta del script de la tool -----------
    $toolScriptPath = Get-AtlasToolScript -FunctionName $function
    if (-not $toolScriptPath) {
        $msg = "No se pudo obtener la tool '$($Tool.name)'. Verifica conexion o integridad."
        Write-AtlasLog $msg -Level ERROR -Tool 'Runner'
        [System.Windows.MessageBox]::Show($msg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
        return
    }

    $toolSource = [IO.File]::ReadAllText($toolScriptPath, [Text.Encoding]::UTF8)
    $expected = Get-AtlasToolExpectedHash -FileName "$function.ps1"
    if (-not $script:AtlasDevelopmentMode -and (Get-AtlasTextHash $toolSource) -cne $expected) { throw 'Tool changed before wrapper creation.' }
    $psExe = Get-AtlasToolRuntime -Tool $Tool
    if (-not $script:AtlasChildLibrarySource) { throw 'Required child libraries are unavailable. Reopen the complete Atlas release.' }

    $brandName = if ($Branding -and $Branding.brand -and $Branding.brand.shortName) { $Branding.brand.shortName } else { 'Atlas PC Support' }
    $title = "$brandName - $($Tool.name)"

    # ----------- Script temporal que llama a la tool -----------
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Atlas PC Support - runner temp script')
    [void]$sb.AppendLine('$ErrorActionPreference = ''Stop''')
    [void]$sb.AppendLine('try { $Host.UI.RawUI.WindowTitle = ' + ("'{0}'" -f ($title -replace "'","''")) + ' } catch {}')
    [void]$sb.AppendLine('')
    # All child libraries come from the already verified launcher, without downloads.
    # Missing helpers must stop the tool, not downgrade the validation policy.
    # The shared source begins with the native runtime header, before JSON autoload.
    [void]$sb.AppendLine($script:AtlasChildLibrarySource)
    $context = @{
        AtlasVersion = $script:AtlasVersion
        AtlasRoot = $script:AtlasRoot
        AtlasReleaseCommit = $script:AtlasReleaseCommit
        AtlasManifestSha256 = $script:AtlasManifestSha256
        AtlasDevelopmentMode = [bool]$script:AtlasDevelopmentMode
        AtlasOfflineRoot = $env:ATLAS_OFFLINE_ROOT
    } | ConvertTo-Json -Compress
    [void]$sb.AppendLine("`$atlasContext = '" + $context.Replace("'", "''") + "' | ConvertFrom-Json")
    [void]$sb.AppendLine('foreach ($entry in $atlasContext.PSObject.Properties) { Set-Variable -Name $entry.Name -Value $entry.Value -Scope Script }')
    [void]$sb.AppendLine('$env:ATLAS_OFFLINE_ROOT = $script:AtlasOfflineRoot')
    [void]$sb.AppendLine($toolSource)
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('$atlasToolExitCode = 0')
    [void]$sb.AppendLine('try {')
    [void]$sb.AppendLine("    $function")
    [void]$sb.AppendLine('} catch {')
    [void]$sb.AppendLine('    $atlasToolExitCode = 1')
    [void]$sb.AppendLine('    Write-Host ""')
    [void]$sb.AppendLine("    Write-Host ('[!] Error en $function : ' + `$_.Exception.Message) -ForegroundColor Red")
    [void]$sb.AppendLine('    Write-Host ""')
    [void]$sb.AppendLine('    Write-Host "Traza:" -ForegroundColor DarkGray')
    [void]$sb.AppendLine('    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray')
    [void]$sb.AppendLine('} finally {')
    [void]$sb.AppendLine('    Write-Host ""')
    [void]$sb.AppendLine('    Write-Host "============================================"')
    [void]$sb.AppendLine('    Write-Host "  Tool finalizada. Presiona ENTER para cerrar."')
    [void]$sb.AppendLine('    Write-Host "============================================"')
    [void]$sb.AppendLine('    [void](Read-Host)')
    [void]$sb.AppendLine('    try { Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue } catch {}')
    [void]$sb.AppendLine('}')
    [void]$sb.AppendLine('exit $atlasToolExitCode')

    $tempDir = Get-AtlasSecureRunDir
    if (-not (Test-Path -LiteralPath $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    $stamp       = "$($Tool.id)-$(Get-Random)"
    $tempScript  = Join-Path $tempDir "run-$stamp.ps1"

    $utf8WithBom = [System.Text.UTF8Encoding]::new($true)
    [System.IO.File]::WriteAllText($tempScript, $sb.ToString(), $utf8WithBom)

    # Validate wrapper parse before launch to avoid "nothing happens" failures.
    try {
        $parseErrors = $null
        $parseTokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile($tempScript, [ref]$parseTokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors -and $parseErrors.Count -gt 0) {
            $first = $parseErrors[0]
            $line = if ($first.Extent -and $first.Extent.StartLineNumber) { $first.Extent.StartLineNumber } else { '?' }
            $msg = "Wrapper invalido para '$($Tool.name)' (linea $line): $($first.Message)"
            Write-AtlasLog $msg -Level ERROR -Tool 'Runner'
            [System.Windows.MessageBox]::Show($msg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
            return
        }
    } catch {
        Write-AtlasLog "No se pudo validar parser del wrapper temporal: $_" -Level WARN -Tool 'Runner'
    }

    $psArgs = @(
        '-NoLogo',
        '-NoProfile',
        '-Sta',
        '-ExecutionPolicy', 'RemoteSigned',
        '-File', ('"{0}"' -f $tempScript)
    )

    $startArgs = @{
        FilePath         = $psExe
        ArgumentList     = $psArgs
        WorkingDirectory = (Split-Path -Parent $toolScriptPath)
    }
    if ($Tool.requiresAdmin -and -not (Test-IsAdmin)) {
        $startArgs.Verb = 'RunAs'
    }

    try {
        Start-Process @startArgs | Out-Null
    } catch {
        $errMsg = "No se pudo lanzar la tool '$($Tool.name)': $($_.Exception.Message)"
        Write-AtlasLog $errMsg -Level ERROR -Tool 'Runner'
        [System.Windows.MessageBox]::Show($errMsg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
        Remove-Item -LiteralPath $tempScript -Force -ErrorAction SilentlyContinue
    }
}
