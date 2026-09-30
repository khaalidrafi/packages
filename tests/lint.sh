#!/usr/bin/env bash
# Run every Guix lint checker over all packages of this channel.  Advisory
# only: see the note in .github/workflows/build.yml about false positives on
# repackaged vendor binaries.
set -euo pipefail
cd "$(dirname "$0")/.."
exec guix lint -L .
