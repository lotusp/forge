---
name: http-api
section: HTTP API Surface
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - route definitions (Express / Fastify / Spring / Gin / FastAPI / etc.)
  - OpenAPI / Swagger spec file
  - API documentation under docs/
token-budget: 1200
---

# Profile: HTTP API Surface

## Relationship to `core/entry-points`

`core/entry-points` gives a 3–5 example overview across all entry point kinds (HTTP / CLI
/ Jobs / Events). This profile goes deeper **only for HTTP**: groups routes by resource,
extracts API versioning, and characterizes response envelope.

Load this profile when the project's primary value is its HTTP API.

## Scan Patterns

**Multi-framework route discovery:**

### Node.js
- Express: `router\.(get|post|put|patch|delete)\(` → method + path
- Fastify: `fastify\.route\(\s*\{` blocks → method + url
- Koa / Hono: similar router patterns
- NestJS: `@(Get|Post|Put|Patch|Delete)\(` decorators

### JVM
- Spring: `@(Get|Post|Put|Patch|Delete|Request)Mapping` / `@RestController`
- Micronaut: same decorator family
- Javalin: `app\.(get|post|...)` lambda registration

### Go
- Gin: `\.(GET|POST|PUT|PATCH|DELETE)\(` on `*gin.Engine` / `*gin.RouterGroup`
- Echo: `\.(GET|POST|...)` on `*echo.Echo`
- net/http: `http\.HandleFunc\(` + `mux\.Handle\(`
- Chi: `r\.(Get|Post|...)\(`

### Python
- FastAPI: `@app\.(get|post|...)\(` / `@router\.(...)`
- Flask: `@app\.route\(` / `@bp\.route\(`
- Django: `urls.py` → `path(...)` / `re_path(...)`

### Rust
- Actix: `#\[(get|post|...)\("` macros
- Axum: `Router::new\(\)\.route\(`

**Supplementary:**
- `openapi.yaml` / `swagger.json` — if present, prefer as authoritative source
- `api/` directory with OpenAPI specs

## Extraction Rules

1. **Group by resource** — `/auth/*`, `/orders/*`, `/products/*` — one group per
   top-level path segment.
2. **Count routes per group** — "12 routes" rather than listing every one.
3. **Call out public vs internal** — admin / internal / webhooks often live under
   distinct prefixes.
4. **Version scheme** — URL-based (`/v1/`, `/v2/`) / header-based / none.
5. **Response envelope** — sample one success and one error shape if discoverable.
6. **Authentication** — which middleware enforces it (brief mention; details in
   `integration/auth`).

## Section Template

```markdown
## HTTP API Surface

- **Base URL:** `/api/v1` [high]
- **Versioning:** URL-based (`/v1`, `/v2`); v1 is current, v2 in beta for orders [high]
- **Total routes:** 87 across 9 resources [high]
- **Response envelope:** `{ data: T }` success / `{ error: { code, message } }` error [high]
- **Auth:** JWT bearer via `authMiddleware` (see `integration/auth`) [high]

### Route Groups

| Group | Routes | Visibility |
|-------|--------|-----------|
| `/auth` | 4 (login, refresh, logout, verify) | public [high] |
| `/orders` | 18 (CRUD + state transitions) | authed [high] |
| `/products` | 12 (search, detail, variants) | public + authed [high] |
| `/customers` | 9 (profile, addresses) | authed [high] |
| `/admin` | 22 (back-office operations) | admin-only [medium] |
| `/webhooks` | 6 (inbound from payment / shipping providers) | signed [high] |

### OpenAPI

- Spec file: `docs/openapi.yaml` (generated from route decorators) [high]
- Swagger UI served at `/api/docs` in non-prod [medium]
```

## Confidence Tags

- `[high]` — routes verified by grep against source; counts accurate
- `[medium]` — group inferred from file layout without exhaustive count
- `[low]` — routes mentioned in README but not matched in source
- `[inferred]` — avoid
