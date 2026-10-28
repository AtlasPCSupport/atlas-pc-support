# ============================================================
# Invoke-DiagnosticoMaster  ->  Full System Report
# i18n: Option A (en default + es secondary). Function name kept
# as Invoke-DiagnosticoMaster for tools.json compatibility.
# ============================================================

function Invoke-DiagnosticoMaster {
    [CmdletBinding()]
    param()

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
            HdrTitle      = 'DIAGNOSTICO MASTER - Full System Report'
            HdrSub        = 'Full System Diagnostic Protocol v82'
            DetectedPC    = 'DETECTED: {0}'
            AskNumPC      = '1. Enter PC number'
            AskAlias      = '2. Enter Alias / Area'
            AskReportLang = '3. Report language / Idioma del reporte:'
            Lang1         = '[1] Español'
            Lang2         = '[2] English'
            LangDefault   = '[Enter] Current panel language'
            ReportType    = '4. SELECT REPORT TYPE:'
            Mode1         = '[1] Simplified Report (Native Windows - Fast)'
            Mode2         = '[2] Detailed Report   (CPU-Z engine - Technical)'
            Mode3         = '[3] Detailed Report   (CPU-Z + HWiNFO64 + CrystalDiskInfo + CrystalDiskMark)'
            FolderExists  = "WARNING: The folder '{0}' already exists."
            FolderActions = '[O] Overwrite  [R] Rename with timestamp  [C] Cancel'
            CreatingFold  = 'Creating folder: {0}...'
            Step1         = '1. Analyzing system...'
            FindingCpuz   = '   Looking for CPU-Z (detailed mode)...'
            FindingHw     = '   Looking for HWiNFO64...'
            FindingCdi    = '   Looking for CrystalDiskInfo...'
            FindingCdm    = '   Looking for CrystalDiskMark...'
            CpuzFound     = '   > FOUND: {0}'
            HwFound       = '   > FOUND: {0}'
            CdiFound      = '   > FOUND: {0}'
            CdmFound      = '   > FOUND: {0}'
            OpeningTools  = '   Opening CPU-Z, HWiNFO64, CrystalDiskInfo and CrystalDiskMark...'
            Step2Detail   = '2. Extracting hardware (CPU-Z engine)...'
            Step2Simple   = '2. Extracting hardware (Simplified native mode)...'
            Step3         = '3. CPU firmware inventory...'
            Step4         = '4. RAM diagnostics...'
            Step5         = '5. Storage analysis...'
            Step6         = '6. Network profile...'
            Step7         = '7. Critical events...'
            Step8         = '8. Battery audit...'
            Step9         = '9. Generating upgrade recommendations...'
            Step10        = '10. Generating HTML report...'
            NoRecs        = 'No automatic upgrade proposals from available inventory. This does not certify health or performance.'
            UpgradeScope  = 'Inventory observations only. No overall health or performance score; verify workload and compatibility before purchasing.'
            CpuUnmeasured = 'CPU performance not measured'
            CpuServiceManual = 'Replacement and soldering not verified. Consult the model service manual; firmware labels and codes do not prove compatibility.'
            NoNetInfo     = 'Network inventory not evaluated: query failed.'
            ReadyAt       = 'READY: {0}'
            ReturnHint    = 'Press [SPACE] to return to the menu, or any other key to exit...'
            FatalError    = 'Fatal error: {0}'
            ErrorLine     = 'Line: {0}'
            EnterExit     = 'Press Enter to exit...'
            TimeoutMsg    = '    [TIMEOUT] Process exceeded {0}s - cancelled.'
            ExecError     = '    [ERROR] Could not execute: {0}'
            HtmlLang      = 'en'
            HtmlReportTitle = 'Technical Report - ATLAS PC SUPPORT - {0}'
            HtmlHdrSub    = 'TECHNICAL DIAGNOSTIC REPORT'
            HtmlClient    = 'Client/Alias:'
            HtmlEquip     = 'Computer:'
            HtmlDate      = 'Date:'
            H1Section     = '1. System summary'
            H2Hardware    = '2. Detailed inventory (CPU-Z)'
            H2HardwareSimple = '2. Simplified inventory'
            H3Cpu         = '3. Processor inventory'
            H4Ram         = '4. RAM diagnostics'
            H5Storage     = '5. Storage'
            H6Net         = '6. Network profile'
            H7Bsod        = '7. Critical events log'
            H8Battery     = '8. Power analysis'
            H9Upgrade     = '10. ⚡ UPGRADE RECOMMENDATIONS - ATLAS ADVISOR'
            H10GpuTriage  = '9. GPU / display-driver slowness triage'
            BsodNone      = 'No usable BlueScreenView records. This does not certify absence of crashes.'
            HtmlFooter1   = 'This report was generated automatically by ATLAS PC SUPPORT v82'
            HtmlFooter2   = 'ATLAS PC SUPPORT &copy; {0} - Huanuco, Peru'
            CatProc       = 'Processor'
            CatBoard      = 'Mainboard'
            CatRamDetail  = 'RAM (detail)'
            CatStorage    = 'Storage'
            CatGraphics   = 'Graphics card'
            DiskFound     = '   --- [ Disk detected ] ---'
            GfxFound      = '   --- [ Graphics card detected ] ---'
            TempCrit      = ' [CRITICAL]'
            TempWarm      = ' [HOT]'
            EquipoLbl     = 'Computer'
            SerialLbl     = 'Serial (SN)'
            BoardLbl      = 'Mainboard'
            BoardSer      = 'Board serial'
            BiosLbl       = 'BIOS'
            ProcLbl       = 'Processor'
            CpuSocket     = 'CPU socket'
            RamDimm       = 'RAM DIMM{0}'
            DiskLbl       = 'Disk'
            NoMemHw       = 'Could not access memory hardware.'
            NoCpuInfo     = 'Could not get processor information.'
            NoNetAdapt    = 'No active network adapters.'
            NoBattery     = 'Battery capacity not evaluated: battery may be absent or its data unavailable.'
            RamSummary    = 'Memory devices reported: {0}/{1} | Max: {2} | Channel: {3}'
            RamChannelUnknown = 'Not verified (SMBIOS inventory)'
            RamXmpUnknown = 'Not verified'
            RamIncomplete = 'RAM capacity unavailable or incomplete. Overall upgrade score not evaluated; verify hardware before purchasing.'
            UnreportedMax = 'Not reported'
            UnknownLbl    = 'Unknown'
            FormUnk       = 'Unknown'
            FormSoldered  = 'Soldered'
            FormRemov     = 'Removable'
            RamNoExp      = 'Firmware indicates soldered memory ({0} devices). Check the service manual for expansion options.'
            RamMixed      = 'MIXED: {0} soldered + {1} removable. {2}'
            RamFreeSlots  = '{0} unpopulated device position(s) reported; verify physical sockets in the service manual.'
            RamUpgradable = 'Firmware reports {0} removable device(s), {1} unpopulated position(s). Verify sockets and compatibility before purchasing.'
            RamColSlot    = 'Slot'
            RamColMan     = 'Manufacturer'
            RamColCap     = 'Capacity'
            RamColSpeed   = 'Speed'
            RamColXmp     = 'XMP Status'
            RamColVolt    = 'Voltage'
            RamColType    = 'Type'
            RamColPart    = 'Part Number'
            CpuTblSocket  = 'Socket'
            CpuTblUpg     = 'Upgrade Method'
            CpuTblCores   = 'Cores / Threads'
            StTblDisk     = 'Disk'
            StTblType     = 'Type'
            StTblBus      = 'Bus'
            StTblSize     = 'Size'
            StTblHealth   = 'Health'
            StTblClass    = 'Classification'
            StHddSlow     = 'HDD reported'
            StSataMid     = 'SATA SSD reported'
            StNvmeFast    = 'NVMe reported'
            StSsdUnk      = 'SSD (bus not identified)'
            StUnclass     = 'Unclassified'
            StFreeOf      = '{0}GB free of {1}GB'
            StPhysicalUnavailable = 'Physical disk inventory not evaluated: query failed.'
            StVolumesUnavailable = 'Volume inventory not evaluated: query failed.'
            StEmptyPhysical = 'No physical disks reported by the provider.'
            StEmptyVolumes = 'No fixed volumes reported by the provider.'
            StCapacityUnknown = 'Space not evaluated: missing or inconsistent capacity/free space.'
            StDeviceCapacityUnknown = 'At least one physical disk has no usable reported capacity.'
            StUnmeasured = 'Reported storage inventory only; no speed or physical health test performed.'
            NetAdap       = 'Adapter'
            NetIp         = 'IP'
            NetMac        = 'MAC'
            NetGw         = 'Gateway'
            NetDns        = 'DNS'
            BatStatus     = 'Status'
            BatHealth     = 'Reported full/design capacity ratio'
            BatCycles     = 'Cycles'
            BatCap        = 'Design / full-charge capacity'
            BatMan        = 'Manufacturer'
            BatStDis      = 'Discharging'
            BatStCha      = 'Charging'
            BatStFull     = 'Fully charged'
            BatStAc       = 'AC available; charging not established'
            BatStPart     = 'Partially charged'
            BatSource     = 'Capacity source'
            BatStatusScope= 'Windows status records are listed separately; they are not matched to capacity rows.'
            BatStLow      = 'Low'
            BatStCrit     = 'Critical'
            BatStInUse    = 'In use'
            BatFraud      = 'Reported capacity and cycles do not establish battery age or authenticity. Validate capacity with a controlled discharge test.'
            UpgArea       = 'Area'
            UpgLevel      = 'Level'
            UpgDiag       = 'Diagnosis'
            UpgAction     = 'Recommended action'
            UpgCost       = 'Estimated cost'
            LvlCritical   = 'CRITICAL'
            LvlLow        = 'LOW'
            LvlOld        = 'OLD'
            LvlNotice     = 'NOTICE'
            RecRamLow     = 'RAM Insufficient ({0}GB)'
            RecRamLim     = 'RAM Limited ({0}GB)'
            RecHdd        = 'HDD reported in storage inventory'
            RecSataSsd    = 'SATA SSD reported in storage inventory'
            RecDiskCrit   = 'Critical disk space (>90%)'
            RecWin10Eol   = 'Windows 10: verify edition and servicing coverage'
            RecOsObs      = 'Outdated operating system'
            RamActSold    = 'Firmware indicates soldered memory. Verify expansion options in the service manual.'
            RamActFree    = 'Firmware reports {0} unpopulated position(s). Verify physical sockets and supported modules before purchasing.'
            RamActReplace = 'Verify module removability, supported capacity and compatibility in the service manual.'
            RamCostNew    = 'Quote after model and compatibility verification'
            RamCost8      = 'Quote after model and compatibility verification'
            RamCostKit    = 'Quote after model and compatibility verification'
            RamImpactLow  = 'Limited capacity can constrain multitasking; this inventory does not measure application performance.'
            RamImpactMed  = 'With 8GB you improve multitasking, browsing with many tabs and Office apps.'
            RamActSoldOk  = 'Firmware indicates soldered memory. Verify expansion options in the service manual.'
            RamActFreeMed = 'Firmware reports {0} unpopulated position(s). Verify sockets, compatibility and workload needs.'
            RamActReplaceMed = 'Verify removable modules, supported capacity and workload needs before purchasing.'
            RamCostNa     = 'Quote after model and compatibility verification'
            DiskActHdd    = 'Identify the system/application volume and measure its workload before planning replacement.'
            DiskCostHdd   = 'Quote after model, interface and workload verification'
            DiskImpactHdd = 'Media type alone does not establish the current bottleneck or boot time.'
            DiskActSata   = 'Verify available interfaces, workload and manufacturer compatibility before considering NVMe.'
            DiskCostSata  = 'Quote after model, interface and workload verification'
            DiskImpactSata= 'No transfer-rate improvement measured by this inventory.'
            DiskActCrit   = 'Review the affected volume and protect data before cleanup or expansion.'
            DiskCostCrit  = 'Quote only after reviewing the volume and available options'
            DiskImpactCrit= 'Limited free space can constrain updates and applications; it does not diagnose corruption.'
            OsActWin10    = 'Verify exact edition, build/UBR, servicing channel, updates and any applicable ESU entitlement before choosing maintenance or migration.'
            OsCostWin10   = 'Verify licensing with the owner; no price or entitlement inferred'
            OsImpactWin10 = 'The caption alone does not establish update coverage. Enterprise LTSC and IoT Enterprise LTSC require separate checks.'
            OsActObs      = 'Review exact edition, vendor support and compatible migration options.'
            OsCostObs     = 'Verify licensing and compatibility with the owner'
            OsImpactObs   = 'This inventory does not audit patch status or licensing.'
            GpuStep       = '8B. GPU slowness triage...'
            GpuVerdictOk  = 'NO STRONG SIGNALS'
            GpuVerdictObs = 'OBSERVATION'
            GpuVerdictRisk= 'GPU/DRIVER RISK'
            GpuAdviceOk   = 'No strong GPU/driver failure signal was found. It is reasonable to continue with normal maintenance, while still checking SSD/RAM/CPU/software.'
            GpuAdviceObs  = 'Moderate GPU/driver signals were found. Warn the customer that maintenance may help, but there is no guarantee.'
            GpuAdviceRisk = 'Do not promise that thermal paste or a Windows reinstall will fix the slowness. Validate GPU/driver/hardware first and protect customer data.'
            GpuNoFindings = 'No strong GPU/driver red flags found.'
            GpuLimits     = 'Safe triage only: no stress test. It may not catch intermittent thermal GPU failures.'
            GpuNotEvaluated = 'NOT EVALUATED'
            GpuIncomplete = 'Some sources could not be evaluated. Findings below are partial; no health verdict is available.'
            GpuEventScope = 'Up to 200 newest matching events per query in the last 30 days; not an exhaustive history.'
            GpuInv        = 'GPU inventory'
            GpuSignals    = 'Risk signals'
            GpuRecentEv   = 'Relevant recent events'
            GpuSeverity   = 'Severity'
            GpuSignal     = 'Signal'
            GpuEvidence   = 'Evidence'
            GpuAction     = 'Recommended action'
            GpuPoints     = 'Points'
            GpuTblDriverDate = 'Driver date'
            GpuTblStatus = 'Status'
            GpuTblPnp    = 'PNP code'
            GpuTblTime   = 'Time'
            GpuTblProvider = 'Provider'
            GpuTblLevel  = 'Level'
            GpuNoEvents  = 'No relevant GPU/display events found.'
            GpuDriverOld  = 'Very old GPU driver'
            GpuDriverOldEv= '{0} driver date {1}'
            GpuDriverAct  = 'Update or clean-install GPU driver, then retest.'
            GpuBasicDrv   = 'Basic display driver'
            GpuBasicAct   = 'Install or repair the vendor GPU driver before promising performance work.'
            GpuDeviceErr  = 'GPU device error'
            GpuDeviceAct  = 'Fix device/driver state before maintenance promises.'
            GpuTdrRep     = 'Repeated TDR/LiveKernelEvent'
            GpuTdrSeen    = 'TDR/LiveKernelEvent seen'
            GpuTdrEv      = '{0} TDR-like event(s) in last 30 days (display driver reset / GPU watchdog)'
            GpuTdrAct     = 'Treat as GPU/driver instability until proven otherwise.'
            GpuDriverEvt  = 'Repeated display driver events'
            GpuDriverEvtEv= '{0} repeated display-driver events in last 30 days'
            GpuDriverEvtAct = 'Review GPU driver and hardware stability.'
            GpuWheaRep    = 'Repeated WHEA hardware events'
            GpuWheaSeen   = 'WHEA hardware event'
            GpuWheaEv     = '{0} WHEA event(s) combined with display/TDR signals'
            GpuWheaAct    = 'This is a hardware stability warning, not GPU-specific by itself. Validate RAM/CPU/PCIe/GPU before promising maintenance.'
            GpuBugcheck   = 'Video bugcheck signature'
            GpuBugcheckEv = '{0} video bugcheck/TDR signature(s)'
            GpuBugcheckAct= 'Prioritize GPU/driver diagnosis over cleanup/reinstall promises.'
            GpuLiveKernel = 'Recent LiveKernel/minidump files'
            GpuLiveKernelEv = '{0} dump file(s) under LiveKernelReports/Minidump'
            GpuLiveKernelAct = 'Inspect dumps or treat as instability evidence before normal maintenance promises.'
            GpuRiskLine   = 'GPU triage: {0} ({1}/100)'
            SevHigh       = 'High'
            SevMed        = 'Medium'
            SevLow        = 'Low'
            CdmHint       = '[IMPORTANT] Run the benchmark in CrystalDiskMark (click "All") BEFORE taking the screenshot.'
        }
        es = @{
            HdrTitle      = 'DIAGNOSTICO MASTER - Full System Report'
            HdrSub        = 'Protocolo de Diagnostico Integral v82'
            DetectedPC    = 'DETECTADO: {0}'
            AskNumPC      = '1. Ingrese Numero de PC'
            AskAlias      = '2. Ingrese Alias/Area'
            AskReportLang = '3. Idioma del reporte / Report language:'
            Lang1         = '[1] Español'
            Lang2         = '[2] English'
            LangDefault   = '[Enter] Idioma actual del panel'
            ReportType    = '4. SELECCIONE TIPO DE INFORME:'
            Mode1         = '[1] Informe Simplificado (Nativo Windows - Rapido)'
            Mode2         = '[2] Informe Detallado    (Motor CPU-Z - Tecnico)'
            Mode3         = '[3] Informe Detallado    (Motor CPU-Z + HWiNFO64 + CristalDiskInfo + CristalDiskMark)'
            FolderExists  = "AVISO: La carpeta '{0}' ya existe."
            FolderActions = '[S] Sobreescribir  [R] Renombrar con timestamp  [C] Cancelar'
            CreatingFold  = 'Creando carpeta: {0}...'
            Step1         = '1. Analizando Sistema...'
            FindingCpuz   = '   Buscando CPU-Z (Modo Detallado)...'
            FindingHw     = '   Buscando HWiNFO64...'
            FindingCdi    = '   Buscando CrystalDiskInfo...'
            FindingCdm    = '   Buscando CrystalDiskMark...'
            CpuzFound     = '   > ENCONTRADO: {0}'
            HwFound       = '   > ENCONTRADO: {0}'
            CdiFound      = '   > ENCONTRADO: {0}'
            CdmFound      = '   > ENCONTRADO: {0}'
            OpeningTools  = '   Abriendo CPU-Z, HWiNFO64, CrystalDiskInfo y CrystalDiskMark...'
            Step2Detail   = '2. Extrayendo Hardware (Motor CPU-Z)...'
            Step2Simple   = '2. Extrayendo Hardware (Modo Simplificado Nativo)...'
            Step3         = '3. Inventario de firmware de CPU...'
            Step4         = '4. Diagnostico RAM...'
            Step5         = '5. Analisis de Almacenamiento...'
            Step6         = '6. Perfil de Red...'
            Step7         = '7. Eventos Criticos...'
            Step8         = '8. Auditando Bateria...'
            Step9         = '9. Generando Recomendaciones de Upgrade...'
            Step10        = '10. Generando Reporte HTML...'
            NoRecs        = 'Sin propuestas automaticas de ampliacion con el inventario disponible. No certifica salud ni rendimiento.'
            UpgradeScope  = 'Solo observaciones de inventario. Sin nota global de salud o rendimiento; verificar uso y compatibilidad antes de comprar.'
            CpuUnmeasured = 'Rendimiento de CPU no medido'
            CpuServiceManual = 'Reemplazo y soldadura no verificados. Consultar el manual de servicio del modelo; etiquetas y codigos de firmware no prueban compatibilidad.'
            NoNetInfo     = 'Inventario de red no evaluado: fallo de consulta.'
            ReadyAt       = 'LISTO: {0}'
            ReturnHint    = 'Presione [ESPACIO] para volver al menu o cualquier otra tecla para salir...'
            FatalError    = 'Error Fatal: {0}'
            ErrorLine     = 'Linea: {0}'
            EnterExit     = 'Presiona Enter para salir...'
            TimeoutMsg    = '    [TIMEOUT] Proceso excedio {0}s - cancelado.'
            ExecError     = '    [ERROR] No se pudo ejecutar: {0}'
            HtmlLang      = 'es'
            HtmlReportTitle = 'Informe Tecnico - ATLAS PC SUPPORT - {0}'
            HtmlHdrSub    = 'REPORTE DE DIAGNOSTICO TECNICO'
            HtmlClient    = 'Cliente/Alias:'
            HtmlEquip     = 'Equipo:'
            HtmlDate      = 'Fecha:'
            H1Section     = '1. Resumen de Sistema'
            H2Hardware    = '2. Inventario Detallado (CPU-Z)'
            H2HardwareSimple = '2. Inventario Simplificado'
            H3Cpu         = '3. Inventario del procesador'
            H4Ram         = '4. Diagnostico de Memoria RAM'
            H5Storage     = '5. Almacenamiento'
            H6Net         = '6. Perfil de Red'
            H7Bsod        = '7. Registro de Eventos Criticos'
            H8Battery     = '8. Analisis de Energia'
            H9Upgrade     = '10. ⚡ RECOMENDACIONES DE UPGRADE - ATLAS ADVISOR'
            H10GpuTriage  = '9. Triaje de lentitud por GPU / driver de video'
            BsodNone      = 'Sin registros utilizables de BlueScreenView. No certifica ausencia de fallos.'
            HtmlFooter1   = 'Este informe fue generado automaticamente por ATLAS PC SUPPORT v82'
            HtmlFooter2   = 'ATLAS PC SUPPORT &copy; {0} - Huanuco, Peru'
            CatProc       = 'Procesador'
            CatBoard      = 'Placa Base'
            CatRamDetail  = 'Memoria RAM (Detalle)'
            CatStorage    = 'Almacenamiento'
            CatGraphics   = 'Tarjeta Grafica'
            DiskFound     = '   --- [ Disco Detectado ] ---'
            GfxFound      = '   --- [ Grafica Detectada ] ---'
            TempCrit      = ' [CRITICO]'
            TempWarm      = ' [CALIENTE]'
            EquipoLbl     = 'Equipo'
            SerialLbl     = 'Serie (SN)'
            BoardLbl      = 'Placa Base'
            BoardSer      = 'Serie Placa'
            BiosLbl       = 'BIOS'
            ProcLbl       = 'Procesador'
            CpuSocket     = 'Socket CPU'
            RamDimm       = 'RAM DIMM{0}'
            DiskLbl       = 'Disco'
            NoMemHw       = 'No se pudo acceder al hardware de memoria.'
            NoCpuInfo     = 'No se pudo obtener info del procesador.'
            NoNetAdapt    = 'Sin adaptadores de red activos.'
            NoBattery     = 'Capacidad de bateria no evaluada: puede no existir o sus datos no estar disponibles.'
            RamSummary    = 'Dispositivos de memoria reportados: {0}/{1} | Max: {2} | Canal: {3}'
            RamChannelUnknown = 'No verificado (inventario SMBIOS)'
            RamXmpUnknown = 'No verificado'
            RamIncomplete = 'Capacidad de RAM no disponible o incompleta. Puntuacion global de ampliacion no evaluada; verificar hardware antes de comprar.'
            UnreportedMax = 'No reportado'
            UnknownLbl    = 'Desconocido'
            FormUnk       = 'Desconocido'
            FormSoldered  = 'Soldada'
            FormRemov     = 'Removible'
            RamNoExp      = 'El firmware indica memoria soldada ({0} dispositivos). Consultar opciones de ampliacion en el manual de servicio.'
            RamMixed      = 'MIXTA: {0} soldado(s) + {1} removible(s). {2}'
            RamFreeSlots  = '{0} posicion(es) sin poblar reportadas; verificar sockets fisicos en el manual de servicio.'
            RamUpgradable = 'Firmware: {0} dispositivo(s) removible(s), {1} posicion(es) sin poblar. Verificar sockets y compatibilidad antes de comprar.'
            RamColSlot    = 'Slot'
            RamColMan     = 'Fabricante'
            RamColCap     = 'Capacidad'
            RamColSpeed   = 'Velocidad'
            RamColXmp     = 'Estado XMP'
            RamColVolt    = 'Voltaje'
            RamColType    = 'Tipo'
            RamColPart    = 'Part Number'
            CpuTblSocket  = 'Socket'
            CpuTblUpg     = 'Upgrade Method'
            CpuTblCores   = 'Nucleos / Hilos'
            StTblDisk     = 'Disco'
            StTblType     = 'Tipo'
            StTblBus      = 'Bus'
            StTblSize     = 'Tamano'
            StTblHealth   = 'Salud'
            StTblClass    = 'Clasificacion'
            StHddSlow     = 'HDD reportado'
            StSataMid     = 'SSD SATA reportado'
            StNvmeFast    = 'NVMe reportado'
            StSsdUnk      = 'SSD (bus no identificado)'
            StUnclass     = 'No clasificado'
            StFreeOf      = '{0}GB libre de {1}GB'
            StPhysicalUnavailable = 'Inventario de discos fisicos no evaluado: fallo de consulta.'
            StVolumesUnavailable = 'Inventario de volumenes no evaluado: fallo de consulta.'
            StEmptyPhysical = 'El proveedor no reporto discos fisicos.'
            StEmptyVolumes = 'El proveedor no reporto volumenes fijos.'
            StCapacityUnknown = 'Espacio no evaluado: capacidad/espacio libre ausentes o inconsistentes.'
            StDeviceCapacityUnknown = 'Al menos un disco fisico no tiene capacidad reportada utilizable.'
            StUnmeasured = 'Solo inventario reportado; no se ejecuta prueba de velocidad ni salud fisica.'
            NetAdap       = 'Adaptador'
            NetIp         = 'IP'
            NetMac        = 'MAC'
            NetGw         = 'Gateway'
            NetDns        = 'DNS'
            BatStatus     = 'Estado'
            BatHealth     = 'Relacion reportada de capacidad completa/diseno'
            BatCycles     = 'Ciclos'
            BatCap        = 'Capacidad de diseno / carga completa'
            BatMan        = 'Fabricante'
            BatStDis      = 'Descargando'
            BatStCha      = 'Cargando'
            BatStFull     = 'Carga completa'
            BatStAc       = 'CA disponible; carga no confirmada'
            BatStPart     = 'Carga parcial'
            BatSource     = 'Fuente de capacidad'
            BatStatusScope= 'Los estados de Windows se muestran por separado; no se asocian a las filas de capacidad.'
            BatStLow      = 'Bajo'
            BatStCrit     = 'Critico'
            BatStInUse    = 'En uso'
            BatFraud      = 'La capacidad y los ciclos reportados no establecen edad ni autenticidad de la bateria. Validar capacidad con una descarga controlada.'
            UpgArea       = 'Area'
            UpgLevel      = 'Nivel'
            UpgDiag       = 'Diagnostico'
            UpgAction     = 'Accion Recomendada'
            UpgCost       = 'Costo Estimado'
            LvlCritical   = 'CRITICO'
            LvlLow        = 'BAJO'
            LvlOld        = 'ANTIGUO'
            LvlNotice     = 'AVISO'
            RecRamLow     = 'RAM Insuficiente ({0}GB)'
            RecRamLim     = 'RAM Limitada ({0}GB)'
            RecHdd        = 'HDD reportado en el inventario'
            RecSataSsd    = 'SSD SATA reportado en el inventario'
            RecDiskCrit   = 'Espacio en Disco Critico (>90%)'
            RecWin10Eol   = 'Windows 10: verificar edicion y cobertura de actualizaciones'
            RecOsObs      = 'Sistema Operativo Obsoleto'
            RamActSold    = 'El firmware indica memoria soldada. Verificar opciones de ampliacion en el manual de servicio.'
            RamActFree    = 'El firmware reporta {0} posicion(es) sin poblar. Verificar sockets fisicos y modulos compatibles antes de comprar.'
            RamActReplace = 'Verificar que los modulos sean removibles, capacidad admitida y compatibilidad en el manual de servicio.'
            RamCostNew    = 'Cotizar tras verificar modelo y compatibilidad'
            RamCost8      = 'Cotizar tras verificar modelo y compatibilidad'
            RamCostKit    = 'Cotizar tras verificar modelo y compatibilidad'
            RamImpactLow  = 'La capacidad limitada puede restringir la multitarea; este inventario no mide el rendimiento de las aplicaciones.'
            RamImpactMed  = 'Con 8GB se mejora multitarea, navegacion con muchas pestanas y apps de Office.'
            RamActSoldOk  = 'El firmware indica memoria soldada. Verificar opciones de ampliacion en el manual de servicio.'
            RamActFreeMed = 'Firmware: {0} posicion(es) sin poblar. Verificar sockets, compatibilidad y necesidades de uso.'
            RamActReplaceMed = 'Verificar modulos removibles, capacidad admitida y necesidades de uso antes de comprar.'
            RamCostNa     = 'Cotizar tras verificar modelo y compatibilidad'
            DiskActHdd    = 'Identificar el volumen del sistema/aplicaciones y medir su carga antes de planificar reemplazo.'
            DiskCostHdd   = 'Cotizar tras verificar modelo, interfaz y necesidades de uso'
            DiskImpactHdd = 'El tipo de medio no demuestra por si solo el cuello de botella ni el tiempo de arranque.'
            DiskActSata   = 'Verificar interfaces disponibles, necesidades de uso y compatibilidad del fabricante antes de considerar NVMe.'
            DiskCostSata  = 'Cotizar tras verificar modelo, interfaz y necesidades de uso'
            DiskImpactSata= 'Este inventario no mide una mejora en la tasa de transferencia.'
            DiskActCrit   = 'Revisar el volumen afectado y proteger datos antes de limpiar o ampliar.'
            DiskCostCrit  = 'Cotizar solo tras revisar el volumen y las opciones disponibles'
            DiskImpactCrit= 'El espacio limitado puede restringir actualizaciones y aplicaciones; no diagnostica corrupcion.'
            OsActWin10    = 'Verificar edicion exacta, build/UBR, canal de mantenimiento, actualizaciones y derecho ESU aplicable antes de elegir mantenimiento o migracion.'
            OsCostWin10   = 'Verificar licencias con el propietario; no se infieren precio ni derechos'
            OsImpactWin10 = 'El nombre del sistema no demuestra cobertura de actualizaciones. Enterprise LTSC e IoT Enterprise LTSC requieren comprobaciones separadas.'
            OsActObs      = 'Revisar edicion exacta, soporte del fabricante y opciones de migracion compatibles.'
            OsCostObs     = 'Verificar licencias y compatibilidad con el propietario'
            OsImpactObs   = 'Este inventario no audita el estado de parches ni licencias.'
            GpuStep       = '8B. Triaje de lentitud por GPU...'
            GpuVerdictOk  = 'SIN SEÑALES FUERTES'
            GpuVerdictObs = 'OBSERVACION'
            GpuVerdictRisk= 'RIESGO GPU/DRIVER'
            GpuAdviceOk   = 'No se encontraron senales fuertes de fallo GPU/driver. Es razonable seguir con mantenimiento normal, revisando tambien SSD/RAM/CPU/software.'
            GpuAdviceObs  = 'Se encontraron senales moderadas de GPU/driver. Avisa al cliente que el mantenimiento puede ayudar, pero sin garantia.'
            GpuAdviceRisk = 'No prometas que pasta termica o reinstalar Windows va a resolver la lentitud. Valida GPU/driver/hardware primero y protege los datos del cliente.'
            GpuNoFindings = 'No se encontraron alertas fuertes de GPU/driver.'
            GpuLimits     = 'Triaje seguro solamente: sin stress test. Puede no capturar fallos termicos intermitentes de GPU.'
            GpuNotEvaluated = 'NO EVALUADO'
            GpuIncomplete = 'No se pudieron evaluar algunas fuentes. Los hallazgos son parciales; no hay dictamen de salud.'
            GpuEventScope = 'Hasta 200 eventos coincidentes más recientes por consulta en los últimos 30 días; historial no exhaustivo.'
            GpuInv        = 'Inventario GPU'
            GpuSignals    = 'Senales de riesgo'
            GpuRecentEv   = 'Eventos recientes relevantes'
            GpuSeverity   = 'Severidad'
            GpuSignal     = 'Senal'
            GpuEvidence   = 'Evidencia'
            GpuAction     = 'Accion recomendada'
            GpuPoints     = 'Puntos'
            GpuTblDriverDate = 'Fecha driver'
            GpuTblStatus = 'Estado'
            GpuTblPnp    = 'Codigo PNP'
            GpuTblTime   = 'Hora'
            GpuTblProvider = 'Proveedor'
            GpuTblLevel  = 'Nivel'
            GpuNoEvents  = 'No se encontraron eventos relevantes de GPU/video.'
            GpuDriverOld  = 'Driver GPU muy antiguo'
            GpuDriverOldEv= '{0} driver fecha {1}'
            GpuDriverAct  = 'Actualizar o reinstalar limpio el driver GPU, luego repetir prueba.'
            GpuBasicDrv   = 'Driver basico de pantalla'
            GpuBasicAct   = 'Instalar o reparar el driver del fabricante antes de prometer mejora.'
            GpuDeviceErr  = 'Error de dispositivo GPU'
            GpuDeviceAct  = 'Corregir estado de dispositivo/driver antes de prometer mantenimiento.'
            GpuTdrRep     = 'TDR/LiveKernelEvent repetido'
            GpuTdrSeen    = 'TDR/LiveKernelEvent detectado'
            GpuTdrEv      = '{0} evento(s) tipo TDR en 30 dias (reinicio del driver / watchdog GPU)'
            GpuTdrAct     = 'Tratar como inestabilidad GPU/driver hasta demostrar lo contrario.'
            GpuDriverEvt  = 'Eventos repetidos de driver de video'
            GpuDriverEvtEv= '{0} eventos repetidos de driver de video en 30 dias'
            GpuDriverEvtAct = 'Revisar driver GPU y estabilidad de hardware.'
            GpuWheaRep    = 'Eventos WHEA repetidos'
            GpuWheaSeen   = 'Evento WHEA de hardware'
            GpuWheaEv     = '{0} evento(s) WHEA combinado(s) con senales de video/TDR'
            GpuWheaAct    = 'Es alerta de estabilidad de hardware, no especifica de GPU por si sola. Validar RAM/CPU/PCIe/GPU antes de prometer mantenimiento.'
            GpuBugcheck   = 'Firma de pantallazo/video bugcheck'
            GpuBugcheckEv = '{0} firma(s) video bugcheck/TDR'
            GpuBugcheckAct= 'Priorizar diagnostico GPU/driver antes que prometer limpieza/reinstalacion.'
            GpuLiveKernel = 'Archivos LiveKernel/minidump recientes'
            GpuLiveKernelEv = '{0} dump(s) en LiveKernelReports/Minidump'
            GpuLiveKernelAct = 'Inspeccionar dumps o tratar como evidencia de inestabilidad antes de prometer mantenimiento normal.'
            GpuRiskLine   = 'Triaje GPU: {0} ({1}/100)'
            SevHigh       = 'Alta'
            SevMed        = 'Media'
            SevLow        = 'Baja'
            CdmHint       = '[IMPORTANTE] Ejecuta la prueba en CrystalDiskMark (Botón "All") ANTES de tomar la foto.'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

$Host.UI.RawUI.ForegroundColor = "Gray"
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 55) } catch {}
try { [Console]::CursorVisible = $true } catch {}

function Wait-DiagnosticoMasterCompat {
    param([string]$Message)
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message $Message
        return
    }
    Read-Host $Message | Out-Null
}

function Escribir-Centrado {
    param([string]$Texto, [ConsoleColor]$Color = "White", [boolean]$NewLine = $true)
    $Ancho = $Host.UI.RawUI.WindowSize.Width
    $PadLeft = [math]::Max(0, [math]::Floor(($Ancho - $Texto.Length) / 2))
    Write-Host (" " * $PadLeft) -NoNewline
    if ($NewLine) { Write-Host $Texto -ForegroundColor $Color } else { Write-Host $Texto -ForegroundColor $Color -NoNewline }
}

function Dibujar-Header {
    try { Clear-Host } catch {}
    if ($atlasToolkitReady) {
        Write-Host "`n"
        Write-AtlasHeader -Title $L.HdrTitle -Color Yellow
        Write-AtlasStep $L.HdrSub
        Write-Host "`n"
        return
    }
    Write-Host "`n`n"
    Escribir-Centrado "==========================================================" "DarkGray"
    Escribir-Centrado $L.HdrTitle "DarkYellow"
    Escribir-Centrado $L.HdrSub "White"
    Escribir-Centrado "==========================================================" "DarkGray"
    Write-Host "`n"
}

function Start-ProcessWithTimeout {
    param([string]$FilePath,[string]$Arguments='', [int]$TimeoutSeconds=60,[string]$WindowStyle='Hidden',[string]$ExpectedOutput)
    if ($ExpectedOutput -and (Test-Path -LiteralPath $ExpectedOutput -ErrorAction Stop)) {
        Write-Warning 'Diagnostic output already exists. Refusing to reuse previous evidence.'
        return $false
    }
    $result=Invoke-AtlasNativeProcess -FilePath $FilePath -Arguments $Arguments -TimeoutSeconds $TimeoutSeconds
    if($result.State -ne 'Correct'){Write-Warning "Diagnostic process ${FilePath}: $($result.State), exit $($result.ExitCode)";return $false}
    if ($ExpectedOutput) {
        try { Assert-AtlasPlainFile $ExpectedOutput }
        catch { Write-Warning 'Diagnostic output was not generated as a new plain file.'; return $false }
    }
    return $true
}

function Get-RAMDiagnostic {
    $result = @{
        HtmlSection = ""; TextSummary = ""; MaxCapGB = 0
        SlotsTotal = 0; SlotsUsed = 0; SlotsLibres = 0
        Modules = @(); SolderedWarning = ""
        TotalGB = $null; AllSoldered = $false; HasFreeSlots = $false
        IsDualChannel = $null; ChannelLabel = $L.RamChannelUnknown
    }

    try {
        $modulos = @(Get-CimInstance Win32_PhysicalMemory -OperationTimeoutSec 10 -ErrorAction Stop)
    } catch {
        $result.HtmlSection = "<h2>$($L.H4Ram)</h2><pre>$($L.NoMemHw)</pre>"
        $result.TextSummary = $L.NoMemHw
        return $result
    }
    if (-not $modulos.Count) {
        $result.HtmlSection = "<pre>$($L.NoMemHw)</pre>"
        $result.TextSummary = $L.NoMemHw
        return $result
    }
    # Array metadata may fail independently of populated memory devices.
    $arrays = @()
    try {
        $arrays = @(Get-CimInstance Win32_PhysicalMemoryArray -OperationTimeoutSec 10 -ErrorAction Stop |
            Where-Object { -not $_.Use -or $_.Use -eq 3 })
    } catch { Write-Verbose "Memory array metadata unavailable: $_" }
    $memory = Get-AtlasMemorySummary -Modules $modulos -Arrays $arrays
    if ($null -ne $memory.MaxGB) { $result.MaxCapGB = $memory.MaxGB }
    if ($null -ne $memory.SlotsTotal) { $result.SlotsTotal = $memory.SlotsTotal }
    $result.SlotsUsed = $memory.SlotsUsed
    if ($null -ne $memory.SlotsFree) { $result.SlotsLibres = $memory.SlotsFree }
    $result.HasFreeSlots = ($null -ne $memory.SlotsFree -and $memory.SlotsFree -gt 0)
    $result.TotalGB = $memory.TotalGB
    # Device count/capacity do not establish the active channel mode or XMP state.

    $maxCapDisplay = if ($result.MaxCapGB -gt 0) { "$($result.MaxCapGB) GB" } else { $L.UnreportedMax }

    $formFactorNames = @{
        0=$L.FormUnk; 1="Other"; 2="SIP"; 3="DIP"; 4="ZIP"; 5="SOJ"; 6="Proprietary"
        7="SIMM"; 8="DIMM"; 9="TSOP"; 10="PGA"; 11="RIMM"; 12="SODIMM"; 13="SRIMM"
        14="SMD"; 15="SSMP"; 16="QFP"; 17="TQFP"; 18="SOIC"; 19="LCC"; 20="PLCC"
        21="BGA"; 22="FPBGA"; 23="LGA"; 24="FB-DIMM"
    }

    $solderedCount = 0; $removableCount = 0

    $htmlTable = "<table class='info-table'>"
    $htmlTable += "<tr><th>$($L.RamColSlot)</th><th>$($L.RamColMan)</th><th>$($L.RamColCap)</th><th>$($L.RamColSpeed)</th><th>$($L.RamColXmp)</th><th>$($L.RamColVolt)</th><th>$($L.RamColType)</th><th>$($L.RamColPart)</th></tr>"
    $slotsDisplay = if ($result.SlotsTotal -gt 0) { $result.SlotsTotal } else { $L.UnknownLbl }
    $textDetail = ($L.RamSummary -f $result.SlotsUsed, $slotsDisplay, $maxCapDisplay, $result.ChannelLabel) + "`n"

    foreach ($ram in $modulos) {
        $capGB = if ($ram.Capacity -gt 0) { [math]::Round($ram.Capacity / 1GB, 2) } else { $null }
        $capDisplay = if ($null -ne $capGB) { "${capGB} GB" } else { $L.UnknownLbl }
        $fab = if ($ram.Manufacturer) { $ram.Manufacturer.Trim() } else { "N/A" }
        $part = if ($ram.PartNumber) { $ram.PartNumber.Trim() } else { "N/A" }
        $slot = if ($ram.DeviceLocator) { $ram.DeviceLocator } else { "N/A" }
        $ff = if ($ram.FormFactor) { [int]$ram.FormFactor } else { 0 }
        $ffName = if ($formFactorNames.ContainsKey($ff)) { $formFactorNames[$ff] } else { "Type ${ff}" }
        $devLoc = if ($ram.DeviceLocator) { $ram.DeviceLocator } else { "" }
        $bankLabel = if ($ram.BankLabel) { $ram.BankLabel } else { "" }

        $voltaje = "N/A"
        if ($ram.ConfiguredVoltage -and $ram.ConfiguredVoltage -gt 0) {
            $voltaje = "$([math]::Round($ram.ConfiguredVoltage / 1000, 2)) V"
        }

        $configSpeed = if ($ram.ConfiguredClockSpeed) { $ram.ConfiguredClockSpeed } else { 0 }
        $nativeSpeed = if ($ram.Speed) { $ram.Speed } else { 0 }
        $speedDisplay = if ($configSpeed -gt 0) { "${configSpeed} MHz" } elseif ($nativeSpeed -gt 0) { "${nativeSpeed} MHz (Nat)" } else { "N/A" }

        $xmpStatus = $L.RamXmpUnknown; $xmpColor = "#888"; $xmpIcon = "?"

        $thisIsSoldered = $null
        if (($devLoc -match "Solder|Onboard|On Board|Integrad") -or
            ($bankLabel -match "Solder|Onboard") -or ($ff -in @(14, 21, 22))) { $thisIsSoldered = $true }
        elseif ($ff -in @(8, 12, 24)) { $thisIsSoldered = $false }

        if ($thisIsSoldered -eq $true) { $solderedCount++ }
        elseif ($thisIsSoldered -eq $false) { $removableCount++ }

        $typeDisplay = $ffName; $typeStyle = ""
        if ($thisIsSoldered) {
            $typeDisplay = "&#128274; ${ffName} ($($L.FormSoldered))"; $typeStyle = "color:#dc3545;font-weight:bold"
        } elseif ($ff -eq 8 -or $ff -eq 12 -or $ff -eq 24) {
            $typeDisplay = "&#128280; ${ffName} ($($L.FormRemov))"; $typeStyle = "color:#28a745"
        }

        $safeSlot = [System.Net.WebUtility]::HtmlEncode($slot)
        $safeFab = [System.Net.WebUtility]::HtmlEncode($fab)
        $safePart = [System.Net.WebUtility]::HtmlEncode($part)
        $htmlTable += "<tr><td>${safeSlot}</td><td>${safeFab}</td><td>${capDisplay}</td><td>${speedDisplay}</td>"
        $htmlTable += "<td style='color:${xmpColor};font-weight:bold'>${xmpIcon} ${xmpStatus}</td>"
        $htmlTable += "<td>${voltaje}</td><td style='${typeStyle};font-size:12px'>${typeDisplay}</td>"
        $htmlTable += "<td style='font-size:10px'>${safePart}</td></tr>"

        $textDetail += "  ${slot}: ${capDisplay} ${fab} @ ${speedDisplay} (${xmpStatus}) [${ffName}]`n"

        $result.Modules += @{
            Slot = $slot; Manufacturer = $fab; CapacityGB = $capGB
            Speed = $configSpeed; NativeSpeed = $nativeSpeed
            Voltage = $voltaje; PartNumber = $part; XMPStatus = $xmpStatus
            FormFactor = $ffName; IsSoldered = $thisIsSoldered
        }
    }

    $htmlTable += "</table>"
    $result.AllSoldered = ($solderedCount -eq @($modulos).Count -and $solderedCount -gt 0)

    $solderHtml = ""
    if ($solderedCount -gt 0 -and $solderedCount -eq @($modulos).Count) {
        $solderHtml = "<div style='background:#f8d7da;color:#721c24;padding:12px;border:1px solid #f5c6cb;border-radius:4px;margin-bottom:10px;font-size:13px'>"
        $solderHtml += "<strong>&#9888; $($L.RamNoExp -f $solderedCount)</strong>"
        $solderHtml += "</div>"
        $result.SolderedWarning = $L.RamNoExp -f $solderedCount
    } elseif ($solderedCount -gt 0 -and $removableCount -gt 0) {
        $freeStr = if ($result.HasFreeSlots) { $L.RamFreeSlots -f $result.SlotsLibres } else { "" }
        $solderHtml = "<div style='background:#fff3cd;color:#856404;padding:12px;border:1px solid #ffeeba;border-radius:4px;margin-bottom:10px;font-size:13px'>"
        $solderHtml += "<strong>&#9432; $($L.RamMixed -f $solderedCount, $removableCount, $freeStr)</strong>"
        $solderHtml += "</div>"
        $result.SolderedWarning = $L.RamMixed -f $solderedCount, $removableCount, $freeStr
    } elseif ($removableCount -gt 0 -and $result.HasFreeSlots) {
        $solderHtml = "<div style='background:#d4edda;color:#155724;padding:12px;border:1px solid #c3e6cb;border-radius:4px;margin-bottom:10px;font-size:13px'>"
        $solderHtml += "<strong>&#10004; $($L.RamUpgradable -f $removableCount, $result.SlotsLibres)</strong>"
        $solderHtml += "</div>"
    }

    $channelLbl = $result.ChannelLabel
    $htmlSummary = "<div style='background:#f0f4f8;padding:10px 15px;border-radius:4px;margin-bottom:10px;font-size:13px'>"
    $htmlSummary += "<strong>$($L.RamColSlot) (SMBIOS):</strong> $($result.SlotsUsed)/${slotsDisplay} | "
    $htmlSummary += "<strong>Max:</strong> ${maxCapDisplay} | "
    $htmlSummary += "<strong>$(if($lang -eq 'es'){'Canal'}else{'Channel'}):</strong> ${channelLbl}"
    $htmlSummary += "</div>"

    $result.HtmlSection = $htmlSummary + $solderHtml + $htmlTable
    $result.TextSummary = $textDetail
    return $result
}

function Get-CPUUpgradeInfo {
    $result = @{
        HtmlSection = ""; Summary = $L.NoCpuInfo; State = 'NotEvaluated'
        IsSoldered = $null; Generation = $null; ProcessorCount = 0; Processors = @()
        ScoreLabel = $L.CpuUnmeasured; ScoreColor = '#666666'
    }
    try { $processors = @(Get-CimInstance Win32_Processor -OperationTimeoutSec 10 -ErrorAction Stop) }
    catch { Write-Verbose "CPU inventory unavailable: $_"; $processors = @() }
    if (-not $processors.Count) {
        $result.HtmlSection = "<pre>$($L.NoCpuInfo)</pre>"
        return $result
    }
    $result.State = 'Observed'; $result.ProcessorCount = $processors.Count
    $html = "<p>$($L.CpuUnmeasured). $($L.CpuServiceManual)</p>"
    $html += "<table class='info-table'><tr><th>$($L.ProcLbl)</th><th>$($L.CpuTblSocket)</th><th>$($L.CpuTblUpg) (SMBIOS)</th><th>$($L.CpuTblCores)</th></tr>"
    foreach ($proc in $processors) {
        $name = if ($proc.Name) { $proc.Name.Trim() } else { $L.UnknownLbl }
        $socket = if ($proc.SocketDesignation) { $proc.SocketDesignation } else { $L.UnknownLbl }
        $upgradeCode = if ($proc.UpgradeMethod -gt 0) { [int]$proc.UpgradeMethod } else { $null }
        $cores = if ($proc.NumberOfCores -gt 0) { [int]$proc.NumberOfCores } else { $null }
        $threads = if ($proc.NumberOfLogicalProcessors -gt 0) { [int]$proc.NumberOfLogicalProcessors } else { $null }
        $result.Processors += @{ Name=$name; SocketDesignation=$socket; UpgradeMethod=$upgradeCode; Cores=$cores; Threads=$threads }
        $safeName = [System.Net.WebUtility]::HtmlEncode($name)
        $safeSocket = [System.Net.WebUtility]::HtmlEncode($socket)
        $codeDisplay = if ($null -ne $upgradeCode) { $upgradeCode } else { $L.UnknownLbl }
        $coreDisplay = if ($null -ne $cores) { $cores } else { $L.UnknownLbl }
        $threadDisplay = if ($null -ne $threads) { $threads } else { $L.UnknownLbl }
        $html += "<tr><td>${safeName}</td><td>${safeSocket}</td><td>${codeDisplay}</td><td>${coreDisplay} / ${threadDisplay}</td></tr>"
    }
    $result.HtmlSection = $html + '</table>'
    $result.Summary = "$($L.CpuUnmeasured) | $($L.CpuServiceManual)"
    return $result
}

function ConvertTo-DiagBatteryNumber {
    param($Value, [switch]$AllowZero)
    $text = ([string]$Value).Trim()
    # Accept whole values, including explicitly grouped mWh; never truncate a locale-specific decimal.
    if ($text -notmatch '^(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)(?:\s+mWh)?$') { return $null }
    $number = 0L
    $digits = ($text -replace '\s+mWh$', '').Replace(',', '')
    if (-not [long]::TryParse($digits, [ref]$number) -or $number -ge [uint32]::MaxValue) { return $null }
    if ($number -eq 0 -and -not $AllowZero) { return $null }
    return $number
}

function ConvertFrom-DiagBatteryExport {
    param([string]$Text, [ValidateSet('PowercfgXml','NirsoftText')][string]$Format)
    if ($Format -eq 'PowercfgXml') {
        $settings = [Xml.XmlReaderSettings]::new()
        $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $settings.MaxCharactersInDocument = 10MB
        $reader = [Xml.XmlReader]::Create([IO.StringReader]::new($Text), $settings)
        try {
            $document = [Xml.XmlDocument]::new(); $document.XmlResolver = $null
            $document.Load($reader)
            if ($document.DocumentElement.LocalName -ne 'BatteryReport') { throw 'Unexpected battery XML root.' }
            foreach ($battery in $document.SelectNodes('/*[local-name()="BatteryReport"]/*[local-name()="Batteries"]/*[local-name()="Battery"]')) {
                [pscustomobject]@{
                    DesignCapacity = ConvertTo-DiagBatteryNumber $battery.DesignCapacity
                    FullChargeCapacity = ConvertTo-DiagBatteryNumber $battery.FullChargeCapacity
                    CycleCount = ConvertTo-DiagBatteryNumber $battery.CycleCount -AllowZero
                    Manufacturer = [string]$battery.Manufacturer; Chemistry = [string]$battery.Chemistry
                }
            }
        } finally { $reader.Dispose() }
        return
    }
    $fields = @{}
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*(Designed Capacity|Full Charged Capacity|Number of charge/discharge cycles|Battery Manufacturer|Chemistry)\s*:\s*(.*?)\s*$') {
            $key = $matches[1]; $value = $matches[2]
            if ($fields.ContainsKey($key)) { throw 'Ambiguous multi-battery text export.' }
            $fields[$key] = $value
        }
    }
    if (-not $fields.ContainsKey('Designed Capacity') -and -not $fields.ContainsKey('Full Charged Capacity')) { throw 'Unrecognized battery text export.' }
    [pscustomobject]@{
        DesignCapacity = ConvertTo-DiagBatteryNumber $fields['Designed Capacity']
        FullChargeCapacity = ConvertTo-DiagBatteryNumber $fields['Full Charged Capacity']
        CycleCount = ConvertTo-DiagBatteryNumber $fields['Number of charge/discharge cycles'] -AllowZero
        Manufacturer = [string]$fields['Battery Manufacturer']; Chemistry = [string]$fields['Chemistry']
    }
}

function Get-BatteryAnalysis {
    param([string]$BatteryInfoViewPath)
    $result = @{ Batteries=@(); StatusRows=@(); CapacityState='Unavailable'; StatusState='Unavailable'; Source=$null; HtmlSection='' }
    # Structured native data preserves each battery's capacity pair. The existing utility remains a fallback.
    foreach ($format in @('PowercfgXml','NirsoftText')) {
        if ($format -eq 'NirsoftText' -and (-not $BatteryInfoViewPath -or -not (Test-Path -LiteralPath $BatteryInfoViewPath))) { continue }
        $extension = if ($format -eq 'PowercfgXml') { '.xml' } else { '.txt' }
        $path = Join-Path $env:TEMP ('atlas_diag_battery_' + [guid]::NewGuid().ToString('N') + $extension)
        try {
            if ($format -eq 'PowercfgXml') {
                $exe = Join-Path $env:SystemRoot 'System32/powercfg.exe'
                $arguments = "/batteryreport /output `"$path`" /xml"
            } else { $exe = $BatteryInfoViewPath; $arguments = "/stext `"$path`"" }
            if (-not (Start-ProcessWithTimeout -FilePath $exe -Arguments $arguments -TimeoutSeconds 15 -ExpectedOutput $path)) { continue }
            try { $text = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false, $true)) }
            catch { $text = [IO.File]::ReadAllText($path, [Text.Encoding]::Default) }
            $result.Batteries = @(ConvertFrom-DiagBatteryExport -Text $text -Format $format)
            $result.CapacityState = if ($result.Batteries.Count) { 'Observed' } else { 'Empty' }
            $result.Source = if ($format -eq 'PowercfgXml') { 'Windows battery report' } else { 'BatteryInfoView' }
            break
        } catch { Write-Verbose "Battery export unavailable ($format): $_" }
        finally { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue } }
    }
    try {
        foreach ($status in @(Get-CimInstance Win32_Battery -OperationTimeoutSec 10 -ErrorAction Stop)) {
            $charge = ConvertTo-DiagBatteryNumber $status.EstimatedChargeRemaining -AllowZero
            if ($null -ne $charge -and $charge -gt 100) { $charge = $null }
            $state = switch ($status.BatteryStatus) {
                1 { $L.BatStDis } 2 { $L.BatStAc } 3 { $L.BatStFull }
                4 { $L.BatStLow } 5 { $L.BatStCrit }
                { $_ -in 6,7,8,9 } { $L.BatStCha }
                11 { $L.BatStPart } default { $L.UnknownLbl }
            }
            $result.StatusRows += [pscustomobject]@{ Status=$state; ChargePercent=$charge }
        }
        $result.StatusState = if ($result.StatusRows.Count) { 'Observed' } else { 'Empty' }
    } catch { Write-Verbose "Battery status unavailable: $_" }
    $html = "<p>$($L.BatFraud)</p>"
    if ($result.Source) { $html += "<p>$($L.BatSource): $($result.Source)</p>" }
    if (-not $result.Batteries.Count) { $html += "<pre>$($L.NoBattery)</pre>" }
    foreach ($battery in $result.Batteries) {
        $ratio = $null
        if ($null -ne $battery.DesignCapacity -and $null -ne $battery.FullChargeCapacity) { $ratio = 100.0 * $battery.FullChargeCapacity / $battery.DesignCapacity }
        $battery | Add-Member -NotePropertyName CapacityRatioPercent -NotePropertyValue $ratio
        $design = if ($null -ne $battery.DesignCapacity) { "$($battery.DesignCapacity) mWh" } else { $L.UnknownLbl }
        $full = if ($null -ne $battery.FullChargeCapacity) { "$($battery.FullChargeCapacity) mWh" } else { $L.UnknownLbl }
        $cycles = if ($null -ne $battery.CycleCount) { [string]$battery.CycleCount } else { $L.UnknownLbl }
        $ratioDisplay = if ($null -ne $ratio) { '{0:N1}%' -f $ratio } else { $L.UnknownLbl }
        $identity = [Net.WebUtility]::HtmlEncode($battery.Manufacturer + ' / ' + $battery.Chemistry)
        $html += "<table class='info-table'><tr><th>$($L.BatHealth)</th><td>${ratioDisplay}</td></tr><tr><th>$($L.BatCycles)</th><td>${cycles}</td></tr><tr><th>$($L.BatCap)</th><td>${design} / ${full}</td></tr><tr><th>$($L.BatMan)</th><td>${identity}</td></tr></table>"
    }
    $html += "<p>$($L.BatStatusScope)</p>"
    foreach ($status in $result.StatusRows) {
        $chargeDisplay = if ($null -ne $status.ChargePercent) { "$($status.ChargePercent)%" } else { $L.UnknownLbl }
        $html += "<p>$($L.BatStatus): $($status.Status) (${chargeDisplay})</p>"
    }
    if ($result.StatusState -eq 'Unavailable') { $html += "<p>$($L.BatStatus): $($L.UnknownLbl)</p>" }
    $result.HtmlSection = $html
    return $result
}

function Get-StorageAnalysis {
    $result = @{
        Disks = @(); Volumes = @(); HasHDD = $false; HasSATASSD = $false; HasNVMe = $false
        CriticalSpace = $null; HtmlSection = ''; State = 'NotEvaluated'; Notes = @()
        PhysicalInventoryState = 'Unavailable'; VolumeInventoryState = 'Unavailable'
    }
    $physDisks = @(); $logDisks = @()
    try {
        $physDisks = @(Get-PhysicalDisk -ErrorAction Stop)
        $result.PhysicalInventoryState = if ($physDisks.Count) { 'Observed' } else { 'Empty' }
        if (-not $physDisks.Count) { $result.Notes += $L.StEmptyPhysical }
    } catch { $result.Notes += $L.StPhysicalUnavailable }
    try {
        $logDisks = @(Get-CimInstance Win32_LogicalDisk -OperationTimeoutSec 10 -ErrorAction Stop | Where-Object { $_.DriveType -eq 3 })
        $result.VolumeInventoryState = if ($logDisks.Count) { 'Observed' } else { 'Empty' }
        if (-not $logDisks.Count) { $result.Notes += $L.StEmptyVolumes }
    } catch { $result.Notes += $L.StVolumesUnavailable }

    $htmlTable = "<table class='info-table'><tr><th>$($L.StTblDisk)</th><th>$($L.StTblType)</th><th>$($L.StTblBus)</th><th>$($L.StTblSize)</th><th>$($L.StTblHealth)</th><th>$($L.StTblClass)</th></tr>"
    if ($physDisks) {
        foreach ($pd in $physDisks) {
            $name = if ($pd.FriendlyName) { $pd.FriendlyName } else { $L.DiskLbl }
            $media = if ($pd.MediaType) { $pd.MediaType.ToString() } else { $L.UnknownLbl }
            $bus = if ($pd.BusType) { $pd.BusType.ToString() } else { $L.UnknownLbl }
            $deviceBytes = 0.0
            $sizeGB = $null
            if ($null -ne $pd.Size -and [double]::TryParse([string]$pd.Size, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$deviceBytes) -and
                $deviceBytes -gt 0 -and -not [double]::IsInfinity($deviceBytes)) {
                $sizeGB = [math]::Round($deviceBytes / 1GB, 1)
            } elseif ($result.Notes -notcontains $L.StDeviceCapacityUnknown) { $result.Notes += $L.StDeviceCapacityUnknown }
            $sizeDisplay = if ($null -ne $sizeGB) { "${sizeGB} GB" } else { $L.UnknownLbl }
            $health = if ($null -ne $pd.HealthStatus) { $pd.HealthStatus.ToString() } else { $L.UnknownLbl }
            $healthColor = if ($health -eq "Healthy") { "#28a745" } elseif ($health -in @('Warning','Unhealthy')) { "#dc3545" } else { "#888" }
            $classification = ""; $classColor = ""
            if ($media -match "HDD") {
                $result.HasHDD = $true; $classification = $L.StHddSlow; $classColor = "#666666"
            } elseif ($media -match "SSD" -and $bus -match "SATA|ATA" -and $bus -notmatch "NVMe") {
                $result.HasSATASSD = $true; $classification = $L.StSataMid; $classColor = "#666666"
            } elseif ($bus -match "NVMe") {
                $result.HasNVMe = $true; $classification = $L.StNvmeFast; $classColor = "#666666"
            }
            if ([string]::IsNullOrEmpty($classification)) {
                if ($media -match "SSD") { $classification = $L.StSsdUnk; $classColor = "#888" }
                else { $classification = $L.StUnclass; $classColor = "#888" }
            }
            $safeName=[Net.WebUtility]::HtmlEncode($name);$safeMedia=[Net.WebUtility]::HtmlEncode($media);$safeBus=[Net.WebUtility]::HtmlEncode($bus);$safeHealth=[Net.WebUtility]::HtmlEncode($health)
            $htmlTable += "<tr><td>${safeName}</td><td>${safeMedia}</td><td>${safeBus}</td><td>${sizeDisplay}</td><td style='color:${healthColor}'>${safeHealth}</td><td style='color:${classColor};font-weight:bold'>${classification}</td></tr>"
            $result.Disks += @{ Name=$name; Media=$media; Bus=$bus; SizeGB=$sizeGB; Health=$health; Class=$classification }
        }
    }
    $htmlTable += "</table>"

    $spaceHtml = ""
    if ($logDisks) {
        $spaceHtml = "<div style='margin-top:10px'>"
        foreach ($ld in $logDisks) {
            $totalBytes = 0.0; $freeBytes = 0.0
            $valid = $null -ne $ld.Size -and $null -ne $ld.FreeSpace -and
                [double]::TryParse([string]$ld.Size, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$totalBytes) -and
                [double]::TryParse([string]$ld.FreeSpace, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$freeBytes) -and
                -not [double]::IsInfinity($totalBytes) -and -not [double]::IsNaN($totalBytes) -and
                -not [double]::IsInfinity($freeBytes) -and -not [double]::IsNaN($freeBytes) -and
                $totalBytes -gt 0 -and $freeBytes -ge 0 -and $freeBytes -le $totalBytes
            if (-not $valid) {
                $result.Volumes += @{ DeviceID=$ld.DeviceID; SizeGB=$null; FreeGB=$null; UsedPercent=$null }
                $spaceHtml += "<p><strong>$([Net.WebUtility]::HtmlEncode([string]$ld.DeviceID))</strong> $($L.StCapacityUnknown)</p>"
                if ($result.Notes -notcontains $L.StCapacityUnknown) { $result.Notes += $L.StCapacityUnknown }
                continue
            }
            $totalGB = [math]::Round($totalBytes / 1GB, 1)
            $freeGB = [math]::Round($freeBytes / 1GB, 1)
            $usedExact = (($totalBytes - $freeBytes) / $totalBytes) * 100
            $usedPct = [math]::Round($usedExact, 0)
            $result.Volumes += @{ DeviceID=$ld.DeviceID; SizeGB=$totalGB; FreeGB=$freeGB; UsedPercent=$usedPct }
            $barColor = if ($usedExact -ge 90) { "#dc3545" } elseif ($usedExact -ge 75) { "#ffc107" } else { "#28a745" }
            if ($usedExact -ge 90) { $result.CriticalSpace = $true }
            $spaceHtml += "<div style='margin:5px 0;font-size:13px'><strong>$([Net.WebUtility]::HtmlEncode([string]$ld.DeviceID))</strong> $($L.StFreeOf -f $freeGB, $totalGB) "
            $spaceHtml += "<div style='background:#e9ecef;border-radius:4px;height:14px;width:200px;display:inline-block;vertical-align:middle'>"
            $spaceHtml += "<div style='background:${barColor};height:100%;width:${usedPct}%;border-radius:4px'></div></div>"
            $spaceHtml += " <span style='color:${barColor};font-weight:bold'>${usedPct}%</span></div>"
        }
        $spaceHtml += "</div>"
    }
    $validVolumes = @($result.Volumes | Where-Object { $null -ne $_.UsedPercent }).Count
    if ($logDisks.Count -gt 0 -and $validVolumes -eq $logDisks.Count -and $null -eq $result.CriticalSpace) {
        $result.CriticalSpace = $false
    }
    if ($physDisks.Count -gt 0 -or $logDisks.Count -gt 0) {
        $result.State = if ($result.Notes.Count) { 'Partial' } else { 'Observed' }
    }
    $notesHtml = "<p>$($L.StUnmeasured)</p>"
    foreach ($note in $result.Notes) { $notesHtml += "<p>${note}</p>" }
    $result.HtmlSection = $notesHtml + $htmlTable + $spaceHtml
    return $result
}

function Get-UpgradeAdvisor {
    param([hashtable]$RAMData, [hashtable]$CPUData, [hashtable]$StorageData, [string]$OSCaption)
    $recommendations = @(); $ramGB = $RAMData.TotalGB
    $ramKnown = ($null -ne $ramGB -and $ramGB -gt 0)
    if ($ramKnown -and $ramGB -lt 4) {
        if ($RAMData.AllSoldered) { $ramAction=$L.RamActSold; $ramCost=$L.RamCostNew }
        elseif ($RAMData.HasFreeSlots) { $ramAction=($L.RamActFree -f $RAMData.SlotsLibres); $ramCost=$L.RamCost8 }
        else { $ramAction=$L.RamActReplace; $ramCost=$L.RamCost8 }
        $recommendations += @{ Area="RAM"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=($L.RecRamLow -f $ramGB); Action=$ramAction; Cost=$ramCost; Impact=$L.RamImpactLow }
    } elseif ($ramKnown -and $ramGB -lt 8) {
        if ($RAMData.AllSoldered) { $ramAction=$L.RamActSoldOk; $ramCost=$L.RamCostNa }
        elseif ($RAMData.HasFreeSlots) { $ramAction=($L.RamActFreeMed -f $RAMData.SlotsLibres); $ramCost=$L.RamCost8 }
        else { $ramAction=$L.RamActReplaceMed; $ramCost=$L.RamCostKit }
        $recommendations += @{ Area="RAM"; Level=$L.LvlLow; Color="#fd7e14"; Icon="&#9432;"; Title=($L.RecRamLim -f $ramGB); Action=$ramAction; Cost=$ramCost; Impact=$L.RamImpactMed }
    }
    if ($StorageData.HasHDD -and -not $StorageData.HasNVMe -and -not $StorageData.HasSATASSD) {
        $recommendations += @{ Area="DISK"; Level=$L.LvlNotice; Color="#ffc107"; Icon="&#9432;"; Title=$L.RecHdd; Action=$L.DiskActHdd; Cost=$L.DiskCostHdd; Impact=$L.DiskImpactHdd }
    } elseif ($StorageData.HasSATASSD -and -not $StorageData.HasNVMe) {
        $recommendations += @{ Area="DISK"; Level=$L.LvlNotice; Color="#ffc107"; Icon="&#9432;"; Title=$L.RecSataSsd; Action=$L.DiskActSata; Cost=$L.DiskCostSata; Impact=$L.DiskImpactSata }
    }
    if ($StorageData.CriticalSpace) {
        $recommendations += @{ Area="DISK"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=$L.RecDiskCrit; Action=$L.DiskActCrit; Cost=$L.DiskCostCrit; Impact=$L.DiskImpactCrit }
    }
    if ($OSCaption -match 'Windows 10') {
        $recommendations += @{ Area="OS"; Level=$L.LvlNotice; Color="#fd7e14"; Icon="&#9432;"; Title=$L.RecWin10Eol; Action=$L.OsActWin10; Cost=$L.OsCostWin10; Impact=$L.OsImpactWin10 }
    } elseif ($OSCaption -match 'Windows 7|Windows 8') {
        $recommendations += @{ Area="OS"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=$L.RecOsObs; Action=$L.OsActObs; Cost=$L.OsCostObs; Impact=$L.OsImpactObs }
    }
    $html = "<p>$($L.UpgradeScope)</p>"
    if (-not $ramKnown) { $html += "<p>$($L.RamIncomplete)</p>" }
    if ($CPUData.State -ne 'Observed') { $html += "<p>$($L.NoCpuInfo)</p>" }
    if ($recommendations.Count -eq 0) { $html += "<p>$($L.NoRecs)</p>" }
    else {
        $html += "<table class='info-table'><tr><th>$($L.UpgArea)</th><th>$($L.UpgLevel)</th><th>$($L.UpgDiag)</th><th>$($L.UpgAction)</th><th>$($L.UpgCost)</th></tr>"
        foreach ($rec in ($recommendations | Sort-Object { if ($_.Level -eq $L.LvlCritical) { 0 } elseif ($_.Level -eq $L.LvlLow) { 1 } else { 2 } })) {
            $recColor = $rec.Color
            $html += "<tr><td><strong>$($rec.Area)</strong></td><td style='background:${recColor}'>$($rec.Icon) $($rec.Level)</td>"
            $html += "<td><strong>$($rec.Title)</strong><br>$($rec.Impact)</td><td>$($rec.Action)</td><td>$($rec.Cost)</td></tr>"
        }
        $html += '</table>'
    }
    return @{ HtmlSection=$html; Recommendations=$recommendations; Score=$null; ScoreLabel=$L.UpgradeScope; ScoreColor='#666666' }
}

function Get-NetworkProfile {
    $result = @{ HtmlSection = ""; TextSummary = ""; State = 'NotEvaluated' }
    try { $adapters = @(Get-CimInstance Win32_NetworkAdapterConfiguration -OperationTimeoutSec 10 -ErrorAction Stop | Where-Object { $_.IPEnabled }) }
    catch { $result.HtmlSection = "<pre>$($L.NoNetInfo)</pre>"; $result.TextSummary = $L.NoNetInfo; return $result }
    $result.State = 'Observed'
    if (-not $adapters) { $result.HtmlSection = "<pre>$($L.NoNetAdapt)</pre>"; return $result }
    $htmlTable = "<table class='info-table'><tr><th>$($L.NetAdap)</th><th>$($L.NetIp)</th><th>$($L.NetMac)</th><th>$($L.NetGw)</th><th>$($L.NetDns)</th></tr>"
    $textNet = ""
    foreach ($a in $adapters) {
        $desc = if ($a.Description) { $a.Description } else { $L.UnknownLbl }
        $ip = if ($a.IPAddress) { $a.IPAddress -join ', ' } else { "N/A" }
        $mac = if ($a.MACAddress) { $a.MACAddress } else { "N/A" }
        $gw = if ($a.DefaultIPGateway) { $a.DefaultIPGateway -join ', ' } else { "N/A" }
        $dns = if ($a.DNSServerSearchOrder) { ($a.DNSServerSearchOrder -join ", ") } else { "N/A" }
        $safeDesc = [System.Net.WebUtility]::HtmlEncode($desc)
        $safeIp = [System.Net.WebUtility]::HtmlEncode($ip)
        $safeMac = [System.Net.WebUtility]::HtmlEncode($mac)
        $safeGw = [System.Net.WebUtility]::HtmlEncode($gw)
        $safeDns = [System.Net.WebUtility]::HtmlEncode($dns)
        $htmlTable += "<tr><td>${safeDesc}</td><td>${safeIp}</td><td style='font-family:Consolas;font-size:11px'>${safeMac}</td><td>${safeGw}</td><td style='font-size:11px'>${safeDns}</td></tr>"
        $textNet += "${desc} | IP: ${ip} | MAC: ${mac}`n"
    }
    $htmlTable += "</table>"; $result.HtmlSection = $htmlTable; $result.TextSummary = $textNet
    return $result
}

function Convert-GpuDriverDate {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    try {
        if ($Value -is [datetime]) { return $Value }
        $s = [string]$Value
        if ($s -match '^\d{14}\.') { return [System.Management.ManagementDateTimeConverter]::ToDateTime($s) }
        return [datetime]::Parse($s)
    } catch {
        return $null
    }
}

function Add-GpuFinding {
    param(
        [System.Collections.ArrayList]$List,
        [int]$Points,
        [string]$Severity,
        [string]$Signal,
        [string]$Evidence,
        [string]$Action
    )
    [void]$List.Add([pscustomobject]@{
        Points = $Points
        Severity = $Severity
        Signal = $Signal
        Evidence = $Evidence
        Action = $Action
    })
}

function Get-GpuTargetedEvents {
    param([datetime]$Since)
    $events = New-Object System.Collections.ArrayList
    $providers = @(
        'Display',
        'nvlddmkm',
        'amdkmdag',
        'amdwddmg',
        'igfx',
        'igfxn',
        'dxgkrnl',
        'Microsoft-Windows-DxgKrnl',
        'Microsoft-Windows-WHEA-Logger'
    )
    foreach ($provider in $providers) {
        try {
            foreach ($ev in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = $provider; StartTime = $Since } -MaxEvents 200 -ErrorAction Stop)) {
                [void]$events.Add($ev)
            }
        } catch {
            if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*' -and $_.FullyQualifiedErrorId -notlike 'NoMatchingProvidersFound*') {
                throw 'GPU System events could not be evaluated.'
            }
        }
    }
    foreach ($id in 4101, 14, 13, 117, 141, 144, 1001) {
        try {
            $found = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = $id; StartTime = $Since } -MaxEvents 200 -ErrorAction Stop | Where-Object {
                $_.ProviderName -match 'Display|nvlddmkm|amdkmdag|amdwddmg|igfx|dxg|WHEA|BugCheck'
            })
            foreach ($ev in $found) { [void]$events.Add($ev) }
        } catch {
            if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw 'GPU System events could not be evaluated.' }
        }
    }
    try {
        $wer = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1001; StartTime = $Since } -MaxEvents 200 -ErrorAction Stop | Where-Object {
            $_.ProviderName -match 'Windows Error Reporting' -and $_.Message -match 'LiveKernelEvent|117|141|144|VIDEO_TDR|Display|graphics|hardware error'
        })
        foreach ($ev in $wer) { [void]$events.Add($ev) }
    } catch {
        if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw 'GPU Application events could not be evaluated.' }
    }
    return @($events | Sort-Object LogName,RecordId -Unique | Sort-Object TimeCreated -Descending)
}

function Get-GpuLiveKernelFiles {
    param([datetime]$Since)
    $roots = @("$env:SystemRoot\LiveKernelReports", "$env:SystemRoot\Minidump")
    $files = @()
    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path -LiteralPath $root -ErrorAction Stop)) { continue }
        $files += @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction Stop | Where-Object {
                $_.LastWriteTime -ge $Since -and ($_.FullName -match 'WATCHDOG|WHEA|VIDEO|GRAPHICS|GPU|\.dmp$')
            } | Select-Object FullName, LastWriteTime, Length)
    }
    return @($files | Sort-Object LastWriteTime -Descending)
}

function Get-GPUSlownessTriageForReport {
    $since = (Get-Date).AddDays(-30)
    $findings = New-Object System.Collections.ArrayList
    $unavailable = [Collections.Generic.List[string]]::new()
    $gpus = @()
    try {
    $gpus = @(Get-CimInstance Win32_VideoController -OperationTimeoutSec 10 -ErrorAction Stop | ForEach-Object {
        $driverDate = Convert-GpuDriverDate $_.DriverDate
        $adapterGb = $null
        try {
            if ($_.AdapterRAM -and [double]$_.AdapterRAM -gt 0) { $adapterGb = [math]::Round(([double]$_.AdapterRAM / 1GB), 2) }
        } catch {}
        [pscustomobject]@{
            Name = $_.Name
            DriverVersion = $_.DriverVersion
            DriverDate = $driverDate
            DriverDateText = if ($driverDate) { $driverDate.ToString('yyyy-MM-dd') } else { [string]$_.DriverDate }
            AdapterRAMGB = $adapterGb
            Status = $_.Status
            ConfigManagerErrorCode = $_.ConfigManagerErrorCode
        }
    })
    } catch { $unavailable.Add('GPU inventory') }
    if ($gpus.Count -eq 0 -and $unavailable.Count -eq 0) { $unavailable.Add('GPU inventory') }

    foreach ($gpu in $gpus) {
        if ([string]$gpu.Name -match 'Microsoft Basic Display|Basic Render|Basic Video') {
            Add-GpuFinding $findings 25 $L.SevMed $L.GpuBasicDrv $gpu.Name $L.GpuBasicAct
        }
        if ($null -ne $gpu.ConfigManagerErrorCode -and [int]$gpu.ConfigManagerErrorCode -ne 0) {
            Add-GpuFinding $findings 35 $L.SevHigh $L.GpuDeviceErr "ConfigManagerErrorCode=$($gpu.ConfigManagerErrorCode) on $($gpu.Name)" $L.GpuDeviceAct
        }
        if ($gpu.DriverDate -and ((Get-Date) - $gpu.DriverDate).TotalDays -ge 1460) {
            Add-GpuFinding $findings 18 $L.SevMed $L.GpuDriverOld ($L.GpuDriverOldEv -f $gpu.Name, $gpu.DriverDateText) $L.GpuDriverAct
        }
    }

    $events = @()
    try { $events = @(Get-GpuTargetedEvents -Since $since) }
    catch { $unavailable.Add('System/Application events') }
    $tdrEvents = @($events | Where-Object { $_.Id -in 4101, 117, 141, 144 -or $_.Message -match 'TDR|LiveKernelEvent|VIDEO_TDR|Display driver stopped responding' })
    $driverEvents = @($events | Where-Object { $_.ProviderName -match 'nvlddmkm|amdkmdag|amdwddmg|igfx|dxg' })
    $wheaEvents = @($events | Where-Object { $_.ProviderName -match 'WHEA' })
    $bugCheckTdr = @($events | Where-Object { $_.Message -match '0x00000116|0x00000117|VIDEO_TDR_FAILURE|VIDEO_SCHEDULER_INTERNAL_ERROR' })
    $lkFiles = @()
    try { $lkFiles = @(Get-GpuLiveKernelFiles -Since $since) }
    catch { $unavailable.Add('LiveKernelReports/Minidump') }

    if ($tdrEvents.Count -ge 3) {
        Add-GpuFinding $findings 35 $L.SevHigh $L.GpuTdrRep ($L.GpuTdrEv -f $tdrEvents.Count) $L.GpuTdrAct
    } elseif ($tdrEvents.Count -gt 0) {
        Add-GpuFinding $findings 20 $L.SevMed $L.GpuTdrSeen ($L.GpuTdrEv -f $tdrEvents.Count) $L.GpuTdrAct
    }
    if ($driverEvents.Count -ge 5) {
        Add-GpuFinding $findings 20 $L.SevMed $L.GpuDriverEvt ($L.GpuDriverEvtEv -f $driverEvents.Count) $L.GpuDriverEvtAct
    }
    $hasDisplayInstability = ($tdrEvents.Count -gt 0 -or $driverEvents.Count -ge 5 -or $bugCheckTdr.Count -gt 0)
    if ($hasDisplayInstability -and $wheaEvents.Count -ge 3) {
        Add-GpuFinding $findings 30 $L.SevHigh $L.GpuWheaRep ($L.GpuWheaEv -f $wheaEvents.Count) $L.GpuWheaAct
    } elseif ($hasDisplayInstability -and $wheaEvents.Count -gt 0) {
        Add-GpuFinding $findings 18 $L.SevMed $L.GpuWheaSeen ($L.GpuWheaEv -f $wheaEvents.Count) $L.GpuWheaAct
    }
    if ($bugCheckTdr.Count -gt 0) {
        Add-GpuFinding $findings 40 $L.SevHigh $L.GpuBugcheck ($L.GpuBugcheckEv -f $bugCheckTdr.Count) $L.GpuBugcheckAct
    }
    if ($lkFiles.Count -gt 0) {
        Add-GpuFinding $findings 25 $L.SevMed $L.GpuLiveKernel ($L.GpuLiveKernelEv -f $lkFiles.Count) $L.GpuLiveKernelAct
    }

    $score = [int](($findings | Measure-Object -Property Points -Sum).Sum)
    if ($score -gt 100) { $score = 100 }
    if ($score -ge 70) {
        $verdict = $L.GpuVerdictRisk; $color = '#dc3545'; $advice = $L.GpuAdviceRisk
    } elseif ($score -ge 40) {
        $verdict = $L.GpuVerdictObs; $color = '#fd7e14'; $advice = $L.GpuAdviceObs
    } else {
        $verdict = $L.GpuVerdictOk; $color = '#28a745'; $advice = $L.GpuAdviceOk
    }

    $state = 'Observed'
    $scoreText = "$score/100"
    if ($unavailable.Count -gt 0) {
        $state = 'NotEvaluated'; $verdict = $L.GpuNotEvaluated; $color = '#666666'
        $advice = $L.GpuIncomplete + ' (' + ($unavailable -join ', ') + ')'
        $scoreText = '--/100'
    }
    $html = "<div style='border-left:5px solid ${color};background:#fff;padding:12px;margin:10px 0'><strong style='color:${color};font-size:18px'>${verdict} (${scoreText})</strong><br>${advice}<br><span style='font-size:12px;color:#666'>$($L.GpuLimits) $($L.GpuEventScope)</span></div>"
    $html += "<h3>$($L.GpuInv)</h3><table class='info-table'><tr><th>GPU</th><th>Driver</th><th>$($L.GpuTblDriverDate)</th><th>VRAM GB</th><th>$($L.GpuTblStatus)</th><th>$($L.GpuTblPnp)</th></tr>"
    foreach ($gpu in $gpus) {
        $cells = @($gpu.Name,$gpu.DriverVersion,$gpu.DriverDateText,$gpu.AdapterRAMGB,$gpu.Status,$gpu.ConfigManagerErrorCode) | ForEach-Object { '<td>' + [Net.WebUtility]::HtmlEncode([string]$_) + '</td>' }
        $html += '<tr>' + ($cells -join '') + '</tr>'
    }
    $html += "</table>"
    $html += "<h3>$($L.GpuSignals)</h3><table class='info-table'><tr><th>$($L.GpuSeverity)</th><th>$($L.GpuSignal)</th><th>$($L.GpuEvidence)</th><th>$($L.GpuAction)</th><th>$($L.GpuPoints)</th></tr>"
    if ($findings.Count -gt 0) {
        foreach ($f in $findings) {
            $cells = @($f.Severity,$f.Signal,$f.Evidence,$f.Action,$f.Points) | ForEach-Object { '<td>' + [Net.WebUtility]::HtmlEncode([string]$_) + '</td>' }
            $html += '<tr>' + ($cells -join '') + '</tr>'
        }
    } else {
        $html += "<tr><td colspan='5'>$($L.GpuNoFindings)</td></tr>"
    }
    $html += "</table>"
    $html += "<h3>$($L.GpuRecentEv)</h3><table class='info-table'><tr><th>$($L.GpuTblTime)</th><th>$($L.GpuTblProvider)</th><th>ID</th><th>$($L.GpuTblLevel)</th></tr>"
    if ($events.Count -gt 0) {
        foreach ($ev in @($events | Select-Object -First 15)) {
            $cells = @($ev.TimeCreated,$ev.ProviderName,$ev.Id,$ev.LevelDisplayName) | ForEach-Object { '<td>' + [Net.WebUtility]::HtmlEncode([string]$_) + '</td>' }
            $html += '<tr>' + ($cells -join '') + '</tr>'
        }
    } else {
        $html += "<tr><td colspan='4'>$($L.GpuNoEvents)</td></tr>"
    }
    $html += "</table>"

    return @{ HtmlSection = $html; State = $state; Score = $(if ($state -eq 'Observed') { $score } else { $null }); Verdict = $verdict; Color = $color; Findings = @($findings); UnavailableSources = @($unavailable.ToArray()) }
}

function Ensure-Dir {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}





function Get-OfflineDiagToolsRoot {
    if ([string]::IsNullOrWhiteSpace($env:ATLAS_OFFLINE_ROOT)) { return $null }
    $root = Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\DiagnosticoMaster\tools'
    if (Test-Path -LiteralPath $root) { return $root }
    return $null
}





function Format-DiagnosticQuantity {
    param($Value,[double]$Divisor=1,[int]$Decimals=0,[string]$Unit)
    if($null -eq $Value -or $Divisor -le 0){return 'N/D'}
    try {
        $number=[double]$Value
        if($number -le 0 -or [double]::IsNaN($number) -or [double]::IsInfinity($number)){return 'N/D'}
        return ('{0} {1}' -f [math]::Round($number/$Divisor,$Decimals),$Unit).Trim()
    } catch {return 'N/D'}
}

function Resolve-DiagnosticoMasterTools {
    param([Parameter(Mandatory)][string]$ToolsDir,[string]$LegacyAppsDir,[string]$SelMode='3')
    $roots=@($ToolsDir,$LegacyAppsDir,(Get-OfflineDiagToolsRoot))
    if($env:ATLAS_OFFLINE_ROOT){$roots+=Join-Path $env:ATLAS_OFFLINE_ROOT 'apps';$roots+=Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\GPUCheck\tools'}
    $files=[ordered]@{
        CPUZ=@('cpuz_x64.exe','cpuz_x32.exe','cpuz.exe')
        BlueScreenView=@('BlueScreenView.exe')
        BatteryInfoView=@('BatteryInfoView.exe')
        CrystalDiskInfo=@('CrystalDiskInfo\DiskInfo64.exe','CrystalDiskInfo\DiskInfo32.exe','DiskInfo64.exe','DiskInfo32.exe')
        CrystalDiskMark=@('CrystalDiskMark\DiskMark64.exe','DiskMark64.exe')
        HWiNFO=@('HWiNFO64.exe')
    }
    $result=[ordered]@{}
    foreach($name in $files.Keys) {
        $result[$name]=$null
        if($name -eq 'CPUZ' -and $SelMode -notin @('2','3')){continue}
        if($name -in @('CrystalDiskInfo','CrystalDiskMark','HWiNFO') -and $SelMode -ne '3'){continue}
        $paths=@(foreach($base in $roots){if($base){foreach($file in $files[$name]){Join-Path $base $file}}})
        $result[$name]=Resolve-AtlasDependency -Name $name -AdditionalSearchPaths $paths -CommandNames @($files[$name]|ForEach-Object {Split-Path -Leaf $_}) -InstallIfMissing
    }
    $result.ToolsDir=$ToolsDir
    $result.LegacyAppsDir=$LegacyAppsDir
    return [pscustomobject]$result
}

do {
    $continuar = $false
    try {
        Dibujar-Header
        $pc = $env:COMPUTERNAME
        Escribir-Centrado ($L.DetectedPC -f $pc) "Gray"
        Write-Host "`n"
        $pad = [math]::Max(0, [math]::Floor(($Host.UI.RawUI.WindowSize.Width - 10) / 2))

        Escribir-Centrado $L.AskNumPC "White"
        Write-Host (" " * $pad) -NoNewline
        $numPC = Read-Host
        if ([string]::IsNullOrWhiteSpace($numPC)) { $numPC = "0" }

        Write-Host ""
        Escribir-Centrado $L.AskAlias "White"
        Write-Host (" " * $pad) -NoNewline
        $aliasPC = Read-Host
        if ([string]::IsNullOrWhiteSpace($aliasPC)) { $aliasPC = "General" }
        $aliasPC = $aliasPC -replace '[\\/:*?"<>|]', ''

        Write-Host "`n"
        Escribir-Centrado $L.AskReportLang "Cyan"
        Escribir-Centrado $L.Lang1 "White"
        Escribir-Centrado $L.Lang2 "White"
        Escribir-Centrado $L.LangDefault "Gray"
        Write-Host "`n"
        Write-Host (" " * $pad) -NoNewline
        $selLang = Read-Host
        if ($selLang -eq "1") {
            $lang = 'es'
            $L = $T[$lang]
        } elseif ($selLang -eq "2") {
            $lang = 'en'
            $L = $T[$lang]
        }

        Write-Host "`n"
        Escribir-Centrado $L.ReportType "Cyan"
        Escribir-Centrado $L.Mode1 "Gray"
        Escribir-Centrado $L.Mode2 "White"
        Escribir-Centrado $L.Mode3 "White"
        Write-Host "`n"
        Write-Host (" " * $pad) -NoNewline
        $selMode = Read-Host
        if ([string]::IsNullOrWhiteSpace($selMode)) { $selMode = "1" }

        $root = [Environment]::GetFolderPath("Desktop")
        $appsLegacy = Join-Path $root "Apps"
        $diagToolsDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\bin\DiagnosticoMaster\tools'
        $diagDeps = Resolve-DiagnosticoMasterTools -ToolsDir $diagToolsDir -LegacyAppsDir $appsLegacy -SelMode $selMode
        $repoRoot = Join-Path $root "REPORTES_PC"
        if (!(Test-Path $repoRoot)) { New-Item -ItemType Directory -Path $repoRoot | Out-Null }

        $nombreBase = "${numPC}. Resultados_${pc}_${aliasPC}"
        $dir = Join-Path $repoRoot $nombreBase
        if (Test-Path $dir) {
            Write-Host ""; Escribir-Centrado ($L.FolderExists -f $nombreBase) "Yellow"
            Escribir-Centrado $L.FolderActions "White"
            Write-Host (" " * $pad) -NoNewline; $opDup = Read-Host
            switch ($opDup.ToUpper()) {
                "R" { $ts=Get-Date -Format "HHmm"; $nombreBase="${numPC}. Resultados_${pc}_${aliasPC}_${ts}"; $dir=Join-Path $repoRoot $nombreBase }
                "C" { $continuar = $false; throw '__cancel__' }
                default { }
            }
        }
        Escribir-Centrado ($L.CreatingFold -f $nombreBase) "DarkGray"
        if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $htmlFile = Join-Path $dir "${nombreBase}.html"

        Write-Host "`n"; Escribir-Centrado $L.Step1 "Cyan"
        $os = Get-CimInstance -OperationTimeoutSec 10 Win32_OperatingSystem -ErrorAction Stop
        $cs = Get-CimInstance -OperationTimeoutSec 10 Win32_ComputerSystem -ErrorAction Stop
        $proc = Get-CimInstance -OperationTimeoutSec 10 Win32_Processor -ErrorAction Stop
        $csproduct = Get-CimInstance -OperationTimeoutSec 10 Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
        $ramSticks = Get-CimInstance -OperationTimeoutSec 10 Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $ramSummary=Get-AtlasMemorySummary -Modules @($ramSticks | Where-Object {$null -ne $_}) -Arrays @()
        $ramTotal=Format-DiagnosticQuantity -Value $ramSummary.TotalGB -Decimals 2 -Unit GB
        $ramDetalleStr=if($ramSticks){($ramSticks|ForEach-Object {Format-DiagnosticQuantity -Value $_.Capacity -Divisor 1GB -Decimals 2 -Unit GB}) -join ' + '}else{'N/D'}
        $modeloExacto = if ($csproduct -and $csproduct.Name) { $csproduct.Name } else { "N/A" }
        $txtSys = "Alias: ${aliasPC}`nOS: $($os.Caption) ($($os.OSArchitecture))`n$($L.EquipoLbl): $($cs.Manufacturer) $($cs.Model)`nModel: ${modeloExacto}`nCPU: $($proc.Name)`nRAM Total: ${ramTotal} (${ramDetalleStr})`nPowerShell: $($PSVersionTable.PSVersion)"

        $htmlHardware = ""
        if ($selMode -eq "2" -or $selMode -eq "3") {
            Escribir-Centrado $L.FindingCpuz "Magenta"
            $exeCpuz = $null
            if ($diagDeps.CPUZ -and (Test-Path -LiteralPath $diagDeps.CPUZ)) {
                $exeCpuz = Get-Item -LiteralPath $diagDeps.CPUZ -ErrorAction SilentlyContinue
            }
            if ($exeCpuz) {
                Escribir-Centrado ($L.CpuzFound -f $exeCpuz.Name) "Green"
            }

            if ($selMode -eq "3") {
                Escribir-Centrado $L.FindingHw "Magenta"
                if ($diagDeps.HWiNFO -and (Test-Path -LiteralPath $diagDeps.HWiNFO)) {
                    Escribir-Centrado ($L.HwFound -f (Split-Path -Leaf $diagDeps.HWiNFO)) "Green"
                }

                Escribir-Centrado $L.FindingCdi "Magenta"
                if ($diagDeps.CrystalDiskInfo -and (Test-Path -LiteralPath $diagDeps.CrystalDiskInfo)) {
                    Escribir-Centrado ($L.CdiFound -f (Split-Path -Leaf $diagDeps.CrystalDiskInfo)) "Green"
                }

                Escribir-Centrado $L.FindingCdm "Magenta"
                if ($diagDeps.CrystalDiskMark -and (Test-Path -LiteralPath $diagDeps.CrystalDiskMark)) {
                    Escribir-Centrado ($L.CdmFound -f (Split-Path -Leaf $diagDeps.CrystalDiskMark)) "Green"
                }
            }

            if ($exeCpuz) {
                Escribir-Centrado $L.Step2Detail "Cyan"
                $tempReportPath = Join-Path $env:TEMP ('cpuz_report_' + [guid]::NewGuid().ToString('N'))
                $arg = '-txt="' + $tempReportPath + '"'
                $reportFile = "${tempReportPath}.txt"
                $cpuzOk = Start-ProcessWithTimeout -FilePath $exeCpuz.FullName -Arguments $arg -TimeoutSeconds 30 -WindowStyle "Normal" -ExpectedOutput $reportFile
                if ($cpuzOk -and (Test-Path $reportFile)) {
                    try { $lines = Get-Content $reportFile -ErrorAction Stop } catch { $lines = Get-Content $reportFile -Encoding Default }
                    $cleanText=""; $currentSection=""; $startLog=$false; $isStorageSection=$false; $isGraphicsSection=$false
                    $keywords = @("Number of cores","Number of threads","Manufacturer","Name","Codename","Specification","Package","CPUID","Extended CPUID","Technology","Core Speed","Multiplier x Bus Speed","Temperature","Northbridge","Southbridge","Bus Specification","Graphic Interface","PCI-E Link Width","PCI-E Link Speed","Memory Type","Memory Size","Module Size","Size","Channels","Memory Frequency","DIMM #","SMBus address","Module format","Max bandwidth","Part number","Manufacturing date","Nominal Voltage","Revision","Capacity","Type","Bus Type","Rotation speed","Features","Controller","Link Speed","Volume","Display adapter","Board Manufacturer","Cores","ROP Units","Memory size","Current Link Width","Current Link Speed")
                    foreach ($line in $lines) {
                        if ($line -match "^Processors Information") { $startLog=$true; $isStorageSection=$false; $isGraphicsSection=$false; $currentSection="`n<span class='categoria-resaltada'>$($L.CatProc)</span>`n-------------------------------------------------------------------------"; $cleanText+=$currentSection+"`n"; continue }
                        if (-not $startLog) { continue }
                        if ($line -match "^Chipset") { $isStorageSection=$false; $isGraphicsSection=$false; $currentSection="`n<span class='categoria-resaltada'>$($L.CatBoard)</span>`n-------------------------------------------------------------------------"; $cleanText+=$currentSection+"`n"; continue }
                        if ($line -match "^Memory SPD") { $isStorageSection=$false; $isGraphicsSection=$false; $currentSection="`n<span class='categoria-resaltada'>$($L.CatRamDetail)</span>`n-------------------------------------------------------------------------"; $cleanText+=$currentSection+"`n"; continue }
                        if ($line -match "^Storage") { $isStorageSection=$true; $isGraphicsSection=$false; $currentSection="`n<span class='categoria-resaltada'>$($L.CatStorage)</span>`n-------------------------------------------------------------------------"; $cleanText+=$currentSection+"`n"; continue }
                        if ($line -match "^Graphics") { $isStorageSection=$false; $isGraphicsSection=$true; $currentSection="`n<span class='categoria-resaltada'>$($L.CatGraphics)</span>`n-------------------------------------------------------------------------"; $cleanText+=$currentSection+"`n"; continue }
                        if ($line -match "^(Software|DMI|Monitoring|LPCIO|PCI Devices|USB Devices)") { $currentSection="IGNORE"; continue }
                        if ($currentSection -eq "IGNORE") { continue }
                        if ($line -match "0x[0-9A-F]{8}") { continue }
                        foreach ($key in $keywords) {
                            if ($line -match "$key\s+" -or $line -match "^\s*$key") {
                                $checkValue=$line.Replace($key,"").Trim()
                                if ([string]::IsNullOrWhiteSpace($checkValue) -or $checkValue -eq ":" -or $checkValue -eq "=") { continue }
                                if ($key -eq "CPUID" -and $checkValue -match "^0x") { continue }
                                $safeLine = [Net.WebUtility]::HtmlEncode($line)
                                if ($isStorageSection -and $line -match "^\s*Name") { $cleanText+="`n$($L.DiskFound)`n" }
                                if ($isGraphicsSection -and $line -match "^\s*Display adapter") { $cleanText+="`n$($L.GfxFound)`n" }
                                if ($key -eq "Temperature" -and $line -match "(\d+)\s*degC") {
                                    $tempVal = [int]$matches[1]
                                    $tempColor = if ($tempVal -ge 85) { "#dc3545" } elseif ($tempVal -ge 70) { "#ff8c00" } else { "#28a745" }
                                    $tempLabel = if ($tempVal -ge 85) { $L.TempCrit } elseif ($tempVal -ge 70) { $L.TempWarm } else { "" }
                                    $cleanText += "<span style='color:${tempColor};font-weight:bold'>${safeLine}${tempLabel}</span>`n"
                                } else {
                                    $cleanText += $safeLine + "`n"
                                }
                                break
                            }
                        }
                    }
                    $cleanText=$cleanText -replace "`n{3,}","`n`n"
                    $htmlHardware="<h2>$($L.H2Hardware)</h2><pre>${cleanText}</pre>"
                    Remove-Item $reportFile -ErrorAction SilentlyContinue
                }
            }
        } else { Escribir-Centrado $L.Step2Simple "Cyan" }

        if ([string]::IsNullOrEmpty($htmlHardware)) {
            function Fmt-Line ($titulo, $valor) { return "<span class='categoria-resaltada'>$([Net.WebUtility]::HtmlEncode([string]$titulo)):</span> $([Net.WebUtility]::HtmlEncode([string]$valor))`n" }
            $inv=""
            $bb=Get-CimInstance -OperationTimeoutSec 10 Win32_BaseBoard -ErrorAction SilentlyContinue; $bios=Get-CimInstance -OperationTimeoutSec 10 Win32_BIOS -ErrorAction SilentlyContinue
            $bbProduct=if($bb -and $bb.Product){$bb.Product}else{"N/A"}; $bbManuf=if($bb -and $bb.Manufacturer){$bb.Manufacturer}else{"N/A"}
            $bbSerial=if($bb -and $bb.SerialNumber){$bb.SerialNumber}else{"N/A"}; $biosSN=if($bios -and $bios.SerialNumber){$bios.SerialNumber}else{"N/A"}
            $biosVer=if($bios -and $bios.SMBIOSBIOSVersion){$bios.SMBIOSBIOSVersion}else{"N/A"}; $biosDate=if($bios -and $bios.ReleaseDate){$bios.ReleaseDate}else{"N/A"}
            $inv += Fmt-Line $L.EquipoLbl "$($cs.Manufacturer) $($cs.Model)"; $inv += Fmt-Line $L.SerialLbl $biosSN
            $inv += Fmt-Line $L.BoardLbl "${bbProduct} (Mfr: ${bbManuf})"; $inv += Fmt-Line $L.BoardSer $bbSerial
            $inv += Fmt-Line $L.BiosLbl "${biosVer} (${biosDate})"; $inv += "`n"
            $inv += Fmt-Line $L.ProcLbl "$($proc.Name)"
            $socket=if($proc.SocketDesignation){$proc.SocketDesignation}else{"N/A"}; $inv += Fmt-Line $L.CpuSocket $socket; $inv += "`n"
            $memS=$ramSticks
            if($memS){$mi=1;foreach($m in $memS){$cap=Format-DiagnosticQuantity -Value $m.Capacity -Divisor 1GB -Decimals 2 -Unit GB;$manuf=if($m.Manufacturer){$m.Manufacturer}else{"N/A"};$spd=Format-DiagnosticQuantity -Value $m.Speed -Unit MHz;$inv+=Fmt-Line ($L.RamDimm -f $mi) "${cap} - ${manuf} @ ${spd}";$mi++}}else{$inv+=Fmt-Line 'RAM' 'N/D'};$inv+="`n"
            $dks=Get-CimInstance -OperationTimeoutSec 10 Win32_DiskDrive -ErrorAction SilentlyContinue|Where-Object{$_.MediaType -ne 'Removable Media'}
            if($dks){foreach($d in $dks){$sz=Format-DiagnosticQuantity -Value $d.Size -Divisor 1GB -Decimals 1 -Unit GB;$dm=if($d.Model){$d.Model}else{"N/A"};$inv+=Fmt-Line $L.DiskLbl "${dm} (${sz})"}}else{$inv+=Fmt-Line $L.DiskLbl 'N/D'}
            $htmlHardware="<h2>$($L.H2HardwareSimple)</h2><pre>${inv}</pre>"
        }

        Escribir-Centrado $L.Step3 "Cyan"
        $cpuInfo = Get-CPUUpgradeInfo
        $htmlCPU = "<h2>$($L.H3Cpu)</h2>" + $cpuInfo.HtmlSection
        $cpuColor = if ($cpuInfo.State -eq 'NotEvaluated') { 'Yellow' } else { 'Gray' }
        Write-Host "    $($cpuInfo.Summary)" -ForegroundColor $cpuColor

        Escribir-Centrado $L.Step4 "Cyan"
        $ramDiag = Get-RAMDiagnostic
        $htmlRAM = "<h2>$($L.H4Ram)</h2>" + $ramDiag.HtmlSection
        Write-Host "    $($ramDiag.TextSummary)" -ForegroundColor Gray
        if ($ramDiag.SolderedWarning) { Write-Host "    $($ramDiag.SolderedWarning)" -ForegroundColor Yellow }

        Escribir-Centrado $L.Step5 "Cyan"
        $storageData = Get-StorageAnalysis
        $htmlStorage = "<h2>$($L.H5Storage)</h2>" + $storageData.HtmlSection
        foreach ($dk in $storageData.Disks) { Write-Host "    $($dk.Name): $($dk.Class)" -ForegroundColor Gray }

        Escribir-Centrado $L.Step6 "Cyan"
        $netProfile = Get-NetworkProfile
        $htmlNet = "<h2>$($L.H6Net)</h2>" + $netProfile.HtmlSection

        Escribir-Centrado $L.Step7 "Cyan"
        $htmlBsod = "<h2>$($L.H7Bsod)</h2><pre>Not evaluated: no successful fresh BSOD export.</pre>"
        $exeBsod = $diagDeps.BlueScreenView
        if (-not $exeBsod) { $exeBsod = Join-Path $appsLegacy "BlueScreenView.exe" }
        $tmpBsod = Join-Path $env:TEMP ('atlas_diag_bsod_' + [guid]::NewGuid().ToString('N') + '.txt')
        if (Test-Path $exeBsod) {
            $bsodOk = Start-ProcessWithTimeout -FilePath $exeBsod -Arguments "/stext `"${tmpBsod}`"" -TimeoutSeconds 15 -ExpectedOutput $tmpBsod
            if ($bsodOk -and (Test-Path $tmpBsod)) { $c=Get-Content $tmpBsod -Raw -ErrorAction SilentlyContinue; if($c -and $c.Length -gt 10){$safeC=[System.Net.WebUtility]::HtmlEncode($c);$htmlBsod="<h2>$($L.H7Bsod)</h2><pre>${safeC}</pre>"}; Remove-Item $tmpBsod -ErrorAction SilentlyContinue }
        }

        Escribir-Centrado $L.Step8 "Cyan"
        $exeBatView = $diagDeps.BatteryInfoView
        if (-not $exeBatView) { $exeBatView = Join-Path $appsLegacy "BatteryInfoView.exe" }
        $batteryData = Get-BatteryAnalysis -BatteryInfoViewPath $exeBatView
        $htmlBat = "<h2>$($L.H8Battery)</h2>" + $batteryData.HtmlSection

        Escribir-Centrado $L.GpuStep "Cyan"
        $gpuTriage = Get-GPUSlownessTriageForReport
        $htmlGpuTriage = "<h2>$($L.H10GpuTriage)</h2>" + $gpuTriage.HtmlSection
        $gpuCol = if ($gpuTriage.State -eq 'NotEvaluated') { 'Yellow' } elseif ($gpuTriage.Score -ge 70) { 'Red' } elseif ($gpuTriage.Score -ge 40) { 'Yellow' } else { 'Green' }
        $gpuScore = if ($null -eq $gpuTriage.Score) { '--' } else { $gpuTriage.Score }
        Write-Host "    $($L.GpuRiskLine -f $gpuTriage.Verdict, $gpuScore)" -ForegroundColor $gpuCol

        Escribir-Centrado $L.Step9 "Magenta"
        $upgradeResult = Get-UpgradeAdvisor -RAMData $ramDiag -CPUData $cpuInfo -StorageData $storageData -OSCaption $os.Caption
        $htmlUpgrade = "<h2 style='background:#FF5500'>$($L.H9Upgrade)</h2>" + $upgradeResult.HtmlSection
        Write-Host ""; Write-Host "    $($L.UpgradeScope)" -ForegroundColor Gray
        if ($upgradeResult.Recommendations.Count -gt 0) {
            foreach ($rec in $upgradeResult.Recommendations) {
                if ($rec.Level -eq $L.LvlCritical -or $rec.Level -eq $L.LvlLow) { $rcCol = 'Red' } else { $rcCol = 'Yellow' }
                Write-Host "    [$($rec.Level)] $($rec.Title)" -ForegroundColor $rcCol
            }
        }
        else { Write-Host $L.NoRecs -ForegroundColor Gray }

        Escribir-Centrado $L.Step10 "Green"
        $fechaReporte=Get-Date -Format 'dd/MM/yyyy HH:mm'; $yearReporte=Get-Date -Format 'yyyy'
        $reportTitle = [Net.WebUtility]::HtmlEncode(($L.HtmlReportTitle -f $aliasPC))
        $css = @"
    <style>
        body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f4f4f9;color:#333;margin:0;padding:20px}
        .container{max-width:960px;margin:0 auto;background:#fff;box-shadow:0 0 15px rgba(0,0,0,.1);border-radius:8px;overflow:hidden}
        .header{background:#002147;color:#fff;padding:20px;text-align:center;border-bottom:5px solid #FF5500}
        .header h1{margin:0;font-size:28px;letter-spacing:3px;color:#FF5500;font-weight:800}
        .header p{margin:5px 0 0;color:#FFF;font-weight:bold;font-size:14px;letter-spacing:1px}
        .info-box{padding:20px;background:#f9f9f9;border-bottom:1px solid #eee;display:flex;justify-content:space-between;flex-wrap:wrap;gap:10px}
        .info-item strong{color:#555}
        .content-area{padding:20px}
        h2{background:#0b3a67;color:white;padding:8px 15px;border-radius:4px;font-size:16px;margin-top:30px;margin-bottom:10px}
        h3{color:#0b3a67;margin:18px 0 6px;font-size:15px}
        pre{background:#fcfcfc;border:1px solid #e0e0e0;border-left:5px solid #FF5500;padding:15px;border-radius:4px;overflow-x:hidden;font-family:Consolas,monospace;font-size:11px;white-space:pre-wrap;word-wrap:break-word;color:#444}
        .info-table{width:100%;border-collapse:collapse;margin-top:10px;background:white;font-size:13px}
        .info-table th{background:#e8f1fb;color:#002147;text-align:left;padding:10px 15px;border-bottom:2px solid #9fc5e8}
        .info-table td{border-bottom:1px solid #ddd;padding:10px 15px}
        .info-table tr:nth-child(even){background:#f8f9fa}
        .categoria-resaltada{display:inline-block;font-weight:700;color:#002147;background:#eef6fc;padding:3px 8px;border-radius:4px;margin-bottom:5px;border-left:3px solid #002147}
        .footer{padding:20px;text-align:center;font-size:12px;color:#777;background:#fafafa;border-top:1px solid #eee}
    </style>
"@
        $htmlHead = '<!DOCTYPE html><html lang="' + $L.HtmlLang + '"><head><meta charset="UTF-8"><title>' + $reportTitle + '</title>' + $css + '</head>'
        $html = $htmlHead + @"
<body>
    <div class="container">
        <div class="header"><h1>ATLAS PC SUPPORT</h1><p>$($L.HtmlHdrSub)</p></div>
        <div class="info-box">
            <div class="info-item"><strong>$($L.HtmlClient)</strong> $([Net.WebUtility]::HtmlEncode([string]$aliasPC))</div>
            <div class="info-item"><strong>$($L.HtmlEquip)</strong> $([Net.WebUtility]::HtmlEncode([string]$pc))</div>
            <div class="info-item"><strong>$($L.HtmlDate)</strong> ${fechaReporte}</div>
        </div>
        <div class="content-area">
            <h2>$($L.H1Section)</h2><pre>$([Net.WebUtility]::HtmlEncode($txtSys))</pre>
            ${htmlHardware}
            ${htmlCPU}
            ${htmlRAM}
            ${htmlStorage}
            ${htmlNet}
            ${htmlBsod}
            ${htmlBat}
            ${htmlGpuTriage}
            ${htmlUpgrade}
        </div>
        <div class="footer">
            <p>$($L.HtmlFooter1)</p>
            <p>$($L.HtmlFooter2 -f $yearReporte)</p>
        </div>
    </div></body></html>
"@
        Write-AtlasShareableReport -Path $htmlFile -Content $html -Tool 'System diagnostic observations' -SensitiveValues @($bios.SerialNumber, $bb.SerialNumber, $aliasPC)
        Write-Host "`n"; Escribir-Centrado ($L.ReadyAt -f $htmlFile) "Green"
        Invoke-Item $dir

        if ($selMode -eq "3") {
            $appChoices=@('CPUZ','HWiNFO','CrystalDiskInfo','CrystalDiskMark')
            while($true) {
                Write-Host 'Optional applications: one at a time; close the selected app to return / Cierra la app para volver.'
                for($i=0;$i -lt $appChoices.Count;$i++){Write-Host ("[{0}] {1}" -f ($i+1),$appChoices[$i])}
                $pick=Read-Host '1-4 to open, ENTER to continue / ENTER para seguir'
                if($pick -notmatch '^[1-4]$'){break}
                $name=$appChoices[[int]$pick-1];$path=$diagDeps.$name
                if(-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)){Write-Warning "$name not available";continue}
                if($name -eq 'CrystalDiskMark'){Escribir-Centrado $L.CdmHint 'Yellow'}
                try {Start-Process -FilePath $path -WorkingDirectory (Split-Path -Parent $path) -Wait -ErrorAction Stop}
                catch {Write-Warning "$name could not be opened."}
            }
        }

        Write-Host "`n"; Escribir-Centrado $L.ReturnHint "Cyan"
        $key=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if($key.VirtualKeyCode -eq 32){$continuar=$true}else{$continuar=$false}

    } catch {
        if ($_.Exception.Message -eq '__cancel__') { $continuar = $false }
        else {
            Write-Host ($L.FatalError -f $_.Exception.Message) -ForegroundColor Red
            Write-Host ($L.ErrorLine -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor DarkGray
            Wait-DiagnosticoMasterCompat -Message $L.EnterExit; $continuar=$false
        }
    }
} while ($continuar)
}
