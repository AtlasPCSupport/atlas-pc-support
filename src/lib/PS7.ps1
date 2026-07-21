# ============================================================
# Atlas PC Support - PowerShell 7 detection & install
#
# Proposito:
#   El panel soporta PS 5.1 (Windows de fabrica), pero las tools
#   sufren bugs de encoding, enums y parametros limitados de 5.1.
#   Cuando PS 7 esta presente, ToolRunner lo usa automaticamente
#   y todas las tools corren en el runtime moderno.
#
# Modo offline (USB):
#   Install-AtlasPS7 -OfflineSource "$PSScriptRoot\deps\PowerShell-*.msi"
#   Preparar USB copia el MSI en deps\ para instalacion sin internet.
# ============================================================

# Versiones conocidas de PS 7 (actualizar cuando salga nueva LTS).
$script:AtlasPS7Version  = '7.5.0'
$script:AtlasPS7UrlX64   = "https://github.com/PowerShell/PowerShell/releases/download/v$($script:AtlasPS7Version)/PowerShell-$($script:AtlasPS7Version)-win-x64.msi"
$script:AtlasPS7MsiName  = "PowerShell-$($script:AtlasPS7Version)-win-x64.msi"
$script:AtlasPS7HashesUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$($script:AtlasPS7Version)/hashes.sha256"

function Get-AtlasPS7Path {
    <#
    .SYNOPSIS
      Devuelve la ruta completa a pwsh.exe si PS 7+ esta instalado, si no $null.
    #>
    [CmdletBinding()]
    param()

    # 1) PATH
    $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
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
            $msi = Get-ChildItem -Path $dir -Filter 'PowerShell-*-win-x64.msi' -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending | Select-Object -First 1
            if ($msi) { return $msi.FullName }
        }
    }
    return $null
}

function Get-AtlasPS7ExpectedHash {
    <#
    .SYNOPSIS
      Descarga el archivo oficial hashes.sha256 y extrae el hash del MSI x64.
    #>
    [CmdletBinding()]
    param()

    try {
        $ProgressPreference = 'SilentlyContinue'
        $raw = (Invoke-WebRequest -Uri $script:AtlasPS7HashesUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop).Content
    } catch {
        throw "No se pudo descargar hashes.sha256 oficial: $($_.Exception.Message)"
    }

    $line = ($raw -split "`r?`n" | Where-Object { $_ -match [regex]::Escape($script:AtlasPS7MsiName) } | Select-Object -First 1)
    if (-not $line) {
        throw "No se encontro hash para $($script:AtlasPS7MsiName) en hashes.sha256."
    }

    $hash = (($line -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
    if ($hash -notmatch '^[a-f0-9]{64}$') {
        throw "Formato de hash invalido en hashes.sha256."
    }
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
    $expectedHash = $null
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
            Invoke-WebRequest -Uri $script:AtlasPS7UrlX64 -OutFile $msi -UseBasicParsing
            $downloadedFromWeb = $true
        } catch {
            throw "Fallo descarga de PS 7: $($_.Exception.Message)"
        }
    }

    # Validar integridad del MSI.
    if (-not $expectedHash) {
        $sidecar = "$msi.sha256"
        if (Test-Path -LiteralPath $sidecar) {
            try {
                $raw = Get-Content -LiteralPath $sidecar -Raw -Encoding UTF8 -ErrorAction Stop
                $parsed = (($raw -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
                if ($parsed -match '^[a-f0-9]{64}$') {
                    $expectedHash = $parsed
                }
            } catch {}
        }
    }

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
        Write-Host "  [!] No se pudo validar hash del MSI (sin sidecar/local hash)." -ForegroundColor Yellow
    }

    # Instalar silencioso con feature completa
    $msiArgs = @(
        '/i', "`"$msi`"",
        '/qn', '/norestart',
        'ADD_PATH=1',
        'ENABLE_PSREMOTING=0',
        'REGISTER_MANIFEST=1'
    )
    Write-Host "  [>] Instalando MSI (msiexec silencioso)..." -ForegroundColor Cyan
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
        throw "msiexec salio con codigo $($p.ExitCode)"
    }

    $path = Get-AtlasPS7Path
    if (-not $path) {
        throw "Instalacion reportada OK pero pwsh.exe no se encuentra en las rutas esperadas."
    }
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
