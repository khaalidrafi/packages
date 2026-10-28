#!/usr/bin/env bash
# The agent-team chain's landing gate: the checks that cost seconds, not
# minutes.  Full derivation validation (guix style, --dry-run) stays in
# tests/check-static.sh under build.yml (workflow_dispatch / pull_request)
# -- the chain runs up to six times a day and must not install Guix and
# start its daemon for every turn.  Needs: bash, guile (reader), python3.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Channel contract: every .scm file is a module.  `guix pull' compiles
#    every .scm under the repo root (.guix-channel declares no (directory
#    ...)), so one stray Scheme file breaks every user's pull.  Same logic
#    (and the same single exemption) as tests/check-static.sh.
echo "==> channel: every .scm file is a module"
non_module_ok='^\./tests/channels-lock\.scm$'
while IFS= read -r f; do
  grep -Eq "$non_module_ok" <<<"$f" && continue
  grep -q '(define-module' "$f" && continue
  cat >&2 <<EOF
$f is a Scheme file but not a Guile module.
'guix pull' would fail on it.  Either give it a define-module form (like
nonguix and brix do for their root-level files) or keep it out of the
repository.
EOF
  exit 1
done < <(find . -path ./.git -prune -o -name '*.scm' -print)

# 2. Reader check: every .scm parses as s-expressions.  A parenthesis slip
#    is a parse error for every guix pull too; this catches it with guile's
#    reader alone -- no Guix modules, no daemon, no network.
echo "==> reader: every .scm parses (guile)"
command -v guile >/dev/null || {
  echo "guile not found -- the reader check cannot run; install guile-3.0" >&2
  exit 1
}
if ! guile -c '
(define (check-file name)
  (call-with-input-file name
    (lambda (port)
      (let loop ()
        (let ((form (read port)))
          (unless (eof-object? form) (loop)))))))
(for-each check-file (cdr (command-line)))' \
  .guix-channel $(find . -path ./.git -prune -o -name '*.scm' -print); then
  echo "a Scheme file does not parse -- 'guix pull' would fail for every user" >&2
  exit 1
fi
echo "    all parse"

# 3. Generated zcode dependency tables: the one check they admit.
echo "==> generated tables: zcode dependency links resolve"
./tests/check-zcode-links.py

# 4. Shell syntax across the test/script surface.
echo "==> shell: bash -n over tests/*.sh and scripts/*.sh"
for sh in tests/*.sh scripts/*.sh; do
  bash -n "$sh"
done

# 5. Python syntax across scripts/.
echo "==> python: py_compile over scripts/*.py"
python3 -m py_compile scripts/*.py

echo "chain gate: GREEN"
