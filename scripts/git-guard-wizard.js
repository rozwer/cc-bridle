#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const os = require('os');

const CONFIG_PATH = path.join(os.homedir(), '.claude', 'cc-bridle', 'config.json');

function loadConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  } catch (e) {
    return {};
  }
}

function saveConfig(cfg) {
  fs.mkdirSync(path.dirname(CONFIG_PATH), { recursive: true });
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(cfg, null, 2) + '\n');
}

const GUARDS = [
  { key: 'block_force_push', label: 'force push ブロック (git push --force / -f)' },
  { key: 'block_push_main', label: 'main/master への直接 push ブロック' },
  { key: 'block_secret_files', label: '機密ファイルのステージングをブロック (.env, *.key 等)' },
  { key: 'check_commit_message', label: 'コミットメッセージの Conventional Commits 検証' },
  { key: 'block_large_files', label: '1MB 超ファイルのステージングをブロック' },
];

// --- CLI mode: node git-guard-wizard.js --set key1=on,key2=off ---
// --- Show mode: node git-guard-wizard.js --show ---
const args = process.argv.slice(2);

if (args.includes('--show')) {
  const cfg = loadConfig();
  const guard = cfg.git_guard || {};
  console.log(JSON.stringify({ guards: GUARDS.map(g => ({ key: g.key, label: g.label, enabled: !!guard[g.key] })) }));
  process.exit(0);
}

if (args.includes('--set')) {
  const setArg = args[args.indexOf('--set') + 1];
  if (!setArg) { console.error('Usage: --set key1=on,key2=off'); process.exit(1); }
  const cfg = loadConfig();
  const guard = cfg.git_guard || {};
  for (const pair of setArg.split(',')) {
    const [k, v] = pair.split('=');
    if (GUARDS.some(g => g.key === k)) {
      guard[k] = v === 'on' || v === 'true' || v === 'yes';
    }
  }
  cfg.git_guard = guard;
  saveConfig(cfg);
  console.log(JSON.stringify({ saved: true, git_guard: guard }));
  process.exit(0);
}

// --- Interactive mode (terminal only) ---
async function run() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const question = (q) => new Promise(resolve => rl.question(q, resolve));

  console.log('\n cc-bridle git-guard ウィザード\n');
  console.log('Claude Code 経由の git コマンドを保護します（手動 git には影響しません）\n');
  console.log('有効化するガードを選択してください（y/n）:\n');

  const selections = {};
  for (const guard of GUARDS) {
    const answer = await question(`${guard.label} [y/n]: `);
    selections[guard.key] = answer.toLowerCase().startsWith('y');
  }

  const cfg = loadConfig();
  cfg.git_guard = selections;
  saveConfig(cfg);

  rl.close();

  console.log('\n git-guard 設定を保存しました:\n');
  GUARDS.forEach(g => {
    const status = selections[g.key] ? '有効' : '無効';
    console.log(`  ${status} ${g.label}`);
  });
}

run().catch(e => { console.error(e); process.exit(1); });
