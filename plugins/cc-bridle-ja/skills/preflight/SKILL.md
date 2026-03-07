---
name: preflight
description: プリフライト安全チェックを実行します。CLAUDE.md と Plans.md を読み込み、権限一覧と危険コマンドのフラグを表示します。
triggers:
  - preflight
  - ユーザーがプリフライトチェックを依頼した場合
---

プロジェクトルートから `node ${CLAUDE_PLUGIN_ROOT}/scripts/preflight.js` を実行し、結果を表示します。
