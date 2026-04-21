# Constraints & Anti-Patterns: forge

> 生成时间：2026-04-19
> 最近人工更新：2026-04-20（新增 TD-007：skill `--audit` 支持）
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate，或针对具体规则做人工补充
> 文件路径：.forge/context/constraints.md

**Important:** 本文件列出 Forge 插件开发的硬性约束和已知反模式。
另见：context/conventions.md、context/architecture.md、context/testing.md

---

## Hard Constraints

这些约束没有例外。违反任何一条都是 `must-fix` 级别问题。

### C1 — Status 脚本是唯一路由权威

`skills/forge/scripts/status.mjs` 是编排器路由的唯一依据。
forge skill 必须执行此脚本并读取其 `[ACTION]` 输出，不可自行判断下一步。

**违反表现：** forge skill 通过读取 `.forge/` 文件自行推断状态，绕过 status.mjs。

### C2 — 交互消息必须使用小写前缀

所有面向用户的消息前缀格式为 `[forge:{skill-name}]`，全小写。

**违反表现：** `[FORGE:CALIBRATE]`、`[Forge:Code]` 等格式。

**当前已知违规位置（待修复）：**
- `skills/tasking/SKILL.md` — Step 6 使用 `[FORGE:TASKING]`（大写）
- `skills/tasking/SKILL.md` — Prerequisites 中使用 `[FORGE:TASKING]`（大写）

### C3 — 产物路径必须使用嵌套结构

所有 `.forge/` 产物必须遵守以下路径规范：

```
.forge/context/{filename}.md         # 项目级上下文
.forge/features/{slug}/{filename}.md # Feature 级产物
.forge/features/{slug}/tasks/T{NNN}-summary.md  # Task 摘要
```

**禁止使用旧的平铺结构：**
- ❌ `.forge/conventions.md`（应为 `.forge/context/conventions.md`）
- ❌ `.forge/clarify-{slug}.md`（应为 `.forge/features/{slug}/clarify.md`）
- ❌ `.forge/design-{slug}.md`（应为 `.forge/features/{slug}/design.md`）

**当前已知违规位置（待修复）：**
- `agents/forge-architect.md:24` — 引用 `.forge/clarify-{slug}.md`（旧路径）
- `agents/forge-architect.md:32` — 引用 `.forge/conventions.md`（旧路径）

### C4 — Skill 引用必须使用当前名称

`tasking`（非 `plan`）和 `inspect`（非 `review`）是当前正确名称，
用于避免与 Claude Code 内置命令冲突。

**当前已知违规位置（待修复）：**
- `agents/forge-reviewer.md:7` — 描述中写 "Used by /forge:review"（应为 /forge:inspect）
- `skills/test/SKILL.md` description — "Use after /forge:review"（应为 /forge:inspect）

### C5 — Inspect skill 不修改任何源文件

`inspect` skill 严格只读。它不可建议修复也不可应用修复。
评审结果只写入 `.forge/features/{slug}/inspect.md`。

### C6 — Code skill 不超出任务范围

`code` skill 在执行时只可修改 `plan.md` 中该 task 明确列出的文件。
如果发现需要修改额外文件，必须触发 Scope Creep Protocol，暂停并询问用户。

### C7 — Agent 层不直接写文件

`forge-explorer`、`forge-architect`、`forge-reviewer` 只返回报告文本。
由调用 skill（clarify/design/inspect）负责将内容写入产物文件。

### C8 — 严禁在任何产物中泄漏非 forge 的真实项目信息

**范围：** commit 消息（subject / body / footer）、所有仓库文档
（`README.md`、`CLAUDE.md`、`docs/**`）、所有 SKILL.md 和 reference 文件、
所有 agent 文件、所有脚本注释、所有 `.forge/` 产物（例外见下）。

**禁止内容：**
- 外部公司、产品、品牌名
- 外部内部系统缩写（不在公开文档中出现的 3–5 字母系统名）
- 外部 Java/Go/Python 包命名空间（`com.{company}.*` 格式）
- 外部基础设施主机、registry 域名、生产端口、生产 schema 名
- 外部数据库/表名、生产 URL、生产 feature slug

**允许内容：**
- Forge 自身的标识符（skill 名、agent 名、artifact 路径等）
- 公开开源工具与协议名（Spring Boot、MySQL、Nacos、REST 等）
- 通用业务名词（`Order`、`Customer`、`Payment`）
- `com.example.*` 命名空间、`{placeholder}` 占位符

**例外：** `.forge/context/onboard.md` 的自举产物（forge 描述自身时）可以
使用 forge 的真实标识符——因为 forge 就是"目标项目"。

**观察来源：** 本约束由 commit `b1f1f8b` 事件触发（之前的 `bd87103` +
`60d309f` 把 AI 辅助开发目标项目的私有标识符带入了公开仓库）。

**违反表现：**
- Commit message 提及具体公司/产品
- 示例代码中出现 `com.{brand}.{product}.*` 包路径
- 文档中用具体 registry 域名代替占位符
- 模板示例沿用真实业务类名（如源自某个特定项目的 `FooBarServiceImpl`）

**修复流程：** 见 `conventions.md` § Content Hygiene §「泄漏后的补救流程」。

### 通用示例调色板

新增任何示例时，优先使用 `conventions.md` § Content Hygiene 中的
"通用示例调色板"（e-commerce order platform 域），以确保跨文档一致性。

---

## Anti-Patterns

这些是在 Forge 代码库中发现的已存在模式，**新代码不应复制**。

### AP1 — 大写交互消息前缀

**现状：** `skills/tasking/SKILL.md` 中使用 `[FORGE:TASKING]` 大写格式。
**问题：** 违反 Decision #1（用户明确要求小写，输入方便）。
**修复：** 将所有 `[FORGE:{SKILL}]` 改为 `[forge:{skill}]`。

### AP2 — 旧平铺路径引用

**现状：** `agents/forge-architect.md` 中引用 `.forge/clarify-{slug}.md` 和 `.forge/conventions.md`。
**问题：** 这些是旧的平铺路径格式，已被嵌套路径取代。Agent 读取这些路径时会找不到文件。
**修复：** 更新为 `.forge/features/{slug}/clarify.md` 和 `.forge/context/conventions.md`。

### AP3 — 过时的 skill 名称引用

**现状：** `agents/forge-reviewer.md` 和 `skills/test/SKILL.md` 中引用 `/forge:review`。
**问题：** skill 已重命名为 `inspect`，`/forge:review` 不存在。
**修复：** 更新为 `/forge:inspect`。

### AP4 — Skill 中内联完整约定

**现状（未发现但需预防）：** 某个 skill 在自身 SKILL.md 中重复定义了 conventions.md 中的规则。
**问题：** 两处定义会发生漂移，产生矛盾。
**正确做法：** Skill 应引用 `context/conventions.md`，而不是内联规则。

### AP5 — 私有项目标识符污染示例

**现状（已发生，commit `b1f1f8b` 修复）：** skill 模板和示例中直接使用了
AI 辅助开发过程中接触到的目标项目的类名、包路径、基础设施域名。
**问题：**
- 把私有项目信息带入公开仓库（潜在泄密）
- 示例与其他项目场景不匹配，降低模板通用性
- 读者被特定领域词汇（例如内部系统缩写）干扰，注意力被拉偏

**正确做法：** 所有示例从 conventions.md § Content Hygiene §「通用示例
调色板」取值（当前推荐：e-commerce order platform 作为示范域）。

---

## Known Technical Debt

| ID | 位置 | 描述 | 优先级 |
|----|------|------|--------|
| TD-001 | `skills/tasking/SKILL.md` | 交互消息使用大写 `[FORGE:TASKING]` | 高 |
| TD-002 | `agents/forge-architect.md:24,32` | 引用旧的平铺路径格式 | 高 |
| TD-003 | `agents/forge-reviewer.md:7` | 引用已废弃的 `/forge:review` | 高 |
| TD-004 | `skills/test/SKILL.md` description | 引用已废弃的 `/forge:review` | 高 |
| TD-005 | 全部 skills | 系统性排查是否还有其他大写消息前缀 | 中 |
| TD-006 | commit / doc / 示例 | 建立 pre-commit 自动化扫描脚本，检测私有项目标识符泄漏（C8 当前靠人工 grep） | 中 |
| TD-007 | 全部 skills | 增加 `--audit <slug>` 只读模式：读对应 artifact + 当前 IRON RULES → 产出 `{slug}/audit-{date}.md` 合规报告（不自动修）；配套 `/forge:forge --audit-all` 批量走查 | 中 |

---

## Scope Boundaries

明确列出哪些内容**不在 Forge 的职责范围内**：

| 超出范围 | 原因 |
|---------|------|
| 执行测试 | Forge 分析和生成代码，不运行测试 |
| 部署 | 无部署 skill，不涉及 CI/CD |
| 数据库迁移执行 | 可生成迁移脚本，但不执行 |
| 代码格式化 | 由项目自身的 linter 负责，Forge 不干预 |
| Git 操作 | Forge 不提交、不推送、不创建分支 |
