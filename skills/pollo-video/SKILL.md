---
name: pollo-video
description: Use when the user asks to generate a video, clip, animation, motion graphic, or video from text — or mentions Seedance, Kling, Runway, Luma, Veo, Sora, Pixverse, Vidu, Hailuo, Pika, or Wan. Submits a text-to-video job to Pollo AI, polls until done, downloads MP4 to Desktop.
---

# Pollo AI Video Generation

## Overview

Pollo AI exposes ~48 text-to-video models (Seedance, Kling, Runway, Luma, Veo, Sora, Pixverse, Vidu, Hailuo, Pika, Wan) via one unified endpoint. This skill wraps the recipe plus a one-shot shell script.

**Default model:** `seedance-2-0` (Seedance 2.0 — latest). Per user preference 2026-04-18.
**Default duration:** 5 seconds. Default aspect: 16:9. Default resolution: 480p.
**Default cost:** ~50 credits for 5s @ 480p. 720p/1080p cost more.

## Prerequisites

- API key at `~/.pollo/key.txt` (same key as the `pollo-image` skill).

## Template Library

**Before generating, match the user's request to a template in `templates.md`** and fill its slots. Templates cover: `cinematic-clip`, `product-demo`, `portrait-loop`, `b-roll`, `motion-graphic`, `explainer-shot`, `aerial`, `action`. Each template has tuned wording + recommended model/duration/aspect/res. If no template fits, write custom — but prefer templates for consistency.

## Quick Call (one shot)

```bash
bash ~/.claude/skills/pollo-video/generate.sh "a cinematic shot of a spaceship landing in a desert at sunset" [duration] [aspect] [resolution] [model]
```

Or via alias (if `pollovid` is in `~/.bashrc`):
```bash
pollovid "your prompt" 5 16:9 480p seedance-2-0
```

Output: `~/Desktop/pollovid-<taskId>.mp4` — path echoed on success.

## Cost-conscious alternatives

| Use case | Model | Duration | Credits |
|---|---|---|---|
| Dirt-cheap smoke test | `seedance-pro-fast` | 2s @ 480p | **1** |
| Balanced quality | `seedance-pro-1-5` | 4s @ 480p | 8 |
| Pro tier (older) | `seedance-pro` | 5s @ 480p | 15 |
| Latest/best (default) | `seedance-2-0` | 5s @ 480p | 50 |

For non-Seedance: `kling-v2-6`, `veo3`, `sora-2`, `runway-gen-4-turbo`, `luma-ray-v2-0`, etc. See `/config/text2video/models` endpoint for full list + pricing.

## API Reference

- **Submit:** `POST /generation/text2video`
  ```json
  {
    "sort": 0,
    "language": "en",
    "generationInput": {
      "modelName": "seedance-2-0",
      "prompt": "...",
      "aspectRatio": "16:9",
      "resolution": "480p",
      "length": 5
    }
  }
  ```
- **Poll:** `GET /generation/{id}` — same as pollo-image. Status: `waiting` → `processing` → `succeed` | `failed`. Videos take 1–5 minutes typically.
- **Result URL:** `data.videoList[0].videoUrlNoWatermark` — MP4.
- **Models list:** `GET /config/text2video/models` (includes creditMatches by resolution/duration).

## Model-specific endpoints

Some models also have dedicated endpoints (e.g. `/generation/kling-ai/kling-v2-6`, `/generation/runway/runway-gen-4-turbo`). The generic `/generation/text2video` works for all and is simpler. Use model-specific endpoints only if validation fails.

## Pitfalls

- Video generation is **slow** (1–5 min, sometimes more) — the script polls up to ~8 min.
- Each model has different valid `length` / `resolution` / `aspectRatio` combinations. If submit returns validation error, check `/config/text2video/models` for that specific model's `creditMatches` array — those are the supported combos.
- Credits are **much higher** than images. Always surface cost to the user before generating.
- Audio-capable models (`generateAudio: true` in creditMatches) need an extra body flag — not handled in default script.

## Resolution policy

Per global `~/.claude/CLAUDE.md`: the **2K image default does not apply here** — video models use their own resolution tiers (480p/720p/1080p). Default 480p, offer 720p/1080p as upgrade options when relevant.

## How the User Runs It

1. **Inside Claude Code:** ask plainly — "make me a 5-second video of...", "generate a clip of...".
2. **Alias:** `pollovid "prompt" 5 16:9 480p seedance-2-0`
3. **Full path:** `bash ~/.claude/skills/pollo-video/generate.sh "prompt"`
