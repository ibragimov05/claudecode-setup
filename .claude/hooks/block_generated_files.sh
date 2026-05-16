#!/usr/bin/env bash
# Refuses Write/Edit/MultiEdit on files that are produced by code
# generators in this project. The glob mirrors `analyzer.exclude` in
# analysis_options.yaml — those are the files marked as write-only by
# their respective generator (build_runner, drift_dev, flutter_gen,
# pubspec_generator, vector_graphics_compiler).
#
# Triggers on the `Write|Edit|MultiEdit` matcher in PreToolUse.
set -euo pipefail

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"

case "$path" in
  *.g.dart\
  |*.freezed.dart\
  |*.gen.dart\
  |*.gql.dart\
  |*.config.dart\
  |*.mocks.dart\
  |*.pb.dart\
  |*.pbenum.dart\
  |*.pbjson.dart\
  |*/lib/src/common/localization/generated/*\
  |*/lib/src/common/model/generated/*\
  |*/lib/src/common/constant/gen/*)
    jq -nc '{
      "permissionDecision": "deny",
      "reason": "Generated file. Edit the source declaration (drift table, .arb file, pubspec.yaml, etc.) and run `make gen` instead."
    }'
    ;;
  *)
    jq -nc '{"permissionDecision": "allow"}'
    ;;
esac
