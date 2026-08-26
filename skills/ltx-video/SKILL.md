---
name: ltx-video
description: Use when the user asks to generate video with LTX, LTX-2, LTX-2.5, LTXV, or Lightricks' video model — including video with synchronized audio. Submits a text-to-video job to LTX on fal.ai, polls the queue, downloads the MP4.
---

# LTX Video Generation (fal.ai)

## Overview

LTX is Lightricks' video foundation model. LTX-2 is the first DiT-based **audio-video**
foundation model — it generates synchronized audio and video in one pass, which no other model
in this toolkit does. This skill wraps the fal.ai hosted route.

**Default endpoint:** `fal-ai/ltx-2.3/text-to-video`. Confirm the exact id on the model's fal
page before a first run — see *Verifying the endpoint* below.

## Why fal.ai for this

| Route | Verdict |
|---|---|
| **fal.ai** *(this skill)* | Recommended. Lightricks links it as an official hosted route, it carries current LTX versions, and the queue API is stable. Needs its own key. |
| Pollo AI | Already wired up in `pollo-video` with a key you have. Best for a quick A/B against Seedance — but it is an aggregator, so it lags on new LTX versions and may not carry the newest. |
| Lightricks direct | Newest models first, via `console.ltx.video`. Another integration to build; worth it only if you need LTX-2.5-class output the aggregators don't have yet. |
| Local / self-hosted | Not practical here. LTX-2.5 is a 22B transformer and the weight set is ~66 GiB, CUDA-first. Fine on a serious GPU box, not on the Windows machine this toolkit targets. |

If the goal is *"is LTX better than what we're using"*, run it through `pollo-video` first — same
key, same wrapper, no new setup. Reach for this skill when you want current LTX or audio.

## Prerequisites

- A fal API key from https://fal.ai/dashboard/keys, saved raw at `~/.fal/key.txt`, or exported
  as `FAL_KEY`. This is **not** the Pollo key — different service, separate billing.
- Never paste keys into chat. If the user does, tell them to rotate it.

## Quick Call

```bash
bash ~/.claude/skills/ltx-video/generate.sh "your prompt"
bash ~/.claude/skills/ltx-video/generate.sh "your prompt" --args '{"resolution":"1080p","duration":6}'
bash ~/.claude/skills/ltx-video/generate.sh "your prompt" --model fal-ai/ltx-2.3/text-to-video
```

Output: `~/Desktop/ltx-<request_id>.mp4`, path echoed on success.

**Only `prompt` is sent by default.** Every other parameter goes through `--args` verbatim.
This is deliberate: parameter names differ between LTX endpoints, and a guessed name comes back
as a 422 that reads like a broken script. Look the names up on the model's fal API tab, then
pass them.

## Verifying the endpoint

Before the first real run, confirm the key and endpoint without spending credits:

```bash
bash ~/.claude/skills/ltx-video/generate.sh --check
```

It POSTs an empty body. **A 422 is the success case** — it means auth worked and the endpoint
exists, and the model is merely rejecting the empty arguments. A 401/403 is a key problem; a
404 means the endpoint id is wrong.

## Prompting LTX

LTX responds to a specific prompt shape, and this is Lightricks' own guidance — it is not the
same style that works for Seedance or Kling. Getting it wrong is the most common reason LTX
output disappoints:

- **One flowing paragraph.** Not a list, not comma-separated tags.
- **Chronological.** Describe what happens in the order it happens.
- **Start directly with the main action**, in a single sentence.
- **Then layer in**, in roughly this order: specific movements and gestures → character and
  object appearance → background and environment → camera angle and movement → lighting and
  colour → any sudden change or event.
- **Literal and precise.** Think cinematographer writing a shot list, not poet.
- **Under 200 words.**

For audio-capable LTX-2 endpoints, spoken lines go in the prompt as quoted dialogue, and
audible non-speech events are described in place ("a quick sniff is heard"). See `templates.md`.

Lightricks' prompting guide: https://ltx.io/blog/prompting-guide-for-ltx-2

## Quality constraints

These come from the LTX-Video repository's parameter guide. **They apply to the open 0.9.x
line** — hosted endpoints usually handle the rounding for you, but they explain a whole class
of "why is it soft / why is it cropped" results:

- Resolution must be **divisible by 32**; frame count must be **divisible by 8, plus 1**
  (e.g. 121, 257). Off-grid input is padded with -1 and then cropped — silently.
- The model works best **under 720×1280** and **under 257 frames**. Pushing past that trades
  quality, it doesn't add it.
- Guidance scale **3–3.5**.
- Inference steps: **40+** for quality, 20–30 for speed.

If a clip looks soft, check the frame/resolution grid before touching the prompt.

## Models

LTX-2.5 is the current recommended model in Lightricks' repo; LTX-2.3 is marked legacy there,
though it is what hosted providers most commonly expose today. Checkpoints are **not**
interchangeable between versions, and a LoRA only works with the model it was trained on.

The open 0.9.x line (`ltxv-13b-0.9.8-dev`, `-distilled`, `ltxv-2b-0.9.8-distilled`, plus fp8
quantised variants) is what you'd run locally — see the LTX-Video repo if that ever becomes
relevant.

## API Reference

Verified against the official `fal-client` 1.0.1 source, not from memory:

- **Auth:** `Authorization: Key <FAL_KEY>`
- **Submit:** `POST https://queue.fal.run/<endpoint-id>` — body is the arguments object itself,
  not wrapped in anything.
- **Submit returns:** `{ "request_id": ..., "status_url": ..., "response_url": ..., "cancel_url": ... }`
- **Poll:** `GET <status_url>` → `status` is `IN_QUEUE` → `IN_PROGRESS` → `COMPLETED`
- **Result:** `GET <response_url>` → the model's output JSON

**Use the `status_url` and `response_url` from the submit response.** Do not rebuild them: fal's
queue path is `queue.fal.run/<owner>/<alias>/requests/<id>`, which drops the endpoint subpath
(`/text-to-video`). Reconstructing it by hand is a reliable way to get a 404.

## Pitfalls

- The result URL is CDN-served and redirects — any hand-rolled download needs `curl -L`, and
  `--fail`, or you save an error page as a `.mp4`. The script verifies the `ftyp` box before
  keeping the file.
- fal keys are sometimes issued as `<key_id>:<key_secret>`. That whole string is the key — paste
  it as-is, colon included.
- Video generation is slow. The script polls up to ~12 minutes.
- Audio-capable endpoints return audio muxed into the MP4. If a clip seems silent, check the
  endpoint actually generates audio rather than assuming the download dropped it.
- Don't compare LTX against another model at different resolutions or durations. Match them, or
  you're measuring the tier rather than the model.

## Related

- `pollo-video` — the other route to LTX, plus ~48 other video models on a key you already have.
- `image-to-motion` — free ffmpeg camera moves on a still, when you don't need generated motion.
