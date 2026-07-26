# ============================================================
# Invoke-InstalarPaquetes  ->  Bulk App Installer (winget) GUI
#
# Interfaz Gráfica (WPF Panel) moderna para Atlas PC Support.
# Soporta catálogo por categorías, checkboxes interactivos Fluent,
# búsqueda dinámica en winget, perfiles cliente JSON e instalación
# asíncrona en vivo mediante PowerShell Runspace, ProcessStartInfo y Dispatcher.
#
# Atlas PC Support
# ============================================================

function Invoke-InstalarPaquetes {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Continue'
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction SilentlyContinue

    # Ensure STA ApartmentState for WPF
    try {
        if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
            [System.Threading.Thread]::CurrentThread.SetApartmentState([System.Threading.ApartmentState]::STA)
        }
    } catch {}

    # --- Language detection (env var -> config.json -> system culture -> en) ---
    function _Atlas-DetectLang {
        if ($env:ATLAS_LANG) { return [string]$env:ATLAS_LANG }
        try {
            $cfg = Join-Path $env:LOCALAPPDATA 'AtlasPC\config.json'
            if (Test-Path -LiteralPath $cfg) {
                $obj = Get-Content -Raw -LiteralPath $cfg -Encoding UTF8 | ConvertFrom-Json
                if ($obj -and $obj.language) { return [string]$obj.language }
            }
        } catch {}
        $sys = (Get-Culture).TwoLetterISOLanguageName
        if ($sys -eq 'es') { return 'es' }
        return 'en'
    }

    # --- Localized strings ---
    $T = @{
        en = @{
            Title                = 'ATLAS PC SUPPORT - BULK APP INSTALLER (winget)'
            SubTitle             = 'Bulk software installer via winget · Atlas PC Support'
            WingetVersion           = 'winget version: {0}'
            WingetUnavailable       = 'winget is not available on this system.'
            WingetUnavailableWin10  = 'winget is not installed. Click "[+] Install winget" to install automatically.'
            InstallWingetBtn        = '[+] Install winget'
            InstallingWinget        = '[...] Installing winget...'
            MenuSelectAll           = 'Select All'
            MenuDeselectAll         = 'Deselect All'
            MenuLoadProfile         = '[+] Load Profile'
            MenuSaveProfile         = '[*] Save Profile'
            SearchPlaceholder       = 'Type app name (e.g. VLC)...'
            SearchBtn               = '[>] Search Winget'
            CurrentSelection        = 'Current selection: {0} package(s)'
            NoSelection             = 'No packages selected.'
            InstallBtn              = '[>] INSTALL SELECTION'
            InstallingBtn           = '[...] Installing...'
            LiveLog                 = 'Live Installation Log:'
            ClearLog                = 'Clear Log'
            CleanTempName           = 'Clean Temporary Files'
            CleanTempCategory       = 'Cleanup'
            CleaningTemp            = 'Cleaning temporary files...'
            CleanupSummary          = 'Total freed: {0:N1} MB'
            NoteRequiresLic         = 'requires license'
            CategoryBrowsers        = 'Browsers'
            CategoryMultimedia      = 'Multimedia'
            CategoryOffice          = 'Office'
            CategoryCommunic        = 'Communication'
            CategoryUtilities       = 'Utilities'
            CategoryDevelop         = 'Development'
            CategorySecurity        = 'Security'
            CategoryNetwork         = 'Network'
            CategoryGaming          = 'Gaming'
            CategoryNotes           = 'Notes & Productivity'
            CategorySearch          = 'Search Results'
            ProfilePromptTitle      = 'Save Profile'
            ProfilePromptMsg        = 'Enter a name for this profile (e.g. client-alice):'
            ProfileSaved            = 'Profile saved: {0}'
            ProfileLoaded           = 'Loaded profile "{0}" with {1} package(s).'
            NoSelectionToInst       = 'No packages selected to install.'
            InstallStarted          = 'Starting installation of {0} package(s)...'
            Installing              = '[>] Installing: {0} ({1})...'
            InstalledOK             = '[OK] Successfully installed: {0}'
            AlreadyInstalled        = '[=] Already installed: {0}'
            InstallFailed           = '[X] Failed installing {0} (Exit code: {1})'
            InstallTimeout          = '[!] Timeout installing {0} (exceeded 3 minutes)'
            InstallException        = '[X] Exception installing {0}: {1}'
            Summary                 = 'Installation finished: {0} OK / {1} already installed / {2} failed'
            Searching               = '[>] Searching winget for: "{0}"...'
            SearchDone              = '[OK] Found {0} result(s) for "{0}".'
            SearchNoResults         = '[!] No results found for "{0}".'
        }
        es = @{
            Title                   = 'ATLAS PC SUPPORT - INSTALADOR DE PAQUETES (winget)'
            SubTitle                = 'Instalación masiva de software con winget · Atlas PC Support'
            WingetVersion           = 'Versión de winget: {0}'
            WingetUnavailable       = 'winget no está disponible en este sistema.'
            WingetUnavailableWin10  = 'winget no está instalado. Haz clic en "[+] Instalar winget" para instalarlo automáticamente.'
            InstallWingetBtn        = '[+] Instalar winget'
            InstallingWinget        = '[...] Instalando winget...'
            MenuSelectAll        = 'Seleccionar Todo'
            MenuDeselectAll      = 'Desmarcar Todo'
            MenuLoadProfile      = '[+] Cargar Perfil'
            MenuSaveProfile      = '[*] Guardar Perfil'
            SearchPlaceholder    = 'Nombre de app (ej. VLC)...'
            SearchBtn            = '[>] Buscar en Winget'
            CurrentSelection     = 'Selección actual: {0} paquete(s)'
            NoSelection          = 'Ningún paquete seleccionado.'
            InstallBtn           = '[>] INSTALAR SELECCIÓN'
            InstallingBtn        = '[...] Instalando...'
            LiveLog              = 'Registro de instalación en vivo:'
            ClearLog             = 'Limpiar Log'
            CleanTempName        = 'Limpiar archivos temporales'
            CleanTempCategory    = 'Limpieza'
            CleaningTemp         = 'Limpiando archivos temporales...'
            CleanupSummary       = 'Total liberado: {0:N1} MB'
            NoteRequiresLic      = 'requiere licencia'
            CategoryBrowsers     = 'Navegadores'
            CategoryMultimedia   = 'Multimedia'
            CategoryOffice       = 'Oficina'
            CategoryCommunic     = 'Comunicación'
            CategoryUtilities    = 'Utilidades'
            CategoryDevelop      = 'Desarrollo'
            CategorySecurity     = 'Seguridad'
            CategoryNetwork      = 'Redes'
            CategoryGaming       = 'Gaming'
            CategoryNotes        = 'Notas y Productividad'
            CategorySearch       = 'Resultados de Búsqueda'
            ProfilePromptTitle   = 'Guardar Perfil'
            ProfilePromptMsg     = 'Ingresa un nombre para este perfil (ej. cliente-alice):'
            ProfileSaved         = 'Perfil guardado: {0}'
            ProfileLoaded        = 'Cargado perfil "{0}" con {1} paquete(s).'
            NoSelectionToInst    = 'No hay paquetes seleccionados para instalar.'
            InstallStarted       = 'Iniciando instalación de {0} paquete(s)...'
            Installing           = '[>] Instalando: {0} ({1})...'
            InstalledOK          = '[OK] Instalado correctamente: {0}'
            AlreadyInstalled     = '[=] Ya instalado: {0}'
            InstallFailed        = '[X] Falló la instalación de {0} (Código: {1})'
            InstallTimeout       = '[!] Tiempo agotado al instalar {0} (superó 3 minutos)'
            InstallException     = '[X] Excepción instalando {0}: {1}'
            Summary              = 'Instalación finalizada: {0} OK / {1} ya instalados / {2} fallidos'
            Searching            = '[>] Buscando en winget: "{0}"...'
            SearchDone           = '[OK] Se encontraron {0} resultado(s) para "{0}".'
            SearchNoResults      = '[!] Sin resultados para "{0}".'
        }
    }

    $lang = _Atlas-DetectLang
    if (-not $T.ContainsKey($lang)) { $lang = 'en' }
    $L = $T[$lang]

    # --- Configuration ---
    $PROFILE_DIR = Join-Path $env:LOCALAPPDATA 'AtlasPC\winget-profiles'
    if (-not (Test-Path $PROFILE_DIR)) {
        New-Item -ItemType Directory -Path $PROFILE_DIR -Force | Out-Null
    }

    # Known package-id migrations (mostly msstore or renamed IDs) to keep old profiles working.
    $ID_MIGRATIONS = @{
        '9NFHQRDFLG40'                             = '9WZDNCRFJ3B4'            # JW Library
        'FreeDownloadManager.FreeDownloadManager'   = 'SoftDeluxe.FreeDownloadManager'
        'SimnetLtd.SimpleStickyNotes'               = 'Simnet.SimpleStickyNotes'
        'LanguageToolGmbH.LanguageToolForDesktop'   = 'Learneo.LanguageTool'
        'Seafile.Seafile-Client'                    = 'Seafile.Seafile'
    }

    function Resolve-PackageId {
        param([hashtable]$Pkg)
        if (-not $Pkg -or -not $Pkg.Id) { return $Pkg }

        $oldId = [string]$Pkg.Id
        if (-not $ID_MIGRATIONS.ContainsKey($oldId)) { return $Pkg }

        $newId = [string]$ID_MIGRATIONS[$oldId]
        if (-not $newId -or $newId -eq $oldId) { return $Pkg }

        $resolved = @{}
        foreach ($k in $Pkg.Keys) { $resolved[$k] = $Pkg[$k] }
        $resolved.Id = $newId
        if (-not $resolved.Source -and $newId -match '^[0-9A-Z]{12}$') { $resolved.Source = 'msstore' }
        return $resolved
    }

    # --- Catalog ---
    $CATALOG = [ordered]@{
        ($L.CategoryBrowsers) = @(
            @{ Id='Google.Chrome';                       Name='Google Chrome' },
            @{ Id='Mozilla.Firefox';                     Name='Mozilla Firefox' },
            @{ Id='Brave.Brave';                         Name='Brave Browser' },
            @{ Id='Opera.Opera';                         Name='Opera' }
        )
        ($L.CategoryMultimedia) = @(
            @{ Id='VideoLAN.VLC';                        Name='VLC Media Player' },
            @{ Id='Spotify.Spotify';                     Name='Spotify' },
            @{ Id='OBSProject.OBSStudio';                Name='OBS Studio' },
            @{ Id='Audacity.Audacity';                   Name='Audacity' },
            @{ Id='SoftDeluxe.FreeDownloadManager';       Name='Free Download Manager' },
            @{ Id='qBittorrent.qBittorrent';             Name='qBittorrent' }
        )
        ($L.CategoryOffice) = @(
            @{ Id='Microsoft.Office';                    Name='Microsoft 365'; NoteKey='RequiresLicense' },
            @{ Id='TheDocumentFoundation.LibreOffice';   Name='LibreOffice' },
            @{ Id='ONLYOFFICE.DesktopEditors';           Name='ONLYOFFICE Desktop Editors' },
            @{ Id='Adobe.Acrobat.Reader.64-bit';         Name='Adobe Acrobat Reader' }
        )
        ($L.CategoryNotes) = @(
            @{ Id='Notion.Notion';                       Name='Notion' },
            @{ Id='Obsidian.Obsidian';                   Name='Obsidian' },
            @{ Id='Simnet.SimpleStickyNotes';            Name='Simple Sticky Notes' },
            @{ Id='Learneo.LanguageTool';                Name='LanguageTool for Desktop' }
        )
        ($L.CategoryCommunic) = @(
            @{ Id='Zoom.Zoom';                           Name='Zoom' },
            @{ Id='Microsoft.Teams';                     Name='Microsoft Teams' },
            @{ Id='Discord.Discord';                     Name='Discord' },
            @{ Id='OpenWhisperSystems.Signal';           Name='Signal' },
            @{ Id='Telegram.TelegramDesktop';            Name='Telegram Desktop' },
            @{ Id='9NKSQGP7F2NH';                        Name='WhatsApp Desktop'; Source='msstore' },
            @{ Id='9WZDNCRFJ3B4';                        Name='JW Library'; Source='msstore' }
        )
        ($L.CategoryUtilities) = @(
            @{ Id='7zip.7zip';                           Name='7-Zip' },
            @{ Id='RARLab.WinRAR';                       Name='WinRAR' },
            @{ Id='Microsoft.PowerToys';                 Name='PowerToys' },
            @{ Id='voidtools.Everything';                Name='Everything (search)' },
            @{ Id='Greenshot.Greenshot';                 Name='Greenshot (screenshots)' },
            @{ Id='ShareX.ShareX';                       Name='ShareX' },
            @{ Id='WinDirStat.WinDirStat';               Name='WinDirStat' },
            @{ Id='Rufus.Rufus';                         Name='Rufus (USB boot)' },
            @{ Id='CPUID.CPU-Z';                         Name='CPU-Z' },
            @{ Id='TechPowerUp.GPU-Z';                   Name='GPU-Z' },
            @{ Id='CrystalDewWorld.CrystalDiskInfo';     Name='CrystalDiskInfo' },
            @{ Id='Seafile.Seafile';                     Name='Seafile Client' },
            @{ Id='w4po.ExplorerTabUtility';             Name='Explorer Tab Utility' }
        )
        ($L.CategoryDevelop) = @(
            @{ Id='Microsoft.VisualStudioCode';          Name='Visual Studio Code' },
            @{ Id='Git.Git';                             Name='Git' },
            @{ Id='GitHub.GitHubDesktop';                Name='GitHub Desktop' },
            @{ Id='OpenJS.NodeJS.LTS';                   Name='Node.js LTS' },
            @{ Id='Python.Python.3.12';                  Name='Python 3.12' },
            @{ Id='Microsoft.PowerShell';                Name='PowerShell 7' },
            @{ Id='Microsoft.WindowsTerminal';           Name='Windows Terminal' }
        )
        ($L.CategorySecurity) = @(
            @{ Id='Malwarebytes.Malwarebytes';           Name='Malwarebytes' },
            @{ Id='Bitdefender.Bitdefender';             Name='Bitdefender Antivirus Free' },
            @{ Id='Bitwarden.Bitwarden';                 Name='Bitwarden' },
            @{ Id='KeePassXCTeam.KeePassXC';             Name='KeePassXC' }
        )
        ($L.CategoryNetwork) = @(
            @{ Id='WireGuard.WireGuard';                 Name='WireGuard' }
        )
        ($L.CategoryGaming) = @(
            @{ Id='Valve.Steam';                         Name='Steam' },
            @{ Id='EpicGames.EpicGamesLauncher';         Name='Epic Games Launcher' }
        )
        ($L.CleanTempCategory) = @(
            @{ Id='__action:clean-temp'; Name=$L.CleanTempName; Type='action'; Handler='Clean-TempFiles' }
        )
    }

    if (-not (Get-Command Get-AtlasWingetPath -ErrorAction SilentlyContinue)) {
        function script:Get-AtlasWingetPath {
            [CmdletBinding()]
            param()
            $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
            if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
            try {
                $pkg = Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' -ErrorAction SilentlyContinue |
                       Sort-Object -Property Version -Descending | Select-Object -First 1
                if ($pkg -and $pkg.InstallLocation) {
                    $exe = Join-Path $pkg.InstallLocation 'winget.exe'
                    if (Test-Path -LiteralPath $exe) { return $exe }
                }
            } catch {}
            try {
                $candidates = Get-ChildItem -Path 'C:\Program Files\WindowsApps' -Filter 'winget.exe' -Recurse -ErrorAction SilentlyContinue |
                              Where-Object { $_.DirectoryName -like '*Microsoft.DesktopAppInstaller*' } |
                              Sort-Object -Property FullName -Descending
                if ($candidates) { return $candidates[0].FullName }
            } catch {}
            return $null
        }
    }

    if (-not (Get-Command Get-AtlasWingetCapabilities -ErrorAction SilentlyContinue)) {
        function script:Get-AtlasWingetCapabilities {
            [CmdletBinding()]
            param([string]$WingetPath)
            $caps = [ordered]@{ Available = $false; Version = $null; SupportsNoInteract = $false; SupportsMsStore = $false }
            if (-not $WingetPath -or -not (Test-Path -LiteralPath $WingetPath)) { return $caps }
            $caps.Available = $true
            $raw = try { (& $WingetPath --version 2>$null | Select-Object -First 1) } catch { $null }
            if (-not $raw) { return $caps }
            $text = ([string]$raw).Trim().TrimStart('v')
            $caps.Version = $text
            $parsed = $null
            if ([version]::TryParse(($text -split '-')[0], [ref]$parsed)) {
                $caps.SupportsNoInteract = ($parsed -ge [version]'1.3')
                $caps.SupportsMsStore    = ($parsed -ge [version]'1.2')
            } else {
                $caps.SupportsNoInteract = $true
                $caps.SupportsMsStore    = $true
            }
            return $caps
        }
    }

    $script:WingetPath = Get-AtlasWingetPath
    $script:WingetCaps = Get-AtlasWingetCapabilities -WingetPath $script:WingetPath

    function script:Test-WingetAvailable {
        return [bool]($script:WingetPath -and $script:WingetCaps.Available)
    }

    # Helper for XML attribute escaping
    function ConvertTo-XmlEscaped {
        param([string]$Text)
        if (-not $Text) { return '' }
        return [System.Security.SecurityElement]::Escape($Text)
    }

    $tVal         = if ($L -and $L.Title)           { $L.Title }           else { 'ATLAS PC SUPPORT - INSTALADOR DE PAQUETES' }
    $titleSafe    = ConvertTo-XmlEscaped $tVal

    $stVal        = if ($L -and $L.SubTitle)        { $L.SubTitle }        else { 'Instalacion masiva con winget' }
    $subTitleSafe = ConvertTo-XmlEscaped $stVal

    $saVal        = if ($L -and $L.MenuSelectAll)   { $L.MenuSelectAll }   else { 'Seleccionar Todo' }
    $selectAll    = ConvertTo-XmlEscaped $saVal

    $daVal        = if ($L -and $L.MenuDeselectAll) { $L.MenuDeselectAll } else { 'Desmarcar Todo' }
    $deselectAll  = ConvertTo-XmlEscaped $daVal

    $lpVal        = if ($L -and $L.MenuLoadProfile) { $L.MenuLoadProfile } else { 'Cargar Perfil' }
    $loadProf     = ConvertTo-XmlEscaped $lpVal

    $spVal        = if ($L -and $L.MenuSaveProfile) { $L.MenuSaveProfile } else { 'Guardar Perfil' }
    $saveProf     = ConvertTo-XmlEscaped $spVal

    $sbVal        = if ($L -and $L.SearchBtn)       { $L.SearchBtn }       else { 'Buscar' }
    $searchBtn    = ConvertTo-XmlEscaped $sbVal

    $nsVal        = if ($L -and $L.NoSelection)     { $L.NoSelection }     else { 'Sin seleccion' }
    $noSel        = ConvertTo-XmlEscaped $nsVal

    $ibVal             = if ($L -and $L.InstallBtn)      { $L.InstallBtn }      else { 'Instalar' }
    $instBtn           = ConvertTo-XmlEscaped $ibVal

    $iwVal             = if ($L -and $L.InstallWingetBtn) { $L.InstallWingetBtn } else { '[+] Instalar winget' }
    $installWingetBtn  = ConvertTo-XmlEscaped $iwVal

    $llVal        = if ($L -and $L.LiveLog)         { $L.LiveLog }         else { 'Log' }
    $liveLog      = ConvertTo-XmlEscaped $llVal

    $clVal        = if ($L -and $L.ClearLog)        { $L.ClearLog }        else { 'Limpiar Log' }
    $clearLog     = ConvertTo-XmlEscaped $clVal

    # ============================================================
    # WPF XAML Interface Definition with High Contrast Styling
    # ============================================================
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$titleSafe"
        Height="780" Width="1160" MinHeight="620" MinWidth="940"
        WindowStartupLocation="CenterScreen"
        Background="#0B0D12" Foreground="#F5F7FA"
        FontFamily="Segoe UI, Segoe UI Variable, sans-serif" FontSize="13">

    <Window.Resources>
        <SolidColorBrush x:Key="AccentBrush" Color="#0066FF"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#257BFF"/>
        <SolidColorBrush x:Key="SurfaceBrush" Color="#161920"/>
        <SolidColorBrush x:Key="SurfaceAltBrush" Color="#1F232D"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#2E3440"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#D0D5DD"/>
        <SolidColorBrush x:Key="TextMuted" Color="#98A2B3"/>

        <!-- Custom Styled CheckBox for High Visibility -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#F5F7FA"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Medium"/>
            <Setter Property="Margin" Value="6,6,12,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid x:Name="RootGrid" Background="Transparent" SnapsToDevicePixels="True">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="20"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <Border x:Name="CheckBoxBorder" Grid.Column="0" Width="18" Height="18"
                                    CornerRadius="4" Background="#1F232D" BorderBrush="#3B4252" BorderThickness="1.5">
                                <Path x:Name="CheckMark" Data="M 3 8 L 7 12 L 14 4"
                                      Stroke="White" StrokeThickness="2.2" StrokeLineJoin="Round" StrokeEndLineCap="Round"
                                      Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>

                            <ContentPresenter Grid.Column="1" Margin="10,0,0,0"
                                              HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="CheckBoxBorder" Property="Background" Value="#0066FF"/>
                                <Setter TargetName="CheckBoxBorder" Property="BorderBrush" Value="#0066FF"/>
                                <Setter TargetName="CheckMark" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="CheckBoxBorder" Property="BorderBrush" Value="#3B82F6"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.5"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Primary Button -->
        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#0066FF"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" CornerRadius="6" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BtnBorder" Property="Background" Value="#257BFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Background" Value="#0052CC"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button -->
        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#1F232D"/>
            <Setter Property="Foreground" Value="#F5F7FA"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="BorderBrush" Value="#3B4252"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" CornerRadius="6" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BtnBorder" Property="Background" Value="#2A2F3D"/>
                                <Setter TargetName="BtnBorder" Property="BorderBrush" Value="#4C566A"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Background" Value="#161920"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- TabControl Style -->
        <Style TargetType="TabControl">
            <Setter Property="Background" Value="#161920"/>
            <Setter Property="BorderBrush" Value="#2E3440"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabControl">
                        <Grid SnapsToDevicePixels="True">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <WrapPanel IsItemsHost="True" Grid.Row="0" Margin="0,0,0,8"/>

                            <Border Grid.Row="1" Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}"
                                    CornerRadius="8" Padding="{TemplateBinding Padding}">
                                <ContentPresenter x:Name="PART_SelectedContentHost" ContentSource="SelectedContent"/>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- TabItem Style -->
        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="#D0D5DD"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Margin" Value="0,0,6,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="TabBorder" CornerRadius="6" Background="#161920" BorderBrush="#2E3440" BorderThickness="1" Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="TabBorder" Property="Background" Value="#0066FF"/>
                                <Setter TargetName="TabBorder" Property="BorderBrush" Value="#0066FF"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="TabBorder" Property="BorderBrush" Value="#3B82F6"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#161920" BorderBrush="#2E3440" BorderThickness="1" CornerRadius="8" Padding="16,12" Margin="0,0,0,14">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Vertical">
                    <TextBlock Text="$titleSafe" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF"/>
                    <TextBlock Text="$subTitleSafe" FontSize="12" Foreground="#D0D5DD" Margin="0,2,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock x:Name="TxtWingetVer" Text="winget: ..." Foreground="#D0D5DD" VerticalAlignment="Center" Margin="0,0,14,0"/>
                    <Button x:Name="BtnInstallWingetAuto" Content="$installWingetBtn" Style="{StaticResource PrimaryBtn}" Visibility="Collapsed" Padding="12,6" FontSize="12" VerticalAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Toolbar & Search -->
        <Grid Grid.Row="1" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnSelectAll" Content="$selectAll" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                <Button x:Name="BtnDeselectAll" Content="$deselectAll" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                <Button x:Name="BtnLoadProfile" Content="$loadProf" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                <Button x:Name="BtnSaveProfile" Content="$saveProf" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
            </StackPanel>

            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                <TextBox x:Name="TxtSearchQuery" Width="240" Padding="8,6" Background="#161920" Foreground="#FFFFFF" CaretBrush="#FFFFFF" BorderBrush="#3B4252" BorderThickness="1" Margin="0,0,6,0"/>
                <Button x:Name="BtnSearchWinget" Content="$searchBtn" Style="{StaticResource SecondaryBtn}"/>
            </StackPanel>
        </Grid>

        <!-- Main Body: Tabs on Left, Installation Panel on Right -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1.5*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Categories Tabs -->
            <TabControl x:Name="TabCategories" Grid.Column="0" Background="#161920" BorderBrush="#2E3440" BorderThickness="1" Padding="14">
            </TabControl>

            <!-- Right Side Panel -->
            <Grid Grid.Column="2">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Selection Card -->
                <Border Grid.Row="0" Background="#161920" BorderBrush="#2E3440" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock x:Name="TxtSelectionCount" Text="Selection count" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF"/>
                        <ScrollViewer MaxHeight="80" VerticalScrollBarVisibility="Auto" Margin="0,6,0,0">
                            <TextBlock x:Name="TxtSelectionList" Text="$noSel" FontSize="12" Foreground="#D0D5DD" TextWrapping="Wrap"/>
                        </ScrollViewer>
                        <Button x:Name="BtnInstall" Content="$instBtn" Style="{StaticResource PrimaryBtn}" Margin="0,12,0,0" HorizontalAlignment="Stretch" FontSize="13"/>
                    </StackPanel>
                </Border>

                <!-- Log Header -->
                <Grid Grid.Row="1" Margin="0,0,0,6">
                    <TextBlock Text="$liveLog" FontSize="12" FontWeight="SemiBold" Foreground="#D0D5DD"/>
                    <Button x:Name="BtnClearLog" Content="$clearLog" HorizontalAlignment="Right" Style="{StaticResource SecondaryBtn}" Padding="6,2" FontSize="11"/>
                </Grid>

                <!-- Output Log Box -->
                <TextBox x:Name="TxtConsoleLog" Grid.Row="2" Background="#0A0B0E" Foreground="#00FF66" FontFamily="Consolas, Cascadia Code, monospace" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Padding="10" TextWrapping="Wrap"/>
            </Grid>
        </Grid>

        <!-- Footer / Progress Bar -->
        <Grid Grid.Row="3" Margin="0,12,0,0">
            <ProgressBar x:Name="PrgInstall" Height="6" Background="#161920" Foreground="#0066FF" BorderThickness="0" Minimum="0" Maximum="100"/>
        </Grid>
    </Grid>
</Window>
"@

    # Robust XAML Parsing with explicit try/catch
    $window = $null
    try {
        $window = [System.Windows.Markup.XamlReader]::Parse($xaml)
    } catch {
        Write-Host ""
        Write-Host ("[X] Error de parseo XAML en XamlReader: " + $_.Exception.Message) -ForegroundColor Red
        if ($_.Exception.InnerException) {
            Write-Host ("    Detalle: " + $_.Exception.InnerException.Message) -ForegroundColor Red
        }
        return
    }

    if (-not $window -or -not ($window -is [System.Windows.Window])) {
        Write-Host "[X] No se pudo instanciar un objeto Window de WPF." -ForegroundColor Red
        return
    }

    # Store control references safely inside $window.Tag
    $window.Tag = @{
        TxtWingetVer         = $window.FindName('TxtWingetVer')
        BtnInstallWingetAuto = $window.FindName('BtnInstallWingetAuto')
        BtnSelectAll         = $window.FindName('BtnSelectAll')
        BtnDeselectAll       = $window.FindName('BtnDeselectAll')
        BtnLoadProfile       = $window.FindName('BtnLoadProfile')
        BtnSaveProfile       = $window.FindName('BtnSaveProfile')
        TxtSearchQuery       = $window.FindName('TxtSearchQuery')
        BtnSearchWinget      = $window.FindName('BtnSearchWinget')
        TabCategories        = $window.FindName('TabCategories')
        TxtSelectionCount    = $window.FindName('TxtSelectionCount')
        TxtSelectionList     = $window.FindName('TxtSelectionList')
        BtnInstall           = $window.FindName('BtnInstall')
        BtnClearLog          = $window.FindName('BtnClearLog')
        TxtConsoleLog        = $window.FindName('TxtConsoleLog')
        PrgInstall           = $window.FindName('PrgInstall')
        L                    = $L
    }

    $ui = $window.Tag
    $script:AllCheckBoxes = @()

    # Helper: Append to Log Box
    $LogMessage = {
        param([string]$Text)
        if ($window -and $window.Tag -and $window.Dispatcher) {
            $window.Dispatcher.Invoke([System.Action]{
                $ctl = $window.Tag
                if ($ctl -and $ctl.TxtConsoleLog) {
                    $stamp = (Get-Date -Format 'HH:mm:ss')
                    $ctl.TxtConsoleLog.AppendText("[$stamp] $Text`n")
                    $ctl.TxtConsoleLog.ScrollToEnd()
                }
            })
        }
    }

    # Detect Winget version and set UI state
    if (Test-WingetAvailable) {
        $ver = if ($script:WingetCaps -and $script:WingetCaps.Version) { $script:WingetCaps.Version } else { '1.x' }
        if ($ui.TxtWingetVer) {
            $ui.TxtWingetVer.Text = ($L.WingetVersion -f $ver)
            $ui.TxtWingetVer.Foreground = [System.Windows.Media.Brushes]::Dimgray
        }
        if ($ui.BtnInstallWingetAuto) { $ui.BtnInstallWingetAuto.Visibility = 'Collapsed' }
    } else {
        if ($ui.TxtWingetVer) {
            $msgUnavail = if ($L -and $L.WingetUnavailableWin10) { $L.WingetUnavailableWin10 } else { $L.WingetUnavailable }
            $ui.TxtWingetVer.Text = $msgUnavail
            $ui.TxtWingetVer.Foreground = [System.Windows.Media.Brushes]::OrangeRed
        }
        if ($ui.BtnInstallWingetAuto) { $ui.BtnInstallWingetAuto.Visibility = 'Visible' }
        if ($ui.BtnInstall) { $ui.BtnInstall.IsEnabled = $false }
        if ($ui.BtnSearchWinget) { $ui.BtnSearchWinget.IsEnabled = $false }
    }

    # Update Selection Summary Card
    $UpdateSelectionSummary = {
        if (-not $window -or -not $window.Tag) { return }
        $ctl = $window.Tag
        $selectedItems = @()
        if ($script:AllCheckBoxes) {
            foreach ($cb in $script:AllCheckBoxes) {
                if ($cb -and $cb.IsChecked -eq $true) {
                    $pkg = $cb.Tag
                    if ($pkg) { $selectedItems += $pkg }
                }
            }
        }
        if ($ctl.TxtSelectionCount) {
            $fmt = if ($ctl.L -and $ctl.L.CurrentSelection) { $ctl.L.CurrentSelection } else { 'Selection: {0}' }
            $ctl.TxtSelectionCount.Text = ($fmt -f $selectedItems.Count)
        }
        if ($ctl.TxtSelectionList) {
            if ($selectedItems.Count -eq 0) {
                $ctl.TxtSelectionList.Text = if ($ctl.L -and $ctl.L.NoSelection) { $ctl.L.NoSelection } else { 'No selection' }
            } else {
                $names = ($selectedItems | ForEach-Object { if ($_.Name) { $_.Name } else { $_.Id } }) -join ', '
                $ctl.TxtSelectionList.Text = $names
            }
        }
    }

    # Populate Catalog Tabs
    if ($CATALOG -and $ui.TabCategories) {
        foreach ($catName in $CATALOG.Keys) {
            $tab = [System.Windows.Controls.TabItem]::new()
            $tab.Header = $catName

            $scroll = [System.Windows.Controls.ScrollViewer]::new()
            $scroll.VerticalScrollBarVisibility = 'Auto'

            $panel = [System.Windows.Controls.WrapPanel]::new()
            $panel.Orientation = 'Horizontal'
            $panel.Margin = [System.Windows.Thickness]::new(4)

            $catItems = $CATALOG[$catName]
            if ($catItems) {
                foreach ($pkg in $catItems) {
                    if (-not $pkg) { continue }
                    $cb = [System.Windows.Controls.CheckBox]::new()
                    $cb.Width = 240
                    $cb.Margin = [System.Windows.Thickness]::new(6, 6, 6, 6)

                    $dispName = if ($pkg.Name) { $pkg.Name } else { $pkg.Id }
                    if ($pkg.NoteKey -eq 'RequiresLicense') {
                        $licStr = if ($L -and $L.NoteRequiresLic) { $L.NoteRequiresLic } else { 'requires license' }
                        $dispName = "$dispName ($licStr)"
                    }
                    $cb.Content = $dispName
                    $cb.ToolTip = "Id: $($pkg.Id)"

                    $pkgEntry = @{ Id = $pkg.Id; Name = $dispName; Category = $catName }
                    if ($pkg.Type)    { $pkgEntry.Type    = $pkg.Type }
                    if ($pkg.Handler) { $pkgEntry.Handler = $pkg.Handler }
                    if ($pkg.Source)  { $pkgEntry.Source  = $pkg.Source }
                    $cb.Tag = $pkgEntry

                    $cb.add_Checked({ & $UpdateSelectionSummary })
                    $cb.add_Unchecked({ & $UpdateSelectionSummary })

                    $null = $panel.Children.Add($cb)
                    $script:AllCheckBoxes += $cb
                }
            }

            $scroll.Content = $panel
            $tab.Content = $scroll
            $null = $ui.TabCategories.Items.Add($tab)
        }
    }

    & $UpdateSelectionSummary

    # Event: Select All in Active Tab
    if ($ui.BtnSelectAll) {
        $ui.BtnSelectAll.add_Click({
            if (-not $window -or -not $window.Tag) { return }
            $ctl = $window.Tag
            if (-not $ctl.TabCategories) { return }
            $selectedTab = $ctl.TabCategories.SelectedItem
            if ($selectedTab -and $selectedTab.Content -and $selectedTab.Content.Content) {
                $panel = $selectedTab.Content.Content
                if ($panel -and $panel.Children) {
                    foreach ($child in $panel.Children) {
                        if ($child -is [System.Windows.Controls.CheckBox]) {
                            $child.IsChecked = $true
                        }
                    }
                }
            }
        })
    }

    # Event: Deselect All in Active Tab
    if ($ui.BtnDeselectAll) {
        $ui.BtnDeselectAll.add_Click({
            if (-not $window -or -not $window.Tag) { return }
            $ctl = $window.Tag
            if (-not $ctl.TabCategories) { return }
            $selectedTab = $ctl.TabCategories.SelectedItem
            if ($selectedTab -and $selectedTab.Content -and $selectedTab.Content.Content) {
                $panel = $selectedTab.Content.Content
                if ($panel -and $panel.Children) {
                    foreach ($child in $panel.Children) {
                        if ($child -is [System.Windows.Controls.CheckBox]) {
                            $child.IsChecked = $false
                        }
                    }
                }
            }
        })
    }

    # Event: Clear Log
    if ($ui.BtnClearLog) {
        $ui.BtnClearLog.add_Click({
            if ($window -and $window.Tag -and $window.Tag.TxtConsoleLog) {
                $window.Tag.TxtConsoleLog.Clear()
            }
        })
    }

    # Event: Save Profile
    if ($ui.BtnSaveProfile) {
        $ui.BtnSaveProfile.add_Click({
            $selectedPkgs = @()
            foreach ($cb in $script:AllCheckBoxes) {
                if ($cb -and $cb.IsChecked -eq $true -and $cb.Tag) { $selectedPkgs += $cb.Tag }
            }
            if ($selectedPkgs.Count -eq 0) {
                [System.Windows.MessageBox]::Show($L.NoSelection, $L.ProfilePromptTitle, 'OK', 'Warning') | Out-Null
                return
            }

            $name = [Microsoft.VisualBasic.Interaction]::InputBox($L.ProfilePromptMsg, $L.ProfilePromptTitle, 'client-profile')
            if ([string]::IsNullOrWhiteSpace($name)) { return }

            $safeName = ($name -replace '[^\w\-\.]', '_')
            $filePath = Join-Path $PROFILE_DIR "$safeName.json"

            $obj = [ordered]@{
                schema   = 'atlas-winget-profile-v1'
                name     = $name
                created  = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
                packages = @($selectedPkgs | ForEach-Object {
                    $p = [ordered]@{ id=$_.Id; name=$_.Name; category=$_.Category }
                    if ($_.Type)    { $p.type    = $_.Type }
                    if ($_.Handler) { $p.handler = $_.Handler }
                    if ($_.Source)  { $p.source  = $_.Source }
                    $p
                })
            }
            try {
                ConvertTo-Json -InputObject $obj -Depth 5 | Set-Content -Path $filePath -Encoding UTF8
                & $LogMessage ($L.ProfileSaved -f $filePath)
                [System.Windows.MessageBox]::Show(($L.ProfileSaved -f $filePath), $L.ProfilePromptTitle, 'OK', 'Information') | Out-Null
            } catch {
                & $LogMessage ("Save profile error: " + $_.Exception.Message)
            }
        })
    }

    # Event: Load Profile
    if ($ui.BtnLoadProfile) {
        $ui.BtnLoadProfile.add_Click({
            $dialog = [Microsoft.Win32.OpenFileDialog]::new()
            $dialog.InitialDirectory = $PROFILE_DIR
            $dialog.Filter = "JSON Profiles (*.json)|*.json"
            if ($dialog.ShowDialog() -eq $true) {
                try {
                    $raw = Get-Content -Raw -Path $dialog.FileName -Encoding UTF8
                    $obj = $raw | ConvertFrom-Json
                    $loadedIds = @{}
                    foreach ($p in $obj.packages) {
                        $entry = @{ Id=$p.id; Name=$p.name; Category=$p.category }
                        if ($p.type)    { $entry.Type    = [string]$p.type }
                        if ($p.handler) { $entry.Handler = [string]$p.handler }
                        if ($p.source)  { $entry.Source  = [string]$p.source }
                        $resolved = Resolve-PackageId -Pkg $entry
                        $loadedIds[$resolved.Id] = $true
                    }

                    # Apply to CheckBoxes
                    foreach ($cb in $script:AllCheckBoxes) {
                        if ($cb -and $cb.Tag -and $loadedIds.ContainsKey($cb.Tag.Id)) {
                            $cb.IsChecked = $true
                        } elseif ($cb) {
                            $cb.IsChecked = $false
                        }
                    }
                    & $LogMessage ($L.ProfileLoaded -f $obj.name, $loadedIds.Count)
                } catch {
                    & $LogMessage ("Load profile error: " + $_.Exception.Message)
                }
            }
        })
    }

    # Event: Unattended Winget Install
    if ($ui.BtnInstallWingetAuto) {
        $ui.BtnInstallWingetAuto.add_Click({
            if (-not $window -or -not $window.Tag) { return }
            $ctl = $window.Tag
            if (-not $ctl.BtnInstallWingetAuto) { return }

            $ctl.BtnInstallWingetAuto.IsEnabled = $false
            $ctl.BtnInstallWingetAuto.Content = $L.InstallingWinget
            & $LogMessage '[>] Iniciando instalacion desatendida de winget (App Installer)...'

            $logQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
            $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
            $rs.Open()
            $ps = [System.Management.Automation.PowerShell]::Create()
            $ps.Runspace = $rs

            $null = $ps.AddScript({
                param($queue)
                if (-not (Get-Command Install-AtlasWingetUnattended -ErrorAction SilentlyContinue)) {
                    function Install-AtlasWingetUnattended {
                        param($LogQueue)
                        $ErrorActionPreference = 'Stop'
                        function _Log { param([string]$Msg) if ($LogQueue) { $LogQueue.Enqueue($Msg) } else { Write-Host $Msg } }
                        try {
                            _Log '[1/3] Descargando dependencia VCLibs UWP...'
                            $vclibsPath = Join-Path $env:TEMP 'Microsoft.VCLibs.x64.14.00.Desktop.appx'
                            Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile $vclibsPath -UseBasicParsing -TimeoutSec 120
                            _Log '[1/3] Instalando VCLibs...'
                            Add-AppxPackage -Path $vclibsPath -ErrorAction Stop
                            Remove-Item -LiteralPath $vclibsPath -Force -ErrorAction SilentlyContinue

                            _Log '[2/3] Descargando dependencia UI.Xaml 2.8...'
                            $uiXamlPath = Join-Path $env:TEMP 'Microsoft.UI.Xaml.2.8.x64.appx'
                            Invoke-WebRequest -Uri 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile $uiXamlPath -UseBasicParsing -TimeoutSec 120
                            _Log '[2/3] Instalando UI.Xaml...'
                            Add-AppxPackage -Path $uiXamlPath -ErrorAction Stop
                            Remove-Item -LiteralPath $uiXamlPath -Force -ErrorAction SilentlyContinue

                            _Log '[3/3] Descargando App Installer (winget) msixbundle...'
                            $wingetBundlePath = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller.msixbundle'
                            Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $wingetBundlePath -UseBasicParsing -TimeoutSec 180
                            _Log '[3/3] Instalando App Installer (winget)...'
                            Add-AppxPackage -Path $wingetBundlePath -ErrorAction Stop
                            Remove-Item -LiteralPath $wingetBundlePath -Force -ErrorAction SilentlyContinue

                            _Log '[OK] Instalacion desatendida de winget completada exitosamente.'
                            return $true
                        } catch {
                            _Log ("[X] Error al instalar winget desatendido: {0}" -f $_.Exception.Message)
                            return $false
                        }
                    }
                }
                return (Install-AtlasWingetUnattended -LogQueue $queue)
            }).AddArgument($logQueue)

            $asyncResult = $ps.BeginInvoke()
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromMilliseconds(150)

            $tickHandler = {
                $msg = $null
                if ($logQueue) {
                    while ($logQueue.TryDequeue([ref]$msg)) {
                        if ($ctl -and $ctl.TxtConsoleLog) {
                            $stamp = (Get-Date -Format 'HH:mm:ss')
                            $ctl.TxtConsoleLog.AppendText("[$stamp] $msg`n")
                            $ctl.TxtConsoleLog.ScrollToEnd()
                        }
                    }
                }

                if ($asyncResult -and $asyncResult.IsCompleted) {
                    if ($timer) { $timer.Stop() }
                    $res = try { $ps.EndInvoke($asyncResult) } catch { $null }
                    try { $ps.Dispose() } catch {}
                    try { $rs.Dispose() } catch {}

                    # Re-detect winget path and capabilities
                    $script:WingetPath = Get-AtlasWingetPath
                    $script:WingetCaps = Get-AtlasWingetCapabilities -WingetPath $script:WingetPath

                    if ($script:WingetPath -and $script:WingetCaps.Available) {
                        if ($ctl.TxtWingetVer) {
                            $ver = if ($script:WingetCaps.Version) { $script:WingetCaps.Version } else { '1.x' }
                            $ctl.TxtWingetVer.Text = ($ctl.L.WingetVersion -f $ver)
                            $ctl.TxtWingetVer.Foreground = [System.Windows.Media.Brushes]::LightGreen
                        }
                        if ($ctl.BtnInstallWingetAuto) { $ctl.BtnInstallWingetAuto.Visibility = 'Collapsed' }
                        if ($ctl.BtnInstall) { $ctl.BtnInstall.IsEnabled = $true }
                        if ($ctl.BtnSearchWinget) { $ctl.BtnSearchWinget.IsEnabled = $true }
                        if ($script:AllCheckBoxes) {
                            foreach ($cb in $script:AllCheckBoxes) { if ($cb) { $cb.IsEnabled = $true } }
                        }
                    } else {
                        if ($ctl.BtnInstallWingetAuto) {
                            $ctl.BtnInstallWingetAuto.IsEnabled = $true
                            $ctl.BtnInstallWingetAuto.Content = $ctl.L.InstallWingetBtn
                        }
                    }
                }
            }.GetNewClosure()

            $timer.add_Tick($tickHandler)
            $timer.Start()
        })
    }

    # Event: Search Winget
    if ($ui.BtnSearchWinget) {
        $ui.BtnSearchWinget.add_Click({
            if (-not $window -or -not $window.Tag) { return }
            $ctl = $window.Tag
            if (-not $ctl.TxtSearchQuery) { return }
            $query = $ctl.TxtSearchQuery.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($query)) { return }

            & $LogMessage ($L.Searching -f $query)
            $ctl.BtnSearchWinget.IsEnabled = $false

            $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
            $rs.Open()
            $ps = [System.Management.Automation.PowerShell]::Create()
            $ps.Runspace = $rs

            $null = $ps.AddScript({
                param($term, $WingetExecutable, $SupportsNoInteract, $SupportsMsStore)
                $esc = [char]0x1B
                $cleanLines = {
                    param([object[]]$Raw)
                    $out = @()
                    foreach ($ln in $Raw) {
                        $s = [regex]::Replace([string]$ln, $esc + '\[[\d;\?]*[A-Za-z]', '')
                        if ($s.IndexOf([char]13) -ge 0) {
                            $segs = @($s -split "`r" | Where-Object { $_.Length -gt 0 })
                            if ($segs.Count -gt 0) { $s = $segs[-1] } else { $s = '' }
                        }
                        $out += $s
                    }
                    return ,$out
                }

                function Parse-SearchOutputInner {
                    param([string[]]$Lines, [string]$SourceTag)
                    $sepIdx = -1
                    for ($i = 0; $i -lt $Lines.Count; $i++) {
                        if ($Lines[$i] -match '^-{3,}') { $sepIdx = $i; break }
                    }
                    if ($sepIdx -le 0) { return @() }

                    $hdrLine = $Lines[$sepIdx - 1]
                    $sepLine = $Lines[$sepIdx]

                    $cols = [regex]::Matches($sepLine, '-+') | ForEach-Object {
                        @{ Start = $_.Index; Length = $_.Length }
                    }
                    if ($cols.Count -eq 0) { return @() }

                    $colNames = @()
                    foreach ($c in $cols) {
                        $start = $c.Start
                        if ($start -ge $hdrLine.Length) { $colNames += 'Col'; continue }
                        $len = [Math]::Min($c.Length, $hdrLine.Length - $start)
                        $colNames += $hdrLine.Substring($start, $len).Trim()
                    }

                    $results = @()
                    for ($i = $sepIdx + 1; $i -lt $Lines.Count; $i++) {
                        $line = $Lines[$i]
                        if ([string]::IsNullOrWhiteSpace($line)) { continue }
                        $row = @{}
                        for ($c = 0; $c -lt $cols.Count; $c++) {
                            $start = $cols[$c].Start
                            if ($start -ge $line.Length) { continue }
                            $end = if ($c -lt $cols.Count - 1) { $cols[$c+1].Start } else { $line.Length }
                            $end = [Math]::Min($end, $line.Length)
                            $val = $line.Substring($start, $end - $start).Trim()
                            $row[$colNames[$c]] = $val
                        }
                        $idVal = $null; $nameVal = $null; $verVal = $null
                        foreach ($k in $row.Keys) {
                            $kl = $k.ToLower()
                            if (-not $idVal   -and  $kl -eq 'id') { $idVal = $row[$k] }
                            if (-not $nameVal -and ($kl -eq 'name' -or $kl -eq 'nombre' -or $kl -eq 'nome' -or $kl -eq 'nom')) { $nameVal = $row[$k] }
                            if (-not $verVal  -and  $kl -like 'vers*') { $verVal = $row[$k] }
                        }
                        if ($idVal) {
                            $results += @{
                                Id      = $idVal
                                Name    = ($nameVal -as [string])
                                Version = ($verVal -as [string])
                                Source  = $SourceTag
                            }
                        }
                    }
                    return $results
                }

                $exe = if ($WingetExecutable -and (Test-Path -LiteralPath $WingetExecutable)) { $WingetExecutable } else { 'winget.exe' }
                $sources = @('winget')
                if ($SupportsMsStore) { $sources += 'msstore' }

                $allRes = @()
                foreach ($src in $sources) {
                    $searchArgs = @('search', $term, '--source', $src, '--accept-source-agreements')
                    if ($SupportsNoInteract) { $searchArgs += '--disable-interactivity' }
                    $out = try { & $exe $searchArgs 2>&1 } catch { $null }
                    if ($out) {
                        $lines = & $cleanLines @($out | ForEach-Object { [string]$_ })
                        $parsed = Parse-SearchOutputInner -Lines $lines -SourceTag $src
                        if ($parsed.Count -gt 0) { $allRes += $parsed }
                    }
                }
                if ($allRes.Count -eq 0) {
                    $searchArgs = @('search', $term, '--accept-source-agreements')
                    if ($SupportsNoInteract) { $searchArgs += '--disable-interactivity' }
                    $out = try { & $exe $searchArgs 2>&1 } catch { $null }
                    if ($out) {
                        $lines = & $cleanLines @($out | ForEach-Object { [string]$_ })
                        $parsed = Parse-SearchOutputInner -Lines $lines -SourceTag ''
                        if ($parsed.Count -gt 0) { $allRes += $parsed }
                    }
                }
                return @{ Query = $term; Results = $allRes }
            }).AddArgument($query).AddArgument($script:WingetPath).AddArgument([bool]($script:WingetCaps -and $script:WingetCaps.SupportsNoInteract)).AddArgument([bool]($script:WingetCaps -and $script:WingetCaps.SupportsMsStore))

            $asyncResult = $ps.BeginInvoke()

            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromMilliseconds(150)

            $tickHandler = {
                if ($asyncResult -and $asyncResult.IsCompleted) {
                    if ($timer) { $timer.Stop() }

                    $resObj = $null
                    try {
                        if ($ps -and $asyncResult) {
                            $resObj = $ps.EndInvoke($asyncResult)[0]
                        }
                    } catch {
                        & $LogMessage ("Search error: " + $_.Exception.Message)
                    } finally {
                        if ($ps) { try { $ps.Dispose() } catch {} }
                        if ($rs) { try { $rs.Close(); $rs.Dispose() } catch {} }
                    }

                    if ($ctl -and $ctl.BtnSearchWinget) { $ctl.BtnSearchWinget.IsEnabled = $true }

                    if (-not $resObj -or -not $resObj.Results -or $resObj.Results.Count -eq 0) {
                        & $LogMessage ($ctl.L.SearchNoResults -f $query)
                        return
                    }

                    $results = $resObj.Results
                    & $LogMessage ($ctl.L.SearchDone -f $results.Count, $query)

                    if (-not $ctl.TabCategories) { return }

                    # Find or Create Search Tab
                    $searchTab = $null
                    foreach ($t in $ctl.TabCategories.Items) {
                        if ($t.Header -eq $ctl.L.CategorySearch) { $searchTab = $t; break }
                    }
                    if (-not $searchTab) {
                        $searchTab = [System.Windows.Controls.TabItem]::new()
                        $searchTab.Header = $ctl.L.CategorySearch
                        $null = $ctl.TabCategories.Items.Add($searchTab)
                    }

                    $scroll = [System.Windows.Controls.ScrollViewer]::new()
                    $scroll.VerticalScrollBarVisibility = 'Auto'
                    $panel = [System.Windows.Controls.WrapPanel]::new()
                    $panel.Orientation = 'Horizontal'
                    $panel.Margin = [System.Windows.Thickness]::new(4)

                    foreach ($r in ($results | Select-Object -First 25)) {
                        $cb = [System.Windows.Controls.CheckBox]::new()
                        $cb.Width = 240
                        $cb.Margin = [System.Windows.Thickness]::new(6, 6, 6, 6)
                        $cb.Content = "$($r.Name) ($($r.Id))"
                        $cb.ToolTip = "Id: $($r.Id) | Source: $($r.Source)"
                        $cb.Tag = @{ Id = $r.Id; Name = $r.Name; Category = $ctl.L.CategorySearch; Source = $r.Source }

                        $cb.add_Checked({ & $UpdateSelectionSummary })
                        $cb.add_Unchecked({ & $UpdateSelectionSummary })

                        $null = $panel.Children.Add($cb)
                        $script:AllCheckBoxes += $cb
                    }

                    $scroll.Content = $panel
                    $searchTab.Content = $scroll
                    $ctl.TabCategories.SelectedItem = $searchTab
                    & $UpdateSelectionSummary
                }
            }.GetNewClosure()

            $timer.add_Tick($tickHandler)
            $timer.Start()
        })
    }

    # Event: Install Selection
    if ($ui.BtnInstall) {
        $ui.BtnInstall.add_Click({
            if (-not $window -or -not $window.Tag) { return }
            $ctl = $window.Tag

            $selectedPkgs = @()
            foreach ($cb in $script:AllCheckBoxes) {
                if ($cb -and $cb.IsChecked -eq $true -and $cb.Tag) {
                    $selectedPkgs += $cb.Tag
                }
            }

            if ($selectedPkgs.Count -eq 0) {
                [System.Windows.MessageBox]::Show($L.NoSelectionToInst, $L.Title, 'OK', 'Warning') | Out-Null
                return
            }

            $ctl.BtnInstall.IsEnabled = $false
            $ctl.BtnInstall.Content = $L.InstallingBtn
            if ($ctl.PrgInstall) {
                $ctl.PrgInstall.Value = 0
                $ctl.PrgInstall.Maximum = $selectedPkgs.Count
            }

            & $LogMessage ($L.InstallStarted -f $selectedPkgs.Count)

            $logQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
            $progressQueue = [System.Collections.Concurrent.ConcurrentQueue[int]]::new()

            $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
            $rs.Open()
            $ps = [System.Management.Automation.PowerShell]::Create()
            $ps.Runspace = $rs

            $null = $ps.AddScript({
                param($packages, $logQueue, $progressQueue, $L_Installing, $L_InstalledOK, $L_AlreadyInstalled, $L_InstallFailed, $L_InstallTimeout, $L_InstallException, $ID_MIGRATIONS, $L_CleaningTemp, $L_CleanupSummary, $WingetExecutable, $SupportsNoInteract, $SupportsMsStore)

                function Resolve-PackageIdInner {
                    param([hashtable]$Pkg, [hashtable]$Migrations)
                    if (-not $Pkg -or -not $Pkg.Id) { return $Pkg }
                    $oldId = [string]$Pkg.Id
                    if (-not $Migrations -or -not $Migrations.ContainsKey($oldId)) { return $Pkg }
                    $newId = [string]$Migrations[$oldId]
                    if (-not $newId -or $newId -eq $oldId) { return $Pkg }
                    $resolved = @{}
                    foreach ($k in $Pkg.Keys) { $resolved[$k] = $Pkg[$k] }
                    $resolved.Id = $newId
                    if (-not $resolved.Source -and $newId -match '^[0-9A-Z]{12}$') { $resolved.Source = 'msstore' }
                    return $resolved
                }

                function Clean-TempFilesInner {
                    param($queue, $CleaningTemp, $CleanupSummary)
                    $queue.Enqueue($CleaningTemp)
                    $totalFreed = 0L
                    $targets = @(
                        @{ Path = $env:TEMP;                                   Label = 'User TEMP' },
                        @{ Path = (Join-Path $env:LOCALAPPDATA 'Temp');        Label = 'LocalAppData Temp' },
                        @{ Path = 'C:\Windows\Temp';                           Label = 'Windows TEMP' },
                        @{ Path = 'C:\Windows\Prefetch';                       Label = 'Prefetch' }
                    )
                    foreach ($t in $targets) {
                        if (-not $t.Path -or -not (Test-Path -LiteralPath $t.Path)) { continue }
                        try {
                            $sizeBefore = 0L
                            Get-ChildItem -LiteralPath $t.Path -Recurse -Force -ErrorAction SilentlyContinue |
                                ForEach-Object { if ($_.PSIsContainer -eq $false) { $sizeBefore += $_.Length } }
                            Get-ChildItem -LiteralPath $t.Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
                                Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                            }
                            $sizeAfter = 0L
                            Get-ChildItem -LiteralPath $t.Path -Recurse -Force -ErrorAction SilentlyContinue |
                                ForEach-Object { if ($_.PSIsContainer -eq $false) { $sizeAfter += $_.Length } }
                            $freed = [math]::Max(0, $sizeBefore - $sizeAfter)
                            $totalFreed += $freed
                            $queue.Enqueue("   [OK] {0,-22} {1,10:N1} MB" -f $t.Label, ($freed / 1MB))
                        } catch {
                            $queue.Enqueue("   [!]  {0,-22} {1}" -f $t.Label, $_.Exception.Message)
                        }
                    }
                    $queue.Enqueue($CleanupSummary -f ($totalFreed / 1MB))
                }

                $okCount = 0; $alreadyCount = 0; $failCount = 0

                for ($i = 0; $i -lt $packages.Count; $i++) {
                    $p = $packages[$i]
                    $logQueue.Enqueue(($L_Installing -f $p.Name, $p.Id))

                    if ($p.Type -eq 'action' -and $p.Handler -eq 'Clean-TempFiles') {
                        Clean-TempFilesInner -queue $logQueue -CleaningTemp $L_CleaningTemp -CleanupSummary $L_CleanupSummary
                        $okCount++
                        $progressQueue.Enqueue($i + 1)
                        continue
                    }

                    try {
                        $pkgToInstall = Resolve-PackageIdInner -Pkg $p -Migrations $ID_MIGRATIONS
                        $wingetArgs = @('install', '--id', $pkgToInstall.Id, '--exact', '--silent',
                                        '--accept-package-agreements', '--accept-source-agreements')

                        if ($SupportsNoInteract) {
                            $wingetArgs += '--disable-interactivity'
                        }

                        if ($pkgToInstall.Source -and [string]$pkgToInstall.Source -ne '') {
                            if ([string]$pkgToInstall.Source -ne 'msstore' -or $SupportsMsStore) {
                                $wingetArgs += @('--source', [string]$pkgToInstall.Source)
                            } else {
                                $logQueue.Enqueue("[!] $($p.Name): fuente msstore no soportada por esta version de winget")
                                $failCount++
                                $progressQueue.Enqueue($i + 1)
                                continue
                            }
                        }

                        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                        $pinfo.FileName = if ($WingetExecutable -and (Test-Path -LiteralPath $WingetExecutable)) { $WingetExecutable } else { 'winget.exe' }
                        $pinfo.Arguments = ($wingetArgs -join ' ')
                        $pinfo.UseShellExecute = $false
                        $pinfo.CreateNoWindow = $true
                        $pinfo.RedirectStandardOutput = $false
                        $pinfo.RedirectStandardError = $false

                        $proc = [System.Diagnostics.Process]::Start($pinfo)

                        # 3 minutes timeout per installer
                        $exited = $proc.WaitForExit(180000)
                        if (-not $exited) {
                            try { $proc.Kill() } catch {}
                            $failCount++
                            $logQueue.Enqueue(($L_InstallTimeout -f $p.Name))
                        } else {
                            $exitCode = $proc.ExitCode
                            $alreadyInstalledCodes = @(
                                -1978335189,   # APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE
                                -1978335212,   # APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
                                -1978335135,   # APPINSTALLER_CLI_ERROR_NO_APPLICABLE_UPDATE
                                2316632083,    # 0x8A150013 unsigned
                                2316632068,    # 0x8A150004 unsigned
                                2316632145     # 0x8A150051 unsigned
                            )

                            if ($exitCode -eq 0) {
                                $okCount++
                                $logQueue.Enqueue(($L_InstalledOK -f $p.Name))
                            } elseif ($alreadyInstalledCodes -contains $exitCode) {
                                $alreadyCount++
                                $logQueue.Enqueue(($L_AlreadyInstalled -f $p.Name))
                            } else {
                                $failCount++
                                $formattedExit = if ($exitCode -lt 0) { ('0x{0:X8}' -f $exitCode) } else { $exitCode }
                                $logQueue.Enqueue(($L_InstallFailed -f $p.Name, $formattedExit))
                            }
                        }
                    } catch {
                        $failCount++
                        $logQueue.Enqueue(($L_InstallException -f $p.Name, $_.Exception.Message))
                    }

                    $progressQueue.Enqueue($i + 1)
                }

                return @{ OK = $okCount; Already = $alreadyCount; Fail = $failCount }
            }).AddArgument($selectedPkgs).AddArgument($logQueue).AddArgument($progressQueue).AddArgument($L.Installing).AddArgument($L.InstalledOK).AddArgument($L.AlreadyInstalled).AddArgument($L.InstallFailed).AddArgument($L.InstallTimeout).AddArgument($L.InstallException).AddArgument($ID_MIGRATIONS).AddArgument($L.CleaningTemp).AddArgument($L.CleanupSummary).AddArgument($script:WingetPath).AddArgument([bool]($script:WingetCaps -and $script:WingetCaps.SupportsNoInteract)).AddArgument([bool]($script:WingetCaps -and $script:WingetCaps.SupportsMsStore))

            $asyncResult = $ps.BeginInvoke()

            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromMilliseconds(150)

            $tickHandler = {
                $msg = $null
                if ($logQueue) {
                    while ($logQueue.TryDequeue([ref]$msg)) {
                        if ($ctl -and $ctl.TxtConsoleLog) {
                            $stamp = (Get-Date -Format 'HH:mm:ss')
                            $ctl.TxtConsoleLog.AppendText("[$stamp] $msg`n")
                            $ctl.TxtConsoleLog.ScrollToEnd()
                        }
                    }
                }

                $val = 0
                if ($progressQueue) {
                    while ($progressQueue.TryDequeue([ref]$val)) {
                        if ($ctl -and $ctl.PrgInstall) {
                            $ctl.PrgInstall.Value = $val
                        }
                    }
                }

                if ($asyncResult -and $asyncResult.IsCompleted) {
                    if ($timer) { $timer.Stop() }

                    $res = $null
                    try {
                        if ($ps -and $asyncResult) {
                            $res = $ps.EndInvoke($asyncResult)[0]
                        }
                    } catch {
                        & $LogMessage ("Install worker error: " + $_.Exception.Message)
                    } finally {
                        if ($ps) { try { $ps.Dispose() } catch {} }
                        if ($rs) { try { $rs.Close(); $rs.Dispose() } catch {} }
                    }

                    if ($ctl -and $ctl.BtnInstall) {
                        $ctl.BtnInstall.IsEnabled = $true
                        $ctl.BtnInstall.Content = $ctl.L.InstallBtn
                    }
                    if ($ctl -and $ctl.PrgInstall) {
                        $ctl.PrgInstall.Value = $ctl.PrgInstall.Maximum
                    }

                    if ($res) {
                        $summaryText = ($ctl.L.Summary -f $res.OK, $res.Already, $res.Fail)
                        if ($ctl -and $ctl.TxtConsoleLog) {
                            $stamp = (Get-Date -Format 'HH:mm:ss')
                            $ctl.TxtConsoleLog.AppendText("[$stamp] $summaryText`n")
                            $ctl.TxtConsoleLog.ScrollToEnd()
                        }
                        [System.Windows.MessageBox]::Show($summaryText, $ctl.L.Title, 'OK', 'Information') | Out-Null
                    }
                }
            }.GetNewClosure()

            $timer.add_Tick($tickHandler)
            $timer.Start()
        })
    }

    # Show Window safely
    if ($window -and ($window -is [System.Windows.Window])) {
        [void]$window.ShowDialog()
    } else {
        Write-Host "[X] Error: No se pudo mostrar la ventana WPF." -ForegroundColor Red
    }
}
