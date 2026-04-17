# tasking.md Output Template

This file defines the exact structure for `.forge/features/{feature-slug}/plan.md`.
Referenced by `/forge:tasking` Step 7.

---

```markdown
# Plan: {feature-slug}

> 基于：features/{feature-slug}/design.md
> 生成时间：YYYY-MM-DD
> 文件路径：.forge/features/{feature-slug}/plan.md

---

## Task List

### T00X — {Task Name} `{type}` [⚠ 高风险]
**描述：** One sentence explaining what this task implements and why.
**依赖：** 无 / T00A, T00B
**范围：**
- Create / modify `path/to/file` — reason
- ...

**验收标准：**
- [ ] Specific, checkable condition (file/unit level)
- [ ] ...

**规模预估：** small / medium / large

---

### T00Y — {Task Name} `{type}`
...

---

## Dependency Graph

T001 → T003 → T005
T002 → T003

## Risk Register

| Task | Risk | Mitigation |
|------|------|------------|
| T00X | Description of risk | How to reduce it |

## Execution Order

Tasks on the same line can run in parallel.

1. T001
2. T002, T003  ← parallel
3. T004
```
