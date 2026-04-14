# Forge Development Journal

> 操作日志，追加写入，不修改历史。  
> 任何人打开此文件，可以看到项目从零到完整的演进历史。

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
