#!/usr/bin/env bash
# Smoke test for mcode-bin: the package installs a vendor JS bundle and wires
# its native deps as node_modules symlinks into the store, so the two ways it
# can silently break are (1) a store package changes its node_modules layout,
# leaving a dangling symlink that only fails at runtime, and (2) the bin
# wrappers stop pointing at a store node.  Both are asserted statically here,
# then the CLI is actually run: `mcode --version` boots cli.js, which imports
# better-sqlite3 eagerly, so a resolution failure surfaces as a build failure
# instead of a user-visible crash.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"
pkg="$out/share/mcode-bin"
nm="$pkg/node_modules"

fail() { echo "mcode-bin smoke: $*" >&2; exit 1; }

# --- wrappers -------------------------------------------------------------
for bin in mcode mcode-tools; do
    [ -x "$out/bin/$bin" ] || fail "$out/bin/$bin missing or not executable"
    # Must exec node by absolute store path: the bundle's own shebang is
    # "#!/usr/bin/env node", which would depend on the user's PATH.
    grep -qE 'exec /gnu/store/[^ ]*/bin/node ' "$out/bin/$bin" ||
        fail "$out/bin/$bin does not exec a store node"
done

# --- native module links --------------------------------------------------
# -e follows the symlink, so this fails on a dangling link (the layout moved)
# rather than passing on a broken one.
for mod in better-sqlite3 @vscode/ripgrep @mariozechner/clipboard; do
    [ -e "$nm/$mod" ] || fail "node_modules/$mod does not resolve"
    [ -f "$nm/$mod/package.json" ] || fail "node_modules/$mod has no package.json"
done
# The addon is what actually has to match the interpreter's ABI.  -L because
# node_modules/better-sqlite3 is itself a symlink into the store.  Captured
# rather than piped to grep -q: with pipefail, grep's early exit SIGPIPEs find
# and the pipeline "fails" on a perfectly good match.
addon="$(find -L "$nm/better-sqlite3" -name 'better_sqlite3.node')"
[ -n "$addon" ] || fail "better-sqlite3 addon (.node) not found"

# JS helper the bundle spawns by relative path, not through a wrapper.
[ -x "$pkg/internal-bin/mcode-tools" ] || fail "internal-bin/mcode-tools not executable"

# --- real invocation ------------------------------------------------------
# HOME is redirected to a temp dir: the CLI creates its data dir on startup
# and a CI container may have no writable HOME.
expected="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$pkg/package.json" | head -1)"
[ -n "$expected" ] || fail "could not read version from $pkg/package.json"

tmp="$(mktemp -d)"
actual="$(HOME="$tmp" "$out/bin/mcode" --version 2>/dev/null | tail -1)"
rm -rf "$tmp"

[ "$actual" = "$expected" ] ||
    fail "mcode --version printed '$actual', package.json says '$expected'"

echo "mcode-bin smoke test passed ($actual)"
