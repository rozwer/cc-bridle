#!/usr/bin/env bats
# phase-8.bats — Plan split tests

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  TMP_DIR="$(mktemp -d /tmp/cc-bridle-phase8-XXXXXX)"
  # Create a minimal Plans.md with a Phase 9
  cat > "$TMP_DIR/Plans.md" <<'EOF'
# Test Plans

## Phase 9: Test Phase
| Task | Content | Status |
|------|---------|--------|
| 9.0.1 | Do something | cc:TODO |

EOF
  mkdir -p "$TMP_DIR/docs/plans"
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "8.0 skills/plan-split/SKILL.md exists" {
  [ -f "$REPO_ROOT/skills/plan-split/SKILL.md" ]
}

@test "8.1 skills/plan-review/SKILL.md exists" {
  [ -f "$REPO_ROOT/skills/plan-review/SKILL.md" ]
}

@test "8.2 skills/plan-review-all/SKILL.md exists" {
  [ -f "$REPO_ROOT/skills/plan-review-all/SKILL.md" ]
}

@test "8.0 scripts/plan-template.md exists with required sections" {
  [ -f "$REPO_ROOT/scripts/plan-template.md" ]
  grep -q "受け入れ条件" "$REPO_ROOT/scripts/plan-template.md"
  grep -q "cc:TODO" "$REPO_ROOT/scripts/plan-template.md"
  grep -q "300行" "$REPO_ROOT/scripts/plan-template.md"
}

@test "8.1 skills/plan-review/SKILL.md contains ito-wo-oshiete-kudasai option" {
  grep -q "意図を教えてください" "$REPO_ROOT/skills/plan-review/SKILL.md"
}
