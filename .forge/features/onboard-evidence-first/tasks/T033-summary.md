# Code Summary: T033

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/kinds/plugin.md` | updated | 移除 `core/local-dev` profile 和 `Local Development` section |
| `plugins/forge/skills/onboard/profiles/kinds/web-backend.md` | updated | 同上 |
| `plugins/forge/skills/onboard/profiles/kinds/web-frontend.md` | updated | 同上 |
| `plugins/forge/skills/onboard/profiles/kinds/monorepo.md` | updated | 同上 |
| `plugins/forge/skills/onboard/profiles/core/local-dev.md` | updated | 添加 deprecation header，并清空 `applies-to` |

## Acceptance Criteria Status

- [x] 4 个 Stage-2 kind manifest 均不再引用 `core/local-dev`
- [x] 4 个 `output-sections` 均不再出现 `Local Development`
- [x] `local-dev.md` 已标记 deprecated，且不再适用于任何 kind

## Assumptions Made

- 无
