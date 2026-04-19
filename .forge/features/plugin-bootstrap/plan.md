# Plan: plugin-bootstrap

> 基于：design-plugin-bootstrap.md  
> 生成时间：2026-04-14

---

## Task List

### T001 — 创建插件目录骨架 `infra`
**描述：** 建立 `.claude-plugin/`、`skills/`（8个子目录）、`agents/`（3个子目录）的完整目录结构。  
**依赖：** 无  
**范围：**
- 创建 `.claude-plugin/` 目录
- 创建 `skills/onboard/`、`skills/calibrate/`、`skills/clarify/`、`skills/design/`、`skills/plan/`、`skills/code/`、`skills/review/`、`skills/test/`
- 创建 `agents/` 目录

**验收标准：**
- [ ] 所有目录存在
- [ ] 目录结构与 `docs/detailed-design.md` 一致

**规模预估：** small

---

### T002 — 编写 plugin.json `infra`
**描述：** 创建插件 manifest 文件，内容最小化，只包含元数据。  
**依赖：** T001  
**范围：**
- 创建 `.claude-plugin/plugin.json`

**验收标准：**
- [ ] 包含 `name`、`version`、`description`、`author` 字段
- [ ] 不包含组件注册（靠约定目录自动发现）
- [ ] JSON 格式合法

**规模预估：** small

---

### T003 — 创建占位 SKILL.md（7个非 plan skills）`docs`
**描述：** 为 onboard / calibrate / clarify / design / code / review / test 创建带合法 frontmatter 的骨架 SKILL.md，内容标注 `[TODO]`。  
**依赖：** T001  
**范围：**
- `skills/onboard/SKILL.md`
- `skills/calibrate/SKILL.md`
- `skills/clarify/SKILL.md`
- `skills/design/SKILL.md`
- `skills/code/SKILL.md`
- `skills/review/SKILL.md`
- `skills/test/SKILL.md`

**验收标准：**
- [ ] 每个文件都有合法的 YAML frontmatter（至少包含 `name` 和 `description`）
- [ ] 正文有 `[TODO]` 标记，表明是占位内容
- [ ] 插件加载后这些 skill 出现在 `/forge:` 命令列表中（即使功能未实现）

**规模预估：** small

---

### T004 — 创建占位 agent.md（3个 agents）`docs`
**描述：** 为 forge-explorer / forge-architect / forge-reviewer 创建带合法 frontmatter 的骨架 agent.md，内容标注 `[TODO]`。  
**依赖：** T001  
**范围：**
- `agents/forge-explorer.md`
- `agents/forge-architect.md`
- `agents/forge-reviewer.md`

**验收标准：**
- [ ] 每个文件都有合法的 YAML frontmatter（`name`、`description`、`tools`、`model`、`color`）
- [ ] 正文有 `[TODO]` 标记

**规模预估：** small

---

### T005 — 实现 plan skill（完整） `logic` ⚠ 关键
**描述：** 编写完整的 `skills/plan/SKILL.md`，使其能够读取 `.forge/design-{slug}.md`，分解任务，生成完整的 `.forge/plan-{slug}.md`。这是 bootstrap 阶段唯一完整实现的 skill。  
**依赖：** T001、T002、T003（需要参考骨架格式）  
**范围：**
- `skills/plan/SKILL.md`（完整 frontmatter + 完整 Process 指令）

**验收标准：**
- [ ] Frontmatter 包含所有必要字段（name, description, argument-hint, allowed-tools, model, effort）
- [ ] Process 章节完整描述执行步骤
- [ ] 输出的 plan 文档符合 `docs/detailed-design.md` 中定义的结构模板
- [ ] Task ID 规则（全局唯一 T{NNN}）在指令中有明确说明
- [ ] 前置条件检查（design 文档不存在时提示用户）
- [ ] 实际运行 `/forge:plan` 能产出合规的 `.forge/plan-*.md`

**规模预估：** medium

---

## Dependency Graph

```
T001 → T002
T001 → T003
T001 → T004
T001 → T003 → T005
```

T002、T003、T004 可在 T001 完成后并行执行。  
T005 在 T001 和 T003 完成后执行。

## Execution Order

1. T001（目录骨架）
2. T002 + T003 + T004（并行）
3. T005（plan skill 完整实现）

## Risk Register

| Task | Risk | Mitigation |
|------|------|------------|
| T003 | frontmatter 格式不合法导致 skill 无法加载 | 参考官方 feature-dev 的格式严格验证 |
| T005 | plan skill 指令不够清晰，产出不符合规范 | 以本文档（plan-plugin-bootstrap.md）的产出质量作为验收基准 |
