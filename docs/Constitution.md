# Wintek Constitution

Non-negotiable. Breaking a principle requires an ADR in `docs/adr/` approved before the code merges.

1. **One stack, no additions.** Flutter stable, Dart 3, Riverpod and the baseline packages listed in ADR-0001; nothing else (dependency, 3D engine, WebView or data source) without an approved ADR.
2. **Specs rule and never drift.** Every change traces to a requirement ID in `specs/`; a behaviour change updates its spec in the same PR, where the agent may propose spec, ADR and constitution edits and only the developer approves them.
3. **The math core is pure Dart.** `packages/orbital_core` never imports Flutter, Riverpod or any I/O package and passes `dart test` on its own; any SGP4 library it wraps must itself be pure Dart, which is a hard selection criterion.
4. **The UI only renders.** `presentation` contains no orbital mechanics, HTTP or JSON parsing; screen geometry (camera rotation, projection) is allowed, and widgets read state that is already propagated.
5. **Dependencies point inward.** `presentation` → `domain` ← `data`; `domain` defines repository interfaces that `data` implements, and depends only on `orbital_core`. SGP4 is reached only through its adapter in `orbital_core`, never from providers or widgets.
6. **Math is proven, not trusted.** Every new or changed formula ships with a test against a published reference value (Vallado, Curtis, official SGP4 vectors), cited in the test.
7. **Tests ride with the change.** Every requirement has at least one test naming its ID (`// REQ-ORB-003`), landing in the same PR as the code.
8. **Green before merge.** `dart format --set-exit-if-changed .`, `flutter analyze` with zero warnings and both test suites pass on every PR.
9. **Offline is a feature.** With cached elements and no network the app still propagates and draws, and the age of the data is always visible.
10. **Be a good CelesTrak citizen.** At most one fetch per dataset every few hours, never polling; the last good response is persisted locally and is the only source of orbital elements.
11. **Cached data is replaceable, not precious.** Only CelesTrak payloads and user settings are stored, in plain JSON under app storage, with no accounts or keys; user location, if used, is kept in memory only and never persisted; deleting the cache must never break the app.
12. **English and explicit units.** Code, comments, UI strings, docs, specs, tests and commit messages are in English and commits follow Conventional Commits; internally km, seconds, radians and UTC, with the unit in the name when ambiguous (`altitudeKm`, `raanRad`).
13. **Frames have a budget.** No network or disk I/O on the frame path; static geometry (globe mesh, coastlines) is precomputed, not rebuilt per frame; a frame must cost under 8 ms in profile mode on the reference device (Samsung Galaxy S23), which leaves headroom for mid-range phones.
