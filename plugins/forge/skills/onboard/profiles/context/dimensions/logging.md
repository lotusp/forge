---
name: logging
output-file: conventions.md
applies-to:
  - web-backend
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - grep: "(logger|log|slf4j|winston|zerolog|zap|pino)"
  - glob: "logback*.xml"
  - glob: "log4j2*.xml"
confidence-signals:
  - logging library declared in dependencies
  - structured JSON log format signals present
  - MDC / context-enrichment usage
token-budget: 800
---

# Dimension: Logging

## Scan Patterns

**Library detection:**

| Evidence | Library |
|----------|---------|
| `@Slf4j` / `Logger.getLogger` / `logback.xml` | Slf4j + Logback / Log4j2 |
| `winston.createLogger` / `pino()` | Winston / Pino (Node) |
| `log/slog` / `zerolog.New` / `zap.NewLogger` | Go stdlib slog / zerolog / zap |
| `logging.getLogger` / `structlog.get_logger` | Python logging / structlog |
| `tracing::info!` / `log!` | Rust tracing / log |

**Log level usage distribution:**
```
Grep "logger\\.(debug|info|warn|error)"
  → count per level; assess convention
```

**Structured logging signals:**
```
Grep "logger\\.info.*\\{.*:" or "WithField" or "logger.*JSON"
  → structured JSON vs plain text
```

**Context fields:**
- `requestId` / `correlationId` / `traceId` in log statements
- `userId` / `tenantId` enrichment
- MDC (`MDC.put(...)`) usage

## Extraction Rules

1. Identify **primary logger** (by import frequency)
2. Detect **output format** (structured JSON vs plain)
3. List **required context fields** observed in ≥ 70% of log statements
4. Document **level semantics** inferred from usage:
   - `error`: observed in catch blocks? → exception logging
   - `warn`: observed in validation failures? → recoverable issues
   - `info`: observed in handler entry/exit? → state transitions
   - `debug`: observed in dev-only blocks?
5. Detect conflicts: multiple loggers used in same module

## Output Template

```markdown
## Logging

**Library:** <Slf4j + Logback | Winston | zap | ...> [high] [build]

**Format:** <Structured JSON | Plain text | Hybrid> [high] [code]

**Required context fields** (include in every log statement where available):
- `<service>` — service identifier [high] [code]
- `<requestId>` — propagated from request header [high] [code]
- `<userId>` — when available [medium] [code]
- `<tenantId>` — when available [medium] [code]

**Level semantics:**
- `error`: <when to use — e.g. "caught exceptions that require
  intervention"> [high] [code]
- `warn`: <when to use — e.g. "expected failures, recoverable"> [high] [code]
- `info`: <when to use — e.g. "significant state changes, handler
  boundaries"> [high] [code]
- `debug`: <when to use — e.g. "development-only tracing, disabled in
  prod"> [medium] [code]

**What to avoid:**
- `console.log` / `println` in production code paths
- Logging full request bodies (PII risk)
- Logging stack traces at `info` level
- Silencing errors via `.catch(() => {})`
```

## Confidence Tags

- `[high]` — library imported in ≥ 80% service files; config file present
- `[medium]` — library in deps but usage inconsistent
- `[low]` — inferred from a single config file; no consistent usage
- `[inferred]` — framework default assumed; no observed usage
