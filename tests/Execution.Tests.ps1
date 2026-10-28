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
