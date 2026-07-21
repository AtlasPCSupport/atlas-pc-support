# ============================================================
# Invoke-MantenimientoPRO
# Migrado de: MantenimientoPRO.ps1 (v8.3)
# Atlas PC Support — v1.0
# ============================================================

function Invoke-MantenimientoPRO {
    [CmdletBinding()]
    param()

# --- 2. CONFIGURACIÓN + NOMBRE CLIENTE ---
$Host.UI.RawUI.WindowTitle = "ATLAS PC SUPPORT | Maintenance Suite v8.3"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host
$atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

function Write-Centered-PRO {
    param([string]$Text, [string]$Color = 'White')
    $w = try { $Host.UI.RawUI.WindowSize.Width } catch { 80 }
    $pad = [Math]::Max(0, [Math]::Floor(($w - $Text.Length) / 2))
    Write-Host ((' ' * $pad) + $Text) -ForegroundColor $Color
}

function _Write-AtlasHeaderCompat {
    param([string]$Title, [ConsoleColor]$Color = 'Yellow')
    if ($atlasToolkitReady) {
        Write-AtlasHeader -Title $Title -Color $Color
        return
    }
    Write-Centered-PRO $Title $Color
}

function _Write-AtlasStepCompat {
    param([string]$Message, [ConsoleColor]$Color = 'Gray')
    if ($atlasToolkitReady) {
        Write-AtlasStep $Message
        return
    }
    Write-Host ("  {0}" -f $Message) -ForegroundColor $Color
}

function _Wait-AtlasExitCompat {
    param([string]$Message)
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message $Message
        return
    }
    Write-Host ("`n  {0}" -f $Message) -ForegroundColor Yellow
    $null = Read-Host
}

Write-Host "`n"
if ($atlasToolkitReady) {
    _Write-AtlasHeaderCompat -Title "DEEP CLEAN & REPAIR  v8.3" -Color Yellow
    _Write-AtlasStepCompat -Message "Defender · Cleanup · DISM/SFC · Repair · Report" -Color DarkGray
} else {
    Write-Centered-PRO "============================================================" 'DarkGray'
    Write-Centered-PRO "        DEEP CLEAN & REPAIR  v8.3" 'Yellow'
    Write-Centered-PRO "  Defender · Cleanup · DISM/SFC · Repair · Report" 'DarkGray'
    Write-Centered-PRO "============================================================" 'DarkGray'
}
Write-Host "`n"
Write-Host "  Client name (Enter to use hostname): " -NoNewline -ForegroundColor Cyan
$inputName = Read-Host
$script:ClientName = if ($inputName.Trim()) { $inputName.Trim() } else { $env:COMPUTERNAME }
Write-Host "  Cliente: $($script:ClientName)" -ForegroundColor Green
Start-Sleep 1

# --- 3. VARIABLES DE ESTADO ---
for ($n = 1; $n -le 15; $n++) {
    Set-Variable -Name "s$n" -Value "[ ]" -Scope Script
    Set-Variable -Name "c$n" -Value "White" -Scope Script
    Set-Variable -Name "Run$n" -Value $false -Scope Script
}
$script:ChkDskResult = "Pendiente"
$script:TempMB = "0 MB"
$script:SxSResult = "Pendiente"
$script:SysOS = ""; $script:SysCPU = ""; $script:SysRAM = ""
$script:SysGPU = ""; $script:SysUptime = ""; $script:SysDiskInfo = ""
$script:DriverIssues = ""; $script:EventErrors = ""
$script:PendingUpdates = ""; $script:DiskSpaceInfo = ""
$script:StartupItems = ""; $script:NetworkInfo = ""
$script:DefenderResult = ""; $script:BatteryInfo = ""
$script:SysPSVer = ""

# --- 4. SISTEMA DE LOG ---
$script:AutoLog = [System.Collections.Generic.List[string]]::new()
function Write-Log {
    param([string]$Msg, [string]$Level = "INFO")
    $Entry = "[$(Get-Date -Format 'HH:mm:ss')][$Level] $Msg"
    $script:AutoLog.Add($Entry)
}

# --- 5. INTERPRETADOR DE ERRORES ---
$script:ErrorPatterns = @(
    @{ Pattern='CHKDSK.*error.*Codigo:\s*11'; Diag='Volumen en uso o bloqueado por otro proceso'; Fix='Ejecute "chkdsk X: /r" programado en el proximo reinicio'; Prio='Media' }
    @{ Pattern='CHKDSK.*error.*Codigo:\s*3';  Diag='File system con errores criticos'; Fix='Programe "chkdsk X: /r" offline urgentemente'; Prio='Alta' }
    @{ Pattern='CHKDSK.*error';               Diag='Error en verificacion de disk'; Fix='Revise el disk manualmente con "chkdsk /r"'; Prio='Alta' }
    @{ Pattern='SFC finalizo con codigo';      Diag='Se encontraron problemas de integridad del sistema'; Fix='Revise CBS.log en C:\Windows\Logs\CBS\CBS.log'; Prio='Media' }
    @{ Pattern='DISM finalizo con codigo';     Diag='Reparacion de imagen completed con advertencias'; Fix='Considere reparacion con ISO de Windows usando /Source'; Prio='Media' }
    @{ Pattern='No MSFT_Volume';               Diag='Unidad no optimizable (particion de recovery o virtual)'; Fix='Esto es normal - excluya esta unidad del proceso'; Prio='Baja' }
    @{ Pattern='SIN INTERNET';                 Diag='No hay conectividad de red activa'; Fix='Verifique cable de red, WiFi, o adaptador de red'; Prio='Alta' }
    @{ Pattern='Restore Point fallo';          Diag='Proteccion del sistema posiblemente desenabled'; Fix='Habilite en: Sistema > Proteccion del sistema > Configurar'; Prio='Alta' }
    @{ Pattern='DISM WinSxS finalizo';         Diag='Limpieza de componentes completed parcialmente'; Fix='Reintente o use Disk Cleanup (cleanmgr) manualmente'; Prio='Baja' }
    @{ Pattern='Kernel-Power';                 Diag='Apagado inesperado o corte de energia detectado'; Fix='Verifique fuente de poder, UPS, y temperatura del computer'; Prio='Alta' }
    @{ Pattern='WHEA';                         Diag='Error de hardware (memoria, CPU, o disk) detectado'; Fix='Ejecute diagnostico de memoria (mdsched.exe) y revise temperaturas'; Prio='Critica' }
    @{ Pattern='BugCheck|BlueScreen';          Diag='Pantalla azul (BSOD) registrada en el sistema'; Fix='Analice minidumps en C:\Windows\Minidump con WinDbg'; Prio='Critica' }
    @{ Pattern='amenaza|threat';               Diag='Posible malware detectado por Windows Defender'; Fix='Ejecute scan completo y revise la cuarentena de Defender'; Prio='Critica' }
    @{ Pattern='disk.*9[0-9]%|disk.*100%';   Diag='Unidad de disk casi llena'; Fix='Libere espacio urgentemente para evitar degradacion del sistema'; Prio='Alta' }
    @{ Pattern='ConfigManagerErrorCode';       Diag='Device con driver problematico'; Fix='Actualice o reinstale el driver desde el Administrador de devices'; Prio='Media' }
)

function Get-Recommendations {
    $Recs = [System.Collections.Generic.List[hashtable]]::new()
    $seen = @{}
    
    foreach ($entry in $script:AutoLog) {
        foreach ($p in $script:ErrorPatterns) {
            if ($entry -match $p.Pattern) {
                $drive = ""
                if ($entry -match '([A-Z]):') { $drive = $Matches[1] + ":" }
                $pct = ""
                if ($entry -match '(\d+)%') { $pct = $Matches[1] + "%" }
                $errCode = ""
                if ($entry -match 'Codigo:\s*(\d+)') { $errCode = "Codigo $($Matches[1])" }
                if ($entry -match 'codigo\s+(\d+)') { $errCode = "Codigo $($Matches[1])" }
                
                $diag = $p.Diag
                $fix = $p.Fix
                if ($drive) { $fix = $fix -replace 'X:', $drive }
                
                $detailParts = @()
                if ($drive)   { $detailParts += "Unidad: $drive" }
                if ($pct)     { $detailParts += "Uso: $pct" }
                if ($errCode) { $detailParts += $errCode }
                $detail = if ($detailParts) { $detailParts -join " | " } else { "-" }
                
                $key = "$($p.Pattern)|$drive"
                if ($seen.ContainsKey($key)) { continue }
                $seen[$key] = $true
                
                $Recs.Add(@{ 
                    Priority  = $p.Prio
                    Diagnosis = $diag
                    Action    = $fix
                    Source    = $entry
                    Drive     = $drive
                    Percent   = $pct
                    ErrCode   = $errCode
                    Detail    = $detail
                })
                break
            }
        }
    }
    return $Recs
}

# --- 6. FUNCIONES DE DISEÑO ---
function Show-Header {
    Clear-Host
    if ($atlasToolkitReady) {
        Write-Host ''
        _Write-AtlasHeaderCompat -Title "ATLAS PC SUPPORT" -Color Yellow
        _Write-AtlasStepCompat -Message ("Cliente: {0}" -f $script:ClientName) -Color Cyan
        Write-Host ''
        return
    }
    $w = $Host.UI.RawUI.WindowSize.Width; if ($w -le 0) { $w = 80 }
    $t = "ATLAS PC SUPPORT"
    $p = [math]::Max(0, [int](($w - $t.Length) / 2))
    Write-Host "`n"
    Write-Host (" " * $p + $t) -ForegroundColor Yellow
    Write-Host ("=" * $w) -ForegroundColor DarkGray
    Write-Host "  Cliente: $($script:ClientName)" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu-Frame {
    $A = 90; $BC = "DarkGray"
    $TL=[char]0x2554; $TR=[char]0x2557; $BL=[char]0x255A; $BR=[char]0x255D
    $V=[char]0x2551; $H=[char]0x2550
    $MG=[math]::Max(0,[math]::Floor(($Host.UI.RawUI.WindowSize.Width-$A)/2))
    
    function ItemMenu($N,$T,$E,$CE) {
        $F=" $N. $T"; $Sp=$A-4-$F.Length-$E.Length; $Rl=" "*[math]::Max(0,$Sp)
        Write-Host (" "*$MG) -NoNewline; Write-Host "$V " -F $BC -NoNewline
        Write-Host $F -F White -NoNewline; Write-Host $Rl -NoNewline
        Write-Host $E -F $CE -NoNewline; Write-Host " $V" -F $BC
    }
    function Sep { Write-Host (" "*$MG) -NoNewline; Write-Host "$V " -F $BC -NoNewline; Write-Host ("-"*($A-4)) -F DarkGray -NoNewline; Write-Host " $V" -F $BC }
    function SepT($T) { 
        $Pad = $A-4-$T.Length-2; $L=[math]::Floor($Pad/2); $R2=$Pad-$L
        Write-Host (" "*$MG) -NoNewline; Write-Host "$V " -F $BC -NoNewline
        Write-Host ("-"*$L) -F DarkGray -NoNewline; Write-Host " $T " -F Cyan -NoNewline
        Write-Host ("-"*$R2) -F DarkGray -NoNewline; Write-Host " $V" -F $BC
    }

    $LH = "$H" * ($A-2)
    Write-Host (" "*$MG) -NoNewline; Write-Host "$TL$LH$TR" -F $BC
    
    SepT "SEGURIDAD"
    ItemMenu "1"  "Crear Punto de Restauracion"           $script:s1  $script:c1
    SepT "DIAGNOSTICO"
    ItemMenu "2"  "System Info (Full Specs)"     $script:s2  $script:c2
    ItemMenu "3"  "Reparacion de Nucleo (SFC + DISM)"      $script:s3  $script:c3
    ItemMenu "4"  "Health Check de Drivers"                $script:s4  $script:c4
    ItemMenu "5"  "Event Log Scanner (Errores Criticos)"   $script:s5  $script:c5
    SepT "MANTENIMIENTO"
    ItemMenu "6"  "Windows Update (Clean + Pendientes)"    $script:s6  $script:c6
    ItemMenu "7"  "Disks (CHKDSK + Espacio + SMART)"      $script:s7  $script:c7
    ItemMenu "8"  "Limpieza de Temporales"                 $script:s8  $script:c8
    ItemMenu "9"  "Limpieza de Navegadores"                $script:s9  $script:c9
    ItemMenu "10" "Startup Programs (Analisis)"            $script:s10 $script:c10
    SepT "RED Y SEGURIDAD"
    ItemMenu "11" "Red (Reset + Perfil Completo)"          $script:s11 $script:c11
    ItemMenu "12" "Defender Quick Scan"                    $script:s12 $script:c12
    SepT "AVANZADO"
    ItemMenu "13" "Battery Report (Laptops)"               $script:s13 $script:c13
    ItemMenu "14" "Limpieza Profunda (WinSxS)"             $script:s14 $script:c14
    ItemMenu "15" "Optimizacion Unidades (TRIM/Defrag)"    $script:s15 $script:c15
    Sep
    ItemMenu "16" "MANTENIMIENTO COMPLETO AUTOMATICO"      "[AUTO]" "Magenta"
    Write-Host (" "*$MG) -NoNewline; Write-Host "$V " -F $BC -NoNewline; Write-Host (" "*($A-4)) -NoNewline; Write-Host " $V" -F $BC
    ItemMenu "0"  "GENERAR REPORTE Y SALIR"                "[HTML]" "Yellow"
    
    Write-Host (" "*$MG) -NoNewline; Write-Host "$BL$LH$BR" -F $BC
    Write-Host ""
}

# --- 7. GENERADOR DE REPORTE HTML ---
function Generar-Report {
    param([bool]$IncluirLog = $false)

    $Fecha = Get-Date -Format "dd/MM/yyyy HH:mm"
    $PC = [System.Net.WebUtility]::HtmlEncode($env:COMPUTERNAME)
    $User = [System.Net.WebUtility]::HtmlEncode($env:USERNAME)
    $Cliente = [System.Net.WebUtility]::HtmlEncode($script:ClientName)
    $FechaFile = Get-Date -Format "yyyyMMdd_HHmm"
    
    function Build-Row {
        param([string]$Mod, [string]$Acc, [string]$Det, [int]$Num)
        $RunVar = Get-Variable -Name "Run$Num" -Scope Script -ValueOnly
        if (-not $RunVar) { return "" }
        $Col = Get-Variable -Name "c$Num" -Scope Script -ValueOnly
        $Cls = if($Col -eq 'Green'){'ok'}else{'error'}
        $Txt = if($Col -eq 'Green'){'OK'}else{'FALLO'}
        $SafeDet = [System.Net.WebUtility]::HtmlEncode($Det)
        return "<tr><td>$Mod</td><td>$Acc</td><td>$SafeDet</td><td class='$Cls'>$Txt</td></tr>"
    }
    
    $Rows = ""
    $Rows += Build-Row -Mod "Seguridad"      -Acc "Restore Point"   -Det "Punto de restauracion"              -Num 1
    $Rows += Build-Row -Mod "Diagnostico"    -Acc "System Info"      -Det "System information collected" -Num 2
    $Rows += Build-Row -Mod "Reparacion"     -Acc "SFC + DISM"       -Det "Integridad de Windows"              -Num 3
    $Rows += Build-Row -Mod "Drivers"        -Acc "Health Check"     -Det $script:DriverIssues                 -Num 4
    $Rows += Build-Row -Mod "Event Log"      -Acc "Error Scanner"    -Det $script:EventErrors                  -Num 5
    $Rows += Build-Row -Mod "Windows Update" -Acc "Clean + Check"    -Det $script:PendingUpdates               -Num 6
    $Rows += Build-Row -Mod "Disks"         -Acc "CHKDSK + SMART"   -Det "$($script:ChkDskResult) | $($script:DiskSpaceInfo)" -Num 7
    $Rows += Build-Row -Mod "Temporales"     -Acc "Deep Clean"       -Det $script:TempMB                       -Num 8
    $Rows += Build-Row -Mod "Navegadores"    -Acc "Cache Clear"      -Det "Chrome, Edge, Firefox"              -Num 9
    $Rows += Build-Row -Mod "Startup"        -Acc "Analisis"         -Det $script:StartupItems                 -Num 10
    $Rows += Build-Row -Mod "Red"            -Acc "Reset + Perfil"   -Det $script:NetworkInfo                  -Num 11
    $Rows += Build-Row -Mod "Seguridad"      -Acc "Defender Scan"    -Det $script:DefenderResult               -Num 12
    $Rows += Build-Row -Mod "Battery"        -Acc "Health Report"    -Det $script:BatteryInfo                  -Num 13
    $Rows += Build-Row -Mod "Sistema"        -Acc "WinSxS Clean"     -Det $script:SxSResult                    -Num 14
    $Rows += Build-Row -Mod "Almacenamiento" -Acc "TRIM / Defrag"    -Det "Optimizacion completed"            -Num 15
    
    if (-not $Rows) { $Rows = "<tr><td colspan='4' style='text-align:center'>No se realizaron acciones.</td></tr>" }

    # System Info Section
    $SysSection = ""
    if ($script:Run2) {
        $SafeOS  = [System.Net.WebUtility]::HtmlEncode($script:SysOS)
        $SafeCPU = [System.Net.WebUtility]::HtmlEncode($script:SysCPU)
        $SafeRAM = [System.Net.WebUtility]::HtmlEncode($script:SysRAM)
        $SafeGPU = [System.Net.WebUtility]::HtmlEncode($script:SysGPU)
        $SafeUp  = [System.Net.WebUtility]::HtmlEncode($script:SysUptime)
        $SafeDsk = [System.Net.WebUtility]::HtmlEncode($script:SysDiskInfo)
        $SysSection = @"
        <div class="sys-info">
            <h2>INFORMACION DEL SISTEMA</h2>
            <div class="sys-grid">
                <div class="sys-item"><span class="sys-label">SO</span><span class="sys-value">$SafeOS</span></div>
                <div class="sys-item"><span class="sys-label">CPU</span><span class="sys-value">$SafeCPU</span></div>
                <div class="sys-item"><span class="sys-label">RAM</span><span class="sys-value">$SafeRAM</span></div>
                <div class="sys-item"><span class="sys-label">GPU</span><span class="sys-value">$SafeGPU</span></div>
                <div class="sys-item"><span class="sys-label">Uptime</span><span class="sys-value">$SafeUp</span></div>
                <div class="sys-item"><span class="sys-label">Disks</span><span class="sys-value">$SafeDsk</span></div>
                <div class="sys-item"><span class="sys-label">PowerShell</span><span class="sys-value">$($script:SysPSVer)</span></div>
            </div>
        </div>
"@
    }

    # Recommendations Section
    $RecSection = ""
    $Recs = Get-Recommendations
    if ($Recs.Count -gt 0) {
        $RecRows = ""
        foreach ($rec in $Recs) {
            $PrioClass = switch ($rec.Priority) { 'Critica'{'prio-crit'} 'Alta'{'prio-high'} 'Media'{'prio-med'} default{'prio-low'} }
            $SafeDiag   = [System.Net.WebUtility]::HtmlEncode($rec.Diagnosis)
            $SafeAct    = [System.Net.WebUtility]::HtmlEncode($rec.Action)
            $SafePrio   = [System.Net.WebUtility]::HtmlEncode($rec.Priority)
            $SafeDetail = [System.Net.WebUtility]::HtmlEncode($rec.Detail)
            $SafeSource = [System.Net.WebUtility]::HtmlEncode($rec.Source)
            $Icon = switch ($rec.Priority) { 'Critica'{'&#9888;'} 'Alta'{'&#9888;'} 'Media'{'&#9432;'} default{'&#8505;'} }
            
            $RecRows += "<tr><td class='$PrioClass'>$Icon $SafePrio</td><td class='rec-detail'><strong>$SafeDetail</strong></td><td>$SafeDiag</td><td><strong>$SafeAct</strong></td><td class='rec-source'>$SafeSource</td></tr>`n"
        }
        
        $CritCount = @($Recs | Where-Object { $_.Priority -eq 'Critica' }).Count
        $HighCount = @($Recs | Where-Object { $_.Priority -eq 'Alta' }).Count
        $MedCount  = @($Recs | Where-Object { $_.Priority -eq 'Media' }).Count
        $LowCount  = @($Recs | Where-Object { $_.Priority -eq 'Baja' }).Count
        
        $badgeHtml = ""
        if ($CritCount) { $badgeHtml += "<span class='badge badge-crit'>$CritCount CRITICA(S)</span>" }
        if ($HighCount) { $badgeHtml += "<span class='badge badge-high'>$HighCount ALTA(S)</span>" }
        if ($MedCount)  { $badgeHtml += "<span class='badge badge-med'>$MedCount MEDIA(S)</span>" }
        if ($LowCount)  { $badgeHtml += "<span class='badge badge-low'>$LowCount BAJA(S)</span>" }
        
        $RecSection = @"
        <div class="rec-header">
            <h2>&#9888; RECOMENDACIONES DEL TECNICO</h2>
            <div class="rec-summary">$badgeHtml</div>
        </div>
        <table class="rec-table">
            <thead><tr>
                <th style="width:90px">Prioridad</th>
                <th style="width:150px">Origen</th>
                <th>Diagnostico</th>
                <th>Accion Recomendada</th>
                <th style="width:220px">Entrada de Log</th>
            </tr></thead>
            <tbody>$RecRows</tbody>
        </table>
"@
    }

    # Log Section
    $LogSection = ""
    if ($IncluirLog -and $script:AutoLog.Count -gt 0) {
        $LogRows = ""
        foreach ($entry in $script:AutoLog) {
            $SafeE = [System.Net.WebUtility]::HtmlEncode($entry)
            $RC = ""
            if ($entry -match "\[ERROR\]") { $RC = " class='log-error'" }
            elseif ($entry -match "\[WARN\]") { $RC = " class='log-warn'" }
            elseif ($entry -match "\[OK\]") { $RC = " class='log-ok'" }
            $LogRows += "<tr$RC><td>$SafeE</td></tr>`n"
        }
        $ErrC = @($script:AutoLog | Where-Object { $_ -match "\[ERROR\]" }).Count
        $WrnC = @($script:AutoLog | Where-Object { $_ -match "\[WARN\]" }).Count
        $OkC  = @($script:AutoLog | Where-Object { $_ -match "\[OK\]" }).Count
        $LogSection = @"
        <div class="log-header">
            <h2>LOG DE EJECUCION</h2>
            <div class="log-summary">
                <span class="badge badge-ok">$OkC OK</span>
                <span class="badge badge-warn">$WrnC WARNINGS</span>
                <span class="badge badge-error">$ErrC ERRORES</span>
            </div>
        </div>
        <table class="log-table"><thead><tr><th>Entrada de Log</th></tr></thead><tbody>$LogRows</tbody></table>
"@
    }

    $HTML = @"
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">
<title>Report - ATLAS PC SUPPORT - $Cliente</title>
<style>
body{font-family:'Segoe UI',sans-serif;background:#f4f4f9;color:#333;margin:0;padding:20px}
.container{max-width:1100px;margin:0 auto;background:#fff;box-shadow:0 0 15px rgba(0,0,0,.1);border-radius:8px;overflow:hidden}
.header{background:#002147;color:#fff;padding:25px;text-align:center;border-bottom:5px solid #FF6600}
.header h1{margin:0;font-size:26px;letter-spacing:3px}
.header p{margin:5px 0 0;color:#FF6600;font-weight:bold}
.info-box{padding:20px;background:#f9f9f9;border-bottom:1px solid #eee;display:flex;justify-content:space-between;flex-wrap:wrap;gap:10px}
.info-box .info-item{font-size:14px}
table{width:100%;border-collapse:collapse}
th,td{padding:12px 15px;text-align:left;border-bottom:1px solid #ddd}
th{background:#002147;color:#fff;font-weight:600;text-transform:uppercase;font-size:11px}
.ok{color:#28a745;font-weight:bold} .error{color:#dc3545;font-weight:bold}
.footer{padding:20px;text-align:center;font-size:11px;color:#777;background:#fafafa}
.sys-info{padding:20px;border-bottom:2px solid #FF6600}
.sys-info h2{margin:0 0 15px;font-size:16px;color:#002147}
.sys-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.sys-item{background:#f8f9fa;padding:10px 15px;border-radius:6px;border-left:3px solid #002147}
.sys-label{display:block;font-size:11px;color:#666;text-transform:uppercase;font-weight:600}
.sys-value{display:block;font-size:13px;color:#333;margin-top:3px}
.rec-header{padding:20px 20px 10px;border-top:3px solid #dc3545}
.rec-header h2{margin:0 0 10px;font-size:16px;color:#dc3545}
.rec-summary{display:flex;gap:8px;flex-wrap:wrap}
.rec-table td{font-size:13px;padding:10px 15px;vertical-align:top}
.rec-detail{font-family:Consolas,monospace;font-size:12px;color:#002147;background:#e8f0fe;border-radius:4px}
.rec-source{font-family:Consolas,monospace;font-size:11px;color:#888;word-break:break-all}
.prio-crit{color:#fff;background:#dc3545;font-weight:bold;border-radius:4px;text-align:center;white-space:nowrap}
.prio-high{color:#fff;background:#fd7e14;font-weight:bold;border-radius:4px;text-align:center;white-space:nowrap}
.prio-med{color:#333;background:#ffc107;font-weight:bold;border-radius:4px;text-align:center;white-space:nowrap}
.prio-low{color:#fff;background:#6c757d;font-weight:bold;border-radius:4px;text-align:center;white-space:nowrap}
.badge{padding:4px 12px;border-radius:12px;font-size:12px;font-weight:bold;color:#fff}
.badge-ok{background:#28a745} .badge-warn{background:#ffc107;color:#333} .badge-error{background:#dc3545}
.badge-crit{background:#dc3545} .badge-high{background:#fd7e14} .badge-med{background:#ffc107;color:#333} .badge-low{background:#6c757d}
.log-header{padding:20px 20px 10px;border-top:3px solid #FF6600}
.log-header h2{margin:0 0 10px;font-size:16px;color:#002147}
.log-summary{display:flex;gap:10px}
.log-table td{font-family:Consolas,monospace;font-size:12px;padding:6px 15px}
.log-error td{background:#fff5f5;color:#dc3545}
.log-warn td{background:#fffdf0;color:#856404}
.log-ok td{background:#f0fff4;color:#28a745}
</style></head><body>
<div class="container">
    <div class="header"><h1>ATLAS PC SUPPORT</h1><p>REPORTE DE MANTENIMIENTO TECNICO</p></div>
    <div class="info-box">
        <div class="info-item"><strong>Cliente:</strong> $Cliente</div>
        <div class="info-item"><strong>Computer:</strong> $PC \ $User</div>
        <div class="info-item"><strong>Date:</strong> $Fecha</div>
    </div>
    $SysSection
    <table><thead><tr><th>Modulo</th><th>Accion</th><th>Detalle Tecnico</th><th>Resultado</th></tr></thead><tbody>$Rows</tbody></table>
    $RecSection
    $LogSection
    <div class="footer">
        <p>Generado por ATLAS PC SUPPORT System Helper v8.3</p>
        <p style="font-size:10px;color:#aaa">Integridad del documento verificable via SHA256 (ver fuente HTML)</p>
    </div>
</div></body></html>
"@
    $ReportFile = "Report_${PC}_${FechaFile}.html"
    $Path = "$env:USERPROFILE\Desktop\$ReportFile"
    $HTML | Out-File $Path -Encoding UTF8
    
    # Hash de integridad
    $Hash = (Get-FileHash $Path -Algorithm SHA256 -EA SilentlyContinue).Hash
    if ($Hash) {
        $HashFooter = "`n<!-- SHA256: $Hash -->"
        Add-Content $Path $HashFooter -Encoding UTF8
        Write-Host "  [SHA256] $Hash" -ForegroundColor DarkGray
    }
    
    # Intentar exportar PDF via Edge headless
    $PdfPath = $Path -replace '\.html$', '.pdf'
    $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edgePath)) { $edgePath = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
    if (Test-Path $edgePath) {
        try {
            $pdfArgs = "--headless --disable-gpu --print-to-pdf=`"$PdfPath`" --no-margins `"$Path`""
            Start-Process $edgePath -ArgumentList $pdfArgs -NoNewWindow -Wait -EA Stop
            if (Test-Path $PdfPath) {
                Write-Host "  [PDF] $PdfPath" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [PDF] No se pudo generar (no critico)." -ForegroundColor Gray
        }
    }
    
    Write-Host "`n  [REPORTE] $Path" -ForegroundColor Green
    Start-Process $Path
}

# --- 8. TASK RUNNER ---
function Run-Task-Safe {
    param([string]$Title, [scriptblock]$ScriptBlock, [switch]$AutoMode)
    if (-not $AutoMode) {
        Clear-Host
        Write-Host "`n  ============================================================" -ForegroundColor DarkGray
        Write-Host "  $Title" -ForegroundColor Yellow
        Write-Host "  ============================================================`n" -ForegroundColor DarkGray
    }
    $Success = $false
    try {
        & $ScriptBlock; $Success = $true
        if (-not $AutoMode) { Write-Host "`n  [OK] Tarea completed." -ForegroundColor Green }
    } catch {
        if (-not $AutoMode) { Write-Host "`n  [!] Error: $_" -ForegroundColor Red }
        Write-Log "[$Title] EXCEPCION: $_" "ERROR"
    }
    if (-not $AutoMode) { _Wait-AtlasExitCompat -Message "Press Enter to go back..." }
    return $Success
}

# --- 9. PROGRESS BAR ---
function Show-AutoProgress {
    param([int]$Step, [int]$Total, [string]$TaskName, [int]$ElapsedSec, [int]$EstTotalSec)
    $Pct = [math]::Round(($Step / $Total) * 100)
    $BL2 = 40; $Fl = [math]::Round($BL2 * $Step / $Total); $Em = $BL2 - $Fl
    $Bar = ([char]0x2588).ToString() * $Fl + ([char]0x2591).ToString() * $Em
    $w = $Host.UI.RawUI.WindowSize.Width; if ($w -le 0) { $w = 80 }
    $RemSec = [math]::Max(0, $EstTotalSec - $ElapsedSec)
    $RemMin = [math]::Round($RemSec / 60, 1)
    Clear-Host
    Write-Host "`n"
    $t2 = "MODO AUTOMATICO - ATLAS PC SUPPORT"
    $pd = [math]::Max(0, [int](($w - $t2.Length) / 2))
    Write-Host (" " * $pd + $t2) -ForegroundColor Magenta
    Write-Host ("=" * $w) -ForegroundColor DarkGray
    Write-Host "  Cliente: $($script:ClientName)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Paso $Step de $Total" -ForegroundColor White
    Write-Host "  $Bar  $Pct%" -ForegroundColor Cyan
    Write-Host "  Tiempo restante estimado: ~${RemMin} min" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  >> $TaskName" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ("-" * $w) -ForegroundColor DarkGray
    Write-Host ""
}

# --- 10. DEFINICIÓN DE 15 TAREAS ---
$script:TaskDefinitions = @(

    @{ Num=1; Title="CREAR PUNTO DE RESTAURACION"; Est=10; Code={
        Write-Host "  Verifying servicio..." -ForegroundColor Gray
        try {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            $Desc = "ATLAS_Mantenimiento_$(Get-Date -Format 'yyyyMMdd')"
            Write-Host "  Creating punto: $Desc" -ForegroundColor Cyan
            $SRP = [System.Management.ManagementClass]"\\.\root\default:SystemRestore"
            $Res = $SRP.CreateRestorePoint($Desc, 12, 100)
            if ($Res.ReturnValue -eq 0) { Write-Host "  Punto created." -ForegroundColor Green; Write-Log "Restore Point created: $Desc" "OK" }
            else { Write-Log "Restore Point fallo. Codigo: $($Res.ReturnValue)" "WARN"; throw "Restore point failed" }
        } catch { Write-Warning "  $_"; throw }
    }},

    @{ Num=2; Title="INFO DEL SISTEMA (SPECS)"; Est=15; Code={
        Write-Host "  Collecting system information..." -ForegroundColor Cyan
        $os = Get-CimInstance Win32_OperatingSystem
        $script:SysOS = "$($os.Caption) Build $($os.BuildNumber)"
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $script:SysCPU = "$($cpu.Name) ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T)"
        $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $script:SysRAM = "${totalRAM} GB total / ${freeRAM} GB libre"
        $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
        $script:SysGPU = if ($gpu) { $gpu.Name } else { "No detectada" }
        $uptime = (Get-Date) - $os.LastBootUpTime
        $script:SysUptime = "$([int]$uptime.TotalDays)d $($uptime.Hours)h $($uptime.Minutes)m"
        $script:SysPSVer = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
        $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $dInfo = @()
        foreach ($d in $disks) {
            $total = [math]::Round($d.Size/1GB,1); $free = [math]::Round($d.FreeSpace/1GB,1)
            $pct = if($d.Size -gt 0){[math]::Round((($d.Size-$d.FreeSpace)/$d.Size)*100,0)}else{0}
            $dInfo += "$($d.DeviceID) ${free}GB libre de ${total}GB (${pct}% usado)"
            if ($pct -ge 90) { Write-Log "disk $($d.DeviceID) al ${pct}% - casi lleno (ver Tarea 7)" "INFO" }
        }
        $script:SysDiskInfo = $dInfo -join " | "
        Write-Host "  OS:     $($script:SysOS)" -ForegroundColor White
        Write-Host "  CPU:    $($script:SysCPU)" -ForegroundColor White
        Write-Host "  RAM:    $($script:SysRAM)" -ForegroundColor White
        Write-Host "  GPU:    $($script:SysGPU)" -ForegroundColor White
        Write-Host "  Uptime: $($script:SysUptime)" -ForegroundColor White
        Write-Host "  Disks: $($script:SysDiskInfo)" -ForegroundColor White
        Write-Host "  PS:     $($script:SysPSVer)" -ForegroundColor White
        Write-Log "System Info recopilada" "OK"
    }},

    @{ Num=3; Title="REPARACION DE NUCLEO (DISM + SFC)"; Est=300; Code={
        Write-Host "  1. DISM RestoreHealth (reparar almacen de componentes)..." -ForegroundColor Cyan
        $DISM = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru
        if ($DISM.ExitCode -eq 0) { Write-Host "  DISM: OK" -ForegroundColor Green; Write-Log "DISM RestoreHealth completed." "OK" }
        else { Write-Host "  DISM: Codigo $($DISM.ExitCode)" -ForegroundColor Yellow; Write-Log "DISM finalizo con codigo $($DISM.ExitCode)" "WARN" }

        Write-Host "  2. SFC /scannow (verificar integridad de archivos de sistema)..." -ForegroundColor Cyan
        $SFC = Start-Process "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru
        if ($SFC.ExitCode -eq 0) { Write-Host "  SFC: OK" -ForegroundColor Green; Write-Log "SFC completed without errors." "OK" }
        else { Write-Host "  SFC: Codigo $($SFC.ExitCode)" -ForegroundColor Yellow; Write-Log "SFC finalizo con codigo $($SFC.ExitCode)" "WARN" }
    }},

    @{ Num=4; Title="HEALTH CHECK DE DRIVERS"; Est=20; Code={
        Write-Host "  Searching for devices with issues..." -ForegroundColor Cyan
        $problems = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        if ($problems) {
            $list = @()
            foreach ($dev in $problems) {
                $msg = "$($dev.Name) (Error: $($dev.ConfigManagerErrorCode))"
                Write-Host "  [!] $msg" -ForegroundColor Red
                $list += $msg
                Write-Log "ConfigManagerErrorCode - $msg" "WARN"
            }
            $script:DriverIssues = "$($problems.Count) device(s) con problemas: $($list[0..2] -join ', ')"
        } else {
            Write-Host "  All drivers OK." -ForegroundColor Green
            $script:DriverIssues = "All drivers working correctly"
            Write-Log "Drivers: todos OK" "OK"
        }
    }},

    @{ Num=5; Title="EVENT LOG SCANNER (ERRORES CRITICOS)"; Est=30; Code={
        Write-Host "  Searching errores criticos (ultimos 7 dias)..." -ForegroundColor Cyan
        $since = (Get-Date).AddDays(-7)
        $events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=$since} -MaxEvents 25 -ErrorAction SilentlyContinue
        if ($events) {
            $grouped = $events | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 5
            $summary = @()
            foreach ($g in $grouped) {
                $msg = "$($g.Name): $($g.Count) error(es)"
                Write-Host "  [!] $msg" -ForegroundColor Yellow
                $summary += $msg
                if ($g.Name -match 'Kernel-Power') { Write-Log "Kernel-Power detectado ($($g.Count) eventos)" "WARN" }
                if ($g.Name -match 'WHEA') { Write-Log "WHEA hardware error ($($g.Count) eventos)" "ERROR" }
            }
            $script:EventErrors = "$($events.Count) errores: $($summary -join '; ')"
            Write-Log "Event Log: $($events.Count) errores criticos en 7 dias" "WARN"
        } else {
            Write-Host "  Sin errores criticos." -ForegroundColor Green
            $script:EventErrors = "No critical errors in the last 7 days"
            Write-Log "Event Log: limpio" "OK"
        }
    }},

    @{ Num=6; Title="WINDOWS UPDATE (CLEAN + PENDIENTES)"; Est=45; Code={
        Write-Host "  Cleaning servicios de Update..." -ForegroundColor Gray
        Stop-Service wuauserv, bits, cryptSvc -Force -EA SilentlyContinue
        Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -EA SilentlyContinue
        Start-Service cryptSvc, wuauserv, bits -EA SilentlyContinue
        Write-Host "  Servicios reiniciados." -ForegroundColor Green
        Write-Log "Windows Update limpiado." "OK"
        Write-Host "  Searching updates pendientes..." -ForegroundColor Cyan
        try {
            $Session = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $Session.CreateUpdateSearcher()
            $Results = $Searcher.Search("IsInstalled=0")
            $count = $Results.Updates.Count
            if ($count -gt 0) {
                Write-Host "  [!] $count actualizacion(es) pendiente(s):" -ForegroundColor Yellow
                $names = @()
                $Results.Updates | Select-Object -First 5 | ForEach-Object {
                    Write-Host "      - $($_.Title)" -ForegroundColor White
                    $names += $_.Title
                }
                $script:PendingUpdates = "$count pendiente(s): $($names[0..2] -join '; ')"
                Write-Log "Updates pendientes: $count" "WARN"
            } else {
                Write-Host "  Sistema al dia." -ForegroundColor Green
                $script:PendingUpdates = "Sistema actualizado"
                Write-Log "Windows Update: al dia" "OK"
            }
        } catch {
            Write-Host "  Could not verify updates." -ForegroundColor Gray
            $script:PendingUpdates = "Could not verify"
            Write-Log "Windows Update check fallo: $_" "WARN"
        }
    }},

    @{ Num=7; Title="DISCOS (CHKDSK + ESPACIO + SMART)"; Est=120; Code={
        Write-Host "  === CHKDSK ===" -ForegroundColor Cyan
        $Drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.FileSystem -eq 'NTFS' }
        $ResultsList = @()
        if ($Drives) {
            foreach ($Disk in $Drives) {
                $DiskID = $Disk.DeviceID
                Write-Host "  [*] Scan: $DiskID" -ForegroundColor Cyan
                $Proc = Start-Process "chkdsk.exe" -ArgumentList "$DiskID /scan" -NoNewWindow -Wait -PassThru
                if ($Proc.ExitCode -eq 0) { $ResultsList += "$DiskID (OK)"; Write-Log "CHKDSK $DiskID OK" "OK" }
                else { $ResultsList += "$DiskID (ERROR)"; Write-Log "CHKDSK $DiskID error (Codigo: $($Proc.ExitCode))" "ERROR" }
            }
        }
        $script:ChkDskResult = if ($ResultsList) { $ResultsList -join " | " } else { "Sin unidades NTFS" }
        
        Write-Host "`n  === ESPACIO ===" -ForegroundColor Cyan
        $spaceInfo = @()
        Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
            $total = [math]::Round($_.Size/1GB,1); $free = [math]::Round($_.FreeSpace/1GB,1)
            $pct = if($_.Size -gt 0){[math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,0)}else{0}
            $color = if($pct -ge 90){"Red"}elseif($pct -ge 75){"Yellow"}else{"Green"}
            Write-Host "  $($_.DeviceID) ${free}GB free of ${total}GB (${pct}%)" -ForegroundColor $color
            $spaceInfo += "$($_.DeviceID) ${pct}%"
            if ($pct -ge 90) { Write-Log "disk $($_.DeviceID) al ${pct}% - critico" "ERROR" }
        }
        $script:DiskSpaceInfo = $spaceInfo -join " | "

        Write-Host "`n  === SMART ===" -ForegroundColor Cyan
        try {
            $physDisks = Get-PhysicalDisk -ErrorAction Stop
            foreach ($pd in $physDisks) {
                $health = $pd.HealthStatus
                $media = $pd.MediaType
                $size = [math]::Round($pd.Size/1GB, 0)
                $color = if($health -eq 'Healthy'){"Green"}else{"Red"}
                Write-Host "  $($pd.FriendlyName) (${media}, ${size}GB) - $health" -ForegroundColor $color
                if ($health -ne 'Healthy') { Write-Log "SMART: $($pd.FriendlyName) estado $health" "ERROR" }
                $rel = Get-StorageReliabilityCounter -PhysicalDisk $pd -ErrorAction SilentlyContinue
                if ($rel) {
                    $temp = $rel.Temperature
                    $hours = $rel.PowerOnHours
                    $wear = $rel.Wear
                    if ($temp) { Write-Host "    Temp: ${temp}C | Horas: $hours | Desgaste: $wear" -ForegroundColor Gray }
                }
            }
            Write-Log "SMART check completed" "OK"
        } catch { Write-Host "  SMART no disponible." -ForegroundColor Gray; Write-Log "SMART no disponible" "WARN" }
    }},

    @{ Num=8; Title="LIMPIEZA DE TEMPORALES"; Est=15; Code={
        $TotalSize = 0; $TotalFiles = 0
        $Folders = @("$env:TEMP", "C:\Windows\Temp")
        foreach ($Folder in $Folders) {
            Write-Host "  Analizando: $Folder" -ForegroundColor Cyan
            if (Test-Path $Folder) {
                $AllFiles = @(Get-ChildItem -Path $Folder -Recurse -File -EA SilentlyContinue)
                $Count = $AllFiles.Count
                if ($Count -gt 0) {
                    $SizeBytes = ($AllFiles | Measure-Object -Property Length -Sum -EA SilentlyContinue).Sum
                    if ($SizeBytes) {
                        $MB = [math]::Round($SizeBytes / 1MB, 2)
                        $TotalSize += $MB
                        $TotalFiles += $Count
                    }
                    Write-Host "  -> Removing $MB MB ($Count archivos)..." -NoNewline
                    Remove-Item "$Folder\*" -Recurse -Force -EA SilentlyContinue
                    Write-Host " [OK]" -ForegroundColor Green
                } else {
                    Write-Host "  -> Carpeta vacia." -ForegroundColor Gray
                }
            }
        }
        Clear-RecycleBin -Force -EA SilentlyContinue
        $script:TempMB = "$TotalSize MB recuperados ($TotalFiles archivos)"
        Write-Host "  Total: $($script:TempMB)" -ForegroundColor Yellow
        Write-Log "Temporales: $($script:TempMB)" "OK"
    }},

    @{ Num=9; Title="LIMPIEZA DE NAVEGADORES"; Est=20; Code={
        Write-Host "  Limpiando cache de navegadores (sin forzar cierre)..." -ForegroundColor Yellow
        $cacheFolders = @("Cache", "Cache_Data", "Code Cache", "GPUCache", "Service Worker\CacheStorage")
        foreach ($browser in @(
            @{Name="Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data"},
            @{Name="Edge";   Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data"}
        )) {
            if (Test-Path $browser.Path) {
                $cleaned = 0
                Get-ChildItem $browser.Path -Directory -EA SilentlyContinue | ForEach-Object {
                    $profileDir = $_.FullName
                    foreach ($cf in $cacheFolders) {
                        $target = Join-Path $profileDir $cf
                        if (Test-Path $target) {
                            Remove-Item "$target\*" -Recurse -Force -EA SilentlyContinue
                            $cleaned++
                        }
                    }
                }
                Write-Host "  $($browser.Name): limpiado ($cleaned caches)" -ForegroundColor Green
            }
        }
        $FF = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $FF) { Get-ChildItem $FF -Directory | ForEach-Object { Remove-Item "$($_.FullName)\cache2\*" -Recurse -Force -EA SilentlyContinue }; Write-Host "  Firefox: limpiado" -ForegroundColor Green }
        Write-Log "Caches de navegadores limpiadas" "OK"
    }},

    @{ Num=10; Title="STARTUP PROGRAMS (ANALISIS)"; Est=10; Code={
        Write-Host "  Analyzing programas de inicio..." -ForegroundColor Cyan
        $items = @()
        $hklm = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -EA SilentlyContinue
        if ($hklm) { $hklm.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { $items += @{Name=$_.Name; Source="HKLM\Run"; Cmd=$_.Value} } }
        $hkcu = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -EA SilentlyContinue
        if ($hkcu) { $hkcu.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { $items += @{Name=$_.Name; Source="HKCU\Run"; Cmd=$_.Value} } }
        $wmi = Get-CimInstance Win32_StartupCommand -EA SilentlyContinue
        if ($wmi) { $wmi | ForEach-Object { $items += @{Name=$_.Name; Source=$_.Location; Cmd=$_.Command} } }
        $unique = $items | Sort-Object { $_.Name } -Unique
        Write-Host "  Encontrados: $($unique.Count) programa(s) de inicio" -ForegroundColor White
        foreach ($it in $unique | Select-Object -First 15) {
            Write-Host "    - $($it.Name) [$($it.Source)]" -ForegroundColor Gray
        }
        $script:StartupItems = "$($unique.Count) programa(s) en inicio"
        if ($unique.Count -gt 10) {
            Write-Host "  [!] Mas de 10 items - considere reducir" -ForegroundColor Yellow
            Write-Log "Startup: $($unique.Count) programas (excesivo)" "WARN"
        } else { Write-Log "Startup: $($unique.Count) programas" "OK" }
    }},

    @{ Num=11; Title="RED (RESET + PERFIL COMPLETO)"; Est=15; Code={
        Write-Host "  === PERFIL DE RED ===" -ForegroundColor Cyan
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
        $netInfo = @()
        foreach ($a in $adapters) {
            $desc = $a.Description
            $ip = ($a.IPAddress | Select-Object -First 1)
            $gw = ($a.DefaultIPGateway | Select-Object -First 1)
            $dns = ($a.DNSServerSearchOrder -join ", ")
            Write-Host "  Adaptador: $desc" -ForegroundColor White
            Write-Host "    IP: $ip | GW: $gw | DNS: $dns" -ForegroundColor Gray
            $netInfo += "$desc ($ip)"
        }
        $script:NetworkInfo = if ($netInfo) { $netInfo -join " | " } else { "Sin adaptadores activos" }
        Write-Host "`n  === CONECTIVIDAD ===" -ForegroundColor Cyan
        $targets = @(@{H="8.8.8.8";N="Google DNS"},@{H="1.1.1.1";N="Cloudflare"},@{H="google.com";N="Google.com"})
        foreach ($t in $targets) {
            $ping = Test-Connection $t.H -Count 1 -Quiet -EA SilentlyContinue
            $color = if($ping){"Green"}else{"Red"}
            $status = if($ping){"OK"}else{"FALLO"}
            Write-Host "  $($t.N): $status" -ForegroundColor $color
        }
        if (Test-Connection 8.8.8.8 -Count 1 -Quiet -EA SilentlyContinue) { Write-Log "Conectividad: OK" "OK" }
        else { Write-Log "SIN INTERNET" "WARN" }
        Write-Host "`n  === RESET ===" -ForegroundColor Cyan
        Start-Process "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait
        Start-Process "netsh.exe" -ArgumentList "int ip reset" -NoNewWindow -Wait
        Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -NoNewWindow -Wait
        Write-Host "  Winsock + IP + DNS reseteados." -ForegroundColor Green
        Write-Log "Red reseteada." "OK"
    }},

    @{ Num=12; Title="DEFENDER QUICK SCAN"; Est=120; Code={
        Write-Host "  Starting Windows Defender Quick Scan..." -ForegroundColor Cyan
        Write-Host "  (Timeout: 5 min)" -ForegroundColor Gray
        try {
            # Verificar que Defender esté activo
            $mpStatus = Get-MpComputerStatus -ErrorAction Stop
            if (-not $mpStatus.AntivirusEnabled) {
                Write-Host "  Defender desenabled (antivirus de terceros?)." -ForegroundColor Yellow
                $script:DefenderResult = "Defender desenabled"
                Write-Log "Defender disabled - possible third-party AV" "WARN"
                return
            }
            Write-Host "  Defender activo. Firmas: $($mpStatus.AntivirusSignatureLastUpdated.ToString('dd/MM/yyyy'))" -ForegroundColor Gray
            
            $scanJob = Start-Job { Start-MpScan -ScanType QuickScan -ErrorAction Stop }
            $completed = $scanJob | Wait-Job -Timeout 300
            if (-not $completed) {
                $scanJob | Stop-Job; $scanJob | Remove-Job -Force
                Write-Host "  Scan excedio 5 min - cancelled." -ForegroundColor Yellow
                $script:DefenderResult = "Scan cancelled by timeout (5 min)"
                Write-Log "Defender scan: timeout 5 min" "WARN"
                return
            }
            $scanJob | Receive-Job -EA SilentlyContinue
            $scanJob | Remove-Job -Force
            
            Write-Host "  Scan completed." -ForegroundColor Green
            $threats = Get-MpThreatDetection -EA SilentlyContinue
            $recent = $threats | Where-Object { $_.InitialDetectionTime -gt (Get-Date).AddDays(-7) }
            if ($recent) {
                $script:DefenderResult = "$(@($recent).Count) amenaza(s) reciente(s) detectada(s)"
                Write-Host "  [!] $($script:DefenderResult)" -ForegroundColor Red
                foreach ($th in $recent | Select-Object -First 3) {
                    Write-Host "      - $($th.ThreatName)" -ForegroundColor Red
                }
                Write-Log "amenaza found: $(@($recent).Count) threat(s)" "ERROR"
            } else {
                $script:DefenderResult = "Sin amenazas detectadas"
                Write-Host "  Sin amenazas." -ForegroundColor Green
                Write-Log "Defender scan: limpio" "OK"
            }
        } catch {
            $script:DefenderResult = "Scan no disponible"
            Write-Host "  Defender no disponible." -ForegroundColor Yellow
            Write-Log "Defender scan fallo: $_" "WARN"
        }
    }},

    @{ Num=13; Title="BATTERY REPORT (LAPTOPS)"; Est=10; Code={
        $battery = Get-CimInstance Win32_Battery -EA SilentlyContinue
        if (-not $battery) {
            Write-Host "  No battery detected (desktop computer)." -ForegroundColor Gray
            $script:BatteryInfo = "Desktop computer - N/A"
            Write-Log "Battery: desktop computer, skipped" "OK"
            return
        }
        $charge = $battery.EstimatedChargeRemaining
        $status = switch ($battery.BatteryStatus) { 1{"Descargando"} 2{"Cargando"} 3{"Carga completa"} default{"Desconocido"} }
        Write-Host "  Battery: ${charge}% - $status" -ForegroundColor $(if($charge -lt 30){"Red"}elseif($charge -lt 60){"Yellow"}else{"Green"})
        $battPath = "$env:USERPROFILE\Desktop\battery-report.html"
        Start-Process "powercfg.exe" -ArgumentList "/batteryreport /output `"$battPath`"" -NoNewWindow -Wait
        if (Test-Path $battPath) {
            Write-Host "  Report: $battPath" -ForegroundColor Green
            $script:BatteryInfo = "${charge}% ($status) - Report en Desktop"
        } else { $script:BatteryInfo = "${charge}% ($status)" }
        Write-Log "Battery: ${charge}% $status" "OK"
    }},

    @{ Num=14; Title="LIMPIEZA PROFUNDA (WINSXS)"; Est=240; Code={
        $DiskBefore = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $FreeBefore = $DiskBefore.FreeSpace
        Write-Host "  Cleaning WinSxS (may take a while)..." -ForegroundColor Cyan
        $DISM = Start-Process "dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup" -NoNewWindow -Wait -PassThru
        if ($DISM.ExitCode -ne 0) { Write-Log "DISM WinSxS finalizo con codigo $($DISM.ExitCode)" "WARN" }
        $DiskAfter = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $Diff = [math]::Round(($DiskAfter.FreeSpace - $FreeBefore) / 1MB, 2)
        if ($Diff -lt 0) { $Diff = 0 }
        $script:SxSResult = "Espacio liberado: $Diff MB"
        Write-Host "  -> $($script:SxSResult)" -ForegroundColor Green
        Write-Log "WinSxS: $($script:SxSResult)" "OK"
    }},

    @{ Num=15; Title="OPTIMIZACION UNIDADES (TRIM/DEFRAG)"; Est=300; Code={
        Write-Host "  Optimizando unidades..." -ForegroundColor Cyan
        $Drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($Disk in $Drives) {
            $DriveLtr = $Disk.DeviceID.Replace(":", "")
            $DriveLabel = $Disk.DeviceID
            Write-Host "  -> Processing ${DriveLabel}..." -NoNewline
            try {
                Optimize-Volume -DriveLetter $DriveLtr -Verbose -ErrorAction Stop | Out-Null
                Write-Host " [OK]" -ForegroundColor Green
                Write-Log "Optimize-Volume ${DriveLabel} completed." "OK"
            } catch {
                Write-Host " [INFO] Managed by Windows." -ForegroundColor Gray
                Write-Log "Optimize-Volume ${DriveLabel} - $($_.Exception.Message)" "WARN"
            }
        }
    }}
)

# --- 11. EJECUCIÓN AUTOMÁTICA ---
function Run-AutoMode {
    $script:AutoLog.Clear()
    $TotalSteps = $script:TaskDefinitions.Count
    $TotalEstSec = ($script:TaskDefinitions | ForEach-Object { $_.Est } | Measure-Object -Sum).Sum
    $StartTime = Get-Date
    $EstMin = [math]::Round($TotalEstSec / 60, 0)
    
    Write-Log "=== INICIO MANTENIMIENTO AUTOMATICO ===" "INFO"
    Write-Log "Cliente: $($script:ClientName) | Computer: $env:COMPUTERNAME | User: $env:USERNAME" "INFO"
    Write-Log "Tiempo estimado: ~$EstMin minutos" "INFO"
    
    # Orden optimizado: Defender (12) antes de Red reset (11) para evitar conflicto
    $AutoOrder = @(0,1,2,3,4,5,6,7,8,9, 11,10, 12,13,14)
    
    for ($i = 0; $i -lt $TotalSteps; $i++) {
        $Task = $script:TaskDefinitions[$AutoOrder[$i]]
        $StepNum = $i + 1
        $Elapsed = [int]((Get-Date) - $StartTime).TotalSeconds
        
        Show-AutoProgress -Step $StepNum -Total $TotalSteps -TaskName $Task.Title -ElapsedSec $Elapsed -EstTotalSec $TotalEstSec
        
        Write-Log "--- Paso $StepNum de ${TotalSteps}: $($Task.Title) ---" "INFO"
        $StepStart = Get-Date
        $TaskResult = Run-Task-Safe -Title $Task.Title -ScriptBlock $Task.Code -AutoMode
        $Duration = [math]::Round(((Get-Date) - $StepStart).TotalSeconds, 1)
        
        $Num = $Task.Num
        if ($TaskResult) {
            Set-Variable -Name "s$Num" -Value "[OK]" -Scope Script
            Set-Variable -Name "c$Num" -Value "Green" -Scope Script
            Write-Log "Paso $StepNum completed en ${Duration}s" "OK"
        } else {
            Set-Variable -Name "s$Num" -Value "[FAIL]" -Scope Script
            Set-Variable -Name "c$Num" -Value "Red" -Scope Script
            Write-Log "Paso $StepNum FALLO (${Duration}s)" "ERROR"
        }
        Set-Variable -Name "Run$Num" -Value $true -Scope Script
    }
    
    $TotalDuration = [math]::Round(((Get-Date) - $StartTime).TotalMinutes, 1)
    Write-Log "=== FIN MANTENIMIENTO AUTOMATICO ($TotalDuration min) ===" "INFO"
    
    try { [System.Media.SystemSounds]::Exclamation.Play() } catch {}
    
    Clear-Host
    $w = $Host.UI.RawUI.WindowSize.Width; if ($w -le 0) { $w = 80 }
    Write-Host "`n"
    $done = "MANTENIMIENTO COMPLETO"
    $pad = [math]::Max(0, [int](($w - $done.Length) / 2))
    Write-Host (" " * $pad + $done) -ForegroundColor Green
    Write-Host ("=" * $w) -ForegroundColor DarkGray
    Write-Host "  Cliente: $($script:ClientName)" -ForegroundColor Cyan
    Write-Host ""
    
    $ErrC = @($script:AutoLog | Where-Object { $_ -match "\[ERROR\]" }).Count
    $WrnC = @($script:AutoLog | Where-Object { $_ -match "\[WARN\]" }).Count
    $OkC  = @($script:AutoLog | Where-Object { $_ -match "\[OK\]" }).Count
    
    Write-Host "  Resultados:" -ForegroundColor White
    Write-Host "    $([char]0x2714) Exitosos:  $OkC" -ForegroundColor Green
    Write-Host "    $([char]0x26A0) Warnings:    $WrnC" -ForegroundColor Yellow
    Write-Host "    $([char]0x2718) Errores:   $ErrC" -ForegroundColor Red
    Write-Host "    $([char]0x23F1) Duracion:  $TotalDuration minutos" -ForegroundColor Cyan
    Write-Host ""
    
    $Recs = Get-Recommendations
    if ($Recs.Count -gt 0) {
        Write-Host "  -- RECOMENDACIONES --" -ForegroundColor Yellow
        foreach ($rec in $Recs) {
            $prioColor = switch ($rec.Priority) { 'Critica'{"Red"} 'Alta'{"Red"} 'Media'{"Yellow"} default{"Gray"} }
            Write-Host "    [$($rec.Priority)] $($rec.Detail) - $($rec.Diagnosis)" -ForegroundColor $prioColor
            Write-Host "      -> $($rec.Action)" -ForegroundColor White
        }
        Write-Host ""
    }
    
    if ($ErrC -gt 0) {
        Write-Host "  -- ERRORES --" -ForegroundColor Red
        $script:AutoLog | Where-Object { $_ -match "\[ERROR\]" } | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        Write-Host ""
    }
    
    $FechaFile = Get-Date -Format "yyyyMMdd_HHmm"
    $LogPath = "$env:USERPROFILE\Desktop\Log_$($env:COMPUTERNAME)_${FechaFile}.txt"
    $script:AutoLog | Out-File $LogPath -Encoding UTF8
    Write-Host "  [LOG] $LogPath" -ForegroundColor Gray
    
    Generar-Report -IncluirLog $true
    
    _Wait-AtlasExitCompat -Message "Press Enter to exit..."
    Exit
}

# --- 12. BUCLE PRINCIPAL ---
do {
    Show-Header
    Show-Menu-Frame
    
    Write-Host " Seleccione option (0=Report, 16=Auto) > " -NoNewline -ForegroundColor Yellow
    $Sel = Read-Host

    switch ($Sel) {
        { $_ -in "1","2","3","4","5","6","7","8","9","10","11","12","13","14","15" } {
            $idx = [int]$Sel - 1
            $Task = $script:TaskDefinitions[$idx]
            $Res = Run-Task-Safe -Title $Task.Title -ScriptBlock $Task.Code
            $N = $Task.Num
            if ($Res) { Set-Variable -Name "s$N" -Value "[OK]" -Scope Script; Set-Variable -Name "c$N" -Value "Green" -Scope Script }
            else      { Set-Variable -Name "s$N" -Value "[FAIL]" -Scope Script; Set-Variable -Name "c$N" -Value "Red" -Scope Script }
            Set-Variable -Name "Run$N" -Value $true -Scope Script
        }
        "16" { Run-AutoMode }
        "0" {
            Write-Host "`n  Generating report..." -ForegroundColor Yellow
            Generar-Report -IncluirLog ($script:AutoLog.Count -gt 0)
            Start-Sleep 2; Exit
        }
        "Q" { Exit }
        "q" { Exit }
        default { Write-Host "`n  Option no valida." -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($true)

}
