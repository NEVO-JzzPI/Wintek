# req-orb-004 — Kepler equation solver

- **Status:** Draft (revision 2, after the first QA audit). Blocked on ADR-0004, which is Proposed; ready for implementation once the developer accepts it. Every published value was checked against a freely available primary source while drafting (see Definitions).
- **Roadmap row:** 6 of 33 (MVP)
- **Blocks:** req-orb-005 (perifocal to inertial state vector, which needs E), req-orb-009 (propagator state carries M and E), req-mth-001 (math mode shows M and E)
- **Depends on:** req-orb-001 (two-part Julian date), req-orb-003 (element set), req-inf-002 (CI quality gates), ADR-0001 (baseline packages), ADR-0003 (TLE element sets and their units), ADR-0004 (derived reference values for the linear mean anomaly)
- **ADR:** ADR-0004 makes a bounded exception to Constitution principle 6 for the linear mean anomaly of REQ-ORB-004.2, which has no free published numeric example (QA audit, finding 5). The work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`, so ADR-0001 is unchanged. The reference values come from a repository licensed under AGPL-3.0; this spec and its tests cite published numbers and one line of the formula only, and copy no code from it.

## Context & Objective

The in-house Kepler propagator turns one element set into a position at any instant. Before it can place the object in its orbital plane (req-orb-005), it needs two angles at that instant:

- the mean anomaly M, which grows linearly with time;
- the eccentric anomaly E, which is tied to M by Kepler's equation `M = E − e·sin E`. That equation has no closed-form solution for E, so it is solved iteratively.

This spec delivers what roadmap row 6 names: advance the mean anomaly to a time t, and solve Kepler's equation by Newton-Raphson.

It also delivers the signed elapsed time between two two-part Julian dates. req-orb-001 moved this here (its Out of Scope) because advancing M needs it. It is a time-base operation, not part of the solver, so it gets its own library file: req-tim-001 and req-orb-009 can then use it without depending on the solver.

The decisions below are fixed so later specs inherit them. The developer approved each one before drafting or during the QA audit.

- **Linear mean anomaly.** M(t) = M₀ + n · (t − t₀), exactly as step 2 of the Project Brief's pipeline.
  - The element set's ṅ/2 and n̈/6 terms are not used; they belong to SGP4 (req-orb-010).
  - The mean motion n is the Kozai mean motion that the element set stores (req-orb-003), used as is.
  - Its reference values are derived under ADR-0004.
- **Plain inputs for the solver.** The solver takes a mean anomaly and an eccentricity as plain numbers, with its own validation, so that published (M, e) → E pairs are tested directly. Advancing M takes an element set and a UTC instant. No public way to build an element set from plain values is added (req-orb-003, Out of Scope, remains in force).
- **Input validation.** The solver rejects NaN and infinite inputs and eccentricities outside the elliptical range, each with an exact message. The roadmap row does not name this. It is kept because the solver runs on the frame path: an unchecked NaN would flow silently into the position and the globe, and a check costs almost nothing.
- **Convergence contract.** Newton-Raphson starts from the initial guess of Vallado's Algorithm 2, stops when one step changes E by at most 1·10⁻¹² rad, and gives up after 50 steps by throwing an error with an exact message.
- **One normalization.** Every result angle is normalized to the range from 0 inclusive to 2π exclusive by one fixed operation (Definitions). Two reasonable reductions can differ by about 3·10⁻¹¹ rad for an input of 1·10⁶ rad (QA audit, finding 1), so the operation is fixed; any other one would make the exact checks undecidable.
- **Elliptical orbits only.** Eccentricity is accepted from 0 inclusive to 1 exclusive, the range an element set can carry (req-orb-003). Parabolic and hyperbolic forms of Kepler's equation are not implemented.
- **Fixed public names.** The three public entry points have the declarations fixed in REQ-ORB-004.6, so the guard test file verifies them by machine. A duration in seconds carries the suffix `Seconds`; an angle in radians carries `Rad`. The short suffix `RadS` stays reserved for rates, as in `meanMotionRadS` of req-orb-003.
- **Free sources only.** Every reference value of the solver comes from the test suite that CelesTrak publishes with the code of Vallado's textbook, pinned to a commit (Definitions). Values from printed books that a reviewer cannot check free of charge are not used.

## Definitions used by every requirement

These definitions are normative.

- **Vallado repository:** CelesTrak, "fundamentals-of-astrodynamics", at `https://github.com/CelesTrak/fundamentals-of-astrodynamics`, licensed under AGPL-3.0. Its description reads: code related to *Fundamentals of Astrodynamics and Applications*, 5th ed., by David Vallado. Three of its files are cited, each pinned to a commit:
  - `software/python/tests/astro/twobody/test_newton.py` at commit `e90b6f6584dd53330e71ee5496aea2eea3853f9b`. It publishes the solver values of REQ-ORB-004.3:
    - its test `test_newtonm` publishes (e, M) → E pairs, one of them labelled "Vallado Ex. 2-1";
    - its tests `test_newtone` and `test_newtonnu` publish (e, E) → M pairs, which this spec reads backwards as (M, e) → E;
  - `software/python/src/valladopy/astro/twobody/newton.py` at commit `116b8cd9f9a34372785260b8be73526d665ca84a`, function `newtonm`, which gives the initial guess and cites "Vallado: 2022, p. 65, Algorithm 2";
  - `software/python/src/valladopy/astro/twobody/kepler.py` at commit `c05278b458e806775c91d1fe74b5ff6e583c8d82`, line 217, `m += mdot * dtsec + ndot * dtsec**2 + nddot * dtsec**3`. This is the published source of the linear mean anomaly when the derivative terms are zero (ADR-0004).
- **Meeus:** J. Meeus, *Astronomical Algorithms*, 2nd ed., Willmann-Bell, 1998, chapter 7, as cited in `specs/req-orb-001.md`. Every Meeus Julian date below is already a reference row of req-orb-001, so this spec adds no new book value.
- **UTC instant**, **valid range**, **two-part Julian date** (day part, fraction part): as defined in `specs/req-orb-001.md`.
- **Element set**, **Vallado SGP4**, and the published sets **00005** and **28129**: as defined in `specs/req-orb-003.md`, including their epochs (REQ-ORB-003.2) and converted values (REQ-ORB-003.1).
- **Elapsed time from A to B**, for two two-part Julian dates A and B: ((day part of B − day part of A) + (fraction part of B − fraction part of A)) · 86400, in seconds, evaluated in this order. It is positive when B is later than A, negative when B is earlier and 0.0 when they are equal.
- **2π (as a double):** the double nearest to 2π, that is, `2 * pi` with `pi` from `dart:math` (6.283185307179586).
- **Normalized angle:** for a double x, the result of Dart's `%` operator on doubles with x as the dividend and 2π (as a double) as the divisor. A result equal to 2π (as a double) is replaced by 0.0. Dart's `%` takes the exact IEEE 754 remainder and adds the divisor when that remainder is negative. Any implementation that returns the same double for every input conforms. For example, 1·10⁶ normalizes to 5.925621140132833 and −1·10⁶ to 0.3575641670467533.
- **Mean anomaly at an instant t,** for an element set: M₀ + n · Δt, normalized. Here M₀ is the element set's mean anomaly, n its mean motion in radians per second, and Δt the elapsed time from the two-part Julian date of the element set's epoch to the two-part Julian date of t. Both dates are produced by REQ-ORB-001.1.
- **Kepler's equation:** M = E − e · sin E, where M is the mean anomaly, E the eccentric anomaly (both in radians) and e the eccentricity.
- **Normalized input:** the mean anomaly given to the solver, normalized.
- **Initial guess (Vallado's Algorithm 2, as given by the Vallado repository):** E₀ = M − e when the normalized input M is greater than π, otherwise E₀ = M + e.
- **Newton step:** E(k+1) = E(k) − (E(k) − e · sin E(k) − M) / (1 − e · cos E(k)), where M is the normalized input.
- **Converged:** one Newton step changes E by at most 1·10⁻¹² rad in absolute value. The solver applies Newton steps from the initial guess until it has converged, at most 50 times. Its result is the last E, normalized.
- **Residual** of a result E for inputs M and e: r = E − e · sin E − (normalized input), normalized; when r is π or more, 2π (as a double) is subtracted from it, so the residual lies from −π inclusive to π exclusive.
- **Close to within x:** the absolute difference from the expected value is at most x.
- **Exact:** compared with `==` on doubles, with no tolerance.
- **Elapsed-time library file:** `packages/orbital_core/lib/src/elapsed_time.dart`.
- **Kepler library file:** `packages/orbital_core/lib/src/kepler.dart`.
- **New library files:** the elapsed-time library file and the Kepler library file.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/kepler_test.dart`. It covers REQ-ORB-004.1 to .5, including the elapsed time.
- **Guard test file:** `test/orbital_core_kepler_guard_test.dart`, in the application suite.
- **Spec file:** `specs/req-orb-004.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-004.1 — Elapsed time between two-part Julian dates

Two two-part Julian dates yield the signed elapsed time from the first to the second, in seconds.

**Acceptance (verified by the math test file).** Each instant is converted to a two-part Julian date by REQ-ORB-001.1 before the elapsed time is computed. Every row passes.

| From (UTC) | To (UTC) | Elapsed time | Tolerance | Source |
| --- | --- | --- | --- | --- |
| 1987-01-27T00:00:00Z | 1988-01-27T00:00:00Z | 31536000.0 s | exact | Meeus: JD 2446822.5 to JD 2447187.5 is 365 days |
| 1988-01-27T00:00:00Z | 1987-01-27T00:00:00Z | −31536000.0 s | exact | Same pair, reversed: the sign follows the order |
| 1987-06-19T12:00:00Z | 1988-06-19T12:00:00Z | 31622400.0 s | exact | Meeus: JD 2446966.0 to JD 2447332.0 is 366 days |
| 1999-01-01T00:00:00Z | 2000-01-01T12:00:00Z | 31579200.0 s | exact | Meeus: JD 2451179.5 to JD 2451545.0 is 365.5 days |
| 2000-01-01T12:00:00Z | 2000-01-01T12:00:00Z | 0.0 s | exact | Equal dates |
| 2026-03-14T00:00:00Z | 2026-03-14T00:00:00.000001Z | 0.000001 s | 1·10⁻¹² s | Definition of fraction part in req-orb-001 (microsecond resolution) |
| 1900-03-01T00:00:00.000000Z | 2100-02-28T23:59:59.999999Z | 6311433599.999999 s | 1·10⁻⁵ s | Day parts 2415079.5 and 2488127.5 of REQ-ORB-001.4: 73048 days plus 86399.999999 s |

The tolerance of the last row covers the resolution of a double near 6.3·10⁹ s, about 9.5·10⁻⁷ s. Evaluated as Definitions fixes it, the error measured while drafting was 4.6·10⁻⁸ s.

### REQ-ORB-004.2 — Mean anomaly at an instant

An element set and a UTC instant yield the mean anomaly at that instant, before or after the epoch.

**Acceptance (verified by the math test file).**

- Each element set is parsed from its two published lines in REQ-ORB-003.1, written as string literals in the math test file.
- Under ADR-0004, every row except the first is marked "Derived". Its expected value comes from the published fields in degrees and revolutions per day, by the linear formula of Definitions, written out in the Source column. It is then converted to radians by multiplying by π / 180.
- The implementation works in radians and radians per second, so the derivation does not follow its path.
- Every row passes within 1·10⁻¹⁰ rad.

| Set | Instant (UTC) | Offset from epoch | Expected mean anomaly | Source |
| --- | --- | --- | --- | --- |
| 00005 | 2000-06-27T18:50:19.733568Z | 0 | 0.3373093125574321 rad (the element set's own mean anomaly) | Published: REQ-ORB-003.1 and .2 (anchor row of ADR-0004) |
| 00005 | 2000-06-28T18:50:19.733568Z | +1 day | 316.0353652° = 5.515857675482708 rad | Derived: 19.3264° + 10.82419157 rev/day · 360° · 1 day, minus 10 revolutions |
| 00005 | 2000-06-26T18:50:19.733568Z | −1 day | 82.6174348° = 1.441946256811743 rad | Derived: 19.3264° − 10.82419157 · 360° · 1, plus 11 revolutions |
| 00005 | 2000-06-28T06:50:19.733568Z | +12 hours | 167.6808826° = 2.9265834940200697 rad | Derived: 19.3264° + 10.82419157 · 360° · 0.5, minus 5 revolutions |
| 28129 | 2006-07-24T13:41:49.461504Z | +30 days | 153.945244° = 2.6868513755860457 rad | Derived: 93.1663° + 2.00562768 · 360° · 30, minus 60 revolutions |
| 28129 | 2006-05-25T13:41:49.461504Z | −30 days | 32.387356° = 0.5652659982155406 rad | Derived: 93.1663° − 2.00562768 · 360° · 30, plus 60 revolutions |

- The first row is exact: at the epoch the elapsed time is 0.0, so the result equals the element set's mean anomaly with no tolerance.
- For every row, the result is greater than or equal to 0.0 and strictly less than 2π (as a double).
- The tolerance of 1·10⁻¹⁰ rad covers the rounding of n · Δt (about 380 rad for the 28129 rows), which is below 1·10⁻¹³ rad.
- An instant that is not UTC, or lies outside the valid range, throws the `ArgumentError` of REQ-ORB-001.4 with its message unchanged:
  - 2006-06-24 13:41:49 with the UTC flag false throws message U of req-orb-001;
  - 2100-03-01T00:00:00.000000Z throws message R of req-orb-001.

### REQ-ORB-004.3 — Kepler's equation from published values

A mean anomaly and an eccentricity yield the eccentric anomaly that solves Kepler's equation.

**Acceptance (verified by the math test file).** Every row passes within 1·10⁻¹¹ rad, the tolerance the Vallado repository uses for the same assertions. Values given in degrees are converted to radians by multiplying by π / 180.

| Mean anomaly | Eccentricity | Expected eccentric anomaly | Source (Vallado repository, `test_newton.py`) | Proves |
| --- | --- | --- | --- | --- |
| 235.4° | 0.4 | 3.8486617450971616 rad | `test_newtonm`, row labelled "Vallado Ex. 2-1" | Third quadrant; the textbook example |
| 6.011077700843401 rad | 0.4 | 334.566986° = 5.839295474173773 rad | `test_newtone`, elliptical row, read backwards | Fourth quadrant (initial guess M − e) |
| 37.31406335764441° | 0.1 | 41.078960346507934° = 0.7169631113427541 rad | `test_newtonnu`, read backwards | Low eccentricity, first quadrant |
| π / 3 | 0.0 | π / 3 | `test_newtonm`, circular row | Circular orbit: E equals M |
| π | 0.9999 | π | `test_newtonm`, near-parabolic row | Eccentricity near 1 at apoapsis |

The repository's own solver printed the published value of the first row, and that solver returns the next-to-last iterate. The value therefore differs from the exact root of Kepler's equation by about 8·10⁻¹⁵ rad, far below the tolerance.

### REQ-ORB-004.4 — Convergence, range and residual

The solver converges for every valid input, returns a normalized angle, and its result satisfies Kepler's equation.

**Acceptance (verified by the math test file).**

- **Grid.** The grid is every eccentricity in {0.0, 1·10⁻⁷, 0.001, 0.1, 0.4, 0.7, 0.9, 0.99, 0.999, 0.9999, 0.99999, 0.999999, 0.9999999} combined with every mean anomaly k · 2π / 360, for k from 0 to 359. For each pair:
  - the solver returns without throwing;
  - the result is greater than or equal to 0.0 and strictly less than 2π (as a double);
  - the absolute value of the residual is at most 1·10⁻¹² rad.

  The largest eccentricity is the largest value the TLE eccentricity field can carry (req-orb-003, field table).
- **Edge inputs.** The same three conditions hold for each mean anomaly below, combined with each eccentricity in {0.0, 1·10⁻⁷, 0.5, 0.9999999}:
  - 5·10⁻³²⁴ (the smallest positive double) and 1·10⁻³⁰⁰;
  - −1·10⁻²⁰;
  - 2π − 1·10⁻¹⁵, 2π and −2π, with 2π as a double;
  - π and −π;
  - 1·10⁶ and −1·10⁶.
- **Circular orbits.** For eccentricity 0.0 and every mean anomaly of the grid and of the edge inputs, the result equals the normalized input exactly.

The edge inputs are there to break careless normalizations:

- For a mean anomaly near 0 and an eccentricity near 1, Newton-Raphson can end at a tiny negative E, about −1.7·10⁻²⁸ rad. Adding 2π to it rounds to exactly 2π (as a double), which the range forbids.
- For ±1·10⁶, any reduction other than the one fixed in Definitions moves the normalized input by about 3·10⁻¹¹ rad and fails the residual check.

When this spec was drafted, a reference evaluation of this exact grid and these edge inputs needed at most 23 Newton steps and failed no condition.

### REQ-ORB-004.5 — Input validation with exact messages

The solver accepts only a finite mean anomaly and a finite eccentricity from 0 inclusive to 1 exclusive. Any other input throws Dart's `ArgumentError` and returns no value. Checks run in this order and the first failure wins: mean anomaly finite, then eccentricity finite, then eccentricity range. "Finite" means neither NaN nor positive or negative infinity. No message contains an apostrophe, so each can be written in the Kepler library file as a plain single-quoted string.

- **Message N-M:** `Kepler solver requires a finite mean anomaly.`
- **Message N-E:** `Kepler solver requires a finite eccentricity.`
- **Message R-E:** `Kepler solver supports eccentricity from 0 inclusive to 1 exclusive only.`
- **Message C:** `Kepler solver did not converge in 50 iterations.` This one is thrown as Dart's `StateError`, never as `ArgumentError`, because it reports a defect of the solver, not of the input.

**Acceptance (verified by the math test file).** "Throws X" means the thrown object is an `ArgumentError` whose message is equal to message X, character for character.

| Mean anomaly | Eccentricity | Expected |
| --- | --- | --- |
| NaN | 0.4 | Throws N-M |
| positive infinity | 0.4 | Throws N-M |
| negative infinity | 0.4 | Throws N-M |
| NaN | 2.0 | Throws N-M (mean anomaly is checked first) |
| 1.0 | NaN | Throws N-E |
| 1.0 | positive infinity | Throws N-E |
| 1.0 | 1.0 | Throws R-E |
| 1.0 | 1.5 | Throws R-E |
| 1.0 | −1·10⁻¹² | Throws R-E |
| 1.0 | −0.0 | Accepted; the result equals 1.0 exactly (negative zero is equal to 0.0) |
| 1.0 | 0.9999999 | Accepted |

**Acceptance (verified by the guard test file).** No valid input reaches message C (REQ-ORB-004.4), so its presence is checked in the source. The Kepler library file contains the substring `Kepler solver did not converge in 50 iterations.` and the substring `StateError(`.

**Acceptance (verified by review, item R1 of the pull request checklist).** The reviewer confirms by reading the Kepler library file that message C is thrown when 50 Newton steps have not converged, and that the solver never returns an unconverged value.

### REQ-ORB-004.6 — Placement, public names and documented contract

The elapsed time lives in the elapsed-time library file. The mean anomaly at an instant and the solver live in the Kepler library file. All three are reachable through the public library file. The documentation states the formulas, the initial guess, the convergence contract, the mean anomaly model, the normalization, the range and the reference, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The elapsed-time library file and the Kepler library file exist.
- The public library file contains the lines `export 'src/elapsed_time.dart';` and `export 'src/kepler.dart';`.
- The elapsed-time library file contains each of these three lines:
  - `/// Elapsed time: ((day B - day A) + (fraction B - fraction A)) * 86400, in seconds.`
  - `/// Sign: positive when B is later than A, negative when earlier, 0 when equal.`
  - `/// Input: the two-part Julian dates of req-orb-001 only.`
- The Kepler library file contains each of these seven lines:
  - `/// Kepler's equation: M = E - e sin E, solved by Newton-Raphson.`
  - `/// Initial guess: E0 = M - e when M > pi, otherwise M + e.`
  - `/// Convergence: |E(k+1) - E(k)| <= 1e-12 rad within 50 iterations.`
  - `/// Mean anomaly: M = M0 + n (t - t0), linear; ndot / 2 and nddot / 6 are not used.`
  - `/// Normalization: Dart's % by 2 * pi; a result equal to 2 * pi becomes 0.`
  - `/// Result range: 0 inclusive to 2π exclusive, in radians.`
  - `/// Reference: CelesTrak fundamentals-of-astrodynamics, newton.py, newtonm (Vallado: 2022, p. 65, Algorithm 2).`
- **Public names.** Each declaration below must appear in its file on a line that, with leading and trailing spaces removed, starts with the declaration and continues with a character that is not a letter, a digit, `_` or `$` (or ends there). These names are the contract that req-orb-005, req-orb-009 and req-tim-001 read. Each fits on one line within the 80 columns of `dart format`.
  - In the elapsed-time library file: `double elapsedSeconds(JulianDate from, JulianDate to)`
  - In the Kepler library file: `double meanAnomalyAtRad(OrbitalElements elements, DateTime utc)`
  - In the Kepler library file: `double eccentricAnomalyRad(double meanAnomalyRad, double eccentricity)`

**Acceptance (verified by command V11).** This pull request changes none of `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart` and `gmst.dart`.

**Acceptance (verified by review, item R2 of the pull request checklist).** The reviewer confirms that the new library files declare no public top-level name other than the three above.

### REQ-ORB-004.7 — Purity, citations and test hygiene

The new code adds no dependency, every published value is cited in the math test file, and the new files follow the hygiene rules of req-orb-003.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file contains each of these five citation lines, compared after trimming:
  - `// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_newton.py, commit e90b6f6584dd53330e71ee5496aea2eea3853f9b.`
  - `// Vallado repository, test_newton.py, newtonm row "Vallado Ex. 2-1": M = 235.4 deg, e = 0.4, E = 3.8486617450971616 rad.`
  - `// Vallado repository, kepler.py, commit c05278b458e806775c91d1fe74b5ff6e583c8d82, line 217: linear mean anomaly; rows derived under ADR-0004.`
  - `// Meeus, Astronomical Algorithms, 2nd ed., chapter 7: JD 2446822.5, 2447187.5, 2446966.0, 2447332.0, 2451179.5, 2451545.0.`
  - `// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005 and 28129.`
- The math test file contains, for each N from 1 to 5, a line equal to `// REQ-ORB-004.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
- The guard test file contains, for each N in {5, 6, 7}, a line equal to `// REQ-ORB-004.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the guard test file, the core library files and the spec file.
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser. `dart:io` never appears in `packages/orbital_core`, which the two regular expressions above enforce.
- Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, either new library file, the public library file, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-004.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-004.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-004.7, which the guard test file checks (Constitution principle 6). The sources are:

- **Solver (REQ-ORB-004.3):** values published by the Vallado repository.
- **Elapsed times (REQ-ORB-004.1):** differences of Meeus Julian dates already cited by req-orb-001.
- **Mean anomalies (REQ-ORB-004.2):** one published anchor row, and rows derived from the published fields of Vallado's verification element sets under the bounded exception of ADR-0004. The formula's source is the pinned line of the Vallado repository.
- **Grid (REQ-ORB-004.4):** checks Kepler's equation itself and introduces no new formula.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `wc` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/kepler_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-004.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-003 still pass |
| V4 | `flutter test test/orbital_core_kepler_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-004.5 (message C), .6, .7 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-004.7 |
| V6 | `flutter test` | exit 0 | REQ-ORB-004.5 – .7; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-004\.[0-9]+" packages/orbital_core/test/kepler_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-004.1,// REQ-ORB-004.2,// REQ-ORB-004.3,// REQ-ORB-004.4,// REQ-ORB-004.5` | REQ-ORB-004.7 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-004\.[0-9]+" test/orbital_core_kepler_guard_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-004.5,// REQ-ORB-004.6,// REQ-ORB-004.7` | REQ-ORB-004.7 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --exit-code origin/main...HEAD -- packages/orbital_core/lib/src/orbital_elements.dart packages/orbital_core/lib/src/tle_parser.dart packages/orbital_core/lib/src/julian_date.dart packages/orbital_core/lib/src/gmst.dart` | exit 0 | REQ-ORB-004.6 (earlier library files unchanged) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after both test files are committed on the feature branch. For each row:

1. Apply the edit.
2. Run the command below and confirm that it prints at least one line. That line carries both the expected tag and the spec path.
3. Revert with `git checkout -- packages/orbital_core test specs` before the next row.

The command is:

    flutter test test/orbital_core_kepler_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-004.md"

Inside the table, `\|` is a single pipe.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the Kepler library file | `[REQ-ORB-004.7]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the Kepler library file | `[REQ-ORB-004.7]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the Kepler library file | `[REQ-ORB-004.7]` |
| G4 | Add `import 'dart:ffi';` as the first line of the elapsed-time library file | `[REQ-ORB-004.7]` |
| G5 | Delete the line `/// Kepler's equation: M = E - e sin E, solved by Newton-Raphson.` from the Kepler library file | `[REQ-ORB-004.6]` |
| G6 | Delete the line `/// Initial guess: E0 = M - e when M > pi, otherwise M + e.` from the Kepler library file | `[REQ-ORB-004.6]` |
| G7 | Delete the line `/// Convergence: \|E(k+1) - E(k)\| <= 1e-12 rad within 50 iterations.` from the Kepler library file | `[REQ-ORB-004.6]` |
| G8 | Delete the line `/// Mean anomaly: M = M0 + n (t - t0), linear; ndot / 2 and nddot / 6 are not used.` from the Kepler library file | `[REQ-ORB-004.6]` |
| G9 | Delete the line `/// Normalization: Dart's % by 2 * pi; a result equal to 2 * pi becomes 0.` from the Kepler library file | `[REQ-ORB-004.6]` |
| G10 | Delete the line `/// Result range: 0 inclusive to 2π exclusive, in radians.` from the Kepler library file | `[REQ-ORB-004.6]` |
| G11 | Delete the line `/// Reference: CelesTrak fundamentals-of-astrodynamics, newton.py, newtonm (Vallado: 2022, p. 65, Algorithm 2).` from the Kepler library file | `[REQ-ORB-004.6]` |
| G12 | Delete the line `/// Elapsed time: ((day B - day A) + (fraction B - fraction A)) * 86400, in seconds.` from the elapsed-time library file | `[REQ-ORB-004.6]` |
| G13 | Delete the line `/// Sign: positive when B is later than A, negative when earlier, 0 when equal.` from the elapsed-time library file | `[REQ-ORB-004.6]` |
| G14 | Delete the line `/// Input: the two-part Julian dates of req-orb-001 only.` from the elapsed-time library file | `[REQ-ORB-004.6]` |
| G15 | Delete the line `export 'src/kepler.dart';` from the public library file | `[REQ-ORB-004.6]` |
| G16 | Delete the line `export 'src/elapsed_time.dart';` from the public library file | `[REQ-ORB-004.6]` |
| G17 | Delete the file `packages/orbital_core/lib/src/kepler.dart` | `[REQ-ORB-004.6]` |
| G18 | Delete the file `packages/orbital_core/lib/src/elapsed_time.dart` | `[REQ-ORB-004.6]` |
| G19 | Replace `double eccentricAnomalyRad(` with `double eccentricAnomaly(` in the Kepler library file | `[REQ-ORB-004.6]` |
| G20 | Replace `double meanAnomalyAtRad(` with `double meanAnomalyAt(` in the Kepler library file | `[REQ-ORB-004.6]` |
| G21 | Replace `double elapsedSeconds(` with `double elapsedS(` in the elapsed-time library file | `[REQ-ORB-004.6]` |
| G22 | Replace `did not converge in 50 iterations.` with `did not converge.` in the Kepler library file | `[REQ-ORB-004.5]` |
| G23 | Replace every `StateError(` with `Exception(` in the Kepler library file | `[REQ-ORB-004.5]` |
| G24 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-004.7]` |
| G25 | Add `import 'package:orbital_core/src/kepler.dart';` to the math test file | `[REQ-ORB-004.7]` |
| G26 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-004.7]` |
| G27 | Replace `// REQ-ORB-004.3` with `// REQ-ORB-004.x` in the math test file | `[REQ-ORB-004.7]` |
| G28 | Insert the line `// note` directly after the line `// REQ-ORB-004.1` in the math test file | `[REQ-ORB-004.7]` |
| G29 | Delete the citation line that starts with `// Vallado repository: https://` from the math test file | `[REQ-ORB-004.7]` |
| G30 | Delete the citation line that starts with `// Vallado repository, test_newton.py, newtonm row` from the math test file | `[REQ-ORB-004.7]` |
| G31 | Delete the citation line that starts with `// Vallado repository, kepler.py` from the math test file | `[REQ-ORB-004.7]` |
| G32 | Delete the citation line that starts with `// Meeus,` from the math test file | `[REQ-ORB-004.7]` |
| G33 | Delete the citation line that starts with `// Vallado et al., Revisiting Spacetrack Report #3` from the math test file | `[REQ-ORB-004.7]` |
| G34 | Append the line `// skip: true` to the math test file | `[REQ-ORB-004.7]` |
| G35 | Run `sed -i 's/$/\r/' packages/orbital_core/test/kepler_test.dart` (CRLF) | `[REQ-ORB-004.7]` |
| G36 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/kepler_test.dart > /tmp/g36 && mv /tmp/g36 packages/orbital_core/test/kepler_test.dart` (BOM) | `[REQ-ORB-004.7]` |
| G37 | Run `sed -i 's/$/\r/' specs/req-orb-004.md` (CRLF in the spec file) | `[REQ-ORB-004.7]` |
| G38 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-004.7]` |
| G39 | Replace `// REQ-ORB-004.6` with `// REQ-ORB-004.x` in the guard test file | `[REQ-ORB-004.7]` |
| G40 | Delete the file `packages/orbital_core/test/kepler_test.dart` | `[REQ-ORB-004.7]` |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V11 and G1–G40, each with its observed result, and the review items below. A pull request without this list is incomplete regardless of its check status.

- **R1:** the reviewer confirms REQ-ORB-004.5 (review acceptance): message C is thrown after 50 unconverged Newton steps, and the solver never returns an unconverged value.
- **R2:** the reviewer confirms REQ-ORB-004.6 (review acceptance): the new library files declare no public top-level name other than the three fixed declarations.

## Edge Cases & Errors

- **Instants before the epoch.** Negative elapsed times are valid and give a mean anomaly that is still normalized (REQ-ORB-004.2, −1 day and −30 days rows). The time controls of req-tim-002 run the clock backwards, so this is a normal case, not an error.
- **Large elapsed times.** n · Δt grows without limit, but the linear model is only meaningful within days of the epoch. This spec does not check the age of the element set (req-dat-004, req-ui-004). Precision stays below 1·10⁻¹⁰ rad for at least ±30 days (REQ-ORB-004.2).
- **Mean anomaly outside 0 to 2π.** The solver accepts it and normalizes it before the initial guess, by the one operation of Definitions (REQ-ORB-004.4, edge inputs ±2π, ±1·10⁶).
- **Result rounding to 2π.** A tiny negative E plus 2π rounds to exactly 2π (as a double); the normalized angle replaces it by 0.0 (Definitions). REQ-ORB-004.4 includes the inputs that trigger it.
- **Eccentricity near 1.** The reference evaluation needed at most 23 steps over the grid of REQ-ORB-004.4; the cap of 50 leaves margin. The denominator 1 − e · cos E is at least 1 − 0.9999999 = 1·10⁻⁷ and never zero for a valid eccentricity.
- **Invalid solver input.** An eccentricity of 1 or more, a negative, NaN or infinite eccentricity, and a NaN or infinite mean anomaly are rejected with an exact `ArgumentError` message (REQ-ORB-004.5). Negative zero is accepted as 0.0.
- **Non-convergence.** Unreachable for valid input. If it ever happens, the solver throws a `StateError` with message C and never returns a partial value (REQ-ORB-004.5, guard check and R1). The fix is in the solver. A larger cap is never the fix without a spec change.
- **Invalid instants.** An instant that is not UTC, or lies outside the valid range, is rejected by REQ-ORB-001.4 when its two-part Julian date is built, with req-orb-001's message unchanged. This spec adds no new time error.
- **Precision of the elapsed time.** Day parts end in .5 and are exact in a double. Subtracting them first, as Definitions fixes, keeps the fraction digits. Across the whole valid range the error stays below 1·10⁻⁵ s (REQ-ORB-004.1).
- **Declarations split by the formatter.** Each fixed declaration fits within 80 columns, so `dart format` keeps it on one line. If a future formatter splits one, the guard reports `[REQ-ORB-004.6]`. The fix is a spec change, never a relaxed guard.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-004.7). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access at run time. V11 needs `git fetch` and is a local check; if the fetch fails, V11 counts as not run, never as a pass. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.

## Out of Scope

Nothing below is written in this pull request:

- Parabolic or hyperbolic forms of Kepler's equation, or any eccentricity of 1 or more.
- True anomaly, the semi-major axis, the position in the orbital plane or any rotation to the inertial frame (req-orb-005).
- Using ṅ/2, n̈/6 or B\* to advance the mean anomaly, or any secular rate of the node or perigee (req-orb-010 owns every perturbation).
- Converting the Kozai mean motion to the Brouwer mean motion (req-orb-005, req-orb-010).
- The propagator interface, a propagated state object, or carrying M and E in it (req-orb-009).
- A public way to build an element set from plain values, or any change to `packages/orbital_core/lib/src/orbital_elements.dart`, `packages/orbital_core/lib/src/tle_parser.dart` or their tests and guard.
- Any change to the Julian date conversion of req-orb-001 or to GMST of req-orb-002, to their library files, tests or guards. The elapsed time is added in its own library file, not in `julian_date.dart`.
- Displaying M or E in degrees, or any formatting for math mode (req-mth-001).
- Any data age threshold or staleness check (req-dat-004, req-ui-004).
- Copying code from the Vallado repository; only its published values and one line of the formula are cited.
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR. ADR-0004 travels with this spec in the spec pull request, never in the implementation pull request.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None. ADR-0004 is Proposed; until the developer accepts it, the Status line keeps this spec blocked.
