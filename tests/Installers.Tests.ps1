#Requires -Version 5.1
#Requires -Modules Pester

Describe 'A01 installer verification regressions' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        function Start-Process { [CmdletBinding()] param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru) throw 'Real process blocked' }
        function Invoke-WebRequest { [CmdletBinding()] param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec) throw 'Network blocked' }
        function Get-AuthenticodeSignature { [CmdletBinding()] param($FilePath) throw 'Real signature inspection blocked' }
        function _Write-AtlasStepCompat { param($Message) }
        function _Write-AtlasOkCompat { param($Message) }
        function _Get-PS7Path { 'mock-pwsh.exe' }
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
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
        Mock Get-AtlasPS7Path { 'mock-pwsh.exe' }
        Mock Invoke-WebRequest { throw 'Network blocked' }
        Mock Get-AuthenticodeSignature {
            [pscustomobject]@{ Status = 'Valid'; SignerCertificate = [pscustomobject]@{ Subject = 'CN=Microsoft Corporation, O=Microsoft Corporation, C=US' } }
        }
        Mock Invoke-ExternalProcessWithTimeout { throw 'Extractor must not run with invalid content' }
        $script:Msi = Join-Path $TestDrive ('fixture with spaces-' + [guid]::NewGuid().ToString('N') + '.msi')
        Set-Content -LiteralPath $script:Msi -Value 'Not an installer' -Encoding ASCII
        $script:Hash = (Get-FileHash -LiteralPath $script:Msi -Algorithm SHA256).Hash.ToLowerInvariant()
        $script:L = @{ UsingLocalMsi='{0}'; Installing='install'; InstallOK='{0}'; DownloadFailed='{0}'; MsiExitCode='{0}'; Downloading='{0}'; FCInstOk='{0}'; FCDLFail='{0}'; PS7Exists='{0}'; PS7Fail='{0}' }
    }

    It 'rejects an unsigned MSI before starting the standalone updater' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        Mock Get-AuthenticodeSignature { [pscustomobject]@{ Status='NotSigned'; SignerCertificate=$null } }
        { _Install-PS7 -OfflineSource $script:Msi -L $script:L -Version 'test' -MsiName 'fixture.msi' } | Should -Throw '*signature*'
        Should -Invoke Start-Process -Times 0 -Exactly
        Should -Invoke Get-AuthenticodeSignature -Times 1 -Exactly
    }
    It 'refuses offline installation without a required expected hash' {
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
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi' | Should -Be 'mock-pwsh.exe'
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'msiexec.exe' -and $ArgumentList[1] -eq ('"'+$script:Msi+'"') }
    }
    It 'does not swallow a mismatch in the standalone updater' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value ('0'*64)
        { _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi' } | Should -Throw '*mismatch*'
        Should -Invoke Start-Process -Times 0 -Exactly
    }
    It 'rejects a nonzero MSI result after verification' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value $script:Hash
        Mock Start-Process { [pscustomobject]@{ ExitCode=1603 } }
        { _Install-PS7 -OfflineSource $script:Msi -L $script:L -MsiName 'fixture.msi' } | Should -Throw '*1603*'
    }
    It 'rejects an offline library MSI with a mismatching digest' {
        Set-Content -LiteralPath "$script:Msi.sha256" -Value ('0'*64)
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
        Mock Get-AtlasReleaseFileHash { $script:Hash }
        Download-PS7 -DepsDir $deps | Should -BeTrue
        (Get-Content -LiteralPath "$file.sha256" -Raw).Trim() | Should -Be $script:Hash
        Should -Invoke Get-AuthenticodeSignature -Times 1 -Exactly
    }
}
