#Requires -Version 5.1
#Requires -Modules Pester

Describe 'Quoted paths for the real launcher invocation' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Start-Process { [CmdletBinding()] param($FilePath,$ArgumentList,$WorkingDirectory,$Verb,[switch]$Wait) throw 'Real process blocked' }
        function Write-AtlasLog { param($Message,$Level,$Tool) }
        function Invoke-AtlasRunnerTempCleanup { }
        function Get-AtlasToolScript { param($FunctionName) throw 'Real download blocked' }
        function Get-AtlasSecureRunDir { throw 'Real run directory blocked' }
        function Initialize-AtlasSecureDirectory { param($Path) throw 'Real ACL change blocked' }
        function Unblock-AtlasFile { param($Path) throw 'Real unblock blocked' }
        function Test-IsAdmin { $false }
        function Test-AtlasToolAvailability { param($Tool,$Capabilities) [pscustomobject]@{Available=$true;Reason=''} }
        function Get-AtlasToolRuntime { param($Tool) 'powershell.exe' }
        . (Get-TestFunction $script:RepoRoot 'src/lib/Release.ps1' 'Get-AtlasTextHash')
        . (Get-TestFunction $script:RepoRoot 'src/lib/ToolRunner.ps1' 'Get-AtlasToolExpectedHash')
        . (Get-TestFunction $script:RepoRoot 'src/lib/ToolRunner.ps1' 'Invoke-AtlasTool')
        . (Get-TestFunction $script:RepoRoot 'src/lib/Admin.ps1' 'Invoke-AsAdmin')
        $ast=Get-TestAst $script:RepoRoot 'launcher.ps1'
        $assignment=$ast.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$script:AtlasChildLibrarySource'},$true)
        $script:RealChildSource=$assignment.Right.Expression.Value
    }
    BeforeEach {
        $script:RunDir=Join-Path $TestDrive 'profile with spaces'
        New-Item -ItemType Directory -Path $script:RunDir -Force | Out-Null
        $script:ToolFile=Join-Path $TestDrive 'fake-tool.ps1'
        [IO.File]::WriteAllText($script:ToolFile,'function Invoke-Fixture { Write-Output "fixture" }',[Text.UTF8Encoding]::new($true))
        $script:AtlasToolKitSource=''
        $script:AtlasPS7CachedPath=$null
        $script:AtlasDevelopmentMode=$false
        $script:AtlasRoot=$TestDrive
        $script:AtlasChildLibrarySource='# fixture child libraries'
        $script:AtlasToolHashes=@{'Invoke-Fixture.ps1'=(Get-AtlasTextHash ([IO.File]::ReadAllText($script:ToolFile,[Text.Encoding]::UTF8)))}
        Mock Start-Process { }
        Mock Get-AtlasToolScript { $script:ToolFile }
        Mock Get-AtlasSecureRunDir { $script:RunDir }
        Mock Initialize-AtlasSecureDirectory { $script:RunDir }
        Mock Unblock-AtlasFile { }
    }
    It 'quotes the file argument when a tool is launched' {
        Invoke-AtlasTool -Tool @{name='Fixture'; id='fixture';function='Invoke-Fixture';requiresAdmin=$false}
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[-2] -eq '-File' -and $ArgumentList[-1] -match '^".*profile with spaces.*\.ps1"$'
        }
    }
    It 'rejects inline execution before loading any tool or launching a process' {
        {Invoke-AtlasTool -Tool @{name='Fixture';id='fixture';function='Invoke-Fixture';runsInNewWindow=$false}}|Should -Throw '*Inline*not supported*'
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Get-AtlasToolScript -Times 0 -Exactly
    }
    It 'keeps the quoting when requesting elevation' {
        Invoke-AtlasTool -Tool @{name='Fixture'; id='fixture';function='Invoke-Fixture';requiresAdmin=$true}
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $Verb -eq 'RunAs' -and $ArgumentList[-1] -match '^".*\.ps1"$'
        }
    }
    It 'quotes the administrative wrapper without executing its payload' {
        Invoke-AsAdmin -ScriptBlock { Write-Output 'fixture' } | Should -BeTrue
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $Verb -eq 'RunAs' -and $ArgumentList[-1] -match '^".*profile with spaces.*\.ps1"$'
        }
    }
    It 'blocks execution when the required child libraries are absent' {
        $script:AtlasChildLibrarySource=''
        { Invoke-AtlasTool -Tool @{name='Fixture';id='fixture';function='Invoke-Fixture'} } | Should -Throw '*libraries*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'blocks a tool changed between acquisition and wrapper creation' {
        Add-Content -LiteralPath $script:ToolFile -Value '# changed'
        { Invoke-AtlasTool -Tool @{name='Fixture';id='fixture';function='Invoke-Fixture'} } | Should -Throw '*changed*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'runs the actual generated wrapper with all helpers and complex paths without modifying a tool' {
        $script:AtlasChildLibrarySource=$script:RealChildSource
        $script:AtlasChildLibrarySource += "`nfunction Test-AtlasToolAvailability { param(`$Tool,`$Capabilities) [pscustomobject]@{Available=`$true} }`nfunction Get-AtlasPlatformCapabilities { param([switch]`$Refresh) [pscustomobject]@{Baseline=`$true} }`n"
        $script:RunDir=Join-Path $TestDrive ("Jos$([char]0xe9)'s profile with spaces")
        New-Item -ItemType Directory -Path $script:RunDir -Force | Out-Null
        $fixture=@'
function Read-Host { 'fixture-no-prompt' }
function Invoke-Fixture {
    foreach ($name in @('Resolve-AtlasDependency','Install-AtlasPS7','Test-AtlasRelease','Write-AtlasHeader','ConvertTo-AtlasNativeArgument','Stop-AtlasOwnedNativeProcess','Invoke-AtlasNativeProcess')) {
        if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing helper: $name" }
    }
    if ((Get-AtlasDependencyDefinition 'PowerShell7').Version -ne '7.6.9') { throw 'Missing catalog' }
    Write-Output 'child-context-ok'
}
'@
        [IO.File]::WriteAllText($script:ToolFile,$fixture,[Text.UTF8Encoding]::new($false))
        $script:AtlasToolHashes['Invoke-Fixture.ps1']=Get-AtlasTextHash $fixture
        $before=(Get-FileHash $script:ToolFile -Algorithm SHA256).Hash
        Invoke-AtlasTool -Tool @{name='Fixture';id='fixture';function='Invoke-Fixture'}
        $wrapper=Get-ChildItem -LiteralPath $script:RunDir -Filter 'run-*.ps1' | Select-Object -First 1
        $wrapper | Should -Not -BeNullOrEmpty
        $engine=(Get-Process -Id $PID).Path
        $output=& $engine -NoProfile -File $wrapper.FullName 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $output | Should -Match 'child-context-ok'
        (Get-FileHash $script:ToolFile -Algorithm SHA256).Hash | Should -Be $before
    }
}

Describe 'Explicit runtime selection' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction (Split-Path -Parent $PSScriptRoot) 'src/lib/ToolRunner.ps1' 'Get-AtlasToolRuntime')
    }
    BeforeEach {
        $script:AtlasPS7CachedPath=Join-Path $TestDrive 'old-pwsh.exe'
        Mock Test-Path { $true }
        $script:Contract=@{runtime=@{engine='windows-powershell';minimumVersion='5.1';architecture='x64';libraries=@('ToolKit','Dependencies','PS7','Release')}}
    }
    It 'uses Windows PowerShell when declared even if a PS7 path is cached' -Skip:($env:OS -ne 'Windows_NT') {
        Get-AtlasToolRuntime -Tool $script:Contract | Should -Match 'System32[\\/]WindowsPowerShell[\\/]v1.0[\\/]powershell.exe$'
    }
    It 'rejects an undeclared engine without falling back' {
        $script:Contract.runtime.engine='unknown'
        { Get-AtlasToolRuntime -Tool $script:Contract } | Should -Throw '*Unknown runtime*'
    }
    It 'does not silently substitute 5.1 for a missing required PS7' {
        $script:Contract.runtime.engine='pwsh'
        $script:AtlasPS7CachedPath=$null
        { Get-AtlasToolRuntime -Tool $script:Contract } | Should -Throw '*unavailable*'
    }
    It 'rejects an unsupported architecture' {
        $script:Contract.runtime.architecture='arm64'
        { Get-AtlasToolRuntime -Tool $script:Contract } | Should -Throw '*x64*'
    }
    It 'rejects an unknown helper requirement' {
        $script:Contract.runtime.libraries=@('Unknown')
        { Get-AtlasToolRuntime -Tool $script:Contract } | Should -Throw '*library*'
    }
    It 'resolves all 27 real manifest contracts without running any tool' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Test-Path { [IO.File]::Exists([string]$LiteralPath) }
        $catalog=Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'config/tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $catalog.tools.Count|Should -Be 27
        foreach($entry in $catalog.tools){
            $runtime=@{};foreach($property in $entry.runtime.PSObject.Properties){$runtime[$property.Name]=$property.Value}
            $runtime.libraries|Should -Contain Reports
            $runtime.libraries|Should -Contain Operations
            Get-AtlasToolRuntime -Tool @{runtime=$runtime}|Should -Match 'WindowsPowerShell[\\/]v1.0[\\/]powershell.exe$' -Because $entry.id
        }
    }
}

Describe 'False positive result guards' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GPUCheck.ps1' 'Get-GpuSessionLevel')
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-InstalarPaquetes.ps1'
        $assignment=$ast.Find({param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$alreadyInstalledCodes'
        },$true)
        if (-not $assignment) { throw 'WinGet status handling missing' }
        $script:WingetCodes=[scriptblock]::Create($assignment.Extent.Text + '; $alreadyInstalledCodes')
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-AIReadiness.ps1'
        $assignment=$ast.Find({param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$badDisk'
        },$true)
        if (-not $assignment) { throw 'Disk-health classification missing' }
        $script:DiskHealth=[scriptblock]::Create('param($diskRows) ' + $assignment.Extent.Text + '; $badDisk')
    }
    It 'does not classify missing telemetry as a passing GPU' {
        Get-GpuSessionLevel -Total 0 -HasTelemetry $false -StressRequested $true -SessionStatus Completed | Should -Be 'NO CONCLUYENTE'
    }
    It 'does not classify early stress termination as passing' {
        Get-GpuSessionLevel -Total 0 -HasTelemetry $true -StressRequested $true -SessionStatus ExitedEarly | Should -Be 'NO CONCLUYENTE'
    }
    It 'does not hide high-risk findings when telemetry is absent' {
        Get-GpuSessionLevel -Total 75 -HasTelemetry $false -StressRequested $true -SessionStatus ExitedEarly | Should -Be 'RIESGO ALTO'
    }
    It 'describes a quick test as observations at rest' {
        Get-GpuSessionLevel -Total 0 -HasTelemetry $true -StressRequested $false -SessionStatus Completed | Should -Be 'SIN HALLAZGOS EN REPOSO'
    }
    It 'limits a completed test to findings in that session' {
        Get-GpuSessionLevel -Total 0 -HasTelemetry $true -StressRequested $true -SessionStatus Completed | Should -Be 'SIN HALLAZGOS EN ESTA SESION'
    }
    It 'accepts only genuine WinGet skip statuses' {
        $codes=@(& $script:WingetCodes)
        $codes | Should -Contain -1978335189
        $codes | Should -Contain -1978335135
        $codes.Count | Should -Be 2
    }
    It 'does not treat absent applications or manifest/conversion errors as installed' {
        $codes=@(& $script:WingetCodes)
        foreach ($code in @(-1978335212,2316632083,2316632068,2316632145)) { $codes | Should -Not -Contain $code }
    }
    It 'distinguishes Unhealthy from Healthy' {
        & $script:DiskHealth @([pscustomobject]@{Health='Unhealthy'}) | Should -BeTrue
        & $script:DiskHealth @([pscustomobject]@{Health='Healthy'}) | Should -BeFalse
    }
}
Describe 'Verified onboarding wrapper behavior' {
    BeforeAll {
        $repo=Split-Path -Parent $PSScriptRoot
        $text=[IO.File]::ReadAllText((Join-Path $repo 'onboarding/install.bat'))
        $elevationLine=@($text -split "`r?`n"|Where-Object {$_ -match '^\s+powershell.exe.*Start-Process'})[0]
        $elevationSource=[regex]::Match($elevationLine,'-Command "(?<code>.*)"').Groups['code'].Value
        $elevationAst=[Management.Automation.Language.Parser]::ParseInput($elevationSource,[ref]$null,[ref]$null)
        $elevationCall=$elevationAst.Find({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Start-Process'},$true)
        if(-not $elevationCall){throw 'Missing BAT elevation call'}
        $script:RealElevationCall=[scriptblock]::Create($elevationCall.Extent.Text)
        $script:OnboardingPayload=([regex]::Matches($text,'(?m)^\s+"(?<code>.*)"(?: \^)?\r?$')|ForEach-Object {$_.Groups['code'].Value}) -join ' '
        $errors=$null
        $ast=[Management.Automation.Language.Parser]::ParseInput($script:OnboardingPayload,[ref]$null,[ref]$errors)
        if($errors.Count){throw ($errors|Out-String)}
        foreach($name in @('Invoke-VerifiedOnboarding','Invoke-OnboardingFile','Assert-OnboardingDirectory','New-OnboardingAttempt')) {
            $node=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
            . ([scriptblock]::Create($node.Extent.Text))
        }
        $script:FixtureBytes=[Text.Encoding]::UTF8.GetBytes('# verified fixture')
        $script:RealDirectoryCheck=[scriptblock]::Create((Get-Command Assert-OnboardingDirectory).Definition)
        $hash=[Security.Cryptography.SHA256]::Create()
        try {$script:FixtureHash=([BitConverter]::ToString($hash.ComputeHash($script:FixtureBytes))).Replace('-','').ToLowerInvariant()} finally {$hash.Dispose()}
    }
    BeforeEach {
        $script:Attempt=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $script:Attempt|Out-Null
        Mock Assert-OnboardingDirectory {}
        Mock Invoke-OnboardingFile {}
        Mock Invoke-WebRequest {
            if($OutFile){[IO.File]::WriteAllBytes($OutFile,$script:FixtureBytes)}else{[pscustomobject]@{Content=($script:FixtureHash+'  install-rustdesk.ps1')}}
        }
    }
    It 'never executes a download with the wrong hash' {
        Mock Invoke-WebRequest {if($OutFile){[IO.File]::WriteAllText($OutFile,'tampered')}else{[pscustomobject]@{Content=$script:FixtureHash}}}
        {Invoke-VerifiedOnboarding $script:Attempt}|Should -Throw '*integrity*'
        Should -Invoke Invoke-OnboardingFile -Times 0 -Exactly
    }
    It 'creates independent attempts and rejects redirected or untrusted directories' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Set-Acl {}
        $first=New-OnboardingAttempt -Base $TestDrive
        $second=New-OnboardingAttempt -Base $TestDrive
        $first|Should -Not -Be $second
        Split-Path $first -Leaf|Should -Match '^[a-f0-9]{32}$'
        $acl=[Security.AccessControl.DirectorySecurity]::new()
        $acl.SetOwner([Security.Principal.SecurityIdentifier]::new('S-1-1-0'))
        Mock Get-Acl {$acl}
        {& $script:RealDirectoryCheck $script:Attempt}|Should -Throw '*owner*'
        Mock Get-Item {[pscustomobject]@{PSIsContainer=$true;Attributes=[IO.FileAttributes]::ReparsePoint}}
        {& $script:RealDirectoryCheck $script:Attempt}|Should -Throw '*Redirected*'
    }
    It 'locks verified bytes against replacement throughout execution' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Invoke-OnboardingFile {
            [IO.File]::ReadAllText($Path)|Should -Be '# verified fixture'
            {[IO.File]::WriteAllText($Path,'replaced')}|Should -Throw
        }
        Invoke-VerifiedOnboarding $script:Attempt
        Should -Invoke Invoke-OnboardingFile -Times 1 -Exactly
        {Invoke-VerifiedOnboarding $script:Attempt}|Should -Throw
        Should -Invoke Invoke-OnboardingFile -Times 1 -Exactly
    }
    It 'refuses concurrent or repeated use of an attempt before any download' {
        $lock=[IO.File]::Open((Join-Path $script:Attempt '.run.lock'),'CreateNew','ReadWrite','None')
        try {{Invoke-VerifiedOnboarding $script:Attempt}|Should -Throw} finally {$lock.Dispose()}
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }
    It 'also prevents different attempts from running installers concurrently' {
        $active=[IO.File]::Open((Join-Path (Split-Path $script:Attempt) '.active.lock'),'OpenOrCreate','ReadWrite','None')
        try {{Invoke-VerifiedOnboarding $script:Attempt}|Should -Throw} finally {$active.Dispose()}
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }
    It 'propagates policy/installer failure and permits a separate new attempt' {
        Mock Invoke-OnboardingFile {throw 'Policy blocked'}
        {Invoke-VerifiedOnboarding $script:Attempt}|Should -Throw '*Policy blocked*'
        $other=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $other|Out-Null
        Mock Invoke-OnboardingFile {}
        Invoke-VerifiedOnboarding $other
        Should -Invoke Invoke-OnboardingFile -Times 2 -Exactly
    }
    It 'transports special paths as environment data and preserves effective execution policy' {
        $script:OnboardingPayload|Should -Not -Match 'ExecutionPolicy|Unblock-File|Invoke-Expression|EncodedCommand'
        $env:ATLAS_ONBOARDING_SELF="C:\Users\O'Neil\Downloads\Atlas & soporte.bat"
        try {
            Mock Start-Process {[pscustomobject]@{ExitCode=0}}
            # Execute the actual BAT elevation call with only the process boundary mocked.
            & $script:RealElevationCall|Out-Null
            Should -Invoke Start-Process -Times 1 -ParameterFilter {$FilePath -eq $env:ATLAS_ONBOARDING_SELF}
        } finally {Remove-Item Env:ATLAS_ONBOARDING_SELF}
    }
}

Describe 'Audited process deadlines and verified GPU stop' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        foreach($name in @('Stop-Proc','Wait-WithProgress','Get-GpuSessionLevel')){. (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GPUCheck.ps1' $name)}
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-Fase0.ps1' 'Get-TunnelState')
        function Invoke-AtlasNativeProcess {param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Native boundary blocked'}
        function New-TestOwnedProcess {
            $p=[pscustomobject]@{HasExited=$false;ForceFails=$false;ForceCalls=0;Graceful=$false;Waits=[Collections.Generic.List[int]]::new()}
            $p|Add-Member ScriptMethod CloseMainWindow {return $this.Graceful}
            $p|Add-Member ScriptMethod WaitForExit {param($milliseconds)$this.Waits.Add($milliseconds);if($this.Graceful){$this.HasExited=$true};return $this.HasExited}
            $p|Add-Member ScriptMethod Refresh {}
            $p|Add-Member ScriptMethod Kill {$this.ForceCalls++;if($this.ForceFails){throw 'Denied'};$this.HasExited=$true}
            return $p
        }
    }
    It 'keeps a timed out or empty tunnel query unevaluated' {
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='TimedOut';Stdout='';StdoutTruncated=$false}}
        Get-TunnelState @('interface','teredo','show','state')|Should -Match 'NotEvaluated.*TimedOut'
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -ParameterFilter {$TimeoutSeconds -eq 10 -and $ArgumentList[1] -eq 'teredo'}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='';StdoutTruncated=$false}}
        Get-TunnelState @('interface','teredo','show','state')|Should -Match 'NotEvaluated'
    }
    It 'confirms graceful or forced termination, with bounded waits' {
        $p=New-TestOwnedProcess;$p.Graceful=$true
        Stop-Proc $p|Should -BeTrue
        $p=New-TestOwnedProcess
        Stop-Proc $p|Should -BeTrue
        @($p.Waits)|Should -Be @(2000,5000)
    }
    It 'reports failure to terminate rather than claiming a successful stop or clean session' {
        $p=New-TestOwnedProcess
        $p.ForceFails=$true
        Stop-Proc $p|Should -BeFalse
        Get-GpuSessionLevel -Total 0 -HasTelemetry $true -StressRequested $true -SessionStatus ProcessStopUnconfirmed|Should -Be 'NO CONCLUYENTE'
        $p.ForceCalls|Should -Be 1
    }
    It 'terminates only its own harmless real child and confirms exit' -Skip:($env:OS -ne 'Windows_NT') {
        $child=Microsoft.PowerShell.Management\Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile','-Command','Start-Sleep -Seconds 20') -WindowStyle Hidden -PassThru
        try { Stop-Proc $child|Should -BeTrue;$child.HasExited|Should -BeTrue }
        finally {if(-not $child.HasExited){$child.Kill()};$child.Dispose()}
    }
}
