#!/usr/bin/env node
/**
 * validate-output.mjs
 *
 * Validates that .forge/conventions.md contains all required sections
 * before the calibration session is considered complete.
 *
 * Required sections (must all be present as ## headings):
 *   - Tech Stack
 *   - Architecture & Layering
 *   - Naming Conventions
 *   - Logging
 *   - Error Handling
 *   - Testing
 *   - Anti-patterns
 *   - Decision Log
 *
 * Usage:
 *   node ${CLAUDE_SKILL_DIR}/scripts/validate-output.mjs
 *
 * Exit codes:
 *   0 — conventions.md is valid (all required sections present)
 *   1 — conventions.md is missing or incomplete
 */

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const conventionsPath = join('.forge', 'conventions.md');

if (!existsSync(conventionsPath)) {
  console.error(`[FAIL] ${conventionsPath} does not exist.`);
  console.error('  → /forge:calibrate did not write the output file.\n');
  process.exit(1);
}

const content = readFileSync(conventionsPath, 'utf8');

const requiredSections = [
  'Tech Stack',
  'Architecture & Layering',
  'Naming Conventions',
  'Logging',
  'Error Handling',
  'Testing',
  'Anti-patterns',
  'Decision Log',
];

const missing = [];

for (const section of requiredSections) {
  // Match as a ## heading (level 2 or deeper)
  const pattern = new RegExp(`^#{1,3}\\s+${section.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'm');
  if (!pattern.test(content)) {
    missing.push(section);
  }
}

console.log('=== /forge:calibrate — Output Validation ===\n');
console.log(`File: ${conventionsPath}\n`);

if (missing.length === 0) {
  console.log('[PASS] All required sections are present.\n');

  // Check that at least some file:line citations exist
  const citationPattern = /[a-zA-Z0-9_/.-]+\.(java|ts|go|py|js|kt):\d+/;
  if (!citationPattern.test(content)) {
    console.warn('[WARN] No file:line citations found. Every rule should cite its source.\n');
  }

  // Check Decision Log has at least one entry
  const decisionLogIdx = content.indexOf('Decision Log');
  if (decisionLogIdx !== -1) {
    const afterLog = content.slice(decisionLogIdx);
    // Simple heuristic: table row starts with "| " after the header separator
    const hasRows = /\|\s*\d+\s*\|/.test(afterLog);
    if (!hasRows) {
      console.warn('[WARN] Decision Log appears empty. All adjudicated conflicts should be logged.\n');
    }
  }

  process.exit(0);
} else {
  console.error('[FAIL] Missing required sections:\n');
  for (const s of missing) {
    console.error(`  - ${s}`);
  }
  console.error('\nDo not mark calibration complete until all sections are present.\n');
  process.exit(1);
}
