#!/usr/bin/env bash
# Run every Guix lint checker over all packages of this channel.  Advisory
# only: see the note in .github/workflows/build.yml about false positives on
# repackaged vendor binaries.
set -euo pipefail
cd "$(dirname "$0")/.."
# `-L .', not `-L sane-packages': the modules are named `(sane-packages ...)'.
# See the note on the derivations step in tests/check-static.sh for what the
# root on the load path costs (one harmless "error: channel: unbound variable"
# line, because tests/channels-lock.scm is a bare channel list, not a module).
exec guix lint -L .
