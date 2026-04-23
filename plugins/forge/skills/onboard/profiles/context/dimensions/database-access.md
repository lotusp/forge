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
  - Repository / DAO pattern used consistently
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

1. Identify **primary ORM / query tool**
2. Detect **Repository / DAO pattern** usage
3. Document **transaction boundary** (service layer is most common)
4. Identify **migration tool** and where migrations live
5. Detect **N+1 avoidance** patterns (`include:` / `join fetch` / `Preload`)
6. Document **raw SQL policy** (allowed in repositories only? never?)

## Output Template

```markdown
## Database Access

**ORM / query tool:** <Prisma | JPA/Hibernate | GORM | SQLAlchemy | ...>
[high] [build]

**Pattern:** Repository / DAO — all DB access through `<XxxRepository>` classes
[high] [code]

**Location of DB logic:**
- Repository layer: `src/repositories/` (or equivalent) [high] [code]
- Business logic / services MUST NOT call ORM directly [high] [code]
- Controllers MUST NOT touch DB at all [high] [code]

**Transactions:**
- Declared at service layer (`@Transactional` or equivalent) [high] [code]
- Repository methods inherit service's transaction; do not open their own
  [high] [code]

**Migrations:**
- Tool: <Prisma Migrate | Flyway | golang-migrate | ...> [high] [build]
- Directory: `<path>` [high] [code]
- Naming: <V<NNN>__<description>.sql | <YYYYMMDDHHMMSS>-<name>.sql> [high] [code]
- **Never** edit applied migrations — always add a new one [high] [readme]

**N+1 avoidance:**
- Use `<include: | join fetch | Preload | joinedload>` for parent-child
  loads [medium] [code]
- Detect with <dataloader | query log inspection> [medium] [code]

**Raw SQL:**
- <Allowed in repositories only for complex aggregations | Forbidden — use
  ORM query builder always> [high] [code]

### What to avoid

- ORM calls inside controllers or services
- Lazy loading in hot paths without explicit fetch strategy
- Modifying applied migrations in place
- Transaction boundaries opened in repositories
- Raw SQL string concatenation (SQL injection risk)
```

## Confidence Tags

- `[high]` — ORM declared in deps AND ≥ 80% DB access via repository layer
- `[medium]` — ORM used but pattern inconsistent (some direct access)
- `[low]` — ORM declared but mostly raw SQL observed
- `[inferred]` — DB stack inferred from docker-compose without confirming code
