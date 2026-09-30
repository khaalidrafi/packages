#!/usr/bin/env bash
# Build every package of this channel and, when tests/smoke/PACKAGE.sh exists,
# run it against the resulting store path.  Every requested package is attempted
# so that one broken package does not hide another; the exit status covers them
# all.
#
# Source-based packages are built FIRST and `*-bin' packages after them: the
# source build is the one that can fail for a real reason (a patch, a phase, a
# dependency), whereas a `*-bin' build mostly proves a download and a wrapping
# work.  Leading with the source packages is what "prioritized" means here.
#
# This script only builds and smoke-tests.  Turning the resulting store into a
# substitute mirror is a separate concern: tests/publish-substitutes.sh does it,
# after this script has run, so the two can be reasoned about independently.
#
# Narrow a run with a space separated subset:
#   PACKAGES="zcode-bin dsh" ./tests/build-all.sh
set -uo pipefail
cd "$(dirname "$0")/.."

if [ -n "${PACKAGES:-}" ]; then
  # Honour the caller's order; do not re-sort an explicit subset.
  names="$PACKAGES"
else
  files=(sane-packages/*.scm)
  if [ ! -e "${files[0]:-}" ]; then
    echo "no modules found under sane-packages/" >&2
    exit 1
  fi
  all=$(grep -hoE '^\(define-public [^ )]+' "${files[@]}" | awk '{print $2}')
  # cline-baseline's fixed-output hash is still a placeholder (see README.org):
  # the one-time network build that captures it has not run, so building it here
  # would only fail on the expected hash mismatch.  It is still evaluated by
  # tests/check-static.sh, and you can build it on purpose with
  # PACKAGES="cline-baseline".  Drop this filter once the real hash is committed.
  source_pkgs=$(printf '%s\n' $all | grep -vE -- '-bin$|^cline-baseline$' || true)
  bin_pkgs=$(printf '%s\n' $all | grep -E -- '-bin$' || true)
  names="$(printf '%s\n' $source_pkgs) $(printf '%s\n' $bin_pkgs)"
fi

failed=()
for name in $names; do
  echo "==> build: $name"
  # Only stdout (the store paths) is captured; progress and errors stream to
  # the log from stderr, where Guix writes them.  A package can have several
  # outputs, so the result may be more than one path.
  if ! outs="$(guix build -L . "$name")"; then
    failed+=("$name (build)")
    continue
  fi

  # Hand the freshly built output paths to the publisher.  One path per line,
  # so GUIX_BUILT_PATHS is a plain list publish-substitutes.sh can read.
  if [ -n "${GUIX_BUILT_PATHS:-}" ]; then
    printf '%s\n' $outs >> "$GUIX_BUILT_PATHS"
  fi

  smoke="tests/smoke/$name.sh"
  if [ -x "$smoke" ]; then
    echo "==> smoke: $name"
    "$smoke" "$outs" || failed+=("$name (smoke)")
  fi
done

if [ ${#failed[@]} -ne 0 ]; then
  echo "failed: ${failed[*]}" >&2
  exit 1
fi
echo "all requested packages built"
