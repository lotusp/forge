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

`core/entry-points` gives a 3–5 example overview across all entry point kinds
(HTTP / CLI / Jobs / Events). This profile goes deeper **only for HTTP**:
discovers route mechanisms, groups code-verified routes, and records response
shape only when it is directly evidenced.

Load this profile when the project exposes HTTP endpoints. Do not assume REST,
resource naming, versioning, authentication, OpenAPI, or a global response
envelope unless the current codebase proves it.

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
- global exception handlers, middleware, interceptors, serializers, or response
  DTOs when characterizing response shapes

## Extraction Rules

1. **Discover the routing mechanism first.** Use framework annotations,
   router registration calls, URL config, generated specs, or equivalent
   current-repo sources. Do not infer routes from controller/entity/file names.
2. **Join route prefixes correctly.** For frameworks with class/module/router
   prefixes, compose the full route from both parent and child declarations.
3. **Group by observed path prefixes** only after routes are discovered. Do not
   force resource-style grouping if the project uses action, RPC, webhook, or
   mixed routing.
4. **Counts require reproducible evidence.** If the scan is sampled, say
   "representative routes" and omit total counts.

   **Mandatory detector invocation (Java/Spring stack only).** Before
   writing any controller-count or route-count number, you MUST invoke
   the `rest_controllers` and `spring_mappings` detectors and use their
   `result` fields verbatim:

   ```bash
   ROOT=$(find "$TARGET" -maxdepth 4 -type d -name java | head -1)
   CONTROLLERS=$(scripts/detectors/rest_controllers.sh "$ROOT" | jq .result)
   MAPPINGS=$(scripts/detectors/spring_mappings.sh "$ROOT" | jq .result)
   ```

   Then anchor each number with an `<!-- ev:id=routes_total -->` /
   `<!-- ev:id=controllers_count -->` evidence comment per Step 6.0 (so
   check5 can verify it). The id MUST match `[a-z0-9_]+` — use
   underscores, not hyphens. Eyeballed estimates
   like "approximately N controllers" or "371 mappings" without
   detector evidence are now treated as unanchored claims by check5b
   (warning) and as fact-mismatches by future fact-check passes
   (hard halt). A prior real-world review found a project claiming
   `371` mappings when the detector reports `3957` (≈10× off) — that
   is exactly the failure this rule prevents.
5. **Version scheme** — record URL/header/media-type/custom versioning only if
   directly evidenced.
6. **Response envelope** — read actual response types, middleware, serializers,
   or exception handlers. Do not generalize from one helper class.
7. **Authentication / authorization** — mention only the observed mechanism
   or link to `integration/auth`; avoid claiming all routes are protected unless
   the scan verified global enforcement.
8. **OpenAPI / Swagger** — distinguish source specs, generated specs, and UI
   routes. Do not infer UI paths from library defaults when config overrides
   may exist.

## Section Template

```markdown
## HTTP API Surface

- **Routing mechanism:** <framework annotations / router registrations / URL
  config / OpenAPI spec> [high] [code]
- **Base prefixes:** `<observed-prefixes>` [medium] [code]
- **Versioning:** <observed scheme, or omit if absent> [medium] [code]
- **Route inventory:** <exact count with reproducible scan, or
  "representative sample"> [medium] [code]
- **Response shape:** <directly evidenced success/error shape, or omit>
  [medium] [code]
- **Auth:** <observed middleware/filter/guard/interceptor, or see
  `integration/auth`> [medium] [code]

### Route Groups

| Group | Routes | Visibility |
|-------|--------|-----------|
| `/orders` | <exact or sampled routes discovered from code> | <observed or omit> [medium] |
| `/customers` | <exact or sampled routes discovered from code> | <observed or omit> [medium] |
| `/webhooks` | <exact or sampled routes discovered from code> | <observed or omit> [medium] |

### OpenAPI

- Spec file: `<path>` [high] [code]
- Documentation UI: `<path from config or code>` [medium] [config]
```

## Confidence Tags

- `[high]` — route/path/shape directly verified from source or authoritative spec with no conflict
- `[medium]` — route group or response shape sampled or partially verified
- `[low]` — route mentioned in docs but not matched in source
- `[inferred]` — avoid
