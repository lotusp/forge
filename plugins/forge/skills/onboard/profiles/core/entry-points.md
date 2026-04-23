---
name: entry-points
section: Entry Points
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
confidence-signals:
  - HTTP route definitions
  - CLI argument parser usage
  - Scheduled job / cron registration
  - Event consumer registration
  - plugin.json skills/agents declarations (claude-code-plugin)
token-budget: 1500
---

# Profile: Entry Points

## Scan Patterns

**HTTP / REST:**
- Express: `app\.(get|post|put|delete|patch)\(` or `router\.(get|post|...)\(`
- Fastify: `fastify\.(get|post|...)\(` or `app\.route\(`
- Spring: `@(Get|Post|Put|Delete|Patch|Request)Mapping` / `@RestController`
- Gin: `\.(GET|POST|PUT|DELETE|PATCH)\(` on gin.Engine / gin.RouterGroup
- FastAPI: `@app\.(get|post|put|delete|patch)\(` / `@router\.(...)`
- Koa/Hono: similar route decorators

**GraphQL:**
- `type Query` / `type Mutation` in `*.graphql` files
- resolver registration files

**CLI:**
- Node: `commander` / `yargs` / `oclif`
- Go: `cobra.Command`
- Python: `click.command` / `argparse`
- Rust: `clap::Parser` derive

**Background / scheduled:**
- cron expressions in config
- `@Scheduled` (Spring) / `BullMQ` / `node-cron` / `APScheduler`

**Event consumers:**
- Kafka: `consumer.subscribe` / `@KafkaListener`
- RabbitMQ: `channel.consume` / `@RabbitListener`
- SQS: `Consumer.create` / lambda event source
- NATS: `subscribe(subject, ...)`

**Claude Code plugin entry points:**
- `skills/<name>/SKILL.md` — each file = one skill
- `agents/<name>.md` — each file = one agent
- `.claude-plugin/plugin.json` — declarative manifest

## Extraction Rules

1. **Group by kind** — HTTP / CLI / Jobs / Event Consumers / Plugin Skills. Omit groups
   with no matches (no "None" placeholders).
2. **Representative examples, not inventory** — 3–5 per group maximum. Prefer the most
   frequently used routes (auth, main resource CRUD) over edge cases.
3. **Include path reference** — `file:line` when line is known, else `file` alone.
4. **For HTTP** — also extract the base URL pattern (e.g. `/api/v1`).
5. **For plugin skills** — list each skill with the invocation form (`/forge:<name>`).

## Section Template

```markdown
## Entry Points

### HTTP API
Base URL pattern: `/api/v1`
Representative routes:
- `POST /auth/login` — `src/routes/auth.ts:42` [high]
- `GET /orders/:id` — `src/routes/orders.ts:15` [high]
- `POST /orders` — `src/routes/orders.ts:28` [high]

### CLI
- `order-cli migrate` — runs pending schema migrations (`cmd/cli/migrate.go`) [high]

### Background Jobs
- `payment-reconcile` — hourly cron (`src/jobs/payment-reconcile.ts`) [medium]

### Event Consumers
- `order.created` → Kafka topic `orders.events` (`src/consumers/order.ts`) [high]

### Plugin Skills (claude-code-plugin only)
- `/forge:onboard` — project map generation + context file extraction (Stage 3) [high]
- `/forge:design` — technical design + task plan in one pass [high]
```

## Confidence Tags

- `[high]` — handler definition located with file:line
- `[medium]` — handler inferred from route manifest without reading the handler body
- `[low]` — entry point mentioned in README but no source match
- `[inferred]` — category existence guessed (e.g. "likely has cron jobs" without match)
