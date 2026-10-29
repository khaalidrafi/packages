#!/usr/bin/env bash
# Smoke test for brow6el-bin: a Chromium/CEF application.  The binary is compiled
# from source but brow6el's CMakeLists installs nothing -- no install() rule, and
# every CEF resource lands in the build tree -- so the whole output is produced by
# one hand-written install-cef-resources phase that copies, chmods and patcheffs
# by hand.  Three runs of CI died inside that phase (37553708689, 37598768203,
# 38101517394) precisely because a missing file there is silent until patchelf or
# brow6el itself hits it.
#
# A CEF app cannot be started headless in a CI container (it needs a display, and
# even the SwiftShader path wants X11), so this asserts the shape of the install
# statically -- the same approach tests/smoke/zcode-bin.sh uses -- and exercises
# the wrapper as far as it can be exercised: the shell wrapper is real shell, so
# running it with a bad flag proves the interpreter, the exec target and the
# cd/LD_LIBRARY_PATH/VK_ICD_FILENAMES preamble all parse and resolve.  Starting
# the GUI is a manual check (README.org).
set -euo pipefail
out="${1:?usage: $0 STORE-PATH}"

fail() { echo "brow6el-bin smoke: $*" >&2; exit 1; }

wrapper="$out/bin/brow6el"
share="$out/share/brow6el"

[ -x "$wrapper" ] || fail "missing executable $wrapper"
[ -d "$share" ] || fail "missing $share"

# The layout the phase copies by hand: the executable, the three patchelf'd CEF
# libraries, the ICU data and the resource packs.  libcef.so is the one that
# cannot be missing (everything links against it); the .pak files are what CEF
# reads at startup before it opens a window.
for path in \
    brow6el \
    libcef.so \
    libEGL.so \
    libGLESv2.so \
    icudtl.dat \
    resources.pak \
    chrome_100_percent.pak \
    v8_context_snapshot.bin \
    vk_swiftshader_icd.json \
    locales; do
  [ -e "$share/$path" ] || fail "CEF resource $share/$path missing"
done
[ -n "$(find "$share/locales" -name '*.pak' -print -quit 2>/dev/null)" ] ||
  fail "$share/locales holds no .pak files"

# chrome-sandbox is deliberately excluded by the copy (it cannot be setuid in the
# store); its absence is the documented behaviour, not a regression, so assert it
# is NOT there -- a future edit that drops the filter and copies it would ship a
# useless setuid-less binary.
[ -e "$share/chrome-sandbox" ] &&
  fail "chrome-sandbox was copied; it cannot be setuid in the store" || true

# The wrapper is generated text, so read it back rather than trusting the build:
# it must cd into the store share dir (the JS/HTML assets are found relative to
# the process cwd), export the CEF lib dir on LD_LIBRARY_PATH, point SwiftShader
# at its ICD json, and exec the ELF next to it.  Every one of those lines exists
# because of a failure in this package's history.  The shebang gets the same
# treatment codebuddy's wrappers do: the format string writes a store bash, so
# `#!/usr/bin/env bash` would mean the store path was dropped.
head -1 "$wrapper" | grep -qE '^#!/gnu/store/.+/bin/bash$' ||
  fail "$wrapper has a non-store shebang: $(head -1 "$wrapper")"
grep -q "cd \"$share\"" "$wrapper" ||
  fail "$wrapper does not cd into $share"
grep -q "LD_LIBRARY_PATH=\"$share" "$wrapper" ||
  fail "$wrapper does not prepend $share to LD_LIBRARY_PATH"
grep -q "VK_ICD_FILENAMES=\"$share/vk_swiftshader_icd.json\"" "$wrapper" ||
  fail "$wrapper does not export VK_ICD_FILENAMES"
grep -q "exec \"$share/brow6el\"" "$wrapper" ||
  fail "$wrapper does not exec $share/brow6el"

# The ELF itself: a real executable, with a store interpreter and an rpath that
# reaches the CEF libs and the Guix libraries CEF dlopens.  Guix is not FHS, so
# both are what makes it start at all, and only patchelf can see them.
patchelf="$(guix build patchelf | head -1)/bin/patchelf"
real="$share/brow6el"
head -c 4 "$real" | grep -q $'ELF' || fail "$real is not an ELF"

interpreter="$("$patchelf" --print-interpreter "$real")"
case "$interpreter" in
  /gnu/store/*) ;;
  *) fail "unpatched interpreter: $interpreter" ;;
esac

runpath="$("$patchelf" --print-rpath "$real")"
# ${%%:*} keeps the first entry only; it must be a store path, and the whole
# list must be store paths (checked entry by entry below).
case "${runpath%%:*}" in
  /gnu/store/*) ;;
  *) fail "runpath does not start with a store path: $runpath" ;;
esac
# $ORIGIN is deliberately absent: the binary is installed in share/ with its
# libraries beside it, and LD_LIBRARY_PATH in the wrapper is what covers them.
case "$runpath" in
  *'$ORIGIN'*) fail "runpath unexpectedly contains \$ORIGIN: $runpath" ;;
esac
# nss installs into lib/nss, and CEF needs NSS, so that entry has to be
# tolerated alongside the plain lib/ ones.
# An empty field ("::") is skipped rather than failed: it is what patchelf
# writes when an entry was nil, and the dynamic linker reads it as "cwd",
# which the wrapper sets anyway with its cd.
bad=""
IFS=':' read -ra entries <<< "$runpath"
for e in "${entries[@]}"; do
  [ -n "$e" ] || continue
  case "$e" in
    /gnu/store/*/lib|/gnu/store/*/lib/nss) ;;
    *) bad="$bad $e" ;;
  esac
done
[ -z "$bad" ] || fail "runpath entries outside the store:$bad"
# 24 inputs feed this rpath (the 23 in `inputs' plus gcc), and a collapsed or
# partially written one is the failure mode that only shows up at runtime as a
# dlopen error.  A floor of 5 is well under the real count but catches an rpath
# that was never assembled at all.
[ "${#entries[@]}" -gt 5 ] ||
  fail "runpath has too few Guix libraries (${#entries[@]}): $runpath"

# The shared libraries get an rpath but no interpreter.  What is checkable
# here is patchelf's postcondition on the final artifact, NOT the chmod that
# made it possible: the chmod happens in the build tree, and the daemon
# canonicalises every registered output to read-only (r--r--r--, or
# r-xr-xr-x with any exec bit), so NO file under $share is ever writable and
# a [ -w ] assertion here can never pass.  That is exactly what run 51
# hit: the chmod before patchelf did its job during the build, the build
# succeeded, and the smoke test still failed with "libcef.so is not
# writable" because it was asserting a build-time property on a build
# result.  The earlier chmod failures this file was written for (runs
# 38101517394, "patchelf: open: Permission denied") die inside the phase
# now, so the build surface already covers them.
#
# What survives into the store is the rpath, so that is what is asserted:
# libcef.so is born with RUNPATH=$ORIGIN (see the link note in the phase),
# so an unpatched library shows up here unambiguously.  The three libs get
# the same rpath list as the executable above -- the Guix libraries CEF
# dlopens -- so the entry rules are the same: store libs only, nss's lib/nss
# tolerated, no $ORIGIN, and more than one entry.
for lib in libcef.so libEGL.so libGLESv2.so; do
  head -c 4 "$share/$lib" | grep -q $'ELF' || fail "$share/$lib is not an ELF"
  libpath="$("$patchelf" --print-rpath "$share/$lib")"
  [ -n "$libpath" ] ||
    fail "$share/$lib has no rpath; the phase's --set-rpath did not run"
  case "$libpath" in
    *'$ORIGIN'*) fail "$share/$lib is unpatched (rpath is \$ORIGIN): $libpath" ;;
  esac
  bad=""
  IFS=':' read -ra libentries <<< "$libpath"
  for e in "${libentries[@]}"; do
    [ -n "$e" ] || continue
    case "$e" in
      /gnu/store/*/lib|/gnu/store/*/lib/nss) ;;
      *) bad="$bad $e" ;;
    esac
  done
  [ -z "$bad" ] ||
    fail "$share/$lib rpath entries outside the store:$bad"
  [ "${#libentries[@]}" -gt 1 ] ||
    fail "$share/$lib rpath has no Guix libraries: $libpath"
done

# Exercise the wrapper for real: no --help (brow6el has none) but a nonexistent
# flag still runs the whole preamble -- cd, both exports, the exec -- and the
# exec'd binary then rejects it.  The point is not the exit code but that it must
# NOT be a shell failure: 126/127 would mean the preamble is broken, and a
# missing ELF would give the same.  A CEF app exits nonzero on any unknown flag,
# so require a code that shows the exec happened.
rc=0
timeout 60 "$wrapper" --definitely-not-a-flag >/dev/null 2>&1 || rc=$?
case "$rc" in
  126|127) fail "$wrapper exited $rc -- the preamble or the exec target is broken" ;;
esac

echo "brow6el-bin smoke test passed"
