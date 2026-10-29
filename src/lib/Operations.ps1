# Small shared primitives for evidence and reversible Windows operations.
function Copy-AtlasDependencyTree {
            param(
                [Parameter(Mandatory)][string]$SourceDir,
                [Parameter(Mandatory)][string]$DestinationDir,
                [string]$PackageKey
            )

            if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) { return $false }
            Assert-AtlasCopyDestination -Source $SourceDir -Destination $DestinationDir
            $sourceRoot=[IO.Path]::GetFullPath($SourceDir).TrimEnd([char[]]'\/')
            $destRoot=[IO.Path]::GetFullPath($DestinationDir)
            $sourceFiles=[Collections.Generic.List[IO.FileInfo]]::new()
            $pending=[Collections.Generic.Stack[string]]::new();$pending.Push($sourceRoot)
            # Preflight every selected path before any write. Never recurse through links.
            while($pending.Count) {
                $directory=$pending.Pop()
                Assert-AtlasPlainDirectory $directory
                foreach($item in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
                    if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'USB dependency paths cannot cross reparse points.'}
                    $relative=$item.FullName.Substring($sourceRoot.Length).TrimStart([char[]]'\/')
                    $target=Join-Path $destRoot $relative
                    if($item.PSIsContainer) {
                        Assert-AtlasCopyDestination -Source $item.FullName -Destination $target
                        $pending.Push($item.FullName)
                    } else {
                        Assert-AtlasCopyDestination -Source $item.FullName -Destination (Split-Path -Parent $target)
                        if(Test-Path -LiteralPath $target){Assert-AtlasPlainFile $target}
                        $sourceFiles.Add($item)
                    }
                }
            }
            if($sourceFiles.Count -eq 0){return $false}
            $robo=Get-Command robocopy.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1
            if(-not $robo){throw 'Robocopy is required for USB dependency copies.'}
            if(-not (Test-Path -LiteralPath $destRoot)){New-Item -ItemType Directory -Path $destRoot -ErrorAction Stop | Out-Null}
            $result=Invoke-AtlasNativeProcess -FilePath $robo.Source -ArgumentList @($sourceRoot,$destRoot,'/E','/R:1','/W:1','/NFL','/NDL','/NJH','/NJS','/NP','/XJ','/FFT','/COPY:DAT','/DCOPY:DAT') -TimeoutSeconds 86400 -SuccessCodes @(0,1,2,3)
            if($result.State -ne 'Correct'){throw "USB copy $($result.State), exit $($result.ExitCode); inspect partial destination before retrying."}
            # Delta metadata may skip damaged same-size/same-date files. Verify every resource.
            $records=[Collections.Generic.List[object]]::new()
            foreach($file in $sourceFiles) {
                $relative=$file.FullName.Substring($sourceRoot.Length).TrimStart([char[]]'\/')
                $target=Join-Path $destRoot $relative
                try {
                    Assert-AtlasPlainFile $file.FullName;Assert-AtlasPlainFile $target
                    $digest=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
                    if($digest -cne (Get-FileHash -LiteralPath $target -Algorithm SHA256 -ErrorAction Stop).Hash){throw 'Resource digest mismatch.'}
                    if($PackageKey){$records.Add(@{Path=$target;Sha256=$digest.ToLowerInvariant()})}
                } catch {throw "USB dependency verification failed: $relative. Existing files were not removed; inspect before retrying."}
            }
            if($PackageKey){$script:AtlasUsbVerifiedPackages[$PackageKey]=$true;$script:AtlasUsbVerifiedFiles[$PackageKey]=$records.ToArray()}
            return $true
        }

function Copy-AtlasUsbExecutable {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination,[Parameter(Mandatory)][string]$PackageKey)
    Assert-AtlasPlainFile $Source
    Assert-AtlasCopyDestination -Source $Source -Destination (Split-Path -Parent $Destination)
    if(Test-Path -LiteralPath $Destination){Assert-AtlasPlainFile $Destination}
    Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
    $digest=(Get-FileHash -LiteralPath $Source -Algorithm SHA256 -ErrorAction Stop).Hash
    if($digest -cne (Get-FileHash -LiteralPath $Destination -Algorithm SHA256 -ErrorAction Stop).Hash){throw 'USB executable copy hash mismatch.'}
    $script:AtlasUsbVerifiedPackages[$PackageKey]=$true
    $script:AtlasUsbVerifiedFiles[$PackageKey]=@(@{Path=$Destination;Sha256=$digest.ToLowerInvariant()})
}

function Get-AtlasPowerShellVersion {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $result=Invoke-AtlasNativeProcess -FilePath $Path -ArgumentList @('-NoLogo','-NoProfile','-Command','$PSVersionTable.PSVersion.ToString()') -TimeoutSeconds 15
    if($result.State -ne 'Correct' -or $result.StdoutTruncated){throw 'Installed PowerShell version could not be evaluated.'}
    $text=([string]$result.Stdout).Trim()
    if($text -notmatch '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$'){throw 'Unexpected PowerShell version output.'}
    return [version]($text -split '-',2)[0]
}

function Get-AtlasLocalAccountPolicy {
    [CmdletBinding()]
    param()
    if($env:OS -ne 'Windows_NT'){throw 'Local account policy requires Windows.'}
    if(-not ('Atlas.LocalPolicyReader' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace Atlas {
  public static class LocalPolicyReader {
    [DllImport("Netapi32.dll", CharSet=CharSet.Unicode)]
    static extern int NetUserModalsGet(string server, int level, out IntPtr buffer);
    [DllImport("Netapi32.dll")] static extern int NetApiBufferFree(IntPtr buffer);
    public static uint[] Read(int level, int count) {
      IntPtr p = IntPtr.Zero;
      try {
        int result = NetUserModalsGet(null, level, out p);
        if(result != 0) throw new System.ComponentModel.Win32Exception(result);
        uint[] values = new uint[count];
        for(int i=0; i<count; i++) values[i] = unchecked((uint)Marshal.ReadInt32(p, i*4));
        return values;
      } finally { if(p != IntPtr.Zero) NetApiBufferFree(p); }
    }
  }
}

'@ -ErrorAction Stop
    }
    $password=[Atlas.LocalPolicyReader]::Read(0,5)
    $lockout=[Atlas.LocalPolicyReader]::Read(3,3)
    [pscustomobject]@{MinPasswordLength=$password[0];MaxPasswordAge=$(if($password[1] -eq [uint32]::MaxValue){'UNLIMITED'}else{[int]($password[1]/86400)});MinPasswordAgeSeconds=$password[2];LockoutThreshold=$lockout[2];Source='Local SAM / NetUserModalsGet'}
}

function Set-AtlasLocalAccountPolicy {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Values,[Parameter(Mandatory)][string]$SnapshotPath)
    $ranges=@{MinPasswordLength=@(0,14);MaxPasswordAge=@(0,999);LockoutThreshold=@(0,999)}
    foreach($name in $Values.Keys) {
        $n=0
        if(-not $ranges.ContainsKey($name) -or -not [int]::TryParse([string]$Values[$name],[ref]$n) -or $n -lt $ranges[$name][0] -or $n -gt $ranges[$name][1]){throw "Invalid local policy value: $name"}
    }
    $computer=Get-CimInstance Win32_ComputerSystem -OperationTimeoutSec 10 -ErrorAction Stop
    if(-not $computer -or $computer.PartOfDomain -isnot [bool] -or $computer.PartOfDomain -or $computer.DomainRole -ge 4){throw 'Use the organization policy administrator for domain-managed computers; local policy changes blocked.'}
    $before=Get-AtlasLocalAccountPolicy
    if($Values.ContainsKey('MaxPasswordAge') -and [int]$Values.MaxPasswordAge -gt 0 -and [int]$Values.MaxPasswordAge*86400 -lt $before.MinPasswordAgeSeconds){throw 'Maximum password age is below the current minimum.'}
    $Values=$Values.Clone()
    if($Values.ContainsKey('MaxPasswordAge') -and [int]$Values.MaxPasswordAge -eq 0){$Values.MaxPasswordAge='UNLIMITED'}
    Assert-AtlasPlainDirectory (Split-Path -Parent ([IO.Path]::GetFullPath($SnapshotPath)))
    if(Test-Path -LiteralPath $SnapshotPath){throw 'Policy snapshot must be a new file.'}
    $snapshot=[ordered]@{SchemaVersion=1;ComputerName=$env:COMPUTERNAME;CreatedUtc=[datetime]::UtcNow.ToString('o');Before=$before;Requested=$Values}
    $json=$snapshot|ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($SnapshotPath,$json,[Text.UTF8Encoding]::new($false))
    if([IO.File]::ReadAllText($SnapshotPath,[Text.Encoding]::UTF8) -cne $json){throw 'Policy snapshot readback failed.'}
    $switches=@{MinPasswordLength='minpwlen';MaxPasswordAge='maxpwage';LockoutThreshold='lockoutthreshold'}
    $completed=0
    foreach($name in @('MinPasswordLength','MaxPasswordAge','LockoutThreshold')) {
        if(-not $Values.ContainsKey($name)){continue}
        try {
            $result=Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32/net.exe') -ArgumentList @('accounts',("/$($switches[$name]):$($Values[$name])")) -TimeoutSeconds 30
            if($result.State -ne 'Correct'){throw "net.exe $($result.State), exit $($result.ExitCode): $($result.Stderr) $($result.Stdout)"}
            $after=Get-AtlasLocalAccountPolicy
            if([string]$after.$name -ne [string]$Values[$name]){throw 'Policy readback differs from the requested value.'}
            $completed++
        } catch {throw "Local policy incomplete: $completed verified change(s). Recovery values: $SnapshotPath. $($_.Exception.Message)"}
    }
    [pscustomobject]@{VerifiedChanges=$completed;Before=$before;After=(Get-AtlasLocalAccountPolicy);Snapshot=$SnapshotPath}
}

function Get-AtlasUacSnapshot {
    [CmdletBinding()]
    param()
    $path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $key=Get-Item -LiteralPath $path -ErrorAction Stop
    $properties=Get-ItemProperty -LiteralPath $path -ErrorAction Stop
    $values=foreach($name in @('EnableLUA','PromptOnSecureDesktop','ConsentPromptBehaviorUser','ConsentPromptBehaviorAdmin')) {
        $p=$properties.PSObject.Properties[$name]
        if($p -and $key.GetValueKind($name).ToString() -ne 'DWord'){throw 'Unexpected UAC registry value type.'}
        [pscustomobject]@{Name=$name;Present=($null -ne $p);Value=$(if($p){[int]$p.Value}else{$null})}
    }
    [pscustomobject]@{SchemaVersion=1;ComputerName=$env:COMPUTERNAME;CreatedUtc=[datetime]::UtcNow.ToString('o');Values=@($values)}
}

function Set-AtlasUacValues {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    $limits=@{EnableLUA=1;PromptOnSecureDesktop=1;ConsentPromptBehaviorUser=3;ConsentPromptBehaviorAdmin=5}
    $seen=@{}
    if($Snapshot.SchemaVersion -ne 1 -or $Snapshot.ComputerName -cne $env:COMPUTERNAME -or @($Snapshot.Values).Count -ne 4){throw 'UAC snapshot does not match this computer.'}
    foreach($entry in $Snapshot.Values) {
        if(-not $limits.ContainsKey([string]$entry.Name) -or $seen.ContainsKey([string]$entry.Name) -or $entry.Present -isnot [bool] -or
            ($entry.Present -and (($entry.Value -isnot [int] -and $entry.Value -isnot [long]) -or $entry.Value -lt 0 -or $entry.Value -gt $limits[$entry.Name]))){throw 'Invalid UAC snapshot value.'}
        $seen[$entry.Name]=$true
    }
    $path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    foreach($entry in $Snapshot.Values) {
        if($entry.Present){New-ItemProperty -LiteralPath $path -Name $entry.Name -Value $entry.Value -PropertyType DWord -Force -ErrorAction Stop | Out-Null}
        elseif((Get-ItemProperty -LiteralPath $path -ErrorAction Stop).PSObject.Properties[$entry.Name]){Remove-ItemProperty -LiteralPath $path -Name $entry.Name -ErrorAction Stop}
    }
    $after=Get-AtlasUacSnapshot
    foreach($entry in $Snapshot.Values) {
        $actual=$after.Values | Where-Object Name -eq $entry.Name
        if($actual.Present -ne $entry.Present -or ($entry.Present -and $actual.Value -ne $entry.Value)){throw "UAC readback differs for $($entry.Name); inspect the recovery snapshot before retrying."}
    }
}

function Set-AtlasUacPreset {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SnapshotPath)
    $before=Get-AtlasUacSnapshot
    Assert-AtlasPlainDirectory (Split-Path -Parent ([IO.Path]::GetFullPath($SnapshotPath)))
    if(Test-Path -LiteralPath $SnapshotPath){throw 'UAC snapshot must be a new file.'}
    $json=$before|ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($SnapshotPath,$json,[Text.UTF8Encoding]::new($false))
    if([IO.File]::ReadAllText($SnapshotPath,[Text.Encoding]::UTF8) -cne $json){throw 'UAC snapshot readback failed.'}
    Write-Host "UAC recovery snapshot: $SnapshotPath"
    $requested=$json|ConvertFrom-Json
    foreach($entry in $requested.Values){$entry.Present=$true;$entry.Value=if($entry.Name -eq 'ConsentPromptBehaviorAdmin'){2}else{1}}
    try {Set-AtlasUacValues -Snapshot $requested}
    catch {throw "UAC preset incomplete. Recovery snapshot: $SnapshotPath. $($_.Exception.Message)"}
}

function Restore-AtlasUacSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    Assert-AtlasPlainFile $Path
    $snapshot=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)|ConvertFrom-Json -ErrorAction Stop
    Set-AtlasUacValues -Snapshot $snapshot
}
function Assert-AtlasCopyDestination {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination)
    $origin=[IO.Path]::GetFullPath($Source).TrimEnd([char[]]'\/')
    $target=[IO.Path]::GetFullPath($Destination).TrimEnd([char[]]'\/')
    if($target.Equals($origin,[StringComparison]::OrdinalIgnoreCase) -or
        $target.StartsWith($origin+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Copy destination cannot be the source or a child of the source.'}
    $item=Get-Item -LiteralPath ([IO.Path]::GetFullPath($Source)) -Force -ErrorAction Stop
    if ($item.PSIsContainer) { Assert-AtlasPlainDirectory $item.FullName }
    else {
        Assert-AtlasPlainFile $item.FullName
        if ((Join-Path ([IO.Path]::GetFullPath($Destination)) $item.Name).Equals($item.FullName,[StringComparison]::OrdinalIgnoreCase)) { throw 'Copy destination would overwrite the source file itself.' }
    }
    $parent=[IO.Path]::GetFullPath($Destination)
    while (-not (Test-Path -LiteralPath $parent)) {
        $parent=[IO.Path]::GetDirectoryName($parent)
        if (-not $parent) { throw 'Copy destination has no existing parent directory.' }
    }
    Assert-AtlasPlainDirectory $parent
}

function ConvertTo-AtlasNativeArgument {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    if ($Value.IndexOf([char]0) -ge 0 -or $Value -match '[\r\n]') { throw 'Native arguments cannot contain NUL or newlines.' }
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Stop-AtlasOwnedNativeProcess {
    [CmdletBinding()]
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)
    if ($Process.HasExited) { return }
    if ($env:OS -eq 'Windows_NT') {
        $info = [Diagnostics.ProcessStartInfo]::new()
        $info.FileName = [IO.Path]::Combine($env:SystemRoot, 'System32\taskkill.exe')
        $info.Arguments = "/PID $($Process.Id) /T /F"
        $info.UseShellExecute = $false; $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
        $stopper = [Diagnostics.Process]::Start($info)
        try {
            $output = $stopper.StandardOutput.ReadToEndAsync(); $errorOutput = $stopper.StandardError.ReadToEndAsync()
            if (-not $stopper.WaitForExit(5000)) { $stopper.Kill(); throw 'Owned process tree termination timed out.' }
            if ($stopper.ExitCode -ne 0 -and -not $Process.HasExited) { throw 'Owned process tree termination failed.' }
            [void]$output.Wait(1000); [void]$errorOutput.Wait(1000)
        } finally { $stopper.Dispose() }
    } else { $Process.Kill($true) }
    if (-not $Process.WaitForExit(5000)) { throw 'Owned process could not be stopped; inspect manually.' }
}

function Invoke-AtlasNativeProcess {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FilePath,[string]$Arguments='',
        [string[]]$ArgumentList,[string]$WorkingDirectory,
        [ValidateRange(1,86400)][int]$TimeoutSeconds=600,[int[]]$SuccessCodes=@(0),
        [Threading.CancellationToken]$CancellationToken=[Threading.CancellationToken]::None,
        [switch]$NoCapture,[ValidateRange(1024,1048576)][int]$MaxCapturedCharacters=65536,
        [string]$OutputLogPath)
    if($PSBoundParameters.ContainsKey('ArgumentList') -and $PSBoundParameters.ContainsKey('Arguments')){throw 'Choose ArgumentList or raw Arguments, not both.'}
    if($NoCapture -and $OutputLogPath){throw 'OutputLogPath requires capture.'}
    if($PSBoundParameters.ContainsKey('ArgumentList')){$Arguments=(@($ArgumentList|ForEach-Object {ConvertTo-AtlasNativeArgument $_}) -join ' ')}
    if($CancellationToken.IsCancellationRequested){
        return [pscustomobject]@{State='Cancelled';Started=$false;Completed=$false;Cancelled=$true;TimedOut=$false;ExitCode=$null;Stdout='';Stderr='';DurationSeconds=0;OutputCaptured=$false;StdoutTruncated=$false;StderrTruncated=$false;OutputLogPath=$null}
    }
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$FilePath;$info.Arguments=$Arguments
    if($WorkingDirectory){$info.WorkingDirectory=$WorkingDirectory}
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=-not $NoCapture;$info.RedirectStandardError=-not $NoCapture
    $watch=[Diagnostics.Stopwatch]::StartNew();$process=$null;$writer=$null
    $pumps=@()
    try {
        if($OutputLogPath){
            $OutputLogPath=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputLogPath)
            Assert-AtlasPlainDirectory (Split-Path -Parent $OutputLogPath)
            # CreateNew refuses an existing file/link. Full verbose logs are explicit, not automatic.
            $stream=[IO.File]::Open($OutputLogPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
            $writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
        }
        $process=[Diagnostics.Process]::Start($info)
        $cancelled=$false;$timedOut=$false;$drainUntil=$null
        if(-not $NoCapture){
            foreach($name in @('Stdout','Stderr')){
                $reader=if($name -eq 'Stdout'){$process.StandardOutput}else{$process.StandardError}
                $buffer=New-Object char[] 4096
                $pumps+=@{Name=$name;Reader=$reader;Buffer=$buffer;Read=$reader.ReadAsync($buffer,0,$buffer.Length);Tail=[Text.StringBuilder]::new();Truncated=$false;Done=$false}
            }
        }
        while($true){
            # Drain both pipes progressively; neither channel buffers the entire output.
            foreach($pump in $pumps){
                $batches=0
                while(-not $pump.Done -and $pump.Read.IsCompleted -and $batches -lt 32){
                    $count=$pump.Read.GetAwaiter().GetResult()
                    if($count -eq 0){$pump.Done=$true;break}
                    if($writer){$writer.Write("[$($pump.Name)]");$writer.Write($pump.Buffer,0,$count)}
                    [void]$pump.Tail.Append($pump.Buffer,0,$count)
                    if($pump.Tail.Length -gt $MaxCapturedCharacters){
                        [void]$pump.Tail.Remove(0,$pump.Tail.Length-$MaxCapturedCharacters);$pump.Truncated=$true
                    }
                    $pump.Read=$pump.Reader.ReadAsync($pump.Buffer,0,$pump.Buffer.Length);$batches++
                }
            }
            $exited=$process.WaitForExit(20)
            if(-not $exited){
                if($CancellationToken.IsCancellationRequested){$cancelled=$true;Stop-AtlasOwnedNativeProcess -Process $process;$exited=$true}
                elseif($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds){$timedOut=$true;Stop-AtlasOwnedNativeProcess -Process $process;$exited=$true}
            }
            if($exited){
                if(-not $drainUntil){$drainUntil=[datetime]::UtcNow.AddSeconds(3)}
                if($NoCapture -or @($pumps|Where-Object {-not $_.Done}).Count -eq 0 -or [datetime]::UtcNow -ge $drainUntil){break}
            }
        }
        $captured=$NoCapture -or @($pumps|Where-Object {-not $_.Done}).Count -eq 0
        if($writer){$writer.Flush()}
        $out=$pumps|Where-Object Name -eq 'Stdout';$err=$pumps|Where-Object Name -eq 'Stderr'
        [pscustomobject]@{State=$(if($cancelled){'Cancelled'}elseif($timedOut){'TimedOut'}elseif(-not $captured){'NotEvaluated'}elseif($SuccessCodes -contains $process.ExitCode){'Correct'}else{'Failed'});
            Started=$true;Completed=(-not($timedOut -or $cancelled));Cancelled=$cancelled;TimedOut=$timedOut;ExitCode=$process.ExitCode;
            Stdout=$(if($out){$out.Tail.ToString()}else{''});Stderr=$(if($err){$err.Tail.ToString()}else{''});
            DurationSeconds=$watch.Elapsed.TotalSeconds;OutputCaptured=([bool]$captured -and -not $NoCapture);
            StdoutTruncated=[bool]$out.Truncated;StderrTruncated=[bool]$err.Truncated;OutputLogPath=$OutputLogPath}
    } finally {
        $watch.Stop()
        if($process){try{if(-not $process.HasExited){Stop-AtlasOwnedNativeProcess -Process $process}}finally{$process.Dispose()}}
        if($writer){$writer.Dispose()}
    }
}

function Get-AtlasCopyInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source,[ValidateRange(0,1000)][int]$SampleSize=0,
        [string[]]$ExcludeFiles=@(),[string[]]$ExcludeDirs=@(),[switch]$SkipCensus,[scriptblock]$FileAction)
    $root=Get-Item -LiteralPath $Source -Force -ErrorAction Stop
    $sourceRoot=if($root.PSIsContainer){$root.FullName}else{$root.DirectoryName}
    Assert-AtlasPlainDirectory $sourceRoot
    $sample=[Collections.Generic.SortedList[string,IO.FileInfo]]::new([StringComparer]::Ordinal)
    $files=[long]0; $bytes=[long]0; $links=0; $errors=0; $excluded=0
    $walk=[Collections.Generic.Stack[object]]::new()
    if($SkipCensus){return [pscustomobject]@{Files=$null;Size=$null;SizeMB=$null;Sample=@();Complete=$false;Scope='Census skipped; size/count not evaluated';UnverifiedLinks=0;UnverifiedPaths=0;Excluded=0;SourceRoot=$sourceRoot}}
    $item=$root
    try {
        while($item -or $walk.Count) {
            if(-not $item) {
                try {
                    if($walk.Peek().MoveNext()){$item=$walk.Peek().Current}
                    else {$e=$walk.Pop();if($e -is [IDisposable]){$e.Dispose()};continue}
                } catch {$errors++;$e=$walk.Pop();if($e -is [IDisposable]){$e.Dispose()};continue}
            }
            $isDirectory=$item -is [IO.DirectoryInfo]
            $patterns=if($isDirectory -and $item.FullName -ne $root.FullName){$ExcludeDirs}elseif(-not $isDirectory){$ExcludeFiles}else{@()}
            $skip=$false
            foreach($pattern in $patterns){if($item.Name -like $pattern){$skip=$true;break}}
            if($skip){$excluded++;$item=$null;continue}
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){$links++;$item=$null;continue}
            if($isDirectory) {
                try {Assert-AtlasPlainDirectory $item.FullName;$walk.Push($item.EnumerateFileSystemInfos().GetEnumerator())}
                catch {$errors++}
            } else {
                $files++;$bytes+=$item.Length
                if($FileAction){& $FileAction $item | Out-Null}
                if($SampleSize -gt 0) {
                    if($sample.Count -lt $SampleSize){$sample.Add($item.FullName,$item)}
                    elseif([StringComparer]::Ordinal.Compare($item.FullName,$sample.Keys[$sample.Count-1]) -lt 0){
                        $sample.RemoveAt($sample.Count-1);$sample.Add($item.FullName,$item)
                    }
                }
            }
            $item=$null
        }
    } finally {while($walk.Count){$e=$walk.Pop();if($e -is [IDisposable]){$e.Dispose()}}}
    $complete=($errors -eq 0 -and $links -eq 0)
    [pscustomobject]@{Files=$files;Size=$bytes;SizeMB=[math]::Round($bytes/1MB,1);Sample=@($sample.Values);Complete=$complete;
        Scope=$(if($complete){'Eligible plain files; hidden/system included; exclusions applied'}else{"Partial census: $errors unreadable path(s), $links link(s) not evaluated"});
        UnverifiedLinks=$links;UnverifiedPaths=$errors;Excluded=$excluded;SourceRoot=$sourceRoot}
}

function Test-AtlasCopySample {
    [CmdletBinding()]
    param([string]$Source,[string]$Destination,[ValidateRange(1,1000)][int]$SampleSize=15,[string[]]$ExcludeFiles=@(),[string[]]$ExcludeDirs=@())
    $inventory=Get-AtlasCopyInventory -Source $Source -SampleSize $SampleSize -ExcludeFiles $ExcludeFiles -ExcludeDirs $ExcludeDirs
    $sample=@($inventory.Sample);$links=$inventory.UnverifiedLinks;$errors=$inventory.UnverifiedPaths
    if(-not $sample.Count){return @{OK=$false;State='NotEvaluated';Coverage='No eligible plain source files';Checked=0;Passed=0;Failed=0;Missing=0;UnverifiedLinks=$links;UnverifiedPaths=$errors}}
    $passed=0;$failed=0;$missing=0
    foreach($file in $sample){
        $relative=$file.FullName.Substring($inventory.SourceRoot.Length).TrimStart([char[]]'\/')
        $target=Join-Path $Destination $relative
        if(-not(Test-Path -LiteralPath $target -PathType Leaf)){$missing++;continue}
        try{
            Assert-AtlasPlainFile $file.FullName; Assert-AtlasPlainFile $target
            if((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash -eq (Get-FileHash -LiteralPath $target -Algorithm SHA256 -ErrorAction Stop).Hash){$passed++}else{$failed++}
        }catch{$failed++}
    }
    @{OK=($failed -eq 0 -and $missing -eq 0 -and $inventory.Complete);State=$(if($failed -or $missing){'Failed'}elseif(-not $inventory.Complete){'NotEvaluated'}else{'SampleVerified'});
        Coverage="SHA256 sample $($sample.Count)/$($inventory.Files) eligible plain files (first ordinal paths); $links links and $errors unreadable paths not evaluated; not full copy certification";
        Checked=$sample.Count;Passed=$passed;Failed=$failed;Missing=$missing;UnverifiedLinks=$links;UnverifiedPaths=$errors}
}

function Resolve-AtlasBackupDestination {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DefaultDirectory,[string]$ExistingDirectory,[Parameter(Mandatory)][string[]]$Sources)
    $target=$DefaultDirectory
    if(-not [string]::IsNullOrWhiteSpace($ExistingDirectory)) {
        $target=$ExistingDirectory.Trim().Trim('"')
        if(-not (Test-Path -LiteralPath $target -PathType Container)){throw 'Select an existing backup directory, not its parent.'}
    }
    $target=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($target)
    foreach($source in $Sources){Assert-AtlasCopyDestination -Source $source -Destination $target}
    return $target
}

function Compare-AtlasCopyMetadata {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination,[string[]]$ExcludeFiles=@(),[string[]]$ExcludeDirs=@())
    Assert-AtlasCopyDestination -Source $Source -Destination $Destination
    $sourceItem=Get-Item -LiteralPath $Source -Force -ErrorAction Stop
    $comparisonRoot=if($sourceItem.PSIsContainer){$sourceItem.FullName}else{$sourceItem.DirectoryName}
    $comparisonTarget=if($sourceItem.PSIsContainer -and $sourceItem.Name){Join-Path $Destination $sourceItem.Name}else{$Destination}
    $counts=@{New=0;Modified=0;Equal=0;SizeTotal=[long]0;Errors=0}
    $inspect={
        param($file)
        $relative=$file.FullName.Substring($comparisonRoot.Length).TrimStart([char[]]'\/')
        $target=Join-Path $comparisonTarget $relative
        try {
            if(-not (Test-Path -LiteralPath $target -PathType Leaf)){$counts.New++;$counts.SizeTotal+=$file.Length}
            else {
                Assert-AtlasPlainFile $target
                $destinationFile=Get-Item -LiteralPath $target -Force -ErrorAction Stop
                if($destinationFile.Length -ne $file.Length -or $destinationFile.LastWriteTimeUtc -ne $file.LastWriteTimeUtc){$counts.Modified++;$counts.SizeTotal+=$file.Length}
                else {$counts.Equal++}
            }
        } catch {$counts.Errors++}
    }
    $inventory=Get-AtlasCopyInventory -Source $Source -ExcludeFiles $ExcludeFiles -ExcludeDirs $ExcludeDirs -FileAction $inspect
    [pscustomobject]@{New=$counts.New;Modified=$counts.Modified;Equal=$counts.Equal;SizeTotal=$counts.SizeTotal;Complete=($inventory.Complete -and $counts.Errors -eq 0);
        Scope='Metadata candidates only; same size/date is not content integrity; native copy log is authoritative'}
}

function Remove-AtlasHostsAlias {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text,[Parameter(Mandatory)][string]$Hostname)
    if($Hostname -notmatch '^(?=.{1,253}$)[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$'){throw 'Invalid exact hosts name.'}
    $lines=foreach($line in ($Text -split '\r?\n')){
        $parts=$line -split '#',2; $tokens=@($parts[0].Trim() -split '\s+' | Where-Object {$_})
        if($tokens.Count -lt 2 -or $tokens[1..($tokens.Count-1)] -inotcontains $Hostname){$line;continue}
        $aliases=@($tokens[1..($tokens.Count-1)] | Where-Object {$_ -ine $Hostname})
        if($aliases.Count){$tokens[0]+"`t"+($aliases -join ' ')+$(if($parts.Count -gt 1){' #'+$parts[1]}else{''})}
        elseif($parts.Count -gt 1){'#'+$parts[1]}
    }
    return $lines -join "`r`n"
}

function Set-AtlasHostsText {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $item=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Hosts file cannot be a link.'}
    Assert-AtlasPlainDirectory (Split-Path -Parent $item.FullName)
    $before=[IO.File]::ReadAllBytes($item.FullName)
    $backup=$item.FullName+'.atlas-'+[guid]::NewGuid().ToString('N')+'.bak'
    $temp=$item.FullName+'.atlas-'+[guid]::NewGuid().ToString('N')+'.tmp'
    try{
        [IO.File]::WriteAllBytes($backup,$before)
        if([Convert]::ToBase64String([IO.File]::ReadAllBytes($backup)) -cne [Convert]::ToBase64String($before)){throw 'Hosts backup readback failed.'}
        [IO.File]::WriteAllText($temp,$Text,[Text.UTF8Encoding]::new($false))
        [IO.File]::Replace($temp,$item.FullName,$backup+'.replace',$true)
        if([IO.File]::ReadAllText($item.FullName,[Text.Encoding]::UTF8) -cne $Text){throw 'Hosts write could not be verified; restore the backup.'}
        return $backup
    }finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force -ErrorAction Stop}}
}

function Clear-AtlasPrintQueue {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$PrinterName)
    # Remove only the selected queue's jobs. Never stop Spooler and delete every queue.
    $printer=Get-Printer -Name $PrinterName -ErrorAction Stop
    if(-not $printer){throw 'Selected printer is unavailable.'}
    $jobs=@(Get-PrintJob -PrinterName $PrinterName -ErrorAction Stop)
    foreach($job in $jobs){Remove-PrintJob -PrinterName $PrinterName -ID $job.ID -ErrorAction Stop}
    $remaining=@(Get-PrintJob -PrinterName $PrinterName -ErrorAction Stop)
    if(@($remaining | Where-Object {$jobs.ID -contains $_.ID}).Count){throw 'Some selected jobs remain; queue clearing was incomplete.'}
    return $jobs.Count
}

function Save-AtlasDnsSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$AdapterNames,[Parameter(Mandatory)][string]$Path)
    $rows=foreach($name in $AdapterNames){
        $adapter=Get-NetAdapter -Name $name -ErrorAction Stop
        foreach($family in @('IPv4','IPv6')){
            $row=Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $family -ErrorAction Stop
            if(-not $row){throw "Missing DNS row for $name/$family"}
            $service=if($family -eq 'IPv4'){'Tcpip'}else{'Tcpip6'}
            $key="HKLM:\SYSTEM\CurrentControlSet\Services\$service\Parameters\Interfaces\$(([guid]$adapter.InterfaceGuid).ToString('B'))"
            $properties=Get-ItemProperty -LiteralPath $key -ErrorAction Stop
            [pscustomobject]@{Guid=[string]$adapter.InterfaceGuid;Family=$family;Automatic=[string]::IsNullOrWhiteSpace([string]$properties.NameServer);Servers=@($row.ServerAddresses)}
        }
    }
    $envelope=[ordered]@{SchemaVersion=1;CreatedUtc=[datetime]::UtcNow.ToString('o');Adapters=@($rows)}
    [IO.File]::WriteAllText($Path,($envelope|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    $read=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)|ConvertFrom-Json -ErrorAction Stop
    if($read.SchemaVersion -ne 1 -or @($read.Adapters).Count -ne @($rows).Count){throw 'DNS snapshot readback failed; no mutation is allowed.'}
    return $Path
}

function Restore-AtlasDnsSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $snapshot=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)|ConvertFrom-Json -ErrorAction Stop
    if($snapshot.SchemaVersion -ne 1 -or @($snapshot.Adapters).Count -eq 0){throw 'Unsupported DNS backup. Legacy backups do not preserve DHCP/static origin.'}
    # Validate the entire snapshot before the first mutation.
    $plan=@(); $seen=@{}
    $adapters=@(Get-NetAdapter -ErrorAction Stop)
    foreach($entry in $snapshot.Adapters){
        $parsedGuid=[guid]::Empty
        if($entry.Family -notin @('IPv4','IPv6') -or $entry.Automatic -isnot [bool] -or -not [guid]::TryParse([string]$entry.Guid,[ref]$parsedGuid)){throw 'Invalid DNS snapshot row.'}
        foreach($address in @($entry.Servers)){
            $ip=$null
            if(-not [Net.IPAddress]::TryParse([string]$address,[ref]$ip) -or
                ($entry.Family -eq 'IPv4' -and $ip.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) -or
                ($entry.Family -eq 'IPv6' -and $ip.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetworkV6)){throw 'Invalid DNS address family in snapshot.'}
        }
        if(-not $entry.Automatic -and @($entry.Servers).Count -eq 0){throw 'Static DNS snapshot lacks addresses.'}
        $id=$parsedGuid.ToString()+'/'+$entry.Family
        if($seen.ContainsKey($id)){throw 'Duplicate DNS snapshot row.'}
        $seen[$id]=$true
        $adapter=@($adapters | Where-Object {[guid]$_.InterfaceGuid -eq $parsedGuid})
        if(@($adapter).Count -ne 1){throw "DNS adapter cannot be identified: $($entry.Guid)"}
        $adapter=$adapter[0]
        $row=Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $entry.Family -ErrorAction Stop
        if(@($row).Count -ne 1){throw 'DNS address-family row is unavailable.'}
        $service=if($entry.Family -eq 'IPv4'){'Tcpip'}else{'Tcpip6'}
        $key="HKLM:\SYSTEM\CurrentControlSet\Services\$service\Parameters\Interfaces\$(([guid]$adapter.InterfaceGuid).ToString('B'))"
        Get-ItemProperty -LiteralPath $key -ErrorAction Stop | Out-Null
        $plan+=@{Entry=$entry;Adapter=$adapter;Row=$row;Key=$key}
    }
    $completed=0
    foreach($step in $plan){
      $entry=$step.Entry; $adapter=$step.Adapter; $row=$step.Row
      try {
        if($entry.Automatic){Set-DnsClientServerAddress -InputObject $row -ResetServerAddresses -ErrorAction Stop}
        else{Set-DnsClientServerAddress -InputObject $row -ServerAddresses @($entry.Servers) -ErrorAction Stop}
        $after=Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $entry.Family -ErrorAction Stop
        if(-not $entry.Automatic -and (@($after.ServerAddresses)-join ',') -ne (@($entry.Servers)-join ',')){throw 'DNS static restoration could not be verified.'}
        $origin=Get-ItemProperty -LiteralPath $step.Key -ErrorAction Stop
        if($entry.Automatic -and -not [string]::IsNullOrWhiteSpace([string]$origin.NameServer)){throw 'Automatic DNS restoration could not be verified.'}
        $completed++
      } catch {
        throw "DNS restoration incomplete: $completed/$($plan.Count) rows verified; inspect $($entry.Guid)/$($entry.Family) and snapshot $Path. $($_.Exception.Message)"
      }
    }
}

function Get-AtlasPlainTreeFiles {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)
    $pending=[Collections.Generic.Stack[string]]::new()
    $pending.Push($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Root))
    while($pending.Count) {
        $directory=$pending.Pop()
        Assert-AtlasPlainDirectory $directory
        foreach($item in Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop) {
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw "Linked member not allowed: $($item.Name)"}
            if($item.PSIsContainer){$pending.Push($item.FullName)}
            else {Assert-AtlasPlainFile $item.FullName; $item}
        }
    }
}

function Write-AtlasDriverManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Directory)
    $root=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Directory).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    $path=Join-Path $root 'driver-backup-manifest.json'
    if(Test-Path -LiteralPath $path){throw 'Driver manifest already exists; use a new export attempt.'}
    $files=@(Get-AtlasPlainTreeFiles -Root $root | ForEach-Object {
        [ordered]@{Path=$_.FullName.Substring($root.Length).Replace('\','/');Bytes=$_.Length;Sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()}
    })
    if(-not $files.Count -or -not @($files | Where-Object Path -match '\.inf$').Count){throw 'No driver INF exported; no completed backup can be claimed.'}
    $manifest=[ordered]@{SchemaVersion=2;CreatedUtc=[datetime]::UtcNow.ToString('o');ExportVerified=$true;RestorationTested=$false;FileCount=$files.Count;InfCount=@($files|Where-Object Path -match '\.inf$').Count;Files=$files}
    [IO.File]::WriteAllText($path,($manifest|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
    Test-AtlasDriverManifest -Directory $Directory | Out-Null
    return $path
}

function Test-AtlasDriverManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Directory)
    $root=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Directory).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    $path=Join-Path $root 'driver-backup-manifest.json'
    Assert-AtlasPlainFile $path
    $manifest=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json -ErrorAction Stop
    if($manifest.SchemaVersion -ne 2 -or -not @($manifest.Files).Count -or $manifest.FileCount -ne @($manifest.Files).Count){throw 'Invalid driver manifest.'}
    $seen=@{}
    foreach($file in $manifest.Files) {
        if([string]$file.Path -match '(^|[\\/])\.\.?([\\/]|$)' -or [IO.Path]::IsPathRooted([string]$file.Path) -or [string]$file.Sha256 -cnotmatch '^[a-f0-9]{64}$'){throw 'Invalid driver manifest member.'}
        $member=[IO.Path]::GetFullPath((Join-Path $root $file.Path))
        if(-not $member.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or $seen.ContainsKey($member)){throw 'Duplicate or escaping driver member.'}
        $seen[$member]=$true
        Assert-AtlasPlainFile $member
        if((Get-Item -LiteralPath $member -Force -ErrorAction Stop).Length -ne $file.Bytes -or
            (Get-FileHash -LiteralPath $member -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() -cne $file.Sha256){throw "Driver member verification failed: $($file.Path)"}
    }
    $actual=@(Get-AtlasPlainTreeFiles -Root $root | Where-Object FullName -ne $path)
    if($actual.Count -ne $seen.Count -or @($actual | Where-Object {-not $seen.ContainsKey($_.FullName)}).Count){throw 'Driver tree differs from the recorded export.'}
    return $manifest
}

function Set-AtlasManagedHostsBlock {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$ListText,[Parameter(Mandatory)][uri]$Source)
    if($Source.Scheme -ne 'https' -or $Source.Host -ne 'raw.githubusercontent.com' -or $Source.AbsolutePath -notlike '/StevenBlack/hosts/*'){throw 'Unexpected hosts list source.'}
    $entries=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($line in $ListText -split '\r?\n') {
        $body=($line -split '#',2)[0].Trim()
        if(-not $body){continue}
        $parts=$body -split '\s+'
        if($parts.Count -lt 2){throw 'Malformed hosts list row.'}
        $localNames=@('localhost','localhost.localdomain','local','ip6-localhost','ip6-loopback','ip6-localnet','ip6-mcastprefix','ip6-allnodes','ip6-allrouters','ip6-allhosts','broadcasthost')
        if(-not @($parts[1..($parts.Count-1)] | Where-Object {$_ -notin $localNames}).Count){continue}
        $ip=$null
        if(-not [Net.IPAddress]::TryParse($parts[0],[ref]$ip)){throw 'Malformed hosts list address.'}
        foreach($name in $parts[1..($parts.Count-1)]) {
            if($name -in $localNames){continue}
            if($parts[0] -notin @('0.0.0.0','127.0.0.1','::') -or $name -notmatch '^(?=.{1,253}$)[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$'){throw 'Unexpected non-blocking hosts list row.'}
            [void]$entries.Add("0.0.0.0 $($name.ToLowerInvariant())")
        }
    }
    if(-not $entries.Count){throw 'No blocking entries found.'}
    $text=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)
    if($text -match '(?m)^# === ATLAS StevenBlack applied '){throw 'Legacy appended list found. Restore its recorded backup before applying a managed block; personal entries will not be guessed.'}
    $begin='# BEGIN ATLAS STEVENBLACK'; $end='# END ATLAS STEVENBLACK'
    $starts=[regex]::Matches($text,'(?m)^# BEGIN ATLAS STEVENBLACK\r?$').Count
    $ends=[regex]::Matches($text,'(?m)^# END ATLAS STEVENBLACK\r?$').Count
    if($starts -ne $ends -or $starts -gt 1){throw 'Malformed managed hosts markers.'}
    $digest=Get-AtlasTextHash $ListText
    $observed=[datetime]::UtcNow.ToString('o')
    if($starts -and $text.Contains("# Observed normalized-text SHA256: $digest")){
        $previousDate=[regex]::Match($text,'(?m)^# Observed UTC: ([^\r\n]+)')
        if($previousDate.Success){$observed=$previousDate.Groups[1].Value}
    }
    $block=(@($begin,"# Source: $($Source.AbsoluteUri)","# Observed UTC: $observed","# Observed normalized-text SHA256: $digest")+@($entries | Sort-Object)+@($end)) -join [Environment]::NewLine
    if($starts) {
        $pattern='(?ms)^# BEGIN ATLAS STEVENBLACK\r?\n.*?^# END ATLAS STEVENBLACK(?:\r?\n|$)'
        if(-not [regex]::IsMatch($text,$pattern)){throw 'Invalid managed block boundaries.'}
        $new=[regex]::Replace($text,$pattern,[Text.RegularExpressions.MatchEvaluator]{param($m)$block+[Environment]::NewLine})
    } else {$new=$text+[Environment]::NewLine+$block+[Environment]::NewLine}
    if($new -ceq $text){return [pscustomobject]@{Changed=$false;Backup=$null;Sha256=$digest;Entries=$entries.Count}}
    $backup=Set-AtlasHostsText -Path $Path -Text $new
    [pscustomobject]@{Changed=$true;Backup=$backup;Sha256=$digest;Entries=$entries.Count}
}

function Clear-AtlasDnsCache {
    [CmdletBinding()]
    param()
    try {
        $result=Invoke-AtlasNativeProcess -FilePath (Join-Path $env:SystemRoot 'System32\ipconfig.exe') -ArgumentList @('/flushdns') -TimeoutSeconds 15
    } catch {
        Write-Warning 'DNS cache refresh could not be evaluated; a completed hosts write or restoration remains separate.'
        return [pscustomobject]@{State='NotEvaluated';ExitCode=$null}
    }
    if($result.State -ne 'Correct'){Write-Warning "DNS cache refresh not completed: $($result.State), exit $($result.ExitCode). Hosts file changes remain separate."}
    return $result
}

function Restore-AtlasHostsBackup {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Backup)
    Assert-AtlasPlainFile $Backup
    Assert-AtlasPlainFile $Path
    $bytes=[IO.File]::ReadAllBytes($Backup)
    $previous=Set-AtlasHostsText -Path $Path -Text ([IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8))
    [IO.File]::WriteAllBytes($Path,$bytes)
    if((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $Backup -Algorithm SHA256).Hash){throw "Hosts byte restoration failed; recovery copy: $previous"}
    return $previous
}

function Get-AtlasServiceSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$Name)
    $service=Get-Service -Name $Name -ErrorAction Stop
    if($service.Status.ToString() -notin @('Running','Stopped')){throw 'Wait for the service to reach a stable state.'}
    if(@($service.DependentServices | Where-Object Status -ne 'Stopped').Count){throw 'Running dependents exist. Atlas will not force-stop them.'}
    $cim=Get-CimInstance -OperationTimeoutSec 10 -ClassName Win32_Service -Filter "Name='$Name'" -ErrorAction Stop
    if($cim.StartMode -notin @('Auto','Manual','Disabled')){throw 'Unknown startup mode; no change allowed.'}
    $key="HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    $properties=Get-ItemProperty -LiteralPath $key -ErrorAction Stop
    $delayed=$properties.PSObject.Properties['DelayedAutostart']
    [pscustomobject]@{SchemaVersion=1;Name=$Name;Status=$service.Status.ToString();StartMode=$cim.StartMode;DelayedPresent=($null -ne $delayed);DelayedValue=$(if($delayed){[int]$delayed.Value}else{0})}
}

function Restore-AtlasServiceSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)
    if($Snapshot.SchemaVersion -ne 1 -or $Snapshot.Name -notmatch '^[A-Za-z0-9_-]+$' -or $Snapshot.Status -notin @('Running','Stopped') -or $Snapshot.StartMode -notin @('Auto','Manual','Disabled') -or $Snapshot.DelayedPresent -isnot [bool]){throw 'Invalid service snapshot.'}
    $name=$Snapshot.Name
    $mode=@{Auto='Automatic';Manual='Manual';Disabled='Disabled'}[$Snapshot.StartMode]
    # A running service can legitimately have Disabled startup. Restore runtime first.
    if($Snapshot.Status -eq 'Running'){
        if((Get-Service -Name $name -ErrorAction Stop).Status -ne 'Running'){
            Set-Service -Name $name -StartupType Manual -ErrorAction Stop
            Start-Service -Name $name -ErrorAction Stop
        }
    }elseif((Get-Service -Name $name -ErrorAction Stop).Status -ne 'Stopped'){
        Stop-Service -Name $name -ErrorAction Stop
    }
    Set-Service -Name $name -StartupType $mode -ErrorAction Stop
    $key="HKLM:\SYSTEM\CurrentControlSet\Services\$name"
    if($Snapshot.DelayedPresent){Set-ItemProperty -LiteralPath $key -Name DelayedAutostart -Value $Snapshot.DelayedValue -Type DWord -ErrorAction Stop}
    elseif((Get-ItemProperty -LiteralPath $key -ErrorAction Stop).PSObject.Properties['DelayedAutostart']){Remove-ItemProperty -LiteralPath $key -Name DelayedAutostart -ErrorAction Stop}
    $after=Get-Service -Name $name -ErrorAction Stop
    $cim=Get-CimInstance -OperationTimeoutSec 10 -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
    if($after.Status.ToString() -ne $Snapshot.Status -or $cim.StartMode -ne $Snapshot.StartMode){throw 'Service restoration could not be verified.'}
    $properties=Get-ItemProperty -LiteralPath $key -ErrorAction Stop
    $delayed=$properties.PSObject.Properties['DelayedAutostart']
    if(($null -ne $delayed) -ne $Snapshot.DelayedPresent -or ($Snapshot.DelayedPresent -and [int]$delayed.Value -ne $Snapshot.DelayedValue)){throw 'Delayed service startup restoration could not be verified.'}
}
