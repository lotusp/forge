#!/usr/bin/env node
/**
 * status.mjs — Forge workflow state detector
 *
 * Reads the .forge/ directory of the target project and emits an authoritative
 * status report: what has been done, what feature is in progress, and exactly
 * which skill + argument to invoke next.
 *
 * This script is the single source of truth for orchestration decisions.
 * The forge skill MUST NOT override or second-guess its output.
 *
 * Usage:
 *   node status.mjs
 *   node status.mjs --feature <slug>
 *   node status.mjs --task <id>          e.g. --task T003
 *   node status.mjs --intent "<text>"    e.g. --intent "add phone verification"
 *
 * Output: plain-text status report + a machine-readable [ACTION] line at the end.
 *
 * [ACTION] format:
 *   [ACTION] skill=<name> arg=<arg> reason=<one-line reason>
 *
 * Exit codes:
 *   0 — action determined
 *   1 — action cannot be determined (user input required)
 */

import { existsSync, readdirSync, readFileSync } from 'fs';
import { join } from 'path';

// ── helpers ──────────────────────────────────────────────────────────────────

const forgeDir = '.forge';

function exists(rel) {
  return existsSync(join(forgeDir, rel));
}

function listMatching(pattern) {
  if (!existsSync(forgeDir)) return [];
  return readdirSync(forgeDir)
    .filter(f => pattern.test(f))
    .sort();
}

function slugFrom(filename, prefix, suffix = '.md') {
  return filename.replace(new RegExp(`^${prefix}-`), '').replace(new RegExp(`${suffix}$`), '');
}

function readForge(filename) {
  try { return readFileSync(join(forgeDir, filename), 'utf8'); }
  catch { return ''; }
}

function parseTaskIds(planContent) {
  const ids = [];
  const re = /^###\s+(T\d{3,})/gm;
  let m;
  while ((m = re.exec(planContent)) !== null) ids.push(m[1]);
  return ids;
}

// ── parse args ────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
let featureArg = null;
let taskArg    = null;
let intentArg  = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--feature' && args[i + 1]) { featureArg = args[++i]; }
  else if (args[i] === '--task' && args[i + 1]) { taskArg = args[++i].toUpperCase(); }
  else if (args[i] === '--intent' && args[i + 1]) { intentArg = args[++i]; }
}

// ── build state ───────────────────────────────────────────────────────────────

const onboardExists     = exists('onboard.md');
const conventionsExists = exists('conventions.md');

const clarifyFiles  = listMatching(/^clarify-.+\.md$/);
const designFiles   = listMatching(/^design-.+\.md$/);
const planFiles     = listMatching(/^plan-.+\.md$/);
const reviewFiles   = listMatching(/^review-.+\.md$/);
const testFiles     = listMatching(/^test-.+\.md$/);
const codeSummaries = listMatching(/^code-T\d+-summary\.md$/);

const clarifiedFeatures = clarifyFiles.map(f => slugFrom(f, 'clarify'));
const designedFeatures  = designFiles.map(f => slugFrom(f, 'design'));
const plannedFeatures   = planFiles.map(f => slugFrom(f, 'plan'));
const reviewedFeatures  = reviewFiles.map(f => slugFrom(f, 'review'));
const testedFeatures    = testFiles.map(f => slugFrom(f, 'test'));

const completedTaskIds  = codeSummaries.map(f => f.match(/code-(T\d+)-summary/)?.[1]).filter(Boolean);

// Build per-feature state
const allFeatures = [...new Set([
  ...clarifiedFeatures,
  ...designedFeatures,
  ...plannedFeatures,
  ...reviewedFeatures,
  ...testedFeatures,
])];

const featureStates = {};
for (const slug of allFeatures) {
  const hasClarify  = clarifiedFeatures.includes(slug);
  const hasDesign   = designedFeatures.includes(slug);
  const hasPlan     = plannedFeatures.includes(slug);
  const hasReview   = reviewedFeatures.includes(slug);
  const hasTest     = testedFeatures.includes(slug);

  let allTasks = [];
  let pendingTasks = [];
  if (hasPlan) {
    const planContent = readForge(`plan-${slug}.md`);
    allTasks = parseTaskIds(planContent);
    pendingTasks = allTasks.filter(id => !completedTaskIds.includes(id));
  }

  let phase = 'clarify';
  if (hasClarify)  phase = 'design';
  if (hasDesign)   phase = 'tasking';
  if (hasPlan && pendingTasks.length > 0) phase = 'code';
  if (hasPlan && pendingTasks.length === 0 && allTasks.length > 0) phase = 'inspect';
  if (hasReview)   phase = 'test';
  if (hasTest)     phase = 'complete';

  featureStates[slug] = {
    slug,
    hasClarify, hasDesign, hasPlan, hasReview, hasTest,
    allTasks, pendingTasks, completedTasks: completedTaskIds.filter(id => allTasks.includes(id)),
    phase,
  };
}

// ── determine action ──────────────────────────────────────────────────────────

let action = null; // { skill, arg, reason }

// Priority 1: explicit task ID
if (taskArg) {
  // Find which feature owns this task
  const ownerSlug = Object.values(featureStates).find(f => f.allTasks.includes(taskArg))?.slug;
  action = {
    skill: 'code',
    arg: taskArg,
    reason: ownerSlug
      ? `Implement task ${taskArg} from plan-${ownerSlug}.md`
      : `Implement task ${taskArg}`,
  };
}

// Priority 2: explicit feature slug
if (!action && featureArg) {
  const fs = featureStates[featureArg];
  if (!fs) {
    // Feature not found — treat as new feature intent
    action = {
      skill: 'clarify',
      arg: featureArg,
      reason: `No artifacts found for "${featureArg}" — starting from clarify`,
    };
  } else {
    switch (fs.phase) {
      case 'clarify':
        action = { skill: 'clarify', arg: fs.slug, reason: `Clarify requirement for ${fs.slug}` };
        break;
      case 'design':
        action = { skill: 'design', arg: fs.slug, reason: `Design feature ${fs.slug} (clarify done)` };
        break;
      case 'tasking':
        action = { skill: 'tasking', arg: fs.slug, reason: `Create task plan for ${fs.slug} (design done)` };
        break;
      case 'code':
        action = { skill: 'code', arg: fs.pendingTasks[0], reason: `Next pending task for ${fs.slug}` };
        break;
      case 'inspect':
        action = { skill: 'inspect', arg: fs.slug, reason: `All tasks coded — review ${fs.slug}` };
        break;
      case 'test':
        action = { skill: 'test', arg: fs.slug, reason: `Review done — write tests for ${fs.slug}` };
        break;
      case 'complete':
        action = { skill: null, arg: null, reason: `Feature ${fs.slug} is complete` };
        break;
    }
  }
}

// Priority 3: infer from global state
if (!action) {
  if (!onboardExists) {
    action = { skill: 'onboard', arg: '', reason: 'No onboard.md — map the codebase first' };
  } else if (!conventionsExists) {
    action = { skill: 'calibrate', arg: '', reason: 'No conventions.md — extract coding standards first' };
  } else {
    // Find the most advanced in-progress feature
    const inProgress = Object.values(featureStates)
      .filter(f => f.phase !== 'complete')
      .sort((a, b) => {
        const order = ['test', 'inspect', 'code', 'tasking', 'design', 'clarify'];
        return order.indexOf(a.phase) - order.indexOf(b.phase);
      });

    if (inProgress.length > 0) {
      const f = inProgress[0];
      switch (f.phase) {
        case 'design':
          action = { skill: 'design', arg: f.slug, reason: `Continue ${f.slug} → design (clarify done)` };
          break;
        case 'tasking':
          action = { skill: 'tasking', arg: f.slug, reason: `Continue ${f.slug} → tasking (design done)` };
          break;
        case 'code':
          action = { skill: 'code', arg: f.pendingTasks[0], reason: `Continue ${f.slug} → code ${f.pendingTasks[0]}` };
          break;
        case 'inspect':
          action = { skill: 'inspect', arg: f.slug, reason: `Continue ${f.slug} → inspect (all tasks coded)` };
          break;
        case 'test':
          action = { skill: 'test', arg: f.slug, reason: `Continue ${f.slug} → test (inspect done)` };
          break;
      }
    } else if (intentArg) {
      action = { skill: 'clarify', arg: intentArg, reason: 'New feature request — start from clarify' };
    } else {
      // No in-progress work and no intent — need user input
      action = null;
    }
  }
}

// ── format output ─────────────────────────────────────────────────────────────

console.log('╔══════════════════════════════════════════════════════════════╗');
console.log('║           FORGE — Workflow Status                            ║');
console.log('╚══════════════════════════════════════════════════════════════╝');
console.log('');
console.log('PROJECT SETUP');
console.log(`  onboard     ${onboardExists     ? '✓' : '✗ missing → run /forge:onboard first'}`);
console.log(`  calibrate   ${conventionsExists ? '✓' : '✗ missing → run /forge:calibrate first'}`);
console.log('');

if (allFeatures.length > 0) {
  console.log('FEATURES');
  const phaseEmoji = { clarify: '🔍', design: '📐', tasking: '📋', code: '⚙️', inspect: '🔎', test: '🧪', complete: '✅' };
  for (const [slug, fs] of Object.entries(featureStates)) {
    const phases = [
      fs.hasClarify ? '✓clarify'  : ' clarify',
      fs.hasDesign  ? '✓design'   : ' design',
      fs.hasPlan    ? `✓tasking(${fs.completedTasks.length}/${fs.allTasks.length} tasks)` : ' tasking',
      fs.hasReview  ? '✓inspect'  : ' inspect',
      fs.hasTest    ? '✓test'     : ' test',
    ];
    const nextLabel = fs.phase === 'complete' ? 'complete' : `→ next: ${fs.phase}`;
    console.log(`  ${phaseEmoji[fs.phase] || '·'} ${slug.padEnd(28)} ${nextLabel}`);
    if (fs.pendingTasks.length > 0) {
      console.log(`     pending tasks: ${fs.pendingTasks.join(', ')}`);
    }
  }
  console.log('');
}

if (action && action.skill) {
  console.log('SUGGESTED NEXT ACTION');
  console.log(`  skill : /forge:${action.skill}`);
  if (action.arg) console.log(`  arg   : ${action.arg}`);
  console.log(`  reason: ${action.reason}`);
  console.log('');
  console.log(`[ACTION] skill=${action.skill} arg=${action.arg ?? ''} reason=${action.reason}`);
  process.exit(0);
} else if (action && !action.skill) {
  console.log('STATUS: All features complete.');
  console.log('[ACTION] skill=none arg= reason=All features complete');
  process.exit(0);
} else {
  console.log('AWAITING INPUT');
  console.log('  No in-progress feature detected and no intent provided.');
  console.log('  Provide a feature description or slug to get started.');
  console.log('');
  console.log('[ACTION] skill=ask arg= reason=No context — user must provide intent or feature');
  process.exit(1);
}
