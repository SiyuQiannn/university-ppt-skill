param(
    [string]$SkillRoot = "",
    [string]$SchoolId = "ruc",
    [ValidateSet("new_deck", "theme_migration", "template_library", "edit_existing", "asset_onboarding")]
    [string]$Mode = "new_deck",
    [string]$Purpose = "course_report",
    [int]$TargetSlideCount = 12,
    [string]$RawUserRequest = "",
    [string]$Title = "此处填写标题",
    [string]$Subtitle = "此处填写副标题",
    [ValidateSet("minimal", "school_identity_only", "rich_media")]
    [string]$ImagePreference = "minimal",
    [string]$StructureSuiteId = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SkillRoot)) {
    $SkillRoot = Split-Path -Parent $PSScriptRoot
}
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path

$libraryPath = Join-Path $SkillRoot "assets\library_index.json"
if (-not (Test-Path -LiteralPath $libraryPath)) {
    throw "Missing library index: $libraryPath"
}
$library = Get-Content -Raw -Encoding UTF8 -LiteralPath $libraryPath | ConvertFrom-Json

$schoolRoot = Join-Path $SkillRoot (Join-Path "assets\schools" $SchoolId)
$brandPath = Join-Path $schoolRoot "brand.json"
if (-not (Test-Path -LiteralPath $brandPath)) {
    throw "School '$SchoolId' is not onboarded. Missing brand file: $brandPath"
}
$brand = Get-Content -Raw -Encoding UTF8 -LiteralPath $brandPath | ConvertFrom-Json
$logoFullColor = [string]$brand.asset_paths.logo_full_color
$logoWhite = [string]$brand.asset_paths.logo_white
$logoSealFullColor = [string]$brand.asset_paths.logo_seal_full_color
$logoSealWhite = [string]$brand.asset_paths.logo_seal_white
$themeTokens = [ordered]@{}
foreach ($property in $brand.color_tokens.PSObject.Properties) {
    $themeTokens[$property.Name] = [string]$property.Value
}

if ($TargetSlideCount -lt 5) {
    $TargetSlideCount = 5
}

$suite = $null
if (-not [string]::IsNullOrWhiteSpace($StructureSuiteId)) {
    $suite = @($library.structure_suites | Where-Object { $_.id -eq $StructureSuiteId }) | Select-Object -First 1
    if (-not $suite) {
        throw "Unknown structure suite id: $StructureSuiteId"
    }
} else {
    $suite = @($library.structure_suites | Where-Object { $_.school_id -eq $SchoolId -and $_.photo_policy -eq "no_photo_default" }) | Select-Object -First 1
    if (-not $suite) {
        $suite = @($library.structure_suites | Where-Object { $_.photo_policy -eq "no_photo_default" }) | Select-Object -First 1
    }
    if (-not $suite) {
        $suite = @($library.structure_suites) | Select-Object -First 1
    }
}

$contentLibrary = @($library.content_layout_libraries | Where-Object { $_.school_id -eq $SchoolId }) | Select-Object -First 1
if (-not $contentLibrary) {
    $contentLibrary = @($library.content_layout_libraries) | Select-Object -First 1
}
if (-not $contentLibrary) {
    throw "No content layout library found in library_index.json"
}

$relationToFiles = @{}
foreach ($file in $contentLibrary.layout_files) {
    foreach ($relation in $file.relation_types) {
        if (-not $relationToFiles.ContainsKey($relation)) {
            $relationToFiles[$relation] = New-Object System.Collections.Generic.List[object]
        }
        $relationToFiles[$relation].Add($file)
    }
}

function Get-RelationSequence([string]$purpose) {
    switch -Regex ($purpose) {
        "thesis|defense|答辩|论文" { return @("bullet_points", "process", "hierarchy", "comparison", "data", "timeline", "summary") }
        "pitch|competition|roadshow|竞赛|路演" { return @("bullet_points", "comparison", "process", "data", "team_profile", "cycle", "summary") }
        "project|项目" { return @("bullet_points", "process", "timeline", "comparison", "data", "hierarchy", "summary") }
        default { return @("bullet_points", "process", "comparison", "hierarchy", "data", "image_text", "summary") }
    }
}

function Resolve-LayoutForRelation([string]$relation) {
    $fallbackMap = @{
        "timeline" = "process"
        "roadmap" = "process"
        "team_profile" = "image_text"
        "people" = "image_text"
        "data_chart" = "data"
        "table" = "data"
        "pyramid" = "hierarchy"
        "framework" = "hierarchy"
    }

    $resolved = $relation
    if (-not $relationToFiles.ContainsKey($resolved) -and $fallbackMap.ContainsKey($resolved)) {
        $resolved = $fallbackMap[$resolved]
    }
    if (-not $relationToFiles.ContainsKey($resolved)) {
        $resolved = @($relationToFiles.Keys | Sort-Object | Select-Object -First 1)
    }

    $candidates = @($relationToFiles[$resolved] | Select-Object -First 3)
    $selected = $candidates | Select-Object -First 1
    $defaultSlideIndex = 1
    if ($selected.file -like "01_*") { $defaultSlideIndex = 10 }
    elseif ($selected.file -like "02_*") { $defaultSlideIndex = 1 }
    elseif ($selected.file -like "03_*") { $defaultSlideIndex = 13 }
    elseif ($selected.file -like "04_*") { $defaultSlideIndex = 3 }
    elseif ($selected.file -like "05_*") { $defaultSlideIndex = 8 }
    elseif ($selected.file -like "06_*") { $defaultSlideIndex = 6 }
    elseif ($selected.file -like "07_*") { $defaultSlideIndex = 1 }
    elseif ($selected.file -like "08_*") { $defaultSlideIndex = 8 }
    elseif ($selected.file -like "10_*") { $defaultSlideIndex = 1 }

    return [pscustomobject]@{
        requested_relation = $relation
        relation = $resolved
        candidates = @($candidates | ForEach-Object { "$($contentLibrary.id)/$($_.file)" })
        selected = "$($contentLibrary.id)/$($selected.file)"
        selected_file = "content-layouts/$($contentLibrary.id)/$($selected.file)"
        selected_slide_index = $defaultSlideIndex
    }
}

$relationSequence = Get-RelationSequence $Purpose
$slides = New-Object System.Collections.Generic.List[object]

$slides.Add([pscustomobject]@{
    slide_number = 1
    page_type = "cover"
    title = $Title
    subtitle = $Subtitle
    structure_layout = "cover"
})

$slides.Add([pscustomobject]@{
    slide_number = 2
    page_type = "toc"
    title = "目录"
    structure_layout = "toc"
})

$slides.Add([pscustomobject]@{
    slide_number = 3
    page_type = "section"
    section = "01"
    title = "章节标题"
    structure_layout = "section"
})

$contentCount = $TargetSlideCount - 4
for ($i = 0; $i -lt $contentCount; $i++) {
    $slideNumber = 4 + $i
    $relation = $relationSequence[$i % $relationSequence.Count]
    $layout = Resolve-LayoutForRelation $relation
    $sectionNumber = [int]([math]::Floor($i / 4) + 1)
    $slides.Add([pscustomobject]@{
        slide_number = $slideNumber
        page_type = "content"
        section = ("{0:D2}" -f $sectionNumber)
        title = "此处填写标题"
        relation = $layout.relation
        requested_relation = $layout.requested_relation
        content_layout_candidates = $layout.candidates
        selected_layout = $layout.selected
        selected_layout_file = $layout.selected_file
        selected_layout_slide_index = $layout.selected_slide_index
        content_density = "medium"
        text_policy = "placeholder_or_user_content"
        image_policy = "none"
    })
}

$slides.Add([pscustomobject]@{
    slide_number = $TargetSlideCount
    page_type = "ending"
    title = "谢谢"
    structure_layout = "ending"
})

if ([string]::IsNullOrWhiteSpace($RawUserRequest)) {
    $RawUserRequest = "Create a $SchoolId university themed $Purpose PPT."
}

$slidesArray = @($slides.ToArray())

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $safePurpose = ($Purpose -replace "[^A-Za-z0-9_-]", "_")
    $OutputPath = Join-Path (Get-Location).Path "deck_spec.$SchoolId.$safePurpose.json"
}

$spec = [ordered]@{
    schema_version = "0.2"
    mode = $Mode
    request = [ordered]@{
        raw_user_request = $RawUserRequest
        language = "zh-CN"
        purpose = $Purpose
        audience = "general_university_audience"
        target_slide_count = $TargetSlideCount
        content_status = "outline_only"
        output_format = "pptx"
        aspect_ratio = "16:9"
        density = "reading_first"
        image_preference = $ImagePreference
    }
    school = [ordered]@{
        school_id = $brand.school_id
        name_zh = $brand.school_name_zh
        name_en = $brand.school_name_en
        short_name = $brand.school_name_zh
        asset_status = "complete"
        asset_dir = "assets/schools/$SchoolId"
        source_policy = "confirmed_local_assets"
    }
    theme = [ordered]@{
        font_zh = $brand.font_family
        font_en = "Arial"
        family = $brand.theme_family
        tokens = $themeTokens
        allowed_supporting_roles = @("neutral", "neutral_light", "accent", "accent_pale")
        forbidden_color_families = @("unmapped_source_school_color", "saturated_competing_color")
    }
    assets = [ordered]@{
        logos = [ordered]@{
            color_horizontal = [ordered]@{
                path = "assets/schools/$SchoolId/$logoFullColor"
                usage = "light_background"
                preserve_aspect_ratio = $true
            }
            white_horizontal = [ordered]@{
                path = "assets/schools/$SchoolId/$logoWhite"
                usage = "dark_background"
                preserve_aspect_ratio = $true
            }
            seal_color = [ordered]@{
                path = "assets/schools/$SchoolId/$logoSealFullColor"
                usage = "light_background"
                preserve_aspect_ratio = $true
            }
            seal_white = [ordered]@{
                path = "assets/schools/$SchoolId/$logoSealWhite"
                usage = "dark_background"
                preserve_aspect_ratio = $true
            }
        }
        photos = @()
        icons = [ordered]@{
            source = "built_in_editable_shapes"
            recolor_policy = "theme_tokens_only"
        }
    }
    structure_suite = [ordered]@{
        suite_id = $suite.id
        source = $suite.path
        selected_from_preview = "auto"
        pages = [ordered]@{
            cover = [ordered]@{ layout_id = "cover"; uses_photo = $false; main_color_extent = "central_band_or_structural_bars_only" }
            toc = [ordered]@{ layout_id = "toc"; uses_photo = $false }
            section = [ordered]@{ layout_id = "section"; uses_photo = $false; main_color_extent = "central_band_or_structural_bars_only" }
            content_master = [ordered]@{ layout_id = "content_master"; chrome_policy = "master_only" }
            ending = [ordered]@{ layout_id = "ending"; uses_photo = $false }
        }
    }
    slides = $slidesArray
    layout_policy = [ordered]@{
        content_layout_source = "assets/content-layouts/$($contentLibrary.id)"
        variants_per_relation = [ordered]@{ default = 2; major = 3 }
        avoid_repeating_exact_layout_within = 3
        text_box_policy = "only_required_text_boxes"
        center_layout_only = $true
        chrome_owned_by_master = $true
    }
    generation_policy = [ordered]@{
        editable_pptx_required = $true
        whole_slide_image_allowed = $false
        pptx_engine_priority = @("existing_pptx_template_clone", "openxml_edit", "pptxgenjs_from_layout_recipe")
        shape_complexity = "preserve_or_recreate"
        font_policy = "microsoft_yahei_all_editable_text"
        slide_size = "16:9"
    }
    validation_policy = [ordered]@{
        render_preview = $true
        checks = @(
            "aspect_ratio_16_9",
            "logo_aspect_ratio",
            "font_family",
            "theme_color_bounds",
            "source_school_residue",
            "template_source_residue",
            "non_target_school_images",
            "structure_page_main_color_extent",
            "content_layout_no_extra_chrome",
            "text_box_overcrowding",
            "visual_overlap"
        )
        fail_on = @("source_school_residue", "logo_distortion", "forbidden_strong_color", "non_target_school_image", "broken_pptx")
    }
    outputs = [ordered]@{
        output_dir = "outputs/$SchoolId/$Purpose"
        pptx = "outputs/$SchoolId/$Purpose/deck.pptx"
        preview_contact_sheet = "outputs/$SchoolId/$Purpose/preview_contact_sheet.png"
        validation_report = "outputs/$SchoolId/$Purpose/validation_report.json"
    }
}

$json = $spec | ConvertTo-Json -Depth 20
$parent = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}
Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
Write-Output "Created deck spec: $OutputPath"
