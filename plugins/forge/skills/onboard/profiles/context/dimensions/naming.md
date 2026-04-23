---
name: naming
output-file: conventions.md
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py,rs}"
  - glob: "plugins/*/skills/*/SKILL.md"
  - glob: "packages/*/src/**/*.{ts,js}"
  - glob: "**/migrations/*.sql"
confidence-signals:
  - majority pattern across sampled files (≥ 70% frequency)
  - explicit naming statement in project README / CLAUDE.md
  - linter config (eslint / checkstyle / golangci) enforcing a style
token-budget: 800
---

# Dimension: Naming Conventions

## Scan Patterns

**File names** — enumerate top-level source directories, catalogue extensions:
```
Glob "src/**/*"  →  collect basename styles
  kebab-case      (user-service.ts)
  camelCase       (userService.ts)
  PascalCase      (UserService.ts)
  snake_case      (user_service.py)
```

**Identifier styles** — grep symbol definitions:
```
"class [A-Za-z_]+"   → class name style
"function [A-Za-z_]+" / "def [A-Za-z_]+"  → function style
"const [A-Z_]+ ="    → constant style
```

**Database columns** — scan migration files:
```
"CREATE TABLE" / "ALTER TABLE ... ADD COLUMN"
  → column name case (snake_case | camelCase)
```

## Extraction Rules

1. Record the **dominant** pattern per category (file / class / function /
   variable / constant / DB column)
2. If two patterns coexist with < 70 / 30 ratio → mark as **conflict**,
   add to batch conflict list
3. If a linter config exists, prefer its declared style over observed
   counts (linter declarations carry higher confidence)
4. For claude-code-plugin kind, skip DB column scan (not applicable)

## Output Template

```markdown
## Naming Conventions

### Files
<Pattern> — e.g. `<example>` [high] [code]

### Classes
<Pattern> — e.g. `<example>` [high] [code]

### Functions / methods
<Pattern> — e.g. `<example>` [high] [code]

### Variables / constants
<Pattern> — e.g. `<example>` [high] [code]

### Database tables / columns  {web-backend / monorepo only}
<Pattern> — e.g. `<example>` [high] [build]
```

Example output for an e-commerce order platform:

```markdown
## Naming Conventions

### Files
kebab-case — e.g. `order-service.ts`, `payment-handler.ts` [high] [code]

### Classes
PascalCase — e.g. `OrderService`, `CustomerRepository` [high] [code]

### Functions / methods
camelCase — e.g. `createOrder`, `findCustomerById` [high] [code]

### Variables / constants
SCREAMING_SNAKE_CASE for module-level constants
(`DEFAULT_PAGE_SIZE`, `MAX_RETRY_COUNT`) [high] [code]

### Database tables / columns
snake_case — e.g. `orders`, `order_items`, `customer_id` [high] [build]
```

## Confidence Tags

- `[high]` — observed across ≥ 70% sampled files OR declared by linter config
- `[medium]` — observed across 50–70% sampled files without linter backing
- `[low]` — observed across < 50%, pattern choice inferred from newer code
- `[inferred]` — no direct evidence; guessed from one-off filename
