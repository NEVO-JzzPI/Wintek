# ADR-0002 — SGP4 library

- **Status:** Accepted (2026-11-08, by the developer, with revision 1 of `specs/req-orb-010.md`, before it was implemented)
- **Date:** 2026-11-08
- **Relates to:** Constitution principles 1 (one stack), 3 (pure-Dart core), 5 (SGP4 only through its adapter) and 6 (math is proven); ADR-0001 (baseline packages, Out of scope: "SGP4 library → ADR-0002"); ADR-0003 (decisions 4 and 6, gravity-model constants); `specs/req-orb-010.md`; `specs/req-inf-001.md` and `specs/req-inf-002.md` (amended with this ADR); roadmap row 12 (req-orb-010)

## Context

The Project Brief fixes SGP4 as the realistic propagator of the MVP, taken from a pub.dev library behind an adapter so that an own port can replace it later. ADR-0001 deferred the choice to this ADR with three conditions: the library is pure Dart (no FFI, no platform plugin), so that the adapter can live inside `packages/orbital_core`; it reproduces the official SGP4 test vectors before it is accepted; and nothing enters a `pubspec.yaml` without an ADR. Constitution principle 3 makes pure Dart a hard selection criterion.

The candidates found on pub.dev on 2026-11-08:

| Package | Last release | Finding |
| --- | --- | --- |
| `satellite_observer` 1.0.1 | 2026, verified publisher `aethar.dev` | MIT; port of Vallado's reference code (AIAA 2006-6753); ships `SGP4-VER.TLE` and `tcppver.out` with a verification test; WGS-72 by default; TEME output; builds an element set from fields (`GpElements.fromMeanElements`) as well as from TLE lines |
| `orbit` 0.0.15 | 2024 | No verification against the official vectors documented |
| `sgp4_sdp4` 0.1.0 | 2021 | Unmaintained |
| `satellite_dart` 1.0.2 | 2022 | Port of satellite.js; no verification and no Dart 3 support documented |
| `pious_squid` 0.3.0 | 2024 | Broad astrodynamics library; no verification of its SGP4 documented |

`satellite_observer` was then checked against its source, version 1.0.1 from pub.dev, archive SHA-256 `39c57843b8d92c6c9e63f362afb135973bd00956471ba50428801217661dca83`:

- Its 31 library files import only `dart:math`, `package:meta` and its own files: no `dart:io`, no `dart:ffi`, no Flutter, no plugin.
- Its only runtime dependency is `meta`, the Dart team's annotation package, with no code that runs.
- Its engine fixes the operation mode to improved (`'i'`) and takes the gravity model as an argument, WGS-72 by default.
- A throwaway prototype of the adapter of req-orb-010, built from the fields of `OrbitalElements` and asked through `stateAt`, reproduced `tcppver.out` for the 30 element sets of `SGP4-VER.TLE` that the TLE parser of req-orb-003 accepts (588 states): largest component error 2.6·10⁻⁷ km in position and 5.3·10⁻¹⁰ km/s in velocity, the second being the rounding of the printed reference. It also reproduced the five SGP4 error codes of those sets that stop early, gave the same states whatever the order of the calls, and cost about 0.9 µs per state.

Its weaknesses are recorded: one maintainer, no stars and a first release in 2026.

## Decision

1. **Library.** The SGP4 adapter of req-orb-010 wraps `satellite_observer`, version 1.0.1.
2. **Placement.** It is a runtime dependency of `packages/orbital_core` only. The application never declares it; it reaches the application through `orbital_core`, and only the adapter file imports it (Constitution principle 5).
3. **Exact version.** The core manifest declares it as exactly `1.0.1`, not as a caret range. `packages/orbital_core` has no committed lockfile, so a caret range would let `dart pub get` in CI pick a newer release that nobody reviewed. This is a bounded exception to the caret rule of ADR-0001 and covers this package only. The application lockfile records the archive SHA-256 above. Moving to another version is a change of `specs/req-orb-010.md` that must pass its official vectors again.
4. **Transitive dependency.** `meta` is accepted as a transitive runtime dependency of the core. It is not declared in any manifest.
5. **Surface used.** The adapter uses only the propagation layer of the library: its element set built from fields, its SGP4 engine with the WGS-72 gravity model, its TEME state and its two exception types for invalid elements and propagation errors. Look angles, passes, visibility, geodesy and the GMST of the library are not used. GMST and the Earth-fixed position stay those of req-orb-002 and req-orb-006, as req-orb-009 fixes for every propagator.
6. **Gravity-model constants (ADR-0003, decisions 4 and 6).** The WGS-72 constants of SGP4 are those of the library, selected by name. The core declares no gravity-model constant for SGP4, so decision 6 (the model in the name) is met by the name of the selected model, and req-orb-010 owns that selection.
7. **Amended specs.** REQ-INF-001.3 and REQ-INF-001.8 of `specs/req-inf-001.md`, and REQ-INF-002.9 of `specs/req-inf-002.md`, are amended with this ADR so that the core may declare this one runtime dependency and no other.
8. **Notes in earlier ADRs.** ADR-0001 notes, under its `packages/orbital_core` table, the runtime dependency and the version exception of decisions 2 to 4. ADR-0003 notes, under the Consequences of its Amendments 1 and 2, that the core holds one gravitational parameter and one Earth radius, both WGS-84, because of decision 6. Their decisions are unchanged.

## Consequences

- req-orb-010 can wrap the library without another ADR, and the dependency guard of req-inf-001 allows exactly this dependency at exactly this version.
- The library is the single owner of the SGP4 arithmetic. A wrong result in it surfaces as a failed official vector in req-orb-010, never as silent drift.
- If the library is withdrawn or abandoned, its MIT licence allows it to be vendored, and the own port of phase 2 (Project Brief) can replace the engine behind the same adapter. Either is a new ADR that supersedes decision 1.
- The CI run of `dart pub get` inside `packages/orbital_core` now downloads one more package. Its failures are handled as req-inf-002 defines and never count as a pass.

## Out of scope

- An own SGP4 port, which the Project Brief lists as optional for phase 2.
- Pass prediction, look angles and visibility, which are phase 2 and would use other parts of the library only after their own spec.
- OMM input, which ADR-0003 excludes.
