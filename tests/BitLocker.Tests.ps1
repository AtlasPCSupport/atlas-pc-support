#Requires -Version 5.1
#Requires -Modules Pester

Describe 'Explicit recovery export and secret boundaries' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        foreach($name in @('Get-AtlasRecoveryBackupFolder','Write-AtlasRecoveryText','Get-AtlasRecoveryRecords','Export-AtlasRecoveryKeys','Invoke-AtlasRecoveryExportMenu','New-AtlasRecoveryCard','Backup-KeyToAD')){
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GestorBitLocker.ps1' $name)
        }
        function Get-BitLockerVolume {[CmdletBinding()]param($MountPoint)throw 'Real secrets blocked'}
        function Get-Partition {[CmdletBinding()]param($DriveLetter)throw 'Real disk lookup blocked'}
        function Write-Log {param($Message,$Level)}
        function Backup-BitLockerKeyProtector {[CmdletBinding()]param($MountPoint,$KeyProtectorId)throw 'Real escrow blocked'}
        function BackupToAAD-BitLockerKeyProtector {[CmdletBinding()]param($MountPoint,$KeyProtectorId)throw 'Real escrow blocked'}
        function Invoke-AtlasNativeProcess {[CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real native query blocked'}
        function Set-Clipboard {[CmdletBinding()]param([Parameter(ValueFromPipeline)]$Value)throw 'Real clipboard blocked'}
        $ast=Get-TestAst $script:RepoRoot 'src/tools/Invoke-GestorBitLocker.ps1'
        $switch=$ast.Find({param($n)$n -is [Management.Automation.Language.SwitchStatementAst] -and $n.Condition.Extent.Text -eq '$Action'},$true)
        $clause=@($switch.Clauses|Where-Object {$_.Item1.Value -eq 'Extract'})[0]
        $script:ExtractAction=[scriptblock]::Create(($clause.Item2.Statements.Extent.Text -join "`n"))
        $script:RecoveryOriginalSystemRoot=$env:SystemRoot
    }
    BeforeEach {
        $script:FakeKey=('123456-'*7)+'123456'
        if(-not $env:SystemRoot){$env:SystemRoot=$TestDrive}
        $script:Record=[pscustomobject]@{MountPoint='Z:';KeyId='{fixture-id}';RecoveryPassword=$script:FakeKey}
        Mock Write-Host {};Mock Write-Log {}
        Mock Get-BitLockerVolume {[pscustomobject]@{MountPoint='Z:';VolumeStatus='FullyEncrypted';KeyProtector=@([pscustomobject]@{KeyProtectorType='RecoveryPassword';KeyProtectorId='{fixture-id}';RecoveryPassword=$script:FakeKey})}}
    }
    AfterAll {$env:SystemRoot=$script:RecoveryOriginalSystemRoot}
    It 'writes and reads a new recovery file and refuses to overwrite it' {
        $file=Join-Path $TestDrive 'new.txt'
        Write-AtlasRecoveryText -Path $file -Content 'synthetic recovery fixture'|Should -Be $file
        [IO.File]::ReadAllText($file)|Should -Be 'synthetic recovery fixture'
        {Write-AtlasRecoveryText -Path $file -Content 'replacement'}|Should -Throw
        [IO.File]::ReadAllText($file)|Should -Be 'synthetic recovery fixture'
    }
    It 'prevalidates every selected volume before writing any secret' {
        Mock Get-AtlasRecoveryBackupFolder {if($MountPoint -eq 'Y:'){throw 'same physical disk'};$TestDrive}
        Mock Write-AtlasRecoveryText {throw 'Must not write'}
        $second=[pscustomobject]@{MountPoint='Y:';KeyId='{second}';RecoveryPassword=$script:FakeKey}
        {Export-AtlasRecoveryKeys -Records @($script:Record,$second) -OutputPath 'C:\fixture\keys.txt'}|Should -Throw '*same physical disk*'
        Should -Invoke Write-AtlasRecoveryText -Times 0 -Exactly
    }
    It 'rejects incomplete secrets before writing and exports only to the selected new file' {
        Mock Get-AtlasRecoveryBackupFolder {$TestDrive}
        Mock Write-AtlasRecoveryText {$Path}
        $script:Record.RecoveryPassword=''
        {Export-AtlasRecoveryKeys -Records @($script:Record) -OutputPath 'C:\fixture\keys.txt'}|Should -Throw '*readable*'
        Should -Invoke Write-AtlasRecoveryText -Times 0 -Exactly
        $script:Record.RecoveryPassword=$script:FakeKey
        Export-AtlasRecoveryKeys -Records @($script:Record) -OutputPath 'C:\fixture\keys.txt'|Should -Not -BeNullOrEmpty
        Should -Invoke Write-AtlasRecoveryText -Times 1 -Exactly -ParameterFilter {$Content -match [regex]::Escape($script:FakeKey)}
    }
    It 'refuses invalid and empty export requests' {
        foreach($path in @('relative.txt','C:\fixture\keys.png')){
            {Export-AtlasRecoveryKeys -Records @($script:Record) -OutputPath $path}|Should -Throw '*explicit*'
        }
        {Export-AtlasRecoveryKeys -Records @() -OutputPath 'C:\fixture\keys.txt'}|Should -Throw '*No readable*'
    }
    It 'requires CLI output before reading keys and keeps successful CLI output hidden by default' {
        Mock Get-AtlasRecoveryRecords {@($script:Record)}
        Mock Export-AtlasRecoveryKeys {'fixture-saved.txt'}
        $Output='';$MountPoint='Z:';$Reveal=$false
        {& $script:ExtractAction}|Should -Throw '*requires an explicit*'
        Should -Invoke Get-AtlasRecoveryRecords -Times 0 -Exactly
        $Output='C:\fixture\keys.txt'
        & $script:ExtractAction
        Should -Invoke Export-AtlasRecoveryKeys -Times 1 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter {($Object -join ' ') -match [regex]::Escape($script:FakeKey)}
        $Reveal=$true;& $script:ExtractAction
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {($Object -join ' ') -match [regex]::Escape($script:FakeKey)}
    }
    It 'keeps menu optional actions off unless their exact tokens were entered' {
        Mock Get-AtlasRecoveryRecords {@($script:Record)}
        Mock Export-AtlasRecoveryKeys {'C:\fixture\keys.txt'}
        Mock Read-Host {if($Prompt -like 'Volume to export*'){'Z:'}elseif($Prompt -like 'Full NEW*'){'C:\fixture\keys.txt'}else{'y'}}
        Mock New-AtlasRecoveryCard {throw 'No card without CARD'}
        Mock Backup-KeyToAD {throw 'No escrow without BACKUP'}
        Mock Set-Clipboard {throw 'No clipboard without COPY'}
        Invoke-AtlasRecoveryExportMenu
        Should -Invoke New-AtlasRecoveryCard -Times 0 -Exactly
        Should -Invoke Backup-KeyToAD -Times 0 -Exactly
        Should -Invoke Set-Clipboard -Times 0 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter {($Object -join ' ') -match [regex]::Escape($script:FakeKey)}
    }
    It 'does not continue menu actions after an export failure' {
        Mock Read-Host {if($Prompt -like 'Volume to export*'){'Z:'}else{'C:\fixture\keys.txt'}}
        Mock Export-AtlasRecoveryKeys {throw 'disk full'}
        {Invoke-AtlasRecoveryExportMenu}|Should -Throw '*disk full*'
        Should -Invoke Read-Host -Times 2 -Exactly
    }
    It 'propagates unreadable secret inventory without a success or export' {
        Mock Get-BitLockerVolume {throw 'Access denied'}
        {Get-AtlasRecoveryRecords -MountPoint 'Z:'}|Should -Throw '*Access denied*'
    }
    It 'preserves a previous printable file and creates explicit text fallback only in the chosen folder' {
        $file=Join-Path $TestDrive 'card.png';[IO.File]::WriteAllText($file,'previous')
        {New-AtlasRecoveryCard -Data $script:FakeKey -OutputPath $file}|Should -Throw '*already exists*'
        [IO.File]::ReadAllText($file)|Should -Be previous
        $file=Join-Path $TestDrive 'new-card.png'
        Mock Add-Type {throw 'Drawing unavailable'}
        $saved=New-AtlasRecoveryCard -Data $script:FakeKey -OutputPath $file -Label 'Fixture only' -WarningAction SilentlyContinue
        $saved|Should -Be (Join-Path $TestDrive 'new-card.txt')
        [IO.File]::ReadAllText($saved)|Should -Match 'Fixture only'
        [IO.File]::ReadAllText($saved)|Should -Match '123456-123456'
    }
    It 'renders an actual printable fixture and releases its output file' -Skip:($env:OS -ne 'Windows_NT') {
        $file=Join-Path $TestDrive 'rendered-card.png'
        New-AtlasRecoveryCard -Data $script:FakeKey -OutputPath $file -Label 'SYNTHETIC TEST ONLY'|Should -Be $file
        $image=[Drawing.Image]::FromFile($file)
        try {$image.Width|Should -Be 800;$image.Height|Should -BeGreaterThan 100}finally{$image.Dispose()}
        Remove-Item -LiteralPath $file -ErrorAction Stop
    }
    It 'does not use truncated Entra join output or call a request accepted remote recovery verified' {
        Mock Backup-BitLockerKeyProtector {throw 'Not joined'}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Correct';Stdout='AzureAdJoined : YES';StdoutTruncated=$true}}
        Mock BackupToAAD-BitLockerKeyProtector {}
        Backup-KeyToAD -MountPoint 'Z:'|Should -BeFalse
        Should -Invoke BackupToAAD-BitLockerKeyProtector -Times 0 -Exactly
        Mock Backup-BitLockerKeyProtector {}
        Backup-KeyToAD -MountPoint 'Z:'|Should -BeTrue
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {($Object -join ' ') -match 'request accepted; confirm remote recovery separately'}
    }
    It 'does not report every protector accepted if only one AD request succeeded' {
        Mock Get-BitLockerVolume {[pscustomobject]@{KeyProtector=@([pscustomobject]@{KeyProtectorType='RecoveryPassword';KeyProtectorId='first'},[pscustomobject]@{KeyProtectorType='RecoveryPassword';KeyProtectorId='second'})}}
        Mock Backup-BitLockerKeyProtector {if($KeyProtectorId -eq 'second'){throw 'Denied'}}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='TimedOut';Stdout='AzureAdJoined : YES';StdoutTruncated=$false}}
        Backup-KeyToAD -MountPoint 'Z:'|Should -BeFalse
    }
}

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
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        foreach($name in @('Get-AtlasRecoveryBackupFolder','Write-AtlasRecoveryText','Save-AtlasRecoveryBackup')){
            . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-GestorBitLocker.ps1' $name)
        }
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
