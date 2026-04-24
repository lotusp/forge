# Code Summary: T034

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/structural/deployment.md` | rewritten | 将 deployment 收窄为 deploy-shape 事实，不再输出执行命令、环境值或运维步骤 |

## Acceptance Criteria Status

- [x] Section Template 仅保留单行部署事实
- [x] 增加 Claim Classification Annotations
- [x] 明确禁止 deploy commands / registry URL / secret path / env 枚举等执行层内容

## Assumptions Made

- 无
