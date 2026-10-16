;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Khalid Rafi <khaalidrafi@gmail.com>

;;; Commentary:
;;;
;;; AutoClaw (https://autoclaw.z.ai) is Z.ai's local desktop client for its
;;; OpenClaw gateway: an Electron application, distributed for Linux as an
;;; AppImage.  Upstream serves several Linux artifacts, and they are not the
;;; same build:
;;;
;;;   * an AppImage under the zwork/updates stream, version 2.0.x, which is
;;;     what the download page offers for x64 and ARM64;
;;;   * .deb files on a 1.18.x stream, which are older.
;;;
;;; This module packages the AppImage, the way nonguix repackages Signal or
;;; Bitwarden from their vendor binaries.  The difference from a .deb is the
;;; container: an AppImage is not an archive to be unpacked but an ELF
;;; runtime with a squashfs payload appended, and a Guix build can neither
;;; mount nor execute the vendor runtime, so the build extracts the payload
;;; with unsquashfs instead.
;;;
;;; Updating: bump %version and refresh both hashes in %autoclaw-builds.
;;; A sha512 of each payload is published next to it in
;;; latest-linux.yml, which is a way to confirm a hash before downloading
;;; the whole file.
;;;
;;; Code:

(define-module (sane-packages autoclaw)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml))

(define %version
  "2.0.3")

;;; Like the vendor .deb of zcode-bin, upstream serves one AppImage per
;;; architecture under one URL pattern, with a different payload and a
;;; different hash each, so the source URI is chosen from the system being
;;; built for.  This is not cross-compilation: a binary package of this kind
;;; wants the matching artifact on the matching machine.
(define %autoclaw-builds
  `(("x86_64-linux" "x64" . "1v5bwcxp5jxaakq2xs1bgd8n843sxwzj56yrgvip06fr3rabjqy6")
    ("aarch64-linux" "arm64" . "0rpah4ficxrhy8bfj5cm491svnx4pk7ddb0z2qsbn6s1xfiks62m")))

(define (autoclaw-source)
  (let* ((entry (or (assoc (%current-system) %autoclaw-builds)
                    (car %autoclaw-builds)))
         (arch (cadr entry))
         (hash (cddr entry)))
    (origin
      (method url-fetch)
      (uri (string-append
            "https://autoglm-public-oss.z.ai/zwork/updates/production/official/linux-"
            arch
            "/AutoClaw-"
            %version
            "-"
            arch
            ".AppImage"))
      (file-name (string-append "autoclaw-bin-" %version "-" arch ".AppImage"))
      (sha256 (base32 hash)))))

;;; Libraries the bundle needs to find through the RUNPATH set in the
;;; patchelf phase below; nss installs into lib/nss, everything else into
;;; lib.  The set is the Electron/GTK stack the AppImage's own binaries
;;; declare as NEEDED, the same closure zcode-bin carries because both apps
;;; are Electron and both bundle their own helpers under $ORIGIN.
(define %autoclaw-rpath-inputs
  '("alsa-lib" "at-spi2-core"
    "cairo"
    "cups"
    "dbus"
    "eudev"
    "expat"
    "fontconfig"
    "freetype"
    "glib"
    "gtk+"
    "libnotify"
    "libsecret"
    "libx11"
    "libxcb"
    "libxcomposite"
    "libxcursor"
    "libxdamage"
    "libxext"
    "libxfixes"
    "libxkbcommon"
    "libxrandr"
    "mesa"
    "nspr"
    "nss"
    "pango"
    "pipewire"
    "pulseaudio"
    "wayland"
    "gcc"))

(define-public autoclaw-bin
  (package
    (name "autoclaw-bin")
    (version %version)
    (source
     (autoclaw-source))
    (build-system copy-build-system)
    (supported-systems (map car %autoclaw-builds))
    (arguments
     (list
      #:validate-runpath? #f ;the same bundled helpers zcode-bin carries:
      ;; libEGL.so and friends have no RUNPATH of their own and are loaded
      ;; by name through the main binary's $ORIGIN.
      ;; (ice-9 binary-ports) is what provides get-bytevector-n for the
      ;; unpack phase's ELF-header read.  copy-build-system's default
      ;; modules are only ((guix build copy-build-system)
      ;; (guix build utils)) -- see guix/build-system/copy.scm -- and
      ;; get-bytevector-n is not among the default bindings: without
      ;; this import the phase died with "Unbound variable:
      ;; get-bytevector-n" (CI run 38571771850).
      ;;
      ;; (rnrs bytevectors) is the second half of the same fix, and the
      ;; earlier claim that bytevector-u8-ref "is core and worked" was
      ;; never exercised: evaluation reaches the field accessor only
      ;; AFTER get-bytevector-n returns (the header read is the first
      ;; let* binding), so run 38571771850 died before the accessor was
      ;; ever touched.  Adding binary-ports alone moved the failure to
      ;; the next unbound symbol:
      ;;
      ;; Unbound variable: bytevector-u8-ref
      ;;
      ;; (CI run 38705403478, still inside phase 'unpack', one field call
      ;; in).  The bytevector accessors (bytevector-u8-ref and
      ;; bytevector-length, both used by this phase) live in
      ;; (rnrs bytevectors), the module Guix's own build-side code
      ;; (guix/build/syscalls.scm among others) imports for the same
      ;; family of procedures.
      #:modules '((guix build copy-build-system)
                  (guix build utils)
                  (ice-9 binary-ports)
                  (rnrs bytevectors))
      #:install-plan
      ;; The payload is the app directory, and everything in it is found
      ;; relative to the main binary ($ORIGIN) or to the resources/ tree,
      ;; so it is kept side by side under one directory rather than split
      ;; across outputs.  usr/share is the payload's icon tree, installed
      ;; where the icon theme looks for it; the .desktop entry at the
      ;; payload root is handled by the last phase, which rewrites its
      ;; Exec to the store before installing it.
      #~'(("squashfs-root" "lib/AutoClaw")
          ("squashfs-root/usr/share" "share"))
      #:phases
      ;; Phases are built with plain alist procedures instead of modify-phases,
      ;; for the same reason as in zcode-bin: the daemon's staged
      ;; (guix build utils) has a modify-phases/%modify-phases version
      ;; mismatch that chokes on multiple -- and even nested -- clauses.
      ;; A let* chain, one binding per phase, keeps each of them closable on
      ;; its own line.
      #~(let* ((after-unpack (alist-replace 'unpack
                                            (lambda* (#:key source
                                                      #:allow-other-keys)
                                              ;; An AppImage of type 2 is the vendor's ELF
                                              ;; runtime with a squashfs filesystem
                                              ;; appended.  Parsing the ELF header is the
                                              ;; whole trick: a type-2 payload starts
                                              ;; immediately after the runtime's section
                                              ;; header table, whose position and size the
                                              ;; header itself carries, so the offset is
                                              ;; computed from the file instead of being
                                              ;; pinned -- the runtime differs per
                                              ;; architecture and the offset moves with
                                              ;; every upstream rebuild.
                                              (define (field header off size)
                                                (let loop
                                                  ((i (- size 1))
                                                   (n 0))
                                                  (if (< i 0) n
                                                      (loop (- i 1)
                                                            (+ (* n 256)
                                                               (bytevector-u8-ref
                                                                header
                                                                (+ off i)))))))
                                              (define (appimage-payload-offset)
                                                (let* ((header (call-with-input-file source
                                                                 (lambda (port)
                                                                   (get-bytevector-n
                                                                    port 64))))
                                                       (shoff (field header 40
                                                                     8))
                                                       (shentsize (field
                                                                   header 58 2))
                                                       (shnum (field header 60
                                                                     2)))
                                                  (when (or (eof-object?
                                                             header)
                                                            (< (bytevector-length
                                                                header) 64))
                                                    (error
                                                     "AppImage too short for an ELF header"
                                                     source))
                                                  (+ shoff
                                                     (* shentsize shnum))))
                                              (let ((offset (appimage-payload-offset)))
                                                ;; Read the superblock only: validates
                                                ;; both the computed offset and the
                                                ;; payload, and fails the build rather
                                                ;; than unpacking into a wrong tree.
                                                (invoke "unsquashfs" "-s" "-o"
                                                        (number->string offset)
                                                        source)
                                                (invoke "unsquashfs"
                                                        "-f"
                                                        "-d"
                                                        "squashfs-root"
                                                        "-o"
                                                        (number->string offset)
                                                        source)))
                                            %standard-phases))
               ;; MUST run after 'install, not after 'unpack: everything in
               ;; this phase -- and in the two phases chained after it --
               ;; operates on the *output* tree ($out/lib/AutoClaw/*,
               ;; $out/share/applications), which copy-build-system only
               ;; populates during 'install.  Before that the payload sits
               ;; in the build directory as ./squashfs-root, so patchelf
               ;; would die with "getting info about .../lib/AutoClaw/
               ;; AutoClaw2: No such file or directory" (the same trap
               ;; zcode-bin's phase documents).
               (with-patchelf (alist-cons-after 'install
                                                'patchelf-binaries
                                                (lambda* (#:key inputs
                                                          #:allow-other-keys)
                                                  ;; The ELF interpreter's file name is per-architecture
                                                  ;; (ld-linux-x86-64.so.2, ld-linux-aarch64.so.1), so
                                                  ;; look it up instead of naming it: this package declares
                                                  ;; more than x86_64.
                                                  (let* ((libc (assoc-ref
                                                                inputs "libc"))
                                                         (interpreter (find-files
                                                                       (string-append
                                                                        libc
                                                                        "/lib")
                                                                       "^ld(-linux.*)?\\.so"))
                                                         ;; The bundle's own helpers are loaded by name
                                                         ;; through $ORIGIN; every Guix library it needs
                                                         ;; has to be reachable from the RUNPATH as well.
                                                         (rpath (string-append
                                                                 "$ORIGIN:"
                                                                 (string-join (delete
                                                                               #f

                                                                               
                                                                               (map (lambda 
                                                                                            (name)
                                                                                      (let 
                                                                                           (
                                                                                            (path
                                                                                             (assoc-ref
                                                                                              inputs
                                                                                              name)))
                                                                                        
                                                                                        
                                                                                        (and
                                                                                         path

                                                                                         
                                                                                         (string-append
                                                                                          path

                                                                                          
                                                                                          (if
                                                                                           (string=?
                                                                                            name
                                                                                            "nss")
                                                                                           "/lib/nss"
                                                                                           "/lib")))))

                                                                                
                                                                                (list #$@%autoclaw-rpath-inputs)))
                                                                  ":"))))
                                                    (unless (pair? interpreter)
                                                      (error
                                                       "no ELF interpreter found in"
                                                       libc))
                                                    ;; Shared objects get no interpreter to set, and their
                                                    ;; own DT_RUNPATH would have to name every library
                                                    ;; they load; the bundle's do not, and
                                                    ;; #:validate-runpath? #f above is what lets that
                                                    ;; stand.  Only the executables are worth rewriting:
                                                    ;; the main app binary, the crashpad handler and the
                                                    ;; sandbox helper, which are the ELF files the payload
                                                    ;; carries outside of its bundled libraries.
                                                    (for-each (lambda (file)
                                                                (invoke
                                                                 "patchelf"
                                                                 "--set-interpreter"
                                                                 (car
                                                                  interpreter)
                                                                 file)
                                                                (invoke
                                                                 "patchelf"
                                                                 "--set-rpath"
                                                                 rpath file))
                                                              (list (string-append #$output
                                                                     "/lib/AutoClaw/AutoClaw2")
                                                                    (string-append #$output
                                                                     "/lib/AutoClaw/chrome_crashpad_handler")
                                                                    (string-append #$output
                                                                     "/lib/AutoClaw/chrome-sandbox")))))
                                                after-unpack))
               (with-wrapper (alist-cons-after 'patchelf-binaries
                                               'create-wrapper
                                               (lambda _
                                                 (wrap-program (string-append #$output
                                                                "/lib/AutoClaw/AutoClaw2")
                                                   `("XDG_DATA_DIRS" suffix
                                                     (,(string-append #$adwaita-icon-theme
                                                        "/share") ,(string-append #$gsettings-desktop-schemas
                                                                    "/share")
                                                      ,(string-append #$shared-mime-info
                                                        "/share")))
                                                   `("PATH" suffix
                                                     (,(string-append #$xdg-utils
                                                                      "/bin"))))
                                                 ;; The AppImage's entry point is AppRun, a script that
                                                 ;; runs AutoClaw2 in the payload root, and upstream
                                                 ;; ships no separate command: AutoClaw is installed
                                                 ;; under the name the product is called, and the
                                                 ;; .desktop entry below is pointed at it.
                                                 (mkdir-p (string-append #$output
                                                           "/bin"))
                                                 (symlink (string-append #$output
                                                           "/lib/AutoClaw/AutoClaw2")
                                                          (string-append #$output
                                                           "/bin/autoclaw")))
                                               with-patchelf)))
          (alist-cons-after 'create-wrapper
                            'fix-desktop-entry
                            (lambda _
                              ;; The payload's own entry is
                              ;; `Exec=AppRun --no-sandbox %U': AppRun is the
                              ;; AppImage runtime's script, which expects
                              ;; its payload next to itself.  Rewriting the
                              ;; Exec to the store is what keeps the menu
                              ;; entry working; MimeType, StartupWMClass and
                              ;; Icon are upstream's and are kept, because
                              ;; the zwork: scheme handler and the AutoClaw2
                              ;; icon are what make the entry useful from a
                              ;; launcher.
                              (install-file (string-append #$output
                                             "/lib/AutoClaw/AutoClaw2.desktop")
                                            (string-append #$output
                                             "/share/applications"))
                              (rename-file (string-append #$output
                                            "/share/applications/AutoClaw2.desktop")
                                           (string-append #$output
                                            "/share/applications/autoclaw.desktop"))
                              (substitute* (string-append #$output
                                            "/share/applications/autoclaw.desktop")
                                (("^Exec=.*")
                                 (string-append "Exec="
                                                #$output "/bin/autoclaw %U"))))
                            with-wrapper))))
    (native-inputs (list squashfs-tools))
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
    (home-page "https://autoclaw.z.ai")
    (synopsis
     "Local desktop client for Z.ai's OpenClaw gateway (prebuilt binary)")
    (description
     "AutoClaw is Z.ai's desktop client for the OpenClaw gateway: an
Electron application that runs the OpenClaw agent locally, with the model
and agent services served from Z.ai.  This package installs the vendor
build from the AppImage upstream publishes for Linux; there is no build
from source to offer, since upstream distributes only the built app.
chrome-sandbox cannot be setuid inside the store, as with every Electron
repackaging here, so the app relies on unprivileged user namespaces or on
being passed @code{--no-sandbox}.")
    ;; The .deb of the older 1.18 stream carries the same app and says
    ;; `License: MIT' in its control file; the AppImage payload ships no
    ;; first-party license text of its own beyond Electron's and Chromium's
    ;; notices, and upstream publishes no repository, so the .deb's own
    ;; statement is the honest description of the repackaged work.
    (license license:expat)))

;;; autoclaw.scm ends here
