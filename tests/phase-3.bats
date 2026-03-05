#!/usr/bin/env bats
# phase-3.bats — Phase 3 acceptance tests for cc-bridle env-detect & env-guard

load helpers/common

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  setup_tmp_home
  # Create a temp project dir for each test
  TMP_PROJECT="$(mktemp -d /tmp/cc-bridle-project-XXXXXX)"
  # Resolve real path (macOS /tmp -> /private/tmp symlink)
  TMP_PROJECT="$(realpath "$TMP_PROJECT")"
}

teardown() {
  teardown_tmp_home
  if [ -n "${TMP_PROJECT:-}" ] && [ -d "$TMP_PROJECT" ]; then
    rm -rf "$TMP_PROJECT"
  fi
}

# Helper: compute cwd-hash exactly as Node.js does (uses node to avoid /tmp symlink issues)
cwd_hash() {
  local dir="$1"
  node -e "const crypto=require('crypto'); process.chdir('$dir'); console.log(crypto.createHash('md5').update(process.cwd()).digest('hex').slice(0,8));"
}

# Helper: run env-detect.js in a given directory with HOME set
run_env_detect() {
  local dir="$1"
  (cd "$dir" && HOME="$TMP_HOME" node "$REPO_ROOT/scripts/env-detect.js")
}

# Helper: read env.json for a given project dir
read_env_json() {
  local dir="$1"
  local hash
  hash=$(cwd_hash "$dir")
  cat "$TMP_HOME/.claude/cc-bridle/projects/$hash/env.json"
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1a env-detect: python-uv detection
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1a pyproject.toml + uv.lock => stack contains python-uv" {
  touch "$TMP_PROJECT/pyproject.toml"
  touch "$TMP_PROJECT/uv.lock"

  run_env_detect "$TMP_PROJECT"

  local env_json
  env_json=$(read_env_json "$TMP_PROJECT")
  echo "$env_json" | jq -e '.stack | contains(["python-uv"])'
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1b env-detect: node-bun detection
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1b package.json + bun.lockb => stack contains node-bun" {
  touch "$TMP_PROJECT/package.json"
  touch "$TMP_PROJECT/bun.lockb"

  run_env_detect "$TMP_PROJECT"

  local env_json
  env_json=$(read_env_json "$TMP_PROJECT")
  echo "$env_json" | jq -e '.stack | contains(["node-bun"])'
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1c env-detect: ruby detection
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1c Gemfile only => stack contains ruby" {
  touch "$TMP_PROJECT/Gemfile"

  run_env_detect "$TMP_PROJECT"

  local env_json
  env_json=$(read_env_json "$TMP_PROJECT")
  echo "$env_json" | jq -e '.stack | contains(["ruby"])'
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1d env-detect: empty dir => stack is []
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1d empty dir => stack is empty array" {
  run_env_detect "$TMP_PROJECT"

  local env_json
  env_json=$(read_env_json "$TMP_PROJECT")
  echo "$env_json" | jq -e '.stack | length == 0'
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1e env-detect: detect-rules-extra.json custom rule is picked up
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1e detect-rules-extra.json custom rule is picked up by env-detect" {
  # Create a custom file that the custom rule requires
  touch "$TMP_PROJECT/my-custom-marker.txt"

  # Compute hash and create the extra rules file
  local hash
  hash=$(cwd_hash "$TMP_PROJECT")
  local extra_dir="$TMP_HOME/.claude/cc-bridle/projects/$hash"
  mkdir -p "$extra_dir"
  printf '[{"id":"my-framework","files_all":["my-custom-marker.txt"],"files_any":[],"files_none":[]}]\n' \
    > "$extra_dir/detect-rules-extra.json"

  run_env_detect "$TMP_PROJECT"

  local env_json
  env_json=$(read_env_json "$TMP_PROJECT")
  echo "$env_json" | jq -e '.stack | contains(["my-framework"])'
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1f env-guard: pip install with python-uv stack => exit 2 (block)
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1f pip install requests with python-uv stack => env-guard exits 2" {
  # Set up env.json for the project dir by running env-detect
  touch "$TMP_PROJECT/pyproject.toml"
  touch "$TMP_PROJECT/uv.lock"
  run_env_detect "$TMP_PROJECT"

  # Run env-guard with pip install command — should exit 2
  local json='{"tool":"Bash","input":{"command":"pip install requests"}}'
  local guard_exit=0
  (cd "$TMP_PROJECT" && HOME="$TMP_HOME" printf '%s' "$json" | node "$REPO_ROOT/scripts/env-guard.js") \
    || guard_exit=$?

  [ "$guard_exit" -eq 2 ]
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1g env-guard: uv add requests with python-uv stack => exit 0 (allow)
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1g uv add requests with python-uv stack => env-guard exits 0 (allow)" {
  touch "$TMP_PROJECT/pyproject.toml"
  touch "$TMP_PROJECT/uv.lock"
  run_env_detect "$TMP_PROJECT"

  local json='{"tool":"Bash","input":{"command":"uv add requests"}}'
  local guard_exit=0
  (cd "$TMP_PROJECT" && HOME="$TMP_HOME" printf '%s' "$json" | node "$REPO_ROOT/scripts/env-guard.js") \
    || guard_exit=$?

  [ "$guard_exit" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────
# 3.3.1h env-guard: env.json missing => exits 0 (allow)
# ──────────────────────────────────────────────────────────────────────

@test "3.3.1h env.json missing => env-guard exits 0 (allow, no error)" {
  # No env.json — just run env-guard directly
  local json='{"tool":"Bash","input":{"command":"pip install requests"}}'
  local guard_exit=0
  (cd "$TMP_PROJECT" && HOME="$TMP_HOME" printf '%s' "$json" | node "$REPO_ROOT/scripts/env-guard.js") \
    || guard_exit=$?

  [ "$guard_exit" -eq 0 ]
}
