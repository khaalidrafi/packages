#!/usr/bin/env bash
# Smoke test for dsh: the package is the upstream npm CLI (a plain JavaScript
# program, so the "binary" is the store node reading a launcher script) plus a
# 513-tarball vendored node_modules closure that the build wrote itself, since
# `npm install' cannot run in the Guix sandbox.  So this checks statically that
# the launcher points at the store node and that the closure actually landed --
# a closure that is missing even one import fails only at require time, which
# is why the whole tree has to be resolved for real -- and dynamically that the
# launcher runs far enough to print its version.
#
# `--version' is the safe full-path probe: commander answers it before the CLI
# resolves a Harness home or boots a profile, so it reads the CLI's own
# package.json and exits without writing anything.  `--profile x' would try to
# boot a profile and needs a real DSH_HOME; that is what the manual usage check
# in README.org is for.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

wrapper="$out/bin/dsh"
lib="$out/lib/node_modules/@deepseek-ai/dsh"
entry="$lib/lib/bin.js"

[ -x "$wrapper" ] || { echo "missing executable $wrapper" >&2; exit 1; }
[ -f "$entry" ]   || { echo "missing $entry" >&2; exit 1; }

# The launcher must exec the store node on the CLI entry point: Guix is not FHS,
# so a `#!/usr/bin/env node' shebang or a `/usr/bin/env' exec would fail here
# with ENOENT.  Both the shebang line and the exec line are written by the
# build, so checking them catches the launcher being half-rewritten.
head -1 "$wrapper" | grep -q '^#!/gnu/store/' ||
  { echo "$wrapper has no store shebang: $(head -1 "$wrapper")" >&2; exit 1; }
grep -q -- "$lib/lib/bin.js" "$wrapper" ||
  { echo "$wrapper does not exec $lib/lib/bin.js" >&2; exit 1; }
grep -q 'bin/node' "$wrapper" ||
  { echo "$wrapper does not go through the store node" >&2; exit 1; }

# The CLI entry point is ESM with a top-level `import.meta.main' dispatch, so
# it needs its whole static import graph to resolve from $lib.  These are the
# packages bin.js imports directly: the build stubs out every .bin symlink the
# manifest declares, so a package named here but absent from the closure is a
# packaging bug, not a lazy optional dependency.
for file in \
    lib/bin.js \
    package.json \
    node_modules/@deepseek-ai/dsh-app-boot \
    node_modules/@deepseek-ai/dsh-home-paths \
    node_modules/commander; do
  [ -e "$lib/$file" ] || { echo "closure is missing $lib/$file" >&2; exit 1; }
done

# bin.js's own `--profile-boot' and `--plugin' branches are dynamically
# imported, so a store move or a missing sibling would break them silently at
# runtime.  Check the files exist; booting a real profile is left to manual
# use because it writes a DSH_HOME.
for file in \
    lib/profile-boot.js \
    lib/dump-config-crgOY3tW.js \
    lib/dump-config-BEDI-dNY.js \
    lib/dump-config-schema-DhhNOaro.js \
    lib/plugin-BGnVfe_D.js; do
  [ -f "$lib/$file" ] || { echo "dynamic import is missing $lib/$file" >&2; exit 1; }
done

# The closure is generated from a lockfile, so a version bump can rename or
# drop a tarball and leave the tree incomplete.  Require it to actually
# resolve: --version prints what getDshRuntimeVersion() reads from this
# package's own package.json, so the value proves the entry point ran, the
# store node started, and the imports loaded.  A truncated or moved tree
# fails with a module-not-found error here instead.
version="$("$wrapper" --version 2>&1 | tail -1)"
case "$version" in
  [0-9]*.[0-9]*) ;;
  *) echo "dsh printed no version: $version" >&2; exit 1 ;;
esac

echo "dsh smoke test passed ($version)"
