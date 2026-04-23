---
name: db-schema
section: Database Schema
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - migrations/ or db/migrations/ directory
  - schema.sql / schema.prisma
  - ORM schema files
token-budget: 1000
---

# Profile: Database Schema

## Scope Boundary

This profile produces **a table inventory**, not ERD diagrams or full column schemas.
Detailed schema analysis lives in onboard Stage 3's `architecture.md`
(when the `database-access` dimension is loaded) or in a feature-level
`design.md`. Onboard Stage 2 (this profile) stays high-level.

**Explicit non-goals:**
- ❌ Column-level enumeration
- ❌ ERD / visual diagrams
- ❌ Index / constraint listings
- ❌ Query performance notes

## Scan Patterns

**Migration sources (priority order):**

1. `schema.prisma` — Prisma single-file schema
2. `db/migrations/` / `migrations/` / `prisma/migrations/` — migration directories
3. `src/**/schema.sql` / `init.sql`
4. TypeORM `@Entity()` decorators (if no migrations)
5. Flyway / Liquibase: `db/migration/V*__*.sql` or `db/changelog/*`

**Count signals:**

- Number of migration files (growth indicator)
- Number of tables in latest schema
- Presence of multi-tenant columns (`tenant_id`, `workspace_id`)

## Extraction Rules

1. **Table inventory** — list tables grouped by domain (use module-map categories where
   possible). Cap at ~20 tables; group if more.
2. **One-line role per table** — what it persists, not columns.
3. **Migration tool + count** — e.g. "Prisma Migrate, 47 migrations applied".
4. **Multi-tenancy note** — if `tenant_id` / `workspace_id` appears in most tables,
   state "multi-tenant by row".
5. **Soft-delete note** — if `deleted_at` / `is_deleted` is widespread.
6. **Skip if no DB** — libraries, pure-CPU services, plugins.

## Section Template

```markdown
## Database Schema

- **Database:** PostgreSQL 15 [high]
- **Migration tool:** Prisma Migrate (47 migrations in `prisma/migrations/`) [high]
- **Multi-tenancy:** row-scoped via `tenant_id` on all business tables [high]
- **Soft delete:** `deleted_at` on core tables (Order, Customer, Product) [medium]

### Table Inventory

| Domain | Tables |
|--------|--------|
| Identity | `users`, `sessions`, `api_keys` [high] |
| Order | `orders`, `order_items`, `payments`, `refunds` [high] |
| Catalog | `products`, `categories`, `inventory` [high] |
| Audit | `audit_log` [medium] |

For full column definitions read `prisma/schema.prisma` or the migrations
directory directly — onboard keeps the view high-level.
```

## Confidence Tags

- `[high]` — table verified in schema file or migration
- `[medium]` — table name inferred from ORM usage without schema inspection
- `[low]` — mentioned in README only
- `[inferred]` — avoid
