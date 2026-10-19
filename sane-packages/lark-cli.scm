;;; sane-packages --- lark-cli: the official Lark/Feishu command line tool.
;;; Commentary:
;;;
;;; Upstream (https://github.com/larksuite/cli) publishes the tool not as a
;;; tarball of source but as a tiny downloader on npm (@larksuite/cli, a
;;; 48 KB package whose run.js execs a binary it fetches on first run) plus
;;; one prebuilt Go binary per platform on GitHub Releases.  The npm package
;;; carries checksums.txt, the sha256 of every release archive, which is how
;;; the hash below can be confirmed before downloading the 49 MB binary.
;;;
;;; A store package cannot run a downloader: the first invocation would
;;; write into the read-only store, and a network fetch at run time is not
;;; reproducible.  So, like the other vendor binaries in this channel, the
;;; package skips the npm stub and installs the real per-platform binary
;;; directly, under the command name upstream itself uses, `lark-cli'.
;;;
;;; The binary is a static Go executable (no PT_INTERP, no DT_NEEDED), so no
;;; patchelf treatment is needed and the vendor bytes are left untouched;
;;; `validate-runpath?' is off because there is no dynamic section to check.
;;;
;;; Updating: bump %lark-cli-version, refresh the archive name's version in
;;; the URI and the sha256; upstream keeps historical releases downloadable.
;;; Only x86_64-linux is packaged, mirroring the other *-bin packages here.
;;;
;;; Code:

(define-module (sane-packages lark-cli)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %lark-cli-version
  "1.0.98")

(define %lark-cli-source
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/larksuite/cli/releases/download/v"
          %lark-cli-version "/lark-cli-" %lark-cli-version
          "-linux-amd64.tar.gz"))
    (sha256 (base32 "107y713xkwrwnl93mb4s399pi0mh8p5ldl5wv235kcmal2vxq4ja"))))

(define-public lark-cli-bin
  (package
    (name "lark-cli-bin")
    (version %lark-cli-version)
    (source
     %lark-cli-source)
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      ;; Static Go executable: nothing for the runpath validator to see, and
      ;; the vendor binary is installed byte-for-byte.
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan
      #~'(("lark-cli" "bin/lark-cli")
          ("LICENSE" "share/doc/lark-cli/LICENSE")
          ("README.md" "share/doc/lark-cli/README.md")
          ("CHANGELOG.md" "share/doc/lark-cli/CHANGELOG.md"))))
    (synopsis "Official Lark/Feishu command line tool (prebuilt)")
    (description
     "Lark CLI is the official command line interface for the Lark/Feishu
open platform.  It wraps the OpenAPI surface (messages, docs, sheets,
calendar, drive, and the rest) and ships agent skills, so scripts and AI
agents can act in a Lark workspace the same way a user would.  This package
installs the upstream prebuilt static Linux binary, not the npm downloader
stub, so it runs offline once installed.")
    (home-page "https://github.com/larksuite/cli")
    (license license:expat)))
