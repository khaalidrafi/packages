;;; sane-packages --- lightpanda: a headless browser written from scratch
;;; in Zig, for AI agents and automation.
;;; Commentary:
;;;
;;; Lightpanda (https://lightpanda.io) is a new browser, not a Chromium
;;; fork: written in Zig with its own JavaScript engine, it serves CDP for
;;; Puppeteer, Playwright and friends, and its `fetch' CLI renders a URL to
;;; html, markdown, a PNG or a PDF without a display.  Upstream is AGPL-3.0
;;; and publishes, per release, a bare ELF and a .deb per architecture;
;;; the .deb is the artifact packaged here, the way zcode-bin repackages
;;; Z.ai's own .deb, because the .deb carries the stripped binary and the
;;; bare ELF does not (1.0.1: a 73 MB stripped binary inside a 19 MB .deb
;;; against a 75 MB unstripped ELF).
;;;
;;; The binary is a single stripped ELF whose only NEEDED entries are
;;; glibc's: libc, libm and the loader.  patchelf rewrites the interpreter
;;; and stops there -- the same treatment opencode2-bin gives its
;;; single-executables -- because an rpath naming nothing but the payload
;;; would resolve no soname the store loader does not already find in its
;;; own glibc output, and the patched binary then runs on any system with
;;; this channel.
;;;
;;; Code:

(define-module (sane-packages lightpanda)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf))

(define %lightpanda-version
  ;; The .deb's binary reports this with `lightpanda version'.
  "1.0.1")

(define %lightpanda-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/lightpanda-io/browser/releases/download/"
          %lightpanda-version "/lightpanda_" %lightpanda-version "_amd64.deb"))
    (sha256 (base32 "1n2vfpfc7za93xlmq7k94zaf21b086namik18cg11yqcjmg30sn6"))))

(define-public lightpanda-bin
  (package
    (name "lightpanda-bin")
    (version %lightpanda-version)
    (source
     %lightpanda-source)
    (build-system copy-build-system)
    ;; Upstream publishes x86_64 and aarch64 .debs; only the x86_64 one is
    ;; packaged, mirroring every other vendor binary here.
    (supported-systems '("x86_64-linux"))
    (native-inputs (list libarchive patchelf))
    (arguments
     (list
      #:validate-runpath? #f ;vendor ELF: interpreter-only patching below
      #:strip-binaries? #f ;upstream ships it stripped already
      ;; The .deb's own layout: usr/bin/lightpanda plus the AGPL notice
      ;; under usr/share/doc.  Everything lands under one payload
      ;; directory the way chrome-headless-shell's does, and bin/
      ;; lightpanda is a symlink into it, which /proc/self/exe preserves
      ;; for any resource lookup the binary makes against itself.
      #:install-plan
      #~'(("usr/bin" "share/lightpanda")
          ("usr/share/doc" "share/doc"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source inputs #:allow-other-keys)
              (let ((bsdtar (string-append (assoc-ref inputs "libarchive")
                                           "/bin/bsdtar")))
                ;; A .deb is an ar archive; the payload is its xz member.
                ;; bsdtar reads both containers (ar, then xz) with no
                ;; decompressor on PATH, the way konaito unpacks its npm
                ;; tarballs.
                (invoke bsdtar "xf" source)
                (invoke bsdtar "xf" "data.tar.xz"))))
          (add-after 'install 'patch-elf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (payload (string-append out "/share/lightpanda"))
                     (binary (string-append payload "/lightpanda"))
                     (patchelf (string-append (assoc-ref inputs "patchelf")
                                              "/bin/patchelf"))
                     (loader (string-append (assoc-ref inputs "libc")
                                            "/lib/ld-linux-x86-64.so.2")))
                ;; NEEDED is glibc-only (libc, libm, the loader), so the
                ;; interpreter is the one rewrite that buys anything: an
                ;; rpath naming nothing but the payload would resolve no
                ;; soname the store loader does not already find in its
                ;; own output.
                (invoke patchelf "--set-interpreter" loader binary))))
          (add-after 'patch-elf 'link-binary
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin")))
                (mkdir-p bin)
                (symlink (string-append out "/share/lightpanda" "/lightpanda")
                         (string-append bin "/lightpanda")) #t))))))
    (synopsis "Headless browser written from scratch in Zig (prebuilt)")
    (description
     "Lightpanda is a headless browser built from scratch for AI agents
and automation: not a Chromium fork but a new browser in Zig with its own
JavaScript engine, a fraction of Chromium's memory, and a CDP endpoint
Puppeteer and Playwright connect to directly.  This package installs the
vendor build from upstream's own .deb; the ELF interpreter is patched for
the Guix store, @code{lightpanda fetch} renders any URL to html, markdown,
a PNG or a PDF without a display, and @code{lightpanda serve} exposes the
CDP endpoint on a host and port of your choice.")
    (home-page "https://lightpanda.io")
    (license license:agpl3)))

;;; lightpanda.scm ends here
