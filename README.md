# media-toolkit

Cinematic motion for still images in Claude Code — local, free, ffmpeg-based.

## What's inside

<!-- BEGIN GENERATED: skills-table -->
| Skill | Purpose | Backend |
|---|---|---|
| `image-to-motion` | Add cinematic motion to stills | Local ffmpeg — no API, no credits |
<!-- END GENERATED: skills-table -->

## One-line install

**macOS / Linux / Git Bash on Windows:**
```bash
git clone https://github.com/troyd12/media-toolkit.git ~/media-toolkit && \
mkdir -p ~/.claude/skills && \
cp -r ~/media-toolkit/skills/* ~/.claude/skills/ && \
echo "✅ media-toolkit skills installed to ~/.claude/skills/"
```

**PowerShell on Windows:**
```powershell
git clone https://github.com/troyd12/media-toolkit.git $HOME/media-toolkit
New-Item -ItemType Directory -Force -Path $HOME/.claude/skills | Out-Null
Copy-Item -Recurse -Force $HOME/media-toolkit/skills/* $HOME/.claude/skills/
Write-Host "media-toolkit skills installed"
```

<!-- BEGIN GENERATED: uninstall -->
After install, the skills auto-load in every Claude Code session. To uninstall, delete `image-to-motion/` from `~/.claude/skills/`.
<!-- END GENERATED: uninstall -->

### 2. Prerequisites

<!-- BEGIN GENERATED: prerequisites -->
`image-to-motion` needs no API key — only ffmpeg installed (`winget install Gyan.FFmpeg`).
<!-- END GENERATED: prerequisites -->

### 3. Shell aliases (optional)

Add to `~/.bashrc`:
<!-- BEGIN GENERATED: aliases -->
```bash
alias motionize='bash ~/.claude/skills/image-to-motion/generate.sh'
```
<!-- END GENERATED: aliases -->

PowerShell equivalents go in `$PROFILE`.

## Usage

Inside Claude Code, just ask in natural language:

- *"add ken burns motion to that image"* → `image-to-motion`
- *"5 second cinematic clip from this PNG, vertical for Reels"* → `image-to-motion` with `pan-up` 1080x1920

Or invoke directly from any terminal via the aliases above.

## License

UNLICENSED — personal use only.
