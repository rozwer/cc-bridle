#!/usr/bin/env bash
# cc-bridle init.sh — idempotent setup of ~/.claude/cc-bridle/ data directory
set -euo pipefail

CC_BRIDLE_DIR="${HOME}/.claude/cc-bridle"
PROJECTS_DIR="${CC_BRIDLE_DIR}/projects"

mkdir -p "${PROJECTS_DIR}"

# Touch JSONL files only if they don't exist yet
touch_if_missing() {
  [ -f "$1" ] || touch "$1"
}

touch_if_missing "${CC_BRIDLE_DIR}/stats.jsonl"
touch_if_missing "${CC_BRIDLE_DIR}/hook-timer.jsonl"

# Write config.json with defaults only if it doesn't exist yet
CONFIG_FILE="${CC_BRIDLE_DIR}/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" <<'EOF'
{"auto_preflight":{"enabled":false,"trigger_skills":["harness-work","work"]}}
EOF
fi

echo "cc-bridle: initialized ${CC_BRIDLE_DIR}"
