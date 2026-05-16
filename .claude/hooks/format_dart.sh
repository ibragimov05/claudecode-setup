#!/usr/bin/env bash
# Formats a single Dart file after Write/Edit/MultiEdit. Falls back
# silently for non-Dart files so the hook is a no-op everywhere else.
# Tries `fvm dart format` first (project's pinned SDK), then plain
# `dart format`, then gives up quietly. Always exits 0 so a missing
# formatter never blocks a tool call.
#
# Triggers on the `Write|Edit|MultiEdit` matcher in PostToolUse.
set -uo pipefail

payload="$(cat || true)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")"

# Only format .dart files. The formatter line length comes from
# analysis_options.yaml's `formatter: page_width: 120` block — no flag
# needed.
case "$path" in
  *.dart)
    if command -v fvm >/dev/null 2>&1; then
      (cd "$(dirname "$path")" && fvm dart format "$path" >/dev/null 2>&1) || \
      dart format "$path" >/dev/null 2>&1 || true
    else
      dart format "$path" >/dev/null 2>&1 || true
    fi
    ;;
  *)
    : # not a Dart file; do nothing
    ;;
esac

exit 0
