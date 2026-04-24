---
name: auth
section: Authentication & Authorization
applies-to:
  - web-backend
  - web-frontend
  - monorepo
confidence-signals:
  - auth library in deps (passport / jsonwebtoken / nextauth / spring-security)
  - middleware files with "auth" in name
  - /auth/* routes in HTTP API
token-budget: 900
---

# Profile: Authentication & Authorization

## Scan Patterns

**Library detection:**

| Evidence | Strategy |
|----------|----------|
| `jsonwebtoken` / `jose` dep | JWT |
| `passport` + strategies | Passport (strategy dependent) |
| `next-auth` / `@auth/*` | NextAuth / Auth.js |
| `@clerk/*` | Clerk |
| `@auth0/*` | Auth0 |
| `firebase-admin` auth methods | Firebase Auth |
| `spring-security-*` | Spring Security |
| `express-session` / `cookie-session` | session-based |
| `oauth2-server` / `oidc-provider` | self-hosted OAuth |

**Middleware signals:**

- files matching `**/auth*middleware*` / `**/middleware/auth*`
- decorators: `@Authenticated`, `@RequireRole`, `@Protected`

**Token / session storage:**

- cookies (name extracted from `cookieName:` / `cookie.name`)
- redis session store (grep `connect-redis` / `redis-store`)
- DB-backed sessions (`sessions` table)

## Extraction Rules

1. **One line per dimension** — auth method / session transport / refresh strategy /
   RBAC model.
2. **Do not leak specific identity provider URLs** — say "OIDC via external IdP" rather
   than naming the tenant.
3. **RBAC model** — role list if documented (cap at ~8 roles); else describe shape
   ("permissions on user record", "role table join", "scopes from IdP claims").
4. **MFA / 2FA** — state if present.
5. **Public vs authed routes** — rough ratio if extractable from middleware coverage.

## Section Template

```markdown
## Authentication & Authorization

- **Auth method:** JWT bearer (HS256) issued on `/auth/login`; refresh via HttpOnly
  rotating cookie [high]
- **Session transport:** HttpOnly `Secure` cookie `orders_sid` (refresh token) + Bearer
  header (access token) [high]
- **Access token lifetime:** 15 minutes; refresh token 7 days with rotation [high]
- **Middleware:** `authMiddleware` (`src/middleware/auth.ts`) enforced on all `/api/*`
  except `/auth/login`, `/auth/register`, `/webhooks/*` [high]
- **RBAC:** role field on `users` table — `customer`, `operator`, `admin`; per-route
  guard via `requireRole(...)` helper [high]
- **MFA:** TOTP optional for `admin` role; required by policy (not enforced in code) [medium]
- **External IdP:** OIDC bridge for SSO login (provider URL redacted per C8) [medium]
```

## Confidence Tags

- `[high]` — library + middleware + route coverage all verified
- `[medium]` — library identified without exhaustive coverage check
- `[low]` — mentioned in README only
- `[inferred]` — avoid
