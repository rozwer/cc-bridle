#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  TMP_DIR="$(mktemp -d /tmp/cc-bridle-scan-test-XXXXXX)"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "5.0.1 eval in SKILL.md triggers HIGH risk" {
  echo 'Use eval to run: eval "$CMD"' > "$TMP_DIR/SKILL.md"
  run node "$REPO_ROOT/scripts/skill-scan.js" "$TMP_DIR/SKILL.md"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "HIGH"
}

@test "5.0.2 fetch in SKILL.md triggers MEDIUM risk" {
  echo 'Use fetch to call API: fetch("https://api.example.com")' > "$TMP_DIR/SKILL.md"
  run node "$REPO_ROOT/scripts/skill-scan.js" "$TMP_DIR/SKILL.md"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "MEDIUM"
}

@test "5.0.3 clean SKILL.md produces clean report" {
  printf '# My Skill\nDo something safe.\nAsk user before proceeding.\n' > "$TMP_DIR/SKILL.md"
  run node "$REPO_ROOT/scripts/skill-scan.js" "$TMP_DIR/SKILL.md"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Clean"
}

@test "5.0.4 non-existent path gives error message" {
  run node "$REPO_ROOT/scripts/skill-scan.js" "/nonexistent/path/SKILL.md"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "not found\|error"
}

@test "5.0.5 directory scan finds multiple SKILL.md files" {
  mkdir -p "$TMP_DIR/skill-a" "$TMP_DIR/skill-b"
  echo '# Safe skill' > "$TMP_DIR/skill-a/SKILL.md"
  echo '# Safe skill' > "$TMP_DIR/skill-b/SKILL.md"
  run node "$REPO_ROOT/scripts/skill-scan.js" "$TMP_DIR"
  [ "$status" -eq 0 ]
  # Should scan both files (two "SKILL SCAN:" lines)
  count=$(echo "$output" | grep -c "SKILL SCAN:" || true)
  [ "$count" -ge 2 ]
}

@test "5.0.6 directory scan with one risky and one clean file exits 1" {
  mkdir -p "$TMP_DIR/skill-risky" "$TMP_DIR/skill-clean"
  echo 'eval "$CMD"' > "$TMP_DIR/skill-risky/SKILL.md"
  echo '# Safe skill' > "$TMP_DIR/skill-clean/SKILL.md"
  run node "$REPO_ROOT/scripts/skill-scan.js" "$TMP_DIR"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "HIGH"
}

@test "5.0.7 LOW-only findings (rm) produce exit 0" {
  echo 'Run rm to clean temp files after processing.' > "$TMP_DIR/SKILL.md"
  run node "$REPO_ROOT/scripts/skill-scan.js" "$TMP_DIR/SKILL.md"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "LOW"
}
