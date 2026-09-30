;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright © 2026 Khalid Rafi <khaalidrafi@gmail.com>

;;; Commentary:
;;;
;;; ZCode (https://zcode.z.ai) is Z.ai's AI coding workspace: a terminal agent,
;;; a desktop app and a browser UI, all built from one pnpm/TypeScript monorepo
;;; (https://github.com/zai-org/ZCode, Apache-2.0).  This module provides the
;;; two packages Guix needs for it, because upstream's two distribution channels
;;; have nothing in common:
;;;
;;;   zcode      compiles the terminal agent from the Apache-2.0 sources with
;;;              upstream's own scripts (tsc + esbuild), and runs the resulting
;;;              bundle on Guix's Node.
;;;
;;;   zcode-bin  repackages the vendor .deb for the desktop app, the way nonguix
;;;              repackages Signal or Bitwarden.
;;;
;;; Why the source build is the CLI and not the desktop app: the desktop app
;;; would additionally need Electron (upstream downloads a prebuilt binary in a
;;; postinstall hook), roughly 1300 more lockfile entries, and upstream's
;;; `prepare:remote-assets' step, which fetches prebuilt runtime assets from
;;; Z.ai's CDN with no fixed-output derivation behind it.  The CLI's closure is
;;; 349 npm tarballs, which is the same order of magnitude as dsh already
;;; carries in (sane-packages dsh-modules), and its bundle needs nothing but
;;; Node.
;;;
;;; How the source build gets its dependencies: Guix cannot run `pnpm install'
;;; offline, and a networked install would not be reproducible, so
;;; (sane-packages zcode-modules) -- generated from upstream's own
;;; pnpm-lock.yaml by scripts/gen-zcode-node-tree.py -- hands the build one
;;; hash-verified origin per tarball plus the exact symlink graph pnpm would
;;; have created.  %zcode-build-manifest below turns those tables into the
;;; instructions; the builder is a small interpreter for that manifest.
;;;
;;; Updating: bump %VERSION and %ZCODE-COMMIT, refresh the two .deb hashes in
;;; %ZCODE-BIN-BUILDS, then regenerate zcode-modules.scm as its header
;;; describes.  Hashes are nix-base32, i.e. plain `guix hash' output;
;;; `guix hash -f base32' prints RFC 4648 and will be rejected.
;;;
;;; Code:

(define-module (sane-packages zcode)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
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
  #:use-module (gnu packages node)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (ice-9 match)
  #:use-module (sane-packages zcode-modules)
  ;; Exported for qoder-desktop-bin in (sane-packages custom), which is the same
  ;; kind of Electron binary and needs the same runtime libraries.  This is a
  ;; plain `export' rather than `define-public' because the name is data, not a
  ;; package, and tests/check-static.sh reads define-public to find packages.
  #:export (%zcode-rpath-inputs))

(define %version
  "3.14.3")

;;; Tag v3.14.3.  Pinned by commit rather than tag: a tag can be moved, and
;;; git-fetch has to resolve the object name anyway.
(define %zcode-commit
  "29628c9acdb81b703bbd4080c207a0e7ce5e276e")

(define %zcode-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/zai-org/ZCode")
          (commit %zcode-commit)))
    (file-name (string-append "zcode-" %version "-checkout"))
    (sha256 (base32 "13y4k09cbxng011s805zxw0hk6kk99nvn7vgdwk1fsqzmablidp0"))))

;;;
;;; Libraries an Electron build needs at runtime: everything it links against
;;; (DT_NEEDED) or dlopen()s -- GTK, NSS, X11, Mesa, PulseAudio.  Guix's
;;; equivalent of a Nix buildInputs list; shared with qoder-desktop-bin, which
;;; is the same kind of binary.
;;;
(define %zcode-rpath-inputs
  '("alsa-lib" "at-spi2-core"
    "cairo"
    "cups"
    "dbus"
    "eudev"
    "expat"
    "fontconfig-minimal"
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

;;;
;;; zcode: the terminal agent, built from source.
;;;

(define (manifest-line fields)
  "Return one tab-separated manifest line from the strings in FIELDS."
  (string-append (string-join fields "\t") "\n"))

(define (manifest-block kind rows)
  "Emit every row in ROWS under manifest command KIND."
  (apply string-append
         (map (lambda (row)
                (manifest-line (cons kind row))) rows)))

(define %zcode-build-manifest
  ;; What the build does, as a file rather than as data spliced into the gexp:
  ;; a couple of thousand strings spliced that way make the .drv unreadable and
  ;; every dependency bump a diff in the wrong place.
  ;;
  ;; Block order *is* build order, and it matters: a tarball has to be on disk
  ;; before the .bin entry that points into it can be chmodded, and the whole
  ;; tree has to exist before anything is compiled.
  (plain-file "zcode-build-manifest"
              (string-append
               ;; One directory per lockfile snapshot -- two packages that differ
               ;; only in how their peers resolved are two directories -- so the
               ;; input label is derived from the install path, not the name.
               (manifest-block "unpack"
                               (map reverse %zcode-node-install-plan))
               ;; Upstream patches three of its dependencies; two are in this
               ;; closure.  The .patch files come from the source tree, which is
               ;; already unpacked by now.
               (manifest-block "patch" %zcode-node-patches)
               ;; The dependency graph pnpm would have built: one symlink per
               ;; edge inside .pnpm, the two flat views, and the @zcode/*
               ;; workspace links.
               (manifest-block "sym" %zcode-node-links)
               (manifest-block "sym" %zcode-workspace-links)
               ;; node_modules/.bin entries: how a package's build script reaches
               ;; tsc, esbuild and vite by name.
               (manifest-block "bin" %zcode-node-bin-links)
               ;; Each workspace's own `build' script, dependencies first.  This
               ;; is the schedule `turbo run build' would compute, spelled out so
               ;; the build needs no build system of upstream's own.
               (manifest-block "script" %zcode-workspace-build-scripts))))

(define-public zcode
  (package
    (name "zcode")
    (version %version)
    (source
     %zcode-source)
    (build-system trivial-build-system)
    ;; The dependency table was filtered for linux-x64/glibc: esbuild, turbo and
    ;; the TUI's native addons only have an x64 tarball in it.  Building for
    ;; aarch64 means re-running scripts/gen-zcode-node-tree.py with TARGET set
    ;; there, on an aarch64 machine.
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 match)
                       (ice-9 rdelim))
          (let* ((out (assoc-ref %outputs "out"))
                 (lib (string-append out "/lib/zcode"))
                 (source (assoc-ref %build-inputs "source"))
                 (manifest (assoc-ref %build-inputs "manifest"))
                 (node (string-append (assoc-ref %build-inputs "node")
                                      "/bin/node"))
                 (bash (string-append (assoc-ref %build-inputs "bash")
                                      "/bin/bash"))
                 (tar (string-append (assoc-ref %build-inputs "tar")
                                     "/bin/tar"))
                 (patch (string-append (assoc-ref %build-inputs "patch")
                                       "/bin/patch"))
                 (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin"))
                 (bin (string-append (assoc-ref %build-inputs "coreutils")
                                     "/bin")))
            ;; Nothing any build script may exec is on PATH by default in a
            ;; trivial build.  A '#!/usr/bin/env node' shebang -- which
            ;; is how npm writes its own bin shims -- needs `env' *and* `node'
            ;; findable, so both go into a shim directory of ours.
            (mkdir-p "shim/bin")
            (symlink node "shim/bin/node")
            (symlink (string-append bin "/env") "shim/bin/env")
            (setenv "PATH"
                    (string-append (getcwd)
                                   "/shim/bin:"
                                   gzip
                                   ":"
                                   (dirname tar)
                                   ":"
                                   (dirname patch)
                                   ":"
                                   bin))
            ;; Some tools refuse to start without a HOME, and the sandbox gives
            ;; them one that does not exist.
            (setenv "HOME"
                    (getcwd))
            ;; scripts/builtin-provider-config.mjs bakes the model endpoint into
            ;; the bundle at build time, and defaults to a local :11434 unless
            ;; ZCODE_ENV says otherwise.  Released builds are production.
            (setenv "ZCODE_ENV" "production")
            (define (read-rows file)
              (call-with-input-file file
                (lambda (port)
                  (let loop
                    ((line (read-line port))
                     (rows '()))
                    (if (eof-object? line)
                        (reverse rows)
                        (loop (read-line port)
                              (cons line rows)))))))
            (define (perform work line)
              (match (string-split line #\tab)
                (("unpack" label path)
                 (mkdir-p path)
                 ;; Every npm tarball has exactly one top-level directory, which
                 ;; is why one strip-components rule fits all of them.
                 (invoke tar
                         "xzf"
                         (assoc-ref %build-inputs label)
                         "--strip-components=1"
                         "-C"
                         path))
                (("patch" path file)
                 (let ((patch-file (string-append work "/" file)))
                   (with-directory-excursion path
                     ;; -p1 because these are `git diff' patches against the
                     ;; unpacked package, which is what pnpm's
                     ;; patchedDependencies applies them as.
                     (invoke patch
                             "-p1"
                             "--forward"
                             "--silent"
                             "-i"
                             patch-file))))
                (("sym" path target)
                 (mkdir-p (dirname path))
                 (symlink target path))
                (("bin" path target)
                 (mkdir-p (dirname path))
                 (symlink target path)
                 ;; npm marks the program a bin entry points at executable; tar
                 ;; hands it over without the bit set.  Read the link rather than
                 ;; chmod the path: Guile's chmod follows links, and a broken one
                 ;; would fail the build instead of showing what is wrong.
                 (let ((prog (false-if-exception (canonicalize-path (string-append
                                                                     (dirname
                                                                      path)
                                                                     "/"
                                                                     (symlink-target
                                                                      path))))))
                   (when prog
                     (chmod prog #o755))))
                (("script" directory command)
                 (with-directory-excursion directory
                   ;; npm and turbo run a package's script with that package's
                   ;; node_modules/.bin at the front of PATH -- that is how a
                   ;; build script saying `tsc' reaches the compiler.  The
                   ;; workspace root's .bin is next: upstream installs with
                   ;; node-linker=hoisted, so most bins are collected there.
                   (let ((path (getenv "PATH")))
                     (setenv "PATH"
                             (string-append (getcwd) "/node_modules/.bin:"
                                            work "/node_modules/.bin:" path))
                     (format #t ">>> ~a: ~a~%" directory command)
                     (invoke bash "-c" command)
                     (setenv "PATH" path))))
                (_ #f)))
            ;; The workspace is both the build tree and the installed payload:
            ;; Node resolves dependencies relative to the bundle, so the
            ;; node_modules tree has to sit next to it at run time too.  So it
            ;; is built where it will be installed -- the output directory is
            ;; writable during the build -- and never copied.
            (with-directory-excursion "work"
              (copy-recursively source ".")
              (for-each (lambda (line)
                          (perform (getcwd) line))
                        (read-rows manifest)))
            (mkdir-p (dirname lib))
            (rename-file "work" lib)
            ;; The bundle is plain JavaScript with a node shebang, so the
            ;; "binary" is Node reading it.
            (mkdir-p (string-append out "/bin"))
            (let ((prog (string-append out "/bin/zcode")))
              (call-with-output-file prog
                (lambda (port)
                  (format port
                   "#!~a~%exec ~a ~a/apps/zcode-cli/packages/cli/dist/zcode.cjs \"$@\"~%"
                   bash node lib)))
              (chmod prog #o555))
            (let ((doc (string-append out "/share/doc/zcode")))
              (mkdir-p doc)
              (for-each (lambda (file)
                          (install-file (string-append lib "/" file) doc))
                        (list "LICENSE" "THIRD-PARTY-NOTICES.md")))))))
    (inputs
     ;; What the bundle needs once it is installed: Node to read it and Bash for
     ;; the shell tools it spawns.  Labels, not just packages -- %build-inputs is
     ;; keyed by the first field of a labelled input, and the builder looks
     ;; programs up by name.  Using "node" rather than "node-lts" also keeps the
     ;; builder working when the channel's Node is renamed by a bump.
     (list (list "bash" bash-minimal)
           (list "node" node-lts)))
    (native-inputs
     ;; Tarballs are build-time only: they are unpacked into $out, so nothing
     ;; refers to them once the build is done.  Everything here is labelled,
     ;; including the tools the builder execs, because a list that mixes
     ;; labelled and unlabelled entries makes Guix label the labelled ones
     ;; twice -- the same trap dsh's inputs avoid.  coreutils is the full
     ;; package rather than coreutils-minimal for one file: `env', which npm's
     ;; bin shims need in their shebangs, and none of this reaches the
     ;; installed closure anyway.
     (append (list (list "coreutils" coreutils)
                   (list "gzip" gzip)
                   (list "patch" patch)
                   (list "tar" tar)
                   (list "manifest" %zcode-build-manifest))
             ;; One hash-verified origin per npm tarball, labelled by the
             ;; install path it belongs at.
             %zcode-node-inputs))
    (home-page "https://zcode.z.ai")
    (synopsis "AI coding agent for the terminal, built from source")
    (description
     "ZCode is Z.ai's agentic development environment.  This package
builds its terminal agent from the Apache-2.0 sources: a TypeScript workspace
compiled by upstream's own tsc and esbuild scripts into a single CLI bundle, run
on Guix's Node.  It drives Z.ai's coding models and other providers, and ships
plugin, MCP and search tooling.")
    (license license:asl2.0)))

;;;
;;; zcode-bin: the desktop app, repackaged from Z.ai's own .deb.
;;;

;;; Upstream publishes one .deb per architecture on its CDN and the hashes
;;; differ, so the source URI is chosen from the system being built for.  This
;;; is not cross-compilation: binary-build systems of this kind want the
;;; matching .deb on the matching machine.
(define %zcode-bin-builds
  `(("x86_64-linux" "linux-x64" . "0ksv1dxkfghdpapwkc0dl5aq4h3bdsl0k9livkncg1lni1wgn4l5")
    ;; Declared because upstream serves the arm64 .deb, and the URL and payload
    ;; layout are the same; no runner here can verify it, since binary packages
    ;; of this kind do not cross-compile.
    ("aarch64-linux" "linux-arm64" . "0xylxzcqp4wcn85izyc17kajc4alm4frg9namz4x8gsn4gnkq9hq")))

(define (zcode-bin-source)
  (let* ((entry (or (assoc (%current-system) %zcode-bin-builds)
                    (car %zcode-bin-builds)))
         (arch (cadr entry))
         (hash (cddr entry)))
    (origin
      (method url-fetch)
      (uri (string-append "https://cdn-zcode.z.ai/zcode/electron/releases/"
                          %version
                          "/"
                          arch
                          "/ZCode-"
                          %version
                          "-"
                          arch
                          ".deb"))
      (file-name (string-append "zcode-bin-" %version ".deb"))
      (sha256 (base32 hash)))))

(define-public zcode-bin
  (package
    (name "zcode-bin")
    (version %version)
    (source
     (zcode-bin-source))
    (build-system copy-build-system)
    (supported-systems (map car %zcode-bin-builds))
    (arguments
     (list
      #:validate-runpath? #f ;bundled prebuilt helpers (koffi.node, ugrep,
      ;; ripgrep) carry no RUNPATH -- Electron ships them
      ;; that way, and they dlopen each other by name.
      #:install-plan
      ;; Keep opt/ZCode's contents side by side under one directory: libffmpeg.so,
      ;; libEGL.so and the resources the app loads are found through $ORIGIN, so
      ;; splitting them across the output would break them.
      #~'(("opt/ZCode" "lib/ZCode")
          ("usr/share" "share"))
      #:phases
      ;; Phases are built with plain alist procedures instead of modify-phases:
      ;; the daemon's staged (guix build utils) has a modify-phases/%modify-phases
      ;; version mismatch that chokes on multiple -- and even nested -- clauses.
      ;; A let* chain, one binding per phase, keeps each of them closable on its
      ;; own line -- readable in review, and impossible to mis-balance.
      #~(let* ((after-unpack (alist-replace 'unpack
                                            (lambda* (#:key source
                                                      #:allow-other-keys)
                                              ;; A .deb is an ar archive; the payload is its xz member.
                                              (invoke "ar" "x" source)
                                              (invoke "tar" "xf" "data.tar.xz"))
                                            %standard-phases))
               (with-patchelf (alist-cons-after 'unpack
                                                'patchelf-binaries
                                                (lambda* (#:key inputs
                                                          #:allow-other-keys)
                                                  ;; The ELF interpreter's file name is per-architecture
                                                  ;; (ld-linux-x86-64.so.2, ld-linux-aarch64.so.1, ld.so on
                                                  ;; i386), so look it up instead of naming it: this package
                                                  ;; declares more than x86_64.
                                                  (let* ((libc (assoc-ref
                                                                inputs "libc"))
                                                         (interpreter (find-files
                                                                       (string-append
                                                                        libc
                                                                        "/lib")
                                                                       "^ld(-linux.*)?\\.so"))
                                                         ;; Every library the bundle dlopen()s by SONAME has to be
                                                         ;; reachable from the executables' RUNPATH; nss installs
                                                         ;; into lib/nss, the rest into lib.
                                                         (rpath (string-append
                                                                 "$ORIGIN:"
                                                                 (string-join (delete
                                                                               #f

                                                                               
                                                                               (map (lambda 
                                                                                            (name)
                                                                                      
                                                                                      
                                                                                      (string-append
                                                                                       (assoc-ref
                                                                                        inputs
                                                                                        name)

                                                                                       
                                                                                       (if
                                                                                        (string=?
                                                                                         name
                                                                                         "nss")
                                                                                        "/lib/nss"
                                                                                        "/lib")))

                                                                               
                                                                               (list #$@%zcode-rpath-inputs)))
                                                                  ":"))))
                                                    (unless (pair? interpreter)
                                                      (error
                                                       "no ELF interpreter found in"
                                                       libc))
                                                    ;; Shared objects get no interpreter to set, and their own
                                                    ;; DT_RUNPATH would have to name every library they dlopen;
                                                    ;; Electron's do not, and #:validate-runpath? #f above is
                                                    ;; what lets that stand.  Only the executables are worth
                                                    ;; rewriting.
                                                    (for-each (lambda (file)
                                                                (unless (or (string-suffix?
                                                                             ".so"
                                                                             file)
                                                                            (string-contains
                                                                             file
                                                                             ".so."))
                                                                  (invoke
                                                                   "patchelf"
                                                                   "--set-interpreter"
                                                                   (car
                                                                    interpreter)
                                                                   file)
                                                                  (invoke
                                                                   "patchelf"
                                                                   "--set-rpath"
                                                                   rpath file)))
                                                              (list (string-append #$output
                                                                     "/lib/ZCode/zcode")
                                                                    (string-append #$output
                                                                     "/lib/ZCode/chrome_crashpad_handler")
                                                                    (string-append #$output
                                                                     "/lib/ZCode/chrome-sandbox")))))
                                                after-unpack))
               (with-wrapper (alist-cons-after 'patchelf-binaries
                                               'create-wrapper
                                               (lambda _
                                                 (wrap-program (string-append #$output
                                                                "/lib/ZCode/zcode")
                                                   `("XDG_DATA_DIRS" suffix
                                                     (,(string-append #$adwaita-icon-theme
                                                        "/share") ,(string-append #$gsettings-desktop-schemas
                                                                    "/share")
                                                      ,(string-append #$shared-mime-info
                                                        "/share")))
                                                   `("PATH" suffix
                                                     (,(string-append #$xdg-utils
                                                                      "/bin"))))
                                                 ;; Entry point, like the deb's own /usr/bin/zcode symlink.
                                                 (mkdir-p (string-append #$output
                                                           "/bin"))
                                                 (symlink (string-append #$output
                                                           "/lib/ZCode/zcode")
                                                          (string-append #$output
                                                           "/bin/zcode")))
                                               with-patchelf)))
          (alist-cons-after 'create-wrapper
                            'fix-desktop-entry
                            (lambda _
                              ;; The deb's Exec names the path it was built for; without this the
                              ;; menu entry points at a /opt that is not there.
                              (substitute* "share/applications/zcode.desktop"
                                (("/opt/ZCode/zcode")
                                 (string-append #$output "/bin/zcode"))))
                            with-wrapper))))
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
    (home-page "https://zcode.z.ai")
    (synopsis "Agentic development environment by Z.ai (prebuilt binary)")
    (description
     "ZCode is Z.ai's desktop application for agentic software
development, with a browser UI and a terminal agent sharing one workspace.  This
package installs the vendor build of the desktop app from Z.ai's own .deb; for a
build from the Apache-2.0 sources, see the @code{zcode} package in this channel,
which provides the terminal agent.")
    ;; The .deb carries no license text beyond Electron/Chromium notices and its
    ;; control file says {@code License: unknown}, but upstream's own repository
    ;; (zai-org/ZCode) ships an Apache-2.0 LICENSE and NOTICE.md states first-party
    ;; code is Apache-2.0.  A repackage is a distribution of that licensed work, so
    ;; asl2.0 is the honest description (README's switch condition: met).
    (license license:asl2.0)))

;;; zcode.scm ends here
