# Platform facts are collected read-only. Build and capabilities, never ProductName alone.
function Resolve-AtlasPlatform {
    [CmdletBinding()]
    param([int]$Build, [string]$EditionId, [int]$ProductType = 1, [string]$Architecture, [string[]]$Commands = @())
    $client = $ProductType -eq 1
    $baseline = $client -and $Build -ge 19044 -and $Architecture -eq 'x64'
    $is11 = $client -and $Build -ge 22000
    $ltsc = $EditionId -match 'EnterpriseS|IoTEnterpriseS'
    [pscustomobject]@{
        Build=$Build; EditionId=$EditionId; Architecture=$Architecture; Client=$client
        Windows11=$is11; LTSC=$ltsc; Baseline=$baseline
        SupportProfile= $(if (-not $baseline) {'Outside tested target'} elseif ($ltsc) {'LTSC capability-dependent'} elseif ($is11) {'Windows 11'} else {'Windows 10 22H2/LTSC target; VM qualification pending'})
        NativeDoh=($is11 -and $Commands -contains 'Get-DnsClientDohServerAddress' -and $Commands -contains 'Set-DnsClientDohServerAddress')
        BitLocker=($EditionId -notmatch '^Core' -and $Commands -contains 'Get-BitLockerVolume' -and $Commands -contains 'Enable-BitLocker')
        Commands=@($Commands)
    }
}

function Get-AtlasPlatformCapabilities {
    [CmdletBinding()]
    param([switch]$Refresh)
    if ($script:AtlasPlatformCapabilities -and -not $Refresh) { return $script:AtlasPlatformCapabilities }
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $edition = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name EditionID -ErrorAction Stop).EditionID
    $architecture = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $architecture = switch ($architecture) { 'AMD64' {'x64'} 'ARM64' {'arm64'} default {'x86'} }
    $names = @('Get-CimInstance','Get-WinEvent','Get-NetAdapter','Get-DnsClientServerAddress','Set-DnsClientServerAddress','Get-DnsClientDohServerAddress','Set-DnsClientDohServerAddress','Get-BitLockerVolume','Enable-BitLocker','Get-LocalUser','Get-LocalGroupMember','Get-AppxPackage','Add-AppxPackage','Get-WindowsOptionalFeature','Enable-WindowsOptionalFeature','Export-WindowsDriver','robocopy.exe','netsh.exe','dism.exe','sfc.exe')
    $available = @($names | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue })
    $script:AtlasPlatformCapabilities = Resolve-AtlasPlatform -Build ([int]$os.BuildNumber) -EditionId $edition -ProductType ([int]$os.ProductType) -Architecture $architecture -Commands $available
    return $script:AtlasPlatformCapabilities
}

function Test-AtlasToolAvailability {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Tool, $Capabilities)
    if (-not $Capabilities) { $Capabilities = Get-AtlasPlatformCapabilities }
    $reasons = @()
    if ($Tool.availability -and $Tool.availability.disabledReason) { $reasons += [string]$Tool.availability.disabledReason }
    if (-not $Capabilities.Baseline) { $reasons += 'Requires a Windows client build 19044+ on x64; this platform is outside the current target.' }
    if ($Tool.availability.minimumBuild -and $Capabilities.Build -lt [int]$Tool.availability.minimumBuild) { $reasons += "Requires build $($Tool.availability.minimumBuild) or newer." }
    foreach ($name in @($Tool.availability.commands)) {
        if ($name -and $Capabilities.Commands -notcontains $name) { $reasons += "Missing Windows capability: $name" }
    }
    if ($Tool.id -eq 'gestor-bitlocker' -and -not $Capabilities.BitLocker) { $reasons += 'Full BitLocker management is unavailable for this edition/modules. Device Encryption is managed in Windows Settings.' }
    [pscustomobject]@{ Available=($reasons.Count -eq 0); Reason=($reasons -join ' '); Profile=$Capabilities.SupportProfile }
}

function Assert-AtlasPackageRequest {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Package, [int]$Build)
    if ($Package.Type -eq 'Action') { throw 'Maintenance actions cannot be installed as packages.' }
    if ([string]$Package.Id -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._+-]{0,199}$') { throw 'Invalid package identifier; options and whitespace are not allowed.' }
    if ($Package.Source -and $Package.Source -cnotin @('winget','msstore')) { throw 'Unsupported package source.' }
    if ($Build -lt 19044) { throw 'Package installation is outside the supported Windows baseline.' }
    if ($Package.MinimumBuild -and $Build -lt [int]$Package.MinimumBuild) { throw 'Package requires a newer Windows build.' }
}

function Get-AtlasStoreState {
    [CmdletBinding()]
    param()
    $platform = Get-AtlasPlatformCapabilities
    $store = $null; $provisioned = $null; $errorMessage = $null
    try { $store = Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction Stop } catch { $errorMessage=$_.Exception.Message }
    if (-not $store) {
        try { $provisioned = @(Get-AppxPackage -AllUsers -Name Microsoft.WindowsStore -ErrorAction Stop) | Select-Object -First 1 }
        catch { $errorMessage=$_.Exception.Message }
    }
    $blocked = $false
    foreach ($path in @('HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore','HKCU:\SOFTWARE\Policies\Microsoft\WindowsStore')) {
        if (Test-Path -LiteralPath $path) {
            $policy = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
            if ($policy.RemoveWindowsStore -eq 1 -or $policy.DisableStoreApps -eq 1) { $blocked=$true }
        }
    }
    $appInstaller = $null
    try { $appInstaller=Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction Stop } catch { $errorMessage=$_.Exception.Message }
    [pscustomobject]@{
        State=$(if($blocked){'BlockedByPolicy'} elseif($store){'RegisteredForCurrentUser'} elseif($provisioned){'PresentNotRegisteredForCurrentUser'} elseif($errorMessage){'NotEvaluated'} else {'NotInstalled'})
        Store=$store; ExistingPackage=$provisioned; AppInstaller=$appInstaller
        WingetAvailable=[bool](Get-Command winget.exe -ErrorAction SilentlyContinue)
        LTSC=$platform.LTSC; Error=$errorMessage
    }
}
