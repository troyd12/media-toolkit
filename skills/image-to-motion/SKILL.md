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
- **Codec:** H.264 (`libx264`), CRF 18, faststart for web playback.
- **FPS:** 30.

## Recommended workflow

1. Generate a high-resolution still via `pollo-image` (2K) or `straico-image` (Flux landscape ~2K).
2. Pipe path into `motionize <path> push-in 5 1920x1080` for a 5-second cinematic clip.
3. Drop into a video editor (CapCut / Premiere / DaVinci) for stacking, audio, transitions.

## Pitfalls

- Source image needs sufficient resolution. If source is 1024×1024 and output is 1920×1080, ffmpeg upscales, which can soften details. Generate at ≥2K for best results.
- ffmpeg's `zoompan` filter has subpixel jitter at low zoom rates — the 4x working-resolution trick in `generate.sh` mitigates this.
- Heavy diagonal pans can show edges if the image's aspect doesn't match output. The script crops to fit.

## How the User Runs It

1. **Claude Code:** "add motion to that logo I just made", "ken burns on the duck image", "make a 5s cinematic clip from <path>"
2. **Terminal alias:** `motionize "C:\Users\User\Desktop\logo.png" push-in 5`
3. **Full path:** `bash ~/.claude/skills/image-to-motion/generate.sh "<path>" <preset>`
