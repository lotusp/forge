# Code Summary: T006

> Feature: skill-design | 完成时间：2026-04-14

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `skills/design/SKILL.md` | modified | 替换占位内容为完整实现 |

## Key Implementation Decisions

**clarify 是可选前置条件：** 与 plan 不同，design 允许在没有 clarify 产物的
情况下继续，因为 Forge 自身的 bootstrap 就是从 design 开始的（空项目没有什么
可以 clarify 的）。缺失时提示用户选择：先运行 clarify，或直接提供上下文。

**conventions 也是可选的：** 新项目可能还没有运行 calibrate，不应因此阻塞
设计阶段。缺失时在输出文档头部明确标注"设计不受约定约束"。

**forge-architect 并发探索：** 对有实质性技术选择的 feature，明确要求并发
派出 2-3 个 architect agent 分别探索不同方向。对小型明确的 feature，允许
跳过多 agent 探索直接设计。这个判断留给 Claude 在运行时决策。

**Open Decisions 是硬阻塞：** 任何未解决的 Open Decision 必须在写入产物前
得到用户回答。这与 plan skill 的约定一致——plan 检查 design 的 Open Decisions
章节，若非空则拒绝继续。

**两级确认门：** Step 4（方案选择）和 Step 6（Open Decisions）各有一个
用户确认点，确保设计方向在投入细节之前得到认可。

## Acceptance Criteria Status

- [x] Frontmatter 包含所有必要字段
- [x] 处理 clarify 缺失的情况（提示 + 备选路径）
- [x] 处理 conventions 缺失的情况（标注并继续）
- [x] 描述 forge-architect agent 的使用方式
- [x] 方案对比需用户确认
- [x] Open Decisions 阻塞流程，写入产物前必须解决
- [x] 输出模板完整，与 plan skill 的读取期望一致
- [ ] 实际运行验证（待 review 后手动测试）
