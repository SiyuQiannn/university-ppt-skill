---
name: university-ppt
description: Create, audit, and migrate editable university-themed PowerPoint decks. Use when the user asks for a PPT/PPTX or slide template for a specific university, wants a school-branded deck, wants to migrate one university theme to another, or wants to expand a reusable university PPT layout library.
---

# University PPT

This skill creates editable 16:9 PowerPoint decks for university-themed presentations. It separates four concerns:

1. Structure suites: cover, directory, chapter, content master, and ending pages.
2. Content layouts: reusable center-area information structures.
3. School theme assets: logo, school name, color tokens, and optional school photos.
4. Deck workflow: user request intake, specification, assembly, migration, and QA.

## Start Here

For every task, first identify the mode:

- New deck: create a PPTX for a university and topic.
- Template/library expansion: add more structure suites or content layout variants.
- School migration: preserve page geometry and replace only theme colors, logo, school name, and school imagery.
- QA/revision: inspect generated decks for the known failure modes below.

Then read the relevant references:

- Workflow: `references/workflow.md`
- Deck specification schema: `references/deck_spec_schema.md`
- Layout taxonomy: `references/layout_taxonomy.md`
- Theme migration rules: `references/theme_migration_rules.md`
- Asset requirements and public-repo policy: `references/asset_requirements.md`

## Required Workflow

1. Determine the target school and whether its assets already exist in `assets/schools/<school_id>/`.
2. If the school exists, load `assets/schools/<school_id>/brand.json`.
3. If the school is missing, ask for or research the minimum assets: logo, school name, primary color, secondary color logic, and suitable campus images.
4. Run `scripts/check_assets.ps1` before assembly when using bundled scripts.
5. Create a deck spec using `references/deck_spec_schema.md`.
6. Choose one structure suite and enough content layouts from `references/layout_taxonomy.md`.
7. Assemble an editable `.pptx`; do not use flattened full-slide images as the final deliverable.
8. Export a preview contact sheet and manually/visually audit it before delivery.

## Non-Negotiable Output Rules

- Final deliverable must be editable PPTX.
- Use 16:9 widescreen unless the user explicitly asks otherwise.
- Use Microsoft YaHei for all editable text.
- Keep placeholder copy generic: `标题`, `此处填写标题`, `此处填写副标题`, `此处填写文字`.
- Remove source-template/vendor text such as template website names, author names, and irrelevant school/topic content.
- Preserve logo aspect ratio. Use a white logo on dark bars and colored logo on light backgrounds.
- Structure chrome belongs to the structure suite or content master, not to individual center layout files.
- Content layout files should contain only the center information structure and only necessary text boxes.
- Prefer no-photo structure suites for normal user decks. Use campus photos only when they improve the deck and match the target school.

## Theme Migration Rules

When converting one school deck to another, do not redesign the deck. Preserve:

- Object positions
- Object sizes
- Layout rhythm
- Page count
- Information relation type
- Master/content separation

Replace only:

- Primary theme color and its shade tokens
- Neutral/accent tokens according to the target brand
- Logo and school name
- School-specific images

Never leave major colors from the old school after migration. For example, a blue theme should not keep red/green/pink as main colors; a green theme should not keep blue/red/pink as main colors. Use gray and small pale warm accents only when they support the primary color.

## Known Failure Modes To Check

- Full-page primary-color backgrounds on cover/chapter pages when the reference suite only uses a central horizontal band.
- Stretched or squashed logo.
- White logo accidentally losing the school mark details on a light background.
- Directory or title text covering the logo/school name.
- Extra PowerPoint placeholders or master text boxes left on the page.
- Source template copy or meaningful old content left in placeholders.
- Red/pink/green/orange artifacts left after migrating to a blue school.
- Red/blue/pink/orange artifacts left after migrating to a green school.
- Mismatched fonts on directory pages or section pages.
- Content layout pages carrying their own header/footer/page number chrome.

## Asset Conventions

Use this structure for each school:

```text
assets/schools/<school_id>/
  brand.json
  logos/
    full-color.*
    white.*
  photos/
    campus-*.*
```

Use this structure for reusable layout sources:

```text
assets/structure-suites/
assets/content-layouts/
```

The current local workspace also contains generated PPTX examples and scripts under `D:\ppt工具`; those can be promoted into this skill after the structure, scripts, and QA gates are finalized.
