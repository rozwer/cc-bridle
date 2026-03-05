---
name: cc-bridle plan-split
description: Auto-split Plans.md into individual phase-N.md files in docs/plans/. Only creates files that don't exist yet.
triggers:
  - /cc-bridle plan-split
  - user asks to split Plans.md
  - user says "フェーズファイルを作って" or "Plans.md を分割して"
---

## What this skill does

1. Read Plans.md and extract all `## Phase N:` sections
2. For each phase, check if `docs/plans/phase-N.md` already exists
3. For phases without a file, generate a phase-N.md following the harness format:
   - Created date
   - Origin (起点)
   - Purpose (目的)
   - Dependencies (依存)
   - Sub-phases with task tables (cc:TODO markers)
   - Acceptance criteria checklist
4. Append a link to Plans.md for the new phase: `[phase-N.md](docs/plans/phase-N.md)`
5. Report: "Phase N のファイルを生成しました: docs/plans/phase-N.md"

## Format for generated phase-N.md

```
# Phase N: <title>

作成日: <today>
起点: <inferred from task descriptions>
目的: <inferred from task descriptions>

依存: <from priority matrix>

---

## Phase N.0: <first sub-phase>

| Task | 内容 | Status |
|------|------|--------|
| N.0.1 | <extracted from Plans.md> | cc:TODO |

---

## 受け入れ条件

- [ ] <key acceptance criteria>
```

Keep generated files under 300 lines.

## Rules

- Never overwrite a phase-N.md that already exists
- Infer 起点 and 目的 from the task descriptions in the Plans.md section
- Extract sub-phases from nested headings or task groupings when present
- Use `scripts/plan-template.md` as the quality standard reference
- After generating all files, summarize: list created files and skipped (already-existing) files
