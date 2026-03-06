---
name: add-stack
description: プロジェクトまたはグローバルの detect-rules-extra.json にカスタムスタック検知ルールを追加します。
triggers:
  - add-stack <stack-id>
  - ユーザーが新しいスタックやプロジェクトタイプの検知を依頼した場合
---

## 使い方

このスキルが呼び出されたら、以下の項目を対話的に確認します：
1. スタック ID（例: "my-framework"）
2. すべて存在する必要があるファイル (files_all)、カンマ区切り
3. いずれか1つ以上存在するファイル (files_any)、カンマ区切り（任意）
4. 存在してはならないファイル (files_none)、カンマ区切り（任意）
5. スコープ: グローバル (detect-rules.json) またはプロジェクト固有 (detect-rules-extra.json)

確認後、新しいルールを対象ファイルに追記して完了を報告します。
