#!/usr/bin/env bash
# Smoke test for the source-built zcode: the bundle must exist where the
# launcher says it does, must parse under Guix's Node, and the modules upstream
# deliberately kept OUT of the bundle (apps/zcode-cli/packages/cli/scripts/
# build.mjs: @zcode/tui, playwright-core, koffi) must resolve from next to it.
# That last part is the real risk of this package: the dependency tree is
# reconstructed from the lockfile rather than installed by pnpm, so a missing
# symlink is invisible until Node looks the module up at run time.
#
# It does not log in or run an agent -- that needs a provider token and a
# terminal; see "What CI cannot tell you" in README.org.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

cli="$out/lib/zcode/apps/zcode-cli/packages/cli"
bundle="$cli/dist/zcode.cjs"

[ -x "$out/bin/zcode" ] || { echo "$out/bin/zcode is missing or not executable" >&2; exit 1; }
[ -e "$bundle" ] || { echo "missing $bundle" >&2; exit 1; }

# The launcher names the bundle by absolute path; if that path is wrong the
# package still installs and then fails at the first `zcode'.
grep -qF "$bundle" "$out/bin/zcode" ||
  { echo "$out/bin/zcode does not point at $bundle" >&2; exit 1; }

# node --check only parses, which is the point: it proves the bundle is
# complete JavaScript for this Node rather than a truncated write.
guix shell -C node-lts -- node --check "$bundle"

# Resolve the three externals the way the running CLI does, from the bundle's
# directory.  require.resolve walks node_modules exactly as described in
# sane-packages/zcode-modules.scm, so this is the layout test.
guix shell -C node-lts -- node -e '
const [dist] = process.argv.slice(1);
for (const name of ["koffi", "playwright-core"]) {
  // require.resolve with `paths` walks node_modules from that directory, which
  // is exactly the tree this package reconstructs from the lockfile.
  const p = require.resolve(name, { paths: [dist] });
  if (!p.startsWith("/gnu/store/")) {
    console.error(name + " resolves outside the store: " + p);
    process.exit(1);
  }
}' "$cli/dist"

# @zcode/tui is a workspace package, not a tarball: esbuild left it external and
# pnpm linked it by path, so check the link and its build output.
tui="$(readlink -f "$cli/node_modules/@zcode/tui")"
[ -e "$tui/dist" ] || { echo "@zcode/tui has no dist: $tui" >&2; exit 1; }
grep -q '"main"\|"exports"' "$tui/package.json" ||
  { echo "@zcode/tui/package.json names no entry point" >&2; exit 1; }

# Licenses travel with the source they cover.
[ -s "$out/share/doc/zcode/LICENSE" ] ||
  { echo "missing $out/share/doc/zcode/LICENSE" >&2; exit 1; }

echo "zcode smoke test passed"
