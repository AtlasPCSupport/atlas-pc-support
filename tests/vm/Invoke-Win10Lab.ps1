#Requires -Version 5.1
<#
 Creates ONLY fresh ATLAS-QA VMs, using the operator's existing ISO files.
 One VM runs at a time. No physical disk, host account/group, Defender setting,
 network switch or production deployment is changed. Leave VMs and snapshots
 available for review; there is deliberately no automatic recursive cleanup.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Windows10Iso,[Parameter(Mandatory)][string]$LtscIso,
    [Parameter(Mandatory)][string]$LabRoot,[ValidateSet('Home','Pro','LTSC')][string[]]$Profiles=@('Home','Pro','LTSC'),
    [string]$TestModuleRoot=(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'),
    [ValidateRange(1,120)][int]$InstallTimeoutMinutes=75,[ValidateRange(1,60)][int]$TestTimeoutMinutes=25)
$ErrorActionPreference='Stop'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
if(-not ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Hyper-V lab requires Windows UAC elevation. Do not bypass UAC or change group permissions.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repo 'src/bootstrap/Runtime.ps1')
. (Join-Path $repo 'src/lib/Release.ps1')
. (Join-Path $PSScriptRoot 'LabHelpers.ps1')
$publication=Get-AtlasPublishedRelease
Test-AtlasRelease -Directory $repo -ExpectedManifestSha256 $publication.manifestSha256|Out-Null
if(Test-Path -LiteralPath $LabRoot){throw 'Use a new dedicated lab directory; existing VMs/disks are never overwritten.'}
$labFull=[IO.Path]::GetFullPath($LabRoot)
if([IO.Path]::GetPathRoot($labFull) -eq $labFull -or (Split-Path $labFull -Leaf) -notmatch '^Atlas-QA-Win10-'){throw 'Dedicated Atlas-QA-Win10-* directory required.'}
foreach($iso in @($Windows10Iso,$LtscIso)){if(-not(Test-Path -LiteralPath $iso -PathType Leaf)){throw "ISO missing: $iso"}}
$hostStatus=Get-MpComputerStatus
if(-not $hostStatus.RealTimeProtectionEnabled){throw 'Host Defender is not active.'}
$drive=Get-PSDrive -Name ([IO.Path]::GetPathRoot($labFull).Substring(0,1))
if($drive.Free -lt 85GB){throw 'At least 85 GB of free space required on the lab volume.'}
Get-VM -ErrorAction Stop|Out-Null
$switch=Get-VMSwitch|Where-Object {$_.Id -eq [guid]'c08cb7b8-9b3c-408e-8e30-5e16a3aeb444' -or $_.Name -eq 'Default Switch'}|Select-Object -First 1
if(-not $switch){throw 'No existing Hyper-V Default Switch; create/review an isolated NAT network manually. No bridge is created automatically.'}
New-Item -ItemType Directory -Path $labFull|Out-Null
$private=Join-Path $labFull 'private';New-Item -ItemType Directory -Path $private|Out-Null
$acl=Get-Acl $private;$acl.SetAccessRuleProtection($true,$false)
foreach($sidText in @('S-1-5-32-544','S-1-5-18')){$sid=[Security.Principal.SecurityIdentifier]::new($sidText);$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'))}
Set-Acl -LiteralPath $private -AclObject $acl -ErrorAction Stop
$state=[ordered]@{SchemaVersion=1;StartedUtc=[datetime]::UtcNow.ToString('o');SourceCommit=(& git -C $repo rev-parse HEAD|Out-String).Trim();ReleaseCommit=$publication.commit;ManifestSha256=$publication.manifestSha256;HostDefenderChanged=$false;WholeIsoAuthenticityIndependentlyVerified=$false;Profiles=@();Stage='Preflight'}
function Save-LabState { $state|ConvertTo-Json -Depth 12|Set-Content (Join-Path $labFull 'status.json') -Encoding UTF8 }
Save-LabState
$modules=@{}
foreach($spec in @(@{Name='Pester';Version='5.8.0'},@{Name='PSScriptAnalyzer';Version='1.25.0'})){
    $module=Get-Module -ListAvailable $spec.Name|Where-Object Version -eq $spec.Version|Select-Object -First 1
    if(-not $module){
        $modulePath=Join-Path $TestModuleRoot ("$($spec.Name)\$($spec.Version)")
        $moduleFile=Join-Path $modulePath ($spec.Name+'.psd1')
        if(Test-Path -LiteralPath $moduleFile){$module=Test-ModuleManifest -Path $moduleFile -ErrorAction Stop}
    }
    if(-not $module -or $module.Version -ne [version]$spec.Version){throw "Missing pinned host test module $($spec.Name) $($spec.Version)."};$modules[$spec.Name]=$module.ModuleBase
}
$isoMetadata=@{}
foreach($profile in $Profiles){
    $configuration=Get-AtlasLabProfile -Profile $profile
    $vm=$null;$session=$null;$mountedByLab=$false;$iso=if($profile -eq 'LTSC'){$LtscIso}else{$Windows10Iso}
    $entry=[ordered]@{Profile=$profile;Status='Preparing';ExpectedBuild=$configuration.Build;ExpectedEdition=$configuration.Edition}
    $state.Profiles+=,$entry
    try{
        if((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory*1KB -lt 3GB){throw 'Less than 3 GB host RAM free; close an application before starting a lab VM.'}
        $state.Stage="Prepare $profile";Save-LabState
        $attached=Get-DiskImage -ImagePath $iso -ErrorAction Stop
        if(-not $attached.Attached){$attached=Mount-DiskImage -ImagePath $iso -PassThru -ErrorAction Stop;$mountedByLab=$true}
        $volume=$attached|Get-Volume;$mediaRoot=([string]$volume.DriveLetter)+':\'
        $signature=Get-AuthenticodeSignature -FilePath (Join-Path $mediaRoot 'setup.exe') -ErrorAction Stop
        if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)'){throw 'ISO Windows Setup Microsoft signature is invalid.'}
        if(-not $isoMetadata.ContainsKey($iso)){$isoMetadata[$iso]=[ordered]@{FileName=[IO.Path]::GetFileName($iso);Sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash.ToLowerInvariant();SetupMicrosoftSignature='Valid'}}
        $entry.Media=$isoMetadata[$iso]
        $images=@(Get-WindowsImage -ImagePath (Join-Path $mediaRoot 'sources/install.wim') -ErrorAction Stop)
        $image=@($images|Where-Object ImageName -eq $configuration.ImageName)
        if($image.Count -ne 1){throw 'The ISO does not contain one unambiguous target edition.'}
        $entry.ImageName=$image[0].ImageName
        if($mountedByLab){Dismount-DiskImage -ImagePath $iso -ErrorAction Stop|Out-Null;$mountedByLab=$false}
        $mediaCopy=Join-Path $labFull $(if($profile -eq 'LTSC'){'media-ltsc.iso'}else{'media-22h2.iso'})
        if(-not (Test-Path -LiteralPath $mediaCopy)){
            Copy-Item -LiteralPath $iso -Destination $mediaCopy -ErrorAction Stop
            if((Get-FileHash -LiteralPath $mediaCopy -Algorithm SHA256).Hash.ToLowerInvariant() -cne $entry.Media.Sha256){throw 'Lab ISO copy hash mismatch.'}
        }
        $suffix=[guid]::NewGuid().ToString('N').Substring(0,8)
        $name="ATLAS-QA-W10-$profile-$suffix";$computerName="ATLAS-$($profile.ToUpperInvariant())"
        $entry.VMName=$name;$entry.ComputerName=$computerName
        $vmRoot=Join-Path $labFull $name;Assert-AtlasLabLocation $labFull $vmRoot
        New-Item -ItemType Directory -Path $vmRoot|Out-Null
        $answerFolder=Join-Path $private $name;New-Item -ItemType Directory -Path $answerFolder|Out-Null
        $password=[guid]::NewGuid().ToString('N')+'aA1!'
        # Random disposable VM credential, not a hardcoded or host password.
        $securePassword=[Security.SecureString]::new()
        foreach($character in $password.ToCharArray()){$securePassword.AppendChar($character)}
        $securePassword.MakeReadOnly()
        $credential=[pscredential]::new('AtlasLab',$securePassword)
        $credential|Export-Clixml -LiteralPath (Join-Path $answerFolder 'credential.clixml')
        $answer=Join-Path $answerFolder 'answer';New-Item -ItemType Directory -Path $answer|Out-Null
        [IO.File]::WriteAllText((Join-Path $answer 'Autounattend.xml'),(New-AtlasLabAnswer -Profile $profile -ImageName $entry.ImageName -Password $password -ComputerName $computerName),[Text.UTF8Encoding]::new($false))
        $password=$null
        $answerIso=Join-Path $answerFolder 'answer.iso';New-AtlasLabIso -Directory $answer -Destination $answerIso
        $vhd=Join-Path $vmRoot 'system.vhdx';Assert-AtlasLabLocation $labFull $vhd
        if(Test-Path -LiteralPath $vhd){throw 'Lab disk already exists.'}
        $vm=New-VM -Name $name -Generation 2 -MemoryStartupBytes 2GB -NewVHDPath $vhd -NewVHDSizeBytes 64GB -Path $vmRoot -SwitchName $switch.Name -ErrorAction Stop
        $entry.VMId=[string]$vm.Id
        Set-VM -VM $vm -ProcessorCount 2 -AutomaticCheckpointsEnabled $false -CheckpointType Standard -AutomaticStartAction Nothing -AutomaticStopAction ShutDown
        Set-VMMemory -VM $vm -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes 2GB -MaximumBytes 3GB
        Set-VMFirmware -VM $vm -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
        Set-VMKeyProtector -VM $vm -NewLocalKeyProtector;Enable-VMTPM -VM $vm
        $vmSid=([Security.Principal.NTAccount]::new("NT VIRTUAL MACHINE\$($vm.Id)")).Translate([Security.Principal.SecurityIdentifier])
        foreach($file in @($answerIso,$mediaCopy)){
            $isoAcl=Get-Acl $file;$isoAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($vmSid,'ReadAndExecute','Allow'));Set-Acl -LiteralPath $file -AclObject $isoAcl
        }
        $dvd=Add-VMDvdDrive -VM $vm -Path $mediaCopy -Passthru
        Add-VMDvdDrive -VM $vm -Path $answerIso|Out-Null
        Set-VMFirmware -VM $vm -FirstBootDevice $dvd
        $disk=@(Get-VMHardDiskDrive -VM $vm)
        if($disk.Count -ne 1 -or [IO.Path]::GetFullPath($disk[0].Path) -cne [IO.Path]::GetFullPath($vhd)){throw 'VM does not have exactly the expected new virtual disk.'}
        $entry.Status='Installing';$state.Stage="Install $profile";Save-LabState
        Start-VM -VM $vm|Out-Null
        # Press space only in this VM's initial firmware/DVD boot interval.
        for($i=0;$i -lt 4;$i++){
            Start-Sleep -Seconds 2
            $system=Get-CimInstance -Namespace root/virtualization/v2 -ClassName Msvm_ComputerSystem -Filter "Name='$($vm.Id)'"
            $keyboard=$system|Get-CimAssociatedInstance -ResultClassName Msvm_Keyboard
            if($keyboard){$key=Invoke-CimMethod -InputObject $keyboard -MethodName TypeKey -Arguments @{KeyCode=[uint32]32};if($key.ReturnValue -notin @(0,4096)){throw 'Initial guest keyboard request failed.'}}
        }
        $session=Wait-AtlasLabDesktop -VMId $vm.Id -Credential $credential -ExpectedComputer $entry.ComputerName -TimeoutMinutes $InstallTimeoutMinutes -OnProgress {param($facts)$entry.Readiness=$facts;Save-LabState}
        Invoke-AtlasLabGuestQA -Session $session -VM $vm -Credential $credential -Entry $entry -Modules $modules -Repo $repo -LabFull $labFull -Publication $publication -TestTimeoutMinutes $TestTimeoutMinutes -SaveState { $state.Stage="$($entry.Status) $($entry.Profile)"; Save-LabState }

    }catch{$entry.Status='Failed';$entry.Error=$_.Exception.Message}
    finally{
        if($session){Remove-PSSession $session -ErrorAction SilentlyContinue}
        if($mountedByLab){Dismount-DiskImage -ImagePath $iso -ErrorAction SilentlyContinue|Out-Null}
        if($vm){
            # Only the exact VM object created above is stopped. Never stop by a broad name.
            try{Stop-VM -VM $vm -Confirm:$false -ErrorAction Stop|Out-Null}catch{
                $entry.ShutdownError=$_.Exception.Message
                Stop-VM -VM $vm -TurnOff -Force -Confirm:$false -ErrorAction Stop|Out-Null
            }
        }
        Save-LabState
    }
}
$state.Stage='Finished';$state.FinishedUtc=[datetime]::UtcNow.ToString('o');Save-LabState
if(@($state.Profiles|Where-Object Status -ne Passed).Count){exit 1}
