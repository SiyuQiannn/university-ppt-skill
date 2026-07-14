param(
    [string]$SkillRoot = "",
    [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SkillRoot)) {
    $SkillRoot = Split-Path -Parent $PSScriptRoot
}
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $SkillRoot "_assembly_smoke_output"
}

$runRoot = Join-Path $OutputRoot (Get-Date -Format "yyyyMMdd_HHmmss")
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
$specPath = Join-Path $runRoot "deck_spec.json"

& (Join-Path $SkillRoot "scripts\new_deck_spec.ps1") `
    -SkillRoot $SkillRoot `
    -SchoolId "ruc" `
    -Purpose "course_report" `
    -TargetSlideCount 8 `
    -RawUserRequest "帮我做一套中国人民大学主题的课程汇报 PPT，8 页，尽量不用图片。" `
    -Title "中国人民大学课程汇报" `
    -Subtitle "此处填写副标题" `
    -OutputPath $specPath | Out-Null

& (Join-Path $SkillRoot "scripts\validate_deck_spec.ps1") `
    -SkillRoot $SkillRoot `
    -SpecPath $specPath `
    -Strict | Out-Null

& (Join-Path $SkillRoot "scripts\assemble_deck.ps1") `
    -SkillRoot $SkillRoot `
    -SpecPath $specPath `
    -OutputDir (Join-Path $runRoot "assembled") | Out-Null

$pptx = Join-Path $runRoot "assembled\deck.pptx"
$contact = Join-Path $runRoot "assembled\preview_contact_sheet.png"
if (-not (Test-Path -LiteralPath $pptx)) { throw "Smoke test failed: missing PPTX $pptx" }
if (-not (Test-Path -LiteralPath $contact)) { throw "Smoke test failed: missing preview contact sheet $contact" }

[pscustomobject]@{
    SpecPath = $specPath
    Pptx = $pptx
    Preview = $contact
    Status = "passed"
} | Format-List
