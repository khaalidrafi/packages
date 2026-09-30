#!/usr/bin/env bash
# Smoke test for zcode-bin: assert the vendor .deb's Electron layout survived
# the copy phase, that the launcher and the .desktop entry point at the store
# rather than at /opt, and that the main binary got a store interpreter and a
# RUNPATH.  Nothing here needs a display; starting the GUI stays a manual check
# (see README.org).
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

for path in \
    bin/zcode \
    lib/ZCode/zcode \
    lib/ZCode/libffmpeg.so \
    lib/ZCode/libEGL.so \
    lib/ZCode/icudtl.dat \
    lib/ZCode/resources/app.asar \
    share/applications/zcode.desktop \
    share/icons/hicolor/256x256/apps/zcode.png; do
  [ -e "$out/$path" ] || { echo "missing $out/$path" >&2; exit 1; }
done

# bin/zcode must reach the wrapper, and the wrapper must be the script
# wrap-program wrote rather than the ELF itself: the RPATH set below is what
# makes the binary run, but XDG_DATA_DIRS and PATH are what make it find icons,
# mime types and xdg-open.
[ -L "$out/bin/zcode" ] || { echo "$out/bin/zcode is not a symlink" >&2; exit 1; }
grep -q 'XDG_DATA_DIRS' "$out/lib/ZCode/zcode" ||
  { echo "$out/lib/ZCode/zcode is not a wrapper" >&2; exit 1; }

grep -q "^Exec=$out/bin/zcode" "$out/share/applications/zcode.desktop" ||
  { echo "desktop Exec not rewritten to the store" >&2; exit 1; }
grep -q '/opt/ZCode' "$out/share/applications/zcode.desktop" &&
  { echo "desktop entry still refers to /opt" >&2; exit 1; } || true

patchelf() { guix shell -C patchelf -- patchelf "$@"; }

interpreter="$(patchelf --print-interpreter "$out/lib/ZCode/zcode")"
case "$interpreter" in
  /gnu/store/*) ;;
  *) echo "unpatched interpreter: $interpreter" >&2; exit 1 ;;
esac

# $ORIGIN first: Electron's own helpers (libffmpeg.so, libEGL.so) live next to
# the binary.  Then the Guix libraries it dlopens, which is the point of
# %zcode-rpath-inputs -- a literal store path, not $out, since the app directory
# is reached through $ORIGIN.
runpath="$(patchelf --print-rpath "$out/lib/ZCode/zcode")"
case "$runpath" in
  '$ORIGIN:'*/gnu/store/*-lib) ;;
  *) echo "unexpected runpath: $runpath" >&2; exit 1 ;;
esac

echo "zcode-bin smoke test passed"
