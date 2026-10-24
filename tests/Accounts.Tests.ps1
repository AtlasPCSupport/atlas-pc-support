#Requires -Version 5.1
#Requires -Modules Pester

Describe 'A02 account safety regressions' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        # Every account/process command is shadowed before source is loaded. A
        # missing mock throws instead of ever reaching a real account operation.
        function Get-LocalUser { [CmdletBinding()] param($Name, $SID) throw 'Real account lookup blocked' }
        function Get-LocalGroup { [CmdletBinding()] param($SID) throw 'Real group lookup blocked' }
        function Get-LocalGroupMember { [CmdletBinding()] param($SID) throw 'Real group lookup blocked' }
        function New-LocalUser { [CmdletBinding()] param($Name, $FullName, $Password, [switch]$NoPassword, [switch]$PasswordNeverExpires) throw 'Real creation blocked' }
        function Set-LocalUser { [CmdletBinding()] param($Name, $SID, $FullName, $Password) throw 'Real modification blocked' }
        function Remove-LocalUser { [CmdletBinding()] param($Name, $SID) throw 'Real deletion blocked' }
        function Disable-LocalUser { [CmdletBinding()] param($Name, $SID) throw 'Real disable blocked' }
        function Enable-LocalUser { [CmdletBinding()] param($Name, $SID) throw 'Real enable blocked' }
        function Add-LocalGroupMember { [CmdletBinding()] param($SID, $Group, $Member) throw 'Real group mutation blocked' }
        function Remove-LocalGroupMember { [CmdletBinding()] param($SID, $Member) throw 'Real group mutation blocked' }
        function Start-Process { [CmdletBinding()] param($FilePath, $ArgumentList) throw 'Real process execution blocked' }
        function net { param($Operation, $Account, $Action) throw 'Native account fallback blocked' }
        function Escribir-Centrado { param($Text, $Color) }
        function Escribir-Descripcion { param($Que, $Recomendacion, $Precaucion) }
        function Dibujar-Header { }
        function Wait-AtlasReturn { param($Message) }
        function Wait-AtlasContinue { param($Message) }
        function Validar-Contrasena { param($Pass) }

        foreach ($name in @('Get-AtlasCurrentUserSid', 'Assert-AtlasLocalAdminRetention')) {
            . (Get-TestFunction $script:RepoRoot 'src/lib/ToolKit.ps1' $name)
        }
        foreach ($name in @('Crear-NuevoUsuario', 'Get-AtlasLocalUsersList', 'Quitar-UsuarioLocal', 'Cambiar-PasswordUsuario', 'Modificar-UsuarioActual')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-EntregaPC.ps1' $name)
        }
        $script:DemoteAction = Get-TestAccountAction $script:RepoRoot '2'
        $script:ToggleAction = Get-TestAccountAction $script:RepoRoot '5'
        $script:CreateAdminAction = Get-TestAccountAction $script:RepoRoot '1'
    }

    BeforeEach {
        $script:Current = [pscustomobject]@{ Name = 'ElevatedOperator'; SID = 'S-1-5-21-1-2-3-1001'; Enabled = $true; FullName = 'Operator' }
        $script:Backup = [pscustomobject]@{ Name = 'Backup'; SID = 'S-1-5-21-1-2-3-1002'; Enabled = $false; FullName = 'Backup' }
        $script:Standard = [pscustomobject]@{ Name = 'Customer'; SID = 'S-1-5-21-1-2-3-1003'; Enabled = $true; FullName = 'Customer' }
        $script:Created = [pscustomobject]@{ Name = 'NewUser'; SID = 'S-1-5-21-1-2-3-1004'; Enabled = $true }
        $script:Users = @($script:Current, $script:Backup, $script:Standard)
        $script:Admins = @($script:Current.SID, $script:Backup.SID)
        $script:StandardMembers = @()
        $script:Answers = [Collections.Generic.Queue[object]]::new()
        $script:FixturePassword = [securestring]::new()
        foreach ($character in 'Fixture only! 123'.ToCharArray()) { $script:FixturePassword.AppendChar($character) }
        $script:L = @{
            AskNewLogon = 'name'; AskNewDisp = 'display'; AskPwdLbl = 'password'; AskAdmin = 'admin'
            AskFullName = 'full name'; UserCreated = 'created:{0}'; UserRemovedOk = 'removed:{0}'
            ErrFmt = 'error:{0}'; ErrGeneric = 'error:{0}'; T2VerifyErr = 'error:{0}'
            T2ConfirmPrompt = 'confirm {0}'; T2ConfirmWord = 'YES'; T2LogoffAsk = 'logoff'
            PwdResetConfirm = 'reset {0}'; PwdResetWord = 'RESET'; ReloadPanel = 'Reload the panel'
            PartialUser = 'partial:{0}'
            T1Success = 'admin-created:{0}'
        }
        $script:padInput = 20
        Mock Write-Host { }
        Mock Escribir-Centrado { }
        Mock Start-Process { throw 'Process execution forbidden' }
        Mock net { throw 'Native fallback forbidden' }
        Mock Get-AtlasCurrentUserSid { $script:Current.SID }
        Mock Get-LocalUser {
            if ($SID) { return $script:Users | Where-Object { [string]$_.SID -eq [string]$SID } }
            if ($Name) { return $script:Users | Where-Object Name -eq $Name }
            return $script:Users
        }
        Mock Get-LocalGroupMember {
            $members = if ([string]$SID -eq 'S-1-5-32-544') { $script:Admins } else { $script:StandardMembers }
            foreach ($memberSid in $members) { [pscustomobject]@{ Name = "TEST\$memberSid"; SID = $memberSid; ObjectClass = 'User' } }
        }
        Mock Read-Host {
            if ($script:Answers.Count -eq 0) { throw 'Unexpected prompt' }
            return $script:Answers.Dequeue()
        }
        Mock New-LocalUser { $script:Users += $script:Created; return $script:Created }
        Mock Add-LocalGroupMember {
            if ([string]$SID -eq 'S-1-5-32-544') { $script:Admins += [string]$Member }
            else { $script:StandardMembers += [string]$Member }
        }
        Mock Remove-LocalGroupMember { $script:Admins = @($script:Admins | Where-Object { $_ -ne [string]$Member }) }
        Mock Remove-LocalUser { $script:Users = @($script:Users | Where-Object { [string]$_.SID -ne [string]$SID }) }
        Mock Disable-LocalUser { ($script:Users | Where-Object { [string]$_.SID -eq [string]$SID }).Enabled = $false }
        Mock Enable-LocalUser { ($script:Users | Where-Object { [string]$_.SID -eq [string]$SID }).Enabled = $true }
        Mock Set-LocalUser { }
    }

    Context 'Retention guard' {
        It 'does not count a disabled backup administrator' {
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Current.SID } | Should -Throw '*enabled local administrator*'
        }
        It 'permits a change when another local administrator is enabled' {
            $script:Backup.Enabled = $true
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Current.SID } | Should -Not -Throw
        }
        It 'does not count a domain principal with the same name as a local account' {
            $script:Backup.Enabled = $true
            $script:Admins = @($script:Current.SID, 'S-1-5-21-9-8-7-1002')
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Current.SID } | Should -Throw
        }
        It 'blocks a change if group membership cannot be verified' {
            Mock Get-LocalGroupMember { throw 'Access denied' }
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Current.SID } | Should -Throw '*Access denied*'
        }
        It 'allows removal of a standard account and a disabled admin' {
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Standard.SID } | Should -Not -Throw
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Backup.SID } | Should -Not -Throw
        }
        It 'rejects a stale or unknown selected SID' {
            { Assert-AtlasLocalAdminRetention -TargetSid 'S-1-5-21-1-2-3-1999' } | Should -Throw
        }
        It 'rejects an unknown enabled state instead of treating it as disabled' {
            $script:Current.Enabled = $null
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Current.SID } | Should -Throw '*enabled state*'
        }
        It 'does not count an expired recovery account even if enabled' {
            $script:Backup.Enabled=$true
            $script:Backup | Add-Member -NotePropertyName AccountExpires -NotePropertyValue (Get-Date).AddDays(-1)
            { Assert-AtlasLocalAdminRetention -TargetSid $script:Current.SID } | Should -Throw
        }
    }

    Context 'Account creation' {
        It 'blocks an administrator with an empty password' {
            @('NewUser', 'Test', [securestring]::new(), 'Y') | ForEach-Object { $script:Answers.Enqueue($_) }
            Crear-NuevoUsuario
            Should -Invoke Read-Host -Times 4 -Exactly
            Should -Invoke New-LocalUser -Times 0 -Exactly
        }
        It 'preserves explicit standard-account creation without a password' {
            @('NewUser', 'Test', [securestring]::new(), 'N') | ForEach-Object { $script:Answers.Enqueue($_) }
            Crear-NuevoUsuario
            Should -Invoke New-LocalUser -Times 1 -Exactly -ParameterFilter { $NoPassword }
            Should -Invoke Add-LocalGroupMember -Times 1 -Exactly -ParameterFilter { [string]$SID -eq 'S-1-5-32-545' -and [string]$Member -eq $script:Created.SID }
        }
        It 'creates an administrator with a password and binds the group by SID' {
            @('NewUser', 'Test', $script:FixturePassword, 'S') | ForEach-Object { $script:Answers.Enqueue($_) }
            Crear-NuevoUsuario
            Should -Invoke New-LocalUser -Times 1 -Exactly -ParameterFilter { $Password.Length -gt 0 -and $ErrorAction -eq 'Stop' }
            Should -Invoke Add-LocalGroupMember -Times 1 -Exactly -ParameterFilter { [string]$SID -eq 'S-1-5-32-544' -and [string]$Member -eq $script:Created.SID }
        }
        It 'cancels before any mutation when the name is zero' {
            $script:Answers.Enqueue('0')
            Crear-NuevoUsuario
            Should -Invoke New-LocalUser -Times 0 -Exactly
        }
        It 'rejects an ambiguous role answer' {
            @('NewUser', 'Test', $script:FixturePassword, 'maybe') | ForEach-Object { $script:Answers.Enqueue($_) }
            Crear-NuevoUsuario
            Should -Invoke New-LocalUser -Times 0 -Exactly
        }
        It 'stops before group assignment when creation fails non-terminatingly' {
            @('NewUser', 'Test', $script:FixturePassword, 'Y') | ForEach-Object { $script:Answers.Enqueue($_) }
            Mock New-LocalUser { Write-Error 'Creation denied' }
            Crear-NuevoUsuario
            Should -Invoke Add-LocalGroupMember -Times 0 -Exactly
            Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { "$Object" -match 'created:' }
        }
        It 'reports incomplete setup when group assignment fails after creation' {
            @('NewUser', 'Test', $script:FixturePassword, 'Y') | ForEach-Object { $script:Answers.Enqueue($_) }
            Mock Add-LocalGroupMember { throw 'Group denied' }
            Crear-NuevoUsuario
            Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { "$Object" -match 'created:' }
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { "$Object" -match 'partial:' }
        }
        It 'does not announce success when group assignment returns without the membership' {
            @('NewUser', 'Test', $script:FixturePassword, 'Y') | ForEach-Object { $script:Answers.Enqueue($_) }
            Mock Add-LocalGroupMember { }
            Crear-NuevoUsuario
            Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { "$Object" -match 'created:' }
        }
        It 'verifies administrator membership in the hardening tool as well' {
            @('NewUser', $script:FixturePassword) | ForEach-Object { $script:Answers.Enqueue($_) }
            & $script:CreateAdminAction
            Should -Invoke Add-LocalGroupMember -Times 1 -Exactly -ParameterFilter { [string]$Member -eq $script:Created.SID }
            Should -Invoke Escribir-Centrado -Times 1 -Exactly -ParameterFilter { $Text -eq 'admin-created:NewUser' }
        }
        It 'does not announce administrator creation if membership is unverified' {
            @('NewUser', $script:FixturePassword) | ForEach-Object { $script:Answers.Enqueue($_) }
            Mock Add-LocalGroupMember { }
            & $script:CreateAdminAction
            Should -Invoke Escribir-Centrado -Times 0 -Exactly -ParameterFilter { $Text -like 'admin-created:*' }
        }
    }

    Context 'Demotion' {
        It 'blocks demotion when the backup admin is disabled' {
            & $script:DemoteAction
            Should -Invoke Get-LocalGroupMember -Times 1 -Exactly
            Should -Invoke Remove-LocalGroupMember -Times 0 -Exactly
            Should -Invoke Add-LocalGroupMember -Times 0 -Exactly
        }
        It 'demotes the actual token identity with an enabled backup admin' {
            $script:Backup.Enabled = $true
            @('YES', 'N') | ForEach-Object { $script:Answers.Enqueue($_) }
            & $script:DemoteAction
            Should -Invoke Remove-LocalGroupMember -Times 1 -Exactly -ParameterFilter { [string]$Member -eq $script:Current.SID -and $ErrorAction -eq 'Stop' }
        }
        It 'preserves membership on cancellation' {
            $script:Backup.Enabled = $true
            $script:Answers.Enqueue('N')
            & $script:DemoteAction
            Should -Invoke Remove-LocalGroupMember -Times 0 -Exactly
        }
        It 'rechecks the recovery account after confirmation' {
            $script:Backup.Enabled = $true
            Mock Read-Host { $script:Backup.Enabled = $false; 'YES' }
            & $script:DemoteAction
            Should -Invoke Remove-LocalGroupMember -Times 0 -Exactly
            Should -Invoke Add-LocalGroupMember -Times 0 -Exactly
        }
        It 'does not demote if adding the standard membership fails' {
            $script:Backup.Enabled = $true
            $script:Answers.Enqueue('YES')
            Mock Add-LocalGroupMember { Write-Error 'Group denied' }
            & $script:DemoteAction
            Should -Invoke Remove-LocalGroupMember -Times 0 -Exactly
        }
    }

    Context 'Deletion' {
        It 'blocks deletion of the last enabled local admin even when its name differs from the environment' {
            Mock Get-AtlasCurrentUserSid { $script:Standard.SID }
            @('1', 'DELETE') | ForEach-Object { $script:Answers.Enqueue($_) }
            Quitar-UsuarioLocal
            Should -Invoke Remove-LocalUser -Times 0 -Exactly
            Should -Invoke net -Times 0 -Exactly
        }
        It 'blocks deleting the current token account by SID' {
            $script:Answers.Enqueue('1')
            Quitar-UsuarioLocal
            Should -Invoke Remove-LocalUser -Times 0 -Exactly
        }
        It 'deletes the selected standard account by SID after confirmation' {
            @('3', 'BORRAR') | ForEach-Object { $script:Answers.Enqueue($_) }
            Quitar-UsuarioLocal
            Should -Invoke Remove-LocalUser -Times 1 -Exactly -ParameterFilter { [string]$SID -eq $script:Standard.SID -and $ErrorAction -eq 'Stop' }
        }
        It 'does not fall back to net.exe when removal fails' {
            @('3', 'DELETE') | ForEach-Object { $script:Answers.Enqueue($_) }
            Mock Remove-LocalUser { throw 'Removal denied' }
            Quitar-UsuarioLocal
            Should -Invoke net -Times 0 -Exactly
            Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { "$Object" -match 'removed:' }
        }
        It 'preserves a selected account when deletion is cancelled' {
            @('3', 'N') | ForEach-Object { $script:Answers.Enqueue($_) }
            Quitar-UsuarioLocal
            Should -Invoke Remove-LocalUser -Times 0 -Exactly
        }
        It 'blocks deletion of a renamed built-in account by its SID' {
            $script:Backup.SID = 'S-1-5-21-1-2-3-500'
            $script:Answers.Enqueue('2')
            Quitar-UsuarioLocal
            Should -Invoke Remove-LocalUser -Times 0 -Exactly
            Should -Invoke Read-Host -Times 1 -Exactly
        }
    }

    Context 'Password and enabled state' {
        It 'leaves a password unchanged when the reset input is empty' {
            @('3', [securestring]::new()) | ForEach-Object { $script:Answers.Enqueue($_) }
            Cambiar-PasswordUsuario
            Should -Invoke Set-LocalUser -Times 0 -Exactly
            Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { "$Object" -match 'error:' }
        }
        It 'resets a password by SID after explicit confirmation' {
            @('3', $script:FixturePassword, 'RESET') | ForEach-Object { $script:Answers.Enqueue($_) }
            Cambiar-PasswordUsuario
            Should -Invoke Set-LocalUser -Times 1 -Exactly -ParameterFilter { [string]$SID -eq $script:Standard.SID -and $Password.Length -gt 0 -and $ErrorAction -eq 'Stop' }
        }
        It 'keeps the existing password when modifying a display name with blank password input' {
            @('New display', [securestring]::new()) | ForEach-Object { $script:Answers.Enqueue($_) }
            Modificar-UsuarioActual
            Should -Invoke Set-LocalUser -Times 1 -Exactly -ParameterFilter { [string]$SID -eq $script:Current.SID -and $FullName -eq 'New display' -and -not $Password }
        }
        It 'blocks disabling the only enabled local administrator' {
            Mock Get-AtlasCurrentUserSid { $script:Standard.SID }
            $script:Answers.Enqueue('1')
            & $script:ToggleAction
            Should -Invoke Disable-LocalUser -Times 0 -Exactly
        }
        It 'cancels a password reset without modifying the account' {
            @('3', $script:FixturePassword, 'N') | ForEach-Object { $script:Answers.Enqueue($_) }
            Cambiar-PasswordUsuario
            Should -Invoke Set-LocalUser -Times 0 -Exactly
        }
        It 'does not modify a similarly named local user for an unknown token SID' {
            Mock Get-AtlasCurrentUserSid { 'S-1-5-21-9-8-7-1001' }
            Modificar-UsuarioActual
            Should -Invoke Set-LocalUser -Times 0 -Exactly
            Should -Invoke Read-Host -Times 0 -Exactly
        }
        It 'disables a standard account by its selected SID' {
            $script:Answers.Enqueue('2')
            & $script:ToggleAction
            Should -Invoke Disable-LocalUser -Times 1 -Exactly -ParameterFilter { [string]$SID -eq $script:Standard.SID -and $ErrorAction -eq 'Stop' }
        }
        It 'enables a disabled account without removing another admin' {
            $script:Answers.Enqueue('1')
            & $script:ToggleAction
            Should -Invoke Enable-LocalUser -Times 1 -Exactly -ParameterFilter { [string]$SID -eq $script:Backup.SID -and $ErrorAction -eq 'Stop' }
            Should -Invoke Get-LocalGroupMember -Times 0 -Exactly
        }
    }
}
