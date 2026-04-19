# Project Conventions: forge

> 生成时间：2025-01-01
> 生成方式：手工补录（自举阶段跳过了 /forge:calibrate）
> 文件路径：.forge/context/conventions.md

**Important:** 本文件定义 Forge 插件自身开发的约定。这不是某个目标项目的约定，
而是 Forge 这个 Claude Code 插件在编写 SKILL.md 和 agents/*.md 时遵循的规范。
参见 `skills/calibrate/reference/output-template.md` 了解目标项目的完整格式。

---

## SKILL.md 写作约定

### Frontmatter 字段

```yaml
---
name: <skill-name>           # 与目录名一致
description: |               # 多行，供 /skills 列表展示
  ...
argument-hint: "<hint>"      # 参数提示，空字符串表示无参数
allowed-tools: "..."         # 空格分隔的工具名列表
model: sonnet                # 默认 sonnet
effort: high / medium / max
context: fork                # 仅在需要子 session 时加（如 inspect）
agent: Explore               # 仅在委托给 agent 时加（如 onboard）
---
```

### 正文结构顺序

1. `## Runtime snapshot` — bash `!` 命令，获取运行时项目状态
2. `## IRON RULES` — 无例外的硬性约束
3. `## Prerequisites` — 前置条件检查
4. `## Process` — 分步执行流程（Step 1 … Step N）
5. `## Output` — 产物路径和格式说明
6. `## Interaction Rules` — 与用户交互的规则
7. `## Constraints` — 约束条件

### 命名约定

- Skill 名称：小写，不含连字符（`tasking`、`inspect`、`forge`）
- 产物路径：`.forge/context/{name}.md` 或 `.forge/features/{slug}/{name}.md`
- Task ID：全局唯一，零填充三位（`T001`、`T002`...）
- Feature slug：2–4 个英文单词，kebab-case（`plugin-bootstrap`）

---

## Agent 写作约定

Agent 文件位于 `agents/` 目录，YAML frontmatter 字段：

```yaml
---
name: forge-{role}
description: |
  ...
tools: Read Glob Grep Bash   # 仅列出需要的工具
model: sonnet
color: yellow / green / red  # 三个 agent 各一种颜色
---
```

---

## 决策日志

| # | 维度 | 决策 | 理由 |
|---|------|------|------|
| 1 | Skill 命名 | `tasking`（非 `plan`）、`inspect`（非 `review`） | 避免与 Claude Code 内置命令冲突 |
| 2 | 产物结构 | `context/` + `features/{slug}/` 嵌套结构 | 多功能项目下更清晰，避免根目录文件堆积 |
| 3 | 约定文件 | calibrate 产出 4 个文件（非 1 个） | 关注点分离：约定 / 测试 / 架构 / 约束 各自独立 |
| 4 | 编排器 | 新增 `forge` skill 作为主入口 | 降低入门门槛，用户无需了解完整工作流顺序 |
