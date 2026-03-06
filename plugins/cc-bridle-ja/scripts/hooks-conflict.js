#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');

function loadHooksJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    return null;
  }
}

function getMatchers(hooks, event) {
  if (!hooks[event]) return [];
  return hooks[event].map(h => h.matcher || '*').filter(Boolean);
}

function findHooksFiles(dir) {
  const results = [];
  let entries;
  try {
    entries = fs.readdirSync(dir);
  } catch (e) {
    return results;
  }
  entries.forEach(entry => {
    const full = path.join(dir, entry);
    let stat;
    try {
      stat = fs.statSync(full);
    } catch (e) {
      return;
    }
    if (stat.isDirectory()) {
      findHooksFiles(full).forEach(f => results.push(f));
    } else if (entry === 'hooks.json') {
      results.push(full);
    }
  });
  return results;
}

const args = process.argv.slice(2);
let newHooksPath = null;
let existingGlob = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--new') newHooksPath = args[++i];
  if (args[i] === '--existing') existingGlob = args[++i];
}

if (!newHooksPath) {
  console.error('Usage: node hooks-conflict.js --new <hooks.json> [--existing <glob>]');
  process.exit(1);
}

const newHooks = loadHooksJson(newHooksPath);
if (!newHooks) {
  console.error(`Error: Cannot read ${newHooksPath}`);
  process.exit(1);
}

// Find existing hooks.json files using pure Node.js directory walk
let existingFiles = [];
if (existingGlob) {
  existingFiles = findHooksFiles(existingGlob).filter(f => f !== newHooksPath);
}

const EVENTS = ['PreToolUse', 'PostToolUse', 'SessionStart', 'Setup', 'UserPromptSubmit'];
let conflicts = [];

existingFiles.forEach(existingPath => {
  const existingHooks = loadHooksJson(existingPath);
  if (!existingHooks) return;

  const existingPlugin = path.basename(path.dirname(existingPath));

  EVENTS.forEach(event => {
    const newMatchers = getMatchers(newHooks, event);
    const existingMatchers = getMatchers(existingHooks, event);

    newMatchers.forEach(nm => {
      existingMatchers.forEach(em => {
        // Both are non-wildcard and equal, or both are wildcards
        const isConflict = nm === em;
        if (isConflict) {
          conflicts.push({ event, matcher: nm, existingPlugin, existingPath });
        }
      });
    });
  });
});

if (conflicts.length === 0) {
  console.log('No hook conflicts detected.');
} else {
  console.log('HOOK CONFLICT detected\n');
  conflicts.forEach(c => {
    console.log(`  event: ${c.event}`);
    console.log(`  matcher: ${c.matcher}`);
    console.log(`  conflicting plugins: [${c.existingPlugin}, cc-bridle]`);
    console.log();
  });

  console.log('Resolution A (priority merge — recommended):');
  console.log('  Register both hooks on the same event and control order via priority field.');
  console.log('  Example: {"event":"PreToolUse","matcher":"Bash","command":"...","priority":10}');
  console.log();
  console.log('Resolution B (alternative matcher):');
  console.log('  Rename one matcher. Example: "Bash__cc-bridle"');
  console.log('  Verify Claude Code recognizes the renamed matcher.');
  console.log();
  console.log('Recommended: Resolution A (priority merge). Preserves both plugins while making execution order explicit.');
}

process.exit(0);
