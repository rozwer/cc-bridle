#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

// CWD from argument or process.cwd()
const cwd = process.argv[2] || process.cwd();

// Read a file, return empty string if missing
function readFileSafe(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch (e) {
    return '';
  }
}

// Check if session_probe is enabled (default: true)
const configPath = path.join(os.homedir(), '.claude', 'cc-bridle', 'config.json');
let config = {};
try {
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (e) {
  // ignore — defaults apply
}
if (config.session_probe && config.session_probe.enabled === false) {
  process.exit(0);
}

// Read project context
const claudeMd = readFileSafe(path.join(cwd, 'CLAUDE.md'));
const plansMd = readFileSafe(path.join(cwd, 'Plans.md'));
const combinedText = claudeMd + '\n' + plansMd;

// Read env.json for stack detection
const cwdHash = crypto.createHash('md5').update(cwd).digest('hex').slice(0, 8);
const envJsonPath = path.join(os.homedir(), '.claude', 'cc-bridle', 'projects', cwdHash, 'env.json');
let envJson = {};
try {
  envJson = JSON.parse(fs.readFileSync(envJsonPath, 'utf8'));
} catch (e) {
  // ignore
}

// Build probe list
const probes = [];
let n = 1;

// Always: basic Bash permission
probes.push({ n: n++, label: 'Bash基本', cmd: 'echo "cc-bridle:ok"' });

// tmp file access (detected from text)
if (/\/tmp\/|mktemp|tmpfile|tempfile|os\.tmpdir|tmp_dir/i.test(combinedText)) {
  probes.push({
    n: n++,
    label: 'tmpファイル',
    cmd: 'F=$(mktemp /tmp/.cc-bridle-XXXXXX) && echo probe > "$F" && cat "$F" && rm -f "$F"',
  });
}

// Package manager probes (from env.json)
const tools = ['uv', 'bun', 'npm', 'pnpm', 'poetry', 'pip'];
for (const tool of tools) {
  if (envJson[tool]) {
    probes.push({ n: n++, label: tool, cmd: `${tool} --version` });
  }
}

// git (detected from text)
if (/git\s+(push|pull|commit|clone|checkout|merge|rebase|stash|fetch)/i.test(combinedText)) {
  probes.push({ n: n++, label: 'git', cmd: 'git --version' });
}

// Output directive for Claude
console.log('=== cc-bridle: セッション権限ウォームアップ ===');
console.log('');
console.log('作業を始める前に、以下の権限プローブを実行してください。');
console.log('これにより作業中の権限ダイアログによる中断を防げます:');
console.log('');
for (const probe of probes) {
  console.log(`${probe.n}. [${probe.label}] ${probe.cmd}`);
}
console.log('');
console.log('実行後、作業を開始してください。');

process.exit(0);
