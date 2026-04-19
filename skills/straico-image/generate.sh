#!/usr/bin/env bash
# Submit a text-to-image job to Straico, download PNG to Desktop.
# Synchronous — no polling.
# Usage: generate.sh "prompt" [size] [variations] [model]
# Defaults: size=landscape, variations=1, model=flux/1.1
# Sizes: square | landscape | portrait

set -euo pipefail

PROMPT="${1:?prompt required as first arg}"
SIZE="${2:-landscape}"
VARS="${3:-1}"
MODEL="${4:-flux/1.1}"

KEY_FILE="${HOME}/.straico/key.txt"
[ -s "$KEY_FILE" ] || { echo "ERROR: Straico key not found at $KEY_FILE. Run: notepad $KEY_FILE" >&2; exit 1; }
KEY=$(cat "$KEY_FILE")

BASE="https://api.straico.com"

BODY=$(node -e '
const [prompt, model, size, variations] = process.argv.slice(1);
console.log(JSON.stringify({
  model, description: prompt, size, variations: Number(variations)
}))' "$PROMPT" "$MODEL" "$SIZE" "$VARS")

echo "submitting $MODEL $SIZE x$VARS..." >&2
R=$(curl -sS -X POST "$BASE/v1/image/generation" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d "$BODY")

# Parse
IMGS_JSON=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const r=JSON.parse(d);if(!r.success){console.error("failed:",d);process.exit(1)}console.log(JSON.stringify({images:r.data.images||[],price:r.data.price,zip:r.data.zip||""}))})' <<< "$R")

N=$(echo "$IMGS_JSON" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const x=JSON.parse(d);console.log(x.images.length)})')
TOTAL=$(echo "$IMGS_JSON" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const x=JSON.parse(d);console.log(x.price?.total||"?")})')
echo "generated $N image(s), cost $TOTAL coins" >&2

# Download all
TS=$(date +%s)
for i in $(seq 0 $((N-1))); do
  URL=$(echo "$IMGS_JSON" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const x=JSON.parse(d);console.log(x.images['"$i"']||"")})')
  [ -n "$URL" ] || continue
  if [ "$N" -eq 1 ]; then
    OUT="${HOME}/Desktop/straico-${TS}.png"
  else
    OUT="${HOME}/Desktop/straico-${TS}-$((i+1)).png"
  fi
  curl -sS -o "$OUT" "$URL"
  echo "$OUT"
done
