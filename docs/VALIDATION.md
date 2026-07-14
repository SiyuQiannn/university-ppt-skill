# Validation

This document records the current workflow validation for the University PPT Skill.

## What Was Tested

The goal was to verify the stable workflow, not only the appearance of one sample deck.

The workflow under test:

```text
user request -> deck_spec.json -> strict validation -> PPTX assembly -> preview/QA -> revision
```

The current automated test layer checks whether realistic user requests can be converted into valid `deck_spec.json` files before a PPTX assembler runs.

## Commands

Run from `skill/university-ppt`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_assets.ps1 -SkillRoot .
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_workflow_tests.ps1 -SkillRoot .
```

## Result

Last local validation: 2026-07-14.

Result:

- Passed: 4
- Failed: 0

## Automated Scenarios

| Scenario | Expected | Result | What It Verifies |
|---|---|---|---|
| Red-theme sample school + thesis defense | Success | Passed | A no-photo academic deck request can become a valid spec. |
| Blue-theme school + project report | Success | Passed | The same layout library can migrate to a blue token system without changing geometry. |
| Green-theme school + course report | Success | Passed | The same workflow works for a green token system. |
| Missing school | Failure | Passed | The skill does not invent logo/color assets and enters asset onboarding instead. |

## Manual QA Prompts

These prompts are used as human-readable regression checks for future agents.

### New Deck

User:

> 帮我做一套红色系 logo 高校毕业论文答辩 PPT，12 页，尽量不要图片。

Expected behavior:

- Mode: `new_deck`.
- Create a `deck_spec.json`.
- Use 16:9, PPTX, Microsoft YaHei, generic placeholder text.
- Prefer no-photo structure suite.
- Include cover, toc, section, content, and ending pages.
- Choose content layouts by information relation, such as process, hierarchy, comparison, data, summary.

### Theme Migration

User:

> 把这套红色主题 PPT 改成蓝色系学校，位置不要变，只换颜色和 logo。

Expected behavior:

- Mode: `theme_migration`.
- Preserve geometry, object sizes, page count, and information relation type.
- Replace only theme tokens, logo variants, school names, and confirmed school imagery.
- Block red/pink/green/orange strong-color leftovers in the blue theme.

### Missing School

User:

> 给我做一套未入库学校 PPT。

Expected behavior:

- Mode: `asset_onboarding`.
- Do not guess logo, official colors, or campus images.
- Ask for logo, school names, primary color, and optional confirmed images.

## Current Boundary

The workflow layer is now stable and tested. The current PPTX assembler is still sample-oriented. The next engineering milestone is a generic `assemble_deck.ps1` runtime that consumes `deck_spec.json` directly.
