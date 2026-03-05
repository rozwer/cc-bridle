---
name: cc-bridle plan-review-all
description: Review all phases from Plans.md in priority order (Required first, then Recommended).
triggers:
  - /cc-bridle plan-review-all
---

## What this skill does

1. Read Plans.md priority matrix
2. Sort phases: Required first, then Recommended
3. For each phase, invoke the plan-review skill
4. After each phase: "次のフェーズに進みますか？" — wait for confirmation before continuing

## Options

`--with-codex`: After user review of each phase, also submit the phase plan to Codex (via /harness-work or standalone) for AI review.

## Process flow

```
for each phase in priority order (Required → Recommended):
  1. Display: "--- Phase N のレビューを開始します ---"
  2. Run the plan-review skill for that phase
  3. When plan-review completes, display:
       "Phase N のレビューが完了しました。"
  4. If --with-codex flag is set:
       Submit phase-N.md to Codex for AI review via /harness-work
       Display Codex feedback summary
  5. Ask: "次のフェーズ（Phase M）に進みますか？"
  6. Wait for user confirmation (yes/no/skip)
     - yes: continue to next phase
     - no: stop the review session
     - skip: skip to the phase after next
```

## Completion

After all phases are reviewed:

```
全フェーズのレビューが完了しました。
レビュー済み: Phase X, Phase Y, ...
スキップ: Phase Z (if any)
```

## Notes

- If a phase-N.md does not yet exist, offer to run plan-split first
- Phases listed as "Complete" or "Done" in Plans.md are skipped by default
- Use the priority matrix in Plans.md to determine Required vs Recommended ordering
