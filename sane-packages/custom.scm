(define-module (sane-packages custom)
  ;; The one non-package name this module exports.  (sane-packages cline)
  ;; already imports this module for bun-bin, and cline's CLI release number
  ;; covers all three deliveries (see %cline-version below); exporting it lets
  ;; that number be written once.  It goes through #:export rather than
  ;; `define-public' because tests/check-static.sh harvests package names by
  ;; grepping `define-public' forms -- a version *string* must not show up
  ;; there.
  #:export (%cline-version)
  #:use-module (gnu packages base)
  #:use-module (gnu packages suckless)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages node)
  #:use-module (gnu packages node-xyz)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system node)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix git-download)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system trivial)
  #:use-module (guix build utils)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages nss)
  ;; qrencode, for purple-discord's QR login (see its inputs)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages image)
  #:use-module (sane-packages bcon-crates)
  #:use-module (sane-packages dsh-modules)
  #:use-module (sane-packages zcode)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services shepherd)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages messaging)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-compression)
  #:use-module (gnu packages commencement))

(define-public bcon
  (package
    (name "bcon")
    (version "1.5.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/sanohiro/bcon.git")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1hvswk4c3q0r6kpdpwf4vfran9zc4cwr3rk91gk1hqyyp6006k14"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:install-source? #f))
    (synopsis "GPU-accelerated terminal emulator for Linux console (TTY)")
    (description
     "bcon is a GPU-accelerated terminal emulator that runs directly on the Linux console (TTY) without X11 or Wayland. It uses DRM/KMS and OpenGL ES for rendering, supports Sixel and Kitty graphics protocols, built-in split panes and tabs, and provides fcitx5 integration for Japanese input.")
    (home-page "https://github.com/sanohiro/bcon")
    (license license:expat)
    (native-inputs (list pkg-config))
    (inputs (append (list libdrm
                          mesa
                          libxkbcommon
                          libinput
                          eudev
                          dbus
                          fontconfig
                          freetype
                          wayland
                          wayland-protocols
                          openssl
                          libseat)
                    ;; All 287 crates from bcon's Cargo.lock, looked up in the
                    ;; (sane-packages bcon-crates) module.  #:module must name
                    ;; the module exactly as its define-module declares it, or
                    ;; resolve-interface fails with "no code for module".
                    (cargo-inputs 'bcon
                                  #:module '(sane-packages bcon-crates))))))

;; Rootless bcon shepherd service.
;; Runs via shepherd-root-service-type (system shepherd, owns DRM/input nodes),
;; but bcon itself is launched as the user: libseat + elogind handle seat
;; assignment, and HOME=/home/khalid so bcon reads ~/.config/bcon natively.
;; Bcon via the *system* shepherd (root method).
;; The getty on the same TTY is removed in system-config.scm (mingetty delete);
;; this also stops it defensively on start, emulating upstream's
;; Conflicts=getty@%i.  BCON_BACKEND=vt is the root-only backend
;; (bypasses libseat entirely, opens DRM directly as root).
(define* (bcon-shepherd-service #:key (tty "tty2")
                                (auto-start? #t))
  (shepherd-service (documentation
                     "Run the bcon GPU terminal emulator on a virtual terminal.")
                    (provision (list (symbol-append 'bcon-
                                                    (string->symbol tty))))
                    (requirement '(user-processes host-name udev))
                    (auto-start? auto-start?)
                    (start #~(lambda args
                               ;; Emulate upstream's Conflicts=getty@%i: stop the getty holding this VT.
                               (false-if-exception (stop-service '#$(symbol-append 'term-
                                                                     (string->symbol
                                                                      tty))))
                               (apply (make-forkexec-constructor (list
                                                                  "/bin/sh"
                                                                  "-c"
                                                                  (string-append
                                                                   "exec "
                                                                   #$(file-append
                                                                      bcon
                                                                      "/bin/bcon")
                                                                   " </dev/"
                                                                   #$tty
                                                                   " >/dev/"
                                                                   #$tty
                                                                   " 2>&1"))
                                                                 #:environment-variables
                                                                 (list
                                                                  "BCON_BACKEND=vt"
                                                                  "RUST_LOG=info"
                                                                  "TERM=linux"
                                                                  "HOME=/root")
                                                                 ;; Upstream systemd unit sets WorkingDirectory=/root; mirror it.
                                                                 #:directory
                                                                 "/root") args)))
                    (stop #~(make-kill-destructor))))

;; Splice into the services list of your operating-system declaration.
;; Uses shepherd-root-service-type (system shepherd manages DRM/input device
;; nodes), but libseat assigns the seat to the logged-in user, not root.
;; The getty on the same TTY MUST be disabled in system-config.scm.
(define* (bcon-service #:key (tty "tty2")
                       (auto-start? #t))
  (simple-service (symbol-append 'bcon-on-
                                 (string->symbol tty))
                  shepherd-root-service-type
                  (list (bcon-shepherd-service #:tty tty
                                               #:auto-start? auto-start?))))

;; systemd's "bcon@ttyN" equivalent: registers disabled instances for
;; tty1..tty6 once, so any of them can be started on demand with
;; "herd start bcon-ttyN" (after stopping the getty on that TTY) without
;; reconfiguring per TTY.
(define %bcon-ttys
  '("tty1" "tty2" "tty3" "tty4" "tty5" "tty6"))
(define bcon-templated-service
  (simple-service 'bcon-templated shepherd-root-service-type
                  (map (lambda (tty)
                         (bcon-shepherd-service #:tty tty)) %bcon-ttys)))

;;; ---------------------------------------------------------------------------
;;; Rootless bcon as a *user* (home) shepherd service.
;;;
;;; This is the variant that runs in the user shepherd (home-config.scm via
;;; home-shepherd-service-type), so it executes *as khalid* (uid 1000), not
;;; root. bcon uses libseat with the logind backend: because khalid already
;;; holds an active elogind session (e.g. c1 on seat0), logind grants the seat
;; and applies DRM/input device ACLs to uid 1000 — so bcon can own the GPU/VT
;; without root. See upstream docs/installation.md "Rootless Mode".
;;
;;; A user shepherd service has no controlling TTY and no PAM session, so it
;;; must open the VT directly. The accompanying udev rule (system-config.scm:
;;; %bcon-vt-udev-rule) makes /dev/ttyN group 'tty' mode 0660, and khalid is a
;;; member of 'tty', so the open succeeds. HOME is set explicitly so bcon reads
;; ~/.config/bcon natively.
(define* (bcon-user-shepherd-service #:key (tty "tty2")
                                     (auto-start? #t))
  (shepherd-service (documentation (string-append
                                    "Run the bcon GPU terminal emulator on "
                                    tty
                                    " as the user (rootless, libseat/logind)."))
                    (provision (list (symbol-append 'bcon-
                                                    (string->symbol tty))))
                    ;; 'dbus' is provided by home-dbus-service-type (user session bus);
                    ;; libseat's logind backend talks to logind over the system bus (always
                    ;; up), and elogind grants the seat to khalid's active session.
                    (requirement '(dbus))
                    (auto-start? auto-start?)
                    ;; No #:user/#$user here: the home shepherd already runs as khalid.
                    (start #~(lambda args
                               ;; Emulate upstream's Conflicts=getty@%i: stop the getty holding this
                               ;; VT (it is removed from %desktop-services in system-config.scm, but
                               ;; if it was re-enabled this keeps bcon the sole owner of the VT).
                               (false-if-exception (stop-service '#$(symbol-append 'term-
                                                                     (string->symbol
                                                                      tty))))
                               ;; If something is already on the VT (a leftover from a previous
                               ;; generation), bail out loudly rather than wedging the VT.
                               (apply (make-forkexec-constructor (list
                                                                  "/bin/sh"
                                                                  "-c"
                                                                  (string-append
                                                                   "exec "
                                                                   #$(file-append
                                                                      bcon
                                                                      "/bin/bcon")
                                                                   " </dev/"
                                                                   #$tty
                                                                   " >/dev/"
                                                                   #$tty
                                                                   " 2>&1"))
                                                                 #:environment-variables
                                                                 (list
                                                                  "BCON_BACKEND=seatd"
                                                                  "RUST_LOG=info"
                                                                  "TERM=linux"
                                                                  "HOME=/home/khalid"
                                                                  "XDG_RUNTIME_DIR=/run/user/1000"))
                                      args)))
                    (stop #~(make-kill-destructor))))

;;; VT-access udev rule for the user-shepherd bcon: grant direct ownership
;;; of tty2 to khalid so the user-shepherd service can open /dev/tty2 without
;;; needing membership in the 'tty' group or touching any other VTs.
(define %bcon-vt-udev-rule
  (udev-rule "99-bcon-vt.rules"
             (string-append "KERNEL==\"tty2\", OWNER=\"khalid\", MODE=\"0600\"
")))

(define %bun-version
  "1.4.2")
(define %bun-github
  "https://github.com/oven-sh/bun/releases/download/bun-v")

(define bun-avx2-source
  (origin
    (method url-fetch)
    (uri (string-append %bun-github %bun-version "/bun-linux-x64.zip"))
    (sha256 (base32 "04x94ba6hh6nin521diym3r425q2936m6bm5zzapay2jyyp8ydin"))))

(define bun-baseline-source
  (origin
    (method url-fetch)
    (uri (string-append %bun-github %bun-version "/bun-linux-x64-baseline.zip"))
    (sha256 (base32 "13vjpyvam9p6gp4nm03jv8r1l1acrv8cndwxhgml017y2h7h8y66"))))

(define-public bun-bin
  (package
    (name "bun-bin")
    (version %bun-version)
    (source
     #f)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("bun-linux-x64/bun" "lib/bun/bun-avx2")
          ("bun-linux-x64-baseline/bun" "lib/bun/bun-baseline"))
      #:phases
      #~(let ((unpack-variants (lambda* (#:key inputs #:allow-other-keys)
                                 (let ((unzip (string-append (assoc-ref inputs
                                                              "unzip")
                                                             "/bin/unzip")))
                                   (invoke unzip "-q"
                                           #$bun-avx2-source)
                                   (invoke unzip "-q"
                                           #$bun-baseline-source)))))
          (alist-cons-after 'install
                            'make-wrapper
                            (lambda* (#:key inputs outputs #:allow-other-keys)
                              ;; patchelf corrupts bun's huge binary; instead of touching the
                              ;; ELF we exec it through the store glibc loader directly (bun
                              ;; needs only glibc, which the loader resolves itself).
                              (let* ((out (assoc-ref outputs "out"))
                                     (loader (string-append (assoc-ref inputs
                                                                       "libc")
                                              "/lib/ld-linux-x86-64.so.2"))
                                     (avx2 (string-append out
                                                          "/lib/bun/bun-avx2"))
                                     (baseline (string-append out
                                                "/lib/bun/bun-baseline")))
                                (mkdir-p (string-append out "/bin"))
                                (call-with-output-file (string-append out
                                                        "/bin/bun")
                                  (lambda (port)
                                    (format port
                                     "#!~a
if grep -q avx2 /proc/cpuinfo 2>/dev/null; then exec ~a ~a \"$@\"; else exec ~a ~a \"$@\"; fi
"
                                     (string-append (assoc-ref inputs "bash")
                                                    "/bin/bash")
                                     loader
                                     avx2
                                     loader
                                     baseline)))
                                (chmod (string-append out "/bin/bun") #o555)))
                            (alist-replace 'unpack unpack-variants
                                           %standard-phases)))))
    (inputs (list bash-minimal unzip))
    (synopsis
     "Incredibly fast JavaScript runtime, bundler, test runner and package manager")
    (description
     "bun is an all-in-one JavaScript/TypeScript runtime and toolchain.  This
package installs the official prebuilt binaries (both the AVX2 and baseline
variants) and a wrapper that picks the right one for the CPU at runtime.
The binaries are patched for Guix (store glibc interpreter and RUNPATH);
building from source would require oven-sh's custom Zig fork, so upstream
release binaries are used instead.")
    (home-page "https://bun.sh")
    (license license:expat)))

(define %opencode-version
  "1.18.34")
(define %opencode-url
  "https://github.com/anomalyco/opencode/releases/download/v")

(define opencode-avx2-source
  (origin
    (method url-fetch)
    (uri (string-append %opencode-url %opencode-version
                        "/opencode-linux-x64.tar.gz"))
    (sha256 (base32 "16ky3nkw3vs11flwcbdnf0wdlyzfh80d55cmv4nisv928yb4f8hg"))))

(define opencode-baseline-source
  (origin
    (method url-fetch)
    (uri (string-append %opencode-url %opencode-version
                        "/opencode-linux-x64-baseline.tar.gz"))
    (sha256 (base32 "09qvv23azpvqmdv4iys9n12ljzygxwyk0ri1fnr4ix8ys9cd9c14"))))

(define-public opencode-bin
  (package
    (name "opencode-bin")
    (version %opencode-version)
    (source
     #f)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("opencode-avx2/opencode" "lib/opencode/opencode-avx2")
          ("opencode-baseline/opencode" "lib/opencode/opencode-baseline"))
      #:phases
      #~(let ((unpack-variants (lambda* (#:key inputs #:allow-other-keys)
                                 ;; Tarballs hold a single `opencode` binary at root.
                                 (mkdir "opencode-avx2")
                                 (mkdir "opencode-baseline")
                                 (invoke "tar" "xzf"
                                         #$opencode-avx2-source "-C"
                                         "opencode-avx2")
                                 (invoke "tar" "xzf"
                                         #$opencode-baseline-source "-C"
                                         "opencode-baseline"))))
          (alist-cons-after 'install
                            'make-wrapper
                            (lambda* (#:key inputs outputs #:allow-other-keys)
                              (let* ((out (assoc-ref outputs "out"))
                                     (loader (string-append (assoc-ref inputs
                                                                       "libc")
                                              "/lib/ld-linux-x86-64.so.2"))
                                     ;; Bun dlopens native modules (watcher.node) needing
                                     ;; libgcc_s/libstdc++; pin them like cursor-cli does.
                                     (lib-path (string-append (assoc-ref
                                                               inputs "gcc")
                                                              "/lib" ":"
                                                              (assoc-ref
                                                               inputs "zlib")
                                                              "/lib"))
                                     (avx2 (string-append out
                                            "/lib/opencode/opencode-avx2"))
                                     (baseline (string-append out
                                                "/lib/opencode/opencode-baseline")))
                                (mkdir-p (string-append out "/bin"))
                                (call-with-output-file (string-append out
                                                        "/bin/opencode")
                                  (lambda (port)
                                    (format port
                                     "#!~a
if grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then exec ~a --library-path ~a ~a \"$@\"; else exec ~a --library-path ~a ~a \"$@\"; fi
"
                                     (string-append (assoc-ref inputs "bash")
                                                    "/bin/bash")
                                     loader
                                     lib-path
                                     avx2
                                     loader
                                     lib-path
                                     baseline)))
                                (chmod (string-append out "/bin/opencode")
                                       #o555)))
                            (alist-replace 'unpack unpack-variants
                                           %standard-phases)))))
    (inputs (list bash-minimal tar gzip
                  (list gcc "lib") zlib))
    (synopsis "AI coding agent for the terminal")
    (description
     "OpenCode is an open-source AI coding agent built for the terminal.
This package installs the official prebuilt binaries (both the AVX2 and
baseline variants) and a wrapper that picks the right one for the CPU at
runtime.  The binaries need only glibc and are exec'd via the store glibc
loader, so no FHS emulation is required.")
    (home-page "https://opencode.ai")
    (license license:expat)))

(define %cursor-cli-version
  "2026.10.01-e373342")

(define cursor-cli-source
  (origin
    (method url-fetch)
    (uri (string-append "https://downloads.cursor.com/lab/"
                        %cursor-cli-version
                        "/linux/x64/agent-cli-package.tar.gz"))
    (sha256 (base32 "1s18mqck59bplrhy9av75f08js2sfx2lrgkh76chwlj4wv32d5x7"))))

(define-public cursor-cli-bin
  (package
    (name "cursor-cli-bin")
    (version %cursor-cli-version)
    (source
     #f)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("dist-package" "."))
      #:phases
      #~(let ((unpack-tarball (lambda* (#:key inputs #:allow-other-keys)
                                (invoke "tar" "xzf"
                                        #$cursor-cli-source)))
              (wrap-node-and-entry (lambda* (#:key inputs outputs
                                             #:allow-other-keys)
                                     (let* ((out (assoc-ref outputs "out"))
                                            (loader (string-append (assoc-ref
                                                                    inputs
                                                                    "libc")
                                                     "/lib/ld-linux-x86-64.so.2"))
                                            (gcc-lib (string-append (assoc-ref
                                                                     inputs
                                                                     "gcc")
                                                                    "/lib"))
                                            (zlib-lib (string-append (assoc-ref
                                                                      inputs
                                                                      "zlib")
                                                                     "/lib"))
                                            (lib-path (string-append gcc-lib
                                                                     ":"
                                                                     zlib-lib)))
                                       ;; node → node.bin; `node` becomes a loader wrapper so
                                       ;; upstream's cursor-agent script runs it unchanged.
                                       (rename-file (string-append out "/node")
                                                    (string-append out
                                                     "/node.bin"))
                                       (call-with-output-file (string-append
                                                               out "/node")
                                         (lambda (port)
                                           (format port
                                            "#!~a
exec ~a --library-path ~a ~a/node.bin \"$@\"
"
                                            (string-append (assoc-ref inputs
                                                                      "bash")
                                                           "/bin/bash")
                                            loader
                                            lib-path
                                            out)))
                                       (chmod (string-append out "/node")
                                              #o555)
                                       ;; upstream launcher renamed to match the CLI name
                                       (rename-file (string-append out
                                                     "/cursor-agent")
                                                    (string-append out
                                                     "/cursor-cli"))
                                       ;; Entry point mirroring numtide's makeWrapper: the
                                       ;; agent script needs realpath/basename (coreutils) and
                                       ;; its own dir (rg, node) on PATH.
                                       (mkdir-p (string-append out "/bin"))
                                       (call-with-output-file (string-append
                                                               out
                                                               "/bin/cursor-cli")
                                         (lambda (port)
                                           (format port
                                            "#!~a
export PATH=\"~a:~a:$PATH\"
exec ~a/cursor-cli \"$@\"
"
                                            (string-append (assoc-ref inputs
                                                                      "bash")
                                                           "/bin/bash")
                                            out
                                            (string-append (assoc-ref inputs
                                                            "coreutils")
                                                           "/bin")
                                            out)))
                                       (chmod (string-append out
                                               "/bin/cursor-cli") #o555)))))
          (alist-cons-after 'install
                            'wrap-node-and-entry wrap-node-and-entry
                            (alist-replace 'unpack unpack-tarball
                                           %standard-phases)))))
    (inputs (list bash-minimal
                  (list gcc "lib") zlib))
    (synopsis "CLI coding agent for the Cursor AI editor")
    (description
     "Cursor Agent is the terminal-based AI coding agent from Cursor.
This package installs the official prebuilt bundle (bash launcher, bundled
Node.js runtime, ripgrep and JS assets).  The bundled node binary is
executed through the Guix store glibc loader with libstdc++/libgcc/zlib on
its library path, so no FHS emulation is needed.")
    (home-page "https://cursor.com")
    (license (license:non-copyleft "https://cursor.com"
              "Proprietary Cursor license — unfree, non-redistributable."))))

(define %copilot-version
  "1.0.91")

(define copilot-loader-source
  (origin
    (method url-fetch)
    (uri (string-append "https://registry.npmjs.org/@github/copilot/-/"
                        "copilot-" %copilot-version ".tgz"))
    (sha256 (base32 "109pv3cng77zsl01s2ggg7xkpdiyi1qgbl16x6abjv0yi9qmsc2g"))))

(define copilot-platform-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://registry.npmjs.org/@github/copilot-linux-x64/-/"
          "copilot-linux-x64-" %copilot-version ".tgz"))
    (sha256 (base32 "0141f3fmpcv2zlqxmxx2kyjqk2zwg3mfxrh1n9qb4n8dlgaxrl8i"))))

(define-public copilot-cli-bin
  (package
    (name "copilot-cli-bin")
    (version %copilot-version)
    (source
     #f)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("loader" "lib/node_modules/@github/copilot")
          ("platform" "lib/node_modules/@github/copilot-linux-x64"))
      #:phases
      #~(let ((unpack-tgzs (lambda* (#:key inputs #:allow-other-keys)
                             (let ((tar (string-append (assoc-ref inputs "tar")
                                                       "/bin/tar")))
                               (invoke tar "xzf"
                                       #$copilot-loader-source)
                               (mkdir-p "loader")
                               (invoke "cp" "-r" "package/." "loader/")
                               (invoke "rm" "-r" "package")
                               (invoke tar "xzf"
                                       #$copilot-platform-source)
                               (mkdir-p "platform")
                               (invoke "cp" "-r" "package/." "platform/")
                               (invoke "rm" "-r" "package")))))
          (alist-cons-after 'install
                            'wrap-binaries
                            (lambda* (#:key inputs outputs #:allow-other-keys)
                              (let* ((out (assoc-ref outputs "out"))
                                     (loader (string-append (assoc-ref inputs
                                                                       "libc")
                                              "/lib/ld-linux-x86-64.so.2"))
                                     (lib-path (string-append (assoc-ref
                                                               inputs "gcc")
                                                              "/lib:"
                                                              (assoc-ref
                                                               inputs "zlib")
                                                              "/lib"))
                                     (plat (string-append out
                                            "/lib/node_modules/@github/copilot-linux-x64"))
                                     (bash (string-append (assoc-ref inputs
                                                                     "bash")
                                                          "/bin/bash")))
                                ;; platform copilot -> copilot.bin + loader wrapper
                                (rename-file (string-append plat "/copilot")
                                             (string-append plat
                                                            "/copilot.bin"))
                                (chmod (string-append plat "/copilot.bin")
                                       #o555)
                                (call-with-output-file (string-append plat
                                                        "/copilot")
                                  (lambda (port)
                                    (format port
                                     "#!~a
exec ~a --library-path ~a ~a/copilot.bin \"$@\"
"
                                     bash
                                     loader
                                     lib-path
                                     plat)))
                                (chmod (string-append plat "/copilot") #o555)
                                ;; npm layout: platform package must be resolvable from
                                ;; the loader package's node_modules.
                                (mkdir-p (string-append plat
                                          "/../copilot/node_modules/@github"))
                                (symlink plat
                                         (string-append plat
                                          "/../copilot/node_modules/@github/"
                                          "copilot-linux-x64"))
                                ;; bin/copilot: skip npm-loader.js (it only picks
                                ;; musl/glibc and needs detect-libc from npm); this is
                                ;; glibc linux-x64, so exec the platform binary
                                ;; (already a loader wrapper) directly.
                                (mkdir-p (string-append out "/bin"))
                                (call-with-output-file (string-append out
                                                        "/bin/copilot")
                                  (lambda (port)
                                    (format port "#!~a
export PATH=\"~a/bin:$PATH\"
exec ~a/copilot \"$@\"
"
                                            bash
                                            (assoc-ref inputs "coreutils")
                                            plat)))
                                (chmod (string-append out "/bin/copilot")
                                       #o555)))
                            (alist-replace 'unpack unpack-tgzs
                                           %standard-phases)))))
    (inputs (list bash-minimal
                  (list gcc "lib") zlib))
    (synopsis "GitHub Copilot CLI - coding agent for your terminal")
    (description
     "GitHub Copilot CLI brings the Copilot coding agent to the terminal.
This package installs the official prebuilt npm bundle: the JS loader plus
the linux-x64 native build.  The 153MB node-based binary is exec'd through
the Guix store glibc loader with libstdc++/zlib on its library path, so no
FHS emulation is needed.  Requires a GitHub account to authenticate.")
    (home-page "https://github.com/features/copilot")
    (license (license:non-copyleft "https://github.com/github/copilot-cli"
              "Proprietary GitHub/Microsoft license - unfree."))))

(define %goose-version
  "1.53.0")

(define goose-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/aaif-goose/goose/releases/download/v"
          %goose-version "/goose-x86_64-unknown-linux-gnu.tar.gz"))
    (sha256 (base32 "1p0mm5wd7s12hvydzxd2iz6gk8jycm95rz1j0aic1b3mdcd1kcny"))))

(define-public goose-cli-bin
  (package
    (name "goose-cli-bin")
    (version %goose-version)
    (source
     #f)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("goose" "lib/goose/goose"))
      #:phases
      #~(let ((unpack-tarball (lambda* (#:key inputs #:allow-other-keys)
                                (let ((tar (string-append (assoc-ref inputs
                                                                     "tar")
                                                          "/bin/tar")))
                                  (invoke tar "xzf"
                                          #$goose-source)
                                  (chmod "goose" #o555))))
              (wrap-binary (lambda* (#:key inputs outputs #:allow-other-keys)
                             (let* ((out (assoc-ref outputs "out"))
                                    (loader (string-append (assoc-ref inputs
                                                                      "libc")
                                             "/lib/ld-linux-x86-64.so.2"))
                                    (lib-path (string-append (assoc-ref inputs
                                                              "gcc") "/lib"))
                                    (bash (string-append (assoc-ref inputs
                                                                    "bash")
                                                         "/bin/bash")))
                               ;; loader wrapper at lib/goose/goose.real
                               (call-with-output-file (string-append out
                                                       "/lib/goose/goose.real")
                                 (lambda (port)
                                   (format port
                                    "#!~a
exec ~a --library-path ~a ~a/lib/goose/goose \"$@\"
"
                                    bash
                                    loader
                                    lib-path
                                    out)))
                               (chmod (string-append out
                                                     "/lib/goose/goose.real")
                                      #o555)
                               ;; entry point: user profile PATH for python/xclip etc
                               (mkdir-p (string-append out "/bin"))
                               (call-with-output-file (string-append out
                                                       "/bin/goose")
                                 (lambda (port)
                                   (format port
                                    "#!~a
export PATH=\"~a/bin:$PATH\"
exec ~a/lib/goose/goose.real \"$@\"
" bash
                                    (assoc-ref inputs "coreutils") out)))
                               (chmod (string-append out "/bin/goose") #o555)))))
          (alist-cons-after 'install
                            'wrap-binary wrap-binary
                            (alist-replace 'unpack unpack-tarball
                                           %standard-phases)))))
    (inputs (list bash-minimal
                  (list gcc "lib")))
    (synopsis "Open-source AI agent for the terminal (Goose CLI)")
    (description
     "Goose is an open-source, extensible AI agent that runs in the
terminal: it installs, executes, edits and tests code with any LLM via
BYOK providers or local models.  This package wraps the official
prebuilt x86_64 GNU binary, exec'd through the Guix store glibc loader
with libstdc++/libgcc_s on its library path - no FHS emulation needed.
Configure with @command{goose configure}; sessions and MCP extensions
live under ~/.config/goose.")
    (home-page "https://github.com/aaif-goose/goose")
    (license license:asl2.0)))

;;;
;;; terminal-browser (prebuilt Electron binary)
;;;
;;; Uses patchelf to set the ELF interpreter and RPATH so that
;;; Electron and its child processes (renderers, GPU, crashpad)
;;; can find all shared libraries on a non-FHS Guix system.

(define %terminal-browser-version
  "0.13.4")

(define %terminal-browser-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/zenbu-labs/terminal-browser/releases/download/v"
          %terminal-browser-version "/terminal-browser-linux-x64.tar.gz"))
    (sha256 (base32 "196k97b9cr68w9v50pf51bkwbylympzwsq8r7ymi2rxipamdlxv2"))))

(define-public terminal-browser-bin
  (package
    (name "terminal-browser-bin")
    (version %terminal-browser-version)
    (source
     %terminal-browser-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs (list patchelf))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("." "share/terminal-browser"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-and-wrap
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((out (assoc-ref outputs "out"))
                     (tb-dir (string-append out "/share/terminal-browser"))
                     (electron-dir (string-append tb-dir "/electron"))
                     (patchelf-bin (string-append (assoc-ref inputs "patchelf")
                                                  "/bin/patchelf"))
                     (loader (string-append (assoc-ref inputs "libc")
                                            "/lib/ld-linux-x86-64.so.2"))
                     (electron-rpath (string-append electron-dir
                                                    ":"
                                                    (assoc-ref inputs "gcc")
                                                    "/lib:"
                                                    (string-join (map (lambda 
                                                                              (p)
                                                                        (string-append
                                                                         (assoc-ref
                                                                          inputs
                                                                          p)
                                                                         "/lib"))
                                                                      '("zlib"
                                                                        "glib"
                                                                        "nspr"
                                                                        "at-spi2-core"
                                                                        "cups"
                                                                        "dbus"
                                                                        "cairo"
                                                                        "pango"
                                                                        "gtk+"
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
                                                                        "fontconfig-minimal"))
                                                                 ":")
                                                    ":"
                                                    (assoc-ref inputs "nss")
                                                    "/lib/nss"))
                     (agent-rpath (string-append (assoc-ref inputs "gcc")
                                                 "/lib"))
                     (electron-bin (string-append electron-dir "/electron"))
                     (crashpad-handler (string-append electron-dir
                                        "/chrome_crashpad_handler"))
                     (agent-browser-bin (string-append tb-dir
                                         "/agent-browser/bin/agent-browser"))
                     (cli-js (string-append tb-dir "/cli/dist/main.js"))
                     (bash (string-append (assoc-ref inputs "bash-minimal")
                                          "/bin/bash")))
                (for-each (lambda (binary rpath)
                            (when (file-exists? binary)
                              (invoke patchelf-bin
                                      "--set-interpreter"
                                      loader
                                      "--set-rpath"
                                      rpath
                                      binary)))
                          (list electron-bin crashpad-handler
                                agent-browser-bin)
                          (list electron-rpath electron-rpath agent-rpath))
                ;; Native Electron addons (e.g. browser/native/pixel.node)
                ;; call dlopen("libstdc++.so.6") / dlopen("libgcc_s.so.1")
                ;; at load time but ship with *no* RUNPATH of their own.
                ;; The dlopened object cannot reuse electron's RUNPATH, so
                ;; the loader fails with
                ;; "libstdc++.so.6: cannot open shared object file"
                ;; and the daemon dies on startup ("daemon did not start",
                ;; or a silent exit when LD_LIBRARY_PATH hides the crash).
                ;; gcc:lib is already an input, so give every .node addon
                ;; the same rpath as electron.
                (for-each (lambda (addon)
                            (invoke patchelf-bin "--set-rpath" electron-rpath
                                    addon))
                          (find-files tb-dir "\\.node$"))
                ;; Fix: the wrapper sets ELECTRON_RUN_AS_NODE=1 so that
                ;; electron acts as a plain Node.js interpreter for the
                ;; CLI (cli/dist/main.js).  But spawnDaemon() inherits
                ;; process.env, so the daemon's browser/dist/main.js
                ;; also gets ELECTRON_RUN_AS_NODE=1 — which prevents it
                ;; from loading require('electron') (only available in
                ;; browser mode) and the daemon dies silently.  Patch the
                ;; spawn call to pass an env without that variable.
                (substitute* (string-append tb-dir "/cli/dist/main.js")
                  ((", stdio: \"ignore\" });")
                   (string-append
                    ", stdio: \"ignore\", env: Object.assign({}, "
                    "process.env, {ELECTRON_RUN_AS_NODE: void 0})});")))
                (mkdir-p (string-append out "/bin"))
                (call-with-output-file (string-append out
                                                      "/bin/terminal-browser")
                  (lambda (port)
                    (format port
                     "#!~a~@
export TERMINAL_BROWSER_DIST_ROOT=\"~a\"~@
export ELECTRON_RUN_AS_NODE=1~@
# bcon supports kitty graphics but doesn't answer the \\x1B[14t probe.~@
# Skip the graphics detection probe; bcon renders kitty graphics fine.~@
export TERMINAL_BROWSER_SKIP_GRAPHICS_CHECK=1~@
exec \"~a/electron\" \"~a/cli/dist/main.js\" \"$@\"~%"
                     bash
                     tb-dir
                     electron-dir
                     tb-dir)))
                (chmod (string-append out "/bin/terminal-browser") #o555)
                (when (file-exists? agent-browser-bin)
                  (call-with-output-file (string-append out
                                                        "/bin/agent-browser")
                    (lambda (port)
                      (format port "#!~a~@\nexec \"~a\" \"$@\"~%" bash
                              agent-browser-bin)))
                  (chmod (string-append out "/bin/agent-browser") #o555))
                #t))))))
    (inputs (list bash-minimal
                  (list gcc "lib")
                  zlib
                  glib
                  nss
                  nspr
                  at-spi2-core
                  cups
                  dbus
                  cairo
                  pango
                  gtk+
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
                  alsa-lib
                  fontconfig))
    (synopsis "Real browser that runs inside your terminal")
    (description
     "terminal-browser is a terminal browser that displays rendered website pixels
inside Kitty/Sixel graphics-capable terminals using Electron's offscreen
rendering API.  The outer UI is a Rust/Tauri graphics engine with a custom
React renderer; both UI and content share a single canvas.  Keyboard and
mouse events are captured from the terminal and replayed into Chromium as
synthetic input.  The @option{--ssh} flag proxies network requests through a
remote server while rendering locally.")
    (home-page "https://github.com/zenbu-labs/terminal-browser")
    (license license:expat)))

;;;
;;; pi-coding-agent (prebuilt compiled Bun binary)
;;;
;;; Pi is a TypeScript coding-agent CLI. The upstream release ships a
;;; single Linux x86_64 tarball containing a self-contained binary
;;; produced by `bun build --compile` (~105 MB, no node runtime needed).
;;; It only links against glibc (libc, ld-linux, libpthread, libdl, libm),
;;; so we exec it through the Guix glibc loader with gcc:lib on the
;;; library path — exactly like goose-cli-bin. No node runtime, no
;;; FHS emulation, no patchelf.

(define %pi-version
  "1.0.2")

(define %pi-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/earendil-works/pi/releases/download/v"
          %pi-version "/pi-linux-x64.tar.gz"))
    (sha256 (base32 "062x52daww4anigbacc908zfxs9wd0l6pjv4ys7sifpwm6k8fxhd"))))

(define-public pi-coding-agent-bin
  (package
    (name "pi-coding-agent-bin")
    (version %pi-version)
    (source
     %pi-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("." "share/pi-coding-agent"))
      #:phases
      #~(let ((wrap-binary (lambda* (#:key inputs outputs #:allow-other-keys)
                             (use-modules (guix build utils))
                             (let* ((out (assoc-ref outputs "out"))
                                    (pi-dir (string-append out
                                             "/share/pi-coding-agent"))
                                    (pi-bin (string-append pi-dir "/pi"))
                                    (loader (string-append (assoc-ref inputs
                                                                      "libc")
                                             "/lib/ld-linux-x86-64.so.2"))
                                    (patchelf (string-append (assoc-ref inputs
                                                              "patchelf")
                                                             "/bin/patchelf")))
                               ;; patchelf --set-interpreter ONLY: changes the ELF
                               ;; interpreter to the store glibc so the binary is
                               ;; directly executable.  No --set-rpath: the original
                               ;; binary has no missing shared libs, and setting rpath
                               ;; on this 105MB Bun-compiled binary causes corruption
                               ;; (SIGSEGV).  This preserves process.execPath = the
                               ;; real pi binary path, so getThemesDir() correctly
                               ;; resolves theme/dark.json relative to the binary.
                               (chmod pi-bin #o755) ;patchelf needs write access
                               (invoke patchelf "--set-interpreter" loader
                                       pi-bin)
                               ;; entry point in user profile PATH
                               (mkdir-p (string-append out "/bin"))
                               ;; Direct symlink so process.execPath = real binary path
                               (symlink (string-append pi-dir "/pi")
                                        (string-append out
                                                       "/bin/pi-coding-agent"))
                               ;; upstream command name is `pi'; alias so tools that
                               ;; spawn `pi' (e.g. pi-acp-bin) can find it on PATH
                               (symlink "pi-coding-agent"
                                        (string-append out "/bin/pi"))
                               #t))))
          (alist-cons-after 'install
                            'wrap-binary wrap-binary %standard-phases))))
    (native-inputs (list patchelf))
    (synopsis "AI coding agent CLI with read, bash, edit, write tools")
    (description
     "Pi is a coding agent CLI with read, bash, edit, write tools and
session management.  This package wraps the official prebuilt x86_64
GNU binary (a self-contained Bun-compiled executable), exec'd through
the Guix store glibc loader with libstdc++ on its path - no node
runtime or FHS emulation needed.  Config and sessions live under
~/.pi.")
    (home-page "https://github.com/earendil-works/pi")
    (license license:expat)))

;;;
;;; pi-acp-bin — ACP (Agent Client Protocol) adapter for the pi coding agent.
;;;
;;; svkozak/pi-acp is a small TypeScript CLI that bridges pi's internal RPC to
;;; ACP JSON-RPC 2.0 over stdio so ACP editors (Zed, etc.) can drive pi.
;;; Upstream publishes a prebuilt `dist/' via npm `prepack', and tsup bundles
;;; its two deps (@agentclientprotocol/sdk, zod) into a single self-contained
;;; dist/index.js (verified: no external require()).  We therefore take the npm
;;; tarball as source, copy dist/index.js, and run it with `node' - no npm
;;; install, no network at build time.  It spawns the `pi' executable, so we
;;; propagate pi-coding-agent-bin (which now also provides `pi').

(define %pi-acp-version
  "0.0.34")

(define %pi-acp-source
  (origin
    (method url-fetch)
    (uri (string-append "https://registry.npmjs.org/pi-acp/-/pi-acp-"
                        %pi-acp-version ".tgz"))
    (sha256 (base32 "0l16ixhg3r0765cxlh0p8y784r740qczmz6p7psbglmyf6ygcfsb"))))

;; pi-acp ships a prebuilt dist/index.js, and tsup does not finish bundling it:
;; the file still carries bare ESM imports for @agentclientprotocol/sdk, zod
;; and cross-spawn.  cross-spawn entered `dependencies' at 0.0.34, and it is
;; not dependency-free either (which -> isexe, path-key, shebang-command ->
;; shebang-regex), so the whole closure is listed here.  npm never runs in this
;; build, so each import is satisfied by unpacking that package's npm tarball
;; into node_modules beside the script, which is where Node's bare-specifier
;; lookup looks.
;;
;; Bumping pi-acp means re-reading the `dependencies' field of
;; pi-acp-<version> on the registry and updating %pi-acp-deps to match; the
;; versions below are what npm's ranges resolve to today.
(define %pi-acp-deps
  `(("zod" "3.25.76" "0xw3m1qdqbqam3fhxiv8ag9l9kampywwx4gfcjmis36xy02il7wy")
    ("cross-spawn" "7.0.6"
     "1siqxlydjwpihy7klgd15cah56vsmxrdm3q90gndyfj1vh63530q")
    ("which" "2.0.2" "1p2fkm4lr36s85gdjxmyr6wh86dizf0iwmffxmarcxpbvmgxyfm1")
    ("isexe" "2.0.0" "0nc3rcqjgyb9yyqajwlzzhfcqmsb682z7zinnx9qrql8w1rfiks7")
    ("path-key" "3.1.1" "14kvp849wnkg6f3dqgmcb73nnb5k6b3gxf65sgf0x0qlp6n9k2ab")
    ("shebang-command" "2.0.0"
     "0vjmdpwcz23glkhlmxny8hc3x01zyr6hwf4qb3grq7m532ysbjws")
    ("shebang-regex" "3.0.0"
     "13wmb23w5srjpn9xx1c85yk5jbc5z9ypg0iz33h6nv5jdnmapnzy")))

(define (pi-acp-dep-source dep)
  ;; DEP is (name version sha256), straight out of %pi-acp-deps.
  (origin
    (method url-fetch)
    (uri (string-append "https://registry.npmjs.org/"
                        (car dep)
                        "/-/"
                        (car dep)
                        "-"
                        (cadr dep)
                        ".tgz"))
    (sha256 (base32 (caddr dep)))))

(define %pi-acp-sdk-source
  (origin
    (method url-fetch)
    (uri
     "https://registry.npmjs.org/@agentclientprotocol/sdk/-/sdk-0.26.0.tgz")
    (sha256 (base32 "14yzrz07cb3whqagpzgjza6v6ykm9n71r5g9lz36q93msabbbsgj"))))

(define-public pi-acp-bin
  (package
    (name "pi-acp-bin")
    (version %pi-acp-version)
    (source
     %pi-acp-source)
    (build-system copy-build-system)
    (arguments
     (list
      #:validate-runpath? #f
      #:phases
      #~(let ((install (lambda* (#:key inputs outputs #:allow-other-keys)
                         (let* ((out (assoc-ref outputs "out"))
                                (sdk (assoc-ref inputs "sdk-source"))
                                (nm (string-append out "/node_modules")))
                           ;; main adapter script (dist/index.js, already executable)
                           (mkdir-p (string-append out "/bin"))
                           (copy-file "dist/index.js"
                                      (string-append out "/bin/pi-acp"))
                           (chmod (string-append out "/bin/pi-acp") #o555)
                           ;; vendored runtime deps: ESM bare imports resolve
                           ;; through node_modules next to the importing script.
                           ;; The scoped one keeps its @scope directory, the rest
                           ;; are flat exactly as npm would have installed them --
                           ;; which is also how they find *their* dependencies.
                           (let ((dest (string-append nm
                                        "/@agentclientprotocol/sdk")))
                             (mkdir-p dest)
                             (invoke "tar"
                                     "xzf"
                                     sdk
                                     "-C"
                                     dest
                                     "--strip-components=1"))
                           (for-each (lambda (name)
                                       (let ((dest (string-append nm "/" name)))
                                         (mkdir-p dest)
                                         (invoke "tar"
                                                 "xzf"
                                                 (assoc-ref inputs name)
                                                 "-C"
                                                 dest
                                                 "--strip-components=1")))
                                     ;; `quote' is not ceremony: a gexp splices
                                     ;; #$value into *code* position, so a bare
                                     ;; #$(map car %pi-acp-deps) emits
                                     ;; ("zod" "cross-spawn" ...) -- a call whose
                                     ;; operator is the string "zod".
                                     '#$(map car %pi-acp-deps))
                           #t))))
          (modify-phases %standard-phases
            (replace 'install
              install)))))
    (native-inputs (append (list (list "sdk-source" %pi-acp-sdk-source))
                           (map (lambda (dep)
                                  (list (car dep)
                                        (pi-acp-dep-source dep))) %pi-acp-deps)))
    (propagated-inputs (list node pi-coding-agent-bin))
    (synopsis "ACP (Agent Client Protocol) adapter for the pi coding agent")
    (description
     "pi-acp bridges the pi coding agent to the Agent Client Protocol (ACP):
it speaks ACP JSON-RPC 2.0 over stdio to an ACP client (e.g. the Zed editor)
and spawns `pi --mode rpc', translating requests and events between the two.
This packages the upstream prebuilt dist (a single JavaScript file) and runs
it with Node.js; the runtime dependencies it still imports by name
(@agentclientprotocol/sdk, zod and cross-spawn with its own closure) are
vendored into node_modules.")
    (home-page "https://github.com/svkozak/pi-acp")
    (license license:expat)))

;;; ---------------------------------------------------------------------------
;;; casty (sanohiro/casty) — pure-JS Node CLI (npm tarball = prebuilt artifact).
;;; ws lists bufferutil/utf-8-validate as optional native addons; they are not in
;;; the Guix offline npm cache, so we strip optional/peer/dev deps.  ws needs no
;;; real hard deps (pure-JS fallback), so after patch-dependencies promotes peer
;;; deps to `dependencies' we drop that field entirely.
;;; ---------------------------------------------------------------------------
(define-public node-ws
  (package
    (name "node-ws")
    (version "8.22.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://registry.npmjs.org/ws/-/ws-" version
                           ".tgz"))
       (sha256
        (base32 "1j5bwyagz7a0vk0j61ikkfq15ah10ppm0gviqvxfh771nac3g6ya"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          (add-after 'patch-dependencies 'delete-dev-dependencies
            (lambda _
              (modify-json (delete-dev-dependencies))))
          (add-after 'delete-dev-dependencies 'remove-stale-deps
            (lambda _
              (modify-json (lambda (meta)
                             (let ((deps (assoc-ref meta "dependencies")))
                               (if deps
                                   (assoc-remove! meta "dependencies") meta)))))))))
    (home-page "https://github.com/websockets/ws")
    (synopsis
     "Simple to use, blazing fast and thoroughly tested websocket client and server for Node.js")
    (description
     "Simple to use, blazing fast and thoroughly tested websocket client and server for Node.js.")
    (license license:expat)))

(define %oh-my-pi-version
  "18.6.0")

(define %oh-my-pi-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/can1357/oh-my-pi/releases/download/v"
          %oh-my-pi-version "/omp-linux-x64"))
    (sha256 (base32 "0mdddqd9hanzkfypg7hflmfj0qzr95h77cz4md9c3i0fc8668k44"))))

(define-public oh-my-pi-bin
  (package
    (name "oh-my-pi-bin")
    (version %oh-my-pi-version)
    (source
     %oh-my-pi-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("omp-linux-x64" "share/oh-my-pi/omp-linux-x64"))
      #:phases
      #~(let ((wrap-binary (lambda* (#:key inputs outputs #:allow-other-keys)
                             (use-modules (guix build utils))
                             (let* ((out (assoc-ref outputs "out"))
                                    (omp-dir (string-append out
                                                            "/share/oh-my-pi"))
                                    (omp-bin (string-append omp-dir
                                                            "/omp-linux-x64"))
                                    (loader (string-append (assoc-ref inputs
                                                                      "libc")
                                             "/lib/ld-linux-x86-64.so.2"))
                                    (patchelf (string-append (assoc-ref inputs
                                                              "patchelf")
                                                             "/bin/patchelf"))
                                    (gcc-lib (string-append (assoc-ref inputs
                                                                       "gcc")
                                                            "/lib")))
                               ;; patchelf --set-interpreter ONLY (same pattern as
                               ;; pi-coding-agent-bin): turns the embedded bun --compile
                               ;; virtual FS into a real on-disk ELF so the omp worker
                               ;; subprocess can re-exec itself.  No --set-rpath: the
                               ;; binary has no missing shared libs; setting rpath on a
                               ;; 239MB bun-compiled binary corrupts it (SIGSEGV).
                               (chmod omp-bin #o755)
                               (invoke patchelf "--set-interpreter" loader
                                       omp-bin)
                               (mkdir-p (string-append out "/bin"))
                               ;; Wrapper: OMP_NATIVE_LIBRARY_PATH is injected by omp into
                               ;; the LD_LIBRARY_PATH of its inference/sherpa/onnx worker
                               ;; subprocesses (which dlopen libstdc++.so.6 at runtime),
                               ;; exactly matching the upstream Nix derivation's wrapProgram.
                               (call-with-output-file (string-append out
                                                       "/bin/omp")
                                 (lambda (port)
                                   (format port
                                    "#!~a
export OMP_NATIVE_LIBRARY_PATH=\"~a\"
exec \"~a\" \"$@\"
"
                                    (string-append (assoc-ref inputs
                                                              "bash-minimal")
                                                   "/bin/bash") gcc-lib
                                    omp-bin)))
                               (chmod (string-append out "/bin/omp") #o555)
                               #t))))
          (alist-cons-after 'install
                            'wrap-binary wrap-binary %standard-phases))))
    (native-inputs (list patchelf))
    (inputs (list bash-minimal
                  (list gcc "lib")))
    (synopsis
     "Coding agent CLI with multi-model support, LSP, subagents, and eval cells")
    (description
     "Oh My Pi (omp) is a coding agent CLI forked from Pi, rewritten as a
coding-first surface in TypeScript on the Bun runtime.  It provides
multi-model support, persistent Python/JavaScript eval cells, subagents,
slash commands, extensions, and LSP integration.  This package wraps the
official prebuilt self-contained binary (a @code{bun --compile} artifact),
exec'd through the Guix store glibc loader with gcc-lib available for the
inference worker subprocesses that dlopen libstdc++.so.6 at runtime - no
FHS emulation or bun runtime install needed.")
    (home-page "https://omp.sh")
    (license license:expat)))

(define-public casty-bin
  (package
    (name "casty-bin")
    (version "1.3.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@sanohiro/casty/-/casty-" version
             ".tgz"))
       (sha256
        (base32 "0igc4mpqdfvmad8ypys9zh7zdp9x9hl4l4fsnv0hj94xfi11q0j0"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build))))
    (inputs (list node-ws))
    (home-page "https://github.com/sanohiro/casty")
    (synopsis
     "Run a real Chrome browser inside your terminal using CDP and Kitty graphics")
    (description
     "Casty runs a real Chrome browser inside your terminal using CDP screencast and the Kitty graphics protocol.")
    (license license:expat)))

;;; ---------------------------------------------------------------------------
;;; mcode (@minimax-ai/code) — pure-JS Node CLI.  Its only hard deps are thin JS
;;; wrappers (@vscode/ripgrep, @mariozechner/clipboard) around prebuilt native
;;; binaries shipped in *-linux-x64-* npm packages.  Keep only the linux-x64
;;; variant (drop the other 10 platform variants that need ENOTCACHED fetches).
;;; mcode's own optional better-sqlite3 is dropped (native C++ addon) and its
;;; postinstall verification script is removed so npm install succeeds.
;;; ---------------------------------------------------------------------------
(define-public node-vscode-ripgrep-linux-x64
  (package
    (name "node-vscode-ripgrep-linux-x64")
    (version "1.18.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@vscode/ripgrep-linux-x64"
             "/-/ripgrep-linux-x64-" version ".tgz"))
       (sha256
        (base32 "02aadf6rzqyvacg1axlykpls47kwf3byr7m0x672b74zw8jnxh4c"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build))))
    (home-page "https://github.com/microsoft/vscode-ripgrep")
    (synopsis "ripgrep binary for linux-x64 (used by @vscode/ripgrep)")
    (description
     "Prebuilt ripgrep binary for linux-x64, consumed by @vscode/ripgrep.")
    (license license:expat)))

(define-public node-mariozechner-clipboard-linux-x64-gnu
  (package
    (name "node-mariozechner-clipboard-linux-x64-gnu")
    (version "0.3.9")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@mariozechner/clipboard-linux-x64-gnu"
             "/-/clipboard-linux-x64-gnu-" version ".tgz"))
       (sha256
        (base32 "0pmhprb9cmb5ly99c31nvxfiscd2nz3dydr9j5b1168qj954ysqh"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          (add-before 'validate-runpath 'patchelf-addon
            (lambda* (#:key inputs outputs #:allow-other-keys)
              ;; .node is a prebuilt napi addon needing libgcc_s.so.1 and
              ;; the dynamic loader; set RUNPATH accordingly.
              (let* ((out (assoc-ref outputs "out"))
                     (addon (string-append out "/lib/node_modules/"
                             "@mariozechner/clipboard-linux-x64-gnu/"
                             "clipboard.linux-x64-gnu.node"))
                     (rpath (string-append (assoc-ref inputs "glibc") "/lib:"
                                           (assoc-ref inputs "gcc") "/lib")))
                (invoke "patchelf" "--set-rpath" rpath addon)))))))
    (native-inputs (list patchelf))
    (inputs (list glibc
                  (list gcc "lib")))
    (home-page "https://github.com/badlogic/clipboard")
    (synopsis "Prebuilt clipboard native binary for linux-x64-gnu")
    (description
     "Prebuilt napi binary for @mariozechner/clipboard on linux-x64-gnu.")
    (license license:expat)))

(define-public node-vscode-ripgrep
  (package
    (name "node-vscode-ripgrep")
    (version "1.18.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://registry.npmjs.org/@vscode/ripgrep"
                           "/-/ripgrep-" version ".tgz"))
       (sha256
        (base32 "0sch4j3s7ky7yyb54x51lfbh66idnn1na8hvf8asl776ifbwh4kd"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          (add-after 'patch-dependencies 'delete-dev-dependencies
            (lambda _
              (modify-json (delete-dev-dependencies))))
          (add-after 'delete-dev-dependencies 'keep-only-linux-x64
            (lambda _
              (modify-json (lambda (meta)
                             (let ((optional (assoc-ref meta
                                              "optionalDependencies")))
                               (if optional
                                   (assoc-set! meta "optionalDependencies"
                                               (filter (lambda (pair)
                                                         (string=? (car pair)
                                                          "@vscode/ripgrep-linux-x64"))
                                                       optional)) meta)))))))))
    (inputs (list node-vscode-ripgrep-linux-x64))
    (home-page "https://github.com/microsoft/vscode-ripgrep")
    (synopsis "Module for using ripgrep in a Node project")
    (description
     "This package provides a module for using ripgrep in a Node project.")
    (license license:expat)))

(define-public node-mariozechner-clipboard
  (package
    (name "node-mariozechner-clipboard")
    (version "0.3.9")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@mariozechner/clipboard"
             "/-/clipboard-" version ".tgz"))
       (sha256
        (base32 "0fandgc1s8qwyg3njw3xqdj4nzh5d6c1kyfm3lyxzymgxjz6x615"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          (add-after 'patch-dependencies 'delete-dev-dependencies
            (lambda _
              (modify-json (delete-dev-dependencies))))
          (add-after 'delete-dev-dependencies 'keep-only-linux-x64
            (lambda _
              (modify-json (lambda (meta)
                             (let ((optional (assoc-ref meta
                                              "optionalDependencies")))
                               (if optional
                                   (assoc-set! meta "optionalDependencies"
                                               (filter (lambda (pair)
                                                         (string=? (car pair)
                                                          "@mariozechner/clipboard-linux-x64-gnu"))
                                                       optional)) meta)))))))))
    (inputs (list node-mariozechner-clipboard-linux-x64-gnu))
    (home-page "https://github.com/badlogic/clipboard")
    (synopsis "Fork of @crosscopy/clipboard with musl support")
    (description
     "Fork of @crosscopy/clipboard with latest clipboard-rs and musl (Alpine) support.")
    (license license:expat)))

;;; ---------------------------------------------------------------------------
;;; node-better-sqlite3 -- the native addon mcode's session store imports at
;;; runtime (chunk-WOISMRTU.js: `import ... from "better-sqlite3"`).  Dropping
;;; it made `mcode acp` die with "Cannot find package 'better-sqlite3'".
;;;
;;; Upstream compiles it with node-gyp from npm's install script, which
;;; downloads node headers and prebuilt binaries -- impossible offline.  So we
;;; compile it ourselves, mirroring binding.gyp + deps/defines.gypi:
;;;   * src/better_sqlite3.cpp is a single TU that #includes all other .cpp
;;;     files; deps/sqlite3/sqlite3.c is the bundled SQLite amalgamation.
;;;   * Guix's node sets v8_enable_pointer_compression=0 and
;;;     v8_enable_sandbox=0 (see include/node/config.gypi), so no V8 ABI
;;;     defines are needed; headers come from the same `node` input, so the
;;;     addon's ABI matches the interpreter that will dlopen it.
;;;   * node/v8 symbols are intentionally left undefined in the .so -- the
;;;     node binary provides them at dlopen time, hence validate-runpath? #f.
;;; `bindings' (pure JS, an upstream runtime dep) locates the .node under
;;; build/Release/ at load time, so we must not change that layout.
;;;
;;; NOTE: the SQLITE_*/HAVE_* compile defines live as a *quoted literal*
;;; inside the compile-addon phase, not as a module variable: a G-exp `#$'
;;; unquote splices a list value as an EXPRESSION (its head gets called as a
;;; procedure -- "Wrong type to apply" at build time), so module-level lists
;;; of strings cannot be unquoted into phase code.
;;; ---------------------------------------------------------------------------
(define-public node-better-sqlite3
  (package
    (name "node-better-sqlite3")
    (version "13.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://registry.npmjs.org/better-sqlite3"
                           "/-/better-sqlite3-" version ".tgz"))
       (sha256
        (base32 "1jv8d3apzhby0jz0bnkyg04k2h1zmnspyk7crqxznsd4q4ym3q3p"))))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'patch-dependencies 'neutralize-native-build-script
            (lambda _
              ;; Two reasons scripts.install must not survive:
              ;; * it is "prebuild-install || node-gyp rebuild --release",
              ;; which downloads node headers and vendor prebuilt .node
              ;; binaries -- impossible offline;
              ;; * deleting it is NOT enough.  npm treats a package that
              ;; ships a binding.gyp as a native addon and, when no
              ;; install script is defined, runs `node-gyp rebuild'
              ;; itself -- which then fails for want of a Python in the
              ;; build environment.  So the script has to be *replaced*
              ;; by a no-op, which also overrides that implicit build.
              ;; 'compile-addon below is what really produces the .node.
              ;; prebuild-install is only used by that script, so drop the
              ;; dependency too -- otherwise npm would try to install it and
              ;; its many native-download-capable deps at configure time.
              (modify-json (lambda (meta)
                             (let ((s (assoc-ref meta "scripts")))
                               (if s
                                   (begin
                                     (assoc-set! s "install" "true") meta)
                                   (assoc-set! meta "scripts"
                                               '(("install" . "true"))))))
                           (lambda (meta)
                             (let ((d (assoc-ref meta "dependencies")))
                               (if d
                                   (assoc-set! meta "dependencies"
                                               (assoc-remove! d
                                                "prebuild-install")) meta))))))
          ;; chai/mocha/etc. are test-only deps with no store substitute;
          ;; npm --offline would fail ENOTCACHED on them in 'configure.
          (add-after 'patch-dependencies 'delete-dev-dependencies
            (lambda _
              (modify-json (delete-dev-dependencies))))
          (delete 'build)
          ;; The .so deliberately has undefined node/v8 symbols (the host
          ;; binary supplies them at dlopen), which 'validate-runpath would
          ;; choke on.  node-build-system has no #:validate-runpath? keyword
          ;; here, so drop the phase itself.
          (delete 'validate-runpath)
          (add-after 'configure 'compile-addon
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (srfi srfi-1))
              (let* ((node-dir (assoc-ref inputs "node"))
                     (addon-api-dir (assoc-ref inputs "node-addon-api"))
                     (gcc-lib (string-append (assoc-ref inputs "gcc") "/lib"))
                     (sql-defines
                      ;; Verbatim from deps/defines.gypi (generated by
                      ;; upstream deps/download.sh).  A quoted literal, not a
                      ;; module variable: gexp `#$' would splice the list as
                      ;; code (see note above the package).
                      (map (lambda (f)
                             (string-append "-D" f))
                           '("HAVE_INT16_T=1" "HAVE_INT32_T=1"
                             "HAVE_INT8_T=1"
                             "HAVE_STDINT_H=1"
                             "HAVE_UINT16_T=1"
                             "HAVE_UINT32_T=1"
                             "HAVE_UINT8_T=1"
                             "HAVE_USLEEP=1"
                             "SQLITE_DEFAULT_CACHE_SIZE=-16000"
                             "SQLITE_DEFAULT_FOREIGN_KEYS=1"
                             "SQLITE_DEFAULT_MEMSTATUS=0"
                             "SQLITE_DEFAULT_WAL_SYNCHRONOUS=1"
                             "SQLITE_DQS=0"
                             "SQLITE_ENABLE_COLUMN_METADATA"
                             "SQLITE_ENABLE_DBSTAT_VTAB"
                             "SQLITE_ENABLE_DESERIALIZE"
                             "SQLITE_ENABLE_FTS3"
                             "SQLITE_ENABLE_FTS3_PARENTHESIS"
                             "SQLITE_ENABLE_FTS4"
                             "SQLITE_ENABLE_FTS5"
                             "SQLITE_ENABLE_GEOPOLY"
                             "SQLITE_ENABLE_JSON1"
                             "SQLITE_ENABLE_MATH_FUNCTIONS"
                             "SQLITE_ENABLE_PERCENTILE"
                             "SQLITE_ENABLE_RTREE"
                             "SQLITE_ENABLE_STAT4"
                             "SQLITE_ENABLE_UPDATE_DELETE_LIMIT"
                             "SQLITE_LIKE_DOESNT_MATCH_BLOBS"
                             "SQLITE_OMIT_DEPRECATED"
                             "SQLITE_OMIT_PROGRESS_CALLBACK"
                             "SQLITE_OMIT_SHARED_CACHE"
                             "SQLITE_OMIT_TCL_VARIABLE"
                             "SQLITE_SOUNDEX"
                             "SQLITE_THREADSAFE=2"
                             "SQLITE_TRACE_SIZE_LIMIT=32"
                             "SQLITE_USE_URI=0")))
                     ;; binding.gyp's `defines' for the C++ target, new in the
                     ;; 13.x series: NAPI_VERSION picks which node-api surface
                     ;; node-addon-api compiles against, and the two exception
                     ;; flags decide how a throwing call is marshalled.  These
                     ;; are compile-time ABI choices, so they have to match
                     ;; upstream rather than our taste.  binding.gyp also adds
                     ;; -flto to cflags_cc, which is left out on purpose: it
                     ;; only means something when the link step uses -flto too,
                     ;; and here the link is the plain g++ below.
                     (napi-cflags (list "-DNAPI_VERSION=10"
                                   "-DNAPI_DISABLE_CPP_EXCEPTIONS"
                                   "-DNODE_API_SWALLOW_UNTHROWABLE_EXCEPTIONS"
                                   "-fvisibility=hidden"
                                   "-fvisibility-inlines-hidden")))
                ;; 1. SQLite amalgamation (C).
                (apply invoke
                       "gcc"
                       "-c"
                       "deps/sqlite3/sqlite3.c"
                       "-O2"
                       "-std=c11"
                       "-fPIC"
                       (append sql-defines
                               '("-o" "sqlite3.o")))
                ;; 2. the addon: one C++ TU that #includes the rest.
                (apply invoke
                       "g++"
                       "-c"
                       "src/better_sqlite3.cpp"
                       "-O2"
                       "-std=c++20"
                       "-fPIC"
                       "-DNDEBUG"
                       "-I"
                       "src"
                       "-I"
                       "deps/sqlite3"
                       "-I"
                       (string-append node-dir "/include/node")
                       ;; 13.x includes <napi.h>, which lives in the
                       ;; node-addon-api package root -- precisely what
                       ;; binding.gyp's `require('node-addon-api').include'
                       ;; resolves to.  12.x used <node.h>/node_object_wrap and
                       ;; needed nothing of the sort.
                       "-I"
                       (string-append addon-api-dir
                                      "/lib/node_modules/node-addon-api")
                       ;; napi-cflags is part of the *tail* list, not a bare
                       ;; argument in the middle: `apply' splices only its last
                       ;; argument, so (apply invoke "g++" ... flags ...) would
                       ;; hand the whole list to invoke as one argument and die
                       ;; with "Wrong type (expecting string)".
                       (append napi-cflags sql-defines
                               '("-o" "better_sqlite3.o")))
                ;; 3. link with binding.gyp's linux ldflags; sqlite3.o goes
                ;; in statically (that is what deps/sqlite3.gyp's static lib
                ;; target achieves upstream).
                (mkdir-p "build/Release")
                (invoke "g++"
                        "-shared"
                        "-fPIC"
                        "-Wl,-Bsymbolic"
                        "-Wl,--exclude-libs,ALL"
                        "-Wl,-rpath"
                        gcc-lib
                        "-lm"
                        "-lpthread"
                        "-o"
                        "build/Release/better_sqlite3.node"
                        "better_sqlite3.o"
                        "sqlite3.o")))))))
    (inputs (list node node-bindings node-addon-api
                  (list gcc "lib")))
    (native-inputs (list gcc-toolchain))
    (home-page "https://github.com/WiseLibs/better-sqlite3")
    (synopsis "The fastest and simplest library for SQLite in Node.js")
    (description
     "better-sqlite3 exposes SQLite to Node.js through a straightforward,
synchronous API.  Unlike node-sqlite3 it is fully synchronous and ships its
own SQLite build.")
    (license license:expat)))

(define %mcode-version
  "0.6.2")

;;; The npm tarball IS the prebuilt artifact (bundled JS + wasm + native
;;; helpers); both `mcode' (node-build-system install) and `mcode-bin'
;;; (copy + store symlinks, no npm) draw from it.
(define %mcode-source
  (origin
    (method url-fetch)
    (uri (string-append "https://registry.npmjs.org/@minimax-ai/code"
                        "/-/code-" %mcode-version ".tgz"))
    (sha256 (base32 "1iscvgxazl54jdp324mbgxmicih2yfajaby6s91f6anl8wa03lfy"))))

(define-public mcode
  (package
    (name "mcode")
    (version %mcode-version)
    (source
     %mcode-source)
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          ;; The app ships vendor prebuilds (better-sqlite3's
          ;; prebuilds/linuxmusl-x64.node and friends) that reference libstdc++
          ;; and libc.musl-x86_64.so.1 by SONAME with no RUNPATH at all; node
          ;; loads them with dlopen and resolves them itself.  Validating them
          ;; cannot succeed on a non-FHS system and there is nothing to fix in
          ;; the binaries.  node-build-system accepts no #:validate-runpath?
          ;; keyword (it is not among the arguments it takes -- passing one
          ;; aborts evaluation with "Unrecognized keyword"), so the phase has
          ;; to be deleted instead.
          (delete 'validate-runpath)
          (add-before 'patch-dependencies 'promote-better-sqlite3
            ;; 'patch-dependencies' only rewrites entries under
            ;; dependencies/devDependencies/peerDependencies to file: paths;
            ;; npm resolves optionalDependencies itself and silently SKIPS
            ;; them when offline -- which is what left the ACP session store
            ;; without better-sqlite3 at runtime.  Promote it to a hard
            ;; dependency so the node-better-sqlite3 input gets wired in.
            (lambda _
              (modify-json (lambda (meta)
                             (let* ((optional (assoc-ref meta
                                               "optionalDependencies"))
                                    (bs3 (and optional
                                              (assoc-ref optional
                                                         "better-sqlite3"))))
                               (if bs3
                                   (begin
                                     (assoc-set! meta "optionalDependencies"
                                                 (assoc-remove! optional
                                                  "better-sqlite3"))
                                     (assoc-set! meta "dependencies"
                                                 (cons (cons "better-sqlite3"
                                                             bs3)
                                                       (or (assoc-ref meta
                                                            "dependencies")
                                                           '())))) meta))))))
          (add-before 'configure 'remove-postinstall
            (lambda _
              (when (file-exists? "package.json")
                (modify-json (lambda (meta)
                               (let ((s (assoc-ref meta "scripts")))
                                 (if (and s
                                          (assoc-ref s "postinstall"))
                                     (assoc-set! meta "scripts"
                                                 (assoc-remove! s
                                                                "postinstall"))
                                     meta))))))))))
    (inputs (list node-better-sqlite3 node-mariozechner-clipboard
                  node-vscode-ripgrep))
    (home-page "https://www.npmjs.com/package/@minimax-ai/code")
    (synopsis "Minimax Code -- terminal coding agent")
    (description "Minimax Code -- terminal coding agent.")
    (license license:expat)))

;;; ---------------------------------------------------------------------------
;;; mcode-bin -- the same prebuilt npm artifact as `mcode', installed WITHOUT
;;; npm: copy-build-system lays the tree down, the three bare specifiers the
;;; bundled chunks import at runtime (better-sqlite3, @vscode/ripgrep,
;;; @mariozechner/clipboard) are wired in as node_modules symlinks pointing at
;;; their store packages, and bin/ shell wrappers exec `node' on the two
;;; package.json bin entries.  This sidesteps every node-build-system pitfall
;;; (offline optionalDependencies, blocked install scripts).
;;; ---------------------------------------------------------------------------
(define-public mcode-bin
  (package
    (name "mcode-bin")
    (version %mcode-version)
    (source
     %mcode-source)
    (build-system copy-build-system)
    ;; the three node_modules links are x86_64 prebuilts / native addons
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:install-plan
      ;; "." not "package/": the standard 'unpack phase chdirs into the npm
      ;; tarball's single top-level directory, so the package tree IS the
      ;; build's current directory by the time copy-build-system installs.
      ;; (Same shape as terminal-browser-bin and pi-coding-agent-bin.)
      #~'(("." "share/mcode-bin"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'link-node-modules
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (pkg (string-append out "/share/mcode-bin"))
                     (nm (string-append pkg "/node_modules")))
                ;; Node's bare-specifier lookup walks up from the importing
                ;; file's directory, so symlinks in the app's own
                ;; node_modules make the store packages importable with no
                ;; npm install at build- or run-time.
                (mkdir-p (string-append nm "/@vscode"))
                (mkdir-p (string-append nm "/@mariozechner"))
                (symlink (string-append (assoc-ref inputs
                                                   "node-better-sqlite3")
                                        "/lib/node_modules/better-sqlite3")
                         (string-append nm "/better-sqlite3"))
                (symlink (string-append (assoc-ref inputs
                                                   "node-vscode-ripgrep")
                                        "/lib/node_modules/@vscode/ripgrep")
                         (string-append nm "/@vscode/ripgrep"))
                (symlink (string-append (assoc-ref inputs
                                         "node-mariozechner-clipboard")
                          "/lib/node_modules/@mariozechner/clipboard")
                         (string-append nm "/@mariozechner/clipboard"))
                ;; JS helper spawned by relative path (a #!/bin/sh script)
                (chmod (string-append pkg "/internal-bin/mcode-tools") #o755))))
          (add-after 'link-node-modules 'make-wrappers
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (pkg (string-append out "/share/mcode-bin"))
                     (node (string-append (assoc-ref inputs "node") "/bin"))
                     (bash (string-append (assoc-ref inputs "bash-minimal")
                                          "/bin/bash")))
                ;; cli.js / mcode-tools.js carry "#!/usr/bin/env node"
                ;; shebangs; the wrappers exec node by store path instead so
                ;; nothing depends on the user's PATH.
                (mkdir-p (string-append out "/bin"))
                (for-each (lambda (bin)
                            (let ((script (string-append out "/bin/"
                                                         (car bin))))
                              (call-with-output-file script
                                (lambda (port)
                                  (format port
                                          "#!~a\nexec ~a/node \"~a/~a\" \"$@\"\n"
                                          bash
                                          node
                                          pkg
                                          (cdr bin))))
                              (chmod script #o555)))
                          '(("mcode" . "cli.js")
                            ("mcode-tools" . "mcode-tools.js")))))))))
    (inputs (list bash-minimal node node-better-sqlite3
                  node-mariozechner-clipboard node-vscode-ripgrep))
    (home-page "https://www.npmjs.com/package/@minimax-ai/code")
    (synopsis "Minimax Code (prebuilt npm artifact) -- terminal coding agent")
    (description
     "Minimax Code is a terminal coding agent.  This package installs the
official npm release -- bundled JavaScript plus its WASM and native helpers
-- without running npm: the native dependencies are symlinked from the Guix
store into the app's node_modules and the CLI starts through a wrapper
around Node.js.")
    (license license:expat)))

;;; ---------------------------------------------------------------------------
;;; purple-discord — libpurple-2 plugin for Discord (EionRobb/purple-discord).
;;; Single C99 file compiled via the upstream Makefile; installs libdiscord.so
;;; into the libpurple plugin dir. Nix (nixos.purple-discord) pins commit
;;; b7ac72399218d2ce011ac84bb171b572560aa2d2 (unstable-2021-10-17) — we mirror
;;; that pin for reproducibility. QR-code auth (nss + qrencode) is optional
;;; upstream and left disabled; icons/locales (imagemagick/gettext) are also
;;; skipped since the plugin loads fine without them.
;;; ---------------------------------------------------------------------------
(define %purple-discord-commit
  "2ae1e6147cef73ad38079c38dba28b25179567b8")

(define-public purple-discord
  (package
    (name "purple-discord")
    ;; Upstream declares DISCORD_PLUGIN_VERSION "1.0" in libdiscord.c at the
    ;; commit pinned below; the date suffix is that commit's date, since this
    ;; is a snapshot of a repository that tags nothing.
    (version "1.0.2026.09.18") ;unstable-2026-09-18
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/EionRobb/purple-discord/archive/"
             %purple-discord-commit ".tar.gz"))
       (sha256
        (base32 "10c7gal60gpc92izxg60v1ri6cq21jg9ngyfa21qcyw1y5n22x9f"))))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:tests? #f ;no test suite
      #:make-flags
      #~(list "libdiscord.so" ;plugin only; skip icons/locales
              (string-append "DESTDIR="
                             #$output) "CC=gcc")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure) ;Makefile-only, no ./configure
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              ;; Install just the .so; icons/locales are optional and would
              ;; need imagemagick/gettext, so skip them.
              (let ((plugindir (string-append (assoc-ref outputs "out")
                                              "/lib/purple-2")))
                (mkdir-p plugindir)
                (invoke "install" "-m" "0755" "libdiscord.so" plugindir)))))))
    (inputs (list pidgin
                  glib
                  json-glib
                  zlib
                  ;; discord_rsa.c includes qrencode.h: the Makefile's QR-login
                  ;; block is `ifneq ($(USE_QRCODE_AUTH), 0)', i.e. on unless you
                  ;; turn it off, and it unconditionally adds
                  ;; `-DUSE_QRCODE_AUTH' plus `pkg-config --cflags/--libs nss
                  ;; libqrencode'.  Those two pkg-config names are what put nss
                  ;; and qrencode in the inputs -- without them the compile dies
                  ;; on the missing header (passing USE_QRCODE_AUTH=0 would
                  ;; build, at the cost of removing the only login method
                  ;; upstream documents).
                  nss
                  qrencode))
    (native-inputs
     ;; gcc-toolchain provides cc/gcc (upstream Makefile uses `CC ?= gcc`);
     ;; pkg-config lets the Makefile resolve `pkg-config purple glib-2.0
     ;; json-glib-1.0 zlib` and find the libpurple headers.
     (list gcc-toolchain pkg-config))
    (synopsis "Discord plugin for libpurple/Pidgin")
    (description
     "purple-discord is a chat plugin that lets Pidgin/libpurple (and Finch or
Bitlbee) connect to Discord.  It implements the Discord HTTP/JSON API directly
and supports servers, channels, direct messages, reactions, and message
history.  This package builds the libpurple-2 shared library (libdiscord.so)
from source against the store libpurple headers.")
    (home-page "https://github.com/EionRobb/purple-discord")
    (license license:gpl3+)))

;;; rdircd — Reliable Discord-client IRC Daemon (mk-fg).
;;; Single Python script that translates Discord channels/DMs into an IRC
;;; server you can connect to with any IRC client.  Only runtime dep is
;;; python-aiohttp; its many Python deps (yarl, multidict, aiosignal, ...)
;;; are propagated and live in separate store paths, so we list them all as
;;; inputs and union their site-packages into PYTHONPATH in the wrapper.
;;; The script resolves rdircd.unicode-emojis.txt.gz relative to its own
;;; __file__ and reads its own source for --conf-dump-defaults, so the
;;; real script file and the data file must be installed adjacent.

(define %rdircd-commit
  "57e2307fae006142953967084852278a859bac60")
;; Snapshot version of the commit above: YYYYMMDD of its author date, plus a
;; counter for the case where a day carries two bumps.  The previous value
;; read 20250913.0 for a commit dated 2026-09-13 -- the year was simply wrong.
(define %rdircd-version
  "20260927.0")

(define-public rdircd
  (package
    (name "rdircd")
    (version %rdircd-version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/mk-fg/"
                           "reliable-discord-client-irc-daemon/archive/"
                           %rdircd-commit ".tar.gz"))
       (sha256
        (base32 "059qp3f2wyafqz0l4ffgd773qw6r6h6n51s7kf6cyjlvf5yf2p6v"))))
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("rdircd" "lib/rdircd/rdircd")
          ("rdircd.unicode-emojis.txt.gz" "lib/rdircd/")
          ("rdircd.defaults.ini" "share/rdircd/"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils)
                           (ice-9 ftw)
                           (ice-9 regex))
              (let* ((out (assoc-ref outputs "out"))
                     (rdir (string-append out "/lib/rdircd"))
                     (python (assoc-ref inputs "python"))
                     (python-bin (string-append python "/bin/python3"))
                     (bash (string-append (assoc-ref inputs "bash-minimal")
                                          "/bin/bash"))
                     ;; Python packages whose site-packages must be on
                     ;; PYTHONPATH for aiohttp + its deps to import.
                     (py-inputs (list "python-aiohttp"
                                      "python-aiohappyeyeballs"
                                      "python-aiosignal"
                                      "python-attrs"
                                      "python-frozenlist"
                                      "python-multidict"
                                      "python-propcache"
                                      "python-yarl"
                                      "python-aiodns"
                                      "python-backports-zstd"
                                      "python-brotli"))
                     (sp-for (lambda (name)
                               (let ((base (assoc-ref inputs name)))
                                 (if base
                                     (string-append base "/lib/python"
                                                    (car (scandir (string-append
                                                                   base "/lib")
                                                                  (lambda (d)
                                                                    (string-prefix?
                                                                     "python"
                                                                     d))))
                                                    "/site-packages") ""))))
                     (pythonpath (string-join (filter (lambda (s)
                                                        (not (string-null? s)))
                                                      (map sp-for py-inputs))
                                              ":")))
                ;; Install real script + data file adjacent (required for
                ;; __file__-relative emoji resolution).
                (mkdir-p rdir)
                (install-file "rdircd" rdir)
                (install-file "rdircd.unicode-emojis.txt.gz" rdir)
                ;; Defaults config: user reference (not needed at runtime).
                (mkdir-p (string-append out "/share/rdircd"))
                (install-file "rdircd.defaults.ini"
                              (string-append out "/share/rdircd"))
                ;; Wrapper: sets PYTHONPATH for aiohttp + deps, then execs the
                ;; real script via python3, preserving __file__ as the real path.
                (mkdir-p (string-append out "/bin"))
                (call-with-output-file (string-append out "/bin/rdircd")
                  (lambda (port)
                    (display (string-append "#!"
                                            bash
                                            "\n"
                                            "export PYTHONPATH="
                                            pythonpath
                                            "${PYTHONPATH:+:$PYTHONPATH}\n"
                                            "exec "
                                            python-bin
                                            " "
                                            rdir
                                            "/rdircd \"$@\"\n") port)))
                (chmod (string-append out "/bin/rdircd") #o555)
                #t))))))
    (inputs (list python
                  python-aiohttp
                  python-aiohappyeyeballs
                  python-aiosignal
                  python-attrs
                  python-frozenlist
                  python-multidict
                  python-propcache
                  python-yarl
                  python-aiodns
                  python-backports-zstd
                  python-brotli))
    (native-inputs (list bash-minimal))
    (synopsis
     "Use Discord via any IRC client (Reliable Discord-client IRC Daemon)")
    (description
     "rdircd is a daemon that translates Discord channels, DMs, and threads
into an IRC server on a local port, allowing you to use Discord from any IRC
client (weechat, irssi, bouncers, etc.).  It supports reactions, message
history, typing notifications, multiple guilds, forums/threads, voice-chat
activity notifications, and inline emoji/mention resolution.")
    (home-page "https://github.com/mk-fg/reliable-discord-client-irc-daemon")
    (license license:wtfpl2)))

;;;
;;; brow6el-bin — CEF-based terminal web browser with Sixel/Kitty graphics
;;;
;;; brow6el embeds Chromium via CEF (Chromium Embedded Framework) and
;;; renders web pages offscreen, converting them to Sixel or Kitty
;;; graphics protocol output in the terminal.  It features vim-style
;;; modal keyboard control, hint-mode link navigation, mouse emulation,
;;; bookmarks, user scripts, and a JS console.
;;;
;;; The CEF binary distribution is ~294 MiB (libcef.so + resources);
;;; the brow6el C++ sources are only ~15 files compiled with cmake.
;;; The wrapper script cd's into the share dir so CEF can find its
;;; .pak resources and icudtl.dat at runtime.
;;;

(define %brow6el-commit
  ;; v0.3.5 tag -- the latest real release.  The previous recipe pinned
  ;; unreleased `main' HEAD and mislabelled it "0.3.6", which upstream never
  ;; published (brow6el.dev's newest tag is v0.3.5).
  "ec0bc3fad3ef1d67e290dddfa82c54862486f84d")

(define %brow6el-version
  "0.3.5")

(define %brow6el-cef-version
  "148.0.7+g5b12d32+chromium-148.0.7778.96")

(define cef-dist
  (package
    (name "cef-binary-dist")
    (version %brow6el-cef-version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://cef-builds.spotifycdn.com/cef_binary_"
                           %brow6el-cef-version
                           "_linux64_beta_minimal.tar.bz2"))
       (sha256
        (base32 "10b18sji7km57z7ad627p8za2s31yvcjca7nmsm8rzyhr0nigjah"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((out #$output)
                (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                (bzip2 (string-append (assoc-ref %build-inputs "bzip2")
                                      "/bin/bzip2")))
            (mkdir-p out)
            (setenv "PATH"
                    (string-append (dirname tar) ":"
                                   (dirname bzip2)))
            (invoke tar
                    "xjf"
                    #$source
                    "-C"
                    out
                    "--strip-components=1")))))
    (native-inputs (list tar bzip2))
    (synopsis "CEF binary distribution (prebuilt Chromium Embedded Framework)")
    (description
     "Prebuilt Chromium Embedded Framework (CEF) binary distribution used by
brow6el-bin.  Contains libcef.so, the CEF runtime resources (.pak, .dat,
locales) and the cmake find modules required to compile CEF-based apps.")
    (home-page "https://cef-builds.spotifycdn.com/")
    (license license:bsd-3)))

(define-public brow6el-bin
  (package
    (name "brow6el-bin")
    (version %brow6el-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://tangled.org/janantos.tngl.sh/brow6el.git")
             (commit %brow6el-commit)))
       (sha256
        (base32 "0fmwrw8l0yxfy35lk7qk304yannynjn2y1aarx11lbh80nlr26aw"))))
    (build-system cmake-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs (list pkg-config))
    (arguments
     (list
      ;; No #:configure-flags here, which is what a reader will look for first.
      ;; brow6el's CMakeLists says
      ;; set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef_binary" CACHE PATH ...)
      ;; set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")
      ;; find_package(CEF REQUIRED)
      ;; so CEF is located by a *cache* variable whose default is a path under
      ;; the source tree -- not by the CEF_ROOT environment variable.  (CMP0074's
      ;; `*_ROOT' hint applies to config-file packages through
      ;; CMAKE_PREFIX_PATH, not to a set(... CACHE) default; that is why an
      ;; earlier revision died with "Could not find a package configuration file
      ;; provided by \"CEF\"".)  An attempt to seed the cache with
      ;; #:configure-flags #~(list (string-append "-DCEF_ROOT=" (getenv "CEF_ROOT")))
      ;; looks right and cannot work: cmake-build-system evaluates
      ;; #:configure-flags in the builder's let-bindings, *before* any phase
      ;; runs, so getenv returns #f and string-append aborts the build.  Hence
      ;; 'build-cef-wrapper below unpacks the dist to exactly the path the
      ;; default expects, and no flag is needed.
      #:phases
      #~(modify-phases %standard-phases
          ;; The CEF "minimal" binary distribution ships the libcef_dll_wrapper
          ;; *sources* (in libcef_dll/) but not the compiled .a.  The upstream
          ;; download_cef.sh builds it with `cmake .. && make libcef_dll_wrapper`
          ;; inside a writable copy of the dist (the input is in the read-only
          ;; store).  We do the same into ${source}/cef_binary, which is both
          ;; writable and precisely where brow6el's CMakeLists looks by default;
          ;; the phase runs before 'configure, so the working directory is still
          ;; the source directory (configure is what chdirs into ./build).
          (add-before 'configure 'build-cef-wrapper
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils)
                           (srfi srfi-1))
              (let* ((cef-src (assoc-ref inputs "cef-binary-dist"))
                     (work (string-append (getcwd) "/cef_binary"))
                     ;; delete-duplicates is the SRFI-1 name.  There is no
                     ;; delete-dups in Guile, Guix or srfi-1, and CI run
                     ;; 37183041125 died in this phase with "Unbound variable:
                     ;; delete-dups" -- the first line of this let*, so nothing
                     ;; else in the phase had run yet.
                     (lib-dirs (delete-duplicates (append (filter file-exists?
                                                           (map (lambda (i)
                                                                  (string-append
                                                                   (cdr i)
                                                                   "/lib"))
                                                                inputs))
                                                          (list (string-append
                                                                 (assoc-ref
                                                                  inputs "nss")
                                                                 "/lib/nss")
                                                                (string-append
                                                                 work
                                                                 "/Release"))))))
                (mkdir-p work)
                (copy-recursively cef-src work)
                (mkdir-p (string-append work "/build"))
                (with-directory-excursion (string-append work "/build")
                  (invoke "cmake" "-DCMAKE_BUILD_TYPE=Release" work)
                  (invoke "make" "-j" "1" "libcef_dll_wrapper"))
                ;; libcef.so has RUNPATH=$ORIGIN, so when linking the executable
                ;; against it ld cannot resolve libcef.so's own NEEDED entries
                ;; (glib, atk, atspi, cairo, cups, gbm, expat ...).  -Wl,-rpath-link
                ;; adds each input's lib dir to ld's search for those second-order
                ;; dependencies (no DT_RUNPATH change, runtime is already handled
                ;; by the install-cef-resources wrapper).
                (setenv "LDFLAGS"
                        (string-join (map (lambda (d)
                                            (string-append "-Wl,-rpath-link,"
                                                           d)) lib-dirs) " "))
                ;; Not used by CMake (see the note above) -- install-cef-resources
                ;; below reads it to find the .so, .pak and locale files.  setenv
                ;; persists across phases because the whole build is one process.
                (setenv "CEF_ROOT" work)
                (format #t "CEF_ROOT set to ~a~%" work))))
          (add-after 'install 'install-cef-resources
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (share (string-append out "/share/brow6el"))
                     (cef (getenv "CEF_ROOT"))
                     (bash (string-append (assoc-ref inputs "bash-minimal")
                                          "/bin/bash"))
                     (loader (string-append (assoc-ref inputs "libc")
                                            "/lib/ld-linux-x86-64.so.2"))
                     (rpath (string-append share
                                           ":"
                                           (assoc-ref inputs "gcc")
                                           "/lib:"
                                           (string-join (map (lambda (p)
                                                               (string-append (assoc-ref
                                                                               inputs
                                                                               p)
                                                                "/lib"))
                                                             '("libx11"
                                                               "libxcb"
                                                               "libxcomposite"
                                                               "libxdamage"
                                                               "libxext"
                                                               "libxfixes"
                                                               "libxrandr"
                                                               "libxkbcommon"
                                                               "glib"
                                                               "nspr"
                                                               "nss"
                                                               "cairo"
                                                               "pango"
                                                               "at-spi2-core"
                                                               "cups"
                                                               "dbus"
                                                               "eudev"
                                                               "alsa-lib"
                                                               "mesa"
                                                               "expat"
                                                               "zlib"
                                                               "fontconfig"))
                                                        ":")
                                           ":"
                                           (assoc-ref inputs "nss")
                                           "/lib/nss")))
                ;; Install the compiled brow6el binary into share/
                (mkdir-p share)
                (install-file (string-append out "/bin/brow6el") share)
                ;; Remove the build-tree copy so we don't ship duplicates.
                (delete-file (string-append out "/bin/brow6el"))
                ;; Copy CEF runtime resources into share/
                (for-each (lambda (f)
                            (if (equal? (basename f) "locales")
                                (begin
                                  (mkdir-p (string-append share "/locales"))
                                  (for-each (lambda (pak)
                                              (copy-file pak
                                                         (string-append share
                                                          "/locales/"
                                                          (basename pak))))
                                            (find-files f "\\.pak$")))
                                (copy-file f
                                           (string-append share "/"
                                                          (basename f)))))
                          (find-files (string-append cef "/Release")
                                      (lambda (f _)
                                        (not (equal? (basename f)
                                                     "chrome-sandbox")))))
                (for-each (lambda (f)
                            (copy-file f
                                       (string-append share "/"
                                                      (basename f))))
                          (find-files (string-append cef "/Resources")
                                      (lambda (f stat)
                                        (or (string-suffix? ".pak" f)
                                            (string-suffix? ".dat" f)))))
                ;; Copy locales from CEF Resources
                (when (file-exists? (string-append cef "/Resources/locales"))
                  (mkdir-p (string-append share "/locales"))
                  (for-each (lambda (pak)
                              (copy-file pak
                                         (string-append share "/locales/"
                                                        (basename pak))))
                            (find-files (string-append cef
                                                       "/Resources/locales")
                                        "\\.pak$")))
                ;; Copy brow6el JS/HTML assets
                (for-each (lambda (f)
                            (copy-file f
                                       (string-append share "/"
                                                      (basename f))))
                          (find-files "."
                                      (lambda (f _)
                                        (or (string-suffix? ".js" f)
                                            (string-suffix? ".html" f)))))
                ;; Copy bundled scripts/ directory
                (when (file-exists? "scripts")
                  (copy-recursively "scripts"
                                    (string-append share "/scripts")))
                ;; Copy the run_brow6el.sh helper
                (when (file-exists? "run_brow6el.sh")
                  (copy-file "run_brow6el.sh"
                             (string-append share "/run_brow6el.sh"))
                  (chmod (string-append share "/run_brow6el.sh") #o755))
                ;; patchelf: set interpreter + rpath on brow6el and libcef.so
                (for-each (lambda (elf)
                            (when (file-exists? elf)
                              (invoke "patchelf" "--set-interpreter" loader
                                      elf)
                              (invoke "patchelf" "--set-rpath" rpath elf)))
                          (list (string-append share "/brow6el")
                                (string-append share "/libcef.so")
                                (string-append share "/libEGL.so")
                                (string-append share "/libGLESv2.so")))
                ;; Wrapper: cd into share dir then exec brow6el
                (mkdir-p bin)
                (call-with-output-file (string-append out "/bin/brow6el")
                  (lambda (port)
                    (format port
                     "#!~a~@
cd \"~a\"~@
export LD_LIBRARY_PATH=\"~a:$LD_LIBRARY_PATH\"~@
export VK_ICD_FILENAMES=\"~a/vk_swiftshader_icd.json\"~@
exec \"~a/brow6el\" \"$@\"~%"
                     bash
                     share
                     share
                     share
                     share)))
                (chmod (string-append out "/bin/brow6el") #o755)))))))
    (inputs (list bash-minimal
                  (list gcc "lib")
                  cef-dist
                  libsixel
                  libx11
                  libxcb
                  libxcomposite
                  libxdamage
                  libxext
                  libxfixes
                  libxrandr
                  libxkbcommon
                  glib
                  nspr
                  nss
                  cairo
                  pango
                  at-spi2-core
                  cups
                  dbus
                  eudev
                  alsa-lib
                  mesa
                  expat
                  zlib
                  fontconfig))
    (synopsis "Terminal web browser with Sixel and Kitty graphics support")
    (description
     "Brow6el is a full-featured web browser for the terminal using CEF
(Chromium Embedded Framework).  It renders web pages offscreen via Chromium
and converts them to Sixel or Kitty graphics protocol output.  Features
include vim-style modal keyboard control, hint-mode link navigation,
keyboard-driven mouse emulation, grid-jump positioning, element inspection,
bookmarks, user scripts, a JavaScript console, DNS-over-HTTPS, per-site zoom,
and download management.  Requires a graphics-capable terminal (foot, wezterm,
kitty, ghostty, mlterm, xterm, etc.).")
    (home-page "https://tangled.org/janantos.tngl.sh/brow6el.git")
    (license license:expat)))

;; One version for one upstream release line.  Cline tags the CLI as
;; cli-vX.Y.Z, publishes X.Y.Z to npm as @cline/* (which is what cline-bin
;; repackages) and the same number drives cline-baseline's git tag, so the
;; number is written exactly once here and (sane-packages cline) reads it back
;; through the module import it already has -- via the #:export at the top of
;; this module, since a plain `define' is private to its module in Guile and
;; cline.scm would otherwise see an unbound variable.  Importing the other way
;; would have made the dependency between the two modules circular.
(define %cline-version
  "3.0.68")

(define-public cline-bin
  (package
    (name "cline-bin")
    (version %cline-version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@cline/cli-linux-x64/-/cli-linux-x64-"
             version ".tgz"))
       (sha256
        (base32 "1ccav6m9rj2gvgb7jq796mm4v5k8jd8wzqh7755r76pbj2894yd9"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((tar (string-append #$tar "/bin/tar"))
                (gzip (string-append #$gzip "/bin/gzip"))
                (patchelf (string-append #$patchelf "/bin/patchelf"))
                (output #$output))
            (setenv "PATH"
                    (string-append #$gzip "/bin"))
            (mkdir-p output)
            (mkdir-p (string-append output "/bin"))
            (invoke tar "xzf"
                    #$source)
            (copy-recursively "package"
                              (string-append output "/libexec/cline"))
            (let ((bin (string-append output "/bin/cline"))
                  (target (string-append output "/libexec/cline/bin/cline")))
              (symlink target bin)
              (chmod target #o755)
              (invoke patchelf "--set-interpreter"
                      (string-append #$glibc "/lib/ld-linux-x86-64.so.2")
                      target)
              (rename-file bin
                           (string-append output "/bin/cline-bin"))
              (call-with-output-file bin
                (lambda (port)
                  (format port
                   "#!~a~%
if ! grep -qw avx2 /proc/cpuinfo 2>/dev/null; then
  echo \"Error: Cline v3.0+ requires a CPU with AVX2 support (e.g., Haswell or newer).\" >&2
  echo \"Your CPU appears to be missing AVX2 instructions.\" >&2
  exit 1
fi
exec ~a/bin/cline-bin \"$@\"
"
                   (string-append #$bash-minimal "/bin/bash") output)))
              (chmod bin #o555))))))
    (native-inputs (list tar gzip patchelf))
    (inputs (list glibc))
    (synopsis "Autonomous coding agent CLI (Cline)")
    (description
     "Cline is an autonomous coding agent CLI capable of creating/editing files,
running commands, using the browser, and more.  This package wraps the prebuilt
linux-x64 binary distribution.")
    (home-page "https://cline.bot")
    (license license:asl2.0)))

(define-public qoder-cli-bin
  (package
    (name "qoder-cli-bin")
    (version "1.1.65")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://qoder-ide.oss-accelerate.aliyuncs.com/qodercli/releases/"
             version "/qodercli-linux-x64.tar.gz"))
       (sha256
        (base32 "137w44d6nf831j6sy2y98bic5xjkk3r8883s0i87hx8jr2wvp7ml"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((tar (string-append #$tar "/bin/tar"))
                (gzip (string-append #$gzip "/bin/gzip"))
                (patchelf (string-append #$patchelf "/bin/patchelf"))
                (output #$output))
            (setenv "PATH"
                    (string-append #$gzip "/bin"))
            (mkdir-p output)
            (mkdir-p (string-append output "/bin"))
            (invoke tar "xzf"
                    #$source)
            ;; The archive contains a single `qodercli` binary at the root
            (let ((bin (string-append output "/bin/qodercli")))
              (copy-file "qodercli" bin)
              (chmod bin #o755)
              (invoke patchelf "--set-interpreter"
                      (string-append #$glibc "/lib/ld-linux-x86-64.so.2") bin)
              ;; Also symlink as qoder
              (symlink "qodercli"
                       (string-append output "/bin/qoder")))))))
    (native-inputs (list tar gzip patchelf))
    (inputs (list glibc))
    (synopsis
     "Qoder AI CLI tool - Terminal-based AI assistant for code development")
    (description
     "Qoder CLI is a terminal-based AI assistant and coding agent that helps you
build software, inspect code, and execute workflows.")
    (home-page "https://qoder.com")
    (license (license:non-copyleft "https://qoder.com"
              "Proprietary Qoder license — unfree, non-redistributable."))))

(define-public qoder-desktop-bin
  (package
    (name "qoder-desktop-bin")
    (version "0.4.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://download.qoder.com/qoder-app/releases/"
                           version "/Qoder-linux-amd64.deb"))
       (sha256
        (base32 "02q50dxhj7xynms1h1h3jcvnsvb9qmr3h3jfiizmiv6wkx1v938y"))))
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:validate-runpath? #f ;bundled Electron helpers have no RUNPATH
      #:install-plan
      #~'(("opt/Qoder" "lib/Qoder")
          ;; keep layout: libffmpeg.so etc.
          ;; resolve via $ORIGIN
          ("usr/share" "share"))
      #:phases
      ;; Plain alist procedures instead of modify-phases: the daemon's
      ;; staged (guix build utils) has a version mismatch that chokes on
      ;; nested clauses.
      #~(alist-cons-after 'patchelf-binaries
                          'create-wrapper
                          (lambda* (#:key inputs #:allow-other-keys)
                            ;; The deb's .desktop points at /opt/Qoder; redirect to our bin
                            ;; (installed as `qoder-desktop` so it never shadows the qoder-cli
                            ;; `qoder` command).
                            (substitute* (string-append #$output
                                          "/share/applications/qoder.desktop")
                              (("/opt/Qoder/qoder")
                               (string-append #$output "/bin/qoder-desktop")))
                            ;; Electron dlopen()s native addons (node-pty's pty.node, keytar,
                            ;; sharp) whose DT_NEEDED (libstdc++, libgcc_s, ...) are resolved
                            ;; against LD_LIBRARY_PATH, not the main binary's RUNPATH.  Export
                            ;; the same store lib dirs that go into the RUNPATH.
                            (wrap-program (string-append #$output
                                                         "/lib/Qoder/qoder")
                              `("LD_LIBRARY_PATH" suffix
                                ,(delete #f
                                         (map (lambda (name)
                                                (string-append (assoc-ref
                                                                inputs name)
                                                               (if (string=?
                                                                    name "nss")
                                                                   "/lib/nss"
                                                                   "/lib")))
                                              (list #$@%zcode-rpath-inputs))))
                              `("XDG_DATA_DIRS" suffix
                                (,(string-append #$adwaita-icon-theme "/share") ,
                                 (string-append #$gsettings-desktop-schemas
                                                "/share")
                                 ,(string-append #$shared-mime-info "/share")))
                              `("PATH" suffix
                                (,(string-append #$xdg-utils "/bin"))))
                            ;; Entry point named `qoder-desktop` (the desktop app), distinct
                            ;; from the `qoder` command owned by qoder-cli-bin.
                            (mkdir-p (string-append #$output "/bin"))
                            (symlink (string-append #$output
                                                    "/lib/Qoder/qoder")
                                     (string-append #$output
                                                    "/bin/qoder-desktop")))
                          (alist-cons-after 'install
                                            'patchelf-binaries
                                            (lambda* (#:key inputs
                                                      #:allow-other-keys)
                                              (let* ((rpath (string-append
                                                             "$ORIGIN:"
                                                             (string-join (delete
                                                                           #f
                                                                           (map (lambda 
                                                                                        (name)
                                                                                  
                                                                                  
                                                                                  (string-append
                                                                                   (assoc-ref
                                                                                    inputs
                                                                                    name)
                                                                                   ;; nss installs into lib/nss
                                                                                   
                                                                                   
                                                                                   (if
                                                                                    (string=?
                                                                                     name
                                                                                     "nss")
                                                                                    "/lib/nss"
                                                                                    "/lib")))
                                                                            (list #$@%zcode-rpath-inputs)))
                                                                          ":"))))
                                                (for-each (lambda (file)
                                                            (unless (or (string-suffix?
                                                                         ".so"
                                                                         file)
                                                                        (string-contains
                                                                         file
                                                                         ".so."))
                                                              ;; Executables: fix loader + RUNPATH (Guix has no
                                                              ;; /lib64/ld-linux, unlike NixOS).
                                                              (invoke
                                                               "patchelf"
                                                               "--set-interpreter"
                                                               (string-append (assoc-ref
                                                                               inputs
                                                                               "libc")
                                                                "/lib/ld-linux-x86-64.so.2")
                                                               file)
                                                              (invoke
                                                               "patchelf"
                                                               "--set-rpath"
                                                               rpath file)))
                                                          (list (string-append #$output
                                                                 "/lib/Qoder/qoder")
                                                                (string-append #$output
                                                                 "/lib/Qoder/chrome_crashpad_handler")
                                                                (string-append #$output
                                                                 "/lib/Qoder/chrome-sandbox")))))
                                            (alist-replace 'unpack
                                                           (lambda* (#:key
                                                                     source
                                                                     #:allow-other-keys)
                                                             ;; Unpack the .deb: ar x -> data.tar.xz.
                                                             (invoke "ar" "x"
                                                                     source)
                                                             (invoke "tar"
                                                              "xf"
                                                              "data.tar.xz"))
                                                           %standard-phases)))))
    (native-inputs (list binutils patchelf))
    (inputs (list (list gcc "lib") ;libgcc_s.so.1
                  adwaita-icon-theme
                  alsa-lib
                  at-spi2-core
                  bash-minimal
                  cairo
                  cups
                  dbus
                  eudev
                  expat
                  fontconfig
                  freetype
                  glib
                  gsettings-desktop-schemas
                  gtk+
                  libnotify
                  libsecret
                  libx11
                  libxcb
                  libxcomposite
                  libxcursor
                  libxdamage
                  libxext
                  libxfixes
                  libxkbcommon
                  libxrandr
                  mesa
                  nspr
                  nss
                  pango
                  pipewire
                  pulseaudio
                  shared-mime-info
                  wayland
                  xdg-utils))
    (synopsis
     "Qoder desktop - agent workbench for human and AI software teams")
    (description
     "Qoder is a desktop application for agentic software development, based
on Electron.  This is a repackaged prebuilt binary; it is proprietary software
and is not endorsed by Guix upstream.")
    (home-page "https://qoder.com")
    (license (license:non-copyleft "https://qoder.com"
              "Proprietary Qoder license — unfree, non-redistributable."))))

;;; DeepSeek Harness publishes nothing but an npm tarball: its GitHub releases
;;; have no assets and the registry ships no prebuilt platform package, so the
;;; tarball itself is the source.  node-build-system does not fit here: it
;;; installs a package's dependencies from *Guix* packages, while dsh's runtime
;;; closure on linux-x64 is 513 npm tarballs.  So the closure is vendored from
;;; (dsh-modules) -- one named build input per tarball -- and %dsh-manifest
;;; below tells the build where each one goes, which reproduces
;;; `npm install -g' without any network access at build time.
(define %dsh-build-inputs
  ;; Guix wants its inputs as lists; (dsh-modules) keeps them as pairs.
  (map (lambda (entry)
         (list (car entry)
               (cdr entry))) %dsh-node-inputs))

(define (dsh-manifest-row kind a b)
  ;; One line of the manifest.  Fields are separated by a tab because neither
  ;; an npm install path nor a build-input label may contain one.
  (string-append kind
                 "\t"
                 a
                 "\t"
                 b
                 "\n"))

(define %dsh-manifest
  ;; What to unpack where, plus the bin links npm would create.  This is a
  ;; file the build reads rather than a value spliced into the gexp: Guix
  ;; serializes a list of lists as bare data, which the builder then tries to
  ;; evaluate as a procedure call.
  (plain-file "dsh-install-manifest"
              (string-append (apply string-append
                                    (map (lambda (entry)
                                           (dsh-manifest-row "unpack"
                                                             (car entry)
                                                             (cdr entry)))
                                         %dsh-node-install-plan))
                             (apply string-append
                                    (map (lambda (entry)
                                           (dsh-manifest-row "link"
                                                             (car entry)
                                                             (cadr entry)))
                                         %dsh-node-bin-links)))))

(define-public dsh
  (package
    (name "dsh")
    (version "0.2.0-rc.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-" version
             ".tgz"))
       (sha256
        (base32 "0nc8yfpypiarpdwgcw9hz6g67ixwpc31ryf1b9b8mmjw8iy889xx"))))
    (build-system trivial-build-system)
    (inputs (list bash node procps))
    (native-inputs (append (list (list "tar" tar)
                                 (list "gzip" gzip)
                                 ;; Every input carries its own label: a list
                                 ;; that mixes labelled and unlabelled entries
                                 ;; makes Guix label the labelled ones twice.
                                 (list "dsh-manifest" %dsh-manifest))
                           %dsh-build-inputs))
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 match)
                       (ice-9 rdelim))
          (let* ((out (assoc-ref %outputs "out"))
                 (lib (string-append out "/lib/node_modules/@deepseek-ai/dsh"))
                 (bash (string-append (assoc-ref %build-inputs "bash")
                                      "/bin/bash"))
                 (sh (string-append (assoc-ref %build-inputs "bash") "/bin/sh"))
                 (ps (string-append (assoc-ref %build-inputs "procps")
                                    "/bin/ps"))
                 (tar (string-append (assoc-ref %build-inputs "tar")
                                     "/bin/tar"))
                 (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin"))
                 (node (string-append (assoc-ref %build-inputs "node")
                                      "/bin/node"))
                 (tab (char-set #\tab)))
            ;; tar(1) delegates -z to gzip(1) and the trivial build system
            ;; puts no input on PATH.
            (setenv "PATH"
                    (string-append gzip ":"
                                   (getenv "PATH")))
            (define (unpack tarball target)
              (mkdir-p target)
              (with-directory-excursion target
                (invoke tar "xzf" tarball "--strip-components=1")))
            (define manifest
              (call-with-input-file (assoc-ref %build-inputs "dsh-manifest")
                (lambda (port)
                  (let loop
                    ((line (read-line port))
                     (rows '()))
                    (if (eof-object? line)
                        (reverse rows)
                        (loop (read-line port)
                              (cons line rows)))))))
            (unpack (assoc-ref %build-inputs "source") lib)
            (for-each (lambda (row)
                        (match (string-split row tab)
                          (("unpack" input path)
                           (unpack (assoc-ref %build-inputs input)
                                   (string-append lib "/" path)))
                          (_ #t))) manifest)
            ;; npm makes each declared bin entry executable and links it
            ;; into the .bin directory holding the package.  That directory
            ;; is created first: the entry it links to is reached through
            ;; it, and rewriting a file needs its parent to exist.
            (for-each (lambda (row)
                        (match (string-split row tab)
                          (("link" link target)
                           (let* ((file (string-append lib "/" link))
                                  (bin (dirname file))
                                  (prog (string-append bin "/" target)))
                             (mkdir-p bin)
                             (substitute* prog
                               (("^#!/usr/bin/env node.*" all)
                                (string-append "#!" node)))
                             (chmod prog #o755)
                             (symlink target file)))
                          (_ #t))) manifest)
            ;; A few helpers execve(2) a program by absolute path instead
            ;; of looking it up in PATH, so point them at the store.
            (for-each (lambda (file)
                        (substitute* file
                          (("\"/bin/bash\"")
                           (string-append "\"" bash "\""))
                          (("\"/bin/sh\"")
                           (string-append "\"" sh "\""))
                          (("\"/bin/ps\"")
                           (string-append "\"" ps "\""))))
                      (append (list (string-append lib
                                     "/node_modules/@deepseek-ai/dsh-terminal-bash/lib/index.js")
                                    (string-append lib
                                     "/node_modules/@deepseek-ai/dsh-api-terminal-controller/lib/index.js"))
                              ;; The runner's file name carries a build hash.
                              (find-files (string-append lib
                                           "/node_modules/@deepseek-ai/dsh-subprocess-local/lib")
                                          "\\.js$")))
            ;; The launcher is plain JavaScript, so the "binary" is node
            ;; reading it.
            (mkdir-p (string-append out "/bin"))
            (let ((prog (string-append out "/bin/dsh")))
              (call-with-output-file prog
                (lambda (port)
                  (format port "#!~a\nexec ~a ~a/lib/bin.js \"$@\"\n" bash
                          node lib)))
              (chmod prog #o555))
            (for-each (lambda (file)
                        (install-file (string-append lib "/" file)
                                      (string-append out "/share/doc/dsh")))
                      (list "LICENSE" "README.md" "README.zh.md"))))))
    (synopsis "Open-source agent harness developed by DeepSeek AI")
    (description "DeepSeek Harness: Everything is a Plugin.")
    (home-page "https://github.com/deepseek-ai/deepseek-harness")
    (license license:expat)))

;;;
;;; cua-driver-bin — Cua Driver daemon (trycua/cua)
;;;
;;; Cua Driver is the background daemon that lets agents inspect and drive a
;;; desktop: it exposes X11/AT-SPI window state and synthetic input over an MCP
;;; server (`cua-driver serve').  Upstream ships no source-only Linux build
;;; path for us here -- the workspace is 15 Rust crates -- but it does publish
;;; a fully static-ified x86_64 binary on every release tag, and its own
;;; installer is just "download that tarball and symlink the binary"
;;; (https://cua.ai/driver/_install-rust.sh).  So we take the same tarball:
;;; patch the ELF interpreter onto the store glibc, point RUNPATH at the X11
;;; libraries the binary needs, and symlink it into bin.
;;;
;;; The release tarball also carries libcua_driver_sdk.so and
;;; cua_driver_node_runtime.node.  Neither is referenced by the daemon (verified
;;; with `strings'): they are for the Python/TypeScript SDKs, and they stay put
;;; next to the binary so an SDK can dlopen them from a known location.
;;; Everything must live side by side because the daemon finds its
;;; cua-cursor-theme helper relative to its own executable.

(define %cua-driver-version
  "0.32.0")

(define %cua-driver-source
  (origin
    (method url-fetch)
    ;; Two Linux assets are published per release and hold the same files; the
    ;; "-binary" one is a flat archive, which Guix's unpacker would mistake for
    ;; a single-root tree (its only directory, wayland-helper, becomes the
    ;; source root), so take the directory archive.
    (uri (string-append
          "https://github.com/trycua/cua/releases/download/cua-driver-rs-v"
          %cua-driver-version "/cua-driver-rs-" %cua-driver-version
          "-linux-x86_64.tar.gz"))
    (sha256 (base32 "12gqs7mafif3q1fim1kcsxiic32gn95pzl525ml6mdrq5i2n73lr"))))

(define-public cua-driver-bin
  (package
    (name "cua-driver-bin")
    (version %cua-driver-version)
    (source
     %cua-driver-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (inputs
     ;; `cua-driver' needs libX11, libXi and libxkbcommon; both executables
     ;; need libgcc_s, which lives in gcc's "lib" output.
     (list (list gcc "lib") libx11 libxi libxkbcommon))
    (native-inputs (list glibc patchelf))
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("." "lib/cua-driver"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-and-link
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (pkg (string-append out "/lib/cua-driver"))
                     (patchelf (string-append (assoc-ref inputs "patchelf")
                                              "/bin/patchelf"))
                     (loader (string-append (assoc-ref inputs "glibc")
                                            "/lib/ld-linux-x86-64.so.2"))
                     (rpath (string-join (map (lambda (input)
                                                (string-append (assoc-ref
                                                                inputs input)
                                                               "/lib"))
                                              '("gcc" "libx11" "libxi"
                                                "libxkbcommon")) ":")))
                ;; patchelf rewrites the binary in place, so it needs write
                ;; permission on the freshly copied file.
                (for-each (lambda (prog)
                            (chmod prog #o755)
                            (invoke patchelf
                                    "--set-interpreter"
                                    loader
                                    "--set-rpath"
                                    rpath
                                    prog))
                          (list (string-append pkg "/cua-driver")
                                (string-append pkg "/cua-cursor-theme")))
                (mkdir-p (string-append out "/bin"))
                ;; A symlink, not a wrapper script, keeps /proc/self/exe inside
                ;; lib/cua-driver where the helper binaries are.
                (symlink (string-append pkg "/cua-driver")
                         (string-append out "/bin/cua-driver"))))))))
    (synopsis "Desktop automation daemon that lets AI agents drive a GUI")
    (description
     "Cua Driver is the background service behind the Cua computer-use stack.
It runs an MCP server (@command{cua-driver serve}) that exposes window and
accessibility state, screenshots, synthetic keyboard/mouse input, browser
control and session recording for a Linux desktop, and it is what the Cua
SDKs connect to.  This package wraps the official prebuilt x86_64 release
binary; the daemon talks to X11 and to AT-SPI over the session D-Bus, so a
graphical session must be running for it to do anything.  Configuration and
state live in @file{~/.cua-driver}.")
    (home-page "https://github.com/trycua/cua")
    (license license:expat)))
