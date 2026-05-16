---
name: pr-checklist
description: Run the pre-PR sequence for this repo — format, analyze,
  stage, conventional commit, and push via `make push` (which also merges
  into the `test` branch). Use when the user says "open a PR", "ship this",
  "push this", or asks to wrap up a change before pushing.
allowed-tools: Read, Edit, Bash(make format:*), Bash(make analyze:*), Bash(fvm flutter analyze:*), Bash(fvm flutter test:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git branch:*), Bash(make push:*)
---

# pr-checklist

## When to use

Trigger when the user wants to finalize a change and ship it. Common phrasings:
"open a PR", "ship this", "push this", "wrap this up", "ready to push".

## Pre-flight

1. Run `git status` and `git branch --show-current`. If on `main` or
   `master`, stop here and tell the user to switch to a feature branch.
   The push hook will block direct pushes anyway, but stopping early is
   friendlier.

2. Run `git diff --stat` to surface what changed. If the diff is empty,
   tell the user there's nothing to ship and stop.

## Verification

3. Run `make format`. Stage any formatting changes with `git add -u`.
   If there were no formatting changes, say so plainly.

4. Run `fvm flutter analyze`. If it reports any error or warning,
   list them and stop here. The user must fix them before continuing.
   Do not auto-edit to suppress lint findings.

5. Run `fvm flutter test` only if test files exist for the changed
   paths. The top-level `test/` directory currently holds JSON fixtures,
   not Dart tests, so usually this step is a no-op. If it fails, list
   the failures and stop. Do not "fix" tests by deleting them.

## Compose the commit

6. Read the staged diff (`git diff --cached`). Propose a Conventional
   Commit message:
   - Type: one of `feat`, `fix`, `refactor`, `chore`, `docs`, `style`,
     `test`, `build`.
   - Scope (optional): the feature name from `lib/src/features/<scope>/`
     or the package name (`data`, `ui`, `local_source`, `localization`).
   - Subject: imperative, ≤72 chars, no trailing period.
   - Body (only if non-trivial): what changed and why, wrapped at 100 cols.

   Show the proposed message to the user before committing.

## Push

7. If the user approves, ask for the branch name to push to (the project's
   `make push` requires an explicit `u=` arg). Default is the current
   branch.

8. Push with: `make push m="<conventional commit message>" u=<branch>`.

   Be aware: this command also merges the change into the `test` branch.
   If the user does not want the merge into `test`, tell them to use plain
   `git push origin <branch>` instead and skip the `make push` helper.

## Do not

- Push directly to `main` or `master`. The PreToolUse hook will defer
  the push; do not try to bypass it.
- Commit if `make format` or `fvm flutter analyze` failed in steps 3–4.
- Edit existing tests to make them pass. Failing tests stop the checklist.
- Run `make gen`, `make build_runner`, or `make fcg` as part of the
  checklist — those are setup commands, not pre-PR commands. If the
  diff touches files that require regeneration, ask the user whether to
  run `make gen` separately before continuing.
