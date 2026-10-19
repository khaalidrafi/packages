;;; sane-packages --- moli: a headless browser for AI agents, built in
;;; Rust, with on-demand layout and rendering.
;;; Commentary:
;;;
;;; Moli (https://github.com/lexmount/moli) is a production-ready headless
;;; browser for AI agents: a complete browser runtime with real
;;; JavaScript, DOM and CSS state, on-demand layout and paint
;;; (structure-first operations skip rendering entirely), and one serve
;;; endpoint speaking CDP, WebDriver Classic and WebDriver BiDi, so
;;; Puppeteer and Playwright connect over CDP with no adapter.  Upstream
;;; is Apache-2.0 OR MIT and publishes a GNU/Linux tarball per
;;; architecture; the x86_64 one is packaged here, the way
;;; chrome-headless-shell repackages Chrome for Testing.
;;;
;;; The binary is a stripped ELF whose direct NEEDED set is
;;; libstdc++/libgcc_s (gcc:lib), fontconfig and zlib on top of glibc.
;;; patchelf rewrites the interpreter and one rpath naming those
;;; dependencies' lib directories --- the ones a Guix library would
;;; resolve for itself, a bare vendor binary needs spelled out, the same
;;; split chrome-headless-shell makes between its executable and its
;;; bundled payload libraries.
;;;
;;; Code:

(define-module (sane-packages moli)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gcc))

(define %moli-version
  ;; Upstream tags this v1.1.18; the tarball's VERSION file and
  ;; `moli --version' both say 1.1.18.
  "1.1.18")

(define %moli-source
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/lexmount/moli/releases/download/v"
          %moli-version "/moli-x86_64-unknown-linux-gnu.tar.gz"))
    (sha256 (base32 "1ca8dbd65p3yw4wngl4z8nc0yp0r5adbbvg16s8vn5mhnaymywar"))))

(define-public moli-bin
  (package
    (name "moli-bin")
    (version %moli-version)
    (source
     %moli-source)
    (build-system copy-build-system)
    ;; Upstream publishes x86_64 and aarch64 GNU/Linux tarballs; only the
    ;; x86_64 one is packaged, mirroring every other vendor binary here.
    (supported-systems '("x86_64-linux"))
    (native-inputs (list libarchive patchelf))
    (arguments
     (list
      #:validate-runpath? #f ;vendor ELF: the rpath below is load-bearing
      #:strip-binaries? #f ;upstream ships it stripped already
      ;; The tarball's single top-level directory is stripped in 'unpack
      ;; below, so "." is the payload: the binary plus LICENSE-APACHE,
      ;; LICENSE-MIT and the third-party notices upstream ships next to
      ;; it.  bin/moli is a symlink into it, which /proc/self/exe
      ;; preserves for any resource lookup the binary makes against
      ;; itself.
      #:install-plan
      #~'(("." "share/moli"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source inputs #:allow-other-keys)
              (let ((bsdtar (string-append (assoc-ref inputs "libarchive")
                                           "/bin/bsdtar")))
                ;; bsdtar reads the tarball with no decompressor on PATH,
                ;; the way konaito unpacks its npm tarballs; the strip
                ;; here replaces 'unpack's chdir into the single top-level
                ;; directory.
                (invoke bsdtar "xzf" source "--strip-components=1"))))
          (add-after 'install 'patch-elf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (payload (string-append out "/share/moli"))
                     (binary (string-append payload "/moli"))
                     (patchelf (string-append (assoc-ref inputs "patchelf")
                                              "/bin/patchelf"))
                     (loader (string-append (assoc-ref inputs "libc")
                                            "/lib/ld-linux-x86-64.so.2"))
                     ;; Every direct DT_NEEDED's lib directory:
                     ;; libstdc++ and libgcc_s through gcc:lib, then
                     ;; fontconfig and zlib.  glibc's own sonames the
                     ;; store loader resolves from its output, the way
                     ;; every -bin package in this channel leaves them.
                     (rpath (string-join (map (lambda (p)
                                                (string-append (assoc-ref
                                                                inputs p)
                                                               "/lib"))
                                              '("gcc" "fontconfig" "zlib"))
                                         ":")))
                (invoke patchelf
                        "--set-interpreter"
                        loader
                        "--set-rpath"
                        rpath
                        binary))))
          (add-after 'patch-elf 'link-binary
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin")))
                (mkdir-p bin)
                (symlink (string-append out "/share/moli" "/moli")
                         (string-append bin "/moli")) #t))))))
    (inputs (list (list gcc "lib") ;libstdc++.so.6, libgcc_s.so.1
                  fontconfig zlib))
    (synopsis "Headless browser for AI agents, on-demand rendering (prebuilt)")
    (description
     "Moli is a headless browser for AI agents: a complete browser runtime
with real JavaScript, DOM and CSS state, whose on-demand layout and paint
design lets structure-first operations skip rendering entirely, so most
automation requests cost a fraction of a continuously compositing browser.
The same serve endpoint speaks CDP, WebDriver Classic and WebDriver BiDi,
which Puppeteer and Playwright connect to over CDP.  This package installs
the vendor build from upstream's own tarball; the ELF interpreter and an
rpath over its direct dependencies are patched for the Guix store, and
@code{moli fetch} renders any URL to markdown, a semantic tree, a PNG or a
paginated PDF without a display.")
    (home-page "https://github.com/lexmount/moli")
    ;; license-metadata.json says "Apache-2.0 OR MIT"; the tarball ships
    ;; both LICENSE files.
    (license (list license:asl2.0 license:expat))))

;;; moli.scm ends here
