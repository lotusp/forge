# Project Conventions: forge

> 生成时间：2026-04-19
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate
> 文件路径：.forge/context/conventions.md

**Important:** 本文件是 Forge 插件自身开发的权威约定。
/forge:code、/forge:inspect、/forge:test 均以此文件为基准。
另见：context/testing.md、context/architecture.md、context/constraints.md

---

## Naming Conventions

### Skill 名称
- 全小写，无连字符，单个英文单词或缩写
- 示例：`onboard`、`calibrate`、`tasking`、`inspect`
- 避免与 Claude Code 内置命令重名（如 `plan`、`review` 已被占用）
- 观察来源：`skills/*/SKILL.md` frontmatter `name` 字段（全部 9 个 skill）

### Agent 名称
- 格式：`forge-{role}`，带连字符，全小写
- 示例：`forge-explorer`、`forge-architect`、`forge-reviewer`
- 观察来源：`agents/*.md` frontmatter `name` 字段

### 文件名
- SKILL.md：固定名称，每个 skill 目录一个
- Agent 文件：`forge-{role}.md`，位于 `agents/` 目录
- 脚本文件：kebab-case，`.mjs` 扩展名（`check-prerequisites.mjs`、`status.mjs`）
- 参考文档：`output-template.md`、`dimensions.md`、`conflict-examples.md`

### Feature Slug
- 格式：2–4 个英文单词，kebab-case
- 示例：`plugin-bootstrap`、`phone-verification`、`order-export-csv`

### Task ID
- 格式：`T{NNN}`，三位数字，零填充，全局唯一
- 示例：`T001`、`T023`、`T100`
- 全局唯一：跨所有 feature 的 plan.md，不可重置或复用
- 观察来源：`skills/tasking/SKILL.md` IRON RULES

---

## SKILL.md Format

### Frontmatter 必填字段

```yaml
---
name: <skill-name>
description: |
  多行描述，首行是一句话摘要（显示在 /skills 列表中）。
  后续行补充使用时机和前置条件。
argument-hint: "<hint>"      # 无参数时为空字符串 ""
allowed-tools: "Tool1 Tool2" # 空格分隔，带引号
model: sonnet
effort: high                 # high / medium / max
---
```

### Frontmatter 可选字段

```yaml
context: fork   # 需要子会话时加（当前使用：onboard、inspect）
agent: Explore  # 委托给内置 agent 时加（当前使用：onboard）
```

### 章节顺序（强制）

1. `## Runtime snapshot`
2. `## IRON RULES`
3. `## Prerequisites`
4. `## Process`（包含 `### Step N` 子节）
5. `## Output`
6. `## Interaction Rules`
7. `## Constraints`

允许在 Process 和 Output 之间插入协议节（如 `## Scope Creep Protocol`）。

### Runtime snapshot 格式

```markdown
## Runtime snapshot
- 标签描述: !`bash命令 2>/dev/null || echo "(none)"`
```

- 每行一个检测项；命令失败时用 `|| echo "(fallback)"` 给出友好默认值

### IRON RULES 格式

```markdown
## IRON RULES

These rules have no exceptions.

- **规则名称。** 规则描述，说明 why。
```

- 规则名称加粗，以句点结尾，与描述在同一段落内

---

## Agent File Format

### Frontmatter

```yaml
---
name: forge-{role}
description: |
  一句话描述职责。
  第二行：调用方式和使用时机。
tools: Tool1, Tool2, Tool3   # 逗号分隔，无引号
model: sonnet
color: yellow                 # yellow(explorer) / green(architect) / red(reviewer)
---
```

### 正文结构顺序

1. `## Input` — 编号列表，列出接收的输入项
2. `## Process` — 分阶段（`### Phase 1 …`）
3. `## Output Format` — 返回报告的精确格式（含填充示例）
4. `## Rules` — agent 级别的硬性约束

---

## User Interaction Format

### 消息前缀
- 格式：`[forge:{skill-name}]` — **全小写**，与命令调用风格一致
- 示例：`[forge:calibrate]`、`[forge:code]`、`[forge:tasking]`
- 观察来源：裁决 #1（原为全大写，用户要求改为小写）

### 选项呈现格式

```
[forge:{skill}] {标题}

{说明段落}

Options:
  1. {选项 A}（recommended）
  2. {选项 B}

Your choice:
```

### 矛盾裁决格式（calibrate 专用）

```
[forge:calibrate] Convention conflict {N} of {M}

Dimension: {维度名}

Pattern A — used in {Module}:
  {描述}（{file:line}）

Pattern B — used in {Module}:
  {描述}（{file:line}）

Recommendation: Pattern A
Reason: {推荐理由}

Options:
  1. Adopt Pattern A（recommended）
  2. Adopt Pattern B
  3. Allow both — context-dependent
  4. Neither — describe what you want
```

---

## Artifact Format

### 文件头（所有 .forge/ 产物必须包含）

```markdown
# {Artifact Type}: {feature-slug 或 project-name}

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:{skill-name}
> 文件路径：.forge/{相对路径}
```

### 产物路径规范

| 产物 | 路径 |
|------|------|
| 活动日志 | `.forge/JOURNAL.md` |
| 项目地图 | `.forge/context/onboard.md` |
| 代码约定 | `.forge/context/conventions.md` |
| 测试约定 | `.forge/context/testing.md` |
| 架构约定 | `.forge/context/architecture.md` |
| 约束规则 | `.forge/context/constraints.md` |
| 需求分析 | `.forge/features/{slug}/clarify.md` |
| 技术设计 | `.forge/features/{slug}/design.md` |
| 任务列表 | `.forge/features/{slug}/plan.md` |
| 评审结果 | `.forge/features/{slug}/inspect.md` |
| 测试计划 | `.forge/features/{slug}/test.md` |
| 实现摘要 | `.forge/features/{slug}/tasks/T{NNN}-summary.md` |
| 会话状态 | `.forge/_session/calibrate-scan.md` |

### JOURNAL.md 条目格式

每个 skill 执行后强制追加，条目由新到旧（追加到文件末尾）：

```markdown
## YYYY-MM-DD — /forge:{skill} {arg}
- 产出：{主产物文件}
- {skill-specific key metric, e.g. 假设/任务/发现数量}
- 下一步：{recommended next command}
```

**关键规则：**
- 每次 skill 执行追加一条，不修改已有条目
- forge 编排器（`/forge:forge`）在 Runtime snapshot 中读取末尾 30 行作为会话上下文
- 不删除、不重写日志；错误记录也保留（便于追溯）

---

## Decision Log

| # | 维度 | 裁决 | 理由 |
|---|------|------|------|
| 1 | 交互消息格式 | `[forge:{skill}]` 全小写 | 与命令调用风格一致，输入方便 |
| 2 | Skill 命名 | `tasking`（非 `plan`），`inspect`（非 `review`） | 避免与 Claude Code 内置命令冲突 |
| 3 | 产物结构 | `context/` + `features/{slug}/` 嵌套 | 多功能项目清晰，避免根目录堆积 |
| 4 | allowed-tools 格式 | 空格分隔带引号字符串 | Claude Code 解析格式要求 |
| 5 | Agent tools 格式 | 逗号分隔无引号 | Agent frontmatter 格式要求 |
| 6 | 会话连续性 | JOURNAL.md 强制追加 + task summary Assumptions Made 章节 | 解决 AI 冷启动和隐性假设可追溯问题 |

---

## Open Questions

| 维度 | 问题 | 影响 |
|------|------|------|
| effort 取值 | `max` 和 `high` 的边界定义不明确 | 影响 calibrate（max）与其他 high skill 的资源分配 |
