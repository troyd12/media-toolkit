# Repo tooling

## `build_readme.py`

The README's tables and `.claude-plugin/plugin.json` are generated from the
`skills/` tree, so adding or renaming a skill cannot leave them stale.

```sh
python3 tools/build_readme.py           # rewrite in place
python3 tools/build_readme.py --check   # exit 1 with a diff if the committed files are stale
```

Stdlib only — no install step, in CI or locally.

### What each skill contributes

```
skills/<name>/
├── SKILL.md    frontmatter `name` must equal <name>
├── meta.json   the display metadata below
└── <entry>     the script the shell alias points at (default: generate.sh)
```

`meta.json`:

| Key | Required | Meaning |
|---|---|---|
| `summary` | ✅ | the README table's **Purpose** cell |
| `backend` | ✅ | the README table's **Backend** cell |
| `entrypoint` | | script the alias runs; defaults to `generate.sh` |
| `alias` | | shell alias name; omit for no alias |
| `order` | | position in the tables; unordered skills sort last, then alphabetically |
| `key` | | `{"service": …, "path": …}`, or `null` for none. Skills sharing a key produce one row |
| `requires` | | for keyless skills: completes the sentence "requires no key — …" |

### What it writes

Four marker-delimited regions in `README.md` — `skills-table`, `uninstall`,
`keys-table`, `aliases` — plus the `skills` array in
`.claude-plugin/plugin.json` (every other key in that file is left alone).
Prose outside the markers is never touched:

```markdown
<!-- BEGIN GENERATED: skills-table -->
...owned by the script, hand edits are overwritten...
<!-- END GENERATED: skills-table -->
```

Removing or duplicating a marker pair is an error, not a silent skip.

### Exit codes

| Code | Meaning |
|---|---|
| 0 | up to date (or written successfully) |
| 1 | `--check` only: committed files are stale. Run without `--check` and commit |
| 2 | a drift or authoring problem — the message names the file and the fix |

Exit 2 covers: a `skills/` directory with no `SKILL.md`, a frontmatter `name`
disagreeing with its directory, a missing or malformed `meta.json`, an
`entrypoint` that does not exist, and two skills claiming one alias.

### CI

`.github/workflows/readme.yml` runs `--check` on every push and PR that touches
`skills/`, `README.md`, the plugin manifest, or the generator. A stale README
fails the build with the exact diff needed to fix it.

### Adding a skill

1. Create `skills/<name>/` with `SKILL.md` and its entrypoint.
2. Write `skills/<name>/meta.json`.
3. Run `python3 tools/build_readme.py` and commit the regenerated files.

Steps 1–2 are the only hand-authoring; the tables and the manifest follow.
