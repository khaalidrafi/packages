#!/usr/bin/env bash
# Smoke test for chrome-headless-shell-bin: the package is a vendor ELF plus
# patchelf, and the two ways it breaks are (1) the interpreter or rpath is
# wrong, so the binary or one of its dlopened libraries fails to load on a
# non-FHS system, and (2) the resource files (.pak, icudtl.dat, the
# SwiftShader ICD) are not where the binary resolves them from, which only
# shows up when a page renders.  `--version' catches the first; a real
# --screenshot catches the second, software GL included, and needs no
# display: this binary exists to render without one.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

shell="$out/bin/chrome-headless-shell"

[ -x "$shell" ] || { echo "missing executable $shell" >&2; exit 1; }

version="$("$shell" --version)"
case "$version" in
  *Chrome*Testing*) ;;
  *) echo "unexpected --version output: $version" >&2; exit 1 ;;
esac
echo "chrome-headless-shell --version: $version"

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
cat > "$dir/page.html" <<'EOF'
<!doctype html>
<html>
  <body><h1>chrome-headless-shell smoke marker</h1></body>
</html>
EOF

# --no-sandbox: this runs on CI runners, and Ubuntu 24.04 restricts
# unprivileged user namespaces (apparmor), which is where Chromium's
# namespace sandbox lives; a stock binary traps there.  On a normal
# system the sandbox works -- this flag is the runner accommodation.
log="$dir/chrome.log"
timeout 120 "$shell" "--screenshot=$dir/frame.png" --window-size=800,600 \
  --no-first-run --no-sandbox "file://$dir/page.html" >"$log" 2>&1 || {
  echo "chrome-headless-shell failed; its output:" >&2
  cat "$log" >&2
  exit 1; }

[ -s "$dir/frame.png" ] || { echo "screenshot wrote no file" >&2; exit 1; }
size="$(stat -c %s "$dir/frame.png")"
[ "$size" -gt 2000 ] || { echo "screenshot is only $size bytes" >&2; exit 1; }
printf '\211PNG\r\n\032\n' > "$dir/magic"
head -c 8 "$dir/frame.png" | cmp -s - "$dir/magic" || {
  echo "screenshot is not a PNG" >&2; exit 1; }

echo "chrome-headless-shell-bin smoke test passed (frame: $size bytes)"
