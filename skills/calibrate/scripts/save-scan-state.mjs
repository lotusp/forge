#!/usr/bin/env node
/**
 * save-scan-state.mjs
 *
 * Creates (or resets) the .forge/calibrate-scan.md skeleton so that
 * /forge:calibrate has a pre-structured file to fill in during the scan.
 *
 * Run ONCE at the start of a new calibration session, before reading
 * any source files. The AI fills in the sections during Steps 1–3.
 *
 * Usage:
 *   node ${CLAUDE_SKILL_DIR}/scripts/save-scan-state.mjs
 *
 * Writes: .forge/calibrate-scan.md
 */

import { mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';

const forgeDir = '.forge';
mkdirSync(forgeDir, { recursive: true });

const today = new Date().toISOString().split('T')[0];

const skeleton = `# Calibrate Scan State

> Saved: ${today}
> Status: scan-in-progress

---

## Build File Findings

> Fill in during Step 1 — read before sampling any source files.

- Build tool: (gradle / maven / npm / go)
- Dependencies of note:
  - (list each dependency relevant to a convention dimension)

---

## Observed Patterns (per dimension)

> Fill in during Step 2 — one sub-section per dimension.

### Architecture & Layering
<!-- file:line citations required -->

### Naming
<!-- file:line citations required -->

### Logging
<!-- file:line citations required -->

### Error Handling
<!-- file:line citations required -->

### Validation
<!-- file:line citations required -->

### Testing
<!-- file:line citations required -->

### API Design
<!-- file:line citations required -->

### Database Access
<!-- file:line citations required -->

### Messaging & Events
<!-- file:line citations required (or "not applicable") -->

---

## Contradictions Identified

> Fill in during Step 4 — one entry per conflict.

| # | Dimension | Pattern A | Pattern B | Files (A) | Files (B) |
|---|-----------|-----------|-----------|-----------|-----------|
| — | — | — | — | — | — |

---

## Mandatory Checks Status

- URL versioning: not checked yet
- Transaction boundaries: not checked yet
- Test isolation strategy: not checked yet

---

## Adjudication Log

> Filled in during Step 5 — one row per resolved conflict.

| # | Dimension | Decision | Reason | Date |
|---|-----------|----------|--------|------|
`;

const outPath = join(forgeDir, 'calibrate-scan.md');
writeFileSync(outPath, skeleton, 'utf8');
console.log(`Written: ${outPath}`);
