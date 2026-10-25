# req-orb-001 — Julian date and UTC time base

- **Status:** Draft (revision 2, after QA audit)
- **Roadmap row:** 3 of 33 (MVP)
- **Blocks:** req-orb-002 (GMST from Julian date)
- **Depends on:** req-inf-001 (monorepo scaffold), req-inf-002 (CI quality gates), ADR-0001 (baseline packages)
- **Requires no new ADR:** the work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`.

## Context & Objective

GMST (req-orb-002) takes Julian centuries since J2000.0 as its input. That input cannot exist until the project has one agreed, tested conversion from a UTC instant to a Julian date. This spec delivers exactly what roadmap row 3 names: a UTC instant becomes a Julian date held in two parts (day part and fraction of day), and a Julian date yields Julian centuries since J2000.0.

Three decisions are fixed here so later specs inherit them:

- **Time scale.** UTC is treated as UT1. DUT1 (bounded by 0.9 s) and ΔT are ignored, so no IERS table or leap-second list is needed; either one would be a new data source under Constitution principle 1. A 0.9 s clock error moves GMST by at most 0.004°, which is below one pixel on the globe. J2000.0 is the epoch JD 2451545.0 on this UTC ≈ UT1 scale, as in Vallado's T_UT1.
- **Representation.** The Julian date is held as two parts, as in Vallado's day/fraction pair. A single double near JD 2.46 million resolves 40 µs; the two-part form resolves the fraction to better than one microsecond, which SGP4 implementations expect (req-orb-010).
- **Units.** Constitution principle 12 fixes km, seconds and radians for physical quantities. The Julian date is a calendar count, conventionally expressed in days, and Julian centuries are the input unit of the GMST polynomial (req-orb-002). Both are kept in those units because converting them to seconds would only reintroduce the factors 86 400 and 3 155 760 000 at every use.

The conversion follows Vallado's Julian date algorithm, whose published domain is 1900-03-01 through 2100-02-28. Instants outside that domain are rejected.

## Definitions used by every requirement

These definitions are normative.

- **Vallado:** D. A. Vallado, *Fundamentals of Astrodynamics and Applications*, 4th ed., Microcosm Press, 2013, chapter 3.
- **Meeus:** J. Meeus, *Astronomical Algorithms*, 2nd ed., Willmann-Bell, 1998, chapter 7.
- **UTC instant:** a value of Dart's standard date-time type whose UTC flag is true. Its resolution is one microsecond.
- **Valid range:** from 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z, both inclusive.
- **Day part:** the Julian date at 00:00:00 UTC of the instant's calendar date. "Ends in .5" means that the day part minus 0.5 is a whole number.
- **Fraction part:** the time elapsed since 00:00:00 UTC of that date, in seconds including microseconds, divided by 86 400.
- **Two-part Julian date:** the pair (day part, fraction part). In this spec it is produced only by the conversion of REQ-ORB-001.1.
- **Julian centuries (T):** (day part − 2451545.0 + fraction part) / 36525.
- **Math test file:** `packages/orbital_core/test/julian_date_test.dart`.
- **Guard test file:** `test/orbital_core_time_base_guard_test.dart`, in the application suite.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.
- **Exact:** compared with `==` on doubles, with no tolerance.

## Functional Requirements

### REQ-ORB-001.1 — UTC instant to two-part Julian date

A UTC instant inside the valid range converts to a two-part Julian date.

**Acceptance (verified by the math test file):**

| Instant (UTC) | Day part (exact) | Fraction part | Tolerance on fraction | Source |
| --- | --- | --- | --- | --- |
| 1996-10-26T14:20:00Z | 2450382.5 | 0.59722222 | 1·10⁻⁸ | Vallado: JD 2450383.09722222 |
| 1992-08-20T12:14:00Z | 2448854.5 | 0.509722 | 1·10⁻⁶ | Vallado (GMST example): JD 2448855.009722 |
| 1957-10-04T19:26:24Z | 2436115.5 | 0.81 | 1·10⁻¹² | Meeus: 1957 October 4.81 = JD 2436116.31 |
| 1987-01-27T00:00:00Z | 2446822.5 | 0.0 (exact) | — | Meeus: 1987 January 27.0 = JD 2446822.5 |
| 1987-06-19T12:00:00Z | 2446965.5 | 0.5 (exact) | — | Meeus: 1987 June 19.5 = JD 2446966.0 |
| 1988-01-27T00:00:00Z | 2447187.5 | 0.0 (exact) | — | Meeus: 1988 January 27.0 = JD 2447187.5 |
| 1988-06-19T12:00:00Z | 2447331.5 | 0.5 (exact) | — | Meeus: 1988 June 19.5 = JD 2447332.0 |
| 1999-01-01T00:00:00Z | 2451179.5 | 0.0 (exact) | — | Meeus: 1999 January 1.0 = JD 2451179.5 |
| 2000-01-01T12:00:00Z | 2451544.5 | 0.5 (exact) | — | Meeus: 2000 January 1.5 = JD 2451545.0 (J2000.0) |
| 2026-03-14T00:00:00.000001Z | 2461113.5 | 0.000001 / 86400 | 1·10⁻²⁰ | Definition of fraction part (microsecond resolution) |

- Every row passes.
- For every row, the day part ends in .5, and the fraction part is greater than or equal to 0.0 and strictly less than 1.0.

### REQ-ORB-001.2 — Calendar invariants

Day parts of consecutive calendar dates differ by exactly one day. This covers the leap-year rule, including the year-2000 exception, and the year rollover, which the published values of REQ-ORB-001.1 do not reach. It is a property of the calendar, not a new formula.

**Acceptance (verified by the math test file).** Each item is the day part of the second instant minus the day part of the first, compared exactly. All instants are at 00:00:00Z.

| First | Second | Difference (exact) | Proves |
| --- | --- | --- | --- |
| 1999-12-31 | 2000-01-01 | 1.0 | Year rollover |
| 2000-02-28 | 2000-02-29 | 1.0 | 2000 is a leap year (divisible by 400) |
| 2000-02-29 | 2000-03-01 | 1.0 | Leap day to March |
| 2024-02-28 | 2024-02-29 | 1.0 | 2024 is a leap year |
| 2024-02-29 | 2024-03-01 | 1.0 | Leap day to March |
| 2023-02-28 | 2023-03-01 | 1.0 | 2023 is not a leap year |
| 2000-02-28 | 2000-03-01 | 2.0 | February 2000 has 29 days |

### REQ-ORB-001.3 — Julian centuries since J2000.0

A two-part Julian date yields T as defined above.

**Acceptance (verified by the math test file):**

| Instant (UTC) | T | Tolerance | Source |
| --- | --- | --- | --- |
| 2000-01-01T12:00:00Z | 0.0 | exact | Definition of J2000.0 |
| 1992-08-20T12:14:00Z | −0.073647919 | 1·10⁻⁹ | Vallado (GMST example): T_UT1 = −0.073647919 |
| 2100-01-01T12:00:00Z | 1.0 | 1·10⁻¹² | Definition of the Julian century (36 525 days) |
| 1900-03-01T00:00:00Z | less than 0.0 | — | Instants before J2000.0 give negative T |

### REQ-ORB-001.4 — Input validation with exact messages

The conversion of REQ-ORB-001.1 accepts only UTC instants inside the valid range. Any other input throws Dart's `ArgumentError` and returns no value. The UTC check runs before the range check.

- **Message U:** `Julian date conversion requires a UTC instant.`
- **Message R:** `Julian date conversion supports 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z only.`

**Acceptance (verified by the math test file).** "Throws U" means the thrown object is an `ArgumentError` whose message is equal to message U, character for character; the same applies to R.

| Input | Expected |
| --- | --- |
| 2026-03-14 10:00:00, UTC flag false | Throws U |
| 1850-01-01 00:00:00, UTC flag false | Throws U (UTC check runs first) |
| 1900-02-28T23:59:59.999999Z | Throws R |
| 1900-01-01T00:00:00.000000Z | Throws R |
| 2100-03-01T00:00:00.000000Z | Throws R |
| 1900-03-01T00:00:00.000000Z | Accepted. Day part exactly 2415079.5, which equals Meeus 1900 January 1.0 = JD 2415020.5 plus 59.0 (31 days of January and 28 of February: 1900 is not a leap year). Fraction part exactly 0.0. |
| 2100-02-28T23:59:59.999999Z | Accepted. Day part exactly 2488127.5, which equals 2451544.5 + 36525.0 + 58.0 (J2000.0 day part plus one Julian century to 2100-01-01, plus 31 days of January and 27 of February). Fraction part equal to 86399.999999 / 86400 within 1·10⁻¹⁵ and strictly less than 1.0. |

### REQ-ORB-001.5 — Documented time-scale contract

The time-scale decision and the valid range are written in the public documentation of the conversion, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file):** at least one core library file contains each of these three lines. A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- `/// UTC is treated as UT1.`
- `/// Valid range: 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z.`
- `/// Reference: Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., chapter 3.`

### REQ-ORB-001.6 — Purity, placement and test hygiene

The time base lives in `packages/orbital_core`, is reachable through the package's public library only, and adds no dependency.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*)['"]`. This forbids imports from `lib/src` and relative imports.
- The math test file contains, for each N from 1 to 4, a line equal to `// REQ-ORB-001.N` after trimming, and the next non-empty line after it starts with `test(` or `group(`.
- The guard test file contains, for each N in {5, 6}, a line equal to `// REQ-ORB-001.N` after trimming, and the next non-empty line after it starts with `test(`.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the math test file, the guard test file and the core library files contains the byte `0D` (CR), and none starts with the bytes `EF BB BF` (UTF-8 BOM).
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- A missing file read by the guard test file (the math test file, the guard test file itself, or the `packages/orbital_core/lib` directory) produces a failing test, never a skipped or passing one.
- Every failure message of the guard test file starts with `[REQ-ORB-001.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-001.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0. This is the req-inf-001 guard proving that neither manifest declares a dependency outside ADR-0001 and that `orbital_core` declares no runtime dependency.

## Mathematical Validation / Testing

Every published value is cited in the math test file next to its assertion, by book, edition, chapter, date and value, as in the tables above (Constitution principle 6). The invariants of REQ-ORB-001.2 and the bounds of REQ-ORB-001.4 are anchored to Meeus 1900 January 1.0, to J2000.0 and to the definition of the Julian century. They introduce no new formula.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/julian_date_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-001.1 – .4 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3 |
| V4 | `flutter test test/orbital_core_time_base_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-001.5, .6 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-001.6 |
| V6 | `flutter test` | exit 0 | REQ-ORB-001.5, .6 and the req-inf-002 contract |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-001\.[0-9]+" packages/orbital_core/test/julian_date_test.dart test/orbital_core_time_base_guard_test.dart \| sort -u \| wc -l` (inside the table, `\|` is a single pipe) | standard output `6` | REQ-ORB-001.6 |

The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after both test files are committed on the feature branch. For each row, apply the edit, run the command below, and confirm that it prints the tag. Then revert with `git checkout -- packages/orbital_core test` before the next row. "The library file" is any core library file that contains the three lines of REQ-ORB-001.5.

    flutter test test/orbital_core_time_base_guard_test.dart 2>&1 | grep -F "<tag>"

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the library file | `[REQ-ORB-001.6]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the library file | `[REQ-ORB-001.6]` |
| G3 | Add `export 'dart:ffi';` as the first line of the library file | `[REQ-ORB-001.6]` |
| G4 | Delete the line `/// UTC is treated as UT1.` from the library file | `[REQ-ORB-001.5]` |
| G5 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-001.6]` |
| G6 | Replace `// REQ-ORB-001.3` with `// REQ-ORB-001.x` in the math test file | `[REQ-ORB-001.6]` |
| G7 | Run `sed -i 's/$/\r/' packages/orbital_core/test/julian_date_test.dart` (CRLF) | `[REQ-ORB-001.6]` |
| G8 | Delete the file `packages/orbital_core/test/julian_date_test.dart` | `[REQ-ORB-001.6]` |

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V9 and G1–G8, each with its observed result. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **Instant not flagged as UTC.** Rejected with message U, never converted. A silent conversion would depend on the device time zone and break Constitution principle 12. The caller converts to UTC before calling.
- **Not UTC and out of range at once.** Message U wins because the UTC check runs first (REQ-ORB-001.4, row 1850-01-01).
- **Outside the valid range.** Rejected with message R. Vallado's algorithm is published for 1900-03-01 through 2100-02-28 only.
- **Leap second (23:59:60).** Dart's standard date-time type cannot represent it and normalizes it to the next minute. The time base never receives a leap second, which matches the UTC ≈ UT1 decision.
- **DUT1 and ΔT.** Ignored by decision (Context). Introducing either requires a spec change and a data source approved by ADR.
- **Instants before J2000.0.** T is negative. That is a valid result, not an error (REQ-ORB-001.3).
- **Last microsecond of a day.** The fraction part stays strictly below 1.0 and the day part does not roll over (REQ-ORB-001.4, last row).
- **CRLF or BOM in the new files.** Rejected by the guard test file (REQ-ORB-001.6). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Platform.** The math test file runs on the Dart VM, the default platform of `dart test`. On the JavaScript platform, Dart's date-time type resolves milliseconds only, so the microsecond row of REQ-ORB-001.1 is not valid there. The JavaScript platform is not a target of this project (REQ-INF-001.2: Android only).
- **Network or CI runner failure.** This spec adds no network access. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.

## Out of Scope

Nothing below is written in this pull request:

- Signed elapsed time between two Julian dates (moved to req-orb-004, whose roadmap objective "advance mean anomaly to time t" requires it).
- A single combined Julian date value for display (deferred to req-mth-001).
- GMST or any sidereal angle (req-orb-002).
- TLE or OMM epoch parsing, including the `yyddd.dddddddd` epoch format (req-orb-003).
- Producing a two-part Julian date from raw numbers rather than from a UTC instant. If req-orb-003 needs it, that spec adds it together with its own validation of the day-part and fraction-part invariants.
- The inverse conversion from Julian date back to a UTC instant.
- UT1, TT, TAI, DUT1, ΔT, leap-second tables, or any data file or network source.
- The simulation clock, time multipliers or any `Ticker` (req-tim-001, req-tim-002).
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution, the roadmap or any ADR.

## Open Questions

None.
