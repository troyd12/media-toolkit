# How to use the `pollo-image` skill

Step-by-step user guide for generating images with Pollo AI from Claude Code or your terminal.

## One-time setup

**1. Get a Pollo API key**
Sign in at [pollo.ai/api-platform](https://pollo.ai/api-platform) and create an API key.

**2. Save the key locally**
In Git Bash:
```bash
notepad ~/.pollo/key.txt
```
Paste the key → Ctrl+S → close.

**3. Reload your shell**
```bash
source ~/.bashrc
```
Activates the `polloimg` alias.

---

## Daily use — three ways

### A. Ask Claude Code (easiest)
1. Start any Claude Code session.
2. Type plain English:
   - *"generate a logo for Acme Corp"*
   - *"make an image of a neon cityscape, 16:9"*
3. Wait ~30–60s. The image opens automatically.

### B. Terminal shortcut
```bash
polloimg "your prompt here"
polloimg "banner for lab24ai" 16:9
polloimg "cheaper draft" 1:1 2K
```

### C. Full path (works anywhere)
```bash
bash ~/.claude/skills/pollo-image/generate.sh "your prompt" 1:1 4K
```

---

## Parameters

| Arg | Position | Valid values | Default |
|---|---|---|---|
| prompt | 1st | any text | *required* |
| aspect ratio | 2nd | `1:1` `3:2` `2:3` `3:4` `4:3` `16:9` `9:16` | `1:1` |
| resolution | 3rd | `1K` `2K` `4K` | `4K` |
| mode | 4th | `standard` `professional` | `professional` |

**Credits:** 2K ≈ 18, 4K ≈ 30. **4K is now the default** — the old 2K default was the main
reason images came out looking soft. Pass `2K` explicitly when you'd rather save credits.

The saved file uses whatever extension matches the format Pollo actually returned — `.png`,
`.jpg` or `.webp`. Earlier versions named every download `.png` regardless, so an old file on
your Desktop may not be the format its name claims.

---

## Writing good prompts

- **Logos:** add *"minimalist, flat design, vector-style, sharp edges, white background, centered, symmetric"*
- **Photos:** add *"cinematic lighting, shallow depth of field, 35mm"*
- **Illustrations:** add *"flat vector illustration, pastel palette, clean lines"*
- Be specific about what to include AND exclude (*"no text"*, *"no people"*).

**If you want it sharp, don't ask for blur.** *shallow depth of field*, *f/1.8*, *bokeh*,
*soft focus* and *dreamy* all tell the model to blur, and it will. For crisp output use
*sharp focus*, *deep focus*, *crisp edges*, *high detail*. Anything containing text or a logo,
and anything you plan to crop into or animate, should be crisp.

**Generate at the shape you'll actually use.** Making a square image and cropping it to 16:9
throws away 44% of the pixels — as visible a loss as dropping a resolution tier.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `polloimg: command not found` | `source ~/.bashrc` or open a fresh Git Bash |
| `ERROR: API key not found` | Redo setup step 2 (Notepad adds `.txt` — that's fine) |
| `HTTP 403 Forbidden` | Key expired/revoked. New key → redo step 2 |
| `ERROR: timed out after 40 polls` | Pollo overloaded — rerun |
| `WARNING: long edge is ...px` | The model ignored 4K and fell back. Try another model: `polloimg --list-models` |
| `ERROR: downloaded file is not a PNG, JPEG or WebP` | The CDN served an error page instead of the image. Rerun; if it persists the key may be out of credits |
| Image blurry / soft | See **Why is my image soft?** below |
| Image off-brand | Sharpen prompt keywords and rerun |

---

## Why is my image soft?

Work down this list. The first four cost nothing.

1. **Read the script's output.** It prints `dimensions=WxH` before the file path. That tells
   you what you actually got rather than what you asked for.
2. **Use 4K.** This is now the default, but an old alias or a saved command may still pass
   `2K`. It is the biggest single lever.
3. **Keep `mode` at `professional`.** `standard` is visibly softer to save one credit.
4. **Check your prompt for blur words** (see *Writing good prompts* above), and generate at
   the aspect ratio you'll ship.
5. **Soft only after editing?** Then the generation was fine and the loss happened downstream
   — check the export size in whatever tool consumed it.
6. **Still soft — finishing pass.** Upscale and sharpen locally, free:

   ```bash
   bash ~/.claude/skills/pollo-image/enhance.sh ~/Desktop/pollo-123.png
   bash ~/.claude/skills/pollo-image/enhance.sh ~/Desktop/pollo-123.png 2x 0.8
   bash ~/.claude/skills/pollo-image/enhance.sh ~/Desktop/pollo-123.png 3840x2160
   ```

   Writes `pollo-123-enhanced.png` next to the original. Needs ffmpeg
   (`winget install Gyan.FFmpeg`). This makes a soft image *look* crisper — it cannot add
   detail that was never generated. If the subject itself is mush, regenerate instead.

---

## Where things live

| What | Path |
|---|---|
| API key | `C:\Users\User\.pollo\key.txt` |
| Script | `C:\Users\User\.claude\skills\pollo-image\generate.sh` |
| Upscale/sharpen script | `C:\Users\User\.claude\skills\pollo-image\enhance.sh` |
| Skill doc (for Claude) | `C:\Users\User\.claude\skills\pollo-image\SKILL.md` |
| User guide (this file) | `C:\Users\User\.claude\skills\pollo-image\README.md` |
| Global resolution default | `C:\Users\User\.claude\CLAUDE.md` |
| Generated images | `C:\Users\User\Desktop\pollo-<id>.png` / `.jpg` / `.webp` |
