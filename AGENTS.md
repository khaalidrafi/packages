# AGENTS.md — operating manual for agents working in khaalidrafi/sensible-packages

REPO-OWNED (Owner order 2026-10-28 05:13Z #hq: created by the Lead from a
repo audit, never pasted in). Every member, acting seat, and the Lead reads
THIS file first. It is the repo's LOCAL law; agent-team/CHARTER.md adds
the team layer on top. Where the two disagree, the stricter rule wins.
(2026-11-24 rewrite: the repo is renamed sensible-packages, and every law
below now names the Guix manual node it comes from.)

## What this repo is

A personal GNU Guix channel (`sensible-packages`) holding packages upstream
Guix cannot carry — vendor-binary repackages (`*-bin`), non-free
dependencies, AI tooling — built by CI instead of by hand on the Owner's
laptop. CI publishes every build as a signed substitute mirror (GitHub
Pages, https://khaalidrafi.github.io/sensible-packages/), so `guix install`
downloads a ready store item instead of compiling.

The repo was renamed `packages` → `sensible-packages` on 2026-11-24 (Owner
order; 3ae1929 + f2dd625 finished it). Git redirects old clone URLs;
GitHub Pages does not — the old mirror URL is a dead 404. See "URL law".

## Branch law

- The trunk is `ai/main` — the default branch, and the branch the README
  channel example and scripts/emit-channels.py tell users to pull.
- Work never lands on the trunk directly: task branches `ai/<topic>`;
  packaging requests `ai/pkgs-<name>`; merge after review; the Owner merges.
- Team-file edits (board, roster, STATE.org) go on the trunk.
- `gh-pages` belongs to CI (force-orphan deploy on every build); never
  touch it by hand.
- The agent-team chain still anchors on `ai/packages` (LEAD-OWNED
  `.github/workflows/agent-team.yml`; brief law #10: seats never edit
  workflow files). Migrating it to the new trunk is the Lead's call, not a
  seat's edit.

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

## The Guix manual is ground truth

Argue from the manual node, not from memory (https://guix.gnu.org/manual/).
The nodes this repo lives inside:

- "Creating a Channel" / "Channels": `guix pull` compiles EVERY `.scm` under
  the repo root (`.guix-channel` declares no `(directory ...)`, so the root
  is the module path). One stray non-module `.scm` breaks every user's
  pull — tests/check-static.sh enforces it, and it is why the news file is
  `news.txt`, never `news.scm`.
- "Writing Channel News": entries are
  `(entry (commit "...") (title (en "...")) (body (en "...")))`; title one
  line, body Texinfo markup (never Markdown), `(LANG "...")` tuples so pull
  can match the user's locale. A user sees an entry once, the first time
  they pull past the commit it names — and since a commit cannot name its
  own hash, the entry lands in a FOLLOWING commit that cites the change's
  hash.
- "Deprecation Policy": a renamed or retired package keeps its old name a
  resolvable alias for at least one year, and popular packages get a news
  entry when deprecated. The mechanism is `deprecated-package`, which sets
  the `superseded` property: `guix install old-name` warns and installs the
  replacement (upstream precedent: go-ipfs → kubo). The manual's
  `define-deprecated-package` macro is the same thing; this repo spells it
  `(define-public old (deprecated-package "old" new))` so
  tests/check-static.sh keeps harvesting — and dry-run checking — the old
  name, and Guix installs that predate the macro still load the module.
  House precedent: `opencode-bin` → `opencode2-bin`, `cline-baseline` →
  `cline-bin` (both 2026-11-24).
- "Channel Authentication": once `.guix-authorizations` exists, `guix pull`
  authenticates every commit against it, anchored on a signed channel
  introduction. This repo's history is unsigned agent commits — adding
  authorizations mid-history would strand every commit before it. Never
  add without the Owner.
- "package Reference": inputs are new-style lists (`(list foo ...)`) — the
  old `(("foo" ,foo))` tuple style is deprecated upstream and banned here.
  `native-inputs` is build-machine-only (cross-compilation is the reason).
  `properties` is an alist; `superseded` is the deprecation key.

## Package conventions

- One module per upstream project (`sensible-packages/zcode.scm`). Generated
  dependency tables live in `*-modules.scm` — DO NOT hand-edit them; change
  the generator under `scripts/` and regenerate.
- `sensible-packages/custom.scm` is the legacy catch-all; move a package
  into its own module when you touch it.
- Every `*-bin` installs the command name upstream uses.
- Generated files are committed, never rebuilt at build time — a package
  must not need a network fetch to know its own dependency hashes.
- Known-intended profile collisions (`zcode`/`zcode-bin`) are doctrine, not
  defects — do not "fix" them.  (`cline-bin`/`cline-baseline` used to be such
  a pair; `cline-baseline` is now a deprecated alias, so it no longer installs
  anything of its own.)
- Deprecating a package follows the manual's Deprecation Policy: alias it
  with `deprecated-package`, add a news entry, keep the alias at least a
  year before removing the name.

## URL law (the rename lesson)

User-facing URLs live in exactly five places and must all say
`sensible-packages`: README.org (channel example + substitute-mirror
instructions), `.guix-channel`'s `(url ...)`, `scripts/emit-channels.py`,
`tests/check-substitutes.sh`'s `MIRROR` default, and this file. Git
redirects cover old clone URLs; the Pages mirror does not. After any
rename: grep all five, land the fix, and put a news entry up for users
whose saved `--substitute-urls` broke.

## CI

- `build.yml`: static checks → lint (advisory) → build all → publish
  substitutes → mirror deploy → fresh-machine install gate. Push builds are
  DISABLED (Owner order 2026-10-28 #hq: the all-packages build on every push
  is too expensive) — it runs on `workflow_dispatch` or `pull_request` only.
  Guix and nonguix are pinned by tests/channels-lock.scm
  (`guix pull --fallback --allow-downgrades -C`); ./tests/update-channels-lock.sh
  re-pins (introduction strings are trust anchors and never move).
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
