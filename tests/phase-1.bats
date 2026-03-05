#!/usr/bin/env bats
# phase-1.bats — Phase 1 acceptance tests for cc-bridle project foundation

load helpers/common

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  setup_tmp_home
}

teardown() {
  teardown_tmp_home
}

@test "1.0.4 hooks/, skills/, scripts/ directories exist" {
  [ -d "$REPO_ROOT/hooks" ]
  [ -d "$REPO_ROOT/skills" ]
  [ -d "$REPO_ROOT/scripts" ]
}

@test "1.0.1 VERSION file exists and contains a semver string" {
  run cat "$REPO_ROOT/VERSION"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "1.2.1 hooks/hooks.json is valid JSON" {
  run jq . "$REPO_ROOT/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

@test "1.2.1 hooks/hooks.json has PreToolUse, PostToolUse, SessionStart, Setup" {
  run jq -e '.PreToolUse, .PostToolUse, .SessionStart, .Setup' "$REPO_ROOT/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

@test "1.0.5 plugin.json is valid JSON" {
  run jq . "$REPO_ROOT/plugin.json"
  [ "$status" -eq 0 ]
}

@test "1.1.2 init.sh creates ~/.claude/cc-bridle/ on first run" {
  run bash "$REPO_ROOT/scripts/init.sh"
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude/cc-bridle" ]
}

@test "1.1.2 init.sh is idempotent (second run succeeds)" {
  run bash "$REPO_ROOT/scripts/init.sh"
  [ "$status" -eq 0 ]
  run bash "$REPO_ROOT/scripts/init.sh"
  [ "$status" -eq 0 ]
}
