# ============================================================
# Atlas PC Support - PowerShell 7 detection & install
#
# Proposito:
#   El panel soporta PS 5.1 (Windows de fabrica), pero las tools
#   sufren bugs de encoding, enums y parametros limitados de 5.1.
#   ToolRunner usa el runtime declarado por cada herramienta.
#   Detectar PS 7 no cambia silenciosamente ese contrato.
#
# Modo offline (USB):
#   Install-AtlasPS7 -OfflineSource "$PSScriptRoot\deps\PowerShell-*.msi"
#   Preparar USB copia el MSI en deps\ para instalacion sin internet.
# ============================================================

$ps7Definition = Get-AtlasDependencyDefinition -Name 'PowerShell7'
$script:AtlasPS7Version = $ps7Definition.Version
$script:AtlasPS7UrlX64 = $ps7Definition.DownloadUrl
$script:AtlasPS7MsiName = $ps7Definition.MsiName
$script:AtlasPS7HashesUrl = $ps7Definition.HashesUrl

function Get-AtlasPS7Path {
    <#
    .SYNOPSIS
      Devuelve la ruta completa a pwsh.exe si PS 7+ esta instalado, si no $null.
    #>
    [CmdletBinding()]
    param()

    # 1) PATH
    $cmd = Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd -and $cmd.Path) { return $cmd.Path }

    # 2) Ruta por defecto de instalacion MSI (64-bit y 32-bit)
    $candidates = @(
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
        "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
    }

    return $null
}

function Find-AtlasPS7OfflineMsi {
    <#
    .SYNOPSIS
      Busca un MSI de PS 7 en carpetas locales conocidas (USB offline).
    #>
    [CmdletBinding()]
    param()

    $searchDirs = @()
    # USB offline root set by run-launcher.ps1 (highest priority — covers USB scenario)
    if ($env:ATLAS_OFFLINE_ROOT) {
        $searchDirs += (Join-Path $env:ATLAS_OFFLINE_ROOT 'deps')
    }
    # USB: si el launcher.ps1 esta en E:\ATLAS_PC_SUPPORT\, mirar deps\
    if ($script:AtlasRoot) {
        $searchDirs += (Join-Path $script:AtlasRoot 'deps')
    }
    # LOCALAPPDATA cache (Preparar USB guarda tambien alli)
    $searchDirs += (Join-Path $env:LOCALAPPDATA 'AtlasPC\deps')

    foreach ($dir in $searchDirs) {
        if (Test-Path -LiteralPath $dir) {
            $msi = Get-ChildItem -Path $dir -Filter $script:AtlasPS7MsiName -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending | Select-Object -First 1
            if ($msi) { return $msi.FullName }
        }
    }
    return $null
}

function Get-AtlasPS7ExpectedHash {
    <#
    .SYNOPSIS
      Reads the independently pinned x64 MSI digest from the verified release.
    #>
    [CmdletBinding()]
    param()

    $hash = (Get-AtlasDependencyDefinition -Name PowerShell7).DownloadSha256
    if ($hash -cnotmatch '^[a-f0-9]{64}$') { throw 'Missing pinned PowerShell SHA-256.' }
    return $hash
}

function Test-AtlasFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedHash
    )

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    return ($actual -eq $ExpectedHash.ToLowerInvariant())
}

function Install-AtlasPS7 {
    <#
    .SYNOPSIS
      Instala PowerShell 7 usando msiexec silencioso.
      Intenta primero MSI local (offline), si no descarga de GitHub.

    .PARAMETER OfflineSource
      Ruta a un MSI ya descargado. Si se omite, se busca automaticamente
      y si no se encuentra se descarga.
    #>
    [CmdletBinding()]
    param(
        [string]$OfflineSource
    )

    $msi = $null
    $expectedHash = Get-AtlasPS7ExpectedHash
    $existing=Get-AtlasPS7Path
    if($existing -and (Get-AtlasPowerShellVersion -Path $existing) -gt [version]$script:AtlasPS7Version){throw 'Refusing to replace a newer PowerShell with the pinned older MSI.'}
    $downloadedFromWeb = $false

    if ($OfflineSource -and (Test-Path -LiteralPath $OfflineSource)) {
        $msi = (Resolve-Path -LiteralPath $OfflineSource).Path
        Write-Host "  [>] Usando MSI local: $msi" -ForegroundColor Cyan
    } else {
        $found = Find-AtlasPS7OfflineMsi
        if ($found) {
            $msi = $found
            Write-Host "  [>] MSI local encontrado: $msi" -ForegroundColor Cyan
        }
    }

    if (-not $msi) {
        # Descargar
        $cacheDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\deps'
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        $msi = Join-Path $cacheDir $script:AtlasPS7MsiName
        Write-Host "  [>] Descargando PowerShell $($script:AtlasPS7Version) (~120 MB)..." -ForegroundColor Cyan
        try {
            $expectedHash = Get-AtlasPS7ExpectedHash
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $script:AtlasPS7UrlX64 -OutFile $msi -UseBasicParsing -TimeoutSec 900 -ErrorAction Stop
            $downloadedFromWeb = $true
        } catch {
            throw "Fallo descarga de PS 7: $($_.Exception.Message)"
        }
    }

    # The release pin is authoritative. A USB sidecar cannot replace it.
    if ($expectedHash) {
        Write-Host "  [>] Verificando integridad SHA-256 del MSI..." -ForegroundColor Cyan
        if (-not (Test-AtlasFileHash -Path $msi -ExpectedHash $expectedHash)) {
            if ($downloadedFromWeb) {
                Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
            }
            throw "La verificacion SHA-256 del MSI de PowerShell 7 fallo."
        }
        Write-Host "  [OK] Integridad verificada." -ForegroundColor Green
    } else {
        throw 'No se pudo validar SHA-256 del MSI. Se requiere su archivo .sha256 para instalar sin conexion.'
    }
    Assert-AtlasInstaller -Path $msi -ExpectedSha256 $expectedHash -MicrosoftSignature

    # Instalar silencioso con feature completa
    $msiArgs = @(
        '/i', "`"$msi`"",
        '/qn', '/norestart',
        'ADD_PATH=1',
        'ENABLE_PSREMOTING=0',
        'REGISTER_MANIFEST=1'
    )
    Write-Host "  [>] Instalando MSI (msiexec silencioso)..." -ForegroundColor Cyan
    $p = Invoke-AtlasNativeProcess -FilePath 'msiexec.exe' -Arguments ($msiArgs -join ' ') -TimeoutSeconds 1800 -SuccessCodes @(0,3010)
    if ($p.State -ne 'Correct') { throw "msiexec: $($p.State), exit $($p.ExitCode). Inspect installation state before retrying." }
    if ($p.ExitCode -eq 3010) { Write-Warning 'PowerShell installation requires a Windows restart.' }

    $path = Get-AtlasPS7Path
    if (-not $path) {
        throw "Instalacion reportada OK pero pwsh.exe no se encuentra en las rutas esperadas."
    }
    if((Get-AtlasPowerShellVersion -Path $path) -lt [version]$script:AtlasPS7Version){throw 'Requested PowerShell version is not yet verified; check installer log/restart before retrying.'}
    Write-Host "  [OK] PowerShell 7 instalado: $path" -ForegroundColor Green
    return $path
}

# Cache de la ruta resuelta (lo rellena el launcher al arrancar).
$script:AtlasPS7CachedPath = $null

function Initialize-AtlasPS7 {
    <#
    .SYNOPSIS
      Llamado por el launcher al arrancar para cachear la ruta a pwsh.exe.
      ToolRunner lee $script:AtlasPS7CachedPath para decidir si usa pwsh o powershell.
    #>
    $script:AtlasPS7CachedPath = Get-AtlasPS7Path
    return $script:AtlasPS7CachedPath
}
