# Detectors — White-listed Evidence Producers

A detector is a small Bash script that answers ONE structured question
about a project (e.g. "how many `@RestController` files are there?").
The validator runs detectors via the registry; profiles reference them
via `detector-id`.

Detectors exist to replace the v0.5.1 anti-pattern of LLMs guessing
counts ("approximately 90 entities") that turn out to be wildly off.

## Hard Contract — every detector MUST

1. **No `eval` of external input.** Only execute hard-coded grep / find /
   awk pipelines. The scan-root path is a positional arg; everything else
   is baked in.
2. **Take scan-root as `$1`** (default `src/main/java`). Validate
   `[ -d "$ROOT" ]` and emit `result: 0` with `error` field if missing.
3. **Output JSON to stdout** via `jq -n` (paths with quotes/spaces will
   corrupt naive `printf '{...}'` output):

   ```json
   {
     "detector": "<detector-id>",
     "root": "<scan-root>",
     "result": <int|array>,
     "evidence_cmd": "<reproducible cmd as display string>",
     "error": "<optional; only when scan failed>"
   }
   ```

4. **`evidence_cmd` is display-only.** Never read it back, never
   re-execute it. It exists for human review traceability.
5. **Exit 0 on success, even if `result == 0`.** Use the `error` field
   for actual failures.
6. **Read-only against the project tree.** No network, no writes outside
   stdout.

## Schema (registry.json)

Each detector has one entry:

```json
{ "detector-id": "...", "detector-script": "...", "rendered-as": "count|list" }
```

- `detector-id` — unique, snake_case, referenced from profile frontmatter
- `detector-script` — path relative to this directory; must be executable
- `rendered-as` — hint for callers about output shape

## Adding a New Detector

1. Pick a `detector-id` that does NOT bake in a stack name (target v0.6.0
   adapter model). Prefer `http_routes` over `spring_mappings` when
   abstracting; v0.5.x detectors carry stack names because the gate
   already restricts to Java/Spring.
2. Create `<detector-id>.sh` following the contract above.
3. `chmod +x` the script.
4. Add an entry to `registry.json`.
5. Reference from profile frontmatter via `detector-id`.
6. preflight will lint registry ↔ profile consistency at validator entry.

## Fuzz Testing

Detectors must be hardened against malicious scan-root values:

```bash
# Should NOT execute any side-effect
bash spring_mappings.sh '/tmp;rm -rf /'
bash spring_mappings.sh '$(date)'
bash spring_mappings.sh '`echo X`'
bash spring_mappings.sh 'path with spaces and "quotes"'
```

Each must emit valid JSON and never invoke external commands implied by
the malformed input. The recipe: pass ROOT as quoted positional arg with
`-- "$ROOT"` separator, never via string concat into a shell line.
