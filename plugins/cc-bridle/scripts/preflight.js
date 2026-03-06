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

// Load global danger-dict.json (relative to __dirname = scripts/)
const globalDictPath = path.join(__dirname, 'danger-dict.json');
let globalDict = { critical: [], warning: [] };
try {
  globalDict = JSON.parse(fs.readFileSync(globalDictPath, 'utf8'));
} catch (e) {
  // ignore
}

// Load project-specific extra dict if it exists
const cwdHash = crypto.createHash('md5').update(cwd).digest('hex').slice(0, 8);
const extraDictPath = path.join(os.homedir(), '.claude', 'cc-bridle', 'projects', cwdHash, 'danger-dict-extra.json');
let extraDict = { critical: [], warning: [] };
try {
  extraDict = JSON.parse(fs.readFileSync(extraDictPath, 'utf8'));
} catch (e) {
  // Not found or invalid — skip
}

const criticalPatterns = (globalDict.critical || []).concat(extraDict.critical || []);
const warningPatterns = (globalDict.warning || []).concat(extraDict.warning || []);

// Read CLAUDE.md and Plans.md
const claudeMd = readFileSafe(path.join(cwd, 'CLAUDE.md'));
const plansMd = readFileSafe(path.join(cwd, 'Plans.md'));
const combinedText = claudeMd + '\n' + plansMd;

// (A) Permission detection
const permissionMap = [
  { pattern: /Bash/,                                    label: 'Bash実行権限' },
  { pattern: /Write|Edit|Create/,                       label: 'ファイル書き込み権限' },
  { pattern: /WebFetch|fetch\s*\(|https?:\/\/|curl\b|wget\b|axios/,  label: 'ネットワーク権限' },
  { pattern: /git push|deploy/,                         label: '外部サービス権限' },
  { pattern: /npm publish|pip upload/,                  label: 'パッケージ公開権限' },
  { pattern: /\/tmp\/|mktemp|tmpfile|tempfile|os\.tmpdir|tmp_dir/, label: 'tmpファイル作成・読み書き権限' },
];

const detectedPermissions = [];
for (const { pattern, label } of permissionMap) {
  if (pattern.test(combinedText)) {
    detectedPermissions.push(label);
  }
}

// (B) Dangerous command detection in text
const dangerousFound = [];

for (const patternStr of criticalPatterns) {
  let re;
  try {
    re = new RegExp(patternStr, 'i');
  } catch (e) {
    continue;
  }
  if (re.test(combinedText)) {
    dangerousFound.push({ level: 'critical', pattern: patternStr });
  }
}

for (const patternStr of warningPatterns) {
  let re;
  try {
    re = new RegExp(patternStr, 'i');
  } catch (e) {
    continue;
  }
  if (re.test(combinedText)) {
    dangerousFound.push({ level: 'warning', pattern: patternStr });
  }
}

// Output results
console.log('=== cc-bridle preflight ===');
console.log('');
console.log('【権限リスト】');
if (detectedPermissions.length === 0) {
  console.log('  (権限なし)');
} else {
  for (const perm of detectedPermissions) {
    console.log('  - ' + perm);
  }
}

console.log('');
console.log('【危険コマンド予告】');
if (dangerousFound.length === 0) {
  console.log('  (危険コマンドなし)');
} else {
  for (const item of dangerousFound) {
    if (item.level === 'critical') {
      console.log('  🔴 CRITICAL: 危険コマンド: ' + item.pattern);
    } else {
      console.log('  🟡 WARNING: 危険コマンド: ' + item.pattern);
    }
  }
}

process.exit(0);
