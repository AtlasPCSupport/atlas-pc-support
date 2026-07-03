# ============================================================
# Invoke-MenorPrivilegio  ->  Local Account Hardening
#
# i18n: Option A (en default + full es secondary). Function name
# kept as Invoke-MenorPrivilegio for tools.json compatibility.
#
# Atlas PC Support
# ============================================================

function Invoke-MenorPrivilegio {
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
            WinTitle           = 'ATLAS PC SUPPORT | Security Suite v3.0'
            UacMax             = 'UAC: MAX [OK]'
            UacOff             = 'UAC: DISABLED [RISK]'
            UacPartial         = 'UAC: PARTIAL [REVIEW]'
            UacUnk             = 'UAC: UNKNOWN'
            RoleAdmin          = 'Administrator'
            RoleStd            = 'Standard'
            RoleUnk            = 'Unknown'
            Bar                = '=========================================================='
            HeaderApp          = 'MENOR PRIVILEGIO - Security Suite'
            HeaderSub          = 'Security Suite v3.0'
            UserRoleLine       = 'User: {0}  |  Role: {1}'
            ErrPwdLen          = 'Password must be at least 8 characters.'
            ErrPwdNum          = 'Must contain at least one digit.'
            ErrPwdUp           = 'Must contain at least one uppercase letter.'
            ErrPwdSym          = 'Must contain at least one special character.'
            LblWhat            = '  WHAT IT DOES:'
            LblRec             = '  RECOMMENDATION:'
            LblWarn            = '  CAUTION:'
            MenuRefText        = '5. Disable / Enable User Account'
            Opt1               = '1. Create NEW Administrator (Backup)'
            Opt2               = '2. Convert Current User to STANDARD'
            Opt3               = '3. UAC Configuration - Maximum Security'
            Opt4               = '4. Audit System Users'
            Opt5               = '5. Disable / Enable User Account'
            Opt6               = '6. Configure Password Policy'
            Opt7               = '7. Export Security Report (.txt)'
            Opt8               = '8. Quit'
            OptionPrompt       = 'Option'
            EnterContinue      = "`nPress Enter to continue..."
            T1Title            = '>>> CREATE NEW ADMINISTRATOR <<<'
            T1Que              = 'Creates a new local Administrator account with a strong password and no expiration. Acts as a backup account to recover the system if the main account fails.'
            T1Rec              = 'Use a discreet name (not "admin" or "backup"). Store credentials in a secure manager such as Bitwarden. Create only one backup account per machine.'
            T1Warn             = 'Having two active Admin accounts widens the attack surface. Create this account, verify it works, then apply option 2 to the main user.'
            T1BlankBack        = '(Empty name = back)'
            T1AskName          = 'Admin name'
            T1Exists           = 'ERROR: An account with that name already exists.'
            T1AskPwd           = 'Password (min 8 chars, 1 digit, 1 upper, 1 symbol): '
            T1EmptyPwd         = 'ERROR: Password cannot be empty.'
            T1Processing       = 'Processing...'
            T1Success          = "SUCCESS: Administrator '{0}' created."
            T2Title            = '>>> CONVERT TO STANDARD <<<'
            T2Que              = 'Removes Administrator privileges from the current user and converts them to a Standard user. Applies the principle of least privilege for daily customer use.'
            T2Rec              = 'This is the ideal day-to-day setup. Drastically reduces the risk of malware infections and accidental system changes.'
            T2Warn             = 'IRREVERSIBLE without another active Admin. The script verifies it automatically, but make sure your backup account (option 1) exists and works first.'
            T2BlockedNoAdmin   = 'BLOCKED: No other active Administrator exists.'
            T2CreateFirst      = 'Create one first using option 1.'
            T2VerifyErr        = 'ERROR while checking admins: {0}'
            T2Warning          = 'WARNING: This action will remove your Admin permissions.'
            T2OtherDetected    = 'Another administrator detected: OK'
            T2ConfirmHint       = "(Type 'YES' to confirm, or Enter to go back)"
            T2ConfirmPrompt    = 'Confirm'
            T2ConfirmWord      = 'YES'
            T2Done             = 'PERMISSIONS UPDATED. You are now a Standard user.'
            T2LogoffAsk        = 'Log off now to apply changes? (Y/N)'
            T3Title            = '>>> SECURITY HARDENING (UAC) <<<'
            T3Que              = 'Enables User Account Control (UAC) at maximum level. Forces Admin credentials when installing software or changing critical system settings.'
            T3Rec              = 'Always run after converting the user to Standard (option 2). Second most important defense layer. Apply on every PC handover.'
            T3Warn             = 'Customer will see more confirmation prompts. Inform them this is for security. May interrupt workflows for users used to running without UAC.'
            T3RulesIntro       = 'These 4 registry rules will be applied:'
            T3Rule1            = '  [1] EnableLUA = 1              (UAC enabled)'
            T3Rule2            = '  [2] PromptOnSecureDesktop = 1  (Secure desktop)'
            T3Rule3            = '  [3] ConsentPromptBehaviorUser = 1  (Credentials for standard users)'
            T3Rule4            = '  [4] ConsentPromptBehaviorAdmin = 2 (Credentials for admins)'
            T3ApplyHint        = "(Enter to apply, 'N' to cancel)"
            T3Applying         = 'Applying registry rules...'
            T3Applied          = 'CONFIGURATION APPLIED.'
            T3WillAsk          = 'Windows will ask for credentials when installing software.'
            T3RebootHint       = 'A reboot is required to fully apply.'
            T4Title            = '>>> SYSTEM USER AUDIT <<<'
            T4Que              = 'Lists all local accounts on the machine showing name, role (Admin/Standard), state (enabled/disabled), and whether a password is required.'
            T4Rec              = 'Run before and after any change to verify the actual state. Ideal to document the configuration at the start and end of a technical session.'
            T4Warn             = 'Read-only, makes no changes. If you see unknown Admin accounts or active accounts without a password, investigate before continuing.'
            T4Header           = '{0,-22} {1,-14} {2,-12} {3,-10}' # USER ROLE STATE KEY
            T4HUser            = 'USER'
            T4HRole            = 'ROLE'
            T4HState           = 'STATE'
            T4HKey             = 'PWD'
            T4StateOn          = 'Enabled'
            T4StateOff         = 'Disabled'
            T4PwdReq           = 'Required'
            T4PwdNo            = 'Not req.'
            T4Total            = 'Total: {0} account(s) | Admins: {1}'
            T5Title            = '>>> DISABLE / ENABLE ACCOUNT <<<'
            T5Que              = 'Deactivates or reactivates a local account without deleting it. A disabled account cannot log in but keeps all of its data and configuration.'
            T5Rec              = 'Prefer disabling over deleting. If you ever need to restore access, you can re-enable without losing data or profile config.'
            T5Warn             = 'You cannot disable your own active account. Do not disable the only Admin or the machine becomes inaccessible without reinstalling Windows.'
            T5NoOthers         = 'No other accounts available.'
            T5StateActive      = '[ENABLED]'
            T5StateInactive    = '[DISABLED]'
            T5BackHint         = '(Account number, or Enter to go back)'
            T5AskAccount       = 'Account'
            T5BadNumber        = 'Invalid number.'
            T5Disabled         = "Account '{0}' DISABLED."
            T5Enabled          = "Account '{0}' ENABLED."
            T6Title            = '>>> PASSWORD POLICY <<<'
            T6Que              = 'Configures global system password rules: minimum length, days until expiration, and number of failed attempts before lockout.'
            T6Rec              = 'Recommended values: minimum length 10, expiration 90 days, lockout after 5 attempts. For home use you can set expiration 0 (never).'
            T6Warn             = 'These changes affect ALL accounts on the machine. A very aggressive lockout (3 attempts) can lock the customer out if they often forget their password.'
            T6CurrentLbl       = 'Current policy:'
            T6NewLbl           = '--- Configure new policy ---'
            T6AskMin           = 'Minimum length (Enter = no change)'
            T6AskMax           = 'Days until expiration (Enter = no change, 0 = never)'
            T6AskLock          = 'Attempts before lockout (Enter = no change)'
            T6Applied          = '{0} change(s) applied.'
            T6NoChanges        = 'No changes.'
            T7Title            = '>>> EXPORT SECURITY REPORT <<<'
            T7Que              = 'Generates a .txt file on the desktop with the full security state: UAC level, list of users with roles and states, and the active password policy.'
            T7Rec              = 'Generate the report at the start and end of every session. Save it in the customer file as evidence of work performed and machine state.'
            T7Warn             = 'The report contains sensitive information (account names, configuration). Do not leave it on the customer desktop: keep it in your system and remove the local copy.'
            T7Building         = 'Generating report...'
            T7Saved            = 'Report saved at:'
            T7TitleLine        = '  ATLAS PC SUPPORT - SECURITY REPORT'
            T7DateLine         = '  Date     : {0}'
            T7HostLine         = '  Computer : {0}'
            T7UserLine         = '  User     : {0}'
            T7UacSec           = '--- UAC STATE ---'
            T7UsersSec         = '--- LOCAL USERS ---'
            T7PolicySec        = '--- PASSWORD POLICY ---'
            T7Footer           = '  Report generated by Atlas PC Support Security Suite v3.0'
            ReportFile         = 'Security_Report_{0}.txt'
            ErrGeneric         = 'ERROR: {0}'
        }
        es = @{
            WinTitle           = 'ATLAS PC SUPPORT | Security Suite v3.0'
            UacMax             = 'UAC: MAXIMO [OK]'
            UacOff             = 'UAC: DESACTIVADO [RIESGO]'
            UacPartial         = 'UAC: PARCIAL [REVISAR]'
            UacUnk             = 'UAC: DESCONOCIDO'
            RoleAdmin          = 'Administrador'
            RoleStd            = 'Estandar'
            RoleUnk            = 'Desconocido'
            Bar                = '=========================================================='
            HeaderApp          = 'MENOR PRIVILEGIO - Security Suite'
            HeaderSub          = 'Security Suite v3.0'
            UserRoleLine       = 'Usuario: {0}  |  Rol: {1}'
            ErrPwdLen          = 'La contrasena debe tener al menos 8 caracteres.'
            ErrPwdNum          = 'Debe contener al menos un numero.'
            ErrPwdUp           = 'Debe contener al menos una mayuscula.'
            ErrPwdSym          = 'Debe contener al menos un caracter especial.'
            LblWhat            = '  QUE HACE:'
            LblRec             = '  RECOMENDACION:'
            LblWarn            = '  PRECAUCION:'
            MenuRefText        = '5. Deshabilitar / Habilitar Cuenta de Usuario'
            Opt1               = '1. Crear NUEVO Administrador (Respaldo)'
            Opt2               = '2. Convertir Usuario Actual a ESTANDAR'
            Opt3               = '3. Configuracion del UAC - Seguridad Maxima'
            Opt4               = '4. Auditoria de Usuarios del Sistema'
            Opt5               = '5. Deshabilitar / Habilitar Cuenta de Usuario'
            Opt6               = '6. Configurar Politica de Contrasenas'
            Opt7               = '7. Exportar Informe de Seguridad (.txt)'
            Opt8               = '8. Salir'
            OptionPrompt       = 'Opcion'
            EnterContinue      = "`nPresione Enter para continuar..."
            T1Title            = '>>> CREAR NUEVO ADMINISTRADOR <<<'
            T1Que              = 'Crea una cuenta de Administrador local nueva con contrasena segura y sin caducidad. Sirve como cuenta de respaldo para recuperar el sistema si la cuenta principal falla.'
            T1Rec              = 'Usa un nombre discreto (no admin ni backup). Guarda las credenciales en un gestor seguro como Bitwarden. Crea solo una cuenta de respaldo por equipo.'
            T1Warn             = 'Tener dos cuentas Admin activas amplia la superficie de ataque. Crea esta cuenta, verifica que funciona y luego aplica la opcion 2 al usuario principal.'
            T1BlankBack        = '(Nombre en blanco = volver)'
            T1AskName          = 'Nombre Admin'
            T1Exists           = 'ERROR: Ya existe una cuenta con ese nombre.'
            T1AskPwd           = 'Contrasena (min 8 car., 1 num., 1 MAY., 1 especial): '
            T1EmptyPwd         = 'ERROR: La contrasena no puede estar vacia.'
            T1Processing       = 'Procesando...'
            T1Success          = "EXITO: Administrador '{0}' creado."
            T2Title            = '>>> CONVERTIR A ESTANDAR <<<'
            T2Que              = 'Quita los privilegios de Administrador al usuario actual y lo convierte en usuario Estandar. Aplica el principio de menor privilegio para el uso diario del cliente.'
            T2Rec              = 'Esta es la configuracion ideal para el dia a dia. Reduce drasticamente el riesgo de infecciones por malware y cambios accidentales en el sistema.'
            T2Warn             = 'IRREVERSIBLE sin otro Admin activo. El script lo verifica automaticamente, pero asegurate de que la cuenta de respaldo (opcion 1) ya existe y funciona antes de continuar.'
            T2BlockedNoAdmin   = 'BLOQUEADO: No existe otro Administrador activo.'
            T2CreateFirst      = 'Crea uno primero con la opcion 1.'
            T2VerifyErr        = 'ERROR al verificar admins: {0}'
            T2Warning          = 'ATENCION: Esta accion quitara tus permisos de Admin.'
            T2OtherDetected    = 'Otro administrador detectado: OK'
            T2ConfirmHint       = "(Escribe 'SI' para confirmar, o Enter para volver)"
            T2ConfirmPrompt    = 'Confirmar'
            T2ConfirmWord      = 'SI'
            T2Done             = 'PERMISOS ACTUALIZADOS. Ahora eres usuario Estandar.'
            T2LogoffAsk        = 'Cerrar sesion ahora para aplicar cambios? (S/N)'
            T3Title            = '>>> BLINDAJE DE SEGURIDAD (UAC) <<<'
            T3Que              = 'Activa el Control de Cuentas de Usuario (UAC) al nivel maximo. Obliga a introducir credenciales de Admin para instalar software o cambiar configuraciones criticas del sistema.'
            T3Rec              = 'Ejecutar siempre despues de convertir al usuario a Estandar (opcion 2). Es la segunda capa de defensa mas importante. Aplica en cada entrega de equipo.'
            T3Warn             = 'El cliente vera mas ventanas de confirmacion. Informa que es por seguridad. Puede interrumpir flujos de trabajo de usuarios acostumbrados a trabajar sin UAC activo.'
            T3RulesIntro       = 'Se aplicaran estas 4 reglas de registro:'
            T3Rule1            = '  [1] EnableLUA = 1              (UAC activo)'
            T3Rule2            = '  [2] PromptOnSecureDesktop = 1  (Escritorio seguro)'
            T3Rule3            = '  [3] ConsentPromptBehaviorUser = 1  (Credenciales para estandar)'
            T3Rule4            = '  [4] ConsentPromptBehaviorAdmin = 2 (Credenciales para admins)'
            T3ApplyHint        = "(Enter para aplicar, 'N' para cancelar)"
            T3Applying         = 'Aplicando reglas de registro...'
            T3Applied          = 'CONFIGURACION APLICADA.'
            T3WillAsk          = 'Windows pedira credenciales para instalar software.'
            T3RebootHint       = 'Se requiere reinicio para aplicar completamente.'
            T4Title            = '>>> AUDITORIA DE USUARIOS DEL SISTEMA <<<'
            T4Que              = 'Lista todas las cuentas locales del equipo mostrando nombre, rol (Admin/Estandar), estado (activa/desactivada) y si tienen contrasena requerida.'
            T4Rec              = 'Ejecuta antes y despues de cualquier cambio para verificar el estado real. Ideal para documentar la configuracion al inicio y al final de una intervencion tecnica.'
            T4Warn             = 'Solo lectura, no realiza ningun cambio. Si ves cuentas Admin desconocidas o cuentas activas sin contrasena, investiga antes de continuar con otras opciones.'
            T4Header           = '{0,-22} {1,-14} {2,-12} {3,-10}'
            T4HUser            = 'USUARIO'
            T4HRole            = 'ROL'
            T4HState           = 'ESTADO'
            T4HKey             = 'CLAVE'
            T4StateOn          = 'Activa'
            T4StateOff         = 'Desactivada'
            T4PwdReq           = 'Requerida'
            T4PwdNo            = 'No req.'
            T4Total            = 'Total: {0} cuenta(s) | Admins: {1}'
            T5Title            = '>>> DESHABILITAR / HABILITAR CUENTA <<<'
            T5Que              = 'Desactiva o reactiva una cuenta local sin eliminarla. Una cuenta desactivada no puede iniciar sesion pero conserva todos sus datos y configuracion intactos.'
            T5Rec              = 'Prefiere deshabilitar sobre eliminar. Si en el futuro necesitas recuperar acceso a esa cuenta, podras reactivarla sin perder datos ni configuracion del perfil.'
            T5Warn             = 'No puedes deshabilitar tu propia cuenta activa. No deshabilites la unica cuenta Admin del sistema o el equipo quedara inaccesible sin reinstalar Windows.'
            T5NoOthers         = 'No hay otras cuentas disponibles.'
            T5StateActive      = '[ACTIVA]'
            T5StateInactive    = '[DESACTIVADA]'
            T5BackHint         = '(Numero de cuenta, o Enter para volver)'
            T5AskAccount       = 'Cuenta'
            T5BadNumber        = 'Numero invalido.'
            T5Disabled         = "Cuenta '{0}' DESHABILITADA."
            T5Enabled          = "Cuenta '{0}' HABILITADA."
            T6Title            = '>>> POLITICA DE CONTRASENAS <<<'
            T6Que              = 'Configura las reglas globales de contrasenas del sistema: longitud minima, dias hasta caducidad y numero de intentos fallidos antes de bloquear la cuenta.'
            T6Rec              = 'Valores recomendados: longitud minima 10, expiracion 90 dias, bloqueo tras 5 intentos. Para uso domestico puedes poner expiracion 0 (nunca caduca).'
            T6Warn             = 'Estos cambios afectan a TODAS las cuentas del equipo. Un lockout muy agresivo (3 intentos) puede bloquear al cliente si olvida su contrasena con frecuencia.'
            T6CurrentLbl       = 'Politica actual:'
            T6NewLbl           = '--- Configurar nueva politica ---'
            T6AskMin           = 'Longitud minima (Enter = no cambiar)'
            T6AskMax           = 'Dias hasta expiracion (Enter = no cambiar, 0 = nunca)'
            T6AskLock          = 'Intentos antes de bloquear (Enter = no cambiar)'
            T6Applied          = '{0} cambio(s) aplicados.'
            T6NoChanges        = 'Sin cambios.'
            T7Title            = '>>> EXPORTAR INFORME DE SEGURIDAD <<<'
            T7Que              = 'Genera un archivo .txt en el escritorio con el estado completo de seguridad: nivel UAC, lista de usuarios con roles y estados, y politica de contrasenas vigente.'
            T7Rec              = 'Genera el informe al inicio y al final de cada intervencion. Guardalo en la ficha del cliente como evidencia del trabajo realizado y estado del equipo.'
            T7Warn             = 'El informe contiene informacion sensible (nombres de cuentas, configuracion). No lo dejes en el escritorio del cliente: guardalo en tu sistema y elimina la copia local.'
            T7Building         = 'Generando informe...'
            T7Saved            = 'Informe guardado en:'
            T7TitleLine        = '  ATLAS PC SUPPORT - INFORME DE SEGURIDAD'
            T7DateLine         = '  Fecha    : {0}'
            T7HostLine         = '  Equipo   : {0}'
            T7UserLine         = '  Usuario  : {0}'
            T7UacSec           = '--- ESTADO UAC ---'
            T7UsersSec         = '--- USUARIOS LOCALES ---'
            T7PolicySec        = '--- POLITICA DE CONTRASENAS ---'
            T7Footer           = '  Informe generado por Atlas PC Support Security Suite v3.0'
            ReportFile         = 'Informe_Seguridad_{0}.txt'
            ErrGeneric         = 'ERROR: {0}'
        }
    }
    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

$ErrorActionPreference = "Stop"

$Host.UI.RawUI.WindowTitle = $L.WinTitle
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Gray"
try { $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(90, 48) } catch {}
Clear-Host
try { [Console]::CursorVisible = $true } catch {}

try {
    $objSIDAdmin = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $adminGroupName = $objSIDAdmin.Translate([System.Security.Principal.NTAccount]).Value.Split("\")[-1]

    $objSIDUser = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-545")
    $stdGroupName = $objSIDUser.Translate([System.Security.Principal.NTAccount]).Value.Split("\")[-1]
} catch {
    $adminGroupName = "Administrators"
    $stdGroupName = "Users"
}

function Escribir-Centrado {
    param([string]$Texto, [ConsoleColor]$Color = "White", [boolean]$NewLine = $true)
    try {
        $Ancho = $Host.UI.RawUI.WindowSize.Width
        $PadLeft = [math]::Max(0, [math]::Floor(($Ancho - $Texto.Length) / 2))
        Write-Host (" " * $PadLeft) -NoNewline
        if ($NewLine) { Write-Host $Texto -ForegroundColor $Color }
        else { Write-Host $Texto -ForegroundColor $Color -NoNewline }
    } catch { Write-Host $Texto -ForegroundColor $Color }
}

function Wait-AtlasContinue {
    param([string]$Message = $L.EnterContinue)
    if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
        Wait-AtlasExit -Message ($Message -replace "^[`r`n\s]+", '')
        return
    }
    $null = Read-Host $Message
}

function Obtener-EstadoUAC {
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $lua  = (Get-ItemProperty -Path $regPath -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
        $sdt  = (Get-ItemProperty -Path $regPath -Name "PromptOnSecureDesktop" -ErrorAction SilentlyContinue).PromptOnSecureDesktop
        $usr  = (Get-ItemProperty -Path $regPath -Name "ConsentPromptBehaviorUser" -ErrorAction SilentlyContinue).ConsentPromptBehaviorUser
        $adm  = (Get-ItemProperty -Path $regPath -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue).ConsentPromptBehaviorAdmin
        if ($lua -eq 1 -and $sdt -eq 1 -and $usr -eq 1 -and $adm -eq 2) { return @{ Texto = $L.UacMax; Color = "Green" } }
        elseif ($lua -eq 0) { return @{ Texto = $L.UacOff; Color = "Red" } }
        else { return @{ Texto = $L.UacPartial; Color = "Yellow" } }
    } catch { return @{ Texto = $L.UacUnk; Color = "DarkGray" } }
}

function Obtener-RolUsuario {
    param([string]$NombreUsuario)
    try {
        $miembros = Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.Split("\")[-1] }
        if ($miembros -contains $NombreUsuario) { return $L.RoleAdmin } else { return $L.RoleStd }
    } catch { return $L.RoleUnk }
}

function Dibujar-Header {
    Clear-Host
    Write-Host "`n"
    $uac = Obtener-EstadoUAC
    $rol = Obtener-RolUsuario $env:USERNAME
    $rolColor = if ($rol -eq $L.RoleAdmin) { "Cyan" } else { "Green" }

    if ($atlasToolkitReady) {
        Write-AtlasHeader -Title $L.HeaderApp -Color Yellow
        Write-AtlasStep $L.HeaderSub
        Write-AtlasStep (($L.UserRoleLine -f $env:USERNAME, $rol))
        if ($uac.Color -eq 'Green') { Write-AtlasSuccess $uac.Texto }
        elseif ($uac.Color -eq 'Red') { Write-AtlasWarn $uac.Texto }
        else { Write-AtlasStep $uac.Texto }
        Write-Host ""
        return
    }

    Escribir-Centrado $L.Bar "DarkGray"
    Escribir-Centrado $L.HeaderApp "Cyan"
    Escribir-Centrado $L.HeaderSub "DarkGray"
    Escribir-Centrado $L.Bar "DarkGray"
    Write-Host ""
    Escribir-Centrado ($L.UserRoleLine -f $env:USERNAME, $rol) $rolColor
    Escribir-Centrado $uac.Texto $uac.Color
    Escribir-Centrado $L.Bar "DarkGray"
    Write-Host ""
}

function Validar-Contrasena {
    param([System.Security.SecureString]$Pass)
    if ($Pass.Length -lt 8) { return $L.ErrPwdLen }
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass)
    try {
        $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        if ($plain -notmatch '[0-9]')         { return $L.ErrPwdNum }
        if ($plain -notmatch '[A-Z]')         { return $L.ErrPwdUp }
        if ($plain -notmatch '[^a-zA-Z0-9]')  { return $L.ErrPwdSym }
        return $null
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}

function Escribir-Descripcion {
    param([string]$Que, [string]$Recomendacion, [string]$Precaucion)
    $w   = $Host.UI.RawUI.WindowSize.Width
    $sep = "-" * 54
    $pad = [math]::Max(0, [math]::Floor(($w - 58) / 2))
    $s   = " " * $pad
    function WrapLine($txt, $col) {
        $words = $txt -split ' '; $line = "  "
        foreach ($word in $words) {
            if (($line + $word).Length -gt 51) {
                Write-Host "$s|  " -NoNewline
                Write-Host ($line.PadRight(53)) -ForegroundColor $col -NoNewline
                Write-Host "|" -ForegroundColor DarkGray
                $line = "  $word "
            } else { $line += "$word " }
        }
        if ($line.Trim()) {
            Write-Host "$s|  " -NoNewline
            Write-Host ($line.PadRight(53)) -ForegroundColor $col -NoNewline
            Write-Host "|" -ForegroundColor DarkGray
        }
    }
    function LabelLine($lbl) {
        Write-Host "$s|  " -NoNewline
        Write-Host ($lbl.PadRight(53)) -ForegroundColor DarkGray -NoNewline
        Write-Host "|" -ForegroundColor DarkGray
    }
    function BlankLine {
        Write-Host "$s|  " -NoNewline
        Write-Host ("".PadRight(53)) -NoNewline
        Write-Host "|" -ForegroundColor DarkGray
    }
    Write-Host "$s+$sep+" -ForegroundColor DarkGray
    LabelLine $L.LblWhat
    WrapLine $Que "White"
    BlankLine
    LabelLine $L.LblRec
    WrapLine $Recomendacion "Cyan"
    BlankLine
    LabelLine $L.LblWarn
    WrapLine $Precaucion "Yellow"
    Write-Host "$s+$sep+" -ForegroundColor DarkGray
    Write-Host ""
}

function Desencriptar-Pass {
    param([System.Security.SecureString]$Pass)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
}

do {
    Dibujar-Header

    $anchoPantalla = $Host.UI.RawUI.WindowSize.Width
    $textoReferencia = $L.MenuRefText
    $padBloque = [math]::Max(0, [math]::Floor(($anchoPantalla - $textoReferencia.Length) / 2))
    $espacio = " " * $padBloque
    $padInput = [math]::Max(0, [math]::Floor(($anchoPantalla - 10) / 2))

    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt1 -ForegroundColor White
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt2 -ForegroundColor White
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt3 -ForegroundColor Cyan
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt4 -ForegroundColor Yellow
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt5 -ForegroundColor Magenta
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt6 -ForegroundColor DarkCyan
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt7 -ForegroundColor DarkYellow
    Write-Host "$espacio" -NoNewline; Write-Host $L.Opt8 -ForegroundColor DarkGray
    Write-Host ""

    Write-Host (" " * $padInput) -NoNewline
    $seleccion = Read-Host $L.OptionPrompt

    switch ($seleccion) {

        "1" {
            Dibujar-Header
            Escribir-Centrado $L.T1Title "Green"
            Write-Host ""
            Escribir-Descripcion -Que $L.T1Que -Recomendacion $L.T1Rec -Precaucion $L.T1Warn
            Escribir-Centrado $L.T1BlankBack "DarkGray"
            Write-Host (" " * ($padInput - 5)) -NoNewline
            $newAdminUser = Read-Host $L.T1AskName
            if ([string]::IsNullOrWhiteSpace($newAdminUser)) { break }

            $existe = Get-LocalUser -Name $newAdminUser -ErrorAction SilentlyContinue
            if ($existe) {
                Escribir-Centrado $L.T1Exists "Red"
                Wait-AtlasContinue -Message $L.EnterContinue
                break
            }

            Write-Host (" " * ($padInput - 5)) -NoNewline
            Write-Host $L.T1AskPwd -NoNewline -ForegroundColor Yellow
            $passSecure = Read-Host -AsSecureString

            if ($passSecure.Length -eq 0) {
                Escribir-Centrado $L.T1EmptyPwd "Red"
                Wait-AtlasContinue -Message $L.EnterContinue
                break
            }

            $errPass = Validar-Contrasena $passSecure
            if ($errPass) {
                Escribir-Centrado ("ERROR: " + $errPass) "Red"
                Wait-AtlasContinue -Message $L.EnterContinue
                break
            }

            Write-Host ""
            Escribir-Centrado $L.T1Processing "Cyan"

            try {
                New-LocalUser -Name $newAdminUser -Password $passSecure -PasswordNeverExpires $true -ErrorAction Stop | Out-Null
                Add-LocalGroupMember -SID "S-1-5-32-544" -Member $newAdminUser -ErrorAction Stop
                Escribir-Centrado ($L.T1Success -f $newAdminUser) "Green"
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
            }
            Wait-AtlasContinue -Message $L.EnterContinue
        }

        "2" {
            Dibujar-Header
            Escribir-Centrado $L.T2Title "Yellow"
            Write-Host ""
            Escribir-Descripcion -Que $L.T2Que -Recomendacion $L.T2Rec -Precaucion $L.T2Warn

            try {
                $todosAdmins = @(Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction Stop | ForEach-Object { $_.Name.Split("\")[-1] })
                $otrosAdmins = $todosAdmins | Where-Object { $_ -ne $env:USERNAME }
                if ($otrosAdmins.Count -eq 0) {
                    Escribir-Centrado $L.T2BlockedNoAdmin "Red"
                    Escribir-Centrado $L.T2CreateFirst "Yellow"
                    Wait-AtlasContinue -Message $L.EnterContinue
                    break
                }
            } catch {
                Escribir-Centrado ($L.T2VerifyErr -f $_.Exception.Message) "Red"
                Wait-AtlasContinue -Message $L.EnterContinue
                break
            }

            Escribir-Centrado $L.T2Warning "Red"
            Escribir-Centrado $L.T2OtherDetected "Green"
            Write-Host ""
            Escribir-Centrado $L.T2ConfirmHint "Gray"
            Write-Host (" " * ($padInput - 10)) -NoNewline
            $confirm = Read-Host $L.T2ConfirmPrompt
            if ($confirm -ne $L.T2ConfirmWord) { break }

            $targetUser = $env:USERNAME
            Escribir-Centrado $L.T1Processing "Cyan"

            try {
                Add-LocalGroupMember -SID "S-1-5-32-545" -Member $targetUser -ErrorAction SilentlyContinue
                Remove-LocalGroupMember -SID "S-1-5-32-544" -Member $targetUser -ErrorAction Stop
                Escribir-Centrado $L.T2Done "Green"
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
                Wait-AtlasContinue -Message $L.EnterContinue
                break
            }

            Write-Host ""
            Write-Host (" " * ($padInput - 10)) -NoNewline
            $logoff = Read-Host $L.T2LogoffAsk
            if ($logoff -eq "S" -or $logoff -eq "s" -or $logoff -eq "Y" -or $logoff -eq "y") {
                Start-Process "shutdown.exe" -ArgumentList "/l"
                return
            }
        }

        "3" {
            Dibujar-Header
            Escribir-Centrado $L.T3Title "Cyan"
            Write-Host ""
            Escribir-Descripcion -Que $L.T3Que -Recomendacion $L.T3Rec -Precaucion $L.T3Warn
            Escribir-Centrado $L.T3RulesIntro "White"
            Write-Host ""
            Escribir-Centrado $L.T3Rule1 "Gray"
            Escribir-Centrado $L.T3Rule2 "Gray"
            Escribir-Centrado $L.T3Rule3 "Gray"
            Escribir-Centrado $L.T3Rule4 "Gray"
            Write-Host ""
            Escribir-Centrado $L.T3ApplyHint "Gray"
            Write-Host (" " * $padInput) -NoNewline
            $uacConf = Read-Host ""
            if ($uacConf -eq "N" -or $uacConf -eq "n") { break }

            try {
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
                Escribir-Centrado $L.T3Applying "DarkGray"

                Set-ItemProperty -Path $regPath -Name "EnableLUA"                    -Value 1 -ErrorAction Stop
                Set-ItemProperty -Path $regPath -Name "PromptOnSecureDesktop"        -Value 1 -ErrorAction Stop
                Set-ItemProperty -Path $regPath -Name "ConsentPromptBehaviorUser"    -Value 1 -ErrorAction Stop
                Set-ItemProperty -Path $regPath -Name "ConsentPromptBehaviorAdmin"   -Value 2 -ErrorAction Stop

                Write-Host ""
                Escribir-Centrado $L.T3Applied "Green"
                Escribir-Centrado $L.T3WillAsk "Gray"
                Escribir-Centrado $L.T3RebootHint "Yellow"
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
            }
            Wait-AtlasContinue -Message $L.EnterContinue
        }

        "4" {
            Dibujar-Header
            Escribir-Centrado $L.T4Title "Yellow"
            Write-Host ""
            Escribir-Descripcion -Que $L.T4Que -Recomendacion $L.T4Rec -Precaucion $L.T4Warn

            try {
                $usuarios = Get-LocalUser -ErrorAction Stop
                $admins   = @(Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.Split("\")[-1] })

                $anchoPantalla2 = $Host.UI.RawUI.WindowSize.Width
                $lineaEncabezado = $L.T4Header -f $L.T4HUser, $L.T4HRole, $L.T4HState, $L.T4HKey
                $padAudit = [math]::Max(0, [math]::Floor(($anchoPantalla2 - $lineaEncabezado.Length) / 2))
                $spc = " " * $padAudit

                Write-Host "$spc$lineaEncabezado" -ForegroundColor DarkGray
                Write-Host "$spc$("-" * $lineaEncabezado.Length)" -ForegroundColor DarkGray

                foreach ($u in $usuarios) {
                    $rol    = if ($admins -contains $u.Name) { 'Admin' } else { $L.RoleStd }
                    $estado = if ($u.Enabled) { $L.T4StateOn } else { $L.T4StateOff }
                    $clave  = if ($u.PasswordRequired) { $L.T4PwdReq } else { $L.T4PwdNo }
                    $linea  = $L.T4Header -f $u.Name, $rol, $estado, $clave

                    $color = if (!$u.Enabled) { "DarkGray" }
                             elseif ($admins -contains $u.Name) { "Cyan" }
                             else { "White" }
                    Write-Host "$spc$linea" -ForegroundColor $color
                }
                Write-Host ""
                Escribir-Centrado ($L.T4Total -f $usuarios.Count, $admins.Count) "DarkGray"
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
            }
            Wait-AtlasContinue -Message $L.EnterContinue
        }

        "5" {
            Dibujar-Header
            Escribir-Centrado $L.T5Title "Magenta"
            Write-Host ""
            Escribir-Descripcion -Que $L.T5Que -Recomendacion $L.T5Rec -Precaucion $L.T5Warn

            try {
                $usuarios = Get-LocalUser -ErrorAction Stop | Where-Object { $_.Name -ne $env:USERNAME }
                if ($usuarios.Count -eq 0) {
                    Escribir-Centrado $L.T5NoOthers "Yellow"
                    Wait-AtlasContinue -Message $L.EnterContinue
                    break
                }

                $anchoPantalla3 = $Host.UI.RawUI.WindowSize.Width
                $i = 1
                foreach ($u in $usuarios) {
                    $estado = if ($u.Enabled) { $L.T5StateActive } else { $L.T5StateInactive }
                    $color  = if ($u.Enabled) { "White" } else { "DarkGray" }
                    $linea  = "  $i. $($u.Name) $estado"
                    $pad3   = [math]::Max(0, [math]::Floor(($anchoPantalla3 - $linea.Length) / 2))
                    Write-Host (" " * $pad3 + $linea) -ForegroundColor $color
                    $i++
                }

                Write-Host ""
                Escribir-Centrado $L.T5BackHint "DarkGray"
                Write-Host (" " * $padInput) -NoNewline
                $numStr = Read-Host $L.T5AskAccount
                if ([string]::IsNullOrWhiteSpace($numStr)) { break }

                $num = 0
                if (![int]::TryParse($numStr, [ref]$num) -or $num -lt 1 -or $num -gt $usuarios.Count) {
                    Escribir-Centrado $L.T5BadNumber "Red"
                    Wait-AtlasContinue -Message $L.EnterContinue
                    break
                }

                $cuentaElegida = @($usuarios)[$num - 1]
                if ($cuentaElegida.Enabled) {
                    Disable-LocalUser -Name $cuentaElegida.Name -ErrorAction Stop
                    Escribir-Centrado ($L.T5Disabled -f $cuentaElegida.Name) "Yellow"
                } else {
                    Enable-LocalUser -Name $cuentaElegida.Name -ErrorAction Stop
                    Escribir-Centrado ($L.T5Enabled -f $cuentaElegida.Name) "Green"
                }
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
            }
            Wait-AtlasContinue -Message $L.EnterContinue
        }

        "6" {
            Dibujar-Header
            Escribir-Centrado $L.T6Title "DarkCyan"
            Write-Host ""
            Escribir-Descripcion -Que $L.T6Que -Recomendacion $L.T6Rec -Precaucion $L.T6Warn

            try {
                $politicaActual = net accounts 2>$null | Select-String "Minimum|Maximum|Lockout" | ForEach-Object { "  " + $_.Line.Trim() }
                Escribir-Centrado $L.T6CurrentLbl "DarkGray"
                $politicaActual | ForEach-Object { Escribir-Centrado $_ "Gray" }
            } catch {}

            Write-Host ""
            Escribir-Centrado $L.T6NewLbl "DarkCyan"
            Write-Host ""

            Write-Host (" " * ($padInput - 8)) -NoNewline
            $minLen = Read-Host $L.T6AskMin

            Write-Host (" " * ($padInput - 8)) -NoNewline
            $maxAge = Read-Host $L.T6AskMax

            Write-Host (" " * ($padInput - 8)) -NoNewline
            $lockout = Read-Host $L.T6AskLock

            $cambios = 0
            try {
                if (![string]::IsNullOrWhiteSpace($minLen) -and $minLen -match '^\d+$') {
                    net accounts /minpwlen:$minLen | Out-Null; $cambios++
                }
                if (![string]::IsNullOrWhiteSpace($maxAge) -and $maxAge -match '^\d+$') {
                    net accounts /maxpwage:$maxAge | Out-Null; $cambios++
                }
                if (![string]::IsNullOrWhiteSpace($lockout) -and $lockout -match '^\d+$') {
                    net accounts /lockoutthreshold:$lockout | Out-Null; $cambios++
                }
                if ($cambios -gt 0) { Escribir-Centrado ($L.T6Applied -f $cambios) "Green" }
                else { Escribir-Centrado $L.T6NoChanges "DarkGray" }
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
            }
            Wait-AtlasContinue -Message $L.EnterContinue
        }

        "7" {
            Dibujar-Header
            Escribir-Centrado $L.T7Title "DarkYellow"
            Write-Host ""
            Escribir-Descripcion -Que $L.T7Que -Recomendacion $L.T7Rec -Precaucion $L.T7Warn
            Escribir-Centrado $L.T7Building "Cyan"

            try {
                $uac      = Obtener-EstadoUAC
                $usuarios = Get-LocalUser -ErrorAction Stop
                $admins   = @(Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name.Split("\")[-1] })
                $politica = net accounts 2>$null

                $lineas = @()
                $lineas += "=========================================================="
                $lineas += $L.T7TitleLine
                $lineas += $L.T7DateLine -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                $lineas += $L.T7HostLine -f $env:COMPUTERNAME
                $lineas += $L.T7UserLine -f $env:USERNAME
                $lineas += "=========================================================="
                $lineas += ""
                $lineas += $L.T7UacSec
                $lineas += "  " + $uac.Texto
                $lineas += ""
                $lineas += $L.T7UsersSec
                $lineas += "  {0,-22} {1,-14} {2,-12} {3}" -f $L.T4HUser, $L.T4HRole, $L.T4HState, $L.T4HKey
                $lineas += "  " + ("-" * 60)
                foreach ($u in $usuarios) {
                    $rol    = if ($admins -contains $u.Name) { 'Admin' } else { $L.RoleStd }
                    $estado = if ($u.Enabled) { $L.T4StateOn } else { $L.T4StateOff }
                    $clave  = if ($u.PasswordRequired) { $L.T4PwdReq } else { $L.T4PwdNo }
                    $lineas += "  {0,-22} {1,-14} {2,-12} {3}" -f $u.Name, $rol, $estado, $clave
                }
                $lineas += ""
                $lineas += $L.T7PolicySec
                $politica | ForEach-Object { $lineas += "  $_" }
                $lineas += ""
                $lineas += "=========================================================="
                $lineas += $L.T7Footer
                $lineas += "=========================================================="

                $rutaInforme = "$env:USERPROFILE\Desktop\" + ($L.ReportFile -f (Get-Date -Format 'yyyyMMdd_HHmm'))
                $lineas | Out-File -FilePath $rutaInforme -Encoding UTF8
                Escribir-Centrado $L.T7Saved "Green"
                Escribir-Centrado $rutaInforme "White"
            } catch {
                Escribir-Centrado ($L.ErrGeneric -f $_.Exception.Message) "Red"
            }
            Wait-AtlasContinue -Message $L.EnterContinue
        }

        "8" { return }
    }

} while ($true)
}

