# Roadmap

## Phase 1: Portfolio-Ready Prototype

- [x] Build RUC theme sample deck.
- [x] Create reusable skill folder.
- [x] Include structure suites and content layout PPTX assets.
- [x] Add asset index and brand token files.
- [x] Add preview contact sheet.
- [x] Add initial documentation.

## Phase 2: Generic Runtime

- [ ] Implement `assemble_deck.ps1` driven by `deck_spec.json`.
- [ ] Implement `migrate_school_theme.ps1` driven by `brand.json`.
- [ ] Separate required runtime assets from optional school photo packs.
- [ ] Add more no-photo structure suites.
- [ ] Add 2-3 variants for every information relation category.

## Phase 3: Quality Automation

- [ ] Detect default Office theme color leakage.
- [ ] Detect non-target-school color leftovers after migration.
- [ ] Detect stretched logos.
- [ ] Detect source-template text leftovers.
- [ ] Detect content-layout pages that include forbidden header/footer chrome.

## Phase 4: School Expansion

- [ ] Formalize school onboarding workflow.
- [ ] Add school color/logo asset checklist.
- [ ] Add user-provided asset ingestion.
- [ ] Add more universities and verify migration quality.
