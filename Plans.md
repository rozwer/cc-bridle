# [cc-bridle] Plans.md

作成日: 2026-03-05

> **コンセプト**: Claude Code 使用時のストレスを軽減する OSS プラグイン。
> harness（claude-code-harness）と同形式・共存前提。
> 命名由来: 馬具の轡（bridle）= harness の相棒、方向制御・暴走防止。

---

## 優先度マトリクス

| 優先度 | Phase | 内容 | タスク数 | 依存 | 詳細 |
|--------|-------|------|----------|------|------|
| **Required** | 1 | プロジェクト基盤 | 10 | なし | [phase-1.md](docs/plans/phase-1.md) |
| **Required** | 2 | 安全ガード系 | 7 | 1 | [phase-2.md](docs/plans/phase-2.md) |
| **Required** | 3 | 環境検知 & 誤誘導防止 | 7 | 1 | [phase-3.md](docs/plans/phase-3.md) |
| **Required** | 4 | 統計・モニタリング | 8 | 1 | [phase-4.md](docs/plans/phase-4.md) |
| **Recommended** | 5 | プラグイン管理 | 7 | 2,3,4 | [phase-5.md](docs/plans/phase-5.md) |
| **Recommended** | 6 | git hooks ウィザード | 5 | 2 | [phase-6.md](docs/plans/phase-6.md) |
| **Required** | 7 | ドキュメント・リリース | 9 | 全Phase | [phase-7.md](docs/plans/phase-7.md) |
| **Required** | 8 | Plan分割 & ユーザーレビュースキル | 8 | 1 | [phase-8.md](docs/plans/phase-8.md) |
| **Required** | 9 | 日英2プラグイン化 | 8 | 全Phase | [phase-9.md](docs/plans/phase-9.md) |

合計: **69 タスク**

---

## 全体進捗

| Phase | Status |
|-------|--------|
| Phase 1: プロジェクト基盤 | cc:完了 |
| Phase 2: 安全ガード系 | cc:完了 |
| Phase 3: 環境検知 & 誤誘導防止 | cc:完了 |
| Phase 4: 統計・モニタリング | cc:完了 |
| Phase 5: プラグイン管理 | cc:完了 |
| Phase 6: git hooks ウィザード | cc:完了 |
| Phase 7: ドキュメント・リリース | cc:完了 |
| Phase 8: Plan分割 & ユーザーレビュースキル | cc:完了 |
| Phase 9: 日英2プラグイン化 | cc:完了 |
