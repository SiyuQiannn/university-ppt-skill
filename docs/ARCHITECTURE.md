# Architecture

## Concept

The project models a university PPT deck as four layers:

1. School theme: brand tokens, school name, logo variants, and optional photos.
2. Structure suite: cover, directory, chapter, content master, and ending.
3. Content layout: editable center-area information structures.
4. Assembly workflow: deck specification, PPTX construction, preview export, and QA.

## Why This Structure

Most school PPT templates only paste a logo and apply a color. This project treats the school identity as a theme layer and keeps the layout library reusable across universities.

The migration rule is strict:

- Preserve positions.
- Preserve object sizes.
- Preserve information relation type.
- Replace only color tokens, school text, logos, and school imagery.

## Important Files

- `skill/university-ppt/SKILL.md`: entry point for Codex.
- `skill/university-ppt/references/workflow.md`: full workflow.
- `skill/university-ppt/references/layout_taxonomy.md`: layout taxonomy.
- `skill/university-ppt/references/deck_spec_schema.md`: planned JSON schema.
- `skill/university-ppt/references/theme_migration_rules.md`: migration rules.
- `skill/university-ppt/assets/library_index.json`: layout asset index.
- `skill/university-ppt/scripts/assemble_ruc_sample_deck.ps1`: current sample assembler.
- `skill/university-ppt/scripts/check_assets.ps1`: asset validation.

## Current Limitation

The current assembler is still RUC-sample oriented. The next engineering step is turning it into a generic deck assembler driven by `deck_spec.json` and `brand.json`.
