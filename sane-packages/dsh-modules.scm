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
   (list "@anthropic-ai/sdk" "0.129.0"
         "1cnzwbhsdn50wvg1z27z9lrzl3jripxxgbnvmn7yjbqx8wqs3yys"
         "node_modules/@anthropic-ai/sdk")
   (list "@aws-sdk/client-bedrock-runtime" "3.1127.0"
         "1vdn38cnb7f6ys18l63yk7imhal9q2xs6k25kw5iva77w8b3d66b"
         "node_modules/@aws-sdk/client-bedrock-runtime")
   (list "@aws-sdk/core" "3.980.0"
         "1r3675sazf68mr6g7gi2qlhrn7nwag5cqijrppnrd9h9wim2i14q"
         "node_modules/@aws-sdk/core")
   (list "@aws-sdk/credential-provider-env" "3.972.81"
         "0n74bvyyz1alcrc0kpg9w184v4fmapr1mj8bdgg3m6q1s5jz2m1j"
         "node_modules/@aws-sdk/credential-provider-env")
   (list "@aws-sdk/credential-provider-http" "3.972.83"
         "16cqm99l413is3f8d58qn2kcv2w7k77mbzdr7rp1iw2yqkw1xm4b"
         "node_modules/@aws-sdk/credential-provider-http")
   (list "@smithy/node-http-handler" "4.14.2"
         "0j0pj28p018pj5f4z9yrbylmdlbw4swnrwszd55ipl19yxw1ryc9"
         "node_modules/@aws-sdk/credential-provider-http/node_modules/@smithy/node-http-handler")
   (list "@aws-sdk/credential-provider-ini" "3.973.26"
         "1bwgyrw6v2cl19rwdv4ak529i9dk6qfxf2x2rk4kz7mz902lris8"
         "node_modules/@aws-sdk/credential-provider-ini")
   (list "@aws-sdk/credential-provider-login" "3.972.88"
         "08bxf7p5ycjj49c00w31r2y5i4l3vywy6a8zpvm0drcqlndbkgvi"
         "node_modules/@aws-sdk/credential-provider-login")
   (list "@aws-sdk/credential-provider-node" "3.972.93"
         "1vdsghizibzm7xzchqwa03ml7bpjrk5kvg2pw2fv7kf64vw7bglh"
         "node_modules/@aws-sdk/credential-provider-node")
   (list "@aws-sdk/credential-provider-process" "3.972.81"
         "01n78cd97zz71vfqg4i8zgjml7nahnar4rzkw88d5zvvigh31vg7"
         "node_modules/@aws-sdk/credential-provider-process")
   (list "@aws-sdk/credential-provider-sso" "3.973.25"
         "0kgm6zv16hznbqslhf1xy34bz5xxik0l701r36iij040wbz8l9jv"
         "node_modules/@aws-sdk/credential-provider-sso")
   (list "@aws-sdk/token-providers" "3.1162.0"
         "05dk57d44f6abcppzhmvhk5d26616x8b7krv7viyr5ajqqdhkwrj"
         "node_modules/@aws-sdk/credential-provider-sso/node_modules/@aws-sdk/token-providers")
   (list "@aws-sdk/credential-provider-web-identity" "3.972.87"
         "1w82ldlsv2csggnh7696fcgmpghvk9ln5fkwbh2cncgzgnr7ppn6"
         "node_modules/@aws-sdk/credential-provider-web-identity")
   (list "@aws-sdk/eventstream-handler-node" "3.972.40"
         "0743nmdgrmirlyhsbapk8a7x4bkcbn595q1ndks1lbk7k9dxky79"
         "node_modules/@aws-sdk/eventstream-handler-node")
   (list "@aws-sdk/middleware-eventstream" "3.972.36"
         "0yj89wkh2k9mnzd34w35cwclnxzdw2cf5y9v2a4yyqwljj81v81j"
         "node_modules/@aws-sdk/middleware-eventstream")
   (list "@aws-sdk/middleware-websocket" "3.972.63"
         "1c487n18y7ncsyd0ajlvccsbwmfpj66klpa9abns94vg7zjvbvwf"
         "node_modules/@aws-sdk/middleware-websocket")
   (list "@aws-sdk/nested-clients" "3.998.0"
         "1xcdh2gjp76fycil7s1b7vvjck27sqhb3s8y3rmpagsrnn4gkx9b"
         "node_modules/@aws-sdk/nested-clients")
   (list "@smithy/node-http-handler" "4.14.2"
         "0j0pj28p018pj5f4z9yrbylmdlbw4swnrwszd55ipl19yxw1ryc9"
         "node_modules/@aws-sdk/nested-clients/node_modules/@smithy/node-http-handler")
   (list "@aws-sdk/signature-v4-multi-region" "3.996.51"
         "1jdpl3kl4s7jnsp9msi0j4x459dyqacb4vxjrl7fr8gi45lr5i89"
         "node_modules/@aws-sdk/signature-v4-multi-region")
   (list "@aws-sdk/token-providers" "3.1127.0"
         "1h4m7k7ifmabsqfbnf34sj7p3lap01m62spvrf3xzgivf65ablym"
         "node_modules/@aws-sdk/token-providers")
   (list "@aws-sdk/types" "3.975.0"
         "1xywxb6dd6l4injik7swjxwj482yk1m4fh786hwgb98159k232f9"
         "node_modules/@aws-sdk/types")
   (list "@aws-sdk/xml-builder" "3.972.42"
         "049y6vd6jgbn7c19464wamykqj9jf2h5ys8hz5r294m4arc4m4ky"
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
   (list "@babel/runtime" "7.29.13"
         "0znz9gzwb9wjpz4ihndpcl28ab4yg0y7ci81g7xjpkm20rqarybf"
         "node_modules/@babel/runtime")
   (list "@deepseek-ai/cordis" "4.0.5"
         "08dkwn8m2cgbsz7pa7h9gm0lfz7ixn5ar21s53k6j1chzy0sx4n4"
         "node_modules/@deepseek-ai/cordis")
   (list "@deepseek-ai/cordis-plugin-group" "1.0.5"
         "0dmvlhcfwivxbrqmwfqiq6mfy2djgsgrf85ps4skqds69p7xh6qa"
         "node_modules/@deepseek-ai/cordis-plugin-group")
   (list "@deepseek-ai/cordis-plugin-include" "1.0.10"
         "1sj9xffnh02jy7d63kpmdk39qx7zkcxpi3gkwjwm670sfbbs47a5"
         "node_modules/@deepseek-ai/cordis-plugin-include")
   (list "@deepseek-ai/cordis-plugin-loader" "1.0.6"
         "0rcfqdsmgbs075fai5ggxhjwik7x7glq6crjwz1as6kmm5bfhmfs"
         "node_modules/@deepseek-ai/cordis-plugin-loader")
   (list "@deepseek-ai/cordis-plugin-timer" "1.1.7"
         "1yn1z07g88vn287i6axvzzdivqxjrbbpw912zvbd02l76f093ync"
         "node_modules/@deepseek-ai/cordis-plugin-timer")
   (list "@deepseek-ai/cosmokit" "1.8.6"
         "0y3f0ds0rq6lwvyhalca4f8xp4wnbvi5cs94jrgpzfmgd8j2qcq2"
         "node_modules/@deepseek-ai/cosmokit")
   (list "@deepseek-ai/dsh-acp" "0.2.1-rc.2"
         "0nsw1lx14j7shv1iml8x62y3lkcbn7xs4idqvjfgqdg3qs2myfcd"
         "node_modules/@deepseek-ai/dsh-acp")
   (list "@deepseek-ai/dsh-acp-app" "0.2.1-rc.2"
         "15168a7x88a1wj99c7y5zah6q58rc5lh0n9wm9gfnxhnxgphfi9i"
         "node_modules/@deepseek-ai/dsh-acp-app")
   (list "@deepseek-ai/dsh-agent" "0.2.1-rc.2"
         "1a932sy56pzpgvkcp030zqms6iyl51idmngk6l2nkfrj6xh9lnxg"
         "node_modules/@deepseek-ai/dsh-agent")
   (list "@deepseek-ai/dsh-agent-default-model" "0.2.1-rc.2"
         "0kwxy5dmyzwwqh7dnscc3z5yw61phm8nyrja5y1k9ars6lykm51s"
         "node_modules/@deepseek-ai/dsh-agent-default-model")
   (list "@deepseek-ai/dsh-agent-instructions" "0.2.1-rc.2"
         "1rhng6vwwd2y9fgkw66brcsg6iwgs2pyqpvm05bk107s38vcg5gl"
         "node_modules/@deepseek-ai/dsh-agent-instructions")
   (list "@deepseek-ai/dsh-agent-loop" "0.2.1-rc.2"
         "0nd6l93bcgs8g93bczhayapp5sn83vwfdz5fykkkwjgfsfd4s0bn"
         "node_modules/@deepseek-ai/dsh-agent-loop")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-agent-loop/node_modules/zod")
   (list "@deepseek-ai/dsh-agent-preset" "0.2.1-rc.2"
         "14b2kzml8y4cj0lkq2a9lj99lz3gfg51zgzp54c8a27q4g2dmnrz"
         "node_modules/@deepseek-ai/dsh-agent-preset")
   (list "@deepseek-ai/dsh-agent-preset-registry" "0.2.1-rc.2"
         "15k470p1qma15lc7lrzbvm9zjbyhb2p1qi82pi8ryg8p15nxyrzf"
         "node_modules/@deepseek-ai/dsh-agent-preset-registry")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-agent-preset-registry/node_modules/zod")
   (list "@deepseek-ai/dsh-agent-tool-presentation" "0.2.1-rc.2"
         "0v95q5pwnznm0b5f1x9qc1kn8h1by74dm4q0b9xxqkank1lp21sg"
         "node_modules/@deepseek-ai/dsh-agent-tool-presentation")
   (list "@deepseek-ai/dsh-anonymous-user-id" "0.2.1-rc.2"
         "0abr8spayy5i30kf4p4lnc0nizlmjczj20qlmv87s3y2l41qx3yp"
         "node_modules/@deepseek-ai/dsh-anonymous-user-id")
   (list "@deepseek-ai/dsh-api-account-controller" "0.2.1-rc.2"
         "0dyngbi1jg4xsn9s0dgpmc0mv9rmw1i68viwghk3crnq27ivs8s3"
         "node_modules/@deepseek-ai/dsh-api-account-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-account-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-gateway" "0.2.1-rc.2"
         "0a3rjhhb83jc6ahfv2sbzkm7r4fqijmfbvn4y20dwqg4rgpnfkh4"
         "node_modules/@deepseek-ai/dsh-api-gateway")
   (list "@deepseek-ai/dsh-api-job-controller" "0.2.1-rc.2"
         "06zlnhs9d9hhk23mb7bghrmkpsc5xzk6595lk1ljk34451cp0db5"
         "node_modules/@deepseek-ai/dsh-api-job-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-job-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-remote-access" "0.2.1-rc.2"
         "0frbayij2wnlph9wwq1i9m4adfi5vxv3arj4iy8v3259g7amhchr"
         "node_modules/@deepseek-ai/dsh-api-remote-access")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-remote-access/node_modules/zod")
   (list "@deepseek-ai/dsh-api-remotes" "0.2.1-rc.2"
         "0f1siwvriw8sizsxardjnx2f5vsd22jbnn81b59vbaxj5p3z0cyq"
         "node_modules/@deepseek-ai/dsh-api-remotes")
   (list "@deepseek-ai/dsh-api-session-controller" "0.2.1-rc.2"
         "0v2y8m67nk89xyn2d1nbwcv8y7nnwig6a7lxlkqvd8jahj0ciydb"
         "node_modules/@deepseek-ai/dsh-api-session-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-session-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-settings-controller" "0.2.1-rc.2"
         "0ha3dp2i5hksccj84pqq909xv3xsz2s13lmkqwblyym1c5gz6gfi"
         "node_modules/@deepseek-ai/dsh-api-settings-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-settings-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-terminal-controller" "0.2.1-rc.2"
         "0hv5qsym3snpzdvxdhf7znjijmnpjinwbxh6xvbgg5gbz0y3j44h"
         "node_modules/@deepseek-ai/dsh-api-terminal-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-terminal-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-workspace-controller" "0.2.1-rc.2"
         "0sivsclckv2vwbf7aijxy9qzb1hs1wza5692jvy61p03bc6dkgsx"
         "node_modules/@deepseek-ai/dsh-api-workspace-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-workspace-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-workspace-files" "0.2.1-rc.2"
         "0b74kf7ggxfx0bbpb2xgwyzlsj30d8anf0y8is13ddvjwz5rs9qs"
         "node_modules/@deepseek-ai/dsh-api-workspace-files")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-workspace-files/node_modules/zod")
   (list "@deepseek-ai/dsh-app-boot" "0.2.1-rc.2"
         "0ddw152n25gxbvwl952wgci4pl61s6m44mz9bz6mn4vxg5hslkm4"
         "node_modules/@deepseek-ai/dsh-app-boot")
   (list "@deepseek-ai/dsh-atomic-write" "0.2.1-rc.2"
         "00mzsnn7krqhlcavfxp8y21im4w4yd1c00ddsj2mq5mj91fb80ab"
         "node_modules/@deepseek-ai/dsh-atomic-write")
   (list "@deepseek-ai/dsh-attachment" "0.2.1-rc.2"
         "12938c97l7wzflfyxd02fb4956xhz1r6liv94z5nzb6rsqzf9n79"
         "node_modules/@deepseek-ai/dsh-attachment")
   (list "@deepseek-ai/dsh-attachment-local" "0.2.1-rc.2"
         "1vi2hxpiykx8hi0xgc5c2r9x5paqm42iisij6xpiz89fk9yi5gqf"
         "node_modules/@deepseek-ai/dsh-attachment-local")
   (list "@deepseek-ai/dsh-authorization" "0.2.1-rc.2"
         "1ma1fnrwigbpygdh7yway9afl5kinnrhvlvmdik4gmym68f82g1i"
         "node_modules/@deepseek-ai/dsh-authorization")
   (list "@deepseek-ai/dsh-base" "0.2.1-rc.2"
         "1kwppgm6xklxc3x6fq5cwd8kvhiw3w4aicwc0926vnzgjfdjfg09"
         "node_modules/@deepseek-ai/dsh-base")
   (list "@deepseek-ai/dsh-bash-local" "0.2.1-rc.2"
         "0bflz6552x4csxdc9lxz7y67mfxryka1n0kjzmgfh5n4gfbdixy2"
         "node_modules/@deepseek-ai/dsh-bash-local")
   (list "@deepseek-ai/dsh-bash-sandbox" "0.2.1-rc.2"
         "1l4dbqprqvxazhdmsf2f03x9a0f1ps7fpp3nbqrvmr91havc55qw"
         "node_modules/@deepseek-ai/dsh-bash-sandbox")
   (list "@deepseek-ai/dsh-brand" "0.2.1-rc.2"
         "05h7ywkf2hcyikggnq5z0xp6yf1fcrzdah9lrn0nhiqcm8nkri5b"
         "node_modules/@deepseek-ai/dsh-brand")
   (list "@deepseek-ai/dsh-chunked-list" "0.2.1-rc.2"
         "0278nsyk1302g6g34hwl2y6qzr4hsgbdlcwhk35m6df43w1jz7nn"
         "node_modules/@deepseek-ai/dsh-chunked-list")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-chunked-list/node_modules/zod")
   (list "@deepseek-ai/dsh-client-connection" "0.2.1-rc.2"
         "16gypw8i3jbrzfn8hq88nyx02dh8ykvqhywc3kwnw0lj5vlhq5li"
         "node_modules/@deepseek-ai/dsh-client-connection")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-connection/node_modules/zod")
   (list "@deepseek-ai/dsh-client-file-upload" "0.2.1-rc.2"
         "1w9pvkn47mdb89rd3ckpbgwjsg0z2qlkipib5s509gb997k6zx89"
         "node_modules/@deepseek-ai/dsh-client-file-upload")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-file-upload/node_modules/zod")
   (list "@deepseek-ai/dsh-client-hmr" "0.2.1-rc.2"
         "0zw17kxjvq4r7ry6wf2rvcfk23irva166pmkkc7hqhma9ac1c4d8"
         "node_modules/@deepseek-ai/dsh-client-hmr")
   (list "@deepseek-ai/dsh-client-locale" "0.2.1-rc.2"
         "0z1pvpy9f9a7rybifbrs4ymrj587fj0kh2gc4a01jx1hy7wkhw5b"
         "node_modules/@deepseek-ai/dsh-client-locale")
   (list "@deepseek-ai/dsh-client-modules" "0.2.1-rc.2"
         "00lza3am676f6wyizg5qnd63f65d6fj7414m0j7wglc96bm0478q"
         "node_modules/@deepseek-ai/dsh-client-modules")
   (list "@deepseek-ai/dsh-client-product-analytics" "0.2.1-rc.2"
         "1w7j7c222mv2ix4yl0gdyccyv78b9c27vh1820rj2naxbi96fs5r"
         "node_modules/@deepseek-ai/dsh-client-product-analytics")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-product-analytics/node_modules/zod")
   (list "@deepseek-ai/dsh-client-resources" "0.2.1-rc.2"
         "12p7ncac2kdh4382pvkqhbdrgapm409p00qbh5wqg8hvyws8ipsj"
         "node_modules/@deepseek-ai/dsh-client-resources")
   (list "@deepseek-ai/dsh-client-shortcuts" "0.2.1-rc.2"
         "04zfg8kqv2n18nrfwqvgd6w5dvd2xxs3b8p334f4hc8frwhm90ap"
         "node_modules/@deepseek-ai/dsh-client-shortcuts")
   (list "@deepseek-ai/dsh-client-ui-agent-preset" "0.2.1-rc.2"
         "0f1bn2zzi6qqvfi8z2q7ba77fh6ihw49nmnclai0f7mlz2mlai8r"
         "node_modules/@deepseek-ai/dsh-client-ui-agent-preset")
   (list "@deepseek-ai/dsh-client-ui-approval" "0.2.1-rc.2"
         "1j32r4jhl9mfavs1yjrvhaifin2si4nh4r6lqhfwmhw2fzij16lc"
         "node_modules/@deepseek-ai/dsh-client-ui-approval")
   (list "@deepseek-ai/dsh-client-ui-attachment" "0.2.1-rc.2"
         "0lh7n8vaa351msscp4acpkmha2ib22kyhz8kxmx2mc9s55ddbzs3"
         "node_modules/@deepseek-ai/dsh-client-ui-attachment")
   (list "@deepseek-ai/dsh-client-ui-brand-official" "0.2.1-rc.2"
         "1a6nb1qdmcks39mqwwkx4n2libglinxncxgirz6wxyp96k6fg1dn"
         "node_modules/@deepseek-ai/dsh-client-ui-brand-official")
   (list "@deepseek-ai/dsh-client-ui-chat" "0.2.1-rc.2"
         "04dgdgm33kp6xd43c73a2k7l3l9i1f9kzw9sgqp27ljbk5bnb6gh"
         "node_modules/@deepseek-ai/dsh-client-ui-chat")
   (list "@deepseek-ai/dsh-client-ui-commands" "0.2.1-rc.2"
         "108id0d3v0757krcx795l6yqyhrd44bg83s1c6cs5i41cxvzfny6"
         "node_modules/@deepseek-ai/dsh-client-ui-commands")
   (list "@deepseek-ai/dsh-client-ui-conversation" "0.2.1-rc.2"
         "1l6r6qadj31vlbsnv60n825q7v2zcdk9y6pf44rikknphndr33s0"
         "node_modules/@deepseek-ai/dsh-client-ui-conversation")
   (list "@deepseek-ai/dsh-client-ui-cordis" "0.2.1-rc.2"
         "0bf3d7wjqbp4nlf0p4gw6izbisjbyia13c9v20q2dp8zy3ppa0fx"
         "node_modules/@deepseek-ai/dsh-client-ui-cordis")
   (list "@deepseek-ai/dsh-client-ui-deepseek-model-label-1017" "0.2.1-rc.2"
         "1kraf891xd9m90krfm72w386x68gpnpva4fvh7f0fp1ngkvqcrw5"
         "node_modules/@deepseek-ai/dsh-client-ui-deepseek-model-label-1017")
   (list "@deepseek-ai/dsh-client-ui-deliverables" "0.2.1-rc.2"
         "0y3dgmm6n2bi0nk4c2vycy69al8c694rpvkpl31aa7fz12kv5l3s"
         "node_modules/@deepseek-ai/dsh-client-ui-deliverables")
   (list "@deepseek-ai/dsh-client-ui-directory-picker-browse" "0.2.1-rc.2"
         "0lf08mg7vi64llwxcr2b09cq0x8azlippdf2lab4zqqhx4qpqasd"
         "node_modules/@deepseek-ai/dsh-client-ui-directory-picker-browse")
   (list "@deepseek-ai/dsh-client-ui-directory-picker-native" "0.2.1-rc.2"
         "13sn1jfh1jwiya047bs9qyz6ja37nhy0xfshkx7n7s38zyijayfw"
         "node_modules/@deepseek-ai/dsh-client-ui-directory-picker-native")
   (list "@deepseek-ai/dsh-client-ui-goal" "0.2.1-rc.2"
         "1al7fgachylqqxfr2z5kr4ah9a2kpixa687cy17950yvp8c6g32d"
         "node_modules/@deepseek-ai/dsh-client-ui-goal")
   (list "@deepseek-ai/dsh-client-ui-input-trigger" "0.2.1-rc.2"
         "0jb88jhfh0q0rywlrzpyk36va6prf4d3acnh3q1y1vqmkbimlfvi"
         "node_modules/@deepseek-ai/dsh-client-ui-input-trigger")
   (list "@deepseek-ai/dsh-client-ui-jobs" "0.2.1-rc.2"
         "1qczx300mzn7jkssf8a42d5vx4bkpj94j5kab703lnfs2cg20v0x"
         "node_modules/@deepseek-ai/dsh-client-ui-jobs")
   (list "@deepseek-ai/dsh-client-ui-layout" "0.2.1-rc.2"
         "12vjc6mdxlamxdymslnfajhjkw5gd7jkfqmsvag6zypdri5axk6i"
         "node_modules/@deepseek-ai/dsh-client-ui-layout")
   (list "@deepseek-ai/dsh-client-ui-message-feedback" "0.2.1-rc.2"
         "0dhy17jqsxp0six2viicsjz42gdgbng2zb7bdrikxnfnna1qn1qp"
         "node_modules/@deepseek-ai/dsh-client-ui-message-feedback")
   (list "@deepseek-ai/dsh-client-ui-model-selection" "0.2.1-rc.2"
         "1fhx87jmdb5m52q1x76k5mqn32qir7fj3d96rx45bmss75apwfsy"
         "node_modules/@deepseek-ai/dsh-client-ui-model-selection")
   (list "@deepseek-ai/dsh-client-ui-open-in-app" "0.2.1-rc.2"
         "15bw5qa9pdffd8h3ai6s9m80i1kna02g72aha6bn4mz65kqdpx5d"
         "node_modules/@deepseek-ai/dsh-client-ui-open-in-app")
   (list "@deepseek-ai/dsh-client-ui-permission-presets" "0.2.1-rc.2"
         "1is540rpr3f8wyg9gcnblvrxdhsf4kl94x5avadksqh9spcbsx1a"
         "node_modules/@deepseek-ai/dsh-client-ui-permission-presets")
   (list "@deepseek-ai/dsh-client-ui-plan" "0.2.1-rc.2"
         "09ikjhn27rbpwxhgb23fxfbb720c8jsdd6g4vyda0inbkp0hp32b"
         "node_modules/@deepseek-ai/dsh-client-ui-plan")
   (list "@deepseek-ai/dsh-client-ui-plugin-manager" "0.2.1-rc.2"
         "15ch1rsk6pm93zb2rmq5g5447d1iqqjkw9n7n5kzns0bqkrg3wd1"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-manager")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-manager/node_modules/zod")
   (list "@deepseek-ai/dsh-client-ui-plugin-market" "0.2.1-rc.2"
         "1w0nvf1iw0vcr73s59p7n3brpav9pgncdagh59hpcfbhg7wcds1d"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-market")
   (list "@deepseek-ai/dsh-client-ui-reference" "0.2.1-rc.2"
         "131zdvy6vy58w534p30ncpyqj0kgwsfq7bqsdkbj6f1qyiy7v4jr"
         "node_modules/@deepseek-ai/dsh-client-ui-reference")
   (list "@deepseek-ai/dsh-client-ui-renderer" "0.2.1-rc.2"
         "1i6rjn1vfickarfavpji0s8r5y6q6abfqmb8zvpr7715s7gnn0fv"
         "node_modules/@deepseek-ai/dsh-client-ui-renderer")
   (list "@deepseek-ai/dsh-client-ui-schedule" "0.2.1-rc.2"
         "1sr815pi32dxs9ljhjy7pkwzhr0fjn0j7dhh4wggq8zgji649p4d"
         "node_modules/@deepseek-ai/dsh-client-ui-schedule")
   (list "@deepseek-ai/dsh-client-ui-secret-mask" "0.2.1-rc.2"
         "0aas47x2g0360r80rfa8jj8954wwbb1dl2vj1hq6vpl5ikfc0an7"
         "node_modules/@deepseek-ai/dsh-client-ui-secret-mask")
   (list "@deepseek-ai/dsh-client-ui-session" "0.2.1-rc.2"
         "0s10f8p2hg2c1l6lvy9yq45l95vaq6wz1f2g6lz4gkpzbg7vxw2p"
         "node_modules/@deepseek-ai/dsh-client-ui-session")
   (list "@deepseek-ai/dsh-client-ui-settings" "0.2.1-rc.2"
         "14ywrir7nnn593al1g1pgddzz39ziqsgzn7m6mnh4f49bfkf43h7"
         "node_modules/@deepseek-ai/dsh-client-ui-settings")
   (list "@deepseek-ai/dsh-client-ui-settings-account" "0.2.1-rc.2"
         "11g6msiws5vhkb0dicpjwch46ppih92jbq05bhs9bnj9w4ffcfdc"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-account")
   (list "@deepseek-ai/dsh-client-ui-settings-agent-loop" "0.2.1-rc.2"
         "07jyrgqn9lgm1ca505i6d68dfgjdinhqsz71zqzbnslvlyk9kggv"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-agent-loop")
   (list "@deepseek-ai/dsh-client-ui-settings-general" "0.2.1-rc.2"
         "1xxhspchqg4fha0q5ldn39f2pqzmgfp01hkxarbmfrsxqg41rqcy"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-general")
   (list "@deepseek-ai/dsh-client-ui-settings-models" "0.2.1-rc.2"
         "0i6vkbjh8p5cz2297ad3iwv8ksxkbsnhl66nzidxrw3l9d9r7g7a"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-models")
   (list "@deepseek-ai/dsh-client-ui-settings-plugin-inventory" "0.2.1-rc.2"
         "1ragjdrqr5raarjq2swzm9cr9p61rjac1kzkc5mxrdvxknjwkckl"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-plugin-inventory")
   (list "@deepseek-ai/dsh-client-ui-settings-plugins" "0.2.1-rc.2"
         "1nr7dnlzkh5f9ardd7fbwwvhag0p37jk9cx2kby85x7sy1457ycm"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-plugins")
   (list "@deepseek-ai/dsh-client-ui-settings-session-log" "0.2.1-rc.2"
         "19nhsn6y883ns9ghb0rkksgb304f8scfswzsgl2ry6ac9ln7r3mz"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-session-log")
   (list "@deepseek-ai/dsh-client-ui-settings-shell" "0.2.1-rc.2"
         "0fw0wy4aj2gg9mx8bn9ir6b718n6iiil54a6xyx8zxnmhvdknddl"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-shell")
   (list "@deepseek-ai/dsh-client-ui-settings-subagent" "0.2.1-rc.2"
         "1clapwlpq4vpz87wkcs9cs1jsxlgb7cwz1jslmy9ifvxsczrlfd2"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-subagent")
   (list "@deepseek-ai/dsh-client-ui-settings-web-search" "0.2.1-rc.2"
         "09j0i705p8pvzi9sn8a09z3z7w99rnkiq3wzdd0b9cc9j6kcmdhj"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-web-search")
   (list "@deepseek-ai/dsh-client-ui-shortcuts" "0.2.1-rc.2"
         "0wzcxi1xzvi44wv8wdazmi3cab80f549p3niyvx0zgf1m8j8nx5a"
         "node_modules/@deepseek-ai/dsh-client-ui-shortcuts")
   (list "@deepseek-ai/dsh-client-ui-sidebar" "0.2.1-rc.2"
         "08ba6qa7cwfzr8x1jws9ixli06vwk60x557202w37h56jrlgy6p8"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar")
   (list "@deepseek-ai/dsh-client-ui-sidebar-browser" "0.2.1-rc.2"
         "01ffwjkhvc6qp8shsw9bmz3x4y9h0q60h0miyk2vcxm99v41pskr"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-browser")
   (list "@deepseek-ai/dsh-client-ui-sidebar-documentpreview" "0.2.1-rc.2"
         "012lci4kws2jppdyh0g68v0qibjbyivxwa0wa4v9hk6knqwrh88n"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-documentpreview")
   (list "@deepseek-ai/dsh-client-ui-sidebar-files" "0.2.1-rc.2"
         "1lhzac1g327f8gg1lrhvlw6bc6m3ib966b8w9v3wzab0m0vk3f5n"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-files")
   (list "@deepseek-ai/dsh-client-ui-sidebar-right" "0.2.1-rc.2"
         "09zki8fhyb46jad3szhzm6cqz0j52c54ryz3pqrg4pnaahipr14x"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-right")
   (list "@deepseek-ai/dsh-client-ui-sidebar-terminal" "0.2.1-rc.2"
         "0cg5yawfws10gqfxlp0xiaq8wmbg7amvf4ndv48d0zbi79ka0fl9"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-terminal")
   (list "@deepseek-ai/dsh-client-ui-skill" "0.2.1-rc.2"
         "1jmaxxvkfk8fgqcz0xfh4jyvx1b6xpq6hd3dmpkdlwjf78fnrf1l"
         "node_modules/@deepseek-ai/dsh-client-ui-skill")
   (list "@deepseek-ai/dsh-client-ui-subagent" "0.2.1-rc.2"
         "0lc2808b39l6i1mn81pjxyr6c5yf6wyrilgl01fs4r6gzvf8ixqp"
         "node_modules/@deepseek-ai/dsh-client-ui-subagent")
   (list "@deepseek-ai/dsh-client-ui-theme" "0.2.1-rc.2"
         "0w03w4bjvcp2cc3qiqhp33mcay7vgcynfjkjzlny3h36cqxvgvxi"
         "node_modules/@deepseek-ai/dsh-client-ui-theme")
   (list "@deepseek-ai/dsh-client-ui-tool" "0.2.1-rc.2"
         "14gwqnww2hggg3q9xg05j0q6ka2dm2hca8dhxh6d3ql6wa1g8jxf"
         "node_modules/@deepseek-ai/dsh-client-ui-tool")
   (list "@deepseek-ai/dsh-client-ui-trajectory" "0.2.1-rc.2"
         "17bj7xwdwqn9k6rg7vlbzq1z633h4yzvi3d5m43k2cifjzdmhwqg"
         "node_modules/@deepseek-ai/dsh-client-ui-trajectory")
   (list "@deepseek-ai/dsh-client-ui-user-questions" "0.2.1-rc.2"
         "02w202bf8cmnpl932xplnbahv5733cibm92wmr0ysf95silmnfsi"
         "node_modules/@deepseek-ai/dsh-client-ui-user-questions")
   (list "@deepseek-ai/dsh-client-ui-workflow-run" "0.2.1-rc.2"
         "07mkhgzmvgkk2526cqd0sr3ym52zx5gznkq2alc6dijflwal5lk5"
         "node_modules/@deepseek-ai/dsh-client-ui-workflow-run")
   (list "@deepseek-ai/dsh-client-ui-workspace" "0.2.1-rc.2"
         "0ia7dpmib48wnvrv33l6b1h7yjai8nxx6wh8ghjq85cz5zv4rq07"
         "node_modules/@deepseek-ai/dsh-client-ui-workspace")
   (list "@deepseek-ai/dsh-cmdline" "0.2.1-rc.2"
         "1xlm4nvw2l13bk4sy5z02myqc6a3qbcx45q514i152s66ylf98cr"
         "node_modules/@deepseek-ai/dsh-cmdline")
   (list "@deepseek-ai/dsh-command-compact" "0.2.1-rc.2"
         "1dy2cgs39pblifdrgyp74vavhxsjvqakfr7kb0924zfx1d30d3n9"
         "node_modules/@deepseek-ai/dsh-command-compact")
   (list "@deepseek-ai/dsh-command-feedback" "0.2.1-rc.2"
         "1dqpjv8rgfzq1hjbdc373j0fqwdw9dg3hpg1njglxskiq2inpvkz"
         "node_modules/@deepseek-ai/dsh-command-feedback")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-command-feedback/node_modules/zod")
   (list "@deepseek-ai/dsh-command-goal" "0.2.1-rc.2"
         "0vhhsy7np4hfkz50mjiz4g1751740zzgjzr0m9w6gabripcivv5v"
         "node_modules/@deepseek-ai/dsh-command-goal")
   (list "@deepseek-ai/dsh-commands" "0.2.1-rc.2"
         "0iw63d3768z60ix79rhx71lwvidhyvfikbv5vyhkp0fqazwgs5yp"
         "node_modules/@deepseek-ai/dsh-commands")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-commands/node_modules/zod")
   (list "@deepseek-ai/dsh-compaction" "0.2.1-rc.2"
         "0y15bag7l24vad9r08qjr9f6dpz88l8v4bk5pxamvivaf92x4jrx"
         "node_modules/@deepseek-ai/dsh-compaction")
   (list "@deepseek-ai/dsh-compaction-basic" "0.2.1-rc.2"
         "08136xpcz9aiaz9rvar3560wfhs6qvw8rkywmy0hxgxrpk7p7avv"
         "node_modules/@deepseek-ai/dsh-compaction-basic")
   (list "@deepseek-ai/dsh-compaction-image-offload" "0.2.1-rc.2"
         "02ssgal9mxbjppj3bcm365qwy630gdip0mfpk98r7h99rcy2q7m4"
         "node_modules/@deepseek-ai/dsh-compaction-image-offload")
   (list "@deepseek-ai/dsh-compaction-tool-result-pruner" "0.2.1-rc.2"
         "1k6glsfp75q33as7jndh5wxarq12hf2m1n9x44h6mkfmplwfiyyi"
         "node_modules/@deepseek-ai/dsh-compaction-tool-result-pruner")
   (list "@deepseek-ai/dsh-config-editor" "0.2.1-rc.2"
         "0wcfv232kmlhk9gm6bbpipxs5gb01ap0w5xr70qly7lgpf1asisf"
         "node_modules/@deepseek-ai/dsh-config-editor")
   (list "@deepseek-ai/dsh-cordis-client-runner" "0.2.1-rc.2"
         "1na4hsqrsq08sl8ylhija0j6q2j1fcjckij0la6c7h4xdya01n89"
         "node_modules/@deepseek-ai/dsh-cordis-client-runner")
   (list "@deepseek-ai/dsh-cordis-host-runner" "0.2.1-rc.2"
         "06pfm36x1af1i398zqn6jj9jxh0a43ycqvlqgcqbbrvbkq6wkgsa"
         "node_modules/@deepseek-ai/dsh-cordis-host-runner")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-cordis-host-runner/node_modules/zod")
   (list "@deepseek-ai/dsh-credentials" "0.2.1-rc.2"
         "174hsjjcx5phgwrhld52wfbwpncg5xk14zsqnh57yhlzs9hfsspr"
         "node_modules/@deepseek-ai/dsh-credentials")
   (list "@deepseek-ai/dsh-credentials-local" "0.2.1-rc.2"
         "1zddc21ad9ykkdjws2jwwsb5spz2940ivmchc3y7cbxyqb2bh5pp"
         "node_modules/@deepseek-ai/dsh-credentials-local")
   (list "@deepseek-ai/dsh-deepseek-account" "0.2.1-rc.2"
         "1db5nwg2zgn5rn6r3nqjh75nj5w7im60q1kabiry6kh4c8wv93b4"
         "node_modules/@deepseek-ai/dsh-deepseek-account")
   (list "@deepseek-ai/dsh-deepseek-account-platform" "0.2.1-rc.2"
         "112q8xphqlar8jnbngkbqx2r3ws4skw7l9yssibyq43n83f7r3kr"
         "node_modules/@deepseek-ai/dsh-deepseek-account-platform")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-deepseek-account-platform/node_modules/zod")
   (list "@deepseek-ai/dsh-deepseek-llm-api-extensions" "0.2.1-rc.2"
         "0cbj63aakyl7z7r6magvgifrzb5dv14i4pd4x1lwb816vbmcaaas"
         "node_modules/@deepseek-ai/dsh-deepseek-llm-api-extensions")
   (list "@deepseek-ai/dsh-deque" "0.2.1-rc.2"
         "15csi40q4n7sgf3h4zc3b45wk3f9bk6ymxg56jlh83m03m2qq609"
         "node_modules/@deepseek-ai/dsh-deque")
   (list "@deepseek-ai/dsh-experimental-agent-team" "0.2.1-rc.2"
         "0mbgbnbhgcdsb8vw7wgqqdmbwb8r5iz9zc5fxaspj002vg2mg0zn"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team")
   (list "@deepseek-ai/dsh-experimental-agent-team-profile" "0.2.1-rc.2"
         "0kz2c9r02mfrvgradl1qpkj8m0n8p0mkzrrcndc1d4hrx2gmbihs"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team-profile")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-api-speech-to-text" "0.2.1-rc.2"
         "1y7haa7l6zx2drq4mqcvrvhkg1ip0qw6l5wwn75qlrv0wal3v0y9"
         "node_modules/@deepseek-ai/dsh-experimental-api-speech-to-text")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-api-speech-to-text/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-auto-review" "0.2.1-rc.2"
         "18bfmwbg8xngn1vwl9k0x0gndhi267w89ja67bgfn6zykgvkmmij"
         "node_modules/@deepseek-ai/dsh-experimental-auto-review")
   (list "@deepseek-ai/dsh-experimental-badge-skill-bundle" "0.2.1-rc.2"
         "0simid8bwf2ghm2kxpcw94rh9fzm07mqk3pd9i1qgs4nac6h1mvm"
         "node_modules/@deepseek-ai/dsh-experimental-badge-skill-bundle")
   (list "@deepseek-ai/dsh-experimental-client-ui-agent-team" "0.2.1-rc.2"
         "0k85qyw8hrynmqaybdqvp4mbafnaf2yr19hwskd3h9hmf50kk5z1"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-agent-team")
   (list "@deepseek-ai/dsh-experimental-client-ui-cot-translation" "0.2.1-rc.2"
         "1ip3vn28i80swqkkwxnph02lb3pmmhnja0v1n1qfcj6rmxdngghl"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-cot-translation")
   (list "@deepseek-ai/dsh-experimental-client-ui-voice-input" "0.2.1-rc.2"
         "00zwyg4kc06njq4ra4b3w1474px7rqc06hmnnkxvf4jm5ys0sizj"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-voice-input")
   (list "@deepseek-ai/dsh-experimental-cot-translation-bundle" "0.2.1-rc.2"
         "1zbqn7mxpfsfr50689mj26zyxvjdkiajl0ggyy6xk599rmjy62p2"
         "node_modules/@deepseek-ai/dsh-experimental-cot-translation-bundle")
   (list "@deepseek-ai/dsh-experimental-inspector" "0.2.1-rc.2"
         "1jfspwv4icwdnibd8apsmnxyv7wglcs4wsckr4hgq41ildczgaj0"
         "node_modules/@deepseek-ai/dsh-experimental-inspector")
   (list "@deepseek-ai/dsh-experimental-inspector-profile" "0.2.1-rc.2"
         "1brjk1r04id5yr2m35n2218ilicq44lqbzn8hwkzbkv7p5smfddz"
         "node_modules/@deepseek-ai/dsh-experimental-inspector-profile")
   (list "@deepseek-ai/dsh-experimental-plugin-market-bundle" "0.2.1-rc.2"
         "1nx7syi66i3ngvvfq1kcxz4psbxgpq952qxscmaas58rpvjkiavz"
         "node_modules/@deepseek-ai/dsh-experimental-plugin-market-bundle")
   (list "@deepseek-ai/dsh-experimental-ralph-bundle" "0.2.1-rc.2"
         "1rqvbcpp5znrlidjk3ss5nbf8a6p0h1asw9sv0z9qbx51d31vf79"
         "node_modules/@deepseek-ai/dsh-experimental-ralph-bundle")
   (list "@deepseek-ai/dsh-experimental-session-inspector" "0.2.1-rc.2"
         "0adwb5zvxdr4y27vkyi0jq4196nwp8qr9w0anyv5v7wvqyzpn76m"
         "node_modules/@deepseek-ai/dsh-experimental-session-inspector")
   (list "@deepseek-ai/dsh-experimental-session-search" "0.2.1-rc.2"
         "0i0i46bqnnsklm0i2wni3kz06qxix6lxsxqmk65ni80grfjxls2c"
         "node_modules/@deepseek-ai/dsh-experimental-session-search")
   (list "@deepseek-ai/dsh-experimental-session-titles-bundle" "0.2.1-rc.2"
         "09jbfyigr0199067kkhv2x72vz9br3qj6sx8fri2dhcrlrc0vp92"
         "node_modules/@deepseek-ai/dsh-experimental-session-titles-bundle")
   (list "@deepseek-ai/dsh-experimental-speech-to-text" "0.2.1-rc.2"
         "0gad60rifvm2f8shdws93kiz20gk7ckqf3drixb3ig95vivwhz2j"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text")
   (list "@deepseek-ai/dsh-experimental-speech-to-text-sensevoice" "0.2.1-rc.2"
         "0ywl6i4d79k3dw4vpdyrxi1mvdkgsw482p61c5hnb0r249g63qsy"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text-sensevoice")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text-sensevoice/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-terminal-bundle" "0.2.1-rc.2"
         "16gkml1plg6552zx23j1pvfy4pgxv6jygws23mjan46y2pq597rz"
         "node_modules/@deepseek-ai/dsh-experimental-terminal-bundle")
   (list "@deepseek-ai/dsh-experimental-tool-agent-team" "0.2.1-rc.2"
         "0pv9s9wzwbv3scwdqiwywmvshgakr48akn0pn8rj6kvc4kqvf806"
         "node_modules/@deepseek-ai/dsh-experimental-tool-agent-team")
   (list "@deepseek-ai/dsh-experimental-tool-worktree" "0.2.1-rc.2"
         "0irynaf1p7jjqxzim0ril1npxh52jxbgf3sfk719mjhvmb2246sn"
         "node_modules/@deepseek-ai/dsh-experimental-tool-worktree")
   (list "@deepseek-ai/dsh-experimental-translator" "0.2.1-rc.2"
         "07s5ij9p1jab7xazs40fyg9w8rmwz8r7lgr3zl95r7jli539hs0s"
         "node_modules/@deepseek-ai/dsh-experimental-translator")
   (list "@deepseek-ai/dsh-experimental-voice-input-bundle" "0.2.1-rc.2"
         "1cljcvmwq1n78w0r378dscc7y8yc1z522n1xcb7m86nlp41d48r6"
         "node_modules/@deepseek-ai/dsh-experimental-voice-input-bundle")
   (list "@deepseek-ai/dsh-experimental-worktree" "0.2.1-rc.2"
         "0qm097jy4bmzm0xpmp7ab0az79zxvdkl8vvhz3gsfaakw2ag8brm"
         "node_modules/@deepseek-ai/dsh-experimental-worktree")
   (list "@deepseek-ai/dsh-file-reference" "0.2.1-rc.2"
         "10c0f3lgmmjk9j2idnwhq28w5mq11ynvjvxld9nx4aw3q6sbl5kq"
         "node_modules/@deepseek-ai/dsh-file-reference")
   (list "@deepseek-ai/dsh-file-reference-local" "0.2.1-rc.2"
         "0iq50vfv5qv1fsz49g9pmxigiqzpxs6rmd5xzxwcarvh7530s5nb"
         "node_modules/@deepseek-ai/dsh-file-reference-local")
   (list "@deepseek-ai/dsh-fs" "0.2.1-rc.2"
         "0yjp7qfy0shhx9k9g443f8bvf7bnljxp863k9grf3kjr9nbfc4pk"
         "node_modules/@deepseek-ai/dsh-fs")
   (list "@deepseek-ai/dsh-fs-local" "0.2.1-rc.2"
         "1m2slf71pb765fnlxi270xp6pp755bl9081w0bnmaxrpwaghlw35"
         "node_modules/@deepseek-ai/dsh-fs-local")
   (list "@deepseek-ai/dsh-fs-observation-policy" "0.2.1-rc.2"
         "0vw7gqlh5pyj9xchph894617cvcc21ymd2cgy6vsdc9qdgi5p7id"
         "node_modules/@deepseek-ai/dsh-fs-observation-policy")
   (list "@deepseek-ai/dsh-fs-sandbox" "0.2.1-rc.2"
         "099k72kvn92lvfh9hp2mkjgccynam120fbzyf9njcik8w18hl59g"
         "node_modules/@deepseek-ai/dsh-fs-sandbox")
   (list "@deepseek-ai/dsh-goal" "0.2.1-rc.2"
         "05v31m2az2hsyaax4bb15y6bsl5fi2wj2w3srr1mzhn33ijfsj2y"
         "node_modules/@deepseek-ai/dsh-goal")
   (list "@deepseek-ai/dsh-goal-round-driver" "0.2.1-rc.2"
         "0ppvrw7v3835amkbw2wnf2g5c0livr2kl2ncz9rf0f80qjwhgr3z"
         "node_modules/@deepseek-ai/dsh-goal-round-driver")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-goal/node_modules/zod")
   (list "@deepseek-ai/dsh-harness-dev-context" "0.2.1-rc.2"
         "19lkq911qhq9c2q6qf4wgynapkk7r3qw2bid8qwa9sfp8nf6drj9"
         "node_modules/@deepseek-ai/dsh-harness-dev-context")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-harness-dev-context/node_modules/zod")
   (list "@deepseek-ai/dsh-headless" "0.2.1-rc.2"
         "19djzi1h1al1ghbfcqij0bx7bqg9kx1a9sq64lcyvx65samii8ly"
         "node_modules/@deepseek-ai/dsh-headless")
   (list "@deepseek-ai/dsh-hmr" "0.2.1-rc.2"
         "11dx24nzsg4944lk4cwdhyxy3hk749hg4b9fmm6blhsfzinrvin5"
         "node_modules/@deepseek-ai/dsh-hmr")
   (list "@deepseek-ai/dsh-home-paths" "0.2.1-rc.2"
         "0vxsgxfy77ccxdzia6si4pacq8cv4a8xr5ikfssfdxyz5jpi4qyj"
         "node_modules/@deepseek-ai/dsh-home-paths")
   (list "@deepseek-ai/dsh-host-directory-picker" "0.2.1-rc.2"
         "1p1gwq12vnc5bz0hv04majr25r3iw4aljvcikv1g08nrwdlyj22s"
         "node_modules/@deepseek-ai/dsh-host-directory-picker")
   (list "@deepseek-ai/dsh-host-directory-picker-auto" "0.2.1-rc.2"
         "165xxnxq3y7q04rqfi02wdgbjbhn38ps27japdsvpcp1y1cpa5zk"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-auto")
   (list "@deepseek-ai/dsh-host-directory-picker-browse" "0.2.1-rc.2"
         "1cr9bjvl9ca5y7q0az38a9va5afkhbzcq7n30d3pzj2373ws944j"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-browse")
   (list "@deepseek-ai/dsh-host-directory-picker-native" "0.2.1-rc.2"
         "078l9r9rcnjpwfa2lfzmxwnq6xdq0ip8m8wa8j00wqrwyx05qm0f"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-native")
   (list "@deepseek-ai/dsh-host-frontend-static" "0.2.1-rc.2"
         "1schn6ga274qwc2g2yi880cqggdp8axk8vcrlllfcs4677jk7fsm"
         "node_modules/@deepseek-ai/dsh-host-frontend-static")
   (list "@deepseek-ai/dsh-host-open-in-app" "0.2.1-rc.2"
         "18ppr7lcccf2v7ld5vnp436fjwm70ifng7k5rcvmq1pfhqcc66bg"
         "node_modules/@deepseek-ai/dsh-host-open-in-app")
   (list "@deepseek-ai/dsh-host-plugin-inventory" "0.2.1-rc.2"
         "19m5x4203hnzaipfrbsn309682536nnadmjgpr7lsfhqkri8d2k2"
         "node_modules/@deepseek-ai/dsh-host-plugin-inventory")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-host-plugin-inventory/node_modules/zod")
   (list "@deepseek-ai/dsh-host-product-telemetry-otel" "0.2.1-rc.2"
         "178nz428gxis9jqp6f8kscxmacklgk0xlx9gwhhf7ml1gkdpyl70"
         "node_modules/@deepseek-ai/dsh-host-product-telemetry-otel")
   (list "@deepseek-ai/dsh-host-webserver" "0.2.1-rc.2"
         "0wpqfg6mv2gnxci9zhms1kzg3fffg79nbmy3ag4m7k47i14d4n7y"
         "node_modules/@deepseek-ai/dsh-host-webserver")
   (list "@deepseek-ai/dsh-http-proxy" "0.2.1-rc.2"
         "0hk8x8yi4xshcvd7xlq51677czqbl8ixckcyl27rn2zadad34rbj"
         "node_modules/@deepseek-ai/dsh-http-proxy")
   (list "@deepseek-ai/dsh-jobs" "0.2.1-rc.2"
         "1ngv2vx93nnpzpqnjlflyqq57xp4xplnpl3as4cmaj4yh7c4baxb"
         "node_modules/@deepseek-ai/dsh-jobs")
   (list "@deepseek-ai/dsh-jobs-local" "0.2.1-rc.2"
         "17y4wsfs0i87rrb1cm01izrr9mql9hwcc8qzqxc96aspwb2g96n9"
         "node_modules/@deepseek-ai/dsh-jobs-local")
   (list "@deepseek-ai/dsh-launch-environment" "0.2.1-rc.2"
         "077xnw0p197m22l8xpvmlaz08isn5jf6n99dfm09v2m4rf067y7p"
         "node_modules/@deepseek-ai/dsh-launch-environment")
   (list "@deepseek-ai/dsh-lazy-require" "0.2.1-rc.2"
         "1k8105q85cmr1rxbcxydlhyy64yyyqg26vww5zy8f03fcf4b4nv1"
         "node_modules/@deepseek-ai/dsh-lazy-require")
   (list "@deepseek-ai/dsh-llm" "0.2.1-rc.2"
         "1fmqlbysmy4mx1b45x3g8yg3z18m2wx2003wlb3if245rx8mpr00"
         "node_modules/@deepseek-ai/dsh-llm")
   (list "@deepseek-ai/dsh-llm-deepseek" "0.2.1-rc.2"
         "1zryck7388kypnfmnvp636jsw3nvl4fpq4d01bkvgjy5lj5b3d75"
         "node_modules/@deepseek-ai/dsh-llm-deepseek")
   (list "@deepseek-ai/dsh-llm-deepseek-account" "0.2.1-rc.2"
         "02yvq5227a1q94d84giyki0glrkph74xgiczr2g76qbj3fhskdw2"
         "node_modules/@deepseek-ai/dsh-llm-deepseek-account")
   (list "@deepseek-ai/dsh-llm-deepseek-api-key" "0.2.1-rc.2"
         "1w0735da2nl1csgzyrw1pjz7bdkmcy56yd2a8gf4hgcmp2lsqwb6"
         "node_modules/@deepseek-ai/dsh-llm-deepseek-api-key")
   (list "@deepseek-ai/dsh-llm-pi-ai" "0.2.1-rc.2"
         "0i6d22vhs34m2jk2q3nrm9y03i51ndbm65ap3kh6frxjqhwy1isn"
         "node_modules/@deepseek-ai/dsh-llm-pi-ai")
   (list "@deepseek-ai/dsh-llm-retry" "0.2.1-rc.2"
         "091pyg7ymi9jj4qmza7dz4plly479hvbxblri2xnrx67sldzmzwg"
         "node_modules/@deepseek-ai/dsh-llm-retry")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-llm-retry/node_modules/zod")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-llm/node_modules/zod")
   (list "@deepseek-ai/dsh-mcp-client" "0.2.1-rc.2"
         "11vxza88gc7sr45qy4lqg1lkzkg53xax0dwyr71nky32psrr2w0d"
         "node_modules/@deepseek-ai/dsh-mcp-client")
   (list "@deepseek-ai/dsh-mcp-resources" "0.2.1-rc.2"
         "0wns63vxcs8n5m0sgii970qk7b09ii4vgq6aib2dnqh7mby308k8"
         "node_modules/@deepseek-ai/dsh-mcp-resources")
   (list "@deepseek-ai/dsh-message-feedback" "0.2.1-rc.2"
         "0k29falmh9nskdzrjn4sspd1j9gqs89fmskla2775028w7yrhibw"
         "node_modules/@deepseek-ai/dsh-message-feedback")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-message-feedback/node_modules/zod")
   (list "@deepseek-ai/dsh-native-command" "0.2.1-rc.2"
         "0la07vz4m5xhwwm1k3rb87ya9lmnpa9kfsbhg98l09fi2kkhwiw0"
         "node_modules/@deepseek-ai/dsh-native-command")
   (list "@deepseek-ai/dsh-office-to-pdf" "0.2.1-rc.2"
         "150prf19hvbwmf76k3xmhwqix0k9brlndzwn1zqkfaixwjwbvbvr"
         "node_modules/@deepseek-ai/dsh-office-to-pdf")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-office-to-pdf/node_modules/zod")
   (list "@deepseek-ai/dsh-otel" "0.2.1-rc.2"
         "10vaki6khms44fzmqif9bmwwk719ph6ncpi1p7853irwj5jrr07s"
         "node_modules/@deepseek-ai/dsh-otel")
   (list "@deepseek-ai/dsh-output-retention" "0.2.1-rc.2"
         "19a3s042y00a8x33xgykklqci8i4d3k7zcry3qg2xjxrq5hkndai"
         "node_modules/@deepseek-ai/dsh-output-retention")
   (list "@deepseek-ai/dsh-package-manifest" "0.2.1-rc.2"
         "1j5xw8fv8ldddmv3ymps57lmbggy13l9qjr0lx65a73n453s04i5"
         "node_modules/@deepseek-ai/dsh-package-manifest")
   (list "@deepseek-ai/dsh-permission-presets" "0.2.1-rc.2"
         "01zbxzcqk2ylhqq0nld02l8achffcc501rwwd93amjll204ja528"
         "node_modules/@deepseek-ai/dsh-permission-presets")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-permission-presets/node_modules/zod")
   (list "@deepseek-ai/dsh-persona" "0.2.1-rc.2"
         "1w3g00i6vzlbrcs9001hblp85yr1s9dl8gbcxqbkvxgz4x0rjbj9"
         "node_modules/@deepseek-ai/dsh-persona")
   (list "@deepseek-ai/dsh-plan-mode" "0.2.1-rc.2"
         "1i0bqhjwp38wszvnszgv014dw5qk9q12h9y6xzc4z1k8xd3i3888"
         "node_modules/@deepseek-ai/dsh-plan-mode")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-plan-mode/node_modules/zod")
   (list "@deepseek-ai/dsh-plugin-manager" "0.2.1-rc.2"
         "1cybmjqphy7wy4n34vn0hkd9pzf85sdrcj8lzpl6ag86s9gi100g"
         "node_modules/@deepseek-ai/dsh-plugin-manager")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-plugin-manager/node_modules/zod")
   (list "@deepseek-ai/dsh-plugin-market" "0.2.1-rc.2"
         "0kcgkd6ayv1p25d703imlz2g3b3flwgq7srwn1xyrj3zfxfldnvd"
         "node_modules/@deepseek-ai/dsh-plugin-market")
   (list "@deepseek-ai/dsh-plugin-market-index" "0.2.1-rc.2"
         "0vcrrjdbrn9ma4m17w8n4p71s9b3ip91jqzsldh8m37krq8i8159"
         "node_modules/@deepseek-ai/dsh-plugin-market-index")
   (list "@deepseek-ai/dsh-plugin-package-inventory-deepseek" "0.2.1-rc.2"
         "05nnnp2cb6h6g9bp06zz4bp6nipb61jj1kdl2j7pxj7d5bn9aslb"
         "node_modules/@deepseek-ai/dsh-plugin-package-inventory-deepseek")
   (list "@deepseek-ai/dsh-ptc-runtime" "0.2.1-rc.2"
         "093xi0nm2jl6r7mgqr3pqdb8vnzgzcp7afrcnysffwiqr28w54ig"
         "node_modules/@deepseek-ai/dsh-ptc-runtime")
   (list "@deepseek-ai/dsh-ptc-runtime-node" "0.2.1-rc.2"
         "1jq4pi38j4cnjsd4ych6y05fjkzjk2a8z261nwv4hhqyvdbgxm2s"
         "node_modules/@deepseek-ai/dsh-ptc-runtime-node")
   (list "@deepseek-ai/dsh-pwsh-local" "0.2.1-rc.2"
         "0xwd2hi993fi60f234vw9mj4mw8m1a5a3kszn7x6g4y6nxvipwvg"
         "node_modules/@deepseek-ai/dsh-pwsh-local")
   (list "@deepseek-ai/dsh-pwsh-sandbox" "0.2.1-rc.2"
         "0925xh79xrnqryn309zbcvcvvkw1r929ncr70qqs2pv85j3289k6"
         "node_modules/@deepseek-ai/dsh-pwsh-sandbox")
   (list "@deepseek-ai/dsh-repeat-tool-reminder" "0.2.1-rc.2"
         "1g5hf03vzziin4n50lswp074cp2ybn72rnv270l70szdsgji1h8w"
         "node_modules/@deepseek-ai/dsh-repeat-tool-reminder")
   (list "@deepseek-ai/dsh-sandbox" "0.2.1-rc.2"
         "1k69wjf7x3wf2cb11w12xhg46ysqs6lammwqrkxy8cf1m16lc0j3"
         "node_modules/@deepseek-ai/dsh-sandbox")
   (list "@deepseek-ai/dsh-sandbox-local" "0.2.1-rc.2"
         "141x4vdb3y8fnqr1icd3w783h3g3hwy9ag5ffy7fapfjh9fs76j8"
         "node_modules/@deepseek-ai/dsh-sandbox-local")
   (list "@deepseek-ai/dsh-sandbox-policy" "0.2.1-rc.2"
         "1yj46wjghwg8b29fz6k8y3bwnbk9ajpxw5ln2a8zy70szpp9sn23"
         "node_modules/@deepseek-ai/dsh-sandbox-policy")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-sandbox-policy/node_modules/zod")
   (list "@deepseek-ai/dsh-sandbox-windows-acl" "0.2.1-rc.2"
         "1dfq5ax8phyjiqxh4sjl9d0x13mkgbxk1iswy78i9spkg7mr7vr8"
         "node_modules/@deepseek-ai/dsh-sandbox-windows-acl")
   (list "@deepseek-ai/dsh-schedule" "0.2.1-rc.2"
         "18bnd0qgpscvfsvc5s0hg7amar08g6kmj4bi3maqaw7nay9vhjbn"
         "node_modules/@deepseek-ai/dsh-schedule")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-schedule/node_modules/zod")
   (list "@deepseek-ai/dsh-scope" "0.2.1-rc.2"
         "1sbwsmz2dai0123qvbvhw071jpshikwghdglx0xqpky09lmn0vyg"
         "node_modules/@deepseek-ai/dsh-scope")
   (list "@deepseek-ai/dsh-sdk-app" "0.2.1-rc.2"
         "1z20pjjlymx55ivp6s416s0imgwnwxrbgw2cclv2njnvifcc9z99"
         "node_modules/@deepseek-ai/dsh-sdk-app")
   (list "@deepseek-ai/dsh-sdk-jsonrpc-server" "0.2.1-rc.2"
         "06r41a6c9r5lm32zv21i6xv23jnpjv3pwq0l9j6yri9ynhnn8wxj"
         "node_modules/@deepseek-ai/dsh-sdk-jsonrpc-server")
   (list "@deepseek-ai/dsh-sdk-minimal" "0.2.1-rc.2"
         "1v7xsc7b14zhzmhmrvricnzcd4cmq2k0hb9f7f560f02968lad64"
         "node_modules/@deepseek-ai/dsh-sdk-minimal")
   (list "@deepseek-ai/dsh-sdk-protocol" "0.2.1-rc.2"
         "0ni3anr2yj8024an5ml9ssxqqzkpw5qrxhby841z57wgmc4xwmgr"
         "node_modules/@deepseek-ai/dsh-sdk-protocol")
   (list "@deepseek-ai/dsh-session" "0.2.1-rc.2"
         "1rr508zdfan1rnxagc0dlp5mdzj04rs2gm9sjafggq90w7jkidbj"
         "node_modules/@deepseek-ai/dsh-session")
   (list "@deepseek-ai/dsh-session-checkpoint-policy" "0.2.1-rc.2"
         "1mqmybcmxwsybv8992x81d71gnjiqk5z77ggdayw7zjbjllyy7p5"
         "node_modules/@deepseek-ai/dsh-session-checkpoint-policy")
   (list "@deepseek-ai/dsh-session-format" "0.2.1-rc.2"
         "0hksxlzsm52521h1qsqmsvbmblq8maj8xm5329xvcq5ivz6rpk0m"
         "node_modules/@deepseek-ai/dsh-session-format")
   (list "@deepseek-ai/dsh-session-format-catalog" "0.2.1-rc.2"
         "07glpq1gw1bd2jh27zjnxwp4why7vs7gz6p9jlfhr0rr0snmxnib"
         "node_modules/@deepseek-ai/dsh-session-format-catalog")
   (list "@deepseek-ai/dsh-session-format-v0-to-v1" "0.2.1-rc.2"
         "1h9568b6vwh119nlyq0sw28sk494ipyjj4lsj49hlq3j5qzb8aai"
         "node_modules/@deepseek-ai/dsh-session-format-v0-to-v1")
   (list "@deepseek-ai/dsh-session-format-v1-to-v2" "0.2.1-rc.2"
         "108nfhl6fz12siqjvw41ccl6aq77rq72ydzjsh9wwkjbrq17r7cm"
         "node_modules/@deepseek-ai/dsh-session-format-v1-to-v2")
   (list "@deepseek-ai/dsh-session-format-v2-to-v3" "0.2.1-rc.2"
         "17p7cvz18p47pxhd497pz1c7v33znbls8zzcfm2ch3hba3qxnwdb"
         "node_modules/@deepseek-ai/dsh-session-format-v2-to-v3")
   (list "@deepseek-ai/dsh-session-format-v3-to-v4" "0.2.1-rc.2"
         "0fgq283iq9kqna1hnah5ncrhb09dqzf7sasqqn2a8hvbl9q9xbq3"
         "node_modules/@deepseek-ai/dsh-session-format-v3-to-v4")
   (list "@deepseek-ai/dsh-session-log-deepseek" "0.2.1-rc.2"
         "0yc57d6yh3j92nllsp5hb5qsrmv20gff8n29nkyif826zml7mrbk"
         "node_modules/@deepseek-ai/dsh-session-log-deepseek")
   (list "@deepseek-ai/dsh-session-log-export" "0.2.1-rc.2"
         "1dfpr3b5rz42y4kryylb9ij4wk9zbmpjq29dn1vdhv070nyiqgl2"
         "node_modules/@deepseek-ai/dsh-session-log-export")
   (list "@deepseek-ai/dsh-session-persistence" "0.2.1-rc.2"
         "1c39krf0pqkdrkfmhml9skhx3ljcxjxiqa4chz88n61kf0nqy4vl"
         "node_modules/@deepseek-ai/dsh-session-persistence")
   (list "@deepseek-ai/dsh-session-persistence-jsonl" "0.2.1-rc.2"
         "0c1kmfmw98a4h0rd270hv0y8839blw4jspmd3cvbhl36qnzi6lmd"
         "node_modules/@deepseek-ai/dsh-session-persistence-jsonl")
   (list "@deepseek-ai/dsh-session-projection" "0.2.1-rc.2"
         "1milqp1akhd63ahdqzn2hcvn09vnhikivf38abqhcycglfsvjs3d"
         "node_modules/@deepseek-ai/dsh-session-projection")
   (list "@deepseek-ai/dsh-session-projection-cache" "0.2.1-rc.2"
         "1sk88npg7hxdw39qg3mklkbyk4x3p6imcakqkzz5jxf9idqsihjy"
         "node_modules/@deepseek-ai/dsh-session-projection-cache")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-projection-cache/node_modules/zod")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-projection/node_modules/zod")
   (list "@deepseek-ai/dsh-session-query" "0.2.1-rc.2"
         "057i3v5d93lq2hl5yzic8f4f6kpmc8qhah5yaxg7g6l3hprcyk2x"
         "node_modules/@deepseek-ai/dsh-session-query")
   (list "@deepseek-ai/dsh-session-query-sqlite" "0.2.1-rc.2"
         "0d14br3bsjny5sabidiiszfaz0gi2fj3597f63ddjhfml67hwdzn"
         "node_modules/@deepseek-ai/dsh-session-query-sqlite")
   (list "@deepseek-ai/dsh-session-reference" "0.2.1-rc.2"
         "0asnqyrp2p17wq3yl5sfl2z3a9r0p2fnwh5hk5pd70sjw05ydbk6"
         "node_modules/@deepseek-ai/dsh-session-reference")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-reference/node_modules/zod")
   (list "@deepseek-ai/dsh-session-stats" "0.2.1-rc.2"
         "0cjz0yf8mifd6pknyzp3vaz6dlaxrxwxq6w1y3j66wgqjgwm4hwf"
         "node_modules/@deepseek-ai/dsh-session-stats")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-stats/node_modules/zod")
   (list "@deepseek-ai/dsh-session-telemetry" "0.2.1-rc.2"
         "1kirjnkqspn5dpmhxxxc50m4989qjgs72g2jfcha0blac9ydcpac"
         "node_modules/@deepseek-ai/dsh-session-telemetry")
   (list "@deepseek-ai/dsh-session-telemetry-otel" "0.2.1-rc.2"
         "035wk716k3kbi9ibwwpl5n2mbmwzy9ma1g72lww1fhj13xpsfdbr"
         "node_modules/@deepseek-ai/dsh-session-telemetry-otel")
   (list "@deepseek-ai/dsh-session-title" "0.2.1-rc.2"
         "13h8zdh8jxr6yhc9yw2j7vw2iai1rsz3spzp3l082fhpj8ki5s83"
         "node_modules/@deepseek-ai/dsh-session-title")
   (list "@deepseek-ai/dsh-session-title-all-prompts-llm" "0.2.1-rc.2"
         "0iya7wkw30gyay1bbfw4dv11g1064hbsgzwfhqkln1swglq3gvq7"
         "node_modules/@deepseek-ai/dsh-session-title-all-prompts-llm")
   (list "@deepseek-ai/dsh-session-title-first-prompt-llm" "0.2.1-rc.2"
         "03i91srsc6rh63s8x10j81waxbr0cnzp78ghw6v1jaid119a9j9y"
         "node_modules/@deepseek-ai/dsh-session-title-first-prompt-llm")
   (list "@deepseek-ai/dsh-session-title-llm" "0.2.1-rc.2"
         "0y6kww5641bnh153hqrkyyzpn8n367x9fpbipcz37n1dy1qwa8qh"
         "node_modules/@deepseek-ai/dsh-session-title-llm")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-title/node_modules/zod")
   (list "@deepseek-ai/dsh-session-turn-outline" "0.2.1-rc.2"
         "08vv4jjnhvk1d64yswkzc0y0isw14kx80jaal8zgi218ghd3smcs"
         "node_modules/@deepseek-ai/dsh-session-turn-outline")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-turn-outline/node_modules/zod")
   (list "@deepseek-ai/dsh-settings" "0.2.1-rc.2"
         "16h9wdvn14h45hwv6f28js67hpss5cbn11p5ab4w3v3r534q6qiy"
         "node_modules/@deepseek-ai/dsh-settings")
   (list "@deepseek-ai/dsh-shell" "0.2.1-rc.2"
         "0g4pmz15i7x2n1a8avccb6wkkrm3x65xnhmm5pbm5szv61zmh8p3"
         "node_modules/@deepseek-ai/dsh-shell")
   (list "@deepseek-ai/dsh-shell-env" "0.2.1-rc.2"
         "0n8kyismcwxdkw41gs3f5nf2xxlffn3xaiksdc2qxj91vf7ifw3y"
         "node_modules/@deepseek-ai/dsh-shell-env")
   (list "@deepseek-ai/dsh-skill" "0.2.1-rc.2"
         "07fqd9crszxgsp5m49rndlmfzkyiic9yjikzxln60vq2vd01qw7h"
         "node_modules/@deepseek-ai/dsh-skill")
   (list "@deepseek-ai/dsh-skill-badge" "0.2.1-rc.2"
         "0jcxlcryalh0a2ig91mcwga616rrxlwk5fssqcpgq444hy8k5lx7"
         "node_modules/@deepseek-ai/dsh-skill-badge")
   (list "@deepseek-ai/dsh-skill-filesystem" "0.2.1-rc.2"
         "0q7z4yk545rrc1ar8bi1wv9pcjxif4ya4wif6xh928a2lq3ghvqh"
         "node_modules/@deepseek-ai/dsh-skill-filesystem")
   (list "@deepseek-ai/dsh-skill-office" "0.2.1-rc.2"
         "1ylvlzxqy9l3pf4brc81b07dv0z48x1q9qi1ylsyfck8mmgw73pn"
         "node_modules/@deepseek-ai/dsh-skill-office")
   (list "@deepseek-ai/dsh-spill" "0.2.1-rc.2"
         "0dir54xcgpmn49zns94f5bzhl7gh0i5lh370w6ay5ib2yq33d3kh"
         "node_modules/@deepseek-ai/dsh-spill")
   (list "@deepseek-ai/dsh-spill-local" "0.2.1-rc.2"
         "16c7avic8pwhlh711xgywv7d2bfh3lygkzwmjxcnbhqw8vcay190"
         "node_modules/@deepseek-ai/dsh-spill-local")
   (list "@deepseek-ai/dsh-spill-policy" "0.2.1-rc.2"
         "1pdb2ql8hvjdkw4xkq4f59cbdi139nmnspvxzq92q9z79ih45hfm"
         "node_modules/@deepseek-ai/dsh-spill-policy")
   (list "@deepseek-ai/dsh-storage" "0.2.1-rc.2"
         "0syfn5zd88nb6f1vqqd0sc2sk69cv2kn0pqq5gyw4wriikszx179"
         "node_modules/@deepseek-ai/dsh-storage")
   (list "@deepseek-ai/dsh-storage-domain" "0.2.1-rc.2"
         "1fg23g6m224zhzv0viirkdif5c6z40hm0z4dqwv805qwkgh9w1ip"
         "node_modules/@deepseek-ai/dsh-storage-domain")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-storage-domain/node_modules/zod")
   (list "@deepseek-ai/dsh-storage-json" "0.2.1-rc.2"
         "11j3bnin1id3ag62q3azazjfd5k4ba43k8xgspz1vr56vjq5b9cd"
         "node_modules/@deepseek-ai/dsh-storage-json")
   (list "@deepseek-ai/dsh-subagent" "0.2.1-rc.2"
         "1mi70fr2wk6gsr9r40wxzplpz936jw5bhpq98y5d7wkw4v4289fs"
         "node_modules/@deepseek-ai/dsh-subagent")
   (list "@deepseek-ai/dsh-subagent-fork-in-process" "0.2.1-rc.2"
         "03flhc929ay3h0wdvp18mr23z63yg26whi60852fz45yna5wjzjh"
         "node_modules/@deepseek-ai/dsh-subagent-fork-in-process")
   (list "@deepseek-ai/dsh-subagent-spawn-in-process" "0.2.1-rc.2"
         "1xa1ya77c6hdh7y5zjfl0b39znm056zqp8mh7pqix1lpzvqi7hcb"
         "node_modules/@deepseek-ai/dsh-subagent-spawn-in-process")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-subagent/node_modules/zod")
   (list "@deepseek-ai/dsh-subprocess" "0.2.1-rc.2"
         "11s2n55f1drrjn8xzzb76yaa0hbkpv4x6li0nhkclibycl8yf6za"
         "node_modules/@deepseek-ai/dsh-subprocess")
   (list "@deepseek-ai/dsh-subprocess-local" "0.2.1-rc.2"
         "1y9c84w1lngnck7b3kf5ksys7lihysrk5kmhmf8rxrgp92w1svhx"
         "node_modules/@deepseek-ai/dsh-subprocess-local")
   (list "@deepseek-ai/dsh-system-prompt" "0.2.1-rc.2"
         "0v90csbf8vxf90d3hac997kpp58h35js1lc4dbqw60dqh8sib1ni"
         "node_modules/@deepseek-ai/dsh-system-prompt")
   (list "@deepseek-ai/dsh-terminal" "0.2.1-rc.2"
         "0j7bj5m4jjbpl1qyakhyv8v0v8ajx27rrmk2rlsl6k2pz0jpil2r"
         "node_modules/@deepseek-ai/dsh-terminal")
   (list "@deepseek-ai/dsh-terminal-bash" "0.2.1-rc.2"
         "00lcawhvaj77giawjpsg6d1kjb53q18zfqj6081dqznh96jaakai"
         "node_modules/@deepseek-ai/dsh-terminal-bash")
   (list "@deepseek-ai/dsh-time-context" "0.2.1-rc.2"
         "01lqb70b4bqz5kv3ll6ni1sdy6dx7nwbkmpk5dm3gjrrm8js29fi"
         "node_modules/@deepseek-ai/dsh-time-context")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-time-context/node_modules/zod")
   (list "@deepseek-ai/dsh-timeout" "0.2.1-rc.2"
         "0ihpvfb8lazinzcybzqvb271vpxfmynm3w0m8mgmvg1z39rc7jzh"
         "node_modules/@deepseek-ai/dsh-timeout")
   (list "@deepseek-ai/dsh-tmux-context" "0.2.1-rc.2"
         "1p0pbbh73qd9ysndk1i3nf63kwj7rim922f3kgv6s6n5as3252xi"
         "node_modules/@deepseek-ai/dsh-tmux-context")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-tmux-context/node_modules/zod")
   (list "@deepseek-ai/dsh-token-meter" "0.2.1-rc.2"
         "0cd0a30zdrfhg1pp2d4acfca7r1zxs532m7ydhjc8zksxvyh94am"
         "node_modules/@deepseek-ai/dsh-token-meter")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-token-meter/node_modules/zod")
   (list "@deepseek-ai/dsh-tool-ask-user" "0.2.1-rc.2"
         "1wszfw2myra0vjssqfifwsz4w439as3ypmh01kindismz1glpawk"
         "node_modules/@deepseek-ai/dsh-tool-ask-user")
   (list "@deepseek-ai/dsh-tool-bash" "0.2.1-rc.2"
         "1xxihxhc0rh2r3dn8qg9qnhrrxvddf2hgmm5f290194s7j9ychmx"
         "node_modules/@deepseek-ai/dsh-tool-bash")
   (list "@deepseek-ai/dsh-tool-bash-persistent" "0.2.1-rc.2"
         "1mab317qybirpfcxwq8janl0989p0yl7b98j8cnrja1rsx9bz6g0"
         "node_modules/@deepseek-ai/dsh-tool-bash-persistent")
   (list "@deepseek-ai/dsh-tool-call-timeout-policy" "0.2.1-rc.2"
         "1az1ncskb6lv96x7iw4384y71xw2fgxhnx0h9pg1sc52k5igm0s2"
         "node_modules/@deepseek-ai/dsh-tool-call-timeout-policy")
   (list "@deepseek-ai/dsh-tool-cordis" "0.2.1-rc.2"
         "0jqvhcng1szlnwq0z0jkzcq07x7f8xgx655ywayh5yw1rsz3bja1"
         "node_modules/@deepseek-ai/dsh-tool-cordis")
   (list "@deepseek-ai/dsh-tool-fs" "0.2.1-rc.2"
         "1amag2dkn03m39cizixwhb4m5w0kmavn7ic5xc4bjjgv6rhisgvb"
         "node_modules/@deepseek-ai/dsh-tool-fs")
   (list "@deepseek-ai/dsh-tool-fs-search" "0.2.1-rc.2"
         "0qwqkirv3w11myyg4s3nv0p66zm9yhzq252ljdfj4lsqgc1wm4qd"
         "node_modules/@deepseek-ai/dsh-tool-fs-search")
   (list "@deepseek-ai/dsh-tool-goal" "0.2.1-rc.2"
         "0qm8p2fsvp2q0ggcq5v95b3wr0s7xszwymxs2cq4mkdmxni65xwb"
         "node_modules/@deepseek-ai/dsh-tool-goal")
   (list "@deepseek-ai/dsh-tool-jobs" "0.2.1-rc.2"
         "1nbdy4wlinlpmbh81q8w20l2sm00l2pi7s2bii8wkqvscjdpy8q9"
         "node_modules/@deepseek-ai/dsh-tool-jobs")
   (list "@deepseek-ai/dsh-tool-present" "0.2.1-rc.2"
         "1qjvbik09mzf30lmzdlc23hzjx869hai11ckvwycidy5xklkjyb8"
         "node_modules/@deepseek-ai/dsh-tool-present")
   (list "@deepseek-ai/dsh-tool-pwsh" "0.2.1-rc.2"
         "11zngcdxijbvpjdpgzl4izyn1ypldlbqmiy42vg10gscw89i4cj7"
         "node_modules/@deepseek-ai/dsh-tool-pwsh")
   (list "@deepseek-ai/dsh-tool-pwsh-persistent" "0.2.1-rc.2"
         "0cgaa3xhxhd8h7axwzq2knc4y1rnr22yphg5rc2fgdalady2ng04"
         "node_modules/@deepseek-ai/dsh-tool-pwsh-persistent")
   (list "@deepseek-ai/dsh-tool-ralph" "0.2.1-rc.2"
         "1y15afrcp1yn2w2hs101f3dzszdr90vjjsm0693bynmwza24pbrv"
         "node_modules/@deepseek-ai/dsh-tool-ralph")
   (list "@deepseek-ai/dsh-tool-schedule" "0.2.1-rc.2"
         "1ghfcpv7467km1ailjsmmaaq78xwwgwvlij5mf8l2h0l50dkrh41"
         "node_modules/@deepseek-ai/dsh-tool-schedule")
   (list "@deepseek-ai/dsh-tool-session-query" "0.2.1-rc.2"
         "0ln1ag5xp50qb8yz19hj9lkj75p224h02drwz1lr1lf8j3kipspa"
         "node_modules/@deepseek-ai/dsh-tool-session-query")
   (list "@deepseek-ai/dsh-tool-skill" "0.2.1-rc.2"
         "0zw01ss9wh0yqi0j1gi4hqwsf8j4vbk7d3hg30bwcnmryxa81inf"
         "node_modules/@deepseek-ai/dsh-tool-skill")
   (list "@deepseek-ai/dsh-tool-str-replace-editor" "0.2.1-rc.2"
         "037qbskh5h7jwcwpw5vfx02p3qmgvawhddfwsfywr84jj6azg465"
         "node_modules/@deepseek-ai/dsh-tool-str-replace-editor")
   (list "@deepseek-ai/dsh-tool-subagent" "0.2.1-rc.2"
         "0c6rkccg8pg54h4i3r2ki6dmpdpyawsj6indprd6k9vd49329xmd"
         "node_modules/@deepseek-ai/dsh-tool-subagent")
   (list "@deepseek-ai/dsh-tool-subagent-control" "0.2.1-rc.2"
         "1mjs09ffd3pavkb7gvz6ydg4sfs1955f3zmrb8b37kfgpmx6i9zh"
         "node_modules/@deepseek-ai/dsh-tool-subagent-control")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-tool-subagent/node_modules/zod")
   (list "@deepseek-ai/dsh-tool-terminal" "0.2.1-rc.2"
         "0gjnsnw73qjlgdn4yk6lm0r2qsv4qj13bh60a1li9vqaqx1b86ny"
         "node_modules/@deepseek-ai/dsh-tool-terminal")
   (list "@deepseek-ai/dsh-tool-todo" "0.2.1-rc.2"
         "0k8ls828hmad4asw222amhaqsc9nvvni9gn5xafz241fn1j2mc5g"
         "node_modules/@deepseek-ai/dsh-tool-todo")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-tool-todo/node_modules/zod")
   (list "@deepseek-ai/dsh-tool-web" "0.2.1-rc.2"
         "1sjq44128j642i7kamrayj4figf0jjsqgp3s6g9h3k85vyhs17n4"
         "node_modules/@deepseek-ai/dsh-tool-web")
   (list "@deepseek-ai/dsh-tool-workflow" "0.2.1-rc.2"
         "0fk9k3m0rsjkl6cwcai38hjw9y694dykall4ycnwy29hl9r2kba8"
         "node_modules/@deepseek-ai/dsh-tool-workflow")
   (list "@deepseek-ai/dsh-tool-working-directory" "0.2.1-rc.2"
         "1i28kqq8sgqlqqgd39rykhpkcn74cr3vbzqpkhdnivgbp0bdvj0h"
         "node_modules/@deepseek-ai/dsh-tool-working-directory")
   (list "@deepseek-ai/dsh-tool-workspace-dependencies" "0.2.1-rc.2"
         "13zx2k6x2sj5n4rv2s0p1jvzqwyaz52ca0mas2kvfkbzrkx4w5y6"
         "node_modules/@deepseek-ai/dsh-tool-workspace-dependencies")
   (list "@deepseek-ai/dsh-tools" "0.2.1-rc.2"
         "0f07jqsn1m2135qg6bbafvijky038l6wqj65y26ifh05065fxphv"
         "node_modules/@deepseek-ai/dsh-tools")
   (list "@deepseek-ai/dsh-typert-loader" "0.2.1-rc.2"
         "1vfnaw76qblh53bpyxy7l88j79i8h196vhx8i8hwjpj6q494g1xh"
         "node_modules/@deepseek-ai/dsh-typert-loader")
   (list "@deepseek-ai/dsh-typert-protocol" "0.2.1-rc.2"
         "058hl7pbw7p0i3jgwdih58c17dak0pf8p12r1s0pssgyhpzs1if3"
         "node_modules/@deepseek-ai/dsh-typert-protocol")
   (list "@deepseek-ai/dsh-typert-registry" "0.2.1-rc.2"
         "1cjjb96yyhykvfm1j8wrhn3rnhihxkp4sircrlv121v6dghb5z4g"
         "node_modules/@deepseek-ai/dsh-typert-registry")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-typert-registry/node_modules/zod")
   (list "@deepseek-ai/dsh-user-approval" "0.2.1-rc.2"
         "1s3vzxizcg38xmxrjwsa489hldh4332p3h14kbnz8iy29pyy5a08"
         "node_modules/@deepseek-ai/dsh-user-approval")
   (list "@deepseek-ai/dsh-user-questions" "0.2.1-rc.2"
         "0sdb0bfjv2r14kw9k67jpglcqmg4mbqyddc7ckajlhdkw6xll6gm"
         "node_modules/@deepseek-ai/dsh-user-questions")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-user-questions/node_modules/zod")
   (list "@deepseek-ai/dsh-util-code-language" "0.2.1-rc.2"
         "0wag5shs3bwz9ywmwp7jni95h987yaaw3j0is7iczd2kv1kh03m6"
         "node_modules/@deepseek-ai/dsh-util-code-language")
   (list "@deepseek-ai/dsh-util-crypto" "0.2.1-rc.2"
         "15816rc6vnw226gypvxv0alfwcapdlvzhj4xil8j7m2pyymi0drk"
         "node_modules/@deepseek-ai/dsh-util-crypto")
   (list "@deepseek-ai/dsh-util-time" "0.2.1-rc.2"
         "0cz25s8rii7y91kzd6nf7m8z79437lj0hhslvj0zrxvvgqzjjxhs"
         "node_modules/@deepseek-ai/dsh-util-time")
   (list "@deepseek-ai/dsh-util-values" "0.2.1-rc.2"
         "1js0wx2jwgj7wm9ikjf5vmmxcg3nkd42hapqaw5a9lwwmr73l9rb"
         "node_modules/@deepseek-ai/dsh-util-values")
   (list "@deepseek-ai/dsh-util-workspace-path" "0.2.1-rc.2"
         "00hn4c6z8fhcm3sav5wmg50kf2lk4994rh0052fgwn9lwb5hvvbg"
         "node_modules/@deepseek-ai/dsh-util-workspace-path")
   (list "@deepseek-ai/dsh-web" "0.2.1-rc.2"
         "0f5grlpb9pacnnwgvijz50xzsh07gn39dn6xhz7mlmidg5xg01yh"
         "node_modules/@deepseek-ai/dsh-web")
   (list "@deepseek-ai/dsh-web-app" "0.2.1-rc.2"
         "1p1kq6p540lnm22q0zcvpcay0gm8glhh7vjhhgnyrsi77d779883"
         "node_modules/@deepseek-ai/dsh-web-app")
   (list "@deepseek-ai/dsh-web-deepseek-api" "0.2.1-rc.2"
         "0y2j2kqicf4n1m7qd08vh0319ciqs1pdbqrb8zbczamszng4f4pr"
         "node_modules/@deepseek-ai/dsh-web-deepseek-api")
   (list "@deepseek-ai/dsh-web-fetch-http" "0.2.1-rc.2"
         "1h0fs73cnh34ls5vs91qycjjiz5rl39knzkbkm2kvcy7ya9ahq8f"
         "node_modules/@deepseek-ai/dsh-web-fetch-http")
   (list "@deepseek-ai/dsh-web-frontend" "0.2.1-rc.2"
         "15vxcp2bxv81fg6aqji5i1vrxy5kprm54cgc1iww8q4fxw43yfcy"
         "node_modules/@deepseek-ai/dsh-web-frontend")
   (list "@deepseek-ai/dsh-web-search-deepseek" "0.2.1-rc.2"
         "1vryp3v18jad54bnjj91br0qz7frf9mwy28va77pc1gb5x2pd64h"
         "node_modules/@deepseek-ai/dsh-web-search-deepseek")
   (list "@deepseek-ai/dsh-win32-process" "0.2.1-rc.2"
         "0zdrb5b8icmkakm7jcl2n72r29nql5ifjqjlc93bya9n2p4yfhhl"
         "node_modules/@deepseek-ai/dsh-win32-process")
   (list "@deepseek-ai/dsh-workflow" "0.2.1-rc.2"
         "0jiqncp5pm2slkjf19afaqnyb0n1q6z9436a18hh6i445npqfid5"
         "node_modules/@deepseek-ai/dsh-workflow")
   (list "@deepseek-ai/dsh-workflow-ptc" "0.2.1-rc.2"
         "0g216m7qcd84j1wv0yxf0n4srnlsgv1gh540whkdkh93jhdmxmxz"
         "node_modules/@deepseek-ai/dsh-workflow-ptc")
   (list "@deepseek-ai/dsh-working-directory" "0.2.1-rc.2"
         "0barvyngf2bq8hg3ksfkfr2bj8chl1zmr7vq8nxi3qci0yqhydqw"
         "node_modules/@deepseek-ai/dsh-working-directory")
   (list "@deepseek-ai/dsh-workspace" "0.2.1-rc.2"
         "04jajri5zzdwrylkz0hqrjgk0va957jlqmll857h9cpxadv80msl"
         "node_modules/@deepseek-ai/dsh-workspace")
   (list "@deepseek-ai/dsh-workspace-changes" "0.2.1-rc.2"
         "0bppwsamv6d337aki2pyryc04djlk3fjssjrmq7fw7a1cgbmamxm"
         "node_modules/@deepseek-ai/dsh-workspace-changes")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-workspace/node_modules/zod")
   (list "@deepseek-ai/libreoffice-kit" "0.1.5"
         "0xm5igsjas5823vxmybzzvd474q2ak3kmcp0mq7gq9bs9r19xvgk"
         "node_modules/@deepseek-ai/libreoffice-kit")
   (list "@deepseek-ai/libreoffice-kit-wasm" "0.1.5"
         "01nl3r0wnxrk9gkfvvrx2qp7r3bh6x7pmlvnjz85zmspl8cxlpad"
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
   (list "@deepseek-ai/schemastery" "3.18.5"
         "0gjj9xah8mizvaffcb6ndiw0dpn61kykd2mlyizxigfhh9an6zb0"
         "node_modules/@deepseek-ai/schemastery")
   (list "@earendil-works/pi-ai" "1.5.0"
         "0p7a92vwrfdkw482chs6dalilzw3wmpkazd3m4mph9xrs9xzw873"
         "node_modules/@earendil-works/pi-ai")
   (list "@earendil-works/pi-schema" "1.5.0"
         "13xp0safv6c1rlqb0g4gvqnc6cgx54mdihkx0sjvd42fhkfpc7w6"
         "node_modules/@earendil-works/pi-schema")
   (list "@earendil-works/pi-telemetry" "1.5.0"
         "020l8f7n88ayhdsfs6nr1zmgf3mx03vcy0yx6ls3as46ln14ghx1"
         "node_modules/@earendil-works/pi-telemetry")
   (list "@emnapi/runtime" "1.11.3"
         "0jaykdkjap399v92d0krwrc6y068vkxmr6jzsqv18mcbl09qksz6"
         "node_modules/@emnapi/runtime")
   (list "@eslint-community/regexpp" "4.12.2"
         "04hgmvpsk3810z2zni47wkrr8ncr21wsaykbx48zaixd0kk25jxm"
         "node_modules/@eslint-community/regexpp")
   (list "@google/genai" "2.21.0"
         "1inzl6y65h2hv35z68svg399925qw66d9hk07pnkqig1zv9hg7l5"
         "node_modules/@google/genai")
   (list "@img/colour" "1.1.0"
         "1cc55mq08pxqx9vnd1151kh4n076g6jl52ddj5qn9f6l6fng6bbc"
         "node_modules/@img/colour")
   (list "@img/sharp-libvips-linux-x64" "1.3.4"
         "02fiy5sqsbdpncgpyvdbxw59sycjs2in1yykl2b2r0n87xqwnwg3"
         "node_modules/@img/sharp-libvips-linux-x64")
   (list "@img/sharp-linux-x64" "0.35.5"
         "0d1kxab6lxaffqjbz197l4ch0kacb9dxwmd3hrvc0i1jbll8frsm"
         "node_modules/@img/sharp-linux-x64")
   (list "@img/sharp-wasm32" "0.35.5"
         "0f5vwnzz0dpfj8c14vff0bg4nvg1c8w5lf2kgfrdglhs7vsvv2n6"
         "node_modules/@img/sharp-wasm32")
   (list "@joplin/turndown-plugin-gfm" "1.0.68"
         "08jp7qywkwk086ln57k2sf9z9n212r3xsi03vfi3wb07987b3p7x"
         "node_modules/@joplin/turndown-plugin-gfm")
   (list "@js-temporal/polyfill" "0.5.1"
         "1qxkwrxid345y6ckkixsp3kvpjgs5n2pgj9hzlys6mcacyjlv6n9"
         "node_modules/@js-temporal/polyfill")
   (list "@keyv/serialize" "1.1.1"
         "0rhkz6a2w2n3clr555fpnhlnaf0m54x8qrffly27rvzds7vssc2p"
         "node_modules/@keyv/serialize")
   (list "@koromix/koffi-linux-x64" "3.1.1"
         "1zniacwn5f5c3161n8zx1p5zra68k82havbxnym598w2caj3hh0b"
         "node_modules/@koromix/koffi-linux-x64")
   (list "@mixmark-io/domino" "2.2.0"
         "1v5gcm0izyxkz2v7x9ypai0hbyxn2mlxs8108gv4jijl175bqadq"
         "node_modules/@mixmark-io/domino")
   (list "@modelcontextprotocol/client" "2.2.0"
         "0j0l3gnkzag5cx74xy4xdfrsq78sxnlqa5j5agl5a812bw2cjwq3"
         "node_modules/@modelcontextprotocol/client")
   (list "@modelcontextprotocol/core" "2.2.0"
         "1j4dpj59b7snam59b96gfi0f7c5a0hchqhl988h5nfvdnia1nhgb"
         "node_modules/@modelcontextprotocol/core")
   (list "@opentelemetry/api" "1.9.1"
         "1liwcywxmyr0f8byvpdxwgm9h8ax74d16jngfczd5b3m8ypazqhi"
         "node_modules/@opentelemetry/api")
   (list "@opentelemetry/api-logs" "0.222.0"
         "0b3b50778rhddynrb7knagynhzlfwi1mhwv457j7df5b9g9c812p"
         "node_modules/@opentelemetry/api-logs")
   (list "@opentelemetry/core" "2.11.0"
         "1hgkpq0d02ll9gks5sbsz4dyxjrz4x9k7kxsh725mpx1s9cfm3q0"
         "node_modules/@opentelemetry/core")
   (list "@opentelemetry/otlp-exporter-base" "0.222.0"
         "01nbs22xmg2j6bhi4qgn8bkb1hbcdkkrkc8028jggrldlh4140ba"
         "node_modules/@opentelemetry/otlp-exporter-base")
   (list "@opentelemetry/otlp-transformer" "0.222.0"
         "1mbww2ha3hmn6nrl6azxpw1sbdlwhni3gmlsdn8pck28mcrhhb39"
         "node_modules/@opentelemetry/otlp-transformer")
   (list "@opentelemetry/resources" "2.11.0"
         "155jjr1hggb6x5rf2ijbj410frda5dnl71ls0x16q57clh17j05g"
         "node_modules/@opentelemetry/resources")
   (list "@opentelemetry/sdk-logs" "0.222.0"
         "095pvmq4a02rpsa1krk9d93f1z7fsfqzr98kx0vqnjjlmwdwzlq0"
         "node_modules/@opentelemetry/sdk-logs")
   (list "@opentelemetry/sdk-metrics" "2.11.0"
         "0zwgqpc6s2kgrf5b9xdb6gqjr6kxjqh3lww0qvyafbbx7ycnrx2x"
         "node_modules/@opentelemetry/sdk-metrics")
   (list "@opentelemetry/sdk-trace" "2.11.0"
         "1nzh71r4ir5k5ykg15jmnvga3bnc005hxpf0xrn1i9nsxn15wwld"
         "node_modules/@opentelemetry/sdk-trace")
   (list "@opentelemetry/semantic-conventions" "1.44.0"
         "05k58sx5vrfm2lwgypiclhcnqq958b7jz126c5cdj8kccbfxi4a6"
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
   (list "@sindresorhus/is" "7.2.0"
         "0m5fvvpy3dc3i4zafd8zkz770p4cjp727jy4z1x6dg2ww64ym8iw"
         "node_modules/@sindresorhus/is")
   (list "@sindresorhus/merge-streams" "4.0.0"
         "1ggy58pn5rwvswrxgn0dkg1brm6md3nkzciqxdc8mplqgzmbpqsn"
         "node_modules/@sindresorhus/merge-streams")
   (list "@smithy/core" "3.39.0"
         "0hqfb9c7zbwfgkxpwzhs4574gpb0bbnjnsqpp6sc4ckkbznbavyg"
         "node_modules/@smithy/core")
   (list "@smithy/credential-provider-imds" "4.5.2"
         "04h6678cws5cqc4qig9pnkckrs33zanr0b4kdg8rx68c42c4gkh1"
         "node_modules/@smithy/credential-provider-imds")
   (list "@smithy/fetch-http-handler" "5.8.0"
         "114jsxlfj2m1108kf50grvb1shdmr5gp1f9qwycsmczipwq83l78"
         "node_modules/@smithy/fetch-http-handler")
   (list "@smithy/node-http-handler" "4.12.1"
         "1swfrzyf91lxpmzzqymvwplsh8nsi1dgpi7bbw4nvqfyzccmkl79"
         "node_modules/@smithy/node-http-handler")
   (list "@smithy/signature-v4" "5.7.5"
         "0al4vi1img7jw82j46z0qqf9kaxkacbv1diq0q1kwaq11rqvcig9"
         "node_modules/@smithy/signature-v4")
   (list "@smithy/types" "4.20.0"
         "07i6qy009i6nh9axfah4lwnq6fwkdm0r78pra1yzn937w4jxd8s3"
         "node_modules/@smithy/types")
   (list "@stablelib/base64" "1.0.1"
         "0sjrdadiyy1xyh6lp9pdlbxk8qdx6lgxn9bqdi1qfgqd5qfp2c01"
         "node_modules/@stablelib/base64")
   (list "@standard-schema/spec" "1.1.0"
         "1byfgh3b6ngdj4vba2jw48bk9wl6gjqc7y2hshcba2i8prl75jx7"
         "node_modules/@standard-schema/spec")
   (list "@swc/helpers" "0.5.24"
         "0chfwl9q4b0y32b0yi2q4fi3dgjgcwkn3r6d7b8bnp0j8bjdhw9b"
         "node_modules/@swc/helpers")
   (list "@types/http-cache-semantics" "4.2.0"
         "0si8d9ad5sxflhq7cj292pf3kmmvb79p3awkn0qa158zmpcaswv5"
         "node_modules/@types/http-cache-semantics")
   (list "@types/node" "26.6.6"
         "0mh40bp0nws3h5r6msks225h0n5hiha8hdfmx5l7hr3s5y20dw3y"
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
   (list "agent-base" "9.0.0"
         "17x8rcirms5s8d21m7ldrfzkn3nvx3c6prhxk54npy2gjb7gwq93"
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
   (list "bowser" "2.15.0"
         "0cw8jc9nasbwwfcm264xnd32x7wgd9v1a57jqdhy9nx1bwib72q2"
         "node_modules/bowser")
   (list "brotli" "1.3.3"
         "096v5fggvvbm1849k7bcidi7s8i1zplik4cswkz9bpv3c87jcz1w"
         "node_modules/brotli")
   (list "buffer-equal-constant-time" "1.0.1"
         "0np7kzq65a7yvs7ch5vrhm6i9ayv7v3lqspdaiw3w422wdcm2icg"
         "node_modules/buffer-equal-constant-time")
   (list "bundle-name" "4.1.1"
         "1nink3irr7aaw9yrrpkb5mzkaw7yzgiyf968h2iq2ss5px9hs47n"
         "node_modules/bundle-name")
   (list "byte-counter" "0.1.0"
         "1gl2q906gzcardwjwbl63m31grmjvbvxh43r8p2rj2s31j2g1cbi"
         "node_modules/byte-counter")
   (list "bytes" "3.1.2"
         "10f5wgg4izi14lc425v7ljr1ayk28ycdjckfxpm4bnj0bankfpl3"
         "node_modules/bytes")
   (list "cacheable-lookup" "7.0.0"
         "1l4jrm1iw3a88b68q12jk6n9d0vbsl3852sakyrjzmjjdqwq2dwl"
         "node_modules/cacheable-lookup")
   (list "cacheable-request" "13.0.19"
         "09mp2fkyik65wp8djzj1qw3ns9w0kvakg5sibsfp32g17lachaj1"
         "node_modules/cacheable-request")
   (list "chokidar" "5.0.0"
         "1qzmyw8jg7gr3zj0f593phii9p4yqiy58g5b6g3q5r3ysnkpxl25"
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
   (list "decompress-response" "10.0.0"
         "0xfb48c2pxyq7ayrr3g5gcdrdn17p5kpcjagf4bn08366mg645hv"
         "node_modules/decompress-response")
   (list "default-browser" "5.5.1"
         "09myy4lzx9mr19yr5vl3c5kazvmahpnz3mnxf2l4ddv5a0c9f692"
         "node_modules/default-browser")
   (list "default-browser-id" "5.0.1"
         "0ablblhrzy81aixklbvdvq5fzdybh33q1086vkk0sq8bv7hgp51w"
         "node_modules/default-browser-id")
   (list "define-lazy-prop" "3.0.0"
         "1da99k4vnnn9bxpgjniai8248bcf4w9cwyn7p3wlzii9l9kzxsdv"
         "node_modules/define-lazy-prop")
   (list "depd" "2.0.0"
         "19yl2piwl0ci2lvn5j5sk0z4nbldj6apsrqds3ql2d09aqh8m998"
         "node_modules/depd")
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
   (list "ee-first" "1.1.1"
         "175r500n567a04qmswzw5hkgdnika3dvn63n284jlar2gvmyhj2i"
         "node_modules/ee-first")
   (list "encodeurl" "2.0.1"
         "1gx7h0x0rnicx3cajnm9hs52bhjfskbq78pdngmhb0mgqs6nm7l8"
         "node_modules/encodeurl")
   (list "escape-html" "1.0.3"
         "0rh35dvab1wbp87dy1m6rynbcb9rbs5kry7jk17ixyxx7if1a0d1"
         "node_modules/escape-html")
   (list "etag" "1.8.1"
         "1bqgznlsrqcmxnhmnqkhwzcrqfaalxmfxzly1ikaplkkm5w6ragn"
         "node_modules/etag")
   (list "eventsource" "3.0.7"
         "14hw12k1s7h7bdh5x7sdlx4ic9p4dw6mb7ppbafb6nbf36xx8qkw"
         "node_modules/eventsource")
   (list "eventsource-parser" "3.1.1"
         "1v9niv3704fq0s4l1dpkp2zxncpb9i0p6gny8yn7dspcdk5a1824"
         "node_modules/eventsource-parser")
   (list "execa" "10.2.1"
         "1ah29i3lvq2jlxhq2cbc7xlj0nxmvynlj4kgir0pq5mbi59sa5fc"
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
   (list "fast-uri" "3.1.9"
         "0ppfm5ljwmjah3mkigahq7s14mvzc83fhf5dngksl40invvnfnjg"
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
   (list "form-data-encoder" "4.1.0"
         "0wajiyv2pnggza5g7wmdlksm2am45z0hkpqfm2nsjmwa3swcz0fn"
         "node_modules/form-data-encoder")
   (list "formdata-polyfill" "4.0.10"
         "1sc7hip8lwxbz2jg2k0snyqqwb4s8087kdj11zyz0cza710kpxqz"
         "node_modules/formdata-polyfill")
   (list "fresh" "2.0.0"
         "1mvs4wihlr6bw05h7q12771qrkwrssm26bk80ysv4qjzn1x3j25d"
         "node_modules/fresh")
   (list "gaxios" "7.3.1"
         "174rd4f5jpx4axq1n3vqdl64wfi5w9hx8nvjkhpwj4ah8cxlr723"
         "node_modules/gaxios")
   (list "agent-base" "7.1.4"
         "0zmmkk3xhnkwb6djnvri7zyxllsdz5aa5w83x7afi959d0badm3x"
         "node_modules/gaxios/node_modules/agent-base")
   (list "debug" "4.4.3"
         "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9"
         "node_modules/gaxios/node_modules/debug")
   (list "https-proxy-agent" "7.0.6"
         "1q603cjw6z348j2i7k7s5zb3kp91hi9lml298bv84214wpl8j3wn"
         "node_modules/gaxios/node_modules/https-proxy-agent")
   (list "ms" "2.1.3"
         "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn"
         "node_modules/gaxios/node_modules/ms")
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
   (list "got" "14.6.6"
         "0xiisawzzh3rdfnsaj2k4kzzpzfakg6q2fjgzd8qz93v98x6q89j"
         "node_modules/got")
   (list "http-cache-semantics" "4.3.0"
         "1vlkwlpzq9wh9vvbvxy2ik91cyir9df2n3igbvd58yaq25m1wpnp"
         "node_modules/http-cache-semantics")
   (list "http-errors" "2.0.1"
         "0qbc38g805qi9bcywg082sz8kdgxkq4fssgjlfcrc1xg3fqvnqmd"
         "node_modules/http-errors")
   (list "http-proxy-agent" "9.1.0"
         "0vd7jypljz7ak2zy5hlrgagq8qvxys3pvc6nhkg9pgpa6z2z3329"
         "node_modules/http-proxy-agent")
   (list "debug" "4.4.3"
         "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9"
         "node_modules/http-proxy-agent/node_modules/debug")
   (list "ms" "2.1.3"
         "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn"
         "node_modules/http-proxy-agent/node_modules/ms")
   (list "http2-wrapper" "2.2.4"
         "03gq3syd1bb0sz3w36c45a8pdmwgvgc5ic248z2ir8gx4lgfi3zp"
         "node_modules/http2-wrapper")
   (list "https-proxy-agent" "9.1.0"
         "1va0x7fvaa15xfnxk3zcbb5f8iymrdfkgklnhd76m48qsaw8cpzh"
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
   (list "inherits" "2.0.4"
         "1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr"
         "node_modules/inherits")
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
   (list "jose" "6.2.15"
         "170fa1ld9fz4kb92z43k3777b7k2c9irc7krblhrbv433pf7mm76"
         "node_modules/jose")
   (list "js-tokens" "4.0.0"
         "0lrw3qvcfmxrwwi7p7ng4r17yw32ki7jpnbj2a65ddddv2icg16q"
         "node_modules/js-tokens")
   (list "js-yaml" "4.3.2"
         "1cg5rqg09lgzlfihykcwi2yr3nl7xr6alm1qylzjbyac4b943cn7"
         "node_modules/js-yaml")
   (list "jsbi" "4.3.2"
         "13ipid9zf0f5iwjfnyjz656z7pnd95blkjpaf03hlh0gix41678k"
         "node_modules/jsbi")
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
   (list "keyv" "5.6.0"
         "1q776734yr255pp2aby789nz4hr4ak5x2hb14qsw3bfshdy2p66v"
         "node_modules/keyv")
   (list "koffi" "3.1.1"
         "05rvw2lhs2l2483hpysdz33ni1g1kgh9rws0zrnd2mfiynawpqyn"
         "node_modules/koffi")
   (list "long" "5.3.2"
         "09kbcinla92p75h69i90v5n730wxfaxl34z5r597vpvkcx33w0v8"
         "node_modules/long")
   (list "lowercase-keys" "3.0.0"
         "0w8fkm177ilnwxwvqv4r1xyisnalgv0y3fj0wz4v0w8jvj784mmc"
         "node_modules/lowercase-keys")
   (list "mime-db" "1.54.0"
         "0864s7g498w1f95yvgq0ayqlgpb8x49jfb80qmcbvsnhcm70a89b"
         "node_modules/mime-db")
   (list "mime-types" "3.0.2"
         "1b6j7px7npv0gli3v249m5a1rc2m8x3qxxpva23zy0y3af1x579g"
         "node_modules/mime-types")
   (list "mimic-response" "4.0.0"
         "1ssc0ya79dym26l97r94qa91khyivn5jnww9p8cg9bkagr6hz4qd"
         "node_modules/mimic-response")
   (list "minisearch" "7.2.0"
         "12i1w0w5csh6i1vg7y3h1fja83ibg7q98wkqhyrxcrgalck82fyb"
         "node_modules/minisearch")
   (list "ms" "2.0.0"
         "1jrysw9zx14av3jdvc3kywc3xkjqxh748g4s6p1iy634i2mm489n"
         "node_modules/ms")
   (list "negotiator" "1.1.0"
         "1m6fj8fixhv6hcjnfipsal14h82zh6ipzjgaln4r39lyna1s5b84"
         "node_modules/negotiator")
   (list "node-addon-api" "7.1.1"
         "10hzqyn8vxz16gmh4hwdxzw3kn83krkypc0wgb8hqz4pbb8ma15i"
         "node_modules/node-addon-api")
   (list "node-addon-native-custom-loader" "0.1.9"
         "1s6ypad4i5l4k2k0z7z4p5lm7v64r0vqwy5dlcdbzagw5k0b59qa"
         "node_modules/node-addon-native-custom-loader")
   (list "node-addon-require-builtin" "0.1.9"
         "1vx1ahxs0rj38w40wwgan3j42x62g81mw7m1cpbcw7d7jpyqfi99"
         "node_modules/node-addon-require-builtin")
   (list "node-addon-require-builtin-linux-x64-gnu" "0.1.9"
         "0rhpcvhq6m0lsdig25xvkd8wknyf2i98l61bzg0ys225q5vm9b3q"
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
   (list "normalize-url" "8.1.1"
         "0isjqkfk0mcz4hccnvd7036v1p3pxxhiaq5lw3bba6459jgq98kk"
         "node_modules/normalize-url")
   (list "npm-run-path" "6.0.0"
         "1pwdj6ghn661hpb4clp3bd5p4lmgcwdz484dkyjg4vm4wfikl5l2"
         "node_modules/npm-run-path")
   (list "path-key" "4.0.0"
         "19s9y2rp8b9wvbccpawvx895d69pam72r1vdvgma51h9k8n9m8mf"
         "node_modules/npm-run-path/node_modules/path-key")
   (list "on-finished" "2.4.2"
         "108sbpq5qy0g880wglwl1sr5fls1lib5skxvfp9dzwg9ajhcrxy9"
         "node_modules/on-finished")
   (list "on-headers" "1.1.0"
         "0962avqk7n8jxzghmi2q8h3wabr5riwvnlln4bs44m4n95wlf897"
         "node_modules/on-headers")
   (list "open" "11.0.4"
         "0740ci54m96m8v17v4mag560xynq8qmzx0dyjcvp0waxglsbjn25"
         "node_modules/open")
   (list "openai" "7.19.0"
         "1w87mp7x1579cwfyqnncd3fjmd4qnxbxppnsbsmfh7h5p7f34xar"
         "node_modules/openai")
   (list "p-cancelable" "4.0.1"
         "1fbcmr8hinjjfg0ckn01g78pk5vbxpcj1q6cqkvhgrnrflp97hz0"
         "node_modules/p-cancelable")
   (list "p-limit" "7.3.3"
         "1xrj4im7p3x7fgg6kzj6a8kpg65spjpcxzw9x9zlbcidp0q21pmf"
         "node_modules/p-limit")
   (list "p-retry" "4.6.2"
         "0n5mgwrr69i01n5y8ah793dcyphjcrmbw7jzx3lj0cfyhjs2n491"
         "node_modules/p-retry")
   (list "pako" "0.2.9"
         "17ydqdhy9g76ppkbg0lgkk9837vkpga6gzw8w0m04mfinzqik4sa"
         "node_modules/pako")
   (list "parse-ms" "4.0.0"
         "0s7vnwlhl2513zvff5f21qml9yz3ds24z6gyz4k9vkbv7wcpxg5b"
         "node_modules/parse-ms")
   (list "parseurl" "1.3.3"
         "06h2bx1rilkdir3v9jlg94r1q2fn895s0vxjjs0wx5z027x4pvsn"
         "node_modules/parseurl")
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
   (list "proxy-agent-negotiate" "1.1.0"
         "15qrra5km7sjly0mjs8q6r32w19sdn3ij779mzzv1a41sgaj7v3f"
         "node_modules/proxy-agent-negotiate")
   (list "quick-lru" "5.1.1"
         "1prmggnyx8kw2f4fxbqpaj9hnlpkxaydmkgrvi7qv8h9la25i0xr"
         "node_modules/quick-lru")
   (list "range-parser" "1.3.0"
         "1bhgiw8k39icavl8qkyzj6q8pbrkwzlmc0k86aqqhryvfb09xdsi"
         "node_modules/range-parser")
   (list "readdirp" "5.1.1"
         "19fm2ijz7kd44ifq0v9cbfkrkgka5ma5cjjf316a2pkijy0nhnlk"
         "node_modules/readdirp")
   (list "require-from-string" "2.0.2"
         "10ldp2bzb86czf47kmvirn9x2976yh6g0my7l1spg3whcm4llsfb"
         "node_modules/require-from-string")
   (list "resolve-alpn" "1.2.1"
         "0853fjjwl8as4px6mh6fcs59mnk4l5f4g7yl7pig0m9s72w4z5zx"
         "node_modules/resolve-alpn")
   (list "resolve.exports" "2.0.4"
         "0qyp7yvj3lyj6jk1xddps5sw4kc4wzhjkd9p7m7lpz82k6pysbps"
         "node_modules/resolve.exports")
   (list "responselike" "4.0.2"
         "0lhcnmivmx02bah63n9mf1bw3qc8nrv3r2xc1vwnq96ds4cwribq"
         "node_modules/responselike")
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
   (list "semver" "7.8.6"
         "1gvirlhhqd90i2jlj11zq5kibmjxnbi6xhf60c25s7lb9qr4qn66"
         "node_modules/semver")
   (list "send" "1.2.1"
         "0wn46l21fl21yf5abnx3yr6fr2kq4cxm7ggf5g5xs8yx2srly9gs"
         "node_modules/send")
   (list "debug" "4.4.3"
         "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9"
         "node_modules/send/node_modules/debug")
   (list "ms" "2.1.3"
         "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn"
         "node_modules/send/node_modules/ms")
   (list "serve-static" "2.2.1"
         "0hszcbfcncifwgxk060jy1andx4b7pzjbvig40cfnwlknlmzgm1n"
         "node_modules/serve-static")
   (list "setprototypeof" "1.2.0"
         "1qnzx8bl8h1vga28pf59mjd52wvh1hf3ma18d4zpwmijlrpcqfy8"
         "node_modules/setprototypeof")
   (list "sharp" "0.35.5"
         "1b592hhdm5val7ywbn0ycp27jpfd4qcs794cjf1w7x88ngkbnsrv"
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
   (list "statuses" "2.0.2"
         "1q4zjhjprvhdjc32px6b4b0i3ffn1mbqygp7yilbb204f4j0m06a"
         "node_modules/statuses")
   (list "strip-final-newline" "4.0.0"
         "17lsqdpy1wgnxm2g5ln2a86zps09a6xadqxq56rqsmgl373zcjax"
         "node_modules/strip-final-newline")
   (list "tiny-inflate" "1.0.3"
         "0klgdanxyf1rl8gs1ckpw9z41aww4a0n8gh4mypgzr94jhrjp4vk"
         "node_modules/tiny-inflate")
   (list "toidentifier" "1.0.1"
         "021fp42m51qbqbqabwhxky8bkfkkwza65lqiz7d2gqwd91vwqvqq"
         "node_modules/toidentifier")
   (list "ts-algebra" "2.0.0"
         "0p669fivm6k85ip9n54rv6bh70lcalrv43l6jhp9bdqyv27rdhzl"
         "node_modules/ts-algebra")
   (list "tslib" "2.9.1"
         "02k782x297dqwiilc0vmgdcf5gwlmsvc2g24hsq63hqjnm3ax4l0"
         "node_modules/tslib")
   (list "turndown" "7.2.5"
         "02wfx6ciqaxhz25167j3788s928fi5qsqd2ph8jzv9h7dk9w34by"
         "node_modules/turndown")
   (list "type-fest" "4.41.0"
         "0cl98zyggxrvx5w8adbyr4wvg3l4fmzcqrgia8q1kjfxlvh6kqbx"
         "node_modules/type-fest")
   (list "undici" "8.11.2"
         "1mxqkgsn03a1aindmkv4sbkdgkxj64vq0d9ylk3n5cnz82agg6y6"
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
   (list "wsl-utils" "1.0.1"
         "1gpjqq6k5410fys3n73gi85a5arv0wvrvwxgpycazq2viimac3yh"
         "node_modules/wsl-utils")
   (list "xmlchars" "2.2.0"
         "1a3daxxjcy0p0qbxcqp6d9z6h1czsab5xabanyavvr33i4lh1ydx"
         "node_modules/xmlchars")
   (list "yaml" "2.9.1"
         "1lz5kpawfrwc1sb196r3my21qnl06213f65mnw3s5f2rym6cbxjf"
         "node_modules/yaml")
   (list "yocto-queue" "1.2.2"
         "1bhbd2ncrbx8ijmpfpwil87lzykr3fiwf4pvrsr1dg6g7wav3rv9"
         "node_modules/yocto-queue")
   (list "yoctocolors" "2.2.0"
         "0p3zgy88305bnmpiq9d69z2nhcsn85s4yf293j5s9m5w15223cxb"
         "node_modules/yoctocolors")
   (list "zod" "4.6.7"
         "166n05r9d8qg3w8yn3jvpmn562r7pr8wjgvrdql70cnrprax3vw4"
         "node_modules/zod")
))

(define %dsh-node-bin-links
  ;; (link target), both relative to the package directory, as npm
  ;; creates them in each node_modules/.bin.
  (list
   (list "node_modules/.bin/anthropic-ai-sdk" "../@anthropic-ai/sdk/bin/cli")
   (list "node_modules/.bin/cordis" "../@deepseek-ai/cordis/bin.js")
   (list "node_modules/.bin/dsoffice" "../@deepseek-ai/libreoffice-kit/lib/cli.js")
   (list "node_modules/.bin/is-docker" "../is-docker/cli.js")
   (list "node_modules/.bin/is-inside-container" "../is-inside-container/cli.js")
   (list "node_modules/.bin/js-yaml" "../js-yaml/bin/js-yaml.js")
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
