# Fish Audio — vendor review for media-toolkit

**Date:** 2026-09-01
**Question:** should media-toolkit add a Fish Audio text-to-speech skill?
**Verdict:** **Yes — add it, paid-tier only, as `fish-audio-tts`.** It is the cheapest credible
TTS that fits this toolkit's shape (one curl call, binary out, no SDK), and it closes the
obvious gap: every clip this toolkit produces today is silent. Do *not* build on the free
tier or on self-hosted weights — see [Risks](#risks).

---

## 1. Why it fits this toolkit

| media-toolkit today | gap |
|---|---|
| `pollo-image` — stills | — |
| `pollo-video` — clips | silent |
| `image-to-motion` — ffmpeg motion on stills | silent |

There is no voice/audio backend. Adding TTS makes `image-to-motion` output narratable
(`ffmpeg -i clip.mp4 -i vo.mp3 -c:v copy -shortest out.mp4`), which is the single
highest-value addition to the current three skills.

Mechanically it is *simpler* than the Pollo skills: `/v1/tts` streams the audio bytes back
on the same request. No task id, no polling loop, no download step — the whole
`generate.sh` is one `curl --output`. Compare the 30-poll loop in
`skills/pollo-image/generate.sh:34`.

## 2. API surface

Verified by reading the official Python SDK source (`fish-audio-sdk` 1.3.0, Apache-2.0,
published 2026-03-10) rather than the docs site, which is blocked by this session's egress
policy.

| Item | Value | Source |
|---|---|---|
| Base URL | `https://api.fish.audio` | `fishaudio/client.py:46` |
| Auth | `Authorization: Bearer <key>` | `fishaudio/core/client_wrapper.py:68` |
| TTS | `POST /v1/tts` → raw audio stream | `fishaudio/resources/tts.py:145` |
| Model selection | **request header** `model: s2-pro` (not a body field) | `fishaudio/resources/tts.py:146` |
| Live streaming | `wss` `/v1/tts/live` | `fishaudio/resources/tts.py:347` |
| ASR | `POST /v1/asr` | `fishaudio/resources/asr.py:60` |
| Voice cloning | `POST /model`, multipart (`voices` file parts + `title`, `visibility`, `train_mode=fast`) | `fishaudio/resources/voices.py:191` |
| Credit balance | `GET /wallet/self/api-credit` | `fishaudio/resources/account.py:46` |

**Body encoding:** the SDK posts `Content-Type: application/msgpack` (ormsgpack). Fish's own
docs and published curl examples accept `application/json` for the same endpoint, which is
what a bash skill needs — this is the one thing in this review I could not confirm from
source and it must be smoke-tested before the skill ships.

Request fields and defaults (from `fishaudio/types/tts.py`):

| Field | Range / values | Default |
|---|---|---|
| `text` | required | — |
| `reference_id` | voice model id, e.g. `802e3bc2b27e49c2995d23ef70e6ac89` | none (default voice) |
| `references[]` | `{audio, text}` — instant clone, no model to create | `[]` |
| `format` | `mp3` `wav` `pcm` `opus` | `mp3` |
| `mp3_bitrate` | `64` `128` `192` | `128` |
| `sample_rate` | int Hz | format default |
| `latency` | `normal` (quality) / `balanced` (fast) | `balanced` |
| `prosody.speed` | 0.5–2.0 | 1.0 |
| `prosody.volume` | -20.0–20.0 dB | 0.0 |
| `chunk_length` | 100–300 | 200 |
| `temperature` / `top_p` | 0.0–1.0 | 0.7 / 0.7 |
| `normalize` | text cleanup | `true` |

Proposed one-shot call, matching the toolkit's existing style:

```bash
curl -sS -X POST https://api.fish.audio/v1/tts \
  -H "Authorization: Bearer $(tr -d '\r\n \t' < ~/.fish/key.txt)" \
  -H "Content-Type: application/json" \
  -H "model: s2-pro" \
  -d '{"text":"...","format":"mp3","mp3_bitrate":128,"latency":"normal"}' \
  --output ~/Desktop/fish-$(date +%s).mp3
```

## 3. Models

| Model header | Notes |
|---|---|
| `s2.1-pro` | current flagship; ~83 languages; ~90 ms time-to-first-audio claimed |
| `s2-pro` | previous gen, **the SDK default**; 4B params; sub-150 ms |
| `s1` | older; parenthesised emotion tags — `(happy)`, `(sad)` |
| `speech-1.5`, `speech-1.6` | deprecated, SDK emits a `DeprecationWarning` |
| `s2.1-pro-free` | free tier, see below |

Note the SDK's `Model` literal (`fishaudio/types/shared.py:26`) still lists only
`s1`/`s2-pro` — `s2.1-pro` shipped after SDK 1.3.0. Since the model is a plain header
string, that is a typing lag, not a capability gap, but it is a fair signal of how tightly
the SDK tracks the API.

## 4. Cost

Pay-as-you-go, **$15.00 per 1M UTF-8 bytes**, same rate for `s1`, `s2-pro` and `s2.1-pro` —
voice cloning, streaming and the community voice library are not priced separately.
1M bytes ≈ 180k English words ≈ 12 h of speech.

Practical scale for this toolkit: a 200-word voiceover is ~1.2 KB ≈ **$0.02**. A 10-minute
narration ≈ **$0.14**. Non-Latin scripts cost 2–3× per word because they are multi-byte.

Comparison at the same quality tier: ElevenLabs is roughly $165 per 1M characters, so Fish
is ~10× cheaper. Subscription plans (Free 8k credits, Plus ~$5.50/mo annual / 200 min, Pro
~$37.50/mo annual / 1,620 min) cover the web app; the API is billed separately and is the
only thing relevant here.

## 5. Free tier

`s2.1-pro-free` is genuinely free with no hard character cap, governed by a Fair Use policy,
**with no SLA** and throttling at Fish's discretion. Concurrency elsewhere on the API is 5
concurrent requests under $100 lifetime spend, 15 above it.

Good for evaluating the skill. Not something to hard-code as the default — a free model
string is the first thing a vendor withdraws, and this repo already ate that outcome once
(`3171a9a`, Straico sunset). Default to `s2-pro`, expose the model as an argument.

## 6. Risks

1. **Support and billing.** Independent review sites and Trustpilot carry a consistent
   pattern: unanswered support tickets, missing invoices, refund and cancellation trouble.
   No published SLA. For a personal toolkit this is tolerable; for anything billable it is
   the main reason to keep a second TTS backend viable.
2. **Open weights are not open source.** `fishaudio/fish-speech` (32.5k stars) ships under
   the *Fish Audio Research License* (updated 2026-03-07): research and non-commercial use
   only, and section III requires a separate written licence for any commercial purpose —
   explicitly including internal business operations. Self-hosting to dodge credits is not
   an option for commercial work.
3. **Free *plan* ≠ commercial rights.** The 8k-credit web plan is personal-use only. Vendor
   wording on this is inconsistent across pages; anything monetised should sit on a paid
   plan and the terms should be re-read at that point.
4. **Voice cloning consent.** Cloning is 15-seconds easy, which makes it easy to misuse.
   Any skill should clone only the user's own voice or a voice with documented permission,
   and default new models to `visibility: private` (which is the API default already).
5. **Long-form consistency.** Reported weak spot: pacing and inflection drift over long
   narration, and a single mispronounced word per take. Mitigation is chunking per
   paragraph and regenerating the bad chunk, not regenerating the whole read.
6. **Untested here.** No API key was available in this session and `fish.audio` /
   `docs.fish.audio` are blocked by the egress policy, so nothing below the SDK-source layer
   was executed. The JSON-body assumption in §2 is the one blocking unknown.

## 7. Recommendation

Ship a `fish-audio-tts` skill on the existing pattern — `SKILL.md` + `README.md` +
`generate.sh`, key at `~/.fish/key.txt`, output to `~/Desktop/fish-<ts>.mp3`, alias `fishtts`:

```bash
generate.sh "text or @file.txt" [voice-id] [format] [model] [speed]
# defaults: default voice, mp3, s2-pro, 1.0
```

Sequenced:

1. Smoke-test JSON vs msgpack on `/v1/tts` with a real key, and check
   `GET /wallet/self/api-credit` for the credit read-out the skill should print.
2. Ship TTS only. Skip ASR and voice-model creation in v1 — cloning carries the consent
   burden and multipart handling for no first-release benefit.
3. Add a `narrate` path in `image-to-motion` that muxes the mp3 over the generated clip.
   That is where the value is.
4. Keep the model a first-class argument so `s2.1-pro`, `s2.1-pro-free` and whatever
   replaces them are one flag away.

Reconsider if: the JSON body turns out unsupported (then it is a Python-SDK dependency, not
a bash skill, and the fit argument weakens), or the work becomes commercial and the support
record starts to matter.

## Sources

- [fish-audio-sdk on PyPI](https://pypi.org/project/fish-audio-sdk/) — SDK 1.3.0 source, read directly for §2
- [fishaudio/fish-speech](https://github.com/fishaudio/fish-speech) and its [LICENSE](https://raw.githubusercontent.com/fishaudio/fish-speech/main/LICENSE)
- [Fish Audio pricing & rate limits](https://docs.fish.audio/developer-guide/models-pricing/pricing-and-rate-limits)
- [S2.1 Pro free API announcement](https://fish.audio/blog/s2-1-pro-free-api/)
- [Fish Audio pricing, API billing & commercial use in 2026 (smallest.ai)](https://smallest.ai/blog/fish-audio-pricing-plans-api-billing-commercial-use-in-2026)
- [Fish Audio review 2026 (diyai.io)](https://diyai.io/ai-tools/audio-generation/reviews/fish-audio-review/)
- [Fish Audio review 2026: pricing, limits & verdict (saascrmreview)](https://saascrmreview.com/fish-audio-review/)
- [Trustpilot — fish.audio](https://www.trustpilot.com/review/fish.audio)
- [Fish Audio launches S2.1 Pro with 83 languages (TestingCatalog)](https://www.testingcatalog.com/fish-audio-launches-s2-1-pro-with-support-for-83-languages/)
