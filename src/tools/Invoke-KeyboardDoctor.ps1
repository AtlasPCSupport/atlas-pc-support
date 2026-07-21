function Invoke-KeyboardDoctor {
    <#
    .SYNOPSIS
      Keyboard Doctor: safe ghost-typing / keyboard-fault triage.

    .DESCRIPTION
      - Checks keyboard devices, accessibility key settings, battery health,
        touchpad presence, and recent HID/keyboard/touchpad driver events.
      - Provides manual BIOS/external-keyboard/touchpad isolation prompts.
      - Optional foreground-only hands-off key monitor requires explicit consent.
      - Exports bilingual HTML/TXT reports.
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
            Title='ATLAS PC SUPPORT - Keyboard Doctor'
            Subtitle='Ghost typing and keyboard fault triage'
            Menu1='[1] Quick diagnosis'
            Menu2='[2] List keyboard / touchpad devices'
            Menu3='[3] Accessibility keys check'
            Menu4='[4] Battery pressure risk check'
            Menu5='[5] Recent keyboard / HID / touchpad events'
            Menu6='[6] Manual isolation tests'
            Menu7='[7] Optional hands-off key monitor'
            Menu8='[8] Repair actions (confirm required)'
            Menu9='[9] Export HTML/TXT report'
            MenuQ='[Q] Quit'
            Prompt='Option'
            Back='ENTER to continue'
            Running='Running...'
            Done='Done.'
            Unknown='Unknown'
            Yes='Yes'
            No='No'
            Computer='Computer'
            OS='Operating system'
            Manufacturer='Manufacturer'
            Model='Model'
            Device='Device'
            Class='Class'
            Status='Status'
            InstanceId='Instance ID'
            Accessibility='Accessibility keys'
            FilterKeys='Filter Keys'
            StickyKeys='Sticky Keys'
            ToggleKeys='Toggle Keys'
            RawFlags='Raw flags'
            Battery='Battery'
            BatteryWear='Battery wear'
            NoBattery='No battery detected (desktop or unavailable data).'
            Events='Events'
            EventTime='Time'
            EventId='Event ID'
            Provider='Provider'
            Level='Level'
            Message='Message'
            NoEvents='No recent keyboard/HID/touchpad warning or error events found.'
            ManualTitle='Manual isolation tests'
            BiosAsk='Did ghost typing happen in BIOS/UEFI? (y/n/skip)'
            ExternalAsk='With external USB keyboard and internal keyboard disabled/avoided, did ghost typing stop? (stopped/persists/skip)'
            TouchpadAsk='With touchpad disabled or palm rejection tested, did ghost typing stop? (stopped/persists/skip)'
            MonitorWarn='Foreground-only monitor. It records key NAMES only while this console is visible. Do not type passwords. Type CONSENT to continue.'
            MonitorMinutes='Minutes to monitor (1-10, Enter=3)'
            MonitorActive='Monitor active. Do not touch the keyboard.'
            MonitorDone='Monitor complete. Captured keys: {0}'
            RepairTitle='Repair actions'
            RepairWarn='These actions change user settings. Use only after explaining to the customer.'
            Repair1='[1] Disable Filter/Sticky/Toggle Keys shortcuts'
            Repair2='[2] Open Device Manager'
            Repair3='[3] Open Keyboard settings'
            RepairB='[B] Back'
            Confirm='Type YES to confirm'
            Cancelled='Cancelled.'
            AccessibilityDisabled='Accessibility key shortcuts disabled for current user.'
            ExportSaved='Report saved: {0}'
            ReportTitle='ATLAS PC SUPPORT - Keyboard Doctor Report'
            Generated='Generated'
            Summary='Summary'
            Findings='Findings'
            Recommendations='Recommendations'
            ResultApto='APTO'
            ResultObs='OBSERVATION'
            ResultRisk='KEYBOARD/HARDWARE RISK'
            FindingOk='No strong keyboard red flags found in the quick check.'
            RecOk='Proceed with normal software cleanup, driver check, and observation before promising hardware replacement.'
            FindingNoKeyboard='No keyboard devices are visible to Windows.'
            RecNoKeyboard='Check Device Manager, BIOS detection, USB/internal connection, and keyboard driver.'
            FindingBadKeyboard='Keyboard device has non-OK status: {0}'
            RecBadKeyboard='Review Device Manager status/code, reinstall driver, then retest.'
            FindingAccess='Accessibility key feature appears enabled: {0}'
            RecAccess='Disable Filter/Sticky/Toggle Keys and retest before blaming hardware.'
            FindingBattery='Battery wear is high ({0}%).'
            RecBattery='Physically inspect laptop battery; swelling can press the keyboard/touchpad and is a safety risk.'
            FindingEvents='Recent keyboard/HID/touchpad driver warnings/errors: {0}'
            RecEvents='Review driver/PnP events before promising that Windows reinstall or cleaning will fix it.'
            FindingBios='Ghost typing was reported inside BIOS/UEFI.'
            RecBios='Treat as hardware until proven otherwise: internal keyboard, flex cable, board, or battery pressure.'
            FindingExternal='Ghost typing stopped when isolating the internal keyboard.'
            RecExternal='Internal keyboard or related hardware is likely; do not promise a software-only fix.'
            FindingTouchpad='Ghost typing stopped when isolating touchpad/palm input.'
            RecTouchpad='Check touchpad, palm rejection, swelling battery pressure, and touchpad driver.'
            FindingMonitor='Hands-off monitor captured unexpected key events: {0}'
            RecMonitor='If repeated on one key, suspect stuck key/short. If random, review drivers/software and repeat in BIOS.'
            HtmlLang='en'
        }
        es = @{
            Title='ATLAS PC SUPPORT - Keyboard Doctor'
            Subtitle='Triaje de ghost typing y fallos de teclado'
            Menu1='[1] Diagnostico rapido'
            Menu2='[2] Listar teclado / touchpad'
            Menu3='[3] Revisar Filter/Sticky/Toggle Keys'
            Menu4='[4] Riesgo por bateria presionando'
            Menu5='[5] Eventos recientes de teclado / HID / touchpad'
            Menu6='[6] Pruebas manuales de aislamiento'
            Menu7='[7] Monitor opcional sin tocar teclado'
            Menu8='[8] Acciones de reparacion (requieren confirmacion)'
            Menu9='[9] Exportar reporte HTML/TXT'
            MenuQ='[Q] Salir'
            Prompt='Opcion'
            Back='ENTER para continuar'
            Running='Ejecutando...'
            Done='Listo.'
            Unknown='Desconocido'
            Yes='Si'
            No='No'
            Computer='Equipo'
            OS='Sistema operativo'
            Manufacturer='Fabricante'
            Model='Modelo'
            Device='Dispositivo'
            Class='Clase'
            Status='Estado'
            InstanceId='Instance ID'
            Accessibility='Teclas de accesibilidad'
            FilterKeys='Filter Keys'
            StickyKeys='Sticky Keys'
            ToggleKeys='Toggle Keys'
            RawFlags='Flags crudos'
            Battery='Bateria'
            BatteryWear='Desgaste bateria'
            NoBattery='No se detecto bateria (desktop o datos no disponibles).'
            Events='Eventos'
            EventTime='Hora'
            EventId='Event ID'
            Provider='Proveedor'
            Level='Nivel'
            Message='Mensaje'
            NoEvents='No hay eventos recientes de teclado/HID/touchpad con warning o error.'
            ManualTitle='Pruebas manuales de aislamiento'
            BiosAsk='Aparecio ghost typing en BIOS/UEFI? (y/n/skip)'
            ExternalAsk='Con teclado USB externo e interno aislado/evitado, desaparecio el ghost typing? (stopped/persists/skip)'
            TouchpadAsk='Con touchpad desactivado o palm rejection probado, desaparecio el ghost typing? (stopped/persists/skip)'
            MonitorWarn='Monitor solo en primer plano. Registra NOMBRES de teclas solo mientras esta consola esta visible. No escribas contrasenas. Escribe CONSENT para continuar.'
            MonitorMinutes='Minutos de monitoreo (1-10, Enter=3)'
            MonitorActive='Monitor activo. No toques el teclado.'
            MonitorDone='Monitor completado. Teclas capturadas: {0}'
            RepairTitle='Acciones de reparacion'
            RepairWarn='Estas acciones cambian ajustes del usuario. Usar solo tras explicarlo al cliente.'
            Repair1='[1] Desactivar atajos Filter/Sticky/Toggle Keys'
            Repair2='[2] Abrir Administrador de dispositivos'
            Repair3='[3] Abrir configuracion de teclado'
            RepairB='[B] Volver'
            Confirm='Escribe SI para confirmar'
            Cancelled='Cancelado.'
            AccessibilityDisabled='Atajos de accesibilidad desactivados para el usuario actual.'
            ExportSaved='Reporte guardado: {0}'
            ReportTitle='ATLAS PC SUPPORT - Reporte Keyboard Doctor'
            Generated='Generado'
            Summary='Resumen'
            Findings='Hallazgos'
            Recommendations='Recomendaciones'
            ResultApto='APTO'
            ResultObs='OBSERVACION'
            ResultRisk='RIESGO TECLADO/HARDWARE'
            FindingOk='No se encontraron alertas fuertes de teclado en el chequeo rapido.'
            RecOk='Puedes continuar con limpieza de software, driver y observacion antes de prometer reemplazo de hardware.'
            FindingNoKeyboard='Windows no muestra ningun dispositivo de teclado.'
            RecNoKeyboard='Revisar Device Manager, deteccion en BIOS, conexion USB/interna y driver de teclado.'
            FindingBadKeyboard='Teclado con estado no OK: {0}'
            RecBadKeyboard='Revisar estado/codigo en Device Manager, reinstalar driver y volver a probar.'
            FindingAccess='Funcion de accesibilidad parece activa: {0}'
            RecAccess='Desactivar Filter/Sticky/Toggle Keys y repetir antes de culpar hardware.'
            FindingBattery='Desgaste de bateria alto ({0}%).'
            RecBattery='Inspeccion fisica de bateria; una bateria hinchada puede presionar teclado/touchpad y es riesgo de seguridad.'
            FindingEvents='Eventos recientes de driver teclado/HID/touchpad: {0}'
            RecEvents='Revisar eventos PnP/driver antes de prometer que reinstalar Windows o limpiar lo arreglara.'
            FindingBios='Se reporto ghost typing dentro de BIOS/UEFI.'
            RecBios='Tratar como hardware hasta demostrar lo contrario: teclado interno, flex, placa o presion de bateria.'
            FindingExternal='El ghost typing desaparecio al aislar el teclado interno.'
            RecExternal='Probable teclado interno o hardware relacionado; no prometer solucion solo de software.'
            FindingTouchpad='El ghost typing desaparecio al aislar touchpad/palm input.'
            RecTouchpad='Revisar touchpad, palm rejection, presion por bateria hinchada y driver de touchpad.'
            FindingMonitor='El monitor sin tocar teclado capturo eventos inesperados: {0}'
            RecMonitor='Si se repite una tecla, sospecha tecla trabada/corto. Si es aleatorio, revisar drivers/software y repetir en BIOS.'
            HtmlLang='es'
        }
    }

    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    $script:KeyboardDoctorReport = [ordered]@{
        Generated = Get-Date
        Computer = $env:COMPUTERNAME
        OS = ''
        Manufacturer = ''
        Model = ''
        Keyboards = @()
        PointingDevices = @()
        Accessibility = @()
        Battery = $null
        Events = @()
        Manual = [ordered]@{
            Bios = 'Not tested'
            ExternalKeyboard = 'Not tested'
            Touchpad = 'Not tested'
        }
        Monitor = @()
        Findings = @()
        Recommendations = @()
        Result = $L.ResultApto
    }

    function Write-KDHeader {
        Clear-Host
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title $L.Title -Color Yellow
            Write-AtlasStep $L.Subtitle
            Write-Host ""
            return
        }
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  $($L.Title)" -ForegroundColor Cyan
        Write-Host "  $($L.Subtitle)" -ForegroundColor DarkGray
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
    }

    function Pause-KeyboardDoctor {
        Write-Host ""
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $L.Back
            return
        }
        Read-Host $L.Back | Out-Null
    }

    function Add-KDFinding {
        param(
            [ValidateSet('info','observation','risk')] [string]$Severity,
            [string]$Finding,
            [string]$Recommendation
        )
        $script:KeyboardDoctorReport.Findings += [pscustomobject]@{
            Severity = $Severity
            Finding = $Finding
            Recommendation = $Recommendation
        }
        $script:KeyboardDoctorReport.Recommendations += $Recommendation
        if ($Severity -eq 'risk') {
            $script:KeyboardDoctorReport.Result = $L.ResultRisk
        } elseif ($Severity -eq 'observation' -and $script:KeyboardDoctorReport.Result -ne $L.ResultRisk) {
            $script:KeyboardDoctorReport.Result = $L.ResultObs
        }
    }

    function Get-KDSystemInfo {
        try {
            $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
            $script:KeyboardDoctorReport.Manufacturer = [string]$cs.Manufacturer
            $script:KeyboardDoctorReport.Model = [string]$cs.Model
        } catch {}
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
            $script:KeyboardDoctorReport.OS = ('{0} {1}' -f $os.Caption, $os.Version)
        } catch {}
    }

    function Get-KDDevicesByClass {
        param([string[]]$Classes)
        $items = @()
        foreach ($className in $Classes) {
            try {
                if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {
                    $items += @(Get-PnpDevice -Class $className -ErrorAction SilentlyContinue | Select-Object FriendlyName, Class, Status, InstanceId)
                }
            } catch {}
        }
        if ($items.Count -eq 0) {
            try {
                $rx = ($Classes -join '|')
                $items += @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object {
                    $_.PNPClass -match $rx -or $_.Name -match $rx
                } | Select-Object @{n='FriendlyName';e={$_.Name}}, @{n='Class';e={$_.PNPClass}}, Status, @{n='InstanceId';e={$_.PNPDeviceID}})
            } catch {}
        }
        return @($items)
    }

    function Get-KDKeyboardDevices {
        $items = @(Get-KDDevicesByClass -Classes @('Keyboard'))
        $script:KeyboardDoctorReport.Keyboards = $items
        return $items
    }

    function Get-KDPointingDevices {
        $items = @(Get-KDDevicesByClass -Classes @('Mouse','HIDClass') | Where-Object {
            $_.FriendlyName -match 'touchpad|trackpad|synaptics|elan|precision|alps|i2c|hid|mouse'
        } | Select-Object -First 25)
        $script:KeyboardDoctorReport.PointingDevices = $items
        return $items
    }

    function Get-KDAccessibility {
        $defs = @(
            @{ Name=$L.StickyKeys; Path='HKCU:\Control Panel\Accessibility\StickyKeys' },
            @{ Name=$L.FilterKeys; Path='HKCU:\Control Panel\Accessibility\Keyboard Response' },
            @{ Name=$L.ToggleKeys; Path='HKCU:\Control Panel\Accessibility\ToggleKeys' }
        )
        $rows = @()
        foreach ($d in $defs) {
            $flags = $null
            $enabled = $false
            try {
                $p = Get-ItemProperty -LiteralPath $d.Path -ErrorAction Stop
                $flags = [string]$p.Flags
                $num = 0
                if ([int]::TryParse($flags, [ref]$num)) { $enabled = (($num -band 1) -eq 1) }
            } catch {}
            $rows += [pscustomobject]@{
                Name = $d.Name
                Enabled = [bool]$enabled
                Flags = if ($flags) { $flags } else { $L.Unknown }
            }
        }
        $script:KeyboardDoctorReport.Accessibility = $rows
        return $rows
    }

    function Get-KDBattery {
        $result = [ordered]@{
            Present = $false
            Name = ''
            Status = ''
            EstimatedChargeRemaining = $null
            WearPercent = $null
            Note = $L.NoBattery
        }
        try {
            $bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($bat) {
                $result.Present = $true
                $result.Name = [string]$bat.Name
                $result.Status = [string]$bat.Status
                $result.EstimatedChargeRemaining = $bat.EstimatedChargeRemaining
                $result.Note = ''
            }
        } catch {}
        try {
            $static = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue | Select-Object -First 1
            $full = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($static -and $full -and $static.DesignedCapacity -gt 0) {
                $wear = [math]::Round((1 - ($full.FullChargedCapacity / $static.DesignedCapacity)) * 100, 1)
                if ($wear -lt 0) { $wear = 0 }
                $result.WearPercent = $wear
            }
        } catch {}
        $script:KeyboardDoctorReport.Battery = [pscustomobject]$result
        return $script:KeyboardDoctorReport.Battery
    }

    function Get-KDEvents {
        param([int]$Days = 14)
        $start = (Get-Date).AddDays(-1 * $Days)
        $events = @()
        try {
            $all = @(Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$start } -ErrorAction SilentlyContinue | Where-Object {
                ($_.LevelDisplayName -match 'Error|Warning|Critical|Advertencia') -and (
                    $_.ProviderName -match 'i8042|kbd|hid|Kernel-PnP|UserPnp|DriverFrameworks|SynTP|ETD|ELAN|I2C' -or
                    $_.Message -match 'keyboard|teclado|touchpad|trackpad|hid|i2c|ps/2'
                )
            } | Select-Object -First 80 TimeCreated, ProviderName, Id, LevelDisplayName, Message)
            $events += $all
        } catch {}
        $script:KeyboardDoctorReport.Events = @($events | Sort-Object TimeCreated -Descending)
        return $script:KeyboardDoctorReport.Events
    }

    function Invoke-KDQuickDiagnosis {
        $script:KeyboardDoctorReport.Findings = @()
        $script:KeyboardDoctorReport.Recommendations = @()
        $script:KeyboardDoctorReport.Result = $L.ResultApto

        Get-KDSystemInfo
        $keyboards = @(Get-KDKeyboardDevices)
        $touch = @(Get-KDPointingDevices)
        $access = @(Get-KDAccessibility)
        $battery = Get-KDBattery
        $events = @(Get-KDEvents -Days 14)

        if ($keyboards.Count -eq 0) {
            Add-KDFinding 'risk' $L.FindingNoKeyboard $L.RecNoKeyboard
        }
        foreach ($kb in $keyboards | Where-Object { $_.Status -and $_.Status -notmatch 'OK|Unknown' }) {
            Add-KDFinding 'observation' ($L.FindingBadKeyboard -f $kb.FriendlyName) $L.RecBadKeyboard
        }
        foreach ($a in $access | Where-Object { $_.Enabled }) {
            Add-KDFinding 'observation' ($L.FindingAccess -f $a.Name) $L.RecAccess
        }
        if ($battery -and $battery.WearPercent -ne $null -and $battery.WearPercent -ge 55) {
            $sev = if ($battery.WearPercent -ge 70) { 'risk' } else { 'observation' }
            Add-KDFinding $sev ($L.FindingBattery -f $battery.WearPercent) $L.RecBattery
        }
        if ($events.Count -ge 8) {
            $sev2 = if ($events.Count -ge 25) { 'risk' } else { 'observation' }
            Add-KDFinding $sev2 ($L.FindingEvents -f $events.Count) $L.RecEvents
        }
        if ($script:KeyboardDoctorReport.Manual.Bios -eq 'y') { Add-KDFinding 'risk' $L.FindingBios $L.RecBios }
        if ($script:KeyboardDoctorReport.Manual.ExternalKeyboard -eq 'stopped') { Add-KDFinding 'risk' $L.FindingExternal $L.RecExternal }
        if ($script:KeyboardDoctorReport.Manual.Touchpad -eq 'stopped') { Add-KDFinding 'observation' $L.FindingTouchpad $L.RecTouchpad }
        if ($script:KeyboardDoctorReport.Monitor.Count -gt 0) { Add-KDFinding 'observation' ($L.FindingMonitor -f $script:KeyboardDoctorReport.Monitor.Count) $L.RecMonitor }
        if ($script:KeyboardDoctorReport.Findings.Count -eq 0) { Add-KDFinding 'info' $L.FindingOk $L.RecOk }

        [pscustomobject]@{
            Result = $script:KeyboardDoctorReport.Result
            Keyboards = $keyboards.Count
            PointingDevices = $touch.Count
            AccessibilityEnabled = @($access | Where-Object { $_.Enabled }).Count
            BatteryWearPercent = if ($battery) { $battery.WearPercent } else { $null }
            Events = $events.Count
        }
    }

    function Show-KDDevices {
        $keyboards = @(Get-KDKeyboardDevices)
        $touch = @(Get-KDPointingDevices)
        Write-Host $L.Device -ForegroundColor Cyan
        if ($keyboards.Count -eq 0) { Write-Host "  $($L.FindingNoKeyboard)" -ForegroundColor Yellow }
        else { $keyboards | Format-Table FriendlyName, Class, Status, InstanceId -AutoSize -Wrap }
        Write-Host "`nTouchpad / HID / Mouse:" -ForegroundColor Cyan
        if ($touch.Count -eq 0) { Write-Host "  ($($L.Unknown))" -ForegroundColor DarkGray }
        else { $touch | Format-Table FriendlyName, Class, Status, InstanceId -AutoSize -Wrap }
    }

    function Show-KDAccessibility {
        $rows = @(Get-KDAccessibility)
        $rows | Format-Table Name, Enabled, Flags -AutoSize
    }

    function Show-KDBattery {
        $bat = Get-KDBattery
        if (-not $bat.Present) { Write-Host $L.NoBattery -ForegroundColor DarkGray; return }
        $bat | Format-List
        if ($bat.WearPercent -ne $null -and $bat.WearPercent -ge 55) {
            Write-Host $L.RecBattery -ForegroundColor Yellow
        }
    }

    function Show-KDEvents {
        $events = @(Get-KDEvents -Days 14)
        if ($events.Count -eq 0) { Write-Host $L.NoEvents -ForegroundColor Green; return }
        $events | Select-Object -First 25 TimeCreated, ProviderName, Id, LevelDisplayName, @{n='Message';e={ $m = [string]$_.Message; $m = $m -replace '\s+', ' '; $m.Substring(0, [Math]::Min(120, $m.Length)) }} | Format-Table -Wrap
    }

    function Invoke-KDManualTests {
        do {
            Write-KDHeader
            Write-Host $L.ManualTitle -ForegroundColor Cyan
            Write-Host "  [1] BIOS/UEFI"
            Write-Host "  [2] External keyboard isolation"
            Write-Host "  [3] Touchpad / palm rejection isolation"
            Write-Host "  [B] Back"
            $op = Read-Host $L.Prompt
            switch ($op.ToUpperInvariant()) {
                '1' {
                    Write-Host "Restart into BIOS/UEFI, place focus in a text/search field if available, keep hands off for 2-5 minutes." -ForegroundColor Yellow
                    $script:KeyboardDoctorReport.Manual.Bios = (Read-Host $L.BiosAsk).Trim().ToLowerInvariant()
                    Pause-KeyboardDoctor
                }
                '2' {
                    Write-Host "Use a USB keyboard. If safe, disable/avoid the internal keyboard, then observe in Notepad." -ForegroundColor Yellow
                    $script:KeyboardDoctorReport.Manual.ExternalKeyboard = (Read-Host $L.ExternalAsk).Trim().ToLowerInvariant()
                    Pause-KeyboardDoctor
                }
                '3' {
                    Write-Host "Disable touchpad via hotkey/Settings/Device Manager or test palm rejection, then observe." -ForegroundColor Yellow
                    $script:KeyboardDoctorReport.Manual.Touchpad = (Read-Host $L.TouchpadAsk).Trim().ToLowerInvariant()
                    Pause-KeyboardDoctor
                }
            }
        } while ($op.ToUpperInvariant() -ne 'B')
    }

    function Invoke-KDMonitor {
        Write-KDHeader
        Write-Host $L.MonitorWarn -ForegroundColor Yellow
        $consent = Read-Host $L.Confirm
        if ($consent -ne 'CONSENT') { Write-Host $L.Cancelled; Pause-KeyboardDoctor; return }
        $minutes = Read-Host $L.MonitorMinutes
        if ([string]::IsNullOrWhiteSpace($minutes) -or $minutes -notmatch '^\d+$') { $minutes = 3 }
        $minutes = [Math]::Max(1, [Math]::Min(10, [int]$minutes))
        $api = '[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vk);'
        if (-not ([System.Management.Automation.PSTypeName]'Atlas.KeyboardDoctor.Native').Type) {
            Add-Type -Name Native -Namespace Atlas.KeyboardDoctor -MemberDefinition $api
        }
        $map = @{
            8='Backspace';9='Tab';13='Enter';27='Esc';32='Space';46='Delete'
            48='0';49='1';50='2';51='3';52='4';53='5';54='6';55='7';56='8';57='9'
            65='A';66='B';67='C';68='D';69='E';70='F';71='G';72='H';73='I';74='J';75='K';76='L';77='M';78='N';79='O';80='P';81='Q';82='R';83='S';84='T';85='U';86='V';87='W';88='X';89='Y';90='Z'
            112='F1';113='F2';114='F3';115='F4';116='F5';117='F6';118='F7';119='F8';120='F9';121='F10';122='F11';123='F12'
        }
        $ignore = @(16,17,18,91,92,160,161,162,163,164,165)
        $start = Get-Date
        $end = $start.AddMinutes($minutes)
        $captured = @()
        Write-Host $L.MonitorActive -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        while ((Get-Date) -lt $end) {
            foreach ($i in 8..123) {
                if ($i -in $ignore) { continue }
                $state = [Atlas.KeyboardDoctor.Native]::GetAsyncKeyState($i)
                if (($state -band 0x0001) -ne 0) {
                    $name = if ($map.ContainsKey($i)) { $map[$i] } else { "VK$i" }
                    $entry = [pscustomobject]@{ Time = Get-Date; Key = $name; Code = $i }
                    $captured += $entry
                    Write-Host ("  {0:HH:mm:ss.fff}  {1}" -f $entry.Time, $entry.Key) -ForegroundColor Yellow
                }
            }
            Start-Sleep -Milliseconds 75
        }
        $script:KeyboardDoctorReport.Monitor += $captured
        Write-Host ($L.MonitorDone -f $captured.Count) -ForegroundColor Green
        Pause-KeyboardDoctor
    }

    function Invoke-KDDisableAccessibilityKeys {
        $targets = @(
            @{ Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Value='506' },
            @{ Path='HKCU:\Control Panel\Accessibility\Keyboard Response'; Name='Flags'; Value='122' },
            @{ Path='HKCU:\Control Panel\Accessibility\ToggleKeys'; Name='Flags'; Value='58' },
            @{ Path='HKCU:\Control Panel\Accessibility\Keyboard Preference'; Name='On'; Value='0' }
        )
        foreach ($tgt in $targets) {
            if (-not (Test-Path -LiteralPath $tgt.Path)) { New-Item -Path $tgt.Path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $tgt.Path -Name $tgt.Name -Value $tgt.Value -ErrorAction Stop
        }
        Write-Host $L.AccessibilityDisabled -ForegroundColor Green
    }

    function Invoke-KDRepairMenu {
        do {
            Write-KDHeader
            Write-Host $L.RepairTitle -ForegroundColor Cyan
            Write-Host $L.RepairWarn -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  $($L.Repair1)"
            Write-Host "  $($L.Repair2)"
            Write-Host "  $($L.Repair3)"
            Write-Host "  $($L.RepairB)"
            $op = Read-Host $L.Prompt
            switch ($op.ToUpperInvariant()) {
                '1' {
                    $confirm = Read-Host $L.Confirm
                    if ($confirm -ne 'YES' -and $confirm -ne 'SI') { Write-Host $L.Cancelled; Pause-KeyboardDoctor; break }
                    try { Invoke-KDDisableAccessibilityKeys } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
                    Pause-KeyboardDoctor
                }
                '2' { try { Start-Process devmgmt.msc } catch { Write-Host $_.Exception.Message -ForegroundColor Red }; Pause-KeyboardDoctor }
                '3' { try { Start-Process 'ms-settings:easeofaccess-keyboard' } catch { Start-Process control.exe 'keyboard' }; Pause-KeyboardDoctor }
            }
        } while ($op.ToUpperInvariant() -ne 'B')
    }

    function ConvertTo-KDHtml {
        param([string]$Text)
        return [System.Net.WebUtility]::HtmlEncode([string]$Text)
    }

    function New-KDTable {
        param([array]$Rows, [string[]]$Columns)
        if (-not $Rows -or $Rows.Count -eq 0) { return '<p class="muted">No data.</p>' }
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('<table><thead><tr>')
        foreach ($c in $Columns) { [void]$sb.AppendLine("<th>$(ConvertTo-KDHtml $c)</th>") }
        [void]$sb.AppendLine('</tr></thead><tbody>')
        foreach ($r in $Rows) {
            [void]$sb.AppendLine('<tr>')
            foreach ($c in $Columns) {
                $v = ''
                try { $v = $r.$c } catch {}
                [void]$sb.AppendLine("<td>$(ConvertTo-KDHtml $v)</td>")
            }
            [void]$sb.AppendLine('</tr>')
        }
        [void]$sb.AppendLine('</tbody></table>')
        return $sb.ToString()
    }

    function Export-KDReport {
        Invoke-KDQuickDiagnosis | Out-Null
        $dir = Join-Path $env:USERPROFILE 'Desktop'
        if (-not (Test-Path -LiteralPath $dir)) { $dir = $PWD.Path }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $htmlPath = Join-Path $dir "Atlas-KeyboardDoctor-$stamp.html"
        $txtPath = Join-Path $dir "Atlas-KeyboardDoctor-$stamp.txt"

        $findRows = @($script:KeyboardDoctorReport.Findings | ForEach-Object {
            [pscustomobject]@{ Severity=$_.Severity; Finding=$_.Finding; Recommendation=$_.Recommendation }
        })
        $monitorRows = @($script:KeyboardDoctorReport.Monitor | Select-Object @{n='Time';e={ '{0:HH:mm:ss.fff}' -f $_.Time }}, Key, Code)
        $manualRows = @(
            [pscustomobject]@{ Test='BIOS/UEFI'; Result=$script:KeyboardDoctorReport.Manual.Bios },
            [pscustomobject]@{ Test='External keyboard'; Result=$script:KeyboardDoctorReport.Manual.ExternalKeyboard },
            [pscustomobject]@{ Test='Touchpad'; Result=$script:KeyboardDoctorReport.Manual.Touchpad }
        )

        $css = @'
body{font-family:Segoe UI,Arial,sans-serif;background:#f4f7fb;color:#162033;margin:0;padding:24px}
.wrap{max-width:1080px;margin:auto;background:#fff;border:1px solid #d8e0ec;border-radius:16px;box-shadow:0 8px 30px rgba(15,23,42,.08);overflow:hidden}
header{background:#172554;color:#fff;padding:22px 26px}
h1{margin:0;font-size:24px} h2{margin-top:28px;color:#172554;border-bottom:2px solid #dbeafe;padding-bottom:6px}
.content{padding:24px 26px}.badge{display:inline-block;border-radius:999px;padding:8px 14px;font-weight:700;background:#e0f2fe;color:#075985}
.risk{background:#fee2e2;color:#991b1b}.observation{background:#fef3c7;color:#92400e}.apto{background:#dcfce7;color:#166534}
table{width:100%;border-collapse:collapse;margin:12px 0 18px}th{background:#dbeafe;color:#172554;text-align:left}th,td{border:1px solid #d8e0ec;padding:8px;vertical-align:top}.muted{color:#64748b}
footer{padding:14px 26px;background:#f8fafc;color:#64748b;font-size:12px}
'@
        $resultClass = 'apto'
        if ($script:KeyboardDoctorReport.Result -eq $L.ResultRisk) { $resultClass = 'risk' }
        elseif ($script:KeyboardDoctorReport.Result -eq $L.ResultObs) { $resultClass = 'observation' }

        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine("<!doctype html><html lang='$($L.HtmlLang)'><head><meta charset='utf-8'><title>$($L.ReportTitle)</title><style>$css</style></head><body><div class='wrap'>")
        [void]$sb.AppendLine("<header><h1>$($L.ReportTitle)</h1><p>$($L.Generated): $(Get-Date -Format 'yyyy-MM-dd HH:mm')</p></header><div class='content'>")
        [void]$sb.AppendLine("<h2>$($L.Summary)</h2><p><span class='badge $resultClass'>$($script:KeyboardDoctorReport.Result)</span></p>")
        [void]$sb.AppendLine('<table><tbody>')
        [void]$sb.AppendLine("<tr><th>$($L.Computer)</th><td>$(ConvertTo-KDHtml $script:KeyboardDoctorReport.Computer)</td></tr>")
        [void]$sb.AppendLine("<tr><th>$($L.Manufacturer)</th><td>$(ConvertTo-KDHtml $script:KeyboardDoctorReport.Manufacturer)</td></tr>")
        [void]$sb.AppendLine("<tr><th>$($L.Model)</th><td>$(ConvertTo-KDHtml $script:KeyboardDoctorReport.Model)</td></tr>")
        [void]$sb.AppendLine("<tr><th>$($L.OS)</th><td>$(ConvertTo-KDHtml $script:KeyboardDoctorReport.OS)</td></tr>")
        [void]$sb.AppendLine('</tbody></table>')
        [void]$sb.AppendLine("<h2>$($L.Findings)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $findRows -Columns @('Severity','Finding','Recommendation')))
        [void]$sb.AppendLine("<h2>$($L.Device)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $script:KeyboardDoctorReport.Keyboards -Columns @('FriendlyName','Class','Status','InstanceId')))
        [void]$sb.AppendLine("<h2>Touchpad / HID</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $script:KeyboardDoctorReport.PointingDevices -Columns @('FriendlyName','Class','Status','InstanceId')))
        [void]$sb.AppendLine("<h2>$($L.Accessibility)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $script:KeyboardDoctorReport.Accessibility -Columns @('Name','Enabled','Flags')))
        [void]$sb.AppendLine("<h2>$($L.Battery)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows @($script:KeyboardDoctorReport.Battery) -Columns @('Present','Name','Status','EstimatedChargeRemaining','WearPercent','Note')))
        [void]$sb.AppendLine("<h2>$($L.ManualTitle)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $manualRows -Columns @('Test','Result')))
        [void]$sb.AppendLine("<h2>$($L.Events)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows (@($script:KeyboardDoctorReport.Events | Select-Object -First 30 TimeCreated, ProviderName, Id, LevelDisplayName, @{n='Message';e={ ([string]$_.Message) -replace '\s+', ' ' }})) -Columns @('TimeCreated','ProviderName','Id','LevelDisplayName','Message')))
        [void]$sb.AppendLine("<h2>Hands-off monitor</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $monitorRows -Columns @('Time','Key','Code')))
        [void]$sb.AppendLine("</div><footer>ATLAS PC SUPPORT - Keyboard Doctor</footer></div></body></html>")
        [System.IO.File]::WriteAllText($htmlPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($true))

        $txt = [System.Text.StringBuilder]::new()
        [void]$txt.AppendLine($L.ReportTitle)
        [void]$txt.AppendLine("$($L.Generated): $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
        [void]$txt.AppendLine("$($L.Computer): $($script:KeyboardDoctorReport.Computer)")
        [void]$txt.AppendLine("$($L.ResultApto)/$($L.ResultObs)/$($L.ResultRisk): $($script:KeyboardDoctorReport.Result)")
        [void]$txt.AppendLine("")
        [void]$txt.AppendLine($L.Findings)
        foreach ($f in $script:KeyboardDoctorReport.Findings) {
            [void]$txt.AppendLine("- [$($f.Severity)] $($f.Finding)")
            [void]$txt.AppendLine("  -> $($f.Recommendation)")
        }
        [void]$txt.AppendLine("")
        [void]$txt.AppendLine("Manual: BIOS=$($script:KeyboardDoctorReport.Manual.Bios); External=$($script:KeyboardDoctorReport.Manual.ExternalKeyboard); Touchpad=$($script:KeyboardDoctorReport.Manual.Touchpad)")
        [void]$txt.AppendLine("Monitor captured keys: $($script:KeyboardDoctorReport.Monitor.Count)")
        [System.IO.File]::WriteAllText($txtPath, $txt.ToString(), [System.Text.UTF8Encoding]::new($true))

        Write-Host ($L.ExportSaved -f $htmlPath) -ForegroundColor Green
        Write-Host ($L.ExportSaved -f $txtPath) -ForegroundColor Green
        try { Invoke-Item -LiteralPath $htmlPath } catch {}
    }

    do {
        Write-KDHeader
        Write-Host "  $($L.Menu1)"
        Write-Host "  $($L.Menu2)"
        Write-Host "  $($L.Menu3)"
        Write-Host "  $($L.Menu4)"
        Write-Host "  $($L.Menu5)"
        Write-Host "  $($L.Menu6)"
        Write-Host "  $($L.Menu7)"
        Write-Host "  $($L.Menu8)"
        Write-Host "  $($L.Menu9)"
        Write-Host "  $($L.MenuQ)"
        Write-Host ""
        $op = Read-Host $L.Prompt
        switch ($op.ToUpperInvariant()) {
            '1' {
                Write-KDHeader
                Write-Host $L.Running -ForegroundColor Cyan
                $summary = Invoke-KDQuickDiagnosis
                $summary | Format-List
                Write-Host "`n$($L.Findings):" -ForegroundColor Cyan
                $script:KeyboardDoctorReport.Findings | Format-Table Severity, Finding, Recommendation -Wrap
                Pause-KeyboardDoctor
            }
            '2' { Write-KDHeader; Show-KDDevices; Pause-KeyboardDoctor }
            '3' { Write-KDHeader; Show-KDAccessibility; Pause-KeyboardDoctor }
            '4' { Write-KDHeader; Show-KDBattery; Pause-KeyboardDoctor }
            '5' { Write-KDHeader; Show-KDEvents; Pause-KeyboardDoctor }
            '6' { Invoke-KDManualTests }
            '7' { Invoke-KDMonitor }
            '8' { Invoke-KDRepairMenu }
            '9' { Write-KDHeader; Export-KDReport; Pause-KeyboardDoctor }
        }
    } while ($op.ToUpperInvariant() -ne 'Q')
}
