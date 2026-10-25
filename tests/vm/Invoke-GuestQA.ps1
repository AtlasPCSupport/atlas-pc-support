#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root='C:\AtlasQA'
$results=Join-Path $root 'results'
New-Item -ItemType Directory -Path $results -Force|Out-Null
function Write-LabStage {param($Stage);[ordered]@{Stage=$Stage;Utc=[datetime]::UtcNow.ToString('o')}|ConvertTo-Json|Set-Content (Join-Path $results 'status.json') -Encoding UTF8}
$summary=[ordered]@{SchemaVersion=1;Windows10SuiteExecuted=$false;FullWindows10Qualification=$false;Passed=$false;RepairsExecuted=$false}
try{
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
    & (Join-Path $repo 'tests/Invoke-LocalChecks.ps1') *>&1|Out-File (Join-Path $results 'local-checks.log') -Encoding UTF8
    $report=Get-ChildItem $env:TEMP -Directory -Filter 'atlas-local-checks-*'|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
    if(-not $report){throw 'Local test report was not produced.'}
    $checks=Get-Content (Join-Path $report.FullName 'summary.json') -Raw -Encoding UTF8|ConvertFrom-Json
    Copy-Item -LiteralPath $report.FullName -Destination (Join-Path $results 'local-checks') -Recurse -Force
    $summary.LocalChecks=$checks
    if($checks.Failed -or $checks.AnalyzerErrors -or -not $checks.DistributionArtifactsUnchanged){throw 'Guest local checks failed.'}
    $summary.Windows10SuiteExecuted=$true
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
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    $engine=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $gui=Start-Process -FilePath $engine -ArgumentList @('-NoProfile','-STA','-ExecutionPolicy','RemoteSigned','-File',('"'+(Join-Path $release.Directory 'launcher.ps1')+'"'),'-AtlasReleaseCommit',$release.Commit,'-AtlasManifestSha256',$release.ManifestSha256) -PassThru -WindowStyle Normal
    try{
        $window=$null;$deadline=[datetime]::UtcNow.AddSeconds(90)
        while(-not $window -and [datetime]::UtcNow -lt $deadline -and -not $gui.HasExited){
            Start-Sleep -Seconds 2
            $condition=[Windows.Automation.PropertyCondition]::new([Windows.Automation.AutomationElement]::ProcessIdProperty,$gui.Id)
            $windows=[Windows.Automation.AutomationElement]::RootElement.FindAll([Windows.Automation.TreeScope]::Children,$condition)
            foreach($candidate in $windows){if($candidate.Current.Name -like '*Atlas*' -and -not $candidate.Current.IsOffscreen){$window=$candidate;break}}
        }
        if(-not $window){throw 'No visible Atlas main window in the interactive guest desktop.'}
        Start-Sleep -Seconds 5
        $screen=[Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap=[Drawing.Bitmap]::new($screen.Width,$screen.Height)
        $graphics=[Drawing.Graphics]::FromImage($bitmap)
        try{$graphics.CopyFromScreen($screen.X,$screen.Y,0,0,$bitmap.Size);$bitmap.Save((Join-Path $results 'panel.png'),[Drawing.Imaging.ImageFormat]::Png)}finally{$graphics.Dispose();$bitmap.Dispose()}
        $summary.MainWindow=[ordered]@{Visible=$true;Title=$window.Current.Name;ToolsExecuted=$false;Screenshot='panel.png'}
        $pattern=$window.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)
        $pattern.Close()
        if(-not $gui.WaitForExit(15000)){throw 'Atlas window did not close normally.'}
        if($gui.ExitCode -ne 0){throw 'Atlas main window exited with an error.'}
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
