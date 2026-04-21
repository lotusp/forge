# Design Inputs: onboard-kind-profiles

> 生成时间：2026-04-20
> 生成方式：从 clarify 会话中剥离的**实现级预置边界**
> 文件路径：.forge/features/onboard-kind-profiles/design-inputs.md
> 同时参考：clarify.md（需求级决策）

---

## 本文件是什么 / 不是什么

**是什么：**
用户在 clarify 会话里基于 3 个设计目标（DG1/DG2/DG3）**提前固化的实现级边界**。
这些不是需求（需求在 `clarify.md`），也不是完整的技术设计（技术设计在 `design.md`）——
是**约束 design 阶段探索空间的预置门栏**。

**不是什么：**
- 不是需求：不影响"要造什么产品"
- 不是完整设计：只约束空间，不定义具体类结构/算法/完整流程
- 不是硬约束规则：若 design 阶段发现边界与 DG1/DG2/DG3 冲突，可重新协商

**为什么单独一个文件：**
`clarify.md` 的 IRON RULES 要求 Q&A 限于需求级议题（何种能力、范围边界、产品
策略）。以下 5 项在 clarify 会话中被讨论但实质是实现决策，单独放这里避免污染 clarify。

---

## DI-1：Profile 文件存放在 skill-local `reference/profiles/`

**服务目标：** DG1（按需加载）
**已决定：** skill-local，路径 `plugins/forge/skills/onboard/reference/profiles/*.md`

**不使用：**
- plugin-level 共享位置（`plugins/forge/profiles/*.md`）— YAGNI，profile 概念尚未跨 skill 验证
- 分层位置（`profiles/shared/` + `reference/profiles/`）— 过度工程化

**Design 阶段的自由度：**
- Profile 文件命名规则（kebab-case / snake_case / 具体命名模式）
- 子目录进一步分组（如 `profiles/core/`、`profiles/entry-points/`）
- 索引文件是否存在（如 `profiles/INDEX.md`）

---

## DI-2：IRON RULES 采用 core + per-kind overlay 结构

**服务目标：** DG2（就近重述规则），DG3（kind-specific 规则封装）
**已决定：** Core 规则留在 SKILL.md；每个 kind 文件允许声明 `iron_rules_overlay`。Skill 运行时先加载 core，检测 kind 后追加 overlay。

**不使用：**
- 所有规则在 SKILL.md 打 `applies-to:` 标签（膨胀 SKILL.md，违反 DG1）
- 去掉 per-kind 规则，全部通用化（失去了"HTTP 方法必从注解读"这种 kind-有意义的约束）

**Design 阶段的自由度：**
- `iron_rules_overlay` 的具体数据结构（frontmatter 子节 / 独立文件正文节）
- 哪些 core 规则可被 overlay 覆盖 vs 哪些是不可变
- overlay 加载失败的降级策略

---

## DI-3：Kind detection 信号存放在各 kind 文件的 frontmatter

**服务目标：** DG1（加载成本）
**已决定：** Detection 阶段只读各 kind 文件的 **frontmatter**（预计 < 30 行/kind），不读 body。3 个 MVP kind 的 detection 总开销 < 100 行。

**不使用：**
- 信号硬编码在 SKILL.md Step 1（SKILL.md 膨胀）
- 独立 `reference/kind-detection.md`（一次读整个文件；加 kind 时需维护两处）

**Design 阶段的自由度：**
- Frontmatter 内的信号结构（weight 字段形态、模糊匹配 vs 精确匹配）
- 打分算法（加权和 / 条件树 / 最高分快速短路）
- "Unknown kind" 的 fallback 行为（细节见 clarify Open Questions）

---

## DI-4：Profile 加载采用 "read-do-discard" 节奏

**服务目标：** DG1（token 最优），DG2（注意力按 step 切换）
**已决定：** SKILL.md 的 Process 每 step 显式 `Read reference/profiles/{name}.md` → 执行该 profile 的 scan + render 逻辑 → section 写入磁盘后**不在后续 step 主动保留 profile 内容**。

**"read-do-discard" 术语定义：**
- **read**：当前 Process step 显式调用 Read 工具加载 profile 文件
- **do**：按 profile 指引完成扫描、生成、写入一个 section（含 section marker）
- **discard**：后续 step 不显式重新引用；依赖 Claude 的自然注意力衰减 + 新 profile 的就近 IRON RULES 重述，把上下文焦点切到下一 profile

**不使用：**
- 全量预加载（长上下文，违反 DG2）
- 隐式加载（依赖 Claude 从 SKILL.md 推断该读什么 — 容易漏读或错读）

**Design 阶段的自由度：**
- Process step 模板的精确 prompt 文字
- 共享扫描结果的缓存机制（多 profile 用同一 grep 时是否去重）
- 失败恢复时如何定位到具体 profile（可能需要 checkpoint 文件）

---

## DI-5：Profile 文件丰度为 Lean + Golden-Path + Compressed Rules

**服务目标：** DG3（质量），DG2（规则就近），DG1（受控 token）
**已决定：** 每个 profile 文件约 80 行，必含 5 个组成部分：

1. **适用 kind 列表**（frontmatter）
2. **扫描规程**（grep/glob 指令块，可 cross-reference `scan-patterns.md`）
3. **Template 片段**（section body 模板，带 `{placeholders}`）
4. **N/A 兜底呈现说明**（扫描无结果时如何 emit 空 section）
5. **Golden-path 示例**（一个填好的 section 样本）
6. **相关 IRON RULES 的压缩提醒**（3-5 条摘要，非完整抄写）
7. 可选：依赖的其他 profile（纯文本链接）

**不使用：**
- Lean-only（约 50 行）— 无 golden-path，AI 生成质量波动
- Rich（约 150 行）— token 成本过高
- Split（主文件 lean + `profile-examples/{name}.md` 独立）— 分离读写，维护性差

**Design 阶段的自由度：**
- Markdown 结构的精确分节标题
- Golden-path 示例采用的虚构场景（**必须**遵循 `conventions.md § Content Hygiene` 的"通用示例调色板"——e-commerce order platform）
- "压缩 IRON RULES 提醒"的具体长度上限（2 行 / 3 行 / 5 行？）

---

## 交叉索引

| Design Input | 相关 Gap (clarify.md) | 相关 Open Question | 相关 Goal |
|--------------|----------------------|--------------------|-----------|
| DI-1 | Gap-02 (Profile 库) | — | DG1 |
| DI-2 | Gap-05 (IRON RULES core/overlay) | — | DG2, DG3 |
| DI-3 | Gap-01 (Kind detection 机制) | OQ-02（阈值数值） | DG1 |
| DI-4 | Gap-04 (Process 模板化) | OQ-01（`--thorough` 交互） | DG1, DG2 |
| DI-5 | Gap-02 (Profile 库) | OQ-04（cross-reference 语法） | DG3, DG2 |

---

## Design 阶段使用须知

Design 阶段 (`/forge:design onboard-kind-profiles`) 开始时：

1. **先读 clarify.md**（需求与范围）
2. **再读本文件**（实现边界与自由度）
3. **按需读 scan-patterns.md / incremental-mode.md**（现有实现细节）

Design 产出 `design.md` 时，对每个 DI 做一件事：
- 要么**接受**（按预置边界展开具体设计）
- 要么**质疑**（说明为什么与 DG 冲突，建议替代边界，回到用户协商）

不允许**隐式违反**预置边界（如把 profile 文件放到其他位置却不在 design.md 里说明）。
