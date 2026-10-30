#!/usr/bin/env bash
# Smoke test for cline-baseline: the package is a Bun-compiled standalone
# binary (the non-AVX2 baseline target) whose ELF interpreter is patched to
# the store glibc loader with patchelf --set-interpreter (only --set-rpath
# corrupts Bun's appended payload), and a small shell wrapper execs the
# binary as the process image with LD_LIBRARY_PATH exported.  Routing the
# binary through `ld-linux --library-path' instead would make the loader the
# executable, and the hub daemon -- which re-executes process.execPath --
# would die on `unrecognized option --cline-hub-daemon' (the cline-bin
# lesson, dcd11c6).  So this checks statically that bin/cline execs the
# binary directly with LD_LIBRARY_PATH set and that lib/cline/cline is the
# ELF binary, and dynamically: the CLI prints its version, and the hub
# starts, answers status, and stops.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

binary="$out/lib/cline/cline"
wrapper="$out/bin/cline"

[ -x "$wrapper" ] || { echo "missing executable $wrapper" >&2; exit 1; }
[ -f "$binary" ]  || { echo "missing $binary" >&2; exit 1; }

# The wrapper must export LD_LIBRARY_PATH and exec the binary itself, not
# hand it to the ld loader (--library-path is the hub killer), and Guix is
# not FHS, so nothing may point at a system-wide path either.
grep -q 'export LD_LIBRARY_PATH=' "$wrapper" ||
  { echo "$wrapper does not export LD_LIBRARY_PATH" >&2; exit 1; }
grep -qF "exec $binary" "$wrapper" ||
  { echo "$wrapper does not exec $binary directly" >&2; exit 1; }
if grep -q -- '--library-path' "$wrapper"; then
  { echo "$wrapper still execs through the ld loader (hub killer)" >&2
    exit 1
  }
fi

# It must be an ELF executable, i.e. the Bun payload survived the copy phase.
head -c 4 "$binary" | grep -q $'ELF' ||
  { echo "$binary is not an ELF" >&2; exit 1; }

# The real proof: run it.  --version must print something and exit 0; an AVX2
# build dies with SIGILL (132) here on pre-Haswell CPUs, and a binary whose
# interpreter was not patched to the store loader cannot even start under
# guix (there is no /lib64).  --help is a second, broader exercise of the
# CLI startup path.  Give --version a moment; Bun may JIT on first run.
"$wrapper" --version
"$wrapper" --help >/dev/null

# Hub round trip: start, status, stop.  `hub start' detaches and upstream
# waits a fixed 15 s for its socket, which a loaded runner can overrun, so
# poll `hub status' instead of trusting the start banner -- and give the
# daemon a writable HOME, the build user's home is not.
export HOME="$(mktemp -d)"
timeout 60 "$wrapper" hub start >/dev/null 2>&1 || true
hub_up=""
for _ in $(seq 1 30); do
  if "$wrapper" hub status 2>/dev/null | grep -qi running; then
    hub_up=yes
    break
  fi
  sleep 1
done
[ -n "$hub_up" ] || { echo "hub did not reach running state" >&2; exit 1; }
"$wrapper" hub stop >/dev/null 2>&1 || true
hub_down=""
for _ in $(seq 1 10); do
  if ! "$wrapper" hub status 2>/dev/null | grep -qi running; then
    hub_down=yes
    break
  fi
  sleep 1
done
[ -n "$hub_down" ] || { echo "hub did not stop" >&2; exit 1; }

echo "cline-baseline smoke test passed"
