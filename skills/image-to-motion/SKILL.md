---
name: image-to-motion
description: Use when the user wants to add cinematic motion (Ken Burns, push-in, pan, drift) to an existing still image to create a short MP4 video — or when AI video APIs are unavailable/expensive. Free, local, ffmpeg-based, no AI.
---

# Image-to-Motion (ffmpeg-based)

## Overview

Apply cinematic camera moves to a still image, output an MP4. **No AI**, no API, no credits — just ffmpeg locally. Works on any PNG/JPG. Use it as a free alternative or supplement to true AI video (Veo, Runway, Kling).

**What it can do:** push-in, pull-out, pan (any direction), Ken Burns combos, slow drift.
**What it can't do:** invent new content, add characters, animate water/clouds realistically. For that you need real AI video.

## Prerequisites

- ffmpeg installed (`winget install Gyan.FFmpeg`). Skill auto-locates the winget install path if `ffmpeg` isn't on PATH yet.

## Quick Call

```bash
bash ~/.claude/skills/image-to-motion/generate.sh "path/to/image.png" [preset] [duration] [output_size]
```

Alias: `motionize "path" preset 5 1920x1080`

Output: `~/Desktop/motion-<preset>-<timestamp>.mp4`

## Presets

| Preset | What it does | Best for |
|---|---|---|
| `push-in` *(default)* | Slow zoom into center | Logo reveals, hero shots |
| `pull-out` | Starts zoomed, pulls back to wide | Reveal a scene |
| `pan-left` / `pan-right` | Sideways pan across image | Landscapes, banners |
| `pan-up` / `pan-down` | Vertical pan | Portraits, tall compositions |
| `ken-burns-1` / `ken-burns-2` | Combined zoom + diagonal pan (classic doc style) | Portraits, photos |
| `drift-left` / `drift-right` | Subtle sideways drift, no zoom | B-roll, atmospheric |

## Defaults

- **Duration:** 5 seconds (override with 3rd arg)
- **Output size:** 1920x1080 (full HD). Use `3840x2160` for 4K, `1080x1920` for vertical (Reels/TikTok).
- **Codec:** H.264 (`libx264`), `-preset slow`, CRF 16, `-tune stillimage`, faststart for web playback.
- **FPS:** 30.
- **Resampling:** lanczos throughout, plus a light unsharp pass after the downscale.

Env overrides: `MOTION_CRF` (lower is sharper, larger file), `MOTION_SHARPEN` (unsharp amount,
`0` disables), `MOTION_OUT_DIR`, `FFMPEG_PATH`.

## Recommended workflow

1. Generate a high-resolution still via `pollo-image` at **4K**. The camera move crops into the
   image, so the still must carry more resolution than the video output — a 2K still pushed
   into for a 1080p clip is running out of pixels by the end of the move.
2. Pipe path into `motionize <path> push-in 5 1920x1080` for a 5-second cinematic clip.
3. Drop into a video editor (CapCut / Premiere / DaVinci) for stacking, audio, transitions.

## Sharpness

If a clip looks softer than the still it came from, the cause is almost always one of these:

1. **The source still is too small.** A push-in ends at 1.18x zoom, so a 1080p clip is reading
   roughly a 2270px-wide window out of the source by the final frame. Generate the still at 4K.
2. **The output size is smaller than where it will be shown.** A 1080p clip upscaled to a 4K
   timeline is soft no matter how clean the render was. Pass `3840x2160`.
3. **The still was already soft.** Run `pollo-image/enhance.sh` on it first, or regenerate with
   the blur vocabulary removed from the prompt — see that skill's templates.
4. **Over-compression.** Drop `MOTION_CRF` to 14 for a larger, cleaner file.

## Pitfalls

- Source image needs sufficient resolution. If source is 1024×1024 and output is 1920×1080, ffmpeg upscales, which can soften details. Generate at 4K for best results.
- ffmpeg's `zoompan` filter is the main source of mush. Two things mitigate it here: the still
  is prescaled well above the render size, and zoompan renders into a supersampled buffer that
  is resampled down with lanczos afterwards.
- Camera moves are closed-form functions of the frame index rather than per-frame accumulation
  (`zoom+0.001`). Accumulating causes zoompan's subpixel jitter, and it also made the size of
  the move depend on duration — a 10s push-in used to travel twice as far as a 5s one. Moves
  are now duration-independent and eased in and out.
- The working resolution is capped at 8192px on the long edge. The old code always used 4x the
  output, which at 4K meant a 15360x8640 intermediate — enough to exhaust memory or fail.
- Heavy diagonal pans can show edges if the image's aspect doesn't match output. The script crops to fit.

## How the User Runs It

1. **Claude Code:** "add motion to that logo I just made", "ken burns on the duck image", "make a 5s cinematic clip from <path>"
2. **Terminal alias:** `motionize "C:\Users\User\Desktop\logo.png" push-in 5`
3. **Full path:** `bash ~/.claude/skills/image-to-motion/generate.sh "<path>" <preset>`
