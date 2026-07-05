# ============================================================
# Atlas PC Support - Tool runner
# Ejecuta una herramienta en una nueva ventana de PowerShell.
#
# Orden de origen:
#   0. Source local (dev checkout): src\tools\ si existe junto al repo
#   1. USB offline: deps\tools\ junto al launcher
#   2. Cache local: %LOCALAPPDATA%\AtlasPC\tools\
#   3. Descarga remota: $script:AtlasToolsBaseUrl
#
# Seguridad:
#   - Valida SHA-256 de cada tool contra $script:AtlasToolHashes.
#   - Fail-closed para usb/cache/download cuando no hay hash esperado.
#   - Fail-open solo para local-src (modo desarrollo).
#   - Descargas se escriben primero a .download y luego se mueven atomicamente.
#   - Nunca usa EncodedCommand (reduce heuristicas AV).
#
# Estabilidad:
#   - Limpia wrappers temporales antiguos en %LOCALAPPDATA%\AtlasPC\secure-run.
#   - Cache con refresco por antiguedad para evitar "version congelada".
# ============================================================

if (-not $script:AtlasToolCacheMaxAgeHours) {
    $script:AtlasToolCacheMaxAgeHours = 6
}
if (-not $script:AtlasToolHashes) {
    $script:AtlasToolHashes = @{}
}

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

function Unblock-AtlasFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    try {
        if (Test-Path -LiteralPath $Path) {
            Unblock-File -LiteralPath $Path -ErrorAction SilentlyContinue
        }
    } catch {}
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

function Get-AtlasToolHashesRemoteUrl {
    [CmdletBinding()]
    param()

    if (-not $script:AtlasToolsBaseUrl) { return $null }
    $base = [string]$script:AtlasToolsBaseUrl
    if ([string]::IsNullOrWhiteSpace($base)) { return $null }

    $normalized = $base.TrimEnd('/')
    if ($normalized -match '/src/tools$') {
        return ($normalized -replace '/src/tools$', '/config/tool-hashes.json')
    }
    return $null
}

function Get-AtlasToolHashesDigestUrl {
    [CmdletBinding()]
    param()

    if ($script:AtlasToolHashesDigestUrl) {
        $url = [string]$script:AtlasToolHashesDigestUrl
        if (-not [string]::IsNullOrWhiteSpace($url)) { return $url.Trim() }
    }
    return $null
}

function Get-AtlasExpectedDigestFromRemote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DigestUrl,
        [string]$Label = 'digest'
    )

    try {
        $ProgressPreference = 'SilentlyContinue'
        $raw = (Invoke-WebRequest -Uri ($DigestUrl + '?v=' + [guid]::NewGuid().ToString('N').Substring(0,8)) `
            -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop).Content
        $expected = (($raw -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
        if ($expected -match '^[a-f0-9]{64}$') {
            return $expected
        }
        Write-AtlasLog "Digest remoto invalido para $Label en $DigestUrl" -Level WARN -Tool 'Runner'
        return $null
    } catch {
        Write-AtlasLog "No se pudo obtener digest remoto ($Label): $_" -Level WARN -Tool 'Runner'
        return $null
    }
}

function Refresh-AtlasToolHashesFromRemote {
    [CmdletBinding()]
    param([string]$FileName)

    $hashUrl = Get-AtlasToolHashesRemoteUrl
    if (-not $hashUrl) { return $false }

    $tmpPath = Join-Path (Get-AtlasSecureRunDir) ("atlas-tool-hashes-" + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri ($hashUrl + '?v=' + [guid]::NewGuid().ToString('N').Substring(0,8)) `
            -OutFile $tmpPath -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop

        $digestRequired = $false
        if ($null -ne $script:AtlasToolHashesDigestRequired) {
            $digestRequired = [bool]$script:AtlasToolHashesDigestRequired
        }
        $digestUrl = Get-AtlasToolHashesDigestUrl
        if ($digestUrl) {
            $expectedDigest = Get-AtlasExpectedDigestFromRemote -DigestUrl $digestUrl -Label 'tool-hashes.json'
            if (-not $expectedDigest) {
                if ($digestRequired) {
                    Write-AtlasLog "Digest remoto requerido para tool-hashes pero no disponible." -Level ERROR -Tool 'Runner'
                    return $false
                }
            } else {
                $actualDigest = (Get-FileHash -LiteralPath $tmpPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
                if ($actualDigest -ne $expectedDigest) {
                    Write-AtlasLog "tool-hashes.json rechazado por digest out-of-band. Esperado=$expectedDigest Actual=$actualDigest" -Level ERROR -Tool 'Runner'
                    return $false
                }
                Write-AtlasLog "Digest out-of-band validado para tool-hashes.json." -Level INFO -Tool 'Runner'
            }
        } elseif ($digestRequired) {
            Write-AtlasLog "Digest out-of-band requerido para tool-hashes pero no configurado." -Level ERROR -Tool 'Runner'
            return $false
        }

        $raw = Get-Content -Raw -LiteralPath $tmpPath -Encoding UTF8 -ErrorAction Stop
        $obj = ConvertFrom-AtlasJson $raw
        if (-not $obj -or -not $obj.files) {
            Write-AtlasLog "Refresh hashes: respuesta invalida desde $hashUrl" -Level WARN -Tool 'Runner'
            return $false
        }

        $map = @{}
        if ($obj.files -is [hashtable]) {
            $map = $obj.files
        } else {
            foreach ($p in $obj.files.PSObject.Properties) {
                $map[$p.Name] = [string]$p.Value
            }
        }
        if ($map.Count -le 0) {
            Write-AtlasLog "Refresh hashes: mapa vacio desde $hashUrl" -Level WARN -Tool 'Runner'
            return $false
        }

        $script:AtlasToolHashes = $map
        if ($FileName) {
            $newExpected = Get-AtlasToolExpectedHash -FileName $FileName
            if ($newExpected) {
                Write-AtlasLog "Hashes refrescados en caliente para '$FileName'." -Level INFO -Tool 'Runner'
                return $true
            }
            Write-AtlasLog "Hashes refrescados, pero '$FileName' no existe en el manifiesto remoto." -Level WARN -Tool 'Runner'
            return $false
        }
        Write-AtlasLog "Hashes refrescados en caliente ($($map.Count) entries)." -Level INFO -Tool 'Runner'
        return $true
    } catch {
        Write-AtlasLog "No se pudo refrescar tool-hashes remotos: $_" -Level WARN -Tool 'Runner'
        return $false
    } finally {
        Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
    }
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

    $fileName  = "$FunctionName.ps1"
    $cacheDir  = Join-Path $env:LOCALAPPDATA 'AtlasPC\tools'
    $cachePath = Join-Path $cacheDir $fileName
    $fallbackCachePath = $null

    # 0) Source local (dev checkout) + 1) USB offline: deps\tools\ junto al launcher
    $launcherDir = $null
    if ($script:AtlasRoot -and (Test-Path -LiteralPath $script:AtlasRoot)) {
        $launcherDir = $script:AtlasRoot
    } else {
        $candidates = @($PSCommandPath, $MyInvocation.PSCommandPath, $MyInvocation.ScriptName)
        foreach ($candidate in $candidates) {
            if ($candidate -and (Test-Path -LiteralPath $candidate)) {
                $launcherDir = Split-Path -Parent $candidate
                if ($launcherDir) { break }
            }
        }
    }

    if ($launcherDir) {
        # 0) Source local (dev checkout) - evita mismatch de hash cuando el launcher
        # local apunta a un branch que aun no esta en main remoto.
        $localCandidates = @()
        if ($script:AtlasSrc) {
            $localCandidates += (Join-Path $script:AtlasSrc "tools\$fileName")
        }
        $localCandidates += (Join-Path $launcherDir "src\tools\$fileName")

        $seen = @{}
        foreach ($localPath in $localCandidates) {
            if (-not $localPath) { continue }
            $key = $localPath.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true

            if (Test-Path -LiteralPath $localPath) {
                if (Test-AtlasToolFileIntegrity -Path $localPath -FileName $fileName -SourceLabel 'local-src') {
                    Unblock-AtlasFile -Path $localPath
                    Write-AtlasLog "Tool desde source local: $localPath" -Tool 'Runner'
                    return $localPath
                }
                Write-AtlasLog "Tool local-src descartada por integridad: $localPath" -Level WARN -Tool 'Runner'
            }
        }

        $usbPath = Join-Path $launcherDir "deps\tools\$fileName"
        if (Test-Path -LiteralPath $usbPath) {
            if (Test-AtlasToolFileIntegrity -Path $usbPath -FileName $fileName -SourceLabel 'usb') {
                Unblock-AtlasFile -Path $usbPath
                Write-AtlasLog "Tool desde USB: $usbPath" -Tool 'Runner'
                return $usbPath
            }
            Write-AtlasLog "Tool USB descartada por integridad: $usbPath" -Level WARN -Tool 'Runner'
        }
    }

    # 2) Cache local
    $invalidCachePath = $null
    if (Test-Path -LiteralPath $cachePath) {
        if (Test-AtlasToolFileIntegrity -Path $cachePath -FileName $fileName -SourceLabel 'cache') {
            Unblock-AtlasFile -Path $cachePath
            $ageHours = [math]::Round(((Get-Date) - (Get-Item -LiteralPath $cachePath).LastWriteTime).TotalHours, 2)
            if ($ageHours -lt [double]$script:AtlasToolCacheMaxAgeHours) {
                Write-AtlasLog "Tool desde cache fresca ($ageHours h): $cachePath" -Tool 'Runner'
                return $cachePath
            }
            $fallbackCachePath = $cachePath
            Write-AtlasLog "Tool cache valida pero expirada ($ageHours h); intentare refrescar." -Level INFO -Tool 'Runner'
        } else {
            $invalidCachePath = $cachePath
            Write-AtlasLog "Cache invalida para '$fileName'; se intentara refrescar hashes antes de descartar." -Level WARN -Tool 'Runner'
            if (Refresh-AtlasToolHashesFromRemote -FileName $fileName) {
                if (Test-AtlasToolFileIntegrity -Path $cachePath -FileName $fileName -SourceLabel 'cache-refreshed') {
                    Unblock-AtlasFile -Path $cachePath
                    Write-AtlasLog "Cache recuperada tras refresh de hashes: $cachePath" -Level INFO -Tool 'Runner'
                    return $cachePath
                }
            }
            Write-AtlasLog "Cache sigue invalida para '$fileName'; se forzara descarga." -Level WARN -Tool 'Runner'
            Remove-Item -LiteralPath $cachePath -Force -ErrorAction SilentlyContinue
        }
    }

    # 3) Descarga remota (si hay URL base)
    if (-not $script:AtlasToolsBaseUrl) {
        if ($fallbackCachePath) {
            Write-AtlasLog "Sin AtlasToolsBaseUrl; usando cache expirada como fallback: $fallbackCachePath" -Level WARN -Tool 'Runner'
            return $fallbackCachePath
        }
        Write-AtlasLog "No hay AtlasToolsBaseUrl configurada para '$FunctionName'." -Level ERROR -Tool 'Runner'
        return $null
    }

    $toolsBaseUri = $null
    try { $toolsBaseUri = [Uri]$script:AtlasToolsBaseUrl } catch {}
    if (-not $toolsBaseUri -or -not $toolsBaseUri.IsAbsoluteUri -or $toolsBaseUri.Scheme -ne 'https') {
        Write-AtlasLog "AtlasToolsBaseUrl invalida o insegura (solo HTTPS): '$script:AtlasToolsBaseUrl'." -Level ERROR -Tool 'Runner'
        if ($fallbackCachePath) {
            Write-AtlasLog "Usando cache expirada por URL insegura: $fallbackCachePath" -Level WARN -Tool 'Runner'
            return $fallbackCachePath
        }
        return $null
    }

    Write-AtlasLog "Descargando tool: $FunctionName" -Tool 'Runner'
    try {
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }

        $baseUrl = $script:AtlasToolsBaseUrl.TrimEnd('/')
        $url = "$baseUrl/$fileName"
        $tempDownload = Join-Path $cacheDir ($fileName + '.download')
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri ($url + '?v=' + [guid]::NewGuid().ToString('N').Substring(0,8)) `
            -OutFile $tempDownload -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop

        if (-not (Test-AtlasToolFileIntegrity -Path $tempDownload -FileName $fileName -SourceLabel 'download')) {
            # Si el launcher quedo atrasado respecto a hashes remotos, intentar
            # refrescar hashes en caliente y volver a validar sin perder disponibilidad.
            $validatedAfterRefresh = $false
            if (Refresh-AtlasToolHashesFromRemote -FileName $fileName) {
                if (Test-AtlasToolFileIntegrity -Path $tempDownload -FileName $fileName -SourceLabel 'download-refreshed') {
                    $validatedAfterRefresh = $true
                    Write-AtlasLog "Descarga validada tras refresh de hashes: $fileName" -Level INFO -Tool 'Runner'
                }
            }

            if (-not $validatedAfterRefresh) {
                Remove-Item -LiteralPath $tempDownload -Force -ErrorAction SilentlyContinue
                if ($invalidCachePath -and (Test-Path -LiteralPath $invalidCachePath)) {
                    Write-AtlasLog "Usando cache previa como ultimo fallback para '$fileName'." -Level WARN -Tool 'Runner'
                    return $invalidCachePath
                }
                throw "Descarga rechazada por validacion de integridad."
            }
        }

        Move-Item -LiteralPath $tempDownload -Destination $cachePath -Force
        Unblock-AtlasFile -Path $cachePath
        Write-AtlasLog "Tool descargada y validada: $cachePath" -Tool 'Runner'
        return $cachePath
    } catch {
        Write-AtlasLog "Fallo descarga de '$FunctionName': $_" -Level ERROR -Tool 'Runner'
        if ($fallbackCachePath) {
            Write-AtlasLog "Usando cache expirada como fallback: $fallbackCachePath" -Level WARN -Tool 'Runner'
            return $fallbackCachePath
        }
        return $null
    }
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

    # ----------- Asegurar BOM para PS 5.1 -----------
    try {
        $bytes = [System.IO.File]::ReadAllBytes($toolScriptPath)
        if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
            $bom = [byte[]](0xEF, 0xBB, 0xBF)
            $withBom = New-Object byte[] ($bom.Length + $bytes.Length)
            [System.Buffer]::BlockCopy($bom, 0, $withBom, 0, $bom.Length)
            [System.Buffer]::BlockCopy($bytes, 0, $withBom, $bom.Length, $bytes.Length)
            [System.IO.File]::WriteAllBytes($toolScriptPath, $withBom)
        }
    } catch {
        Write-AtlasLog "BOM check fallo para '$function': $_" -Level WARN -Tool 'Runner'
    }

    $brandName = if ($Branding -and $Branding.brand -and $Branding.brand.shortName) { $Branding.brand.shortName } else { 'Atlas PC Support' }
    $title = "$brandName - $($Tool.name)"

    # ----------- Script temporal que llama a la tool -----------
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Atlas PC Support - runner temp script')
    [void]$sb.AppendLine('$ErrorActionPreference = ''Continue''')
    [void]$sb.AppendLine('try { $Host.UI.RawUI.WindowTitle = ' + ("'{0}'" -f ($title -replace "'","''")) + ' } catch {}')
    [void]$sb.AppendLine('')
    # ---- Inyectar el ToolKit compartido (helpers de UI / reportes) ----
    # Embebido en el launcher (cubierto por launcher.ps1.sha256), por lo que no
    # anade superficie de descarga. Va dentro de try/catch para que un fallo del
    # toolkit NUNCA impida ejecutar la tool. Se define ANTES del tool para que la
    # propia tool pueda sobre-escribir cualquier helper si lo necesita.
    if ($script:AtlasToolKitSource) {
        [void]$sb.AppendLine('# ---- Atlas ToolKit (inyectado por ToolRunner) ----')
        [void]$sb.AppendLine('try {')
        [void]$sb.AppendLine($script:AtlasToolKitSource)
        [void]$sb.AppendLine('} catch { Write-Host ("[Atlas] ToolKit no disponible: " + $_.Exception.Message) -ForegroundColor DarkYellow }')
        [void]$sb.AppendLine('')
    }

    # Dot-source del archivo de la tool (define la funcion)
    $escapedPath = $toolScriptPath -replace "'", "''"
    [void]$sb.AppendLine(". '$escapedPath'")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('try {')
    [void]$sb.AppendLine("    $function")
    [void]$sb.AppendLine('} catch {')
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

    $tempDir = Get-AtlasSecureRunDir
    if (-not (Test-Path -LiteralPath $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    $stamp       = "$($Tool.id)-$(Get-Random)"
    $tempScript  = Join-Path $tempDir "run-$stamp.ps1"

    $utf8WithBom = [System.Text.UTF8Encoding]::new($true)
    [System.IO.File]::WriteAllText($tempScript, $sb.ToString(), $utf8WithBom)
    Unblock-AtlasFile -Path $tempScript

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

    $psExe = 'powershell.exe'
    if ($script:AtlasPS7CachedPath -and (Test-Path -LiteralPath $script:AtlasPS7CachedPath)) {
        $psExe = $script:AtlasPS7CachedPath
    }
    $psArgs = @(
        '-NoLogo',
        '-NoProfile',
        '-Sta',
        '-ExecutionPolicy', 'RemoteSigned',
        '-File', $tempScript
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
