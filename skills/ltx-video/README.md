# How to use the `ltx-video` skill

Generating video with Lightricks' LTX model via fal.ai, from Claude Code or your terminal.

## One-time setup

**1. Get a fal API key**
Sign in at [fal.ai](https://fal.ai/dashboard/keys) and create a key. This is separate from your
Pollo key — different service, separate billing.

**2. Save it locally**
In Git Bash:
```bash
mkdir -p ~/.fal && notepad ~/.fal/key.txt
```
Paste the key → Ctrl+S → close. If fal gave you a `key_id:key_secret` pair, paste the whole
string including the colon.

**3. Verify before spending anything**
```bash
bash ~/.claude/skills/ltx-video/generate.sh --check
```
**A 422 means it worked** — auth is good and the endpoint exists, it's just refusing an empty
request. 401/403 means the key is wrong; 404 means the endpoint id is wrong.

---

## Daily use

### A. Ask Claude Code
- *"make an LTX clip of a rain-soaked alley at night"*
- *"generate a talking-head video with LTX saying 'welcome back'"*

### B. Terminal
```bash
bash ~/.claude/skills/ltx-video/generate.sh "your prompt"
bash ~/.claude/skills/ltx-video/generate.sh "your prompt" --args '{"resolution":"1080p","duration":6}'
```

Optional alias for `~/.bashrc`:
```bash
alias ltxvid='bash ~/.claude/skills/ltx-video/generate.sh'
```

Output lands at `~/Desktop/ltx-<request_id>.mp4`.

---

## Parameters

| Arg | Form | Notes |
|---|---|---|
| prompt | 1st positional | Required. One flowing paragraph — see below. |
| `--args` | JSON object | Everything else: resolution, duration, aspect ratio, seed. |
| `--model` | endpoint id | Default `fal-ai/ltx-2.3/text-to-video`. |
| `--check` | flag | Auth + endpoint test, no generation. |

**Why isn't there a `--resolution` flag?** Parameter names differ between LTX endpoints. A
guessed name returns a 422 that looks like a broken script, so this passes through only what you
give it. Get the real names from the endpoint's **API** tab on fal, then:

```bash
--args '{"resolution":"1080p","aspect_ratio":"16:9","duration":6}'
```

Env vars: `FAL_KEY`, `FAL_KEY_FILE`, `LTX_MODEL`, `LTX_ARGS`, `LTX_OUT_DIR`.

---

## Writing prompts for LTX

LTX does **not** want the tag-soup style (`4k, cinematic, masterpiece`) that works on some
image models. Lightricks' own guidance:

> One flowing paragraph. Chronological. Start with the main action. Literal and precise, like a
> cinematographer writing a shot list. Under 200 words.

Order within the paragraph: main action → movements and gestures → appearance → background →
camera angle and movement → lighting and colour → any sudden change.

`templates.md` has fill-in-the-blank versions for establishing shots, character action,
dialogue, product reveals, b-roll and logo motion.

**For a talking clip** (audio-capable endpoints only), put the spoken words in quotes inside the
paragraph and describe non-speech sounds in place: *"...he speaks with a deep voice, saying, 'I
think it's so good.' A short audible breath is heard, then he continues..."*

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `HTTP 401` / `403` | Key wrong or revoked. Recheck `~/.fal/key.txt` — include the colon if it's an id:secret pair |
| `HTTP 404` | Endpoint id wrong. Check it on the model's fal page and pass `--model` |
| `HTTP 422` on a real run | An argument name the endpoint doesn't take. Check its API tab; the argument names are per-endpoint |
| `HTTP 422` on `--check` | Expected — that's the success signal |
| `downloaded file is not an MP4` | The CDN served an error page. Rerun; if it persists the account may be out of credits |
| `timed out after 90 polls` | Queue backed up. The `request_id` is printed — the job may still finish on fal's dashboard |
| Clip is soft | Check resolution and frame count first (see below), then the prompt |
| Clip drifts or invents an event | Add an explicit "the motion continues evenly without any sudden change" clause |
| Logo/text gets redrawn wrong | Expected — generative video redraws marks. Use `image-to-motion` on a still instead |

---

## Why is my clip soft?

1. **Resolution and frame count are on a grid.** LTX works on resolutions divisible by 32 and
   frame counts divisible by 8 plus 1 (121, 257). Off-grid input gets padded and cropped
   silently. Hosted endpoints usually round for you, but it's the first thing to check.
2. **Past ~720×1280 or ~257 frames, quality drops.** Bigger is not better with this model.
3. **Compare like with like.** LTX at 480p against Seedance at 1080p tells you nothing about
   either model.
4. **Steps and guidance** (where the endpoint exposes them): 40+ steps for quality, guidance
   3–3.5.

---

## Where things live

| What | Path |
|---|---|
| fal API key | `C:\Users\User\.fal\key.txt` |
| Script | `C:\Users\User\.claude\skills\ltx-video\generate.sh` |
| Skill doc (for Claude) | `C:\Users\User\.claude\skills\ltx-video\SKILL.md` |
| Prompt templates | `C:\Users\User\.claude\skills\ltx-video\templates.md` |
| Generated clips | `C:\Users\User\Desktop\ltx-<request_id>.mp4` |
