# req-inf-002 — CI quality gates

- **Status:** Draft (revision 2, after QA audit)
- **Roadmap row:** 2 of 33 (MVP)
- **Blocks:** req-orb-001 and every later spec
- **Depends on:** req-inf-001 (monorepo scaffold, implemented on `main` in commit `27c27d1`), ADR-0001 (baseline packages)
- **Requires no new ADR:** the workflow uses no third-party action (REQ-INF-002.3) and adds nothing to either `pubspec.yaml`.

## Context & Objective

req-inf-001 made Constitution principle 8 executable locally. Nothing yet runs those gates before a merge. This spec moves them to GitHub Actions: every pull request into `main`, and every push to `main`, runs format, analysis and both test suites on a clean Linux runner with a pinned toolchain, and `main` rejects any pull request whose checks are not green.

The mathematics package is checked in a separate job where Flutter is not installed, so ADR-0001's promise that `orbital_core` "tests run without a Flutter toolchain" is proven by execution.

Every requirement below is verified by a machine: either by a test in the application suite that reads files as text (no YAML parser, no new package, no `dart:io` inside `orbital_core`), or by a command with an exact expected output.

## Matching rules used by every requirement

These definitions are normative. "The workflow" means the file `.github/workflows/ci.yml`.

- **Line present:** at least one line of the workflow, after removing leading and trailing spaces, is equal to the given string, character for character.
- **Line count N:** exactly N lines of the workflow, after removing leading and trailing spaces, are equal to the given string.
- **Substring absent:** the given string does not occur anywhere in the workflow, comments included.
- **App block:** the lines strictly after the line exactly equal to `  app:` (two leading spaces) and strictly before the line exactly equal to `  orbital_core:`.
- **Core block:** the lines strictly after the line exactly equal to `  orbital_core:` up to the end of the file.
- **In order:** the listed lines are present in the given block, and the index of each one is greater than the index of the previous one.
- **Contract test:** the file `test/ci_workflow_test.dart` in the application suite.

## Functional Requirements

### REQ-INF-002.1 — Workflow file, encoding, triggers, permissions, concurrency

**Acceptance (all verified by the contract test):**

- The file `.github/workflows/ci.yml` exists.
- Its first three bytes are not `EF BB BF` (no UTF-8 BOM), and it contains no byte `0D` (no CR, LF line endings only).
- Line present: `name: CI`
- Line present: `pull_request:`
- Line present: `push:`
- Line count 2: `branches: [main]`
- Line present: `permissions:`
- Line present: `contents: read`
- Line present: `concurrency:`
- Line present: `group: ci-${{ github.event.pull_request.number || github.ref }}`
- Line present: `cancel-in-progress: true`
- Substring absent, for each of: `secrets.`, `workflow_dispatch`, `schedule:`, `tags:`, `: write`

### REQ-INF-002.2 — Pinned toolchain and pinned runner

**Acceptance (all verified by the contract test):**

- Exactly one line, after trimming, matches the regular expression `^FLUTTER_VERSION: (\d+)\.(\d+)\.(\d+)$`. Its captured version string occurs exactly once in the whole workflow.
- Exactly one line, after trimming, matches the regular expression `^DART_VERSION: (\d+)\.(\d+)\.(\d+)$`. Its captured version string occurs exactly once in the whole workflow.
- The `DART_VERSION` value is equal to the version captured by the regular expression `^  sdk: \^(\d+\.\d+\.\d+)$` in `pubspec.yaml` and also equal to the one captured in `packages/orbital_core/pubspec.yaml`.
- Line count 2: `runs-on: ubuntu-24.04`
- Substring absent: `ubuntu-latest`
- Line present in the app block: `flutter --version | head -n 1 | grep -F "Flutter $FLUTTER_VERSION "`
- Line count 2 (one per block): `test "$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)" = "$DART_VERSION"`

**Acceptance for this pull request (verified by the command in the validation table):** `FLUTTER_VERSION` is `3.47.1` and `DART_VERSION` is `3.13.1`.

### REQ-INF-002.3 — No third-party actions; toolchain installed from official sources

**Acceptance (all verified by the contract test):**

- Exactly 2 lines, after trimming, start with `uses:` or `- uses:`.
- Both of those lines match the regular expression `^(- )?uses: actions/checkout@([0-9a-f]{40})( # v\d+\.\d+\.\d+)?$`, and both capture the same 40-character SHA.
- Line count 2: `persist-credentials: false`
- Line present in the app block: `git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$RUNNER_TEMP/flutter"`
- Line present in the app block: `echo "$RUNNER_TEMP/flutter/bin" >> "$GITHUB_PATH"`
- Line present in the core block: `curl -fsSL --retry 3 -o "$RUNNER_TEMP/dartsdk.zip" "https://storage.googleapis.com/dart-archive/channels/stable/release/$DART_VERSION/sdk/dartsdk-linux-x64-release.zip"`
- Line present in the core block: `unzip -q "$RUNNER_TEMP/dartsdk.zip" -d "$RUNNER_TEMP"`
- Line present in the core block: `echo "$RUNNER_TEMP/dart-sdk/bin" >> "$GITHUB_PATH"`

The checkout SHA is the commit of the latest `actions/checkout` release tag at implementation time, and the trailing comment names that tag.

### REQ-INF-002.4 — Deterministic dependency resolution

**Acceptance (all verified by the contract test):**

- Line present in the app block: `run: flutter pub get --enforce-lockfile`
- Line count 2: `run: dart pub get`
- Line count 2: `working-directory: packages/orbital_core`
- In order, in the app block: `run: flutter pub get --enforce-lockfile`, `run: dart pub get`, `run: flutter analyze --fatal-infos --fatal-warnings`

### REQ-INF-002.5 — Application gates job

**Acceptance (all verified by the contract test):**

- Line present in the app block: `name: app-gates`
- Line present in the app block: `runs-on: ubuntu-24.04`
- Line present in the app block: `timeout-minutes: 15`
- In order, in the app block:
  1. `- name: Checkout`
  2. `- name: Install Flutter`
  3. `- name: Verify toolchain versions`
  4. `- name: Resolve app dependencies`
  5. `- name: Resolve orbital_core dependencies`
  6. `- name: Format`
  7. `run: dart format --set-exit-if-changed .`
  8. `- name: Analyze`
  9. `run: flutter analyze --fatal-infos --fatal-warnings`
  10. `- name: Test`
  11. `run: flutter test`

### REQ-INF-002.6 — Dart-only mathematics package job

**Acceptance (all verified by the contract test):**

- Line present in the core block: `name: orbital-core-gates`
- Line present in the core block: `runs-on: ubuntu-24.04`
- Line present in the core block: `timeout-minutes: 10`
- Line present in the core block: `working-directory: packages/orbital_core`
- In order, in the core block:
  1. `- name: Checkout`
  2. `- name: Install Dart`
  3. `- name: Assert Flutter is absent`
  4. `if command -v flutter; then echo "Flutter is on PATH; the orbital_core job must be Dart-only (Constitution principle 3)." >&2; exit 1; fi`
  5. `- name: Verify toolchain versions`
  6. `- name: Resolve dependencies`
  7. `run: dart pub get`
  8. `- name: Analyze`
  9. `run: dart analyze --fatal-infos`
  10. `- name: Test`
  11. `run: dart test`
- Substring absent from the core block, for each of: `flutter.git`, `flutter pub`, `flutter analyze`, `flutter test`, `FLUTTER_VERSION`

### REQ-INF-002.7 — No soft failures

**Acceptance (verified by the contract test):**

- Substring absent, for each of: `continue-on-error`, `if:`, `|| true`, `cache`
- In the workflow, the line `jobs:` is present with no leading spaces, and no line after it starts with a non-space character. This guarantees that `app` and `orbital_core` are the only jobs and that the core block runs to the end of the file.
- Line count 1: `app:`, and line count 1: `orbital_core:`. The line `  app:` comes before the line `  orbital_core:`.

### REQ-INF-002.8 — Merge blocked until both checks pass

**Repository half (verified by the contract test):**

- Line count 1: `name: app-gates`
- Line count 1: `name: orbital-core-gates`

**GitHub half (verified by the command below; prerequisite: `gh auth status` exits with code 0):**

The protection is applied with this exact command:

```bash
gh api -X PUT repos/NEVO-JzzPI/Wintek/branches/main/protection --input - <<'EOF'
{"required_status_checks":{"strict":true,"contexts":["app-gates","orbital-core-gates"]},"enforce_admins":true,"required_pull_request_reviews":{"required_approving_review_count":0},"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
```

It is verified by this command:

```bash
gh api repos/NEVO-JzzPI/Wintek/branches/main/protection --jq '[.required_status_checks.strict, (.required_status_checks.contexts | sort | join(",")), .enforce_admins.enabled, .allow_force_pushes.enabled, .required_pull_request_reviews.required_approving_review_count] | map(tostring) | join("|")'
```

whose standard output must be exactly:

```text
true|app-gates,orbital-core-gates|true|false|0
```

### REQ-INF-002.9 — Shared repository-root helper

The repository-root search currently private to `test/dependency_guard_test.dart` moves to `test/support/repo_root.dart`, so both the guard and the contract test use one implementation. This is the only change allowed to a req-inf-001 file.

**Acceptance (verified by the contract test, except the last item):**

- `test/support/repo_root.dart` exists and contains the substrings `Platform.script` and `AGENTS.md`.
- `test/dependency_guard_test.dart` contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- `test/ci_workflow_test.dart` contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- When the root cannot be resolved, the failure message contains `Cannot resolve the repository root`. It also contains `Constitution principle 3` when called from the guard and `Constitution principle 8` when called from the contract test.
- Verified by command, not by the contract test: `flutter test test/dependency_guard_test.dart --reporter expanded` exits with code 0, and its output contains each of these three test names verbatim:
  - `app manifest declares no dependency outside the ADR-0001 baseline`
  - `orbital_core manifest declares zero runtime deps, no Flutter SDK and only the approved dev deps`
  - `orbital_core/lib never imports dart:io or dart:ffi`

### REQ-INF-002.10 — Contract test structure and failure semantics

**Acceptance (verified by the contract test reading its own source, and by the commands in the validation table):**

- For each N from 1 to 10, `test/ci_workflow_test.dart` contains a line which, after trimming, is exactly `// REQ-INF-002.N`, and the next non-empty line opens a test.
- It does not contain the substring `skip:`.
- A missing file read by the test (the workflow, either manifest, either test file, or the helper) produces a failing test, never a skipped or passing one.
- Every failure message starts with `[REQ-INF-002.N]`, where N is the requirement whose check failed, and contains `Constitution principle 8`.
- The contract test is part of `flutter test` at the root, so the app-gates job of REQ-INF-002.5 executes it on every pull request.

## Mathematical Validation / Testing

This spec contains no orbital mathematics, so there is nothing to check against Vallado or Curtis. Every check below has an exact command and an exact expected result.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| L1 | `dart format --set-exit-if-changed .` | exit 0 | REQ-INF-002.5 |
| L2 | `flutter pub get --enforce-lockfile` | exit 0 | REQ-INF-002.4 |
| L3 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | REQ-INF-002.5 |
| L4 | `flutter test` | exit 0 | REQ-INF-002.1 – .10 |
| L5 | `flutter test test/ci_workflow_test.dart --reporter expanded` | exit 0 | REQ-INF-002.1 – .10 |
| L6 | `flutter test test/dependency_guard_test.dart --reporter expanded` | exit 0, output contains the three names of REQ-INF-002.9 | REQ-INF-002.9 |
| L7 | `dart pub get && dart analyze --fatal-infos && dart test`, inside `packages/orbital_core` | exit 0 | REQ-INF-002.6 |
| L8 | command L8 below | `10` | REQ-INF-002.10 |
| L9 | command L9 below | `2` | REQ-INF-002.2 |
| L10 | `grep -c "skip:" test/ci_workflow_test.dart` | `0` | REQ-INF-002.10 |

```bash
# L8
grep -oE "// REQ-INF-002\.[0-9]+" test/ci_workflow_test.dart | sort -u | wc -l
# L9
grep -cE "^  (FLUTTER_VERSION: 3\.47\.1|DART_VERSION: 3\.13\.1)$" .github/workflows/ci.yml
```

### Local negative checks (contract test only)

These run after the workflow is committed on the feature branch. For each row, apply the edit and run the command below. It must print the tag, which means the contract test failed for the expected requirement. Then revert with `git checkout -- .github/workflows/ci.yml` before the next row.

```bash
flutter test test/ci_workflow_test.dart 2>&1 | grep -F "<tag>"
```

| # | Edit to `.github/workflows/ci.yml` | Tag expected in output |
| --- | --- | --- |
| C1 | `sed -i 's/$/\r/' .github/workflows/ci.yml` (CRLF) | `[REQ-INF-002.1]` |
| C2 | `printf '\xEF\xBB\xBF' \| cat - .github/workflows/ci.yml > ci.tmp && mv ci.tmp .github/workflows/ci.yml` (BOM; inside the table, `\|` is a single pipe) | `[REQ-INF-002.1]` |
| C3 | Replace `FLUTTER_VERSION: 3.47.1` with `FLUTTER_VERSION: stable` | `[REQ-INF-002.2]` |
| C4 | Replace both `runs-on: ubuntu-24.04` with `runs-on: ubuntu-latest` | `[REQ-INF-002.2]` |
| C5 | Add a step line `uses: subosito/flutter-action@v2` to the app block | `[REQ-INF-002.3]` |
| C6 | Replace `run: flutter pub get --enforce-lockfile` with `run: flutter pub get` | `[REQ-INF-002.4]` |
| C7 | Delete the `- name: Format` step and its `run:` line | `[REQ-INF-002.5]` |
| C8 | Add `run: flutter test` to the core block | `[REQ-INF-002.6]` |
| C9 | Add `continue-on-error: true` under `- name: Test` in the app block | `[REQ-INF-002.7]` |
| C10 | Replace `name: orbital-core-gates` with `name: core` | `[REQ-INF-002.8]` |
| C11 | Delete the file `.github/workflows/ci.yml` | `[REQ-INF-002.1]` |

### Remote checks, in this exact order

Prerequisites, both must hold before step R1:

- `gh auth status` exits with code 0.
- `gh api repos/NEVO-JzzPI/Wintek --jq .visibility` prints `public`. If it prints anything else, stop: REQ-INF-002.8 cannot be met (see Edge Cases).

**R1 — open the non-draft pull request that closes this spec, wait for both checks** (proves REQ-INF-002.1 to .7):

```bash
gh pr checks <PR> --json name,bucket --jq 'sort_by(.name) | map(.name + "=" + .bucket) | join(",")'
```

Expected output: `app-gates=pass,orbital-core-gates=pass`

**R2 — apply the protection** (REQ-INF-002.8): run the PUT command of REQ-INF-002.8. Expected: exit code 0.

**R3 — verify the protection** (REQ-INF-002.8): run the GET command of REQ-INF-002.8. Expected: the exact output given there.

**R4 — red pull requests** (REQ-INF-002.5, .6): for each row N1–N7 below, push a throwaway branch containing only that edit, open a non-draft pull request, and wait for its checks.

```bash
gh pr checks <n> --json name,bucket --jq '.[] | select(.name=="<check>") | .bucket'
```

Expected output: `fail`

**R5 — merge is blocked** (REQ-INF-002.8): for each pull request of R4:

```bash
gh pr view <n> --json mergeStateStatus --jq .mergeStateStatus
```

Expected output: `BLOCKED`

**R6 — clean up:** `gh pr close <n> --delete-branch` for each pull request of R4. Expected: exit code 0.

**R7 — post-merge run** (REQ-INF-002.1): merge the pull request of R1, wait for the push run, then:

```bash
gh run list --branch main --event push --limit 1 --json conclusion --jq '.[0].conclusion'
```

Expected output: `success`

| # | Throwaway edit | `<check>` expected `fail` |
| --- | --- | --- |
| N1 | Add one extra leading space to any statement line in `lib/main.dart` | `app-gates` |
| N2 | Add `import 'dart:math';` (unused) to `lib/main.dart` | `app-gates` |
| N3 | Change `'1.0.0'` to `'0.0.0'` inside the `expect` of `test/scaffold_test.dart` | `app-gates` |
| N4 | Add `import 'package:flutter/foundation.dart';` to `packages/orbital_core/lib/orbital_core.dart` | `orbital-core-gates` |
| N5 | Change `'1.0.0'` to `'0.0.0'` inside the `expect` of `packages/orbital_core/test/orbital_core_test.dart` | `orbital-core-gates` |
| N6 | In `packages/orbital_core/test/orbital_core_test.dart`, store `coreVersion` in a local whose name starts with an uppercase letter and pass that local to `expect` (the lint `non_constant_identifier_names` reports at info severity only) | `orbital-core-gates` |
| N7 | Add `shared_preferences: ^2.0.0` under `dependencies:` in `pubspec.yaml` without updating `pubspec.lock` | `app-gates` |

**Pull request checklist.** The description of the pull request that closes this spec lists the commands L1–L10, C1–C11 and R1–R7, each with its observed result. For R4 and R5 it also gives the pull request number of N1–N7. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **CRLF or BOM in the workflow.** The contract test rejects both (REQ-INF-002.1). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF. A file written by an editor or shell that adds CR or a BOM fails locally before it reaches CI. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Network failure while installing the toolchain or resolving packages.** `curl` retries 3 times (REQ-INF-002.3). `git clone`, `flutter pub get` and `dart pub get` do not retry. Any failure fails the job. The workflow never retries a job automatically. The developer re-runs the failed job with `gh run rerun <run-id> --failed`.
- **Runner out of memory or disk, or a hung step.** The job is killed by `timeout-minutes` (15 for app-gates, 10 for orbital-core-gates) or by the runner, and its check ends as `fail` or `cancelled`. Neither counts as `pass`, so the merge stays blocked. The fix is a re-run or a spec change to the limits, never a soft failure (REQ-INF-002.7).
- **Flutter preinstalled on the runner image.** The `Assert Flutter is absent` step fails the core job with a message naming principle 3. Removing Flutter from the image path is a spec change, not a workaround applied in the pull request.
- **Bundled Dart differs from `DART_VERSION`.** The `Verify toolchain versions` step fails. The fix is to correct the pair in the workflow and the `sdk:` lower bounds in both manifests in one pull request (REQ-INF-002.2).
- **Pinned Flutter tag or Dart archive unavailable.** `git clone` or `curl` fails and the job fails. Replacing the pin with a floating value is rejected by REQ-INF-002.2.
- **Untracked `orbital_core` lockfile.** The core job resolves fresh within the caret ranges on every run (accepted by REQ-INF-001.10). If a newer allowed version breaks the job, the fix is a constraint change in its own pull request.
- **Required checks before their first run.** The check names exist on GitHub only after the workflow has run once, which is why R1 comes before R2.
- **Repository not public.** On a private repository, branch protection with required checks needs a paid plan. If the visibility prerequisite does not print `public`, implementation stops and the developer decides; CI is not merged without REQ-INF-002.8.
- **`gh` not installed or not authenticated.** `gh` is a verification tool used by the developer, not a project dependency: it appears in no manifest and no workflow step. If `gh auth status` fails, R1–R7 cannot run and the pull request is incomplete.
- **GitHub Actions outage.** Checks cannot report `pass`, so `main` is blocked (`enforce_admins` is `true`). This is accepted: no merge path that bypasses the gates exists.
- **Principle 2 is not enforced by the rule.** `required_approving_review_count` is `0`, so approval of spec, ADR and constitution edits remains the developer's act of merging, not a GitHub setting.
- **Repository root not found on the runner.** The helper of REQ-INF-002.9 fails with `Cannot resolve the repository root`. It never skips.

## Out of Scope

Nothing below is written in this pull request:

- Any change to files of req-inf-001 other than the refactor of REQ-INF-002.9: removing the private root search from `test/dependency_guard_test.dart` and adding the import line. The guard's three test names, its assertions and its allow-lists stay unchanged.
- Any third-party GitHub Action, any `pubspec.yaml` change in either package, and any ADR.
- Building, signing, tagging or publishing the APK (req-rel-001).
- Coverage, coverage badges, README badges (req-rel-002).
- Caching of SDKs or the pub cache (forbidden by REQ-INF-002.7).
- Matrix builds, other runners, integration or emulator tests, golden tests, frame-budget measurement.
- Dependabot, CodeQL, secret scanning, commit linting, git hooks.
- Any orbital mathematics, network, cache or UI code.

## Open Questions

None blocking. `specs/req-inf-001.md` still reads `Status: Draft` although its code is on `main`; updating that status belongs to the developer, not to this pull request.
