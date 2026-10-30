#!/usr/bin/env bash
# Smoke test for autoclaw-bin: assert the AppImage payload survived the
# squashfs extraction and the copy phase, that the launcher and the .desktop
# entry point at the store rather than at the AppRuntime, that the main
# binary got a store interpreter and a RUNPATH, and that the two version
# stamps the payload carries agree with each other.  Nothing here needs a
# display; starting the GUI stays a manual check (see README.org).
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

for path in \
    bin/autoclaw \
    lib/AutoClaw/AutoClaw2 \
    lib/AutoClaw/.AutoClaw2-real \
    lib/AutoClaw/chrome-sandbox \
    lib/AutoClaw/chrome_crashpad_handler \
    lib/AutoClaw/resources/app/package.json \
    lib/AutoClaw/LICENSE.electron.txt \
    share/applications/autoclaw.desktop \
    share/icons/hicolor/512x512/apps/AutoClaw2.png; do
  [ -e "$out/$path" ] || { echo "missing $out/$path" >&2; exit 1; }
done

# bin/autoclaw must reach the launcher, and since 9ce25e7 it is a script
# the build writes, NOT a symlink: a symlink cannot add arguments, and the
# launch fix needs --disable-gpu before "$@" (9ce25e7; eece268 added
# --password-store=basic to the same exec line for DISPATCH #2's login
# persistence, whose login->restart->still-logged-in check stays with the
# Owner).  Assert the exact behaviour those commits promise: a regular
# script that execs the store launcher with both flags.  The launcher
# itself remains the script wrap-program wrote rather than the ELF: the
# RPATH checked below is what makes the binary run, but XDG_DATA_DIRS and
# PATH are what make it find icons, mime types and xdg-open.  The vendor
# ELF itself lives next to the wrapper as .AutoClaw2-real, which is the
# file patchelf checks apply to below.
[ -f "$out/bin/autoclaw" ] && [ ! -L "$out/bin/autoclaw" ] ||
  { echo "$out/bin/autoclaw is not the launcher script (regular file expected)" >&2; exit 1; }
grep -q 'lib/AutoClaw/AutoClaw2' "$out/bin/autoclaw" ||
  { echo "$out/bin/autoclaw does not exec the launcher" >&2; exit 1; }
grep -q -- '--disable-gpu' "$out/bin/autoclaw" ||
  { echo "$out/bin/autoclaw lost --disable-gpu (9ce25e7)" >&2; exit 1; }
grep -q -- '--password-store=basic' "$out/bin/autoclaw" ||
  { echo "$out/bin/autoclaw lost --password-store=basic (eece268)" >&2; exit 1; }
grep -q 'XDG_DATA_DIRS' "$out/lib/AutoClaw/AutoClaw2" ||
  { echo "$out/lib/AutoClaw/AutoClaw2 is not a wrapper" >&2; exit 1; }

# The payload's entry is `Exec=AppRun --no-sandbox %U': AppRun is the
# AppImage runtime's own script, which finds its payload next to itself.
# Rewriting it to the store is what keeps the menu entry working, and the
# zwork: scheme handler and the StartupWMClass are upstream's and must have
# survived the rewrite.
grep -q "^Exec=$out/bin/autoclaw" "$out/share/applications/autoclaw.desktop" ||
  { echo "desktop Exec not rewritten to the store" >&2; exit 1; }
grep -q 'AppRun' "$out/share/applications/autoclaw.desktop" &&
  { echo "desktop entry still refers to the AppImage runtime" >&2; exit 1; } || true
grep -q '^Icon=AutoClaw2$' "$out/share/applications/autoclaw.desktop" ||
  { echo "desktop Entry lost its icon name" >&2; exit 1; }
grep -q 'x-scheme-handler/zwork' "$out/share/applications/autoclaw.desktop" ||
  { echo "desktop entry lost the zwork: scheme handler" >&2; exit 1; }

# Run patchelf straight out of the store rather than through `guix shell -C':
# a container mounts only the profile of the packages it starts, so the store
# path under test is not visible inside it and patchelf reports a confusing
# "getting info about ...: No such file or directory" for a file that plainly
# exists on the host.  Ask about .AutoClaw2-real, the ELF wrap-program moved
# aside, not about the wrapper it wrote in its place.
patchelf="$(guix build patchelf | head -1)/bin/patchelf"
real="$out/lib/AutoClaw/.AutoClaw2-real"
[ -f "$real" ] || { echo "missing wrapped ELF $real" >&2; exit 1; }

interpreter="$("$patchelf" --print-interpreter "$real")"
case "$interpreter" in
  /gnu/store/*) ;;
  *) echo "unpatched interpreter: $interpreter" >&2; exit 1 ;;
esac

# $ORIGIN first: the bundle's own helpers (libEGL.so, libffmpeg.so) live next
# to the binary.  Then the Guix libraries it dlopens, which is the point of
# %autoclaw-rpath-inputs -- a literal store path, not $out, since the app
# directory is reached through $ORIGIN.  Checked entry by entry rather than
# with one glob: the order of the entries follows the input list, and nss
# installs into lib/nss while everything else uses lib, so a single pattern
# would be tied to whichever package happens to be last.
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

# The payload carries its version twice: in resources/app/package.json,
# where Electron's build recorded it, and in the .desktop entry's
# X-AppImage-Version, where appimagekit recorded it.  Two independent stamps
# that disagree mean the extraction or the copy moved, dropped or mixed
# payloads, so require them to agree and print the version for the log.
bundled_version="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]*"' \
  "$out/lib/AutoClaw/resources/app/package.json" \
  | head -1 | grep -oE '[0-9][0-9.]*[0-9]')"
[ -n "$bundled_version" ] ||
  { echo "no version found in the bundled package.json" >&2; exit 1; }
entry_version="$(sed -n 's/^X-AppImage-Version=//p' \
  "$out/share/applications/autoclaw.desktop")"
[ -n "$entry_version" ] ||
  { echo "no X-AppImage-Version in the desktop entry" >&2; exit 1; }
[ "$bundled_version" = "$entry_version" ] ||
  { echo "version stamps disagree: package.json has $bundled_version," \
     "desktop entry has $entry_version" >&2; exit 1; }

echo "autoclaw-bin smoke test passed ($bundled_version)"
