#!/usr/bin/env bash
# session.sh — SessionStart / Setup dispatcher
# Invokes session-probe.js to output permission warmup directives for Claude.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CWD="${1:-$(pwd)}"

node "$SCRIPT_DIR/../scripts/session-probe.js" "$CWD"
