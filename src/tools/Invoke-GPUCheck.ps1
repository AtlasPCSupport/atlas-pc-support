# ============================================================
# Invoke-GPUCheck
# GPU diagnostics with optional stress test and report export.
# Atlas PC Support
# ============================================================

function Invoke-GPUCheck {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Continue'

    function Get-UiLang {
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
            Title                  = 'ATLAS PC SUPPORT - GPU Check'
            Header                 = 'GPU CHECK'
            MenuQuick              = '[1] Quick (1 min, no stress)'
            MenuFull               = '[2] Full (12 min, stress)'
            MenuCustom             = '[3] Custom'
            MenuExit               = '[0] Exit'
            PickOption             = 'Choose option'
            InvalidOption          = 'Invalid option.'
            AskMinutes             = 'Test minutes (1-180, default 12)'
            AskStress              = 'Enable stress test? [Y/N] (default Y)'
            Starting               = 'Starting GPU Check...'
            DataRoot               = 'Data root'
            OutDir                 = 'Output folder'
            NeedGPUZ               = 'GPU-Z is required and was not found.'
            NeedFurMark            = 'FurMark stress binary was not found.'
            StageDeps              = 'Resolving dependencies...'
            NoteHwinfoOptional     = 'HWiNFO is optional and not required by this mode.'
            DxdiagStep             = 'Collecting dxdiag...'
            StartGPUZ              = 'Starting GPU-Z logging...'
            StartStress            = 'Starting stress test...'
            StartNvidiaSmi         = 'Starting nvidia-smi logging...'
            TestProgress           = 'Test running'
            ClosingProcs           = 'Stopping test processes...'
            CollectEvents          = 'Collecting GPU-related events...'
            AnalyzeStep            = 'Analyzing data...'
            Done                   = 'Done.'
            JsonPath               = 'JSON'
            HtmlPath               = 'HTML'
            PressEnter             = 'Press ENTER to return to menu...'
            StressOff              = 'Stress test disabled.'
            NoNvidia               = 'NVIDIA GPU not detected (nvidia-smi skipped).'
            NoNvidiaSmi            = 'nvidia-smi not found (NVIDIA telemetry skipped).'
        }
        es = @{
            Title                  = 'ATLAS PC SUPPORT - GPU Check'
            Header                 = 'GPU CHECK'
            MenuQuick              = '[1] Rapido (1 min, sin stress)'
            MenuFull               = '[2] Completo (12 min, con stress)'
            MenuCustom             = '[3] Personalizado'
            MenuExit               = '[0] Salir'
            PickOption             = 'Elige opcion'
            InvalidOption          = 'Opcion no valida.'
            AskMinutes             = 'Minutos de prueba (1-180, default 12)'
            AskStress              = 'Activar stress test? [S/N] (default S)'
            Starting               = 'Iniciando GPU Check...'
            DataRoot               = 'Raiz de datos'
            OutDir                 = 'Carpeta de salida'
            NeedGPUZ               = 'GPU-Z es obligatorio y no fue encontrado.'
            NeedFurMark            = 'No se encontro el binario de stress FurMark.'
            StageDeps              = 'Resolviendo dependencias...'
            NoteHwinfoOptional     = 'HWiNFO es opcional y no es requerido en este modo.'
            DxdiagStep             = 'Recolectando dxdiag...'
            StartGPUZ              = 'Iniciando log de GPU-Z...'
            StartStress            = 'Iniciando stress test...'
            StartNvidiaSmi         = 'Iniciando log de nvidia-smi...'
            TestProgress           = 'Prueba en progreso'
            ClosingProcs           = 'Cerrando procesos de prueba...'
            CollectEvents          = 'Recolectando eventos relacionados a GPU...'
            AnalyzeStep            = 'Analizando datos...'
            Done                   = 'Listo.'
            JsonPath               = 'JSON'
            HtmlPath               = 'HTML'
            PressEnter             = 'Presiona ENTER para volver al menu...'
            StressOff              = 'Stress test desactivado.'
            NoNvidia               = 'No se detecto GPU NVIDIA (se omite nvidia-smi).'
            NoNvidiaSmi            = 'No se encontro nvidia-smi (telemetria NVIDIA omitida).'
        }
    }

    $lang = Get-UiLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    function Write-Centered {
        param([string]$Text, [string]$Color = 'White')
        $w = try { $Host.UI.RawUI.WindowSize.Width } catch { 100 }
        $pad = [Math]::Max(0, [Math]::Floor(($w - $Text.Length) / 2))
        Write-Host ((' ' * $pad) + $Text) -ForegroundColor $Color
    }

    function Write-GPUHeader {
        Clear-Host
        if ($atlasToolkitReady) {
            Write-Host ''
            Write-AtlasHeader -Title ("ATLAS PC SUPPORT - " + $L.Header) -Color Yellow
            Write-Host ''
            return
        }
        Write-Host ''
        Write-Centered '============================================================' 'Cyan'
        Write-Centered ("ATLAS PC SUPPORT - " + $L.Header) 'Yellow'
        Write-Centered '============================================================' 'Cyan'
        Write-Host ''
    }

    function Wait-GPUContinue {
        param([string]$Message = $L.PressEnter)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

    function Ensure-Dir {
        param([Parameter(Mandatory)] [string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }

    function Get-AtlasDataRoot {
        $candidates = @()
        if ($env:ProgramData) { $candidates += (Join-Path $env:ProgramData 'AtlasPC') }
        if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'AtlasPC') }
        foreach ($c in $candidates) {
            try {
                Ensure-Dir -Path $c
                return $c
            } catch {}
        }
        return (Join-Path $env:TEMP 'AtlasPC')
    }

    function Copy-FileSafe {
        param(
            [Parameter(Mandatory)] [string]$Source,
            [Parameter(Mandatory)] [string]$Destination
        )
        $dstDir = Split-Path -Parent $Destination
        Ensure-Dir -Path $dstDir
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }

    function Copy-DirSafe {
        param(
            [Parameter(Mandatory)] [string]$SourceDir,
            [Parameter(Mandatory)] [string]$DestinationDir
        )
        Ensure-Dir -Path $DestinationDir
        robocopy $SourceDir $DestinationDir /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    }

    function Import-CsvAuto {
        param([string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) { return @() }
        $line = ''
        try { $line = Get-Content -LiteralPath $Path -TotalCount 1 -ErrorAction Stop } catch { return @() }
        $delimiter = ','
        if ($line) {
            $semi = ([regex]::Matches($line, ';')).Count
            $comma = ([regex]::Matches($line, ',')).Count
            if ($semi -gt $comma) { $delimiter = ';' }
        }
        try {
            $rows = Import-Csv -LiteralPath $Path -Delimiter $delimiter
            return @($rows)
        } catch {
            return @()
        }
    }

    function Clean-Number {
        param([string]$Text)
        if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
        $raw = $Text.Trim() -replace '[^\d,\.\-]', ''
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $lastComma = $raw.LastIndexOf(',')
        $lastDot = $raw.LastIndexOf('.')
        if ($lastComma -ge 0 -and $lastDot -ge 0) {
            if ($lastComma -gt $lastDot) {
                $raw = $raw.Replace('.', '').Replace(',', '.')
            } else {
                $raw = $raw.Replace(',', '')
            }
        } elseif ($lastComma -ge 0) {
            $raw = $raw.Replace(',', '.')
        }
        $n = 0.0
        if ([double]::TryParse($raw, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { return $n }
        return $null
    }

    function Find-Col {
        param([string[]]$Headers, [string[]]$Patterns)
        foreach ($p in $Patterns) {
            $hit = $Headers | Where-Object { $_ -match $p } | Select-Object -First 1
            if ($hit) { return $hit }
        }
        return $null
    }

    function Get-OfflineToolsRoot {
        if ([string]::IsNullOrWhiteSpace($env:ATLAS_OFFLINE_ROOT)) { return $null }
        $root = Join-Path $env:ATLAS_OFFLINE_ROOT 'deps\GPUCheck\tools'
        if (Test-Path -LiteralPath $root) { return $root }
        return $null
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

    function Resolve-DepPath {
        param(
            [Parameter(Mandatory)] [string]$DepName,
            [Parameter(Mandatory)] [string[]]$InstallPaths,
            [Parameter(Mandatory)] [string]$WingetId,
            [string]$ExecutableName
        )

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try {
                winget install --id $WingetId --exact --accept-source-agreements --accept-package-agreements --silent | Out-Null
            } catch {}
        }

        $resolved = Find-FirstExistingPath -Candidates $InstallPaths
        if (-not $resolved -and $ExecutableName) {
            $cmd = Get-Command $ExecutableName -ErrorAction SilentlyContinue
            if ($cmd) { $resolved = $cmd.Source }
        }
        return $resolved
    }

    function Resolve-GpuCheckTools {
        param(
            [Parameter(Mandatory)] [string]$ToolsDir,
            [switch]$NeedStress
        )
        Ensure-Dir -Path $ToolsDir
        $notes = New-Object System.Collections.Generic.List[string]
        $offlineRoot = Get-OfflineToolsRoot

        $gpuzLocal = Join-Path $ToolsDir 'GPU-Z.exe'
        if (-not (Test-Path -LiteralPath $gpuzLocal) -and $offlineRoot) {
            $off = Join-Path $offlineRoot 'GPU-Z.exe'
            if (Test-Path -LiteralPath $off) { Copy-FileSafe -Source $off -Destination $gpuzLocal; $notes.Add('GPU-Z staged from offline pack.') | Out-Null }
        }
        if (-not (Test-Path -LiteralPath $gpuzLocal)) {
            $gpuzSrc = Resolve-DepPath -DepName 'GPUZ' -WingetId 'TechPowerUp.GPU-Z' -ExecutableName 'GPU-Z.exe' -InstallPaths @(
                'C:\Program Files (x86)\GPU-Z\GPU-Z.exe',
                'C:\Program Files\GPU-Z\GPU-Z.exe',
                '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\GPU-Z.exe'
            )
            if ($gpuzSrc) { Copy-FileSafe -Source $gpuzSrc -Destination $gpuzLocal; $notes.Add('GPU-Z staged from system dependency.') | Out-Null }
        }

        $furLocal = Join-Path $ToolsDir 'FurMark2_x64\furmark.exe'
        if ($NeedStress -and -not (Test-Path -LiteralPath $furLocal) -and $offlineRoot) {
            $offDir = Join-Path $offlineRoot 'FurMark2_x64'
            if (Test-Path -LiteralPath $offDir) {
                Copy-DirSafe -SourceDir $offDir -DestinationDir (Join-Path $ToolsDir 'FurMark2_x64')
                $notes.Add('FurMark staged from offline pack.') | Out-Null
            }
        }
        if ($NeedStress -and -not (Test-Path -LiteralPath $furLocal)) {
            $furSrc = Resolve-DepPath -DepName 'FurMark2' -WingetId 'Geeks3D.FurMark.2' -ExecutableName 'furmark.exe' -InstallPaths @(
                'C:\Program Files\Geeks3D\FurMark2_x64\furmark.exe',
                'C:\Program Files (x86)\Geeks3D\FurMark2_x64\furmark.exe',
                '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\FurMark2_x64\furmark.exe'
            )
            if ($furSrc) {
                $furSrcDir = Split-Path -Parent $furSrc
                Copy-DirSafe -SourceDir $furSrcDir -DestinationDir (Join-Path $ToolsDir 'FurMark2_x64')
                $notes.Add('FurMark staged from system dependency.') | Out-Null
            }
        }

        $hwLocal = Join-Path $ToolsDir 'HWiNFO64.exe'
        if (-not (Test-Path -LiteralPath $hwLocal) -and $offlineRoot) {
            $offHw = Join-Path $offlineRoot 'HWiNFO64.exe'
            if (Test-Path -LiteralPath $offHw) { Copy-FileSafe -Source $offHw -Destination $hwLocal }
        }
        if (-not (Test-Path -LiteralPath $hwLocal)) {
            $hwSrc = Resolve-DepPath -DepName 'HWiNFO' -WingetId 'REALiX.HWiNFO' -ExecutableName 'HWiNFO64.exe' -InstallPaths @(
                'C:\Program Files\HWiNFO64\HWiNFO64.exe',
                'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe',
                '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\HWiNFO64.exe'
            )
            if ($hwSrc) { Copy-FileSafe -Source $hwSrc -Destination $hwLocal }
        }

        $resolvedFur = $null
        $furCandidates = @(
            (Join-Path $ToolsDir 'FurMark2_x64\furmark.exe'),
            (Join-Path $ToolsDir 'FurMark\FurMark.exe'),
            (Join-Path $ToolsDir 'furmark.exe')
        )
        foreach ($c in $furCandidates) {
            if (Test-Path -LiteralPath $c) { $resolvedFur = $c; break }
        }

        return [pscustomobject]@{
            GPUZ = if (Test-Path -LiteralPath $gpuzLocal) { $gpuzLocal } else { $null }
            FurMark = $resolvedFur
            HWiNFO = if (Test-Path -LiteralPath $hwLocal) { $hwLocal } else { $null }
            Notes = $notes.ToArray()
        }
    }

    function Start-Stress {
        param(
            [string]$ExePath,
            [int]$Minutes
        )
        if (-not $ExePath) { return $null }
        $seconds = [Math]::Max(1, $Minutes * 60)
        $help = ''
        try { $help = (& $ExePath --help 2>&1 | Out-String) } catch {}
        $args = "/nogui /max_time=$seconds"
        if ($help -match '--max-time') {
            $args = "--benchmark --p1080 --max-time $seconds --no-score-box"
        }
        $wd = Split-Path -Parent $ExePath
        return Start-Process -FilePath $ExePath -ArgumentList $args -WorkingDirectory $wd -PassThru
    }

    function Stop-Proc {
        param([AllowNull()]$Process)
        if ($null -eq $Process) { return }
        try {
            if (-not $Process.HasExited) {
                try { $Process.CloseMainWindow() | Out-Null } catch {}
                Start-Sleep -Seconds 2
                if (-not $Process.HasExited) { $Process | Stop-Process -Force }
            }
        } catch {}
    }

    function Wait-WithProgress {
        param([int]$Seconds, [string]$Label)
        if ($Seconds -le 0) { return }
        Write-Host ("[GPU Check] {0} ({1}s)" -f $Label, $Seconds) -ForegroundColor Cyan
        $elapsed = 0
        while ($elapsed -lt $Seconds) {
            $step = [Math]::Min(15, $Seconds - $elapsed)
            Start-Sleep -Seconds $step
            $elapsed += $step
            if (($elapsed % 60) -eq 0 -or $elapsed -eq $Seconds) {
                Write-Host ("  {0}/{1} sec" -f $elapsed, $Seconds) -ForegroundColor Gray
            }
        }
    }

    function Start-NvidiaSmiLoop {
        param([string]$CsvPath)
        $cmd = Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue
        if (-not $cmd) { return $null }
        $query = @(
            'timestamp',
            'name',
            'temperature.gpu',
            'utilization.gpu',
            'clocks.current.graphics',
            'power.draw',
            'clocks_throttle_reasons.hw_thermal_slowdown',
            'clocks_throttle_reasons.hw_slowdown',
            'clocks_throttle_reasons.sw_power_cap'
        ) -join ','
        $args = "--query-gpu=$query --format=csv,nounits -l 1"
        return Start-Process -FilePath $cmd.Source -ArgumentList $args -RedirectStandardOutput $CsvPath -WindowStyle Hidden -PassThru
    }

    function Get-GpuEvents {
        param([datetime]$Since, [datetime]$Until)
        $fh = @{ LogName = 'System'; StartTime = $Since; EndTime = $Until }
        return Get-WinEvent -FilterHashtable $fh -ErrorAction SilentlyContinue |
            Where-Object { $_.ProviderName -match 'Display|nvlddmkm|amdkmdag|igfx|dxgkrnl|Microsoft-Windows-WHEA-Logger' } |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
    }

    function Build-HtmlReport {
        param([hashtable]$Data)
@"
<!doctype html>
<html lang="$lang"><head><meta charset="utf-8"/>
<title>GPU Check Report</title>
<style>
body{font-family:Segoe UI,Arial;margin:20px;color:#222}
.card{border:1px solid #ddd;border-radius:10px;padding:12px;margin-bottom:12px}
table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:6px;font-size:13px}
</style></head><body>
<h1>GPU Check</h1>
<div class="card"><b>Date:</b> $($Data.meta.date)<br/><b>Output:</b> $($Data.meta.outDir)</div>
<div class="card"><b>Result:</b> $($Data.final.level) ($($Data.final.total)/100)<br/><b>Advice:</b> $($Data.final.advice)</div>
<div class="card"><h3>Scores</h3>
<ul><li>Events: $($Data.scores.events)</li><li>GPU-Z: $($Data.scores.gpuz)</li><li>NVIDIA: $($Data.scores.nvidia)</li></ul>
</div>
<div class="card"><h3>Notes</h3><ul>$((@($Data.notes) | ForEach-Object { "<li>$_</li>" }) -join "`n")</ul></div>
</body></html>
"@
    }

    $Host.UI.RawUI.WindowTitle = $L.Title
    try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 36) } catch {}
    Write-GPUHeader
    Write-Centered $L.MenuQuick 'White'
    Write-Centered $L.MenuFull 'White'
    Write-Centered $L.MenuCustom 'White'
    Write-Centered $L.MenuExit 'DarkGray'
    Write-Host ''
    $opt = Read-Host $L.PickOption

    $testMinutes = 12
    $skipStress = $false
    switch ($opt) {
        '1' { $testMinutes = 1; $skipStress = $true }
        '2' { $testMinutes = 12; $skipStress = $false }
        '3' {
            $minsRaw = Read-Host $L.AskMinutes
            if ($minsRaw -as [int]) {
                $testMinutes = [Math]::Max(1, [Math]::Min(180, [int]$minsRaw))
            }
            $s = Read-Host $L.AskStress
            $skipStress = ($s -match '^[Nn]$')
            if ($lang -eq 'es' -and $s -match '^[Ss]$') { $skipStress = $false }
        }
        '0' { return }
        default {
            Write-Host $L.InvalidOption -ForegroundColor Red
            Wait-GPUContinue -Message $L.PressEnter
            return
        }
    }

    Write-Host ''
    Write-Host ("[GPU Check] " + $L.Starting) -ForegroundColor Cyan

    $atlasRoot = Get-AtlasDataRoot
    $binRoot = Join-Path $atlasRoot 'bin\GPUCheck'
    $toolsDir = Join-Path $binRoot 'tools'
    $reportsRoot = Join-Path $atlasRoot 'reports\GPUCheck'
    Ensure-Dir -Path $binRoot
    Ensure-Dir -Path $toolsDir
    Ensure-Dir -Path $reportsRoot

    Write-Host ("[GPU Check] {0}: {1}" -f $L.DataRoot, $atlasRoot) -ForegroundColor Gray
    Write-Host ("[GPU Check] {0}" -f $L.StageDeps) -ForegroundColor Gray
    $deps = Resolve-GpuCheckTools -ToolsDir $toolsDir -NeedStress:(-not $skipStress)
    foreach ($n in @($deps.Notes)) { Write-Host ("  - " + $n) -ForegroundColor DarkGray }

    if (-not $deps.GPUZ) {
        Write-Host ("[GPU Check] " + $L.NeedGPUZ) -ForegroundColor Red
        Wait-GPUContinue -Message $L.PressEnter
        return
    }
    if ((-not $skipStress) -and (-not $deps.FurMark)) {
        Write-Host ("[GPU Check] " + $L.NeedFurMark) -ForegroundColor Red
        Wait-GPUContinue -Message $L.PressEnter
        return
    }
    if ($skipStress) { Write-Host ("[GPU Check] " + $L.StressOff) -ForegroundColor Yellow }
    Write-Host ("[GPU Check] " + $L.NoteHwinfoOptional) -ForegroundColor DarkGray

    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outDir = Join-Path $reportsRoot "GPUCheck_$ts"
    Ensure-Dir -Path $outDir
    Write-Host ("[GPU Check] {0}: {1}" -f $L.OutDir, $outDir) -ForegroundColor Gray

    $gpuzLog = Join-Path $outDir 'gpuz.csv'
    $eventsCsv = Join-Path $outDir 'events.csv'
    $gpuCsv = Join-Path $outDir 'gpu_inventory.csv'
    $dxdiagTxt = Join-Path $outDir 'dxdiag.txt'
    $nvidiaCsv = Join-Path $outDir 'nvidia_smi.csv'
    $jsonOut = Join-Path $outDir 'result.json'
    $htmlOut = Join-Path $outDir 'report.html'

    Get-CimInstance Win32_VideoController |
        Select-Object Name, DriverVersion, DriverDate, AdapterRAM, VideoProcessor, PNPDeviceID |
        Export-Csv -LiteralPath $gpuCsv -NoTypeInformation -Encoding UTF8
    $inventory = Import-Csv -LiteralPath $gpuCsv

    $isNvidia = $false
    foreach ($g in @($inventory)) {
        if (($g.Name -match '(?i)NVIDIA') -or ($g.PNPDeviceID -match '(?i)VEN_10DE')) { $isNvidia = $true; break }
    }

    try {
        Write-Host ("[GPU Check] " + $L.DxdiagStep) -ForegroundColor Gray
        Start-Process -FilePath 'dxdiag.exe' -ArgumentList "/whql:off /t `"$dxdiagTxt`"" -Wait
    } catch {}

    $pG = $null
    $pS = $null
    $pN = $null
    $sessionStart = Get-Date
    try {
        Write-Host ("[GPU Check] " + $L.StartGPUZ) -ForegroundColor Gray
        $pG = Start-Process -FilePath $deps.GPUZ -ArgumentList "/minimized /log `"$gpuzLog`"" -PassThru
        Start-Sleep -Seconds 4

        if ($isNvidia) {
            $cmdNv = Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue
            if ($cmdNv) {
                Write-Host ("[GPU Check] " + $L.StartNvidiaSmi) -ForegroundColor Gray
                $pN = Start-NvidiaSmiLoop -CsvPath $nvidiaCsv
            } else {
                Write-Host ("[GPU Check] " + $L.NoNvidiaSmi) -ForegroundColor DarkGray
            }
        } else {
            Write-Host ("[GPU Check] " + $L.NoNvidia) -ForegroundColor DarkGray
        }

        if (-not $skipStress) {
            Write-Host ("[GPU Check] " + $L.StartStress) -ForegroundColor Gray
            $pS = Start-Stress -ExePath $deps.FurMark -Minutes $testMinutes
        }

        Wait-WithProgress -Seconds ($testMinutes * 60) -Label $L.TestProgress
    } finally {
        Write-Host ("[GPU Check] " + $L.ClosingProcs) -ForegroundColor Gray
        Stop-Proc -Process $pS
        Stop-Proc -Process $pN
        Stop-Proc -Process $pG
        Start-Sleep -Seconds 2
    }
    $sessionEnd = Get-Date

    Write-Host ("[GPU Check] " + $L.CollectEvents) -ForegroundColor Gray
    $events = Get-GpuEvents -Since ($sessionStart.AddSeconds(-30)) -Until ($sessionEnd.AddMinutes(1))
    $events | Export-Csv -LiteralPath $eventsCsv -NoTypeInformation -Encoding UTF8

    Write-Host ("[GPU Check] " + $L.AnalyzeStep) -ForegroundColor Gray
    $notes = New-Object System.Collections.Generic.List[string]

    $gpuzScore = 0
    $gpuzMaxT = $null
    $gpuzRows = Import-CsvAuto -Path $gpuzLog
    if ($gpuzRows.Count -gt 2) {
        $hdr = @($gpuzRows[0].PSObject.Properties.Name)
        $tempCol = Find-Col $hdr @('GPU Temperature', 'Temperature')
        if ($tempCol) {
            $temps = New-Object System.Collections.Generic.List[double]
            foreach ($r in $gpuzRows) {
                $n = Clean-Number ([string]$r.$tempCol)
                if ($null -ne $n -and $n -gt 0) { $temps.Add($n) | Out-Null }
            }
            if ($temps.Count -gt 0) {
                $gpuzMaxT = [Math]::Round((($temps.ToArray() | Measure-Object -Maximum).Maximum), 1)
                if ($gpuzMaxT -ge 95) { $gpuzScore += 30; $notes.Add("GPU-Z: temperatura critica ($gpuzMaxT C).") | Out-Null }
                elseif ($gpuzMaxT -ge 88) { $gpuzScore += 15; $notes.Add("GPU-Z: temperatura alta ($gpuzMaxT C).") | Out-Null }
            } else {
                $notes.Add('GPU-Z: sin temperatura parseable.') | Out-Null
            }
        } else {
            $notes.Add('GPU-Z: columna de temperatura no encontrada.') | Out-Null
        }
    } else {
        $notes.Add('GPU-Z: log insuficiente.') | Out-Null
    }

    $nvidiaScore = 0
    $nvidiaMaxT = $null
    $nvidiaRows = Import-CsvAuto -Path $nvidiaCsv
    if ($nvidiaRows.Count -gt 0) {
        $temps = New-Object System.Collections.Generic.List[double]
        foreach ($r in $nvidiaRows) {
            $n = Clean-Number ([string]$r.'temperature.gpu')
            if ($null -ne $n -and $n -gt 0) { $temps.Add($n) | Out-Null }
            if (([string]$r.'clocks_throttle_reasons.hw_thermal_slowdown').Trim() -match '^(?i:1|yes|true|on|active|enabled)$') { $nvidiaScore += 20 }
            if (([string]$r.'clocks_throttle_reasons.hw_slowdown').Trim() -match '^(?i:1|yes|true|on|active|enabled)$') { $nvidiaScore += 15 }
            if (([string]$r.'clocks_throttle_reasons.sw_power_cap').Trim() -match '^(?i:1|yes|true|on|active|enabled)$') { $nvidiaScore += 8 }
        }
        if ($temps.Count -gt 0) {
            $nvidiaMaxT = [Math]::Round((($temps.ToArray() | Measure-Object -Maximum).Maximum), 1)
            if ($nvidiaMaxT -ge 95) { $nvidiaScore += 30; $notes.Add("nvidia-smi: temperatura critica ($nvidiaMaxT C).") | Out-Null }
            elseif ($nvidiaMaxT -ge 88) { $nvidiaScore += 15; $notes.Add("nvidia-smi: temperatura alta ($nvidiaMaxT C).") | Out-Null }
        }
        if ($nvidiaScore -gt 100) { $nvidiaScore = 100 }
    }

    $eventsScore = 0
    $errCount = (@($events | Where-Object { $_.LevelDisplayName -match 'Error|Critical' })).Count
    $tdrCount = (@($events | Where-Object { $_.Id -in 4101, 14, 117, 141 -or $_.Message -match 'TDR|Display driver stopped responding|LiveKernelEvent' })).Count
    $wheaCount = (@($events | Where-Object { $_.ProviderName -match 'WHEA' })).Count
    if ($errCount -gt 0) { $eventsScore += 25; $notes.Add("Eventos Error/Critical: $errCount.") | Out-Null }
    if ($tdrCount -gt 0) { $eventsScore += 30; $notes.Add("Eventos TDR-like: $tdrCount.") | Out-Null }
    if ($wheaCount -gt 0) { $eventsScore += 35; $notes.Add("Eventos WHEA: $wheaCount.") | Out-Null }
    if ($eventsScore -gt 100) { $eventsScore = 100 }

    $total = [Math]::Round(($eventsScore * 0.50) + ($gpuzScore * 0.35) + ($nvidiaScore * 0.15), 1)
    $level = if ($total -ge 70) { 'RIESGO ALTO' } elseif ($total -ge 40) { 'OBSERVACION' } else { 'APTO' }
    $advice = switch ($level) {
        'RIESGO ALTO' { 'Recomendar validacion de hardware profunda y no prometer mejora por mantenimiento general.' }
        'OBSERVACION' { 'Aplicar mantenimiento termico/driver y repetir prueba para confirmar tendencia.' }
        default { 'Sin senales fuertes de falla GPU en esta sesion.' }
    }
    if ($notes.Count -eq 0) { $notes.Add('Sin hallazgos criticos automaticos.') | Out-Null }

    $result = [ordered]@{
        meta = @{
            date = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            outDir = $outDir
            dataRoot = $atlasRoot
            toolsDir = $toolsDir
            testMinutes = $testMinutes
            skipStress = $skipStress
        }
        scores = @{
            events = $eventsScore
            gpuz = $gpuzScore
            nvidia = $nvidiaScore
        }
        telemetry = @{
            gpuzMaxTempC = $gpuzMaxT
            nvidiaMaxTempC = $nvidiaMaxT
            eventCounts = @{
                errorCritical = $errCount
                tdrLike = $tdrCount
                whea = $wheaCount
            }
        }
        final = @{
            total = $total
            level = $level
            advice = $advice
        }
        notes = $notes.ToArray()
        inventory = $inventory
    }

    $result | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $jsonOut -Encoding UTF8
    $html = Build-HtmlReport -Data $result
    $html | Out-File -LiteralPath $htmlOut -Encoding UTF8

    Write-Host ''
    Write-Host ("[GPU Check] " + $L.Done) -ForegroundColor Green
    Write-Host ("[GPU Check] {0}: {1}" -f $L.JsonPath, $jsonOut) -ForegroundColor Gray
    Write-Host ("[GPU Check] {0}: {1}" -f $L.HtmlPath, $htmlOut) -ForegroundColor Gray
    Write-Host ''
    Wait-GPUContinue -Message $L.PressEnter
}
