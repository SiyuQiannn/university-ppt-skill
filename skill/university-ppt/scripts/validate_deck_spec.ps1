param(
    [Parameter(Mandatory = $true)]
    [string]$SpecPath,
    [string]$SkillRoot = "",
    [string]$ReportPath = "",
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SkillRoot)) {
    $SkillRoot = Split-Path -Parent $PSScriptRoot
}
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$SpecPath = (Resolve-Path -LiteralPath $SpecPath).Path

$issues = New-Object System.Collections.Generic.List[object]
function Add-Issue([string]$level, [string]$code, [string]$message, [string]$path = "") {
    $script:issues.Add([pscustomobject]@{
        Level = $level
        Code = $code
        Path = $path
        Message = $message
    })
}

function Test-RequiredString($value, [string]$path) {
    if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
        Add-Issue "Error" "missing_required_field" "Required string is missing." $path
    }
}

function Resolve-SkillPath([string]$relativePath) {
    if ([string]::IsNullOrWhiteSpace($relativePath)) { return $null }
    return Join-Path $SkillRoot ($relativePath -replace "/", "\")
}

function Get-PptxSlideCount([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
    try {
        return @($zip.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide[0-9]+\.xml$' }).Count
    } finally {
        $zip.Dispose()
    }
}

$spec = Get-Content -Raw -Encoding UTF8 -LiteralPath $SpecPath | ConvertFrom-Json

Test-RequiredString $spec.schema_version "schema_version"
Test-RequiredString $spec.mode "mode"
Test-RequiredString $spec.school.school_id "school.school_id"
Test-RequiredString $spec.request.output_format "request.output_format"
Test-RequiredString $spec.request.aspect_ratio "request.aspect_ratio"

if ($spec.request.output_format -ne "pptx") {
    Add-Issue "Error" "unsupported_output_format" "University PPT skill must output editable pptx." "request.output_format"
}
if ($spec.request.aspect_ratio -ne "16:9") {
    Add-Issue "Error" "unsupported_aspect_ratio" "Default output must be 16:9 unless explicitly overridden by the user." "request.aspect_ratio"
}

$requiredTokens = @("primary", "primary_dark", "primary_light_75", "primary_light_50", "primary_light_25", "neutral_dark", "neutral", "neutral_light", "background")
foreach ($token in $requiredTokens) {
    $value = $spec.theme.tokens.$token
    if ([string]::IsNullOrWhiteSpace([string]$value)) {
        Add-Issue "Error" "missing_theme_token" "Missing required theme token '$token'." "theme.tokens.$token"
    } elseif ($value -notmatch "^#[0-9A-Fa-f]{6}$") {
        Add-Issue "Error" "invalid_theme_token" "Theme token '$token' must be a hex color like #A00000." "theme.tokens.$token"
    }
}

if ($spec.theme.font_zh -ne "Microsoft YaHei") {
    Add-Issue "Warning" "font_not_microsoft_yahei" "Editable Chinese text should use Microsoft YaHei." "theme.font_zh"
}

$schoolId = [string]$spec.school.school_id
$brandPath = Join-Path $SkillRoot (Join-Path "assets\schools\$schoolId" "brand.json")
if (-not (Test-Path -LiteralPath $brandPath)) {
    Add-Issue "Error" "missing_school_brand" "Missing brand.json for school '$schoolId'." "school.asset_dir"
}

foreach ($logoName in @("color_horizontal", "white_horizontal", "seal_color", "seal_white")) {
    $logo = $spec.assets.logos.$logoName
    if ($null -eq $logo) {
        Add-Issue "Error" "missing_logo_role" "Missing logo role '$logoName'." "assets.logos.$logoName"
        continue
    }
    if ($logo.preserve_aspect_ratio -ne $true) {
        Add-Issue "Error" "logo_ratio_policy_missing" "Logo role '$logoName' must preserve aspect ratio." "assets.logos.$logoName.preserve_aspect_ratio"
    }
    $fullLogoPath = Resolve-SkillPath $logo.path
    if (-not (Test-Path -LiteralPath $fullLogoPath)) {
        Add-Issue "Error" "missing_logo_file" "Logo file does not exist: $($logo.path)" "assets.logos.$logoName.path"
    }
}

$libraryPath = Join-Path $SkillRoot "assets\library_index.json"
if (-not (Test-Path -LiteralPath $libraryPath)) {
    Add-Issue "Error" "missing_library_index" "Missing assets/library_index.json." "assets.library_index"
} else {
    $library = Get-Content -Raw -Encoding UTF8 -LiteralPath $libraryPath | ConvertFrom-Json
    $suiteIds = @($library.structure_suites | ForEach-Object { $_.id })
    if ($suiteIds -notcontains $spec.structure_suite.suite_id) {
        Add-Issue "Error" "unknown_structure_suite" "Unknown structure suite '$($spec.structure_suite.suite_id)'." "structure_suite.suite_id"
    }

    $allowedRelations = New-Object System.Collections.Generic.HashSet[string]
    $layoutFiles = New-Object System.Collections.Generic.HashSet[string]
    foreach ($layoutLibrary in $library.content_layout_libraries) {
        foreach ($file in $layoutLibrary.layout_files) {
            [void]$layoutFiles.Add("content-layouts/$($layoutLibrary.id)/$($file.file)")
            foreach ($relation in $file.relation_types) {
                [void]$allowedRelations.Add([string]$relation)
            }
        }
    }
}

$slides = @($spec.slides)
if ($slides.Count -eq 0) {
    Add-Issue "Error" "missing_slides" "Spec must include slides." "slides"
} else {
    $expected = 1
    foreach ($slide in $slides) {
        if ([int]$slide.slide_number -ne $expected) {
            Add-Issue "Error" "non_sequential_slide_numbers" "Slide numbers must be sequential; expected $expected but found $($slide.slide_number)." "slides"
        }
        $expected++
        Test-RequiredString $slide.page_type "slides[$($slide.slide_number)].page_type"
        if ($slide.page_type -eq "content") {
            Test-RequiredString $slide.relation "slides[$($slide.slide_number)].relation"
            if ($allowedRelations -and -not $allowedRelations.Contains([string]$slide.relation)) {
                Add-Issue "Warning" "unknown_relation" "Relation '$($slide.relation)' is not in the current layout library index." "slides[$($slide.slide_number)].relation"
            }
            Test-RequiredString $slide.selected_layout_file "slides[$($slide.slide_number)].selected_layout_file"
            if (-not [string]::IsNullOrWhiteSpace([string]$slide.selected_layout_file)) {
                $layoutRelative = [string]$slide.selected_layout_file
                if ($layoutFiles -and -not $layoutFiles.Contains($layoutRelative)) {
                    Add-Issue "Warning" "layout_not_indexed" "Selected layout file is not indexed: $layoutRelative" "slides[$($slide.slide_number)].selected_layout_file"
                }
                $layoutFullPath = Resolve-SkillPath (Join-Path "assets" $layoutRelative)
                if (-not (Test-Path -LiteralPath $layoutFullPath)) {
                    Add-Issue "Error" "missing_layout_file" "Selected layout file does not exist: $layoutRelative" "slides[$($slide.slide_number)].selected_layout_file"
                } else {
                    $idx = 1
                    if ($null -ne $slide.selected_layout_slide_index) {
                        $idx = [int]$slide.selected_layout_slide_index
                    }
                    $count = Get-PptxSlideCount $layoutFullPath
                    if ($idx -lt 1 -or $idx -gt $count) {
                        Add-Issue "Error" "invalid_layout_slide_index" "Selected slide index $idx is outside '$layoutRelative' slide count $count." "slides[$($slide.slide_number)].selected_layout_slide_index"
                    }
                }
            }
        }
    }

    $pageTypes = @($slides | ForEach-Object { $_.page_type })
    foreach ($requiredPageType in @("cover", "toc", "content", "ending")) {
        if ($pageTypes -notcontains $requiredPageType) {
            Add-Issue "Error" "missing_required_page_type" "Deck spec should include at least one '$requiredPageType' page." "slides"
        }
    }
}

if ($spec.layout_policy.center_layout_only -ne $true) {
    Add-Issue "Error" "center_layout_policy_disabled" "Content layout pages must be center-layout only." "layout_policy.center_layout_only"
}
if ($spec.layout_policy.chrome_owned_by_master -ne $true) {
    Add-Issue "Error" "chrome_owner_policy_disabled" "Header/footer/logo/page number chrome must be owned by the structure suite or master." "layout_policy.chrome_owned_by_master"
}
if ($spec.generation_policy.editable_pptx_required -ne $true -or $spec.generation_policy.whole_slide_image_allowed -eq $true) {
    Add-Issue "Error" "editable_policy_violation" "Final deck must be editable PPTX and must not be a whole-slide image deck." "generation_policy"
}

$requiredChecks = @("aspect_ratio_16_9", "logo_aspect_ratio", "font_family", "theme_color_bounds", "source_school_residue", "template_source_residue", "content_layout_no_extra_chrome")
$checks = @($spec.validation_policy.checks)
foreach ($check in $requiredChecks) {
    if ($checks -notcontains $check) {
        $level = if ($Strict) { "Error" } else { "Warning" }
        Add-Issue $level "missing_validation_check" "Validation policy should include '$check'." "validation_policy.checks"
    }
}

$issuesArray = @($issues.ToArray())
$issuesArray | Sort-Object Level, Code, Path | Format-Table -AutoSize

if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $report = [ordered]@{
        spec_path = $SpecPath
        checked_at = (Get-Date).ToString("s")
        issue_count = $issuesArray.Count
        issues = $issuesArray
    }
    $parent = Split-Path -Parent $ReportPath
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
}

$errors = @($issuesArray | Where-Object { $_.Level -eq "Error" })
if ($errors.Count -gt 0) {
    throw "Deck spec validation failed with $($errors.Count) error(s)."
}

Write-Output "Deck spec valid: $SpecPath"
