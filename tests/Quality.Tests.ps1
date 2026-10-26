#Requires -Modules Pester
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
    It 'requires fresh output at all four diagnostic export call sites' {
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1'
        $calls=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Start-ProcessWithTimeout'},$true))
        $calls.Count | Should -Be 4
        foreach($call in $calls) {
            @($call.CommandElements | Where-Object {$_ -is [Management.Automation.Language.CommandParameterAst]}).ParameterName | Should -Contain ExpectedOutput
        }
    }
}

Describe 'Diagnostic dependency installation boundaries' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' 'Resolve-DiagDep')
        function Find-FirstExistingPath { param($Candidates) }
        function Get-AtlasWingetPath { 'fixture-winget.exe' }
        function Invoke-AtlasNativeProcess { [CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds,$SuccessCodes) throw 'Real installation blocked' }
    }
    BeforeEach {
        Mock Find-FirstExistingPath { $null }
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='TimedOut';ExitCode=0} }
    }
    It 'keeps an installed diagnostic dependency without starting an installer' {
        Mock Find-FirstExistingPath { 'existing.exe' }
        Mock Get-Item { [pscustomobject]@{Attributes=0} }
        Resolve-DiagDep -WingetId 'Fixture.Tool' -InstallPaths @('existing.exe') | Should -Be existing.exe
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
    It 'reports a timed out dependency before staging a partial installation' {
        {Resolve-DiagDep -WingetId 'Fixture.Tool' -InstallPaths @('missing.exe')} | Should -Throw '*TimedOut*'
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'fixture-winget.exe' -and $TimeoutSeconds -eq 600 -and
            $ArgumentList[4] -eq '--source' -and $ArgumentList[5] -eq 'winget'
        }
        Should -Invoke Find-FirstExistingPath -Times 1 -Exactly
    }
    It 'looks up the installed file only after an accepted process result' {
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Correct';ExitCode=0} }
        Resolve-DiagDep -WingetId 'Fixture.Tool' -InstallPaths @('missing.exe') | Should -BeNullOrEmpty
        Should -Invoke Find-FirstExistingPath -Times 2 -Exactly
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
        Mock Get-Command { [pscustomobject]@{Source='fixture-nvidia.exe'} }
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='TimedOut';Stdout='Fixture, 8192, 30, 1'} }
        Get-AIRNvidiaSmi -WarningAction SilentlyContinue | Should -BeNullOrEmpty
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter {$TimeoutSeconds -eq 10}
    }
    It 'parses multiple GPUs and preserves unavailable sensor values' {
        Mock Get-Command { [pscustomobject]@{Source='fixture-nvidia.exe'} }
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Correct';Stdout="Fixture1, 8192, 30, 1`r`nFixture2, 16384, N/A, 2`r`n"} }
        $rows=@(Get-AIRNvidiaSmi)
        $rows.Count | Should -Be 2
        $rows[0].MemoryMB | Should -Be 8192
        $rows[1].TemperatureC | Should -BeNullOrEmpty
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
}

Describe 'Storage evidence without bus/size guesses' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-DiagnosticoMaster.ps1' 'Get-StorageAnalysis')
        function Get-PhysicalDisk {[CmdletBinding()]param() throw 'Real inventory blocked'}
        function Get-CimInstance {[CmdletBinding()]param($ClassName) throw 'Real inventory blocked'}
        $script:L=@{UnknownLbl='Unknown';StUnclass='Not classified'}
    }
    It 'does not label an unspecified large SATA disk as an HDD or unhealthy' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='<script>fixture</script>';MediaType='Unspecified';BusType='SATA';Size=1TB;HealthStatus=$null}}
        Mock Get-CimInstance { }
        $result=Get-StorageAnalysis
        $result.HasHDD|Should -BeFalse;$result.Disks[0].Health|Should -Be Unknown
        $result.HtmlSection|Should -Not -Match '<script>'; $result.HtmlSection|Should -Match '&lt;script&gt;'
    }
    It 'keeps an explicit HDD type and preserves a zero-valued status' {
        Mock Get-PhysicalDisk {[pscustomobject]@{FriendlyName='Fixture';MediaType='HDD';BusType='SATA';Size=1TB;HealthStatus=0}}
        Mock Get-CimInstance { }
        $result=Get-StorageAnalysis
        $result.HasHDD|Should -BeTrue;$result.Disks[0].Health|Should -Be '0'
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
