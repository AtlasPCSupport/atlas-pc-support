#Requires -Version 5.1
#Requires -Modules Pester

Describe 'A03 recovery before BitLocker activation' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Get-BitLockerVolume { [CmdletBinding()] param($MountPoint) throw 'Real BitLocker lookup blocked' }
        function Get-Tpm { [CmdletBinding()] param() throw 'Real TPM lookup blocked' }
        function Add-BitLockerKeyProtector { [CmdletBinding()] param($MountPoint,[switch]$RecoveryPasswordProtector) throw 'Real protector change blocked' }
        function Enable-BitLocker { [CmdletBinding()] param($MountPoint,$EncryptionMethod,[switch]$TpmProtector,[switch]$PasswordProtector,$Password) throw 'Real encryption blocked' }
        function Get-Partition { [CmdletBinding()] param($DriveLetter) throw 'Real partition lookup blocked' }
        foreach ($name in @('Save-AtlasRecoveryBackup','Enable-AtlasBitLockerSafely')) {
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GestorBitLocker.ps1' $name)
        }
    }
    BeforeEach {
        $script:Recovery = [pscustomobject]@{ KeyProtectorType='RecoveryPassword'; KeyProtectorId='{fixture-id}'; RecoveryPassword=('123456-'*7)+'123456' }
        $script:Volume = [pscustomobject]@{
            VolumeType='OperatingSystem'; VolumeStatus='FullyDecrypted'; LockStatus='Unlocked'; ProtectionStatus='Off'; KeyProtector=@()
        }
        $script:BackupSaved=$false
        $script:Secret=[securestring]::new()
        foreach ($character in 'fixture only'.ToCharArray()) { $script:Secret.AppendChar($character) }
        Mock Get-BitLockerVolume { $script:Volume }
        Mock Get-Tpm { [pscustomobject]@{ TpmPresent=$true; TpmReady=$true } }
        Mock Add-BitLockerKeyProtector { $script:Volume.KeyProtector=@($script:Recovery) }
        Mock Save-AtlasRecoveryBackup { $script:BackupSaved=$true; 'X:\fixture\recovery.txt' }
        Mock Enable-BitLocker {
            if (-not $script:BackupSaved) { throw 'Encryption called before verified backup' }
            $type=if ($TpmProtector) {'Tpm'} else {'Password'}
            $script:Volume.KeyProtector += [pscustomobject]@{KeyProtectorType=$type}
            $script:Volume.VolumeStatus='EncryptionInProgress'
        }
    }
    It 'backs up recovery before enabling the OS volume with a TPM protector' {
        $result=Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture'
        $result.RecoveryBackup | Should -Be 'X:\fixture\recovery.txt'
        $result.RebootMayBeRequired | Should -BeTrue
        Should -Invoke Save-AtlasRecoveryBackup -Times 1 -Exactly -ParameterFilter { $Protector.KeyProtectorId -eq '{fixture-id}' }
        Should -Invoke Enable-BitLocker -Times 1 -Exactly -ParameterFilter { $TpmProtector -and -not $PasswordProtector -and $ErrorAction -eq 'Stop' }
    }
    It 'does not enable encryption if backup fails' {
        Mock Save-AtlasRecoveryBackup { throw 'Disk full or backup failed' }
        { Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture' } | Should -Throw '*backup failed*'
        Should -Invoke Enable-BitLocker -Times 0 -Exactly
    }
    It 'does not enable encryption if a recovery protector cannot be read back' {
        Mock Add-BitLockerKeyProtector { }
        { Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture' } | Should -Throw '*recovery protector*'
        Should -Invoke Enable-BitLocker -Times 0 -Exactly
    }
    It 'does not alter an existing encrypted or locked volume' -ForEach @(
        @{Status='FullyEncrypted';Lock='Unlocked'}, @{Status='FullyDecrypted';Lock='Locked'}, @{Status='DecryptionInProgress';Lock='Unlocked'}
    ) {
        $script:Volume.VolumeStatus=$Status; $script:Volume.LockStatus=$Lock
        { Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture' } | Should -Throw '*preserved*'
        Should -Invoke Add-BitLockerKeyProtector -Times 0 -Exactly
        Should -Invoke Enable-BitLocker -Times 0 -Exactly
    }
    It 'requires a ready TPM for this OS activation flow' {
        Mock Get-Tpm { [pscustomobject]@{TpmPresent=$true;TpmReady=$false} }
        { Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture' } | Should -Throw '*ready TPM*'
        Should -Invoke Add-BitLockerKeyProtector -Times 0 -Exactly
        Should -Invoke Enable-BitLocker -Times 0 -Exactly
    }
    It 'requires a nonempty data-volume unlock password before changing protectors' {
        $script:Volume.VolumeType='FixedData'
        { Enable-AtlasBitLockerSafely -MountPoint 'D:' -RecoveryDirectory 'X:\fixture' } | Should -Throw '*password*'
        Should -Invoke Add-BitLockerKeyProtector -Times 0 -Exactly
    }
    It 'uses a password instead of TPM for a data volume even if a TPM exists' {
        $script:Volume.VolumeType='FixedData'
        Enable-AtlasBitLockerSafely -MountPoint 'D:' -RecoveryDirectory 'X:\fixture' -Password $script:Secret | Out-Null
        Should -Invoke Get-Tpm -Times 0 -Exactly
        Should -Invoke Enable-BitLocker -Times 1 -Exactly -ParameterFilter { $PasswordProtector -and -not $TpmProtector -and $Password.Length -gt 0 }
    }
    It 'reuses an existing recovery protector without rotating it' {
        $script:Volume.KeyProtector=@($script:Recovery)
        Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture' | Out-Null
        Should -Invoke Add-BitLockerKeyProtector -Times 0 -Exactly
    }
    It 'does not report success when the main protector is absent afterwards' {
        Mock Enable-BitLocker { }
        { Enable-AtlasBitLockerSafely -MountPoint 'C:' -RecoveryDirectory 'X:\fixture' } | Should -Throw '*required primary*'
    }
}

Describe 'A03 recovery file verification' -Tag 'Windows' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Get-Partition { [CmdletBinding()] param($DriveLetter) throw 'Real partition lookup blocked' }
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GestorBitLocker.ps1' 'Save-AtlasRecoveryBackup')
    }
    BeforeEach {
        $script:Recovery = [pscustomobject]@{ KeyProtectorId='{fixture-id}'; RecoveryPassword=('123456-'*7)+'123456' }
        $script:Folder=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:Folder | Out-Null
        Mock Get-Partition { [pscustomobject]@{DiskNumber=$(if ($DriveLetter -eq 'Z') {0} else {1})} }
    }
    It 'writes and reads a new file in a separate disk folder without printing the key' -Skip:($env:OS -ne 'Windows_NT') {
        $file=Save-AtlasRecoveryBackup -MountPoint 'Z:' -Directory $script:Folder -Protector $script:Recovery
        (Get-Content -LiteralPath $file -Raw) | Should -Match ([regex]::Escape($script:Recovery.RecoveryPassword))
        (Split-Path -Parent $file) | Should -Be (Get-Item -LiteralPath $script:Folder).FullName
    }
    It 'rejects another partition on the same physical disk before writing' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Get-Partition { [pscustomobject]@{DiskNumber=0} }
        { Save-AtlasRecoveryBackup -MountPoint 'Z:' -Directory $script:Folder -Protector $script:Recovery } | Should -Throw '*different physical disk*'
        @(Get-ChildItem -LiteralPath $script:Folder).Count | Should -Be 0
    }
    It 'refuses to save an unreadable recovery password' {
        $script:Recovery.RecoveryPassword=''
        { Save-AtlasRecoveryBackup -MountPoint 'Z:' -Directory $script:Folder -Protector $script:Recovery } | Should -Throw '*readable recovery*'
    }
}
