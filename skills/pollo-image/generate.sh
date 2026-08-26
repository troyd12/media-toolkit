#!/usr/bin/env bash
# Submit a text-to-image job to Pollo AI, poll until done, download the result.
#
# Usage:
#   generate.sh "prompt" [aspectRatio] [resolution] [mode] [model]
#   generate.sh --list-models
#
# Defaults: 1:1, 4K, professional, pollo-image-v2
#
# Quality notes (why this script looks the way it does):
#   - resolution defaults to 4K, the highest tier the API offers. Pass 2K for the
#     cheaper tier. This is the single biggest lever on perceived sharpness.
#   - the download follows redirects and fails loudly on HTTP errors. Previously a
#     redirect or error page was saved verbatim as a ".png", producing a file that
#     looked broken or blank.
#   - the saved file keeps the format Pollo actually returned (png / jpg / webp)
#     instead of being blindly named ".png".
#   - the real pixel dimensions are printed, and a warning fires when they come back
#     smaller than the requested tier implies.
#
# Env overrides:
#   POLLO_KEY_FILE   path to the API key      (default ~/.pollo/key.txt)
#   POLLO_OUT_DIR    where to save the image  (default ~/Desktop)
#   POLLO_EXTRA_JSON extra JSON object merged into generationInput, e.g.
#                    POLLO_EXTRA_JSON='{"seed":1234}' generate.sh "..."
#                    Pass-through only: this script does not validate the fields,
#                    the API is the authority on which ones exist.

set -euo pipefail

BASE="https://pollo.ai/api/platform"
KEY_FILE="${POLLO_KEY_FILE:-${HOME}/.pollo/key.txt}"
OUT_DIR="${POLLO_OUT_DIR:-${HOME}/Desktop}"

read_key() {
  if [ ! -s "$KEY_FILE" ]; then
    echo "ERROR: API key not found or empty at $KEY_FILE" >&2
    echo "       Create it with: notepad \"$KEY_FILE\"   (paste the raw key, no quotes)" >&2
    exit 1
  fi
  tr -d '\r\n \t' < "$KEY_FILE"
}

# ---------------------------------------------------------------- --list-models
if [ "${1:-}" = "--list-models" ]; then
  KEY=$(read_key) || exit 1
  echo "available text2image models:" >&2
  curl -sS -L -H "x-api-key: $KEY" "$BASE/config/text2image/models" \
    -w '\nHTTP %{http_code}\n'
  exit 0
fi

PROMPT="${1:?prompt required as first arg}"
ASPECT="${2:-1:1}"
RES="${3:-4K}"
MODE="${4:-professional}"
MODEL="${5:-pollo-image-v2}"

case "$RES" in
  1K|2K|4K) ;;
  *) echo "ERROR: resolution must be 1K, 2K or 4K (got '$RES')" >&2; exit 1 ;;
esac
case "$MODE" in
  standard|professional) ;;
  *) echo "ERROR: mode must be 'standard' or 'professional' (got '$MODE')" >&2; exit 1 ;;
esac

KEY=$(read_key) || exit 1

# ---------------------------------------------------------------------- submit
BODY=$(node -e '
const [prompt, model, mode, aspect, res, extra] = process.argv.slice(1);
const input = { modelName: model, prompt, mode, aspectRatio: aspect, resolution: res };
if (extra) {
  let parsed;
  try { parsed = JSON.parse(extra); }
  catch (e) { console.error("ERROR: POLLO_EXTRA_JSON is not valid JSON: " + e.message); process.exit(1); }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    console.error("ERROR: POLLO_EXTRA_JSON must be a JSON object, e.g. {\"seed\":1234}");
    process.exit(1);
  }
  Object.assign(input, parsed);
}
console.log(JSON.stringify({ sort: 0, language: "en", generationInput: input }));
' "$PROMPT" "$MODEL" "$MODE" "$ASPECT" "$RES" "${POLLO_EXTRA_JSON:-}")

echo "submitting: $MODEL $MODE $ASPECT $RES" >&2
SUBMIT=$(curl -sS -L -X POST "$BASE/generation/text2image" \
  -H "x-api-key: $KEY" -H "Content-Type: application/json" -d "$BODY" \
  -w '\n%{http_code}')
HTTP_CODE="${SUBMIT##*$'\n'}"
SUBMIT="${SUBMIT%$'\n'*}"

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
  echo "ERROR: submit returned HTTP $HTTP_CODE" >&2
  echo "       $SUBMIT" >&2
  if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    echo "       key looks expired or revoked — regenerate it and rewrite $KEY_FILE" >&2
  fi
  exit 1
fi

ID=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{let r;try{r=JSON.parse(d)}catch(e){console.error("submit returned non-JSON:",d);process.exit(1)}if(!r.data?.id){console.error("submit failed:",d);process.exit(1)}console.log(r.data.id)})' <<< "$SUBMIT")
echo "taskId=$ID" >&2

# ------------------------------------------------------------------------ poll
URL=""
for i in $(seq 1 40); do
  sleep 6
  R=$(curl -sS -L "$BASE/generation/$ID" -H "x-api-key: $KEY")
  STATUS=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{console.log(JSON.parse(d).data?.status||"?")}catch(e){console.log("err")}})' <<< "$R")
  echo "poll $i: $STATUS" >&2
  case "$STATUS" in
    succeed)
      URL=$(node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const v=JSON.parse(d).data?.videoList?.[0]||{};console.log(v.videoUrlNoWatermark||v.videoUrl||"")})' <<< "$R")
      break
      ;;
    failed|error)
      echo "ERROR: generation $STATUS. Raw: $R" >&2
      exit 1
      ;;
  esac
done

if [ -z "$URL" ]; then
  echo "ERROR: timed out after 40 polls (~4 min) without a result URL" >&2
  exit 1
fi

# -------------------------------------------------------------------- download
mkdir -p "$OUT_DIR"
TMP=$(mktemp "${TMPDIR:-/tmp}/pollo-${ID}.XXXXXX")
trap 'rm -f "$TMP"' EXIT

echo "downloading..." >&2
# -L follows the CDN redirect, --fail turns an HTTP error page into a non-zero exit
# instead of a "PNG" full of HTML, --retry rides out transient CDN blips.
if ! curl -sS -L --fail --retry 3 --retry-delay 2 -o "$TMP" "$URL"; then
  echo "ERROR: download failed from $URL" >&2
  exit 1
fi

[ -s "$TMP" ] || { echo "ERROR: downloaded file is empty" >&2; exit 1; }

# Identify the real format and dimensions from the file's own header, so a soft or
# downgraded result is visible immediately rather than discovered in a video editor.
INFO=$(node - "$TMP" <<'JS'
const fs = require("fs");
const b = fs.readFileSync(process.argv[2]);
let fmt = "", w = 0, h = 0;

if (b.length >= 24 && b.toString("hex", 0, 8) === "89504e470d0a1a0a") {
  fmt = "png"; w = b.readUInt32BE(16); h = b.readUInt32BE(20);
} else if (b.length > 4 && b[0] === 0xff && b[1] === 0xd8) {
  fmt = "jpg";
  let o = 2;
  while (o + 9 < b.length) {
    if (b[o] !== 0xff) { o++; continue; }
    const m = b[o + 1];
    if (m === 0xd8 || m === 0x01 || (m >= 0xd0 && m <= 0xd7)) { o += 2; continue; }
    const len = b.readUInt16BE(o + 2);
    // SOF0-SOF15, excluding DHT(c4) DAC(cc) and the RSTn range
    if (m >= 0xc0 && m <= 0xcf && m !== 0xc4 && m !== 0xc8 && m !== 0xcc) {
      h = b.readUInt16BE(o + 5); w = b.readUInt16BE(o + 7); break;
    }
    o += 2 + len;
  }
} else if (b.length >= 16 && b.toString("ascii", 0, 4) === "RIFF" && b.toString("ascii", 8, 12) === "WEBP") {
  fmt = "webp";
  const chunk = b.toString("ascii", 12, 16);
  if (chunk === "VP8X" && b.length >= 30) {
    w = (b[24] | (b[25] << 8) | (b[26] << 16)) + 1;
    h = (b[27] | (b[28] << 8) | (b[29] << 16)) + 1;
  } else if (chunk === "VP8 " && b.length >= 30) {
    w = b.readUInt16LE(26) & 0x3fff; h = b.readUInt16LE(28) & 0x3fff;
  } else if (chunk === "VP8L" && b.length >= 25) {
    const bits = b.readUInt32LE(21);
    w = (bits & 0x3fff) + 1; h = ((bits >>> 14) & 0x3fff) + 1;
  }
}
console.log([fmt, w, h].join("\t"));
JS
)

FMT=$(cut -f1 <<< "$INFO")
IMG_W=$(cut -f2 <<< "$INFO")
IMG_H=$(cut -f3 <<< "$INFO")

if [ -z "$FMT" ]; then
  echo "ERROR: downloaded file is not a PNG, JPEG or WebP image." >&2
  echo "       First bytes: $(head -c 64 "$TMP" | tr -d '\0' | head -c 64)" >&2
  exit 1
fi

OUT="${OUT_DIR}/pollo-${ID}.${FMT}"
mv "$TMP" "$OUT"
trap - EXIT

BYTES=$(wc -c < "$OUT" | tr -d ' ')
echo "format=${FMT} dimensions=${IMG_W}x${IMG_H} bytes=${BYTES}" >&2

# Warn when the delivered image is materially smaller than the requested tier.
case "$RES" in
  1K) EXPECT=1024 ;;
  2K) EXPECT=2048 ;;
  4K) EXPECT=3840 ;;
esac
LONG_EDGE=$IMG_W
[ "$IMG_H" -gt "$LONG_EDGE" ] && LONG_EDGE=$IMG_H
if [ "$LONG_EDGE" -gt 0 ] && [ $((LONG_EDGE * 10)) -lt $((EXPECT * 9)) ]; then
  echo "WARNING: long edge is ${LONG_EDGE}px but $RES implies ~${EXPECT}px." >&2
  echo "         The model may not support $RES and fell back to a lower tier." >&2
  echo "         Try a different model: $0 --list-models" >&2
fi
if [ "$FMT" = "jpg" ]; then
  echo "NOTE: Pollo returned JPEG, so the image is already lossy-compressed." >&2
  echo "      Avoid re-saving it as JPEG; edit and export to PNG to stop the loss compounding." >&2
fi

echo "$OUT"
