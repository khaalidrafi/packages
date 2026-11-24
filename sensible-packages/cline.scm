;;; sensible-packages --- cline: the Cline CLI from upstream's npm build.
;;; Commentary:
;;;
;;; Cline's published CLI (@cline/cli-linux-x64) is a single-file executable
;;; produced by `bun build --compile', which embeds the Bun runtime.  Bun's
;;; default x86_64 build uses AVX2, so such a binary raises SIGILL on any CPU
;;; older than Intel Haswell (upstream issue #11539) -- and this channel's
;;; target machine is a pre-Haswell Celeron, which is why the channel watched
;;; that issue at all.  The published payload turned out not to be an AVX2
;;; build, though: it starts and serves its hub on exactly that Celeron, so
;;; the npm prebuilt is what this module ships, as cline-bin.
;;;
;;; History, so nobody rebuilds the mistake: this module used to carry
;;; cline-baseline, which compiled Cline from the cli-v<version> tag with
;;; Bun's `bun-linux-x64-baseline' target (upstream publishes no baseline
;;; artifact) inside one fixed-output derivation -- a network build whose
;;; output hash moved with every Bun bump, which made it the channel's most
;;; expensive package to keep current, all to deliver a binary the npm
;;; package already provides.  It was deprecated on 2026-11-24: the build is
;;; deleted, and the name remains only as a deprecated-package alias of
;;; cline-bin (see the note at the bottom of this file).

(define-module (sensible-packages cline)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages base) ;glibc
  #:use-module (gnu packages bash) ;bash-minimal
  #:use-module (gnu packages compression) ;zlib
  #:use-module (gnu packages elf) ;patchelf
  #:use-module (gnu packages gcc))

;;; The npm prebuilt
;;;
;;; Upstream publishes the CLI as a platform npm package,
;;; @cline/cli-linux-x64, whose payload is a Bun-compiled binary -- plus the
;;; cline-hub webview tree the hub serves.  That is a vendor binary: cheap to
;;; build (download + repack) and cheap to test, and it is what this module
;;; ships as cline-bin.  Empirically it runs on this pre-Haswell Celeron
;;; (--version, --help, hub status/stop verified), so the payload was not
;;; compiled for Bun's AVX2 target -- the finding that retired the from-source
;;; baseline build this module used to carry (see the deprecation note at the
;;; bottom).  Only the presumption that the published binary needs AVX2 ever
;;; justified compiling a baseline one here.
;;;
;;; The binary is a Bun ELF carrying PT_INTERP /lib64/ld-linux-x86-64.so.2, a
;;; path that does not exist in Guix -- direct exec answers ENOENT on the
;;; target (the same failure the retired source build's CI smoke test hit).
;;; The wrapper therefore execs it through the store glibc loader, as every
;;; Bun binary in this channel does.

(define %cline-bin-version
  "3.0.74")

(define %cline-bin-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://registry.npmjs.org/@cline/cli-linux-x64/-/cli-linux-x64-"
          %cline-bin-version ".tgz"))
    (sha256 (base32 "1z0v4431sxi99qdldmfijj66av8i67mz53f3aq8lb2npm0w28l2j"))))

(define-public cline-bin
  (package
    (name "cline-bin")
    (version %cline-bin-version)
    (source
     %cline-bin-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      ;; The Bun ELF carries its JavaScript payload appended to the ELF
      ;; image: strip and the runpath validator both touch (or reject) it.
      ;; The interpreter is patched by hand below.
      #:validate-runpath? #f
      #:strip-binaries? #f
      ;; The npm tarball's single top-level directory is `package/', and the
      ;; binary finds cline-hub/ relative to itself, so the whole payload is
      ;; kept side by side under one directory.
      #:install-plan
      #~'(("." "lib/cline"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-elf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (binary (string-append out "/lib/cline/bin/cline"))
                     (patchelf (string-append (assoc-ref inputs "patchelf")
                                              "/bin/patchelf"))
                     (loader (string-append (assoc-ref inputs "glibc")
                                            "/lib/ld-linux-x86-64.so.2"))
                     (lib-path (string-append (assoc-ref inputs "gcc") "/lib"
                                              ":"
                                              (assoc-ref inputs "zlib") "/lib"))
                     (bash (assoc-ref inputs "bash-minimal")))
                ;; Only the interpreter, and never --set-rpath: rewriting
                ;; the Bun executable's dynamic section corrupts the payload
                ;; appended to it (verified: a patchelf run that also sets
                ;; the rpath segfaults at startup).
                (invoke patchelf "--set-interpreter" loader binary)
                ;; The hub daemon re-executes process.execPath, so the
                ;; binary must be the process image.  Executing it through
                ;; `ld-linux --library-path' instead makes the loader the
                ;; executable and `hub start' then dies with an unknown
                ;; --cline-hub-daemon option.
                (mkdir-p (string-append out "/bin"))
                (call-with-output-file (string-append out "/bin/cline")
                  (lambda (port)
                    (format port
                     "#!~a/bin/bash
export LD_LIBRARY_PATH=~a${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
exec ~a \"$@\"
"
                     bash lib-path binary)))
                (chmod (string-append out "/bin/cline") #o555)))))))
    (native-inputs (list patchelf))
    (inputs (list bash-minimal glibc
                  (list gcc "lib") zlib))
    (home-page "https://cline.bot")
    (synopsis "Autonomous coding agent CLI (prebuilt)")
    (description
     "Cline is an autonomous coding agent for the terminal: it can read and
edit files, run commands, and use a browser.  This package installs the
upstream-published prebuilt Linux x86_64 binary from the @code{@cline/cli-linux-x64}
npm package, with its ELF interpreter patched for the Guix store.  The name
@code{cline-baseline} -- this channel's former from-source build for CPUs
without AVX2 -- is a deprecated alias of this package, so either name installs
the command @code{cline}.")
    (license license:asl2.0)))

;;; cline-baseline is deprecated, superseded by cline-bin.  The package used
;;; to compile Cline from the cli-v<version> tag with Bun's baseline
;;; (no-AVX2) target inside one fixed-output derivation -- upstream publishes
;;; no baseline artifact, so this channel built its own -- and that FoD was
;;; the channel's most expensive package to keep current: its output hash
;;; moved with every Bun bump and could only be re-captured by a one-time
;;; network build.  The npm payload turned out to run on the pre-Haswell
;;; Celeron this channel targets, so the build was retired rather than
;;; maintained.  The name keeps the manual's Deprecation Policy shape -- a
;;; resolvable alias that warns and installs its replacement, the
;;; go-ipfs -> kubo pattern and this channel's opencode-bin -> opencode2-bin
;;; precedent -- spelled as define-public + deprecated-package rather than the
;;; manual's define-deprecated-package macro so tests/check-static.sh keeps
;;; harvesting, and dry-run checking, the name.  deprecated-package sets the
;;; 'superseded property; keep the alias at least a year, and take its
;;; eventual removal through a news entry.
(define-public cline-baseline
  (deprecated-package "cline-baseline" cline-bin))

;;; cline.scm ends here
