# cc-bridle

![バージョン](https://img.shields.io/badge/version-0.1.5-blue)
![ライセンス](https://img.shields.io/badge/license-MIT-green)
![テスト](https://img.shields.io/badge/tests-passing-brightgreen)

**Claude Code の「轡（くつわ）」— ブロックせず、誘導する安全プラグイン。**

Claude Code は強力ですが、`rm -rf` を黙って実行したり、`uv` プロジェクトで `pip install` を叩いたりすることがあります。cc-bridle は危険な操作に警告を出し、技術スタックの誤用を防ぎ、ツール使用状況を可視化します。

[claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) と共存設計済み。フック衝突なしで協調動作します。

---

## Before / After

<table>
<tr><th>シナリオ</th><th>cc-bridle なし</th><th>cc-bridle あり</th></tr>
<tr>
<td><strong>破壊コマンド</strong></td>
<td>

```
✓ Bash: rm -rf ./node_modules
```

</td>
<td>

```
🔴 DANGER: rm -rf が含まれています
   本当に実行しますか？
[許可] [拒否]
```

</td>
</tr>
<tr>
<td><strong>パッケージ<br>マネージャー誤用</strong></td>
<td>

```
✓ Bash: pip install requests
  # uv のロックファイルを無視
```

</td>
<td>

```
🚫 ENV GUARD: uv プロジェクトです
  × pip install requests
  → uv add requests
```

</td>
</tr>
</table>

---

## 主な機能

### ガード系（ブロックする）

| 機能 | 動作 |
|------|------|
| 🛡️ **env-guard** | プロジェクトの技術スタック（uv / bun / pnpm / poetry 等 14種）を自動検出し、誤ったパッケージマネージャーの実行を**ブロック**。正しいコマンドへの書き換えを提案する（例: `pip install` → `uv add`）。ルールは `redirect-rules.json` で定義、キャプチャグループによるコマンド引数の引き継ぎにも対応。 |
| 🔐 **git-guard** | Claude Code の git 操作に4つの設定可能なガードを適用: **force push 防止**・**main/master への直接 push 防止**・**機密ファイル（.env, .key, .pem 等）のステージング防止**・**Conventional Commits 形式の強制**。すべて `config.json` で個別に ON/OFF 可能。手動で実行する git コマンドには一切影響しない（`.git/hooks/` は変更しない）。 |

### モニター系（警告する・記録する）

| 機能 | 動作 |
|------|------|
| 🔴 **danger-label** | `rm -rf`・`git push --force`・`DROP TABLE`・`DROP SCHEMA`・`mkfs` 等の破壊的コマンドを正規表現で検出し、Claude の許可ダイアログに 🔴 CRITICAL / 🟡 WARNING のラベルを付与。**ブロックしない**（`action: 'allow'` を常に返す）。パターンはグローバル `danger-dict.json` ＋プロジェクト固有 `danger-dict-extra.json` で拡張可能。 |
| 📊 **stats** | 全ツール呼び出し（tool 名・exit_code・成否・実行時間）を `stats.jsonl` に記録。`Skill` ツールはスキル名、`Agent` ツールはサブエージェント種別も追跡。`/cc-bridle stats` で使用頻度・失敗率・最適化ヒントを表示。 |
| ⏱️ **hook-timer** | 各フックの実行時間を計測し、閾値（デフォルト 500ms、`config.json` で変更可）を超えると stderr に警告を出力。履歴は `hook-timer.jsonl` に蓄積され、`/cc-bridle hook-timer` でボトルネックを特定できる。 |

### 診断・分析系

| 機能 | 動作 |
|------|------|
| 🔍 **skill-scan** | SKILL.md ファイルを再帰スキャンし、シェルインジェクション・`eval`/`exec`・認証情報アクセス（🔴 HIGH）、ファイル書き込み・外部通信（🟡 MEDIUM）、ファイル削除（🔵 LOW）を検出。HIGH/MEDIUM 検出時は exit 1 を返し、**CI ゲートとして機能する**。LOW のみなら exit 0。 |
| 🔌 **hooks-conflict** | 新旧プラグインの hooks.json を 5 イベント（PreToolUse / PostToolUse / SessionStart / Setup / UserPromptSubmit）にわたって比較し、同一 matcher の衝突を検出。**衝突時は2つの解決策を提案**: ① 優先度マージ（推奨）② matcher リネーム。 |
| 🚀 **preflight** | CLAUDE.md と Plans.md を解析し、セッションに必要な**6種の権限**（Bash 実行・ファイル書き込み・ネットワーク・外部サービス・パッケージ公開・tmp ファイル操作）を検出。同時に danger-dict の全パターンで危険コマンドを事前マッチングし、🔴/🟡 で一覧表示。**session-probe** と連携し、検出した権限に応じたウォームアップコマンド（`echo`・`mktemp`・`uv --version` 等）をセッション開始時に自動生成する。 |

### 計画管理系

| 機能 | 動作 |
|------|------|
| 📋 **plan-split** | `Plans.md` の `## Phase N:` セクションを個別の `docs/plans/phase-N.md` に分割。既存ファイルはスキップ（上書きしない）。生成ファイルには作成日・目的・依存関係・タスク表（`cc:TODO` マーカー付き）・受け入れ条件チェックリストを含む。 |
| 📝 **plan-review** | フェーズファイルの各タスクをひとつずつレビュー。タスクごとに **OK / 修正したい / 意図を教えてください** の3択を提示し、修正はその場で phase-N.md に反映。受け入れ条件も個別に確認・編集できる。 |

---

## インストール

```bash
# プラグインマネージャー（推奨）
claude plugin install cc-bridle

# または手動
git clone https://github.com/your-org/cc-bridle ~/.claude/plugins/cc-bridle
bash ~/.claude/plugins/cc-bridle/scripts/init.sh
```

手動の場合は `~/.claude/settings.json` に `"plugins": ["cc-bridle"]` を追加してください。

---

## スキル（コマンド）一覧

| コマンド | 説明 |
|----------|------|
| `/cc-bridle preflight` | 権限要件＋危険コマンドの事前診断 |
| `/cc-bridle stats` | 使用統計と最適化のヒント |
| `/cc-bridle hook-timer` | フック性能レポート |
| `/cc-bridle scan <path>` | SKILL.md のセキュリティスキャン（CI ゲート対応） |
| `/cc-bridle githooks` | git ガードの設定ウィザード |
| `/cc-bridle add-stack <id>` | カスタムスタック検出ルールを追加 |
| `/cc-bridle plan-split` | Plans.md をフェーズファイルに分割 |
| `/cc-bridle plan-review [file]` | タスク＋受け入れ条件のインタラクティブレビュー |
| `/cc-bridle plan-review-all` | 全フェーズを優先度順にレビュー |

---

## 他プラグインとの共存

**claude-code-harness** — 同じフック形式を使用。`hooks-conflict.js` で衝突チェック＋解決策提案が可能。推奨: cc-bridle のガードを harness フックの前に配置。

**Skill Evolver / skill-usage-tracker** — 保存先が異なる（`~/.claude/cc-bridle/` vs SQLite / `~/.claude/activity-logs/`）ため競合なし。3つ同時稼働可能。

---

## ライセンス

MIT © 2026
