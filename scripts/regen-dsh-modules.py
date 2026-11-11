#!/usr/bin/env python3
"""Regenerate sensible-packages/dsh-modules.scm from the npm registry.

This automates exactly the route documented in that file's header: extract
the @deepseek-ai/dsh tarball for the given version, run

    npm install --package-lock-only --ignore-scripts --no-audit --no-fund

inside it, keep the packages whose os/cpu/libc fields still match
linux-x64/glibc, hash every remaining registry tarball (sha256, printed in
nix-base32 -- the encoding Guix's `base32' reader expects, the same one
`guix hash -f nix-base32' prints), and emit one row per package at the
install path the lockfile names, plus the node_modules/.bin links npm would
create.  Usage:

    ./scripts/regen-dsh-modules.py <dsh-version> [output.scm]

Output defaults to sensible-packages/dsh-modules.scm.  Tarballs are cached under
$DSH_DEP_CACHE (default /tmp/dshdep) keyed by name@version, so bumping dsh
only costs the tarballs that actually changed.
"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile

TARGET_OS, TARGET_CPU, TARGET_LIBC = "linux", "x64", "glibc"
CACHE = os.environ.get("DSH_DEP_CACHE", "/tmp/dshdep")
NIX32 = "0123456789abcdfghijklmnpqrsvwxyz"

HEADER = ''';;; dsh's npm dependency tree, generated at packaging time; do not edit.
;;;
;;; One row per tarball npm installs for @deepseek-ai/dsh on linux-x64:
;;;   (npm-name version sha256 install-path)
;;; INSTALL-PATH is relative to the package directory and is also where npm
;;; would unpack it, nested node_modules included.  To refresh this file after
;;; bumping dsh: extract the new tarball, run
;;;   npm install --package-lock-only --ignore-scripts --no-audit --no-fund
;;; in it, keep the packages whose os/cpu/libc fields still match linux-x64,
;;; hash every remaining registry tarball with `guix hash -f nix-base32', and
;;; emit one row per package at the install path the lockfile names.

(define-module (sensible-packages dsh-modules)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix base32)
  #:use-module (ice-9 match)
  #:export (%dsh-node-modules %dsh-node-bin-links %dsh-node-inputs
            %dsh-node-install-plan dsh-npm-origin dsh-input-name))

(define (dsh-npm-origin name version digest)
  "Return the origin of npm package NAME at VERSION as a tarball, where
DIGEST is the base-32 sha256 of the tarball.

These origins are used as build inputs, so each one only downloads and
verifies; the dsh build unpacks them into its node_modules tree."
  ;; Scoped packages live under /@scope/ but their file name drops the scope:
  ;; @img/sharp-linux-x64 is served as /@img/sharp-linux-x64/-/sharp-....tgz.
  (let* ((parts (string-split name #\\/))
         (scoped (string-prefix? "@" name))
         (scope (and scoped (car parts)))
         (base (if scoped (cadr parts) name)))
    (origin
      (method url-fetch)
      (uri (string-append "https://registry.npmjs.org/"
                          (if scoped (string-append scope "/") "")
                          base "/-/" base "-" version ".tgz"))
      (sha256 (base32 digest)))))

(define (dsh-input-name install-path)
  "Return the build-input name under which the tarball that belongs at
INSTALL-PATH is handed to the build.  Install paths are unique, so sanitising
one identifies the dependency it holds: \\"node_modules/@img/sharp-linux-x64\\"
becomes \\"node-modules-img-sharp-linux-x64\\"."
  (list->string
   (map (lambda (c) (if (or (char=? c #\\/) (char=? c #\\@) (char=? c #\\_))
                        #\\-
                        c))
        (string->list install-path))))
'''

FOOTER = '''
(define %dsh-node-bin-links
  ;; (link target), both relative to the package directory, as npm
  ;; creates them in each node_modules/.bin.
  (list
@BODY@))

;; What the dsh package hands to its build: one download derivation per
;; tarball, named after the path it belongs at, and the name/path pairs that
;; tell the build where to unpack each one.
(define %dsh-node-inputs
  (map (lambda (spec)
         (match spec
           ((name version digest path)
            (cons (dsh-input-name path)
                  (dsh-npm-origin name version digest)))))
       %dsh-node-modules))

(define %dsh-node-install-plan
  (map (lambda (spec)
         (match spec
           ((_ _ _ path) (cons (dsh-input-name path) path))))
       %dsh-node-modules))
'''


def die(msg):
    sys.exit("regen-dsh-modules: %s" % msg)


def nix_base32(hexdigest):
    """sha256 hex -> nix-base32 (guix hash -f nix-base32)."""
    n = 0
    for b in reversed(bytes.fromhex(hexdigest)):
        n = (n << 8) | b
    out = ""
    while n > 0:
        out = NIX32[n & 31] + out
        n >>= 5
    return out.rjust(52, "0")


def fetch(url, dest):
    if os.path.exists(dest):
        return dest
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".part"
    with open(tmp, "wb") as f:
        subprocess.run(["curl", "-fsSL", url], stdout=f, check=True)
    os.rename(tmp, dest)
    return dest


def tarball_facts(name, version, url):
    """(nix-base32 sha256, bin field) of the registry tarball, cached.

    The `bin' field comes from the tarball's own package.json rather than
    the lockfile: npm only records it there for some packages, while every
    package npm links into node_modules/.bin is in the tarball by
    construction."""
    path = fetch(url, os.path.join(CACHE, "%s-%s.tgz" % (name.replace("/", "-"),
                                                         version)))
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    bin_field = None
    with tarfile.open(path) as tar:
        # npm tarballs root at package/, but a few (some @types stubs) root
        # at the package name instead; either way package.json sits directly
        # under that single top-level directory.
        member = None
        for m in tar.getmembers():
            parts = m.name.lstrip("./").split("/")
            if len(parts) == 2 and parts[1] == "package.json":
                member = m
                break
        if member is None:
            die("%s@%s: tarball has no package.json" % (name, version))
        meta = json.load(tar.extractfile(member))
        bin_field = meta.get("bin")
    return nix_base32(h.hexdigest()), bin_field


def platform_ok(field, want):
    """npm os/cpu semantics: a '!' entry makes the list a blocklist."""
    if not field:
        return True
    negated = [x[1:] for x in field if x.startswith("!")]
    if negated:
        return want not in negated
    return want in field


def name_from_path(path):
    """node_modules/@scope/name (nested) -> @scope/name / name."""
    parts = path.split("/")
    i = len(parts) - 1 - parts[::-1].index("node_modules")
    rest = parts[i + 1:]
    return "/".join(rest) if rest[0].startswith("@") else rest[0]


def make_lockfile(version, workdir):
    """Extract the dsh tarball and run the documented npm command in it."""
    url = ("https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-%s.tgz"
           % version)
    tgz = fetch(url, os.path.join(CACHE, "dsh-%s.tgz" % version))
    pkg = os.path.join(workdir, "package")
    with tarfile.open(tgz) as tar:
        tar.extractall(workdir, filter="data")  # single package/ directory
    if not os.path.isfile(os.path.join(pkg, "package.json")):
        die("tarball for %s has no package/package.json" % version)
    env = dict(os.environ, HOME=workdir, npm_config_progress="false")
    subprocess.run(["npm", "install", "--package-lock-only",
                    "--ignore-scripts", "--no-audit", "--no-fund"],
                   cwd=pkg, env=env, check=True,
                   stdout=subprocess.DEVNULL)
    return os.path.join(pkg, "package-lock.json")


def collect(lock_path):
    """Rows (name, version, digest, install-path) and .bin links from the
    lockfile, filtered for linux-x64/glibc exactly as `npm install' would."""
    with open(lock_path) as f:
        lock = json.load(f)
    if lock.get("lockfileVersion") != 3:
        die("lockfileVersion %s, not 3 (npm too old?)"
            % lock.get("lockfileVersion"))
    rows, links = [], []
    for path, entry in lock["packages"].items():
        if path == "" or entry.get("link"):
            continue  # the dsh tarball itself; workspace links
        if entry.get("dev"):
            # Reachable only through devDependencies: not part of what
            # `npm install --omit=dev' (the runtime closure this table
            # reproduces) would lay down.
            continue
        if not (platform_ok(entry.get("os"), TARGET_OS)
                and platform_ok(entry.get("cpu"), TARGET_CPU)
                and platform_ok(entry.get("libc"), TARGET_LIBC)):
            continue
        name = entry.get("name") or name_from_path(path)
        version = entry["version"]
        resolved = entry["resolved"]
        if not resolved.endswith(".tgz"):
            die("%s@%s: not a registry tarball: %s" % (name, version, resolved))
        digest, bin_field = tarball_facts(name, version, resolved)
        rows.append((name, version, digest, path))
        if bin_field:
            bins = ({name.rsplit("/", 1)[-1]: bin_field}
                    if isinstance(bin_field, str) else bin_field)
            # The .bin lives in the node_modules directory that CONTAINS the
            # package: top-level for a hoisted package, the nested one for a
            # nested package -- dirname(path) would put a scoped package's
            # link inside its own scope directory.
            cut = path.rfind("node_modules") + len("node_modules")
            bindir = path[:cut] + "/.bin"
            for bin_name, bin_file in bins.items():
                target = os.path.relpath(os.path.join(path, bin_file),
                                         bindir)
                links.append((os.path.join(bindir, bin_name), target))
    rows.sort(key=lambda r: r[3])
    links.sort()
    if not rows:
        die("no packages kept from the lockfile")
    seen = [r[3] for r in rows]
    if len(set(seen)) != len(seen):
        die("duplicate install paths in lockfile")
    return rows, links


def emit(rows, links):
    out = [HEADER, "\n(define %dsh-node-modules\n  (list\n"]
    for name, version, digest, path in rows:
        out.append('   (list "%s" "%s"\n         "%s"\n         "%s")\n'
                   % (name, version, digest, path))
    out.append("))\n")
    body = "".join('   (list "%s" "%s")\n' % pair for pair in links)
    out.append(FOOTER.replace("@BODY@", body))
    return "".join(out)


def main():
    if len(sys.argv) < 2:
        die("usage: regen-dsh-modules.py <dsh-version> [output.scm]")
    version, out_path = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2
                                      else "sensible-packages/dsh-modules.scm")
    with tempfile.TemporaryDirectory(prefix="dsh-regen-") as workdir:
        lock = make_lockfile(version, workdir)
        rows, links = collect(lock)
    with open(out_path, "w") as f:
        f.write(emit(rows, links))
    print("wrote %s: %d tarballs, %d bin links" % (out_path, len(rows),
                                                   len(links)))


if __name__ == "__main__":
    main()
