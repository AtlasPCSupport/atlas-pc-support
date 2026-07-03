# ============================================================
# Invoke-AuditoriaRouter
# Migrado de: AuditoriaRouter.ps1
# Atlas PC Support — v1.0
# ============================================================

function Invoke-AuditoriaRouter {
    [CmdletBinding()]
    param(
        # Modulo O: lanza el informe completo sin interaccion
        [switch]$Auto
    )
# (#Requires movido al launcher principal)
# ================================================================
#  Atlas PC Support - Herramientas de Red  v3.0
#  Compatibilidad: Windows 10 / 11 / Server 2019+, PS 5+
# ================================================================
[console]::BackgroundColor = "Black"
[console]::ForegroundColor = "Gray"
Clear-Host

# ================================================================
#  VARIABLES GLOBALES DE SESION
# ================================================================
$script:HistorialSesion = [System.Collections.Generic.List[string]]::new()
$script:ArchivoEstado   = "$env:TEMP\AtlasRed_UltimoEscaneo.txt"
$script:MostrarInfo     = $true        # El user puede deshabilitarlo con X en la info card
$script:ModoAuto        = $Auto.IsPresent
$atlasToolkitReady      = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

# ================================================================
#  TABLA OUI - Prefijos MAC (3 octetos) -> Fabricante
#  ~200 entradas de los fabricantes mas comunes en redes domesticas
# ================================================================
$script:OUI = @{
    # Apple
    "00-17-F2"="Apple";"00-1C-BF"="Apple";"00-1E-52"="Apple";"00-23-12"="Apple"
    "00-26-B9"="Apple";"3C-07-54"="Apple";"F4-F1-5A"="Apple";"04-15-52"="Apple"
    "04-26-65"="Apple";"60-03-08"="Apple";"60-C5-47"="Apple";"70-EC-E4"="Apple"
    "78-D7-5F"="Apple";"A4-5E-60"="Apple";"AC-87-A3"="Apple";"B8-8D-12"="Apple"
    "C8-BC-C8"="Apple";"F0-B4-79"="Apple";"D8-BB-C1"="Apple";"E0-AC-CB"="Apple"
    "00-F7-6F"="Apple";"04-4B-ED"="Apple";"04-E5-36"="Apple";"08-74-02"="Apple"
    "0C-4D-E9"="Apple";"10-41-7F"="Apple";"14-5A-05"="Apple";"18-65-90"="Apple"
    "1C-36-BB"="Apple";"20-78-F0"="Apple";"24-A0-74"="Apple";"28-5A-EB"="Apple"
    "34-15-9E"="Apple";"38-C9-86"="Apple";"3C-15-C2"="Apple";"40-30-04"="Apple"
    "44-00-10"="Apple";"48-60-BC"="Apple";"4C-57-CA"="Apple";"50-EA-D6"="Apple"
    "54-26-96"="Apple";"58-55-CA"="Apple";"5C-8D-4E"="Apple";"60-9A-10"="Apple"
    "64-A3-CB"="Apple";"68-AB-1E"="Apple";"6C-40-08"="Apple";"70-14-A6"="Apple"
    "74-E1-B6"="Apple";"78-CA-39"="Apple";"7C-6D-62"="Apple";"80-82-23"="Apple"
    "84-38-35"="Apple";"88-1F-A1"="Apple";"8C-7B-9D"="Apple";"90-3C-92"="Apple"
    "94-F6-A3"="Apple";"98-01-A7"="Apple";"9C-20-7B"="Apple";"A0-99-9B"="Apple"
    "A4-C3-61"="Apple";"A8-5B-78"="Apple";"AC-3C-0B"="Apple";"B0-34-95"="Apple"
    "B4-18-D1"="Apple";"B8-09-8A"="Apple";"BC-3B-AF"="Apple";"C0-9F-42"="Apple"
    "C4-2C-03"="Apple";"C8-2A-14"="Apple";"CC-44-63"="Apple";"D0-03-4B"="Apple"
    "D4-61-9D"="Apple";"D8-1D-72"="Apple";"DC-2B-2A"="Apple";"E0-5F-45"="Apple"
    "E4-CE-8F"="Apple";"E8-80-2E"="Apple";"EC-35-86"="Apple";"F0-DC-E2"="Apple"
    "F4-31-C3"="Apple";"F8-1E-DF"="Apple";"FC-25-3F"="Apple"
    # TP-Link
    "00-0A-EB"="TP-Link";"14-CF-92"="TP-Link";"18-D6-C7"="TP-Link";"20-DC-E6"="TP-Link"
    "28-28-5D"="TP-Link";"30-DE-4B"="TP-Link";"50-C7-BF"="TP-Link";"54-E6-FC"="TP-Link"
    "60-E3-27"="TP-Link";"70-4F-57"="TP-Link";"74-DA-88"="TP-Link";"84-16-F9"="TP-Link"
    "90-F6-52"="TP-Link";"98-DA-C4"="TP-Link";"B0-48-7A"="TP-Link";"C4-6E-1F"="TP-Link"
    "C8-3A-35"="TP-Link";"D8-07-B6"="TP-Link";"EC-08-6B"="TP-Link";"F8-1A-67"="TP-Link"
    "C4-E9-84"="TP-Link";"34-29-12"="TP-Link";"44-94-FC"="TP-Link";"50-3E-AA"="TP-Link"
    "64-70-02"="TP-Link";"7C-39-56"="TP-Link";"80-35-C1"="TP-Link";"AC-84-C6"="TP-Link"
    "B4-B0-24"="TP-Link";"D4-6E-5C"="TP-Link";"F4-EC-38"="TP-Link";"1C-3B-F3"="TP-Link"
    # ASUS
    "00-0C-6E"="ASUS";"00-11-2F"="ASUS";"00-13-D4"="ASUS";"00-15-F2"="ASUS"
    "00-17-31"="ASUS";"00-1A-92"="ASUS";"00-1D-60"="ASUS";"00-1E-8C"="ASUS"
    "00-24-8C"="ASUS";"00-26-18"="ASUS";"04-92-26"="ASUS";"08-60-6E"="ASUS"
    "10-BF-48"="ASUS";"14-DA-E9"="ASUS";"1C-87-2C"="ASUS";"2C-4D-54"="ASUS"
    "30-5A-3A"="ASUS";"38-D5-47"="ASUS";"50-46-5D"="ASUS";"60-45-CB"="ASUS"
    "74-D0-2B"="ASUS";"90-E6-BA"="ASUS";"A0-F3-C1"="ASUS";"AC-22-0B"="ASUS"
    "B0-6E-BF"="ASUS";"BC-AE-C5"="ASUS";"C8-60-00"="ASUS";"FC-34-97"="ASUS"
    "04-D9-F5"="ASUS";"08-62-66"="ASUS";"0C-9D-92"="ASUS";"10-78-D2"="ASUS"
    ;"18-31-BF"="ASUS";"20-CF-30"="ASUS";"24-4B-FE"="ASUS"
    "2C-56-DC"="ASUS";"3C-97-0E"="ASUS";"40-16-7E"="ASUS"
    "44-8A-5B"="ASUS";"48-5B-39"="ASUS";"4C-ED-FB"="ASUS";"50-AF-73"="ASUS"
    "54-04-A6"="ASUS";"58-11-22"="ASUS";"5C-AD-CF"="ASUS";"60-A4-4C"="ASUS"
    "64-00-6A"="ASUS";"68-1C-A2"="ASUS";"6C-FD-B9"="ASUS";"70-4D-7B"="ASUS"
    ;"78-24-AF"="ASUS";"7C-10-C9"="ASUS";"80-1F-02"="ASUS"
    "84-A9-C4"="ASUS";"88-D7-F6"="ASUS";"8C-8D-28"="ASUS";"90-48-9A"="ASUS"
    "94-08-53"="ASUS";"98-EE-CB"="ASUS";"9C-5C-8E"="ASUS";"A8-5E-45"="ASUS"
    "BC-EE-7B"="ASUS";"C8-D3-FF"="ASUS";"CC-28-AA"="ASUS";"D0-17-C2"="ASUS"
    # Samsung
    "00-1D-25"="Samsung";"00-21-19"="Samsung";"00-23-39"="Samsung";"00-24-54"="Samsung"
    "08-08-C2"="Samsung";"10-1D-C0"="Samsung";"14-49-E0"="Samsung";"18-1E-B0"="Samsung"
    "1C-62-B8"="Samsung";"24-4B-81"="Samsung";"28-98-7B"="Samsung";"38-AA-3C"="Samsung"
    "40-0E-85"="Samsung";"44-78-3E"="Samsung";"50-01-BB"="Samsung";"5C-3C-27"="Samsung"
    "60-6B-BD"="Samsung";"6C-2F-2C"="Samsung";"70-F9-27"="Samsung";"84-25-DB"="Samsung"
    "8C-71-F8"="Samsung";"94-76-B7"="Samsung";"A0-07-98"="Samsung";"B4-79-A7"="Samsung"
    "CC-07-AB"="Samsung";"DC-A9-04"="Samsung";"F0-25-B7"="Samsung";"FC-A1-3E"="Samsung"
    "2C-AE-2B"="Samsung";"34-14-5F"="Samsung";"40-B8-37"="Samsung";"48-13-7E"="Samsung"
    "50-CC-F8"="Samsung";"5C-E8-EB"="Samsung";"68-48-98"="Samsung";"78-59-5E"="Samsung"
    "84-55-A5"="Samsung";"8C-A9-82"="Samsung";"90-18-7C"="Samsung";"9C-3A-AF"="Samsung"
    "A4-EB-D3"="Samsung";"BC-20-A4"="Samsung";"C0-BD-D1"="Samsung";"C4-57-6E"="Samsung"
    # Xiaomi
    "0C-1D-AF"="Xiaomi";"10-2A-B3"="Xiaomi";"28-6C-07"="Xiaomi";"34-80-B3"="Xiaomi"
    "38-A4-ED"="Xiaomi";"50-8F-4C"="Xiaomi";"64-09-80"="Xiaomi";"74-23-44"="Xiaomi"
    "78-11-DC"="Xiaomi";"8C-BE-BE"="Xiaomi";"A0-86-C6"="Xiaomi";"AC-F7-F3"="Xiaomi"
    "B0-E4-35"="Xiaomi";"C4-0B-CB"="Xiaomi";"D4-97-0B"="Xiaomi";"F4-8B-32"="Xiaomi"
    "FC-64-BA"="Xiaomi";"64-B4-73"="Xiaomi";"00-9E-C8"="Xiaomi";"04-CF-8C"="Xiaomi"
    "18-59-36"="Xiaomi";"20-82-C0"="Xiaomi";"28-E3-1F"="Xiaomi";"34-CE-00"="Xiaomi"
    "40-31-3C"="Xiaomi";"48-2C-A0"="Xiaomi";"50-64-2B"="Xiaomi";"58-44-98"="Xiaomi"
    # Huawei
    "00-0F-E2"="Huawei";"00-18-82"="Huawei";"00-1E-10"="Huawei";"00-25-9E"="Huawei"
    "04-BD-70"="Huawei";"0C-37-96"="Huawei";"1C-8E-5C"="Huawei";"28-3C-E4"="Huawei"
    "2C-AB-00"="Huawei";"34-6B-D3"="Huawei";"40-4D-8E"="Huawei";"48-46-FB"="Huawei"
    "54-89-98"="Huawei";"5C-C3-07"="Huawei";"60-DE-44"="Huawei";"70-72-CF"="Huawei"
    "78-1D-BA"="Huawei";"80-38-BC"="Huawei";"98-E7-F4"="Huawei";"A0-08-6F"="Huawei"
    "C8-51-95"="Huawei";"D4-12-43"="Huawei";"E8-CD-2D"="Huawei";"F4-63-1F"="Huawei"
    "04-C0-6F"="Huawei";"08-19-A6"="Huawei";"10-1B-54"="Huawei";"14-B9-68"="Huawei"
    "18-C5-8A"="Huawei";"20-08-ED"="Huawei";"24-69-A5"="Huawei";"2C-E8-75"="Huawei"
    "30-87-D9"="Huawei";"3C-47-11"="Huawei";"44-6A-B7"="Huawei";"48-DB-50"="Huawei"
    # NETGEAR
    "00-1A-4B"="NETGEAR";"00-1B-2F"="NETGEAR";"00-1E-2A"="NETGEAR";"00-22-3F"="NETGEAR"
    "00-24-B2"="NETGEAR";"20-4E-7F"="NETGEAR";"28-C6-8E"="NETGEAR";"2C-B0-5D"="NETGEAR"
    "6C-F0-49"="NETGEAR";"84-1B-5E"="NETGEAR";"9C-D3-6D"="NETGEAR";"A0-40-A0"="NETGEAR"
    "C0-3F-0E"="NETGEAR";"E0-91-F5"="NETGEAR";"E4-F4-C6"="NETGEAR";"10-DA-43"="NETGEAR"
    "30-46-9A"="NETGEAR";"6C-B0-CE"="NETGEAR";"80-37-73"="NETGEAR"
    # D-Link
    "00-0D-88"="D-Link";"00-11-95"="D-Link";"00-13-46"="D-Link";"00-15-E9"="D-Link"
    "00-17-9A"="D-Link";"00-19-5B"="D-Link";"00-1B-11"="D-Link";"00-1C-F0"="D-Link"
    "00-21-91"="D-Link";"00-22-B0"="D-Link";"00-24-01"="D-Link";"00-26-5A"="D-Link"
    "14-D6-4D"="D-Link";"1C-7E-E5"="D-Link";"28-10-7B"="D-Link";"34-08-04"="D-Link"
    "5C-D9-98"="D-Link";"78-54-2E"="D-Link";"90-94-E4"="D-Link";"B8-A3-86"="D-Link"
    "C8-BE-19"="D-Link";"CC-B2-55"="D-Link";"F0-7D-68"="D-Link";"FC-75-16"="D-Link"
    "18-0F-76"="D-Link";"20-E5-2A"="D-Link";"40-9B-CD"="D-Link"
    # Intel (NICs en laptops/PCs)
    "00-0E-35"="Intel";"00-16-EA"="Intel";"00-1B-21"="Intel";"00-1E-67"="Intel"
    "00-21-6A"="Intel";"00-22-FB"="Intel";"00-24-D7"="Intel"
    "A0-88-B4"="Intel";"A4-C3-F0"="Intel";"B8-CA-3A"="Intel";"C4-85-08"="Intel"
    "DC-53-60"="Intel";"E8-2A-EA"="Intel";"F8-34-41"="Intel";"7C-5C-F8"="Intel"
    "00-00-F0"="Intel";"00-02-B3"="Intel";"00-03-47"="Intel";"00-04-23"="Intel"
    "00-07-E9"="Intel";"00-0C-F1"="Intel";"00-0E-0C"="Intel";"00-12-F0"="Intel"
    "00-13-02"="Intel";"00-13-20"="Intel";"00-13-CE"="Intel";"00-15-00"="Intel"
    "00-16-76"="Intel";"00-19-D1"="Intel";"00-1C-C0"="Intel";"00-1D-E0"="Intel"
    "00-1F-3B"="Intel";"00-21-5C"="Intel";"00-23-14"="Intel";"00-23-AE"="Intel"
    ;"00-26-C6"="Intel";"00-27-10"="Intel";"04-0E-3C"="Intel"
    # Cisco / Linksys
    "00-14-BF"="Cisco/Linksys";"00-18-F8"="Cisco/Linksys";"00-1A-70"="Cisco"
    "00-1B-54"="Cisco";"00-1C-10"="Cisco";"00-22-BD"="Cisco";"00-23-BE"="Cisco"
    "00-25-2E"="Cisco";"0C-D9-96"="Cisco";"1C-E6-C7"="Cisco";"58-AC-78"="Cisco"
    "64-9E-F3"="Cisco";"84-78-AC"="Cisco";"98-90-96"="Cisco";"A4-6C-2A"="Cisco"
    "B4-14-89"="Cisco";"C8-00-84"="Cisco";"DC-8C-37"="Cisco";"F0-29-29"="Cisco"
    "00-02-16"="Cisco";"00-03-6B"="Cisco";"00-04-DD"="Cisco";"00-05-DC"="Cisco"
    "00-06-28"="Cisco";"00-07-0D"="Cisco";"00-08-A3"="Cisco";"00-09-12"="Cisco"
    "00-0A-8A"="Cisco";"00-0B-BE"="Cisco";"00-0C-85"="Cisco";"00-0D-29"="Cisco"
    "00-0E-D7"="Cisco";"00-0F-8F"="Cisco";"00-10-07"="Cisco";"00-10-79"="Cisco"
    "00-10-F6"="Cisco";"00-11-21"="Cisco";"00-12-00"="Cisco";"00-13-19"="Cisco"
    # Google (Chromecast, Nest, Pixel, Home)
    "00-1A-11"="Google";"08-9E-08"="Google";"20-DF-B9"="Google";"3C-5A-B4"="Google"
    "48-D6-D5"="Google";"54-60-09"="Google";"6C-AD-F8"="Google";"A4-77-33"="Google"
    "AC-67-B2"="Google";"F4-F5-D8"="Google";"58-CB-52"="Google";"D8-EB-97"="Google"
    "1C-F2-9A"="Google";"30-FD-38"="Google";"38-8B-59"="Google";"4C-BC-98"="Google"
    "54-52-00"="Google";"7C-1E-06"="Google";"9C-9D-7E"="Google"
    # Amazon (Alexa, Echo, Fire TV, Kindle)
    "00-BB-3A"="Amazon";"18-74-2E"="Amazon";"34-D2-70"="Amazon";"40-B4-CD"="Amazon"
    "44-65-0D"="Amazon";"50-DC-E7"="Amazon";"68-37-E9"="Amazon";"78-E1-03"="Amazon"
    "84-D6-D0"="Amazon";"A0-02-DC"="Amazon";"B4-7C-59"="Amazon";"F0-27-2D"="Amazon"
    "0C-47-C9"="Amazon";"10-AE-60"="Amazon";"28-EF-01"="Amazon"
    ;"40-4E-36"="Amazon";"50-F5-DA"="Amazon"
    "74-75-48"="Amazon";"FC-A1-83"="Amazon"
    # Microsoft (Surface, Xbox, HoloLens)
    "00-03-FF"="Microsoft";"00-15-5D"="Hyper-V";"00-1D-D8"="Microsoft"
    "28-18-78"="Microsoft";"48-50-73"="Microsoft";"7C-1E-52"="Microsoft"
    "DC-B4-C4"="Microsoft";"98-5F-D3"="Microsoft";"60-45-BD"="Microsoft"
    "00-50-F2"="Microsoft";"70-77-81"="Microsoft"
    # Raspberry Pi Foundation
    "28-CD-C1"="Raspberry Pi";"B8-27-EB"="Raspberry Pi"
    "DC-A6-32"="Raspberry Pi";"E4-5F-01"="Raspberry Pi"
    # Ubiquiti (UniFi, AmpliFi, EdgeRouter)
    "00-15-6D"="Ubiquiti";"00-27-22"="Ubiquiti";"04-18-D6"="Ubiquiti"
    "24-A4-3C"="Ubiquiti";"44-D9-E7"="Ubiquiti";"68-72-51"="Ubiquiti"
    "74-83-C2"="Ubiquiti";"78-8A-20"="Ubiquiti";"80-2A-A8"="Ubiquiti"
    "DC-9F-DB"="Ubiquiti";"F0-9F-C2"="Ubiquiti";"18-E8-29"="Ubiquiti"
    # Virtualizacion
    "00-0C-29"="VMware";"00-50-56"="VMware";"00-05-69"="VMware"
    "08-00-27"="VirtualBox";"52-54-00"="QEMU/KVM"
    # Realtek (chips de red genericos en placas base)
    "00-E0-4C"="Realtek";"00-01-6C"="Realtek";"52-54-AB"="Realtek"
    # Otros fabricantes de red comunes
    "00-10-18"="Broadcom";"00-10-4A"="3Com";"00-60-08"="3Com";"00-00-F4"="Allied Telesis"
    "00-00-0C"="Cisco";"00-AA-00"="Intel";"02-00-4C"="Hyper-V"
}
# ================================================================
#  DATOS DE LAS PANTALLAS DE INFORMACION POR MODULO
# ================================================================
$script:Info = @{
    "A" = @{
        Titulo = "LAN Port Audit"
        Color  = "Cyan"
        Desc   = @(
            "Tests TCP connection to the most relevant ports of the router",
            "using TcpClient with a 1-second timeout per port. Much",
            "faster than Test-NetConnection because it does not wait for ICMP.",
            "Puertos base: 21, 22, 23, 80, 443, 8080, 8443, 8888, 9090.",
            "You can add additional ports at the start of the scan."
        )
        Prec   = @(
            "Some routers with IDS/IPS log the scan in their logs.",
            "  Harmless, but may appear as 'suspicious activity'.",
            "Do not run against any IP other than your own gateway.",
            "False negatives possible if the router uses DROP instead of REJECT."
        )
        Recs   = @(
            "Run A before C to find out if the panel uses HTTP or HTTPS.",
            "Combine with module H to find out if those ports are on WAN.",
            "Si el puerto 23 (Telnet) aparece abierto, cerrarlo es urgente:",
            "  Router panel -> Administration -> disable Telnet."
        )
        Ejem   = @(
            "Router panel inaccessible: check whether 80 or 443 respond.",
            "  If both are closed, the admin panel is OFF.",
            "Router slow with no apparent reason: open Telnet may indicate",
            "  acceso remoto activo no autorizado drenando recursos."
        )
    }
    "B" = @{
        Titulo = "Device Scan + Duplicate IP Detection"
        Color  = "Cyan"
        Desc   = @(
            "Pings the entire subnet (.1 to .254) and logs every",
            "device that responds. Shows IP, MAC, DNS name and",
            "manufacturer. Detects IP conflicts (same MAC, different IP)",
            "which can cause random connection drops."
        )
        Prec   = @(
            "Scanning 254 hosts may take between 30 and 90 seconds.",
            "Devices with firewall active may not respond to ping",
            "  aunque esten conectados (falsos negativos esperables).",
            "DNS name may appear as 'Hidden' on many devices."
        )
        Recs   = @(
            "Run when the client reports 'someone got into my WiFi'",
            "  or when there are random network drops with no apparent reason.",
            "Combine with module N (comparison) to see changes over time.",
            "Use module J to see manufacturers grouped."
        )
        Ejem   = @(
            "Two devices with the same IP cause random disconnections:",
            "  the scan will show an IP conflict alert.",
            "Device with unknown MAC in the list: could be an",
            "  intruder - investigate with module J."
        )
    }
    "C" = @{
        Titulo = "Open Router Panel (automatic HTTP/S detection)"
        Color  = "Cyan"
        Desc   = @(
            "Detects whether the router accepts HTTPS (port 443) or HTTP (port 80)",
            "before opening the browser, and use the correct protocol.",
            "Avoids the typical error of typing http:// on a router that only",
            "responds on https:// or vice versa."
        )
        Prec   = @(
            "Some routers with CSRF protection block access from",
            "  direct links. In that case, open the browser manually.",
            "La advertencia 'Connection no segura' en HTTPS es completamente",
            "  normal on local networks (self-signed certificate)."
        )
        Recs   = @(
            "First run module A to confirm that at least one",
            "  of the ports (80 or 443) is active.",
            "Common default credentials: admin/admin, admin/1234,",
            "  admin/(blank). Check the label under the router."
        )
        Ejem   = @(
            "Quick support: access the panel without remembering whether it's http or https.",
            "Router with HTTPS enabled: module C opens directly",
            "  the secure version to avoid the browser warning."
        )
    }
    "D" = @{
        Titulo = "Latency and Stability Diagnostics"
        Color  = "Yellow"
        Desc   = @(
            "Sends 10 pings to three targets: the router (LAN), Cloudflare",
            "(1.1.1.1) and Google (8.8.8.8). Calculates min, max and mean.",
            "Automatically identifies whether the problem is in the local network",
            "or in the Internet provider (ISP)."
        )
        Prec   = @(
            "Internet pings can be blocked with VPN active,",
            "  giving false negatives at WAN targets.",
            "On corporate networks some firewalls block ICMP.",
            "A single test is not representative: run at different times."
        )
        Recs   = @(
            "Router latency > 20ms = problem on local network (WiFi, cable).",
            "Internet latency > 100ms = likely ISP issue.",
            "Packet loss > 30% = severe failure requiring attention.",
            "Compare results at peak vs off-peak hours."
        )
        Ejem   = @(
            "Client reports 'Internet slow': if router ping is high",
            "  the problem is the LAN. If the router responds well but 1.1.1.1",
            "  fails, call the ISP with the test data as evidence.",
            "Video calls dropping: look for packet loss > 5%."
        )
    }
    "E" = @{
        Titulo = "Full Network Adapter Information"
        Color  = "White"
        Desc   = @(
            "Shows all data of the active network adapter: name,",
            "description, status, link speed, own MAC, local IP,",
            "netmask (/XX notation), gateway and DNS",
            "servers configured."
        )
        Prec   = @(
            "If there are multiple adapters (VPN active + physical adapter),",
            "  shows the one associated with the most optimal default route.",
            "Speed may appear as N/A on virtual WiFi adapters."
        )
        Recs   = @(
            "Always run as the first module in any diagnostic.",
            "IP at 169.254.x.x (APIPA): DHCP is not responding.",
            "DNS at 127.0.0.1: a local service is acting as DNS",
            "  (Pi-hole, VPN, DNSCrypt). May be intentional or not."
        )
        Ejem   = @(
            "PC without Internet but with correct IP: check whether the gateway",
            "  is the router's or one wrongly assigned by mistake.",
            "Machine at 10Mbps speed on Gigabit network: cable or port",
            "  of the switch in half-duplex mode or deteriorated."
        )
    }
    "F" = @{
        Titulo = "DNS Resolution Test"
        Color  = "White"
        Desc   = @(
            "Resolves 5 known domains (Google, Cloudflare, Microsoft,",
            "Amazon, YouTube) measuring response time in ms.",
            "Alerts if any domain takes more than 500ms or fails.",
            "Diagnoses whether the 'websites not loading' issue is DNS."
        )
        Prec   = @(
            "If the computer uses local DNS (Pi-hole, AdGuard), latency",
            "  can be higher without that being a problem.",
            "Total failures with working ping = router DNS down."
        )
        Recs   = @(
            "If all domains fail but ping to 8.8.8.8 works,",
            "  DNS is down. Quick fix: change DNS to 1.1.1.1",
            "  in the network configuration of the computer or router.",
            "Times > 200ms consistently: switch to public DNS."
        )
        Ejem   = @(
            "Slow websites but fast downloads: DNS is taking too long",
            "  to resolve. Switching to 1.1.1.1 usually fixes the problem.",
            "Some websites don't open: selective resolution failing,",
            "  possible blocklist or corrupted DNS cache on the router."
        )
    }
    "H" = @{
        Titulo = "Detection of Dangerous Ports Exposed on Internet (WAN)"
        Color  = "Red"
        Desc   = @(
            "Gets your public IP via api.ipify.org and scans from Internet",
            "the most dangerous ports: 21 (FTP), 22 (SSH), 23 (Telnet),",
            "80 (HTTP), 443 (HTTPS), 3389 (RDP) and 8080 (HTTP-Alt).",
            "Detects whether your router is exposed to external attacks."
        )
        Prec   = @(
            "Some ISPs use CG-NAT: the result may not reflect",
            "  the real exposure of the router (shared IPs).",
            "Networks with hairpin NAT may report ports as closed.",
            "ONLY scan your own network. Never use against third-party IPs."
        )
        Recs   = @(
            "Puerto 23 o 3389 abiertos desde Internet: URGENTE cerrarlos.",
            "  Router panel -> Remote administration -> disable.",
            "Puerto 22 abierto: cambiar SSH a un puerto no estandar",
            "  and enable key-based authentication, not password-based."
        )
        Ejem   = @(
            "Router recibiendo ataques de fuerza bruta: puertos 22 o 23",
            "  open in WAN are the vector. Closing them stops the attack.",
            "Client with slow Internet at night: port 23 open",
            "  may indicate the router is being used as a proxy."
        )
    }
    "J" = @{
        Titulo = "Manufacturer Identification by MAC Prefix (OUI)"
        Color  = "White"
        Desc   = @(
            "Scans the network and cross-references each MAC with a local table of 200+",
            "OUI prefixes to identify the manufacturer of the network chip.",
            "Shows results grouped by manufacturer to make easier",
            "la identificacion de devices desconocidos.",
            "Does not require Internet: the table is embedded."
        )
        Prec   = @(
            "OUI identifies the manufacturer of the network CHIP, not the device.",
            "  A Xiaomi router can use an Intel or Realtek chip.",
            "MACs aleatorizadas (Android 10+, iOS 14+, Windows 10 reciente)",
            "  may appear as 'Unknown' or with incorrect manufacturer.",
            "The table covers the most common ones but is not exhaustive."
        )
        Recs   = @(
            "Cuando aparece un fabricante inesperado (Raspberry Pi, Amazon,",
            "  QEMU) in a client's home, investigate that device.",
            "If several devices show the same manufacturer (Intel),",
            "  they are likely laptops or PCs with integrated NIC."
        )
        Ejem   = @(
            "If 'Raspberry Pi' appears on the client network: someone installed",
            "  a mini-PC, possibly a server or a network relay.",
            "Aparece 'Amazon': es un Echo, Fire TV, Kindle o Ring.",
            "If 'VMware'/'QEMU' appears: a virtual machine is on the network."
        )
    }
    "L" = @{
        Titulo = "Router Firmware Version Detection"
        Color  = "DarkYellow"
        Desc   = @(
            "Tries to access without authentication well-known paths of pages",
            "firmware information in TP-Link, ASUS, D-Link, Movistar",
            "and generic routers. Extracts the version if it finds it.",
            "Works on approximately 60-70% of home routers."
        )
        Prec   = @(
            "Some routers require login to show the version.",
            "  In that case, use module C to access the panel.",
            "Result may vary depending on manufacturer configuration.",
            "Does not change anything on the router: read-only."
        )
        Recs   = @(
            "If you find the version, compare with the one available on the web",
            "  from the manufacturer. More than 1 year without updates = risk.",
            "TP-Link and ASUS usually expose the version without authentication.",
            "When in doubt, access the panel manually (module C)."
        )
        Ejem   = @(
            "Router with 2019 firmware in 2024: likely vulnerable",
            "  to public CVEs. Recommend update to the client.",
            "Version not found: the router requires login or is not supported",
            "  with known routes. Use module C manually."
        )
    }
    "M" = @{
        Titulo = "Automatic Full Report (A + E + F + D)"
        Color  = "Green"
        Desc   = @(
            "Automatically runs modules A, E, F and D in sequence",
            "without user interaction. When done it generates a single",
            "consolidated TXT file with date and time on the Desktop.",
            "Ideal for the start or end of a tech support visit."
        )
        Prec   = @(
            "Full execution takes between 2 and 5 minutes.",
            "  Do not close the window mid-process.",
            "Requires active network connection for all modules.",
            "The TXT file is overwritten if one from the same second already exists."
        )
        Recs   = @(
            "Run at the start of the visit to have a baseline.",
            "Run at the end to document the state after changes.",
            "Email the TXT to the client as a record of the visit.",
            "To run without interaction from a .bat: AuditoriaRouter.ps1 -Auto"
        )
        Ejem   = @(
            "Mantenimiento preventivo mensual: lanzar M, esperar, adjuntar",
            "  the TXT to the support ticket as evidence of state.",
            "Scheduled task: configure in the Windows Task Scheduler",
            "  Windows with the -Auto parameter for nightly execution."
        )
    }
    "N" = @{
        Titulo = "Device Comparison (Before / Now)"
        Color  = "Magenta"
        Desc   = @(
            "Scans the current network and compares with the last scan",
            "saved on disk. Shows new devices in green",
            "and in red the ones that have disappeared. Devices without",
            "changes are shown in gray."
        )
        Prec   = @(
            "Saved state persists across sessions in a temp folder.",
            "  Si se limpia %TEMP%, el historial se pierde.",
            "Powered-off devices may appear as 'missing'",
            "  even if they still belong to the network."
        )
        Recs   = @(
            "On first client visit: run to save baseline state.",
            "On subsequent visits: run to detect new devices.",
            "If a new unexpected device appears: cross-reference with module J",
            "  to identify the manufacturer."
        )
        Ejem   = @(
            "Client says 'someone connected to my WiFi': compare with the",
            "  previous scan to see exactly which device is new.",
            "After changing WiFi password: verify there are no leftover",
            "  devices from the previous scan that should not be there."
        )
    }
    "P" = @{
        Titulo = "Download Speed Test"
        Color  = "Yellow"
        Desc   = @(
            "Downloads a ~5MB file from Cloudflare servers",
            "and measures actual download speed in MB/s and Mbps.",
            "No depende de aplicaciones externas ni de Speedtest.net.",
            "Provides a quick estimate with no installation."
        )
        Prec   = @(
            "Result may vary with server load and time of day.",
            "  Run several times to get a representative average.",
            "Measures the computer speed, not the router: other devices",
            "  on the network consuming bandwidth will affect the result.",
            "Requiere acceso a Internet (cloudflare.com)."
        )
        Recs   = @(
            "Compare the result with the speed contracted with the ISP.",
            "  Regla practica: se espera al menos el 70% de la velocidad",
            "  contracted under normal conditions.",
            "Run on both WiFi and cable to compare differences."
        )
        Ejem   = @(
            "Client with 300 Mbps contracted getting 5 Mbps: possible",
            "  Misconfigured QoS, ISP throttling or saturated router.",
            "Diferencia grande entre WiFi y cable: problema de cobertura o",
            "  interference on the WiFi channel. Recommendation: change channel."
        )
    }
    "Q" = @{
        Titulo = "Captive Portal Detection"
        Color  = "DarkYellow"
        Desc   = @(
            "Makes an HTTP request to connectivitycheck.gstatic.com/generate_204.",
            "If it returns HTTP 204: clean connection to Internet.",
            "Si devuelve HTTP 200 o redirige: hay un portal cautivo activo",
            "which requires acceptance before browsing (hotels, airports)."
        )
        Prec   = @(
            "On very restrictive networks it may give false positives.",
            "  Verify manually by opening the browser if in doubt.",
            "Some parental control systems or content filters",
            "  may intercept the request and give a false positive."
        )
        Recs   = @(
            "Run when 'WiFi is connected but websites don't load'.",
            "  Classic symptom of an unaccepted captive portal.",
            "Solution: open any HTTP URL (without S) in the browser.",
            "  Ejemplo: http://neverssl.com redirige siempre al portal."
        )
        Ejem   = @(
            "Hotel WiFi: ping works, DNS resolves, but websites don't open.",
            "  Captive portal without accepting terms. Open browser.",
            "Red corporativa nueva: portal de registro de devices activo.",
            "  The client IT must approve the computer MAC."
        )
    }
}

# ================================================================
#  FUNCIONES UTILITARIAS BASE
# ================================================================

function Escribir-Centrado {
    param([string]$Texto, [ConsoleColor]$Color = "Gray")
    $W = $Host.UI.RawUI.WindowSize.Width
    if ($Texto.Length -lt $W) {
        $Esp = [Math]::Floor(($W - $Texto.Length) / 2)
        Write-Host (" " * $Esp + $Texto) -ForegroundColor $Color
    } else {
        Write-Host $Texto -ForegroundColor $Color
    }
}

function Obtener-Router {
    $Routes = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
              Sort-Object RouteMetric
    foreach ($R in $Routes) {
        $A = Get-NetAdapter -InterfaceIndex $R.InterfaceIndex -ErrorAction SilentlyContinue
        if ($A -and $A.InterfaceDescription -notmatch "VPN|TAP|Tunnel|WireGuard|OpenVPN|PPP|Loopback|Virtual") {
            return @{ Gateway = $R.NextHop; InterfaceIndex = $R.InterfaceIndex }
        }
    }
    $F = $Routes | Select-Object -First 1
    if ($F) { return @{ Gateway = $F.NextHop; InterfaceIndex = $F.InterfaceIndex } }
    return $null
}

function Obtener-SubredBase {
    param([string]$Gateway, [int]$InterfaceIndex)
    $C = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 `
         -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($C -and $C.PrefixLength -ge 24) {
        $O = $C.IPAddress.Split('.')
        return "$($O[0]).$($O[1]).$($O[2])"
    }
    return $Gateway.Substring(0, $Gateway.LastIndexOf('.'))
}

function Test-Puerto {
    param([string]$Destino, [int]$Puerto, [int]$TimeoutMs = 1000)
    try {
        $tcp   = New-Object System.Net.Sockets.TcpClient
        $async = $tcp.BeginConnect($Destino, $Puerto, $null, $null)
        $ok    = $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if ($ok -and $tcp.Connected) { $tcp.EndConnect($async) | Out-Null; $tcp.Close(); return $true }
        $tcp.Close()
    } catch { }
    return $false
}

function Get-MACDesdeARP {
    param([string]$IP)
    try {
        foreach ($L in (arp -a $IP 2>$null)) {
            if ($L -match [regex]::Escape($IP) -and
                $L -match '([0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2})') {
                $M = $Matches[1].ToUpper()
                if ($M -ne "FF-FF-FF-FF-FF-FF" -and $M -ne "00-00-00-00-00-00") { return $M }
            }
        }
    } catch { }
    return "Desconocida"
}

function Get-Fabricante {
    param([string]$MAC)
    if ($MAC -eq "Desconocida") { return "Desconocido" }
    $Prefijo = ($MAC -replace ":", "-").ToUpper().Substring(0, 8)
    if ($script:OUI.ContainsKey($Prefijo)) { return $script:OUI[$Prefijo] }
    return "Desconocido"
}

function Exportar-Informe {
    param([string[]]$Contenido, [string]$NombreModulo)
    $Fecha      = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $Desktop = [Environment]::GetFolderPath("Desktop")
    $Archivo    = "$Desktop\AtlasRed_${NombreModulo}_${Fecha}.txt"
    $Contenido | Out-File -FilePath $Archivo -Encoding UTF8
    Write-Host "  Informe saved: $Archivo" -ForegroundColor Green
    return $Archivo
}

# ================================================================
#  PANTALLA DE INFORMACION DEL MODULO
#  Retorna $true to continue, $false para cancelar
# ================================================================
function Mostrar-InfoModulo {
    param([string]$Letra)

    if (-not $script:MostrarInfo -or $script:ModoAuto) { return $true }

    $D = $script:Info[$Letra]
    if (-not $D) { return $true }

    Clear-Host
    $Sep = "-" * 64

    Write-Host ""
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host ("  [ $Letra ]  " + $D.Titulo.ToUpper()) -ForegroundColor $D.Color
    Write-Host "  $Sep" -ForegroundColor DarkGray

    Write-Host "`n  QUE HACE" -ForegroundColor Yellow
    foreach ($L in $D.Desc)  { Write-Host "    $L" -ForegroundColor Gray }

    Write-Host "`n  PRECAUCIONES" -ForegroundColor DarkYellow
    foreach ($L in $D.Prec)  { Write-Host "    $L" -ForegroundColor Gray }

    Write-Host "`n  RECOMENDACIONES" -ForegroundColor Cyan
    foreach ($L in $D.Recs)  { Write-Host "    $L" -ForegroundColor Gray }

    Write-Host "`n  EJEMPLOS DE USO" -ForegroundColor Green
    foreach ($L in $D.Ejem)  { Write-Host "    $L" -ForegroundColor Gray }

    Write-Host ""
    Write-Host "  $Sep" -ForegroundColor DarkGray
    Write-Host "  Y = continue    N = cancel    X = do not show info in the future" -ForegroundColor DarkGray
    Write-Host "  $Sep" -ForegroundColor DarkGray
    $R = Read-Host "  Tu eleccion"

    if ($R.ToUpper() -eq "X") { $script:MostrarInfo = $false; return $true }
    if ($R.ToUpper() -eq "N") { return $false }
    return $true
}

function Esperar-Enter {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not $script:ModoAuto) {
        $msg = "`n  Press ENTER to go back to menu..."
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $msg
            return
        }
        Read-Host $msg
    }
}

# ================================================================
#  MODULO A - AUDITORIA DE PUERTOS LAN
# ================================================================
function Modulo-Auditoria {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "A")) { return @() }

    Clear-Host
    Write-Host ""
    Write-Host "  [ A ]  AUDITORIA DE PUERTOS LAN" -ForegroundColor Cyan
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return @() }
    $GW = $RI.Gateway
    Write-Host "`n  Router detectado: $GW" -ForegroundColor White

    $Base = @(21, 22, 23, 80, 443, 8080, 8443, 8888, 9090)
    Write-Host "  Puertos base    : $($Base -join ', ')" -ForegroundColor DarkGray

    $Extra = ""
    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Extra = Read-Host "`n  Additional ports separated by comma (or ENTER to skip)"
    }

    $Puertos = $Base
    if ($Extra.Trim() -ne "") {
        $Add = $Extra -split ',' | ForEach-Object { $_.Trim() } |
               Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
        $Puertos = ($Puertos + $Add) | Sort-Object -Unique
    }

    Write-Host "`n  Scanning $($Puertos.Count) puertos en $GW...`n" -ForegroundColor DarkGray

    $Leyendas = @{
        21 = "FTP         Transferencia de archivos. INSEGURO si expuesto."
        22 = "SSH         Encrypted CLI access. Normal on managed routers."
        23 = "Telnet      Plain text, no encryption. VERY DANGEROUS if open."
        80 = "HTTP        Router panel via local network."
        443= "HTTPS       Secure router panel via local network."
        8080="HTTP-Alt    Secondary panel in many routers."
        8443="HTTPS-Alt   Panel HTTPS secundario."
        8888="Common Alt  Present in some modern routers."
        9090="Admin-Alt   Puerto de administracion alternativo."
        3389="RDP         Desktop remoto Windows. CRITICO si abierto."
    }

    $Log      = @("=== AUDITORIA DE PUERTOS LAN === $(Get-Date)", "Router: $GW", "")
    $Abiertos = @()

    foreach ($P in $Puertos) {
        $Ok = Test-Puerto -Destino $GW -Puerto $P -TimeoutMs 1000
        if ($Ok) {
            Write-Host "  [ABIERTO]  Puerto $P" -ForegroundColor Red
            $Log += "  [ABIERTO]  Puerto $P"
            $Abiertos += $P
        } else {
            Write-Host "  [cerrado]  Puerto $P" -ForegroundColor DarkGreen
            $Log += "  [cerrado]  Puerto $P"
        }
    }

    Write-Host "`n  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "  LEYENDA DE PUERTOS" -ForegroundColor Cyan
    foreach ($P in $Puertos) {
        if ($Leyendas.ContainsKey($P)) { Write-Host "    [$P]  $($Leyendas[$P])" -ForegroundColor Gray }
    }
    Write-Host "`n  NOTE: Open ports on LAN are normal. The real risk is" -ForegroundColor DarkGray
    Write-Host "        if they appear open from Internet. Use module H." -ForegroundColor DarkGray

    $script:HistorialSesion.Add("[A] Auditoria $GW | Abiertos: $(if ($Abiertos.Count) { $Abiertos -join ',' } else { 'None' })")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Auditoria" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
    return $Log
}

# ================================================================
#  MODULO B - ESCANEO DE DISPOSITIVOS + DETECCION IPs DUPLICADAS (K)
# ================================================================
function Modulo-Escaneo {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "B")) { return @() }

    Clear-Host
    Write-Host ""
    Write-Host "  [ B ]  ESCANEO DE DISPOSITIVOS" -ForegroundColor Cyan
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return @() }
    $GW  = $RI.Gateway
    $Sub = Obtener-SubredBase -Gateway $GW -InterfaceIndex $RI.InterfaceIndex

    Write-Host "`n  Subred: ${Sub}.1 - ${Sub}.254" -ForegroundColor White
    Write-Host "  This may take up to 90 seconds. Please wait.`n" -ForegroundColor DarkGray

    $Ping        = New-Object System.Net.NetworkInformation.Ping
    $Encontrados = [System.Collections.Generic.List[hashtable]]::new()
    $MACVisto    = @{}
    $Log         = @("=== ESCANEO DE DISPOSITIVOS === $(Get-Date)", "Subred: ${Sub}.x", "")

    for ($i = 1; $i -le 254; $i++) {
        $IP = "$Sub.$i"
        try {
            if ($Ping.Send($IP, 150).Status -eq 'Success') {

                $Host_ = "Oculto"
                try { $H = [System.Net.Dns]::GetHostEntry($IP); if ($H.HostName) { $Host_ = $H.HostName } } catch { }

                $null = arp -a 2>$null
                Start-Sleep -Milliseconds 80
                $MAC  = Get-MACDesdeARP -IP $IP
                $Fab  = Get-Fabricante -MAC $MAC

                # Modulo K: deteccion de conflicto de IP
                $Conflicto = ""
                if ($MAC -ne "Desconocida") {
                    if ($MACVisto.ContainsKey($MAC)) {
                        $Conflicto = "  [!!! CONFLICTO: misma MAC que $($MACVisto[$MAC])]"
                    } else {
                        $MACVisto[$MAC] = $IP
                    }
                }

                $Entrada = @{ IP = $IP; MAC = $MAC; Host = $Host_; Fab = $Fab }
                $Encontrados.Add($Entrada)

                if ($IP -eq $GW) {
                    Write-Host "  [ROUTER]   $IP  $MAC  $Fab" -ForegroundColor Green
                    $Log += "  [ROUTER]   $IP | $MAC | $Fab"
                } elseif ($Conflicto) {
                    Write-Host "  [CONFLICTO]$IP  $MAC  $Fab$Conflicto" -ForegroundColor Red
                    $Log += "  [CONFLICTO]$IP | $MAC | $Fab$Conflicto"
                } else {
                    Write-Host "  [disp]     $IP  $MAC  $Fab  |  $Host_" -ForegroundColor Cyan
                    $Log += "  [disp]     $IP | $MAC | $Fab | $Host_"
                }
            }
        } catch { }
    }

    Write-Host "`n  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "  Total found: $($Encontrados.Count) devices" -ForegroundColor Yellow
    if ($MACVisto.Count -lt ($Encontrados | Where-Object { $_.MAC -ne "Desconocida" } | Measure-Object).Count) {
        Write-Host "  WARNING: IP conflicts detected. See lines marked [CONFLICT]." -ForegroundColor Red
    }

    # Guardar estado para modulo N
    try {
        $Lineas = $Encontrados | ForEach-Object { "$($_.IP)|$($_.MAC)|$($_.Host)" }
        $Lineas | Out-File $script:ArchivoEstado -Encoding UTF8 -Force
        Write-Host "  State saved for comparison (module N)." -ForegroundColor DarkGray
    } catch { }

    $script:HistorialSesion.Add("[B] Escaneo ${Sub}.x | $($Encontrados.Count) devices")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Escaneo" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
    return $Log
}

# ================================================================
#  MODULO C - PANEL DEL ROUTER
# ================================================================
function Modulo-Panel {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "C")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ C ]  PANEL DEL ROUTER" -ForegroundColor Cyan
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return }
    $GW = $RI.Gateway

    Write-Host "`n  Detecting protocolo en $GW..." -ForegroundColor DarkGray
    $URL = $null
    if (Test-Puerto -Destino $GW -Puerto 443 -TimeoutMs 1500) {
        $URL = "https://$GW"
        Write-Host "  Puerto 443 disponible  ->  usando HTTPS" -ForegroundColor Green
    } elseif (Test-Puerto -Destino $GW -Puerto 80 -TimeoutMs 1500) {
        $URL = "http://$GW"
        Write-Host "  Puerto 80 disponible   ->  usando HTTP" -ForegroundColor Yellow
    } else {
        $URL = "http://$GW"
        Write-Host "  Ningun puerto confirmo response. Intentando HTTP..." -ForegroundColor DarkGray
    }

    Write-Host "`n  Abriendo: $URL" -ForegroundColor White
    Write-Host "  If browser shows 'Site not secure', that is normal on LAN." -ForegroundColor DarkGray
    Write-Host "  Credenciales habituales: admin / admin  |  admin / 1234  |  admin / (vacio)" -ForegroundColor DarkGray

    try { Start-Process $URL } catch { Write-Host "  Error al abrir el navegador." -ForegroundColor Red }

    $script:HistorialSesion.Add("[C] Panel abierto: $URL")
    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO D - DIAGNOSTICO DE LATENCIA
# ================================================================
function Modulo-Latencia {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "D")) { return @() }

    Clear-Host
    Write-Host ""
    Write-Host "  [ D ]  DIAGNOSTICO DE LATENCIA" -ForegroundColor Yellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return @() }
    $GW = $RI.Gateway

    $Objetivos = @(
        @{ N = "Router   (LAN)    "; IP = $GW       },
        @{ N = "Cloudflare (WAN)  "; IP = "1.1.1.1" },
        @{ N = "Google     (WAN)  "; IP = "8.8.8.8" }
    )

    $Log = @("=== DIAGNOSTICO DE LATENCIA === $(Get-Date)", "Router: $GW", "")
    $PO  = New-Object System.Net.NetworkInformation.Ping
    $N   = 10

    foreach ($Obj in $Objetivos) {
        Write-Host "`n  $($Obj.N.Trim()) ($($Obj.IP))  -  $N pings" -ForegroundColor Cyan
        $T = @(); $F = 0
        for ($p = 1; $p -le $N; $p++) {
            try {
                $R = $PO.Send($Obj.IP, 2000)
                if ($R.Status -eq 'Success') {
                    $T += $R.RoundtripTime
                    Write-Host "    Ping $p : $($R.RoundtripTime) ms" -ForegroundColor DarkGray
                } else { $F++; Write-Host "    Ping $p : TIMEOUT" -ForegroundColor DarkRed }
            } catch { $F++; Write-Host "    Ping $p : ERROR" -ForegroundColor DarkRed }
            Start-Sleep -Milliseconds 200
        }
        if ($T.Count -gt 0) {
            $Min = ($T | Measure-Object -Minimum).Minimum
            $Max = ($T | Measure-Object -Maximum).Maximum
            $Avg = [Math]::Round(($T | Measure-Object -Average).Average, 1)
            $Res = "Min:${Min}ms  Max:${Max}ms  Media:${Avg}ms  Perdidos:$F/$N"
            Write-Host "  RESULTADO  $Res" -ForegroundColor Yellow
            $Log += "  $($Obj.N.Trim()): $Res"
            if ($Obj.IP -eq $GW     -and $Avg -gt 20)  { Write-Host "  WARNING: High router latency. Possible LAN congestion or weak WiFi." -ForegroundColor Red }
            if ($Obj.IP -ne $GW     -and $Avg -gt 100) { Write-Host "  WARNING: High Internet latency. Possible ISP issue." -ForegroundColor Red }
            if ($F -gt ($N / 2))                        { Write-Host "  WARNING: Over half of pings were lost. Severe failure." -ForegroundColor Red }
        } else {
            Write-Host "  Sin responses. Destino inaccesible." -ForegroundColor Red
            $Log += "  $($Obj.N.Trim()): SIN RESPUESTA"
        }
    }

    $script:HistorialSesion.Add("[D] Diagnostico de latencia completed")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Latencia" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
    return $Log
}

# ================================================================
#  MODULO E - INFO DEL ADAPTADOR
# ================================================================
function Modulo-InfoAdaptador {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "E")) { return @() }

    Clear-Host
    Write-Host ""
    Write-Host "  [ E ]  INFORMACION DEL ADAPTADOR DE RED" -ForegroundColor White
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return @() }
    $GW = $RI.Gateway
    $II = $RI.InterfaceIndex

    $A   = Get-NetAdapter -InterfaceIndex $II -ErrorAction SilentlyContinue
    $IP  = Get-NetIPAddress -InterfaceIndex $II -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
    $DNS = Get-DnsClientServerAddress -InterfaceIndex $II -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $EC  = if ($A.Status -eq 'Up') { 'Green' } else { 'Red' }

    Write-Host ""
    Write-Host "  ADAPTADOR ACTIVO" -ForegroundColor Cyan
    Write-Host "  Nombre         : $($A.Name)"
    Write-Host "  Descripcion    : $($A.InterfaceDescription)"
    Write-Host "  Estado         : $($A.Status)" -ForegroundColor $EC
    Write-Host "  Velocidad      : $(if ($A.LinkSpeed) { $A.LinkSpeed } else { 'N/A' })"
    Write-Host "  MAC propia     : $($A.MacAddress)" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "  IP CONFIGURATION" -ForegroundColor Cyan
    $IPColor = if ($IP.IPAddress -match "^169\.254") { "Red" } else { "Yellow" }
    Write-Host "  IP Local       : $($IP.IPAddress)" -ForegroundColor $IPColor
    if ($IP.IPAddress -match "^169\.254") {
        Write-Host "  WARNING: APIPA IP (169.254.x.x). DHCP is not responding." -ForegroundColor Red
    }
    Write-Host "  Mascara de red : /$($IP.PrefixLength)"
    Write-Host "  Puerta enlace  : $GW"

    Write-Host ""
    Write-Host "  SERVIDORES DNS" -ForegroundColor Cyan
    if ($DNS -and $DNS.ServerAddresses.Count -gt 0) {
        foreach ($S in $DNS.ServerAddresses) {
            $DNSColor = "White"
            $DNSNota  = ""
            if ($S -eq "127.0.0.1")  { $DNSColor = "Yellow"; $DNSNota = "  (DNS local activo: Pi-hole, VPN o DNSCrypt)" }
            if ($S -eq "1.1.1.1")    { $DNSNota = "  (Cloudflare)" }
            if ($S -eq "8.8.8.8")    { $DNSNota = "  (Google)" }
            if ($S -eq "9.9.9.9")    { $DNSNota = "  (Quad9)" }
            if ($S -eq "208.67.222.222") { $DNSNota = "  (OpenDNS)" }
            Write-Host "  -> $S$DNSNota" -ForegroundColor $DNSColor
        }
    } else { Write-Host "  No se encontraron DNS configurados." -ForegroundColor DarkGray }

    $Log = @(
        "=== INFO ADAPTADOR === $(Get-Date)",
        "Nombre    : $($A.Name)  |  $($A.InterfaceDescription)",
        "Estado    : $($A.Status)  |  Velocidad: $($A.LinkSpeed)",
        "MAC       : $($A.MacAddress)",
        "IP        : $($IP.IPAddress)/$($IP.PrefixLength)",
        "Gateway   : $GW",
        "DNS       : $($DNS.ServerAddresses -join ', ')"
    )

    $script:HistorialSesion.Add("[E] Adaptador: $($A.Name) | IP: $($IP.IPAddress) | GW: $GW")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Adaptador" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
    return $Log
}

# ================================================================
#  MODULO F - TEST DNS
# ================================================================
function Modulo-TestDNS {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "F")) { return @() }

    Clear-Host
    Write-Host ""
    Write-Host "  [ F ]  TEST DE RESOLUCION DNS" -ForegroundColor White
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host ""

    $Doms = @("google.com","cloudflare.com","microsoft.com","amazon.com","youtube.com")
    $Log  = @("=== TEST DNS === $(Get-Date)", "")
    $F    = 0

    foreach ($D in $Doms) {
        $T0 = Get-Date
        try {
            $R  = [System.Net.Dns]::GetHostEntry($D)
            $Ms = [Math]::Round((New-TimeSpan -Start $T0 -End (Get-Date)).TotalMilliseconds)
            $IP = ($R.AddressList | Select-Object -First 2 | ForEach-Object { $_.IPAddressToString }) -join ", "
            $C  = if ($Ms -gt 500) { "Yellow" } else { "Green" }
            Write-Host "  [OK]    $D" -NoNewline -ForegroundColor $C
            Write-Host "   ${Ms}ms  ->  $IP" -ForegroundColor DarkGray
            if ($Ms -gt 500) { Write-Host "          WARNING: slow resolution. Router DNS may be congested." -ForegroundColor DarkYellow }
            $Log += "  [OK]    $D : ${Ms}ms -> $IP"
        } catch {
            $Ms = [Math]::Round((New-TimeSpan -Start $T0 -End (Get-Date)).TotalMilliseconds)
            Write-Host "  [FALLO] $D  (${Ms}ms)" -ForegroundColor Red
            $Log += "  [FALLO] $D : ${Ms}ms"
            $F++
        }
    }

    Write-Host ""
    if ($F -eq $Doms.Count) {
        Write-Host "  WARNING: All domains failed. No Internet or DNS completely down." -ForegroundColor Red
        Write-Host "  Quick fix: change DNS to 1.1.1.1 in the adapter configuration." -ForegroundColor Yellow
    } elseif ($F -gt 0) {
        Write-Host "  WARNING: $F domain(s) fallaron. Posible filtracion o cache DNS corrupta." -ForegroundColor Yellow
    }

    $script:HistorialSesion.Add("[F] Test DNS: $($Doms.Count - $F)/$($Doms.Count) domains OK")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "DNS" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
    return $Log
}

# ================================================================
#  MODULO H - PUERTOS WAN PELIGROSOS
# ================================================================
function Modulo-PuertosWAN {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "H")) { return @() }

    Clear-Host
    Write-Host ""
    Write-Host "  [ H ]  PUERTOS PELIGROSOS EN INTERNET (WAN)" -ForegroundColor Red
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "`n  Obteniendo IP publica..." -ForegroundColor DarkGray

    $IPP = $null
    foreach ($Srv in @("https://api.ipify.org","https://api.my-ip.io/ip","https://ifconfig.me/ip")) {
        try { $IPP = (Invoke-RestMethod -Uri $Srv -TimeoutSec 5 -ErrorAction Stop).Trim()
              if ($IPP -match '^\d{1,3}(\.\d{1,3}){3}$') { break } else { $IPP = $null }
        } catch { $IPP = $null }
    }

    if (-not $IPP) { Write-Host "  No se pudo obtener la IP publica." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return @() }

    Write-Host "  IP Publica: $IPP" -ForegroundColor White
    Write-Host "`n  Scanning puertos criticos desde Internet...`n" -ForegroundColor DarkGray

    $Puertos = @(
        @{ P = 21;   N = "FTP";      R = "CRITICO" }
        @{ P = 22;   N = "SSH";      R = "ALTO"    }
        @{ P = 23;   N = "Telnet";   R = "CRITICO" }
        @{ P = 80;   N = "HTTP";     R = "MEDIO"   }
        @{ P = 443;  N = "HTTPS";    R = "BAJO"    }
        @{ P = 3389; N = "RDP";      R = "CRITICO" }
        @{ P = 8080; N = "HTTP-Alt"; R = "MEDIO"   }
    )

    $Log     = @("=== PUERTOS WAN === $(Get-Date)", "IP Publica: $IPP", "")
    $Alertas = @()

    foreach ($E in $Puertos) {
        $Ok = Test-Puerto -Destino $IPP -Puerto $E.P -TimeoutMs 2000
        if ($Ok) {
            $C = switch ($E.R) { "CRITICO" { "Red" } "ALTO" { "Yellow" } default { "DarkYellow" } }
            Write-Host ("  [EXPUESTO]  Puerto {0,-5} ({1,-10}) RIESGO {2}" -f $E.P, $E.N, $E.R) -ForegroundColor $C
            $Log += "  [EXPUESTO]  Puerto $($E.P) ($($E.N)) [$($E.R)]"
            $Alertas += $E.P
        } else {
            Write-Host ("  [OK]        Puerto {0,-5} ({1,-10}) cerrado/filtrado" -f $E.P, $E.N) -ForegroundColor DarkGreen
            $Log += "  [OK]        Puerto $($E.P) ($($E.N))"
        }
    }

    Write-Host ""
    if ($Alertas.Count -gt 0) {
        Write-Host "  ACCION RECOMENDADA:" -ForegroundColor Yellow
        Write-Host "    Router panel (module C) -> Remote administration -> disable." -ForegroundColor Yellow
        Write-Host "    Or in Port Forwarding: remove rules for the marked ports." -ForegroundColor Yellow
    } else {
        Write-Host "  Sin puertos criticos expuestos. Router bien configurado." -ForegroundColor Green
    }

    $script:HistorialSesion.Add("[H] WAN $IPP | Expuestos: $(if ($Alertas.Count) { $Alertas -join ',' } else { 'None' })")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "WAN" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
    return $Log
}

# ================================================================
#  MODULO J - FABRICANTES POR MAC (OUI)
# ================================================================
function Modulo-Fabricantes {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "J")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ J ]  IDENTIFICACION DE FABRICANTES POR MAC" -ForegroundColor White
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return }
    $GW  = $RI.Gateway
    $Sub = Obtener-SubredBase -Gateway $GW -InterfaceIndex $RI.InterfaceIndex

    Write-Host "`n  Scanning ${Sub}.1 - ${Sub}.254 (tabla OUI local, sin Internet)..." -ForegroundColor DarkGray
    Write-Host ""

    $Ping    = New-Object System.Net.NetworkInformation.Ping
    $Grupos  = @{}   # Fabricante -> Lista de IPs
    $Log     = @("=== FABRICANTES POR MAC === $(Get-Date)", "Subred: ${Sub}.x", "")

    for ($i = 1; $i -le 254; $i++) {
        $IP = "$Sub.$i"
        try {
            if ($Ping.Send($IP, 150).Status -eq 'Success') {
                $null = arp -a 2>$null; Start-Sleep -Milliseconds 80
                $MAC = Get-MACDesdeARP -IP $IP
                $Fab = Get-Fabricante  -MAC $MAC
                $Tag = if ($IP -eq $GW) { " [ROUTER]" } else { "" }

                if (-not $Grupos.ContainsKey($Fab)) { $Grupos[$Fab] = [System.Collections.Generic.List[string]]::new() }
                $Grupos[$Fab].Add("$IP  |  $MAC$Tag")
            }
        } catch { }
    }

    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "  RESULTADOS AGRUPADOS POR FABRICANTE`n" -ForegroundColor Cyan

    $Total = 0
    foreach ($Fab in ($Grupos.Keys | Sort-Object)) {
        $Alerta = $Fab -match "VMware|VirtualBox|QEMU|Raspberry Pi|Ubiquiti"
        $C = if ($Fab -eq "Desconocido") { "DarkGray" } elseif ($Alerta) { "Yellow" } else { "White" }
        Write-Host "  $Fab ($($Grupos[$Fab].Count) device(s))" -ForegroundColor $C
        $Log += "  $Fab ($($Grupos[$Fab].Count)):"
        foreach ($L in $Grupos[$Fab]) {
            Write-Host "    -> $L" -ForegroundColor DarkGray
            $Log += "    -> $L"
            $Total++
        }
        if ($Alerta) { Write-Host "    NOTE: Unusual manufacturer on home network. Verify." -ForegroundColor Yellow }
        $Log += ""
        Write-Host ""
    }

    Write-Host "  Total: $Total devices found." -ForegroundColor Yellow
    $script:HistorialSesion.Add("[J] Fabricantes ${Sub}.x | $Total devices | $($Grupos.Count) fabricantes")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Fabricantes" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO L - VERSION DE FIRMWARE DEL ROUTER
# ================================================================
function Modulo-Firmware {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "L")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ L ]  DETECCION DE FIRMWARE DEL ROUTER" -ForegroundColor DarkYellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    $RI = Obtener-Router
    if (-not $RI) { Write-Host "`n  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return }
    $GW = $RI.Gateway

    Write-Host "`n  Probando rutas conocidas en $GW...`n" -ForegroundColor DarkGray

    # Rutas conocidas por fabricante (accesibles sin autenticacion en muchos modelos)
    $Rutas = @(
        @{ URL = "http://$GW/help/aboutinfo.htm";       Marca = "TP-Link (clasico)"  }
        @{ URL = "http://$GW/userRpm/AboutRpm.htm";     Marca = "TP-Link (alt)"      }
        @{ URL = "http://$GW/cgi-bin/status";           Marca = "TP-Link (cgi)"      }
        @{ URL = "http://$GW/about.html";               Marca = "D-Link"             }
        @{ URL = "http://$GW/info.html";                Marca = "D-Link (alt)"       }
        @{ URL = "http://$GW/Main_Analysis_Content.asp";Marca = "ASUS"               }
        @{ URL = "https://$GW/appGet.cgi?hook=get_system_info()"; Marca = "ASUS (HTTPS)" }
        @{ URL = "http://$GW/statusInfo.html";          Marca = "Huawei/Movistar"    }
        @{ URL = "http://$GW/html/status.html";         Marca = "Huawei (alt)"       }
        @{ URL = "http://$GW/firmware.html";            Marca = "Generico"           }
        @{ URL = "http://$GW/status.html";              Marca = "Generico (alt)"     }
    )

    $Encontrada = $false
    $Log = @("=== FIRMWARE DEL ROUTER === $(Get-Date)", "Gateway: $GW", "")

    foreach ($R in $Rutas) {
        Write-Host "  Probando: $($R.Marca)..." -ForegroundColor DarkGray -NoNewline
        try {
            $Resp = Invoke-WebRequest -Uri $R.URL -TimeoutSec 3 -UseBasicParsing `
                    -ErrorAction Stop -WarningAction SilentlyContinue
            $HTML = $Resp.Content

            # Patrones de version en el HTML
            $Version = $null
            $Patrones = @(
                'Firmware[^<:]*(?:Version)?[^<:]*:[^<"]*?([\d]+\.[\d]+[\d\.]*)',
                'Software Version[^<]*?([0-9]+\.[0-9]+[0-9A-Za-z\._-]*)',
                'FW Version[^<]*?([0-9]+\.[0-9]+[0-9A-Za-z\._-]*)',
                'HW Version[^<]*?([0-9]+\.[0-9]+[0-9A-Za-z\._-]*)',
                'Version[^<"]*?([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\._-]*)',
                '"firmware"[^"]*"([^"]+)"',
                'firmwareVersion[^"]*"([^"]+)"'
            )

            foreach ($Pat in $Patrones) {
                if ($HTML -match $Pat) {
                    $Version = $Matches[1].Trim()
                    break
                }
            }

            if ($Version) {
                Write-Host "  ENCONTRADO" -ForegroundColor Green
                Write-Host ""
                Write-Host "  Marca/Modelo detectado : $($R.Marca)" -ForegroundColor White
                Write-Host "  Version firmware       : $Version" -ForegroundColor Yellow
                Write-Host "  URL fuente             : $($R.URL)" -ForegroundColor DarkGray
                Write-Host ""
                Write-Host "  RECOMMENDATION: Compare this version with the one available on the web" -ForegroundColor Cyan
                Write-Host "  from the manufacturer. If older than 1 year, consider updating." -ForegroundColor Cyan
                $Log += "  Marca   : $($R.Marca)"
                $Log += "  Version : $Version"
                $Log += "  URL     : $($R.URL)"
                $Encontrada = $true
                break
            } elseif ($Resp.StatusCode -eq 200) {
                Write-Host "  responds (no parseable version)" -ForegroundColor DarkGray
            } else {
                Write-Host "  no access" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "  no access" -ForegroundColor DarkGray
        }
    }

    if (-not $Encontrada) {
        Write-Host ""
        Write-Host "  Firmware version not detected automatically." -ForegroundColor Yellow
        Write-Host "  Options manuales:" -ForegroundColor DarkGray
        Write-Host "    1. Use module C to access the router panel." -ForegroundColor Gray
        Write-Host "    2. Look for the version in: Administration > Firmware update." -ForegroundColor Gray
        Write-Host "    3. Check the physical label on the bottom of the router." -ForegroundColor Gray
        $Log += "  Resultado: No found de forma automatica."
    }

    $script:HistorialSesion.Add("[L] Firmware $GW | $(if ($Encontrada) { 'Encontrado' } else { 'No found' })")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Firmware" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO M - INFORME COMPLETO AUTOMATICO
# ================================================================
function Modulo-InformeCompleto {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not $script:ModoAuto -and -not (Mostrar-InfoModulo "M")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ M ]  INFORME COMPLETO AUTOMATICO" -ForegroundColor Green
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "`n  Running modules A, E, F and D in sequence..." -ForegroundColor DarkGray
    Write-Host "  Do not close this window. Will take 2-5 minutes.`n" -ForegroundColor Yellow

    $LogTotal = @(
        "================================================================"
        "  INFORME COMPLETO - Atlas PC Support  v3.0"
        "  Date: $(Get-Date)"
        "================================================================"
        ""
    )

    Write-Host "  [1/4]  Auditoria de Puertos..." -ForegroundColor Cyan
    $LA = Modulo-Auditoria -Silencioso
    $LogTotal += @("", "--- [ A ] AUDITORIA DE PUERTOS ---") + $LA

    Write-Host "`n  [2/4]  Adapter Info..." -ForegroundColor Cyan
    $LE = Modulo-InfoAdaptador -Silencioso
    $LogTotal += @("", "--- [ E ] INFO DEL ADAPTADOR ---") + $LE

    Write-Host "`n  [3/4]  Test DNS..." -ForegroundColor Cyan
    $LF = Modulo-TestDNS -Silencioso
    $LogTotal += @("", "--- [ F ] TEST DNS ---") + $LF

    Write-Host "`n  [4/4]  Diagnostico de Latencia..." -ForegroundColor Cyan
    $LD = Modulo-Latencia -Silencioso
    $LogTotal += @("", "--- [ D ] LATENCIA ---") + $LD

    $LogTotal += @("", "================================================================", "  End of report", "================================================================")

    Write-Host ""
    $Archivo = Exportar-Informe -Contenido $LogTotal -NombreModulo "InformeCompleto"

    $script:HistorialSesion.Add("[M] Informe completo generado: $Archivo")
    Write-Host "`n  Full report ready." -ForegroundColor Green

    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO N - COMPARATIVA DE DISPOSITIVOS
# ================================================================
function Modulo-Comparativa {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "N")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ N ]  COMPARATIVA DE DISPOSITIVOS" -ForegroundColor Magenta
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray

    # Cargar estado previo
    $Previo = @{}
    if (Test-Path $script:ArchivoEstado) {
        $FechaMod = (Get-Item $script:ArchivoEstado).LastWriteTime
        Write-Host "`n  Estado previo found: $FechaMod" -ForegroundColor DarkGray
        foreach ($L in (Get-Content $script:ArchivoEstado)) {
            $P = $L -split '\|'
            if ($P.Count -ge 2) { $Previo[$P[0]] = @{ MAC = $P[1]; Host = if ($P.Count -ge 3) { $P[2] } else { "Oculto" } } }
        }
        Write-Host "  Devices en estado previo: $($Previo.Count)" -ForegroundColor DarkGray
    } else {
        Write-Host "`n  No hay estado previo saved." -ForegroundColor Yellow
        Write-Host "  Run module B first to save a baseline." -ForegroundColor Yellow
        Esperar-Enter -Silencioso:$Silencioso; return
    }

    Write-Host "`n  Scanning la red actual..." -ForegroundColor DarkGray
    $RI = Obtener-Router
    if (-not $RI) { Write-Host "  No se pudo detectar el router." -ForegroundColor Red; Esperar-Enter -Silencioso:$Silencioso; return }
    $Sub  = Obtener-SubredBase -Gateway $RI.Gateway -InterfaceIndex $RI.InterfaceIndex
    $Ping = New-Object System.Net.NetworkInformation.Ping

    $Actual = @{}
    for ($i = 1; $i -le 254; $i++) {
        $IP = "$Sub.$i"
        try {
            if ($Ping.Send($IP, 150).Status -eq 'Success') {
                $null = arp -a 2>$null; Start-Sleep -Milliseconds 60
                $MAC    = Get-MACDesdeARP -IP $IP
                $HostN  = "Oculto"
                try { $H = [System.Net.Dns]::GetHostEntry($IP); if ($H.HostName) { $HostN = $H.HostName } } catch { }
                $Actual[$IP] = @{ MAC = $MAC; Host = $HostN }
            }
        } catch { }
    }

    Write-Host "`n  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "  RESULTADO DE LA COMPARATIVA`n" -ForegroundColor Cyan

    $Log = @("=== COMPARATIVA DE DISPOSITIVOS === $(Get-Date)", "Subred: ${Sub}.x", "")

    # Devices nuevos
    $Nuevos = $Actual.Keys | Where-Object { -not $Previo.ContainsKey($_) }
    if ($Nuevos) {
        Write-Host "  NEW DEVICES (not present in previous scan)" -ForegroundColor Yellow
        $Log += "  NUEVOS:"
        foreach ($IP in ($Nuevos | Sort-Object)) {
            $Fab = Get-Fabricante -MAC $Actual[$IP].MAC
            Write-Host "  [+] $IP  |  $($Actual[$IP].MAC)  |  $Fab  |  $($Actual[$IP].Host)" -ForegroundColor Green
            $Log += "  [+] $IP | $($Actual[$IP].MAC) | $Fab | $($Actual[$IP].Host)"
        }
        $Log += ""
        Write-Host ""
    }

    # Devices desaparecidos
    $Idos = $Previo.Keys | Where-Object { -not $Actual.ContainsKey($_) }
    if ($Idos) {
        Write-Host "  MISSING DEVICES (were present before, no longer responding)" -ForegroundColor DarkGray
        $Log += "  DESAPARECIDOS:"
        foreach ($IP in ($Idos | Sort-Object)) {
            Write-Host "  [-] $IP  |  $($Previo[$IP].MAC)  |  $($Previo[$IP].Host)" -ForegroundColor DarkGray
            $Log += "  [-] $IP | $($Previo[$IP].MAC) | $($Previo[$IP].Host)"
        }
        $Log += ""
        Write-Host ""
    }

    # Sin cambios
    $Iguales = $Actual.Keys | Where-Object { $Previo.ContainsKey($_) }
    Write-Host "  SIN CAMBIOS: $($Iguales.Count) device(s)" -ForegroundColor DarkGray
    $Log += "  SIN CAMBIOS: $($Iguales.Count)"

    Write-Host ""
    if (-not $Nuevos -and -not $Idos) {
        Write-Host "  La red no ha cambiado desde el ultimo escaneo." -ForegroundColor Green
    }

    # Guardar el nuevo estado como el actual
    try {
        ($Actual.Keys | ForEach-Object { "$_|$($Actual[$_].MAC)|$($Actual[$_].Host)" }) |
        Out-File $script:ArchivoEstado -Encoding UTF8 -Force
    } catch { }

    $script:HistorialSesion.Add("[N] Comparativa | +$($Nuevos.Count) nuevos | -$($Idos.Count) desaparecidos")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Comparativa" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO P - TEST DE VELOCIDAD DE DESCARGA
# ================================================================
function Modulo-Velocidad {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "P")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ P ]  TEST DE VELOCIDAD DE DESCARGA" -ForegroundColor Yellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host ""

    $URL_5MB  = "https://speed.cloudflare.com/__down?bytes=5242880"
    $URL_10MB = "https://speed.cloudflare.com/__down?bytes=10485760"

    $Resultados = @()
    $Log = @("=== TEST DE VELOCIDAD === $(Get-Date)", "Servidor: Cloudflare CDN", "")

    foreach ($Prueba in @(@{ URL = $URL_5MB; Tam = 5 }, @{ URL = $URL_10MB; Tam = 10 })) {
        Write-Host "  Downloading $($Prueba.Tam) MB desde Cloudflare..." -ForegroundColor DarkGray -NoNewline
        try {
            $T0   = Get-Date
            $null = Invoke-WebRequest -Uri $Prueba.URL -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
            $Secs = (New-TimeSpan -Start $T0 -End (Get-Date)).TotalSeconds
            $MBs  = [Math]::Round($Prueba.Tam / $Secs, 2)
            $Mbps = [Math]::Round($MBs * 8, 1)

            $C = if ($Mbps -lt 5) { "Red" } elseif ($Mbps -lt 25) { "Yellow" } else { "Green" }
            Write-Host " OK" -ForegroundColor Green
            Write-Host ("  Resultado ($($Prueba.Tam) MB):  {0,7} MB/s  =  {1,8} Mbps  (en {2:F1}s)" -f $MBs, $Mbps, $Secs) -ForegroundColor $C
            $Log     += "  Test $($Prueba.Tam) MB : $MBs MB/s = $Mbps Mbps en $([Math]::Round($Secs,1))s"
            $Resultados += $Mbps
        } catch {
            Write-Host " ERROR" -ForegroundColor Red
            Write-Host "  Could not download file. Check connection." -ForegroundColor Red
            $Log += "  Test $($Prueba.Tam) MB : ERROR"
        }
        Write-Host ""
    }

    if ($Resultados.Count -gt 0) {
        $Media = [Math]::Round(($Resultados | Measure-Object -Average).Average, 1)
        Write-Host "  Media aproximada: $Media Mbps" -ForegroundColor White
        Write-Host ""
        Write-Host "  REFERENCIA:" -ForegroundColor Cyan
        Write-Host "    < 5 Mbps    Very slow. Severe connection issues." -ForegroundColor Red
        Write-Host "    5 - 25 Mbps Basica. Navegacion y streaming SD." -ForegroundColor Yellow
        Write-Host "    25 - 100 Mbps Buena. Streaming HD y videollamadas." -ForegroundColor Green
        Write-Host "    > 100 Mbps  Excellent. Fit for any use." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  NOTE: Run on cable and WiFi to compare differences." -ForegroundColor DarkGray
        $Log += "  Media: $Media Mbps"
    }

    $script:HistorialSesion.Add("[P] Test velocidad | Media: $(if ($Resultados.Count) { ($Resultados | Measure-Object -Average).Average.ToString('F1') } else { 'ERROR' }) Mbps")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "Velocidad" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO Q - DETECCION DE PORTAL CAUTIVO
# ================================================================
function Modulo-PortalCautivo {
    param([switch]$Silencioso)
    if (-not $Silencioso -and -not (Mostrar-InfoModulo "Q")) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  [ Q ]  DETECCION DE PORTAL CAUTIVO" -ForegroundColor DarkYellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host "`n  Verifying conectividad limpia a Internet...`n" -ForegroundColor DarkGray

    $Log = @("=== PORTAL CAUTIVO === $(Get-Date)", "")
    $Resultado = "DESCONOCIDO"

    try {
        # Google genera_204 es el estandar de deteccion de portal cautivo
        $R = Invoke-WebRequest -Uri "http://connectivitycheck.gstatic.com/generate_204" `
             -UseBasicParsing -TimeoutSec 5 -MaximumRedirection 0 -ErrorAction Stop

        if ($R.StatusCode -eq 204) {
            Write-Host "  RESULTADO: Connection limpia" -ForegroundColor Green
            Write-Host "  HTTP 204 recibido -> No hay portal cautivo activo." -ForegroundColor Green
            Write-Host "`n  Your device has direct Internet access with no interception." -ForegroundColor White
            $Resultado = "LIMPIA"
            $Log      += "  Resultado : Connection limpia (HTTP 204)"
        } elseif ($R.StatusCode -eq 200) {
            Write-Host "  RESULTADO: Portal cautivo detectado" -ForegroundColor Red
            Write-Host "  HTTP 200 instead of 204 -> Response was intercepted." -ForegroundColor Red
            Write-Host "`n  ACCION RECOMENDADA:" -ForegroundColor Yellow
            Write-Host "    Open the browser and navigate to http://neverssl.com" -ForegroundColor Yellow
            Write-Host "    The registration portal will open automatically." -ForegroundColor Yellow
            $Resultado = "PORTAL CAUTIVO"
            $Log      += "  Resultado : Portal cautivo detectado (HTTP 200)"
        } else {
            Write-Host "  RESULTADO: Response inesperada (HTTP $($R.StatusCode))" -ForegroundColor Yellow
            $Resultado = "INESPERADO ($($R.StatusCode))"
            $Log      += "  Resultado : Response inesperada HTTP $($R.StatusCode)"
        }
    } catch {
        # Una redireccion (30x) normalmente es portal cautivo
        $Msg = $_.Exception.Message
        if ($Msg -match "redirect|30[0-9]|Location") {
            Write-Host "  RESULTADO: Portal cautivo detectado (redireccion 3xx)" -ForegroundColor Red
            Write-Host "`n  ACCION RECOMENDADA:" -ForegroundColor Yellow
            Write-Host "    Open the browser and navigate to http://neverssl.com" -ForegroundColor Yellow
            $Resultado = "PORTAL CAUTIVO (redireccion)"
            $Log      += "  Resultado : Portal cautivo - redireccion detectada"
        } else {
            Write-Host "  RESULT: No Internet connection" -ForegroundColor Red
            Write-Host "  No se pudo alcanzar el servidor de verificacion." -ForegroundColor DarkGray
            Write-Host "`n  Check that WiFi/cable is connected and run module D." -ForegroundColor Yellow
            $Resultado = "SIN INTERNET"
            $Log      += "  Result  : No Internet connection"
        }
    }

    # Prueba adicional con Apple
    try {
        $R2 = Invoke-WebRequest -Uri "http://captive.apple.com/hotspot-detect.html" `
              -UseBasicParsing -TimeoutSec 5 -MaximumRedirection 0 -ErrorAction Stop
        $EsPortal2 = $R2.Content -notmatch "Success"
        $Log += "  Apple captive.apple.com : $(if ($EsPortal2) { 'Portal detectado' } else { 'Limpio' })"
    } catch { }

    $script:HistorialSesion.Add("[Q] Portal cautivo: $Resultado")

    if (-not $Silencioso -and -not $script:ModoAuto) {
        $Exp = Read-Host "`n  Exportar informe a TXT? (Y/N)"
        if ($Exp -match '^[SsYy]$') { Exportar-Informe -Contenido $Log -NombreModulo "PortalCautivo" | Out-Null }
    }

    Esperar-Enter -Silencioso:$Silencioso
}

# ================================================================
#  MODULO I - HISTORIAL DE SESION
# ================================================================
function Modulo-WiFiGuardadas {
    Clear-Host
    Write-Host ""
    Write-Host "  [ K ]  PASSWORDS WIFI GUARDADAS" -ForegroundColor Yellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [!] WiFi networks saved on this PC will be shown" -ForegroundColor Cyan
    Write-Host "      along with their passwords (requires admin)." -ForegroundColor Cyan
    Write-Host "  [!] This is sensitive information. Use only on your own computers" -ForegroundColor Yellow
    Write-Host "      or with explicit owner authorization." -ForegroundColor Yellow
    Write-Host ""
    $ok = Read-Host "  Continuar? [Y/N]"
    if ($ok -notmatch '^[SsYy]$') { return }

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  [X] Esta option requiere run como administrador." -ForegroundColor Red
        Esperar-Enter
        return
    }

    Write-Host ""
    Write-Host "  Consultando perfiles WLAN..." -ForegroundColor DarkGray

    $raw = netsh wlan show profiles 2>$null
    $perfiles = @()
    foreach ($line in $raw) {
        if ($line -match "Perfil de all users\s*:\s*(.+)$" -or $line -match "All User Profile\s*:\s*(.+)$") {
            $perfiles += ($matches[1]).Trim()
        }
    }

    if ($perfiles.Count -eq 0) {
        Write-Host "  [!] No se detectaron perfiles WLAN saved." -ForegroundColor Yellow
        Esperar-Enter
        return
    }

    $resultado = @()
    $resultado += "=== PASSWORDS WIFI GUARDADAS ==="
    $resultado += "Computer: $env:COMPUTERNAME"
    $resultado += "Date:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $resultado += ""
    $resultado += "{0,-40} {1,-15} {2}" -f "SSID", "Autenticacion", "Password"
    $resultado += ("-" * 80)

    foreach ($p in $perfiles) {
        $det = netsh wlan show profile name="$p" key=clear 2>$null
        $auth = ""
        $pass = ""
        foreach ($l in $det) {
            if ($l -match "Autenticaci.n\s*:\s*(.+)$" -or $l -match "Authentication\s*:\s*(.+)$") { $auth = ($matches[1]).Trim() }
            elseif ($l -match "Contenido de la clave\s*:\s*(.+)$" -or $l -match "Key Content\s*:\s*(.+)$") { $pass = ($matches[1]).Trim() }
        }
        if (-not $pass) { $pass = "(no password / open)" }
        if (-not $auth) { $auth = "?" }
        $linea = "{0,-40} {1,-15} {2}" -f $p, $auth, $pass
        $resultado += $linea
        Write-Host "  $linea" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  Total perfiles: $($perfiles.Count)" -ForegroundColor Cyan
    Write-Host ""
    $x = Read-Host "  Export to TXT on Desktop? [Y/N]"
    if ($x -match '^[SsYy]$') { Exportar-Informe -Contenido $resultado -NombreModulo "WiFiGuardadas" }
    $script:HistorialSesion.Add("WiFi saved: $($perfiles.Count) perfiles") | Out-Null
    Esperar-Enter
}

function Modulo-PortScanGateway {
    Clear-Host
    Write-Host ""
    Write-Host "  [ O ]  ESCANEO DE PUERTOS DEL GATEWAY (ROUTER)" -ForegroundColor Yellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host ""

    $gw = Obtener-Router
    if (-not $gw) {
        Write-Host "  [X] No se pudo determinar el gateway." -ForegroundColor Red
        Esperar-Enter; return
    }

    Write-Host "  Gateway: $gw" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Scanning puertos tipicos abiertos..." -ForegroundColor DarkGray
    Write-Host ""

    $puertos = @(
        @{ p=21;    s="FTP"         },
        @{ p=22;    s="SSH"         },
        @{ p=23;    s="Telnet"      },
        @{ p=53;    s="DNS"         },
        @{ p=80;    s="HTTP (panel)"},
        @{ p=81;    s="HTTP alt"    },
        @{ p=123;   s="NTP"         },
        @{ p=139;   s="NetBIOS"     },
        @{ p=443;   s="HTTPS"       },
        @{ p=445;   s="SMB"         },
        @{ p=515;   s="LPD imp."    },
        @{ p=548;   s="AFP"         },
        @{ p=554;   s="RTSP"        },
        @{ p=631;   s="IPP imp."    },
        @{ p=1900;  s="UPnP"        },
        @{ p=5000;  s="UPnP alt"    },
        @{ p=5357;  s="WSD"         },
        @{ p=7547;  s="TR-069 CWMP" },
        @{ p=8080;  s="HTTP proxy"  },
        @{ p=8081;  s="HTTP alt"    },
        @{ p=8291;  s="MikroTik"    },
        @{ p=8443;  s="HTTPS alt"   },
        @{ p=8888;  s="HTTP alt"    },
        @{ p=9100;  s="JetDirect"   }
    )

    $resultado = @()
    $resultado += "=== ESCANEO PUERTOS GATEWAY ==="
    $resultado += "Gateway: $gw"
    $resultado += "Date:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $resultado += ""

    $abiertos = 0; $total = $puertos.Count; $n = 0
    foreach ($e in $puertos) {
        $n++
        Write-Progress -Activity "Scanning gateway ports" -Status ("Puerto {0}/{1} - {2}" -f $n, $total, $e.p) -PercentComplete (($n / $total) * 100)
        $ok = Test-Puerto -Destino $gw -Puerto $e.p -TimeoutMs 600
        if ($ok) {
            $line = ("  [OK] {0,5}/tcp  {1}" -f $e.p, $e.s)
            Write-Host $line -ForegroundColor Green
            $resultado += "ABIERTO {0,5}/tcp - {1}" -f $e.p, $e.s
            $abiertos++
        }
    }
    Write-Progress -Activity "Scanning gateway ports" -Completed

    Write-Host ""
    Write-Host "  Total abiertos: $abiertos / $total" -ForegroundColor Cyan
    Write-Host ""
    if ($abiertos -gt 0) {
        Write-Host "  NOTA: Un panel web (80/443/8080/8443) es normal." -ForegroundColor DarkGray
        Write-Host "  Ports such as Telnet (23), SMB (445), FTP (21) open on the router" -ForegroundColor Yellow
        Write-Host "  suelen indicar configuration insegura. Revisa el panel." -ForegroundColor Yellow
    }
    Write-Host ""
    $x = Read-Host "  Exportar TXT? [Y/N]"
    if ($x -match '^[SsYy]$') { Exportar-Informe -Contenido $resultado -NombreModulo "PortScanGateway" }
    $script:HistorialSesion.Add("PortScan Gateway: $abiertos abiertos en $gw") | Out-Null
    Esperar-Enter
}

function Modulo-ARPCompleto {
    Clear-Host
    Write-Host ""
    Write-Host "  [ R ]  DISPOSITIVOS EN LA LAN (ARP / NEIGHBOR)" -ForegroundColor Yellow
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host ""

    $entries = @()

    try {
        $nbrs = Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
            $_.State -in 'Reachable','Stale','Permanent','Delay','Probe' -and
            $_.IPAddress -notmatch '^(224\.|239\.|255\.)' -and
            $_.LinkLayerAddress -and $_.LinkLayerAddress -ne '00-00-00-00-00-00'
        }
        foreach ($n in $nbrs) {
            $entries += [pscustomobject]@{
                IP = $n.IPAddress
                MAC = ($n.LinkLayerAddress -replace ':', '-').ToUpper()
                Estado = $n.State
                Fuente = 'Get-NetNeighbor'
            }
        }
    } catch { }

    # Fallback a arp -a
    if ($entries.Count -eq 0) {
        $raw = arp -a 2>$null
        foreach ($l in $raw) {
            if ($l -match '(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2}[-:][0-9a-fA-F]{2})\s+(\w+)') {
                $m = ($matches[2] -replace ':', '-').ToUpper()
                if ($m -ne 'FF-FF-FF-FF-FF-FF' -and $m -ne '00-00-00-00-00-00') {
                    $entries += [pscustomobject]@{
                        IP = $matches[1]
                        MAC = $m
                        Estado = $matches[3]
                        Fuente = 'arp -a'
                    }
                }
            }
        }
    }

    if ($entries.Count -eq 0) {
        Write-Host "  [!] No devices detected. Try after pinging the gateway." -ForegroundColor Yellow
        Esperar-Enter; return
    }

    $gw = Obtener-Router

    $resultado = @()
    $resultado += "=== DISPOSITIVOS EN LA LAN ==="
    $resultado += "Gateway: $gw"
    $resultado += "Date:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $resultado += ""
    $resultado += "{0,-16} {1,-18} {2,-10} {3,-12} {4}" -f "IP", "MAC", "Estado", "Fuente", "Fabricante"
    $resultado += ("-" * 80)

    Write-Host ("  {0,-16} {1,-18} {2,-10} {3,-12} {4}" -f "IP", "MAC", "Estado", "Fuente", "Fabricante") -ForegroundColor Cyan
    Write-Host "  $('-' * 80)" -ForegroundColor DarkGray

    $porFabricante = @{}
    foreach ($e in ($entries | Sort-Object { [version]($_.IP -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$', '$1.$2.$3.$4') } )) {
        $fab = Get-Fabricante -MAC $e.MAC
        $marker = if ($e.IP -eq $gw) { "*" } else { " " }
        $line = ("{0} {1,-15} {2,-18} {3,-10} {4,-12} {5}" -f $marker, $e.IP, $e.MAC, $e.Estado, $e.Fuente, $fab)
        Write-Host "  $line" -ForegroundColor White
        $resultado += $line.Trim()
        if (-not $porFabricante.ContainsKey($fab)) { $porFabricante[$fab] = 0 }
        $porFabricante[$fab]++
    }

    Write-Host ""
    Write-Host "  Total devices: $($entries.Count)  (* = gateway)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Summary by manufacturer:" -ForegroundColor DarkGray
    foreach ($k in ($porFabricante.Keys | Sort-Object)) {
        Write-Host ("    {0,-20} {1}" -f $k, $porFabricante[$k]) -ForegroundColor DarkGray
    }
    Write-Host ""

    $x = Read-Host "  Exportar TXT? [Y/N]"
    if ($x -match '^[SsYy]$') { Exportar-Informe -Contenido $resultado -NombreModulo "ARPCompleto" }
    $script:HistorialSesion.Add("ARP LAN: $($entries.Count) devices") | Out-Null
    Esperar-Enter
}

function Mostrar-Historial {
    Clear-Host
    Write-Host ""
    Write-Host "  [ I ]  HISTORIAL DE SESION" -ForegroundColor DarkGray
    Write-Host "  $("-" * 60)" -ForegroundColor DarkGray
    Write-Host ""
    if ($script:HistorialSesion.Count -eq 0) {
        Write-Host "  You have not run any tool in this session yet." -ForegroundColor DarkGray
    } else {
        Write-Host "  Actions performed this session:`n" -ForegroundColor Cyan
        $n = 1
        foreach ($E in $script:HistorialSesion) {
            Write-Host ("  {0,2}. {1}" -f $n, $E) -ForegroundColor White
            $n++
        }
    }
    Esperar-Enter
}

# ================================================================
#  MODO AUTO (-Auto): run informe completo y salir
# ================================================================
if ($script:ModoAuto) {
    Modulo-InformeCompleto -Silencioso
    return
}

# ================================================================
#  MENU PRINCIPAL
# ================================================================
while ($true) {
    Clear-Host
    Write-Host "`n"
    if ($atlasToolkitReady) {
        Write-AtlasHeader -Title 'ROUTER SECURITY AUDIT v3.0' -Color Yellow
        Write-AtlasStep 'Scan · Firmware · Devices · Report'
        Write-Host ""
    } else {
        Escribir-Centrado "  +--------------------------------------------------------------+  " "DarkGray"
        Escribir-Centrado "  |                                                              |  " "Yellow"
        Escribir-Centrado "  |            ROUTER SECURITY AUDIT  v3.0                      |  " "Yellow"
        Escribir-Centrado "  |         Scan · Firmware · Devices · Report                  |  " "DarkGray"
        Escribir-Centrado "  |                                                              |  " "Yellow"
        Escribir-Centrado "  +--------------------------------------------------------------+  " "DarkGray"
        Write-Host ""
    }
    Escribir-Centrado "  +--- DIAGNOSTICO BASICO ------+---- HERRAMIENTAS AVANZADAS --+  " "DarkGray"
    Escribir-Centrado "  |                             |                              |  " "DarkGray"
    Escribir-Centrado "  |  [A]  LAN Ports Audit       |  [L]  Router Firmware       |  " "White"
    Escribir-Centrado "  |  [B]  Escaneo Devices  |  [M]  Informe Automatico    |  " "White"
    Escribir-Centrado "  |  [C]  Router Panel          |  [N]  Network Comparison    |  " "Cyan"
    Escribir-Centrado "  |  [D]  Latencia / Estabilidad|  [P]  Test de Velocidad     |  " "White"
    Escribir-Centrado "  |  [E]  Adapter Info          |  [Q]  Captive Portal        |  " "White"
    Escribir-Centrado "  |  [F]  Test de DNS           |                              |  " "White"
    Escribir-Centrado "  |  [H]  Puertos WAN           |  [J]  Fabricantes (MAC/OUI) |  " "White"
    Escribir-Centrado "  |                             |                              |  " "DarkGray"
    Escribir-Centrado "  +--- SEGURIDAD / RECON -------+------------------------------+  " "DarkGray"
    Escribir-Centrado "  |  [K]  Passwords WiFi      |  [O]  Scan puertos gateway  |  " "Cyan"
    Escribir-Centrado "  |  [R]  Devices LAN (ARP)|                              |  " "Cyan"
    Escribir-Centrado "  +--- SESION ------------------+------------------------------+  " "DarkGray"
    Escribir-Centrado "  |  [I]  Historial de Sesion   |  [S]  Salir                 |  " "DarkGray"
    Escribir-Centrado "  +-----------------------------+------------------------------+  " "DarkGray"
    Write-Host ""
    if ($script:HistorialSesion.Count -gt 0) {
        Escribir-Centrado "  Session actions: $($script:HistorialSesion.Count)  |  Info: $(if ($script:MostrarInfo) { 'on' } else { 'off' })  " "DarkGray"
        Write-Host ""
    }

    $Op = Read-Host "  Choose an option"

    switch ($Op.ToUpper()) {
        "A" { Modulo-Auditoria     }
        "B" { Modulo-Escaneo       }
        "C" { Modulo-Panel         }
        "D" { Modulo-Latencia      }
        "E" { Modulo-InfoAdaptador }
        "F" { Modulo-TestDNS       }
        "H" { Modulo-PuertosWAN    }
        "I" { Mostrar-Historial    }
        "J" { Modulo-Fabricantes   }
        "K" { Modulo-WiFiGuardadas }
        "L" { Modulo-Firmware      }
        "O" { Modulo-PortScanGateway }
        "R" { Modulo-ARPCompleto   }
        "M" { Modulo-InformeCompleto }
        "N" { Modulo-Comparativa   }
        "P" { Modulo-Velocidad     }
        "Q" { Modulo-PortalCautivo }
        "S" {
            if ($script:HistorialSesion.Count -gt 0) {
                Write-Host ""
                Write-Host "  --- RESUMEN DE SESION ---" -ForegroundColor Yellow
                $n = 1
                foreach ($E in $script:HistorialSesion) {
                    Write-Host ("  {0,2}. {1}" -f $n, $E) -ForegroundColor DarkGray
                    $n++
                }
            }
            Write-Host "`n  Closing herramientas... Hasta pronto, Atlas!" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            [console]::ResetColor()
            Clear-Host
            return
        }
        default {
            Write-Host "`n  Invalid option. Choose a letter from the menu." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
}
