#!/usr/bin/env bash
# pre-tool.sh — PreToolUse handler chain: env-guard -> git-guard -> danger-label
# Claude Code hook contract: allow = no output + exit 0, block = JSON + exit 2
# stderr is suppressed on all node calls to prevent Claude Code "hook error" labels
SCRIPT_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)" 2>/dev/null || exit 0

INPUT=$(cat 2>/dev/null) || INPUT=""

# env-guard (blocking — exits 2 on match, 0 on allow)
if [ -f "$SCRIPT_DIR/env-guard.js" ]; then
  GUARD_OUT=$(printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/env-guard.js" 2>/dev/null)
  GUARD_RC=$?
  if [ $GUARD_RC -ne 0 ] && [ -n "$GUARD_OUT" ]; then
    printf '%s\n' "$GUARD_OUT"
    exit $GUARD_RC
  fi
fi

# git-guard (blocking — exits 2 on match, 0 on allow)
if [ -f "$SCRIPT_DIR/git-guard.js" ]; then
  GIT_GUARD_OUT=$(printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/git-guard.js" 2>/dev/null)
  GIT_RC=$?
  if [ $GIT_RC -ne 0 ] && [ -n "$GIT_GUARD_OUT" ]; then
    printf '%s\n' "$GIT_GUARD_OUT"
    exit $GIT_RC
  fi
fi

# danger-label (non-blocking — outputs label JSON only when matched, silent on allow)
if [ -f "$SCRIPT_DIR/danger-label.js" ]; then
  LABEL_OUT=$(printf '%s\n' "$INPUT" | node "$SCRIPT_DIR/danger-label.js" 2>/dev/null) || true
  if [ -n "$LABEL_OUT" ]; then
    printf '%s\n' "$LABEL_OUT"
  fi
fi

exit 0
