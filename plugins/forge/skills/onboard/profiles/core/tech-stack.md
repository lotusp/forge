---
name: tech-stack
section: Tech Stack
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
confidence-signals:
  - language config files present (package.json / pom.xml / go.mod / Cargo.toml / pyproject.toml)
  - Dockerfile or docker-compose.yml present
  - lock files present (package-lock.json / pnpm-lock.yaml / poetry.lock / Cargo.lock)
token-budget: 1200
---

# Profile: Tech Stack

## Scan Patterns

**Language / runtime detection (first-match wins within each bucket):**

| Glob | Implies |
|------|---------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `pom.xml` / `build.gradle` / `build.gradle.kts` | JVM (Java / Kotlin / Scala) |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `mix.exs` | Elixir |
| `.claude-plugin/plugin.json` | Claude Code plugin |

**Framework detection (grep inside identified config):**

| Pattern | Implies |
|---------|---------|
| `"express"` / `"fastify"` / `"koa"` in package.json deps | Node web framework |
| `spring-boot-starter` in pom.xml | Spring Boot |
| `github.com/gin-gonic/gin` in go.mod | Gin |
| `fastapi` / `flask` / `django` in requirements | Python web framework |

**Infrastructure signals:**

| File | Extract |
|------|---------|
| `Dockerfile` | base image → runtime version |
| `docker-compose.yml` | services list (DB / cache / MQ) |
| `.nvmrc` / `.node-version` | Node version |
| `.tool-versions` | asdf-managed tool versions |

## Extraction Rules

1. **Language line**: pick one primary language (the one the entry points use).
   If multiple coexist (e.g. TS + a Python script), primary = highest-count source extension.
2. **Runtime version**: prefer lock / engines field > Dockerfile base image > CI config.
3. **Framework**: pick the top 1–2 by dependency centrality (used in entry points).
4. **Database / cache / MQ**: extract from docker-compose services and/or explicit driver
   dependencies (e.g. `pg`, `mysql2`, `redis`, `amqplib`).
5. Skip dev-only dependencies unless they define the build contract (e.g. `typescript`).

## Section Template

```markdown
## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | <e.g. TypeScript 5.x> [high] |
| Runtime | <e.g. Node.js 20 LTS> [high] |
| Framework | <e.g. Express 4 + Zod validation> [medium] |
| Database | <e.g. PostgreSQL 15> [high] |
| Cache | <e.g. Redis 7> [high] |
| Message queue | <e.g. RabbitMQ 3.12> [medium] |
| Infrastructure | <e.g. Docker Compose (dev), Kubernetes (prod-inferred)> [inferred] |
| Key libraries | <notable domain libraries> [medium] |
```

Omit rows that produce no evidence. Do not fabricate.

## Confidence Tags

- `[high]` — declared in an authoritative config file (package.json engines, pom.xml,
  go.mod toolchain, Dockerfile FROM)
- `[medium]` — inferred from lock file version or dependency presence (not pinned)
- `[low]` — mentioned in README but not verified by config
- `[inferred]` — guessed from directory layout or file presence (e.g. Kubernetes inferred
  from existence of `k8s/` dir without any manifest read)
