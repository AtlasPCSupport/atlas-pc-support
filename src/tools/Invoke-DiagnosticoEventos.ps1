function Invoke-DiagnosticoEventos {
    <#
    .SYNOPSIS
      Event Log Analyzer: reads the Windows Event Viewer and explains
      common errors in plain language with a suggested action.

    .DESCRIPTION
      - Filters events by category (reboots, hardware, crashes, drivers, security).
      - Translates the most common EventIDs into plain language + severity + recommendation.
      - Exports an HTML report to share with a customer or archive.
      - Runs isolated (ToolRunner), independent of launcher libraries.
      - Bilingual (en default + full es). Function name preserved for tools.json.
    #>

    $ErrorActionPreference = 'Stop'

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
            HeaderBar    = '================================================================'
            HeaderTitle  = '  Event Log Analyzer (Windows Event Viewer)'
            ComputerLbl  = 'Computer'
            Menu1        = '  [1] Recent critical errors (24h)'
            Menu2        = '  [2] Unexpected reboots (7d)'
            Menu3        = '  [3] Hardware (WHEA / Disk) (7d)'
            Menu4        = '  [4] App crashes (7d)'
            Menu5        = '  [5] Drivers (7d)'
            Menu6        = '  [6] Security (7d) [requires admin]'
            Menu7        = '  [7] Export HTML report (last 7d)'
            Menu8        = '  [8] Look up by EventID (knowledge base)'
            MenuQ        = '  [Q] Quit'
            OptPrompt    = '  Option'
            EnterBack    = "`n  ENTER to go back"
            Section1     = 'Critical / Errors (System + Application, 24h)'
            Section2     = 'Unexpected reboots (7d)'
            Section3     = 'Hardware WHEA + Disk (7d)'
            Section4     = 'Application crashes (7d)'
            Section5     = 'Failed drivers (7d)'
            Section6     = 'Security (7d)'
            SecDenied    = '  [X] Access to Security log denied: {0}'
            SecRetry     = '      Relaunch the panel as Administrator.'
            HtmlBuilding = '  Generating HTML report (last 7d)... 5-15s...'
            HtmlSaved    = '  [OK] Saved: {0}'
            HtmlError    = '  [X] Error: {0}'
            AskEventId   = '  EventID to look up (e.g. 41, 6008, 4625)'
            BadId        = '  [X] Invalid ID.'
            EnterPrompt  = "`n  ENTER"
            KbLine1      = '  [{0}] EventID {1} - {2}'
            KbSeverity   = '      Severity : {0}'
            KbCause      = '      Cause    : {0}'
            KbAction     = '      Action   : {0}'
            KbNotInDB    = '  [i] EventID {0} is not in the knowledge base.'
            KbGoogle     = '      Look it up at: https://www.google.com/search?q=windows+event+id+{0}'
            KbRecent     = '  Recent occurrences in System + Application (last 30d, top 5)...'
            KbNoneRecent = '    (none in the last 30 days)'
            NoEvents     = '    (no events in the queried range)'
            FieldProvider= 'Provider'
            FieldEventId = 'EventID'
            FieldLast    = 'Latest'
            FieldCause   = 'Cause'
            FieldAction  = 'Action'
            HtmlTitle    = 'ATLAS PC SUPPORT - Event Log Analyzer'
            HtmlEquipo   = 'Computer'
            HtmlRange    = 'Range: last {0} days'
            HtmlGen      = 'Generated'
            HtmlPrint    = '🖨  Print / PDF'
            HtmlSecCrit  = 'Recent Criticals (System+App)'
            HtmlSecBoot  = 'Unexpected Reboots'
            HtmlSecHw    = 'Hardware (WHEA / Disk)'
            HtmlSecCrash = 'App Crashes'
            HtmlSecDrv   = 'Drivers'
            HtmlSecSec   = 'Security'
            HtmlNoEvents = 'No events.'
            HtmlLang     = 'en'
        }
        es = @{
            HeaderBar    = '================================================================'
            HeaderTitle  = '  Diagnostico Eventos (Windows Event Viewer)'
            ComputerLbl  = 'Equipo'
            Menu1        = '  [1] Ultimos errores criticos (24h)'
            Menu2        = '  [2] Reinicios inesperados (7d)'
            Menu3        = '  [3] Hardware (WHEA / Disk) (7d)'
            Menu4        = '  [4] App crashes (7d)'
            Menu5        = '  [5] Drivers (7d)'
            Menu6        = '  [6] Seguridad (7d) [requiere admin]'
            Menu7        = '  [7] Exportar reporte HTML (ultimos 7d)'
            Menu8        = '  [8] Buscar por EventID (base de conocimiento)'
            MenuQ        = '  [Q] Salir'
            OptPrompt    = '  Opcion'
            EnterBack    = "`n  ENTER para volver"
            Section1     = 'Criticos / Errores (System + Application, 24h)'
            Section2     = 'Reinicios inesperados (7d)'
            Section3     = 'Hardware WHEA + Disk (7d)'
            Section4     = 'Application crashes (7d)'
            Section5     = 'Drivers fallidos (7d)'
            Section6     = 'Seguridad (7d)'
            SecDenied    = '  [X] Acceso a Security log denegado: {0}'
            SecRetry     = '      Relanza el panel como Administrador.'
            HtmlBuilding = '  Generando reporte HTML (ultimos 7d)... puede tardar 5-15s...'
            HtmlSaved    = '  [OK] Guardado: {0}'
            HtmlError    = '  [X] Error: {0}'
            AskEventId   = '  EventID a buscar (ej. 41, 6008, 4625)'
            BadId        = '  [X] ID invalido.'
            EnterPrompt  = "`n  ENTER"
            KbLine1      = '  [{0}] EventID {1} - {2}'
            KbSeverity   = '      Severidad: {0}'
            KbCause      = '      Causa    : {0}'
            KbAction     = '      Accion   : {0}'
            KbNotInDB    = '  [i] EventID {0} no esta en la base de conocimiento.'
            KbGoogle     = '      Consulta en: https://www.google.com/search?q=windows+event+id+{0}'
            KbRecent     = '  Mostrando ocurrencias recientes en System + Application (30d, top 5)...'
            KbNoneRecent = '    (ninguna en los ultimos 30 dias)'
            NoEvents     = '    (sin eventos en el rango consultado)'
            FieldProvider= 'Provider'
            FieldEventId = 'EventID'
            FieldLast    = 'Ultima'
            FieldCause   = 'Causa'
            FieldAction  = 'Accion'
            HtmlTitle    = 'ATLAS PC SUPPORT - Diagnostico Eventos'
            HtmlEquipo   = 'Equipo'
            HtmlRange    = 'Rango: ultimos {0} dias'
            HtmlGen      = 'Generado'
            HtmlPrint    = '🖨  Imprimir / PDF'
            HtmlSecCrit  = 'Ultimos Criticos (System+App)'
            HtmlSecBoot  = 'Reinicios Inesperados'
            HtmlSecHw    = 'Hardware (WHEA / Disk)'
            HtmlSecCrash = 'App Crashes'
            HtmlSecDrv   = 'Drivers'
            HtmlSecSec   = 'Seguridad'
            HtmlNoEvents = 'Sin eventos.'
            HtmlLang     = 'es'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    # ----- Bilingual EventID knowledge base -----
    # Two parallel hashtables; we pick by language.
    $kbEn = @{
        '*|Microsoft-Windows-WHEA-Logger|1' = @{ Level='CRITICAL'; Title='Fatal hardware error'; Cause='Windows reported a hardware error. Inspect the original record, component, error source and type; this entry does not identify the failed part.'; Action='Preserve the event and correlate recurrence, workload, firmware and system settings before repair or replacement.' }
        '*|Microsoft-Windows-WHEA-Logger|17' = @{ Level='WARN'; Title='Corrected hardware error'; Cause='Windows reported a hardware error. Inspect the original record, component, error source and type; this entry does not identify the failed part.'; Action='Preserve the event and correlate recurrence, workload, firmware and system settings before repair or replacement.' }
        '*|Microsoft-Windows-WHEA-Logger|18' = @{ Level='CRITICAL'; Title='Fatal processor hardware error'; Cause='Windows reported a hardware error. Inspect the original record, component, error source and type; this entry does not identify the failed part.'; Action='Preserve the event and correlate recurrence, workload, firmware and system settings before repair or replacement.' }
        '*|Microsoft-Windows-WHEA-Logger|19' = @{ Level='WARN'; Title='Corrected processor hardware error'; Cause='The processor reported a corrected hardware error; inspect the original error source and type.'; Action='Correlate the event details, firmware, settings and workload before attributing a faulty component.' }
        '*|Microsoft-Windows-WHEA-Logger|46' = @{ Level='CRITICAL'; Title='Fatal memory hardware error'; Cause='WHEA reported a fatal memory-related hardware error; the event alone does not identify a replaceable faulty module.'; Action='Preserve the original event and data, protect important files and investigate memory/platform stability before further stress or replacement.' }
    }
    $kbEs = @{
        '*|Microsoft-Windows-WHEA-Logger|1' = @{ Level='CRITICAL'; Title='Error fatal de hardware'; Cause='Windows notifico un error de hardware. Revisar registro original, componente, origen y tipo; esta entrada no identifica la pieza defectuosa.'; Action='Conservar el evento y correlacionar recurrencia, carga, firmware y configuracion antes de reparar o reemplazar.' }
        '*|Microsoft-Windows-WHEA-Logger|17' = @{ Level='WARN'; Title='Error de hardware corregido'; Cause='Windows notifico un error de hardware. Revisar registro original, componente, origen y tipo; esta entrada no identifica la pieza defectuosa.'; Action='Conservar el evento y correlacionar recurrencia, carga, firmware y configuracion antes de reparar o reemplazar.' }
        '*|Microsoft-Windows-WHEA-Logger|18' = @{ Level='CRITICAL'; Title='Error fatal de hardware de procesador'; Cause='Windows notifico un error de hardware. Revisar registro original, componente, origen y tipo; esta entrada no identifica la pieza defectuosa.'; Action='Conservar el evento y correlacionar recurrencia, carga, firmware y configuracion antes de reparar o reemplazar.' }
        '*|Microsoft-Windows-WHEA-Logger|19' = @{ Level='WARN'; Title='Error de hardware de procesador corregido'; Cause='El procesador notifico un error corregido; revisar origen y tipo en el evento original.'; Action='Correlacionar detalles, firmware, configuracion y carga antes de atribuir un componente defectuoso.' }
        '*|Microsoft-Windows-WHEA-Logger|46' = @{ Level='CRITICAL'; Title='Error fatal de hardware relacionado con memoria'; Cause='WHEA notifico un error fatal relacionado con memoria; el evento solo no identifica un modulo reemplazable defectuoso.'; Action='Conservar evento y datos originales, proteger archivos importantes e investigar estabilidad de memoria/plataforma antes de mas estres o reemplazos.' }
    }
    $script:AtlasEventsKB = if ($lang -eq 'es') { $kbEs } else { $kbEn }

    function _Kb-Lookup {
        param([string]$LogName, [string]$Provider, [int]$EventId)
        if ($null -eq $script:AtlasEventsKB) { return $null }
        $keys = @(
            "$LogName|$Provider|$EventId",
            "*|$Provider|$EventId"
        )
        foreach ($k in $keys) {
            if ($script:AtlasEventsKB.ContainsKey($k)) { return $script:AtlasEventsKB[$k] }
        }
        return $null
    }

    function _Level-Color {
        param([string]$Level)
        switch ($Level) {
            'CRITICAL' { 'Red' }
            'WARN'     { 'Yellow' }
            'INFO'     { 'DarkCyan' }
            default    { 'Gray' }
        }
    }

    function _Level-Icon {
        param([string]$Level)
        switch ($Level) {
            'CRITICAL' { '[X]' }
            'WARN'     { '[!]' }
            'INFO'     { '[i]' }
            default    { '   ' }
        }
    }

    function _Query-Events {
        param(
            [string]$LogName = 'System',
            [int[]]$Levels = @(0,1,2,3,4),
            [int[]]$Ids = $null,
            [int]$Hours = 24,
            [int]$MaxEvents = 500
        )
        $since = (Get-Date).AddHours(-[int]$Hours)
        $filter = @{
            LogName      = $LogName
            Level        = $Levels
            StartTime    = $since
        }
        if ($Ids -and $Ids.Count -gt 0) { $filter['Id'] = $Ids }
        try {
            return @(Get-WinEvent -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction Stop)
        } catch {
            if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { return @() }
            throw "Event log $LogName was not evaluated: $($_.Exception.Message)"
        }
    }

    function _Render-Events {
        param([array]$Events, [string]$Heading)
        Write-Host ''
        Write-Host "  --- $Heading ---" -ForegroundColor Cyan
        if (-not $Events -or $Events.Count -eq 0) {
            Write-Host $L.NoEvents -ForegroundColor DarkGray
            return
        }
        $groups = $Events | Group-Object ProviderName, Id | Sort-Object Count -Descending
        foreach ($g in $groups) {
            $first = $g.Group[0]
            $kb = _Kb-Lookup $first.LogName $first.ProviderName ([int]$first.Id)
            $level = if ($first.Level -in @(1,2)) { 'CRITICAL' } elseif ($first.Level -eq 3) { 'WARN' } elseif ($first.Level -eq 4) { 'INFO' } else { 'UNKNOWN' }
            $icon  = _Level-Icon $level
            $color = _Level-Color $level
            $title = if ($kb) { $kb.Title } else { "$($first.ProviderName) #$($first.Id)" }
            Write-Host ''
            Write-Host ("  $icon $title  [x$($g.Count)]") -ForegroundColor $color
            Write-Host ("     $($L.FieldProvider): $($first.ProviderName) - $($L.FieldEventId): $($first.Id) - $($L.FieldLast): $($first.TimeCreated.ToString('yyyy-MM-dd HH:mm'))") -ForegroundColor DarkGray
            if ($kb) {
                Write-Host ("     $($L.FieldCause) (hypothesis, correlate original event): $($kb.Cause)") -ForegroundColor Gray
                Write-Host ("     $($L.FieldAction): $($kb.Action)") -ForegroundColor White
            } else {
                $msg = ($first.Message -replace "`r?`n", ' ').Trim()
                if ($msg.Length -gt 180) { $msg = $msg.Substring(0,177) + '...' }
                Write-Host ("     $msg") -ForegroundColor Gray
            }
        }
    }

    function _Build-HtmlReport {
        param([string]$OutPath, [int]$Hours = 168)
        $sections = [ordered]@{}
        $sections[$L.HtmlSecCrit]  = (_Query-Events -LogName 'System'      -Levels @(1,2) -Hours $Hours -MaxEvents 200) +
                                     (_Query-Events -LogName 'Application' -Levels @(1,2) -Hours $Hours -MaxEvents 200)
        $sections[$L.HtmlSecBoot]  = _Query-Events -LogName 'System' -Ids @(41,6008,6006,1074) -Hours $Hours -MaxEvents 200
        $sections[$L.HtmlSecHw]    = _Query-Events -LogName 'System' -Ids @(1,17,18,19,46,47,7,51,52,55,153) -Hours $Hours -MaxEvents 200
        $sections[$L.HtmlSecCrash] = _Query-Events -LogName 'Application' -Ids @(1000,1001,1026) -Hours $Hours -MaxEvents 200
        $sections[$L.HtmlSecDrv]   = _Query-Events -LogName 'System' -Ids @(219,7026) -Hours $Hours -MaxEvents 200

        $securityState = 'Observed'
        try {
            $sec = _Query-Events -LogName 'Security' -Ids @(4625,4720,4726,4724,4740) -Hours $Hours -MaxEvents 200
            $sections[$L.HtmlSecSec] = @($sec)
        } catch { $securityState = 'NotEvaluated'; $sections[$L.HtmlSecSec] = @() }

        $hostName  = $env:COMPUTERNAME
        $generated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        $days = [int]([math]::Round($Hours/24))

        $htmlSections = ''
        foreach ($title in $sections.Keys) {
            $events = @($sections[$title])
            $htmlSections += "<section><h2>$([System.Net.WebUtility]::HtmlEncode($title)) <span class='count'>(" + $events.Count + ")</span></h2>"
            if ($title -eq $L.HtmlSecSec -and $securityState -eq 'NotEvaluated') {
                $htmlSections += '<p class="muted">NotEvaluated: Security log unavailable; check access and policy.</p></section>'
                continue
            }
            if ($events.Count -eq 0) {
                $htmlSections += "<p class='muted'>$($L.HtmlNoEvents)</p></section>"
                continue
            }
            $groups = $events | Group-Object ProviderName, Id | Sort-Object Count -Descending
            $htmlSections += "<div class='events'>"
            foreach ($g in $groups) {
                $first = $g.Group[0]
                $kb = _Kb-Lookup $first.LogName $first.ProviderName ([int]$first.Id)
                $level = if ($first.Level -in @(1,2)) { 'CRITICAL' } elseif ($first.Level -eq 3) { 'WARN' } elseif ($first.Level -eq 4) { 'INFO' } else { 'UNKNOWN' }
                $cls = $level.ToLower()
                $evTitle = if ($kb) { $kb.Title } else { "$($first.ProviderName) #$($first.Id)" }
                $cause  = if ($kb) { [System.Net.WebUtility]::HtmlEncode($kb.Cause)  } else { '' }
                $action = if ($kb) { [System.Net.WebUtility]::HtmlEncode($kb.Action) } else { '' }
                $rawMsg = [System.Net.WebUtility]::HtmlEncode((($first.Message -replace "`r?`n", ' ').Trim()))
                if ($rawMsg.Length -gt 300) { $rawMsg = $rawMsg.Substring(0,297) + '...' }
                $htmlSections += "<div class='event $cls'>"
                $htmlSections += "<div class='ev-head'><span class='lvl'>$level</span><span class='ev-title'>$(([System.Net.WebUtility]::HtmlEncode($evTitle)))</span><span class='count'>x$($g.Count)</span></div>"
                $htmlSections += "<div class='meta'>$($L.FieldProvider): <code>$([System.Net.WebUtility]::HtmlEncode($first.ProviderName))</code> - $($L.FieldEventId): <code>$($first.Id)</code> - $($L.FieldLast): <code>$($first.TimeCreated.ToString('yyyy-MM-dd HH:mm'))</code></div>"
                if ($kb) {
                    $htmlSections += "<div class='kb'><div><strong>$($L.FieldCause):</strong> $cause</div><div><strong>$($L.FieldAction):</strong> $action</div></div>"
                } else {
                    $htmlSections += "<div class='kb'><div class='raw'>$rawMsg</div></div>"
                }
                $htmlSections += '</div>'
            }
            $htmlSections += '</div></section>'
        }

        $htmlLang = $L.HtmlLang
        $htmlTitle = $L.HtmlTitle
        $htmlEquipo = $L.HtmlEquipo
        $htmlRangeStr = ($L.HtmlRange -f $days)
        $htmlGenLbl = $L.HtmlGen
        $htmlPrintLbl = $L.HtmlPrint

        $html = @"
<!DOCTYPE html>
<html lang="$htmlLang"><head><meta charset="utf-8"/>
<title>$htmlTitle - $hostName</title>
<style>
  :root{--bg:#0f141b;--surf:#171d26;--surf2:#1e2631;--bord:#2c3444;--acc:#3b82f6;--text:#e5e7eb;--mut:#9ca3af;--ok:#22c55e;--warn:#eab308;--err:#ef4444}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.5}
  .wrap{max-width:1000px;margin:0 auto;padding:24px}
  header{background:linear-gradient(135deg,var(--acc),#1d4ed8);color:white;padding:28px;border-radius:10px;margin-bottom:20px;box-shadow:0 6px 24px rgba(59,130,246,.25)}
  header h1{margin:0 0 4px;font-size:26px;letter-spacing:-.5px}
  header .meta{opacity:.8;font-size:12px;margin-top:8px}
  section{background:var(--surf);border:1px solid var(--bord);border-radius:10px;padding:18px 22px;margin-bottom:16px}
  section h2{margin:0 0 12px;font-size:15px;color:#60a5fa;text-transform:uppercase;letter-spacing:.5px;border-bottom:1px solid var(--bord);padding-bottom:8px}
  section h2 .count{color:var(--mut);font-size:12px;font-weight:400;margin-left:8px}
  .event{background:var(--surf2);border-radius:8px;padding:12px 14px;margin:8px 0;border-left:4px solid var(--bord)}
  .event.critical{border-left-color:var(--err)}
  .event.warn{border-left-color:var(--warn)}
  .event.info{border-left-color:#60a5fa}
  .ev-head{display:flex;align-items:center;gap:10px;margin-bottom:4px}
  .lvl{font-size:10px;font-weight:700;padding:2px 7px;border-radius:4px;background:var(--bord);color:white;text-transform:uppercase;letter-spacing:.5px}
  .event.critical .lvl{background:var(--err)}
  .event.warn .lvl{background:var(--warn);color:#1a1300}
  .event.info .lvl{background:#60a5fa;color:#0a1828}
  .ev-title{flex:1;font-weight:600;font-size:14px}
  .count{color:var(--mut);font-size:12px}
  .meta{color:var(--mut);font-size:11px;margin-bottom:6px}
  code{background:#0d121a;padding:1px 6px;border-radius:3px;color:#cbd5e1;font-size:11px}
  .kb{font-size:12.5px;line-height:1.55}
  .kb div{margin:3px 0}
  .kb strong{color:#60a5fa}
  .kb .raw{color:var(--mut);font-style:italic;font-size:12px}
  .muted{color:var(--mut);font-style:italic}
  .toolbar{position:sticky;top:10px;z-index:10;text-align:right;margin-bottom:12px}
  .btn{background:var(--acc);color:white;border:0;border-radius:6px;padding:9px 16px;font-size:12px;cursor:pointer;font-weight:500}
  .btn:hover{background:#60a5fa}
  @media print{
    body{background:white !important;color:black !important;font-size:11pt}
    header{background:white !important;color:black !important;border:2px solid #333;box-shadow:none}
    header h1{color:#1d4ed8 !important}
    section{background:white !important;border:1px solid #999 !important;color:black !important;page-break-inside:avoid}
    section h2{color:#1d4ed8 !important;border-color:#999}
    .event{background:#f7f8fa !important;color:black !important;break-inside:avoid}
    .event.critical{border-left:4px solid #c00 !important}
    .event.warn{border-left:4px solid #c90 !important}
    .meta,.muted{color:#555 !important}
    code{background:#eee !important;color:#333 !important}
    .kb strong{color:#1d4ed8 !important}
    .toolbar,.no-print{display:none !important}
  }
</style></head><body>
<div class="wrap">
<div class="toolbar no-print"><button class="btn" onclick="window.print()">$htmlPrintLbl</button></div>
<header>
  <h1>$htmlTitle</h1>
  <div>$htmlEquipo`: <strong>$hostName</strong> - $htmlRangeStr</div>
  <div class="meta">$htmlGenLbl`: $generated</div>
</header>
$htmlSections
</div></body></html>
"@

        Write-AtlasShareableReport -Path $OutPath -Content $html -Tool 'Event log observations'
        return $OutPath
    }

    function Show-DEHeader {
        Clear-Host
        Write-Host ''
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title ($L.HeaderTitle.Trim()) -Color Yellow
            Write-AtlasStep ("{0}: {1}" -f $L.ComputerLbl, $env:COMPUTERNAME)
            Write-Host ''
            return
        }
        Write-Host $L.HeaderBar -ForegroundColor Cyan
        Write-Host $L.HeaderTitle -ForegroundColor Cyan
        Write-Host $L.HeaderBar -ForegroundColor Cyan
        Write-Host ''
        Write-Host "  $($L.ComputerLbl): $env:COMPUTERNAME"
        Write-Host ''
    }

    function Pause-DE {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

    while ($true) {
        Show-DEHeader
        Write-Host $L.Menu1 -ForegroundColor White
        Write-Host $L.Menu2 -ForegroundColor White
        Write-Host $L.Menu3 -ForegroundColor White
        Write-Host $L.Menu4 -ForegroundColor White
        Write-Host $L.Menu5 -ForegroundColor White
        Write-Host $L.Menu6 -ForegroundColor White
        Write-Host $L.Menu7 -ForegroundColor Yellow
        Write-Host $L.Menu8 -ForegroundColor White
        Write-Host $L.MenuQ -ForegroundColor DarkGray
        Write-Host ''
        $opt = Read-Host $L.OptPrompt
        $opt = $opt.Trim().ToUpper()

        switch ($opt) {
            '1' {
                $a = _Query-Events -LogName 'System'      -Levels @(1,2) -Hours 24 -MaxEvents 200
                $b = _Query-Events -LogName 'Application' -Levels @(1,2) -Hours 24 -MaxEvents 200
                _Render-Events @($a + $b) $L.Section1
                Pause-DE -Message $L.EnterBack
            }
            '2' {
                $e = _Query-Events -LogName 'System' -Ids @(41,6008,6006,1074) -Hours 168 -MaxEvents 200
                _Render-Events $e $L.Section2
                Pause-DE -Message $L.EnterBack
            }
            '3' {
                $e = _Query-Events -LogName 'System' -Ids @(1,17,18,19,46,47,7,51,52,55,153) -Hours 168 -MaxEvents 300
                _Render-Events $e $L.Section3
                Pause-DE -Message $L.EnterBack
            }
            '4' {
                $e = _Query-Events -LogName 'Application' -Ids @(1000,1001,1026) -Hours 168 -MaxEvents 300
                _Render-Events $e $L.Section4
                Pause-DE -Message $L.EnterBack
            }
            '5' {
                $e = _Query-Events -LogName 'System' -Ids @(219,7026) -Hours 168 -MaxEvents 200
                _Render-Events $e $L.Section5
                Pause-DE -Message $L.EnterBack
            }
            '6' {
                try {
                    $e = _Query-Events -LogName 'Security' -Ids @(4625,4720,4726,4724,4740) -Hours 168 -MaxEvents 300
                    _Render-Events $e $L.Section6
                } catch {
                    Write-Host ''
                    Write-Host ($L.SecDenied -f $_.Exception.Message) -ForegroundColor Red
                    Write-Host $L.SecRetry -ForegroundColor DarkGray
                }
                Pause-DE -Message $L.EnterBack
            }
            '7' {
                $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $desktop = [Environment]::GetFolderPath('Desktop')
                $out = Join-Path $desktop "atlas-events-$env:COMPUTERNAME-$stamp.html"
                Write-Host ''
                Write-Host $L.HtmlBuilding -ForegroundColor Yellow
                try {
                    $saved = _Build-HtmlReport -OutPath $out -Hours 168
                    Write-Host ($L.HtmlSaved -f $saved) -ForegroundColor Green
                    try { Start-Process $saved } catch {}
                } catch {
                    Write-Host ($L.HtmlError -f $_.Exception.Message) -ForegroundColor Red
                }
                Pause-DE -Message $L.EnterBack
            }
            '8' {
                Write-Host ''
                $idTxt = Read-Host $L.AskEventId
                $idN = 0
                if (-not [int]::TryParse($idTxt, [ref]$idN)) {
                    Write-Host $L.BadId -ForegroundColor Red
                    Pause-DE -Message $L.EnterPrompt
                    continue
                }
                $provider = (Read-Host 'Exact event provider (Enter: observations only) / Proveedor exacto').Trim()
                $kb = if ($provider -and $provider -ne '*') { _Kb-Lookup '*' $provider $idN } else { $null }
                Write-Host 'Event IDs are provider-specific. Causes are hypotheses; inspect the original event. / El ID depende del proveedor.' -ForegroundColor Yellow
                Write-Host ''
                if ($kb) {
                    $color = _Level-Color $kb.Level
                    Write-Host ($L.KbLine1 -f (_Level-Icon $kb.Level), $idN, $kb.Title) -ForegroundColor $color
                    Write-Host ($L.KbSeverity -f $kb.Level) -ForegroundColor $color
                    Write-Host ($L.KbCause    -f $kb.Cause) -ForegroundColor Gray
                    Write-Host ($L.KbAction   -f $kb.Action) -ForegroundColor White
                } else {
                    Write-Host ($L.KbNotInDB -f $idN) -ForegroundColor Yellow
                    Write-Host ($L.KbGoogle  -f $idN) -ForegroundColor DarkGray
                }
                Write-Host ''
                Write-Host $L.KbRecent -ForegroundColor DarkGray
                $combined = @()
                foreach ($log in @('System','Application')) {
                    $r = _Query-Events -LogName $log -Ids @($idN) -Levels @(1,2,3,4) -Hours 720 -MaxEvents 20
                    $combined += $r
                }
                if ($combined.Count -eq 0) {
                    Write-Host $L.KbNoneRecent -ForegroundColor DarkGray
                } else {
                    $combined | Sort-Object TimeCreated -Descending | Select-Object -First 5 | ForEach-Object {
                        $msg = ($_.Message -replace "`r?`n", ' ').Trim()
                        if ($msg.Length -gt 140) { $msg = $msg.Substring(0,137) + '...' }
                        Write-Host ("    - $($_.TimeCreated.ToString('yyyy-MM-dd HH:mm')) [$($_.LogName)] $msg") -ForegroundColor DarkGray
                    }
                }
                Pause-DE -Message $L.EnterBack
            }
            'Q' { return }
            default { }
        }
    }
}
