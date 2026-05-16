# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`app_name` is a `app_description` targeting iOS and Android. It uses FVM (Flutter Version Manager) with Flutter 3.41.6 and Dart SDK 3.11.4.

For deeper architecture detail (DI scopes, `control`/`StateController` patterns, `thunder` middleware pipeline, deep-link bridge, drift schema), see `ARCHITECTURE.md`.

## Behavioral guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Common Commands

All commands use `fvm flutter` / `fvm dart` via the Makefile (which includes `tools/makefile/{pub,deploy,git,fire}.mk`). Run `make help` for the full list.

- **Get dependencies:** `make get`
- **Full code generation:** `make gen` (build_runner + flutter_gen + l10n + format + clean+get)
- **Build runner only:** `make build_runner`
- **Format:** `make format` (line length 120)
- **Analyze:** `fvm flutter analyze`
- **Clean + get:** `make fcg`
- **Full clean:** `make clean_all`

### Building

- **Android APK (dev/stage/prod):** `make apk`, `make apk-stage`, `make apk-prod`
- **Android AAB:** `make aab`
- **iOS IPA (dev/stage/prod):** `make ipa`, `make ipa-stage`, `make ipa-prod`

All build targets depend on `pre-build` (increment-build → clean_all → gen). Build configs are in `config/{development,staging,production}.json` and passed via `--dart-define-from-file`.

### Git Workflow

- Pre-commit hook runs `dart format` and `flutter analyze` on staged Dart files. Configure with: `git config core.hooksPath .githooks` (see `.githooks/PRE-COMMIT.md`).
- Push with: `make push m="commit message" u=branch_name` (also merges into the `test` branch).

## Architecture

### Workspace / Mono-repo Structure

The project uses Dart workspaces with 4 packages:

- `**lib/`\*\* — Main app (features, routing, DI, services)
- `**data/**` — Data layer (models, repositories, API services, network clients)
- `**packages/ui/**` — Shared UI components, theme, text fields, constants
- `**packages/local_source/**` — Local storage abstraction (SharedPreferences DAOs)
- `**packages/localization/**` — i18n/l10n (ARB files, generated translations)

### App Layer (`lib/src/`)

```
lib/src/
├── common/          # Shared infrastructure
│   ├── constant/    # Config, URLs, generated constants (pubspec.yaml.g.dart, firebase_options.g.dart, gen/)
│   ├── core_widget/ # Foundational widgets used across features
│   ├── database/    # Drift (SQLite) database
│   ├── dependencies/initialization/  # DI setup & app initialization
│   ├── enum/        # Shared enums
│   ├── extension/   # BuildContext / DateTime / String / Number extensions
│   ├── router/      # Elixir-based routing (page files per feature)
│   ├── service/     # App-wide services (analytics, deeplinks, notifications, remote config, sounds, error logging)
│   ├── util/        # ApiClient, middleware, pagination mixins, status types
│   └── widget/      # Shared widgets
└── features/        # Feature modules
```

### Feature Module Pattern

Each feature under `lib/src/features/` follows a layered structure:

- `**controller/**` — State management (primarily `control` package controllers)
- `**bloc/**` — Some features use BLoC/Cubit (`flutter_bloc`)
- `**data/**` — Feature-specific repositories
- `**model/**` — Feature-specific models
- `**screen/**` — UI screens/pages
- `**widget/**` — Feature-specific widgets
- `**service/**` — Feature-specific services
- `**state/**` — State classes

### Key Technical Decisions

- **State management:** `control` package (controllers)
- **Routing:** `elixir` package (custom Navigator 2.0 wrapper from Miracle-Blue)
- **Networking:** `thunder` (HTTP client + middleware pipeline) + `ws` (WebSocket)
- **Database:** Drift (SQLite) — schema at `lib/src/common/database/app_database.dart`
- **Assets codegen:** `flutter_gen` outputs to `lib/src/common/constant/gen/`
- **Formatter:** 120 char line width
- **Strict analysis:** `strict-casts`, `strict-raw-types`, `strict-inference` all enabled
- **Lint rules:** `flutter_lints` with extensive custom rules (see `analysis_options.yaml`)

### Data Layer (`data/`)

Mirrors the feature structure: `data/lib/src/features/` contains repositories and services per feature. Common utilities, models, and base network setup live in `data/lib/src/common/`.

### Tests

The top-level `test/` directory currently holds only JSON fixtures, not Dart unit tests. There is no project-wide test command beyond `fvm flutter test` if tests are added.

### Keep in mind

- Codex will review your output once you are done
- Report outcomes faithfully. If tests fail, say so with the relevant output.
- If you did not run a verification step, say that rather than implying it succeeded.
- Never claim "all tests pass" when output shows failures.
- Never characterize incomplete or broken work as done.
- When a check did pass or a task is complete, state it plainly — do not hedge confirmed results or re-verify things you already checked.
- The goal is an accurate report, not a defensive one.

## Guardrails (Claude: follow these literally)

- If editing `lib/**` or `test/**`, the rules in `.claude/rules/flutter.md` are loaded automatically by glob. Read them before planning changes.
- If editing `data/**`, the rules in `.claude/rules/data.md` apply. Repositories return raw model types (not `Either`); errors throw across the boundary and `StateController.handle()`'s `error:` callback catches them.
- Generated files are write-only by the generator. The exclude list in `analysis_options.yaml` is authoritative — see `.claude/hooks/block_generated_files.sh` for the enforced glob.
- Never introduce a new package without checking `pubspec.yaml` for an existing one that does the same thing.
- Use `fvm flutter` / `fvm dart`, never bare `flutter` / `dart`.
- All async repository calls flow through `apiService.request(...)` in `data/`; do not construct new HTTP clients in feature code.

## Before opening a PR

- `make format` clean (or it will be auto-applied by the PostToolUse hook).
- `fvm flutter analyze` clean.
- `fvm flutter test` passing (if any tests exist for the touched area).
- Use the `pr-checklist` skill in `.claude/skills/` for the full sequence.

@.claude/rules/conventions.md
