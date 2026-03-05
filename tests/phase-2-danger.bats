#!/usr/bin/env bats
# phase-2-danger.bats — Phase 2.0 acceptance tests for danger-label

load helpers/common

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
DANGER_LABEL="$REPO_ROOT/scripts/danger-label.js"

setup() {
  setup_tmp_home
}

teardown() {
  teardown_tmp_home
}

@test "rm -rf command triggers critical 🔴 warning, exit 0" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"rm -rf /tmp/test\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "git reset --hard triggers warning 🟡, exit 0" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"git reset --hard HEAD~1\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F7E1'* ]] || [[ "$output" == *"🟡"* ]]
}

@test "ls -la triggers no warning, exit 0, no message" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"ls -la\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" != *'"message"'* ]]
}

@test "GIT PUSH --FORCE (uppercase) triggers critical 🔴, exit 0 (case-insensitive)" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"GIT PUSH --FORCE\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "non-Bash tool passes through, exit 0, action allow" {
  run bash -c "echo '{\"tool\":\"Write\",\"input\":{\"command\":\"rm -rf /\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" != *'"message"'* ]]
}

@test "git push origin --force (with remote name) triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"git push origin --force\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "git push origin -f (short flag with remote) triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"git push origin -f\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "git push -f origin main (flag before remote) triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"git push -f origin main\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "git push origin feature-branch (no force) produces no warning" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"git push origin feature-branch\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" != *'"message"'* ]]
}

@test "rm -r -f (split flags) triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"rm -r -f /tmp/test\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "rm -f -r (reverse split flags) triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"rm -f -r /tmp/test\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "rm -r /path (no force, warning level) triggers warning 🟡 not critical" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"rm -r /tmp/mydir\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F7E1'* ]] || [[ "$output" == *"🟡"* ]]
  [[ "$output" != *$'\U0001F534'* ]] && [[ "$output" != *"🔴"* ]]
}

@test "rm --recursive /path triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"rm --recursive /home/user/data\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "DROP SCHEMA triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"psql -c \\\"DROP SCHEMA myschema CASCADE\\\"\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}

@test "mkfs.ext4 triggers critical 🔴" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"mkfs.ext4 /dev/sdb1\"}}' | node '$DANGER_LABEL'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"action":"allow"'* ]]
  [[ "$output" == *$'\U0001F534'* ]] || [[ "$output" == *"🔴"* ]]
}
