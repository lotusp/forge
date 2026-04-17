#!/usr/bin/env node
/**
 * validate-output.mjs
 *
 * Validates that all four context files under .forge/context/ contain
 * the required sections before the calibration session is considered complete.
 *
 * Files validated:
 *   - .forge/context/conventions.md  (naming, logging, error handling, validation,
 *                                     API design, DB access, messaging)
 *   - .forge/context/testing.md      (test framework, isolation, mocks, data, coverage)
 *   - .forge/context/architecture.md (layering, inter-module communication, tech debt)
 *   - .forge/context/constraints.md  (hard rules, anti-patterns, security)
 *
 * Usage:
 *   node ${CLAUDE_SKILL_DIR}/scripts/validate-output.mjs
 *
 * Exit codes:
 *   0 — all four context files are valid (required sections present)
 *   1 — one or more context files are missing or incomplete
 */

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const contextDir = join('.forge', 'context');

// ── file requirements ─────────────────────────────────────────────────────────

const filesToValidate = [
  {
    path: join(contextDir, 'conventions.md'),
    label: 'conventions.md',
    requiredSections: [
      'Naming',
      'Logging',
      'Error Handling',
      'Validation',
      'API Design',
      'Database Access',
      'Decision Log',
    ],
  },
  {
    path: join(contextDir, 'testing.md'),
    label: 'testing.md',
    requiredSections: [
      'Test Framework',
      'Test Location',
      'Mock Strategy',
      'Test Data',
      'Coverage',
    ],
  },
  {
    path: join(contextDir, 'architecture.md'),
    label: 'architecture.md',
    requiredSections: [
      'Layering',
      'Inter-Module',
    ],
  },
  {
    path: join(contextDir, 'constraints.md'),
    label: 'constraints.md',
    requiredSections: [
      'Hard Rules',
      'Anti-patterns',
    ],
  },
];

// ── helpers ───────────────────────────────────────────────────────────────────

function checkSections(content, sections) {
  const missing = [];
  for (const section of sections) {
    const pattern = new RegExp(`^#{1,3}\\s+${section.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'mi');
    if (!pattern.test(content)) {
      missing.push(section);
    }
  }
  return missing;
}

// ── main ──────────────────────────────────────────────────────────────────────

console.log('=== /forge:calibrate — Output Validation ===\n');

let overallPass = true;

for (const spec of filesToValidate) {
  if (!existsSync(spec.path)) {
    console.error(`[FAIL] ${spec.path} does not exist.`);
    console.error(`  → /forge:calibrate did not write ${spec.label}.\n`);
    overallPass = false;
    continue;
  }

  const content = readFileSync(spec.path, 'utf8');
  const missing = checkSections(content, spec.requiredSections);

  if (missing.length === 0) {
    console.log(`[PASS] ${spec.path}`);

    // Check that at least some file:line citations exist in conventions/architecture
    if (spec.label === 'conventions.md' || spec.label === 'architecture.md') {
      const citationPattern = /[a-zA-Z0-9_/.-]+\.(java|ts|go|py|js|kt):\d+/;
      if (!citationPattern.test(content)) {
        console.warn(`[WARN] ${spec.label}: No file:line citations found. Every rule should cite its source.\n`);
      }
    }

    // Check Decision Log has at least one entry in conventions.md
    if (spec.label === 'conventions.md') {
      const decisionLogIdx = content.indexOf('Decision Log');
      if (decisionLogIdx !== -1) {
        const afterLog = content.slice(decisionLogIdx);
        const hasRows = /\|\s*\d+\s*\|/.test(afterLog);
        if (!hasRows) {
          console.warn('[WARN] conventions.md: Decision Log appears empty. All adjudicated conflicts should be logged.\n');
        }
      }
    }
  } else {
    console.error(`[FAIL] ${spec.path} — missing required sections:`);
    for (const s of missing) {
      console.error(`  - ${s}`);
    }
    console.error('');
    overallPass = false;
  }
}

console.log('');

if (overallPass) {
  console.log('[PASS] All four context files are present and valid.\n');
  process.exit(0);
} else {
  console.error('[FAIL] One or more context files are missing or incomplete.');
  console.error('Do not mark calibration complete until all files pass.\n');
  process.exit(1);
}
