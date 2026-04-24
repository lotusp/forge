# Design: onboard-evidence-first

> 基于：`.forge/features/onboard-evidence-first/clarify.md` + `.forge/features/onboard-evidence-first/design-inputs.md` + 4 context files
> 生成时间：2026-04-24
> 文件路径：`.forge/features/onboard-evidence-first/design.md`
> Kind：plugin（self-hosting）
> MVP 范围：priorities 1–3（evidence discipline + claim classification + reduce execution-layer content）；priorities 4–5 延至后续 feature `onboard-change-navigation`
> 预估风险：Medium（触达 onboard skill 核心、引入 wire-format 变更、要求 `--regenerate` 迁移）
> Revise log：Stage 2 一次性通过；3 个 scenario 全部 ✅；spec-review PASS（9/9 SC + 9/9 Gap + 0 orphan）

---

## Solution Overview

将 `/forge:onboard` 从 prompt-driven summarizer 升级为 evidence-first context compiler。核心机制是在 Stage 2 / Stage 3 的 "scan → extract → render" 流程中插入**分类子步骤**（classify claims 到六类之一：`fact` / `inference` / `enforced-rule` / `recommended-pattern` / `process-rule` / `current-caveat`），分类结果决定**产物落点**（artifact + section），而不仅是 confidence tag。

分类逻辑采用 **distributed annotations** 模型：全局策略（6 类 + 允许的 artifact/section + 置信度下限）定义在 SKILL.md 三条新 Iron Rule（R15/R16/R17）；每个受影响的 dimension/profile 文件内部增加 `## Claim Classification Annotations` 子段，把本 dimension 抽取的事实类型显式映射到类别 + 目标 section。LLM 处理每个 dimension 时，分类指引与抽取规则始终**同场出现**，避免长 prompt 下的分类漂移。

同时：`local-dev.md` profile 从全部 4 个 Stage-2 kind manifest 中移除；`deployment.md` profile 收窄到单行架构事实；`architecture.md` / `constraints.md` 的 Output Template 重排为三段结构；新增 `delivery-conventions.md` dimension 汇总 Delivery 期望；Stage 3 smart-merge 新增 **pre-redesign detection**：遇到与新 Output Template 结构不匹配的旧 section 时 halt 并要求 `--regenerate`。

---

## Approach Options

| Option | Description | Pros | Cons | Verdict |
|--------|-------------|------|------|---------|
| A — Distributed Annotations | 全局策略在 SKILL.md R15；每 dim/profile 内嵌 Classification Annotations 小表 | 长 prompt 稳定性最强（DI-2）；每文件自审；分类指引与抽取同场 | 策略表在 R15 + 各 dim 各有一份；策略迁移要同步多文件 | ✅ Chosen |
| B — Central Reference File | 新 `reference/claim-classification.md` 承载 6 类 + 路由表；dim/profile 仅标类别 hint；SKILL.md R15 指向 reference | 单一权威定义；路由表易于更新 | 参考文件在 dim 10 / 12 时已退到 context 远端（DI-2 风险）；dim 文件变浅、依赖记忆 | ❌ Rejected — 对 prompt-execution 系统，co-location 比 centralization 更可靠 |

---

## Component Changes

### New Components

| Path | Layer | Type | Responsibility |
|------|-------|------|----------------|
| `plugins/forge/skills/onboard/profiles/context/dimensions/delivery-conventions.md` | Profile (context/dimensions) | dimension file | Stage-3 dimension；汇总 commit-format 范围外的 delivery 期望（task-commit 粒度、完成前 testing 期望、`.forge` artifact 更新期望）；通过 Claim Classification Annotations + kind-manifest 注册路由到 `conventions.md § Delivery Conventions` 与 `constraints.md § Process / Quality Gates`，不引入新的 dual-output-file frontmatter 语义 |

### Modified Components

| Path | What Changes | Why |
|------|--------------|-----|
| `plugins/forge/skills/onboard/SKILL.md` | 新增 R15（claim classification required）+ R16（per-artifact confidence floor + `[inferred]` 软路由）+ R17（execution-content exclusion policy）；Step 2（read-do-discard）增加 "classify before render" 子步；Step 4（Stage 3.1 scan）同样子步；Step 6（smart-merge 前）新增 pre-redesign detection 分支；Runtime snapshot 增加 "pre-redesign sections detected?" 行 | 承载全局分类策略 + execution-content 排除 + pre-redesign halt 语义（G-1 / G-6 / G-7 / G-8） |
| `plugins/forge/skills/onboard/reference/incremental-mode.md` | 新增 § Pre-redesign format detection：枚举检测规则（section.profile 指向已移除/重构的 dim；body 不含新 Output Template 的必需 h3 anchor）→ halt message → user 执行 `--regenerate` 路径 | 把 SKILL.md Step 6 描述的算法展开落地（G-7） |
| `plugins/forge/skills/onboard/profiles/kinds/plugin.md` | `profiles[]` 中移除 `core/local-dev` | SC-8 / G-2 |
| `plugins/forge/skills/onboard/profiles/kinds/web-backend.md` | 同上 | 同上 |
| `plugins/forge/skills/onboard/profiles/kinds/web-frontend.md` | 同上 | 同上 |
| `plugins/forge/skills/onboard/profiles/kinds/monorepo.md` | 同上 | 同上 |
| `plugins/forge/skills/onboard/profiles/structural/deployment.md` | Section Template 收窄：仅保留单行 "Target: `<platform>` via `<manifest-path>`"；移除 Environments / Deploy trigger / Image registry / Rollback / Infrastructure 段。新增 `## Claim Classification Annotations` 子段：Target 行归类 `fact`（架构事实） | SC-1 / G-8 — `deployment.md` 的 platform+manifest 位置是架构事实；其余为运行时期望，应排除 |
| `plugins/forge/skills/onboard/profiles/core/local-dev.md` | 文件顶部插入 deprecation 标记 comment：`<!-- forge:deprecated since=v0.6.0 reason="execution-layer content excluded by onboard-evidence-first redesign" -->`；frontmatter `applies-to:` 清空；文件本体保留以便 git 追溯 / 将来可用 | 保留删除的可逆性；Stage 1 空 `applies-to:` 阻止任何 kind 加载 |
| `plugins/forge/skills/onboard/profiles/context/dimensions/architecture-layers.md` | Output Template 每 kind 各重写为三个必需 h3 子段：`### Observed Structure`（事实）/ `### Enforced Rules`（`enforced-rule` + `[high] [code]`）/ `### Recommended Direction`（`recommended-pattern`）；原 "What to avoid" 段降级并入 Recommended Direction。新增 `## Claim Classification Annotations` 子段（8–12 行小表） | SC-2 / G-3 — 分离观察 / 强制 / 建议三层语义 |
| `plugins/forge/skills/onboard/profiles/context/dimensions/hard-constraints.md` | Output Template 改为 `## Hard Constraints` 顶层；process-rule 相关抽取规则移走（去 delivery-conventions）；新增 `## Claim Classification Annotations` 子段：仅接受 `enforced-rule` + `[high]` + 来源为 code/test/framework/IRON RULE 的 claim | SC-3 / G-4 / G-6 — Hard Constraints 不混入 process-rule |
| `plugins/forge/skills/onboard/profiles/context/dimensions/anti-patterns.md` | Output Template 分化：真 `current-caveat` 归 `constraints.md § Current Business Caveats`；process 期望迁 delivery-conventions；纯 `recommended-pattern` 类 anti-pattern 迁 architecture.md Recommended Direction 或 conventions.md。新增 `## Claim Classification Annotations` | SC-3 / G-4 |
| `plugins/forge/skills/onboard/profiles/context/dimensions/commit-format.md` | 范围收窄为 commit message 结构（type / scope / subject / body / footer）；task-commit 粒度、完成前 testing 期望、`.forge` artifact 更新期望**不再**由本 dim 产出，由新 delivery-conventions 承接 | 去重；避免 conventions.md 跨 dim 内容撞车 |
| `plugins/forge/skills/onboard/profiles/context/dimensions/testing-strategy.md` | Extraction Rules 增加 sample-size → confidence tag 映射：1 份证据 → `[low]`；2 份一致 → `[medium]`；≥3 份一致 → `[high]`；单文件推断 rule 不得超 `[low]`。新增 `## Claim Classification Annotations` | SC-9 / G-9 |
| `plugins/forge/skills/onboard/profiles/context/kinds/plugin.md` | `dimensions-loaded[conventions.md]` 追加 `dimensions/delivery-conventions`；`commit-format` 保留；无其他调整 | SC-4 / G-5 |
| `plugins/forge/skills/onboard/profiles/context/kinds/web-backend.md` | 同上 | 同上 |
| `plugins/forge/skills/onboard/profiles/context/kinds/web-frontend.md` | 同上 | 同上 |
| `plugins/forge/skills/onboard/profiles/context/kinds/monorepo.md` | 同上 | 同上 |
| `README.md` | 新增 "v0.6.0 evidence-first" 精简变更告知 + 链接 docs/upgrade-0.6.md | R20 user-facing docs |
| `CLAUDE.md` | "Core Design Principles to Uphold When Implementing Skills" 增加 "Claim classification before render" 条目；onboard Stage 3 描述更新（提及 classification + 3-section architecture/constraints） | R20 — project-wide AI context 须同步 |
| `docs/upgrade-0.6.md` | 新文件（迁移向导）：breaking changes、`--regenerate` 步骤、preserve-block 保留说明、已知不兼容点 | R20 — user-facing upgrade guide |

### Deprecated / Archived Components

| Path | Reason |
|------|--------|
| `plugins/forge/skills/onboard/profiles/core/local-dev.md` | 执行层内容（docker / env / pnpm commands）；brief 明确排除；file 不删除，加 deprecation header + 清空 applies-to | 

### Deleted Components

_None — 本 feature 的删除动作仅限于配置（kind manifests 中的引用），不删除任何磁盘文件。_

---

## API Changes

_None_ — `/forge:onboard` 的 CLI 签名（`/forge:onboard [--regenerate | --section=<name> | --kind=<kind-id>]`）不变；用户可见消息新增一类（pre-redesign halt，见 Wire Protocol Examples）。

---

## Data Model Changes

_None_ — 无数据库 / schema / migration。artifact 文件格式变更（architecture.md 三段 / constraints.md 三段 / conventions.md 新 Delivery Conventions 段）属于 wire-protocol 变更，详见下节。

---

## Wire Protocol Examples

### 1 — `architecture.md` new section structure (plugin kind, after redesign)

```markdown
<!-- forge:onboard source-file="architecture.md" section="architecture-layers" profile="context/dimensions/architecture-layers" verified-commit="a3f2c1d4" body-signature="e5f1a2b3c4d5e6f7" generated="2026-05-01" -->

## Architecture Layers

### Observed Structure

**Model:** Skill / Agent / Script / Artifact (四层)

| Layer | Path | Role |
|-------|------|------|
| Skill | `plugins/forge/skills/<name>/SKILL.md` | 主 agent 指令文件 [high] [code] |
| Sub-agent | `plugins/forge/agents/<name>.md` | 专用 agent，tool 受限 [high] [code] |
| Script | `plugins/forge/skills/<name>/scripts/*.mjs` | Node.js 确定性 helper [medium] [code] |
| Artifact | `.forge/<path>.md` | 持久化结构化上下文 [high] [code] |

### Enforced Rules

- Skill 可 spawn sub-agent（通过 Agent tool call） [high] [code]
- Skill 可以 Bash 调用 script [high] [code]
- Agent 禁止直接写 `.forge/`；agent 向 skill 返回 report 文本 [high] [code]（IRON RULE in `plugins/forge/agents/forge-explorer.md:12`）
- Skill 不跨 skill 直接调用；`forge` orchestrator 负责路由 [high] [code]（IRON RULE in `plugins/forge/skills/forge/SKILL.md:R2`）

### Recommended Direction

- 业务逻辑不要放在 `forge` orchestrator；放到具体 skill [medium] [code]
- Skill 不应绕过 `status.mjs`（orchestrator 路由权威） [medium] [code]
- Cross-skill imports 违反 "skill = self-contained prompt document" 原则 [medium] [code]

<!-- /forge:onboard section="architecture-layers" -->
```

### 2 — `constraints.md` new section structure (plugin kind, after redesign)

```markdown
<!-- forge:onboard source-file="constraints.md" section="hard-constraints" profile="context/dimensions/hard-constraints" verified-commit="a3f2c1d4" body-signature="b2c3d4e5f6a7b8c9" generated="2026-05-01" -->

## Hard Constraints

These rules have zero exceptions. Violations are `must-fix` severity.

### C1 — Skills are read + write-to-.forge/ only

No skill may modify project source files. Write is limited to `.forge/` paths declared in `allowed-tools` and Output section. [high] [code]

**Enforcement:** IRON RULE R8 in onboard SKILL.md; IRON RULE R3 in inspect SKILL.md.

### C6 — Section markers must be complete (all 6 attributes)

Every forge artifact section marker must carry all 6 attributes in the exact order: `source-file`, `section`, `profile`, `verified-commit`, `body-signature`, `generated`. [high] [code]

**Enforcement:** IRON RULE R9 in onboard SKILL.md.

<!-- /forge:onboard section="hard-constraints" -->

<!-- forge:onboard source-file="constraints.md" section="process-quality-gates" profile="context/dimensions/delivery-conventions" verified-commit="a3f2c1d4" body-signature="c3d4e5f6a7b8c9d0" generated="2026-05-01" -->

## Process / Quality Gates

- 每个 task（T{NNN}）完成后独立 commit；禁止批量合并 [high] [readme]
- `.forge/` 产物在产出时即 commit，不等到 feature 结束 [high] [readme]

<!-- /forge:onboard section="process-quality-gates" -->

<!-- forge:onboard source-file="constraints.md" section="current-business-caveats" profile="context/dimensions/anti-patterns" verified-commit="a3f2c1d4" body-signature="d4e5f6a7b8c9d0e1" generated="2026-05-01" -->

## Current Business Caveats

- `plugins/forge/skills/test/SKILL.md:51` 仍引用已废弃的 `/forge:calibrate`；appears to be pre-v0.5.0 residue, likely safe to clean up [inferred] [code]
- `/forge:onboard` Runtime snapshot 行 "Excluded-dimensions" 目前只在 onboard.md 头部呈现；下游 skill 若未来依赖该信息，需显式读 header [inferred] [code]

<!-- /forge:onboard section="current-business-caveats" -->
```

### 3 — `conventions.md § Delivery Conventions` new section (plugin kind, via new dimension)

```markdown
<!-- forge:onboard source-file="conventions.md" section="delivery-conventions" profile="context/dimensions/delivery-conventions" verified-commit="a3f2c1d4" body-signature="e5f6a7b8c9d0e1f2" generated="2026-05-01" -->

## Delivery Conventions

### Task-to-commit granularity

- 每个 task（`T{NNN}`）完成后独立 commit；subject 形如 `feat(skill/onboard): <desc> (T032)` [high] [readme]
- `.forge/` design / plan / clarify artifact 在产出时即 commit [high] [readme]

### Testing before done

- Skill 行为变更需产出或追加 `.forge/features/<slug>/verification.md` [high] [readme]
- 未做 verification 不视为 task 完成 [high] [readme]

### `.forge/` artifact update expectations

- clarify → design → code → inspect → test 链路产物必须按序产出；跳过前置阶段视为 scope-creep [high] [code]
- JOURNAL.md 追加只不修改（R9 append-only） [high] [code]

<!-- /forge:onboard section="delivery-conventions" -->
```

### 4 — `## Claim Classification Annotations` 子段格式（以 `architecture-layers.md` 为例）

该段落插入 dimension 文件 `## Extraction Rules` 之后、`## Output Template` 之前。字面形式：

```markdown
## Claim Classification Annotations

Each fact extracted by this dimension MUST be classified before render. The table maps extracted fact types to claim category, target artifact + section, and minimum confidence.

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| Directory layout observation (e.g. "controllers/ / services/ present") | `fact` | `architecture.md` | `### Observed Structure` | `[medium]` |
| Import-direction rule backed by compile/test/static-check | `enforced-rule` | `architecture.md` | `### Enforced Rules` | `[high]` + `[code]` |
| Import-direction rule backed by IRON RULE in a SKILL.md / agent file | `enforced-rule` | `architecture.md` | `### Enforced Rules` | `[high]` + `[code]` (quote rule location) |
| "Business logic should stay in services/" (inferred from directory convention) | `recommended-pattern` | `architecture.md` | `### Recommended Direction` | `[medium]` |
| "What to avoid" soft guidance | `recommended-pattern` | `architecture.md` | `### Recommended Direction` | `[medium]` |

**Forbidden routes:**
- Directory-layout observation → NOT Enforced Rules (needs enforcement evidence)
- `[inferred]` confidence → NOT this dimension (架构层不接受 inference；若无证据，omit)
```

### 5 — Pre-redesign halt message (Stage 3 Step 6 before smart-merge)

```
[forge:onboard] Pre-redesign artifacts detected

3 sections in .forge/context/ use templates superseded by the evidence-first redesign
(v0.6.0):

  architecture.md § architecture-layers
    profile marker points to context/dimensions/architecture-layers
    but body is missing required h3 anchors:
      ### Observed Structure
      ### Enforced Rules
      ### Recommended Direction

  constraints.md § hard-constraints
    body mixes process-rule and hard-constraint bullets (new template splits them)

  constraints.md § anti-patterns
    body mixes current-caveat and recommended-pattern bullets

Incremental update is not safe across this structural change.
Preserve blocks will be retained automatically.

Please re-run with:

  /forge:onboard --regenerate

See docs/upgrade-0.6.md for migration notes.
```

---

## Scenario Walkthroughs

### Scenario 1 — Happy path: first-run on forge self-hosting after `--regenerate`

**Setup:**
- `.forge/context/` 存在预重构产物（v0.5.0 生成）
- 用户执行 `/forge:onboard --regenerate`
- forge 仓库 kind = plugin（confidence 1.0）

**Flow:**
1. Stage 1 emits Execution Plan：`Plan.profiles[]` 含 `core/{tech-stack, module-map, entry-points, data-flows, notes}`（无 `core/local-dev`，无 `structural/deployment` — plugin kind 原本就 exclude 后者）；`Plan.context-dimensions[conventions.md]` 追加 `dimensions/delivery-conventions`。exercises K-1（classification scope）
2. Stage 2 loops 5 个 profile。每个 profile 的 Extraction Rules 产出 facts；per R15，classify sub-step 给每条 fact 打类别（都 → `fact`，走 `onboard.md`）；execution-content 检查（R17）为空命中。exercises R15 / R17
3. Stage 2 写出 onboard.md：章节顺序 What This Is / Tech Stack / Module Map / Entry Surface / Key Data Flows / Notes。**无 Local Development**（SC-1 / SC-8）。exercises K-3
4. Stage 3.1 扫描 dimensions。架构维度 `architecture-layers.md`：其 Claim Classification Annotations 把 "Agent 不写 .forge/" 归 `enforced-rule`（证据：`forge-explorer.md` 的 IRON RULE 段），路由到 `architecture.md § Enforced Rules`；把 "orchestrator 里避免业务逻辑" 归 `recommended-pattern`，路由到 `## Recommended Direction`。exercises K-1 / K-5 / K-11
5. Stage 3.1 扫描 `hard-constraints.md`：只接受 `enforced-rule` + `[high]` + IRON-RULE-backed claim，产 C1/C6 两条 → `constraints.md § Hard Constraints`。exercises K-6 / R16
6. Stage 3.1 扫描 `anti-patterns.md`：发现 `test/SKILL.md:51` 的 `/forge:calibrate` 残留，归 `current-caveat` + `[inferred]`，软化措辞 "appears to be pre-v0.5.0 residue, likely safe to clean up" → `constraints.md § Current Business Caveats`。exercises K-9 / R16
7. Stage 3.1 扫描新 `delivery-conventions.md`：从 CLAUDE.md § "Git Commit Convention" + `.forge/JOURNAL.md` + 已有 verification.md 模式抽取 task-commit 粒度 / testing-before-done / .forge update expectations → `conventions.md § Delivery Conventions`。exercises K-7
8. Stage 3.1 扫描 `testing-strategy.md`：每条 rule 回溯 sample size；`verification.md` 样本 3 份 → `[high]` 允许；其他 1–2 份 → `[low]`/`[medium]`。exercises K-10
9. Stage 3 Step 6：**pre-redesign detection** 发现旧 architecture.md section 不含新 h3 anchors → 但 `mode == regenerate`，detection 仅打 log，继续 smart-merge；preserve block 从旧 section 抽出、re-anchor 到对应新 h3 尾部。exercises K-8 / R14
10. 写出 5 个 context 文件；JOURNAL 记 `mode=regenerate`。

**Decisions exercised:** K-1, K-3, K-5, K-6, K-7, K-8, K-9, K-10, K-11 + R15, R16, R17, R14

**Walkthrough result:** ✅ passes — 每步有明确组件支撑；preserve block 保留正确；所有 9 个 SC 的预期产物均落在对应位置

---

### Scenario 2 — Edge: incremental run on pre-redesign artifacts (no `--regenerate`)

**Setup:**
- 同 Scenario 1 的 pre-redesign `.forge/context/`
- 用户执行 `/forge:onboard`（无 flag，默认 Mode B 增量）

**Flow:**
1. Stage 1 incremental：读 onboard.md header，kind = plugin 稳定 → 复用 kind（无 Stage-1 重打分）
2. Stage 2 incremental：section 逐条比对 `verified-commit` 与 HEAD short-sha。因距上次 onboard 有 commit，部分 section dirty，走 re-render。onboard.md **重写为无 Local Development**（profile 从 kind manifest 被移除了；`local-dev` section 成为 R14 的 orphan，按 "no longer applies" 处理，移到 `## Legacy Notes`）
3. Stage 3 incremental 启动。Step 6 的 pre-redesign detection 优先执行，在 smart-merge 前：
   - 遍历现有 `.forge/context/*.md` 的所有 section markers
   - 对每个 section，查 `profile` 属性：是否仍在当前 kind 的 `dimensions-loaded[]` 中？✅（`architecture-layers` 仍在）
   - 查 section body：是否包含当前 dimension 的 Output Template 必需 h3 anchors？**❌ 旧 architecture.md § architecture-layers body 无 `### Observed Structure` / `### Enforced Rules` / `### Recommended Direction`**
   - 同样 constraints.md § hard-constraints（旧 body 包含 `### AP1` 子结构但不符新的 flat Hard Constraints 形态）、§ anti-patterns（旧合并了 current-caveat + recommended-pattern）
4. Detection 认定 3 个 section 为 pre-redesign format
5. HALT with message（见 Wire Protocol Example #5）；不写任何文件；run 终止

**Decisions exercised:** K-8, K-5, K-6 + R14

**Walkthrough result:** ✅ passes — halt 是设计预期行为；用户收到明确 next step；preserve block 未被触碰

---

### Scenario 3 — Edge: Classification boundary stress test（IRON RULE claim 走向分化）

**Setup:**
- 同 Scenario 1 继续到 Stage 3.1 扫 `architecture-layers.md` dimension
- forge codebase 中 `plugins/forge/agents/forge-explorer.md` 有 IRON RULE："Agents do NOT write artifacts directly"
- 同一 dimension 的扫描结果还包括：观察到 `plugins/forge/skills/forge/` 下存在 `status.mjs`，由此推断 "business logic should not live in the orchestrator"（这是从目录结构 + 命名推断的 pattern，没有编译/测试/IRON RULE 强制）

**Flow:**
1. Extraction 得到两条候选 claim：
   - Claim A（来源：`forge-explorer.md` IRON RULE 段）— "Agents do NOT write artifacts directly"
   - Claim B（来源：对 `skills/forge/` 目录和 `status.mjs` 命名的推断）— "business logic should not live in orchestrator"
2. 按 `architecture-layers.md` 的 Claim Classification Annotations 表：
   - Claim A 匹配 "Import-direction rule backed by IRON RULE in a SKILL.md / agent file" → 类别 `enforced-rule` / confidence `[high] [code]` / 目标 `architecture.md § Enforced Rules`
   - Claim B 匹配 "`What to avoid` soft guidance" → 类别 `recommended-pattern` / confidence `[medium] [code]` / 目标 `architecture.md § Recommended Direction`
3. R15 的 Iron Rule 校验：两条 claim 均已分类，可 render；R16 校验：`enforced-rule` 要求 `[high]` ✓；`recommended-pattern` 要求 `[medium]` ✓
4. Render：
   - Enforced Rules 段：`- Agent 禁止直接写 .forge/；agent 向 skill 返回 report 文本 [high] [code] (IRON RULE in plugins/forge/agents/forge-explorer.md:12)`
   - Recommended Direction 段：`- 业务逻辑不要放在 forge orchestrator；放到具体 skill [medium] [code]`（无 MUST / NEVER / ONLY，符合 K-11 与 R16 对 `recommended-pattern` 的措辞要求）

**Decisions exercised:** K-1 (distributed annotation drives routing), K-5 (three-section architecture), K-11 (IRON RULE = enforced-rule), R15, R16

**Walkthrough result:** ✅ passes — 分类把"曾混在 'What to avoid' 的两类 claim"清晰分流；IRON RULE-backed claim 保留强措辞与 [high]；推断型 pattern 落入 Recommended Direction 并软化措辞；无 `[inferred]` 进入 Enforced Rules

---

## Impact Analysis

| Area | Risk | Description |
|------|------|-------------|
| `plugins/forge/skills/onboard/SKILL.md` | Medium | 核心 skill 文件新增 3 条 Iron Rule + 4 处 Step 内改动。长 SKILL.md 易引起 LLM 理解漂移；T032 应保持变更集中在新增段落，不打散已有 R1–R14 顺序 |
| 下游 skill（clarify / design / code / inspect / test）读 context 文件 | Low | 代码搜索已验证：下游 skill 不对 context 文件的特定 h2/h3 section 名做 grep 硬匹配（本会话 `grep -r '## Hard Constraints\|## Enforced Rules\|...'` 结果 = none）。assumption 1 验证通过，不再是 risk |
| 自宿主 `.forge/context/`（本仓库） | Medium | ship 后首次运行必须 `--regenerate`；preserve block 当前为 0（验证：`grep -r 'forge:preserve' .forge/context/` 为空），不存在跨 schema 迁移压力。assumption 2 验证通过 |
| `docs/` (read-only 设计文档) | Low | 本 feature 不改 `docs/forge-plugin-design.md` / `detailed-design.md` / `artifact-structure.md`；仅新增 `docs/upgrade-0.6.md` |
| 后续 feature `onboard-change-navigation`（priorities 4–5） | Low | 本 feature 的 6 类 claim model + per-dim annotations 模板，为 Change Navigation Map 的分类提供了基础；两 feature 解耦 |
| profile 文件 applies-to 清空的 `local-dev.md` | Low | Stage 1 不加载；`/forge:inspect` structural scan 也不扫 orphan profile。deprecation comment 是唯一活的信号 |

**Feature 整体风险：Medium**

主要风险点：
1. T032 SKILL.md 重写幅度大（3 新 Iron Rule + 4 处 Step 改动 + pre-redesign detection 算法草案）；如果 T032 Iron Rule 措辞不精确，T035–T038 / T040 的 annotation 都会受影响 → 缓解：T032 写完后 `/forge:inspect` 先走一遍 SKILL.md，再进入 Wave 2
2. T042 verification 是 end-to-end 自举测试；首次 run 若失败需回到某 dimension 文件调整分类 table → 缓解：T042 acceptance criteria 明确到每条 SC 的验证方法

---

## Key Decisions

| # | Decision | Options Considered | Chosen | Rationale |
|---|----------|--------------------|--------|-----------|
| K-1 | Claim classification mechanism location | A: distributed annotations per dim / B: central reference file + hints | **A** | 对 prompt-execution 系统，co-location 比 centralization 更稳；LLM 处理 dim N 时分类指引与抽取同场出现（DI-2 explicit 要求） |
| K-2 | Iron Rule 拆分 | 合一条大 Rule / 拆 3 条 | **拆 3 条**（R15 / R16 / R17） | R15 = classification required；R16 = confidence floor + inferred 软路由；R17 = execution-content exclusion。三者正交，违反时 halt message 可指向精确原因 |
| K-3 | `local-dev.md` profile 物理文件处置 | 删除 / 保留 + deprecation header | **保留 + deprecation header + 清空 applies-to** | git 历史已足够 recover；保留便于未来以 gated 形式重启；清空 applies-to 确保 Stage 1 绝不加载 |
| K-4 | `deployment.md` profile 是否全删 | 全删（同 local-dev）/ 收窄 | **收窄到单行架构事实**（platform + manifest location） | brief 允许"对 code understanding 有强价值"的 exception；"Target: Kubernetes via Helm in `helm/<name>/`" 告诉开发者 deploy manifest 在哪，属于架构事实；deploy trigger / image registry / rollback 属运行时期望，删除 |
| K-5 | `architecture.md` 顶层章节结构 | flat / 3 段（Observed / Enforced / Recommended） | **3 段** | brief § Section Intent 明确要求；分离观察事实 / 强制规则 / 建议方向三层语义 |
| K-6 | `constraints.md` 顶层章节结构 | flat / 3 段（Hard / Process / Caveats） | **3 段** | brief § Section Intent；Hard Constraints 不混 process；caveats 不混 hard rules |
| K-7 | Delivery expectations 归属 | 新建 delivery.md 独立文件 / 并入 conventions.md 一个 section | **并入 conventions.md § Delivery Conventions** | brief 明确要求 "No new standalone delivery.md" |
| K-8 | Pre-redesign detection 触发条件 | body-signature 不匹配 / section profile 指向已移除 dim / body 缺失新 Output Template 必需 anchors | **"body 缺失新 Output Template 必需 anchors"（正向 anchor 检查）** | 比 body-signature 对比更稳定（body-signature 每次 git commit 都可能变）；anchor 缺失是结构变更的最准确信号 |
| K-9 | `[inferred]` 允许出现的位置 | 完全禁止进 constraints.md / 仅允许进 § Current Business Caveats 并软化措辞 | **仅 § Current Business Caveats + 软化措辞**（由 clarify Q5-A 裁决） | 保留合法的推断型观察去处；强措辞路径仍被禁 |
| K-10 | testing-strategy.md sample-size → confidence tag 映射 | 无约束 / 固定规则 | **固定规则**：1 份 → `[low]`；2 份一致 → `[medium]`；≥3 份一致 → `[high]`；单文件推断 rule 不超 `[low]` | SC-9 可验性；避免泛化从少量样本 |
| K-11 | IRON RULE-backed constraint 分类 | enforced-rule / recommended-pattern | **enforced-rule** | brief 的 "framework constraints" 覆盖 skill framework；IRON RULE 违反会 halt run，等价于 runtime 强制；引用规则位置作证据 |
| K-12 | `commit-format.md` vs `delivery-conventions.md` 范围 | 混合 / 按内容拆分 | **拆分**：commit-format 只管 commit message 结构；task-commit 粒度 / testing-before-done / .forge update 归 delivery-conventions | 避免同一 conventions.md 两个 dim 内容重叠 |

---

## Constraints & Trade-offs

**排除的方向：**

1. **为本 feature 新建一个 `reference/claim-classification.md`（Option B）** — 虽然中央化更"干净"，但 DI-2 长 prompt 稳定性风险过高。
2. **同时实现 priorities 4–5（Change Navigation Map + deterministic extraction）** — 会把本 feature 扩到 ~20 任务 + 新 scripts/。clarify Q1-B 已锁 MVP=1–3。
3. **把 `deployment.md` 完全删除（对称于 local-dev）** — "本项目部署形态 = K8s" 是架构事实，对 code understanding 有正向价值；brief 留了"evidence 强 + 直接有用"的 exception 通道。
4. **增量 mode 自动 reclassify 旧内容** — 跨 schema 的自动合并易产出损坏产物；更稳的路径是 halt + `--regenerate`（clarify Q4-B）。
5. **在 render 后加 "分类 audit pass"（二次校验）** — 会让 SKILL.md 出现双层循环描述，增加理解成本；改由每 dim 的 Claim Classification Annotations 在 extraction 时就锁定分类，相当于"预防胜于事后检查"。

**已知 trade-off：**

- R15 策略表在 SKILL.md + 各 dim 之间有**概念上的重复**。未来扩类别或调映射时需同步多处。接受此 trade-off 以换取长 prompt 稳定性。
- Pre-redesign detection 的 anchor-based 检查对 Output Template 未来再次变更敏感。后续 feature（如 `onboard-change-navigation` 要改 architecture.md 模板）也可能触发一次 `--regenerate`。这是 schema-evolution 的固有代价。

---

## Convention Deviations

| Convention | Deviation | Reason |
|------------|-----------|--------|
| `.forge/context/conventions.md § SKILL.md Canonical body outline` — 规定 SKILL.md 顶层段落顺序为 Runtime snapshot / IRON RULES / Prerequisites / Process / Output / Interaction Rules / Constraints | 本 feature 在 IRON RULES 段内追加 R15/R16/R17；**不**新增额外顶级段 | 符合 convention 对 IRON RULES 的增量扩展语义；未破坏段序 |

_其余所有 convention 均严格遵守（naming / section markers / markdown conventions / commit format / artifact writing discipline）。_

---

## Embedded Spec-Review Self-Run (Stage 3, R19)

```
[forge:design] Embedded spec-review (Stage 3) — 2026-04-24

Checking design against clarify.md Success Criteria + Gaps...

Success Criteria coverage:
  ✅ SC-1  onboard.md excludes execution-layer   → R17 (T032) + T033 (local-dev) + T034 (deployment)
  ✅ SC-2  architecture.md 3-section             → T035 (arch-layers rewrite) + K-5
  ✅ SC-3  constraints.md 3-section              → T036 (hard-constraints) + T037 (anti-patterns) + K-6
  ✅ SC-4  conventions.md Delivery Conv          → T038 (new dim) + T039 (kind manifests)
  ✅ SC-5  classification drives routing         → R15 (T032) + dim annotations (T035 / T036 / T037 / T038 / T041)
  ✅ SC-6  [inferred] soft routing               → R16 (T032) + K-9
  ✅ SC-7  pre-redesign detection                → T040 + K-8
  ✅ SC-8  local-dev removed                     → T033
  ✅ SC-9  testing.md sample-size floor          → T041 + K-10

Gap coverage:
  ✅ G-1 (no classification layer)               → R15 + T035–T038, T041
  ✅ G-2 (local-dev active)                      → T033
  ✅ G-3 (arch-layers Output Template flat)      → T035
  ✅ G-4 (hard/anti-patterns no 3-split)         → T036 + T037
  ✅ G-5 (no Delivery Conv section)              → T038 + T039
  ✅ G-6 (no per-artifact confidence floor)      → R16 (T032)
  ✅ G-7 (no pre-redesign detection)             → T040
  ✅ G-8 (no execution-layer exclusion policy)   → R17 (T032) + T034
  ✅ G-9 (testing-strategy no sample-size guard) → T041

Orphan design (components not traceable to SC/Gap):
  (none) — 每个新 / 改动组件均回溯到至少一条 SC 或 Gap

Decision: PASS — proceeding to Stage 4 task decomposition.
```

---

## Open Decisions

_None_ — Stage 2 期间无 decision 被 defer；三条 clarify assumption（下游 skill 结构不变读、preserve block 稀少、deployment.md 保留收窄）在 Impact Analysis 中通过实测（grep）+ 明确 Key Decision 落定。

| # | Question | Context | Status |
|---|----------|---------|--------|
| — | — | — | — |

---

## Dogfooding Strategy

forge 仓库本身就是 plugin-kind 目标项目；本 feature 实现后：

1. **T042 verification** 直接在 forge 仓库 `--regenerate`，验证 SC-1..9 全部成立：
   - onboard.md 不含 Local Development / Docker 命令 / env 复制（SC-1）
   - architecture.md 的 architecture section 下出现 `### Observed Structure` / `### Enforced Rules` / `### Recommended Direction`（SC-2）
   - constraints.md 出现 `## Hard Constraints` / `## Process / Quality Gates` / `## Current Business Caveats`（SC-3）
   - conventions.md 新增 `## Delivery Conventions`（SC-4）
   - 抽查 10 条 bullet 的分类落点（SC-5）；搜 `[inferred]` 确认仅出现在允许位置（SC-6）
   - 构造 pre-redesign fixture：移除新 h3 anchors → 跑非 regenerate onboard → 应 halt（SC-7）
   - grep kind manifests 无 `core/local-dev`（SC-8）
   - testing.md 每条 rule 回溯 sample 数（SC-9）
2. verification.md 作为 T042 产物，存 `.forge/features/onboard-evidence-first/verification.md`

3. **后续 MVP 落地后对比指标**：
   - `.forge/context/onboard.md` 行数下降（Local Development 段被删）
   - `.forge/context/architecture.md` 行数上升（三段拆开 + 标注来源）
   - `.forge/context/constraints.md` 行数不变或小幅上升
   - `.forge/context/conventions.md` 行数上升（新增 Delivery Conventions 段）

---

## Next Step

```
/forge:code T032
```

T032 是 SKILL.md foundation 任务，Wave 1 的唯一项；Wave 2 八个 task 在 T032 完成后可全部并行。
