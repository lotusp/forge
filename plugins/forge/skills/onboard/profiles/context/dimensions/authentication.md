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

1. Identify **auth strategy** (JWT / session / external OIDC / hybrid)
2. Document **token transport** (Authorization header / HttpOnly cookie /
   both)
3. Document **middleware coverage** (which routes are authed, which are
   public)
4. Document **role / permission model**
5. Detect **MFA / 2FA** usage if present
6. Document **external IdP** presence (with C8 redaction — do NOT leak
   provider tenant URLs; say "OIDC via external IdP")

## Output Template

```markdown
## Authentication & Authorization

**Method:** <JWT bearer | Session cookie | JWT + rotating refresh cookie | ...>
[high] [code]

**Token transport:**
- Access token: `Authorization: Bearer <jwt>` [high] [code]
- Refresh token: HttpOnly Secure cookie `<name>` (SameSite=Lax) [high] [code]

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
```

## Confidence Tags

- `[high]` — auth library in deps AND middleware covers the majority of routes
- `[medium]` — auth library in deps but coverage partial
- `[low]` — auth partially implemented; some routes unprotected
- `[inferred]` — strategy inferred from framework default without observing enforcement
