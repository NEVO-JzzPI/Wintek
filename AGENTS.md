# AGENTS.md — Wintek
 
## Project
Wintek is an Android app built with Flutter that shows, in real time on a hand-drawn 3D globe, where four objects in Earth orbit are: ISS (25544), Tiangong (48274), FASat-Charlie (38011) and one geostationary satellite (GOES-East). Orbital elements (GP data, OMM/TLE) come from CelesTrak, are cached locally, and positions are propagated on-device every frame using SGP4 (library behind an adapter) and an in-house Kepler propagator.
Architecture: feature-first layers (`domain` / `data` / `presentation`), Riverpod for state, a pure-Dart package `packages/orbital_core` for all orbital math (Kepler, GMST, TEME → ECEF → WGS-84), and a `CustomPainter` globe with its own 3D projection (no 3D engine).
 
## Commands
- Run: `flutter run`
- Tests: `flutter test` (app) and `cd packages/orbital_core && dart test` (math core)
- Lint/format: `dart format --set-exit-if-changed .` and `flutter analyze`
- Release build: `flutter build apk --release`
## Style and conventions
- Latest stable Flutter and Dart 3; follow Effective Dart and the repo's `analysis_options.yaml`.
- Names: `UpperCamelCase` for types, `lowerCamelCase` for members, `snake_case` for files.
- Code, comments, UI strings, docs, specs and commit messages are in English.
- Commits follow Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
- Units: kilometers, seconds and radians internally; put the unit in the name when ambiguous (`altitudeKm`, `velocityKmS`, `raanRad`).
- Time: store and compute in UTC; show local time in the UI, except the math mode, which shows UTC.
- Every test references the ID of the requirement it verifies (e.g. `// REQ-ORB-003`).
## Rules
- Read `docs/Constitution.md` and the active spec in `specs/` before touching code.
- `packages/orbital_core` must never import Flutter or any UI/state package.
- Do not add dependencies without asking first; explain why the new package is needed.
- Do not change specs, the constitution or accepted ADRs (`docs/adr/`) without asking.
- Any new or changed math needs a test against a published reference value (cite the source in the test, e.g. Vallado or Curtis).
- Access SGP4 only through its adapter, never directly from the UI or the providers.
- Fetch from CelesTrak at most once every few hours per dataset; never poll it.
- Do not add a 3D engine, WebView or new data sources (e.g. NASA NeoWs) without asking.
- Keep the Wintek name's Selk'nam origin explained in About/README, and do not use Selk'nam symbols as decoration.
## When finishing any task
- Run `dart format --set-exit-if-changed .`, `flutter analyze` (zero warnings) and both test suites; all must pass.
- Confirm the task's acceptance criteria in the active spec are met and mark its progress.
- If a decision with lasting impact was made, propose a new ADR in `docs/adr/`.
- Summarize what changed and propose a Conventional Commit message.
