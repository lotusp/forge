# Design: onboard-kind-profiles

> 基于：features/onboard-kind-profiles/clarify.md + design-inputs.md + context/conventions.md + context/constraints.md
> 生成时间：2026-04-20
> 生成方式：/forge:design — 用户确认 Option C + OQ 裁决
> 文件路径：.forge/features/onboard-kind-profiles/design.md

---

## Solution Overview

将 `/forge:onboard` 从**单模板固定流程**改为**两级 Process 架构**：

1. **Plan 生成层（Step 1）—** kind detection + 从选定 kind 文件的 frontmatter
   读取有序 profile 列表及可选的 `iron_rules_overlay`，形成本次 run 的
   execution plan。
2. **Plan 执行层（Step 2）—** 对 plan 中的每个 profile 执行
   read-do-discard 循环：Read profile 文件 → 应用 scan 规程 → 渲染
   section → 写入 artifact（含 marker）→ (若 --thorough) self-critique
   → 显式"放手"进入下一轮。

配套建立两类小颗粒度 reference 文件：3 个 **kind 定义** + 17 个
**profile 文件**，替代 v0.3.0 的单一 `output-template.md`。

此架构以**最小 SKILL.md 常驻体积 + 按需 Read profile** 实现 DG1（渐进加
载），以**每 profile 显式 checkpoint** 实现 DG2（长上下文稳定），以**每
profile 自带 golden-path + 压缩 IRON RULES 提醒** 实现 DG3（生成质量）。

---

## Approach Options

三种 Process 编排风格对比（详细分析见本 feature 的设计讨论；用户确认 C）：

| Option | 描述 | Pros | Cons | Verdict |
|--------|------|------|------|---------|
| A — Execution Plan 循环 | SKILL.md 仅有 4 步抽象循环；kind 文件驱动一切 | 极简；加 profile 不改 SKILL.md | SKILL.md 看不出本次会做什么；可读性差 | ❌ 舍弃 |
| B — 静态 Directive 枚举 | SKILL.md 明确列出每个可能 profile 的 step | 自文档；可读性好 | 加 profile 必改 SKILL.md；样板冗余；token 膨胀 | ❌ 舍弃 |
| C — 两级 Process | 先生成 plan（Step 1），再 plan-driven 循环（Step 2，含 a-f 子步骤显式） | Token 优（A 继承）+ checkpoint 清晰（DG2）+ 规则就近 | 引入"execution plan"中间概念；Process 概念略升级 | ✅ 选用 |

---

## Component Changes

### New Components

#### Kind 定义（3 个）

| Path | Layer | Type | Responsibility |
|------|-------|------|----------------|
| `plugins/forge/skills/onboard/reference/kinds/web-backend.md` | skill reference | kind 定义 | HTTP 服务端框架（Spring / Express / FastAPI / Gin / 等）的信号集 + profile 引用序列 + 可选 IRON RULES overlay |
| `plugins/forge/skills/onboard/reference/kinds/claude-code-plugin.md` | skill reference | kind 定义 | 检测 `.claude-plugin/` 结构；使用 plugin 专属 profile |
| `plugins/forge/skills/onboard/reference/kinds/monorepo.md` | skill reference | kind 定义 | 检测 workspace/lerna/nx/turbo 等；引用 monorepo-package-graph profile |

**Kind 文件 frontmatter 约定**（Key Decision K-2）：

- `name`、`description`
- `detection_signals`：有序结构列表，每项含 `pattern` / `weight` / `where`
- `profiles`：有序 profile 名列表（含 "core/xxx" 子目录前缀）
- `iron_rules_overlay`（可选）：字符串数组，每条一规则；加载时 append 到 core IRON RULES

#### Profile 库（17 个）

位于 `plugins/forge/skills/onboard/reference/profiles/`，按功能子目录：

| 子目录 | 文件 | 适用 kind | 备注 |
|--------|------|----------|------|
| `core/` | `project-identity.md` | 所有 | 核心（OQ-03）|
| `core/` | `architecture-overview.md` | 所有 | 核心（OQ-03）|
| `core/` | `change-navigation.md` | 所有 | 核心（OQ-03）|
| `core/` | `local-development.md` | 所有 | 核心（OQ-03）|
| `core/` | `known-traps.md` | 所有 | 核心（OQ-03）|
| `core/` | `document-confidence.md` | 所有 | 核心（OQ-03，footer）|
| `structural/` | `codebase-structure-web-backend.md` | web-backend | Controllers/Services/Repositories 视角 |
| `structural/` | `codebase-structure-plugin.md` | claude-code-plugin | Skills/Agents/Scripts/Docs 视角 |
| `structural/` | `codebase-structure-monorepo.md` | monorepo | Workspace/Packages 视角 |
| `model/` | `domain-entities.md` | web-backend | 聚合根 + 状态机 + 领域事件（条件性，需发现 `@Entity`/`@Column`/等）|
| `model/` | `artifact-types.md` | claude-code-plugin | Artifact 类型 + 生产者/消费者关系 |
| `entry-points/` | `http-entry-points.md` | web-backend | Controller 路由 + 调用链 |
| `entry-points/` | `slash-command-entry-points.md` | claude-code-plugin | Slash command 列表 + 执行链 |
| `integration/` | `external-integrations.md` | web-backend | Feign client / HTTP client / 外部系统矩阵（条件性）|
| `integration/` | `internal-events.md` | web-backend | Spring `*Event` → 全 observer 映射（条件性）|
| `integration/` | `scheduled-jobs.md` | 任何 | `@Scheduled` / cron job（条件性）|
| `monorepo/` | `monorepo-package-graph.md` | monorepo | 包列表 + 每包 kind detection 结果 |

**Profile 文件结构**（DI-5 细化）：

- Frontmatter：`name`、`section_name`（决定 section marker 与 heading）、
  `description`、`applies_to_kinds`（documentation-only，不用于匹配；真正匹配由 kind 文件驱动）
- 正文固定 5+ 节：Scan Procedure / Template / N/A Rendering / Golden-Path
  Example / Compressed IRON RULES Reminder

#### Profile 索引

| Path | Layer | Type | Responsibility |
|------|-------|------|----------------|
| `plugins/forge/skills/onboard/reference/profiles/README.md` | skill reference | 索引 | 17 个 profile 的一句话目录 + 子目录说明；方便人工浏览 |

### Modified Components

| Path | What Changes | Why |
|------|-------------|-----|
| `plugins/forge/skills/onboard/SKILL.md` | **重写**为 Option C 的 4-step 结构：Step 0 run mode / Step 1 kind detection + plan / Step 2 plan execution loop (a-f) / Step 3 verification / Step 4 JOURNAL。IRON RULES 分 Core（常驻）与 kind overlay（Step 1 末附加）两层。 | 实现两级 Process；保持常驻体积小 |
| `plugins/forge/skills/onboard/reference/incremental-mode.md` | Section 名称从硬编码 10 项改为从 kind 文件的 `profiles` 列表派生；加"kind drift"处理（Key Decision K-7） | 适配 kind-dependent section 集 |
| `plugins/forge/skills/onboard/reference/scan-patterns.md` | 保留现有扫描模式表；profile 文件的 Scan Procedure 节通过 cross-reference 引用这里的模式（不复制）| 避免扫描模式在 17 个 profile 中重复 |
| `plugins/forge/.claude-plugin/plugin.json` | `version`: `0.3.1` → `0.4.0` | Breaking release per Q-2 |
| `README.md` | 版本徽章更新；新增"Kind-aware onboarding" 简介 | 用户感知入口 |
| `CLAUDE.md` | 目录树增补 `reference/kinds/` 和 `reference/profiles/` 子结构说明 | 保持 CLAUDE.md 与真实结构一致 |
| `.forge/context/onboard.md` | **重新生成**（通过 v0.4.0 skill 自举） | Success Criteria SC-1 验证 |
| `.forge/JOURNAL.md` | 追加 design / tasking / code / test 各阶段条目 | 工作流常规 |

### Deleted Components

| Path | Reason |
|------|--------|
| `plugins/forge/skills/onboard/reference/output-template.md` | v0.3.0 的单一 9-section 模板；内容已拆分进 17 个 profile 文件 |

---

## API Changes

`/forge:onboard` 命令参数扩展（具体 flag 名在 Key Decision K-8 / K-9 选定）：

| 参数 | 作用 | 交互 |
|------|------|------|
| **既有（保留）**：`--regenerate` | 全量重写（含 kind 重新检测） | 不变 |
| **既有（保留）**：`--section=<name>` | 单 section 刷新 | 若 `<name>` 不在当前 kind 的 profile 列表中，报错并列出有效 section 名 |
| **新增**：Kind 显式覆盖 flag（K-8） | 跳过 detection，直接用指定 kind | 若指定值不在已定义 kind 列表中，报错并列出可用 kind |
| **新增**：Opt-in 质量模式 flag（K-9） | 启用 self-critique | 见 OQ-01 处理方式 |

所有新 flag 的内部命名约定留到 tasking / code 阶段实现（per clarify skill IRON RULE：design 不指定具体 flag 字符串）。

**无**任何公开接口变更（forge 是 Claude Code plugin，所有交互经 slash command 层）。

---

## Data Model Changes

### `onboard.md` artifact header 扩展

**v0.3.0 header：**
```markdown
# Project Onboard: {project-name}
> Generated by: /forge:onboard
> Last run: {...}
> Verified against commit: {hash}
```

**v0.4.0 header（新增 3 行）：**
```markdown
# Project Onboard: {project-name}
> Generated by: /forge:onboard
> Last run: {...}
> Verified against commit: {hash}
> Detected kind: {kind-name}             ← 新增
> Kind file version: {hash-or-version}   ← 新增（kind 文件内容 hash；用于 kind 定义演进时识别过时 artifact）
> Profiles applied: {ordered list}       ← 新增
```

增量模式用 `Detected kind` 字段做 kind drift 检测（Key Decision K-7）。

### Section marker 格式（无变化）

```markdown
<!-- forge:onboard section=<name> verified=<commit> generated=<date> -->
```

但 `<name>` 的取值集合从 v0.3.0 的硬编码 10 项，变为从当前 kind 的
`profiles` 列表派生（每个 profile 的 `section_name` frontmatter）。

### `Document Confidence` footer 扩展

footer 增加 1 行："Detected kind: `<kind>`（confidence: `<primary-score>` / `<total>`）"，便于读者判断 onboarding 信息的适用范围。

---

## Impact Analysis

| Area | Risk | Description |
|------|------|-------------|
| `plugins/forge/skills/onboard/SKILL.md` | **High** | 整个 Process 重写；Run Mode 检测逻辑保留但细节变化。风险集中在 Step 1 kind detection 首次稳定性 |
| `plugins/forge/skills/onboard/reference/**` | **High** | 新建 17 个 profile + 3 个 kind 文件；首次内容质量是自举测试的核心变量 |
| `plugins/forge/.claude-plugin/plugin.json` | **Low** | 仅版本号变化 |
| Forge 其他 skills | **Low** | 不读 onboard.md 的具体 section 名，只读 `.forge/context/onboard.md` 存在性 + 头部元信息。section 重排不影响其他 skill |
| `.forge/context/onboard.md`（自举产物） | **Medium** | 必须通过 v0.4.0 自举再生成；若 v0.4.0 有 bug，产物会不合规 |
| 用户工作流 | **Low** | 首次升级会看到 kind detection 新步骤；若检测准确则无感切换 |
| 未来 kind 增补（Gap-09） | **Low** | 仅需新增 kind 文件 + 可选新 profile；不触 SKILL.md |
| 未来 monorepo 递归（Gap-08） | **Medium** | 本次架构留 4 条可扩展性要求（clarify § Monorepo Future-Proofing）；实际递归实现时仍需定义 `.forge/context/packages/` 结构 |

---

## Key Decisions

| # | Decision | Options Considered | Chosen | Rationale / 服务目标 |
|---|----------|--------------------|--------|-----------|
| K-1 | Process 编排风格 | A 抽象循环 / B 静态枚举 / C 两级 | **C 两级** | SKILL.md 精简 + checkpoint 清晰 + 规则就近（DG1+DG2+DG3）|
| K-2 | Kind 文件格式 | 纯 frontmatter / 全正文 / 混合 | **混合**：frontmatter 含 `detection_signals` / `profiles` / `iron_rules_overlay`；正文含人类可读的 kind 说明与设计理由 | Frontmatter 使 Step 1 只读 < 30 行/kind（DG1）；正文给人类上下文 |
| K-3 | Kind 检测算法 | 加权和 / 决策树 / 必需信号+加分 | **加权和 + tie-break 用户确认** | 最直观；低复杂度；OQ-02 的 0.6 比例阈值提供充足交互克制 |
| K-4 | Profile 文件组织 | 全平铺 / 子目录分组 | **子目录分组**（`core/` `structural/` `model/` `entry-points/` `integration/` `monorepo/`）| 17 个文件平铺难以浏览；子目录显性表达功能分类 |
| K-5 | Profile ↔ Kind 关联来源 | Profile 文件声明自己适用哪些 kind / Kind 文件声明引用哪些 profile | **Kind 文件单向声明** | 职责单向：kind 是"组装指令"，profile 是"纯功能块"；加新 kind 只新增 kind 文件，不动 profile |
| K-6 | IRON RULES overlay 合并 | 纯 append / ID 标识可替换 / tagged 合并 | **纯 append**（MVP）| MVP 够用；ID/tagged 复杂度高；未来需要替换时再升级 |
| K-7 | Kind drift 处理（incremental mode 下检测到 kind 变了）| 静默重检 / 阻塞并 prompt / 保留旧 kind | **Prompt 3 选项**：(1) `--regenerate` 以新 kind 重写 (2) 保留旧 kind 做 incremental (3) 手动 `--kind=<name>` 覆盖 | 保留用户控制；不自动破坏现有 artifact |
| K-8 | Kind 显式覆盖机制 | 环境变量 / flag / 配置文件 | **Flag**（具体名待 tasking 选定） | 交互式；与 Claude Code 其他参数风格一致 |
| K-9 | Opt-in 质量模式机制 | 环境变量 / flag / 配置文件 | **Flag**（具体名待 tasking 选定） | 同 K-8 |
| K-10 | OQ-01 `--thorough` 在 incremental 下语义 | 全量 / 仅 rewritten sections | **仅 rewritten sections 做 self-critique** | Incremental 的核心价值是"不动的不碰"；全量 critique 破坏语义 |
| K-11 | OQ-02 低置信度阈值 | 固定差值 / 固定比例 / 动态自适应 | **Primary / (Primary + Secondary) < 0.6 → prompt** | 平衡"两弱"和"接近"两种歧义场景；复杂度低 |
| K-12 | OQ-03 Core profiles 集合 | 3 个 / 6 个 / 更多 | **6 个** | 每个 kind 都有 "identity / architecture / navigation / dev / traps / confidence" 共通需求 |
| K-13 | Unknown kind fallback | 默认 web-backend / 报错拒绝 / prompt 列候选 | **Prompt 列候选 + 引导 `--kind=<name>`** | 不假设；要求用户明确意图；与 K-7 的 "保留用户控制"理念一致 |
| K-14 | Monorepo Future-Proofing 落地 | 忽略 / 留架构口 / 实际实现 | **留架构口**：kind detection 接受 `{base-path}`（默认 `.`）；markers 预留多值 hash 语法；`monorepo-package-graph` profile 输出列可扩展 | 遵守 clarify § Monorepo Future-Proofing 4 项要求 |

### DI accept/challenge 声明

| DI | Accept / Challenge | 说明 |
|----|-------------------|------|
| DI-1（profile skill-local）| **Accept** | 无 challenge；按 `reference/profiles/` 实现；加 `README.md` 索引（K-4 自然导出）|
| DI-2（IRON RULES core + overlay）| **Accept** | 按 K-6 "纯 append" 语义实现 |
| DI-3（kind 信号走 frontmatter）| **Accept** | 按 K-2 细化 |
| DI-4（read-do-discard 节奏）| **Accept** | K-1 Option C 的 Step 2 a-f 子步骤显式实现 |
| DI-5（profile 丰度 Lean+Golden-Path）| **Accept with minor refinement** | Profile 文件正文 5 节（Scan / Template / N/A / Golden-Path / Compressed IRON RULES Reminder）；约 80 行/profile。"压缩 IRON RULES 提醒" 上限 5 行（具体内容待 code 阶段决定）|

---

## Constraints & Trade-offs

**Accepted trade-offs：**
- Option C 引入"execution plan"中间概念，学习成本略高（vs Option A 的纯循环）。换取 DG2（checkpoint）和 DG3（规则就近）的明确收益。
- 17 个 profile 文件 vs v0.3.0 的 1 个模板。总行数约 1,400 行 vs 521 行（增加约 170%）。单次 run 实际读取的是 9 个 profile（约 720 行）远少于 v0.3.0 的 521 行一次性加载。
- 加权和检测算法不精确（没有 ML），可能误检。用 tie-break prompt（K-11）作为安全网。

**Ruled out：**
- ML-based kind detection（过度工程化；forge 目标用户手动 `--kind=<name>` 足够）
- Profile 文件支持多 kind 的变体块（违反 K-5 单向职责）
- v0.3.0 artifact 自动迁移（Q-3 明确 "不做"）
- Monorepo 自动递归生成子包 onboard（Gap-08 defer；只留架构口）

---

## Convention Deviations

_None_

本设计严格遵守现有 `.forge/context/conventions.md` 全部 8 条 Decision 与
`.forge/context/constraints.md` 的 C1–C8 硬约束。Content Hygiene（C8）
将在实现阶段通过以下方式严格执行：

- 所有 17 个 profile 文件的 Golden-Path Example 使用通用示例调色板
  （e-commerce order platform：`com.example.shop.*` / `Order` / `Customer`
  / `Payment` 等）
- 3 个 kind 文件的正文说明部分不含任何非 forge 项目标识符
- Commit message 严格按 conventions.md Commit 规则

---

## Open Decisions

_None — 所有 blocking 决策已通过 K-1 至 K-14 解决。_

无 deferred-with-acknowledgement 项。tasking 阶段可直接进入任务分解。

---

## Profile × Kind 引用矩阵

完整的 3 kinds × 17 profiles 引用关系：

| Profile | web-backend | claude-code-plugin | monorepo |
|---------|:-----------:|:------------------:|:--------:|
| core/project-identity | ✅ | ✅ | ✅ |
| core/architecture-overview | ✅ | ✅ | ✅ |
| structural/codebase-structure-web-backend | ✅ | ❌ | ❌ |
| structural/codebase-structure-plugin | ❌ | ✅ | ❌ |
| structural/codebase-structure-monorepo | ❌ | ❌ | ✅ |
| model/domain-entities | ✅ ¹ | ❌ | ❌ |
| model/artifact-types | ❌ | ✅ | ❌ |
| entry-points/http-entry-points | ✅ | ❌ | ❌ |
| entry-points/slash-command-entry-points | ❌ | ✅ | ❌ |
| integration/external-integrations | ✅ ¹ | ❌ | ❌ |
| integration/internal-events | ✅ ¹ | ❌ | ❌ |
| integration/scheduled-jobs | ✅ ¹ | ✅ ¹ | ✅ ¹ |
| monorepo/monorepo-package-graph | ❌ | ❌ | ✅ |
| core/change-navigation | ✅ | ✅ | ✅ |
| core/local-development | ✅ | ✅ | ✅ |
| core/known-traps | ✅ | ✅ | ✅ |
| core/document-confidence | ✅ | ✅ | ✅ |

¹ = 条件性：profile 只在 scan 发现相关代码时才触发加载（例如 domain-entities
仅在发现 `@Entity` 时；internal-events 仅在发现 `*Event` 类时；
scheduled-jobs 仅在发现 `@Scheduled` 或 cron 定义时）。未触发时该 profile
的 section marker 仍 emit 但 body 为 "No {category} detected"。

### Kind 执行顺序示例

**claude-code-plugin 的 execution plan：**
1. `core/project-identity`
2. `core/architecture-overview`
3. `structural/codebase-structure-plugin`
4. `model/artifact-types`
5. `entry-points/slash-command-entry-points`
6. `integration/scheduled-jobs`（条件性，通常 skip）
7. `core/change-navigation`
8. `core/local-development`
9. `core/known-traps`
10. `core/document-confidence`

**web-backend 的完整 plan：**
1. `core/project-identity`
2. `core/architecture-overview`
3. `structural/codebase-structure-web-backend`
4. `model/domain-entities`（条件性）
5. `entry-points/http-entry-points`
6. `integration/external-integrations`（条件性）
7. `integration/internal-events`（条件性）
8. `integration/scheduled-jobs`（条件性）
9. `core/change-navigation`
10. `core/local-development`
11. `core/known-traps`
12. `core/document-confidence`

**monorepo 的 plan：**
1. `core/project-identity`
2. `core/architecture-overview`
3. `structural/codebase-structure-monorepo`
4. `monorepo/monorepo-package-graph`
5. `core/change-navigation`
6. `core/local-development`
7. `core/known-traps`
8. `core/document-confidence`

---

## Next Step

`/forge:tasking onboard-kind-profiles`

Tasking 阶段会将本 design 拆解为有序 task 列表，预期包含：

1. 新建目录骨架 + `reference/profiles/README.md` 索引
2. 实现 6 个 core profile
3. 实现 3 个 kind-specific structural profile
4. 实现 2 个 kind-specific model profile + 2 个 entry-points profile
5. 实现 3 个 integration/conditional profile + 1 个 monorepo profile
6. 实现 3 个 kind 定义文件
7. 重写 `SKILL.md` 为 Option C 两级 Process
8. 更新 `incremental-mode.md` 适配动态 section name + kind drift
9. 删除旧 `output-template.md`
10. Bump plugin version + README + CLAUDE.md 同步
11. 自举测试：在 forge 自身跑新 `--regenerate` 并对照 Success Criteria 1-8 验收
12. 自举产物差异 review + 修补
