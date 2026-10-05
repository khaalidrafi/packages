#!/usr/bin/env bash
# Smoke test for codebuddy-code-bin: the package installs a vendor JS bundle and
# wires esbuild in as a node_modules symlink into the store, so the two ways it
# can silently break are (1) a store package changes its node_modules layout,
# leaving a dangling symlink that only fails at runtime, and (2) the bin
# wrappers stop pointing at a store node.  Both are asserted statically here,
# then the CLI is actually run.
#
# Note the invocation is `--help`, not `--version`: the version check
# short-circuits before dist/codebuddy.js is ever loaded, so it still exits 0
# with esbuild missing and would pass on a broken build.  `--help` loads the
# full bundle, so a resolution failure surfaces here instead.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"
pkg="$out/share/codebuddy-code"
nm="$pkg/node_modules"

fail() { echo "codebuddy-code-bin smoke: $*" >&2; exit 1; }

# --- wrappers -------------------------------------------------------------
for bin in codebuddy codebuddy-code cbc cbc-prewarm codebuddy-lowmem; do
    [ -x "$out/bin/$bin" ] || fail "$out/bin/$bin missing or not executable"
    # Must exec node by absolute store path: the bundle's own shebang is
    # "#!/usr/bin/env node", which would depend on the user's PATH.
    grep -qE 'exec /gnu/store/[^ ]*/bin/node ' "$out/bin/$bin" ||
        fail "$out/bin/$bin does not exec a store node"
done

# --- native module links --------------------------------------------------
# -e follows the symlink, so this fails on a dangling link (the layout moved)
# rather than passing on a broken one.
[ -e "$nm/esbuild" ] || fail "node_modules/esbuild does not resolve"
[ -f "$nm/esbuild/package.json" ] || fail "node_modules/esbuild has no package.json"

# esbuild/lib/main.js resolves its native binary by bare specifier from inside
# its own lib/ directory, so the link to @esbuild/linux-x64 has to live in the
# esbuild package's own node_modules -- not beside the consumer.  Check it here
# because its absence only shows up as a runtime "download the binary" error.
esb_root="$(dirname "$(dirname "$(dirname "$(readlink -f "$nm/esbuild")")")")"
native="$esb_root/node_modules/@esbuild/linux-x64"
[ -e "$native/bin/esbuild" ] || fail "esbuild native binary not reachable at $native"

# Vendored ripgrep: x86-64 prebuilt that the bundle spawns by relative path.
rg_bin="$(find "$pkg/vendor/ripgrep" -name rg -type f 2>/dev/null | head -1)"
[ -n "$rg_bin" ] || fail "vendored ripgrep not found"
[ -x "$rg_bin" ] || fail "vendored ripgrep is not executable"

# --- real invocation ------------------------------------------------------
# HOME is redirected to a temp dir: the CLI creates its data dir on startup
# and a CI container may have no writable HOME.  No credentials are needed to
# print help, so this runs with no network and no account.
expected="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$pkg/package.json" | head -1)"
[ -n "$expected" ] || fail "could not read version from $pkg/package.json"

tmp="$(mktemp -d)"
actual="$(HOME="$tmp" "$out/bin/codebuddy" --version 2>/dev/null | tail -1)"
help_rc=0
HOME="$tmp" "$out/bin/codebuddy" --help >/dev/null 2>&1 || help_rc=$?
rm -rf "$tmp"

[ "$actual" = "$expected" ] ||
    fail "codebuddy --version printed '$actual', package.json says '$expected'"
[ "$help_rc" -eq 0 ] ||
    fail "codebuddy --help exited $help_rc (full bundle failed to load)"

echo "codebuddy-code-bin smoke test passed ($actual)"