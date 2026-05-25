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
3. **Migration tool + scale, with examples (v0.6).** Read the
   `flyway_migrations` entry from `.forge/_session/facts.json` (or
   the equivalent for the project's migration tool). Render:

   - the size word (`many` / `a large set of` / etc.) matching
     `inferred_size`
   - 3–5 sample migration filenames from `samples` to convey what
     the schema evolution looks like
   - anchor with `<!-- ev:id=flyway_migrations -->`

   Example:

   ```markdown
   - **Migration tool:** Flyway 4.2.0; <!-- ev:id=flyway_migrations -->
     a large set of `V*.sql` migration files. Recent examples:
     - `V2024_05_03__add_payment_table.sql`
     - `V2024_03_18__alter_order_status.sql`
     - `V2023_11_02__drop_legacy_index.sql`
   ```

   No precise counts. Counts are unreliable because copies live in
   `build/` and `bin/` after compilation; the size bucket is robust
   to that, and the sample filenames carry the schema-evolution
   timeline.
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
