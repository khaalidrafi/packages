#!/usr/bin/env bash
# Smoke test for moli-bin: the package is a vendor ELF plus patchelf, and
# the two ways it breaks are (1) the interpreter or rpath is wrong, so the
# binary or one of its libraries fails to load on a non-FHS system, and
# (2) the JavaScript or layout engine is broken, which only shows up when
# a page is actually fetched.  `--version' catches the first; a real fetch
# of a page whose script rewrites the DOM catches the second -- scripts do
# not appear in a markdown dump, so the marker can only come from executed
# JavaScript -- and a --layout screenshot exercises the on-demand paint
# path on top.
#
# moli refuses file:// URLs (a local file navigation needs an explicitly
# granted capability), so the marker page is served from the loopback with
# python3's http.server; the build has already proven outbound network,
# and 127.0.0.1 needs none.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

mo="$out/bin/moli"

[ -x "$mo" ] || { echo "missing executable $mo" >&2; exit 1; }

version="$($mo --version)"
case "$version" in
  "moli "[0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "unexpected --version output: $version" >&2; exit 1 ;;
esac
echo "moli --version: $version"

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
    <h1>moli smoke marker</h1>
    <div id="nojs">js disabled</div>
    <script>document.getElementById('nojs').textContent = 'js-ran-marker';</script>
  </body>
</html>
EOF

port=8124
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$dir" >/dev/null 2>&1 &
server=$!
page="http://127.0.0.1:$port/page.html"
for _ in $(seq 1 50); do
  curl -fsS -o /dev/null "$page" && break
  sleep 0.2
done
curl -fsS -o /dev/null "$page" || { echo "server did not come up" >&2; exit 1; }

# The markdown dump carries no script tags, so the marker can only be
# there because the page's JavaScript ran and changed the DOM; the no-JS
# text is the static fallback that must be gone.
md="$($mo fetch --dump markdown --wait-until done "$page" 2>/dev/null)" || {
  echo "moli fetch failed" >&2
  exit 1; }
case "$md" in
  *js-ran-marker*) ;;
  *) echo "markdown dump carries no marker; dumped:" >&2
     printf '%s\n' "$md" | head -c 400 >&2
     exit 1 ;;
esac
case "$md" in
  *"js disabled"*) echo "page JavaScript did not run; dumped:" >&2
                    printf '%s\n' "$md" | head -c 400 >&2
                    exit 1 ;;
esac

# --layout turns on the geometry that a screenshot needs: this exercises
# the on-demand paint path on top of the structure-first dump above.
log="$dir/render.log"
"$mo" fetch --layout --dump screenshot "$page" > "$dir/frame.png" 2>"$log" || {
  echo "screenshot dump failed; its output:" >&2
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

echo "moli-bin smoke test passed (frame: $size bytes)"
