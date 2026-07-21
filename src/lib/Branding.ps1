# ============================================================
# Atlas PC Support - Branding loader
# Carga branding.json del repo o de una ruta personalizada.
# Los revendedores / técnicos editan branding.json para cambiar
# nombre, logo, colores, título de ventana, etc. sin tocar el código.
# ============================================================

# Convierte recursivamente un objeto salido de ConvertFrom-Json a hashtable.
# Necesario porque ConvertFrom-Json -AsHashtable solo existe en PS 7+ y
# el panel debe funcionar tambien en Windows PowerShell 5.1.
function ConvertTo-AtlasHashtable {
    param($Obj)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [System.Management.Automation.PSCustomObject]) {
        $ht = @{}
        foreach ($p in $Obj.PSObject.Properties) {
            $ht[$p.Name] = ConvertTo-AtlasHashtable $p.Value
        }
        return $ht
    }
    if ($Obj -is [System.Collections.IEnumerable] -and -not ($Obj -is [string])) {
        $list = New-Object System.Collections.ArrayList
        foreach ($item in $Obj) { [void]$list.Add((ConvertTo-AtlasHashtable $item)) }
        return ,$list.ToArray()
    }
    return $Obj
}

function ConvertFrom-AtlasJson {
    param([Parameter(Mandatory)][string]$Json)
    $obj = $Json | ConvertFrom-Json
    return (ConvertTo-AtlasHashtable $obj)
}

function Get-AtlasBranding {
    [CmdletBinding()]
    param(
        [string]$OverridePath
    )

    $defaultBranding = @{
        brand = @{
            name         = "ATLAS PC SUPPORT"
            shortName    = "Atlas"
            tagline      = "Panel unificado de soporte tecnico para Windows"
            version      = "1.0.0"
            companyUrl   = "https://github.com/mikepchelper-spec/atlas-pc-support"
            supportEmail = ""
            copyright    = "(c) 2026 Atlas PC Support"
        }
        theme = @{
            accentColor      = "#FF5500"
            secondaryColor   = "#002147"
            darkMode         = $true
            useSystemAccent  = $false
            cornerRadius     = 8
            fontFamily       = "Segoe UI Variable"
        }
        language = "auto"
        window = @{
            title       = "ATLAS PC SUPPORT - Panel v1.0"
            width       = 1100
            height      = 720
            minWidth    = 900
            minHeight   = 600
            showSearch  = $true
            showFooter  = $true
        }
        behavior = @{
            autoElevate        = $true
            logPath            = "%LOCALAPPDATA%\AtlasPC\logs"
            dependenciesPath   = "%LOCALAPPDATA%\AtlasPC\bin"
            defaultCategory    = "Diagnostico"
            confirmBeforeRun   = $false
        }
        categories = @(
            @{ id = "diagnostico";    label = "Diagnostico";    icon = "DIAG";  order = 1 }
            @{ id = "mantenimiento";  label = "Mantenimiento";  icon = "MAINT"; order = 2 }
            @{ id = "copia";          label = "Backup & Sync";  icon = "SYNC";  order = 3 }
            @{ id = "redes";          label = "Redes";          icon = "NET";   order = 4 }
            @{ id = "seguridad";      label = "Seguridad";      icon = "SEC";   order = 5 }
            @{ id = "software";       label = "Software";       icon = "SOFT";  order = 6 }
            @{ id = "entrega";        label = "Entrega";        icon = "HAND";  order = 7 }
        )
    }

    $candidatePaths = @()
    if ($OverridePath) { $candidatePaths += $OverridePath }
    if ($PSScriptRoot) {
        $candidatePaths += (Join-Path $PSScriptRoot "..\..\branding.json")
        $candidatePaths += (Join-Path $PSScriptRoot "branding.json")
    }
    if ($env:LOCALAPPDATA) {
        $candidatePaths += (Join-Path $env:LOCALAPPDATA "AtlasPC\branding.json")
    }
    if ($env:APPDATA) {
        $candidatePaths += (Join-Path $env:APPDATA "AtlasPC\branding.json")
    }

    foreach ($path in $candidatePaths) {
        if ($path -and (Test-Path $path)) {
            try {
                $userBranding = ConvertFrom-AtlasJson (Get-Content -Raw -Path $path)
                Write-Verbose "Branding cargado desde: $path"
                return (Merge-AtlasBranding $defaultBranding $userBranding)
            } catch {
                Write-Warning "No se pudo parsear $path - usando branding por defecto. Error: $_"
            }
        }
    }

    return $defaultBranding
}

function Merge-AtlasBranding {
    param(
        [hashtable]$Default,
        [hashtable]$Override
    )
    $merged = @{}
    foreach ($key in $Default.Keys) { $merged[$key] = $Default[$key] }
    foreach ($key in $Override.Keys) {
        if ($merged.ContainsKey($key) -and $merged[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $merged[$key] = Merge-AtlasBranding $merged[$key] $Override[$key]
        } else {
            $merged[$key] = $Override[$key]
        }
    }
    return $merged
}

function Expand-AtlasPath {
    param([string]$Path)
    if (-not $Path) { return "" }
    return [System.Environment]::ExpandEnvironmentVariables($Path)
}

function Set-AtlasPathAcl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CurrentUserOnly
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if ($env:OS -ne 'Windows_NT') { return $true }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $perm = if ($item.PSIsContainer) { '(OI)(CI)F' } else { 'F' }
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        if (-not $sid) { return $false }

        & icacls $Path '/inheritance:r' | Out-Null
        & icacls $Path '/grant:r' ("*{0}:{1}" -f $sid, $perm) | Out-Null
        if (-not $CurrentUserOnly) {
            & icacls $Path '/grant:r' ("*S-1-5-18:{0}" -f $perm) | Out-Null
            & icacls $Path '/grant:r' ("*S-1-5-32-544:{0}" -f $perm) | Out-Null
        }
        return $true
    } catch {
        return $false
    }
}

function Initialize-AtlasSecureDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CurrentUserOnly
    )

    $expanded = Expand-AtlasPath $Path
    if (-not $expanded) { return $null }
    if (-not (Test-Path -LiteralPath $expanded)) {
        New-Item -ItemType Directory -Path $expanded -Force | Out-Null
    }
    [void](Set-AtlasPathAcl -Path $expanded -CurrentUserOnly:$CurrentUserOnly)
    return $expanded
}
