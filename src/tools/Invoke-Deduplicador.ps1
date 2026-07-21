# ============================================================
# Invoke-Deduplicador
# Atlas PC Support — v1.0
# ============================================================

function Invoke-Deduplicador {
    [CmdletBinding()]
    param()

    #region ── Inicializacion ─────────────────────────────────────────────────────
    [console]::BackgroundColor = "Black"
    [console]::ForegroundColor = "White"
    Clear-Host

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

    $T = @{
        Title       = if ($es) { "Deduplicador Visual Web" } else { "Visual Web Deduplicator" }
        Opt1        = if ($es) { " [1] Iniciar Servidor Deduplicador Web y Abrir Navegador" } else { " [1] Start Web Deduplicator Server & Open Browser" }
        Opt2        = if ($es) { " [2] Detener Servidor Deduplicador Activo (DeduplicadorServer)" } else { " [2] Stop Active Deduplicator Server (DeduplicadorServer)" }
        Opt0        = if ($es) { " [0] Volver al Menú Principal / Salir" } else { " [0] Back to Main Menu / Exit" }
        Prompt      = if ($es) { "Elige una opción (0-2): " } else { "Choose an option (0-2): " }
        FolderP     = if ($es) { " Carpeta a escanear [D:\0.MULTIMEDIA\memes]: " } else { " Folder to scan [D:\0.MULTIMEDIA\memes]: " }
        Checking    = if ($es) { " [>] Verificando dependencias de Python..." } else { " [>] Checking Python dependencies..." }
        PyErr       = if ($es) { " [ERROR] Python no está instalado o no se encuentra en el PATH." } else { " [ERROR] Python is not installed or not found in PATH." }
        PyHint      = if ($es) { " Descárgalo e instálalo desde python.org y activa 'Add python.exe to PATH'." } else { " Download and install it from python.org and select 'Add python.exe to PATH'." }
        PillInstall = if ($es) { " [i] Pillow no está instalado. Instalándolo vía pip..." } else { " [i] Pillow is not installed. Installing via pip..." }
        ScNotF      = if ($es) { " [!] No se pudo encontrar 'app_deduplicar.py' automáticamente." } else { " [!] Could not locate 'app_deduplicar.py' automatically." }
        ScPrompt    = if ($es) { " Ingrese la ruta completa de app_deduplicar.py: " } else { " Enter the full path of app_deduplicar.py: " }
        Starting    = if ($es) { " [>] Iniciando servidor en segundo plano..." } else { " [>] Starting server in background..." }
        Started     = if ($es) { " [OK] Servidor iniciado. Abriendo navegador predeterminado..." } else { " [OK] Server started. Opening default browser..." }
        Stopping    = if ($es) { " [>] Deteniendo servidores activos..." } else { " [>] Stopping active servers..." }
        Stopped     = if ($es) { " [OK] Servidor(es) detenido(s) con éxito." } else { " [OK] Server(s) successfully stopped." }
        Next        = if ($es) { " Presiona cualquier tecla para continuar..." } else { " Press any key to continue..." }
    }
    $atlasToolkitReady = [bool](Get-Command Write-AtlasHeader -ErrorAction SilentlyContinue)

    function Pause-Deduplicador {
        param([string]$Message)
        if ($atlasToolkitReady -and (Get-Command Wait-AtlasExit -ErrorAction SilentlyContinue)) {
            Wait-AtlasExit -Message $Message
            return
        }
        Read-Host $Message | Out-Null
    }

    function Show-DeduplicadorHeader {
        Clear-Host
        Write-Host ''
        if ($atlasToolkitReady) {
            Write-AtlasHeader -Title ("ATLAS PC SUPPORT - " + $T.Title) -Color Yellow
            Write-Host ''
            return
        }
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host "         ATLAS PC SUPPORT - $($T.Title)" -ForegroundColor Yellow
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host ''
    }
    #endregion

    while ($true) {
        Show-DeduplicadorHeader
        Write-Host $T.Opt1 -ForegroundColor White
        Write-Host $T.Opt2 -ForegroundColor White
        Write-Host ''
        Write-Host $T.Opt0 -ForegroundColor DarkGray
        Write-Host ''

        $opt = Read-Host $T.Prompt
        if ($opt -eq '0') {
            break
        }
        elseif ($opt -eq '1') {
            # 1. Verificar Python
            Write-Host ''
            Write-Host $T.Checking -ForegroundColor Cyan
            $pythonCheck = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonCheck) {
                Write-Host $T.PyErr -ForegroundColor Red
                Write-Host $T.PyHint -ForegroundColor Yellow
                Write-Host ''
                Pause-Deduplicador -Message $T.Next
                continue
            }

            # Verificar Pillow
            python -c "from PIL import Image" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host $T.PillInstall -ForegroundColor Cyan
                pip install Pillow
            }

            # 2. Localizar app_deduplicar.py
            $possiblePaths = @(
                (Join-Path $env:LOCALAPPDATA 'AtlasPC\scripts\app_deduplicar.py'),
                (Join-Path $PSScriptRoot "app_deduplicar.py"),
                (Join-Path $PSScriptRoot "scripts\app_deduplicar.py"),
                (Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\app_deduplicar.py"),
                (Join-Path (Get-Location).Path "scripts\app_deduplicar.py"),
                (Join-Path (Get-Location).Path "app_deduplicar.py")
            )
            $scriptPath = $null
            foreach ($p in $possiblePaths) {
                if (Test-Path -LiteralPath $p) {
                    $scriptPath = (Resolve-Path -LiteralPath $p).Path
                    break
                }
            }
            if (-not $scriptPath) {
                Write-Host $T.ScNotF -ForegroundColor Yellow
                $scriptPath = Read-Host $T.ScPrompt
                if ([string]::IsNullOrWhiteSpace($scriptPath) -or -not (Test-Path -LiteralPath $scriptPath)) {
                    Write-Host " [ERROR] Archivo no encontrado en la ruta especificada." -ForegroundColor Red
                    Write-Host ''
                    Pause-Deduplicador -Message $T.Next
                    continue
                }
            }

            # 3. Solicitar carpeta a escanear
            $defaultPictures = [Environment]::GetFolderPath('MyPictures')
            $folderInput = Read-Host ($T.FolderP -replace '\[.*?\]', "[$defaultPictures]")
            if ([string]::IsNullOrWhiteSpace($folderInput)) {
                $folderPath = $defaultPictures
            } else {
                # First check if the entire input exists (handles single unquoted folder with spaces)
                $trimmedInput = $folderInput.Trim().Trim('"').Trim("'").Trim()
                if (Test-Path -LiteralPath $trimmedInput) {
                    $folderPath = $trimmedInput
                } else {
                    # Parse multiple paths that might be quoted (single/double) or separated by space/semicolon/comma
                    $pattern = '"([^"]+)"|''([^'']+)''|([^;,\s]+)'
                    $matches = [regex]::Matches($folderInput, $pattern)
                    $paths = @()
                    foreach ($m in $matches) {
                        $p = $m.Groups[1].Value
                        if ([string]::IsNullOrEmpty($p)) { $p = $m.Groups[2].Value }
                        if ([string]::IsNullOrEmpty($p)) { $p = $m.Groups[3].Value }
                        if (-not [string]::IsNullOrWhiteSpace($p)) {
                            $p = $p.Trim().Trim('"').Trim("'").Trim()
                            $paths += $p
                        }
                    }
                    
                    if ($paths.Count -eq 0) {
                        $folderPath = "D:\0.MULTIMEDIA\memes"
                    } elseif ($paths.Count -eq 1) {
                        $folderPath = $paths[0]
                    } else {
                        # Multiple paths
                        $validPaths = @()
                        foreach ($p in $paths) {
                            if (Test-Path -LiteralPath $p) {
                                $validPaths += (Resolve-Path -LiteralPath $p).Path
                            } else {
                                Write-Host " [WARNING] La ruta no existe y sera omitida: $p" -ForegroundColor Yellow
                            }
                        }
                        if ($validPaths.Count -eq 0) {
                            Write-Host " [ERROR] Ninguna de las rutas especificadas existe." -ForegroundColor Red
                            Write-Host ''
                            Pause-Deduplicador -Message $T.Next
                            continue
                        }
                        $folderPath = $validPaths -join ';'
                    }
                }
            }

            # Validar que exista la carpeta (si es ruta única o no validada antes)
            if ($folderPath -notlike '*;*') {
                if (-not (Test-Path -LiteralPath $folderPath)) {
                    Write-Host " [ERROR] La carpeta especificada no existe: $folderPath" -ForegroundColor Red
                    Write-Host ''
                    Pause-Deduplicador -Message $T.Next
                    continue
                }
                $folderPath = (Resolve-Path -LiteralPath $folderPath).Path
            }

            # 4. Iniciar Servidor
            Write-Host $T.Starting -ForegroundColor Cyan
            $normalizedFolder = $folderPath -replace '\\', '/'
            
            # Detener antes si hay uno corriendo
            taskkill /f /t /fi "windowtitle eq DeduplicadorServer" 2>$null | Out-Null
            
            # Lanzar cmd con título e iniciar python usando la ruta absoluta detectada
            Start-Process cmd.exe -ArgumentList "/c title DeduplicadorServer && `"$($pythonCheck.Path)`" `"$scriptPath`" `"$normalizedFolder`"" -WindowStyle Minimized
            
            # Esperar a que el puerto se abra (puertos 8000-8010)
            $port = 8000
            $found = $false
            Write-Host " [>] Esperando a que el servidor web responda (puertos 8000-8010)..." -ForegroundColor Cyan
            for ($i = 0; $i -lt 15; $i++) {
                Start-Sleep -Milliseconds 500
                for ($p = 8000; $p -le 8010; $p++) {
                    $connection = $null
                    try {
                        $connection = New-Object System.Net.Sockets.TcpClient
                        $connection.Connect("127.0.0.1", $p)
                        if ($connection.Connected) {
                            $port = $p
                            $found = $true
                            $connection.Close()
                            break
                        }
                    } catch {
                        try {
                            $connection = New-Object System.Net.Sockets.TcpClient
                            $connection.Connect("localhost", $p)
                            if ($connection.Connected) {
                                $port = $p
                                $found = $true
                                $connection.Close()
                                break
                            }
                        } catch {}
                    } finally {
                        if ($connection) { $connection.Dispose() }
                    }
                }
                if ($found) { break }
            }

            if ($found) {
                Write-Host " [OK] Servidor detectado en puerto $port." -ForegroundColor Green
                Write-Host $T.Started -ForegroundColor Green
                try {
                    Start-Process "http://localhost:$port"
                } catch {
                    Start-Process "explorer.exe" "http://localhost:$port"
                }
            } else {
                Write-Host " [!] No se pudo confirmar que el servidor esté activo, abriendo puerto 8000 de todos modos..." -ForegroundColor Yellow
                try {
                    Start-Process "http://localhost:8000"
                } catch {
                    Start-Process "explorer.exe" "http://localhost:8000"
                }
            }
            Write-Host ''
            Pause-Deduplicador -Message $T.Next
        }
        elseif ($opt -eq '2') {
            Write-Host ''
            Write-Host $T.Stopping -ForegroundColor Cyan
            taskkill /f /t /fi "windowtitle eq DeduplicadorServer" 2>$null | Out-Null
            Write-Host $T.Stopped -ForegroundColor Green
            Write-Host ''
            Pause-Deduplicador -Message $T.Next
        }
    }
}
