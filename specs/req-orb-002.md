# req-orb-002 — GMST from Julian date

- **Status:** Draft (revision 1). Published values marked `[TO VERIFY]` must be confirmed against the books before implementation starts (see Open Questions).
- **Roadmap row:** 4 of 33 (MVP)
- **Blocks:** req-orb-006 (inertial to ECEF rotation)
- **Depends on:** req-orb-001 (Julian date and UTC time base), req-inf-002 (CI quality gates), ADR-0001 (baseline packages)
- **Requires no new ADR:** the work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`.

## Context & Objective

SGP4 delivers positions in the TEME frame, and the in-house Kepler propagator delivers them in an inertial frame. Neither can be drawn on a rotating Earth until the app knows how far the Earth has turned. That angle is Greenwich Mean Sidereal Time (GMST). This spec delivers exactly what roadmap row 4 names: a two-part Julian date (req-orb-001) yields GMST, the rotation angle that req-orb-006 applies.

Three decisions are fixed here so later specs inherit them:

- **Model.** GMST follows the IAU-82 model, the polynomial in Julian centuries of UT1 published by Vallado (in seconds of time) and by Meeus (in degrees). It is the model SGP4 uses to define TEME, so req-orb-006 and req-orb-010 stay consistent. The IAU-2006 Earth Rotation Angle model is not used.
- **Input.** The only input is the two-part Julian date produced by REQ-ORB-001.1, through its Julian centuries since J2000.0. A raw number cannot reach GMST, so the valid range and the UTC check of REQ-ORB-001.4 are inherited without being repeated.
- **Output.** GMST is an angle in radians, normalized to the range from 0 inclusive to 2π exclusive (Constitution principle 12). Degrees and hours are display formats and belong to req-mth-001.

The UTC ≈ UT1 decision of req-orb-001 is inherited. A DUT1 of up to 0.9 s moves GMST by at most 0.0038°, below one pixel on the globe.

## Definitions used by every requirement

These definitions are normative.

- **Vallado:** D. A. Vallado, *Fundamentals of Astrodynamics and Applications*, 4th ed., Microcosm Press, 2013, chapter 3.
- **Meeus:** J. Meeus, *Astronomical Algorithms*, 2nd ed., Willmann-Bell, 1998, chapter 12.
- **Two-part Julian date** and **Julian centuries (T):** as defined in `specs/req-orb-001.md`.
- **IAU-82 GMST polynomial (seconds of time):** 67310.54841 + (876600 · 3600 + 8640184.812866) · T + 0.093104 · T² − 6.2 · 10⁻⁶ · T³, as given by Vallado (eq. 3-47 `[TO VERIFY]`). Meeus eq. 12.4 is the same model written in degrees: 280.46061837 + 360.98564736629 · (JD − 2451545.0) + 0.000387933 · T² − T³ / 38710000.
- **GMST:** the IAU-82 polynomial converted to radians (one second of time is 2π / 86400 radians) and normalized to the range from 0 inclusive to 2π exclusive.
- **Published unit conversion:** in the tests, a published value in degrees is converted to radians by π / 180, and a value in hours, minutes and seconds of time by 2π / 86400 per second. Its tolerance is converted by the same factor.
- **Angular difference:** for two GMST values a and b, (b − a) normalized to the range from 0 inclusive to 2π exclusive.
- **Math test file:** `packages/orbital_core/test/gmst_test.dart`.
- **Guard test file:** `test/orbital_core_gmst_guard_test.dart`, in the application suite.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.
- **Exact:** compared with `==` on doubles, with no tolerance.

## Functional Requirements

### REQ-ORB-002.1 — GMST from a two-part Julian date

A two-part Julian date yields GMST.

**Acceptance (verified by the math test file).** Each instant is converted to a two-part Julian date by REQ-ORB-001.1 before GMST is computed.

| Instant (UTC) | Published GMST | Tolerance | Source |
| --- | --- | --- | --- |
| 1992-08-20T12:14:00Z | 152.578787810° `[TO VERIFY]` | 1·10⁻⁶° | Vallado, Example 3-5 `[TO VERIFY]`, p. `[TO VERIFY]`: T_UT1 = −0.073647919 |
| 1987-04-10T00:00:00Z | 13h 10m 46.3668s | 1·10⁻⁴ s of time | Meeus, Example 12.a |
| 1987-04-10T19:21:00Z | 8h 34m 57.0896s | 1·10⁻⁴ s of time | Meeus, Example 12.b |
| 2000-01-01T12:00:00Z | 280.46061837° | 1·10⁻⁸° | Meeus eq. 12.4 at J2000.0 (T = 0); equal to Vallado's 67310.54841 s |

- Every row passes.

### REQ-ORB-002.2 — Result range

GMST is always at least 0.0 and strictly less than 2π, including for negative T and at the edges of the valid range of req-orb-001.

**Acceptance (verified by the math test file).** For each instant below, GMST is greater than or equal to 0.0 and strictly less than 2π.

| Instant (UTC) | Why |
| --- | --- |
| 1900-03-01T00:00:00.000000Z | First valid instant; T near −1, the most negative polynomial value |
| 2100-02-28T23:59:59.999999Z | Last valid instant; T near +1, the largest polynomial value |
| 2000-01-01T12:00:00Z | J2000.0 (T = 0) |
| 1992-08-20T12:14:00Z | Negative T, published row |
| 2026-03-14T00:00:00.000001Z | Microsecond resolution of req-orb-001 |

### REQ-ORB-002.3 — Sidereal advance per solar day

Between 00:00:00Z of one date and 00:00:00Z of the next, the Earth turns one full revolution plus 0.98564736629°. This is the linear coefficient of Meeus eq. 12.4 (360.98564736629° per day) minus 360°. It is a property of the model, not a new formula, and it proves that the normalization neither loses nor adds a revolution.

**Acceptance (verified by the math test file).** For each pair, the angular difference of GMST from the first instant to the second equals 0.98564736629° within 1·10⁻⁷°. The tolerance covers the T² term, which changes the daily advance by less than 2.2·10⁻⁸° anywhere in the valid range.

| First | Second |
| --- | --- |
| 1987-04-10T00:00:00Z | 1987-04-11T00:00:00Z |
| 1999-12-31T00:00:00Z | 2000-01-01T00:00:00Z |
| 2024-02-28T00:00:00Z | 2024-02-29T00:00:00Z |
| 2100-02-27T00:00:00Z | 2100-02-28T00:00:00Z |

### REQ-ORB-002.4 — Documented model contract

The model decision and the output range are written in the public documentation of the GMST computation, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file):** one core library file contains all three lines below. A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- `/// GMST model: IAU-82, the model SGP4 uses for TEME.`
- `/// Result range: 0 inclusive to 2π exclusive, in radians.`
- `/// Reference: Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., chapter 3.`

### REQ-ORB-002.5 — Purity, placement and test hygiene

GMST lives in `packages/orbital_core`, is reachable through the package's public library only, and adds no dependency.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*)['"]`.
- The math test file contains, for each N from 1 to 3, a line equal to `// REQ-ORB-002.N` after trimming, and the next non-empty line after it starts with `test(` or `group(`.
- The guard test file contains, for each N in {4, 5}, a line equal to `// REQ-ORB-002.N` after trimming, and the next non-empty line after it starts with `test(`.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the math test file, the guard test file and the core library files contains the byte `0D` (CR), and none starts with the bytes `EF BB BF` (UTF-8 BOM).
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- A missing file read by the guard test file (the math test file, the guard test file itself, or the `packages/orbital_core/lib` directory) produces a failing test, never a skipped or passing one.
- Every failure message of the guard test file starts with `[REQ-ORB-002.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-002.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited in the math test file next to its assertion, by book, edition, chapter, example or equation number, page where known, date and value, as in the tables above (Constitution principle 6). The range checks of REQ-ORB-002.2 and the daily advance of REQ-ORB-002.3 are anchored to Meeus eq. 12.4 and introduce no new formula.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/gmst_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-002.1 – .3 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 still passes |
| V4 | `flutter test test/orbital_core_gmst_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-002.4, .5 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-002.5 |
| V6 | `flutter test` | exit 0 | REQ-ORB-002.4, .5; req-orb-001 guard still passes |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-002\.[0-9]+" packages/orbital_core/test/gmst_test.dart test/orbital_core_gmst_guard_test.dart \| sort -u \| wc -l` (inside the table, `\|` is a single pipe) | standard output `5` | REQ-ORB-002.5 |

The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after both test files are committed on the feature branch. For each row, apply the edit, run the command below, and confirm that it prints the tag. Then revert with `git checkout -- packages/orbital_core test` before the next row. "The GMST library file" is the core library file that contains the three lines of REQ-ORB-002.4.

    flutter test test/orbital_core_gmst_guard_test.dart 2>&1 | grep -F "<tag>"

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the GMST library file | `[REQ-ORB-002.5]` |
| G2 | Delete the line `/// GMST model: IAU-82, the model SGP4 uses for TEME.` from the GMST library file | `[REQ-ORB-002.4]` |
| G3 | Delete the line `/// Result range: 0 inclusive to 2π exclusive, in radians.` from the GMST library file | `[REQ-ORB-002.4]` |
| G4 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-002.5]` |
| G5 | Replace `// REQ-ORB-002.2` with `// REQ-ORB-002.x` in the math test file | `[REQ-ORB-002.5]` |
| G6 | Run `sed -i 's/$/\r/' packages/orbital_core/test/gmst_test.dart` (CRLF) | `[REQ-ORB-002.5]` |
| G7 | Delete the file `packages/orbital_core/test/gmst_test.dart` | `[REQ-ORB-002.5]` |

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V9 and G1–G7, each with its observed result. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **Negative T.** Every instant before J2000.0 gives a negative polynomial value. The normalization must still return a value from 0 inclusive to 2π exclusive (REQ-ORB-002.2, row 1900-03-01).
- **Value equal to 2π after rounding.** A result that rounds to exactly 2π is not valid output; it is reported as 0.0 (REQ-ORB-002.2: strictly less than 2π).
- **Precision of the large term.** At |T| = 1 the linear term reaches about 3.2·10⁹ seconds of time. A double resolves it to about 5·10⁻⁷ s of time, about 4·10⁻¹¹ rad, far below the tolerances of REQ-ORB-002.1.
- **Rounded published T.** Vallado prints T_UT1 rounded to nine decimals. The test computes T from the instant through req-orb-001 and never types the rounded value; the 1·10⁻⁶° tolerance covers the difference with the printed GMST.
- **Invalid instants.** Instants that are not UTC, or are outside the valid range, never reach GMST: REQ-ORB-001.4 rejects them when the two-part Julian date is built. This spec adds no new error.
- **DUT1, nutation and the equation of the equinoxes.** Ignored by decision (Context). Introducing any of them requires a spec change.
- **CRLF or BOM in the new files.** Rejected by the guard test file (REQ-ORB-002.5). The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Platform.** The math test file runs on the Dart VM, the default platform of `dart test`, as in req-orb-001.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.

## Out of Scope

Nothing below is written in this pull request:

- Greenwich Apparent Sidereal Time (GAST), nutation or the equation of the equinoxes.
- Local sidereal time or any observer longitude.
- The Earth's rotation rate or any velocity transformation (req-orb-006).
- The rotation of a vector from TEME or inertial coordinates to ECEF (req-orb-006).
- The IAU-2006 Earth Rotation Angle model.
- GMST in degrees or hours for display (req-mth-001).
- Any change to the Julian date conversion of req-orb-001, to `packages/orbital_core/test/julian_date_test.dart` or to `test/orbital_core_time_base_guard_test.dart`.
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution, the roadmap or any ADR.

## Open Questions

The developer confirms these against the printed books before implementation starts. The values above were consistent with the IAU-82 polynomial when computed during drafting (Vallado row 152.578787852°, Meeus rows 46.3668 s and 57.0896 s, J2000.0 280.460618375°), but they were written from memory, not copied from the books.

1. Vallado: the number and page of the IAU-82 GMST equation (drafted as eq. 3-47).
2. Vallado: the number and page of the GMST example (drafted as Example 3-5), its instant (drafted as 1992-08-20 12:14:00 UT1), its T_UT1 (drafted as −0.073647919) and its exact GMST value (drafted as 152.578787810°).
3. Meeus: that Examples 12.a and 12.b give 13h 10m 46.3668s and 8h 34m 57.0896s for the instants above, and that eq. 12.4 has the coefficients written in Definitions.
