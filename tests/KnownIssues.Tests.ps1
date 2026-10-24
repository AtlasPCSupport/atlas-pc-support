#Requires -Version 5.1
#Requires -Modules Pester
<#
Acceptance tests for confirmed defects. These SHOULD FAIL until their fixes land.
Run explicitly using Invoke-LocalChecks.ps1 -IncludeKnownIssues.
Only extracted functions/branches run. Process, network and account operations
are replaced by local functions that throw unless mocked. No real MSI is used.
#>

Describe 'Critical acceptance tests pending phase 1' -Tag 'KnownIssue' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        function Get-TestAst([string]$RelativePath) {
            $errors = $null
            $text = Get-Content -LiteralPath (Join-Path $script:RepoRoot $RelativePath) -Raw -Encoding UTF8
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$null, [ref]$errors)
            if ($errors.Count) { throw "Cannot test invalid source: $RelativePath" }
            return $ast
        }
        function Get-TestFunction([string]$RelativePath, [string]$Name) {
            $ast = Get-TestAst $RelativePath
            $node = $ast.Find({ param($n)
                $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name
            }, $true)
            if (-not $node) { throw "Missing function: $Name" }
            return [scriptblock]::Create($node.Extent.Text)
        }

        # Defense in depth: never fall through to a native mutating command.
        function Start-Process { [CmdletBinding()] param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru) throw 'Real process execution blocked in tests' }
        function Invoke-WebRequest { [CmdletBinding()] param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec) throw 'Network blocked in tests' }
        function Get-AuthenticodeSignature { [CmdletBinding()] param($FilePath) throw 'Use mocked signature only' }
        function New-LocalUser { [CmdletBinding()] param($Name, $FullName, $Password, [switch]$NoPassword, [switch]$PasswordNeverExpires) throw 'Real account creation blocked in tests' }
        function Get-LocalGroup { [CmdletBinding()] param() throw 'Real group lookup blocked in tests' }
        function Get-LocalGroupMember { [CmdletBinding()] param($SID) throw 'Real group lookup blocked in tests' }
        function Get-LocalUser { [CmdletBinding()] param($Name, $SID) throw 'Real account lookup blocked in tests' }
        function Add-LocalGroupMember { [CmdletBinding()] param($SID, $Group, $Member) throw 'Real group mutation blocked in tests' }
        function Remove-LocalGroupMember { [CmdletBinding()] param($SID, $Member) throw 'Real group mutation blocked in tests' }
        function _Write-AtlasStepCompat { param($Message) }
        function _Write-AtlasOkCompat { param($Message) }
        function _Write-AtlasWarnCompat { param($Message) }
        function Escribir-Centrado { param($Text, $Color) }
        function Escribir-Descripcion { param($Que, $Recomendacion, $Precaucion) }
        function Dibujar-Header { }
        function Wait-AtlasReturn { param($Message) }
        function Wait-AtlasContinue { param($Message) }
        function _Get-PS7Path { 'mock-pwsh.exe' }
        . (Join-Path $script:RepoRoot 'src/lib/PS7.ps1')
        . (Get-TestFunction 'src/tools/Invoke-ActualizarPowerShell.ps1' '_Install-PS7')
        . (Get-TestFunction 'src/tools/Invoke-EntregaPC.ps1' 'Crear-NuevoUsuario')
        $ast = Get-TestAst 'src/tools/Invoke-MenorPrivilegio.ps1'
        $menu = $ast.Find({ param($n)
            $n -is [System.Management.Automation.Language.SwitchStatementAst] -and $n.Condition.Extent.Text -eq '$seleccion'
        }, $true)
        $clause = $menu.Clauses | Where-Object { $_.Item1.Value -eq '2' }
        if (-not $clause) { throw 'Missing account demotion action' }
        $script:DemoteAction = [scriptblock]::Create("switch ('2') { '2' $($clause.Item2.Extent.Text) }")
    }

    BeforeEach {
        Mock Write-Host { }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
        Mock Get-AtlasPS7Path { 'mock-pwsh.exe' }
        Mock Invoke-WebRequest { throw 'Network blocked in tests' }
        $script:Msi = Join-Path $TestDrive 'not an installer.msi'
        Set-Content -LiteralPath $script:Msi -Value 'Non-executable test fixture' -Encoding ASCII
        $script:L = @{
            UsingLocalMsi = '{0}'; Installing = 'install'; InstallOK = '{0}'
            AskNewLogon = 'name'; AskNewDisp = 'display'; AskPwdLbl = 'password'; AskAdmin = 'admin'
            UserCreated = '{0}'; ErrFmt = '{0}'; T2VerifyErr = '{0}'; ErrGeneric = '{0}'
            T2ConfirmPrompt = 'confirm'; T2ConfirmWord = 'YES'; T2LogoffAsk = 'logoff'
        }
        $script:padInput = 20
    }

    It 'A01: rejects an unsigned MSI in the standalone updater' {
        Mock Get-AuthenticodeSignature { [pscustomobject]@{ Status = 'NotSigned'; StatusMessage = 'test fixture' } }
        Mock Get-AtlasPS7ExpectedHash { (Get-FileHash -LiteralPath $script:Msi -Algorithm SHA256).Hash.ToLowerInvariant() }
        $failure = $null
        try { _Install-PS7 -OfflineSource $script:Msi -L $script:L -Version 'test' -MsiName 'fixture.msi' } catch { $failure = $_ }
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Get-AuthenticodeSignature -Times 1 -Exactly
        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -Match 'signature|firma|Authenticode'
    }

    It 'A01: refuses offline installation without a required expected hash' {
        $failure = $null
        try { Install-AtlasPS7 -OfflineSource $script:Msi } catch { $failure = $_ }
        Should -Invoke Start-Process -Times 0 -Exactly
        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -Match 'hash|SHA|checksum'
    }

    It 'A02: refuses to create an administrator with an empty password' {
        Mock Read-Host {
            if ($AsSecureString) { return [securestring]::new() }
            switch ($Prompt) { 'name' { 'AtlasTestAdmin' }; 'display' { 'Test' }; 'admin' { 'Y' }; default { 'N' } }
        }
        Mock New-LocalUser { [pscustomobject]@{ Name = 'AtlasTestAdmin' } }
        Mock Get-LocalGroup { [pscustomobject]@{ SID = 'S-1-5-32-544'; Name = 'Test Administrators' } }
        Mock Add-LocalGroupMember { }
        Crear-NuevoUsuario
        Should -Invoke Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -eq 'admin' }
        Should -Invoke New-LocalUser -Times 0 -Exactly
    }

    It 'A02: a disabled backup admin does not permit demoting the active admin' {
        Mock Get-LocalGroupMember {
            [pscustomobject]@{ Name = "TEST\$env:USERNAME"; ObjectClass = 'User'; SID = 'S-1-5-21-1-1001' }
            [pscustomobject]@{ Name = 'TEST\DisabledBackup'; ObjectClass = 'User'; SID = 'S-1-5-21-1-1002' }
        }
        Mock Get-LocalUser {
            [pscustomobject]@{ Name = $env:USERNAME; Enabled = $true; SID = 'S-1-5-21-1-1001' }
            [pscustomobject]@{ Name = 'DisabledBackup'; Enabled = $false; SID = 'S-1-5-21-1-1002' }
        }
        Mock Read-Host { if ($Prompt -eq 'confirm') { 'YES' } else { 'N' } }
        Mock Add-LocalGroupMember { }
        Mock Remove-LocalGroupMember { }
        & $script:DemoteAction
        Should -Invoke Get-LocalGroupMember -Times 1 -Exactly
        Should -Invoke Remove-LocalGroupMember -Times 0 -Exactly
    }
}
