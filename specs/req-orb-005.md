# req-orb-005 — Perifocal to inertial state vector

- **Status:** Ready for implementation (revision 2, after the first QA audit). ADR-0005 and Amendment 1 of ADR-0003 were accepted by the developer on 2026-11-01. Every published value was checked against a freely available primary source while drafting (see Definitions).
- **Roadmap row:** 7 of 33 (MVP)
- **Blocks:** req-orb-006 (inertial to ECEF rotates the vectors defined here), req-orb-008 (derived values need the semi-major axis and μ), req-orb-009 (the Kepler implementation composes req-orb-004 and this spec; it also decides whether the propagator interface, and with it req-orb-010, reuses the state vector type defined here)
- **Depends on:** req-orb-003 (element set and its Kozai mean motion), req-orb-004 (eccentric anomaly; roadmap order), req-inf-002 (CI quality gates), ADR-0001 (baseline packages), ADR-0003 (TLE element sets and their units, with its Amendment 1 on the gravitational parameter of the Kepler propagator), ADR-0005 (derived reference values for the semi-major axis from mean motion)
- **ADR:** ADR-0005 (accepted) makes a bounded exception to Constitution principle 6 for the semi-major axis from mean motion of REQ-ORB-005.1, which has no free published numeric example. Amendment 1 of ADR-0003 (accepted; first QA audit, finding 2.1) places the gravitational parameter of the Kepler propagator in this spec, under a name that states its model. The work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`, so ADR-0001 is unchanged. The reference values come from a repository licensed under AGPL-3.0; this spec and its tests cite published numbers only, and copy no code from it.

## Context & Objective

req-orb-004 delivers the eccentric anomaly E at an instant. The in-house Kepler propagator still cannot place the object in space: it needs the size of the orbit, the position and velocity within the orbital plane, and the rotation from that plane to the inertial axes of the element set. This spec delivers what roadmap row 7 names, as steps 4 and 5 of the Project Brief's pipeline fix them:

- derive the semi-major axis a from the mean motion n;
- place the object in its orbital (perifocal) plane from a, the eccentricity e and E;
- rotate position and velocity by R₃(−Ω) · R₁(−i) · R₃(−ω) to obtain an inertial state vector.

The decisions below are fixed so later specs inherit them. The developer approved each one before drafting or during the first QA audit.

- **Semi-major axis.** a = (μ / n²)^(1/3) with μ = 398600.4418 km³/s², exactly as step 4 of the Project Brief. This is the gravitational parameter of WGS-84. It is a public constant of the package, named after its model, because req-orb-008 needs the same value for vis-viva (ADR-0003, Amendment 1). The WGS-72 constants of SGP4 stay with req-orb-010.
- **Kozai mean motion, used as is.** n is the Kozai mean motion that the element set stores (req-orb-003). It is not converted to the Brouwer mean motion: that conversion needs the WGS-72 gravity constants (J2 and the Earth radius) that ADR-0003 assigns to the SGP4 adapter (req-orb-010). The cost is a semi-major axis a few kilometres off for low orbits, which the phase-2 comparison of Kepler and SGP4 will show.
- **Position and velocity from E.** The perifocal position follows step 4 of the Project Brief. The perifocal velocity is its time derivative, written with E so that no true anomaly is needed. Both are checked against the published state vector of Vallado's Example 2-6.
- **Plain inputs.** The functions take plain numbers, so that published values are tested directly, as the solver of req-orb-004 does. Composing an element set and an instant into a state vector is req-orb-009's job. No public way to build an element set from plain values is added (req-orb-003, Out of Scope, remains in force).
- **Named parameters.** The state vector function takes its six inputs as required named parameters, because six positional numbers of the same type are easy to swap (for example Ω and ω) without any error.
- **New value types.** An immutable Cartesian vector and an immutable state vector carry the result. req-orb-006 and req-orb-009 are expected to reuse them; whether req-orb-010 does is decided by req-orb-009. The vector carries no unit of its own; the state vector names the units of its two members. The vector is not called `Vector3`, so that it cannot clash with the type of that name in `vector_math`, which Flutter uses.
- **Frame.** The output is expressed in the inertial frame of the elements. For elements read from a TLE this is TEME, the frame of SGP4 (AIAA 2006-6753), which req-orb-006 rotates to ECEF with GMST.
- **Input validation.** Non-finite inputs, a semi-major axis or mean motion that is not positive and an eccentricity outside the elliptical range are rejected, each with an exact message. The roadmap row does not name this. It is kept for the same reason as in req-orb-004: the functions run on the frame path, and an unchecked NaN would flow silently into the globe.
- **Free sources only.** Every published reference value comes from the test suite that CelesTrak publishes with the code of Vallado's textbook, pinned to a commit (Definitions). Values from printed books that a reviewer cannot check free of charge are not used.

## Definitions used by every requirement

These definitions are normative.

- **Vallado repository:** CelesTrak, "fundamentals-of-astrodynamics", at `https://github.com/CelesTrak/fundamentals-of-astrodynamics`, licensed under AGPL-3.0, as described in `specs/req-orb-004.md`. Three of its files are cited, all at commit `49df0479c950917c0a2c5ac31f2db6477bba57f6`:
  - `software/python/tests/astro/twobody/test_frame_conversions.py`:
    - its fixture `coe` of class `TestClassical` (line 94, labelled "Vallado, 2022, Ex. 2-6") publishes the inputs p = 11067.790 km, e = 0.83285, i = 87.87°, Ω = 227.89°, ω = 53.38° and ν = 92.335°;
    - its test `test_coe2rv` (line 111) publishes the resulting position (6525.368120986091, 6861.531834896055, 6449.118614160162) km and velocity (4.902278644574153, 5.533139566279278, −1.9757100987916154) km/s;
    - its test `test_perifocal_transform` (line 645, labelled "From Vallado Example 2-6, 2022") publishes, for the same i, Ω and ω, the unit vectors P = (−0.37786007180211706, −0.46252560096516104, 0.8020547578498088), Q = (0.5546417852962037, 0.580556376955298, 0.596092931664164) and W = (−0.7413462457860962, 0.6700928007584878, 0.03716695078301055);
  - `software/python/src/valladopy/astro/twobody/frame_conversions.py`, function `coe2rv` (line 139), which produced the published state vector;
  - `software/python/src/valladopy/constants.py`, line 61, `MU = 398600.4415`, the μ that produced the published state vector.
- **Element set**, **Vallado SGP4**, and the published sets **00005** and **28129**: as defined in `specs/req-orb-003.md`, including their converted values (REQ-ORB-003.1).
- **μ:** 398600.4418 km³/s², the gravitational parameter of WGS-84, as fixed by step 4 of the Project Brief. It differs from the μ of the Vallado repository by 3·10⁻⁴ km³/s². For the published state vector this changes the velocity by a factor of about 1 + 3.8·10⁻¹⁰, at most 2.1·10⁻⁹ km/s per component, and leaves the position unchanged.
- **2π (as a double):** `2 * pi` with `pi` from `dart:math`, as in `specs/req-orb-004.md`.
- **Semi-major axis from mean motion:** for a mean motion n in radians per second, a = (μ / n²)^(1/3), in kilometres.
- **Perifocal axes:** the axes of the orbital plane, with the first axis towards perigee, the second axis 90° ahead in the direction of motion, and the third axis along the orbit normal.
- **Orbit radius:** r = a · (1 − e · cos E).
- **Perifocal position:** (a · (cos E − e), a · √(1 − e²) · sin E, 0), in kilometres.
- **Perifocal velocity:** (√(μ · a) / r) · (−sin E, √(1 − e²) · cos E, 0), in kilometres per second.
- **Rotation to inertial axes:** the product R₃(−Ω) · R₁(−i) · R₃(−ω) applied to a perifocal vector (x, y, 0). Its result is x · P + y · Q, where:
  - P = (cos Ω · cos ω − sin Ω · sin ω · cos i, sin Ω · cos ω + cos Ω · sin ω · cos i, sin ω · sin i);
  - Q = (−cos Ω · sin ω − sin Ω · cos ω · cos i, −sin Ω · sin ω + cos Ω · cos ω · cos i, cos ω · sin i);
  - W = (sin Ω · sin i, −cos Ω · sin i, cos i), the orbit normal, which multiplies the zero third component.
- **Inertial state vector:** the rotation to inertial axes of the perifocal position (the position) and of the perifocal velocity (the velocity), for the inputs a, e, i, Ω, ω and E.
- **Derived inputs of Example 2-6:** the semi-major axis a = p / (1 − e²) and the eccentric anomaly E = 2 · atan(√((1 − e) / (1 + e)) · tan(ν / 2)), computed in the math test file from the published p, e and ν with `dart:math`, after converting ν from degrees to radians by multiplying by π / 180. They evaluate to 36126.64283480516 km and 0.6095079699392009 rad. They only translate the published inputs to the inputs of this spec; the expected outputs stay the published ones.
- **Close to within x:** the absolute difference from the expected value is at most x. For a vector, each of its three components is close to within x of the matching expected component.
- **Relatively close to within x:** the absolute difference from the expected value is at most x times the absolute value of the expected value.
- **Exact:** compared with `==` on doubles, with no tolerance.
- **Perifocal library file:** `packages/orbital_core/lib/src/perifocal.dart`.
- **State-vector library file:** `packages/orbital_core/lib/src/state_vector.dart`.
- **New library files:** the perifocal library file and the state-vector library file.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/perifocal_test.dart`. It covers REQ-ORB-005.1 to .5.
- **Guard test file:** `test/orbital_core_perifocal_guard_test.dart`, in the application suite.
- **Spec file:** `specs/req-orb-005.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-005.1 — Semi-major axis from mean motion

A mean motion in radians per second yields the semi-major axis in kilometres.

**Acceptance (verified by the math test file).**

- Each element set is parsed from its two published lines in REQ-ORB-003.1, written as string literals in the math test file. Its mean motion in radians per second is passed to the function as a plain number.
- Under ADR-0005, every row is marked "Derived". Its expected value was derived from the published mean motion in revolutions per day, through the period, as written out in the Source column. The implementation takes radians per second, so the derivation does not follow its path.
- The math test file compares each result with the expected value of its row, written as a literal number. It does not repeat the derivation, and it never uses the constant of the package to compute an expected value.
- Every row passes within 1·10⁻⁸ km.

| Set | Published mean motion | Expected semi-major axis | Source |
| --- | --- | --- | --- |
| 00005 | 10.82419157 rev/day | 8632.531955915649 km | Derived: T = 86400 / 10.82419157 = 7982.120368181917 s; a = (398600.4418 · T² / (4π²))^(1/3) |
| 28129 | 2.00562768 rev/day | 26560.421624650135 km | Derived: T = 86400 / 2.00562768 = 43078.78319668983 s; a = (398600.4418 · T² / (4π²))^(1/3) |

The two paths agreed within 4·10⁻¹² km when this spec was drafted.

- **Largest reachable axis.** For a mean motion of 1·10⁻⁸ rev/day times 2π / 86400, the smallest positive value the TLE mean motion field can carry (req-orb-003, field table), the result is finite and greater than 0. It was about 9.1·10⁹ km when this spec was drafted.
- **Constant.** The public constant μ of the perifocal library file equals 398600.4418 exactly. This is the only assertion of the math test file that reads the constant.

### REQ-ORB-005.2 — Inertial state vector from published values

Six orbital values, given as plain numbers, yield the inertial position in kilometres and the inertial velocity in kilometres per second.

**Acceptance (verified by the math test file).**

- The inputs are the derived inputs of Example 2-6 (Definitions), with i, Ω and ω converted from degrees to radians by multiplying by π / 180.
- The position is close to within 1·10⁻⁶ km of the published position of `test_coe2rv`. The error measured while drafting was 4·10⁻¹² km.
- The velocity is close to within 1·10⁻⁸ km/s of the published velocity of `test_coe2rv`. The tolerance covers the difference of μ (Definitions), at most 2.1·10⁻⁹ km/s.

### REQ-ORB-005.3 — Rotation axes from published values

The rotation to inertial axes maps the perifocal axes onto the published P, Q and W.

**Acceptance (verified by the math test file).** The inputs are a = 1.0 km, e = 0.0, and the i, Ω and ω of Example 2-6 in radians.

- With E = 0.0, the position is close to within 1·10⁻¹² km of P.
- With E = π / 2 (`pi / 2` as a double), the position is close to within 1·10⁻¹² km of Q.
- With E = 0.0, the cross product of position and velocity, divided by its own length, is close to within 1·10⁻¹² of W.

### REQ-ORB-005.4 — Two-body identities over a grid

Every state vector satisfies the radius, energy and angular momentum of its orbit, and its angular momentum points along the orbit normal.

**Acceptance (verified by the math test file).**

- **Grid.** Every combination of:
  - a in {6778.0, 26560.0, 42164.0} km;
  - e in {0.0, 1·10⁻⁷, 0.1, 0.5, 0.9, 0.9999999};
  - (i, Ω, ω) in {(the angles of Example 2-6), (0.0, 0.0, 0.0), (π, 1.0, 2.0), (π / 2, 3.0, 5.0)}, in radians;
  - E = k · 2π / 36, for k from 0 to 35.
- For each combination, with |v| the Euclidean length of a vector v, μ the literal 398600.4418 and W as in Definitions:
  - **radius:** |position| is relatively close to within 1·10⁻¹³ of a · (1 − e · cos E);
  - **vis-viva:** |velocity|² is relatively close to within 1·10⁻⁷ of μ · (2 / |position| − 1 / a);
  - **angular momentum:** |position × velocity| is relatively close to within 1·10⁻¹¹ of √(μ · a · (1 − e²));
  - **normal:** (position × velocity) / |position × velocity| is close to within 1·10⁻¹¹ of W.
- **Largest reachable axis.** For the semi-major axis of the largest-reachable-axis row of REQ-ORB-005.1, e = 0.9999999, i = 1.0, Ω = 2.0, ω = 3.0 and E = 0.5, every component of position and velocity is finite.

These identities are standard two-body results (vis-viva and the specific angular momentum). They are used only as checks and add no formula to the package. The largest errors measured while drafting were 3.9·10⁻¹⁵ (radius), 5.4·10⁻⁹ (vis-viva), 3.1·10⁻¹³ (angular momentum) and 2.2·10⁻¹³ (normal). The vis-viva tolerance is the widest because 2 / |position| − 1 / a nearly cancels at apoapsis when e is close to 1.

### REQ-ORB-005.5 — Input validation with exact messages

Each function accepts only the inputs below. Any other input throws Dart's `ArgumentError` and returns no value. No message contains an apostrophe, so each can be written in the perifocal library file as a plain single-quoted string. "Finite" means neither NaN nor positive or negative infinity.

- **Semi-major axis from mean motion:** a finite mean motion strictly greater than 0. Otherwise it throws message N.
- **Inertial state vector:** checks run in this order and the first failure wins:
  1. the semi-major axis is finite and strictly greater than 0, otherwise message A;
  2. the eccentricity is from 0 inclusive to 1 exclusive, otherwise message E (NaN is outside that range);
  3. the inclination, Ω, ω and E are all finite, otherwise message G.

The messages:

- **Message N:** `Semi-major axis requires a finite mean motion greater than 0.`
- **Message A:** `State vector requires a finite semi-major axis greater than 0.`
- **Message E:** `State vector requires an eccentricity from 0 inclusive to 1 exclusive.`
- **Message G:** `State vector requires finite angles.`

**Acceptance (verified by the math test file).**

- "Throws X" means the thrown object is an `ArgumentError` whose message is equal to message X, character for character.
- "Accepted" means the function returns without throwing and every component of its result is finite.
- Unless a row says otherwise, the state vector inputs are a = 7000.0 km, e = 0.1, i = 1.0, Ω = 2.0, ω = 3.0 and E = 4.0, and the row changes only the inputs it names.

| Function | Input | Expected |
| --- | --- | --- |
| Semi-major axis | n = NaN | Throws N |
| Semi-major axis | n = positive infinity | Throws N |
| Semi-major axis | n = negative infinity | Throws N |
| Semi-major axis | n = 0.0 | Throws N |
| Semi-major axis | n = −0.0 | Throws N |
| Semi-major axis | n = −1·10⁻¹² | Throws N |
| State vector | a = NaN | Throws A |
| State vector | a = positive infinity | Throws A |
| State vector | a = 0.0 | Throws A |
| State vector | a = −1.0 | Throws A |
| State vector | a = NaN and e = 2.0 | Throws A (the semi-major axis is checked first) |
| State vector | e = NaN | Throws E |
| State vector | e = 1.0 | Throws E |
| State vector | e = 1.5 | Throws E |
| State vector | e = −1·10⁻¹² | Throws E |
| State vector | e = NaN and i = NaN | Throws E (the eccentricity is checked before the angles) |
| State vector | i = NaN | Throws G |
| State vector | Ω = positive infinity | Throws G |
| State vector | ω = negative infinity | Throws G |
| State vector | E = NaN | Throws G |
| State vector | e = −0.0 | Accepted; every component equals, exactly, the matching component for e = 0.0 |
| State vector | e = 0.9999999 | Accepted |

### REQ-ORB-005.6 — Placement, public names and documented contract

The constant μ, the semi-major axis and the state vector function live in the perifocal library file. The two value types live in the state-vector library file. All are reachable through the public library file. The documentation states the formulas, the constant, the mean motion used, the rotation, the frame, the units and the reference, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The perifocal library file and the state-vector library file exist.
- The public library file contains the lines `export 'src/perifocal.dart';` and `export 'src/state_vector.dart';`.
- The perifocal library file contains each of these eight lines:
  - `/// Semi-major axis: a = (mu / n^2)^(1/3), with mu = 398600.4418 km^3/s^2 (WGS-84).`
  - `/// Mean motion: the Kozai mean motion of the element set, used as is.`
  - `/// Perifocal position: x = a (cos E - e), y = a sqrt(1 - e^2) sin E, z = 0.`
  - `/// Perifocal velocity: sqrt(mu a) / r * (-sin E, sqrt(1 - e^2) cos E, 0), r = a (1 - e cos E).`
  - `/// Rotation: R3(-raan) R1(-i) R3(-argp), from perifocal to inertial axes.`
  - `/// Frame: the inertial frame of the elements; TEME for elements read from a TLE.`
  - `/// Units: km, km/s and radians.`
  - `/// Reference: CelesTrak fundamentals-of-astrodynamics, frame_conversions.py, coe2rv (Vallado: 2022, Ex. 2-6).`
- The state-vector library file contains each of these two lines:
  - `/// Cartesian vector: components x, y and z along the axes of one frame.`
  - `/// State vector: position in km and velocity in km/s, in the same frame.`
- The perifocal library file contains the line `const double wgs84MuKm3S2 = 398600.4418;`.
- **Public names.** Each declaration below must appear in its file on a line that, with leading and trailing spaces removed, starts with the declaration and continues with a character that is not a letter, a digit, `_` or `$` (or ends there). These names are the contract that req-orb-006, req-orb-008, req-orb-009 and req-orb-010 read. Each fits on one line within the 80 columns of `dart format`.
  - In the perifocal library file:
    - `double semiMajorAxisKmFromMeanMotion(double meanMotionRadS)`
    - `StateVector inertialStateVector({`
  - In the state-vector library file:
    - `final class CartesianVector`
    - `const CartesianVector(this.x, this.y, this.z)`
    - `final double x`
    - `final double y`
    - `final double z`
    - `final class StateVector`
    - `const StateVector({required this.positionKm, required this.velocityKmS})`
    - `final CartesianVector positionKm`
    - `final CartesianVector velocityKmS`
- **Parameters.** The six lines directly after the line that starts with `StateVector inertialStateVector({` are, in this order and each equal after trimming: `required double semiMajorAxisKm,`, `required double eccentricity,`, `required double inclinationRad,`, `required double raanRad,`, `required double argumentOfPerigeeRad,`, `required double eccentricAnomalyRad,`. `dart format` always splits this declaration one parameter per line, because it does not fit within 80 columns.
- **Immutability.** No line of the state-vector library file, with leading spaces removed, starts with `var `, `set ` or `late `.

**Acceptance (verified by command V11).** This pull request changes none of `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart` and `kepler.dart`.

**Acceptance (verified by review, item R1 of the pull request checklist).** The reviewer confirms that the new library files declare no public top-level name other than `wgs84MuKm3S2`, `semiMajorAxisKmFromMeanMotion`, `inertialStateVector`, `CartesianVector` and `StateVector`, and that the two classes declare no public member other than their fixed constructor and fields.

### REQ-ORB-005.7 — Purity, citations and test hygiene

The new code adds no dependency, every published value is cited in the math test file, and the new files follow the hygiene rules of req-orb-004.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file contains each of these four citation lines, compared after trimming:
  - `// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.`
  - `// Vallado repository, test_frame_conversions.py, test_coe2rv "Vallado, 2022, Ex. 2-6": p = 11067.790 km, e = 0.83285, i = 87.87 deg, raan = 227.89 deg, argp = 53.38 deg, nu = 92.335 deg.`
  - `// Vallado repository, test_frame_conversions.py, test_perifocal_transform "From Vallado Example 2-6, 2022": P, Q and W unit vectors.`
  - `// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005 and 28129; semi-major axes derived under ADR-0005.`
- The math test file contains, for each N from 1 to 5, a line equal to `// REQ-ORB-005.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
- The guard test file contains, for each N in {6, 7}, a line equal to `// REQ-ORB-005.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
- The guard test file builds the tag strings of the math test file (`// REQ-ORB-005.1` to `.5`) by interpolation, never as literals, so that V10 prints only its own tags.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the guard test file, the core library files and the spec file.
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser. `dart:io` never appears in `packages/orbital_core`, which the two regular expressions above enforce.
- Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, either new library file, the public library file, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-005.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-005.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-005.7, which the guard test file checks (Constitution principle 6). The sources are:

- **State vector (REQ-ORB-005.2):** the position and velocity published by the Vallado repository for Example 2-6.
- **Rotation (REQ-ORB-005.3):** the unit vectors P, Q and W published by the Vallado repository for Example 2-6.
- **Semi-major axis (REQ-ORB-005.1):** rows derived from the published mean motions of Vallado's verification element sets under the bounded exception of ADR-0005.
- **Grid (REQ-ORB-005.4):** checks two-body identities and introduces no new formula.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `wc` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/perifocal_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-005.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-004 still pass |
| V4 | `flutter test test/orbital_core_perifocal_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-005.6, .7 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-005.7 |
| V6 | `flutter test` | exit 0 | REQ-ORB-005.6, .7; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-005\.[0-9]+" packages/orbital_core/test/perifocal_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-005.1,// REQ-ORB-005.2,// REQ-ORB-005.3,// REQ-ORB-005.4,// REQ-ORB-005.5` | REQ-ORB-005.7 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-005\.[0-9]+" test/orbital_core_perifocal_guard_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-005.6,// REQ-ORB-005.7` | REQ-ORB-005.7 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --exit-code origin/main...HEAD -- packages/orbital_core/lib/src/orbital_elements.dart packages/orbital_core/lib/src/tle_parser.dart packages/orbital_core/lib/src/julian_date.dart packages/orbital_core/lib/src/gmst.dart packages/orbital_core/lib/src/elapsed_time.dart packages/orbital_core/lib/src/kepler.dart` | exit 0 | REQ-ORB-005.6 (earlier library files unchanged) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after both test files are committed on the feature branch. For each row:

1. Apply the edit.
2. Run the command below and confirm that it prints at least one line. That line carries both the expected tag and the spec path.
3. Revert with `git checkout -- packages/orbital_core test specs` before the next row.

The command is:

    flutter test test/orbital_core_perifocal_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-005.md"

"Delete the line X" and "Replace the line X" act on every line that equals X after trimming. "Replace every occurrence" acts on every occurrence of the substring. Inside the table, `\|` is a single pipe.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the perifocal library file | `[REQ-ORB-005.7]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the perifocal library file | `[REQ-ORB-005.7]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the perifocal library file | `[REQ-ORB-005.7]` |
| G4 | Add `import 'dart:ffi';` as the first line of the state-vector library file | `[REQ-ORB-005.7]` |
| G5 | Delete the line `/// Semi-major axis: a = (mu / n^2)^(1/3), with mu = 398600.4418 km^3/s^2 (WGS-84).` from the perifocal library file | `[REQ-ORB-005.6]` |
| G6 | Delete the line `/// Mean motion: the Kozai mean motion of the element set, used as is.` from the perifocal library file | `[REQ-ORB-005.6]` |
| G7 | Delete the line `/// Perifocal position: x = a (cos E - e), y = a sqrt(1 - e^2) sin E, z = 0.` from the perifocal library file | `[REQ-ORB-005.6]` |
| G8 | Delete the line `/// Perifocal velocity: sqrt(mu a) / r * (-sin E, sqrt(1 - e^2) cos E, 0), r = a (1 - e cos E).` from the perifocal library file | `[REQ-ORB-005.6]` |
| G9 | Delete the line `/// Rotation: R3(-raan) R1(-i) R3(-argp), from perifocal to inertial axes.` from the perifocal library file | `[REQ-ORB-005.6]` |
| G10 | Delete the line `/// Frame: the inertial frame of the elements; TEME for elements read from a TLE.` from the perifocal library file | `[REQ-ORB-005.6]` |
| G11 | Delete the line `/// Units: km, km/s and radians.` from the perifocal library file | `[REQ-ORB-005.6]` |
| G12 | Delete the line `/// Reference: CelesTrak fundamentals-of-astrodynamics, frame_conversions.py, coe2rv (Vallado: 2022, Ex. 2-6).` from the perifocal library file | `[REQ-ORB-005.6]` |
| G13 | Delete the line `/// Cartesian vector: components x, y and z along the axes of one frame.` from the state-vector library file | `[REQ-ORB-005.6]` |
| G14 | Delete the line `/// State vector: position in km and velocity in km/s, in the same frame.` from the state-vector library file | `[REQ-ORB-005.6]` |
| G15 | Delete the line `export 'src/perifocal.dart';` from the public library file | `[REQ-ORB-005.6]` |
| G16 | Delete the line `export 'src/state_vector.dart';` from the public library file | `[REQ-ORB-005.6]` |
| G17 | Delete the file `packages/orbital_core/lib/src/perifocal.dart` | `[REQ-ORB-005.6]` |
| G18 | Delete the file `packages/orbital_core/lib/src/state_vector.dart` | `[REQ-ORB-005.6]` |
| G19 | Replace the line `const double wgs84MuKm3S2 = 398600.4418;` with `const double wgs84MuKm3S2 = 398600.4415;` in the perifocal library file | `[REQ-ORB-005.6]` |
| G20 | Replace every occurrence of `double semiMajorAxisKmFromMeanMotion(` with `double semiMajorAxisKm(` in the perifocal library file | `[REQ-ORB-005.6]` |
| G21 | Replace every occurrence of `StateVector inertialStateVector(` with `StateVector inertialState(` in the perifocal library file | `[REQ-ORB-005.6]` |
| G22 | Replace the line `required double semiMajorAxisKm,` with `required double semiMajorAxis,` in the perifocal library file | `[REQ-ORB-005.6]` |
| G23 | Replace the line `required double eccentricity,` with `required double ecc,` in the perifocal library file | `[REQ-ORB-005.6]` |
| G24 | Replace the line `required double inclinationRad,` with `required double inclination,` in the perifocal library file | `[REQ-ORB-005.6]` |
| G25 | Replace the line `required double raanRad,` with `required double rightAscensionRad,` in the perifocal library file | `[REQ-ORB-005.6]` |
| G26 | Replace the line `required double argumentOfPerigeeRad,` with `required double argpRad,` in the perifocal library file | `[REQ-ORB-005.6]` |
| G27 | Replace the line `required double eccentricAnomalyRad,` with `required double anomalyRad,` in the perifocal library file | `[REQ-ORB-005.6]` |
| G28 | Delete the line `required double eccentricity,` from the perifocal library file and insert it directly after the line `required double eccentricAnomalyRad,` | `[REQ-ORB-005.6]` |
| G29 | Replace every occurrence of `final class CartesianVector` with `class CartesianVector` in the state-vector library file | `[REQ-ORB-005.6]` |
| G30 | Replace every occurrence of `const CartesianVector(this.x, this.y, this.z)` with `const CartesianVector(this.z, this.y, this.x)` in the state-vector library file | `[REQ-ORB-005.6]` |
| G31 | Replace every occurrence of `final double x;` with `double x;` in the state-vector library file | `[REQ-ORB-005.6]` |
| G32 | Replace every occurrence of `final double y;` with `double y;` in the state-vector library file | `[REQ-ORB-005.6]` |
| G33 | Replace every occurrence of `final double z;` with `double z;` in the state-vector library file | `[REQ-ORB-005.6]` |
| G34 | Replace every occurrence of `final class StateVector` with `class StateVector` in the state-vector library file | `[REQ-ORB-005.6]` |
| G35 | Replace every occurrence of `const StateVector({required this.positionKm, required this.velocityKmS})` with `const StateVector({required this.velocityKmS, required this.positionKm})` in the state-vector library file | `[REQ-ORB-005.6]` |
| G36 | Replace every occurrence of `final CartesianVector positionKm` with `final CartesianVector position` in the state-vector library file | `[REQ-ORB-005.6]` |
| G37 | Replace every occurrence of `final CartesianVector velocityKmS` with `final CartesianVector velocity` in the state-vector library file | `[REQ-ORB-005.6]` |
| G38 | Append the line `var cache = 0;` to the state-vector library file | `[REQ-ORB-005.6]` |
| G39 | Append the line `set cache(int value) {}` to the state-vector library file | `[REQ-ORB-005.6]` |
| G40 | Append the line `late final int cache;` to the state-vector library file | `[REQ-ORB-005.6]` |
| G41 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-005.7]` |
| G42 | Add `import 'package:orbital_core/src/perifocal.dart';` to the math test file | `[REQ-ORB-005.7]` |
| G43 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-005.7]` |
| G44 | Replace the line `// REQ-ORB-005.2` with `// REQ-ORB-005.x`, keeping its indentation, in the math test file | `[REQ-ORB-005.7]` |
| G45 | Insert the line `// note` directly after the line `// REQ-ORB-005.1` in the math test file | `[REQ-ORB-005.7]` |
| G46 | Delete the citation line that starts with `// Vallado repository: https://` from the math test file | `[REQ-ORB-005.7]` |
| G47 | Delete the citation line that starts with `// Vallado repository, test_frame_conversions.py, test_coe2rv` from the math test file | `[REQ-ORB-005.7]` |
| G48 | Delete the citation line that starts with `// Vallado repository, test_frame_conversions.py, test_perifocal_transform` from the math test file | `[REQ-ORB-005.7]` |
| G49 | Delete the citation line that starts with `// Vallado et al., Revisiting Spacetrack Report #3` from the math test file | `[REQ-ORB-005.7]` |
| G50 | Append the line `// skip: true` to the math test file | `[REQ-ORB-005.7]` |
| G51 | Run `sed -i 's/$/\r/' packages/orbital_core/test/perifocal_test.dart` (CRLF) | `[REQ-ORB-005.7]` |
| G52 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/perifocal_test.dart > /tmp/g52 && mv /tmp/g52 packages/orbital_core/test/perifocal_test.dart` (BOM) | `[REQ-ORB-005.7]` |
| G53 | Run `sed -i 's/$/\r/' specs/req-orb-005.md` (CRLF in the spec file) | `[REQ-ORB-005.7]` |
| G54 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-005.7]` |
| G55 | Replace the line `// REQ-ORB-005.6` with `// REQ-ORB-005.x`, keeping its indentation, in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-ORB-005.7]` |
| G56 | Delete the file `packages/orbital_core/test/perifocal_test.dart` | `[REQ-ORB-005.7]` |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V11 and G1–G56, each with its observed result, and the review item below. A pull request without this list is incomplete regardless of its check status.

- **R1:** the reviewer confirms REQ-ORB-005.6 (review acceptance): the new library files declare no public top-level name other than the five fixed names, and the two classes declare no public member other than their fixed constructor and fields.

## Edge Cases & Errors

- **Circular orbits (e = 0).** The argument of perigee has no physical meaning, but the formulas stay defined: the position is measured from the given ω. The grid of REQ-ORB-005.4 includes e = 0.0.
- **Equatorial orbits (i = 0 or π).** The node has no physical meaning, but P, Q and W stay defined and orthonormal. The grid includes i = 0.0 and i = π.
- **Angles outside their usual ranges.** The state vector function takes plain numbers and does not range-check the angles: any finite angle gives a rotation. Element sets carry inclinations from 0 to π only (req-orb-003).
- **Eccentricity near 1.** At perigee the radius is small and the velocity large, both finite. The grid includes e = 0.9999999, the largest value the TLE eccentricity field can carry (req-orb-003).
- **Very large semi-major axis.** The largest axis an element set can produce is about 9.1·10⁹ km (REQ-ORB-005.1), and its state vector is finite (REQ-ORB-005.4). For plain inputs far above that, products such as μ · a can overflow; such inputs are not reachable from any element set, and this spec does not check the result for them.
- **Rounding of π / 2.** cos(π / 2) as a double is about 6.1·10⁻¹⁷, not 0, so the Q row of REQ-ORB-005.3 is checked within a tolerance, never exactly.
- **Negative zero eccentricity.** Accepted as 0.0, with the same result (REQ-ORB-005.5).
- **Different μ in the reference.** The published state vector used μ = 398600.4415 km³/s². The velocity tolerance of REQ-ORB-005.2 covers the difference; the position does not depend on μ when a is given.
- **Two gravitational parameters.** Once req-orb-010 lands, the core holds the WGS-84 μ of this spec and the WGS-72 μ of SGP4. Each is named after its model (ADR-0003, Amendment 1), so a spec that needs μ picks it by name; the Kepler propagator and req-orb-008 use the WGS-84 one.
- **Kozai mean motion.** The semi-major axis is computed from the Kozai mean motion as is, so it is a few kilometres off the SGP4 value for low orbits. This is a documented model choice (Context), not an error.
- **Declarations split by the formatter.** Each fixed declaration fits within 80 columns, so `dart format` keeps it on one line. The state vector function is the exception, and its parameter lines are fixed one per line. If a future formatter changes either layout, the guard reports `[REQ-ORB-005.6]`. The fix is a spec change, never a relaxed guard.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-005.7). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access at run time. V11 needs `git fetch` and is a local check; if the fetch fails, V11 counts as not run, never as a pass. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.

## Out of Scope

Nothing below is written in this pull request:

- Converting the Kozai mean motion to the Brouwer mean motion, J2 or any other perturbation, and any WGS-72 constant (req-orb-010).
- The true anomaly, or any public conversion between the true and the eccentric anomaly. The math test file converts the published ν of Example 2-6 to E itself.
- A function that takes an element set or an instant, the propagator interface, or a propagated state that carries M and E (req-orb-009).
- The rotation to ECEF and any use of GMST (req-orb-006), geodetic coordinates (req-orb-007), and the altitude, speed or period shown to the user (req-orb-008). The vis-viva identity appears only as a check in the math test file.
- Arithmetic, value equality, hashing or formatting of the new value types (addition, dot or cross products, lengths, `toString`).
- Parabolic or hyperbolic orbits, or any eccentricity of 1 or more.
- Any change to `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart` or `kepler.dart`, or to their tests and guards.
- Copying code from the Vallado repository; only its published values are cited.
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR. ADR-0005 and Amendment 1 of ADR-0003 travel with this spec in the spec pull request, never in the implementation pull request.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
