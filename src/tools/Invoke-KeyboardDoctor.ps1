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
        Coverage = @{}
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
            $cs = Get-CimInstance -OperationTimeoutSec 10 Win32_ComputerSystem -ErrorAction Stop
            $script:KeyboardDoctorReport.Manufacturer = [string]$cs.Manufacturer
            $script:KeyboardDoctorReport.Model = [string]$cs.Model
        } catch {}
        try {
            $os = Get-CimInstance -OperationTimeoutSec 10 Win32_OperatingSystem -ErrorAction Stop
            $script:KeyboardDoctorReport.OS = ('{0} {1}' -f $os.Caption, $os.Version)
        } catch {}
    }

    function Get-KDDevicesByClass {
        param([string[]]$Classes)
        $read = Invoke-AtlasInventoryRead -Source ('PnP: ' + ($Classes -join ', ')) -Query {
            Get-CimInstance Win32_PnPEntity -OperationTimeoutSec 10 -ErrorAction Stop | Where-Object { $_.PNPClass -in $Classes } |
                Select-Object @{n='FriendlyName';e={$_.Name}}, @{n='Class';e={$_.PNPClass}}, Status, @{n='InstanceId';e={$_.PNPDeviceID}}
        }
        $script:KeyboardDoctorReport.Coverage[($Classes -join ',')] = $read.State
        return @($read.Items)
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
            $enabled = $null
            try {
                $p = Get-ItemProperty -LiteralPath $d.Path -ErrorAction Stop
                $flags = [string]$p.Flags
                $num = 0
                if ([int]::TryParse($flags, [ref]$num)) { $enabled = (($num -band 1) -eq 1) }
            } catch {}
            $rows += [pscustomobject]@{
                Name = $d.Name
                Enabled = $enabled
                Flags = if ($flags) { $flags } else { $L.Unknown }
                State = if ($null -ne $enabled) { 'Observed' } else { 'NotEvaluated' }
            }
        }
        $script:KeyboardDoctorReport.Accessibility = $rows
        $script:KeyboardDoctorReport.Coverage['Accessibility'] = if (@($rows | Where-Object State -eq 'NotEvaluated').Count) { 'NotEvaluated' } else { 'Observed' }
        return $rows
    }

    function Get-KDBattery {
        $read = Invoke-AtlasInventoryRead -Source 'Battery status' -Query { Get-CimInstance Win32_Battery -OperationTimeoutSec 10 -ErrorAction Stop }
        $script:KeyboardDoctorReport.Coverage['Battery'] = $read.State
        # Do not join unrelated first rows; detailed capacity remains in Master.
        $result = [pscustomobject]@{
            Present = if ($read.State -eq 'Observed') { [bool]$read.Items.Count } else { $null }
            Name = (@($read.Items | ForEach-Object Name) -join '; ')
            Status = (@($read.Items | ForEach-Object Status) -join '; ')
            EstimatedChargeRemaining = if ($read.Items.Count -eq 1 -and $null -ne $read.Items[0].EstimatedChargeRemaining -and $read.Items[0].EstimatedChargeRemaining -ge 0 -and $read.Items[0].EstimatedChargeRemaining -le 100) { $read.Items[0].EstimatedChargeRemaining } else { $null }
            WearPercent = $null
            Note = 'Capacity wear not measured here; use the per-battery report in Diagnostico Master. No swelling diagnosis from inventory.'
        }
        $script:KeyboardDoctorReport.Battery = $result
        return $result
    }

    function Get-KDEvents {
        param([int]$Days = 14)
        $start = (Get-Date).AddDays(-1 * $Days)
        $events = @()
        $read = Invoke-AtlasInventoryRead -Source 'Keyboard-related System events' -Query {
            Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$start; Level=1,2,3 } -MaxEvents 500 -ErrorAction Stop | Where-Object {
                $_.ProviderName -match 'i8042|kbd|hid|Kernel-PnP|UserPnp|DriverFrameworks|SynTP|ETD|ELAN|I2C' -or
                $_.Message -match 'keyboard|teclado|touchpad|trackpad|hid|i2c|ps/2'
            } | Select-Object -First 80 TimeCreated, ProviderName, Id, LevelDisplayName, Message
        }
        $script:KeyboardDoctorReport.Coverage['Events'] = $read.State
        $events = @($read.Items)
        $script:KeyboardDoctorReport.Events = @($events | Sort-Object TimeCreated -Descending)
        return $script:KeyboardDoctorReport.Events
    }

    function Invoke-KDQuickDiagnosis {
        $script:KeyboardDoctorReport.Findings = @()
        $script:KeyboardDoctorReport.Recommendations = @()
        $script:KeyboardDoctorReport.Result = 'Inventory observations; hardware health not certified'

        $script:KeyboardDoctorReport.Coverage = @{}
        Get-KDSystemInfo
        $keyboards = @(Get-KDKeyboardDevices)
        $touch = @(Get-KDPointingDevices)
        $access = @(Get-KDAccessibility)
        $battery = Get-KDBattery
        $events = @(Get-KDEvents -Days 14)

        if ($script:KeyboardDoctorReport.Coverage.Keyboard -eq 'Observed' -and $keyboards.Count -eq 0) {
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
            Add-KDFinding 'observation' ("Battery wear $($battery.WearPercent)%; this does not establish swelling or keyboard pressure.") 'Physical inspection is required to evaluate swelling; wear alone is not evidence.'
        }
        if ($events.Count -ge 8) {
            $sev2 = if ($events.Count -ge 25) { 'risk' } else { 'observation' }
            Add-KDFinding $sev2 ($L.FindingEvents -f $events.Count) $L.RecEvents
        }
        if ($script:KeyboardDoctorReport.Manual.Bios -eq 'y') { Add-KDFinding 'risk' $L.FindingBios $L.RecBios }
        if ($script:KeyboardDoctorReport.Manual.ExternalKeyboard -eq 'stopped') { Add-KDFinding 'risk' $L.FindingExternal $L.RecExternal }
        if ($script:KeyboardDoctorReport.Manual.Touchpad -eq 'stopped') { Add-KDFinding 'observation' $L.FindingTouchpad $L.RecTouchpad }
        $monitorCount = Get-KDMonitorCount -Observations @($script:KeyboardDoctorReport.Monitor)
        if ($monitorCount -gt 0) { Add-KDFinding 'observation' ($L.FindingMonitor -f $monitorCount) $L.RecMonitor }
        foreach ($source in @($script:KeyboardDoctorReport.Coverage.Keys)) {
            if ($script:KeyboardDoctorReport.Coverage[$source] -ne 'Observed') { Add-KDFinding 'observation' "$source not evaluated; inventory incomplete." 'Check availability and permissions before repair.' }
        }
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
        if ($script:KeyboardDoctorReport.Coverage.Keyboard -ne 'Observed') { Write-Warning 'Keyboard inventory not evaluated.'; return }
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
        if ($script:KeyboardDoctorReport.Coverage.Events -ne 'Observed') { Write-Warning 'Events not evaluated.'; return }
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

    function Get-KDMonitorCount {
        param([object[]]$Observations)
        $total = 0
        foreach ($row in $Observations) {
            $value = 0
            if ($row.Scope -eq 'FocusedWindow' -and [int]::TryParse([string]$row.Count, [ref]$value) -and $value -ge 0) { $total += $value }
        }
        return $total
    }

    function Invoke-KDMonitor {
    Write-Host 'Focused keyboard test only. No global keyboard capture. Close the window or press Escape to stop; no typed text is recorded.'
    if((Read-Host 'Type CONSENT to open the test window') -cne 'CONSENT'){return}
    Add-Type -AssemblyName PresentationFramework
    $window=[Windows.Window]::new();$window.Title='Atlas focused keyboard test';$window.Width=560;$window.Height=220
    $label=[Windows.Controls.TextBlock]::new();$label.Text='Press keys while this window has focus. Escape closes. Events: 0';$label.TextWrapping='Wrap';$label.Margin='24'
    $window.Content=$label
    $count=[Collections.Generic.List[datetime]]::new()
    $window.Add_KeyDown({param($sender,$eventArgs)
        if($eventArgs.Key -eq [Windows.Input.Key]::Escape){$sender.Close();return}
        $count.Add([datetime]::UtcNow);$label.Text="Key-down events observed in this window: $($count.Count). Escape closes."
    }.GetNewClosure())
    [void]$window.ShowDialog()
    $script:KeyboardDoctorReport.Monitor=@([pscustomobject]@{Scope='FocusedWindow';Count=$count.Count;CapturedText=$false;AtUtc=[datetime]::UtcNow})
}

    function Invoke-KDDisableAccessibilityKeys {
    Write-Host 'Review accessibility preferences for the intended user. Atlas does not replace existing accessibility flags with fixed values.'
    Start-Process -FilePath 'ms-settings:easeofaccess-keyboard' -ErrorAction Stop | Out-Null
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
        $monitorRows = @($script:KeyboardDoctorReport.Monitor | Select-Object Scope, Count, CapturedText, AtUtc)
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
        [void]$sb.AppendLine("<h2>Focused-window key count (no text captured)</h2>")
        [void]$sb.AppendLine((New-KDTable -Rows $monitorRows -Columns @('Scope','Count','CapturedText','AtUtc')))
        [void]$sb.AppendLine("</div><footer>ATLAS PC SUPPORT - Keyboard Doctor</footer></div></body></html>")
        Write-AtlasShareableReport -Path $htmlPath -Content $sb.ToString() -Tool 'Keyboard observations'

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
        [void]$txt.AppendLine("Focused test count: $(Get-KDMonitorCount -Observations @($script:KeyboardDoctorReport.Monitor))")
        Write-AtlasShareableReport -Path $txtPath -Content $txt.ToString() -Tool 'Keyboard observations'

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
