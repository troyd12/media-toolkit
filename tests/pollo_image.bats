#!/usr/bin/env bats
# End-to-end tests for skills/pollo-image/generate.sh with the network mocked.

load test_helper

setup() {
  setup_common
  SCRIPT="$SKILLS/pollo-image/generate.sh"
  export MOCK_SUBMIT_FILE="$FIXTURES/image_submit.json"
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
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 1 ]
  [[ "$output" == *"API key not found"* ]]
}

@test "errors when the API key file is empty" {
  : > "$HOME/.pollo/key.txt"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 1 ]
  [[ "$output" == *"API key not found"* ]]
}

@test "succeeds: downloads the no-watermark PNG and prints its path" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/Desktop/pollo-img-task-123.png" ]]
  [ -f "$HOME/Desktop/pollo-img-task-123.png" ]
  # It must prefer the no-watermark URL.
  grep -q "result.png" "$MOCK_DOWNLOAD_LOG"
  ! grep -q "watermark.png" "$MOCK_DOWNLOAD_LOG"
}

@test "fails when submit returns no task id" {
  export MOCK_SUBMIT_FILE="$FIXTURES/submit_no_id.json"
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -ne 0 ]
  [[ "$output" == *"submit failed"* ]]
}

@test "fails when generation status is failed" {
  export MOCK_POLL_FILE="$FIXTURES/poll_failed.json"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 1 ]
  [[ "$output" == *"generation failed"* ]]
}

@test "fails when a succeeded job has no result URL" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed_no_url.json"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no URL in response"* ]]
}

@test "times out when the job never finishes" {
  export MOCK_POLL_FILE="$FIXTURES/poll_processing.json"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 1 ]
  [[ "$output" == *"timeout"* ]]
}

@test "default request body carries the documented defaults" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a red apple"
  [ "$status" -eq 0 ]
  body="$(cat "$MOCK_SUBMIT_BODY_LOG")"
  [[ "$body" == *'"modelName":"pollo-image-v2"'* ]]
  [[ "$body" == *'"mode":"professional"'* ]]
  [[ "$body" == *'"aspectRatio":"1:1"'* ]]
  [[ "$body" == *'"resolution":"2K"'* ]]
  [[ "$body" == *'"prompt":"a red apple"'* ]]
}

@test "positional args override the defaults in the request body" {
  export MOCK_POLL_FILE="$FIXTURES/poll_succeed.json"
  run bash "$SCRIPT" "a red apple" "16:9" "4K" "standard" "custom-model"
  [ "$status" -eq 0 ]
  body="$(cat "$MOCK_SUBMIT_BODY_LOG")"
  [[ "$body" == *'"modelName":"custom-model"'* ]]
  [[ "$body" == *'"mode":"standard"'* ]]
  [[ "$body" == *'"aspectRatio":"16:9"'* ]]
  [[ "$body" == *'"resolution":"4K"'* ]]
}
