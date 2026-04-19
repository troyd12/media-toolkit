# media-toolkit

AI image + video generation toolkit for Claude Code.

## What's inside

| Skill | Purpose | Backend |
|---|---|---|
| `pollo-image` | Text-to-image | Pollo AI (`pollo-image-v2`, others) |
| `pollo-video` | Text-to-video | Pollo AI (Seedance, Kling, Veo, etc.) |
| `straico-image` | Text-to-image | Straico (Flux, DALL-E, Ideogram, Recraft, Imagen, GPT Image, …) |
| `image-to-motion` | Add cinematic motion to stills | Local ffmpeg — no API, no credits |

## Setup

### 1. Install the plugin

Symlink or copy the plugin into your Claude Code plugins directory, OR install via your Claude Code marketplace if published.

For a personal install, simply make sure each skill in `skills/` is also present in `~/.claude/skills/`.

### 2. API keys

Save raw keys (no quotes, no banners) into these files:

| Service | Path |
|---|---|
| Pollo AI | `~/.pollo/key.txt` |
| Straico | `~/.straico/key.txt` |

`image-to-motion` requires no key — only ffmpeg installed (`winget install Gyan.FFmpeg`).

### 3. Shell aliases (optional)

Add to `~/.bashrc`:
```bash
alias polloimg='bash ~/.claude/skills/pollo-image/generate.sh'
alias pollovid='bash ~/.claude/skills/pollo-video/generate.sh'
alias straicoimg='bash ~/.claude/skills/straico-image/generate.sh'
alias motionize='bash ~/.claude/skills/image-to-motion/generate.sh'
```

PowerShell equivalents go in `$PROFILE`.

## Usage

Inside Claude Code, just ask in natural language:

- *"generate a logo for X"* → `pollo-image` or `straico-image` (with template-driven prompt)
- *"add ken burns motion to that image"* → `image-to-motion`
- *"5 second cinematic clip from this PNG, vertical for Reels"* → `image-to-motion` with `pan-up` 1080x1920

Or invoke directly from any terminal via the aliases above.

## License

UNLICENSED — personal use only. APIs are subject to their respective providers' terms.
