# Test-only loaders: parse UTF-8 sources and load definitions without running menus.
function Get-TestAst {
    param([string]$RepoRoot, [string]$RelativePath)
    $errors = $null
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $RelativePath) -Raw -Encoding UTF8
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$null, [ref]$errors)
    if ($errors.Count) { throw "Cannot test invalid source: $RelativePath" }
    return $ast
}

function Get-TestFunction {
    param([string]$RepoRoot, [string]$RelativePath, [string]$Name)
    $ast = Get-TestAst $RepoRoot $RelativePath
    $node = $ast.Find({ param($n)
        $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name
    }, $true)
    if (-not $node) { throw "Missing function: $Name" }
    return [scriptblock]::Create($node.Extent.Text)
}

function Get-TestAccountAction {
    param([string]$RepoRoot, [string]$Option)
    $ast = Get-TestAst $RepoRoot 'src/tools/Invoke-MenorPrivilegio.ps1'
    $menu = $ast.Find({ param($n)
        $n -is [System.Management.Automation.Language.SwitchStatementAst] -and $n.Condition.Extent.Text -eq '$seleccion'
    }, $true)
    $clause = $menu.Clauses | Where-Object { $_.Item1.Value -eq $Option }
    if (-not $clause) { throw "Missing account action: $Option" }
    return [scriptblock]::Create("switch ('$Option') { '$Option' $($clause.Item2.Extent.Text) }")
}
