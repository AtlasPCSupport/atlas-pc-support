# ============================================================
# Invoke-StopServices  ->  Service Optimizer
#
# i18n: Option A (en default + full es secondary). Function name
# kept as Invoke-StopServices for tools.json compatibility.
#
# Atlas PC Support
# ============================================================

function Invoke-StopServices {
    [CmdletBinding()]
    param()

    # --- Language detection ---
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
            WinTitle      = 'ATLAS PC SUPPORT - SERVICE OPTIMIZER'
            HeaderTitle   = 'ATLAS PC SUPPORT - SERVICE OPTIMIZER v2'
            NeedAdmin     = '[X] ADMIN required. Relaunch with privileges.'
            BackupSaved   = '[i] Backup saved: {0}'
            StoppedManual = '[OK]   {0,-22} stopped and set to Manual'
            ErrFmt        = '[ERR]  {0,-22} {1}'
            NoBackup      = '[!] No backup. Nothing has been optimized from this tool.'
            BackupCorrupt = '[X] Backup is corrupt.'
            BackupEmpty   = '[!] Backup empty.'
            RestorePoints = '=== RESTORE POINTS ==='
            RestoreLine   = '[{0}] {1} - {2} services affected'
            CancelOpt     = '[0] Cancel'
            WhichRestore  = 'Which backup to restore?'
            RestoreOK     = '[OK]   {0,-22} mode={1,-18} prev_status={2}'
            RestoreDone   = 'Restore complete.'
            Cancelled     = 'Cancelled.'
            ColService    = 'Service'
            ColTier       = 'Tier'
            ColStatus     = 'Status'
            ColMode       = 'StartMode'
            ColDesc       = 'Description'
            NoteLabel     = 'note: {0}'
            Opt1          = '[1] View current state of candidate services'
            Opt2          = '[2] Stop SAFE services - recommended'
            Opt3          = '[3] Also stop MODERATE services (advanced)'
            Opt4          = '[4] UNDO - Restore a previous backup'
            Opt5          = '[5] View per-service warnings'
            OptQ          = '[Q] Quit'
            Selection     = 'Selection'
            EnterReturn   = 'ENTER to return'
            Enter         = 'ENTER'
            NoneFound     = 'No service from the list was detected on this Windows.'
            SafeOnly      = 'Will stop ONLY SAFE-tier services (do not break a normal PC).'
            AlreadyOptim  = 'No SAFE services running. Already optimized.'
            AdvHeader     = 'ADVANCED MODE: ALSO stops MODERATE services.'
            AdvWarn       = 'Read each service note carefully before saying YES.'
            AllStopped    = 'Everything is already stopped.'
            ProceedQ      = 'Proceed? [Y/N]'
            ProceedAllQ   = 'Proceed with ALL detected? [Y/N]'
            WarningsHdr   = '--- PER-SERVICE WARNINGS ---'
            BadOption     = 'Invalid option.'
        }
        es = @{
            WinTitle      = 'ATLAS PC SUPPORT - STOP SERVICES'
            HeaderTitle   = 'ATLAS PC SUPPORT - OPTIMIZACION DE SERVICIOS v2'
            NeedAdmin     = '[X] ADMIN requerido. Relanza con privilegios.'
            BackupSaved   = '[i] Backup guardado: {0}'
            StoppedManual = '[OK]   {0,-22} detenido y marcado Manual'
            ErrFmt        = '[ERR]  {0,-22} {1}'
            NoBackup      = '[!] No hay backup. No se ha optimizado nada desde este tool.'
            BackupCorrupt = '[X] Backup corrupto.'
            BackupEmpty   = '[!] Backup vacio.'
            RestorePoints = '=== PUNTOS DE RESTAURACION ==='
            RestoreLine   = '[{0}] {1} - {2} servicios afectados'
            CancelOpt     = '[0] Cancelar'
            WhichRestore  = 'Que backup restaurar?'
            RestoreOK     = '[OK]   {0,-22} modo={1,-18} estado_prev={2}'
            RestoreDone   = 'Restauracion completa.'
            Cancelled     = 'Cancelado.'
            ColService    = 'Servicio'
            ColTier       = 'Tier'
            ColStatus     = 'Estado'
            ColMode       = 'StartMode'
            ColDesc       = 'Descripcion'
            NoteLabel     = 'note: {0}'
            Opt1          = '[1] Ver estado actual de los servicios candidatos'
            Opt2          = '[2] Detener servicios SEGUROS (SAFE) - recomendado'
            Opt3          = '[3] Detener ADEMAS servicios MODERADOS (avanzado)'
            Opt4          = '[4] UNDO - Restaurar un backup previo'
            Opt5          = '[5] Ver advertencias de cada servicio'
            OptQ          = '[Q] Salir'
            Selection     = 'Seleccion'
            EnterReturn   = 'ENTER para volver'
            Enter         = 'ENTER'
            NoneFound     = 'No se detecto ningun servicio de la lista en este Windows.'
            SafeOnly      = 'Detendra SOLO servicios del tier SAFE (no rompen nada en un PC normal).'
            AlreadyOptim  = 'No hay servicios SAFE en ejecucion. Ya esta optimizado.'
            AdvHeader     = 'MODO AVANZADO: se detendran ADEMAS servicios MODERADOS.'
            AdvWarn       = 'Revisa la nota de CADA servicio antes de decir SI.'
            AllStopped    = 'Ya esta todo detenido.'
            ProceedQ      = 'Proceder? [S/N]'
            ProceedAllQ   = 'Proceder con TODOS los detectados? [S/N]'
            WarningsHdr   = '--- ADVERTENCIAS POR SERVICIO ---'
            BadOption     = 'Opcion no valida.'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    # Per-service descriptions also localized
    $svcLoc = @{
        en = @{
            DiagTrack          = @{ Desc='Telemetry (Connected User Experiences)'; Note='Does not affect functionality.' }
            dmwappushservice   = @{ Desc='WAP Push Message Routing';                Note='Only affects enterprise SMS push.' }
            WerSvc             = @{ Desc='Windows Error Reporting';                 Note='Just stops sending crashes to MS.' }
            wisvc              = @{ Desc='Windows Insider';                          Note='Only if you are not an Insider.' }
            PcaSvc             = @{ Desc='Program Compatibility Assistant';          Note='Just stops "run in compat mode" hints.' }
            XblAuthManager     = @{ Desc='Xbox Live Auth';                            Note='If you DO NOT play Microsoft Store games.' }
            XblGameSave        = @{ Desc='Xbox Live Game Save';                       Note='If you DO NOT play Microsoft Store games.' }
            XboxNetApiSvc      = @{ Desc='Xbox Live Networking';                      Note='If you DO NOT play Microsoft Store games.' }
            XboxGipSvc         = @{ Desc='Xbox Game Input Protocol';                  Note='If you DO NOT use an Xbox controller via USB/BT.' }
            MapsBroker         = @{ Desc='Offline Maps (Windows Maps)';               Note='Only affects MS Maps app.' }
            WalletService      = @{ Desc='Microsoft Wallet';                          Note='Discontinued app.' }
            RetailDemo         = @{ Desc='Retail Demo Mode';                          Note='Only for store demo PCs.' }
            Fax                = @{ Desc='Fax';                                       Note='Who uses fax today?' }
            RemoteRegistry     = @{ Desc='Remote Registry (attack vector)';           Note='Disabling IMPROVES security.' }
            TabletInputService = @{ Desc='Touch / pen input';                         Note='BREAKS: touch screens, tablets, Surface.' }
            SensorService      = @{ Desc='Sensor service';                            Note='BREAKS: screen rotation, auto-brightness (laptops).' }
            SensorDataService  = @{ Desc='Sensor data';                               Note='Same as SensorService.' }
            SensrSvc           = @{ Desc='Sensor monitoring';                         Note='Same as SensorService.' }
            WbioSrvc           = @{ Desc='Biometrics (fingerprint / Windows Hello)'; Note='BREAKS: fingerprint and face unlock.' }
            Spooler            = @{ Desc='Print Spooler';                             Note='BREAKS: printing. If you do NOT print, also closes PrintNightmare-style CVEs.' }
            WSearch            = @{ Desc='Windows Search Indexer';                    Note='BREAKS: fast Explorer/Outlook search.' }
            Bthserv            = @{ Desc='Bluetooth Support';                         Note='BREAKS: Bluetooth (if you do not use BT, fine).' }
        }
        es = @{
            DiagTrack          = @{ Desc='Telemetria (Connected User Experiences)';  Note='No afecta funcionalidad.' }
            dmwappushservice   = @{ Desc='WAP Push Message Routing';                  Note='Solo afecta SMS push en empresa.' }
            WerSvc             = @{ Desc='Reporte de errores de Windows';             Note='Solo deja de mandar crashes a MS.' }
            wisvc              = @{ Desc='Windows Insider';                            Note='Solo si no eres Insider.' }
            PcaSvc             = @{ Desc='Asistente de compatibilidad programas';     Note='Solo deja de sugerir "ejecutar en modo compat".' }
            XblAuthManager     = @{ Desc='Xbox Live Auth';                              Note='Si NO juegas a juegos Microsoft Store.' }
            XblGameSave        = @{ Desc='Xbox Live Game Save';                         Note='Si NO juegas a juegos Microsoft Store.' }
            XboxNetApiSvc      = @{ Desc='Xbox Live Networking';                        Note='Si NO juegas a juegos Microsoft Store.' }
            XboxGipSvc         = @{ Desc='Xbox Game Input Protocol';                    Note='Si NO usas mando Xbox por USB/Bluetooth.' }
            MapsBroker         = @{ Desc='Mapas offline (Windows Maps)';                Note='Solo afecta app Mapas de MS.' }
            WalletService      = @{ Desc='Cartera (Microsoft Wallet)';                  Note='App discontinuada.' }
            RetailDemo         = @{ Desc='Modo demo de tienda';                         Note='Solo para PCs de demostracion en tiendas.' }
            Fax                = @{ Desc='Fax';                                          Note='Quien usa fax hoy.' }
            RemoteRegistry     = @{ Desc='Registro remoto (vector de ataque)';          Note='Deshabilitarlo MEJORA seguridad.' }
            TabletInputService = @{ Desc='Entrada tactil / lapiz';                      Note='ROMPE: pantallas tactiles, tablets, Surface.' }
            SensorService      = @{ Desc='Servicio de sensores';                        Note='ROMPE: rotacion pantalla, auto-brillo (laptops).' }
            SensorDataService  = @{ Desc='Datos de sensores';                           Note='Lo mismo que SensorService.' }
            SensrSvc           = @{ Desc='Supervision de sensores';                     Note='Lo mismo que SensorService.' }
            WbioSrvc           = @{ Desc='Biometria (huellas / Windows Hello)';        Note='ROMPE: huella y reconocimiento facial.' }
            Spooler            = @{ Desc='Print Spooler';                                Note='ROMPE: impresion. Si NO imprimes, tambien cierra CVE tipo PrintNightmare.' }
            WSearch            = @{ Desc='Indexador de Windows Search';                  Note='ROMPE: busquedas rapidas Explorer y Outlook.' }
            Bthserv            = @{ Desc='Bluetooth Support';                            Note='ROMPE: Bluetooth (si no usas nada BT, se puede).' }
        }
    }
    $svcL = $svcLoc[$lang]
    if (-not $svcL) { $svcL = $svcLoc['en'] }

    try { $Host.UI.RawUI.WindowTitle = $L.WinTitle } catch {}
    Clear-Host

    # Backup directory
    $backupDir = Join-Path $env:LOCALAPPDATA 'AtlasPC'
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $backupFile = Join-Path $backupDir 'services-backup.json'

    # Service tiers (SAFE / MODERATE)
    $tiers = @(
        @{ Name='DiagTrack';           Tier='SAFE' }
        @{ Name='dmwappushservice';    Tier='SAFE' }
        @{ Name='WerSvc';              Tier='SAFE' }
        @{ Name='wisvc';               Tier='SAFE' }
        @{ Name='PcaSvc';              Tier='SAFE' }
        @{ Name='XblAuthManager';      Tier='SAFE' }
        @{ Name='XblGameSave';         Tier='SAFE' }
        @{ Name='XboxNetApiSvc';       Tier='SAFE' }
        @{ Name='XboxGipSvc';          Tier='SAFE' }
        @{ Name='MapsBroker';          Tier='SAFE' }
        @{ Name='WalletService';       Tier='SAFE' }
        @{ Name='RetailDemo';          Tier='SAFE' }
        @{ Name='Fax';                 Tier='SAFE' }
        @{ Name='RemoteRegistry';      Tier='SAFE' }
        @{ Name='TabletInputService';  Tier='MODERATE' }
        @{ Name='SensorService';       Tier='MODERATE' }
        @{ Name='SensorDataService';   Tier='MODERATE' }
        @{ Name='SensrSvc';            Tier='MODERATE' }
        @{ Name='WbioSrvc';            Tier='MODERATE' }
        @{ Name='Spooler';             Tier='MODERATE' }
        @{ Name='WSearch';             Tier='MODERATE' }
        @{ Name='Bthserv';             Tier='MODERATE' }
    )
    $serviciosAOptimizar = foreach ($t in $tiers) {
        $loc = $svcL[$t.Name]
        if (-not $loc) { $loc = @{ Desc=$t.Name; Note='' } }
        @{ Name=$t.Name; Tier=$t.Tier; Desc=$loc.Desc; Note=$loc.Note }
    }

    function Wait-StopServicesCompat {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

    function Show-Header {
        Clear-Host
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title $L.HeaderTitle -Color Yellow
            Write-Host ''
            return
        }
        Write-Host ''
        Write-Host '  =================================================' -ForegroundColor DarkGray
        Write-Host ('   ' + $L.HeaderTitle) -ForegroundColor Yellow
        Write-Host '  =================================================' -ForegroundColor DarkGray
        Write-Host ''
    }

    function Check-Admin {
        $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function List-Services {
        param([string]$TierFilter = '')
        $out = @()
        foreach ($s in $serviciosAOptimizar) {
            if ($TierFilter -and $s.Tier -ne $TierFilter) { continue }
            $svc = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
            if (-not $svc) { continue }
            try {
                $svcCim = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($s.Name)'" -ErrorAction SilentlyContinue
                $startMode = if ($svcCim) { $svcCim.StartMode } else { '?' }
            } catch { $startMode = '?' }
            $out += [pscustomobject]@{
                Name      = $s.Name
                Desc      = $s.Desc
                Note      = $s.Note
                Tier      = $s.Tier
                Status    = $svc.Status
                StartMode = $startMode
            }
        }
        return $out
    }

    function Apply-Stop {
        param($Targets)
        if (-not (Check-Admin)) {
            Write-Host ''
            Write-Host ('  ' + $L.NeedAdmin) -ForegroundColor Red
            return $false
        }

        # Snapshot previous state
        $backup = @()
        foreach ($t in $Targets) {
            $svc = Get-Service -Name $t.Name -ErrorAction SilentlyContinue
            if (-not $svc) { continue }
            $cim = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($t.Name)'" -ErrorAction SilentlyContinue
            $delayed = $false
            if ($cim -and $cim.StartMode -eq 'Auto') {
                try {
                    $regKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($t.Name)"
                    $delayed = [bool](Get-ItemProperty -Path $regKey -Name DelayedAutostart -ErrorAction Stop).DelayedAutostart
                } catch { $delayed = $false }
            }
            $backup += [pscustomobject]@{
                Name              = $t.Name
                Status            = $svc.Status.ToString()
                StartMode         = if ($cim) { $cim.StartMode } else { 'Unknown' }
                DelayedAutoStart  = $delayed
                Timestamp         = (Get-Date).ToString('s')
            }
        }
        $history = @()
        if (Test-Path $backupFile) {
            try { $history = @(Get-Content $backupFile -Raw | ConvertFrom-Json) } catch { $history = @() }
        }
        $entry = [pscustomobject]@{
            Timestamp = (Get-Date).ToString('s')
            Services  = $backup
        }
        $history = @($history) + @($entry)
        ConvertTo-Json -InputObject $history -Depth 5 | Out-File -FilePath $backupFile -Encoding UTF8
        Write-Host ''
        Write-Host ('  ' + ($L.BackupSaved -f $backupFile)) -ForegroundColor DarkGray
        Write-Host ''

        foreach ($t in $Targets) {
            try {
                Stop-Service -Name $t.Name -Force -ErrorAction Stop
                Set-Service  -Name $t.Name -StartupType Manual -ErrorAction Stop
                Write-Host ('  ' + ($L.StoppedManual -f $t.Name)) -ForegroundColor Green
            } catch {
                Write-Host ('  ' + ($L.ErrFmt -f $t.Name, $_.Exception.Message)) -ForegroundColor Red
            }
        }
        return $true
    }

    function Apply-Undo {
        if (-not (Check-Admin)) {
            Write-Host ''
            Write-Host ('  ' + $L.NeedAdmin) -ForegroundColor Red
            return
        }
        if (-not (Test-Path $backupFile)) {
            Write-Host ''
            Write-Host ('  ' + $L.NoBackup) -ForegroundColor Yellow
            return
        }
        try {
            $history = @(Get-Content $backupFile -Raw | ConvertFrom-Json)
        } catch {
            Write-Host ''
            Write-Host ('  ' + $L.BackupCorrupt) -ForegroundColor Red
            return
        }
        if ($history.Count -eq 0) {
            Write-Host ''
            Write-Host ('  ' + $L.BackupEmpty) -ForegroundColor Yellow
            return
        }

        Write-Host ''
        Write-Host ('  ' + $L.RestorePoints) -ForegroundColor Yellow
        Write-Host ''
        $i = 1
        foreach ($e in $history) {
            $n = @($e.Services).Count
            Write-Host ('  ' + ($L.RestoreLine -f $i, $e.Timestamp, $n)) -ForegroundColor White
            $i++
        }
        Write-Host ''
        Write-Host ('  ' + $L.CancelOpt) -ForegroundColor DarkGray
        Write-Host ''
        $sel = Read-Host ('  ' + $L.WhichRestore)
        if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $history.Count) {
            $entry = $history[[int]$sel - 1]
            foreach ($s in $entry.Services) {
                $modeMap = @{ 'Auto' = 'Automatic'; 'Automatic' = 'Automatic'; 'Manual' = 'Manual'; 'Disabled' = 'Disabled'; 'Boot' = 'Boot'; 'System' = 'System' }
                $mode = if ($modeMap.ContainsKey($s.StartMode)) { $modeMap[$s.StartMode] } else { 'Manual' }
                $label = if ($mode -eq 'Automatic' -and $s.DelayedAutoStart) { 'Automatic(Delayed)' } else { $mode }
                try {
                    Set-Service -Name $s.Name -StartupType $mode -ErrorAction Stop
                    $hasDelayedProp = $s.PSObject.Properties.Name -contains 'DelayedAutoStart'
                    if ($mode -eq 'Automatic' -and $hasDelayedProp) {
                        $regKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($s.Name)"
                        $flagVal = if ($s.DelayedAutoStart) { 1 } else { 0 }
                        try {
                            Set-ItemProperty -Path $regKey -Name 'DelayedAutostart' -Value $flagVal -Type DWord -ErrorAction Stop
                        } catch {}
                    }
                    if ($s.Status -eq 'Running') {
                        Start-Service -Name $s.Name -ErrorAction SilentlyContinue
                    }
                    Write-Host ('  ' + ($L.RestoreOK -f $s.Name, $label, $s.Status)) -ForegroundColor Green
                } catch {
                    Write-Host ('  ' + ($L.ErrFmt -f $s.Name, $_.Exception.Message)) -ForegroundColor Red
                }
            }
            Write-Host ''
            Write-Host ('  ' + $L.RestoreDone) -ForegroundColor Cyan
        } else {
            Write-Host ('  ' + $L.Cancelled) -ForegroundColor DarkGray
        }
    }

    function Show-ServicesTable {
        param($List)
        Write-Host ('  {0,-22} {1,-6} {2,-10} {3,-10} {4}' -f $L.ColService, $L.ColTier, $L.ColStatus, $L.ColMode, $L.ColDesc) -ForegroundColor Cyan
        Write-Host ('  ' + ('-' * 90)) -ForegroundColor DarkGray
        foreach ($r in $List) {
            $color = if ($r.Status -eq 'Running') { 'Green' } else { 'DarkGray' }
            Write-Host ("  {0,-22} {1,-6} {2,-10} {3,-10} {4}" -f $r.Name, $r.Tier, $r.Status, $r.StartMode, $r.Desc) -ForegroundColor $color
            Write-Host ('  ' + (' ' * 22) + '   ' + ($L.NoteLabel -f $r.Note)) -ForegroundColor DarkGray
        }
    }

    # ============================================================
    # MAIN MENU
    # ============================================================
    while ($true) {
        Show-Header
        Write-Host ('  ' + $L.Opt1) -ForegroundColor White
        Write-Host ('  ' + $L.Opt2) -ForegroundColor Green
        Write-Host ('  ' + $L.Opt3) -ForegroundColor Yellow
        Write-Host ('  ' + $L.Opt4) -ForegroundColor Cyan
        Write-Host ('  ' + $L.Opt5) -ForegroundColor DarkCyan
        Write-Host ('  ' + $L.OptQ)
        Write-Host ''
        $sel = Read-Host ('  ' + $L.Selection)

        switch -regex ($sel) {
            '^1$' {
                Show-Header
                $list = List-Services
                if ($list.Count -eq 0) {
                    Write-Host ('  ' + $L.NoneFound) -ForegroundColor Yellow
                } else {
                    Show-ServicesTable $list
                }
                Write-Host ''
                Wait-StopServicesCompat -Message ('  ' + $L.EnterReturn)
            }
            '^2$' {
                Show-Header
                Write-Host ('  ' + $L.SafeOnly) -ForegroundColor Green
                Write-Host ''
                $list = List-Services -TierFilter 'SAFE' | Where-Object { $_.Status -eq 'Running' }
                if ($list.Count -eq 0) {
                    Write-Host ('  ' + $L.AlreadyOptim) -ForegroundColor Cyan
                    Wait-StopServicesCompat -Message ('  ' + $L.Enter)
                    continue
                }
                Show-ServicesTable $list
                Write-Host ''
                $c = Read-Host ('  ' + $L.ProceedQ)
                if ($c -match '^[SsYy]$') {
                    Apply-Stop -Targets $list | Out-Null
                }
                Write-Host ''
                Wait-StopServicesCompat -Message ('  ' + $L.Enter)
            }
            '^3$' {
                Show-Header
                Write-Host ('  ' + $L.AdvHeader) -ForegroundColor Yellow
                Write-Host ('  ' + $L.AdvWarn) -ForegroundColor Yellow
                Write-Host ''
                $list = List-Services | Where-Object { $_.Status -eq 'Running' }
                if ($list.Count -eq 0) {
                    Write-Host ('  ' + $L.AllStopped) -ForegroundColor Cyan
                    Wait-StopServicesCompat -Message ('  ' + $L.Enter)
                    continue
                }
                Show-ServicesTable $list
                Write-Host ''
                $c = Read-Host ('  ' + $L.ProceedAllQ)
                if ($c -match '^[SsYy]$') {
                    Apply-Stop -Targets $list | Out-Null
                }
                Write-Host ''
                Wait-StopServicesCompat -Message ('  ' + $L.Enter)
            }
            '^4$' {
                Show-Header
                Apply-Undo
                Write-Host ''
                Wait-StopServicesCompat -Message ('  ' + $L.Enter)
            }
            '^5$' {
                Show-Header
                Write-Host ('  ' + $L.WarningsHdr) -ForegroundColor Yellow
                Write-Host ''
                foreach ($s in $serviciosAOptimizar) {
                    $col = if ($s.Tier -eq 'SAFE') { 'Green' } else { 'Yellow' }
                    Write-Host ("  [{0}] {1,-22} ({2})" -f $s.Tier, $s.Name, $s.Desc) -ForegroundColor $col
                    Write-Host ("        {0}" -f $s.Note) -ForegroundColor Gray
                    Write-Host ''
                }
                Wait-StopServicesCompat -Message ('  ' + $L.Enter)
            }
            '^[Qq]$' { return }
            default { Write-Host ('  ' + $L.BadOption) -ForegroundColor Red; Start-Sleep 1 }
        }
    }
}
