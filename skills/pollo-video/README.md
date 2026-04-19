# How to use the `pollo-video` skill

Step-by-step guide for generating videos with Pollo AI (Seedance default).

## One-time setup

Uses the same API key as `pollo-image` — at `~/.pollo/key.txt`. If not present, see `~/.claude/skills/pollo-image/README.md`.

## Daily use — three ways

### A. Ask Claude Code (easiest)
1. Type: *"generate a 5-second video of ..."* or *"make a clip of a spaceship landing"*
2. I auto-invoke the skill and run it.

### B. Terminal shortcut (requires `source ~/.bashrc` first time)
```bash
pollovid "your prompt here"
pollovid "your prompt" 5 16:9 480p seedance-2-0
```

### C. Full path
```bash
bash ~/.claude/skills/pollo-video/generate.sh "your prompt"
```

## Parameters

| Arg | Position | Notes | Default |
|---|---|---|---|
| prompt | 1 | any text | *required* |
| duration | 2 | seconds — **model-dependent valid values** | `5` |
| aspect ratio | 3 | `16:9` `9:16` `1:1` `3:4` `4:3` | `16:9` |
| resolution | 4 | `480p` `540p` `720p` `1080p` `4k` — **model-dependent** | `480p` |
| model | 5 | see Seedance table below | `seedance-2-0` |

**Model-dependent** = each video model has its own valid length/resolution combos. If you get a Zod validation error, the error message lists exact valid values per model — copy one.

## Seedance variants (cheapest to most expensive)

| Model | Typical cost | Notes |
|---|---|---|
| `seedance-pro-fast` | **1 credit** / 2s 480p | Smoke-test tier |
| `seedance` (Lite) | 5 credits / 5s 480p | Baseline |
| `seedance-pro-1-5` | 8–10 credits | 4–5s balanced |
| `seedance-pro` | 15 credits / 5s 480p | 30 credits @ 720p |
| `seedance-2-0-fast` | 30 credits / 5s 480p | Fast v2 |
| `seedance-2-0` *(default)* | **50 credits** / 5s 480p | Latest/best |

## Other model families Pollo supports

Via the same script, just change the `model` arg:
- **Kling** — `kling-v2-6`, `kling-v3`, `kling-video-o1`, `kling-v2-5-turbo`
- **Google Veo** — `veo3`, `veo3-1`, `veo3-fast`
- **OpenAI Sora** — `sora-2`, `sora-2-pro`
- **Runway** — (via dedicated endpoints — ask Claude if needed)
- **Luma** — `luma-ray-v2-0`, `luma-ray-v2-0-flash`
- **Pixverse** — `pixverse-v5-5`, `pixverse-v5`
- **Vidu** — `viduq3-pro`, `viduq3-turbo`
- **Pollo native** — `pollo-v3-0`, `pollo-v2-5`
- **Hailuo** — `minimax-hailuo-2.3`
- **Pika / Wan / Grok** — `pika-v2-2`, `wan-v2-7`, `grok-imagine-video`

## Troubleshooting

| Problem | Fix |
|---|---|
| `Not enough credits` | Top up at [pollo.ai](https://pollo.ai/api-platform) |
| `Invalid enum value. Expected 5 \| 10, received '2'` | Duration not allowed for that model — use a listed value |
| `Invalid enum value. Expected '720p' \| '1080p'` | Resolution not allowed — use a listed value |
| `videoModel` required / missing | You used image script (`modelName`) against video endpoint. Use `pollovid`, not `polloimg` |
| Timeout after 60 polls | Pollo slow — rerun, or try a `*-fast` variant |

## Where things live

| What | Path |
|---|---|
| Script | `C:\Users\User\.claude\skills\pollo-video\generate.sh` |
| Skill doc (for Claude) | `C:\Users\User\.claude\skills\pollo-video\SKILL.md` |
| User guide (this file) | `C:\Users\User\.claude\skills\pollo-video\README.md` |
| Generated videos | `C:\Users\User\Desktop\pollovid-<id>.mp4` |
