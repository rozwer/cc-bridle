#!/usr/bin/env node
// hook-timer.js — Timing wrapper for hooks
// Reads stdin as JSON HookInput, measures execution time, logs to hook-timer.jsonl
// Warns on stderr if duration exceeds threshold.
// Always exits 0.
//
// Usage: node scripts/hook-timer.js [hook_name]
//   hook_name defaults to process.argv[2] if provided, else "unknown"

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

const start = Date.now();

function main() {
  const hookName = process.argv[2] || 'unknown';

  let raw = '';
  try {
    raw = fs.readFileSync('/dev/stdin', 'utf8');
  } catch (_) {
    process.exit(0);
  }

  let input = {};
  try {
    input = JSON.parse(raw);
  } catch (_) {
    // Invalid JSON — continue, record what we can
  }

  const end = Date.now();
  const duration_ms = end - start;

  const tool = input.tool_name || input.tool || null;

  // Read config for threshold
  const configFile = path.join(os.homedir(), '.claude', 'cc-bridle', 'config.json');
  let threshold = 500;
  try {
    const configRaw = fs.readFileSync(configFile, 'utf8');
    const config = JSON.parse(configRaw);
    if (typeof config.hook_timer_threshold_ms === 'number') {
      threshold = config.hook_timer_threshold_ms;
    }
  } catch (_) {
    // Use default threshold
  }

  // Warn if slow
  if (duration_ms > threshold) {
    process.stderr.write(
      `\u26A0\uFE0F HOOK SLOW: ${hookName} \u304C ${duration_ms}ms \u304B\u304B\u3063\u3066\u3044\u307E\u3059\uFF08\u9596\u5024: ${threshold}ms\uFF09\n`
    );
  }

  // mkdir -p ~/.claude/cc-bridle/
  const dir = path.join(os.homedir(), '.claude', 'cc-bridle');
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch (_) {
    process.exit(0);
  }

  const record = {
    hook_name: hookName,
    tool,
    duration_ms,
    timestamp: new Date().toISOString(),
  };

  const timerFile = path.join(dir, 'hook-timer.jsonl');
  try {
    fs.appendFileSync(timerFile, JSON.stringify(record) + '\n');
  } catch (_) {
    // Never block on write failure
  }

  // Output allow action
  process.stdout.write(JSON.stringify({ action: 'allow' }) + '\n');
  process.exit(0);
}

main();
