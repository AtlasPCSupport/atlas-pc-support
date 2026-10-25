# Small shared primitives for evidence and reversible Windows operations.
function Assert-AtlasCopyDestination {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination)
    $origin=[IO.Path]::GetFullPath($Source).TrimEnd([char[]]'\/')
    $target=[IO.Path]::GetFullPath($Destination).TrimEnd([char[]]'\/')
    if($target.Equals($origin,[StringComparison]::OrdinalIgnoreCase) -or
        $target.StartsWith($origin+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Copy destination cannot be the source or a child of the source.'}
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
        [string[]]$ArgumentList, [string]$WorkingDirectory,
        [ValidateRange(1,86400)][int]$TimeoutSeconds=600,[int[]]$SuccessCodes=@(0),
        [Threading.CancellationToken]$CancellationToken = [Threading.CancellationToken]::None,
        [switch]$NoCapture)
    if ($PSBoundParameters.ContainsKey('ArgumentList') -and $PSBoundParameters.ContainsKey('Arguments')) { throw 'Choose ArgumentList or raw Arguments, not both.' }
    if ($PSBoundParameters.ContainsKey('ArgumentList')) { $Arguments = (@($ArgumentList | ForEach-Object { ConvertTo-AtlasNativeArgument $_ }) -join ' ') }
    if ($CancellationToken.IsCancellationRequested) {
        return [pscustomobject]@{State='Cancelled';Started=$false;Completed=$false;Cancelled=$true;TimedOut=$false;ExitCode=$null;Stdout='';Stderr='';DurationSeconds=0;OutputCaptured=$false}
    }
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$FilePath; $info.Arguments=$Arguments
    if ($WorkingDirectory) { $info.WorkingDirectory = $WorkingDirectory }
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=-not $NoCapture; $info.RedirectStandardError=-not $NoCapture
    $watch=[Diagnostics.Stopwatch]::StartNew(); $process=$null
    try {
        $process=[Diagnostics.Process]::Start($info)
        $stdout=$null; $stderr=$null; $cancelled=$false; $timedOut=$false
        if (-not $NoCapture) { $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync() }
        while (-not $process.WaitForExit(100)) {
            if ($CancellationToken.IsCancellationRequested) { $cancelled=$true; break }
            if ($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds) { $timedOut=$true; break }
        }
        if ($cancelled -or $timedOut) { Stop-AtlasOwnedNativeProcess -Process $process }
        $captured=$NoCapture -or ($stdout.Wait(3000) -and $stderr.Wait(3000))
        [pscustomobject]@{State=$(if($cancelled){'Cancelled'}elseif($timedOut){'TimedOut'}elseif(-not $captured){'NotEvaluated'}elseif($SuccessCodes -contains $process.ExitCode){'Correct'}else{'Failed'});Started=$true;Completed=(-not($timedOut -or $cancelled));Cancelled=$cancelled;ExitCode=$process.ExitCode;TimedOut=$timedOut;Stdout=$(if($stdout -and $stdout.IsCompleted){$stdout.Result}else{''});Stderr=$(if($stderr -and $stderr.IsCompleted){$stderr.Result}else{''});DurationSeconds=$watch.Elapsed.TotalSeconds;OutputCaptured=([bool]$captured -and -not $NoCapture)}
    } finally {
        $watch.Stop()
        if($process){
            try { if (-not $process.HasExited) { Stop-AtlasOwnedNativeProcess -Process $process } }
            finally { $process.Dispose() }
        }
    }
}

function Test-AtlasCopySample {
    [CmdletBinding()]
    param([string]$Source,[string]$Destination,[int]$SampleSize=15,[string[]]$ExcludeFiles=@(),[string[]]$ExcludeDirs=@())
    $sourceRoot=[IO.Path]::GetFullPath($Source).TrimEnd([char[]]'\/')
    $files=@(Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -ErrorAction Stop)
    $files=@($files | Where-Object {
        $file=$_; $excluded=$false
        foreach($pattern in $ExcludeFiles){if($file.Name -like $pattern){$excluded=$true}}
        $relative=$file.FullName.Substring($sourceRoot.Length).TrimStart([char[]]'\/')
        $parts=@($relative -split '[\\/]')
        if($parts.Count -gt 1){foreach($directory in $parts[0..($parts.Count-2)]){foreach($pattern in $ExcludeDirs){if($directory -like $pattern){$excluded=$true}}}}
        -not $excluded
    })
    if($files.Count -eq 0){return @{OK=$false;State='NotEvaluated';Coverage='No source files';Checked=0;Passed=0;Failed=0;Missing=0}}
    $sample=@($files | Sort-Object FullName | Select-Object -First $SampleSize)
    $passed=0;$failed=0;$missing=0
    foreach($file in $sample){
        Assert-AtlasPlainDirectory $file.DirectoryName
        $relative=$file.FullName.Substring($sourceRoot.Length).TrimStart([char[]]'\/')
        $target=Join-Path $Destination $relative
        if(-not(Test-Path -LiteralPath $target -PathType Leaf)){$missing++;continue}
        try{if((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash -eq (Get-FileHash -LiteralPath $target -Algorithm SHA256 -ErrorAction Stop).Hash){$passed++}else{$failed++}}catch{$failed++}
    }
    @{OK=($failed -eq 0 -and $missing -eq 0);State=$(if($failed -or $missing){'Failed'}else{'SampleVerified'});Coverage="SHA256 sample $($sample.Count)/$($files.Count) eligible files, not full copy certification";Checked=$sample.Count;Passed=$passed;Failed=$failed;Missing=$missing}
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
    foreach($entry in $snapshot.Adapters){
        $parsedGuid=[guid]::Empty
        if($entry.Family -notin @('IPv4','IPv6') -or $entry.Automatic -isnot [bool] -or -not [guid]::TryParse([string]$entry.Guid,[ref]$parsedGuid)){throw 'Invalid DNS snapshot row.'}
        foreach($address in @($entry.Servers)){ $ip=$null; if(-not [Net.IPAddress]::TryParse([string]$address,[ref]$ip)){throw 'Invalid DNS address in snapshot.'} }
        if(-not $entry.Automatic -and @($entry.Servers).Count -eq 0){throw 'Static DNS snapshot lacks addresses.'}
    }
    foreach($entry in $snapshot.Adapters){
        $adapter=Get-NetAdapter -ErrorAction Stop | Where-Object {[string]$_.InterfaceGuid -eq [string]$entry.Guid}
        if(@($adapter).Count -ne 1){throw "DNS adapter cannot be identified: $($entry.Guid)"}
        $row=Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $entry.Family -ErrorAction Stop
        if($entry.Automatic){Set-DnsClientServerAddress -InputObject $row -ResetServerAddresses -ErrorAction Stop}
        else{Set-DnsClientServerAddress -InputObject $row -ServerAddresses @($entry.Servers) -ErrorAction Stop}
        $after=Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily $entry.Family -ErrorAction Stop
        if(-not $entry.Automatic -and (@($after.ServerAddresses)-join ',') -ne (@($entry.Servers)-join ',')){throw 'DNS static restoration could not be verified.'}
        $service=if($entry.Family -eq 'IPv4'){'Tcpip'}else{'Tcpip6'}
        $key="HKLM:\SYSTEM\CurrentControlSet\Services\$service\Parameters\Interfaces\$(([guid]$adapter.InterfaceGuid).ToString('B'))"
        $origin=Get-ItemProperty -LiteralPath $key -ErrorAction Stop
        if($entry.Automatic -and -not [string]::IsNullOrWhiteSpace([string]$origin.NameServer)){throw 'Automatic DNS restoration could not be verified.'}
    }
}

function Get-AtlasServiceSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$Name)
    $service=Get-Service -Name $Name -ErrorAction Stop
    if($service.Status.ToString() -notin @('Running','Stopped')){throw 'Wait for the service to reach a stable state.'}
    if(@($service.DependentServices | Where-Object Status -ne 'Stopped').Count){throw 'Running dependents exist. Atlas will not force-stop them.'}
    $cim=Get-CimInstance -ClassName Win32_Service -Filter "Name='$Name'" -ErrorAction Stop
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
    $cim=Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
    if($after.Status.ToString() -ne $Snapshot.Status -or $cim.StartMode -ne $Snapshot.StartMode){throw 'Service restoration could not be verified.'}
    $properties=Get-ItemProperty -LiteralPath $key -ErrorAction Stop
    $delayed=$properties.PSObject.Properties['DelayedAutostart']
    if(($null -ne $delayed) -ne $Snapshot.DelayedPresent -or ($Snapshot.DelayedPresent -and [int]$delayed.Value -ne $Snapshot.DelayedValue)){throw 'Delayed service startup restoration could not be verified.'}
}
