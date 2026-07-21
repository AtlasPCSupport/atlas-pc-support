function Invoke-PrinterDoctor {
    <#
    .SYNOPSIS
      Printer Doctor: safe Windows printer diagnostics and optional repairs.

    .DESCRIPTION
      - Lists printers, ports, drivers, jobs, spooler state, and recent print events.
      - Tests network connectivity for printer IP/hostname.
      - Exports bilingual HTML/TXT reports.
      - Repair actions require explicit confirmation.
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
            Title='ATLAS PC SUPPORT - Printer Doctor'
            Subtitle='Safe printer diagnostics and optional repairs'
            Menu1='[1] Quick diagnosis'
            Menu2='[2] List printers / ports / drivers'
            Menu3='[3] Test printer IP or hostname'
            Menu4='[4] Print Spooler status'
            Menu5='[5] Print jobs / stuck queue'
            Menu6='[6] Recent print events'
            Menu7='[7] Repair actions (confirm required)'
            Menu8='[8] Export HTML/TXT report'
            MenuQ='[Q] Quit'
            Prompt='Option'
            Back='ENTER to continue'
            Running='Running...'
            Done='Done.'
            NoPrinters='No printers detected.'
            NoJobs='No print jobs detected.'
            NoEvents='No recent print events found.'
            Unknown='Unknown'
            Yes='Yes'
            No='No'
            Admin='Administrator'
            Computer='Computer'
            OS='Operating system'
            Printer='Printer'
            Default='Default'
            Shared='Shared'
            Offline='Offline'
            WorkOffline='Work offline'
            Status='Status'
            Driver='Driver'
            Port='Port'
            PortHost='Host/IP'
            Protocol='Protocol'
            Spooler='Print Spooler'
            ServiceStatus='Service status'
            StartType='Start type'
            Jobs='Jobs'
            JobId='Job ID'
            Owner='Owner'
            Document='Document'
            Submitted='Submitted'
            Size='Size'
            Pages='Pages'
            EventTime='Time'
            EventId='Event ID'
            Provider='Provider'
            Level='Level'
            Message='Message'
            PingAsk='Printer IP or hostname'
            PingOk='Host responds to ping.'
            PingFail='Host did not respond to ping.'
            PingNote='Some printers block ping; failure is not proof that the printer is offline.'
            RepairTitle='Repair actions'
            RepairWarn='These actions can interrupt printing. Use only after checking the queue and informing the customer.'
            Repair1='[1] Restart Print Spooler'
            Repair2='[2] Clear all print queues'
            Repair3='[3] Open Windows Printers settings'
            Repair4='[4] Print test page'
            RepairB='[B] Back'
            Confirm='Type YES to confirm'
            Cancelled='Cancelled.'
            NeedAdmin='This action may require Administrator rights.'
            SpoolerRestarted='Print Spooler restarted.'
            QueuesCleared='Print queues cleared.'
            AskPrinterName='Printer name'
            TestPageSent='Test page command sent.'
            ExportSaved='Report saved: {0}'
            ReportTitle='ATLAS PC SUPPORT - Printer Doctor Report'
            Generated='Generated'
            Summary='Summary'
            Findings='Findings'
            Recommendations='Recommendations'
            FindingNoSpooler='Print Spooler is not running.'
            RecNoSpooler='Restart Print Spooler, then retry printing.'
            FindingNoPrinter='No printers are installed or visible.'
            RecNoPrinter='Install the printer driver or add the network printer again.'
            FindingOffline='Printer marked offline/work offline: {0}'
            RecOffline='Disable Work Offline, verify USB/network connection, then print a test page.'
            FindingJobs='Stuck or pending jobs detected: {0}'
            RecJobs='If jobs are stuck, clear the queue after customer approval.'
            FindingEvents='Recent print errors/warnings detected: {0}'
            RecEvents='Review Event Viewer entries and printer driver before promising a software-only fix.'
            FindingOk='No strong printer red flags found in the quick check.'
            RecOk='Proceed with normal printer troubleshooting: cable/Wi-Fi, driver, app print settings, and test page.'
            HtmlLang='en'
        }
        es = @{
            Title='ATLAS PC SUPPORT - Printer Doctor'
            Subtitle='Diagnostico seguro de impresoras y reparaciones opcionales'
            Menu1='[1] Diagnostico rapido'
            Menu2='[2] Listar impresoras / puertos / drivers'
            Menu3='[3] Probar IP o hostname de impresora'
            Menu4='[4] Estado de Print Spooler'
            Menu5='[5] Trabajos / cola trabada'
            Menu6='[6] Eventos recientes de impresion'
            Menu7='[7] Acciones de reparacion (requieren confirmacion)'
            Menu8='[8] Exportar reporte HTML/TXT'
            MenuQ='[Q] Salir'
            Prompt='Opcion'
            Back='ENTER para continuar'
            Running='Ejecutando...'
            Done='Listo.'
            NoPrinters='No se detectaron impresoras.'
            NoJobs='No se detectaron trabajos de impresion.'
            NoEvents='No se encontraron eventos recientes de impresion.'
            Unknown='Desconocido'
            Yes='Si'
            No='No'
            Admin='Administrador'
            Computer='Equipo'
            OS='Sistema operativo'
            Printer='Impresora'
            Default='Predeterminada'
            Shared='Compartida'
            Offline='Offline'
            WorkOffline='Trabajar sin conexion'
            Status='Estado'
            Driver='Driver'
            Port='Puerto'
            PortHost='Host/IP'
            Protocol='Protocolo'
            Spooler='Print Spooler'
            ServiceStatus='Estado del servicio'
            StartType='Tipo de inicio'
            Jobs='Trabajos'
            JobId='ID trabajo'
            Owner='Usuario'
            Document='Documento'
            Submitted='Enviado'
            Size='Tamano'
            Pages='Paginas'
            EventTime='Hora'
            EventId='Event ID'
            Provider='Proveedor'
            Level='Nivel'
            Message='Mensaje'
            PingAsk='IP o hostname de impresora'
            PingOk='El host responde a ping.'
            PingFail='El host no respondio a ping.'
            PingNote='Algunas impresoras bloquean ping; fallar no prueba que la impresora este apagada.'
            RepairTitle='Acciones de reparacion'
            RepairWarn='Estas acciones pueden interrumpir impresiones. Usar solo despues de revisar la cola e informar al cliente.'
            Repair1='[1] Reiniciar Print Spooler'
            Repair2='[2] Limpiar todas las colas de impresion'
            Repair3='[3] Abrir configuracion de impresoras de Windows'
            Repair4='[4] Imprimir pagina de prueba'
            RepairB='[B] Volver'
            Confirm='Escribe SI para confirmar'
            Cancelled='Cancelado.'
            NeedAdmin='Esta accion puede requerir permisos de Administrador.'
            SpoolerRestarted='Print Spooler reiniciado.'
            QueuesCleared='Colas de impresion limpiadas.'
            AskPrinterName='Nombre de impresora'
            TestPageSent='Comando de pagina de prueba enviado.'
            ExportSaved='Reporte guardado: {0}'
            ReportTitle='ATLAS PC SUPPORT - Reporte Printer Doctor'
            Generated='Generado'
            Summary='Resumen'
            Findings='Hallazgos'
            Recommendations='Recomendaciones'
            FindingNoSpooler='Print Spooler no esta ejecutandose.'
            RecNoSpooler='Reiniciar Print Spooler y volver a probar impresion.'
            FindingNoPrinter='No hay impresoras instaladas o visibles.'
            RecNoPrinter='Instalar driver o agregar nuevamente la impresora de red.'
            FindingOffline='Impresora marcada offline/sin conexion: {0}'
            RecOffline='Desactivar Trabajar sin conexion, verificar USB/red y luego imprimir pagina de prueba.'
            FindingJobs='Trabajos trabados o pendientes detectados: {0}'
            RecJobs='Si la cola esta trabada, limpiarla despues de aprobacion del cliente.'
            FindingEvents='Errores/advertencias recientes de impresion: {0}'
            RecEvents='Revisar eventos y driver antes de prometer solucion solo por software.'
            FindingOk='No se encontraron alertas fuertes de impresora en el chequeo rapido.'
            RecOk='Continuar diagnostico normal: cable/Wi-Fi, driver, configuracion de app y pagina de prueba.'
            HtmlLang='es'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    $script:PrinterDoctorReport = [ordered]@{
        Generated = Get-Date
        Computer = $env:COMPUTERNAME
        OS = ''
        Printers = @()
        Ports = @()
        Drivers = @()
        Jobs = @()
        Spooler = $null
        Events = @()
        NetworkTests = @()
        Findings = @()
        Recommendations = @()
    }

    function Test-IsAdmin {
        try {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            $p = [Security.Principal.WindowsPrincipal]::new($id)
            return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch { return $false }
    }

    function Pause-PrinterDoctor {
        Write-Host ""
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $L.Back
            return
        }
        Read-Host $L.Back | Out-Null
    }

    function Write-PDHeader {
        Clear-Host
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title $L.Title -Color Yellow
            Write-AtlasStep $L.Subtitle
            Write-Host "$($L.Computer): $env:COMPUTERNAME | $($L.Admin): $(if (Test-IsAdmin) { $L.Yes } else { $L.No })" -ForegroundColor DarkGray
            Write-Host ""
            return
        }
        Write-Host "============================================================" -ForegroundColor DarkCyan
        Write-Host "  $($L.Title)" -ForegroundColor Cyan
        Write-Host "  $($L.Subtitle)" -ForegroundColor Gray
        Write-Host "============================================================" -ForegroundColor DarkCyan
        Write-Host "$($L.Computer): $env:COMPUTERNAME | $($L.Admin): $(if (Test-IsAdmin) { $L.Yes } else { $L.No })" -ForegroundColor DarkGray
        Write-Host ""
    }

    function Add-Finding {
        param([string]$Finding, [string]$Recommendation)
        if ($script:PrinterDoctorReport.Findings -notcontains $Finding) { $script:PrinterDoctorReport.Findings += $Finding }
        if ($script:PrinterDoctorReport.Recommendations -notcontains $Recommendation) { $script:PrinterDoctorReport.Recommendations += $Recommendation }
    }

    function Get-PDSystemInfo {
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
            $script:PrinterDoctorReport.OS = "$($os.Caption) $($os.OSArchitecture)"
        } catch {
            $script:PrinterDoctorReport.OS = $L.Unknown
        }
    }

    function Get-PDPrinters {
        $printers = @()
        try {
            $printers = @(Get-CimInstance Win32_Printer -ErrorAction Stop | Sort-Object Name | ForEach-Object {
                [pscustomobject]@{
                    Name = $_.Name
                    Default = [bool]$_.Default
                    Shared = [bool]$_.Shared
                    Network = [bool]$_.Network
                    WorkOffline = [bool]$_.WorkOffline
                    PrinterStatus = $_.PrinterStatus
                    DetectedErrorState = $_.DetectedErrorState
                    DriverName = $_.DriverName
                    PortName = $_.PortName
                }
            })
        } catch {}
        $script:PrinterDoctorReport.Printers = $printers
        return $printers
    }

    function Get-PDPorts {
        $ports = @()
        try {
            if (Get-Command Get-PrinterPort -ErrorAction SilentlyContinue) {
                $ports = @(Get-PrinterPort -ErrorAction Stop | Sort-Object Name | ForEach-Object {
                    [pscustomobject]@{
                        Name = $_.Name
                        HostAddress = $_.PrinterHostAddress
                        PortNumber = $_.PortNumber
                        Protocol = $_.Protocol
                        Description = $_.Description
                    }
                })
            }
        } catch {}
        if (-not $ports) {
            try {
                $ports = @(Get-CimInstance Win32_TCPIPPrinterPort -ErrorAction Stop | Sort-Object Name | ForEach-Object {
                    [pscustomobject]@{
                        Name = $_.Name
                        HostAddress = $_.HostAddress
                        PortNumber = $_.PortNumber
                        Protocol = $_.Protocol
                        Description = $_.Description
                    }
                })
            } catch {}
        }
        $script:PrinterDoctorReport.Ports = @($ports)
        return @($ports)
    }

    function Get-PDDrivers {
        $drivers = @()
        try {
            $drivers = @(Get-CimInstance Win32_PrinterDriver -ErrorAction Stop | Sort-Object Name | ForEach-Object {
                [pscustomobject]@{
                    Name = $_.Name
                    DriverPath = $_.DriverPath
                    InfName = $_.InfName
                    SupportedPlatform = $_.SupportedPlatform
                    Version = $_.Version
                }
            })
        } catch {}
        $script:PrinterDoctorReport.Drivers = $drivers
        return $drivers
    }

    function Get-PDSpooler {
        $svc = $null
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='Spooler'" -ErrorAction Stop
            $svc = [pscustomobject]@{
                Name = $svc.Name
                State = $svc.State
                Status = $svc.Status
                StartMode = $svc.StartMode
                ProcessId = $svc.ProcessId
            }
        } catch {}
        $script:PrinterDoctorReport.Spooler = $svc
        return $svc
    }

    function Get-PDJobs {
        $jobs = @()
        try {
            $jobs = @(Get-CimInstance Win32_PrintJob -ErrorAction Stop | Sort-Object Name | ForEach-Object {
                [pscustomobject]@{
                    Name = $_.Name
                    Owner = $_.Owner
                    Document = $_.Document
                    JobStatus = $_.JobStatus
                    Status = $_.Status
                    TimeSubmitted = $_.TimeSubmitted
                    Size = $_.Size
                    TotalPages = $_.TotalPages
                }
            })
        } catch {}
        $script:PrinterDoctorReport.Jobs = $jobs
        return $jobs
    }

    function Get-PDPrintEvents {
        param([int]$Days = 7)
        $since = (Get-Date).AddDays(-1 * $Days)
        $events = @()
        $queries = @(
            @{ LogName='Microsoft-Windows-PrintService/Admin'; StartTime=$since; Level=1,2,3 }
            @{ LogName='System'; ProviderName='Microsoft-Windows-PrintSpooler'; StartTime=$since; Level=1,2,3 }
        )
        foreach ($q in $queries) {
            try {
                $events += @(Get-WinEvent -FilterHashtable $q -ErrorAction Stop | Select-Object -First 50 TimeCreated, ProviderName, Id, LevelDisplayName, Message)
            } catch {}
        }
        $script:PrinterDoctorReport.Events = @($events | Sort-Object TimeCreated -Descending)
        return $script:PrinterDoctorReport.Events
    }

    function Invoke-PDQuickDiagnosis {
        $script:PrinterDoctorReport.Findings = @()
        $script:PrinterDoctorReport.Recommendations = @()
        Get-PDSystemInfo
        $printers = @(Get-PDPrinters)
        $ports = @(Get-PDPorts)
        $drivers = @(Get-PDDrivers)
        $spooler = Get-PDSpooler
        $jobs = @(Get-PDJobs)
        $events = @(Get-PDPrintEvents -Days 7)

        if (-not $spooler -or $spooler.State -ne 'Running') { Add-Finding $L.FindingNoSpooler $L.RecNoSpooler }
        if ($printers.Count -eq 0) { Add-Finding $L.FindingNoPrinter $L.RecNoPrinter }
        foreach ($p in $printers | Where-Object { $_.WorkOffline -or $_.PrinterStatus -in 7, 9 }) {
            Add-Finding ($L.FindingOffline -f $p.Name) $L.RecOffline
        }
        if ($jobs.Count -gt 0) { Add-Finding ($L.FindingJobs -f $jobs.Count) $L.RecJobs }
        if ($events.Count -gt 0) { Add-Finding ($L.FindingEvents -f $events.Count) $L.RecEvents }
        if ($script:PrinterDoctorReport.Findings.Count -eq 0) { Add-Finding $L.FindingOk $L.RecOk }

        [pscustomobject]@{
            Printers = $printers.Count
            Ports = $ports.Count
            Drivers = $drivers.Count
            Jobs = $jobs.Count
            PrintEvents = $events.Count
            SpoolerState = if ($spooler) { $spooler.State } else { $L.Unknown }
        }
    }

    function Show-PDPrinters {
        $printers = @(Get-PDPrinters)
        $ports = @(Get-PDPorts)
        $drivers = @(Get-PDDrivers)
        if ($printers.Count -eq 0) { Write-Host $L.NoPrinters -ForegroundColor Yellow; return }
        $printers | Format-Table Name, Default, Network, WorkOffline, PrinterStatus, DriverName, PortName -AutoSize
        if ($ports.Count -gt 0) {
            Write-Host "`n$($L.Port):" -ForegroundColor Cyan
            $ports | Format-Table Name, HostAddress, PortNumber, Protocol -AutoSize
        }
        if ($drivers.Count -gt 0) {
            Write-Host "`n$($L.Driver):" -ForegroundColor Cyan
            $drivers | Select-Object -First 20 Name, Version, SupportedPlatform | Format-Table -AutoSize
        }
    }

    function Invoke-PDPing {
        $hostName = Read-Host $L.PingAsk
        if ([string]::IsNullOrWhiteSpace($hostName)) { return }
        $ok = $false
        try { $ok = Test-Connection -ComputerName $hostName.Trim() -Count 2 -Quiet -ErrorAction SilentlyContinue } catch {}
        $entry = [pscustomobject]@{ Host = $hostName.Trim(); Success = [bool]$ok; TestedAt = Get-Date }
        $script:PrinterDoctorReport.NetworkTests += $entry
        if ($ok) { Write-Host $L.PingOk -ForegroundColor Green } else { Write-Host $L.PingFail -ForegroundColor Yellow }
        Write-Host $L.PingNote -ForegroundColor DarkGray
    }

    function Show-PDSpooler {
        $svc = Get-PDSpooler
        if (-not $svc) { Write-Host "$($L.Spooler): $($L.Unknown)" -ForegroundColor Yellow; return }
        $svc | Format-List
    }

    function Show-PDJobs {
        $jobs = @(Get-PDJobs)
        if ($jobs.Count -eq 0) { Write-Host $L.NoJobs -ForegroundColor Green; return }
        $jobs | Format-Table Name, Owner, Document, JobStatus, Status, TotalPages, Size -AutoSize
    }

    function Show-PDEvents {
        $events = @(Get-PDPrintEvents -Days 7)
        if ($events.Count -eq 0) { Write-Host $L.NoEvents -ForegroundColor Green; return }
        $events | Select-Object -First 20 TimeCreated, ProviderName, Id, LevelDisplayName, @{n='Message';e={ $m = [string]$_.Message; $m = $m -replace '\s+', ' '; $m.Substring(0, [Math]::Min(120, $m.Length)) }} | Format-Table -Wrap
    }

    function Invoke-PDRepairMenu {
        do {
            Write-PDHeader
            Write-Host $L.RepairTitle -ForegroundColor Cyan
            Write-Host $L.RepairWarn -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  $($L.Repair1)"
            Write-Host "  $($L.Repair2)"
            Write-Host "  $($L.Repair3)"
            Write-Host "  $($L.Repair4)"
            Write-Host "  $($L.RepairB)"
            $op = Read-Host $L.Prompt
            switch ($op.ToUpperInvariant()) {
                '1' {
                    $confirm = Read-Host $L.Confirm
                    if ($confirm -ne 'YES' -and $confirm -ne 'SI') { Write-Host $L.Cancelled; Pause-PrinterDoctor; break }
                    try { Restart-Service -Name Spooler -Force -ErrorAction Stop; Write-Host $L.SpoolerRestarted -ForegroundColor Green } catch { Write-Host "$($L.NeedAdmin) $($_.Exception.Message)" -ForegroundColor Red }
                    Pause-PrinterDoctor
                }
                '2' {
                    $confirm = Read-Host $L.Confirm
                    if ($confirm -ne 'YES' -and $confirm -ne 'SI') { Write-Host $L.Cancelled; Pause-PrinterDoctor; break }
                    try {
                        Stop-Service -Name Spooler -Force -ErrorAction Stop
                        $spool = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
                        if (Test-Path -LiteralPath $spool) {
                            Get-ChildItem -LiteralPath $spool -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                        }
                        Start-Service -Name Spooler -ErrorAction Stop
                        Write-Host $L.QueuesCleared -ForegroundColor Green
                    } catch { Write-Host "$($L.NeedAdmin) $($_.Exception.Message)" -ForegroundColor Red }
                    Pause-PrinterDoctor
                }
                '3' {
                    try { Start-Process 'ms-settings:printers' } catch { try { Start-Process 'control.exe' 'printers' } catch {} }
                    Pause-PrinterDoctor
                }
                '4' {
                    $name = Read-Host $L.AskPrinterName
                    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host $L.Cancelled; Pause-PrinterDoctor; break }
                    try {
                        $printer = Get-CimInstance Win32_Printer -Filter ("Name='{0}'" -f ($name.Replace("'","''"))) -ErrorAction Stop
                        if ($printer) { Invoke-CimMethod -InputObject $printer -MethodName PrintTestPage -ErrorAction Stop | Out-Null; Write-Host $L.TestPageSent -ForegroundColor Green }
                    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
                    Pause-PrinterDoctor
                }
                'B' { return }
            }
        } while ($true)
    }

    function ConvertTo-HtmlCell {
        param([object]$Value)
        return [System.Net.WebUtility]::HtmlEncode([string]$Value)
    }

    function Export-PDReport {
        Invoke-PDQuickDiagnosis | Out-Null
        $desktop = [Environment]::GetFolderPath('Desktop')
        $dir = Join-Path $desktop 'REPORTES_PC'
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $base = "PrinterDoctor-$env:COMPUTERNAME-$stamp"
        $htmlPath = Join-Path $dir "$base.html"
        $txtPath = Join-Path $dir "$base.txt"

        $txt = @()
        $txt += $L.ReportTitle
        $txt += "$($L.Computer): $env:COMPUTERNAME"
        $txt += "$($L.OS): $($script:PrinterDoctorReport.OS)"
        $txt += "$($L.Generated): $($script:PrinterDoctorReport.Generated)"
        $txt += ""
        $txt += $L.Findings
        $txt += ($script:PrinterDoctorReport.Findings | ForEach-Object { "- $_" })
        $txt += ""
        $txt += $L.Recommendations
        $txt += ($script:PrinterDoctorReport.Recommendations | ForEach-Object { "- $_" })
        $txt | Set-Content -LiteralPath $txtPath -Encoding UTF8

        $printerRows = if ($script:PrinterDoctorReport.Printers.Count) {
            ($script:PrinterDoctorReport.Printers | ForEach-Object { "<tr><td>$(ConvertTo-HtmlCell $_.Name)</td><td>$($_.Default)</td><td>$($_.WorkOffline)</td><td>$(ConvertTo-HtmlCell $_.DriverName)</td><td>$(ConvertTo-HtmlCell $_.PortName)</td></tr>" }) -join "`n"
        } else { "<tr><td colspan='5'>$($L.NoPrinters)</td></tr>" }
        $jobRows = if ($script:PrinterDoctorReport.Jobs.Count) {
            ($script:PrinterDoctorReport.Jobs | ForEach-Object { "<tr><td>$(ConvertTo-HtmlCell $_.Name)</td><td>$(ConvertTo-HtmlCell $_.Owner)</td><td>$(ConvertTo-HtmlCell $_.Document)</td><td>$(ConvertTo-HtmlCell $_.Status)</td></tr>" }) -join "`n"
        } else { "<tr><td colspan='4'>$($L.NoJobs)</td></tr>" }
        $eventRows = if ($script:PrinterDoctorReport.Events.Count) {
            ($script:PrinterDoctorReport.Events | Select-Object -First 20 | ForEach-Object { "<tr><td>$($_.TimeCreated)</td><td>$(ConvertTo-HtmlCell $_.ProviderName)</td><td>$($_.Id)</td><td>$(ConvertTo-HtmlCell $_.LevelDisplayName)</td><td>$(ConvertTo-HtmlCell $_.Message)</td></tr>" }) -join "`n"
        } else { "<tr><td colspan='5'>$($L.NoEvents)</td></tr>" }
        $findingsHtml = ($script:PrinterDoctorReport.Findings | ForEach-Object { "<li>$(ConvertTo-HtmlCell $_)</li>" }) -join "`n"
        $recsHtml = ($script:PrinterDoctorReport.Recommendations | ForEach-Object { "<li>$(ConvertTo-HtmlCell $_)</li>" }) -join "`n"
        $spoolerState = if ($script:PrinterDoctorReport.Spooler) { $script:PrinterDoctorReport.Spooler.State } else { $L.Unknown }

        $html = @"
<!DOCTYPE html>
<html lang="$($L.HtmlLang)">
<head><meta charset="UTF-8"><title>$($L.ReportTitle)</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;background:#f4f6f8;color:#222;margin:0;padding:20px}
.container{max-width:1100px;margin:auto;background:#fff;border-radius:8px;box-shadow:0 4px 16px rgba(0,0,0,.08);overflow:hidden}
.header{background:#002147;color:#fff;padding:24px;text-align:center;border-bottom:5px solid #FF5500}
.content{padding:22px}
h2{background:#0b3a67;color:#fff;padding:8px 14px;border-radius:4px;font-size:16px;margin-top:26px}
table{width:100%;border-collapse:collapse;margin-top:8px;font-size:13px}
th{background:#e8f1fb;color:#002147;text-align:left;padding:9px;border-bottom:2px solid #9fc5e8}
td{padding:9px;border-bottom:1px solid #ddd}
tr:nth-child(even){background:#f8f9fa}
.summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px}
.card{background:#f8fafc;border-left:4px solid #FF5500;padding:12px;border-radius:4px}
li{margin:6px 0}
</style></head>
<body><div class="container"><div class="header"><h1>$($L.ReportTitle)</h1><p>ATLAS PC SUPPORT</p></div><div class="content">
<div class="summary">
<div class="card"><strong>$($L.Computer)</strong><br>$env:COMPUTERNAME</div>
<div class="card"><strong>$($L.OS)</strong><br>$(ConvertTo-HtmlCell $script:PrinterDoctorReport.OS)</div>
<div class="card"><strong>$($L.Spooler)</strong><br>$(ConvertTo-HtmlCell $spoolerState)</div>
<div class="card"><strong>$($L.Generated)</strong><br>$($script:PrinterDoctorReport.Generated)</div>
</div>
<h2>$($L.Findings)</h2><ul>$findingsHtml</ul>
<h2>$($L.Recommendations)</h2><ul>$recsHtml</ul>
<h2>$($L.Printer)</h2><table><tr><th>$($L.Printer)</th><th>$($L.Default)</th><th>$($L.WorkOffline)</th><th>$($L.Driver)</th><th>$($L.Port)</th></tr>$printerRows</table>
<h2>$($L.Jobs)</h2><table><tr><th>$($L.JobId)</th><th>$($L.Owner)</th><th>$($L.Document)</th><th>$($L.Status)</th></tr>$jobRows</table>
<h2>$($L.EventTime)</h2><table><tr><th>$($L.EventTime)</th><th>$($L.Provider)</th><th>$($L.EventId)</th><th>$($L.Level)</th><th>$($L.Message)</th></tr>$eventRows</table>
</div></div></body></html>
"@
        $html | Out-File -LiteralPath $htmlPath -Encoding UTF8
        Write-Host ($L.ExportSaved -f $htmlPath) -ForegroundColor Green
        Write-Host ($L.ExportSaved -f $txtPath) -ForegroundColor Green
        try { Invoke-Item $htmlPath } catch {}
    }

    do {
        Write-PDHeader
        Write-Host "  $($L.Menu1)"
        Write-Host "  $($L.Menu2)"
        Write-Host "  $($L.Menu3)"
        Write-Host "  $($L.Menu4)"
        Write-Host "  $($L.Menu5)"
        Write-Host "  $($L.Menu6)"
        Write-Host "  $($L.Menu7)"
        Write-Host "  $($L.Menu8)"
        Write-Host "  $($L.MenuQ)"
        Write-Host ""
        $choice = Read-Host $L.Prompt
        switch ($choice.ToUpperInvariant()) {
            '1' { Write-Host $L.Running -ForegroundColor Cyan; Invoke-PDQuickDiagnosis | Format-List; Pause-PrinterDoctor }
            '2' { Show-PDPrinters; Pause-PrinterDoctor }
            '3' { Invoke-PDPing; Pause-PrinterDoctor }
            '4' { Show-PDSpooler; Pause-PrinterDoctor }
            '5' { Show-PDJobs; Pause-PrinterDoctor }
            '6' { Show-PDEvents; Pause-PrinterDoctor }
            '7' { Invoke-PDRepairMenu }
            '8' { Export-PDReport; Pause-PrinterDoctor }
            'Q' { return }
        }
    } while ($true)
}
