#Requires -Modules Pester
Describe 'Windows client capability matrix' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Capabilities.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-SelectorDNS.ps1' 'Invoke-DoHToggle')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-Personalizacion.ps1' 'Apply-Win11Minimal')
        function Start-Process { param($FilePath) throw 'Real process blocked' }
        function Write-Centered { param($Text,$Color) }
    }
    It 'keeps the baseline for 22H2 and LTSC x64 without Store or WinGet' -ForEach @(@{Build=19045;Edition='Core'},@{Build=19045;Edition='Professional'},@{Build=19044;Edition='EnterpriseS'},@{Build=19044;Edition='IoTEnterpriseS'}) {
        $cap=Resolve-AtlasPlatform -Build $Build -EditionId $Edition -Architecture x64
        $cap.Baseline | Should -BeTrue
        $cap.NativeDoh | Should -BeFalse
    }
    It 'does not mistake Server or ARM/x86 for the x64 client baseline' -ForEach @(@{Build=20348;Arch='x64';Type=3},@{Build=19045;Arch='x86';Type=1},@{Build=26100;Arch='arm64';Type=1},@{Build=17763;Arch='x64';Type=1}) {
        (Resolve-AtlasPlatform -Build $Build -EditionId Professional -Architecture $Arch -ProductType $Type).Baseline | Should -BeFalse
    }
    It 'requires both OS and actual cmdlets for native DoH' {
        (Resolve-AtlasPlatform -Build 19045 -Architecture x64 -Commands @('Get-DnsClientDohServerAddress','Set-DnsClientDohServerAddress')).NativeDoh | Should -BeFalse
        (Resolve-AtlasPlatform -Build 26100 -Architecture x64).NativeDoh | Should -BeFalse
        (Resolve-AtlasPlatform -Build 26100 -Architecture x64 -Commands @('Get-DnsClientDohServerAddress','Set-DnsClientDohServerAddress')).NativeDoh | Should -BeTrue
    }
    It 'does not equate Home device encryption with full BitLocker management' {
        $commands=@('Get-BitLockerVolume','Enable-BitLocker')
        (Resolve-AtlasPlatform -Build 19045 -EditionId Core -Architecture x64 -Commands $commands).BitLocker | Should -BeFalse
        (Resolve-AtlasPlatform -Build 19045 -EditionId Professional -Architecture x64 -Commands $commands).BitLocker | Should -BeTrue
    }
    It 'explains unavailable commands before launching a tool' {
        $cap=Resolve-AtlasPlatform -Build 19045 -EditionId Professional -Architecture x64
        $result=Test-AtlasToolAvailability -Tool @{id='fixture';availability=@{commands=@('Get-LocalUser')}} -Capabilities $cap
        $result.Available | Should -BeFalse
        $result.Reason | Should -Match 'Get-LocalUser'
    }
    It 'keeps ordinary tools available without Store or winget' {
        $cap=Resolve-AtlasPlatform -Build 19044 -EditionId EnterpriseS -Architecture x64
        (Test-AtlasToolAvailability -Tool @{id='fixture'} -Capabilities $cap).Available | Should -BeTrue
    }
    It 'does not mutate registry or launch settings for DoH on Windows 10' {
        Mock Get-AtlasPlatformCapabilities { [pscustomobject]@{NativeDoh=$false} }
        Mock Start-Process { }
        Invoke-DoHToggle
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'blocks a typed Windows 11 tweak on Windows 10 before registry writes' {
        Mock Get-AtlasPlatformCapabilities { [pscustomobject]@{Windows11=$false} }
        Mock Set-ItemProperty { throw 'Unexpected registry change' }
        Apply-Win11Minimal
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
    }
    It 'rejects package option injection and unknown sources' -ForEach @(@{Id='--override';Source='winget'},@{Id='Vendor.App --silent';Source='winget'},@{Id='Vendor.App';Source='untrusted'},@{Id='a;b';Source='winget'}) {
        { Assert-AtlasPackageRequest -Package @{Id=$Id;Source=$Source} -Build 19045 } | Should -Throw
    }
    It 'accepts exact normal IDs and an explicit package OS minimum' {
        { Assert-AtlasPackageRequest -Package @{Id='Microsoft.VCRedist.2015+.x64';Source='winget'} -Build 19045 } | Should -Not -Throw
        { Assert-AtlasPackageRequest -Package @{Id='Vendor.App';MinimumBuild=22000} -Build 19045 } | Should -Throw '*newer*'
    }
    It 'uses a native NetFx3 path without requiring WinGet' {
        $text=[IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/tools/Invoke-InstalarRuntimes.ps1'))
        $text.IndexOf("if (`$choice -eq '3')") | Should -BeLessThan $text.IndexOf('$winget=Get-AtlasWingetPath')
        $text | Should -Match 'LimitAccess'
    }
}

Describe 'Store state differentiation' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Capabilities.ps1')
        function Get-AppxPackage { [CmdletBinding()] param($Name,[switch]$AllUsers) throw 'Real Appx blocked' }
    }
    BeforeEach {
        Mock Get-AtlasPlatformCapabilities { [pscustomobject]@{LTSC=$true} }
        Mock Test-Path { $false }
        Mock Get-Command { $null } -ParameterFilter {$Name -eq 'winget.exe'}
        Mock Get-AppxPackage { $null }
    }
    It 'distinguishes an absent package on LTSC without attempting installation' {
        $state=Get-AtlasStoreState
        $state.State | Should -Be 'NotInstalled'
        $state.LTSC | Should -BeTrue
    }
    It 'distinguishes missing per-user registration from absence' {
        Mock Get-AppxPackage { [pscustomobject]@{InstallLocation='fixture'} } -ParameterFilter { $AllUsers -and $Name -eq 'Microsoft.WindowsStore' }
        (Get-AtlasStoreState).State | Should -Be 'PresentNotRegisteredForCurrentUser'
    }
    It 'reports denied enumeration as not evaluated, not missing' {
        Mock Get-AppxPackage { throw 'Denied' }
        (Get-AtlasStoreState).State | Should -Be 'NotEvaluated'
    }
    It 'does not bypass an organizational Store policy' {
        Mock Test-Path { $true }
        Mock Get-ItemProperty { [pscustomobject]@{RemoveWindowsStore=1} }
        (Get-AtlasStoreState).State | Should -Be 'BlockedByPolicy'
    }
}
