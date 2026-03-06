#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');

const CONFIG_PATH = path.join(os.homedir(), '.claude', 'cc-bridle', 'config.json');

function allow() {
  process.stdout.write(JSON.stringify({ action: 'allow' }) + '\n');
  process.exit(0);
}

function block(message) {
  process.stdout.write(JSON.stringify({ action: 'block', message }) + '\n');
  process.exit(2);
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  let parsed;
  try { parsed = JSON.parse(input); } catch (e) { allow(); return; }

  const { tool, input: toolInput } = parsed;
  if (tool !== 'Bash') { allow(); return; }

  const command = (toolInput && toolInput.command) || '';

  // Only check git commands
  if (!/git\s/.test(command)) { allow(); return; }

  let cfg = {};
  try { cfg = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')); } catch (e) {}

  const guard = cfg.git_guard || {};

  // [1] Block force push
  if (guard.block_force_push) {
    if (/git\s+push\s+.*(?:--force|-f)\b/.test(command)) {
      block('GIT GUARD: force push は Claude Code から禁止されています\n  コマンド: ' + command);
      return;
    }
  }

  // [2] Block direct push to main/master
  if (guard.block_push_main) {
    if (/git\s+push\s+(?:\S+\s+)?(?:main|master)\b/.test(command)) {
      block('GIT GUARD: main/master への直接 push は Claude Code から禁止されています\n  コマンド: ' + command);
      return;
    }
  }

  // [3] Block secret files staging
  if (guard.block_secret_files) {
    if (/git\s+add/.test(command)) {
      if (/\.env\b|\.key\b|\.pem\b|\.p12\b|id_rsa|credentials/.test(command)) {
        block('GIT GUARD: 機密ファイルのステージングは禁止されています\n  コマンド: ' + command);
        return;
      }
    }
  }

  // [4] Conventional Commits check
  if (guard.check_commit_message) {
    const commitMatch = command.match(/git\s+commit\s+.*-m\s+["']([^"']+)["']/);
    if (commitMatch) {
      const msg = commitMatch[1];
      if (!/^(?:feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(?:\(.+\))?:\s+.+/.test(msg)) {
        block('GIT GUARD: コミットメッセージが Conventional Commits 形式ではありません\n  メッセージ: ' + msg + '\n  例: "feat: add new feature"');
        return;
      }
    }
  }

  allow();
});
