;;; Qoder <qoder@qoder.com>
;;; Copyright © 2026 Khalid Rafi <khaalidrafi@gmail.com>

(define-module (sane-packages ods)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix build-system copy)
  #:use-module ((guix build utils))
  ;; Runtime tools the `ods' CLI looks up on PATH; propagated so they land in
  ;; the same profile as `ods' itself.
  #:use-module (gnu packages docker) ;docker, docker-compose
  #:use-module (gnu packages curl)
  #:use-module (gnu packages web) ;jq lives here in this fork
  #:use-module (gnu packages python)
  #:use-module (gnu packages tls) ;openssl (certs for curl/docker)
  #:use-module (gnu packages version-control) ;git (the installer clones)
  ;; Build-side tools the generated wrapper calls by absolute store path.
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base) ;coreutils (cp, chmod)
  #:export (ods))

;;;
;;; ODS -- the Osmantic Deployment System.
;;;
;;; A self-hosted "private AI server" stack: Ollama/llama.cpp, Open WebUI,
;;; n8n, ComfyUI, RAG, TTS/STT, wired together with Docker Compose and driven
;;; by an `ods' command.  Upstream (https://osmantic.com) does not compile
;;; anything -- the product is the `ods/' tree of bash + python + docker-compose
;;; YAML, and `ods/ods-cli` is the entry point -- so this is a copy-style data
;;; package, not a compiled one.  There are no binary releases (source-only tags).
;;;
;;; Two facts drive the packaging:
;;;
;;; 1. Writable tree.  `ods-cli' reads and *writes* its `.env' and `data/'
;;;    inside the directory it resolves (see _resolve_cli_install_dir in
;;;    ods-cli: an INSTALL_DIR/ODS_HOME override, else the directory holding a
;;;    docker-compose file next to the realpath'd CLI, else $HOME/ods).  The
;;;    Guix store is read-only, so the CLI cannot run out of $out directly.
;;;    Upstream's own bootstrap (get-ods.sh) sidesteps this by rsyncing the
;;;    tree to $HOME/ods and operating there; the generated wrapper does the
;;;    same -- it seeds a writable working copy once and points INSTALL_DIR at
;;;    it -- so the immutable store holds the pristine source and the user's
;;;    mutable state stays under ODS_HOME.
;;;
;;; 2. Mixed license.  The root LICENSE and ods/LICENSE are Apache-2.0, but
;;;    ods/vendor/pixel/ is under the separate non-OSI "Pixel License for ODS"
;;;    (source-available, redistribution only *within* ODS -- see
;;;    ods/LICENSING.md).  Pixel is an optional dashboard: it appears nowhere
;;;    in ods-cli and its bundle is only referenced under ods/tests/, so we
;;;    delete the vendor/pixel* paths at install.  What remains is Apache-2.0,
;;;    which is why the package below can carry license:asl2.0.  Users who want
;;;    the Pixel dashboard must install it themselves under that license.
;;;
;;; Not verifiable on a build host: ODS needs a running Docker daemon (on Guix
;;; System, enable docker-service-type), and at run time it pulls third-party
;;; service images (pinned in ods/config/dependency-lock.json) -- those images
;;; are Docker's concern, never a Guix input.  systemctl/pgrep/nvidia-smi are
;;; likewise host tools, not declared here.

(define %ods-version
  "3.0.0")

(define %ods-commit
  "bec0c42e7c9885a5aecd419a166a6a81e0d37236")
; tag v3.0.0 (no submodules)

(define-public ods
  (package
    (name "ods")
    (version %ods-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Osmantic/ods")
             (commit %ods-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0rm184s07x9lfsrlky1vf444c53m1p7jcdfr3x98h7z7m4a9zanl"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:imported-modules '((guix build copy-build-system)
                           (guix build utils))
      #:modules '((guix build copy-build-system)
                  (guix build utils))
      ;; Only the `ods/' subtree is the product; `installer/' is a separate
      ;; optional Tauri GUI and the repo root is docs/CI, neither of which the
      ;; CLI needs.
      #:install-plan
      #~'(("ods" "share/ods"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'prune
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((tree (string-append (assoc-ref outputs "out")
                                         "/share/ods")))
                (for-each delete-file-recursively
                          ;; Non-OSI Pixel source (optional dashboard only).
                          (list (string-append tree "/vendor/pixel")
                                (string-append tree "/vendor/pixel.bundle")
                                (string-append tree
                                 "/vendor/PIXEL-SOURCE-PROVENANCE.md")
                                ;; Development trees upstream itself leaves out
                                ;; when installing.
                                (string-append tree "/tests")
                                (string-append tree "/docs")
                                (string-append tree "/examples")))
                ;; The git archive may not keep the executable bit on every
                ;; script; make the CLI and all shell helpers runnable.
                (for-each (lambda (f)
                            (chmod f #o755))
                          (cons (string-append tree "/ods-cli")
                                (find-files tree "\\.sh$"))))))
          (add-after 'prune 'create-launcher
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin/ods"))
                     (bash (assoc-ref inputs "bash-minimal"))
                     (coreutils (assoc-ref inputs "coreutils"))
                     (tree (string-append out "/share/ods")))
                (mkdir-p (dirname bin))
                (call-with-output-file bin
                  (lambda (port)
                    ;; Every value below is a store path or shell literal, so
                    ;; no user input reaches the shell (no injection surface).
                    (format port "#!~a/bin/bash\n" bash)
                    (format port
                     "# Wrapper for ODS: seed a writable working copy, run ods-cli.
")
                    (format port "set -e\n")
                    (format port "ods_home=\"${ODS_HOME:-$HOME/ods}\"\n")
                    (format port "cu=\"~a/bin\"\n" coreutils)
                    ;; Seed once, never clobber: if the user already has a tree
                    ;; (their .env, data/, extensions), leave it alone.
                    (format port "if [ ! -e \"$ods_home/ods-cli\" ]; then\n")
                    (format port "  mkdir -p \"$ods_home\"\n")
                    (format port "  \"$cu/cp\" -a \"~a/.\" \"$ods_home/\"\n"
                            tree)
                    (format port "  \"$cu/chmod\" -R u+w \"$ods_home\"\n")
                    (format port "fi\n")
                    ;; INSTALL_DIR makes ods-cli operate on the writable copy.
                    (format port "export INSTALL_DIR=\"$ods_home\"\n")
                    (format port
                            "exec \"~a/bin/bash\" \"$ods_home/ods-cli\" \"$@\"
"
                            bash)))
                (chmod bin #o755)))))))
    (inputs (list bash-minimal coreutils))
    (propagated-inputs (list docker
                             docker-compose
                             curl
                             jq
                             python
                             git
                             openssl))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://github.com/Osmantic/ods")
    (synopsis "Self-hosted private AI server stack driven by Docker Compose")
    (description
     "ODS (the Osmantic Deployment System) installs and operates a
self-hosted AI server: Ollama or llama.cpp for inference, Open WebUI as the
web front end, and optional services such as n8n, ComfyUI, RAG, and
text-to-speech/speech-to-text, all wired together with Docker Compose and
managed through the @code{ods} command.  The first run copies the application
tree into a writable working directory (@env{ODS_HOME}, default @file{$HOME/ods})
where it keeps its configuration and data; from there @command{ods} brings the
stack up.  A running Docker daemon and network access to pull the service images
are required at run time.")
    (license license:asl2.0)))
