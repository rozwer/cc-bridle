#!/usr/bin/env bats
# phase-2-preflight.bats — Phase 2.1 acceptance tests for preflight

load helpers/common

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
PREFLIGHT="$REPO_ROOT/scripts/preflight.js"

setup() {
  setup_tmp_home
  TMP_CWD="$(mktemp -d /tmp/cc-bridle-preflight-XXXXXX)"
}

teardown() {
  teardown_tmp_home
  rm -rf "$TMP_CWD"
}

@test "Plans.md with Bash keyword -> output contains Bash permission label" {
  echo "Use the Bash tool to run tests." > "$TMP_CWD/Plans.md"
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bash"* ]]
  [[ "$output" == *"Bash実行権限"* ]] || [[ "$output" == *"Bash"* ]]
}

@test "CLAUDE.md with git push -> output contains external service permission and danger warning" {
  echo "Run git push to deploy the app." > "$TMP_CWD/CLAUDE.md"
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"外部サービス権限"* ]]
  [[ "$output" == *"危険コマンド"* ]]
}

@test "Plans.md with rm -rf -> output contains critical 🔴 warning" {
  echo "Clean up with: rm -rf /tmp/build" > "$TMP_CWD/Plans.md"
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"🔴"* ]]
}

@test "missing CLAUDE.md and Plans.md -> no error, exit 0" {
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
}

@test "preflight always exits with code 0" {
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
}

@test "Plans.md with /tmp/ path -> output contains tmp permission label" {
  echo "Write output to /tmp/build-result.json for inspection." > "$TMP_CWD/Plans.md"
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tmpファイル作成・読み書き権限"* ]]
}

@test "Plans.md with mktemp -> output contains tmp permission label" {
  echo "Use mktemp to create a scratch file before processing." > "$TMP_CWD/Plans.md"
  run node "$PREFLIGHT" "$TMP_CWD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tmpファイル作成・読み書き権限"* ]]
}
