---
name: auth
section: Authentication & Authorization
applies-to:
  - web-backend
  - web-frontend
  - monorepo
confidence-signals:
  - auth library in deps (passport / jsonwebtoken / nextauth / spring-security / auth-starter)
  - middleware / filter files with "auth" in name
  - /auth/* routes in HTTP API
  - X-User-Auth or similar gateway-injected header references
must-grep:
  - 'request\.getHeader\("[^"]+"\)|@RequestHeader\("[^"]+"\)'
  - '@PreAuthorize|@Secured|@RolesAllowed'
  - 'TtlExecutors|TransmittableThreadLocal'
token-budget: 1100
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
| `auth-starter` (custom) | Gateway-decoded JWT (header-based) |
| `express-session` / `cookie-session` | session-based |
| `oauth2-server` / `oidc-provider` | self-hosted OAuth |

**Middleware / filter signals:**

- files matching `**/auth*middleware*` / `**/middleware/auth*`
- Spring `GenericFilterBean` / `OncePerRequestFilter` subclasses
- decorators: `@Authenticated`, `@RequireRole`, `@Protected`
- Spring annotations: `@PreAuthorize`, `@Secured`, `@RolesAllowed`

**Token / session transport:**

- cookies (name extracted from `cookieName:` / `cookie.name`)
- redis session store (grep `connect-redis` / `redis-store`)
- DB-backed sessions (`sessions` table)
- gateway-injected headers (e.g. `X-User-Auth`, `X-User-Token`)

**Async context propagation (Java/Spring specific):**

- `com.alibaba:transmittable-thread-local` in deps
- `@Async` / `@EnableAsync` / custom `Executor` beans
- `TtlExecutors.getTtlExecutor()` wrapping (correct usage)
- raw `ThreadPoolTaskExecutor` / `Executors.newFixedThreadPool` (potential foot-gun)

## Extraction Rules

1. **Four-axis structure (mandatory).** Render the section as four
   sub-headings (Inbound / Outbound / Gateway / Token refresh) so a
   reader can locate any one axis quickly. Do NOT collapse into a flat
   bullet list — different services have very different shapes per axis.

2. **Header names are extracted LITERALLY.** When the service receives
   a JWT/auth context via HTTP header, the header name MUST be quoted
   verbatim from code via grep:
   - Spring: `request.getHeader("...")` / `@RequestHeader("...")`
   - Express: `req.headers["..."]` / `req.get("...")`

   ✅ Correct: "JWT via custom `X-User-Auth` header (gateway-decoded)"
   ❌ Wrong:   "JWT bearer token" — implies `Authorization: Bearer`
              when the actual transport is a custom header.

   This rule exists because v0.5.1 review of three SVC services found
   the auth section claiming "JWT bearer tokens" while the real
   transport was a `X-User-Auth` custom header injected by the upstream
   gateway. Grepping the codebase prevents this misleading paraphrase.

3. **Do not leak identity-provider hostnames.** R17 redactor will catch
   internal hosts; this profile additionally avoids tenant URLs in
   prose. Say "OIDC via external IdP" rather than naming the tenant.

4. **RBAC model shape.** Role list if documented (cap at ~8 roles);
   else describe shape ("permissions on user record", "role table
   join", "scopes from IdP claims"). For very large role enumerations
   (Java `RolePrivilege.java` with 100+ ROLE_* constants), surface the
   count via the `role_constants` detector and add a note about
   privilege bloat to the artifact `Notes` section instead of dumping
   the list here.

5. **Async context propagation (Java foot-gun).** When the project
   uses `TransmittableThreadLocal` (TTL) for user-context propagation,
   surface a clear warning under "Async Context Propagation" sub-section.
   Any new `@Async` method or custom `Executor` MUST be wrapped via
   `TtlExecutors.getTtlExecutor(...)`; raw `ThreadPoolTaskExecutor` will
   silently drop the user context, producing wrong-user authorization
   decisions in async paths. Count wrapped vs raw Executors via grep so
   readers see the current ratio.

6. **MFA / 2FA** — state if present.

7. **Public vs authenticated routes** — rough ratio if extractable from
   middleware coverage. For BFF / gateway-fronted services, explicitly
   note when the service trusts upstream gateway auth and does not
   re-validate.

## Section Template

```markdown
## Authentication & Authorization

### Inbound caller auth

- **Method:** <one-line description; e.g. JWT via custom X-User-Auth header (gateway-decoded), or "no inbound auth filter — trust delegated to upstream"> [high] [code]
- **Filter / middleware:** <class name + path> [high] [code]
- **Public routes:** <list of permitted prefixes; e.g. `/api/sales-website/**`, `/actuator/**`> [high] [code]

### Outbound service auth

- **Per downstream:** <list each downstream + its token mechanism>
  - `account-management` — Feign + JWT propagation [high] [code]
  - `peer-svc-a` — OAuth2 password-grant; token cached in-memory [high] [code]

### Gateway-trusted headers

- **Header name:** `X-User-Auth` (literal) [high] [code]
- **Validation in this service:** <none — gateway is trusted | header signature verified> [high] [code]
- **Risk note (if applicable):** "/api/sales-website/** is permitted in the BFF security config; the BFF imposes no auth gate on that prefix" [high] [code]

### Token refresh mechanics (only if applicable)

- **Trigger:** <ApplicationReadyEvent + TokenRefreshEvent | scheduled cron | on 401 reactive | n/a> [high] [code]
- **Cache:** <in-memory | redis | none> [confidence] [code]

### RBAC

- **Model:** <role list / scope flags / permissions> [confidence]
- **Enforcement:** <`@PreAuthorize` / role checker class / per-route guard> [high] [code]

### Async Context Propagation (Java only — present when TTL is in deps)

- Library: `com.alibaba:transmittable-thread-local` [high] [build]
- Wrapped Executors: <count from grep `TtlExecutors`> [medium] [cli]
- Unwrapped Executors: <count from grep `new ThreadPoolTaskExecutor`> [medium] [cli]
- ⚠️ Any new `@Async` method or custom `Executor` MUST be wrapped via
  `TtlExecutors.getTtlExecutor(...)`. Raw executors silently drop the
  user context, leading to wrong-user authorization decisions. [high] [code]

### MFA / 2FA

- <e.g. "TOTP optional for admin role; required by policy (not enforced in code)" | "none observed"> [confidence]
```

## Confidence Tags

- `[high]` — library + filter + route coverage + literal header name all verified
- `[medium]` — library identified without exhaustive coverage check, or async exec ratio sampled
- `[low]` — mentioned in README only
- `[inferred]` — avoid; auth claims affect security posture and need direct evidence
