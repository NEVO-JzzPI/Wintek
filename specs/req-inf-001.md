# req-inf-001 — Monorepo scaffold

- **Status:** Draft
- **Roadmap row:** 1 of 33 (MVP)
- **Blocks:** every other spec
- **Depends on:** ADR-0001 (baseline packages)

## Context & Objective

The repository holds governance only: `AGENTS.md`, `docs/Constitution.md`, `docs/adr/ADR-0001-baseline-packages.md`, `docs/roadmap.md` and the project brief. There is no Dart code, no package manifest and no version control. Constitution principles 2 and 7 require every change to trace to a requirement ID and carry a test; principle 8 requires format, analyze and both suites to pass on every pull request. None of that is executable today.

This spec creates the smallest structure in which those principles become enforceable: a single Android Flutter application at the repository root and one pure-Dart package for orbital mathematics, each resolving its dependencies independently, each with a non-empty test suite, under version control.

Its value is not a feature. It is the **dependency barrier**: because the two packages resolve separately, Flutter is not reachable from the mathematics package even by accident, which is what makes principle 3 a property of the toolchain rather than a convention. Every later spec inherits that barrier for free.

This spec assumes no prior task. It assumes only that a stable Flutter SDK with the Android toolchain is installed on the development machine, and that ADR-0001 fixes the approved dependency list.

## Functional Requirements

### REQ-INF-001.1 — Repository layout and layer skeleton

The repository root contains the application and, beside it, a `packages/` directory holding the orbital mathematics package and a `specs/` directory for specifications. The application source directory also carries the feature-first layer skeleton that principle 5 governs, so the layering can be validated from the first commit instead of appearing later by convention.

**Acceptance:**

- The root holds the application manifest, source directory, test directory and Android directory; `packages/orbital_core/` holds its own manifest, source and test directories.
- `lib/domain/`, `lib/data/` and `lib/presentation/` exist in the application.
- Each of those three directories contains an empty `.gitkeep` file, so git tracks the directories and the layer boundaries of principle 5 are present in the repository rather than implied.
- `docs/`, `AGENTS.md` and `CLAUDE.md` are byte-identical to their state before the change.

### REQ-INF-001.2 — Android-only application target with fixed identity

The application targets Android exclusively, and its platform identity is fixed now because it is the only scaffold decision that is expensive to reverse.

**Acceptance:** `android/` is the only platform directory present; the Android application identifier and namespace are both `cl.wintek.app`; the Dart package name is `wintek`; the user-visible application label is `Wintek`; a debug APK builds successfully.

### REQ-INF-001.3 — Pure-Dart mathematics package with independent resolution

`packages/orbital_core` is a plain Dart package, not a Flutter package, and it resolves its dependencies on its own.

**Acceptance:** its manifest declares **zero** runtime dependencies and exactly the two development dependencies approved in ADR-0001 for this package; it declares no Flutter SDK dependency and no shared-resolution directive; its test suite passes when invoked from inside the package directory with the plain Dart toolchain.

### REQ-INF-001.4 — One-way dependency proven by a single version constant

The application reaches the mathematics package through a relative path; the package never references the application. To prove the link is real and not merely declared, the package exposes exactly one value, deliberately chosen to carry no mathematics.

**Acceptance:**

- The application manifest lists the mathematics package as a path dependency; the package manifest contains no reference to the application or to any sibling path.
- The public library of `orbital_core` exports a single file whose entire content is the declaration `const String coreVersion = '1.0.0';` and nothing else: no other constant, no function, no type.
- The application imports that constant and asserts it in its own test suite, which proves resolution, path wiring and compilation across the package boundary without writing a line of orbital logic.

### REQ-INF-001.5 — Baseline dependencies exactly as approved

The application declares the full ADR-0001 baseline in this single pull request, so no later spec needs to touch the manifest and principle 1 can be checked by comparing two lists.

**Acceptance:** the runtime dependencies of the application are exactly the three approved packages for state, HTTP and path resolution, plus the mathematics package; its development dependencies are exactly the approved lint ruleset and the Flutter test harness; nothing else appears in either list. State management is initialized once at the application root so later specs add providers without restructuring the entry point.

### REQ-INF-001.6 — Lint and format configuration in both packages

Each package carries its own analysis configuration, because the Flutter ruleset cannot apply to a package that must not see Flutter.

**Acceptance:** the analysis configuration of the application enables the approved Flutter lint ruleset; the analysis configuration of the package enables the approved pure-Dart ruleset; formatting check and static analysis both report zero issues at the root and inside the package.

### REQ-INF-001.7 — Two non-empty test suites with a concrete assertion

Both suites must contain at least one assertion that would fail if the scaffold were broken, because an empty suite passes and proves nothing.

**Acceptance:**

- The application suite runs and passes, and contains `expect(coreVersion, '1.0.0')`, which fails if the path dependency, the export or the package resolution is broken.
- The package suite runs and passes with at least one test.
- Neither suite depends on a device or an emulator.

### REQ-INF-001.8 — Dependency-direction guard, by file reading only

A test in the **application** suite enforces the dependency barrier by reading files directly. It uses `File(...).readAsStringSync()` exclusively and no YAML parser or any other added package, so the guard introduces no dependency of its own and cannot violate the very rule it protects.

**Acceptance:**

- The guard reads the application manifest at the repository root and fails if any dependency outside the ADR-0001 baseline appears there.
- The guard reads `packages/orbital_core/pubspec.yaml` and fails if that package declares any runtime dependency, any Flutter SDK dependency, or any development dependency outside the ADR-0001 allowance.
- The guard iterates over the contents of every file under `packages/orbital_core/lib/` as text and fails explicitly if it finds the substring `import 'dart:io';` or the substring `import 'dart:ffi';`, because neither appears in any manifest and both would otherwise pass unseen.
- Every failure message names Constitution principle 3 and points at ADR-0001.
- The guard resolves all three locations relative to the repository, not to the working directory, and fails rather than skips when a file or directory it expects is absent.
- The guard passes on the delivered state.

### REQ-INF-001.9 — Deliberate placeholder screen

The application starts and shows one screen written for this project, not the generated sample.

**Acceptance:** launching the application on the reference device shows a single screen identifying the app; no counter sample, no generated sample assets and no leftover template commentary remain in the source.

### REQ-INF-001.10 — Version control with normalized line endings

The repository is placed under git with artifacts excluded, line endings normalized and history started from the governance documents. Normalization is part of this requirement because the development machine is Windows and continuous integration will run on Linux: without it, a formatting check can pass locally and fail in CI on the checkout alone.

**Acceptance:**

- A git repository exists with `main` as the default branch.
- A `.gitattributes` file exists at the repository root whose content is exactly `* text=auto eol=lf`.
- The ignore rules exclude build outputs, tool caches, local Android properties and editor files.
- The lockfile of the application is tracked and the lockfile of the package is ignored.
- The initial commit contains the pre-existing documentation plus this scaffold and follows Conventional Commits.
- A GitHub remote is configured and `main` is pushed.

### REQ-INF-001.11 — Recorded SDK and version ranges

ADR-0001 fixes *which* packages are allowed but defers *which versions* to setup time, so setup time must record them.

**Acceptance:** both manifests declare an SDK constraint satisfied by the installed stable toolchain; approved packages are declared as caret ranges, never pinned to an exact version and never with a wildcard; the resolved versions are captured in the tracked lockfile; the toolchain version used is stated in the pull request description.

## Mathematical Validation / Testing

This spec contains no orbital mathematics, so there is nothing to validate against Vallado or Curtis. Reference-value validation starts at req-orb-001; claiming it here would be theatre. Verification is entirely structural and uses the commands already fixed in `AGENTS.md`.

**Positive checks — all must pass:**

| Check | Command | Proves |
| --- | --- | --- |
| Formatting | `dart format --set-exit-if-changed .` at root | REQ-INF-001.6 |
| Static analysis, app | `flutter analyze` at root | REQ-INF-001.6 |
| Static analysis, package | `dart analyze` inside `packages/orbital_core` | REQ-INF-001.3, .6 |
| Application suite | `flutter test` at root | REQ-INF-001.4, .7, .8 |
| Package suite | `dart test` inside `packages/orbital_core` | REQ-INF-001.3, .7 |
| Buildability | `flutter build apk --debug` | REQ-INF-001.2 |
| Runtime | `flutter run` on the Samsung Galaxy S23 | REQ-INF-001.9 |

The application suite is the check that carries the most weight here: it holds both `expect(coreVersion, '1.0.0')` from REQ-INF-001.7 and the file-reading guard of REQ-INF-001.8.

**Negative checks — each must fail, and then be reverted:** adding a Flutter import to the mathematics package must fail to resolve at compile time, not merely warn; inserting `import 'dart:io';` into any file under `packages/orbital_core/lib/` must turn the guard red; adding any dependency to the manifest of either package must turn the guard red with a message naming principle 3; renaming or removing a file the guard reads must make the guard fail with an explicit error rather than pass.

**Mandatory pull request checklist.** The description of the pull request that closes this spec must contain a checklist mapping every terminal command executed to the requirement ID it verifies, so the reviewer audits coverage instead of trusting a summary. Each line pairs one command with one or more IDs, for example `flutter run` → REQ-INF-001.9, `flutter test` → REQ-INF-001.4, .7, .8, `flutter build apk --debug` → REQ-INF-001.2. The checklist also records the three negative checks above as executed and reverted, and states the toolchain version required by REQ-INF-001.11. A pull request without that mapping is incomplete regardless of whether the suites are green.

No performance measurement happens here: the frame budget of principle 13 has no frame to measure until req-viz-002.

## Edge Cases & Errors

- **Scaffolding into a non-empty directory.** The generator must not be allowed to overwrite or delete `docs/`, `AGENTS.md` or `CLAUDE.md`. If the tool refuses to run or would clobber them, generate in a scratch location and move the artifacts in. Losing a governance document to satisfy a generator is a failed task, not a trade-off.
- **Installed SDK older than the declared constraint.** Dependency resolution must fail loudly. Widening the constraint to make resolution pass is forbidden: it silently changes the baseline that ADR-0001 fixed. Upgrade the toolchain or stop and report.
- **Guard test run from an unexpected working directory.** A guard that cannot find a file it reads must fail, never skip and never pass. A silently skipped guard is worse than no guard, because it reports safety that does not exist.
- **Lockfile drift between the two packages.** The two resolutions may settle on different versions of shared development packages. This is accepted: only the lockfile of the application is authoritative for a build. It must not be "fixed" by adopting a shared resolution, which would dissolve the dependency barrier of REQ-INF-001.3.
- **Incomplete Android toolchain or unaccepted licences.** The Android section of `flutter doctor` must be clean before this spec is considered done; a debug APK that cannot be built makes REQ-INF-001.2 unverifiable.
- **No network during dependency resolution.** The task fails. Offline operation in this project means serving cached orbital elements (principle 9); it never meant resolving a toolchain offline.
- **Remote repository name already taken or already populated.** Stop and ask. Never force-push over existing history, and never rename an existing remote repository to free the name.

## Out of Scope

Nothing below is to be written in this pull request, under any circumstance, even if it looks like a two-line addition:

- Any orbital mathematics whatsoever: Julian dates, GMST, Kepler, reference-frame rotations, geodetic conversion. The mathematics package ships with nothing but the version constant of REQ-INF-001.4 and its smoke test.
- Any network call, CelesTrak client, URL, JSON parsing or model type, even though the HTTP dependency is declared here.
- Any caching, file persistence or staleness logic, even though the path-resolution dependency is declared here.
- Any theme, palette, typography or design token — that is req-ui-001. The placeholder screen uses framework defaults.
- Any painter, projection, globe geometry, gesture handling or satellite marker.
- Any content inside `lib/domain/`, `lib/data/` or `lib/presentation/` beyond the `.gitkeep` files of REQ-INF-001.1; the directories are created empty and filled by later specs.
- Any state provider beyond initializing the root scope; no clock, no time multiplier, no satellite state.
- The continuous integration workflow — that is req-inf-002. This spec only guarantees that the commands it will run exist and pass locally.
- The SGP4 library and its adapter, which are gated on ADR-0002.
- Monorepo tooling, code generation and serialization helpers: all explicitly refused in ADR-0001.
- Release signing configuration, store metadata, launcher icon, splash screen and APK publishing — that is req-rel-001.
- iOS, web, macOS, Linux and Windows targets; internationalization; crash reporting; analytics; coverage reporting; git hooks.

## Open Questions

- [NEEDS CLARIFICATION] Exact stable Flutter and Dart versions at scaffold time. ADR-0001 says "latest stable at setup time"; the implementer records what was installed and derives the caret ranges from it.
- [NEEDS CLARIFICATION] GitHub repository name and visibility. The brief still lists "confirm the final name and that it is free on GitHub and the Play Store" as open. `cl.wintek.app` fixes the Android identity but not the repository slug.
- [NEEDS CLARIFICATION] Whether the git root is the current `WintekSDD/` directory or its parent. The layout decision placed the application at the root of `WintekSDD/`; the question is only whether that folder name survives as the repository name.
- [NEEDS CLARIFICATION] Android `minSdkVersion` and `targetSdkVersion`. Flutter defaults are assumed; the reference device runs a recent Android, so nothing in the MVP forces a change.
- [NEEDS CLARIFICATION] Whether the application label stays `Wintek` if the naming question of the brief resolves differently. Changing the label later is cheap; changing `cl.wintek.app` is not.
