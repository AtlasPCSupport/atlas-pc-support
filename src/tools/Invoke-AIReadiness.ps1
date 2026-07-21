function Invoke-AIReadiness {
    <#
    .SYNOPSIS
      AI Readiness Assessment: self-contained local/cloud AI readiness audit.

    .DESCRIPTION
      Scores RAM, CPU, GPU/VRAM, storage and AI connectivity without external
      scripts. Exports per-client HTML/JSON reports with Ollama model guidance.
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
            Title='ATLAS PC SUPPORT - AI Readiness Assessment'
            Subtitle='Local/cloud AI readiness audit'
            AskClient='Client name'
            AskConsult='Consultant name'
            DefaultClient='Demo Client'
            DefaultConsult='Atlas PC Support'
            Running='Running self-contained audit. This may take 20-40 seconds...'
            Done='Report saved'
            ReportOpened='Report opened in browser.'
            OpenFail='Report saved, but it could not be opened automatically.'
            PressKey='Press any key to exit...'
            Computer='Computer'
            OS='Operating system'
            Manufacturer='Manufacturer'
            Model='Model'
            Generated='Generated'
            Consultant='Consultant'
            Client='Client'
            Score='AI readiness score'
            Verdict='Verdict'
            Mode='Recommended AI mode'
            Ready='READY'
            Limited='LIMITED'
            NotReady='NOT READY'
            ModeGpu='Local GPU models'
            ModeCpu='CPU GGUF / small local models'
            ModeCloud='Cloud AI first'
            ModeNone='Not recommended without upgrades'
            Summary='Summary'
            Hardware='Hardware'
            Cpu='CPU'
            Ram='RAM'
            Gpu='GPU'
            Disk='Storage'
            Stack='AI stack / connectivity'
            Findings='Findings'
            Recommendations='Recommendations'
            Models='Suggested Ollama models'
            Connectivity='Connectivity'
            Delta='Previous scan delta'
            NoData='No data.'
            Installed='Installed'
            NotInstalled='Not installed'
            Reachable='Reachable'
            NotReachable='Not reachable'
            FindingOk='No major AI-readiness blocker found.'
            RecOk='Machine is reasonable for the recommended AI mode. Still validate real workload expectations with the customer.'
            LowRam='RAM below 16 GB limits local AI.'
            RecLowRam='For useful local AI, prefer 16 GB minimum; 32 GB is a better target.'
            LowCpu='CPU thread count is modest for CPU-only inference.'
            RecLowCpu='Use smaller models, cloud AI, or explain slower responses to the customer.'
            LowGpu='No strong local-AI GPU/VRAM capacity detected.'
            RecLowGpu='Use CPU GGUF models or cloud AI. Do not promise fast local AI without a suitable GPU.'
            BasicGpu='Microsoft Basic Display driver detected.'
            RecBasicGpu='Install the vendor GPU driver before judging AI or graphics performance.'
            HddOnly='No SSD/NVMe storage was detected.'
            RecHddOnly='Move to SSD/NVMe before promising acceptable AI or general performance.'
            DiskHealth='Disk health is not reported as healthy.'
            RecDiskHealth='Back up data and validate storage before AI setup or performance promises.'
            NoOllama='Ollama was not found.'
            RecNoOllama='Install Ollama if local model execution is desired: https://ollama.com/download'
            NoNet='AI/cloud endpoints were not reachable in this quick check.'
            RecNoNet='Verify internet, DNS, firewall or captive portal before configuring cloud AI tools.'
            TempHigh='GPU temperature reported high by nvidia-smi.'
            RecTempHigh='Check cooling before running local GPU workloads.'
            DriverOld='GPU driver appears old.'
            RecDriverOld='Update the GPU driver before judging AI compatibility.'
            ReportTitle='ATLAS PC SUPPORT - AI Readiness Report'
            ScoreChange='Score change'
            PreviousScore='Previous score'
            PreviousDate='Previous scan'
        }
        es = @{
            Title='ATLAS PC SUPPORT - Auditoria de Aptitud para IA'
            Subtitle='Auditoria local/nube para IA'
            AskClient='Nombre del cliente'
            AskConsult='Nombre consultora'
            DefaultClient='Cliente Demo'
            DefaultConsult='Atlas PC Support'
            Running='Ejecutando auditoria autocontenida. Puede tardar 20-40 segundos...'
            Done='Reporte guardado'
            ReportOpened='Reporte abierto en el navegador.'
            OpenFail='Reporte guardado, pero no se pudo abrir automaticamente.'
            PressKey='Presiona cualquier tecla para salir...'
            Computer='Equipo'
            OS='Sistema operativo'
            Manufacturer='Fabricante'
            Model='Modelo'
            Generated='Generado'
            Consultant='Consultora'
            Client='Cliente'
            Score='Puntuacion de aptitud IA'
            Verdict='Veredicto'
            Mode='Modo IA recomendado'
            Ready='APTO'
            Limited='LIMITADO'
            NotReady='NO APTO'
            ModeGpu='Modelos locales con GPU'
            ModeCpu='GGUF por CPU / modelos locales pequenos'
            ModeCloud='Priorizar IA en la nube'
            ModeNone='No recomendado sin mejoras'
            Summary='Resumen'
            Hardware='Hardware'
            Cpu='CPU'
            Ram='RAM'
            Gpu='GPU'
            Disk='Almacenamiento'
            Stack='Stack IA / conectividad'
            Findings='Hallazgos'
            Recommendations='Recomendaciones'
            Models='Modelos Ollama sugeridos'
            Connectivity='Conectividad'
            Delta='Cambio desde escaneo previo'
            NoData='Sin datos.'
            Installed='Instalado'
            NotInstalled='No instalado'
            Reachable='Alcanzable'
            NotReachable='No alcanzable'
            FindingOk='No se encontro un bloqueo fuerte para aptitud IA.'
            RecOk='El equipo es razonable para el modo IA recomendado. Aun asi, valida expectativas reales con el cliente.'
            LowRam='RAM inferior a 16 GB limita la IA local.'
            RecLowRam='Para IA local util, preferir minimo 16 GB; 32 GB es mejor objetivo.'
            LowCpu='La CPU tiene pocos hilos para inferencia solo por CPU.'
            RecLowCpu='Usar modelos pequenos, IA en la nube, o explicar respuestas mas lentas al cliente.'
            LowGpu='No se detecto GPU/VRAM fuerte para IA local.'
            RecLowGpu='Usar modelos GGUF por CPU o IA en nube. No prometas IA local rapida sin GPU adecuada.'
            BasicGpu='Se detecto Microsoft Basic Display driver.'
            RecBasicGpu='Instalar driver GPU del fabricante antes de juzgar rendimiento IA/grafico.'
            HddOnly='No se detecto SSD/NVMe.'
            RecHddOnly='Migrar a SSD/NVMe antes de prometer buen rendimiento IA o general.'
            DiskHealth='La salud del disco no aparece como correcta.'
            RecDiskHealth='Respaldar datos y validar almacenamiento antes de configurar IA o prometer rendimiento.'
            NoOllama='No se encontro Ollama.'
            RecNoOllama='Instalar Ollama si se desea ejecutar modelos locales: https://ollama.com/download'
            NoNet='No se pudieron alcanzar endpoints IA/nube en esta revision rapida.'
            RecNoNet='Verificar internet, DNS, firewall o portal cautivo antes de configurar IA en nube.'
            TempHigh='nvidia-smi reporta temperatura GPU alta.'
            RecTempHigh='Revisar refrigeracion antes de usar cargas IA por GPU.'
            DriverOld='El driver GPU parece antiguo.'
            RecDriverOld='Actualizar driver GPU antes de juzgar compatibilidad IA.'
            ReportTitle='ATLAS PC SUPPORT - Reporte de Aptitud IA'
            ScoreChange='Cambio de puntuacion'
            PreviousScore='Puntuacion previa'
            PreviousDate='Escaneo previo'
        }
    }

    $lang = _Atlas-DetectLang
    $L = if ($T.ContainsKey($lang)) { $T[$lang] } else { $T['en'] }
    $esc = [char]0x1B
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    function Write-AIRHeader {
        Clear-Host
        if ($atlasToolkitReady) {
            Write-Host ''
            Write-AtlasHeader -Title $L.Title -Color Yellow
            Write-AtlasStep $L.Subtitle
            Write-Host ("  " + ('=' * 72)) -ForegroundColor DarkGray
            Write-Host ''
            return
        }
        Write-Host ''
        Write-Host "  $esc[38;5;208m$($L.Title)$esc[0m"
        Write-Host "  $esc[90m$($L.Subtitle)$esc[0m"
        Write-Host "  $esc[90m$('=' * 72)$esc[0m"
        Write-Host ''
    }

    function ConvertTo-AIRHtml {
        param([object]$Value)
        return [System.Net.WebUtility]::HtmlEncode([string]$Value)
    }

    function Pause-AIR {
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $L.PressKey
            return
        }
        Write-Host ''
        Write-Host "  $($L.PressKey)"
        try {
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        } catch {
            try { [void](Read-Host) } catch {}
        }
    }

    function Format-AIRGB {
        param([object]$Bytes)
        try {
            if (-not $Bytes) { return 0 }
            return [math]::Round(([double]$Bytes / 1GB), 1)
        } catch {
            return 0
        }
    }

    function ConvertFrom-AIRWmiDate {
        param([object]$Value)
        if (-not $Value) { return '' }
        if ($Value -is [datetime]) { return $Value.ToString('yyyy-MM-dd') }
        try { return ([System.Management.ManagementDateTimeConverter]::ToDateTime([string]$Value)).ToString('yyyy-MM-dd') } catch {}
        return [string]$Value
    }

    function Get-AIRCim {
        param(
            [Parameter(Mandatory)] [string]$ClassName,
            [string]$Namespace = 'root\cimv2',
            [string]$Filter = ''
        )
        try {
            if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
                $args = @{ ClassName = $ClassName; Namespace = $Namespace; ErrorAction = 'Stop' }
                if ($Filter) { $args.Filter = $Filter }
                return @(Get-CimInstance @args)
            }
            $args = @{ Class = $ClassName; Namespace = $Namespace; ErrorAction = 'Stop' }
            if ($Filter) { $args.Filter = $Filter }
            return @(Get-WmiObject @args)
        } catch {
            return @()
        }
    }

    function Get-AIRCommandState {
        param([string]$Name)
        $cmd = Get-Command $Name -ErrorAction SilentlyContinue
        if ($cmd) {
            $path = if ($cmd.Source) { $cmd.Source } else { $cmd.Path }
            return [pscustomobject]@{ Name=$Name; Installed=$true; Path=$path }
        }
        return [pscustomobject]@{ Name=$Name; Installed=$false; Path='' }
    }

    function Test-AIREndpoint {
        param([string]$Name, [string]$Url)
        $reachable = $false
        $status = ''
        try {
            $ProgressPreference = 'SilentlyContinue'
            $resp = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
            $reachable = $true
            $status = [string]$resp.StatusCode
        } catch {
            try {
                if ($_.Exception.Response) {
                    $code = [int]$_.Exception.Response.StatusCode
                    $status = [string]$code
                    if ($code -eq 401 -or $code -eq 403 -or $code -eq 405) { $reachable = $true }
                } else {
                    $status = $_.Exception.Message
                }
            } catch {
                $status = $_.Exception.Message
            }
        }
        return [pscustomobject]@{ Name=$Name; Url=$Url; Reachable=$reachable; Status=$status }
    }

    function Invoke-AIRCpuBenchmark {
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $ops = 0
            while ($sw.ElapsedMilliseconds -lt 700) {
                for ($i = 1; $i -le 3000; $i++) {
                    $null = [math]::Sqrt(($i * 13.37) % 997)
                }
                $ops += 3000
            }
            $sw.Stop()
            return [math]::Round(($ops / [math]::Max($sw.Elapsed.TotalSeconds, 0.1)) / 1000000, 2)
        } catch {
            return 0
        }
    }

    function Get-AIRDiskInfo {
        $rows = @()
        try {
            $physical = @(Get-PhysicalDisk -ErrorAction Stop)
            foreach ($d in $physical) {
                $rows += [pscustomobject]@{
                    Name=[string]$d.FriendlyName
                    MediaType=[string]$d.MediaType
                    BusType=[string]$d.BusType
                    SizeGB=(Format-AIRGB $d.Size)
                    Health=[string]$d.HealthStatus
                }
            }
        } catch {}

        if (-not $rows -or $rows.Count -eq 0) {
            $disks = Get-AIRCim -ClassName 'Win32_DiskDrive'
            foreach ($d in $disks) {
                $model = [string]$d.Model
                $media = [string]$d.MediaType
                if ($model -match '(?i)nvme') { $media = 'SSD' }
                elseif ($model -match '(?i)\bssd\b|solid') { $media = 'SSD' }
                elseif ($media -match '(?i)fixed hard disk') { $media = 'HDD' }
                $rows += [pscustomobject]@{
                    Name=$model
                    MediaType=$media
                    BusType=[string]$d.InterfaceType
                    SizeGB=(Format-AIRGB $d.Size)
                    Health=[string]$d.Status
                }
            }
        }
        return @($rows)
    }

    function Get-AIRNvidiaSmi {
        $cmd = Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue
        if (-not $cmd) { $cmd = Get-Command 'nvidia-smi' -ErrorAction SilentlyContinue }
        if (-not $cmd) { return $null }
        try {
            $out = & $cmd.Source '--query-gpu=name,memory.total,temperature.gpu,driver_version' '--format=csv,noheader,nounits' 2>$null
            if (-not $out) { return $null }
            $rows = @()
            foreach ($line in @($out)) {
                $parts = @($line -split ',\s*')
                if ($parts.Count -ge 4) {
                    $rows += [pscustomobject]@{
                        Name=$parts[0]
                        MemoryMB=[int]($parts[1] -replace '[^\d]', '')
                        TemperatureC=[int]($parts[2] -replace '[^\d]', '')
                        DriverVersion=$parts[3]
                    }
                }
            }
            return @($rows)
        } catch {
            return $null
        }
    }

    function Get-AIRModelRecommendations {
        param([double]$RamGB, [double]$VramGB)
        $models = @()
        if ($RamGB -ge 8) {
            $models += [pscustomobject]@{ Profile='Very small / CPU'; Model='llama3.2:1b'; Command='ollama pull llama3.2:1b'; Notes='Good first test on low-end PCs.' }
            $models += [pscustomobject]@{ Profile='Very small / CPU'; Model='qwen2.5:1.5b'; Command='ollama pull qwen2.5:1.5b'; Notes='Light chat/coding test.' }
        }
        if ($RamGB -ge 16) {
            $models += [pscustomobject]@{ Profile='Small / CPU'; Model='llama3.2:3b'; Command='ollama pull llama3.2:3b'; Notes='Practical baseline for 16 GB RAM.' }
            $models += [pscustomobject]@{ Profile='Small / CPU'; Model='qwen2.5:3b'; Command='ollama pull qwen2.5:3b'; Notes='Balanced small assistant.' }
            $models += [pscustomobject]@{ Profile='Small / CPU'; Model='phi3:mini'; Command='ollama pull phi3:mini'; Notes='Compact general model.' }
        }
        if ($RamGB -ge 32 -or $VramGB -ge 6) {
            $models += [pscustomobject]@{ Profile='7B class'; Model='mistral:7b'; Command='ollama pull mistral:7b'; Notes='Use SSD and expect slower CPU-only responses.' }
            $models += [pscustomobject]@{ Profile='7B class'; Model='qwen2.5:7b'; Command='ollama pull qwen2.5:7b'; Notes='Better with 8 GB+ VRAM or 32 GB RAM.' }
            $models += [pscustomobject]@{ Profile='7B/8B class'; Model='llama3.1:8b'; Command='ollama pull llama3.1:8b'; Notes='Good GPU/local AI benchmark.' }
        }
        if ($VramGB -ge 8 -or $RamGB -ge 32) {
            $models += [pscustomobject]@{ Profile='Coding'; Model='qwen2.5-coder:7b'; Command='ollama pull qwen2.5-coder:7b'; Notes='Coding-focused model.' }
            $models += [pscustomobject]@{ Profile='Reasoning'; Model='deepseek-r1:8b'; Command='ollama pull deepseek-r1:8b'; Notes='Reasoning test; responses may be slower.' }
        }
        if ($VramGB -ge 12 -or $RamGB -ge 64) {
            $models += [pscustomobject]@{ Profile='Larger local'; Model='qwen2.5-coder:14b'; Command='ollama pull qwen2.5-coder:14b'; Notes='Requires stronger GPU or high RAM CPU mode.' }
        }
        return @($models)
    }

    function New-AIRTable {
        param([array]$Rows, [string[]]$Columns)
        if (-not $Rows -or $Rows.Count -eq 0) { return "<p class='muted'>$($L.NoData)</p>" }
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('<table><thead><tr>')
        foreach ($c in $Columns) { [void]$sb.AppendLine("<th>$(ConvertTo-AIRHtml $c)</th>") }
        [void]$sb.AppendLine('</tr></thead><tbody>')
        foreach ($row in $Rows) {
            [void]$sb.AppendLine('<tr>')
            foreach ($c in $Columns) {
                $value = ''
                try { $value = $row.$c } catch {}
                [void]$sb.AppendLine("<td>$(ConvertTo-AIRHtml $value)</td>")
            }
            [void]$sb.AppendLine('</tr>')
        }
        [void]$sb.AppendLine('</tbody></table>')
        return $sb.ToString()
    }

    function New-AIRReport {
        param([string]$ClientName, [string]$ConsultantName)

        $generated = Get-Date
        $os = @(Get-AIRCim -ClassName 'Win32_OperatingSystem' | Select-Object -First 1)
        $cs = @(Get-AIRCim -ClassName 'Win32_ComputerSystem' | Select-Object -First 1)
        $cpu = @(Get-AIRCim -ClassName 'Win32_Processor' | Select-Object -First 1)
        $gpuRows = @(Get-AIRCim -ClassName 'Win32_VideoController' | ForEach-Object {
            [pscustomobject]@{
                Name=[string]$_.Name
                Processor=[string]$_.VideoProcessor
                VRAMGB=(Format-AIRGB $_.AdapterRAM)
                DriverVersion=[string]$_.DriverVersion
                DriverDate=(ConvertFrom-AIRWmiDate $_.DriverDate)
                Status=[string]$_.Status
            }
        })
        $nvidia = @(Get-AIRNvidiaSmi)
        if ($nvidia -and $nvidia.Count -gt 0) {
            foreach ($n in $nvidia) {
                $match = $gpuRows | Where-Object { $_.Name -like "*$($n.Name)*" } | Select-Object -First 1
                if ($match) {
                    $match.VRAMGB = [math]::Round($n.MemoryMB / 1024, 1)
                    $match.DriverVersion = $n.DriverVersion
                } else {
                    $gpuRows += [pscustomobject]@{
                        Name=$n.Name
                        Processor='NVIDIA'
                        VRAMGB=([math]::Round($n.MemoryMB / 1024, 1))
                        DriverVersion=$n.DriverVersion
                        DriverDate=''
                        Status='OK'
                    }
                }
            }
        }

        $diskRows = @(Get-AIRDiskInfo)
        $ramGb = if ($cs) { Format-AIRGB $cs.TotalPhysicalMemory } else { 0 }
        $logical = if ($cpu -and $cpu.NumberOfLogicalProcessors) { [int]$cpu.NumberOfLogicalProcessors } else { 0 }
        $cores = if ($cpu -and $cpu.NumberOfCores) { [int]$cpu.NumberOfCores } else { 0 }
        $cpuName = if ($cpu) { [string]$cpu.Name } else { '' }
        $cpuBench = Invoke-AIRCpuBenchmark
        $maxVram = 0
        foreach ($g in $gpuRows) {
            if ([double]$g.VRAMGB -gt $maxVram) { $maxVram = [double]$g.VRAMGB }
        }
        $hasBasicGpu = @($gpuRows | Where-Object { $_.Name -match '(?i)basic display|microsoft basic' }).Count -gt 0
        $hasSsd = @($diskRows | Where-Object { $_.MediaType -match '(?i)ssd|nvme' -or $_.BusType -match '(?i)nvme' }).Count -gt 0
        $hasHddOnly = ($diskRows.Count -gt 0 -and -not $hasSsd)
        $badDisk = @($diskRows | Where-Object { $_.Health -and $_.Health -notmatch '(?i)^ok$|healthy|unknown' }).Count -gt 0

        $ollama = Get-AIRCommandState 'ollama'
        $python = Get-AIRCommandState 'python'
        $winget = Get-AIRCommandState 'winget'
        $connectivity = @(
            (Test-AIREndpoint -Name 'Ollama.com' -Url 'https://ollama.com'),
            (Test-AIREndpoint -Name 'Hugging Face' -Url 'https://huggingface.co'),
            (Test-AIREndpoint -Name 'OpenAI API' -Url 'https://api.openai.com/v1/models')
        )
        $reachableCount = @($connectivity | Where-Object { $_.Reachable }).Count

        $ramScore = if ($ramGb -ge 64) { 25 } elseif ($ramGb -ge 32) { 22 } elseif ($ramGb -ge 16) { 17 } elseif ($ramGb -ge 8) { 10 } elseif ($ramGb -ge 4) { 4 } else { 0 }
        $cpuScore = if ($logical -ge 16) { 20 } elseif ($logical -ge 12) { 17 } elseif ($logical -ge 8) { 14 } elseif ($logical -ge 4) { 9 } elseif ($logical -gt 0) { 5 } else { 0 }
        if ($cpuBench -ge 4 -and $cpuScore -lt 20) { $cpuScore += 1 }
        $gpuScore = if ($maxVram -ge 16) { 25 } elseif ($maxVram -ge 12) { 22 } elseif ($maxVram -ge 8) { 19 } elseif ($maxVram -ge 6) { 15 } elseif ($maxVram -ge 4) { 11 } elseif ($maxVram -ge 2) { 6 } elseif ($maxVram -gt 0) { 3 } else { 0 }
        if ($hasBasicGpu -and $gpuScore -gt 2) { $gpuScore = 2 }
        $diskScore = if ($hasSsd) { 15 } elseif ($diskRows.Count -gt 0) { 4 } else { 8 }
        if ($badDisk -and $diskScore -gt 5) { $diskScore = 5 }
        $stackScore = 0
        if ($ollama.Installed) { $stackScore += 5 }
        $stackScore += [math]::Min(10, ($reachableCount * 4))
        if ($stackScore -gt 15) { $stackScore = 15 }
        $score = [math]::Min(100, [int]($ramScore + $cpuScore + $gpuScore + $diskScore + $stackScore))

        $verdict = if ($score -ge 75) { $L.Ready } elseif ($score -ge 50) { $L.Limited } else { $L.NotReady }
        $mode = if ($maxVram -ge 8 -and $score -ge 65) { $L.ModeGpu } elseif ($ramGb -ge 16 -and $hasSsd) { $L.ModeCpu } elseif ($reachableCount -ge 2) { $L.ModeCloud } else { $L.ModeNone }

        $findings = @()
        $recommendations = @()
        if ($ramGb -lt 16) { $findings += $L.LowRam; $recommendations += $L.RecLowRam }
        if ($logical -lt 8) { $findings += $L.LowCpu; $recommendations += $L.RecLowCpu }
        if ($maxVram -lt 6) { $findings += $L.LowGpu; $recommendations += $L.RecLowGpu }
        if ($hasBasicGpu) { $findings += $L.BasicGpu; $recommendations += $L.RecBasicGpu }
        if ($hasHddOnly) { $findings += $L.HddOnly; $recommendations += $L.RecHddOnly }
        if ($badDisk) { $findings += $L.DiskHealth; $recommendations += $L.RecDiskHealth }
        if (-not $ollama.Installed) { $findings += $L.NoOllama; $recommendations += $L.RecNoOllama }
        if ($reachableCount -eq 0) { $findings += $L.NoNet; $recommendations += $L.RecNoNet }
        foreach ($n in $nvidia) {
            if ($n.TemperatureC -ge 85) { $findings += "$($L.TempHigh) ($($n.Name): $($n.TemperatureC) C)"; $recommendations += $L.RecTempHigh }
        }
        foreach ($g in $gpuRows) {
            try {
                if ($g.DriverDate) {
                    $driverDate = [datetime]::Parse($g.DriverDate)
                    if ($driverDate -lt (Get-Date).AddYears(-4)) {
                        $findings += "$($L.DriverOld) ($($g.Name): $($g.DriverDate))"
                        $recommendations += $L.RecDriverOld
                    }
                }
            } catch {}
        }
        if ($findings.Count -eq 0) { $findings += $L.FindingOk; $recommendations += $L.RecOk }
        $recommendations = @($recommendations | Select-Object -Unique)

        $models = @(Get-AIRModelRecommendations -RamGB $ramGb -VramGB $maxVram)
        $stackRows = @(
            [pscustomobject]@{ Component='Ollama'; State=($(if ($ollama.Installed) { $L.Installed } else { $L.NotInstalled })); Detail=$ollama.Path },
            [pscustomobject]@{ Component='Python'; State=($(if ($python.Installed) { $L.Installed } else { $L.NotInstalled })); Detail=$python.Path },
            [pscustomobject]@{ Component='winget'; State=($(if ($winget.Installed) { $L.Installed } else { $L.NotInstalled })); Detail=$winget.Path }
        )

        return [ordered]@{
            ClientName=$ClientName
            ConsultantName=$ConsultantName
            Generated=$generated.ToString('yyyy-MM-dd HH:mm:ss')
            Language=$lang
            ComputerName=$env:COMPUTERNAME
            OS=if ($os) { "$($os.Caption) $($os.OSArchitecture)" } else { '' }
            Manufacturer=if ($cs) { [string]$cs.Manufacturer } else { '' }
            Model=if ($cs) { [string]$cs.Model } else { '' }
            Score=$score
            Verdict=$verdict
            RecommendedMode=$mode
            Scores=[ordered]@{ RAM=$ramScore; CPU=$cpuScore; GPU=$gpuScore; Storage=$diskScore; Stack=$stackScore }
            CPU=[ordered]@{ Name=$cpuName; Cores=$cores; LogicalProcessors=$logical; MaxClockMHz=if ($cpu) { [int]$cpu.MaxClockSpeed } else { 0 }; BenchmarkMOps=$cpuBench }
            RAM=[ordered]@{ TotalGB=$ramGb }
            GPU=@($gpuRows)
            NvidiaSmi=@($nvidia)
            Disks=@($diskRows)
            Stack=@($stackRows)
            Connectivity=@($connectivity)
            Findings=@($findings)
            Recommendations=@($recommendations)
            ModelRecommendations=@($models)
        }
    }

    function Export-AIRReport {
        param([object]$Report)
        $desktop = [Environment]::GetFolderPath('Desktop')
        if (-not $desktop -or -not (Test-Path -LiteralPath $desktop)) { $desktop = $PWD.Path }
        $root = Join-Path $desktop 'REPORTES_PC'
        $root = Join-Path $root 'AIReadiness'
        $safeClient = ($Report.ClientName -replace '[\\/:*?"<>|]', '_').Trim()
        if ([string]::IsNullOrWhiteSpace($safeClient)) { $safeClient = 'SinNombre' }
        $dir = Join-Path $root $safeClient
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $htmlPath = Join-Path $dir 'report.html'
        $jsonPath = Join-Path $dir 'report.json'
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $htmlCopyPath = Join-Path $dir "report-$stamp.html"

        $previous = $null
        if (Test-Path -LiteralPath $jsonPath) {
            try { $previous = Get-Content -Raw -LiteralPath $jsonPath -Encoding UTF8 | ConvertFrom-Json } catch {}
        }
        $delta = [ordered]@{ HasPrevious=$false; PreviousScore=''; ScoreChange=''; PreviousGenerated='' }
        if ($previous) {
            $delta.HasPrevious = $true
            $delta.PreviousScore = [string]$previous.Score
            try { $delta.ScoreChange = [string]([int]$Report.Score - [int]$previous.Score) } catch { $delta.ScoreChange = '' }
            $delta.PreviousGenerated = [string]$previous.Generated
        }
        $Report.Delta = $delta

        $Report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

        $componentRows = @(
            [pscustomobject]@{ Component=$L.Ram; Value=("{0} GB" -f $Report.RAM.TotalGB); Score=$Report.Scores.RAM },
            [pscustomobject]@{ Component=$L.Cpu; Value=("{0} ({1}C/{2}T, {3} MOps)" -f $Report.CPU.Name, $Report.CPU.Cores, $Report.CPU.LogicalProcessors, $Report.CPU.BenchmarkMOps); Score=$Report.Scores.CPU },
            [pscustomobject]@{ Component=$L.Gpu; Value=(($Report.GPU | ForEach-Object { "{0} ({1} GB VRAM)" -f $_.Name, $_.VRAMGB }) -join '; '); Score=$Report.Scores.GPU },
            [pscustomobject]@{ Component=$L.Disk; Value=(($Report.Disks | ForEach-Object { "{0} {1} {2}GB health={3}" -f $_.BusType, $_.MediaType, $_.SizeGB, $_.Health }) -join '; '); Score=$Report.Scores.Storage },
            [pscustomobject]@{ Component=$L.Stack; Value=(($Report.Stack | ForEach-Object { "{0}: {1}" -f $_.Component, $_.State }) -join '; '); Score=$Report.Scores.Stack }
        )
        $connRows = @($Report.Connectivity | ForEach-Object {
            [pscustomobject]@{ Name=$_.Name; State=($(if ($_.Reachable) { $L.Reachable } else { $L.NotReachable })); Status=$_.Status; Url=$_.Url }
        })
        $findingRows = @($Report.Findings | ForEach-Object { [pscustomobject]@{ Finding=$_ } })
        $recRows = @($Report.Recommendations | ForEach-Object { [pscustomobject]@{ Recommendation=$_ } })
        $deltaRows = @([pscustomobject]@{ Item=$L.PreviousDate; Value=$Report.Delta.PreviousGenerated }, [pscustomobject]@{ Item=$L.PreviousScore; Value=$Report.Delta.PreviousScore }, [pscustomobject]@{ Item=$L.ScoreChange; Value=$Report.Delta.ScoreChange })

        $css = @'
body{font-family:Segoe UI,Arial,sans-serif;background:#f4f7fb;color:#162033;margin:0;padding:24px}
.wrap{max-width:1120px;margin:auto;background:#fff;border:1px solid #d8e0ec;border-radius:16px;box-shadow:0 8px 30px rgba(15,23,42,.08);overflow:hidden}
header{background:#172554;color:#fff;padding:24px 28px;border-bottom:5px solid #ff5500}
h1{margin:0;font-size:25px} h2{margin-top:28px;color:#172554;border-bottom:2px solid #dbeafe;padding-bottom:6px}
.content{padding:24px 28px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px}
.card{background:#f8fafc;border:1px solid #e2e8f0;border-left:4px solid #ff5500;border-radius:10px;padding:14px}.card strong{color:#172554}
.score{font-size:42px;font-weight:800}.badge{display:inline-block;border-radius:999px;padding:8px 14px;font-weight:700;background:#e0f2fe;color:#075985}
.ready{background:#dcfce7;color:#166534}.limited{background:#fef3c7;color:#92400e}.notready{background:#fee2e2;color:#991b1b}
table{width:100%;border-collapse:collapse;margin:12px 0 18px}th{background:#dbeafe;color:#172554;text-align:left}th,td{border:1px solid #d8e0ec;padding:8px;vertical-align:top}.muted{color:#64748b}
tr:nth-child(even){background:#f8fafc}
'@
        $badgeClass = if ($Report.Score -ge 75) { 'ready' } elseif ($Report.Score -ge 50) { 'limited' } else { 'notready' }
        $componentHtml = New-AIRTable -Rows $componentRows -Columns @('Component','Value','Score')
        $gpuHtml = New-AIRTable -Rows $Report.GPU -Columns @('Name','Processor','VRAMGB','DriverVersion','DriverDate','Status')
        $diskHtml = New-AIRTable -Rows $Report.Disks -Columns @('Name','MediaType','BusType','SizeGB','Health')
        $stackHtml = New-AIRTable -Rows $Report.Stack -Columns @('Component','State','Detail')
        $connHtml = New-AIRTable -Rows $connRows -Columns @('Name','State','Status','Url')
        $findHtml = New-AIRTable -Rows $findingRows -Columns @('Finding')
        $recHtml = New-AIRTable -Rows $recRows -Columns @('Recommendation')
        $modelsHtml = New-AIRTable -Rows $Report.ModelRecommendations -Columns @('Profile','Model','Command','Notes')
        $deltaHtml = if ($Report.Delta.HasPrevious) { New-AIRTable -Rows $deltaRows -Columns @('Item','Value') } else { "<p class='muted'>$($L.NoData)</p>" }

        $html = @"
<!DOCTYPE html>
<html lang="$lang">
<head><meta charset="UTF-8"><title>$($L.ReportTitle)</title><style>$css</style></head>
<body><div class="wrap">
<header><h1>$($L.ReportTitle)</h1><p>ATLAS PC SUPPORT</p></header>
<div class="content">
<div class="grid">
<div class="card"><strong>$($L.Score)</strong><div class="score">$($Report.Score)/100</div></div>
<div class="card"><strong>$($L.Verdict)</strong><br><span class="badge $badgeClass">$(ConvertTo-AIRHtml $Report.Verdict)</span></div>
<div class="card"><strong>$($L.Mode)</strong><br>$(ConvertTo-AIRHtml $Report.RecommendedMode)</div>
<div class="card"><strong>$($L.Client)</strong><br>$(ConvertTo-AIRHtml $Report.ClientName)<br><strong>$($L.Consultant)</strong><br>$(ConvertTo-AIRHtml $Report.ConsultantName)</div>
<div class="card"><strong>$($L.Computer)</strong><br>$(ConvertTo-AIRHtml $Report.ComputerName)<br>$(ConvertTo-AIRHtml $Report.Manufacturer) $(ConvertTo-AIRHtml $Report.Model)</div>
<div class="card"><strong>$($L.OS)</strong><br>$(ConvertTo-AIRHtml $Report.OS)<br><strong>$($L.Generated)</strong><br>$($Report.Generated)</div>
</div>
<h2>$($L.Summary)</h2>$componentHtml
<h2>$($L.Findings)</h2>$findHtml
<h2>$($L.Recommendations)</h2>$recHtml
<h2>$($L.Gpu)</h2>$gpuHtml
<h2>$($L.Disk)</h2>$diskHtml
<h2>$($L.Stack)</h2>$stackHtml
<h2>$($L.Connectivity)</h2>$connHtml
<h2>$($L.Models)</h2>$modelsHtml
<h2>$($L.Delta)</h2>$deltaHtml
</div></div></body></html>
"@

        $html | Set-Content -LiteralPath $htmlPath -Encoding UTF8
        $html | Set-Content -LiteralPath $htmlCopyPath -Encoding UTF8
        return [pscustomobject]@{ Html=$htmlPath; Json=$jsonPath; HtmlCopy=$htmlCopyPath }
    }

    Write-AIRHeader
    $clientName = Read-Host "  $($L.AskClient)"
    if ([string]::IsNullOrWhiteSpace($clientName)) { $clientName = $L.DefaultClient }
    $consultName = Read-Host "  $($L.AskConsult)"
    if ([string]::IsNullOrWhiteSpace($consultName)) { $consultName = $L.DefaultConsult }

    Write-Host ''
    Write-Host "  $esc[33m$($L.Running)$esc[0m"
    Write-Host ''

    try {
        $report = New-AIRReport -ClientName $clientName -ConsultantName $consultName
        $paths = Export-AIRReport -Report $report
        Write-Host "  $esc[32m$($L.Done):$esc[0m $($paths.Html)"
        Write-Host "  JSON: $($paths.Json)"
        try {
            Start-Process $paths.Html
            Write-Host "  $($L.ReportOpened)"
        } catch {
            Write-Host "  $($L.OpenFail)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host ''
        Write-Host "  [!] $($_.Exception.Message)" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }

    Pause-AIR
}
