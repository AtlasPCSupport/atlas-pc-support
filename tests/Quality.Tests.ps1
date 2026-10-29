#Requires -Modules Pester
BeforeAll {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/ToolKit.ps1')
}

Describe 'Router observation regression coverage' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        foreach($name in @('Compare-AtlasRouterObservations','Save-AtlasRouterBaseline','Get-AtlasRouterFirmwareVersion','Get-MACDesdeARP','Modulo-Escaneo')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-AuditoriaRouter.ps1' $name)}
        function Invoke-AtlasNativeProcess {[CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real network blocked'}
        function Obtener-Router {[pscustomobject]@{Gateway='192.0.2.1';InterfaceIndex=1}}
        function Obtener-SubredBase {param($Gateway,$InterfaceIndex)'192.0.2'}
        function Esperar-Enter {param([switch]$Silencioso)}
        function Get-Fabricante {param($MAC)'Fixture'}
        $script:RouterOriginalSystemRoot=$env:SystemRoot
    }
    BeforeEach {
        $script:ArchivoEstado=Join-Path $TestDrive ('baseline-'+[guid]::NewGuid().ToString('N')+'.txt')
        if(-not $env:SystemRoot){$env:SystemRoot=$TestDrive}
        Mock Write-Host {};Mock Clear-Host {};Mock Start-Sleep {}
    }
    AfterAll {$env:SystemRoot=$script:RouterOriginalSystemRoot}
    It 'separates MAC changes, equal observations, unknown identity, new and missing addresses' {
        $before=@{'192.0.2.1'=@{MAC='00:11:22:33:44:55'};'192.0.2.2'=@{MAC='00-11-22-33-44-66'};'192.0.2.3'=@{MAC='Desconocida'};'192.0.2.4'=@{MAC='00-11-22-33-44-77'}}
        $after=@{'192.0.2.1'=@{MAC='00-11-22-33-44-56'};'192.0.2.2'=@{MAC='00:11:22:33:44:66'};'192.0.2.3'=@{MAC='Desconocida'};'192.0.2.5'=@{MAC='00-11-22-33-44-88'}}
        $r=Compare-AtlasRouterObservations -Previous $before -Current $after
        $r.Changed.Count|Should -Be 1;$r.Changed[0].IP|Should -Be '192.0.2.1'
        $r.Unchanged|Should -Be @('192.0.2.2');$r.Uncertain|Should -Be @('192.0.2.3')
        $r.New|Should -Be @('192.0.2.5');$r.Missing|Should -Be @('192.0.2.4')
        (Compare-AtlasRouterObservations -Previous @{} -Current @{}).Changed.Count|Should -Be 0
    }
    It 'reads explicit firmware but refuses hardware-only, generic and ambiguous versions' {
        Get-AtlasRouterFirmwareVersion '<p>HW Version: 2.0</p><p>Firmware Version: 1.2.3 Build 20261001</p>'|Should -Be '1.2.3 Build 20261001'
        Get-AtlasRouterFirmwareVersion '{"firmwareVersion":"1.2.3"}'|Should -Be '1.2.3'
        foreach($html in @('HW Version: 2.0','Version: 1.2.3','Firmware Version: 1.2.3 Software Version: 2.3.4',('x'*524289))){Get-AtlasRouterFirmwareVersion $html|Should -BeNullOrEmpty}
    }
    It 'preserves a baseline on empty and failed scans and replaces a complete observation' {
        [IO.File]::WriteAllText($script:ArchivoEstado,'previous')
        $rows=@([pscustomobject]@{IP='192.0.2.1';MAC='00-11-22-33-44-55';Host='fixture'})
        Save-AtlasRouterBaseline -Observations @() -WarningAction SilentlyContinue|Should -BeFalse
        Save-AtlasRouterBaseline -Observations $rows -ScanErrors 1 -WarningAction SilentlyContinue|Should -BeFalse
        [IO.File]::ReadAllText($script:ArchivoEstado)|Should -Be previous
        Save-AtlasRouterBaseline -Observations $rows|Should -BeTrue
        [IO.File]::ReadAllText($script:ArchivoEstado)|Should -Be '192.0.2.1|00-11-22-33-44-55|fixture'
        @(Get-ChildItem -LiteralPath $TestDrive -Filter 'atlas-baseline-*.tmp').Count|Should -Be 0
    }
    It 'does not claim persistence for an invalid destination' {
        $script:ArchivoEstado=Join-Path $TestDrive 'missing/baseline.txt'
        Save-AtlasRouterBaseline -Observations @([pscustomobject]@{IP='192.0.2.1';MAC='Desconocida';Host='fixture'}) -WarningAction SilentlyContinue|Should -BeFalse
    }
    It 'bounds ARP and requires an exact IP and complete valid MAC result' {
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout="  192.0.2.10  00-11-22-33-44-55 dynamic`n  192.0.2.1  00-11-22-33-44-66 dynamic";StdoutTruncated=$false}}
        Get-MACDesdeARP '192.0.2.1'|Should -Be '00-11-22-33-44-66'
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {$TimeoutSeconds -eq 2 -and $ArgumentList[1] -eq '192.0.2.1'}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='TimedOut';Stdout='192.0.2.1 00-11-22-33-44-55 dynamic'}}
        Get-MACDesdeARP '192.0.2.1'|Should -Be Desconocida
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='192.0.2.1 00-11-22-33-44-55 dynamic';StdoutTruncated=$true}}
        Get-MACDesdeARP '192.0.2.1'|Should -Be Desconocida
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='192.0.2.1 FF-FF-FF-FF-FF-FF dynamic';StdoutTruncated=$false}}
        Get-MACDesdeARP '192.0.2.1'|Should -Be Desconocida
    }
    It 'runs the real scan with synthetic failures and disposes ping without losing the old baseline' {
        [IO.File]::WriteAllText($script:ArchivoEstado,'previous')
        $script:FakePing=[pscustomobject]@{Disposed=$false}
        $script:FakePing|Add-Member ScriptMethod Send {param($ip,$timeout)throw 'synthetic failure'}
        $script:FakePing|Add-Member ScriptMethod Dispose {$this.Disposed=$true}
        Mock New-Object {$script:FakePing} -ParameterFilter {$TypeName -eq 'System.Net.NetworkInformation.Ping'}
        $script:HistorialSesion=[Collections.Generic.List[string]]::new()
        Modulo-Escaneo -Silencioso -WarningAction SilentlyContinue|Out-Null
        $script:FakePing.Disposed|Should -BeTrue
        [IO.File]::ReadAllText($script:ArchivoEstado)|Should -Be previous
    }
}

Describe 'Runtime selection executes only requested packages' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Invoke-InstalarRuntimes','Resolve-AtlasLegacyRuntimeSelection')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-InstalarRuntimes.ps1' $name)}
        function Write-AtlasHeader {param($Title)}
        function Wait-AtlasExit {}
        function Get-AtlasWingetPath {'fixture-winget.exe'}
        function Invoke-AtlasNativeProcess {[CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds,$SuccessCodes)throw 'Real installer blocked'}
    }
    BeforeEach {Mock Write-Host {};Mock Wait-AtlasExit {};Mock Get-AtlasWingetPath {'fixture-winget.exe'}}
    It 'deduplicates IDs and rejects a malformed selection entirely' {
        @(Resolve-AtlasLegacyRuntimeSelection '1, 3,1')|Should -Be @('Microsoft.VCRedist.2013.x64','Microsoft.DirectX')
        foreach($selection in @('1,6','all','1;3','--override','1,')){{Resolve-AtlasLegacyRuntimeSelection $selection}|Should -Throw}
        @(Resolve-AtlasLegacyRuntimeSelection '').Count|Should -Be 0
    }
    It 'cancels before WinGet if selection is empty' {
        Mock Read-Host {if($Prompt -like 'Only required*'){''}else{'2'}}
        Mock Invoke-AtlasNativeProcess {throw 'No installation'}
        Invoke-InstalarRuntimes
        Should -Invoke Get-AtlasWingetPath -Times 0 -Exactly
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
    It 'installs and verifies only the chosen package through the real menu flow' {
        Mock Read-Host {if($Prompt -like 'Only required*'){'3'}elseif($Prompt -like 'Type INSTALL*'){'INSTALL'}else{'2'}}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';ExitCode=0;Stdout='Microsoft.DirectX';StdoutTruncated=$false}}
        Invoke-InstalarRuntimes
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {$ArgumentList[0] -eq 'install' -and $ArgumentList[2] -eq 'Microsoft.DirectX' -and $TimeoutSeconds -eq 1800}
        Should -Invoke Invoke-AtlasNativeProcess -Times 2 -Exactly
    }
    It 'stops a selection after interruption without starting the next installer: <State>' -ForEach @(@{State='TimedOut'},@{State='Cancelled'}) {
        Mock Read-Host {if($Prompt -like 'Only required*'){'1,3'}elseif($Prompt -like 'Type INSTALL*'){'INSTALL'}else{'2'}}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State=$State;ExitCode=$null}}
        Invoke-InstalarRuntimes -WarningAction SilentlyContinue
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly
    }
}

Describe 'Audit phase 4: bounded copy census and destination continuity' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-FastCopy.ps1' 'Test-CopyIntegrity')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-FastCopy.ps1' 'Start-FastCopy')
        function _Write-AtlasStepCompat {param($Message,$FallbackColor)}
    }
    It 'keeps only the requested ordinal sample while counting every eligible file' {
        $source=Join-Path $TestDrive 'many';New-Item -ItemType Directory -Path $source|Out-Null
        foreach($i in 0..1001){[IO.File]::WriteAllText((Join-Path $source ('f{0:d4}.txt' -f $i)),'fixture')}
        $r=Get-AtlasCopyInventory -Source $source -SampleSize 5
        $r.Files|Should -Be 1002;$r.Sample.Count|Should -Be 5;$r.Sample[0].Name|Should -Be 'f0000.txt'
        $r.Sample[4].Name|Should -Be 'f0004.txt';$r.Complete|Should -BeTrue
    }
    It 'includes hidden files, applies name exclusions and can skip the census explicitly' {
        $source=Join-Path $TestDrive 'hidden';New-Item -ItemType Directory -Path (Join-Path $source 'excluded') -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $source '.hidden.txt'),'fixture')
        [IO.File]::WriteAllText((Join-Path $source 'skip.tmp'),'fixture')
        [IO.File]::WriteAllText((Join-Path $source 'excluded/skip.txt'),'fixture')
        if($env:OS -eq 'Windows_NT'){[IO.File]::SetAttributes((Join-Path $source '.hidden.txt'),[IO.FileAttributes]::Hidden)}
        $r=Get-AtlasCopyInventory -Source $source -ExcludeFiles '*.tmp' -ExcludeDirs excluded -SampleSize 5
        $r.Files|Should -Be 1;$r.Sample[0].Name|Should -Be '.hidden.txt'
        $r=Get-AtlasCopyInventory -Source $source -SkipCensus -FileAction {throw 'Scan must be skipped'}
        $r.Files|Should -BeNullOrEmpty;$r.Size|Should -BeNullOrEmpty;$r.Complete|Should -BeFalse
    }
    It 'marks an unreadable subtree as incomplete instead of healthy empty data' {
        $source=Join-Path $TestDrive 'denied';$child=Join-Path $source 'blocked'
        New-Item -ItemType Directory -Path $child -Force|Out-Null
        Mock Assert-AtlasPlainDirectory {if($Path -eq $child){throw 'Access denied fixture'}}
        $r=Get-AtlasCopyInventory -Source $source
        $r.Complete|Should -BeFalse;$r.UnverifiedPaths|Should -Be 1
    }
    It 'continues the chosen existing backup rather than appending another date' {
        $source=Join-Path $TestDrive 'source';$existing=Join-Path $TestDrive 'Backup_2026-10-20'
        New-Item -ItemType Directory -Path $source,$existing|Out-Null
        Resolve-AtlasBackupDestination -DefaultDirectory (Join-Path $TestDrive 'Backup_2026-10-27') -ExistingDirectory $existing -Sources @($source)|Should -Be $existing
        {Resolve-AtlasBackupDestination -DefaultDirectory $existing -ExistingDirectory $source -Sources @($source)}|Should -Throw '*destination*'
    }
    It 'counts changed size/date as candidates, including an older source, without equating metadata to hashes' {
        $source=Join-Path $TestDrive 'metadata';$dest=Join-Path $TestDrive 'backup'
        New-Item -ItemType Directory -Path $source,(Join-Path $dest 'metadata') -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'file.txt'),'source')
        [IO.File]::WriteAllText((Join-Path $dest 'metadata/file.txt'),'different')
        [IO.File]::SetLastWriteTimeUtc((Join-Path $source 'file.txt'),[datetime]'2020-01-01')
        $r=Compare-AtlasCopyMetadata -Source $source -Destination $dest
        $r.Modified|Should -Be 1;$r.Equal|Should -Be 0;$r.Scope|Should -Match 'not content integrity'
    }
    It 'verifies the actual FastCopy folder layout rather than the destination parent' {
        $source=Join-Path $TestDrive 'FastSource';$dest=Join-Path $TestDrive 'FastDestination'
        New-Item -ItemType Directory -Path $source,(Join-Path $dest 'FastSource') -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'file.txt'),'fixture')
        Copy-Item -LiteralPath (Join-Path $source 'file.txt') -Destination (Join-Path $dest 'FastSource/file.txt')
        (Test-CopyIntegrity -Origen $source -Destino $dest).OK|Should -BeTrue
    }
    It 'rejects an invalid second FastCopy source before creating any destination or launching a process' {
        $source=Join-Path $TestDrive 'safe';New-Item -ItemType Directory -Path $source|Out-Null
        Mock Write-Host {};Mock New-Item {throw 'No write before validation'};Mock Invoke-AtlasNativeProcess {throw 'No process before validation'}
        {Start-FastCopy -Origins @($source,$TestDrive) -Destino (Join-Path $TestDrive 'child') -Mode INCREMENTAL}|Should -Throw '*destination*'
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
}

Describe 'Audit phase 4: one dependency executable and complete resources' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Write-AtlasLog {param($Message,$Tool,$Level)}
        function Expand-AtlasPath {param($Path)$Path}
        foreach($name in @('Resolve-AtlasDependency','Resolve-SymlinkPath','Get-AtlasDependencyCandidate')){. (Get-TestFunction $script:RepoRoot 'src/lib/Dependencies.ps1' $name)}
    }
    It 'selects one real application when PATH contains multiple matches' {
        $first=Join-Path $TestDrive 'first.exe';$second=Join-Path $TestDrive 'second.exe'
        [IO.File]::WriteAllText($first,'fixture');[IO.File]::WriteAllText($second,'fixture')
        $script:AtlasDepsRegistry=@{Fixture=@{SearchPaths=@();ExecutableName='fixture.exe'}}
        Mock Get-Command {@([pscustomobject]@{Source=$first},[pscustomobject]@{Source=$second})}
        Resolve-AtlasDependency -Name Fixture|Should -Be $first
        Should -Invoke Get-Command -Times 1 -Exactly -ParameterFilter {$CommandType -eq 'Application'}
    }
    It 'does not accept CrystalDiskInfo with a missing or empty resource directory' {
        $exe=Join-Path $TestDrive 'DiskInfo64.exe';[IO.File]::WriteAllText($exe,'fixture')
        Get-AtlasDependencyCandidate -Name CrystalDiskInfo -Path $exe|Should -BeNullOrEmpty
        New-Item -ItemType Directory -Path (Join-Path $TestDrive 'CdiResource')|Out-Null
        Get-AtlasDependencyCandidate -Name CrystalDiskInfo -Path $exe|Should -BeNullOrEmpty
        [IO.File]::WriteAllText((Join-Path $TestDrive 'CdiResource/res.dat'),'resource')
        Get-AtlasDependencyCandidate -Name CrystalDiskInfo -Path $exe|Should -Be $exe
    }
}

Describe 'Audit phase 4: per-package USB evidence and no retry' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Get-UsbDependencyRows','Register-UsbInstallerFiles','Download-FastCopy')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PrepararUSB.ps1' $name)}
        function Write-Centered {param($Text,$Color)}
    }
    BeforeEach {
        $script:AtlasUsbVerifiedPackages=@{};$script:AtlasUsbVerifiedFiles=@{};$script:AtlasUsbAttemptFailures=@{}
        $script:PS7_VERSION='7.6.9';$script:FASTCOPY_URL='https://example.invalid/fixture'
        $script:Usb=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:Usb|Out-Null
    }
    It 'does not treat GPU-Z alone as a ready GPU group or an unqualified executable as verified' {
        $folder=Join-Path $script:Usb 'deps/GPUCheck/tools';New-Item -ItemType Directory -Path $folder -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $folder 'GPU-Z.exe'),'fixture')
        $rows=@(Get-UsbDependencyRows -Root $script:Usb)
        ($rows|Where-Object Key -eq 'GPU/GPUZ').State|Should -Be PresentNotEvaluated
        @($rows|Where-Object {$_.Group -eq 'GPU' -and $_.State -notin @('CopiedAndHashVerified','RecordedFilesVerified')}).Count|Should -Be 3
    }
    It 'detects a missing Crystal resource independently of the executable' {
        $folder=Join-Path $script:Usb 'deps/DiagnosticoMaster/tools/CrystalDiskInfo';New-Item -ItemType Directory -Path $folder -Force|Out-Null
        [IO.File]::WriteAllText((Join-Path $folder 'DiskInfo64.exe'),'fixture')
        (Get-UsbDependencyRows -Root $script:Usb|Where-Object Key -eq 'Diag/CrystalDiskInfo').State|Should -Be MissingOrIncomplete
    }
    It 'rechecks every recorded resource after transport and detects a same-length change' {
        $folder=Join-Path $script:Usb 'deps/GPUCheck/tools/FurMark2_x64';New-Item -ItemType Directory -Path $folder -Force|Out-Null
        foreach($name in @('furmark.exe','resource.dat')){[IO.File]::WriteAllText((Join-Path $folder $name),'fixture')}
        Register-UsbInstallerFiles -Key 'GPU/FurMark2' -Directory $folder
        $rows=@(Get-UsbDependencyRows -Root $script:Usb)
        ($rows|Where-Object Key -eq 'GPU/FurMark2').State|Should -Be CopiedAndHashVerified
        @{SchemaVersion=1;Packages=$rows}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $script:Usb 'usb-dependency-status.json') -Encoding UTF8
        $script:AtlasUsbVerifiedPackages=@{};$script:AtlasUsbVerifiedFiles=@{}
        (Get-UsbDependencyRows -Root $script:Usb|Where-Object Key -eq 'GPU/FurMark2').State|Should -Be RecordedFilesVerified
        [IO.File]::WriteAllText((Join-Path $folder 'resource.dat'),'changed')
        (Get-UsbDependencyRows -Root $script:Usb|Where-Object Key -eq 'GPU/FurMark2').State|Should -Be ChangedOrNotEvaluated
    }
    It 'does not execute another installer after FastCopy extraction times out' {
        Mock Invoke-WebRequest {[IO.File]::WriteAllText($OutFile,'fixture installer')}
        Mock Get-AtlasDependencyDefinition {[pscustomobject]@{DownloadSha256=('0'*64)}}
        Mock Assert-AtlasInstaller {}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='TimedOut';ExitCode=0}}
        Mock Register-UsbInstallerFiles {throw 'No verified extraction'}
        Download-FastCopy -AppsDir (Join-Path $script:Usb 'apps')|Should -BeFalse
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly
        Should -Invoke Register-UsbInstallerFiles -Times 0 -Exactly
        $script:AtlasUsbAttemptFailures.FastCopy|Should -BeTrue
    }
}

Describe 'Audit phase 3: verified local policies and reversible UAC' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$OperationTimeoutSec)throw 'Real inventory blocked'}
        function Invoke-AtlasNativeProcess {param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real policy mutation blocked'}
        $script:OriginalPolicySystemRoot=$env:SystemRoot
        if(-not $env:SystemRoot){$env:SystemRoot=$TestDrive}
    }
    AfterAll {$env:SystemRoot=$script:OriginalPolicySystemRoot}
    BeforeEach {
        $script:Policy=[pscustomobject]@{MinPasswordLength=8;MaxPasswordAge=90;MinPasswordAgeSeconds=0;LockoutThreshold=5}
        Mock Get-AtlasLocalAccountPolicy {$script:Policy}
        Mock Get-CimInstance {[pscustomobject]@{PartOfDomain=$false;DomainRole=0}}
        Mock Invoke-AtlasNativeProcess {throw 'Policy mutation needs a fixture'}
        Mock Write-Host {}
    }
    It 'validates every policy value before launching a native process' {
        {Set-AtlasLocalAccountPolicy -Values @{MinPasswordLength=10;LockoutThreshold='3 /domain'} -SnapshotPath (Join-Path $TestDrive 'invalid.json')}|Should -Throw '*Invalid*'
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
        Should -Invoke Get-CimInstance -Times 0 -Exactly
    }
    It 'blocks domain-managed computers without a policy mutation' {
        Mock Get-CimInstance {[pscustomobject]@{PartOfDomain=$true;DomainRole=1}}
        {Set-AtlasLocalAccountPolicy -Values @{MinPasswordLength=10} -SnapshotPath (Join-Path $TestDrive 'domain.json')}|Should -Throw '*domain-managed*'
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
    It 'preserves recovery values and stops after a failed native result' {
        $path=Join-Path $TestDrive 'partial.json'
        Mock Invoke-AtlasNativeProcess {
            if($ArgumentList[1] -like '/minpwlen:*'){$script:Policy.MinPasswordLength=10;return [pscustomobject]@{State='Correct';ExitCode=0}}
            [pscustomobject]@{State='Failed';ExitCode=5;Stdout='denied';Stderr=''}
        }
        {Set-AtlasLocalAccountPolicy -Values @{MinPasswordLength=10;MaxPasswordAge=60;LockoutThreshold=4} -SnapshotPath $path}|Should -Throw '*1 verified*'
        (Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).Before.MinPasswordLength|Should -Be 8
        Should -Invoke Invoke-AtlasNativeProcess -Times 2 -Exactly
    }
    It 'does not count native success without a matching policy readback' {
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';ExitCode=0}}
        {Set-AtlasLocalAccountPolicy -Values @{MinPasswordLength=10} -SnapshotPath (Join-Path $TestDrive 'mismatch.json')}|Should -Throw '*readback differs*'
    }
    It 'maps the existing zero-expiration UI to UNLIMITED and verifies it' {
        Mock Invoke-AtlasNativeProcess {$script:Policy.MaxPasswordAge='UNLIMITED';[pscustomobject]@{State='Correct';ExitCode=0}}
        $r=Set-AtlasLocalAccountPolicy -Values @{MaxPasswordAge=0} -SnapshotPath (Join-Path $TestDrive 'unlimited.json')
        $r.VerifiedChanges|Should -Be 1
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {$ArgumentList[1] -eq '/maxpwage:UNLIMITED'}
    }
}

Describe 'Audit phase 3: UAC snapshot boundaries' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
    }
    BeforeEach {
        $script:UacValues=@{EnableLUA=1;ConsentPromptBehaviorUser=3;ConsentPromptBehaviorAdmin=5}
        $key=[pscustomobject]@{}
        $key|Add-Member ScriptMethod GetValueKind {param($name)'DWord'}
        Mock Get-Item {$key} -ParameterFilter {$LiteralPath -like 'HKLM:*'}
        Mock Get-ItemProperty {[pscustomobject]$script:UacValues.Clone()}
        Mock New-ItemProperty {$script:UacValues[$Name]=[int]$Value}
        Mock Remove-ItemProperty {foreach($n in $Name){$script:UacValues.Remove($n)}}
        Mock Write-Host {}
    }
    It 'saves before the preset and restores absent and existing values' {
        $path=Join-Path $TestDrive 'uac.json'
        Set-AtlasUacPreset -SnapshotPath $path
        $script:UacValues.ConsentPromptBehaviorAdmin|Should -Be 2
        Restore-AtlasUacSnapshot -Path $path
        $script:UacValues.ConsentPromptBehaviorAdmin|Should -Be 5
        $script:UacValues.ContainsKey('PromptOnSecureDesktop')|Should -BeFalse
    }
    It 'rejects unknown keys before the first write' {
        $s=Get-AtlasUacSnapshot
        $s.Values[3].Name='UnrelatedPolicy'
        {Set-AtlasUacValues -Snapshot $s}|Should -Throw '*Invalid UAC*'
        Should -Invoke New-ItemProperty -Times 0 -Exactly
        Should -Invoke Remove-ItemProperty -Times 0 -Exactly
    }
    It 'preserves a snapshot and reports a partial preset on denied writes' {
        $path=Join-Path $TestDrive 'uac-denied.json'
        Mock New-ItemProperty {throw 'Registry denied'}
        {Set-AtlasUacPreset -SnapshotPath $path}|Should -Throw '*incomplete*Recovery snapshot*'
        Test-Path -LiteralPath $path|Should -BeTrue
    }
}

Describe 'Audit phase 3: complete driver export evidence' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-RespaldoControladores.ps1' 'Invoke-RespaldoControladores')
        function Test-IsAdmin {throw 'Real token query blocked'}
        function Export-WindowsDriver {[CmdletBinding()]param([switch]$Online,$Destination)throw 'Real export blocked'}
        function Invoke-AtlasNativeProcess {param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real DISM blocked'}
    }
    It 'records every member and detects same-length CAT corruption' {
        $dir=Join-Path $TestDrive 'driver export'
        New-Item -ItemType Directory -Path (Join-Path $dir 'package') -Force|Out-Null
        foreach($name in @('driver.inf','driver.cat','driver.sys')){[IO.File]::WriteAllText((Join-Path $dir "package/$name"),'fixture')}
        Push-Location $TestDrive
        try {Write-AtlasDriverManifest -Directory 'driver export'|Out-Null} finally {Pop-Location}
        $m=Test-AtlasDriverManifest -Directory $dir
        $m.FileCount|Should -Be 3;$m.InfCount|Should -Be 1;$m.RestorationTested|Should -BeFalse
        [IO.File]::WriteAllText((Join-Path $dir 'package/driver.cat'),'changed')
        {Test-AtlasDriverManifest -Directory $dir}|Should -Throw '*verification failed*'
    }
    It 'rejects empty export and does not mix a previous attempt' {
        $dir=Join-Path $TestDrive 'empty';New-Item -ItemType Directory -Path $dir|Out-Null
        {Write-AtlasDriverManifest -Directory $dir}|Should -Throw '*No driver INF*'
        [IO.File]::WriteAllText((Join-Path $dir 'driver.inf'),'fixture')
        Write-AtlasDriverManifest -Directory $dir|Out-Null
        {Write-AtlasDriverManifest -Directory $dir}|Should -Throw '*already exists*'
    }
    It 'does not run a second exporter or announce success after a partial cmdlet failure' {
        Mock Test-IsAdmin {$true};Mock Write-Host {}
        Mock Export-WindowsDriver {[IO.File]::WriteAllText((Join-Path $Destination 'partial.inf'),'partial');throw 'Export failed'}
        Mock Invoke-AtlasNativeProcess {throw 'DISM must not run'}
        Invoke-RespaldoControladores -DestinationPath $TestDrive
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter {"$Object" -like '*file hashes verified*'}
    }
}

Describe 'Audit phase 3: idempotent hosts block and exact restoration' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
    }
    It 'preserves personal aliases and does not append a list twice' {
        $path=Join-Path $TestDrive 'hosts'
        [IO.File]::WriteAllText($path,'127.0.0.1 personal.test')
        $list=@('127.0.0.1 localhost','fe80::1%lo0 localhost','0.0.0.0 ads.example.test','0.0.0.0 ADS.example.test') -join [Environment]::NewLine
        $r=Set-AtlasManagedHostsBlock -Path $path -ListText $list -Source 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts'
        $r.Changed|Should -BeTrue;$r.Entries|Should -Be 1
        $r=Set-AtlasManagedHostsBlock -Path $path -ListText $list -Source 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts'
        $r.Changed|Should -BeFalse
        [IO.File]::ReadAllText($path)|Should -Match 'personal.test'
    }
    It 'rejects malformed or redirecting input before changing hosts' {
        $path=Join-Path $TestDrive 'hosts-bad';[IO.File]::WriteAllText($path,'# untouched')
        {Set-AtlasManagedHostsBlock -Path $path -ListText '1.2.3.4 bank.example.test' -Source 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts'}|Should -Throw
        [IO.File]::ReadAllText($path)|Should -Be '# untouched'
    }
    It 'restores exact original bytes including BOM and newline convention' {
        $path=Join-Path $TestDrive 'hosts-bytes'
        $bytes=[byte[]](239,187,191,35,120,13,10);[IO.File]::WriteAllBytes($path,$bytes)
        $backup=Set-AtlasHostsText -Path $path -Text '0.0.0.0 ads.example.test'
        Restore-AtlasHostsBackup -Path $path -Backup $backup|Out-Null
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))|Should -Be ([Convert]::ToBase64String($bytes))
    }
}

Describe 'Audit phase 2: shared memory and cautious PartsUpgrade output' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PartsUpgrade.ps1' 'Invoke-PartsUpgrade')
        function Get-PhysicalDisk {[CmdletBinding()]param() throw 'Real disks blocked'}
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$OperationTimeoutSec) throw 'Real hardware blocked'}
        function Write-AtlasShareableReport {param($Path,$Content,$Tool) throw 'Real report blocked'}
        $script:OriginalLang=$env:ATLAS_LANG;$env:ATLAS_LANG='en'
        $script:PartsEnvironment=@{}
        foreach($name in @('LOCALAPPDATA','APPDATA')) {
            $script:PartsEnvironment[$name]=[Environment]::GetEnvironmentVariable($name)
            [Environment]::SetEnvironmentVariable($name,$TestDrive)
        }
    }
    AfterAll {
        $env:ATLAS_LANG=$script:OriginalLang
        foreach($name in $script:PartsEnvironment.Keys) {[Environment]::SetEnvironmentVariable($name,$script:PartsEnvironment[$name])}
    }
    It 'sums complete arrays and prefers extended capacity while preserving missing data' {
        $modules=@([pscustomobject]@{Capacity=8GB},[pscustomobject]@{Capacity=8GB})
        $arrays=@([pscustomobject]@{Use=3;MaxCapacity=1;MaxCapacityEx=64MB;MemoryDevices=2},[pscustomobject]@{Use=3;MaxCapacity=32MB;MemoryDevices=2})
        $r=Get-AtlasMemorySummary -Modules $modules -Arrays $arrays
        $r.TotalGB|Should -Be 16;$r.MaxGB|Should -Be 96;$r.SlotsTotal|Should -Be 4;$r.SlotsFree|Should -Be 2
        $r=Get-AtlasMemorySummary -Modules @([pscustomobject]@{}) -Arrays @()
        $r.TotalGB|Should -BeNullOrEmpty;$r.MaxGB|Should -BeNullOrEmpty;$r.SlotsTotal|Should -BeNullOrEmpty
        (Get-AtlasMemorySummary -Modules $modules -Arrays @([pscustomobject]@{MemoryDevices=1})).SlotsFree|Should -BeNullOrEmpty
    }
    It 'runs the real Parts report without inferring generation, XMP, BGA or unknown capacities: <Missing>' -ForEach @(@{Missing=$false},@{Missing=$true}) {
        Mock Get-CimInstance {
            switch($ClassName) {
                Win32_PhysicalMemoryArray {[pscustomobject]@{Use=3;MaxCapacityEx=64MB;MemoryDevices=2}}
                Win32_PhysicalMemory {if($Missing){throw 'Denied'};[pscustomobject]@{Capacity=8GB;Speed=3200;ConfiguredClockSpeed=2666;SMBIOSMemoryType=26;FormFactor=12}}
                Win32_Processor {[pscustomobject]@{Name='Intel Core i7-8700';UpgradeMethod=6;SocketDesignation='Unknown';NumberOfCores=6;NumberOfLogicalProcessors=12}}
                default {}
            }
        }
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';Size=$null;HealthStatus=0;BusType='SATA';MediaType='Unknown'}}
        Mock Read-Host {'2'};Mock Wait-AtlasExit {};Mock Start-Process {};Mock Clear-Host {};Mock Write-Host {}
        Mock Get-AtlasReportDir {$TestDrive}
        Mock Write-AtlasShareableReport {$script:PartsHtml=$Content}
        Invoke-PartsUpgrade
        $script:PartsHtml|Should -Not -Match 'Intel Gen 87|XMP OFF|Soldada \(BGA\)|None/BGA|<!-- SHA256:'
        $script:PartsHtml|Should -Match 'None \(SMBIOS\)|not verified|no verificada'
        $script:PartsHtml|Should -Match 'N/D GB';$script:PartsHtml|Should -Match 'Healthy'
        if($Missing){
            $script:PartsHtml|Should -Match 'no capacity-based purchase advice'
            $script:PartsHtml|Should -Not -Match 'RAM Insufficient'
            $script:PartsHtml|Should -Match 'Slots libres</span><span[^>]*>N/D'
        }
    }
}

Describe 'Audit phase 2: unavailable printer and keyboard queries are not empty successes' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Get-PDPrinters','Get-PDPorts','Get-PDDrivers','Get-PDSpooler','Get-PDJobs','Get-PDPrintEvents','Invoke-PDQuickDiagnosis','Add-Finding')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PrinterDoctor.ps1' $name)
        }
        foreach($name in @('Get-KDDevicesByClass','Get-KDKeyboardDevices','Get-KDPointingDevices','Get-KDAccessibility','Get-KDBattery','Get-KDEvents','Get-KDMonitorCount','Invoke-KDQuickDiagnosis','Add-KDFinding')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-KeyboardDoctor.ps1' $name)
        }
        function Get-PDSystemInfo {}
        function Get-KDSystemInfo {}
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$OperationTimeoutSec,$Filter) throw 'Real hardware blocked'}
        function Get-WinEvent {[CmdletBinding()]param($FilterHashtable,$MaxEvents) throw 'Real events blocked'}
    }
    BeforeEach {
        $script:L=@{FindingNoPrinter='ABSENT_PRINTER';RecNoPrinter='Repair';FindingNoSpooler='STOPPED_SPOOLER';RecNoSpooler='Restart';FindingNoKeyboard='ABSENT_KEYBOARD';RecNoKeyboard='Repair';FindingOk='NO_FINDINGS';RecOk='Review';ResultObs='Observation'}
        $script:PrinterDoctorReport=@{Coverage=@{};Findings=@();Recommendations=@()}
        $script:KeyboardDoctorReport=@{Coverage=@{};Findings=@();Recommendations=@();Manual=@{};Monitor=@()}
        Mock Get-Command {$null} -ParameterFilter {$Name -eq 'Get-PrinterPort'}
        Mock Get-ItemProperty {throw 'Registry denied'}
    }
    It 'keeps denied queries out of absent-device and stopped-service findings' {
        Mock Get-CimInstance {throw 'Access denied'};Mock Get-WinEvent {throw 'Access denied'}
        Invoke-PDQuickDiagnosis|Out-Null
        $script:PrinterDoctorReport.Coverage.Printers|Should -Be NotEvaluated
        $script:PrinterDoctorReport.Findings|Should -Not -Contain 'ABSENT_PRINTER'
        $script:PrinterDoctorReport.Findings|Should -Not -Contain 'STOPPED_SPOOLER'
        Invoke-KDQuickDiagnosis|Out-Null
        $script:KeyboardDoctorReport.Coverage.Keyboard|Should -Be NotEvaluated
        @($script:KeyboardDoctorReport.Findings|Where-Object Finding -eq 'ABSENT_KEYBOARD').Count|Should -Be 0
        $script:KeyboardDoctorReport.Battery.Present|Should -BeNullOrEmpty
        @($script:KeyboardDoctorReport.Accessibility|Where-Object {$null -eq $_.Enabled}).Count|Should -Be 3
    }
    It 'distinguishes a successful empty inventory and a no-matching-events exception' {
        Mock Get-CimInstance {};Mock Get-WinEvent {Write-Error 'No events' -ErrorId NoMatchingEventsFound -ErrorAction Stop}
        Invoke-PDQuickDiagnosis|Out-Null
        $script:PrinterDoctorReport.Coverage.Events|Should -Be Observed
        $script:PrinterDoctorReport.Findings|Should -Contain 'ABSENT_PRINTER'
        Invoke-KDQuickDiagnosis|Out-Null
        $script:KeyboardDoctorReport.Coverage.Keyboard|Should -Be Observed
        @($script:KeyboardDoctorReport.Findings|Where-Object Finding -eq 'ABSENT_KEYBOARD').Count|Should -Be 1
    }
    It 'does not combine capacity rows or manufacture wear when several batteries exist' {
        Mock Get-CimInstance {@([pscustomobject]@{Name='A';EstimatedChargeRemaining=0},[pscustomobject]@{Name='B';EstimatedChargeRemaining=80})}
        $r=Get-KDBattery
        $r.WearPercent|Should -BeNullOrEmpty;$r.EstimatedChargeRemaining|Should -BeNullOrEmpty
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {$ClassName -eq 'Win32_Battery' -and $OperationTimeoutSec -eq 10}
    }
}

Describe 'Audit phase 2: real GPU scoring branches and event coverage' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Get-GpuSessionLevel','Get-GpuEventAssessment','Clean-Number','Find-Col')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GPUCheck.ps1' $name)
        }
        $source=[IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/tools/Invoke-GPUCheck.ps1'))
        $start=$source.IndexOf('    $gpuzScore = 0');$end=$source.IndexOf('    if ($notes.Count -eq 0)', $start)
        $script:GpuScoring=[scriptblock]::Create($source.Substring($start,$end-$start))
        function Import-CsvAuto {param($Path) throw 'Real telemetry file blocked'}
    }
    It 'uses numeric event severity and does not attribute unrelated WHEA or ID 141 to GPU' {
        $events=@([pscustomobject]@{ProviderName='Display';Level=2;LevelDisplayName='Error localizado';Id=7},[pscustomobject]@{ProviderName='Microsoft-Windows-WHEA-Logger';Level=2;Id=141})
        $r=Get-GpuEventAssessment $events
        $r.ErrorCritical|Should -Be 1;$r.Whea|Should -Be 1;$r.TdrLike|Should -Be 0;$r.Score|Should -Be 25
        (Get-GpuEventAssessment @($events[1])).Score|Should -Be 0
    }
    It 'preserves a critical measured temperature and refuses a clean verdict without events: <Evaluated>' -ForEach @(@{Evaluated=$true},@{Evaluated=$false}) {
        Mock Import-CsvAuto {1..3|ForEach-Object {[pscustomobject]@{'GPU Temperature'=95}}} -ParameterFilter {$Path -eq 'gpuz-fixture'}
        Mock Import-CsvAuto {} -ParameterFilter {$Path -eq 'nvidia-fixture'}
        $gpuzLog='gpuz-fixture';$nvidiaCsv='nvidia-fixture';$events=@();$notes=[Collections.Generic.List[string]]::new()
        $eventRead=@{State=$(if($Evaluated){'Observed'}else{'NotEvaluated'})};$skipStress=$false;$sessionStatus='Completed'
        . $script:GpuScoring
        $total|Should -Be 70;$level|Should -Be 'RIESGO ALTO'
        Get-GpuSessionLevel -Total 0 -HasTelemetry $true -StressRequested $true -SessionStatus Completed -EventsEvaluated $false|Should -Be 'NO CONCLUYENTE'
    }
}

Describe 'Audit phase 1: classic DNS and aggregate keyboard evidence' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Assert-ClassicDNSAddresses','Apply-DNS')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-SelectorDNS.ps1' $name)
        }
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-KeyboardDoctor.ps1' 'Get-KDMonitorCount')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-KeyboardDoctor.ps1' 'Invoke-KDQuickDiagnosis')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-KeyboardDoctor.ps1' 'Add-KDFinding')
        function Get-KDSystemInfo {}
        function Get-KDKeyboardDevices {[pscustomobject]@{Status='OK'}}
        function Get-KDPointingDevices {}
        function Get-KDAccessibility {}
        function Get-KDBattery {}
        function Get-KDEvents {param($Days)}
        function Save-AtlasDnsSnapshot {param($AdapterNames,$Path) throw 'Real network changes blocked'}
    }
    It 'rejects retired encrypted-only addresses before a DNS snapshot or change: <Address>' -ForEach @(
        @{Address='194.242.2.2'},@{Address='194.242.2.9'},@{Address='2a07:e340:0:0:0:0:0:4'}
    ) {
        Mock Save-AtlasDnsSnapshot {throw 'Snapshot must not be reached'}
        {Apply-DNS -AdapterNames Fixture -Addresses $Address -Label Fixture}|Should -Throw '*Mullvad*'
        Should -Invoke Save-AtlasDnsSnapshot -Times 0 -Exactly
    }
    It 'keeps DHCP and supported classic DNS choices available and rejects malformed input' {
        {Assert-ClassicDNSAddresses @()}|Should -Not -Throw
        {Assert-ClassicDNSAddresses @('1.1.1.1','2606:4700:4700::1111')}|Should -Not -Throw
        {Assert-ClassicDNSAddresses @('not-an-address')}|Should -Throw '*Invalid*'
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-SelectorDNS.ps1'
        $profiles=$ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$dnsProfiles'},$true)
        . ([scriptblock]::Create($profiles.Extent.Text))
        foreach($key in @('9','10','11','12','13','14')) {$dnsProfiles.Keys|Should -Not -Contain $key}
    }
    It 'counts actual focused-window events rather than the number of monitor records: <Count>' -ForEach @(@{Count=0},@{Count=1},@{Count=17}) {
        Get-KDMonitorCount @([pscustomobject]@{Scope='FocusedWindow';Count=$Count;CapturedText=$false})|Should -Be $Count
        Get-KDMonitorCount @()|Should -Be 0
        Get-KDMonitorCount @([pscustomobject]@{Time='legacy';Key='fixture'})|Should -Be 0
    }
    It 'uses the aggregate in the real quick diagnosis: <Count>' -ForEach @(@{Count=0},@{Count=17}) {
        $script:L=@{FindingMonitor='Monitor events {0}';RecMonitor='Observe';FindingOk='No findings';RecOk='Review';ResultObs='Observation'}
        $script:KeyboardDoctorReport=@{Manual=@{};Monitor=@([pscustomobject]@{Scope='FocusedWindow';Count=$Count});Findings=@();Recommendations=@();Result=''}
        Invoke-KDQuickDiagnosis|Out-Null
        $findings=@($script:KeyboardDoctorReport.Findings|Where-Object Finding -like 'Monitor events *')
        if($Count -eq 0){$findings.Count|Should -Be 0}
        else {$findings.Count|Should -Be 1;$findings[0].Finding|Should -Be "Monitor events $Count"}
    }
}

Describe 'Audit phase 1: private AI report export with explicit baseline ID' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        foreach($name in @('Export-AIRReport','New-AIRTable','ConvertTo-AIRHtml')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-AIReadiness.ps1' $name)
        }
        function Get-AtlasReportDir {param($SubFolder) throw 'Real report directory blocked'}
    }
    BeforeEach {
        $script:AiRoot=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [void](New-Item -ItemType Directory -Path $script:AiRoot)
        Mock Get-AtlasReportDir {$script:AiRoot}
        $script:L=@{ReportTitle='Fixture';NoData='No data'};$script:lang='en'
        $script:AiReport=[ordered]@{ClientName='Al';ConsultantName='Bo';Score=50;Verdict='Fixture';RecommendedMode='Fixture';Generated='2026-10-27';RAM=@{TotalGB=16};CPU=@{Name='Fixture CPU';Cores=4;LogicalProcessors=8};Scores=@{RAM=17;CPU=14;GPU=0;Storage=15;Stack=0};GPU=@();Disks=@();Stack=@();Connectivity=@();Findings=@();Recommendations=@();ModelRecommendations=@()}
    }
    It 'masks short identity fields in JSON/HTML and uses an opaque directory' {
        $paths=Export-AIRReport -Report $script:AiReport
        $paths.ReportId|Should -Match '^[a-f0-9]{32}$'
        Split-Path (Split-Path $paths.Json -Parent) -Leaf|Should -Be $paths.ReportId
        $json=Get-Content -LiteralPath $paths.Json -Raw|ConvertFrom-Json
        $json.ClientName|Should -Be '[REDACTED]';$json.ConsultantName|Should -Be '[REDACTED]'
        $html=[IO.File]::ReadAllText($paths.Html)
        $html|Should -Match '\[REDACTED\]';$html|Should -Not -Match '>Al<|>Bo<'
    }
    It 'compares only a deliberately reused valid ID and ignores client-name directories' {
        $script:AiReport.ClientName='..'
        $first=Export-AIRReport -Report $script:AiReport
        $script:AiReport.Score=60
        $second=Export-AIRReport -Report $script:AiReport -ReportId $first.ReportId
        $second.Json|Should -Be $first.Json
        $data=Get-Content -LiteralPath $second.Json -Raw|ConvertFrom-Json
        $data.Delta.HasPrevious|Should -BeTrue;$data.Delta.ScoreChange|Should -Be '10'
        {Export-AIRReport -Report $script:AiReport -ReportId '..'}|Should -Throw '*Report ID*'
        {Export-AIRReport -Report $script:AiReport -ReportId 'CON'}|Should -Throw '*Report ID*'
    }
}
Describe 'Diagnostic HTML text boundaries' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $translations=$ast.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$T'},$true)
        . ([scriptblock]::Create($translations.Extent.Text))
        $script:L=$T.en
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' 'Fmt-Line')
        $script:CpuzKeywords=[scriptblock]::Create(($ast.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$keywords'},$true)).Extent.Text)
        $script:CpuzLoop=[scriptblock]::Create(($ast.Find({param($n) $n -is [System.Management.Automation.Language.ForEachStatementAst] -and $n.Variable.Extent.Text -eq '$line' -and $n.Condition.Extent.Text -eq '$lines'},$true)).Extent.Text)
        $script:HeaderParts=foreach($var in @('$reportTitle','$htmlHead','$html')) {
            $node=$ast.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq $var -and ($var -ne '$html' -or $n.Right.Extent.Text -match '^\$htmlHead')},$true)
            [scriptblock]::Create($node.Extent.Text)
        }
    }
    It 'encodes native inventory labels and values while preserving the owned span' {
        $html=Fmt-Line '<script>label</script>' '<img src=x> A&B'
        $html|Should -Not -Match '<script>|<img '
        $html|Should -Match '<span class='; $html|Should -Match '&amp;'
    }
    It 'encodes CPU-Z text and temperature lines without losing section formatting' {
        $lines=@('Processors Information','Name <script>cpu</script>','Temperature 90 degC <img src=x>','Chipset','Manufacturer A&B')
        $cleanText='';$currentSection='';$startLog=$false;$isStorageSection=$false;$isGraphicsSection=$false
        . $script:CpuzKeywords
        . $script:CpuzLoop
        $cleanText|Should -Not -Match '<script>|<img '
        $cleanText|Should -Match '&lt;script&gt;|A&amp;B'
        $cleanText|Should -Match 'color:#dc3545'
        $cleanText|Should -Match 'categoria-resaltada'
    }
    It 'encodes title, identity and system text while retaining owned HTML sections' {
        $aliasPC='<script>client</script>';$pc='<img src=x>';$txtSys='A&B <script>system</script>'
        $css='';$fechaReporte='fixture';$yearReporte='2026'
        $htmlHardware='<p>Owned fixture</p>'
        foreach($name in @('htmlCPU','htmlRAM','htmlStorage','htmlNet','htmlBsod','htmlBat','htmlGpuTriage','htmlUpgrade')) {Set-Variable -Name $name -Value ''}
        foreach($part in $script:HeaderParts){. $part}
        $html|Should -Not -Match '<script>|<img '
        $html|Should -Match 'A&amp;B'
        $html|Should -Match '<p>Owned fixture</p>'
    }
}

Describe 'PowerShell executable resolution' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/lib/PS7.ps1' 'Get-AtlasPS7Path')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-ActualizarPowerShell.ps1' '_Get-PS7Path')
    }
    It 'returns one executable when PATH exposes multiple installations: <Function>' -TestCases @(
        @{Function='Get-AtlasPS7Path'},@{Function='_Get-PS7Path'}
    ) {
        param($Function)
        Mock Get-Command {
            [pscustomobject]@{Path='C:\fixture first\pwsh.exe'}
            [pscustomobject]@{Path='C:\fixture second\pwsh.exe'}
        } -ParameterFilter {$Name -eq 'pwsh.exe' -and $CommandType -eq 'Application'}
        $paths=@(& $Function)
        $paths.Count|Should -Be 1
        $paths[0]|Should -Be 'C:\fixture first\pwsh.exe'
    }
}

Describe 'Battery capacity and status stay within reported evidence' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $translations=$ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$T'},$true)
        . ([scriptblock]::Create($translations.Extent.Text))
        $script:BatteryLabels=$T.en
        $script:BatteryOriginalTemp=$env:TEMP;$script:BatteryOriginalSystemRoot=$env:SystemRoot
        # These exporters are mocked. Give Linux CI isolated Windows-path roots too.
        $env:TEMP=$TestDrive;$env:SystemRoot=$TestDrive
        foreach($name in @('ConvertTo-DiagBatteryNumber','ConvertFrom-DiagBatteryExport','Get-BatteryAnalysis')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' $name)
        }
        function Start-ProcessWithTimeout { param($FilePath,$Arguments,$TimeoutSeconds,$ExpectedOutput) throw 'Real process blocked' }
        function Get-CimInstance { [CmdletBinding()]param($ClassName,$OperationTimeoutSec) throw 'Real inventory blocked' }
        $script:BatteryFixtureExe=Join-Path $TestDrive 'BatteryInfoView.exe'
        [IO.File]::WriteAllText($script:BatteryFixtureExe,'Not executable; fixture only')
    }
    AfterAll {
        $env:TEMP=$script:BatteryOriginalTemp;$env:SystemRoot=$script:BatteryOriginalSystemRoot
    }
    BeforeEach {
        $script:L=$script:BatteryLabels
        $script:BatteryXml='<BatteryReport><Batteries><Battery><DesignCapacity>57000</DesignCapacity><FullChargeCapacity>51000</FullChargeCapacity><Manufacturer>Fixture</Manufacturer><Chemistry>LIon</Chemistry></Battery></Batteries></BatteryReport>'
        $script:BatteryText="Designed Capacity : 57,000 mWh`nFull Charged Capacity : 51,000 mWh`nNumber of charge/discharge cycles : N/A"
        $script:BatteryStatuses=@();$script:BatteryNativeSuccess=$true;$script:BatteryVendorSuccess=$true;$script:BatteryPaths=@()
        Mock Get-CimInstance { $script:BatteryStatuses }
        Mock Start-ProcessWithTimeout {
            $script:BatteryPaths += $ExpectedOutput
            if($FilePath -like '*powercfg.exe') {
                [IO.File]::WriteAllText($ExpectedOutput,$script:BatteryXml,[Text.UTF8Encoding]::new($false))
                return $script:BatteryNativeSuccess
            }
            [IO.File]::WriteAllText($ExpectedOutput,$script:BatteryText,[Text.Encoding]::Unicode)
            return $script:BatteryVendorSuccess
        }
    }
    It 'parses whole grouped mWh values without truncating them and leaves absent cycles unknown' {
        $row=ConvertFrom-DiagBatteryExport -Text $script:BatteryText -Format NirsoftText
        $row.DesignCapacity|Should -Be 57000;$row.FullChargeCapacity|Should -Be 51000
        $row.CycleCount|Should -BeNullOrEmpty
    }
    It 'does not turn invalid, ambiguous or unsupported numeric data into a capacity: <Value>' -TestCases @(
        @{Value=''},@{Value='N/A'},@{Value='-1'},@{Value='57,00'},@{Value='57.000'},@{Value='1.5'},@{Value='NaN'},@{Value='Infinity'},@{Value='4294967295'}
    ) {
        param($Value)
        ConvertTo-DiagBatteryNumber $Value | Should -BeNullOrEmpty
    }
    It 'retains an explicitly reported zero cycle count but not unsupported zero design capacity' {
        ConvertTo-DiagBatteryNumber '0' -AllowZero | Should -Be 0
        ConvertTo-DiagBatteryNumber '0' | Should -BeNullOrEmpty
    }
    It 'rejects duplicate text capacity fields rather than pairing different batteries' {
        {ConvertFrom-DiagBatteryExport -Text ($script:BatteryText+"`nDesigned Capacity : 10000") -Format NirsoftText}|Should -Throw '*Ambiguous*'
    }
    It 'keeps multiple namespaced battery rows separate and never divides unmatched capacities' {
        $script:BatteryXml='<BatteryReport xmlns="urn:fixture"><Batteries><Battery><DesignCapacity>100</DesignCapacity><FullChargeCapacity>80</FullChargeCapacity></Battery><Battery><FullChargeCapacity>70</FullChargeCapacity></Battery></Batteries></BatteryReport>'
        $result=Get-BatteryAnalysis
        $result.Batteries.Count|Should -Be 2
        $result.Batteries[0].CapacityRatioPercent|Should -Be 80
        $result.Batteries[1].DesignCapacity|Should -BeNullOrEmpty
        $result.Batteries[1].CapacityRatioPercent|Should -BeNullOrEmpty
        $result.Batteries[0].CycleCount|Should -BeNullOrEmpty
    }
    It 'rejects malformed XML and external entity declarations' {
        {ConvertFrom-DiagBatteryExport '<BatteryReport>' PowercfgXml}|Should -Throw
        {ConvertFrom-DiagBatteryExport '<!DOCTYPE BatteryReport [<!ENTITY x SYSTEM "file:///not-read">]><BatteryReport>&x;</BatteryReport>' PowercfgXml}|Should -Throw
    }
    It 'does not infer charging or zero percent from AC-available status' {
        $script:BatteryStatuses=@([pscustomobject]@{BatteryStatus=2;EstimatedChargeRemaining=$null})
        $result=Get-BatteryAnalysis
        $result.StatusRows[0].Status|Should -Be $L.BatStAc
        $result.StatusRows[0].ChargePercent|Should -BeNullOrEmpty
        $result.HtmlSection|Should -Not -Match '\(0%\)'
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {$OperationTimeoutSec -eq 10}
    }
    It 'preserves reported zero charge while rejecting a percentage above 100' {
        $script:BatteryStatuses=@([pscustomobject]@{BatteryStatus=1;EstimatedChargeRemaining=0},[pscustomobject]@{BatteryStatus=3;EstimatedChargeRemaining=101})
        $result=Get-BatteryAnalysis
        $result.StatusRows[0].ChargePercent|Should -Be 0
        $result.StatusRows[1].ChargePercent|Should -BeNullOrEmpty
        $result.HtmlSection|Should -Not -Match '101%|100%'
    }
    It 'maps charging-critical and undefined status separately' {
        $script:BatteryStatuses=@([pscustomobject]@{BatteryStatus=9},[pscustomobject]@{BatteryStatus=10},[pscustomobject]@{BatteryStatus=11})
        $result=Get-BatteryAnalysis
        $result.StatusRows[0].Status|Should -Be $L.BatStCha
        $result.StatusRows[1].Status|Should -Be $L.UnknownLbl
        $result.StatusRows[2].Status|Should -Be $L.BatStPart
    }
    It 'uses the existing utility fallback with BOM-detected text and cleans only its new reports' {
        $script:BatteryNativeSuccess=$false
        $result=Get-BatteryAnalysis -BatteryInfoViewPath $script:BatteryFixtureExe
        $result.Source|Should -Be 'BatteryInfoView'
        $result.Batteries[0].DesignCapacity|Should -Be 57000
        $result.Batteries[0].CycleCount|Should -BeNullOrEmpty
        $script:BatteryPaths.Count|Should -Be 2
        @($script:BatteryPaths | Select-Object -Unique).Count|Should -Be 2
        Should -Invoke Start-ProcessWithTimeout -Times 2 -Exactly -ParameterFilter {$ExpectedOutput -and $TimeoutSeconds -eq 15}
        foreach($path in $script:BatteryPaths){Test-Path -LiteralPath $path|Should -BeFalse}
    }
    It 'rejects output left by failed exporters instead of reporting a measured battery' {
        $script:BatteryNativeSuccess=$false;$script:BatteryVendorSuccess=$false
        $result=Get-BatteryAnalysis -BatteryInfoViewPath $script:BatteryFixtureExe
        $result.CapacityState|Should -Be Unavailable
        $result.Batteries.Count|Should -Be 0
    }
    It 'keeps capacity findings if Windows status is denied' {
        Mock Get-CimInstance {throw 'Fixture access denied'}
        $result=Get-BatteryAnalysis
        $result.CapacityState|Should -Be Observed
        $result.StatusState|Should -Be Unavailable
        $result.Batteries[0].FullChargeCapacity|Should -Be 51000
    }
    It 'distinguishes an empty report from an export failure without assuming absent batteries' {
        $script:BatteryXml='<BatteryReport><Batteries/></BatteryReport>'
        $result=Get-BatteryAnalysis
        $result.CapacityState|Should -Be Empty
        $result.HtmlSection|Should -Match 'not evaluated'
    }
    It 'encodes battery identity and does not label reported ratios as proof of physical health or authenticity' {
        $script:BatteryXml='<BatteryReport><Batteries><Battery><DesignCapacity>100</DesignCapacity><FullChargeCapacity>110</FullChargeCapacity><CycleCount>0</CycleCount><Manufacturer>&lt;script&gt;battery&lt;/script&gt;</Manufacturer><Chemistry>A&amp;B</Chemistry></Battery></Batteries></BatteryReport>'
        $result=Get-BatteryAnalysis
        $result.Batteries[0].CapacityRatioPercent|Should -Be 110
        $result.Batteries[0].CycleCount|Should -Be 0
        $result.HtmlSection|Should -Not -Match '<script>|#5cb85c|#FF8C00|\(\?\)'
        $result.HtmlSection|Should -Match '&lt;script&gt;|A&amp;B'
    }
}

Describe 'CPU and network inventory without performance or upgrade guesses' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $translations=$ast.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$T'},$true)
        . ([scriptblock]::Create($translations.Extent.Text))
        $script:L=$T.en
        foreach($name in @('Get-CPUUpgradeInfo','Get-UpgradeAdvisor','Get-NetworkProfile')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' $name)
        }
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$OperationTimeoutSec) throw 'Real inventory blocked'}
    }
    It 'does not derive measured performance or a generation from <CpuName>' -ForEach @(@{CpuName='Fixture Unknown CPU'},@{CpuName='Intel Core i7-8700'},@{CpuName='AMD Ryzen 7 5800X'}) {
        Mock Get-CimInstance {[pscustomobject]@{Name=$CpuName;NumberOfCores=8;NumberOfLogicalProcessors=16;UpgradeMethod=2;SocketDesignation='Unknown'}}
        $cpu=Get-CPUUpgradeInfo
        $cpu.Generation|Should -BeNullOrEmpty
        $cpu.IsSoldered|Should -BeNullOrEmpty
        $cpu.ScoreLabel|Should -Be $L.CpuUnmeasured
        $advice=Get-UpgradeAdvisor -RAMData @{TotalGB=16} -CPUData $cpu -StorageData @{HasNVMe=$true} -OSCaption 'Windows 11'
        $advice.Score|Should -BeNullOrEmpty
        @($advice.Recommendations|Where-Object Area -eq CPU).Count|Should -Be 0
        $advice.HtmlSection|Should -Not -Match 'COMPUTER IN GOOD SHAPE'
    }
    It 'does not equate a mobile suffix or UpgradeMethod None with proven BGA' -ForEach @(@{Code=2},@{Code=6},@{Code=64}) {
        Mock Get-CimInstance {
            if($ClassName -eq 'Win32_Processor'){[pscustomobject]@{Name='Fixture 1234U';UpgradeMethod=$Code;SocketDesignation='Unknown'}}
            else{[pscustomobject]@{ChassisTypes=@(9)}}
        }
        $cpu=Get-CPUUpgradeInfo
        $cpu.IsSoldered|Should -BeNullOrEmpty
        $cpu.HtmlSection|Should -Match ([regex]::Escape($L.CpuServiceManual))
        $cpu.HtmlSection|Should -Not -Match 'LGA1700|None/BGA|Not replaceable|SOCKETED - Replaceable'
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {$ClassName -eq 'Win32_Processor' -and $OperationTimeoutSec -eq 10}
    }
    It 'marks denied or empty CPU inventory as not evaluated' -ForEach @(@{Denied=$true},@{Denied=$false}) {
        Mock Get-CimInstance {if($Denied){throw 'Access denied'}}
        $cpu=Get-CPUUpgradeInfo
        $cpu.State|Should -Be NotEvaluated
        $cpu.Summary|Should -Be $L.NoCpuInfo
        $cpu.IsSoldered|Should -BeNullOrEmpty
    }
    It 'keeps all reported processor rows and encodes firmware strings' {
        Mock Get-CimInstance {@([pscustomobject]@{Name='<script>fixture</script>';SocketDesignation='<img src=x>';UpgradeMethod=2},[pscustomobject]@{Name='Second CPU';SocketDesignation='A&B';UpgradeMethod=6})}
        $cpu=Get-CPUUpgradeInfo
        $cpu.ProcessorCount|Should -Be 2
        $cpu.HtmlSection|Should -Match 'Second CPU|&lt;script&gt;|A&amp;B'
        $cpu.HtmlSection|Should -Not -Match '<script>|<img '
    }
    It 'distinguishes denied networking inventory from no enabled adapters' {
        Mock Get-CimInstance {throw 'Access denied'}
        (Get-NetworkProfile).State|Should -Be NotEvaluated
        Mock Get-CimInstance { }
        (Get-NetworkProfile).State|Should -Be Observed
    }
    It 'retains both IP families and encodes every network value for HTML' {
        Mock Get-CimInstance {[pscustomobject]@{IPEnabled=$true;Description='<script>adapter</script>';IPAddress=@('2001:db8::1','192.0.2.1');MACAddress='<img src=x>';DefaultIPGateway=@('2001:db8::2','192.0.2.2');DNSServerSearchOrder=@('A&B')}}
        $network=Get-NetworkProfile
        $network.HtmlSection|Should -Not -Match '<script>|<img '
        $network.HtmlSection|Should -Match '2001:db8::1, 192.0.2.1'
        $network.HtmlSection|Should -Match '2001:db8::2, 192.0.2.2'
        $network.HtmlSection|Should -Match 'A&amp;B'
        $network.TextSummary|Should -Match '<script>adapter</script>'
    }
    It 'does not declare all Windows 10 editions out of support from their caption' -ForEach @(@{Caption='Windows 10 Home'},@{Caption='Windows 10 Enterprise LTSC'}) {
        $advice=Get-UpgradeAdvisor -RAMData @{TotalGB=16} -CPUData @{} -StorageData @{HasNVMe=$true} -OSCaption $Caption
        $advice.Score|Should -BeNullOrEmpty
        $advice.HtmlSection|Should -Not -Match 'End of support Oct 2025|good shape'
        $advice.Recommendations.Action|Should -Contain $L.OsActWin10
        $advice.HtmlSection|Should -Match 'edition|Edition'
    }
}

Describe 'RAM evidence and cautious upgrade advice' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $translations=$ast.Find({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$T'},$true)
        . ([scriptblock]::Create($translations.Extent.Text))
        $script:L=$T.en; $script:lang='en'
        foreach($name in @('Get-RAMDiagnostic','Get-UpgradeAdvisor')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' $name)
        }
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$OperationTimeoutSec) throw 'Real inventory blocked'}
        $script:CpuFixture=@{State='Observed'}
        $script:DiskFixture=@{HasNVMe=$true;HasHDD=$false;HasSATASSD=$false;CriticalSpace=$false}
    }
    BeforeEach {
        Mock Get-CimInstance {
            switch($ClassName) {
                Win32_PhysicalMemoryArray {[pscustomobject]@{MemoryDevices=4;MaxCapacity=32MB;MaxCapacityEx=64MB}}
                Win32_PhysicalMemory {[pscustomobject]@{Capacity=8GB;FormFactor=12;Speed=3200;ConfiguredClockSpeed=2666;DeviceLocator='DIMM1'}}
                Win32_SystemEnclosure {[pscustomobject]@{ChassisTypes=@(9)}}
            }
        }
    }
    It 'does not infer an active channel from <Count> populated memory devices' -ForEach @(@{Count=1},@{Count=2},@{Count=3}) {
        Mock Get-CimInstance {1..$Count|ForEach-Object {[pscustomobject]@{Capacity=8GB;FormFactor=12}}} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $ram.IsDualChannel|Should -BeNullOrEmpty
        $ram.ChannelLabel|Should -Be $L.RamChannelUnknown
        $ram.TextSummary|Should -Not -Match 'Single Channel|Dual Channel'
        $advice=Get-UpgradeAdvisor -RAMData $ram -CPUData $script:CpuFixture -StorageData $script:DiskFixture -OSCaption 'Windows 11'
        @($advice.Recommendations|Where-Object Area -eq RAM).Count|Should -Be 0
    }
    It 'does not call an unknown laptop form factor soldered or removable' {
        Mock Get-CimInstance {[pscustomobject]@{Capacity=8GB;FormFactor=0}} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $ram.Modules[0].IsSoldered|Should -BeNullOrEmpty
        $ram.AllSoldered|Should -BeFalse
        $ram.HtmlSection|Should -Not -Match 'UPGRADABLE:'
    }
    It 'reports a rate difference without claiming XMP state' {
        $ram=Get-RAMDiagnostic
        $ram.Modules[0].XMPStatus|Should -Be $L.RamXmpUnknown
        $ram.HtmlSection|Should -Not -Match 'XMP off|LOW \('
        $ram.Modules[0].Speed|Should -Be 2666
        $ram.Modules[0].NativeSpeed|Should -Be 3200
    }
    It 'prefers extended maximum capacity and includes multiple system memory arrays' {
        Mock Get-CimInstance {@([pscustomobject]@{MemoryDevices=2;MaxCapacity=32MB;MaxCapacityEx=64MB;Use=3},[pscustomobject]@{MemoryDevices=2;MaxCapacity=32MB;MaxCapacityEx=64MB;Use=3},[pscustomobject]@{MemoryDevices=8;MaxCapacityEx=1TB;Use=4})} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemoryArray'}
        $ram=Get-RAMDiagnostic
        $ram.MaxCapGB|Should -Be 128
        $ram.SlotsTotal|Should -Be 4
    }
    It 'preserves installed capacity if the array query fails' {
        Mock Get-CimInstance {throw 'Array denied'} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemoryArray'}
        $ram=Get-RAMDiagnostic
        $ram.TotalGB|Should -Be 8
        $ram.SlotsTotal|Should -Be 0
        $ram.HasFreeSlots|Should -BeFalse
    }
    It 'uses the legacy capacity only when extended capacity is unavailable' {
        Mock Get-CimInstance {[pscustomobject]@{MemoryDevices=2;MaxCapacity=32MB;MaxCapacityEx=0;Use=3}} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemoryArray'}
        (Get-RAMDiagnostic).MaxCapGB|Should -Be 32
    }
    It 'does not score partial capacity or count an unknown device as removable' {
        Mock Get-CimInstance {@([pscustomobject]@{Capacity=8GB;FormFactor=12},[pscustomobject]@{Capacity=0;FormFactor=0})} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $ram.TotalGB|Should -BeNullOrEmpty
        $ram.Modules[1].CapacityGB|Should -BeNullOrEmpty
        $ram.Modules[1].IsSoldered|Should -BeNullOrEmpty
    }
    It 'still reports observed limited capacity with model-specific purchasing advice' {
        Mock Get-CimInstance {[pscustomobject]@{Capacity=2GB;FormFactor=12}} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $advice=Get-UpgradeAdvisor -RAMData $ram -CPUData $script:CpuFixture -StorageData $script:DiskFixture -OSCaption 'Windows 11'
        $advice.Score|Should -BeNullOrEmpty
        $finding=@($advice.Recommendations|Where-Object Area -eq RAM)
        $finding.Count|Should -Be 1
        $finding[0].Action|Should -Match 'Verify'
        $finding[0].Cost|Should -Match 'verification'
    }
    It 'does not treat missing modules as zero RAM or score the incomplete advisor' -ForEach @(@{Mode='Empty'},@{Mode='Denied'},@{Mode='MissingCapacity'}) {
        Mock Get-CimInstance {
            if($Mode -eq 'Denied'){throw 'Memory denied'}
            if($Mode -eq 'MissingCapacity'){[pscustomobject]@{FormFactor=12}}
        } -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $ram.TotalGB|Should -BeNullOrEmpty
        $advice=Get-UpgradeAdvisor -RAMData $ram -CPUData $script:CpuFixture -StorageData $script:DiskFixture -OSCaption 'Windows 11'
        $advice.Score|Should -BeNullOrEmpty
        @($advice.Recommendations|Where-Object Area -eq RAM).Count|Should -Be 0
        $advice.HtmlSection|Should -Not -Match 'COMPUTER IN GOOD SHAPE'
        $advice.HtmlSection|Should -Match ([regex]::Escape($L.RamIncomplete))
    }
    It 'encodes device strings in RAM HTML without altering inventory values' {
        Mock Get-CimInstance {[pscustomobject]@{Capacity=8GB;FormFactor=12;DeviceLocator='<script>slot</script>';Manufacturer='A&B';PartNumber='<img src=x>'}} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $ram.Modules[0].Manufacturer|Should -Be 'A&B'
        $ram.HtmlSection|Should -Not -Match '<script>|<img '
        $ram.HtmlSection|Should -Match 'A&amp;B'
    }
    It 'retains explicit soldered and removable evidence without claiming expansion is impossible' {
        Mock Get-CimInstance {@([pscustomobject]@{Capacity=4GB;FormFactor=21;DeviceLocator='Onboard'},[pscustomobject]@{Capacity=4GB;FormFactor=12;DeviceLocator='DIMM1'})} -ParameterFilter {$ClassName -eq 'Win32_PhysicalMemory'}
        $ram=Get-RAMDiagnostic
        $ram.Modules[0].IsSoldered|Should -BeTrue
        $ram.Modules[1].IsSoldered|Should -BeFalse
        $ram.AllSoldered|Should -BeFalse
    }
}

Describe 'Native outcomes and copy coverage' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
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
    It 'handles a single file without enumerating its siblings' {
        $source=Join-Path $TestDrive 'single source';$destination=Join-Path $TestDrive 'single dest'
        New-Item -ItemType Directory -Path $source,$destination|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'selected.txt'),'selected')
        [IO.File]::WriteAllText((Join-Path $source 'sibling.txt'),'not copied')
        [IO.File]::WriteAllText((Join-Path $destination 'selected.txt'),'selected')
        $result=Test-AtlasCopySample -Source (Join-Path $source 'selected.txt') -Destination $destination
        $result.OK|Should -BeTrue;$result.Checked|Should -Be 1
        {Assert-AtlasCopyDestination -Source (Join-Path $source 'selected.txt') -Destination $source}|Should -Throw '*source file*'
    }
    It 'rejects an empty requested sample before reporting success' {
        {Test-AtlasCopySample -Source $TestDrive -Destination $TestDrive -SampleSize 0}|Should -Throw
    }
    It 'does not follow a source junction or certify an incomplete sample' -Skip:($env:OS -ne 'Windows_NT') {
        $source=Join-Path $TestDrive 'junction src';$outside=Join-Path $TestDrive 'outside';$destination=Join-Path $TestDrive 'junction dest'
        New-Item -ItemType Directory -Path $source,$outside,$destination|Out-Null
        [IO.File]::WriteAllText((Join-Path $outside 'outside.txt'),'not traversed')
        New-Item -ItemType Junction -Path (Join-Path $source 'link') -Target $outside|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'plain.txt'),'copied')
        [IO.File]::WriteAllText((Join-Path $destination 'plain.txt'),'copied')
        $result=Test-AtlasCopySample -Source $source -Destination $destination
        $result.OK|Should -BeFalse;$result.State|Should -Be NotEvaluated
        $result.Checked|Should -Be 1;$result.UnverifiedLinks|Should -Be 1
    }
    It 'rejects a redirected destination even when its final directory does not exist' -Skip:($env:OS -ne 'Windows_NT') {
        $source=Join-Path $TestDrive 'plain src';$outside=Join-Path $TestDrive 'redirected';$link=Join-Path $TestDrive 'dest link'
        New-Item -ItemType Directory -Path $source,$outside|Out-Null
        New-Item -ItemType Junction -Path $link -Target $outside|Out-Null
        {Assert-AtlasCopyDestination -Source $source -Destination (Join-Path $link 'new-child')}|Should -Throw '*reparse*'
    }
    It 'does not hash files through a destination junction' -Skip:($env:OS -ne 'Windows_NT') {
        $source=Join-Path $TestDrive 'target src';$destination=Join-Path $TestDrive 'target dest';$outside=Join-Path $TestDrive 'target outside'
        New-Item -ItemType Directory -Path (Join-Path $source 'sub'),$destination,$outside|Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'sub/plain.txt'),'same')
        [IO.File]::WriteAllText((Join-Path $outside 'plain.txt'),'same')
        New-Item -ItemType Junction -Path (Join-Path $destination 'sub') -Target $outside|Out-Null
        $result=Test-AtlasCopySample -Source $source -Destination $destination
        $result.OK|Should -BeFalse;$result.Failed|Should -Be 1
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
    It 'does not start a child when cancellation was already requested' {
        $cancel=[Threading.CancellationTokenSource]::new();$cancel.Cancel()
        try {
            $result=Invoke-AtlasNativeProcess -FilePath 'does-not-exist' -CancellationToken $cancel.Token
            $result.State|Should -Be Cancelled;$result.Started|Should -BeFalse;$result.Completed|Should -BeFalse
        } finally { $cancel.Dispose() }
    }
    It 'cancels its own running child without reporting a timeout or success' {
        $cancel=[Threading.CancellationTokenSource]::new();$cancel.CancelAfter(800)
        try {
            $result=Invoke-AtlasNativeProcess -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile','-Command','Start-Sleep -Seconds 20') -CancellationToken $cancel.Token -TimeoutSeconds 15
            $result.State|Should -Be Cancelled;$result.Cancelled|Should -BeTrue;$result.TimedOut|Should -BeFalse
        } finally { $cancel.Dispose() }
    }
    It 'passes spaces, quotes and trailing slashes as literal native arguments' {
        $fixture=Join-Path $TestDrive 'argv fixture.ps1'
        [IO.File]::WriteAllText($fixture,'[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([Environment]::GetCommandLineArgs()[-1]))')
        $value='literal space & ; quote"slash\ and trailing\'
        $result=Invoke-AtlasNativeProcess -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile','-File',$fixture,$value)
        $result.State|Should -Be Correct
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($result.Stdout.Trim()))|Should -Be $value
    }
    It 'rejects ambiguous or control-containing native arguments before launch' {
        {Invoke-AtlasNativeProcess -FilePath 'not-started' -Arguments 'raw' -ArgumentList token}|Should -Throw '*Choose*'
        {Invoke-AtlasNativeProcess -FilePath 'not-started' -ArgumentList "bad`nargument"}|Should -Throw '*newlines*'
    }
    It 'uses a specified working directory without invoking a shell' {
        $result=Invoke-AtlasNativeProcess -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile','-Command','[IO.Directory]::GetCurrentDirectory()') -WorkingDirectory $TestDrive
        $result.State|Should -Be Correct;$result.Stdout.Trim()|Should -Be $TestDrive
    }
    It 'supports documented nonzero success codes without converting every error to success' {
        $result=Invoke-AtlasNativeProcess -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile','-Command','exit 7') -SuccessCodes @(0,7)
        $result.State|Should -Be Correct;$result.ExitCode|Should -Be 7
    }
    It 'retains bounded tails of both verbose pipes and an explicit full log without losing exit status' {
        $log=Join-Path $TestDrive 'verbose.log'
        $code='for($i=0;$i -lt 512;$i++){[Console]::Out.Write(("x"*4096));[Console]::Error.Write(("y"*4096))};[Console]::Out.Write("OUT-END");[Console]::Error.Write("ERR-END");exit 7'
        $result=Invoke-AtlasNativeProcess -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile','-Command',$code) -TimeoutSeconds 30 -MaxCapturedCharacters 2048 -OutputLogPath $log
        $result.State|Should -Be Failed;$result.ExitCode|Should -Be 7
        $result.Stdout.Length|Should -BeLessOrEqual 2048;$result.Stderr.Length|Should -BeLessOrEqual 2048
        $result.Stdout|Should -Match 'OUT-END$';$result.Stderr|Should -Match 'ERR-END$'
        $result.StdoutTruncated|Should -BeTrue;$result.StderrTruncated|Should -BeTrue
        (Get-Item -LiteralPath $log).Length|Should -BeGreaterThan 4MB
    }
    It 'refuses to overwrite a previous verbose log before starting a child' {
        $log=Join-Path $TestDrive 'previous.log';[IO.File]::WriteAllText($log,'keep')
        {Invoke-AtlasNativeProcess -FilePath 'not-launched' -OutputLogPath $log}|Should -Throw
        [IO.File]::ReadAllText($log)|Should -Be keep
    }
}

Describe 'Real Robocopy integration confined to TestDrive' -Tag 'LocalFileIO' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
    }
    It 'copies real fixture bytes and preserves unrelated existing destination files' -Skip:($env:OS -ne 'Windows_NT') {
        $source=Join-Path $TestDrive 'native source & apostrophe''s'
        $destination=Join-Path $TestDrive 'native destination'
        New-Item -ItemType Directory -Path $source,$destination | Out-Null
        [IO.File]::WriteAllText((Join-Path $source 'one.txt'),'new fixture bytes')
        [IO.File]::WriteAllText((Join-Path $destination 'one.txt'),'old')
        [IO.File]::WriteAllText((Join-Path $destination 'keep.txt'),'keep fixture')
        Assert-AtlasCopyDestination -Source $source -Destination $destination
        $copy=Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32/robocopy.exe') -ArgumentList @($source,$destination,'/E','/R:0','/W:0','/XJ') -TimeoutSeconds 20 -SuccessCodes @(0,1,2,3)
        $copy.State | Should -Be Correct
        (Test-AtlasCopySample -Source $source -Destination $destination).OK | Should -BeTrue
        [IO.File]::ReadAllText((Join-Path $destination 'keep.txt')) | Should -Be 'keep fixture'
    }
    It 'reports a real sharing violation as failure rather than verified backup' -Skip:($env:OS -ne 'Windows_NT') {
        $source=Join-Path $TestDrive 'locked source'
        $destination=Join-Path $TestDrive 'locked destination'
        New-Item -ItemType Directory -Path $source,$destination | Out-Null
        $file=Join-Path $source 'locked.txt'
        [IO.File]::WriteAllText($file,'locked fixture bytes')
        $handle=[IO.FileStream]::new($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try {
            $copy=Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32/robocopy.exe') -ArgumentList @($source,$destination,'/E','/R:0','/W:0','/XJ') -TimeoutSeconds 20 -SuccessCodes @(0,1,2,3)
            $copy.State | Should -Be Failed
            $copy.ExitCode | Should -BeGreaterOrEqual 8
            $verification=Test-AtlasCopySample -Source $source -Destination $destination
            $verification.OK | Should -BeFalse
            $verification.State | Should -Be Failed
        } finally { $handle.Dispose() }
    }
}

Describe 'USB dependency tree copy integrity' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Operations.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PrepararUSB.ps1' 'Copy-TreeSafely')
    }
    BeforeEach {
        $script:Source=Join-Path $TestDrive ([guid]::NewGuid().ToString('N')+' source')
        $script:Destination=Join-Path $TestDrive ([guid]::NewGuid().ToString('N')+' destination')
        New-Item -ItemType Directory -Path $script:Source | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:Source 'resource.dat'),'original')
        Mock Get-Command { [pscustomobject]@{Source='fixture-robocopy.exe'} } -ParameterFilter {$Name -eq 'robocopy.exe'}
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Correct';ExitCode=0} }
    }
    It 'does not accept exit zero when no resource files were copied' {
        {Copy-TreeSafely -SourceDir $script:Source -DestinationDir $script:Destination} | Should -Throw '*verification*'
    }
    It 'rejects same-size same-date corruption instead of trusting delta metadata' {
        New-Item -ItemType Directory -Path $script:Destination | Out-Null
        $sourceFile=Join-Path $script:Source 'resource.dat';$destFile=Join-Path $script:Destination 'resource.dat'
        [IO.File]::WriteAllText($destFile,'corrupt!')
        [IO.File]::SetLastWriteTimeUtc($destFile,[IO.File]::GetLastWriteTimeUtc($sourceFile))
        {Copy-TreeSafely -SourceDir $script:Source -DestinationDir $script:Destination} | Should -Throw '*verification*'
    }
    It 'does not retry an installer resource copy with an unverified fallback after native failure' {
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Failed';ExitCode=8} }
        Mock Copy-Item { throw 'Fallback must not run' }
        {Copy-TreeSafely -SourceDir $script:Source -DestinationDir $script:Destination} | Should -Throw '*Failed*'
        Should -Invoke Copy-Item -Times 0 -Exactly
    }
    It 'rejects a recursive copy destination before creating it' {
        $child=Join-Path $script:Source 'child'
        {Copy-TreeSafely -SourceDir $script:Source -DestinationDir $child} | Should -Throw '*destination*'
        Test-Path -LiteralPath $child | Should -BeFalse
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
    It 'rejects source junctions before the native copy' -Skip:($env:OS -ne 'Windows_NT') {
        $outside=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $outside | Out-Null
        New-Item -ItemType Junction -Path (Join-Path $script:Source 'link') -Target $outside | Out-Null
        {Copy-TreeSafely -SourceDir $script:Source -DestinationDir $script:Destination} | Should -Throw '*reparse*'
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
    It 'rejects redirected destination descendants before the native copy' -Skip:($env:OS -ne 'Windows_NT') {
        $sub=Join-Path $script:Source 'sub';$outside=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $sub,$outside,$script:Destination | Out-Null
        [IO.File]::WriteAllText((Join-Path $sub 'data.txt'),'fixture')
        New-Item -ItemType Junction -Path (Join-Path $script:Destination 'sub') -Target $outside | Out-Null
        {Copy-TreeSafely -SourceDir $script:Source -DestinationDir $script:Destination} | Should -Throw '*reparse*'
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
        @(Get-ChildItem -LiteralPath $outside).Count | Should -Be 0
    }
    It 'accepts a complete byte-verified fixture and retains unrelated destination files' {
        Mock Invoke-AtlasNativeProcess {
            Copy-Item -LiteralPath (Join-Path $script:Source 'resource.dat') -Destination (Join-Path $script:Destination 'resource.dat')
            [pscustomobject]@{State='Correct';ExitCode=1}
        }
        New-Item -ItemType Directory -Path $script:Destination | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:Destination 'keep.txt'),'retained')
        Copy-TreeSafely -SourceDir $script:Source -DestinationDir $script:Destination | Should -BeTrue
        [IO.File]::ReadAllText((Join-Path $script:Destination 'keep.txt')) | Should -Be retained
    }
}

Describe 'Opt-in physical USB acceptance guards' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'tests/Invoke-UsbAcceptance.ps1' 'Assert-UsbIdentity')
        . (Get-TestFunction $script:RepoRoot 'tests/Invoke-UsbAcceptance.ps1' 'Assert-OwnedUsbPath')
        function Get-Volume { [CmdletBinding()]param($DriveLetter) throw 'Real volume blocked' }
        function Get-Partition { [CmdletBinding()]param($DriveLetter) throw 'Real partition blocked' }
        function Get-Disk { [CmdletBinding()]param([Parameter(ValueFromPipeline)]$InputObject) throw 'Real disk blocked' }
        $script:DriveLetter='E';$script:driveRoot='E:\';$script:ExpectedDiskNumber=2
        $script:ExpectedIdentitySha256=Get-AtlasTextHash 'fixture-disk|fixture-volume'
        $script:usbRoot='E:\ATLAS_USB_QA_fixture'
    }
    BeforeEach {
        Mock Get-Volume { [pscustomobject]@{UniqueId='fixture-volume';FileSystem='NTFS';SizeRemaining=2GB} }
        Mock Get-Partition { [pscustomobject]@{DiskNumber=2} }
        Mock Get-Disk { [pscustomobject]@{Number=2;UniqueId='fixture-disk';BusType='USB';IsBoot=$false;IsSystem=$false;IsOffline=$false;IsReadOnly=$false} }
        Mock Assert-AtlasPlainDirectory { }
    }
    It 'accepts only the explicitly matched non-system USB identity' {
        (Assert-UsbIdentity).FileSystem | Should -Be NTFS
    }
    It 'rejects a different volume identity even if the letter and disk number match' {
        Mock Get-Volume { [pscustomobject]@{UniqueId='replacement-volume';FileSystem='NTFS';SizeRemaining=2GB} }
        {Assert-UsbIdentity} | Should -Throw '*identity changed*'
    }
    It 'rejects internal, system, read-only and mismatched disks' -ForEach @(
        @{Bus='SATA';Boot=$false;ReadOnly=$false;Number=2},
        @{Bus='USB';Boot=$true;ReadOnly=$false;Number=2},
        @{Bus='USB';Boot=$false;ReadOnly=$true;Number=2},
        @{Bus='USB';Boot=$false;ReadOnly=$false;Number=3}
    ) {
        Mock Get-Disk { [pscustomobject]@{Number=$Number;UniqueId='fixture-disk';BusType=$Bus;IsBoot=$Boot;IsSystem=$false;IsOffline=$false;IsReadOnly=$ReadOnly} }
        {Assert-UsbIdentity} | Should -Throw '*non-system USB*'
    }
    It 'refuses insufficient free space without trying to fill or format a drive' {
        Mock Get-Volume { [pscustomobject]@{UniqueId='fixture-volume';FileSystem='NTFS';SizeRemaining=100MB} }
        {Assert-UsbIdentity} | Should -Throw '*1 GiB*'
    }
    It 'rejects root, sibling-prefix and traversal paths outside its owned folder' -Skip:($env:OS -ne 'Windows_NT') {
        foreach($path in @('E:\','E:\ATLAS_USB_QA_fixture-other\file','E:\ATLAS_USB_QA_fixture\..\existing.txt')) {
            {Assert-OwnedUsbPath $path} | Should -Throw '*escaped*'
        }
        {Assert-OwnedUsbPath 'E:\ATLAS_USB_QA_fixture\copy\file.txt'} | Should -Not -Throw
    }
}

Describe 'Fresh diagnostic export evidence' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Reports.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' 'Start-ProcessWithTimeout')
        function Invoke-AtlasNativeProcess { [CmdletBinding()]param($FilePath,$Arguments,$TimeoutSeconds) throw 'Real diagnostic process blocked' }
    }
    BeforeEach {
        $script:Output=Join-Path $TestDrive ([guid]::NewGuid().ToString('N')+'.txt')
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Correct';ExitCode=0} }
    }
    It 'rejects old output before starting a new diagnostic process' {
        [IO.File]::WriteAllText($script:Output,'stale fixture')
        Start-ProcessWithTimeout -FilePath fixture.exe -ExpectedOutput $script:Output | Should -BeFalse
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
        [IO.File]::ReadAllText($script:Output) | Should -Be 'stale fixture'
    }
    It 'does not treat exit zero with no report as successful evidence' {
        Start-ProcessWithTimeout -FilePath fixture.exe -ExpectedOutput $script:Output | Should -BeFalse
    }
    It 'rejects output left by a timed out process even when a file exists' {
        Mock Invoke-AtlasNativeProcess { [IO.File]::WriteAllText($script:Output,'partial');[pscustomobject]@{State='TimedOut';ExitCode=0} }
        Start-ProcessWithTimeout -FilePath fixture.exe -ExpectedOutput $script:Output | Should -BeFalse
        Test-Path -LiteralPath $script:Output | Should -BeTrue
    }
    It 'accepts only a successful process and a newly created plain report' {
        Mock Invoke-AtlasNativeProcess { [IO.File]::WriteAllText($script:Output,'fresh fixture');[pscustomobject]@{State='Correct';ExitCode=0} }
        Start-ProcessWithTimeout -FilePath fixture.exe -ExpectedOutput $script:Output | Should -BeTrue
    }
    It 'requires fresh output at every diagnostic export call site, including the shared battery exporter' {
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $calls=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Start-ProcessWithTimeout'},$true))
        $calls.Count | Should -Be 3
        foreach($call in $calls) {
            @($call.CommandElements | Where-Object {$_ -is [Management.Automation.Language.CommandParameterAst]}).ParameterName | Should -Contain ExpectedOutput
        }
    }
}

Describe 'Transversal dependency consumers' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Write-AtlasLog {param($Message,$Tool,$Level)}
        function Expand-AtlasPath {param($Path)[Environment]::ExpandEnvironmentVariables($Path)}
        function Invoke-AtlasNativeProcess {[CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real installation blocked'}
        function Invoke-WebRequest {[CmdletBinding()]param($Uri,$OutFile,$TimeoutSec,[switch]$UseBasicParsing)throw 'Network blocked'}
        foreach($name in @('Resolve-AtlasDependency','Resolve-SymlinkPath','Get-AtlasDependencyCandidate')){. (Get-TestFunction $script:RepoRoot 'src/lib/Dependencies.ps1' $name)}
        foreach($name in @('Get-OfflineDiagToolsRoot','Resolve-DiagnosticoMasterTools','Format-DiagnosticQuantity')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' $name)}
        foreach($name in @('Get-OfflineToolsRoot','Resolve-GpuCheckTools')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GPUCheck.ps1' $name)}
        foreach($name in @('Find-FastCopy','Install-FastCopyAuto')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-FastCopy.ps1' $name)}
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PrepararUSB.ps1' 'Resolve-DepPath')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-AIReadiness.ps1' 'Get-AIRCommandState')
        $script:OriginalOffline=$env:ATLAS_OFFLINE_ROOT
        $script:OriginalLocalAppData=$env:LOCALAPPDATA
    }
    BeforeEach {
        $env:ATLAS_OFFLINE_ROOT=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $env:ATLAS_OFFLINE_ROOT|Out-Null
        $env:LOCALAPPDATA=$env:ATLAS_OFFLINE_ROOT
        $script:AtlasDepsRegistry=@{}
        foreach($name in @('CPUZ','BlueScreenView','BatteryInfoView','CrystalDiskInfo','CrystalDiskMark','HWiNFO','GPUZ','FurMark2','FastCopy')){
            $script:AtlasDepsRegistry[$name]=@{SearchPaths=@();ExecutableName="$name.exe";WingetId="Fixture.$name"}
        }
        Mock Get-Command {$null}
        Mock Get-AtlasWingetPath {'fixture-winget.exe'}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='TimedOut';ExitCode=0}}
        Mock Invoke-WebRequest {throw 'No fallback download allowed'}
    }
    AfterAll {$env:ATLAS_OFFLINE_ROOT=$script:OriginalOffline;$env:LOCALAPPDATA=$script:OriginalLocalAppData}
    It 'resolves Master legacy candidates but rejects empty Crystal resources without staging files' {
        $legacy=Join-Path $TestDrive 'legacy';$tools=Join-Path $TestDrive 'unused-staging'
        New-Item -ItemType Directory -Path (Join-Path $legacy 'CrystalDiskInfo/CdiResource') -Force|Out-Null
        $cpuz=Join-Path $legacy 'cpuz_x64.exe';[IO.File]::WriteAllText($cpuz,'fixture')
        [IO.File]::WriteAllText((Join-Path $legacy 'CrystalDiskInfo/DiskInfo64.exe'),'fixture')
        $r=Resolve-DiagnosticoMasterTools -ToolsDir $tools -LegacyAppsDir $legacy -SelMode 3
        $r.CPUZ|Should -Be $cpuz;$r.CrystalDiskInfo|Should -BeNullOrEmpty
        Test-Path -LiteralPath $tools|Should -BeFalse
        Should -Invoke Invoke-AtlasNativeProcess -Times 5 -Exactly
    }
    It 'uses an existing offline GPU dependency and never installs FurMark for an idle session' {
        $tools=Join-Path $env:ATLAS_OFFLINE_ROOT 'deps/GPUCheck/tools'
        New-Item -ItemType Directory -Path $tools -Force|Out-Null
        foreach($file in @('GPU-Z.exe','HWiNFO64.exe')){[IO.File]::WriteAllText((Join-Path $tools $file),'fixture')}
        $r=Resolve-GpuCheckTools -ToolsDir (Join-Path $TestDrive 'not-created')
        $r.GPUZ|Should -Be (Join-Path $tools 'GPU-Z.exe');$r.FurMark|Should -BeNullOrEmpty
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
    It 'retains caller paths after a successful install but rejects partial files after a timeout' {
        $exe=Join-Path $TestDrive 'usb-candidate.exe'
        Mock Invoke-AtlasNativeProcess {[IO.File]::WriteAllText($exe,'partial');[pscustomobject]@{State='TimedOut';ExitCode=0}}
        Resolve-DepPath -DepName GPUZ -FallbackPaths @($exe)|Should -BeNullOrEmpty
        Remove-Item -LiteralPath $exe
        Mock Invoke-AtlasNativeProcess {[IO.File]::WriteAllText($exe,'complete');[pscustomobject]@{State='Correct';ExitCode=0}}
        Resolve-DepPath -DepName GPUZ -FallbackPaths @($exe)|Should -Be $exe
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }
    It 'does not accept a partial FastCopy install on the fallback path' {
        $exe=Join-Path $env:ATLAS_OFFLINE_ROOT 'apps/FastCopy/FastCopy.exe'
        New-Item -ItemType Directory -Path (Split-Path -Parent $exe) -Force|Out-Null
        Mock Invoke-AtlasNativeProcess {[IO.File]::WriteAllText($exe,'partial');[pscustomobject]@{State='Failed';ExitCode=1603}}
        {Install-FastCopyAuto}|Should -Throw '*could not be resolved*'
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly
    }
    It 'resolves one actual application for AI and rejects function or directory impostors' {
        $exe=Join-Path $TestDrive 'runtime.exe';[IO.File]::WriteAllText($exe,'fixture')
        Mock Get-Command {@([pscustomobject]@{Source=$TestDrive},[pscustomobject]@{Source=$exe})} -ParameterFilter {$CommandType -eq 'Application'}
        $r=Get-AIRCommandState -Name fixture
        $r.Installed|Should -BeTrue;$r.Path|Should -Be $exe
        Should -Invoke Get-Command -Times 1 -Exactly -ParameterFilter {$CommandType -eq 'Application'}
    }
    It 'shows unknown quantities explicitly and keeps fractional module sizes' {
        foreach($value in @($null,0,-1,[double]::NaN,[double]::PositiveInfinity,'unknown')){Format-DiagnosticQuantity -Value $value -Divisor 1GB -Unit GB|Should -Be 'N/D'}
        Format-DiagnosticQuantity -Value 512MB -Divisor 1GB -Decimals 2 -Unit GB|Should -Be '0.5 GB'
        $r=Get-AtlasMemorySummary -Modules @([pscustomobject]@{Capacity=8GB},[pscustomobject]@{Capacity=$null}) -Arrays @()
        Format-DiagnosticQuantity -Value $r.TotalGB -Unit GB|Should -Be 'N/D'
    }
    It 'keeps the real Master application menu property lookup functional' {
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $assignment=$ast.Find({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$path' -and $n.Right.Extent.Text -match 'diagDeps'},$true)
        $diagDeps=[pscustomobject]@{CPUZ='fixture-cpuz.exe'};$name='CPUZ'
        & ([scriptblock]::Create($assignment.Right.Extent.Text))|Should -Be 'fixture-cpuz.exe'
    }
}

Describe 'Transversal inventory source boundaries' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
    }
    It 'bounds every production CIM call explicitly, allowing only the audited AI query splat' {
        $missing=@(foreach($file in Get-ChildItem (Join-Path $script:RepoRoot 'src') -Filter *.ps1 -Recurse -File){
            $ast=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$null,[ref]$null)
            foreach($call in $ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in @('Get-CimInstance','Get-WmiObject')},$true)){
                if($call.GetCommandName() -eq 'Get-WmiObject'){"Legacy WMI: $($file.Name)";continue}
                $parameters=@($call.CommandElements|Where-Object {$_ -is [Management.Automation.Language.CommandParameterAst]}).ParameterName
                if($parameters -contains 'OperationTimeoutSec'){continue}
                if($file.Name -eq 'Invoke-AIReadiness.ps1' -and $call.Extent.Text -eq 'Get-CimInstance @query' -and $ast.Extent.Text -match 'OperationTimeoutSec\s*=\s*10'){continue}
                "$($file.Name):$($call.Extent.StartLineNumber)"
            }
        })
        $missing|Should -BeNullOrEmpty
    }
    It 'prevents direct winget and synchronous DNS regressions across every production script' {
        foreach($file in Get-ChildItem (Join-Path $script:RepoRoot 'src') -Filter *.ps1 -Recurse -File){
            $ast=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$null,[ref]$null)
            @($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in @('winget','winget.exe')},$true)).Count|Should -Be 0 -Because $file.Name
            @($ast.FindAll({param($n)$n -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Expression.Extent.Text -match '^\[(System\.)?Net\.Dns\]$' -and $n.Member.Value -in @('GetHostEntry','GetHostAddresses')},$true)).Count|Should -Be 0 -Because $file.Name
        }
    }
    It 'bounds DNS task accumulation when Framework cannot cancel an outstanding lookup' {
        $tasks=@(1..4|ForEach-Object {[Threading.Tasks.TaskCompletionSource[object]]::new()})
        $script:AtlasDnsPending=@($tasks|ForEach-Object {$_.Task})
        (Resolve-AtlasDnsEntry -Name 'should-not-be-queried.invalid' -TimeoutMilliseconds 1).State|Should -Be NotEvaluated
        $script:AtlasDnsPending.Count|Should -Be 4
        foreach($task in $tasks){$task.SetResult($null)}
        $script:AtlasDnsPending=@()
    }
    It 'reports timed out DNS observations without inventing a cause or successful answer' {
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-AuditoriaRouter.ps1' 'Modulo-TestDNS')
        function Esperar-Enter {param([switch]$Silencioso)}
        $script:HistorialSesion=[Collections.Generic.List[string]]::new()
        Mock Clear-Host {};Mock Write-Host {}
        Mock Resolve-AtlasDnsEntry {[pscustomobject]@{State='TimedOut';Entry=$null}}
        $log=Modulo-TestDNS -Silencioso
        @($log|Where-Object {$_ -match '\[TimedOut\]'}).Count|Should -Be 5
        ($log -join "`n")|Should -Not -Match '\[OK\]|completely down|corrupt'
        Should -Invoke Resolve-AtlasDnsEntry -Times 5 -Exactly -ParameterFilter {$TimeoutMilliseconds -eq 3000}
    }
}

Describe 'Real local policy and runtime definitions' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/lib/Operations.ps1' 'Get-AtlasPowerShellVersion')
        function Invoke-AtlasNativeProcess {[CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real execution blocked'}
    }
    It 'compiles the actual policy CSharp source without invoking or changing account policies' {
        $ast=Get-TestAst $script:RepoRoot 'src/lib/Operations.ps1'
        $source=$ast.Find({param($n)$n -is [Management.Automation.Language.StringConstantExpressionAst] -and $n.Value -match 'static extern int NetUserModalsGet'},$true).Value
        $source|Should -Not -BeNullOrEmpty
        # Compile under a unique test namespace; never call the native policy API.
        $source=$source.Replace('namespace Atlas {',('namespace AtlasPolicyTest'+[guid]::NewGuid().ToString('N')+' {'))
        (Add-Type -TypeDefinition $source -PassThru -ErrorAction Stop).Name|Should -Contain LocalPolicyReader
    }
    It 'queries the runtime through the real available helper and rejects a truncated success tail' {
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='7.6.9';StdoutTruncated=$false}}
        Get-AtlasPowerShellVersion -Path 'fixture-pwsh.exe'|Should -Be ([version]'7.6.9')
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {$TimeoutSeconds -eq 15 -and $FilePath -eq 'fixture-pwsh.exe'}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='7.6.9';StdoutTruncated=$true}}
        {Get-AtlasPowerShellVersion -Path 'fixture-pwsh.exe'}|Should -Throw '*not be evaluated*'
    }
}
Describe 'Service restoration and dependent protection' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Operations.ps1')
        function Get-Service {[CmdletBinding()]param($Name)throw 'Real service blocked'}
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$Filter,$OperationTimeoutSec)throw 'Real CIM blocked'}
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

Describe 'GPU evidence and unavailable sources' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach ($name in @('Convert-GpuDriverDate','Add-GpuFinding','Get-GpuTargetedEvents','Get-GpuLiveKernelFiles','Get-GPUSlownessTriageForReport')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' $name)
        }
        function Get-CimInstance { [CmdletBinding()]param($ClassName,$OperationTimeoutSec) throw 'Real inventory blocked' }
        function Get-WinEvent { [CmdletBinding()]param($FilterHashtable,$MaxEvents) throw 'Real event read blocked' }
        $script:L=@{
            GpuVerdictOk='NO STRONG SIGNALS';GpuVerdictObs='OBSERVATION';GpuVerdictRisk='RISK'
            GpuAdviceOk='Limited triage';GpuNotEvaluated='NOT EVALUATED';GpuIncomplete='Partial sources'
            GpuEventScope='200 newest per query';GpuNoFindings='No findings';GpuNoEvents='No matching events'
            SevMed='Medium';GpuBasicDrv='Basic driver';GpuBasicAct='Review driver'
        }
    }
    It 'distinguishes denied access from a genuinely empty event query' {
        Mock Get-WinEvent { throw 'Access denied' }
        {Get-GpuTargetedEvents -Since (Get-Date).AddDays(-30)} | Should -Throw '*could not be evaluated*'
    }
    It 'accepts the no-matching-events condition and limits each query' {
        Mock Get-WinEvent { Write-Error 'No events' -ErrorId NoMatchingEventsFound -ErrorAction Stop }
        @(Get-GpuTargetedEvents -Since (Get-Date).AddDays(-30)).Count | Should -Be 0
        Should -Invoke Get-WinEvent -Times 17 -Exactly -ParameterFilter {$MaxEvents -eq 200}
    }
    It 'deduplicates within a log without losing a colliding record in another log' {
        Mock Get-WinEvent {
            if ($FilterHashtable.LogName -eq 'Application') {
                [pscustomobject]@{LogName='Application';RecordId=17;Id=1001;ProviderName='Windows Error Reporting';Message='LiveKernelEvent';TimeCreated=(Get-Date)}
            } elseif ($FilterHashtable.ProviderName -eq 'Display' -or $FilterHashtable.Id -eq 4101) {
                [pscustomobject]@{LogName='System';RecordId=17;Id=4101;ProviderName='Display';Message='TDR';TimeCreated=(Get-Date)}
            }
        }
        $events=@(Get-GpuTargetedEvents -Since (Get-Date).AddDays(-30))
        $events.Count | Should -Be 2
        @($events.LogName | Sort-Object -Unique).Count | Should -Be 2
    }
    Context 'Report conclusions' {
        BeforeEach {
            Mock Get-CimInstance { [pscustomobject]@{Name='Fixture GPU';DriverVersion='1.0';DriverDate=(Get-Date);Status='OK';ConfigManagerErrorCode=0} }
            Mock Get-GpuTargetedEvents { }
            Mock Get-GpuLiveKernelFiles { }
        }
        It 'does not score a failed or missing GPU inventory as healthy' -ForEach @(@{Missing=$true},@{Missing=$false}) {
            Mock Get-CimInstance { if (-not $Missing) { throw 'CIM denied' } }
            $result=Get-GPUSlownessTriageForReport
            $result.State | Should -Be NotEvaluated
            $result.Score | Should -BeNullOrEmpty
            $result.Verdict | Should -Be 'NOT EVALUATED'
            $result.UnavailableSources | Should -Contain 'GPU inventory'
        }
        It 'marks event and dump read failures explicitly without dropping device findings' {
            Mock Get-CimInstance { [pscustomobject]@{Name='Microsoft Basic Display';DriverVersion='1';Status='OK';ConfigManagerErrorCode=0} }
            Mock Get-GpuTargetedEvents { throw 'Event read denied' }
            Mock Get-GpuLiveKernelFiles { throw 'Dump access denied' }
            $result=Get-GPUSlownessTriageForReport
            $result.State | Should -Be NotEvaluated
            $result.Findings.Count | Should -Be 1
            $result.UnavailableSources.Count | Should -Be 2
            $result.HtmlSection | Should -Match '--/100'
        }
        It 'encodes device-provided strings and labels an observation as limited triage' {
            Mock Get-CimInstance { [pscustomobject]@{Name='Microsoft Basic Display <script>x</script>';DriverVersion='1<2';DriverDate=(Get-Date);Status='OK';ConfigManagerErrorCode=0} }
            $result=Get-GPUSlownessTriageForReport
            $result.State | Should -Be Observed
            $result.HtmlSection | Should -Not -Match '<script>'
            $result.HtmlSection | Should -Match '&lt;script&gt;'
            $result.HtmlSection | Should -Match '200 newest per query'
        }
    }
}

Describe 'AI inventory without obsolete or unbounded fallbacks' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Get-AIRCim','Format-AIRGB','ConvertFrom-AIRWmiDate','Get-AIRDiskInfo','Get-AIRNvidiaSmi','New-AIRReport')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-AIReadiness.ps1' $name)
        }
        function Get-CimInstance { [CmdletBinding()]param($ClassName,$Namespace,$Filter,$OperationTimeoutSec) throw 'Real inventory blocked' }
        function Get-PhysicalDisk { [CmdletBinding()]param() throw 'Real disk read blocked' }
        function Invoke-AtlasNativeProcess { [CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds) throw 'Real GPU query blocked' }
        function Get-AtlasApplicationPath { param($Name) 'fixture-nvidia.exe' }
        function Get-AIRCommandState { param($Name) [pscustomobject]@{Installed=$false;Path=''} }
        function Test-AIREndpoint { param($Name,$Url) [pscustomobject]@{Reachable=$false} }
        function Get-AIRModelRecommendations { param($RamGB,$VramGB) }
    }
    It 'uses CIM with a timeout and preserves namespace and filter' {
        Mock Get-CimInstance { [pscustomobject]@{Name='fixture'} }
        (Get-AIRCim -ClassName Win32_Processor -Namespace 'root/cimv2' -Filter 'DeviceID=0').Name | Should -Be fixture
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {$OperationTimeoutSec -eq 10 -and $Namespace -eq 'root/cimv2' -and $Filter -eq 'DeviceID=0'}
    }
    It 'reports unavailable CIM as an empty inventory with a warning' {
        Mock Get-CimInstance { throw 'Access denied' }
        $warnings=@()
        @(Get-AIRCim -ClassName Win32_Processor -WarningVariable warnings -WarningAction SilentlyContinue).Count | Should -Be 0
        $warnings | Should -Not -BeNullOrEmpty
    }
    It 'does not call a fixed-media disk HDD based on its model or size' {
        Mock Get-PhysicalDisk { throw 'Provider unavailable' }
        Mock Get-AIRCim { [pscustomobject]@{Model='Fixture NVMe SSD';MediaType='Fixed hard disk media';Size=2TB;Status='OK';InterfaceType='SCSI'} }
        (Get-AIRDiskInfo).MediaType | Should -Be Unknown
    }
    It 'keeps a failed NVIDIA process from contributing telemetry' {
        Mock Get-AtlasApplicationPath { 'fixture-nvidia.exe' }
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='TimedOut';Stdout='Fixture, 8192, 30, 1'} }
        Get-AIRNvidiaSmi -WarningAction SilentlyContinue | Should -BeNullOrEmpty
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {$TimeoutSeconds -eq 10}
    }
    It 'parses multiple GPUs and preserves unavailable sensor values' {
        Mock Get-AtlasApplicationPath { 'fixture-nvidia.exe' }
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Correct';Stdout="Fixture1, 8192, 30, 1`r`nFixture2, 16384, N/A, 2`r`n"} }
        $rows=@(Get-AIRNvidiaSmi)
        $rows.Count | Should -Be 2
        $rows[0].MemoryMB | Should -Be 8192
        $rows[1].TemperatureC | Should -BeNullOrEmpty
    }
    It 'rejects a truncated NVIDIA success tail rather than parsing partial telemetry' {
        Mock Get-AtlasApplicationPath { 'fixture-nvidia.exe' }
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='Fixture, 8192, 30, 1';StdoutTruncated=$true}}
        Get-AIRNvidiaSmi -WarningAction SilentlyContinue|Should -BeNullOrEmpty
    }
    It 'does not recommend HDD replacement or fabricate a CPU benchmark from unknown media' {
        Mock Get-AIRCim {
            switch($ClassName) {
                Win32_ComputerSystem { [pscustomobject]@{TotalPhysicalMemory=16GB} }
                Win32_Processor { [pscustomobject]@{Name='Fixture';NumberOfLogicalProcessors=8;NumberOfCores=4} }
                default { [pscustomobject]@{Name='Fixture';Caption='Fixture'} }
            }
        }
        Mock Get-AIRNvidiaSmi { }
        Mock Get-AIRDiskInfo { [pscustomobject]@{MediaType='Unknown';BusType='SATA';Health='Unknown'} }
        $script:L=@{HddOnly='HDD fixture finding';RecHddOnly='Replace HDD fixture'}
        $result=New-AIRReport -ClientName '' -ConsultantName ''
        $result.CPU.BenchmarkExecuted | Should -BeFalse
        $result.CPU.BenchmarkMOps | Should -BeNullOrEmpty
        $result.Findings | Should -Not -Contain 'HDD fixture finding'
        $result.Recommendations | Should -Not -Contain 'Replace HDD fixture'
    }
    It 'preserves missing RAM and VRAM and does not recommend a model from incomplete inventory' {
        Mock Get-AIRCim {
            switch($ClassName) {
                Win32_ComputerSystem {[pscustomobject]@{TotalPhysicalMemory=$null}}
                Win32_Processor {[pscustomobject]@{Name='Fixture';NumberOfLogicalProcessors=0}}
                Win32_VideoController {[pscustomobject]@{Name='Fixture';AdapterRAM=$null}}
                default {}
            }
        }
        Mock Get-AIRNvidiaSmi {}
        Mock Get-AIRDiskInfo {[pscustomobject]@{MediaType='Unknown';BusType='SATA';Health='Unknown'}}
        $script:L=@{LowRam='FALSE_LOW_RAM';LowCpu='FALSE_LOW_CPU';LowGpu='FALSE_LOW_GPU'}
        $r=New-AIRReport -ClientName '' -ConsultantName ''
        $r.RAM.TotalGB|Should -BeNullOrEmpty;$r.GPU[0].VRAMGB|Should -BeNullOrEmpty
        $r.InventoryComplete|Should -BeFalse;$r.ModelRecommendations.Count|Should -Be 0
        $r.Findings|Should -Not -Contain 'FALSE_LOW_RAM';$r.Findings|Should -Not -Contain 'FALSE_LOW_CPU';$r.Findings|Should -Not -Contain 'FALSE_LOW_GPU'
    }
}

Describe 'Storage evidence without bus/size guesses' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' 'Get-StorageAnalysis')
        function Get-PhysicalDisk {[CmdletBinding()]param() throw 'Real inventory blocked'}
        function Get-CimInstance {[CmdletBinding()]param($ClassName,$OperationTimeoutSec) throw 'Real inventory blocked'}
        $script:L=@{UnknownLbl='Unknown';StUnclass='Not classified';StPhysicalUnavailable='Physical inventory unavailable';StVolumesUnavailable='Volume inventory unavailable';StEmptyPhysical='No physical disks reported';StEmptyVolumes='No fixed volumes reported';StCapacityUnknown='Space not evaluated';StDeviceCapacityUnknown='Disk capacity unavailable';StUnmeasured='Inventory only, performance not measured'}
    }
    It 'does not label an unspecified large SATA disk as an HDD or unhealthy' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='<script>fixture</script>';MediaType='Unspecified';BusType='SATA';Size=1TB;HealthStatus=$null}}
        Mock Get-CimInstance {[pscustomobject]@{DeviceID='<img src=fixture>';DriveType=3;Size=1TB;FreeSpace=500GB}}
        $result=Get-StorageAnalysis
        $result.HasHDD|Should -BeFalse;$result.Disks[0].Health|Should -Be Unknown
        $result.HtmlSection|Should -Not -Match '<script>'; $result.HtmlSection|Should -Match '&lt;script&gt;'
        $result.HtmlSection|Should -Not -Match '<img '; $result.HtmlSection|Should -Match '&lt;img '
    }
    It 'keeps an explicit HDD type and preserves a zero-valued status' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';MediaType='HDD';BusType='SATA';Size=1TB;HealthStatus=0}}
        Mock Get-CimInstance { }
        $result=Get-StorageAnalysis
        $result.HasHDD|Should -BeTrue;$result.Disks[0].Health|Should -Be '0'
    }
    It 'retains a real volume finding when physical disk inventory fails' {
        Mock Get-PhysicalDisk {throw 'Access denied'}
        Mock Get-CimInstance {[pscustomobject]@{DeviceID='Q:';DriveType=3;Size=100GB;FreeSpace=5GB}}
        $result=Get-StorageAnalysis
        $result.State|Should -Be Partial
        $result.PhysicalInventoryState|Should -Be Unavailable
        $result.VolumeInventoryState|Should -Be Observed
        $result.CriticalSpace|Should -BeTrue
        $result.Volumes[0].UsedPercent|Should -Be 95
        $result.HtmlSection|Should -Match 'Physical inventory unavailable'
    }
    It 'retains device information when volume enumeration fails' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';MediaType='HDD';BusType='SATA';Size=1TB;HealthStatus='Healthy'}}
        Mock Get-CimInstance {throw 'Access denied'}
        $result=Get-StorageAnalysis
        $result.State|Should -Be Partial
        $result.HasHDD|Should -BeTrue
        $result.VolumeInventoryState|Should -Be Unavailable
        $result.CriticalSpace|Should -BeNullOrEmpty
        $result.HtmlSection|Should -Match 'Volume inventory unavailable'
    }
    It 'reports an empty inventory explicitly without declaring healthy capacity' {
        Mock Get-PhysicalDisk { }
        Mock Get-CimInstance { }
        $result=Get-StorageAnalysis
        $result.State|Should -Be NotEvaluated
        $result.PhysicalInventoryState|Should -Be Empty
        $result.VolumeInventoryState|Should -Be Empty
        $result.CriticalSpace|Should -BeNullOrEmpty
        $result.HtmlSection|Should -Match 'No physical disks reported'
        $result.HtmlSection|Should -Match 'No fixed volumes reported'
    }
    It 'does not invent volume space from <Case> values' -ForEach @(
        @{Case='missing total';Size=$null;Free=1GB},@{Case='missing free';Size=100GB;Free=$null},
        @{Case='zero total';Size=0;Free=0},@{Case='negative free';Size=100GB;Free=-1},
        @{Case='free above total';Size=100GB;Free=101GB},@{Case='non numeric';Size='invalid';Free=1},
        @{Case='non finite';Size=[double]::PositiveInfinity;Free=1}
    ) {
        Mock Get-PhysicalDisk { }
        Mock Get-CimInstance {[pscustomobject]@{DeviceID='Q:';DriveType=3;Size=$Size;FreeSpace=$Free}}
        $result=Get-StorageAnalysis
        $result.Volumes[0].UsedPercent|Should -BeNullOrEmpty
        $result.CriticalSpace|Should -BeNullOrEmpty
        $result.HtmlSection|Should -Match 'Space not evaluated'
        $result.HtmlSection|Should -Not -Match 'width:0%|width:-|width:NaN|width:Infinity'
    }
    It 'uses exact occupancy for the low-space threshold before display rounding' -ForEach @(@{Free=10.4GB;Critical=$false},@{Free=10GB;Critical=$true},@{Free=0;Critical=$true},@{Free=100GB;Critical=$false}) {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';Size=1TB;BusType='NVMe';MediaType='SSD';HealthStatus='Healthy'}}
        Mock Get-CimInstance {[pscustomobject]@{DeviceID='Q:';DriveType=3;Size=100GB;FreeSpace=$Free}}
        $result=Get-StorageAnalysis
        $result.CriticalSpace|Should -Be $Critical
        $result.Volumes[0].UsedPercent|Should -BeGreaterOrEqual 0
        $result.Volumes[0].UsedPercent|Should -BeLessOrEqual 100
    }
    It 'preserves a known critical volume alongside another with unavailable capacity' {
        Mock Get-PhysicalDisk { }
        Mock Get-CimInstance {@([pscustomobject]@{DeviceID='Q:';DriveType=3;Size=100GB;FreeSpace=1GB},[pscustomobject]@{DeviceID='R:';DriveType=3;Size=100GB;FreeSpace=$null})}
        $result=Get-StorageAnalysis
        $result.CriticalSpace|Should -BeTrue
        $result.State|Should -Be Partial
        $result.Volumes.Count|Should -Be 2
        $result.Volumes[1].UsedPercent|Should -BeNullOrEmpty
    }
    It 'does not present unavailable physical disk capacity as zero GB' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';MediaType='SSD';BusType='NVMe';Size=$null;HealthStatus='Healthy'}}
        Mock Get-CimInstance {[pscustomobject]@{DeviceID='Q:';DriveType=3;Size=100GB;FreeSpace=50GB}}
        $result=Get-StorageAnalysis
        $result.Disks[0].SizeGB|Should -BeNullOrEmpty
        $result.State|Should -Be Partial
        $result.HtmlSection|Should -Match 'Disk capacity unavailable'
        $result.HtmlSection|Should -Not -Match '<td>0 GB</td>'
    }
    It 'keeps a healthy reported NVMe device with a valid volume as observed inventory' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';MediaType='SSD';BusType='NVMe';Size=1TB;HealthStatus='Healthy'}}
        Mock Get-CimInstance {[pscustomobject]@{DeviceID='Q:';DriveType=3;Size=100GB;FreeSpace=50GB}}
        $result=Get-StorageAnalysis
        $result.State|Should -Be Observed
        $result.Notes.Count|Should -Be 0
        $result.Disks[0].Health|Should -Be Healthy
        $result.HasNVMe|Should -BeTrue
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {$ClassName -eq 'Win32_LogicalDisk' -and $OperationTimeoutSec -eq 10}
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
    It 'resolves every adapter before the first DNS mutation' {
        $path=Join-Path $TestDrive 'missing-adapter.json';Save-AtlasDnsSnapshot -AdapterNames Ethernet -Path $path|Out-Null
        $s=Get-Content $path -Raw|ConvertFrom-Json
        $s.Adapters[1].Guid='a4c5366a-dae2-484e-a211-518ff110f126'
        $s|ConvertTo-Json -Depth 8|Set-Content $path
        {Restore-AtlasDnsSnapshot -Path $path}|Should -Throw '*cannot be identified*'
        Should -Invoke Set-DnsClientServerAddress -Times 0 -Exactly
    }
    It 'rejects a mismatching IP family before any mutation' {
        $path=Join-Path $TestDrive 'wrong-family.json';Save-AtlasDnsSnapshot -AdapterNames Ethernet -Path $path|Out-Null
        $s=Get-Content $path -Raw|ConvertFrom-Json;$s.Adapters[1].Servers=@('1.1.1.1')
        $s|ConvertTo-Json -Depth 8|Set-Content $path
        {Restore-AtlasDnsSnapshot -Path $path}|Should -Throw '*address family*'
        Should -Invoke Set-DnsClientServerAddress -Times 0 -Exactly
    }
}
