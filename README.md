# University PPT Skill

面向大学生汇报、课程展示、论文答辩和校园项目展示的可编辑 PPTX 生成 skill 原型。

这个项目的目标不是简单给 PPT 加校徽，而是把“学校主题 PPT”拆成可复用的结构：学校品牌 token、封面/目录/章节/结尾四件套、内容页母版、信息关系版式库和主题迁移规则。当前版本以中国人民大学红色系为样本，并保留了复旦蓝、南京林业大学绿的迁移 token。

![Preview](examples/preview_contact_sheet.png)

## What It Does

- 生成可编辑 `.pptx`，不是整页截图或不可编辑图片。
- 内置结构套件：封面、目录、章节页、内容页母版、结尾页。
- 内置内容版式库：卡片要点、图文案例、流程时间线、层级金字塔、对比分析、数据图表、地图空间、循环网络、图标素材等。
- 使用学校主题 token 管理主色、深色、浅色、灰色和点缀色。
- 支持学校主题迁移逻辑：保持版式位置不变，只替换颜色、logo、学校名称和学校图片。
- 提供 QA 规则，避免 logo 拉伸、默认 Office 蓝绿残留、来源模板文字残留、过多文本框等问题。

## Current Contents

```text
skill/university-ppt/
  SKILL.md
  references/
  scripts/
  assets/
    library_index.json
    schools/
examples/
  preview_contact_sheet.png
docs/
```

The repository page includes the skill source, scripts, references, theme tokens, and preview images. The full editable PPTX template/layout library is attached to the latest GitHub Release:

[Download full PPTX template library](https://github.com/SiyuQiannn/university-ppt-skill/releases/latest/download/university-ppt-skill-repo.zip)

The release zip includes the generated PPT layout/template assets created during this project:

- 2 structure suites
- 9 content layout library PPTX files
- 25-slide sample RUC deck
- preview contact sheet for quick visual inspection

## Quick Start

Requirements:

- Windows
- Microsoft PowerPoint desktop app
- PowerShell

Check bundled assets:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\skill\university-ppt\scripts\check_assets.ps1 -SkillRoot .\skill\university-ppt
```

To generate a sample RUC deck, first download and unzip the full release package. Then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\skill\university-ppt\scripts\assemble_ruc_sample_deck.ps1 -OutputDir .\outputs\ruc_sample
```

The script exports:

- `RUC_skill_sample_deck.pptx`
- `preview_png/`
- `preview_contact_sheet.png`
- `validation.csv`

## Design Principles

- PPT should be editable.
- Structure chrome belongs to structure suites and content masters.
- Content layout pages should only contain the center information structure.
- Placeholder text should be generic, such as `标题` and `此处填写文字`.
- Logo aspect ratio must be preserved.
- School migration should preserve geometry and change theme assets only.
- Default Office blue/green/orange theme colors must be cleaned after generation.

## Status

Prototype, locally verified on 2026-06-21.

Validated output in the release package:

- [examples/preview_contact_sheet.png](examples/preview_contact_sheet.png)

## Roadmap

- Generalize `assemble_ruc_sample_deck.ps1` into a `deck_spec.json` driven assembler.
- Generalize school migration into `migrate_school_theme.ps1` driven by `brand.json`.
- Add more structure suites without photos by default.
- Add 2-3 variants for every major information relation type.
- Add automated visual checks for color leakage, logo stretching, and leftover text placeholders.
- Add school asset ingestion workflow for user-provided logos, colors, and campus photos.

## Notes

This is a portfolio/work-in-progress repository. The author-created PPT layout/template assets are included so the project can be reviewed directly. School logos and real campus imagery should be replaced or verified before broad redistribution.
