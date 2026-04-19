---
name: straico-image
description: Use when the user asks to generate an image via Straico, mentions Straico, DALL-E, Ideogram, Flux, Imagen, Recraft, Nano Banana, Seedream, or Qwen — or when Pollo is unavailable. Submits a text-to-image job to Straico's API (synchronous), downloads the PNG to the user's Desktop.
---

# Straico Image Generation

## Overview

Straico's API exposes ~20+ image models (DALL-E 3, Flux 1.1, Ideogram V1/V2/V3, Imagen 4, Recraft V3, Nano Banana, Seedream, Qwen, GPT Image, Bagel) through one unified endpoint. **Synchronous — no polling**.

**Default model:** `flux/1.1` (~250 coins for landscape). User has ~361k coins = ~1400 images.

## Prerequisites

- Straico key at `~/.straico/key.txt` (starts `Pu-`).
- Endpoint expects `Authorization: Bearer <key>` header.

## Quick Call

```bash
bash ~/.claude/skills/straico-image/generate.sh "prompt" [size] [variations] [model]
```

Alias: `straicoimg "prompt"`

**Sizes:** `square` (1:1) · `landscape` (16:9-ish) · `portrait` (9:16-ish). NOT a pixel count — Straico maps these to model-specific resolutions.

**Variations:** 1–N images per call.

Output: `~/Desktop/straico-<timestamp>.png` (or `-1.png`, `-2.png` for N>1).

## Template Library

Before generating, match the user's request to a template in `templates.md` (reuses the pollo-image template vocabulary: logo, headshot, product-shot, etc.). Fill slots, pick a sensible size, generate.

## Model Catalog

| Model | ID | Notes | Approx cost (landscape) |
|---|---|---|---|
| **Flux 1.1** *(default)* | `flux/1.1` | Balanced realism + speed | 250 coins |
| DALL-E 3 | `openai/dall-e-3` | OpenAI's classic | 90–120 |
| Ideogram V3 (Fal) | `fal-ai/ideogram/v3` | Best text rendering in images | ~90 |
| GPT Image 1 | `openai/gpt-image-1` | OpenAI's newest | higher |
| Imagen 4 (Fal) | `fal-ai/imagen4/preview` | Google's flagship | ~120 |
| Recraft V3 (Fal) | `fal-ai/recraft/v3/text-to-image` | Excellent vector/logo | ~90 |
| Nano Banana | `fal-ai/nano-banana` | Cheap & fast | very cheap |
| Seedream 4.0 Edit | `fal-ai/bytedance/seedream/v4/edit` | Image-to-image edits | ~90 |
| Qwen Image | `fal-ai/qwen-image` | Alibaba's model | ~90 |

Full list: `GET /v1/models` → `data.image[]`.

## API Reference

- **Base:** `https://api.straico.com`
- **Auth:** `Authorization: Bearer <key>`
- **Submit:** `POST /v1/image/generation`
  ```json
  { "model": "flux/1.1", "description": "...", "size": "landscape", "variations": 1 }
  ```
- **Response (HTTP 201, synchronous):**
  ```json
  { "data": { "images": ["https://..."], "zip": "https://...", "price": { "total": 250 } }, "success": true }
  ```
- **Models list:** `GET /v1/models` → `data.image`.
- **Account info / balance:** `GET /v0/user` → `data.coins`.

## Pitfalls

- Runway / Kling / Veo / Vidu models appear in the model list with `allowed_durations > 0` but are **NOT accessible via this endpoint** (server returns "Cannot read properties of undefined (reading 'generate')"). Straico's video capability is web-app only.
- `size` is a string enum (`square` / `landscape` / `portrait`), not pixel dimensions. Different models have different actual resolutions.
- Synchronous — no polling. If the model is slow, curl will just wait.

## How the User Runs It

1. **Claude Code:** "generate via Straico: a ..."; "make a Straico image of ..."; "use Flux to create ...".
2. **Terminal:** `straicoimg "prompt" landscape 1 flux/1.1`
3. **Full path:** `bash ~/.claude/skills/straico-image/generate.sh "prompt"`

## Resolution policy

Straico's `size` enum is coarser than Pollo's 1K/2K/4K. Honor the user's global 2K preference by preferring models/sizes known to output high-res (GPT Image, Imagen 4). Flux 1.1 landscape is roughly 2K-equivalent.
