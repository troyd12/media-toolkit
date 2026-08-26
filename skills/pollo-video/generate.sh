#!/usr/bin/env bash
# Submit a text-to-video job to Pollo AI, poll until done, download MP4 to Desktop.
#
# Usage:
#   generate.sh "prompt" [duration] [aspectRatio] [resolution] [model]
#   generate.sh --list-models [filter]
#
# Defaults: duration=5, aspect=16:9, resolution=720p, model=seedance-2-0
#
# Quality notes:
#   - resolution defaults to 720p. It used to be 480p, which made every model
#     look bad and made model comparisons meaningless. 480p is still available
#     for cheap smoke tests — pass it explicitly.
#   - the download follows redirects and fails loudly on HTTP errors, then checks
#     the file really is an MP4. Previously a redirect saved an empty file and an
#     error page saved as HTML, both named ".mp4".
#
# Env overrides:
#   POLLO_KEY_FILE     path to the API key       (default ~/.pollo/key.txt)
#   POLLO_OUT_DIR      where to save             (default ~/Desktop)
#   POLLO_MODEL_FIELD  JSON field carrying the model name (default videoModel).
#                      Pollo's docs describe `modelName` for text2image while this
#                      endpoint has taken `videoModel`. If a model rejects the
#                      submit with a validation error, try:
#                        POLLO_MODEL_FIELD=modelName generate.sh "..." 5 16:9 720p <model>
#   POLLO_EXTRA_JSON   extra JSON object merged into generationInput, e.g. audio
#                      flags for models that support them. Pass-through only.

set -euo pipefail

BASE="https://pollo.ai/api/platform"
KEY_FILE="${POLLO_KEY_FILE:-${HOME}/.pollo/key.txt}"
OUT_DIR="${POLLO_OUT_DIR:-${HOME}/Desktop}"
MODEL_FIELD="${POLLO_MODEL_FIELD:-videoModel}"

read_key() {
  if [ ! -s "$KEY_FILE" ]; then
    echo "ERROR: API key not found or empty at $KEY_FILE" >&2
    echo "       Create it with: notepad \"$KEY_FILE\"   (paste the raw key, no quotes)" >&2
    exit 1
  fi
  tr -d '\r\n \t' < "$KEY_FILE"
}

# ---------------------------------------------------------------- --list-models
# Finding a model's exact slug is the usual blocker when trying a new backend
# (LTX, Veo, Kling...). An optional filter greps names case-insensitively.
if [ "${1:-}" = "--list-models" ]; then
  KEY=$(read_key) || exit 1
  FILTER="${2:-}"
  RAW=$(curl -sS -L -H "x-api-key: $KEY" "$BASE/config/text2video/models")
  PARSED=$(node -e '
let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
  const filter = (process.argv[1] || "").toLowerCase();
  let r; try { r = JSON.parse(d); } catch(e) { process.exit(1); }
  const out = [];
  (function walk(n){
    if (!n || typeof n !== "object") return;
    if (Array.isArray(n)) return n.forEach(walk);
    const name = n.name || n.modelName || n.videoModel || n.model;
    if (typeof name === "string") out.push({ name, display: n.displayName || n.title || "" });
    Object.values(n).forEach(walk);
  })(r);
  const seen = new Set();
  const rows = out.filter(m => !seen.has(m.name) && seen.add(m.name))
                  .filter(m => !filter || (m.name + " " + m.display).toLowerCase().includes(filter))
                  .sort((a,b) => a.name.localeCompare(b.name));
  if (!rows.length) { console.log(filter ? "no models matching: " + filter : "no models parsed"); return; }
  rows.forEach(m => console.log(m.display ? m.name + "\t" + m.display : m.name));
})' "$FILTER" <<< "$RAW") || PARSED=""
  if [ -n "$PARSED" ]; then echo "$PARSED"; else
    echo "could not parse the model list; raw response follows:" >&2
    echo "$RAW"
  fi
  exit 0
fi

PROMPT="${1:?prompt required as first arg}"
DURATION="${2:-5}"
ASPECT="${3:-16:9}"
RES="${4:-720p}"
MODEL="${5:-seedance-2-0}"

case "$DURATION" in
  ''|*[!0-9]*) echo "ERROR: duration must be a whole number of seconds (got '$DURATION')" >&2; exit 1 ;;
esac

KEY=$(read_key) || exit 1

BODY=$(node -e '
const [prompt, model, aspect, res, duration, field, extra] = process.argv.slice(1);
const input = { prompt, aspectRatio: aspect, resolution: res, length: Number(duration) };
input[field] = model;
if (extra) {
  let parsed;
  try { parsed = JSON.parse(extra); }
  catch (e) { console.error("ERROR: POLLO_EXTRA_JSON is not valid JSON: " + e.message); process.exit(1); }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    console.error("ERROR: POLLO_EXTRA_JSON must be a JSON object"); process.exit(1);
  }
  Object.assign(input, parsed);
}
console.log(JSON.stringify({ sort: 0, language: "en", generationInput: input }));
' "$PROMPT" "$MODEL" "$ASPECT" "$RES" "$DURATION" "$MODEL_FIELD" "${POLLO_EXTRA_JSON:-}") || exit 1

echo "submitting $MODEL ${DURATION}s ${ASPECT} ${RES} (model field: $MODEL_FIELD)..." >&2
SUBMIT=$(curl -sS -L -X POST "$BASE/generation/text2video" \
  -H "x-api-key: $KEY" -H "Content-Type: application/json" -d "$BODY" -w '\n%{http_code}')
CODE="${SUBMIT##*$'\n'}"; SUBMIT="${SUBMIT%$'\n'*}"

if [ "$CODE" != "200" ] && [ "$CODE" != "201" ]; then
  echo "ERROR: submit returned HTTP $CODE" >&2
  echo "       $SUBMIT" >&2
  if [ "$CODE" = "401" ] || [ "$CODE" = "403" ]; then
    echo "       key looks expired or revoked — regenerate it and rewrite $KEY_FILE" >&2
  else
    echo "       If this is a validation error: each model accepts only certain" >&2
    echo "       length/resolution/aspectRatio combos. Check its creditMatches via" >&2
    echo "       $0 --list-models ${MODEL%%-*}" >&2
    echo "       If the model name itself is rejected, try POLLO_MODEL_FIELD=modelName" >&2
  fi
  exit 1
fi

ID=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{let r;try{r=JSON.parse(d)}catch(e){console.error("submit returned non-JSON:",d);process.exit(1)}if(!r.data?.id){console.error("submit failed:",d);process.exit(1)}console.log(r.data.id)})' <<< "$SUBMIT") || exit 1
echo "taskId=$ID" >&2

URL=""
for i in $(seq 1 60); do
  sleep 8
  R=$(curl -sS -L "$BASE/generation/$ID" -H "x-api-key: $KEY")
  STATUS=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{console.log(JSON.parse(d).data?.status||"?")}catch(e){console.log("err")}})' <<< "$R")
  echo "poll $i: $STATUS" >&2
  case "$STATUS" in
    succeed)
      URL=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const v=JSON.parse(d).data?.videoList?.[0]||{};console.log(v.videoUrlNoWatermark||v.videoUrl||"")})' <<< "$R")
      break ;;
    failed|error)
      echo "ERROR: generation $STATUS. Raw: $R" >&2; exit 1 ;;
  esac
done

[ -n "$URL" ] || { echo "ERROR: timed out after 60 polls (~8 min) without a result URL" >&2; exit 1; }

mkdir -p "$OUT_DIR"
TMP=$(mktemp "${TMPDIR:-/tmp}/pollovid-${ID}.XXXXXX")
trap 'rm -f "$TMP"' EXIT

echo "downloading..." >&2
curl -sS -L --fail --retry 3 --retry-delay 2 -o "$TMP" "$URL" \
  || { echo "ERROR: download failed from $URL" >&2; exit 1; }
[ -s "$TMP" ] || { echo "ERROR: downloaded file is empty" >&2; exit 1; }

if ! node -e '
const fs=require("fs");const b=fs.readFileSync(process.argv[1]);
process.exit(b.length>12 && b.toString("ascii",4,8)==="ftyp" ? 0 : 1);
' "$TMP"; then
  echo "ERROR: downloaded file is not an MP4 (no ftyp box)." >&2
  echo "       First bytes: $(head -c 64 "$TMP" | tr -d '\0' | head -c 64)" >&2
  exit 1
fi

OUT="${OUT_DIR}/pollovid-${ID}.mp4"
mv "$TMP" "$OUT"; trap - EXIT
echo "bytes=$(wc -c < "$OUT" | tr -d ' ')" >&2
echo "$OUT"
