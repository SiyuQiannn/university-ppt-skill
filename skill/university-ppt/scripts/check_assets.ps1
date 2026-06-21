param(
    [string]$SkillRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SkillRoot)) {
    $SkillRoot = Split-Path -Parent $PSScriptRoot
}
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check([string]$kind, [string]$relativePath, [bool]$required = $true) {
    $fullPath = Join-Path $SkillRoot $relativePath
    $script:checks.Add([pscustomobject]@{
        Kind = $kind
        Path = $relativePath
        Required = $required
        Exists = Test-Path -LiteralPath $fullPath
    })
}

Add-Check "skill" "SKILL.md"
Add-Check "index" "assets\library_index.json"
Add-Check "reference" "references\workflow.md"
Add-Check "reference" "references\deck_spec_schema.md"
Add-Check "reference" "references\layout_taxonomy.md"
Add-Check "reference" "references\theme_migration_rules.md"
Add-Check "reference" "references\asset_requirements.md"

$libraryPath = Join-Path $SkillRoot "assets\library_index.json"
if (Test-Path -LiteralPath $libraryPath) {
    $library = Get-Content -Raw -Encoding UTF8 -LiteralPath $libraryPath | ConvertFrom-Json
    foreach ($suite in $library.structure_suites) {
        Add-Check "structure-suite" (Join-Path "assets" $suite.path)
    }
    foreach ($layoutLibrary in $library.content_layout_libraries) {
        foreach ($file in $layoutLibrary.layout_files) {
            Add-Check "content-layout" (Join-Path (Join-Path "assets" $layoutLibrary.path) $file.file)
        }
    }
}

foreach ($brandFile in Get-ChildItem -LiteralPath (Join-Path $SkillRoot "assets\schools") -Filter "brand.json" -Recurse -ErrorAction SilentlyContinue) {
    $schoolRoot = Split-Path -Parent $brandFile.FullName
    $schoolRelative = $schoolRoot.Substring($SkillRoot.Length).TrimStart("\")
    $brand = Get-Content -Raw -Encoding UTF8 -LiteralPath $brandFile.FullName | ConvertFrom-Json
    Add-Check "brand" (Join-Path $schoolRelative "brand.json")
    foreach ($assetPath in @(
        $brand.asset_paths.logo_full_color,
        $brand.asset_paths.logo_white,
        $brand.asset_paths.logo_seal_full_color,
        $brand.asset_paths.logo_seal_white
    )) {
        if (-not [string]::IsNullOrWhiteSpace($assetPath)) {
            Add-Check "logo" (Join-Path $schoolRelative $assetPath)
        }
    }
}

$checks | Sort-Object Kind, Path | Format-Table -AutoSize

$missing = @($checks | Where-Object { $_.Required -and -not $_.Exists })
if ($missing.Count -gt 0) {
    Write-Error ("Missing required assets: " + ($missing.Path -join "; "))
}
