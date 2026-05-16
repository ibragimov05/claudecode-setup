#!/usr/bin/env bash
# Defers any git push that targets main or master. The session pauses;
# a human must approve out-of-band to continue. Strictly safer than allow,
# strictly more convenient than deny.
#
# Triggers on the `Bash` matcher in .claude/settings.json's PreToolUse.
set -euo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"

case "$cmd" in
  *"git push"*"origin main"*\
  |*"git push"*" main"\
  |*"git push"*"origin master"*\
  |*"git push"*" master"\
  |*"git push --force"*\
  |*"git push -f"*)
    jq -nc '{
      "permissionDecision": "defer",
      "reason": "Push to a protected branch (main/master) or a force-push requires explicit human approval."
    }'
    ;;
  *)
    jq -nc '{"permissionDecision": "allow"}'
    ;;
esac
