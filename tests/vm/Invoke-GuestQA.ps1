#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root='C:\AtlasQA'
$results=Join-Path $root 'results'
New-Item -ItemType Directory -Path $results -Force|Out-Null
function Write-LabStage {param($Stage);[ordered]@{Stage=$Stage;Utc=[datetime]::UtcNow.ToString('o')}|ConvertTo-Json|Set-Content (Join-Path $results 'status.json') -Encoding UTF8}
function Invoke-AtlasGuestLocalChecks {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo,[Parameter(Mandatory)][string]$Results,
        [string]$TempRoot=([IO.Path]::GetTempPath()))
    $previous=@(Get-ChildItem -LiteralPath $TempRoot -Directory -Filter 'atlas-local-checks-*'|ForEach-Object FullName)
    $failure=$null
    try{& (Join-Path $Repo 'tests/Invoke-LocalChecks.ps1') *>&1|Out-File (Join-Path $Results 'local-checks.log') -Encoding UTF8}catch{$failure=$_}
    $report=Get-ChildItem -LiteralPath $TempRoot -Directory -Filter 'atlas-local-checks-*'|
        Where-Object FullName -NotIn $previous|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
    if(-not $report){if($failure){throw $failure};throw 'A fresh local test report was not produced.'}
    # Pester failures still leave useful XML and a summary. Copy before propagating
    # the error, and never replace a missing fresh result with an earlier report.
    Copy-Item -LiteralPath $report.FullName -Destination (Join-Path $Results 'local-checks') -Recurse -Force -ErrorAction Stop
    $summaryPath=Join-Path $report.FullName 'summary.json'
    $checks=if(Test-Path -LiteralPath $summaryPath){Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8|ConvertFrom-Json}else{$null}
    [pscustomobject]@{Summary=$checks;Failure=$failure}
}
$summary=[ordered]@{SchemaVersion=1;Windows10SuiteExecuted=$false;FullWindows10Qualification=$false;Passed=$false;RepairsExecuted=$false}
try{
    $summary.GuestRunnerSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $marker=Get-Content (Join-Path $root 'marker.json') -Raw -Encoding UTF8|ConvertFrom-Json
    $computer=Get-CimInstance Win32_ComputerSystem
    if($computer.Model -notmatch 'Virtual Machine' -or $env:COMPUTERNAME -cne $marker.ComputerName){throw 'Guest-only guard failed.'}
    $os=Get-CimInstance Win32_OperatingSystem
    $version=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $edition=$version.EditionID
    $summary.Profile=$marker.Profile;$summary.Build=[int]$os.BuildNumber;$summary.Edition=$edition
    $summary.Runtime=$PSVersionTable.PSVersion.ToString();$summary.Caption=$os.Caption
    $summary.UBR=$version.UBR;$summary.LabSource=$marker.LabSource
    if($summary.Build -ne $marker.ExpectedBuild -or $edition -cne $marker.ExpectedEdition){throw 'Installed edition/build does not match the target profile.'}
    $env:PSModulePath=(Join-Path $root 'modules')+';'+$env:PSModulePath
    Write-LabStage 'Waiting for completed OOBE and interactive desktop'
    $desktopDeadline=[datetime]::UtcNow.AddMinutes(15);$desktopReady=$false
    while([datetime]::UtcNow -lt $desktopDeadline -and -not $desktopReady){
        $setup=Get-ItemProperty 'HKLM:\SYSTEM\Setup' -ErrorAction Stop
        $sessionId=(Get-Process -Id $PID).SessionId
        $desktopReady=$setup.SystemSetupInProgress -eq 0 -and $setup.OOBEInProgress -eq 0 -and @((Get-Process explorer -ErrorAction SilentlyContinue)|Where-Object SessionId -eq $sessionId).Count -gt 0
        if(-not $desktopReady){Start-Sleep -Seconds 10}
    }
    if(-not $desktopReady){throw 'OOBE/interactive desktop did not become ready; no UI qualification claimed.'}
    Write-LabStage 'Defender'
    $defender=Get-MpComputerStatus -ErrorAction Stop
    $summary.Defender=[ordered]@{AntivirusEnabled=$defender.AntivirusEnabled;RealTimeProtectionEnabled=$defender.RealTimeProtectionEnabled;AMServiceEnabled=$defender.AMServiceEnabled;SignatureUpdated=$defender.AntivirusSignatureLastUpdated.ToUniversalTime().ToString('o')}
    if(-not $defender.AntivirusEnabled -or -not $defender.RealTimeProtectionEnabled -or -not $defender.AMServiceEnabled){throw 'Defender is not active in this guest.'}
    $summary.ActivationStatuses=@(Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'"|Where-Object PartialProductKey|Select-Object -ExpandProperty LicenseStatus)
    $repo=Join-Path $root 'repo'
    $summary.TestBundleFiles=[ordered]@{}
    foreach($relative in @('tests/Invoke-LocalChecks.ps1','tests/VmLab.Tests.ps1','tests/vm/LabHelpers.ps1','tests/vm/Invoke-Win10Lab.ps1','tests/vm/Resume-Win10Lab.ps1','tests/vm/Invoke-GuestQA.ps1')){
        $summary.TestBundleFiles[$relative]=(Get-FileHash -LiteralPath (Join-Path $repo $relative) -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Write-LabStage 'Local checks and WPF'
    $localRun=Invoke-AtlasGuestLocalChecks -Repo $repo -Results $results
    $checks=$localRun.Summary
    $summary.LocalChecks=$checks
    $summary.Windows10SuiteExecuted=$null -ne $checks
    if($localRun.Failure){throw $localRun.Failure}
    if(-not $checks){throw 'Fresh local test summary was not produced.'}
    if($checks.Failed -or $checks.AnalyzerErrors -or -not $checks.DistributionArtifactsUnchanged){throw 'Guest local checks failed.'}
    Write-LabStage 'Actual platform capabilities'
    . (Join-Path $repo 'src/lib/Capabilities.ps1')
    $cap=Get-AtlasPlatformCapabilities -Refresh
    $summary.Capabilities=[ordered]@{Baseline=$cap.Baseline;Build=$cap.Build;Edition=$cap.EditionId;NativeDoh=$cap.NativeDoh;BitLocker=$cap.BitLocker;LTSC=$cap.LTSC}
    if(-not $cap.Baseline -or $cap.NativeDoh){throw 'Windows 10 capability gate failed.'}
    $summary.Store=Get-AtlasStoreState|Select-Object State,LTSC,WingetAvailable
    Write-LabStage 'Published release and online/offline entry'
    . (Join-Path $repo 'src/lib/Release.ps1')
    $published=Get-AtlasPublishedRelease
    if($published.commit -cne $marker.ReleaseCommit -or $published.manifestSha256 -cne $marker.ManifestSha256){throw 'Publication moved during qualification.'}
    $bootstrap=Join-Path $root 'published-get.ps1'
    Invoke-WebRequest -Uri 'https://toolspanel.atlaspcsupport.com/' -UseBasicParsing -OutFile $bootstrap -TimeoutSec 60 -ErrorAction Stop
    $cache=Join-Path $root 'verified release with spaces'
    $release=& $bootstrap -InstallRoot $cache -NoLaunch
    Initialize-AtlasOfflineEntry -Root $cache -Release $release
    $offline=& (Join-Path $cache 'get.ps1') -OfflineRoot $cache -NoLaunch
    if($release.Commit -cne $offline.Commit -or $release.ManifestSha256 -cne $offline.ManifestSha256){throw 'Online/offline mismatch.'}
    $summary.OnlineOffline=[ordered]@{Commit=$release.Commit;ManifestSha256=$release.ManifestSha256;Passed=$true;ToolCount=@($release.Manifest.files.PSObject.Properties|Where-Object Name -like 'src/tools/*').Count}
    Write-LabStage 'Interactive main window'
    $engine=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $gui=Start-Process -FilePath $engine -ArgumentList @('-NoProfile','-STA','-ExecutionPolicy','RemoteSigned','-File',('"'+(Join-Path $release.Directory 'launcher.ps1')+'"'),'-AtlasReleaseCommit',$release.Commit,'-AtlasManifestSha256',$release.ManifestSha256) -PassThru -WindowStyle Normal
    try{
        $windowCreated=$false;$deadline=[datetime]::UtcNow.AddSeconds(90)
        while(-not $windowCreated -and [datetime]::UtcNow -lt $deadline -and -not $gui.HasExited){
            Start-Sleep -Seconds 2
            $gui.Refresh()
            $windowCreated=$gui.MainWindowHandle -ne [IntPtr]::Zero -and $gui.MainWindowTitle -like '*Atlas*'
        }
        if(-not $windowCreated){throw 'Atlas did not create its main window.'}
        $summary.MainWindow=[ordered]@{Created=$true;Title=$gui.MainWindowTitle;ToolsExecuted=$false;VisualVerification='External VM console observation required';ClosedNormally=$false}
        Write-LabStage 'Waiting for visual verification and normal panel close'
        if(-not $gui.WaitForExit(600000)){throw 'Panel visual verification/normal close timed out.'}
        if($gui.ExitCode -ne 0){throw 'Atlas main window exited with an error.'}
        $summary.MainWindow.ClosedNormally=$true
    }finally{if(-not $gui.HasExited){$gui|Stop-Process -Force};$gui.Dispose()}
    $summary.Passed=$true
    Write-LabStage 'Completed'
}catch{
    $summary.Error=$_.Exception.Message
    $_|Out-String|Out-File (Join-Path $results 'failure.log') -Encoding UTF8
    Write-LabStage 'Failed'
}finally{
    $summary.FinishedUtc=[datetime]::UtcNow.ToString('o')
    $summary|ConvertTo-Json -Depth 12|Set-Content (Join-Path $results 'summary.json') -Encoding UTF8
}
if(-not $summary.Passed){exit 1}
