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

(define-module (sensible-packages dsh-modules)
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
   (list "@aws-sdk/core" "3.981.0"
         "1cd4blnjx3gxgi3aj2xc2x8pabgl3l7pqxgwi0lh6i7drakm9vpq"
         "node_modules/@aws-sdk/core")
   (list "@aws-sdk/credential-provider-env" "3.972.84"
         "1wyikhyj3a04pc0a9xn7w99dlkr7s8bpvchjrm1nyx46xihv2n7h"
         "node_modules/@aws-sdk/credential-provider-env")
   (list "@aws-sdk/credential-provider-http" "3.972.86"
         "1hh8908b5p75b4y1935d6ii8hiv21dg9nddd7vxnna7p98k3k6kk"
         "node_modules/@aws-sdk/credential-provider-http")
   (list "@smithy/node-http-handler" "4.14.2"
         "0j0pj28p018pj5f4z9yrbylmdlbw4swnrwszd55ipl19yxw1ryc9"
         "node_modules/@aws-sdk/credential-provider-http/node_modules/@smithy/node-http-handler")
   (list "@aws-sdk/credential-provider-ini" "3.973.29"
         "0jxvbwcqvcvxzcq61rv7gh1l45rwxmc62lr7364bsfphg0lbbx15"
         "node_modules/@aws-sdk/credential-provider-ini")
   (list "@aws-sdk/credential-provider-login" "3.972.91"
         "0icgdpqz2h6dga8apaa8a6qpq6amfr4iv23wxnsg16m1qc31ammw"
         "node_modules/@aws-sdk/credential-provider-login")
   (list "@aws-sdk/credential-provider-node" "3.972.96"
         "07v2sb0mx2y1hazpxs242270m4h4inagjrwl4a1rzqc1yj635nqm"
         "node_modules/@aws-sdk/credential-provider-node")
   (list "@aws-sdk/credential-provider-process" "3.972.84"
         "1hvw43bczvfj4n8l00nqjla3xf6xjydwzf595w54kv5zgix5c5y8"
         "node_modules/@aws-sdk/credential-provider-process")
   (list "@aws-sdk/credential-provider-sso" "3.973.28"
         "0hxkxhspzn4jgpr5yxgm5xk13qbyw6zcjjag9yvss3dqlkwvv5ri"
         "node_modules/@aws-sdk/credential-provider-sso")
   (list "@aws-sdk/token-providers" "3.1166.0"
         "1gk9pvnbbv8c1xpg7cr2dqazhmiwmxvll1mdz741c5s5bx8fz3a0"
         "node_modules/@aws-sdk/credential-provider-sso/node_modules/@aws-sdk/token-providers")
   (list "@aws-sdk/credential-provider-web-identity" "3.972.90"
         "0m2mn32wvvsxf16ss6pm1sf6v4rcxzzdppg41bcf1fbnr2syk6cz"
         "node_modules/@aws-sdk/credential-provider-web-identity")
   (list "@aws-sdk/eventstream-handler-node" "3.972.42"
         "1qzhzn2dkhqym22ngf33y5xjfsg2v8zi54aqxqnjsckj4vgm7scq"
         "node_modules/@aws-sdk/eventstream-handler-node")
   (list "@aws-sdk/middleware-eventstream" "3.972.38"
         "1y06b7q0vsq46arc2vmh4q60fhfplfh5sy4y7z6cwh795zxpsjxm"
         "node_modules/@aws-sdk/middleware-eventstream")
   (list "@aws-sdk/middleware-websocket" "3.972.66"
         "07b2xxy1d8ih1y5nir8v4njilmsb3v2mlzw1m6737l4dpx1nh5q9"
         "node_modules/@aws-sdk/middleware-websocket")
   (list "@aws-sdk/nested-clients" "3.998.3"
         "1ldaw5x16jarsqhkdvjgzv7pf7aqnjz51mmwpz58x2rsj7zz3d9h"
         "node_modules/@aws-sdk/nested-clients")
   (list "@smithy/node-http-handler" "4.14.2"
         "0j0pj28p018pj5f4z9yrbylmdlbw4swnrwszd55ipl19yxw1ryc9"
         "node_modules/@aws-sdk/nested-clients/node_modules/@smithy/node-http-handler")
   (list "@aws-sdk/signature-v4-multi-region" "3.996.52"
         "0d0m37s24i5sng96k9xxak5z6334ywpfh9x8gmv1k4marhkxhzlm"
         "node_modules/@aws-sdk/signature-v4-multi-region")
   (list "@aws-sdk/token-providers" "3.1127.0"
         "1h4m7k7ifmabsqfbnf34sj7p3lap01m62spvrf3xzgivf65ablym"
         "node_modules/@aws-sdk/token-providers")
   (list "@aws-sdk/types" "3.975.1"
         "1z5p4w1xp257jvhybhx035h92kpywgvmnhjzivvp1fg6dhhygbc4"
         "node_modules/@aws-sdk/types")
   (list "@aws-sdk/xml-builder" "3.972.43"
         "1jnr2v2i88cmf364fl6g92xg57hndk033g29rlxi394i9byyd9wi"
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
   (list "@deepseek-ai/cordis" "4.1.0"
         "1jiffnkvqw8ilqdf2z8gd72rbq8sdz7jl14rw71m42wvmak9j01v"
         "node_modules/@deepseek-ai/cordis")
   (list "@deepseek-ai/cordis-plugin-group" "1.1.0"
         "1l2gx8r3jy0vpb3rh01f1y3ngwjxacl4917d50dy7rq97cyxjqdc"
         "node_modules/@deepseek-ai/cordis-plugin-group")
   (list "@deepseek-ai/cordis-plugin-include" "1.1.0"
         "0jj61cz66h5wd395bqyxaxldb3v1ylg2avnjdgfd19r5v9s6zszy"
         "node_modules/@deepseek-ai/cordis-plugin-include")
   (list "@deepseek-ai/cordis-plugin-loader" "1.1.0"
         "17wkk74b8fsh7zhc5s7v1lkzqgzgj37wpkc8kawql7inhpy6gd5g"
         "node_modules/@deepseek-ai/cordis-plugin-loader")
   (list "@deepseek-ai/cordis-plugin-timer" "1.2.0"
         "0wm2jmxlbn57kxm36qazfybp0kps4226j1yisspqcmid61bmq3nz"
         "node_modules/@deepseek-ai/cordis-plugin-timer")
   (list "@deepseek-ai/cosmokit" "1.9.0"
         "07gpgzhij1qq4spjgn3sjrvjb5scny0w6jqhrg3zcvvzphyh89b2"
         "node_modules/@deepseek-ai/cosmokit")
   (list "@deepseek-ai/dsh-acp" "0.2.2-rc.1"
         "0xsp17w78s3anbrfrq3a44nra2jwaj3c2g8gssxx9dvn6fwmnjdq"
         "node_modules/@deepseek-ai/dsh-acp")
   (list "@deepseek-ai/dsh-acp-app" "0.2.2-rc.1"
         "1ah82kkxd0l14hkzhq67lgh4j6k2q1hc8zcikbmiircj9iikkrxr"
         "node_modules/@deepseek-ai/dsh-acp-app")
   (list "@deepseek-ai/dsh-action-cards" "0.2.2-rc.1"
         "10lw23rl1jv34axg5nf5d9jb9r6k1nq5kjhwzqh2n9li2a282zq7"
         "node_modules/@deepseek-ai/dsh-action-cards")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-action-cards/node_modules/zod")
   (list "@deepseek-ai/dsh-agent" "0.2.2-rc.1"
         "1m5bx8kwgivi79733h33s0bk3h564qrkcvjp1q3bk39i18xqmxng"
         "node_modules/@deepseek-ai/dsh-agent")
   (list "@deepseek-ai/dsh-agent-default-model" "0.2.2-rc.1"
         "1mcm7qp11z8d03qmlmir69zwng8i1yvdp9pl3qip2n3ms1pmzphz"
         "node_modules/@deepseek-ai/dsh-agent-default-model")
   (list "@deepseek-ai/dsh-agent-instructions" "0.2.2-rc.1"
         "1dwx1dqhbm1nyp9lb88kzk1di8cnilrmy2b70mdgjr8hy1cc1hks"
         "node_modules/@deepseek-ai/dsh-agent-instructions")
   (list "@deepseek-ai/dsh-agent-loop" "0.2.2-rc.1"
         "1qz0ksd3gb10f5clzgkcqck50kcpxxzzissciql746rbjw5ws4r6"
         "node_modules/@deepseek-ai/dsh-agent-loop")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-agent-loop/node_modules/zod")
   (list "@deepseek-ai/dsh-agent-preset" "0.2.2-rc.1"
         "0cam9rxp958l5dgyk9k5gzzw35nr0q7zcsq8gw5klvja382app00"
         "node_modules/@deepseek-ai/dsh-agent-preset")
   (list "@deepseek-ai/dsh-agent-preset-registry" "0.2.2-rc.1"
         "1w91lg15iyrj0hhhl4bvi0107yv8vbsd26xivbvd7g4kimbql88m"
         "node_modules/@deepseek-ai/dsh-agent-preset-registry")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-agent-preset-registry/node_modules/zod")
   (list "@deepseek-ai/dsh-agent-tool-presentation" "0.2.2-rc.1"
         "12yyz4zh8j93174v0336gpql78g469zsfp7chcqpq747ldhrl12d"
         "node_modules/@deepseek-ai/dsh-agent-tool-presentation")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-agent/node_modules/zod")
   (list "@deepseek-ai/dsh-anonymous-user-id" "0.2.2-rc.1"
         "0nyxwx0s2jcimyhjjfy2w1mhh106g30m5z3hbip59p4550x7vhvq"
         "node_modules/@deepseek-ai/dsh-anonymous-user-id")
   (list "@deepseek-ai/dsh-api-account-controller" "0.2.2-rc.1"
         "13218ghs2wqdl9k0az52yd8w13nsqbf18gry00wj5b2yjq9p7mbj"
         "node_modules/@deepseek-ai/dsh-api-account-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-account-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-gateway" "0.2.2-rc.1"
         "0hw9k3g0ax4g33ia49y96y56dn72ym1l4m3hapviv5w6s2fzm0gr"
         "node_modules/@deepseek-ai/dsh-api-gateway")
   (list "@deepseek-ai/dsh-api-job-controller" "0.2.2-rc.1"
         "1av2fdzr3x99ryxmay4m32vpjry2556zhhbqhzahqzfvjy9prhll"
         "node_modules/@deepseek-ai/dsh-api-job-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-job-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-remote-access" "0.2.2-rc.1"
         "0j0msi5r3lvwvb9yvpz09rpwix9x1699p8izm1l6462q41hifc2h"
         "node_modules/@deepseek-ai/dsh-api-remote-access")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-remote-access/node_modules/zod")
   (list "@deepseek-ai/dsh-api-remotes" "0.2.2-rc.1"
         "10pa6ml4rwx7qwkg52z7dyhhdzzwv30bhsljqyx7pigkhscbb1kc"
         "node_modules/@deepseek-ai/dsh-api-remotes")
   (list "@deepseek-ai/dsh-api-session-controller" "0.2.2-rc.1"
         "0rk8xnaszdl50pbf5kqdml31571nqw87jz14spx3m8qgiwhfxzwy"
         "node_modules/@deepseek-ai/dsh-api-session-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-session-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-settings-controller" "0.2.2-rc.1"
         "19sb20jvx9qmvmm5922rdhvkanfj4j204sckf7pwlaxa71wjvpv5"
         "node_modules/@deepseek-ai/dsh-api-settings-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-settings-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-terminal-controller" "0.2.2-rc.1"
         "1ndjnb1mf0pisgccw1p2msfqib1ircf53la6fcsxdkwvwlnkmy5d"
         "node_modules/@deepseek-ai/dsh-api-terminal-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-terminal-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-workspace-controller" "0.2.2-rc.1"
         "0gmxmany62rr3cpapz6s93mbj6rx80k8i7gfln3qi7657i57027m"
         "node_modules/@deepseek-ai/dsh-api-workspace-controller")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-workspace-controller/node_modules/zod")
   (list "@deepseek-ai/dsh-api-workspace-files" "0.2.2-rc.1"
         "1jfids11c3l3a89xm1k32rkcpd9y5f1q70fpn3jghpx80q26pkzx"
         "node_modules/@deepseek-ai/dsh-api-workspace-files")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-api-workspace-files/node_modules/zod")
   (list "@deepseek-ai/dsh-app-boot" "0.2.2-rc.1"
         "1qdxs6wf8cf39x5zy2xksxgq78lvimb9kcvb2sl054qfq4a31dsc"
         "node_modules/@deepseek-ai/dsh-app-boot")
   (list "@deepseek-ai/dsh-atomic-write" "0.2.2-rc.1"
         "04jnbaccbc5y88b35w96dr5848w9mg96xn08kphnkvmbm62jhsh9"
         "node_modules/@deepseek-ai/dsh-atomic-write")
   (list "@deepseek-ai/dsh-attachment" "0.2.2-rc.1"
         "01hbljv33fpan9sgm2csy2dqqflk4r33pjqmlkv58jv1hb6qv0j1"
         "node_modules/@deepseek-ai/dsh-attachment")
   (list "@deepseek-ai/dsh-attachment-local" "0.2.2-rc.1"
         "0yrjlvn6g3p681s0nfanvh6xykq0msiiirkx1zwi453qjxr3jjdm"
         "node_modules/@deepseek-ai/dsh-attachment-local")
   (list "@deepseek-ai/dsh-authorization" "0.2.2-rc.1"
         "00zg5pslgm4v2rbrs7d2xz1zbpwbgs5wq9vbinpni7rmzr66rvv3"
         "node_modules/@deepseek-ai/dsh-authorization")
   (list "@deepseek-ai/dsh-base" "0.2.2-rc.1"
         "1bi9q8flr4nk7hcpr5f5a2s27x8311c3dljvmvn601j1jsrsl648"
         "node_modules/@deepseek-ai/dsh-base")
   (list "@deepseek-ai/dsh-bash-local" "0.2.2-rc.1"
         "0wn99js4b209nslcn48mji6js924149yxmjiqwb9mvy22llf6xn1"
         "node_modules/@deepseek-ai/dsh-bash-local")
   (list "@deepseek-ai/dsh-bash-sandbox" "0.2.2-rc.1"
         "0iyxbac93qz982v55mj9dy3xq5ddaa9knx5zqsbhhp0hr492zgsb"
         "node_modules/@deepseek-ai/dsh-bash-sandbox")
   (list "@deepseek-ai/dsh-brand" "0.2.2-rc.1"
         "0c2mmm45662aky8bw342a6kyy7j26qxrmkj70c5vwsfdimgcnlyr"
         "node_modules/@deepseek-ai/dsh-brand")
   (list "@deepseek-ai/dsh-chunked-list" "0.2.2-rc.1"
         "1nb5ywjd16ksj8cf9gayjihxh5wxgc3ww7s9ql6izmfgf94m9s2n"
         "node_modules/@deepseek-ai/dsh-chunked-list")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-chunked-list/node_modules/zod")
   (list "@deepseek-ai/dsh-client-connection" "0.2.2-rc.1"
         "0qz2yldphg7bz08hz185fpisrn2ssgilzany5njb9c85p4m061an"
         "node_modules/@deepseek-ai/dsh-client-connection")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-connection/node_modules/zod")
   (list "@deepseek-ai/dsh-client-file-upload" "0.2.2-rc.1"
         "0i8n3yff90dgj6qb5fl7sx8ki8lk96bpkwajz65ab1ndvm3bfd8i"
         "node_modules/@deepseek-ai/dsh-client-file-upload")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-file-upload/node_modules/zod")
   (list "@deepseek-ai/dsh-client-hmr" "0.2.2-rc.1"
         "0yh4lhrmzn1dd8v4mfmwwnrb3rcbb3jz67dbgdnag72za78ib7bm"
         "node_modules/@deepseek-ai/dsh-client-hmr")
   (list "@deepseek-ai/dsh-client-locale" "0.2.2-rc.1"
         "0rp3jdp6w0k0mg541dib0irnz8qzwqb2b2cy94r899migj9kg610"
         "node_modules/@deepseek-ai/dsh-client-locale")
   (list "@deepseek-ai/dsh-client-modules" "0.2.2-rc.1"
         "18fxh4c4krsc0q5j5nymk03qg8l8y0rddq10vvlapifvzbfa8lis"
         "node_modules/@deepseek-ai/dsh-client-modules")
   (list "@deepseek-ai/dsh-client-product-analytics" "0.2.2-rc.1"
         "03z6s7qd5jq7ldvs7xvqzgc961lzys7arhny08143nr6zlx2m0z1"
         "node_modules/@deepseek-ai/dsh-client-product-analytics")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-product-analytics/node_modules/zod")
   (list "@deepseek-ai/dsh-client-resources" "0.2.2-rc.1"
         "0ql96dlcw4cfnhznpk8kc0aaimg9kpai5cpgjazb1mkv6v64r24s"
         "node_modules/@deepseek-ai/dsh-client-resources")
   (list "@deepseek-ai/dsh-client-shortcuts" "0.2.2-rc.1"
         "1cn9kzazp2czim9nvrms0d8l7m33pz0491a572xfrnj061pxsklr"
         "node_modules/@deepseek-ai/dsh-client-shortcuts")
   (list "@deepseek-ai/dsh-client-ui-action-cards" "0.2.2-rc.1"
         "0c47d58rw0aawbgj0xmp6y8k1xws59msrn1v69gr1f8pk3sa8vc1"
         "node_modules/@deepseek-ai/dsh-client-ui-action-cards")
   (list "@deepseek-ai/dsh-client-ui-agent-preset" "0.2.2-rc.1"
         "0nlf6w1q5hyym2m1pf2vn87bz29hs7pv21hpf7m1idip36210sgk"
         "node_modules/@deepseek-ai/dsh-client-ui-agent-preset")
   (list "@deepseek-ai/dsh-client-ui-approval" "0.2.2-rc.1"
         "1ra8h9ff8fpihdkrlgx6drw2lkwdn1z1mq6c09fx3ivg3m3kv637"
         "node_modules/@deepseek-ai/dsh-client-ui-approval")
   (list "@deepseek-ai/dsh-client-ui-attachment" "0.2.2-rc.1"
         "182icrp2i06bp1w9bj3b3awmz6lk9v9fwq75lz4xp5317vz02h6j"
         "node_modules/@deepseek-ai/dsh-client-ui-attachment")
   (list "@deepseek-ai/dsh-client-ui-brand-official" "0.2.2-rc.1"
         "1ymhrrxd88qqsrwfckhv3f9rbxdr6i475kq8m8679ms1q0cigmxc"
         "node_modules/@deepseek-ai/dsh-client-ui-brand-official")
   (list "@deepseek-ai/dsh-client-ui-chat" "0.2.2-rc.1"
         "131aijdz1rzp544yn47jam297qqk43kvkh58vhla1d705mvnsic8"
         "node_modules/@deepseek-ai/dsh-client-ui-chat")
   (list "@deepseek-ai/dsh-client-ui-commands" "0.2.2-rc.1"
         "0iydf7lv9dp476iznw5xjs55m03wjqpscgfkybrjvmkh7rfx7iyn"
         "node_modules/@deepseek-ai/dsh-client-ui-commands")
   (list "@deepseek-ai/dsh-client-ui-context-menu" "0.2.2-rc.1"
         "0hgky7bss2vkgfkp1vddw1kksmi0lnry3mj4ywfpdllc4z77q08p"
         "node_modules/@deepseek-ai/dsh-client-ui-context-menu")
   (list "@deepseek-ai/dsh-client-ui-conversation" "0.2.2-rc.1"
         "0w56cw4867h81blmyzcgw8wfd7nyk3f8adgipjxzh2flaxvkg25h"
         "node_modules/@deepseek-ai/dsh-client-ui-conversation")
   (list "@deepseek-ai/dsh-client-ui-cordis" "0.2.2-rc.1"
         "00nlp49pwh2zsfyl0isl6q7zr8m595nxi4jnw4b3w587318pqrd7"
         "node_modules/@deepseek-ai/dsh-client-ui-cordis")
   (list "@deepseek-ai/dsh-client-ui-creation-recommendations" "0.2.2-rc.1"
         "1ai4zsf213s6cyqg3msjkwvcsymavzxh7f6xbw8yvwbvic9s2067"
         "node_modules/@deepseek-ai/dsh-client-ui-creation-recommendations")
   (list "@deepseek-ai/dsh-client-ui-deliverables" "0.2.2-rc.1"
         "0z1j9p51iyq6vf4ik3l0aqgpis5ag0yazwbblfyykgrs778q6pbi"
         "node_modules/@deepseek-ai/dsh-client-ui-deliverables")
   (list "@deepseek-ai/dsh-client-ui-directory-picker-browse" "0.2.2-rc.1"
         "0wmmw3r499c33prf5kx0c31fkkci4a4j2pi7g98l4s2q4v790ni0"
         "node_modules/@deepseek-ai/dsh-client-ui-directory-picker-browse")
   (list "@deepseek-ai/dsh-client-ui-directory-picker-native" "0.2.2-rc.1"
         "0l0ifs4p5c593q4is0yski9glhlsl47h874djdf8ir5b4vijywf3"
         "node_modules/@deepseek-ai/dsh-client-ui-directory-picker-native")
   (list "@deepseek-ai/dsh-client-ui-entry-customization" "0.2.2-rc.1"
         "0ln3nz73cb83j16bpy7wfk2abcn68s28h0xj0arkwk14ppfmrqn8"
         "node_modules/@deepseek-ai/dsh-client-ui-entry-customization")
   (list "@deepseek-ai/dsh-client-ui-file-actions" "0.2.2-rc.1"
         "0rj9wrhynm2m2dlslg4wknr3dn8sfycj78f1xnsqpd9wjhxq8rl3"
         "node_modules/@deepseek-ai/dsh-client-ui-file-actions")
   (list "@deepseek-ai/dsh-client-ui-file-drag" "0.2.2-rc.1"
         "051ap0l12b5lhdjbqypd0qqq9isy20qh239a1alxm4bj6rpfbjmx"
         "node_modules/@deepseek-ai/dsh-client-ui-file-drag")
   (list "@deepseek-ai/dsh-client-ui-goal" "0.2.2-rc.1"
         "108jbx1wnc6qgjsp7pjr05sa642rvk96krndcfvr5xmfkhv0p0qj"
         "node_modules/@deepseek-ai/dsh-client-ui-goal")
   (list "@deepseek-ai/dsh-client-ui-input-trigger" "0.2.2-rc.1"
         "0ccj2y96wnqgkvnb71lmhh2yj7w1mbdz1l1hq9bix8i03y794zr4"
         "node_modules/@deepseek-ai/dsh-client-ui-input-trigger")
   (list "@deepseek-ai/dsh-client-ui-jobs" "0.2.2-rc.1"
         "0vm1ff6s47142k61awxy8i77yldvg9vmc127rzpr41b6pmdkr2g7"
         "node_modules/@deepseek-ai/dsh-client-ui-jobs")
   (list "@deepseek-ai/dsh-client-ui-layout" "0.2.2-rc.1"
         "0d3vh7k5mdag807bz2azg86zdkga0q2dq49qcjjhm6ia7iijn18k"
         "node_modules/@deepseek-ai/dsh-client-ui-layout")
   (list "@deepseek-ai/dsh-client-ui-message-feedback" "0.2.2-rc.1"
         "1fgfp4p924mjgxzp8bxq0jkfrbpn9gyshspy6sq2719643ifi92l"
         "node_modules/@deepseek-ai/dsh-client-ui-message-feedback")
   (list "@deepseek-ai/dsh-client-ui-model-selection" "0.2.2-rc.1"
         "0g02y7ffamxjklm99bii8222zrpcrlzishw7fr26iqrgbk4cv336"
         "node_modules/@deepseek-ai/dsh-client-ui-model-selection")
   (list "@deepseek-ai/dsh-client-ui-open-in-app" "0.2.2-rc.1"
         "0m207dkaavjq2q2y7w5sn5x340kipzis8gnls79i6whr7qi9cgry"
         "node_modules/@deepseek-ai/dsh-client-ui-open-in-app")
   (list "@deepseek-ai/dsh-client-ui-permission-presets" "0.2.2-rc.1"
         "0226whzdd5c2p64fbpd9dchg1n3fwn86qwkqjvj6xylwnlvj6hcq"
         "node_modules/@deepseek-ai/dsh-client-ui-permission-presets")
   (list "@deepseek-ai/dsh-client-ui-plan" "0.2.2-rc.1"
         "1z7x3g3zqk2wl4px3a76p7mi4np1yqx3xg8crn3jzh85jgpkzxyl"
         "node_modules/@deepseek-ai/dsh-client-ui-plan")
   (list "@deepseek-ai/dsh-client-ui-plugin-manager" "0.2.2-rc.1"
         "0w32id57s5ld7sj4962xb9lq1v46qjkh9cm883cb9idyzq547n7i"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-manager")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-manager/node_modules/zod")
   (list "@deepseek-ai/dsh-client-ui-plugin-market" "0.2.2-rc.1"
         "04i63kipn4sk53kn5nvq233mhkp5n408hmbbfxk3gz3vjrr58cii"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-market")
   (list "@deepseek-ai/dsh-client-ui-plugin-recommendations" "0.2.2-rc.1"
         "1sw5l6af2zvyap9aaiv3nj4p2r8w07glvrh4gdxlbc2dg97l5gj9"
         "node_modules/@deepseek-ai/dsh-client-ui-plugin-recommendations")
   (list "@deepseek-ai/dsh-client-ui-reference" "0.2.2-rc.1"
         "1apv15n3day25ch4xxycqnf9cxbzp72bwvva0zsivkb4vpaybnmq"
         "node_modules/@deepseek-ai/dsh-client-ui-reference")
   (list "@deepseek-ai/dsh-client-ui-renderer" "0.2.2-rc.1"
         "1z1v9j36y1xyr2cn885li6pnrd2cslgw5yqgyqwigc8crsymfasc"
         "node_modules/@deepseek-ai/dsh-client-ui-renderer")
   (list "@deepseek-ai/dsh-client-ui-schedule" "0.2.2-rc.1"
         "0q08pf7r7mg43pxh0knb58307swq3irqqr37p694ch5id2l1lmhi"
         "node_modules/@deepseek-ai/dsh-client-ui-schedule")
   (list "@deepseek-ai/dsh-client-ui-secret-mask" "0.2.2-rc.1"
         "132bs0nn5aljps492z5zwxl338j7h2qv85818xl78ypnmsifl6ck"
         "node_modules/@deepseek-ai/dsh-client-ui-secret-mask")
   (list "@deepseek-ai/dsh-client-ui-session" "0.2.2-rc.1"
         "0djvm3wdb8g1zyvwjc37mg1lzsskj8fnxbyr2c6c0394qw7q5s2x"
         "node_modules/@deepseek-ai/dsh-client-ui-session")
   (list "@deepseek-ai/dsh-client-ui-settings" "0.2.2-rc.1"
         "0ijh17r01sw3hrf41rbs716f1fi3rgba90xpyyfcrayz2m8br3hp"
         "node_modules/@deepseek-ai/dsh-client-ui-settings")
   (list "@deepseek-ai/dsh-client-ui-settings-account" "0.2.2-rc.1"
         "07nlkmwasckkb4kdgllkxl26ncrzh0h29xzfqjbfa5c9bqj6ylrj"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-account")
   (list "@deepseek-ai/dsh-client-ui-settings-agent-loop" "0.2.2-rc.1"
         "0g8024lnqc5ahy7y03f5ibdhkhchf0d345i96fbyzqcr7w63sfxf"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-agent-loop")
   (list "@deepseek-ai/dsh-client-ui-settings-general" "0.2.2-rc.1"
         "0p68mqka53vjpxa1fhf2sdia3yqh5ljhf9rw83dgg714y8y66vby"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-general")
   (list "@deepseek-ai/dsh-client-ui-settings-models" "0.2.2-rc.1"
         "0n5d9vq5g8gbfk3hxk64k8bs1hkszbkv4i3rjpzzl81cg4sgmlk1"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-models")
   (list "@deepseek-ai/dsh-client-ui-settings-plugin-inventory" "0.2.2-rc.1"
         "0i0f4py7m3grhbsrwfy95wfypc2h3zlxv405ri44d3aa15vdsb09"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-plugin-inventory")
   (list "@deepseek-ai/dsh-client-ui-settings-plugins" "0.2.2-rc.1"
         "0bd1pag66s2x01zl174bvylp8zr5yg7zsas8xf8cs371cyls1yr8"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-plugins")
   (list "@deepseek-ai/dsh-client-ui-settings-session-log" "0.2.2-rc.1"
         "0ivm02m05hqgpj37d8fcqpnrri0s5ybmqs4yfamcs7ka5c7984b0"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-session-log")
   (list "@deepseek-ai/dsh-client-ui-settings-shell" "0.2.2-rc.1"
         "0hkxa0pmhwh0wfwilsyz26yyyjaf694f8vh65fvlf4b7rm49l8j6"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-shell")
   (list "@deepseek-ai/dsh-client-ui-settings-subagent" "0.2.2-rc.1"
         "0bspga3ly4p64rmz68lnvrghgg3jpksfb6bzh4kv20kw1yrdk7qy"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-subagent")
   (list "@deepseek-ai/dsh-client-ui-settings-web-search" "0.2.2-rc.1"
         "0a45lxh8xnyi76k5yss0059yibbyxwng1cb9bzg25aclf2ii3hz5"
         "node_modules/@deepseek-ai/dsh-client-ui-settings-web-search")
   (list "@deepseek-ai/dsh-client-ui-shortcuts" "0.2.2-rc.1"
         "104812r15l7f8wanczrbx1nw0jhr5d4679dknrvz2hk3p99hn4mf"
         "node_modules/@deepseek-ai/dsh-client-ui-shortcuts")
   (list "@deepseek-ai/dsh-client-ui-sidebar" "0.2.2-rc.1"
         "1cadyvdfh2wnap4w0a3b6sf5hi04hjy82big5pw4dlj4h36q6dh0"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar")
   (list "@deepseek-ai/dsh-client-ui-sidebar-browser" "0.2.2-rc.1"
         "1zm778g53j76mpvkkxp19xwkanydbckmnwp01didbq73n8hiz63b"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-browser")
   (list "@deepseek-ai/dsh-client-ui-sidebar-documentpreview" "0.2.2-rc.1"
         "1qnqq370i1czcb5rch0i8hx7fwhhcrmnfs1srbkibmfl95wwm9z0"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-documentpreview")
   (list "@deepseek-ai/dsh-client-ui-sidebar-files" "0.2.2-rc.1"
         "06zxjkbkld9lzp5nlzf3kddk7q7xb74dnf7zp8lbzp2icdqqyanl"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-files")
   (list "@deepseek-ai/dsh-client-ui-sidebar-right" "0.2.2-rc.1"
         "0yd7l5js8qr9rwic3lnj011z5qcmj0dccz3b4azpdsbx7ghs7pgq"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-right")
   (list "@deepseek-ai/dsh-client-ui-sidebar-terminal" "0.2.2-rc.1"
         "0hff6v0zfkvk673ylj5r84c1jscaqmm068ixfhy82jbc6cbrpxp7"
         "node_modules/@deepseek-ai/dsh-client-ui-sidebar-terminal")
   (list "@deepseek-ai/dsh-client-ui-skill" "0.2.2-rc.1"
         "0l9wzjrljgyk777c5r61idp6ppawb64sfhkzbihz0p711fxn9ks7"
         "node_modules/@deepseek-ai/dsh-client-ui-skill")
   (list "@deepseek-ai/dsh-client-ui-subagent" "0.2.2-rc.1"
         "1pxq3sg7wwis5206sh6315718q44lary7ma3j2h4mzai46hhimg1"
         "node_modules/@deepseek-ai/dsh-client-ui-subagent")
   (list "@deepseek-ai/dsh-client-ui-theme" "0.2.2-rc.1"
         "0z5226fl7i9qhl2886b3zil1178j9fhh1dbala3yamzqaj5961za"
         "node_modules/@deepseek-ai/dsh-client-ui-theme")
   (list "@deepseek-ai/dsh-client-ui-tool" "0.2.2-rc.1"
         "1s2v7irx5kylzq23v726hmxm8w4v8iwrp3vbq8psff67k2pg9gnz"
         "node_modules/@deepseek-ai/dsh-client-ui-tool")
   (list "@deepseek-ai/dsh-client-ui-trajectory" "0.2.2-rc.1"
         "1n6zfn2pwd7fyb8zchzrg80qgcd7yl2sym6qdc337gycbrixza1b"
         "node_modules/@deepseek-ai/dsh-client-ui-trajectory")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-client-ui-trajectory/node_modules/zod")
   (list "@deepseek-ai/dsh-client-ui-user-questions" "0.2.2-rc.1"
         "117xdk88jqf1g82lfpm6g6awyxj7c8faznbhp0a3j1333cb99qhn"
         "node_modules/@deepseek-ai/dsh-client-ui-user-questions")
   (list "@deepseek-ai/dsh-client-ui-workflow-run" "0.2.2-rc.1"
         "0kql9jald93wfa4rrj112hmd023dx4520s7bc9k608q7dpicg6w0"
         "node_modules/@deepseek-ai/dsh-client-ui-workflow-run")
   (list "@deepseek-ai/dsh-client-ui-workspace" "0.2.2-rc.1"
         "1c0012xzsm1s3y242n6j562vg9g60gf4jywyqk04jdjrxl1c4ira"
         "node_modules/@deepseek-ai/dsh-client-ui-workspace")
   (list "@deepseek-ai/dsh-cmdline" "0.2.2-rc.1"
         "07hxm9jx3jjgwbci8wgqfq8h5rdbwf5x174yacv0y6q7flbjsymf"
         "node_modules/@deepseek-ai/dsh-cmdline")
   (list "@deepseek-ai/dsh-command-compact" "0.2.2-rc.1"
         "1v2pqy0483v0l2d4v4akpkwqlbsdp5gh6ny522al4bx2b8rn5w6h"
         "node_modules/@deepseek-ai/dsh-command-compact")
   (list "@deepseek-ai/dsh-command-feedback" "0.2.2-rc.1"
         "1npafmf745f42nkn5417gvnk1xk7lappf9jd4s0vmssy380385a6"
         "node_modules/@deepseek-ai/dsh-command-feedback")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-command-feedback/node_modules/zod")
   (list "@deepseek-ai/dsh-command-goal" "0.2.2-rc.1"
         "0wi3lc9dq084ldqfgdbydiw8fics0q0qayspfh320993wjffqpfi"
         "node_modules/@deepseek-ai/dsh-command-goal")
   (list "@deepseek-ai/dsh-commands" "0.2.2-rc.1"
         "0994hzq2zggmbs6wg2zplqfgrxda53n400szv4fn5q2514jy82cg"
         "node_modules/@deepseek-ai/dsh-commands")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-commands/node_modules/zod")
   (list "@deepseek-ai/dsh-compaction" "0.2.2-rc.1"
         "015gd626dfakcyjd8rn9pikn273sbjw6gfnpk5kifw672fxxrrs5"
         "node_modules/@deepseek-ai/dsh-compaction")
   (list "@deepseek-ai/dsh-compaction-basic" "0.2.2-rc.1"
         "1bmqylkrrsg1hd344kr3bkf8ic4ihm2imdawsx2873mzn7b5c9az"
         "node_modules/@deepseek-ai/dsh-compaction-basic")
   (list "@deepseek-ai/dsh-compaction-image-offload" "0.2.2-rc.1"
         "10afdykll57q0l61abxp9073vra5m67mmy907vpjc68fvv05rw8w"
         "node_modules/@deepseek-ai/dsh-compaction-image-offload")
   (list "@deepseek-ai/dsh-compaction-tool-result-pruner" "0.2.2-rc.1"
         "1fjnnkch6r4av63ppy3y9iz31v3dqfwb4sb3kkymcp3ks5h25qyk"
         "node_modules/@deepseek-ai/dsh-compaction-tool-result-pruner")
   (list "@deepseek-ai/dsh-config-editor" "0.2.2-rc.1"
         "1z5r1j1q6y7j5xmn6y3mcq9kr8x8fj6algk7avl43zm6ckmdfyzw"
         "node_modules/@deepseek-ai/dsh-config-editor")
   (list "@deepseek-ai/dsh-cordis-client-runner" "0.2.2-rc.1"
         "1w4a1k797km9nj824xn5c41mxlqgc0vzpz3v1zwf0xc31vv85hrm"
         "node_modules/@deepseek-ai/dsh-cordis-client-runner")
   (list "@deepseek-ai/dsh-cordis-host-runner" "0.2.2-rc.1"
         "0v7yq5vd0gj5ic4f0ppflb4k5vxxa66i3bfi16x6rgm8f2q2flrx"
         "node_modules/@deepseek-ai/dsh-cordis-host-runner")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-cordis-host-runner/node_modules/zod")
   (list "@deepseek-ai/dsh-creation-recommendations" "0.2.2-rc.1"
         "1d3i25kx5pdqafj5r941ian3gqhqzn21m3mbs9vp5wdjrka9liwg"
         "node_modules/@deepseek-ai/dsh-creation-recommendations")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-creation-recommendations/node_modules/zod")
   (list "@deepseek-ai/dsh-credentials" "0.2.2-rc.1"
         "185dha3amrs6s9ipc6lafqjm9yiljhaakaxqcpy41vkblgn3ky89"
         "node_modules/@deepseek-ai/dsh-credentials")
   (list "@deepseek-ai/dsh-credentials-local" "0.2.2-rc.1"
         "1a0x0liavv0z8qar5ryzl27pfisnalh5b36i63jr188x47xfcnm4"
         "node_modules/@deepseek-ai/dsh-credentials-local")
   (list "@deepseek-ai/dsh-deepseek-account" "0.2.2-rc.1"
         "0zcigvcgg594psdp50yzkb0f1jxxm128zp7qyhb92sb1ylga9lyn"
         "node_modules/@deepseek-ai/dsh-deepseek-account")
   (list "@deepseek-ai/dsh-deepseek-account-platform" "0.2.2-rc.1"
         "0b0xqyrnd4mj8qnfak9iqasv2y9bn5d8a7nxr2kv68lijx4gzj4j"
         "node_modules/@deepseek-ai/dsh-deepseek-account-platform")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-deepseek-account-platform/node_modules/zod")
   (list "@deepseek-ai/dsh-deepseek-llm-api-extensions" "0.2.2-rc.1"
         "0a68fz6amw99q2l6kxadvfzs1cpwri8nbv7f322kc4kppypqhxj8"
         "node_modules/@deepseek-ai/dsh-deepseek-llm-api-extensions")
   (list "@deepseek-ai/dsh-deliverable-file-references" "0.2.2-rc.1"
         "06cwnvki12fsyy4cgaqbxfpkpp69mvz12agzwb9vs5xp4rx90n9s"
         "node_modules/@deepseek-ai/dsh-deliverable-file-references")
   (list "@deepseek-ai/dsh-deque" "0.2.2-rc.1"
         "0zjg3h2c43056cwi1xg9llf48l1ia3q4pd6bw00vi0bfmn17nf1f"
         "node_modules/@deepseek-ai/dsh-deque")
   (list "@deepseek-ai/dsh-experimental-agent-team" "0.2.2-rc.1"
         "1xs0xxcsm89rz9vmvx77jabrf03zfx9866iw6bmzsmqs5f64pn61"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team")
   (list "@deepseek-ai/dsh-experimental-agent-team-profile" "0.2.2-rc.1"
         "0r1yvnb53r9dwdr8y0w37vs4ypjaf7hd8xm4rlp991zibpgjdqrf"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team-profile")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-agent-team/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-api-speech-to-text" "0.2.2-rc.1"
         "0pdkcxq23rmp6226cwpsjkfw4y6f01kc6plxwglv487iha1n8n39"
         "node_modules/@deepseek-ai/dsh-experimental-api-speech-to-text")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-api-speech-to-text/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-auto-review" "0.2.2-rc.1"
         "0xq8ikimsi073jwk00rnmhqd8wq9lv29vn68vk3cvxqzllwmpv8y"
         "node_modules/@deepseek-ai/dsh-experimental-auto-review")
   (list "@deepseek-ai/dsh-experimental-badge-skill-bundle" "0.2.2-rc.1"
         "19d3cx15im28p506agl4hgnmpyg1af11dpf60fp158aq1hr9qbpi"
         "node_modules/@deepseek-ai/dsh-experimental-badge-skill-bundle")
   (list "@deepseek-ai/dsh-experimental-client-ui-agent-team" "0.2.2-rc.1"
         "0y83gssf0rdiwwagm6qi5bzcdy1jqm7ribha3ra56pr6gx4i7yi3"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-agent-team")
   (list "@deepseek-ai/dsh-experimental-client-ui-cot-translation" "0.2.2-rc.1"
         "1xcpwjpggagjksikxmmh7jgq93y78g96k05lkpnv6hxwx4cn0psc"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-cot-translation")
   (list "@deepseek-ai/dsh-experimental-client-ui-forge" "0.2.2-rc.1"
         "1afxx2yaf8j29rp6lpb81arv7f9m6swpnb24wykx5j0hw9x6njwk"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-forge")
   (list "@deepseek-ai/dsh-experimental-client-ui-stats" "0.2.2-rc.1"
         "00vnbixyy17vwxb7jgcx2vcynzqy673197gb7q4cawbhn90lcymq"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-stats")
   (list "@deepseek-ai/dsh-experimental-client-ui-voice-input" "0.2.2-rc.1"
         "1wcb8az0qkwcz21gjq1rp4b3765kjdb2p7a6dsilg33nhg8mx35w"
         "node_modules/@deepseek-ai/dsh-experimental-client-ui-voice-input")
   (list "@deepseek-ai/dsh-experimental-cot-translation-bundle" "0.2.2-rc.1"
         "15vl11cz73wndxc4kflhq1sdc5gr3p6yc0bxnzq0q87v7fk3qab0"
         "node_modules/@deepseek-ai/dsh-experimental-cot-translation-bundle")
   (list "@deepseek-ai/dsh-experimental-forge" "0.2.2-rc.1"
         "1khfv628nxz8gnbdb2q40rmyzy6280nhmbqnmzkh705m7vw8gvcs"
         "node_modules/@deepseek-ai/dsh-experimental-forge")
   (list "@deepseek-ai/dsh-experimental-forge-bundle" "0.2.2-rc.1"
         "10pa23kf4awba2qjl8scpn8hfw2rkqqmxpjvwjd37i1z7wwxm99q"
         "node_modules/@deepseek-ai/dsh-experimental-forge-bundle")
   (list "@deepseek-ai/dsh-experimental-forge-github" "0.2.2-rc.1"
         "13brrnir0qiwqim26mp1bi7ac0512q8lndizagiyk4kq9v8fkqrx"
         "node_modules/@deepseek-ai/dsh-experimental-forge-github")
   (list "@deepseek-ai/dsh-experimental-forge-session" "0.2.2-rc.1"
         "1wnjad3w5ggxv8sy223fv3akyvfb9d0hkas6pymr55s03pfhhvyk"
         "node_modules/@deepseek-ai/dsh-experimental-forge-session")
   (list "@deepseek-ai/dsh-experimental-inspector" "0.2.2-rc.1"
         "027260l11wxjfwcaq1fjn0w6zixz7jjhw5y549r19xp76dqj39r8"
         "node_modules/@deepseek-ai/dsh-experimental-inspector")
   (list "@deepseek-ai/dsh-experimental-inspector-profile" "0.2.2-rc.1"
         "0ylxqrmpk4qs51jinqy712i2rp3rc3gyvw8b73p5pq11zq0zbhvf"
         "node_modules/@deepseek-ai/dsh-experimental-inspector-profile")
   (list "@deepseek-ai/dsh-experimental-liveshare" "0.2.2-rc.1"
         "0hr89yb49ibgd61n3aq88pdv7h1ksi113f9c5mx4bykqx17vbhli"
         "node_modules/@deepseek-ai/dsh-experimental-liveshare")
   (list "@deepseek-ai/dsh-experimental-liveshare-protocol" "0.2.2-rc.1"
         "16649ln6lb7dns8877ljvfk0ygpkbvkrdbj65zvvzn5dhn0sn59a"
         "node_modules/@deepseek-ai/dsh-experimental-liveshare-protocol")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-liveshare/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-plugin-market-bundle" "0.2.2-rc.1"
         "0w5n8rv93jd6xm1zny7vvbj4xby4ax93d0lib3rvnjwmkx3i04yj"
         "node_modules/@deepseek-ai/dsh-experimental-plugin-market-bundle")
   (list "@deepseek-ai/dsh-experimental-ralph-bundle" "0.2.2-rc.1"
         "1fnz870j6vb9wkd9jz5ki0fcnbh6sbwmpl92ss0aaf9k5ijfdz4k"
         "node_modules/@deepseek-ai/dsh-experimental-ralph-bundle")
   (list "@deepseek-ai/dsh-experimental-session-inspector" "0.2.2-rc.1"
         "0fv0s9p6vvwbpw8mdys1pjx9gnd944sj35yvabhpa5z1vssbnlrq"
         "node_modules/@deepseek-ai/dsh-experimental-session-inspector")
   (list "@deepseek-ai/dsh-experimental-session-search" "0.2.2-rc.1"
         "1lds0w8rds6kq3pih48306py6xcwghcqv9kz5ydx4dbyp011v9gi"
         "node_modules/@deepseek-ai/dsh-experimental-session-search")
   (list "@deepseek-ai/dsh-experimental-session-titles-bundle" "0.2.2-rc.1"
         "17cghkm911imfc9kccp5cimhjl2rkihk9jzgmfkic2cj01drmi92"
         "node_modules/@deepseek-ai/dsh-experimental-session-titles-bundle")
   (list "@deepseek-ai/dsh-experimental-speech-to-text" "0.2.2-rc.1"
         "07jshr8n456sbk2k4bnzhsaaf6b5vqngmbcsx696ax3dj74rap68"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text")
   (list "@deepseek-ai/dsh-experimental-speech-to-text-sensevoice" "0.2.2-rc.1"
         "0f9ks29g1i3m3df2vzcfkfp7phszii4v1bjj5bl3l7kzx3w3f9mx"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text-sensevoice")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-experimental-speech-to-text-sensevoice/node_modules/zod")
   (list "@deepseek-ai/dsh-experimental-terminal-bundle" "0.2.2-rc.1"
         "1h2ny63ikwhqzsrllp0brgc84n7h4dvfm3wnkji11pw2wd1sw8x1"
         "node_modules/@deepseek-ai/dsh-experimental-terminal-bundle")
   (list "@deepseek-ai/dsh-experimental-tool-agent-team" "0.2.2-rc.1"
         "08pw6nzjbp9jpn6iifp1h74m2ws1fsj7zh8cs3d4jqbkxy9f78ii"
         "node_modules/@deepseek-ai/dsh-experimental-tool-agent-team")
   (list "@deepseek-ai/dsh-experimental-tool-worktree" "0.2.2-rc.1"
         "0hd290fmf254n6dcl779qqr52cdkij2yn2x923yd4xgphq5x3vgv"
         "node_modules/@deepseek-ai/dsh-experimental-tool-worktree")
   (list "@deepseek-ai/dsh-experimental-translator" "0.2.2-rc.1"
         "12sinmr6i3idh2mc4lifjdl901wzqdmbcxb0yfwyg70cbyg467c6"
         "node_modules/@deepseek-ai/dsh-experimental-translator")
   (list "@deepseek-ai/dsh-experimental-voice-input-bundle" "0.2.2-rc.1"
         "0qynig4harkyin42q15rprxg45x2hralxwapfb4nsnmdh9f24n4x"
         "node_modules/@deepseek-ai/dsh-experimental-voice-input-bundle")
   (list "@deepseek-ai/dsh-experimental-worktree" "0.2.2-rc.1"
         "0m9nb6z9h820wnpmcfcfipcw67335hzz70n78fkyic8avxkwz4fn"
         "node_modules/@deepseek-ai/dsh-experimental-worktree")
   (list "@deepseek-ai/dsh-file-reference" "0.2.2-rc.1"
         "1sjjcxnp2g8f9m811gwg1772lhzjnfwkj4fp5h87cyzavxv7vxxp"
         "node_modules/@deepseek-ai/dsh-file-reference")
   (list "@deepseek-ai/dsh-file-reference-local" "0.2.2-rc.1"
         "1441269nigisjs5sb7la789bd0vjlv4jnqacaw0qsy3zk1l2yhf9"
         "node_modules/@deepseek-ai/dsh-file-reference-local")
   (list "@deepseek-ai/dsh-fs" "0.2.2-rc.1"
         "1djbw4xg59n1fjvxxgwlg42k4z1vdzhpl4kmxy0cmmvmshr7a65h"
         "node_modules/@deepseek-ai/dsh-fs")
   (list "@deepseek-ai/dsh-fs-local" "0.2.2-rc.1"
         "0qbfs475xd5nkzyj9yh55bjiw681pz4i6inhkv0zbs36dh219j3l"
         "node_modules/@deepseek-ai/dsh-fs-local")
   (list "@deepseek-ai/dsh-fs-observation-policy" "0.2.2-rc.1"
         "1y0flybz17xjcs7zvvx5crvnc4rfs964ykxksgpyagswhx12q48m"
         "node_modules/@deepseek-ai/dsh-fs-observation-policy")
   (list "@deepseek-ai/dsh-fs-patch" "0.2.2-rc.1"
         "1qd31idmwnikrmq8fv13rpcfzgrv2qvpjidna78m0sv3rsaxjpsz"
         "node_modules/@deepseek-ai/dsh-fs-patch")
   (list "@deepseek-ai/dsh-fs-sandbox" "0.2.2-rc.1"
         "0y9ljw08g9b9xhf9qdpyjfipkli0ixlcv4c1392d3xnqfs27nmjw"
         "node_modules/@deepseek-ai/dsh-fs-sandbox")
   (list "@deepseek-ai/dsh-goal" "0.2.2-rc.1"
         "0fxywlyyjihlimf6kgf2s3i24wnr35zyiszh1s1w46fcsjsr1rb2"
         "node_modules/@deepseek-ai/dsh-goal")
   (list "@deepseek-ai/dsh-goal-round-driver" "0.2.2-rc.1"
         "10r5n11c1ds25j9zrdqajcvgxlgr5z74i7c49785v1mil8fca4dv"
         "node_modules/@deepseek-ai/dsh-goal-round-driver")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-goal/node_modules/zod")
   (list "@deepseek-ai/dsh-harness-dev-context" "0.2.2-rc.1"
         "0i2y776x7zhizxmsapbjc4dl920ignnki0sn4iwbs93irqwj2h70"
         "node_modules/@deepseek-ai/dsh-harness-dev-context")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-harness-dev-context/node_modules/zod")
   (list "@deepseek-ai/dsh-headless" "0.2.2-rc.1"
         "1788ps9f9r4qdw3m3rhna6s13imz6xw263gx456mk9lx5q256xri"
         "node_modules/@deepseek-ai/dsh-headless")
   (list "@deepseek-ai/dsh-hmr" "0.2.2-rc.1"
         "19anj7fnzfr8z8dgmhrhn0ppq0y2m8724mz8gqsq0azkglbbpbql"
         "node_modules/@deepseek-ai/dsh-hmr")
   (list "@deepseek-ai/dsh-home-paths" "0.2.2-rc.1"
         "0dfyc3hannd7rlyc436xql7wbchabsci57vq1krklk6ddgmb7q51"
         "node_modules/@deepseek-ai/dsh-home-paths")
   (list "@deepseek-ai/dsh-host-directory-picker" "0.2.2-rc.1"
         "18riqhxz1ylkykyb6hnc90n0srq9kf5zwnbx1nms7146gnl0b3v4"
         "node_modules/@deepseek-ai/dsh-host-directory-picker")
   (list "@deepseek-ai/dsh-host-directory-picker-auto" "0.2.2-rc.1"
         "1w5nvrj5b9plj2z05q3zq7jpmkik6ibk1f23c488davw00ywhjpx"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-auto")
   (list "@deepseek-ai/dsh-host-directory-picker-browse" "0.2.2-rc.1"
         "070v1habp9w6g4l79z9kw6wwfpmazg5q7y5v7ia1drwabhdf4bfj"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-browse")
   (list "@deepseek-ai/dsh-host-directory-picker-native" "0.2.2-rc.1"
         "13yqf1ccpw2zgys5kcyhjpi9mnaqh40x67pwwwspgmw1i84b50m6"
         "node_modules/@deepseek-ai/dsh-host-directory-picker-native")
   (list "@deepseek-ai/dsh-host-frontend-static" "0.2.2-rc.1"
         "03w56kf0ffs80l02ip5x5wcg4849zq8j5l4ajknlhhj9fdfkhk2z"
         "node_modules/@deepseek-ai/dsh-host-frontend-static")
   (list "@deepseek-ai/dsh-host-open-in-app" "0.2.2-rc.1"
         "0w5m7062lmcslpz7bya3vvim7xhqpvqj7v3ysb8pahc36dpxjbq3"
         "node_modules/@deepseek-ai/dsh-host-open-in-app")
   (list "@deepseek-ai/dsh-host-plugin-inventory" "0.2.2-rc.1"
         "16n0f9qgfsnklnmc3z5k1n5r2cc253yc13v0j93ww87wy5sw8m4d"
         "node_modules/@deepseek-ai/dsh-host-plugin-inventory")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-host-plugin-inventory/node_modules/zod")
   (list "@deepseek-ai/dsh-host-product-telemetry-otel" "0.2.2-rc.1"
         "1kkw5d006c2idr1k7k06q485fxrbnfxxxhg4mp91m9jhq42fvw2a"
         "node_modules/@deepseek-ai/dsh-host-product-telemetry-otel")
   (list "@deepseek-ai/dsh-host-webserver" "0.2.2-rc.1"
         "0d4izm0v70r3p55w7fhai903zl5s2ks22b1f2hx71yr96zvai5hr"
         "node_modules/@deepseek-ai/dsh-host-webserver")
   (list "@deepseek-ai/dsh-http-proxy" "0.2.2-rc.1"
         "1fzxf5jv0wcwhq4mm81fiq3x64gzvpplfd834pgf8jwk47fxnxwk"
         "node_modules/@deepseek-ai/dsh-http-proxy")
   (list "@deepseek-ai/dsh-jobs" "0.2.2-rc.1"
         "00pnawgd7ccf7n8fjfy7f4w9vznjsax17yix4mm8yrw6ajm1i9y9"
         "node_modules/@deepseek-ai/dsh-jobs")
   (list "@deepseek-ai/dsh-jobs-local" "0.2.2-rc.1"
         "1pi22nzymyikgk01jmrn368j3iyw74d61yjkchw6p7msd5wb34g4"
         "node_modules/@deepseek-ai/dsh-jobs-local")
   (list "@deepseek-ai/dsh-launch-environment" "0.2.2-rc.1"
         "1cwfymj95mk46l0cazvf76ivihaybx7qwavz8p4dxzadkwh46imw"
         "node_modules/@deepseek-ai/dsh-launch-environment")
   (list "@deepseek-ai/dsh-lazy-require" "0.2.2-rc.1"
         "0zky5vgriqy7b8pnbvkzmm28y097yjyv43r7mp9xc6bigrc2cwzr"
         "node_modules/@deepseek-ai/dsh-lazy-require")
   (list "@deepseek-ai/dsh-llm" "0.2.2-rc.1"
         "1m057ch4ws0i9jr8zps9n38c5a27m0l4jlfyhxly4qzgscwm1x6b"
         "node_modules/@deepseek-ai/dsh-llm")
   (list "@deepseek-ai/dsh-llm-deepseek" "0.2.2-rc.1"
         "0fy6nh02078m7akxgli6ga4n708iphlw7kx5a78w9kf5s18m1ff2"
         "node_modules/@deepseek-ai/dsh-llm-deepseek")
   (list "@deepseek-ai/dsh-llm-deepseek-account" "0.2.2-rc.1"
         "0kyp2jzwc6x9xxgrgsc0w6l4yw0k28qpni50xblfipssw1lb1qdk"
         "node_modules/@deepseek-ai/dsh-llm-deepseek-account")
   (list "@deepseek-ai/dsh-llm-deepseek-api-key" "0.2.2-rc.1"
         "0idb9d1fa7akky01hs5n9mlsq6zjyjj6020wqyz16nbmlnr92r9a"
         "node_modules/@deepseek-ai/dsh-llm-deepseek-api-key")
   (list "@deepseek-ai/dsh-llm-pi-ai" "0.2.2-rc.1"
         "0pqymkp7lknlrxj02pn5c1cv45ksdks0l5wjbdvw6m2kk2l8705p"
         "node_modules/@deepseek-ai/dsh-llm-pi-ai")
   (list "@deepseek-ai/dsh-llm-retry" "0.2.2-rc.1"
         "1iz5pzs3q1niv602dzrn6idx80p4bmq5b8163zb0y0kvagnwxkbd"
         "node_modules/@deepseek-ai/dsh-llm-retry")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-llm-retry/node_modules/zod")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-llm/node_modules/zod")
   (list "@deepseek-ai/dsh-mcp-client" "0.2.2-rc.1"
         "1x8992jnw4a4h2ca1738kpw4mllxiwh9xmyaz72ikvxvkvkipxc6"
         "node_modules/@deepseek-ai/dsh-mcp-client")
   (list "@deepseek-ai/dsh-mcp-resources" "0.2.2-rc.1"
         "0r3sh31z80zib0rysv4p6807rv4lxmwzphcb3jaj5xpkiklv6n3h"
         "node_modules/@deepseek-ai/dsh-mcp-resources")
   (list "@deepseek-ai/dsh-message-feedback" "0.2.2-rc.1"
         "0dy7abahgs9d23bns0sibs84b3s7wrg7bv3nqw37p069mwjf6isa"
         "node_modules/@deepseek-ai/dsh-message-feedback")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-message-feedback/node_modules/zod")
   (list "@deepseek-ai/dsh-message-quotes" "0.2.2-rc.1"
         "04gr71k9mh1ii76izmkl0hq87hbcfkpbhp1wg3x1wbicckha7jy4"
         "node_modules/@deepseek-ai/dsh-message-quotes")
   (list "@deepseek-ai/dsh-native-command" "0.2.2-rc.1"
         "0y2dkkzk8mffzmrmzdr6s196dqwm7p1gp8ndyir3y249gl63w5ns"
         "node_modules/@deepseek-ai/dsh-native-command")
   (list "@deepseek-ai/dsh-office-to-pdf" "0.2.2-rc.1"
         "1hvv4zihpfd4n3srcg942bsg38bixbc2iphyhiq535zskllmysyz"
         "node_modules/@deepseek-ai/dsh-office-to-pdf")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-office-to-pdf/node_modules/zod")
   (list "@deepseek-ai/dsh-official-bundles" "0.2.2-rc.1"
         "0cklw100xh8zpcm8yi7ym1fylkkx6b91bjkapgc00pc6cv8xhizm"
         "node_modules/@deepseek-ai/dsh-official-bundles")
   (list "@deepseek-ai/dsh-otel" "0.2.2-rc.1"
         "1ddjvbvigj9xkw5wpnl14p3zjjjmrf9cpj7s0fcvs49kqbdf0fnz"
         "node_modules/@deepseek-ai/dsh-otel")
   (list "@deepseek-ai/dsh-output-retention" "0.2.2-rc.1"
         "0ajf4hp7jfw8r2fdl275vbi9yqzgnd3wr8amgfl4lc46zqd964nv"
         "node_modules/@deepseek-ai/dsh-output-retention")
   (list "@deepseek-ai/dsh-package-manifest" "0.2.2-rc.1"
         "0qr981hkd4p4c626m1srkwnrs96rjj1ahahnzh62lc27bg854c47"
         "node_modules/@deepseek-ai/dsh-package-manifest")
   (list "@deepseek-ai/dsh-permission-presets" "0.2.2-rc.1"
         "0p0snd96nafcwvj04z9059g6y84m65q4871w39bmw4k2i8vd4s5h"
         "node_modules/@deepseek-ai/dsh-permission-presets")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-permission-presets/node_modules/zod")
   (list "@deepseek-ai/dsh-persona" "0.2.2-rc.1"
         "1s1rifsv0s5plyhxvlqj7hwhkba69f31izr0pgjvzj2ch1jak8jm"
         "node_modules/@deepseek-ai/dsh-persona")
   (list "@deepseek-ai/dsh-personalized-recommendations" "0.2.2-rc.1"
         "0h2viicr454c7p7rn2k00djmnf8i1qpai16ypijjdw914wc7h2v1"
         "node_modules/@deepseek-ai/dsh-personalized-recommendations")
   (list "@deepseek-ai/dsh-plan-mode" "0.2.2-rc.1"
         "0ghsi7gmqj54aaisfwfbrm0ch0qc79qmxn62baaxi94ha1bnsh9m"
         "node_modules/@deepseek-ai/dsh-plan-mode")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-plan-mode/node_modules/zod")
   (list "@deepseek-ai/dsh-plugin-detail" "0.2.2-rc.1"
         "0kz1znnrcmjs4ri2mmabd0xp2d4ahl9idhy7bln7q058xb0ky514"
         "node_modules/@deepseek-ai/dsh-plugin-detail")
   (list "@deepseek-ai/dsh-plugin-manager" "0.2.2-rc.1"
         "0z337pww1av8zkzm4c6d69kg4w0jfi4ahn3acyv57grw7aqvxnzd"
         "node_modules/@deepseek-ai/dsh-plugin-manager")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-plugin-manager/node_modules/zod")
   (list "@deepseek-ai/dsh-plugin-market" "0.2.2-rc.1"
         "06ra43pnnma3nwh409bj4yyha1ngawggx83f7r0pyfk8gzwk6vsf"
         "node_modules/@deepseek-ai/dsh-plugin-market")
   (list "@deepseek-ai/dsh-plugin-market-index" "0.2.2-rc.1"
         "0mg0sc20wnqcjm4rxv5vrbcymc6mqldwlbn86d1psgpiylx5q5r2"
         "node_modules/@deepseek-ai/dsh-plugin-market-index")
   (list "@deepseek-ai/dsh-plugin-package-inventory-deepseek" "0.2.2-rc.1"
         "1vsm3i657ypkgak8s0pz12qdzi60kc1qvsgly6r8hrp6v27sq1wk"
         "node_modules/@deepseek-ai/dsh-plugin-package-inventory-deepseek")
   (list "@deepseek-ai/dsh-plugin-recommendations" "0.2.2-rc.1"
         "0jhrzhavfpm4s8d0rg8q7h4ap7awzjiq4dwrfqx99sa961g0f4qw"
         "node_modules/@deepseek-ai/dsh-plugin-recommendations")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-plugin-recommendations/node_modules/zod")
   (list "@deepseek-ai/dsh-ptc-runtime" "0.2.2-rc.1"
         "1ps30v2skggp5r9bzx014fdmihxd84hl0cyp5p8d4cmw31l3clxl"
         "node_modules/@deepseek-ai/dsh-ptc-runtime")
   (list "@deepseek-ai/dsh-ptc-runtime-node" "0.2.2-rc.1"
         "174hs9d7yyl22sscxfddfjsndzg02mpgjzrjlvlgl5f6x4b3nswa"
         "node_modules/@deepseek-ai/dsh-ptc-runtime-node")
   (list "@deepseek-ai/dsh-pwsh-local" "0.2.2-rc.1"
         "1dcxcqmclpgvixidzp3zvahhnxd1w5h5pr8s0pmdf6mgjncqr36k"
         "node_modules/@deepseek-ai/dsh-pwsh-local")
   (list "@deepseek-ai/dsh-pwsh-sandbox" "0.2.2-rc.1"
         "04y2da761kw57w1adp1zfkn7rpzzp5ldpcasrc18p9km6b5fx8x0"
         "node_modules/@deepseek-ai/dsh-pwsh-sandbox")
   (list "@deepseek-ai/dsh-repeat-tool-reminder" "0.2.2-rc.1"
         "0472n66zf524vd9gvi1hfavjjj13y1q75szsq99g4pbydmv6hi8a"
         "node_modules/@deepseek-ai/dsh-repeat-tool-reminder")
   (list "@deepseek-ai/dsh-sandbox" "0.2.2-rc.1"
         "1na32d8hzk4svy3gj8rn720zal5hcxy59628yn6did4sbb3k2mj9"
         "node_modules/@deepseek-ai/dsh-sandbox")
   (list "@deepseek-ai/dsh-sandbox-local" "0.2.2-rc.1"
         "16gqp42bzyb7hl34qxlmk5rgmq87id4rbsx5khj0syz3qk9434m9"
         "node_modules/@deepseek-ai/dsh-sandbox-local")
   (list "@deepseek-ai/dsh-sandbox-policy" "0.2.2-rc.1"
         "09c84n0gzqvvp9vcqskmaphip7r3g0wyqjicdm6fbap5rpnjssyn"
         "node_modules/@deepseek-ai/dsh-sandbox-policy")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-sandbox-policy/node_modules/zod")
   (list "@deepseek-ai/dsh-sandbox-windows-acl" "0.2.2-rc.1"
         "092iiz03c44cbpni9chfbbsv829chx2yyihyv98g68brh8p7lkr9"
         "node_modules/@deepseek-ai/dsh-sandbox-windows-acl")
   (list "@deepseek-ai/dsh-schedule" "0.2.2-rc.1"
         "06ysjnhrrl81pg0i52pv5bq0akdpl2sgb9x83dkvhbkvxh4djj48"
         "node_modules/@deepseek-ai/dsh-schedule")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-schedule/node_modules/zod")
   (list "@deepseek-ai/dsh-scope" "0.2.2-rc.1"
         "0bjl6wr8yvj6zd3rmjy23rb2mnzk1ayfbficd863jr308nvzpb7k"
         "node_modules/@deepseek-ai/dsh-scope")
   (list "@deepseek-ai/dsh-sdk-app" "0.2.2-rc.1"
         "0lxjb8v2hdn7drpr9pdfpl2wmynbjynazq0x838gjw2fyq4yvldi"
         "node_modules/@deepseek-ai/dsh-sdk-app")
   (list "@deepseek-ai/dsh-sdk-jsonrpc-server" "0.2.2-rc.1"
         "038f6gpqs266c454arcxh4gcv0zpcf4d99p8vwv9paqhi0lsgp5n"
         "node_modules/@deepseek-ai/dsh-sdk-jsonrpc-server")
   (list "@deepseek-ai/dsh-sdk-minimal" "0.2.2-rc.1"
         "0scij20p803wr62609mp09455nply3544kybrz2ym5vvq2kms1l6"
         "node_modules/@deepseek-ai/dsh-sdk-minimal")
   (list "@deepseek-ai/dsh-sdk-protocol" "0.2.2-rc.1"
         "0cj61vpg9hihjkgqy098mhdgn145qak7rj0hdqngv0q7g7jgd3yj"
         "node_modules/@deepseek-ai/dsh-sdk-protocol")
   (list "@deepseek-ai/dsh-session" "0.2.2-rc.1"
         "1dfgy7z3lny045f6gmranr11iwfxijqx6khk9jzbvvy8p6kv9cdq"
         "node_modules/@deepseek-ai/dsh-session")
   (list "@deepseek-ai/dsh-session-checkpoint-policy" "0.2.2-rc.1"
         "05mgqwz4avbvn6qkwx11sgad8f91riib2wmsq9cyx3zfpafplgkw"
         "node_modules/@deepseek-ai/dsh-session-checkpoint-policy")
   (list "@deepseek-ai/dsh-session-format" "0.2.2-rc.1"
         "0p2k28s7454m4n9s94kh6cv8qgsan7cy2ds83byx45lvqfa1bvrv"
         "node_modules/@deepseek-ai/dsh-session-format")
   (list "@deepseek-ai/dsh-session-format-catalog" "0.2.2-rc.1"
         "0n001hdw66n8zqisa6a7wiv6xjwqjfcn7jl0b25qslr0jd8nphj6"
         "node_modules/@deepseek-ai/dsh-session-format-catalog")
   (list "@deepseek-ai/dsh-session-format-v0-to-v1" "0.2.2-rc.1"
         "0xl7qhhnv626pairwajxjm02al7cli760jlrjaz2kahhz83g69xy"
         "node_modules/@deepseek-ai/dsh-session-format-v0-to-v1")
   (list "@deepseek-ai/dsh-session-format-v1-to-v2" "0.2.2-rc.1"
         "1vkjx9q6wzzzp5yxs5i6rr1hv0vf44j27al3sx6q27dan00jpcha"
         "node_modules/@deepseek-ai/dsh-session-format-v1-to-v2")
   (list "@deepseek-ai/dsh-session-format-v2-to-v3" "0.2.2-rc.1"
         "1x46a4k89kljl2sgv7xrngb1jg04xryyy4p2csnqvwbhmb5i93kh"
         "node_modules/@deepseek-ai/dsh-session-format-v2-to-v3")
   (list "@deepseek-ai/dsh-session-format-v3-to-v4" "0.2.2-rc.1"
         "0zsv6vk02h3r9fgc2gmjr2pnpqzniqcdi9p0mbv1k8mpg2a07ry8"
         "node_modules/@deepseek-ai/dsh-session-format-v3-to-v4")
   (list "@deepseek-ai/dsh-session-log-deepseek" "0.2.2-rc.1"
         "13925mrhv2sriy06jbrd7ln4laqpmhdgy6ibviy1mj5sbb2i2czk"
         "node_modules/@deepseek-ai/dsh-session-log-deepseek")
   (list "@deepseek-ai/dsh-session-log-export" "0.2.2-rc.1"
         "0qmzd4r5rj2yjxds1gjhfvj255dg9ywj0ljz2fbv0x7bflpq5v9l"
         "node_modules/@deepseek-ai/dsh-session-log-export")
   (list "@deepseek-ai/dsh-session-persistence" "0.2.2-rc.1"
         "1q15aaig0l463icvryl1kg5cd8k2p82b8z7h1l7an3chadmfcvk0"
         "node_modules/@deepseek-ai/dsh-session-persistence")
   (list "@deepseek-ai/dsh-session-persistence-jsonl" "0.2.2-rc.1"
         "14lgvasgm7x93sl1aj4jyqcj7ngjzp7dm53hws74pgvj6r3yxib3"
         "node_modules/@deepseek-ai/dsh-session-persistence-jsonl")
   (list "@deepseek-ai/dsh-session-projection" "0.2.2-rc.1"
         "1g01a8vlzkx8g1i5qw76rac7cisv4hja703c47ifkkmwfz1bsrn3"
         "node_modules/@deepseek-ai/dsh-session-projection")
   (list "@deepseek-ai/dsh-session-projection-cache" "0.2.2-rc.1"
         "0x2pv5gi68hamsj1vkwm2d6m59d8vnblymz9scvg0aq5798dmrxb"
         "node_modules/@deepseek-ai/dsh-session-projection-cache")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-projection-cache/node_modules/zod")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-projection/node_modules/zod")
   (list "@deepseek-ai/dsh-session-query" "0.2.2-rc.1"
         "1369bg5pfjiflarf0vsrjg4k8chplkm3szx1p7lfb4kl6g8rwch8"
         "node_modules/@deepseek-ai/dsh-session-query")
   (list "@deepseek-ai/dsh-session-query-sqlite" "0.2.2-rc.1"
         "1nsyl4lk0q5z4d0wr7pas4mhnmz0si6gjqpj6f7n6n2dgkm6xsyj"
         "node_modules/@deepseek-ai/dsh-session-query-sqlite")
   (list "@deepseek-ai/dsh-session-reference" "0.2.2-rc.1"
         "1hf5gmk7a8s18i8kky4pgl4zmfdvnqn35qb5ssijkhz3z7acr6a7"
         "node_modules/@deepseek-ai/dsh-session-reference")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-reference/node_modules/zod")
   (list "@deepseek-ai/dsh-session-stats" "0.2.2-rc.1"
         "1zyy08pjpag2aa1wf50cyqka3g6rigs1nq8avz7j171n9j6jclsf"
         "node_modules/@deepseek-ai/dsh-session-stats")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-stats/node_modules/zod")
   (list "@deepseek-ai/dsh-session-telemetry" "0.2.2-rc.1"
         "1bfg0ylpwjr9dfn6kk0zdb620z52qsl6lgqnd05g87v0bfja45by"
         "node_modules/@deepseek-ai/dsh-session-telemetry")
   (list "@deepseek-ai/dsh-session-telemetry-otel" "0.2.2-rc.1"
         "0fvzkdi3dx6wf4xqnwcwjk1x8b17bs6xpr13wy9mq8crpisn9cg9"
         "node_modules/@deepseek-ai/dsh-session-telemetry-otel")
   (list "@deepseek-ai/dsh-session-title" "0.2.2-rc.1"
         "0lavd2vpwlmdlwa5s9fdqj335466znzzfs4535qp6z5ff1n8l5ak"
         "node_modules/@deepseek-ai/dsh-session-title")
   (list "@deepseek-ai/dsh-session-title-all-prompts-llm" "0.2.2-rc.1"
         "1br64xhjvmjwl4hwh3i7kclv7pfbvrcg8dy9sd5ab82z983p4h4m"
         "node_modules/@deepseek-ai/dsh-session-title-all-prompts-llm")
   (list "@deepseek-ai/dsh-session-title-first-prompt-llm" "0.2.2-rc.1"
         "1cbpj9cjh54y5kxrz8lp8pxns7z5wkf9aljpnk5zmz7qggj0qhpw"
         "node_modules/@deepseek-ai/dsh-session-title-first-prompt-llm")
   (list "@deepseek-ai/dsh-session-title-llm" "0.2.2-rc.1"
         "07gyq24qkg1bcm8y99cfw3n1ggsxnlciclsi4wm3wm4nr1ayhbk5"
         "node_modules/@deepseek-ai/dsh-session-title-llm")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-title/node_modules/zod")
   (list "@deepseek-ai/dsh-session-turn-outline" "0.2.2-rc.1"
         "0vzs3gxca4jwh5ziphn8l0dd3vqr2mi5i0fp3cqr7xc9fccxx9zz"
         "node_modules/@deepseek-ai/dsh-session-turn-outline")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-session-turn-outline/node_modules/zod")
   (list "@deepseek-ai/dsh-settings" "0.2.2-rc.1"
         "0w9fnadbprq7980b53ir5h3mnnwqndhryxfv3pkchcgil5naan8c"
         "node_modules/@deepseek-ai/dsh-settings")
   (list "@deepseek-ai/dsh-shell" "0.2.2-rc.1"
         "1rn12kjjjrkqayars5cpl57wxpviv062v6i6hs3v43dlpl8yykfh"
         "node_modules/@deepseek-ai/dsh-shell")
   (list "@deepseek-ai/dsh-shell-env" "0.2.2-rc.1"
         "0ymrkx4xqbsqhvxlimqjl1jn0696pmq6piwlxflah1mw73jbwsx8"
         "node_modules/@deepseek-ai/dsh-shell-env")
   (list "@deepseek-ai/dsh-skill" "0.2.2-rc.1"
         "17zd3jixqpv22mwmxkrjwq8shk258589mmakzjbn70xz1mfbv6i8"
         "node_modules/@deepseek-ai/dsh-skill")
   (list "@deepseek-ai/dsh-skill-badge" "0.2.2-rc.1"
         "11gnkfzsqrj9krcfd9939k9ib7yvfsmc0fs8qf7bx70lqxdflbyc"
         "node_modules/@deepseek-ai/dsh-skill-badge")
   (list "@deepseek-ai/dsh-skill-filesystem" "0.2.2-rc.1"
         "0v7dclqv2xnv208nc1y6dq5ajr9bs2b1zb3ibynpn7y3qkm5j862"
         "node_modules/@deepseek-ai/dsh-skill-filesystem")
   (list "@deepseek-ai/dsh-skill-office" "0.2.2-rc.1"
         "07irz4cbgp87c8w9x5lahm9qkbccy38n8614dir4qa36h7d3acp9"
         "node_modules/@deepseek-ai/dsh-skill-office")
   (list "@deepseek-ai/dsh-spill" "0.2.2-rc.1"
         "0fh5rzmcfz43a0zn23xv6nap6fkmsnkl1vsmxhna4l21sakvzgqz"
         "node_modules/@deepseek-ai/dsh-spill")
   (list "@deepseek-ai/dsh-spill-local" "0.2.2-rc.1"
         "01vnhvsqil8nsyy6vid07rw23l90ay1m48mlnkk9k4jpphhlvj56"
         "node_modules/@deepseek-ai/dsh-spill-local")
   (list "@deepseek-ai/dsh-spill-policy" "0.2.2-rc.1"
         "125rcchbkqff8x3lvgnlffmlsc9mg8rf9zw7pzj9xj47i8ma1fnl"
         "node_modules/@deepseek-ai/dsh-spill-policy")
   (list "@deepseek-ai/dsh-storage" "0.2.2-rc.1"
         "15bx81kaviw2nvcgiicgzp9sjf2g6h3pyjvhk5mgpnriika1zpnj"
         "node_modules/@deepseek-ai/dsh-storage")
   (list "@deepseek-ai/dsh-storage-domain" "0.2.2-rc.1"
         "06n52i59wz40dkhk996daqmsxl01anf3p73vkyfic835b5vkh73m"
         "node_modules/@deepseek-ai/dsh-storage-domain")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-storage-domain/node_modules/zod")
   (list "@deepseek-ai/dsh-storage-json" "0.2.2-rc.1"
         "1zxzys6xxqhggpxnzqw2brzf1z2lyczgjp6m1xqg0yp5k2hajvs0"
         "node_modules/@deepseek-ai/dsh-storage-json")
   (list "@deepseek-ai/dsh-subagent" "0.2.2-rc.1"
         "0ihxy6zlg8ajpxs3pc815yscskfgnmbsld3rmwbl9kdjb14ijh2k"
         "node_modules/@deepseek-ai/dsh-subagent")
   (list "@deepseek-ai/dsh-subagent-fork-in-process" "0.2.2-rc.1"
         "05dg7lvv0q59qn8j99xlk0a2yy2kja51mwglik8dqvmklg1433n7"
         "node_modules/@deepseek-ai/dsh-subagent-fork-in-process")
   (list "@deepseek-ai/dsh-subagent-spawn-in-process" "0.2.2-rc.1"
         "15h5vwwi90g2ma5lmadp2gca2gdnqahrn9k68xxghpb23s92awzn"
         "node_modules/@deepseek-ai/dsh-subagent-spawn-in-process")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-subagent/node_modules/zod")
   (list "@deepseek-ai/dsh-subprocess" "0.2.2-rc.1"
         "1nwsjy8ab2jwq92j0bcn44riha5kxsyzcqcff116imj3v67zjp36"
         "node_modules/@deepseek-ai/dsh-subprocess")
   (list "@deepseek-ai/dsh-subprocess-local" "0.2.2-rc.1"
         "15xfsklsxv714imw42r3z4xvhkx85mkp28y6d30cqd4g0wkswamc"
         "node_modules/@deepseek-ai/dsh-subprocess-local")
   (list "@deepseek-ai/dsh-system-prompt" "0.2.2-rc.1"
         "1a82zqwmmva6cvd52p85r3acvr8wgy8yzh92ghl3gh7hy8pkzjsy"
         "node_modules/@deepseek-ai/dsh-system-prompt")
   (list "@deepseek-ai/dsh-terminal" "0.2.2-rc.1"
         "11iki24kwiyk8dag876i1pkahv6sdxfkhhv3drpmkgnirfl1ihsy"
         "node_modules/@deepseek-ai/dsh-terminal")
   (list "@deepseek-ai/dsh-terminal-bash" "0.2.2-rc.1"
         "02vfwqpxghxizlyspkfdrlfzxycsky8lx8jnvlzwj8b242ql1k1r"
         "node_modules/@deepseek-ai/dsh-terminal-bash")
   (list "@deepseek-ai/dsh-time-context" "0.2.2-rc.1"
         "1qb1hvixcsx8a7dci8pl938zmbscw5273319ni3wg72wjwwvgvq7"
         "node_modules/@deepseek-ai/dsh-time-context")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-time-context/node_modules/zod")
   (list "@deepseek-ai/dsh-timeout" "0.2.2-rc.1"
         "06qbkl0ira5a1aigfhlqz4fmiwfylk984a6v0b9in1vyqqrjbb24"
         "node_modules/@deepseek-ai/dsh-timeout")
   (list "@deepseek-ai/dsh-tmux-context" "0.2.2-rc.1"
         "1w07rhc1nn2jc0g46g1xcz6hpmj6zslc4hfnfnpsbms8ckr6fzfh"
         "node_modules/@deepseek-ai/dsh-tmux-context")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-tmux-context/node_modules/zod")
   (list "@deepseek-ai/dsh-token-meter" "0.2.2-rc.1"
         "1501qgyvblwx51v1hqsd9cg4jnbyv42chiabd2wpmxb8d2ns3y03"
         "node_modules/@deepseek-ai/dsh-token-meter")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-token-meter/node_modules/zod")
   (list "@deepseek-ai/dsh-tool-ask-user" "0.2.2-rc.1"
         "0g8jwr3ahv4bw0hhhfmapgh3jv8d874v8j1sfx4gpajz0sjgavfg"
         "node_modules/@deepseek-ai/dsh-tool-ask-user")
   (list "@deepseek-ai/dsh-tool-bash" "0.2.2-rc.1"
         "04nzyj2cnjfi04infshglb6mnykal7irgsmscdznydhfslwvdym0"
         "node_modules/@deepseek-ai/dsh-tool-bash")
   (list "@deepseek-ai/dsh-tool-bash-persistent" "0.2.2-rc.1"
         "184n17ca558xs15rq7zfazaizkch6x3761grvya5251pnc46bbab"
         "node_modules/@deepseek-ai/dsh-tool-bash-persistent")
   (list "@deepseek-ai/dsh-tool-call-timeout-policy" "0.2.2-rc.1"
         "1af8jg92g5zvjp008qcndja79flgbdmbvlywcj928d8405a68nfx"
         "node_modules/@deepseek-ai/dsh-tool-call-timeout-policy")
   (list "@deepseek-ai/dsh-tool-cordis" "0.2.2-rc.1"
         "0v2qfh4k9qj5ifilk99hh142b5rhr2c7s97bxncw4ah32yqwyjgs"
         "node_modules/@deepseek-ai/dsh-tool-cordis")
   (list "@deepseek-ai/dsh-tool-executor-native" "0.2.2-rc.1"
         "1s7qsbhywcijnvpqawnjz8wlbwv8i6y7dsp3vv6qchsizkf1lair"
         "node_modules/@deepseek-ai/dsh-tool-executor-native")
   (list "@deepseek-ai/dsh-tool-executor-ptc" "0.2.2-rc.1"
         "1sf3l1chz5l7xicqcrh2k46xpx38a2nlbshpfrp4302bb90zvlh5"
         "node_modules/@deepseek-ai/dsh-tool-executor-ptc")
   (list "@deepseek-ai/dsh-tool-fs" "0.2.2-rc.1"
         "0g59cv7blwfnb3gjiv6n3il9raarwjihwv6spvqxxrr8h1hiqibz"
         "node_modules/@deepseek-ai/dsh-tool-fs")
   (list "@deepseek-ai/dsh-tool-fs-search" "0.2.2-rc.1"
         "1ng8ikzn617h0gkpi4a1dyql04f5h9d2k4p9hgsds3bs9sd4mban"
         "node_modules/@deepseek-ai/dsh-tool-fs-search")
   (list "@deepseek-ai/dsh-tool-goal" "0.2.2-rc.1"
         "1ml3w12s7b4iqxr1lff6ny1fxl7q2hqbbqb851dygdfzalw2l37n"
         "node_modules/@deepseek-ai/dsh-tool-goal")
   (list "@deepseek-ai/dsh-tool-jobs" "0.2.2-rc.1"
         "1rjvskm53917w5k1a2l6d5fvcmxjcjvk8f7qhqinw812a07czrby"
         "node_modules/@deepseek-ai/dsh-tool-jobs")
   (list "@deepseek-ai/dsh-tool-present" "0.2.2-rc.1"
         "0g4nsb55zv4zdqim76yv0p4h9kw0kcvj925yl392m5qbglkkqlwn"
         "node_modules/@deepseek-ai/dsh-tool-present")
   (list "@deepseek-ai/dsh-tool-pwsh" "0.2.2-rc.1"
         "0q6nqhkqp1mmz7w14fdvml04rhp6zqdh7i9dk5d708f9c5r33pi5"
         "node_modules/@deepseek-ai/dsh-tool-pwsh")
   (list "@deepseek-ai/dsh-tool-pwsh-persistent" "0.2.2-rc.1"
         "00igbz60aijyj0y116mbswjgs06jr4p52w19mkx0wd8rr00pdbcs"
         "node_modules/@deepseek-ai/dsh-tool-pwsh-persistent")
   (list "@deepseek-ai/dsh-tool-ralph" "0.2.2-rc.1"
         "1d9cm6rik0rilwr7z38900q0a3cnam556z61wxqi69abf188jdy0"
         "node_modules/@deepseek-ai/dsh-tool-ralph")
   (list "@deepseek-ai/dsh-tool-schedule" "0.2.2-rc.1"
         "0v2s3jni9z87sabdy2wr0i2l8j79wdv1p8wjmlf648nzv901l2yi"
         "node_modules/@deepseek-ai/dsh-tool-schedule")
   (list "@deepseek-ai/dsh-tool-session-query" "0.2.2-rc.1"
         "1ysfl746g7i76v85dbxs3d8nsbjdp0ay10x9czg8mbbybgp0l9vw"
         "node_modules/@deepseek-ai/dsh-tool-session-query")
   (list "@deepseek-ai/dsh-tool-skill" "0.2.2-rc.1"
         "190cmi87n3rv79jr0yggh56d95avmzddiqyp28mdrcfp04s3ay7p"
         "node_modules/@deepseek-ai/dsh-tool-skill")
   (list "@deepseek-ai/dsh-tool-str-replace-editor" "0.2.2-rc.1"
         "07vgias8b1krmivk0imr1b5dskspa7097afv05vq9fjw5nd5pdwb"
         "node_modules/@deepseek-ai/dsh-tool-str-replace-editor")
   (list "@deepseek-ai/dsh-tool-subagent" "0.2.2-rc.1"
         "1fdj5f6yin1mk1zcvkr723c9hi53irmmj7bznv81dz8vg8hvkvs1"
         "node_modules/@deepseek-ai/dsh-tool-subagent")
   (list "@deepseek-ai/dsh-tool-subagent-control" "0.2.2-rc.1"
         "1q8qznplxrgyh80p6bklz0f8lnnlisfrl9s875ibsb1phfw9miwf"
         "node_modules/@deepseek-ai/dsh-tool-subagent-control")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-tool-subagent/node_modules/zod")
   (list "@deepseek-ai/dsh-tool-terminal" "0.2.2-rc.1"
         "0cvx8ywyna6s8p1vx15b40lddvcqz44n7v28b2acyj124i1p9bxl"
         "node_modules/@deepseek-ai/dsh-tool-terminal")
   (list "@deepseek-ai/dsh-tool-todo" "0.2.2-rc.1"
         "1vpcv09xwr9b2v9ljyymz78sjkjbn7imahhdc5wsxk8jmgsanl8q"
         "node_modules/@deepseek-ai/dsh-tool-todo")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-tool-todo/node_modules/zod")
   (list "@deepseek-ai/dsh-tool-web" "0.2.2-rc.1"
         "02xykwprvn8s68z0y47766rwiig18cxkyw8sy1ivz67zvfiqj346"
         "node_modules/@deepseek-ai/dsh-tool-web")
   (list "@deepseek-ai/dsh-tool-workflow" "0.2.2-rc.1"
         "1d4wzz84sxghdavw63rn07z2fnbh7q25kw68xpdhs079r5m5mbmh"
         "node_modules/@deepseek-ai/dsh-tool-workflow")
   (list "@deepseek-ai/dsh-tool-working-directory" "0.2.2-rc.1"
         "149vx5k3bl0a0bsx2akd7q9xv9k5gszifsabxcx8v6jsrik59swd"
         "node_modules/@deepseek-ai/dsh-tool-working-directory")
   (list "@deepseek-ai/dsh-tool-workspace-dependencies" "0.2.2-rc.1"
         "1gfrd3jybb1xa1432ji8x2nc7bnz8r16z5vjx5ah80yb5c925y1z"
         "node_modules/@deepseek-ai/dsh-tool-workspace-dependencies")
   (list "@deepseek-ai/dsh-tools" "0.2.2-rc.1"
         "0wnssr7mvrmpxrncm82zi65jcjq8lwgnlk35s3ifzlypgc1yx55v"
         "node_modules/@deepseek-ai/dsh-tools")
   (list "@deepseek-ai/dsh-typert-loader" "0.2.2-rc.1"
         "0qc1n982v6m7mzwmwaz377h6s8ds1bybjnlhb3yixvdjc9xc0fmq"
         "node_modules/@deepseek-ai/dsh-typert-loader")
   (list "@deepseek-ai/dsh-typert-protocol" "0.2.2-rc.1"
         "1syahab7knx9wj3p4pwpkmaspgwgz6ma94x6mfhwbzcnq05vdm1i"
         "node_modules/@deepseek-ai/dsh-typert-protocol")
   (list "@deepseek-ai/dsh-typert-registry" "0.2.2-rc.1"
         "0wilq2d36q6mw5i4k9zl1r9kbdwfc6y9ifd96lngwm2yjlg4l3jl"
         "node_modules/@deepseek-ai/dsh-typert-registry")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-typert-registry/node_modules/zod")
   (list "@deepseek-ai/dsh-user-approval" "0.2.2-rc.1"
         "0lj2g2xy4wcn7gzpz1da0xcfmb2y46y5bnn216nf97gpkqvbk4q9"
         "node_modules/@deepseek-ai/dsh-user-approval")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-user-approval/node_modules/zod")
   (list "@deepseek-ai/dsh-user-questions" "0.2.2-rc.1"
         "07mmw7zffjib8k43bffjj3l8ri0522yp4ln99riw1agy6j1c7hg7"
         "node_modules/@deepseek-ai/dsh-user-questions")
   (list "zod" "4.4.3"
         "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"
         "node_modules/@deepseek-ai/dsh-user-questions/node_modules/zod")
   (list "@deepseek-ai/dsh-util-code-language" "0.2.2-rc.1"
         "0sf3n1kwhirmamviz5nq981yd4q95bardrzx88bkd0mnbxh7lkqx"
         "node_modules/@deepseek-ai/dsh-util-code-language")
   (list "@deepseek-ai/dsh-util-crypto" "0.2.2-rc.1"
         "0sja3qyrqw7gc8lscp9pzji956hkn4r5vgfpy4135j40sbz0vvy9"
         "node_modules/@deepseek-ai/dsh-util-crypto")
   (list "@deepseek-ai/dsh-util-time" "0.2.2-rc.1"
         "1vzgm8c95gy7hl9sql8bl2hnn2w4xiz8wisg58nsh9hkm9vfiq0g"
         "node_modules/@deepseek-ai/dsh-util-time")
   (list "@deepseek-ai/dsh-util-values" "0.2.2-rc.1"
         "0ngpxj0rqygs9hzkjzvagd5jd5w0zh6ws0m7vdr0viq04qy9mpp5"
         "node_modules/@deepseek-ai/dsh-util-values")
   (list "@deepseek-ai/dsh-util-workspace-path" "0.2.2-rc.1"
         "18gsn1gn9fr02xgk6csydn5jfx0q9pmvapj6p34fq9ladpkk44m9"
         "node_modules/@deepseek-ai/dsh-util-workspace-path")
   (list "@deepseek-ai/dsh-web" "0.2.2-rc.1"
         "06ykq2rpaqraga133fra2ii9xf2clqkmkf5l278nqll163ysj73m"
         "node_modules/@deepseek-ai/dsh-web")
   (list "@deepseek-ai/dsh-web-app" "0.2.2-rc.1"
         "1wzlir5dm3xa2gmnbwmha31mmq6j2i1253y1b4szp8d7h87vj621"
         "node_modules/@deepseek-ai/dsh-web-app")
   (list "@deepseek-ai/dsh-web-deepseek-api" "0.2.2-rc.1"
         "0fim56rkdb0h2pll9klmabri5mbsc4cz12sbhwqn5yyagpkcncba"
         "node_modules/@deepseek-ai/dsh-web-deepseek-api")
   (list "@deepseek-ai/dsh-web-fetch-http" "0.2.2-rc.1"
         "1kh5knk4hd2s5wrwsywiwbwhzjkqsd1pfvf7873imbqjx6l2qqh8"
         "node_modules/@deepseek-ai/dsh-web-fetch-http")
   (list "@deepseek-ai/dsh-web-frontend" "0.2.2-rc.1"
         "0gkmzpg19ahmgazjhnnb8vbs02bf98zra219nj9j7npacjdmyrdv"
         "node_modules/@deepseek-ai/dsh-web-frontend")
   (list "@deepseek-ai/dsh-web-search-deepseek" "0.2.2-rc.1"
         "1ny3r3cg3i14cwy2vimxlpqrg0mvi54nphvjcxl51n3qmnbr2sm8"
         "node_modules/@deepseek-ai/dsh-web-search-deepseek")
   (list "@deepseek-ai/dsh-win32-process" "0.2.2-rc.1"
         "1glcw7xkhm3fn8zf52xgvh4v3bp5lgjih2dzq15zljqcns3n1aj2"
         "node_modules/@deepseek-ai/dsh-win32-process")
   (list "@deepseek-ai/dsh-workflow" "0.2.2-rc.1"
         "0bm26sj5n7dssf715cg43bbhij5z1d4x4728zffmx21a6f2iwdr8"
         "node_modules/@deepseek-ai/dsh-workflow")
   (list "@deepseek-ai/dsh-workflow-ptc" "0.2.2-rc.1"
         "14h0h0xbfcj8pmsk1985jlhdnvg7klnmzl1pn3h571fahzp9mhvw"
         "node_modules/@deepseek-ai/dsh-workflow-ptc")
   (list "@deepseek-ai/dsh-working-directory" "0.2.2-rc.1"
         "17cxy1l8hcps3k3pksvy9q6gzkv609asxz1f5gya0yy3kbqk3d1d"
         "node_modules/@deepseek-ai/dsh-working-directory")
   (list "@deepseek-ai/dsh-workspace" "0.2.2-rc.1"
         "0warpxk3l46wikq1vn9n6hqbvdyim20z0apb20fdacfksyzzisiy"
         "node_modules/@deepseek-ai/dsh-workspace")
   (list "@deepseek-ai/dsh-workspace-changes" "0.2.2-rc.1"
         "1m3qhr7yvxdcv9ac4fp3543h6v53yn760b2nydxmipff00xhi4dn"
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
   (list "@deepseek-ai/schemastery" "3.19.0"
         "1q1r7r8g1k76zssp2c1cla2psb30ds62blfqqnbk8fds58aww0pp"
         "node_modules/@deepseek-ai/schemastery")
   (list "@earendil-works/pi-ai" "1.5.2"
         "1y257d9jvawgk7bidgq0j34rq5pfyjfv8hm023gvy8schgx5wwfm"
         "node_modules/@earendil-works/pi-ai")
   (list "@earendil-works/pi-schema" "1.5.2"
         "0sppgjhlyzj23bv0qky14gh99wa1mrsl95va9knw3gklzybi4daz"
         "node_modules/@earendil-works/pi-schema")
   (list "@earendil-works/pi-telemetry" "1.5.2"
         "1vprm4nhk5q5caanygqad4pxmsf14srpqp032mqsyx0chgpdna8d"
         "node_modules/@earendil-works/pi-telemetry")
   (list "@emnapi/runtime" "1.11.3"
         "0jaykdkjap399v92d0krwrc6y068vkxmr6jzsqv18mcbl09qksz6"
         "node_modules/@emnapi/runtime")
   (list "@eslint-community/regexpp" "4.12.3"
         "1j35qyazwf7f7k4f1jnvg0dyfryd6ycxnaqzqf9j9nmj3s27zig8"
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
   (list "@opentelemetry/semantic-conventions" "1.45.0"
         "1zjmx26d8m9vrfrxjdlsf931h4jgxz1pizrqgjzzkvviaymk82cg"
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
   (list "@smithy/core" "3.40.0"
         "1413rxm481s5x7kkanf8x1hxcwz501l0frvlanvsapi4393kgn1a"
         "node_modules/@smithy/core")
   (list "@smithy/credential-provider-imds" "4.5.2"
         "04h6678cws5cqc4qig9pnkckrs33zanr0b4kdg8rx68c42c4gkh1"
         "node_modules/@smithy/credential-provider-imds")
   (list "@smithy/fetch-http-handler" "5.8.1"
         "06a2zc3hxyn3x9lwjmrwplk0vnh7jmlls67ks08rsp22aimdpyw6"
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
   (list "acorn" "8.19.0"
         "1bzs7fyn2xj7gkqklyxg38y0khhix4fxw7dz701s4aqzz8gx5yn6"
         "node_modules/acorn")
   (list "acorn-walk" "8.3.5"
         "1kgzsfj2lq2clmdyfy71k65fghgz6ihkr6lnnaprbb2qgirzzqjf"
         "node_modules/acorn-walk")
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
   (list "birpc" "4.2.0"
         "0vgbxgcwkzrgz5sj8h270r1wcnxwk89hpdc0y52b187m6xr24sby"
         "node_modules/birpc")
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
   (list "commander" "15.1.0"
         "1psvqp0h27q0m9n8bgz2ni71nknqd248b253q64wil7n4jiid3rh"
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
   (list "hosted-git-info" "9.0.3"
         "0wxnrvdfn0sm0kfg3ama55xii7rsf3ak9jy2hb264qizb7x1rfmm"
         "node_modules/hosted-git-info")
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
   (list "jose" "6.2.17"
         "1z067zlwgf1lcvir5m7vda37spq9vn1r56bp7k3ym7jjn7jslyin"
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
   (list "lru-cache" "11.5.3"
         "1n4483fb5bz9nfra86m2ll4sqw4b1h98x9fcs8q1s2fhsyxkk1yi"
         "node_modules/lru-cache")
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
   (list "rrule" "2.8.1"
         "02rhrir83p0fx7jd7m1cyvaqimcgniglvq8bjpfgwfg79n5vcgj1"
         "node_modules/rrule")
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
   (list "shell-quote" "1.12.0"
         "19lqg1014hxd9avw6yl521qsdarwm21f9qz8hbvmymm0i9f2knrw"
         "node_modules/shell-quote")
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
   (list "node_modules/.bin/acorn" "../acorn/bin/acorn")
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
