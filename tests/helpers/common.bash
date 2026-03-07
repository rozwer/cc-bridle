# common.bash — shared test helpers for cc-bridle bats test suite

# Creates a temporary HOME directory and sets HOME to it.
# Call in setup() of your bats file.
setup_tmp_home() {
  TMP_HOME="$(mktemp -d /tmp/cc-bridle-test-XXXXXX)"
  export HOME="$TMP_HOME"
}

# Removes the temporary HOME directory created by setup_tmp_home.
# Call in teardown() of your bats file.
teardown_tmp_home() {
  if [ -n "${TMP_HOME:-}" ] && [ -d "$TMP_HOME" ]; then
    rm -rf "$TMP_HOME"
  fi
}
