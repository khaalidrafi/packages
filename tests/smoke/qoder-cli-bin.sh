#!/usr/bin/env bash
# Smoke test for qoder-cli-bin: the package is a single patchelf'd ELF, so
# the real proof is running it.  --version must answer exactly the pinned
# version and exit 0 -- a FATAL-style check in the devin-bin sense: a
# wrong binary or a broken interpreter patch dies here instead of
# answering the wrong version silently.  Nothing else is probed: auth and
# any command that writes a config or a token file stay out of CI (the
# credential storage investigation is recorded on the board).
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

bin="$out/bin/qodercli"
[ -f "$bin" ] || { echo "missing $bin" >&2; exit 1; }
[ -x "$bin" ] || { echo "$bin is not executable" >&2; exit 1; }

# The store symlink `qoder' must exist: it is the command name users reach
# the CLI through, distinct from the desktop app's `qoder-desktop'.
[ -e "$out/bin/qoder" ] || { echo "missing $out/bin/qoder symlink" >&2; exit 1; }

version="$("$bin" --version 2>&1 | tail -1)"
[ "$version" = "1.1.83" ] ||
  { echo "qodercli --version answered '$version', expected 1.1.83" >&2; exit 1; }

echo "qoder-cli-bin smoke test passed ($version)"
