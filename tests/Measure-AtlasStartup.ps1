[CmdletBinding()]
param([Parameter(Mandatory)][string]$RepoRoot,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$script:StartupWatch=[Diagnostics.Stopwatch]::StartNew()
$source=[IO.File]::ReadAllText((Join-Path $RepoRoot 'launcher.ps1'),[Text.Encoding]::UTF8)
$boundary=$source.IndexOf('# Legacy get.ps1 invokes launcher.ps1')
if($boundary -lt 0){throw 'Launcher definition boundary not found.'}
. ([scriptblock]::Create($source.Substring(0,$boundary)))
$script:AtlasRoot=$RepoRoot
$manifestHash=(Get-FileHash -LiteralPath (Join-Path $RepoRoot 'release-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant()
Test-AtlasRelease -Directory $RepoRoot -ExpectedManifestSha256 $manifestHash|Out-Null
$script:VerifiedAtMs=$script:StartupWatch.Elapsed.TotalMilliseconds
$show=(Get-Command Show-AtlasWindow -CommandType Function).Definition
$instrument=@'
    $window.ShowActivated=$false
    $window.Add_ContentRendered({
        param($sender,$eventArgs)
        $script:FirstPaintMs=$script:StartupWatch.Elapsed.TotalMilliseconds
        [void]$sender.Dispatcher.BeginInvoke([Action]{
            $script:UsableMs=$script:StartupWatch.Elapsed.TotalMilliseconds
            $script:MainWindow.Close()
        },[Windows.Threading.DispatcherPriority]::ApplicationIdle)
    })
    [void]$window.ShowDialog()
'@
if(-not $show.Contains('[void]$window.ShowDialog()')){throw 'Window measurement hook not found.'}
$show=$show.Replace('[void]$window.ShowDialog()',$instrument)
. ([scriptblock]::Create('function Show-AtlasWindow {'+$show+'}'))
$script:AtlasToolHashes=(ConvertFrom-AtlasJson $script:AtlasToolHashesJson).files
$branding=Get-AtlasBranding
$savedLang=Get-AtlasLanguagePref
if($savedLang){Set-AtlasLanguage $savedLang|Out-Null}else{Set-AtlasLanguage $branding.language|Out-Null}
Initialize-AtlasLog|Out-Null
Initialize-AtlasPS7|Out-Null
$script:BeforeWindowMs=$script:StartupWatch.Elapsed.TotalMilliseconds
$tools=@((ConvertFrom-AtlasJson $script:AtlasToolsManifest).tools)
Show-AtlasWindow -Branding $branding -Tools $tools -XamlTemplate $script:AtlasXamlTemplate
if(-not $script:FirstPaintMs -or -not $script:UsableMs){throw 'No actual render/idle observation.'}
$result=[ordered]@{Version=$script:AtlasVersion;Runtime=$PSVersionTable.PSVersion.ToString();VerifiedAtMs=$script:VerifiedAtMs;BeforeWindowMs=$script:BeforeWindowMs;FirstPaintMs=$script:FirstPaintMs;DispatcherIdleMs=$script:UsableMs;ToolsLaunched=0;Scope='Local verified code initialization; new process, OS cache not flushed; excludes network/bootstrap download'}
$result|ConvertTo-Json|Set-Content -LiteralPath $Output -Encoding UTF8
$result|ConvertTo-Json
