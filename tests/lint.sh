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
#
# The package list is passed explicitly.  `guix lint' with no arguments lints
# EVERY package on the load path, and `-L .' puts the whole pinned GNU set
# there too -- ~30k packages the channel does not maintain, hours of upstream
# probes per run (CI run 38676834662 spent over four hours in this step
# without ever reaching the build), and warnings this repository cannot act
# on.  The header comment has always said "all packages of this channel";
# deriving the list from the define-public forms is what actually scopes it
# to the channel, and it is the same convention build-all.sh already uses to
# decide what to build.
files=(sane-packages/*.scm)
if [ ! -e "${files[0]:-}" ]; then
  echo "no modules found under sane-packages/" >&2
  exit 1
fi
all=$(grep -hoE '^\(define-public [^ )]+' "${files[@]}" | awk '{print $2}')
exec guix lint -L . $all
