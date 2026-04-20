# Forge Development Journal

> 操作日志，追加写入，不修改历史。  
> 任何人打开此文件，可以看到项目从零到完整的演进历史。
> `/forge:forge` 在 Runtime snapshot 中读取末尾 30 行作为新会话上下文。

---

## 2026-04-14

### 项目启动
- 创建仓库，首次提交 `docs/forge-plugin-design.md`（原始愿景）
- 创建 `CLAUDE.md`（项目上下文入口）

### 设计文档完成
- 创建 `docs/detailed-design.md`（各 skill 完整技术规范、SKILL.md 格式、plugin.json 格式）
- 创建 `docs/artifact-structure.md`（产物规范：命名、位置、时间线索引）
- 创建 `.forge/JOURNAL.md`（本文件，时间线正式启动）
- 建立目录骨架：`.forge/`、`docs/decisions/`、`docs/milestones/`、`tests/scenarios/`

**当前状态：** 设计阶段完成，进入实现阶段。  
**下一步：** 运行 `/forge:onboard` 生成项目地图，然后 `/forge:calibrate` 建立 SKILL.md 写作规范。

### 设计调整（基于官方文档研究）
- 更新 `docs/detailed-design.md`：SKILL.md 改为 YAML frontmatter 格式；新增 agents/ 目录和三个核心 agent 规范；plugin.json 简化为纯元数据
- 确认插件可包含：skills、agents、hooks、MCP servers（v1 只用 skills + agents）
- 确认官方 `feature-dev` 插件与 Forge 设计方向相似，作为参考实现

### /forge:design plugin-bootstrap（模拟）
- 产出：`.forge/design-plugin-bootstrap.md`
- 关键决策：首个完整 skill 选 `plan`；plugin.json 最小化；占位文件需含合法 frontmatter

### /forge:plan plugin-bootstrap（模拟）
- 产出：`.forge/plan-plugin-bootstrap.md`
- Tasks：T001（目录骨架）→ T002+T003+T004（并行）→ T005（plan skill 完整实现）
- 下一步：开始 `/forge:code T001`

---

## 2026-04-19 — /forge:onboard
- 产出：.forge/context/onboard.md
- 摘要：9 个 skill、3 个 agent、4 个脚本；Claude Code Plugin 无外部依赖
- 下一步：/forge:calibrate

## 2026-04-19 — /forge:calibrate
- 产出：conventions.md, testing.md, architecture.md, constraints.md
- 裁决：1 个矛盾（交互消息大小写），关键决策：`[forge:{skill}]` 全小写
- 下一步：持续优化 skill 实现

## 2026-04-20 — 优化：JOURNAL.md + Assumptions Made（非 skill 执行，直接代码变更）
- 变更：forge:forge Runtime snapshot 加 JOURNAL 读取；所有 9 个 skill 加 JOURNAL 追加步骤；
  forge:code 加 assumption tracking IRON RULE、Step 3 说明、summary Assumptions Made 章节；
  forge:inspect 扩展 prerequisites 和 Step 2 以接收 assumptions；
  conventions.md 更新产物路径表和 Decision #6；初始化 JOURNAL.md 格式头
- 下一步：评估中优先级改进项（conventions-quickref、design Rejected Approaches 等）

## 2026-04-20 — /forge:onboard (--regenerate, self-bootstrap)
- 产出：.forge/context/onboard.md (575 行, 107 confidence tags, 10 section markers)
- 摘要：验证新 skill（v0.3.0）在 forge 自身项目上的行为；全 9 section 均产出
- 自举发现：
  1. 模板中 "Business Domain vs Technical Layer" 的二分法不适合 meta-project；Section 3 需要明确支持 plugin/library/tool 类项目
  2. Section 4 (Core Domain Objects) 在无数据库项目上需用 "artifact types" 等类比概念填充
  3. Section 5 (Entry Points) 模板预设 HTTP/events/jobs；slash-command 型项目需新子类别
  4. Section 6 (Integration Topology) 对 meta-project 大部分 N/A，模板需说明如何优雅处理
- 置信度警示：无 [conflict]；2 处 [inferred]（空 docs/decisions/、空 docs/milestones/）
- 下一步：据自举发现做 skill 小幅修补（新增 project-kind 检测 + 各 section 的 N/A 指引）
