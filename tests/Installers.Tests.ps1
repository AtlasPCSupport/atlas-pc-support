#Requires -Version 5.1
#Requires -Modules Pester

Describe 'A01 installer verification regressions' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        function Start-Process { [CmdletBinding()] param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru) throw 'Real process blocked' }
        function Invoke-AtlasNativeProcess { [CmdletBinding()] param($FilePath,$Arguments,$ArgumentList,$TimeoutSeconds,$SuccessCodes) throw 'Real native process blocked' }
        function Invoke-WebRequest { [CmdletBinding()] param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec) throw 'Network blocked' }
        function Get-AuthenticodeSignature { [CmdletBinding()] param($FilePath) throw 'Real signature inspection blocked' }
        function _Write-AtlasStepCompat { param($Message) }
        function _Write-AtlasOkCompat { param($Message) }
        function _Get-PS7Path { 'mock-pwsh.exe' }
        function Get-AtlasPowerShellVersion {param($Path)throw 'Real runtime execution blocked'}
        function Register-UsbInstallerFiles {param($Key,$Directory,$SingleFile)throw 'Fixture registration required'}
        function Write-Centered { param($Text, $Color) }
        function Format-Size { param($Size) 'test size' }
        function Invoke-ExternalProcessWithTimeout { param($FilePath,$ArgumentList,$TimeoutSec) throw 'Real extractor blocked' }
        $script:AtlasDependencyCatalog = [IO.File]::ReadAllText((Join-Path $script:RepoRoot 'config/dependencies.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($name in @('Assert-AtlasInstaller', 'Get-AtlasReleaseFileHash', 'Get-AtlasDependencyDefinition')) {
            . (Get-TestFunction $script:RepoRoot 'src/lib/ToolKit.ps1' $name)
        }
        . (Join-Path $script:RepoRoot 'src/lib/PS7.ps1')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-ActualizarPowerShell.ps1' '_Install-PS7')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PrepararUSB.ps1' 'Download-FastCopy')
        . (Get-TestFunction $script:RepoRoot 'src/tools/Invoke-PrepararUSB.ps1' 'Download-PS7')
    }
    BeforeEach {
        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{ State='Correct'; ExitCode=0 } }
        Mock Get-AtlasPS7Path { 'mock-pwsh.exe' }
        Mock Get-AtlasPowerShellVersion {[version]'7.6.9'}
        Mock Register-UsbInstallerFiles {}
        $script:AtlasUsbAttemptFailures=@{}
        Mock Invoke-WebRequest { throw 'Network blocked' }
        Mock Get-AuthenticodeSignature {
            [pscustomobject]@{ Status = 'Valid'; SignerCertificate = [pscustomobject]@{ Subject = 'CN=Microsoft Corporation, O=Microsoft Corporation, C=US' } }
        }
        Mock Invoke-ExternalProcessWithTimeout { throw 'Extractor must not run with invalid content' }
        $script:Msi = Join-Path $TestDrive ('fixture with spaces-' + [guid]::NewGuid().ToString('N') + '.msi')
        Set-Content -LiteralPath $script:Msi -Value 'Not an installer' -Encoding ASCII
        $script:Hash = (Get-FileHash -LiteralPath $script:Msi -Algorithm SHA256).Hash.ToLowerInvariant()
        $script:AtlasDependencyCatalog.PowerShell7.DownloadSha256 = $script:Hash
        $script:L = @{ UsingLocalMsi='{0}'; Installing='install'; InstallOK='{0}'; DownloadFailed='{0}'; MsiExitCode='{0}'; Downloading='{0}'; FCInstOk='{0}'; FCDLFail='{0}'; PS7Exists='{0}'; PS7Fail='{0}' }
    }

    It 'rejects an unsigned MSI before starting the standalone updater' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        Mock Get-AuthenticodeSignature { [pscustomobject]@{ Status='NotSigned'; SignerCertificate=$null } }
        { _Install-PS7 -OfflineSource $script:Msi -L $script:L -Version '7.6.9' -MsiName 'fixture.msi' } | Should -Throw '*signature*'
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Get-AuthenticodeSignature -Times 1 -Exactly
    }
    It 'refuses offline installation without a required expected hash' {
        $script:AtlasDependencyCatalog.PowerShell7.DownloadSha256 = $null
        { Install-AtlasPS7 -OfflineSource $script:Msi } | Should -Throw '*SHA-256*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'rejects an empty or malformed expected digest' -ForEach @(@{HashValue=''},@{HashValue='invalid'}) {
        { Assert-AtlasInstaller -Path $script:Msi -ExpectedSha256 $HashValue } | Should -Throw '*SHA-256*'
    }
    It 'rejects a mismatch even if a signature would be valid' {
        { Assert-AtlasInstaller -Path $script:Msi -ExpectedSha256 ('0'*64) -MicrosoftSignature } | Should -Throw '*mismatch*'
        Should -Invoke Get-AuthenticodeSignature -Times 0 -Exactly
    }
    It 'rejects a valid certificate belonging to another publisher' {
        Mock Get-AuthenticodeSignature { [pscustomobject]@{ Status='Valid'; SignerCertificate=[pscustomobject]@{ Subject='O=Example Corporation, CN=Microsoft tool' } } }
        { Assert-AtlasInstaller -Path $script:Msi -ExpectedSha256 $script:Hash -MicrosoftSignature } | Should -Throw '*Microsoft*'
    }
    It 'rejects a signature API failure' {
        Mock Get-AuthenticodeSignature { throw 'Trust unavailable' }
        { Assert-AtlasInstaller -Path $script:Msi -ExpectedSha256 $script:Hash -MicrosoftSignature } | Should -Throw '*Trust unavailable*'
    }
    It 'accepts a matching digest and valid Microsoft signature' {
        { Assert-AtlasInstaller -Path $script:Msi -ExpectedSha256 $script:Hash -MicrosoftSignature } | Should -Not -Throw
    }
    It 'launches a verified local MSI with a quoted path and checks its native exit' {
        # A sidecar is not the authority; the verified release already pins bytes.
        Set-Content -LiteralPath "$script:Msi.sha256" -Value ('0'*64)
        _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi' | Should -Be 'mock-pwsh.exe'
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'msiexec.exe' -and $Arguments.Contains(('"'+$script:Msi+'"')) -and $TimeoutSeconds -eq 1800 }
    }
    It 'does not swallow a mismatch in the standalone updater' {
        Set-Content -LiteralPath $script:Msi -Value 'Modified installer' -Encoding ASCII
        Set-Content -LiteralPath "$script:Msi.sha256" -Value (Get-FileHash $script:Msi -Algorithm SHA256).Hash
        { _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi' } | Should -Throw '*mismatch*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'rejects a nonzero MSI result after verification' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{ State='Failed'; ExitCode=1603 } }
        { _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi' } | Should -Throw '*1603*'
    }
    It 'rejects an offline library MSI with a mismatching digest' {
        Set-Content -LiteralPath $script:Msi -Value 'Modified installer' -Encoding ASCII
        Set-Content -LiteralPath "$script:Msi.sha256" -Value (Get-FileHash $script:Msi -Algorithm SHA256).Hash
        { Install-AtlasPS7 -OfflineSource $script:Msi } | Should -Throw '*SHA-256*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'parses an exact filename in the official checksum format' {
        Mock Invoke-WebRequest { [pscustomobject]@{Content=('1'*64)+' *other.msi'+"`n"+$script:Hash+'  fixture.msi'} }
        Get-AtlasReleaseFileHash -HashesUrl 'https://example.invalid/hashes' -FileName 'fixture.msi' | Should -Be $script:Hash
    }
    It 'rejects ambiguous checksum entries' {
        Mock Invoke-WebRequest { [pscustomobject]@{Content=$script:Hash+'  fixture.msi'+"`n"+$script:Hash+'  fixture.msi'} }
        { Get-AtlasReleaseFileHash -HashesUrl 'https://example.invalid/hashes' -FileName 'fixture.msi' } | Should -Throw '*ambiguous*'
    }
    It 'reads a UTF-16 checksum asset returned as bytes' {
        Mock Invoke-WebRequest {
            $encoding=[Text.UnicodeEncoding]::new($false,$true)
            [pscustomobject]@{Content=[byte[]]($encoding.GetPreamble()+$encoding.GetBytes($script:Hash+' *fixture.msi'))}
        }
        Get-AtlasReleaseFileHash -HashesUrl 'https://example.invalid/hashes' -FileName 'fixture.msi' | Should -Be $script:Hash
    }
    It 'does not accept a partial filename match' {
        Mock Invoke-WebRequest { [pscustomobject]@{Content=$script:Hash+'  fixture.msi.extra'} }
        { Get-AtlasReleaseFileHash -HashesUrl 'https://example.invalid/hashes' -FileName 'fixture.msi' } | Should -Throw
    }
    It 'does not extract a USB FastCopy download that only passes the size threshold' {
        $apps = Join-Path $TestDrive 'apps'
        New-Item -ItemType Directory -Path $apps | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $apps 'FastCopy_installer.exe'), [byte[]]::new(210KB))
        Mock Invoke-WebRequest { }
        $script:FASTCOPY_URL = 'https://example.invalid/fixture'
        Download-FastCopy -AppsDir $apps | Should -BeFalse
        Should -Invoke Invoke-ExternalProcessWithTimeout -Times 0 -Exactly
    }
    It 'verifies a cached USB MSI and writes its required sidecar' {
        $script:PS7_VERSION='test'
        $deps=Join-Path $TestDrive 'deps'
        New-Item -ItemType Directory -Path $deps | Out-Null
        $file=Join-Path $deps 'PowerShell-test-win-x64.msi'
        Copy-Item -LiteralPath $script:Msi -Destination $file
        Download-PS7 -DepsDir $deps | Should -BeTrue
        (Get-Content -LiteralPath "$file.sha256" -Raw).Trim() | Should -Be $script:Hash
        Should -Invoke Get-AuthenticodeSignature -Times 1 -Exactly
    }
    It 'does not convert a timeout to a completed MSI installation' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='TimedOut';ExitCode=0} }
        {_Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi'}|Should -Throw '*TimedOut*'
    }
    It 'accepts a successful MSI reboot-required code distinctly' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        Mock Invoke-AtlasNativeProcess { [pscustomobject]@{State='Correct';ExitCode=3010} }
        _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi'|Should -Be 'mock-pwsh.exe'
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -match 'restart' }
    }
    It 'blocks a newer installed runtime before download or MSI execution in both callers' {
        Mock Get-AtlasPowerShellVersion {[version]'7.7.0'}
        {_Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi'}|Should -Throw '*newer*'
        {Install-AtlasPS7 -OfflineSource $script:Msi}|Should -Throw '*newer*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Invoke-AtlasNativeProcess -Times 0 -Exactly
    }
}

Describe 'Dependency failure does not launch an alternative installer' {
    BeforeAll {
        $script:RepoRoot=Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Write-AtlasLog { param($Message,$Tool,$Level) }
        function Expand-AtlasPath { param($Path) $Path }
        function Get-AtlasWingetPath { 'fixture-winget.exe' }
        function Invoke-AtlasNativeProcess { [CmdletBinding()]param($FilePath,$ArgumentList,$TimeoutSeconds)throw 'Real installation blocked' }
        function Invoke-WebRequest { [CmdletBinding()]param($Uri,$OutFile,$TimeoutSec,[switch]$UseBasicParsing)throw 'Network blocked' }
        foreach($name in @('Resolve-AtlasDependency','Resolve-SymlinkPath','Test-AtlasDependencyHash','Get-AtlasDependencyCandidate')){. (Get-TestFunction $script:RepoRoot 'src/lib/Dependencies.ps1' $name)}
    }
    BeforeEach {
        $script:Candidate=Join-Path $TestDrive ('dependency-'+[guid]::NewGuid().ToString('N')+'.exe')
        $script:AtlasDepsRegistry=@{Fixture=@{SearchPaths=@($script:Candidate);ExecutableName='fixture-dependency.exe';WingetId='Vendor.Fixture';DownloadUrl='https://example.invalid/installer.exe'}}
        Mock Get-Command { $null }
        Mock Invoke-WebRequest {throw 'Network must not be reached after an installer attempt'}
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='Failed';ExitCode=1603}}
    }
    It 'does not download or retry after an unsuccessful install even when partial files exist' {
        Mock Invoke-AtlasNativeProcess {[IO.File]::WriteAllText($script:Candidate,'partial');[pscustomobject]@{State='Failed';ExitCode=1603}}
        Resolve-AtlasDependency -Name Fixture -InstallIfMissing|Should -BeNullOrEmpty
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Invoke-AtlasNativeProcess -Times 1 -Exactly
    }
    It 'does not retry another installer after a timeout' {
        Mock Invoke-AtlasNativeProcess {[pscustomobject]@{State='TimedOut';ExitCode=0}}
        Resolve-AtlasDependency -Name Fixture -InstallIfMissing|Should -BeNullOrEmpty
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }
    It 'resolves a newly installed candidate only after a successful native result' {
        Mock Invoke-AtlasNativeProcess {[IO.File]::WriteAllText($script:Candidate,'fixture');[pscustomobject]@{State='Correct';ExitCode=0}}
        Resolve-AtlasDependency -Name Fixture -InstallIfMissing|Should -Be $script:Candidate
    }
    It 'does not call missing expected hashes verified' {
        [IO.File]::WriteAllText($script:Candidate,'fixture')
        {Test-AtlasDependencyHash -Path $script:Candidate -ExpectedSha256 ''}|Should -Throw
    }
}
