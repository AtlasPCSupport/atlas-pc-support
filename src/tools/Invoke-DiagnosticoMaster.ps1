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
            Step3         = '3. CPU upgrade check...'
            Step4         = '4. RAM diagnostics...'
            Step5         = '5. Storage analysis...'
            Step6         = '6. Network profile...'
            Step7         = '7. Critical events...'
            Step8         = '8. Battery audit...'
            Step9         = '9. Generating upgrade recommendations...'
            Step10        = '10. Generating HTML report...'
            ScoreLine     = 'SCORE: {0}/100 - {1}'
            NoRecs        = '    No recommendations - the computer is in good shape.'
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
            H3Cpu         = '3. Processor status'
            H4Ram         = '4. RAM diagnostics'
            H5Storage     = '5. Storage'
            H6Net         = '6. Network profile'
            H7Bsod        = '7. Critical events log'
            H8Battery     = '8. Power analysis'
            H9Upgrade     = '10. ⚡ UPGRADE RECOMMENDATIONS - ATLAS ADVISOR'
            H10GpuTriage  = '9. GPU / display-driver slowness triage'
            BsodNone      = 'No recent errors.'
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
            NoBattery     = 'No battery detected (Desktop PC).'
            RamSummary    = 'Slots: {0}/{1} | Max: {2} | Channel: {3}'
            DualCh        = 'Dual Channel'
            SingleCh      = 'Single Channel'
            UnreportedMax = 'Not reported (Legacy BIOS)'
            UnknownLbl    = 'Unknown'
            FormUnk       = 'Unknown'
            FormSoldered  = 'Soldered'
            FormRemov     = 'Removable'
            RamNoExp      = 'NOT UPGRADABLE: All modules ({0}) are soldered. Memory cannot be upgraded.'
            RamMixed      = 'MIXED: {0} soldered + {1} removable. {2}'
            RamFreeSlots  = '{0} free slot(s).'
            RamUpgradable = 'UPGRADABLE: {0} removable. {1} free slot(s).'
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
            CpuTblGen     = 'Generation'
            CpuTblCores   = 'Cores / Threads'
            CpuTblScore   = 'Classification'
            CpuTblRepl    = 'Replaceable'
            CpuSoldered   = 'SOLDERED (BGA) - Not replaceable'
            CpuProbSold   = 'PROBABLY SOLDERED'
            CpuSocketed   = 'SOCKETED - Replaceable'
            CpuAdvSold    = 'The processor is soldered to the board. It cannot be replaced.'
            CpuAdvProb    = 'Signs indicate the CPU is probably soldered. Verify with the manufacturer.'
            CpuAdvSocket  = 'The processor uses socket {0}. It can be replaced with a compatible one.'
            CpuDetect     = 'Detection: {0}'
            CpuNoSig      = 'No specific signs'
            CpuGenNotDet  = 'Not detected'
            ScoreBasic    = 'BASIC'
            ScoreOld      = 'OLD'
            ScoreOk       = 'ACCEPTABLE'
            ScoreGood     = 'GOOD'
            StTblDisk     = 'Disk'
            StTblType     = 'Type'
            StTblBus      = 'Bus'
            StTblSize     = 'Size'
            StTblHealth   = 'Health'
            StTblClass    = 'Classification'
            StHddSlow     = 'HDD (mechanical) - Slow'
            StSataMid     = 'SATA SSD - Medium'
            StNvmeFast    = 'NVMe - Fast'
            StSsdUnk      = 'SSD (bus not identified)'
            StUnclass     = 'Unclassified'
            StFreeOf      = '{0}GB free of {1}GB'
            NetAdap       = 'Adapter'
            NetIp         = 'IP'
            NetMac        = 'MAC'
            NetGw         = 'Gateway'
            NetDns        = 'DNS'
            BatStatus     = 'Status'
            BatHealth     = 'Health'
            BatCycles     = 'Cycles'
            BatCap        = 'Capacity'
            BatMan        = 'Manufacturer'
            BatStDis      = 'Discharging'
            BatStCha      = 'Charging'
            BatStFull     = 'Charged 100%'
            BatStLow      = 'Low'
            BatStCrit     = 'Critical'
            BatStInUse    = 'In use'
            BatFraud      = 'WARNING: 100% health with 0 cycles is unusual. Verify with a discharge test.'
            UpgGood       = 'COMPUTER IN GOOD SHAPE'
            UpgNoCrit     = 'No critical areas detected.'
            UpgState      = 'OVERALL STATE: {0} ({1}/100)'
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
            RecRamSC      = 'RAM running in Single Channel'
            RecCpuObs     = 'Outdated processor'
            RecCpuOld     = 'Old processor ({0})'
            RecHdd        = 'Mechanical disk (HDD) - VERY slow'
            RecSataSsd    = 'SATA SSD (medium speed)'
            RecDiskCrit   = 'Critical disk space (>90%)'
            RecWin10Eol   = 'Windows 10 - End of support Oct 2025'
            RecOsObs      = 'Outdated operating system'
            RamActSold    = 'RAM is soldered. Replacing the computer with one with at least 8GB is recommended.'
            RamActFree    = 'Add a module in the free slot. {0} slot(s) available.'
            RamActReplace = 'Replace existing module(s) with higher capacity.'
            RamCostNew    = 'New computer: from S/1,200'
            RamCost8      = '8GB DDR4 module: S/80-120 | DDR5: S/120-180'
            RamCostKit    = '2x8GB DDR4 kit: S/150-200'
            RamImpactLow  = 'Below 4GB the system freezes frequently. Windows needs at least 4GB just to boot.'
            RamImpactMed  = 'With 8GB you improve multitasking, browsing with many tabs and Office apps.'
            RamActSoldOk  = 'Soldered RAM - cannot upgrade. Functional but limited.'
            RamActFreeMed = 'Add module in free slot ({0} available). Target: 16GB.'
            RamActReplaceMed = 'Replace with higher-capacity modules. Target: 16GB.'
            RamCostNa     = 'N/A (soldered)'
            RamSCAct      = 'Add a second identical module for Dual Channel. Improves 10-20%.'
            RamSCCost     = 'Identical module: S/80-180'
            RamSCImpact   = 'Dual channel improves gaming, editing and graphics tasks.'
            CpuActSold    = 'CPU is soldered. Replacing the entire computer is recommended.'
            CpuCostI5     = 'i5 Gen 12+ computer: from S/1,500'
            CpuActSocket  = 'Replace with a CPU compatible with socket {0}.'
            CpuCostUpg    = 'CPU upgrade: S/200-600'
            CpuImpactBasic= 'Basic/old CPU is the largest bottleneck. Everything feels slow.'
            CpuActSoldMed = 'CPU is soldered. Functional for basic office, consider replacement medium-term.'
            CpuCostFut    = 'New computer recommended in the future'
            CpuActUpgMed  = 'Consider upgrading to a higher-generation CPU.'
            CpuCostUpgMed = 'CPU upgrade: S/200-500'
            CpuImpactOld  = 'Old generations lack modern instructions and efficiency.'
            DiskActHdd    = 'Replace HDD with SSD. The HIGHEST-impact upgrade. Boots 5-10x faster.'
            DiskCostHdd   = 'SATA 480GB SSD: S/80-120 | NVMe 500GB: S/100-150'
            DiskImpactHdd = 'Switching from HDD to SSD is upgrade #1. Windows boots in 15s vs 2+ min.'
            DiskActSata   = 'Consider NVMe if the board supports it. 3-5x improvement in transfers.'
            DiskCostSata  = 'NVMe 500GB SSD: S/100-150 | 1TB: S/180-250'
            DiskImpactSata= 'NVMe improves load times, compilation and large transfers.'
            DiskActCrit   = 'Free up space or add an additional disk urgently.'
            DiskCostCrit  = 'Additional disk 500GB: S/80-150'
            DiskImpactCrit= 'Disk >90% causes extreme slowness, update failures and possible corruption.'
            OsActWin10    = 'Plan migration to Windows 11 if hardware is compatible.'
            OsCostWin10   = 'Win11 license: S/50-150 (or free upgrade)'
            OsImpactWin10 = 'No support = no security patches. Risk of vulnerabilities.'
            OsActObs      = 'Update to Windows 10/11 urgently.'
            OsCostObs     = 'Windows license: S/50-150'
            OsImpactObs   = 'Unpatched system = vulnerable to malware and ransomware.'
            GpuStep       = '8B. GPU slowness triage...'
            GpuVerdictOk  = 'PASS'
            GpuVerdictObs = 'OBSERVATION'
            GpuVerdictRisk= 'GPU/DRIVER RISK'
            GpuAdviceOk   = 'No strong GPU/driver failure signal was found. It is reasonable to continue with normal maintenance, while still checking SSD/RAM/CPU/software.'
            GpuAdviceObs  = 'Moderate GPU/driver signals were found. Warn the customer that maintenance may help, but there is no guarantee.'
            GpuAdviceRisk = 'Do not promise that thermal paste or a Windows reinstall will fix the slowness. Validate GPU/driver/hardware first and protect customer data.'
            GpuNoFindings = 'No strong GPU/driver red flags found.'
            GpuLimits     = 'Safe triage only: no stress test. It may not catch intermittent thermal GPU failures.'
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
            Step3         = '3. CPU Upgrade Check...'
            Step4         = '4. Diagnostico RAM...'
            Step5         = '5. Analisis de Almacenamiento...'
            Step6         = '6. Perfil de Red...'
            Step7         = '7. Eventos Criticos...'
            Step8         = '8. Auditando Bateria...'
            Step9         = '9. Generando Recomendaciones de Upgrade...'
            Step10        = '10. Generando Reporte HTML...'
            ScoreLine     = 'SCORE: {0}/100 - {1}'
            NoRecs        = '    Sin recomendaciones - equipo en buen estado.'
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
            H3Cpu         = '3. Estado del Procesador'
            H4Ram         = '4. Diagnostico de Memoria RAM'
            H5Storage     = '5. Almacenamiento'
            H6Net         = '6. Perfil de Red'
            H7Bsod        = '7. Registro de Eventos Criticos'
            H8Battery     = '8. Analisis de Energia'
            H9Upgrade     = '10. ⚡ RECOMENDACIONES DE UPGRADE - ATLAS ADVISOR'
            H10GpuTriage  = '9. Triaje de lentitud por GPU / driver de video'
            BsodNone      = 'Sin errores recientes.'
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
            NoBattery     = 'No se detecto bateria (PC de Escritorio).'
            RamSummary    = 'Slots: {0}/{1} | Max: {2} | Canal: {3}'
            DualCh        = 'Dual Channel'
            SingleCh      = 'Single Channel'
            UnreportedMax = 'No reportado (BIOS Legacy)'
            UnknownLbl    = 'Desconocido'
            FormUnk       = 'Desconocido'
            FormSoldered  = 'Soldada'
            FormRemov     = 'Removible'
            RamNoExp      = 'RAM NO AMPLIABLE: Todos los modulos ({0}) estan soldados. No es posible ampliar la memoria.'
            RamMixed      = 'MIXTA: {0} soldado(s) + {1} removible(s). {2}'
            RamFreeSlots  = '{0} slot(s) libre(s).'
            RamUpgradable = 'AMPLIABLE: {0} removible(s). {1} slot(s) libre(s).'
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
            CpuTblGen     = 'Generacion'
            CpuTblCores   = 'Nucleos / Hilos'
            CpuTblScore   = 'Clasificacion'
            CpuTblRepl    = 'Reemplazable'
            CpuSoldered   = 'SOLDADO (BGA) - No reemplazable'
            CpuProbSold   = 'PROBABLEMENTE SOLDADO'
            CpuSocketed   = 'SOCKET - Reemplazable'
            CpuAdvSold    = 'El procesador esta soldado a la placa. No es posible reemplazarlo.'
            CpuAdvProb    = 'Senales indican CPU probablemente soldado. Verifique con el fabricante.'
            CpuAdvSocket  = 'El procesador usa socket {0}. Es posible reemplazarlo por otro compatible.'
            CpuDetect     = 'Deteccion: {0}'
            CpuNoSig      = 'Sin senales especificas'
            CpuGenNotDet  = 'No detectada'
            ScoreBasic    = 'BASICO'
            ScoreOld      = 'ANTIGUO'
            ScoreOk       = 'ACEPTABLE'
            ScoreGood     = 'BUENO'
            StTblDisk     = 'Disco'
            StTblType     = 'Tipo'
            StTblBus      = 'Bus'
            StTblSize     = 'Tamano'
            StTblHealth   = 'Salud'
            StTblClass    = 'Clasificacion'
            StHddSlow     = 'HDD MECANICO - Lento'
            StSataMid     = 'SSD SATA - Medio'
            StNvmeFast    = 'NVMe - Rapido'
            StSsdUnk      = 'SSD (bus no identificado)'
            StUnclass     = 'No clasificado'
            StFreeOf      = '{0}GB libre de {1}GB'
            NetAdap       = 'Adaptador'
            NetIp         = 'IP'
            NetMac        = 'MAC'
            NetGw         = 'Gateway'
            NetDns        = 'DNS'
            BatStatus     = 'Estado'
            BatHealth     = 'Salud'
            BatCycles     = 'Ciclos'
            BatCap        = 'Capacidad'
            BatMan        = 'Fabricante'
            BatStDis      = 'Descargando'
            BatStCha      = 'Cargando'
            BatStFull     = 'Cargado 100%'
            BatStLow      = 'Bajo'
            BatStCrit     = 'Critico'
            BatStInUse    = 'En uso'
            BatFraud      = 'ALERTA: Salud 100% con 0 ciclos es inusual. Verificar con prueba de descarga.'
            UpgGood       = 'EQUIPO EN BUEN ESTADO'
            UpgNoCrit     = 'No se detectaron areas criticas.'
            UpgState      = 'ESTADO GENERAL: {0} ({1}/100)'
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
            RecRamSC      = 'RAM en Single Channel'
            RecCpuObs     = 'Procesador Obsoleto'
            RecCpuOld     = 'Procesador Antiguo ({0})'
            RecHdd        = 'Disco Mecanico (HDD) - MUY Lento'
            RecSataSsd    = 'SSD SATA (velocidad media)'
            RecDiskCrit   = 'Espacio en Disco Critico (>90%)'
            RecWin10Eol   = 'Windows 10 - Fin de Soporte Oct 2025'
            RecOsObs      = 'Sistema Operativo Obsoleto'
            RamActSold    = 'RAM soldada. Se recomienda reemplazar el equipo por uno con minimo 8GB.'
            RamActFree    = 'Agregar modulo en slot libre. Hay {0} slot(s) disponible(s).'
            RamActReplace = 'Reemplazar modulo(s) existente(s) por mayor capacidad.'
            RamCostNew    = 'Equipo nuevo: desde S/1,200'
            RamCost8      = 'Modulo 8GB DDR4: S/80-120 | DDR5: S/120-180'
            RamCostKit    = 'Kit 2x8GB DDR4: S/150-200'
            RamImpactLow  = 'Con menos de 4GB el sistema se congela frecuentemente. Windows necesita minimo 4GB solo para arrancar.'
            RamImpactMed  = 'Con 8GB se mejora multitarea, navegacion con muchas pestanas y apps de Office.'
            RamActSoldOk  = 'RAM soldada - no ampliable. Funcional pero limitado.'
            RamActFreeMed = 'Agregar modulo en slot libre ({0} disponible). Objetivo: 16GB.'
            RamActReplaceMed = 'Reemplazar por modulos de mayor capacidad. Objetivo: 16GB.'
            RamCostNa     = 'N/A (soldada)'
            RamSCAct      = 'Agregar segundo modulo identico para Dual Channel. Mejora 10-20%.'
            RamSCCost     = 'Modulo identico: S/80-180'
            RamSCImpact   = 'Dual channel mejora rendimiento en juegos, edicion y tareas graficas.'
            CpuActSold    = 'CPU soldado. Se recomienda reemplazar el equipo completo.'
            CpuCostI5     = 'Equipo i5 Gen 12+: desde S/1,500'
            CpuActSocket  = 'Reemplazar por CPU compatible con socket {0}.'
            CpuCostUpg    = 'CPU upgrade: S/200-600'
            CpuImpactBasic= 'CPU basico/antiguo es el mayor cuello de botella. Todo se siente lento.'
            CpuActSoldMed = 'CPU soldado. Funcional para oficina basica, considere reemplazo a mediano plazo.'
            CpuCostFut    = 'Equipo nuevo recomendado a futuro'
            CpuActUpgMed  = 'Considere upgrade a CPU de mayor generacion.'
            CpuCostUpgMed = 'CPU upgrade: S/200-500'
            CpuImpactOld  = 'Generaciones antiguas carecen de instrucciones modernas y eficiencia.'
            DiskActHdd    = 'Reemplazar HDD por SSD. Mejora con MAYOR impacto. Arrancara 5-10x mas rapido.'
            DiskCostHdd   = 'SSD SATA 480GB: S/80-120 | NVMe 500GB: S/100-150'
            DiskImpactHdd = 'Cambiar HDD a SSD es la mejora #1. Windows arranca en 15s en vez de 2+ min.'
            DiskActSata   = 'Considere NVMe si la placa soporta. Mejora 3-5x en transferencias.'
            DiskCostSata  = 'SSD NVMe 500GB: S/100-150 | 1TB: S/180-250'
            DiskImpactSata= 'NVMe mejora tiempos de carga, compilacion y transferencias grandes.'
            DiskActCrit   = 'Liberar espacio o agregar disco adicional urgentemente.'
            DiskCostCrit  = 'Disco adicional 500GB: S/80-150'
            DiskImpactCrit= 'Disco >90% causa lentitud extrema, fallos de update y posible corrupcion.'
            OsActWin10    = 'Planificar migracion a Windows 11 si el hardware es compatible.'
            OsCostWin10   = 'Licencia Win11: S/50-150 (o upgrade gratuito)'
            OsImpactWin10 = 'Sin soporte = sin parches de seguridad. Riesgo de vulnerabilidades.'
            OsActObs      = 'Actualizar a Windows 10/11 urgentemente.'
            OsCostObs     = 'Licencia Windows: S/50-150'
            OsImpactObs   = 'Sistema sin parches = vulnerable a malware y ransomware.'
            GpuStep       = '8B. Triaje de lentitud por GPU...'
            GpuVerdictOk  = 'APTO'
            GpuVerdictObs = 'OBSERVACION'
            GpuVerdictRisk= 'RIESGO GPU/DRIVER'
            GpuAdviceOk   = 'No se encontraron senales fuertes de fallo GPU/driver. Es razonable seguir con mantenimiento normal, revisando tambien SSD/RAM/CPU/software.'
            GpuAdviceObs  = 'Se encontraron senales moderadas de GPU/driver. Avisa al cliente que el mantenimiento puede ayudar, pero sin garantia.'
            GpuAdviceRisk = 'No prometas que pasta termica o reinstalar Windows va a resolver la lentitud. Valida GPU/driver/hardware primero y protege los datos del cliente.'
            GpuNoFindings = 'No se encontraron alertas fuertes de GPU/driver.'
            GpuLimits     = 'Triaje seguro solamente: sin stress test. Puede no capturar fallos termicos intermitentes de GPU.'
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
    param([string]$FilePath, [string]$Arguments = "", [int]$TimeoutSeconds = 60, [string]$WindowStyle = "Hidden")
    try {
        $proc = Start-Process $FilePath -ArgumentList $Arguments -PassThru -WindowStyle $WindowStyle -ErrorAction Stop
        $waited = $proc.WaitForExit($TimeoutSeconds * 1000)
        if (-not $waited) {
            $proc | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Host ($L.TimeoutMsg -f $TimeoutSeconds) -ForegroundColor Yellow
            return $false
        }
        return $true
    } catch {
        Write-Host ($L.ExecError -f $_) -ForegroundColor Red
        return $false
    }
}

function Get-RAMDiagnostic {
    $result = @{
        HtmlSection = ""; TextSummary = ""; MaxCapGB = 0
        SlotsTotal = 0; SlotsUsed = 0; SlotsLibres = 0
        Modules = @(); SolderedWarning = ""
        TotalGB = 0; AllSoldered = $false; HasFreeSlots = $false
        IsDualChannel = $false
    }

    try {
        $placa = Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction Stop | Select-Object -First 1
        $modulos = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
    } catch {
        $result.HtmlSection = "<h2>$($L.H4Ram)</h2><pre>$($L.NoMemHw)</pre>"
        return $result
    }

    if ($placa.MaxCapacity -and $placa.MaxCapacity -gt 0) {
        $result.MaxCapGB = [math]::Round(($placa.MaxCapacity / 1024 / 1024), 0)
    }

    $result.SlotsTotal = if ($placa.MemoryDevices) { $placa.MemoryDevices } else { 0 }
    $result.SlotsUsed = @($modulos).Count
    $result.SlotsLibres = [math]::Max(0, $result.SlotsTotal - $result.SlotsUsed)
    $result.HasFreeSlots = ($result.SlotsLibres -gt 0)
    $result.TotalGB = [math]::Round(($modulos | Measure-Object Capacity -Sum).Sum / 1GB, 0)
    $allSameCap = ($modulos | Select-Object -ExpandProperty Capacity -Unique | Measure-Object).Count -eq 1
    $result.IsDualChannel = ($result.SlotsUsed -ge 2 -and $allSameCap)

    $maxCapDisplay = if ($result.MaxCapGB -gt 0) { "$($result.MaxCapGB) GB" } else { $L.UnreportedMax }

    $chassis = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue
    $isLaptop = $false
    if ($chassis) {
        $laptopTypes = @(9, 10, 14, 31, 32)
        foreach ($ct in $chassis.ChassisTypes) { if ($ct -in $laptopTypes) { $isLaptop = $true; break } }
    }

    $formFactorNames = @{
        0=$L.FormUnk; 1="Other"; 2="SIP"; 3="DIP"; 4="ZIP"; 5="SOJ"; 6="Proprietary"
        7="SIMM"; 8="DIMM"; 9="TSOP"; 10="PGA"; 11="RIMM"; 12="SODIMM"; 13="SRIMM"
        14="SMD"; 15="SSMP"; 16="QFP"; 17="TQFP"; 18="SOIC"; 19="LCC"; 20="PLCC"
        21="BGA"; 22="FPBGA"; 23="LGA"; 24="FB-DIMM"
    }

    $solderedCount = 0; $removableCount = 0

    $htmlTable = "<table class='info-table'>"
    $htmlTable += "<tr><th>$($L.RamColSlot)</th><th>$($L.RamColMan)</th><th>$($L.RamColCap)</th><th>$($L.RamColSpeed)</th><th>$($L.RamColXmp)</th><th>$($L.RamColVolt)</th><th>$($L.RamColType)</th><th>$($L.RamColPart)</th></tr>"
    $textDetail = ($L.RamSummary -f $result.SlotsUsed, $result.SlotsTotal, $maxCapDisplay, $(if($result.IsDualChannel){$L.DualCh}else{$L.SingleCh})) + "`n"

    foreach ($ram in $modulos) {
        $capGB = [math]::Round($ram.Capacity / 1GB, 0)
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

        $xmpStatus = "OK"; $xmpColor = "#5cb85c"; $xmpIcon = "&#10004;"
        if ($configSpeed -gt 0 -and $nativeSpeed -gt 0 -and $configSpeed -lt $nativeSpeed) {
            $xmpStatus = "LOW (${configSpeed} vs ${nativeSpeed} MHz) - XMP off?"
            if ($lang -eq 'es') { $xmpStatus = "BAJA (${configSpeed} vs ${nativeSpeed} MHz) - XMP Apagado?" }
            $xmpColor = "#d9534f"; $xmpIcon = "&#9888;"
        } elseif ($configSpeed -eq 0 -or $nativeSpeed -eq 0) {
            $xmpStatus = if ($lang -eq 'es') { "No verificable" } else { "Not verifiable" }
            $xmpColor = "#888"; $xmpIcon = "?"
        }

        $thisIsSoldered = ($devLoc -match "Solder|Onboard|On Board|Integrad") -or
                          ($bankLabel -match "Solder|Onboard") -or
                          ($ff -eq 0 -and $isLaptop) -or
                          ($ff -in @(14, 21, 22))

        if ($thisIsSoldered) { $solderedCount++ } else { $removableCount++ }

        $typeDisplay = $ffName; $typeStyle = ""
        if ($thisIsSoldered) {
            $typeDisplay = "&#128274; ${ffName} ($($L.FormSoldered))"; $typeStyle = "color:#dc3545;font-weight:bold"
        } elseif ($ff -eq 8 -or $ff -eq 12 -or $ff -eq 24) {
            $typeDisplay = "&#128280; ${ffName} ($($L.FormRemov))"; $typeStyle = "color:#28a745"
        }

        $htmlTable += "<tr><td>${slot}</td><td>${fab}</td><td>${capGB} GB</td><td>${speedDisplay}</td>"
        $htmlTable += "<td style='color:${xmpColor};font-weight:bold'>${xmpIcon} ${xmpStatus}</td>"
        $htmlTable += "<td>${voltaje}</td><td style='${typeStyle};font-size:12px'>${typeDisplay}</td>"
        $htmlTable += "<td style='font-size:10px'>${part}</td></tr>"

        $textDetail += "  ${slot}: ${capGB}GB ${fab} @ ${speedDisplay} (${xmpStatus}) [${ffName}]`n"

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

    $channelLbl = if ($result.IsDualChannel) { $L.DualCh } else { $L.SingleCh }
    $htmlSummary = "<div style='background:#f0f4f8;padding:10px 15px;border-radius:4px;margin-bottom:10px;font-size:13px'>"
    $htmlSummary += "<strong>$($L.RamColSlot):</strong> $($result.SlotsUsed)/$($result.SlotsTotal) | "
    $htmlSummary += "<strong>Max:</strong> ${maxCapDisplay} | "
    $htmlSummary += "<strong>$(if($lang -eq 'es'){'Canal'}else{'Channel'}):</strong> ${channelLbl}"
    $htmlSummary += "</div>"

    $result.HtmlSection = $htmlSummary + $solderHtml + $htmlTable
    $result.TextSummary = $textDetail
    return $result
}

function Get-CPUUpgradeInfo {
    $result = @{
        HtmlSection = ""; IsSoldered = $false; SocketType = ""
        UpgradeMethod = ""; Summary = ""
        Generation = 0; GenerationLabel = ""; IsBasic = $false
        CoreCount = 0; ThreadCount = 0; CPUName = ""
        ScoreLabel = ""; ScoreColor = ""
    }

    $proc = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) {
        $result.HtmlSection = "<pre>$($L.NoCpuInfo)</pre>"
        return $result
    }

    $result.CPUName = if ($proc.Name) { $proc.Name.Trim() } else { $L.UnknownLbl }
    $result.CoreCount = if ($proc.NumberOfCores) { $proc.NumberOfCores } else { 0 }
    $result.ThreadCount = if ($proc.NumberOfLogicalProcessors) { $proc.NumberOfLogicalProcessors } else { 0 }
    $socketName = if ($proc.SocketDesignation) { $proc.SocketDesignation } else { $L.UnknownLbl }
    $result.SocketType = $socketName

    $upgradeCode = if ($proc.UpgradeMethod) { [int]$proc.UpgradeMethod } else { 2 }

    $upgradeMethodNames = @{
        1="Other"; 2=$L.UnknownLbl; 3="Daughter Board"; 4="ZIF Socket"; 5="Replaceable"
        6="None (BGA/Soldered)"; 7="LIF Socket"; 8="Slot 1"; 9="Slot 2"
        10="370-pin"; 11="Slot A"; 12="Slot M"; 13="Socket 423"; 14="Socket A (462)"
        15="Socket 478"; 16="Socket 754"; 17="Socket 940"; 18="Socket 939"
        19="mPGA604"; 20="LGA771"; 21="LGA775"; 22="S1"; 23="AM2"; 24="F (1207)"
        25="LGA1366"; 26="G34"; 27="AM3"; 28="C32"; 29="LGA1156"; 30="LGA1567"
        31="PGA988A"; 32="BGA1288"; 33="rPGA988B"; 34="BGA1023"; 35="BGA1224"
        36="LGA1155"; 37="LGA1356"; 38="LGA2011"; 39="FS1"; 40="FS2"; 41="FM1"
        42="FM2"; 43="LGA2011-3"; 44="LGA1356-3"; 45="LGA1150"; 46="BGA1168"
        47="BGA1234"; 48="BGA1364"; 49="AM4"; 50="LGA1151"; 51="BGA1356"
        52="BGA1440"; 53="BGA1515"; 54="LGA3647-1"; 55="SP3"; 56="SP3r2"
        57="LGA2066"; 58="BGA1392"; 59="BGA1510"; 60="BGA1528"; 61="LGA4189"
        62="LGA1200"; 63="LGA4677"; 64="LGA1700"; 65="BGA1744"; 66="BGA1781"
        67="BGA1211"; 68="BGA2422"; 69="LGA1211"; 70="LGA2085"; 71="LGA4710"
    }

    $upgradeMethodName = if ($upgradeMethodNames.ContainsKey($upgradeCode)) { $upgradeMethodNames[$upgradeCode] } else { "Code ${upgradeCode}" }
    $result.UpgradeMethod = $upgradeMethodName

    $cpuName = $result.CPUName
    $gen = 0; $genLabel = ""
    if ($cpuName -match "i[3579]-(\d{1,2})(\d{2,3})") { $gen = [int]$matches[1]; $genLabel = "Intel Gen ${gen}" }
    elseif ($cpuName -match "Core\s*Ultra") { $gen = 14; $genLabel = "Intel Core Ultra (Gen 14+)" }
    elseif ($cpuName -match "Intel.*\b(1[234]\d{2,3})\b") { $firstTwo = [int]($matches[1].Substring(0,2)); if ($firstTwo -ge 10 -and $firstTwo -le 14) { $gen=$firstTwo; $genLabel="Intel Gen ${gen}" } }
    elseif ($cpuName -match "Ryzen\s+[3579]\s+(\d)(\d{2,3})") { $gen = [int]$matches[1]; $genLabel = "AMD Ryzen Gen ${gen}" }
    elseif ($cpuName -match "Ryzen\s+[3579]\s+(\d)(\d{3})") { $gen = [int]$matches[1]; $genLabel = "AMD Ryzen Gen ${gen}" }
    elseif ($cpuName -match "Athlon|A[46]-|A[46]\s|E[12]-|FX-") { $gen = 1; $genLabel = "AMD Legacy" }
    $result.Generation = $gen; $result.GenerationLabel = $genLabel

    if ($cpuName -match "Celeron|Pentium|Atom|Sempron|Athlon") { $result.IsBasic = $true }
    elseif ($cpuName -match "i3-[234]\d{2}" -or ($cpuName -match "i3" -and $gen -le 4)) { $result.IsBasic = $true }
    elseif ($result.CoreCount -le 2 -and $result.ThreadCount -le 2) { $result.IsBasic = $true }

    if ($result.IsBasic -or $gen -le 3) { $result.ScoreLabel=$L.ScoreBasic; $result.ScoreColor="#dc3545" }
    elseif ($gen -le 6) { $result.ScoreLabel=$L.ScoreOld; $result.ScoreColor="#fd7e14" }
    elseif ($gen -le 9) { $result.ScoreLabel=$L.ScoreOk; $result.ScoreColor="#ffc107" }
    else { $result.ScoreLabel=$L.ScoreGood; $result.ScoreColor="#28a745" }
    if ($gen -eq 0 -and $result.CoreCount -ge 6) { $result.ScoreLabel=$L.ScoreOk; $result.ScoreColor="#ffc107" }

    $bgaSignals = 0; $bgaReasons = @()
    if ($upgradeCode -eq 6) { $bgaSignals += 3; $bgaReasons += "UpgradeMethod = None/BGA" }
    elseif ($upgradeMethodName -match "BGA") { $bgaSignals += 3; $bgaReasons += "Socket BGA (${upgradeMethodName})" }
    if ($socketName -match "BGA") { $bgaSignals += 2; $bgaReasons += "Socket designated BGA" }
    if ($cpuName -match "[-\s](\d{4,5})[UYHPG]\b") { $bgaSignals += 1; $bgaReasons += "Mobile suffix" }
    $chassis = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue
    $isLaptop = $false
    if ($chassis) { foreach ($ct in $chassis.ChassisTypes) { if ($ct -in @(9,10,14,31,32)) { $isLaptop=$true; break } } }
    if ($isLaptop -and $bgaSignals -ge 1) { $bgaSignals += 1; $bgaReasons += "Laptop chassis" }

    if ($bgaSignals -ge 3) {
        $result.IsSoldered=$true; $statusIcon="&#128274;"; $statusText=$L.CpuSoldered
        $statusColor="#dc3545"; $bgColor="#f8d7da"; $borderColor="#f5c6cb"; $textColor="#721c24"
        $advice=$L.CpuAdvSold
    } elseif ($bgaSignals -ge 1) {
        $result.IsSoldered=$true; $statusIcon="&#9888;"; $statusText=$L.CpuProbSold
        $statusColor="#fd7e14"; $bgColor="#fff3cd"; $borderColor="#ffeeba"; $textColor="#856404"
        $advice=$L.CpuAdvProb
    } else {
        $result.IsSoldered=$false; $statusIcon="&#128280;"; $statusText=$L.CpuSocketed
        $statusColor="#28a745"; $bgColor="#d4edda"; $borderColor="#c3e6cb"; $textColor="#155724"
        $advice=$L.CpuAdvSocket -f $socketName
    }

    $reasonList = if ($bgaReasons.Count -gt 0) { $bgaReasons -join " | " } else { $L.CpuNoSig }
    $alertHtml = "<div style='background:${bgColor};color:${textColor};padding:12px;border:1px solid ${borderColor};border-radius:4px;margin-top:10px;font-size:13px'>"
    $alertHtml += "<strong>${statusIcon} ${statusText}</strong><br>${advice}<br>"
    $alertHtml += "<span style='font-size:11px;opacity:0.8'>$($L.CpuDetect -f $reasonList)</span></div>"

    $scoreLabel=$result.ScoreLabel; $scoreColor=$result.ScoreColor
    $genDisplay = if ($genLabel) { $genLabel } else { $L.CpuGenNotDet }
    $cpuTable = "<table class='info-table'>"
    $cpuTable += "<tr><th>$($L.CpuTblSocket)</th><td>${socketName}</td></tr>"
    $cpuTable += "<tr><th>$($L.CpuTblUpg)</th><td>${upgradeMethodName}</td></tr>"
    $cpuTable += "<tr><th>$($L.CpuTblGen)</th><td>${genDisplay}</td></tr>"
    $cpuTable += "<tr><th>$($L.CpuTblCores)</th><td>$($result.CoreCount)C / $($result.ThreadCount)T</td></tr>"
    $cpuTable += "<tr><th>$($L.CpuTblScore)</th><td style='color:${scoreColor};font-weight:bold'>${scoreLabel}</td></tr>"
    $cpuTable += "<tr><th>$($L.CpuTblRepl)</th><td style='color:${statusColor};font-weight:bold'>${statusIcon} ${statusText}</td></tr>"
    $cpuTable += "</table>"
    $result.HtmlSection = $cpuTable + $alertHtml
    $result.Summary = "${statusText} | ${scoreLabel} | ${genDisplay}"
    return $result
}

function Get-StorageAnalysis {
    $result = @{ Disks = @(); HasHDD = $false; HasSATASSD = $false; HasNVMe = $false; CriticalSpace = $false; HtmlSection = "" }
    $physDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    $logDisks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 3 }

    $htmlTable = "<table class='info-table'><tr><th>$($L.StTblDisk)</th><th>$($L.StTblType)</th><th>$($L.StTblBus)</th><th>$($L.StTblSize)</th><th>$($L.StTblHealth)</th><th>$($L.StTblClass)</th></tr>"
    if ($physDisks) {
        foreach ($pd in $physDisks) {
            $name = if ($pd.FriendlyName) { $pd.FriendlyName } else { $L.DiskLbl }
            $media = if ($pd.MediaType) { $pd.MediaType.ToString() } else { $L.UnknownLbl }
            $bus = if ($pd.BusType) { $pd.BusType.ToString() } else { $L.UnknownLbl }
            $sizeGB = if ($pd.Size) { [math]::Round($pd.Size / 1GB, 0) } else { 0 }
            $health = if ($pd.HealthStatus) { $pd.HealthStatus.ToString() } else { $L.UnknownLbl }
            $healthColor = if ($health -eq "Healthy") { "#28a745" } else { "#dc3545" }
            $classification = ""; $classColor = ""
            if ($media -match "HDD" -or ($media -match "Unspecified" -and $sizeGB -gt 500 -and $bus -match "SATA|ATA" -and $bus -notmatch "NVMe")) {
                $result.HasHDD = $true; $classification = "&#9888; $($L.StHddSlow)"; $classColor = "#dc3545"
            } elseif ($media -match "SSD" -and $bus -match "SATA|ATA" -and $bus -notmatch "NVMe") {
                $result.HasSATASSD = $true; $classification = "&#9432; $($L.StSataMid)"; $classColor = "#ffc107"
            } elseif ($bus -match "NVMe") {
                $result.HasNVMe = $true; $classification = "&#10004; $($L.StNvmeFast)"; $classColor = "#28a745"
            }
            if ([string]::IsNullOrEmpty($classification)) {
                if ($media -match "SSD") { $classification = $L.StSsdUnk; $classColor = "#888" }
                else { $classification = $L.StUnclass; $classColor = "#888" }
            }
            $htmlTable += "<tr><td>${name}</td><td>${media}</td><td>${bus}</td><td>${sizeGB} GB</td><td style='color:${healthColor}'>${health}</td><td style='color:${classColor};font-weight:bold'>${classification}</td></tr>"
            $result.Disks += @{ Name=$name; Media=$media; Bus=$bus; SizeGB=$sizeGB; Health=$health; Class=$classification }
        }
    }
    $htmlTable += "</table>"

    $spaceHtml = ""
    if ($logDisks) {
        $spaceHtml = "<div style='margin-top:10px'>"
        foreach ($ld in $logDisks) {
            $totalGB = [math]::Round($ld.Size / 1GB, 1)
            $freeGB = [math]::Round($ld.FreeSpace / 1GB, 1)
            $usedPct = if ($ld.Size -gt 0) { [math]::Round((($ld.Size - $ld.FreeSpace) / $ld.Size) * 100, 0) } else { 0 }
            $barColor = if ($usedPct -ge 90) { "#dc3545" } elseif ($usedPct -ge 75) { "#ffc107" } else { "#28a745" }
            if ($usedPct -ge 90) { $result.CriticalSpace = $true }
            $spaceHtml += "<div style='margin:5px 0;font-size:13px'><strong>$($ld.DeviceID)</strong> $($L.StFreeOf -f $freeGB, $totalGB) "
            $spaceHtml += "<div style='background:#e9ecef;border-radius:4px;height:14px;width:200px;display:inline-block;vertical-align:middle'>"
            $spaceHtml += "<div style='background:${barColor};height:100%;width:${usedPct}%;border-radius:4px'></div></div>"
            $spaceHtml += " <span style='color:${barColor};font-weight:bold'>${usedPct}%</span></div>"
        }
        $spaceHtml += "</div>"
    }
    $result.HtmlSection = $htmlTable + $spaceHtml
    return $result
}

function Get-UpgradeAdvisor {
    param([hashtable]$RAMData, [hashtable]$CPUData, [hashtable]$StorageData, [string]$OSCaption)
    $recommendations = @(); $overallScore = 0; $maxScore = 0

    $maxScore += 25; $ramGB = $RAMData.TotalGB
    if ($ramGB -lt 4) {
        $overallScore += 0
        if ($RAMData.AllSoldered) { $ramAction=$L.RamActSold; $ramCost=$L.RamCostNew }
        elseif ($RAMData.HasFreeSlots) { $ramAction=($L.RamActFree -f $RAMData.SlotsLibres); $ramCost=$L.RamCost8 }
        else { $ramAction=$L.RamActReplace; $ramCost=$L.RamCost8 }
        $recommendations += @{ Area="RAM"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=($L.RecRamLow -f $ramGB); Action=$ramAction; Cost=$ramCost; Impact=$L.RamImpactLow; Score=0 }
    } elseif ($ramGB -lt 8) {
        $overallScore += 10
        if ($RAMData.AllSoldered) { $ramAction=$L.RamActSoldOk; $ramCost=$L.RamCostNa }
        elseif ($RAMData.HasFreeSlots) { $ramAction=($L.RamActFreeMed -f $RAMData.SlotsLibres); $ramCost=$L.RamCost8 }
        else { $ramAction=$L.RamActReplaceMed; $ramCost=$L.RamCostKit }
        $recommendations += @{ Area="RAM"; Level=$L.LvlLow; Color="#fd7e14"; Icon="&#9432;"; Title=($L.RecRamLim -f $ramGB); Action=$ramAction; Cost=$ramCost; Impact=$L.RamImpactMed; Score=10 }
    } else { $overallScore += 25 }

    if (-not $RAMData.IsDualChannel -and $ramGB -ge 8 -and -not $RAMData.AllSoldered) {
        $recommendations += @{ Area="RAM"; Level=$L.LvlNotice; Color="#ffc107"; Icon="&#9432;"; Title=$L.RecRamSC; Action=$L.RamSCAct; Cost=$L.RamSCCost; Impact=$L.RamSCImpact; Score=0 }
    }

    $maxScore += 25
    if ($CPUData.IsBasic -or $CPUData.Generation -le 3) {
        $overallScore += 0
        if ($CPUData.IsSoldered) { $cpuAction=$L.CpuActSold; $cpuCost=$L.CpuCostI5 }
        else { $cpuAction=($L.CpuActSocket -f $CPUData.SocketType); $cpuCost=$L.CpuCostUpg }
        $recommendations += @{ Area="CPU"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=$L.RecCpuObs; Action=$cpuAction; Cost=$cpuCost; Impact=$L.CpuImpactBasic; Score=0 }
    } elseif ($CPUData.Generation -le 6) {
        $overallScore += 10
        if ($CPUData.IsSoldered) { $cpuAction=$L.CpuActSoldMed; $cpuCost=$L.CpuCostFut }
        else { $cpuAction=$L.CpuActUpgMed; $cpuCost=$L.CpuCostUpgMed }
        $recommendations += @{ Area="CPU"; Level=$L.LvlOld; Color="#fd7e14"; Icon="&#9432;"; Title=($L.RecCpuOld -f $CPUData.GenerationLabel); Action=$cpuAction; Cost=$cpuCost; Impact=$L.CpuImpactOld; Score=10 }
    } elseif ($CPUData.Generation -le 9) { $overallScore += 20 }
    else { $overallScore += 25 }

    $maxScore += 25
    if ($StorageData.HasHDD -and -not $StorageData.HasNVMe -and -not $StorageData.HasSATASSD) {
        $overallScore += 0
        $recommendations += @{ Area="DISK"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=$L.RecHdd; Action=$L.DiskActHdd; Cost=$L.DiskCostHdd; Impact=$L.DiskImpactHdd; Score=0 }
    } elseif ($StorageData.HasSATASSD -and -not $StorageData.HasNVMe) {
        $overallScore += 18
        $recommendations += @{ Area="DISK"; Level=$L.LvlNotice; Color="#ffc107"; Icon="&#9432;"; Title=$L.RecSataSsd; Action=$L.DiskActSata; Cost=$L.DiskCostSata; Impact=$L.DiskImpactSata; Score=18 }
    } elseif ($StorageData.HasNVMe) { $overallScore += 25 }
    else { $overallScore += 15 }

    if ($StorageData.CriticalSpace) {
        $recommendations += @{ Area="DISK"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=$L.RecDiskCrit; Action=$L.DiskActCrit; Cost=$L.DiskCostCrit; Impact=$L.DiskImpactCrit; Score=0 }
    }

    $maxScore += 25; $osScore = 25
    if ($OSCaption -match "Windows 10") {
        $osScore = 15
        $recommendations += @{ Area="OS"; Level=$L.LvlNotice; Color="#fd7e14"; Icon="&#9432;"; Title=$L.RecWin10Eol; Action=$L.OsActWin10; Cost=$L.OsCostWin10; Impact=$L.OsImpactWin10; Score=15 }
    } elseif ($OSCaption -match "Windows 7|Windows 8") {
        $osScore = 0
        $recommendations += @{ Area="OS"; Level=$L.LvlCritical; Color="#dc3545"; Icon="&#9888;"; Title=$L.RecOsObs; Action=$L.OsActObs; Cost=$L.OsCostObs; Impact=$L.OsImpactObs; Score=0 }
    }
    $overallScore += $osScore

    $globalPct = if ($maxScore -gt 0) { [math]::Round(($overallScore / $maxScore) * 100, 0) } else { 0 }
    if ($globalPct -ge 80) { $globalLabel=$L.ScoreGood; $globalColor="#28a745"; $globalIcon="&#10004;" }
    elseif ($globalPct -ge 60) { $globalLabel=$L.ScoreOk; $globalColor="#ffc107"; $globalIcon="&#9432;" }
    elseif ($globalPct -ge 35) { $globalLabel=$L.LvlLow; $globalColor="#fd7e14"; $globalIcon="&#9888;" }
    else { $globalLabel=$L.LvlCritical; $globalColor="#dc3545"; $globalIcon="&#9888;" }

    $html = ""
    if ($recommendations.Count -eq 0) {
        $html = "<div style='background:#d4edda;color:#155724;padding:20px;border-radius:6px;text-align:center;font-size:16px'><strong>&#10004; $($L.UpgGood)</strong><br>$($L.UpgNoCrit)</div>"
    } else {
        $html += "<div style='text-align:center;margin-bottom:20px'><div style='display:inline-block;background:${globalColor};color:#fff;padding:15px 30px;border-radius:50px;font-size:20px;font-weight:bold'>${globalIcon} $($L.UpgState -f $globalLabel, $globalPct)</div></div>"
        $html += "<table class='info-table' style='margin-top:15px'><tr><th style='width:70px'>$($L.UpgArea)</th><th style='width:80px'>$($L.UpgLevel)</th><th>$($L.UpgDiag)</th><th>$($L.UpgAction)</th><th style='width:180px'>$($L.UpgCost)</th></tr>"
        $sorted = $recommendations | Sort-Object {
            $lvl = $_.Level
            if ($lvl -eq $L.LvlCritical) { 0 }
            elseif ($lvl -eq $L.LvlLow) { 1 }
            elseif ($lvl -eq $L.LvlOld) { 2 }
            elseif ($lvl -eq $L.LvlNotice) { 3 }
            else { 4 }
        }
        foreach ($rec in $sorted) {
            $recColor = $rec.Color
            $html += "<tr><td><strong>$($rec.Area)</strong></td>"
            $html += "<td style='color:#fff;background:${recColor};padding:3px 8px;border-radius:4px;font-weight:bold;text-align:center;white-space:nowrap'>$($rec.Icon) $($rec.Level)</td>"
            $html += "<td><strong>$($rec.Title)</strong><br><span style='font-size:11px;color:#666'>$($rec.Impact)</span></td>"
            $html += "<td>$($rec.Action)</td><td style='font-size:12px'>$($rec.Cost)</td></tr>"
        }
        $html += "</table>"
    }
    return @{ HtmlSection=$html; Recommendations=$recommendations; Score=$globalPct; ScoreLabel=$globalLabel; ScoreColor=$globalColor }
}

function Get-NetworkProfile {
    $result = @{ HtmlSection = ""; TextSummary = "" }
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPEnabled }
    if (-not $adapters) { $result.HtmlSection = "<pre>$($L.NoNetAdapt)</pre>"; return $result }
    $htmlTable = "<table class='info-table'><tr><th>$($L.NetAdap)</th><th>$($L.NetIp)</th><th>$($L.NetMac)</th><th>$($L.NetGw)</th><th>$($L.NetDns)</th></tr>"
    $textNet = ""
    foreach ($a in $adapters) {
        $desc = if ($a.Description) { $a.Description } else { $L.UnknownLbl }
        $ip = if ($a.IPAddress) { ($a.IPAddress | Select-Object -First 1) } else { "N/A" }
        $mac = if ($a.MACAddress) { $a.MACAddress } else { "N/A" }
        $gw = if ($a.DefaultIPGateway) { ($a.DefaultIPGateway | Select-Object -First 1) } else { "N/A" }
        $dns = if ($a.DNSServerSearchOrder) { ($a.DNSServerSearchOrder -join ", ") } else { "N/A" }
        $htmlTable += "<tr><td>${desc}</td><td>${ip}</td><td style='font-family:Consolas;font-size:11px'>${mac}</td><td>${gw}</td><td style='font-size:11px'>${dns}</td></tr>"
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
            foreach ($ev in @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = $provider; StartTime = $Since } -ErrorAction Stop)) {
                [void]$events.Add($ev)
            }
        } catch {}
    }
    foreach ($id in 4101, 14, 13, 117, 141, 144, 1001) {
        try {
            $found = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = $id; StartTime = $Since } -ErrorAction Stop | Where-Object {
                $_.ProviderName -match 'Display|nvlddmkm|amdkmdag|amdwddmg|igfx|dxg|WHEA|BugCheck'
            })
            foreach ($ev in $found) { [void]$events.Add($ev) }
        } catch {}
    }
    try {
        $wer = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1001; StartTime = $Since } -ErrorAction Stop | Where-Object {
            $_.ProviderName -match 'Windows Error Reporting' -and $_.Message -match 'LiveKernelEvent|117|141|144|VIDEO_TDR|Display|graphics|hardware error'
        })
        foreach ($ev in $wer) { [void]$events.Add($ev) }
    } catch {}
    return @($events | Sort-Object RecordId -Unique | Sort-Object TimeCreated -Descending)
}

function Get-GpuLiveKernelFiles {
    param([datetime]$Since)
    $roots = @("$env:SystemRoot\LiveKernelReports", "$env:SystemRoot\Minidump")
    $files = @()
    foreach ($root in $roots) {
        if (-not $root -or -not (Test-Path -LiteralPath $root)) { continue }
        try {
            $files += @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
                $_.LastWriteTime -ge $Since -and ($_.FullName -match 'WATCHDOG|WHEA|VIDEO|GRAPHICS|GPU|\.dmp$')
            } | Select-Object FullName, LastWriteTime, Length)
        } catch {}
    }
    return @($files | Sort-Object LastWriteTime -Descending)
}

function Get-GPUSlownessTriageForReport {
    $since = (Get-Date).AddDays(-30)
    $findings = New-Object System.Collections.ArrayList
    $gpus = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | ForEach-Object {
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

    $events = @(Get-GpuTargetedEvents -Since $since)
    $tdrEvents = @($events | Where-Object { $_.Id -in 4101, 117, 141, 144 -or $_.Message -match 'TDR|LiveKernelEvent|VIDEO_TDR|Display driver stopped responding' })
    $driverEvents = @($events | Where-Object { $_.ProviderName -match 'nvlddmkm|amdkmdag|amdwddmg|igfx|dxg' })
    $wheaEvents = @($events | Where-Object { $_.ProviderName -match 'WHEA' })
    $bugCheckTdr = @($events | Where-Object { $_.Message -match '0x00000116|0x00000117|VIDEO_TDR_FAILURE|VIDEO_SCHEDULER_INTERNAL_ERROR' })
    $lkFiles = @(Get-GpuLiveKernelFiles -Since $since)

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

    $html = "<div style='border-left:5px solid ${color};background:#fff;padding:12px;margin:10px 0'><strong style='color:${color};font-size:18px'>${verdict} (${score}/100)</strong><br>${advice}<br><span style='font-size:12px;color:#666'>$($L.GpuLimits)</span></div>"
    $html += "<h3>$($L.GpuInv)</h3><table class='info-table'><tr><th>GPU</th><th>Driver</th><th>$($L.GpuTblDriverDate)</th><th>VRAM GB</th><th>$($L.GpuTblStatus)</th><th>$($L.GpuTblPnp)</th></tr>"
    foreach ($gpu in $gpus) {
        $html += "<tr><td>$($gpu.Name)</td><td>$($gpu.DriverVersion)</td><td>$($gpu.DriverDateText)</td><td>$($gpu.AdapterRAMGB)</td><td>$($gpu.Status)</td><td>$($gpu.ConfigManagerErrorCode)</td></tr>"
    }
    $html += "</table>"
    $html += "<h3>$($L.GpuSignals)</h3><table class='info-table'><tr><th>$($L.GpuSeverity)</th><th>$($L.GpuSignal)</th><th>$($L.GpuEvidence)</th><th>$($L.GpuAction)</th><th>$($L.GpuPoints)</th></tr>"
    if ($findings.Count -gt 0) {
        foreach ($f in $findings) {
            $html += "<tr><td>$($f.Severity)</td><td>$($f.Signal)</td><td>$($f.Evidence)</td><td>$($f.Action)</td><td>$($f.Points)</td></tr>"
        }
    } else {
        $html += "<tr><td colspan='5'>$($L.GpuNoFindings)</td></tr>"
    }
    $html += "</table>"
    $html += "<h3>$($L.GpuRecentEv)</h3><table class='info-table'><tr><th>$($L.GpuTblTime)</th><th>$($L.GpuTblProvider)</th><th>ID</th><th>$($L.GpuTblLevel)</th></tr>"
    if ($events.Count -gt 0) {
        foreach ($ev in @($events | Select-Object -First 15)) {
            $html += "<tr><td>$($ev.TimeCreated)</td><td>$($ev.ProviderName)</td><td>$($ev.Id)</td><td>$($ev.LevelDisplayName)</td></tr>"
        }
    } else {
        $html += "<tr><td colspan='4'>$($L.GpuNoEvents)</td></tr>"
    }
    $html += "</table>"

    return @{ HtmlSection = $html; Score = $score; Verdict = $verdict; Color = $color; Findings = @($findings) }
}

function Ensure-Dir {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Find-FirstExistingPath {
    param([string[]]$Candidates)
    foreach ($c in @($Candidates)) {
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        $p = [Environment]::ExpandEnvironmentVariables($c)
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Find-ToolFileInRoots {
    param(
        [string[]]$Roots,
        [string[]]$Names
    )
    foreach ($root in @($Roots)) {
        if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) { continue }
        foreach ($name in @($Names)) {
            $hit = Get-ChildItem -Path $root -Filter $name -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { return $hit.FullName }
        }
    }
    return $null
}

function Get-OfflineDiagToolsRoot {
    if ([string]::IsNullOrWhiteSpace($env:ATLAS_OFFLINE_ROOT)) { return $null }
    $root = Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\DiagnosticoMaster\tools'
    if (Test-Path -LiteralPath $root) { return $root }
    return $null
}

function Resolve-DiagDep {
    param(
        [Parameter(Mandatory)] [string]$WingetId,
        [Parameter(Mandatory)] [string[]]$InstallPaths,
        [string[]]$CommandNames
    )

    $resolved = Find-FirstExistingPath -Candidates $InstallPaths
    if (-not $resolved -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        try {
            winget install --id $WingetId --exact --accept-source-agreements --accept-package-agreements --silent | Out-Null
        } catch {}
        if ($CommandNames) {
            foreach ($cmdName in $CommandNames) {
                $cmd = Get-Command $cmdName -ErrorAction SilentlyContinue
                if ($cmd) { $resolved = $cmd.Source; break }
            }
        }
        if (-not $resolved) {
            $resolved = Find-FirstExistingPath -Candidates $InstallPaths
        }
    }

    if ($resolved) {
        $resolved = try {
            $item = Get-Item -LiteralPath $resolved -ErrorAction Stop
            if ($item.Attributes -match "ReparsePoint") {
                if ($item.LinkTarget) { $item.LinkTarget }
                elseif ($item.Target) {
                    if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
                } else { $resolved }
            } else { $resolved }
        } catch { $resolved }
    }
    return $resolved
}

function Stage-DiagDep {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$ToolsDir,
        [string]$TargetName
    )
    if (-not (Test-Path -LiteralPath $Source)) { return $null }
    Ensure-Dir -Path $ToolsDir
    $name = if ($TargetName) { $TargetName } else { Split-Path -Leaf $Source }
    $dst = Join-Path $ToolsDir $name
    Copy-Item -LiteralPath $Source -Destination $dst -Force
    return $dst
}

function Resolve-DiagnosticoMasterTools {
    param(
        [Parameter(Mandatory)] [string]$ToolsDir,
        [string]$LegacyAppsDir,
        [string]$SelMode = "3"
    )

    Ensure-Dir -Path $ToolsDir

    # Clean up legacy standalone files in ToolsDir that cause crashes due to missing resources
    foreach ($file in @('DiskInfo64.exe', 'DiskInfo32.exe', 'DiskMark64.exe')) {
        $legacyPath = Join-Path $ToolsDir $file
        if (Test-Path -LiteralPath $legacyPath) {
            Remove-Item -LiteralPath $legacyPath -Force -ErrorAction SilentlyContinue
        }
    }

    $offlineRoot = Get-OfflineDiagToolsRoot
    if ($offlineRoot) {
        # Copy standard single-file tools (added HWiNFO64.exe)
        foreach ($name in @('cpuz_x64.exe', 'cpuz_x32.exe', 'cpuz.exe', 'BlueScreenView.exe', 'BatteryInfoView.exe', 'HWiNFO64.exe')) {
            $src = Join-Path $offlineRoot $name
            if (Test-Path -LiteralPath $src) {
                Copy-Item -LiteralPath $src -Destination (Join-Path $ToolsDir $name) -Force
            }
        }
        # Copy CrystalDiskInfo folder recursively (preserves CdiResource folder and avoids crashes)
        $srcCdi = Join-Path $offlineRoot 'CrystalDiskInfo'
        if (Test-Path -LiteralPath $srcCdi) {
            $destCdi = Join-Path $ToolsDir 'CrystalDiskInfo'
            Ensure-Dir -Path $destCdi
            Copy-Item -Path (Join-Path $srcCdi "*") -Destination $destCdi -Recurse -Force -ErrorAction SilentlyContinue
        }
        # Copy CrystalDiskMark folder recursively (preserves CdmResource folder and avoids crashes)
        $srcCdm = Join-Path $offlineRoot 'CrystalDiskMark'
        if (Test-Path -LiteralPath $srcCdm) {
            $destCdm = Join-Path $ToolsDir 'CrystalDiskMark'
            Ensure-Dir -Path $destCdm
            Copy-Item -Path (Join-Path $srcCdm "*") -Destination $destCdm -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $cpuz = $null
    if ($SelMode -eq "2" -or $SelMode -eq "3") {
        $cpuz = Find-ToolFileInRoots -Roots @($ToolsDir) -Names @('cpuz_x64.exe', 'cpuz_x32.exe', 'cpuz.exe')
        if (-not $cpuz) {
            $cpuzSrc = Resolve-DiagDep -WingetId 'CPUID.CPU-Z' -CommandNames @('cpuz.exe', 'cpuz_x64.exe', 'cpuz_x32.exe') -InstallPaths @(
                'C:\Program Files\CPUID\CPU-Z\cpuz_x64.exe',
                'C:\Program Files\CPUID\CPU-Z\cpuz_x32.exe',
                'C:\Program Files\CPUID\CPU-Z\cpuz.exe',
                'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x64.exe',
                'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x32.exe',
                'C:\Program Files (x86)\CPUID\CPU-Z\cpuz.exe',
                '%LOCALAPPDATA%\Microsoft\WinGet\Links\cpuz.exe'
            )
            if ($cpuzSrc) { $cpuz = Stage-DiagDep -Source $cpuzSrc -ToolsDir $ToolsDir }
        }
    }

    $bsod = Find-FirstExistingPath -Candidates @(
        (Join-Path $ToolsDir 'BlueScreenView.exe')
    )
    if (-not $bsod) {
        $bsodSrc = Resolve-DiagDep -WingetId 'NirSoft.BlueScreenView' -CommandNames @('bluescreenview.exe', 'BlueScreenView.exe') -InstallPaths @(
            'C:\Program Files\NirSoft\BlueScreenView\BlueScreenView.exe',
            'C:\Program Files (x86)\NirSoft\BlueScreenView\BlueScreenView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\bluescreenview.exe'
        )
        if ($bsodSrc) { $bsod = Stage-DiagDep -Source $bsodSrc -ToolsDir $ToolsDir -TargetName 'BlueScreenView.exe' }
    }

    $battery = Find-FirstExistingPath -Candidates @(
        (Join-Path $ToolsDir 'BatteryInfoView.exe')
    )
    if (-not $battery) {
        $batterySrc = Resolve-DiagDep -WingetId 'NirSoft.BatteryInfoView' -CommandNames @('batteryinfoview.exe', 'BatteryInfoView.exe') -InstallPaths @(
            'C:\Program Files\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            'C:\Program Files (x86)\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\batteryinfoview.exe'
        )
        if ($batterySrc) { $battery = Stage-DiagDep -Source $batterySrc -ToolsDir $ToolsDir -TargetName 'BatteryInfoView.exe' }
    }

    $cdi = $null
    if ($SelMode -eq "3") {
        $cdiCandidates = @(
            'C:\Program Files\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files\CrystalDiskInfo\DiskInfo32.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo32.exe',
            (Join-Path $LegacyAppsDir 'CrystalDiskInfo\DiskInfo64.exe'),
            (Join-Path $LegacyAppsDir 'CrystalDiskInfo\DiskInfo32.exe'),
            (Join-Path $ToolsDir 'CrystalDiskInfo\DiskInfo64.exe'),
            (Join-Path $ToolsDir 'CrystalDiskInfo\DiskInfo32.exe'),
            (Join-Path $ToolsDir 'DiskInfo64.exe'),
            (Join-Path $ToolsDir 'DiskInfo32.exe')
        )
        if ($env:ATLAS_OFFLINE_ROOT) {
            $cdiCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'apps\CrystalDiskInfo\DiskInfo64.exe'
            $cdiCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'apps\CrystalDiskInfo\DiskInfo32.exe'
            $cdiCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\DiagnosticoMaster\tools\CrystalDiskInfo\DiskInfo64.exe'
            $cdiCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\DiagnosticoMaster\tools\CrystalDiskInfo\DiskInfo32.exe'
        }
        # Check only candidates that have the CdiResource folder
        $validCdiCandidates = @()
        foreach ($cand in $cdiCandidates) {
            $candPath = [Environment]::ExpandEnvironmentVariables($cand)
            if (Test-Path -LiteralPath $candPath) {
                $parent = Split-Path -Parent $candPath
                if (Test-Path -LiteralPath (Join-Path $parent "CdiResource")) {
                    $validCdiCandidates += $candPath
                }
            }
        }
        $cdi = if ($validCdiCandidates.Count -gt 0) { $validCdiCandidates[0] } else { $null }

        if (-not $cdi) {
            $cdiSrc = Resolve-DiagDep -WingetId 'CrystalDewWorld.CrystalDiskInfo' -CommandNames @('diskinfo.exe', 'DiskInfo64.exe', 'DiskInfo32.exe') -InstallPaths @(
                'C:\Program Files\CrystalDiskInfo\DiskInfo64.exe',
                'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo64.exe',
                'C:\Program Files\CrystalDiskInfo\DiskInfo32.exe',
                'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo32.exe',
                '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskinfo.exe'
            )
            # Extra verification for Winget source
            if ($cdiSrc -and (Test-Path -LiteralPath $cdiSrc)) {
                $parent = Split-Path -Parent $cdiSrc
                if (Test-Path -LiteralPath (Join-Path $parent "CdiResource")) {
                    $cdi = $cdiSrc
                }
            }
        }
    }

    $cdm = $null
    if ($SelMode -eq "3") {
        $cdmCandidates = @(
            'C:\Program Files\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark\DiskMark64.exe',
            (Join-Path $LegacyAppsDir 'CrystalDiskMark\DiskMark64.exe'),
            (Join-Path $ToolsDir 'CrystalDiskMark\DiskMark64.exe'),
            (Join-Path $ToolsDir 'DiskMark64.exe')
        )
        if ($env:ATLAS_OFFLINE_ROOT) {
            $cdmCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'apps\CrystalDiskMark\DiskMark64.exe'
            $cdmCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\DiagnosticoMaster\tools\CrystalDiskMark\DiskMark64.exe'
        }
        # Check only candidates that have the CdmResource folder
        $validCdmCandidates = @()
        foreach ($cand in $cdmCandidates) {
            $candPath = [Environment]::ExpandEnvironmentVariables($cand)
            if (Test-Path -LiteralPath $candPath) {
                $parent = Split-Path -Parent $candPath
                if (Test-Path -LiteralPath (Join-Path $parent "CdmResource")) {
                    $validCdmCandidates += $candPath
                }
            }
        }
        $cdm = if ($validCdmCandidates.Count -gt 0) { $validCdmCandidates[0] } else { $null }

        if (-not $cdm) {
            $cdmSrc = Resolve-DiagDep -WingetId 'CrystalDewWorld.CrystalDiskMark' -CommandNames @('diskmark.exe', 'DiskMark64.exe') -InstallPaths @(
                'C:\Program Files\CrystalDiskMark8\DiskMark64.exe',
                'C:\Program Files\CrystalDiskMark9\DiskMark64.exe',
                'C:\Program Files\CrystalDiskMark\DiskMark64.exe',
                'C:\Program Files (x86)\CrystalDiskMark8\DiskMark64.exe',
                'C:\Program Files (x86)\CrystalDiskMark9\DiskMark64.exe',
                'C:\Program Files (x86)\CrystalDiskMark\DiskMark64.exe',
                '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskmark.exe'
            )
            # Extra verification for Winget source
            if ($cdmSrc -and (Test-Path -LiteralPath $cdmSrc)) {
                $parent = Split-Path -Parent $cdmSrc
                if (Test-Path -LiteralPath (Join-Path $parent "CdmResource")) {
                    $cdm = $cdmSrc
                }
            }
        }
    }

    $hwinfo = $null
    if ($SelMode -eq "3") {
        $hwCandidates = @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe',
            (Join-Path $LegacyAppsDir 'HWiNFO64.exe'),
            (Join-Path $ToolsDir 'HWiNFO64.exe')
        )
        if ($env:ATLAS_OFFLINE_ROOT) {
            $hwCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'apps\HWiNFO64.exe'
            $hwCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\GPUCheck\tools\HWiNFO64.exe'
            $hwCandidates += Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\DiagnosticoMaster\tools\HWiNFO64.exe'
        }
        $hwinfo = Find-FirstExistingPath -Candidates $hwCandidates
        if (-not $hwinfo) {
            $hwSrc = Resolve-DiagDep -WingetId 'REALiX.HWiNFO' -CommandNames @('HWiNFO64.exe') -InstallPaths @(
                'C:\Program Files\HWiNFO64\HWiNFO64.exe',
                'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe',
                '%LOCALAPPDATA%\Microsoft\WinGet\Links\hwinfo64.exe'
            )
            if ($hwSrc) { $hwinfo = $hwSrc }
        }
    }

    return [pscustomobject]@{
        CPUZ = $cpuz
        BlueScreenView = $bsod
        BatteryInfoView = $battery
        CrystalDiskInfo = $cdi
        CrystalDiskMark = $cdm
        HWiNFO = $hwinfo
        ToolsDir = $ToolsDir
        LegacyAppsDir = $LegacyAppsDir
    }
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
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $proc = Get-CimInstance Win32_Processor -ErrorAction Stop
        $csproduct = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
        $ramSticks = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $ramTotal=0; $ramDetalleStr="N/A"
        if ($ramSticks) { $ramTotal=[math]::Round(($ramSticks|Measure-Object Capacity -Sum).Sum/1GB,2); $ramDetalleStr=($ramSticks|ForEach-Object{"$([math]::Round($_.Capacity/1GB,0))GB"}) -join " + " }
        $modeloExacto = if ($csproduct -and $csproduct.Name) { $csproduct.Name } else { "N/A" }
        $txtSys = "Alias: ${aliasPC}`nOS: $($os.Caption) ($($os.OSArchitecture))`n$($L.EquipoLbl): $($cs.Manufacturer) $($cs.Model)`nModel: ${modeloExacto}`nCPU: $($proc.Name)`nRAM Total: ${ramTotal} GB (${ramDetalleStr})`nPowerShell: $($PSVersionTable.PSVersion)"

        $htmlHardware = ""
        if ($selMode -eq "2" -or $selMode -eq "3") {
            Escribir-Centrado $L.FindingCpuz "Magenta"
            $exeCpuz = $null
            if ($diagDeps.CPUZ -and (Test-Path -LiteralPath $diagDeps.CPUZ)) {
                $exeCpuz = Get-Item -LiteralPath $diagDeps.CPUZ -ErrorAction SilentlyContinue
            }
            if (-not $exeCpuz) {
                $cpuzLegacy = Find-ToolFileInRoots -Roots @($appsLegacy) -Names @('cpuz_x64.exe', 'cpuz_x32.exe', 'cpuz.exe')
                if ($cpuzLegacy) { $exeCpuz = Get-Item -LiteralPath $cpuzLegacy -ErrorAction SilentlyContinue }
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
                $tempReportPath = Join-Path $env:TEMP "cpuz_report_$(Get-Date -Format 'HHmmss')"
                $arg = "-txt=${tempReportPath}"
                $cpuzOk = Start-ProcessWithTimeout -FilePath $exeCpuz.FullName -Arguments $arg -TimeoutSeconds 30 -WindowStyle "Normal"
                $reportFile = "${tempReportPath}.txt"
                if ($cpuzOk -and (Test-Path $reportFile)) {
                    try { $lines = Get-Content $reportFile -ErrorAction Stop } catch { $lines = Get-Content $reportFile -Encoding Default }
                    $cleanText=""; $currentSection=""; $startLog=$false; $isStorageSection=$false; $isGraphicsSection=$false
                    $keywords = @("Number of cores","Number of threads","Manufacturer","Name","Codename","Specification","Package","CPUID","Extended CPUID","Technology","Core Speed","Multiplier x Bus Speed","Temperature","Northbridge","Southbridge","Bus Specification","Graphic Interface","PCI-E Link Width","PCI-E Link Speed","Memory Type","Memory Size","Module Size","Size","Channels","Memory Frequency","DIMM #","SMBus address","Module format","Max bandwidth","Part number","Serial number","Manufacturing date","Nominal Voltage","Revision","Capacity","Type","Bus Type","Rotation speed","Features","Controller","Link Speed","Volume","Display adapter","Board Manufacturer","Cores","ROP Units","Memory size","Current Link Width","Current Link Speed")
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
                                if ($isStorageSection -and $line -match "^\s*Name") { $cleanText+="`n$($L.DiskFound)`n" }
                                if ($isGraphicsSection -and $line -match "^\s*Display adapter") { $cleanText+="`n$($L.GfxFound)`n" }
                                if ($key -eq "Temperature" -and $line -match "(\d+)\s*degC") {
                                    $tempVal = [int]$matches[1]
                                    $tempColor = if ($tempVal -ge 85) { "#dc3545" } elseif ($tempVal -ge 70) { "#ff8c00" } else { "#28a745" }
                                    $tempLabel = if ($tempVal -ge 85) { $L.TempCrit } elseif ($tempVal -ge 70) { $L.TempWarm } else { "" }
                                    $cleanText += "<span style='color:${tempColor};font-weight:bold'>${line}${tempLabel}</span>`n"
                                } else {
                                    $cleanText += $line + "`n"
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
            function Fmt-Line ($titulo, $valor) { return "<span class='categoria-resaltada'>${titulo}:</span> ${valor}`n" }
            $inv=""
            $bb=Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue; $bios=Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
            $bbProduct=if($bb -and $bb.Product){$bb.Product}else{"N/A"}; $bbManuf=if($bb -and $bb.Manufacturer){$bb.Manufacturer}else{"N/A"}
            $bbSerial=if($bb -and $bb.SerialNumber){$bb.SerialNumber}else{"N/A"}; $biosSN=if($bios -and $bios.SerialNumber){$bios.SerialNumber}else{"N/A"}
            $biosVer=if($bios -and $bios.SMBIOSBIOSVersion){$bios.SMBIOSBIOSVersion}else{"N/A"}; $biosDate=if($bios -and $bios.ReleaseDate){$bios.ReleaseDate}else{"N/A"}
            $inv += Fmt-Line $L.EquipoLbl "$($cs.Manufacturer) $($cs.Model)"; $inv += Fmt-Line $L.SerialLbl $biosSN
            $inv += Fmt-Line $L.BoardLbl "${bbProduct} (Mfr: ${bbManuf})"; $inv += Fmt-Line $L.BoardSer $bbSerial
            $inv += Fmt-Line $L.BiosLbl "${biosVer} (${biosDate})"; $inv += "`n"
            $inv += Fmt-Line $L.ProcLbl "$($proc.Name)"
            $socket=if($proc.SocketDesignation){$proc.SocketDesignation}else{"N/A"}; $inv += Fmt-Line $L.CpuSocket $socket; $inv += "`n"
            $memS=Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
            if($memS){$mi=1;foreach($m in $memS){$cap=[math]::Round($m.Capacity/1GB,0);$manuf=if($m.Manufacturer){$m.Manufacturer}else{"N/A"};$spd=if($m.Speed){$m.Speed}else{0};$inv+=Fmt-Line ($L.RamDimm -f $mi) "${cap}GB - ${manuf} @ ${spd}MHz";$mi++}};$inv+="`n"
            $dks=Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue|Where-Object{$_.MediaType -ne 'Removable Media'}
            if($dks){foreach($d in $dks){$sz=if($d.Size){[math]::Round($d.Size/1GB,1)}else{0};$dm=if($d.Model){$d.Model}else{"N/A"};$inv+=Fmt-Line $L.DiskLbl "${dm} (${sz} GB)"}}
            $htmlHardware="<h2>$($L.H2HardwareSimple)</h2><pre>${inv}</pre>"
        }

        Escribir-Centrado $L.Step3 "Cyan"
        $cpuInfo = Get-CPUUpgradeInfo
        $htmlCPU = "<h2>$($L.H3Cpu)</h2>" + $cpuInfo.HtmlSection
        $cpuColor = if ($cpuInfo.IsSoldered) { "Red" } else { "Green" }
        Write-Host "    $($cpuInfo.Summary)" -ForegroundColor $cpuColor

        Escribir-Centrado $L.Step4 "Cyan"
        $ramDiag = Get-RAMDiagnostic
        $htmlRAM = "<h2>$($L.H4Ram)</h2>" + $ramDiag.HtmlSection
        $ch = if($ramDiag.IsDualChannel){'Dual'}else{'Single'}
        Write-Host "    Slots: $($ramDiag.SlotsUsed)/$($ramDiag.SlotsTotal) | Total: $($ramDiag.TotalGB)GB | Channel: ${ch}" -ForegroundColor Gray
        if ($ramDiag.SolderedWarning) { Write-Host "    $($ramDiag.SolderedWarning)" -ForegroundColor Yellow }

        Escribir-Centrado $L.Step5 "Cyan"
        $storageData = Get-StorageAnalysis
        $htmlStorage = "<h2>$($L.H5Storage)</h2>" + $storageData.HtmlSection
        foreach ($dk in $storageData.Disks) { Write-Host "    $($dk.Name): $($dk.Class)" -ForegroundColor Gray }

        Escribir-Centrado $L.Step6 "Cyan"
        $netProfile = Get-NetworkProfile
        $htmlNet = "<h2>$($L.H6Net)</h2>" + $netProfile.HtmlSection

        Escribir-Centrado $L.Step7 "Cyan"
        $htmlBsod = "<h2>$($L.H7Bsod)</h2><pre>$($L.BsodNone)</pre>"
        $exeBsod = $diagDeps.BlueScreenView
        if (-not $exeBsod) { $exeBsod = Join-Path $appsLegacy "BlueScreenView.exe" }
        $tmpBsod = Join-Path $env:TEMP "atlas_diag_bsod.txt"
        if (Test-Path $exeBsod) {
            $bsodOk = Start-ProcessWithTimeout -FilePath $exeBsod -Arguments "/stext `"${tmpBsod}`"" -TimeoutSeconds 15
            if ($bsodOk -and (Test-Path $tmpBsod)) { $c=Get-Content $tmpBsod -Raw -ErrorAction SilentlyContinue; if($c -and $c.Length -gt 10){$safeC=[System.Net.WebUtility]::HtmlEncode($c);$htmlBsod="<h2>$($L.H7Bsod)</h2><pre>${safeC}</pre>"}; Remove-Item $tmpBsod -ErrorAction SilentlyContinue }
        }

        Escribir-Centrado $L.Step8 "Cyan"
        $htmlBat=""
        $exeBatView = $diagDeps.BatteryInfoView
        if (-not $exeBatView) { $exeBatView = Join-Path $appsLegacy "BatteryInfoView.exe" }
        $designCap=0;$fullCap=0;$cycleCount=0;$chemistry="N/A";$voltage="N/A";$manufactureName="N/A"
        if (Test-Path $exeBatView) {
            $tmpBatInfo=Join-Path $env:TEMP "atlas_diag_bat_info.txt"
            $batOk=Start-ProcessWithTimeout -FilePath $exeBatView -Arguments "/stext `"${tmpBatInfo}`"" -TimeoutSeconds 15
            if($batOk -and (Test-Path $tmpBatInfo)){try{$linesBat=$null;foreach($enc in @("Unicode","UTF8","Default")){try{$linesBat=Get-Content $tmpBatInfo -Encoding $enc -ErrorAction Stop;if($linesBat -and $linesBat.Count -gt 3){break}}catch{$linesBat=$null}};if($linesBat){foreach($batLine in $linesBat){if($batLine -match "Designed Capacity\s+:\s+([0-9]+)"){$designCap=[int64]$matches[1]};if($batLine -match "Full Charged Capacity\s+:\s+([0-9]+)"){$fullCap=[int64]$matches[1]};if($batLine -match "Number of charge/discharge cycles\s+:\s+([0-9]+)"){$cycleCount=[int]$matches[1]};if($batLine -match "Battery Manufacturer\s+:\s+(.*)"){$manufactureName=$matches[1].Trim()};if($batLine -match "Chemistry\s+:\s+(.*)"){$chemistry=$matches[1].Trim()};if($batLine -match "Voltage\s+:\s+(.*)"){$voltage=$matches[1].Trim()}}}}catch{};Remove-Item $tmpBatInfo -ErrorAction SilentlyContinue}
        }
        if($designCap -eq 0){$tmpBatXML=Join-Path $env:TEMP "atlas_diag_battery_report.xml";Start-ProcessWithTimeout -FilePath "powercfg" -Arguments "/batteryreport /output `"${tmpBatXML}`" /xml" -TimeoutSeconds 15|Out-Null;if(Test-Path $tmpBatXML){try{[xml]$xmlBat=Get-Content $tmpBatXML -ErrorAction Stop;$batInfo=$xmlBat.BatteryReport.Batteries.Battery;if($batInfo){if($batInfo -is [array]){$designCap=0;$fullCap=0;$cycleCount=0;foreach($b in $batInfo){if($b.DesignCapacity){$designCap+=[int64]$b.DesignCapacity};if($b.FullChargeCapacity){$fullCap+=[int64]$b.FullChargeCapacity};if($b.CycleCount){$cycleCount=[math]::Max($cycleCount,[int]$b.CycleCount)}}}else{if($batInfo.DesignCapacity){$designCap=[int64]$batInfo.DesignCapacity};if($batInfo.FullChargeCapacity){$fullCap=[int64]$batInfo.FullChargeCapacity};if($batInfo.CycleCount){$cycleCount=[int]$batInfo.CycleCount}}}}catch{};Remove-Item $tmpBatXML -ErrorAction SilentlyContinue}}
        if($designCap -gt 0){
            $healthPct=($fullCap/$designCap)*100;$saludStr="{0:N1}%" -f $healthPct
            if($healthPct -lt 50){$saludColor="#d9534f"}elseif($healthPct -lt 80){$saludColor="#f0ad4e"}else{$saludColor="#5cb85c"}
            $notaFraude=""
            if($healthPct -ge 98 -and $cycleCount -eq 0){$saludColor="#FF8C00";$saludStr+=" (?)";$notaFraude="<div style='background:#fff3cd;color:#856404;padding:10px;border:1px solid #ffeeba;border-radius:4px;margin-top:10px;font-size:12px'><strong>&#9888; $($L.BatFraud)</strong></div>"}
            $wmiBat=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue;$batStatus=$L.UnknownLbl;$batPercent="0%"
            if($wmiBat){
                $batStatus=switch($wmiBat.BatteryStatus){
                    1{$L.BatStDis}
                    2{$L.BatStCha}
                    3{$L.BatStFull}
                    4{$L.BatStLow}
                    5{$L.BatStCrit}
                    6{$L.BatStCha}
                    7{$L.BatStCha}
                    8{$L.BatStCha}
                    10{$L.BatStCha}
                    default{$L.UnknownLbl}
                }
                $batPercent="$($wmiBat.EstimatedChargeRemaining)%"
            }
            $htmlBat="<h2>$($L.H8Battery)</h2><table class='info-table'><tr><th>$($L.BatStatus)</th><td>${batStatus} (${batPercent})</td></tr><tr><th>$($L.BatHealth)</th><td style='color:${saludColor};font-weight:bold'>${saludStr}</td></tr><tr><th>$($L.BatCycles)</th><td>${cycleCount}</td></tr><tr><th>$($L.BatCap)</th><td>${designCap} / ${fullCap} mWh</td></tr><tr><th>$($L.BatMan)</th><td>${manufactureName} / ${chemistry}</td></tr></table>${notaFraude}"
        } else { $htmlBat="<h2>$($L.H8Battery)</h2><pre>$($L.NoBattery)</pre>" }

        Escribir-Centrado $L.GpuStep "Cyan"
        $gpuTriage = Get-GPUSlownessTriageForReport
        $htmlGpuTriage = "<h2>$($L.H10GpuTriage)</h2>" + $gpuTriage.HtmlSection
        $gpuCol = if ($gpuTriage.Score -ge 70) { 'Red' } elseif ($gpuTriage.Score -ge 40) { 'Yellow' } else { 'Green' }
        Write-Host "    $($L.GpuRiskLine -f $gpuTriage.Verdict, $gpuTriage.Score)" -ForegroundColor $gpuCol

        Escribir-Centrado $L.Step9 "Magenta"
        $upgradeResult = Get-UpgradeAdvisor -RAMData $ramDiag -CPUData $cpuInfo -StorageData $storageData -OSCaption $os.Caption
        $htmlUpgrade = "<h2 style='background:#FF5500'>$($L.H9Upgrade)</h2>" + $upgradeResult.HtmlSection
        $scoreLbl = $upgradeResult.ScoreLabel
        if ($scoreLbl -eq $L.LvlCritical -or $scoreLbl -eq $L.LvlLow) { $scoreCol = 'Red' }
        elseif ($scoreLbl -eq $L.ScoreOk) { $scoreCol = 'Yellow' }
        else { $scoreCol = 'Green' }
        Write-Host ""; Write-Host "    ========================================" -ForegroundColor $scoreCol
        Write-Host "    $($L.ScoreLine -f $upgradeResult.Score, $upgradeResult.ScoreLabel)" -ForegroundColor $scoreCol
        Write-Host "    ========================================" -ForegroundColor $scoreCol
        if ($upgradeResult.Recommendations.Count -gt 0) {
            foreach ($rec in $upgradeResult.Recommendations) {
                if ($rec.Level -eq $L.LvlCritical -or $rec.Level -eq $L.LvlLow) { $rcCol = 'Red' } else { $rcCol = 'Yellow' }
                Write-Host "    [$($rec.Level)] $($rec.Title)" -ForegroundColor $rcCol
            }
        }
        else { Write-Host $L.NoRecs -ForegroundColor Green }

        Escribir-Centrado $L.Step10 "Green"
        $fechaReporte=Get-Date -Format 'dd/MM/yyyy HH:mm'; $yearReporte=Get-Date -Format 'yyyy'
        $reportTitle = $L.HtmlReportTitle -f $aliasPC
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
            <div class="info-item"><strong>$($L.HtmlClient)</strong> ${aliasPC}</div>
            <div class="info-item"><strong>$($L.HtmlEquip)</strong> ${pc}</div>
            <div class="info-item"><strong>$($L.HtmlDate)</strong> ${fechaReporte}</div>
        </div>
        <div class="content-area">
            <h2>$($L.H1Section)</h2><pre>${txtSys}</pre>
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
        $html | Out-File -FilePath $htmlFile -Encoding UTF8
        Write-Host "`n"; Escribir-Centrado ($L.ReadyAt -f $htmlFile) "Green"
        Invoke-Item $dir

        if ($selMode -eq "3") {
            Write-Host "`n"
            Escribir-Centrado $L.OpeningTools "Cyan"
            if ($diagDeps.CPUZ -and (Test-Path -LiteralPath $diagDeps.CPUZ)) {
                $dirCpuZ = Split-Path -Parent $diagDeps.CPUZ
                Start-Process -FilePath $diagDeps.CPUZ -WorkingDirectory $dirCpuZ -ErrorAction SilentlyContinue
            }
            if ($diagDeps.HWiNFO -and (Test-Path -LiteralPath $diagDeps.HWiNFO)) {
                $dirHw = Split-Path -Parent $diagDeps.HWiNFO
                Start-Process -FilePath $diagDeps.HWiNFO -WorkingDirectory $dirHw -ErrorAction SilentlyContinue
            }
            if ($diagDeps.CrystalDiskInfo -and (Test-Path -LiteralPath $diagDeps.CrystalDiskInfo)) {
                $dirCdi = Split-Path -Parent $diagDeps.CrystalDiskInfo
                Start-Process -FilePath $diagDeps.CrystalDiskInfo -WorkingDirectory $dirCdi -ErrorAction SilentlyContinue
            }
            if ($diagDeps.CrystalDiskMark -and (Test-Path -LiteralPath $diagDeps.CrystalDiskMark)) {
                $dirCdm = Split-Path -Parent $diagDeps.CrystalDiskMark
                Escribir-Centrado $L.CdmHint "Yellow"
                Start-Process -FilePath $diagDeps.CrystalDiskMark -WorkingDirectory $dirCdm -ErrorAction SilentlyContinue
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
