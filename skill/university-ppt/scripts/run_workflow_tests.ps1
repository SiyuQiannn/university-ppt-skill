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
    $OutputRoot = Join-Path $SkillRoot "_workflow_test_output"
}

$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$runRoot = Join-Path $OutputRoot $runId
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null

$newSpecScript = Join-Path $SkillRoot "scripts\new_deck_spec.ps1"
$validateScript = Join-Path $SkillRoot "scripts\validate_deck_spec.ps1"
foreach ($script in @($newSpecScript, $validateScript)) {
    if (-not (Test-Path -LiteralPath $script)) {
        throw "Missing required workflow script: $script"
    }
}

$scenarios = @(
    [pscustomobject]@{
        Id = "red_thesis_success"
        SchoolId = "ruc"
        Purpose = "thesis_defense"
        TargetSlideCount = 12
        RawUserRequest = "帮我做一套红色系 logo 高校毕业论文答辩 PPT，12 页，尽量不要图片。"
        Expected = "success"
    },
    [pscustomobject]@{
        Id = "blue_project_success"
        SchoolId = "fudan"
        Purpose = "project_report"
        TargetSlideCount = 10
        RawUserRequest = "帮我做一套蓝色系高校项目汇报 PPT，保持正式、少用图片。"
        Expected = "success"
    },
    [pscustomobject]@{
        Id = "green_course_success"
        SchoolId = "njfu"
        Purpose = "course_report"
        TargetSlideCount = 8
        RawUserRequest = "帮我做一套绿色系高校课程汇报 PPT，使用通用占位文字。"
        Expected = "success"
    },
    [pscustomobject]@{
        Id = "missing_school_expected_failure"
        SchoolId = "unknown_school"
        Purpose = "course_report"
        TargetSlideCount = 8
        RawUserRequest = "帮我做一套未入库学校 PPT。"
        Expected = "failure"
    }
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($scenario in $scenarios) {
    $scenarioRoot = Join-Path $runRoot $scenario.Id
    New-Item -ItemType Directory -Force -Path $scenarioRoot | Out-Null
    $specPath = Join-Path $scenarioRoot "deck_spec.json"
    $validationPath = Join-Path $scenarioRoot "validation_report.json"
    $status = "unknown"
    $message = ""

    try {
        & $newSpecScript `
            -SkillRoot $SkillRoot `
            -SchoolId $scenario.SchoolId `
            -Purpose $scenario.Purpose `
            -TargetSlideCount $scenario.TargetSlideCount `
            -RawUserRequest $scenario.RawUserRequest `
            -OutputPath $specPath | Out-Null

        & $validateScript `
            -SkillRoot $SkillRoot `
            -SpecPath $specPath `
            -ReportPath $validationPath `
            -Strict | Out-Null

        $status = "success"
        $message = "Generated and validated deck_spec.json"
    } catch {
        $status = "failure"
        $message = $_.Exception.Message
    }

    $passed = $false
    if ($scenario.Expected -eq "success" -and $status -eq "success") {
        $passed = $true
    }
    if ($scenario.Expected -eq "failure" -and $status -eq "failure") {
        $passed = $true
    }

    $results.Add([pscustomobject]@{
        Id = $scenario.Id
        SchoolId = $scenario.SchoolId
        Purpose = $scenario.Purpose
        Expected = $scenario.Expected
        Status = $status
        Passed = $passed
        SpecPath = if (Test-Path -LiteralPath $specPath) { $specPath } else { "" }
        ValidationReportPath = if (Test-Path -LiteralPath $validationPath) { $validationPath } else { "" }
        Message = $message
    })
}

$resultArray = @($results.ToArray())
$passedCount = ($resultArray | Where-Object { $_.Passed -eq $true } | Measure-Object).Count
$failedCount = ($resultArray | Where-Object { $_.Passed -ne $true } | Measure-Object).Count

$report = [ordered]@{
    run_id = $runId
    skill_root = $SkillRoot
    output_root = $runRoot
    passed = $passedCount
    failed = $failedCount
    scenarios = $resultArray
}

$jsonReportPath = Join-Path $runRoot "workflow_test_report.json"
$mdReportPath = Join-Path $runRoot "workflow_test_report.md"
$report | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 -LiteralPath $jsonReportPath

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Workflow Test Report")
$md.Add("")
$md.Add(("- Run ID: ``{0}``" -f $runId))
$md.Add(("- Skill root: ``{0}``" -f $SkillRoot))
$md.Add("- Passed: $($report.passed)")
$md.Add("- Failed: $($report.failed)")
$md.Add("")
$md.Add("| Scenario | Expected | Status | Passed | Message |")
$md.Add("|---|---|---|---|---|")
foreach ($result in $results) {
    $safeMessage = ([string]$result.Message).Replace("|", "/")
    $md.Add("| $($result.Id) | $($result.Expected) | $($result.Status) | $($result.Passed) | $safeMessage |")
}
$md | Set-Content -Encoding UTF8 -LiteralPath $mdReportPath

$results | Format-Table -AutoSize
Write-Output "Workflow test report: $jsonReportPath"

if ($report.failed -gt 0) {
    throw "Workflow tests failed: $($report.failed)"
}
