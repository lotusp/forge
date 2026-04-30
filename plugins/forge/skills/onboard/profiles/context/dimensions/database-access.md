---
name: database-access
output-file: conventions.md
applies-to:
  - web-backend
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - grep: "(Prisma|TypeORM|Sequelize|Hibernate|JPA|GORM|SQLAlchemy|sqlx|Entity)"
  - glob: "**/migrations/**"
  - glob: "schema.prisma"
  - glob: "**/entities/**"
confidence-signals:
  - ORM declared in dependencies
  - Repository / DAO / query component pattern observed
  - migration tool + migration files present
token-budget: 900
---

# Dimension: Database Access

## Scan Patterns

**ORM / query-builder detection:**

| Evidence | Tool |
|----------|------|
| `schema.prisma` + `PrismaClient` | Prisma |
| `@Entity` (TS) + TypeORM imports | TypeORM |
| `@Entity` + `@Table` + `@Column` (Java) + `EntityManager` | JPA / Hibernate |
| `gorm.Model` + struct tags | GORM |
| `sqlalchemy.Column` + declarative_base | SQLAlchemy |
| `sqlx.QueryRow` + struct tags | sqlx (Go) |
| Raw SQL in `.sql` files | Raw SQL + query builder |

**Repository pattern detection:**
```
Glob "**/repositor*/" or "**/dao/" or "**/*Repository.{ts,java,go,py}"
  → presence suggests Repository pattern usage
```

**Migration tooling:**
- `prisma migrate` config → Prisma Migrate
- `flyway.conf` / `V*__*.sql` → Flyway
- `db/migrate/*.rb` → Rails
- `migrations/*.sql` + `golang-migrate` → golang-migrate
- Sequelize / TypeORM migrations

**Transaction boundary detection:**
```
Grep "@Transactional" / "beginTransaction" / "WithContext.*Tx"
  → transaction scope (service / repository / request-scoped)
```

## Extraction Rules

1. Identify **primary ORM / query tool** if present.
2. Detect actual **Repository / DAO / query component / raw SQL** usage.
3. Document **transaction boundaries** as observed; do not assume they belong
   to a service layer.
4. Identify **migration tool** and where migrations live
5. Detect **N+1 avoidance** patterns (`include:` / `join fetch` / `Preload`)
   only when present.
6. Document **raw SQL usage or policy** only when evidenced by code or docs.
7. Do not emit "must not" rules for controller/service/repository boundaries
   unless the current repo has enforcement evidence.

## Output Template

```markdown
## Database Access

**ORM / query tool:** <Prisma | JPA/Hibernate | GORM | SQLAlchemy | ...>
[high] [build]

**Pattern:** Repository / DAO — all DB access through `<XxxRepository>` classes
[medium] [code]

**Location of DB logic:**
- `<path-or-component>` — <observed DB/query role> [medium] [code]
- `<path-or-component>` — <observed direct ORM/raw SQL usage, if present>
  [medium] [code]

**Enforced DB boundaries:**
- <rule backed by test/lint/build/runtime evidence, or omit this subsection>
  [high] [code]

**Transactions:**
- Declared at `<observed layer/component>` [medium] [code]
- Transaction behavior not fully traced across all DB paths [medium] [code]

**Migrations:**
- Tool: <Prisma Migrate | Flyway | golang-migrate | ...> [high] [build]
- Directory: `<path>` [high] [code]
- Naming: <V<NNN>__<description>.sql | <YYYYMMDDHHMMSS>-<name>.sql> [high] [code]
- Applied migration policy: <local rule if documented/enforced, otherwise omit>
  [medium] [readme]

**N+1 avoidance:**
- Use `<include: | join fetch | Preload | joinedload>` for parent-child
  loads [medium] [code]
- Detect with <dataloader | query log inspection> [medium] [code]

**Raw SQL:**
- <Allowed in repositories only for complex aggregations | Forbidden — use
  ORM query builder always> [high] [code]

### Observed Risks / Inconsistencies

- <direct DB access, mixed transaction style, migration inconsistency, or raw SQL
  risk observed in the current repo> [medium] [code]
```

## Confidence Tags

- `[high]` — DB tool/pattern exhaustively verified with no conflicting evidence
- `[medium]` — DB tool/pattern observed but sampled or inconsistent
- `[low]` — ORM declared but mostly raw SQL observed
- `[inferred]` — DB stack inferred from docker-compose without confirming code
