# School PPT Theme Migration Rules

These rules record the issues found while migrating the RUC deck to Fudan and must be followed for later school migrations.

## Invariants

- Keep layout geometry unchanged: do not move, resize, or simplify existing layout structures when only changing schools.
- Preserve all logo and photo aspect ratios. Use fit for logos and crop-fill for photos; never stretch.
- Replace school identity assets by role: logo to logo, seal to seal, campus/photo band to equivalent campus/photo band.
- Replace school text and motto completely; no source-school residue in slides, masters, or editable layout text.
- Use one unified font family across editable text. Current default: Microsoft YaHei.
- Apply migration to slides, slide masters, and custom layouts. Header/footer bands often live in masters or layouts, not on the visible slide canvas.
- Structure pages such as cover, catalog, chapter, and ending must not become full-screen main-color pages. Keep the canvas white or very light; use the main school color primarily on the central horizontal band and small necessary frame elements.
- When assembling a user-facing sample deck, include multiple content-page candidates. Aim for 2-3 variants for major information structures where source material allows.

## Color Token Rules

- Main color maps to the target school's main color.
- Dark main-color positions map to dark target-color variants.
- Light main-color positions map to light target-color variants.
- Supporting colors must not compete with the main color.
- For a blue school theme, allowed supporting colors are neutral gray, light gray, pale blue, and only small amounts of pale yellow.
- For a green school theme, allowed supporting colors are neutral gray, light gray, pale green, and only small amounts of pale yellow.
- Do not leave strong non-target colors such as source red, source blue, pink, orange, purple, or other saturated competing colors in charts, icons, group fills, gradients, or decorative dots.
- Recolor group objects themselves as well as their child shapes. Many PowerPoint groups store visible fill color on the group object, not only children.
- Recolor charts separately; chart series colors are not ordinary shape fills.
- Check slide/background fills, gradients, and picture overlays. A source red gradient may live in `Background.Fill`, not in a normal shape.
- Check transparent source-color overlays and shadows. A 90% transparent red band still exports as pink and must be recolored.

## Validation Before Delivery

- Export a contact-sheet preview and inspect cover, catalog, chapter, content, chart, icon, hierarchy, and ending pages.
- Scan for source-school words such as old school name, English name, author, template source, and old motto.
- Scan XML for obvious saturated old-theme colors when possible.
- Specifically inspect previously problematic pages: cover/chapters, catalog, wave layouts, circular icon layouts, pyramid/hierarchy, gear/cycle layouts, and chart pages.
