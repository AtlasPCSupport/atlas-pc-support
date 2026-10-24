# A 5.1 child of pwsh can inherit PS7 module precedence. Keep native modules first,
# in this process only, before JSON, hashing or other module autoloading occurs.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $atlasNativeModules = [IO.Path]::Combine($PSHOME, 'Modules') + [IO.Path]::PathSeparator
    if (-not ([string]$env:PSModulePath).StartsWith($atlasNativeModules, [StringComparison]::OrdinalIgnoreCase)) {
        $env:PSModulePath = $atlasNativeModules + $env:PSModulePath
    }
}
