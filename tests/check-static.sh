#!/usr/bin/env bash
# Checks that cost no build time: Guix formatting and derivation validity.
# `--dry-run` evaluates the package, resolves every input and prints the
# derivation path, so it catches typos, unbound variables, bad hashes and
# missing inputs -- without compiling or downloading anything.
#
# Package names come from the `define-public' forms themselves, so that adding
# a package needs no bookkeeping here.
set -euo pipefail
cd "$(dirname "$0")/.."
shopt -s nullglob

files=(sane-packages/*.scm)
if [ ${#files[@]} -eq 0 ]; then
  echo "no modules found under sane-packages/" >&2
  exit 1
fi

# Generated files (crate and npm dependency trees) carry no packages and are
# machine-written: skip them for style, which would fight the generator.
style_files=()
for f in "${files[@]}"; do
  head -2 "$f" | grep -qiE 'generated|do not edit' || style_files+=("$f")
done

# Channel shape, checked before anything else because these are the failures
# users hit rather than ones we hit.
#
# `guix pull' compiles a channel with (find-files source "\\.scm$") -- see
# `standard-module-derivation' in guix/channels.scm.  Any Scheme file that is
# not a module, anywhere under the repo root (.guix-channel declares no
# (directory ...), so the root *is* the module path), makes every user's pull
# fail.  tests/, scripts/ and copy-pasteable examples are where such files
# tend to appear.
#
# The exceptions are hand-maintained on purpose, not derived: a bare channel
# list cannot be made a module (`guix pull -C' loads it with load* and
# #isolated? #t, where define-module is unbound), and forcing one in would
# mean the file stops being loadable as a channels file -- see the header of
# tests/channels-lock.scm.  It is out of the load path only because .guix-
# channel declares no (directory ...); anything else there is still compiled.
# Any new exemption must come with the reason it cannot be a module.
echo "==> channel: every .scm file is a module"
non_module_ok='^\./tests/channels-lock\.scm$'
while IFS= read -r f; do
  if grep -Eq "$non_module_ok" <<<"$f"; then
    continue
  fi
  grep -q '(define-module' "$f" && continue
  cat >&2 <<EOF
$f is a Scheme file but not a Guile module.
'guix pull' would fail on it.  Either give it a define-module form (like nonguix
and brix do for their root-level files) or keep it out of the repository.
EOF
  exit 1
done < <(find . -path ./.git -prune -o -name '*.scm' -print)

# The metadata file itself is not a module, and `guix style' silently ignores
# files it does not consider Scheme, so compare against a renamed copy: a
# parenthesis slip here is a parse error for every user too.  Only the exit
# status is used -- formatting is not a correctness property.
echo "==> channel: .guix-channel parses"
meta_dir=$(mktemp -d)
cp .guix-channel "$meta_dir/channel.scm"
if ! meta_out=$(guix style -f -n "$meta_dir/channel.scm" 2>&1); then
  echo "$meta_out" >&2
  echo ".guix-channel does not parse; 'guix pull' would fail for every user." >&2
  rm -rf "$meta_dir"
  exit 1
fi
rm -rf "$meta_dir"

# zcode's dependency tables are generated, so nothing in guix style or in a
# dry-run can look at them: both only see Scheme that parses.  The one thing
# that can be wrong in them is a relative link that resolves nowhere, and that
# only shows up as a hard build failure in CI, one dangling link at a time.
echo "==> generated tables: zcode dependency links resolve"
./tests/check-zcode-links.py

names=$(grep -hoE '^\(define-public [^ )]+' "${files[@]}" | awk '{print $2}')

for f in "${style_files[@]}"; do
  echo "==> style: $f"
  # NOT `guix style -f -n', even though -n is documented as "display files
  # that would be edited but do nothing": with -f it rewrites the file and
  # prints nothing, so the gate could never fire and CI's style step was a
  # no-op (it also silently reformats whatever it is pointed at, which on a
  # laptop is how a dry run ends up in the working tree).  Format for real
  # into place and ask Git whether the file moved; restore it either way, so
  # a *check* leaves nothing behind.
  before=$(mktemp)
  cp "$f" "$before"
  guix style -f "$f" >/dev/null 2>&1 || true
  if ! cmp -s "$before" "$f"; then
    cp "$before" "$f"
    rm -f "$before"
    echo "$f is not guix-style; run 'guix style -f $f' and commit." >&2
    exit 1
  fi
  rm -f "$before"
done

# One Guix process for the whole channel.  Starting one costs about a minute --
# it loads every (gnu packages *) module these files import -- so looping here
# would make the CI job mostly measure Guix's start-up time.  When the batch
# fails, re-run per package so the log says which one.
#
# `-L .' and not `-L sane-packages': the modules are named `(sane-packages
# cline)' etc., so Guile has to find them at ./sane-packages/cline.scm, which
# needs the repository root on the load path.  The cost is one harmless line
# per invocation: with the root on the path, Guile also maps any `(...)'
# module name onto tests/*.scm, so the bare `(list (channel ...))' in
# tests/channels-lock.scm gets read as the module `(list ...)' and Guix prints
# "error: channel: unbound variable" before doing any work.  It is only noise
# -- the exit status is unaffected, and the dry run still resolves every
# derivation (verified by removing the file: the line disappears, the result
# does not).  The alternative, `-L sane-packages', breaks resolution outright
# with "cline-baseline: unknown package".
echo "==> derivations: $(printf '%s ' $names)"
if ! guix build -L . --dry-run $names; then
  for name in $names; do
    echo "==> derivation: $name"
    guix build -L . --dry-run "$name"
  done
  exit 1
fi
