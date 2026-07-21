# ============================================================
# Invoke-SelectorDNS
# Migrado de: SelectorDNS.ps1
# Atlas PC Support — v1.0
# ============================================================

function Invoke-SelectorDNS {
    [CmdletBinding()]
    param()
# ==============================================================================
# Atlas PC Support - Advanced DNS Selector v2.0
# Bilingue, Navegable, Full-Featured
# Fixes: TryParse guard, ReadKey, Write-Centered fuera del loop,
#        BackgroundColor + Clear-Host inmediato, header box alineado,
#        null-safe adapter check.
# Upscales: DNS status, latency test, custom DNS, per-adapter, backup/restore,
#           more providers, DoH toggle, startup task, activity log, UI polish.
# ==============================================================================

#region ── Inicializacion ─────────────────────────────────────────────────────
[console]::BackgroundColor = "Black"
[console]::ForegroundColor = "White"
Clear-Host  # FIX: Clear inmediato para que el BackgroundColor aplique de una vez

function _Atlas-DetectLang {
    if ($env:ATLAS_LANG) { return [string]$env:ATLAS_LANG }
    try {
        $cfg = Join-Path $env:LOCALAPPDATA 'AtlasPC\config.json'
        if (Test-Path -LiteralPath $cfg) {
            $obj = Get-Content -Raw -LiteralPath $cfg -Encoding UTF8 | ConvertFrom-Json
            if ($obj.language) { return [string]$obj.language }
        }
    } catch {}
    $sys = (Get-Culture).TwoLetterISOLanguageName
    if ($sys -eq 'es') { return 'es' }
    return 'en'
}
$lang = _Atlas-DetectLang
$es   = ($lang -eq 'es')
$atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

$logFile    = Join-Path $env:LOCALAPPDATA 'AtlasPC\logs\dns_log.txt'
$backupFile = Join-Path $env:LOCALAPPDATA 'AtlasPC\logs\dns_backup.json'
$null = New-Item -ItemType Directory -Path (Split-Path $logFile) -Force -ErrorAction SilentlyContinue
#endregion

#region ── Diccionario Bilingue ───────────────────────────────────────────────
$txt = @{
    # Encabezado
    VerStr       = "v2.0"
    # Opciones DNS
    Opt1         = if ($es) { " 1. DNS Automatico        (Windows por defecto)" }       else { " 1. Automatic DNS         (Windows default)" }
    HeaderCF     = "--- CLOUDFLARE -----------------------------------------------"
    Opt2         = " 2. Basico               (1.1.1.1  | Max Speed)"
    Opt3         = " 3. Avanzado             (1.1.1.2  | Malware Block)"
    Opt4         = " 4. Familiar             (1.1.1.3  | Malware + Adult)"
    HeaderGG     = "--- GOOGLE ---------------------------------------------------"
    Opt5         = " 5. Google DNS           (8.8.8.8  | General Purpose)"
    HeaderQ9     = "--- QUAD9 ----------------------------------------------------"
    Opt6         = " 6. Quad9                (9.9.9.9  | Malware + Privacy)"
    HeaderOD     = "--- OPENDNS --------------------------------------------------"
    Opt7         = " 7. OpenDNS Home         (208.67.222.222 | General)"
    Opt8         = " 8. OpenDNS FamilyShield (208.67.222.123 | Adult Block)"
    HeaderMV     = "--- MULLVAD --------------------------------------------------"
    Opt9         = " 9. Mullvad 1            (194.242.2.2 | Solo DNS Resolver)"
    Opt10        = "10. Mullvad 2            (194.242.2.3 | AdBlock)"
    Opt11        = "11. Mullvad 3            (194.242.2.4 | Ads+Trackers+Adware)"
    Opt12        = "12. Mullvad 4            (194.242.2.5 | Social Media+Molest.)"
    Opt13        = "13. Mullvad 5            (194.242.2.6 | Adult+Gambling)"
    Opt14        = "14. Mullvad 6            (194.242.2.9 | Extreme)"
    HeaderND     = "--- NEXTDNS --------------------------------------------------"
    Opt15        = "15. NextDNS              (45.90.28.0  | Configurable)"
    HeaderCU     = "--- PERSONALIZADO / CUSTOM -----------------------------------"
    Opt16        = if ($es) { "16. DNS Personalizado    (Ingresa tus propias IPs)" }     else { "16. Custom DNS           (Enter your own IPs)" }
    # Herramientas
    HeaderTools  = if ($es) { "===== HERRAMIENTAS =====================================" } else { "===== TOOLS ============================================" }
    Opt17        = if ($es) { "17. Test de Latencia DNS    (Ping a todos los servers)" } else { "17. DNS Latency Test        (Ping all servers)" }
    Opt18        = if ($es) { "18. Backup DNS actual       (Guardar config actual)" }     else { "18. Backup current DNS      (Save current config)" }
    Opt19        = if ($es) { "19. Restaurar desde Backup  (Revertir cambios)" }          else { "19. Restore from Backup     (Revert changes)" }
    Opt20        = if ($es) { "20. Toggle DNS-over-HTTPS   (DoH On/Off)" }                else { "20. Toggle DNS-over-HTTPS   (DoH On/Off)" }
    Opt21        = if ($es) { "21. Persistencia al Inicio  (Tarea Programada)" }          else { "21. Startup Persistence     (Scheduled Task)" }
    Opt22        = if ($es) { "22. Ver Registro            (Ultimas 30 entradas)" }       else { "22. View Activity Log       (Last 30 entries)" }
    Opt23        = if ($es) { "23. Seleccion por Adaptador (Elegir NIC especifica)" }     else { "23. Per-Adapter Selection   (Choose specific NIC)" }
    Opt24        = if ($es) { "24. Test Seguridad DNS      (Cloudflare ESNI browser)" }   else { "24. DNS Security Test       (Cloudflare ESNI browser)" }
    Opt0         = if ($es) { " 0. Salir" }                                               else { " 0. Exit" }
    # Prompts y mensajes
    Prompt       = if ($es) { "Elige una opcion (0-24)" }              else { "Choose an option (0-24)" }
    PromptDNSOpt = if ($es) { "Perfil DNS a aplicar (1-15): " }        else { "DNS profile to apply (1-15): " }
    ErrNoAdap    = if ($es) { "[ERROR] No se encontraron adaptadores." } else { "[ERROR] No adapters found." }
    Applying     = if ($es) { "Aplicando configuracion..." }            else { "Applying configuration..." }
    Opening      = if ($es) { "Abriendo navegador..." }                 else { "Opening browser..." }
    OkAuto       = if ($es) { "-> DNS Automatico" }                     else { "-> Automatic DNS" }
    OkDNS        = if ($es) { "-> Usando" }                             else { "-> Using" }
    ErrInv       = if ($es) { "[ERROR] Opcion no valida." }             else { "[ERROR] Invalid option." }
    ErrBlank     = if ($es) { "[ERROR] Debes ingresar un numero (0-24)." } else { "[ERROR] Enter a number (0-24)." }
    FlushDNS     = if ($es) { "Limpiando cache DNS..." }                else { "Flushing DNS cache..." }
    Done         = if ($es) { "Hecho! Proceso terminado exitosamente." } else { "Done! Process finished successfully." }
    Next         = if ($es) { " Presiona cualquier tecla para volver al menu..." } else { " Press any key to return to menu..." }
    CurrentDNS   = if ($es) { "DNS ACTIVO" }                            else { "ACTIVE DNS" }
    Auto         = if ($es) { "Automatico" }                            else { "Automatic" }
    # Custom DNS
    CustomPrim   = if ($es) { "  DNS Primario   (ej: 8.8.8.8)  : " }   else { "  Primary DNS    (e.g. 8.8.8.8) : " }
    CustomSec    = if ($es) { "  DNS Secundario (ej: 8.8.4.4)  : " }   else { "  Secondary DNS  (e.g. 8.8.4.4) : " }
    CustomApply  = if ($es) { "Aplicar a todos los adaptadores? (s/n) [n = elegir]: " } else { "Apply to all adapters? (y/n) [n = choose]: " }
    # Backup / Restore
    BackupOk     = if ($es) { "[OK] Backup guardado en:" }              else { "[OK] Backup saved to:" }
    BackupNone   = if ($es) { "[ERROR] No se encontro archivo de backup en:" } else { "[ERROR] No backup file found at:" }
    RestoreOk    = if ($es) { "[OK] DNS restaurado desde backup." }     else { "[OK] DNS restored from backup." }
    # Latencia
    PingTesting  = if ($es) { "Probando latencia (3 pings por servidor)..." } else { "Testing latency (3 pings per server)..." }
    Fastest      = if ($es) { "Mas rapido" }                            else { "Fastest" }
    NoResp       = if ($es) { "Sin respuesta" }                         else { "No response" }
    # DoH
    DoHStatus    = if ($es) { "Estado DoH actual:" }                    else { "Current DoH status:" }
    DoHOn        = if ($es) { "ACTIVADO" }                              else { "ENABLED" }
    DoHOff       = if ($es) { "DESACTIVADO" }                          else { "DISABLED" }
    DoHChoose    = if ($es) { "  [1] Activar DoH   [2] Desactivar DoH   [0] Cancelar: " } else { "  [1] Enable DoH   [2] Disable DoH   [0] Cancel: " }
    DoHNote      = if ($es) { "(Requiere reinicio para aplicarse completamente)" } else { "(Restart required for full effect)" }
    # Tarea programada
    TaskExists   = if ($es) { "Ya existe la tarea 'AtlasDNS'. Eliminarla? (s/n): " } else { "Task 'AtlasDNS' already exists. Remove it? (y/n): " }
    TaskCreated  = if ($es) { "[OK] Tarea creada. El DNS se re-aplicara al iniciar sesion." } else { "[OK] Task created. DNS will re-apply on logon." }
    TaskRemoved  = if ($es) { "[OK] Tarea programada eliminada." }      else { "[OK] Scheduled task removed." }
    TaskNone     = if ($es) { "(No hay tarea activa actualmente)" }     else { "(No active task currently)" }
    # Log
    LogEmpty     = if ($es) { "(El registro esta vacio)" }              else { "(The log is empty)" }
    LogPath      = if ($es) { "Archivo: " }                             else { "File: " }
    # Per-adapter
    AdapHeader   = if ($es) { "Adaptadores disponibles:" }              else { "Available adapters:" }
    AdapPrompt   = if ($es) { "  Numero de adaptador o [T]odos: " }    else { "  Adapter number or [A]ll: " }
    AdapAll      = if ($es) { "Todos los adaptadores" }                 else { "All adapters" }
}
#endregion

#region ── Perfiles DNS ──────────────────────────────────────────────────────
$dnsProfiles = [ordered]@{
    '1'  = @{ Label = "Automatic";               Addr = @() }
    '2'  = @{ Label = "Cloudflare Basic";         Addr = @("1.1.1.1","1.0.0.1","2606:4700:4700::1111","2606:4700:4700::1001") }
    '3'  = @{ Label = "Cloudflare Advanced";      Addr = @("1.1.1.2","1.0.0.2","2606:4700:4700::1112","2606:4700:4700::1002") }
    '4'  = @{ Label = "Cloudflare Family";        Addr = @("1.1.1.3","1.0.0.3","2606:4700:4700::1113","2606:4700:4700::1003") }
    '5'  = @{ Label = "Google DNS";               Addr = @("8.8.8.8","8.8.4.4","2001:4860:4860::8888","2001:4860:4860::8844") }
    '6'  = @{ Label = "Quad9";                    Addr = @("9.9.9.9","149.112.112.112","2620:fe::fe","2620:fe::9") }
    '7'  = @{ Label = "OpenDNS Home";             Addr = @("208.67.222.222","208.67.220.220") }
    '8'  = @{ Label = "OpenDNS FamilyShield";     Addr = @("208.67.222.123","208.67.220.123") }
    '9'  = @{ Label = "Mullvad 1 (Resolver)";     Addr = @("194.242.2.2","2a07:e340::2") }
    '10' = @{ Label = "Mullvad 2 (AdBlock)";      Addr = @("194.242.2.3","2a07:e340::3") }
    '11' = @{ Label = "Mullvad 3 (Tracker)";      Addr = @("194.242.2.4","2a07:e340::4") }
    '12' = @{ Label = "Mullvad 4 (Social)";       Addr = @("194.242.2.5","2a07:e340::5") }
    '13' = @{ Label = "Mullvad 5 (Adult)";        Addr = @("194.242.2.6","2a07:e340::6") }
    '14' = @{ Label = "Mullvad 6 (Extreme)";      Addr = @("194.242.2.9","2a07:e340::9") }
    '15' = @{ Label = "NextDNS";                  Addr = @("45.90.28.0","45.90.30.0","2a07:a8c0::","2a07:a8c1::") }
}

# Templates DoH por IP
$dohTemplates = @{
    "1.1.1.1"              = "https://cloudflare-dns.com/dns-query"
    "1.0.0.1"              = "https://cloudflare-dns.com/dns-query"
    "2606:4700:4700::1111" = "https://cloudflare-dns.com/dns-query"
    "2606:4700:4700::1001" = "https://cloudflare-dns.com/dns-query"
    "1.1.1.2"              = "https://security.cloudflare-dns.com/dns-query"
    "1.0.0.2"              = "https://security.cloudflare-dns.com/dns-query"
    "2606:4700:4700::1112" = "https://security.cloudflare-dns.com/dns-query"
    "2606:4700:4700::1002" = "https://security.cloudflare-dns.com/dns-query"
    "1.1.1.3"              = "https://family.cloudflare-dns.com/dns-query"
    "1.0.0.3"              = "https://family.cloudflare-dns.com/dns-query"
    "2606:4700:4700::1113" = "https://family.cloudflare-dns.com/dns-query"
    "2606:4700:4700::1003" = "https://family.cloudflare-dns.com/dns-query"
    "8.8.8.8"              = "https://dns.google/dns-query"
    "8.8.4.4"              = "https://dns.google/dns-query"
    "2001:4860:4860::8888" = "https://dns.google/dns-query"
    "2001:4860:4860::8844" = "https://dns.google/dns-query"
    "9.9.9.9"              = "https://dns.quad9.net/dns-query"
    "149.112.112.112"      = "https://dns.quad9.net/dns-query"
    "2620:fe::fe"          = "https://dns.quad9.net/dns-query"
    "2620:fe::9"           = "https://dns.quad9.net/dns-query"
    "194.242.2.2"          = "https://doh.mullvad.net/dns-query"
    "2a07:e340::2"         = "https://doh.mullvad.net/dns-query"
    "194.242.2.3"          = "https://adblock.doh.mullvad.net/dns-query"
    "2a07:e340::3"         = "https://adblock.doh.mullvad.net/dns-query"
    "194.242.2.4"          = "https://adblock.doh.mullvad.net/dns-query"
    "2a07:e340::4"         = "https://adblock.doh.mullvad.net/dns-query"
    "194.242.2.5"          = "https://adblock.doh.mullvad.net/dns-query"
    "2a07:e340::5"         = "https://adblock.doh.mullvad.net/dns-query"
    "194.242.2.6"          = "https://adblock.doh.mullvad.net/dns-query"
    "2a07:e340::6"         = "https://adblock.doh.mullvad.net/dns-query"
    "194.242.2.9"          = "https://adblock.doh.mullvad.net/dns-query"
    "2a07:e340::9"         = "https://adblock.doh.mullvad.net/dns-query"
    "45.90.28.0"           = "https://dns.nextdns.io/dns-query"
    "45.90.30.0"           = "https://dns.nextdns.io/dns-query"
    "2a07:a8c0::"          = "https://dns.nextdns.io/dns-query"
    "2a07:a8c1::"          = "https://dns.nextdns.io/dns-query"
}

# IPs de referencia para el test de latencia
$latencyTargets = [ordered]@{
    "Cloudflare Basic"      = "1.1.1.1"
    "Cloudflare Advanced"   = "1.1.1.2"
    "Cloudflare Family"     = "1.1.1.3"
    "Google DNS"            = "8.8.8.8"
    "Quad9"                 = "9.9.9.9"
    "OpenDNS Home"          = "208.67.222.222"
    "OpenDNS FamilyShield"  = "208.67.222.123"
    "Mullvad 1"             = "194.242.2.2"
    "Mullvad 2"             = "194.242.2.3"
    "Mullvad 3"             = "194.242.2.4"
    "Mullvad 6 (Extreme)"   = "194.242.2.9"
    "NextDNS"               = "45.90.28.0"
}
#endregion

#region ── Funciones Helper ───────────────────────────────────────────────────

function Write-Centered {
    param([string]$Text, [ConsoleColor]$Color = "White")
    $w   = $Host.UI.RawUI.WindowSize.Width
    $pad = [math]::Max(0, [math]::Floor(($w - $Text.Length) / 2))
    Write-Host ((" " * $pad) + $Text) -ForegroundColor $Color
}

function Press-AnyKey {
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message ($txt.Next.Trim())
        return
    }
    Write-Host ""
    Write-Host $txt.Next -ForegroundColor DarkGray
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        try { $null = Read-Host } catch {}
    }
}

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts | $Msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Get-PhysicalAdapters {
    return Get-NetAdapter -Physical | Where-Object {
        $_.InterfaceDescription -notmatch "Bluetooth" -and $_.Status -ne "Not Present"
    }
}

function Get-DNSStatusLines {
    $adapters = Get-PhysicalAdapters
    if (-not $adapters) { return @("  (no adapters)") }
    $lines = @()
    foreach ($a in $adapters) {
        $ipv4dns = (Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $dnsStr  = if ($ipv4dns) { ($ipv4dns | Select-Object -First 2) -join "  |  " } else { $txt.Auto }
        $status  = if ($a.Status -eq "Up") { "[UP] " } else { "[--] " }
        $color   = if ($a.Status -eq "Up") { "Green" } else { "DarkGray" }
        $lines  += @{ Text = "  $status$($a.Name.PadRight(20)) $dnsStr"; Color = $color }
    }
    return $lines
}

function Register-DoHTemplates {
    # RAIZ DEL BUG ANTERIOR: PowerShell registry provider interpreta '2606:' como
    # PSDrive al parsear rutas con IPv6 (ej: \DoHAddresses\2606:4700::1).
    # Fix: reg.exe llama directamente a la Win32 API — sin ese parsing de rutas,
    # soporta '::' en nombres de clave de registro sin ningun problema.
    param([string[]]$Addresses)
    $base = "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\DoHAddresses"

    foreach ($ip in $Addresses) {
        if (-not $dohTemplates.ContainsKey($ip)) { continue }
        $tmpl = $dohTemplates[$ip]
        & reg add "$base\$ip" /v DohTemplate       /t REG_SZ    /d $tmpl /f 2>&1 | Out-Null
        & reg add "$base\$ip" /v AutoUpgrade        /t REG_DWORD /d 1     /f 2>&1 | Out-Null
        & reg add "$base\$ip" /v AllowFallbackToUdp /t REG_DWORD /d 0     /f 2>&1 | Out-Null
        $ok = ($LASTEXITCODE -eq 0)
        Write-Host "    DoH global [$ip] $(if ($ok) { '[OK]' } else { '[FAIL]' })" `
            -ForegroundColor $(if ($ok) { 'DarkGray' } else { 'Red' })
    }
}

function Set-InterfaceDoH {
    # Per-interface DoH config. Uses reg.exe (Win32 API) so the registry
    # provider's '::' parsing bug for IPv6 keys doesn't bite.
    #
    # Microsoft's documented Win11 layout puts each IP under a Doh\ or
    # Doh6\ subkey:
    #   ...\InterfaceSpecificParameters\<GUID>\DohInterfaceSettings\Doh\<IPv4>
    #   ...\InterfaceSpecificParameters\<GUID>\DohInterfaceSettings\Doh6\<IPv6>
    # The previous version of this code wrote directly under
    # DohInterfaceSettings\<IP> (no Doh\ prefix). On builds that follow
    # the documented layout, those writes were ignored — the global
    # EnableAutoDoh=2 flag was set, which made our status read-back show
    # ENABLED, but Windows never picked up the per-interface templates so
    # actual DNS traffic still went over plaintext UDP. Write to BOTH
    # paths to cover legacy + current builds.
    param([string]$AdapterName, [string[]]$Addresses)
    try {
        $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop
        $guid    = $adapter.InterfaceGuid    # {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
        $idx     = $adapter.InterfaceIndex   # numero (ej: 5, 12)
        $iscBase = "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters"

        foreach ($ip in $Addresses) {
            if (-not $dohTemplates.ContainsKey($ip)) { continue }
            $tmpl = $dohTemplates[$ip]
            # Detect IPv4 vs IPv6 to pick the correct subkey name.
            $isV6 = $ip -match ':'
            $bucket = if ($isV6) { 'Doh6' } else { 'Doh' }
            # Try GUID and Index identifiers (Windows uses one or the
            # other depending on build) AND both layouts (with/without
            # Doh\ prefix) for maximum coverage.
            foreach ($id in @($guid, "$idx")) {
                foreach ($p in @(
                    "$iscBase\$id\DohInterfaceSettings\$bucket\$ip",
                    "$iscBase\$id\DohInterfaceSettings\$ip"
                )) {
                    & reg add $p /v DohTemplate       /t REG_SZ    /d $tmpl /f 2>&1 | Out-Null
                    & reg add $p /v AutoUpgrade       /t REG_DWORD /d 1     /f 2>&1 | Out-Null
                    & reg add $p /v AllowFallbackToUdp /t REG_DWORD /d 0    /f 2>&1 | Out-Null
                    # Newer Windows builds also read DohFlags (REG_QWORD).
                    # Bit 0 = enabled, bit 1 = require encrypted (no UDP
                    # fallback). Set both → 3.
                    & reg add $p /v DohFlags          /t REG_QWORD /d 3     /f 2>&1 | Out-Null
                }
            }
            $ok = ($LASTEXITCODE -eq 0)
            Write-Host "    DoH iface [$AdapterName][$ip] $(if ($ok) { '[OK]' } else { '[FAIL]' })" `
                -ForegroundColor $(if ($ok) { 'DarkGray' } else { 'Red' })
        }
    } catch {
        Write-Host "    DoH iface [$AdapterName] [FAIL] $_" -ForegroundColor Red
    }
}

function Apply-DNS {
    param(
        [string[]]$AdapterNames,
        [string[]]$Addresses,
        [string]$Label
    )
    Write-Host ""
    Write-Host "  $($txt.Applying)" -ForegroundColor Cyan

    # PASO 1 — registrar templates DoH globalmente via registro (IPv4 + IPv6)
    if ($Addresses.Count -gt 0) {
        Register-DoHTemplates -Addresses $Addresses
        # Activar DoH automatico: Windows usa los templates para todos los adaptadores
        $dohReg = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
        Set-ItemProperty -Path $dohReg -Name "EnableAutoDoh" -Value 2 -Type DWord `
            -ErrorAction SilentlyContinue
    }

    foreach ($n in $AdapterNames) {
        try {
            if ($Addresses.Count -eq 0) {
                Set-DnsClientServerAddress -InterfaceAlias $n -ResetServerAddresses -ErrorAction Stop
                Write-Host "  [OK] $($n.PadRight(22)) $($txt.OkAuto)" -ForegroundColor Green
                Write-Log "SET | $n | Automatic"
            } else {
                # PASO 2 — asignar IPs (-AddressFamily no existe en WinPS 5.1)
                Set-DnsClientServerAddress -InterfaceAlias $n -ServerAddresses $Addresses `
                    -ErrorAction Stop
                Write-Host "  [OK] $($n.PadRight(22)) $($txt.OkDNS) $Label" -ForegroundColor Green
                Write-Log "SET | $n | $Label | $($Addresses -join ', ')"

                # PASO 3 — escribir config DoH por interfaz via registro (GUID, no nombre)
                Set-InterfaceDoH -AdapterName $n -Addresses $Addresses
            }
        } catch {
            Write-Host "  [FAIL] $n -> $_" -ForegroundColor Red
            Write-Log "FAIL | $n | $Label | $_"
        }
    }

    Write-Host ""
    Write-Host "  $($txt.FlushDNS)" -ForegroundColor DarkGray
    Clear-DnsClientCache
    Write-Host "  $($txt.Done)" -ForegroundColor Green
}

function Select-AdapterNames {
    $all = Get-PhysicalAdapters
    if (-not $all) {
        Write-Host "`n  $($txt.ErrNoAdap)" -ForegroundColor Red
        return $null
    }
    Write-Host ""
    Write-Host "  $($txt.AdapHeader)" -ForegroundColor Cyan
    for ($i = 0; $i -lt $all.Count; $i++) {
        $st    = if ($all[$i].Status -eq "Up") { "[UP]" } else { "[--]" }
        $col   = if ($all[$i].Status -eq "Up") { "White" } else { "DarkGray" }
        Write-Host "  [$($i+1)] $st $($all[$i].Name.PadRight(20)) $($all[$i].InterfaceDescription)" -ForegroundColor $col
    }
    $allKey = if ($es) { "T" } else { "A" }
    Write-Host "  [$allKey] $($txt.AdapAll)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host -NoNewline $txt.AdapPrompt -ForegroundColor Yellow
    $sel = (Read-Host).Trim()
    if ($sel -match "^[TtAa]$") {
        return $all.Name
    }
    $idx = 0
    if ([int]::TryParse($sel, [ref]$idx) -and $idx -ge 1 -and $idx -le $all.Count) {
        return @($all[$idx - 1].Name)
    }
    Write-Host "`n  $($txt.ErrInv)" -ForegroundColor Red
    return $null
}

function Invoke-LatencyTest {
    Write-Host ""
    Write-Host "  $($txt.PingTesting)" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 58)) -ForegroundColor DarkGray
    Write-Host ("  " + "SERVER".PadRight(26) + "IP".PadRight(18) + "AVG LATENCY") -ForegroundColor DarkGray
    Write-Host ("  " + ("-" * 58)) -ForegroundColor DarkGray
    $results = @()
    foreach ($entry in $latencyTargets.GetEnumerator()) {
        Write-Host -NoNewline "  $($entry.Key.PadRight(26))$($entry.Value.PadRight(18))"
        try {
            $pings = Test-Connection -ComputerName $entry.Value -Count 3 -ErrorAction Stop
            # PowerShell 5.1: Test-Connection returns Win32_PingStatus
            # objects with the property `ResponseTime` (int, ms).
            # PowerShell 7+: returns PingStatus objects with `Latency`
            # (long, ms) instead. Pull whichever one exists; otherwise
            # the average comes back as 0 and every server reads 0 ms.
            $times = @($pings | ForEach-Object {
                if ($_.PSObject.Properties['Latency'] -and $null -ne $_.Latency) { [int]$_.Latency }
                elseif ($_.PSObject.Properties['ResponseTime'] -and $null -ne $_.ResponseTime) { [int]$_.ResponseTime }
            })
            if ($times.Count -eq 0) { throw 'No ping samples returned' }
            $avg   = [math]::Round(($times | Measure-Object -Average).Average, 1)
            $bar   = if ($avg -lt 20)  { "Green" }
                     elseif ($avg -lt 60) { "Yellow" }
                     else { "Red" }
            $block = if ($avg -lt 20)  { "[FAST]  " }
                     elseif ($avg -lt 60) { "[OK]    " }
                     else { "[SLOW]  " }
            Write-Host "$block$avg ms" -ForegroundColor $bar
            $results += [PSCustomObject]@{ Name=$entry.Key; IP=$entry.Value; Avg=$avg }
        } catch {
            Write-Host $txt.NoResp -ForegroundColor Red
            $results += [PSCustomObject]@{ Name=$entry.Key; IP=$entry.Value; Avg=99999 }
        }
    }
    Write-Host ("  " + ("-" * 58)) -ForegroundColor DarkGray
    $best = $results | Where-Object { $_.Avg -lt 99999 } | Sort-Object Avg | Select-Object -First 1
    if ($best) {
        Write-Host "`n  $($txt.Fastest): " -NoNewline -ForegroundColor White
        Write-Host "$($best.Name) [$($best.IP)] - $($best.Avg) ms" -ForegroundColor Green
        Write-Log "LATENCY TEST | Fastest: $($best.Name) [$($best.IP)] - $($best.Avg) ms"
    }
}

function Invoke-Backup {
    $adapters = Get-PhysicalAdapters
    if (-not $adapters) { Write-Host "`n  $($txt.ErrNoAdap)" -ForegroundColor Red; return }
    $backup = @{}
    foreach ($a in $adapters) {
        $v4 = (Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $v6 = (Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv6 -ErrorAction SilentlyContinue).ServerAddresses
        $backup[$a.Name] = @{ IPv4 = $v4; IPv6 = $v6 }
    }
    $backup | ConvertTo-Json -Depth 5 | Out-File -FilePath $backupFile -Encoding UTF8
    Write-Host ""
    Write-Host "  $($txt.BackupOk)" -ForegroundColor Green
    Write-Host "  $backupFile"       -ForegroundColor Cyan
    Write-Log "BACKUP SAVED | $backupFile"
}

function Invoke-Restore {
    if (-not (Test-Path $backupFile)) {
        Write-Host ""
        Write-Host "  $($txt.BackupNone)" -ForegroundColor Red
        Write-Host "  $backupFile"         -ForegroundColor DarkGray
        return
    }
    $backup = Get-Content $backupFile -Raw | ConvertFrom-Json
    Write-Host ""
    Write-Host "  $($txt.Applying)" -ForegroundColor Cyan
    foreach ($adapterName in $backup.PSObject.Properties.Name) {
        $v4 = $backup.$adapterName.IPv4
        try {
            if ($v4) {
                Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses $v4 -ErrorAction Stop
            } else {
                Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses -ErrorAction Stop
            }
            Write-Host "  [OK] $adapterName" -ForegroundColor Green
            Write-Log "RESTORE | $adapterName | IPv4: $($v4 -join ', ')"
        } catch {
            Write-Host "  [FAIL] $adapterName -> $_" -ForegroundColor Red
        }
    }
    Clear-DnsClientCache
    Write-Host ""
    Write-Host "  $($txt.RestoreOk)" -ForegroundColor Green
}

function Invoke-DoHToggle {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
    $current = (Get-ItemProperty -Path $regPath -Name "EnableAutoDoh" -ErrorAction SilentlyContinue).EnableAutoDoh
    Write-Host ""
    Write-Host "  $($txt.DoHStatus) " -NoNewline -ForegroundColor White
    if ($current -eq 2) { Write-Host $txt.DoHOn -ForegroundColor Green }
    else                 { Write-Host $txt.DoHOff -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "  [1] $($txt.DoHOn)" -ForegroundColor Green
    Write-Host "  [2] $($txt.DoHOff)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host -NoNewline $txt.DoHChoose -ForegroundColor Yellow
    $ans = (Read-Host).Trim()

    if ($ans -eq '1') {
        # — recolectar todas las IPs activas en cada adaptador
        $adapters   = Get-PhysicalAdapters
        $adapterDNS = @{}
        if ($adapters) {
            foreach ($a in $adapters) {
                $v4 = (Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
                $v6 = (Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv6 -ErrorAction SilentlyContinue).ServerAddresses
                $all = @()
                if ($v4) { $all += $v4 }
                if ($v6) { $all += $v6 }
                if ($all.Count -gt 0) { $adapterDNS[$a.Name] = $all }
            }
        }
        # — registrar templates globalmente via registro (IPv4 + IPv6)
        $allIPs = ($adapterDNS.Values | ForEach-Object { $_ } | Select-Object -Unique)
        if ($allIPs) {
            Write-Host "  (Registrando templates DoH...)" -ForegroundColor DarkGray
            Register-DoHTemplates -Addresses $allIPs
        }
        # — EnableAutoDoh = 2
        Set-ItemProperty -Path $regPath -Name "EnableAutoDoh" -Value 2 -Type DWord
        # — config DoH por interfaz via registro (GUID)
        foreach ($adName in $adapterDNS.Keys) {
            Set-InterfaceDoH -AdapterName $adName -Addresses $adapterDNS[$adName]
        }
        # Dnscache caches the DoH config in memory at service-start
        # time. Without restarting it the registry writes don't take
        # effect until the next reboot, so the read-back shows ENABLED
        # but actual DNS traffic still goes over plaintext UDP. Try a
        # restart; if it fails (locked, AV, etc.) fall back to the old
        # advice of "reboot to apply".
        try {
            Restart-Service -Name 'Dnscache' -Force -ErrorAction Stop
            Write-Host "  (Dnscache service restarted)" -ForegroundColor DarkGray
        } catch {
            Write-Host "  (Could not restart Dnscache; reboot to apply: $($_.Exception.Message))" -ForegroundColor DarkYellow
        }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Host "  -> $($txt.DoHOn)" -ForegroundColor Green
        Write-Log "DoH ENABLED"

    } elseif ($ans -eq '2') {
        Set-ItemProperty -Path $regPath -Name "EnableAutoDoh" -Value 0 -Type DWord
        try {
            Restart-Service -Name 'Dnscache' -Force -ErrorAction Stop
            Write-Host "  (Dnscache service restarted)" -ForegroundColor DarkGray
        } catch {
            Write-Host "  (Could not restart Dnscache; reboot to apply: $($_.Exception.Message))" -ForegroundColor DarkYellow
        }
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Write-Host "  -> $($txt.DoHOff)" -ForegroundColor Yellow
        Write-Log "DoH DISABLED"

    } else {
        Write-Host "`n  $($txt.ErrInv)" -ForegroundColor Red
        return
    }
    Write-Host "  $($txt.DoHNote)" -ForegroundColor DarkGray
}

function Invoke-StartupTask {
    $taskName     = "AtlasDNSSelector"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Write-Host ""
    if ($existingTask) {
        Write-Host "  " -NoNewline
        Write-Host -NoNewline $txt.TaskExists -ForegroundColor Yellow
        $ans = (Read-Host).Trim()
        if ($ans -match "^[SsYy]$") {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "  $($txt.TaskRemoved)" -ForegroundColor Yellow
            Write-Log "STARTUP TASK REMOVED"
        }
    } else {
        if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
            Write-Host "  [!] Startup task requires running the tool as a standalone .ps1 file." -ForegroundColor Yellow
            Write-Host "  [i] Launch directly via: pwsh -File Invoke-SelectorDNS.ps1" -ForegroundColor DarkGray
        } else {
            $scriptPath = $PSCommandPath
            $action     = New-ScheduledTaskAction -Execute "powershell.exe" `
                              -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
            $trigger    = New-ScheduledTaskTrigger -AtLogOn
            $settings   = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew
            $principal  = New-ScheduledTaskPrincipal -RunLevel Highest -LogonType Interactive
            Register-ScheduledTask -TaskName $taskName `
                -Action $action -Trigger $trigger -Settings $settings -Principal $principal `
                -Description "Atlas PC Support - DNS Selector auto-apply on logon" | Out-Null
            Write-Host "  $($txt.TaskCreated)" -ForegroundColor Green
            Write-Log "STARTUP TASK CREATED"
        }
    }
}

function Show-Log {
    Write-Host ""
    if (-not (Test-Path $logFile)) {
        Write-Host "  $($txt.LogEmpty)" -ForegroundColor DarkGray
        return
    }
    $lines = Get-Content $logFile -Tail 30
    if (-not $lines) {
        Write-Host "  $($txt.LogEmpty)" -ForegroundColor DarkGray
        return
    }
    Write-Host ("  " + ("-" * 64)) -ForegroundColor DarkGray
    foreach ($line in $lines) {
        $col = switch -Regex ($line) {
            "FAIL"    { "Red" }
            "BACKUP|RESTORE" { "Cyan" }
            "DoH"     { "Magenta" }
            "LATENCY" { "Yellow" }
            "TASK"    { "Blue" }
            default   { "Gray" }
        }
        Write-Host "  $line" -ForegroundColor $col
    }
    Write-Host ("  " + ("-" * 64)) -ForegroundColor DarkGray
    Write-Host "  $($txt.LogPath)$logFile" -ForegroundColor DarkGray
}

function Invoke-CustomDNS {
    Write-Host ""
    Write-Host -NoNewline $txt.CustomPrim -ForegroundColor Yellow
    $prim = (Read-Host).Trim()
    if (-not $prim) { Write-Host "  $($txt.ErrInv)" -ForegroundColor Red; return }
    Write-Host -NoNewline $txt.CustomSec -ForegroundColor Yellow
    $sec = (Read-Host).Trim()
    $addresses = if ($sec) { @($prim, $sec) } else { @($prim) }
    $label     = "Custom ($($addresses -join ' / '))"
    Write-Host ""
    Write-Host -NoNewline "  $($txt.CustomApply)" -ForegroundColor Yellow
    $ans = (Read-Host).Trim()
    if ($ans -match "^[SsYy]$") {
        $adapters = Get-PhysicalAdapters
        if (-not $adapters) { Write-Host "  $($txt.ErrNoAdap)" -ForegroundColor Red; return }
        Apply-DNS -AdapterNames $adapters.Name -Addresses $addresses -Label $label
    } else {
        $selected = Select-AdapterNames
        if ($selected) { Apply-DNS -AdapterNames $selected -Addresses $addresses -Label $label }
    }
}

function Invoke-PerAdapterDNS {
    Write-Host ""
    Write-Host "  $($txt.PromptDNSOpt)" -ForegroundColor Cyan
    foreach ($k in $dnsProfiles.Keys) {
        $label = $dnsProfiles[$k].Label
        Write-Host "  [$k] $label" -ForegroundColor White
    }
    Write-Host ""
    Write-Host -NoNewline "  >> " -ForegroundColor Yellow
    $dnsOpt = (Read-Host).Trim()
    if ($dnsProfiles.Keys -contains $dnsOpt) {
        $profile  = $dnsProfiles[$dnsOpt]
        $selected = Select-AdapterNames
        if ($selected) {
            Apply-DNS -AdapterNames $selected -Addresses $profile.Addr -Label $profile.Label
        }
    } elseif ($dnsOpt -eq '16') {
        Invoke-CustomDNS
    } else {
        Write-Host "`n  $($txt.ErrInv)" -ForegroundColor Red
    }
}

#endregion

#region ── Loop Principal ────────────────────────────────────────��───────────
do {
    Clear-Host
    $screenW  = $Host.UI.RawUI.WindowSize.Width
    $menuW    = 64
    $lm       = " " * [math]::Max(0, [math]::Floor(($screenW - $menuW) / 2))
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title 'ATLAS PC SUPPORT' -Color Yellow
        Write-AtlasStep ("DNS Selector {0}" -f $txt.VerStr)
        Write-Host ''
    } else {
        Write-Host ""
        Write-Centered "################################################################" "Yellow"
        Write-Centered "#                                                              #" "Yellow"
        Write-Centered "#           A T L A S   P C   S U P P O R T                  #" "Yellow"
        Write-Centered "#              DNS Selector  v2.0                             #" "Yellow"
        Write-Centered "#                                                              #" "Yellow"
        Write-Centered "################################################################" "Yellow"
        Write-Host ""
    }
    Write-Host "$lm[ $($txt.CurrentDNS) ]" -ForegroundColor DarkCyan
    $statusLines = Get-DNSStatusLines
    foreach ($sl in $statusLines) {
        Write-Host "$lm$($sl.Text)" -ForegroundColor $sl.Color
    }
    Write-Host ""
    Write-Host "$lm$($txt.Opt1)" -ForegroundColor Green
    Write-Host ""
    Write-Host "$lm$($txt.HeaderCF)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt2)"
    Write-Host "$lm$($txt.Opt3)"
    Write-Host "$lm$($txt.Opt4)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderGG)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt5)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderQ9)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt6)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderOD)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt7)"
    Write-Host "$lm$($txt.Opt8)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderMV)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt9)"
    Write-Host "$lm$($txt.Opt10)"
    Write-Host "$lm$($txt.Opt11)"
    Write-Host "$lm$($txt.Opt12)"
    Write-Host "$lm$($txt.Opt13)"
    Write-Host "$lm$($txt.Opt14)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderND)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt15)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderCU)" -ForegroundColor Cyan
    Write-Host "$lm$($txt.Opt16)"
    Write-Host ""
    Write-Host "$lm$($txt.HeaderTools)" -ForegroundColor Magenta
    Write-Host "$lm$($txt.Opt17)"
    Write-Host "$lm$($txt.Opt18)"
    Write-Host "$lm$($txt.Opt19)"
    Write-Host "$lm$($txt.Opt20)"
    Write-Host "$lm$($txt.Opt21)"
    Write-Host "$lm$($txt.Opt22)"
    Write-Host "$lm$($txt.Opt23)"
    Write-Host "$lm$($txt.Opt24)"
    Write-Host ""
    Write-Host "$lm$($txt.Opt0)" -ForegroundColor Red
    Write-Host ""
    Write-Host -NoNewline "$lm$($txt.Prompt): " -ForegroundColor Yellow
    $rawMenu = Read-Host
    if ($null -eq $rawMenu) { $rawMenu = "" }
    $opcion = $rawMenu.Trim()
    if ($opcion -eq '0') { break }
    if ([string]::IsNullOrWhiteSpace($opcion)) {
        Write-Host "`n  $($txt.ErrBlank)" -ForegroundColor Red
        Press-AnyKey
        continue
    }
    switch ($opcion) {
        { $dnsProfiles.Keys -contains $_ } {
            $profile  = $dnsProfiles[$opcion]
            $adapters = Get-PhysicalAdapters
            if (-not $adapters) {
                Write-Host "`n  $($txt.ErrNoAdap)" -ForegroundColor Red
            } else {
                Apply-DNS -AdapterNames $adapters.Name -Addresses $profile.Addr -Label $profile.Label
            }
        }
        '16' { Invoke-CustomDNS }
        '17' { Invoke-LatencyTest }
        '18' { Invoke-Backup }
        '19' { Invoke-Restore }
        '20' { Invoke-DoHToggle }
        '21' { Invoke-StartupTask }
        '22' { Show-Log }
        '23' { Invoke-PerAdapterDNS }
        '24' {
            Write-Host "`n  $($txt.Opening)" -ForegroundColor Magenta
            Start-Process "https://www.cloudflare.com/ssl/encrypted-sni/"
        }
        default {
            if ($opcion -ne '') {
                Write-Host "`n  $($txt.ErrInv)" -ForegroundColor Red
            }
        }
    }
    Press-AnyKey
} while ($true)
Write-Host ""
Write-Centered "$(if ($es) { 'Gracias por usar Atlas PC Support. Hasta luego!' } else { 'Thank you for using Atlas PC Support. Goodbye!' })" "Yellow"
Write-Host ""
#endregion
}
