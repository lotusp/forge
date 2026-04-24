---
name: config-management
section: Configuration
applies-to:
  - web-backend
  - web-frontend
  - monorepo
confidence-signals:
  - .env.example / .env.sample present
  - config/ directory with per-environment files
  - application.yml / application.properties (Spring)
  - config loader library in dependencies (dotenv / viper / config-rs / etc.)
token-budget: 900
---

# Profile: Configuration

## Scan Patterns

**Environment variable sources:**

- `.env.example` / `.env.sample` / `.env.template` — variable catalogue
- `docker-compose.yml` `environment:` blocks
- Kubernetes manifests `env:` / `envFrom:` under containers
- Helm values files

**Config file formats:**

| Glob | Framework convention |
|------|---------------------|
| `config/*.{js,ts,json,yaml}` | Node convention |
| `application.yml` / `application-{env}.yml` | Spring Boot |
| `appsettings.json` / `appsettings.{env}.json` | .NET |
| `settings.py` / `settings/{env}.py` | Django |
| `config.toml` / `config/{env}.toml` | Rust / Go convention |

**Config loader libraries (grep deps):**

- Node: `dotenv`, `@nestjs/config`, `convict`
- Go: `viper`, `envconfig`
- Python: `pydantic-settings`, `dynaconf`
- JVM: Spring `@Value` / `@ConfigurationProperties`

**Secret management signals:**

- `vault`, `aws-sdk-ssm`, `sops`, `doppler`, `1password` in deps
- `.sops.yaml` / `secrets.enc.yaml`

## Extraction Rules

1. **List env var categories, not every variable** — group by concern (DB / cache /
   external services / feature flags).
2. **Count required vs optional** — a required env var has no default in `.env.example`.
3. **Per-environment file count** — if `application-{dev,staging,prod}.yml` pattern
   exists, note it.
4. **Secret management** — state how secrets are injected (CI env / vault / bundled).
5. **Do not leak real credential names** that match external system naming (follow C8).

## Section Template

```markdown
## Configuration

- **Env variable catalogue:** `.env.example` defines ~24 variables grouped into:
  DB (5), cache (2), external APIs (6), feature flags (8), logging (3) [high]
- **Config loader:** `@nestjs/config` with Zod schema validation at startup [high]
- **Per-environment config:** `config/{development,test,production}.ts`, selected by
  `NODE_ENV` [high]
- **Secret injection:** local via `.env` (gitignored); CI via GitHub Actions secrets;
  prod via AWS SSM Parameter Store (path `/orders/prod/*`) [medium]
- **Required at startup:** 7 variables (app fails fast if missing) [high]
```

## Confidence Tags

- `[high]` — config file read, variable list verified
- `[medium]` — loader library identified but per-env split inferred
- `[low]` — config pattern mentioned in README, no file inspection
- `[inferred]` — avoid
