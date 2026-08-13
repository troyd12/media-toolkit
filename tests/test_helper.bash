# Shared setup for all bats suites.
#
# Provides an isolated fake HOME, puts tests/mock_bin on the front of PATH
# (so curl / sleep / ffmpeg are intercepted), and exposes fixture paths.

setup_common() {
  TESTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  REPO_ROOT="$( cd "$TESTS_DIR/.." && pwd )"
  FIXTURES="$TESTS_DIR/fixtures"
  SKILLS="$REPO_ROOT/skills"

  # Intercept curl / sleep / ffmpeg with the mocks.
  PATH="$TESTS_DIR/mock_bin:$PATH"

  # Isolated HOME so the scripts read a fake key file and write to a
  # throwaway Desktop instead of the real one.
  FAKE_HOME="$(mktemp -d)"
  HOME="$FAKE_HOME"
  export HOME
  mkdir -p "$HOME/.pollo" "$HOME/Desktop"
  printf 'test-key-abc123' > "$HOME/.pollo/key.txt"

  export TESTS_DIR REPO_ROOT FIXTURES SKILLS FAKE_HOME
}

teardown_common() {
  [ -n "${FAKE_HOME:-}" ] && rm -rf "$FAKE_HOME"
}
