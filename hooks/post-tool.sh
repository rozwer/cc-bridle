#!/usr/bin/env bash
# post-tool.sh — PostToolUse handler (metrics only, never blocks)
# Claude Code hook contract: no stdout output = silent success
# stderr is suppressed to prevent Claude Code "hook error" labels
SCRIPT_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)" 2>/dev/null || exit 0

INPUT=$(cat 2>/dev/null) || INPUT=""
printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/stats.js" >/dev/null 2>&1 || true
printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/hook-timer.js" PostToolUse >/dev/null 2>&1 || true
exit 0
