#!/usr/bin/env python3
"""Rewrite the (commit ...) fields in tests/channels-lock.scm from upstream tips.

Prints the diff-worthy result on stdout; the caller (the shell wrapper) or a
human decides what to do with it.  Used by tests/update-channels-lock.sh, which
supplies the two commits it already resolved.

WHY NOT sed/awk
===============
The obvious tool is a regex on the 40-hex string, and it is wrong twice over.
This file's comments *mention* ``(commit ...)`` in prose, so a line-based match
has to tell a form from a comment -- and getting that wrong silently edits the
wrong line instead of failing.  It also has to know which of the two channels a
commit belongs to, which means threading state through the file.

Why not a Scheme reader either: reading the file as forms is fine, but writing
them back drops every comment -- and in a file whose entire value is the
comments next to the pins, losing them is data loss, not reformatting.

So: regex to *locate* candidate lines, then a real balance check to make sure a
hit is a genuine form, and a positional substitution so no reformat happens.
Every uncertainty raises rather than guessing.
"""
import re
import sys

# (name 'guix) / (name 'nonguix), optionally with whitespace between the parts.
NAME_RE = re.compile(r"\(\s*name\s+'?(?P<chan>guix|nonguix)'?\s*\)")
# (commit "<40 hex>")
COMMIT_RE = re.compile(r'\(\s*commit\s+"(?P<hash>[0-9a-f]{40})"\s*\)')


def channel_name(line: str):
    """Channel named on this line, or None."""
    m = NAME_RE.search(line)
    return m.group("chan") if m else None


def balanced(src: str, start: int) -> bool:
    """True if the parenthesised form opening at `start` closes in `src`.

    Scheme comments make naive counting wrong, so anything that would change
    the count (a quote, a character constant, a comment) makes this give up and
    report unbalanced rather than return a wrong answer.
    """
    depth = 0
    i = start
    n = len(src)
    while i < n:
        c = src[i]
        if c == ";":
            nl = src.find("\n", i)
            i = n if nl < 0 else nl
            continue
        if c in "'\"":
            # A string, or a quote-prefixed datum such as (name 'guix).  Skip
            # to the matching close; a lone ' is a normal symbol character in
            # Scheme, so only treat it as a string when it opens one.
            if c == '"' or (i + 1 < n and src[i + 1] == "("):
                quote = c
                i += 1
                while i < n and src[i] != quote:
                    i += 2 if src[i] == "\\" else 1
                i += 1
                continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return True
        i += 1
    return False


def rewrite(src: str, guix: str, nonguix: str) -> tuple[str, list[str]]:
    """Return (new source, list of human-readable changes)."""
    lines = src.splitlines(keepends=True)
    out = []
    changes = []
    # Channel is carried across lines, so a (name 'x) on its own line still
    # tells us what the (commit "...") two lines down belongs to.
    current = None
    offset = 0

    for line in lines:
        name = channel_name(line)
        if name:
            current = name
        m = COMMIT_RE.search(line)
        if m and current:
            # Reject a hit that is not the whole form: that is either prose in
            # a comment or something we do not understand, and guessing is how
            # a lock file gets corrupted quietly.
            start = offset + m.start()
            if balanced(src, start):
                replacement = COMMIT_RE.sub(
                    '(commit "%s")' % (guix if current == "guix" else nonguix), line
                )
                changes.append("%s: %s -> %s" % (current, m.group("hash"), replacement.strip()))
                out.append(replacement)
                offset += len(line)
                continue
        out.append(line)
        offset += len(line)

    return "".join(out), changes


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: retarget-channels-lock.py FILE GUIX_COMMIT NONGUIX_COMMIT", file=sys.stderr)
        return 2
    path, guix, nonguix = sys.argv[1], sys.argv[2], sys.argv[3]
    for value, label in ((guix, "guix"), (nonguix, "nonguix")):
        if not re.fullmatch(r"[0-9a-f]{40}", value):
            print("not a 40-hex commit: %s=%s" % (label, value), file=sys.stderr)
            return 2

    with open(path, encoding="utf-8") as fh:
        src = fh.read()

    new, changes = rewrite(src, guix, nonguix)
    if not changes:
        print("NO-EDIT")
        return 0
    if new == src:
        # Every candidate was already at the right hash.
        print("NO-EDIT")
        return 0

    with open(path, "w", encoding="utf-8") as fh:
        fh.write(new)
    for change in changes:
        print(change)
    return 0


if __name__ == "__main__":
    sys.exit(main())
