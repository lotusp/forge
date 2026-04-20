# Clarify: onboard-kind-profiles

> 原始需求："针对不同的项目框架给出不同的模板输出；如何进一步优化 onboard skill"
> 生成时间：2026-04-20
> 生成方式：/forge:clarify — 人机对话裁决
> 文件路径：.forge/features/onboard-kind-profiles/clarify.md

---

## Requirement Restatement

扩展 `/forge:onboard` skill，使其第一步检测**项目 kind**（项目类型），
再根据 kind 从 **profile 库** 中按定义顺序组合出 kind-appropriate 的
`onboard.md` 输出，取代当前 v0.3.0 的固定 9-section 模板。

**关键概念：**

| 概念 | 定义 |
|------|------|
| **Kind** | 项目类型分类（例：`web-backend` / `claude-code-plugin` / `monorepo`），通过扫描 build files + 目录结构 + 特征文件加权打分确定 |
| **Profile** | 可复用的 section 单元，包含：(适用 kind 列表 + scan 规程 + template 片段 + N/A 兜底 + golden-path 示例 + 相关 IRON RULES 提醒) |
| **Kind 定义** | 一个 kind 引用哪些 profile、按什么顺序、附加哪些 kind-specific IRON RULES（`iron_rules_overlay`） |

**范围：**
- 仅改动 `plugins/forge/skills/onboard/`（SKILL.md + reference/）
- 不改动其他 skill、agents、scripts
- 不改动 artifact 目录结构（产物仍落 `.forge/context/onboard.md`）
- 保留 Run Modes（first-run / incremental / `--regenerate` / `--section=<name>`），新增 `--kind=<name>` override 和 `--thorough` 质量旗标

**非目标（defer 至后续迭代）：**
- Monorepo 递归生成每个子包的独立 onboard.md
- 更多 kind（frontend-spa / cli-tool / library-sdk / data-pipeline / infra-as-code）
- 自动化 pre-commit content-hygiene 扫描

---

## Current Implementation

### Entry Points

| Entry point | Path | Description |
|-------------|------|-------------|
| `/forge:onboard` slash command | `plugins/forge/skills/onboard/SKILL.md` | 480 行 skill 主文件，11 步 Process |
| Output template | `plugins/forge/skills/onboard/reference/output-template.md` | 521 行，包含硬编码的 9-section 结构 |
| Scan patterns | `plugins/forge/skills/onboard/reference/scan-patterns.md` | 337 行，按语言/框架分类的 grep/glob 模式 |
| Incremental mode | `plugins/forge/skills/onboard/reference/incremental-mode.md` | 210 行，diff/merge/preserve-block 逻辑 |

### Call Chain (v0.3.0)

```
/forge:onboard [args]
  └─ Step 0: Run mode detection (first-run / incremental / --regenerate / --section=<name>)
       └─ Steps 1–9: 顺序扫描 + 写入 9 个固定 section（project-identity → document-confidence）
            └─ Step 10: Verification pass (遍历所有 IRON RULES 检查)
                 └─ Step 11: Write section-by-section with HTML markers
                      └─ JOURNAL.md append
```

### Data Flow

**输入：** 目标项目的源代码 + 当前 HEAD commit + 既有 `.forge/context/onboard.md`（如有）
**转换：**
1. Runtime snapshot 预扫描（已内置）
2. 各 Process step 做 Glob/Grep/Read
3. 把扫描结果填充进固定模板的 9 个 section
4. 按 IRON RULES 校验
**输出：** `.forge/context/onboard.md` + JOURNAL.md 追加 + Document Confidence footer

### 当前问题（自举验证 commit `60d309f` 暴露）

| ID | 问题 | 证据 |
|----|------|------|
| P1 | "Business Domain vs Technical Layer" 二分不适配 meta-project（如 Claude Code plugin） | 自举时 Section 3 手工改为 Skills/Agents/Scripts 四表 |
| P2 | Core Domain Objects section 预设 `@Entity` 扫描，非 DB 项目需要手动转义 | 自举时改用 "artifact types" 代替 |
| P3 | Entry Points 子类别（HTTP/Events/Jobs/CLI/gRPC）缺 slash-command / MCP / hooks | 自举时手动加 Slash Commands 表 |
| P4 | Integration Topology 在无外部系统时大段 N/A，显得冗余 | 自举时重复了 artifact→skill 依赖图 |

---

## Affected Components

| Component | Path | Nature of Impact |
|-----------|------|------------------|
| `onboard` SKILL.md | `plugins/forge/skills/onboard/SKILL.md` | **重写**：加 Step 1 kind-detection、Process 改为 read-do-discard 节奏 |
| `onboard` output-template.md | `plugins/forge/skills/onboard/reference/output-template.md` | **废弃**：内容拆解成 profile 文件 |
| `onboard` scan-patterns.md | `plugins/forge/skills/onboard/reference/scan-patterns.md` | **保留**：profile 文件通过 cross-reference 引用其中的扫描模式 |
| `onboard` incremental-mode.md | `plugins/forge/skills/onboard/reference/incremental-mode.md` | **小改**：section name 从硬编码 10 项改为从 kind 定义动态读取 |
| 新增 kind 目录 | `plugins/forge/skills/onboard/reference/kinds/*.md` | **新增**：3 个 kind 定义文件 |
| 新增 profile 目录 | `plugins/forge/skills/onboard/reference/profiles/*.md` | **新增**：约 10 个 profile 文件 |
| Plugin version | `plugins/forge/.claude-plugin/plugin.json` | **bump** 0.3.0 → 0.4.0（breaking） |
| Plugin README | `README.md` | **更新**：版本徽章 + 新 flag 说明 |
| Forge 自身 `.forge/context/onboard.md` | `.forge/context/onboard.md` | **重新生成**（通过新版 skill 自举） |
| Journal | `.forge/JOURNAL.md` | **追加**多个条目（本次 clarify + 后续 design/tasking/code）|

---

## External Dependencies

| Dependency | Type | Relevance |
|------------|------|-----------|
| Claude Code 运行时 | Platform | Skill 的载体，加载 SKILL.md + reference/*.md 的行为决定 token 消耗 |
| Git | CLI | Kind detection 不依赖 git；但 incremental mode 依赖 `git rev-parse --short HEAD` 作为 verified= 标记 |
| Node.js | Runtime | 现有 4 个 `.mjs` 脚本（status.mjs 等）不受本次修改影响 |
| 文件系统 Glob/Grep | Tool | Kind detection 的信号扫描（读 build files 等） |

无新增外部依赖。

---

## Design Goals Tracker

本项目有 3 个跨切面设计目标，所有后续设计决策都要按这个矩阵评估：

| ID | 目标 | 硬性约束 |
|----|------|---------|
| **G1** | 渐进加载，尽量省 token | SKILL.md 常驻部分必须精简；profile/kind 文件 **按需 Read**，**不预加载**；detection 信号只读 frontmatter 或 build-file 元数据，**不读正文** |
| **G2** | 长上下文稳定 | Process 步骤短、有 checkpoint；关键 IRON RULES 在使用点 **就近再声明一次**；按 section 逐个 write，每次生成的注意力负荷隔离 |
| **G3** | 生成质量高 | IRON RULES 完备；confidence tag 强制；verification pass；`--thorough` flag 开启 self-critique；每个 profile 自带 golden-path 示例 |

每个 Gap 将标注它如何服务这 3 个目标（或需要权衡）。

---

## Assumptions Made

以下在分析期做的假设，进入 design 前需再确认：

- **A1.** 假设 `--thorough` flag 在所有 Run Mode 下语义相同（全量扫描 + 开启 self-critique），不区分 first-run / incremental。design 阶段需确认是否有 mode 特定差异。
- **A2.** 假设 kind detection 的"低置信度"阈值采用简单规则：primary 得分与次名差距 < X% 时触发用户确认。具体 X 值由 design 阶段确定。
- **A3.** 假设 profile 文件间可以 cross-reference（例如 `entry-points` profile 提及 Section 6 会详述），通过纯文本链接实现；不引入模板引擎。
- **A4.** 假设 3 个 MVP kind 的 profile 引用集存在交集（例如 `project-identity` / `local-development` / `known-traps` / `change-navigation` / `document-confidence` 5 个核心 profile 应被所有 kind 引用）；design 阶段会明确每个 kind 的完整 profile 列表。
- **A5.** 假设 monorepo kind 的子包 kind detection 输出仅记录在 `monorepo-package-graph` profile 的产物里（每行一条），**不**单独写 `.forge/context/packages/{pkg}/*.md` 文件。

---

## Questions & Answers

### Batch 1（架构根决策）

| # | Question | Answer | 理由（用户或推荐） |
|---|----------|--------|--------------------|
| 1 | Kind 起手集 | **B** — 3 个聚焦：`web-backend` / `claude-code-plugin` / `monorepo` | 深度优先；覆盖 forge 目标场景 + 自举场景 + 复杂现实场景 |
| 2 | Profile 存放位置 | **A** — `plugins/forge/skills/onboard/reference/profiles/*.md`（skill-local） | YAGNI；先证明 profile 概念，再考虑跨 skill |
| 3 | Breaking 节奏 | **A** — 一次性发 v0.4.0 | forge 无存量用户，不需迁移兼容 |
| 4 | IRON RULES 叠加方式 | **A** — Core 在 SKILL.md + 各 kind 文件的 `iron_rules_overlay` | 封装性好，kind 文件内聚 |
| 5 | 向后兼容 | **D** — 不处理 | 无用户，直接 breaking |

### Batch 2（实现细节，按 3 个设计目标评估）

| # | Question | Answer | 理由 / 服务的目标 |
|---|----------|--------|-------------------|
| 6 | Kind detection 信号存放 | **B** — 信号写在各 kind 文件的 frontmatter；Step 1 仅读 frontmatter | G1+G3 最优：检测只读 < 100 行；加 kind = 加文件 |
| 7 | Profile 加载策略 | **C** — Process 模板化的 "read-do-discard"：每 step 显式 Read 对应 profile，执行完即丢 | G1+G2 最优：注意力按 step 切换，失败可单 profile 重跑 |
| 8 | Monorepo kind 深度 | **C** — MVP 列包图 + 对每子包跑 detection（标注推断 kind），**不**递归生成独立 onboard.md | 详见下方 Architectural Accommodation |
| 9 | Self-critique 启用 | **C** — `--thorough` flag 默认关闭；verification pass 始终作兜底 | G1+G3 诚实权衡；flag 可扩展到其他未来场景 |
| 10 | Profile 文件丰度 | **C** — Lean 默认 + 必含 golden-path 示例 + 压缩版 IRON RULES 提醒（约 80 行/profile） | G3 保证（示例直接提升质量）+ G2 就近规则；G1 可接受 |

---

## Architectural Accommodation: Monorepo Recursion 预留

Q8 的用户补充："**需要考虑后续递归每个 repo 的可能性，毕竟要熟悉整个项目上下文。**"

虽然 MVP 不做递归生成，但 design 阶段的架构必须为此留口。具体需要：

1. **`monorepo-package-graph` profile 的产出结构可扩展为包含子包 onboard.md 路径**
   - MVP：每行 `{package-path} | {detected-kind} | {brief}`
   - 未来：加一列 `{package-onboard-path}` 指向 `.forge/context/packages/{pkg}/onboard.md`
2. **Kind detection 函数无全局状态依赖**
   - MVP 在目标项目根目录运行一次
   - 未来可对任意子路径独立运行，无需修改 detection 逻辑
3. **Profile 的 scan 规程不假设"仓库根 = 当前工作目录"**
   - 所有 Glob/Grep 路径可接受 `{base-path}` 参数（MVP 默认 `.`）
4. **Section markers 的 `verified=<hash>` 需扩展方案**
   - MVP：单 commit hash
   - 未来（递归）：子包的 hash 可能独立（尤其 git submodule），markers 需支持 per-package hash

这 4 条架构约束会进入 design 阶段的非功能需求。

---

## Open Questions

Batch 1+2 全部回答，无 deferred 项。以下为 design 阶段需要进一步决定（由 A1–A5 假设引出）：

| # | Question | Impact if unresolved |
|---|----------|----------------------|
| OQ1 | `--thorough` flag 在 incremental 模式下如何交互（是否强制 refresh 所有 section） | 影响 Run Mode 矩阵的完备性 |
| OQ2 | Kind detection 低置信阈值的具体数值（primary 与次名差距百分比） | 影响用户确认交互的触发频率 |
| OQ3 | 哪些 profile 归为"核心"（所有 kind 共用） | 影响 profile 库的组织和 kind 文件的 profile 列表长度 |
| OQ4 | Profile 之间的 cross-reference 语法规范（例如如何引用"见 Section 6"） | 影响可维护性 |
| OQ5 | Monorepo 子包 detection 的并行度（串行 vs 并行扫描） | 影响大型 monorepo 运行时间 |

这 5 条进入 `/forge:design` 阶段处理。

---

## Gaps (What Doesn't Exist Yet)

### Core gaps（必须在 v0.4.0 完成）

| Gap | 描述 | 服务目标 |
|-----|------|----------|
| **G-A** | Kind detection 机制（Step 1） | 解决 P1/P2/P3/P4 问题根因 |
| **G-B** | Profile 库（扫描 + 模板 + 示例的原子单元） | G3 质量提升的载体 |
| **G-C** | Kind 定义库（声明式 kind → profile 映射 + overlay rules） | G1 按需加载的前提 |
| **G-D** | SKILL.md 的 Process 模板化（read-do-discard 节奏） | G1+G2 核心机制 |
| **G-E** | IRON RULES 的 core/overlay 拆分与就近重述（per profile） | G2+G3 实现 |
| **G-F** | `--kind=<name>` 和 `--thorough` 两个新 flag 的解析与路由 | 用户显式控制 |
| **G-G** | Incremental mode 的 section name 动态化 | 适配 kind-dependent section 集 |

### Accommodation gaps（MVP 不做但架构需支持）

| Gap | 描述 |
|-----|------|
| **G-H** | Monorepo 子包递归生成（预留扩展点，见 Architectural Accommodation 1–4）|
| **G-I** | 更多 kind（`frontend-spa` / `cli-tool` / `library-sdk` / `data-pipeline` / `infra-as-code`）|
| **G-J** | 自动化 pre-commit content-hygiene 扫描（TD-006）|
| **G-K** | 机器可读 sidecar `.forge/context/onboard.json`（从 Markdown 衍生的结构化版本）|

---

## Next Step

`/forge:design onboard-kind-profiles`

Design 阶段会处理：
1. Gaps G-A 到 G-G 的具体技术方案（并发探索多条路径，forge-architect agent 参与）
2. Open Questions OQ1–OQ5 的裁决
3. Monorepo recursion 的 4 条架构约束如何在 v0.4.0 的类/文件结构中预留
4. Profile 库的完整清单与 3 个 kind 对应的引用矩阵
