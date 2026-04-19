# How to use the `straico-image` skill

Step-by-step guide for generating images via Straico (20+ models, synchronous, cheap).

## One-time setup

Straico key should be at `~/.straico/key.txt` (starts `Pu-`). If missing:
```bash
notepad ~/.straico/key.txt
```

## Daily use — three ways

### A. Ask Claude Code
*"Generate a Straico image of ..."*, *"use Flux to create..."*, *"make a logo with Recraft"*.

### B. Terminal shortcut
```bash
straicoimg "your prompt"
straicoimg "your prompt" landscape 1 flux/1.1
straicoimg "a logo for ACME" square 1 fal-ai/recraft/v3/text-to-image
```

### C. Full path
```bash
bash ~/.claude/skills/straico-image/generate.sh "your prompt"
```

## Parameters

| Arg | Position | Valid values | Default |
|---|---|---|---|
| prompt | 1 | any text | *required* |
| size | 2 | `square` · `landscape` · `portrait` | `landscape` |
| variations | 3 | 1–N | `1` |
| model | 4 | see model catalog in SKILL.md | `flux/1.1` |

## Quick model picker

| Use case | Model arg | Why |
|---|---|---|
| **General / best default** | `flux/1.1` | Balanced quality + speed |
| **Logo / vector / icon** | `fal-ai/recraft/v3/text-to-image` | Clean vector aesthetic |
| **Text in image** | `fal-ai/ideogram/v3` | Best readable lettering |
| **Photorealism** | `openai/gpt-image-1` or `fal-ai/imagen4/preview` | Premium quality |
| **Cheap + fast** | `fal-ai/nano-banana` | Lowest cost |
| **Edits (image-to-image)** | `fal-ai/bytedance/seedream/v4/edit` | Modify existing images |

## Troubleshooting

| Problem | Fix |
|---|---|
| `straicoimg: command not found` | `source ~/.bashrc` or restart terminal |
| `failed: {...}` with `success:false` | Body validation — check model ID spelling |
| `Unauthorized` | Key stale — regenerate at pollo.ai → update `~/.straico/key.txt` |
| Image is generic / ignored details | Pick Ideogram or Imagen instead of Flux |
| Need 4K / higher res | Use `openai/gpt-image-1` or `fal-ai/imagen4/preview` |

## Where things live

| What | Path |
|---|---|
| API key | `C:\Users\User\.straico\key.txt` |
| Script | `C:\Users\User\.claude\skills\straico-image\generate.sh` |
| Skill (for Claude) | `C:\Users\User\.claude\skills\straico-image\SKILL.md` |
| Templates | `C:\Users\User\.claude\skills\straico-image\templates.md` |
| User guide (this file) | `C:\Users\User\.claude\skills\straico-image\README.md` |
| Generated images | `C:\Users\User\Desktop\straico-<timestamp>.png` |

## Check balance

```bash
curl -sS https://api.straico.com/v0/user -H "Authorization: Bearer $(cat ~/.straico/key.txt)"
```
