# ============================================================
# Atlas PC Support - Auto-elevation
# Sustituye a los .bat de cada tool.
# ============================================================

function Test-IsAdmin {
    [CmdletBinding()]
    param()
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SelfElevate {
    [CmdletBinding()]
    param(
        [string]$ScriptPath = $PSCommandPath
    )
    if (Test-IsAdmin) { return $true }

    if (-not $ScriptPath) {
        Write-Warning "No se puede auto-elevar: no hay ruta de script."
        return $false
    }

    try {
        Unblock-File -LiteralPath $ScriptPath -ErrorAction SilentlyContinue
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "RemoteSigned", "-File", "`"$ScriptPath`"") `
            -Verb RunAs | Out-Null
        exit 0
    } catch {
        Write-Warning "No se pudo elevar: $_"
        return $false
    }
}

function Invoke-AsAdmin {
    <#
    .SYNOPSIS
    Ejecuta un bloque de código en una nueva ventana de PowerShell elevada.
    .PARAMETER ScriptBlock
    Bloque de código a ejecutar.
    .PARAMETER Title
    Título de la ventana.
    .PARAMETER Wait
    Esperar a que termine antes de volver.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock,
        [string]$Title = "Atlas PC Support",
        [switch]$Wait
    )

    # Write the block to a per-user secure directory and run with -File instead
    # of -EncodedCommand. -EncodedCommand triggers AV heuristics on many endpoints.
    $secureRunDir = Initialize-AtlasSecureDirectory -Path '%LOCALAPPDATA%\AtlasPC\secure-run'
    if (-not $secureRunDir) {
        $secureRunDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\secure-run'
        if (-not (Test-Path -LiteralPath $secureRunDir)) {
            New-Item -ItemType Directory -Path $secureRunDir -Force | Out-Null
        }
    }
    $tmp = Join-Path $secureRunDir ("atlas-admin-" + [guid]::NewGuid().ToString('N').Substring(0,8) + ".ps1")
    try {
        $payload = @(
            '$ErrorActionPreference = ''Continue'''
            $ScriptBlock.ToString()
            'try { Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue } catch {}'
        ) -join [Environment]::NewLine
        [System.IO.File]::WriteAllText($tmp, $payload, [System.Text.UTF8Encoding]::new($true))
    } catch {
        Write-Warning "No se pudo escribir script temporal: $_"
        return $false
    }

    $psArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "RemoteSigned",
        "-File", $tmp
    )

    $startArgs = @{
        FilePath     = "powershell.exe"
        ArgumentList = $psArgs
        Verb         = "RunAs"
    }
    if ($Wait) { $startArgs.Wait = $true }

    try {
        Start-Process @startArgs | Out-Null
        # Cleanup is best-effort; the elevated process may still be running if -Wait was not set.
        if ($Wait) { Remove-Item $tmp -ErrorAction SilentlyContinue }
        return $true
    } catch {
        Remove-Item $tmp -ErrorAction SilentlyContinue
        Write-Warning "No se pudo lanzar ventana elevada: $_"
        return $false
    }
}
