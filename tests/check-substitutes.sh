#!/usr/bin/env bash
# Consumer-side test of the substitute mirror: does a machine that never
# built anything -- same Guix pin, same channel checkout, nothing in its
# store -- install this channel's packages from the gh-pages mirror, and
# does what it installs actually run?
#
# It runs on a fresh runner (the `substitutes' job of build.yml), where
# nothing was built, so every store item must arrive as a substitute.  Three
# steps, each failing loudly:
#
#   1. dry-run WITHOUT the mirror: the test packages' own derivations must
#      be "would be built" -- they are this channel's own outputs, upstream
#      Guix has no substitutes for them, so this proves the packages cannot
#      be had without either building them or trusting our mirror.  Their
#      dependencies still download from bordeaux/ci.guix, which is fine;
#      only the packages themselves must not.
#   2. dry-run WITH the mirror authorized: the same packages must flip to
#      "would be downloaded" -- the mirror serves their exact output paths
#      (same channels-lock pin, so same grafts and same hashes).
#   3. a real `guix package --install' into a scratch profile, then the
#      packages' own smoke tests against the substituted store paths: the
#      narinfo signature check, the nar download, the hash validation and
#      the unpack all happened on the way, and the smoke tests prove the
#      imported trees execute.
#
# The test packages are chosen small (the mirror's 95 MB GitHub Pages cap
# skips big nars, so dsh and zcode are not on it) and one of them has a
# smoke test.  Their store paths come from the .drv files the step-1
# dry-runs name, so no step builds anything and version bumps track
# themselves; the narinfo probe in step 2 is what fails if a package fell
# off the mirror.
set -euo pipefail
cd "$(dirname "$0")/.."

MIRROR="${MIRROR_URL:-https://khaalidrafi.github.io/packages}"
# The daemon of a fresh runner knows bordeaux, ci.guix.gnu.org and nonguix;
# our URL is passed per command, exactly as README.org documents for users.
UPSTREAMS="https://ci.guix.gnu.org https://bordeaux.guix.gnu.org"
URLS="$UPSTREAMS $MIRROR"

# Packages to test: one tiny (90 KB nar) to keep the test quick, one real
# application with a smoke test (12 MB nar) to prove the imports run.
TEST_PKGS="casty-bin mcode-bin"

# --- 0. the mirror is alive and says what it is ----------------------------
info="$(curl -sf "$MIRROR/nix-cache-info")"
echo "$info" | grep -q '^StoreDir=/gnu/store$' || {
  echo "::error::$MIRROR/nix-cache-info is not a Guix cache" >&2; exit 1; }
echo "mirror answers: $(echo "$info" | tr '\n' ' ')"

# --- 1. authorize the signing key for the daemon ---------------------------
# The daemon (root) checks narinfo signatures against /etc/guix/acl, so the
# key has to be authorized for the daemon's user.  Idempotent: re-running
# must not append a second copy.  A restart makes sure a daemon that read
# the ACL before we touched it sees the new key.  The absolute path is not
# pedantry: sudo's secure_path does not carry the runner's guix profile
# (~/.config/guix/current/bin), so plain `sudo guix' is "command not
# found" (run 39022788916).
guix_bin="$(command -v guix)"
key_hex="$(sed -n 's/.*(q #\([0-9A-F]*\)#.*/\1/p' .guix-substitutes.pub)"
if sudo grep -q "$key_hex" /etc/guix/acl 2>/dev/null; then
  echo "signing key already authorized"
else
  sudo "$guix_bin" archive --authorize < .guix-substitutes.pub
  sudo systemctl restart guix-daemon
  echo "signing key authorized, daemon restarted"
fi

# --- 2. paths and the without-mirror proof, without building anything ------
declare -A paths
for pkg in $TEST_PKGS; do
  # The path cannot come from building (run 39026484531: a plain
  # `guix build' fetched 62.5 MB of deps and built the drvs, leaving the
  # outputs in the store and making every later step vacuous), and it
  # cannot come from --dry-run's tail either (run 39030479774: with work
  # pending, build-notifier skips the daemon call, so
  # show-derivation-outputs never runs and the output path is never
  # printed).  But the would-be-BUILT list names the package's .drv, and
  # the .drv file -- which computing the plan already wrote to the store
  # -- names its output paths in Derive([("out","/gnu/store/...","")]).
  # The drv is the grafted one, because options->derivations runs under
  # %graft?, so the output path is the one a real `guix build' (and the
  # mirror) would produce.
  #
  # No --no-grafts anywhere: the mirror publishes what build-all.sh
  # built, which is plain `guix build' with grafts.  The channels pin
  # makes both runners compute the same derivations, grafts included.
  dry="$(guix build -L . --dry-run \
           --substitute-urls="$UPSTREAMS" "$pkg" 2>&1 || true)"
  # The package itself must not be substitutable upstream.  Dependencies
  # downloading from bordeaux is expected (they are guix's own
  # packages), so the would-be-built/downloaded HEADINGS cannot tell
  # package from dependency; the lists can.  The package's drv ends in
  # .drv, its output path does not, and only these two name it.
  if grep -E "^ +/gnu/store/[0-9a-z]+-$pkg-[0-9]" <<<"$dry" | grep -qv '\.drv$'; then
    echo "::error::$pkg has an upstream substitute; it tests nothing" >&2
    exit 1
  fi
  drv="$(grep -E -- "/gnu/store/[0-9a-z]+-$pkg-[0-9][^ ]*\.drv$" <<<"$dry" | head -n1 | sed 's/^ *//' || true)"
  [ -n "$drv" ] || {
    echo "::error::upstreams alone would not build $pkg either:" >&2
    echo "$dry" >&2; exit 1; }
  # The first output tuple of the .drv names "out"; both test packages
  # are single-output, so a ("out",...) that found nothing means that
  # changed.
  out="$(grep -oE '\("out", *"/gnu/store/[0-9a-z]+-'"$pkg"'-[0-9][^"]*"' \
           "$drv" | head -n1 | sed -E 's/^\("out", *"//; s/"$//' || true)"
  [ -n "$out" ] || {
    echo "::error::$drv names no out output for $pkg" >&2; exit 1; }
  paths[$pkg]="$out"
  echo "$pkg -> $out (upstreams alone: would be built, as they should be)"
done

# --- 3. with the mirror they are downloads ---------------------------------
for pkg in $TEST_PKGS; do
  base="$(basename "${paths[$pkg]}")"
  hash="${base%%-*}"
  curl -sf "$MIRROR/$hash.narinfo" > /dev/null || {
    echo "::error::$MIRROR/$hash.narinfo is 404; $pkg is not on the mirror" >&2
    exit 1; }
  dry="$(guix build -L . --dry-run \
           --substitute-urls="$URLS" "$pkg" 2>&1)"
  # The package's own output path must now be in a would-be-downloaded
  # list (indented, no .drv); deps download too, which is fine.
  grep -E "^ +/gnu/store/[0-9a-z]+-$pkg-[0-9]" <<<"$dry" | grep -qv '\.drv$' || {
    echo "::error::mirror does not substitute $pkg:" >&2
    echo "$dry" >&2; exit 1; }
  echo "with mirror: $pkg would be downloaded"
done

# --- 4. the real thing: install into a profile from the mirror -------------
profile="$(mktemp -d)/profile"
for pkg in $TEST_PKGS; do
  # GUIX_PACKAGE_PATH, not -L: `guix package' has no load-path flag; the
  # environment variable is the supported way to point it at a checkout.
  GUIX_PACKAGE_PATH="$PWD" \
    guix package -p "$profile" --install "$pkg" \
    --substitute-urls="$URLS"
done

# --- 5. what was substituted must also run ---------------------------------
for pkg in $TEST_PKGS; do
  # Plain `guix build' prints the store path; after the install above it is
  # already in the store, so this resolves without building anything.
  out="$(guix build -L . "$pkg")"
  smoke="tests/smoke/$pkg.sh"
  if [ -x "$smoke" ]; then
    "$smoke" "$out"
  else
    echo "$pkg: no smoke test, checking bin/ only"
    ls "$out/bin" > /dev/null
  fi
done

echo "substitute install test passed"
