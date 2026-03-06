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
  process.stdout.write(JSON.stringify({ action: 'allow' }) + '\n');
  process.exit(0);
}

// If tool is not Bash, passthrough
if (!input || input.tool_name !== 'Bash') {
  process.stdout.write(JSON.stringify({ action: 'allow' }) + '\n');
  process.exit(0);
}

const command = (input.tool_input && input.tool_input.command) ? input.tool_input.command : '';

// Load global danger-dict.json (relative to __dirname = scripts/)
const globalDictPath = path.join(__dirname, 'danger-dict.json');
let globalDict = { critical: [], warning: [] };
try {
  globalDict = JSON.parse(fs.readFileSync(globalDictPath, 'utf8'));
} catch (e) {
  // If we can't read the dict, just allow
}

// Load project-specific extra dict if it exists
const cwdHash = crypto.createHash('md5').update(process.cwd()).digest('hex').slice(0, 8);
const extraDictPath = path.join(os.homedir(), '.claude', 'cc-bridle', 'projects', cwdHash, 'danger-dict-extra.json');
let extraDict = { critical: [], warning: [] };
try {
  extraDict = JSON.parse(fs.readFileSync(extraDictPath, 'utf8'));
} catch (e) {
  // Not found or invalid — skip
}

// Merge dicts
const criticalPatterns = (globalDict.critical || []).concat(extraDict.critical || []);
const warningPatterns = (globalDict.warning || []).concat(extraDict.warning || []);

// Check critical patterns
for (const patternStr of criticalPatterns) {
  let re;
  try {
    re = new RegExp(patternStr, 'i');
  } catch (e) {
    continue;
  }
  if (re.test(command)) {
    process.stdout.write(JSON.stringify({
      action: 'allow',
      message: '\uD83D\uDD34 DANGER: ' + patternStr + ' \u304C\u542B\u307E\u308C\u3066\u3044\u307E\u3059\u3002\u672C\u5F53\u306B\u5B9F\u884C\u3057\u307E\u3059\u304B\uFF1F'
    }) + '\n');
    process.exit(0);
  }
}

// Check warning patterns
for (const patternStr of warningPatterns) {
  let re;
  try {
    re = new RegExp(patternStr, 'i');
  } catch (e) {
    continue;
  }
  if (re.test(command)) {
    process.stdout.write(JSON.stringify({
      action: 'allow',
      message: '\uD83D\uDFE1 WARNING: ' + patternStr + ' \u3092\u542B\u3080\u64CD\u4F5C\u3067\u3059\u3002'
    }) + '\n');
    process.exit(0);
  }
}

// No match
process.stdout.write(JSON.stringify({ action: 'allow' }) + '\n');
process.exit(0);
