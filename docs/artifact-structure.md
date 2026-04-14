# Forge 项目产物规范

> 本文档定义 Forge 插件开发过程中所有产物的存放位置、命名规则和用途。  
> 遵循此规范，可以从任意产物出发，沿时间线追溯完整开发历史。

---

## 一、总体目录结构

```
forge/
│
├── docs/                          # 人工撰写的项目文档（长期有效）
│   ├── forge-plugin-design.md     # 原始设计愿景（不修改，仅参考）
│   ├── detailed-design.md         # 完整技术设计规范（本项目）
│   ├── artifact-structure.md      # 本文档
│   ├── decisions/                 # 架构决策记录（ADR）
│   │   └── ADR-NNN-{slug}.md
│   └── milestones/                # 里程碑记录
│       └── M{NN}-{slug}.md
│
├── .forge/                        # 自托管上下文（Forge 开发 Forge 的产物）
│   ├── JOURNAL.md                 # 操作日志（追加写入，时间线索引）
│   ├── onboard.md
│   ├── conventions.md
│   └── {skill}-{feature-slug}.md  # 按 skill+feature 命名
│
├── skills/                        # 插件实现（最终交付物）
│   └── {skill-name}/
│       └── SKILL.md
│
├── tests/                         # 手动/自动化测试资源
│   └── scenarios/
│       └── {feature-slug}/
│           ├── setup.md           # 测试环境说明
│           └── cases.md           # 测试用例（来自 /forge:test 产物整合）
│
├── .claude-plugin/
│   └── plugin.json
└── CLAUDE.md
```

---

## 二、`.forge/` — 自托管上下文目录

这是 Forge 开发自身时产生的所有 skill 输出。遵循与目标项目完全相同的规范，以验证 Forge 流程的可用性。

### 2.1 固定文件（项目级，唯一）

| 文件名 | 产生方式 | 用途 |
|--------|----------|------|
| `JOURNAL.md` | 人工 + skill 辅助维护 | 时间线索引，记录每次 skill 调用 |
| `onboard.md` | `/forge:onboard` | Forge 项目本身的项目地图 |
| `conventions.md` | `/forge:calibrate` | SKILL.md 写作规范和文档格式标准 |

### 2.2 Feature 相关文件（按 feature-slug 聚合）

每个 skill 产出以 `{skill}-{feature-slug}.md` 命名：

```
.forge/
├── clarify-skill-onboard.md
├── design-skill-onboard.md
├── plan-skill-onboard.md
├── code-T001-summary.md
├── code-T002-summary.md
├── review-skill-onboard.md
├── test-skill-onboard.md
│
├── clarify-skill-calibrate.md
├── design-skill-calibrate.md
...
```

### 2.3 Feature Slug 规划（本项目）

| Feature Slug | 对应内容 |
|-------------|----------|
| `plugin-bootstrap` | plugin.json 和目录结构搭建 |
| `skill-onboard` | `/forge:onboard` skill 实现 |
| `skill-calibrate` | `/forge:calibrate` skill 实现 |
| `skill-clarify` | `/forge:clarify` skill 实现 |
| `skill-design` | `/forge:design` skill 实现 |
| `skill-plan` | `/forge:plan` skill 实现 |
| `skill-code` | `/forge:code` skill 实现 |
| `skill-review` | `/forge:review` skill 实现 |
| `skill-test` | `/forge:test` skill 实现 |

### 2.4 Task ID 规则

Task ID 在**整个项目范围内全局唯一**（不局限于单个 feature），格式为 `T{NNN}`，三位数字，从 `T001` 开始顺序递增。

> 这样设计的原因：`code-T003-summary.md` 不需要加 feature 前缀就能全局定位。

---

## 三、`docs/` — 人工撰写文档

### 3.1 固定文档

| 文件 | 创建时机 | 内容 |
|------|----------|------|
| `forge-plugin-design.md` | 项目初始 | 原始愿景，**只读参考** |
| `detailed-design.md` | 开发启动前 | 完整技术规范 |
| `artifact-structure.md` | 开发启动前 | 本文档 |

### 3.2 架构决策记录（ADR）

**路径：** `docs/decisions/ADR-{NNN}-{slug}.md`

**命名示例：**
```
ADR-001-skill-md-format.md        # SKILL.md 格式选型
ADR-002-artifact-naming.md        # 产物命名规范决策
ADR-003-task-id-global-scope.md   # Task ID 全局还是 feature 级
```

**编号规则：** 三位数字，从 001 开始顺序递增，不跳号，不复用。

**文件结构：**
```markdown
# ADR-{NNN}: {决策标题}

**日期：** YYYY-MM-DD  
**状态：** proposed / accepted / superseded by ADR-XXX / deprecated

## 背景
[为什么需要做这个决策]

## 决策
[最终选择了什么]

## 原因
[为什么这样选，对比了哪些方案]

## 后果
[这个决策带来的影响和约束]
```

### 3.3 里程碑记录

**路径：** `docs/milestones/M{NN}-{slug}.md`

**命名示例：**
```
M01-project-kickoff.md
M02-conventions-established.md
M03-onboard-skill-shipped.md
M04-all-core-skills-shipped.md
M05-self-hosted-dogfood-complete.md
```

**编号规则：** 两位数字，从 01 开始。

**文件结构：**
```markdown
# M{NN}: {里程碑名称}

**完成日期：** YYYY-MM-DD  
**关联 Tasks：** T001, T002, ...

## 达成内容
[这个里程碑包含了什么]

## 验证方式
[如何确认里程碑达成]

## 遗留问题
[发现但未解决的问题，记录到哪个后续 task]
```

---

## 四、`tests/` — 测试资源

测试资源分两类：
1. **自动化测试**（如有）：直接放在 `tests/` 下，按语言/框架约定组织
2. **场景化手动测试**：放在 `tests/scenarios/{feature-slug}/`

```
tests/
└── scenarios/
    ├── skill-onboard/
    │   ├── setup.md       # 准备一个 mock 目标项目的步骤
    │   └── cases.md       # 具体用例（来自 .forge/test-skill-onboard.md 整合）
    └── skill-calibrate/
        ├── setup.md
        └── cases.md
```

**测试报告：** 测试执行后，在 `tests/scenarios/{feature-slug}/` 下新增：
```
report-YYYY-MM-DD.md    # 当次测试结果，包含通过/失败状态和备注
```

---

## 五、JOURNAL.md — 时间线索引

**路径：** `.forge/JOURNAL.md`

这是整个项目从头到尾的操作日志，任何人打开这个文件，就能看到项目的完整演进历史。

**追加写入，不修改历史记录。**

**格式：**
```markdown
# Forge Development Journal

---

## 2026-04-14

### 09:30 — 项目启动
- 创建仓库，提交初始设计文档 `docs/forge-plugin-design.md`
- 创建 `docs/detailed-design.md`（技术规范）
- 创建 `docs/artifact-structure.md`（本规范）

### 10:15 — /forge:onboard
- 产出：`.forge/onboard.md`
- 备注：首次运行，建立基础上下文

### 11:00 — /forge:calibrate  
- 产出：`.forge/conventions.md`
- 裁决了 3 个约定矛盾（见 conventions.md > Open Questions）
- ADR-001 产出：SKILL.md 格式决策

### 14:00 — /forge:clarify skill-onboard
- 产出：`.forge/clarify-skill-onboard.md`
- 澄清了 4 个问题（onboard skill 的目录扫描深度、monorepo 处理方式等）

### 15:30 — /forge:design skill-onboard
- 产出：`.forge/design-skill-onboard.md`
- 关键决策：onboard 输出采用固定 section 结构而非自由格式

### 16:00 — /forge:plan skill-onboard
- 产出：`.forge/plan-skill-onboard.md`
- Tasks 分配：T001-T004

---

## 2026-04-15

### 10:00 — /forge:code T001
- 产出：`skills/onboard/SKILL.md` + `.forge/code-T001-summary.md`
...
```

---

## 六、完整产物时间线示意

以下展示一个 skill（`skill-onboard`）从需求到上线的完整产物链：

```
时间线 →

docs/forge-plugin-design.md          # [T0] 原始愿景
docs/detailed-design.md              # [T0] 技术规范（本文档前序）
.forge/onboard.md                    # [1] /forge:onboard 产出
.forge/conventions.md                # [2] /forge:calibrate 产出
docs/decisions/ADR-001-*.md          # [2] calibrate 过程中产生的决策
.forge/clarify-skill-onboard.md      # [3] /forge:clarify 产出
.forge/design-skill-onboard.md       # [4] /forge:design 产出
.forge/plan-skill-onboard.md         # [5] /forge:plan 产出（含 T001-T004）
.forge/code-T001-summary.md          # [6a] /forge:code T001 产出
skills/onboard/SKILL.md              # [6a] 实际交付文件
.forge/code-T002-summary.md          # [6b] /forge:code T002 产出
.forge/review-skill-onboard.md       # [7] /forge:review 产出
.forge/test-skill-onboard.md         # [8] /forge:test 产出
tests/scenarios/skill-onboard/       # [8] 测试场景（从 test 产物整合）
tests/scenarios/skill-onboard/report-YYYY-MM-DD.md  # [9] 测试执行结果
docs/milestones/M03-onboard-skill-shipped.md         # [10] 里程碑记录
```

---

## 七、快速查阅索引

| 我想了解… | 去看… |
|----------|-------|
| 项目是做什么的 | `docs/forge-plugin-design.md` |
| 技术实现细节 | `docs/detailed-design.md` |
| 项目发生了什么（时间线） | `.forge/JOURNAL.md` |
| 当前约定和规范 | `.forge/conventions.md` |
| 某 skill 的需求是什么 | `.forge/clarify-{skill}.md` |
| 某 skill 的设计方案 | `.forge/design-{skill}.md` |
| 当前开发任务清单 | `.forge/plan-{skill}.md` |
| 某次实现做了什么 | `.forge/code-{task-id}-summary.md` |
| 某个架构决策为什么这样做 | `docs/decisions/ADR-NNN-*.md` |
| 测试覆盖情况 | `.forge/test-{skill}.md` |
| 某次测试的结果 | `tests/scenarios/{skill}/report-*.md` |
