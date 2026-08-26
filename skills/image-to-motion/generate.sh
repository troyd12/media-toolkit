#!/usr/bin/env bash
# Apply cinematic motion to a still image using ffmpeg → MP4 on Desktop.
#
# Usage: generate.sh "path/to/image.png" [preset] [duration] [output_size]
# Defaults: preset=push-in, duration=5, output_size=1920x1080
# Presets: push-in | pull-out | pan-left | pan-right | pan-up | pan-down |
#          ken-burns-1 | ken-burns-2 | drift-left | drift-right
#
# Sharpness notes (why this pipeline looks the way it does):
#   - camera moves are closed-form functions of the frame index instead of
#     accumulating (zoom+0.001 every frame). Accumulation is what produced
#     zoompan's subpixel jitter, and it also made the size of the move depend on
#     the clip's duration — a 10s push-in moved twice as far as a 5s one.
#   - zoompan renders into a supersampled buffer which is then resampled down with
#     lanczos. zoompan's own internal scaler is the main source of mush; letting it
#     work large and downsampling afterwards keeps edges crisp.
#   - every scale uses lanczos rather than swscale's default bicubic.
#   - the working resolution is capped. The old code always used 4x the output,
#     which at 4K meant a 15360x8640 intermediate — enough to exhaust memory or
#     fail outright.
#   - x264 runs at CRF 16 with -tune stillimage, which reduces deblocking and so
#     preserves fine detail on near-static footage.
#
# Env overrides:
#   FFMPEG_PATH      explicit path to the ffmpeg binary
#   MOTION_SHARPEN   unsharp amount after downscale, 0 disables (default 0.4)
#   MOTION_CRF       x264 quality, lower is better (default 16)
#   MOTION_OUT_DIR   where to write the mp4 (default ~/Desktop)

set -euo pipefail

IN="${1:?image path required as first arg}"
PRESET="${2:-push-in}"
DUR="${3:-5}"
SIZE="${4:-1920x1080}"

OUT_DIR="${MOTION_OUT_DIR:-${HOME}/Desktop}"
SHARPEN="${MOTION_SHARPEN:-0.4}"
CRF="${MOTION_CRF:-16}"

[ -f "$IN" ] || { echo "ERROR: image not found: $IN" >&2; exit 1; }

case "$DUR" in
  ''|*[!0-9]*) echo "ERROR: duration must be a whole number of seconds (got '$DUR')" >&2; exit 1 ;;
esac
[ "$DUR" -ge 1 ] || { echo "ERROR: duration must be at least 1 second" >&2; exit 1; }

# ------------------------------------------------------------------ find ffmpeg
find_ffmpeg() {
  if [ -n "${FFMPEG_PATH:-}" ] && [ -x "$FFMPEG_PATH" ]; then echo "$FFMPEG_PATH"; return 0; fi
  if command -v ffmpeg >/dev/null 2>&1; then command -v ffmpeg; return 0; fi
  local c
  # Glob the current user's winget install rather than a hard-coded C:\Users\User.
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

# --------------------------------------------------------------------- geometry
FPS=30
FRAMES=$((DUR * FPS))
W=${SIZE%x*}
H=${SIZE#*x}
case "$W$H" in
  ''|*[!0-9]*) echo "ERROR: output size must look like 1920x1080 (got '$SIZE')" >&2; exit 1 ;;
esac

LONG=$W; [ "$H" -gt "$LONG" ] && LONG=$H

# Supersample the zoompan render for outputs at or below ~2K. Above that there are
# already enough pixels that a 2x buffer costs far more than it returns.
if [ "$LONG" -le 2048 ]; then SUPER=2; else SUPER=1; fi
SUP_W=$((W * SUPER)); SUP_H=$((H * SUPER))

# Prescale the still so zoompan has headroom to crop into: the widest zoom used by
# any preset is 1.18, and 1.6x leaves margin. Capped so huge outputs stay tractable.
MAX_EDGE=8192
PRE_W=$(( (SUP_W * 16) / 10 )); PRE_H=$(( (SUP_H * 16) / 10 ))
PRE_LONG=$PRE_W; [ "$PRE_H" -gt "$PRE_LONG" ] && PRE_LONG=$PRE_H
if [ "$PRE_LONG" -gt "$MAX_EDGE" ]; then
  PRE_W=$(( PRE_W * MAX_EDGE / PRE_LONG ))
  PRE_H=$(( PRE_H * MAX_EDGE / PRE_LONG ))
fi
# libx264 requires even dimensions; swscale is happier with them too.
PRE_W=$(( (PRE_W / 2) * 2 )); PRE_H=$(( (PRE_H / 2) * 2 ))
SUP_W=$(( (SUP_W / 2) * 2 )); SUP_H=$(( (SUP_H / 2) * 2 ))

# ----------------------------------------------------------------- camera moves
# P is linear progress 0..1 across the clip; E eases it (smoothstep) so the move
# starts and stops gently instead of snapping into motion.
LAST=$((FRAMES - 1)); [ "$LAST" -lt 1 ] && LAST=1
P="(on/$LAST)"
E="($P*$P*(3-2*$P))"

CX="iw/2-(iw/zoom/2)"
CY="ih/2-(ih/zoom/2)"

case "$PRESET" in
  push-in)     Z="(1+0.18*$E)";    X="$CX"; Y="$CY" ;;
  pull-out)    Z="(1.18-0.18*$E)"; X="$CX"; Y="$CY" ;;
  pan-left)    Z="1.15"; X="(iw-iw/zoom)*(1-$E)"; Y="$CY" ;;
  pan-right)   Z="1.15"; X="(iw-iw/zoom)*$E";     Y="$CY" ;;
  pan-up)      Z="1.15"; X="$CX"; Y="(ih-ih/zoom)*(1-$E)" ;;
  pan-down)    Z="1.15"; X="$CX"; Y="(ih-ih/zoom)*$E" ;;
  ken-burns-1) Z="(1+0.15*$E)"; X="(iw-iw/zoom)*$E";     Y="(ih-ih/zoom)*$E*0.5" ;;
  ken-burns-2) Z="(1+0.15*$E)"; X="(iw-iw/zoom)*(1-$E)"; Y="(ih-ih/zoom)*$E*0.7" ;;
  drift-left)  Z="1.12"; X="(iw-iw/zoom)*(0.5-0.3*$E)"; Y="$CY" ;;
  drift-right) Z="1.12"; X="(iw-iw/zoom)*(0.5+0.3*$E)"; Y="$CY" ;;
  *) echo "ERROR: unknown preset '$PRESET'" >&2
     echo "       valid: push-in pull-out pan-left pan-right pan-up pan-down ken-burns-1 ken-burns-2 drift-left drift-right" >&2
     exit 1 ;;
esac

# ------------------------------------------------------------------ filtergraph
CHAIN="scale=${PRE_W}:${PRE_H}:flags=lanczos:force_original_aspect_ratio=increase"
CHAIN="${CHAIN},crop=${PRE_W}:${PRE_H}"
CHAIN="${CHAIN},zoompan=z='${Z}':x='${X}':y='${Y}':d=${FRAMES}:s=${SUP_W}x${SUP_H}:fps=${FPS}"
if [ "$SUPER" -gt 1 ]; then
  CHAIN="${CHAIN},scale=${W}:${H}:flags=lanczos"
fi
if [ "$SHARPEN" != "0" ]; then
  CHAIN="${CHAIN},unsharp=3:3:${SHARPEN}:3:3:0"
fi
CHAIN="${CHAIN},format=yuv420p"

mkdir -p "$OUT_DIR"
TS=$(date +%s)
OUT="${OUT_DIR}/motion-${PRESET}-${TS}.mp4"

echo "applying $PRESET for ${DUR}s @ ${SIZE} (prescale ${PRE_W}x${PRE_H}, render ${SUP_W}x${SUP_H}, crf ${CRF})..." >&2

"$FFMPEG" -y -loglevel error -loop 1 -i "$IN" \
  -vf "$CHAIN" \
  -c:v libx264 -preset slow -crf "$CRF" -tune stillimage \
  -profile:v high -pix_fmt yuv420p -r "$FPS" -t "$DUR" -movflags +faststart \
  "$OUT"

[ -s "$OUT" ] || { echo "ERROR: ffmpeg produced no output" >&2; exit 1; }
echo "$OUT"
