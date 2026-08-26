#!/usr/bin/env bash
# Submit a text-to-video job to LTX on fal.ai, poll the queue, download the MP4.
#
# Usage:
#   generate.sh "prompt" [--args '<json>'] [--model <endpoint-id>]
#   generate.sh --check
#
# Only `prompt` is sent by default. Every other model parameter goes through
# --args (or LTX_ARGS) verbatim, because parameter names differ between LTX
# endpoints and inventing them produces silent 422s. Look the names up on the
# model's fal page, then pass them:
#
#   generate.sh "a slow dolly through a rain-soaked alley" \
#     --args '{"resolution":"1080p","aspect_ratio":"16:9","duration":6}'
#
# Transport (verified against the official fal-client 1.0.1 source):
#   auth    Authorization: Key <FAL_KEY>
#   submit  POST https://queue.fal.run/<endpoint-id>   body = the arguments object
#   returns {request_id, status_url, response_url, cancel_url}
#   poll    GET <status_url>   -> status IN_QUEUE | IN_PROGRESS | COMPLETED
#   result  GET <response_url> -> the model output JSON
# The status/response URLs come back from submit rather than being rebuilt here:
# fal's status path uses owner/alias WITHOUT the endpoint subpath, so rebuilding
# them by hand is a common way to get a 404.
#
# Env overrides:
#   FAL_KEY        the key itself (takes precedence over the key file)
#   FAL_KEY_FILE   path to the key   (default ~/.fal/key.txt)
#   LTX_MODEL      default endpoint id
#   LTX_ARGS       same as --args
#   LTX_OUT_DIR    where to save     (default ~/Desktop)

set -euo pipefail

QUEUE="https://queue.fal.run"
KEY_FILE="${FAL_KEY_FILE:-${HOME}/.fal/key.txt}"
OUT_DIR="${LTX_OUT_DIR:-${HOME}/Desktop}"
MODEL="${LTX_MODEL:-fal-ai/ltx-2.3/text-to-video}"
ARGS="${LTX_ARGS:-}"

read_key() {
  if [ -n "${FAL_KEY:-}" ]; then printf '%s' "$FAL_KEY"; return 0; fi
  if [ ! -s "$KEY_FILE" ]; then
    echo "ERROR: no fal key. Set FAL_KEY, or save the raw key at $KEY_FILE" >&2
    echo "       Get one at https://fal.ai/dashboard/keys" >&2
    exit 1
  fi
  tr -d '\r\n \t' < "$KEY_FILE"
}

PROMPT=""
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check)  CHECK=1; shift ;;
    --args)   ARGS="${2:?--args needs a JSON object}"; shift 2 ;;
    --model)  MODEL="${2:?--model needs an endpoint id}"; shift 2 ;;
    --help|-h) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "ERROR: unknown flag '$1'" >&2; exit 1 ;;
    *)  [ -z "$PROMPT" ] && PROMPT="$1" || { echo "ERROR: unexpected extra argument '$1' (quote your prompt)" >&2; exit 1; }
        shift ;;
  esac
done

if [ "$CHECK" = "1" ]; then
  KEY=$(read_key) || exit 1
  echo "key loaded from ${FAL_KEY:+FAL_KEY env}${FAL_KEY:-$KEY_FILE} (${#KEY} chars)" >&2
  echo "model: $MODEL" >&2
  curl -sS -L -X POST "$QUEUE/$MODEL" \
    -H "Authorization: Key $KEY" -H "Content-Type: application/json" \
    -d '{}' -w '\nHTTP %{http_code}\n'
  echo "(a 422 here means auth works and the endpoint exists — it is just rejecting the empty body)" >&2
  exit 0
fi

[ -n "$PROMPT" ] || { echo "ERROR: prompt required as first arg" >&2; exit 1; }
KEY=$(read_key) || exit 1

# --------------------------------------------------------------- build payload
BODY=$(node -e '
const [prompt, extra] = process.argv.slice(1);
const args = { prompt };
if (extra) {
  let parsed;
  try { parsed = JSON.parse(extra); }
  catch (e) { console.error("ERROR: --args is not valid JSON: " + e.message); process.exit(1); }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    console.error("ERROR: --args must be a JSON object, e.g. {\"resolution\":\"1080p\"}");
    process.exit(1);
  }
  Object.assign(args, parsed);
}
console.log(JSON.stringify(args));
' "$PROMPT" "$ARGS") || exit 1

echo "submitting to $MODEL ..." >&2
SUBMIT=$(curl -sS -L -X POST "$QUEUE/$MODEL" \
  -H "Authorization: Key $KEY" -H "Content-Type: application/json" \
  -d "$BODY" -w '\n%{http_code}')
CODE="${SUBMIT##*$'\n'}"; SUBMIT="${SUBMIT%$'\n'*}"

if [ "$CODE" != "200" ] && [ "$CODE" != "201" ]; then
  echo "ERROR: submit returned HTTP $CODE" >&2
  echo "       $SUBMIT" >&2
  case "$CODE" in
    401|403) echo "       key rejected — check https://fal.ai/dashboard/keys" >&2 ;;
    404)     echo "       endpoint '$MODEL' not found — check the id on its fal model page" >&2 ;;
    422)     echo "       the model rejected an argument. Names differ per endpoint;" >&2
             echo "       check the model's API tab and pass them via --args." >&2 ;;
  esac
  exit 1
fi

read -r REQ_ID STATUS_URL RESPONSE_URL <<< "$(node -e '
let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
  let r; try { r = JSON.parse(d); } catch(e){ console.error("submit returned non-JSON:",d); process.exit(1); }
  if (!r.request_id || !r.status_url || !r.response_url) { console.error("unexpected submit response:", d); process.exit(1); }
  console.log([r.request_id, r.status_url, r.response_url].join(" "));
})' <<< "$SUBMIT")" || exit 1
echo "request_id=$REQ_ID" >&2

# ------------------------------------------------------------------------ poll
RESULT=""
for i in $(seq 1 90); do
  sleep 8
  R=$(curl -sS -L "$STATUS_URL" -H "Authorization: Key $KEY")
  ST=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{console.log(JSON.parse(d).status||"?")}catch(e){console.log("err")}})' <<< "$R")
  echo "poll $i: $ST" >&2
  case "$ST" in
    COMPLETED)
      RESULT=$(curl -sS -L "$RESPONSE_URL" -H "Authorization: Key $KEY")
      break ;;
    IN_QUEUE|IN_PROGRESS) ;;
    *) echo "ERROR: unexpected status '$ST'. Raw: $R" >&2; exit 1 ;;
  esac
done

[ -n "$RESULT" ] || { echo "ERROR: timed out after 90 polls (~12 min)" >&2; exit 1; }

# Find the video URL without assuming the exact output shape: prefer a `video`
# object's url, then any url with a video extension, then any media-ish url.
URL=$(node -e '
let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
  let r; try { r = JSON.parse(d); } catch(e){ console.error("result was not JSON:", d); process.exit(1); }
  const VIDEO_EXT = /\.(mp4|webm|mov|m4v)(\?|$)/i;
  let best = null, fallback = null;
  (function walk(node, key) {
    if (node === null || node === undefined) return;
    if (typeof node === "string") {
      if (!/^https?:\/\//.test(node)) return;
      if (VIDEO_EXT.test(node)) { if (!best) best = node; }
      else if (key === "url" && !fallback) fallback = node;
      return;
    }
    if (Array.isArray(node)) { node.forEach(v => walk(v, key)); return; }
    if (typeof node === "object") {
      if (node.video && typeof node.video === "object" && typeof node.video.url === "string") {
        if (!best) best = node.video.url;
      }
      for (const k of Object.keys(node)) walk(node[k], k);
    }
  })(r, null);
  console.log(best || fallback || "");
})' <<< "$RESULT") || exit 1

if [ -z "$URL" ]; then
  echo "ERROR: no video URL found in the result." >&2
  echo "       Raw result: $RESULT" >&2
  exit 1
fi

# -------------------------------------------------------------------- download
mkdir -p "$OUT_DIR"
TMP=$(mktemp "${TMPDIR:-/tmp}/ltx-${REQ_ID}.XXXXXX")
trap 'rm -f "$TMP"' EXIT

echo "downloading..." >&2
curl -sS -L --fail --retry 3 --retry-delay 2 -o "$TMP" "$URL" \
  || { echo "ERROR: download failed from $URL" >&2; exit 1; }
[ -s "$TMP" ] || { echo "ERROR: downloaded file is empty" >&2; exit 1; }

# An MP4/MOV starts with a 4-byte size then 'ftyp'. Catches an error page saved
# as a .mp4, which otherwise only shows up when the file refuses to play.
if ! node -e '
const fs=require("fs");const b=fs.readFileSync(process.argv[1]);
process.exit(b.length>12 && b.toString("ascii",4,8)==="ftyp" ? 0 : 1);
' "$TMP"; then
  echo "ERROR: downloaded file is not an MP4 (no ftyp box)." >&2
  echo "       First bytes: $(head -c 64 "$TMP" | tr -d '\0' | head -c 64)" >&2
  exit 1
fi

OUT="${OUT_DIR}/ltx-${REQ_ID}.mp4"
mv "$TMP" "$OUT"; trap - EXIT
echo "bytes=$(wc -c < "$OUT" | tr -d ' ')" >&2
echo "$OUT"
