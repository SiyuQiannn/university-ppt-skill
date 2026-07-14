---
name: university-ppt
description: Create, audit, and migrate editable university-themed PowerPoint decks. Use when the user asks for a PPT/PPTX or slide template for a specific university, wants a school-branded deck, wants a reusable university slide layout library, wants to migrate one university theme to another color/logo system, or wants to test/expand the university PPT generation workflow.
---

# University PPT

Create editable 16:9 PowerPoint decks for university-themed presentations by separating five layers:

1. User intent: school, purpose, content status, slide count, image preference.
2. School theme: `brand.json`, logo variants, theme tokens, optional confirmed photos.
3. Structure suite: cover, toc, section, content master, ending.
4. Content layouts: reusable center-area information structures.
5. Workflow lock: `deck_spec.json`, validation report, preview contact sheet, revision loop.

## Required First Steps

Identify the mode before editing or generating any PPTX:

- `new_deck`: user wants a new university-themed deck.
- `theme_migration`: user wants one school theme converted to another.
- `template_library`: user wants new structure/content layouts added.
- `edit_existing`: user wants an existing PPTX changed.
- `asset_onboarding`: user wants a new school added or school assets collected.

Read only the references needed for that mode:

- Workflow contract: `references/workflow.md`
- Deck spec schema: `references/deck_spec_schema.md`
- Layout taxonomy: `references/layout_taxonomy.md`
- Theme migration rules: `references/theme_migration_rules.md`
- Asset requirements: `references/asset_requirements.md`
- Workflow test protocol: `references/test_protocol.md`

## Stable Generation Protocol

Always make generation spec-driven.

1. Inspect `assets/library_index.json` and the target `assets/schools/<school_id>/brand.json`.
2. If the target school exists, create a spec with `scripts/new_deck_spec.ps1` or by copying `assets/specs/deck_spec.template.json`.
3. If the target school is missing, do not fabricate assets. Switch to `asset_onboarding` and ask for logo, school name, primary color, and optional confirmed images.
4. Validate the spec with `scripts/validate_deck_spec.ps1 -Strict`.
5. Assemble or edit the PPTX only after the spec passes.
6. Export previews/contact sheet whenever possible.
7. Fix QA failures before delivery.

Example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\new_deck_spec.ps1 `
  -SkillRoot . `
  -SchoolId ruc `
  -Purpose thesis_defense `
  -TargetSlideCount 12 `
  -OutputPath .\outputs\ruc_thesis\deck_spec.json

powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate_deck_spec.ps1 `
  -SkillRoot . `
  -SpecPath .\outputs\ruc_thesis\deck_spec.json `
  -Strict

powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\assemble_deck.ps1 `
  -SkillRoot . `
  -SpecPath .\outputs\ruc_thesis\deck_spec.json `
  -OutputDir .\outputs\ruc_thesis
```

## Non-Negotiable Output Rules

- Final deliverable must be editable PPTX, not a full-slide screenshot deck.
- Use 16:9 widescreen unless the user explicitly asks otherwise.
- Use Microsoft YaHei for editable Chinese text.
- Keep placeholder copy generic: `标题`, `此处填写标题`, `此处填写副标题`, `此处填写文字`.
- Remove vendor/source-template text, author names, websites, old school names, and irrelevant old topic copy.
- Preserve logo aspect ratio. Use white logo on dark bars and colored logo on light backgrounds.
- Prefer no-photo structure suites for normal user decks. Use photos only when they are target-school or user-provided assets.
- Structure chrome belongs to structure suites and content masters.
- Content layouts must contain only the center information structure and necessary text boxes.

## Theme Migration Contract

When converting one school deck to another, preserve:

- Object positions and sizes
- Slide count
- Layout rhythm
- Information relation type
- Structure/content boundary

Replace only:

- Theme tokens
- Logo variants
- School names
- Confirmed school imagery

Never leave major colors from the old school after migration. A blue theme must not retain red/green/pink/orange as strong colors; a green theme must not retain blue/red/pink/orange as strong colors. Use gray and small pale warm accents only when they support the primary color.

## Known Failure Modes To Block

- Cover/section pages become full-screen primary color when the selected structure only uses a central band or structural bars.
- Logo is stretched, squashed, hidden, or loses detail on the wrong background.
- Directory/title text covers logo or school name.
- PowerPoint default placeholders or master text boxes remain visible.
- Meaningful old source content remains, such as original template title, school, website, author, or topic.
- Content layout pages include their own header/footer/page number/logo chrome.
- Non-target school images remain.
- Default Office blue/green/orange or old-school colors leak after migration.
- Fonts differ across directory, section, and content pages.
- 4:3 source pages leave side blanks in 16:9 output.

## Testing Requirement

After changing this skill, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_assets.ps1 -SkillRoot .
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_workflow_tests.ps1 -SkillRoot .
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_assembly_smoke_test.ps1 -SkillRoot .
```

The workflow tests must include successful specs for onboarded schools and one expected failure for a missing school. The assembly smoke test must create a real editable PPTX and contact-sheet preview. If a test fails unexpectedly, update the skill resources and rerun until it passes.
