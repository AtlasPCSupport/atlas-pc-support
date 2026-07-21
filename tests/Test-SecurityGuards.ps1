#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Security regression guards for high-risk bootstrap/runtime patterns.

.DESCRIPTION
    This test intentionally checks only a narrow set of high-signal controls:
      - No Invoke-Expression/iex command invocation in production scripts.
      - No -EncodedCommand parameter token in production scripts.
      - onboarding/install.bat must not execute remote code via iex and must
        verify SHA256 before executing installer.
      - Runtime privileged wrappers must use secure-run path, not %TEMP%\AtlasPC.

    Exit code 0 = all guards pass, 1 = one or more guards failed.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'
$script:FailCount = 0

function Write-GuardOk {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-GuardFail {
    param([string]$Message)
    $script:FailCount++
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Get-PsFilesForGuard {
    param([string]$Root)
    $src = Join-Path $Root 'src'
    $files = @()
    if (Test-Path -LiteralPath $src) {
        $files += Get-ChildItem -LiteralPath $src -Recurse -File -Filter '*.ps1' -ErrorAction Stop
    }
    $rootGet = Join-Path $Root 'get.ps1'
    if (Test-Path -LiteralPath $rootGet) {
        $files += Get-Item -LiteralPath $rootGet -ErrorAction Stop
    }
    return @($files | Sort-Object -Property FullName -Unique)
}

function Parse-PsFile {
    param([Parameter(Mandatory)][string]$Path)
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    return @{
        Ast    = $ast
        Tokens = @($tokens)
        Errors = @($errors)
    }
}

function Test-NoInvokeExpression {
    param([System.IO.FileInfo[]]$Files)
    $hits = @()
    foreach ($f in $Files) {
        $parsed = Parse-PsFile -Path $f.FullName
        if ($parsed.Errors.Count -gt 0) {
            Write-GuardFail "Parse failed in $($f.FullName); cannot validate Invoke-Expression guard."
            continue
        }
        $cmds = $parsed.Ast.FindAll({
                param($n)
                if (-not ($n -is [System.Management.Automation.Language.CommandAst])) { return $false }
                $name = $n.GetCommandName()
                return ($name -and ($name -ieq 'Invoke-Expression' -or $name -ieq 'iex'))
            }, $true)
        foreach ($c in $cmds) {
            $hits += [pscustomobject]@{
                Path = $f.FullName
                Line = $c.Extent.StartLineNumber
                Name = $c.GetCommandName()
            }
        }
    }
    if ($hits.Count -gt 0) {
        foreach ($h in $hits) {
            Write-GuardFail "Invoke-Expression blocked: $($h.Name) at $($h.Path):$($h.Line)"
        }
    } else {
        Write-GuardOk "No Invoke-Expression/iex command usage found in production scripts."
    }
}

function Test-NoEncodedCommandToken {
    param([System.IO.FileInfo[]]$Files)
    $hits = @()
    foreach ($f in $Files) {
        $parsed = Parse-PsFile -Path $f.FullName
        if ($parsed.Errors.Count -gt 0) { continue }
        foreach ($t in $parsed.Tokens) {
            if ($t -and $t.Kind -eq 'Parameter' -and $t.Text -and $t.Text.ToLowerInvariant() -eq '-encodedcommand') {
                $hits += [pscustomobject]@{
                    Path = $f.FullName
                    Line = $t.Extent.StartLineNumber
                }
            }
        }
    }
    if ($hits.Count -gt 0) {
        foreach ($h in $hits) {
            Write-GuardFail "EncodedCommand blocked at $($h.Path):$($h.Line)"
        }
    } else {
        Write-GuardOk "No -EncodedCommand parameter token found in production scripts."
    }
}

function Test-OnboardingInstallBat {
    param([string]$Root)
    $path = Join-Path $Root 'onboarding\install.bat'
    if (-not (Test-Path -LiteralPath $path)) {
        Write-GuardFail "Missing onboarding/install.bat"
        return
    }
    $text = Get-Content -Raw -LiteralPath $path -Encoding UTF8
    if ($text -match '(?i)\biex\s*\(\s*iwr') {
        Write-GuardFail "onboarding/install.bat contains direct iex(iwr...) pattern."
    } else {
        Write-GuardOk "onboarding/install.bat does not use direct iex(iwr...) execution."
    }

    if ($text -notmatch '(?i)Get-FileHash') {
        Write-GuardFail "onboarding/install.bat does not verify SHA-256 before execution."
    } else {
        Write-GuardOk "onboarding/install.bat includes SHA-256 verification."
    }
}

function Test-SecureRunPath {
    param([string]$Root)
    $adminPath = Join-Path $Root 'src\lib\Admin.ps1'
    $runnerPath = Join-Path $Root 'src\lib\ToolRunner.ps1'
    foreach ($p in @($adminPath, $runnerPath)) {
        if (-not (Test-Path -LiteralPath $p)) {
            Write-GuardFail "Missing required file for secure-run guard: $p"
            continue
        }
    }

    $adminText = Get-Content -Raw -LiteralPath $adminPath -Encoding UTF8
    $runnerText = Get-Content -Raw -LiteralPath $runnerPath -Encoding UTF8

    if ($adminText -notmatch 'AtlasPC\\secure-run') {
        Write-GuardFail "Admin runner is not using AtlasPC\\secure-run path."
    }
    if ($runnerText -notmatch 'AtlasPC\\secure-run') {
        Write-GuardFail "ToolRunner is not using AtlasPC\\secure-run path."
    }

    if ($adminText -match '(?i)Join-Path\s+\$env:TEMP\s+[''"]AtlasPC[''"]') {
        Write-GuardFail "Admin runner still writes wrappers to %TEMP%\\AtlasPC."
    }
    if ($runnerText -match '(?i)Join-Path\s+\$env:TEMP\s+[''"]AtlasPC[''"]') {
        Write-GuardFail "ToolRunner still writes wrappers to %TEMP%\\AtlasPC."
    }

    if ($script:FailCount -eq 0) {
        Write-GuardOk "Runtime wrappers use secure-run path (not %TEMP%\\AtlasPC)."
    }
}

$files = Get-PsFilesForGuard -Root $RepoRoot
if ($files.Count -eq 0) {
    Write-GuardFail "No production PowerShell files found for guard checks."
}

Test-NoInvokeExpression -Files $files
Test-NoEncodedCommandToken -Files $files
Test-OnboardingInstallBat -Root $RepoRoot
Test-SecureRunPath -Root $RepoRoot

Write-Host ""
if ($script:FailCount -gt 0) {
    Write-Host "=== SECURITY GUARDS: $($script:FailCount) failure(s) ===" -ForegroundColor Red
    exit 1
}

Write-Host "=== SECURITY GUARDS: ALL GOOD ===" -ForegroundColor Green
exit 0
