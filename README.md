<div align="center">
  <img src="assets/logo.png" alt="Forge" style="max-width: 100%" />
  <p>AI-driven development workflow for existing codebases.</p>

  <p>
    <a href="https://github.com/lotusp/forge/releases"><img src="https://img.shields.io/badge/version-0.3.0-blue" alt="version"/></a>
    <a href="https://github.com/lotusp/forge/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="license"/></a>
    <img src="https://img.shields.io/badge/Claude%20Code-plugin-orange" alt="Claude Code plugin"/>
  </p>

  <p>
    <a href="#安装">安装</a> ·
    <a href="#使用指南">使用指南</a> ·
    <a href="docs/detailed-design.md">文档</a>
  </p>
</div>

---

Forge 将软件开发的完整流程拆解为一组相互衔接的 Claude Code skill。每个 skill 产出结构化的文档产物，存储在 `.forge/` 目录，下一个 skill 直接读取，形成可跨会话持续的上下文链。

**核心理念：AI 是开发者，人类提供意图和判断。**

---

## 为什么需要 Forge？

在真实项目中，AI 辅助开发最常见的失败模式：

| 问题 | 表现 | Forge 的解法 |
|------|------|------------|
| **上下文丢失** | 每次会话重新解释项目背景 | `.forge/` 产物跨会话持久保存 |
| **规范漂移** | AI 引入项目中不存在的模式 | `calibrate` 生成权威约定，所有 skill 强制遵守 |
| **范围失控** | 顺手改了不相关的东西引入回归 | `code` skill 严格执行 Scope Creep 协议 |
| **假设替代思考** | AI 猜测业务规则而不提问 | 任何 skill 遇到不确定项必须暂停并提问 |

---

## Skill 流程

```
onboard → calibrate → clarify → design → tasking → code → inspect → test
```

或直接使用编排器，自动检测当前状态并路由：

```
/forge:forge
```

| Skill | 调用方式 | 作用 | 输出 |
|-------|---------|------|------|
| `forge` | `/forge:forge [意图或 slug]` | 自动检测项目状态，路由到正确的下一步 | — |
| `onboard` | `/forge:onboard` | 扫描项目，生成人可读的项目地图 | `.forge/context/onboard.md` |
| `calibrate` | `/forge:calibrate` | 提取隐式约定，裁决代码风格矛盾 | `.forge/context/`（4 个文件） |
| `clarify` | `/forge:clarify <需求>` | 追踪代码路径，澄清需求，提取未知项 | `.forge/features/{slug}/clarify.md` |
| `design` | `/forge:design <feature>` | 并发探索技术方向，产出技术设计方案 | `.forge/features/{slug}/design.md` |
| `tasking` | `/forge:tasking <feature>` | 将设计拆解为带验收标准的有序任务 | `.forge/features/{slug}/plan.md` |
| `code` | `/forge:code T001` | 严格按任务范围实现，不越界、不猜测 | 源文件 + `.forge/features/{slug}/tasks/T001-summary.md` |
| `inspect` | `/forge:inspect <feature 或 file-path>` | 并发逐文件评审，置信度 ≥80 才上报 | `.forge/features/{slug}/inspect.md` |
| `test` | `/forge:test <feature>` | 生成符合项目测试规范的测试代码 | 测试文件 + `.forge/features/{slug}/test.md` |

---

## 安装

### 从 GitHub 安装

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

重启 Claude Code，执行 `/skills` 验证安装，应看到 9 个 `forge:*` skill 处于 **on** 状态。

### 本地开发模式

```bash
git clone https://github.com/lotusp/forge.git
claude --plugin-dir ./forge
```

修改 skill 文件后执行 `/reload-plugins` 热更新，无需重启。

---

## 使用指南

### 使用编排器（推荐）

直接调用 `/forge:forge`，它会自动检测项目状态并告诉你下一步：

```
/forge:forge                         # 自动检测并路由
/forge:forge "用户注册时需要验证手机号"  # 从需求描述开始
/forge:forge phone-verification      # 继续指定功能
/forge:forge T005                    # 直接跳到某个任务
```

### 逐步手动调用

```
/forge:onboard
/forge:calibrate
```

`calibrate` 会交互式地解决代码库中的约定矛盾，产出 `.forge/context/` 下的 4 个约定文件，这是后续所有 skill 的约束基准。

```
/forge:clarify "用户注册时需要验证手机号"
/forge:design phone-verification
/forge:tasking phone-verification
/forge:code T001
/forge:code T002
/forge:inspect phone-verification
/forge:test phone-verification
```

### 跨会话继续工作

`.forge/` 目录的产物持久保存，新会话中可从任意步骤继续：

```
/forge:code T005              # 继续实现下一个任务
/forge:inspect src/auth/      # 对指定路径单独评审
/forge:forge                  # 让编排器自动判断从哪里继续
```

---

## `.forge/` 产物目录

建议将 `.forge/` 提交到版本控制，作为项目决策历史的一部分。

```
.forge/
├── context/                   # 项目级上下文（跨功能共享）
│   ├── onboard.md             # 项目地图
│   ├── conventions.md         # 权威约定规范
│   ├── testing.md             # 测试规范
│   ├── architecture.md        # 架构约定
│   └── constraints.md         # 硬性规则和反模式
│
└── features/                  # 每个功能一个子目录
    └── {feature-slug}/
        ├── clarify.md         # 需求分析
        ├── design.md          # 技术设计
        ├── plan.md            # 任务列表
        ├── inspect.md         # 评审结果
        ├── test.md            # 测试计划
        └── tasks/
            └── T001-summary.md  # 实现摘要（每个任务一份）
```

---

## 内置 Agent

| Agent | 颜色 | 由谁调用 | 职责 |
|-------|------|---------|------|
| `forge-explorer` | 🟡 | `clarify` | 追踪代码路径和数据流，每个入口点并发一个实例 |
| `forge-architect` | 🟢 | `design` | 并发探索不同技术方向，产出设计蓝图 |
| `forge-reviewer` | 🔴 | `inspect` | 逐文件对照约定评审，置信度 ≥80 才上报发现 |

---

## 更新

```bash
# Claude Code 内执行
/plugin update forge

# 本地开发版
git pull && # 在 Claude Code 内执行 /reload-plugins
```

---

## 文档

| 文档 | 说明 |
|------|------|
| [`docs/forge-plugin-design.md`](docs/forge-plugin-design.md) | 原始设计愿景 |
| [`docs/detailed-design.md`](docs/detailed-design.md) | 完整技术规范（skill I/O 合约、agent 格式） |
| [`docs/artifact-structure.md`](docs/artifact-structure.md) | 产物命名规范和开发时间线索引 |
