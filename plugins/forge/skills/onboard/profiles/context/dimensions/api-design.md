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
  - Base prefixes actually present
  - Route shapes actually present
  - Whether routing is resource-style, action-style, RPC-style, webhook-style,
    generated from specs, or mixed
```

**HTTP verb usage:**
```
Count GET / POST / PUT / PATCH / DELETE per observed route group
  → detect local patterns only when repeated
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

1. Extract **base prefixes + versioning strategy** only when evidenced.
2. Document **HTTP verb usage** as observed local patterns, not REST rules.
3. Capture **response envelope shape** with literal examples only after reading
   response types, middleware, serializers, exception handlers, or specs.
4. List **status code patterns** only when directly observed.
5. Document **pagination strategy** (page / offset / cursor / custom) only when
   observed.
6. Note any **HATEOAS / hypermedia** conventions if present.
7. Detect conflicts (e.g. some endpoints return bare resource,
   others wrapped)
8. Do not classify mixed API behavior as wrong unless the current repo has a
   local rule forbidding it. Mixed behavior may be an observed risk.

## Output Template

```markdown
## API Design

**Base URL:** `<e.g. /api/v1>` [high] [code]

**Versioning:** <URL-based | Header-based | media-type | custom | none observed>
[medium] [code]

### URL structure

\`\`\`
GET    /orders                — observed handler purpose [medium] [code]
POST   /orders/actions/cancel — observed handler purpose [medium] [code]
POST   /webhooks/payments     — observed handler purpose [medium] [code]
\`\`\`

Observed route shape: <resource-style / action-style / webhook-style / mixed>
[medium] [code]

### Verb Usage

- `<verb>`: <local usage pattern observed across handlers> [medium] [code]

### Response envelope

Success:

\`\`\`json
{
  "data": { /* observed payload shape */ }
}
\`\`\`

Error:

\`\`\`json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Order not found",
    "details": { /* optional */ }
  }
}
\`\`\`

[high] [code]

### Status Code Patterns

- `<status>` — <observed use in handlers or exception mapping> [medium] [code]

### Pagination

<Cursor-based | Offset-based | Page-based | custom | none observed>
[medium] [code]

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

### Observed Risks / Inconsistencies

- <mixed response/status/pagination behavior observed in current repo; reference
  only unless a local rule enforces consistency> [medium] [code]
```

## Confidence Tags

- `[high]` — authoritative spec or exhaustive source scan verifies the pattern with no conflict
- `[medium]` — pattern observed in sampled handlers or conflicts with another source
- `[low]` — pattern visible in 1–2 handlers or docs only
- `[inferred]` — framework default assumed; avoid in final output
