# Calibrate Output Templates

The `/forge:calibrate` skill produces **four separate files** under `.forge/context/`.
Each template is shown below. Referenced by `/forge:calibrate` Step 8.

---

## context/conventions.md

Covers: naming, logging, error handling, validation, API design, database access, messaging.

```markdown
# Project Conventions

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate

**Important:** This file defines coding conventions for new development.
/forge:code, /forge:inspect, and /forge:test all reference this document.
See also: context/testing.md, context/architecture.md, context/constraints.md.

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
- **Always include in log messages:** {e.g. orderId=, requestId=}
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

---

## context/testing.md

Covers: test framework, isolation strategy, mock strategy, test data patterns, naming conventions, coverage expectations.

```markdown
# Testing Conventions

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决

**Important:** This file is the authoritative source of truth for all test
development. /forge:test reads this document before generating any test code.

---

## Test Framework

- **Unit test framework:** {e.g. JUnit 5 + AssertJ / Jest / pytest}
- **Integration test framework:** {e.g. Spring Boot Test / Supertest}
- **Mocking library:** {e.g. Mockito / jest.mock / unittest.mock}
- **Assertion style:** {e.g. assertThat(x).isEqualTo(y) — never assertEquals}

---

## Test Location

- **Unit tests:** {e.g. src/test/java/... mirrors src/main/java/... package structure}
- **Integration tests:** {e.g. src/test/java/.../integration/ subdirectory}
- **File naming:** {e.g. UserServiceTest.java for unit, UserServiceIT.java for integration}
- **Test method naming:** {pattern — e.g. should_{outcome}_when_{condition}}

---

## Mock Strategy

- **Mock at:** {e.g. repository boundary — never mock service-to-service calls}
- **Do not mock:** {e.g. domain objects, value objects}
- **Preferred approach:** {e.g. @MockBean for Spring context tests, @Mock + @InjectMocks for pure unit tests}
- **When to use real implementations:** {e.g. always use real domain model objects}

---

## Test Data

- **Preferred approach:** {e.g. builder pattern — use *Builder classes, never new EntityClass() directly}
- **Fixtures:** {e.g. JSON fixtures in src/test/resources/fixtures/}
- **Database seeding:** {e.g. @Sql annotation with setup scripts for integration tests}
- **Factories:** {e.g. TestDataFactory class with static factory methods per entity}

---

## Test Isolation

- **Between unit tests:** {e.g. no shared mutable state — every test constructs its own instances}
- **Between integration tests:** {e.g. @Transactional rollback after each test / @DirtiesContext / manual truncate}
- **When to use truncate vs rollback:** {e.g. rollback for read-only tests, truncate when events are committed mid-test}

---

## Coverage

- **Minimum line coverage:** {e.g. 80% for service layer}
- **What must have unit tests:** {e.g. all service methods, all domain model methods with logic}
- **What must have integration tests:** {e.g. all repository custom queries, all controller endpoints}
- **What is explicitly excluded:** {e.g. DTOs, generated code, configuration classes}

---

## Open Questions

| Area | Question | Impact |
|------|----------|--------|
| {area} | {unresolved question} | {what it affects} |
```

---

## context/architecture.md

Covers: layering rules, inter-module communication, cross-cutting concerns, known tech debt.

```markdown
# Architecture Conventions

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决

**Important:** This file defines structural rules for where code lives and how
modules communicate. /forge:design and /forge:inspect reference this document.

---

## Layering

{Description of the layer model: which layers exist, what each owns, and
which direction dependencies flow. Include explicit "NOT allowed" rules.}

**Rules:**
- {Rule} (observed in: file:line)
- {e.g. Controllers must not access Repository interfaces directly} (file:line)
- {e.g. Business logic must not depend on Spring HTTP types} (file:line)
- ...

**Layer ownership:**
| Layer | Responsibility | Allowed to call |
|-------|---------------|-----------------|
| Controller | HTTP boundary, request mapping | Application Service |
| Application Service | Business process orchestration | Domain, Repository |
| Domain | Business rules, invariants | Nothing outside domain |
| Repository / Infrastructure | Data access, external services | DB, external APIs |

---

## Inter-Module Communication

- **Service-to-service calls:** {e.g. Feign clients only — no direct repository access across modules}
- **Internal events:** {e.g. Spring ApplicationEvents for within-module async — not for cross-module}
- **Shared types:** {e.g. shared DTOs live in common module — never import domain entities across modules}

---

## Cross-Cutting Concerns

- **Authentication/authorisation:** {where it lives — e.g. API gateway + @PreAuthorize on controller methods}
- **Logging context:** {how request context propagates — e.g. MDC with requestId, userId}
- **Error translation:** {e.g. single @RestControllerAdvice in each BFF, not in domain services}
- **Caching:** {where caches live and who owns cache invalidation}

---

## Known Tech Debt

{Areas of the codebase that violate these rules but exist for historical reasons.
New code must not replicate these patterns.}

| Location | Violation | Reason it exists | Plan to fix |
|----------|-----------|-----------------|-------------|
| `path/to/file:line` | {what rule it violates} | {why it was done} | {planned fix or "no fix planned"} |
```

---

## context/constraints.md

Covers: hard non-negotiable rules, anti-patterns with file locations, security and compliance rules.

```markdown
# Constraints & Anti-Patterns

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决

**Important:** These rules must never be violated in new code. Each anti-pattern
entry cites where the pattern exists in the legacy codebase — do not replicate it.
/forge:inspect uses this document as a blocking checklist.

---

## Hard Rules

Rules that must not be violated under any circumstances, regardless of context.
Violations are always `must-fix` findings in /forge:inspect.

- **{Rule name}:** {Description of what is forbidden and why.}
  - Applies to: {all code / controller layer / service layer / etc.}
- **{Rule name}:** {Description.}
- ...

Examples of hard rules:
- No raw SQL in service or domain layers — all DB access through repository interfaces
- No @Transactional on Controller methods
- No direct calls to another module's Repository from outside that module
- No business logic in event Listeners or message Consumers (delegate to services)

---

## Anti-Patterns

Patterns found in the existing codebase that must not appear in new code.
Each entry includes where the pattern was found so reviewers can identify
and not replicate it.

- **{Anti-pattern name}:** {Description}.
  Found in: `{file:line}` — {brief explanation of why it is problematic and what to do instead}.

- **{Anti-pattern name}:** {Description}.
  Found in: `{file:line}`

---

## Security & Compliance Rules

Rules driven by security requirements, compliance obligations, or audit findings.

- **{Rule}:** {Description and rationale.}
- ...

Examples:
- All endpoints that return PII must have @RequiresRole annotation
- Passwords and secrets must never appear in log output
- External API credentials must come from environment variables or Azure Key Vault — never hardcoded
```
