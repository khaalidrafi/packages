#!/usr/bin/env bash
# The agent-team chain's landing gate: the checks that cost seconds, not
# minutes.  Full derivation validation (guix style, --dry-run, real gexp
# reader) stays in tests/check-static.sh under build.yml
# (workflow_dispatch / pull_request) -- the chain runs up to six times a
# day and must not install Guix and start its daemon for every turn.
# Needs: bash, guile (paren scanner), python3.
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

# 2. Paren balance: every .scm stays well-formed.  A parenthesis slip is
#    a parse error for every guix pull too; this catches it with a
#    comment/string/char-literal-aware scanner.  Plain guile's reader is
#    NOT used directly: Guix's gexp reader macros (#~ #\$ #$@) need the
#    guix modules, which this gate deliberately does not install.
echo "==> balance: every .scm scans clean (guile)"
command -v guile >/dev/null || {
  echo "guile not found -- the balance check cannot run; install guile-3.0" >&2
  exit 1
}
if ! guile -c '
(define (balanced? name)
  (call-with-input-file name
    (lambda (port)
      (let lp ((depth 0))
        (let ((c (read-char port)))
          (cond
           ((eof-object? c)
            (unless (zero? depth) (error "unbalanced parens" name))
            #t)
           ((char=? c #\;)
            (let skip ((d (read-char port)))
              (if (or (eof-object? d) (char=? d #\newline))
                  (lp depth)
                  (skip (read-char port)))))
           ((char=? c #\")
            (let skip ((d (read-char port)))
              (cond ((eof-object? d) (error "unterminated string" name))
                    ((char=? d #\\) (read-char port) (skip (read-char port)))
                    ((char=? d #\") (lp depth))
                    (else (skip (read-char port))))))
           ((and (char=? c #\#) (char=? (peek-char port) #\\))
            (read-char port) (read-char port) (lp depth))
           ((and (char=? c #\#) (char=? (peek-char port) #\|))
            (read-char port)
            (let skip ((d (read-char port)))
              (cond ((eof-object? d) (error "unterminated block comment" name))
                    ((and (char=? d #\|) (char=? (peek-char port) #\#))
                     (read-char port) (lp depth))
                    (else (skip (read-char port))))))
           ((or (char=? c #\() (char=? c #\[)) (lp (+ depth 1)))
           ((or (char=? c #\)) (char=? c #\]))
            (if (zero? depth) (error "extra closer" name) (lp (- depth 1))))
           (else (lp depth))))))))
(for-each balanced? (cdr (command-line)))' \
  .guix-channel $(find . -path ./.git -prune -o -name '*.scm' -print); then
  echo "a Scheme file is malformed -- 'guix pull' would fail for every user" >&2
  exit 1
fi
echo "    all balanced"

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
