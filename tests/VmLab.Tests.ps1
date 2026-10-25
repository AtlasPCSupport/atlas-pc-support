Describe 'Windows 10 lab boundaries and unattended metadata' {
    BeforeAll {. (Join-Path $PSScriptRoot 'vm/LabHelpers.ps1'); $fixtureComputer='ATLAS-QA'; $invalidComputer='DESKTOP-REAL'}
    It 'rejects paths outside the dedicated lab root' {
        {Assert-AtlasLabLocation -Root (Join-Path $TestDrive 'lab') -Path (Join-Path $TestDrive 'other/disk.vhdx')}|Should -Throw '*escapes*'
        {Assert-AtlasLabLocation -Root $TestDrive -Path (Join-Path $TestDrive 'vm/disk.vhdx')}|Should -Not -Throw
    }
    It 'creates well-formed edition-specific answers with escaped data' -ForEach @(@{Profile='Home'},@{Profile='Pro'},@{Profile='LTSC'}) {
        $password='RandomOnlyFixtureWith&<>"123456'
        [xml]$answer=New-AtlasLabAnswer -Profile $Profile -ImageName 'Windows 10 <test>' -Password $password -ComputerName $fixtureComputer
        $ns=[Xml.XmlNamespaceManager]::new($answer.NameTable);$ns.AddNamespace('u','urn:schemas-microsoft-com:unattend')
        $answer.SelectSingleNode('//u:MetaData/u:Value',$ns).InnerText|Should -Be 'Windows 10 <test>'
        $answer.SelectSingleNode('//u:LocalAccount/u:Password/u:Value',$ns).InnerText|Should -Be $password
        $answer.SelectSingleNode('//u:InstallTo/u:DiskID',$ns).InnerText|Should -Be '0'
        $answer.SelectSingleNode('//u:AutoLogon/u:LogonCount',$ns).InnerText|Should -Be '1'
        $answer.SelectNodes('//u:Key',$ns).Count|Should -Be 2
        $answer.SelectSingleNode('//u:UserData/u:ProductKey/u:Key',$ns).InnerText|Should -Match '^[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}$'
        $answer.SelectNodes('//u:component[@name="Microsoft-Windows-Shell-Setup"]/u:ProductKey',$ns).Count|Should -Be 0
    }
    It 'rejects weak credentials and arbitrary computer names' {
        {New-AtlasLabAnswer -Profile Home -ImageName Fixture -Password short -ComputerName $fixtureComputer}|Should -Throw '*20*'
        {New-AtlasLabAnswer -Profile Home -ImageName Fixture -Password ('x'*24) -ComputerName $invalidComputer}|Should -Throw '*computer*'
    }
    It 'does not format host disks or change host security/group/network settings' {
        foreach($file in @('Invoke-Win10Lab.ps1','Resume-Win10Lab.ps1','LabHelpers.ps1')){
            $text=Get-Content (Join-Path $PSScriptRoot "vm/$file") -Raw -Encoding UTF8
            $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($text,[ref]$null,[ref]$errors)
            $errors.Count|Should -Be 0
            $commands=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst]},$true)|ForEach-Object {$_.GetCommandName()})
            foreach($forbidden in @('Format-Volume','Initialize-Disk','Clear-Disk','Mount-VHD','Add-LocalGroupMember','Set-MpPreference','Add-MpPreference','Set-ExecutionPolicy','New-VMSwitch','Remove-VM')){
                $commands|Should -Not -Contain $forbidden
            }
        }
    }
}

Describe 'Guest readiness before file transfer' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'vm/LabHelpers.ps1')
        $assignment=(Get-Command Wait-AtlasLabDesktop).ScriptBlock.Ast.Find({
            param($node)
            $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.VariablePath.UserPath -eq 'readyScript'
        },$true)
        $desktopPredicate=$assignment.Right.Find({param($node)$node -is [Management.Automation.Language.ScriptBlockExpressionAst]},$true).ScriptBlock.GetScriptBlock()
    }
    BeforeEach {
        $previousComputer=$env:COMPUTERNAME;$env:COMPUTERNAME='ATLAS-QA'
        Mock Get-CimInstance {[pscustomobject]@{Model=$fixtureModel}}
        Mock Get-ItemProperty {[pscustomobject]@{SystemSetupInProgress=$systemSetup;OOBEInProgress=$oobe}}
        Mock Test-Path {$profileExists}
        Mock Get-Process {if($explorerExists){[pscustomobject]@{ProcessName='explorer'}}}
    }
    AfterEach {$env:COMPUTERNAME=$previousComputer}
    It '<case>' -ForEach @(
        @{case='does not accept a profile created while OOBE is running';systemSetup=0;oobe=1;profileExists=$true;explorerExists=$true;fixtureModel='Virtual Machine';expectedComputer='ATLAS-QA';ready=$false},
        @{case='does not accept system setup';systemSetup=1;oobe=0;profileExists=$true;explorerExists=$true;fixtureModel='Virtual Machine';expectedComputer='ATLAS-QA';ready=$false},
        @{case='does not accept unknown setup state';systemSetup=$null;oobe=$null;profileExists=$true;explorerExists=$true;fixtureModel='Virtual Machine';expectedComputer='ATLAS-QA';ready=$false},
        @{case='requires the interactive shell';systemSetup=0;oobe=0;profileExists=$true;explorerExists=$false;fixtureModel='Virtual Machine';expectedComputer='ATLAS-QA';ready=$false},
        @{case='requires the lab user profile';systemSetup=0;oobe=0;profileExists=$false;explorerExists=$true;fixtureModel='Virtual Machine';expectedComputer='ATLAS-QA';ready=$false},
        @{case='rejects another computer';systemSetup=0;oobe=0;profileExists=$true;explorerExists=$true;fixtureModel='Virtual Machine';expectedComputer='ATLAS-OTHER';ready=$false},
        @{case='rejects a physical computer';systemSetup=0;oobe=0;profileExists=$true;explorerExists=$true;fixtureModel='Physical Computer';expectedComputer='ATLAS-QA';ready=$false},
        @{case='accepts the completed owned VM desktop';systemSetup=0;oobe=0;profileExists=$true;explorerExists=$true;fixtureModel='Virtual Machine';expectedComputer='ATLAS-QA';ready=$true}
    ) {
        (& $desktopPredicate $expectedComputer)|Should -Be $ready
    }
}
