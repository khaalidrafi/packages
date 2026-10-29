#!/usr/bin/env bash
# Smoke test for cline-baseline: the package is a Bun-compiled standalone
# binary (the non-AVX2 baseline target) exec'd through the store glibc loader
# by a small shell wrapper, because patchelf corrupts Bun's embedded payload.
# So this checks two things statically -- that bin/cline is a loader wrapper and
# that lib/cline/cline is the ELF binary -- and one thing dynamically: the real
# binary runs far enough to print its version (which is exactly what SIGILLs on
# an AVX2 build, so a clean --version here is the point of the package).
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

binary="$out/lib/cline/cline"
wrapper="$out/bin/cline"

[ -x "$wrapper" ] || { echo "missing executable $wrapper" >&2; exit 1; }
[ -f "$binary" ]  || { echo "missing $binary" >&2; exit 1; }

# The wrapper must exec the binary through the store ld loader with a
# --library-path, not run it directly (Guix is not FHS, so a bare ELF would
# fail to find its interpreter).
grep -q 'ld-linux-x86-64.so.2' "$wrapper" ||
  { echo "$wrapper does not go through the glibc loader" >&2; exit 1; }
grep -q -- '--library-path' "$wrapper" ||
  { echo "$wrapper has no --library-path" >&2; exit 1; }

# It must be an ELF executable, i.e. the Bun payload survived the copy phase.
head -c 4 "$binary" | grep -q $'ELF' ||
  { echo "$binary is not an ELF" >&2; exit 1; }

# The real proof: run it.  --version must print something and exit 0; an AVX2
# build dies with SIGILL (132) here on pre-Haswell CPUs.  --help is a second,
# broader exercise of the CLI startup path.  Give --version a moment; Bun may
# JIT on first run.
"$wrapper" --version
"$wrapper" --help >/dev/null

echo "cline-baseline smoke test passed"
