;;; sane-packages --- konaito: terminal-browser, a browser inside the
;;; terminal, TypeScript edition.
;;; Commentary:
;;;
;;; https://github.com/konaito/terminal-browser is a clean-room
;;; reimplementation of zenbu-labs/terminal-browser with no Electron: pure
;;; TypeScript driving a headless Chromium over CDP, rendering into the
;;; terminal through the kitty graphics protocol.  Upstream distributes it
;;; as the npm package @konaito/terminal-browser -- plain compiled ESM under
;;; dist/, not a bundle -- with a single dependency, puppeteer, whose
;;; `dependencies' closure is the whole runtime tree.
;;;
;;; The package therefore has the mcode-bin shape (install the npm artifact,
;;; give it a node_modules) but a generated dependency table, because the
;;; tree is a hundred packages rather than three: (sane-packages
;;; konaito-modules) holds one hash-verified origin per tarball, laid out
;;; flat, exactly as npm would install them; scripts/gen-konaito-node-tree.py
;;; writes it.  No npm machinery runs at build time, so nothing needs the
;;; network beyond downloading the tarballs Guix already verifies.
;;;
;;; Which Chromium it drives is a runtime concern, decided by the wrapper:
;;; puppeteer reads PUPPETEER_EXECUTABLE_PATH (getConfiguration.js of the
;;; puppeteer package) before falling back to its download cache, which a
;;; store build has none of.  The wrapper points that variable at
;;; chrome-headless-shell-bin by default -- the exact revision puppeteer
;;; itself pins -- and any other Chromium can be used by setting it before
;;; the wrapper runs.  `headless: "shell"' in upstream's browser.ts is what
;;; chrome-headless-shell is for; a full Chrome works too but repaints
;;; background pages less reliably.
;;;
;;; The smoke test renders a real page: --dump-frame launches the browser,
;;; navigates, waits for the first CDP screencast frame and writes it as a
;;; PNG, which exercises the whole chain (node, the module tree, CDP,
;;; chrome-headless-shell, software GL) without needing a kitty terminal.
;;;
;;; Code:

(define-module (sane-packages konaito)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages node)
  #:use-module (sane-packages chrome-headless-shell)
  #:use-module (sane-packages konaito-modules))

(define %konaito-version
  "0.1.0")

(define %konaito-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://registry.npmjs.org/@konaito/terminal-browser/-/terminal-browser-"
          %konaito-version ".tgz"))
    (sha256
     (base32 "10j55nl35xlrl4fiam1sj3kjzylz26jw5wjpcm73cg6hkf3rbh5l"))))

(define-public konaito-terminal-browser-bin
  (package
    (name "konaito-terminal-browser-bin")
    (version %konaito-version)
    (source
     %konaito-source)
    (build-system copy-build-system)
    ;; Pure JavaScript throughout, but the wrapper bakes in the store path
    ;; of chrome-headless-shell-bin, which is x86_64-only.
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:install-plan
      #~'(("dist" "share/konaito-terminal-browser-bin/dist")
          ("package.json" "share/konaito-terminal-browser-bin/package.json")
          ("README.md" "share/konaito-terminal-browser-bin/README.md")
          ("LICENSE" "share/konaito-terminal-browser-bin/LICENSE"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'unpack-node-modules
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (root (string-append out
                                          "/share/konaito-terminal-browser-bin"))
                     (nm (string-append root "/node_modules"))
                     (bsdtar (string-append (assoc-ref inputs "libarchive")
                                            "/bin/bsdtar")))
                (mkdir-p nm)
                ;; One tarball per row of the install plan: the label holds
                ;; the origin Guix fetched, the npm name is the directory
                ;; Node's bare-specifier walk looks for.  Scoped packages
                ;; install at node_modules/@scope/name like npm does.
                (for-each
                 (lambda (row)
                   (let* ((name (car row))
                          (label (cadr row))
                          (dest (string-append nm "/" name)))
                     ;; mkdir-p, not mkdir: a scoped package's parent
                     ;; (@scope) does not exist yet either, and bsdtar -C
                     ;; needs the destination itself present.
                     (mkdir-p dest)
                     ;; Every npm tarball has exactly one top-level
                     ;; directory, so one strip-components fits all.  bsdtar,
                     ;; not tar: some tarballs ship directories without the
                     ;; execute bit and GNU tar dies writing into them
                     ;; (zcode, CI run 37119444764), so the bits go back
                     ;; after extraction for what Node needs to descend.
                     (invoke bsdtar "xzf" (assoc-ref inputs label)
                             "--strip-components=1" "-C" dest)
                     (invoke "chmod" "-R" "u+rwx" dest)))
                 #$%konaito-node-install-plan))))
          (add-after 'unpack-node-modules 'make-wrapper
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (root (string-append out
                                          "/share/konaito-terminal-browser-bin"))
                     (bin (string-append out "/bin"))
                     (bash (string-append (assoc-ref inputs "bash-minimal")
                                          "/bin/bash"))
                     (node (string-append (assoc-ref inputs "node")
                                          "/bin/node"))
                     (shell (string-append (assoc-ref inputs
                                                      "chrome-headless-shell-bin")
                                           "/bin/chrome-headless-shell")))
                (mkdir-p bin)
                ;; The store paths written below are references the daemon
                ;; discovers by scanning output contents, so node and the
                ;; browser land in the closure without being propagated;
                ;; grafting rewrites them on security updates.
                (call-with-output-file (string-append bin
                                                      "/terminal-browser")
                  (lambda (port)
                    (format port "#!~a\n# Puppeteer reads this variable (its\n# getConfiguration.js) before touching its download cache; the default is\n# the store's chrome-headless-shell, the revision puppeteer pins.  Set it\n# to use any other Chromium.\nexport PUPPETEER_EXECUTABLE_PATH=\"${PUPPETEER_EXECUTABLE_PATH:-~a}\"\nexec \"~a\" \"~a/dist/main.js\" \"$@\"\n"
                            bash
                            shell
                            node
                            root)))
                (chmod (string-append bin "/terminal-browser") #o555)
                #t))))))
    (native-inputs
     ;; All labelled, mixing labelled and plain entries makes Guix label
     ;; the labelled ones twice (the dsh trap, see zcode's native-inputs).
     ;; bsdtar for the tarballs, then one hash-verified origin per npm
     ;; dependency, labelled by the name it installs under.
     (append (list (list "libarchive" libarchive))
             %konaito-node-inputs))
    (inputs
     (list bash-minimal node chrome-headless-shell-bin))
    (synopsis "Browser inside your terminal (kitty graphics + CDP, no Electron)")
    (description
     "Terminal-browser renders a real Chromium inside kitty, ghostty or
WezTerm: pages are screenshotted over CDP and displayed with the kitty
graphics protocol, and keyboard input is replayed into the browser.  A
@code{--headless} mode serves a socket action API (@code{snapshot},
@code{click}, @code{fill}, @code{eval}) for driving pages from scripts or
agents.  This package installs the upstream npm release with its whole
puppeteer dependency tree, and launches the chrome-headless-shell build
Puppeteer pins as the engine; override @code{PUPPETEER_EXECUTABLE_PATH} to
point it at another Chromium.")
    (home-page "https://github.com/konaito/terminal-browser")
    (license license:expat)))
