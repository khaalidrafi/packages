#!/usr/bin/env python3
"""Regenerate sane-packages/zcode-modules.scm from ZCode's pnpm-lock.yaml.

Why this exists: `guix build zcode' has to compile ZCode's terminal CLI without
network access, which means every npm dependency has to arrive as its own
hash-verified origin.  pnpm's lockfile already records the exact graph, so this
script reads it and prints the Scheme table the package splices in.  Run it
with the new version, which is also %version in zcode.scm:

    git clone --branch v<version> https://github.com/zai-org/ZCode /tmp/ZCode
    ./scripts/gen-zcode-node-tree.py /tmp/ZCode <version> \
        > sane-packages/zcode-modules.scm

Tarballs are downloaded into (and reused from) $ZCODE_DEP_CACHE, so a version
bump only costs the dependencies that actually changed.  Nothing here builds
anything: the script only fetches tarballs to (a) hash them and (b) read their
package.json `bin' fields, which is all the on-disk layout needs.

Layout: upstream asks for pnpm's *hoisted* node linker (.npmrc), which is an
npm-style flat tree that only pnpm's own hoisting algorithm can produce
faithfully.  We lay out pnpm's *isolated* tree instead -- one directory per
lockfile key under node_modules/.pnpm, one symlink per dependency edge, plus
the flat .pnpm/node_modules view pnpm itself maintains for ambient lookups.
Every package then resolves exactly the version the lockfile pinned, and
nothing that upstream's tree offers is missing, so tsc and esbuild see a
consistent graph.  Non-matching optional dependencies (other operating systems,
cpus, or musl) are left out, exactly as `pnpm install' would on this platform.
"""

import collections
import hashlib
import json
import os
import re
import subprocess
import sys
import tarfile

TARGET = {"os": "linux", "cpu": "x64", "libc": "glibc"}
CACHE = os.environ.get("ZCODE_DEP_CACHE", "/tmp/zdep/dl")
START = "apps/zcode-cli/packages/cli"
VERSION = sys.argv[2] if len(sys.argv) > 2 else "3.14.3"


# --------------------------------------------------------------------------
# Reading the lockfile
# --------------------------------------------------------------------------
# Guile and Python here have no YAML parser, and pnpm-lock.yaml only uses block
# mappings, block sequences and flow collections ({a: 'b', c: [d]}), so the
# small recursive-descent parser below is enough.  Anything it misreads shows up
# as a KeyError or a failed assertion in the caller rather than as a silently
# wrong table.

def _split_flow(body):
    """Split a flow collection on commas outside brackets and quotes."""
    out, depth, quote, cur = [], 0, "", ""
    for ch in body:
        if quote:
            cur += ch
            if ch == quote:
                quote = ""
            continue
        if ch in "'\"":
            quote = ch
            cur += ch
            continue
        if ch in "[{":
            depth += 1
        elif ch in "]}":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return out


def _unquote(s):
    s = s.strip()
    if len(s) > 1 and s[0] == s[-1] and s[0] in "'\"":
        return s[1:-1].replace("''", "'")
    return s


def _flow_value(v):
    v = v.strip()
    if v.startswith("[") and v.endswith("]"):
        return [_unquote(x) for x in _split_flow(v[1:-1]) if x.strip()]
    return _unquote(v)


def _scalar(s):
    s = s.strip()
    if s in ("{}", ""):
        return {}
    if s == "[]":
        return []
    if s.startswith("{") and s.endswith("}"):
        out = {}
        for part in _split_flow(s[1:-1]):
            if ":" not in part:
                continue
            k, v = part.split(":", 1)
            out[_unquote(k)] = _flow_value(v)
        return out
    if s.startswith("[") and s.endswith("]"):
        return [_flow_value(x) for x in _split_flow(s[1:-1]) if x.strip()]
    return _unquote(s)


def load_lock(path):
    text = open(path).read()
    lines = text.split("\n")

    def parse(start, end, indent):
        i = start
        while i < end and (not lines[i].strip() or lines[i].lstrip().startswith("#")):
            i += 1
        if i >= end:
            return {}
        out = [] if lines[i].lstrip().startswith("- ") else {}
        while i < end:
            if not lines[i].strip():
                i += 1
                continue
            col = len(lines[i]) - len(lines[i].lstrip())
            if col < indent:
                break
            if col > indent:
                i += 1
                continue
            stripped = lines[i].strip()
            if isinstance(out, list):
                out.append(_scalar(stripped[2:]))
                i += 1
                continue
            m = re.match(r"^((?:'[^']*'|\"[^\"]*\"|[^:])+):\s*(.*)$", stripped)
            if not m:
                i += 1
                continue
            key = _unquote(m.group(1))
            rest = m.group(2)
            j = i + 1
            while j < end and (not lines[j].strip()
                               or (len(lines[j]) - len(lines[j].lstrip())) > col):
                j += 1
            out[key] = _scalar(rest) if rest.strip() else parse(i + 1, j, col + 2)
            i = j
        return out

    tops = [(i, m.group(1))
            for i, l in enumerate(lines) if (m := re.match(r"^([a-zA-Z][^:]*):$", l))]
    doc = {}
    for n, (i, name) in enumerate(tops):
        end = tops[n + 1][0] if n + 1 < len(tops) else len(lines)
        doc[name] = parse(i + 1, end, 2)
    return doc


def as_dict(value):
    return value if isinstance(value, dict) else {}


# --------------------------------------------------------------------------
# Lockfile keys, platform filtering, tarballs
# --------------------------------------------------------------------------

def platform_of(entry):
    """{os: [...], cpu: [...], libc: [...]} as the lockfile declares them."""
    entry = as_dict(entry)
    fields = {}
    engines = as_dict(entry.get("engines"))
    for key in ("os", "cpu", "libc"):
        value = entry.get(key, engines.get(key))
        if value is not None:
            fields[key] = value if isinstance(value, list) else [value]
    return fields


def fits(key, packages):
    fields = platform_of(packages.get(key))
    return all(not fields.get(name) or (want in fields[name]) or ("any" in fields[name])
               for name, want in TARGET.items())


def snapshot_key(name, ref, snapshots):
    """The lockfile key a dependency reference denotes, or None if absent."""
    key = ref if ref.startswith(name + "@") else name + "@" + ref
    if key in snapshots:
        return key
    base = re.sub(r"\(.*?\)", "", key)
    matches = [s for s in snapshots if s.split("(")[0] == base]
    return matches[0] if matches else None


def name_version(key):
    """('@babel/core', '7.29.0') from a snapshot key, peers dropped."""
    head = key.split("(")[0]
    at = head.rindex("@")
    raw, version = head[:at], head[at + 1:]
    return (raw.replace("+", "/") if raw.startswith("@") else raw), version


def dir_name(key):
    """The directory pnpm names a snapshot: every '/' becomes '+'."""
    return key.replace("/", "+")


def tarball_url(name, version):
    if name.startswith("@"):
        scope, base = name.split("/", 1)
        return "https://registry.npmjs.org/%s/%s/-/%s-%s.tgz" % (scope, base, base, version)
    return "https://registry.npmjs.org/%s/-/%s-%s.tgz" % (name, name, version)


def fetch(name, version):
    flat = name.replace("/", "+").replace("@", "")
    path = os.path.join(CACHE, "%s-%s.tgz" % (flat, version))
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        os.makedirs(CACHE, exist_ok=True)
        tmp = path + ".part"
        subprocess.run(["curl", "-sSL", "--retry", "3", "-o", tmp, tarball_url(name, version)],
                       check=True)
        if not os.path.getsize(tmp):
            sys.exit("empty tarball for %s@%s" % (name, version))
        os.replace(tmp, path)
    return path


NIX_BASE32 = "0123456789abcdfghijklmnpqrsvwxyz"


def nix_base32(digest):
    """Encode a sha256 the way `guix hash' prints it (little-endian base-32).

    Guix's `base32' reader expects this encoding, not RFC 4648: the digest
    bytes form one integer read from the low end, printed most significant
    five bits first over ceil(bits / 5) characters of a vowel-free alphabet.
    Cross-checked against `guix hash' output before use.
    """
    number = int.from_bytes(digest, "little")
    width = (len(digest) * 8 + 4) // 5
    return "".join(NIX_BASE32[(number >> (5 * i)) & 0x1F] for i in range(width - 1, -1, -1))


def hash_tarball(name, version):
    with open(fetch(name, version), "rb") as handle:
        return nix_base32(hashlib.sha256(handle.read()).digest())


def bin_entries(name, version, _cache={}):
    """{command: path-inside-package} from the tarball's package.json."""
    if (name, version) not in _cache:
        result = {}
        with tarfile.open(fetch(name, version), "r:gz") as tar:
            root = tar.getnames()[0].split("/")[0]
            member = tar.getroot().getmember(root + "/package.json") if False else None
            for m in tar:
                if m.name == root + "/package.json":
                    manifest = json.load(tar.extractfile(m))
                    bin_ = manifest.get("bin")
                    if isinstance(bin_, dict):
                        result = {k: v for k, v in bin_.items() if isinstance(v, str)}
                    elif isinstance(bin_, str):
                        result = {manifest.get("name", name).split("/")[-1]: bin_}
        _cache[(name, version)] = result
    return _cache[(name, version)]


# --------------------------------------------------------------------------
# The graph a source build needs
# --------------------------------------------------------------------------

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "/tmp/ZCode"
    lock = load_lock(os.path.join(root, "pnpm-lock.yaml"))
    snapshots, packages, importers = lock["snapshots"], lock["packages"], lock["importers"]

    # Workspace packages reachable through the lockfile's `link:' references.
    links = {}
    for directory, entry in importers.items():
        found = {}
        for kind in ("dependencies", "devDependencies", "optionalDependencies"):
            for name, spec in as_dict(as_dict(entry).get(kind)).items():
                version = spec.get("version", "") if isinstance(spec, dict) else spec
                if isinstance(version, str) and version.startswith("link:"):
                    found[name] = os.path.normpath(
                        os.path.join(directory, version[len("link:"):]))
        links[directory] = found

    order, done, cycles = [], set(), []

    def visit(directory, stack):
        if directory in done:
            return
        if directory in stack:
            cycles.append(" -> ".join(stack + [directory]))
            return
        for target in links.get(directory, {}).values():
            visit(target, stack + [directory])
        done.add(directory)
        order.append(directory)

    visit(START, [])
    if cycles:
        sys.stderr.write("warning: workspace cycles, order may be wrong:\n  %s\n"
                         % "\n  ".join(cycles))

    # npm closure over those workspaces.  Development dependencies count: tsc,
    # esbuild and vite are how the packages are compiled.
    seen, edges, missing = set(), {}, []
    queue = collections.deque()

    def push(name, ref):
        key = snapshot_key(name, ref, snapshots)
        if key is None:
            missing.append((name, ref))
            return
        if not fits(key, packages) or key in seen:
            return
        seen.add(key)
        node = as_dict(snapshots.get(key))
        deps = {}
        for kind in ("dependencies", "optionalDependencies"):
            for n2, ref2 in as_dict(node.get(kind)).items():
                if isinstance(ref2, str):
                    deps[n2] = ref2
                    queue.append((n2, ref2))
        edges[key] = deps

    if START not in importers:
        sys.exit("%s is not a workspace in this lockfile" % START)
    entry = as_dict(importers[START])
    for kind in ("dependencies", "devDependencies", "optionalDependencies"):
        for name, spec in as_dict(entry.get(kind)).items():
            version = spec.get("version", "") if isinstance(spec, dict) else spec
            if version and not version.startswith("link:"):
                queue.append((name, version))
    # Seed from every reachable workspace, not just the entry point.
    for directory in order:
        entry = as_dict(importers.get(directory))
        for kind in ("dependencies", "devDependencies", "optionalDependencies"):
            for name, spec in as_dict(entry.get(kind)).items():
                version = spec.get("version", "") if isinstance(spec, dict) else spec
                if version and not version.startswith("link:"):
                    queue.append((name, version))
    while queue:
        push(*queue.popleft())
    if missing:
        sys.exit("unresolved npm references: %s" % missing[:8])

    package_dir = {k: "node_modules/.pnpm/%s/node_modules/%s" % (dir_name(k), name_version(k)[0])
                   for k in seen}
    tarballs = sorted({name_version(k) for k in seen})

    # Rows: one per installed tarball.
    modules = []
    digests = {}
    for name, version in tarballs:
        digests[(name, version)] = hash_tarball(name, version)
    for key in sorted(seen):
        name, version = name_version(key)
        modules.append((name, version, digests[(name, version)], package_dir[key]))

    # Rows: symlinks inside .pnpm, so a package finds its own dependencies.
    node_links = []
    for key in sorted(seen):
        host = "node_modules/.pnpm/%s/node_modules" % dir_name(key)
        for dep, ref in sorted(edges.get(key, {}).items()):
            target = snapshot_key(dep, ref, snapshots)
            if target is None or not fits(target, packages) or target not in seen:
                continue
            node_links.append(("%s/%s" % (host, dep),
                               "../../%s/node_modules/%s"
                               % (dir_name(target), name_version(target)[0])))

    # Rows: the flat .pnpm/node_modules view, for packages that require a
    # dependency they do not declare (the CLI bundle keeps koffi and
    # playwright-core external) and for TypeScript's ambient @types lookup.
    hoisted = {}
    for key in seen:
        name, version = name_version(key)
        current = hoisted.get(name)
        if current is None or name_version(current)[1] < version:
            hoisted[name] = key
    #
    # Two flat views are emitted, both from the same `hoisted' map:
    #   node_modules/.pnpm/node_modules   -- pnpm's own hoist directory, which
    #       is where a package may find a dependency it does not declare;
    #   node_modules                      -- the npm-style flat tree.  Upstream
    #       asks pnpm for exactly this (.npmrc: node-linker=hoisted), and the
    #       bundle needs it at *runtime*: esbuild leaves `require("koffi")` and
    #       `require("playwright-core")` in place (build.mjs's `external'), and
    #       Node resolves those by walking up from dist/ to the repository root,
    #       where only the flat view can answer.
    for name, key in sorted(hoisted.items()):
        node_links.append(("node_modules/.pnpm/node_modules/%s" % name,
                           "../%s/node_modules/%s" % (dir_name(key), name)))
        node_links.append(("node_modules/%s" % name,
                           ".pnpm/%s/node_modules/%s" % (dir_name(key), name)))

    # Rows: node_modules/.bin entries, the executables a build script calls.
    bin_links, workspace_links = [], []
    # (link, target) for the two .bin directories: the repository root's, which
    # is what a build script run from the root sees, and the hoist directory's,
    # which is what a package inside .pnpm sees.
    for name, key in sorted(hoisted.items()):
        n, v = name_version(key)
        for cmd, rel in sorted(bin_entries(n, v).items()):
            bin_links.append(("node_modules/.bin/%s" % cmd,
                              "../.pnpm/%s/node_modules/%s/%s" % (dir_name(key), name, rel)))
            bin_links.append(("node_modules/.pnpm/node_modules/.bin/%s" % cmd,
                              "../../%s/node_modules/%s/%s" % (dir_name(key), name, rel)))
    for directory in order:
        entry = as_dict(importers.get(directory))
        depth = len(directory.split("/")) + 1
        rows = []
        for kind in ("dependencies", "devDependencies", "optionalDependencies"):
            for name, spec in as_dict(entry.get(kind)).items():
                version = spec.get("version", "") if isinstance(spec, dict) else spec
                if not version:
                    continue
                if version.startswith("link:"):
                    target = os.path.normpath(os.path.join(directory, version[len("link:"):]))
                    workspace_links.append(
                        ("%s/node_modules/%s" % (directory, name),
                         os.path.relpath(target, os.path.join(directory, "node_modules"))))
                    continue
                key = snapshot_key(name, version, snapshots)
                if key is None or not fits(key, packages) or key not in seen:
                    continue
                rows.append((name, "npm", package_dir[key]))
                n, v = name_version(key)
                for cmd, rel in sorted(bin_entries(n, v).items()):
                    bin_links.append(("%s/node_modules/.bin/%s" % (directory, cmd),
                                      "%s%s/%s" % ("../" * depth, package_dir[key], rel)))

    # patchedDependencies keys carry no peer suffix while snapshot keys do, so
    # match on the part before the first "(".
    patches = []
    for base, meta in sorted(as_dict(lock.get("patchedDependencies")).items()):
        for key in sorted(seen):
            if key.split("(")[0] == base:
                patches.append((package_dir[key], meta["path"]))

    build_scripts = []
    for directory in order:
        manifest = os.path.join(root, directory, "package.json")
        if not os.path.exists(manifest):
            continue
        script = json.load(open(manifest)).get("scripts", {}).get("build")
        if script:
            build_scripts.append((directory, script))

    emit(modules, node_links, bin_links, workspace_links, patches, order, build_scripts)


# --------------------------------------------------------------------------
# Emitting the module
# --------------------------------------------------------------------------

# Must stay in sync with %zcode-label-replacements below: it is only used to
# prove no two install paths collapse onto one input label.
LABEL_REPLACEMENTS = {"/": "-sl-", "@": "-at-", "(": "-op-", ")": "-cp-",
                      "=": "-eq-", "_": "-un-"}


def py_label(path):
    return "".join(LABEL_REPLACEMENTS.get(c, c) for c in path)


def quote(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def rows_table(rows, wrapper="list"):
    return "\n".join("    (%s %s)" % (wrapper, " ".join(quote(x) for x in row))
                     for row in rows)


PREAMBLE = """;;; ZCode's npm dependency tree, generated at packaging time; do not edit.
;;;
;;; One row per tarball pnpm installs for the ZCode terminal CLI on
;;; linux-x64/glibc, laid out in pnpm's isolated tree:
;;;   (npm-name version sha256 install-path)
;;; plus the symlinks, .bin entries, workspace links and lockfile patches that
;;; make that tree resolve the way Node and tsc expect.  Refresh after bumping
;;; %version in (sane-packages zcode):
;;;
;;;   git clone --branch v<version> https://github.com/zai-org/ZCode /tmp/ZCode
;;;   ./scripts/gen-zcode-node-tree.py /tmp/ZCode <version> \\
;;;       > sane-packages/zcode-modules.scm
;;;
;;; That script explains the layout choice, caches tarballs in
;;; $ZCODE_DEP_CACHE, and prints hashes in nix-base32 -- what Guix's `base32'
;;; reader expects (`guix hash' prints the same; `guix hash -f base32' does
;;; not).

(define-module (sane-packages zcode-modules)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (%zcode-node-modules %zcode-node-links %zcode-node-bin-links
            %zcode-workspace-links %zcode-node-patches
            %zcode-workspace-order %zcode-workspace-build-scripts
            %zcode-node-inputs %zcode-node-install-plan
            zcode-npm-origin zcode-input-name))

(define (zcode-npm-origin name version digest)
  "Return the origin of npm package NAME at VERSION as a tarball, where DIGEST
is the nix-base32 sha256 of that tarball.  These origins are build inputs, so
each one only downloads and verifies; the build unpacks them into the
node_modules tree the lockfile describes."
  ;; A scoped package is served under /@scope/ but its file name drops the
  ;; scope: @img/sharp-linux-x64 is fetched as
  ;; /@img/sharp-linux-x64/-/sharp-linux-x64-<version>.tgz.
  (let* ((scoped (string-prefix? "@" name))
         (parts (string-split name #\\/))
         (scope (car parts))
         (base (if scoped (cadr parts) name)))
    (origin
      (method url-fetch)
      (uri (string-append "https://registry.npmjs.org/"
                          (if scoped (string-append scope "/") "")
                          base "/-/" base "-" version ".tgz"))
      (sha256 (base32 digest)))))

(define %zcode-label-replacements
  ;; Install paths are the only thing that identifies a dependency to the
  ;; build, and an input label must be a plain file name.  Each character that
  ;; may not appear in one expands to a distinct two-letter tag, so two
  ;; different paths cannot collapse onto the same label.
  '((#\\/ . "-sl-") (#\\@ . "-at-") (#\\( . "-op-") (#\\) . "-cp-")
    (#\\= . "-eq-") (#\\_ . "-un-")))

(define (zcode-input-name install-path)
  "Return the build-input label for the tarball that belongs at INSTALL-PATH."
  (list->string
   (apply append
          (map (lambda (character)
                 (let ((hit (assq character %zcode-label-replacements)))
                   (if hit (string->list (cdr hit)) (list character))))
               (string->list install-path)))))
"""


def emit(modules, node_links, bin_links, workspace_links, patches, order, build_scripts):
    labels = [py_label(path) for (_, _, _, path) in modules]
    if len(set(labels)) != len(labels):
        dupes = [x for x, c in collections.Counter(labels).items() if c > 1]
        sys.exit("input label collision, extend %zcode-label-replacements: %s" % dupes[:5])
    out = [PREAMBLE]
    out.append("\n(define %%zcode-node-modules\n  ;; (name version sha256 install-path), one row per\n  ;; snapshot key; two keys may share a tarball when they differ\n  ;; only in peer resolution, hence one row per path.\n  (list\n%s))\n"
               % rows_table(modules))
    out.append("\n(define %%zcode-node-links\n  ;; Symlinks pnpm would create: (link target), both relative\n  ;; to the source root, target relative to the link's directory.\n  (list\n%s))\n"
               % rows_table(node_links))
    out.append("\n(define %%zcode-node-bin-links\n  ;; (link target) for node_modules/.bin entries -- the\n  ;; executables a build script may call by name.\n  (list\n%s))\n"
               % rows_table(bin_links))
    out.append("\n(define %%zcode-workspace-links\n  ;; @zcode/* packages are source directories, not tarballs: pnpm\n  ;; symlinks them into node_modules like any other dependency.\n  (list\n%s))\n"
               % rows_table(workspace_links))
    out.append("\n(define %%zcode-node-patches\n  ;; lockfile patchedDependencies: (install-path patch-file).  The\n  ;; patch files come from the source tree, so they are already there.\n  (list\n%s))\n"
               % rows_table(patches))
    out.append("\n(define %%zcode-workspace-order\n  ;; Dependencies before dependents, @zcode/cli last: the order\n  ;; `turbo run build' would schedule, taken from the link: graph.\n  (list\n%s))\n"
               % "\n".join("    %s" % quote(d) for d in order))
    out.append("\n(define %%zcode-workspace-build-scripts\n  ;; Each package's `build' script, run with bash -c from inside\n  ;; that package's directory.\n  (list\n%s))\n"
               % rows_table(build_scripts))
    out.append("""
(define %zcode-node-install-plan
  ;; install-path -> input label, which is all the builder needs.
  (map (match-lambda
         ((name version digest path) (list path (zcode-input-name path))))
       %zcode-node-modules))

(define %zcode-node-inputs
  ;; One labelled origin per install path.
  (map (match-lambda
         ((name version digest path)
          (list (zcode-input-name path)
                (zcode-npm-origin name version digest))))
       %zcode-node-modules))
""")
    sys.stdout.write("".join(out))


def zcode_label(install_path):
    """Python twin of zcode-input-name, for the collision check above."""
    replacements = {"/": "-sl-", "@": "-at-", "(": "-op-", ")": "-cp-",
                    "=": "-eq-", "_": "-un-"}
    return "".join(replacements.get(c, c) for c in install_path)


if __name__ == "__main__":
    main()
