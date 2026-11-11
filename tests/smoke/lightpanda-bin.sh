#!/usr/bin/env bash
# Smoke test for lightpanda-bin: the package is a vendor ELF plus one
# patchelf rewrite, and the two ways it breaks are (1) the interpreter is
# wrong, so the binary fails to load on a non-FHS system, and (2) the
# rendering or JavaScript engine is broken, which only shows up when a
# page is actually fetched.  `version' catches the first; a real fetch of
# a page whose script rewrites the DOM catches the second, because the
# dumped HTML then carries the script's change instead of the static
# source.
#
# lightpanda rejects file:// URLs (UnsupportedProtocol), so the marker page
# is served from the loopback with python3's http.server; the build has
# already proven outbound network, and 127.0.0.1 needs none.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

lp="$out/bin/lightpanda"

[ -x "$lp" ] || { echo "missing executable $lp" >&2; exit 1; }

version="$($lp version)"
case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "unexpected version output: $version" >&2; exit 1 ;;
esac
echo "lightpanda version: $version"

dir="$(mktemp -d)"
server=""
cleanup() {
  if [ -n "$server" ]; then kill "$server" 2>/dev/null || true; fi
  rm -rf "$dir"
}
trap cleanup EXIT

cat > "$dir/page.html" <<'EOF'
<!doctype html>
<html>
  <body>
    <h1>lightpanda smoke marker</h1>
    <div id="nojs">js disabled</div>
    <script>document.getElementById('nojs').textContent = 'js-ran-marker';</script>
  </body>
</html>
EOF

port=8123
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$dir" >/dev/null 2>&1 &
server=$!
page="http://127.0.0.1:$port/page.html"
for _ in $(seq 1 50); do
  curl -fsS -o /dev/null "$page" && break
  sleep 0.2
done
curl -fsS -o /dev/null "$page" || { echo "server did not come up" >&2; exit 1; }

# The dumped HTML must show the DOM change the page's script makes.  The
# static source contains both the marker string (inside the script tag)
# and the no-JS text, so the discriminator is the no-JS text: it is gone
# exactly when the JavaScript engine ran.
html="$($lp fetch --dump html "$page" 2>/dev/null)" || {
  echo "lightpanda fetch failed" >&2
  exit 1; }
case "$html" in
  *js-ran-marker*) ;;
  *) echo "fetch returned no marker; dumped:" >&2
     printf '%s\n' "$html" | head -c 400 >&2
     exit 1 ;;
esac
case "$html" in
  *"js disabled"*) echo "page JavaScript did not run; dumped:" >&2
                    printf '%s\n' "$html" | head -c 400 >&2
                    exit 1 ;;
esac

# A PNG dump exercises the software rendering path end to end.
log="$dir/render.log"
"$lp" fetch --dump png "$page" > "$dir/frame.png" 2>"$log" || {
  echo "png dump failed; its output:" >&2
  cat "$log" >&2
  exit 1; }
size="$(stat -c %s "$dir/frame.png")"
[ "$size" -gt 2000 ] || { echo "frame is only $size bytes" >&2; exit 1; }
# PNG magic: a zero-length or text error response would still have
# written *something* to the file.
printf '\211PNG\r\n\032\n' > "$dir/magic"
head -c 8 "$dir/frame.png" | cmp -s - "$dir/magic" || {
  echo "frame is not a PNG" >&2
  exit 1; }

echo "lightpanda-bin smoke test passed (frame: $size bytes)"
