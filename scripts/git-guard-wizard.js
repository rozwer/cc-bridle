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
  { key: 'block_force_push', label: '[1] force push ブロック (git push --force / -f)' },
  { key: 'block_push_main', label: '[2] main/master への直接 push ブロック' },
  { key: 'block_secret_files', label: '[3] 機密ファイルのステージングをブロック (.env, *.key 等)' },
  { key: 'check_commit_message', label: '[4] コミットメッセージの Conventional Commits 検証' },
  { key: 'block_large_files', label: '[5] 1MB 超ファイルのステージングをブロック' },
];

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
