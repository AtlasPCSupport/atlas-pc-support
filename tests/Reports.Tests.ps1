#Requires -Modules Pester
Describe 'Shareable report privacy and trace' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Release.ps1')
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Reports.ps1')
    }
    It 'redacts full product keys and BitLocker recovery passwords' {
        $text = 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE 123456-234567-345678-456789-567890-678901-789012-890123'
        $result = Protect-AtlasReportText $text
        $result | Should -Not -Match 'AAAAA|123456'
        $result | Should -Match '\[REDACTED\]'
    }
    It 'redacts network identifiers, user paths, SIDs and email' {
        $result=Protect-AtlasReportText '10.24.1.77 2606:4700:4700::1111 fe80::1234%12 AA:BB:CC:DD:EE:FF C:\Users\FixtureUser\file S-1-5-21-111-222-333-1001 fixture@example.test'
        $result|Should -Not -Match '10\.24|2606:|fe80:|AA:BB|FixtureUser|S-1-5-21|fixture@example'
    }
    It 'redacts all equally long explicit values and their HTML encoding' {
        $result=Protect-AtlasReportText 'SN123 SN456 A&amp;BCD' -SensitiveValues @('SN123','SN456','A&BCD')
        $result|Should -Not -Match 'SN123|SN456|BCD'
    }
    It 'preserves evidence fields and types while masking nested identity fields' {
        $input=[pscustomobject]@{Score=0;Evaluated=$false;SerialNumber='SN-FIXTURE';Items=@([pscustomobject]@{Owner='Other User';Document='private.pdf';State='NotEvaluated'});Missing=$null}
        $result=Protect-AtlasReportObject $input
        $result.Score|Should -Be 0;$result.Evaluated|Should -BeFalse
        $result.SerialNumber|Should -Be '[REDACTED]';$result.Items[0].Document|Should -Be '[REDACTED]'
        $result.Items[0].State|Should -Be 'NotEvaluated';$result.Missing|Should -BeNullOrEmpty
    }
    It 'writes valid redacted JSON with tool/version/commit/coverage metadata' {
        $path=Join-Path $TestDrive 'report.json'
        $script:AtlasVersion='fixture';$script:AtlasReleaseCommit='a'*40
        Write-AtlasShareableReport -Path $path -Content '{"Owner":"private-person","Score":0,"Evidence":"NotEvaluated"}' -Tool Fixture
        $result=[IO.File]::ReadAllText($path)|ConvertFrom-Json
        $result.Owner|Should -Be '[REDACTED]';$result.Score|Should -Be 0
        $result.Trace.Commit|Should -Be ('a'*40);$result.Trace.Tool|Should -Be Fixture
        $result.Trace.Coverage|Should -Match 'not a health'
    }
    It 'writes HTML without exposing encoded explicit identifiers' {
        $path=Join-Path $TestDrive 'report.html'
        Write-AtlasShareableReport -Path $path -Content '<html><body>A&amp;BCD</body></html>' -Tool Fixture -SensitiveValues 'A&BCD'
        $result=[IO.File]::ReadAllText($path)
        $result|Should -Not -Match 'BCD';$result|Should -Match '<body>\[REDACTED\]</body>'
        $result|Should -Match 'GeneratedUtc'
    }
}

Describe 'Persistent handover evidence' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Release.ps1')
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Reports.ps1')
        $script:Items=@('Recovery backup independently checked','Manual customer handover')
    }
    It 'starts every item as not verified' {
        $path=Join-Path $TestDrive 'new.json';$result=Get-AtlasHandoverChecklist -Path $path -Items $script:Items
        @($result.Items|Where-Object State -ne NotVerified).Count|Should -Be 0
        $result.HandoverId|Should -Match '^[a-f0-9]{32}$'
    }
    It 'persists manual state, evidence and timestamp across reloads with previous backup' {
        $path=Join-Path $TestDrive 'persist.json';$state=Get-AtlasHandoverChecklist -Path $path -Items $script:Items
        Save-AtlasHandoverChecklist -Path $path -Checklist $state
        $state.Items[0].State='ManualConfirmed';$state.Items[0].Evidence='Fixture external recovery check';$state.Items[0].CheckedUtc=[datetime]::UtcNow.ToString('o')
        Save-AtlasHandoverChecklist -Path $path -Checklist $state
        $loaded=Get-AtlasHandoverChecklist -Path $path -Items $script:Items
        $loaded.Items[0].State|Should -Be ManualConfirmed;$loaded.Items[1].State|Should -Be NotVerified
        Test-Path -LiteralPath ($path+'.previous')|Should -BeTrue
    }
    It 'does not overwrite valid evidence with an unsupported or incomplete confirmation' {
        $path=Join-Path $TestDrive 'guard.json';$state=Get-AtlasHandoverChecklist -Path $path -Items $script:Items
        Save-AtlasHandoverChecklist -Path $path -Checklist $state
        $before=[IO.File]::ReadAllText($path);$state.Items[0].State='ManualConfirmed'
        {Save-AtlasHandoverChecklist -Path $path -Checklist $state}|Should -Throw '*Invalid checklist*'
        [IO.File]::ReadAllText($path)|Should -Be $before
    }
    It 'rejects changed items instead of carrying confirmations onto a different checklist' {
        $path=Join-Path $TestDrive 'changed.json';$state=Get-AtlasHandoverChecklist -Path $path -Items $script:Items
        Save-AtlasHandoverChecklist -Path $path -Checklist $state
        {Get-AtlasHandoverChecklist -Path $path -Items @('Different requirement','Manual customer handover')}|Should -Throw
    }
}

Describe 'Report and license integration boundaries' {
    BeforeAll { $script:RepoRoot=Split-Path -Parent $PSScriptRoot }
    It 'contains no automatic clipboard copy or registry key-decoding fallback' {
        $text=[IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/tools/Invoke-ExtraerLicencias.ps1'))
        $text|Should -Not -Match '\|\s*clip\b|DigitalProductId|BackupProductKeyDefault'
        $text|Should -Match "-cne 'REVEAL'";$text|Should -Match "-ceq 'COPY'"
    }
    It 'does not extract cleartext WLAN passwords' {
        [IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/tools/Invoke-AuditoriaRouter.ps1'))|Should -Not -Match 'key=clear'
    }
    It 'does not offer an HTML check-all that fabricates completed handover evidence' {
        $text=[IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/tools/Invoke-EntregaPC.ps1'))
        $text|Should -Not -Match 'toggleAll\('
        $text|Should -Match 'Save-AtlasHandoverChecklist';$text|Should -Match "State='NotVerified'"
    }
}

Describe 'Bilingual tool cards and search' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/gui/MainWindow.ps1' 'Get-AtlasToolDisplay')
        . (Get-TestFunction $script:RepoRoot 'src/gui/MainWindow.ps1' 'Test-AtlasToolQuery')
        $script:Catalog=(Get-Content (Join-Path $script:RepoRoot 'config/tools.json') -Raw -Encoding UTF8|ConvertFrom-Json).tools
    }
    It 'has coherent English and Spanish labels for all 27 entries' {
        $script:Catalog.Count|Should -Be 27
        foreach($tool in $script:Catalog){$tool.nameEs|Should -Not -BeNullOrEmpty;$tool.descriptionEs|Should -Not -BeNullOrEmpty}
    }
    It 'renders Spanish explicitly and falls back to English for other languages' {
        $tool=$script:Catalog|Where-Object id -eq diagnostico-eventos
        (Get-AtlasToolDisplay -Tool $tool -Language es).Name|Should -Be 'Analizar eventos'
        (Get-AtlasToolDisplay -Tool $tool -Language fr).Name|Should -Be $tool.name
    }
    It 'finds either language without case or accent sensitivity' {
        $tool=$script:Catalog|Where-Object id -eq mod-personalizacion
        Test-AtlasToolQuery -Tool $tool -Query 'MENU INICIO'|Should -BeTrue
        Test-AtlasToolQuery -Tool $tool -Query 'windows settings'|Should -BeTrue
        Test-AtlasToolQuery -Tool $tool -Query 'impossible-token'|Should -BeFalse
    }
}
