;;; channels-lock.scm --- pin every channel this CI builds against.
;; -*- scheme -*-
;; commentary:
;;
;; WHY THIS FILE EXISTS
;; ====================
;; The Install Guix step of .github/workflows/build.yml would otherwise run
;; `guix pull --fallback -C channels.scm' against %default-channels, i.e.
;; against the *tip* of guix master and nonguix master.  Both move daily.  So
;; a build that is green this morning can be red this afternoon with no change
;; to this repository at all, and the log then blames a package definition
;; that was not touched.  That is the largest single cause of the "CI is red
;; but I cannot reproduce it here" loop this channel has been stuck in.
;;
;; Passing this file to `guix pull -C' replaces that moving target with the
;; exact commits below, so the same SHA always resolves to the same package
;; definitions, on this machine and on the runner.  If a failure is a Guix or
;; nonguix regression it then stays red *on purpose* until the pin is bumped,
;; which is far easier to debug than a red that comes and goes.
;;
;; This is the pattern SystoleOS/guix-systole uses (a channels-lock.scm that
;; scripts/run-tests.sh hands to `guix time-machine -C').
;;
;; WHY IT LIVES IN tests/ AND IS NOT A MODULE
;; ==========================================
;; .guix-channel declares no (directory ...), so the repository root is Guile's
;; module load path and `guix pull` compiles *every* *.scm in the tree -- see
;; `standard-module-derivation' in guix/channels.scm.  A bare channel list is
;; not a module, so a channels-lock.scm at the root would break the pull for
;; *every user of this channel*, not just for CI.  tests/ is where such a file
;; belongs: it is still compiled (tests/build/ is the other such place), but it
;; is out of the load path, and tests/check-static.sh deliberately exempts it
;; so that this file does not have to pretend to be a module.
;;
;; `guix pull -C FILE' does not compile the file: guix/scripts/pull.scm:921
;; reads it with (load* file %safe-channel-bindings #:isolated? #t), i.e. in a
;; sandbox with no imports, where define-module is simply unbound ("error:
;; define-module: unbound variable").  So the file must stay a bare list and
;; the CI step must name it explicitly.  For the same reason it cannot `#:use-
;; module' anything -- `channel' and `make-channel-introduction' come from
;; (guix channels) via %safe-channel-bindings (guix/scripts/pull.scm:751),
;; not from this file.
;;
;; The commit pins are the payload.  The introductions are the security
;; boundary, not version pins: they say "trust this channel from this commit
;; onwards, signed by this key".  Do not edit them when bumping.  The guix one
;; is %guix-channel-introduction from guix/channels.scm; the nonguix one must
;; stay byte-identical to the one in .guix-channel and in build.yml.
;;
;; HOW TO BUMP
;; ===========
;;   ./tests/update-channels-lock.sh
;; which rewrites the two (commit ...) fields from `git ls-remote' and shows
;; the diff.  Review it: a Guix bump does change package definitions, so a
;; large diff is a signal, not noise.  A failing bump is the moment to decide
;; whether the regression is ours (fix the package) or upstream (re-pin one
;; commit back with --commit-1 <sha>).

(list (channel
        (name 'guix)
        (url "https://git.guix.gnu.org/guix.git")
        (commit "4341c003d7655ac02d72aea58cda706d87d0f965")
        (introduction
         (make-channel-introduction "9edb3f66fd807b096b48283debdcddccfea34bad"
          (openpgp-fingerprint
           "BBB0 2DDF 2CEA F6A8 0D1D E643 A2A0 6DF2 A33A 54FA"))))

      (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        (commit "c0192e90a52cafb4d33b04734cbe9bbedd703a04")
        (introduction
         (make-channel-introduction "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
          (openpgp-fingerprint
           "2A39 3FFF 68F4 EF7A 3D29 12AF 6F51 20A0 22FB B2D5")))))
