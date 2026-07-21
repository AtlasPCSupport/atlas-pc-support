# ============================================================
#  Atlas PC Support - launcher.ps1 (compilado)
#  Version: 1.0.0
#  Build:   2026-07-21 15:56:43
#  Repo:    https://github.com/mikepchelper-spec/atlas-pc-support
#
#  Uso:
#      Save get.ps1 locally and run: pwsh -ExecutionPolicy Bypass -File get.ps1
#
#  Este archivo es AUTOGENERADO por build.ps1. NO lo edites a mano.
#  Las fuentes estan en src/.
# ============================================================

#Requires -Version 5.1


# ============================================================
#  DATOS EMBEBIDOS
# ============================================================

$script:AtlasVersion = '1.0.0'
$script:AtlasBuildDate = '2026-07-21 15:56:43'
$script:AtlasToolsBaseUrl = 'https://raw.githubusercontent.com/mikepchelper-spec/atlas-pc-support/main/src/tools'

$script:AtlasToolsManifest = @'
{
  "$comment": "Tool manifest. Each entry describes one tool. The launcher uses this to render the panel''s tool tiles.",
  "tools": [
    {
      "id": "fase-0",
      "name": "Disable Legacy IPv6 Tunnels",
      "description": "Initial hardening: disables Teredo, 6to4 and ISATAP. Includes exportable technical log.",
      "category": "seguridad",
      "function": "Invoke-Fase0",
      "source": "Invoke-Fase0.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "parts-upgrade",
      "name": "Parts Upgrade Advisor",
      "description": "Analyzes RAM, CPU (socket/BGA) and storage (NVMe/SATA/M.2). Buying recommendations and warnings.",
      "category": "diagnostico",
      "function": "Invoke-PartsUpgrade",
      "source": "Invoke-PartsUpgrade.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "diagnostico-master",
      "name": "Full System Report",
      "description": "Comprehensive HTML report: system, hardware, CPU, RAM, storage, network, battery, BSOD, GPU slowness triage and Upgrade Advisor.",
      "category": "diagnostico",
      "function": "Invoke-DiagnosticoMaster",
      "source": "Invoke-DiagnosticoMaster.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": ["CPUZ", "BlueScreenView", "BatteryInfoView", "CrystalDiskInfo", "CrystalDiskMark", "HWiNFO"]
    },
    {
      "id": "diagnostico-eventos",
      "name": "Event Log Analyzer",
      "description": "Reads Event Viewer and interprets errors: reboots, hardware (WHEA/disk), crashes, drivers, security. Exports HTML.",
      "category": "diagnostico",
      "function": "Invoke-DiagnosticoEventos",
      "source": "Invoke-DiagnosticoEventos.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "printer-doctor",
      "name": "Printer Doctor",
      "description": "Printer diagnostics: printers, ports, drivers, spooler, queues, network test, print events, optional repairs and report export.",
      "category": "diagnostico",
      "function": "Invoke-PrinterDoctor",
      "source": "Invoke-PrinterDoctor.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "keyboard-doctor",
      "name": "Keyboard Doctor",
      "description": "Ghost typing and keyboard fault triage: devices, accessibility keys, battery pressure risk, HID events, isolation prompts and report export.",
      "category": "diagnostico",
      "function": "Invoke-KeyboardDoctor",
      "source": "Invoke-KeyboardDoctor.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "ai-readiness",
      "name": "AI Readiness Assessment",
      "description": "Self-contained local/cloud AI readiness audit: RAM, CPU, GPU/VRAM, storage, Ollama/cloud connectivity, 0-100 score, suggested models and HTML/JSON report export.",
      "category": "diagnostico",
      "function": "Invoke-AIReadiness",
      "source": "Invoke-AIReadiness.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "gpu-check",
      "name": "GPU Check",
      "description": "GPU diagnostics with optional stress test, GPU-Z and events analysis, NVIDIA telemetry when available, and JSON/HTML report export.",
      "category": "diagnostico",
      "function": "Invoke-GPUCheck",
      "source": "Invoke-GPUCheck.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": ["GPUZ", "FurMark2", "HWiNFO"]
    },
    {
      "id": "mantenimiento-pro",
      "name": "Deep Clean & Repair",
      "description": "Full maintenance suite: Defender, cleanup, DISM/SFC, system repair, final report.",
      "category": "mantenimiento",
      "function": "Invoke-MantenimientoPRO",
      "source": "Invoke-MantenimientoPRO.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "instalar-paquetes",
      "name": "Bulk App Installer (winget)",
      "description": "Install software in bulk via winget. Curated catalog by category, JSON profiles per client, built-in winget search, and a Cleanup section (clear temp files).",
      "category": "software",
      "function": "Invoke-InstalarPaquetes",
      "source": "Invoke-InstalarPaquetes.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "instalar-ms-store",
      "name": "Install Microsoft Store",
      "description": "Installs the Microsoft Store on systems where it is absent (LTSC, IoT Enterprise, corporate images). Uses wsreset -i on W11 or downloads the Appx bundle from Microsoft CDN.",
      "category": "software",
      "function": "Invoke-InstalarMicrosoftStore",
      "source": "Invoke-InstalarMicrosoftStore.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "instalar-runtimes",
      "name": "Install Runtime Dependencies",
      "description": "Installs common Windows runtime packages in bulk: VC++ 2015+ and 2013 (x64/x86), .NET Framework 3.5, DirectX, and optionally XNA and OpenAL for gaming. Two modes: Minimum and Full/Gaming.",
      "category": "software",
      "function": "Invoke-InstalarRuntimes",
      "source": "Invoke-InstalarRuntimes.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "actualizar-powershell",
      "name": "Install/Update PowerShell 7",
      "description": "Installs or updates PowerShell 7 (modern runtime). Better encoding, modern enums and fewer bugs than Windows PowerShell 5.1.",
      "category": "mantenimiento",
      "function": "Invoke-ActualizarPowerShell",
      "source": "Invoke-ActualizarPowerShell.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "mod-personalizacion",
      "name": "Windows Tweaks",
      "description": "Wallpaper via Win32 API, dark theme, accent color, taskbar tweaks and watermark.",
      "category": "mantenimiento",
      "function": "Invoke-Personalizacion",
      "source": "Invoke-Personalizacion.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "stop-services",
      "name": "Service Optimizer",
      "description": "Stops and sets to Manual non-essential services: telemetry, Xbox, sensors, fax, etc.",
      "category": "mantenimiento",
      "function": "Invoke-StopServices",
      "source": "Invoke-StopServices.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "fastcopy",
      "name": "FastCopy",
      "description": "Multi-source copy with profiles, comparison, MD5 and exportable summary. Replaces Robocopy with better UX.",
      "category": "copia",
      "function": "Invoke-FastCopy",
      "source": "Invoke-FastCopy.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": [
        "FastCopy"
      ]
    },
    {
      "id": "preparar-usb",
      "name": "Build Offline USB",
      "description": "Copies the panel and its dependencies to a USB drive for offline use. Auto-updates launcher when connected to the internet.",
      "category": "copia",
      "function": "Invoke-PrepararUSB",
      "source": "Invoke-PrepararUSB.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "respaldo-controladores",
      "name": "Driver Backup (External BAT)",
      "description": "Runs Respaldo-Controladores.bat from common desktop/USB locations. If missing, asks for a custom .bat/.cmd path and saves it.",
      "category": "copia",
      "function": "Invoke-RespaldoControladores",
      "source": "Invoke-RespaldoControladores.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "robocopy",
      "name": "Robocopy Mirror",
      "description": "Optimized robocopy-based copy: mirror mode, retries, centralized logging.",
      "category": "copia",
      "function": "Invoke-Robocopy",
      "source": "Invoke-Robocopy.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "selector-dns",
      "name": "DNS Switcher",
      "description": "Switches DNS server between profiles (Cloudflare, Google, OpenDNS, custom) with one click.",
      "category": "redes",
      "function": "Invoke-SelectorDNS",
      "source": "Invoke-SelectorDNS.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "hosts",
      "name": "Hosts File Editor",
      "description": "Windows HOSTS file editor with automatic backup.",
      "category": "redes",
      "function": "Invoke-HostsManager",
      "source": "Invoke-HostsManager.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "auditoria-router",
      "name": "Router Security Audit",
      "description": "Local network router scan and security audit.",
      "category": "redes",
      "function": "Invoke-AuditoriaRouter",
      "source": "Invoke-AuditoriaRouter.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "gestor-bitlocker",
      "name": "BitLocker Manager",
      "description": "BitLocker status, activation, suspension and recovery key export.",
      "category": "seguridad",
      "function": "Invoke-GestorBitLocker",
      "source": "Invoke-GestorBitLocker.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "menor-privilegio",
      "name": "Local Account Hardening",
      "description": "Audit and apply principle-of-least-privilege to local user accounts.",
      "category": "seguridad",
      "function": "Invoke-MenorPrivilegio",
      "source": "Invoke-MenorPrivilegio.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "extraer-licencias",
      "name": "Extract Product Keys",
      "description": "Extract Windows and Office product keys (read-only, safe).",
      "category": "seguridad",
      "function": "Invoke-ExtraerLicencias",
      "source": "Invoke-ExtraerLicencias.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "deduplicador",
      "name": "Deduplicator & Converter",
      "description": "Visual and exact file deduplicator and media converter (WebP to JPG/PNG, WebM to MP4). Supports GUI and Web modes.",
      "category": "copia",
      "function": "Invoke-Deduplicador",
      "source": "Invoke-Deduplicador.ps1",
      "requiresAdmin": false,
      "runsInNewWindow": true,
      "dependencies": []
    },
    {
      "id": "entrega-pc",
      "name": "PC Handover Report",
      "description": "Closeout protocol: final cleanup, summary, log and client handover preparation.",
      "category": "entrega",
      "function": "Invoke-EntregaPC",
      "source": "Invoke-EntregaPC.ps1",
      "requiresAdmin": true,
      "runsInNewWindow": true,
      "dependencies": []
    }
  ]
}

'@

$script:AtlasToolHashesJson = @'
{
    "generatedAt":  "2026-07-21T15:56:43.8327665-05:00",
    "algorithm":  "SHA256",
    "files":  {
                  "Invoke-ActualizarPowerShell.ps1":  "094062f8ebf7c9279dc8eeedaf2e635e6fad889630feb1e73ce73ab4bb107304",
                  "Invoke-AIReadiness.ps1":  "6f734eac4cdc9d3c8da7ba3b84fda9ad31fa596c2af239f8d69dd8ee3bcce280",
                  "Invoke-AuditoriaRouter.ps1":  "6500c6bfdc3f37e19ba3a66e3c6d348d0c9a50e782859918e10fc2ed344df8f6",
                  "Invoke-Deduplicador.ps1":  "b48df614411e9ace66f0c774ded389d1146fdc5c9f40867e92c15ad8bf0a5e3b",
                  "Invoke-DiagnosticoEventos.ps1":  "d8bcd80253e7118747e819618f8814729d615ff2fc359d7740ccad97b9c6cb1b",
                  "Invoke-DiagnosticoMaster.ps1":  "55b07593b743e653bbe47f887710edb2392c13e2811bdc755e62855f077c79f5",
                  "Invoke-EntregaPC.ps1":  "efd068e45dacef5d7460ad5abe3df8394e2e74b219777ca2434dfaa3cf85d80e",
                  "Invoke-ExtraerLicencias.ps1":  "03310f849ee3d4c826a984565aa9e6b51a0bca57f9f450d4c302eb8e97500f22",
                  "Invoke-Fase0.ps1":  "87f903655a9873823f44091b8adf696242556e2332a26183bea67618d07cf41a",
                  "Invoke-FastCopy.ps1":  "22c76639e7c2208a98d68446f2864ee6171dc7aabbca16de70e18c715b16e0e8",
                  "Invoke-GestorBitLocker.ps1":  "da6bb20b8e689b180e5ea20ad3274bdbf960279b6c5517db695edff90df13675",
                  "Invoke-GPUCheck.ps1":  "ec3c2e1c0a24d5ea6b38c40694bd0dd18a132102d518aa399c859fdb92bf9e28",
                  "Invoke-HostsManager.ps1":  "fe26ffe69919dc72b3cce423df40364e597caf387c72ce5e7d961ba42eba6e35",
                  "Invoke-InstalarMicrosoftStore.ps1":  "a96e3adf0507b6d0fa9ea4777e0141dda0c29f067e8e1dfcfa487c0b17a8105d",
                  "Invoke-InstalarPaquetes.ps1":  "3d4fc31116319b2d2e14733ea61ca0e62dc88819655070672e844cc4ca89160a",
                  "Invoke-InstalarRuntimes.ps1":  "1baad75ad5ccd5ce0459f8fb2e00e7ebca3eecbf0b56bb27483e197f5bcd3c29",
                  "Invoke-KeyboardDoctor.ps1":  "f4e2e484b3b08ccbc3d829b3893df82719943f6dc226f0e26dc72d0203cd5660",
                  "Invoke-MantenimientoPRO.ps1":  "475d9f7dd1cc3c7e26ee4afac6b0e698e65644216796a8fbb7a440ff323ce245",
                  "Invoke-MenorPrivilegio.ps1":  "1f0c63ad3081d0ad8d10fb8fea68ddc7de49918988032d4f2985a66442de0426",
                  "Invoke-PartsUpgrade.ps1":  "d8703a7ff9a2c6cc8aa42caedc4457451174b0ae0c6fa70d7b8a76038c03d3be",
                  "Invoke-Personalizacion.ps1":  "0212b1ac489832ac2d87242849dbd7be5e2a96ef80604f272a2f586d05cde5e3",
                  "Invoke-PrepararUSB.ps1":  "17abb8c974a3c9609a35498553bae7eeabf3d6a1c9630051e85b9b1ebf306413",
                  "Invoke-PrinterDoctor.ps1":  "fe78e343744f8182427a6c157f54e7a24185fe950dba86ca193bd02541a243d2",
                  "Invoke-RespaldoControladores.ps1":  "eb813133976f704c216e1fd8280d3869384040c67ee51fa72a007501edebedb5",
                  "Invoke-Robocopy.ps1":  "29f5abf91d82946d6fd7ffd7786de8165ad3e481e7075e7654fd4071328f0a7a",
                  "Invoke-SelectorDNS.ps1":  "71ed1eb9a2087f02c7f2810dd25f819a6dcfb8d9a897fbcc9de1a12341bf4e94",
                  "Invoke-StopServices.ps1":  "04013323966c6326b13567a265001a74731ab3bf28c9264b6c7348a4441d56fe"
              }
}
'@

$script:AtlasXamlTemplate = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="{{WINDOW_TITLE}}"
    Height="{{WINDOW_HEIGHT}}"
    Width="{{WINDOW_WIDTH}}"
    MinWidth="{{WINDOW_MIN_WIDTH}}"
    MinHeight="{{WINDOW_MIN_HEIGHT}}"
    WindowStartupLocation="CenterScreen"
    Background="{{BG_COLOR}}"
    FontFamily="{{FONT_FAMILY}}"
    FontSize="13"
    TextOptions.TextFormattingMode="Display"
    TextOptions.TextRenderingMode="ClearType">

    <Window.Resources>
        <!-- Paleta Atlas -->
        <SolidColorBrush x:Key="AccentBrush"         Color="{{ACCENT_COLOR}}"/>
        <SolidColorBrush x:Key="AccentHoverBrush"    Color="{{ACCENT_HOVER}}"/>
        <SolidColorBrush x:Key="AccentPressedBrush"  Color="{{ACCENT_PRESSED}}"/>
        <SolidColorBrush x:Key="SurfaceBrush"        Color="{{SURFACE_COLOR}}"/>
        <SolidColorBrush x:Key="SurfaceAltBrush"     Color="{{SURFACE_ALT_COLOR}}"/>
        <SolidColorBrush x:Key="BorderBrush"         Color="{{BORDER_COLOR}}"/>
        <SolidColorBrush x:Key="TextPrimaryBrush"    Color="{{TEXT_PRIMARY}}"/>
        <SolidColorBrush x:Key="TextSecondaryBrush"  Color="{{TEXT_SECONDARY}}"/>
        <SolidColorBrush x:Key="TextMutedBrush"      Color="{{TEXT_MUTED}}"/>

        <!-- Botón primario (estilo Fluent) -->
        <Style x:Key="AtlasPrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="{{CORNER_RADIUS}}"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="{StaticResource AccentHoverBrush}"/>
                                <Setter Property="BorderBrush" Value="{StaticResource AccentHoverBrush}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="{StaticResource AccentPressedBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Botón secundario (outline) -->
        <Style x:Key="AtlasSecondaryButton" TargetType="Button" BasedOn="{StaticResource AtlasPrimaryButton}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
        </Style>

        <!-- Tarjeta de herramienta -->
        <Style x:Key="ToolCard" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="{{CORNER_RADIUS}}"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="Margin" Value="0,0,12,12"/>
        </Style>

        <!-- Categoría pill -->
        <Style x:Key="CategoryPill" TargetType="RadioButton">
            <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border x:Name="Pill"
                                CornerRadius="{{CORNER_RADIUS}}"
                                Background="Transparent"
                                BorderBrush="Transparent"
                                BorderThickness="1">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Pill" Property="Background" Value="{StaticResource SurfaceAltBrush}"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Pill" Property="Background" Value="{StaticResource AccentBrush}"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Scrollbar minimalista -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="10"/>
        </Style>

        <!-- ComboBox Atlas (header) - ControlTemplate completo para que el combo se integre
             visualmente con la barra superior. Usa las brushes del tema (SurfaceBrush,
             BorderBrush, TextPrimaryBrush) para que empalme con el header como una sola pieza.
             Sin ControlTemplate, WPF pinta el combo con chrome Aero blanco aunque se fije
             Background/Foreground. -->
        <Style x:Key="AtlasComboBox" TargetType="ComboBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton x:Name="ToggleButton"
                                          Focusable="False"
                                          ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border x:Name="TBBorder"
                                                CornerRadius="{{CORNER_RADIUS}}"
                                                Background="{StaticResource SurfaceBrush}"
                                                BorderBrush="{StaticResource BorderBrush}"
                                                BorderThickness="1">
                                            <Grid>
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="22"/>
                                                </Grid.ColumnDefinitions>
                                                <Path Grid.Column="1"
                                                      Data="M 0 0 L 4 4 L 8 0 Z"
                                                      Fill="{StaticResource TextSecondaryBrush}"
                                                      HorizontalAlignment="Center"
                                                      VerticalAlignment="Center"/>
                                            </Grid>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter TargetName="TBBorder" Property="Background" Value="{StaticResource SurfaceAltBrush}"/>
                                            </Trigger>
                                            <Trigger Property="IsChecked" Value="True">
                                                <Setter TargetName="TBBorder" Property="Background" Value="{StaticResource SurfaceAltBrush}"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <ContentPresenter x:Name="ContentSite"
                                              IsHitTestVisible="False"
                                              Content="{TemplateBinding SelectionBoxItem}"
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                              Margin="{TemplateBinding Padding}"
                                              VerticalAlignment="Center"
                                              HorizontalAlignment="Left"
                                              TextElement.Foreground="{StaticResource TextPrimaryBrush}"/>
                            <Popup x:Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True"
                                   Focusable="False"
                                   PopupAnimation="Slide">
                                <Border Background="{StaticResource SurfaceBrush}"
                                        BorderBrush="{StaticResource BorderBrush}"
                                        BorderThickness="1"
                                        CornerRadius="{{CORNER_RADIUS}}"
                                        MinWidth="{TemplateBinding ActualWidth}"
                                        SnapsToDevicePixels="True">
                                    <ScrollViewer SnapsToDevicePixels="True">
                                        <StackPanel IsItemsHost="True"
                                                    KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Resources>
                <Style TargetType="ComboBoxItem">
                    <Setter Property="Background" Value="Transparent"/>
                    <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
                    <Setter Property="Padding" Value="10,6"/>
                    <Setter Property="Cursor" Value="Hand"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ComboBoxItem">
                                <Border x:Name="ItemBorder"
                                        Background="{TemplateBinding Background}"
                                        Padding="{TemplateBinding Padding}">
                                    <ContentPresenter TextElement.Foreground="{TemplateBinding Foreground}"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsHighlighted" Value="True">
                                        <Setter TargetName="ItemBorder" Property="Background" Value="{StaticResource SurfaceAltBrush}"/>
                                    </Trigger>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter TargetName="ItemBorder" Property="Background" Value="{StaticResource SurfaceAltBrush}"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </Style.Resources>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>   <!-- Header -->
            <RowDefinition Height="Auto"/>   <!-- Dashboard banner -->
            <RowDefinition Height="Auto"/>   <!-- Tabs -->
            <RowDefinition Height="*"/>      <!-- Sidebar + Content -->
            <RowDefinition Height="Auto"/>   <!-- Footer -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Border Grid.Row="0" Background="{StaticResource SurfaceBrush}"
                BorderBrush="{StaticResource BorderBrush}"
                BorderThickness="0,0,0,1"
                Padding="24,18">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Vertical">
                    <TextBlock Text="{{BRAND_NAME}}"
                               Foreground="{StaticResource AccentBrush}"
                               FontSize="22"
                               FontWeight="Bold"/>
                    <TextBlock Text="{{BRAND_TAGLINE}}"
                               Foreground="{StaticResource TextMutedBrush}"
                               FontSize="12"
                               Margin="0,2,0,0"/>
                </StackPanel>

                <TextBox x:Name="SearchBox"
                         Grid.Column="1"
                         MaxWidth="360"
                         Margin="24,0"
                         Padding="12,8"
                         Background="{StaticResource SurfaceAltBrush}"
                         Foreground="{StaticResource TextPrimaryBrush}"
                         BorderBrush="{StaticResource BorderBrush}"
                         FontSize="13"
                         VerticalContentAlignment="Center"
                         Tag="🔍  {{SEARCH_PLACEHOLDER}}"/>

                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock x:Name="AdminBadge"
                               Text=""
                               Foreground="{StaticResource TextMutedBrush}"
                               FontSize="11"
                               Margin="0,0,12,0"
                               VerticalAlignment="Center"/>
                    <ComboBox x:Name="LanguageCombo"
                              Style="{StaticResource AtlasComboBox}"
                              Width="130"
                              Height="34"
                              Margin="0,0,6,0"
                              FontSize="12"
                              VerticalContentAlignment="Center"
                              ToolTip="{{LANG_TOOLTIP}}"/>
                    <Button x:Name="BtnRestart"
                            Content="↻"
                            Style="{StaticResource AtlasSecondaryButton}"
                            Margin="0,0,8,0"
                            Padding="10,6"
                            FontSize="16"
                            ToolTip="{{RESTART_TOOLTIP}}"/>
                    <Button x:Name="BtnLogs"
                            Content="{{HEADER_LOGS}}"
                            Style="{StaticResource AtlasSecondaryButton}"
                            Margin="0,0,8,0"/>
                    <Button x:Name="BtnAbout"
                            Content="{{HEADER_ABOUT}}"
                            Style="{StaticResource AtlasSecondaryButton}"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- DASHBOARD BANNER (live system metrics) -->
        <Border Grid.Row="1"
                Background="{StaticResource SurfaceBrush}"
                BorderBrush="{StaticResource BorderBrush}"
                BorderThickness="0,0,0,1"
                Padding="24,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="2*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- CPU -->
                <StackPanel Grid.Column="0" Margin="0,0,16,0">
                    <Grid Margin="0,0,0,4">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0"
                                   Text="{{DASH_CPU}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="11"
                                   FontWeight="SemiBold"/>
                        <TextBlock Grid.Column="1"
                                   x:Name="DashCpuValue"
                                   Text="--%"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   FontWeight="SemiBold"/>
                    </Grid>
                    <ProgressBar x:Name="DashCpuBar"
                                 Height="6"
                                 Minimum="0"
                                 Maximum="100"
                                 Value="0"
                                 Background="{StaticResource SurfaceAltBrush}"
                                 Foreground="{StaticResource AccentBrush}"
                                 BorderThickness="0"/>
                </StackPanel>

                <!-- RAM -->
                <StackPanel Grid.Column="1" Margin="0,0,16,0">
                    <Grid Margin="0,0,0,4">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0"
                                   Text="{{DASH_RAM}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="11"
                                   FontWeight="SemiBold"/>
                        <TextBlock Grid.Column="1"
                                   x:Name="DashRamValue"
                                   Text="--%"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   FontWeight="SemiBold"/>
                    </Grid>
                    <ProgressBar x:Name="DashRamBar"
                                 Height="6"
                                 Minimum="0"
                                 Maximum="100"
                                 Value="0"
                                 Background="{StaticResource SurfaceAltBrush}"
                                 Foreground="{StaticResource AccentBrush}"
                                 BorderThickness="0"/>
                </StackPanel>

                <!-- DISK (system drive) -->
                <StackPanel Grid.Column="2" Margin="0,0,16,0">
                    <Grid Margin="0,0,0,4">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0"
                                   Text="{{DASH_DISK}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="11"
                                   FontWeight="SemiBold"/>
                        <TextBlock Grid.Column="1"
                                   x:Name="DashDiskValue"
                                   Text="--%"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   FontWeight="SemiBold"/>
                    </Grid>
                    <ProgressBar x:Name="DashDiskBar"
                                 Height="6"
                                 Minimum="0"
                                 Maximum="100"
                                 Value="0"
                                 Background="{StaticResource SurfaceAltBrush}"
                                 Foreground="{StaticResource AccentBrush}"
                                 BorderThickness="0"/>
                </StackPanel>

                <!-- ALERTS -->
                <StackPanel Grid.Column="3" VerticalAlignment="Center">
                    <TextBlock Text="{{DASH_ALERTS}}"
                               Foreground="{StaticResource TextMutedBrush}"
                               FontSize="11"
                               FontWeight="SemiBold"
                               Margin="0,0,0,4"/>
                    <TextBlock x:Name="DashAlertsText"
                               Text="--"
                               Foreground="{StaticResource TextSecondaryBrush}"
                               FontSize="12"
                               TextWrapping="Wrap"/>
                </StackPanel>

                <!-- RESOURCE MONITOR CONTROLS -->
                <StackPanel Grid.Column="4"
                            Orientation="Horizontal"
                            VerticalAlignment="Center"
                            Margin="12,0,0,0">
                    <Button x:Name="BtnDashMonitorToggle"
                            Content="{{DASH_TOGGLE_OFF}}"
                            Style="{StaticResource AtlasSecondaryButton}"
                            Padding="10,6"
                            FontSize="12"
                            ToolTip="{{DASH_TOGGLE_TOOLTIP}}"/>
                    <Button x:Name="BtnDashRefresh"
                            Content="↻"
                            Style="{StaticResource AtlasSecondaryButton}"
                            Margin="8,0,0,0"
                            Padding="10,6"
                            FontSize="16"
                            ToolTip="{{DASH_REFRESH_TOOLTIP}}"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- TABS / CATEGORÍAS -->
        <Border Grid.Row="2"
                Background="{{BG_COLOR}}"
                Padding="24,12,24,0">
            <StackPanel x:Name="CategoryBar"
                        Orientation="Horizontal"
                        VerticalAlignment="Center"/>
        </Border>

        <!-- SIDEBAR + CONTENT -->
        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="240"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- SIDEBAR (always visible PC info) -->
            <Border Grid.Column="0"
                    Background="{StaticResource SurfaceBrush}"
                    BorderBrush="{StaticResource BorderBrush}"
                    BorderThickness="0,1,1,0"
                    Padding="16,16,16,16">
                <ScrollViewer VerticalScrollBarVisibility="Auto"
                              HorizontalScrollBarVisibility="Disabled">
                    <StackPanel>
                        <TextBlock Text="{{SIDEBAR_HEADER}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="11"
                                   FontWeight="SemiBold"
                                   Margin="0,0,0,12"/>

                        <!-- Hostname -->
                        <TextBlock Text="{{SIDEBAR_HOST}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideHost"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="13"
                                   FontWeight="SemiBold"
                                   TextTrimming="CharacterEllipsis"
                                   Margin="0,0,0,10"/>

                        <!-- User -->
                        <TextBlock Text="{{SIDEBAR_USER}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideUser"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   TextTrimming="CharacterEllipsis"
                                   Margin="0,0,0,10"/>

                        <!-- OS -->
                        <TextBlock Text="{{SIDEBAR_OS}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideOS"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   TextWrapping="Wrap"
                                   Margin="0,0,0,10"/>

                        <!-- CPU model -->
                        <TextBlock Text="{{SIDEBAR_CPU}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideCpu"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="11"
                                   TextWrapping="Wrap"
                                   Margin="0,0,0,10"/>

                        <!-- RAM total -->
                        <TextBlock Text="{{SIDEBAR_RAM}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideRam"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   Margin="0,0,0,10"/>

                        <!-- Uptime -->
                        <TextBlock Text="{{SIDEBAR_UPTIME}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideUptime"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   Margin="0,0,0,10"/>

                        <!-- IP -->
                        <TextBlock Text="{{SIDEBAR_IP}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideIp"
                                   Text="--"
                                   Foreground="{StaticResource TextPrimaryBrush}"
                                   FontSize="12"
                                   TextTrimming="CharacterEllipsis"
                                   Margin="0,0,0,10"/>

                        <!-- Last sync (when dashboard was last refreshed) -->
                        <TextBlock Text="{{SIDEBAR_LASTSYNC}}"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="10"
                                   Margin="0,0,0,2"/>
                        <TextBlock x:Name="SideLastSync"
                                   Text="--"
                                   Foreground="{StaticResource TextMutedBrush}"
                                   FontSize="11"
                                   FontStyle="Italic"
                                   Margin="0,0,0,4"/>
                    </StackPanel>
                </ScrollViewer>
            </Border>

            <!-- CONTENT -->
            <ScrollViewer Grid.Column="1"
                          VerticalScrollBarVisibility="Auto"
                          HorizontalScrollBarVisibility="Disabled"
                          Padding="24,12,24,12">
                <ItemsControl x:Name="ToolsGrid">
                    <ItemsControl.ItemsPanel>
                        <ItemsPanelTemplate>
                            <WrapPanel Orientation="Horizontal"/>
                        </ItemsPanelTemplate>
                    </ItemsControl.ItemsPanel>
                </ItemsControl>
            </ScrollViewer>
        </Grid>

        <!-- FOOTER -->
        <Border Grid.Row="4"
                Background="{StaticResource SurfaceBrush}"
                BorderBrush="{StaticResource BorderBrush}"
                BorderThickness="0,1,0,0"
                Padding="24,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0"
                           x:Name="StatusText"
                           Text="{{STATUS_READY}}"
                           Foreground="{StaticResource TextMutedBrush}"
                           FontSize="11"
                           VerticalAlignment="Center"/>
                <TextBlock Grid.Column="1"
                           x:Name="CoffeeLink"
                           Text="☕ {{COFFEE_LABEL}}"
                           Foreground="{StaticResource AccentBrush}"
                           FontSize="11"
                           FontWeight="SemiBold"
                           Cursor="Hand"
                           VerticalAlignment="Center"
                           Margin="0,0,16,0"
                           ToolTip="{{COFFEE_TOOLTIP}}"/>
                <TextBlock Grid.Column="2"
                           Text="{{BRAND_COPYRIGHT}} · v{{BRAND_VERSION}}"
                           Foreground="{StaticResource TextMutedBrush}"
                           FontSize="11"
                           VerticalAlignment="Center"/>
            </Grid>
        </Border>
    </Grid>
</Window>

'@

$script:AtlasToolKitSource = @'
# ============================================================
# Atlas PC Support - Tool toolkit (helpers compartidos para TOOLS)
#
# A diferencia del resto de lib/, este archivo esta pensado para estar
# disponible DENTRO de cada tool, que corre aislada en su propia ventana.
# El ToolRunner inyecta el contenido de este archivo (embebido en el launcher
# y por tanto cubierto por launcher.ps1.sha256) al principio del wrapper
# temporal de cada tool. Asi se deduplican los banners, el calculo de carpeta
# de reportes y el armado de HTML que hoy cada tool reimplementa.
#
# REGLAS para este archivo:
#   - Debe ser 100% autonomo (no depende de otras funciones de lib/).
#   - Nunca debe lanzar al cargarse (solo define funciones).
#   - Cambios aqui afectan a TODAS las tools: mantener minimo y robusto.
# ============================================================

function Write-AtlasHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)] [string]$Title,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )
    $line = '=' * ([Math]::Min(60, [Math]::Max(12, $Title.Length + 6)))
    Write-Host ''
    Write-Host $line -ForegroundColor $Color
    Write-Host ("  {0}" -f $Title) -ForegroundColor $Color
    Write-Host $line -ForegroundColor $Color
}

function Write-AtlasStep {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [>] {0}" -f $Message) -ForegroundColor Cyan
}

function Write-AtlasSuccess {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [OK] {0}" -f $Message) -ForegroundColor Green
}

function Write-AtlasWarn {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [!] {0}" -f $Message) -ForegroundColor Yellow
}

function Write-AtlasFailure {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [X] {0}" -f $Message) -ForegroundColor Red
}

function Wait-AtlasExit {
    [CmdletBinding()]
    param([string]$Message = 'Presiona ENTER para cerrar')
    Write-Host ''
    [void](Read-Host $Message)
}

function Get-AtlasReportDir {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$SubFolder)
    $base = Join-Path $env:USERPROFILE 'Documents\AtlasPC\reports'
    $dir  = if ($SubFolder) { Join-Path $base $SubFolder } else { $base }
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function Get-AtlasReportPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$Prefix,
        [string]$Extension = 'html',
        [string]$SubFolder
    )
    $dir   = Get-AtlasReportDir -SubFolder $SubFolder
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $ext   = $Extension.TrimStart('.')
    return (Join-Path $dir ("{0}_{1}.{2}" -f $Prefix, $stamp, $ext))
}

function ConvertTo-AtlasHtmlEncoded {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][string]$Text)
    process {
        if ($null -eq $Text) { return '' }
        return [System.Net.WebUtility]::HtmlEncode($Text)
    }
}

function ConvertTo-AtlasHtmlDocument {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$BodyHtml,
        [string]$AccentColor = '#0078D4',
        [string]$Subtitle
    )
    $safeTitle    = ConvertTo-AtlasHtmlEncoded $Title
    $safeSubtitle = if ($Subtitle) { ConvertTo-AtlasHtmlEncoded $Subtitle } else { '' }
    $generated    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $subtitleHtml = if ($safeSubtitle) { "<p class='subtitle'>$safeSubtitle</p>" } else { '' }
    return @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
  :root { --accent: $AccentColor; }
  * { box-sizing: border-box; }
  body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 0; color: #1b1b1b; background: #f3f3f3; }
  header { background: var(--accent); color: #fff; padding: 24px 32px; }
  header h1 { margin: 0; font-size: 22px; }
  header .subtitle { margin: 6px 0 0; opacity: .9; font-size: 14px; }
  main { padding: 24px 32px; max-width: 1100px; margin: 0 auto; }
  section { background: #fff; border: 1px solid #e1e1e1; border-radius: 8px; padding: 16px 20px; margin-bottom: 16px; }
  h2 { font-size: 16px; border-bottom: 2px solid var(--accent); padding-bottom: 6px; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #eee; }
  th { background: #fafafa; }
  footer { text-align: center; color: #888; font-size: 12px; padding: 16px; }
  .ok { color: #107c10; } .warn { color: #c19c00; } .err { color: #d13438; }
</style>
</head>
<body>
<header>
  <h1>$safeTitle</h1>
  $subtitleHtml
</header>
<main>
$BodyHtml
</main>
<footer>Atlas PC Support &middot; generado $generated</footer>
</body>
</html>
"@
}

'@

# ============================================================
#  LIBRERIAS (lib/)
# ============================================================

# ---- lib\Branding.ps1 ----
# ============================================================
# Atlas PC Support - Branding loader
# Carga branding.json del repo o de una ruta personalizada.
# Los revendedores / técnicos editan branding.json para cambiar
# nombre, logo, colores, título de ventana, etc. sin tocar el código.
# ============================================================

# Convierte recursivamente un objeto salido de ConvertFrom-Json a hashtable.
# Necesario porque ConvertFrom-Json -AsHashtable solo existe en PS 7+ y
# el panel debe funcionar tambien en Windows PowerShell 5.1.
function ConvertTo-AtlasHashtable {
    param($Obj)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [System.Management.Automation.PSCustomObject]) {
        $ht = @{}
        foreach ($p in $Obj.PSObject.Properties) {
            $ht[$p.Name] = ConvertTo-AtlasHashtable $p.Value
        }
        return $ht
    }
    if ($Obj -is [System.Collections.IEnumerable] -and -not ($Obj -is [string])) {
        $list = New-Object System.Collections.ArrayList
        foreach ($item in $Obj) { [void]$list.Add((ConvertTo-AtlasHashtable $item)) }
        return ,$list.ToArray()
    }
    return $Obj
}

function ConvertFrom-AtlasJson {
    param([Parameter(Mandatory)][string]$Json)
    $obj = $Json | ConvertFrom-Json
    return (ConvertTo-AtlasHashtable $obj)
}

function Get-AtlasBranding {
    [CmdletBinding()]
    param(
        [string]$OverridePath
    )

    $defaultBranding = @{
        brand = @{
            name         = "ATLAS PC SUPPORT"
            shortName    = "Atlas"
            tagline      = "Panel unificado de soporte técnico para Windows"
            version      = "1.0.0"
            companyUrl   = "https://github.com/mikepchelper-spec/atlas-pc-support"
            supportEmail = ""
            copyright    = "© 2026 Atlas PC Support"
        }
        theme = @{
            accentColor      = "#FF5500"
            secondaryColor   = "#002147"
            darkMode         = $true
            useSystemAccent  = $false
            cornerRadius     = 8
            fontFamily       = "Segoe UI Variable"
        }
        language = "auto"
        window = @{
            title       = "ATLAS PC SUPPORT · Panel v1.0"
            width       = 1100
            height      = 720
            minWidth    = 900
            minHeight   = 600
            showSearch  = $true
            showFooter  = $true
        }
        behavior = @{
            autoElevate        = $true
            logPath            = "%LOCALAPPDATA%\AtlasPC\logs"
            dependenciesPath   = "%LOCALAPPDATA%\AtlasPC\bin"
            defaultCategory    = "Diagnóstico"
            confirmBeforeRun   = $false
        }
        categories = @(
            @{ id = "diagnostico";    label = "Diagnóstico";    icon = "🔍"; order = 1 }
            @{ id = "mantenimiento";  label = "Mantenimiento";  icon = "🛠"; order = 2 }
            @{ id = "copia";          label = "Backup & Sync";  icon = "📁"; order = 3 }
            @{ id = "redes";          label = "Redes";          icon = "🌐"; order = 4 }
            @{ id = "seguridad";      label = "Seguridad";      icon = "🔒"; order = 5 }
            @{ id = "software";       label = "Software";       icon = "📦"; order = 6 }
            @{ id = "entrega";        label = "Entrega";        icon = "✅"; order = 7 }
        )
    }

    $candidatePaths = @()
    if ($OverridePath) { $candidatePaths += $OverridePath }
    if ($PSScriptRoot) {
        $candidatePaths += (Join-Path $PSScriptRoot "..\..\branding.json")
        $candidatePaths += (Join-Path $PSScriptRoot "branding.json")
    }
    if ($env:LOCALAPPDATA) {
        $candidatePaths += (Join-Path $env:LOCALAPPDATA "AtlasPC\branding.json")
    }
    if ($env:APPDATA) {
        $candidatePaths += (Join-Path $env:APPDATA "AtlasPC\branding.json")
    }

    foreach ($path in $candidatePaths) {
        if ($path -and (Test-Path $path)) {
            try {
                $userBranding = ConvertFrom-AtlasJson (Get-Content -Raw -Path $path)
                Write-Verbose "Branding cargado desde: $path"
                return (Merge-AtlasBranding $defaultBranding $userBranding)
            } catch {
                Write-Warning "No se pudo parsear $path — usando branding por defecto. Error: $_"
            }
        }
    }

    return $defaultBranding
}

function Merge-AtlasBranding {
    param(
        [hashtable]$Default,
        [hashtable]$Override
    )
    $merged = @{}
    foreach ($key in $Default.Keys) { $merged[$key] = $Default[$key] }
    foreach ($key in $Override.Keys) {
        if ($merged.ContainsKey($key) -and $merged[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $merged[$key] = Merge-AtlasBranding $merged[$key] $Override[$key]
        } else {
            $merged[$key] = $Override[$key]
        }
    }
    return $merged
}

function Expand-AtlasPath {
    param([string]$Path)
    if (-not $Path) { return "" }
    return [System.Environment]::ExpandEnvironmentVariables($Path)
}

function Set-AtlasPathAcl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CurrentUserOnly
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if ($env:OS -ne 'Windows_NT') { return $true }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $perm = if ($item.PSIsContainer) { '(OI)(CI)F' } else { 'F' }
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        if (-not $sid) { return $false }

        & icacls $Path '/inheritance:r' | Out-Null
        & icacls $Path '/grant:r' ("*{0}:{1}" -f $sid, $perm) | Out-Null
        if (-not $CurrentUserOnly) {
            & icacls $Path '/grant:r' ("*S-1-5-18:{0}" -f $perm) | Out-Null
            & icacls $Path '/grant:r' ("*S-1-5-32-544:{0}" -f $perm) | Out-Null
        }
        return $true
    } catch {
        return $false
    }
}

function Initialize-AtlasSecureDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CurrentUserOnly
    )

    $expanded = Expand-AtlasPath $Path
    if (-not $expanded) { return $null }
    if (-not (Test-Path -LiteralPath $expanded)) {
        New-Item -ItemType Directory -Path $expanded -Force | Out-Null
    }
    [void](Set-AtlasPathAcl -Path $expanded -CurrentUserOnly:$CurrentUserOnly)
    return $expanded
}


# ---- lib\Strings.ps1 ----
# ============================================================
# Atlas PC Support - Strings / i18n
# Supported languages: en (default), es, pt, fr, de, it, ro
# To add another: copy the 'en' block and translate the values.
# ============================================================

$script:AtlasStringsDict = @{
    'es' = @{
        'app.tagline'             = 'Panel unificado de soporte técnico para Windows'
        'search.placeholder'      = 'Buscar herramienta...'
        'category.all'            = 'Todo'
        'category.diagnostico'    = 'Diagnóstico'
        'category.mantenimiento'  = 'Mantenimiento'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Redes'
        'category.seguridad'      = 'Seguridad'
        'category.software'       = 'Software'
        'category.entrega'        = 'Entrega'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Usuario'
        'header.logs'             = '📋 Logs'
        'header.about'            = 'ℹ️ Acerca de'
        'button.run'              = '▶  Ejecutar'
        'badge.requiresAdmin'     = '🛡  requiere admin'
        'status.ready'            = 'Listo'
        'status.launching'        = 'Lanzando: {0}...'
        'status.lastRun'          = 'Listo — última: {0}'
        'status.toolsShown'       = '{0} herramienta(s) mostrada(s)'
        'logs.empty'              = 'Aún no hay logs. Ejecuta alguna herramienta primero.'
        'about.title'             = 'Acerca de'
        'about.description'       = 'Panel inspirado en WinUtil (Chris Titus Tech).{NEWLINE}Licencia: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Presiona Enter para cerrar esta ventana...'
        'tool.error'              = '[!] Error en {0}: {1}'
        'tool.notLoaded'          = "No se pudo serializar la función '{0}'. ¿Está cargada?"
        'footer.coffee'           = 'Invítame un café'
        'footer.coffeeTooltip'    = 'Apoya el proyecto con una donación vía PayPal'
        'header.language'         = 'Idioma'
        'header.languageTooltip'  = 'Cambiar idioma del panel'
        'header.restartTooltip'   = 'Reiniciar el panel (aplica el cambio de idioma)'
        'language.restartRequired'= 'Reinicia el panel para aplicar el nuevo idioma.'
        'restart.instructions'    = "El panel se cerrará ahora.{NEWLINE}{NEWLINE}Para reabrirlo, vuelve a ejecutar:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disco'
        'dash.alerts'             = 'Alertas'
        'dash.alerts.none'        = 'Sin alertas — el equipo está bien.'
        'dash.refreshTooltip'     = 'Actualizar dashboard ahora'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Activar/desactivar monitor de recursos en vivo'
        'dash.monitor.paused'     = 'Monitor de recursos apagado — pulsa Monitor OFF para activarlo.'
        'dash.alert.cpu'          = 'CPU al {0}%'
        'dash.alert.ram'          = 'RAM al {0}%'
        'dash.alert.disk'         = 'Disco {0} al {1}% lleno'
        'dash.alert.uptime'       = 'Uptime alto ({0} días) — considera reiniciar'
        'dash.alert.battery'      = 'Batería baja ({0}%)'
        'dash.alert.pendingReboot'= 'Reinicio pendiente de Windows Update'
        'sidebar.header'          = 'EQUIPO'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Usuario'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM total'
        'sidebar.uptime'          = 'Encendido desde'
        'sidebar.ip'              = 'IP local'
        'sidebar.lastSync'        = 'Última actualización'
        'sidebar.uptimeFmt'       = '{0}d {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB libres)'
    }
    'en' = @{
        'app.tagline'             = 'Unified Windows tech-support panel'
        'search.placeholder'      = 'Search tool...'
        'category.all'            = 'All'
        'category.diagnostico'    = 'Diagnostics'
        'category.mantenimiento'  = 'Maintenance'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Network'
        'category.seguridad'      = 'Security'
        'category.software'       = 'Software'
        'category.entrega'        = 'Handover'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 User'
        'header.logs'             = '📋 Logs'
        'header.about'            = 'ℹ️ About'
        'button.run'              = '▶  Run'
        'badge.requiresAdmin'     = '🛡  requires admin'
        'status.ready'            = 'Ready'
        'status.launching'        = 'Launching: {0}...'
        'status.lastRun'          = 'Ready — last: {0}'
        'status.toolsShown'       = '{0} tool(s) shown'
        'logs.empty'              = 'No logs yet. Run a tool first.'
        'about.title'             = 'About'
        'about.description'       = 'Panel inspired by WinUtil (Chris Titus Tech).{NEWLINE}License: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Press Enter to close this window...'
        'tool.error'              = '[!] Error in {0}: {1}'
        'tool.notLoaded'          = "Could not serialize the function '{0}'. Is it loaded?"
        'footer.coffee'           = 'Buy me a coffee'
        'footer.coffeeTooltip'    = 'Support the project with a PayPal donation'
        'header.language'         = 'Language'
        'header.languageTooltip'  = 'Change panel language'
        'header.restartTooltip'   = 'Restart the panel (apply language change)'
        'language.restartRequired'= 'Restart the panel to apply the new language.'
        'restart.instructions'    = "The panel will now close.{NEWLINE}{NEWLINE}To reopen it, run:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disk'
        'dash.alerts'             = 'Alerts'
        'dash.alerts.none'        = 'No alerts — system looks healthy.'
        'dash.refreshTooltip'     = 'Refresh dashboard now'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Turn live resource monitor on/off'
        'dash.monitor.paused'     = 'Resource monitor is off — click Monitor OFF to enable it.'
        'dash.alert.cpu'          = 'CPU at {0}%'
        'dash.alert.ram'          = 'RAM at {0}%'
        'dash.alert.disk'         = 'Disk {0} at {1}% used'
        'dash.alert.uptime'       = 'Long uptime ({0} days) — consider rebooting'
        'dash.alert.battery'      = 'Battery low ({0}%)'
        'dash.alert.pendingReboot'= 'Windows Update reboot pending'
        'sidebar.header'          = 'SYSTEM'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'User'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'Total RAM'
        'sidebar.uptime'          = 'Up since'
        'sidebar.ip'              = 'Local IP'
        'sidebar.lastSync'        = 'Last refresh'
        'sidebar.uptimeFmt'       = '{0}d {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB free)'
    }
    'ro' = @{
        'app.tagline'             = 'Panou unificat de suport tehnic pentru Windows'
        'search.placeholder'      = 'Caută unealta...'
        'category.all'            = 'Toate'
        'category.diagnostico'    = 'Diagnostic'
        'category.mantenimiento'  = 'Mentenanță'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Rețea'
        'category.seguridad'      = 'Securitate'
        'category.software'       = 'Software'
        'category.entrega'        = 'Predare'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utilizator'
        'header.logs'             = '📋 Jurnale'
        'header.about'            = 'ℹ️ Despre'
        'button.run'              = '▶  Rulează'
        'badge.requiresAdmin'     = '🛡  necesită admin'
        'status.ready'            = 'Gata'
        'status.launching'        = 'Se lansează: {0}...'
        'status.lastRun'          = 'Gata — ultima: {0}'
        'status.toolsShown'       = '{0} unealtă(e) afișată(e)'
        'logs.empty'              = 'Încă nu există jurnale. Rulează o unealtă mai întâi.'
        'about.title'             = 'Despre'
        'about.description'       = 'Panou inspirat din WinUtil (Chris Titus Tech).{NEWLINE}Licență: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Apasă Enter pentru a închide această fereastră...'
        'tool.error'              = '[!] Eroare în {0}: {1}'
        'tool.notLoaded'          = "Nu s-a putut serializa funcția '{0}'. Este încărcată?"
        'footer.coffee'           = 'Oferă-mi o cafea'
        'footer.coffeeTooltip'    = 'Susține proiectul cu o donație prin PayPal'
        'header.language'         = 'Limbă'
        'header.languageTooltip'  = 'Schimbă limba panoului'
        'header.restartTooltip'   = 'Repornește panoul (aplică schimbarea de limbă)'
        'language.restartRequired'= 'Repornește panoul pentru a aplica noua limbă.'
        'restart.instructions'    = "Panoul se va închide acum.{NEWLINE}{NEWLINE}Pentru a-l redeschide, rulează:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disc'
        'dash.alerts'             = 'Alerte'
        'dash.alerts.none'        = 'Fără alerte — sistemul e în regulă.'
        'dash.refreshTooltip'     = 'Reîmprospătează dashboard'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Pornește/oprește monitorul live de resurse'
        'dash.monitor.paused'     = 'Monitorul de resurse este oprit — apasă Monitor OFF pentru activare.'
        'dash.alert.cpu'          = 'CPU la {0}%'
        'dash.alert.ram'          = 'RAM la {0}%'
        'dash.alert.disk'         = 'Disc {0} folosit {1}%'
        'dash.alert.uptime'       = 'Uptime mare ({0} zile) — repornește'
        'dash.alert.battery'      = 'Baterie scăzută ({0}%)'
        'dash.alert.pendingReboot'= 'Restart Windows Update în așteptare'
        'sidebar.header'          = 'SISTEM'
        'sidebar.host'            = 'Nume PC'
        'sidebar.user'            = 'Utilizator'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM total'
        'sidebar.uptime'          = 'Pornit din'
        'sidebar.ip'              = 'IP local'
        'sidebar.lastSync'        = 'Ultima actualizare'
        'sidebar.uptimeFmt'       = '{0}z {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB liberi)'
    }
    'pt' = @{
        'app.tagline'             = 'Painel unificado de suporte técnico para Windows'
        'search.placeholder'      = 'Buscar ferramenta...'
        'category.all'            = 'Tudo'
        'category.diagnostico'    = 'Diagnóstico'
        'category.mantenimiento'  = 'Manutenção'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Rede'
        'category.seguridad'      = 'Segurança'
        'category.software'       = 'Software'
        'category.entrega'        = 'Entrega'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utilizador'
        'header.logs'             = '📋 Registos'
        'header.about'            = 'ℹ️ Acerca'
        'button.run'              = '▶  Executar'
        'badge.requiresAdmin'     = '🛡  requer admin'
        'status.ready'            = 'Pronto'
        'status.launching'        = 'A iniciar: {0}...'
        'status.lastRun'          = 'Pronto — última: {0}'
        'status.toolsShown'       = '{0} ferramenta(s) mostrada(s)'
        'logs.empty'              = 'Ainda sem registos. Executa uma ferramenta primeiro.'
        'about.title'             = 'Acerca'
        'about.description'       = 'Painel inspirado no WinUtil (Chris Titus Tech).{NEWLINE}Licença: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Pressiona Enter para fechar esta janela...'
        'tool.error'              = '[!] Erro em {0}: {1}'
        'tool.notLoaded'          = "Não foi possível serializar a função '{0}'. Está carregada?"
        'footer.coffee'           = 'Paga-me um café'
        'footer.coffeeTooltip'    = 'Apoia o projeto com um donativo PayPal'
        'header.language'         = 'Idioma'
        'header.languageTooltip'  = 'Mudar idioma do painel'
        'header.restartTooltip'   = 'Reiniciar o painel (aplicar mudança de idioma)'
        'language.restartRequired'= 'Reinicia o painel para aplicar o novo idioma.'
        'restart.instructions'    = "O painel irá fechar agora.{NEWLINE}{NEWLINE}Para reabrir, executa:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disco'
        'dash.alerts'             = 'Alertas'
        'dash.alerts.none'        = 'Sem alertas — sistema saudável.'
        'dash.refreshTooltip'     = 'Atualizar painel agora'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Ativar/desativar monitor de recursos em tempo real'
        'dash.monitor.paused'     = 'Monitor de recursos desligado — clica Monitor OFF para ativar.'
        'dash.alert.cpu'          = 'CPU em {0}%'
        'dash.alert.ram'          = 'RAM em {0}%'
        'dash.alert.disk'         = 'Disco {0} a {1}% cheio'
        'dash.alert.uptime'       = 'Uptime alto ({0} dias) — reinicie'
        'dash.alert.battery'      = 'Bateria fraca ({0}%)'
        'dash.alert.pendingReboot'= 'Reinício do Windows Update pendente'
        'sidebar.header'          = 'SISTEMA'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Utilizador'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM total'
        'sidebar.uptime'          = 'Ligado desde'
        'sidebar.ip'              = 'IP local'
        'sidebar.lastSync'        = 'Última atualização'
        'sidebar.uptimeFmt'       = '{0}d {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB livres)'
    }
    'fr' = @{
        'app.tagline'             = 'Panneau unifié de support technique pour Windows'
        'search.placeholder'      = 'Rechercher un outil...'
        'category.all'            = 'Tout'
        'category.diagnostico'    = 'Diagnostic'
        'category.mantenimiento'  = 'Maintenance'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Réseau'
        'category.seguridad'      = 'Sécurité'
        'category.software'       = 'Logiciels'
        'category.entrega'        = 'Livraison'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utilisateur'
        'header.logs'             = '📋 Journaux'
        'header.about'            = 'ℹ️ À propos'
        'button.run'              = '▶  Exécuter'
        'badge.requiresAdmin'     = '🛡  admin requis'
        'status.ready'            = 'Prêt'
        'status.launching'        = 'Lancement : {0}...'
        'status.lastRun'          = 'Prêt — dernier : {0}'
        'status.toolsShown'       = '{0} outil(s) affiché(s)'
        'logs.empty'              = 'Aucun journal pour l''instant. Lance un outil d''abord.'
        'about.title'             = 'À propos'
        'about.description'       = 'Panneau inspiré de WinUtil (Chris Titus Tech).{NEWLINE}Licence : MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Appuyez sur Entrée pour fermer cette fenêtre...'
        'tool.error'              = '[!] Erreur dans {0} : {1}'
        'tool.notLoaded'          = "Impossible de sérialiser la fonction '{0}'. Est-elle chargée ?"
        'footer.coffee'           = 'Offre-moi un café'
        'footer.coffeeTooltip'    = 'Soutiens le projet avec un don PayPal'
        'header.language'         = 'Langue'
        'header.languageTooltip'  = 'Changer la langue du panneau'
        'header.restartTooltip'   = 'Redémarrer le panneau (appliquer le changement de langue)'
        'language.restartRequired'= 'Redémarre le panneau pour appliquer la nouvelle langue.'
        'restart.instructions'    = "Le panneau va se fermer maintenant.{NEWLINE}{NEWLINE}Pour le rouvrir, exécute :{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disque'
        'dash.alerts'             = 'Alertes'
        'dash.alerts.none'        = 'Aucune alerte — système OK.'
        'dash.refreshTooltip'     = 'Actualiser le tableau de bord'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Activer/désactiver le moniteur de ressources'
        'dash.monitor.paused'     = "Moniteur de ressources désactivé — cliquez sur Monitor OFF pour l'activer."
        'dash.alert.cpu'          = 'CPU à {0}%'
        'dash.alert.ram'          = 'RAM à {0}%'
        'dash.alert.disk'         = 'Disque {0} à {1}% plein'
        'dash.alert.uptime'       = 'Uptime élevé ({0} j) — redémarre'
        'dash.alert.battery'      = 'Batterie faible ({0}%)'
        'dash.alert.pendingReboot'= 'Redémarrage Windows Update en attente'
        'sidebar.header'          = 'SYSTÈME'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Utilisateur'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM totale'
        'sidebar.uptime'          = 'Allumé depuis'
        'sidebar.ip'              = 'IP locale'
        'sidebar.lastSync'        = 'Dernière actu'
        'sidebar.uptimeFmt'       = '{0}j {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} Go libres)'
    }
    'de' = @{
        'app.tagline'             = 'Einheitliches Windows-Supportpanel'
        'search.placeholder'      = 'Werkzeug suchen...'
        'category.all'            = 'Alle'
        'category.diagnostico'    = 'Diagnose'
        'category.mantenimiento'  = 'Wartung'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Netzwerk'
        'category.seguridad'      = 'Sicherheit'
        'category.software'       = 'Software'
        'category.entrega'        = 'Übergabe'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Benutzer'
        'header.logs'             = '📋 Logs'
        'header.about'            = 'ℹ️ Über'
        'button.run'              = '▶  Ausführen'
        'badge.requiresAdmin'     = '🛡  Admin nötig'
        'status.ready'            = 'Bereit'
        'status.launching'        = 'Starte: {0}...'
        'status.lastRun'          = 'Bereit — zuletzt: {0}'
        'status.toolsShown'       = '{0} Werkzeug(e) angezeigt'
        'logs.empty'              = 'Noch keine Logs. Führe zuerst ein Werkzeug aus.'
        'about.title'             = 'Über'
        'about.description'       = 'Panel inspiriert von WinUtil (Chris Titus Tech).{NEWLINE}Lizenz: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Drücke Enter, um dieses Fenster zu schließen...'
        'tool.error'              = '[!] Fehler in {0}: {1}'
        'tool.notLoaded'          = "Funktion '{0}' konnte nicht serialisiert werden. Ist sie geladen?"
        'footer.coffee'           = 'Spendiere mir einen Kaffee'
        'footer.coffeeTooltip'    = 'Unterstütze das Projekt mit einer PayPal-Spende'
        'header.language'         = 'Sprache'
        'header.languageTooltip'  = 'Panel-Sprache ändern'
        'header.restartTooltip'   = 'Panel neu starten (Sprache anwenden)'
        'language.restartRequired'= 'Starte das Panel neu, um die neue Sprache anzuwenden.'
        'restart.instructions'    = "Das Panel wird jetzt geschlossen.{NEWLINE}{NEWLINE}Zum erneuten Öffnen ausführen:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Datenträger'
        'dash.alerts'             = 'Warnungen'
        'dash.alerts.none'        = 'Keine Warnungen — System OK.'
        'dash.refreshTooltip'     = 'Dashboard jetzt aktualisieren'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Live-Ressourcenmonitor ein-/ausschalten'
        'dash.monitor.paused'     = 'Ressourcenmonitor ist aus — Monitor OFF zum Aktivieren klicken.'
        'dash.alert.cpu'          = 'CPU bei {0}%'
        'dash.alert.ram'          = 'RAM bei {0}%'
        'dash.alert.disk'         = 'Datenträger {0} zu {1}% voll'
        'dash.alert.uptime'       = 'Lange Laufzeit ({0} T) — neu starten'
        'dash.alert.battery'      = 'Akku niedrig ({0}%)'
        'dash.alert.pendingReboot'= 'Windows-Update-Neustart ausstehend'
        'sidebar.header'          = 'SYSTEM'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Benutzer'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM gesamt'
        'sidebar.uptime'          = 'An seit'
        'sidebar.ip'              = 'Lokale IP'
        'sidebar.lastSync'        = 'Letzte Aktualisierung'
        'sidebar.uptimeFmt'       = '{0}T {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB frei)'
    }
    'it' = @{
        'app.tagline'             = 'Pannello unificato di supporto tecnico per Windows'
        'search.placeholder'      = 'Cerca strumento...'
        'category.all'            = 'Tutto'
        'category.diagnostico'    = 'Diagnostica'
        'category.mantenimiento'  = 'Manutenzione'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Rete'
        'category.seguridad'      = 'Sicurezza'
        'category.software'       = 'Software'
        'category.entrega'        = 'Consegna'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utente'
        'header.logs'             = '📋 Log'
        'header.about'            = 'ℹ️ Info'
        'button.run'              = '▶  Esegui'
        'badge.requiresAdmin'     = '🛡  richiede admin'
        'status.ready'            = 'Pronto'
        'status.launching'        = 'Avvio: {0}...'
        'status.lastRun'          = 'Pronto — ultimo: {0}'
        'status.toolsShown'       = '{0} strumento/i mostrato/i'
        'logs.empty'              = 'Ancora nessun log. Esegui prima uno strumento.'
        'about.title'             = 'Info'
        'about.description'       = 'Pannello ispirato a WinUtil (Chris Titus Tech).{NEWLINE}Licenza: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Premi Invio per chiudere questa finestra...'
        'tool.error'              = '[!] Errore in {0}: {1}'
        'tool.notLoaded'          = "Impossibile serializzare la funzione '{0}'. È caricata?"
        'footer.coffee'           = 'Offrimi un caffè'
        'footer.coffeeTooltip'    = 'Sostieni il progetto con una donazione PayPal'
        'header.language'         = 'Lingua'
        'header.languageTooltip'  = 'Cambia lingua del pannello'
        'header.restartTooltip'   = 'Riavviare il pannello (applicare il cambio lingua)'
        'language.restartRequired'= 'Riavvia il pannello per applicare la nuova lingua.'
        'restart.instructions'    = "Il pannello si chiuderà ora.{NEWLINE}{NEWLINE}Per riaprirlo, esegui:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disco'
        'dash.alerts'             = 'Avvisi'
        'dash.alerts.none'        = 'Nessun avviso — sistema OK.'
        'dash.refreshTooltip'     = 'Aggiorna dashboard ora'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Attiva/disattiva monitor risorse live'
        'dash.monitor.paused'     = 'Monitor risorse spento — clicca Monitor OFF per attivarlo.'
        'dash.alert.cpu'          = 'CPU al {0}%'
        'dash.alert.ram'          = 'RAM al {0}%'
        'dash.alert.disk'         = 'Disco {0} al {1}% pieno'
        'dash.alert.uptime'       = 'Uptime alto ({0} g) — riavvia'
        'dash.alert.battery'      = 'Batteria scarica ({0}%)'
        'dash.alert.pendingReboot'= 'Riavvio Windows Update in sospeso'
        'sidebar.header'          = 'SISTEMA'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Utente'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM totale'
        'sidebar.uptime'          = 'Acceso da'
        'sidebar.ip'              = 'IP locale'
        'sidebar.lastSync'        = 'Ultimo aggiornamento'
        'sidebar.uptimeFmt'       = '{0}g {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB liberi)'
    }
}

$script:AtlasCurrentLang = 'en'

# Nombres nativos de los idiomas para mostrar en el selector.
$script:AtlasLanguageNames = [ordered]@{
    'es' = 'Español'
    'en' = 'English'
    'pt' = 'Português'
    'fr' = 'Français'
    'de' = 'Deutsch'
    'it' = 'Italiano'
    'ro' = 'Română'
}

function Get-AtlasSystemLanguage {
    try {
        $culture = [System.Globalization.CultureInfo]::CurrentUICulture
        $two = $culture.TwoLetterISOLanguageName.ToLower()
        if ($script:AtlasStringsDict.ContainsKey($two)) {
            return $two
        }
    } catch {}
    return 'en'
}

function Set-AtlasLanguage {
    [CmdletBinding()]
    param(
        [string]$Language = 'auto'
    )
    if ($Language -eq 'auto' -or -not $Language) {
        $Language = Get-AtlasSystemLanguage
    }
    $Language = $Language.ToLower()
    if (-not $script:AtlasStringsDict.ContainsKey($Language)) {
        Write-Warning "Language '$Language' not supported. Using 'en'."
        $Language = 'en'
    }
    $script:AtlasCurrentLang = $Language
    return $Language
}

function Get-AtlasString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)] [string]$Key,
        [Parameter(Position=1, ValueFromRemainingArguments=$true)] [object[]]$Args
    )
    $dict = $script:AtlasStringsDict[$script:AtlasCurrentLang]
    if (-not $dict.ContainsKey($Key)) {
        # fallback to English
        $dict = $script:AtlasStringsDict['en']
    }
    $value = $dict[$Key]
    if (-not $value) { return $Key }
    if ($Args -and $Args.Count -gt 0) {
        $value = [string]::Format($value, $Args)
    }
    $value = $value -replace '\{NEWLINE\}', [Environment]::NewLine
    return $value
}

function Get-AtlasSupportedLanguages {
    # Si hay AtlasLanguageNames (ordenado), usarlo para orden estable en dropdowns.
    if ($script:AtlasLanguageNames) {
        return @($script:AtlasLanguageNames.Keys | Where-Object { $script:AtlasStringsDict.ContainsKey($_) })
    }
    return @($script:AtlasStringsDict.Keys)
}

function Get-AtlasLanguageName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Code)
    if ($script:AtlasLanguageNames -and $script:AtlasLanguageNames.Contains($Code)) {
        return $script:AtlasLanguageNames[$Code]
    }
    return $Code.ToUpper()
}

# ----- Persistencia de preferencia de idioma -----
function _Get-AtlasConfigPath {
    $dir = Join-Path $env:LOCALAPPDATA 'AtlasPC'
    if (-not (Test-Path -LiteralPath $dir)) {
        try { New-Item -ItemType Directory -Path $dir -Force | Out-Null } catch {}
    }
    return (Join-Path $dir 'config.json')
}

function Get-AtlasLanguagePref {
    try {
        $cfgPath = _Get-AtlasConfigPath
        if (Test-Path -LiteralPath $cfgPath) {
            $obj = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($obj.language -and $script:AtlasStringsDict.ContainsKey([string]$obj.language)) {
                return [string]$obj.language
            }
        }
    } catch {}
    return $null
}

function Set-AtlasLanguagePref {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Language)
    try {
        $cfgPath = _Get-AtlasConfigPath
        $obj = [ordered]@{}
        if (Test-Path -LiteralPath $cfgPath) {
            try {
                $existing = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($existing) {
                    foreach ($p in $existing.PSObject.Properties) { $obj[$p.Name] = $p.Value }
                }
            } catch {}
        }
        $obj['language'] = $Language
        $json = $obj | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $cfgPath -Value $json -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}


# ---- lib\Admin.ps1 ----
# ============================================================
# Atlas PC Support - Auto-elevation
# Sustituye a los .bat de cada tool.
# ============================================================

function Test-IsAdmin {
    [CmdletBinding()]
    param()
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SelfElevate {
    [CmdletBinding()]
    param(
        [string]$ScriptPath = $PSCommandPath
    )
    if (Test-IsAdmin) { return $true }

    if (-not $ScriptPath) {
        Write-Warning "No se puede auto-elevar: no hay ruta de script."
        return $false
    }

    try {
        Unblock-File -LiteralPath $ScriptPath -ErrorAction SilentlyContinue
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "RemoteSigned", "-File", "`"$ScriptPath`"") `
            -Verb RunAs | Out-Null
        exit 0
    } catch {
        Write-Warning "No se pudo elevar: $_"
        return $false
    }
}

function Invoke-AsAdmin {
    <#
    .SYNOPSIS
    Ejecuta un bloque de código en una nueva ventana de PowerShell elevada.
    .PARAMETER ScriptBlock
    Bloque de código a ejecutar.
    .PARAMETER Title
    Título de la ventana.
    .PARAMETER Wait
    Esperar a que termine antes de volver.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock,
        [string]$Title = "Atlas PC Support",
        [switch]$Wait
    )

    # Write the block to a per-user secure directory and run with -File instead
    # of -EncodedCommand. -EncodedCommand triggers AV heuristics on many endpoints.
    $secureRunDir = Initialize-AtlasSecureDirectory -Path '%LOCALAPPDATA%\AtlasPC\secure-run'
    if (-not $secureRunDir) {
        $secureRunDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\secure-run'
        if (-not (Test-Path -LiteralPath $secureRunDir)) {
            New-Item -ItemType Directory -Path $secureRunDir -Force | Out-Null
        }
    }
    $tmp = Join-Path $secureRunDir ("atlas-admin-" + [guid]::NewGuid().ToString('N').Substring(0,8) + ".ps1")
    try {
        $payload = @(
            '$ErrorActionPreference = ''Continue'''
            $ScriptBlock.ToString()
            'try { Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue } catch {}'
        ) -join [Environment]::NewLine
        [System.IO.File]::WriteAllText($tmp, $payload, [System.Text.UTF8Encoding]::new($true))
    } catch {
        Write-Warning "No se pudo escribir script temporal: $_"
        return $false
    }

    $psArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "RemoteSigned",
        "-File", $tmp
    )

    $startArgs = @{
        FilePath     = "powershell.exe"
        ArgumentList = $psArgs
        Verb         = "RunAs"
    }
    if ($Wait) { $startArgs.Wait = $true }

    try {
        Start-Process @startArgs | Out-Null
        # Cleanup is best-effort; the elevated process may still be running if -Wait was not set.
        if ($Wait) { Remove-Item $tmp -ErrorAction SilentlyContinue }
        return $true
    } catch {
        Remove-Item $tmp -ErrorAction SilentlyContinue
        Write-Warning "No se pudo lanzar ventana elevada: $_"
        return $false
    }
}


# ---- lib\Logging.ps1 ----
# ============================================================
# Atlas PC Support - Central logging
# ============================================================

$script:AtlasLogFile = $null

function Initialize-AtlasLog {
    [CmdletBinding()]
    param(
        [string]$LogPath = (Expand-AtlasPath "%LOCALAPPDATA%\AtlasPC\logs")
    )

    $resolvedLogPath = Initialize-AtlasSecureDirectory -Path $LogPath
    if (-not $resolvedLogPath) {
        $resolvedLogPath = Expand-AtlasPath $LogPath
        if (-not (Test-Path -LiteralPath $resolvedLogPath)) {
            New-Item -ItemType Directory -Path $resolvedLogPath -Force | Out-Null
        }
    }

    $date = Get-Date -Format "yyyy-MM-dd"
    $script:AtlasLogFile = Join-Path $resolvedLogPath "atlas-$date.log"

    $header = @"

================================================================
 Atlas PC Support — sesión iniciada $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
 Equipo : $env:COMPUTERNAME
 Usuario: $env:USERNAME
================================================================
"@
    Add-Content -Path $script:AtlasLogFile -Value $header -Encoding UTF8
    [void](Set-AtlasPathAcl -Path $script:AtlasLogFile)
    return $script:AtlasLogFile
}

function Write-AtlasLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)] [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','DEBUG')] [string]$Level = 'INFO',
        [string]$Tool = ''
    )
    if (-not $script:AtlasLogFile) { Initialize-AtlasLog | Out-Null }
    $ts   = Get-Date -Format "HH:mm:ss"
    $tool = if ($Tool) { "[$Tool] " } else { "" }
    $line = "[$ts] [$Level] $tool$Message"
    try {
        Add-Content -Path $script:AtlasLogFile -Value $line -Encoding UTF8
    } catch {
        # no op — logging nunca debe romper la tool
    }
}

function Get-AtlasLogPath {
    if (-not $script:AtlasLogFile) { Initialize-AtlasLog | Out-Null }
    return $script:AtlasLogFile
}


# ---- lib\ToolKit.ps1 ----
# ============================================================
# Atlas PC Support - Tool toolkit (helpers compartidos para TOOLS)
#
# A diferencia del resto de lib/, este archivo esta pensado para estar
# disponible DENTRO de cada tool, que corre aislada en su propia ventana.
# El ToolRunner inyecta el contenido de este archivo (embebido en el launcher
# y por tanto cubierto por launcher.ps1.sha256) al principio del wrapper
# temporal de cada tool. Asi se deduplican los banners, el calculo de carpeta
# de reportes y el armado de HTML que hoy cada tool reimplementa.
#
# REGLAS para este archivo:
#   - Debe ser 100% autonomo (no depende de otras funciones de lib/).
#   - Nunca debe lanzar al cargarse (solo define funciones).
#   - Cambios aqui afectan a TODAS las tools: mantener minimo y robusto.
# ============================================================

function Write-AtlasHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)] [string]$Title,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )
    $line = '=' * ([Math]::Min(60, [Math]::Max(12, $Title.Length + 6)))
    Write-Host ''
    Write-Host $line -ForegroundColor $Color
    Write-Host ("  {0}" -f $Title) -ForegroundColor $Color
    Write-Host $line -ForegroundColor $Color
}

function Write-AtlasStep {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [>] {0}" -f $Message) -ForegroundColor Cyan
}

function Write-AtlasSuccess {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [OK] {0}" -f $Message) -ForegroundColor Green
}

function Write-AtlasWarn {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [!] {0}" -f $Message) -ForegroundColor Yellow
}

function Write-AtlasFailure {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)] [string]$Message)
    Write-Host ("  [X] {0}" -f $Message) -ForegroundColor Red
}

function Wait-AtlasExit {
    [CmdletBinding()]
    param([string]$Message = 'Presiona ENTER para cerrar')
    Write-Host ''
    [void](Read-Host $Message)
}

function Get-AtlasReportDir {
    [CmdletBinding()]
    [OutputType([string])]
    param([string]$SubFolder)
    $base = Join-Path $env:USERPROFILE 'Documents\AtlasPC\reports'
    $dir  = if ($SubFolder) { Join-Path $base $SubFolder } else { $base }
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function Get-AtlasReportPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$Prefix,
        [string]$Extension = 'html',
        [string]$SubFolder
    )
    $dir   = Get-AtlasReportDir -SubFolder $SubFolder
    $stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $ext   = $Extension.TrimStart('.')
    return (Join-Path $dir ("{0}_{1}.{2}" -f $Prefix, $stamp, $ext))
}

function ConvertTo-AtlasHtmlEncoded {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][string]$Text)
    process {
        if ($null -eq $Text) { return '' }
        return [System.Net.WebUtility]::HtmlEncode($Text)
    }
}

function ConvertTo-AtlasHtmlDocument {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$BodyHtml,
        [string]$AccentColor = '#0078D4',
        [string]$Subtitle
    )
    $safeTitle    = ConvertTo-AtlasHtmlEncoded $Title
    $safeSubtitle = if ($Subtitle) { ConvertTo-AtlasHtmlEncoded $Subtitle } else { '' }
    $generated    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $subtitleHtml = if ($safeSubtitle) { "<p class='subtitle'>$safeSubtitle</p>" } else { '' }
    return @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
  :root { --accent: $AccentColor; }
  * { box-sizing: border-box; }
  body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 0; color: #1b1b1b; background: #f3f3f3; }
  header { background: var(--accent); color: #fff; padding: 24px 32px; }
  header h1 { margin: 0; font-size: 22px; }
  header .subtitle { margin: 6px 0 0; opacity: .9; font-size: 14px; }
  main { padding: 24px 32px; max-width: 1100px; margin: 0 auto; }
  section { background: #fff; border: 1px solid #e1e1e1; border-radius: 8px; padding: 16px 20px; margin-bottom: 16px; }
  h2 { font-size: 16px; border-bottom: 2px solid var(--accent); padding-bottom: 6px; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #eee; }
  th { background: #fafafa; }
  footer { text-align: center; color: #888; font-size: 12px; padding: 16px; }
  .ok { color: #107c10; } .warn { color: #c19c00; } .err { color: #d13438; }
</style>
</head>
<body>
<header>
  <h1>$safeTitle</h1>
  $subtitleHtml
</header>
<main>
$BodyHtml
</main>
<footer>Atlas PC Support &middot; generado $generated</footer>
</body>
</html>
"@
}


# ---- lib\Dependencies.ps1 ----
# ============================================================
# Atlas PC Support - Dependency manager
# Resuelve y descarga dependencias externas (FastCopy, etc.)
# a %LOCALAPPDATA%\AtlasPC\bin\ bajo demanda.
# ============================================================

$script:AtlasDepsRegistry = @{
    'FastCopy' = @{
        DisplayName    = 'FastCopy'
        ExecutableName = 'FastCopy.exe'
        WingetId       = 'FastCopy.FastCopy'
        DownloadUrl    = 'https://fastcopy.jp/archive/FastCopy5.11.2_installer.exe'
        DownloadSha256 = '70b273dd08c15d40fac59a217b93be195bacfa47acabd031463a6df800d29fea'
        SearchPaths    = @(
            'C:\Program Files\FastCopy\FastCopy.exe',
            'C:\Program Files (x86)\FastCopy\FastCopy.exe',
            '%LOCALAPPDATA%\FastCopy\FastCopy.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\FastCopy\FastCopy.exe'
        )
    }
    'winget' = @{
        DisplayName    = 'Windows Package Manager'
        ExecutableName = 'winget.exe'
        SearchPaths    = @(
            '%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe'
        )
    }
    'GPUZ' = @{
        DisplayName    = 'TechPowerUp GPU-Z'
        ExecutableName = 'GPU-Z.exe'
        WingetId       = 'TechPowerUp.GPU-Z'
        SearchPaths    = @(
            'C:\Program Files (x86)\GPU-Z\GPU-Z.exe',
            'C:\Program Files\GPU-Z\GPU-Z.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\GPU-Z.exe'
        )
    }
    'FurMark2' = @{
        DisplayName    = 'Geeks3D FurMark 2'
        ExecutableName = 'furmark.exe'
        WingetId       = 'Geeks3D.FurMark.2'
        SearchPaths    = @(
            'C:\Program Files\Geeks3D\FurMark2_x64\furmark.exe',
            'C:\Program Files (x86)\Geeks3D\FurMark2_x64\furmark.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\FurMark2_x64\furmark.exe'
        )
    }
    'HWiNFO' = @{
        DisplayName    = 'HWiNFO64'
        ExecutableName = 'HWiNFO64.exe'
        WingetId       = 'REALiX.HWiNFO'
        SearchPaths    = @(
            'C:\Program Files\HWiNFO64\HWiNFO64.exe',
            'C:\Program Files (x86)\HWiNFO64\HWiNFO64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\GPUCheck\tools\HWiNFO64.exe'
        )
    }
    'CPUZ' = @{
        DisplayName    = 'CPUID CPU-Z'
        ExecutableName = 'cpuz.exe'
        WingetId       = 'CPUID.CPU-Z'
        SearchPaths    = @(
            'C:\Program Files\CPUID\CPU-Z\cpuz_x64.exe',
            'C:\Program Files\CPUID\CPU-Z\cpuz_x32.exe',
            'C:\Program Files\CPUID\CPU-Z\cpuz.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x64.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz_x32.exe',
            'C:\Program Files (x86)\CPUID\CPU-Z\cpuz.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\cpuz.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\cpuz_x64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\cpuz_x32.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\cpuz.exe'
        )
    }
    'BlueScreenView' = @{
        DisplayName    = 'NirSoft BlueScreenView'
        ExecutableName = 'BlueScreenView.exe'
        WingetId       = 'NirSoft.BlueScreenView'
        SearchPaths    = @(
            'C:\Program Files\NirSoft\BlueScreenView\BlueScreenView.exe',
            'C:\Program Files (x86)\NirSoft\BlueScreenView\BlueScreenView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\bluescreenview.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\BlueScreenView.exe'
        )
    }
    'BatteryInfoView' = @{
        DisplayName    = 'NirSoft BatteryInfoView'
        ExecutableName = 'BatteryInfoView.exe'
        WingetId       = 'NirSoft.BatteryInfoView'
        SearchPaths    = @(
            'C:\Program Files\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            'C:\Program Files (x86)\NirSoft\BatteryInfoView\BatteryInfoView.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\batteryinfoview.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\BatteryInfoView.exe'
        )
    }
    'CrystalDiskInfo' = @{
        DisplayName    = 'CrystalDiskInfo'
        ExecutableName = 'DiskInfo64.exe'
        WingetId       = 'CrystalDewWorld.CrystalDiskInfo'
        SearchPaths    = @(
            'C:\Program Files\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo64.exe',
            'C:\Program Files\CrystalDiskInfo\DiskInfo32.exe',
            'C:\Program Files (x86)\CrystalDiskInfo\DiskInfo32.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskinfo.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\CrystalDiskInfo\DiskInfo64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\CrystalDiskInfo\DiskInfo32.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\DiskInfo64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\DiskInfo32.exe'
        )
    }
    'CrystalDiskMark' = @{
        DisplayName    = 'CrystalDiskMark'
        ExecutableName = 'DiskMark64.exe'
        WingetId       = 'CrystalDewWorld.CrystalDiskMark'
        SearchPaths    = @(
            'C:\Program Files\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files\CrystalDiskMark\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark8\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark9\DiskMark64.exe',
            'C:\Program Files (x86)\CrystalDiskMark\DiskMark64.exe',
            '%LOCALAPPDATA%\Microsoft\WinGet\Links\diskmark.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\CrystalDiskMark\DiskMark64.exe',
            '%LOCALAPPDATA%\AtlasPC\bin\DiagnosticoMaster\tools\DiskMark64.exe'
        )
    }
}

function Resolve-SymlinkPath {
    param([string]$Path)
    if (-not $Path) { return $Path }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($item.Attributes -match "ReparsePoint") {
            if ($item.LinkTarget) { return $item.LinkTarget }
            elseif ($item.Target) {
                if ($item.Target -is [array]) { return $item.Target[0] }
                return [string]$item.Target
            }
        }
    } catch {}
    return $Path
}

function Test-AtlasDependencyHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedSha256
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if (-not $ExpectedSha256) { return $true }

    $expected = $ExpectedSha256.ToLowerInvariant()
    if ($expected -notmatch '^[a-f0-9]{64}$') {
        Write-AtlasLog "Hash esperado invalido para dependencia: $ExpectedSha256" -Level WARN -Tool 'Deps'
        return $false
    }

    try {
        $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
        return ($actual -eq $expected)
    } catch {
        Write-AtlasLog "No se pudo calcular SHA256 para '$Path': $_" -Level WARN -Tool 'Deps'
        return $false
    }
}

function Resolve-AtlasDependency {
    <#
    .SYNOPSIS
    Busca una dependencia en el sistema; si no la encuentra,
    intenta instalarla con winget o descargarla.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Name,
        [switch]$InstallIfMissing
    )

    if (-not $script:AtlasDepsRegistry.ContainsKey($Name)) {
        Write-AtlasLog "Dependencia desconocida: $Name" -Level ERROR -Tool 'Deps'
        return $null
    }
    $dep = $script:AtlasDepsRegistry[$Name]

    foreach ($p in $dep.SearchPaths) {
        $expanded = Expand-AtlasPath $p
        if (Test-Path $expanded) {
            # Ensure CrystalDiskInfo and CrystalDiskMark have their resource folders
            if ($Name -eq 'CrystalDiskInfo') {
                $parent = Split-Path -Parent $expanded
                if (-not (Test-Path -LiteralPath (Join-Path $parent 'CdiResource'))) {
                    Write-AtlasLog "Ignorando $Name en $expanded porque falta CdiResource" -Level WARN -Tool 'Deps'
                    continue
                }
            }
            if ($Name -eq 'CrystalDiskMark') {
                $parent = Split-Path -Parent $expanded
                if (-not (Test-Path -LiteralPath (Join-Path $parent 'CdmResource'))) {
                    Write-AtlasLog "Ignorando $Name en $expanded porque falta CdmResource" -Level WARN -Tool 'Deps'
                    continue
                }
            }
            Write-AtlasLog "Encontrada $Name en $expanded" -Tool 'Deps'
            return Resolve-SymlinkPath $expanded
        }
    }
    $inPath = Get-Command $dep.ExecutableName -ErrorAction SilentlyContinue
    if ($inPath) { return Resolve-SymlinkPath $inPath.Source }

    if (-not $InstallIfMissing) {
        Write-AtlasLog "$Name no encontrada (no se pidió instalar)." -Level WARN -Tool 'Deps'
        return $null
    }

    if ($dep.WingetId -and (Get-Command 'winget' -ErrorAction SilentlyContinue)) {
        Write-AtlasLog "Instalando $Name vía winget ($($dep.WingetId))" -Tool 'Deps'
        try {
            winget install --id $dep.WingetId --exact --accept-source-agreements --accept-package-agreements --silent | Out-Null
        } catch {
            Write-AtlasLog "winget falló: $_" -Level WARN -Tool 'Deps'
        }
        foreach ($p in $dep.SearchPaths) {
            $expanded = Expand-AtlasPath $p
            if (Test-Path $expanded) { return Resolve-SymlinkPath $expanded }
        }
    }

    # Fallback: direct download via DownloadUrl when winget is unavailable or failed
    if ($dep.DownloadUrl) {
        Write-AtlasLog "Intentando descarga directa de $Name ($($dep.DownloadUrl))" -Tool 'Deps'
        $cacheDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\bin'
        if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
        $installerFile = Join-Path $cacheDir ("$Name-installer-" + [guid]::NewGuid().ToString('N').Substring(0,8) + '.exe')
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $dep.DownloadUrl -OutFile $installerFile -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            if ((Get-Item $installerFile).Length -gt 100KB) {
                if ($dep.DownloadSha256) {
                    if (-not (Test-AtlasDependencyHash -Path $installerFile -ExpectedSha256 $dep.DownloadSha256)) {
                        throw "Hash SHA-256 invalido para el instalador de $Name."
                    }
                }
                $targetDir = Join-Path $env:LOCALAPPDATA "AtlasPC\bin\$Name"
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                $p = Start-Process -FilePath $installerFile -ArgumentList @('/EXTRACT64', '/NOSUBDIR', '/AGREE_LICENSE', "/DIR=`"$targetDir`"") -Wait -PassThru -ErrorAction SilentlyContinue
                if (-not ($p -and $p.ExitCode -eq 0)) {
                    Start-Process -FilePath $installerFile -ArgumentList @('/SILENT', '/AGREE_LICENSE', "/DIR=`"$targetDir`"") -Wait -ErrorAction SilentlyContinue
                }
                Remove-Item $installerFile -ErrorAction SilentlyContinue
                foreach ($sp in $dep.SearchPaths) {
                    $expanded = Expand-AtlasPath $sp
                    if (Test-Path $expanded) { return Resolve-SymlinkPath $expanded }
                }
                $found = Get-ChildItem -Path $targetDir -Filter $dep.ExecutableName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) { return Resolve-SymlinkPath $found.FullName }
            }
        } catch {
            Write-AtlasLog "Descarga directa falló: $_" -Level WARN -Tool 'Deps'
            Remove-Item $installerFile -ErrorAction SilentlyContinue
        }
    }

    Write-AtlasLog "No se pudo resolver $Name. Revisa la ruta manualmente." -Level ERROR -Tool 'Deps'
    return $null
}

function Register-AtlasDependency {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [hashtable]$Definition
    )
    $script:AtlasDepsRegistry[$Name] = $Definition
}


# ---- lib\PS7.ps1 ----
# ============================================================
# Atlas PC Support - PowerShell 7 detection & install
#
# Proposito:
#   El panel soporta PS 5.1 (Windows de fabrica), pero las tools
#   sufren bugs de encoding, enums y parametros limitados de 5.1.
#   Cuando PS 7 esta presente, ToolRunner lo usa automaticamente
#   y todas las tools corren en el runtime moderno.
#
# Modo offline (USB):
#   Install-AtlasPS7 -OfflineSource "$PSScriptRoot\deps\PowerShell-*.msi"
#   Preparar USB copia el MSI en deps\ para instalacion sin internet.
# ============================================================

# Versiones conocidas de PS 7 (actualizar cuando salga nueva LTS).
$script:AtlasPS7Version  = '7.5.0'
$script:AtlasPS7UrlX64   = "https://github.com/PowerShell/PowerShell/releases/download/v$($script:AtlasPS7Version)/PowerShell-$($script:AtlasPS7Version)-win-x64.msi"
$script:AtlasPS7MsiName  = "PowerShell-$($script:AtlasPS7Version)-win-x64.msi"
$script:AtlasPS7HashesUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$($script:AtlasPS7Version)/hashes.sha256"

function Get-AtlasPS7Path {
    <#
    .SYNOPSIS
      Devuelve la ruta completa a pwsh.exe si PS 7+ esta instalado, si no $null.
    #>
    [CmdletBinding()]
    param()

    # 1) PATH
    $cmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Path) { return $cmd.Path }

    # 2) Ruta por defecto de instalacion MSI (64-bit y 32-bit)
    $candidates = @(
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
        "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
    }

    return $null
}

function Find-AtlasPS7OfflineMsi {
    <#
    .SYNOPSIS
      Busca un MSI de PS 7 en carpetas locales conocidas (USB offline).
    #>
    [CmdletBinding()]
    param()

    $searchDirs = @()
    # USB offline root set by run-launcher.ps1 (highest priority — covers USB scenario)
    if ($env:ATLAS_OFFLINE_ROOT) {
        $searchDirs += (Join-Path $env:ATLAS_OFFLINE_ROOT 'deps')
    }
    # USB: si el launcher.ps1 esta en E:\ATLAS_PC_SUPPORT\, mirar deps\
    if ($script:AtlasRoot) {
        $searchDirs += (Join-Path $script:AtlasRoot 'deps')
    }
    # LOCALAPPDATA cache (Preparar USB guarda tambien alli)
    $searchDirs += (Join-Path $env:LOCALAPPDATA 'AtlasPC\deps')

    foreach ($dir in $searchDirs) {
        if (Test-Path -LiteralPath $dir) {
            $msi = Get-ChildItem -Path $dir -Filter 'PowerShell-*-win-x64.msi' -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending | Select-Object -First 1
            if ($msi) { return $msi.FullName }
        }
    }
    return $null
}

function Get-AtlasPS7ExpectedHash {
    <#
    .SYNOPSIS
      Descarga el archivo oficial hashes.sha256 y extrae el hash del MSI x64.
    #>
    [CmdletBinding()]
    param()

    try {
        $ProgressPreference = 'SilentlyContinue'
        $raw = (Invoke-WebRequest -Uri $script:AtlasPS7HashesUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop).Content
    } catch {
        throw "No se pudo descargar hashes.sha256 oficial: $($_.Exception.Message)"
    }

    $line = ($raw -split "`r?`n" | Where-Object { $_ -match [regex]::Escape($script:AtlasPS7MsiName) } | Select-Object -First 1)
    if (-not $line) {
        throw "No se encontro hash para $($script:AtlasPS7MsiName) en hashes.sha256."
    }

    $hash = (($line -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
    if ($hash -notmatch '^[a-f0-9]{64}$') {
        throw "Formato de hash invalido en hashes.sha256."
    }
    return $hash
}

function Test-AtlasFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedHash
    )

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    return ($actual -eq $ExpectedHash.ToLowerInvariant())
}

function Install-AtlasPS7 {
    <#
    .SYNOPSIS
      Instala PowerShell 7 usando msiexec silencioso.
      Intenta primero MSI local (offline), si no descarga de GitHub.

    .PARAMETER OfflineSource
      Ruta a un MSI ya descargado. Si se omite, se busca automaticamente
      y si no se encuentra se descarga.
    #>
    [CmdletBinding()]
    param(
        [string]$OfflineSource
    )

    $msi = $null
    $expectedHash = $null
    $downloadedFromWeb = $false

    if ($OfflineSource -and (Test-Path -LiteralPath $OfflineSource)) {
        $msi = (Resolve-Path -LiteralPath $OfflineSource).Path
        Write-Host "  [>] Usando MSI local: $msi" -ForegroundColor Cyan
    } else {
        $found = Find-AtlasPS7OfflineMsi
        if ($found) {
            $msi = $found
            Write-Host "  [>] MSI local encontrado: $msi" -ForegroundColor Cyan
        }
    }

    if (-not $msi) {
        # Descargar
        $cacheDir = Join-Path $env:LOCALAPPDATA 'AtlasPC\deps'
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        $msi = Join-Path $cacheDir $script:AtlasPS7MsiName
        Write-Host "  [>] Descargando PowerShell $($script:AtlasPS7Version) (~120 MB)..." -ForegroundColor Cyan
        try {
            $expectedHash = Get-AtlasPS7ExpectedHash
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $script:AtlasPS7UrlX64 -OutFile $msi -UseBasicParsing
            $downloadedFromWeb = $true
        } catch {
            throw "Fallo descarga de PS 7: $($_.Exception.Message)"
        }
    }

    # Validar integridad del MSI.
    if (-not $expectedHash) {
        $sidecar = "$msi.sha256"
        if (Test-Path -LiteralPath $sidecar) {
            try {
                $raw = Get-Content -LiteralPath $sidecar -Raw -Encoding UTF8 -ErrorAction Stop
                $parsed = (($raw -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
                if ($parsed -match '^[a-f0-9]{64}$') {
                    $expectedHash = $parsed
                }
            } catch {}
        }
    }

    if ($expectedHash) {
        Write-Host "  [>] Verificando integridad SHA-256 del MSI..." -ForegroundColor Cyan
        if (-not (Test-AtlasFileHash -Path $msi -ExpectedHash $expectedHash)) {
            if ($downloadedFromWeb) {
                Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
            }
            throw "La verificacion SHA-256 del MSI de PowerShell 7 fallo."
        }
        Write-Host "  [OK] Integridad verificada." -ForegroundColor Green
    } else {
        Write-Host "  [!] No se pudo validar hash del MSI (sin sidecar/local hash)." -ForegroundColor Yellow
    }

    # Instalar silencioso con feature completa
    $msiArgs = @(
        '/i', "`"$msi`"",
        '/qn', '/norestart',
        'ADD_PATH=1',
        'ENABLE_PSREMOTING=0',
        'REGISTER_MANIFEST=1'
    )
    Write-Host "  [>] Instalando MSI (msiexec silencioso)..." -ForegroundColor Cyan
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
        throw "msiexec salio con codigo $($p.ExitCode)"
    }

    $path = Get-AtlasPS7Path
    if (-not $path) {
        throw "Instalacion reportada OK pero pwsh.exe no se encuentra en las rutas esperadas."
    }
    Write-Host "  [OK] PowerShell 7 instalado: $path" -ForegroundColor Green
    return $path
}

# Cache de la ruta resuelta (lo rellena el launcher al arrancar).
$script:AtlasPS7CachedPath = $null

function Initialize-AtlasPS7 {
    <#
    .SYNOPSIS
      Llamado por el launcher al arrancar para cachear la ruta a pwsh.exe.
      ToolRunner lee $script:AtlasPS7CachedPath para decidir si usa pwsh o powershell.
    #>
    $script:AtlasPS7CachedPath = Get-AtlasPS7Path
    return $script:AtlasPS7CachedPath
}


# ---- lib\ToolRunner.ps1 ----
# ============================================================
# Atlas PC Support - Tool runner
# Ejecuta una herramienta en una nueva ventana de PowerShell.
#
# Orden de origen:
#   0. Source local (dev checkout): src\tools\ si existe junto al repo
#   1. USB offline: deps\tools\ junto al launcher
#   2. Cache local: %LOCALAPPDATA%\AtlasPC\tools\
#   3. Descarga remota: $script:AtlasToolsBaseUrl
#
# Seguridad:
#   - Valida SHA-256 de cada tool contra $script:AtlasToolHashes.
#   - Fail-closed para usb/cache/download cuando no hay hash esperado.
#   - Fail-open solo para local-src (modo desarrollo).
#   - Descargas se escriben primero a .download y luego se mueven atomicamente.
#   - Nunca usa EncodedCommand (reduce heuristicas AV).
#
# Estabilidad:
#   - Limpia wrappers temporales antiguos en %LOCALAPPDATA%\AtlasPC\secure-run.
#   - Cache con refresco por antiguedad para evitar "version congelada".
# ============================================================

if (-not $script:AtlasToolCacheMaxAgeHours) {
    $script:AtlasToolCacheMaxAgeHours = 6
}
if (-not $script:AtlasToolHashes) {
    $script:AtlasToolHashes = @{}
}

function Get-AtlasSecureRunDir {
    [CmdletBinding()]
    param()

    if ($script:AtlasSecureRunDir -and (Test-Path -LiteralPath $script:AtlasSecureRunDir)) {
        return $script:AtlasSecureRunDir
    }

    $dir = Initialize-AtlasSecureDirectory -Path '%LOCALAPPDATA%\AtlasPC\secure-run'
    if (-not $dir) {
        $dir = Expand-AtlasPath '%LOCALAPPDATA%\AtlasPC\secure-run'
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    $script:AtlasSecureRunDir = $dir
    return $script:AtlasSecureRunDir
}

function Unblock-AtlasFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    try {
        if (Test-Path -LiteralPath $Path) {
            Unblock-File -LiteralPath $Path -ErrorAction SilentlyContinue
        }
    } catch {}
}

function Get-AtlasSHA256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    try {
        # Tool scripts are text. Hash in canonical UTF-8 + LF form so checks are
        # stable across CRLF/LF differences between local checkout and GitHub raw.
        $text = Get-Content -Raw -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        $normalized = ($text -replace "`r`n", "`n") -replace "`r", "`n"
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($normalized)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $sha.ComputeHash($bytes)
            return ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
        } finally {
            $sha.Dispose()
        }
    } catch {
        Write-AtlasLog "No se pudo calcular SHA256 de '$Path': $_" -Level WARN -Tool 'Runner'
        return $null
    }
}

function Get-AtlasToolExpectedHash {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FileName)

    if (-not $script:AtlasToolHashes) { return $null }
    if ($script:AtlasToolHashes -is [hashtable]) {
        if ($script:AtlasToolHashes.ContainsKey($FileName)) {
            return [string]$script:AtlasToolHashes[$FileName]
        }
        return $null
    }

    try {
        $prop = $script:AtlasToolHashes.PSObject.Properties[$FileName]
        if ($prop) { return [string]$prop.Value }
    } catch {}

    return $null
}

function Get-AtlasToolHashesRemoteUrl {
    [CmdletBinding()]
    param()

    if (-not $script:AtlasToolsBaseUrl) { return $null }
    $base = [string]$script:AtlasToolsBaseUrl
    if ([string]::IsNullOrWhiteSpace($base)) { return $null }

    $normalized = $base.TrimEnd('/')
    if ($normalized -match '/src/tools$') {
        return ($normalized -replace '/src/tools$', '/config/tool-hashes.json')
    }
    return $null
}

function Get-AtlasToolHashesDigestUrl {
    [CmdletBinding()]
    param()

    if ($script:AtlasToolHashesDigestUrl) {
        $url = [string]$script:AtlasToolHashesDigestUrl
        if (-not [string]::IsNullOrWhiteSpace($url)) { return $url.Trim() }
    }
    return $null
}

function Get-AtlasExpectedDigestFromRemote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DigestUrl,
        [string]$Label = 'digest'
    )

    try {
        $ProgressPreference = 'SilentlyContinue'
        $raw = (Invoke-WebRequest -Uri ($DigestUrl + '?v=' + [guid]::NewGuid().ToString('N').Substring(0,8)) `
            -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop).Content
        $expected = (($raw -split '\s+') | Where-Object { $_ } | Select-Object -First 1).ToLowerInvariant()
        if ($expected -match '^[a-f0-9]{64}$') {
            return $expected
        }
        Write-AtlasLog "Digest remoto invalido para $Label en $DigestUrl" -Level WARN -Tool 'Runner'
        return $null
    } catch {
        Write-AtlasLog "No se pudo obtener digest remoto ($Label): $_" -Level WARN -Tool 'Runner'
        return $null
    }
}

function Refresh-AtlasToolHashesFromRemote {
    [CmdletBinding()]
    param([string]$FileName)

    $hashUrl = Get-AtlasToolHashesRemoteUrl
    if (-not $hashUrl) { return $false }

    $tmpPath = Join-Path (Get-AtlasSecureRunDir) ("atlas-tool-hashes-" + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri ($hashUrl + '?v=' + [guid]::NewGuid().ToString('N').Substring(0,8)) `
            -OutFile $tmpPath -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop

        $digestRequired = $false
        if ($null -ne $script:AtlasToolHashesDigestRequired) {
            $digestRequired = [bool]$script:AtlasToolHashesDigestRequired
        }
        $digestUrl = Get-AtlasToolHashesDigestUrl
        if ($digestUrl) {
            $expectedDigest = Get-AtlasExpectedDigestFromRemote -DigestUrl $digestUrl -Label 'tool-hashes.json'
            if (-not $expectedDigest) {
                if ($digestRequired) {
                    Write-AtlasLog "Digest remoto requerido para tool-hashes pero no disponible." -Level ERROR -Tool 'Runner'
                    return $false
                }
            } else {
                $actualDigest = (Get-FileHash -LiteralPath $tmpPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
                if ($actualDigest -ne $expectedDigest) {
                    Write-AtlasLog "tool-hashes.json rechazado por digest out-of-band. Esperado=$expectedDigest Actual=$actualDigest" -Level ERROR -Tool 'Runner'
                    return $false
                }
                Write-AtlasLog "Digest out-of-band validado para tool-hashes.json." -Level INFO -Tool 'Runner'
            }
        } elseif ($digestRequired) {
            Write-AtlasLog "Digest out-of-band requerido para tool-hashes pero no configurado." -Level ERROR -Tool 'Runner'
            return $false
        }

        $raw = Get-Content -Raw -LiteralPath $tmpPath -Encoding UTF8 -ErrorAction Stop
        $obj = ConvertFrom-AtlasJson $raw
        if (-not $obj -or -not $obj.files) {
            Write-AtlasLog "Refresh hashes: respuesta invalida desde $hashUrl" -Level WARN -Tool 'Runner'
            return $false
        }

        $map = @{}
        if ($obj.files -is [hashtable]) {
            $map = $obj.files
        } else {
            foreach ($p in $obj.files.PSObject.Properties) {
                $map[$p.Name] = [string]$p.Value
            }
        }
        if ($map.Count -le 0) {
            Write-AtlasLog "Refresh hashes: mapa vacio desde $hashUrl" -Level WARN -Tool 'Runner'
            return $false
        }

        $script:AtlasToolHashes = $map
        if ($FileName) {
            $newExpected = Get-AtlasToolExpectedHash -FileName $FileName
            if ($newExpected) {
                Write-AtlasLog "Hashes refrescados en caliente para '$FileName'." -Level INFO -Tool 'Runner'
                return $true
            }
            Write-AtlasLog "Hashes refrescados, pero '$FileName' no existe en el manifiesto remoto." -Level WARN -Tool 'Runner'
            return $false
        }
        Write-AtlasLog "Hashes refrescados en caliente ($($map.Count) entries)." -Level INFO -Tool 'Runner'
        return $true
    } catch {
        Write-AtlasLog "No se pudo refrescar tool-hashes remotos: $_" -Level WARN -Tool 'Runner'
        return $false
    } finally {
        Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
    }
}

function Test-AtlasToolFileIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$FileName,
        [string]$SourceLabel = 'unknown'
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }

    try {
        $fi = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($fi.Length -lt 128) {
            Write-AtlasLog "Archivo tool demasiado corto (sospechoso): $Path" -Level ERROR -Tool 'Runner'
            return $false
        }
    } catch {
        Write-AtlasLog "No se pudo inspeccionar archivo tool '$Path': $_" -Level ERROR -Tool 'Runner'
        return $false
    }

    $expected = Get-AtlasToolExpectedHash -FileName $FileName
    if (-not $expected) {
        if ($SourceLabel -eq 'local-src') {
            Write-AtlasLog "Sin hash esperado para '$FileName' en local-src; permitido solo para desarrollo." -Level WARN -Tool 'Runner'
            return $true
        }
        Write-AtlasLog "Sin hash esperado para '$FileName' (origen=$SourceLabel). Bloqueado por politica fail-closed." -Level ERROR -Tool 'Runner'
        return $false
    }

    $actual = Get-AtlasSHA256 -Path $Path
    if (-not $actual) { return $false }
    if ($actual -ne $expected.ToLowerInvariant()) {
        Write-AtlasLog "Hash invalido para '$FileName' (origen=$SourceLabel). Esperado=$expected Actual=$actual" -Level ERROR -Tool 'Runner'
        return $false
    }

    return $true
}

function Invoke-AtlasRunnerTempCleanup {
    [CmdletBinding()]
    param(
        [string]$TempDir,
        [int]$MaxAgeHours = 24
    )

    if (-not $TempDir) { $TempDir = Get-AtlasSecureRunDir }
    if (-not (Test-Path -LiteralPath $TempDir)) { return }

    $cutoff = (Get-Date).AddHours(-1 * [math]::Abs($MaxAgeHours))
    try {
        Get-ChildItem -LiteralPath $TempDir -File -ErrorAction SilentlyContinue |
            Where-Object {
                ($_.Name -like 'run-*.ps1' -or $_.Name -like 'run-*.cmd' -or $_.Name -like 'atlas-tool-hashes-*.json') -and
                $_.LastWriteTime -lt $cutoff
            } |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    } catch {
        Write-AtlasLog "Limpieza de temporales fallo: $_" -Level WARN -Tool 'Runner'
    }
}

function Get-AtlasToolScript {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FunctionName)

    $fileName  = "$FunctionName.ps1"
    $cacheDir  = Join-Path $env:LOCALAPPDATA 'AtlasPC\tools'
    $cachePath = Join-Path $cacheDir $fileName
    $fallbackCachePath = $null

    # 0) Source local (dev checkout) + 1) USB offline: deps\tools\ junto al launcher
    $launcherDir = $null
    if ($script:AtlasRoot -and (Test-Path -LiteralPath $script:AtlasRoot)) {
        $launcherDir = $script:AtlasRoot
    } else {
        $candidates = @($PSCommandPath, $MyInvocation.PSCommandPath, $MyInvocation.ScriptName)
        foreach ($candidate in $candidates) {
            if ($candidate -and (Test-Path -LiteralPath $candidate)) {
                $launcherDir = Split-Path -Parent $candidate
                if ($launcherDir) { break }
            }
        }
    }

    if ($launcherDir) {
        # 0) Source local (dev checkout) - evita mismatch de hash cuando el launcher
        # local apunta a un branch que aun no esta en main remoto.
        $localCandidates = @()
        if ($script:AtlasSrc) {
            $localCandidates += (Join-Path $script:AtlasSrc "tools\$fileName")
        }
        $localCandidates += (Join-Path $launcherDir "src\tools\$fileName")

        $seen = @{}
        foreach ($localPath in $localCandidates) {
            if (-not $localPath) { continue }
            $key = $localPath.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true

            if (Test-Path -LiteralPath $localPath) {
                if (Test-AtlasToolFileIntegrity -Path $localPath -FileName $fileName -SourceLabel 'local-src') {
                    Unblock-AtlasFile -Path $localPath
                    Write-AtlasLog "Tool desde source local: $localPath" -Tool 'Runner'
                    return $localPath
                }
                Write-AtlasLog "Tool local-src descartada por integridad: $localPath" -Level WARN -Tool 'Runner'
            }
        }

        $usbPath = Join-Path $launcherDir "deps\tools\$fileName"
        if (Test-Path -LiteralPath $usbPath) {
            if (Test-AtlasToolFileIntegrity -Path $usbPath -FileName $fileName -SourceLabel 'usb') {
                Unblock-AtlasFile -Path $usbPath
                Write-AtlasLog "Tool desde USB: $usbPath" -Tool 'Runner'
                return $usbPath
            }
            Write-AtlasLog "Tool USB descartada por integridad: $usbPath" -Level WARN -Tool 'Runner'
        }
    }

    # 2) Cache local
    $invalidCachePath = $null
    if (Test-Path -LiteralPath $cachePath) {
        if (Test-AtlasToolFileIntegrity -Path $cachePath -FileName $fileName -SourceLabel 'cache') {
            Unblock-AtlasFile -Path $cachePath
            $ageHours = [math]::Round(((Get-Date) - (Get-Item -LiteralPath $cachePath).LastWriteTime).TotalHours, 2)
            if ($ageHours -lt [double]$script:AtlasToolCacheMaxAgeHours) {
                Write-AtlasLog "Tool desde cache fresca ($ageHours h): $cachePath" -Tool 'Runner'
                return $cachePath
            }
            $fallbackCachePath = $cachePath
            Write-AtlasLog "Tool cache valida pero expirada ($ageHours h); intentare refrescar." -Level INFO -Tool 'Runner'
        } else {
            $invalidCachePath = $cachePath
            Write-AtlasLog "Cache invalida para '$fileName'; se intentara refrescar hashes antes de descartar." -Level WARN -Tool 'Runner'
            if (Refresh-AtlasToolHashesFromRemote -FileName $fileName) {
                if (Test-AtlasToolFileIntegrity -Path $cachePath -FileName $fileName -SourceLabel 'cache-refreshed') {
                    Unblock-AtlasFile -Path $cachePath
                    Write-AtlasLog "Cache recuperada tras refresh de hashes: $cachePath" -Level INFO -Tool 'Runner'
                    return $cachePath
                }
            }
            Write-AtlasLog "Cache sigue invalida para '$fileName'; se forzara descarga." -Level WARN -Tool 'Runner'
            Remove-Item -LiteralPath $cachePath -Force -ErrorAction SilentlyContinue
        }
    }

    # 3) Descarga remota (si hay URL base)
    if (-not $script:AtlasToolsBaseUrl) {
        if ($fallbackCachePath) {
            Write-AtlasLog "Sin AtlasToolsBaseUrl; usando cache expirada como fallback: $fallbackCachePath" -Level WARN -Tool 'Runner'
            return $fallbackCachePath
        }
        Write-AtlasLog "No hay AtlasToolsBaseUrl configurada para '$FunctionName'." -Level ERROR -Tool 'Runner'
        return $null
    }

    $toolsBaseUri = $null
    try { $toolsBaseUri = [Uri]$script:AtlasToolsBaseUrl } catch {}
    if (-not $toolsBaseUri -or -not $toolsBaseUri.IsAbsoluteUri -or $toolsBaseUri.Scheme -ne 'https') {
        Write-AtlasLog "AtlasToolsBaseUrl invalida o insegura (solo HTTPS): '$script:AtlasToolsBaseUrl'." -Level ERROR -Tool 'Runner'
        if ($fallbackCachePath) {
            Write-AtlasLog "Usando cache expirada por URL insegura: $fallbackCachePath" -Level WARN -Tool 'Runner'
            return $fallbackCachePath
        }
        return $null
    }

    Write-AtlasLog "Descargando tool: $FunctionName" -Tool 'Runner'
    try {
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }

        $baseUrl = $script:AtlasToolsBaseUrl.TrimEnd('/')
        $url = "$baseUrl/$fileName"
        $tempDownload = Join-Path $cacheDir ($fileName + '.download')
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri ($url + '?v=' + [guid]::NewGuid().ToString('N').Substring(0,8)) `
            -OutFile $tempDownload -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop

        if (-not (Test-AtlasToolFileIntegrity -Path $tempDownload -FileName $fileName -SourceLabel 'download')) {
            # Si el launcher quedo atrasado respecto a hashes remotos, intentar
            # refrescar hashes en caliente y volver a validar sin perder disponibilidad.
            $validatedAfterRefresh = $false
            if (Refresh-AtlasToolHashesFromRemote -FileName $fileName) {
                if (Test-AtlasToolFileIntegrity -Path $tempDownload -FileName $fileName -SourceLabel 'download-refreshed') {
                    $validatedAfterRefresh = $true
                    Write-AtlasLog "Descarga validada tras refresh de hashes: $fileName" -Level INFO -Tool 'Runner'
                }
            }

            if (-not $validatedAfterRefresh) {
                Remove-Item -LiteralPath $tempDownload -Force -ErrorAction SilentlyContinue
                if ($invalidCachePath -and (Test-Path -LiteralPath $invalidCachePath)) {
                    Write-AtlasLog "Usando cache previa como ultimo fallback para '$fileName'." -Level WARN -Tool 'Runner'
                    return $invalidCachePath
                }
                throw "Descarga rechazada por validacion de integridad."
            }
        }

        Move-Item -LiteralPath $tempDownload -Destination $cachePath -Force
        Unblock-AtlasFile -Path $cachePath
        Write-AtlasLog "Tool descargada y validada: $cachePath" -Tool 'Runner'
        return $cachePath
    } catch {
        Write-AtlasLog "Fallo descarga de '$FunctionName': $_" -Level ERROR -Tool 'Runner'
        if ($fallbackCachePath) {
            Write-AtlasLog "Usando cache expirada como fallback: $fallbackCachePath" -Level WARN -Tool 'Runner'
            return $fallbackCachePath
        }
        return $null
    }
}

function Invoke-AtlasTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [hashtable]$Tool,
        [hashtable]$Branding
    )

    Invoke-AtlasRunnerTempCleanup
    Write-AtlasLog "Ejecutando: $($Tool.name) [$($Tool.id)]" -Tool 'Runner'

    $function = $Tool.function

    $runInNew = $true
    if ($Tool.ContainsKey('runsInNewWindow')) {
        $runInNew = [bool]$Tool.runsInNewWindow
    }

    if (-not $runInNew) {
        # Inline (sin nueva ventana): cargar el script en el scope actual y llamar la funcion.
        $toolPath = Get-AtlasToolScript -FunctionName $function
        if (-not $toolPath) {
            $msg = "No se pudo obtener la tool '$function'."
            [System.Windows.MessageBox]::Show($msg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
            return
        }
        try {
            . $toolPath
            & $function
        } catch {
            Write-AtlasLog "Error en ${function}: $_" -Level ERROR -Tool 'Runner'
            [System.Windows.MessageBox]::Show("Error: $_", 'Atlas PC Support', 'OK', 'Error') | Out-Null
        }
        return
    }

    # ----------- Obtener ruta del script de la tool -----------
    $toolScriptPath = Get-AtlasToolScript -FunctionName $function
    if (-not $toolScriptPath) {
        $msg = "No se pudo obtener la tool '$($Tool.name)'. Verifica conexion o integridad."
        Write-AtlasLog $msg -Level ERROR -Tool 'Runner'
        [System.Windows.MessageBox]::Show($msg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
        return
    }

    # ----------- Asegurar BOM para PS 5.1 -----------
    try {
        $bytes = [System.IO.File]::ReadAllBytes($toolScriptPath)
        if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
            $bom = [byte[]](0xEF, 0xBB, 0xBF)
            $withBom = New-Object byte[] ($bom.Length + $bytes.Length)
            [System.Buffer]::BlockCopy($bom, 0, $withBom, 0, $bom.Length)
            [System.Buffer]::BlockCopy($bytes, 0, $withBom, $bom.Length, $bytes.Length)
            [System.IO.File]::WriteAllBytes($toolScriptPath, $withBom)
        }
    } catch {
        Write-AtlasLog "BOM check fallo para '$function': $_" -Level WARN -Tool 'Runner'
    }

    $brandName = if ($Branding -and $Branding.brand -and $Branding.brand.shortName) { $Branding.brand.shortName } else { 'Atlas PC Support' }
    $title = "$brandName - $($Tool.name)"

    # ----------- Script temporal que llama a la tool -----------
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Atlas PC Support - runner temp script')
    [void]$sb.AppendLine('$ErrorActionPreference = ''Continue''')
    [void]$sb.AppendLine('try { $Host.UI.RawUI.WindowTitle = ' + ("'{0}'" -f ($title -replace "'","''")) + ' } catch {}')
    [void]$sb.AppendLine('')
    # ---- Inyectar el ToolKit compartido (helpers de UI / reportes) ----
    # Embebido en el launcher (cubierto por launcher.ps1.sha256), por lo que no
    # anade superficie de descarga. Va dentro de try/catch para que un fallo del
    # toolkit NUNCA impida ejecutar la tool. Se define ANTES del tool para que la
    # propia tool pueda sobre-escribir cualquier helper si lo necesita.
    if ($script:AtlasToolKitSource) {
        [void]$sb.AppendLine('# ---- Atlas ToolKit (inyectado por ToolRunner) ----')
        [void]$sb.AppendLine('try {')
        [void]$sb.AppendLine($script:AtlasToolKitSource)
        [void]$sb.AppendLine('} catch { Write-Host ("[Atlas] ToolKit no disponible: " + $_.Exception.Message) -ForegroundColor DarkYellow }')
        [void]$sb.AppendLine('')
    }

    # Dot-source del archivo de la tool (define la funcion)
    $escapedPath = $toolScriptPath -replace "'", "''"
    [void]$sb.AppendLine(". '$escapedPath'")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('try {')
    [void]$sb.AppendLine("    $function")
    [void]$sb.AppendLine('} catch {')
    [void]$sb.AppendLine('    Write-Host ""')
    [void]$sb.AppendLine("    Write-Host ('[!] Error en $function : ' + `$_.Exception.Message) -ForegroundColor Red")
    [void]$sb.AppendLine('    Write-Host ""')
    [void]$sb.AppendLine('    Write-Host "Traza:" -ForegroundColor DarkGray')
    [void]$sb.AppendLine('    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray')
    [void]$sb.AppendLine('} finally {')
    [void]$sb.AppendLine('    Write-Host ""')
    [void]$sb.AppendLine('    Write-Host "============================================"')
    [void]$sb.AppendLine('    Write-Host "  Tool finalizada. Presiona ENTER para cerrar."')
    [void]$sb.AppendLine('    Write-Host "============================================"')
    [void]$sb.AppendLine('    [void](Read-Host)')
    [void]$sb.AppendLine('    try { Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue } catch {}')
    [void]$sb.AppendLine('}')

    $tempDir = Get-AtlasSecureRunDir
    if (-not (Test-Path -LiteralPath $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    $stamp       = "$($Tool.id)-$(Get-Random)"
    $tempScript  = Join-Path $tempDir "run-$stamp.ps1"

    $utf8WithBom = [System.Text.UTF8Encoding]::new($true)
    [System.IO.File]::WriteAllText($tempScript, $sb.ToString(), $utf8WithBom)
    Unblock-AtlasFile -Path $tempScript

    # Validate wrapper parse before launch to avoid "nothing happens" failures.
    try {
        $parseErrors = $null
        $parseTokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile($tempScript, [ref]$parseTokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors -and $parseErrors.Count -gt 0) {
            $first = $parseErrors[0]
            $line = if ($first.Extent -and $first.Extent.StartLineNumber) { $first.Extent.StartLineNumber } else { '?' }
            $msg = "Wrapper invalido para '$($Tool.name)' (linea $line): $($first.Message)"
            Write-AtlasLog $msg -Level ERROR -Tool 'Runner'
            [System.Windows.MessageBox]::Show($msg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
            return
        }
    } catch {
        Write-AtlasLog "No se pudo validar parser del wrapper temporal: $_" -Level WARN -Tool 'Runner'
    }

    $psExe = 'powershell.exe'
    if ($script:AtlasPS7CachedPath -and (Test-Path -LiteralPath $script:AtlasPS7CachedPath)) {
        $psExe = $script:AtlasPS7CachedPath
    }
    $psArgs = @(
        '-NoLogo',
        '-NoProfile',
        '-Sta',
        '-ExecutionPolicy', 'RemoteSigned',
        '-File', $tempScript
    )

    $startArgs = @{
        FilePath         = $psExe
        ArgumentList     = $psArgs
        WorkingDirectory = (Split-Path -Parent $toolScriptPath)
    }
    if ($Tool.requiresAdmin -and -not (Test-IsAdmin)) {
        $startArgs.Verb = 'RunAs'
    }

    try {
        Start-Process @startArgs | Out-Null
    } catch {
        $errMsg = "No se pudo lanzar la tool '$($Tool.name)': $($_.Exception.Message)"
        Write-AtlasLog $errMsg -Level ERROR -Tool 'Runner'
        [System.Windows.MessageBox]::Show($errMsg, 'Atlas PC Support', 'OK', 'Error') | Out-Null
        Remove-Item -LiteralPath $tempScript -Force -ErrorAction SilentlyContinue
    }
}


# ============================================================
#  GUI
# ============================================================

# ============================================================
# Atlas PC Support — MainWindow.ps1
# Construye la ventana WPF, aplica branding, renderiza herramientas.
# ============================================================

function ConvertTo-AtlasHex {
    param([string]$Hex)
    if (-not $Hex) { return "#FFFFFF" }

    $clean = ([string]$Hex).Trim()
    if ($clean.StartsWith('#')) { $clean = $clean.Substring(1) }
    if ($clean -match '^[0-9A-Fa-f]{3}$') {
        $clean = ($clean.ToCharArray() | ForEach-Object { "$_$_" }) -join ''
    }
    if ($clean -notmatch '^[0-9A-Fa-f]{6}$') {
        return "#FFFFFF"
    }

    return ('#{0}' -f $clean.ToUpperInvariant())
}

function ConvertTo-AtlasXamlSafe {
    param($Value)
    if ($null -eq $Value) { return '' }
    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function ConvertTo-AtlasIntOrDefault {
    param($Value, [int]$Default = 0)
    try { return [int]$Value } catch { return $Default }
}

# Recorre el arbol logico de WPF buscando el primer descendiente del tipo indicado.
function Find-AtlasDescendant {
    param(
        [Parameter(Mandatory)] $Root,
        [Parameter(Mandatory)] [type]$Type
    )
    if ($null -eq $Root) { return $null }
    if ($Root -is $Type) { return $Root }

    # Intentar varios "hijos" segun el tipo de contenedor WPF
    $kids = @()
    if ($Root.PSObject.Properties.Match('Child').Count -gt 0 -and $Root.Child) {
        $kids += $Root.Child
    }
    if ($Root.PSObject.Properties.Match('Children').Count -gt 0 -and $Root.Children) {
        foreach ($c in $Root.Children) { $kids += $c }
    }
    if ($Root.PSObject.Properties.Match('Content').Count -gt 0 -and $Root.Content -and ($Root.Content -is [System.Windows.DependencyObject])) {
        $kids += $Root.Content
    }
    if ($Root.PSObject.Properties.Match('Items').Count -gt 0 -and $Root.Items) {
        foreach ($c in $Root.Items) {
            if ($c -is [System.Windows.DependencyObject]) { $kids += $c }
        }
    }

    foreach ($kid in $kids) {
        $found = Find-AtlasDescendant -Root $kid -Type $Type
        if ($found) { return $found }
    }
    return $null
}

function Get-AtlasPalette {
    param([hashtable]$Branding)

    $accent = ConvertTo-AtlasHex $Branding.theme.accentColor
    $dark   = [bool]$Branding.theme.darkMode
    $secondary = if ($Branding.theme.secondaryColor) { ConvertTo-AtlasHex $Branding.theme.secondaryColor } else { $null }

    if ($dark) {
        # Si hay secondaryColor (ej. Atlas navy #002147), tínta sutilmente el fondo
        $bg      = if ($secondary) { (Get-AtlasColorShift $secondary -15) } else { '#0F1115' }
        $surface = if ($secondary) { (Get-AtlasColorShift $secondary 0)   } else { '#1A1D23' }
        $surfAlt = if ($secondary) { (Get-AtlasColorShift $secondary 15)  } else { '#23272F' }
        return @{
            BgColor          = $bg
            SurfaceColor     = $surface
            SurfaceAltColor  = $surfAlt
            BorderColor      = '#2E333D'
            TextPrimary      = '#F5F5F5'
            TextSecondary    = '#C5C7CC'
            TextMuted        = '#9BA0AA'
            AccentColor      = $accent
            AccentHover      = (Get-AtlasColorShift $accent 20)
            AccentPressed    = (Get-AtlasColorShift $accent -20)
        }
    } else {
        return @{
            BgColor          = '#F7F8FA'
            SurfaceColor     = '#FFFFFF'
            SurfaceAltColor  = '#F0F1F4'
            BorderColor      = '#E0E2E7'
            TextPrimary      = '#1A1D23'
            TextSecondary    = '#434750'
            TextMuted        = '#8A8E95'
            AccentColor      = $accent
            AccentHover      = (Get-AtlasColorShift $accent -10)
            AccentPressed    = (Get-AtlasColorShift $accent -25)
        }
    }
}

function Get-AtlasColorShift {
    param([string]$Hex, [int]$Delta)
    $safeHex = ConvertTo-AtlasHex $Hex
    $h = $safeHex.TrimStart('#')
    $r = [Convert]::ToInt32($h.Substring(0,2), 16)
    $g = [Convert]::ToInt32($h.Substring(2,2), 16)
    $b = [Convert]::ToInt32($h.Substring(4,2), 16)
    $r = [Math]::Max(0, [Math]::Min(255, $r + $Delta))
    $g = [Math]::Max(0, [Math]::Min(255, $g + $Delta))
    $b = [Math]::Max(0, [Math]::Min(255, $b + $Delta))
    return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
}

function Expand-AtlasXaml {
    param(
        [string]$Xaml,
        [hashtable]$Branding,
        [hashtable]$Palette
    )
    $tagline = $Branding.brand.tagline
    if (-not $tagline) { $tagline = Get-AtlasString 'app.tagline' }

    $map = @{
        'WINDOW_TITLE'       = (ConvertTo-AtlasXamlSafe $Branding.window.title)
        'WINDOW_WIDTH'       = (ConvertTo-AtlasIntOrDefault $Branding.window.width 1100)
        'WINDOW_HEIGHT'      = (ConvertTo-AtlasIntOrDefault $Branding.window.height 720)
        'WINDOW_MIN_WIDTH'   = (ConvertTo-AtlasIntOrDefault $Branding.window.minWidth 900)
        'WINDOW_MIN_HEIGHT'  = (ConvertTo-AtlasIntOrDefault $Branding.window.minHeight 600)
        'BRAND_NAME'         = (ConvertTo-AtlasXamlSafe $Branding.brand.name)
        'BRAND_TAGLINE'      = (ConvertTo-AtlasXamlSafe $tagline)
        'BRAND_VERSION'      = (ConvertTo-AtlasXamlSafe $Branding.brand.version)
        'BRAND_COPYRIGHT'    = (ConvertTo-AtlasXamlSafe $Branding.brand.copyright)
        'FONT_FAMILY'        = (ConvertTo-AtlasXamlSafe $Branding.theme.fontFamily)
        'CORNER_RADIUS'      = (ConvertTo-AtlasIntOrDefault $Branding.theme.cornerRadius 8)
        'ACCENT_COLOR'       = $Palette.AccentColor
        'ACCENT_HOVER'       = $Palette.AccentHover
        'ACCENT_PRESSED'     = $Palette.AccentPressed
        'BG_COLOR'           = $Palette.BgColor
        'SURFACE_COLOR'      = $Palette.SurfaceColor
        'SURFACE_ALT_COLOR'  = $Palette.SurfaceAltColor
        'BORDER_COLOR'       = $Palette.BorderColor
        'TEXT_PRIMARY'       = $Palette.TextPrimary
        'TEXT_SECONDARY'     = $Palette.TextSecondary
        'TEXT_MUTED'         = $Palette.TextMuted
        'SEARCH_PLACEHOLDER' = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'search.placeholder'))
        'HEADER_LOGS'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.logs'))
        'HEADER_ABOUT'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.about'))
        'STATUS_READY'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'status.ready'))
        'COFFEE_LABEL'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'footer.coffee'))
        'COFFEE_TOOLTIP'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'footer.coffeeTooltip'))
        'LANG_TOOLTIP'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.languageTooltip'))
        'RESTART_TOOLTIP'    = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'header.restartTooltip'))
        'DASH_CPU'           = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.cpu'))
        'DASH_RAM'           = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.ram'))
        'DASH_DISK'          = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.disk'))
        'DASH_ALERTS'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.alerts'))
        'DASH_REFRESH_TOOLTIP' = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.refreshTooltip'))
        'DASH_TOGGLE_ON'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.monitor.on'))
        'DASH_TOGGLE_OFF'    = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.monitor.off'))
        'DASH_TOGGLE_TOOLTIP'= (ConvertTo-AtlasXamlSafe (Get-AtlasString 'dash.monitor.tooltip'))
        'SIDEBAR_HEADER'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.header'))
        'SIDEBAR_HOST'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.host'))
        'SIDEBAR_USER'       = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.user'))
        'SIDEBAR_OS'         = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.os'))
        'SIDEBAR_CPU'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.cpu'))
        'SIDEBAR_RAM'        = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.ram'))
        'SIDEBAR_UPTIME'     = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.uptime'))
        'SIDEBAR_IP'         = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.ip'))
        'SIDEBAR_LASTSYNC'   = (ConvertTo-AtlasXamlSafe (Get-AtlasString 'sidebar.lastSync'))
    }
    foreach ($k in $map.Keys) {
        $Xaml = $Xaml.Replace("{{$k}}", [string]$map[$k])
    }
    return $Xaml
}

function New-AtlasToolCard {
    param(
        [hashtable]$Tool,
        [hashtable]$Branding,
        [hashtable]$Palette
    )

    $width = 320
    $cornerRadius = ConvertTo-AtlasIntOrDefault $Branding.theme.cornerRadius 8
    $xaml = @"
<Border xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Background='$($Palette.SurfaceColor)'
        BorderBrush='$($Palette.BorderColor)'
        BorderThickness='1'
        CornerRadius='$cornerRadius'
        Padding='16'
        Margin='0,0,12,12'
        Width='$width'>
    <StackPanel>
        <StackPanel Orientation='Horizontal' Margin='0,0,0,6'>
            <TextBlock Text='{{ICON}}' FontSize='18' Margin='0,0,8,0' Foreground='$($Palette.AccentColor)'/>
            <TextBlock Text='{{NAME}}' FontSize='15' FontWeight='SemiBold' Foreground='$($Palette.TextPrimary)' TextTrimming='CharacterEllipsis'/>
        </StackPanel>
        <TextBlock Text='{{DESCRIPTION}}'
                   Foreground='$($Palette.TextSecondary)'
                   FontSize='12'
                   TextWrapping='Wrap'
                   Height='56'
                   Margin='0,0,0,10'/>
        <StackPanel Orientation='Horizontal'>
            <Button x:Name='BtnRun' Content='{{BTN_RUN}}' Tag='{{ID}}' Padding='14,6'
                    Background='$($Palette.AccentColor)' Foreground='White'
                    BorderBrush='$($Palette.AccentColor)' BorderThickness='1'
                    Cursor='Hand'/>
            <TextBlock x:Name='AdminIcon' Text='{{ADMIN_BADGE}}'
                       Foreground='$($Palette.TextMuted)' FontSize='11'
                       Margin='12,0,0,0' VerticalAlignment='Center'/>
        </StackPanel>
    </StackPanel>
</Border>
"@

    $iconMap = @{
        'diagnostico'   = '🔍'
        'mantenimiento' = '🛠'
        'copia'         = '📁'
        'redes'         = '🌐'
        'seguridad'     = '🔒'
        'software'      = '📦'
        'entrega'       = '✅'
    }
    $icon = $iconMap[$Tool.category]
    if (-not $icon) { $icon = '⚙' }

    $adminBadge = if ($Tool.requiresAdmin) { (Get-AtlasString 'badge.requiresAdmin') } else { "" }
    $btnRunText = Get-AtlasString 'button.run'

    $xaml = $xaml.Replace('{{ICON}}', $icon).
                  Replace('{{NAME}}', [System.Security.SecurityElement]::Escape($Tool.name)).
                  Replace('{{DESCRIPTION}}', [System.Security.SecurityElement]::Escape($Tool.description)).
                  Replace('{{ID}}', $Tool.id).
                  Replace('{{BTN_RUN}}', [System.Security.SecurityElement]::Escape($btnRunText)).
                  Replace('{{ADMIN_BADGE}}', $adminBadge)

    return $xaml
}

# ---- Dashboard / Sidebar helpers ----------------------------------------

if (-not $script:AtlasLiveSnapshotMinIntervalSeconds) {
    # Avoid hammering CIM from the UI thread every 2 seconds.
    $script:AtlasLiveSnapshotMinIntervalSeconds = 5
}
if (-not $script:AtlasLiveSnapshotAt) {
    $script:AtlasLiveSnapshotAt = [datetime]::MinValue
}

# Cached static system info (gathered once — these don't change at runtime).
function Get-AtlasStaticSystemInfo {
    if ($script:AtlasStaticSysInfo) { return $script:AtlasStaticSysInfo }
    $info = @{
        HostName    = $env:COMPUTERNAME
        UserName    = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
        OSCaption   = ''
        OSVersion   = ''
        OSBuild     = ''
        CpuName     = ''
        TotalRamGB  = 0
        LastBoot    = $null
        SysDriveLetter = ''
        SysDriveTotalGB = 0
    }
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $info.OSCaption = ($os.Caption -replace '^Microsoft\s*', '').Trim()
        $info.OSVersion = $os.Version
        $info.OSBuild   = $os.BuildNumber
        $info.LastBoot  = $os.LastBootUpTime
        $info.SysDriveLetter = ($os.SystemDrive -replace ':', '')
        # TotalVisibleMemorySize is in KB
        $info.TotalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    } catch { Write-AtlasLog "Get-AtlasStaticSystemInfo: OS query failed: $_" -Level WARN -Tool 'UI' }

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        if ($cpu) { $info.CpuName = ($cpu.Name -replace '\s+', ' ').Trim() }
    } catch { Write-AtlasLog "Get-AtlasStaticSystemInfo: CPU query failed: $_" -Level WARN -Tool 'UI' }

    try {
        if ($info.SysDriveLetter) {
            $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($info.SysDriveLetter):'" -ErrorAction Stop
            if ($disk -and $disk.Size) {
                $info.SysDriveTotalGB = [math]::Round($disk.Size / 1GB, 0)
            }
        }
    } catch { Write-AtlasLog "Get-AtlasStaticSystemInfo: Disk query failed: $_" -Level WARN -Tool 'UI' }

    $script:AtlasStaticSysInfo = $info
    return $info
}

# Live snapshot — fast queries only (called every refresh tick).
function Get-AtlasLiveSystemSnapshot {
    [CmdletBinding()]
    param([switch]$ForceRefresh)

    if (-not $ForceRefresh -and $script:AtlasLiveSnapshotCache -and $script:AtlasLiveSnapshotAt) {
        $ageSec = ((Get-Date) - $script:AtlasLiveSnapshotAt).TotalSeconds
        if ($ageSec -lt [double]$script:AtlasLiveSnapshotMinIntervalSeconds) {
            return $script:AtlasLiveSnapshotCache
        }
    }

    $snap = @{
        CpuPercent  = $null
        RamPercent  = $null
        RamUsedGB   = 0
        RamTotalGB  = 0
        DiskPercent = $null
        DiskFreeGB  = 0
        DiskTotalGB = 0
        IpAddress   = ''
        BatteryPct  = $null
        Uptime      = $null
        UptimeDays  = 0
        PendingReboot = $false
    }

    $static = Get-AtlasStaticSystemInfo

    try {
        $cpuPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor `
            -Filter "Name='_Total'" -ErrorAction Stop
        if ($cpuPerf) { $snap.CpuPercent = [int]$cpuPerf.PercentProcessorTime }
    } catch { }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        if ($os) {
            $totalKb = [double]$os.TotalVisibleMemorySize
            $freeKb  = [double]$os.FreePhysicalMemory
            if ($totalKb -gt 0) {
                $snap.RamPercent = [int](100 - ($freeKb * 100 / $totalKb))
                $snap.RamTotalGB = [math]::Round($totalKb / 1MB, 1)
                $snap.RamUsedGB  = [math]::Round(($totalKb - $freeKb) / 1MB, 1)
            }
            if ($os.LastBootUpTime) {
                $snap.Uptime = (Get-Date) - $os.LastBootUpTime
                $snap.UptimeDays = [int]$snap.Uptime.TotalDays
            }
        }
    } catch { }

    try {
        if ($static.SysDriveLetter) {
            $disk = Get-CimInstance -ClassName Win32_LogicalDisk `
                -Filter "DeviceID='$($static.SysDriveLetter):'" -ErrorAction Stop
            if ($disk -and $disk.Size -gt 0) {
                $snap.DiskTotalGB = [math]::Round($disk.Size / 1GB, 0)
                $snap.DiskFreeGB  = [math]::Round($disk.FreeSpace / 1GB, 0)
                $snap.DiskPercent = [int]((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100)
            }
        }
    } catch { }

    try {
        # Prefer Get-NetIPAddress (PS 5.1+ on Win8+); fallback to ipconfig parse
        $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.PrefixOrigin -ne 'WellKnown' -and $_.IPAddress -notmatch '^169\.254\.' -and $_.IPAddress -ne '127.0.0.1' } |
            Sort-Object -Property InterfaceMetric |
            Select-Object -First 1
        if ($ip) { $snap.IpAddress = $ip.IPAddress }
    } catch { }

    try {
        $bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop |
            Select-Object -First 1
        if ($bat -and $null -ne $bat.EstimatedChargeRemaining) {
            $snap.BatteryPct = [int]$bat.EstimatedChargeRemaining
        }
    } catch { }

    try {
        $pendingPaths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        )
        foreach ($p in $pendingPaths) {
            if (Test-Path $p) { $snap.PendingReboot = $true; break }
        }
    } catch { }

    $script:AtlasLiveSnapshotCache = $snap
    $script:AtlasLiveSnapshotAt = Get-Date
    return $snap
}

# Build localized alert list from the live snapshot.
function Get-AtlasDashboardAlerts {
    param([hashtable]$Snap)
    $alerts = @()
    if ($null -ne $Snap.CpuPercent -and $Snap.CpuPercent -ge 90) {
        $alerts += (Get-AtlasString 'dash.alert.cpu' $Snap.CpuPercent)
    }
    if ($null -ne $Snap.RamPercent -and $Snap.RamPercent -ge 90) {
        $alerts += (Get-AtlasString 'dash.alert.ram' $Snap.RamPercent)
    }
    if ($null -ne $Snap.DiskPercent -and $Snap.DiskPercent -ge 90) {
        $static = Get-AtlasStaticSystemInfo
        $alerts += (Get-AtlasString 'dash.alert.disk' "$($static.SysDriveLetter):" $Snap.DiskPercent)
    }
    if ($Snap.UptimeDays -ge 7) {
        $alerts += (Get-AtlasString 'dash.alert.uptime' $Snap.UptimeDays)
    }
    if ($null -ne $Snap.BatteryPct -and $Snap.BatteryPct -le 20) {
        $alerts += (Get-AtlasString 'dash.alert.battery' $Snap.BatteryPct)
    }
    if ($Snap.PendingReboot) {
        $alerts += (Get-AtlasString 'dash.alert.pendingReboot')
    }
    return ,$alerts
}

# Initialize dashboard + sidebar data.
#
# Performance: pre-fill the cheap fields (hostname/user from env vars)
# synchronously, then defer all CIM/WMI/Get-NetIPAddress work to run AFTER
# the window has been rendered. This way the panel pops up immediately
# and the dashboard fills in over the next ~1 s instead of blocking the
# Show-AtlasWindow ShowDialog call for several CIM round trips on startup.
function Initialize-AtlasDashboard {
    param([Parameter(Mandatory)] $Window)

    # ---- Phase 1: instant fill (no CIM) -----------------------------
    $sideHost     = $Window.FindName('SideHost')
    $sideUser     = $Window.FindName('SideUser')
    $sideOS       = $Window.FindName('SideOS')
    $sideCpu      = $Window.FindName('SideCpu')
    $sideRam      = $Window.FindName('SideRam')
    $sideUptime   = $Window.FindName('SideUptime')
    $sideIp       = $Window.FindName('SideIp')
    $sideLastSync = $Window.FindName('SideLastSync')

    if ($sideHost) { $sideHost.Text = $env:COMPUTERNAME }
    if ($sideUser) {
        $sideUser.Text = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
    }
    $loadingTxt = '...'
    if ($sideOS)     { $sideOS.Text     = $loadingTxt }
    if ($sideCpu)    { $sideCpu.Text    = $loadingTxt }
    if ($sideRam)    { $sideRam.Text    = $loadingTxt }
    if ($sideUptime) { $sideUptime.Text = $loadingTxt }

    $dashCpuVal   = $Window.FindName('DashCpuValue')
    $dashCpuBar   = $Window.FindName('DashCpuBar')
    $dashRamVal   = $Window.FindName('DashRamValue')
    $dashRamBar   = $Window.FindName('DashRamBar')
    $dashDiskVal  = $Window.FindName('DashDiskValue')
    $dashDiskBar  = $Window.FindName('DashDiskBar')
    $dashAlerts   = $Window.FindName('DashAlertsText')
    $btnDashRefresh = $Window.FindName('BtnDashRefresh')
    $btnDashMonitorToggle = $Window.FindName('BtnDashMonitorToggle')

    $monitorOffText = Get-AtlasString 'dash.monitor.off'
    $monitorOnText = Get-AtlasString 'dash.monitor.on'
    $monitorPausedText = Get-AtlasString 'dash.monitor.paused'

    if ($dashAlerts) {
        $dashAlerts.Text = $monitorPausedText
        $dashAlerts.Foreground = [System.Windows.Media.Brushes]::Gray
    }

    # ---- Phase 2: deferred CIM/WMI work -----------------------------
    #
    # In Windows PowerShell 5.1, GetNewClosure() snapshots local variables
    # but breaks access to script-scope FUNCTIONS (verified by user log:
    # "The term 'Write-AtlasLog' is not recognized" thrown from inside
    # the closed scriptblock). Workaround: capture every function we need
    # as a scriptblock value into local variables, then invoke them with
    # `&` inside the closure. The closure picks up the local refs by value
    # so everything resolves bullet-proof at tick time.
    $logFn        = ${function:Write-AtlasLog}
    $strFn        = ${function:Get-AtlasString}
    $liveFn       = ${function:Get-AtlasLiveSystemSnapshot}
    $staticFn     = ${function:Get-AtlasStaticSystemInfo}
    $alertsFn     = ${function:Get-AtlasDashboardAlerts}

    $tickAction = {
        try {
            $snap = & $liveFn

            if ($null -ne $snap.CpuPercent) {
                $dashCpuVal.Text = "{0}%" -f $snap.CpuPercent
                $dashCpuBar.Value = $snap.CpuPercent
            }
            if ($null -ne $snap.RamPercent) {
                $dashRamVal.Text = "{0}% ({1}/{2} GB)" -f $snap.RamPercent, $snap.RamUsedGB, $snap.RamTotalGB
                $dashRamBar.Value = $snap.RamPercent
            }
            if ($null -ne $snap.DiskPercent) {
                $dashDiskVal.Text = & $strFn 'dash.disk.detail' $snap.DiskPercent $snap.DiskFreeGB
                $dashDiskBar.Value = $snap.DiskPercent
            }

            if ($sideIp -and $snap.IpAddress) { $sideIp.Text = $snap.IpAddress }

            # Static info (cached) — also drives the sidebar fields that
            # were left as "..." during phase-1 instant fill.
            $static2 = & $staticFn
            if ($sideOS -and $sideOS.Text -eq '...' -and $static2.OSCaption) {
                $os = if ($static2.OSBuild) { "$($static2.OSCaption) (build $($static2.OSBuild))" } else { $static2.OSCaption }
                $sideOS.Text = $os
            }
            if ($sideCpu -and $sideCpu.Text -eq '...' -and $static2.CpuName) {
                $sideCpu.Text = $static2.CpuName
            }
            if ($sideRam -and $sideRam.Text -eq '...' -and $static2.TotalRamGB -gt 0) {
                $sideRam.Text = "$($static2.TotalRamGB) GB"
            }
            if ($sideUptime -and $snap.Uptime -and $static2.LastBoot) {
                $upFmt = & $strFn 'sidebar.uptimeFmt' `
                    ([int]$snap.Uptime.TotalDays) `
                    ($snap.Uptime.Hours) `
                    ($snap.Uptime.Minutes)
                $sideUptime.Text = "$($static2.LastBoot.ToString('yyyy-MM-dd HH:mm'))  ($upFmt)"
            }

            $alerts = & $alertsFn -Snap $snap
            if ($alerts.Count -eq 0) {
                $dashAlerts.Text = & $strFn 'dash.alerts.none'
                $dashAlerts.Foreground = [System.Windows.Media.Brushes]::ForestGreen
            } else {
                $dashAlerts.Text = '⚠  ' + ($alerts -join '   •   ')
                $dashAlerts.Foreground = [System.Windows.Media.Brushes]::OrangeRed
            }

            if ($sideLastSync) {
                $sideLastSync.Text = (Get-Date).ToString('HH:mm:ss')
            }
        } catch {
            try { & $logFn "Dashboard tick failed: $_" -Level WARN -Tool 'UI' } catch { }
        }
    }

    # CRITICAL: scriptblocks captured by .NET event handlers (DispatcherTimer,
    # Window.ContentRendered, Button.Click) lose access to local variables
    # by the time they fire. GetNewClosure() snapshots the current scope so
    # $dashCpuVal/$sideHost/$logFn/etc. are all resolvable when the tick runs.
    $tickClosed = $tickAction.GetNewClosure()
    $script:AtlasDashboardTick = $tickClosed
    try {
        & $logFn ("Dashboard tick handler initialized: {0}" -f ($script:AtlasDashboardTick.GetType().FullName)) -Level DEBUG -Tool 'UI'
    } catch { }

    $startMonitorAction = {
        try {
            $tickToRun = if ($script:AtlasDashboardTick -is [scriptblock]) { $script:AtlasDashboardTick } else { $tickClosed }
            if (-not ($tickToRun -is [scriptblock])) {
                throw "Dashboard tick handler no disponible."
            }
            if (-not $script:AtlasDashboardTimer) {
                $timer = New-Object System.Windows.Threading.DispatcherTimer
                $timer.Interval = [TimeSpan]::FromSeconds(2)
                $timer.Add_Tick($tickToRun)
                $script:AtlasDashboardTimer = $timer
            }
            & $tickToRun
            $script:AtlasDashboardTimer.Start()
            $script:AtlasDashboardMonitorEnabled = $true
            if ($btnDashMonitorToggle) { $btnDashMonitorToggle.Content = $monitorOnText }
            try { & $logFn "Dashboard monitor started." -Level DEBUG -Tool 'UI' } catch { }
        } catch {
            try { & $logFn "Dashboard monitor start failed: $_" -Level WARN -Tool 'UI' } catch { }
        }
    }

    $stopMonitorAction = {
        try {
            if ($script:AtlasDashboardTimer) {
                $script:AtlasDashboardTimer.Stop()
            }
            $script:AtlasDashboardMonitorEnabled = $false
            if ($btnDashMonitorToggle) { $btnDashMonitorToggle.Content = $monitorOffText }
            if ($dashAlerts) {
                $dashAlerts.Text = $monitorPausedText
                $dashAlerts.Foreground = [System.Windows.Media.Brushes]::Gray
            }
        } catch {
            try { & $logFn "Dashboard monitor stop failed: $_" -Level WARN -Tool 'UI' } catch { }
        }
    }

    $startClosed = $startMonitorAction.GetNewClosure()
    $stopClosed = $stopMonitorAction.GetNewClosure()
    $script:AtlasDashboardStartMonitor = $startClosed
    $script:AtlasDashboardStopMonitor = $stopClosed

    # Wire the manual refresh button (↻ next to the alerts panel).
    if ($btnDashRefresh) {
        $btnDashRefresh.Add_Click({
            try {
                $script:AtlasLiveSnapshotAt = [datetime]::MinValue
                $tickToRun = if ($script:AtlasDashboardTick -is [scriptblock]) { $script:AtlasDashboardTick } else { $tickClosed }
                if ($tickToRun -is [scriptblock]) {
                    & $tickToRun
                } else {
                    throw "Dashboard tick handler no disponible para refresh."
                }
            } catch {
                try { & $logFn "Dashboard manual refresh failed: $_" -Level WARN -Tool 'UI' } catch { }
            }
        })
    }

    if ($btnDashMonitorToggle) {
        $btnDashMonitorToggle.Add_Click({
            try {
                $startToRun = if ($script:AtlasDashboardStartMonitor -is [scriptblock]) { $script:AtlasDashboardStartMonitor } else { $startClosed }
                $stopToRun  = if ($script:AtlasDashboardStopMonitor -is [scriptblock]) { $script:AtlasDashboardStopMonitor } else { $stopClosed }
                if ($script:AtlasDashboardMonitorEnabled) {
                    if ($stopToRun -is [scriptblock]) {
                        & $stopToRun
                    } else {
                        throw "Dashboard stop handler no disponible."
                    }
                } else {
                    if ($startToRun -is [scriptblock]) {
                        & $startToRun
                    } else {
                        throw "Dashboard start handler no disponible."
                    }
                }
            } catch {
                try { & $logFn "Dashboard monitor toggle click failed: $_" -Level WARN -Tool 'UI' } catch { }
            }
        })
    }

    # Keep startup cheap. The live monitor stays off until the user enables it.
    $bootstrapAction = {
        try {
            if ($script:AtlasDashboardBooted) { return }
            $script:AtlasDashboardBooted = $true

            $static2 = & $staticFn
            if ($sideOS -and $static2.OSCaption) {
                $os = if ($static2.OSBuild) { "$($static2.OSCaption) (build $($static2.OSBuild))" } else { $static2.OSCaption }
                $sideOS.Text = $os
            }
            if ($sideCpu -and $static2.CpuName) {
                $sideCpu.Text = $static2.CpuName
            }
            if ($sideRam -and $static2.TotalRamGB -gt 0) {
                $sideRam.Text = "$($static2.TotalRamGB) GB"
            }

            $snap2 = & $liveFn
            if ($sideIp -and $snap2.IpAddress) {
                $sideIp.Text = $snap2.IpAddress
            }
            if ($sideUptime -and $snap2.Uptime -and $static2.LastBoot) {
                $upFmt = & $strFn 'sidebar.uptimeFmt' `
                    ([int]$snap2.Uptime.TotalDays) `
                    ($snap2.Uptime.Hours) `
                    ($snap2.Uptime.Minutes)
                $sideUptime.Text = "$($static2.LastBoot.ToString('yyyy-MM-dd HH:mm'))  ($upFmt)"
            }
            if ($sideLastSync) {
                $sideLastSync.Text = (Get-Date).ToString('HH:mm:ss')
            }

            $stopToRun = if ($script:AtlasDashboardStopMonitor -is [scriptblock]) { $script:AtlasDashboardStopMonitor } else { $stopClosed }
            if ($stopToRun -is [scriptblock]) { & $stopToRun }
        } catch {
            try { & $logFn "Dashboard bootstrap failed: $_" -Level WARN -Tool 'UI' } catch { }
        }
    }
    $bootstrapClosed = $bootstrapAction.GetNewClosure()
    $Window.Add_ContentRendered($bootstrapClosed)

    # Stop the timer cleanly when the window closes.
    $Window.Add_Closed({
        try {
            if ($script:AtlasDashboardTimer) {
                $script:AtlasDashboardTimer.Stop()
                $script:AtlasDashboardTimer = $null
            }
            $script:AtlasDashboardBooted = $false
            $script:AtlasDashboardMonitorEnabled = $false
            $script:AtlasDashboardTick = $null
            $script:AtlasDashboardStartMonitor = $null
            $script:AtlasDashboardStopMonitor = $null
            $script:AtlasLiveSnapshotCache = $null
            $script:AtlasLiveSnapshotAt = [datetime]::MinValue
        } catch { }
    })
}

function Show-AtlasWindow {
    param(
        [hashtable]$Branding,
        [array]$Tools,
        [string]$XamlTemplate
    )

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    $palette = Get-AtlasPalette -Branding $Branding
    $xaml    = Expand-AtlasXaml -Xaml $XamlTemplate -Branding $Branding -Palette $palette

    try {
        [xml]$xamlDoc = $xaml
    } catch {
        throw "XAML inválido tras expansión de branding: $_"
    }

    $reader = New-Object System.Xml.XmlNodeReader $xamlDoc
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Agarrar controles
    $categoryBar = $window.FindName('CategoryBar')
    $toolsGrid   = $window.FindName('ToolsGrid')
    $searchBox   = $window.FindName('SearchBox')
    $statusText  = $window.FindName('StatusText')
    $adminBadge  = $window.FindName('AdminBadge')
    $btnLogs     = $window.FindName('BtnLogs')
    $btnAbout    = $window.FindName('BtnAbout')
    $btnRestart  = $window.FindName('BtnRestart')
    $coffeeLink  = $window.FindName('CoffeeLink')
    $langCombo   = $window.FindName('LanguageCombo')

    # Badge de admin en header
    if (Test-IsAdmin) {
        $adminBadge.Text = Get-AtlasString 'header.admin'
        $adminBadge.Foreground = [System.Windows.Media.Brushes]::LimeGreen
    } else {
        $adminBadge.Text = Get-AtlasString 'header.user'
    }

    # Categorías — usa label traducido si el brand no sobreescribe
    $categories = @($Branding.categories) | Sort-Object -Property order
    $allCat = New-Object System.Windows.Controls.RadioButton
    $allCat.Content = Get-AtlasString 'category.all'
    $allCat.Style = $window.FindResource('CategoryPill')
    $allCat.Tag = '__all__'
    $allCat.IsChecked = $true
    [void]$categoryBar.Children.Add($allCat)

    foreach ($cat in $categories) {
        $rb = New-Object System.Windows.Controls.RadioButton
        $translatedLabel = Get-AtlasString "category.$($cat.id)"
        $label = if ($translatedLabel -ne "category.$($cat.id)") { $translatedLabel } else { $cat.label }
        $rb.Content = "$($cat.icon) $label"
        $rb.Style = $window.FindResource('CategoryPill')
        $rb.Tag = $cat.id
        [void]$categoryBar.Children.Add($rb)
    }

    # Renderizar tools
    $script:AllCards = @()
    foreach ($tool in $Tools) {
        $cardXaml = New-AtlasToolCard -Tool $tool -Branding $Branding -Palette $palette
        [xml]$cardDoc = $cardXaml
        $cardReader = New-Object System.Xml.XmlNodeReader $cardDoc
        $card = [Windows.Markup.XamlReader]::Load($cardReader)
        $card.Tag = $tool

        # Walk visual tree robustly para encontrar el boton "Run"
        $btn = Find-AtlasDescendant -Root $card -Type ([System.Windows.Controls.Button])
        if ($btn) {
            # Guardar el tool completo en el Tag del boton, evita depender de scope compartido
            $btn.Tag = $tool
            Write-AtlasLog ("Bound click handler: tool={0}" -f $tool.id) -Level DEBUG

            $btn.Add_Click({
                param($eventSender, $eventArgs)
                try {
                    # $eventSender es el boton, fallback a $this si PowerShell no lo binde
                    $theBtn = if ($eventSender) { $eventSender } else { $this }
                    $t = $theBtn.Tag
                    if (-not $t) {
                        Write-AtlasLog "Click: Button.Tag esta vacio" -Level WARN
                        return
                    }
                    Write-AtlasLog ("Click: lanzando tool={0} function={1}" -f $t.id, $t.function) -Level INFO

                    $statusText = $script:MainWindow.FindName('StatusText')
                    if ($statusText) { $statusText.Text = Get-AtlasString 'status.launching' $t.name }

                    Invoke-AtlasTool -Tool $t -Branding $script:Branding

                    if ($statusText) { $statusText.Text = Get-AtlasString 'status.lastRun' $t.name }
                } catch {
                    Write-AtlasLog ("Click handler fallo: {0}" -f $_.Exception.Message) -Level ERROR
                    [System.Windows.MessageBox]::Show(
                        "Error al lanzar la herramienta:`n`n$($_.Exception.Message)",
                        "Atlas PC Support",
                        'OK', 'Error') | Out-Null
                }
            })
        } else {
            Write-AtlasLog ("NO se encontro el boton Run para tool={0}" -f $tool.id) -Level ERROR
        }

        $script:AllCards += [pscustomobject]@{ Card = $card; Tool = $tool }
        [void]$toolsGrid.Items.Add($card)
    }

    # Función filtro
    $applyFilter = {
        $selectedCat = ($categoryBar.Children | Where-Object { $_.IsChecked }).Tag
        $query = $searchBox.Text.Trim().ToLower()

        $toolsGrid.Items.Clear()
        foreach ($entry in $script:AllCards) {
            $t = $entry.Tool
            $matchesCat = ($selectedCat -eq '__all__') -or ($t.category -eq $selectedCat)
            $matchesQuery = (-not $query) -or ($t.name.ToLower().Contains($query)) -or ($t.description.ToLower().Contains($query))
            if ($matchesCat -and $matchesQuery) {
                [void]$toolsGrid.Items.Add($entry.Card)
            }
        }
        $statusText.Text = Get-AtlasString 'status.toolsShown' $toolsGrid.Items.Count
    }

    foreach ($rb in $categoryBar.Children) {
        $rb.Add_Checked($applyFilter)
    }
    $searchBox.Add_TextChanged($applyFilter)

    # Botones header
    $btnLogs.Add_Click({
        $logPath = Get-AtlasLogPath
        if (Test-Path $logPath) {
            Start-Process notepad.exe -ArgumentList $logPath
        } else {
            [System.Windows.MessageBox]::Show((Get-AtlasString 'logs.empty'), $script:Branding.brand.shortName) | Out-Null
        }
    })
    $btnAbout.Add_Click({
        $webLabel = Get-AtlasString 'about.web'
        $tagline = if ($script:Branding.brand.tagline) { $script:Branding.brand.tagline } else { Get-AtlasString 'app.tagline' }
        $msg = @"
$($script:Branding.brand.name) v$($script:Branding.brand.version)

$tagline

$($webLabel): $($script:Branding.brand.companyUrl)
$($script:Branding.brand.copyright)

$(Get-AtlasString 'about.description')
"@
        [System.Windows.MessageBox]::Show($msg, (Get-AtlasString 'about.title'), "OK", "Information") | Out-Null
    })

    # Selector de idioma (header)
    if ($langCombo) {
        $supported = Get-AtlasSupportedLanguages
        $currentLang = $script:AtlasCurrentLang
        $selectedIndex = 0
        $i = 0
        foreach ($code in $supported) {
            $item = New-Object System.Windows.Controls.ComboBoxItem
            $item.Content = Get-AtlasLanguageName $code
            $item.Tag = $code
            [void]$langCombo.Items.Add($item)
            if ($code -eq $currentLang) { $selectedIndex = $i }
            $i++
        }
        $langCombo.SelectedIndex = $selectedIndex
        # Marcar initial selection como hecho ANTES de enganchar el handler,
        # para evitar que un evento espureo dispare al crear la ComboBox.
        $script:LangComboReady = $true
        $langCombo.Add_SelectionChanged({
            param($eventSender, $eventArgs)
            if (-not $script:LangComboReady) { return }
            $sel = $eventSender.SelectedItem
            if (-not $sel) { return }
            $newLang = [string]$sel.Tag
            if ($newLang -eq $script:AtlasCurrentLang) { return }
            $ok = Set-AtlasLanguagePref $newLang
            Write-AtlasLog "Idioma cambiado a '$newLang' (guardado=$ok). Reinicio requerido." -Tool 'UI'
            $brand = if ($script:Branding -and $script:Branding.brand) { $script:Branding.brand.shortName } else { 'Atlas PC Support' }
            # Usar el string del NUEVO idioma (ya cargado en el dict, solo no aplicado a UI)
            $msg = $script:AtlasStringsDict[$newLang]['language.restartRequired']
            if (-not $msg) { $msg = Get-AtlasString 'language.restartRequired' }
            [System.Windows.MessageBox]::Show($msg, $brand, 'OK', 'Information') | Out-Null
        })
    }

    if ($btnRestart) {
        $btnRestart.Add_Click({
            $msg = Get-AtlasString 'restart.instructions'
            $brand = if ($script:Branding -and $script:Branding.brand) { $script:Branding.brand.shortName } else { 'Atlas PC Support' }
            [System.Windows.MessageBox]::Show($msg, $brand, 'OK', 'Information') | Out-Null
            Write-AtlasLog "Reinicio solicitado por usuario — cerrando panel." -Tool 'UI'
            if ($script:MainWindow) { $script:MainWindow.Close() }
        })
    }

    # Coffee / donacion (footer)
    if ($coffeeLink) {
        $coffeeUrl = 'https://www.paypal.me/atlaspcsupport'
        $coffeeLink.Add_MouseLeftButtonUp({
            try {
                Start-Process $coffeeUrl
            } catch {
                Write-AtlasLog "No se pudo abrir URL de donacion: $_" -Level WARN
            }
        })
    }

    $script:MainWindow = $window
    $script:Branding = $Branding
    $script:AllTools = $Tools

    # Populate dashboard + sidebar and start the live refresh timer.
    try {
        Initialize-AtlasDashboard -Window $window
    } catch {
        Write-AtlasLog "Initialize-AtlasDashboard failed: $_" -Level WARN -Tool 'UI'
    }

    [void]$window.ShowDialog()
}



# ============================================================
#  BOOTSTRAP
# ============================================================

$ErrorActionPreference = 'Stop'

$branding = Get-AtlasBranding
# Preferencia guardada por el usuario (selector de idioma) manda sobre branding / auto-detect.
$savedLang = Get-AtlasLanguagePref
if ($savedLang) {
    $currentLang = Set-AtlasLanguage $savedLang
} else {
    $currentLang = Set-AtlasLanguage $branding.language
}
Initialize-AtlasLog | Out-Null
Write-AtlasLog "Atlas PC Support iniciado (launcher compilado v$script:AtlasVersion, lang=$currentLang, savedPref=$savedLang)"

# Detectar PS 7 y cachear la ruta (ToolRunner lo usa para lanzar tools en pwsh).
$ps7 = Initialize-AtlasPS7
if ($ps7) {
    Write-AtlasLog "PowerShell 7 disponible: $ps7"
} else {
    Write-AtlasLog "PowerShell 7 NO instalado; tools correran en Windows PowerShell 5.1. Usar la tool 'Actualizar PowerShell'."
}

try {
    $toolHashesObj = ConvertFrom-AtlasJson $script:AtlasToolHashesJson
    if ($toolHashesObj.files -is [hashtable]) {
        $script:AtlasToolHashes = $toolHashesObj.files
        Write-AtlasLog "Hashes embebidos cargados: $($script:AtlasToolHashes.Count)" -Tool 'Launcher'
    } else {
        $script:AtlasToolHashes = @{}
        Write-AtlasLog "Hash map embebido invalido; continuando sin validacion fuerte." -Level WARN -Tool 'Launcher'
    }
} catch {
    $script:AtlasToolHashes = @{}
    Write-AtlasLog "No se pudo parsear hash map embebido: $_" -Level WARN -Tool 'Launcher'
}

try {
    $manifestObj = ConvertFrom-AtlasJson $script:AtlasToolsManifest
    $tools = @($manifestObj.tools)
} catch {
    throw "No se pudo parsear el manifiesto embebido: $_"
}

Show-AtlasWindow -Branding $branding -Tools $tools -XamlTemplate $script:AtlasXamlTemplate