function Invoke-Deduplicador {
    [CmdletBinding()]
    param()
    Write-Warning 'Deduplicator is unavailable: its backend, reproducible runtime and reversible deletion flow are not included in this release.'
    Write-Host 'Atlas will not start an unrelated localhost service, install global Python or delete duplicate candidates. Use a separately qualified workflow until the backend is integrated.'
    if (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue) { Wait-AtlasExit }
}
