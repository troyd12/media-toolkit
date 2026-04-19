#!/usr/bin/env bash
# Apply cinematic motion to a still image using ffmpeg → MP4 on Desktop.
# Usage: generate.sh "path/to/image.png" [preset] [duration] [output_size]
# Defaults: preset=push-in, duration=5, output_size=1920x1080
# Presets: push-in | pull-out | pan-left | pan-right | pan-up | pan-down |
#          ken-burns-1 | ken-burns-2 | drift-left | drift-right | rotate-cw | rotate-ccw

set -euo pipefail

IN="${1:?image path required as first arg}"
PRESET="${2:-push-in}"
DUR="${3:-5}"
SIZE="${4:-1920x1080}"

[ -f "$IN" ] || { echo "ERROR: image not found: $IN" >&2; exit 1; }

# Find ffmpeg (winget install path or PATH)
FFMPEG=$(command -v ffmpeg 2>/dev/null || ls "/c/Users/User/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_"*"/ffmpeg-"*"/bin/ffmpeg.exe" 2>/dev/null | head -1)
[ -n "$FFMPEG" ] || { echo "ERROR: ffmpeg not found. Install via 'winget install Gyan.FFmpeg'" >&2; exit 1; }

FPS=30
FRAMES=$((DUR * FPS))
W=$(echo "$SIZE" | cut -dx -f1)
H=$(echo "$SIZE" | cut -dx -f2)

# Build the zoompan filter expression based on preset.
# zoompan uses 'on' (output frame index) 0..FRAMES-1 and zoom variable z.
case "$PRESET" in
  push-in)       Z="zoom+0.0010"; X="iw/2-(iw/zoom/2)";        Y="ih/2-(ih/zoom/2)" ;;
  pull-out)      Z="if(eq(on,0),1.30,zoom-0.0010)"; X="iw/2-(iw/zoom/2)"; Y="ih/2-(ih/zoom/2)" ;;
  pan-left)      Z="1.20"; X="(iw-iw/zoom)*(1-on/$FRAMES)";   Y="ih/2-(ih/zoom/2)" ;;
  pan-right)     Z="1.20"; X="(iw-iw/zoom)*(on/$FRAMES)";     Y="ih/2-(ih/zoom/2)" ;;
  pan-up)        Z="1.20"; X="iw/2-(iw/zoom/2)";              Y="(ih-ih/zoom)*(1-on/$FRAMES)" ;;
  pan-down)      Z="1.20"; X="iw/2-(iw/zoom/2)";              Y="(ih-ih/zoom)*(on/$FRAMES)" ;;
  ken-burns-1)   Z="zoom+0.0008"; X="(iw-iw/zoom)*(on/$FRAMES)";        Y="(ih-ih/zoom)*(on/$FRAMES)*0.5" ;;
  ken-burns-2)   Z="zoom+0.0008"; X="(iw-iw/zoom)*(1-on/$FRAMES)";      Y="(ih-ih/zoom)*(on/$FRAMES)*0.7" ;;
  drift-left)    Z="1.15"; X="(iw-iw/zoom)*(0.5-0.3*on/$FRAMES)";       Y="ih/2-(ih/zoom/2)" ;;
  drift-right)   Z="1.15"; X="(iw-iw/zoom)*(0.5+0.3*on/$FRAMES)";       Y="ih/2-(ih/zoom/2)" ;;
  *) echo "ERROR: unknown preset '$PRESET'" >&2; exit 1 ;;
esac

TS=$(date +%s)
OUT="${HOME}/Desktop/motion-${PRESET}-${TS}.mp4"

# Pre-scale the image up so zoompan has resolution to work with, then compose.
# Use a high working resolution (4x output) so panning/zooming stays sharp.
WORK_W=$((W * 4))
WORK_H=$((H * 4))

echo "applying $PRESET for ${DUR}s @ ${SIZE}..." >&2
"$FFMPEG" -y -loglevel error -loop 1 -i "$IN" \
  -vf "scale=${WORK_W}:${WORK_H}:force_original_aspect_ratio=increase,crop=${WORK_W}:${WORK_H},zoompan=z='${Z}':x='${X}':y='${Y}':d=${FRAMES}:s=${W}x${H}:fps=${FPS}" \
  -c:v libx264 -pix_fmt yuv420p -preset fast -crf 18 -t "$DUR" -movflags +faststart \
  "$OUT"

echo "$OUT"
