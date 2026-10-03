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

# Run patchelf straight out of the store rather than through `guix shell -C':
# a container mounts only the profile of the packages it starts, so the store
# path under test is not visible inside it and patchelf reports a confusing
# "getting info about ...: No such file or directory" for a file that plainly
# exists on the host.
patchelf="$(guix build patchelf | head -1)/bin/patchelf"

# patchelf has to look at the ELF, which is no longer at bin/zcode or at
# lib/ZCode/zcode: wrap-program moved the original binary to
# .<name>-real beside the wrapper it wrote.  Asking patchelf about the wrapper
# fails with a misleading "getting info about ...: No such file or directory",
# because it is a shell script, not a missing file.
real="$out/lib/ZCode/.zcode-real"
[ -f "$real" ] || { echo "missing wrapped ELF $real" >&2; exit 1; }

interpreter="$("$patchelf" --print-interpreter "$real")"
case "$interpreter" in
  /gnu/store/*) ;;
  *) echo "unpatched interpreter: $interpreter" >&2; exit 1 ;;
esac

# $ORIGIN first: Electron's own helpers (libffmpeg.so, libEGL.so) live next to
# the binary.  Then the Guix libraries it dlopens, which is the point of
# %zcode-rpath-inputs -- a literal store path, not $out, since the app directory
# is reached through $ORIGIN.  Checked entry by entry rather than with one
# glob: the order of the entries follows the input list, and nss installs into
# lib/nss while everything else uses lib, so a single pattern would be tied to
# whichever package happens to be last.
runpath="$("$patchelf" --print-rpath "$real")"
[ "${runpath%%:*}" = '$ORIGIN' ] ||
  { echo "runpath does not start with \$ORIGIN: $runpath" >&2; exit 1; }
bad=""
IFS=':' read -ra entries <<< "$runpath"
for e in "${entries[@]:1}"; do
  case "$e" in
    /gnu/store/*/lib|/gnu/store/*/lib/nss) ;;
    *) bad="$bad $e" ;;
  esac
done
[ -z "$bad" ] || { echo "runpath entries outside the store:$bad" >&2; exit 1; }
[ "${#entries[@]}" -gt 1 ] ||
  { echo "runpath has no Guix libraries: $runpath" >&2; exit 1; }

echo "zcode-bin smoke test passed"
