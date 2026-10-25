# Runtime installation is application-driven. Legacy components are explicit.
function Invoke-InstalarRuntimes {
    [CmdletBinding()]
    param()
    Write-AtlasHeader 'Application runtimes'
    Write-Host '[1] VC++ v14 x64/x86 (only if required by applications)'
    Write-Host '[2] Legacy VC++ 2013 / DirectX / XNA / OpenAL (application requirement only)'
    Write-Host '[3] Windows .NET Framework 3.5 feature (no WinGet required)'
    Write-Host '[0] Cancel'
    $choice=Read-Host
    if ($choice -notin @('1','2','3')) { return }
    if ((Read-Host 'Type INSTALL to continue; no components will be removed') -cne 'INSTALL') { return }
    if ($choice -eq '3') {
        $before=Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction Stop
        if ($before.State -eq 'Enabled') { Write-Host 'NetFx3 is already enabled; no change.'; return }
        $source=Read-Host 'Optional matching Windows image sources\sxs path; Enter uses Windows Update'
        $parameters=@{Online=$true;FeatureName='NetFx3';NoRestart=$true;ErrorAction='Stop'}
        if ($source) {
            if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw 'Source directory missing. Use media matching this Windows build.' }
            $parameters.Source=$source; $parameters.LimitAccess=$true
        }
        $result=Enable-WindowsOptionalFeature @parameters
        $after=Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction Stop
        if ($after.State -notin @('Enabled','EnablePending')) { throw "NetFx3 result could not be verified: $($after.State)" }
        Write-Host "NetFx3 state: $($after.State); restart required: $($result.RestartNeeded)"
        return
    }
    $winget=Get-AtlasWingetPath
    if (-not $winget) { throw 'WinGet unavailable. Check App Installer separately using the Store/App Installer tool.' }
    $ids=if($choice -eq '1'){@('Microsoft.VCRedist.2015+.x64','Microsoft.VCRedist.2015+.x86')}else{@('Microsoft.VCRedist.2013.x64','Microsoft.VCRedist.2013.x86','Microsoft.DirectX','Microsoft.XNARedist','OpenAL.OpenAL')}
    foreach ($id in $ids) {
        $install = Invoke-AtlasNativeProcess -FilePath $winget -ArgumentList @('install','--id',$id,'--exact','--source','winget','--silent','--accept-source-agreements','--accept-package-agreements') -TimeoutSeconds 1800 -SuccessCodes @(0,-1978335189,-1978335135)
        $code=$install.ExitCode
        if ($install.State -ne 'Correct') { Write-Warning "$id $($install.State), native code $code. Inspect any partial installation before retrying."; continue }
        $verification = Invoke-AtlasNativeProcess -FilePath $winget -ArgumentList @('list','--id',$id,'--exact','--source','winget','--accept-source-agreements') -TimeoutSeconds 60
        if ($verification.State -ne 'Correct' -or $verification.Stdout -notmatch [regex]::Escape($id)) { Write-Warning "${id}: operation returned $code but presence could not be verified." }
        else { Write-Host "$id present; native result $code. Review version/support for the requesting application." }
    }
    Wait-AtlasExit
}
