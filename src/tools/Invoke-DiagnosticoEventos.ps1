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
        '*|*|41' = @{ Level='CRITICAL'; Title='Kernel-Power: unexpected shutdown'; Cause='The system powered off without flushing. Typical causes: power outage, faulty PSU, overheating, silent BSOD, hardware reset button.'; Action='Check CPU/GPU temperatures (Parts Upgrade tool). If there was a BSOD: analyze C:\Windows\Minidump\*.dmp with WinDbg or BlueScreenView. If recurring: bench-test the PSU.' }
        '*|*|6008' = @{ Level='WARN'; Title='Previous shutdown was unexpected'; Cause='The PC turned off without a clean shutdown. Normal after a Kernel-Power 41.'; Action='Correlate with event 41 on the same date. If there is no 41, may be a power cut or hardware reset.' }
        '*|*|6006' = @{ Level='INFO'; Title='Event Log stopped (clean shutdown)'; Cause='The Event Log service stopped cleanly. Happens on every shutdown.'; Action='Informational. Its absence next to a 6008 indicates a dirty reboot.' }
        '*|*|1074' = @{ Level='INFO'; Title='Reboot/shutdown initiated by user or app'; Cause='Some process requested the reboot. The message states who (e.g. "Windows Update", "user X", "explorer.exe").'; Action='If you do not recognize the initiator: may be Windows Update (normal) or malware forcing a reboot.' }
        '*|*|1001' = @{ Level='WARN'; Title='Windows Error Reporting / Bugcheck'; Cause='A BSOD crash was reported. The message contains the stopcode (e.g. 0x0000001A = MEMORY_MANAGEMENT).'; Action='Look up the stopcode in the message. Quick table: 0x3B=driver, 0x7E=SYSTEM_THREAD, 0x1A=RAM, 0x9F=power/driver, 0x133=DPC_WATCHDOG (slow IO).' }
        '*|*|1000' = @{ Level='WARN'; Title='Application Error (app crashed)'; Cause='An application closed unexpectedly. The message names the exe + faulty module + address.'; Action='If it always recurs with the same exe: reinstall the app. If ntdll.dll is faulty module: may be hardware (RAM/disk).' }
        '*|*|1026' = @{ Level='WARN'; Title='.NET Runtime: unhandled exception'; Cause='.NET app crashed with an unhandled exception (StackOverflow, OOM, InvalidOperationException, etc.).'; Action='Check the stacktrace in the message. StackOverflow: infinite recursion in third-party code.' }
        '*|*|219' = @{ Level='WARN'; Title='Driver failed to load'; Cause='A signed driver failed to initialize. The message names the driver.'; Action='Open Device Manager, find the device. Reinstall a fresh driver from the vendor (NOT Windows Update if needed).' }
        '*|*|7026' = @{ Level='WARN'; Title='Boot-start driver failed'; Cause='One or more essential boot drivers did not load.'; Action='Critical if the driver is for storage (AHCI, NVMe). Check the message: antivirus/VPN/virtualization is usually harmless.' }
        '*|*|7001' = @{ Level='WARN'; Title='Service dependency failed'; Cause='A service did not start because a service it depended on failed.'; Action='Open services.msc and try a manual start. Sometimes indicates broken WMI (repair with winmgmt /resetrepository).' }
        '*|*|7031' = @{ Level='WARN'; Title='Service crashed'; Cause='A Windows service terminated unexpectedly.'; Action='If recurring: re-enable from services.msc or uninstall associated app. If Explorer/Shell: sfc /scannow + dism.' }
        '*|*|7034' = @{ Level='WARN'; Title='Service ended without notice'; Cause='Similar to 7031 - service died without a clean shutdown.'; Action='Same as 7031.' }
        '*|*|7' = @{ Level='CRITICAL'; Title='Bad block on disk (Disk error)'; Cause='The physical disk has corrupt sectors. Typical message: "The device, \\Device\\HarddiskX, has a bad block".'; Action='URGENT. Run SMART check (CrystalDiskInfo). If health <100%, plan backup + replacement NOW. Parts Upgrade tool gives you the model.' }
        '*|*|51' = @{ Level='CRITICAL'; Title='Disk I/O error'; Cause='Windows had a read/write error on disk. Loose SATA cable, controller, or failing disk.'; Action='Check cables (open the case). SMART check. If NVMe: verify BIOS is up to date.' }
        '*|*|52' = @{ Level='WARN'; Title='Disk capacity low'; Cause='Free space below the critical threshold.'; Action='Deep Clean & Repair tool -> free up space.' }
        '*|*|55' = @{ Level='WARN'; Title='File system corrupt'; Cause='NTFS/ReFS detected structural corruption.'; Action='chkdsk C: /f (requires reboot). If recurring: disk is failing physically.' }
        '*|*|153' = @{ Level='WARN'; Title='IO operation retried'; Cause='IO operation to disk had to be retried. Early symptom of a dying drive.'; Action='SMART check is a priority. Plan replacement.' }
        '*|WHEA-Logger|1' = @{ Level='CRITICAL'; Title='Hardware error: CPU/Bus'; Cause='WHEA (Windows Hardware Error Architecture) detected an unrecoverable hardware fault. Typically CPU overheat, corrupt RAM, or unstable PCIe.'; Action='Test RAM with MemTest86 4+ passes. Check temperatures. BIOS to latest firmware.' }
        '*|WHEA-Logger|17' = @{ Level='WARN'; Title='Hardware error corrected'; Cause='Hardware error the system was able to correct (e.g. PCIe AER). Does not crash but indicates degradation.'; Action='If frequent: motherboard or expansion card issue. Reseat PCIe (GPU/SSD). BIOS update.' }
        '*|WHEA-Logger|18' = @{ Level='CRITICAL'; Title='Fatal hardware error (Machine Check)'; Cause='Machine Check Exception (MCE). CPU reports a fatal error. Hardware instability is highly likely.'; Action='Check CPU temp (HWiNFO). Remove OC. Test RAM. If recurring: CPU or board may be defective.' }
        '*|WHEA-Logger|19' = @{ Level='WARN'; Title='Hardware error corrected (PCIe)'; Cause='PCIe bus error corrected via AER.'; Action='GPU/SSD PCIe poorly seated or faulty cable. Reseat + BIOS update.' }
        '*|WHEA-Logger|46' = @{ Level='INFO'; Title='CPU thermal throttling'; Cause='CPU lowered frequency due to overheating.'; Action='Parts Upgrade tool -> see temps. Repaste + clean fans. Old laptop: nearly certain.' }
        '*|*|10016' = @{ Level='INFO'; Title='DCOM permissions error'; Cause='An app tried to call a COM component without permission. Almost always harmless.'; Action='Ignorable. Microsoft acknowledges it as noise. Do not touch DCOM permissions unless you have a concrete symptom.' }
        '*|Microsoft-Windows-Kernel-Boot|134' = @{ Level='INFO'; Title='Boot time recorded'; Cause='Windows recorded how long boot took. Informational.'; Action='If very high (>60s with SSD): startup defrag, sfc, review startup programs.' }
        '*|*|4625' = @{ Level='WARN'; Title='Logon failure'; Cause='Someone tried to log in with wrong credentials. Message contains source IP + attempted username.'; Action='If many and from external IPs: brute-force attack. Disable public RDP, use a VPN.' }
        '*|*|4720' = @{ Level='WARN'; Title='User account created'; Cause='A new local account was created.'; Action='Verify you created it. If not: malware / unauthorized access. See who created it.' }
        '*|*|4726' = @{ Level='WARN'; Title='User account deleted'; Cause='A local account was deleted.'; Action='Verify it was not accidental. If not yours: intrusion.' }
        '*|*|4724' = @{ Level='WARN'; Title='Admin password reset'; Cause='An admin reset another account password.'; Action='Normal in helpdesk. If you do not recognize source: unauthorized access.' }
        '*|*|4740' = @{ Level='INFO'; Title='Account locked by failed attempts'; Cause='Account lockout (policy).'; Action='User forgot password or attack attempt.' }
        '*|*|4672' = @{ Level='INFO'; Title='Special privileges assigned'; Cause='An admin logged in (normal).'; Action='Informational. Useful to audit who has access.' }
        '*|*|16' = @{ Level='INFO'; Title='Microsoft-Windows-Time-Service sync'; Cause='Late or failed NTP sync.'; Action='If recurring: restart w32time. sc config w32time start=auto + w32tm /resync.' }
        '*|*|36888' = @{ Level='INFO'; Title='Schannel fatal error'; Cause='TLS handshake failed. Common with old apps/browsers and sites that require TLS 1.2+.'; Action='If annoying: enable TLS 1.2 in Internet Options. Update Windows.' }
    }
    $kbEs = @{
        '*|*|41' = @{ Level='CRITICAL'; Title='Kernel-Power: apagado inesperado'; Cause='El sistema se apago sin flushear. Causas tipicas: corte de corriente, PSU defectuosa, sobrecalentamiento, BSOD silencioso, boton de reset fisico.'; Action='Revisa temperaturas CPU/GPU (tool Parts Upgrade). Si hay BSOD: analiza C:\Windows\Minidump\*.dmp con WinDbg o BlueScreenView. Si repite: test de PSU con multimetro.' }
        '*|*|6008' = @{ Level='WARN'; Title='Apagado anterior inesperado'; Cause='El PC se apago sin hacer shutdown limpio. Normal tras un 41 (Kernel-Power).'; Action='Correlaciona con evento 41 en la misma fecha. Si no hay 41, puede ser corte electrico o reset fisico.' }
        '*|*|6006' = @{ Level='INFO'; Title='Event Log detenido (apagado normal)'; Cause='El servicio Event Log fue detenido de forma limpia. Ocurre en cada shutdown.'; Action='Informativo. Si su ausencia contrasta con un 6008, hubo reboot sucio.' }
        '*|*|1074' = @{ Level='INFO'; Title='Reinicio/apagado iniciado por usuario o app'; Cause='Algun proceso pidio el reinicio. El mensaje dice quien (ej. "Windows Update", "usuario X", "explorer.exe").'; Action='Si no reconoces el iniciador: puede ser Windows Update (normal) o malware que fuerza reboot.' }
        '*|*|1001' = @{ Level='WARN'; Title='Windows Error Reporting / Bugcheck'; Cause='Un crash BSOD se reporto. El mensaje contiene el stopcode (ej. 0x0000001A = MEMORY_MANAGEMENT).'; Action='Mira el stopcode en el mensaje. Tabla rapida: 0x3B=driver, 0x7E=SYSTEM_THREAD, 0x1A=RAM, 0x9F=power/driver, 0x133=DPC_WATCHDOG (IO lento).' }
        '*|*|1000' = @{ Level='WARN'; Title='Application Error (app crashed)'; Cause='Una aplicacion se cerro inesperadamente. El mensaje indica el exe + modulo faulty + direccion.'; Action='Si se repite siempre con el mismo exe: reinstalar la app. Si es ntdll.dll como faulty module: puede ser hardware (RAM/disco).' }
        '*|*|1026' = @{ Level='WARN'; Title='.NET Runtime: excepcion no controlada'; Cause='App .NET crasheo con excepcion sin manejar (StackOverflow, OOM, InvalidOperationException, etc.).'; Action='Mira el stacktrace en el mensaje. Si es StackOverflow: recursion infinita en codigo de terceros.' }
        '*|*|219' = @{ Level='WARN'; Title='Driver fallo al cargar'; Cause='Un driver firmado fallo su inicializacion. Mensaje indica nombre del driver.'; Action='Abre Device Manager, busca el dispositivo con el driver problemarico. Reinstala driver fresh (fabricante, NO Windows Update si hace falta).' }
        '*|*|7026' = @{ Level='WARN'; Title='Boot-start driver fallo'; Cause='Uno o varios drivers esenciales no cargaron en arranque.'; Action='Critico si el driver es de disco (AHCI, NVMe). Revisa mensaje: si es antivirus/VPN/virtualizacion, probablemente inofensivo.' }
        '*|*|7001' = @{ Level='WARN'; Title='Servicio dependencia fallo'; Cause='Un servicio no arranco porque otro del que dependia fallo.'; Action='Mira services.msc, intenta start manual. A veces indica WMI roto (reparar con winmgmt /resetrepository).' }
        '*|*|7031' = @{ Level='WARN'; Title='Servicio crasheo'; Cause='Un servicio Windows terminio inesperadamente.'; Action='Si repite: rehabilitar via services.msc o desinstalar app asociada. Si es Explorer/Shell: sfc /scannow + dism.' }
        '*|*|7034' = @{ Level='WARN'; Title='Servicio termino sin previo aviso'; Cause='Similar a 7031 — servicio murio sin shutdown limpio.'; Action='Igual que 7031.' }
        '*|*|7' = @{ Level='CRITICAL'; Title='Bad block en disco (Disk error)'; Cause='El disco fisico tiene sectores corruptos. Mensaje tipico: "The device, \\Device\\HarddiskX, has a bad block".'; Action='URGENTE. Ejecuta SMART check (CrystalDiskInfo). Si salud no es 100%, plan backup + reemplazo de disco YA. Tool Parts Upgrade te da el modelo.' }
        '*|*|51' = @{ Level='CRITICAL'; Title='Disk I/O error'; Cause='Windows tuvo un error al leer/escribir al disco. Cable SATA suelto, controladora, o disco fallando.'; Action='Verifica cables (abre caja). SMART check. Si NVMe: revisa que la BIOS este actualizada.' }
        '*|*|52' = @{ Level='WARN'; Title='Disk capacidad baja'; Cause='Espacio libre menor al umbral critico.'; Action='Tool Mantenimiento PRO -> liberar espacio.' }
        '*|*|55' = @{ Level='WARN'; Title='File system corrupt'; Cause='NTFS/ReFS detecto corrupcion estructural.'; Action='chkdsk C: /f (requiere reboot). Si repite: disco fallando fisicamente.' }
        '*|*|153' = @{ Level='WARN'; Title='IO operation retried'; Cause='Operacion IO al disco tuvo que reintentarse. Sintoma temprano de disco moribundo.'; Action='SMART check prioritario. Plan de reemplazo.' }
        '*|WHEA-Logger|1' = @{ Level='CRITICAL'; Title='Hardware error: CPU/Bus'; Cause='WHEA (Windows Hardware Error Architecture) detecto fallo hardware no recuperable. Tipicamente CPU overheat, RAM corrupta, o PCIe inestable.'; Action='Test RAM con MemTest86 4+ pases. Check temperaturas. BIOS al ultimo firmware.' }
        '*|WHEA-Logger|17' = @{ Level='WARN'; Title='Hardware error corregido'; Cause='Error hardware que el sistema pudo corregir (ej. PCIe AER). No causa crash, pero indica degradacion.'; Action='Si es frecuente: problema de placa/tarjeta expansion. Re-asiente PCIe (GPU/SSD). BIOS update.' }
        '*|WHEA-Logger|18' = @{ Level='CRITICAL'; Title='Fatal hardware error (Machine Check)'; Cause='Machine Check Exception (MCE). CPU reporta error fatal. Muy probable inestabilidad hardware.'; Action='Check CPU temp (HWiNFO). Remove OC. Test RAM. Si repite: CPU o placa posiblemente defectuosa.' }
        '*|WHEA-Logger|19' = @{ Level='WARN'; Title='Hardware error corregido (PCIe)'; Cause='Error en bus PCIe corregido via AER.'; Action='GPU/SSD PCIe mal asentada o cable defectuoso. Reseat + BIOS update.' }
        '*|WHEA-Logger|46' = @{ Level='INFO'; Title='Throttling CPU por temperatura'; Cause='CPU redujo frecuencia por sobrecalentamiento.'; Action='Tool Parts Upgrade -> ver temps. Limpieza de pasta termica + ventilador. Notebook viejo: casi seguro.' }
        '*|*|10016' = @{ Level='INFO'; Title='DCOM error de permisos'; Cause='App intento llamar a un componente COM sin permisos. Casi siempre inofensivo.'; Action='Ignorable. Microsoft lo reconoce como ruido. No toques DCOM permissions salvo que tengas sintoma concreto.' }
        '*|Microsoft-Windows-Kernel-Boot|134' = @{ Level='INFO'; Title='Tiempo de arranque registrado'; Cause='Windows registro el tiempo que tardo el boot. Informativo.'; Action='Si ves tiempo muy alto (>60s con SSD): defrag autostart, sfc, revisar programas de inicio.' }
        '*|*|4625' = @{ Level='WARN'; Title='Logon fallido'; Cause='Alguien intento login con credenciales incorrectas. Mensaje contiene IP origen + usuario intentado.'; Action='Si son muchos y de IPs externas: ataque por fuerza bruta. Desactiva RDP publico, usa VPN.' }
        '*|*|4720' = @{ Level='WARN'; Title='Cuenta de usuario creada'; Cause='Una nueva cuenta local se creo.'; Action='Verifica que la creaste tu. Si no: malware / acceso no autorizado. Ver quien la creo.' }
        '*|*|4726' = @{ Level='WARN'; Title='Cuenta de usuario eliminada'; Cause='Una cuenta local se elimino.'; Action='Verifica que no fue accidente. Si no lo hiciste tu: intrusion.' }
        '*|*|4724' = @{ Level='WARN'; Title='Password reset admin'; Cause='Un admin reseteo el password de otra cuenta.'; Action='Normal en helpdesk. Si no reconoces origen: acceso no autorizado.' }
        '*|*|4740' = @{ Level='INFO'; Title='Cuenta bloqueada por intentos fallidos'; Cause='Account lockout (policy).'; Action='Usuario olvido password o intento de ataque.' }
        '*|*|4672' = @{ Level='INFO'; Title='Privilegios especiales asignados'; Cause='Un admin hizo login (normal).'; Action='Informativo. Util para auditar quien tiene acceso.' }
        '*|*|16' = @{ Level='INFO'; Title='Microsoft-Windows-Time-Service sync'; Cause='NTP sync tardio o fallido.'; Action='Si repite: reiniciar w32time. sc config w32time start=auto + w32tm /resync.' }
        '*|*|36888' = @{ Level='INFO'; Title='Schannel fatal error'; Cause='TLS handshake fallo. Frecuente con apps/navegadores antiguos y sitios que requieren TLS 1.2+.'; Action='Si molesta: habilitar TLS 1.2 en Internet Options. Update Windows.' }
    }
    $script:AtlasEventsKB = if ($lang -eq 'es') { $kbEs } else { $kbEn }

    function _Kb-Lookup {
        param([string]$LogName, [string]$Provider, [int]$EventId)
        if ($null -eq $script:AtlasEventsKB) { return $null }
        $keys = @(
            "$LogName|$Provider|$EventId",
            "*|$Provider|$EventId",
            "*|*|$EventId"
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
            return @()
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
            $level = if ($kb) { $kb.Level } else { 'INFO' }
            $icon  = _Level-Icon $level
            $color = _Level-Color $level
            $title = if ($kb) { $kb.Title } else { "$($first.ProviderName) #$($first.Id)" }
            Write-Host ''
            Write-Host ("  $icon $title  [x$($g.Count)]") -ForegroundColor $color
            Write-Host ("     $($L.FieldProvider): $($first.ProviderName) - $($L.FieldEventId): $($first.Id) - $($L.FieldLast): $($first.TimeCreated.ToString('yyyy-MM-dd HH:mm'))") -ForegroundColor DarkGray
            if ($kb) {
                Write-Host ("     $($L.FieldCause) : $($kb.Cause)") -ForegroundColor Gray
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

        try {
            $sec = _Query-Events -LogName 'Security' -Ids @(4625,4720,4726,4724,4740) -Hours $Hours -MaxEvents 200
            if ($sec -and $sec.Count -gt 0) { $sections[$L.HtmlSecSec] = $sec }
        } catch {}

        $hostName  = $env:COMPUTERNAME
        $generated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        $days = [int]([math]::Round($Hours/24))

        $htmlSections = ''
        foreach ($title in $sections.Keys) {
            $events = @($sections[$title])
            $htmlSections += "<section><h2>$([System.Net.WebUtility]::HtmlEncode($title)) <span class='count'>(" + $events.Count + ")</span></h2>"
            if ($events.Count -eq 0) {
                $htmlSections += "<p class='muted'>$($L.HtmlNoEvents)</p></section>"
                continue
            }
            $groups = $events | Group-Object ProviderName, Id | Sort-Object Count -Descending
            $htmlSections += "<div class='events'>"
            foreach ($g in $groups) {
                $first = $g.Group[0]
                $kb = _Kb-Lookup $first.LogName $first.ProviderName ([int]$first.Id)
                $level = if ($kb) { $kb.Level } else { 'INFO' }
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

        Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
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
                $kb = _Kb-Lookup '*' '*' $idN
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
