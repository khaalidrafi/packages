#!/usr/bin/env bash
# Smoke test for devin-bin: the payload is a Bun-compiled STATIC-PIE ELF
# (no interpreter, no loader wrapper -- unlike cline-bin, which is
# dynamically linked and has to be exec'd through the store loader), so
# this checks statically that bin/devin is a script execing the store
# payload and that the payload survived the copy as an ELF, then
# dynamically that the real binary runs far enough to print exactly the
# pinned version.  The pin is read from the module itself, so a
# tarball/module version disagreement fails here too; the build's FATAL
# check-version phase is the same comparison at build time, and this one
# guards the installed output.  Nothing here authenticates or touches
# `devin auth' -- credentials are out of this channel's scope.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

wrapper="$out/bin/devin"
binary="$out/lib/devin/bin/devin"

[ -x "$wrapper" ] || { echo "missing executable $wrapper" >&2; exit 1; }
[ -f "$binary" ]  || { echo "missing $binary" >&2; exit 1; }

# The wrapper must be a script that execs the payload, not a symlink:
# a symlink cannot carry a future flag (the autoclaw-bin lesson), and
# there is no loader hop to check -- static-pie has no PT_INTERP.
[ -f "$wrapper" ] && [ ! -L "$wrapper" ] ||
  { echo "$wrapper is not a regular file (script expected)" >&2; exit 1; }
grep -q "lib/devin/bin/devin" "$wrapper" ||
  { echo "$wrapper does not exec the store payload" >&2; exit 1; }

# The payload must be an ELF: the copy phase must not have mangled it.
head -c 4 "$binary" | grep -q $'ELF' ||
  { echo "$binary is not an ELF" >&2; exit 1; }

# The docs ride next to the binary and are read relative to it.
[ -d "$out/lib/devin/share/devin/docs" ] ||
  { echo "missing $out/lib/devin/share/devin/docs" >&2; exit 1; }

# The pinned version, from the module itself -- the same string the
# build's FATAL check-version phase compares against.
pin=$(sed -n 's/^  "\([0-9][0-9.]*\)")$/\1/p' sane-packages/devin.scm)
[ -n "$pin" ] || { echo "could not read %devin-version" >&2; exit 1; }

# The real proof: run it.  --version must answer the pinned version as
# its second stdout token and exit 0 -- anything else is the wrong
# binary and must die, which is the point of the package's FATAL check.
# --help is a broader exercise of the CLI startup path (measured
# 2026-10-30: 109 lines on stdout, empty stderr, exit 0).
read -r _ got _ <<<"$("$wrapper" --version)"
[ "$got" = "$pin" ] ||
  { echo "devin --version answered '$got', expected '$pin'" >&2; exit 1; }
"$wrapper" --help >/dev/null

echo "devin-bin smoke test passed"
