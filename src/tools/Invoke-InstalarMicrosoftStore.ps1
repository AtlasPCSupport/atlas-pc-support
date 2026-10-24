# Store is optional. Do not install an unsupported Store onto a managed image.
function Invoke-InstalarMicrosoftStore {
    [CmdletBinding()]
    param()
    $state = Get-AtlasStoreState
    Write-AtlasHeader 'Store / App Installer'
    Write-Host "Store: $($state.State)"
    Write-Host "App Installer registered: $([bool]$state.AppInstaller); WinGet available: $($state.WingetAvailable)"
    if ($state.Error) { Write-Warning "A query could not be completed: $($state.Error)" }
    if ($state.LTSC) { Write-Warning 'LTSC/IoT: Store may be intentionally absent. Consult image policy; Atlas does not add it automatically.' }
    if ($state.State -eq 'BlockedByPolicy') { Write-Warning 'Store is blocked by policy. No policy will be changed.' }
    elseif ($state.State -eq 'PresentNotRegisteredForCurrentUser') {
        Write-Host 'An existing package can be registered for THIS process user. Run from the intended user session, not alternate admin credentials.'
        if ((Read-Host 'Type REGISTER to register the existing Store; Enter cancels') -ceq 'REGISTER') {
            $manifest = Join-Path $state.ExistingPackage.InstallLocation 'AppxManifest.xml'
            if (-not (Test-Path -LiteralPath $manifest)) { throw 'Existing Store manifest is unavailable.' }
            Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ErrorAction Stop
            $after=Get-AtlasStoreState
            if ($after.State -ne 'RegisteredForCurrentUser') { throw 'Store registration could not be verified.' }
            Write-AtlasSuccess 'Store registration verified for the current user.'
        }
    } elseif ($state.State -eq 'RegisteredForCurrentUser') {
        Write-Host 'For repair/reset use Windows Settings > Apps > Microsoft Store > Advanced options. This may reset app data.'
    } else { Write-Warning 'No supported Store repair is available here. Use your Windows image provider or organizational administrator.' }
    if (-not $state.WingetAvailable) {
        Write-Host 'App Installer / WinGet can be handled separately, without assuming Store exists:'
        Write-Host 'https://learn.microsoft.com/windows/package-manager/winget/#install-winget'
        Write-Host 'Use the official WinGet release or Microsoft.WinGet.Client repair procedure appropriate to this image and user. Atlas does not sideload mixed package versions.'
    }
    Wait-AtlasExit
}
