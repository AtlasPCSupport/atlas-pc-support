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
        . (Get-TestFunction $script:RepoRoot 'src/lib/ToolRunner.ps1' 'Invoke-AtlasTool')
        . (Get-TestFunction $script:RepoRoot 'src/lib/Admin.ps1' 'Invoke-AsAdmin')
    }
    BeforeEach {
        $script:RunDir=Join-Path $TestDrive 'profile with spaces'
        New-Item -ItemType Directory -Path $script:RunDir -Force | Out-Null
        $script:ToolFile=Join-Path $TestDrive 'fake-tool.ps1'
        [IO.File]::WriteAllText($script:ToolFile,'function Invoke-Fixture { Write-Output "fixture" }',[Text.UTF8Encoding]::new($true))
        $script:AtlasToolKitSource=''
        $script:AtlasPS7CachedPath=$null
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
