#!/usr/bin/env bash
# Submit a text-to-video job to Pollo AI, poll until done, download MP4 to Desktop.
# Usage: generate.sh "prompt" [duration] [aspectRatio] [resolution] [model]
# Defaults: duration=5, aspect=16:9, resolution=480p, model=seedance-2-0

set -euo pipefail

PROMPT="${1:?prompt required as first arg}"
DURATION="${2:-5}"
ASPECT="${3:-16:9}"
RES="${4:-480p}"
MODEL="${5:-seedance-2-0}"

KEY_FILE="${HOME}/.pollo/key.txt"
[ -s "$KEY_FILE" ] || { echo "ERROR: API key not found at $KEY_FILE. Run: notepad $KEY_FILE" >&2; exit 1; }
KEY=$(tr -d '\r\n \t' < "$KEY_FILE")

BASE="https://pollo.ai/api/platform"

BODY=$(node -e '
const [prompt, model, aspect, res, duration] = process.argv.slice(1);
console.log(JSON.stringify({
  sort: 0, language: "en",
  generationInput: {
    videoModel: model,
    prompt,
    aspectRatio: aspect,
    resolution: res,
    length: Number(duration)
  }
}))' "$PROMPT" "$MODEL" "$ASPECT" "$RES" "$DURATION")

echo "submitting $MODEL ${DURATION}s ${ASPECT} ${RES}..." >&2
SUBMIT=$(curl -sS -X POST "$BASE/generation/text2video" \
  -H "x-api-key: $KEY" -H "Content-Type: application/json" -d "$BODY")

ID=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const r=JSON.parse(d);if(!r.data?.id){console.error("submit failed:",d);process.exit(1)}console.log(r.data.id)})' <<< "$SUBMIT")
echo "taskId=$ID" >&2

for i in $(seq 1 60); do
  sleep 8
  R=$(curl -sS "$BASE/generation/$ID" -H "x-api-key: $KEY")
  STATUS=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{console.log(JSON.parse(d).data?.status||"?")}catch(e){console.log("err")}})' <<< "$R")
  echo "poll $i: $STATUS" >&2
  if [ "$STATUS" = "succeed" ]; then
    URL=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const v=JSON.parse(d).data?.videoList?.[0];console.log(v?.videoUrlNoWatermark||v?.videoUrl||"")})' <<< "$R")
    [ -n "$URL" ] || { echo "ERROR: no URL in response" >&2; exit 1; }
    OUT="${HOME}/Desktop/pollovid-${ID}.mp4"
    curl -sS -o "$OUT" "$URL"
    echo "$OUT"
    exit 0
  fi
  if [ "$STATUS" = "failed" ] || [ "$STATUS" = "error" ]; then
    echo "ERROR: generation $STATUS. Raw: $R" >&2
    exit 1
  fi
done

echo "ERROR: timeout after 60 polls (~8 min)" >&2
exit 1
