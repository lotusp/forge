# Code Summary: T039

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/context/kinds/plugin.md` | updated | 将 `dimensions/delivery-conventions` 加入 conventions / constraints 分组 |
| `plugins/forge/skills/onboard/profiles/context/kinds/web-backend.md` | updated | 同上 |
| `plugins/forge/skills/onboard/profiles/context/kinds/web-frontend.md` | updated | 同上 |
| `plugins/forge/skills/onboard/profiles/context/kinds/monorepo.md` | updated | 同上 |

## Acceptance Criteria Status

- [x] 4 个 context kind manifest 都注册了 `dimensions/delivery-conventions`
- [x] conventions 与 constraints 两侧的路由都显式存在
- [x] 未引入任何新的 frontmatter routing 语义

## Assumptions Made

- 无
