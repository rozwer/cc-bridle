#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  TMP_HOME="$(mktemp -d /tmp/cc-bridle-git-test-XXXXXX)"
  export HOME="$TMP_HOME"
  mkdir -p "$TMP_HOME/.claude/cc-bridle"
}

teardown() {
  rm -rf "$TMP_HOME"
}

write_config() {
  cat > "$TMP_HOME/.claude/cc-bridle/config.json" <<EOF
{"git_guard":$1}
EOF
}

@test "6.0.2a force push blocked when guard enabled" {
  write_config '{"block_force_push":true}'
  run bash -c 'echo '"'"'{"tool":"Bash","input":{"command":"git push origin main --force"}}'"'"' | HOME='"$TMP_HOME"' node '"$REPO_ROOT"'/scripts/git-guard.js'
  [ "$status" -eq 2 ]
  echo "$output" | grep -q "GIT GUARD"
}

@test "6.0.2b force push allowed when guard disabled (default)" {
  write_config '{"block_force_push":false}'
  run bash -c 'echo '"'"'{"tool":"Bash","input":{"command":"git push origin main --force"}}'"'"' | HOME='"$TMP_HOME"' node '"$REPO_ROOT"'/scripts/git-guard.js'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"action":"allow"'
}

@test "6.0.2c normal git push to main allowed when only force push guard active" {
  write_config '{"block_force_push":true,"block_push_main":false}'
  run bash -c 'echo '"'"'{"tool":"Bash","input":{"command":"git push origin main"}}'"'"' | HOME='"$TMP_HOME"' node '"$REPO_ROOT"'/scripts/git-guard.js'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"action":"allow"'
}

@test "6.0.2d .env staging blocked when secret guard enabled" {
  write_config '{"block_secret_files":true}'
  run bash -c 'echo '"'"'{"tool":"Bash","input":{"command":"git add .env"}}'"'"' | HOME='"$TMP_HOME"' node '"$REPO_ROOT"'/scripts/git-guard.js'
  [ "$status" -eq 2 ]
}

@test "6.0.2e normal git commit allowed with all guards enabled" {
  write_config '{"block_force_push":true,"block_push_main":true,"block_secret_files":true,"check_commit_message":true,"block_large_files":true}'
  run bash -c 'echo '"'"'{"tool":"Bash","input":{"command":"git commit -m \"feat: add x\""}}'"'"' | HOME='"$TMP_HOME"' node '"$REPO_ROOT"'/scripts/git-guard.js'
  [ "$status" -eq 0 ]
}

@test "6.0.2f non-git command always allowed" {
  write_config '{"block_force_push":true}'
  run bash -c 'echo '"'"'{"tool":"Bash","input":{"command":"ls -la"}}'"'"' | HOME='"$TMP_HOME"' node '"$REPO_ROOT"'/scripts/git-guard.js'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"action":"allow"'
}
