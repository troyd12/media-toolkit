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
polloimg "banner for lab24ai" 16:9 2K
polloimg "high-res poster" 2:3 4K
```

### C. Full path (works anywhere)
```bash
bash ~/.claude/skills/pollo-image/generate.sh "your prompt" 1:1 2K
```

---

## Parameters

| Arg | Position | Valid values | Default |
|---|---|---|---|
| prompt | 1st | any text | *required* |
| aspect ratio | 2nd | `1:1` `3:2` `2:3` `3:4` `4:3` `16:9` `9:16` | `1:1` |
| resolution | 3rd | `1K` `2K` `4K` | `2K` |
| mode | 4th | `standard` `professional` | `professional` |

**Credits:** 2K ≈ 18, 4K ≈ 30. 4K only on demand.

---

## Writing good prompts

- **Logos:** add *"minimalist, flat design, vector-style, sharp edges, white background, centered, symmetric"*
- **Photos:** add *"cinematic lighting, shallow depth of field, 35mm"*
- **Illustrations:** add *"flat vector illustration, pastel palette, clean lines"*
- Be specific about what to include AND exclude (*"no text"*, *"no people"*).

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `polloimg: command not found` | `source ~/.bashrc` or open a fresh Git Bash |
| `ERROR: API key not found` | Redo setup step 2 (Notepad adds `.txt` — that's fine) |
| `HTTP 403 Forbidden` | Key expired/revoked. New key → redo step 2 |
| `ERROR: timeout after 30 polls` | Pollo overloaded — rerun |
| Image blurry / off-brand | Sharpen prompt keywords and rerun |

---

## Where things live

| What | Path |
|---|---|
| API key | `C:\Users\User\.pollo\key.txt` |
| Script | `C:\Users\User\.claude\skills\pollo-image\generate.sh` |
| Skill doc (for Claude) | `C:\Users\User\.claude\skills\pollo-image\SKILL.md` |
| User guide (this file) | `C:\Users\User\.claude\skills\pollo-image\README.md` |
| Global 2K default | `C:\Users\User\.claude\CLAUDE.md` |
| Generated images | `C:\Users\User\Desktop\pollo-<id>.png` |
