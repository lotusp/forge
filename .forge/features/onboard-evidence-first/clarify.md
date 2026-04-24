# Clarify: onboard-evidence-first

<!-- clarify:self-review iterations=1 checks-run=5 majors-fixed=0 minors-reported=1 final=pass -->

> 原始需求：见 `docs/onboard-redesign-input.md`（intentional input brief for clarify/design — 包含 Problem Statement / Product Goal / Non-Goals / Redesign Direction / File-Level Responsibilities / Claim Classification Model / Evidence Discipline / Success Criteria / 以及 "Questions Clarify/Design Should Resolve" 完整章节）。
> 生成时间：2026-04-24

---

## Requirement Restatement

将 `/forge:onboard` 从 **prompt-driven summarizer** 重构为 **evidence-first context compiler**。新的内部执行模型是 `scan codebase → build evidence → classify claims → render context artifacts`：每条从代码中抽取出来的断言（claim），先按六类分类（`fact` / `inference` / `enforced-rule` / `recommended-pattern` / `process-rule` / `current-caveat`），再被 render 到与其**语义匹配**的产物文件（`onboard.md` / `architecture.md` / `conventions.md` / `testing.md` / `constraints.md`）。证据层与分类层是 **skill 内部机制**，不对最终用户暴露。

本 feature 的 MVP 范围聚焦 **可信度优先**（priorities 1–3）：

1. 收紧 evidence / confidence 规则（单来源 / 取样过小 / 冲突证据 不再写成 `[high]`；不可靠执行型信息不输出）
2. 强制 claim classification — 每条断言在进入 render 前分到 6 类之一；artifact 落点由分类决定，而不仅由 confidence 决定
3. 降低不稳定的 execution-layer 内容（本地启动脚本、Docker 启动命令、部署指令、env 复制步骤等）

Priorities 4–5（Change Navigation Map、count-based / route-based deterministic extraction 脚本）deferred 到后续 feature（候选 slug: `onboard-change-navigation`）。

本 feature 不改变 onboard skill 的三阶段骨架（Stage 1 kind 检测 / Stage 2 onboard.md 生成 / Stage 3 context files 生成）、不移除 kind-aware 能力、不破坏 preserve block / section marker / incremental reconciliation 语义。

---

## Current Implementation

### Entry Points

| Entry point | Path | Line | Description |
|-------------|------|------|-------------|
| `/forge:onboard` SKILL | `plugins/forge/skills/onboard/SKILL.md` | 1 | skill 主入口，定义三阶段流程 + 14 条 Iron Rules |
| Stage 2 profile loader | `plugins/forge/skills/onboard/SKILL.md` | 495–540 | Step 2 "read-do-discard" 循环，按 kind 的 `profiles[]` 顺序加载并 render |
| Stage 3 dimension scanner | `plugins/forge/skills/onboard/SKILL.md` | 650–790 | Step 4–6，扫描 dimension 证据 → 批量冲突解决 → smart-merge 写 context files |
| Kind manifests (Stage 2) | `plugins/forge/skills/onboard/profiles/kinds/*.md` | — | 4 个 kind：`plugin` / `web-backend` / `web-frontend` / `monorepo` |
| Kind manifests (Stage 3) | `plugins/forge/skills/onboard/profiles/context/kinds/*.md` | — | 同上 4 个 kind 的 context-dimension 清单 |
| Profiles (Stage 2) | `plugins/forge/skills/onboard/profiles/core/*.md`, `.../entry-points/*.md`, `.../integration/*.md`, `.../model/*.md`, `.../structural/*.md`, `.../monorepo/*.md` | — | 14 个 profile 文件 |
| Dimensions (Stage 3) | `plugins/forge/skills/onboard/profiles/context/dimensions/*.md` | — | 16 个 dimension 文件 |

### Execution Flow（现状）

```
Stage 1 (kind detection)
  └─ 读 profiles/kinds/*.md → score → 选 top kind → emit Execution Plan
       └─ 读 profiles/context/kinds/<kind>.md（dimension 清单）→ 合并到 plan

Stage 2 (onboard.md generation, read-do-discard loop)
  └─ for profile in plan.profiles[]:
       ├─ Read(profile file)
       ├─ apply Scan Patterns (Glob/Grep/Bash)   ← 原始 evidence
       ├─ apply Extraction Rules                  ← 提取结构化 facts
       ├─ render(Section Template, facts)         ← 直接输出 markdown
       └─ append section to onboard.md
       ↑ **NO classification step exists between extraction and render.**

Stage 3 (context files, scan + conflicts + merge)
  └─ Stage 3.1 scan: for dim in plan.context-dimensions[]:
       ├─ Read(dim file)
       ├─ apply Scan Patterns
       ├─ extract facts + detect conflicts
       └─ evidence_by_dim[dim] = facts
     Stage 3.2 batch conflict resolution (one interactive round)
     Stage 3.3 smart-merge with existing context files (R14)
     Stage 3.4 write .forge/context/{conventions,testing,architecture,constraints}.md
       ↑ **Same issue: no claim-classification step; all facts flow directly into the section template.**
```

### Data Flow（现状）

所有被提取出来的 fact 直接带上 R10 定义的 `[confidence]` 和 `[source?]` tag，然后进入 profile / dimension 自带的 Section Template。Template 内部混合多种语义（事实、推断、建议、强制规则），没有语义分层。典型的混合证据案例：

- `profiles/core/local-dev.md`（本地开发 profile）:
  - Section Template 产出 `docker compose up -d postgres redis` / `pnpm install` 等 shell 命令块
  - 这是 **执行层内容**（Docker 启动、env 复制），input brief 明确要求排除

- `profiles/context/dimensions/architecture-layers.md`（架构分层 dimension）:
  - Output Template 包含 "What to avoid" 段，内容如 "Business logic inside controllers/ — always delegate to services/"
  - 这类断言是 **recommended-pattern**（由目录布局观察得来），不是 **enforced-rule**（无编译 / 测试 / static check 强制）
  - 当前 template 把两者混在一起写入 `architecture.md`，等于把推断当成强制规则

- 当前 `.forge/context/onboard.md` 中 "~6 TODO markers" 是 **approximate count**
  - input brief 要求 count-based claims 必须 deterministic
  - 当前靠 LLM 近似估算，非脚本精确提取（该项 priority 5，本 feature 不解决，deferred）

---

## Affected Components

| Component | Path | Nature of Impact |
|-----------|------|-----------------|
| Onboard SKILL.md | `plugins/forge/skills/onboard/SKILL.md` | modified — 新增 Iron Rules（claim-classification、per-artifact confidence floor、execution-content exclusion policy、pre-redesign detection + regenerate notice）；Stage 2 / Stage 3 process 增加 classification step |
| Kind manifest: plugin | `plugins/forge/skills/onboard/profiles/kinds/plugin.md` | modified — 移除 `local-dev` profile 引用 |
| Kind manifest: web-backend | `plugins/forge/skills/onboard/profiles/kinds/web-backend.md` | modified — 移除 `local-dev` profile 引用 |
| Kind manifest: web-frontend | `plugins/forge/skills/onboard/profiles/kinds/web-frontend.md` | modified — 移除 `local-dev` profile 引用 |
| Kind manifest: monorepo | `plugins/forge/skills/onboard/profiles/kinds/monorepo.md` | modified — 移除 `local-dev` profile 引用 |
| Profile: local-dev | `plugins/forge/skills/onboard/profiles/core/local-dev.md` | removed — 本 feature 后该文件不再被任何 kind 引用；design 阶段决定是保留但 orphan，还是直接删除 |
| Profile: deployment | `plugins/forge/skills/onboard/profiles/structural/deployment.md` | modified — 产出需限制在 **架构事实** 范围（"此项目会被部署成 X 形态"），**排除** 部署命令 / secret 路径 / registry 地址；design 决定是否需要保留此 profile |
| Dimension: architecture-layers | `plugins/forge/skills/onboard/profiles/context/dimensions/architecture-layers.md` | modified — Output Template 拆成三段（Observed Structure / Enforced Rules / Recommended Direction）；"What to avoid" 降级为 Recommended Direction |
| Dimension: hard-constraints | `plugins/forge/skills/onboard/profiles/context/dimensions/hard-constraints.md` | modified — 只产出 Hard Constraints；process-rule 内容迁到其他 dimension |
| Dimension: anti-patterns | `plugins/forge/skills/onboard/profiles/context/dimensions/anti-patterns.md` | modified — 审视 output 归类：真 `current-caveat` 保留，推断型 anti-pattern 降级 |
| New dimension: delivery-conventions | `plugins/forge/skills/onboard/profiles/context/dimensions/delivery-conventions.md` | **new** — 汇总 commit format / task-commit granularity / testing-before-done / `.forge` artifact update expectations；通过分类与 kind-manifest 路由写入 `conventions.md` 的 "Delivery Conventions" 段和 `constraints.md` 的 "Process / Quality Gates" 段 |
| Dimension: commit-format | `plugins/forge/skills/onboard/profiles/context/dimensions/commit-format.md` | modified — 范围收窄为 commit message 结构本身；task-commit 粒度等内容迁入 delivery-conventions |
| Context kind manifest: all | `plugins/forge/skills/onboard/profiles/context/kinds/{plugin,web-backend,web-frontend,monorepo}.md` | modified — 引入 delivery-conventions dimension；调整 hard-constraints / anti-patterns 映射 |
| Incremental mode reference | `plugins/forge/skills/onboard/reference/incremental-mode.md` | modified — 新增 "pre-redesign format detection → surface regenerate notice" 流程 |
| CLAUDE.md | `CLAUDE.md` | modified — project-wide AI context 需同步 onboard 的 evidence-first 语义（claim classification before render + Stage 3 新的 context 章节结构）；`docs/` 下的设计文档仍是 read-only reference |
| `.forge/context/*.md`（自宿主） | `.forge/context/onboard.md`, `conventions.md`, `architecture.md`, `testing.md`, `constraints.md` | **runtime impact** — 本仓库是自宿主 forge，本 feature 实现完成后 `--regenerate` 会按新 schema 重写这些文件；旧内容通过 preserve block 保留 |

### Call / Dependency Chain（概念级）

```
user ──/forge:onboard──▶ SKILL.md Stage 1 (kind detect)
                              │
                              ▼
                         Execution Plan  ←—— 本 feature 在 plan 里新增：
                              │                 · applicable-classification-categories[]
                              │                 · execution-content-policy（exclude/gated/allowed）
                              │                 · confidence-floor-per-artifact
                              ▼
                         Stage 2 loop ─── for each profile:
                              │              scan → extract → **CLASSIFY（NEW）** → render
                              ▼
                         onboard.md
                              │
                              ▼
                         Stage 3 scan ─── for each dim:
                              │              scan → extract → **CLASSIFY（NEW）** → route → render
                              ▼
                         architecture.md / conventions.md / testing.md / constraints.md
                              │
                              ▼
                         (pre-redesign detection ── if old section format detected)
                              │                 └─ HALT with regenerate notice
                              ▼
                         JOURNAL entry
```

---

## External Dependencies

| Dependency | Type | Relevance |
|------------|------|-----------|
| Claude Code CLI (runtime) | internal | SKILL.md 指令由 Claude Code 主 agent 执行；skill 内部无独立 runtime |
| Git | external | `git rev-parse --short HEAD` 用于 verified-commit；`git log` 用于 Runtime snapshot（现已使用，无变动） |
| Glob / Grep / Read / Bash / Write tools | internal | skill 的 `allowed-tools`（无变动） |
| Downstream skills | internal | `/forge:clarify` / `/forge:design` / `/forge:code` / `/forge:inspect` / `/forge:test` 消费 `.forge/context/*.md`；本 feature 改变 context 文件结构，下游 skill 读逻辑 **如果** 依赖特定章节名需要验证 |

---

## Assumptions Made

- **下游 skill 对 context 文件的读取方式是结构无关的** — 即 /forge:clarify / /forge:design 等读 `.forge/context/*.md` 时，靠自然语言理解而非对特定章节名 grep。基于此，修改 architecture.md / constraints.md 的章节结构不应破坏下游 skill 的契约。**请确认**（若不成立，design 阶段需扩大 scope 覆盖下游 skill 适配）。
- **Preserve blocks 现存数量少 / 位置集中于本仓库自宿主的 `.forge/context/`** — 基于此，`--regenerate` 路径下的 preserve block re-anchor 压力可控。**请确认**（若不成立，design 阶段需要更详细地规划 preserve block 的跨 schema 迁移）。
- **`deployment.md` profile 保留但 output 收窄是可接受的** — 不直接删除，避免丢失 "这个项目是一个可部署的服务" 这类**架构事实**。**请确认**（若倾向于直接删除，design 阶段可简化 profile 清单）。

---

## Questions & Answers

| # | Question | Answer | Source |
|---|----------|--------|--------|
| 1 | [WHAT] 本 feature 覆盖全部 5 个优先级，还是 MVP 只做 1–3，priorities 4–5（Change Navigation Map + deterministic extraction）延到后续 feature？ | **B** — MVP 只做 1–3；priorities 4–5 延到后续 feature（建议 slug `onboard-change-navigation`） | User |
| 2 | [WHAT] Change Navigation Map 对所有 kind 都必需，还是只对 web-backend / monorepo 必需，plugin / web-frontend 可选或 stub？ | **B** — 只对 web-backend / monorepo 必需；plugin / web-frontend 可选或 stub | User |
| 3 | [WHAT] `local-dev` profile 是直接移除，还是保留但加 policy gate（仅在高置信 + 非执行型时输出）？ | **A** — 直接从所有 Stage 2 kind manifest 移除；onboard.md 不再出现 Local Development 段 | User |
| 4 | [WHAT] 旧 `.forge/context/` 能否通过普通 incremental mode 升级，还是首次 post-redesign 运行必须用 `--regenerate`？ | **B** — 必须 `--regenerate`；Stage 3 需检测到旧格式 section 时显式提示 | User |
| 5 | [WHAT] `[inferred]` 置信度的 claim 能否出现在 `constraints.md`？ | **A** — 仅允许出现在 "Current Business Caveats" 段，必须带显式 `[inferred]` tag + 软化措辞（"appears to" / "likely"）；禁止进入 Hard Constraints / Process Gates | User |

**说明**：Q2 的答案（Change Nav Map 仅 web-backend / monorepo 必需）是为后续 feature `onboard-change-navigation` 记录的前置决定，**不适用于本 MVP**，仅保留以保证追溯性。

---

## Open Questions

*(无。Q&A 已覆盖全部 [WHAT] 类别阻塞项。)*

| # | Question | Impact if unresolved |
|---|----------|----------------------|
| — | — | — |

---

## Success Criteria

本 feature 成功的可验证条件（与 brief § "Success Criteria" 的条目对齐；仅覆盖 MVP 优先级 1–3 的成功项）：

- **SC-1** — 再生成的 `onboard.md` **不包含**以下任何形式的执行层内容：shell code block 含 `docker`、`npm install`、`pnpm install`、`pip install`、`make <target>` 等启动命令；`.env` 复制指令；部署命令；环境特定 URL / registry 地址 / secret 路径。验证：对一个已知目标项目跑 `--regenerate`，然后 grep `onboard.md` 不命中上述模式。_（对应 brief SC-1）_

- **SC-2** — 再生成的 `architecture.md` 中，`## Architecture Layers`（或对应 kind 的同义 architecture section）下至少有三个必需的 h3 子段：`### Observed Structure` / `### Enforced Rules` / `### Recommended Direction`。`Enforced Rules` 段只包含标注 `[high]` 且证据来源为编译 / 测试 / static check / framework 强制 的 claim。验证：对 `### Enforced Rules` 章节 grep 所有 bullet，每条都能在 `architecture.md` 或 skill 注释中追溯到至少一个强制性证据引用。_（对应 brief SC-2）_

- **SC-3** — 再生成的 `constraints.md` 至少有三个顶层 section：`Hard Constraints` / `Process / Quality Gates` / `Current Business Caveats`。Process-rule 类 claim 不出现在 `Hard Constraints`；current-caveat 不出现在 `Hard Constraints`。验证：对每个 section body 按分类规则抽样 100% bullet，核对归类。_（对应 brief SC-3）_

- **SC-4** — 再生成的 `conventions.md` 存在 `Delivery Conventions` 段，且覆盖：commit message 结构、task-to-commit 粒度、完成前 testing 期望、`.forge` artifact 更新期望。**不产生** 独立的 `delivery.md` 文件。验证：对 `conventions.md` grep `## Delivery Conventions` 命中；`.forge/context/delivery.md` 文件不存在。_（对应 brief SC-4）_

- **SC-5** — Claim classification 驱动 artifact 落点（不仅仅是 confidence tag 选择）。可观察的后果是：`enforced-rule` 只出现在 `architecture.md § Enforced Rules` 或 `constraints.md § Hard Constraints`；`recommended-pattern` 只出现在 `architecture.md § Recommended Direction` 或 `conventions.md`；`process-rule` 只出现在 `conventions.md § Delivery Conventions` 或 `constraints.md § Process / Quality Gates`；`current-caveat` 只出现在 `constraints.md § Current Business Caveats` 或可选地 echo 到 `onboard.md § Known Ambiguities`；`inference` 只出现在 `onboard.md` 段落 或 `constraints.md § Current Business Caveats`（带软化措辞）。验证：对生成的 4 个 context 文件 + onboard.md 采样 100% claim，标注分类，核对落点映射。_（对应 brief SC-5 + SC-6）_

- **SC-6** — `[inferred]` confidence 的 claim 绝不支持 `MUST / NEVER / ONLY / ENFORCED` 这类强硬措辞的规则。验证：对所有产物 grep `[inferred]`，逐条检查其所在 bullet 是否包含禁用词，应 0 命中。_（对应 brief § Evidence Discipline "Hard evidence rules"）_

- **SC-7** — 当 `.forge/context/` 中存在旧格式 section（markers 指向本 feature 后已移除 / 已重构的 profile，或 section body 结构不符合新 Output Template）时，首次运行必须 halt 并显示 `[forge:onboard] Pre-redesign artifacts detected — please re-run with --regenerate` 类似消息。普通 incremental mode 下不做破坏性 rewrite。验证：构造一个带旧格式 section 的 fixture `.forge/context/`，跑 `/forge:onboard`（无 flag）应 halt；跑 `/forge:onboard --regenerate` 应正常产出新格式。_（对应 Q&A #4）_

- **SC-8** — `local-dev` profile 不出现在任何 Stage 2 kind manifest 的 `profiles[]` 中。验证：grep `profiles/kinds/*.md` 不命中 `local-dev`。生成的 `onboard.md` 不含 `## Local Development` section（无论 kind）。_（对应 Q&A #3）_

- **SC-9** — `testing.md` 中的每条 rule claim 的 confidence tag 与其 evidence sample size 一致：单文件来源的 rule 最高 `[low]`；需 ≥3 份一致样本才允许 `[high]`。验证：对 testing.md 采样 bullet，回溯 dimension 的 scan pattern 实际 hit 数；tag 不一致即违规。_（对应 brief SC-5 — testing.md 不过度泛化）_

---

## Gaps (What Doesn't Exist Yet)

- **G-1** — Stage 2 / Stage 3 均缺少 claim classification step。profile 的 Extraction Rules 产出 fact 后直接喂给 Section Template；dimension 的 scan evidence 合并 synthesize 后也直接进入 Output Template。缺少"每条 claim 在 render 前分到六类之一"的中间步骤，以及"分类→artifact/section 路由"的规则。_（支撑 SC-5）_

- **G-2** — `local-dev.md` profile 当前仍被 4 个 kind manifest（`plugin` / `web-backend` / `web-frontend` / `monorepo`）通过 `profiles[]` 引用；profile 文件本身产出 `docker compose` 等执行命令。需要从所有 kind manifest 中移除引用，并决定 profile 文件本身是删除还是保留为 orphan。_（支撑 SC-1 / SC-8）_

- **G-3** — `architecture-layers.md` dimension 的 Output Template 只有一个合并输出块（`Model / Layers / Import rules / What to avoid`），没有 `Observed Structure / Enforced Rules / Recommended Direction` 三段切分。现有 "What to avoid" 段内容绝大多数是 recommended-pattern（推断自目录布局），当前被作为 architecture.md 的权威规则输出。_（支撑 SC-2）_

- **G-4** — `hard-constraints.md` + `anti-patterns.md` dimension 产出合并进 `constraints.md` 时无三段切分（Hard / Process / Current Caveats）。process-rule 类 claim（如 "每个 task 完成后单独提交"）与 hard constraint（如 "不读项目源码以外的文件"）被写入同一个 bullet 列表。_（支撑 SC-3）_

- **G-5** — `conventions.md` 当前无 `Delivery Conventions` 段。commit-format / artifact-writing / markdown-conventions 是三个独立 dimension，各自产出独立 section；没有 dimension 汇总"完成前测试"、"task-commit 粒度"、".forge artifact update expectation" 等 delivery 层面的期望。_（支撑 SC-4）_

- **G-6** — 无 per-artifact confidence floor。R7 禁造假，但不禁止 `[inferred]` 进 `architecture.md § Enforced Rules` 或 `constraints.md § Hard Constraints`。需要在 SKILL.md 加入显式映射：`fact → any`, `inference → onboard.md / constraints.md § Current Caveats only`, `enforced-rule → [high] required`, etc.。_（支撑 SC-5 / SC-6 / SC-9）_

- **G-7** — 无 pre-redesign 格式检测。Stage 3.3 smart-merge（R14）目前无条件执行；没有 "发现旧 section 指向被移除的 profile / 结构不符合新 template → halt 并提示 regenerate" 的分支。_（支撑 SC-7）_

- **G-8** — Execution-layer content exclusion policy 无显式定义。Stage 2 `deployment.md` profile 同样产出部署命令内容（未被此次 Q&A 专门裁决，但与 local-dev 同属执行层）。需要在 SKILL.md 加入显式 Iron Rule 或 policy 条款，把"shell 启动命令 / Docker / env-copy / deploy-cmd / secret path"等内容列为 excluded，并应用于所有 profile。_（支撑 SC-1）_

- **G-9** — `testing-strategy.md` dimension 无 sample-size→confidence-tag 约束。一条推断自单文件的 rule 可以被标 `[high]`。需要在 dimension 的 extraction rule 或 SKILL.md 层面加入 sample-size gate。_（支撑 SC-9）_

---

## Design Inputs (auto-routed)

见 `.forge/features/onboard-evidence-first/design-inputs.md`。7 条 [HOW] 项已路由到该文件：

- DI-1 — Evidence item 内部 schema
- DI-2 — Claim classification 在长 prompt 下的稳定性机制
- DI-3 — 需要拆 / 重写 / 删除的 profile & dimension 清单
- DI-4 — deterministic extraction helper（本 MVP 不覆盖，记录在 design-inputs 供 follow-up feature 使用）
- DI-5 — Change Navigation Map 生成算法（同上，follow-up feature）
- DI-6 — `architecture.md` 三段 / `constraints.md` 三段 的 Output Template 设计
- DI-7 — incremental mode 与 claim-reclassification 的交互

---

## Self-review Log

**Iteration 1 (initial draft)** — 5 checks run:

| Check | Result | Detail |
|-------|--------|--------|
| 1. scope-creep | ✅ pass | Resolved Questions 均为 [WHAT]；无 [HOW] 污染 |
| 2. contradiction | ✅ pass | Gaps 对现状的描述与 `.forge/context/onboard.md` 记录的 module map / Stage 结构一致 |
| 3. unresolved-blocking | ✅ pass | 无 Open Questions |
| 4. success-criteria-too-vague | ⚠️ minor | SC-5 原措辞 "classified internally before rendering" 是内部状态，不直接可验；已改写为 "驱动 artifact 落点 + 可观察的落点规则"，可通过 100% bullet 采样核对。已 inline 修正，不触发 revise pass |
| 5. gap-success-mismatch | ✅ pass | SC-1↔G-2,G-8；SC-2↔G-3；SC-3↔G-4；SC-4↔G-5；SC-5↔G-1,G-6；SC-6↔G-6；SC-7↔G-7；SC-8↔G-2；SC-9↔G-9。每条 SC 至少映射一条 Gap，每条 Gap 至少支撑一条 SC |

**Final verdict**: `pass`（0 major / 1 minor fixed inline）。

---

## Next Step

```
/forge:design onboard-evidence-first
```

Design skill 将消费本 clarify.md + `design-inputs.md`，并在 design.md / plan.md 中解决 7 条 DI 项，产出 4-stage design 流程（包括 Scenario Walkthrough 和 Wire Protocol Literalization 对 claim-classification pipeline 的字面描述）。
