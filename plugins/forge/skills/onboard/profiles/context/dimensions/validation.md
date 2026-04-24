---
name: validation
output-file: conventions.md
applies-to:
  - web-backend
  - web-frontend
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - grep: "(zod|joi|yup|class-validator|ajv|validator|@Valid|pydantic)"
  - glob: "**/dto/**"
  - glob: "**/schemas/**"
confidence-signals:
  - validation library in dependencies
  - DTO / schema files present
  - @Valid / validation decorators in route handlers
token-budget: 700
---

# Dimension: Input Validation

## Scan Patterns

**Library detection:**

| Evidence | Library |
|----------|---------|
| `import { z } from "zod"` | Zod |
| `Joi.object({` | Joi |
| `@IsString() / @IsEmail()` | class-validator |
| `@Valid` + `@NotBlank` | Spring Bean Validation |
| `class X(BaseModel):` | Pydantic |
| `validator.IsEmail` + struct tags | Go validator |

**Validation location (architectural question):**
```
Grep for validation calls at:
  - route handler entry (controller / handler layer)
  - middleware (pre-handler pipeline)
  - service entry boundary
```

**Error response format:**
```
Read a handful of handler error paths to see what gets returned to client:
  - { error: { code, message, fields } } ?
  - RFC 7807 Problem Details ?
  - Plain string / legacy format ?
```

## Extraction Rules

1. Identify **primary validation library**
2. Identify **validation location** (route / middleware / service) —
   this is a conventions-level decision, not just a library choice
3. Document **error response format** by sampling 3+ failure paths
4. Note whether validation schemas are **co-located** with DTOs or
   centralized in `schemas/` / `validators/`
5. Detect conflict: some handlers validate at route, others at service

## Output Template

```markdown
## Input Validation

**Library:** <Zod | Joi | class-validator | Spring Bean Validation | ...>
[high] [build]

**Location:** <route handler | middleware | service boundary>
[high] [code]

**Schema organization:** <co-located with DTO / centralized in schemas/>
[high] [code]

**Error response format:**

\`\`\`json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "fields": [
      { "path": "email", "message": "must be a valid email" },
      { "path": "quantity", "message": "must be >= 1" }
    ]
  }
}
\`\`\`

[high] [code]

**Convention for new endpoints:**
- Define Zod / Joi / ... schema next to the handler [high] [code]
- Parse/validate at <location> before business logic [high] [code]
- Never validate inside business logic / services [high] [code]

**What to avoid:**
- Ad-hoc `if (x == null)` checks scattered in service code
- Silent type coercion (`+req.body.amount`) without schema
- Custom validation strings that deviate from the shared error shape
```

## Confidence Tags

- `[high]` — library present in deps AND used in ≥ 5 endpoints consistently
- `[medium]` — library in deps but usage inconsistent across handlers
- `[low]` — only seen in 1–2 endpoints; rest of codebase lacks validation
- `[inferred]` — framework default assumed
