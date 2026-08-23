# The Early AI-dopters Gumroad vault — how it works, and what's in it for media-toolkit

Notes on [`earlyaidopters/gumroad-resources`](https://github.com/earlyaidopters/gumroad-resources),
a public mirror of Mark Kashef's Gumroad store (156 published resources, ~733 MB).
Written to answer two questions: *how is that repo built*, and *is any of it useful here*.

---

## 1. What the repo is

A self-updating storefront mirror. Every free Gumroad resource is pulled down, unpacked,
indexed, and rendered into a browsable README — no manual curation step.

```
gumroad-resources/
├── README.md              # fully generated: latest-10 table + 6 category tables
├── manifest.json          # the index: 156 products, one record each
├── resources/<slug>/
│   ├── README.md          # generated per-resource page
│   ├── content.md         # the Gumroad content page, verbatim
│   ├── meta.json          # slug, permalink, numeric_id, category, files, hashes
│   ├── files/             # the actual product downloads
│   └── unpacked/          # every .zip in files/ extracted, so GitHub can render it
├── tools/                 # the sync pipeline (1,090 lines total)
└── .github/workflows/sync.yml
```

`manifest.json` record shape:

```json
{
  "slug": "bench-studio-ownership-kit",
  "permalink": "tppav",
  "numeric_id": 13880078,
  "name": "Bench Studio Ownership Kit",
  "status": "published",
  "archived": false,
  "category": "Other",
  "content_hash": "b5c33a7dec22615f",
  "files": ["bench_studio_ownership_kit.zip"],
  "has_content": true
}
```

### Content breakdown

| Category | Count |
|---|---:|
| 🎯 Prompting & Engineering Skills | 37 |
| 🔌 Automation & Workflows (n8n, Replit, Make.com) | 29 |
| Other | 26 |
| 🧠 Custom GPTs & AI Agents | 26 |
| 🗂️ Frameworks, Meta Techniques & Experiments | 23 |
| 📊 Tools, Cheat Sheets & Evaluations | 15 |

110 of the 156 ship actual downloadable files; the other 46 are content-page-only
(links to Notion docs, Custom GPTs, Scribe walkthroughs).

---

## 2. The sync pipeline

`.github/workflows/sync.yml` runs on `cron: "0 */6 * * *"` plus `workflow_dispatch`,
with `contents: write` + `issues: write` and a `concurrency` group that queues rather
than cancels. It calls `tools/sync.sh`, which is the whole job in 42 lines:

1. **Write the cookie.** `$GUMROAD_COOKIE` secret → `~/.config/gumroad/cookies`, `chmod 600`.
   The public Gumroad API only exposes metadata, so the pull authenticates as the
   logged-in seller via a `_gumroad_app_session` cookie.
2. **`gumroad-pull check`** — if the session is dead, touch `$RUNNER_TEMP/auth_failed`
   and exit 1.
3. **`gumroad-pull products`** → product index JSON.
4. **`gumroad-pull pull --all --published-only --max-file-mb=95`** → downloads into
   `resources/`. Committed files act as the download cache, so re-runs are cheap.
5. **`youtube_map.py`** (only if `$YOUTUBE_API_KEY` is set) refreshes video pairings.
   Failure here is non-fatal — it keeps the existing map.
6. **`build_repo.py --repo . --index …`** — re-renders README + manifest.

Then back in the workflow: commit as `gumroad-sync[bot]` **only if `git status` is
non-empty**, and push.

### Three failure modes, each wired to a GitHub issue

- **Expired cookie** → the `auth_failed` sentinel file distinguishes an auth failure
  from any other error. Opens (or reuses) an issue titled *"Gumroad session cookie
  expired — sync paused"* and fails the run.
- **Any other sync error** → fails loudly, no issue.
- **Unpaired video** → `check_pairings.py` flags any of the 5 newest live resources
  with no YouTube video. Opens an issue, comments on it while it persists, and
  **auto-closes it** once pairing is restored. `tools/README.md` says this exists
  because forgetting used to fail silently — the drop shipped with a dash in the
  Watch column.

### `build_repo.py` — the interesting part (340 lines)

- `MAX_FILE_MB = 95`, deliberately under GitHub's 100 MB hard limit. Oversized **zips
  that were already unpacked** get dropped from `files/` — contents stay browsable in
  `unpacked/`, and the README notes "get the full archive on Gumroad". Oversized
  non-zips just get a note.
- `SECRET_RE` scans every text file in `files/`, `unpacked/`, and the content page, and
  rewrites anything key-shaped to `REDACTED_SECRET_replace_with_your_own_key`. The
  redaction count and the list of affected slugs go into the manifest. This runs
  *before* anything is committed.
- `GENERATED = {"README.md", "content.md", "unpacked"}` is excluded from `dir_hash()`,
  so `content_hash` tracks the real product files only — generated output can't cause
  spurious churn.
- Ordering is newest-first, driven by `--index`; `tools/README.md` warns that omitting
  `--index` breaks the storefront ordering.
- YouTube pairing is **authoritative, not fuzzy**: `youtube_map.py` matches a video to
  a resource by finding `gumroad.com/l/<permalink>` in the video description. That's
  why the README can embed `i.ytimg.com/vi/<id>/maxresdefault.jpg` thumbnails with
  confidence.

### Patterns worth stealing

Regardless of whether we mirror anything from this vault, four ideas port cleanly to
`media-toolkit`:

1. **Generated README from a manifest.** One `build_repo.py`-style script owns the
   README; the manifest is the source of truth. Adopted — `tools/build_readme.py`.
   It paid for itself the day Pollo was dropped: two skills left the tree and every
   table, the alias list, and the plugin manifest followed from one command.
2. **Redaction on the way in, not on review.** A `SECRET_RE` pass over anything about
   to be committed is cheap insurance for any skill that ships an API recipe.
3. **Self-closing issues for silent failures.** The pairing check is a good template:
   detect the silent-failure condition, open one issue, comment while it persists,
   close it automatically on recovery.
4. **Hash what's authored, not what's generated.** Excluding generated paths from the
   content hash is what keeps the "commit only if changed" step honest.

---

## 3. What's actually relevant to media-toolkit

`media-toolkit` is now a single local skill, `image-to-motion` — the Pollo AI skills were
removed on 2026-08-23, since Pollo is no longer used. That makes the vault's API guides more
interesting rather than less: they are the candidate backends if a generation skill returns.
Ten of the 156 resources touch media generation:

| Resource | What's in it | Useful here? |
|---|---|---|
| [`sora-studio-builder`](https://github.com/earlyaidopters/gumroad-resources/tree/main/resources/sora-studio-builder) | `openai-video-api-guide.md` + a master prompt to build a Sora web UI | **Yes** — the API guide is a reference for a future `sora-video` skill; the master prompt is not our shape |
| [`banana-squad-image-agent-team`](https://github.com/earlyaidopters/gumroad-resources/tree/main/resources/banana-squad-image-agent-team) | `gemini-3-image-api-guide.md`, `paperbanana.md`, `spawn-team-prompt.md` | **Yes** — the strongest candidate for a replacement image backend |
| [`4o-image-generation-suite`](https://github.com/earlyaidopters/gumroad-resources/tree/main/resources/4o-image-generation-suite) | A prompt-craft knowledge base (.md + .pdf) for 4o image gen | **Maybe** — prompt-craft material, if an image skill returns |
| [`sora-zero-to-hero-prompting-guide`](https://github.com/earlyaidopters/gumroad-resources/tree/main/resources/sora-zero-to-hero-prompting-guide) | Links only — a Custom GPT and a Notion guide, no files | Marginal — nothing to vendor |
| [`openai-image-api-n8n-agents`](https://github.com/earlyaidopters/gumroad-resources/tree/main/resources/openai-image-api-n8n-agents) | 4 n8n workflow JSONs (orchestrator, create, edit, sheets) | No — n8n, wrong runtime |
| `master-canvas-guide-for-n8n-vibe-automation` | n8n canvas guide | No |
| `advanced-voice-chatgpt-use-cases`, `vapiception-voice-agent-builder-kit…`, `voice-agent-space-breakdown…` | Voice agents, Make.com | No — audio, not our lane |
| `claudeclaw-mega-prompt-visual-guide` | Matched on "visual"; it's a general ClaudeClaw prompt | No |

### The other angle: skill-authoring craft

30 `SKILL.md` files live in the vault, and several are directly instructive for how we
write our own:

- **`claude-code-skills-guide/unpacked/skill_examples/`** — two deliberately *bad*
  skills and two *good* ones side by side (`csv-data-pipeline`, `project-sprint-planner`
  vs. `data_processor`, `My Project Helper`). Best single reference in the vault for
  auditing our three `SKILL.md` files.
- **`polyskill-kit`** — one source skill compiled to both `install/claude_code/` and
  `install/codex/` layouts. If we ever want `media-toolkit` to install outside Claude
  Code, that's the pattern.
- **`skill-chaining-kit-for-claude-code`** — 10 skills across two chains
  (`brain-chain`, `launch-chain`) designed to hand off to each other. Relevant if we
  ever want a generate → `image-to-motion` → publish chain to be explicit rather than left
  to the model's judgement.
- **`the-claude-folder-a-complete-guide`** — a worked `.claude/skills/` project layout.

---

## 4. Caveats before copying anything

- **No LICENSE file.** The repo has none, and the products are "free" on Gumroad in the
  sense of $0, not in the sense of openly licensed. Default copyright applies: all
  rights reserved. Referencing techniques and linking is fine; **vendoring their files
  into `media-toolkit` is not**, absent permission from the author.
- Our own `media-toolkit` is `UNLICENSED — personal use only`, so any mixing would need
  sorting out on both sides.
- The API guides (`openai-video-api-guide.md`, `gemini-3-image-api-guide.md`) are
  third-party summaries of vendor docs. For anything we implement, read them for
  orientation and verify against the vendor's own docs — they carry no freshness
  guarantee and the underlying APIs move fast.
- Read access only from this environment: the repo clones fine anonymously, but we
  cannot push to it or use GitHub API tools against it.

---

## 5. Recommendation

Two things are worth doing, in this order:

1. ~~**Adopt the generated-README pattern** for `media-toolkit`.~~ **Done** — see
   `tools/build_readme.py` and `tools/README.md`. `skills/` is now the source of truth;
   the README tables and the `skills` array in `.claude-plugin/plugin.json` are
   generated, and `.github/workflows/readme.yml` fails the build on drift. It caught a
   live one on the first run: the README told users to delete "the four folders" from a
   three-skill toolkit.
2. **Audit our three `SKILL.md` files** against the bad-vs-good examples in
   `claude-code-skills-guide`. Read-and-learn, nothing copied.

Anything involving their actual content — the Sora/Gemini API guides, the 4o prompt
knowledge base — should wait on a licensing answer from the author.
