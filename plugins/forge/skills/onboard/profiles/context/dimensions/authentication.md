---
name: authentication
output-file: conventions.md
applies-to:
  - web-backend
  - web-frontend
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - grep: "(passport|jsonwebtoken|spring-security|oauth|@Authenticated|RequireRole)"
  - glob: "**/middleware/auth*"
  - glob: "**/guards/**"
confidence-signals:
  - auth library in dependencies
  - auth middleware covers /api/* routes
  - role / permission model visible
token-budget: 900
---

# Dimension: Authentication & Authorization

## Scan Patterns

**Library detection:**

| Evidence | Strategy |
|----------|----------|
| `jsonwebtoken` / `jose` | JWT |
| `passport` + strategy plugins | Passport (strategy dependent) |
| `@next-auth/*` / `@auth/*` | Auth.js / NextAuth |
| `@clerk/*` | Clerk |
| `@auth0/*` | Auth0 |
| `firebase-admin` | Firebase Auth |
| `spring-security` | Spring Security |
| `express-session` / `cookie-session` | Session-based (Node) |
| `oauth2-server` / `oidc-provider` | Self-hosted OAuth2 / OIDC |

**Middleware / guard identification:**
```
Glob "**/middleware/auth*" / "**/guards/*Auth*" / "**/interceptors/*Auth*"
```

**Token storage:**
- Cookies: grep for `cookieName:` / `cookie: { name: ` / `Set-Cookie`
- Redis session store: `connect-redis` / `redis-store`
- DB-backed: `sessions` table

**Role / permission model:**
```
Grep "@RequireRole" / "hasRole" / "permissions:" / "scopes:" / "roles:"
Read a representative handler using auth to infer RBAC/ABAC model
```

## Extraction Rules

1. Identify **auth strategy** (JWT / session / external OIDC / hybrid /
   gateway-trusted header)
2. Document **token transport** with LITERAL header / cookie name —
   extract via grep of `request.getHeader("...")` / `req.headers["..."]` /
   `@RequestHeader("...")`. Do NOT paraphrase as "JWT bearer" when the
   real transport is a custom header (v0.5.1 review caught three SVC
   services doing exactly this).
3. Document **middleware coverage** (which routes are authed, which are
   public)
4. Document **role / permission model**
5. Detect **MFA / 2FA** usage if present
6. Document **external IdP** presence (with C8 redaction — do NOT leak
   provider tenant URLs; say "OIDC via external IdP")
7. **Async-context-propagation guidance** (Java/Spring only). When the
   onboard.md `Authentication` section flagged
   `transmittable-thread-local` (TTL) usage, this conventions.md
   section MUST also surface a "do not unwrap TTL" rule under
   "Convention for new endpoints" so future maintainers see the rule
   in both files.

> **Stage-2 ↔ Stage-3 sync note (v7 R1):** This dimension MUST stay in
> step with `profiles/integration/auth.md` (the onboard.md side).
> Whenever the Stage-2 profile's section template changes (e.g. a new
> sub-axis is added), reflect the same vocabulary here so the `auth`
> entries in `onboard.md` and the `conventions.md` Authentication
> section do not contradict each other.

## Output Template

```markdown
## Authentication & Authorization

**Method:** <JWT bearer | Session cookie | JWT + rotating refresh cookie |
gateway-decoded JWT via custom header | ...>
[high] [code]

**Token transport (literal — no paraphrase):**
- Access token: e.g. `Authorization: Bearer <jwt>` OR custom header
  `X-User-Auth` (gateway-decoded). Extract verbatim; never substitute a
  generic "Bearer token" phrasing when the actual transport differs.
  [high] [code]
- Refresh token (when applicable): HttpOnly Secure cookie `<name>`
  (SameSite=Lax) [high] [code]

**Token lifetime:**
- Access: `<N minutes>` [high] [code]
- Refresh: `<N days>` + rotation on use [high] [code]

**Middleware:**
- Enforcement point: `<src/middleware/auth.ts:NN>` [high] [code]
- Applied to: all `/api/*` routes [high] [code]
- Public exceptions: `/api/auth/*`, `/api/webhooks/*`, `/api/health` [high] [code]

**Authorization model:**
- Role-based via `users.role` column; values: `<customer | operator |
  admin>` [high] [code]
- Per-route guard: `requireRole(...)` helper [high] [code]
- Fine-grained permissions: <none | via `permissions:` JSONB column |
  via external policy service> [medium] [code]

**MFA:**
- <Not enforced | TOTP optional for admin role | Required for all users>
  [medium] [code]

**External IdP (if any):**
- OIDC bridge for SSO (provider host redacted per C8) [medium] [code]

### Convention for new endpoints

- By default, all new `/api/*` routes require authentication (middleware
  catches them) [high] [code]
- If public, add the route to the public-exception list explicitly
  [high] [code]
- Per-role access: use `requireRole('admin')` wrapper, not inline role
  checks inside handlers [high] [code]

### What to avoid

- Storing access tokens in `localStorage` (XSS risk); always HttpOnly
  cookie for refresh, memory for access
- Hardcoding role strings across handlers; use a central enum
- Bypassing middleware with `app.use` path-specific skips that drift
  from documentation
- Leaking external IdP tenant URLs / client IDs in docs (C8)
- Paraphrasing custom auth header as `Authorization: Bearer ...` —
  the actual header name MUST appear verbatim in this section
- (Java/Spring) Wrapping `@Async` methods or custom `Executor` beans
  WITHOUT `TtlExecutors.getTtlExecutor()` when the project relies on
  `transmittable-thread-local` for user-context propagation. Raw
  executors silently drop the user identity and produce wrong-user
  authorization decisions. (See onboard.md "Async Context Propagation"
  for the wrapped/unwrapped Executor count.)
```

## Confidence Tags

- `[high]` — auth library in deps AND middleware covers the majority of routes
- `[medium]` — auth library in deps but coverage partial
- `[low]` — auth partially implemented; some routes unprotected
- `[inferred]` — strategy inferred from framework default without observing enforcement
