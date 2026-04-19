#!/usr/bin/env bash
# Submit a text-to-image job to Pollo AI, poll until done, download PNG to Desktop.
# Usage: generate.sh "prompt" [aspectRatio] [resolution] [mode] [model]
# Defaults: 1:1, 2K, professional, pollo-image-v2

set -euo pipefail

PROMPT="${1:?prompt required as first arg}"
ASPECT="${2:-1:1}"
RES="${3:-2K}"
MODE="${4:-professional}"
MODEL="${5:-pollo-image-v2}"

KEY_FILE="${HOME}/.pollo/key.txt"
[ -s "$KEY_FILE" ] || { echo "ERROR: API key not found at $KEY_FILE. Run: notepad $KEY_FILE" >&2; exit 1; }
KEY=$(tr -d '\r\n \t' < "$KEY_FILE")

BASE="https://pollo.ai/api/platform"

BODY=$(node -e '
const [prompt, model, mode, aspect, res] = process.argv.slice(1);
console.log(JSON.stringify({
  sort: 0, language: "en",
  generationInput: { modelName: model, prompt, mode, aspectRatio: aspect, resolution: res }
}))' "$PROMPT" "$MODEL" "$MODE" "$ASPECT" "$RES")

echo "submitting..." >&2
SUBMIT=$(curl -sS -X POST "$BASE/generation/text2image" \
  -H "x-api-key: $KEY" -H "Content-Type: application/json" -d "$BODY")

ID=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const r=JSON.parse(d);if(!r.data?.id){console.error("submit failed:",d);process.exit(1)}console.log(r.data.id)})' <<< "$SUBMIT")
echo "taskId=$ID" >&2

for i in $(seq 1 30); do
  sleep 6
  R=$(curl -sS "$BASE/generation/$ID" -H "x-api-key: $KEY")
  STATUS=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{console.log(JSON.parse(d).data?.status||"?")}catch(e){console.log("err")}})' <<< "$R")
  echo "poll $i: $STATUS" >&2
  if [ "$STATUS" = "succeed" ]; then
    URL=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const v=JSON.parse(d).data?.videoList?.[0];console.log(v?.videoUrlNoWatermark||v?.videoUrl||"")})' <<< "$R")
    [ -n "$URL" ] || { echo "ERROR: no URL in response" >&2; exit 1; }
    OUT="${HOME}/Desktop/pollo-${ID}.png"
    curl -sS -o "$OUT" "$URL"
    echo "$OUT"
    exit 0
  fi
  if [ "$STATUS" = "failed" ] || [ "$STATUS" = "error" ]; then
    echo "ERROR: generation $STATUS. Raw: $R" >&2
    exit 1
  fi
done

echo "ERROR: timeout after 30 polls" >&2
exit 1
