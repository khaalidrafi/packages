;;; dsh's npm dependency tree, generated at packaging time; do not edit.
;;;
;;; One row per tarball npm installs for @deepseek-ai/dsh on linux-x64:
;;;   (npm-name version sha256 install-path)
;;; INSTALL-PATH is relative to the package directory and is also where npm
;;; would unpack it, nested node_modules included.  To refresh this file after
;;; bumping dsh: extract the new tarball, run
;;;   npm install --package-lock-only --ignore-scripts --no-audit --no-fund
;;; in it, keep the packages whose os/cpu/libc fields still match linux-x64,
;;; hash every remaining registry tarball with `guix hash -f nix-base32', and
;;; emit one row per package at the install path the lockfile names.

(define-module (sane-packages dsh-modules)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix base32)
  #:use-module (ice-9 match)
  #:export (%dsh-node-modules %dsh-node-bin-links %dsh-node-inputs
            %dsh-node-install-plan dsh-npm-origin dsh-input-name))

(define (dsh-npm-origin name version digest)
  "Return the origin of npm package NAME at VERSION as a tarball, where
DIGEST is the base-32 sha256 of the tarball.

These origins are used as build inputs, so each one only downloads and
verifies; the dsh build unpacks them into its node_modules tree."
  ;; Scoped packages live under /@scope/ but their file name drops the scope:
  ;; @img/sharp-linux-x64 is served as /@img/sharp-linux-x64/-/sharp-....tgz.
  (let* ((parts (string-split name #\/))
         (scoped (string-prefix? "@" name))
         (scope (and scoped (car parts)))
         (base (if scoped (cadr parts) name)))
    (origin
      (method url-fetch)
      (uri (string-append "https://registry.npmjs.org/"
                          (if scoped (string-append scope "/") "")
                          base "/-/" base "-" version ".tgz"))
      (sha256 (base32 digest)))))

(define (dsh-input-name install-path)
  "Return the build-input name under which the tarball that belongs at
INSTALL-PATH is handed to the build.  Install paths are unique, so sanitising
one identifies the dependency it holds: \"node_modules/@img/sharp-linux-x64\"
becomes \"node-modules-img-sharp-linux-x64\"."
  (list->string
   (map (lambda (c) (if (or (char=? c #\/) (char=? c #\@) (char=? c #\_))
                        #\-
                        c))
        (string->list install-path))))

(define %dsh-node-modules
  (list
   (list "@agentclientprotocol/sdk" "1.4.0"
         "0dss6rj7zxr6w1dpahjc1dl4068ld8glv66cbdp402avf3vv1gjp"
         "node_modules/@agentclientprotocol/sdk")
   (list "@anthropic-ai/sdk" "0.123.0"
         "1gznmv3ql2l49m5djgils7iairp2h3d558smmr6wfivphdl43zfy"
         "node_modules/@anthropic-ai/sdk")
   (list "@aws-crypto/sha256-browser" "5.2.0"
         "13f23v4d91h48a6j6j9517vzywa6rp9y3hdsb7ns9z04g2y38900"
         "node_modules/@aws-crypto/sha256-browser")
   (list "@aws-crypto/sha256-js" "5.2.0"
         "0sm9wi14sj7qsscgdwpfkss1slc5s8r4by7glvi5kqdi9y5n6l2p"
         "node_modules/@aws-crypto/sha256-js")
   (list "@aws-crypto/supports-web-crypto" "5.2.0"
         "1f3x1j89zi8hdnf8sdyidslklcf8kvgvl3clixj50rb10z6r216l"
         "node_modules/@aws-crypto/supports-web-crypto")
   (list "@aws-crypto/util" "5.2.0"
         "1lvjyz8d2g5lpy6wxfhqgyji61nz8qzl62g04awjhnfvgayrmaj2"
         "node_modules/@aws-crypto/util")
   (list "@aws-sdk/client-bedrock-runtime" "3.1048.0"
         "0ayqqflicslxm612s8bcc5gg23a5nxlkfz7n8h6g161k9lbvhkkj"
         "node_modules/@aws-sdk/client-bedrock-runtime")
   (list "@aws-sdk/core" "3.978.1"
         "0hdmi91y48rda2wckg87vb0m3pzv7sn6s9gsfcx1akybz9kdh36n"
         "node_modules/@aws-sdk/core")
   (list "@aws-sdk/credential-provider-env" "3.972.72"
         "0s11dbi6izs83kjpbyywl2zc1mjyh8dz67hcij8dc6iyxv716a59"
         "node_modules/@aws-sdk/credential-provider-env")
   (list "@aws-sdk/credential-provider-http" "3.972.74"
         "19fi7h8q5lnyldk81fk3lyxf8al7w2alcqmgqviqrhhq67nxl8fp"
         "node_modules/@aws-sdk/credential-provider-http")
   (list "@smithy/node-http-handler" "4.12.1"
         "1swfrzyf91lxpmzzqymvwplsh8nsi1dgpi7bbw4nvqfyzccmkl79"
         "node_modules/@aws-sdk/credential-provider-http/node_modules/@smithy/node-http-handler")
   (list "@aws-sdk/credential-provider-ini" "3.973.17"
         "06a0avxwis4lipkgr5rvnazcpj6x3gm55270h8kpcjlzigm7d9qj"
         "node_modules/@aws-sdk/credential-provider-ini")
   (list "@aws-sdk/credential-provider-login" "3.972.79"
         "1rfzcj7x85li4n6fbhl860s380zy5giq98xspmvryyg1jxmn5rm6"
         "node_modules/@aws-sdk/credential-provider-login")
   (list "@aws-sdk/credential-provider-node" "3.972.84"
         "0fgwwwssl2f4jy1wp7ynxw0gp5i4lhp10mf18gg3x3g35wm2ffbr"
         "node_modules/@aws-sdk/credential-provider-node")
   (list "@aws-sdk/credential-provider-process" "3.972.72"
         "0sb0qph0w2f90lh11wg8n17ld9wh1n441mv46zia5lfziiw99rmk"
         "node_modules/@aws-sdk/credential-provider-process")
   (list "@aws-sdk/credential-provider-sso" "3.973.16"
         "0a4ixz4ja2pdcj47zcb4y58015k7j0i2i3dsx886dksahi9s340f"
         "node_modules/@aws-sdk/credential-provider-sso")
   (list "@aws-sdk/token-providers" "3.1138.0"
         "19my2xcfwk37fs6wmrbg4aywxw8l5wxzb4kqd8x4rp1hqzpyxmz4"
         "node_modules/@aws-sdk/credential-provider-sso/node_modules/@aws-sdk/token-providers")
   (list "@aws-sdk/credential-provider-web-identity" "3.972.78"
         "1qcfhalicgz4xqjr6dfrw9zl19m900x6f69x5hz5cy07p1j91zm9"
         "node_modules/@aws-sdk/credential-provider-web-identity")
   (list "@aws-sdk/eventstream-handler-node" "3.972.35"
         "10h89kna4qs2vvbf0bczqg4xr8dfsi4n8wdfaav4p7b00n6hgax3"
         "node_modules/@aws-sdk/eventstream-handler-node")
   (list "@aws-sdk/middleware-eventstream" "3.972.30"
         "0w3d36gxdbvmr3zqcc7jsyqiqysdi0fg1g9d7zd3naxmx8jv45i6"
         "node_modules/@aws-sdk/middleware-eventstream")
   (list "@aws-sdk/middleware-websocket" "3.972.54"
         "13xvgdqwwz97ic7pdfipgf2881zjd7kffyms87v66354gxs5jhhw"
         "node_modules/@aws-sdk/middleware-websocket")
   (list "@aws-sdk/nested-clients" "3.997.46"
         "0am7ciyaqixm0cnd1b0rcbgcyc2hhgkamj79hvxhc08hvpfbzj9j"
         "node_modules/@aws-sdk/nested-clients")
   (list "@smithy/node-http-handler" "4.12.1"
         "1swfrzyf91lxpmzzqymvwplsh8nsi1dgpi7bbw4nvqfyzccmkl79"
         "node_modules/@aws-sdk/nested-clients/node_modules/@smithy/node-http-handler")
   (list "@aws-sdk/signature-v4-multi-region" "3.996.47"
         "0mih1f1bayl0ir78nrqkjw8wr2jx55afyyx9843jnkl4f63hv8vr"
         "node_modules/@aws-sdk/signature-v4-multi-region")
   (list "@aws-sdk/token-providers" "3.1048.0"
         "1bsk3lx3iry076imksh7n2s1cfminlvx1vfqw5qgw0z6fz1rbvlw"
         "node_modules/@aws-sdk/token-providers")
   (list "@aws-sdk/types" "3.974.6"
         "1zwnhajmq6z6iypbjkhvbwsqf1bsy8c0wji8n8hm2y4iqk81dzb2"
         "node_modules/@aws-sdk/types")
   (list "@aws-sdk/util-locate-window" "3.965.10"
         "1599bac8yi7ii1dv6488rzjzs64j467a07kzziv2gaf1j0cmx6cs"
         "node_modules/@aws-sdk/util-locate-window")
   (list "@aws-sdk/xml-builder" "3.972.41"
         "091c2kns2bprb36xvzpdwjsps10k68z6ch6pjmz3f0m8zfb2zd1l"
         "node_modules/@aws-sdk/xml-builder")
   (list "@aws/lambda-invoke-store" "0.3.0"
         "0rxniijkjvx2qpbgd2d2s70j3i70dfqvbgb8jskkqikfy7bq9lcs"
         "node_modules/@aws/lambda-invoke-store")
   (list "@babel/code-frame" "7.29.7"
         "0rwwq509ywaizggi0l54awqr6xag3wzl8cxd84mxgldml1pig2zs"
         "node_modules/@babel/code-frame")
   (list "@babel/helper-validator-identifier" "7.29.7"
         "07ywjzwh0xw22zazdw2bzckllvr929ypkpg5slrb46szqi5r0cbs"
         "node_modules/@babel/helper-validator-identifier")
   (list "@babel/runtime" "7.29.7"
         "19csnq2xy2ny8kr03vfjcq35z1l46b8kiiswc93lv9m10bainzsd"
         "node_modules/@babel/runtime")
   (list "@deepseek-ai/cordis" "4.0.4"
         "0p0q4x4mb4crr95wdafkyx35sn19zpfa3qxl7h1wndyy8jrwv9cr"
         "node_modules/@deepseek-ai/cordis")
   (list "@deepseek-ai/cordis-plugin-group" "1.0.4"
         "1p3c9q7ar4dqsd6aa7gkm9r6v213w28bngyd7b73x4xjvcy9x7qz"
         "node_modules/@deepseek-ai/cordis-plugin-group")
   (list "@deepseek-ai/cordis-plugin-include" "1.0.9"
         "1v4r71ydr05v48gls2gva1si9azndx26b5qn6631y0d2ywc8bsjd"
         "node_modules/@deepseek-ai/cordis-plugin-include")
   (list "@deepseek-ai/cordis-plugin-loader" "1.0.5"
         "12p5q6isd128bbs0cihd8d4kpl4ywbcsjk7jgkm1lf57wyhnc5sx"
         "node_modules/@deepseek-ai/cordis-plugin-loader")
   (list "@deepseek-ai/cordis-plugin-timer" "1.1.6"
         "07s711awki9fhg06k2dahppl6apjncyzgcjc7ywh3f9ri2zqdwsy"
         "node_modules/@deepseek-ai/cordis-plugin-timer")
   (list "@deepseek-ai/cosmokit" "1.8.5"
         "0r7ynhzsg6632zjnwxda9vvdcnip8n9q4rhmk94r097kqg220jcs"
         "node_modules/@deepseek-ai/cosmokit")
   (list "@deepseek-ai/dsh-acp" "0.1.7-rc.1"
         "1prc1p6vf9wkw86kq6skdgm3fc4s5l0kx4sywy2g4j05nakcsjia"
         "node_modules/@deepseek-ai/dsh-acp")
   (list "@deepseek-ai/dsh-acp-app" "0.1.7-rc.1"
         "1aq7rvcnzva4l5mlhdnwq7ym4b4g2g1xng8lpldr80na9k1ahvkk"
         "node_modules/@deepseek-ai/dsh-acp-app")
   (list "@deepseek-ai/dsh-agent" "0.1.7-rc.1"
         "0qw1ds79lrgmsnnh0908g690prr84bc3md31bg071xn3qdm2cn0l"
         "node_modules/@deepseek-ai/dsh-agent")
   (list "@deepseek-ai/dsh-agent-default-model" "0.1.7-rc.1"
         "1x9n7wksa3rc36s8xxxmvgn6fv1hzybvhph40nxpikn4r3p99lg1"
         "node_modules/@deepseek-ai/dsh-agent-default-model")
   (list "@deepseek-ai/dsh-agent-instructions" "0.1.7-rc.1"
         "03mqvpkxgciml4mlgg43vzzwz7sr8975cg277fqphfaph38jq6qc"
         "node_modules/@deepseek-ai/dsh-agent-instructions")
   (list "@deepseek-ai/dsh-agent-loop" "0.1.7-rc.1"
         "1anvl90a5jirjvx8gq4hifn00x411hbj4fwa7srgkb312c424ijc"
         "node_modules/@deepseek-ai/dsh-agent-loop")
   (list "@deepseek-ai/dsh-agent-preset" "0.1.7-rc.1"
         "0bmczm3cxwnrb3wmhicy8xrd1qgqgxjcac0sxsslpcrbdyrs8v3s"
         "node_modules/@deepseek-ai/dsh-agent-preset")
   (list "@deepseek-ai/dsh-agent-preset-registry" "0.1.7-rc.1"
         "1myag5gwzcqbcia65h9xfn045j4w5rm7gp6ccw1nykzgks7iyxvj"
         "node_modules/@deepseek-ai/dsh-agent-preset-registry")
   (list "@deepseek-ai/dsh-agent-tool-presentation" "0.1.7-rc.1"
         "11v0h52h1l1779hl5z63asfz6b6xgd84xk98mc6y4bajiw0xz9yq"
         "node_modules/@deepseek-ai/dsh-agent-tool-presentation")
   (list "@deepseek-ai/dsh-anonymous-user-id" "0.1.7-rc.1"
         "03qhm3261hqm72l5940vwibf6gdgi47pxdr23ijw31dj8byi77as"
         "node_modules/@deepseek-ai/dsh-anonymous-user-id")
   (list "@deepseek-ai/dsh-api-account-controller" "0.1.7-rc.1"
         "1qj72xn85hkf4dsnz4qqm4rscdw6jhpq53klpmh8am38kk3yk173"
         "node_modules/@deepseek-ai/dsh-api-account-controller")
   (list "@deepseek-ai/dsh-api-gateway" "0.1.7-rc.1"
         "1rxni1zbs6pvzyrq41xzi3km5bb7w71ivd2p2yncw40pmbl9yyg0"
         "node_modules/@deepseek-ai/dsh-api-gateway")
   (list "@deepseek-ai/dsh-api-job-controller" "0.1.7-rc.1"
         "1m1hqmw88xv2yxjc3qpl7d7qzzr2w5dql78hzrs57jj9lgv47y88"
         "node_modules/@deepseek-ai/dsh-api-job-controller")
   (list "@deepseek-ai/dsh-api-remotes" "0.1.7-rc.1"
         "16b5p22wyvih665rl6rm6fg50pzrw6lrr24n6byhik7dxfqd26ra"
         "node_modules/@deepseek-ai/dsh-api-remotes")
   (list "@deepseek-ai/dsh-api-session-controller" "0.1.7-rc.1"
         "065n3hqyfi8xf77sh534zgr2z7y5qh7m7f9lz27sj1vx8gngh2mw"
         "node_modules/@deepseek-ai/dsh-api-session-controller")
   (list "@deepseek-ai/dsh-api-settings-controller" "0.1.7-rc.1"
         "0c9ihz9b3misw0ym953vw7fyl3cnhqxqh7232njv3a0iksdk3y0x"
         "node_modules/@deepseek-ai/dsh-api-settings-controller")
   (list "@deepseek-ai/dsh-api-terminal-controller" "0.1.7-rc.1"
         "0fw1s8p4vprzfc7yzll0bncsgq7c4rg0jjafg85hs08dqdfa63dh"
         "node_modules/@deepseek-ai/dsh-api-terminal-controller")
   (list "@deepseek-ai/dsh-api-workspace-controller" "0.1.7-rc.1"
         "1glkk1blmm760gnx8xxa3f9jczd23byh76ccl835rr2pn692jipr"
         "node_modules/@deepseek-ai/dsh-api-workspace-controller")
   (list "@deepseek-ai/dsh-api-workspace-files" "0.1.7-rc.1"
         "03di47h7caisx8qsl4hdqnx59k8s4jgbjiwl27qbh4b261n1skq8"
         "node_modules/@deepseek-ai/dsh-api-workspace-files")
   (list "@deepseek-ai/dsh-app-boot" "0.1.7-rc.1"
         "1cciwlsrwxmyiqdazkpqbdjq8wx621lnrbmaqrhswhj5fgycizn5"
         "node_modules/@deepseek-ai/dsh-app-boot")
   (list "@deepseek-ai/dsh-atomic-write" "0.1.7-rc.1"
         "19b9nhsmdrvd4rfs6nxsvcxcr2aizn1711gay0ixsp9xwldlkqnz"
         "node_modules/@deepseek-ai/dsh-atomic-write")
   (list "@deepseek-ai/dsh-attachment" "0.1.7-rc.1"
         "1a5vl1555ca43vkhvp4j2i4lcwa1pwnlz7kwhwdj5mmgn5p165ph"
         "node_modules/@deepseek-ai/dsh-attachment")
   (list "@deepseek-ai/dsh-attachment-local" "0.1.7-rc.1"
         "1xk9zfq4p3q7gz3bx7jmnf6b293qcgy25wsnjclbwff8px4iasxf"
         "node_modules/@deepseek-ai/dsh-attachment-local")
   (list "@deepseek-ai/dsh-authorization" "0.1.7-rc.1"
         "04ib9c43v4d91xk80jr3acp871za4qsz06y9dpvbk9g49hz16778"
         "node_modules/@deepseek-ai/dsh-authorization")
   (list "@deepseek-ai/dsh-base" "0.1.7-rc.1"
         "08sgbqhyjxsgxwhsp1i3x91svzgncghhh1slyhw7klxm8sv50nhy"
         "node_modules/@deepseek-ai/dsh-base")
   (list "@deepseek-ai/dsh-bash-local" "0.1.7-rc.1"
         "0m8bhwgyvs6fsrp4rg98iflmw6nq73pg8bkmy2xk7m0cjdmmfwqy"
         "node_modules/@deepseek-ai/dsh-bash-local")
   (list "@deepseek-ai/dsh-bash-sandbox" "0.1.7-rc.1"
         "12sn6r8zlr8ys7z3sfs3nwj0xv62psk8wh2qp6wi6pmzxmmrfmc1"
         "node_modules/@deepseek-ai/dsh-bash-sandbox")
   (list "@deepseek-ai/dsh-brand" "0.1.7-rc.1"
         "12h5i0ifdb9jkwbg2bzihxav81nv7mydn0pq1vkp9a58v4w065qf"
         "node_modules/@deepseek-ai/dsh-brand")
   (list "@deepseek-ai/dsh-chunked-list" "0.1.7-rc.1"
         "09sfwhzmqgsgdm0plirlic7g5mnn8iwjdq0nhkjppmskcnpbfbfx"
         "node_modules/@deepseek-ai/dsh-chunked-list")
   (list "@deepseek-ai/dsh-client-connection" "0.1.7-rc.1"
         "0zlm1ylspqk131l6pjjvp14vlh09zj9j17295g7172wfdj6r5kfj"
         "node_modules/@deepseek-ai/dsh-client-connection")
   (list "@deepseek-ai/dsh-client-file-upload" "0.1.7-rc.1"
         "01ikgk5g4qp8dbkqpqafybx9w2hnxjpdvym3l9lb8ahm7n1mgs0z"
         "node_modules/@deepseek-ai/dsh-client-file-upload")
   (list "@deepseek-ai/dsh-client-hmr" "0.1.7-rc.1"
         "1i0w5xcg156nkh2jw4s18i6n8vlcbalha8hidd3kcj3s0pj1vka0"
         "node_modules/@deepseek-ai/dsh-client-hmr")
   (list "@deepseek-ai/dsh-client-locale" "0.1.7-rc.1"
         "0wxhxfd04di4wigrw0df9p4nlcsgb9nwir7mp2ck1cw6g51kmqg2"
         "node_modules/@deepseek-ai/dsh-client-locale")
   (list "@deepseek-ai/dsh-client-modules" "0.1.7-rc.1"
         "1ihb9vlbc67mfvpwr7gac2531ldjdgd9i4v02dq959z7r9dvr5am"
         "node_modules/@deepseek-ai/dsh-client-modules")
   (list "@deepseek-ai/dsh-client-resources" "0.1.7-rc.1"
         "0kgfc8d691l2f9qbqn6jm0rbr0v1r3kg6zlcbhji9dq1b8hqg567"
         "node_modules/@deepseek-ai/dsh-client-resources")
   (list "@deepseek-ai/dsh-client-store" "0.1.7-rc.1"
         "0rvhz43v7lsr4ral5v7dmzadixf1kisssgvjm4y8jr1mx39y4k01"
         "node_modules/@deepseek-ai/dsh-client-store")
   (list "@deepseek-ai/dsh-client-ui-agent-preset" "0.1.7-rc.1"
         "1r56iq86ay3rf14pfv8xny0k0nwdl2v4lk2npxh52ixm4yakky76"
         "node_modules/@deepseek-ai/dsh-client-ui-agent-preset")
   (list "@deepseek-ai/dsh-client-ui-approval" "0.1.7-rc.1"
         "0j4700alabyi2rkd3c8vc4fb1w8sq38nxf50lmkl53wdxkn5llxs"
         "node_modules/@deepseek-ai/dsh-client-ui-approval")
   (list "@deepseek-ai/dsh-client-ui-attachment" "0.1.7-rc.1"
         "0j4bzs06b6ibf5xh9x72swx57fhj2xrsb54kwd7c9r69sy13dm84"
         "node_modules/@deepseek-ai/dsh-client-ui-attachment")
   (list "@deepseek-ai/dsh-client-ui-brand-official" "0.1.7-rc.1"
         "0ikf8il2mbkmpi1sp8rhcsfy70whhg469r0ym6b9gdkfzii1xynx"
         "node_modules/@deepseek-ai/dsh-client-ui-brand-official")
   (list "@deepseek-ai/dsh-client-ui-chat" "0.1.7-rc.1"
         "02a2r4f270xvpsmcg50kgysgh6ddib5vg20sfyrgskmvq3c00n8h"
         "node_modules/@deepseek-ai/dsh-client-ui-chat")
   (list "@deepseek-ai/dsh-client-ui-commands" "0.1.7-rc.1"
         "0bi6k4rnlz2nxmc0wbqf73w0y155spvjc5jg5pp1l7vvwlqzff5z"
         "node_modules/@deepseek-ai/dsh-client-ui-commands")
   (list "@deepseek-ai/dsh-client-ui-conversation" "0.1.7-rc.1"
         "1r41v8qd82s44ab7i7yc66gp3y40yv2scmszb5ch3jnqbxgq153x"
         "node_modules/@deepseek-ai/dsh-client-ui-conversation")
   (list "@deepseek-ai/dsh-client-ui-cordis" "0.1.7-rc.1"
         "1x8cp3j7q3zkh9765jnc91iyv767w4hg5chr3w6yn9bjqss524kh"
         "node_modules/@deepseek-ai/dsh-client-ui-cordis")
   (list "@deepseek-ai/dsh-client-ui-deliverables" "0.1.7-rc.1"
         "1bsaipgiskp8drb5gijlrff51q7d37mg9cpg7qhxbl75ri7qscl7"
         "node_modules/@deepseek-ai/dsh-client-ui-deliverables")
   (list "@deepseek-ai/dsh-client-ui-directory-picker-browse" "0.1.7-rc.1"
         "0q2pz6wwfbpc2knja69271gplhcrwvsc8ks59ww23lrrgvh4larm"
         "node_modules/@deepseek-ai/dsh-client-ui-directory-picker-browse")
   (list "@deepseek-ai/dsh-client-ui-directory-picker-native" "0.1.7-rc.1"
         "15rdykhggs50vini4m4jkqdqfdpk560yjpdrh03kf7fd2jvzhyzg"
         "node_modules/@deepseek-ai/dsh-client-ui-directory-picker-native")
   (list "@deepseek-ai/dsh-client-ui-goal" "0.1.7-rc.1"
         "1r6c4vymgz0x0lrm2cknfbl81y2z8x17il0pk2yacmk95rhrjlvb"
         "node_modules/@deepseek-ai/dsh-client-ui-goal")
   (list "@deepseek-ai/dsh-client-ui-input-trigger" "0.1.7-rc.1"
         "0iib3kbbkq6h9cmzp8dy30wlmg087669b7fnc7wygy73yqfvi6lq"
         "node_modules/@deepseek-ai/dsh-client-ui-input-trigger")
   (list "@deepseek-ai/dsh-client-ui-jobs" "0.1.7-rc.1"
         "0wfj8zirzlrx9i3rqdi2lyvl9fyg4vif3xjm39nrdgx4pfkdabwb"
         "node_modules/@deepseek-ai/dsh-client-ui-jobs")
   (list "@deepseek-ai/dsh-client-ui-layout" "0.1.7-rc.1"
         "0s5klaihf4pia226gjhv4ywr2khp8mw4862gwj7fxwyrhxp2fcr2"
         "node_modules/@deepseek-ai/dsh-client-ui-layout")
   (list "@deepseek-ai/dsh-client-ui-message-feedback" "0.1.7-rc.1"
         "16z470zfnmvxmdsibpxr2z7djpdvi6a1b7b1w7swncj0yfh92g2a"
         "node_modules/@deepseek-ai/dsh-client-ui-message-feedback")
   (list "@deepseek-ai/dsh-client-ui-model-selection" "0.1.7-rc.1"
         "0352q1cq9y3fb112vqqi2h7h9iw1yyim1fjlps7r46s5pg8vdxjf"
         "node_modules/@deepseek-ai/dsh-client-ui-model-selection")
   (list "@deepseek-ai/dsh-client-ui-open-in-app" "0.1.7-rc.1"
         "1niskqilsqn36d8ddi0l0pyz14zkf1cdlypvmrc6v7npl3q63jpn"
         "node_modules/@deepseek-ai/dsh-client-ui-open-in-app")
   (list "@deepseek-ai/dsh-client-ui-permission-presets" "0.1.7-rc.1"
         "1acddb5cdx9n3dgd25kajkl0fagb1868nlycx099jk5nh9kk81v1"
         "node_modules/@deepseek-ai/dsh-client-ui-permission-presets")
   (list "@deepseek-ai/dsh-client-ui-plan" "0.1.7-rc.1"
         "10pkmanzl7y8djdismpq0n0qgkhn6xp00awc1zn5m8s4wr23lk0v"
         "node_modules/@deepseek-ai/dsh-client-ui-plan")
   (list "@deepseek-ai/dsh-client-ui-plugin-manager" "0.1.7-rc.1"
         "0xk5ll3qwsq52pxc3l53v883im1jcc9nn8rraybry91wm4l941d8"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-manager")
   (list "@deepseek-ai/dsh-client-ui-primitives" "0.1.7-rc.1"
         "1afj72d4rz73yzypypflc6jrb6wy653k5y1imflzb27cgq8qw3g3"
         "node_modules/@deepseek-ai/dsh-client-ui-primitives")
   (list "@deepseek-ai/dsh-client-ui-reference" "0.1.7-rc.1"
         "0ckv3pxxc4z8nkycnawx4cay2x6zmwl5i17cp0q1fllmar3wg9b2"
         "node_modules/@deepseek-ai/dsh-client-ui-reference")
   (list "@deepseek-ai/dsh-client-ui-renderer" "0.1.7-rc.1"
         "15mpl16sa253i9xcc6bgk6d7wrpc3vz6185bxdbvz253p8yswr60"
         "node_modules/@deepseek-ai/dsh-client-ui-renderer")
   (list "@deepseek-ai/dsh-client-ui-schedule" "0.1.7-rc.1"
         "1aac36am01p4m2pz90lz19j88qpjnd00hxy7qxa99rpm0yij5i5r"
         "node_modules/@deepseek-ai/dsh-client-ui-schedule")
   (list "@deepseek-ai/dsh-client-ui-session" "0.1.7-rc.1"
         "1h9k9hahwsphmlhzp2mzrkpzj29ia2ny6yr667ia5070y79pamcc"
         "node_modules/@deepseek-ai/dsh-client-ui-session")
   (list "@deepseek-ai/dsh-client-ui-settings" "0.1.7-rc.1"
         "16b6cxzdzs2f2h0r8a0yrznbk6igkzzv7pqlwkp0qg66yqs0n3vq"
         "node_modules/@deepseek-ai/dsh-client-ui-settings")
   (list "@deepseek-ai/dsh-client-ui-settings-account" "0.1.7-rc.1"
         "1cijqmh6qg0175a8v87v29c20rgxm49956g3cs250yggyyplf9nj"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-account")
   (list "@deepseek-ai/dsh-client-ui-settings-agent-loop" "0.1.7-rc.1"
         "1iymx9r2nw8nzzflbmvzcf2h9sni6cbwgxm1awnbd9l0xvgn9jp9"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-agent-loop")
   (list "@deepseek-ai/dsh-client-ui-settings-general" "0.1.7-rc.1"
         "0gswhpz8ng90hp6gqsql30lr3bzq5vlrkc5n7i9533q66qq6fs0f"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-general")
   (list "@deepseek-ai/dsh-client-ui-settings-models" "0.1.7-rc.1"
         "1v859d36l641y9lbw8nfp74libm33mbkrvyhpqnr59m4ihapqgdc"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-models")
   (list "@deepseek-ai/dsh-client-ui-settings-plugin-inventory" "0.1.7-rc.1"
         "0ck2nkqwf803hcmi0ms23x0vqhwxvzx4c0yi3qwkqmzqxsmpvp4j"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-plugin-inventory")
   (list "@deepseek-ai/dsh-client-ui-settings-plugins" "0.1.7-rc.1"
         "07vljmfighzmgxnhz73fypz03slgrhyrb1xm2f8g6s3rrb9zq5lx"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-plugins")
   (list "@deepseek-ai/dsh-client-ui-settings-shell" "0.1.7-rc.1"
         "04mbvamd465y24qwp8ar2kh5hhl9g6lnzn60smw6jamj69b8yqm4"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-shell")
   (list "@deepseek-ai/dsh-client-ui-settings-subagent" "0.1.7-rc.1"
         "02v6kc0bndw72pzqplkljxshs1544vq7q7xvdsxpzkc3swshbf2p"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-subagent")
   (list "@deepseek-ai/dsh-client-ui-settings-web-search" "0.1.7-rc.1"
         "040s7s0pqy82gfdxad92rx36zinlf5f7lqw3c02jrkhqcs60bkfn"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-web-search")
   (list "@deepseek-ai/dsh-client-ui-sidebar" "0.1.7-rc.1"
         "1r1b2g1nx2c60gc73vhimsjddlw19979b9d0rnblpac7xxz9hnac"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar")
   (list "@deepseek-ai/dsh-client-ui-sidebar-browser" "0.1.7-rc.1"
         "1db2xgakq8sa7f16bbh7z8wx5ifj4svv9i3zwhrfil5z5m1naqgz"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-browser")
   (list "@deepseek-ai/dsh-client-ui-sidebar-documentpreview" "0.1.7-rc.1"
         "0a19pfmimcksg2ncd9nlm7q301lizxpnyblqg52zx3n5d7qyyl6y"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-documentpreview")
   (list "@deepseek-ai/dsh-client-ui-sidebar-files" "0.1.7-rc.1"
         "1c3vf8pc6am1bsgj09vsfjrmh2cc5bdpdaa5k21djx35kyd3zjq6"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-files")
   (list "@deepseek-ai/dsh-client-ui-sidebar-right" "0.1.7-rc.1"
         "0arw172n1yfiibhhy35f0aqxnp58ybf282ak7303ajdzjp50cfgd"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-right")
   (list "@deepseek-ai/dsh-client-ui-sidebar-terminal" "0.1.7-rc.1"
         "0n7j8gzbv7phlg1239xi1gmbs90aj9xw2865xpmqc96wlyks0kf3"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-terminal")
   (list "@deepseek-ai/dsh-client-ui-skill" "0.1.7-rc.1"
         "1g6n5arg8h065jz7vxhgfd1pv1cm1v3s2h6m180cq5qb9w2yivxy"
         "node_modules/@deepseek-ai/dsh-client-ui-skill")
   (list "@deepseek-ai/dsh-client-ui-slots" "0.1.7-rc.1"
         "1nvb7z319bpsr9q9g9av2mj1x1b7npsqaix9dgcpldq21h8fl68w"
         "node_modules/@deepseek-ai/dsh-client-ui-slots")
   (list "@deepseek-ai/dsh-client-ui-subagent" "0.1.7-rc.1"
         "0bm3ns22jbh0c62998azs801lc2xqvwia416q6w5s2wihxxgmahx"
         "node_modules/@deepseek-ai/dsh-client-ui-subagent")
   (list "@deepseek-ai/dsh-client-ui-theme" "0.1.7-rc.1"
         "08wkl22zi9yczvpf51jv66z2ig5qk0n78chzcjzsd90h405wyycr"
         "node_modules/@deepseek-ai/dsh-client-ui-theme")
   (list "@deepseek-ai/dsh-client-ui-tool" "0.1.7-rc.1"
         "0k72zmdpap0xsd6068jrkldn58mhm509wlwi6f55118ahr4915qy"
         "node_modules/@deepseek-ai/dsh-client-ui-tool")
   (list "@deepseek-ai/dsh-client-ui-trajectory" "0.1.7-rc.1"
         "0npv5p9r9c95fj5h1ylx22vxzxyfk867f0vj3mprpxwbidzgax6y"
         "node_modules/@deepseek-ai/dsh-client-ui-trajectory")
   (list "@deepseek-ai/dsh-client-ui-user-questions" "0.1.7-rc.1"
         "0wrj569mis55vj5z96hsxw1jxxlf2qd9mp5pr022ws684n30j4pb"
         "node_modules/@deepseek-ai/dsh-client-ui-user-questions")
   (list "@deepseek-ai/dsh-client-ui-workflow-run" "0.1.7-rc.1"
         "171snn84ays90q3si08dfzbbr4m4rv84a8cpw0lkz9v0wx2j3ldd"
         "node_modules/@deepseek-ai/dsh-client-ui-workflow-run")
   (list "@deepseek-ai/dsh-client-ui-workspace" "0.1.7-rc.1"
         "1za04jbb3kmvlyisi9wcaxqy99djy785mq1dlr936275b50w475z"
         "node_modules/@deepseek-ai/dsh-client-ui-workspace")
   (list "@deepseek-ai/dsh-cmdline" "0.1.7-rc.1"
         "1gkh5mvywi3kgi3aazhfs9c5js5zccyjk8w4yvnb6pnvys4l2bgb"
         "node_modules/@deepseek-ai/dsh-cmdline")
   (list "@deepseek-ai/dsh-command-compact" "0.1.7-rc.1"
         "1wyvv8pv3my3lhnkwk5nffaz7gdr3j8jpc9iq795qpvv4c7sk13m"
         "node_modules/@deepseek-ai/dsh-command-compact")
   (list "@deepseek-ai/dsh-command-feedback" "0.1.7-rc.1"
         "0bqsq3qq9030in9d047pfng2cwc63z3rgdxgnxyij9zal0f87hwc"
         "node_modules/@deepseek-ai/dsh-command-feedback")
   (list "@deepseek-ai/dsh-command-goal" "0.1.7-rc.1"
         "1migb0vzrpa0fmp7789hsi8lj1ybg1a345pbd5ixyscli0d6xhf6"
         "node_modules/@deepseek-ai/dsh-command-goal")
   (list "@deepseek-ai/dsh-commands" "0.1.7-rc.1"
         "0gq5r4i2llxdx7in1zw8ncg2n1bbdyjhfzniywqayq99cbnd7501"
         "node_modules/@deepseek-ai/dsh-commands")
   (list "@deepseek-ai/dsh-compaction" "0.1.7-rc.1"
         "1bbgg56mpg53dy5g45iyvcqrx7f7iyi3x65gs6js0bmyg1vpkb4y"
         "node_modules/@deepseek-ai/dsh-compaction")
   (list "@deepseek-ai/dsh-compaction-basic" "0.1.7-rc.1"
         "1n5ckmvybnybk4mk2f67jly1cp04l2p5f249w3g6c39vscpiwx88"
         "node_modules/@deepseek-ai/dsh-compaction-basic")
   (list "@deepseek-ai/dsh-compaction-image-offload" "0.1.7-rc.1"
         "1vpxnc7a007a6nina5psism0pd4iv8jpasp3wvxdbyvc6i9a1l9g"
         "node_modules/@deepseek-ai/dsh-compaction-image-offload")
   (list "@deepseek-ai/dsh-compaction-tool-result-pruner" "0.1.7-rc.1"
         "19ym9wbwgsr3c5x6l7kb7jxhhvlhgwbmcsa4jg6a30xpl88q862j"
         "node_modules/@deepseek-ai/dsh-compaction-tool-result-pruner")
   (list "@deepseek-ai/dsh-config-editor" "0.1.7-rc.1"
         "01j591bb56qxfd43n2zdykzw1ks2csa9mgwyxw0cr22jgl50rnp5"
         "node_modules/@deepseek-ai/dsh-config-editor")
   (list "@deepseek-ai/dsh-cordis-client-runner" "0.1.7-rc.1"
         "028pjahk1pvcgvk0q0664dlhp0j21mlbx4d90nhmdz755zji9kvv"
         "node_modules/@deepseek-ai/dsh-cordis-client-runner")
   (list "@deepseek-ai/dsh-cordis-host-runner" "0.1.7-rc.1"
         "19zgnahpmkxgb3q1iqzyn2j92k0s27fwkgaf903fjsbfn6anix4f"
         "node_modules/@deepseek-ai/dsh-cordis-host-runner")
   (list "@deepseek-ai/dsh-credentials" "0.1.7-rc.1"
         "0svajs2hhh8s8jla6ynkn88d98cvbl57m0v51sx2711p1n7sffyp"
         "node_modules/@deepseek-ai/dsh-credentials")
   (list "@deepseek-ai/dsh-credentials-local" "0.1.7-rc.1"
         "0cnd39wifs8p8ylf9hw4z99dz985nv09chnpfca5kplzmi5nd3sq"
         "node_modules/@deepseek-ai/dsh-credentials-local")
   (list "@deepseek-ai/dsh-deepseek-account" "0.1.7-rc.1"
         "1js17v4i5wg1wk0ixr19a6l272qrvvdkha5xr7fw43j1y5r5y9wr"
         "node_modules/@deepseek-ai/dsh-deepseek-account")
   (list "@deepseek-ai/dsh-deepseek-account-platform" "0.1.7-rc.1"
         "04dn2k8ga7p8wxfh658wfgzlgr50yv7jlyka6iidsksnnvjmfhws"
         "node_modules/@deepseek-ai/dsh-deepseek-account-platform")
   (list "@deepseek-ai/dsh-deepseek-llm-api-extensions" "0.1.7-rc.1"
         "0rvca0n1s6v8dy1wqw75snvka0a5mn9djx43jsx54ca24jlik28p"
         "node_modules/@deepseek-ai/dsh-deepseek-llm-api-extensions")
   (list "@deepseek-ai/dsh-deque" "0.1.7-rc.1"
         "1phjsgwcv7li82cs8m97wf9jqzqygv1c1z1r5ayj8xxl4vgnb606"
         "node_modules/@deepseek-ai/dsh-deque")
   (list "@deepseek-ai/dsh-experimental-agent-team" "0.1.7-rc.1"
         "0wq6i0fzh4hnl1zkpiyp7v3cdwl2jwxgbalx9zrawiyi8wlbm989"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team")
   (list "@deepseek-ai/dsh-experimental-agent-team-profile" "0.1.7-rc.1"
         "1l1xbcw4x7ji7md35a50xlixzr05aqb5y3ni748sgk5q40361xk7"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team-profile")
   (list "@deepseek-ai/dsh-experimental-api-speech-to-text" "0.1.7-alpha.1"
         "0vfpszhrzb0ivvs8bf81n7nna7728yqrnys26r36a9jv9m2rzmj4"
         "node_modules/@deepseek-ai/dsh-experimental-api-speech-to-text")
   (list "@deepseek-ai/dsh-experimental-client-ui-agent-team" "0.1.7-rc.1"
         "164zffww2gfqawr1g0kih5n7d7s7fy4fmqb2pgb10y2xqnxdqrjz"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-agent-team")
   (list "@deepseek-ai/dsh-experimental-client-ui-voice-input" "0.1.7-alpha.1"
         "0rg8qr6ljinz66lkdfs2js4as73nf0shf0zph3qaap5jl9gx5wlx"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-voice-input")
   (list "@deepseek-ai/dsh-experimental-speech-to-text" "0.1.7-alpha.1"
         "02smj09cr9g2af43cvp6k498rrcf6ah42zbpg662cq226azw8kll"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text")
   (list "@deepseek-ai/dsh-experimental-speech-to-text-sensevoice" "0.1.7-alpha.1"
         "042rncmlg9kpvm3qi4jsbigwksiinvrvlbfax63ax42rkx64xwkm"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text-sensevoice")
   (list "@deepseek-ai/dsh-experimental-tool-agent-team" "0.1.7-rc.1"
         "0vdklpn7bhc4i286ixd72r6vp76p8b91hidmscpbd42vd1ps9mqj"
         "node_modules/@deepseek-ai/dsh-experimental-tool-agent-team")
   (list "@deepseek-ai/dsh-experimental-voice-input-bundle" "0.1.7-alpha.1"
         "16jshssgflc7kk7jrminwbw93r61kih0kc4m36nlwn0dfrqc8r8s"
         "node_modules/@deepseek-ai/dsh-experimental-voice-input-bundle")
   (list "@deepseek-ai/dsh-file-reference" "0.1.7-rc.1"
         "0wm63s3fp0v66p0xjm5xvp7mx1r5jg8h0hw8h0ar9saa9wyjqp0j"
         "node_modules/@deepseek-ai/dsh-file-reference")
   (list "@deepseek-ai/dsh-file-reference-local" "0.1.7-rc.1"
         "061svif66jnq84ia5lny6b4xlgqvg4f2xhqsgba86vlxzphgmhhr"
         "node_modules/@deepseek-ai/dsh-file-reference-local")
   (list "@deepseek-ai/dsh-fs" "0.1.7-rc.1"
         "1zjr1cd1czfh7x7ixa1qcd901gcgg8wvv8h0rlprp81scclcpzla"
         "node_modules/@deepseek-ai/dsh-fs")
   (list "@deepseek-ai/dsh-fs-local" "0.1.7-rc.1"
         "0jnvvbv83hmdsackd0xlhpx1h6kgr2xxvl4pfsgdlg5yx2f6afaj"
         "node_modules/@deepseek-ai/dsh-fs-local")
   (list "@deepseek-ai/dsh-fs-observation-policy" "0.1.7-rc.1"
         "1ggacj4fz770mikw444xwm0m0cl8fragly3f5793pc1xd8vs4v0y"
         "node_modules/@deepseek-ai/dsh-fs-observation-policy")
   (list "@deepseek-ai/dsh-fs-sandbox" "0.1.7-rc.1"
         "1dfixh8d2b5kdapcjvwb7sqbiqikhiv4633n96pgfgpg6gsny61r"
         "node_modules/@deepseek-ai/dsh-fs-sandbox")
   (list "@deepseek-ai/dsh-goal" "0.1.7-rc.1"
         "01z7jzzr92s4c9jqzlzmssbqbzc9y404xw0i43fl7mzlqqfjp5zc"
         "node_modules/@deepseek-ai/dsh-goal")
   (list "@deepseek-ai/dsh-goal-round-driver" "0.1.7-rc.1"
         "1446fgfyyx963yv9c9irlvwb85zvl4yj1r4ki9idmnkdxypvdnri"
         "node_modules/@deepseek-ai/dsh-goal-round-driver")
   (list "@deepseek-ai/dsh-headless" "0.1.7-rc.1"
         "19jz1yhrg3q1w0i19m2xsdlpayjn0h1aazwcc0b29rc7gcxdybin"
         "node_modules/@deepseek-ai/dsh-headless")
   (list "@deepseek-ai/dsh-hmr" "0.1.7-rc.1"
         "0ab29vdms61av93isq7776l14l4m358dnj3arz3pjhx8r0pznrxb"
         "node_modules/@deepseek-ai/dsh-hmr")
   (list "@deepseek-ai/dsh-home-paths" "0.1.7-rc.1"
         "1xs3h1qkbz5wiy3bf0vi3xnh9afa95pk4ym7w246b81djjnv7q06"
         "node_modules/@deepseek-ai/dsh-home-paths")
   (list "@deepseek-ai/dsh-hook-protocol" "0.1.7-rc.1"
         "0kdkkkjn9z06hjrs6y00hjmxy7vdp8hjiwlp0284cg1zj8cql1hy"
         "node_modules/@deepseek-ai/dsh-hook-protocol")
   (list "@deepseek-ai/dsh-hooks-claude-code" "0.1.7-rc.1"
         "1zllyydlxk87zlr3lgy1g1jsm8q19abnz728nmy9vq42wmgrsnp5"
         "node_modules/@deepseek-ai/dsh-hooks-claude-code")
   (list "@deepseek-ai/dsh-hooks-codex" "0.1.7-rc.1"
         "11ldni84d8w0yniq7m3fg8ngiicz5xj2avakyypkh5ib8r0lvv26"
         "node_modules/@deepseek-ai/dsh-hooks-codex")
   (list "@deepseek-ai/dsh-host-directory-picker" "0.1.7-rc.1"
         "1wwwmbslgbnk0kfl3gjfs80gqij6lb34z5rp3p9cpjsxzqs88a8h"
         "node_modules/@deepseek-ai/dsh-host-directory-picker")
   (list "@deepseek-ai/dsh-host-directory-picker-auto" "0.1.7-rc.1"
         "0v4flahklpbxzakaalccgndr0f4irm09wbf89i6d1j34z30gjh2r"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-auto")
   (list "@deepseek-ai/dsh-host-directory-picker-browse" "0.1.7-rc.1"
         "1sd7i06gd6iwvsal2sfs6hnagb6ycq9zcmqxpkdqcf3zb3ili2ld"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-browse")
   (list "@deepseek-ai/dsh-host-directory-picker-native" "0.1.7-rc.1"
         "1imw52s8v85vg2cmc85si9dvkm0vgxml3agxn3p8nidlnx06i9gk"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-native")
   (list "@deepseek-ai/dsh-host-frontend-static" "0.1.7-rc.1"
         "0imy9hd4jyf7918a80ihnh3q47q1pnwb1638qb9iggmw4vly8az3"
         "node_modules/@deepseek-ai/dsh-host-frontend-static")
   (list "@deepseek-ai/dsh-host-open-in-app" "0.1.7-rc.1"
         "0bmlaqnl0pjsamf6val2cy7c4klm8fzyb8n1w59a5ccs6fng55b1"
         "node_modules/@deepseek-ai/dsh-host-open-in-app")
   (list "@deepseek-ai/dsh-host-plugin-inventory" "0.1.7-rc.1"
         "16jk3v60pijg90mjflk68qzvj45cqvkgykf2yvqfz4c2p7s7jlik"
         "node_modules/@deepseek-ai/dsh-host-plugin-inventory")
   (list "@deepseek-ai/dsh-host-webserver" "0.1.7-rc.1"
         "19vm1ppg5rk93f5dgfib4q1apc374xh8vvg0zk1bk7v5vszy5fa4"
         "node_modules/@deepseek-ai/dsh-host-webserver")
   (list "@deepseek-ai/dsh-http-proxy" "0.1.7-rc.1"
         "0f9mzkjlqvxsg5avb27wqjpy3hqjnjd6bhd38a1358bf9nqh2pl3"
         "node_modules/@deepseek-ai/dsh-http-proxy")
   (list "@deepseek-ai/dsh-invariants" "0.1.7-rc.1"
         "1jmymq7yg27sybgq46j91k1ifa4p01wvdwvszdif7whldck9xqch"
         "node_modules/@deepseek-ai/dsh-invariants")
   (list "@deepseek-ai/dsh-jobs" "0.1.7-rc.1"
         "0x6r3z7643rnl8anjc7h2ga6jbw7ki5nl5vm0mybxvm597kgv1zn"
         "node_modules/@deepseek-ai/dsh-jobs")
   (list "@deepseek-ai/dsh-jobs-local" "0.1.7-rc.1"
         "036fc1m702yfgjf2fh1d1srswb2i8bvg9j1jf16ldnhfq7mw5lzs"
         "node_modules/@deepseek-ai/dsh-jobs-local")
   (list "@deepseek-ai/dsh-launch-environment" "0.1.7-rc.1"
         "0v5arvk2skwhicqjbcmzc1agqphys9qlzh6ydmsvx71i2hldv9jy"
         "node_modules/@deepseek-ai/dsh-launch-environment")
   (list "@deepseek-ai/dsh-lazy-require" "0.1.7-rc.1"
         "1shsj00is02pv6237giys694n9512xninj9z1yrxkmsgpkiqk96m"
         "node_modules/@deepseek-ai/dsh-lazy-require")
   (list "@deepseek-ai/dsh-llm" "0.1.7-rc.1"
         "1v3hd26n2kyk47ijysj2yql72awbcg5m6zfyarb1phsgpza0zv80"
         "node_modules/@deepseek-ai/dsh-llm")
   (list "@deepseek-ai/dsh-llm-deepseek" "0.1.7-rc.1"
         "0gn1szdcxmcv49qcyk6z0ifph8s9y91w3f4g9znssnjgcxc9cslz"
         "node_modules/@deepseek-ai/dsh-llm-deepseek")
   (list "@deepseek-ai/dsh-llm-pi-ai" "0.1.7-rc.1"
         "1xaf92lwnx1jhmq1bds1x7vd27zqvn27g9pl8g8wv2hc6i6yr6b2"
         "node_modules/@deepseek-ai/dsh-llm-pi-ai")
   (list "@deepseek-ai/dsh-llm-retry" "0.1.7-rc.1"
         "1cd3c6vhhzr6kpzz2jv7ahpyiv2d7bwmrl3yhpinmkycx4zp1b9v"
         "node_modules/@deepseek-ai/dsh-llm-retry")
   (list "@deepseek-ai/dsh-mcp-client" "0.1.7-rc.1"
         "0sq2xiwwsn0n4lx9a5lkc1iy0dggyacnb3hybjxm2m22w1g11wz7"
         "node_modules/@deepseek-ai/dsh-mcp-client")
   (list "@deepseek-ai/dsh-mcp-resources" "0.1.7-rc.1"
         "1lpyrwj75xgmihy9mdjiw6rvmpqr6f1dyk4yiswcwb5phssa0asm"
         "node_modules/@deepseek-ai/dsh-mcp-resources")
   (list "@deepseek-ai/dsh-message-feedback" "0.1.7-rc.1"
         "096766h8c4h4d1gidz7iypzskak6rc7k4jbhw2hgkbg86r0iyws4"
         "node_modules/@deepseek-ai/dsh-message-feedback")
   (list "@deepseek-ai/dsh-native-command" "0.1.7-rc.1"
         "1ydbx076ps2sqzjshrb1175511c94dr43ywjz7x26mgkd5jrr6qq"
         "node_modules/@deepseek-ai/dsh-native-command")
   (list "@deepseek-ai/dsh-office-to-pdf" "0.1.7-rc.1"
         "0skasmbjd62a897pfdixjnzdgh9lp1zdf0dkgcygvv5c3zgn5slk"
         "node_modules/@deepseek-ai/dsh-office-to-pdf")
   (list "@deepseek-ai/dsh-output-retention" "0.1.7-rc.1"
         "08libs10np15r93j4zp1bwrhayiziwyj5v48axrb3pj75kygl652"
         "node_modules/@deepseek-ai/dsh-output-retention")
   (list "@deepseek-ai/dsh-package-manifest" "0.1.7-rc.1"
         "0qn0sv6pqqkzg30cnk403lv27axcl17yvayzg1h6yr6zrkpbad9f"
         "node_modules/@deepseek-ai/dsh-package-manifest")
   (list "@deepseek-ai/dsh-permission-presets" "0.1.7-rc.1"
         "026ivjf0xcaxagihlg97gzrjzsxrbkb0mn2jrkx8igddj141fhn4"
         "node_modules/@deepseek-ai/dsh-permission-presets")
   (list "@deepseek-ai/dsh-persona" "0.1.7-rc.1"
         "1p9zg4gz5ca8sypcghgfsrjxsmwrxgc8a6diarjsv54b6ch6j1wq"
         "node_modules/@deepseek-ai/dsh-persona")
   (list "@deepseek-ai/dsh-plan-mode" "0.1.7-rc.1"
         "04sqq50wv7fsi9j8nknnq5lxq5m69a3d17v6gi73cfwz14ixcqnx"
         "node_modules/@deepseek-ai/dsh-plan-mode")
   (list "@deepseek-ai/dsh-plugin-manager" "0.1.7-rc.1"
         "19akbb1pyx8hy68y67p2av69pj028r6z1nr773czw9gc7yv64dj4"
         "node_modules/@deepseek-ai/dsh-plugin-manager")
   (list "@deepseek-ai/dsh-plugin-package-inventory-deepseek" "0.1.7-rc.1"
         "1bd8rx8c0aq8vmbzli73y91px0h1z6i2h61ha5dqkx90wlh3vk4g"
         "node_modules/@deepseek-ai/dsh-plugin-package-inventory-deepseek")
   (list "@deepseek-ai/dsh-ptc-runtime" "0.1.7-rc.1"
         "1f1yh5yq7kkbny6s9ca47d5207vria4c9lrwwr3sk0vrdw8bggw2"
         "node_modules/@deepseek-ai/dsh-ptc-runtime")
   (list "@deepseek-ai/dsh-ptc-runtime-node" "0.1.7-rc.1"
         "0la5537phflc4jhqn7wf8i4yc9mnqjrwfikhislz55ida2agva4g"
         "node_modules/@deepseek-ai/dsh-ptc-runtime-node")
   (list "@deepseek-ai/dsh-pwsh-local" "0.1.7-rc.1"
         "02rhkai66s7dazfhrw1hwqg9zb2mm011bc5fql6abzq59jf0a8q2"
         "node_modules/@deepseek-ai/dsh-pwsh-local")
   (list "@deepseek-ai/dsh-pwsh-sandbox" "0.1.7-rc.1"
         "1sfdcpixjmmli7flg8v6szas8lf0i0i0fv785ppj8h8kmlcmhbb1"
         "node_modules/@deepseek-ai/dsh-pwsh-sandbox")
   (list "@deepseek-ai/dsh-repeat-tool-reminder" "0.1.7-rc.1"
         "0d8kypixb790gmmz5bzwhy3ql1zipi9swhp78rd0w9jq87mcyjyc"
         "node_modules/@deepseek-ai/dsh-repeat-tool-reminder")
   (list "@deepseek-ai/dsh-sandbox" "0.1.7-rc.1"
         "1iq537ldgxic64y90y918dai2v05rmqkvfxsrh7h1ddix0n3rbaw"
         "node_modules/@deepseek-ai/dsh-sandbox")
   (list "@deepseek-ai/dsh-sandbox-local" "0.1.7-rc.1"
         "1nc7an249pas4ip0axnm1lyq62jmrmrs0x2w5w358zsn7iwbvpyn"
         "node_modules/@deepseek-ai/dsh-sandbox-local")
   (list "@deepseek-ai/dsh-sandbox-policy" "0.1.7-rc.1"
         "1a9hnhsylq2k0bicwk70mvicc56g5cw9d8gil2cr5qkyi556lsis"
         "node_modules/@deepseek-ai/dsh-sandbox-policy")
   (list "@deepseek-ai/dsh-sandbox-windows-acl" "0.1.7-rc.1"
         "1cw9mxcinkd1pvhbw4pvx9kl6nj4zk3zwgg67p8q4mkyz1fdmjzx"
         "node_modules/@deepseek-ai/dsh-sandbox-windows-acl")
   (list "@deepseek-ai/dsh-schedule" "0.1.7-rc.1"
         "1hpgdybbc01d6a97cnliqicgv09v492q13y3v555cqxijrf06bxg"
         "node_modules/@deepseek-ai/dsh-schedule")
   (list "@deepseek-ai/dsh-scope" "0.1.7-rc.1"
         "0r5vnzf3k0klxvlqjaz71r7lw9z5g3dbd68yr1vdcy21jc90a0qn"
         "node_modules/@deepseek-ai/dsh-scope")
   (list "@deepseek-ai/dsh-sdk-app" "0.1.7-rc.1"
         "14hd46pd29w2yb4q9chiym2hibzgc07fbqk3fph5b2s219vhccsc"
         "node_modules/@deepseek-ai/dsh-sdk-app")
   (list "@deepseek-ai/dsh-sdk-jsonrpc-server" "0.1.7-rc.1"
         "1pw6pl9dvas789hc1ci4b9bwq1r0k7g9bjkfrwlraw13s5m19lb9"
         "node_modules/@deepseek-ai/dsh-sdk-jsonrpc-server")
   (list "@deepseek-ai/dsh-sdk-minimal" "0.1.7-rc.1"
         "1q0mfd2plqz302m83j1skki0zyrxnizg98131cd29al2gqgvfab5"
         "node_modules/@deepseek-ai/dsh-sdk-minimal")
   (list "@deepseek-ai/dsh-sdk-protocol" "0.1.7-rc.1"
         "0kkqqg8nkwclwpq7kv6gzalpj02fszvjymmaclckxcgkv36z5y41"
         "node_modules/@deepseek-ai/dsh-sdk-protocol")
   (list "@deepseek-ai/dsh-session" "0.1.7-rc.1"
         "1gdjx4hrmlaq7d5vbgikn2kgdq4w1a6yczzq4s2gnwv1lnsza4v1"
         "node_modules/@deepseek-ai/dsh-session")
   (list "@deepseek-ai/dsh-session-checkpoint-policy" "0.1.7-rc.1"
         "0my4vzv358l98shz4z5hv3r47110j7yrnaqmj177d1jrlpi8xiqh"
         "node_modules/@deepseek-ai/dsh-session-checkpoint-policy")
   (list "@deepseek-ai/dsh-session-format" "0.1.7-rc.1"
         "0nzkwcc2h6rdn3l20yx5sg7f2zi3vp5wdr3wnyj3ny79sj6ci7cg"
         "node_modules/@deepseek-ai/dsh-session-format")
   (list "@deepseek-ai/dsh-session-format-catalog" "0.1.7-rc.1"
         "1c8vzk331zn6l6xml94zsb120f2cq814hvjni4m2250isa43z31p"
         "node_modules/@deepseek-ai/dsh-session-format-catalog")
   (list "@deepseek-ai/dsh-session-format-v0-to-v1" "0.1.7-rc.1"
         "1n669c54fnpcyd12qw4nj9nrj4y690zzjglxb3cr7ac5kmpr5zkv"
         "node_modules/@deepseek-ai/dsh-session-format-v0-to-v1")
   (list "@deepseek-ai/dsh-session-format-v1-to-v2" "0.1.7-rc.1"
         "0k59a90g2swchivncc7pd7chwhnnpza6rdiqxv1qwd92khgddam0"
         "node_modules/@deepseek-ai/dsh-session-format-v1-to-v2")
   (list "@deepseek-ai/dsh-session-format-v2-to-v3" "0.1.7-rc.1"
         "1jck0paj5yinwbn5ymf507d75mqjm21b4cq71wi283mwdrqffh6p"
         "node_modules/@deepseek-ai/dsh-session-format-v2-to-v3")
   (list "@deepseek-ai/dsh-session-format-v3-to-v4" "0.1.7-rc.1"
         "0n4bbm9s0a7dwzxq3kvp9q87gvrjxd7z20j5563mwhwq6hn43ww4"
         "node_modules/@deepseek-ai/dsh-session-format-v3-to-v4")
   (list "@deepseek-ai/dsh-session-log-deepseek" "0.1.7-rc.1"
         "0b21in8ymgv70wbkib4910qa18i5qw99h1xwkiw7pf77mw7r4a6n"
         "node_modules/@deepseek-ai/dsh-session-log-deepseek")
   (list "@deepseek-ai/dsh-session-log-export" "0.1.7-rc.1"
         "0gwhqam73q3cg0krbfh6gg5vivnwb19idis66zz5fdqc8smmq7z5"
         "node_modules/@deepseek-ai/dsh-session-log-export")
   (list "@deepseek-ai/dsh-session-persistence" "0.1.7-rc.1"
         "0mkgjx6yb7a1vhizgdcsi8ija5z6idvak02pxdk74bqk9y85alwm"
         "node_modules/@deepseek-ai/dsh-session-persistence")
   (list "@deepseek-ai/dsh-session-persistence-jsonl" "0.1.7-rc.1"
         "163z4mksbhx2f9ifzhd3qyc07nz1lgqkvk6rixaz46szdlg9hx98"
         "node_modules/@deepseek-ai/dsh-session-persistence-jsonl")
   (list "@deepseek-ai/dsh-session-projection" "0.1.7-rc.1"
         "0xinpy7zc06zxmw63cjsknskgxcgamm6zds3rzpgrcd9y07vwvnp"
         "node_modules/@deepseek-ai/dsh-session-projection")
   (list "@deepseek-ai/dsh-session-projection-cache" "0.1.7-rc.1"
         "030v2kxxrqm2nw2ihpy0aisqnm497sllmhx0yn4pyfjdss1vnk27"
         "node_modules/@deepseek-ai/dsh-session-projection-cache")
   (list "@deepseek-ai/dsh-session-query" "0.1.7-rc.1"
         "18bwc5vmz0mn7w76xk1zdj6fl2swja85yhr1ap7gi39fgfd8vf49"
         "node_modules/@deepseek-ai/dsh-session-query")
   (list "@deepseek-ai/dsh-session-query-sqlite" "0.1.7-rc.1"
         "1xzc6ycxzwlfnsgspjs8fqmzwk9i77w2z3mjfa1aq7hskphfskj2"
         "node_modules/@deepseek-ai/dsh-session-query-sqlite")
   (list "@deepseek-ai/dsh-session-reference" "0.1.7-rc.1"
         "00rcjg13lap4didmsp5scp7qi837m57wngjgs9a3acz3j6wvw8lv"
         "node_modules/@deepseek-ai/dsh-session-reference")
   (list "@deepseek-ai/dsh-session-stats" "0.1.7-rc.1"
         "0aw160kiq7l5jv8da0213vfzb360ag246khxlcsh1zmgwhcd9pvi"
         "node_modules/@deepseek-ai/dsh-session-stats")
   (list "@deepseek-ai/dsh-session-telemetry" "0.1.7-rc.1"
         "03j50br2yg94xd29pmkdhri24nrpg43qala49shqkbwgcxzpc91q"
         "node_modules/@deepseek-ai/dsh-session-telemetry")
   (list "@deepseek-ai/dsh-session-telemetry-otel" "0.1.7-rc.1"
         "0s4prrd95lxz0sjk4flii63hdl6xlkvdw26jx0irmyjn1pp40ihf"
         "node_modules/@deepseek-ai/dsh-session-telemetry-otel")
   (list "@deepseek-ai/dsh-session-title" "0.1.7-rc.1"
         "1vqji16s7kca060m3yv1qqsy5z2mdp3jr10r4s98alji75800ydg"
         "node_modules/@deepseek-ai/dsh-session-title")
   (list "@deepseek-ai/dsh-session-title-first-prompt-llm" "0.1.7-rc.1"
         "0mv42l0mdwvxy4x0waack3vgxl03p8wk7hpw995j8f6yqxa8q6bw"
         "node_modules/@deepseek-ai/dsh-session-title-first-prompt-llm")
   (list "@deepseek-ai/dsh-session-title-llm" "0.1.7-rc.1"
         "02lc5x8fk8199fpdy1j2xz9b5v55sa0hkjmx1padidv469gypmhd"
         "node_modules/@deepseek-ai/dsh-session-title-llm")
   (list "@deepseek-ai/dsh-session-turn-outline" "0.1.7-rc.1"
         "1xama3qq7xmc0mf99c3bjzps78c3v57qyf8a2qgdgn365i7pa04g"
         "node_modules/@deepseek-ai/dsh-session-turn-outline")
   (list "@deepseek-ai/dsh-settings" "0.1.7-rc.1"
         "19dlz5d9g2ny2s2ji5mmi8agfy8yz3nzrl1bz1lhm5bnjfrli2lc"
         "node_modules/@deepseek-ai/dsh-settings")
   (list "@deepseek-ai/dsh-shell" "0.1.7-rc.1"
         "0mh48naakg3q34fi81829fb5i17gx4b71dqh0kp7fgsqxw3005k9"
         "node_modules/@deepseek-ai/dsh-shell")
   (list "@deepseek-ai/dsh-shell-env" "0.1.7-rc.1"
         "02fjd6l81fg5a19fhb3yx4j745xzpi01k4v30qapyyw57vr023gg"
         "node_modules/@deepseek-ai/dsh-shell-env")
   (list "@deepseek-ai/dsh-skill" "0.1.7-rc.1"
         "15jlxm916aisikaj77mvrwbsybzv0md0k3irmx5sipia0l27ma3d"
         "node_modules/@deepseek-ai/dsh-skill")
   (list "@deepseek-ai/dsh-skill-badge" "0.1.7-rc.1"
         "1nvh0fmsk2jk5rkps9a3k0r9v0zm1l4b5ps4icmzs4w4b926xkkw"
         "node_modules/@deepseek-ai/dsh-skill-badge")
   (list "@deepseek-ai/dsh-skill-filesystem" "0.1.7-rc.1"
         "0zc7sgxlv8954w2kvxzq220zagvcx4pclpd0h40wgny5xz8mnlcr"
         "node_modules/@deepseek-ai/dsh-skill-filesystem")
   (list "chokidar" "5.0.0"
         "1qzmyw8jg7gr3zj0f593phii9p4yqiy58g5b6g3q5r3ysnkpxl25"
         "node_modules/@deepseek-ai/dsh-skill-filesystem/node_modules/chokidar")
   (list "readdirp" "5.1.1"
         "19fm2ijz7kd44ifq0v9cbfkrkgka5ma5cjjf316a2pkijy0nhnlk"
         "node_modules/@deepseek-ai/dsh-skill-filesystem/node_modules/readdirp")
   (list "@deepseek-ai/dsh-skill-office" "0.1.7-rc.1"
         "0v8ypqn62490nc2jvnpri8sq0zmq4d10zayrdvkhq2bp2q6b4lg9"
         "node_modules/@deepseek-ai/dsh-skill-office")
   (list "@deepseek-ai/dsh-spill" "0.1.7-rc.1"
         "00xgmigfjxn50ncxv7ll1fqi2m6dk38id8kl7j571r6vr7rfdpj4"
         "node_modules/@deepseek-ai/dsh-spill")
   (list "@deepseek-ai/dsh-spill-local" "0.1.7-rc.1"
         "1i02jq10q2cf8zmwmjc6c3nqgrrh3skc7ng1p3jbbygvgnaqvama"
         "node_modules/@deepseek-ai/dsh-spill-local")
   (list "@deepseek-ai/dsh-spill-policy" "0.1.7-rc.1"
         "11c922hdwf3ddw97kxg3vmvs3irczl98736clbxpmgq2cycl07ph"
         "node_modules/@deepseek-ai/dsh-spill-policy")
   (list "@deepseek-ai/dsh-storage" "0.1.7-rc.1"
         "09fnipsl9456xphfwpk3l6qlqcl4ikf6wc38xr6jbil67pid1mgx"
         "node_modules/@deepseek-ai/dsh-storage")
   (list "@deepseek-ai/dsh-storage-domain" "0.1.7-rc.1"
         "04ax4gam80yi6bgvw0m3fg0mbbv5hrzlmxipj3c710vgd2gnga2y"
         "node_modules/@deepseek-ai/dsh-storage-domain")
   (list "@deepseek-ai/dsh-storage-json" "0.1.7-rc.1"
         "0pk95wb6zlx4bj37gxhrxdqf4wcr9h5p00hicsy0w11j6nl2srfl"
         "node_modules/@deepseek-ai/dsh-storage-json")
   (list "@deepseek-ai/dsh-subagent" "0.1.7-rc.1"
         "10mskh3i32flsax0zvih750dq4kxbh0ks0zsgj5644vk520j8f0y"
         "node_modules/@deepseek-ai/dsh-subagent")
   (list "@deepseek-ai/dsh-subagent-fork-in-process" "0.1.7-rc.1"
         "07jhi1339jmaz8sa0rwzslrp5wlfjq78bjwxqi66pqwb6q7gs95z"
         "node_modules/@deepseek-ai/dsh-subagent-fork-in-process")
   (list "@deepseek-ai/dsh-subagent-in-process-driver" "0.1.7-rc.1"
         "13ddqsy7z30c3fj40a77yvm2imvgrjmi9zydflni740xjy509v37"
         "node_modules/@deepseek-ai/dsh-subagent-in-process-driver")
   (list "@deepseek-ai/dsh-subagent-spawn-in-process" "0.1.7-rc.1"
         "16shqhs8qp9sqr6j8ddqkvispi8f8nblw67bnj5pnrpv8xb9q86y"
         "node_modules/@deepseek-ai/dsh-subagent-spawn-in-process")
   (list "@deepseek-ai/dsh-subprocess" "0.1.7-rc.1"
         "0xw17r4sxgcp7amyaqzn0a7p8mqj3bi7hhs4hlpg6mw7xajmxvg3"
         "node_modules/@deepseek-ai/dsh-subprocess")
   (list "@deepseek-ai/dsh-subprocess-local" "0.1.7-rc.1"
         "0nn9wqwj91bl06c5wjny7fw8yqp4lfpvdj56bhc1xqzw4ivxlzwq"
         "node_modules/@deepseek-ai/dsh-subprocess-local")
   (list "@deepseek-ai/dsh-system-prompt" "0.1.7-rc.1"
         "02lxcyapxrfgbj0ki9dh1aj417q83p3lvyvwsn715ms048md55k2"
         "node_modules/@deepseek-ai/dsh-system-prompt")
   (list "@deepseek-ai/dsh-terminal" "0.1.7-rc.1"
         "107bszs5mha8v6i8nvj3y19bpkrpdsn7yw12cviym252c60rmiw8"
         "node_modules/@deepseek-ai/dsh-terminal")
   (list "@deepseek-ai/dsh-terminal-bash" "0.1.7-rc.1"
         "1d14pgwywvsrndbvfkgn635k2gc5xh8zgw7bvs8bzjjpv65fapbb"
         "node_modules/@deepseek-ai/dsh-terminal-bash")
   (list "@deepseek-ai/dsh-time-context" "0.1.7-rc.1"
         "184m393sphqwhlcnnaxzvvgmzwfchvb9chzd4cw94vnr3qyr4z08"
         "node_modules/@deepseek-ai/dsh-time-context")
   (list "@deepseek-ai/dsh-timeout" "0.1.7-rc.1"
         "1y9mpzrgqjlzymdw08f9inlcbimg4912psy7w03lk42i2qqplgn0"
         "node_modules/@deepseek-ai/dsh-timeout")
   (list "@deepseek-ai/dsh-tmux-context" "0.1.7-rc.1"
         "0xjsb7h8frgwdc7mq6kw4s1jg3l3b023y1wsg1g556rrlhlvcc62"
         "node_modules/@deepseek-ai/dsh-tmux-context")
   (list "@deepseek-ai/dsh-token-meter" "0.1.7-rc.1"
         "1z7rlcdjil1h0i27i93cpdqffr98jrvfybx841mavym2d36jg7l8"
         "node_modules/@deepseek-ai/dsh-token-meter")
   (list "@deepseek-ai/dsh-tool-ask-user" "0.1.7-rc.1"
         "1pjbjs0zjxrm0qb5javb285jdf8qjnslnnzvs7sz284qabkm5jnp"
         "node_modules/@deepseek-ai/dsh-tool-ask-user")
   (list "@deepseek-ai/dsh-tool-bash" "0.1.7-rc.1"
         "0fif6qx8xqw1d1z75b07zc70c7jda41a05mp9k7swfhxsqf5ki8b"
         "node_modules/@deepseek-ai/dsh-tool-bash")
   (list "@deepseek-ai/dsh-tool-bash-persistent" "0.1.7-rc.1"
         "050r811fh59k1xby7x774hnfsw98sw0jgk0qn5rlchhbndpwwdv7"
         "node_modules/@deepseek-ai/dsh-tool-bash-persistent")
   (list "@deepseek-ai/dsh-tool-call-timeout-policy" "0.1.7-rc.1"
         "0bclzj3z9c51x46yx30jb6npfajd9plxj6lgwmc1gxiq9y9fz8jz"
         "node_modules/@deepseek-ai/dsh-tool-call-timeout-policy")
   (list "@deepseek-ai/dsh-tool-cordis" "0.1.7-rc.1"
         "15h8q3c9b3wxiqrkj0aihn49gyf2c0053i2rnxjnyp1xkviqh6x1"
         "node_modules/@deepseek-ai/dsh-tool-cordis")
   (list "@deepseek-ai/dsh-tool-fs" "0.1.7-rc.1"
         "0ak8asn1x1s9g3m70qal4cgnbfg5yqdqyw788dqbp2ldvaprrvr5"
         "node_modules/@deepseek-ai/dsh-tool-fs")
   (list "@deepseek-ai/dsh-tool-fs-search" "0.1.7-rc.1"
         "1m0xr7zi173jc5ysc8fpifh5hb89hi24ahmhh09fx74djmvx3nyy"
         "node_modules/@deepseek-ai/dsh-tool-fs-search")
   (list "@deepseek-ai/dsh-tool-goal" "0.1.7-rc.1"
         "1dmfblfb84zyqcspxx03gfvxhr25hidlfi2ys0n39h7691ql8ggr"
         "node_modules/@deepseek-ai/dsh-tool-goal")
   (list "@deepseek-ai/dsh-tool-jobs" "0.1.7-rc.1"
         "1jw80w4cl3c8dplldww875pwiaqykygp2qzbdcz6gvjhfg4kpq2x"
         "node_modules/@deepseek-ai/dsh-tool-jobs")
   (list "@deepseek-ai/dsh-tool-present" "0.1.7-rc.1"
         "108qgniwzmlv6lzl6wqsfar7zd73mpjw5280bv1xzc439v3z5c9z"
         "node_modules/@deepseek-ai/dsh-tool-present")
   (list "@deepseek-ai/dsh-tool-pwsh" "0.1.7-rc.1"
         "1qnll1xcd9gdi7rr1drqqmn4f1i22zi1ndkc45f4y0cb95jm8ix4"
         "node_modules/@deepseek-ai/dsh-tool-pwsh")
   (list "@deepseek-ai/dsh-tool-pwsh-persistent" "0.1.7-rc.1"
         "07d1shikdw8wpw51mchym1fjlxk0kaclq68waapglbxkmifvmcvf"
         "node_modules/@deepseek-ai/dsh-tool-pwsh-persistent")
   (list "@deepseek-ai/dsh-tool-ralph" "0.1.7-rc.1"
         "1mrrs8i4dgafawhvv03jawnazh1xbvd5ixdxkpsl69brjw9kccdm"
         "node_modules/@deepseek-ai/dsh-tool-ralph")
   (list "@deepseek-ai/dsh-tool-skill" "0.1.7-rc.1"
         "1s005w4zqkydw3yxf017zy05l96bl77cqawiillqhlfc3dsb527f"
         "node_modules/@deepseek-ai/dsh-tool-skill")
   (list "@deepseek-ai/dsh-tool-str-replace-editor" "0.1.7-rc.1"
         "05c5a8zqqz76gm07l9gjj58jyax12x07b5s3aaz4r4lsacdpqbpp"
         "node_modules/@deepseek-ai/dsh-tool-str-replace-editor")
   (list "@deepseek-ai/dsh-tool-subagent" "0.1.7-rc.1"
         "18c1kadgffmhzcawi0bj9iyngrjqrw67g5mx8v4kbbqqzgvaxa6z"
         "node_modules/@deepseek-ai/dsh-tool-subagent")
   (list "@deepseek-ai/dsh-tool-subagent-control" "0.1.7-rc.1"
         "1jd6l67jswa1dv4gfglxln6lb8q2a35gh48wi29qf38q3lm8w3ym"
         "node_modules/@deepseek-ai/dsh-tool-subagent-control")
   (list "@deepseek-ai/dsh-tool-todo" "0.1.7-rc.1"
         "0v2zn9dhhka2sqglzmg8q3zhwk1vjz19ixy0qprfqigll6nlr44z"
         "node_modules/@deepseek-ai/dsh-tool-todo")
   (list "@deepseek-ai/dsh-tool-web" "0.1.7-rc.1"
         "0fycg8nw10y8fkqszpqra0dlvbld61a6pdz7dfi5w761qdsfy8jb"
         "node_modules/@deepseek-ai/dsh-tool-web")
   (list "@deepseek-ai/dsh-tool-workflow" "0.1.7-rc.1"
         "0cm97k0bkqcpwy4dmw1qg2ymdbha0y7rygxhslixbdrb5l4dhff2"
         "node_modules/@deepseek-ai/dsh-tool-workflow")
   (list "@deepseek-ai/dsh-tool-workspace-dependencies" "0.1.7-rc.1"
         "14qnd3ik14x8k49flzhspkd4dx1l1c3l308g7mj5zazm6xkbm1k6"
         "node_modules/@deepseek-ai/dsh-tool-workspace-dependencies")
   (list "@deepseek-ai/dsh-tools" "0.1.7-rc.1"
         "06z3jqwilvvf1n4ii74hmy112cjq0s5p5jpf7q0mbgmmmy0g0jcm"
         "node_modules/@deepseek-ai/dsh-tools")
   (list "@deepseek-ai/dsh-typert-loader" "0.1.7-rc.1"
         "0md6ilqx74vljis8vvj3j7idisj3sbs68lcjqmqqr1h0rrjicy5y"
         "node_modules/@deepseek-ai/dsh-typert-loader")
   (list "@deepseek-ai/dsh-typert-protocol" "0.1.7-rc.1"
         "03zzgxmbv419wx5if3grwdf1q0hwpxs0j5xlwvsqmw7pcma64408"
         "node_modules/@deepseek-ai/dsh-typert-protocol")
   (list "@deepseek-ai/dsh-typert-registry" "0.1.7-rc.1"
         "0dg1x9w1kviw95d9ibjc9gw22a8nixmzbsqp6sfbhjhl906wc006"
         "node_modules/@deepseek-ai/dsh-typert-registry")
   (list "@deepseek-ai/dsh-user-approval" "0.1.7-rc.1"
         "0jq7sf8fcp2w151rl69k9brid6zcf905235j0cgyhbf4mgzrkj2r"
         "node_modules/@deepseek-ai/dsh-user-approval")
   (list "@deepseek-ai/dsh-user-questions" "0.1.7-rc.1"
         "0153g30dbza6kqsmc8jnylz0r6v8dbwig4wrn7an4xdx9nm8vn8i"
         "node_modules/@deepseek-ai/dsh-user-questions")
   (list "@deepseek-ai/dsh-util-crypto" "0.1.7-rc.1"
         "0wq05xzmwmd674vba8adlaxfn9237angdnaajfgs1p6al5cc51dw"
         "node_modules/@deepseek-ai/dsh-util-crypto")
   (list "@deepseek-ai/dsh-util-time" "0.1.7-rc.1"
         "1f2w8cy01lwxjll4l3rb4p22wb3v46kqbj53rr611l13r24mh64z"
         "node_modules/@deepseek-ai/dsh-util-time")
   (list "@deepseek-ai/dsh-util-values" "0.1.7-rc.1"
         "0lhz3a1fzgbx98m13khk6f6l5dbc56x7i3xsdk669hvls29rhbzr"
         "node_modules/@deepseek-ai/dsh-util-values")
   (list "@deepseek-ai/dsh-util-workspace-path" "0.1.7-rc.1"
         "0v6vrna3v3d983r81zymsmqa0pp41wnk1zlj99h765kfmw01d824"
         "node_modules/@deepseek-ai/dsh-util-workspace-path")
   (list "@deepseek-ai/dsh-web" "0.1.7-rc.1"
         "1f11f50p4513b11h5lj9wn567l8n96n3jrwyjf72iyw377s5b95v"
         "node_modules/@deepseek-ai/dsh-web")
   (list "@deepseek-ai/dsh-web-app" "0.1.7-rc.1"
         "07krcfqmwlc3yz2ippz2b8kmwprb4cz32ky631rq47xsq5qwdifr"
         "node_modules/@deepseek-ai/dsh-web-app")
   (list "@deepseek-ai/dsh-web-fetch-http" "0.1.7-rc.1"
         "1llfrxvklxcl63sw8zf81j2g0ppi5sv6bjqc5hr1fljdkdchpivy"
         "node_modules/@deepseek-ai/dsh-web-fetch-http")
   (list "@deepseek-ai/dsh-web-frontend" "0.1.7-rc.1"
         "0j6cd0mn030vfzhlxrrb574kgciwvn747451336hjj1yq923yk43"
         "node_modules/@deepseek-ai/dsh-web-frontend")
   (list "@deepseek-ai/dsh-web-search-deepseek" "0.1.7-rc.1"
         "06xnrkrrm753vs6y1ahrspsbm5wvv6wr6kw8wnbb2g52mw2zm6a7"
         "node_modules/@deepseek-ai/dsh-web-search-deepseek")
   (list "@deepseek-ai/dsh-webhook" "0.1.7-rc.1"
         "05zrywcqas6asgdr7f6pc82k0pv447dnl4kri5vjfjgy0d6r4l8x"
         "node_modules/@deepseek-ai/dsh-webhook")
   (list "@deepseek-ai/dsh-webhook-github" "0.1.7-rc.1"
         "0rdyaiafxncxw0jmq2lp45ivl6c4yi2xyzn3qjl50dmsw8hd4g9w"
         "node_modules/@deepseek-ai/dsh-webhook-github")
   (list "@deepseek-ai/dsh-win32-process" "0.1.7-rc.1"
         "1602s0pa5fc8kxb0f5yph1hxpsxliyf5i7kkqcszc0vify7mpayw"
         "node_modules/@deepseek-ai/dsh-win32-process")
   (list "@deepseek-ai/dsh-workflow" "0.1.7-rc.1"
         "1s105lw70890f1z01n3cglbsbvqjzksvvprp4ipqpnbf0hk96mpv"
         "node_modules/@deepseek-ai/dsh-workflow")
   (list "@deepseek-ai/dsh-workflow-ptc" "0.1.7-rc.1"
         "18r5v19x5hpw95zrkf3913p1grnszsyw04rx9jdp1rkvqqwqpy33"
         "node_modules/@deepseek-ai/dsh-workflow-ptc")
   (list "@deepseek-ai/dsh-workspace" "0.1.7-rc.1"
         "0zpfmw8rfh4v5zzckdjrwqmxc18jpdpl5swy9p8zbxivins4wgfd"
         "node_modules/@deepseek-ai/dsh-workspace")
   (list "@deepseek-ai/dsh-workspace-changes" "0.1.7-rc.1"
         "0byawn0f3vs1i9rjlv8761wc81v48p8h50mamh9amh0zwv11pqvs"
         "node_modules/@deepseek-ai/dsh-workspace-changes")
   (list "@deepseek-ai/libreoffice-kit" "0.1.0"
         "0mr8wn3fnizql6b9xnsqnj3lp22rmbw2x1j44p0jsp11m8b9s5ik"
         "node_modules/@deepseek-ai/libreoffice-kit")
   (list "@deepseek-ai/libreoffice-kit-wasm" "0.1.0"
         "0mwimkkpsk1g9iz9rpxprym81ph7gszki6g7wqnjir16b3diqc9g"
         "node_modules/@deepseek-ai/libreoffice-kit-wasm")
   (list "fflate" "0.8.2"
         "1p21s6c9kk613jzyqjxzw49s6y5xqzzg5xr964z5x3pww9hm1zb1"
         "node_modules/@deepseek-ai/libreoffice-kit/node_modules/fflate")
   (list "@deepseek-ai/node-addon-system" "0.1.2"
         "0vn3j68y3zjq59mix5wk61qcf7747vmp4awgp1paz88yrfq0nyil"
         "node_modules/@deepseek-ai/node-addon-system")
   (list "@deepseek-ai/node-addon-system-linux-x64" "0.1.2"
         "086c26k464rrykv18s1bwypcrcfx6na7nv7rs7zw6cr1xqdpgyvp"
         "node_modules/@deepseek-ai/node-addon-system-linux-x64")
   (list "@deepseek-ai/schemastery" "3.18.4"
         "093d4v4qcavb1w6h6b5wcra0afmdn5x8yyczvbxws9zs8h5qwlfs"
         "node_modules/@deepseek-ai/schemastery")
   (list "@earendil-works/pi-ai" "0.85.1"
         "0lwjx7svfmf566p5r9nkzz027y12vrbpvcw8zvk5qi3rc6c12zdg"
         "node_modules/@earendil-works/pi-ai")
   (list "@earendil-works/pi-telemetry" "0.85.1"
         "040k43xmjdd4i65spad56rkca949nkd3l2yxm061zaspqqr3l412"
         "node_modules/@earendil-works/pi-telemetry")
   (list "@emnapi/runtime" "1.11.3"
         "0jaykdkjap399v92d0krwrc6y068vkxmr6jzsqv18mcbl09qksz6"
         "node_modules/@emnapi/runtime")
   (list "@eslint-community/regexpp" "4.12.2"
         "04hgmvpsk3810z2zni47wkrr8ncr21wsaykbx48zaixd0kk25jxm"
         "node_modules/@eslint-community/regexpp")
   (list "@google/genai" "1.52.0"
         "108rbj4inq67nxc61vlrwdsb3z033k16fsvp853qw46ynb1g8285"
         "node_modules/@google/genai")
   (list "@img/colour" "1.1.0"
         "1cc55mq08pxqx9vnd1151kh4n076g6jl52ddj5qn9f6l6fng6bbc"
         "node_modules/@img/colour")
   (list "@img/sharp-libvips-linux-x64" "1.3.3"
         "0shz582g4hd0qp265gr53vngb38q8zrf401shmis2h9fpc5gmdkl"
         "node_modules/@img/sharp-libvips-linux-x64")
   (list "@img/sharp-linux-x64" "0.35.4"
         "0fxzca8ykcfamaa50vx7kqic3cffgliyvm8n7xhfnhvnyl5xxqlz"
         "node_modules/@img/sharp-linux-x64")
   (list "@img/sharp-wasm32" "0.35.4"
         "0swbbnzpqw9bqfv4bglkh4q9g8qg3h267qzlxx341irhvjijisnr"
         "node_modules/@img/sharp-wasm32")
   (list "@joplin/turndown-plugin-gfm" "1.0.68"
         "08jp7qywkwk086ln57k2sf9z9n212r3xsi03vfi3wb07987b3p7x"
         "node_modules/@joplin/turndown-plugin-gfm")
   (list "@koromix/koffi-linux-x64" "3.3.1"
         "0bngi91f1wzkpqqpa0xl7nf6kax9rw51921lyywk2hriwx2y2psf"
         "node_modules/@koromix/koffi-linux-x64")
   (list "@mixmark-io/domino" "2.2.0"
         "1v5gcm0izyxkz2v7x9ypai0hbyxn2mlxs8108gv4jijl175bqadq"
         "node_modules/@mixmark-io/domino")
   (list "@modelcontextprotocol/client" "2.0.0"
         "0cm7pwkcqkdba9d2lccgc1vlwd15xa0j5as544k6x85l9410niyb"
         "node_modules/@modelcontextprotocol/client")
   (list "@modelcontextprotocol/core" "2.0.0"
         "1rh5mk4var6mvwsnmqifxzyysr7ld3x51fxyh51x7jhs4y6knhz9"
         "node_modules/@modelcontextprotocol/core")
   (list "@octokit/openapi-types" "29.0.1"
         "18kyc378gsvlip2rf8zvk6yg5hxzk2a32dhjjq5gnxbz9ggk3hsw"
         "node_modules/@octokit/openapi-types")
   (list "@octokit/openapi-webhooks-types" "12.1.0"
         "1cxcwaawnmv1gm2ivhyyhpra9hqd91axakamf3vvdhysiarca436"
         "node_modules/@octokit/openapi-webhooks-types")
   (list "@octokit/request-error" "7.1.2"
         "1iy8l48awgxyz0f1kc0gr2awsr9pbida67jpkqblv925ny3fnma1"
         "node_modules/@octokit/request-error")
   (list "@octokit/types" "18.0.0"
         "1lvbl00hkrf76nhn1p9wyf3xqldd4fmpv4x1gqxy4xasm96nsmyb"
         "node_modules/@octokit/types")
   (list "@octokit/webhooks" "14.2.0"
         "19mz8w592r9a33p4zg76f6qcans5glq9fihgwrwfbf58p14rsgnq"
         "node_modules/@octokit/webhooks")
   (list "@octokit/webhooks-methods" "6.0.0"
         "1s2b42aarbk5m2mr6b6xa7fnpxzayrjvcc5jjr1z0m8ww80vrfqq"
         "node_modules/@octokit/webhooks-methods")
   (list "@opentelemetry/api" "1.9.1"
         "1liwcywxmyr0f8byvpdxwgm9h8ax74d16jngfczd5b3m8ypazqhi"
         "node_modules/@opentelemetry/api")
   (list "@opentelemetry/api-logs" "0.220.0"
         "004x6zvbjirn1042681d4q6a0i8f4h025x31912nh1dp96li715c"
         "node_modules/@opentelemetry/api-logs")
   (list "@opentelemetry/core" "2.9.0"
         "1ay9ixh8vb73an4k8axivq9mf68pqk8r5dn75ijqzsiaaaqixc5i"
         "node_modules/@opentelemetry/core")
   (list "@opentelemetry/exporter-logs-otlp-http" "0.220.0"
         "0qgvlawjl5yw2h07jd4xqxb36d2x51082l660wwq2jphgxikx9s9"
         "node_modules/@opentelemetry/exporter-logs-otlp-http")
   (list "@opentelemetry/otlp-exporter-base" "0.220.0"
         "0r0gwh9fx9dcgmdhqd33xpisdymrcnf0aj0xkjnl3bkd9pyks0hk"
         "node_modules/@opentelemetry/otlp-exporter-base")
   (list "@opentelemetry/otlp-transformer" "0.220.0"
         "133pbh4579dfba368hwh4ixcvfk4sk420dff1d3d99y5iks7a0i5"
         "node_modules/@opentelemetry/otlp-transformer")
   (list "@opentelemetry/resources" "2.9.0"
         "1iqry50c5lrnwxk0zbrxn9nzmlf4k0m30k59ji014wbak1abf6iv"
         "node_modules/@opentelemetry/otlp-transformer/node_modules/@opentelemetry/resources")
   (list "@opentelemetry/resources" "2.11.0"
         "155jjr1hggb6x5rf2ijbj410frda5dnl71ls0x16q57clh17j05g"
         "node_modules/@opentelemetry/resources")
   (list "@opentelemetry/core" "2.11.0"
         "1hgkpq0d02ll9gks5sbsz4dyxjrz4x9k7kxsh725mpx1s9cfm3q0"
         "node_modules/@opentelemetry/resources/node_modules/@opentelemetry/core")
   (list "@opentelemetry/sdk-logs" "0.220.0"
         "1h2m8zlbhyqrx9nh1lng4jh07cmimklsv2dkw2z18xlx72sl08l6"
         "node_modules/@opentelemetry/sdk-logs")
   (list "@opentelemetry/resources" "2.9.0"
         "1iqry50c5lrnwxk0zbrxn9nzmlf4k0m30k59ji014wbak1abf6iv"
         "node_modules/@opentelemetry/sdk-logs/node_modules/@opentelemetry/resources")
   (list "@opentelemetry/sdk-metrics" "2.9.0"
         "16qyc98jj97dqp1j0pihx15z9gdxcd0rj8impd3lz1rw66sg9ybh"
         "node_modules/@opentelemetry/sdk-metrics")
   (list "@opentelemetry/resources" "2.9.0"
         "1iqry50c5lrnwxk0zbrxn9nzmlf4k0m30k59ji014wbak1abf6iv"
         "node_modules/@opentelemetry/sdk-metrics/node_modules/@opentelemetry/resources")
   (list "@opentelemetry/sdk-trace" "2.9.0"
         "1ww8896apq847vpbqg0zj5m6wnk4xl370l5hzjjhfl3ywxm8l4vb"
         "node_modules/@opentelemetry/sdk-trace")
   (list "@opentelemetry/resources" "2.9.0"
         "1iqry50c5lrnwxk0zbrxn9nzmlf4k0m30k59ji014wbak1abf6iv"
         "node_modules/@opentelemetry/sdk-trace/node_modules/@opentelemetry/resources")
   (list "@opentelemetry/semantic-conventions" "1.43.0"
         "0hjxv05xdfil08ckaqrm8qsh6bbsisikfkmnmip089fgz6fq6ra4"
         "node_modules/@opentelemetry/semantic-conventions")
   (list "@protobufjs/aspromise" "1.1.2"
         "06f1w67bgnw3zr7hbhv0yfbzz5mwbqsnc1jyri5zmwh9ha5qfh80"
         "node_modules/@protobufjs/aspromise")
   (list "@protobufjs/base64" "1.1.2"
         "0shs0f28zn7q7vprwlh6kzfrnmsg2h94rhyzii3i4ma4w7k6wznn"
         "node_modules/@protobufjs/base64")
   (list "@protobufjs/codegen" "2.0.5"
         "009sl5cds5r1ikixc091pib9mvysiscl3a2h4hxa5jqv4b8zxfi0"
         "node_modules/@protobufjs/codegen")
   (list "@protobufjs/eventemitter" "1.1.1"
         "0z3r58vyqxn745pq700l9w1l1gif6n785ldd3lf7fbh6ny6bjdjm"
         "node_modules/@protobufjs/eventemitter")
   (list "@protobufjs/fetch" "1.1.1"
         "0s3jicdxhgqjsrdi18qvpgvp6fzbiqsz4f82ig1y3g6ycaf1sj2l"
         "node_modules/@protobufjs/fetch")
   (list "@protobufjs/float" "1.0.2"
         "0bbivv9vgs7myqayb6akklb35470lvkahlidc1abg09jsl9ddcr0"
         "node_modules/@protobufjs/float")
   (list "@protobufjs/path" "1.1.2"
         "131jr8ykzasqh4hjg7r15mnyirxqafxs4da5fgakcg0p23llwdnc"
         "node_modules/@protobufjs/path")
   (list "@protobufjs/pool" "1.1.0"
         "00r7ffp1skf16ad4dzl2z2ffzhrwl3vyj6mzqb8wgll2fb9dn8gp"
         "node_modules/@protobufjs/pool")
   (list "@protobufjs/utf8" "1.1.2"
         "0zfa7ymbgkz6wwwi90yaxh1k3qrhchff4ns138sx8lxvwm4cwasi"
         "node_modules/@protobufjs/utf8")
   (list "@sec-ant/readable-stream" "0.4.1"
         "19jxad9wmfj36zyvpick8wdb6hrnzx9r4w893gqgvrrqd54xhm7w"
         "node_modules/@sec-ant/readable-stream")
   (list "@sindresorhus/merge-streams" "4.0.0"
         "1ggy58pn5rwvswrxgn0dkg1brm6md3nkzciqxdc8mplqgzmbpqsn"
         "node_modules/@sindresorhus/merge-streams")
   (list "@smithy/core" "3.35.0"
         "0vmfg198ihsmlasi9liw2jxnfd3qahpn8azmb5i7hlbzzj5j2qxw"
         "node_modules/@smithy/core")
   (list "@smithy/credential-provider-imds" "4.5.2"
         "04h6678cws5cqc4qig9pnkckrs33zanr0b4kdg8rx68c42c4gkh1"
         "node_modules/@smithy/credential-provider-imds")
   (list "@smithy/fetch-http-handler" "5.8.0"
         "114jsxlfj2m1108kf50grvb1shdmr5gp1f9qwycsmczipwq83l78"
         "node_modules/@smithy/fetch-http-handler")
   (list "@smithy/is-array-buffer" "2.2.0"
         "1ggpdqnyl7yrvmskk8n624awp9wj9br8kfqw4p0plvbmn03jdx1l"
         "node_modules/@smithy/is-array-buffer")
   (list "@smithy/node-http-handler" "4.7.3"
         "0qa4c9v6mkiha90cbryfpraf23s9147px9jl5nfavq3klbksz0rp"
         "node_modules/@smithy/node-http-handler")
   (list "@smithy/signature-v4" "5.7.3"
         "159wacy1lgphiphb7qw7vww0khhnxp1yzzsbms0w3hmi0qd2wzgh"
         "node_modules/@smithy/signature-v4")
   (list "@smithy/types" "4.19.0"
         "0a2gjprdwvfn635jb88zbzrdn6gsfnsxlhqlagkmj349cmfrx6hi"
         "node_modules/@smithy/types")
   (list "@smithy/util-buffer-from" "2.2.0"
         "1y5ifi0nicvi35k0vf8663limqa387vq0qyywi8qq64b6v9in515"
         "node_modules/@smithy/util-buffer-from")
   (list "@smithy/util-utf8" "2.3.0"
         "06h2zai4w7sv0d8cd5830bbza4zl9g0y2ch37n49r91j79ngadxi"
         "node_modules/@smithy/util-utf8")
   (list "@stablelib/base64" "1.0.1"
         "0sjrdadiyy1xyh6lp9pdlbxk8qdx6lgxn9bqdi1qfgqd5qfp2c01"
         "node_modules/@stablelib/base64")
   (list "@standard-schema/spec" "1.1.0"
         "1byfgh3b6ngdj4vba2jw48bk9wl6gjqc7y2hshcba2i8prl75jx7"
         "node_modules/@standard-schema/spec")
   (list "@swc/helpers" "0.5.23"
         "0idr0l22b6x2z1xyr3vcymcwyj1viaqm0mv5g5yiq7bw3f2zzq1x"
         "node_modules/@swc/helpers")
   (list "@types/node" "26.6.2"
         "1fr21lykrlx7j562a8g18h6f3z4mznwk8ddm5z1nxsrlncmyiyav"
         "node_modules/@types/node")
   (list "@types/retry" "0.12.0"
         "1j7qm574gpf1favz78qzn79ky5g6xbflkwwz3f8wps51mdsxp5vw"
         "node_modules/@types/retry")
   (list "@vscode/ripgrep" "1.18.0"
         "0sch4j3s7ky7yyb54x51lfbh66idnn1na8hvf8asl776ifbwh4kd"
         "node_modules/@vscode/ripgrep")
   (list "@vscode/ripgrep-linux-x64" "1.18.0"
         "02aadf6rzqyvacg1axlykpls47kwf3byr7m0x672b74zw8jnxh4c"
         "node_modules/@vscode/ripgrep-linux-x64")
   (list "@xterm/addon-serialize" "0.14.0"
         "1yxvqm0w28j0j2zxfkv6l6b70al154n0iz738s21gin97n9918pr"
         "node_modules/@xterm/addon-serialize")
   (list "@xterm/headless" "6.0.0"
         "12npqip9wr7xjlvb7xbxm90wvbga8rvw3j2ppmnfzrvl2q5rgr07"
         "node_modules/@xterm/headless")
   (list "agent-base" "7.1.4"
         "0zmmkk3xhnkwb6djnvri7zyxllsdz5aa5w83x7afi959d0badm3x"
         "node_modules/agent-base")
   (list "ajv" "8.20.0"
         "1cz7yr42yf4kb0znhwyxslqrxqcr2j5z0538zdgcrf5vjflb7w5j"
         "node_modules/ajv")
   (list "argparse" "2.0.1"
         "133jjyhcr25rf4vy7bca7x06dfmsyy819s1kbbyfc5c2zi3ki417"
         "node_modules/argparse")
   (list "base64-js" "1.5.1"
         "118a46skxnrgx5bdd68ny9xxjcvyb7b1clj2hf82d196nm2skdxi"
         "node_modules/base64-js")
   (list "bignumber.js" "9.3.1"
         "10ifa4ic5in9v44xgafclh1fxi5py4pyvamdp56gcrhf57m47agm"
         "node_modules/bignumber.js")
   (list "bowser" "2.14.1"
         "186a857fp2d7sh47byjd1qffcmfrsiwqk920jyphqnz2l5bs40cp"
         "node_modules/bowser")
   (list "brotli" "1.3.3"
         "096v5fggvvbm1849k7bcidi7s8i1zplik4cswkz9bpv3c87jcz1w"
         "node_modules/brotli")
   (list "buffer-equal-constant-time" "1.0.1"
         "0np7kzq65a7yvs7ch5vrhm6i9ayv7v3lqspdaiw3w422wdcm2icg"
         "node_modules/buffer-equal-constant-time")
   (list "bundle-name" "4.1.0"
         "0489x4n9f6z8v4qpycgakqp30j58xsgi69lrl96bw7698119vr1m"
         "node_modules/bundle-name")
   (list "bytes" "3.1.2"
         "10f5wgg4izi14lc425v7ljr1ayk28ycdjckfxpm4bnj0bankfpl3"
         "node_modules/bytes")
   (list "chokidar" "4.0.3"
         "12c3hr28bai0n50vxm73fc365i0l900jfwxylwrwvhhlsflrv8k1"
         "node_modules/chokidar")
   (list "clone" "2.1.2"
         "0gg90kb5jpm6bcmqfhvmfbx8dralysv5v9ph8b38a89ni9hkmxkx"
         "node_modules/clone")
   (list "commander" "15.0.0"
         "0vv9615p75afsyrzzj911zgzkfzzll85pbjgkjkqzs9ikc1iwb33"
         "node_modules/commander")
   (list "compressible" "2.0.18"
         "1mjr4010mlv5qim0n2by0gz5wiayscy7anaf712q19i4ha79syx5"
         "node_modules/compressible")
   (list "compression" "1.8.2"
         "19ip2l0r2rl4as0kp97q2bpj0hh2lgydph6g70w8sinn38q6rr0m"
         "node_modules/compression")
   (list "negotiator" "0.6.4"
         "045jfbblqx9zhv5rd88xsnwbmgkj9li1jflka560syxc6102viwg"
         "node_modules/compression/node_modules/negotiator")
   (list "content-type" "2.1.0"
         "0n6pa2s08s6fibxay10y4lk5sb2bw32l5a9s4vfrcypqvpjqx827"
         "node_modules/content-type")
   (list "cross-spawn" "7.0.6"
         "1siqxlydjwpihy7klgd15cah56vsmxrdm3q90gndyfj1vh63530q"
         "node_modules/cross-spawn")
   (list "data-uri-to-buffer" "4.0.1"
         "18a22rwk14m78xxhh8kkqkhp9651ghpy3xrgavxjj2sxfwdjnx55"
         "node_modules/data-uri-to-buffer")
   (list "debug" "2.6.9"
         "160wvc74r8aypds7pym3hq4qpa786hpk4vif58ggiwcqcv34ibil"
         "node_modules/debug")
   (list "default-browser" "5.5.1"
         "09myy4lzx9mr19yr5vl3c5kazvmahpnz3mnxf2l4ddv5a0c9f692"
         "node_modules/default-browser")
   (list "default-browser-id" "5.0.1"
         "0ablblhrzy81aixklbvdvq5fzdybh33q1086vkk0sq8bv7hgp51w"
         "node_modules/default-browser-id")
   (list "define-lazy-prop" "3.0.0"
         "1da99k4vnnn9bxpgjniai8248bcf4w9cwyn7p3wlzii9l9kzxsdv"
         "node_modules/define-lazy-prop")
   (list "destroy" "1.2.0"
         "1a6gf6hn9zc4g6v3dqdcsc3v1n22qbv1s5xmdakljjgmdkl2gzcd"
         "node_modules/destroy")
   (list "detect-libc" "2.1.2"
         "09wlldyqvhf2w7q4xcch4xh6pvldy7c2vbx83m48dzvcq07yq397"
         "node_modules/detect-libc")
   (list "dfa" "1.2.0"
         "1b935a6x35pvn4rw723ps9pxzsnv2xdnk3q2jwnsmdks60xfp0fp"
         "node_modules/dfa")
   (list "diff" "9.0.0"
         "13xmnf3hr0qm51rz1ak2x381xmgi2d0dspg2frsn152mr4ivz65q"
         "node_modules/diff")
   (list "ecdsa-sig-formatter" "1.0.11"
         "1zj8r1gp6vg3as5d0qs2qsycn0qwwkjaaj5n7cn7f514zx6vjz28"
         "node_modules/ecdsa-sig-formatter")
   (list "eventsource" "3.0.7"
         "14hw12k1s7h7bdh5x7sdlx4ic9p4dw6mb7ppbafb6nbf36xx8qkw"
         "node_modules/eventsource")
   (list "eventsource-parser" "3.1.1"
         "1v9niv3704fq0s4l1dpkp2zxncpb9i0p6gny8yn7dspcdk5a1824"
         "node_modules/eventsource-parser")
   (list "execa" "10.0.1"
         "1j2clqyn1688zv6dy15pbqhk9pqrsk6l2xh04wzix3ysnfqkrxdj"
         "node_modules/execa")
   (list "extend" "3.0.2"
         "1ckjrzapv4awrafybcvq3n5rcqm6ljswfdx97wibl355zaqd148x"
         "node_modules/extend")
   (list "fast-deep-equal" "3.1.3"
         "13vvwib6za4zh7054n3fg86y127ig3jb0djqz31qsqr71yca06dh"
         "node_modules/fast-deep-equal")
   (list "fast-sha256" "1.3.0"
         "1xl45kfg22wr0qnzybw05aahbwdlcl7lsz8f4nqwzjadb6i7x2ag"
         "node_modules/fast-sha256")
   (list "fast-uri" "3.1.8"
         "0v08mbps4fcmriw98l2ydg5w0yjww7iqzp0yab03fxva80xh7gl6"
         "node_modules/fast-uri")
   (list "fetch-blob" "3.2.0"
         "0lhcwk678vgadhilyfjmx5im77y55c52i37080icwzwplic0vgsa"
         "node_modules/fetch-blob")
   (list "fflate" "0.8.3"
         "14kxhl2w7wn58fvs0jlfd3m87sn2mrs24y1w2m1pnh028j1cvhiq"
         "node_modules/fflate")
   (list "figures" "6.1.0"
         "1z0xwlwg029qbdrfvawjhh4b995px8b848qxc7sxv498fxf1byrh"
         "node_modules/figures")
   (list "fontkit" "2.0.4"
         "023sg69ifnppqr48a1k567jrg0bjf02ybzsbmcbcwgzkb98sk1pn"
         "node_modules/fontkit")
   (list "formdata-polyfill" "4.0.10"
         "1sc7hip8lwxbz2jg2k0snyqqwb4s8087kdj11zyz0cza710kpxqz"
         "node_modules/formdata-polyfill")
   (list "gaxios" "7.3.1"
         "174rd4f5jpx4axq1n3vqdl64wfi5w9hx8nvjkhpwj4ah8cxlr723"
         "node_modules/gaxios")
   (list "gcp-metadata" "8.1.2"
         "156v633mndhk6r6c7102idkkdian7irr3lpca90hfp3md34g5hzr"
         "node_modules/gcp-metadata")
   (list "get-stream" "9.0.1"
         "1ii445ia39i2qlcavinywlw0qx9k3ggkcabps00qzqqcfdnnyrwf"
         "node_modules/get-stream")
   (list "google-auth-library" "10.9.1"
         "0yijnnlxqhw8iypc3jqpr7923f6nb0j7g8cfb9w2gsi8ajw315a9"
         "node_modules/google-auth-library")
   (list "google-logging-utils" "1.1.3"
         "1g8bjykjsax507xazrgsz23qspq2237c1hkgfaz98grk9q6ir4is"
         "node_modules/google-logging-utils")
   (list "http-proxy-agent" "7.0.2"
         "00kgi96l0vs04g2vl2xw3g53saxb4n9za2x23pbaiyrbm7x76pvq"
         "node_modules/http-proxy-agent")
   (list "debug" "4.4.3"
         "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9"
         "node_modules/http-proxy-agent/node_modules/debug")
   (list "ms" "2.1.3"
         "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn"
         "node_modules/http-proxy-agent/node_modules/ms")
   (list "https-proxy-agent" "7.0.6"
         "1q603cjw6z348j2i7k7s5zb3kp91hi9lml298bv84214wpl8j3wn"
         "node_modules/https-proxy-agent")
   (list "debug" "4.4.3"
         "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9"
         "node_modules/https-proxy-agent/node_modules/debug")
   (list "ms" "2.1.3"
         "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn"
         "node_modules/https-proxy-agent/node_modules/ms")
   (list "human-signals" "8.0.1"
         "1xnl55qynw3yl5q89bqchsf1nrasbjjv6v15c3gc6s9x07cpwfdj"
         "node_modules/human-signals")
   (list "ipaddr.js" "2.5.0"
         "1hr6ls6ig4svfihz9zyiqw9zi61dl1jjf39gc5hvysf85klplvsq"
         "node_modules/ipaddr.js")
   (list "is-docker" "3.0.0"
         "1vnxw8y4p31nx66rbgxhd40jc5zx8akmcf7fpl3gy7n84l5hn8qs"
         "node_modules/is-docker")
   (list "is-in-ssh" "1.0.0"
         "0m6r0p35lv8prm60i7sivbz3606yhsbjv3s0pmqqvzjl33j9l5fd"
         "node_modules/is-in-ssh")
   (list "is-inside-container" "1.0.0"
         "0yz0fbbkypqsx5d5cls1ik8928zkqhwl2kcp4iv7bi2g8fw9bpnv"
         "node_modules/is-inside-container")
   (list "is-plain-obj" "4.1.0"
         "1xr1ws5y464sf7if4zrk0fjxws4p1xwwx05h541mdkdpg97qf7f7"
         "node_modules/is-plain-obj")
   (list "is-stream" "4.0.1"
         "06cd55gjr6kbjwr0hryvmkiqdac4cxf7lfmk42hllcnph7aarx5q"
         "node_modules/is-stream")
   (list "is-unicode-supported" "2.1.0"
         "0qnkzlhkxra98ahzbpcr0w3sd2h22wrffn26gg5zjbz61r0c09jr"
         "node_modules/is-unicode-supported")
   (list "is-wsl" "3.1.1"
         "1cifp5r1mabbd24d1b81xgnh7dy0js7vwnx3hyj6iry2jsbkzygh"
         "node_modules/is-wsl")
   (list "isexe" "2.0.0"
         "0nc3rcqjgyb9yyqajwlzzhfcqmsb682z7zinnx9qrql8w1rfiks7"
         "node_modules/isexe")
   (list "jose" "6.2.12"
         "1zpba5rzx18h00wzh9448bqh2ql6ms6ixqiaxyn0q48fm8mdmn9j"
         "node_modules/jose")
   (list "js-tokens" "4.0.0"
         "0lrw3qvcfmxrwwi7p7ng4r17yw32ki7jpnbj2a65ddddv2icg16q"
         "node_modules/js-tokens")
   (list "js-yaml" "4.3.2"
         "1cg5rqg09lgzlfihykcwi2yr3nl7xr6alm1qylzjbyac4b943cn7"
         "node_modules/js-yaml")
   (list "json-bigint" "1.0.0"
         "1dh3z67vh5084b07y8sklacnidzrddkqjjbc3kz6rcygaclm0ksc"
         "node_modules/json-bigint")
   (list "json-schema-to-ts" "3.1.1"
         "0r639hff6d5z17lzkzqb0c8p1blpl97ssi7nx59qgjis8m74xwzn"
         "node_modules/json-schema-to-ts")
   (list "json-schema-traverse" "1.0.0"
         "08cvg5wysj4r0ax2lvhx7j74l7da8w75klz5pmsc57zj5mi24ch2"
         "node_modules/json-schema-traverse")
   (list "jwa" "2.0.1"
         "079lm1m5malvssgz4lxiqvp300gpq6wpmygknvqx5jdxzgwhrg68"
         "node_modules/jwa")
   (list "jws" "4.0.1"
         "04ifx47v412kfslgqgl7shj9im3wivl3f2p3r0311kpq4yq5yfpd"
         "node_modules/jws")
   (list "koffi" "3.3.1"
         "0zyigv6adq4lrmwim0rd8zypglrsm85yc1i6krkqjgv7ivvgdwjp"
         "node_modules/koffi")
   (list "long" "5.3.2"
         "09kbcinla92p75h69i90v5n730wxfaxl34z5r597vpvkcx33w0v8"
         "node_modules/long")
   (list "mime-db" "1.54.0"
         "0864s7g498w1f95yvgq0ayqlgpb8x49jfb80qmcbvsnhcm70a89b"
         "node_modules/mime-db")
   (list "mime-types" "3.0.2"
         "1b6j7px7npv0gli3v249m5a1rc2m8x3qxxpva23zy0y3af1x579g"
         "node_modules/mime-types")
   (list "ms" "2.0.0"
         "1jrysw9zx14av3jdvc3kywc3xkjqxh748g4s6p1iy634i2mm489n"
         "node_modules/ms")
   (list "negotiator" "1.1.0"
         "1m6fj8fixhv6hcjnfipsal14h82zh6ipzjgaln4r39lyna1s5b84"
         "node_modules/negotiator")
   (list "node-addon-api" "7.1.1"
         "10hzqyn8vxz16gmh4hwdxzw3kn83krkypc0wgb8hqz4pbb8ma15i"
         "node_modules/node-addon-api")
   (list "node-addon-native-custom-loader" "0.1.6"
         "0wai6zzgiqyxisghn33v6jyi0q61c75r3z0i6v0v0msky375ghxf"
         "node_modules/node-addon-native-custom-loader")
   (list "node-addon-require-builtin" "0.1.6"
         "0vfx8h1av20a0wyfqlb8ssixhl1mv39syrhkkk5zd7z9bnfrjd8i"
         "node_modules/node-addon-require-builtin")
   (list "node-addon-require-builtin-linux-x64-gnu" "0.1.6"
         "1crl7svr08184p5cf4qgvmhfy7x96ylf7zhvr6zli9vc0nl4psdi"
         "node_modules/node-addon-require-builtin-linux-x64-gnu")
   (list "node-domexception" "1.0.0"
         "0wf9c2mxlzvr2cjwdlg1kgml40idsdyccaswp03pi2ch909k98pb"
         "node_modules/node-domexception")
   (list "node-fetch" "3.3.2"
         "1ardip9x9gicwpbpv1nqw7f8cdngcg0ydy2l9dmjg3rz6q7gjnk1"
         "node_modules/node-fetch")
   (list "node-pty" "1.2.0-beta.15"
         "1ic95zycsd9qvajh777ljlk5hxjm2cni590pcbvyyxg07w6chjhi"
         "node_modules/node-pty")
   (list "npm-run-path" "6.0.0"
         "1pwdj6ghn661hpb4clp3bd5p4lmgcwdz484dkyjg4vm4wfikl5l2"
         "node_modules/npm-run-path")
   (list "path-key" "4.0.0"
         "19s9y2rp8b9wvbccpawvx895d69pam72r1vdvgma51h9k8n9m8mf"
         "node_modules/npm-run-path/node_modules/path-key")
   (list "on-headers" "1.1.0"
         "0962avqk7n8jxzghmi2q8h3wabr5riwvnlln4bs44m4n95wlf897"
         "node_modules/on-headers")
   (list "open" "11.0.4"
         "0740ci54m96m8v17v4mag560xynq8qmzx0dyjcvp0waxglsbjn25"
         "node_modules/open")
   (list "openai" "6.40.0"
         "16q54kyb1nbylq7vgl1bns9bq7j3xi9i40l2gbkih9qa0ryyjpn2"
         "node_modules/openai")
   (list "p-retry" "4.6.2"
         "0n5mgwrr69i01n5y8ah793dcyphjcrmbw7jzx3lj0cfyhjs2n491"
         "node_modules/p-retry")
   (list "pako" "0.2.9"
         "17ydqdhy9g76ppkbg0lgkk9837vkpga6gzw8w0m04mfinzqik4sa"
         "node_modules/pako")
   (list "parse-ms" "4.0.0"
         "0s7vnwlhl2513zvff5f21qml9yz3ds24z6gyz4k9vkbv7wcpxg5b"
         "node_modules/parse-ms")
   (list "partial-json" "0.1.7"
         "08k35xv5dhx2k0mlamp1yl5qzyfrjrvw6d2gl8ngn9fwdznzxsih"
         "node_modules/partial-json")
   (list "path-key" "3.1.1"
         "14kvp849wnkg6f3dqgmcb73nnb5k6b3gxf65sgf0x0qlp6n9k2ab"
         "node_modules/path-key")
   (list "picocolors" "1.1.1"
         "1nc2z3w16wpz2840srcwyxd747khwfvh66yigyrpwywn0wldpbnk"
         "node_modules/picocolors")
   (list "picomatch" "4.0.7"
         "1a20wz4mq49bigbh7dszhyaxz7d6358gv521izy9zgfdwcxlcyv9"
         "node_modules/picomatch")
   (list "pkce-challenge" "5.0.1"
         "0w7a7gzxrn5widngl5w358kfi68njp121ig77p8n4mf0bfpbpz6i"
         "node_modules/pkce-challenge")
   (list "powershell-utils" "0.2.1"
         "0x97l9agkdxxnvb53b4f7sbkqf1vz9p1x9a9hq0q6h1qjr78fy9j"
         "node_modules/powershell-utils")
   (list "pretty-ms" "9.3.1"
         "0ns7yk4my8c6dqpcgr9bnqv10mq1dc23p1dk8klz0pl6x3s3q1n0"
         "node_modules/pretty-ms")
   (list "protobufjs" "7.6.6"
         "1zkdxclaj4cnznfahypp12qzykgi0zqyx9kd74kmsl3b0jrl20nz"
         "node_modules/protobufjs")
   (list "readdirp" "4.1.2"
         "0njzcnyjv31k0lw1rswaay334iyck4wvx6wwjdmzxbhlcfxa4vkn"
         "node_modules/readdirp")
   (list "require-from-string" "2.0.2"
         "10ldp2bzb86czf47kmvirn9x2976yh6g0my7l1spg3whcm4llsfb"
         "node_modules/require-from-string")
   (list "resolve.exports" "2.0.3"
         "05i82xb5g8656cp4sjzdsgy27yfj4dprdrca1dbl3p7cpz0bhk56"
         "node_modules/resolve.exports")
   (list "restructure" "3.0.2"
         "0hab2da45dfvciakkmp0hc0mdpa2969dwsyj95k609lk5svrbhhi"
         "node_modules/restructure")
   (list "retry" "0.13.1"
         "1140kg3sia3i6fi3bzpypam1gysa7i3szdyci3l7am44br2dh8bm"
         "node_modules/retry")
   (list "run-applescript" "7.1.0"
         "17ccrallz3df13sh6pdkpfcni3i3gharlzh236qxd85a2xqwx6nj"
         "node_modules/run-applescript")
   (list "safe-buffer" "5.2.1"
         "1s5kvjpwqsc682zcy71h9c6pxla21sysfwj270x6jjkca421h62x"
         "node_modules/safe-buffer")
   (list "saxes" "6.0.0"
         "1nwn5r953v568imgl8zz9bkr1ra67zkbilk5qdsx3jqwpvxm5pqw"
         "node_modules/saxes")
   (list "semver" "7.8.5"
         "0pbx2afqpl5na8j25kgz496g6wrfaggrasrkj745fz8d63a4al6q"
         "node_modules/semver")
   (list "sharp" "0.35.4"
         "0nka9ypghkchma1kszz0lqx6mjijkv5kwbp2v44p6b1pj01g3gkf"
         "node_modules/sharp")
   (list "shebang-command" "2.0.0"
         "0vjmdpwcz23glkhlmxny8hc3x01zyr6hwf4qb3grq7m532ysbjws"
         "node_modules/shebang-command")
   (list "shebang-regex" "3.0.0"
         "13wmb23w5srjpn9xx1c85yk5jbc5z9ypg0iz33h6nv5jdnmapnzy"
         "node_modules/shebang-regex")
   (list "sherpa-onnx-linux-x64" "1.13.8"
         "0b1ir72i5nz2dl4102bcc509l8ick8z48dbsla68b9axhb6ina8k"
         "node_modules/sherpa-onnx-linux-x64")
   (list "sherpa-onnx-node" "1.13.8"
         "1wghl7krynpa1ggamwgy5gfx6gy3zsd9272wrblvcl6r325pnanv"
         "node_modules/sherpa-onnx-node")
   (list "signal-exit" "4.1.0"
         "15dpm2y84hd7ybqy89raj6xza56dfj92i1vkad0sdxpc26l5hfwx"
         "node_modules/signal-exit")
   (list "standardwebhooks" "1.1.1"
         "1vaailq1hmvlvwmvv8pc7926zmbizr26z1xw7km317hc53n8zg6h"
         "node_modules/standardwebhooks")
   (list "strip-final-newline" "4.0.0"
         "17lsqdpy1wgnxm2g5ln2a86zps09a6xadqxq56rqsmgl373zcjax"
         "node_modules/strip-final-newline")
   (list "tiny-inflate" "1.0.3"
         "0klgdanxyf1rl8gs1ckpw9z41aww4a0n8gh4mypgzr94jhrjp4vk"
         "node_modules/tiny-inflate")
   (list "ts-algebra" "2.0.0"
         "0p669fivm6k85ip9n54rv6bh70lcalrv43l6jhp9bdqyv27rdhzl"
         "node_modules/ts-algebra")
   (list "tslib" "2.8.1"
         "17hiw9pawyczkhsnhlq4k9dn3kq2l49nk5rlfn049bmbxvakbxk6"
         "node_modules/tslib")
   (list "turndown" "7.2.4"
         "183g55p22yqg3gxl3k880yq0n15r4qp4kdgisxf5xjmfy31ipxh5"
         "node_modules/turndown")
   (list "typebox" "1.3.7"
         "0fl6l3ylrdgbgvdss4c5s3l5i0kcbadr8a73kk53cjg6c0jr9l5i"
         "node_modules/typebox")
   (list "undici" "8.11.0"
         "02pd2yy6sad6hdv6phq70ghxi7m63vwy7cl8f53ylqjn431nfhj4"
         "node_modules/undici")
   (list "undici-types" "8.9.0"
         "1ikq7qx4grfa4k5pg93snwd2lzlxh7mki2mc1sr2245zri8phn1s"
         "node_modules/undici-types")
   (list "unicode-properties" "1.4.1"
         "0qlrhjjjz4mjlhgbrr45hb9falnnyiw3fbppij9xdi0jqxw89ynz"
         "node_modules/unicode-properties")
   (list "unicode-trie" "2.0.0"
         "1dffvsb50qy1wpcc3zpakgrv3rk9ggpbai6m5g25w3ar5427bfbx"
         "node_modules/unicode-trie")
   (list "unicorn-magic" "0.3.0"
         "13lh0rv0k0bafp02x2krzk7vdj3qjd3ng0qrfd7z4kqlczlbpgz4"
         "node_modules/unicorn-magic")
   (list "vary" "1.1.2"
         "0wbf4kmfyzc23dc0vjcmymkd1ks50z5gvv23lkkkayipf438cy3k"
         "node_modules/vary")
   (list "web-streams-polyfill" "3.3.3"
         "0m5v1r411b7vlziw4bgk1vxc8mkxbnklsq20bk9ylqq2vk9kiq8y"
         "node_modules/web-streams-polyfill")
   (list "which" "2.0.2"
         "1p2fkm4lr36s85gdjxmyr6wh86dizf0iwmffxmarcxpbvmgxyfm1"
         "node_modules/which")
   (list "which-command" "0.1.0"
         "1p9navjy2y8w7bffpgkd4a7y7qphx6ykihqg84c5c0423hq3rkly"
         "node_modules/which-command")
   (list "ws" "8.21.3"
         "1hrd1jn7vgi9f82x60bzkymf3gzrvii1f95rnm8cx4ap43pm8d6z"
         "node_modules/ws")
   (list "wsl-utils" "1.0.0"
         "1kp2fih73a3k49xn64wfcfpaimlqwrcvd1n6mqqx8jd6vk73jc5r"
         "node_modules/wsl-utils")
   (list "powershell-utils" "0.1.0"
         "0aqrjbd5ib1h3iv9lqmkcc50cfl3303b71l152nxcwr17qvypfdb"
         "node_modules/wsl-utils/node_modules/powershell-utils")
   (list "xmlchars" "2.2.0"
         "1a3daxxjcy0p0qbxcqp6d9z6h1czsab5xabanyavvr33i4lh1ydx"
         "node_modules/xmlchars")
   (list "yaml" "2.9.1"
         "1lz5kpawfrwc1sb196r3my21qnl06213f65mnw3s5f2rym6cbxjf"
         "node_modules/yaml")
   (list "yoctocolors" "2.2.0"
         "0p3zgy88305bnmpiq9d69z2nhcsn85s4yf293j5s9m5w15223cxb"
         "node_modules/yoctocolors")
   (list "zod" "4.6.5"
         "1z1n1fsh2lrmmqpf7lm81p5r1qq6mi1sqnf2mz2c23g37m9hr357"
         "node_modules/zod")
))

(define %dsh-node-bin-links
  ;; (link target), both relative to the package directory, as npm
  ;; creates them in each node_modules/.bin.
  (list
   (list "node_modules/.bin/anthropic-ai-sdk" "../@anthropic-ai/sdk/bin/cli")
   (list "node_modules/.bin/cordis" "../@deepseek-ai/cordis/bin.js")
   (list "node_modules/.bin/is-docker" "../is-docker/cli.js")
   (list "node_modules/.bin/is-inside-container" "../is-inside-container/cli.js")
   (list "node_modules/.bin/js-yaml" "../js-yaml/bin/js-yaml.js")
   (list "node_modules/.bin/libreoffice-kit" "../@deepseek-ai/libreoffice-kit/lib/cli.js")
   (list "node_modules/.bin/node-which" "../which/bin/node-which")
   (list "node_modules/.bin/pi-ai" "../@earendil-works/pi-ai/dist/cli.js")
   (list "node_modules/.bin/semver" "../semver/bin/semver.js")
   (list "node_modules/.bin/which-command" "../which-command/cli.js")
   (list "node_modules/.bin/yaml" "../yaml/bin.mjs")
))

;; What the dsh package hands to its build: one download derivation per
;; tarball, named after the path it belongs at, and the name/path pairs that
;; tell the build where to unpack each one.
(define %dsh-node-inputs
  (map (lambda (spec)
         (match spec
           ((name version digest path)
            (cons (dsh-input-name path)
                  (dsh-npm-origin name version digest)))))
       %dsh-node-modules))

(define %dsh-node-install-plan
  (map (lambda (spec)
         (match spec
           ((_ _ _ path) (cons (dsh-input-name path) path))))
       %dsh-node-modules))
