---
name: domain-model
section: Domain Concepts / Data Model
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - src/models/ or src/domain/ or src/entities/ directory
  - ORM entity decorators (@Entity / Prisma schema)
  - database schema files, DTOs, messages, or external API models
token-budget: 1000
---

# Profile: Domain Concepts / Data Model

## Scan Patterns

**Model and concept locations:**

- `src/models/**`, `src/entities/**`, `src/domain/**`
- `**/*.entity.{ts,js}`, `**/*.model.{ts,js}`
- `**/entity/*.java`, `**/domain/*.java`
- Prisma: `schema.prisma` (single source of truth)
- TypeORM: `@Entity()` decorator grep
- Sequelize: `sequelize.define(` grep
- Pydantic: `class <Name>(BaseModel):` grep
- database migration/schema files
- message/event DTOs and external API request/response models

**Domain-organization signals:**

- repeated concept names across packages/modules/files
- state enum or workflow names
- table names, document types, queue/message payload names, or API DTOs

## Extraction Rules

1. **Describe the current codebase's own domain/data shape.** It may be an ORM
   entity model, schema-first model, DTO-heavy service, procedural module set,
   external API model, or mixed legacy model.
2. **List core concepts only** — the 5–10 most central concepts directly
   evidenced by code/schema/config. Skip incidental DTOs unless DTOs are the
   dominant model.
3. **Do not invent aggregate boundaries.** Only use "aggregate", "bounded
   context", "entity", or similar vocabulary when the codebase uses or strongly
   evidences it.
4. **Use actual file locations.** Do not move concepts into conventional
   directories in the output if they are physically elsewhere.
5. **Relationships at a glance** — note 1–2 key relationships only when traced
   from fields, schema, ORM metadata, or repeated code usage.
6. **Skip fields entirely** — field lists belong in `/forge:design`'s
   Component Changes section or code-level context, not onboard.
7. **Generic examples only** — when examples are needed in this profile, use
   familiar placeholder concepts such as `Order`, `Customer`, `Product`, or
   `Payment`. Never copy real project classes, packages, endpoints, queues, or
   business terms into the profile itself.

## Section Template

```markdown
## Domain Concepts / Data Model

### Observed Shape

- <ORM entities / schema-first tables / DTO-heavy external API model / mixed
  model / other observed shape> [medium] [code]

### Core Concepts

- **`Order`** — <business role confirmed from code/schema usage> [high] [code]
- **`Customer`** — <business role confirmed from code/schema usage> [medium] [code]
- **`Product`** — <business role confirmed from code/schema usage> [medium] [code]

### Relationships / State

- `<relationship or state transition traced from fields/schema/usage>`
  [medium] [code]

### Notes

- <important inconsistency, mixed model, or untraced gap that helps future
  developers understand the codebase> [medium] [code]
```

If the project has few domain concepts or no clear domain/data model, say what
was actually found, for example "Project is mostly infrastructure/tooling code"
or "No structured domain model was found in the scanned sources." Do not force
an aggregate/entity vocabulary.

## Confidence Tags

- `[high]` — concept file/schema located and purpose confirmed from code usage
- `[medium]` — concept identified from repeated code/schema evidence but not fully traced
- `[low]` — entity mentioned in ORM config but file not inspected
- `[inferred]` — avoid
