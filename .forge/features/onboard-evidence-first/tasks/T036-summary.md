# Code Summary: T036

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/context/dimensions/hard-constraints.md` | rewritten | 收窄为只产 `## Hard Constraints`，并将 process-rule 移交给 `delivery-conventions` |

## Acceptance Criteria Status

- [x] Extraction Rules 仅接受 `enforced-rule` + `[high]`
- [x] 新增 Claim Classification Annotations
- [x] 明确 process-rule / current-caveat / inferred 不进入 `Hard Constraints`
- [x] Output Template 只保留 `## Hard Constraints`

## Assumptions Made

- 无
