function Invoke-StopServices {
    [CmdletBinding()]
    param()
    $allowed=@('SysMain','WSearch','DiagTrack','MapsBroker')
    Write-AtlasHeader 'Services: inspect, select and restore'
    Get-Service -Name $allowed -ErrorAction SilentlyContinue | Format-Table Name,Status,StartType
    Write-Host 'Stopping indexing/cache/telemetry is not a universal performance improvement. No security or remote-support service is selected.'
    Write-Host '[1] Stop one listed service and set Manual, with snapshot'
    Write-Host '[2] Restore a snapshot created here'
    $choice=Read-Host
    $directory=Get-AtlasReportDir -SubFolder ServiceSnapshots
    if($choice -eq '1'){
        $name=Read-Host 'Exact service name'
        if($name -notin $allowed){throw 'This service is not in the restricted supported list.'}
        $snapshot=Get-AtlasServiceSnapshot -Name $name
        if((Read-Host "Type STOP to change $name; active dependents will block the operation") -cne 'STOP'){return}
        $snapshot=Get-AtlasServiceSnapshot -Name $name
        $path=Join-Path $directory ($name+'-'+[guid]::NewGuid().ToString('N')+'.json')
        [IO.File]::WriteAllText($path,($snapshot|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
        $read=[IO.File]::ReadAllText($path)|ConvertFrom-Json -ErrorAction Stop
        if($read.Name -ne $name -or $read.Status -ne $snapshot.Status){throw 'Snapshot verification failed.'}
        try{
            Stop-Service -Name $name -ErrorAction Stop
            Set-Service -Name $name -StartupType Manual -ErrorAction Stop
            $after=Get-AtlasServiceSnapshot -Name $name
            if($after.Status -ne 'Stopped' -or $after.StartMode -ne 'Manual'){throw 'Service change not verified.'}
            Write-Host "Verified. Snapshot: $path"
        }catch{ $failure=$_; try{Restore-AtlasServiceSnapshot $snapshot}catch{Write-Warning "Rollback incomplete: $_; snapshot $path"};throw $failure }
    }elseif($choice -eq '2'){
        Get-ChildItem -LiteralPath $directory -Filter '*.json' | Select-Object Name,LastWriteTime | Format-Table
        $file=Read-Host 'Exact snapshot filename (not a path)'
        if([IO.Path]::GetFileName($file) -cne $file -or $file -notmatch '^[A-Za-z0-9_-]+\.json$'){throw 'Invalid snapshot filename.'}
        $snapshot=[IO.File]::ReadAllText((Join-Path $directory $file))|ConvertFrom-Json -ErrorAction Stop
        if($snapshot.Name -notin $allowed){throw 'Snapshot targets a service outside this tool scope.'}
        if((Read-Host 'Type RESTORE to restore startup and previous running/stopped state') -cne 'RESTORE'){return}
        Restore-AtlasServiceSnapshot $snapshot
        Write-Host 'Previous service state verified.'
    }
    Wait-AtlasExit
}
