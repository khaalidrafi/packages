#!/usr/bin/env bash
# Publish the packages that tests/build-all.sh just built as a Guix substitute
# mirror, ready to serve from GitHub Pages (or any static file host).
#
# How it works (all of it from the Guix manual, node "Invoking guix publish"):
#
#   * `guix publish --cache=DIRECTORY' serves only items already baked into
#     DIRECTORY, and "the first .narinfo request triggers a background process
#     to bake the archive".  So warming the cache means GETting each store
#     path's .narinfo, then waiting for the baker to write the files.
#   * We bake only the *top-level outputs* of our packages, not their whole
#     closure: shared libraries (glibc, gcc, Mesa, ...) already have substitutes
#     on ci.guix.gnu.org / bordeaux.guix.gnu.org, which every user keeps enabled
#     alongside ours.  That is how nonguix publishes --- own outputs only ---
#     and it keeps the static mirror small enough for GitHub Pages' soft ~1 GB
#     repository limit.
#   * The on-disk cache layout differs from the wire protocol, so the last step
#     rearranges it.  `guix publish' bakes
#         CACHE/gzip/<store-item-basename>.narinfo
#         CACHE/gzip/<store-item-basename>.nar
#     but a client asks for (see `fetch-narinfos' in guix/substitutes.scm)
#         GET <root>/<hash>.narinfo            hash = hash-part of the basename
#         GET <root>/nar/gzip/<item-basename>  the URL: field in that narinfo
#     A live `guix publish' translates between the two, but a static host
#     cannot, so we materialise the client-facing layout.  <hash> is just the
#     basename up to its first '-', so no lookup table is needed.
#
# Inputs (all via the environment; CI sets them):
#   GUIX_SIGNING_KEY   private key, canonical-sexp text.  Required to publish.
#   GUIX_BUILT_PATHS   file of store paths to publish, one per line (the output
#                      of tests/build-all.sh).  Required.
#   GUIX_SUBST_CACHE   bake directory (default: ./.substitute-cache)
#   SITE_DIR           static mirror to write (default: ./.substitute-site)
# The matching public key is read from .guix-substitutes.pub in the repository
# and copied into the site so users can authorize the server in one command.
set -uo pipefail
cd "$(dirname "$0")/.."

: "${GUIX_SIGNING_KEY:?GUIX_SIGNING_KEY (the private key) is required}"
: "${GUIX_BUILT_PATHS:?GUIX_BUILT_PATHS (built store paths) is required}"
[ -s "$GUIX_BUILT_PATHS" ] || { echo "no built paths to publish" >&2; exit 1; }
[ -f .guix-substitutes.pub ] || { echo ".guix-substitutes.pub missing" >&2; exit 1; }

CACHE="${GUIX_SUBST_CACHE:-$PWD/.substitute-cache}"
SITE="${SITE_DIR:-$PWD/.substitute-site}"
# Clean runners have nothing on 8000; if it is taken, the poll below fails fast
# and the publish log names the collision.
PORT="${GUIX_PUBLISH_PORT:-8000}"

# --- start the publish server ------------------------------------------------
key_dir=$(mktemp -d)
# The private key signs narinfos; never print it.  0600 so only this user reads
# it, and it lives in a mktemp dir removed on exit.
printf '%s' "$GUIX_SIGNING_KEY" > "$key_dir/signing-key.sec"
chmod 600 "$key_dir/signing-key.sec"
cp .guix-substitutes.pub "$key_dir/signing-key.pub"
rm -rf "$CACHE"; mkdir -p "$CACHE"

# gzip only, so the narinfo URL, the cache directory name and the static mirror
# all agree on one compression method.  cache-bypass-threshold is irrelevant to
# baking (every request enqueues a bake) but keeps big items serving 200.
guix publish --cache="$CACHE" \
             --private-key="$key_dir/signing-key.sec" \
             --public-key="$key_dir/signing-key.pub" \
             -C gzip --nar-path=nar \
             --workers="$(nproc)" --cache-bypass-threshold=1G \
             -p "$PORT" >/tmp/guix-publish.log 2>&1 &
publish_pid=$!
cleanup() { kill "$publish_pid" 2>/dev/null || true; rm -rf "$key_dir"; }
trap cleanup EXIT

up=0
for _ in $(seq 1 30); do
  curl -sf "http://localhost:$PORT/nix-cache-info" >/dev/null && { up=1; break; }
  sleep 1
done
[ "$up" = 1 ] || { echo "guix publish did not start:"; cat /tmp/guix-publish.log >&2; exit 1; }

# --- warm the cache ----------------------------------------------------------
# Fire every narinfo request first (the publish worker pool bakes them in
# parallel), then wait for the whole set to land.  Waiting per-path would
# serialize the bakes.
paths=$(sort -u "$GUIX_BUILT_PATHS")
echo "==> baking $(printf '%s\n' "$paths" | wc -l) store items"
for path in $paths; do
  base=$(basename "$path")
  curl -sf "http://localhost:$PORT/${base%%-*}.narinfo" >/dev/null 2>&1 || true
done

# Each bake writes <base>.nar then <base>.narinfo; the narinfo is the "done"
# marker.  Poll until every requested item has one (or a generous timeout).
want=$(printf '%s\n' "$paths" | wc -l)
for _ in $(seq 1 900); do
  have=$(find "$CACHE/gzip" -name '*.narinfo' 2>/dev/null | wc -l)
  [ "$have" -ge "$want" ] && break
  sleep 2
done
have=$(find "$CACHE/gzip" -name '*.narinfo' 2>/dev/null | wc -l)
echo "==> baked $have/$want items"

kill "$publish_pid" 2>/dev/null || true
trap - EXIT

# --- rearrange the cache into the static (client-facing) layout --------------
rm -rf "$SITE"; mkdir -p "$SITE/nar/gzip"
count=0
for narinfo in "$CACHE"/gzip/*.narinfo; do
  [ -e "$narinfo" ] || continue
  base=$(basename "$narinfo" .narinfo)          # <hash>-<name>-<version>
  cp "$narinfo" "$SITE/${base%%-*}.narinfo"
  cp "$CACHE/gzip/$base.nar" "$SITE/nar/gzip/$base"
  count=$((count + 1))
done

# Advisory for users: authorize this server with this key, and point Guix at
# the Pages URL.
cp .guix-substitutes.pub "$SITE/pubkey"
printf 'StoreDir=/gnu/store\nWantMassQuery=1\nPriority=10\n' > "$SITE/nix-cache-info"

echo "static substitute mirror: $SITE ($count items)"
