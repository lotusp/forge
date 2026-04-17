# conventions.md Output Template

This file defines the exact structure for `.forge/conventions.md`.
Referenced by `/forge:calibrate` Step 8.

---

```markdown
# Project Conventions

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate

**Important:** This file is the authoritative source of truth for all new
development. /forge:code, /forge:review, and /forge:test all reference this
document. If conventions change, regenerate this file.

---

## Architecture & Layering

{Rules about which layer calls which, where business logic lives, what each
layer is responsible for. Include explicit "NOT allowed" rules.}

**Rules:**
- {Rule} (observed in: file:line)
- ...

---

## Naming Conventions

### Classes
{Pattern with suffix table and examples. Cite observed examples.}

### Methods & variables
{Pattern with examples.}

### Constants
{Pattern with examples.}

### Database tables & columns
{Naming pattern with examples. Include ORM mapping rules.}

### Migration files
{File naming pattern with example.}

### URL resources
{URL structure pattern. State explicitly whether versioning (/api/v2) is
used and when.}

---

## Logging

- **Library:** {e.g. SLF4J via @Slf4j / Winston / Zap}
- **Format:** {structured JSON / plain text}
- **Always include in log messages:** {e.g. orderId=, salesType=}
- **Level semantics:**
  - `error`: {when to use — e.g. caught exceptions requiring investigation}
  - `warn`: {when to use — e.g. expected but noteworthy conditions}
  - `info`: {when to use — e.g. significant state transitions}
  - `debug`: {when to use — e.g. diagnostic detail not needed in production}
- **Prohibited patterns:** {e.g. do not use LoggerFactory.getLogger() directly}

---

## Error Handling

{Chosen exception/error pattern with a short code example.}
{Include: exception hierarchy if applicable, HTTP status mapping,
where errors are caught (global handler?), error response shape.}

**Example — defining a new exception:**
```
{language-specific example}
```

**Prohibited patterns:**
- {e.g. Do not return { success: false } objects from service methods}

---

## Validation

| Concern | Mechanism | Where |
|---------|-----------|-------|
| {e.g. HTTP request body} | {library/annotation} | {layer} |
| {e.g. Business pre-conditions} | {method} | {layer} |
| {e.g. Authorisation/access} | {annotation/middleware} | {layer} |

---

## Testing

- **Test location:** {e.g. src/test/java/... mirrors main package structure}
- **Base class:** {name and key behaviours it provides}
- **HTTP testing:** {preferred library — e.g. RestAssuredMockMvc, not raw MockMvc}
- **Test method naming:** {pattern — e.g. should_{outcome}_when_{condition}}
- **Test data:** {builder/fixture pattern and where to find them}
- **Mock strategy:** {what to mock, at which layer boundary}
- **DB cleanup between tests:** {rollback vs truncate, and when to use each}

---

## API Design

- **URL structure:** {pattern with example}
- **HTTP verbs:** {GET/POST/PUT/PATCH/DELETE semantics}
- **Response envelope:** {wrapped vs unwrapped, with example}
- **Error response shape:** {example JSON}
- **Status codes:** {which codes are used for which situations}
- **Documentation:** {e.g. @ApiOperation required on every public endpoint}

---

## Database Access

- **Pattern:** {e.g. Spring Data JPA — all access through *Repository interfaces}
- **Custom queries:** {JPQL preferred vs native SQL — when to use each}
- **Transaction boundaries:** {which layer owns @Transactional, rollbackFor rules}
- **Fetch strategy:** {EAGER vs LAZY defaults, when to override}
- **Migration tool:** {Flyway / Liquibase / Prisma Migrate — no auto-DDL}

---

## Messaging & Events

{Only include if the codebase uses messaging or internal event bus.}

- **Internal events:** {when to use Spring ApplicationEvent / Node EventEmitter / etc.}
- **External messaging:** {when to use message broker — Azure Service Bus / Kafka / SQS}
- **Consumer pattern:** {how consumers are structured, error handling for async failures}

---

## What to Avoid

{Anti-patterns found in the codebase that must not appear in new code.
Each entry must cite the file where the anti-pattern was observed.}

- **{Anti-pattern name}:** {Description}. Found in: `{file:line}` — do not replicate.
- ...

---

## Decision Log

Decisions made during calibration that involved user adjudication.

| # | Dimension | Conflict | Decision | Rationale |
|---|-----------|----------|----------|-----------|
| 1 | {e.g. URL versioning} | /api vs /api/v2 | {chosen pattern} | {user's stated reason or AI recommendation accepted} |
| 2 | ... | ... | ... | ... |

---

## Open Questions

Convention dimensions that could not be resolved during calibration.
These require a follow-up decision before work in that area begins.

| Dimension | Question | Impact |
|-----------|----------|--------|
| {area} | {unresolved question} | {what it affects} |
```
