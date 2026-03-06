---
name: githooks
description: Configure Claude Code-specific git guards via interactive wizard.
triggers:
  - githooks
  - user asks to configure git protection for Claude Code
---

## What this skill does

Configures protections for Claude Code's git operations.

These guards only apply when Claude Code executes git commands via the Bash tool.
Your own manual git commands (in terminal) are NOT affected.

## Procedure

### Step 1: Show current status

Run: `node ${CLAUDE_PLUGIN_ROOT}/scripts/git-guard-wizard.js --show`

This outputs JSON with all guard keys and their current enabled state.

### Step 2: Ask the user

Use AskUserQuestion with multiSelect=true to let the user pick which guards to enable.

Available guards:
- `block_force_push` — force push ブロック (git push --force / -f)
- `block_push_main` — main/master への直接 push ブロック
- `block_secret_files` — 機密ファイルのステージングをブロック (.env, *.key 等)
- `check_commit_message` — Conventional Commits 検証
- `block_large_files` — 1MB 超ファイルのステージングをブロック

Show current status to the user. Present a single multiSelect question with these as options.
Note: AskUserQuestion supports max 4 options, so split into 2 questions if needed
(e.g. question 1: force_push, push_main, secret_files; question 2: commit_message, large_files).

### Step 3: Apply settings

Build a comma-separated `key=on` / `key=off` string from user selections and run:

```
node ${CLAUDE_PLUGIN_ROOT}/scripts/git-guard-wizard.js --set key1=on,key2=off,...
```

### Step 4: Confirm

Show the saved configuration to the user.
