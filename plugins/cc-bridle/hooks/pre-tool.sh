#!/usr/bin/env bash
# pre-tool.sh — PreToolUse handler chain: env-guard -> git-guard -> danger-label
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)"

INPUT=$(cat)

# env-guard (blocking — exits 2 on match, 0 on allow)
if [ -f "$SCRIPT_DIR/env-guard.js" ]; then
  GUARD_OUT=$(printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/env-guard.js")
  GUARD_EXIT=$?
  if [ $GUARD_EXIT -ne 0 ]; then
    printf '%s\n' "$GUARD_OUT"
    exit $GUARD_EXIT
  fi
else
  printf 'cc-bridle: env-guard.js not found — environment enforcement skipped\n' >&2
fi

# git-guard (blocking — exits 2 on match, 0 on allow)
if [ -f "$SCRIPT_DIR/git-guard.js" ]; then
  GIT_GUARD_OUT=$(printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/git-guard.js")
  GIT_GUARD_EXIT=$?
  if [ $GIT_GUARD_EXIT -ne 0 ]; then
    printf '%s\n' "$GIT_GUARD_OUT"
    exit $GIT_GUARD_EXIT
  fi
fi

# danger-label (non-blocking, always exit 0)
if [ -f "$SCRIPT_DIR/danger-label.js" ]; then
  printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/danger-label.js"
else
  printf '%s\n' '{"action":"allow"}'
fi
