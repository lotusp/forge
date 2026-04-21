# Project Conventions: forge

> 生成时间：2026-04-19
> 最近人工更新：2026-04-20（新增 Skill Rule Evolution 节 + Decision #8）
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate，或针对具体规则做人工补充
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

## Content Hygiene

> 所有面向外部的文字内容（commit message、文档、SKILL.md 示例、reference 文件、
> agent 文件、测试夹具）必须使用**中性的、通用的、虚构的**示例标识符。
> **除 forge 自身之外**，不得出现任何其他真实项目、公司、产品、系统的名称。

### 适用范围

| 类型 | 具体包含 |
|------|----------|
| Commit 消息 | Subject + Body + footer |
| 仓库文档 | `README.md`、`CLAUDE.md`、`docs/**/*.md` |
| Skill 文件 | `plugins/forge/skills/**/SKILL.md`、`reference/*.md` |
| Agent 文件 | `plugins/forge/agents/*.md` |
| Artifact 模板 | `output-template.md`、`scan-patterns.md`、`incremental-mode.md` |
| 脚本文件 | `scripts/*.mjs` 中的注释和示例 |
| `.forge/` 产物 | `.forge/context/*.md`、`.forge/features/**/*.md` |

### 什么可以出现

| 类别 | 允许值 | 示例 |
|------|--------|------|
| Forge 自身标识符 | skill 名、agent 名、artifact 文件名、目录结构 | `onboard`、`forge-explorer`、`clarify.md`、`.forge/context/` |
| 公开开源工具 | 通用技术栈名称，无品牌敏感性 | `Spring Boot`、`MySQL`、`Redis`、`Feign`、`Flyway`、`Nacos`、`Togglz`、`WireMock`、`Testcontainers` |
| 通用生态术语 | 行业中立的架构/协议术语 | `REST`、`Webhook`、`Message Queue`、`Feature Toggle` |
| Claude Code 生态 | 官方产品名 | `Claude Code`、`Anthropic API`、`claude.ai/code` |

### 什么必须避免

| 类别 | 禁止值 | 替换为 |
|------|--------|--------|
| 公司名 | 任何真实公司（特别是 forge 的 AI 辅助开发目标用户的雇主） | 省略，或 `{company}` 占位符 |
| 产品名 | 任何其他真实产品/系统 | 通用业务名词（如 `order`、`catalog`、`inventory`） |
| 内部系统缩写 | 外部不可识别的 3–5 字母全大写缩写（来自具体项目的内部系统名） | 可识别的功能描述（如 `Payment Gateway`、`Vendor Catalog Feed`） |
| Java 包命名空间 | `com.{company}.*`、`com.{brand}.*` | `com.example.*` |
| 基础设施主机 | 具体的 registry / endpoint 域名 | `registry.example.com`、`{registry-host}` 占位符 |
| 实际 schema 名 | 生产数据库 schema | 通用名（`shop_orders`）或 `{schema-name}` |
| 实际端口号 | 生产端口 | `{N}` 或 `8080` 等大众默认值 |
| 实际 feature slug | 真实业务特性名 | `phone-verification`、`order-export-csv` 等泛用示例 |

### 通用示例调色板（推荐沿用）

为保持跨文档一致性，**所有新增示例优先从下表取值**：

| 领域 | 标识符 |
|------|--------|
| 示例业务域 | 通用电商订单平台（e-commerce order platform） |
| Java 包基址 | `com.example.shop` |
| 服务名 | `order-service` |
| 聚合根 | `Order`、`LineItem`、`Customer`、`Payment`、`PromotionProgram` |
| 枚举 | `OrderStatus: DRAFT → SUBMITTED → CONFIRMED → SHIPPED → DELIVERED` |
| Controller | `OrderController`、`PaymentController` |
| Service | `OrderService`、`PaymentService` |
| Feign client | `InventoryClient`、`ShippingClient`、`NotificationClient`、`ReportingClient` |
| Event | `OrderPlacedEvent`、`OrderConfirmedEvent`、`OrderCancelledEvent` |
| Listener | `OrderPlacedListener`、`FulfilmentInitListener`、`ShippingDispatchListener` |
| 外部系统 | Payment Gateway、Notification Service、Warehouse Scheduler、Customer Data Platform、Vendor Catalog Feed |
| 占位域名 | `registry.example.com`、`api.example.com` |
| 占位命名空间 | `com.example.internal:*`（私有仓标识符） |
| 占位路径 | `{project-root}`、`{module}`、`{vendor-name}` |

### Commit 提交前的自检

在 `git commit` 之前手动运行：

```bash
# 检查当前工作区是否混入非 forge 项目标识符
# （补充自己熟悉的企业/产品名到 pattern 里）
git diff --cached | grep -iE "{company-patterns}|{product-patterns}" \
  && echo "⚠ 发现可疑标识符，清理后再提交" \
  || echo "✓ 可提交"
```

不强制在 hook 里执行（forge 当前无 git hook 基础设施），但任何 AI 辅助提交
前必须做一次人眼 diff review。

### 泄漏后的补救流程

1. **commit 消息已泄漏** → 需要 rebase/force-push（仅限仓库 owner 协调，
   普通用户严禁自行 force-push）
2. **仅工作区文件泄漏，未 push** → `git commit --amend` 清理后提交
3. **已 push 但 commit 消息干净，仅文件内容泄漏** → 前向修复 commit
   （新 commit 清理 + 明确说明泄漏上下文），**不**重写历史

本次泄漏修复采用方式 3（见 commit `b1f1f8b`）——历史消息本来就干净，
只需前向修复即可。

### 反面清单的陷阱（元规则）

**写"禁止使用 X"时，列举真实的 X 本身就泄漏 X。**

正确姿势：用**类别描述** + **无害占位符**，不要把真实违规案例写进文档。

错误写法（反例）：
> 禁止使用 `XYZ_ACRONYM_FROM_REAL_PROJECT` 这种内部缩写

正确写法：
> 禁止使用外部不可识别的 3–5 字母全大写缩写（来自具体项目的内部系统名）

### 例外

Forge 在自举场景下，`.forge/context/onboard.md` 会描述 forge 自己作为
"项目"。此时使用 forge 自身的标识符（`forge-explorer`、`/forge:onboard`、
`plugins/forge/skills/*` 等）是允许的，因为 forge 就是 THE 项目。

---

## Skill Rule Evolution & Artifact Compliance

> Skill 的 IRON RULES / Process / Output 要求随着项目认知演进会发生变化。
> 之前已生成的 `.forge/` 产物（onboard.md、clarify.md、design.md 等）**不会
> 自动跟随**。本节定义变更发生时的责任分配与流程。

### 三条规则

**R1 — Skill IRON RULES 变更等同于 breaking change。**
当 `plugins/forge/skills/{name}/SKILL.md` 的 IRON RULES 节发生新增、删除
或语义修改时：

- 必须 bump 至少 patch 版本（`plugin.json` 的 `version`）
- 必须在同一 commit 中说明受影响的 artifact 类型
- 若变更影响语义（非仅排版），须在 `JOURNAL.md` 明示"此变更触发下游审计"

**R2 — 变更 commit 必须附带同期的 artifact 审计。**
Skill 规则变更后、进入下一个 feature 之前，必须对当前仓库所有同类型 artifact
做一次人工审计：

```
受影响 skill = X
审计目标 = .forge/features/*/X.md + （若适用）.forge/context/{X 对应的 context 文件}.md
判据 = 变更后的 SKILL.md 全部 IRON RULES
```

审计产出三种动作之一：

| 动作 | 适用场景 |
|------|---------|
| **Rewrite** | Artifact 有违规点，有明确修正路径 |
| **Regenerate** | 违规点多 / 结构需重构，重新跑对应 skill 更经济 |
| **Preserve with exception** | 旧 artifact 代表历史状态，不应改写；用 `<!-- preserve -->` 块标记，在 JOURNAL 记录例外理由 |

**R3 — 审计结果必须记录 JOURNAL。**
每次 skill 变更后的审计都在 `JOURNAL.md` 追加一条形如：

```markdown
## YYYY-MM-DD — {skill} 合规审计 (触发：{variant commit hash})
- 审计范围：{列出检查的 artifact 文件}
- 发现：{N 条违规}
- 动作：{rewrite/regenerate/preserve-with-exception 分布}
- 修正 commit：{后续修正的 commit hash；若本次同步修 → 同 commit}
```

### 执行模式的演进路径

| 阶段 | 模式 | 说明 |
|------|------|------|
| **现在** | 纯人工审计 | Skill 改动较少，artifact 数量有限；审计者把 SKILL.md 当 checklist 手工对照 |
| **中期** | Skill 提供 `--audit <slug>` | 每个 skill 加只读审计模式：读 artifact + 当前 IRON RULES，产 `{slug}/audit-{date}.md` 报告（见 `constraints.md` TD-007） |
| **远期** | `/forge:forge --audit-all` 批量 | 全仓走查；CI 集成阻塞非合规发布 |

### 元规则

- 本节本身是"规则的规则"。如果未来变更了这里的三条规则（R1/R2/R3），同样
  触发一次本节审计（审计自己是否还覆盖变更后的情况）。
- 若跳过审计（例如紧急修复），JOURNAL 必须显式记录"跳过原因"；下次 skill
  变更时补做。

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
| 7 | 内容洁净原则 | Commit message + 文档 + 示例代码 均使用中性/虚构标识符；除 forge 自身外禁止提及任何真实项目 | 防止 AI 辅助开发场景下把目标项目信息泄漏进 forge 公开仓库（已有先例：commit `b1f1f8b` 清理） |
| 8 | Skill 规则演进与 artifact 合规 | Skill IRON RULES 变更 = breaking；变更 commit 必须附带同期 artifact 审计；审计结果记录 JOURNAL | 变更发生时的责任边界清晰；防止规则与产物长期不同步；为未来工具化（`--audit` flag）留下约定基础（已有先例：commit `52f2e75` 新增 Q&A 边界规则后 `2bd25b3` 审计修正 T3 clarify.md）|

---

## Open Questions

| 维度 | 问题 | 影响 |
|------|------|------|
| effort 取值 | `max` 和 `high` 的边界定义不明确 | 影响 calibrate（max）与其他 high skill 的资源分配 |
