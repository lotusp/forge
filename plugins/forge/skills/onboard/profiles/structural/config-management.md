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

# Profile: Configuration Sources and Conflicts

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

**Conflict sources:**

- README / docs / parent guidance mentioning ports, profiles, config files, or
  template-copy steps
- build manifests and runtime config files that select profiles or load config
- missing files referenced by docs

## Extraction Rules

1. **Current-repo config files are primary evidence.** Build manifests and
   runtime config files outrank README, parent docs, and external guidance.
2. **List config categories, not every variable** — group by concern (database,
   cache, external services, feature flags, logging, security).
3. **Count only when reproducible.** Required vs optional counts must come from
   schema validation, config examples, or direct default-value inspection.
4. **Per-environment files** — record only files that exist.
5. **Secret management** — state how secrets are injected only when directly
   evidenced by dependencies/config/manifests.
6. **Detect conflicts.** If docs mention files, ports, profiles, loaders, or
   setup steps that differ from current config/build files, mark `[conflict]`
   or move the doc-only item to notes.
7. **Never emit setup commands or template-copy instructions** (R17). If a
   referenced template file is absent, report it as a config-source conflict,
   not as an instruction.
8. **Do not leak real credential names** that match external system naming
   (follow C8).

## Section Template

```markdown
## Configuration Sources and Conflicts

- **Primary config files:** `<path list observed in current repo>` [high] [config]
- **Config loader:** `<loader/framework mechanism observed in dependencies/code>`
  [medium] [build]
- **Environment selection:** `<profile/env selection mechanism observed in current
  repo>` [medium] [config]
- **Secret injection:** `<observed secret source, or omit if not evidenced>`
  [medium] [config]

### Conflicts / Stale Guidance

- `<doc source>` mentions `<config fact>`, but `<current config/build source>`
  shows `<conflicting fact>` [medium] [readme] [conflict]
```

## Confidence Tags

- `[high]` — current-repo config/build file read and no conflicting source found
- `[medium]` — source exists but is partial, sampled, or conflicts with another source
- `[low]` — config pattern mentioned in README, no file inspection
- `[inferred]` — avoid
