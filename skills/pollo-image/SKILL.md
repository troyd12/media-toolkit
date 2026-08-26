---
name: pollo-image
description: Use when the user asks to generate an image, logo, illustration, artwork, or visual — or references Pollo AI. Submits a text-to-image job to Pollo AI, polls until done, downloads the image to the user's Desktop.
---

# Pollo AI Image Generation

## Overview

Pollo AI's REST API generates images from text prompts. This skill is the proven recipe: auth header, endpoint, body shape, polling pattern, and a one-shot shell script that does it all.

**Model default:** `pollo-image-v2`, professional mode, 1:1, 4K.

**Resolution policy (updated 2026-08-26):** Default to **4K**. The previous 2K default was
the main reason generated images looked soft, so quality now wins over credit cost by
default. 4K is ~30 credits against ~18 for 2K. Mention the cost once at the start of a
session — *"Going 4K (~30 credits) for sharpness; say 2K if you'd rather save credits."* —
then stick with whatever the user picks and stop re-offering.

## Prerequisites

- API key saved at `~/.pollo/key.txt` (Notepad on Windows silently appends `.txt` — that's expected).
  - If missing: `notepad "$HOME/.pollo/key"` → user pastes raw key → Ctrl+S → close. Verify with `wc -c < ~/.pollo/key.txt`.
- Never paste keys into chat. If user does, tell them to rotate it.
- `enhance.sh` additionally needs ffmpeg (`winget install Gyan.FFmpeg`). `generate.sh` does not.

## Template Library

**Before generating, match the user's request to a template in `templates.md`** and fill its slots. Templates cover: `logo`, `wordmark`, `monogram`, `icon`, `headshot`, `product-shot`, `hero-banner`, `illustration`, `concept-art`, `social-tile`. Each has tuned wording + recommended aspect/res. If no template fits, write a custom prompt — but prefer templates for consistency.

Read the **Sharpness** section at the top of `templates.md` before filling a template. Several
templates deliberately ask for shallow depth of field; that is correct for a portrait and
wrong for anything the user intends to read, crop into, or animate.

## Quick Call (one shot)

Use `generate.sh` in this skill directory. It submits, polls, downloads, verifies, prints the path.

```bash
bash ~/.claude/skills/pollo-image/generate.sh "a minimalist logo for ACME, cyan gradient on white" [aspectRatio] [resolution] [mode] [model]
```

Defaults: aspectRatio `1:1`, resolution `4K`, mode `professional`, model `pollo-image-v2`.

The script writes to `~/Desktop/pollo-<taskId>.<ext>` and echoes the path. **The extension
reflects the format Pollo actually returned** (png, jpg or webp) — it is no longer assumed to
be PNG. Before printing the path it reports the real dimensions on stderr, e.g.
`format=png dimensions=3840x2160 bytes=8412355`. Then `Read` the path to show the image.

To discover models that may render sharper than `pollo-image-v2`:

```bash
bash ~/.claude/skills/pollo-image/generate.sh --list-models
```

## Fixing a soft or low-quality image

Work down this list in order — the early items cost nothing and fix most cases.

1. **Read what the script reported.** `dimensions=` tells you what you actually received. If
   it printed a `WARNING` that the long edge is well below the requested tier, the model
   silently fell back — the fix is a different model (`--list-models`), not a better prompt.
2. **Raise the resolution.** 2K → 4K doubles linear detail. This is the single biggest lever
   and the most common cause of "it looks soft".
3. **Confirm `mode` is `professional`.** `standard` is visibly softer for one credit less.
4. **Generate at the aspect ratio you will actually use.** Making a 1:1 image and cropping it
   to 16:9 throws away 44% of the pixels. Pass the target ratio up front.
5. **Audit the prompt for blur vocabulary.** *shallow depth of field*, *f/1.8*, *bokeh*,
   *soft focus*, *dreamy*, *atmospheric haze* all instruct the model to blur. *cinematic*
   often pulls in grain and haze too. If the user wants crisp, swap in *sharp focus*,
   *deep focus*, *crisp edges*, *high detail*, *tack sharp*.
6. **Check what happened after generation.** If the image looks fine at full size but soft in
   a video or on a slide, the loss is in the downstream resize, not in the generation. Check
   the output size of whatever consumed it (see the `image-to-motion` skill).
7. **Don't re-save a JPEG as JPEG.** If the script noted `format=jpg`, the image is already
   lossy. Export edits to PNG so the loss doesn't compound.
8. **Last resort — local finishing pass.** `enhance.sh` resamples with lanczos and applies an
   unsharp mask. It recovers apparent crispness from a merely-soft image; it cannot invent
   detail the model never rendered.

   ```bash
   bash ~/.claude/skills/pollo-image/enhance.sh "~/Desktop/pollo-123.png" [2x|1.5x|3840x2160] [sharpen]
   ```

   Defaults: `2x`, sharpen `0.6`. Always writes PNG next to the input as `<name>-enhanced.png`.
   Free — no API, no credits.

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
      "resolution": "4K"
    }
  }
  ```
  Returns `{ "data": { "id": <taskId>, "status": "waiting" } }`.
- **Poll:** `GET /generation/{id}` (NOT `/status` — that's 404). `data.status`: `waiting` → `processing` → `succeed` | `failed`.
- **Result URL:** `data.videoList[0].videoUrlNoWatermark` (field is named `videoList` even for images).
- **Models list:** `GET /config/text2image/models`.

The result URL is served through a CDN that redirects, so any hand-rolled download must use
`curl -L`. Without it you save the redirect stub, not the image.

## Parameters

| Field | Values | Notes |
|---|---|---|
| `modelName` | `pollo-image-v2` (default) | Others via `--list-models` |
| `mode` | `standard`, `professional` | Professional = cinema quality, +1 credit. Default. |
| `aspectRatio` | `1:1`, `3:2`, `2:3`, `3:4`, `4:3`, `16:9`, `9:16` | Generate at the ratio you'll ship |
| `resolution` | `1K`, `2K`, `4K` | 4K is the default, ~30 credits |

Fields beyond these are not asserted to exist. To experiment with one the API may support,
pass it through without editing the script:

```bash
POLLO_EXTRA_JSON='{"seed":1234}' bash generate.sh "your prompt"
```

Other env overrides: `POLLO_KEY_FILE`, `POLLO_OUT_DIR`.

## Multi-Variation Workflow

When user asks for N variations, submit all N in parallel (they're async), then poll once. The script supports single shots — for batch, loop the submit step with different prompts, collect IDs, then loop polling.

## Pitfalls

- `/agent/generate` and `/agent/generation/{id}` require `userId` in the body — use `/generation/*` instead.
- `/generation/{id}/status` returns `NOT_FOUND` — use `/generation/{id}` for both polling and results.
- Don't confuse with Higgsfield. Higgsfield uses `hf-api-key` + `hf-secret`; Pollo uses just `x-api-key`.
- Pollo's Soul-style models are photo/cinematic — for flat vector logos, lean hard on prompt keywords ("flat design", "vector-style", "sharp edges", "no gradient" if mono).
- A `.png` on disk is not proof of a PNG. Older versions of this script named every download
  `.png` regardless of content, so a stale file may be a JPEG — or an HTML error page.

## Related Memory

See `reference_pollo_api.md` in the user's memory for the same recipe in reference form.
