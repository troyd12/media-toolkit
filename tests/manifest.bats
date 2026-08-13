#!/usr/bin/env bats
# Repo-hygiene checks: the plugin manifest must match what is on disk, and
# every shipped script must be syntactically valid.

load test_helper

setup() { setup_common; }
teardown() { teardown_common; }

@test "plugin.json is valid JSON" {
  run node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$REPO_ROOT/.claude-plugin/plugin.json"
  [ "$status" -eq 0 ]
}

@test "every skill listed in plugin.json exists on disk with a SKILL.md" {
  run node -e '
    const fs = require("fs"), path = require("path");
    const root = process.argv[1];
    const manifest = JSON.parse(fs.readFileSync(path.join(root, ".claude-plugin/plugin.json"), "utf8"));
    for (const s of manifest.skills) {
      const dir = path.join(root, s);
      if (!fs.existsSync(dir)) { console.error("missing skill dir: " + s); process.exit(1); }
      if (!fs.existsSync(path.join(dir, "SKILL.md"))) { console.error("missing SKILL.md in: " + s); process.exit(1); }
    }
  ' "$REPO_ROOT"
  [ "$status" -eq 0 ]
}

@test "every generate.sh passes bash -n syntax check" {
  for script in "$SKILLS"/*/generate.sh; do
    run bash -n "$script"
    [ "$status" -eq 0 ] || { echo "syntax error in $script"; return 1; }
  done
}

@test "every generate.sh sets safe bash flags (set -euo pipefail)" {
  for script in "$SKILLS"/*/generate.sh; do
    grep -q 'set -euo pipefail' "$script" || { echo "missing 'set -euo pipefail' in $script"; return 1; }
  done
}

@test "every SKILL.md has a name and description front-matter field" {
  for skill in "$SKILLS"/*/SKILL.md; do
    grep -qE '^name:' "$skill" || { echo "missing name in $skill"; return 1; }
    grep -qE '^description:' "$skill" || { echo "missing description in $skill"; return 1; }
  done
}
