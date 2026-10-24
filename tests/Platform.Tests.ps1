#Requires -Version 5.1
#Requires -Modules Pester

Describe 'WPF local smoke tests' -Tag 'Windows' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        if ($env:OS -eq 'Windows_NT') {
            Add-Type -AssemblyName PresentationFramework
            # PS 5.1 needs a BOM when loading Unicode sources by file path.
            # Prepare local fixtures instead of modifying the real source files.
            foreach ($relative in @('src/lib/Strings.ps1', 'src/GUI/MainWindow.ps1')) {
                $fixture = Join-Path $TestDrive ([IO.Path]::GetFileName($relative))
                $source = [IO.File]::ReadAllText((Join-Path $script:RepoRoot $relative), [Text.Encoding]::UTF8)
                [IO.File]::WriteAllText($fixture, $source, [Text.UTF8Encoding]::new($true))
                . $fixture
            }
            # ConvertFrom-Json -AsHashtable is unavailable on Windows PowerShell 5.1.
            $script:Branding = @{
                brand = @{}; theme = @{}; window = @{}
            }
            $example = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'branding.example.json') -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($section in @('brand', 'theme', 'window')) {
                foreach ($property in $example.$section.PSObject.Properties) {
                    $script:Branding[$section][$property.Name] = $property.Value
                }
            }
            $script:Palette = Get-AtlasPalette -Branding $script:Branding
        }
    }

    It 'loads the expanded window in STA without showing it or starting tools' -Skip:($env:OS -ne 'Windows_NT') {
        [System.Threading.Thread]::CurrentThread.GetApartmentState().ToString() | Should -Be 'STA'
        $template = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'src/GUI/MainWindow.xaml') -Raw -Encoding UTF8
        $expanded = Expand-AtlasXaml -Xaml $template -Branding $script:Branding -Palette $script:Palette
        $expanded | Should -Not -Match '\{\{[A-Z_]+\}\}'
        $window = [Windows.Markup.XamlReader]::Parse($expanded)
        try {
            $window | Should -BeOfType ([System.Windows.Window])
            $window.FindName('StatusText') | Should -Not -BeNullOrEmpty
            $window.IsVisible | Should -BeFalse
        } finally {
            $window.Close()
        }
    }

    It 'loads every manifest card without attaching click handlers' -Skip:($env:OS -ne 'Windows_NT') {
        $manifest = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'config/tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($entry in $manifest.tools) {
            $tool = @{}
            foreach ($property in $entry.PSObject.Properties) { $tool[$property.Name] = $property.Value }
            $xaml = New-AtlasToolCard -Tool $tool -Branding $script:Branding -Palette $script:Palette
            $card = [Windows.Markup.XamlReader]::Parse($xaml)
            $card.FindName('BtnRun') | Should -Not -BeNullOrEmpty -Because $entry.id
        }
    }
    It 'renders an unavailable capability as disabled with an explanation' -Skip:($env:OS -ne 'Windows_NT') {
        $tool=@{id='fixture';name='Fixture';description='Capability test';category='software';_availability=[pscustomobject]@{Available=$false;Reason='Needs edition & module'}}
        $card=[Windows.Markup.XamlReader]::Parse((New-AtlasToolCard -Tool $tool -Branding $script:Branding -Palette $script:Palette))
        $card.FindName('BtnRun').IsEnabled | Should -BeFalse
        $card.FindName('BtnRun').ToolTip | Should -Be 'Needs edition & module'
    }
}
