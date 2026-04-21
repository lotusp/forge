# Clarify: onboard-kind-profiles

> 原始需求："针对不同的项目框架给出不同的模板输出；如何进一步优化 onboard skill"
> 生成时间：2026-04-20
> 最近修订：2026-04-20（按 self-review 收敛 Q&A 到需求级；实现级决策剥离至 design-inputs.md；合并 Assumptions/Open Questions；加 Success Criteria；统一编号）
> 生成方式：/forge:clarify — 人机对话裁决
> 文件路径：.forge/features/onboard-kind-profiles/clarify.md
> 同时参考：design-inputs.md（实现级预置边界）

---

## Requirement Restatement

扩展 `/forge:onboard` skill，使其**第一步检测项目类型（kind）**，
然后**按 kind 组合出合适的 section 集合**，取代当前 v0.3.0 的固定 9-section 模板。
目标是首次运行即产出 kind 合身的 `onboard.md`，而不是套用后端服务中心化的模板后由
AI 手工改写。

**关键概念（需求层面的定义；实现结构见 `design-inputs.md`）：**

| 概念 | 需求定义 |
|------|----------|
| **Kind** | 项目类型的一级分类，决定 onboard.md 包含哪些 section 及采用什么视角 |
| **Profile** | 可复用的 section 单元；相同 profile 可被多个 kind 引用 |
| **Kind 定义** | 一个 kind 引用哪些 profile、按什么顺序 |

---

## Out of Scope

### Deferred — 本次 v0.4.0 不做，但架构已留口

- **Monorepo 子包递归**：生成每个子包独立 `onboard.md`（见 Requirements: Monorepo Future-Proofing）
- **更多 kind**：frontend-spa / cli-tool / library-sdk / data-pipeline / infra-as-code 等

### Future — 不在架构考虑范围内，视反馈再启动

- 自动化 pre-commit content-hygiene 扫描（见 `constraints.md` TD-006）
- 机器可读 sidecar `.forge/context/onboard.json`
- 跨 skill 共享 profile 库（目前只服务 onboard skill）

---

## Current Implementation

### Entry Points

| Entry point | Path | 规模 |
|-------------|------|------|
| `/forge:onboard` slash command | `plugins/forge/skills/onboard/SKILL.md` | 480 行 |
| Output template | `plugins/forge/skills/onboard/reference/output-template.md` | 521 行（硬编码 9-section） |
| Scan patterns | `plugins/forge/skills/onboard/reference/scan-patterns.md` | 337 行（按语言/框架分类） |
| Incremental mode | `plugins/forge/skills/onboard/reference/incremental-mode.md` | 210 行 |

### Call Chain (v0.3.0)

```
/forge:onboard [args]
  └─ Step 0: Run mode 检测（first-run / incremental / --regenerate / --section）
       └─ Steps 1–9: 顺序执行 9 个硬编码 section 的扫描+生成
            └─ Step 10: Verification pass（IRON RULES 遍历）
                 └─ Step 11: 按 section 顺序 write（HTML markers）
                      └─ JOURNAL.md append
```

### Data Flow

**v0.3.0 当前流：**
```
目标项目源代码
  ↓ [Runtime snapshot 预扫描]
  ↓ [Steps 1-9 各自的 Glob/Grep/Read 产生 section 数据]
9 段固定结构的数据
  ↓ [按硬编码模板渲染]
.forge/context/onboard.md（9 section + footer）
  + JOURNAL.md 追加条目
  + Document Confidence footer（含 verified=<hash> markers）
```

**v0.4.0 期望流（本需求的目标状态）：**
```
目标项目源代码
  ↓ [Step 1 Kind detection：读 kind 文件 frontmatter → 加权打分]
kind identifier（+ 可选 secondary kind）
  ↓ [加载 kind 定义 → 获取有序 profile 引用列表 + iron_rules_overlay]
本 run 的执行计划（有序 profile 序列）
  ↓ [按 profile 序列，每步 read-do-discard 一个 profile]
  ↓   - read profile 文件 → 应用 scan → 生成 section 内容 → write（带 markers）
  ↓   - 可选 --thorough：每 section 写后触发 self-critique round-trip
动态 section 集合（kind 决定）
  ↓ [Verification pass（core IRON RULES + kind overlay）]
.forge/context/onboard.md（kind-appropriate）
  + JOURNAL.md 追加条目
  + Document Confidence footer
```

**关键变化：**
- Step 1 **新增** kind detection，产出"本 run 要用哪些 profile"
- Section 集合 **动态化**（不再固定 9 个）
- Incremental mode 的 section marker 需支持动态名称

### Current Problems（自举验证 commit `60d309f` 暴露）

| ID | 问题 | 证据 |
|----|------|------|
| P-01 | "Business Domain vs Technical Layer" 二分不适配 meta-project（如 Claude Code plugin） | 自举时 Section 3 手工改为 Skills/Agents/Scripts 四表 |
| P-02 | Core Domain Objects section 预设 `@Entity` 扫描，非 DB 项目需要手动转义 | 自举时改用 "artifact types" 代替 |
| P-03 | Entry Points 子类别（HTTP/Events/Jobs/CLI/gRPC）缺 slash-command / MCP / hooks | 自举时手动加 Slash Commands 表 |
| P-04 | Integration Topology 在无外部系统时大段 N/A，显得冗余 | 自举时重复了 artifact→skill 依赖图 |

---

## Affected Components

**仅列当前需求直接触及的文件。** 后续 tasking/code 阶段自然会追加 JOURNAL 条目等，
不在此列。

| Component | Path | Nature of Impact |
|-----------|------|------------------|
| `onboard` SKILL.md | `plugins/forge/skills/onboard/SKILL.md` | **重写**：Process 结构从 9 固定 step 改为 kind-driven 动态序列 |
| `onboard` output-template.md | `plugins/forge/skills/onboard/reference/output-template.md` | **删除/替换**：内容拆解进 profile 文件 |
| `onboard` scan-patterns.md | `plugins/forge/skills/onboard/reference/scan-patterns.md` | **保留**：profile 文件按需 cross-reference |
| `onboard` incremental-mode.md | `plugins/forge/skills/onboard/reference/incremental-mode.md` | **小改**：section 名称集合从硬编码改为从 kind 定义派生 |
| Kind 目录 | `plugins/forge/skills/onboard/reference/kinds/*.md` | **新增**：3 个 kind 定义 |
| Profile 目录 | `plugins/forge/skills/onboard/reference/profiles/*.md` | **新增**：约 10 个 profile 文件 |
| Plugin version | `plugins/forge/.claude-plugin/plugin.json` | **Bump** 0.3.x → 0.4.0 |
| README | `README.md` | **更新**：版本徽章、新 flag 使用示例 |
| 自举产物 | `.forge/context/onboard.md` | **重新生成**：用 v0.4.0 skill 跑一遍验证 |

---

## External Dependencies

无新增外部依赖。现有工具（Claude Code 的 Read/Glob/Grep/Write/Bash；Git 用于
commit hash；Node.js 用于既有 `.mjs` 脚本）已足够。

---

## Design Goals

跨切面设计目标，每个 Gap 会标注它如何服务或权衡这 3 个：

| ID | 目标 | 硬性约束 |
|----|------|---------|
| **DG1** | 渐进加载，尽量省 token | SKILL.md 常驻部分精简；profile/kind 文件按需 Read 不预加载；detection 信号只读 frontmatter |
| **DG2** | 长上下文稳定 | Process 步骤短、有 checkpoint；关键 IRON RULES 在使用点就近再声明；按 section 逐个 write |
| **DG3** | 生成质量高 | IRON RULES 完备；confidence tag 强制；verification pass；`--thorough` flag 开启 self-critique；profile 自带 golden-path 示例 |

---

## Success Criteria

v0.4.0 落地后，以下 8 条验收项需全部通过：

### 产品行为

1. **自举（claude-code-plugin）：** 在 forge 自身跑 `/forge:onboard --regenerate`，
   产出 `.forge/context/onboard.md` 自动检测为 `claude-code-plugin` kind，section
   集合**不含** `domain-entities` / `http-entry-points` / `external-integrations`
   这类不适用 section；**含** `artifact-types` / `slash-command-entry-points`。
2. **主流后端（web-backend）：** 在一个典型 Spring Boot 单体项目跑 `--regenerate`，
   自动检测为 `web-backend` kind，产出含 `domain-entities` / `http-entry-points` /
   `external-integrations` / `internal-events` 等 section，无需手工改写。
3. **Monorepo：** 在一个 nx / turbo / pnpm-workspace 项目跑 `--regenerate`，
   自动检测为 `monorepo` kind，产出含包图表格（每行 `{package-path}` +
   `{detected-kind}` + brief）；**不**为每个子包生成独立 onboard.md（defer）。

### 用户交互

4. **`--kind=<name>` override** 生效：显式指定 kind 后，detection 跳过，按指定
   kind 的 profile 序列执行。无效 kind 名给出清晰错误提示。
5. **`--thorough` flag** 生效：启用后，每个 section 写入后看到至少一次
   self-critique round-trip；关闭时不产生此开销。
6. **低置信度提示**：当 kind detection 的 primary 与次名得分接近（阈值由
   design 决定），skill 主动提示用户确认或提供 `--kind=<name>` 选项。

### 非功能

7. **Token 消耗：** 在自举场景下，v0.4.0 的完整 `--regenerate` 总 token 消耗
   ≤ v0.3.0 同场景的 1.5 倍（ceiling；理想情况应等量或更少）。
8. **Content Hygiene：** 所有新 profile 文件的 golden-path 示例遵循
   `conventions.md § Content Hygiene` 的通用示例调色板（e-commerce order platform）；
   不含非 forge 项目的标识符。

---

## Questions & Answers（仅需求级）

按修订后的 clarify 边界，只保留"产品该不该有 X 能力"、"范围如何裁剪"、"产品策略"
层面的决策。实现细节见 `design-inputs.md`。

| # | 需求级问题 | 答案 | 归属层面 |
|---|-----------|------|----------|
| Q-1 | v0.4.0 MVP 应支持哪几个 kind？ | **B** — 3 个聚焦：`web-backend` / `claude-code-plugin` / `monorepo` | 产品范围 |
| Q-2 | v0.4.0 是否作为 breaking release 一次性推出？ | **A** — 一次性发 v0.4.0 | 产品策略 |
| Q-3 | 是否为 v0.3.x 旧产物提供向后兼容迁移？ | **D** — 不提供，forge 无存量用户 | 产品策略 |
| Q-4 | Monorepo kind 是否递归生成每子包独立 onboard？ | **C** — MVP 仅列包图并对每子包做 kind detection；递归生成 defer 至未来版本 | 范围裁剪 |
| Q-5 | 产品是否暴露 self-critique 质量模式给用户？ | **C** — 是，通过 opt-in flag（默认关闭；具体 flag 名属 design） | 产品能力 |

**剥离到 design-inputs.md 的实现级决策**（不属于 clarify Q&A）：
- Profile 文件存放位置 → DI-1
- IRON RULES 叠加方式 → DI-2
- Kind detection 信号存放位置 → DI-3
- Profile 加载策略（read-do-discard）→ DI-4
- Profile 文件内容丰度 → DI-5

---

## Open Questions

合并原 Assumptions 与 Open Questions（同一议题不再双写）。design 阶段需裁决。

| # | 议题 | 当前默认假设 | Impact if unresolved |
|---|------|-------------|----------------------|
| OQ-01 | `--thorough` flag 在 incremental 模式下的语义 | 假设与 first-run 一致（全量 + self-critique） | Run Mode 矩阵不完整 |
| OQ-02 | Kind detection 低置信度触发用户确认的**具体阈值数值**（primary 与次名的得分差） | 假设 < 20% 触发确认 | 影响交互频率、用户体验 |
| OQ-03 | 哪些 profile 归为"核心"（所有 kind 共用，如 project-identity / local-development / known-traps / document-confidence） | 假设 5 个核心 profile | 影响 profile 库组织、kind 文件的 profile 列表 |
| OQ-04 | Profile 之间的 cross-reference 语法（例如"见 Section 6"）用纯文本 / 固定格式 / Markdown 链接？ | 假设纯文本 + section 标题引用 | 影响可维护性、未来自动化工具 |
| OQ-05 | Monorepo 子包 kind detection 是否并行？ | 假设串行（简单、易调试） | 影响大型 monorepo 运行时长 |

---

## Requirements: Monorepo Future-Proofing

Q-4 的答案虽是"MVP 不递归"，但用户明确要求："**需要考虑后续递归每个 repo 的可能性，
毕竟要熟悉整个项目上下文。**" 因此 design 阶段必须满足以下 4 条可扩展要求——否则
未来递归能力需要重写：

1. **`monorepo-package-graph` profile 的产出结构可扩展**
   - MVP 列：`{package-path} | {detected-kind} | {brief}`
   - 未来可增补列：`{package-onboard-path}` 指向 `.forge/context/packages/{pkg}/onboard.md`
2. **Kind detection 无全局状态依赖**
   - MVP 在目标项目根目录运行一次
   - 未来可对任意子路径独立调用，不修改 detection 函数签名
3. **Profile 的 scan 规程不假设"仓库根 = 当前工作目录"**
   - 所有 Glob/Grep 路径必须接受 `{base-path}` 参数（MVP 默认 `.`）
4. **Section markers 的 `verified=<hash>` 标记可扩展为 per-package**
   - MVP：全局单 commit hash
   - 未来（递归）：子包 hash 可能独立（尤其 git submodule），markers 需支持
     `verified=<pkg1-hash>,<pkg2-hash>` 或类似复合形式

这 4 条进入 design 阶段作为**架构约束**（functional + non-functional 混合）。

---

## Gaps (What Doesn't Exist Yet)

### Core Gaps — v0.4.0 必须完成

| ID | Gap | 服务 DG |
|----|-----|---------|
| **Gap-01** | Kind detection 机制（新 Process Step 1） | DG1（轻量）; 解决 P-01/02/03/04 根因 |
| **Gap-02** | Profile 库（10 个 profile 文件的原子单元）| DG3 质量载体 |
| **Gap-03** | Kind 定义库（3 个 kind 文件，声明式 kind→profile 映射）| DG1 按需加载前提 |
| **Gap-04** | SKILL.md 的 Process 模板化（read-do-discard 节奏）| DG1+DG2 核心机制 |
| **Gap-05** | IRON RULES 的 core/overlay 拆分 + profile 内压缩重述 | DG2+DG3 |
| **Gap-06** | `--kind=<name>` 和 `--thorough` 两个新 flag 的解析与路由 | 用户显式控制 |
| **Gap-07** | Incremental mode 的 section 名称集合动态化 | 适配 kind-dependent section 集 |

### Future Gaps — 架构预留但 MVP 不做

| ID | Gap | 架构预留要求 |
|----|-----|-------------|
| **Gap-08** | Monorepo 子包递归生成独立 onboard.md | 见 Requirements: Monorepo Future-Proofing（1-4）|
| **Gap-09** | 更多 kind（frontend-spa / cli-tool / library-sdk / data-pipeline / infra-as-code）| Kind 定义格式必须支持增量新增文件 |
| **Gap-10** | 自动化 pre-commit content-hygiene 扫描（`constraints.md` TD-006）| 不影响 v0.4.0 架构 |
| **Gap-11** | 机器可读 sidecar `.forge/context/onboard.json` | 不影响 v0.4.0 架构；未来可从 section markers 衍生 |

---

## Content Hygiene Notice

本需求新增 ~13 个 reference 文件（3 个 kind + 10 个 profile），其中 profile
文件**必含 golden-path 示例**（DI-5）。所有示例必须遵循 `.forge/context/
conventions.md § Content Hygiene` 的规则：

- 示例域使用"通用示例调色板"（e-commerce order platform）
- 禁止出现除 forge 自身外的任何真实项目/公司/产品/内部系统名
- 自举产物 `.forge/context/onboard.md` 描述 forge 自己时，可用 forge 真实
  标识符（`forge-explorer`、`/forge:onboard` 等）——这是规则里明确的例外

Design 和 Code 阶段都会被 inspect 阶段按此规则检查。

---

## Next Step

`/forge:design onboard-kind-profiles`

Design 阶段的输入与产出：

**输入：**
1. `clarify.md`（本文件）— 需求与范围
2. `design-inputs.md` — 实现预置边界（DI-1 ... DI-5）
3. `plugins/forge/skills/onboard/` 现有实现
4. `.forge/context/conventions.md` § Content Hygiene

**产出（`.forge/features/onboard-kind-profiles/design.md`）：**
1. Gap-01 ... Gap-07 的具体技术方案（forge-architect agent 并发探索多条路径）
2. OQ-01 ... OQ-05 的裁决结果
3. Monorepo Future-Proofing 的 4 条可扩展性要求在类/文件结构中的落地
4. 3 个 kind × ~10 个 profile 的完整引用矩阵
5. 对 DI-1 ... DI-5 的 accept/challenge 声明（DI-2 中约定的 design 职责）
