#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

const cwd = process.cwd();
const cwdHash = crypto.createHash('md5').update(cwd).digest('hex').slice(0, 8);

// Load global detect-rules.json (relative to __dirname = scripts/)
const globalRulesPath = path.join(__dirname, 'detect-rules.json');
let rules = [];
try {
  rules = JSON.parse(fs.readFileSync(globalRulesPath, 'utf8'));
} catch (e) {
  // If we can't read global rules, continue with empty
}

// Load project-specific extra rules if they exist
const extraRulesPath = path.join(
  os.homedir(), '.claude', 'cc-bridle', 'projects', cwdHash, 'detect-rules-extra.json'
);
let extraRules = [];
try {
  extraRules = JSON.parse(fs.readFileSync(extraRulesPath, 'utf8'));
} catch (e) {
  // Not found or invalid — skip
}

// Merge: project-specific rules after global rules
const allRules = rules.concat(extraRules);

// Helper: check if a file exists in CWD
function fileExists(filename) {
  try {
    fs.accessSync(path.join(cwd, filename), fs.constants.F_OK);
    return true;
  } catch (e) {
    return false;
  }
}

// Evaluate each rule
const matchedStacks = [];
const detectedFiles = new Set();

for (const rule of allRules) {
  const filesAll = rule.files_all || [];
  const filesAny = rule.files_any || [];
  const filesNone = rule.files_none || [];

  // files_all: ALL must exist
  if (filesAll.length > 0 && !filesAll.every(fileExists)) {
    continue;
  }

  // files_any: at least ONE must exist (skip check if array is empty)
  if (filesAny.length > 0 && !filesAny.some(fileExists)) {
    continue;
  }

  // files_none: NONE must exist
  if (filesNone.some(fileExists)) {
    continue;
  }

  // Rule matched — collect stack id and contributing files
  matchedStacks.push(rule.id);
  for (const f of filesAll) {
    if (fileExists(f)) detectedFiles.add(f);
  }
  for (const f of filesAny) {
    if (fileExists(f)) detectedFiles.add(f);
  }
}

// Ensure output directory exists
const projectDir = path.join(os.homedir(), '.claude', 'cc-bridle', 'projects', cwdHash);
try {
  fs.mkdirSync(projectDir, { recursive: true });
} catch (e) {
  // Already exists or permission error
}

// Write env.json
const envData = {
  stack: matchedStacks,
  detected_files: Array.from(detectedFiles),
  cwd: cwd,
  updated_at: new Date().toISOString()
};

const envPath = path.join(projectDir, 'env.json');
fs.writeFileSync(envPath, JSON.stringify(envData, null, 2) + '\n', 'utf8');

// Print detected stacks to stdout
if (matchedStacks.length > 0) {
  process.stdout.write('Detected stacks: ' + matchedStacks.join(', ') + '\n');
} else {
  process.stdout.write('Detected stacks: (none)\n');
}

process.exit(0);
