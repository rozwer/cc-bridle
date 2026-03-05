# cc-bridle

![Version](https://img.shields.io/badge/version-0.1.5-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-passing-brightgreen)

**A "bridle" for Claude Code — guides without blocking.**

Claude Code is powerful, but it can silently run `rm -rf` or use `pip install` in a `uv` project. cc-bridle warns before dangerous operations, prevents tech stack misuse, and gives you visibility into tool usage.

Designed to coexist with [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) — both plugins share hooks without conflict.

---

## Before / After

<table>
<tr><th>Scenario</th><th>Without cc-bridle</th><th>With cc-bridle</th></tr>
<tr>
<td><strong>Destructive<br>command</strong></td>
<td>

```
✓ Bash: rm -rf ./node_modules
```

</td>
<td>

```
🔴 DANGER: rm -rf detected.
   Are you sure?
[Allow] [Deny]
```

</td>
</tr>
<tr>
<td><strong>Wrong package<br>manager</strong></td>
<td>

```
✓ Bash: pip install requests
  # Bypasses uv's lockfile
```

</td>
<td>

```
🚫 ENV GUARD: This is a uv project
  × pip install requests
  → uv add requests
```

</td>
</tr>
</table>

---

## Features

### Guards (block execution)

| Feature | Behavior |
|---------|----------|
| 🛡️ **env-guard** | Auto-detects your project's tech stack (uv / bun / pnpm / poetry and 14 stacks total) and **blocks** the wrong package manager. Suggests the correct command via `redirect-rules.json` with capture group support for argument passthrough (e.g. `pip install foo` → `uv add foo`). |
| 🔐 **git-guard** | Applies 4 configurable guards to Claude Code's git operations: **force push prevention**, **direct push to main/master prevention**, **secret file staging prevention** (.env, .key, .pem, etc.), and **Conventional Commits enforcement**. Each guard is individually togglable in `config.json`. Your manual git commands are **completely unaffected** (no `.git/hooks/` changes). |

### Monitors (warn & record)

| Feature | Behavior |
|---------|----------|
| 🔴 **danger-label** | Detects destructive commands (`rm -rf`, `git push --force`, `DROP TABLE`, `DROP SCHEMA`, `mkfs`, etc.) via regex and adds 🔴 CRITICAL / 🟡 WARNING labels to Claude's permission dialog. **Never blocks** (always returns `action: 'allow'`). Patterns are extensible via global `danger-dict.json` + per-project `danger-dict-extra.json`. |
| 📊 **stats** | Records every tool invocation (tool name, exit code, success/failure, duration) to `stats.jsonl`. Tracks `Skill` tool calls by skill name and `Agent` tool calls by subagent type. `/cc-bridle stats` shows usage frequency, failure rates, and optimization hints. |
| ⏱️ **hook-timer** | Measures each hook's execution time and warns to stderr when it exceeds the threshold (default 500ms, configurable in `config.json`). History is stored in `hook-timer.jsonl`; use `/cc-bridle hook-timer` to identify bottlenecks. |

### Diagnostics & analysis

| Feature | Behavior |
|---------|----------|
| 🔍 **skill-scan** | Recursively scans SKILL.md files for shell injection, `eval`/`exec`, credential access (🔴 HIGH), file writes, external network calls (🟡 MEDIUM), and file deletion (🔵 LOW). **Exits 1 on HIGH/MEDIUM findings, acting as a CI gate.** LOW-only findings exit 0. |
| 🔌 **hooks-conflict** | Compares hooks.json files across 5 events (PreToolUse / PostToolUse / SessionStart / Setup / UserPromptSubmit) and detects same-matcher collisions. **On conflict, proposes 2 resolution strategies**: ① priority merge (recommended) ② matcher rename. |
| 🚀 **preflight** | Parses CLAUDE.md and Plans.md to detect **6 permission types** needed for the session (Bash execution, file writes, network, external services, package publishing, tmp file operations). Simultaneously matches all danger-dict patterns against planned commands and reports them as 🔴/🟡. Works with **session-probe** to auto-generate warmup commands (`echo`, `mktemp`, `uv --version`, etc.) at session start, pre-triggering permission dialogs so they don't interrupt your workflow. |

### Plan management

| Feature | Behavior |
|---------|----------|
| 📋 **plan-split** | Splits `Plans.md` `## Phase N:` sections into individual `docs/plans/phase-N.md` files. Skips existing files (never overwrites). Generated files include creation date, purpose, dependencies, task tables with `cc:TODO` markers, and acceptance criteria checklists. |
| 📝 **plan-review** | Walks through each task in a phase file one by one, presenting 3 options: **OK / Edit / Explain intent**. Edits are saved to the phase file in place. Acceptance criteria are also reviewed individually and can be modified on the spot. |

---

## Install

```bash
# Plugin manager (recommended)
claude plugin install cc-bridle

# Or manually
git clone https://github.com/your-org/cc-bridle ~/.claude/plugins/cc-bridle
bash ~/.claude/plugins/cc-bridle/scripts/init.sh
```

For manual install, add `"plugins": ["cc-bridle"]` to `~/.claude/settings.json`.

---

## Skills (commands)

| Command | Description |
|---------|-------------|
| `/cc-bridle preflight` | Permission requirements + dangerous command preview |
| `/cc-bridle stats` | Usage statistics and optimization hints |
| `/cc-bridle hook-timer` | Hook performance report |
| `/cc-bridle scan <path>` | SKILL.md security scan (CI gate) |
| `/cc-bridle githooks` | Git guard configuration wizard |
| `/cc-bridle add-stack <id>` | Add custom stack detection rule |
| `/cc-bridle plan-split` | Split Plans.md into phase files |
| `/cc-bridle plan-review [file]` | Interactive task + acceptance criteria review |
| `/cc-bridle plan-review-all` | Review all phases in priority order |

---

## Coexisting with other plugins

**claude-code-harness** — Uses the same hook format. Run `hooks-conflict.js` to check for collisions and get resolution suggestions. Recommended: chain cc-bridle guards before harness hooks.

**Skill Evolver / skill-usage-tracker** — Different storage locations (`~/.claude/cc-bridle/` vs SQLite / `~/.claude/activity-logs/`), so no conflicts. All three can run simultaneously.

---

## License

MIT © 2026
