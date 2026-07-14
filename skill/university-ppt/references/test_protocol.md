# 大学主题 PPT Skill 测试协议

本文件用于验证 skill 是否满足稳定工作流，而不是只验证某一次 PPT 是否好看。

## 测试目标

每次更新 skill 后，至少确认：

- 已入库学校可以从自然语言需求生成 `deck_spec.json`。
- `deck_spec.json` 能通过严格校验。
- 缺失学校不会被胡乱编造，会进入资产补全流程。
- spec 中保持 16:9、PPTX、微软雅黑、可编辑、中心版式/母版分离等规则。
- spec 中的 logo、结构套件、内容版式文件都存在。
- 主题 token 包含主色、深色、浅色、灰色和背景色。

## 自动测试

在 `skill/university-ppt` 目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_assets.ps1 -SkillRoot .
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_workflow_tests.ps1 -SkillRoot .
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_assembly_smoke_test.ps1 -SkillRoot .
```

自动测试包含：

| 场景 | 预期 |
|---|---|
| 红色系样本学校 + 论文答辩 | 生成并通过严格 spec 校验 |
| 蓝色系学校 + 项目汇报 | 生成并通过严格 spec 校验 |
| 绿色系学校 + 课程汇报 | 生成并通过严格 spec 校验 |
| 未入库学校 | `new_deck_spec.ps1` 应失败，并提示缺少 `brand.json` |
| 真实 PPT 组装 | `assemble_deck.ps1` 应生成 `.pptx`、`preview_png/`、`preview_contact_sheet.png` |

## 人工测试问答

模拟用户请求时，另一个 agent 应该给出这些行为：

### 1. 已入库学校新建 PPT

用户：

> 帮我做一套某红色系 logo 高校的毕业论文答辩 PPT，12 页，尽量不要图片。

合格行为：

- 识别为 `new_deck`。
- 使用 no-photo 结构套件。
- 生成 12 页 spec，包含封面、目录、章节、内容页、结尾。
- 内容页从信息关系中选择流程、层级、对比、数据、总结等版式。
- 不编造论文事实，只放通用占位文字或请求用户提供内容。

### 2. 学校主题迁移

用户：

> 把这套红色主题 PPT 改成蓝色系学校，位置不要变，只换颜色和 logo。

合格行为：

- 识别为 `theme_migration`。
- 明确“只改主题 token、logo、校名、图片，不重排版”。
- 检查红色、粉色、绿色、橙色等旧主题强色残留。
- 不把复杂版式降级为简单圆圈方块。

### 3. 未入库学校

用户：

> 给我做一套某某大学 PPT。

如果学校不在 `assets/schools`：

- 不猜 logo。
- 不猜标准色。
- 不下载或确认未经许可的图片作为正式资产。
- 提示需要：学校 logo、主色、学校中英文名、是否允许使用校园图。

### 4. 用户只给主题不给内容

用户：

> 给我做一份某大学主题的课程汇报 PPT，但我还没内容。

合格行为：

- 生成模板型 deck/spec。
- 使用无信息占位文字：`标题`、`此处填写文字`。
- 不残留具体“选题背景”“模板网站”“作者”等内容。

## 失败后处理

如果自动测试失败：

1. 先看 `workflow_test_report.json`。
2. 判断是脚本问题、资产缺失、schema 不完整，还是规则冲突。
3. 修改对应脚本、reference 或 asset index。
4. 重跑 `check_assets.ps1`、`run_workflow_tests.ps1` 和 `run_assembly_smoke_test.ps1`。
5. 只有全部通过后才提交或发布。
