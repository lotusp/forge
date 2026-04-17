#!/usr/bin/env node
/**
 * check-prerequisites.mjs
 *
 * Checks whether the prerequisites for /forge:calibrate are met:
 *   1. .forge/context/onboard.md exists (required)
 *   2. .forge/_session/calibrate-scan.md exists (optional — enables resume)
 *   3. .forge/context/conventions.md exists (warns that re-calibration will overwrite)
 *
 * Usage (from the target project root):
 *   node ${CLAUDE_SKILL_DIR}/scripts/check-prerequisites.mjs
 *
 * Exit codes:
 *   0 — all required prerequisites are met
 *   1 — onboard.md is missing (blocking)
 */

import { existsSync } from 'fs';
import { join } from 'path';

const forgeDir = '.forge';

const onboardPath     = join(forgeDir, 'context', 'onboard.md');
const scanStatePath   = join(forgeDir, '_session', 'calibrate-scan.md');
const conventionsPath = join(forgeDir, 'context', 'conventions.md');

const onboardExists     = existsSync(onboardPath);
const scanStateExists   = existsSync(scanStatePath);
const conventionsExists = existsSync(conventionsPath);

console.log('=== /forge:calibrate — Prerequisite Check ===\n');

if (!onboardExists) {
  console.error(`[MISSING] ${onboardPath}`);
  console.error('  → Run /forge:onboard first to generate the module map.\n');
  process.exit(1);
} else {
  console.log(`[OK]      ${onboardPath}`);
}

if (scanStateExists) {
  console.log(`[RESUME]  ${scanStatePath} — prior scan found, adjudication can resume`);
} else {
  console.log(`[NEW]     ${scanStatePath} — no prior scan, full scan required`);
}

if (conventionsExists) {
  console.log(`[WARN]    ${conventionsPath} — existing conventions will be overwritten on completion`);
} else {
  console.log(`[OK]      ${conventionsPath} — will be created`);
}

console.log('\nPrerequisites met. Proceeding with calibration.\n');
process.exit(0);
