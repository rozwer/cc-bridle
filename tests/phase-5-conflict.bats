#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  TMP_DIR="$(mktemp -d /tmp/cc-bridle-conflict-test-XXXXXX)"
  mkdir -p "$TMP_DIR/plugin-a" "$TMP_DIR/plugin-b"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "5.1.1 same PreToolUse matcher triggers conflict" {
  echo '{"PreToolUse":[{"matcher":"Bash","command":"foo.sh"}]}' > "$TMP_DIR/plugin-a/hooks.json"
  echo '{"PreToolUse":[{"matcher":"Bash","command":"bar.sh"}]}' > "$TMP_DIR/plugin-b/hooks.json"
  run node "$REPO_ROOT/scripts/hooks-conflict.js" --new "$TMP_DIR/plugin-b/hooks.json" --existing "$TMP_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "CONFLICT\|conflict"
}

@test "5.1.2 different matchers Bash vs Read no conflict" {
  echo '{"PreToolUse":[{"matcher":"Bash","command":"foo.sh"}]}' > "$TMP_DIR/plugin-a/hooks.json"
  echo '{"PreToolUse":[{"matcher":"Read","command":"bar.sh"}]}' > "$TMP_DIR/plugin-b/hooks.json"
  run node "$REPO_ROOT/scripts/hooks-conflict.js" --new "$TMP_DIR/plugin-b/hooks.json" --existing "$TMP_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No hook conflicts"
}

@test "5.1.3 different events same matcher no conflict reported" {
  echo '{"PreToolUse":[{"matcher":"Bash","command":"foo.sh"}]}' > "$TMP_DIR/plugin-a/hooks.json"
  echo '{"PostToolUse":[{"matcher":"Bash","command":"bar.sh"}]}' > "$TMP_DIR/plugin-b/hooks.json"
  run node "$REPO_ROOT/scripts/hooks-conflict.js" --new "$TMP_DIR/plugin-b/hooks.json" --existing "$TMP_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "No hook conflicts"
}

@test "5.1.4 conflict output includes solution A and B" {
  echo '{"PreToolUse":[{"matcher":"Bash","command":"foo.sh"}]}' > "$TMP_DIR/plugin-a/hooks.json"
  echo '{"PreToolUse":[{"matcher":"Bash","command":"bar.sh"}]}' > "$TMP_DIR/plugin-b/hooks.json"
  run node "$REPO_ROOT/scripts/hooks-conflict.js" --new "$TMP_DIR/plugin-b/hooks.json" --existing "$TMP_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Resolution A"
  echo "$output" | grep -q "Resolution B"
}
