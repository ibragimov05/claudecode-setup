---
name: conventions
description: Project-wide conventions that apply to every package in this
  Dart workspace (lib/, data/, packages/ui/, packages/local_source/,
  packages/localization/). Loaded for any file under the repository.
globs:
  - "**/*"
---

# Project conventions

## Tooling

- Use `fvm flutter` and `fvm dart`. Never invoke bare `flutter` / `dart` —
  the project pins Flutter through FVM and a mismatched SDK breaks the
  workspace.
- Use `make` targets where one exists rather than re-typing the underlying
  command. `make help` lists them. The most common: `make get`, `make gen`,
  `make format`, `make build_runner`, `make fcg`, `make clean_all`.
- The formatter line length is 120 (set in `analysis_options.yaml`'s
  `formatter:` block). Do not narrow it locally.

## Imports

- Lint rule `prefer_relative_imports: true` is enabled. Inside a package
  (e.g. within `lib/src/`), siblings import via relative paths, not via
  `package:app_name/...`. Cross-package imports (e.g. `lib/` ↔ `data/`)
  use `package:data/...`, `package:ui/...`, etc.
- Lint rule `avoid_relative_lib_imports: true` means files outside `lib/`
  never reach into `lib/` with a relative path.

## Logging

- Use `l.s(...)`, `l.i(...)`, `l.w(...)`, `l.d(...)` from `logbook`. Never
  leave `print` or `debugPrint` in committed code (the lint reports them
  but does not always fail the build).
- Errors caught in a controller's `handle(error: ...)` callback should call
  `l.s('<ControllerName> > <method>: $error', stackTrace)` so the source is
  greppable in logs.

## Code style

- Public functions over ~40 lines need a comment explaining intent.
- Prefer `final class` over plain `class` for leaf types. The analyzer
  enforces `sort_constructors_first`, `sort_unnamed_constructors_first`,
  `always_put_required_named_parameters_first`.
- `dynamic` is banned by `avoid_annotating_with_dynamic`. Use `Object?` if
  the value is truly heterogeneous.
- TODO comments include date and owner: `// TODO(2026-05-14, fazliddin): ...`.

## Generated files

The following globs are write-only by their generator. Hand-editing is
blocked by `.claude/hooks/block_generated_files.sh` and excluded from the
analyzer:

```
**.g.dart       **.freezed.dart    **.gen.dart       **.gql.dart
**.config.dart  **.mocks.dart      **.pb.dart        **.pbenum.dart
**.pbjson.dart
lib/src/common/localization/generated/**
lib/src/common/model/generated/**
lib/src/common/constant/**.g.dart
```

Re-run `make gen` (or `make build_runner`) after touching anything they
read from.

## Commits and pushes

- Push uses the Makefile target: `make push m="commit message" u=branch_name`.
  This also merges the change into the `test` branch — be aware before
  pushing speculative work.
- Direct pushes to `main` or `master` are deferred by
  `.claude/hooks/gate_git_push.sh` and require human approval.
