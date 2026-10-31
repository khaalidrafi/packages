;;; sane-packages --- cline: the Cline CLI, built for CPUs without AVX2.
;;; Commentary:
;;;
;;; Cline's published CLI (@cline/cli-linux-x64) is a single-file executable
;;; produced by `bun build --compile`, which embeds the Bun runtime.  Bun's
;;; default x86_64 build uses AVX2, so that binary raises SIGILL on any CPU
;;; older than Intel Haswell (upstream issue #11539).  This CPU is a
;;; pre-Haswell Celeron, so a CLI built for the AVX2 target is the wrong thing
;;; to depend on here.  The package that used to guard against exactly that --
;;; an older `cline-bin' in (sane-packages custom), which refused to start
;;; without avx2 -- was superseded by the `cline-bin' defined further down, and
;;; the stale copy has been dropped so the channel no longer carries that
;;; package name twice.
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
  #:use-module (guix build-system copy)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base) ;coreutils, tar, glibc
  #:use-module (gnu packages bash) ;bash-minimal
  #:use-module (gnu packages compression) ;zlib
  #:use-module (gnu packages elf) ;patchelf
  #:use-module (gnu packages gcc) ;gcc
  #:use-module (gnu packages nss) ;nss-certs
  #:use-module (gnu packages version-control) ;git
  #:use-module (gnu packages node) ;node -- see the inputs comment
  #:use-module (sane-packages custom))
; bun-bin, %cline-version

;; The CLI is released under cli-vX.Y.Z tags; the npm wrapper and the platform
;; packages all carry this same version.  %cline-version itself is defined in
;; (sane-packages custom), which this module already imports for bun-bin:
;; importing the other way would have made the dependency between the two
;; modules circular.  It drives the `cli-v<version>' tag this module builds from
;; source; cline-bin below carries its own %cline-bin-version, so a bump has to
;; move both numbers together.
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
                                      (node #$node)
                                      (gcc #$gcc)
                                      ;; glibc is an input for one reason only: the
                                      ;; smoke-test loader below.  It is *not*
                                      ;; on LD_LIBRARY_PATH -- see the note there.
                                      (glibc #$glibc)
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
                                           node
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

                                    ;; Bun 1.4.2 *does* create the .bin links, so the ENOENT is
                                    ;; not a missing file -- it is a file that cannot be
                                    ;; exec'd.  posix_spawn reports only the path it was
                                    ;; handed, so a dead symlink and an un-runnable target
                                    ;; both surface identically as .../.bin/tsc:
                                    ;;
                                    ;; error: Failed to run "tsc" due to:
                                    ;; ENOENT: .../cline/node_modules/.bin/tsc:
                                    ;; No such file or directory (posix_spawn(...))
                                    ;;
                                    ;; typescript@5.9.3 IS on disk -- the install prints
                                    ;; "+ typescript@5.9.3" and "2375 packages installed" --
                                    ;; and there are two distinct shapes of break hidden
                                    ;; behind that one message:
                                    ;;
                                    ;; - .bin/tsc resolves, but typescript's own bin/tsc
                                    ;; starts with `#!/usr/bin/env node'.  A Guix
                                    ;; sandbox has no /usr/bin at all, so the kernel
                                    ;; cannot start the interpreter and execve returns
                                    ;; ENOENT *on the target*.
                                    ;;
                                    ;; - the link dangles.  typescript is a
                                    ;; peerDependency of the root package.json and so
                                    ;; installs only into the root node_modules, never
                                    ;; into a workspace's own -- hence
                                    ;; sdk/packages/ui/node_modules/.bin/tsc ->
                                    ;; ../typescript/bin/tsc, which resolves to
                                    ;; sdk/packages/ui/node_modules/typescript/bin/tsc,
                                    ;; a path that does not exist.
                                    ;;
                                    ;; Both halves of that are guarded, and both guards
                                    ;; can hide a silent no-op: `file-exists?' follows
                                    ;; symlinks, so a dangling link reads as absent and
                                    ;; an `if' quietly creates nothing.  The same trap
                                    ;; caught the first cut of this block -- `root' is
                                    ;; (getcwd) *inside* the excursion, so it already
                                    ;; ends in /cline, and appending another /cline
                                    ;; made tsc-target a path that never existed.
                                    ;; The repair therefore never ran and the build
                                    ;; died at exactly the ENOENT it was written to
                                    ;; fix (CI run 38145306251).  Note that
                                    ;; (getcwd)'s value is a symlinked path, not the
                                    ;; canonicalised one.
                                    (let* ((root (getcwd))
                                           (tsc-target (string-append root
                                                        "/node_modules"
                                                        "/typescript/bin/tsc")))
                                      (when (file-exists? tsc-target)
                                        (for-each (lambda (nm)
                                                    (let ((link (string-append
                                                                 nm
                                                                 "/.bin/tsc")))
                                                      (when (not (file-exists?
                                                                  link))
                                                        ;; Unlink first: symlink cannot
                                                        ;; overwrite an existing dangling
                                                        ;; link.  Guarded because
                                                        ;; symbolic-link? lstat()s and
                                                        ;; throws when there is nothing
                                                        ;; there at all, which is the
                                                        ;; common case for a workspace
                                                        ;; that has no .bin directory.
                                                        (when (false-if-exception
                                                               (symbolic-link?
                                                                link))
                                                          (delete-file link))
                                                        (mkdir-p (dirname link))
                                                        (symlink tsc-target
                                                                 link))))
                                                  ;; root is the workspace root itself, so
                                                  ;; it is the first element and also the
                                                  ;; find-files starting point: every
                                                  ;; nested node_modules found under it is
                                                  ;; a workspace whose own .bin the install
                                                  ;; may have left dangling.
                                                  (cons root
                                                        (find-files root
                                                         "^node_modules$"
                                                         #:directories? #t
                                                         #:stat lstat))))

                                      ;; This is patch-source-shebangs from
                                      ;; gnu-build-system.scm copied rather than
                                      ;; reinvented, and it must cover the whole
                                      ;; tree: which bin/tsc (or bin/vite, or any
                                      ;; other) a script happens to spawn by name
                                      ;; is not knowable ahead of the build.
                                      ;;
                                      ;; #:stat lstat is what stops the walk from
                                      ;; looping on the node_modules symlink
                                      ;; nodes that point back up at their own
                                      ;; directory, and regular files only is not
                                      ;; just tidiness: patch-shebang finishes by
                                      ;; renaming its temp file over its argument
                                      ;; (build/utils.scm:1138), so handed a
                                      ;; .bin/* symlink it would silently replace
                                      ;; the link with a copy of the file.
                                      ;; patch-shebang returns #f for anything
                                      ;; that does not start with "#!", so ELF
                                      ;; addons such as @opentui/core's .node and
                                      ;; every .js/.json file pass through
                                      ;; untouched.
                                      (for-each patch-shebang
                                                (find-files root
                                                            (lambda (file stat)
                                                              (eq? 'regular
                                                                   (stat:type
                                                                    stat)))
                                                            #:stat lstat)))

                                    ;; The wildcard bind above is necessary but not sufficient.  Upstream's
                                    ;; smoke block then runs `hub start', which does not merely spawn the
                                    ;; daemon -- it stays in the client and polls the daemon over TCP until
                                    ;; it answers, for up to HUB_STARTUP_TIMEOUT_MS = 15s, and throws
                                    ;;
                                    ;; Timed out after 15000ms waiting for detached hub startup.
                                    ;;
                                    ;; if it never does.  A bind on 0.0.0.0 succeeds in the sandbox, but no
                                    ;; loopback client can connect to anything, so every one of those probes
                                    ;; fails and the command is doomed no matter which host literal it binds.
                                    ;; `hub status' needs the same TCP for its probe, and only falls back to
                                    ;; _reading_ the discovery record when there is none at all.
                                    ;;
                                    ;; So this substitution replaces the whole pair with the network-free
                                    ;; equivalent, and it runs BEFORE the loader rewrite below: the loader
                                    ;; rewrite rewrites `${outfile}' everywhere it appears, so an anchor
                                    ;; written against the un-prefixed line would never match again.
                                    ;;
                                    ;; The daemon personality of the very same binary is invoked the
                                    ;; way `hub start' spawns it for a compiled binary (daemon.ts's
                                    ;; resolveLaunchCommand: the marker flag, --cwd, --host, --port, and
                                    ;; CLINE_NO_INTERACTIVE + CLINE_RUN_AS_HUB_DAEMON in the environment;
                                    ;; resolveDaemonEntryArgs returns just [--cline-hub-daemon] when the
                                    ;; entry path is inside a compiled Bun artifact), but spawned
                                    ;; _detached_ so this script keeps control and can reap it.
                                    ;; Readiness is then decided by the discovery file the daemon is
                                    ;; contractually required to publish before it reports healthy -- the
                                    ;; same signal `hub start' waits for, minus the socket: the WS server in
                                    ;; sdk/packages/core/src/hub/server.ts writes it right after a successful
                                    ;; bind (writeHubDiscovery) and dies if that write fails, so a complete
                                    ;; record with an auth token proves the daemon reached its bound state.
                                    ;;
                                    ;; --host 0.0.0.0 is passed explicitly rather than left to the default
                                    ;; 127.0.0.1 (resolveDefaultHubHost), because the default bind cannot
                                    ;; succeed here for the same EADDRNOTAVAIL reason findFreePort could not;
                                    ;; discovery.write's host/port/url fields are then recorded as the
                                    ;; daemon's own, which is what any later client would connect to.
                                    ;;
                                    ;; THE SPAWN IS THE STORE LOADER, NOT process.execPath, AND THE
                                    ;; BINARY ARRIVES AS AN argv ENTRY, NOT INSIDE A TEMPLATE LITERAL.
                                    ;; Two bugs lived in this one line and CI run 38571771850 hit both:
                                    ;;
                                    ;; 1. spawn(process.execPath, [`${outfile} --cline-hub-daemon ...`])
                                    ;; hands the bun runtime ONE argument that is the whole command
                                    ;; string.  node:child_process passes argv entries verbatim, so
                                    ;; the runtime was asked to run a *script* literally named
                                    ;; "/.../cline --cline-hub-daemon --host 0.0.0.0 ..." (ENOENT), the
                                    ;; daemon never existed, and the poll below resolved
                                    ;; {running:false} after its 30s deadline: "Expected a healthy
                                    ;; hub, got {\"running\":false}" (build.ts:315), 31 seconds after
                                    ;; the --version pass.
                                    ;; 2. Even with correct argv, spawning the compiled ELF directly
                                    ;; cannot work here: it is a `bun build --compile' artifact with
                                    ;; PT_INTERP /lib64/ld-linux-x86-64.so.2, which does not exist in
                                    ;; the sandbox (the same reason the --version exec below needs the
                                    ;; loader prefix).  So the launcher IS the loader and the binary
                                    ;; is its first argument.
                                    ;;
                                    ;; The replacement text therefore carries the identifier `outfile'
                                    ;; and NOT the template literal `${outfile}': the loader rewrite
                                    ;; further down this phase rewrites every literal `${outfile}' in
                                    ;; the file, and a `${outfile}' here would be rewritten into the
                                    ;; loader command INSIDE the argv array, resurrecting bug 1 in a
                                    ;; second form.
                                    (substitute* "apps/cli/script/build.ts"
                                      ;; build.ts never imports node:child_process -- its only runtime is
                                      ;; Bun's own $ -- so add it to the file's single import list rather
                                      ;; than top-level require()'ing in the middle of a function body.
                                      (("import \\{ type AddressInfo, createServer \\} from \"node:net\";")
                                       "import { spawn } from \"node:child_process\";
import { type AddressInfo, createServer } from \"node:net\";"))
                                    (substitute* "apps/cli/script/build.ts"
                                      (("await \\$`\\$\\{outfile\\} hub start`\\.env\\(smokeEnv\\)\\.quiet\\(\\);")
                                       (string-append
                                        "const hubDaemon = spawn(\""
                                        glibc
                                        "/lib/ld-linux-x86-64.so.2\", [\"--library-path\", \""
                                        gcc
                                        "/lib\", outfile, \"--cline-hub-daemon\", \"--cwd\", process.cwd(), \"--host\", \"0.0.0.0\", \"--port\", String(smokeEnv.CLINE_HUB_PORT)], {
"
                                        "\t\t\t\t\t\tcwd: process.cwd(),\n"
                                        "                                               env: { ...smokeEnv, CLINE_NO_INTERACTIVE: \"1\", CLINE_RUN_AS_HUB_DAEMON: \"1\" },
"
                                        "\t\t\t\t\t\tdetached: true,\n"
                                        "\t\t\t\t\t\tstdio: \"ignore\",\n"
                                        "\t\t\t\t\t});\n"
                                        "\t\t\t\t\tvoid hubDaemon;")))
                                    ;; `void hubDaemon;', not
                                    ;; `(void) hubDaemon;': Bun 1.4.3's parser
                                    ;; rejects the parenthesized form outright
                                    ;; ("Unexpected )"), which failed the whole
                                    ;; build.ts before it could bundle anything
                                    ;; -- CI run 38541038306, reproduced with the
                                    ;; pinned bun on the patched file alone.  The
                                    ;; two forms mean the same thing here (evaluate
                                    ;; the binding, discard the result); the bare
                                    ;; one parses.
                                    
                                    ;; `hub status' is replaced by a bounded poll of the discovery file the
                                    ;; daemon writes.  It resolves to the same shape the next assertion
                                    ;; expects -- { running, coreVersion } -- but sourced from the file rather
                                    ;; than from an HTTP probe that cannot be served.  The credentials it
                                    ;; waits for are the ones the daemon itself generated (hub.ts's status
                                    ;; reports the discovered record when the probe fails, and a record with
                                    ;; an authToken is a daemon that finished binding, not a leftover).
                                    ;;
                                    ;; The three substitutions below are the *whole* replacement, split on
                                    ;; single-line anchors on purpose: `substitute*' reads its input one line
                                    ;; at a time (build/utils.scm's `substitute' loops on `read-line' and
                                    ;; applies every pattern to that single line), so a PATTERN containing a
                                    ;; newline can NEVER match, however its spans are written -- while a
                                    ;; REPLACEMENT may span any number of lines.  Anchor 1 therefore emits
                                    ;; the entire promise body as one string, and the other two anchors
                                    ;; delete the lines it replaced.
                                    ;;
                                    ;; NB: Guile's regexp is POSIX ERE, where \t is NOT an escape for tab
                                    ;; -- it would match a literal 't'.  The anchors below are therefore
                                    ;; written with either no leading whitespace or an explicit [ \t] class.
                                    (substitute* "apps/cli/script/build.ts"
                                      (("const status = JSON\\.parse\\(")
                                       (string-append
                                        "const status = await new Promise<{ running?: boolean; coreVersion?: string }>((resolve) => {
"
                                        "                                       const deadline = Date.now() + 30_000;
"
                                        "\t\t\t\t\tconst poll = () => {\n"
                                        "\t\t\t\t\t\ttry {\n"
                                        "                                                       const parsed = JSON.parse(readFileSync(smokeEnv.CLINE_HUB_DISCOVERY_PATH, \"utf-8\")) as { authToken?: string; coreVersion?: string; pid?: number };
"
                                        "                                                       if (parsed.authToken) { resolve({ running: true, coreVersion: parsed.coreVersion }); }
"
                                        "                                                       else if (Date.now() >= deadline) { resolve({ running: false, coreVersion: undefined }); }
"
                                        "\t\t\t\t\t\t} catch { /* not written yet */ }\n"
                                        "                                               if (Date.now() >= deadline) { resolve({ running: false, coreVersion: undefined }); }
"
                                        "\t\t\t\t\t\telse { setTimeout(poll, 200); }\n"
                                        "\t\t\t\t\t};\n"
                                        "\t\t\t\t\tpoll();")))
                                    (substitute* "apps/cli/script/build.ts"
                                      (("await \\$`\\$\\{outfile\\} hub status`\\.env\\(smokeEnv\\)\\.text\\(\\),")
                                       ""))
                                    (substitute* "apps/cli/script/build.ts"
                                      (("\\) as \\{ running\\?: boolean; coreVersion\\?: string \\};")
                                       "});"))

                                    ;; The teardown line is `hub stop', not the daemon PID, so it keeps
                                    ;; working unchanged: with no reachable hub, stopLocalHubServerGracefully
                                    ;; returns false and stopHubServer falls back to process.kill(pid,
                                    ;; SIGTERM) from the same discovery record, then clears it.  It is
                                    ;; already .nothrow(), so it cannot fail the build either.
                                    ;;
                                    ;; That leaves only the process group: the daemon was spawned detached,
                                    ;; so it is not a child this script can wait on, and a SIGTERM that the
                                    ;; daemon answers is enough -- its own shutdownCoordinator tears the
                                    ;; listener down and exits.  Nothing is left listening on the port and
                                    ;; smokeHome is deleted below regardless.
                                    
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

                                    ;; Upstream smoke-tests the freshly compiled binary
                                    ;; by exec'ing it directly (`${outfile} --version').
                                    ;; That can never work in a Guix sandbox, and the
                                    ;; failure is not a bug in the build: a
                                    ;; `bun build --compile' output is a Bun ELF with
                                    ;; PT_INTERP /lib64/ld-linux-x86-64.so.2, and Guix
                                    ;; is not FHS -- that path does not exist.  The
                                    ;; kernel resolves PT_INTERP before ld.so is ever
                                    ;; running, so no LD_LIBRARY_PATH entry can fix it,
                                    ;; and the kernel reports the missing interpreter
                                    ;; as ENOENT *on the target*.  Bun's own shell
                                    ;; surfaces that verbatim:
                                    ;;
                                    ;; Smoke test FAILED for @cline/cli-linux-x64:
                                    ;; stderr: "bun: No such file or directory:
                                    ;; .../dist/cli-linux-x64/bin/cline"
                                    ;;
                                    ;; CI run 38227017938.  The identical signature
                                    ;; killed grpc-tools' protoc in 37179344851 -- the
                                    ;; two failures share one cause; what fixed that
                                    ;; one was skipping its install script, which is
                                    ;; not an option for this one because the smoke
                                    ;; test IS the failure, not a step before it.
                                    ;;
                                    ;; The fix is the one this repository already uses to
                                    ;; run Bun ELFs at runtime: exec through the store
                                    ;; glibc loader.  Verified on this machine against
                                    ;; both bun-baseline (which carries the same
                                    ;; PT_INTERP and needs gcc's libstdc++) and the
                                    ;; installed cline ELF: direct exec gives
                                    ;; `No such file or directory', while
                                    ;;
                                    ;; ld-linux-x86-64.so.2 --library-path gcc/lib
                                    ;; <binary> --version
                                    ;;
                                    ;; prints `1.4.2' and `3.0.68' respectively.  Only
                                    ;; the smoke test is rewritten; the compiled binary
                                    ;; itself is untouched (it is the package output,
                                    ;; and the loader wrapper that finally runs it is
                                    ;; added by the `cline-baseline' package below).
                                    ;;
                                    ;; --library-path is kept even though the cline ELF
                                    ;; only needs libc/libpthread/libdl/libm today:
                                    ;; bun-baseline -- which carries the same PT_INTERP
                                    ;; and is the runtime a fresh compile embeds --
                                    ;; also needs libstdc++, and gcc/lib is the one
                                    ;; store directory that has it.  glibc is an input
                                    ;; for this line alone; it is deliberately NOT
                                    ;; added to LD_LIBRARY_PATH, because that variable
                                    ;; cannot help an exec the kernel refuses (see
                                    ;; the grpc-tools note above) and the loader here
                                    ;; is a path, not a search.
                                    (let ((loader (string-append glibc
                                                   "/lib/ld-linux-x86-64.so.2"))
                                          (lib-path (string-append gcc "/lib")))
                                      (substitute* "apps/cli/script/build.ts"
                                        ;; `${outfile}' is exactly the string that
                                        ;; opens every exec of the compiled binary.
                                        ;; The rewrite keeps the template literal
                                        ;; and re-inserts `${outfile}' at the end,
                                        ;; so Bun's interpolation still supplies
                                        ;; the path and the shell command becomes
                                        ;; `$`LD --library-path GCCC/lib ${outfile}
                                        ;; --version`' -- the same command the
                                        ;; cline-baseline wrapper runs at runtime.
                                        ;; Verified on a copy of this file with the
                                        ;; real substitute*: all four exec sites
                                        ;; (lines 263, 292, 294, 303 of the
                                        ;; pinned tag) take the prefix, and the
                                        ;; two console.logs merely print it.
                                        (("\\$\\{outfile\\}")
                                         (string-append " "
                                                        loader
                                                        " --library-path "
                                                        lib-path
                                                        " "
                                                        "${outfile}")))

                                      ;; --version now passes, and the next smoke
                                      ;; step -- `cline hub start/status/stop' --
                                      ;; dies before the binary is even exec'd:
                                      ;;
                                      ;; error: listen EADDRNOTAVAIL: address not
                                      ;; available 127.0.0.1
                                      ;; errno: 99
                                      ;; at <anonymous> (build.ts:174:10)
                                      ;; at findFreePort (build.ts:171:9)
                                      ;; at build.ts:289:34
                                      ;;
                                      ;; That literal is build.ts's findFreePort():
                                      ;;
                                      ;; server.listen(0, "127.0.0.1", ...)
                                      ;;
                                      ;; The Guix build sandbox runs in a fresh
                                      ;; network namespace whose loopback
                                      ;; interface is DOWN (gnu/build/
                                      ;; linux-container.scm's
                                      ;; `set-network-interface-up "lo"' only
                                      ;; runs when the daemon requested the net
                                      ;; namespace together with loopback-network?,
                                      ;; and it evidently did not here), so no
                                      ;; address is assigned to lo and binding
                                      ;; 127.0.0.1 answers EADDRNOTAVAIL, errno 99.
                                      ;;
                                      ;; 0.0.0.0 is the wildcard bind: it needs no
                                      ;; address of its own, only a live stack, so
                                      ;; it succeeds where 127.0.0.1 cannot.  The
                                      ;; socket is closed again immediately after
                                      ;; learning the port number, so nothing is
                                      ;; ever reachable on it, and the port is
                                      ;; then handed to the hub through
                                      ;; CLINE_HUB_PORT as an opaque integer --
                                      ;; the hub binds it itself.  Rewriting the
                                      ;; literal therefore changes what
                                      ;; findFreePort binds, not what the built
                                      ;; hub listens on, which is exactly the
                                      ;; property this fix needs.
                                      (substitute* "apps/cli/script/build.ts"
                                        ;; Exactly one occurrence in the pinned
                                        ;; tag (line 174), so this cannot eat an
                                        ;; unrelated bind.
                                        (("127\\.0\\.0\\.1")
                                         "0.0.0.0")))

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
                                    ;; The long form alone is not enough: `run' has to be
                                    ;; explicit too.  `bun --filter PAT build' and
                                    ;; `bun -F PAT build' are both rejected by 1.4.2 --
                                    ;; "Must use --outdir when specifying more than one
                                    ;; entry point" -- because with no `run' between them
                                    ;; bun is building a bundle, not filtering scripts.
                                    ;; What works is `bun run --filter PAT build', i.e.
                                    ;; `run' first and the filter as a flag to it.  Verified
                                    ;; all three orderings against a two-package workspace.
                                    (substitute* "package.json"
                                      (("\"build:sdk\": \"bun --production -F ")
                                       "\"build:sdk\": \"bun run --filter "))

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
                                    ;; #o644, NOT #o555: this derivation is a
                                    ;; fixed-output one with #:recursive? #f --
                                    ;; the output is one file, not a tree -- and
                                    ;; the daemon-side finalization of such an
                                    ;; output requires a NON-EXECUTABLE regular
                                    ;; file before it will hash the bytes:
                                    ;;
                                    ;; output path `...' should be a
                                    ;; non-executable regular file
                                    ;;
                                    ;; (CI run 38705403478; the builder had
                                    ;; already finished -- "Build complete.  1
                                    ;; targets built" -- and every smoke step
                                    ;; inside build.ts had passed).  Guile's
                                    ;; copy-file also preserves the source's
                                    ;; mode in newer Guile, so the exec bit the
                                    ;; Bun compile artifact carries must be
                                    ;; dropped explicitly, whatever the umask.
                                    ;; The consumer package restores it:
                                    ;; cline-baseline's builder does
                                    ;; (chmod binary #o555) after copying this
                                    ;; file to $out/lib/cline/cline, so the
                                    ;; store item it installs is executable.
                                    (chmod #$output #o644))))
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
  ;; is the one the one-time network build reported: CI run 38969043034 built
  ;; the whole FOD (bun install, the build.ts substitution chain, the smoke
  ;; phases inside it, the compile) with the #o644 output fix in place, and
  ;; the daemon's hash comparison then failed against the all-zeros
  ;; placeholder exactly as designed, printing
  ;;
  ;; sha256 hash mismatch for /gnu/store/...-cline-baseline-3.0.70:
  ;; expected hash: 0000000000000000000000000000000000000000000000000000
  ;; actual hash: 0ynpf764v7jca55q553q4p40xyp9p3j1v5p9vfpv748j2savy03g
  ;;
  ;; The actual value is pasted in below.  For this to converge, the next
  ;; build of the FOD must produce a byte-identical file -- same pinned
  ;; inputs, same bun, same substitutions -- which is what makes the
  ;; declared hash a fixed output rather than a guess.  (Comment lines
  ;; carry exactly one space after ';;': guix style's canonicalize-
  ;; comment trims anything else, and the style gate in
  ;; tests/check-static.sh diffs the result.)
  (origin
    (method cline-baseline-build)
    (uri (list %cline-url %cline-tag))
    (file-name (string-append "cline-baseline-" %cline-version))
    (sha256 (base32 "0ynpf764v7jca55q553q4p40xyp9p3j1v5p9vfpv748j2savy03g"))))

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
    ;; node is NOT optional and NOT there for the CLI's own sake -- it is what
    ;; makes `bun run --filter ... build' work at all.
    ;;
    ;; Cline's SDK packages each have "build": "bun run bun.mts && bun tsc ...".
    ;; Run from the workspace root via --filter, Bun does not resolve those the
    ;; way a direct `bun run <script>' does, and `bun run' falls back to looking
    ;; for node on PATH; with no node there it reports
    ;;
    ;; run: error while loading shared libraries: run: cannot open shared
    ;; object file: No such file or directory
    ;;
    ;; which reads like a missing shared library and is not one -- "run" is being
    ;; exec'd as the program.  Bisected to a single directory on PATH: adding a
    ;; dir containing only a `node' symlink flips a two-package workspace from
    ;; exit 127 to exit 0, and removing it flips it back.  Nothing else in the
    ;; environment mattered.  CI runs 37611886029, 37611208416.
    ;;
    ;; Listing node in the input is only half of that bisection: the other half
    ;; is the directory.  Node was put here but its bin was left out of the
    ;; PATH setenv below, which is why 7c4a179 did not actually fix anything --
    ;; the exit-127 `run:' error came back verbatim in CI run 38101517394, one
    ;; level deeper into each SDK package's build script.
    (inputs (list bash-minimal glibc node
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

;;; The npm prebuilt
;;;
;;; Upstream also publishes the CLI as a platform npm package,
;;; @cline/cli-linux-x64, whose payload is the same Bun-compiled binary the
;;; source build above compiles with `bun build --compile' -- plus the
;;; cline-hub webview tree the hub serves.  That is a vendor binary, so unlike
;;; cline-baseline it is cheap enough to build (download + repack) and test on
;;; this machine, and it is what cline-bin packages.  The two packages differ
;;; in provenance, not in purpose: cline-baseline is compiled here from source
;;; with Bun's baseline (no-AVX2) target, cline-bin is upstream's published
;;; build.  Both install the command `cline', so install one per profile, the
;;; same rule opencode-bin/opencode2-bin follow.
;;;
;;; The binary is a Bun ELF carrying PT_INTERP /lib64/ld-linux-x86-64.so.2, a
;;; path that does not exist in Guix -- direct exec answers ENOENT on the
;;; target (the same failure the source build's CI smoke test hit, see the
;;; long note above).  The wrapper therefore execs it through the store glibc
;;; loader, as every Bun binary in this channel does.  Empirically the npm
;;; build runs on this pre-Haswell Celeron (--version, --help, hub status/stop
;;; verified), so it was not compiled for the AVX2 target.

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
npm package, with its ELF interpreter patched for the Guix store.  For the variant
compiled from source with Bun's baseline (no-AVX2) target, install
@code{cline-baseline} instead; both provide the command @code{cline}.")
    (license license:asl2.0)))

;;; cline.scm ends here
