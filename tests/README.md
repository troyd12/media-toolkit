# Tests

Offline test suite for the media-toolkit skill scripts. Nothing here touches
the Pollo AI API, the network, ffmpeg rendering, or your real `~/Desktop` — the
external commands are replaced with mocks and each run gets an isolated fake
`$HOME`.

## Running

```bash
npm install -g bats        # one-time
bats tests/                # run everything
bats tests/pollo_image.bats   # a single suite
```

CI runs the same suite plus `shellcheck` on every push and PR
(`.github/workflows/ci.yml`).

## How it works

- **`mock_bin/`** — fake `curl`, `sleep`, and `ffmpeg` placed on the front of
  `PATH`. The scripts run unmodified; the mocks return recorded fixtures and
  record what the scripts asked for (request bodies, download URLs, the ffmpeg
  filtergraph) so tests can assert on real behaviour.
- **`fixtures/`** — recorded Pollo API JSON responses (submit, poll states,
  malformed payloads).
- **`test_helper.bash`** — sets up the isolated `$HOME` and fake key file.

## What's covered

| Suite | Covers |
|---|---|
| `pollo_image.bats` | arg/key guards, submit→poll→download happy path, no-watermark URL preference, failed/timeout/no-URL paths, default + override request body |
| `pollo_video.bats` | same flow for video, plus numeric `length` serialization |
| `image_to_motion.bats` | file/arg guards, all presets build a valid filtergraph, unknown-preset rejection, **header-vs-implementation drift guard**, duration/size math |
| `manifest.bats` | `plugin.json` matches disk, `bash -n`, safe-flags, SKILL.md front-matter |

## Known gaps / next steps

- The duplicated `node -e` JSON parse/build snippets in the two Pollo scripts
  are exercised end-to-end but not unit-tested in isolation; extracting them
  into a shared helper would let them be tested directly and remove the
  duplication.
- No test yet asserts the exact submit **endpoint** path (`text2image` vs
  `text2video`) — the mock accepts either.
- Multi-variation / batch image workflow (mentioned in the SKILL.md) has no
  script path and therefore no tests.
