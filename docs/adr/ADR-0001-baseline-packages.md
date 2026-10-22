# ADR-0001 — Baseline packages

- **Status:** Accepted
- **Date:** 2026-10-20
- **Relates to:** Constitution principles 1 (one stack), 3 (pure-Dart core), 5 (dependencies point inward)

## Context

Constitution principle 1 allows no dependency outside "the baseline packages listed in ADR-0001". Without this list the project cannot fetch data, cache it or lint itself, so the baseline must be fixed before the first commit of production code.

The baseline is deliberately minimal. Weeks 1–2 of the roadmap cover Kepler, GMST and the TEME → ECEF → WGS-84 conversions, none of which need a third-party package: that work lives in `packages/orbital_core`, which keeps **zero runtime dependencies** so principle 3 holds by construction.

## Decision

The following packages are approved. Nothing else enters `pubspec.yaml` — app or package — without a new ADR.

### App (`pubspec.yaml`), runtime

| Package | Why it is unavoidable |
| --- | --- |
| `flutter_riverpod` | State management chosen in the Project Brief; holds the simulation clock and the propagated positions. |
| `http` | Single HTTP call per dataset against CelesTrak GP data. Chosen over `dio` because retries, interceptors and multipart are not needed. |
| `path_provider` | Resolves the platform directory where the cached OMM/TLE JSON is written (principles 9–11). |

### App, development only

| Package | Why |
| --- | --- |
| `flutter_lints` | Lint ruleset behind `analysis_options.yaml`, enforced by `flutter analyze` (principle 8). |
| `flutter_test` | Ships with the SDK; required for the widget tests of the object card and the time control. |

### `packages/orbital_core`

| Package | Scope | Why |
| --- | --- | --- |
| *(none)* | runtime | The math core must stay pure Dart with no I/O; dart:math and dart:core are enough. |
| `lints` | dev | Pure-Dart equivalent of `flutter_lints`; the package must not depend on Flutter. |
| `test` | dev | Runs `dart test` standalone, as principle 3 requires. |

Versions are the latest stable at setup time, recorded as caret ranges in `pubspec.yaml` and locked by `pubspec.lock`. Upgrading within a range is not an ADR; changing the list is.

## Out of scope

- **SGP4 library → ADR-0002 (week 3).** Not needed for weeks 1–2 and the candidates are not evaluated yet. It must be pure Dart (no FFI, no platform plugin) so the adapter can live inside `orbital_core`, and it must reproduce the official SGP4 test vectors before it is accepted.
- **Coastline dataset** and its licence: separate ADR when the geometry source is chosen.
- `shared_preferences`, `dio`, `freezed`, `json_serializable`, any 3D engine and any WebView: not approved. Settings ride in the same cached JSON until a spec proves that insufficient.

## Consequences

- A dependency request from an agent is answerable by grep: if it is not in the tables above, it needs an ADR.
- `orbital_core` can be published or reused as-is, and its tests run without a Flutter toolchain.
- Hand-written `fromJson` for OMM payloads instead of code generation: a little boilerplate, no build_runner step in CI.
