#!/usr/bin/env bash
# Print the sha256 digests Guix needs for a version bump, without building
# anything.  GitHub release assets publish their sha256 directly through the
# API; npm tarballs publish only sha1/sha512, which Guix cannot use, so for
# those the tarball is fetched and hashed with `guix download`.
#
# Guix's (sha256 (base32 "...")) is the same content hash in Nix base32
# encoding: digest bytes read as a little-endian bignum, emitted in 5-bit
# groups from the highest group down, over the alphabet that drops e, o, t, u
# (nc (guix base32) / nixhash in the Nix sources).
#
#   ./scripts/bump-digests.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

# hex -> Nix base32, one "NAME HEXDIGEST" pair per line.
nix_base32() { # nix_base32 reads "name hexdigest" lines on stdin
  python3 -c '
import sys

ALPHABET = "0123456789abcdfghijklmnpqrsvwxyz"


def hex_to_nix_base32(hexstr):
    n = 0
    for b in reversed(bytes.fromhex(hexstr)):
        n = (n << 8) | b
    out = ""
    while n > 0:
        out = ALPHABET[n & 31] + out
        n >>= 5
    return out.rjust(52, "0")


for line in sys.stdin:
    name, _, dig = line.strip().partition(" ")
    print(name, hex_to_nix_base32(dig))
'
}

gh_asset() { # gh_asset OWNER/REPO TAG ASSET-NAME-SUBSTRING
  timeout 30 curl -fsSL "https://api.github.com/repos/$1/releases/tags/$2" |
    python3 -c '
import json,sys
d=json.load(sys.stdin)
want=sys.argv[1]
for a in d["assets"]:
    if want in a["name"]:
        dg=(a.get("digest") or "").removeprefix("sha256:")
        if dg:
            print(a["name"], dg)
' "$3" | nix_base32
}

npm_base32() { # npm_base32 TARBALL-URL  -- guix download computes the hash
  guix download "$1"
}

echo "### bun 1.4.3"
gh_asset oven-sh/bun bun-v1.4.3 bun-linux-x64.zip
gh_asset oven-sh/bun bun-v1.4.3 bun-linux-x64-baseline.zip
echo "### opencode 1.19.0"
gh_asset anomalyco/opencode v1.19.0 opencode-linux-x64.tar.gz
gh_asset anomalyco/opencode v1.19.0 opencode-linux-x64-baseline.tar.gz
echo "### goose 1.54.0"
gh_asset aaif-goose/goose v1.54.0 goose-x86_64-unknown-linux-gnu.tar.gz
echo "### oh-my-pi 18.10.1"
gh_asset can1357/oh-my-pi v18.10.1 omp-linux-x64
echo "### pi 1.1.0"
gh_asset earendil-works/pi v1.1.0 pi-linux-x64.tar.gz

# npm tarballs: no sha256 upstream, so fetch and hash.  A few MB each, so
# comment these out when only the GitHub half is needed.
echo "### npm digests (fetched, hashed with guix download)"
echo -n "mcode 0.6.8: "
npm_base32 "https://registry.npmjs.org/@minimax-ai/code/-/code-0.6.8.tgz"
echo -n "codebuddy 2.164.0: "
npm_base32 "https://registry.npmjs.org/@tencent-ai/codebuddy-code/-/codebuddy-code-2.164.0.tgz"
echo -n "copilot 1.0.95 loader: "
npm_base32 "https://registry.npmjs.org/@github/copilot/-/copilot-1.0.95.tgz"
echo -n "copilot 1.0.95 platform: "
npm_base32 "https://registry.npmjs.org/@github/copilot-linux-x64/-/copilot-linux-x64-1.0.95.tgz"
echo -n "opencode2 2.0.27 avx2: "
npm_base32 "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-2.0.27.tgz"
echo -n "opencode2 2.0.27 baseline: "
npm_base32 "https://registry.npmjs.org/@opencode/cli-linux-x64-baseline/-/cli-linux-x64-baseline-2.0.27.tgz"
echo -n "cline 3.0.70: "
npm_base32 "https://registry.npmjs.org/@cline/cli-linux-x64/-/cli-linux-x64-3.0.70.tgz"
