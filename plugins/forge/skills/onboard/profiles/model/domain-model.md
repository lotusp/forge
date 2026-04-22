---
name: domain-model
section: Domain Model
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - src/models/ or src/domain/ or src/entities/ directory
  - ORM entity decorators (@Entity / Prisma schema)
  - DDD-style aggregate files
token-budget: 1000
---

# Profile: Domain Model

## Scan Patterns

**Entity file locations:**

- `src/models/**`, `src/entities/**`, `src/domain/**`
- `**/*.entity.{ts,js}`, `**/*.model.{ts,js}`
- `**/entity/*.java`, `**/domain/*.java`
- Prisma: `schema.prisma` (single source of truth)
- TypeORM: `@Entity()` decorator grep
- Sequelize: `sequelize.define(` grep
- Pydantic: `class <Name>(BaseModel):` grep

**Aggregate / bounded context signals:**

- DDD layout: `src/<context>/domain/`, `src/<context>/application/`,
  `src/<context>/infrastructure/`
- Folder names: `order/`, `customer/`, `catalog/`, `payment/`, `inventory/`

## Extraction Rules

1. **List core entities only** — the 5–10 most central domain objects (skip DTOs,
   request/response types, pure value objects).
2. **One-line purpose per entity** — business role, not field enumeration.
3. **Note aggregate boundaries** — if DDD-style, group entities by aggregate root.
4. **Relationships at a glance** — note 1–2 key relationships per aggregate ("Order has
   many OrderItems, belongs to Customer").
5. **Skip entity fields entirely** — field lists belong in `/forge:calibrate` or code-level
   context, not onboard.
6. **Generic domain only** — when example needed, use `Order`, `Customer`, `Product`,
   `Payment` (e-commerce palette per C8).

## Section Template

```markdown
## Domain Model

Core entities and their aggregate boundaries:

### Order aggregate
- **`Order`** — lifecycle root; holds status, total, timestamps [high]
- **`OrderItem`** — line item; child of Order [high]
- **`Payment`** — one per Order, records settlement state [high]

### Customer aggregate
- **`Customer`** — account holder; billing address [high]
- **`Address`** — value object; embedded in Customer [medium]

### Catalog aggregate
- **`Product`** — SKU-addressable catalog item [high]
- **`Inventory`** — stock count per Product per warehouse [high]

**Cross-aggregate relationships:**
- `Order.customerId` → `Customer.id`
- `OrderItem.productId` → `Product.id` (soft FK; no DB constraint) [medium]
```

If project has < 4 entities or no clear domain, state "Project has no structured domain
model (utility library / tooling)" and omit the entity list.

## Confidence Tags

- `[high]` — entity file located and purpose confirmed from class-level comment or usage
- `[medium]` — entity identified but purpose inferred from name
- `[low]` — entity mentioned in ORM config but file not inspected
- `[inferred]` — avoid
