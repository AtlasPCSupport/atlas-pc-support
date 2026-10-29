#Requires -Modules Pester

Describe 'Language preferences preserve existing configuration' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . ([scriptblock]::Create([IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/lib/Strings.ps1'),[Text.Encoding]::UTF8)))
        $script:LanguageLocalApp=$env:LOCALAPPDATA
    }
    BeforeEach {$env:LOCALAPPDATA=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))}
    AfterAll {$env:LOCALAPPDATA=$script:LanguageLocalApp}

    It 'reads a missing preference without creating directories' {
        Get-AtlasLanguagePref|Should -BeNullOrEmpty
        Test-Path -LiteralPath $env:LOCALAPPDATA|Should -BeFalse
    }
    It 'creates a supported preference and preserves unrelated nested settings' {
        Set-AtlasLanguagePref es|Should -BeTrue
        Get-AtlasLanguagePref|Should -Be es
        $path=Join-Path $env:LOCALAPPDATA 'AtlasPC/config.json'
        $config=[ordered]@{language='es';custom=@{level1=@{level2=@{level3=@{level4=@{level5=@{value='fixture'}}}}}};list=@('first','second')}
        [IO.File]::WriteAllText($path,($config|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
        Set-AtlasLanguagePref ro|Should -BeTrue
        $saved=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
        $saved.language|Should -Be ro
        $saved.custom.level1.level2.level3.level4.level5.value|Should -Be fixture
        @($saved.list)|Should -Be @('first','second')
    }
    It 'rejects unreadable JSON shapes without overwriting bytes: <Existing>' -ForEach @(
        @{Existing='{"language":'},@{Existing='[{"language":"es"}]'},@{Existing='null'}
    ) {
        $directory=Join-Path $env:LOCALAPPDATA 'AtlasPC';New-Item -ItemType Directory -Path $directory -Force|Out-Null
        $path=Join-Path $directory 'config.json';[IO.File]::WriteAllText($path,$Existing,[Text.UTF8Encoding]::new($true))
        $before=[Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
        Set-AtlasLanguagePref es|Should -BeFalse
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))|Should -Be $before
    }
    It 'reports a denied write as failure and preserves the existing configuration' -Skip:($env:OS -ne 'Windows_NT') {
        $directory=Join-Path $env:LOCALAPPDATA 'AtlasPC';New-Item -ItemType Directory -Path $directory -Force|Out-Null
        $path=Join-Path $directory 'config.json';[IO.File]::WriteAllText($path,'{"language":"en","custom":"fixture"}')
        $before=[Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
        $lock=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        try {Set-AtlasLanguagePref es -ErrorAction Continue 2>$null|Should -BeFalse} finally {$lock.Dispose()}
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))|Should -Be $before
        @(Get-ChildItem -LiteralPath $directory -Filter '*.tmp').Count|Should -Be 0
    }
    It 'rejects an unsupported language without changing existing preferences' {
        Set-AtlasLanguagePref es|Should -BeTrue
        $path=Join-Path $env:LOCALAPPDATA 'AtlasPC/config.json';$before=[IO.File]::ReadAllText($path)
        Set-AtlasLanguagePref 'unsupported'|Should -BeFalse
        [IO.File]::ReadAllText($path)|Should -Be $before
    }
}

Describe 'Language selection reports the persistence result' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . ([scriptblock]::Create([IO.File]::ReadAllText((Join-Path $script:RepoRoot 'src/lib/Strings.ps1'),[Text.Encoding]::UTF8)))
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        $ast=Get-TestAst $script:RepoRoot 'src/gui/MainWindow.ps1'
        $registration=$ast.Find({param($n)$n -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Member.Value -eq 'Add_SelectionChanged' -and $n.Expression.Extent.Text -eq '$langCombo'},$true)
        $handler=$registration.Arguments[0].ScriptBlock
        $source=$handler.Extent.Text
        # Substitute only the static dialog boundary; execute the real event body.
        foreach($dialog in $handler.FindAll({param($n)$n -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Expression.Extent.Text -eq '[System.Windows.MessageBox]'},$true)) {
            $source=$source.Replace($dialog.Extent.Text,("Show-TestLanguageDialog -Message " + $dialog.Arguments[0].Extent.Text + ' -Icon ' + $dialog.Arguments[3].Extent.Text))
        }
        $script:LanguageSelection=[scriptblock]::Create($source.Substring(1,$source.Length-2))
        function Show-TestLanguageDialog {param($Message,$Icon)$script:LanguageDialogs.Add([pscustomobject]@{Message=$Message;Icon=$Icon})}
        function Write-AtlasLog {param($Message,$Level,$Tool)}
    }
    It 'uses a warning and restores selection only on save failure: <Save>' -ForEach @(@{Save=$false},@{Save=$true}) {
        $script:AtlasCurrentLang='en';$script:LangComboReady=$true;$script:Branding=@{brand=@{shortName='Fixture'}}
        $script:LanguageDialogs=[Collections.Generic.List[object]]::new()
        $items=@([pscustomobject]@{Tag='en'},[pscustomobject]@{Tag='es'})
        $control=[pscustomobject]@{Items=$items;SelectedItem=$items[1]}
        Mock Set-AtlasLanguagePref {$Save};Mock Write-AtlasLog {}
        & $script:LanguageSelection $control $null
        Should -Invoke Set-AtlasLanguagePref -Times 1 -Exactly -ParameterFilter {$Language -eq 'es'}
        $script:LanguageDialogs.Count|Should -Be 1
        $script:LangComboReady|Should -BeTrue
        if($Save) {
            $control.SelectedItem.Tag|Should -Be es
            $script:LanguageDialogs[0].Icon|Should -Be Information
            $script:LanguageDialogs[0].Message|Should -Be $script:AtlasStringsDict['es']['language.restartRequired']
        } else {
            $control.SelectedItem.Tag|Should -Be en
            $script:LanguageDialogs[0].Icon|Should -Be Warning
            $script:LanguageDialogs[0].Message|Should -Be $script:AtlasStringsDict['en']['language.saveFailed']
            Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter {$Level -eq 'WARN'}
        }
    }
}
