function Invoke-ExtraerLicencias {
    [CmdletBinding()]
    param()
    function Get-LicenseInventory {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $products = @(Get-CimInstance SoftwareLicensingProduct -Filter 'PartialProductKey IS NOT NULL' -Property Name,Description,LicenseStatus,PartialProductKey -ErrorAction Stop)
        [pscustomobject]@{
            Trace = Get-AtlasReportTrace -Tool 'License inventory'
            Windows = $os.Caption; Build = $os.BuildNumber
            Coverage = 'Local Windows/Office licensing records only. Microsoft 365 subscriptions and entitlement are not verified. Registry/decoded generic keys do not prove activation.'
            Products = @($products | ForEach-Object {
                [pscustomobject]@{
                    Name = $_.Name; Description = $_.Description
                    LicenseStatusCode = $_.LicenseStatus
                    Status = if ($_.LicenseStatus -eq 1) { 'Licensed (reported locally by Windows)' } else { 'Not confirmed licensed; inspect native status code' }
                    PartialProductKey = '[HIDDEN]'
                }
            })
        }
    }
    do {
        Write-AtlasHeader 'Licencias / License inventory'
        Write-Host '[1] Consultar estado local Windows/Office (sin claves completas)'
        Write-Host '[2] Revelar clave OEM de este equipo, con confirmacion'
        Write-Host '[3] Exportar inventario redactado'
        Write-Host '[4] Abrir Activacion de Windows'
        Write-Host '[0] Volver'
        try {
            switch (Read-Host 'Opcion') {
                '1' { Get-LicenseInventory | ConvertTo-Json -Depth 6 | Write-Host }
                '2' {
                    if ((Read-Host 'La clave es sensible. Escribe REVEAL para verla en esta consola') -cne 'REVEAL') { continue }
                    $key = [string](Get-CimInstance SoftwareLicensingService -Property OA3xOriginalProductKey -ErrorAction Stop).OA3xOriginalProductKey
                    if ($key -notmatch '^[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}$') { Write-AtlasWarn 'No se encontro una clave OEM. Una licencia digital puede no tener clave recuperable.'; continue }
                    Write-Host $key -ForegroundColor Yellow
                    Write-Host 'La presencia de esta clave no prueba activacion ni derecho de transferencia.'
                    if ((Read-Host 'Opcional: escribe COPY para copiarla al portapapeles; ENTER para omitir') -ceq 'COPY') {
                        Set-Clipboard -Value $key -ErrorAction Stop
                        Write-AtlasWarn 'Clave copiada por solicitud. El portapapeles/historial puede conservar datos; gestionarlo corresponde al usuario.'
                    }
                    $key = $null
                }
                '3' {
                    $path = Get-AtlasReportPath -Prefix 'License-inventory' -Extension 'json'
                    $report = Protect-AtlasReportObject (Get-LicenseInventory)
                    [IO.File]::WriteAllText($path, ($report | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
                    Write-AtlasSuccess "Inventario guardado: $path"
                }
                '4' { Start-Process 'ms-settings:activation' -ErrorAction Stop }
                '0' { return }
            }
        } catch { Write-AtlasFailure $_.Exception.Message }
    } while ($true)
}
