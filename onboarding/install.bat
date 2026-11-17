@echo off
setlocal
chcp 65001 >nul
title Atlas PC Support - Acceso remoto
REM Paths are transported as data, never interpolated into PowerShell code.
set "ATLAS_ONBOARDING_SELF=%~f0"
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -Command "try {$p=Start-Process -FilePath $env:ATLAS_ONBOARDING_SELF -Verb RunAs -Wait -PassThru -ErrorAction Stop; exit $p.ExitCode} catch {Write-Error 'Elevation cancelled or unavailable'; exit 1}"
    exit /b
)
echo Atlas - descarga verificada. La politica de Windows puede bloquear la ejecucion.
echo No cierre esta ventana. Un bloqueo requiere revision del tecnico.
REM BEGIN VERIFIED ONBOARDING - parsed by regression tests; no remote evaluation.
powershell.exe -NoProfile -Command ^
  "function Assert-OnboardingDirectory {" ^
  "param([string]$Path);" ^
  "$item=Get-Item -LiteralPath $Path -Force -ErrorAction Stop;" ^
  "if(-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Redirected onboarding directory refused.'};" ^
  "$parent=$item.Parent;" ^
  "while($parent){if($parent.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected onboarding ancestor refused.'};$parent=$parent.Parent};" ^
  "$acl=Get-Acl -LiteralPath $Path -ErrorAction Stop;" ^
  "$trusted=@('S-1-5-18','S-1-5-32-544',([Security.Principal.NTAccount]'NT SERVICE\TrustedInstaller').Translate([Security.Principal.SecurityIdentifier]).Value);" ^
  "if($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -notin $trusted){throw 'Untrusted directory owner.'};" ^
  "$write=[Security.AccessControl.FileSystemRights]'Write,Delete,DeleteSubdirectoriesAndFiles,ChangePermissions,TakeOwnership';" ^
  "foreach($rule in $acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier])){" ^
  "if($rule.AccessControlType -eq 'Allow' -and -not ($rule.PropagationFlags -band [Security.AccessControl.PropagationFlags]::InheritOnly) -and ($rule.FileSystemRights -band $write) -and $rule.IdentityReference.Value -notin $trusted){throw 'Directory is writable by an untrusted identity.'};" ^
  "};" ^
  "};" ^
  "function New-OnboardingAttempt {" ^
  "param([string]$Base=[Environment]::GetFolderPath('ProgramFiles'));" ^
  "Assert-OnboardingDirectory $base;" ^
  "foreach($part in @('AtlasPC','onboarding')){" ^
  "$base=Join-Path $base $part;" ^
  "if(-not (Test-Path -LiteralPath $base)){New-Item -ItemType Directory -Path $base -ErrorAction Stop|Out-Null};" ^
  "Assert-OnboardingDirectory $base;" ^
  "};" ^
  "$path=Join-Path $base ([guid]::NewGuid().ToString('N'));" ^
  "New-Item -ItemType Directory -Path $path -ErrorAction Stop|Out-Null;" ^
  "$acl=[Security.AccessControl.DirectorySecurity]::new();" ^
  "$acl.SetAccessRuleProtection($true,$false);" ^
  "$acl.SetOwner([Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'));" ^
  "foreach($sid in @('S-1-5-18','S-1-5-32-544')){" ^
  "$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($sid),'FullControl','ContainerInherit,ObjectInherit','None','Allow'));" ^
  "};" ^
  "Set-Acl -LiteralPath $path -AclObject $acl -ErrorAction Stop;" ^
  "Assert-OnboardingDirectory $path;" ^
  "return $path;" ^
  "};" ^
  "function Invoke-OnboardingFile {" ^
  "param([string]$Path);" ^
  "& (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -NoProfile -File $Path;" ^
  "if($LASTEXITCODE -ne 0){throw ('Installer failed or execution policy blocked it; exit '+$LASTEXITCODE)};" ^
  "};" ^
  "function Invoke-VerifiedOnboarding {" ^
  "param([string]$Directory);" ^
  "Assert-OnboardingDirectory $Directory;" ^
  "$lock=$null;$file=$null;" ^
  "try {" ^
  "$lock=[IO.File]::Open((Join-Path $Directory '.run.lock'),'CreateNew','ReadWrite','None');" ^
  "$tmp=Join-Path $Directory 'install.download';" ^
  "$dst=Join-Path $Directory 'install-rustdesk.ps1';" ^
  "$base='https://toolspanel.atlaspcsupport.com';" ^
  "$checksum=Invoke-WebRequest -Uri ($base+'/install.ps1.sha256') -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop;" ^
  "$expected=(([string]$checksum.Content -split '\s+')[0]).ToLowerInvariant();" ^
  "if($expected -notmatch '^[a-f0-9]{64}$'){throw 'Invalid checksum.'};" ^
  "Invoke-WebRequest -Uri ($base+'/install.ps1') -OutFile $tmp -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop;" ^
  "if((Get-FileHash -LiteralPath $tmp -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() -cne $expected){throw 'Installer integrity failed; nothing executed.'};" ^
  "Move-Item -LiteralPath $tmp -Destination $dst -ErrorAction Stop;" ^
  "$file=[IO.File]::Open($dst,'Open','Read','Read');" ^
  "Write-Host ('Verified installer. Attempt: '+$Directory);" ^
  "Invoke-OnboardingFile $dst;" ^
  "} finally {" ^
  "if($file){$file.Dispose()};" ^
  "if($lock){$lock.Dispose()};" ^
  "};" ^
  "};" ^
  "$ErrorActionPreference='Stop';" ^
  "try {" ^
  "$id=[Security.Principal.WindowsIdentity]::GetCurrent();" ^
  "if(-not ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Administrator rights required.'};" ^
  "Invoke-VerifiedOnboarding (New-OnboardingAttempt);" ^
  "exit 0;" ^
  "} catch {Write-Error ('Onboarding stopped: '+$_.Exception.Message);exit 1};"
set "RC=%errorlevel%"
if not "%RC%"=="0" echo Instalacion detenida. Revise el bloqueo y el intento; no cambie la proteccion del equipo.
pause
endlocal & exit /b %RC%
