# HUMANS.md — packages (sane-packages Guix channel)

A guide for humans navigating and developing this codebase. Written
2026-11-18 per the org-wide rule that every agent-developed repo
carries one.

## What this is

A personal GNU Guix channel holding packages upstream Guix cannot or
will not carry — vendor-binary repackages (`*-bin`), non-free
dependencies, AI tooling — built by GitHub Actions CI instead of by
hand on the Owner's 2014 Celeron / 4 GB RAM laptop. CI publishes every
build as a signed substitute mirror on GitHub Pages
(https://khaalidrafi.github.io/packages/), so `guix install` downloads
a ready store item instead of compiling anything.

## Mental model

The repo root IS a Guile module load path — that is the load-bearing
fact of the whole design. `guix pull` compiles every `.scm` file it
finds via `find-files`, so one stray non-module `.scm` anywhere in the
tree breaks the channel for every user. `tests/check-static.sh`
enforces this; do not rely on noticing it later.

Packaging convention: one module per upstream project under
`sane-packages/` (`zcode.scm`), with a generated `-modules.scm`
companion (`zcode-modules.scm`) when the dependency closure is
machine-generated — tables of names/versions/hashes marked
"do not edit", written by generators under `scripts/`.
`sane-packages/custom.scm` is the original catch-all; a package moves
out of it into its own module when you touch it. CI derives its build
list from the `define-public` forms themselves — adding a package is
adding a definition, no list to keep in sync.

The `nonguix` channel dependency is declared in `.guix-channel`, so
users add only this channel; `(nonguix licenses)` resolves for
zcode.scm without a second entry.

## Code map

| Path | Role |
|---|---|
| `.guix-channel` | Channel metadata; news file; nonguix dependency. THE file that makes the repo root a module path. |
| `sane-packages/*.scm` | The packages. One module per upstream project; `custom.scm` is the catch-all. |
| `sane-packages/*-modules.scm` | Generated dependency-closure tables (do not edit by hand). |
| `scripts/gen-zcode-node-tree.py`, `gen-konaito-node-tree.py` | The generators that write the `-modules.scm` files. |
| `scripts/latest-version.sh`, `bump-digests.sh` | Version/hash refresh helpers. |
| `scripts/emit-channels.py` | Emits the user-facing channels snippet. |
| `tests/check-static.sh` | The guard: every `.scm` in the tree must be a valid module (the `guix pull` invariant). |
| `tests/build-all.sh`, `lint.sh`, `check-chain.sh`, `check-substitutes.sh`, `publish-substitutes.sh` | CI lanes: build, lint, chain integrity, substitute mirror, publish. |
| `tests/channels-lock.scm` + `update-channels-lock.sh` / `retarget-channels-lock.py` | Pinned channels for reproducible CI. |
| `ci/` | The agent-team-ci kit submodule (laws, harness, guards). |
| `agent-team/` | Team state: board, roster, CHAT protocol. |
| `news.txt` | Channel news shown on `guix pull`. |

## Invariants and gotchas

- **The machine law** (why this repo exists): NO source builds locally,
  ever — `guix build -L . --dry-run PKG` only (evaluation catches
  typos, bad hashes, unresolvable inputs). CI does the real builds.
  `guix install` is only ever allowed for `*-bin` packages, and after
  installing one you RUN the binary to prove the wrapping works (Guix
  is not FHS; "file not found" is the failure mode).
- Every `.scm` in the tree must be a loadable module (see Mental
  model). Test files live in `tests/` as `.sh`/`.py` precisely for
  this reason.
- `*-bin` naming is semantic: CI builds source-based packages first,
  `*-bin` after, and publishes both as substitutes.
- The trunk is `ai/packages` (the default branch, and the branch the
  channel URL pulls). Packaging work goes through `ai/<topic>` /
  `ai/pkgs-<name>` branches; the Owner merges. Team-file edits (board,
  roster, STATE.org) go on the trunk directly.
- The CI chain state rides GitHub Actions variables (chain
  bookkeeping), not files in the repo — do not "fix" that by moving it
  back into files.

## Developing

```sh
guix build -L . --dry-run <pkg>     # the ONLY allowed local build command
bash tests/check-static.sh          # module invariant
bash tests/lint.sh                  # guix lint over the channel
```

Real build/lint/publish happens in CI (`.github/workflows/`, wired
through the `ci/` submodule). A new package: add the `define-public`
form in the right module (create it if missing), run the static check,
push, let CI build.
