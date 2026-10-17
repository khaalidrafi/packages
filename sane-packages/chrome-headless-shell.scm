;;; sane-packages --- chrome-headless-shell: the headless Chromium that
;;; Puppeteer's `headless: "shell"' mode drives.
;;; Commentary:
;;;
;;; Chrome for Testing (https://googlechromelabs.github.io/chrome-for-testing/)
;;; publishes chrome-headless-shell, the old-headless Chromium build: a
;;; browser with no UI toolkit of its own that background pages always paint,
;;; which is exactly what a CDP screencast client wants (the new headless
;;; mode stops painting when nothing watches the compositor).
;;;
;;; The version pinned here is the one Puppeteer itself pins for its
;;; `chrome-headless-shell' product: revisions.js of the puppeteer-core the
;;; channel ships with konaito-terminal-browser-bin.  Puppeteer tolerates other
;;; revisions, but the pairing it tests is the one worth shipping, and CfT
;;; keeps every historical build downloadable, so the pin is stable.
;;;
;;; The binary is a Google build of the BSD-licensed Chromium sources (the
;;; zip carries LICENSE.headless_shell), linked against the usual desktop
;;; library set but with no GUI toolkit: no GTK, no cairo, no cups, only
;;; glib, nss, atk/atspi, dbus, X11's composite/damage/fixes family, mesa's
;;; gbm, udev and alsa.  patchelf sets the interpreter and one rpath that
;;; names the payload directory first (so the bundled libEGL/libGLESv2/
;;; libvulkan and the SwiftShader ICD resolve) and every direct dependency's
;;; lib directory after it --- the same treatment the channel's Electron
;;; packages give their vendor runtime.  The bundled libraries carry no
;;; rpath of their own, so they get the same one.
;;;
;;; The output exceeds the substitute mirror's 95 MB limit, like dsh and
;;; zcode: it builds in CI but ships no mirror substitute.
;;;
;;; Code:

(define-module (sane-packages chrome-headless-shell)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))

(define %chrome-headless-shell-version
  ;; Keep in lockstep with PUPPETEER_REVISIONS of the puppeteer-core that
  ;; (sane-packages konaito) ships; bump both together.
  "148.0.7778.97")

(define %chrome-headless-shell-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://storage.googleapis.com/chrome-for-testing-public/"
          %chrome-headless-shell-version
          "/linux64/chrome-headless-shell-linux64.zip"))
    (sha256 (base32 "0rq15dpl0c9y7sq1hrj61bd2zsv1nw6j40pvak4ibg8c59rgh8p1"))))

(define-public chrome-headless-shell-bin
  (package
    (name "chrome-headless-shell-bin")
    (version %chrome-headless-shell-version)
    (source
     %chrome-headless-shell-source)
    (build-system copy-build-system)
    ;; Google publishes linux64 (x86_64) and linux-aarch64 builds; only the
    ;; x86_64 one is packaged, mirroring every other vendor binary here.
    (supported-systems '("x86_64-linux"))
    (native-inputs (list patchelf unzip))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      ;; The zip's single top-level directory becomes cwd in 'unpack, so
      ;; "." is the payload.  A plain directory, not an archive appImage:
      ;; Chromium resolves its .pak files and icudtl.dat relative to the
      ;; real binary path (/proc/self/exe), which a symlink preserves.
      #:install-plan
      #~'(("." "share/chrome-headless-shell"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-elf
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (payload (string-append out
                                             "/share/chrome-headless-shell"))
                     (shell (string-append payload "/chrome-headless-shell"))
                     (patchelf (string-append (assoc-ref inputs "patchelf")
                                              "/bin/patchelf"))
                     (loader (string-append (assoc-ref inputs "libc")
                                            "/lib/ld-linux-x86-64.so.2"))
                     ;; The payload directory itself first: libEGL, libGLESv2,
                     ;; libvulkan and the SwiftShader ICD live there and the
                     ;; bundled libraries carry no rpath of their own.  Then
                     ;; every direct DT_NEEDED's lib directory; the ones a
                     ;; Guix library would resolve for itself, a bare vendor
                     ;; binary needs spelled out.
                     (rpath (string-append payload
                                           ":"
                                           (string-join (map (lambda (p)
                                                               (string-append (assoc-ref
                                                                               inputs
                                                                               p)
                                                                "/lib"))
                                                             '("gcc" "glib"
                                                               "nspr"
                                                               "dbus"
                                                               "libx11"
                                                               "libxcb"
                                                               "libxcomposite"
                                                               "libxdamage"
                                                               "libxext"
                                                               "libxfixes"
                                                               "libxrandr"
                                                               "mesa"
                                                               "expat"
                                                               "libxkbcommon"
                                                               "eudev"
                                                               "alsa-lib"
                                                               "at-spi2-core"))
                                                        ":")
                                           ":"
                                           (assoc-ref inputs "nss")
                                           "/lib/nss")))
                ;; The executable gets a store loader and the rpath; the
                ;; bundled libraries are ET_DYN with no PT_INTERP of their
                ;; own, so they get the rpath only -- the same split the
                ;; channel's Electron packages use between electron itself
                ;; and its .node addons.
                (invoke patchelf
                        "--set-interpreter"
                        loader
                        "--set-rpath"
                        rpath
                        shell)
                (for-each (lambda (lib)
                            (invoke patchelf "--set-rpath" rpath lib))
                          (list (string-append payload "/libEGL.so")
                                (string-append payload "/libGLESv2.so")
                                (string-append payload "/libvulkan.so.1")
                                (string-append payload "/libvk_swiftshader.so")))))
            (add-after 'patch-elf
                       'link-binary
                       (lambda* (#:key outputs #:allow-other-keys)
                         (let* ((out (assoc-ref outputs "out"))
                                (bin (string-append out "/bin")))
                           (mkdir-p bin)
                           (symlink (string-append out
                                     "/share/chrome-headless-shell"
                                     "/chrome-headless-shell")
                                    (string-append bin
                                                   "/chrome-headless-shell"))
                           #t)))))))
    ;; gcc here is gcc:lib (libgcc_s.so.1); glib covers glib, gmodule,
    ;; gobject and gio; at-spi2-core covers atk, at-spi2-atk and atspi in
    ;; the merged upstream the pinned Guix carries.
    (inputs (list (list gcc "lib")
                  glib
                  nss
                  nspr
                  at-spi2-core
                  dbus
                  libx11
                  libxcb
                  libxcomposite
                  libxdamage
                  libxext
                  libxfixes
                  libxrandr
                  mesa
                  expat
                  libxkbcommon
                  eudev
                  alsa-lib))
    (synopsis "Headless Chromium build published for testing (prebuilt)")
    (description
     "Chrome for Testing is Google's Chromium build for automated testing.
This package installs its @code{chrome-headless-shell} variant, the
old-headless browser without a UI toolkit that renders background pages
whether or not anything watches the compositor, which makes it the engine of
choice for CDP screencasting.  The ELF interpreter and rpath are patched for
the Guix store, so the binary runs on any system with this channel; point
Puppeteer at it with @code{PUPPETEER_EXECUTABLE_PATH}, or install
@code{konaito-terminal-browser-bin}, which wires it in by default.")
    (home-page "https://googlechromelabs.github.io/chrome-for-testing/")
    (license license:bsd-3)))
