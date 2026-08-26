#!/usr/bin/env bash
# Upscale and sharpen an existing image locally with ffmpeg. No API, no credits.
#
# Usage: enhance.sh "path/to/image" [scale] [sharpen]
#   scale    "2x" / "1.5x" / "3840x2160"   (default 2x)
#   sharpen  unsharp amount, 0 disables    (default 0.6)
#
# What this does and does not do:
#   Lanczos resampling plus an unsharp mask recovers apparent crispness from an
#   image that is merely soft. It cannot invent detail that the model never
#   rendered. If the subject itself is mushy, regenerate at 4K with a sharper
#   prompt instead — this is a finishing step, not a substitute for resolution.
#
# Output is always PNG, so the enhancement is not immediately re-compressed away.
#
# Env overrides:
#   FFMPEG_PATH      explicit path to the ffmpeg binary
#   ENHANCE_OUT_DIR  where to write the result (default alongside the input)

set -euo pipefail

IN="${1:?image path required as first arg}"
SCALE="${2:-2x}"
SHARPEN="${3:-0.6}"

[ -f "$IN" ] || { echo "ERROR: image not found: $IN" >&2; exit 1; }

find_ffmpeg() {
  if [ -n "${FFMPEG_PATH:-}" ] && [ -x "$FFMPEG_PATH" ]; then echo "$FFMPEG_PATH"; return 0; fi
  if command -v ffmpeg >/dev/null 2>&1; then command -v ffmpeg; return 0; fi
  local c
  for c in "$HOME/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg"*/"ffmpeg-"*/bin/ffmpeg.exe \
           "/c/Program Files/ffmpeg/bin/ffmpeg.exe" \
           "/c/ffmpeg/bin/ffmpeg.exe"; do
    [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}
FFMPEG=$(find_ffmpeg) || {
  echo "ERROR: ffmpeg not found. Install with 'winget install Gyan.FFmpeg', or set FFMPEG_PATH." >&2
  exit 1
}

# Express the target as an ffmpeg scale expression so no probing of the source is
# needed — "2x" becomes iw*2:ih*2, an explicit WxH is fitted without distortion.
SCALE=$(printf '%s' "$SCALE" | tr 'X' 'x')

if printf '%s' "$SCALE" | grep -Eq '^[0-9]+x[0-9]+$'; then
  TW="${SCALE%x*}"; TH="${SCALE#*x}"
  SCALE_EXPR="scale=${TW}:${TH}:flags=lanczos:force_original_aspect_ratio=decrease"
  LABEL="fit within ${TW}x${TH}"
elif printf '%s' "$SCALE" | grep -Eq '^[0-9]+(\.[0-9]+)?x$'; then
  FACTOR="${SCALE%x}"
  # Guard against a typo like "3840x" being read as a 3840x upscale.
  awk -v f="$FACTOR" 'BEGIN{exit !(f>=1 && f<=8)}' \
    || { echo "ERROR: scale factor must be between 1x and 8x (got '${SCALE}'). For an explicit target write it as 3840x2160." >&2; exit 1; }
  SCALE_EXPR="scale=iw*${FACTOR}:ih*${FACTOR}:flags=lanczos"
  LABEL="${FACTOR}x"
else
  echo "ERROR: unrecognised scale '$SCALE' (want 2x, 1.5x or 3840x2160)" >&2
  exit 1
fi

printf '%s' "$SHARPEN" | grep -Eq '^[0-9]+(\.[0-9]+)?$' \
  || { echo "ERROR: sharpen must be a non-negative number (got '$SHARPEN')" >&2; exit 1; }

CHAIN="$SCALE_EXPR"
[ "$SHARPEN" != "0" ] && CHAIN="${CHAIN},unsharp=5:5:${SHARPEN}:5:5:0"

BASE=$(basename "$IN"); STEM="${BASE%.*}"
DIR="${ENHANCE_OUT_DIR:-$(dirname "$IN")}"
mkdir -p "$DIR"
OUT="${DIR}/${STEM}-enhanced.png"

echo "enhancing: ${LABEL}, unsharp ${SHARPEN} -> PNG" >&2
"$FFMPEG" -y -loglevel error -i "$IN" -vf "$CHAIN" -frames:v 1 "$OUT"

[ -s "$OUT" ] || { echo "ERROR: ffmpeg produced no output" >&2; exit 1; }
echo "$OUT"
