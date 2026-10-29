#!/usr/bin/env bash
# Print the newest ZCode version that upstream offers as a Linux .deb.
# The download links live in the product page's HTML, which is the same source
# numtide's updater scrapes; the GitHub releases only carry Windows/macOS
# installers, so they cannot be the reference for what we package.
set -euo pipefail

page="${ZCODE_PAGE:-https://zcode.z.ai/en}"

curl -fsSL "$page" |
  grep -oE 'ZCode-[0-9]+\.[0-9]+\.[0-9]+-linux-x64\.deb' |
  sed -E 's/^ZCode-(.*)-linux-x64\.deb$/\1/' |
  sort -V |
  tail -1
