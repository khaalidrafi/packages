;;; sane-packages --- devin: the Devin CLI from Cognition, vendor binary.
;;; Commentary:
;;;
;;; Cognition distributes the Devin CLI as the npm package `devin'.  The
;;; package's main entry `bin/devin.js' is only a 3 KB Node launcher stub
;;; whose job is to find and exec the platform binary; the real program is
;;; the same package's platform release -- version `3000.11.228-linux-x64'
;;; -- whose tarball carries the 217 MB Bun-compiled `bin/devin' together
;;; with `share/devin/docs'.  (Two facts in the dispatch that asked for
;;; this package were measured wrong on 2026-10-30 and are corrected here
;;; and on the board: the main tarball contains no binary at all, and the
;;; platform binary is NOT cline-bin's shape.  The platform tarball also
;;; ships a 3-byte `distribution' file containing the text `npm' --
;;; upstream packaging cruft; it rides along under lib/devin, harmless.)
;;;
;;; The platform binary is a STATIC-PIE ELF: `file' reports
;;; `ELF 64-bit LSB pie executable, static-pie linked, stripped', and it
;;; has no PT_INTERP at all.  cline-bin's Bun payload is dynamically
;;; linked and needs patchelf --set-interpreter plus an LD_LIBRARY_PATH
;;; wrapper; this one maps itself and runs directly, so this module needs
;;; no patchelf, no glibc input and no loader dance.  Consequence of the
;;; stripping: the embedded Bun version is not readable, so whether the
;;; payload runs on the Owner's no-AVX2 Celeron can only be proven there
;;; (`guix install devin-bin && devin --version') -- the build sandbox
;;; and the CI runners both have AVX2 and prove nothing in that
;;; direction.
;;;
;;; The build refuses to lie about what it installed: the check-version
;;; phase is FATAL unless `devin --version' answers exactly the pinned
;;; version.  Measured behaviour of this exact pin (2026-10-30, sandbox):
;;; stdout is the single line `devin 3000.11.228 (053434014dbd)', stderr
;;; is empty, exit status 0.  The comparison takes the second
;;; whitespace-separated token of stdout, the same token a user reads.
;;;
;;; NO CREDENTIALS: nothing in this package, its build or its smoke
;;; authenticates, stores tokens, or touches `devin auth'; credential
;;; material lives outside this channel (vault secrets/DEVIN_API_KEY).
;;;
;;; Code:

(define-module (sane-packages devin)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages bash))

(define %devin-version
  "3000.11.228")

(define %devin-source
  (origin
    (method url-fetch)
    ;; Not the version in (name "devin"): the payload is the platform
    ;; release of the same package name, whose version string carries the
    ;; platform suffix and whose tarball name therefore does too.
    (uri (string-append "https://registry.npmjs.org/devin/-/devin-"
                        %devin-version "-linux-x64.tgz"))
    (sha256 (base32 "1lnjkspfscykx1j18avb7q1pjl15cl1qlcvm87ph76ymxmj1w4in"))))

(define-public devin-bin
  (package
    (name "devin-bin")
    (version %devin-version)
    (source
     %devin-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      ;; Static-pie: there is no interpreter for a validator to resolve
      ;; and no runpath to rewrite; and strip must not touch the Bun
      ;; payload appended to the ELF image (the cline-bin lesson).
      #:validate-runpath? #f
      #:strip-binaries? #f
      ;; The binary reads `share/devin/docs' relative to itself, so the
      ;; whole payload stays side by side under one directory, exactly
      ;; as cline-bin keeps `cline-hub/' next to its binary.
      #:install-plan
      #~'(("." "lib/devin"))
      #:phases
      #~(begin
          (use-modules (srfi srfi-1)
                       (guix build utils)
                       (ice-9 popen)
                       (ice-9 rdelim))
          (modify-phases %standard-phases
            (add-after 'install 'make-wrapper
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref outputs "out"))
                       (bash (assoc-ref inputs "bash-minimal"))
                       (payload (string-append out "/lib/devin/bin/devin")))
                  ;; A script, not a symlink: a symlink cannot add
                  ;; arguments, and the day this wrapper needs a flag
                  ;; (autoclaw-bin's --disable-gpu is the precedent), the
                  ;; insertion point must already exist.  The payload
                  ;; needs no loader and no library path -- only exec.
                  (mkdir-p (string-append out "/bin"))
                  (call-with-output-file (string-append out "/bin/devin")
                    (lambda (port)
                      (format port "#!~a/bin/bash\nexec ~a \"$@\"\n" bash
                              payload)))
                  (chmod (string-append out "/bin/devin") #o555))))
            (add-after 'make-wrapper 'check-version
              (lambda* (#:key outputs #:allow-other-keys)
                ;; FATAL: the build dies unless the installed command
                ;; answers the pinned version.  A wrong-binary output can
                ;; never silently pass: status must be 0, stdout must
                ;; carry the expected version as its second token.
                (let* ((devin (string-append (assoc-ref outputs "out")
                                             "/bin/devin"))
                       (expected #$%devin-version)
                       (port (open-pipe* OPEN_READ devin "--version"))
                       (line (read-line port))
                       (status (close-pipe port))
                       (tokens (if (string? line)
                                   (filter (lambda (t)
                                             (not (string-null? t)))
                                           (string-split line #\space))
                                   '())))
                  (unless (and (zero? status)
                               (>= (length tokens) 2)
                               (string=? (cadr tokens) expected))
                    (error
                     "devin --version does not answer the pinned version"
                     (list 'exit
                           status
                           'stdout
                           line
                           'expected
                           expected)))
                  (format #t "devin --version answered: ~a~%" line))))))))
    (inputs (list bash-minimal))
    (home-page "https://devin.ai")
    (synopsis "Autonomous software engineer CLI (prebuilt)")
    (description
     "Devin is Cognition's autonomous software engineer: a terminal agent
that reads a codebase, plans, edits files, runs commands and reports back.
This package installs the upstream-published prebuilt Linux x86_64 binary
from the @code{devin} npm package's @code{linux-x64} platform release,
together with the @code{share/devin/docs} tree the binary reads relative to
itself.  The binary is a static-pie ELF, so unlike @code{cline-bin} it needs
no interpreter patch or loader wrapper: @code{bin/devin} is a small script
that execs the payload directly.  The build fails loudly whenever
@code{devin --version} does not answer the pinned version.  No credential
material is involved anywhere in the package or its build.")
    (license (license:non-copyleft "https://cognition.ai/terms-of-service"
              "Proprietary Cognition license — unfree, non-redistributable."))))

;;; devin.scm ends here
