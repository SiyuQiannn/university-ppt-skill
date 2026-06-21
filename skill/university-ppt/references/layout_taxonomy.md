# 大学主题 PPT 版式分类体系

本文件定义内容页的信息关系分类。每一类都对应可复用的中心版式，不包含页眉、页脚、logo、页码和结构页边框。

## 分类原则

- 先识别信息关系，再选择视觉形态。
- 一个内容页只归入一个主关系，可以有一个辅助关系。
- 每个主要关系至少准备 2 个候选版式，常用关系准备 3 个以上。
- 版式应是可编辑对象：形状、文本框、表格、图表、图片占位，不应整页图片化。
- 文本框只保留与版式结构强相关的必要文本框。
- 占位文字只使用“标题”“此处填写文字”“此处填写副标题”等无信息内容。

## 页面类型总表

| 页面类型 | ID | 说明 |
|---|---|---|
| 封面 | `cover` | 标题、学校身份、主题气质 |
| 目录 | `toc` | 章节导航 |
| 章节页 | `section` | 章节切换 |
| 内容页 | `content` | 主体信息结构 |
| 结尾页 | `ending` | 致谢、总结、联系方式 |
| 附录页 | `appendix` | 长表格、参考资料、补充信息 |

封面、目录、章节、内容页母版、结尾由结构套件管理。以下分类主要管理 `content` 页的中心版式。

## 内容关系类型

| ID | 中文名 | 信息关系 | 典型内容 |
|---|---|---|---|
| `bullet_points` | 要点罗列 | 并列要点 | 观点、建议、特点、结论 |
| `numbered_points` | 数字要点 | 并列数字化结论 | 三个发现、四项能力 |
| `process` | 流程步骤 | 先后顺序 | 方法流程、操作步骤 |
| `timeline` | 时间线 | 时间顺序 | 发展历程、研究进度 |
| `comparison` | 对比 | A/B 差异 | 方案对比、前后变化 |
| `matrix` | 矩阵 | 二维分类 | 重要性-紧急性、能力-价值 |
| `swot` | SWOT | 四象限分析 | 优势劣势机会威胁 |
| `hierarchy` | 层级结构 | 上下级/包含 | 组织结构、理论框架 |
| `pyramid` | 金字塔 | 层级递进 | 需求层级、能力层级 |
| `cycle` | 循环 | 闭环关系 | PDCA、反馈机制 |
| `radial` | 中心发散 | 中心-分支 | 核心能力、影响因素 |
| `tree` | 树状分支 | 根-枝-叶 | 分类体系、研究框架 |
| `fishbone` | 鱼骨分析 | 原因归因 | 问题成因、风险拆解 |
| `funnel` | 漏斗 | 筛选/收敛 | 用户转化、样本筛选 |
| `roadmap` | 路线图 | 阶段计划 | 研究计划、项目规划 |
| `data_chart` | 数据图表 | 数据关系 | 柱状图、折线图、饼图 |
| `table` | 表格 | 多字段比较 | 指标、样本、计划表 |
| `image_text` | 图文 | 图像+说明 | 校园图、案例图、产品图 |
| `gallery` | 图片墙 | 多图展示 | 活动、作品、场景 |
| `people` | 人物介绍 | 人-身份-贡献 | 团队、导师、成员 |
| `case_study` | 案例拆解 | 背景-行动-结果 | 案例页、实践页 |
| `quote` | 引用强调 | 一句话重点 | 金句、核心判断 |
| `kpi` | 关键数字 | 数字+解释 | 3 个指标、增长数据 |
| `dashboard` | 仪表盘 | 多指标概览 | 项目状态、竞赛成果 |
| `mobile_mockup` | 手机模拟 | 移动界面展示 | App、智能体、交互流程 |
| `architecture` | 架构图 | 模块依赖 | 系统架构、技术路径 |
| `map_relation` | 地图/空间 | 地理或空间关系 | 校区、区域、路径 |
| `risk_issue` | 问题风险 | 问题-影响-对策 | 风险识别、挑战分析 |
| `summary` | 总结归纳 | 多点收束 | 本章小结、结论 |

## 版式候选规则

每个关系类型的候选版式命名：

```text
<relation>-<visual_form>-<variant_number>
```

例：

- `process-horizontal-steps-01`
- `process-arc-stages-02`
- `hierarchy-pyramid-3d-01`
- `comparison-two-cards-01`

候选版式 metadata：

```json
{
  "layout_id": "process-horizontal-steps-01",
  "relation": "process",
  "visual_form": "horizontal_steps",
  "slots": {
    "title": 1,
    "step": 5,
    "description": 5,
    "icon": 5
  },
  "density": "medium",
  "supports_images": false,
  "supports_data": false,
  "editable": true,
  "requires_master_chrome": true,
  "theme_token_roles": [
    "primary",
    "primary_light_50",
    "neutral"
  ]
}
```

## 常用关系的候选形态

### `bullet_points` 要点罗列

候选形态：

- `bullet_cards_grid`：2x2 或 2x3 卡片，每卡一个要点。
- `bullet_icon_rows`：左侧图标，右侧标题与短句。
- `bullet_side_index`：左侧大编号，右侧解释。
- `bullet_ribbon_list`：横向色带或阶梯式列表。
- `bullet_stack_panels`：上下堆叠面板，适合阅读型 PPT。

适合：

- 3-6 个并列观点。
- 文本量中等。
- 不强调顺序。

避免：

- 超过 6 个要点硬塞一页。
- 所有文本居中。

### `process` 流程步骤

候选形态：

- `process_horizontal_steps`：水平步骤箭头。
- `process_card_chain`：卡片链条。
- `process_arc_stages`：弧形递进。
- `process_stair_steps`：阶梯上升。
- `process_swimlane`：多角色流程。

适合：

- 3-6 步。
- 方法、流程、执行路径。

校验重点：

- 箭头方向清楚。
- 步骤编号不被遮挡。
- 每步说明不超过 2 行。

### `timeline` 时间线

候选形态：

- `timeline_horizontal`：横向年份节点。
- `timeline_vertical`：纵向阶段轴。
- `timeline_road_curve`：曲线路径。
- `timeline_milestone_cards`：里程碑卡片。
- `timeline_dual_track`：双线并行。

适合：

- 3-7 个时间节点。
- 发展历程、研究安排。

### `comparison` 对比

候选形态：

- `comparison_two_columns`：左右对比。
- `comparison_before_after`：前后变化。
- `comparison_pros_cons`：优劣对比。
- `comparison_vs_center`：中间 VS。
- `comparison_check_matrix`：勾叉矩阵。

适合：

- A/B、传统/创新、现状/目标。

避免：

- 两列内容长度差异过大。

### `matrix` 矩阵

候选形态：

- `matrix_2x2_quadrant`：四象限。
- `matrix_axis_bubble`：坐标+气泡。
- `matrix_priority_grid`：优先级矩阵。
- `matrix_capability_value`：能力-价值矩阵。

适合：

- 有两个判断维度。
- 需要分类定位。

### `swot` SWOT

候选形态：

- `swot_four_cards`：四卡片。
- `swot_cross_quadrant`：十字四象限。
- `swot_ring_center`：中心主题+四象限。

适合：

- 商业/项目/竞赛分析。

### `hierarchy` 层级结构

候选形态：

- `hierarchy_tree`：树状层级。
- `hierarchy_stack_blocks`：上下堆叠。
- `hierarchy_org_chart`：组织架构。
- `hierarchy_nested_boxes`：嵌套结构。
- `hierarchy_3d_layers`：三维层级。

适合：

- 框架体系、组织结构、理论结构。

### `pyramid` 金字塔

候选形态：

- `pyramid_flat_layers`：平面层级。
- `pyramid_3d_layers`：三维层级。
- `pyramid_left_labels`：左侧标签说明。
- `pyramid_callout_lines`：右侧引线说明。

适合：

- 3-5 层。
- 从基础到顶层的递进。

校验重点：

- 不得留下源模板多余连接线。
- 底部不得出现不属于金字塔的残留图形。

### `cycle` 循环

候选形态：

- `cycle_ring_arrows`：环形箭头。
- `cycle_four_cards`：四卡闭环。
- `cycle_center_core`：中心主题+外圈步骤。
- `cycle_gear`：齿轮闭环。

适合：

- PDCA、反馈机制、循环迭代。

### `radial` 中心发散

候选形态：

- `radial_center_nodes`：中心节点+周边节点。
- `radial_petals`：花瓣形。
- `radial_spokes`：放射线。
- `radial_orbit`：轨道关系。

适合：

- 一个核心概念影响多个因素。

### `tree` 树状分支

候选形态：

- `tree_left_to_right`：左根右枝。
- `tree_top_down`：上根下枝。
- `tree_mindmap`：思维导图。
- `tree_taxonomy_cards`：分类卡片树。

适合：

- 分类体系、研究维度。

### `fishbone` 鱼骨分析

候选形态：

- `fishbone_classic`：经典鱼骨。
- `fishbone_cards`：卡片式原因归类。
- `fishbone_left_problem`：左侧问题，右侧原因骨架。

适合：

- 问题成因、风险归因。

### `funnel` 漏斗

候选形态：

- `funnel_vertical_layers`：垂直漏斗。
- `funnel_horizontal_pipeline`：横向收敛。
- `funnel_stage_cards`：阶段卡片。

适合：

- 用户转化、样本筛选、方案筛选。

### `data_chart` 数据图表

候选形态：

- `chart_bar_with_insight`：柱状图+洞察。
- `chart_line_trend`：趋势线。
- `chart_donut_breakdown`：环图占比。
- `chart_combo_dashboard`：多图表组合。
- `chart_ranked_bars`：排名条形。

适合：

- 用户提供真实数据。
- 需要图表对象可编辑。

规则：

- 默认用可编辑图表或表格，不做整页图片。
- 颜色必须来自主题 token。
- 数据来源不明时使用占位数据并明确提示可替换。

### `table` 表格

候选形态：

- `table_clean_grid`：基础网格表。
- `table_zebra_rows`：斑马纹。
- `table_comparison`：对比表。
- `table_schedule`：计划表。
- `table_scorecard`：评分表。

适合：

- 3-8 行以内内容页表格。
- 超过 8 行进入附录页。

### `image_text` 图文

候选形态：

- `image_text_left_image`：左图右文。
- `image_text_right_image`：右图左文。
- `image_text_top_image`：上图下文。
- `image_text_caption_overlay`：图上弱叠加说明。

适合：

- 用户提供图、学校图、案例图。

规则：

- 图片保持比例。
- 校园图必须来自目标学校。
- 默认不在封面目录大量使用图片。

### `people` 人物介绍

候选形态：

- `people_cards_four`：四人卡片。
- `people_hex_portraits`：六边形头像。
- `people_profile_left`：单人介绍。
- `people_team_grid`：团队矩阵。

适合：

- 团队、成员、导师、项目组。

规则：

- 头像或照片保持比例。
- 无用户照片时使用头像占位形状，不生成假人物照片。

### `mobile_mockup` 手机模拟

候选形态：

- `mobile_single_mockup`：单手机大图。
- `mobile_three_screens`：三屏并列。
- `mobile_flow_mockup`：手机界面流程。
- `mobile_feature_callouts`：手机+功能标注。

适合：

- App、智能体、交互界面、H5。

### `architecture` 架构图

候选形态：

- `architecture_layered`：分层架构。
- `architecture_modules`：模块关系。
- `architecture_pipeline`：数据流。
- `architecture_cloud_center`：中心服务+周边模块。

适合：

- 技术方案、系统流程、智能体架构。

## 结构页套件类型

结构套件候选不进入内容版式库，单独管理。

| ID | 说明 | 图片策略 |
|---|---|---|
| `structure_clean_band` | 白底，中间横条主色，适合答辩 | 默认无图片 |
| `structure_top_nav` | 顶部导航条，适合章节清晰报告 | 默认无图片 |
| `structure_book_footer` | 底部书本/展开页元素，适合论文答辩 | 可用抽象图形，不依赖照片 |
| `structure_side_stripe` | 侧边色带，适合正式汇报 | 默认无图片 |
| `structure_photo_soft` | 低透明校园图背景，适合学校身份增强 | 仅使用确认校园图 |

结构套件至少包含：

- `cover`
- `toc`
- `section`
- `content_master`
- `ending`

## 版式选择启发

| 内容条件 | 优先关系 |
|---|---|
| 出现“步骤、流程、方法、路径” | `process` |
| 出现年份、阶段、月份、计划 | `timeline` 或 `roadmap` |
| 出现“相比、优劣、前后、传统/创新” | `comparison` |
| 出现“优势、劣势、机会、威胁” | `swot` |
| 出现“体系、框架、层级、结构” | `hierarchy` 或 `pyramid` |
| 出现“原因、影响因素、归因” | `fishbone` 或 `radial` |
| 出现“占比、趋势、增长、数据” | `data_chart` 或 `kpi` |
| 出现“团队、成员、导师、分工” | `people` |
| 出现“界面、App、小程序、智能体” | `mobile_mockup` |
| 出现“模块、系统、技术、链路” | `architecture` |

## 禁止和降级规则

- 文本过多时，不缩到不可读，拆页。
- 表格过长时，不塞内容页，转附录。
- 没有真实数据时，不编造具体事实，使用占位数据或询问用户。
- 没有用户照片时，不生成真人头像。
- 结构页颜色过重时，降级为白底+横条。
- 某个复杂版式迁移后出现颜色残留时，先修复版式，不替换成简单圆圈方块。

