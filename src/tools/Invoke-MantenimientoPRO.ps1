function Invoke-MantenimientoPRO {
    [CmdletBinding()]
    param()
    Write-AtlasHeader 'Windows maintenance: inspect first'
    Write-Host '[1] Read Defender status and pending restart indicators'
    Write-Host '[2] DISM CheckHealth + SFC VerifyOnly (may take time)'
    Write-Host '[3] Selected component repair: DISM RestoreHealth + SFC ScanNow'
    Write-Host '[0] Cancel'
    $choice=Read-Host
    if($choice -eq '1'){
        try{Get-MpComputerStatus -ErrorAction Stop | Select-Object AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated | Format-List}catch{Write-Warning "Defender not evaluated: $_"}
        foreach($key in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')){Write-Host "$key : $(Test-Path -LiteralPath $key)"}
    }elseif($choice -in @('2','3')){
        if($choice -eq '3' -and (Read-Host 'Repair is not a routine speedup. Type REPAIR to change Windows components') -cne 'REPAIR'){return}
        $directory=Get-AtlasReportDir -SubFolder Maintenance
        $arguments=if($choice -eq '2'){'/Online /Cleanup-Image /CheckHealth'}else{'/Online /Cleanup-Image /RestoreHealth'}
        $dism=Invoke-AtlasNativeProcess -FilePath "$env:SystemRoot\System32\dism.exe" -Arguments $arguments -TimeoutSeconds 3600 -SuccessCodes @(0,3010)
        $dism|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $directory ('dism-'+[guid]::NewGuid().ToString('N')+'.json')) -Encoding UTF8
        Write-Host "DISM native state: $($dism.State), exit: $($dism.ExitCode); restart pending: $($dism.ExitCode -eq 3010)"
        if($dism.State -ne 'Correct'){throw 'DISM did not complete successfully; inspect its report before SFC.'}
        $sfcArgs=if($choice -eq '2'){'/verifyonly'}else{'/scannow'}
        $sfc=Invoke-AtlasNativeProcess -FilePath "$env:SystemRoot\System32\sfc.exe" -Arguments $sfcArgs -TimeoutSeconds 3600
        $sfc|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $directory ('sfc-'+[guid]::NewGuid().ToString('N')+'.json')) -Encoding UTF8
        Write-Host "SFC process: $($sfc.State), exit: $($sfc.ExitCode). Review CBS.log and output for integrity findings; exit 0 alone does not certify a healthy system."
    }else{return}
    Write-Host 'Cache/recycle-bin deletion, network reset and update-service cleanup are not part of this inspection. Use a separately planned repair for the diagnosed symptom.'
    Wait-AtlasExit
}
