# Shared report privacy and persistent manual handover. No collection at load time.
function Assert-AtlasPlainFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $file = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Report/checklist must be a plain file.' }
    Assert-AtlasPlainDirectory $file.DirectoryName
}

function Protect-AtlasReportText {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text, [string[]]$SensitiveValues = @())
    $result = $Text
    # Recovery secrets, product keys, user paths, SIDs, emails and network identifiers.
    foreach ($pattern in @(
        '(?i)\b(?:[A-Z0-9]{5}-){4}[A-Z0-9]{5}\b',
        '\b(?:\d{6}-){7}\d{6}\b',
        '(?i)\b[A-Z]:\\Users\\[^\\\s<>"'']+',
        '(?i)\bS-1-5-21-(?:\d+-){2,3}\d+\b',
        '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        '(?i)\b(?:[A-F0-9]{2}[:-]){5}[A-F0-9]{2}\b',
        '\b(?:\d{1,3}\.){3}\d{1,3}\b'
    )) { $result = [regex]::Replace($result, $pattern, '[REDACTED]') }
    $result = [regex]::Replace($result, '(?i)(?<![a-z0-9:])(?:[a-f0-9]{0,4}:){2,}[a-f0-9]{0,4}(?:%[\w.-]+)?(?![a-z0-9:])', {
        param($match)
        $address = $null
        if ([Net.IPAddress]::TryParse($match.Value, [ref]$address) -and $address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6) { return '[REDACTED]' }
        return $match.Value
    })
    $values = @($SensitiveValues) + @($env:COMPUTERNAME, $env:USERNAME, $env:USERPROFILE)
    foreach ($value in @($values | Where-Object { $_ -and $_.Length -ge 3 } | Select-Object -Unique | Sort-Object Length -Descending)) {
        foreach ($encoded in @($value, [Net.WebUtility]::HtmlEncode($value))) {
            $result = [regex]::Replace($result, [regex]::Escape($encoded), '[REDACTED]', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
    }
    return $result
}

function Protect-AtlasReportObject {
    [CmdletBinding()]
    param([AllowNull()][object]$InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [string]) { return (Protect-AtlasReportText $InputObject) }
    if ($InputObject -is [ValueType]) { return $InputObject }
    if ($InputObject -is [Collections.IDictionary] -or $InputObject -is [pscustomobject]) {
        $result = [ordered]@{}
        $names = if ($InputObject -is [Collections.IDictionary]) { @($InputObject.Keys) } else { @($InputObject.PSObject.Properties.Name) }
        foreach ($name in $names) {
            if ($name -match '^(?i:Serial(?:Number)?|UUID|ProcessorId|MachineGuid|MacAddress|IpAddress(?:es)?|UserName|ComputerName|Computer|HostName|Owner|Document|SSID|BSSID|RecoveryPassword|ProductKey|KeyProtectorId|FullName|FileSystemLabel|PNPDeviceId|DeviceId|InstanceId|DeviceInstanceId)$') {
                $result[$name] = '[REDACTED]'
            } else { $result[$name] = Protect-AtlasReportObject $InputObject.$name }
        }
        return [pscustomobject]$result
    }
    if ($InputObject -is [Collections.IEnumerable]) {
        $items = @($InputObject | ForEach-Object { Protect-AtlasReportObject $_ })
        return ,$items
    }
    return (Protect-AtlasReportText ([string]$InputObject))
}

function Write-AtlasShareableReport {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        [Parameter(Mandatory)][string]$Tool, [string[]]$SensitiveValues = @())
    Assert-AtlasPlainDirectory (Split-Path -Parent ([IO.Path]::GetFullPath($Path)))
    if (Test-Path -LiteralPath $Path) { Assert-AtlasPlainFile $Path }
    $trace = Get-AtlasReportTrace -Tool $Tool
    if ([IO.Path]::GetExtension($Path) -eq '.json') {
        $report = Protect-AtlasReportObject ($Content | ConvertFrom-Json -ErrorAction Stop)
        $report | Add-Member -NotePropertyName Trace -NotePropertyValue $trace -Force
        $contentToSave = $report | ConvertTo-Json -Depth 20
    } else {
        $traceText = $trace | ConvertTo-Json -Compress
        $suffix = if ([IO.Path]::GetExtension($Path) -eq '.html') { "`n<!-- " + [Net.WebUtility]::HtmlEncode($traceText) + " -->" } else { "`n`n$traceText" }
        $contentToSave = $Content + $suffix
    }
    $contentToSave = Protect-AtlasReportText -Text $contentToSave -SensitiveValues $SensitiveValues
    [IO.File]::WriteAllText($Path, $contentToSave, [Text.UTF8Encoding]::new($false))
}

function Get-AtlasReportTrace {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Tool)
    $version = Get-Variable AtlasVersion -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    $commit = Get-Variable AtlasReleaseCommit -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    return [pscustomobject][ordered]@{
        SchemaVersion = 1; Tool = $Tool
        Version = if ($version) { [string]$version } else { 'development' }
        Commit = if ($commit) { [string]$commit } else { 'unpublished' }
        GeneratedUtc = [datetime]::UtcNow.ToString('o')
        Privacy = 'Redacted by default; review free text before sharing.'
        Coverage = 'Observations and manual confirmations; not a health, activation or recovery-escrow certificate.'
    }
}

function Get-AtlasHandoverChecklist {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string[]]$Items)
    if (-not $Items.Count) { throw 'Checklist items are required.' }
    if (Test-Path -LiteralPath $Path) {
        Assert-AtlasPlainFile $Path
        $state = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($state.SchemaVersion -ne 1 -or $state.HandoverId -cnotmatch '^[a-f0-9]{32}$' -or -not $state.Trace -or @($state.Items).Count -ne $Items.Count) { throw 'Unsupported checklist schema or changed item count; start a new handover.' }
        for ($index = 0; $index -lt $Items.Count; $index++) {
            $row = $state.Items[$index]
            if ($row.Id -ne ($index + 1) -or $row.Text -cne $Items[$index] -or
                $row.State -notin @('NotVerified','ManualConfirmed','NotApplicable') -or
                ($row.State -ne 'NotVerified' -and (-not $row.CheckedUtc -or -not $row.Evidence))) { throw 'Invalid checklist entry. Existing evidence was not changed.' }
        }
        return $state
    }
    $index = 0
    return [pscustomobject][ordered]@{
        SchemaVersion = 1; HandoverId = [guid]::NewGuid().ToString('N')
        Trace = Get-AtlasReportTrace -Tool 'PC Handover'
        Items = @($Items | ForEach-Object { $index++; [pscustomobject]@{ Id=$index; Text=$_; State='NotVerified'; CheckedUtc=$null; Evidence=$null } })
    }
}

function Save-AtlasHandoverChecklist {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Checklist)
    $directory = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    Assert-AtlasPlainDirectory $directory
    if (Test-Path -LiteralPath $Path) { Assert-AtlasPlainFile $Path }
    $temporary = Join-Path $directory ('checklist-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $json = $Checklist | ConvertTo-Json -Depth 8
        [IO.File]::WriteAllText($temporary, $json, [Text.UTF8Encoding]::new($false))
        Get-AtlasHandoverChecklist -Path $temporary -Items @($Checklist.Items | ForEach-Object Text) | Out-Null
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, ($Path + '.previous'), $true) }
        else { [IO.File]::Move($temporary, $Path) }
    } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force } }
}
