#Requires -Version 5.1
<#
.SYNOPSIS
    Opt-in physical USB checks, confined to a new GUID directory and local Temp.
.DESCRIPTION
    Requires an explicitly identified USB disk/volume. Does not format, repartition,
    eject, fill the drive, alter ACLs or touch existing payloads. Retains evidence.
    Runs native copies and offline Atlas validation only; never starts real tools.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[D-Zd-z]$')][string]$DriveLetter,
    [Parameter(Mandatory)][ValidateRange(0,1024)][int]$ExpectedDiskNumber,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedIdentitySha256
)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'src/bootstrap/Runtime.ps1')
. (Join-Path $repoRoot 'src/lib/Release.ps1')
. (Join-Path $repoRoot 'src/lib/Reports.ps1')
. (Join-Path $repoRoot 'src/lib/Operations.ps1')
$DriveLetter=$DriveLetter.ToUpperInvariant()
$driveRoot=$DriveLetter+':\'

function Assert-UsbIdentity {
    $volume=Get-Volume -DriveLetter $DriveLetter -ErrorAction Stop
    $disk=Get-Partition -DriveLetter $DriveLetter -ErrorAction Stop | Get-Disk -ErrorAction Stop
    if (@($disk).Count -ne 1 -or $disk.Number -ne $ExpectedDiskNumber -or $disk.BusType.ToString() -ne 'USB' -or
        $disk.IsBoot -or $disk.IsSystem -or $disk.IsOffline -or $disk.IsReadOnly -or
        $volume.FileSystem -notin @('NTFS','exFAT','FAT32') -or $volume.SizeRemaining -lt 1GB) {
        throw 'Expected writable non-system USB volume with at least 1 GiB free is required.'
    }
    $identity=Get-AtlasTextHash (([string]$disk.UniqueId)+'|'+([string]$volume.UniqueId))
    if ($identity -cne $ExpectedIdentitySha256) { throw 'USB identity changed. No write is allowed.' }
    Assert-AtlasPlainDirectory $driveRoot
    return $volume
}

function Get-ExistingRootFingerprint {
    # Metadata only, never enumerate personal subdirectories or publish their names.
    $rows=@(Get-ChildItem -LiteralPath $driveRoot -Force -ErrorAction Stop |
        Where-Object Name -ne $runName | Sort-Object Name | ForEach-Object {
            [ordered]@{Name=$_.Name;Directory=$_.PSIsContainer;Length=$(if(-not $_.PSIsContainer){$_.Length}else{$null});Modified=$_.LastWriteTimeUtc.Ticks}
        })
    Get-AtlasTextHash ($rows | ConvertTo-Json -Depth 4 -Compress)
}

function Assert-OwnedUsbPath([string]$Path) {
    [void](Assert-UsbIdentity)
    $full=[IO.Path]::GetFullPath($Path)
    $prefix=[IO.Path]::GetFullPath($usbRoot).TrimEnd('\')+'\'
    if (-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'USB write escaped the owned test directory.' }
    Assert-AtlasPlainDirectory $usbRoot
}

function Add-Check([string]$Name,[bool]$Passed,[object]$Details) {
    $checks.Add([pscustomobject]@{Name=$Name;Passed=$Passed;Details=$Details})
    if (-not $Passed) { throw "USB check failed: $Name" }
    Write-Host "[OK] $Name"
}

function Invoke-UsbCopy([string]$Source,[string]$Destination,[switch]$ExpectFailure) {
    # Both source and destination must be owned fixtures; USB direction may vary.
    foreach($path in @($Source,$Destination)) {
        $full=[IO.Path]::GetFullPath($path)
        if ($full.StartsWith($driveRoot,[StringComparison]::OrdinalIgnoreCase)) { Assert-OwnedUsbPath $path }
        elseif (-not $full.StartsWith($localRoot+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Copy escaped the local fixture directory.' }
    }
    Assert-AtlasCopyDestination -Source $Source -Destination $Destination
    $native=Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32/robocopy.exe') -ArgumentList @($Source,$Destination,'/E','/J','/MT:2','/R:0','/W:0','/XJ','/FFT','/COPY:DAT','/DCOPY:DAT','/NP') -TimeoutSeconds 60 -SuccessCodes @(0,1,2,3)
    $script:copyAttempt++
    [IO.File]::WriteAllText((Join-Path $localRoot ("copy-$script:copyAttempt.log")),($native.Stdout+"`n"+$native.Stderr))
    if (-not $ExpectFailure -and $native.State -ne 'Correct') { throw "Native USB copy: $($native.State), exit $($native.ExitCode)" }
    return $native
}

function Test-OfflineEntry([string]$Root,[string]$Engine,[string]$Name) {
    Assert-OwnedUsbPath (Join-Path $Root 'get.ps1')
    $probe=Invoke-AtlasNativeProcess -FilePath $Engine -ArgumentList @('-NoProfile','-STA','-ExecutionPolicy','RemoteSigned','-File',(Join-Path $Root 'get.ps1'),'-OfflineRoot',$Root,'-NoLaunch') -TimeoutSeconds 60
    [IO.File]::WriteAllText((Join-Path $localRoot ($Name+'.log')),($probe.Stdout+"`n"+$probe.Stderr))
    Add-Check $Name ($probe.State -eq 'Correct' -and $probe.Stdout -match '27 tools verified') @{State=$probe.State;ExitCode=$probe.ExitCode}
}

$volume=Assert-UsbIdentity
$runName='ATLAS_USB_QA_'+[guid]::NewGuid().ToString('N')
$usbRoot=Join-Path $driveRoot $runName
$localRoot=Join-Path ([IO.Path]::GetTempPath()) $runName
$checks=[Collections.Generic.List[object]]::new()
$script:copyAttempt=0
$before=Get-ExistingRootFingerprint
$result=[ordered]@{SchemaVersion=1;StartedUtc=[datetime]::UtcNow.ToString('o');Runtime=$PSVersionTable.PSVersion.ToString();HostBuild=[Environment]::OSVersion.Version.ToString();FileSystem=$volume.FileSystem;UsbIdentitySha256=$ExpectedIdentitySha256;Passed=$false;Windows10Qualified=$false;PowerLossTested=$false;HotRemovalTested=$false;AclRecoveryTested=$false;FreeSpaceFailureTested=$false;NoFormatOrPartitionChanges=$true;UsbDirectory=$usbRoot;LocalEvidenceDirectory=$localRoot;Checks=@()}
New-Item -ItemType Directory -Path $localRoot -ErrorAction Stop | Out-Null
try {
    [void](Assert-UsbIdentity)
    if (Test-Path -LiteralPath $usbRoot) { throw 'Test directory already exists.' }
    New-Item -ItemType Directory -Path $usbRoot -ErrorAction Stop | Out-Null
    [IO.File]::WriteAllText((Join-Path $usbRoot 'README.txt'),'Atlas QA only. Existing USB files were not selected. Retain this directory until evidence is reviewed. Offline Atlas is under atlas-offline. No apps or drivers are installed by this test.')
    $source=Join-Path $localRoot 'source with spaces & apostrophe''s'
    $destination=Join-Path $usbRoot 'copy'
    New-Item -ItemType Directory -Path $source,(Join-Path $source 'nested'),(Join-Path $source 'empty'),$destination | Out-Null
    [IO.File]::WriteAllText((Join-Path $source 'plain.txt'),'fixture original')
    [IO.File]::WriteAllText((Join-Path $source ('accent-'+[char]0x00f1+'.txt')),'unicode filename fixture')
    [IO.File]::WriteAllBytes((Join-Path $source 'zero.bin'),[byte[]]@())
    [IO.File]::WriteAllText((Join-Path $source 'hidden.txt'),'hidden fixture')
    [IO.File]::SetAttributes((Join-Path $source 'hidden.txt'),[IO.FileAttributes]::Hidden)
    foreach($number in 1..20) { [IO.File]::WriteAllText((Join-Path $source ("nested/file-$number.txt")),('fixture '+$number)) }
    $bytes=New-Object byte[] (8MB)
    $rng=[Security.Cryptography.RandomNumberGenerator]::Create()
    try {$rng.GetBytes($bytes)} finally {$rng.Dispose()}
    [IO.File]::WriteAllBytes((Join-Path $source 'data.bin'),$bytes);$bytes=$null
    [IO.File]::WriteAllText((Join-Path $destination 'keep.txt'),'unrelated fixture retained')
    [void](Invoke-UsbCopy $source $destination)
    $verify=Test-AtlasCopySample -Source $source -Destination $destination -SampleSize 1000
    Add-Check 'USB full fixture hashes' ($verify.OK -and $verify.Checked -eq 25) $verify
    Add-Check 'Empty directory and hidden file preserved' ((Test-Path -LiteralPath (Join-Path $destination 'empty') -PathType Container) -and ((Get-Item -LiteralPath (Join-Path $destination 'hidden.txt') -Force).Attributes -band [IO.FileAttributes]::Hidden)) $null
    Add-Check 'Existing destination fixture retained' ([IO.File]::ReadAllText((Join-Path $destination 'keep.txt')) -ceq 'unrelated fixture retained') $null
    $repeat=Invoke-UsbCopy $source $destination
    Add-Check 'Unchanged copy skips fixture data' ($repeat.ExitCode -eq 2) @{ExitCode=$repeat.ExitCode;ExtraFixtureExpected=$true}
    [IO.File]::WriteAllText((Join-Path $source 'plain.txt'),'fixture changed with a different size')
    [IO.File]::WriteAllText((Join-Path $source 'new.txt'),'new fixture')
    [void](Invoke-UsbCopy $source $destination)
    $verify=Test-AtlasCopySample -Source $source -Destination $destination -SampleSize 1000
    Add-Check 'Incremental changes verified' ($verify.OK -and $verify.Checked -eq 26) $verify
    $restored=Join-Path $localRoot 'restored'
    [void](Invoke-UsbCopy $destination $restored)
    $verify=Test-AtlasCopySample -Source $destination -Destination $restored -SampleSize 1000
    Add-Check 'USB round trip full fixture hashes' ($verify.OK -and $verify.Checked -eq 27) $verify
    Assert-OwnedUsbPath (Join-Path $destination 'plain.txt')
    [IO.File]::WriteAllText((Join-Path $destination 'plain.txt'),'corrupted fixture')
    $verify=Test-AtlasCopySample -Source $source -Destination $destination -SampleSize 1000
    Add-Check 'Corruption is detected' (-not $verify.OK -and $verify.Failed -eq 1) @{State=$verify.State;Failed=$verify.Failed}
    [void](Invoke-UsbCopy $source $destination)
    Add-Check 'Copy repairs changed fixture' (Test-AtlasCopySample -Source $source -Destination $destination -SampleSize 1000).OK $null
    $lockedSource=Join-Path $localRoot 'locked';New-Item -ItemType Directory -Path $lockedSource | Out-Null
    $locked=Join-Path $lockedSource 'locked.txt';[IO.File]::WriteAllText($locked,'locked fixture')
    $handle=[IO.FileStream]::new($locked,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try {
        $failure=Invoke-UsbCopy $lockedSource (Join-Path $usbRoot 'locked-copy') -ExpectFailure
        Add-Check 'Locked source fails explicitly' ($failure.State -eq 'Failed' -and $failure.ExitCode -ge 8) @{State=$failure.State;ExitCode=$failure.ExitCode}
    } finally {$handle.Dispose()}
    $descriptor=Get-AtlasPublishedRelease
    $digest=(Get-FileHash -LiteralPath (Join-Path $repoRoot 'release-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    if($descriptor.manifestSha256 -cne $digest){throw 'Checkout differs from the approved publication; do not prepare it.'}
    $offline=Join-Path $usbRoot 'atlas-offline';Assert-OwnedUsbPath $offline
    $release=Install-AtlasRelease -Root $offline -Descriptor $descriptor -SourceDirectory $repoRoot -PrepareOfflineEntry
    Add-Check 'Approved bundle on physical USB' (@($release.Manifest.files.PSObject.Properties).Count -eq 33) @{Commit=$release.Commit;Manifest=$digest;Version=$release.Manifest.version;Members=33}
    $engine51=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    Test-OfflineEntry $offline $engine51 'Offline entry PS5.1 NoLaunch'
    $core=Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if($core){Test-OfflineEntry $offline $core.Source 'Offline entry PS7 NoLaunch'}
    else {$checks.Add([pscustomobject]@{Name='Offline entry PS7 NoLaunch';Passed=$null;Details='PowerShell 7 not installed'})}
    # Corrupt only a second owned fixture bundle, never the retained usable entry.
    $corruptRoot=Join-Path $usbRoot 'corrupt-fixture';Assert-OwnedUsbPath $corruptRoot
    $bad=Install-AtlasRelease -Root $corruptRoot -Descriptor $descriptor -SourceDirectory $repoRoot -PrepareOfflineEntry
    [IO.File]::AppendAllText((Join-Path $bad.Directory 'launcher.ps1'),"`n# deliberately altered QA fixture`n")
    $probe=Invoke-AtlasNativeProcess -FilePath $engine51 -ArgumentList @('-NoProfile','-ExecutionPolicy','RemoteSigned','-File',(Join-Path $corruptRoot 'get.ps1'),'-OfflineRoot',$corruptRoot,'-NoLaunch') -TimeoutSeconds 60
    [IO.File]::WriteAllText((Join-Path $localRoot 'corruption-rejection.log'),($probe.Stdout+"`n"+$probe.Stderr))
    Add-Check 'Offline entry rejects altered USB bundle' ($probe.State -eq 'Failed' -and $probe.ExitCode -ne 0 -and ($probe.Stdout+$probe.Stderr) -match 'digest mismatch') @{State=$probe.State;ExitCode=$probe.ExitCode}
    $again=Get-AtlasPublishedRelease
    Add-Check 'Publication unchanged during USB checks' ($again.commit -ceq $descriptor.commit -and $again.manifestSha256 -ceq $descriptor.manifestSha256) @{Commit=$again.commit}
    $defender=Get-MpComputerStatus
    Add-Check 'Defender remains active' ($defender.AntivirusEnabled -and $defender.RealTimeProtectionEnabled -and $defender.AMServiceEnabled -and $defender.IsTamperProtected) $null
    [void](Assert-UsbIdentity)
    Add-Check 'Existing USB root metadata unchanged' ((Get-ExistingRootFingerprint) -ceq $before) @{Scope='Top-level pre-existing entries only; no claim about all payload bytes'}
    $result.Passed=$true
} catch {
    $result['Error']=$_.Exception.Message
    throw
} finally {
    $result['CompletedUtc']=[datetime]::UtcNow.ToString('o')
    $result.Checks=$checks.ToArray()
    $json=$result | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText((Join-Path $localRoot 'summary.json'),$json,[Text.UTF8Encoding]::new($false))
    Write-Host "Evidence: $localRoot"
}
$result | ConvertTo-Json -Depth 10
