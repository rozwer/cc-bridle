#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

// Read all stdin synchronously
let raw = '';
try {
  raw = fs.readFileSync('/dev/stdin', 'utf8');
} catch (e) {
  raw = '';
}

let input;
try {
  input = JSON.parse(raw);
} catch (e) {
  process.exit(0);
}

// If tool is not Bash, passthrough
if (!input || input.tool_name !== 'Bash') {
  process.exit(0);
}

const command = (input.tool_input && input.tool_input.command) ? input.tool_input.command : '';

// Load env.json for current project
const cwdHash = crypto.createHash('md5').update(process.cwd()).digest('hex').slice(0, 8);
const envPath = path.join(os.homedir(), '.claude', 'cc-bridle', 'projects', cwdHash, 'env.json');

let envData;
try {
  envData = JSON.parse(fs.readFileSync(envPath, 'utf8'));
} catch (e) {
  // env.json missing or invalid - allow passthrough
  process.exit(0);
}

const stack = (envData && Array.isArray(envData.stack)) ? envData.stack : [];

if (stack.length === 0) {
  process.exit(0);
}

// Load redirect-rules.json from __dirname (= scripts/)
const redirectRulesPath = path.join(__dirname, 'redirect-rules.json');
let redirectRules = {};
try {
  redirectRules = JSON.parse(fs.readFileSync(redirectRulesPath, 'utf8'));
} catch (e) {
  // If we cannot load rules, allow
  process.exit(0);
}

// Check each stack entry against redirect rules
for (const stackId of stack) {
  const rule = redirectRules[stackId];
  if (!rule) continue;

  const wrongPatterns = rule.wrong || [];
  const suggest = rule.suggest || '';
  const message = rule.message || '';

  for (const patternStr of wrongPatterns) {
    let re;
    try {
      re = new RegExp(patternStr, 'i');
    } catch (e) {
      continue;
    }

    const match = re.exec(command);
    if (match) {
      // Replace $1, $2, ... in suggest with captured groups
      let suggestResolved = suggest;
      for (let i = 1; i < match.length; i++) {
        suggestResolved = suggestResolved.replace(
          new RegExp('\\$' + i, 'g'),
          (match[i] || '').trim()
        );
      }

      const blockMessage =
        '\uD83D\uDEAB ENV GUARD: ' + message + '\n' +
        '  \u5B9F\u884C\u30B3\u30DE\u30F3\u30C9: ' + command + '\n' +
        '  \u63A8\u5968\u30B3\u30DE\u30F3\u30C9: ' + suggestResolved;

      process.stdout.write(JSON.stringify({ action: 'block', message: blockMessage }) + '\n');
      process.exit(2);
    }
  }
}

// No match - allow
process.exit(0);
