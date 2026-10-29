;;; @konaito/terminal-browser's npm dependency tree, generated at
;;; packaging time; do not edit.
;;;
;;; One row per tarball the CLI's own dependencies need at run time:
;;;   (npm-name version sha256)
;;; laid out flat under node_modules/, which is npm's own layout and resolves
;;; every bare specifier because the tree has no version conflicts (the
;;; generator refuses to emit a table otherwise).  Refresh after bumping
;;; %konaito-version in (sane-packages konaito):
;;;
;;;   ./scripts/gen-konaito-node-tree.py <version> \
;;;       > sane-packages/konaito-modules.scm
;;;
;;; The generator resolves every `dependencies' range the way npm would,
;;; ignores dev/peer/optional dependencies, downloads each tarball once into
;;; $KONAITO_DEP_CACHE to hash it, and prints nix-base32 sha256s -- what
;;; Guix's `base32' reader expects.

(define-module (sane-packages konaito-modules)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix base32)
  #:use-module (ice-9 match)
  #:export (%konaito-node-modules %konaito-node-install-plan
            %konaito-node-inputs konaito-input-name))

(define (konaito-npm-origin name version digest)
  "Return the origin of npm package NAME at VERSION as a tarball, where DIGEST
is the nix-base32 sha256 of that tarball.  These origins are build inputs, so
each one only downloads and verifies; the build unpacks them into the flat
node_modules tree.  A scoped package is served under /@scope/ but its file
name drops the scope: @puppeteer/browsers is fetched as
/@puppeteer/browsers/-/browsers-<version>.tgz."
  (let* ((scoped (string-prefix? "@" name))
         (parts (string-split name #\/))
         (scope (car parts))
         (base (if scoped (cadr parts) name)))
    (origin
      (method url-fetch)
      (uri (string-append "https://registry.npmjs.org/"
                          (if scoped (string-append scope "/") "")
                          base "/-/" base "-" version ".tgz"))
      (sha256 (base32 digest)))))

(define %konaito-label-replacements
  ;; npm names may contain characters an input label cannot: '/' separates
  ;; the label from the derivation path and '@' has meaning in labels.  Each
  ;; such character expands to a distinct two-letter tag, so two different
  ;; names cannot collapse onto the same label.  Same table zcode uses.
  '((#\/ . "-sl-") (#\@ . "-at-")))

(define (konaito-input-name name)
  "Return the build-input label for the tarball that belongs at
node_modules/NAME."
  (list->string
   (apply append
          (map (lambda (character)
                 (let ((hit (assq character %konaito-label-replacements)))
                   (if hit (string->list (cdr hit)) (list character))))
               (string->list name)))))

(define %konaito-node-modules
  ;; (name version sha256), one row per runtime dependency, sorted by name.
  (list
    (list "@babel/code-frame" "7.29.7" "0rwwq509ywaizggi0l54awqr6xag3wzl8cxd84mxgldml1pig2zs")
    (list "@babel/helper-validator-identifier" "7.29.7" "07ywjzwh0xw22zazdw2bzckllvr929ypkpg5slrb46szqi5r0cbs")
    (list "@puppeteer/browsers" "2.13.2" "1smmbd2z9sg5zc7fmyy5qmz64zzj2p2fsg2ciqyizymcz4d2gi7s")
    (list "@tootallnate/quickjs-emscripten" "0.23.0" "1pj0barbvvqkbyy6ak8ql3cbn6sm29fs33rv4s4g31bg5bfwpcn9")
    (list "@types/node" "26.6.5" "1pyvr1d64x10rc7v68zfssf9sacn6fwachwhlxdals84hsn7vr74")
    (list "@types/yauzl" "2.10.3" "0y1mkflnfxxrk8vf4a5yxsj4jb6sf7mhgqja39bc8d72k6ylm0xp")
    (list "agent-base" "7.1.4" "0zmmkk3xhnkwb6djnvri7zyxllsdz5aa5w83x7afi959d0badm3x")
    (list "ansi-regex" "5.0.1" "1ng0r2k4mcz7b2bfr6g1dschnxm0vifaslsvv2smv06smb6ss3hf")
    (list "ansi-styles" "4.3.0" "0zwqsx67hr7m4a8dpd0jzkp2rjm5v7938x4rhcqh7djsv139llrc")
    (list "argparse" "2.0.1" "133jjyhcr25rf4vy7bca7x06dfmsyy819s1kbbyfc5c2zi3ki417")
    (list "ast-types" "0.13.4" "1z20hhv2vac4addxa2lz13npir3bj9vls8fxdpa89f8h5iwd48ay")
    (list "b4a" "1.9.0" "1id9nmk1jim13q7s2xrvxj65lji96iam2c3prirdm2x03qvg0nfy")
    (list "bare-events" "2.9.2" "1bll0p1h1gqgb6wskm8sjmil5afwzwrql5zq917zw46njv47a04k")
    (list "bare-fs" "4.8.4" "120qj44v87zicgacid72n6mzkypxbkmyag1jhsmaywnqx50w0as1")
    (list "bare-path" "3.1.2" "0lmg82qvmnw41cqi4z60qh9c3vvx5f96ypg9ryij45fc5q1hch6d")
    (list "bare-stream" "2.13.4" "1la03x7wayafbjs7vvfpjycnfk6nd2dk32khczbmapv35sqqjkpv")
    (list "bare-url" "2.5.5" "0wgxz10d1rawf47x7py4rib3shgrqr7xvnlqww5rh3y60h3g744a")
    (list "basic-ftp" "5.3.1" "0z51l42jzpl61nac5w1lsjlzjilnpacq3n2k86sf8blqhm4rwl77")
    (list "buffer-crc32" "0.2.13" "0vf6adpqimbz921y729mf91pvghihj44js2ck5ci44zh4x21bl97")
    (list "callsites" "3.1.0" "17f8wf2bxv2s4k36ld1x4y2rbkh9a8vsmbhwab470vmz6ayl40hp")
    (list "chromium-bidi" "14.0.0" "0klq2470rhypi9p4lgjrz8nm6yn76vqkzlz0bir9009jwh8sdz02")
    (list "cliui" "8.0.1" "13cc8rvmzcvvlvf2prwxj1zjyxhybsznl1nirnlrwd4abvid3yny")
    (list "color-convert" "2.0.1" "1qbw9rwfzcp7y0cpa8gmwlj7ccycf9pwn15zvf2s06f070ss83wj")
    (list "color-name" "1.1.4" "020p7x7k8rlph38lhsqpqvkx0b70lzlmk6mgal9r9sz8c527qysh")
    (list "cosmiconfig" "9.0.2" "07ah0k5qmmv3bfrjvp6zlqq29iyxdc34d5in9046glr676w2z7p7")
    (list "data-uri-to-buffer" "6.0.2" "1142i1m7bj0i6si14gglj7xl5mg4g8xhipdcp0dh6w8jn6r3ggs8")
    (list "debug" "4.4.3" "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9")
    (list "degenerator" "5.0.1" "1lrrh34czv0nphhwiaxr91z0jygvh8j3v1z7fz8gz2hdfid0r4sb")
    (list "devtools-protocol" "0.0.1608973" "0vbmvrp0xl0i9l0cyb423df7l6xvpp5i9xlcimrjmqv1nrfy8x0s")
    (list "emoji-regex" "8.0.0" "01xi3ikahnlj77h2gqs3jb7kmnxn1nsb9dmnpvpqw288zgxxkk5m")
    (list "end-of-stream" "1.4.5" "02d3hkin7l3ac84mn3icdm1dp30khbx9v5x4ndvjnr6w61h2m73d")
    (list "env-paths" "2.2.1" "17knwv8glmap1vcgca11h1r48hyards94slc83y9z02q857qj2ss")
    (list "error-ex" "1.3.4" "11s6fgpcsfkrnr7n1j9xhc6kx0pyy1p0ygcld9xdqq27wx9mzpl9")
    (list "escalade" "3.2.0" "1rxy0388xsgxam8limnbxhksa1z1xccd47vi4r9p1ip6q2pma9xs")
    (list "escodegen" "2.1.0" "14vmy0mzr0ndpd3zavw3phanw49mxf7j24ayf99fvbc190xzvlh6")
    (list "esprima" "4.0.1" "0x6cjgh4452wa28yz562b4c2dad78rn3fxfzqns9bk5ykh7938fq")
    (list "estraverse" "5.3.0" "19pxf86qwp2xl1i8k5w6q81aaldmspmgys0ksnla91c0bgd4b39y")
    (list "esutils" "2.0.3" "03v4y32k50mbxwv70prr7ghwg59vd5gyxsdsbdikqnj919rvvbf5")
    (list "events-universal" "1.0.1" "1snjpml0ss6bgs3p6cqajywiwh6cyhnvyjshwabyh2xk2lfl1w48")
    (list "extract-zip" "2.0.1" "1d6sffrprp0na74i7yaprqhdhlr2n3znws509jv7nqgscypf1d2r")
    (list "fast-fifo" "1.3.2" "0jjpyvjzhzi9hxczql8gss5gfagfil8ggadk54vx21lsd2avq7d7")
    (list "fd-slicer" "1.1.0" "08w8mwdkaadagyhh61cppma7a4l9z13rlbrxz14ys6r7xfp26s6c")
    (list "get-caller-file" "2.0.5" "0pwk4r8iyyq2j0xpxavdm3ldb4h4k4s4xb74m8dlrzs9374f24vv")
    (list "get-stream" "5.2.0" "077iv0jqfgqyxw6jb0iradw9idjcmphmrc58zj050vf58yx0bzkr")
    (list "get-uri" "6.0.5" "0iv2zgnp7xlfsi7g7bdw9slbvnnz9gzfq03vpx8v9c7z8ihx1v91")
    (list "http-proxy-agent" "7.0.2" "00kgi96l0vs04g2vl2xw3g53saxb4n9za2x23pbaiyrbm7x76pvq")
    (list "https-proxy-agent" "7.0.6" "1q603cjw6z348j2i7k7s5zb3kp91hi9lml298bv84214wpl8j3wn")
    (list "import-fresh" "3.3.1" "1xsgyzk76d3w7nwk7yf9rl795xwn0dzk054wy7c8b9diw98g8q6d")
    (list "ip-address" "10.7.4" "1zr6by3fyghii67f38c0s1v8w1y889cy6vhcfx1jy04w6vfx1qgr")
    (list "is-arrayish" "0.2.1" "13734x7w9924g9pch6ywgz741hs5ir612k3578k9fy247vcib3c4")
    (list "is-fullwidth-code-point" "3.0.0" "0jmw03rxmbwbrkx0a8wq05qsjhdrx9jn3vns88dhy1y6bnp5shbg")
    (list "js-tokens" "4.0.0" "0lrw3qvcfmxrwwi7p7ng4r17yw32ki7jpnbj2a65ddddv2icg16q")
    (list "js-yaml" "4.3.2" "1cg5rqg09lgzlfihykcwi2yr3nl7xr6alm1qylzjbyac4b943cn7")
    (list "json-parse-even-better-errors" "2.3.1" "0s95hppvdm62vq9ax92bl7dpgs28dp97j6xlrka1q25bc797g1ra")
    (list "lines-and-columns" "1.2.4" "174sl99srzs7c0a9l7q73dqmlczgbji9aqh028y2y6c54g8r47s7")
    (list "lru-cache" "7.18.3" "0zfliwgajml2qzrx8wqdmm74ilnfad79y5jaj06zxj8gsrcas5d5")
    (list "mitt" "3.0.1" "01kkdp9ccd5jn728p9hr3y9ha5wciknhmcxqzn35pbbljmk9rxif")
    (list "ms" "2.1.3" "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn")
    (list "netmask" "2.1.1" "0ysp4vsddgxdw746pa372b6bspwjw1c83mcpyqwf2b4z73dj3n2n")
    (list "once" "1.4.0" "1kygzk36kdcfiqz01dhql2dk75rl256m2vlpigv9iikhlc5lclfg")
    (list "pac-proxy-agent" "7.2.0" "1m4kcmrsilsl2lr19iq7n5y2wpim4ixfcgp2v5fvgrk70xvamryk")
    (list "pac-resolver" "7.0.1" "0d0ngs3wc85s4fcbxlhihq0zp0d0hmpg0jhrqdwwf270n1lwm1nr")
    (list "parent-module" "1.0.1" "01z4k8a3y21gqmpcwyf7gq9v8v4k2y5180f5g7qgswd4gq986zk0")
    (list "parse-json" "5.2.0" "1388gc6zhgygqc68vkmqxafk6r9kxgdqqwbbm96k9hpxw223ddq6")
    (list "pend" "1.2.0" "0zvd8cli24vpvgsf9ldmm5ibivmx02njp2d9a85p3px94ndjfbx1")
    (list "picocolors" "1.1.1" "1nc2z3w16wpz2840srcwyxd747khwfvh66yigyrpwywn0wldpbnk")
    (list "progress" "2.0.3" "191ax3hag867ggjsn6wh1b00bp5iippxsml7fyxf7h7nizhna63h")
    (list "proxy-agent" "6.5.0" "1byd0nqnrchxhbzxb1hqli9wkq873p6lwvj03c6vq8xqpv5vfp4k")
    (list "proxy-from-env" "1.1.0" "03yy2xm903581x3vmklhp06dlxgipz10d4vhx69sqg2xy1a2824l")
    (list "pump" "3.0.4" "0dlv9kb9py5sgiv935266khkb284iqfyhcqbpgd5q0rh9kycfn1w")
    (list "puppeteer" "24.43.1" "1fnzr4561rp4agnpp9p254nmm7zk1lm8bhm8bc08yybb5bndkpkr")
    (list "puppeteer-core" "24.43.1" "007ljv316rr3rd6bgxd0dhd26pbnll4mvbfd4xknhszs4sx3x1dn")
    (list "require-directory" "2.1.1" "1j46ydacaai73mx5krskl0k78r32lnjx94l79bz860rn8h4fwfvh")
    (list "resolve-from" "4.0.0" "1p11030pz8qdm9x2d9q0qi2p329447i2bb7a5j7hbsxxqbs2hhi4")
    (list "semver" "7.8.5" "0pbx2afqpl5na8j25kgz496g6wrfaggrasrkj745fz8d63a4al6q")
    (list "smart-buffer" "4.2.0" "18ahcjprcl5mr719dxpzh7kq1lylnwzf7j3bmi3vkgnirgj1b61x")
    (list "socks" "2.8.10" "003q4g1086qyf08zrw5iwy3fn0d2r2i7xcjgs0rw6npc3cbhf941")
    (list "socks-proxy-agent" "8.0.5" "1xn1zw629fi49gyjnq4ymncv6zd0mgpjh28rmxmyp10z628syffl")
    (list "source-map" "0.6.1" "11ib173i7xf5sd85da9jfrcbzygr48pppz5csl15hnpz2w6s3g5x")
    (list "streamx" "2.28.1" "0ia793djl6iqb28raz4wvkfvrx493q8f6sp053mfmsrgbxydlndb")
    (list "string-width" "4.2.3" "0d19spdisrqxd6311fc7z1yg34ww6rwh1zxdk6pnk03fnaqlzfxd")
    (list "strip-ansi" "6.0.1" "1jh81jj6cn1lli1c7m6xi0ynra9zdghb1g63v1nib7zlpz87bnwv")
    (list "tar-fs" "3.1.3" "0kwb8i2lzy4prbxxrjnmrp2gc83i5jmcbhfnwpdsy2mjdfxch5ki")
    (list "tar-stream" "3.2.2" "1xnxfqn9mv8wfpgi3ni5wd6sccb3s5dpr0wcrpgvcbxl81jg5nva")
    (list "teex" "1.0.1" "1s7ygzc588158jhgpnvbxwk89s0ps0sjpn6335pxykznxsmsxgwg")
    (list "text-decoder" "1.2.7" "1rhjcsgz1290hql5sa66xn2j0k6mfsg924byj601czv9s4k1qzxr")
    (list "tslib" "2.8.1" "17hiw9pawyczkhsnhlq4k9dn3kq2l49nk5rlfn049bmbxvakbxk6")
    (list "typed-query-selector" "2.12.3" "1hxkw2l5r9385wnghx93l691hy9bz9656vhxsmxnw8nd5q5q2pk1")
    (list "undici-types" "8.9.0" "1ikq7qx4grfa4k5pg93snwd2lzlxh7mki2mc1sr2245zri8phn1s")
    (list "webdriver-bidi-protocol" "0.4.1" "0vnc51n6ndl08r7jqnff584w831ikygjpym8dd5dwi74fx10blvb")
    (list "wrap-ansi" "7.0.0" "0bx4bkwfli34343rl97qy5pdg3zmskinsf8mlkv3isfj1d8v7587")
    (list "wrappy" "1.0.2" "1yzx63jf27yz0bk0m78vy4y1cqzm113d2mi9h91y3cdpj46p7wxg")
    (list "ws" "8.22.0" "1j5bwyagz7a0vk0j61ikkfq15ah10ppm0gviqvxfh771nac3g6ya")
    (list "y18n" "5.0.8" "0sd7mpg2c0fxqq4q2574hvm26fgy6byp1gxnsgskmjx7sfx46dyl")
    (list "yargs" "17.7.3" "0zkiz00wclf5vkgmwiz64022dnkabwbxpzkvkkddiw3l8s1k1b3n")
    (list "yargs-parser" "21.1.1" "0lcif2zbzw2jfj63paq2wdgc1hs9fd8i2xzjcidjcwjagm97sarl")
    (list "yauzl" "2.10.0" "1cbcq82bafcifhliglwjzp6b898qawrzng8315rh0r3vbn1k23sm")
    (list "zod" "3.25.76" "0xw3m1qdqbqam3fhxiv8ag9l9kampywwx4gfcjmis36xy02il7wy")
    ))

(define %konaito-node-install-plan
  ;; npm name -> input label, which is all the builder needs: it unpacks the
  ;; label's tarball into node_modules/<name>.
  (map (match-lambda
         ((name version digest) (list name (konaito-input-name name))))
       %konaito-node-modules))

(define %konaito-node-inputs
  ;; One labelled origin per npm tarball.
  (map (match-lambda
         ((name version digest)
          (list (konaito-input-name name)
                (konaito-npm-origin name version digest))))
       %konaito-node-modules))
