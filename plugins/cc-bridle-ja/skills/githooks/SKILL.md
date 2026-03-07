---
name: githooks
description: Claude Code 固有の git ガードを対話的ウィザードで設定します。
triggers:
  - githooks
  - ユーザーが Claude Code の git 保護設定を依頼した場合
---

## このスキルの機能

Claude Code の git 操作に対する保護を設定します。

ガードは Claude Code が Bash ツール経由で git コマンドを実行する場合のみ適用されます。
ターミナルで手動実行する git コマンドには影響しません。

## 手順

### Step 1: 現在の状態を表示

実行: `node ${CLAUDE_PLUGIN_ROOT}/scripts/git-guard-wizard.js --show`

全ガードキーと現在の有効/無効状態が JSON で出力されます。

### Step 2: ユーザーに確認する

AskUserQuestion を multiSelect=true で使用して、有効にするガードをユーザーに選択してもらいます。

利用可能なガード:
- `block_force_push` — force push ブロック (git push --force / -f)
- `block_push_main` — main/master への直接 push ブロック
- `block_secret_files` — 機密ファイルのステージングをブロック (.env, *.key 等)
- `check_commit_message` — Conventional Commits 検証
- `block_large_files` — 1MB 超ファイルのステージングをブロック

現在の状態をユーザーに示し、これらをオプションとして単一の multiSelect 質問で提示します。
注意: AskUserQuestion は最大4オプションまでのため、必要に応じて2回に分けてください
（例: 質問1: force_push, push_main, secret_files; 質問2: commit_message, large_files）。

### Step 3: 設定を適用する

ユーザーの選択から `key=on` / `key=off` のカンマ区切り文字列を構築して実行:

```
node ${CLAUDE_PLUGIN_ROOT}/scripts/git-guard-wizard.js --set key1=on,key2=off,...
```

### Step 4: 確認する

保存された設定をユーザーに表示します。
