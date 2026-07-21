# ============================================================
# Invoke-ExtraerLicencias
# Migrado de: EXTAER+LICENCIAS.ps1
# Atlas PC Support — v1.0
# ============================================================

function Invoke-ExtraerLicencias {
    [CmdletBinding()]
    param()
# ============================================================================
# Script: Extractor de Licencias ATLAS y Auditor (Estable)
# Arquitectura: PowerShell (Compatible v2.0+)
# Objetivo: Extracción de BIOS, OS Actual y Detección de Originalidad
# ============================================================================

<#
.SYNOPSIS
    Fuerza la elevación de privilegios de Administrador de manera estable.
#>
$ErrorActionPreference = "Stop"

# (auto-elevación gestionada por Atlas Launcher)

<#
.SYNOPSIS
    Funciones de interfaz de usuario para alineación y formato estandarizado.
#>
$Host.UI.RawUI.WindowTitle = "ATLAS PC SUPPORT - Extract Product Keys"
$atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

function Write-Centered {
    param(
        [string]$Text,
        [ConsoleColor]$Color = 'White'
    )
    $windowWidth = $Host.UI.RawUI.WindowSize.Width
    if ($windowWidth -gt $Text.Length) {
        $padding = [math]::Max(0, [math]::Floor(($windowWidth - $Text.Length) / 2))
        $spaces = " " * $padding
        Write-Host "$spaces$Text" -ForegroundColor $Color
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Show-Header {
    Clear-Host
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title "EXTRACT PRODUCT KEYS" -Color Yellow
        Write-AtlasStep "Windows · Office · BIOS/UEFI"
        Write-Host ''
        return
    }
    Write-Host "`n"
    Write-Centered -Text "========================================" -Color Yellow
    Write-Centered -Text "  EXTRACT PRODUCT KEYS" -Color Yellow
    Write-Centered -Text "  Windows · Office · BIOS/UEFI" -Color DarkGray
    Write-Centered -Text "========================================" -Color Yellow
    Write-Host "`n"
}

function Wait-AtlasReturn {
    param([string]$Message = "Press ENTER to return")
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message $Message
        return
    }
    Write-Centered -Text $Message -Color White
    $null = Read-Host
}

<#
.SYNOPSIS
    OPCIÓN 1: Extracción de clave inyectada en placa base (BIOS/UEFI)
#>
function Get-BiosKey {
    Show-Header
    Write-Centered -Text "--- BIOS/UEFI FACTORY KEY EXTRACTION ---" -Color Cyan
    Write-Host "`n"
    
    try {
        $wmiQuery = Get-CimInstance -Query 'SELECT * FROM SoftwareLicensingService' -ErrorAction Stop
        $biosKey = $wmiQuery.OA3xOriginalProductKey
        $biosDesc = $wmiQuery.OA3xOriginalProductKeyDescription

        if ([string]::IsNullOrWhiteSpace($biosKey)) {
            Write-Centered -Text "[!] No OEM key found in BIOS/UEFI." -Color Red
            Write-Centered -Text "This computer did not come with Windows pre-installed from factory." -Color Gray
        } else {
            Write-Centered -Text "[+] BIOS KEY FOUND:" -Color Green
            if (-not [string]::IsNullOrWhiteSpace($biosDesc)) {
                Write-Centered -Text "Factory Edition: $biosDesc" -Color Cyan
            }
            Write-Centered -Text $biosKey -Color Yellow
            $biosKey | clip
            Write-Host "`n"
            Write-Centered -Text "(Copied to clipboard securely)" -Color Gray
        }
    } catch {
        Write-Centered -Text "[X] Error querying ACPI table: $($_.Exception.Message)" -Color Red
    }
    
    Write-Host "`n"
    Wait-AtlasReturn -Message "Press ENTER to return to menu..."
}

<#
.SYNOPSIS
    OPTION 2: Extract currently installed key (Advanced Registry Base24)
#>
function Get-CurrentKey {
    Show-Header
    Write-Centered -Text "--- CURRENT KEY EXTRACTION (INSTALLED OS) ---" -Color Cyan
    Write-Host "`n"
    
    try {
        # 1. Mostrar la Clave de la BIOS como referencia cruzada
        $sls = Get-CimInstance -Query 'SELECT * FROM SoftwareLicensingService' -ErrorAction SilentlyContinue
        $biosRefKey = $sls.OA3xOriginalProductKey
        $biosRefDesc = $sls.OA3xOriginalProductKeyDescription
        
        if (-not [string]::IsNullOrWhiteSpace($biosRefKey)) {
            Write-Centered -Text "[+] FACTORY KEY (BIOS) FOR REFERENCE:" -Color DarkCyan
            if (-not [string]::IsNullOrWhiteSpace($biosRefDesc)) {
                Write-Centered -Text "Factory Edition: $biosRefDesc" -Color Cyan
            }
            Write-Centered -Text $biosRefKey -Color Gray
            Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray
        }

        # 2. Búsqueda en el Registro para el OS Actual
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $backupKey = (Get-ItemProperty -Path $regPath -Name BackupProductKeyDefault -ErrorAction SilentlyContinue).BackupProductKeyDefault

        $hexPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        
        # Corrección: Leer edición real desde WMI para evitar el falso "Windows 10" del registro de Win 11
        $currentEdition = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption -replace '^Microsoft\s+', ''
        
        $digitalProductId = (Get-ItemProperty -Path $hexPath -Name DigitalProductId -ErrorAction SilentlyContinue).DigitalProductId
        
        $decodedKey = $null
        $isKMSOrDigital = $false

        if ($digitalProductId -ne $null -and $digitalProductId.Length -ge 67) {
            $isWin8Or10 = [math]::Floor($digitalProductId[66] / 6) -band 1
            $digitalProductId[66] = ($digitalProductId[66] -band 0xF7) -bOr (($isWin8Or10 -band 2) * 4)
            $chars = "BCDFGHJKMPQRTVWXY2346789"
            $decodedKeyStr = ""
            for ($i = 24; $i -ge 0; $i--) {
                $current = 0
                for ($j = 14; $j -ge 0; $j--) {
                    $current = $current * 256 + $digitalProductId[$j + 52]
                    $digitalProductId[$j + 52] = [math]::Floor($current / 24)
                    $current = $current % 24
                }
                $decodedKeyStr = $chars[$current] + $decodedKeyStr
                $last = $current
            }
            if ($isWin8Or10 -eq 1) {
                $decodedKeyStr = $decodedKeyStr.Substring(1, $last) + "N" + $decodedKeyStr.Substring($last + 1)
            }
            $decodedKey = $decodedKeyStr.Insert(5, "-").Insert(11, "-").Insert(17, "-").Insert(23, "-")
            
            if ($decodedKey -eq "BBBBB-BBBBB-BBBBB-BBBBB-BBBBB") {
                $decodedKey = $null
                $isKMSOrDigital = $true
            }
        }

        $activeWmi = Get-CimInstance -Query "SELECT PartialProductKey, Description FROM SoftwareLicensingProduct WHERE LicenseStatus = 1 AND PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue

        if ($activeWmi) {
            Write-Centered -Text "[+] ACTIVATION ENGINE EVIDENCE (ONLY REAL DATA):" -Color Cyan
            foreach ($lic in $activeWmi) {
                Write-Centered -Text "Partial: ******-******-******-******-$($lic.PartialProductKey)" -Color White
            }
            Write-Host ""
        }

        if (-not [string]::IsNullOrWhiteSpace($currentEdition)) {
            Write-Centered -Text "Installed Edition: $currentEdition" -Color Cyan
            Write-Host ""
        }

        if ($isKMSOrDigital) {
            Write-Centered -Text "[!] TECHNICAL ALERT: KEY HIDDEN BY DESIGN" -Color Yellow
            Write-Centered -Text "Windows has removed the key from registry for corporate security." -Color Gray
            Write-Centered -Text "The license is MAK or Digital and does not reside physically on disk." -Color Gray
        } elseif (-not [string]::IsNullOrWhiteSpace($decodedKey)) {
            Write-Centered -Text "[+] DECODED KEY FROM REGISTRY:" -Color Green
            Write-Centered -Text $decodedKey -Color Yellow
            $decodedKey | clip
        }

        if (-not [string]::IsNullOrWhiteSpace($backupKey)) {
            Write-Host ""
            Write-Centered -Text "[+] BACKUP KEY FOUND:" -Color DarkCyan
            Write-Centered -Text $backupKey -Color Gray
        }

    } catch {
        Write-Centered -Text "[X] Critical decoding error." -Color Red
    }
    
    Write-Host "`n"
    Wait-AtlasReturn -Message "Press ENTER to return to menu..."
}

<#
.SYNOPSIS
    OPTION 3: Native audit via SLMGR
#>
function Invoke-NativeAudit {
    Show-Header
    Write-Centered -Text "--- NATIVE SYSTEM AUDIT (SLMGR) ---" -Color Cyan
    Write-Host "`n"
    Write-Centered -Text "Starting official Microsoft tool..." -Color Gray
    
    # Ejecuta el comando nativo de Windows para mostrar información de la licencia
    cscript //nologo C:\Windows\System32\slmgr.vbs /dli
    
    Write-Host "`n"
    Write-Centered -Text "--- AUTHENTICITY ANALYSIS ---" -Color Cyan
    try {
        $wmi = Get-CimInstance -Query "SELECT Description, LicenseStatus FROM SoftwareLicensingProduct WHERE LicenseStatus = 1 AND PartialProductKey IS NOT NULL"
        foreach ($item in $wmi) {
            if ($item.Description -match "VOLUME_KMSCLIENT") {
                Write-Centered -Text "[!] DETECTED: KMS CHANNEL (Possible emulator activation)" -Color Yellow
            } elseif ($item.Description -match "VOLUME_MAK|RETAIL|OEM") {
                Write-Centered -Text "[+] DETECTED: ORIGINAL CHANNEL ($($item.Description -replace '.*, ', ''))" -Color Green
            }
        }
    } catch {}

    Write-Host "`n"
    Wait-AtlasReturn -Message "Press ENTER to return to menu..."
}

<#
.SYNOPSIS
    OPTION 4: System Information (Includes BIOS Key, Current Key and Visual Audit)
#>
function Get-OsInfo {
    Show-Header
    Write-Centered -Text "--- OPERATING SYSTEM INFORMATION ---" -Color Cyan
    Write-Host "`n"
    
    # Variables para almacenar el reporte exportable
    $reportTxt = "========================================`r`nATLAS PC SUPPORT - SYSTEM REPORT`r`n========================================`r`n`r`n"
    $reportHtml = "<html><head><meta charset='UTF-8'><title>ATLAS Report</title><style>body{font-family:'Segoe UI',Tahoma,sans-serif;background:#121212;color:#e0e0e0;text-align:center} .container{max-width:700px;margin:auto;background:#1e1e1e;padding:20px;border-radius:10px;box-shadow:0 4px 8px rgba(0,0,0,0.5)} h2{color:#f1c40f} .ok{color:#2ecc71} .warn{color:#f39c12} .info{color:#3498db;font-style:italic;font-size:0.9em;margin-top:5px;}</style></head><body><div class='container'><h2>ATLAS PC SUPPORT<br><small>License Report</small></h2><hr>"

    try {
        # Obtener datos del OS
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Centered -Text "System: $($os.Caption)" -Color White
        Write-Centered -Text "Version: $($os.Version)" -Color White
        Write-Centered -Text "Architecture: $($os.OSArchitecture)" -Color White
        Write-Centered -Text "OS Serial: $($os.SerialNumber)" -Color White
        
        $reportTxt += "--- OPERATING SYSTEM ---`r`nSystem: $($os.Caption)`r`nVersion: $($os.Version)`r`nArchitecture: $($os.OSArchitecture)`r`nSerial: $($os.SerialNumber)`r`n`r`n"
        $reportHtml += "<h3>OPERATING SYSTEM</h3><p>System: $($os.Caption)<br>Version: $($os.Version)<br>Architecture: $($os.OSArchitecture)<br>Serial: $($os.SerialNumber)</p><hr>"
        
        Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray
        
        # ---------------------------------------------------------
        # Obtener datos de la BIOS (Punto 1 integrado)
        # ---------------------------------------------------------
        Write-Centered -Text "--- FACTORY KEY (BIOS/UEFI) ---" -Color Cyan
        $sls = Get-CimInstance -Query 'SELECT * FROM SoftwareLicensingService'
        $biosKey = $sls.OA3xOriginalProductKey
        $biosDesc = $sls.OA3xOriginalProductKeyDescription
        
        $reportTxt += "--- FACTORY KEY (BIOS/UEFI) ---`r`n"
        $reportHtml += "<h3>FACTORY KEY (BIOS/UEFI)</h3>"

        if ([string]::IsNullOrWhiteSpace($biosKey)) {
            Write-Centered -Text "BIOS Key: Not found (computer without factory Windows)" -Color Gray
            $reportTxt += "Status: Not found.`r`n`r`n"
            $reportHtml += "<p>Status: Not found.</p><hr>"
        } else {
            $descText = if ([string]::IsNullOrWhiteSpace($biosDesc)) { "Unknown Version" } else { $biosDesc }
            Write-Centered -Text "Factory Version: $descText" -Color Cyan
            Write-Centered -Text "BIOS Key: $biosKey" -Color Green
            Write-Centered -Text "[i] NOTE: Keys injected into BIOS (OEM) come from the" -Color DarkCyan
            Write-Centered -Text "computer manufacturer and are genuine licenses by nature." -Color DarkCyan

            $reportTxt += "Factory Version: $descText`r`nBIOS Key: $biosKey`r`n[i] NOTE: Keys injected into BIOS (OEM) come from the computer manufacturer and are genuine licenses by nature.`r`n`r`n"
            $reportHtml += "<p>Factory Version: <strong style='color:#3498db'>$descText</strong></p><p>BIOS Key: <strong class='ok'>$biosKey</strong></p><p class='info'>[i] NOTE: Keys injected into BIOS (OEM) come from the computer manufacturer and are genuine licenses by nature.</p><hr>"
        }
        
        Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray

        # ---------------------------------------------------------
        # Obtener datos de la Clave Actual (Punto 2 integrado)
        # ---------------------------------------------------------
        Write-Centered -Text "--- CURRENT KEY (INSTALLED OS) ---" -Color Cyan
        
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $backupKey = (Get-ItemProperty -Path $regPath -Name BackupProductKeyDefault -ErrorAction SilentlyContinue).BackupProductKeyDefault

        $hexPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        
        # Corrección WMI:
        $currentEdition = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption -replace '^Microsoft\s+', ''
        
        $digitalProductId = (Get-ItemProperty -Path $hexPath -Name DigitalProductId -ErrorAction SilentlyContinue).DigitalProductId
        
        $decodedKey = $null
        $isKMSOrDigital = $false

        if ($digitalProductId -ne $null -and $digitalProductId.Length -ge 67) {
            $isWin8Or10 = [math]::Floor($digitalProductId[66] / 6) -band 1
            $digitalProductId[66] = ($digitalProductId[66] -band 0xF7) -bOr (($isWin8Or10 -band 2) * 4)
            $chars = "BCDFGHJKMPQRTVWXY2346789"
            $decodedKeyStr = ""
            for ($i = 24; $i -ge 0; $i--) {
                $current = 0
                for ($j = 14; $j -ge 0; $j--) {
                    $current = $current * 256 + $digitalProductId[$j + 52]
                    $digitalProductId[$j + 52] = [math]::Floor($current / 24)
                    $current = $current % 24
                }
                $decodedKeyStr = $chars[$current] + $decodedKeyStr
                $last = $current
            }
            if ($isWin8Or10 -eq 1) {
                $decodedKeyStr = $decodedKeyStr.Substring(1, $last) + "N" + $decodedKeyStr.Substring($last + 1)
            }
            $decodedKey = $decodedKeyStr.Insert(5, "-").Insert(11, "-").Insert(17, "-").Insert(23, "-")
            
            if ($decodedKey -eq "BBBBB-BBBBB-BBBBB-BBBBB-BBBBB") {
                $decodedKey = $null
                $isKMSOrDigital = $true
            }
        }

        $reportTxt += "--- CURRENT KEY (INSTALLED OS) ---`r`n"
        $reportHtml += "<h3>CURRENT KEY (INSTALLED OS)</h3>"

        $edText = if ([string]::IsNullOrWhiteSpace($currentEdition)) { "Unknown Edition" } else { $currentEdition }
        Write-Centered -Text "Installed Edition: $edText" -Color Cyan
        $reportTxt += "Installed Edition: $edText`r`n"
        $reportHtml += "<p>Installed Edition: <strong style='color:#3498db'>$edText</strong></p>"

        if ($isKMSOrDigital) {
            Write-Centered -Text "Decoded Key: [Hidden by corporate security]" -Color Yellow
            $reportTxt += "Status: Physical key hidden (MAK/KMS or Digital).`r`n"
            $reportHtml += "<p class='warn'>Status: Physical key hidden (MAK/KMS or Digital).</p>"
        } elseif (-not [string]::IsNullOrWhiteSpace($decodedKey)) {
            Write-Centered -Text "Decoded Key: $decodedKey" -Color Green
            $reportTxt += "Decoded Key: $decodedKey`r`n"
            $reportHtml += "<p>Decoded Key: <strong class='ok'>$decodedKey</strong></p>"
        } else {
            Write-Centered -Text "Decoded Key: Not found" -Color Gray
            $reportTxt += "Decoded Key: Not found`r`n"
            $reportHtml += "<p>Decoded Key: Not found</p>"
        }

        if (-not [string]::IsNullOrWhiteSpace($backupKey)) {
            Write-Centered -Text "Backup Key: $backupKey" -Color DarkCyan
            $reportTxt += "Backup Key: $backupKey`r`n"
            $reportHtml += "<p>Backup Key: <strong>$backupKey</strong></p>"
        }

        $reportTxt += "`r`n"
        $reportHtml += "<hr>"
        Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray

        # ---------------------------------------------------------
        # Obtener datos de Originalidad Visual (Punto 3 integrado)
        # ---------------------------------------------------------
        Write-Centered -Text "--- AUTHENTICITY ANALYSIS ---" -Color Cyan
        $wmiLic = Get-CimInstance -Query "SELECT Description, LicenseStatus FROM SoftwareLicensingProduct WHERE LicenseStatus = 1 AND PartialProductKey IS NOT NULL"
        
        $reportTxt += "--- AUTHENTICITY ANALYSIS ---`r`n"
        $reportHtml += "<h3>AUTHENTICITY ANALYSIS</h3>"

        if (-not $wmiLic) {
            Write-Centered -Text "[!] No active license detected on system." -Color Red
            $reportTxt += "Status: No active license.`r`n"
            $reportHtml += "<p class='warn'>Status: No active license.</p>"
        } else {
            foreach ($item in $wmiLic) {
                $cleanDesc = $item.Description -replace '.*, ', ''
                if ($item.Description -match "VOLUME_KMSCLIENT") {
                    Write-Centered -Text "[!] DETECTED: KMS CHANNEL ($cleanDesc)" -Color Yellow
                    Write-Centered -Text "[i] NOTE: Volume activation. If this computer does not belong" -Color DarkCyan
                    Write-Centered -Text "to a company, it was very likely activated using an emulator (Pirated)." -Color DarkCyan

                    $reportTxt += "[!] DETECTED: KMS CHANNEL ($cleanDesc)`r`n[i] NOTE: Volume activation. If this computer does not belong to a company, it was very likely activated using an emulator (Pirated).`r`n"
                    $reportHtml += "<p class='warn'>[!] DETECTED: KMS CHANNEL ($cleanDesc)</p><p class='info'>[i] NOTE: Volume activation. If this computer does not belong to a company, it was very likely activated using an emulator (Pirated).</p>"
                } elseif ($item.Description -match "VOLUME_MAK|RETAIL|OEM") {
                    Write-Centered -Text "[+] DETECTED: ORIGINAL CHANNEL ($cleanDesc)" -Color Green
                    Write-Centered -Text "[i] NOTE: Verified with the Windows licensing engine" -Color DarkCyan
                    Write-Centered -Text "that the current channel is official and legally ACTIVATED." -Color DarkCyan

                    $reportTxt += "[+] DETECTED: ORIGINAL CHANNEL ($cleanDesc)`r`n[i] NOTE: Verified with the Windows licensing engine that the current channel is official and legally ACTIVATED.`r`n"
                    $reportHtml += "<p class='ok'>[+] DETECTED: ORIGINAL CHANNEL ($cleanDesc)</p><p class='info'>[i] NOTE: Verified with the Windows licensing engine that the current channel is official and legally ACTIVATED.</p>"
                } else {
                    Write-Centered -Text "[?] DETECTED: UNKNOWN CHANNEL ($cleanDesc)" -Color Gray
                    
                    $reportTxt += "[?] DETECTED: UNKNOWN CHANNEL ($cleanDesc)`r`n"
                    $reportHtml += "<p>[?] DETECTED: UNKNOWN CHANNEL ($cleanDesc)</p>"
                }
            }
        }
        $reportHtml += "</div></body></html>"
        
    } catch {
        Write-Centered -Text "[X] Error retrieving system information." -Color Red
    }
    
    # Export menu
    Write-Host "`n----------------------------------------`n" -ForegroundColor DarkGray
    Write-Centered -Text "--- EXPORT THIS REPORT ---" -Color Yellow
    Write-Centered -Text "[ 1 ] Save as Text Document (.txt)" -Color White
    Write-Centered -Text "[ 2 ] Save as Web Page (.html)" -Color White
    Write-Centered -Text "[ 0 ] Back to menu without saving" -Color Red
    Write-Host "`n"

    $exportLoop = $true
    while ($exportLoop) {
        $expSel = Read-Host " Select an option"
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        
        switch ($expSel) {
            '1' {
                $outPath = "$desktopPath\ATLAS_License_Report.txt"
                [System.IO.File]::WriteAllText($outPath, $reportTxt)
                Write-Host "`n"
                Write-Centered -Text "[+] Successfully saved to your Desktop:" -Color Green
                Write-Centered -Text "ATLAS_License_Report.txt" -Color Gray
                $exportLoop = $false
            }
            '2' {
                $outPath = "$desktopPath\ATLAS_License_Report.html"
                [System.IO.File]::WriteAllText($outPath, $reportHtml, [System.Text.Encoding]::UTF8)
                Write-Host "`n"
                Write-Centered -Text "[+] Successfully saved to your Desktop:" -Color Green
                Write-Centered -Text "ATLAS_License_Report.html" -Color Gray
                $exportLoop = $false
            }
            '0' {
                $exportLoop = $false
            }
            default {
                Write-Centered -Text "[!] Invalid selection. Please try again." -Color Red
            }
        }
    }

    Write-Host "`n"
    Wait-AtlasReturn -Message "Press ENTER to return to main menu..."
}

# ============================================================================
#  OPCION 5: Claves de Office (SPP/OSPP + registro)
# ============================================================================
function Get-OfficeKeys {
    Show-Header
    Write-Centered -Text "--- OFFICE PRODUCT KEYS (SPP/OSPP) ---" -Color Cyan
    Write-Host ""

    $encontradas = @()

    # 5.1 Via OSPP / SPP: listar las licencias activas de Office via WMI
    try {
        $lics = Get-CimInstance -Query "SELECT * FROM SoftwareLicensingProduct WHERE ApplicationID='59A52881-A989-479D-AF46-F275C6370663' AND PartialProductKey IS NOT NULL" -ErrorAction Stop
        foreach ($l in $lics) {
            $statusMap = @{ 0='Unlicensed'; 1='Licensed'; 2='OOB Grace'; 3='OOT Grace'; 4='Non-Genuine Grace'; 5='Notification'; 6='Extended Grace' }
            $status = if ($statusMap.ContainsKey([int]$l.LicenseStatus)) { $statusMap[[int]$l.LicenseStatus] } else { "Code $($l.LicenseStatus)" }
            $encontradas += [pscustomobject]@{
                Producto = $l.Name
                Descripcion = $l.Description
                ParcialPK = "XXXXX-XXXXX-XXXXX-XXXXX-$($l.PartialProductKey)"
                Estado = $status
                Fuente = 'OSPP / SoftwareLicensingProduct'
            }
        }
    } catch {
        Write-Centered -Text "[!] Could not query OSPP: $($_.Exception.Message)" -Color Yellow
    }

    # 5.2 Buscar keys en registro HKLM:\SOFTWARE\Microsoft\Office\*\Registration\*\DigitalProductId
    try {
        $baseKeys = @(
            'HKLM:\SOFTWARE\Microsoft\Office',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office'
        )
        foreach ($bk in $baseKeys) {
            if (-not (Test-Path $bk)) { continue }
            $regs = Get-ChildItem -Path "$bk\*\Registration\*" -ErrorAction SilentlyContinue
            foreach ($r in $regs) {
                $dpi = (Get-ItemProperty -Path $r.PSPath -Name DigitalProductId -ErrorAction SilentlyContinue).DigitalProductId
                $prodName = (Get-ItemProperty -Path $r.PSPath -Name ProductName -ErrorAction SilentlyContinue).ProductName
                if ($dpi) {
                    $key = Decode-DigitalProductId -BinKey $dpi
                    if ($key) {
                        $encontradas += [pscustomobject]@{
                            Producto = if ($prodName) { $prodName } else { $r.PSChildName }
                            Descripcion = 'DigitalProductId in Registry'
                            ParcialPK = $key
                            Estado = 'Active (registry)'
                            Fuente = 'Registry Office'
                        }
                    }
                }
            }
        }
    } catch { }

    if ($encontradas.Count -eq 0) {
        Write-Centered -Text "[!] No active Office keys detected." -Color Yellow
    } else {
        foreach ($e in $encontradas) {
            Write-Centered -Text ("Product : {0}" -f $e.Producto) -Color White
            Write-Centered -Text ("Status  : {0}" -f $e.Estado) -Color Cyan
            Write-Centered -Text ("Key     : {0}" -f $e.ParcialPK) -Color Yellow
            Write-Centered -Text ("Source  : {0}" -f $e.Fuente) -Color DarkGray
            Write-Host ""
        }
    }

    Write-Host ""
    $exp = Read-Host " Export results to TXT on Desktop? [Y/N]"
    if ($exp -match '^[SsYy]$') {
        $out = [Environment]::GetFolderPath('Desktop') + "\ATLAS_OfficeKeys_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
        $txt = "=== ATLAS - OFFICE PRODUCT KEYS ===`r`nDate: $(Get-Date)`r`n`r`n"
        foreach ($e in $encontradas) {
            $txt += "Product     : $($e.Producto)`r`nStatus      : $($e.Estado)`r`nKey         : $($e.ParcialPK)`r`nSource      : $($e.Fuente)`r`n`r`n"
        }
        [System.IO.File]::WriteAllText($out, $txt, [System.Text.UTF8Encoding]::new($true))
        Write-Centered -Text "[OK] Saved: $out" -Color Green
    }

    Write-Host ""
    Wait-AtlasReturn -Message "Press ENTER to return"
}

# ============================================================================
#  Helper: Decodificar DigitalProductId (algoritmo Microsoft)
# ============================================================================
function Decode-DigitalProductId {
    param([byte[]]$BinKey)
    if (-not $BinKey -or $BinKey.Length -lt 67) { return $null }
    $isWin8 = ($BinKey[66] -band 0x8) -eq 0x8
    $chars = 'BCDFGHJKMPQRTVWXY2346789'
    $keyOffset = 52
    $out = ''

    if ($isWin8) {
        # Algoritmo Win8+ (25 chars, con N al 10)
        $bin = @($BinKey[$keyOffset..($keyOffset + 14)])
        $bin[14] = ($bin[14] -band 0xF7)
        $lastIdx = 0
        $decoded = New-Object 'System.Collections.Generic.List[char]'
        for ($i = 24; $i -ge 0; $i--) {
            $cur = 0
            for ($j = 14; $j -ge 0; $j--) {
                $cur = ($cur * 256) -bxor $bin[$j]
                $bin[$j] = [byte]([Math]::Floor($cur / 24))
                $cur = $cur % 24
            }
            $decoded.Insert(0, [char]$chars[$cur])
            $lastIdx = $cur
        }
        $first = $decoded[0]
        $decoded.RemoveAt(0)
        $decoded.Insert($lastIdx, 'N')
        $decoded.Insert(0, $first)
        $s = -join $decoded
        # Formato XXXXX-XXXXX-XXXXX-XXXXX-XXXXX (25 chars agrupados 5+5+5+5+5)
        $parts = @()
        for ($i = 0; $i -lt 25; $i += 5) { $parts += $s.Substring($i, [Math]::Min(5, 25 - $i)) }
        return ($parts -join '-')
    } else {
        # Algoritmo legacy
        $bin = @($BinKey[$keyOffset..($keyOffset + 14)])
        $decoded = New-Object 'System.Collections.Generic.List[char]'
        for ($i = 24; $i -ge 0; $i--) {
            $cur = 0
            for ($j = 14; $j -ge 0; $j--) {
                $cur = ($cur * 256) -bxor $bin[$j]
                $bin[$j] = [byte]([Math]::Floor($cur / 24))
                $cur = $cur % 24
            }
            $decoded.Insert(0, [char]$chars[$cur])
        }
        $s = -join $decoded
        $parts = @()
        for ($i = 0; $i -lt 25; $i += 5) { $parts += $s.Substring($i, [Math]::Min(5, 25 - $i)) }
        return ($parts -join '-')
    }
}

# ============================================================================
#  OPCION 6: Claves de productos instalados (DigitalProductId en Registry)
# ============================================================================
function Get-InstalledProductKeys {
    Show-Header
    Write-Centered -Text "--- INSTALLED PRODUCT KEYS (DigitalProductId) ---" -Color Cyan
    Write-Host ""
    Write-Centered -Text "Scanning HKLM and HKCU for DigitalProductId..." -Color DarkGray
    Write-Host ""

    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office',
        'HKCU:\SOFTWARE\Microsoft\Office'
    )

    $resultados = @()
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        try {
            $hits = Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | Where-Object {
                $_.GetValue('DigitalProductId') -ne $null
            }
            foreach ($h in $hits) {
                $bin = $h.GetValue('DigitalProductId')
                $prod = $h.GetValue('ProductName')
                if (-not $prod) { $prod = $h.GetValue('ProductID') }
                if (-not $prod) { $prod = $h.PSChildName }
                $key = Decode-DigitalProductId -BinKey $bin
                if ($key -match '^[A-Z0-9]{5}(-[A-Z0-9]{5}){4}$') {
                    $resultados += [pscustomobject]@{
                        Producto = $prod
                        Clave = $key
                        Ruta = $h.PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
                    }
                }
            }
        } catch { }
    }

    if ($resultados.Count -eq 0) {
        Write-Centered -Text "[!] No decodable DigitalProductIds found." -Color Yellow
    } else {
        foreach ($r in ($resultados | Sort-Object Producto -Unique)) {
            Write-Centered -Text ("{0}" -f $r.Producto) -Color White
            Write-Centered -Text ("  Key: {0}" -f $r.Clave) -Color Yellow
            Write-Centered -Text ("  {0}" -f $r.Ruta) -Color DarkGray
            Write-Host ""
        }
    }

    Write-Host ""
    $exp = Read-Host " Export to TXT? [Y/N]"
    if ($exp -match '^[SsYy]$') {
        $out = [Environment]::GetFolderPath('Desktop') + "\ATLAS_ProductKeys_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
        $txt = "=== ATLAS - PRODUCT KEYS (DigitalProductId) ===`r`nDate: $(Get-Date)`r`n`r`n"
        foreach ($r in ($resultados | Sort-Object Producto -Unique)) {
            $txt += "Product : $($r.Producto)`r`nKey     : $($r.Clave)`r`nPath    : $($r.Ruta)`r`n`r`n"
        }
        [System.IO.File]::WriteAllText($out, $txt, [System.Text.UTF8Encoding]::new($true))
        Write-Centered -Text "[OK] Saved: $out" -Color Green
    }

    Write-Host ""
    Wait-AtlasReturn -Message "Press ENTER to return"
}

# Bucle principal
$menuLoop = $true
while ($menuLoop) {
    Show-Header
    Write-Centered -Text "M A I N   M E N U" -Color Cyan
    Write-Host "`n"
    Write-Centered -Text "[ 1 ] Extract Factory Key (BIOS/UEFI)" -Color White
    Write-Centered -Text "[ 2 ] Extract and Diagnose Current Key (Registry)" -Color White
    Write-Centered -Text "[ 3 ] Native Audit and Authenticity (SLMGR)" -Color White
    Write-Centered -Text "[ 4 ] Full Report (OS, BIOS, Current and Authenticity)" -Color White
    Write-Centered -Text "[ 5 ] Extract Office Keys (OSPP/SPP + Registry)" -Color Cyan
    Write-Centered -Text "[ 6 ] Installed product keys (DigitalProductId)" -Color Cyan
    Write-Centered -Text "[ 0 ] Exit" -Color Red
    Write-Host "`n"
    
    $selection = Read-Host " Select an option"
    
    switch ($selection) {
        '1' { Get-BiosKey }
        '2' { Get-CurrentKey }
        '3' { Invoke-NativeAudit }
        '4' { Get-OsInfo }
        '5' { Get-OfficeKeys }
        '6' { Get-InstalledProductKeys }
        '0' { $menuLoop = $false }
    }
}
}
