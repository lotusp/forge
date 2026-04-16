# Forge

> A Claude Code plugin for AI-driven development on existing codebases.

Forge 是一个 Claude Code 插件，将软件开发的完整流程——从理解需求到交付经过评审的代码——拆解为一组相互衔接的 skill。每个 skill 产出结构化的文档产物，下一个 skill 直接读取，形成可跨会话持续的上下文链。

**核心理念：AI 是开发者，人类提供意图和判断。**

---

## 设计意图

### 为什么需要 Forge？

在真实项目中，AI 辅助开发最常见的失败模式是：

- **上下文丢失**：每次会话重新解释项目背景，AI 做出与项目风格不符的决策
- **规范漂移**：AI 引入项目中不存在的模式，代码风格逐渐碎片化
- **范围失控**：实现一个功能时顺手改了不相关的东西，引入回归问题
- **假设替代思考**：AI 遇到不确定的业务规则时猜测，而不是提问

Forge 通过**产物驱动的工作流**解决这些问题：每个 skill 的输出都是一份文档，存储在 `.forge/` 目录下，作为后续 skill 的输入。约定、设计决策、实现摘要都有明确的归处，不依赖单次会话的上下文窗口。

### 适用场景

- 在已有代码库上开发新功能（而非从零开始）
- 需要保持与项目现有代码风格一致
- 团队希望 AI 的每一步决策都可追溯、可复查
- 需要跨多个会话持续推进同一个功能

---

## Skill 流程

```
onboard → calibrate → clarify → design → plan → code → review → test
```

每个 skill 都可以独立运行（当上下文已存在时），也可以按顺序从头执行。

| Skill | 调用方式 | 作用 | 输出产物 |
|-------|---------|------|---------|
| `onboard` | `/forge:onboard` | 扫描项目，生成人可读的项目地图 | `.forge/onboard.md` |
| `calibrate` | `/forge:calibrate` | 提取项目隐式约定，裁决矛盾，生成权威规范 | `.forge/conventions.md` |
| `clarify` | `/forge:clarify <需求>` | 追踪代码路径，澄清需求，提取未知项 | `.forge/clarify-{feature}.md` |
| `design` | `/forge:design <feature>` | 基于约定和需求分析，设计具体技术方案 | `.forge/design-{feature}.md` |
| `plan` | `/forge:plan <feature>` | 将设计拆解为带验收标准的有序任务列表 | `.forge/plan-{feature}.md` |
| `code` | `/forge:code <T001>` | 严格按任务范围实现，不越界、不猜测 | 源文件 + `.forge/code-{T}.md` |
| `review` | `/forge:review <feature>` | 按约定文档评审实现，给出分级发现 | `.forge/review-{feature}.md` |
| `test` | `/forge:test <feature>` | 生成符合项目测试规范的测试计划和测试代码 | 测试文件 + `.forge/test-{feature}.md` |

---

## 安装

### 从 GitHub 安装（推荐）

在 `~/.claude/settings.json` 中添加：

```json
{
  "extraKnownMarketplaces": {
    "forge": {
      "source": {
        "source": "url",
        "url": "https://github.com/lotusp/forge.git"
      }
    }
  },
  "enabledPlugins": {
    "forge@forge": true
  }
}
```

重启 Claude Code，插件自动从 GitHub 拉取并激活。

### 本地开发模式

克隆仓库后，在启动 Claude Code 时加载本地版本：

```bash
git clone https://github.com/lotusp/forge.git
claude --plugin-dir ./forge
```

修改 skill 文件后，在 Claude Code 内执行 `/reload-plugins` 即可热更新。

### 验证安装

输入 `/forge:` 后按 Tab，应出现 8 个 skill 的补全提示。

---

## 使用指南

### 第一次使用新项目

```
# 1. 在项目根目录生成项目地图
/forge:onboard

# 2. 提取项目约定（需要 onboard.md 存在）
/forge:calibrate
```

`calibrate` 会交互式地帮你裁决代码库中的约定矛盾，产出 `.forge/conventions.md`。这是后续所有 skill 的基础。

### 开发一个新功能

```
# 3. 分析需求，追踪相关代码路径
/forge:clarify "用户注册时需要验证手机号"

# 4. 生成技术设计方案
/forge:design phone-verification

# 5. 拆解为可执行任务
/forge:plan phone-verification

# 6. 逐个实现任务
/forge:code T001
/forge:code T002
...

# 7. 评审实现
/forge:review phone-verification

# 8. 生成测试
/forge:test phone-verification
```

### 在已有上下文下继续工作

`.forge/` 目录中的产物跨会话持久保存。新会话中可以直接从任意步骤继续：

```
# 直接继续实现下一个任务
/forge:code T005

# 对已实现的文件单独评审
/forge:review src/services/phone-verification.ts
```

---

## `.forge/` 产物目录

所有产物存储在**目标项目**的 `.forge/` 目录下（不是 Forge 插件仓库本身）。建议将此目录提交到版本控制，作为项目开发历史的一部分。

```
.forge/
├── onboard.md                    # 项目地图
├── conventions.md                # 权威约定规范
├── clarify-{feature}.md          # 需求分析
├── design-{feature}.md           # 技术设计
├── plan-{feature}.md             # 任务列表
├── code-{T001}-summary.md        # 实现摘要
├── review-{feature}.md           # 评审结果
└── test-{feature}.md             # 测试计划
```

---

## 内置 Agent

Forge 内置三个专用子 agent，在 skill 执行时自动委派：

| Agent | 颜色 | 使用方 | 职责 |
|-------|------|--------|------|
| `forge-explorer` | 🟡 黄 | `clarify` | 追踪代码路径和数据流 |
| `forge-architect` | 🟢 绿 | `design` | 并发探索技术方向，产出设计蓝图 |
| `forge-reviewer` | 🔴 红 | `review` | 逐文件对照约定评审，置信度 ≥80 才上报 |

---

## 更新插件

```bash
# GitHub 安装版：在 Claude Code 内执行
/plugin update forge

# 本地开发版：拉取最新代码后热更新
git pull
# 然后在 Claude Code 内执行 /reload-plugins
```

---

## 文档

| 文档 | 说明 |
|------|------|
| [`docs/forge-plugin-design.md`](docs/forge-plugin-design.md) | 原始设计愿景 |
| [`docs/detailed-design.md`](docs/detailed-design.md) | 完整技术规范（skill I/O 合约、agent 格式） |
| [`docs/artifact-structure.md`](docs/artifact-structure.md) | 产物命名规范和开发时间线索引 |
