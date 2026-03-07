#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');

// Check items with severity
const CHECKS = [
  { severity: 'HIGH', pattern: /`[^`]*\$\(|`[^`]*`/, reason: 'Shell injection (backtick or $())' },
  { severity: 'HIGH', pattern: /\beval\b|\bexec\b/, reason: 'eval/exec usage' },
  { severity: 'HIGH', pattern: /process\.env\..*(?:KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)/i, reason: 'Credential access pattern' },
  { severity: 'MEDIUM', pattern: /fs\.writeFileSync|Write|Edit/, reason: 'File write without confirmation' },
  { severity: 'MEDIUM', pattern: /fetch|axios|http|https|WebFetch|curl|wget/, reason: 'External network access' },
  { severity: 'LOW', pattern: /\brm\b|\bunlink\b|\brmdir\b/, reason: 'File deletion' },
];

function scanFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const issues = [];

  lines.forEach((line, i) => {
    CHECKS.forEach(check => {
      if (check.pattern.test(line)) {
        issues.push({ severity: check.severity, lineNum: i + 1, line: line.trim(), reason: check.reason });
      }
    });
  });

  return issues;
}

function scanPath(targetPath) {
  const stat = fs.statSync(targetPath);
  const files = [];

  if (stat.isDirectory()) {
    // Find all SKILL.md files recursively
    function findSkills(dir) {
      fs.readdirSync(dir).forEach(entry => {
        const full = path.join(dir, entry);
        const s = fs.statSync(full);
        if (s.isDirectory()) findSkills(full);
        else if (entry === 'SKILL.md') files.push(full);
      });
    }
    findSkills(targetPath);
  } else {
    files.push(targetPath);
  }

  return files;
}

const args = process.argv.slice(2);
const targetPath = args[0];

if (!targetPath) {
  console.error('Usage: node skill-scan.js <path>');
  process.exit(1);
}

if (!fs.existsSync(targetPath)) {
  console.error(`Error: Path not found: ${targetPath}`);
  process.exit(1);
}

const files = scanPath(targetPath);
let hasBlockingIssues = false;

files.forEach(file => {
  const issues = scanFile(file);
  console.log(`\n🔍 SKILL SCAN: ${file}`);

  if (issues.length === 0) {
    console.log('  ✅ Clean — no issues detected');
  } else {
    if (issues.some(i => i.severity === 'HIGH' || i.severity === 'MEDIUM')) {
      hasBlockingIssues = true;
    }
    issues.forEach(issue => {
      const emoji = issue.severity === 'HIGH' ? '🔴' : issue.severity === 'MEDIUM' ? '🟡' : '🔵';
      console.log(`  ${emoji} ${issue.severity}: line ${issue.lineNum} - ${issue.reason}`);
      console.log(`    > ${issue.line}`);
    });
  }
});

// Exit 1 on HIGH/MEDIUM findings (CI gate). LOW findings are informational only.
process.exit(hasBlockingIssues ? 1 : 0);
