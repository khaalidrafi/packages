# AGENTS.md — operating manual for agents working in khaalidrafi/packages

REPO-OWNED (Owner order 2026-10-28 05:13Z #hq: created by the Lead from a
repo audit, never pasted in). Every member, acting seat, and the Lead reads
THIS file first. It is the repo's LOCAL law; agent-team/CHARTER.md adds
the team layer on top. Where the two disagree, the stricter rule wins.

## What this repo is

A personal GNU Guix channel (`sane-packages`) holding packages upstream Guix
cannot carry — vendor-binary repackages (`*-bin`), non-free dependencies, AI
tooling — built by CI instead of by hand on the Owner's laptop. CI publishes
every build as a signed substitute mirror (GitHub Pages,
https://khaalidrafi.github.io/packages/), so `guix install` downloads a ready
store item instead of compiling.

## Branch law

- The trunk is `ai/packages` — the default branch, and the branch the channel
  URL in `.guix-channel`/README pulls.
- Work never lands on the trunk directly: task branches `ai/<topic>`;
  packaging requests `ai/pkgs-<name>`; merge after review; the Owner merges.
- Team-file edits (board, roster, STATE.org) go on the trunk.

## The machine (why this law exists)

The Owner's box is a 2014 Celeron, 4 GB RAM, no AVX2:

- NO source builds locally (bun/pnpm installs, compilations) — they freeze it.
- `*-bin` packages (vendor-binary repackages) MAY be built, installed and run
  here.
- Source packages: evaluation only — `guix build -L . --dry-run PKG`.
- Real builds happen on CI (`.github/workflows/build.yml`).
- `rg`/`fd`, not grep/find.
- Every `define-public` gets a passing `--dry-run` before it is pushed — the
  cheapest real test available on this machine.

## Commands (run from the repo root)

- `./tests/check-static.sh` — the channel contract first (every `.scm` under
  the root must be a module — `guix pull` compiles all of them; one stray
  file breaks every user's pull).
- `./tests/lint.sh` — `guix lint`, advisory only.
- `./tests/build-all.sh` — builds everything, source packages first, `*-bin`
  after (`PACKAGES="a b"` narrows the run). Source packages: CI only.
- `guix build -L . PKG` — build from this working tree. On the Owner's box,
  clear `GUIX_PACKAGE_PATH` first or a stale copy resolves instead of your
  edit.

## Package conventions

- One module per upstream project (`sane-packages/zcode.scm`). Generated
  dependency tables live in `*-modules.scm` — DO NOT hand-edit them; change
  the generator under `scripts/` and regenerate.
- `sane-packages/custom.scm` is the legacy catch-all; move a package into its
  own module when you touch it.
- Every `*-bin` installs the command name upstream uses.
- Generated files are committed, never rebuilt at build time — a package must
  not need a network fetch to know its own dependency hashes.
- `news.txt` entries: Texinfo markup, added in a following commit that cites
  the change's hash (a commit cannot name its own hash).
- Known-intended profile collisions (`cline-bin`/`cline-baseline`,
  `zcode`/`zcode-bin`) are doctrine, not defects — do not "fix" them.

## CI

- `build.yml`: static checks → lint (advisory) → build all → publish
  substitutes → mirror deploy → fresh-machine install gate. Push builds are
  DISABLED (Owner order 2026-10-28 #hq: the all-packages build on every push
  is too expensive) — it runs on `workflow_dispatch` or `pull_request` only.
- `upstream.yml`: nightly zcode version-drift reminder (fails when packaged
  version falls behind upstream).
- The substitute signing key's private half is an Actions secret — never
  committed, never echoed.

## Commit law

- Subject ≤ 72 chars, names WHAT changed (≥ 3 words); banned openers:
  `wip`, `update`, `misc`, `done`.
- Body carries the model identity line, `Co-authored-by: z.ai-agent
  <z.ai-agent@z.ai>` and `Co-authored-by: Khalid Rafi
  <khaalidrafi@gmail.com>` trailers, and a short note on which prompts
  shaped the change.
- Agent commits are unsigned (no pinentry on this box). `.guix-authorizations`
  deliberately does not exist yet — adding it would make every later unsigned
  commit unpullable; do not add it without the Owner.

## Secret law

Credentials NEVER travel in chat, files, commits, or messages — only as ENV
VAR NAMES. Provider keys CI needs live as repo Actions secrets, sealed by
the Owner's relay (z.ai-agent) from the vault. Never echo a value; never
write one into a file.

## Team layer (read in this order after this file)

1. `agent-team/CHARTER.md` — charter + operating manual (master prompt).
2. `agent-team/MEMBERS.org` — ranked roster, seats, fallbacks.
3. `agent-team/TODOS.org` — the board, the ONLY inter-member
   channel (dispatches, handoffs, reports).
4. `STATE.org` — cross-session state (Owner pastes back at session start).

A missing file the team can author is NOT a stop: audit the repo and write
it (Owner order 2026-10-28 05:13Z #hq). Query the Owner only for what the
audit cannot answer — one batched question.
