# deck_spec.json 契约

`deck_spec.json` 是每次生成或迁移大学主题 PPT 的执行锁。它记录用户意图、学校资产、颜色映射、结构套件、页面计划、版式选择和校验规则。

任何生成脚本都必须先读取 `deck_spec.json`，不得只凭上下文记忆继续执行。

## 顶层结构

```json
{
  "schema_version": "0.1",
  "mode": "new_deck",
  "request": {},
  "school": {},
  "theme": {},
  "assets": {},
  "structure_suite": {},
  "slides": [],
  "layout_policy": {},
  "generation_policy": {},
  "validation_policy": {},
  "outputs": {}
}
```

## `mode`

可选值：

- `new_deck`
- `theme_migration`
- `template_library`
- `edit_existing`
- `asset_onboarding`

## `request`

记录用户请求和生成目标。

```json
{
  "raw_user_request": "给我做一套中国人民大学毕业论文答辩 PPT",
  "language": "zh-CN",
  "purpose": "thesis_defense",
  "audience": "academic_committee",
  "target_slide_count": 16,
  "content_status": "outline_only",
  "output_format": "pptx",
  "aspect_ratio": "16:9",
  "density": "reading_first",
  "image_preference": "minimal"
}
```

字段说明：

| 字段 | 类型 | 说明 |
|---|---|---|
| `raw_user_request` | string | 用户原始请求 |
| `language` | string | 默认 `zh-CN` |
| `purpose` | string | `thesis_defense`、`course_report`、`project_pitch`、`academic_talk` 等 |
| `audience` | string | 受众，如导师、同学、评委、管理层 |
| `target_slide_count` | number | 目标页数 |
| `content_status` | string | `full_content`、`outline_only`、`topic_only`、`source_pptx` |
| `output_format` | string | 默认 `pptx` |
| `aspect_ratio` | string | 默认 `16:9` |
| `density` | string | `speaker_led` 或 `reading_first` |
| `image_preference` | string | `minimal`、`school_identity_only`、`rich_media` |

## `school`

记录目标学校身份。

```json
{
  "school_id": "ruc",
  "name_zh": "中国人民大学",
  "name_en": "Renmin University of China",
  "short_name": "人大",
  "asset_status": "complete",
  "asset_dir": "assets/schools/ruc",
  "source_policy": "confirmed_local_assets"
}
```

字段说明：

| 字段 | 类型 | 说明 |
|---|---|---|
| `school_id` | string | 小写 ID，如 `ruc`、`fudan`、`njfu` |
| `name_zh` | string | 中文校名 |
| `name_en` | string | 英文校名 |
| `short_name` | string | 常用简称 |
| `asset_status` | string | `complete`、`partial`、`missing`、`needs_user_confirmation` |
| `asset_dir` | string | 学校资产目录 |
| `source_policy` | string | `confirmed_local_assets`、`user_provided`、`web_candidates_pending` |

## `theme`

记录主题 token。脚本应使用 token，而不是直接猜颜色。

```json
{
  "font_zh": "Microsoft YaHei",
  "font_en": "Arial",
  "tokens": {
    "primary": "#AA0000",
    "primary_dark": "#7A0000",
    "primary_light_75": "#D46A6A",
    "primary_light_50": "#F0B8B8",
    "primary_light_25": "#F8E8E8",
    "accent": "#C8A85A",
    "accent_light": "#EFE5C8",
    "neutral_dark": "#333333",
    "neutral": "#666666",
    "neutral_light": "#E8E8E8",
    "background": "#FFFFFF"
  },
  "allowed_supporting_roles": [
    "neutral",
    "neutral_light",
    "accent",
    "accent_light"
  ],
  "forbidden_color_families": [
    "unmapped_source_school_color",
    "saturated_competing_color"
  ]
}
```

颜色 token 语义：

| token | 用途 |
|---|---|
| `primary` | 学校主色，用于核心色块、标题、重点图形 |
| `primary_dark` | 深主色，用于深色横条、深色强调块 |
| `primary_light_75` | 75% 浅色，用于次级块、层级结构 |
| `primary_light_50` | 50% 浅色，用于浅卡片、图表辅助 |
| `primary_light_25` | 25% 浅色，用于背景带、弱区域 |
| `accent` | 少量点缀色，不得抢主色 |
| `accent_light` | 浅点缀色，用于细线或弱背景 |
| `neutral_dark` | 正文深灰 |
| `neutral` | 次级文字和弱线 |
| `neutral_light` | 边框、浅底 |
| `background` | 页面底色 |

主题迁移规则：

- 源主色位置 -> 目标 `primary`。
- 源深主色位置 -> 目标 `primary_dark`。
- 源浅主色位置 -> 目标 `primary_light_*`。
- 源金色/弱辅助色 -> 目标 `accent` 或 `accent_light`。
- 源灰色 -> 目标 neutral token。
- 禁止留下未映射的强色。

## `assets`

记录 logo、图片和素材角色。

```json
{
  "logos": {
    "color_horizontal": {
      "path": "assets/schools/ruc/logo/logo_color_horizontal.png",
      "usage": "light_background",
      "preserve_aspect_ratio": true
    },
    "white_horizontal": {
      "path": "assets/schools/ruc/logo/logo_white_horizontal.png",
      "usage": "dark_background",
      "preserve_aspect_ratio": true
    },
    "seal_color": {
      "path": "assets/schools/ruc/logo/seal_color.png",
      "usage": "light_background",
      "preserve_aspect_ratio": true
    }
  },
  "photos": [
    {
      "id": "campus_gate_01",
      "path": "assets/schools/ruc/photos/campus_gate_01.jpg",
      "role": "campus_identity_background",
      "status": "confirmed",
      "fit": "cover",
      "avoid_if": ["minimal_no_photo_cover"]
    }
  ],
  "icons": {
    "source": "built_in_monoline",
    "recolor_policy": "theme_tokens_only"
  }
}
```

规则：

- logo 必须保持原始纵横比。
- 深色背景优先使用白色 logo。
- 浅色背景优先使用彩色 logo。
- 校园图必须是目标学校或用户提供素材。
- 网络检索图片必须标记 `needs_user_confirmation`，确认前不得进入正式 PPT。

## `structure_suite`

结构套件是封面、目录、章节、内容页母版、结尾的联动系统。

```json
{
  "suite_id": "thesis-clean-band-01",
  "source": "ruc_thesis_exact_structure_suite",
  "selected_from_preview": "A",
  "pages": {
    "cover": {
      "layout_id": "cover-horizontal-band",
      "uses_photo": false,
      "logo_mode": "color_on_light",
      "main_color_extent": "central_band_only"
    },
    "toc": {
      "layout_id": "toc-four-cards",
      "uses_photo": false,
      "logo_mode": "white_on_dark_or_color_on_light"
    },
    "section": {
      "layout_id": "section-horizontal-band",
      "uses_photo": false,
      "main_color_extent": "central_band_only"
    },
    "content_master": {
      "layout_id": "content-header-footer-lite",
      "chrome_policy": "master_only"
    },
    "ending": {
      "layout_id": "ending-thank-you",
      "uses_photo": false
    }
  }
}
```

强制规则：

- 封面和章节页不得满屏主色。
- 结构页主色优先出现在中间横条和必要框线。
- 内容页母版负责页眉、页脚、logo、页码、导航。
- 内容版式不得重复绘制母版边框或学校 logo。

## `slides`

记录每页的页面类型、内容关系和版式选择。

```json
[
  {
    "slide_number": 1,
    "page_type": "cover",
    "title": "此处填写标题",
    "subtitle": "此处填写副标题",
    "structure_layout": "cover-horizontal-band"
  },
  {
    "slide_number": 4,
    "page_type": "content",
    "section": "01",
    "title": "此处填写标题",
    "relation": "process",
    "content_layout_candidates": [
      "process-horizontal-steps-01",
      "process-arc-stages-02",
      "process-card-chain-03"
    ],
    "selected_layout": "process-horizontal-steps-01",
    "content_density": "medium",
    "text_policy": "placeholder_or_user_content",
    "image_policy": "none"
  }
]
```

字段说明：

| 字段 | 类型 | 说明 |
|---|---|---|
| `slide_number` | number | 页码 |
| `page_type` | string | `cover`、`toc`、`section`、`content`、`ending`、`appendix` |
| `section` | string | 所属章节 |
| `title` | string | 页面标题 |
| `relation` | string | 内容页信息关系 |
| `content_layout_candidates` | array | 候选版式，通常 2-3 个 |
| `selected_layout` | string | 最终版式 |
| `content_density` | string | `low`、`medium`、`high` |
| `text_policy` | string | `placeholder_or_user_content`、`preserve_user_text`、`summarize_user_text` |
| `image_policy` | string | `none`、`school_identity`、`user_image`、`data_chart` |

## `layout_policy`

```json
{
  "content_layout_source": "assets/content-layouts",
  "variants_per_relation": {
    "default": 2,
    "major": 3
  },
  "avoid_repeating_exact_layout_within": 3,
  "text_box_policy": "only_required_text_boxes",
  "center_layout_only": true,
  "chrome_owned_by_master": true
}
```

规则：

- 每类主要信息关系给 2-3 个候选。
- 连续 3 页内避免复用同一具体版式。
- 中心版式只保留必要文本框。
- 页眉、页脚、logo、页码由母版承担。

## `generation_policy`

```json
{
  "editable_pptx_required": true,
  "whole_slide_image_allowed": false,
  "pptx_engine_priority": [
    "existing_pptx_template_clone",
    "openxml_edit",
    "pptxgenjs_from_layout_recipe"
  ],
  "shape_complexity": "preserve_or_recreate",
  "font_policy": "microsoft_yahei_all_editable_text",
  "slide_size": "16:9"
}
```

## `validation_policy`

```json
{
  "render_preview": true,
  "checks": [
    "aspect_ratio_16_9",
    "logo_aspect_ratio",
    "font_family",
    "theme_color_bounds",
    "source_school_residue",
    "template_source_residue",
    "non_target_school_images",
    "structure_page_main_color_extent",
    "content_layout_no_extra_chrome",
    "text_box_overcrowding",
    "visual_overlap"
  ],
  "fail_on": [
    "source_school_residue",
    "logo_distortion",
    "forbidden_strong_color",
    "non_target_school_image",
    "broken_pptx"
  ]
}
```

## `outputs`

```json
{
  "output_dir": "outputs/ruc_thesis_20260621_1600",
  "pptx": "outputs/ruc_thesis_20260621_1600/deck.pptx",
  "preview_contact_sheet": "outputs/ruc_thesis_20260621_1600/preview_contact_sheet.png",
  "validation_report": "outputs/ruc_thesis_20260621_1600/validation_report.json"
}
```

## 最小示例

```json
{
  "schema_version": "0.1",
  "mode": "new_deck",
  "request": {
    "raw_user_request": "做一套中国人民大学毕业论文答辩 PPT",
    "language": "zh-CN",
    "purpose": "thesis_defense",
    "target_slide_count": 16,
    "content_status": "outline_only",
    "output_format": "pptx",
    "aspect_ratio": "16:9",
    "density": "reading_first",
    "image_preference": "minimal"
  },
  "school": {
    "school_id": "ruc",
    "name_zh": "中国人民大学",
    "name_en": "Renmin University of China",
    "asset_status": "complete",
    "asset_dir": "assets/schools/ruc"
  },
  "theme": {
    "font_zh": "Microsoft YaHei",
    "font_en": "Arial",
    "tokens": {
      "primary": "#AA0000",
      "primary_dark": "#7A0000",
      "primary_light_75": "#D46A6A",
      "primary_light_50": "#F0B8B8",
      "primary_light_25": "#F8E8E8",
      "accent": "#C8A85A",
      "accent_light": "#EFE5C8",
      "neutral_dark": "#333333",
      "neutral": "#666666",
      "neutral_light": "#E8E8E8",
      "background": "#FFFFFF"
    }
  },
  "structure_suite": {
    "suite_id": "thesis-clean-band-01",
    "selected_from_preview": "A"
  },
  "slides": [
    {
      "slide_number": 1,
      "page_type": "cover",
      "title": "此处填写标题"
    },
    {
      "slide_number": 4,
      "page_type": "content",
      "relation": "process",
      "selected_layout": "process-horizontal-steps-01"
    }
  ],
  "validation_policy": {
    "render_preview": true,
    "checks": [
      "aspect_ratio_16_9",
      "logo_aspect_ratio",
      "font_family",
      "theme_color_bounds",
      "source_school_residue"
    ]
  }
}
```
