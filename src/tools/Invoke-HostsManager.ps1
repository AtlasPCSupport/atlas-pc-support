# ============================================================
# Invoke-HostsManager  ->  Hosts File Editor
#
# i18n: Option A (en default + full es secondary). Function name
# kept as Invoke-HostsManager for tools.json compatibility.
#
# Atlas PC Support
# ============================================================

function Invoke-HostsManager {
    [CmdletBinding()]
    param()

    # --- Language detection ---
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

    $T = @{
        en = @{
            WinTitle      = 'ATLAS PC SUPPORT - HOSTS FILE EDITOR'
            Header        = 'ATLAS PC SUPPORT - HOSTS FILE EDITOR'
            PathLabel     = 'Path:  {0}'
            AdminLabel    = 'Admin: {0}'
            AdminYes      = 'YES'
            AdminNo       = 'NO (writes will fail)'
            Options       = 'Options:'
            Opt1          = '[1] View current contents'
            Opt2          = '[2] Backup with timestamp'
            Opt3          = '[3] Add entry (IP + name)'
            Opt4          = '[4] Remove lines containing a name'
            Opt5          = '[5] Open in Notepad (admin)'
            Opt6          = '[6] Restore default (auto-backup first)'
            OptAdv        = '--- ADVANCED ---'
            Opt7          = '[7] Export hosts to Desktop'
            Opt8          = '[8] Import hosts from file (with backup)'
            Opt9          = '[9] Apply StevenBlack ads/tracking (separate, with backup)'
            OptR          = '[R] Revert StevenBlack (restore pre-application)'
            OptQ          = '[Q] Quit'
            SelectPrompt  = 'Selection'
            NotExist      = '(does not exist)'
            EnterCont     = 'Enter to continue'
            BackupCreated = 'Backup created: {0}'
            ErrPrefix     = 'Error: {0}'
            IPLabel       = 'IP'
            NameLabel     = 'Host name'
            Added         = 'Added: {0}  {1}'
            ErrAdmin      = 'Error (need admin?): {0}'
            CancelEmpty   = 'Cancelled (empty IP or name).'
            DelPrompt     = 'Name to remove (lines containing it)'
            Removed       = 'Removed {0} line(s) containing "{1}".'
            NotepadOpen   = 'Notepad opened (in elevated window).'
            ConfirmReset  = 'This OVERWRITES hosts. Confirm? [y/N]'
            Restored      = 'hosts restored. Previous backup at: {0}'
            ErrAdmin2     = 'Error (need admin): {0}'
            Exported      = 'Exported: {0}'
            ImportPrompt  = 'Full path of hosts file to import (drag into CMD and Enter)'
            FileNotFound  = 'File not found.'
            ConfirmImport = 'This will OVERWRITE current hosts (a backup will be made). Confirm? [y/N]'
            Imported      = 'Imported. Previous backup: {0}'
            SBHeader      = '=== STEVENBLACK HOSTS - ads/tracking blocking ==='
            SBSource      = 'Official source: https://github.com/StevenBlack/hosts'
            SBChoose      = 'List to apply:'
            SBOpt1        = '[1] unified (ads + malware)'
            SBOpt2        = '[2] ads + malware + fakenews'
            SBOpt3        = '[3] ads + malware + fakenews + gambling + social'
            SBOpt0        = '[0] Cancel'
            SBCancelled   = 'Cancelled. Enter'
            SBNote1       = '[!] An automatic backup of your current hosts will be made'
            SBNote2       = '    in the SAME folder (hosts.atlas-pre-stevenblack.<timestamp>)'
            SBNote3       = '    so you can revert with option [R].'
            SBContinue    = 'Continue and download the list? [y/N]'
            SBBackupOK    = 'Backup ready: {0}'
            SBDownloading = 'Downloading list...'
            SBEmpty       = 'Download empty or too small.'
            SBApplied     = '[OK] StevenBlack applied. DNS cache flushed.'
            SBSuggest     = 'Hint: check connection, admin perms, or try again.'
            SBNoBackup    = 'No StevenBlack backup recorded.'
            SBBackupGone  = 'Recorded backup does not exist: {0}'
            SBWillRestore = 'Will restore: {0}'
            SBConfirm     = 'Confirm? [y/N]'
            SBRestored    = '[OK] Restored. DNS cache flushed.'
            SBPostBackup  = '(Backup of post-StevenBlack state: {0})'
            HostsDefault  = "# Copyright (c) 1993-2009 Microsoft Corp.`n#`n# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.`n#`n# Localhost name resolution is handled within DNS itself.`n#`t127.0.0.1`tlocalhost`n#`t::1`tlocalhost"
            CommentTag    = 'Atlas-added'
        }
        es = @{
            WinTitle      = 'ATLAS PC SUPPORT - GESTOR HOSTS'
            Header        = 'ATLAS PC SUPPORT - GESTOR DEL ARCHIVO HOSTS'
            PathLabel     = 'Ruta:  {0}'
            AdminLabel    = 'Admin: {0}'
            AdminYes      = 'SI'
            AdminNo       = 'NO (las escrituras fallaran)'
            Options       = 'Opciones:'
            Opt1          = '[1] Ver contenido actual'
            Opt2          = '[2] Hacer backup con timestamp'
            Opt3          = '[3] Agregar entrada (IP + nombre)'
            Opt4          = '[4] Eliminar lineas que contengan un nombre'
            Opt5          = '[5] Abrir en Notepad (admin)'
            Opt6          = '[6] Restaurar default (backup automatico previo)'
            OptAdv        = '--- AVANZADO ---'
            Opt7          = '[7] Exportar hosts a Escritorio'
            Opt8          = '[8] Importar hosts desde archivo (con backup)'
            Opt9          = '[9] Aplicar StevenBlack ads/tracking (separado, con backup)'
            OptR          = '[R] Revertir StevenBlack (restaurar pre-aplicacion)'
            OptQ          = '[Q] Salir'
            SelectPrompt  = 'Seleccion'
            NotExist      = '(no existe)'
            EnterCont     = 'Enter para continuar'
            BackupCreated = 'Backup creado: {0}'
            ErrPrefix     = 'Error: {0}'
            IPLabel       = 'IP'
            NameLabel     = 'Nombre host'
            Added         = 'Agregada: {0}  {1}'
            ErrAdmin      = 'Error (necesita admin?): {0}'
            CancelEmpty   = 'Cancelado (IP o nombre vacios).'
            DelPrompt     = 'Nombre a eliminar (lineas que lo contengan)'
            Removed       = 'Eliminadas {0} linea(s) que contenian "{1}".'
            NotepadOpen   = 'Notepad abierto (en nueva ventana elevada).'
            ConfirmReset  = 'Esto SOBREESCRIBE hosts. Confirmar? [s/N]'
            Restored      = 'hosts restaurado. Backup previo en: {0}'
            ErrAdmin2     = 'Error (necesita admin): {0}'
            Exported      = 'Exportado: {0}'
            ImportPrompt  = 'Ruta completa del archivo hosts a importar (arrastra al CMD y Enter)'
            FileNotFound  = 'Archivo no encontrado.'
            ConfirmImport = 'Esto SOBREESCRIBIRA hosts actual (se hara backup). Confirmar? [s/N]'
            Imported      = 'Importado. Backup previo: {0}'
            SBHeader      = '=== STEVENBLACK HOSTS - Bloqueo ads/tracking ==='
            SBSource      = 'Fuente oficial: https://github.com/StevenBlack/hosts'
            SBChoose      = 'Lista a aplicar:'
            SBOpt1        = '[1] unified (ads + malware)'
            SBOpt2        = '[2] ads + malware + fakenews'
            SBOpt3        = '[3] ads + malware + fakenews + gambling + social'
            SBOpt0        = '[0] Cancelar'
            SBCancelled   = 'Cancelado. Enter'
            SBNote1       = '[!] Se hara backup automatico de tu hosts actual'
            SBNote2       = '    en la MISMA carpeta (hosts.atlas-pre-stevenblack.<timestamp>)'
            SBNote3       = '    para que puedas revertir con la opcion [R].'
            SBContinue    = 'Continuar y descargar la lista? [s/N]'
            SBBackupOK    = 'Backup listo: {0}'
            SBDownloading = 'Descargando lista...'
            SBEmpty       = 'Descarga vacia o demasiado pequena.'
            SBApplied     = '[OK] StevenBlack aplicado. DNS cache purgada.'
            SBSuggest     = 'Sugerencia: verifica conexion, permisos admin, o intenta de nuevo.'
            SBNoBackup    = 'No hay backup de StevenBlack registrado.'
            SBBackupGone  = 'Backup registrado no existe: {0}'
            SBWillRestore = 'Se restaurara: {0}'
            SBConfirm     = 'Confirmar? [s/N]'
            SBRestored    = '[OK] Restaurado. DNS cache purgada.'
            SBPostBackup  = '(Backup del estado con StevenBlack: {0})'
            HostsDefault  = "# Copyright (c) 1993-2009 Microsoft Corp.`n#`n# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.`n#`n# Localhost name resolution is handled within DNS itself.`n#`t127.0.0.1`tlocalhost`n#`t::1`tlocalhost"
            CommentTag    = 'Atlas-added'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    $hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'

    try { $Host.UI.RawUI.WindowTitle = $L.WinTitle } catch {}

    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    function Pause-HostsManager {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

    function Show-HMHeader {
        Clear-Host
        Write-Host ""
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title $L.Header -Color Yellow
        } else {
            Write-Host "  =================================================" -ForegroundColor DarkGray
            Write-Host ('   ' + $L.Header) -ForegroundColor Yellow
            Write-Host "  =================================================" -ForegroundColor DarkGray
        }
        Write-Host ('  ' + ($L.PathLabel -f $hostsPath)) -ForegroundColor Gray
        $adminText = if ($isAdmin) { $L.AdminYes } else { $L.AdminNo }
        Write-Host ('  ' + ($L.AdminLabel -f $adminText)) -ForegroundColor $(if ($isAdmin) { 'Green' } else { 'Yellow' })
        Write-Host ""
    }

    do {
        Show-HMHeader
        Write-Host ('  ' + $L.Options) -ForegroundColor Cyan
        Write-Host ('    ' + $L.Opt1)
        Write-Host ('    ' + $L.Opt2)
        Write-Host ('    ' + $L.Opt3)
        Write-Host ('    ' + $L.Opt4)
        Write-Host ('    ' + $L.Opt5)
        Write-Host ('    ' + $L.Opt6)
        Write-Host ('    ' + $L.OptAdv) -ForegroundColor Cyan
        Write-Host ('    ' + $L.Opt7)
        Write-Host ('    ' + $L.Opt8)
        Write-Host ('    ' + $L.Opt9) -ForegroundColor Yellow
        Write-Host ('    ' + $L.OptR) -ForegroundColor Yellow
        Write-Host ('    ' + $L.OptQ)
        Write-Host ""
        $sel = Read-Host ('  ' + $L.SelectPrompt)

        switch ($sel) {
            '1' {
                Write-Host ""
                if (Test-Path $hostsPath) {
                    Get-Content $hostsPath | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
                } else {
                    Write-Host ('  ' + $L.NotExist) -ForegroundColor Red
                }
                Write-Host ""
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '2' {
                try {
                    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
                    $backup = Join-Path (Split-Path $hostsPath) "hosts.backup.$stamp"
                    Copy-Item $hostsPath $backup -Force
                    Write-Host ""
                    Write-Host ('  ' + ($L.BackupCreated -f $backup)) -ForegroundColor Green
                } catch {
                    Write-Host ('  ' + ($L.ErrPrefix -f $_.Exception.Message)) -ForegroundColor Red
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '3' {
                $ip   = Read-Host ('  ' + $L.IPLabel)
                $name = Read-Host ('  ' + $L.NameLabel)
                if ($ip -and $name) {
                    try {
                        $line = "{0}`t{1}`t# {2} {3}" -f $ip, $name, $L.CommentTag, (Get-Date -Format 'yyyy-MM-dd')
                        Add-Content -Path $hostsPath -Value "`r`n$line" -Encoding UTF8
                        Write-Host ('  ' + ($L.Added -f $ip, $name)) -ForegroundColor Green
                    } catch {
                        Write-Host ('  ' + ($L.ErrAdmin -f $_.Exception.Message)) -ForegroundColor Red
                    }
                } else {
                    Write-Host ('  ' + $L.CancelEmpty) -ForegroundColor Yellow
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '4' {
                $name = Read-Host ('  ' + $L.DelPrompt)
                if ($name) {
                    try {
                        $pattern = [regex]::Escape($name)
                        $content = Get-Content $hostsPath
                        $kept    = $content | Where-Object { $_ -notmatch $pattern }
                        $deleted = $content.Count - $kept.Count
                        Set-Content -Path $hostsPath -Value $kept -Encoding UTF8
                        Write-Host ('  ' + ($L.Removed -f $deleted, $name)) -ForegroundColor Green
                    } catch {
                        Write-Host ('  ' + ($L.ErrAdmin -f $_.Exception.Message)) -ForegroundColor Red
                    }
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '5' {
                try {
                    Start-Process notepad.exe -ArgumentList $hostsPath -Verb RunAs
                    Write-Host ('  ' + $L.NotepadOpen) -ForegroundColor Green
                } catch {
                    Write-Host ('  ' + ($L.ErrPrefix -f $_.Exception.Message)) -ForegroundColor Red
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '6' {
                $ok = Read-Host ('  ' + $L.ConfirmReset)
                if ($ok -match '^[sSyY]$') {
                    try {
                        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                        $before = Join-Path (Split-Path $hostsPath) "hosts.before-reset.$stamp"
                        Copy-Item $hostsPath $before -Force
                        Set-Content -Path $hostsPath -Value $L.HostsDefault -Encoding UTF8
                        Write-Host ('  ' + ($L.Restored -f $before)) -ForegroundColor Green
                    } catch {
                        Write-Host ('  ' + ($L.ErrAdmin2 -f $_.Exception.Message)) -ForegroundColor Red
                    }
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '7' {
                try {
                    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                    $out = Join-Path ([Environment]::GetFolderPath('Desktop')) "hosts.atlas.$stamp.txt"
                    Copy-Item $hostsPath $out -Force
                    Write-Host ""
                    Write-Host ('  ' + ($L.Exported -f $out)) -ForegroundColor Green
                } catch {
                    Write-Host ('  ' + ($L.ErrPrefix -f $_.Exception.Message)) -ForegroundColor Red
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '8' {
                $src = Read-Host ('  ' + $L.ImportPrompt)
                $src = $src.Trim('"').Trim("'")
                if (-not (Test-Path $src)) {
                    Write-Host ('  ' + $L.FileNotFound) -ForegroundColor Red
                    Pause-HostsManager -Message ('  ' + $L.EnterCont)
                    continue
                }
                $ok = Read-Host ('  ' + $L.ConfirmImport)
                if ($ok -match '^[sSyY]$') {
                    try {
                        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                        $before = Join-Path (Split-Path $hostsPath) "hosts.before-import.$stamp"
                        Copy-Item $hostsPath $before -Force
                        Copy-Item $src $hostsPath -Force
                        Write-Host ('  ' + ($L.Imported -f $before)) -ForegroundColor Green
                    } catch {
                        Write-Host ('  ' + ($L.ErrAdmin2 -f $_.Exception.Message)) -ForegroundColor Red
                    }
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            '9' {
                Write-Host ""
                Write-Host ('  ' + $L.SBHeader) -ForegroundColor Yellow
                Write-Host ('  ' + $L.SBSource) -ForegroundColor DarkGray
                Write-Host ""
                Write-Host ('  ' + $L.SBChoose) -ForegroundColor Cyan
                Write-Host ('    ' + $L.SBOpt1) -ForegroundColor White
                Write-Host ('    ' + $L.SBOpt2) -ForegroundColor White
                Write-Host ('    ' + $L.SBOpt3) -ForegroundColor White
                Write-Host ('    ' + $L.SBOpt0) -ForegroundColor DarkGray
                $lsel = Read-Host ('  ' + $L.SelectPrompt)
                $url = switch ($lsel) {
                    '1' { 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts' }
                    '2' { 'https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts' }
                    '3' { 'https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts' }
                    default { $null }
                }
                if (-not $url) {
                    Pause-HostsManager -Message ('  ' + $L.SBCancelled)
                    continue
                }
                Write-Host ""
                Write-Host ('  ' + $L.SBNote1) -ForegroundColor Yellow
                Write-Host ('  ' + $L.SBNote2) -ForegroundColor Yellow
                Write-Host ('  ' + $L.SBNote3) -ForegroundColor Yellow
                Write-Host ""
                $ok = Read-Host ('  ' + $L.SBContinue)
                if ($ok -notmatch '^[sSyY]$') { Pause-HostsManager -Message ('  ' + $L.SBCancelled); continue }
                try {
                    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                    $before = Join-Path (Split-Path $hostsPath) "hosts.atlas-pre-stevenblack.$stamp"
                    Copy-Item $hostsPath $before -Force
                    $ptrFile = Join-Path $env:LOCALAPPDATA 'AtlasPC\hosts-last-stevenblack-backup.txt'
                    if (-not (Test-Path (Split-Path $ptrFile))) { New-Item -ItemType Directory -Path (Split-Path $ptrFile) -Force | Out-Null }
                    Set-Content -Path $ptrFile -Value $before -Encoding UTF8
                    Write-Host ('  ' + ($L.SBBackupOK -f $before)) -ForegroundColor Green
                    Write-Host ('  ' + $L.SBDownloading) -ForegroundColor Cyan
                    $tmp = Join-Path $env:TEMP "atlas-stevenblack-$stamp.txt"
                    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 60
                    if (-not (Test-Path $tmp) -or (Get-Item $tmp).Length -lt 1000) {
                        throw $L.SBEmpty
                    }
                    $userLines = Get-Content $hostsPath
                    $marker = "# === ATLAS StevenBlack applied $stamp ==="
                    $new = @()
                    $new += $userLines
                    $new += ""
                    $new += $marker
                    $new += (Get-Content $tmp)
                    Set-Content -Path $hostsPath -Value $new -Encoding UTF8
                    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
                    try { ipconfig /flushdns | Out-Null } catch {}
                    Write-Host ('  ' + $L.SBApplied) -ForegroundColor Green
                } catch {
                    Write-Host ('  ' + ($L.ErrPrefix -f $_.Exception.Message)) -ForegroundColor Red
                    Write-Host ('  ' + $L.SBSuggest) -ForegroundColor Yellow
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            { $_ -match '^[rR]$' } {
                $ptrFile = Join-Path $env:LOCALAPPDATA 'AtlasPC\hosts-last-stevenblack-backup.txt'
                if (-not (Test-Path $ptrFile)) {
                    Write-Host ('  ' + $L.SBNoBackup) -ForegroundColor Yellow
                    Pause-HostsManager -Message ('  ' + $L.EnterCont)
                    continue
                }
                $backupPath = (Get-Content $ptrFile -Raw).Trim()
                if (-not (Test-Path $backupPath)) {
                    Write-Host ('  ' + ($L.SBBackupGone -f $backupPath)) -ForegroundColor Red
                    Pause-HostsManager -Message ('  ' + $L.EnterCont)
                    continue
                }
                Write-Host ""
                Write-Host ('  ' + ($L.SBWillRestore -f $backupPath)) -ForegroundColor Cyan
                $ok = Read-Host ('  ' + $L.SBConfirm)
                if ($ok -match '^[sSyY]$') {
                    try {
                        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                        $bumpBefore = Join-Path (Split-Path $hostsPath) "hosts.before-revert-stevenblack.$stamp"
                        Copy-Item $hostsPath $bumpBefore -Force
                        Copy-Item $backupPath $hostsPath -Force
                        try { ipconfig /flushdns | Out-Null } catch {}
                        Write-Host ('  ' + $L.SBRestored) -ForegroundColor Green
                        Write-Host ('  ' + ($L.SBPostBackup -f $bumpBefore)) -ForegroundColor DarkGray
                    } catch {
                        Write-Host ('  ' + ($L.ErrAdmin2 -f $_.Exception.Message)) -ForegroundColor Red
                    }
                }
                Pause-HostsManager -Message ('  ' + $L.EnterCont)
            }
            { $_ -match '^[qQ]$' } { return }
        }
    } while ($true)
}
