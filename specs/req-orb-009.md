# req-orb-009 — Propagator interface and Kepler implementation

- **Status:** Draft (revision 1), pending the first QA audit. On 2026-11-08, before drafting, the developer approved four decisions: a propagator bound to one element set, a common state with a Kepler subtype that adds M and E, a propagation failure type fixed now, and validation by identity and invariants with no new ADR. On the same day the developer approved the drafting plan, including the assumptions listed in Context. Every measured figure below was measured in Dart with a throwaway prototype of this contract, which is not part of the repository.
- **Roadmap row:** 11 of 33 (MVP)
- **Blocks:** req-orb-010 (the SGP4 adapter implements the interface fixed here), req-sta-001 (reads the propagated state each frame), req-mth-001 (math mode reads M, E, GMST and the ECEF vector from the Kepler state), req-viz-006 (samples the state over one period)
- **Depends on:** req-orb-001 (`JulianDate` and its UTC checks), req-orb-002 (`gmstRad`), req-orb-003 (`OrbitalElements` and the TLE parser), req-orb-004 (`meanAnomalyAtRad` and `eccentricAnomalyRad`), req-orb-005 (`CartesianVector`, `StateVector`, `semiMajorAxisKmFromMeanMotion` and `inertialStateVector`), req-orb-006 (`ecefPositionKm`), req-orb-008 (the decision that the state carries the inertial velocity, and that the derived values stay outside it), req-inf-002 (CI quality gates), ADR-0001 (baseline packages), ADR-0003 (TLE element sets).
- **ADR:** none required. The seam is a contract of this spec, not an architectural exception: it adds no dependency to either `pubspec.yaml` (ADR-0001 is unchanged), it uses only files of `packages/orbital_core` (Constitution principle 3), and it chooses no SGP4 library (ADR-0002, not yet written). Constitution principle 6 asks for a published reference value for every new or changed formula. The Kepler implementation adds no formula: every number it returns is the result of a function of req-orb-002, req-orb-004, req-orb-005 or req-orb-006, each already validated against published values in its own spec. REQ-ORB-009.1 proves that composition exactly, and the guard of REQ-ORB-009.5 forbids any arithmetic of its own in the implementation file. If a reviewer reads the closing sentence of ADR-0005 ("any other formula that has no published reference value needs its own ADR") as covering a composition, the way out is a new ADR, not a change of the tests.

## Context & Objective

Roadmap row 11 asks for "the one seam every propagator implements, returning a state that already carries M, E, GMST, ECEF and the inertial position and velocity, so math mode and the derived values of req-orb-008 later need no refactor". req-orb-002 to req-orb-008 deliver each step as a function of plain numbers, and none of them takes an element set and an instant together. This spec joins them: an interface that every propagator implements, the state it returns, the failure it may report, and the in-house Kepler propagator that implements it by composing the existing functions.

The developer approved the first four decisions below before drafting.

- **Bound to one element set.** A propagator is built from one `OrbitalElements` and returns its state at any UTC instant. SGP4 initializes its model once per element set, so the SGP4 adapter of req-orb-010 fits this shape without per-frame initialization. req-sta-001 builds one propagator per tracked object when its elements change and asks it for a state every frame.
- **Common state and Kepler subtype.** Every propagator returns a common state: the instant, the inertial position and velocity, GMST and the Earth-fixed position. M and E belong to the Kepler model; SGP4 does not produce them in the same sense. The Kepler propagator returns a subtype of the common state that adds them. Its method is declared with the subtype as return type, so math mode (req-mth-001) reads M and E from a Kepler propagator without a cast, while every other consumer reads the common state through the interface.
- **Failure type fixed now.** The interface declares a dedicated exception type for a model that cannot propagate an element set to an instant, such as a decayed object in SGP4. The Kepler propagator never throws it. req-orb-010 maps the failures of the chosen library to it. Fixing it here keeps the seam unchanged when req-orb-010 lands; req-orb-008 (Edge Cases, Error output of a propagator) left this to the propagator specs.
- **Validation by identity and invariants.** No published source gives a two-body propagation from a TLE to a position. Each field of the Kepler state is therefore compared with `==` to the result of the functions it composes, with the same inputs (REQ-ORB-009.1), and the composition is checked by invariants that a wrong wiring breaks: the mean anomaly at the epoch, the return to the same position after whole periods, and a geostationary orbit that hardly moves in Earth-fixed axes while it moves through tens of thousands of kilometres in inertial ones (REQ-ORB-009.2).

The developer approved these assumptions with the drafting plan.

- **Contents of the common state.** The instant, the inertial `StateVector` of req-orb-005, GMST in radians and the Earth-fixed position as a `CartesianVector`. This closes the question that req-orb-005 left open: req-orb-010 reuses `StateVector` and `CartesianVector` through this state.
- **Not in the state.** Geodetic coordinates (req-orb-007), the derived values (req-orb-008) and any Earth-relative velocity (req-orb-006, Context, Position only). They are pure functions of what the state carries, and req-sta-001 composes them, as req-orb-008 decided for the derived values. Keeping them out keeps the seam to the list of roadmap row 11.
- **Elements exposed.** A propagator exposes the element set it was built from, because req-sta-001 needs the mean motion for the period and the semi-major axis of req-orb-008.
- **Exception, not error.** The failure type is an `Exception`: a decayed object is a condition of the data at run time, not a defect of the program. An invalid instant stays an `ArgumentError`, as req-orb-001 defines it.
- **Instant as a UTC `DateTime`.** The clock of req-tim-001 produces UTC instants, and `meanAnomalyAtRad` already takes one. The Julian date is computed inside the propagator; it is not part of the seam.

The remaining decisions follow from the Constitution and the existing specs.

- **Fixed semantics of GMST and ECEF.** The interface documentation states that GMST is `gmstRad` of the Julian date of the instant and the Earth-fixed position is `ecefPositionKm` of the inertial position at that GMST. Every propagator, req-orb-010 included, therefore produces the same GMST and ECEF for the same instant and inertial position, so the globe and math mode never mix two models of Earth rotation.
- **Finite results.** A propagator returns finite values or throws. A NaN must never reach the frame path silently (req-orb-008, Context, Input validation); req-orb-010 maps a NaN of its library to the failure type.
- **Composition only.** The Kepler implementation file calls the existing functions and holds no arithmetic, no `dart:math` and no constant of its own. The guard enforces this by text (REQ-ORB-009.5).
- **No state between calls.** A propagator holds only its element set, so two calls with the same instant return equal states whatever was asked in between (REQ-ORB-009.3). req-tim-002 runs time backwards and req-viz-006 samples a whole period, so neither may depend on call order.
- **Units.** Kilometres, kilometres per second, seconds and radians (Constitution principle 12). The instant is UTC (AGENTS.md, Time).
- **Cost.** The prototype measured 0.87 µs per Kepler state on the development machine (100 000 states in 87 ms), far below the frame budget of Constitution principle 13. This is recorded, not tested; profiling belongs to req-sta-001.

## Definitions used by every requirement

These definitions are normative.

- **Propagator library file:** `packages/orbital_core/lib/src/propagator.dart`. It declares the interface, the common state and the failure type.
- **Kepler library file:** `packages/orbital_core/lib/src/kepler_propagator.dart`. It declares the Kepler state and the Kepler propagator.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/propagator_test.dart`. It covers REQ-ORB-009.1 to .4.
- **Guard test file:** `test/orbital_core_propagator_guard_test.dart`, in the application suite.
- **Spec file:** `specs/req-orb-009.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.
- **The two new library files:** the propagator library file and the Kepler library file.
- **Code line:** a line whose text, with leading spaces removed, does not start with `//`.
- **Published element sets:** the four TLEs below, as the repository's TLE parser test already uses them.
  - **NOAA 14:** the example of CelesTrak, "NORAD Two-Line Element Set Format" (`https://celestrak.org/NORAD/documentation/tle-fmt.php`), lines `1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621` and `2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148495`.
  - **Sets 00005, 23599 and 28129** of `SGP4-VER.TLE`, Vallado et al., "Revisiting Spacetrack Report #3", AIAA 2006-6753:
    - `1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753` and `2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667`;
    - `1 23599U 95029B   06171.76535463  .00085586  12891-6  12956-2 0  2905` and `2 23599   6.9327   0.2849 5782022 274.4436  25.2425  4.47796565123555`;
    - `1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459` and `2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443`.
- **Synthetic GEO set:** an element set built for this spec, not a published object, with valid checksums: `1 99999U 26001A   26310.50000000  .00000000  00000-0  00000-0 0  9991` and `2 99999   0.0100 100.0000 0001000  90.0000 180.0000  1.00273791000019`. Its epoch is 2026-11-06T12:00:00Z, its inclination 0.01°, its eccentricity 0.0001 and its mean motion 1.00273791 revolutions per day, about one sidereal day.
- **Test element sets:** the four published element sets and the synthetic GEO set, five in total.
- **Grid instants** of an element set with epoch t0: t0; t0 + 90 min; t0 + 1 day; t0 − 1 day; t0 + 30 days; 2026-11-08T00:00:00Z; 1900-03-01T00:00:00.000000Z and 2100-02-28T23:59:59.999999Z, the first and last instants that req-orb-001 accepts. Eight in total, all UTC.
- **Expected values** of an element set and an instant t, computed in the math test file through the public library file:
  - M = `meanAnomalyAtRad` of the element set at t;
  - E = `eccentricAnomalyRad` of M and the eccentricity of the element set;
  - a = `semiMajorAxisKmFromMeanMotion` of the mean motion of the element set;
  - the inertial state = `inertialStateVector` with a, the eccentricity, the inclination, the ascending node and the argument of perigee of the element set, and E;
  - GMST = `gmstRad` of `JulianDate.fromUtc` of t;
  - the Earth-fixed position = `ecefPositionKm` of the position of the inertial state at GMST.
- **Kepler state of an element set at t:** the result of asking a Kepler propagator built from that element set for its state at t (REQ-ORB-009.6).
- **Period of an element set:** 2π divided by its mean motion in radians per second, with `pi` from `dart:math`.
- **k periods after the epoch:** the epoch plus a `Duration` of k · period · 10⁶ microseconds, rounded to the nearest integer.
- **Distance:** the square root of the sum of the squares of the differences of the three components of two vectors.
- **Close to within x:** the absolute difference from the expected value is at most x.
- **Exact:** compared with `==`, with no tolerance, so 0.0 and −0.0 compare equal.
- **Julian message U:** `Julian date conversion requires a UTC instant.`
- **Julian message R:** `Julian date conversion supports 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z only.`

## Functional Requirements

### REQ-ORB-009.1 — The Kepler state is the composition of the validated functions

Every field of the Kepler state equals the result of the function it composes, with the same inputs.

**Acceptance (verified by the math test file).** For each of the five test element sets and each of its eight grid instants, 40 states in total, the Kepler state at that instant has:

| Field of the state | Expected | Compared |
| --- | --- | --- |
| the instant | the grid instant | exact |
| the mean anomaly | M | exact |
| the eccentric anomaly | E | exact |
| each component of the inertial position | the same component of the position of the inertial state | exact |
| each component of the inertial velocity | the same component of the velocity of the inertial state | exact |
| GMST | GMST | exact |
| each component of the Earth-fixed position | the same component of the Earth-fixed position | exact |

The test counts the states and checks that the count is 40. Every comparison measured equal in the prototype, because the propagator calls the same functions with the same inputs.

### REQ-ORB-009.2 — Invariants of the composition

The state at the epoch starts from the published mean anomaly, the orbit closes after whole periods, and a geostationary orbit stays almost fixed in Earth-fixed axes.

**Acceptance (verified by the math test file).**

- **Epoch.** For each of the five test element sets, the mean anomaly of the Kepler state at its epoch is exactly the mean anomaly of the element set. All five measured equal.
- **Whole periods.** For each of the five test element sets and each k from 1 to 10, the distance between the inertial position of the Kepler state k periods after the epoch and the one at the epoch is at most 1·10⁻⁴ km, and the distance between their inertial velocities is at most 1·10⁻⁷ km/s. The largest distances measured were 3.7·10⁻⁶ km and 3.6·10⁻⁹ km/s; they come from rounding the instant to a microsecond and from the floating-point growth of M.
- **Geostationary.** For the synthetic GEO set and each whole hour h from 1 to 24 after its epoch, the distance between the Earth-fixed position at epoch + h and the one at the epoch is at most 30 km. The largest distance measured was 17.0 km, at 12 h: the inclination of 0.01° moves the position by about ±7.4 km along the z axis, and the eccentricity of 0.0001 moves the radius by about ±4.2 km. At epoch + 12 h, the distance between the inertial positions is at least 80 000 km; it measured 84 327.6 km. A propagator that skipped the rotation to Earth-fixed axes, or rotated by a wrong angle, fails this row.

### REQ-ORB-009.3 — Conformance to the seam

The Kepler propagator implements the interface, its state is a common state, it keeps no state between calls, and the failure type carries its message.

**Acceptance (verified by the math test file).**

- **Interface.** A Kepler propagator built from NOAA 14 and held in a variable whose static type is the interface returns, at the epoch of NOAA 14, an object that is a common state and a Kepler state.
- **Elements.** The element set that the Kepler propagator exposes is identical (`identical`) to the one it was built from.
- **Finite and in range.** For each of the 40 states of REQ-ORB-009.1, all twelve numbers (M, E, GMST, the three components of each of the inertial position, the inertial velocity and the Earth-fixed position) are finite, and M, E and GMST are from 0 inclusive to 2π exclusive. All 40 measured finite and in range.
- **No state between calls.** For NOAA 14, a Kepler propagator asked for its state at t0 + 30 days, then at t0 − 1 day, then again at t0 + 30 days, returns two states at t0 + 30 days whose twelve numbers are exactly equal.
- **Failure type.** The failure type built with the message `Model failure.` is an `Exception`, its message is `Model failure.`, and its string form is `PropagationException: Model failure.`.

### REQ-ORB-009.4 — Invalid instants

An instant that req-orb-001 rejects is rejected by the propagator with the same error, and no state is returned.

**Acceptance (verified by the math test file).** "Throws X" means the thrown object is an `ArgumentError`, and therefore not the failure type, whose message is equal to X, character for character.

| Instant passed to the Kepler propagator built from NOAA 14 | Expected |
| --- | --- |
| 2026-11-08T00:00:00 as a local `DateTime`, not flagged as UTC | Throws Julian message U |
| 1900-02-28T23:59:59.999999Z | Throws Julian message R |
| 2100-03-01T00:00:00.000000Z | Throws Julian message R |

The Kepler propagator adds no check of its own: the errors come from `JulianDate.fromUtc`, which `meanAnomalyAtRad` calls first. The Kepler propagator never throws the failure type, which is documented (REQ-ORB-009.6) and follows from the guard of REQ-ORB-009.5: its file holds no arithmetic that could fail.

### REQ-ORB-009.5 — Placement, composition only and no copied constants

The two new library files live in the core, are reachable through the public library file, compose the existing functions and hold no formula or constant of their own.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- Both new library files exist.
- The public library file contains the lines `export 'src/kepler_propagator.dart';` and `export 'src/propagator.dart';`.
- The propagator library file contains the lines `import 'orbital_elements.dart';` and `import 'state_vector.dart';`.
- The Kepler library file contains the lines `import 'earth_fixed.dart';`, `import 'gmst.dart';`, `import 'julian_date.dart';`, `import 'kepler.dart';`, `import 'orbital_elements.dart';`, `import 'perifocal.dart';` and `import 'propagator.dart';`.
- **No outside code.** No line of either new library file, with leading spaces removed, starts with `import 'package:`, `import "package:`, `import 'dart:math'`, `import "dart:math"` or `export`. So no third-party package, such as an SGP4 library, enters the seam (ADR-0001), and no trigonometry is available to the Kepler library file.
- **Composition only.** Every one of the substrings `meanAnomalyAtRad(`, `eccentricAnomalyRad(`, `semiMajorAxisKmFromMeanMotion(`, `inertialStateVector(`, `JulianDate.fromUtc(`, `gmstRad(` and `ecefPositionKm(` appears on at least one code line of the Kepler library file. No code line of the Kepler library file contains any of the substrings `sin(`, `cos(`, `sqrt(`, `pow(`, `atan2(` or `% `. The guard cannot prove that the calls are wired correctly; REQ-ORB-009.1 proves the values.
- **No copied constants.** No code line of either new library file contains the substring `398600`, `6378` or `86400`. The gravitational parameter, the Earth radius and the length of a day are read through the functions that own them (ADR-0003, Amendments 1 and 2).

### REQ-ORB-009.6 — Public names and documented contract

The documentation states the seam, the state, the failure and the model, so a reader of the package learns them without opening this spec, and the public names are fixed for req-orb-010, req-sta-001 and req-mth-001.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- **Doc blocks.** The doc block of a declaration is the run of consecutive lines directly before its declaration line whose text, with leading and trailing spaces removed, starts with `///`. It contains each of the lines listed for it below, in any order.
  - In the propagator library file, before the line `abstract interface class Propagator {`:
    - `/// Seam: every propagator is bound to one element set and returns its state at a UTC instant.`
    - `/// Implementations: KeplerPropagator (two-body, in this package) and the SGP4 adapter (req-orb-010).`
    - `/// Errors: ArgumentError for an instant that is not UTC or outside the range of JulianDate.fromUtc; PropagationException when the model cannot propagate the element set to the instant.`
    - `/// Results: every number of a returned state is finite; a propagator throws instead of returning NaN or infinity.`
  - In the propagator library file, before the line `base class PropagatedState {`:
    - `/// Instant: the UTC instant passed to stateAt.`
    - `/// Inertial state: position in km and velocity in km/s, in the inertial frame of the elements; TEME for elements read from a TLE.`
    - `/// GMST: gmstRad of the Julian date of the instant (IAU-82), from 0 inclusive to 2 pi exclusive, in radians.`
    - `/// ECEF: ecefPositionKm of the inertial position at that GMST, in km; Earth-fixed axes without polar motion (PEF).`
    - `/// Not carried: geodetic coordinates, derived values and any Earth-relative velocity.`
  - In the propagator library file, before the line `final class PropagationException implements Exception {`:
    - `/// Thrown by a propagator when its model cannot propagate the element set to the instant, such as a decayed object.`
    - `/// Not thrown for an invalid instant, which is an ArgumentError, and never thrown by KeplerPropagator.`
  - In the Kepler library file, before the line `final class KeplerPropagatedState extends PropagatedState {`:
    - `/// Mean anomaly: meanAnomalyAtRad of the elements at the instant, from 0 inclusive to 2 pi exclusive, in radians.`
    - `/// Eccentric anomaly: eccentricAnomalyRad of that mean anomaly and the eccentricity, from 0 inclusive to 2 pi exclusive, in radians.`
  - In the Kepler library file, before the line `final class KeplerPropagator implements Propagator {`:
    - `/// Model: two-body Kepler propagation, composed from the functions of req-orb-002 and req-orb-004 to req-orb-006, with no formula of its own.`
    - `/// Mean anomaly: linear, M = M0 + n (t - t0); ndot / 2, nddot / 6 and B* are ignored, so there is no drag and no J2.`
    - `/// Semi-major axis: semiMajorAxisKmFromMeanMotion of the Kozai mean motion, with mu = wgs84MuKm3S2.`
    - `/// Errors: only the ArgumentError of JulianDate.fromUtc for an invalid instant; never PropagationException.`
    - `/// Reference: none of its own; each composed function is validated against published values in its own spec.`
- **Exact members.** The members of a class are the lines after its declaration line up to, and not including, the first line equal to `}` compared with no spaces removed, leaving out empty lines and lines whose text, with leading spaces removed, starts with `///`. After trimming, they are exactly the lines below, in this order.
  - `abstract interface class Propagator {`: `OrbitalElements get elements;`, `PropagatedState stateAt(DateTime utc);`.
  - `base class PropagatedState {`: `const PropagatedState({`, `required this.utc,`, `required this.inertialState,`, `required this.gmstRad,`, `required this.ecefPositionKm,`, `});`, `final DateTime utc;`, `final StateVector inertialState;`, `final double gmstRad;`, `final CartesianVector ecefPositionKm;`.
  - `final class PropagationException implements Exception {`: `const PropagationException(this.message);`, `final String message;`, `@override`, `String toString() => 'PropagationException: $message';`.
  - `final class KeplerPropagatedState extends PropagatedState {`: `const KeplerPropagatedState({`, `required super.utc,`, `required super.inertialState,`, `required super.gmstRad,`, `required super.ecefPositionKm,`, `required this.meanAnomalyRad,`, `required this.eccentricAnomalyRad,`, `});`, `final double meanAnomalyRad;`, `final double eccentricAnomalyRad;`.
- **Kepler propagator.** The Kepler library file contains the lines `KeplerPropagator(this.elements);`, `final OrbitalElements elements;` and `KeplerPropagatedState stateAt(DateTime utc) {`. The line directly before each of the last two, after trimming, is `@override`. The return type of `stateAt` is the Kepler state, so math mode needs no cast (Context). Its body is not fixed line by line; REQ-ORB-009.5 limits what it may contain.
- **Top-level declarations.** Every line of a new library file that has a character other than a space at its first column, compared with no spaces removed, starts with `//`, starts with `import '`, or is equal to `}` or to one of the declaration lines of that file: `abstract interface class Propagator {`, `base class PropagatedState {` and `final class PropagationException implements Exception {` in the propagator library file, and `final class KeplerPropagatedState extends PropagatedState {` and `final class KeplerPropagator implements Propagator {` in the Kepler library file. Empty lines are allowed. `dart format` writes every top-level declaration at the first column and every line inside one indented, so neither file declares another top-level name, public or private, and in particular no constant and no function.

**Acceptance (verified by command V11).** Compared with `main`, this pull request adds or changes exactly five files and no other: the public library file, the two new library files, the math test file and the guard test file. This enforces the file list of Out of Scope by machine.

### REQ-ORB-009.7 — Purity, citations and test hygiene

The new code adds no dependency, every element set is cited in the math test file, and the new files follow the hygiene rules of req-orb-006 to req-orb-008.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file does not contain the substring `wgs84`, compared case-sensitively, so that its expected values come from the public functions and not from a constant read beside them.
- The math test file contains each of these three citation lines, compared after trimming:
  - `// CelesTrak, NORAD Two-Line Element Set Format, https://celestrak.org/NORAD/documentation/tle-fmt.php: NOAA 14 (23455) example.`
  - `// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005, 23599 and 28129.`
  - `// Synthetic GEO element set 99999, built for specs/req-orb-009.md with valid checksums; not a published object.`
- The math test file contains, for each N from 1 to 4, a line equal to `// REQ-ORB-009.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
- The guard test file contains, for each N in {5, 6, 7}, a line equal to `// REQ-ORB-009.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
- The guard test file builds the tag strings of the math test file (`// REQ-ORB-009.1` to `.4`) by interpolation, never as literals, so that V10 prints only its own tags.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the guard test file, the core library files and the spec file.
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser. `dart:io` never appears in `packages/orbital_core`, which the two regular expressions above enforce.
- Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, each new library file, the public library file, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-009.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-009.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

This spec adds no formula (ADR line of the header). The math test file proves that the Kepler state is the exact composition of functions already validated against published values (REQ-ORB-009.1), and the invariants of REQ-ORB-009.2 catch a composition that is wired wrongly. The inputs are cited in the math test file by the citation lines of REQ-ORB-009.7, which the guard test file checks:

- **Published element sets:** NOAA 14 from CelesTrak, and sets 00005, 23599 and 28129 of Vallado's SGP4 verification file. They cover a near-circular LEO, an eccentricity of 0.19, an eccentricity of 0.58 and a semi-synchronous orbit.
- **Synthetic GEO set:** a constructed input, not a reference value. It is used only for the invariant of REQ-ORB-009.2, whose bound comes from geometry and not from a source.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `wc` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/propagator_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-009.1 – .4 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-008 still pass |
| V4 | `flutter test test/orbital_core_propagator_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-009.5 – .7 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-009.7 |
| V6 | `flutter test` | exit 0 | REQ-ORB-009.5 – .7; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-009\.[0-9]+" packages/orbital_core/test/propagator_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-009.1,// REQ-ORB-009.2,// REQ-ORB-009.3,// REQ-ORB-009.4` | REQ-ORB-009.7 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-009\.[0-9]+" test/orbital_core_propagator_guard_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-009.5,// REQ-ORB-009.6,// REQ-ORB-009.7` | REQ-ORB-009.7 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --name-only origin/main...HEAD \| sort \| paste -sd, -` | standard output `packages/orbital_core/lib/orbital_core.dart,packages/orbital_core/lib/src/kepler_propagator.dart,packages/orbital_core/lib/src/propagator.dart,packages/orbital_core/test/propagator_test.dart,test/orbital_core_propagator_guard_test.dart` | REQ-ORB-009.6 (only the five files of this spec change) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after every file of this pull request is committed on the feature branch, so that the revert below restores each of them. Before G0, `git status --porcelain` must print nothing; otherwise stop, because the deletions and the revert would destroy uncommitted work.

The command is:

    flutter test test/orbital_core_propagator_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-009.md"

**Control run (G0).** With no edit applied, run the command once with `<tag>` replaced by each of `[REQ-ORB-009.5]`, `[REQ-ORB-009.6]` and `[REQ-ORB-009.7]`, and confirm that each prints nothing. A line printed here means that the output of a passing run, such as a test name, already carries a tag and the spec path, so the rows below would prove nothing; fix the guard test file before continuing.

Then, for each row of the table:

1. Apply the edit.
2. Run the command and confirm that it prints at least one line. That line carries both the expected tag and the spec path.
3. Revert with `git checkout -- packages/orbital_core test specs` before the next row.

"Delete the line X" and "Replace the line X" act on every line that equals X after trimming, keeping the indentation of a replaced line. "Replace every occurrence" acts on every occurrence of the substring. "Append" adds a line at the end of the file. Inside the table, `\|` is a single pipe. "The propagator file", "the Kepler file", "the math test file" and "the guard test file" are the propagator library file, the Kepler library file, the math test file and the guard test file of Definitions.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the propagator file | `[REQ-ORB-009.7]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the Kepler file | `[REQ-ORB-009.7]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the propagator file | `[REQ-ORB-009.7]` |
| G4 | Add `import 'dart:ffi';` as the first line of the Kepler file | `[REQ-ORB-009.7]` |
| G5 | Add `import 'dart:math';` as the first line of the Kepler file | `[REQ-ORB-009.5]` |
| G6 | Add `import 'package:sgp4/sgp4.dart';` as the first line of the propagator file | `[REQ-ORB-009.5]` |
| G7 | Delete the line `export 'src/propagator.dart';` from the public library file | `[REQ-ORB-009.5]` |
| G8 | Delete the line `export 'src/kepler_propagator.dart';` from the public library file | `[REQ-ORB-009.5]` |
| G9 | Delete the file `packages/orbital_core/lib/src/propagator.dart` | `[REQ-ORB-009.5]` |
| G10 | Delete the file `packages/orbital_core/lib/src/kepler_propagator.dart` | `[REQ-ORB-009.5]` |
| G11 | Delete the line `import 'state_vector.dart';` from the propagator file | `[REQ-ORB-009.5]` |
| G12 | Delete the line `import 'perifocal.dart';` from the Kepler file | `[REQ-ORB-009.5]` |
| G13 | Replace every occurrence of `gmstRad(` with `gmstRadOf(` on the code lines of the Kepler file | `[REQ-ORB-009.5]` |
| G14 | Replace every occurrence of `ecefPositionKm(` with `earthFixed(` on the code lines of the Kepler file | `[REQ-ORB-009.5]` |
| G15 | Append the line `  final double _s = sin(1.0);` (indented by two spaces) to the Kepler file | `[REQ-ORB-009.5]` |
| G16 | Append the line `  final double _m = 398600.4418;` (indented by two spaces) to the Kepler file | `[REQ-ORB-009.5]` |
| G17 | Append the line `  final double _r = 6378.137;` (indented by two spaces) to the propagator file | `[REQ-ORB-009.5]` |
| G18 | Append the line `  final double _d = 86400.0;` (indented by two spaces) to the Kepler file | `[REQ-ORB-009.5]` |
| G19 | Delete the line `/// Seam: every propagator is bound to one element set and returns its state at a UTC instant.` from the propagator file | `[REQ-ORB-009.6]` |
| G20 | Delete the line `/// Implementations: KeplerPropagator (two-body, in this package) and the SGP4 adapter (req-orb-010).` from the propagator file | `[REQ-ORB-009.6]` |
| G21 | Delete the line `/// Errors: ArgumentError for an instant that is not UTC or outside the range of JulianDate.fromUtc; PropagationException when the model cannot propagate the element set to the instant.` from the propagator file | `[REQ-ORB-009.6]` |
| G22 | Delete the line `/// Results: every number of a returned state is finite; a propagator throws instead of returning NaN or infinity.` from the propagator file | `[REQ-ORB-009.6]` |
| G23 | Delete the line `/// Instant: the UTC instant passed to stateAt.` from the propagator file | `[REQ-ORB-009.6]` |
| G24 | Delete the line `/// Inertial state: position in km and velocity in km/s, in the inertial frame of the elements; TEME for elements read from a TLE.` from the propagator file | `[REQ-ORB-009.6]` |
| G25 | Delete the line `/// GMST: gmstRad of the Julian date of the instant (IAU-82), from 0 inclusive to 2 pi exclusive, in radians.` from the propagator file | `[REQ-ORB-009.6]` |
| G26 | Delete the line `/// ECEF: ecefPositionKm of the inertial position at that GMST, in km; Earth-fixed axes without polar motion (PEF).` from the propagator file | `[REQ-ORB-009.6]` |
| G27 | Delete the line `/// Not carried: geodetic coordinates, derived values and any Earth-relative velocity.` from the propagator file | `[REQ-ORB-009.6]` |
| G28 | Delete the line `/// Thrown by a propagator when its model cannot propagate the element set to the instant, such as a decayed object.` from the propagator file | `[REQ-ORB-009.6]` |
| G29 | Delete the line `/// Not thrown for an invalid instant, which is an ArgumentError, and never thrown by KeplerPropagator.` from the propagator file | `[REQ-ORB-009.6]` |
| G30 | Delete the line `/// Mean anomaly: meanAnomalyAtRad of the elements at the instant, from 0 inclusive to 2 pi exclusive, in radians.` from the Kepler file | `[REQ-ORB-009.6]` |
| G31 | Delete the line `/// Eccentric anomaly: eccentricAnomalyRad of that mean anomaly and the eccentricity, from 0 inclusive to 2 pi exclusive, in radians.` from the Kepler file | `[REQ-ORB-009.6]` |
| G32 | Delete the line `/// Model: two-body Kepler propagation, composed from the functions of req-orb-002 and req-orb-004 to req-orb-006, with no formula of its own.` from the Kepler file | `[REQ-ORB-009.6]` |
| G33 | Delete the line `/// Mean anomaly: linear, M = M0 + n (t - t0); ndot / 2, nddot / 6 and B* are ignored, so there is no drag and no J2.` from the Kepler file | `[REQ-ORB-009.6]` |
| G34 | Delete the line `/// Semi-major axis: semiMajorAxisKmFromMeanMotion of the Kozai mean motion, with mu = wgs84MuKm3S2.` from the Kepler file | `[REQ-ORB-009.6]` |
| G35 | Delete the line `/// Errors: only the ArgumentError of JulianDate.fromUtc for an invalid instant; never PropagationException.` from the Kepler file | `[REQ-ORB-009.6]` |
| G36 | Delete the line `/// Reference: none of its own; each composed function is validated against published values in its own spec.` from the Kepler file | `[REQ-ORB-009.6]` |
| G37 | Replace the line `abstract interface class Propagator {` with `abstract class Propagator {` in the propagator file | `[REQ-ORB-009.6]` |
| G38 | Replace the line `PropagatedState stateAt(DateTime utc);` with `PropagatedState stateAt(DateTime instant);` in the propagator file | `[REQ-ORB-009.6]` |
| G39 | Replace the line `OrbitalElements get elements;` with `OrbitalElements get elementSet;` in the propagator file | `[REQ-ORB-009.6]` |
| G40 | Replace the line `base class PropagatedState {` with `class PropagatedState {` in the propagator file | `[REQ-ORB-009.6]` |
| G41 | Insert the line `final double altitudeKm;` directly after the line `final CartesianVector ecefPositionKm;` in the propagator file | `[REQ-ORB-009.6]` |
| G42 | Replace the line `final class PropagationException implements Exception {` with `final class PropagationException extends Error {` in the propagator file | `[REQ-ORB-009.6]` |
| G43 | Replace the line `final double meanAnomalyRad;` with `final double meanAnomaly;` in the Kepler file | `[REQ-ORB-009.6]` |
| G44 | Replace the line `KeplerPropagatedState stateAt(DateTime utc) {` with `PropagatedState stateAt(DateTime utc) {` in the Kepler file | `[REQ-ORB-009.6]` |
| G45 | Replace the line `KeplerPropagator(this.elements);` with `const KeplerPropagator(this.elements);` in the Kepler file | `[REQ-ORB-009.6]` |
| G46 | Delete the line `@override` from the Kepler file | `[REQ-ORB-009.6]` |
| G47 | Append the line `double _extra() => 1.0;` to the Kepler file | `[REQ-ORB-009.6]` |
| G48 | Append the line `const double _mu = 1.0;` to the propagator file | `[REQ-ORB-009.6]` |
| G49 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-009.7]` |
| G50 | Add `import 'package:orbital_core/src/propagator.dart';` to the math test file | `[REQ-ORB-009.7]` |
| G51 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-009.7]` |
| G52 | Replace the line `// REQ-ORB-009.2` with `// REQ-ORB-009.x`, keeping its indentation, in the math test file | `[REQ-ORB-009.7]` |
| G53 | Insert the line `// note` directly after the line `// REQ-ORB-009.1` in the math test file | `[REQ-ORB-009.7]` |
| G54 | Delete the citation line that starts with `// CelesTrak, NORAD Two-Line Element Set Format` from the math test file | `[REQ-ORB-009.7]` |
| G55 | Delete the citation line that starts with `// Vallado et al., Revisiting Spacetrack Report #3` from the math test file | `[REQ-ORB-009.7]` |
| G56 | Delete the citation line that starts with `// Synthetic GEO element set 99999` from the math test file | `[REQ-ORB-009.7]` |
| G57 | Append the line `// skip: true` to the math test file | `[REQ-ORB-009.7]` |
| G58 | Append the line `// wgs84MuKm3S2` to the math test file | `[REQ-ORB-009.7]` |
| G59 | Run `sed -i 's/$/\r/' packages/orbital_core/test/propagator_test.dart` (CRLF) | `[REQ-ORB-009.7]` |
| G60 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/propagator_test.dart > /tmp/g60 && mv /tmp/g60 packages/orbital_core/test/propagator_test.dart` (BOM) | `[REQ-ORB-009.7]` |
| G61 | Run `sed -i 's/$/\r/' specs/req-orb-009.md` (CRLF in the spec file) | `[REQ-ORB-009.7]` |
| G62 | Run `printf '\xEF\xBB\xBF' \| cat - specs/req-orb-009.md > /tmp/g62 && mv /tmp/g62 specs/req-orb-009.md` (BOM in the spec file) | `[REQ-ORB-009.7]` |
| G63 | Run `sed -i 's/$/\r/' packages/orbital_core/lib/src/propagator.dart` (CRLF in a core library file) | `[REQ-ORB-009.7]` |
| G64 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-009.7]` |
| G65 | Replace the line `// REQ-ORB-009.5` with `// REQ-ORB-009.x`, keeping its indentation, in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-ORB-009.7]` |
| G66 | Delete the file `packages/orbital_core/test/propagator_test.dart` | `[REQ-ORB-009.7]` |
| G67 | Delete the file `packages/orbital_core/lib/orbital_core.dart` | `[REQ-ORB-009.5]` |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V11 and G0–G67, each with its observed result. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **Invalid instant.** A `DateTime` not flagged as UTC, or outside 1900-03-01T00:00:00.000000Z to 2100-02-28T23:59:59.999999Z, throws the `ArgumentError` of `JulianDate.fromUtc` with its message unchanged (REQ-ORB-009.4). The epoch of a TLE always lies in 1957 to 2056 (req-orb-003), inside that range, so building a propagator never fails for a parsed element set.
- **Far from the epoch.** The Kepler propagator accepts any valid instant, even decades from the epoch: M grows linearly and is normalized (req-orb-004). The grid of REQ-ORB-009.1 includes the first and last valid instants, about 100 years from the published epochs, and all 40 states measured finite. The physical meaning of such a state is nil, because two-body propagation ignores drag and J2 (Kepler propagator documentation); the age warning of req-ui-004 is the guard against reading it as current, not this spec.
- **Kepler versus SGP4.** The Kepler state of the same element set at the same instant differs from the SGP4 state, by kilometres within hours for a LEO object. That difference is the phase 2 comparison (Project Brief) and is not measured here. The Kepler propagator feeds math mode; the globe of the MVP renders SGP4 (roadmap row 12).
- **Mean elements.** The Kepler propagator reads the TLE mean elements as if they were osculating two-body elements, and uses the Kozai mean motion as is (req-orb-005, ADR-0005). This is the documented model, not an error.
- **Solver failure.** `eccentricAnomalyRad` throws a `StateError` if Newton-Raphson does not converge, which req-orb-004 defines as a defect of the solver and never observed for an eccentricity below 1. The Kepler propagator lets it pass; it is not mapped to the failure type, which reports a condition of the data, not a defect.
- **Failure type before req-orb-010.** No code of this spec throws the failure type. REQ-ORB-009.3 tests it directly, so that it is not dead code without a test, and req-orb-010 is the first to throw it.
- **No state between calls.** Asking for instants in any order, backwards included, gives the same states (REQ-ORB-009.3). A future propagator that caches internally must keep this property; req-orb-010 inherits it from the interface documentation.
- **Signed zeros.** The state may carry −0.0 in a component where the composed functions return it. REQ-ORB-009.1 compares with `==`, which treats −0.0 and 0.0 as equal.
- **Microsecond rounding.** `DateTime` holds microseconds, so "k periods after the epoch" is rounded to the nearest microsecond. At 8 km/s that moves the position by at most 4·10⁻⁶ km, which is the size of the largest distance measured in REQ-ORB-009.2 and inside its tolerance.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-009.7). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Declarations moved by the formatter.** The exact-member and top-level rules of REQ-ORB-009.6 rely on `dart format`, which writes every top-level declaration at the first column, every member indented, and each member line listed there on one line within 80 columns. If a future formatter changes that layout, the guard reports `[REQ-ORB-009.6]`. The fix is a spec change, never a relaxed guard.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access at run time. V11 needs `git fetch` and is a local check; if the fetch fails, V11 counts as not run, never as a pass. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass. When the G edits are scripted in Git Bash on Windows, an argument that starts with `/`, such as a `///` or `//` line, is rewritten as a path before the program receives it, so the edit silently does nothing and the row reports a false failure. Disable that conversion (for example with `MSYS_NO_PATHCONV=1`) and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in this pull request:

- SGP4 in any form: the library, its adapter, its gravity constants, its test vectors and the mapping of its failures to the failure type (req-orb-010, ADR-0002).
- Geodetic coordinates, the derived values of req-orb-008 and any Earth-relative velocity inside the state or computed by a propagator (Context).
- Any formula, constant or use of `dart:math` in the two new library files; a change of any formula of req-orb-001 to req-orb-008.
- Drag, J2, the terms ndot / 2 and nddot / 6, B*, and the conversion of the Kozai mean motion to the Brouwer one in the Kepler propagator.
- A propagator that takes plain elements, OMM or any input other than `OrbitalElements`; a public way to build an element set from plain values (req-orb-003, Out of Scope, remains in force).
- Caching of states, sampling of an orbit path (req-viz-006), the simulation clock (req-tim-001) and any provider (req-sta-001).
- Any change to `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart`, `kepler.dart`, `perifocal.dart`, `state_vector.dart`, `earth_fixed.dart`, `geodetic.dart` or `derived_values.dart`, or to their tests and guards.
- Any code in the application `lib/`, any provider or widget.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
