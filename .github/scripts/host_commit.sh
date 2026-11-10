#!/usr/bin/env bash
# host_commit.sh — host-side commit of seat work (packages chain).
#
# Called by .github/workflows/agent-team.yml (seg step) — the workflow's
# run block sits near GitHub's 21,000-char expression limit, so the
# host-commit logic lives here, out of the parsed workflow file.
#
# OWNER LAW 2026-10-29 #hq: changes made by agents on CI are committed
# by THAT AGENT's author, never by the model/CI that ran the turn.
# OWNER CORRECTION 2026-10-30 #hq + AGENTS.md format: the author is the
# MODEL identity `MODEL <MODEL@PROVIDER>` (e.g. Qwen3.8-Flash
# <qwen3.8-flash@qoder.com>, GLM-5.3 <glm-5.3@z.ai>) — never the raw
# lane string, never "unknown". Committer stays the CI machine.
#
# Usage: host_commit.sh "$SEAT" "$TURN_AGENT" "$TURN_RESULT"
#   (in the repo root, with the workspace diff staged or stageable)
set -u
SEAT="$1"; TURN_AGENT="$2"; TURN_RESULT="$3"

# Resolve the model identity from the lane string. Canonical identities
# first (values = the older-commit precedents); fallback = literal
# MODEL@PROVIDER with the REAL provider (lane prefix, not the runner).
LANE=$(printf '%s' "$TURN_AGENT" | sed -E 's#^[A-Za-z0-9._-]+/##')
MODEL_ID=${LANE%%@*}
PROVIDER_PREFIX=$(printf '%s' "$TURN_AGENT" | sed -nE 's#^([A-Za-z0-9._-]+)/.*#\1#p')
MODEL_PROVIDER=${PROVIDER_PREFIX:-${LANE#*@}}
case "$MODEL_ID" in
  qwen3.8-flash)       TURN_AUTHOR="Qwen3.8-Flash <qwen3.8-flash@qoder.com>" ;;
  glm-5.3)             TURN_AUTHOR="GLM-5.3 <glm-5.3@z.ai>" ;;
  glm-5.3-flash)       TURN_AUTHOR="GLM-5.3-Flash <glm-5.3-flash@z.ai>" ;;
  glm-4.7-flash)       TURN_AUTHOR="GLM-4.7-Flash <glm-4.7-flash@z.ai>" ;;
  glm-5.3-flash-free)  TURN_AUTHOR="glm-5.3-flash-free <glm-5.3-flash-free@opencode>" ;;
  deepseek-v4.1-flash) TURN_AUTHOR="DeepSeek V4.1 Flash <deepseek-v4.1-flash@codebuddy.com>" ;;
  kimi-k2.6)           TURN_AUTHOR="Kimi K2.6 <kimi-k2.6@kimi.ai>" ;;
  qwen3.8-max)         TURN_AUTHOR="Qwen3.8-Max <qwen3.8-max@qwen.ai>" ;;
  minimax-m3.1-flash)  TURN_AUTHOR="MiniMax-M3.1-Flash <minimax-m3.1-flash@openrouter.ai>" ;;
  *)                   TURN_AUTHOR="$MODEL_ID <$MODEL_ID@$MODEL_PROVIDER>" ;;
esac

if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  if [ -n "$TURN_AGENT" ] && [ -n "$MODEL_ID" ]; then
    GIT_AUTHOR_NAME="${TURN_AUTHOR%% <*}" \
    GIT_AUTHOR_EMAIL="$(printf '%s' "$TURN_AUTHOR" | sed -nE 's/.*<([^@]+@[^>]+)>.*/\1/p')" \
      git commit -m "turn(${SEAT}): segment work — host-committed" \
      -m "result: ${TURN_RESULT}" || echo "::notice::workspace commit failed"
  else
    echo "::error::host-commit without a resolvable lane — fell back to CI author; fix the lane string (law: MODEL <MODEL@PROVIDER>)"
    git commit -m "turn(${SEAT}): segment work — host-committed" \
      -m "result: ${TURN_RESULT}" || echo "::notice::workspace commit failed"
  fi
else
  echo "workspace clean — no host commit needed"
fi
