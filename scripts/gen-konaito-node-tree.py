#!/usr/bin/env python3
"""Regenerate sane-packages/konaito-modules.scm from the npm registry.

Why this exists: @konaito/terminal-browser ships as an npm tarball of plain
ESM (no bundle), so `guix build konaito-terminal-browser' has to give Node a
node_modules tree without running npm.  Every dependency arrives as its own
hash-verified origin instead; this script computes that table.  Run it after
bumping %konaito-version in (sane-packages konaito):

    ./scripts/gen-konaito-node-tree.py > sane-packages/konaito-modules.scm

The graph source is the registry itself, not a lockfile: upstream's bun.lock
is a development lock (typescript and bun-types in it) that the published
tarball does not carry, and the runtime tree it pins for puppeteer is
reproducible from the manifests alone.  Each `dependencies' range is resolved
the way npm resolves it -- the newest version satisfying the range -- and
devDependencies / peerDependencies / optionalDependencies are ignored, which
is exactly what `npm install --omit=dev' would install.

Layout: npm's flat node_modules.  The tree this produces has no name
conflicts (checked on every run: a conflict would need nesting, which the
emitted table cannot express), so one directory per package under
node_modules/ resolves every bare specifier.  Scoped packages install at
node_modules/@scope/name like npm does.

Tarballs are downloaded into (and reused from) $KONAITO_DEP_CACHE, so a
version bump only re-hashes what changed.  Nothing here builds anything or
runs any npm script: the script only fetches tarballs to hash them.
"""

import hashlib
import json
import os
import re
import sys
import urllib.request

NPM = "https://registry.npmjs.org"
CACHE = os.environ.get("KONAITO_DEP_CACHE", "/tmp/konaito-deps")
APP = "@konaito/terminal-browser"
VERSION = sys.argv[1] if len(sys.argv) > 1 else "0.1.0"

# nix base32 alphabet (guix/base32.scm %nix-base32-chars)
NIX32 = "0123456789abcdfghijklmnpqrsvwxyz"


def nix_base32(digest):
    """Guix's `base32' reader expects this encoding, not RFC 4648: the digest
    is written as 5-bit groups counted from the least significant bit of the
    last byte, most significant group first.  Same as `guix hash'."""
    bits = int.from_bytes(digest, "little")
    return "".join(NIX32[(bits >> i) & 0x1F] for i in range(255, -1, -5))


def get(url):
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def manifest(name, version):
    """The registry document of NAME at exactly VERSION, cached on disk."""
    os.makedirs(CACHE, exist_ok=True)
    import zlib

    key = zlib.crc32(f"{name}@{version}".encode())
    cache = os.path.join(CACHE, f"{key:x}-{version}.json")
    if not os.path.exists(cache):
        doc = json.loads(get(f"{NPM}/{name}/{version}"))
        with open(cache, "w") as port:
            json.dump(doc, port)
    return json.load(open(cache))


def satisfies(version, rng):
    """Whether VERSION satisfies an npm range of the shapes this tree uses:
    exact, ^, ~, and x-ranges ('1', '1.2').  Anything else is an error --
    silently guessing a resolution would defeat the whole point of a table of
    hashes."""
    m = re.match(r"^(\^|~)?(\d+)(?:\.(\d+))?(?:\.(\d+))?$", rng)
    if rng == "*":
        # Used by @types/* packages for their @types/node sibling; npm reads
        # it as "any version" and installs the newest.
        return True
    if not m:
        raise SystemExit(f"unhandled range {rng}")
    mod = m.group(1) or ""
    maj, mi, pa = m.group(2), m.group(3), m.group(4)
    M, m_, p_ = (int(x) for x in version.split("."))
    if not mod:
        if mi is None:
            return M == int(maj)
        if pa is None:
            return (M, m_) == (int(maj), int(mi))
        return (M, m_, p_) == (int(maj), int(mi), int(pa))
    if mi is None:  # ^1 / ~1: any 1.x
        return M == int(maj)
    if mod == "~":
        return M == int(maj) and m_ == int(mi) and (pa is None or p_ >= int(pa))
    # ^1.2.3, with the ^0 special case
    if int(maj) == 0:
        return M == 0 and m_ == int(mi) and p_ >= int(pa or 0)
    return M == int(maj) and (M, m_, p_) >= (int(maj), int(mi), int(pa or 0))


def resolve(name, rng):
    """Newest version of NAME satisfying RNG."""
    versions = json.loads(get(f"{NPM}/{name}"))["versions"]
    ok = [v for v in versions
          if re.match(r"^\d+\.\d+\.\d+$", v) and satisfies(v, rng)]
    if not ok:
        raise SystemExit(f"no version of {name} satisfies {rng}")
    return ok[-1]


def tarball_url(name, version):
    scoped = name.startswith("@")
    base = name.split("/")[-1]
    scope = name.split("/")[0] if scoped else None
    return (f"{NPM}/{scope}/{base}/-/{base}-{version}.tgz"
            if scoped else f"{NPM}/{name}/-/{name}-{version}.tgz")


def hash_tarball(name, version):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{name.lstrip('@').replace('/', '+')}"
                                 f"-{version}.tgz")
    if not os.path.exists(path):
        with open(path + ".part", "wb") as port:
            port.write(get(tarball_url(name, version)))
        os.replace(path + ".part", path)
    with open(path, "rb") as handle:
        return nix_base32(hashlib.sha256(handle.read()).digest())


def walk(rows, seen, name, rng):
    """Depth-first walk of the runtime graph; one row per (name, version)."""
    try:
        version = resolve(name, rng)
    except SystemExit as e:
        raise SystemExit(f"{name} (needed by {walk.parent}): {e}")
    parent = walk.parent
    walk.parent = name
    if (name, version) in seen:
        walk.parent = parent
        return
    seen.add((name, version))
    rows.append((name, version, hash_tarball(name, version)))
    deps = manifest(name, version).get("dependencies", {})
    for dep, r in sorted(deps.items()):
        walk(rows, seen, dep, r)
    walk.parent = parent


walk.parent = APP


def main():
    rows, seen = [], set()
    walk(rows, seen, APP, VERSION)
    # The application tarball itself is the package's #:source, not a row.
    rows = [r for r in rows if r[0] != APP]

    byname = {}
    for name, version, digest in rows:
        byname.setdefault(name, set()).add(version)
    conflicts = {n: v for n, v in byname.items() if len(v) > 1}
    if conflicts:
        raise SystemExit(f"version conflicts need a nested layout: {conflicts}")

    rows.sort()
    print(f""";;; @konaito/terminal-browser's npm dependency tree, generated at
;;; packaging time; do not edit.
;;;
;;; One row per tarball the CLI's own dependencies need at run time:
;;;   (npm-name version sha256)
;;; laid out flat under node_modules/, which is npm's own layout and resolves
;;; every bare specifier because the tree has no version conflicts (the
;;; generator refuses to emit a table otherwise).  Refresh after bumping
;;; %konaito-version in (sane-packages konaito):
;;;
;;;   ./scripts/gen-konaito-node-tree.py <version> \\
;;;       > sane-packages/konaito-modules.scm
;;;
;;; The generator resolves every `dependencies' range the way npm would,
;;; ignores dev/peer/optional dependencies, downloads each tarball once into
;;; $KONAITO_DEP_CACHE to hash it, and prints nix-base32 sha256s -- what
;;; Guix's `base32' reader expects.

(define-module (sane-packages konaito-modules)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (ice-9 match)
  #:export (%konaito-node-modules %konaito-node-install-plan
            %konaito-node-inputs konaito-input-name))

(define (konaito-npm-origin name version digest)
  \"Return the origin of npm package NAME at VERSION as a tarball, where DIGEST
is the nix-base32 sha256 of that tarball.  These origins are build inputs, so
each one only downloads and verifies; the build unpacks them into the flat
node_modules tree.  A scoped package is served under /@scope/ but its file
name drops the scope: @puppeteer/browsers is fetched as
/@puppeteer/browsers/-/browsers-<version>.tgz.\"
  (let* ((scoped (string-prefix? \"@\" name))
         (parts (string-split name #\\/))
         (scope (car parts))
         (base (if scoped (cadr parts) name)))
    (origin
      (method url-fetch)
      (uri (string-append \"https://registry.npmjs.org/\"
                          (if scoped (string-append scope \"/\") \"\")
                          base \"/-/\" base \"-\" version \".tgz\"))
      (sha256 (base32 digest)))))

(define %konaito-label-replacements
  ;; npm names may contain characters an input label cannot: '/' separates
  ;; the label from the derivation path and '@' has meaning in labels.  Each
  ;; such character expands to a distinct two-letter tag, so two different
  ;; names cannot collapse onto the same label.  Same table zcode uses.
  '((#\\/ . \"-sl-\") (#\\@ . \"-at-\")))

(define (konaito-input-name name)
  \"Return the build-input label for the tarball that belongs at
node_modules/NAME.\"
  (list->string
   (apply append
          (map (lambda (character)
                 (let ((hit (assq character %konaito-label-replacements)))
                   (if hit (string->list (cdr hit)) (list character))))
               (string->list name)))))

(define %konaito-node-modules
  ;; (name version sha256), one row per runtime dependency, sorted by name.
  (list""")
    for name, version, digest in rows:
        print(f'    (list "{name}" "{version}" "{digest}")')
    print("""    ))

(define %konaito-node-install-plan
  ;; npm name -> input label, which is all the builder needs: it unpacks the
  ;; label's tarball into node_modules/<name>.
  (map (match-lambda
         ((name version digest) (list name (konaito-input-name name))))
       %konaito-node-modules))

(define %konaito-node-inputs
  ;; One labelled origin per npm tarball.
  (map (match-lambda
         ((name version digest)
          (list (konaito-input-name name)
                (konaito-npm-origin name version digest))))
       %konaito-node-modules))""")


if __name__ == "__main__":
    main()
