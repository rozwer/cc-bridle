---
name: cc-bridle plan-review
description: Review a phase plan interactively, explaining each task and asking for confirmation.
triggers:
  - /cc-bridle plan-review [phase-N.md]
  - user asks to review requirements
  - user says "要件を確認して" or "これでよいか確認しながら進めて"
---

## What this skill does

1. If no argument given: read Plans.md, list uncompleted phases (cc:TODO), ask user to choose one
2. Read the target phase-N.md
3. For each task in the file:
   a. Explain the task: describe its intent, design rationale, and user impact
   b. Show options: "OK / 修正したい / 意図を教えてください"
   c. If user wants to modify: edit the task in place and confirm
   d. If user asks for intent: explain design decisions in detail
4. Review acceptance criteria one by one, offer to add missing ones
5. After all tasks: "Phase N の要件確認が完了しました"

## Key requirement

Always include "意図を教えてください" option in confirmation prompts. This allows users to understand the design reasoning behind each decision.

## Confirmation prompt format

When presenting each task, use this format:

```
## Task N.X.Y: <task title>

<Explain what this task does, why it was designed this way, and what impact it has on the user.>

これでよいですか？
  OK — 次のタスクへ
  修正したい — この場でタスク内容を編集します
  意図を教えてください — 設計判断の背景をさらに詳しく説明します
```

## Editing tasks

If the user selects "修正したい":
1. Show the current task text
2. Ask what they want to change
3. Apply the edit directly to phase-N.md
4. Confirm: "タスク N.X.Y を更新しました"

## Reviewing acceptance criteria

After all tasks, for each item in 受け入れ条件:
1. Read the criterion aloud
2. Ask: "この受け入れ条件は適切ですか？追加・修正はありますか？"
3. Apply any changes to phase-N.md
