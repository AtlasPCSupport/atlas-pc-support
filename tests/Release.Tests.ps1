#Requires -Version 5.1
#Requires -Modules Pester
Describe 'Complete immutable releases and recovery' {
    BeforeAll {
        $script:RepoRoot = Split-Path -Parent $PSScriptRoot
        . (Join-Path $script:RepoRoot 'src/lib/Release.ps1')
        . (Join-Path $PSScriptRoot 'SourceTestHelpers.ps1')
        $buildAst=Get-TestAst $script:RepoRoot 'build.ps1'
        $epilogAssignment=$buildAst.Find({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$epilog'},$true)
        $script:CompiledEntry=[scriptblock]::Create($epilogAssignment.Right.Expression.Value)
        function New-ReleaseFixture {
            param([string]$Commit)
            $directory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $directory | Out-Null
            $payload = [ordered]@{
                'get.ps1' = '# fixture bootstrap'
                'launcher.ps1' = '# fixture launcher'
                'config/tools.json' = '{"tools":[{"source":"Invoke-Fixture.ps1","function":"Invoke-Fixture","runtime":{"engine":"windows-powershell","minimumVersion":"5.1","architecture":"x64","libraries":["ToolKit"]}}]}'
                'config/dependencies.json' = '{}'
                'config/tool-hashes.json' = '{}'
                'onboarding/install.bat' = '@echo off'
                'src/tools/Invoke-Fixture.ps1' = ('# harmless fixture ' + ('x' * 150))
            }
            $files = [ordered]@{}
            foreach ($name in $payload.Keys) {
                $path = Join-Path $directory $name
                New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
                [IO.File]::WriteAllText($path, $payload[$name], [Text.UTF8Encoding]::new($false))
                $files[$name] = Get-AtlasTextHash $payload[$name]
            }
            $manifest = [ordered]@{ schemaVersion=1; version='fixture'; algorithm='SHA256-UTF8-LF'; files=$files }
            [IO.File]::WriteAllText((Join-Path $directory 'release-manifest.json'), ($manifest | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
            return [pscustomobject]@{ Directory=$directory; Descriptor=[pscustomobject]@{ schemaVersion=1; commit=$Commit; manifestSha256=(Get-FileHash (Join-Path $directory 'release-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant() } }
        }
        function Update-FixtureManifest {
            param($Fixture, [scriptblock]$Change)
            $path = Join-Path $Fixture.Directory 'release-manifest.json'
            $manifest = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
            & $Change $manifest
            [IO.File]::WriteAllText($path, ($manifest | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
            $Fixture.Descriptor.manifestSha256 = (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
    BeforeEach {
        $script:A = New-ReleaseFixture ('a' * 40)
        $script:B = New-ReleaseFixture ('b' * 40)
        $script:Root = Join-Path $TestDrive ('profile con espacios y tilde-' + [guid]::NewGuid().ToString('N'))
        Mock Save-AtlasReleaseFile { throw 'Network blocked' }
        $script:AtlasReleaseCommit=$null
        $script:AtlasManifestSha256=$null
    }
    It 'uses canonical UTF-8 text consistently across BOM and line endings' {
        Get-AtlasTextHash ([string][char]0xFEFF + "hola`r`n") | Should -Be (Get-AtlasTextHash "hola`n")
    }
    It 'hands an older bootstrap invocation to an approved complete release' {
        Mock Get-AtlasPublishedRelease { $script:A.Descriptor }
        Mock Install-AtlasRelease { [pscustomobject]@{Commit=$script:A.Descriptor.commit;ManifestSha256=$script:A.Descriptor.manifestSha256;Directory=$script:A.Directory} }
        Mock Start-AtlasRelease { }
        $original=$env:LOCALAPPDATA
        try { $env:LOCALAPPDATA=$TestDrive; & $script:CompiledEntry }
        finally { $env:LOCALAPPDATA=$original }
        Should -Invoke Start-AtlasRelease -Times 1 -Exactly
    }
    It 'does not reinterpret a malformed explicit context as an older bootstrap' {
        Mock Get-AtlasPublishedRelease { throw 'Unexpected network' }
        Mock Start-AtlasRelease { }
        $script:AtlasReleaseCommit='invalid'
        { & $script:CompiledEntry } | Should -Throw '*descriptor*'
        Should -Invoke Get-AtlasPublishedRelease -Times 0 -Exactly
        Should -Invoke Start-AtlasRelease -Times 0 -Exactly
    }
    It 'launches a verified online bundle without empty native arguments' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Start-Process { [pscustomobject]@{ExitCode=0} }
        $release=[pscustomobject]@{Directory=$script:A.Directory;Commit=$script:A.Descriptor.commit;ManifestSha256=$script:A.Descriptor.manifestSha256}
        Start-AtlasRelease -Release $release
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $Wait -and $PassThru -and $ArgumentList -notcontains '-AtlasOfflineRoot' -and
            @($ArgumentList | Where-Object { [string]::IsNullOrEmpty($_) }).Count -eq 0 -and
            $ArgumentList[5] -match '^".*launcher\.ps1"$'
        }
    }
    It 'quotes an offline asset path independently from the launcher path' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Start-Process { [pscustomobject]@{ExitCode=0} }
        $release=[pscustomobject]@{Directory=$script:A.Directory;Commit=$script:A.Descriptor.commit;ManifestSha256=$script:A.Descriptor.manifestSha256}
        Start-AtlasRelease -Release $release -OfflineAssetsRoot (Join-Path $TestDrive 'USB with spaces')
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $ArgumentList[-2] -eq '-AtlasOfflineRoot' -and $ArgumentList[-1] -match '^".*USB with spaces"$' }
    }
    It 'propagates a nonzero launcher exit instead of reporting success' -Skip:($env:OS -ne 'Windows_NT') {
        Mock Start-Process { [pscustomobject]@{ExitCode=23} }
        $release=[pscustomobject]@{Directory=$script:A.Directory;Commit=$script:A.Descriptor.commit;ManifestSha256=$script:A.Descriptor.manifestSha256}
        { Start-AtlasRelease -Release $release } | Should -Throw '*23*'
    }
    It 'installs the entire bundle before activating it' {
        $release = Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory
        $release.Commit | Should -Be ('a' * 40)
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be $release.Commit
        @(Get-ChildItem -LiteralPath (Join-Path $script:Root 'releases') -Directory).Count | Should -Be 1
        Should -Invoke Save-AtlasReleaseFile -Times 0 -Exactly
    }
    It 'retains the previous verified release and can roll back without network' {
        Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory | Out-Null
        Install-AtlasRelease -Root $script:Root -Descriptor $script:B.Descriptor -SourceDirectory $script:B.Directory | Out-Null
        (Get-AtlasInstalledRelease -Root $script:Root -Previous).Commit | Should -Be ('a' * 40)
        (Restore-AtlasPreviousRelease -Root $script:Root).Commit | Should -Be ('a' * 40)
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be ('a' * 40)
        (Get-AtlasInstalledRelease -Root $script:Root -Previous).Commit | Should -Be ('b' * 40)
        Should -Invoke Save-AtlasReleaseFile -Times 0 -Exactly
    }
    It 'does not replace a valid active release when a download fails' {
        Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory | Out-Null
        { Install-AtlasRelease -Root $script:Root -Descriptor $script:B.Descriptor } | Should -Throw '*Network blocked*'
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be ('a' * 40)
        @(Get-ChildItem -LiteralPath (Join-Path $script:Root 'releases') -Filter '.staging-*' -Force).Count | Should -Be 0
    }
    It 'does not activate a corrupt or partially copied source release' {
        Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory | Out-Null
        Add-Content -LiteralPath (Join-Path $script:B.Directory 'src/tools/Invoke-Fixture.ps1') -Value '# corrupt'
        { Install-AtlasRelease -Root $script:Root -Descriptor $script:B.Descriptor -SourceDirectory $script:B.Directory } | Should -Throw '*digest mismatch*'
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be ('a' * 40)
    }
    It 'does not trust an absent or different manifest digest' -ForEach @(@{Digest=''},@{Digest=('0'*64)}) {
        { Test-AtlasRelease -Directory $script:A.Directory -ExpectedManifestSha256 $Digest } | Should -Throw
    }
    It 'rejects a requested mutable ref before touching the destination' {
        $script:A.Descriptor.commit='main'
        { Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory } | Should -Throw '*descriptor*'
        Test-Path -LiteralPath $script:Root | Should -BeFalse
    }
    It 'rejects path traversal even in an otherwise approved manifest' {
        Update-FixtureManifest $script:A { param($m) $m.files | Add-Member -NotePropertyName '../outside.ps1' -NotePropertyValue ('0'*64) }
        { Test-AtlasRelease -Directory $script:A.Directory -ExpectedManifestSha256 $script:A.Descriptor.manifestSha256 } | Should -Throw '*path*'
    }
    It 'rejects an incomplete tool set' {
        Remove-Item -LiteralPath (Join-Path $script:A.Directory 'src/tools/Invoke-Fixture.ps1') -Force
        { Test-AtlasRelease -Directory $script:A.Directory -ExpectedManifestSha256 $script:A.Descriptor.manifestSha256 } | Should -Throw
    }
    It 'requires an explicit execution contract' {
        $path=Join-Path $script:A.Directory 'config/tools.json'
        [IO.File]::WriteAllText($path,'{"tools":[{"source":"Invoke-Fixture.ps1","function":"Invoke-Fixture"}]}')
        $hash=Get-AtlasTextHash ([IO.File]::ReadAllText($path))
        Update-FixtureManifest $script:A { param($m) $m.files.'config/tools.json'=$hash }
        { Test-AtlasRelease -Directory $script:A.Directory -ExpectedManifestSha256 $script:A.Descriptor.manifestSha256 } | Should -Throw '*contract*'
    }
    It 'never rolls back into a corrupted previous release' {
        $a=Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory
        Install-AtlasRelease -Root $script:Root -Descriptor $script:B.Descriptor -SourceDirectory $script:B.Directory | Out-Null
        Add-Content -LiteralPath (Join-Path $a.Directory 'launcher.ps1') -Value '# corrupt'
        { Restore-AtlasPreviousRelease -Root $script:Root } | Should -Throw '*digest mismatch*'
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be ('b'*40)
    }
    It 'keeps the active pointer unchanged if atomic activation fails' {
        Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory | Out-Null
        Mock Set-AtlasReleasePointer { throw 'Atomic replace unavailable' }
        { Install-AtlasRelease -Root $script:Root -Descriptor $script:B.Descriptor -SourceDirectory $script:B.Directory } | Should -Throw '*Atomic replace*'
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be ('a'*40)
    }
    It 'rejects a concurrent update instead of interleaving activation' {
        Install-AtlasRelease -Root $script:Root -Descriptor $script:A.Descriptor -SourceDirectory $script:A.Directory | Out-Null
        $lock=[IO.FileStream]::new((Join-Path $script:Root '.update.lock'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { { Install-AtlasRelease -Root $script:Root -Descriptor $script:B.Descriptor -SourceDirectory $script:B.Directory } | Should -Throw }
        finally { $lock.Dispose() }
        (Get-AtlasInstalledRelease -Root $script:Root).Commit | Should -Be ('a'*40)
    }
    It 'makes a complete real USB bundle and validates it with no launch or network' {
        $digest=(Get-FileHash (Join-Path $script:RepoRoot 'release-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant()
        $descriptor=[pscustomobject]@{schemaVersion=1;commit=('c'*40);manifestSha256=$digest}
        $release=Install-AtlasRelease -Root $script:Root -Descriptor $descriptor -SourceDirectory $script:RepoRoot -PrepareOfflineEntry
        @($release.Manifest.files.PSObject.Properties | Where-Object Name -like 'src/tools/*').Count | Should -Be 27
        $bat=Get-Content -LiteralPath (Join-Path $script:Root 'run.bat') -Raw
        $bat | Should -Not -Match 'Bypass|Unblock|https://'
        $engine=(Get-Process -Id $PID).Path
        $output=& $engine -NoProfile -File (Join-Path $script:Root 'get.ps1') -OfflineRoot $script:Root -NoLaunch 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $output | Should -Match '27 tools verified'
        Should -Invoke Save-AtlasReleaseFile -Times 0 -Exactly
    }
}

Describe 'Commit-bound transport fallback' {
    BeforeAll {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/lib/Release.ps1')
    }
    It 'uses the same full commit for the API fallback' {
        Mock Invoke-WebRequest { throw 'Raw unavailable' }
        Mock Invoke-RestMethod { [pscustomobject]@{encoding='base64';content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('fixture'))} }
        $path=Join-Path $TestDrive 'file with spaces.ps1'
        Save-AtlasReleaseFile -Commit ('a'*40) -RelativePath 'get.ps1' -Destination $path
        [IO.File]::ReadAllText($path) | Should -Be 'fixture'
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -like ('*?ref=' + ('a'*40)) }
    }
}
