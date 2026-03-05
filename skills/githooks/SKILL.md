---
name: cc-bridle githooks
description: Configure Claude Code-specific git guards via interactive wizard.
triggers:
  - /cc-bridle githooks
  - user asks to configure git protection for Claude Code
---

## What this skill does

Runs the git-guard wizard to configure protections for Claude Code's git operations.

These guards only apply when Claude Code executes git commands via the Bash tool.
Your own manual git commands (in terminal) are NOT affected.

## Usage

Run: `node scripts/git-guard-wizard.js`

After configuration, the settings are saved to `~/.claude/cc-bridle/config.json` under `git_guard`.

## Available Guards

1. **force push block** — Prevents `git push --force` / `-f`
2. **main/master push block** — Prevents direct push to main or master branch
3. **secret files block** — Prevents staging `.env`, `*.key`, `*.pem` files
4. **Conventional Commits** — Validates commit message format (feat:, fix:, etc.)
5. **large file block** — Prevents staging files over 1MB

All guards are OFF by default. Enable only what you need.
