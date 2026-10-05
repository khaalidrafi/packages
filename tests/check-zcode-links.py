#!/usr/bin/env python3
"""Check the relative link rows of sane-packages/zcode-modules.scm.

Every row in those tables is a (link, target) pair, both given relative to the
repository root, with target relative to the link's own directory.  A row is
sound only if resolving target against dirname(link) lands somewhere the build
actually populates:

  * a .bin entry must land inside an install path from %zcode-node-modules,
    which is the only place a tarball is ever unpacked;
  * a workspace link must land in a workspace directory from
    %zcode-workspace-order, i.e. a source directory copied out of the origin.

Both failures are dangling symlinks at run time and hard build failures at
build time -- zcode's builder reads each link and throws "bin entry points at a
target that is not there" -- so they are cheap to catch here and expensive to
find in CI, where the sandbox only shows the first one.

Checked separately: pnpm dependency edges inside node_modules/.pnpm.  Their
targets are siblings under .pnpm/<key>/, which no install path names directly,
so they are not judged against that list.
"""
import os
import re
import sys

SCM = sys.argv[1] if len(sys.argv) > 1 else "sane-packages/zcode-modules.scm"
text = open(SCM).read()


def block(name):
    """Return the body of the (list ...) form in (define NAME ...)."""
    start = re.search(r"\(define %s\b" % re.escape(name), text)
    if not start:
        sys.exit("could not find %s in %s" % (name, SCM))
    open_paren = text.index("(list", start.end())
    # Walk the parens rather than regexing to the next blank line: comments
    # inside the form and nested forms would both end the match too early.
    depth, end = 0, None
    for i in range(open_paren, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        sys.exit("unbalanced parens in %s" % name)
    return text[open_paren:end]


def quoted(line):
    return re.findall(r'"((?:[^"\\]|\\.)*)"', line)


def rows(name, width):
    return [quoted(line) for line in block(name).splitlines()
            if len(quoted(line)) == width]


install_paths = {f[3] for f in rows("%zcode-node-modules", 4)}
order = [q for line in block("%zcode-workspace-order").splitlines()
         for q in quoted(line)]
bin_rows = rows("%zcode-node-bin-links", 2)
workspace_rows = rows("%zcode-workspace-links", 2)


def resolve(link, target):
    return os.path.normpath(os.path.join(os.path.dirname(link), target))


def under(path, prefixes):
    return any(path == p or path.startswith(p + "/") for p in prefixes)


def main():
    broken = []
    workspace_prefixes = tuple("%s/node_modules/.bin/" % d for d in order)
    for link, target in bin_rows:
        where = resolve(link, target)
        if not under(where, install_paths):
            broken.append(("[ws]" if link.startswith(workspace_prefixes) else "[root]",
                           link, target, where))
    for link, target in workspace_rows:
        where = resolve(link, target)
        if not under(where, order):
            broken.append(("[ws-link]", link, target, where))

    print("bin rows:        %d" % len(bin_rows))
    print("workspace rows:  %d" % len(workspace_rows))
    print("install paths:   %d" % len(install_paths))
    print("workspaces:      %d" % len(order))
    print("broken links:    %d" % len(broken))
    for kind, link, target, where in broken:
        print("  %-9s %s" % (kind, link))
        print("            target %s" % target)
        print("            lands  %s" % where)
    if broken:
        print("\nRegenerate with scripts/gen-zcode-node-tree.py; the link targets "
              "are relative to the link's own directory.", file=sys.stderr)
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())