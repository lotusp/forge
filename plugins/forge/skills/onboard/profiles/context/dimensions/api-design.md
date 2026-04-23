---
name: api-design
output-file: conventions.md
applies-to:
  - web-backend
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - glob: "openapi.{yaml,json}" 
  - glob: "**/controllers/**"
  - grep: "(@GetMapping|@PostMapping|app\\.get|router\\.get|gin\\.GET|app_.route)"
confidence-signals:
  - OpenAPI spec present
  - consistent URL structure across route definitions
  - standard response envelope used in ≥ 3 endpoints
token-budget: 1000
---

# Dimension: API Design

## Scan Patterns

**URL structure survey:**
```
Enumerate registered routes (from core/entry-points profile if available):
  - Base prefix: /api, /api/v1, / ?
  - Resource collection pattern: /<resource>, /<resource>/<id>
  - Sub-resource pattern: /<resource>/<id>/<sub>
```

**HTTP verb usage:**
```
Count GET / POST / PUT / PATCH / DELETE per resource
  → detect conventions (e.g. "always PATCH for partial updates, never PUT")
```

**Response envelope:**
```
Sample 3+ successful handlers and 3+ error handlers:
  - Wrapped in `{ data, meta }` ?
  - Wrapped in `{ success, data }` / `{ success, error }` ?
  - Bare resource / bare error ?
  - RFC 7807 Problem Details ?
```

**Status code patterns:**
```
Grep response status usage:
  - 201 for resource creation?
  - 204 for successful delete?
  - 409 for conflict?
  - 422 vs 400 for validation?
```

**Pagination:**
```
Grep query param usage: ?page= / ?offset= / ?cursor=
  → identify strategy
```

## Extraction Rules

1. Extract **base URL + versioning strategy**
2. Document **HTTP verb semantics** per convention
3. Capture **response envelope shape** with literal examples
4. List **status code map** (success + common errors)
5. Document **pagination strategy** (page / offset / cursor)
6. Note any **HATEOAS / hypermedia** conventions if present
7. Detect conflicts (e.g. some endpoints return bare resource,
   others wrapped)

## Output Template

```markdown
## API Design

**Base URL:** `<e.g. /api/v1>` [high] [code]

**Versioning:** <URL-based | Header-based | None> [high] [code]

### URL structure

\`\`\`
GET    /<resource>            — list (paginated)
GET    /<resource>/<id>       — detail
POST   /<resource>            — create
PATCH  /<resource>/<id>       — partial update
DELETE /<resource>/<id>       — delete
\`\`\`

Sub-resources nested up to one level:
`/<parent>/<id>/<child>` [high] [code]

### Verb semantics

- `POST`: resource creation; returns 201 with body [high] [code]
- `PATCH`: partial update; never `PUT` for partial [high] [code]
- `DELETE`: returns 204 (no body) [high] [code]

### Response envelope

Success:

\`\`\`json
{
  "data": { /* resource or list */ },
  "meta": { "page": 1, "pageSize": 20, "total": 137 }
}
\`\`\`

Error:

\`\`\`json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Order abc-123 not found",
    "details": { /* optional */ }
  }
}
\`\`\`

[high] [code]

### Status codes

- `200` — successful GET / PATCH [high] [code]
- `201` — successful POST (creation) [high] [code]
- `204` — successful DELETE [high] [code]
- `400` — malformed request [high] [code]
- `401` — missing / invalid auth [high] [code]
- `403` — authenticated but not authorized [high] [code]
- `404` — resource not found [high] [code]
- `409` — conflict (duplicate, version mismatch) [high] [code]
- `422` — semantic validation failure [medium] [code]
- `500` — unhandled server error [high] [code]

### Pagination

<Cursor-based | Offset-based | Page-based> [high] [code]

Example:
\`\`\`
GET /orders?cursor=eyJpZCI6NzN9&limit=20
→
{ "data": [...], "meta": { "nextCursor": "eyJpZCI6OTN9", "hasMore": true } }
\`\`\`

### OpenAPI

- Spec file: `<path, if present>` [high] [build]
- Serving: `<url path for Swagger UI, if any>` [medium] [code]
- Generation: <auto from decorators | hand-written> [medium] [code]

### What to avoid

- Mixing envelope shapes across endpoints (some wrapped, some bare)
- Using 200 for everything (lose semantic HTTP status)
- Embedding business errors in HTTP 200 with `{ success: false }`
- Leaking DB column names directly as JSON field names without mapping
```

## Confidence Tags

- `[high]` — OpenAPI spec present OR ≥ 5 endpoints demonstrate the same pattern
- `[medium]` — pattern inferred from 3–4 endpoints without spec
- `[low]` — pattern visible in 1–2 endpoints only
- `[inferred]` — pattern not observed; framework default assumed
