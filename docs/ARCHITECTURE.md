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
- `skill/university-ppt/references/deck_spec_schema.md`: deck spec contract.
- `skill/university-ppt/references/theme_migration_rules.md`: migration rules.
- `skill/university-ppt/references/test_protocol.md`: workflow test protocol.
- `skill/university-ppt/assets/library_index.json`: layout asset index.
- `skill/university-ppt/assets/specs/deck_spec.template.json`: reusable spec template.
- `skill/university-ppt/scripts/assemble_ruc_sample_deck.ps1`: current sample assembler.
- `skill/university-ppt/scripts/check_assets.ps1`: asset validation.
- `skill/university-ppt/scripts/new_deck_spec.ps1`: creates a locked deck spec from a user request.
- `skill/university-ppt/scripts/validate_deck_spec.ps1`: validates spec structure, assets, theme tokens, and page rules.
- `skill/university-ppt/scripts/assemble_deck.ps1`: assembles an editable PPTX from a validated deck spec.
- `skill/university-ppt/scripts/run_workflow_tests.ps1`: tests the stable workflow against success and expected-failure scenarios.
- `skill/university-ppt/scripts/run_assembly_smoke_test.ps1`: generates a real PPTX and contact-sheet preview.

## Current Limitation

The first generic assembler is now spec-driven. The next engineering step is deeper automated visual QA for logo residue, color leakage, and layout overlap.
