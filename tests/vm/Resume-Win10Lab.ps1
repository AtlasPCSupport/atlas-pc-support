#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$LabRoot,[Parameter(Mandatory)][guid]$VMId,
    [Parameter(Mandatory)][string]$TestModuleRoot,[ValidateRange(1,120)][int]$InstallTimeoutMinutes=45)
$ErrorActionPreference='Stop'
if(-not ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Use normal Windows UAC elevation to resume the owned lab.'}
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
. (Join-Path $repo 'src/bootstrap/Runtime.ps1')
. (Join-Path $repo 'src/lib/Release.ps1')
. (Join-Path $PSScriptRoot 'LabHelpers.ps1')
$labFull=[IO.Path]::GetFullPath($LabRoot)
if((Split-Path $labFull -Leaf) -notlike 'Atlas-QA-Win10-*'){throw 'Not a dedicated lab root.'}
$state=Get-Content (Join-Path $labFull 'status.json') -Raw -Encoding UTF8|ConvertFrom-Json
$rows=@($state.Profiles|Where-Object VMId -eq ([string]$VMId))
if($rows.Count -ne 1){throw 'Resume requires one explicitly owned lab VM ID.'}
if($state.Profiles.Count -gt 1 -and $state.Stage -ne 'Finished'){throw 'Finish the matrix controller before retrying one of its VMs.'}
$entry=[ordered]@{};foreach($property in $rows[0].PSObject.Properties){$entry[$property.Name]=$property.Value}
$history=Join-Path $labFull ('status-before-resume-'+[guid]::NewGuid().ToString('N')+'.json')
Assert-AtlasLabLocation $labFull $history
Copy-Item -LiteralPath (Join-Path $labFull 'status.json') -Destination $history -ErrorAction Stop
$entry.Remove('Error');$entry.Remove('Result');$entry.Remove('GuestStage');$entry.Remove('ResultDirectory')
$state.Profiles=@(foreach($row in $state.Profiles){if([string]$row.VMId -eq [string]$VMId){$entry}else{$row}})
$state.PSObject.Properties.Remove('FinishedUtc')
$vm=Get-VM -Id $VMId -ErrorAction Stop
if($vm.Name -cne $entry.VMName -or $vm.Name -notlike 'ATLAS-QA-W10-*'){throw 'Lab VM identity mismatch.'}
Assert-AtlasLabLocation -Root $labFull -Path $vm.Path
$disks=@(Get-VMHardDiskDrive -VM $vm)
if($disks.Count -ne 1){throw 'Unexpected lab disk count.'};Assert-AtlasLabLocation -Root $labFull -Path $disks[0].Path
if(@(Get-VM|Where-Object {$_.Name -like 'ATLAS-QA-W10-*' -and $_.Id -ne $VMId -and $_.State -eq 'Running'}).Count){throw 'Another Atlas lab VM is running; preserve sequential execution.'}
$publication=Get-AtlasPublishedRelease
if($publication.commit -cne $state.ReleaseCommit -or $publication.manifestSha256 -cne $state.ManifestSha256){throw 'Publication changed since the lab began.'}
Test-AtlasRelease -Directory $repo -ExpectedManifestSha256 $publication.manifestSha256|Out-Null
$modules=@{}
foreach($spec in @(@{Name='Pester';Version='5.8.0'},@{Name='PSScriptAnalyzer';Version='1.25.0'})){
    $path=Join-Path $TestModuleRoot ("$($spec.Name)\$($spec.Version)\$($spec.Name).psd1")
    $module=Test-ModuleManifest $path
    if($module.Version -ne [version]$spec.Version){throw 'Pinned test module mismatch.'};$modules[$spec.Name]=$module.ModuleBase
}
$private=Join-Path (Join-Path $labFull 'private') $vm.Name
Assert-AtlasLabLocation -Root $labFull -Path $private
$credential=Import-Clixml -LiteralPath (Join-Path $private 'credential.clixml')
$session=$null
function Save-ResumedLab { $state|ConvertTo-Json -Depth 12|Set-Content (Join-Path $labFull 'status.json') -Encoding UTF8 }
try{
    if((Get-MpComputerStatus).RealTimeProtectionEnabled -ne $true){throw 'Host Defender is not active.'}
    if($vm.State -eq 'Off'){
        if((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory*1KB -lt 3GB){throw 'Less than 3 GB host RAM free.'}
        Set-VMMemory -VM $vm -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes 2GB -MaximumBytes 3GB
        Start-VM -VM $vm|Out-Null
    }
    elseif($vm.State -eq 'Saved'){Start-VM -VM $vm|Out-Null}
    $entry.Status='Installing';$state.Stage='Resume installation';Save-ResumedLab
    $session=Wait-AtlasLabDesktop -VMId $VMId -Credential $credential -ExpectedComputer $entry.ComputerName -TimeoutMinutes $InstallTimeoutMinutes -OnProgress {param($facts)$entry.Readiness=$facts;Save-ResumedLab}
    Invoke-AtlasLabGuestQA -Session $session -VM $vm -Credential $credential -Entry $entry -Modules $modules -Repo $repo -LabFull $labFull -Publication $publication -SaveState {$state.Stage="$($entry.Status) $($entry.Profile)";Save-ResumedLab}
}catch{$entry.Status='Failed';$entry.Error=$_.Exception.Message}
finally{
    if($session){Remove-PSSession $session -ErrorAction SilentlyContinue}
    try{Stop-VM -VM $vm -Confirm:$false -ErrorAction Stop|Out-Null}catch{Stop-VM -VM $vm -TurnOff -Force -Confirm:$false -ErrorAction Stop|Out-Null}
    Set-VM -VM $vm -AutomaticStartAction Nothing -AutomaticStopAction ShutDown
    $state.Stage='Finished';$state|Add-Member FinishedUtc ([datetime]::UtcNow.ToString('o')) -Force;Save-ResumedLab
}
if($entry.Status -ne 'Passed'){exit 1}
