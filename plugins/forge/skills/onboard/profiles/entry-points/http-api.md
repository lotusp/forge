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
4. **No precise counts. Cite examples + size word (v0.6).** Read
   `.forge/_session/facts.json` (produced by Stage 1.5c). For each
   detected inventory, the LLM MUST:

   - quote 3–5 of the `samples` directly as concrete examples
     (real `file:line` and the matching snippet)
   - render the scale with the size word matching `inferred_size`
     (`tiny`→a handful of, `small`→a few, `medium`→several,
     `large`→many, `very-large`→a large set of)
   - anchor the qualitative claim with `<!-- ev:id=<fact-id> -->`
     where `<fact-id>` is one of `rest_controllers` / `spring_mappings`

   Example (good):

   ```markdown
   - **Route inventory:** <!-- ev:id=rest_controllers --> many
     `@RestController` files. Examples:
     - `order/api/OrderController.java:214`
     - `inventory/api/StockController.java:30`
     - `billing/api/InvoiceController.java:42`
   ```

   Example (bad — will be stripped by check7 or warned by check5b):

   ```markdown
   - 73 controllers exposing routes
   - approximately 371 mapping annotations
   ```

   The v0.5.x policy of "use the detector's `result` number verbatim"
   was abandoned because counts can't be reliably produced by the
   LLM+script combo. Sample citations are more useful for
   understanding the codebase, and the qualitative size word is
   always correct.
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
