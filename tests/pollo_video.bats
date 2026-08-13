#!/usr/bin/env bats
# End-to-end tests for skills/pollo-video/generate.sh with the network mocked.

load test_helper

setup() {
  setup_common
  SCRIPT="$SKILLS/pollo-video/generate.sh"
  export MOCK_SUBMIT_FILE="$FIXTURES/video_submit.json"
  export MOCK_DOWNLOAD_LOG="$FAKE_HOME/download.log"
  export MOCK_SUBMIT_BODY_LOG="$FAKE_HOME/submit_body.log"
}

teardown() { teardown_common; }

@test "requires a prompt argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"prompt required"* ]]
}

@test "errors when the API key file is missing" {
  rm -f "$HOME/.pollo/key.txt"
  run bash "$SCRIPT" "a drone shot over mountains"
  [ "$status" -eq 1 ]
  [[ "$output" == *"API key not found"* ]]
}

@test "succeeds: downloads the no-watermark MP4 and prints its path" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a drone shot over mountains"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/Desktop/pollovid-vid-task-456.mp4" ]]
  [ -f "$HOME/Desktop/pollovid-vid-task-456.mp4" ]
  grep -q "result.png" "$MOCK_DOWNLOAD_LOG"   # fixture reuses the same URL field
}

@test "fails when submit returns no task id" {
  export MOCK_SUBMIT_FILE="$FIXTURES/submit_no_id.json"
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a drone shot over mountains"
  [ "$status" -ne 0 ]
  [[ "$output" == *"submit failed"* ]]
}

@test "fails when generation status is failed" {
  export MOCK_POLL_FILE="$FIXTURES/poll_failed.json"
  run bash "$SCRIPT" "a drone shot over mountains"
  [ "$status" -eq 1 ]
  [[ "$output" == *"generation failed"* ]]
}

@test "default request body carries the documented defaults" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a drone shot over mountains"
  [ "$status" -eq 0 ]
  body="$(cat "$MOCK_SUBMIT_BODY_LOG")"
  [[ "$body" == *'"videoModel":"seedance-2-0"'* ]]
  [[ "$body" == *'"aspectRatio":"16:9"'* ]]
  [[ "$body" == *'"resolution":"480p"'* ]]
  [[ "$body" == *'"length":5'* ]]
}

@test "duration argument is serialized as a number, not a string" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a drone shot over mountains" 10
  [ "$status" -eq 0 ]
  body="$(cat "$MOCK_SUBMIT_BODY_LOG")"
  [[ "$body" == *'"length":10'* ]]
  [[ "$body" != *'"length":"10"'* ]]
}
