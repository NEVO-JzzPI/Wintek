# req-orb-002 — GMST from Julian date

- **Status:** Ready for implementation (revision 2, after QA audit). Every published value was checked against a freely available primary source during revision (see Definitions).
- **Roadmap row:** 4 of 33 (MVP)
- **Blocks:** req-orb-006 (inertial to ECEF rotation), req-orb-009 (propagator state carries GMST), req-mth-001 (math mode shows GMST)
- **Depends on:** req-orb-001 (Julian date and UTC time base), req-inf-002 (CI quality gates), ADR-0001 (baseline packages)
- **ADR:** the Constitution requires none, because the work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`. The choice of the IAU-82 model is a lasting decision. It is recorded in Context, and a separate ADR-0003 (GMST model) may be written if the developer approves it; that ADR does not block this spec.

## Context & Objective

SGP4 delivers positions in the TEME frame, and the in-house Kepler propagator delivers them in an inertial frame. Neither can be drawn on a rotating Earth until the app knows how far the Earth has turned. That angle is Greenwich Mean Sidereal Time (GMST). This spec delivers exactly what roadmap row 4 names: a two-part Julian date (req-orb-001) yields GMST, the rotation angle that req-orb-006 applies.

Three decisions are fixed here so later specs inherit them:

- **Model.** GMST follows the IAU-82 model: the polynomial in Julian centuries of UT1 defined by Aoki et al. (1982) and given by Vallado as eq. 3-45. Vallado's own SGP4 source code (AIAA 2006-6753) computes GMST with exactly this polynomial to rotate TEME, so req-orb-006 and req-orb-010 stay consistent with it. The IAU-2006 Earth Rotation Angle model is not used.
- **Input.** The only input is the two-part Julian date produced by REQ-ORB-001.1, through its Julian centuries since J2000.0. A raw number cannot reach GMST, so the valid range and the UTC check of REQ-ORB-001.4 are inherited without being repeated.
- **Output.** GMST is an angle in radians, from 0 inclusive to 2π exclusive (Constitution principle 12). Degrees and hours are display formats and belong to req-mth-001.

The UTC ≈ UT1 decision of req-orb-001 is inherited. A DUT1 of up to 0.9 s moves GMST by at most 0.0038°, below one pixel on the globe.

## Definitions used by every requirement

These definitions are normative.

- **Vallado:** D. A. Vallado, *Fundamentals of Astrodynamics and Applications*, 4th ed., Microcosm Press, 2013, eq. 3-45, p. 187. The equation number and page are the ones Vallado cites for the function `gstime` in his own SGP4 source code, published free of charge with D. A. Vallado, P. Crawford, R. Hujsak and T. S. Kelso, "Revisiting Spacetrack Report #3", AIAA 2006-6753, at `https://celestrak.org/publications/AIAA/2006-6753/`.
- **SOFA:** the IAU Standards of Fundamental Astronomy library, through its open-source derivative ERFA. Its validation program `t_erfa_c.c`, test `t_gmst82`, publishes the GMST of the UT1 Julian date 2400000.5 + 53736.0 (2006-01-01T00:00:00 UT1) as 1.754174981860675096 rad. Its function `gmst82` cites Aoki et al., *Astronomy and Astrophysics* 105, 359–361 (1982).
- **Two-part Julian date** and **Julian centuries (T):** as defined in `specs/req-orb-001.md`.
- **IAU-82 GMST polynomial (seconds of time):** 67310.54841 + (876600 · 3600 + 8640184.812866) · T + 0.093104 · T² − 6.2 · 10⁻⁶ · T³ (Vallado). The term 876600 · 3600 equals 36525 · 86400, so the daily advance of GMST beyond one revolution is 8640184.812866 / 36525 seconds of time.
- **GMST:** the IAU-82 polynomial converted to radians (one second of time is 2π / 86400 radians) and normalized to the range from 0 inclusive to 2π exclusive.
- **Angular difference:** for two GMST values a and b, (b − a) normalized to the range from 0 inclusive to 2π exclusive.
- **GMST library file:** `packages/orbital_core/lib/src/gmst.dart`.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/gmst_test.dart`.
- **Guard test file:** `test/orbital_core_gmst_guard_test.dart`, in the application suite.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-002.1 — GMST from a two-part Julian date

A two-part Julian date yields GMST.

**Acceptance (verified by the math test file).** Each instant is converted to a two-part Julian date by REQ-ORB-001.1 before GMST is computed. Every row passes.

| Instant (UTC) | Published GMST | Tolerance | Source |
| --- | --- | --- | --- |
| 2006-01-01T00:00:00Z | 1.754174981860675096 rad | 1·10⁻¹⁰ rad | SOFA, test `t_gmst82` |
| 2000-01-01T12:00:00Z | 67310.54841 s of time = 4.894961212823059 rad | 1·10⁻¹⁰ rad | Vallado: constant term of the polynomial at J2000.0 (T = 0) |

The tolerance of 1·10⁻¹⁰ rad (about 4 mm at geostationary distance) admits Vallado's direct evaluation of the polynomial, which is the form SGP4 uses. It differs from SOFA's day-separated evaluation by about 1.5·10⁻¹² rad at the SOFA instant.

### REQ-ORB-002.2 — Result range

GMST is always at least 0.0 and strictly less than 2π, including for negative T and at the edges of the valid range of req-orb-001.

**Acceptance (verified by the math test file).** For each instant below, GMST is greater than or equal to 0.0 and strictly less than 2π.

| Instant (UTC) | Why |
| --- | --- |
| 1900-03-01T00:00:00.000000Z | First valid instant; T near −1, the most negative polynomial value |
| 2100-02-28T23:59:59.999999Z | Last valid instant; T near +1, the largest polynomial value |
| 2000-01-01T12:00:00Z | J2000.0 (T = 0) |
| 1992-08-20T12:14:00Z | Negative T |
| 2006-01-01T00:00:00Z | SOFA instant, positive T |
| 2026-03-14T00:00:00.000001Z | Microsecond resolution of req-orb-001 |

### REQ-ORB-002.3 — Sidereal advance per solar day

Between 00:00:00Z of one date and 00:00:00Z of the next, the Earth turns one full revolution plus 8640184.812866 / 36525 seconds of time, that is 0.017202791805307 rad (0.98564736629°). This follows from the linear coefficient of the polynomial (Definitions). It is a property of the model, not a new formula, and it proves that the normalization neither loses nor adds a revolution.

**Acceptance (verified by the math test file).** For each pair, the angular difference of GMST from the first instant to the second equals 0.017202791805307 rad within 1.75·10⁻⁹ rad (1·10⁻⁷°). The tolerance covers the T² term, which changes the daily advance by less than 4·10⁻¹⁰ rad anywhere in the valid range.

| First | Second |
| --- | --- |
| 1987-04-10T00:00:00Z | 1987-04-11T00:00:00Z |
| 1999-12-31T00:00:00Z | 2000-01-01T00:00:00Z |
| 2024-02-28T00:00:00Z | 2024-02-29T00:00:00Z |
| 2100-02-27T00:00:00Z | 2100-02-28T00:00:00Z |

### REQ-ORB-002.4 — Placement and documented contract

GMST lives in the GMST library file, is reachable through the public library file, and its documentation states the model, the range, the input and the reference, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The GMST library file exists.
- The public library file contains the line `export 'src/gmst.dart';`.
- The GMST library file contains each of these four lines:
  - `/// GMST model: IAU-82, the model SGP4 uses for TEME.`
  - `/// Result range: 0 inclusive to 2π exclusive, in radians.`
  - `/// Input: the two-part Julian date of req-orb-001 only.`
  - `/// Reference: Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., eq. 3-45, p. 187.`

**Acceptance (verified by review, item R1 of the pull request checklist).** The public library exposes GMST only from a two-part Julian date: no public function, method, getter or constructor of `orbital_core` computes GMST from a plain number. The reviewer confirms this by reading the GMST library file, which is the only file this spec adds under `packages/orbital_core/lib`.

### REQ-ORB-002.5 — Purity, citations and test hygiene

GMST adds no dependency, every published value is cited in the math test file, and the new test files follow the hygiene rules of req-orb-001.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*)['"]`.
- The math test file contains each of these citation lines, compared after trimming:
  - `// SOFA/ERFA t_erfa_c.c, test t_gmst82: JD 2400000.5 + 53736.0 (2006-01-01T00:00:00 UT1) = 1.754174981860675096 rad.`
  - `// Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., eq. 3-45, p. 187: 67310.54841 s at T = 0.`
- The math test file contains, for each N from 1 to 3, a line equal to `// REQ-ORB-002.N` after trimming, and the next non-empty line after it starts with `test(` or `group(`.
- The guard test file contains, for each N in {4, 5}, a line equal to `// REQ-ORB-002.N` after trimming, and the next non-empty line after it starts with `test(`.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the math test file, the guard test file and the core library files contains the byte `0D` (CR), and none starts with the bytes `EF BB BF` (UTF-8 BOM).
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- A missing math test file, GMST library file, public library file or `packages/orbital_core/lib` directory produces a failing test, never a skipped or passing one. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-002.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-002.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-002.5, which the guard test file checks (Constitution principle 6). The range checks of REQ-ORB-002.2 and the daily advance of REQ-ORB-002.3 are anchored to the coefficients of the polynomial and introduce no new formula.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `wc` and `printf` with byte escapes.

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

These run after both test files are committed on the feature branch. For each row, apply the edit, run the command below, and confirm that it prints at least one line. That line carries both the expected tag and the spec path. Then revert with `git checkout -- packages/orbital_core test` before the next row.

    flutter test test/orbital_core_gmst_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-002.md"

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the GMST library file | `[REQ-ORB-002.5]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the GMST library file | `[REQ-ORB-002.5]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the GMST library file | `[REQ-ORB-002.5]` |
| G4 | Delete the line `/// GMST model: IAU-82, the model SGP4 uses for TEME.` from the GMST library file | `[REQ-ORB-002.4]` |
| G5 | Delete the line `/// Result range: 0 inclusive to 2π exclusive, in radians.` from the GMST library file | `[REQ-ORB-002.4]` |
| G6 | Delete the line `/// Input: the two-part Julian date of req-orb-001 only.` from the GMST library file | `[REQ-ORB-002.4]` |
| G7 | Delete the line `/// Reference: Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., eq. 3-45, p. 187.` from the GMST library file | `[REQ-ORB-002.4]` |
| G8 | Delete the line `export 'src/gmst.dart';` from the public library file | `[REQ-ORB-002.4]` |
| G9 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-002.5]` |
| G10 | Add `import 'package:orbital_core/src/gmst.dart';` to the math test file | `[REQ-ORB-002.5]` |
| G11 | Replace `// REQ-ORB-002.2` with `// REQ-ORB-002.x` in the math test file | `[REQ-ORB-002.5]` |
| G12 | Delete the SOFA citation line of REQ-ORB-002.5 from the math test file | `[REQ-ORB-002.5]` |
| G13 | Append the line `// skip: true` to the math test file | `[REQ-ORB-002.5]` |
| G14 | Run `sed -i 's/$/\r/' packages/orbital_core/test/gmst_test.dart` (CRLF) | `[REQ-ORB-002.5]` |
| G15 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/gmst_test.dart > /tmp/g15 && mv /tmp/g15 packages/orbital_core/test/gmst_test.dart` (BOM; inside the table, `\|` is a single pipe) | `[REQ-ORB-002.5]` |
| G16 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-002.5]` |
| G17 | Delete the file `packages/orbital_core/test/gmst_test.dart` | `[REQ-ORB-002.5]` |

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V9 and G1–G17, each with its observed result, and the review item below. A pull request without this list is incomplete regardless of its check status.

- **R1:** the reviewer confirms REQ-ORB-002.4 (review acceptance): no public entry point of `orbital_core` computes GMST from a plain number.

## Edge Cases & Errors

- **Negative T.** Every instant before J2000.0 gives a negative polynomial value. The result must still lie from 0 inclusive to 2π exclusive (REQ-ORB-002.2, row 1900-03-01). Any normalization that satisfies REQ-ORB-002.2 is acceptable; a value that rounds to exactly 2π fails it.
- **Precision of the large term.** At |T| = 1 the linear term reaches about 3.2·10⁹ seconds of time. A double resolves it to about 5·10⁻⁷ s of time, about 4·10⁻¹¹ rad, below the 1·10⁻¹⁰ rad tolerance of REQ-ORB-002.1.
- **Invalid instants.** Instants that are not UTC, or are outside the valid range, never reach GMST: REQ-ORB-001.4 rejects them when the two-part Julian date is built. This spec adds no new error.
- **DUT1, nutation and the equation of the equinoxes.** Ignored by decision (Context). Introducing any of them requires a spec change.
- **CRLF or BOM in the new files.** Rejected by the guard test file (REQ-ORB-002.5). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V9 prints a count below 5.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.
- **Network or CI runner failure.** This spec adds no network access. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Platform.** The math test file runs on the Dart VM, the default platform of `dart test`, as in req-orb-001.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.

## Out of Scope

Nothing below is written in this pull request:

- Greenwich Apparent Sidereal Time (GAST), nutation or the equation of the equinoxes.
- Local sidereal time or any observer longitude.
- The Earth's rotation rate or any velocity transformation (req-orb-006).
- The rotation of a vector from TEME or inertial coordinates to ECEF (req-orb-006).
- Any SGP4 code or library (req-orb-010, ADR-0002). This spec only states which GMST model SGP4 uses.
- The IAU-2006 Earth Rotation Angle model, or SOFA's day-separated evaluation as a requirement.
- GMST in degrees or hours for display (req-mth-001).
- Any change to the Julian date conversion of req-orb-001, to `packages/orbital_core/lib/src/julian_date.dart`, to `packages/orbital_core/test/julian_date_test.dart` or to `test/orbital_core_time_base_guard_test.dart`.
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
