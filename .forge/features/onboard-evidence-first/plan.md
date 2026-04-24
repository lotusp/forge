# Plan: onboard-evidence-first

> 基于：`.forge/features/onboard-evidence-first/design.md`
> 生成时间：2026-04-24
> 生成方式：/forge:design（Stage 4）
> 目标版本：forge 0.6.0（evidence-first redesign — MVP priorities 1–3）

---

## 概览

把 `/forge:onboard` 从 prompt-driven summarizer 升级为 evidence-first context compiler：
引入 6 类 claim classification + 按分类路由到产物章节 + 收紧 `[inferred]` 软路由 +
移除执行层内容（local-dev profile）+ 收窄 deployment profile + 三段式 architecture.md
/ constraints.md + 新增 Delivery Conventions 维度 + Stage 3 pre-redesign detection
触发 `--regenerate` 升级。

**12 个任务（T032–T043），3 个高风险。5 个执行波次。**

---

## Task List

### T032 — 重写 onboard SKILL.md：R15/R16/R17 Iron Rules + Stage 2/3 classify 子步 `skill` ⚠

**描述：** 在 `plugins/forge/skills/onboard/SKILL.md` 的 IRON RULES 段内追加 3 条新规则，并在 Process 的 Step 2、Step 4、Step 6 三处插入 "classify claims before render / before route" 子步。同时 Runtime snapshot 追加 "pre-redesign sections detected?" 检测行的触发点。

**依赖：** 无

**范围：**
- `plugins/forge/skills/onboard/SKILL.md`

**变更内容：**
- **R15 — Claim classification required before render**
  - 正文说明：Stage 2 / Stage 3 中，每条抽取后的 fact 必须先归入六类之一（`fact` / `inference` / `enforced-rule` / `recommended-pattern` / `process-rule` / `current-caveat`），再进入 Section Template / Output Template render
  - 附 6 类 × 允许 artifact × 允许 section 的主映射表（与 design.md § Wire Protocol Example #4 的 annotations schema 保持一致的用语）
- **R16 — Per-artifact confidence floors**
  - `enforced-rule` 必须 `[high]` + 来源 `[code]` 且证据为 compile/test/static-check/framework/IRON-RULE 文件
  - `[inferred]` 禁止出现在 `architecture.md § Enforced Rules` 与 `constraints.md § Hard Constraints`；允许出现在 `onboard.md` 正文段 + `constraints.md § Current Business Caveats`，并必须软化措辞（"appears to"、"likely"、"seems"），严禁 MUST / NEVER / ONLY / ENFORCED
  - `recommended-pattern` 最低 `[medium]`
- **R17 — Execution-content exclusion policy**
  - 以下内容类型在所有产物中禁止出现：
    - shell code block 含 `docker`、`npm install`、`pnpm install`、`pip install`、`make <target>`、`poetry install`、`cargo build` 等启动/构建命令
    - `.env` / 配置模板的复制指令
    - 部署命令（`kubectl apply`、`helm upgrade`、`gcloud deploy` 等）
    - 环境特定 URL / registry 地址 / secret path
  - 例外：当信息是"项目会以 X 形态部署"这样的**架构事实**（platform + manifest 位置）时允许，且必须以单行陈述呈现
- **Step 2 (Stage 2 read-do-discard) 插入子步** "2.X — Classify extracted facts"：在 `extracted = extract(rules, evidence)` 之后、`render(template, extracted)` 之前，对每条 fact 查该 profile 的 Claim Classification Annotations；若无匹配则按 R15 映射表默认归 `fact` 进 `onboard.md`
- **Step 4 (Stage 3.1 non-interactive scan) 插入子步** "4.X — Classify and pre-route"：在 `facts = extract(...)` 之后、`evidence_by_dim[dim_path] = facts` 之前，对每条 fact 标注类别 + 目标 artifact + 目标 section；存为增强 evidence 结构
- **Step 6 (Stage 3.3/3.4 smart-merge + write) 前置新子步** "6.0 — Pre-redesign format detection"：遍历 existing context files 的 section markers，检查 `profile` 属性 + body 必需 h3 anchors；若发现 pre-redesign section 且 `mode != regenerate` → 输出 Wire Protocol #5 halt message，run 终止
- **Step 6 正文修改：** smart-merge 里，render 改用 "classification 路由器"：同一 dim 可能产出多个 section（如 anti-patterns.md 同时产 Current Business Caveats 和 Recommended Direction），按 fact 的 target-section 分发
- Runtime snapshot 追加一行：`- Pre-redesign sections: !`grep -L '### Observed Structure\|### Enforced Rules' .forge/context/architecture.md 2>/dev/null && echo "maybe stale" || echo "(ok or absent)"``

**验收标准：**
- [ ] SKILL.md 顶层段序未变（Runtime snapshot / IRON RULES / Prerequisites / Process / Output / Interaction Rules / Constraints）
- [ ] IRON RULES 段存在 R15 / R16 / R17 三条新规则，格式与 R1–R14 一致（`### R15 — {title}` 开头，正文祈使句）
- [ ] Step 2 / Step 4 / Step 6 三处的 classify 子步均引用 R15 + 各 dim 的 Claim Classification Annotations
- [ ] Step 6.0 Pre-redesign detection 伪代码 + halt message 字面量齐备
- [ ] `/forge:inspect` 针对该 SKILL.md 扫描通过（section marker / IRON RULE 形态合规）

**规模预估：** medium–large（估 +200..+350 行 SKILL.md）

---

### T033 — 从 4 个 Stage-2 kind manifest 移除 `core/local-dev` + `local-dev.md` profile 加 deprecation header `kind-def`

**描述：** 从 plugin / web-backend / web-frontend / monorepo 四个 kind manifest 的 `profiles[]` 中删除 `core/local-dev`（若 `output-sections:` 列出 Local Development 也一并删）。同时在 `profiles/core/local-dev.md` 顶部加 deprecation comment 并清空 frontmatter `applies-to:`。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/kinds/plugin.md`
- `plugins/forge/skills/onboard/profiles/kinds/web-backend.md`
- `plugins/forge/skills/onboard/profiles/kinds/web-frontend.md`
- `plugins/forge/skills/onboard/profiles/kinds/monorepo.md`
- `plugins/forge/skills/onboard/profiles/core/local-dev.md`

**验收标准：**
- [ ] 4 个 kind manifest `grep -c 'core/local-dev'` 均返回 0
- [ ] 4 个 kind manifest 的 `output-sections:` 不含 "Local Development"
- [ ] `profiles/core/local-dev.md` 首行（frontmatter 上方）插入 `<!-- forge:deprecated since=v0.6.0 reason="execution-layer content excluded by onboard-evidence-first redesign" -->`
- [ ] `profiles/core/local-dev.md` frontmatter `applies-to:` 为空列表（或整个 key 删除）
- [ ] `grep 'core/local-dev' plugins/forge/skills/onboard/profiles/**/*.md` 全局命中 0（除 local-dev.md 自己）

**规模预估：** small

---

### T034 — 收窄 `deployment.md` profile：Section Template 仅保留单行架构事实 `profile`

**描述：** 将 `plugins/forge/skills/onboard/profiles/structural/deployment.md` 的 Section Template 压缩为单行 "**Target:** `<platform>` via `<manifest-path>`"。移除 Environments / Deploy trigger / Image registry / Rollback / Infrastructure 五个 bullet。Extraction Rules 相应精简。新增 `## Claim Classification Annotations`：Target 行归 `fact`，目标 `onboard.md § Deployment`，min confidence `[high]` + 来源 `[config]`/`[build]`。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/structural/deployment.md`

**验收标准：**
- [ ] Section Template 只有一行 Target 陈述 + 可选 1 行备注（如 "部署发生在 sub-package 层面，见对应子项目"）
- [ ] 旧模板中 Environments / Deploy trigger / Image registry / Rollback / Infrastructure 五段移除
- [ ] `## Claim Classification Annotations` 子段存在，表头含 `| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |`
- [ ] `grep -E 'kubectl|helm upgrade|docker push|gcloud'` 在 Section Template 中返回 0

**规模预估：** small

---

### T035 — 重写 `architecture-layers.md` dimension：三段 Output Template + Classification Annotations `profile`

**描述：** 重写 `plugins/forge/skills/onboard/profiles/context/dimensions/architecture-layers.md` 的四个 kind 的 Output Template，每个都拆为 `### Observed Structure` / `### Enforced Rules` / `### Recommended Direction` 三个子段。原 "What to avoid" 段全部迁入 Recommended Direction 并降级为 `recommended-pattern`。新增 `## Claim Classification Annotations` 子段，按 design.md § Wire Protocol Example #4 的格式落地。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/context/dimensions/architecture-layers.md`

**验收标准：**
- [ ] 四个 Output Template（web-backend / web-frontend / plugin / monorepo）均出现 `### Observed Structure` / `### Enforced Rules` / `### Recommended Direction` 三个必需 h3 anchor
- [ ] Enforced Rules 段示例中每条 bullet 都 **引用** 具体 enforcement 来源（IRON RULE 位置 / static check / framework 约束），不接受纯 directory-layout 证据
- [ ] `## Claim Classification Annotations` 子段存在，至少覆盖 5 种 extracted fact type；必须明确列出 "Forbidden routes"（如 directory-layout-observation → NOT Enforced Rules）
- [ ] 全文无 "What to avoid" 独立段（已迁入 Recommended Direction）

**规模预估：** medium

---

### T036 — 重构 `hard-constraints.md` dimension：仅产 Hard Constraints + Classification Annotations `profile`

**描述：** `plugins/forge/skills/onboard/profiles/context/dimensions/hard-constraints.md` 的 Extraction Rules 收窄：只接受 `enforced-rule` + `[high]` + 证据来源为 code/test/static-check/framework/IRON-RULE 的 claim。process-rule 类（如 "task 完成后独立 commit"）**不再**由本 dim 抽取，改由新 delivery-conventions.md（T038）承接。Output Template 顶层为 `## Hard Constraints`，维持现有 C1/C2/... 结构化子条目。新增 `## Claim Classification Annotations`。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/context/dimensions/hard-constraints.md`

**验收标准：**
- [ ] Output Template 只产出 `## Hard Constraints` 单个顶层章节
- [ ] Extraction Rules 明确写明 "process expectations are routed to delivery-conventions, not this dimension"
- [ ] `## Claim Classification Annotations` 列出：接受 `enforced-rule`；拒绝 `process-rule` / `current-caveat` / `inference`
- [ ] 每条示例 Hard Constraint 都给出 enforcement 来源（IRON RULE 位置 / SKILL.md Constraints 段）

**规模预估：** small–medium

---

### T037 — 重构 `anti-patterns.md` dimension：split Current Business Caveats + Recommended Direction `profile`

**描述：** `plugins/forge/skills/onboard/profiles/context/dimensions/anti-patterns.md` 拆分产出路径：真 `current-caveat`（时间绑定、项目特有的临时状况）→ `constraints.md § Current Business Caveats`（允许 `[inferred]` + 软化措辞）；推断型 anti-pattern（如 "avoid putting business logic in orchestrator"）→ `architecture.md § Recommended Direction` 或 `conventions.md`。process 期望全部移到 delivery-conventions（T038）。新增 `## Claim Classification Annotations`。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/context/dimensions/anti-patterns.md`

**验收标准：**
- [ ] Output Template 声明可能产出的多个 section（Current Business Caveats / Recommended Direction）及归属文件
- [ ] `## Claim Classification Annotations` 明确：`current-caveat` + `[inferred]` → Current Business Caveats（软化措辞）；`recommended-pattern` → architecture.md Recommended Direction；`process-rule` → 由 delivery-conventions 承接、不由本 dim 产出
- [ ] Extraction Rules 明确每类证据如何归位，示例充分
- [ ] 全文无 "Known Technical Debt 表" 硬编码（该表在当前 forge 的 anti-patterns 里出现过，应通过分类机制自动归位，不特殊处理）

**规模预估：** medium

---

### T038 — 新建 `delivery-conventions.md` dimension `profile`

**描述：** 新建 `plugins/forge/skills/onboard/profiles/context/dimensions/delivery-conventions.md`，承接 commit-format 范围外的 delivery 期望：task-to-commit granularity、testing-before-done、.forge artifact update expectations、summary/review 期望（如适用）。Scan Sources 包括 CLAUDE.md（Git Commit Convention / Commit cadence 段）、`.forge/JOURNAL.md`（实际 commit 节奏）、existing `verification.md` 文件（testing-before-done 模式）。该 dimension 的路由权威沿用本 feature 的统一机制：**Claim Classification Annotations + context kind manifests** 决定 claim 落到 `conventions.md § Delivery Conventions`（for fact / recommended-pattern）或 `constraints.md § Process / Quality Gates`（for `process-rule`）；**不引入** 新的 dual-output-file frontmatter 语义。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/context/dimensions/delivery-conventions.md`（NEW）

**验收标准：**
- [ ] 新文件带完整 frontmatter，且遵守现有 dimension schema；**不得**引入 `output-file: primary/secondary` 之类的新语义。至少包含：`name: delivery-conventions` / `applies-to: [plugin, web-backend, web-frontend, monorepo]` / `scan-sources:` / `token-budget`
- [ ] Scan Patterns 至少列出：CLAUDE.md Git Commit Convention 段 / .forge/JOURNAL.md commit 节奏 / verification.md 存在与否
- [ ] Extraction Rules 涵盖 4 类：task-commit granularity / testing-before-done / .forge artifact update / summary expectations
- [ ] `## Claim Classification Annotations` 明确：事实类（"每个 task 独立 commit"）→ conventions.md § Delivery Conventions；process 强约束（"未做 verification 不算完成"）→ constraints.md § Process / Quality Gates
- [ ] Output Template 同时包含 `## Delivery Conventions`（conventions.md 用）与 `## Process / Quality Gates`（constraints.md 用）两份 template，字面分开标注用途

**规模预估：** medium

---

### T039 — 更新 4 个 context kind manifest：加入 `dimensions/delivery-conventions` + 调整路由 `kind-def`

**描述：** 在 `plugins/forge/skills/onboard/profiles/context/kinds/{plugin,web-backend,web-frontend,monorepo}.md` 的 `dimensions-loaded:` 下的 `conventions.md:` 和 `constraints.md:` 两组，追加 `dimensions/delivery-conventions`。同步更新 `output-files:` 确保不变。若 excluded-dimensions 有变化也更新。

**依赖：** T038

**范围：**
- `plugins/forge/skills/onboard/profiles/context/kinds/plugin.md`
- `plugins/forge/skills/onboard/profiles/context/kinds/web-backend.md`
- `plugins/forge/skills/onboard/profiles/context/kinds/web-frontend.md`
- `plugins/forge/skills/onboard/profiles/context/kinds/monorepo.md`

**验收标准：**
- [ ] 4 个 kind manifest 的 `dimensions-loaded → conventions.md` 含 `dimensions/delivery-conventions`
- [ ] 4 个 kind manifest 的 `dimensions-loaded → constraints.md` 含 `dimensions/delivery-conventions`（用于 Process / Quality Gates 分支）
- [ ] excluded-dimensions 注释更新：标明 delivery-conventions 为新维度，不再 excluded
- [ ] `output-files:` 不变（仍是 conventions.md / testing.md / architecture.md / constraints.md 的 kind-applicable 子集）

**规模预估：** small

---

### T040 — Pre-redesign format detection：SKILL.md Step 6 + `reference/incremental-mode.md` 算法展开 `skill` ⚠

**描述：** T032 已在 SKILL.md Step 6 插入 "6.0 — Pre-redesign format detection" 的调用点；本任务把**算法细节**写入 `plugins/forge/skills/onboard/reference/incremental-mode.md` 新段 `## Pre-redesign format detection`，包括：遍历 existing context files 的 section markers、从 markers 的 `profile` 属性查当前 kind 的 dimension 注册表、对每个 section 检查其 body 是否包含该 dimension 的 Output Template 所要求的必需 h3 anchors（anchor 白名单来自 dimension 文件）、发现缺失即标为 pre-redesign、如果 `mode != regenerate` 则 halt。SKILL.md 中的伪代码相应被替换为 "详见 reference/incremental-mode.md § Pre-redesign format detection"。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/SKILL.md`（Step 6 伪代码区微调，引用 reference）
- `plugins/forge/skills/onboard/reference/incremental-mode.md`（新增 `## Pre-redesign format detection` 段）

**验收标准：**
- [ ] `reference/incremental-mode.md` 新段包含：检测算法伪代码（输入：existing `.forge/context/*.md` + 当前 kind's dimensions-loaded 清单；输出：`pre_redesign_sections[]`）、anchor 白名单来源说明、halt 条件、halt message 字面量（与 design.md Wire Protocol #5 一致）
- [ ] SKILL.md Step 6.0 伪代码区清晰表明 "detection 在 smart-merge 之前执行；regenerate mode 下 detection 仅 log 不 halt"
- [ ] `/forge:inspect` 对这两个文件均通过

**规模预估：** medium

---

### T041 — Sample-size → confidence floor in `testing-strategy.md` `profile`

**描述：** 在 `plugins/forge/skills/onboard/profiles/context/dimensions/testing-strategy.md` 的 Extraction Rules 新增 "Sample-size → confidence tag" 规则：1 份样本 → `[low]`；2 份一致 → `[medium]`；≥3 份一致 → `[high]`；单文件推断规则不超 `[low]`。新增 `## Claim Classification Annotations`：测试策略事实（framework / 目录 / base class）归 `fact`；测试期望（"完成前必须跑 X"）归 `process-rule` 并路由到 delivery-conventions（不在本 dim 产出）；"avoid" 类指导归 `recommended-pattern`。

**依赖：** T032

**范围：**
- `plugins/forge/skills/onboard/profiles/context/dimensions/testing-strategy.md`

**验收标准：**
- [ ] Extraction Rules 明确列出 1/2/≥3 三档 sample-size 到 confidence tag 的映射
- [ ] `## Claim Classification Annotations` 子段存在，且明确写明 process-rule 类内容不由本 dim 产出（去重 T038）
- [ ] Output Template 每条示例 bullet 都能回溯到具体 sample count 注释
- [ ] 保留四个 kind 各自 Output Template（web-backend / web-frontend / plugin / monorepo），格式一致

**规模预估：** small–medium

---

### T042 — 验证：`--regenerate` 自宿主 + SC-1..9 逐条核验，产出 `verification.md` `docs` ⚠

**描述：** 在当前 forge 仓库运行 `/forge:onboard --regenerate`，检查产出的 5 个 context 文件严格符合 SC-1..9，并构造一个 pre-redesign fixture（改动一个 section body 去掉新 h3 anchor）验证 SC-7 halt 行为。把完整验证报告写入 `.forge/features/onboard-evidence-first/verification.md`（与 `plugin-bootstrap` / `onboard-kind-profiles` / `lean-kind-aware-pipeline` 的 verification.md 同结构）。

**依赖：** T032, T033, T034, T035, T036, T037, T038, T039, T040, T041（全部实现 task 完成）

**范围：**
- `.forge/features/onboard-evidence-first/verification.md`（NEW）
- 可能改动（re-generate 结果）：`.forge/context/onboard.md`、`architecture.md`、`constraints.md`、`conventions.md`、`testing.md`（属于验证产物，不在源码改动集）

**验收标准：**
- [ ] verification.md 按 SC-1..9 逐条列出：验证方法 + 观察结果 + PASS/FAIL；目标全 PASS
- [ ] SC-1：`grep -E 'docker compose|pnpm install|npm install|pip install|kubectl|helm upgrade|\.env' .forge/context/onboard.md` 命中 0
- [ ] SC-2：`.forge/context/architecture.md` 的 architecture section 下必含 h3 anchors `### Observed Structure|### Enforced Rules|### Recommended Direction`
- [ ] SC-3：`.forge/context/constraints.md` 必含 `## Hard Constraints|## Process|## Current Business Caveats`（子串匹配允许 `## Process / Quality Gates`）
- [ ] SC-4：`.forge/context/conventions.md` 必含 `## Delivery Conventions`；`.forge/context/delivery.md` 不存在
- [ ] SC-5：抽 10 条 bullet，人工标注分类；每条都落在 R15 允许的 artifact+section
- [ ] SC-6：`grep '[inferred]' .forge/context/{architecture,constraints}.md` 的命中结果：架构文件无命中；constraints 仅出现在 § Current Business Caveats 段内
- [ ] SC-7：构造 fixture（改 .forge/context/architecture.md 去掉 `### Observed Structure` h3）→ 跑 `/forge:onboard` 无 flag → 必须 halt 并输出 pre-redesign halt message；恢复 fixture 后 `--regenerate` 跑通
- [ ] SC-8：`grep -c 'core/local-dev' plugins/forge/skills/onboard/profiles/kinds/*.md` 命中 0
- [ ] SC-9：抽 testing.md 5 条 rule，回溯 sample size；tag 与映射一致
- [ ] verification.md 标注是否 fully-pass / conditional-pass / fail，并列出任何 conditional / fail 的原因

**规模预估：** large

---

### T043 — 更新用户面向文档：README.md / CLAUDE.md / docs/upgrade-0.6.md `docs`

**描述：** 按 R20 "plan.md ends with a mandatory T{last} docs task"，把本 feature 的用户面向影响写入：README badge 更新至 0.6.0（或 0.6.0-dev 视正式发布时机）+ "v0.6.0 is here" 精简变更告知链接；CLAUDE.md 的 "Core Design Principles" 补 "Claim classification before render" 一条、Stage 3 描述更新；docs/upgrade-0.6.md（新文件）作为迁移向导（breaking changes 列表、`--regenerate` 步骤、preserve-block 保留说明、pre-redesign halt message 示例）。若某文件实际不需要改动，需在 task summary 明确记录 "No user-facing changes needed for <file>"。

**依赖：** T042

**范围：**
- `README.md`
- `CLAUDE.md`
- `docs/upgrade-0.6.md`（NEW）

**验收标准：**
- [ ] README.md badge 与当前 plugin.json version 同步；README 顶部或 "v0.6.0" 段描述 evidence-first redesign 要点（3–5 行）
- [ ] CLAUDE.md "Core Design Principles to Uphold When Implementing Skills" 段新增 "Claim classification — every fact classified before render; category drives artifact placement" 条目；"Skill Flow" 段的 `onboard` 描述补 MVP 改动摘要
- [ ] `docs/upgrade-0.6.md` 文件存在，含：breaking changes 清单 / 升级步骤（stop → regenerate → review preserve blocks）/ FAQ 5 问 / 回滚说明
- [ ] task summary（`.forge/features/onboard-evidence-first/tasks/T043-summary.md`）显式记录任何 "No user-facing docs touched by this feature for <file>" 情况

**规模预估：** small–medium

---

## Dependency Graph

```
              T032 (SKILL.md foundation)
              /   /   |   |   |   |   |   \
             /   /    |   |   |   |   |    \
          T033 T034 T035 T036 T037 T038 T040 T041
                                    │
                                    ▼
                                   T039 (kind manifests)
                                    │
         ┌──────────────────────────┘
         │
         ▼
       T042 (verification — depends on ALL impl tasks)
         │
         ▼
       T043 (docs — R20 mandatory)
```

---

## Execution Waves

| Wave | Tasks | Run mode |
|------|-------|----------|
| 1 | T032 | Serial — blocks everything downstream |
| 2 | T033, T034, T035, T036, T037, T038, T040, T041 | **Parallel**（互不依赖；均仅依赖 T032） |
| 3 | T039 | Serial — depends on T038 |
| 4 | T042 | Serial — depends on Wave 1+2+3 全部完成 |
| 5 | T043 | Serial — R20 mandatory，depends on T042 |

**建议节奏：**
- Wave 1 完成后跑一次 `/forge:inspect onboard-evidence-first`（仅扫 SKILL.md 变动是否合规）
- Wave 2 八个 task 可并行；完成后整体再跑 `/forge:inspect` 一次
- Wave 3 完成后进入 Wave 4 verification；verification 若 FAIL，回到相关 task 修正（最可能回 T035 / T037 — 分类表措辞或 Output Template anchor 不齐）
- Wave 5 T043 在 verification 通过后再做，避免 docs 描述偏离实际行为

---

## Risk Register

| Task | Risk | Mitigation |
|------|------|-----------|
| T032 | **High** — SKILL.md 幅度大；R15/R16/R17 措辞精度直接影响 Wave 2 各 dim 的 annotations | 完成后立即 `/forge:inspect` 一次 SKILL.md；用 2 个自然语言 example 验证 R15 映射表可用性 |
| T040 | **High** — pre-redesign detection 算法影响 incremental mode 正确性；anchor 白名单必须与 T035/T036/T037 保持一致 | 约束 anchor 白名单只从各 dimension 文件的 Output Template 中提取；T040 完成后跑 SC-7 fixture test |
| T042 | **High** — 首次 end-to-end 跑通不会一次成功；失败回滚到哪个 task 需判断 | verification.md 首行记录"当前 run 的上下文：commit / 各 task 完成状态"；失败时按 SC 逐项定位 |
| T037 | Medium | anti-patterns dim 重构涉及内容跨三 section 分化；测试样本须覆盖 current-caveat / recommended / process 三类 |
| T038 | Medium | 新 dim 需要把 claim 分流到 conventions/constraints 两处；必须坚持由 annotations + kind manifests 路由，不能再发明 dual-output-file frontmatter 语义；兼容性由 T042 验证 |
| T033 | Low | 纯删除 + deprecation header；回滚简单 |
| T034 | Low | 单 profile 的 template 收窄 |
| T035 | Low | Output Template 结构化改动，每 kind 一段，重复性高 |
| T036 | Low | Hard Constraints 范围收窄；改动集中 |
| T041 | Low | 新增 extraction rule + annotations；不破坏现有模板 |
| T039 | Low | 4 个 kind manifest 追加一行，对称改动 |
| T043 | Low | 纯 docs；如 verification 通过则文档顺水推舟 |

**高风险 task 数：3 个（T032 / T040 / T042）**

---

## Next Step

```
/forge:code T032
```
