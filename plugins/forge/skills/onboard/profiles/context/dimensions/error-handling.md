---
name: error-handling
output-file: conventions.md
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py,rs}"
  - glob: "plugins/*/skills/*/SKILL.md"
confidence-signals:
  - centralized error-handling middleware present
  - custom Error class hierarchy defined
  - consistent pattern across service-layer files
token-budget: 900
---

# Dimension: Error Handling

## Scan Patterns

**Service-layer error generation:**
```
"throw new [A-Z][A-Za-z]*Error"        → custom error class usage
"return \\{ success: false"             → sentinel-return pattern
"return (err|error)"                    → Go-style multi-return
"raise [A-Z][A-Za-z]*Exception"         → Python exception raise
"return Result\\.Err"                   → Rust Result pattern
```

**Central handlers:**
```
"app.use.*errorHandler"                 → Express / Koa middleware
"@ExceptionHandler"                     → Spring
"recover()"                             → Go panic recovery
"@app.exception_handler"                → FastAPI
```

**Error class hierarchy:**
```
Glob "src/**/errors/**"                 → enumerate error classes
"extends (Error|RuntimeException|...)"  → inheritance chain
```

**For claude-code-plugin kind:** scan SKILL.md for interaction-error
patterns (structured `[forge:<skill>]` halts, IRON RULE halt messages).

## Extraction Rules

1. Identify the **dominant error mode**: exception-based / sentinel-return /
   Result-type
2. Locate central handler entry points; note whether it's standardized
3. For exception-based: identify base error class and subclass convention
4. Detect conflicts if two modes coexist (batch-list; common when
   different modules use different idioms)
5. For plugin kind: identify the `[forge:<skill>] <message>` halt format
   if present

## Output Template

### Output Template — web-backend / monorepo

```markdown
## Error Handling

**Mode:** <exception-based | sentinel-return | Result-type>

<One-paragraph summary with file reference>

**Convention for new code:**
- Use `<BaseError>` or a subclass; never bare `Error` [high] [code]
- Errors caught in <handler location>; client sees standardized shape:
  `<example JSON>` [high] [code]
- Internal errors logged at `error` level; user-facing errors logged at
  `warn` [medium] [code]

**What to avoid:**
- Catching and silently dropping errors — always re-throw or log
- Mixing the non-chosen mode in new code
```

### Output Template — claude-code-plugin

```markdown
## Error Handling

**Mode:** Skill halt-and-surface

**Convention for new code:**
- Skills that cannot proceed produce a structured `[forge:<skill-name>]`
  block and stop; never silently fall back to defaults [high] [code]
- IRON RULE violations halt the run; the user receives a precise
  "why" + "next step" message [high] [code]
- Scripts (`.mjs`) exit non-zero on hard errors; SKILL.md may route on
  exit code [medium] [code]

**What to avoid:**
- `try { ... } catch {}` that swallows errors silently
- Proceeding with best-guess defaults when a required input is missing
```

## Confidence Tags

- `[high]` — pattern observed in ≥ 5 service-layer files consistently
- `[medium]` — pattern observed but with 1–2 dissenting files (noted as
  conflict in batch list)
- `[low]` — pattern inferred from one or two files; not widely consistent
- `[inferred]` — pattern guessed from library choice without code evidence
