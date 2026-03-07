# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-03-06

### Changed

- **Multi-language plugin restructuring**: Moved from single root-level plugin to two independent plugins under `plugins/cc-bridle/` (English) and `plugins/cc-bridle-ja/` (Japanese).
- **marketplace.json**: Updated to reference both plugins.
- **Removed**: Root-level `skills/`, `plugin.json`, and `hooks.json` — each plugin now carries its own full directory structure.

### Added

- **plugins/cc-bridle-ja/**: Full Japanese translation of all 9 SKILL.md files with English `name` fields preserved for plugin system compatibility.

## [0.1.5] - 2026-03-05

### Added

- **scripts/session-probe.js**: New script that reads project context (CLAUDE.md, Plans.md) and env.json, then outputs a structured list of permission probe commands for Claude to execute at session start. Covers: Bash basic (`echo`), tmp file operations (`mktemp`), package manager version checks (`uv`, `bun`, `npm`, `pnpm`, `poetry`, `pip`), and git version check. Can be disabled via `~/.claude/cc-bridle/config.json` → `session_probe.enabled: false`.
- **hooks/session.sh**: Updated from passthrough (`exit 0`) to invoke `session-probe.js`, so permission warm-up directives are output to Claude's initial context on every SessionStart / Setup event.
- **tests/phase-session-probe.bats**: 14 new tests covering all probe conditions: always-on Bash probe, tmp probe (via `/tmp/` and `mktemp` detection), tool probes (uv/bun/npm), git probe (via git operation keywords), multi-tool env.json, disabled-via-config, and sequential numbering.

## [0.1.4] - 2026-03-05

### Fixed

- **danger-dict.json**: Added word boundary to `mkfs` pattern (`\bmkfs\b`) to prevent false positives when `mkfs` appears inside a path component or other word (e.g., `ls /mnt/mkfs_backup/`).

### Added

- **danger-dict.json**: Added `DROP\s+SCHEMA` as a critical pattern, equivalent in destructiveness to `DROP DATABASE`.
- **tests/phase-2-danger.bats**: Added 10 regression tests covering previously-untested patterns: `git push origin --force`, `git push origin -f`, `git push -f origin main`, safe `git push` (negative test), `rm -r -f`, `rm -f -r`, `rm -r` (warning level), `rm --recursive`, `DROP SCHEMA`, and `mkfs.ext4`.

## [0.1.3] - 2026-03-05

### Fixed

- **danger-dict.json**: Fixed false positive in `rm\\s+.*--recursive` — replaced `.*` with `[^;&|\n]*` so the pattern does not span shell operators (e.g., `rm /tmp/file && grep --recursive src/` no longer triggers).
- **danger-dict.json**: Added `rm\\s+-r\\b` as a warning-level pattern to catch standalone recursive deletion without force flag (previously uncovered).
- **danger-dict.json**: Extended git force-push patterns to cover remote-name forms — `git push origin --force` and `git push origin -f` were not matched by the previous patterns. Changed `git\\s+push\\s+--force` → `git\\s+push\\b[^;&|\\n]*--force` and `git\\s+push\\s+-f` → `git\\s+push\\b[^;&|\\n]*\\s-f\\b`.
- **README.md / README_ja.md**: Updated version badges from `0.1.2` to `0.1.3`.
- **CHANGELOG.md**: Corrected [0.1.2] entry — version was bumped to `0.1.2`, not `0.1.1` as previously written.
- **tests/phase-5-scan.bats**: Fixed test 5.0.3 to use `printf` instead of `echo` so `\n` produces actual newlines in the test fixture file.

## [0.1.2] - 2026-03-05

### Fixed

- **plugin.json / VERSION**: Bumped version field to `0.1.2` (was still `0.1.0` in plugin.json; VERSION also updated).
- **skill-scan**: Exit 1 now triggers only on HIGH/MEDIUM findings; LOW findings (e.g., `rm` in cleanup documentation) are informational and do not cause CI gate failure.
- **danger-dict.json**: Added `rm -r -f`, `rm -f -r` (split flag, any order) and changed `rm\s+--recursive` to `rm\s+.*--recursive` to cover `rm --force --recursive` and similar interleaved-flag forms.
- **pre-tool.sh**: Added stderr warning when `env-guard.js` is not found, so deployment errors are visible rather than silently bypassing env enforcement.
- **tests/phase-5-scan.bats**: Added test 5.0.6 (mixed clean/risky directory scan exits 1) and 5.0.7 (LOW-only findings exit 0) to cover the exit code change.
- **skills/scan/SKILL.md**: Documented exit code contract (0 = clean or LOW-only, 1 = HIGH/MEDIUM found or path error).

## [0.1.1] - 2026-03-05

### Fixed

- **skill-scan**: Fixed exit code — now exits 1 when any issue is detected (was always 0, making it useless as a CI gate).
- **danger-dict.json**: Added `rm -fr` and `rm --recursive` critical patterns to close bypass via flag-order reversal.
- **danger-dict.json**: Narrowed `TRUNCATE` to `TRUNCATE TABLE` to eliminate false positives from the Unix `truncate` utility.
- **preflight**: Narrowed `ネットワーク権限` detection from bare `http` to `https?://`, `fetch(`, `WebFetch`, `curl`, `wget`, `axios` — prevents any project file mentioning the word "http" from triggering the permission label.
- **plugin.json**: Removed non-existent `setup` skill from the skills array (no `skills/setup/` directory exists).
- **plugin.json**: Removed duplicate `install` field that incorrectly ran `skill-scan.js` as the install step; `install_command` (init.sh) is the sole install entry.
- **README.md / README_ja.md**: Removed `setup` skill row from the skills reference table.
- **post-tool.sh**: Added `|| true` to the `stats.js` invocation so a crash in stats does not abort the hook chain. Replaced `echo` with `printf '%s\n'` for safe JSON piping.
- **pre-tool.sh**: Added file-existence guard for `env-guard.js` (matching the existing guard for `git-guard.js`). Replaced all `echo "$INPUT"` with `printf '%s\n' "$INPUT"` to prevent accidental interpretation of flags in JSON.
- **docs/data-schema.md**: Corrected hash algorithm description from "MD5 (or SHA1)" to "MD5" (only MD5 is used in the implementation).

## [0.1.0] - 2026-03-05

### Added

- **danger-label**: PreToolUse hook that annotates dangerous Bash commands (rm -rf, git push --force, DROP TABLE, etc.) with 🔴 critical or 🟡 warning messages in Claude's permission dialog. Never blocks — always informs.
- **danger-dict.json**: Global dictionary of critical (10 patterns) and warning (5 patterns) regex patterns, case-insensitive. Supports project-specific overrides via `~/.claude/cc-bridle/projects/<cwd-hash>/danger-dict-extra.json`.
- **env-detect**: Stack detection engine supporting 14 stacks (python-uv, python-poetry, python-pip, node-bun, node-pnpm, node-yarn, node-npm, rust, go, docker, ruby, php, java, swift). Results saved to `~/.claude/cc-bridle/projects/<cwd-hash>/env.json`.
- **env-guard**: PreToolUse hook that blocks wrong package manager commands for the detected stack (e.g., pip install in a uv project). Exits 2 to block; provides `uv add` / `bun install` suggestions.
- **redirect-rules.json**: Redirect rules mapping wrong commands to correct alternatives, with capture group substitution support.
- **git-guard**: PreToolUse hook that blocks configurable git operation risks: force push, direct push to main/master, secret file staging (.env, *.key), Conventional Commits enforcement, large file blocking. Only affects Claude Code's Bash tool — never `.git/hooks/`.
- **git-guard-wizard**: Interactive CLI wizard to configure git-guard rules, saved to `~/.claude/cc-bridle/config.json`.
- **stats**: PostToolUse hook that appends `{tool, skill, subagent, exit_code, success, cwd_hash, timestamp, duration_ms}` to `~/.claude/cc-bridle/stats.jsonl`.
- **hook-timer**: Tracks hook execution duration, warns to stderr when exceeding configurable threshold (default 500ms), appends to `~/.claude/cc-bridle/hook-timer.jsonl`.
- **skill-scan**: Security scanner for SKILL.md files. Detects HIGH (eval/exec/shell injection/credentials), MEDIUM (file writes/network), LOW (file deletion) risks. Two-phase: static patterns + AI contextual review.
- **hooks-conflict**: Detects hook registration conflicts between plugins and proposes resolution strategies (priority merge or matcher rename).
- **preflight skill**: `/cc-bridle preflight` — reads CLAUDE.md and Plans.md to preview required permissions (Bash, file write, network, external services, package publish, tmp file access) and flag dangerous commands before a session.
- **stats skill**: `/cc-bridle stats` — aggregates stats.jsonl to show top tools, skill usage, failure rates, and optimization suggestions.
- **hook-timer skill**: `/cc-bridle hook-timer` — displays hook performance table with slow hook warnings.
- **scan skill**: `/cc-bridle scan <path>` — two-phase security scan of SKILL.md files.
- **githooks skill**: `/cc-bridle githooks` — runs the git-guard wizard.
- **add-stack skill**: `/cc-bridle add-stack <id>` — interactively adds custom stack detection rules globally or per-project.
- **plan-split skill**: `/cc-bridle plan-split` — auto-generates `docs/plans/phase-N.md` from Plans.md sections (skips existing files).
- **plan-review skill**: `/cc-bridle plan-review [file]` — reviews tasks one-by-one with intent explanation and the "意図を教えてください" confirmation option.
- **plan-review-all skill**: `/cc-bridle plan-review-all` — reviews all phases in priority order (Required → Recommended), with optional Codex integration.
- **init.sh**: Idempotent initializer for `~/.claude/cc-bridle/` data directory, creating JSONL files and default config.json.
- **hooks.json**: PreToolUse (Bash) → pre-tool.sh chain; PostToolUse (.*) → post-tool.sh chain; SessionStart/Setup → session.sh.
- **plugin.json**: Full marketplace metadata including author, repository, license, keywords, skills list, hooks summary.
- **docs/data-schema.md**: Complete schema documentation for all JSONL files and project-specific data.
- **CONTRIBUTING.md**: Development environment setup, directory structure, feature addition guide, test instructions, PR rules, and dictionary contribution guide.
