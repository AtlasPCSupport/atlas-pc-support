#Requires -Modules Pester
Describe 'Native outcomes and copy coverage' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
    }
    It 'does not treat an empty copy sample as successful verification' {
        $source=Join-Path $TestDrive 'empty';New-Item -ItemType Directory -Path $source|Out-Null
        $result=Test-AtlasCopySample -Source $source -Destination $TestDrive
        $result.OK|Should -BeFalse;$result.State|Should -Be 'NotEvaluated'
    }
    It 'rejects recursive or identical copy destinations' {
        {Assert-AtlasCopyDestination -Source $TestDrive -Destination (Join-Path $TestDrive 'child')}|Should -Throw '*destination*'
        {Assert-AtlasCopyDestination -Source $TestDrive -Destination $TestDrive}|Should -Throw '*destination*'
    }
    It 'detects corruption and reports sampling scope' {
        $source=Join-Path $TestDrive 'src';$destination=Join-Path $TestDrive 'dest'
        New-Item -ItemType Directory -Path $source,$destination -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'one'),'source');[IO.File]::WriteAllText((Join-Path $destination 'one'),'corrupt')
        $result=Test-AtlasCopySample -Source $source -Destination $destination
        $result.OK|Should -BeFalse;$result.Failed|Should -Be 1;$result.Coverage|Should -Match 'not full'
    }
    It 'omits excluded directories and files from the verification scope' {
        $source=Join-Path $TestDrive 'excluded';$destination=Join-Path $TestDrive 'eligible-dest'
        New-Item -ItemType Directory -Path (Join-Path $source 'Cache'),$destination -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'Cache/missing'),'excluded')
        [IO.File]::WriteAllText((Join-Path $source 'missing.tmp'),'excluded')
        [IO.File]::WriteAllText((Join-Path $source 'keep.txt'),'included')
        [IO.File]::WriteAllText((Join-Path $destination 'keep.txt'),'included')
        $result=Test-AtlasCopySample -Source $source -Destination $destination -ExcludeDirs Cache -ExcludeFiles '*.tmp'
        $result.OK|Should -BeTrue;$result.Checked|Should -Be 1
    }
    It 'never reports a missing destination file as verified' {
        $source=Join-Path $TestDrive 'missing-src';New-Item -ItemType Directory -Path $source|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'one'),'source')
        (Test-AtlasCopySample -Source $source -Destination $TestDrive).Missing|Should -Be 1
    }
    It 'captures native stdout, stderr and nonzero status' {
        $engine=(Get-Process -Id $PID).Path
        $result=Invoke-AtlasNativeProcess -FilePath $engine -Arguments '-NoProfile -Command "Write-Output fixture; [Console]::Error.WriteLine(''fixture-error''); exit 9"' -TimeoutSeconds 20
        $result.State|Should -Be 'Failed';$result.ExitCode|Should -Be 9
        $result.Stdout|Should -Match 'fixture';$result.Stderr|Should -Match 'fixture-error'
    }
    It 'bounds an owned child and reports timeout distinctly' {
        $engine=(Get-Process -Id $PID).Path
        $result=Invoke-AtlasNativeProcess -FilePath $engine -Arguments '-NoProfile -Command "Start-Sleep -Seconds 20"' -TimeoutSeconds 1
        $result.TimedOut|Should -BeTrue;$result.State|Should -Be 'TimedOut'
    }
}

Describe 'Service restoration and dependent protection' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Operations.ps1')
        function Get-Service {[CmdletBinding()]param($Name)throw 'Real service blocked'}
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$Filter)throw 'Real CIM blocked'}
        function Set-Service {[CmdletBinding()]param($Name,$StartupType)throw 'Real service blocked'}
        function Start-Service {[CmdletBinding()]param($Name)throw 'Real service blocked'}
        function Stop-Service {[CmdletBinding()]param($Name)throw 'Real service blocked'}
        # Registry -Type is a Windows provider dynamic parameter; model it explicitly on Linux.
        function Set-ItemProperty {[CmdletBinding()]param($LiteralPath,$Name,$Value,$Type)throw 'Real registry blocked'}
    }
    BeforeEach {
        $script:Status='Running';$script:Mode='Auto';$script:Delayed=$null
        Mock Get-Service {[pscustomobject]@{Status=$script:Status;DependentServices=@()}}
        Mock Get-CimInstance {[pscustomobject]@{StartMode=$script:Mode}}
        Mock Get-ItemProperty {if($null -eq $script:Delayed){[pscustomobject]@{}}else{[pscustomobject]@{DelayedAutostart=$script:Delayed}}}
        Mock Set-Service {$script:Mode=@{Automatic='Auto';Manual='Manual';Disabled='Disabled'}[$StartupType]}
        Mock Start-Service {$script:Status='Running'}
        Mock Stop-Service {$script:Status='Stopped'}
        Mock Set-ItemProperty {$script:Delayed=$Value}
        Mock Remove-ItemProperty {$script:Delayed=$null}
    }
    It 'refuses to force-stop running dependents' {
        Mock Get-Service {[pscustomobject]@{Status='Running';DependentServices=@([pscustomobject]@{Status='Running'})}}
        {Get-AtlasServiceSnapshot -Name WSearch}|Should -Throw '*dependents*'
        Should -Invoke Stop-Service -Times 0 -Exactly
    }
    It 'does not invent a startup state if CIM fails' {
        Mock Get-CimInstance {throw 'Denied'}
        {Get-AtlasServiceSnapshot -Name WSearch}|Should -Throw '*Denied*'
    }
    It 'restores both previous startup and stopped state' {
        $script:Status='Stopped';$snapshot=Get-AtlasServiceSnapshot -Name WSearch
        $script:Status='Running';$script:Mode='Manual'
        Restore-AtlasServiceSnapshot $snapshot
        $script:Status|Should -Be 'Stopped';$script:Mode|Should -Be 'Auto'
    }
    It 'restores delayed-start presence and value exactly' {
        $script:Delayed=1;$snapshot=Get-AtlasServiceSnapshot -Name WSearch
        $script:Delayed=0;$script:Status='Stopped';$script:Mode='Manual'
        Restore-AtlasServiceSnapshot $snapshot
        $script:Delayed|Should -Be 1;$script:Status|Should -Be 'Running'
    }
    It 'rejects an invalid snapshot before mutation' {
        {Restore-AtlasServiceSnapshot ([pscustomobject]@{SchemaVersion=0;Name='WinDefend'})}|Should -Throw '*Invalid*'
        Should -Invoke Set-Service -Times 0 -Exactly
    }
}

Describe 'Diagnostic interpretation stays within evidence' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoEventos.ps1' '_Kb-Lookup')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoEventos.ps1' '_Query-Events')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-AuditoriaRouter.ps1' 'Obtener-SubredBase')
        function Get-WinEvent {[CmdletBinding()]param($FilterHashtable,$MaxEvents)throw 'Real event read blocked'}
        function Get-NetIPAddress {[CmdletBinding()]param($InterfaceIndex,$AddressFamily)throw 'Real network blocked'}
    }
    It 'never applies an ID-only rule from another provider' {
        $script:AtlasEventsKB=@{'*|*|18'=@{Title='Wrong'};'*|Microsoft-Windows-WHEA-Logger|18'=@{Title='WHEA fixture'}}
        (_Kb-Lookup System Microsoft-Windows-WHEA-Logger 18).Title|Should -Be 'WHEA fixture'
        _Kb-Lookup System UnrelatedProvider 18|Should -BeNullOrEmpty
    }
    It 'does not present denied event access as an empty healthy log' {
        Mock Get-WinEvent {throw 'Access denied'}
        {_Query-Events -LogName Security}|Should -Throw '*not evaluated*'
    }
    It 'refuses a fabricated /24 scan for a /25 or /16 interface' -ForEach @(@{Prefix=25},@{Prefix=16}) {
        Mock Get-NetIPAddress {[pscustomobject]@{PrefixLength=$Prefix;IPAddress='10.0.0.50'}}
        {Obtener-SubredBase -Gateway '10.0.0.1' -InterfaceIndex 1}|Should -Throw '*/24 only*'
    }
    It 'retains the qualified /24 legacy scan boundary' {
        Mock Get-NetIPAddress {[pscustomobject]@{PrefixLength=24;IPAddress='10.0.5.50'}}
        Obtener-SubredBase -Gateway '10.0.5.1' -InterfaceIndex 1|Should -Be '10.0.5'
    }
    It 'contains no global key-state capture in the focused keyboard test' {
        $text=[IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/tools/Invoke-KeyboardDoctor.ps1'))
        $text|Should -Not -Match 'GetAsyncKeyState'
        $text|Should -Match 'CapturedText=\$false'
    }
}

Describe 'Exact hosts changes and verified backup' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Release.ps1')
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Operations.ps1')
    }
    It 'removes only an exact alias and preserves other names and comments' {
        $text="127.0.0.1 example.test sibling.test # example.test comment`r`n127.0.0.1 sub.example.test`r`n# example.test"
        $after=Remove-AtlasHostsAlias -Text $text -Hostname example.test
        $after|Should -Match '127.0.0.1\s+sibling.test # example.test comment'
        $after|Should -Match 'sub.example.test';$after|Should -Match '# example.test'
    }
    It 'rejects newlines or options in a hosts name' {
        {Remove-AtlasHostsAlias -Text '' -Hostname "name`n0.0.0.0 evil"}|Should -Throw
    }
    It 'saves the exact original bytes before replacing hosts text' {
        $path=Join-Path $TestDrive 'hosts';$bytes=[byte[]](239,187,191,35,120,13,10)
        [IO.File]::WriteAllBytes($path,$bytes)
        $backup=Set-AtlasHostsText -Path $path -Text '127.0.0.1 localhost'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($backup))|Should -Be ([Convert]::ToBase64String($bytes))
        [IO.File]::ReadAllText($path)|Should -Be '127.0.0.1 localhost'
    }
}

Describe 'Scoped print queue cleanup' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Operations.ps1')
        function Get-Printer {[CmdletBinding()]param($Name)throw 'Printer blocked'}
        function Get-PrintJob {[CmdletBinding()]param($PrinterName)throw 'Printer blocked'}
        function Remove-PrintJob {[CmdletBinding()]param($PrinterName,$ID)throw 'Printer blocked'}
        function Stop-Service {[CmdletBinding()]param($Name)throw 'Real service blocked'}
    }
    It 'does not stop Spooler or delete the shared spool directory' {
        Mock Get-Printer {[pscustomobject]@{Name='Selected'}}
        $script:reads=0
        Mock Get-PrintJob {if($script:reads++ -eq 0){[pscustomobject]@{ID=1}}}
        Mock Remove-PrintJob { }
        Mock Stop-Service {throw 'Unexpected global service mutation'}
        Clear-AtlasPrintQueue -PrinterName Selected|Should -Be 1
        Should -Invoke Remove-PrintJob -Times 1 -Exactly -ParameterFilter {$PrinterName -eq 'Selected' -and $ID -eq 1}
        Should -Invoke Stop-Service -Times 0 -Exactly
    }
    It 'reports failure if selected jobs remain' {
        Mock Get-Printer {[pscustomobject]@{Name='Selected'}}
        Mock Get-PrintJob {[pscustomobject]@{ID=1}}
        Mock Remove-PrintJob { }
        {Clear-AtlasPrintQueue -PrinterName Selected}|Should -Throw '*incomplete*'
    }
}

Describe 'DNS origin and dual-family restoration' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Operations.ps1')
        function Get-NetAdapter {[CmdletBinding()]param($Name)throw 'Network blocked'}
        function Get-DnsClientServerAddress {[CmdletBinding()]param($InterfaceIndex,$AddressFamily)throw 'Network blocked'}
        function Set-DnsClientServerAddress {[CmdletBinding()]param($InputObject,$ServerAddresses,[switch]$ResetServerAddresses)throw 'Network blocked'}
        $script:Guid=[guid]'7c8188c0-a7ea-46d8-874c-58ec99bb0ce9'
    }
    BeforeEach {
        Mock Get-NetAdapter {[pscustomobject]@{Name='Ethernet';ifIndex=42;InterfaceGuid=[string]$script:Guid}}
        Mock Get-DnsClientServerAddress {[pscustomobject]@{AddressFamily=$AddressFamily;ServerAddresses=$(if($AddressFamily -eq 'IPv4'){@('1.1.1.1')}else{@('2606:4700:4700::1111')})}}
        Mock Get-ItemProperty {[pscustomobject]@{NameServer=$(if($LiteralPath -match 'Tcpip6') {''} else {'1.1.1.1'})}}
        Mock Set-DnsClientServerAddress { }
    }
    It 'backs up resolved addresses separately from automatic/static origin' {
        $path=Join-Path $TestDrive 'dns.json';Save-AtlasDnsSnapshot -AdapterNames Ethernet -Path $path|Out-Null
        $snapshot=Get-Content $path -Raw|ConvertFrom-Json
        @($snapshot.Adapters).Count|Should -Be 2
        ($snapshot.Adapters|Where-Object Family -eq IPv4).Automatic|Should -BeFalse
        ($snapshot.Adapters|Where-Object Family -eq IPv6).Automatic|Should -BeTrue
        Restore-AtlasDnsSnapshot -Path $path
        Should -Invoke Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {$ResetServerAddresses -and $InputObject.AddressFamily -eq 'IPv6'}
        Should -Invoke Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter {$ServerAddresses -contains '1.1.1.1' -and $InputObject.AddressFamily -eq 'IPv4'}
    }
    It 'blocks legacy backup with unknown source before any mutation' {
        $path=Join-Path $TestDrive 'legacy.json';[IO.File]::WriteAllText($path,'{"Ethernet":{"IPv4":["1.1.1.1"]}}')
        {Restore-AtlasDnsSnapshot -Path $path}|Should -Throw '*Legacy*'
        Should -Invoke Set-DnsClientServerAddress -Times 0 -Exactly
    }
    It 'blocks the entire restore if any row is malformed' {
        $path=Join-Path $TestDrive 'bad.json';Save-AtlasDnsSnapshot -AdapterNames Ethernet -Path $path|Out-Null
        $s=Get-Content $path -Raw|ConvertFrom-Json;$s.Adapters[1].Family='unknown';$s|ConvertTo-Json -Depth 8|Set-Content $path
        {Restore-AtlasDnsSnapshot -Path $path}|Should -Throw
        Should -Invoke Set-DnsClientServerAddress -Times 0 -Exactly
    }
}
