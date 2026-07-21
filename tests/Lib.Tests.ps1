#Requires -Modules Pester
<#
.SYNOPSIS
    Pruebas unitarias (Pester v5) para el ToolKit compartido y para el
    mecanismo de inyeccion del ToolRunner.
    Ejecutar:  Invoke-Pester -Path tests/Lib.Tests.ps1
#>

Describe 'ToolKit - helpers de consola' {
    BeforeAll {
        $script:Root      = Split-Path -Parent $PSScriptRoot
        $script:ToolKit   = Join-Path $script:Root 'src/lib/ToolKit.ps1'
        . $script:ToolKit
    }

    It 'Write-AtlasHeader/Step/Success/Warn/Failure no lanzan' {
        { Write-AtlasHeader 'Prueba' } | Should -Not -Throw
        { Write-AtlasStep 'a' }        | Should -Not -Throw
        { Write-AtlasSuccess 'b' }     | Should -Not -Throw
        { Write-AtlasWarn 'c' }        | Should -Not -Throw
        { Write-AtlasFailure 'd' }     | Should -Not -Throw
    }
}

Describe 'ToolKit - ConvertTo-AtlasHtmlEncoded' {
    It 'escapa caracteres HTML peligrosos' {
        ConvertTo-AtlasHtmlEncoded '<b>&"x"' | Should -Be '&lt;b&gt;&amp;&quot;x&quot;'
    }
    It 'devuelve cadena vacia con entrada vacia' {
        ConvertTo-AtlasHtmlEncoded '' | Should -Be ''
    }
}

Describe 'ToolKit - ConvertTo-AtlasHtmlDocument' {
    It 'produce HTML con titulo escapado y cuerpo intacto' {
        $html = ConvertTo-AtlasHtmlDocument -Title '<Reporte>' -BodyHtml '<section>ok</section>'
        $html | Should -Match '<!DOCTYPE html>'
        $html | Should -Match '&lt;Reporte&gt;'
        $html | Should -Match '<section>ok</section>'
    }
    It 'incluye el color de acento y el subtitulo indicados' {
        $html = ConvertTo-AtlasHtmlDocument -Title 't' -BodyHtml 'x' -AccentColor '#abcdef' -Subtitle 'sub-x'
        $html | Should -Match '#abcdef'
        $html | Should -Match 'sub-x'
    }
}

Describe 'ToolKit - rutas de reporte' {
    BeforeAll {
        $script:OrigProfile = $env:USERPROFILE
        $script:TmpProfile  = Join-Path ([System.IO.Path]::GetTempPath()) ("atlas-test-" + [guid]::NewGuid().ToString('N').Substring(0,8))
        $env:USERPROFILE    = $script:TmpProfile
    }
    AfterAll {
        $env:USERPROFILE = $script:OrigProfile
        if (Test-Path -LiteralPath $script:TmpProfile) {
            Remove-Item -LiteralPath $script:TmpProfile -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    It 'Get-AtlasReportDir crea y devuelve la carpeta' {
        $dir = Get-AtlasReportDir
        Test-Path -LiteralPath $dir | Should -BeTrue
        $dir | Should -Match 'AtlasPC'
    }
    It 'Get-AtlasReportDir respeta SubFolder' {
        (Get-AtlasReportDir -SubFolder 'PrinterDoctor') | Should -Match 'PrinterDoctor'
    }
    It 'Get-AtlasReportPath compone nombre con timestamp y no crea archivo' {
        $path = Get-AtlasReportPath -Prefix 'printer-doctor' -Extension 'html'
        $path | Should -Match 'printer-doctor_\d{4}-\d{2}-\d{2}_\d{6}\.html$'
        Test-Path -LiteralPath $path | Should -BeFalse
    }
    It 'Get-AtlasReportPath normaliza extension con punto inicial' {
        (Get-AtlasReportPath -Prefix 'p' -Extension '.json') | Should -Match '[^.]\.json$'
    }
}

Describe 'ToolRunner - inyeccion del ToolKit en una tool aislada' {
    # Reproduce lo que hace ToolRunner: un proceso pwsh nuevo que recibe el
    # ToolKit inyectado y luego una "tool" que usa sus helpers. Prueba que los
    # helpers estan realmente disponibles en el contexto aislado de la tool.
    It 'una tool en proceso aislado puede usar los helpers inyectados' {
        $toolkitSource = Get-Content -Raw -LiteralPath $script:ToolKit
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("atlas-inject-" + [guid]::NewGuid().ToString('N').Substring(0,8) + '.ps1')
        $wrapper = @"
`$ErrorActionPreference = 'Continue'
try {
$toolkitSource
} catch { Write-Host "TOOLKIT-FAIL: `$(`$_.Exception.Message)" }

# 'tool' simulada que usa los helpers inyectados
function Invoke-FakeTool {
    Write-AtlasHeader 'Fake'
    Write-AtlasSuccess 'helper-ok'
    `$doc = ConvertTo-AtlasHtmlDocument -Title 'T' -BodyHtml '<p>hi</p>'
    if (`$doc -match '<!DOCTYPE html>') { Write-Host 'HTML-OK' }
}
Invoke-FakeTool
"@
        Set-Content -LiteralPath $tmp -Value $wrapper -Encoding UTF8
        try {
            $pwsh = (Get-Process -Id $PID).Path
            if (-not $pwsh) { $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source }
            if (-not $pwsh) { $pwsh = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
            $out  = & $pwsh -NoProfile -File $tmp 2>&1 | Out-String
            $out  | Should -Match 'helper-ok'
            $out  | Should -Match 'HTML-OK'
            $out  | Should -Not -Match 'TOOLKIT-FAIL'
        } finally {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}
