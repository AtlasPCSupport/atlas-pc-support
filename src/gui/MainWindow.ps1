# ============================================================
# Atlas PC Support — MainWindow.ps1
# Construye la ventana WPF, aplica branding, renderiza herramientas.
# ============================================================

function ConvertTo-AtlasHex {
    param([string]$Hex)
    if (-not $Hex) { return "#FFFFFF" }

    $clean = ([string]$Hex).Trim()
    if ($clean.StartsWith('#')) { $clean = $clean.Substring(1) }
    if ($clean -match '^[0-9A-Fa-f]{3}$') {
        $clean = ($clean.ToCharArray() | ForEach-Object { "$_$_" }) -join ''
    }
    if ($clean -notmatch '^[0-9A-Fa-f]{6}$') {
        return "#FFFFFF"
    }

    return ('#{0}' -f $clean.ToUpperInvariant())
}

function ConvertTo-AtlasXamlSafe {
    param($Value)
    if ($null -eq $Value) { return '' }
    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function ConvertTo-AtlasIntOrDefault {
    param($Value, [int]$Default = 0)
    try { return [int]$Value } catch { return $Default }
}

# Recorre el arbol logico de WPF buscando el primer descendiente del tipo indicado.
function Find-AtlasDescendant {
    param(
        [Parameter(Mandatory)] $Root,
        [Parameter(Mandatory)] [type]$Type
    )
    if ($null -eq $Root) { return $null }
    if ($Root -is $Type) { return $Root }

    # Intentar varios "hijos" segun el tipo de contenedor WPF
    $kids = @()
    if ($Root.PSObject.Properties.Match('Child').Count -gt 0 -and $Root.Child) {
        $kids += $Root.Child
    }
    if ($Root.PSObject.Properties.Match('Children').Count -gt 0 -and $Root.Children) {
        foreach ($c in $Root.Children) { $kids += $c }
    }
    if ($Root.PSObject.Properties.Match('Content').Count -gt 0 -and $Root.Content -and ($Root.Content -is [System.Windows.DependencyObject])) {
        $kids += $Root.Content
    }
    if ($Root.PSObject.Properties.Match('Items').Count -gt 0 -and $Root.Items) {
        foreach ($c in $Root.Items) {
            if ($c -is [System.Windows.DependencyObject]) { $kids += $c }
        }
    }

    foreach ($kid in $kids) {
        $found = Find-AtlasDescendant -Root $kid -Type $Type
        if ($found) { return $found }
    }
    return $null
}

function Get-AtlasPalette {
    param([hashtable]$Branding)

    $accent = ConvertTo-AtlasHex $Branding.theme.accentColor
    $dark   = [bool]$Branding.theme.darkMode
    $secondary = if ($Branding.theme.secondaryColor) { ConvertTo-AtlasHex $Branding.theme.secondaryColor } else { $null }

    if ($dark) {
        # Si hay secondaryColor (ej. Atlas navy #002147), tínta sutilmente el fondo
        $bg      = if ($secondary) { (Get-AtlasColorShift $secondary -15) } else { '#0F1115' }
        $surface = if ($secondary) { (Get-AtlasColorShift $secondary 0)   } else { '#1A1D23' }
        $surfAlt = if ($secondary) { (Get-AtlasColorShift $secondary 15)  } else { '#23272F' }
        return @{
            BgColor          = $bg
            SurfaceColor     = $surface
            SurfaceAltColor  = $surfAlt
            BorderColor      = '#2E333D'
            TextPrimary      = '#F5F5F5'
            TextSecondary    = '#C5C7CC'
            TextMuted        = '#9BA0AA'
            AccentColor      = $accent
            AccentHover      = (Get-AtlasColorShift $accent 20)
            AccentPressed    = (Get-AtlasColorShift $accent -20)
        }
    } else {
        return @{
            BgColor          = '#F7F8FA'
            SurfaceColor     = '#FFFFFF'
            SurfaceAltColor  = '#F0F1F4'
            BorderColor      = '#E0E2E7'
            TextPrimary      = '#1A1D23'
            TextSecondary    = '#434750'
            TextMuted        = '#8A8E95'
            AccentColor      = $accent
            AccentHover      = (Get-AtlasColorShift $accent -10)
            AccentPressed    = (Get-AtlasColorShift $accent -25)
        }
    }
}

function Get-AtlasColorShift {
    param([string]$Hex, [int]$Delta)
    $safeHex = ConvertTo-AtlasHex $Hex
    $h = $safeHex.TrimStart('#')
    $r = [Convert]::ToInt32($h.Substring(0,2), 16)
    $g = [Convert]::ToInt32($h.Substring(2,2), 16)
    $b = [Convert]::ToInt32($h.Substring(4,2), 16)
    $r = [Math]::Max(0, [Math]::Min(255, $r + $Delta))
    $g = [Math]::Max(0, [Math]::Min(255, $g + $Delta))
    $b = [Math]::Max(0, [Math]::Min(255, $b + $Delta))
    return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
}

function Expand-AtlasXaml {
    param(
        [string]$Xaml,
        [hashtable]$Branding,
        [hashtable]$Palette
    )
    $tagline = $Branding.brand.tagline
    if (-not $tagline) { $tagline = Get-AtlasString 'app.tagline' }

    $map = @{
        'WINDOW_TITLE'       = (ConvertTo-AtlasXamlSafe $Branding.window.title)
        'WINDOW_WIDTH'       = (ConvertTo-AtlasIntOrDefault $Branding.window.width 1100)
        'WINDOW_HEIGHT'      = (ConvertTo-AtlasIntOrDefault $Branding.window.height 720)
        'WINDOW_MIN_WIDTH'   = (ConvertTo-AtlasIntOrDefault $Branding.window.minWidth 900)
        'WINDOW_MIN_HEIGHT'  = (ConvertTo-AtlasIntOrDefault $Branding.window.minHeight 600)
        'BRAND_NAME'         = (ConvertTo-AtlasXamlSafe $Branding.brand.name)
        'BRAND_TAGLINE'      = (ConvertTo-AtlasXamlSafe $tagline)
        'BRAND_VERSION'      = (ConvertTo-AtlasXamlSafe $Branding.brand.version)
        'BRAND_COPYRIGHT'    = (ConvertTo-AtlasXamlSafe $Branding.brand.copyright)
        'FONT_FAMILY'        = (ConvertTo-AtlasXamlSafe $Branding.theme.fontFamily)
        'CORNER_RADIUS'      = (ConvertTo-AtlasIntOrDefault $Branding.theme.cornerRadius 8)
        'ACCENT_COLOR'       = $Palette.AccentColor
        'ACCENT_HOVER'       = $Palette.AccentHover
        'ACCENT_PRESSED'     = $Palette.AccentPressed
        'BG_COLOR'           = $Palette.BgColor
        'SURFACE_COLOR'      = $Palette.SurfaceColor
        'SURFACE_ALT_COLOR'  = $Palette.SurfaceAltColor
        'BORDER_COLOR'       = $Palette.BorderColor
        'TEXT_PRIMARY'       = $Palette.TextPrimary
        'TEXT_SECONDARY'     = $Palette.TextSecondary
        'TEXT_MUTED'         = $Palette.TextMuted
        'SEARCH_PLACEHOLDER' = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'search.placeholder'))
        'HEADER_LOGS'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.logs'))
        'HEADER_ABOUT'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.about'))
        'STATUS_READY'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'status.ready'))
        'COFFEE_LABEL'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'footer.coffee'))
        'COFFEE_TOOLTIP'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'footer.coffeeTooltip'))
        'LANG_TOOLTIP'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.languageTooltip'))
        'RESTART_TOOLTIP'    = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.restartTooltip'))
        'DASH_CPU'           = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.cpu'))
        'DASH_RAM'           = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.ram'))
        'DASH_DISK'          = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.disk'))
        'DASH_ALERTS'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.alerts'))
        'DASH_REFRESH_TOOLTIP' = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.refreshTooltip'))
        'DASH_TOGGLE_ON'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.monitor.on'))
        'DASH_TOGGLE_OFF'    = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.monitor.off'))
        'DASH_TOGGLE_TOOLTIP'= (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.monitor.tooltip'))
        'SIDEBAR_HEADER'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.header'))
        'SIDEBAR_HOST'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.host'))
        'SIDEBAR_USER'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.user'))
        'SIDEBAR_OS'         = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.os'))
        'SIDEBAR_CPU'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.cpu'))
        'SIDEBAR_RAM'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.ram'))
        'SIDEBAR_UPTIME'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.uptime'))
        'SIDEBAR_IP'         = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.ip'))
        'SIDEBAR_LASTSYNC'   = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.lastSync'))
        'SIDEBAR_LOAD_BTN'   = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.loadBtn'))
    }
    foreach ($k in $map.Keys) {
        $Xaml = $Xaml.Replace("{{$k}}", [string]$map[$k])
    }
    return $Xaml
}

function Get-AtlasToolDisplay {
    param([Parameter(Mandatory)]$Tool, [string]$Language = $script:AtlasCurrentLang)
    if ($Language -eq 'es' -and $Tool.nameEs -and $Tool.descriptionEs) {
        return [pscustomobject]@{Name=$Tool.nameEs;Description=$Tool.descriptionEs}
    }
    return [pscustomobject]@{Name=$Tool.name;Description=$Tool.description}
}

function Test-AtlasToolQuery {
    param([Parameter(Mandatory)]$Tool, [AllowEmptyString()][string]$Query)
    function ConvertTo-SearchText([string]$Value) {
        return [regex]::Replace($Value.Normalize([Text.NormalizationForm]::FormD),'\p{Mn}','').ToLowerInvariant()
    }
    $haystack = ConvertTo-SearchText (@($Tool.id,$Tool.category,$Tool.name,$Tool.description,$Tool.nameEs,$Tool.descriptionEs) -join ' ')
    foreach ($term in @((ConvertTo-SearchText $Query).Split(' ') | Where-Object { $_ })) {
        if (-not $haystack.Contains($term)) { return $false }
    }
    return $true
}

function New-AtlasToolCard {
    param(
        [hashtable]$Tool,
        [hashtable]$Branding,
        [hashtable]$Palette
    )

    $width = 320
    $cornerRadius = ConvertTo-AtlasIntOrDefault $Branding.theme.cornerRadius 8
    $xaml = @"
<Border xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Background='$($Palette.SurfaceColor)'
        BorderBrush='$($Palette.BorderColor)'
        BorderThickness='1'
        CornerRadius='$cornerRadius'
        Padding='16'
        Margin='0,0,12,12'
        Width='$width'>
    <StackPanel>
        <StackPanel Orientation='Horizontal' Margin='0,0,0,6'>
            <TextBlock Text='{{ICON}}' FontSize='18' Margin='0,0,8,0' Foreground='$($Palette.AccentColor)'/>
            <TextBlock Text='{{NAME}}' FontSize='15' FontWeight='SemiBold' Foreground='$($Palette.TextPrimary)' TextTrimming='CharacterEllipsis'/>
        </StackPanel>
        <TextBlock Text='{{DESCRIPTION}}'
                   Foreground='$($Palette.TextSecondary)'
                   FontSize='12'
                   TextWrapping='Wrap'
                   Height='56'
                   Margin='0,0,0,10'/>
        <StackPanel Orientation='Horizontal'>
            <Button x:Name='BtnRun' Content='{{BTN_RUN}}' Tag='{{ID}}' Padding='14,6'
                    Background='$($Palette.AccentColor)' Foreground='White'
                    BorderBrush='$($Palette.AccentColor)' BorderThickness='1'
                    Cursor='Hand'/>
            <TextBlock x:Name='AdminIcon' Text='{{ADMIN_BADGE}}'
                       Foreground='$($Palette.TextMuted)' FontSize='11'
                       Margin='12,0,0,0' VerticalAlignment='Center'/>
        </StackPanel>
    </StackPanel>
</Border>
"@

    $iconMap = @{
        'diagnostico'   = '🔍'
        'mantenimiento' = '🛠'
        'copia'         = '📁'
        'redes'         = '🌐'
        'seguridad'     = '🔒'
        'software'      = '📦'
        'entrega'       = '✅'
    }
    $icon = $iconMap[$Tool.category]
    if (-not $icon) { $icon = '⚙' }

    $adminBadge = if ($Tool.requiresAdmin) { (Get-AtlasString 'badge.requiresAdmin') } else { "" }
    $btnRunText = Get-AtlasString 'button.run'
    $availability = if ($Tool.ContainsKey('_availability')) { $Tool._availability } else { $null }
    if ($availability -and -not $availability.Available) {
        $xaml = $xaml.Replace("x:Name='BtnRun'", "x:Name='BtnRun' IsEnabled='False' ToolTip='" + [Security.SecurityElement]::Escape($availability.Reason) + "'")
        $xaml = $xaml.Replace("Text='{{DESCRIPTION}}'", "Text='{{DESCRIPTION}}' ToolTip='" + [Security.SecurityElement]::Escape($availability.Reason) + "'")
        $btnRunText = if ($script:AtlasCurrentLang -eq 'es') { 'No disponible' } else { 'Unavailable' }
    }

    $display = Get-AtlasToolDisplay -Tool $Tool
    $xaml = $xaml.Replace('{{ICON}}', $icon).
                  Replace('{{NAME}}', [System.Security.SecurityElement]::Escape($display.Name)).
                  Replace('{{DESCRIPTION}}', [System.Security.SecurityElement]::Escape($display.Description)).
                  Replace('{{ID}}', $Tool.id).
                  Replace('{{BTN_RUN}}', [System.Security.SecurityElement]::Escape($btnRunText)).
                  Replace('{{ADMIN_BADGE}}', $adminBadge)

    return $xaml
}

# ---- Dashboard / Sidebar helpers ----------------------------------------

if (-not $script:AtlasLiveSnapshotMinIntervalSeconds) {
    # Avoid hammering CIM from the UI thread every 2 seconds.
    $script:AtlasLiveSnapshotMinIntervalSeconds = 5
}
if (-not $script:AtlasLiveSnapshotAt) {
    $script:AtlasLiveSnapshotAt = [datetime]::MinValue
}

# Cached static system info (gathered once — these don't change at runtime).
function Get-AtlasStaticSystemInfo {
    if ($script:AtlasStaticSysInfo) { return $script:AtlasStaticSysInfo }
    $info = @{
        HostName    = $env:COMPUTERNAME
        UserName    = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
        OSCaption   = ''
        OSVersion   = ''
        OSBuild     = ''
        CpuName     = ''
        TotalRamGB  = 0
        LastBoot    = $null
        SysDriveLetter = ''
        SysDriveTotalGB = 0
    }
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 5 -ErrorAction Stop
        $info.OSCaption = ($os.Caption -replace '^Microsoft\s*', '').Trim()
        $info.OSVersion = $os.Version
        $info.OSBuild   = $os.BuildNumber
        $info.LastBoot  = $os.LastBootUpTime
        $info.SysDriveLetter = ($os.SystemDrive -replace ':', '')
        # TotalVisibleMemorySize is in KB
        $info.TotalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    } catch { Write-AtlasLog "Get-AtlasStaticSystemInfo: OS query failed: $_" -Level WARN -Tool 'UI' }

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -OperationTimeoutSec 5 -ErrorAction Stop | Select-Object -First 1
        if ($cpu) { $info.CpuName = ($cpu.Name -replace '\s+', ' ').Trim() }
    } catch { Write-AtlasLog "Get-AtlasStaticSystemInfo: CPU query failed: $_" -Level WARN -Tool 'UI' }

    try {
        if ($info.SysDriveLetter) {
            $disk = Get-CimInstance -ClassName Win32_LogicalDisk -OperationTimeoutSec 5 -Filter "DeviceID='$($info.SysDriveLetter):'" -ErrorAction Stop
            if ($disk -and $disk.Size) {
                $info.SysDriveTotalGB = [math]::Round($disk.Size / 1GB, 0)
            }
        }
    } catch { Write-AtlasLog "Get-AtlasStaticSystemInfo: Disk query failed: $_" -Level WARN -Tool 'UI' }

    $script:AtlasStaticSysInfo = $info
    return $info
}

# Live snapshot — fast queries only (called every refresh tick).
function Get-AtlasLiveSystemSnapshot {
    [CmdletBinding()]
    param([switch]$ForceRefresh)

    if (-not $ForceRefresh -and $script:AtlasLiveSnapshotCache -and $script:AtlasLiveSnapshotAt) {
        $ageSec = ((Get-Date) - $script:AtlasLiveSnapshotAt).TotalSeconds
        if ($ageSec -lt [double]$script:AtlasLiveSnapshotMinIntervalSeconds) {
            return $script:AtlasLiveSnapshotCache
        }
    }

    $snap = @{
        CpuPercent  = $null
        RamPercent  = $null
        RamUsedGB   = 0
        RamTotalGB  = 0
        DiskPercent = $null
        DiskFreeGB  = 0
        DiskTotalGB = 0
        IpAddress   = ''
        BatteryPct  = $null
        Uptime      = $null
        UptimeDays  = 0
        PendingReboot = $false
    }

    $static = Get-AtlasStaticSystemInfo

    try {
        $cpuPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -OperationTimeoutSec 5 `
            -Filter "Name='_Total'" -ErrorAction Stop
        if ($cpuPerf) { $snap.CpuPercent = [int]$cpuPerf.PercentProcessorTime }
    } catch { }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 5 -ErrorAction Stop
        if ($os) {
            $totalKb = [double]$os.TotalVisibleMemorySize
            $freeKb  = [double]$os.FreePhysicalMemory
            if ($totalKb -gt 0) {
                $snap.RamPercent = [int](100 - ($freeKb * 100 / $totalKb))
                $snap.RamTotalGB = [math]::Round($totalKb / 1MB, 1)
                $snap.RamUsedGB  = [math]::Round(($totalKb - $freeKb) / 1MB, 1)
            }
            if ($os.LastBootUpTime) {
                $snap.Uptime = (Get-Date) - $os.LastBootUpTime
                $snap.UptimeDays = [int]$snap.Uptime.TotalDays
            }
        }
    } catch { }

    try {
        if ($static.SysDriveLetter) {
            $disk = Get-CimInstance -ClassName Win32_LogicalDisk -OperationTimeoutSec 5 `
                -Filter "DeviceID='$($static.SysDriveLetter):'" -ErrorAction Stop
            if ($disk -and $disk.Size -gt 0) {
                $snap.DiskTotalGB = [math]::Round($disk.Size / 1GB, 0)
                $snap.DiskFreeGB  = [math]::Round($disk.FreeSpace / 1GB, 0)
                $snap.DiskPercent = [int]((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100)
            }
        }
    } catch { }

    try {
        # Prefer Get-NetIPAddress (PS 5.1+ on Win8+); fallback to ipconfig parse
        $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.PrefixOrigin -ne 'WellKnown' -and $_.IPAddress -notmatch '^169\.254\.' -and $_.IPAddress -ne '127.0.0.1' } |
            Sort-Object -Property InterfaceMetric |
            Select-Object -First 1
        if ($ip) { $snap.IpAddress = $ip.IPAddress }
    } catch { }

    try {
        $bat = Get-CimInstance -ClassName Win32_Battery -OperationTimeoutSec 5 -ErrorAction Stop |
            Select-Object -First 1
        if ($bat -and $null -ne $bat.EstimatedChargeRemaining) {
            $snap.BatteryPct = [int]$bat.EstimatedChargeRemaining
        }
    } catch { }

    try {
        $pendingPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        )
        foreach ($p in $pendingPaths) {
            if (Test-Path $p) { $snap.PendingReboot = $true; break }
        }
    } catch { }

    $script:AtlasLiveSnapshotCache = $snap
    $script:AtlasLiveSnapshotAt = Get-Date
    return $snap
}

# Build localized alert list from the live snapshot.
function Get-AtlasDashboardAlerts {
    param([hashtable]$Snap)
    $alerts = @()
    if ($null -ne $Snap.CpuPercent -and $Snap.CpuPercent -ge 90) {
        $alerts += (Get-AtlasString 'dash.alert.cpu' $Snap.CpuPercent)
    }
    if ($null -ne $Snap.RamPercent -and $Snap.RamPercent -ge 90) {
        $alerts += (Get-AtlasString 'dash.alert.ram' $Snap.RamPercent)
    }
    if ($null -ne $Snap.DiskPercent -and $Snap.DiskPercent -ge 90) {
        $static = Get-AtlasStaticSystemInfo
        $alerts += (Get-AtlasString 'dash.alert.disk' "$($static.SysDriveLetter):" $Snap.DiskPercent)
    }
    if ($Snap.UptimeDays -ge 7) {
        $alerts += (Get-AtlasString 'dash.alert.uptime' $Snap.UptimeDays)
    }
    if ($null -ne $Snap.BatteryPct -and $Snap.BatteryPct -le 20) {
        $alerts += (Get-AtlasString 'dash.alert.battery' $Snap.BatteryPct)
    }
    if ($Snap.PendingReboot) {
        $alerts += (Get-AtlasString 'dash.alert.pendingReboot')
    }
    return ,$alerts
}

# Initialize dashboard + sidebar data.
#
# Performance: pre-fill the cheap fields (hostname/user from env vars)
# synchronously, then defer all CIM/WMI/Get-NetIPAddress work to run AFTER
# the window has been rendered. This way the panel pops up immediately
# and the dashboard fills in over the next ~1 s instead of blocking the
# Show-AtlasWindow ShowDialog call for several CIM round trips on startup.
function Initialize-AtlasDashboard {
    param([Parameter(Mandatory)]$Window)
    $controls = @{}
    foreach ($name in @('SideHost','SideUser','SideOS','SideCpu','SideRam','SideUptime','SideIp','SideLastSync','DashCpuValue','DashCpuBar','DashRamValue','DashRamBar','DashDiskValue','DashDiskBar','DashAlertsText','BtnDashRefresh','BtnDashMonitorToggle','BtnLoadSysInfo')) {
        $controls[$name] = $Window.FindName($name)
    }
    if ($controls.SideHost) { $controls.SideHost.Text = $env:COMPUTERNAME }
    if ($controls.SideUser) { $controls.SideUser.Text = $env:USERNAME }
    foreach ($name in @('SideOS','SideCpu','SideRam','SideUptime','SideIp','DashCpuValue','DashRamValue','DashDiskValue')) {
        if ($controls[$name]) { $controls[$name].Text = '--' }
    }
    $state = @{ Worker=$null; Pending=$null; StopPending=$null; Started=[datetime]::MinValue; Last=[datetime]::MinValue; Monitor=$false; WantSidebar=$false; Closed=$false }
    $strFn = ${function:Get-AtlasString}
    $logFn = ${function:Write-AtlasLog}
    # Only collectors execute in the background runspace. WPF objects remain on the dispatcher.
    $collector = "function Get-AtlasStaticSystemInfo {`n${function:Get-AtlasStaticSystemInfo}`n}`nfunction Get-AtlasLiveSystemSnapshot {`n${function:Get-AtlasLiveSystemSnapshot}`n}`nfunction Write-AtlasLog { param(`$Message,`$Level,`$Tool) Write-Verbose `$Message }`n"
    $collector += '[pscustomobject]@{ Static=(Get-AtlasStaticSystemInfo); Snapshot=(Get-AtlasLiveSystemSnapshot -ForceRefresh) }'
    $startRead = {
        if ($state.Closed -or $state.Worker) { return }
        $state.Worker = [powershell]::Create()
        [void]$state.Worker.AddScript($collector)
        $state.Started = [datetime]::UtcNow
        $state.Pending = $state.Worker.BeginInvoke()
        if ($controls.DashAlertsText) { $controls.DashAlertsText.Text = '...' }
    }.GetNewClosure()
    $poll = {
        if ($state.Closed) { return }
        if ($state.StopPending) {
            if (-not $state.StopPending.IsCompleted) { return }
            try { $state.Worker.EndStop($state.StopPending) } catch { & $logFn "Dashboard cancellation: $_" -Level WARN -Tool UI }
            $state.Worker.Dispose(); $state.Worker=$null; $state.Pending=$null; $state.StopPending=$null
            $state.Last=[datetime]::UtcNow
            return
        }
        if ($state.Worker -and -not $state.Pending.IsCompleted) {
            if (([datetime]::UtcNow - $state.Started).TotalSeconds -gt 30) {
                $state.StopPending = $state.Worker.BeginStop($null,$null)
                $state.Monitor = $false
                if ($controls.BtnDashMonitorToggle) { $controls.BtnDashMonitorToggle.Content = & $strFn 'dash.monitor.off' }
                if ($controls.DashAlertsText) { $controls.DashAlertsText.Text = 'Not evaluated: inventory query timed out.' }
            }
            return
        }
        if ($state.Worker) {
            try {
                $result = @($state.Worker.EndInvoke($state.Pending)) | Select-Object -Last 1
                if (-not $result -or -not $result.Snapshot) { throw 'No inventory result.' }
                $static = $result.Static; $snap = $result.Snapshot
                if ($state.WantSidebar) {
                    if ($controls.SideOS) { $controls.SideOS.Text = "$($static.OSCaption) (build $($static.OSBuild))" }
                    if ($controls.SideCpu) { $controls.SideCpu.Text = [string]$static.CpuName }
                    if ($controls.SideRam) { $controls.SideRam.Text = "$($static.TotalRamGB) GB" }
                    if ($controls.SideIp) { $controls.SideIp.Text = [string]$snap.IpAddress }
                    if ($controls.SideUptime -and $snap.Uptime) { $controls.SideUptime.Text = [string]$snap.Uptime }
                    $state.WantSidebar = $false
                }
                foreach ($metric in @('Cpu','Ram','Disk')) {
                    $value = $snap[($metric + 'Percent')]
                    if ($controls[('Dash' + $metric + 'Value')]) { $controls[('Dash' + $metric + 'Value')].Text = if ($null -eq $value) { '-- (not evaluated)' } else { "$value%" } }
                    if ($controls[('Dash' + $metric + 'Bar')]) { $controls[('Dash' + $metric + 'Bar')].Value = if ($null -eq $value) { 0 } else { $value } }
                }
                $alerts = @()
                foreach ($metric in @('Cpu','Ram','Disk')) {
                    if ($null -ne $snap[($metric+'Percent')] -and $snap[($metric+'Percent')] -ge 90) { $alerts += "$metric >= 90%" }
                }
                if ($snap.PendingReboot) { $alerts += & $strFn 'dash.alert.pendingReboot' }
                if ($snap.UptimeDays -ge 7) { $alerts += & $strFn 'dash.alert.uptime' $snap.UptimeDays }
                if ($controls.DashAlertsText) {
                    $controls.DashAlertsText.Text = if ($null -eq $snap.CpuPercent -or $null -eq $snap.RamPercent -or $null -eq $snap.DiskPercent) {
                        'Partial inventory: one or more metrics were not evaluated.'
                    } elseif ($alerts.Count) { $alerts -join ' | ' } else { & $strFn 'dash.alerts.none' }
                }
                if ($controls.SideLastSync) { $controls.SideLastSync.Text = (Get-Date).ToString('HH:mm:ss') }
            } catch {
                if ($controls.DashAlertsText) { $controls.DashAlertsText.Text = 'Not evaluated: inventory query failed.' }
                & $logFn "Dashboard query failed: $_" -Level WARN -Tool UI
            } finally {
                $state.Worker.Dispose(); $state.Worker=$null; $state.Pending=$null; $state.Last=[datetime]::UtcNow
            }
        }
        if ($state.Monitor -and ([datetime]::UtcNow - $state.Last).TotalSeconds -ge 5) { & $startRead }
    }.GetNewClosure()
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [timespan]::FromMilliseconds(200)
    $timer.Add_Tick($poll)
    $timer.Start()
    if ($controls.DashAlertsText) { $controls.DashAlertsText.Text = & $strFn 'dash.monitor.paused' }
    if ($controls.BtnDashMonitorToggle) {
        $controls.BtnDashMonitorToggle.Content = & $strFn 'dash.monitor.off'
        $controls.BtnDashMonitorToggle.Add_Click({
            $state.Monitor = -not $state.Monitor
            $controls.BtnDashMonitorToggle.Content = if ($state.Monitor) { & $strFn 'dash.monitor.on' } else { & $strFn 'dash.monitor.off' }
            if ($state.Monitor) { & $startRead }
        }.GetNewClosure())
    }
    if ($controls.BtnDashRefresh) { $controls.BtnDashRefresh.Add_Click({ & $startRead }.GetNewClosure()) }
    if ($controls.BtnLoadSysInfo) { $controls.BtnLoadSysInfo.Add_Click({ $state.WantSidebar=$true; & $startRead }.GetNewClosure()) }
    $Window.Add_Closed({
        $state.Closed=$true; $timer.Stop()
        if ($state.Worker) {
            if ($state.Pending.IsCompleted) { $state.Worker.Dispose() }
            elseif (-not $state.StopPending) { $state.StopPending=$state.Worker.BeginStop($null,$null) }
        }
    }.GetNewClosure())
    # Exposed for isolated WPF lifecycle tests; no read starts until the user requests it.
    $Window.Tag = [pscustomobject]@{ DashboardState=$state; DashboardTimer=$timer; DashboardPoll=$poll; DashboardStart=$startRead }
}

function Show-AtlasWindow {
    param(
        [hashtable]$Branding,
        [array]$Tools,
        [string]$XamlTemplate
    )

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    $palette = Get-AtlasPalette -Branding $Branding
    $xaml    = Expand-AtlasXaml -Xaml $XamlTemplate -Branding $Branding -Palette $palette

    try {
        [xml]$xamlDoc = $xaml
    } catch {
        throw "XAML inválido tras expansión de branding: $_"
    }

    $reader = New-Object System.Xml.XmlNodeReader $xamlDoc
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Agarrar controles
    $categoryBar = $window.FindName('CategoryBar')
    $toolsGrid   = $window.FindName('ToolsGrid')
    $searchBox   = $window.FindName('SearchBox')
    $statusText  = $window.FindName('StatusText')
    $adminBadge  = $window.FindName('AdminBadge')
    $btnLogs     = $window.FindName('BtnLogs')
    $btnAbout    = $window.FindName('BtnAbout')
    $btnRestart  = $window.FindName('BtnRestart')
    $coffeeLink  = $window.FindName('CoffeeLink')
    $langCombo   = $window.FindName('LanguageCombo')

    # Badge de admin en header
    if (Test-IsAdmin) {
        $adminBadge.Text = Get-AtlasString 'header.admin'
        $adminBadge.Foreground = [System.Windows.Media.Brushes]::LimeGreen
    } else {
        $adminBadge.Text = Get-AtlasString 'header.user'
    }

    # Categorías — usa label traducido si el brand no sobreescribe
    $categories = @($Branding.categories) | Sort-Object -Property order
    $allCat = New-Object System.Windows.Controls.RadioButton
    $allCat.Content = Get-AtlasString 'category.all'
    $allCat.Style = $window.FindResource('CategoryPill')
    $allCat.Tag = '__all__'
    $allCat.IsChecked = $true
    [void]$categoryBar.Children.Add($allCat)

    foreach ($cat in $categories) {
        $rb = New-Object System.Windows.Controls.RadioButton
        $translatedLabel = Get-AtlasString "category.$($cat.id)"
        $label = if ($translatedLabel -ne "category.$($cat.id)") { $translatedLabel } else { $cat.label }
        $rb.Content = "$($cat.icon) $label"
        $rb.Style = $window.FindResource('CategoryPill')
        $rb.Tag = $cat.id
        [void]$categoryBar.Children.Add($rb)
    }

    # Renderizar tools
    $script:AllCards = @()
    foreach ($tool in $Tools) {
        try { $tool._availability = Test-AtlasToolAvailability -Tool $tool }
        catch { $tool._availability = [pscustomobject]@{ Available=$false; Reason="Platform could not be evaluated: $_" } }
        $cardXaml = New-AtlasToolCard -Tool $tool -Branding $Branding -Palette $palette
        [xml]$cardDoc = $cardXaml
        $cardReader = New-Object System.Xml.XmlNodeReader $cardDoc
        $card = [Windows.Markup.XamlReader]::Load($cardReader)
        $card.Tag = $tool

        # Walk visual tree robustly para encontrar el boton "Run"
        $btn = Find-AtlasDescendant -Root $card -Type ([System.Windows.Controls.Button])
        if ($btn) {
            # Guardar el tool completo en el Tag del boton, evita depender de scope compartido
            $btn.Tag = $tool
            Write-AtlasLog ("Bound click handler: tool={0}" -f $tool.id) -Level DEBUG

            $btn.Add_Click({
                param($eventSender, $eventArgs)
                try {
                    # $eventSender es el boton, fallback a $this si PowerShell no lo binde
                    $theBtn = if ($eventSender) { $eventSender } else { $this }
                    $t = $theBtn.Tag
                    if (-not $t) {
                        Write-AtlasLog "Click: Button.Tag esta vacio" -Level WARN
                        return
                    }
                    Write-AtlasLog ("Click: lanzando tool={0} function={1}" -f $t.id, $t.function) -Level INFO

                    $statusText = $script:MainWindow.FindName('StatusText')
                    if ($statusText) { $statusText.Text = Get-AtlasString 'status.launching' $t.name }

                    Invoke-AtlasTool -Tool $t -Branding $script:Branding

                    if ($statusText) { $statusText.Text = Get-AtlasString 'status.lastRun' $t.name }
                } catch {
                    Write-AtlasLog ("Click handler fallo: {0}" -f $_.Exception.Message) -Level ERROR
                    [System.Windows.MessageBox]::Show(
                        "Error al lanzar la herramienta:`n`n$($_.Exception.Message)",
                        "Atlas PC Support",
                        'OK', 'Error') | Out-Null
                }
            })
        } else {
            Write-AtlasLog ("NO se encontro el boton Run para tool={0}" -f $tool.id) -Level ERROR
        }

        $script:AllCards += [pscustomobject]@{ Card = $card; Tool = $tool }
        [void]$toolsGrid.Items.Add($card)
    }

    # Función filtro
    $applyFilter = {
        $selectedCat = ($categoryBar.Children | Where-Object { $_.IsChecked }).Tag
        $query = $searchBox.Text.Trim().ToLower()

        $toolsGrid.Items.Clear()
        foreach ($entry in $script:AllCards) {
            $t = $entry.Tool
            $matchesCat = ($selectedCat -eq '__all__') -or ($t.category -eq $selectedCat)
            $matchesQuery = Test-AtlasToolQuery -Tool $t -Query $query
            if ($matchesCat -and $matchesQuery) {
                [void]$toolsGrid.Items.Add($entry.Card)
            }
        }
        $statusText.Text = Get-AtlasString 'status.toolsShown' $toolsGrid.Items.Count
    }

    foreach ($rb in $categoryBar.Children) {
        $rb.Add_Checked($applyFilter)
    }
    $searchBox.Add_TextChanged($applyFilter)

    # Botones header
    $btnLogs.Add_Click({
        $logPath = Get-AtlasLogPath
        if (Test-Path $logPath) {
            Start-Process notepad.exe -ArgumentList $logPath
        } else {
            [System.Windows.MessageBox]::Show((Get-AtlasString 'logs.empty'), $script:Branding.brand.shortName) | Out-Null
        }
    })
    $btnAbout.Add_Click({
        $webLabel = Get-AtlasString 'about.web'
        $tagline = if ($script:Branding.brand.tagline) { $script:Branding.brand.tagline } else { Get-AtlasString 'app.tagline' }
        $msg = @"
$($script:Branding.brand.name) v$($script:Branding.brand.version)

$tagline

$($webLabel): $($script:Branding.brand.companyUrl)
$($script:Branding.brand.copyright)

$(Get-AtlasString 'about.description')
"@
        [System.Windows.MessageBox]::Show($msg, (Get-AtlasString 'about.title'), "OK", "Information") | Out-Null
    })

    # Selector de idioma (header)
    if ($langCombo) {
        $supported = Get-AtlasSupportedLanguages
        $currentLang = $script:AtlasCurrentLang
        $selectedIndex = 0
        $i = 0
        foreach ($code in $supported) {
            $item = New-Object System.Windows.Controls.ComboBoxItem
            $item.Content = Get-AtlasLanguageName $code
            $item.Tag = $code
            [void]$langCombo.Items.Add($item)
            if ($code -eq $currentLang) { $selectedIndex = $i }
            $i++
        }
        $langCombo.SelectedIndex = $selectedIndex
        # Marcar initial selection como hecho ANTES de enganchar el handler,
        # para evitar que un evento espureo dispare al crear la ComboBox.
        $script:LangComboReady = $true
        $langCombo.Add_SelectionChanged({
            param($eventSender, $eventArgs)
            if (-not $script:LangComboReady) { return }
            $sel = $eventSender.SelectedItem
            if (-not $sel) { return }
            $newLang = [string]$sel.Tag
            if ($newLang -eq $script:AtlasCurrentLang) { return }
            $ok = Set-AtlasLanguagePref $newLang
            Write-AtlasLog "Idioma cambiado a '$newLang' (guardado=$ok). Reinicio requerido." -Tool 'UI'
            $brand = if ($script:Branding -and $script:Branding.brand) { $script:Branding.brand.shortName } else { 'Atlas PC Support' }
            # Usar el string del NUEVO idioma (ya cargado en el dict, solo no aplicado a UI)
            $msg = $script:AtlasStringsDict[$newLang]['language.restartRequired']
            if (-not $msg) { $msg = Get-AtlasString 'language.restartRequired' }
            [System.Windows.MessageBox]::Show($msg, $brand, 'OK', 'Information') | Out-Null
        })
    }

    if ($btnRestart) {
        $btnRestart.Add_Click({
            $msg = Get-AtlasString 'restart.instructions'
            $brand = if ($script:Branding -and $script:Branding.brand) { $script:Branding.brand.shortName } else { 'Atlas PC Support' }
            [System.Windows.MessageBox]::Show($msg, $brand, 'OK', 'Information') | Out-Null
            Write-AtlasLog "Reinicio solicitado por usuario — cerrando panel." -Tool 'UI'
            if ($script:MainWindow) { $script:MainWindow.Close() }
        })
    }

    # Coffee / donacion (footer)
    if ($coffeeLink) {
        $coffeeUrl = 'https://www.paypal.me/atlaspcsupport'
        $coffeeLink.Add_MouseLeftButtonUp({
            try {
                Start-Process $coffeeUrl
            } catch {
                Write-AtlasLog "No se pudo abrir URL de donacion: $_" -Level WARN
            }
        })
    }

    $script:MainWindow = $window
    $script:Branding = $Branding
    $script:AllTools = $Tools

    # Populate dashboard + sidebar and start the live refresh timer.
    try {
        Initialize-AtlasDashboard -Window $window
    } catch {
        Write-AtlasLog "Initialize-AtlasDashboard failed: $_" -Level WARN -Tool 'UI'
    }

    [void]$window.ShowDialog()
}
