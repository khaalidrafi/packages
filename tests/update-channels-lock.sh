#!/usr/bin/env bash
# Rewrite the (commit ...) fields in channels-lock.scm from the current
# upstream tips, then show the diff so a Guix bump's blast radius is reviewable.
#
# Introduction strings are deliberately NOT touched: they are trust anchors,
# not version numbers, so bumping a pin must never change who signs a channel.
#
#   ./tests/update-channels-lock.sh
#   ./tests/update-channels-lock.sh --commit-1 4341c003d7655ac02d72aea58cda706d87d0f965
#
# --commit-1 re-pins the guix channel to one specific commit instead of the
# tip.  That is how you unstick a red build caused by an upstream Guix
# regression: step back to the last good commit, land that, and bisect
# separately.
#
# The rewriting is done by tests/retarget-channels-lock.py, which explains why
# it is not a sed one-liner.  The short version: this file's comments mention
# `(commit ...)` in prose, so a line-based match has to tell a form from a
# comment, and getting that wrong edits the wrong line silently.
set -euo pipefail
cd "$(dirname "$0")/.."
lock=tests/channels-lock.scm

case "${1:-}" in
  "" )        guix_commit=$(git ls-remote https://git.guix.gnu.org/guix.git HEAD | cut -f1) ;;
  --commit-1) guix_commit="${2:?--commit-1 needs a commit sha}" ;;
  * ) echo "usage: $0 [--commit-1 <sha>]" >&2; exit 1 ;;
esac

# Read the branch tip explicitly rather than HEAD: on some mirrors HEAD is
# absent or stale, and HEAD is not always what CI resolves.
nonguix_commit=$(git ls-remote https://gitlab.com/nonguix/nonguix refs/heads/master 2>/dev/null | cut -f1)
[ -n "$guix_commit" ]     || { echo "could not read guix HEAD" >&2; exit 1; }
[ -n "$nonguix_commit" ] || { echo "could not read nonguix master" >&2; exit 1; }

before=$(mktemp); cp "$lock" "$before"

if ! output=$(python3 tests/retarget-channels-lock.py "$lock" "$guix_commit" "$nonguix_commit"); then
  echo "rewrite failed; $lock left untouched" >&2
  exit 1
fi

if cmp -s "$before" "$lock"; then
  echo "no change (guix $guix_commit, nonguix $nonguix_commit already pinned)"
  rm -f "$before"
  exit 0
fi

# A rewrite that does not parse would break `guix pull' for every user, so
# check before showing a tidy diff.
if ! guix style -f "$lock" >/dev/null 2>&1; then
  echo "the rewritten file does not parse; restoring" >&2
  cp "$before" "$lock"
  exit 1
fi

echo "==> rewritten"
printf '%s\n' "$output"
echo
echo "==> diff"
# `git diff --no-index' rather than `git diff --': the lock is not tracked yet
# on a first run, and plain `git diff' prints nothing at all for an untracked
# file, so a real rewrite would look like a no-op.  Exit status 1 here just
# means "they differ", which is the point, hence the || true.
git diff --no-index -- "$before" "$lock" | tail -n +5 || true
echo
echo "guix:    $guix_commit"
echo "nonguix: $nonguix_commit"
echo
echo "Verify the pins resolve before committing:"
echo "  guix pull -n --allow-downgrades -C $lock"
