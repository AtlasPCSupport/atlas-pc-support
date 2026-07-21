# ============================================================
# Invoke-Fase0  ->  Disable Legacy IPv6 Tunnels
#
# i18n: Option A (en default + full es secondary). Tool-internal
# function name kept as Invoke-Fase0 so tools.json registry, USB
# offline copies, and existing client config.json keep working.
#
# Atlas PC Support
# ============================================================

function Invoke-Fase0 {
    [CmdletBinding()]
    param()
<#
    .SYNOPSIS
    ATLAS PC SUPPORT - Disable Legacy IPv6 Tunnels (Teredo / 6to4 / ISATAP)
#>

# --- 0. Language detection ---
function _Atlas-DetectLang {
    if ($env:ATLAS_LANG) { return [string]$env:ATLAS_LANG }
    try {
        $cfg = Join-Path $env:LOCALAPPDATA 'AtlasPC\config.json'
        if (Test-Path -LiteralPath $cfg) {
            $obj = Get-Content -Raw -LiteralPath $cfg -Encoding UTF8 | ConvertFrom-Json
            if ($obj.language) { return [string]$obj.language }
        }
    } catch {}
    $sys = (Get-Culture).TwoLetterISOLanguageName
    if ($sys -eq 'es') { return 'es' }
    return 'en'
}

$T = @{
    en = @{
        Brand          = 'FASE 0 - PC Intake & Hardening'
        Subtitle       = 'DISABLE LEGACY IPv6 TUNNELS'
        Sep            = '================================'
        LogActive      = '[ REC ] LOG ACTIVE'
        LogInactive    = '[   ] LOG INACTIVE'
        LogStarted     = 'Log started.'
        LogAlready     = 'Log already running.'
        ReportSaved    = 'Report saved.'
        ReportHeader   = "=========================================`n ATLAS PC SUPPORT - TECHNICAL REPORT`n=========================================`nStart      : {0}`nClient PC  : {1}`nUser       : {2}`n=========================================`n"
        SessionEnd     = '--- SESSION END ---'
        ApplyHeader    = '[ APPLYING HARDENING PROTOCOL ]'
        ApplyStart     = '-> STARTING IPv6 TUNNEL HARDENING'
        DisablingTeredo = 'Disabling Teredo Tunneling... [OK]'
        Disabling6to4   = 'Disabling 6to4 Interface... [OK]'
        DisablingIsatap = 'Disabling ISATAP Tunneling... [OK]'
        ApplyDone       = '-> HARDENING COMPLETE.'
        Done            = 'HARDENING COMPLETE.'
        PressKey        = '[ Press any key to return ]'
        UndoHeader      = '[ RESTORING DEFAULTS ]'
        UndoStart       = '-> REVERTING CHANGES (RESTORE DEFAULTS)'
        RestoringTeredo = 'Restoring Teredo... [OK]'
        Restoring6to4   = 'Restoring 6to4... [OK]'
        RestoringIsatap = 'Restoring ISATAP... [OK]'
        UndoDone        = '-> WARNING: machine returned to default (vulnerable) state.'
        Warn            = 'WARN: machine returned to vulnerable state.'
        StatusHeader    = '[ CURRENT NETWORK STATE ]'
        StatusReq       = '-> REQUESTING CURRENT INTERFACE STATE'
        TeredoState     = '--- TEREDO STATE ---'
        SixToFourState  = '--- 6to4 STATE ---'
        Menu1           = '[1] Start log                    '
        Menu2           = '[2] APPLY HARDENING (recommended)'
        Menu3           = '[3] Check current state          '
        Menu4           = '[4] Restore defaults (undo)      '
        Menu5           = '[5] Stop log                     '
        MenuQ           = '[Q] Quit                         '
        Prompt          = "`n      > Atlas_Admin@Terminal: "
        ExecLabel       = '[EXEC] '
        Result          = 'Result: '
        ReportFolderName = 'ATLAS_SUPPORT'
        ReportFilePrefix = 'Report_LegacyIPv6_'
    }
    es = @{
        Brand          = 'FASE 0 - PC Intake & Hardening'
        Subtitle       = 'SEGURIDAD FASE 0'
        Sep            = '================================'
        LogActive      = '[ REC ] BITACORA ACTIVA'
        LogInactive    = '[   ] BITACORA INACTIVA'
        LogStarted     = 'Bitacora iniciada correctamente.'
        LogAlready     = 'La bitacora ya esta iniciada.'
        ReportSaved    = 'Reporte guardado exitosamente.'
        ReportHeader   = "=========================================`n ATLAS PC SUPPORT - REPORTE TECNICO`n=========================================`nFecha de inicio : {0}`nEquipo Cliente  : {1}`nUsuario         : {2}`n=========================================`n"
        SessionEnd     = '--- CIERRE DE SESION ---'
        ApplyHeader    = '[ APLICANDO PROTOCOLO DE BLINDAJE ]'
        ApplyStart     = '-> INICIANDO PROTOCOLO DE BLINDAJE (FASE 0)'
        DisablingTeredo = 'Desactivando Teredo Tunneling... [OK]'
        Disabling6to4   = 'Desactivando 6to4 Interface... [OK]'
        DisablingIsatap = 'Desactivando ISATAP Tunneling... [OK]'
        ApplyDone       = '-> FASE 0 COMPLETADA CON EXITO.'
        Done            = 'FASE 0 COMPLETADA.'
        PressKey        = '[ Presiona cualquier tecla para volver ]'
        UndoHeader      = '[ RESTAURANDO VALORES DE FABRICA ]'
        UndoStart       = '-> REVIRTIENDO CAMBIOS (RESTAURACION DE FABRICA)'
        RestoringTeredo = 'Restaurando Teredo... [OK]'
        Restoring6to4   = 'Restaurando 6to4... [OK]'
        RestoringIsatap = 'Restaurando ISATAP... [OK]'
        UndoDone        = '-> ADVERTENCIA: El equipo ha sido devuelto a su estado predeterminado.'
        Warn            = 'WARN: El equipo ha vuelto a su estado vulnerable.'
        StatusHeader    = '[ ESTADO ACTUAL DE LA RED ]'
        StatusReq       = '-> SOLICITANDO ESTADO ACTUAL DE INTERFACES'
        TeredoState     = '--- TEREDO STATE ---'
        SixToFourState  = '--- 6to4 STATE ---'
        Menu1           = '[1] Iniciar bitacora               '
        Menu2           = '[2] EJECUTAR BLINDAJE (recomendado)'
        Menu3           = '[3] Verificar estado actual        '
        Menu4           = '[4] Restaurar configuracion (undo) '
        Menu5           = '[5] Finalizar bitacora             '
        MenuQ           = '[Q] Salir                          '
        Prompt          = "`n      > Atlas_Admin@Terminal: "
        ExecLabel       = '[EJECUTANDO] '
        Result          = 'Resultado: '
        ReportFolderName = 'ATLAS_SUPPORT'
        ReportFilePrefix = 'Reporte_Fase0_'
    }
}
$lang = _Atlas-DetectLang
if (-not $T.ContainsKey($lang)) { $lang = 'en' }
$L = $T[$lang]
$atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

# --- 1. INITIAL CONFIG ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$AtlasOrange = "$([char]0x1b)[38;2;255;102;0m"
$AtlasWhite  = "$([char]0x1b)[38;2;255;255;255m"
$AtlasGray   = "$([char]0x1b)[38;2;100;100;100m"
$AtlasGreen  = "$([char]0x1b)[38;2;0;255;0m"
$AtlasRed    = "$([char]0x1b)[38;2;255;50;50m"
$Reset       = "$([char]0x1b)[0m"

$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# Globals for the log subsystem
$global:IsLogging = $false
$global:LogFile = ""

# --- 2. AUTO-ELEVATION ---
# (auto-elevation handled by Atlas Launcher)

# --- 3. VISUAL HELPERS ---
function Write-Centered {
    param([string]$Text, [string]$Color = $AtlasWhite)
    $WindowWidth = $Host.UI.RawUI.WindowSize.Width
    $Padding = [math]::Max(0, [int](($WindowWidth - $Text.Length) / 2))
    $LeftSpaces = " " * $Padding
    Write-Host "$LeftSpaces$Color$Text$Reset"
}

function Show-Header {
    Clear-Host
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title $L.Brand -Color Yellow
        Write-AtlasStep $L.Subtitle
        if ($global:IsLogging) {
            Write-AtlasWarn $L.LogActive
        } else {
            Write-AtlasStep $L.LogInactive
        }
        Write-Host ''
        return
    }

    Write-Host "`n`n`n"
    Write-Centered $L.Brand $AtlasOrange
    Write-Centered $L.Subtitle $AtlasWhite
    Write-Centered $L.Sep $AtlasGray

    if ($global:IsLogging) {
        Write-Centered $L.LogActive $AtlasRed
    } else {
        Write-Centered $L.LogInactive $AtlasGray
    }
    Write-Host "`n`n"
}

function Wait-AtlasReturn {
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message $L.PressKey
        return
    }
    Write-Centered $L.PressKey $AtlasGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# --- 4. CUSTOM LOG ENGINE ---
function Write-AtlasLog {
    param([string]$Message)
    if ($global:IsLogging -and $global:LogFile) {
        $Timestamp = Get-Date -Format "HH:mm:ss"
        "[$Timestamp] $Message" | Out-File -FilePath $global:LogFile -Append -Encoding UTF8
    }
}

function Start-AtlasLog {
    if ($global:IsLogging) {
        Show-Header; Write-Centered $L.LogAlready $AtlasOrange; Start-Sleep -Seconds 2; return
    }

    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $LogFolder = Join-Path -Path $DesktopPath -ChildPath $L.ReportFolderName
    if (-not (Test-Path -Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null }

    $TimeString = Get-Date -Format "yyyyMMdd_HHmmss"
    $global:LogFile = Join-Path -Path $LogFolder -ChildPath ('{0}{1}.txt' -f $L.ReportFilePrefix, $TimeString)
    $global:IsLogging = $true

    $ReportHeader = $L.ReportHeader -f (Get-Date -Format 'dd/MM/yyyy HH:mm:ss'), $env:COMPUTERNAME, $env:USERNAME
    $ReportHeader | Out-File -FilePath $global:LogFile -Encoding UTF8

    Show-Header
    Write-Centered $L.LogStarted $AtlasGreen
    Start-Sleep -Seconds 1
}

function Stop-AtlasLog {
    if (-not $global:IsLogging) { return }

    Write-AtlasLog $L.SessionEnd
    $global:IsLogging = $false

    Show-Header
    Write-Centered $L.ReportSaved $AtlasGreen
    Start-Sleep -Seconds 1
}

# --- 5. ACTION FUNCTIONS WITH LOGGING ---
function Hardening-Apply {
    Show-Header
    Write-Centered $L.ApplyHeader $AtlasWhite
    Write-Host "`n"

    Write-AtlasLog $L.ApplyStart

    Write-Centered $L.DisablingTeredo $AtlasGreen
    Write-AtlasLog ($L.ExecLabel + $L.DisablingTeredo)
    $res1 = netsh interface teredo set state disabled
    Write-AtlasLog ($L.Result + $res1)

    Write-Centered $L.Disabling6to4 $AtlasGreen
    Write-AtlasLog ($L.ExecLabel + $L.Disabling6to4)
    $res2 = netsh interface ipv6 6to4 set state state=disabled undoonstop=disabled
    Write-AtlasLog ($L.Result + $res2)

    Write-Centered $L.DisablingIsatap $AtlasGreen
    Write-AtlasLog ($L.ExecLabel + $L.DisablingIsatap)
    $res3 = netsh interface ipv6 isatap set state state=disabled
    Write-AtlasLog ($L.Result + $res3)

    Write-AtlasLog $L.ApplyDone

    Write-Host "`n"
    Write-Centered $L.Done $AtlasOrange
    Write-Host "`n"
    Wait-AtlasReturn
}

function Restore-Defaults {
    Show-Header
    Write-Centered $L.UndoHeader $AtlasRed
    Write-Host "`n"

    Write-AtlasLog $L.UndoStart

    Write-Centered $L.RestoringTeredo $AtlasWhite
    $res1 = netsh interface teredo set state type=default
    Write-AtlasLog ($L.ExecLabel + $L.RestoringTeredo + ' ' + $L.Result + $res1)

    Write-Centered $L.Restoring6to4 $AtlasWhite
    $res2 = netsh interface ipv6 6to4 set state state=enabled
    Write-AtlasLog ($L.ExecLabel + $L.Restoring6to4 + ' ' + $L.Result + $res2)

    Write-Centered $L.RestoringIsatap $AtlasWhite
    $res3 = netsh interface ipv6 isatap set state state=enabled
    Write-AtlasLog ($L.ExecLabel + $L.RestoringIsatap + ' ' + $L.Result + $res3)

    Write-AtlasLog $L.UndoDone

    Write-Host "`n"
    Write-Centered $L.Warn $AtlasWhite
    Write-Host "`n"
    Wait-AtlasReturn
}

function Check-Status {
    Show-Header
    Write-Centered $L.StatusHeader $AtlasWhite
    Write-Host "`n"

    Write-AtlasLog $L.StatusReq

    $Teredo = (netsh interface teredo show state | Out-String).Trim()
    $6to4 = (netsh interface ipv6 6to4 show state | Out-String).Trim()

    Write-AtlasLog ($L.TeredoState + "`n" + $Teredo)
    Write-AtlasLog ($L.SixToFourState + "`n" + $6to4)

    Write-Centered $L.TeredoState $AtlasGray
    Write-Centered $Teredo $AtlasWhite
    Write-Host "`n"
    Write-Centered $L.SixToFourState $AtlasGray
    Write-Centered $6to4 $AtlasWhite
    Write-Host "`n"
    Wait-AtlasReturn
}

# --- 6. MAIN MENU ---
do {
    Show-Header

    Write-Centered $L.Menu1 $AtlasGreen
    Write-Centered $L.Menu2 $AtlasWhite
    Write-Centered $L.Menu3 $AtlasWhite
    Write-Centered $L.Menu4 $AtlasRed
    Write-Centered $L.Menu5 $AtlasGray
    Write-Centered $L.MenuQ $AtlasGray

    Write-Host $L.Prompt -NoNewline -ForegroundColor DarkYellow
    $Selection = Read-Host

    switch ($Selection) {
        '1' { Start-AtlasLog }
        '2' { Hardening-Apply }
        '3' { Check-Status }
        '4' { Restore-Defaults }
        '5' { Stop-AtlasLog }
        'q' { Stop-AtlasLog; return }
        'Q' { Stop-AtlasLog; return }
    }
} while ($true)
}
