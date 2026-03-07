---
name: plan-review-all
description: Plans.md の全フェーズを優先度順にレビューします（Required を先に、次に Recommended）。
triggers:
  - plan-review-all
---

## このスキルの機能

1. Plans.md の優先度マトリクスを読み込む
2. フェーズを並び替え: Required を先に、次に Recommended
3. 各フェーズに対して plan-review スキルを実行
4. 各フェーズ完了後: 「次のフェーズに進みますか？」 — 確認を待ってから続行

## オプション

`--with-codex`: ユーザーによる各フェーズのレビュー後、そのフェーズ計画を Codex（/harness-work またはスタンドアロン経由）にも送信して AI レビューを行います。

## 処理フロー

```
優先度順（Required → Recommended）で各フェーズを処理:
  1. 表示: "--- Phase N のレビューを開始します ---"
  2. そのフェーズの plan-review スキルを実行
  3. plan-review 完了後に表示:
       "Phase N のレビューが完了しました。"
  4. --with-codex フラグが設定されている場合:
       phase-N.md を /harness-work 経由で Codex に送信して AI レビュー
       Codex フィードバックの概要を表示
  5. 確認: "次のフェーズ（Phase M）に進みますか？"
  6. ユーザーの確認を待つ（yes/no/skip）
     - yes: 次のフェーズへ進む
     - no: レビューセッションを終了
     - skip: 次の次のフェーズへスキップ
```

## 完了時

全フェーズのレビューが完了したら:

```
全フェーズのレビューが完了しました。
レビュー済み: Phase X, Phase Y, ...
スキップ: Phase Z（ある場合）
```

## 注意事項

- phase-N.md がまだ存在しない場合は、最初に plan-split の実行を提案する
- Plans.md で「Complete」または「Done」とマークされたフェーズはデフォルトでスキップされる
- Plans.md の優先度マトリクスを使用して Required と Recommended の順序を決定する
