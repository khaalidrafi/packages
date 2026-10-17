#!/usr/bin/env bash
# Smoke test for konaito-terminal-browser-bin: two things can silently break
# this package and neither shows up as a build failure.
#
# 1. The node_modules tree: it is unpacked from a hundred hash-verified
#    tarballs, and a misplaced directory or a truncated tarball only fails
#    when Node walks the tree.  `--version' fails loudly on any of that:
#    dist/main.js statically imports the browser adapter, which imports
#    puppeteer, whose dependency closure IS the tree -- so a plain
#    `--version' boots every package that matters without needing a browser.
# 2. The browser wiring: the wrapper points PUPPETEER_EXECUTABLE_PATH at the
#    store's chrome-headless-shell, and upstream's --dump-frame exercises the
#    whole chain -- puppeteer launch, CDP session, Page.startScreencast,
#    software GL inside chrome-headless-shell -- and exits, which makes it
#    the one command that proves the package renders without needing a
#    kitty-graphics terminal or a TTY.
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

tb="$out/bin/terminal-browser"

[ -x "$tb" ] || { echo "missing executable $tb" >&2; exit 1; }

# --- 1. the module graph ---------------------------------------------------
version="$($tb --version)"
case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "unexpected --version output: $version" >&2; exit 1 ;;
esac
echo "terminal-browser --version: $version"

# --- 2. a real render --------------------------------------------------------
# file:// because the sandbox that smoke tests run next to has no network
# guarantee beyond what the build already used; a local page renders the
# same code paths as a remote one.  timeout is belt-and-braces: a screencast
# that never delivers a frame would hang the job otherwise.
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
cat > "$dir/page.html" <<'EOF'
<!doctype html>
<html>
  <head><title>konaito smoke</title></head>
  <body>
    <h1>guix-konaito-smoke-marker</h1>
    <p>rendered by chrome-headless-shell</p>
  </body>
</html>
EOF

# TERMINAL_BROWSER_CHROME_ARGS="--no-sandbox" is the runner accommodation
# (Ubuntu 24.04 restricts the unprivileged user namespaces Chromium's
# namespace sandbox needs); the wrapper's env hook passes it through.
log="$dir/tb.log"
TERMINAL_BROWSER_CHROME_ARGS="--no-sandbox" \
  timeout 180 "$tb" --dump-frame "$dir/frame.png" "$dir/page.html" \
  >"$log" 2>&1 || {
  echo "terminal-browser --dump-frame failed; its output:" >&2
  cat "$log" >&2
  exit 1; }

[ -s "$dir/frame.png" ] || { echo "dump-frame wrote no file" >&2; exit 1; }
size="$(stat -c %s "$dir/frame.png")"
[ "$size" -gt 2000 ] || { echo "frame is only $size bytes" >&2; exit 1; }
# PNG magic: the screencast returns PNG buffers, and a zero-length or
# text error response would still have written *something*.
printf '\211PNG\r\n\032\n' > "$dir/magic"
head -c 8 "$dir/frame.png" | cmp -s - "$dir/magic" || {
  echo "frame is not a PNG" >&2; exit 1; }

echo "konaito-terminal-browser-bin smoke test passed (frame: $size bytes)"
