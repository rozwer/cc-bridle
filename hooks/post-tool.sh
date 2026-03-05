#!/usr/bin/env bash
# post-tool.sh — PostToolUse handler
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)"
INPUT=$(cat)
printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/stats.js" || true
printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/hook-timer.js" PostToolUse >/dev/null || true
exit 0
