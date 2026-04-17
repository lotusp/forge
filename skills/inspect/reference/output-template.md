# inspect.md Output Template

This file defines the exact structure for `.forge/review-{feature-slug}.md`.
Referenced by `/forge:inspect` Step 6.

---

```markdown
# Review: {feature-slug}

> 评审时间：YYYY-MM-DD
> 评审范围：{list of files reviewed}
> Conventions：{found / not found — reviewed for internal consistency only}

---

## Overall Verdict

**ready** / **needs-work** / **needs-redesign**

{One paragraph summarising the overall state of the implementation.}

---

## Findings

### `path/to/file.ts`

#### [must-fix] {Short title}
**位置：** Line N (or lines N–M)
**问题：** {What is wrong}
**依据：** conventions.md > {Section name} — "{relevant rule quoted}"
**建议：** {Specific change to make}

#### [should-fix] {Short title}
**位置：** Line N
**问题：** {What could be better}
**建议：** {Specific change}

#### [consider] {Short title}
**建议：** {Optional improvement suggestion — no obligation}

---

### `path/to/another-file.ts`

_No findings above confidence threshold._

---

## Convention Compliance Summary

| Dimension | Status | Notes |
|-----------|--------|-------|
| Architecture / layering | ✅ / ⚠️ / ❌ | |
| Naming | ✅ / ⚠️ / ❌ | |
| Logging | ✅ / ⚠️ / ❌ | |
| Error handling | ✅ / ⚠️ / ❌ | |
| Validation | ✅ / ⚠️ / ❌ | |
| Testing | ✅ / ⚠️ / ❌ | |

✅ Compliant  ⚠️ Minor issues  ❌ Violations found

---

## Design Adherence

{Was the implementation faithful to .forge/design-{slug}.md?
Note any deviations — intentional or not.}

_No design artifact available._ ← use this if design doc was not found

---

## Scope Creep

{Files changed that were not in the design or plan scope.}

_None._
```
