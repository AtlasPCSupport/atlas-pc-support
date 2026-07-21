# ============================================================
# Invoke-EntregaPC  ->  PC Handover Report
#
# i18n: Option A (en default + full es secondary). Function name
# kept as Invoke-EntregaPC for tools.json compatibility.
# ============================================================

function Invoke-EntregaPC {
    [CmdletBinding()]
    param()

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
            NeedAdmin1   = 'WARNING: This script needs Administrator permissions.'
            NeedAdmin2   = "Right-click the file and select 'Run with PowerShell' as administrator."
            HeaderSub    = '        P C   S U P P O R T              '
            HdrBar       = '========================================='
            CfgUser      = '--- CONFIGURING CURRENT USER: [{0}] ---'
            CancelHint   = "   (Type '0' at any time to cancel and go back)"
            AskFullName  = "   -> Customer's full name"
            AskPwdHint   = '   -> Password (type blindly and press ENTER. Leave blank to NOT use a password)'
            AskPwdLbl    = '      Password'
            UpdName      = '   [OK] Display name updated to: {0}'
            UpdPwd       = '   [OK] Password set.'
            NoPwd        = '   [OK] Account kept without a password.'
            ErrFmt       = '   [ERROR] {0}'
            ReturnHint   = "`n   Press ENTER to return to the main menu..."
            CreateUser   = '--- CREATING NEW USER ---'
            AskNewLogon  = '   -> Internal account name (e.g. jorge, no spaces)'
            AskNewDisp   = '   -> Display name (e.g. Jorge Martinez)'
            AskAdmin     = '   -> Make this user an Administrator? (Y/N)'
            UserCreated  = "   [OK] User '{0}' created."
            GrantedAdm   = '   [OK] Administrator permissions granted.'
            GrantedStd   = '   [OK] Standard user permissions granted.'
            RenameTitle  = '--- RENAME COMPUTER ---'
            CurrName     = '   Current name: {0}'
            AskNewName   = '   -> New name (0 to cancel)'
            BadName      = "`n   [ERROR] Invalid name. Only A-Z 0-9 and dash, max 15."
            EnterBack    = "`n   ENTER to go back"
            NameOk       = '   [OK] Name changed to: {0}'
            NeedReboot   = '   You must reboot the computer to apply.'
            BuildingHtml = '--- GENERATING HANDOVER CHECKLIST (HTML) ---'
            Gathering    = '   Gathering computer information...'
            ErrEquipo    = "Error getting computer info: {0}"
            ErrAct       = "Could not query activation."
            ErrUsers     = 'User list error: {0}'
            ErrDisks     = 'Disk error: {0}'
            BLNotAvail   = 'BitLocker not available: {0}'
            ErrVols      = 'Volume error: {0}'
            ErrHotfix    = 'HotFix error: {0}'
            NoNet        = 'No active interfaces.'
            HtmlSavedOk  = '   [OK] HTML report saved at:'
            OpeningBrw   = '   Opening in browser...'
            CouldNotSave = '   [ERROR] Could not save: {0}'
            HtmlLang     = 'en'
            HtmlTitle    = '{0} - Handover Checklist - {1}'
            HtmlSubTitle = 'Handover Checklist - {0}'
            HtmlMeta     = 'Generated: {0} - Operator: {1}'
            HtmlSecEquipo= 'Computer'
            HtmlSecAct   = 'Windows Activation'
            HtmlSecUsers = 'Users'
            HtmlULocal   = 'Enabled local accounts'
            HtmlUAdmin   = 'Administrators'
            HtmlSecBL    = 'BitLocker'
            HtmlBLNote   = 'Save Recovery Keys somewhere outside the PC (password manager, signed printout, customer folder).'
            HtmlSecDisks = 'Physical disks'
            HtmlVolumes  = 'Volumes'
            HtmlSecNet   = 'Network'
            HtmlSecDef   = 'Windows Defender'
            HtmlSecHF    = 'Latest updates (top 10)'
            HtmlSecChk   = 'Manual pre-handover checklist'
            HtmlSecSig   = 'Signatures'
            HtmlSigTech  = 'Technician signature'
            HtmlSigCust  = 'Customer signature'
            HtmlDateLine = 'Handover date: ____________________'
            HtmlFooter   = 'Atlas PC Support - Report generated automatically - Save this file or print to PDF for the record'
            BtnPrint     = '[Print / Save PDF]'
            BtnCheckAll  = '[Check all]'
            ColModel     = 'Model'
            ColSerial    = 'Serial'
            ColSize      = 'Size'
            ColHealth    = 'Health'
            ColType      = 'Type'
            ColDrive     = 'Drive'
            ColLabel     = 'Label'
            ColFree      = 'Free'
            ColTotal     = 'Total'
            ColFs        = 'FS'
            ColHotfix    = 'HotFix'
            ColInstalled = 'Installed'
            ColTypeKB    = 'Type'
            RowName      = 'Name'
            RowMaker     = 'Manufacturer'
            RowModel     = 'Model'
            RowBios      = 'BIOS Serial'
            RowOs        = 'OS'
            RowVer       = 'Version'
            RowBuild     = 'Build'
            RowArch      = 'Architecture'
            RowRam       = 'Total RAM'
            RowAvOn      = 'AV Enabled'
            RowAvRT      = 'RealTime Protection'
            RowAvSig     = 'AV Signature'
            ChkItems     = @(
                'Hardware tested (display, keyboard, touch, audio, USB, webcam, fingerprint)',
                'Battery at 100% and charger included',
                'Antivirus active and up to date',
                'BitLocker enabled and recovery key saved in a safe place',
                'Windows Update up to date',
                'Browser clean (no technician accounts saved)',
                'Customer account created with the correct name',
                'Password handed over physically or via secure channel',
                'Customer informed about warranty and contact',
                'Computer cleaned (dust, screen, keyboard)',
                'Customer documents recovered and restored',
                'Customer-requested programs installed'
            )
            MainOpt1     = '[ 1 ]  Hand over computer (current user: {0})'
            MainOpt2     = '[ 2 ]  Create an additional new user'
            MainOpt3     = '[ 3 ]  Rename computer'
            MainOpt4     = '[ 4 ]  Generate HANDOVER CHECKLIST (report)'
            MainOpt5     = '[ 5 ]  Quit and close tool'
            MainPrompt   = 'Select an option [1-5]'
            BadOption    = 'Invalid option.'
        }
        es = @{
            NeedAdmin1   = 'ATENCION: Este script necesita permisos de Administrador.'
            NeedAdmin2   = "Haz clic derecho en el archivo y selecciona 'Ejecutar con PowerShell' como administrador."
            HeaderSub    = '        P C   S U P P O R T              '
            HdrBar       = '========================================='
            CfgUser      = '--- CONFIGURANDO USUARIO ACTUAL: [{0}] ---'
            CancelHint   = "   (Escriba '0' en cualquier momento para cancelar y volver)"
            AskFullName  = '   -> Nombre y apellido del cliente'
            AskPwdHint   = '   -> Contrasena (Escriba a ciegas y presione ENTER. Deje en blanco para NO usar clave)'
            AskPwdLbl    = '      Clave'
            UpdName      = '   [OK] Nombre actualizado a: {0}'
            UpdPwd       = '   [OK] Contrasena establecida.'
            NoPwd        = '   [OK] El usuario se mantiene sin contrasena.'
            ErrFmt       = '   [ERROR] {0}'
            ReturnHint   = "`n   Presione ENTER para volver al menu principal..."
            CreateUser   = '--- CREANDO NUEVO USUARIO ---'
            AskNewLogon  = '   -> Nombre interno de la cuenta (ej. jorge, sin espacios)'
            AskNewDisp   = '   -> Nombre completo para la pantalla (ej. Jorge Martinez)'
            AskAdmin     = '   -> Hacer a este usuario Administrador? (S/N)'
            UserCreated  = "   [OK] Usuario '{0}' creado correctamente."
            GrantedAdm   = '   [OK] Permisos de Administrador concedidos.'
            GrantedStd   = '   [OK] Permisos de Usuario Estandar concedidos.'
            RenameTitle  = '--- RENOMBRAR EQUIPO ---'
            CurrName     = '   Nombre actual: {0}'
            AskNewName   = '   -> Nuevo nombre (0 para cancelar)'
            BadName      = "`n   [ERROR] Nombre invalido. Solo A-Z 0-9 y guion, max 15."
            EnterBack    = "`n   ENTER para volver"
            NameOk       = '   [OK] Nombre cambiado a: {0}'
            NeedReboot   = '   Debe reiniciar el equipo para aplicar.'
            BuildingHtml = '--- GENERANDO CHECKLIST DE ENTREGA (HTML) ---'
            Gathering    = '   Recopilando informacion del equipo...'
            ErrEquipo    = 'Error obteniendo info equipo: {0}'
            ErrAct       = 'No se pudo consultar activacion.'
            ErrUsers     = 'Error usuarios: {0}'
            ErrDisks     = 'Error discos: {0}'
            BLNotAvail   = 'BitLocker no disponible: {0}'
            ErrVols      = 'Error volumenes: {0}'
            ErrHotfix    = 'Error HotFix: {0}'
            NoNet        = 'Sin interfaces activas.'
            HtmlSavedOk  = '   [OK] Reporte HTML guardado en:'
            OpeningBrw   = '   Abriendo en navegador...'
            CouldNotSave = '   [ERROR] No se pudo guardar: {0}'
            HtmlLang     = 'es'
            HtmlTitle    = '{0} - Checklist Entrega - {1}'
            HtmlSubTitle = 'Checklist de Entrega &mdash; {0}'
            HtmlMeta     = 'Generado: {0} &middot; Operador: {1}'
            HtmlSecEquipo= 'Equipo'
            HtmlSecAct   = 'Activacion Windows'
            HtmlSecUsers = 'Usuarios'
            HtmlULocal   = 'Locales habilitados'
            HtmlUAdmin   = 'Administradores'
            HtmlSecBL    = 'BitLocker'
            HtmlBLNote   = 'Guarda las Recovery Keys en un sitio fuera del PC (gestor de contrasenas, impresion firmada, carpeta cliente).'
            HtmlSecDisks = 'Discos fisicos'
            HtmlVolumes  = 'Volumenes'
            HtmlSecNet   = 'Red'
            HtmlSecDef   = 'Windows Defender'
            HtmlSecHF    = 'Ultimas actualizaciones (top 10)'
            HtmlSecChk   = 'Checklist manual pre-entrega'
            HtmlSecSig   = 'Firmas'
            HtmlSigTech  = 'Firma Tecnico'
            HtmlSigCust  = 'Firma Cliente'
            HtmlDateLine = 'Fecha entrega: ____________________'
            HtmlFooter   = 'Atlas PC Support - Reporte generado automaticamente - Guarda este archivo o impr. a PDF para registro'
            BtnPrint     = '[Imprimir / Guardar PDF]'
            BtnCheckAll  = '[Marcar todos]'
            ColModel     = 'Modelo'
            ColSerial    = 'Serial'
            ColSize      = 'Tamano'
            ColHealth    = 'Salud'
            ColType      = 'Tipo'
            ColDrive     = 'Drive'
            ColLabel     = 'Label'
            ColFree      = 'Libre'
            ColTotal     = 'Total'
            ColFs        = 'FS'
            ColHotfix    = 'HotFix'
            ColInstalled = 'Instalado'
            ColTypeKB    = 'Tipo'
            RowName      = 'Nombre'
            RowMaker     = 'Fabricante'
            RowModel     = 'Modelo'
            RowBios      = 'Serial BIOS'
            RowOs        = 'OS'
            RowVer       = 'Version'
            RowBuild     = 'Build'
            RowArch      = 'Arquitectura'
            RowRam       = 'RAM total'
            RowAvOn      = 'AV Enabled'
            RowAvRT      = 'RealTime Protection'
            RowAvSig     = 'AV Signature'
            ChkItems     = @(
                'Hardware probado (pantalla, teclado, tactil, audio, USB, webcam, lector huellas)',
                'Bateria al 100% y cargador incluido',
                'Antivirus activo y actualizado',
                'BitLocker activado y recovery key guardada en sitio seguro',
                'Windows Update al dia',
                'Navegador limpio (sin cuentas guardadas del tecnico)',
                'Usuario cliente creado con nombre correcto',
                'Password entregada fisicamente o por canal seguro',
                'Cliente informado sobre garantia y contacto',
                'Equipo limpio (polvo, pantalla, teclado)',
                'Documentos de cliente recuperados y restaurados',
                'Programas solicitados por el cliente instalados'
            )
            MainOpt1     = '[ 1 ]  Entregar equipo (Usuario actual: {0})'
            MainOpt2     = '[ 2 ]  Crear un usuario nuevo adicional'
            MainOpt3     = '[ 3 ]  Renombrar equipo'
            MainOpt4     = '[ 4 ]  Generar CHECKLIST DE ENTREGA (reporte)'
            MainOpt5     = '[ 5 ]  Salir y cerrar herramienta'
            MainPrompt   = 'Seleccione una opcion [1-5]'
            BadOption    = 'Opcion no valida.'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

function Wait-AtlasReturn {
    param([string]$Message = $L.ReturnHint)
    $cleanMsg = ($Message -replace "^[`r`n\s]+", '').Trim()
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($cleanMsg)) { $cleanMsg = 'Press ENTER to continue...' }
        Wait-AtlasExit -Message $cleanMsg
        return
    }
    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        Write-Host $Message -ForegroundColor DarkGray
    }
    $null = Read-Host
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning $L.NeedAdmin1
    Write-Warning $L.NeedAdmin2
    Wait-AtlasReturn -Message $L.ReturnHint
    return
}

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

function Escribir-Centrado {
    param([string]$texto, [string]$color)
    $anchoConsola = $Host.UI.RawUI.WindowSize.Width
    $espacios = " " * ([math]::Max(0, [math]::Floor(($anchoConsola - $texto.Length) / 2)))
    Write-Host ($espacios + $texto) -ForegroundColor $color
}

function Mostrar-Encabezado {
    Clear-Host
    if ($atlasToolkitReady) {
        Write-Host ''
        Write-AtlasHeader -Title 'ATLAS PC SUPPORT' -Color Yellow
        Write-AtlasStep ($L.HeaderSub.Trim())
        Write-Host ''
        return
    }
    Write-Host "`n"
    Escribir-Centrado " █████╗ ████████╗██╗      █████╗ ███████╗" "DarkYellow"
    Escribir-Centrado "██╔══██╗╚══██╔══╝██║     ██╔══██╗██╔════╝" "DarkYellow"
    Escribir-Centrado "███████║   ██║   ██║     ███████║███████╗" "DarkYellow"
    Escribir-Centrado "██╔══██║   ██║   ██║     ██╔══██║╚════██║" "DarkYellow"
    Escribir-Centrado "██║  ██║   ██║   ███████╗██║  ██║███████║" "DarkYellow"
    Escribir-Centrado "╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝" "DarkYellow"
    Escribir-Centrado $L.HeaderSub "DarkYellow"
    Escribir-Centrado $L.HdrBar "DarkGray"
    Write-Host "`n"
}

function Modificar-UsuarioActual {
    $userName = $env:USERNAME
    Escribir-Centrado ($L.CfgUser -f $userName) "Cyan"
    Write-Host ""
    Write-Host $L.CancelHint -ForegroundColor DarkGray
    Write-Host ""

    $newDisplayName = Read-Host $L.AskFullName
    if ($newDisplayName -eq "0") { return }

    Write-Host $L.AskPwdHint -ForegroundColor Yellow
    $securePassword = Read-Host $L.AskPwdLbl -AsSecureString

    try {
        if (![string]::IsNullOrWhiteSpace($newDisplayName)) {
            Set-LocalUser -Name $userName -FullName $newDisplayName
            Write-Host ("`n" + ($L.UpdName -f $newDisplayName)) -ForegroundColor Green
        }
        if ($securePassword.Length -gt 0) {
            Set-LocalUser -Name $userName -Password $securePassword
            Write-Host $L.UpdPwd -ForegroundColor Green
        } else {
            Write-Host ("`n" + $L.NoPwd) -ForegroundColor Green
        }
    } catch {
        Write-Host ("`n" + ($L.ErrFmt -f $_.Exception.Message)) -ForegroundColor Red
    }
    Wait-AtlasReturn -Message $L.ReturnHint
}

function Crear-NuevoUsuario {
    Escribir-Centrado $L.CreateUser "Cyan"
    Write-Host ""
    Write-Host $L.CancelHint -ForegroundColor DarkGray
    Write-Host ""

    $newUser = Read-Host $L.AskNewLogon
    if ($newUser -eq "0" -or [string]::IsNullOrWhiteSpace($newUser)) { return }

    $newDisplayName = Read-Host $L.AskNewDisp
    if ($newDisplayName -eq "0") { return }

    Write-Host $L.AskPwdHint -ForegroundColor Yellow
    $securePassword = Read-Host $L.AskPwdLbl -AsSecureString

    $esAdmin = Read-Host $L.AskAdmin
    if ($esAdmin -eq "0") { return }

    try {
        if ($securePassword.Length -gt 0) {
            New-LocalUser -Name $newUser -FullName $newDisplayName -Password $securePassword -PasswordNeverExpires $true | Out-Null
        } else {
            New-LocalUser -Name $newUser -FullName $newDisplayName -NoPassword | Out-Null
        }
        Write-Host ("`n" + ($L.UserCreated -f $newUser)) -ForegroundColor Green

        if ($esAdmin -match "^[sSyY]") {
            $AdminGroup = Get-LocalGroup | Where-Object SID -eq "S-1-5-32-544"
            Add-LocalGroupMember -Group $AdminGroup -Member $newUser
            Write-Host $L.GrantedAdm -ForegroundColor Green
        } else {
            $UsersGroup = Get-LocalGroup | Where-Object SID -eq "S-1-5-32-545"
            Add-LocalGroupMember -Group $UsersGroup -Member $newUser
            Write-Host $L.GrantedStd -ForegroundColor Green
        }
    } catch {
        Write-Host ("`n" + ($L.ErrFmt -f $_.Exception.Message)) -ForegroundColor Red
    }
    Wait-AtlasReturn -Message $L.ReturnHint
}

function Renombrar-Equipo {
    Escribir-Centrado $L.RenameTitle "Cyan"
    Write-Host ""
    $actual = $env:COMPUTERNAME
    Write-Host ($L.CurrName -f $actual) -ForegroundColor White
    Write-Host ""
    $nuevo = Read-Host $L.AskNewName
    if ($nuevo -eq "0" -or [string]::IsNullOrWhiteSpace($nuevo)) { return }
    if ($nuevo -notmatch '^[A-Za-z0-9\-]{1,15}$') {
        Write-Host $L.BadName -ForegroundColor Red
        Wait-AtlasReturn -Message $L.EnterBack
        return
    }
    try {
        Rename-Computer -NewName $nuevo -Force -ErrorAction Stop
        Write-Host ("`n" + ($L.NameOk -f $nuevo)) -ForegroundColor Green
        Write-Host $L.NeedReboot -ForegroundColor Yellow
    } catch {
        Write-Host ("`n" + ($L.ErrFmt -f $_.Exception.Message)) -ForegroundColor Red
    }
    Wait-AtlasReturn -Message $L.EnterBack
}

function _Esc-Html {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return ([System.Net.WebUtility]::HtmlEncode($Text))
}

function _Row {
    param([string]$Label, [string]$Value)
    $v = _Esc-Html $Value
    $l = _Esc-Html $Label
    return "<tr><th>$l</th><td>$v</td></tr>"
}

function _Brighten-Hex {
    param([string]$Hex, [int]$Delta = 35)
    if (-not $Hex) { return $Hex }
    $h = $Hex.TrimStart('#')
    if ($h.Length -ne 6) { return $Hex }
    try {
        $r = [Math]::Min(255, [Convert]::ToInt32($h.Substring(0,2),16) + $Delta)
        $g = [Math]::Min(255, [Convert]::ToInt32($h.Substring(2,2),16) + $Delta)
        $b = [Math]::Min(255, [Convert]::ToInt32($h.Substring(4,2),16) + $Delta)
        return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
    } catch { return $Hex }
}

function _Darken-Hex {
    param([string]$Hex, [int]$Delta = 35)
    if (-not $Hex) { return $Hex }
    $h = $Hex.TrimStart('#')
    if ($h.Length -ne 6) { return $Hex }
    try {
        $r = [Math]::Max(0, [Convert]::ToInt32($h.Substring(0,2),16) - $Delta)
        $g = [Math]::Max(0, [Convert]::ToInt32($h.Substring(2,2),16) - $Delta)
        $b = [Math]::Max(0, [Convert]::ToInt32($h.Substring(4,2),16) - $Delta)
        return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
    } catch { return $Hex }
}

function _Load-AtlasBrand {
    $defaults = @{
        Name          = 'Atlas PC Support'
        Accent        = '#FF5500'
        Secondary     = '#002147'
    }
    $candidates = @()
    if ($env:USERPROFILE)    { $candidates += (Join-Path $env:USERPROFILE 'branding.json') }
    if ($env:LOCALAPPDATA)   { $candidates += (Join-Path $env:LOCALAPPDATA 'AtlasPC\branding.json') }
    if ($env:APPDATA)        { $candidates += (Join-Path $env:APPDATA 'AtlasPC\branding.json') }
    $candidates += (Join-Path (Get-Location) 'branding.json')
    foreach ($p in $candidates) {
        if ($p -and (Test-Path -LiteralPath $p)) {
            try {
                $obj = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($obj) {
                    if ($obj.brand -and $obj.brand.shortName) { $defaults.Name = [string]$obj.brand.shortName }
                    elseif ($obj.brand -and $obj.brand.name)  { $defaults.Name = [string]$obj.brand.name }
                    if ($obj.theme -and $obj.theme.accentColor)    { $defaults.Accent    = [string]$obj.theme.accentColor }
                    if ($obj.theme -and $obj.theme.secondaryColor) { $defaults.Secondary = [string]$obj.theme.secondaryColor }
                    break
                }
            } catch {}
        }
    }
    $defaults.AccentHover   = _Brighten-Hex $defaults.Accent 30
    $defaults.SecondaryDark = _Darken-Hex   $defaults.Secondary 15
    return $defaults
}

function Generar-ChecklistEntrega {
    Escribir-Centrado $L.BuildingHtml "Cyan"
    Write-Host ""
    Write-Host $L.Gathering -ForegroundColor Yellow

    $brand         = _Load-AtlasBrand
    $brandName     = $brand.Name
    $accent        = $brand.Accent
    $accentHover   = $brand.AccentHover
    $secondary     = $brand.Secondary
    $secondaryDark = $brand.SecondaryDark

    $now = Get-Date
    $generated = $now.ToString('yyyy-MM-dd HH:mm:ss')
    $hostName  = $env:COMPUTERNAME
    $userName  = $env:USERNAME

    $equipoRows = @()
    try {
        $cs   = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
        $os   = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $equipoRows += _Row $L.RowName  $hostName
        $equipoRows += _Row $L.RowMaker ($cs.Manufacturer)
        $equipoRows += _Row $L.RowModel ($cs.Model)
        $equipoRows += _Row $L.RowBios  ($bios.SerialNumber)
        $equipoRows += _Row $L.RowOs    ($os.Caption)
        $equipoRows += _Row $L.RowVer   ($os.Version)
        $equipoRows += _Row $L.RowBuild ($os.BuildNumber)
        $equipoRows += _Row $L.RowArch  ($os.OSArchitecture)
        $equipoRows += _Row $L.RowRam   (("{0:N1} GB" -f ($cs.TotalPhysicalMemory/1GB)))
    } catch {
        $equipoRows += "<tr><td colspan='2' class='err'>$($L.ErrEquipo -f (_Esc-Html $_.Exception.Message))</td></tr>"
    }

    $activacion = ''
    try {
        $licInfo = cscript.exe //Nologo "C:\Windows\System32\slmgr.vbs" /xpr 2>&1
        $activacion = _Esc-Html (($licInfo -join "`n").Trim())
    } catch {
        $activacion = "<span class='err'>$($L.ErrAct)</span>"
    }

    $usuariosHtml = ''
    $adminsHtml   = ''
    try {
        $ul = Get-LocalUser -ErrorAction Stop | Where-Object { $_.Enabled }
        $usuariosHtml = ($ul | ForEach-Object {
            "<li><strong>$(_Esc-Html $_.Name)</strong> <span class='muted'>$(_Esc-Html $_.FullName)</span></li>"
        }) -join ''
        $adminGroup = Get-LocalGroup | Where-Object SID -eq 'S-1-5-32-544'
        if ($adminGroup) {
            $members = Get-LocalGroupMember -Group $adminGroup -ErrorAction SilentlyContinue
            if ($members) {
                $adminsHtml = ($members | ForEach-Object { "<li>$(_Esc-Html $_.Name)</li>" }) -join ''
            }
        }
    } catch {
        $usuariosHtml = "<li class='err'>$($L.ErrUsers -f (_Esc-Html $_.Exception.Message))</li>"
    }

    $bitlockerRows = @()
    try {
        $vols = Get-BitLockerVolume -ErrorAction Stop
        foreach ($v in $vols) {
            $status = "$(_Esc-Html $v.VolumeStatus) - Protection: $(_Esc-Html $v.ProtectionStatus) - Enc: $($v.EncryptionPercentage)%"
            $rk = $v.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
            $keys = ''
            foreach ($r in $rk) {
                $maskedKey = "[Recovery Key Protected - Escrow Active]"
                if ($r.RecoveryPassword -and $r.RecoveryPassword.Length -gt 6) {
                    $lastChars = $r.RecoveryPassword.Substring($r.RecoveryPassword.Length - 6)
                    $maskedKey = "••••-••••-••••-••••-••••-••••-••••-$lastChars"
                }
                $keys += "<div class='key-block'><div class='muted small'>Key ID: $(_Esc-Html $r.KeyProtectorId)</div><code>$(_Esc-Html $maskedKey)</code></div>"
            }
            $bitlockerRows += "<tr><th>$(_Esc-Html $v.MountPoint)</th><td>$status$keys</td></tr>"
        }
    } catch {
        $bitlockerRows += "<tr><td colspan='2' class='err'>$($L.BLNotAvail -f (_Esc-Html $_.Exception.Message))</td></tr>"
    }

    $discosHtml = ''
    try {
        $discosHtml += "<table class='mini'><thead><tr><th>$($L.ColModel)</th><th>$($L.ColSerial)</th><th>$($L.ColSize)</th><th>$($L.ColHealth)</th><th>$($L.ColType)</th></tr></thead><tbody>"
        Get-PhysicalDisk -ErrorAction Stop | ForEach-Object {
            $health = _Esc-Html "$($_.HealthStatus)"
            $cls = if ($_.HealthStatus -eq 'Healthy') { 'ok' } elseif ($_.HealthStatus -eq 'Warning') { 'warn' } else { 'err' }
            $discosHtml += "<tr><td>$(_Esc-Html $_.FriendlyName)</td><td><code>$(_Esc-Html $_.SerialNumber)</code></td><td>$("{0:N0} GB" -f ($_.Size/1GB))</td><td class='$cls'>$health</td><td>$(_Esc-Html $_.MediaType)</td></tr>"
        }
        $discosHtml += '</tbody></table>'
    } catch {
        $discosHtml = "<p class='err'>$($L.ErrDisks -f (_Esc-Html $_.Exception.Message))</p>"
    }

    $volumenesHtml = ''
    try {
        $volumenesHtml += "<table class='mini'><thead><tr><th>$($L.ColDrive)</th><th>$($L.ColLabel)</th><th>$($L.ColFree)</th><th>$($L.ColTotal)</th><th>$($L.ColFs)</th></tr></thead><tbody>"
        Get-Volume -ErrorAction Stop | Where-Object { $_.DriveLetter } | Sort-Object DriveLetter | ForEach-Object {
            $pctFree = if ($_.Size -gt 0) { [int](($_.SizeRemaining/$_.Size)*100) } else { 0 }
            $cls = if ($pctFree -lt 10) { 'err' } elseif ($pctFree -lt 20) { 'warn' } else { 'ok' }
            $volumenesHtml += "<tr><td><strong>$($_.DriveLetter):</strong></td><td>$(_Esc-Html $_.FileSystemLabel)</td><td class='$cls'>$("{0:N1} GB" -f ($_.SizeRemaining/1GB)) ($pctFree%)</td><td>$("{0:N1} GB" -f ($_.Size/1GB))</td><td>$(_Esc-Html $_.FileSystem)</td></tr>"
        }
        $volumenesHtml += '</tbody></table>'
    } catch {
        $volumenesHtml = "<p class='err'>$($L.ErrVols -f (_Esc-Html $_.Exception.Message))</p>"
    }

    $hotfixHtml = ''
    try {
        $hotfixHtml += "<table class='mini'><thead><tr><th>$($L.ColHotfix)</th><th>$($L.ColInstalled)</th><th>$($L.ColTypeKB)</th></tr></thead><tbody>"
        Get-HotFix -ErrorAction Stop | Sort-Object InstalledOn -Descending | Select-Object -First 10 | ForEach-Object {
            $installedDate = if ($_.InstalledOn) { $_.InstalledOn.ToString('yyyy-MM-dd') } else { '' }
            $hotfixHtml += "<tr><td><code>$(_Esc-Html $_.HotFixID)</code></td><td>$(_Esc-Html $installedDate)</td><td>$(_Esc-Html $_.Description)</td></tr>"
        }
        $hotfixHtml += '</tbody></table>'
    } catch {
        $hotfixHtml = "<p class='err'>$($L.ErrHotfix -f (_Esc-Html $_.Exception.Message))</p>"
    }

    $redHtml = ''
    try {
        $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop | Where-Object { $_.IPAddress -notlike '169.*' -and $_.IPAddress -notlike '127.*' }
        if ($ips) {
            $redHtml = '<ul>'
            foreach ($ip in $ips) {
                $redHtml += "<li><strong>$(_Esc-Html $ip.InterfaceAlias):</strong> <code>$(_Esc-Html $ip.IPAddress)/$($ip.PrefixLength)</code></li>"
            }
            $redHtml += '</ul>'
        } else {
            $redHtml = "<p class='muted'>$($L.NoNet)</p>"
        }
    } catch {}

    $defenderRows = @()
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        $defenderRows += _Row $L.RowAvOn  ([string]$mp.AntivirusEnabled)
        $defenderRows += _Row $L.RowAvRT  ([string]$mp.RealTimeProtectionEnabled)
        $defenderRows += _Row $L.RowAvSig ([string]$mp.AntivirusSignatureLastUpdated)
    } catch {}

    $checklistItems = $L.ChkItems
    $checklistHtml = ''
    $i = 0
    foreach ($item in $checklistItems) {
        $i++
        $checklistHtml += "<label class='check'><input type='checkbox' id='c$i'><span>$(_Esc-Html $item)</span></label>"
    }

    $equipoTable    = $equipoRows    -join ''
    $bitlockerTable = $bitlockerRows -join ''
    $defenderTable  = $defenderRows  -join ''

    $titleStr = $L.HtmlTitle -f $brandName, $hostName
    $subtitleStr = $L.HtmlSubTitle -f $hostName
    $metaStr = $L.HtmlMeta -f $generated, $userName
    $htmlLang = $L.HtmlLang
    $titleEsc = _Esc-Html $titleStr

    $html = @"
<!DOCTYPE html>
<html lang="$htmlLang">
<head>
<meta charset="utf-8"/>
<title>$titleEsc</title>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
  :root {
    --bg: #0f141b;
    --surface: #171d26;
    --surface-alt: #1e2631;
    --border: #2c3444;
    --accent: $accent;
    --accent-hover: $accentHover;
    --secondary: $secondary;
    --secondary-dark: $secondaryDark;
    --text: #e5e7eb;
    --muted: #9ca3af;
    --ok: #22c55e;
    --warn: #eab308;
    --err: #ef4444;
    --radius: 10px;
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--text); font-family: -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif; font-size: 14px; line-height: 1.5; }
  .wrap { max-width: 960px; margin: 0 auto; padding: 24px; }
  header { background: linear-gradient(135deg, var(--secondary) 0%, var(--accent) 100%); color: white; padding: 32px 24px; border-radius: var(--radius); margin-bottom: 24px; box-shadow: 0 6px 24px rgba(0,0,0,0.35); }
  header h1 { margin: 0 0 4px 0; font-size: 28px; letter-spacing: -0.5px; }
  header .subtitle { opacity: .85; font-size: 14px; }
  header .meta { margin-top: 12px; font-size: 12px; opacity: .75; }
  section { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px 24px; margin-bottom: 16px; }
  section h2 { margin: 0 0 12px 0; font-size: 16px; color: var(--accent-hover); letter-spacing: .5px; text-transform: uppercase; border-bottom: 1px solid var(--border); padding-bottom: 8px; }
  table { border-collapse: collapse; width: 100%; font-size: 13px; }
  table th, table td { text-align: left; padding: 6px 10px; border-bottom: 1px solid var(--border); }
  table th { color: var(--muted); font-weight: 500; white-space: nowrap; width: 30%; }
  table.mini th, table.mini td { padding: 5px 8px; font-size: 12px; }
  table.mini thead th { background: var(--surface-alt); color: var(--accent-hover); font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: .5px; border-bottom: 2px solid var(--border); }
  code { background: var(--surface-alt); padding: 2px 6px; border-radius: 4px; font-size: 12px; color: #cbd5e1; }
  pre { background: var(--surface-alt); padding: 10px; border-radius: 6px; white-space: pre-wrap; font-size: 12px; }
  ul { margin: 4px 0; padding-left: 20px; }
  li { margin: 2px 0; }
  .muted { color: var(--muted); }
  .small { font-size: 11px; }
  .ok { color: var(--ok); font-weight: 500; }
  .warn { color: var(--warn); font-weight: 500; }
  .err { color: var(--err); font-weight: 500; }
  .key-block { margin-top: 4px; background: var(--surface-alt); padding: 8px; border-radius: 4px; border-left: 3px solid var(--warn); }
  .key-block code { background: transparent; color: var(--warn); font-size: 13px; font-weight: 600; letter-spacing: .5px; }
  .check { display: flex; align-items: flex-start; padding: 10px 12px; margin: 4px 0; background: var(--surface-alt); border-radius: 6px; cursor: pointer; transition: background .15s; border: 1px solid transparent; }
  .check:hover { background: #252d3a; border-color: var(--border); }
  .check input[type=checkbox] { flex-shrink: 0; width: 18px; height: 18px; margin-right: 10px; accent-color: var(--accent); cursor: pointer; }
  .check input[type=checkbox]:checked + span { color: var(--ok); text-decoration: line-through; opacity: .7; }
  .check span { flex: 1; }
  .signature-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-top: 16px; }
  .signature-box { padding: 30px 10px 10px; border-top: 2px solid var(--border); text-align: center; color: var(--muted); font-size: 12px; min-height: 80px; }
  .toolbar { position: sticky; top: 10px; z-index: 10; display: flex; gap: 10px; justify-content: flex-end; margin-bottom: 12px; }
  .btn { background: var(--accent); color: white; border: 0; border-radius: 6px; padding: 10px 18px; font-size: 13px; cursor: pointer; font-weight: 500; transition: background .15s; }
  .btn:hover { background: var(--accent-hover); }
  .btn.secondary { background: var(--surface-alt); color: var(--text); border: 1px solid var(--border); }
  footer { margin-top: 32px; padding: 16px; text-align: center; color: var(--muted); font-size: 11px; }
  @media print {
    body { background: white !important; color: black !important; font-size: 11pt; }
    .wrap { max-width: 100%; padding: 0; }
    header { background: white !important; color: black !important; border: 2px solid var(--secondary); box-shadow: none; page-break-after: avoid; }
    header h1, header .subtitle { color: var(--secondary) !important; }
    section { background: white !important; border: 1px solid #999 !important; color: black !important; page-break-inside: avoid; }
    section h2 { color: var(--secondary) !important; border-color: #999; }
    table th, table td { border-bottom: 1px solid #ccc !important; color: black !important; }
    table.mini thead th { background: #eee !important; color: var(--secondary) !important; }
    code, pre { background: #f5f5f5 !important; color: black !important; }
    .check { background: white !important; border: 1px solid #999 !important; break-inside: avoid; }
    .key-block { background: #fff8e6 !important; color: #666 !important; }
    .key-block code { color: #7a5a00 !important; }
    .muted { color: #666 !important; }
    .toolbar, .no-print { display: none !important; }
    .signature-box { border-top: 2px solid black; color: black; }
    a { color: black; text-decoration: none; }
  }
</style>
</head>
<body>
<div class="wrap">
<div class="toolbar no-print">
  <button class="btn" onclick="window.print()">$($L.BtnPrint)</button>
  <button class="btn secondary" onclick="toggleAll()">$($L.BtnCheckAll)</button>
</div>
<header>
  <h1>$(_Esc-Html $brandName)</h1>
  <div class="subtitle">$subtitleStr</div>
  <div class="meta">$metaStr</div>
</header>
<section><h2>$($L.HtmlSecEquipo)</h2><table>$equipoTable</table></section>
<section><h2>$($L.HtmlSecAct)</h2><pre>$activacion</pre></section>
<section>
  <h2>$($L.HtmlSecUsers)</h2>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px">
    <div><h3 style="margin:0 0 6px;font-size:13px;color:var(--muted);text-transform:uppercase">$($L.HtmlULocal)</h3><ul>$usuariosHtml</ul></div>
    <div><h3 style="margin:0 0 6px;font-size:13px;color:var(--muted);text-transform:uppercase">$($L.HtmlUAdmin)</h3><ul>$adminsHtml</ul></div>
  </div>
</section>
<section><h2>$($L.HtmlSecBL)</h2><table>$bitlockerTable</table><p class="small muted">$($L.HtmlBLNote)</p></section>
<section><h2>$($L.HtmlSecDisks)</h2>$discosHtml<h3 style="margin:16px 0 6px;font-size:13px;color:var(--muted);text-transform:uppercase">$($L.HtmlVolumes)</h3>$volumenesHtml</section>
<section><h2>$($L.HtmlSecNet)</h2>$redHtml</section>
<section><h2>$($L.HtmlSecDef)</h2><table>$defenderTable</table></section>
<section><h2>$($L.HtmlSecHF)</h2>$hotfixHtml</section>
<section><h2>$($L.HtmlSecChk)</h2>$checklistHtml</section>
<section>
  <h2>$($L.HtmlSecSig)</h2>
  <div class="signature-grid">
    <div class="signature-box">$($L.HtmlSigTech)<br/><span class="small">$(_Esc-Html $userName)</span></div>
    <div class="signature-box">$($L.HtmlSigCust)<br/><span class="small">_______________________</span></div>
  </div>
  <p class="small muted" style="margin-top:12px">$($L.HtmlDateLine)</p>
</section>
<footer>$($L.HtmlFooter)</footer>
</div>
<script>
function toggleAll(){
  var b=document.querySelectorAll(".check input[type=checkbox]");
  var all=true; for(var i=0;i<b.length;i++){ if(!b[i].checked){all=false;break;} }
  for(var j=0;j<b.length;j++){ b[j].checked=!all; }
}
</script>
</body>
</html>
"@

    try {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $desktop = [Environment]::GetFolderPath('Desktop')
        $out = Join-Path $desktop "atlas-handover-$hostName-$stamp.html"
        Set-Content -Path $out -Value $html -Encoding UTF8
        Write-Host ""
        Write-Host $L.HtmlSavedOk -ForegroundColor Green
        Write-Host "   $out" -ForegroundColor White
        Write-Host ""
        Write-Host $L.OpeningBrw -ForegroundColor DarkGray
        try { Start-Process $out } catch {
            try { Start-Process 'explorer.exe' -ArgumentList $out } catch {}
        }
    } catch {
        Write-Host ""
        Write-Host ($L.CouldNotSave -f $_.Exception.Message) -ForegroundColor Red
    }
    Wait-AtlasReturn -Message $L.EnterBack
}

while ($true) {
    Mostrar-Encabezado

    $l1 = $L.MainOpt1 -f $env:USERNAME
    $l2 = $L.MainOpt2
    $l3 = $L.MainOpt3
    $l4 = $L.MainOpt4
    $l5 = $L.MainOpt5

    $maxLen = [math]::Max($l1.Length, [math]::Max($l2.Length, [math]::Max($l3.Length, [math]::Max($l4.Length, $l5.Length))))

    Escribir-Centrado $l1.PadRight($maxLen) "White"
    Escribir-Centrado $l2.PadRight($maxLen) "White"
    Escribir-Centrado $l3.PadRight($maxLen) "White"
    Escribir-Centrado $l4.PadRight($maxLen) "Green"
    Escribir-Centrado $l5.PadRight($maxLen) "DarkGray"
    Write-Host ""

    $textoPrompt = $L.MainPrompt
    $ancho = $Host.UI.RawUI.WindowSize.Width
    $espacios = " " * ([math]::Max(0, [math]::Floor(($ancho - $textoPrompt.Length - 2) / 2)))
    Write-Host $espacios -NoNewline
    $opcion = Read-Host $textoPrompt

    switch ($opcion) {
        '1' { Mostrar-Encabezado; Modificar-UsuarioActual }
        '2' { Mostrar-Encabezado; Crear-NuevoUsuario }
        '3' { Mostrar-Encabezado; Renombrar-Equipo }
        '4' { Mostrar-Encabezado; Generar-ChecklistEntrega }
        '5' { Clear-Host; return }
        default { Escribir-Centrado $L.BadOption "Red"; Start-Sleep -s 1 }
    }
}
}
