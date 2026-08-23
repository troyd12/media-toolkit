#!/usr/bin/env python3
"""Regenerate the README's generated regions and the plugin manifest from skills/.

The skills tree is the source of truth. Each skill contributes:

  skills/<name>/SKILL.md    frontmatter `name` (must match the directory)
  skills/<name>/meta.json   the display metadata the README renders
  skills/<name>/<entry>     the entrypoint the shell alias points at

Everything between a `<!-- BEGIN GENERATED: x -->` / `<!-- END GENERATED: x -->`
pair in README.md is owned by this script; prose outside those markers is never
touched. `.claude-plugin/plugin.json` keeps all of its authored keys — only the
`skills` array is rewritten.

    python3 tools/build_readme.py           # rewrite in place
    python3 tools/build_readme.py --check   # exit 1 (with a diff) if anything would change

Stdlib only, so CI needs no install step.
"""

import argparse
import difflib
import json
import os
import re
import sys
from dataclasses import dataclass, field

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS_DIR = os.path.join(ROOT, "skills")
README = os.path.join(ROOT, "README.md")
PLUGIN = os.path.join(ROOT, ".claude-plugin", "plugin.json")

REQUIRED_META = ("summary", "backend")
BLOCK_RE = "<!-- BEGIN GENERATED: {name} -->\n.*?<!-- END GENERATED: {name} -->"


class BuildError(Exception):
    """A drift or authoring problem the maintainer has to fix."""


@dataclass
class Skill:
    name: str
    summary: str
    backend: str
    entrypoint: str
    order: int
    alias: str = ""
    key: dict = field(default_factory=dict)
    requires: str = ""


# --------------------------------------------------------------------------
# loading
# --------------------------------------------------------------------------

def parse_frontmatter(path):
    """Pull the top-level scalar keys out of a SKILL.md YAML frontmatter block.

    Deliberately not a YAML parser: skill frontmatter is flat `key: value`
    pairs, and depending on PyYAML would mean a CI install step for three keys.
    """
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    if not text.startswith("---\n"):
        raise BuildError("{}: does not open with a `---` frontmatter block".format(rel(path)))
    end = text.find("\n---", 3)
    if end == -1:
        raise BuildError("{}: frontmatter block is never closed".format(rel(path)))

    fields = {}
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[:1].isspace() or ":" not in line:
            continue  # nested/continuation lines: nothing here needs them
        key, _, value = line.partition(":")
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        fields[key.strip()] = value
    return fields


def load_skills():
    if not os.path.isdir(SKILLS_DIR):
        raise BuildError("no skills/ directory at {}".format(SKILLS_DIR))

    skills = []
    for name in sorted(os.listdir(SKILLS_DIR)):
        skill_dir = os.path.join(SKILLS_DIR, name)
        if not os.path.isdir(skill_dir) or name.startswith("."):
            continue

        skill_md = os.path.join(skill_dir, "SKILL.md")
        if not os.path.isfile(skill_md):
            raise BuildError(
                "skills/{}/ has no SKILL.md — every directory under skills/ must be "
                "a real skill, or be moved out".format(name)
            )
        declared = parse_frontmatter(skill_md).get("name", "")
        if declared != name:
            raise BuildError(
                "skills/{}/SKILL.md declares name: {!r}, which does not match its "
                "directory".format(name, declared)
            )

        meta_path = os.path.join(skill_dir, "meta.json")
        if not os.path.isfile(meta_path):
            raise BuildError(
                "skills/{}/meta.json is missing. It supplies the README display "
                "metadata; required keys: {}".format(name, ", ".join(REQUIRED_META))
            )
        try:
            with open(meta_path, encoding="utf-8") as fh:
                meta = json.load(fh)
        except json.JSONDecodeError as exc:
            raise BuildError("skills/{}/meta.json is not valid JSON: {}".format(name, exc))

        missing = [k for k in REQUIRED_META if not meta.get(k)]
        if missing:
            raise BuildError(
                "skills/{}/meta.json is missing required key(s): {}".format(
                    name, ", ".join(missing)
                )
            )

        entrypoint = meta.get("entrypoint", "generate.sh")
        if not os.path.isfile(os.path.join(skill_dir, entrypoint)):
            raise BuildError(
                "skills/{}/meta.json points at entrypoint {!r}, which does not "
                "exist".format(name, entrypoint)
            )

        key = meta.get("key") or {}
        if key and not (key.get("service") and key.get("path")):
            raise BuildError(
                "skills/{}/meta.json has a `key` without both `service` and "
                "`path`".format(name)
            )

        skills.append(Skill(
            name=name,
            summary=meta["summary"],
            backend=meta["backend"],
            entrypoint=entrypoint,
            order=meta.get("order", 999),
            alias=meta.get("alias", ""),
            key=key,
            requires=meta.get("requires", ""),
        ))

    if not skills:
        raise BuildError("skills/ contains no skills")

    aliases = {}
    for skill in skills:
        if not skill.alias:
            continue
        if skill.alias in aliases:
            raise BuildError(
                "alias {!r} is claimed by both {} and {}".format(
                    skill.alias, aliases[skill.alias], skill.name
                )
            )
        aliases[skill.alias] = skill.name

    skills.sort(key=lambda s: (s.order, s.name))
    return skills


# --------------------------------------------------------------------------
# rendering
# --------------------------------------------------------------------------

def render_skills_table(skills):
    lines = ["| Skill | Purpose | Backend |", "|---|---|---|"]
    lines += [
        "| `{}` | {} | {} |".format(s.name, s.summary, s.backend) for s in skills
    ]
    return "\n".join(lines)


def render_prerequisites(skills):
    """The whole prerequisites section body.

    The "save your keys here" lead-in is generated rather than authored so it
    cannot outlive the last keyed skill — when every backend is local, a README
    telling people where to put API keys is worse than no README.
    """
    keyed = []
    for skill in skills:
        if skill.key and skill.key not in keyed:
            keyed.append(skill.key)

    lines = []
    if keyed:
        lines.append("Save raw API keys (no quotes, no banners) into these files:")
        lines.append("")
        lines.append("| Service | Path |")
        lines.append("|---|---|")
        lines += ["| {} | `{}` |".format(k["service"], k["path"]) for k in keyed]

    notes = [
        "`{}` needs no API key — {}.".format(s.name, s.requires)
        for s in skills if not s.key and s.requires
    ]
    if notes:
        if lines:
            lines.append("")
        lines += notes
    elif not lines:
        lines.append("No skill in this toolkit needs an API key.")
    return "\n".join(lines)


def render_aliases(skills):
    aliased = [s for s in skills if s.alias]
    if not aliased:
        return "_No skill defines a shell alias._"
    lines = ["```bash"]
    lines += [
        "alias {}='bash ~/.claude/skills/{}/{}'".format(s.alias, s.name, s.entrypoint)
        for s in aliased
    ]
    lines.append("```")
    return "\n".join(lines)


def render_uninstall(skills):
    folders = ["`{}/`".format(s.name) for s in skills]
    if len(folders) == 1:
        listed = folders[0]
    elif len(folders) == 2:
        listed = "{} and {}".format(*folders)
    else:
        listed = "{}, and {}".format(", ".join(folders[:-1]), folders[-1])
    return (
        "After install, the skills auto-load in every Claude Code session. "
        "To uninstall, delete {} from `~/.claude/skills/`.".format(listed)
    )


def replace_block(text, name, body):
    pattern = re.compile(BLOCK_RE.format(name=re.escape(name)), re.DOTALL)
    found = len(pattern.findall(text))
    if found == 0:
        raise BuildError(
            "README.md has no `<!-- BEGIN GENERATED: {0} -->` / "
            "`<!-- END GENERATED: {0} -->` pair".format(name)
        )
    if found > 1:
        raise BuildError("README.md has {} `{}` generated blocks; expected 1".format(found, name))
    replacement = "<!-- BEGIN GENERATED: {0} -->\n{1}\n<!-- END GENERATED: {0} -->".format(
        name, body
    )
    return pattern.sub(lambda _: replacement, text, count=1)


def build_readme(skills):
    with open(README, encoding="utf-8") as fh:
        text = fh.read()
    for name, body in (
        ("skills-table", render_skills_table(skills)),
        ("uninstall", render_uninstall(skills)),
        ("prerequisites", render_prerequisites(skills)),
        ("aliases", render_aliases(skills)),
    ):
        text = replace_block(text, name, body)
    return text


def build_plugin(skills):
    with open(PLUGIN, encoding="utf-8") as fh:
        manifest = json.load(fh)
    manifest["skills"] = ["skills/{}".format(s.name) for s in skills]
    return json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"


# --------------------------------------------------------------------------
# driver
# --------------------------------------------------------------------------

def rel(path):
    return os.path.relpath(path, ROOT)


def write_or_check(path, new_text, check):
    with open(path, encoding="utf-8") as fh:
        old_text = fh.read()
    if old_text == new_text:
        return False
    if check:
        diff = difflib.unified_diff(
            old_text.splitlines(keepends=True),
            new_text.splitlines(keepends=True),
            fromfile="{} (committed)".format(rel(path)),
            tofile="{} (generated)".format(rel(path)),
        )
        sys.stderr.write("".join(diff))
        return True
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(new_text)
    return True


def plural(n):
    return "1 skill" if n == 1 else "{} skills".format(n)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--check",
        action="store_true",
        help="do not write; exit 1 and print a diff if the committed files are stale",
    )
    args = parser.parse_args()

    try:
        skills = load_skills()
        outputs = [(README, build_readme(skills)), (PLUGIN, build_plugin(skills))]
    except BuildError as exc:
        sys.stderr.write("error: {}\n".format(exc))
        return 2

    stale = [path for path, text in outputs if write_or_check(path, text, args.check)]

    if args.check:
        if stale:
            sys.stderr.write(
                "\n{} out of date. Run `python3 tools/build_readme.py` and commit "
                "the result.\n".format(", ".join(rel(p) for p in stale))
            )
            return 1
        print("{} — README.md and plugin.json are up to date.".format(plural(len(skills))))
        return 0

    if stale:
        print("regenerated {} from {}".format(", ".join(rel(p) for p in stale), plural(len(skills))))
    else:
        print("{} — nothing to change.".format(plural(len(skills))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
