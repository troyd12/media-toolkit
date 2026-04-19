---
name: pollo-image
description: Use when the user asks to generate an image, logo, illustration, artwork, or visual — or references Pollo AI. Submits a text-to-image job to Pollo AI, polls until done, downloads the PNG to the user's Desktop.
---

# Pollo AI Image Generation

## Overview

Pollo AI's REST API generates images from text prompts. This skill is the proven recipe: auth header, endpoint, body shape, polling pattern, and a one-shot shell script that does it all.

**Model default:** `pollo-image-v2`, professional mode, 1:1, 2K — ~18 credits per image.

**Resolution policy (user preference, 2026-04-18):** Default to **2K** without asking. Before generating, offer 4K as an optional upgrade in one sentence (e.g. "Going with 2K (~18 credits) — say 4K if you want ~30-credit high-res."). Do not ask about 1K — only 2K (default) vs 4K (opt-in). Do not repeat the offer on every follow-up in the same session; once the user picks, stick with it.

## Prerequisites

- API key saved at `~/.pollo/key.txt` (Notepad on Windows silently appends `.txt` — that's expected).
  - If missing: `notepad "$HOME/.pollo/key"` → user pastes raw key → Ctrl+S → close. Verify with `wc -c < ~/.pollo/key.txt`.
- Never paste keys into chat. If user does, tell them to rotate it.

## Template Library

**Before generating, match the user's request to a template in `templates.md`** and fill its slots. Templates cover: `logo`, `wordmark`, `monogram`, `icon`, `headshot`, `product-shot`, `hero-banner`, `illustration`, `concept-art`, `social-tile`. Each has tuned wording + recommended aspect/res. If no template fits, write a custom prompt — but prefer templates for consistency.

## Quick Call (one shot)

Use `generate.sh` in this skill directory. It submits, polls, downloads, prints the path.

```bash
bash ~/.claude/skills/pollo-image/generate.sh "a minimalist logo for ACME, cyan gradient on white" [aspectRatio] [resolution]
```

Defaults: aspectRatio `1:1`, resolution `2K`. Outputs PNG to `~/Desktop/pollo-<taskId>.png` and echoes the path. Then `Read` the path to show the image.

## How the User Runs It (outside Claude Code)

Three equivalent ways — tell the user whichever matches how they're asking:

1. **Inside Claude Code:** ask in plain English ("generate a logo for X") — this skill auto-invokes.
2. **Any bash terminal, full path:**
   ```bash
   bash ~/.claude/skills/pollo-image/generate.sh "your prompt" [aspectRatio] [resolution]
   ```
3. **Short alias** (added to `~/.bashrc` on 2026-04-18):
   ```bash
   polloimg "your prompt" [aspectRatio] [resolution]
   ```
   Requires a fresh shell or `source ~/.bashrc`. If `polloimg` isn't found, check `grep polloimg ~/.bashrc`.

## API Reference (for custom calls)

- **Base:** `https://pollo.ai/api/platform`
- **Auth:** `x-api-key: <key>` header
- **Submit:** `POST /generation/text2image`
  ```json
  {
    "sort": 0,
    "language": "en",
    "generationInput": {
      "modelName": "pollo-image-v2",
      "prompt": "...",
      "mode": "professional",
      "aspectRatio": "1:1",
      "resolution": "2K"
    }
  }
  ```
  Returns `{ "data": { "id": <taskId>, "status": "waiting" } }`.
- **Poll:** `GET /generation/{id}` (NOT `/status` — that's 404). `data.status`: `waiting` → `processing` → `succeed` | `failed`.
- **Result URL:** `data.videoList[0].videoUrlNoWatermark` (field is named `videoList` even for images).
- **Models list:** `GET /config/text2image/models`.

## Parameters

| Field | Values | Notes |
|---|---|---|
| `modelName` | `pollo-image-v2` (default) | Others via `/config/text2image/models` |
| `mode` | `standard`, `professional` | Professional = cinema quality, +1 credit |
| `aspectRatio` | `1:1`, `3:2`, `2:3`, `3:4`, `4:3`, `16:9`, `9:16` | |
| `resolution` | `1K`, `2K`, `4K` | 4K costs ~30 credits |

## Multi-Variation Workflow

When user asks for N variations, submit all N in parallel (they're async), then poll once. The script supports single shots — for batch, loop the submit step with different prompts, collect IDs, then loop polling.

## Pitfalls

- `/agent/generate` and `/agent/generation/{id}` require `userId` in the body — use `/generation/*` instead.
- `/generation/{id}/status` returns `NOT_FOUND` — use `/generation/{id}` for both polling and results.
- Don't confuse with Higgsfield. Higgsfield uses `hf-api-key` + `hf-secret`; Pollo uses just `x-api-key`.
- Pollo's Soul-style models are photo/cinematic — for flat vector logos, lean hard on prompt keywords ("flat design", "vector-style", "sharp edges", "no gradient" if mono).

## Related Memory

See `reference_pollo_api.md` in the user's memory for the same recipe in reference form.
