# Phase 9: 日英2プラグイン化

作成日: 2026-03-06
起点: スキルが全て英語で動作しており日本語対応が必要
目的: 同一マーケットプレイスから cc-bridle（英語）と cc-bridle-ja（日本語）を提供

依存: 全Phase

---

## タスク一覧

| Task | 内容 | Status |
|------|------|--------|
| 9.1 | plugins/cc-bridle/ ディレクトリ作成・hooks/scripts/skills コピー | cc:完了 |
| 9.2 | plugins/cc-bridle/.claude-plugin/ に plugin.json + hooks.json 配置 | cc:完了 |
| 9.3 | plugins/cc-bridle-ja/ ディレクトリ作成・hooks/scripts コピー | cc:完了 |
| 9.4 | plugins/cc-bridle-ja/skills/ に全9スキルの日本語版 SKILL.md を作成 | cc:完了 |
| 9.5 | plugins/cc-bridle-ja/.claude-plugin/ に plugin.json + hooks.json 配置 | cc:完了 |
| 9.6 | .claude-plugin/marketplace.json を2プラグイン参照に更新 | cc:完了 |
| 9.7 | ルートの旧 skills/, plugin.json, hooks.json 削除 | cc:完了 |
| 9.8 | バージョン 0.3.0 にバンプ、validate、push、再インストール検証 | cc:完了 |

---

## 受け入れ条件

- [x] plugins/cc-bridle/ に完全な英語版プラグインが存在する
- [x] plugins/cc-bridle-ja/ に完全な日本語版プラグインが存在する
- [x] 各プラグインが独立した hooks/, scripts/, skills/, .claude-plugin/ を持つ
- [x] marketplace.json が両プラグインを参照している
- [x] ルートの旧 skills/ と plugin 設定ファイルが削除されている
- [x] バージョンが 0.3.0 に更新されている
