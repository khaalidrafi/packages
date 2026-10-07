;;; sane-packages --- cline: the Cline CLI, built for CPUs without AVX2.
;;; Commentary:
;;;
;;; Cline's published CLI (@cline/cli-linux-x64) is a single-file executable
;;; produced by `bun build --compile`, which embeds the Bun runtime.  Bun's
;;; default x86_64 build uses AVX2, so that binary raises SIGILL on any CPU
;;; older than Intel Haswell (upstream issue #11539; the channel's own
;;; `cline-bin' package therefore refuses to run without avx2).  This CPU is a
;;; pre-Haswell Celeron, so `cline-bin' is useless here.
;;;
;;; Upstream publishes no baseline build, so we make one ourselves: compile
;;; Cline from the cli-v<version> tag with Bun's *baseline* target,
;;; `bun-linux-x64-baseline', which embeds the non-AVX2 runtime.  That target
;;; is exactly how sst/opencode ships its own `-baseline' artifacts
;;; (packages/opencode/script/build.ts); Cline's build.ts is the same shape
;;; minus the baseline target (unmerged upstream PR #11412 adds it).
;;;
;;; A from-source Bun build needs the network: `bun install` resolves the
;;; workspace (bun workspaces, ~468 packages plus per-CPU @opentui/core native
;;; addons) and the baseline compile downloads Bun's baseline runtime artifact.
;;; Guix only allows network in a fixed-output derivation, so the whole
;;; clone+install+compile runs inside one, whose single output is the compiled
;;; `cline' binary, pinned by content hash.  Unlike `zcode' (a pnpm lockfile
;;; that reduces cleanly to a hash-verified tarball table), a bun-workspace
;;; install does not, so a fixed-output build is the honest, reviewed unit here.

(define-module (sane-packages cline)
  #:use-module (guix gexp)
  #:use-module (guix monads)
  #:use-module (guix store)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base) ;coreutils, tar
  #:use-module (gnu packages bash) ;bash-minimal
  #:use-module (gnu packages compression) ;zlib
  #:use-module (gnu packages gcc) ;gcc
  #:use-module (gnu packages nss) ;nss-certs
  #:use-module (gnu packages version-control) ;git
  #:use-module (sane-packages custom))
; bun-bin, %cline-version

;; The CLI is released under cli-vX.Y.Z tags; the npm wrapper and the platform
;; packages all carry this same version.  %cline-version itself is defined in
;; (sane-packages custom), which this module already imports for bun-bin: it is
;; the module that carries cline-bin, and one version for one upstream release
;; line has to be written down once.  Importing the other way would have made
;; the dependency between the two modules circular.
(define %cline-url
  "https://github.com/cline/cline")
(define %cline-tag
  (string-append "cli-v" %cline-version))

;;; Commentary:
;;; `cline-baseline-build' is an origin METHOD.  origin->derivation calls a
;;; method as (method uri hash-algo hash name #:system system); URI is the
;;; value stored in the origin's uri field (we keep the (url tag) pair there).
;;; Forwarding #:hash/#:hash-algo to gexp->derivation is precisely what turns
;;; the result into a fixed-output derivation -- the only derivation kind Guix
;;; lets touch the network -- so the install and the baseline-runtime download
;;; both happen inside it.

(define* (cline-baseline-build spec
                               hash-algo
                               hash
                               name
                               #:key (system (%current-system))
                               (guile (default-guile)))
  (let ((url (car spec))
        ;; plain strings, embedded as-is
        (tag (cadr spec)))
    (mlet %store-monad
          ((guile (package->derivation guile system)))
          (gexp->derivation (or name "cline-baseline-build")
                            #~(begin
                                (use-modules (guix build utils))
                                ;; Unquoting a package inside a gexp lowers it to a build input and
                                ;; substitutes its store path (see 'package-compiler' in packages.scm)
                                ;; -- exactly what git-download's builder does with '#+inputs.
                                (let ((git #$git)
                                      (bun #$bun-bin)
                                      (coreutils #$coreutils)
                                      (tar #$tar)
                                      (gcc #$gcc)
                                      (bash #$bash-minimal)
                                      (certs #$nss-certs))
                                  ;; bun/git want a writable HOME and cache; the store output is
                                  ;; produced by this builder, so work entirely under /tmp.
                                  (setenv "HOME" "/tmp")
                                  (setenv "XDG_CACHE_HOME" "/tmp/.cache")
                                  ;; For any prebuilt helper binary that does get exec'd during
                                  ;; the build (esbuild's, @opentui/core's native addons, all
                                  ;; linked against a system libstdc++).  gcc's lib directory
                                  ;; is the only one in the store that has one, and gcc is
                                  ;; already an input for the store paths below.
                                  ;;
                                  ;; This is NOT what makes grpc-tools' protoc run, and a
                                  ;; previous revision's comment here claimed it was.  It
                                  ;; cannot be: the kernel resolves PT_INTERP before ld.so
                                  ;; gets a say, so no environment variable can make
                                  ;; /lib64/ld-linux-x86-64.so.2 appear.  The install scripts
                                  ;; that would have needed it are skipped instead -- see
                                  ;; `bun install --ignore-scripts' below.
                                  (setenv "LD_LIBRARY_PATH"
                                          (string-append gcc "/lib"))
                                  ;; build.ts shells out to cp/chmod/rm/mkdir (coreutils) and tar, so
                                  ;; all four bin directories must be on PATH, not just bun/git.
                                  ;;
                                  ;; bash-minimal is NOT optional and is not here for build.ts:
                                  ;; Cline's `bun run build:sdk' fans out one nested `bun run
                                  ;; build' per SDK workspace package, and that inner CLI resolves a
                                  ;; real shell binary before running a package.json script
                                  ;; (find_shell: `which bash', `which sh', `which zsh' on PATH,
                                  ;; then a hardcoded list that includes /bin/sh and /usr/bin/sh).
                                  ;; A Guix sandbox has no /bin at all, so that lookup finds
                                  ;; nothing and the CLI dies with "error: An internal error
                                  ;; occurred (MissingShell)" -- which is why the outer `$` calls
                                  ;; in build.ts succeed (Bun's tagged-template shell is its own
                                  ;; interpreter and never looks for a shell) while the nested
                                  ;; `bun run' one line later fails.  Verified by masking /bin and
                                  ;; /usr/bin in a mount namespace: with bash off PATH it raises
                                  ;; MissingShell, with bash-minimal's bin dir on PATH it passes.
                                  ;; NOTE Bun 1.4.2 calls find_shell before it consults --shell=,
                                  ;; so `--shell=bun' does NOT dodge this (upstream issue #43231).
                                  (setenv "PATH"
                                          (string-append git
                                           "/bin:"
                                           bun
                                           "/bin:"
                                           coreutils
                                           "/bin:"
                                           tar
                                           "/bin:"
                                           bash
                                           "/bin"
                                           ":/run/setuid-programs:/bin:/usr/bin"))

                                  ;; TLS trust for the clone and `bun install`.  The fork ships no
                                  ;; ca-certificates package; nss-certs provides a hashed capath dir
                                  ;; (etc/ssl/certs/<hash>.0 -> *.pem) but no combined bundle, while
                                  ;; git/curl/bun want a single file via SSL_CERT_FILE.  Concatenate
                                  ;; the per-root .pem files into one bundle.  This keeps certificate
                                  ;; verification ON rather than leaning on the fixed-output hash.
                                  (let ((bundle "/tmp/ca-bundle.crt")
                                        (pem-dir (string-append certs
                                                  "/etc/ssl/certs")))
                                    (call-with-output-file bundle
                                      (lambda (out)
                                        (for-each (lambda (pem)
                                                    (call-with-input-file pem
                                                      (lambda (in)
                                                        (dump-port in out))))
                                                  (find-files pem-dir
                                                              "\\.pem$"))))
                                    (setenv "SSL_CERT_FILE" bundle)
                                    (setenv "SSL_CERT_DIR" pem-dir)
                                    (setenv "GIT_SSL_CAINFO" bundle)
                                    (setenv "CURL_CA_BUNDLE" bundle)
                                    ;; bun embeds its own Mozilla roots, but honour this bundle too.
                                    (setenv "NODE_EXTRA_CA_CERTS" bundle))

                                  ;; A shallow clone of just the release tag: build.ts reads the
                                  ;; version from package.json, so no history is needed.
                                  (invoke (string-append git "/bin/git")
                                          "clone"
                                          "--depth"
                                          "1"
                                          "--branch"
                                          #$tag
                                          #$url
                                          "cline")
                                  (with-directory-excursion "cline"
                                    ;; Install the workspace.  --single builds only this host, so the
                                    ;; host @opentui/core native addon from a plain install suffices;
                                    ;; no --os/--cpu fan-out is needed for a native (same-arch) build.
                                    ;;
                                    ;; --ignore-scripts is not optional here.  Cline's root
                                    ;; package.json lists trustedDependencies =
                                    ;; ["better-sqlite3", "grpc-tools"], and grpc-tools' install
                                    ;; script is node-pre-gyp, which fetches a prebuilt protoc
                                    ;; compiled for a *stock* glibc and runs it.  Guix is not FHS:
                                    ;; that binary's PT_INTERP (/lib64/ld-linux-x86-64.so.2) and
                                    ;; the libs it needs do not exist, and LD_LIBRARY_PATH does not
                                    ;; help -- the kernel resolves PT_INTERP before ld.so is even
                                    ;; running.  CI runs 37179344851 and 37183041125 both died
                                    ;; there, the second one as
                                    ;; "install script from \"grpc-tools\" exited with 127".
                                    ;;
                                    ;; Nothing in this build needs those scripts: the output is
                                    ;; `bun build --compile' of TypeScript sources, so protobuf
                                    ;; codegen (what grpc-tools exists for) and better-sqlite3's
                                    ;; native binding check are both irrelevant here.  Bun skips
                                    ;; untrusted dependency scripts by default anyway -- the
                                    ;; trustedDependencies list is what opts these two back in --
                                    ;; so this flag only takes away what the upstream project
                                    ;; asked for, in a sandbox that cannot run it.
                                    (invoke (string-append bun "/bin/bun")
                                            "install" "--ignore-scripts")

                                    ;; Make Bun compile for the baseline (non-AVX2) ISA.  Cline's
                                    ;; build.ts has no baseline target (upstream PR #11412 adds one);
                                    ;; the minimal faithful change is to rewrite the single triple it
                                    ;; hands to Bun.build's compile.target.  That string appears only
                                    ;; once -- in getBunTarget -- so the substitution is unambiguous,
                                    ;; and everything downstream (dir names, package names) is left
                                    ;; alone: the binary still lands under dist/cli-linux-x64/bin.
                                    (substitute* "apps/cli/script/build.ts"
                                      (("bun-\\$\\{targetOs\\}-\\$\\{item\\.arch\\}")
                                       "bun-${targetOs}-x64-baseline"))

                                    ;; Upstream's `build:sdk' is
                                    ;; `bun --production -F './sdk/packages/*' build', and neither
                                    ;; flag survives Bun 1.4.2.
                                    ;;
                                    ;; --production was deprecated in 1.1 and removed in 1.2, so
                                    ;; 1.4.2 answers "bun: unrecognized option '--production'" and
                                    ;; exits 1.
                                    ;;
                                    ;; -F is subtler, and is why an earlier attempt here that
                                    ;; removed ONLY --production traded one failure for another:
                                    ;;
                                    ;; $ bun -F './sdk/packages/*' build
                                    ;; -F: error while loading shared libraries: -F: cannot open
                                    ;; shared object file: No such file or directory
                                    ;;
                                    ;; That is not a missing library.  It is the dynamic loader
                                    ;; being handed "-F" as the program to load: `bun run build:sdk'
                                    ;; parsed the short flag as a script name rather than as a
                                    ;; flag, and then tried to exec it.  Rewriting it to the long
                                    ;; form --filter is the fix:
                                    ;;
                                    ;; bun --filter './sdk/packages/*' build
                                    ;;
                                    ;; --filter goes through the same 1.4.2 parser and selects the
                                    ;; same workspace packages, so this is exactly equivalent minus
                                    ;; the parse bug.  Verified against the pinned bun
                                    ;; (i8j20p81567kcxvwr1xzz2yw6sa8i2cr, the store path CI used).
                                    ;;
                                    ;; --production needs no replacement.  As a global flag it only
                                    ;; ever meant "omit devDependencies" and that applies to an
                                    ;; *install*, not to which script `bun run' then executes.  The
                                    ;; install above is a full one, so the dev dependencies are on
                                    ;; disk regardless -- which is what we want anyway, since those
                                    ;; SDK packages build with `tsc', itself a devDependency.
                                    ;;
                                    ;; Substituted before `bun install' so the manifest is already
                                    ;; correct by the time anything reads it, and anchored on the
                                    ;; `build:sdk' key so the unrelated `build:apps' line -- which
                                    ;; also says --production but is not what build.ts invokes --
                                    ;; keeps upstream's text.
                                    (substitute* "package.json"
                                      (("\"build:sdk\": \"bun --production -F ")
                                       "\"build:sdk\": \"bun --filter "))

                                    ;; build.ts --single then orchestrates, in order: build:sdk, the
                                    ;; CLI bundle, the Cline Hub webview, and `bun build --compile'
                                    ;; for the (now baseline) host target.
                                    ;; Upstream's `build:sdk' is
                                    ;; `bun --production -F './sdk/packages/*' build'.
                                    ;; Neither flag survives Bun 1.4.2.
                                    ;;
                                    ;; --production was deprecated in 1.1 and removed in
                                    ;; 1.2, so 1.4.2 answers "bun: unrecognized option
                                    ;; '--production'" and exits 1.
                                    ;;
                                    ;; -F is subtler and was the reason an earlier
                                    ;; attempt in this repository removed only
                                    ;; --production and got a *different* failure:
                                    ;;
                                    ;; $ bun -F './sdk/packages/*' build
                                    ;; -F: error while loading shared libraries
                                    ;;
                                    ;; That message is not a missing library -- it is the
                                    ;; dynamic loader being handed "-F" as the program to
                                    ;; load, i.e. `bun run build:sdk' parsed the short
                                    ;; flag as a script name rather than a flag.  Rewriting
                                    ;; it to the long form --filter is what fixes it:
                                    ;;
                                    ;; bun --filter './sdk/packages/*' build
                                    ;;
                                    ;; --filter is accepted by the same 1.4.2 parser and
                                    ;; selects the same workspace packages (verified against
                                    ;; this pinned bun), so the substitution is exactly
                                    ;; equivalent minus the parse bug.  Two forms, one
                                    ;; substitution, anchored on the script name so
                                    ;; build:apps -- which also says --production and is not
                                    ;; what build.ts invokes -- keeps upstream's text.
                                    
                                    (invoke (string-append bun "/bin/bun")
                                            "apps/cli/script/build.ts"
                                            "--single")

                                    ;; Emit the compiled ELF as the single fixed output.
                                    (copy-file
                                     "apps/cli/dist/cli-linux-x64/bin/cline"
                                     #$output)
                                    (chmod #$output #o555))))
                            #:system system
                            #:guile-for-build guile
                            ;; (guix build utils) has to be copied into the build
                            ;; environment for the (use-modules ...) above: this is
                            ;; a raw gexp->derivation, not a package built by a
                            ;; build system, so nothing else provides it.  Without
                            ;; it the build dies before doing any work with
                            ;; "no code for module (guix build utils)" (CI run
                            ;; 37148319887).  gexp->derivation's #:modules is
                            ;; documented as deprecated in favour of
                            ;; with-imported-modules, which would mean wrapping
                            ;; the whole gexp in another form; the keyword does
                            ;; the same job with a one-line diff.
                            #:modules '((guix build utils))
                            #:hash hash
                            #:hash-algo hash-algo
                            #:recursive? #f ;the output is one file, not a tree
                            #:leaked-env-vars '("http_proxy" "https_proxy")
                            #:local-build? #t))))
; keep the fetch offload-free

(define %cline-baseline-source
  ;; The fixed-output origin carrying the compiled baseline binary.  The hash
  ;; below is a placeholder: build once (CI or a capable host) and replace it
  ;; with the sha256 Guix reports for the produced output.  It cannot be known
  ;; until the network build has run, which this machine must not do.
  (origin
    (method cline-baseline-build)
    (uri (list %cline-url %cline-tag))
    (file-name (string-append "cline-baseline-" %cline-version))
    (sha256 (base32 "0000000000000000000000000000000000000000000000000000"))))

(define-public cline-baseline
  (package
    (name "cline-baseline")
    (version %cline-version)
    ;; trivial-build-system wires this origin in as the "source" build input;
    ;; the builder below reads it back with (assoc-ref %build-inputs "source").
    (source
     %cline-baseline-source)
    (build-system trivial-build-system)
    (arguments
     (list
      ;; trivial-build-system's default builder module set does not include
      ;; (guix build utils), so the (use-modules ...) below would fail with
      ;; "no code for module (guix build utils)" at evaluation time.
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((out (assoc-ref %outputs "out"))
                 (binary (string-append out "/lib/cline/cline"))
                 (compiled (assoc-ref %build-inputs "source"))
                 ;; Bun binaries resist patchelf -- it corrupts the large
                 ;; embedded payload -- so exec them through the store glibc
                 ;; loader, the way bun-bin and opencode here already do.
                 (loader (string-append (assoc-ref %build-inputs "glibc")
                                        "/lib/ld-linux-x86-64.so.2"))
                 (lib-path (string-append (assoc-ref %build-inputs "gcc")
                                          "/lib" ":"
                                          (assoc-ref %build-inputs "zlib")
                                          "/lib"))
                 (bash (assoc-ref %build-inputs "bash-minimal")))
            (mkdir-p (dirname binary))
            (copy-file compiled binary)
            (chmod binary #o555)
            (mkdir-p (string-append out "/bin"))
            (call-with-output-file (string-append out "/bin/cline")
              (lambda (port)
                (format port
                        "#!~a/bin/bash
exec ~a --library-path ~a ~a \"$@\"
"
                        bash
                        loader
                        lib-path
                        binary)))
            (chmod (string-append out "/bin/cline") #o555)))))
    (inputs (list bash-minimal glibc
                  (list gcc "lib") zlib))
    (supported-systems '("x86_64-linux"))
    (home-page "https://cline.bot")
    (synopsis "Autonomous coding agent CLI, built for CPUs without AVX2")
    (description
     "Cline is an autonomous coding agent for the terminal: it can read and
edit files, run commands, and use a browser.  The published CLI is a
Bun-compiled binary that needs AVX2 and crashes with SIGILL on pre-Haswell
x86_64 CPUs.  This package builds Cline from source with Bun's baseline target
(@code{bun-linux-x64-baseline}), producing the same CLI that runs on CPUs
without AVX2 support.")
    (license license:asl2.0)))

;;; cline.scm ends here
