# req-orb-006 — Inertial to ECEF rotation

- **Status:** Ready for implementation (revision 3, after the second QA audit: findings 1, 2, 3, 4, 5, 8, 9 and 11). The developer approved the scope, the input and the reference rows on 2026-11-01, before drafting, and the revision 3 changes on 2026-11-02. Every published value was checked against a freely available primary source while drafting (see Definitions), and the second QA audit re-checked every value and cited line against the pinned commit.
- **Roadmap row:** 8 of 33 (MVP)
- **Blocks:** req-orb-007 (geodetic coordinates convert the Earth-fixed position defined here), req-orb-009 (the propagated state carries GMST and the Earth-fixed position), req-mth-001 (math mode shows the ECEF vector)
- **Depends on:** req-orb-001 (two-part Julian date, used by the math test file to build GMST), req-orb-002 (GMST, IAU-82), req-orb-005 (`CartesianVector` and the inertial frame of the elements), req-inf-002 (CI quality gates), ADR-0001 (baseline packages)
- **ADR:** none required. The work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`, so ADR-0001 is unchanged. It adds no constant, so ADR-0003 (Amendment 1) does not apply. Every expected value is published, so no exception to Constitution principle 6 is needed. The reference values come from a repository licensed under AGPL-3.0; this spec and its tests cite published numbers only, and copy no code from it.

## Context & Objective

req-orb-005 delivers the position of an object in the inertial frame of its elements: TEME for elements read from a TLE, the frame in which SGP4 also delivers its output (AIAA 2006-6753). req-orb-002 delivers how far the Earth has turned at an instant: GMST. Nothing yet connects the two, so no position can be placed over a point of the rotating Earth. This spec delivers what roadmap row 8 names, as step 7 of the Project Brief's pipeline fixes it: GMST rotates the inertial position into the Earth-fixed frame, which unblocks every ground-referenced coordinate (geodetic latitude, longitude and altitude, the globe, the orbit path and the ECEF vector of math mode).

The decisions below are fixed so later specs inherit them. The developer approved each one before drafting.

- **Rotation.** The Earth-fixed position is R₃(GMST) applied to the inertial position: a rotation about the z axis by the GMST angle. This is the TEME to pseudo-Earth-fixed rotation of Vallado's SGP4 code (AIAA 2006-6753, `teme2ecef`). The z component is unchanged.
- **Position only.** The rotation acts on a position. No MVP consumer needs an Earth-relative velocity: geodetic coordinates (req-orb-007), the globe and the orbit path need positions, math mode shows the ECEF position vector (req-mth-001), and the speed of the object card is the inertial speed by vis-viva (req-orb-008). An Earth-relative velocity also needs the Earth's rotation rate (the term ω⊕ × r) and a new constant; both are left to a later spec, if one ever needs them.
- **Plain inputs.** The function takes the inertial position and GMST in radians, so that published values are tested directly, as req-orb-004 and req-orb-005 do. Computing GMST from an instant is req-orb-002's job, and composing an element set, an instant and both steps into a propagated state is req-orb-009's job. GMST is accepted as any finite angle, not only the range that req-orb-002 produces, because every finite angle defines a rotation.
- **Named parameters.** The two inputs are required named parameters, as in req-orb-005, so that a call states which value is the position and which is the angle.
- **Ignored terms.** Polar motion and the kinematic terms that Vallado's code adds to GMST after 1997 (`frame_conversions.py`, `get_teme_transform_matrices`, line 1418) are not applied. Polar motion needs Earth orientation parameters from the IERS, a data source the Constitution does not allow without an ADR (principle 1). The kinematic terms are 0.00264″ · sin Ω + 0.000063″ · sin 2Ω, where Ω is the longitude of the Moon's ascending node, so they never exceed 0.002703″ (1.31·10⁻⁸ rad), about 0.55 m at geostationary distance. The excess length of day changes only the Earth's rotation rate, which only an Earth-relative velocity needs (Position only), so it does not enter this rotation. This continues the UTC ≈ UT1 decision of req-orb-001. REQ-ORB-006.1 measures the kinematic terms (9.0·10⁻⁹ rad at the reference instant) and REQ-ORB-006.2 measures polar motion.
- **Output frame.** The result is expressed in the Earth-fixed axes without polar motion, which Vallado calls PEF (pseudo Earth-fixed). Wintek uses these axes as its ECEF frame. Their z axis is the Celestial Ephemeris Pole and their x axis lies in the Greenwich meridian. They differ from the ITRF by the ignored polar motion.
- **Reused type.** The input and the output are the `CartesianVector` of req-orb-005, in kilometres. No new value type is added.
- **Input validation.** Non-finite position components and a non-finite GMST are rejected, each with an exact message. The roadmap row does not name this. It is kept for the same reason as in req-orb-004 and req-orb-005: the function runs on the frame path, and an unchecked NaN would flow silently into the globe.
- **Free sources only.** Every published reference value comes from the test suite that CelesTrak publishes with the code of Vallado's textbook, pinned to the commit used by req-orb-004 and req-orb-005 (Definitions).

## Definitions used by every requirement

These definitions are normative.

- **Vallado repository:** CelesTrak, "fundamentals-of-astrodynamics", at `https://github.com/CelesTrak/fundamentals-of-astrodynamics`, licensed under AGPL-3.0, as described in `specs/req-orb-004.md`. Three of its files are cited, all at commit `49df0479c950917c0a2c5ac31f2db6477bba57f6`:
  - `software/python/tests/astro/time/test_frame_conversions.py`:
    - its fixture `rva_teme` (line 86) publishes the TEME position (2994.454240128889, −7384.574761007484, 6380.344532748868) km, the output of its test `test_eci2teme` (line 344);
    - its fixture `rva_pef` (line 38, labelled `[opt = "80"]`) publishes the PEF position (−1033.4750313057266, 7901.305585585349, 6380.344532748868) km of the same state, the output of its test `test_eci2pef` (line 246);
    - its fixture `rva_ecef` (line 21) publishes the ECEF position (−1033.4793830, 7901.2952754, 6380.3565958) km, which its test `test_teme2ecef` (line 548) produces from the TEME position of `rva_teme_ecef` (line 95), equal to that of `rva_teme`;
    - its fixture `t_inputs` (line 138) publishes the Julian date of UT1 shared by all three, `jdut1 = 2453101.5`;
  - `software/python/src/valladopy/astro/time/frame_conversions.py`, function `teme2ecef` (line 1507), which produced the published ECEF position and cites "Vallado: 2022, p. 232-234";
  - `software/python/src/valladopy/astro/time/sidereal.py`, function `gstime` (line 17), the IAU-82 GMST that the published values use, the same polynomial as req-orb-002.
- **Reference instant:** 2004-04-06T00:00:00Z, the UTC instant whose Julian date is the published `jdut1 = 2453101.5`, under the UTC ≈ UT1 decision of req-orb-001.
- **Reference GMST:** the GMST of req-orb-002 at the reference instant, computed in the math test file through the two-part Julian date of req-orb-001. It evaluated to 3.396772787771726 rad when this spec was drafted. The math test file computes it; it never writes it as a literal.
- **Published TEME position**, **published PEF position** and **published ECEF position:** the three positions of the Vallado repository above.
- **Rotation to Earth-fixed axes:** for an inertial position (x, y, z) and an angle θ, the position (cos θ · x + sin θ · y, −sin θ · x + cos θ · y, z). This is R₃(θ) applied to the inertial position.
- **Earth-fixed position:** the rotation to Earth-fixed axes of an inertial position, with θ = GMST.
- **2π (as a double):** `2 * pi` with `pi` from `dart:math`, as in `specs/req-orb-004.md`.
- **|v|:** the Euclidean length of a vector v.
- **Close to within x:** the absolute difference from the expected value is at most x. For a vector, each of its three components is close to within x of the matching expected component.
- **Exact:** compared with `==` on doubles, with no tolerance.
- **Earth-fixed library file:** `packages/orbital_core/lib/src/earth_fixed.dart`.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/earth_fixed_test.dart`. It covers REQ-ORB-006.1 to .5.
- **Guard test file:** `test/orbital_core_earth_fixed_guard_test.dart`, in the application suite.
- **Spec file:** `specs/req-orb-006.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-006.1 — Published TEME position to the published PEF position

The published TEME position, rotated by the reference GMST, yields the published PEF position of the same state.

**Acceptance (verified by the math test file).**

- The input is the published TEME position, written as literal numbers. The angle is the reference GMST (Definitions).
- The result is close to within 1·10⁻⁴ km of the published PEF position.

The error measured while drafting was 7.1·10⁻⁵ km. It is the kinematic terms that Vallado's code adds to GMST (Context, Ignored terms): the angle between the two published positions exceeds the reference GMST by 9.0·10⁻⁹ rad. The published z components are equal, as the rotation requires.

The two positions are outputs of two different published tests (`test_eci2teme` and `test_eci2pef`) that start from the same inertial state and the same time inputs, so they express one state in two frames. The repository publishes no direct TEME to PEF test; REQ-ORB-006.2 adds the direct published TEME to ECEF test.

### REQ-ORB-006.2 — Published TEME position to the published ECEF position

The published TEME position, rotated by the reference GMST, yields the published ECEF position of `test_teme2ecef` within the cost of the ignored polar motion.

**Acceptance (verified by the math test file).**

- The input is the published TEME position, written as literal numbers. The angle is the reference GMST.
- The result is close to within 2·10⁻² km of the published ECEF position.

The error measured while drafting was 1.21·10⁻² km, in the z component. It is the polar motion that `test_teme2ecef` applies (xp = −0.140682″, yp = 0.333309″) and this spec ignores (Context). The tolerance bounds that documented cost; it is not a measure of the rotation, which REQ-ORB-006.1 measures.

The 1.21·10⁻² km is the cost at this instant and this position only, not a bound. Polar motion has stayed within about 0.6″ (2.9·10⁻⁶ rad) of the pole, so ignoring it moves a position by at most about 20 m in low orbit and 125 m at geostationary distance, below one pixel on the globe. These figures are not checked by any test.

### REQ-ORB-006.3 — Fixed rotations

Simple angles move the axes as the rotation to Earth-fixed axes requires, with the sign convention of R₃(θ).

**Acceptance (verified by the math test file).**

| Inertial position (km) | GMST (rad) | Expected Earth-fixed position (km) | Comparison |
| --- | --- | --- | --- |
| (1.0, 2.0, 3.0) | 0.0 | (1.0, 2.0, 3.0) | Exact |
| (−1033.4750313057266, 7901.305585585349, 6380.344532748868) | 0.0 | (−1033.4750313057266, 7901.305585585349, 6380.344532748868) | Exact |
| (1.0, 0.0, 0.0) | π / 2 | (0.0, −1.0, 0.0) | Close to within 1·10⁻¹⁵ |
| (0.0, 1.0, 0.0) | π / 2 | (1.0, 0.0, 0.0) | Close to within 1·10⁻¹⁵ |
| (1.0, 0.0, 0.0) | π | (−1.0, 0.0, 0.0) | Close to within 1·10⁻¹⁵ |
| (0.0, 0.0, 1.0) | π / 2 | (0.0, 0.0, 1.0) | Exact |

π / 2 and π are `pi / 2` and `pi` from `dart:math`. cos(π / 2) as a double is about 6.1·10⁻¹⁷ and sin(π) about 1.2·10⁻¹⁶, so those rows are checked within a tolerance, never exactly.

The quarter-turn rows fix the direction: as the Earth turns east, a point fixed in inertial space moves west over the ground, so the inertial x axis appears on the Earth-fixed −y axis.

### REQ-ORB-006.4 — Rotation identities over a grid

Every Earth-fixed position keeps the length and the z component of its inertial position, two rotations compose into one, and a full turn changes nothing. A position that turns with the Earth stays fixed over the ground, which is what makes a geostationary object appear motionless on the globe.

**Acceptance (verified by the math test file).**

- **Grid.** Every combination of:
  - the inertial position in {(6778.0, 0.0, 0.0), (4000.0, −5000.0, 3000.0), (the published TEME position), (−42164.0, 1·10⁻³, −2.0), (0.0, 0.0, 6378.137), (9.1·10⁹, −9.1·10⁹, 9.1·10⁹)} km;
  - GMST θ in {k · 2π / 36, for k from 0 to 35} ∪ {−10.0, 100.0} rad.
- For each combination, with r the inertial position and f(r, θ) its Earth-fixed position:
  - **length:** the absolute difference of |f(r, θ)| and |r| is at most 1·10⁻¹⁴ · |r|;
  - **axis:** the z component of f(r, θ) is exactly the z component of r;
  - **full turn:** f(r, θ + 2π) is close to within 1·10⁻¹³ · |r| of f(r, θ);
  - **composition:** for every second angle φ of the same GMST set, f(f(r, θ), φ) is close to within 1·10⁻¹³ · |r| of f(r, θ + φ).
- **Turning with the Earth.** For every radius ρ in {6778.0, 42164.0, 9.1·10⁹} km and every θ of the GMST set, the inertial position (ρ · cos θ, ρ · sin θ, 0.0) rotated by θ is close to within 1·10⁻¹⁴ · ρ of (ρ, 0.0, 0.0).

These identities are properties of a rotation and add no formula to the package. The largest errors measured while drafting, relative to |r| or ρ, were 1.8·10⁻¹⁶ (length), 5.9·10⁻¹⁵ (full turn), 6.6·10⁻¹⁵ (composition) and 3.5·10⁻¹⁶ (turning with the Earth); the axis check was exact.

### REQ-ORB-006.5 — Input validation with exact messages

The function accepts only the inputs below. Any other input throws Dart's `ArgumentError` and returns no value. No message contains an apostrophe, so each can be written in the Earth-fixed library file as a plain single-quoted string. "Finite" means neither NaN nor positive or negative infinity.

Checks run in this order and the first failure wins:

1. the three components of the inertial position are finite, otherwise message P;
2. GMST is finite, otherwise message G.

The messages:

- **Message P:** `ECEF rotation requires a finite inertial position.`
- **Message G:** `ECEF rotation requires a finite GMST.`

**Acceptance (verified by the math test file).**

- "Throws X" means the thrown object is an `ArgumentError` whose message is equal to message X, character for character.
- "Accepted" means the function returns without throwing and every component of its result is finite.
- Unless a row says otherwise, the inputs are the inertial position (7000.0, −1000.0, 500.0) km and GMST = 1.0 rad, and the row changes only the inputs it names.

| Input | Expected |
| --- | --- |
| x = NaN | Throws P |
| y = positive infinity | Throws P |
| z = negative infinity | Throws P |
| GMST = NaN | Throws G |
| GMST = positive infinity | Throws G |
| GMST = negative infinity | Throws G |
| x = NaN and GMST = NaN | Throws P (the position is checked first) |
| GMST = −0.0 | Accepted; every component equals, exactly, the matching component for GMST = 0.0 |
| GMST = 2π | Accepted |
| GMST = −10.0 | Accepted |
| position = (0.0, 0.0, 0.0) | Accepted; every component equals 0.0, compared exactly |

### REQ-ORB-006.6 — Placement, public names and documented contract

The function lives in the Earth-fixed library file and is reachable through the public library file. Its documentation states the rotation, the input frame, the output frame, the ignored terms, the units and the reference, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The Earth-fixed library file exists.
- The public library file contains the line `export 'src/earth_fixed.dart';`.
- **Doc block.** The doc block of the function is the run of consecutive lines directly before the line `CartesianVector ecefPositionKm({` whose text, with leading and trailing spaces removed, starts with `///`. It contains each of these six lines, in any order:
  - `/// Rotation: r_ecef = R3(gmst) r_inertial, a rotation about the z axis.`
  - `/// Input frame: the inertial frame of the elements; TEME for elements read from a TLE.`
  - `/// Output frame: Earth-fixed axes without polar motion (PEF), used as ECEF.`
  - `/// Ignored: polar motion and the kinematic terms added to GMST.`
  - `/// Units: km and radians.`
  - `/// Reference: CelesTrak fundamentals-of-astrodynamics, time/frame_conversions.py, teme2ecef (Vallado: 2022, p. 232-234).`
- **Public name.** The line `CartesianVector ecefPositionKm({` must appear in the Earth-fixed library file, compared after trimming. This name is the contract that req-orb-007 and req-orb-009 read.
- **Parameters.** The two lines directly after that line are, in this order and each equal after trimming: `required CartesianVector inertialPositionKm,` and `required double gmstRad,`. `dart format` always splits this declaration one parameter per line, because it does not fit within 80 columns.
- **Single top-level declaration.** Every line of the Earth-fixed library file that has a character other than a space at its first column, compared with no spaces removed, starts with `//`, starts with `import '`, or is equal to one of `CartesianVector ecefPositionKm({`, `}) {` and `}`. Empty lines are allowed. `dart format` writes every top-level declaration at the first column and every line inside the function indented, so the file declares no top-level name other than `ecefPositionKm`: no constant, variable, class, enum, extension, typedef or second function, public or private. Local variables inside the function are indented and stay allowed.

**Acceptance (verified by command V11).** Compared with `main`, this pull request adds or changes exactly four files and no other: the public library file, the Earth-fixed library file, the math test file and the guard test file. This enforces the file list of Out of Scope by machine.

### REQ-ORB-006.7 — Purity, citations and test hygiene

The new code adds no dependency, every published value is cited in the math test file, and the new files follow the hygiene rules of req-orb-005.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file contains each of these three citation lines, compared after trimming:
  - `// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/time/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.`
  - `// Vallado repository, test_frame_conversions.py, fixtures rva_teme and rva_pef (opt 80): TEME and PEF positions of one state, jdut1 = 2453101.5.`
  - `// Vallado repository, test_frame_conversions.py, test_teme2ecef: TEME position to ECEF position with polar motion, jdut1 = 2453101.5.`
- The math test file contains, for each N from 1 to 5, a line equal to `// REQ-ORB-006.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
- The guard test file contains, for each N in {6, 7}, a line equal to `// REQ-ORB-006.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
- The guard test file builds the tag strings of the math test file (`// REQ-ORB-006.1` to `.5`) by interpolation, never as literals, so that V10 prints only its own tags.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the guard test file, the core library files and the spec file.
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser. `dart:io` never appears in `packages/orbital_core`, which the two regular expressions above enforce.
- Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, the Earth-fixed library file, the public library file, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-006.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-006.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-006.7, which the guard test file checks (Constitution principle 6). The sources are:

- **Rotation (REQ-ORB-006.1):** the TEME and PEF positions published by the Vallado repository for one state, compared within the size of the ignored kinematic terms.
- **Rotation with the cost of polar motion (REQ-ORB-006.2):** the TEME to ECEF test published by the Vallado repository, compared within the size of the ignored polar motion.
- **Fixed rotations and grid (REQ-ORB-006.3, .4):** properties of a rotation, which introduce no new formula.

The angle of REQ-ORB-006.1 and .2 is computed by req-orb-002 from the published Julian date, so those rows also check that GMST and the rotation agree with the published values end to end.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `wc` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/earth_fixed_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-006.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-005 still pass |
| V4 | `flutter test test/orbital_core_earth_fixed_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-006.6, .7 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-006.7 |
| V6 | `flutter test` | exit 0 | REQ-ORB-006.6, .7; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-006\.[0-9]+" packages/orbital_core/test/earth_fixed_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-006.1,// REQ-ORB-006.2,// REQ-ORB-006.3,// REQ-ORB-006.4,// REQ-ORB-006.5` | REQ-ORB-006.7 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-006\.[0-9]+" test/orbital_core_earth_fixed_guard_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-006.6,// REQ-ORB-006.7` | REQ-ORB-006.7 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --name-only origin/main...HEAD \| sort \| paste -sd, -` | standard output `packages/orbital_core/lib/orbital_core.dart,packages/orbital_core/lib/src/earth_fixed.dart,packages/orbital_core/test/earth_fixed_test.dart,test/orbital_core_earth_fixed_guard_test.dart` | REQ-ORB-006.6 (only the four files of this spec change) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after every file of this pull request is committed on the feature branch, so that the revert below restores each of them. Before G0, `git status --porcelain` must print nothing; otherwise stop, because G11, G12, G36 and the revert would destroy uncommitted work.

The command is:

    flutter test test/orbital_core_earth_fixed_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-006.md"

**Control run (G0).** With no edit applied, run the command once with `<tag>` replaced by `[REQ-ORB-006.6]` and once with `[REQ-ORB-006.7]`, and confirm that each prints nothing. A line printed here means that the output of a passing run, such as a test name, already carries a tag and the spec path, so the rows below would prove nothing; fix the guard test file before continuing.

Then, for each row of the table:

1. Apply the edit.
2. Run the command and confirm that it prints at least one line. That line carries both the expected tag and the spec path.
3. Revert with `git checkout -- packages/orbital_core test specs` before the next row.

"Delete the line X" and "Replace the line X" act on every line that equals X after trimming. "Replace every occurrence" acts on every occurrence of the substring. Inside the table, `\|` is a single pipe.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the Earth-fixed library file | `[REQ-ORB-006.7]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the Earth-fixed library file | `[REQ-ORB-006.7]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the Earth-fixed library file | `[REQ-ORB-006.7]` |
| G4 | Add `import 'dart:ffi';` as the first line of the Earth-fixed library file | `[REQ-ORB-006.7]` |
| G5 | Delete the line `/// Rotation: r_ecef = R3(gmst) r_inertial, a rotation about the z axis.` from the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G6 | Delete the line `/// Input frame: the inertial frame of the elements; TEME for elements read from a TLE.` from the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G7 | Delete the line `/// Output frame: Earth-fixed axes without polar motion (PEF), used as ECEF.` from the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G8 | Delete the line `/// Ignored: polar motion and the kinematic terms added to GMST.` from the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G9 | Delete the line `/// Units: km and radians.` from the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G10 | Delete the line `/// Reference: CelesTrak fundamentals-of-astrodynamics, time/frame_conversions.py, teme2ecef (Vallado: 2022, p. 232-234).` from the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G11 | Delete the line `export 'src/earth_fixed.dart';` from the public library file | `[REQ-ORB-006.6]` |
| G12 | Delete the file `packages/orbital_core/lib/src/earth_fixed.dart` | `[REQ-ORB-006.6]` |
| G13 | Replace every occurrence of `CartesianVector ecefPositionKm(` with `CartesianVector ecefPosition(` in the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G14 | Replace the line `required CartesianVector inertialPositionKm,` with `required CartesianVector positionKm,` in the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G15 | Replace the line `required double gmstRad,` with `required double gmst,` in the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G16 | Delete the line `required double gmstRad,` from the Earth-fixed library file and insert it directly before the line `required CartesianVector inertialPositionKm,` | `[REQ-ORB-006.6]` |
| G17 | Append the line `const double earthRotationRadS = 7.292115e-5;` to the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G18 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-006.7]` |
| G19 | Add `import 'package:orbital_core/src/earth_fixed.dart';` to the math test file | `[REQ-ORB-006.7]` |
| G20 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-006.7]` |
| G21 | Replace the line `// REQ-ORB-006.2` with `// REQ-ORB-006.x`, keeping its indentation, in the math test file | `[REQ-ORB-006.7]` |
| G22 | Insert the line `// note` directly after the line `// REQ-ORB-006.1` in the math test file | `[REQ-ORB-006.7]` |
| G23 | Delete the citation line that starts with `// Vallado repository: https://` from the math test file | `[REQ-ORB-006.7]` |
| G24 | Delete the citation line that starts with `// Vallado repository, test_frame_conversions.py, fixtures rva_teme` from the math test file | `[REQ-ORB-006.7]` |
| G25 | Delete the citation line that starts with `// Vallado repository, test_frame_conversions.py, test_teme2ecef` from the math test file | `[REQ-ORB-006.7]` |
| G26 | Append the line `// skip: true` to the math test file | `[REQ-ORB-006.7]` |
| G27 | Run `sed -i 's/$/\r/' packages/orbital_core/test/earth_fixed_test.dart` (CRLF) | `[REQ-ORB-006.7]` |
| G28 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/earth_fixed_test.dart > /tmp/g28 && mv /tmp/g28 packages/orbital_core/test/earth_fixed_test.dart` (BOM) | `[REQ-ORB-006.7]` |
| G29 | Run `sed -i 's/$/\r/' specs/req-orb-006.md` (CRLF in the spec file) | `[REQ-ORB-006.7]` |
| G30 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-006.7]` |
| G31 | Replace the line `// REQ-ORB-006.6` with `// REQ-ORB-006.x`, keeping its indentation, in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-ORB-006.7]` |
| G32 | Delete the file `packages/orbital_core/test/earth_fixed_test.dart` | `[REQ-ORB-006.7]` |
| G33 | Append the line `double _earthRateRadS = 7.292115e-5;` to the Earth-fixed library file | `[REQ-ORB-006.6]` |
| G34 | Delete the line `/// Units: km and radians.` from the Earth-fixed library file and insert it as the first line of the same file | `[REQ-ORB-006.6]` |
| G35 | Run `sed -i 's/$/\r/' packages/orbital_core/lib/src/earth_fixed.dart` (CRLF in a core library file) | `[REQ-ORB-006.7]` |
| G36 | Delete the file `packages/orbital_core/lib/orbital_core.dart` | `[REQ-ORB-006.6]` |
| G37 | Run `printf '\xEF\xBB\xBF' \| cat - specs/req-orb-006.md > /tmp/g37 && mv /tmp/g37 specs/req-orb-006.md` (BOM in the spec file) | `[REQ-ORB-006.7]` |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V11 and G0–G37, each with its observed result. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **Angles outside 0 to 2π.** GMST from req-orb-002 is always from 0 inclusive to 2π exclusive, but the function accepts any finite angle and gives the same rotation as its normalized value, within the full-turn tolerance of REQ-ORB-006.4. It does not normalize the angle itself.
- **Negative zero GMST.** Accepted as 0.0, with the same result (REQ-ORB-006.5).
- **Zero vector.** The origin rotates to the origin (REQ-ORB-006.5). Components may come out as −0.0, which compares equal to 0.0.
- **Positions on the z axis.** A position along the rotation axis is unchanged for every angle (REQ-ORB-006.3, last row; REQ-ORB-006.4, grid row (0.0, 0.0, 6378.137)).
- **Very large positions.** The largest semi-major axis an element set can produce is about 9.1·10⁹ km (req-orb-005), and the grid of REQ-ORB-006.4 includes positions of that size. The rotation multiplies each component by a cosine or a sine and adds two such products, so it cannot overflow for any position whose components are below about 8·10³⁰⁷ km in magnitude; this spec does not check larger inputs, which no element set can reach.
- **Rounding of π / 2 and π.** cos(π / 2) and sin(π) as doubles are not 0, so those rows of REQ-ORB-006.3 use a tolerance, never `==`.
- **Polar motion and the kinematic terms.** Ignored by decision (Context). REQ-ORB-006.1 and .2 measure their cost against published values. Applying either requires a spec change and, for polar motion, an ADR for the IERS data source (Constitution principle 1).
- **Length of day.** It does not enter the rotation of a position (Context, Ignored terms). It matters only for an Earth-relative velocity, which is out of scope.
- **Earth-relative velocity.** Not produced (Context, Position only). Rotating a velocity with this function gives a vector that is not the Earth-relative velocity, because it lacks the term ω⊕ × r; no consumer may do so. req-orb-009 carries only the Earth-fixed position.
- **Frame of the Kepler propagator.** The inertial frame of the elements is TEME for elements read from a TLE, so the same rotation serves both propagators (req-orb-005, Context). No separate rotation is needed for the Kepler output.
- **UTC as UT1.** GMST is computed from UTC (req-orb-001). A DUT1 of up to 0.9 s turns the Earth by at most 6.6·10⁻⁵ rad, which moves a geostationary position by at most 2.8 km. This is inherited, not new, and the published rows of this spec use the published UT1 date as UTC, so they do not include it.
- **Declarations split by the formatter.** The public declaration does not fit within 80 columns, so `dart format` splits its parameters one per line, which the guard fixes. The single top-level declaration rule of REQ-ORB-006.6 relies on the same formatter, which writes every top-level declaration at the first column and closes this declaration with `}) {`. If a future formatter changes that layout, the guard reports `[REQ-ORB-006.6]`. The fix is a spec change, never a relaxed guard.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-006.7). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access at run time. V11 needs `git fetch` and is a local check; if the fetch fails, V11 counts as not run, never as a pass. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.

## Out of Scope

Nothing below is written in this pull request:

- An Earth-relative velocity or acceleration, the Earth's rotation rate and its excess length of day, and any new constant. A new constant means a top-level declaration (REQ-ORB-006.6); local variables inside the function, `const` ones included, are allowed.
- Polar motion, the kinematic terms of GMST, nutation, Greenwich Apparent Sidereal Time, or any Earth orientation data from the IERS.
- The inverse rotation from Earth-fixed to inertial axes, and any conversion to or from GCRF, J2000, TOD, MOD, CIRS, TIRS or ITRF.
- A function that takes an element set, an instant or a Julian date, the propagator interface, or a propagated state (req-orb-009).
- Geodetic latitude, longitude and altitude, and the WGS-84 ellipsoid (req-orb-007).
- Any new value type, or any arithmetic, value equality, hashing or formatting of `CartesianVector`.
- Any change to `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart`, `kepler.dart`, `perifocal.dart` or `state_vector.dart`, or to their tests and guards.
- Copying code from the Vallado repository; only its published values are cited.
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
