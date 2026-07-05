@echo off
setlocal
chcp 65001 >nul
title Atlas PC Support - Instalador de Acceso Remoto

REM ============================================================
REM Atlas PC Support - RustDesk onboarding installer (.bat wrapper)
REM
REM This file is a thin wrapper. The real PowerShell installer
REM lives in the PRIVATE handoff repo and is served via a
REM Cloudflare Worker that injects a GitHub PAT.
REM
REM Public URL (what clients hit):
REM   https://toolspanel.atlaspcsupport.com/install.ps1
REM
REM Source of this .bat:
REM   https://github.com/mikepchelper-spec/atlas-pc-support
REM
REM Usage (technician-side, during a one-shot AnyDesk session):
REM   1. Open the client's web browser.
REM   2. Visit:
REM        https://toolspanel.atlaspcsupport.com/install.bat
REM   3. Save and double-click the file.
REM   4. Accept the Windows SmartScreen warning ("More info" -> "Run anyway").
REM   5. Accept UAC.
REM   6. Wait ~60-90 seconds. A window will pop up with the
REM      ID and password generated for this PC.
REM   7. Copy them into Vaultwarden + RustDesk API Admin.
REM ============================================================

REM ---- Strip Mark of the Web (MotW) before self-elevation ----
REM When this .bat is downloaded from a browser, Windows attaches an
REM Alternate Data Stream (Zone.Identifier) that triggers a SmartScreen
REM "Open File - Security Warning" dialog every time it is launched.
REM The user already accepted that warning when they double-clicked the
REM file. When we self-elevate via Start-Process -Verb RunAs below, the
REM new admin instance re-checks MotW and shows the SAME dialog AGAIN,
REM which is confusing for non-technical clients.
REM Unblock-File removes the Zone.Identifier ADS so the post-elevation
REM launch does not re-prompt. The first prompt (before this line runs)
REM is unavoidable since it precedes any code execution.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -LiteralPath '%~f0'" >nul 2>&1

REM ---- Self-elevate to administrator -------------------------
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Este instalador requiere permisos de administrador.
    echo Solicitando elevacion...
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ================================================================
echo   ATLAS PC SUPPORT - Instalador de Acceso Remoto (RustDesk)
echo ================================================================
echo.
echo   Este proceso tarda 1-2 minutos. No cierre esta ventana.
echo.
echo   Pasos:
echo     [1/4] Descargando la ultima version de RustDesk
echo     [2/4] Instalando como servicio de Windows
echo     [3/4] Aplicando configuracion del servidor Atlas
echo     [4/4] Generando contrasena unica para esta PC
echo.

REM ---- Run the PowerShell installer (served by CF Worker) -----
REM Hardening: NEVER execute remote code directly from memory (iex+iwr).
REM We now:
REM   1) Download install.ps1.sha256
REM   2) Download install.ps1 to a .download file
REM   3) Verify SHA-256
REM   4) Execute local verified file via -File
REM The Worker fetches install-rustdesk.ps1 (+ .sha256) from the PRIVATE repo
REM (atlas-pc-support-handoff) using a GitHub PAT stored as a Worker secret.
REM See docs/CLOUDFLARE-DOMAIN.md.
set "PS_URL=https://toolspanel.atlaspcsupport.com/install.ps1"
set "PS_SHA_URL=https://toolspanel.atlaspcsupport.com/install.ps1.sha256"
set "PS_SCRIPT_NAME=install-rustdesk.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$url='%PS_URL%'; $shaUrl='%PS_SHA_URL%';" ^
  "$root=Join-Path $env:LOCALAPPDATA 'AtlasPC\onboarding'; if(-not (Test-Path -LiteralPath $root)){New-Item -ItemType Directory -Path $root -Force | Out-Null};" ^
  "$tmp=Join-Path $root ('%PS_SCRIPT_NAME%.download'); $dst=Join-Path $root '%PS_SCRIPT_NAME%';" ^
  "Write-Host '  [>] Descargando checksum remoto...' -ForegroundColor Cyan;" ^
  "$shaRaw=(Invoke-WebRequest -Uri ($shaUrl+'?v='+[guid]::NewGuid().ToString('N')) -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop).Content;" ^
  "$expected=((($shaRaw -split '\s+') | Where-Object { $_ })[0]).ToLowerInvariant();" ^
  "if(-not $expected -or $expected -notmatch '^[a-f0-9]{64}$'){throw 'Checksum remoto invalido o no disponible.'};" ^
  "Write-Host '  [>] Descargando instalador...' -ForegroundColor Cyan;" ^
  "Invoke-WebRequest -Uri ($url+'?v='+[guid]::NewGuid().ToString('N')) -OutFile $tmp -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop;" ^
  "$actual=(Get-FileHash -LiteralPath $tmp -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant();" ^
  "if($actual -ne $expected){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;throw ('Integridad fallida. Esperado SHA256='+$expected+', obtenido='+$actual)};" ^
  "Move-Item -LiteralPath $tmp -Destination $dst -Force; Unblock-File -LiteralPath $dst -ErrorAction SilentlyContinue;" ^
  "Write-Host ('  [OK] SHA-256: ' + $actual) -ForegroundColor Green;" ^
  "& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dst;" ^
  "if($global:LASTEXITCODE -ne $null){exit $global:LASTEXITCODE}else{exit 0}"

set "RC=%errorlevel%"
echo.
if %RC% neq 0 (
    echo.
    echo ================================================================
    echo   ERROR
    echo ================================================================
    echo   La instalacion fallo con codigo %RC%.
    echo   Por favor, contacte con su tecnico de Atlas PC Support.
    echo.
)
echo.
echo Pulse cualquier tecla para cerrar esta ventana...
pause >nul
endlocal & exit /b %RC%
