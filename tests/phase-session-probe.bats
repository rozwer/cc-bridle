#!/usr/bin/env bats
# phase-session-probe.bats — Acceptance tests for session-probe.js

load helpers/common

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
PROBE="$REPO_ROOT/scripts/session-probe.js"

setup() {
  setup_tmp_home
  TMP_CWD="$(mktemp -d /tmp/cc-bridle-probe-XXXXXX)"
}

teardown() {
  teardown_tmp_home
  rm -rf "$TMP_CWD"
}

# Helper: write env.json for a project CWD
write_env_json() {
  local cwd="$1"
  local content="$2"
  local hash
  hash=$(node -e "const c=require('crypto');const o=require('os');process.stdout.write(c.createHash('md5').update('$cwd').digest('hex').slice(0,8))")
  local dir="$HOME/.claude/cc-bridle/projects/$hash"
  mkdir -p "$dir"
  echo "$content" > "$dir/env.json"
}

@test "always outputs Bash basic probe" {
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *'echo "cc-bridle:ok"'* ]]
}

@test "always includes warmup header" {
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cc-bridle: セッション権限ウォームアップ"* ]]
}

@test "always exits with code 0" {
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
}

@test "Plans.md with /tmp/ -> includes tmp probe command" {
  echo "Write output to /tmp/result.json" > "$TMP_CWD/Plans.md"
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mktemp /tmp/.cc-bridle-XXXXXX"* ]]
}

@test "Plans.md with mktemp -> includes tmp probe command" {
  echo "Use mktemp to create a scratch file." > "$TMP_CWD/Plans.md"
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mktemp /tmp/.cc-bridle-XXXXXX"* ]]
}

@test "env.json with uv -> includes uv --version probe" {
  write_env_json "$TMP_CWD" '{"uv": true}'
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"uv --version"* ]]
}

@test "env.json with bun -> includes bun --version probe" {
  write_env_json "$TMP_CWD" '{"bun": true}'
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun --version"* ]]
}

@test "env.json with npm -> includes npm --version probe" {
  write_env_json "$TMP_CWD" '{"npm": true}'
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm --version"* ]]
}

@test "Plans.md with git push -> includes git --version probe" {
  echo "Run git push to deploy." > "$TMP_CWD/Plans.md"
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"git --version"* ]]
}

@test "CLAUDE.md with git commit -> includes git --version probe" {
  echo "After changes, git commit and push." > "$TMP_CWD/CLAUDE.md"
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"git --version"* ]]
}

@test "no context files -> only Bash probe (no tmp, no git)" {
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" != *"git --version"* ]]
  [[ "$output" != *"mktemp"* ]]
}

@test "disabled via config -> exits 0 with no output" {
  mkdir -p "$HOME/.claude/cc-bridle"
  echo '{"session_probe":{"enabled":false}}' > "$HOME/.claude/cc-bridle/config.json"
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "env.json with multiple tools -> all appear in output" {
  write_env_json "$TMP_CWD" '{"uv": true, "bun": true, "npm": true}'
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"uv --version"* ]]
  [[ "$output" == *"bun --version"* ]]
  [[ "$output" == *"npm --version"* ]]
}

@test "probes are numbered sequentially starting at 1" {
  run node "$PROBE" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1. [Bash基本]"* ]]
}
