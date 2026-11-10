#!/usr/bin/env bash
# Smoke test for qoder-desktop-bin: static assertions on the Electron deb
# payload's installed layout and on the login-persistence contract of
# DISPATCH #2 carried into DISPATCH #3 Task 2.  Nothing here needs a
# display; starting the GUI stays a manual check (see README.org and the
# Owner-side UAT: login -> restart -> still logged in).
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

# The deb's opt/Qoder tree lands under lib/Qoder and usr/share under share/.
# lib/Qoder/qoder is the wrap-program output and .qoder-real is the ELF it
# moved aside -- the same convention autoclaw-bin's smoke asserts on
# (.AutoClaw2-real there).
for path in \
    bin/qoder-desktop \
    lib/Qoder/qoder \
    lib/Qoder/.qoder-real \
    share/applications/qoder.desktop; do
  [ -e "$out/$path" ] || { echo "missing $out/$path" >&2; exit 1; }
done

# bin/qoder-desktop must be a regular script, not a symlink: a symlink
# cannot carry arguments.  Login persistence (DISPATCH #2, reopened by the
# 2026-10-31 Owner UAT failure): the ZAI-family Electron stack rejects
# Chromium's basic_text backend (autoclaw's main.cjs does so in plain
# text), so the wrapper provides a real Secret Service instead of the
# basic flag -- session bus, blank-password login keyring seeded under the
# user's HOME, gnome-keyring-daemon secrets component -- and execs the
# wrapped launcher with no password-store flag (without a service
# Chromium falls back to basic_text on its own, so absence of the flag is
# never worse than the status quo).
[ -f "$out/bin/qoder-desktop" ] && [ ! -L "$out/bin/qoder-desktop" ] ||
  { echo "$out/bin/qoder-desktop is not the launcher script (regular file expected)" >&2; exit 1; }
grep -q "lib/Qoder/qoder" "$out/bin/qoder-desktop" ||
  { echo "$out/bin/qoder-desktop does not exec the wrapped launcher" >&2; exit 1; }
if grep -q -- '--password-store=basic' "$out/bin/qoder-desktop"; then
  { echo "$out/bin/qoder-desktop still carries --password-store=basic (rejected by the app: basic_text)" >&2; exit 1; }
fi
grep -q 'DBUS_SESSION_BUS_ADDRESS' "$out/bin/qoder-desktop" ||
  { echo "$out/bin/qoder-desktop lost the session-bus wiring" >&2; exit 1; }
grep -q 'gnome-keyring-daemon' "$out/bin/qoder-desktop" ||
  { echo "$out/bin/qoder-desktop lost the gnome-keyring wiring" >&2; exit 1; }
grep -q -- '--unlock --daemonize' "$out/bin/qoder-desktop" ||
  { echo "$out/bin/qoder-desktop lost the login-keyring seeding" >&2; exit 1; }

# The wrapped launcher must still carry the environment the payload needs:
# XDG_DATA_DIRS is what wrap-program wrote (icons, mime types), LD_LIBRARY_PATH
# is what the Electron helpers dlopen through.
grep -q 'XDG_DATA_DIRS' "$out/lib/Qoder/qoder" ||
  { echo "$out/lib/Qoder/qoder is not a wrap-program wrapper" >&2; exit 1; }
grep -q 'LD_LIBRARY_PATH' "$out/lib/Qoder/qoder" ||
  { echo "$out/lib/Qoder/qoder lost LD_LIBRARY_PATH" >&2; exit 1; }

# The deb's .desktop points at /opt/Qoder/qoder upstream; the build rewrites
# the Exec line to our bin/qoder-desktop so the menu entry works from the
# store and carries the same flag the wrapper does.
grep -q "^Exec=$out/bin/qoder-desktop" "$out/share/applications/qoder.desktop" ||
  { echo "desktop Exec not rewritten to the store launcher" >&2; exit 1; }
grep -q '/opt/Qoder' "$out/share/applications/qoder.desktop" &&
  { echo "desktop entry still refers to the deb's /opt path" >&2; exit 1; } || true

echo "qoder-desktop-bin smoke test passed"
