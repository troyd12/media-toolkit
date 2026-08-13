#!/usr/bin/env bats
# Tests for skills/image-to-motion/generate.sh. ffmpeg is mocked, so these
# assert on the constructed filtergraph and control flow, not on rendered video.

load test_helper

# Every preset the script is supposed to implement.
CANONICAL_PRESETS="push-in pull-out pan-left pan-right pan-up pan-down ken-burns-1 ken-burns-2 drift-left drift-right"

setup() {
  setup_common
  SCRIPT="$SKILLS/image-to-motion/generate.sh"
  export MOCK_FFMPEG_ARGS="$FAKE_HOME/ffmpeg_args.log"
  IMG="$FAKE_HOME/in.png"
  printf 'not-a-real-png' > "$IMG"
}

teardown() { teardown_common; }

@test "requires an image path argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"image path required"* ]]
}

@test "errors when the image file does not exist" {
  run bash "$SCRIPT" "$FAKE_HOME/nope.png"
  [ "$status" -eq 1 ]
  [[ "$output" == *"image not found"* ]]
}

@test "rejects an unknown preset" {
  run bash "$SCRIPT" "$IMG" "spin-around"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown preset"* ]]
}

@test "every canonical preset builds a valid zoompan filtergraph" {
  for preset in $CANONICAL_PRESETS; do
    run bash "$SCRIPT" "$IMG" "$preset"
    [ "$status" -eq 0 ] || { echo "preset '$preset' failed: $output"; return 1; }
    grep -q "zoompan=" "$MOCK_FFMPEG_ARGS" || { echo "no zoompan for '$preset'"; return 1; }
  done
}

# Regression guard for the rotate-cw/rotate-ccw drift: every preset advertised
# in the script header comment must actually be implemented (i.e. must not be
# rejected as unknown).
@test "every preset documented in the header is implemented" {
  presets="$(sed -n '/^# Presets:/,/^set -/p' "$SCRIPT" | grep -oE '[a-z]+(-[a-z0-9]+)+')"
  [ -n "$presets" ]
  for preset in $presets; do
    run bash "$SCRIPT" "$IMG" "$preset"
    [ "$status" -eq 0 ] || { echo "documented preset '$preset' is not implemented"; return 1; }
  done
}

@test "defaults: push-in preset, 5s at 1920x1080 -> 150 frames" {
  run bash "$SCRIPT" "$IMG"
  [ "$status" -eq 0 ]
  vf="$(grep -A0 'zoompan=' "$MOCK_FFMPEG_ARGS")"
  [[ "$vf" == *"d=150"* ]]        # 5s * 30fps
  [[ "$vf" == *"s=1920x1080"* ]]
  [[ "$vf" == *"fps=30"* ]]
}

@test "duration and output size arguments flow into the filtergraph" {
  run bash "$SCRIPT" "$IMG" "pan-left" 3 1080x1920
  [ "$status" -eq 0 ]
  vf="$(grep 'zoompan=' "$MOCK_FFMPEG_ARGS")"
  [[ "$vf" == *"d=90"* ]]         # 3s * 30fps
  [[ "$vf" == *"s=1080x1920"* ]]
}

@test "output path is written under Desktop with the preset name" {
  run bash "$SCRIPT" "$IMG" "ken-burns-1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/Desktop/motion-ken-burns-1-"*.mp4 ]]
}
