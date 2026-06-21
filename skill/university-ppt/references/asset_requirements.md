# Asset Requirements

## Purpose

This skill separates reusable layout/template assets from school-specific identity assets. Scripts, schemas, workflow rules, brand token examples, structure suites, and content layout PPTX files are intended to travel with the repository when the author chooses to publish them. Real logos and campus photos should still be handled carefully because they may be subject to trademark or image-license restrictions.

## Public Repository Policy

For a public portfolio repository:

- Include `SKILL.md`, `references/`, `scripts/`, `assets/library_index.json`, and `assets/schools/*/brand.json`.
- Include the author's generated/replicated PPTX structure suites and content layout libraries.
- Do not include real university logos unless their use is clearly permitted.
- Do not include campus photos unless they are licensed for redistribution.
- Do not include third-party vendor marks, watermarks, author credits, or unrelated template-source text.
- Use placeholder directories or instructions for real school photo assets when redistribution is unclear.

For a private working repository:

- Include approved school logos in `assets/schools/<school_id>/logos/`.
- Include curated school photos in `assets/schools/<school_id>/photos/`.
- Keep source and generated asset provenance notes near the asset collection process.

## Required Runtime Assets

The current assembly script expects:

```text
assets/structure-suites/ruc_no_image/00_no_image_cover_catalog_chapter_content_ending_suites.pptx
assets/content-layouts/ruc_core/*.pptx
assets/schools/ruc/logos/full-color.png
assets/schools/ruc/logos/white.png
assets/schools/ruc/logos/seal-full-color.png
assets/schools/ruc/logos/seal-white.png
```

Additional school migrations expect each target school to provide:

```text
assets/schools/<school_id>/brand.json
assets/schools/<school_id>/logos/full-color.png
assets/schools/<school_id>/logos/white.png
assets/schools/<school_id>/logos/seal-full-color.png
assets/schools/<school_id>/logos/seal-white.png
```

## Asset QA Rules

- Preserve logo aspect ratio.
- Prefer SVG/PNG logos with transparent backgrounds.
- Use white logo variants only on dark primary-color bars.
- Use full-color logo variants only on light backgrounds.
- Do not publish source-template vendor marks, watermarks, or author names.
- Avoid non-target-school photos in final user decks.
