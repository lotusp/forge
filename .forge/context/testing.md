# Testing Conventions: forge

> 生成时间：2026-04-19
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate
> 文件路径：.forge/context/testing.md

**Important:** 本文件是 Forge 插件测试约定的权威基准。
另见：context/conventions.md、context/architecture.md、context/constraints.md

---

## Testing Philosophy

Forge 是一个纯 Markdown 插件，无可执行应用代码，因此无法使用传统单元测试框架。
**Forge 的"测试"等同于手动验收场景验证**，核心问题是：

> 当用户在真实项目中调用 `/forge:{skill}`，Claude 是否按预期行为执行？

---

## What Counts as a Test

### 1. Scenario Validation（主要测试形式）

在一个真实（或模拟）的目标代码库中端到端执行 skill，验证：

- Skill 在正确前置条件下能正常完成
- Skill 在缺少前置条件时能友好报错
- 产物文件格式符合 `output-template.md` 规范
- IRON RULES 被遵守（不可绕过的约束）

**记录形式：** `.forge/features/{slug}/test.md`（由 `/forge:test` 生成）

### 2. Artifact Structure Validation（脚本辅助）

`skills/calibrate/scripts/validate-output.mjs` 对 calibrate 产物结构做机器验证：

- 4 个 context 文件均存在
- 文件头格式正确（生成时间、生成方式、文件路径）
- 关键章节（如 Decision Log）存在

其他 skill 目前无对应脚本，靠手动检查。

### 3. IRON RULES Compliance Check

每个 skill 的 IRON RULES 是最高优先级验证项，验证时需明确确认每条规则：

| Skill | 关键 IRON RULES |
|-------|----------------|
| forge | status 脚本是唯一路由权威，不可绕过 |
| tasking | Task ID 全局唯一，不可复用 |
| inspect | 置信度 <80 的发现必须丢弃；所有 agent 必须并发 spawn |
| code | 不可超出任务范围；新模式须经 New Pattern Protocol 确认 |
| calibrate | 每次矛盾必须逐一裁决；不可发明约定 |

---

## Test Scenarios per Skill

### `/forge:onboard`

| 场景 | 验证点 |
|------|--------|
| 首次运行（无 `.forge/` 目录） | 产出 `onboard.md`，含 What This Is、Tech Stack、Module Map、Entry Points、Local Dev |
| 已有 `onboard.md` | 展示选项菜单（再生成 / 查看退出） |
| CLAUDE.md 存在 | 内容反映在 Notes 或修正推断 |

### `/forge:calibrate`

| 场景 | 验证点 |
|------|--------|
| 首次运行 | 逐一裁决矛盾，确认无矛盾模式，产出 4 个 context 文件 |
| 已有 `conventions.md` | 展示选项菜单（重新校准 / 扩展 / 退出） |
| 无矛盾代码库 | 跳过裁决步骤，直接确认模式 |

### `/forge:clarify <需求>`

| 场景 | 验证点 |
|------|--------|
| 正常需求 | 产出 `clarify.md`，含未知项列表和探索记录 |
| 需求模糊 | 暂停并向用户提问，不猜测 |

### `/forge:tasking <slug>`

| 场景 | 验证点 |
|------|--------|
| 正常流程 | 先展示任务列表待确认，确认后写 `plan.md` |
| 缺少 `design.md` | 友好报错，提示先运行 `/forge:design` |
| 已有其他 feature 的任务 | 新 Task ID 从全局最高值续编 |

### `/forge:inspect <slug>`

| 场景 | 验证点 |
|------|--------|
| 正常流程 | 所有 forge-reviewer agent 并发 spawn；置信度 <80 发现被丢弃 |
| 无变更文件 | 不产出空 inspect.md |
| 文件路径参数 | 仅评审该文件 |

---

## How to Run a Test Scenario

1. 在一个真实项目（或专为测试创建的 fixture 目录）中安装 Forge
2. 清除 `.forge/` 目录（按场景要求设置初始状态）
3. 在 Claude Code 中调用对应 `/forge:{skill}`
4. 对照验证点逐项检查产物和交互行为
5. 发现问题时在对应 skill 的 SKILL.md 中修正流程描述或 IRON RULES

---

## Anti-Patterns in Testing

- **不要用 Forge 本身的 `.forge/` 当测试 fixture**：自举目录有特殊语义，用独立 fixture 目录
- **不要跳过 IRON RULES 验证**：soft 问题可接受，IRON RULES 违反必须修复
- **不要手动生成产物再测试**：产物必须由 skill 真实执行产生，否则测不出 Claude 行为

---

## Open Questions

| 维度 | 问题 | 影响 |
|------|------|------|
| 自动化验证 | 是否可为所有 skill 的产物格式编写 validate 脚本 | 减少手动检查负担 |
| Fixture 管理 | 是否维护一个标准 fixture 目标项目供重复测试 | 提升场景重现性 |
