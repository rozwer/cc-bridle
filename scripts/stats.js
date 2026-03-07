#!/usr/bin/env node
// stats.js — PostToolUse handler that records usage statistics
// Reads stdin as JSON (PostToolUse format), appends one JSON line to ~/.claude/cc-bridle/stats.jsonl
// Always exits 0. Never blocks.

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

function main() {
  let raw = '';
  try {
    raw = fs.readFileSync('/dev/stdin', 'utf8');
  } catch (_) {
    // If stdin is not available, exit cleanly
    process.exit(0);
  }

  let input = {};
  try {
    input = JSON.parse(raw);
  } catch (_) {
    // Invalid JSON — exit cleanly, never block
    process.exit(0);
  }

  // Extract fields
  const tool = input.tool_name || input.tool || null;
  const inputData = input.tool_input || input.input || {};
  const output = input.output || {};

  // skill: captured from Skill tool invocations (tool === 'Skill') or Agent tool
  let skill = null;
  if (tool === 'Skill') {
    // Skill tool: name is in input.name or input.skill
    skill = inputData.name || inputData.skill || null;
  } else if (tool === 'Agent') {
    // Agent tool: skill name may appear in various fields
    skill = inputData.skill || inputData.skill_name || inputData.name || null;
    if (!skill && inputData.prompt) {
      const m = inputData.prompt.match(/skill[:\s]+([^\s,]+)/i);
      if (m) skill = m[1];
    }
  }

  const subagent = tool === 'Agent' || tool === 'Skill';

  const exit_code = (output.exit_code !== undefined && output.exit_code !== null)
    ? output.exit_code
    : null;

  const success = (exit_code === 0 || exit_code === null);

  const cwd_hash = crypto.createHash('md5').update(process.cwd()).digest('hex').slice(0, 8);

  const timestamp = new Date().toISOString();

  const duration_ms = (output.duration_ms !== undefined && output.duration_ms !== null)
    ? output.duration_ms
    : null;

  const record = {
    tool,
    skill,
    subagent,
    exit_code,
    success,
    cwd_hash,
    timestamp,
    duration_ms,
  };

  // mkdir -p ~/.claude/cc-bridle/
  const dir = path.join(os.homedir(), '.claude', 'cc-bridle');
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch (_) {
    // If we can't create the dir, exit cleanly
    process.exit(0);
  }

  const statsFile = path.join(dir, 'stats.jsonl');
  try {
    fs.appendFileSync(statsFile, JSON.stringify(record) + '\n');
  } catch (_) {
    // Never block on write failure
  }

  process.exit(0);
}

main();
