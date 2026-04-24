---
name: third-party-apis
section: Third-Party Integrations
applies-to:
  - web-backend
  - web-frontend
  - monorepo
confidence-signals:
  - external SDK dependencies (stripe, twilio, sendgrid, etc.)
  - HTTP client usage with external URLs
  - API keys in .env.example
token-budget: 900
---

# Profile: Third-Party Integrations

## Content Hygiene Reminder

Per C8, this profile must redact specific external provider endpoints / account IDs.
Use **provider category** (Payment provider / SMS provider / Email provider) and
**well-known SDK name** (Stripe / Twilio / SendGrid — these are public product names,
allowed by C8). Do not leak custom domain names, tenant IDs, or private API hosts.

## Scan Patterns

**SDK dependencies (grep package manifests):**

| Category | Example packages (public names OK per C8) |
|----------|-------------------------------------------|
| Payment | `stripe`, `braintree`, `@paypal/*`, `razorpay` |
| SMS | `twilio`, `@aws-sdk/client-sns` |
| Email | `@sendgrid/mail`, `postmark`, `nodemailer` + SMTP |
| Storage | `@aws-sdk/client-s3`, `@google-cloud/storage`, `azure-storage-blob` |
| Search | `@elastic/elasticsearch`, `meilisearch`, `algoliasearch` |
| Feature flags | `launchdarkly-node-server-sdk`, `@growthbook/growthbook` |
| Analytics | `@segment/analytics-node`, `mixpanel`, `posthog-node` |
| Monitoring | `@sentry/*`, `newrelic`, `@datadog/*`, `opentelemetry` |
| Auth | `auth0`, `@clerk/*`, `firebase-admin` |

**HTTP client usage (fallback):**

- `axios.create\(\s*\{\s*baseURL:` — captured base URL
- `fetch\(['"`]https?://` — external fetch calls
- `http.NewRequest\(` in Go with hard-coded URLs

**Config signals:**

- `.env.example` keys like `*_API_KEY`, `*_SECRET`, `*_WEBHOOK_SECRET`

## Extraction Rules

1. **Group by category** (Payment / SMS / Email / ...).
2. **Use SDK name only** — "Stripe" not specific account or webhook URL.
3. **State integration depth** — "client calls only" / "webhook-driven" / "bidirectional".
4. **Flag credential requirements** — which integrations are blocked by missing secrets
   (affects local dev / CI).
5. **Note wrapper modules** — if project has `src/integrations/stripe/`, cite the path.
6. **Skip health checks / CDN libraries** — they're infrastructure, not integrations.

## Section Template

```markdown
## Third-Party Integrations

| Category | Provider | Depth | Wrapper module |
|----------|----------|-------|----------------|
| Payment | Stripe | webhook + client | `src/integrations/payment/` [high] |
| Email | SendGrid | client only | `src/platform/email/` [high] |
| SMS | Twilio | client only | `src/platform/sms/` [medium] |
| Storage | AWS S3 (SDK v3) | client only | `src/platform/storage/` [high] |
| Monitoring | Sentry + OpenTelemetry | instrumentation | `src/platform/telemetry/` [high] |
| Feature flags | GrowthBook | SDK eval | `src/platform/features/` [medium] |

**Credential-gated locally:** Stripe (webhook testing requires `stripe listen`),
SendGrid (no sandbox), Twilio (trial account works). [high]

**Retry / circuit breaker:** each wrapper uses `p-retry` with exponential backoff;
circuit break at 10 consecutive failures per provider. [medium]
```

## Confidence Tags

- `[high]` — SDK dep confirmed + wrapper file located
- `[medium]` — SDK present without wrapper (inline usage)
- `[low]` — mentioned in docs only
- `[inferred]` — avoid
