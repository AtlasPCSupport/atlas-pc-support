function Invoke-Personalizacion {
    [CmdletBinding()]
    param()
    function Apply-Win11Minimal {
        if (-not (Get-AtlasPlatformCapabilities).Windows11) { Write-Warning 'Windows 11 feature unavailable on this platform.'; return }
        Start-Process -FilePath 'ms-settings:taskbar' -ErrorAction Stop | Out-Null
    }
    Write-AtlasHeader 'Windows personalization'
    Write-Host 'Choose settings in the current user session. Atlas does not overwrite registry defaults, restart Explorer or change activation watermarks.'
    Write-Host '[1] Background  [2] Colors/theme  [3] Taskbar  [4] Start preferences  [0] Cancel'
    $choice=Read-Host
    $uri=switch($choice){'1'{'ms-settings:personalization-background'} '2'{'ms-settings:personalization-colors'} '3'{'ms-settings:taskbar'} '4'{'ms-settings:personalization-start'} default{$null}}
    if($uri){Start-Process -FilePath $uri -ErrorAction Stop | Out-Null}
}
