#!/usr/bin/env bats
# phase-4.bats — Phase 4 acceptance tests for cc-bridle statistics & monitoring

load helpers/common

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
STATS_JS="$REPO_ROOT/scripts/stats.js"
HOOK_TIMER_JS="$REPO_ROOT/scripts/hook-timer.js"

setup() {
  setup_tmp_home
}

teardown() {
  teardown_tmp_home
}

# ---------------------------------------------------------------------------
# 4.0.1 stats.js — exit_code:0 → success:true
# ---------------------------------------------------------------------------
@test "4.0.1 stats.js records success:true for exit_code:0" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"ls\"},\"output\":{\"exit_code\":0}}' | HOME=\"$TMP_HOME\" node \"$STATS_JS\""
  [ "$status" -eq 0 ]
  stats_file="$TMP_HOME/.claude/cc-bridle/stats.jsonl"
  [ -f "$stats_file" ]
  run node -e "
    const fs = require('fs');
    const line = fs.readFileSync('$stats_file', 'utf8').trim().split('\n')[0];
    const r = JSON.parse(line);
    process.exit(r.success === true ? 0 : 1);
  "
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 4.0.2 stats.js — exit_code:1 → success:false
# ---------------------------------------------------------------------------
@test "4.0.2 stats.js records success:false for exit_code:1" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"false\"},\"output\":{\"exit_code\":1}}' | HOME=\"$TMP_HOME\" node \"$STATS_JS\""
  [ "$status" -eq 0 ]
  stats_file="$TMP_HOME/.claude/cc-bridle/stats.jsonl"
  [ -f "$stats_file" ]
  run node -e "
    const fs = require('fs');
    const line = fs.readFileSync('$stats_file', 'utf8').trim().split('\n')[0];
    const r = JSON.parse(line);
    process.exit(r.success === false ? 0 : 1);
  "
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 4.0.3 stats.js — Agent tool → subagent:true
# ---------------------------------------------------------------------------
@test "4.0.3 stats.js records subagent:true for Agent tool" {
  run bash -c "echo '{\"tool\":\"Agent\",\"input\":{\"prompt\":\"do something\"},\"output\":{\"exit_code\":0}}' | HOME=\"$TMP_HOME\" node \"$STATS_JS\""
  [ "$status" -eq 0 ]
  stats_file="$TMP_HOME/.claude/cc-bridle/stats.jsonl"
  [ -f "$stats_file" ]
  run node -e "
    const fs = require('fs');
    const line = fs.readFileSync('$stats_file', 'utf8').trim().split('\n')[0];
    const r = JSON.parse(line);
    process.exit(r.subagent === true ? 0 : 1);
  "
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 4.0.4 stats.jsonl entry has cwd_hash field
# ---------------------------------------------------------------------------
@test "4.0.4 stats.jsonl entry has cwd_hash field" {
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"ls\"},\"output\":{\"exit_code\":0}}' | HOME=\"$TMP_HOME\" node \"$STATS_JS\""
  [ "$status" -eq 0 ]
  stats_file="$TMP_HOME/.claude/cc-bridle/stats.jsonl"
  [ -f "$stats_file" ]
  run node -e "
    const fs = require('fs');
    const line = fs.readFileSync('$stats_file', 'utf8').trim().split('\n')[0];
    const r = JSON.parse(line);
    // cwd_hash must be an 8-char hex string
    const valid = typeof r.cwd_hash === 'string' && /^[0-9a-f]{8}$/.test(r.cwd_hash);
    process.exit(valid ? 0 : 1);
  "
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 4.1.1 hook-timer.js — duration > threshold writes warning to stderr
# ---------------------------------------------------------------------------
@test "4.1.1 hook-timer.js warns to stderr when duration exceeds threshold" {
  # Use threshold -1 so that duration_ms (>= 0) always exceeds it, guaranteeing the warning fires.
  mkdir -p "$TMP_HOME/.claude/cc-bridle"
  echo '{"hook_timer_threshold_ms":-1}' > "$TMP_HOME/.claude/cc-bridle/config.json"

  # Capture stderr directly; bats run merges stderr into $output by default
  run bash -c "echo '{\"tool\":\"Bash\",\"input\":{\"command\":\"ls\"}}' | HOME=\"$TMP_HOME\" node \"$HOOK_TIMER_JS\" PreToolUse 2>&1"
  [ "$status" -eq 0 ]
  # $output should contain the HOOK SLOW warning (stderr merged into stdout via 2>&1)
  [[ "$output" == *"HOOK SLOW"* ]]
}

# ---------------------------------------------------------------------------
# 4.1.2 hook-timer.js — fast run (threshold very high) → no stderr warning
# ---------------------------------------------------------------------------
@test "4.1.2 hook-timer.js no warning for fast run under high threshold" {
  # Set threshold to a very high value so hook-timer never exceeds it
  mkdir -p "$TMP_HOME/.claude/cc-bridle"
  echo '{"hook_timer_threshold_ms":999999}' > "$TMP_HOME/.claude/cc-bridle/config.json"

  # Run with stderr captured separately
  actual_stderr=$(echo '{"tool":"Bash","input":{"command":"ls"}}' | HOME="$TMP_HOME" node "$HOOK_TIMER_JS" PostToolUse 2>&1 >/dev/null)
  [ -z "$actual_stderr" ]
}
