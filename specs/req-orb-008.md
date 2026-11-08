# req-orb-008 — Derived orbital values

- **Status:** Draft (revision 2), after the first QA audit (findings 1.1 to 1.7, 2.1, 3.1 to 3.3 and 5.1), pending a second audit. The developer approved four decisions on 2026-11-07, before drafting: three separate functions (speed, period and inclination), the inclination taken from the state vector, the period checked against the WGS-84 angular velocity of the Earth and the sidereal day with no new ADR, and an `ArgumentError` for inconsistent speed inputs. On the same day the developer approved the revision 2 changes, including the edit of roadmap row 11 (req-orb-009). Every published value was checked while drafting against the pinned raw files of the Vallado repository or against a page that can be read free of charge (see Definitions), and every measured figure below was measured in Dart with a throwaway prototype of this contract, which is not part of the repository.
- **Roadmap row:** 10 of 33 (MVP)
- **Blocks:** req-orb-009 (its state must carry the inertial velocity that the inclination reads), req-sta-001 (composes the derived values per frame), req-ui-003 (the object card shows speed, period and inclination)
- **Depends on:** req-orb-003 (the Kozai mean motion of an element set), req-orb-005 (`CartesianVector`, `StateVector`, the constant `wgs84MuKm3S2` and `semiMajorAxisKmFromMeanMotion`), req-orb-006 (the decision that the card has no Earth-relative velocity), req-orb-007 (roadmap order only: the altitude of the card comes from it, and no code of it is used), req-inf-002 (CI quality gates), ADR-0001 (baseline packages), ADR-0003 Amendment 1 (the gravitational parameter is reused, decision 5).
- **ADR:** none required. ADR-0003 Amendment 1, accepted on 2026-11-01, already assigns the gravitational parameter to req-orb-005 and makes this spec reuse it, so this spec declares no constant. The work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`, so ADR-0001 is unchanged. Constitution principle 6 and the closing sentence of ADR-0005 ("any other formula that has no published reference value needs its own ADR") are met as follows. The speed and the inclination compare with published values (REQ-ORB-008.1 and .4). The period compares with a published pair: the input ω is published as a defining constant of WGS-84, and the output, a sidereal day, is published by two sources (REQ-ORB-008.3, first bullet). No source gives a worked example of T = 2π / n itself, and the pair is a plausibility check at 2.3·10⁻⁷ relative, not a worked example; Context records that weakness. The other rows of REQ-ORB-008.2 to .4 are identities and consistency checks, not published values. If a reviewer reads ADR-0005 as requiring a published worked example of this formula, the way out is a new ADR, not a change of the tests. The sources are read only while developing, so no data source is added at run time (Constitution principle 1). The Vallado repository is licensed under AGPL-3.0; this spec and its tests cite published numbers only, and copy no code from it.

## Context & Objective

The object card of the MVP shows altitude, speed, period and inclination. req-orb-007 defines the altitude. Nothing yet derives the other three. This spec delivers what roadmap row 10 names: the speed by the vis-viva equation, the orbital period and the inclination, the values step 9 of the Project Brief lists as derived data.

The developer approved the first four decisions below before drafting.

- **Three separate functions.** Speed, period and inclination take different inputs: a position and a semi-major axis, a mean motion, and a state vector. Each is a function of its own with its own tests, and no new value type joins them. req-orb-009 and the state providers compose them. A single function with one result type, as in req-orb-007, would force every caller to supply all the inputs at once.
- **Speed by vis-viva.** The speed is v = sqrt(μ · (2 / r − 1 / a)), with μ the constant `wgs84MuKm3S2` of req-orb-005 (ADR-0003, Amendment 1, decision 5) and r the length of the position. This is the speed relative to the inertial frame of the elements, which is the speed that step 9 of the Project Brief names. req-orb-006 chose to rotate the position only, so the card has no Earth-relative velocity to read, and this spec does not add one (Out of Scope). Only the length of the position is used, so a position in any frame gives the same speed.
- **Period from the mean motion.** T = 2π / n, with n the Kozai mean motion used as is, the choice that req-orb-005 and ADR-0005 inherit. It needs no semi-major axis.
- **Inclination from the state vector.** The inclination is computed from the inertial state, as the angle between the specific angular momentum h = r × v and the z axis. It is the osculating inclination, and it works the same for the Kepler propagator and for SGP4. It is not the mean inclination of the TLE, which `OrbitalElements.inclinationRad` already holds and which this spec leaves untouched. It is computed as atan2(sqrt(hx² + hy²), hz) and not as acos(hz / |h|): near 0 and π the acos form loses digits, and the prototype measured an error of 4.4·10⁻¹¹ rad at an inclination of 1·10⁻⁶ rad and of 4.9·10⁻⁹ rad at 1·10⁻⁸ rad, where atan2 measured 0.0. The result is 0.0 for a prograde equatorial orbit and π for a retrograde one.

The remaining decisions follow from the Constitution and the existing specs.

- **No second altitude.** Roadmap row 10 states that the altitude comes from req-orb-007. This spec defines none, and the speed does not read the altitude: it uses the length of the position from the center of the Earth, not the height above the ellipsoid.
- **Reference sources.** The speed and the inclination are anchored on two worked examples of Vallado, published by the CelesTrak repository: the state vector of Example 2-5 with its classical elements, and the vectors that Example 2-6 produces. The period is anchored on the WGS-84 angular velocity of the Earth and on the sidereal day (Definitions).
- **Consistency rows of the speed.** The semi-major axis that the repository publishes for Example 2-5 is computed by its `rv2coe` from the same position and velocity, through the energy equation, and the vectors of Example 2-6 come from the same p and ecc as the axis used here. So the two published speed rows of REQ-ORB-008.1 check the arithmetic and the gravitational parameter, and any correct vis-viva passes them. They do not check the model independently. The independent evidence is in REQ-ORB-008.2: the circular speed with a literal μ, the exact zero at r = 2a, and the grid against the velocity that req-orb-005 computes by the perifocal formula, which is a different path.
- **Different μ in the Vallado rows.** The repository computes its values with `MU` = 398600.4415 km³/s² (`constants.py`), not the 398600.4418 of the Project Brief. The relative difference of 7.5·10⁻¹⁰ in μ is 3.8·10⁻¹⁰ in a speed. It is documented in REQ-ORB-008.1 and is not an error of the library.
- **Weak anchor of the period.** No published numeric example of T = 2π / n was found among the free sources read while drafting. The period row compares a published input with a published output at the precision of the sources: 0.02 s of 86164 s, which is 2.3·10⁻⁷ relative. That excludes a wrong factor, the confusion of 2π with 360 and of days with seconds. It does not detect an error below that size. The mean-motion rows that are exact identities (REQ-ORB-008.3) and the agreement with Kepler's third law through req-orb-005 cover the rest. The sidereal day comes from Wikipedia and Kelso, which are not primary sources, and the primary report of ω could not be retrieved. This weakness is accepted and recorded here.
- **Consumers.** The inclination needs the inertial velocity as well as the position. req-orb-009 returns the propagated state, and the roadmap row 11 was edited with this spec so that its state carries the inertial state vector. req-sta-001 calls the three functions each frame. This spec does neither.
- **Input validation.** Non-finite inputs and the inputs that make a quantity undefined are rejected, each with an exact message. The roadmap row does not name this. It is kept for the same reason as in req-orb-004 to req-orb-007: the functions run on the frame path, and an unchecked NaN would flow silently into the card.
- **Named parameters.** The speed and the inclination take required named parameters, so a call states what each value is. The period takes its one parameter positionally, as `semiMajorAxisKmFromMeanMotion` does.
- **Units.** Kilometres, kilometres per second, seconds and radians (Constitution principle 12). Formatting for display is a job of the UI specs.
- **Free sources only.** Every published reference value comes from a document or repository that can be read free of charge (Definitions).

## Definitions used by every requirement

These definitions are normative.

- **Vallado repository:** CelesTrak, "fundamentals-of-astrodynamics", at `https://github.com/CelesTrak/fundamentals-of-astrodynamics`, licensed under AGPL-3.0, as described in `specs/req-orb-004.md`. Two of its files are cited, at commit `49df0479c950917c0a2c5ac31f2db6477bba57f6`: `software/python/src/valladopy/constants.py`, which fixes `MU` = 398600.4415 km³/s² on its line 61 (the **Vallado μ**), and `software/python/tests/astro/twobody/test_frame_conversions.py`. The second publishes:
  - the fixture `rv` of class `TestClassical`, labelled "Vallado, 2022, Ex. 2-5": the **Vallado 2-5 position** (6524.834, 6862.875, 6448.296) km and the **Vallado 2-5 velocity** (4.901327, 5.533756, −1.976341) km/s;
  - its test `test_rv2coe`, labelled "Vallado, 2022, Ex. 2-5", which asserts the **Vallado 2-5 semi-major axis** a = 36127.337763974785 km and the **Vallado 2-5 inclination** 1.5336055626394494 rad;
  - its test `test_coe2rv`, labelled "Vallado, 2022, Ex. 2-6", whose fixture `coe` has p = 11067.790 km, ecc = 0.83285 and incl = `np.radians(87.87)`, and which asserts the **Vallado 2-6 position** (6525.368120986091, 6861.531834896055, 6449.118614160162) km and the **Vallado 2-6 velocity** (4.902278644574153, 5.533139566279278, −1.9757100987916154) km/s.
- **Vallado μ difference:** the Vallado μ (398600.4415) differs from `wgs84MuKm3S2` (398600.4418) by 7.5·10⁻¹⁰ relative. With the Vallado μ, the speed rows of REQ-ORB-008.1 measured errors of 0.0 and 8.9·10⁻¹⁶ km/s.
- **Vallado 2-6 semi-major axis:** p / (1 − ecc²) with the published p and ecc, which the math test file computes. It is 36126.64283480516 km as measured.
- **Vallado 2-6 inclination:** 87.87 · π / 180 rad, the angle of the fixture `coe` converted by the math test file.
- **WGS-84 angular velocity:** ω = 72.92115·10⁻⁶ rad/s, which the article "World Geodetic System" of Wikipedia (`https://en.wikipedia.org/wiki/World_Geodetic_System`) states as "defined to be", citing the Department of Defense World Geodetic System 1984, DMA Technical Report 8350.2 (2nd edition, 1 September 1991). The report itself could not be retrieved while drafting, so it is not cited directly, as in req-orb-007.
- **Sidereal day:** 86164.0905 s, as stated by the article "Sidereal time" of Wikipedia (`https://en.wikipedia.org/wiki/Sidereal_time`), which gives no inline source for it.
- **Kelso sidereal day:** T. S. Kelso, "Basics of the Geostationary Orbit", *Satellite Times*, May 1998 (`https://celestrak.org/columns/v04n07/`), which states that one sidereal day is "equivalent to 23h56m04s of mean solar time", that is 86164 s, to the second.
- **Rotation about the z axis:** by an angle θ, the vector (x, y, z) becomes (x · cos θ − y · sin θ, x · sin θ + y · cos θ, z), with `cos` and `sin` from `dart:math`.
- **Degrees to radians:** a value of d degrees is d · π / 180, with `pi` from `dart:math`.
- **2π:** `2 * pi` with `pi` from `dart:math`.
- **|r|:** the square root of the sum of the squares of the three components of a vector.
- **Close to within x:** the absolute difference from the expected value is at most x.
- **Relatively close to within x:** the absolute difference from the expected value is at most x times the absolute value of the expected value.
- **Exact:** compared with `==` on doubles, with no tolerance, so 0.0 and −0.0 compare equal.
- **Derived library file:** `packages/orbital_core/lib/src/derived_values.dart`.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/derived_values_test.dart`. It covers REQ-ORB-008.1 to .5.
- **Guard test file:** `test/orbital_core_derived_values_guard_test.dart`, in the application suite.
- **Spec file:** `specs/req-orb-008.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-008.1 — Speed against two published worked examples

The vis-viva speed at a published position and semi-major axis equals the length of the published velocity.

**Acceptance (verified by the math test file).** The expected speed is |v| of the published velocity, computed in the math test file. "Speed" is the result of `visVivaSpeedKmS` (REQ-ORB-008.6).

| Source | Position (km) | Semi-major axis (km) | Expected speed (km/s) | Close to within |
| --- | --- | --- | --- | --- |
| Vallado Ex. 2-5 | Vallado 2-5 position | Vallado 2-5 semi-major axis | length of the Vallado 2-5 velocity | 1·10⁻⁸ |
| Vallado Ex. 2-6 | Vallado 2-6 position | Vallado 2-6 semi-major axis | length of the Vallado 2-6 velocity | 1·10⁻⁸ |

The errors measured while drafting were 2.9·10⁻⁹ km/s on both rows. They are the cost of the Vallado μ (Definitions): with it, the same rows measured 0.0 and 8.9·10⁻¹⁶ km/s. The tolerance bounds that documented cost, which is 3.8·10⁻¹⁰ of the speed, with a margin of about three times. These rows are consistency rows and not an independent check of the model (Context); REQ-ORB-008.2 carries that check.

### REQ-ORB-008.2 — Speed identities and agreement with the state vector

The speed is the circular speed at r = a, is exactly 0.0 at r = 2a, and agrees with the velocity of the state vector of req-orb-005 over a grid.

**Acceptance (verified by the math test file).**

- **Circular.** For a in {6778.137, 7000.0, 42164.17} km, the position (a, 0.0, 0.0) gives a speed relatively close to within 1·10⁻¹³ of sqrt(398600.4418 / a), with μ written as a literal number in the math test file. The error measured at a = 7000.0 was 1.3·10⁻¹⁶ relative.
- **Twice the axis.** The positions (14000.0, 0.0, 0.0), (0.0, −14000.0, 0.0) and (0.0, 0.0, 14000.0) with a = 7000.0 give exactly 0.0.
- **Grid.** For every combination, 168 in total, of the semi-major axis in {6778.0, 26560.4, 42164.17, 1·10⁶} km, the eccentricity in {0.0, 0.001, 0.1, 0.5, 0.9, 0.99} and the eccentric anomaly in {0.0, 1.0, π / 2, 3.0, π, 4.0, 6.0} rad, with the inclination 0.5 rad, the ascending node 1.0 rad and the argument of perigee 2.0 rad, `inertialStateVector` of req-orb-005 gives a state. The speed at its position and the given axis is relatively close to within 1·10⁻¹² of the length of its velocity.

The largest error measured on the grid was 1.6·10⁻¹⁴ relative. The grid reaches apoapsis at e = 0.99, where 2 / r − 1 / a nearly cancels.

### REQ-ORB-008.3 — Period against the WGS-84 angular velocity and the sidereal day

The period at the angular velocity of the Earth is a sidereal day, and the formula is consistent with Kepler's third law.

**Acceptance (verified by the math test file).** "Period" is the result of `orbitalPeriodSFromMeanMotion` (REQ-ORB-008.6).

- **Published.** The period at the mean motion ω (Definitions) is close to within 0.02 s of the sidereal day (86164.0905 s) and close to within 0.5 s of the Kelso sidereal day (86164 s). The period measured was 86164.10063718943 s, which is 0.0101 s from the first and 0.1006 s from the second. The 0.0101 s is the cost of ω being a nominal rate and not the sidereal one, and the 0.1006 s is within the second to which Kelso rounds. The tolerances are not a measure of the formula (Context, Weak anchor).
- **Identities.** The period at 1.0 rad/s is exactly `2 * pi`. The period at the mean motion `2 * pi / 86400` is close to within 1·10⁻⁹ s of 86400 s (the measured error was 0.0).
- **Third law.** For each mean motion n in {7.2921159·10⁻⁵, 1.1·10⁻³, 1.65·10⁻³, 9·10⁻⁴, 7.27·10⁻¹³} rad/s, with a the result of `semiMajorAxisKmFromMeanMotion` of req-orb-005 at n and T the result of the period function, T² is relatively close to within 1·10⁻¹³ of 4π² · a³ / 398600.4418, with μ written as a literal number in the math test file. The last value is about the smallest mean motion that a TLE can carry (req-orb-005). The largest error measured was 4.0·10⁻¹⁵ relative.

### REQ-ORB-008.4 — Inclination against published and fixed states

The inclination of the published states is the published inclination, the fixed states give the fixed angles, and the inclination of a state built by req-orb-005 is the inclination it was built with.

**Acceptance (verified by the math test file).** "Inclination" is the result of `inclinationRadFromState` (REQ-ORB-008.6). The angles π / 2, π / 4 and π are `pi / 2`, `pi / 4` and `pi`; "0.0" is `0.0`.

- **Published.**
  - The state made of the Vallado 2-5 position and velocity gives an inclination close to within 1·10⁻¹² rad of the Vallado 2-5 inclination.
  - The state made of the Vallado 2-6 position and velocity gives an inclination close to within 1·10⁻¹² rad of the Vallado 2-6 inclination.
  - The errors measured were 0.0 rad on both rows.
- **Fixed states.** The position is the first column and the velocity the second.

  | Position (km) | Velocity (km/s) | Inclination | Compared |
  | --- | --- | --- | --- |
  | (7000.0, 0.0, 0.0) | (0.0, 7.5, 0.0) | 0.0 | exact |
  | (7000.0, −0.0, 0.0) | (−0.0, 7.5, 0.0) | 0.0 | exact |
  | (7000.0, 0.0, 0.0) | (0.0, −7.5, 0.0) | π | exact |
  | (7000.0, 0.0, 0.0) | (0.0, 0.0, 7.5) | π / 2 | exact |
  | (7000.0, 0.0, 0.0) | (0.0, 5.0, 5.0) | π / 4 | close to within 1·10⁻¹⁵ |

- **Rotation about the z axis.** Rotating the Vallado 2-5 position and velocity by θ = 1.0 rad about the z axis (Definitions) leaves the inclination close to within 1·10⁻¹⁴ rad of the unrotated one. The measured difference was 0.0.
- **Round trip.** For every combination, 144 in total, of the inclination in {0.0, 1·10⁻⁶, 0.5, 0.9, π / 2, 2.0, π − 1·10⁻⁶, π} rad, the ascending node in {0.0, 1.0, 4.0} rad, the argument of perigee in {0.0, 2.0} rad and the eccentric anomaly in {0.0, 1.0, 3.0} rad, with a = 7000.0 km and e = 0.01, `inertialStateVector` gives a state whose inclination is close to within 1·10⁻¹⁴ rad of the given inclination. The largest error measured was 2.2·10⁻¹⁶ rad. The acos form measured 4.4·10⁻¹¹ rad at 1·10⁻⁶ rad, so this row fails it.

### REQ-ORB-008.5 — Input validation with exact messages

Each function accepts only the inputs below. Any other input throws Dart's `ArgumentError` and returns no value. No message contains an apostrophe, so each can be written in the derived library file as a plain single-quoted string. "Finite" means neither NaN nor positive or negative infinity.

**Speed.** Checks run in this order and the first failure wins:

1. the three components of the position are finite, otherwise message P;
2. the semi-major axis is finite and greater than 0, otherwise message A;
3. |position| differs from 0.0, otherwise message O. A component so small that its square underflows counts as zero here;
4. 2 / |position| − 1 / semi-major axis is not negative, otherwise message R. This is the condition that |position| is at most twice the semi-major axis, written so that it holds without computing twice the axis, which overflows for an axis above 8.9·10³⁰⁷. A component so large that its square overflows makes |position| infinite, so 2 / |position| is 0.0 and the check fails here. Within a few units in the last place of twice the axis the outcome depends on rounding, and the rows below pin only the exact value. Measured with an axis of 7000.0 km: the position 14000.0 and the one just below it give 0.0, the position one unit in the last place above 14000.0 throws message R, and the position two units in the last place below 14000.0 gives about 1.0·10⁻⁷ km/s, because 2 / |position| − 1 / semi-major axis nearly cancels there.

- **Message P:** `Orbital speed requires a finite position.`
- **Message A:** `Orbital speed requires a finite semi-major axis greater than 0.`
- **Message O:** `Orbital speed requires a position away from the origin.`
- **Message R:** `Orbital speed requires a position within twice the semi-major axis.`

**Period.** The mean motion is finite and greater than 0, otherwise message N.

- **Message N:** `Orbital period requires a finite mean motion greater than 0.`

**Inclination.** Checks run in this order and the first failure wins:

1. the six components of the position and the velocity are finite, otherwise message F;
2. at least one component of h = r × v differs from 0.0, otherwise message H. Components of h that underflow count as zero here.

- **Message F:** `Inclination requires a finite state vector.`
- **Message H:** `Inclination requires a nonzero angular momentum.`

**Acceptance (verified by the math test file).**

- "Throws X" means the thrown object is an `ArgumentError` whose message is equal to message X, character for character.
- "Accepted" means the function returns without throwing and the result is finite. For the speed it is also at least 0.0, for the period greater than 0.0, and for the inclination from 0.0 to π, both included.

| Function | Input | Expected |
| --- | --- | --- |
| speed | position (NaN, 2000.0, 3000.0), axis 7000.0 | Throws P |
| speed | position (1000.0, positive infinity, 3000.0), axis 7000.0 | Throws P |
| speed | position (1000.0, 2000.0, negative infinity), axis 7000.0 | Throws P |
| speed | position (NaN, 0.0, 0.0), axis NaN | Throws P |
| speed | position (7000.0, 0.0, 0.0), axis NaN | Throws A |
| speed | position (7000.0, 0.0, 0.0), axis positive infinity | Throws A |
| speed | position (7000.0, 0.0, 0.0), axis 0.0 | Throws A |
| speed | position (7000.0, 0.0, 0.0), axis −0.0 | Throws A |
| speed | position (7000.0, 0.0, 0.0), axis −7000.0 | Throws A |
| speed | position (0.0, 0.0, 0.0), axis 0.0 | Throws A |
| speed | position (0.0, 0.0, 0.0), axis 7000.0 | Throws O |
| speed | position (−0.0, 0.0, −0.0), axis 7000.0 | Throws O |
| speed | position (1·10⁻²⁰⁰, 0.0, 0.0), axis 7000.0 | Throws O |
| speed | position (14001.0, 0.0, 0.0), axis 7000.0 | Throws R |
| speed | position (1·10²⁰⁰, 0.0, 0.0), axis 7000.0 | Throws R |
| speed | position (1·10²⁰⁰, 0.0, 0.0), axis 1·10³⁰⁸ | Throws R |
| speed | position (7000.0, 0.0, 0.0), axis 7000.0 | Accepted |
| speed | position (14000.0, 0.0, 0.0), axis 7000.0 | Accepted |
| speed | position (1·10⁻¹⁰⁰, 0.0, 0.0), axis 7000.0 | Accepted |
| period | mean motion NaN | Throws N |
| period | mean motion positive infinity | Throws N |
| period | mean motion negative infinity | Throws N |
| period | mean motion 0.0 | Throws N |
| period | mean motion −0.0 | Throws N |
| period | mean motion −1·10⁻³ | Throws N |
| period | mean motion 7.27·10⁻¹³ | Accepted |
| period | mean motion 1·10⁻³ | Accepted |
| inclination | position (NaN, 0.0, 0.0), velocity (0.0, 7.5, 0.0) | Throws F |
| inclination | position (7000.0, positive infinity, 0.0), velocity (0.0, 7.5, 0.0) | Throws F |
| inclination | position (7000.0, 0.0, 0.0), velocity (0.0, NaN, 0.0) | Throws F |
| inclination | position (7000.0, 0.0, 0.0), velocity (0.0, 0.0, negative infinity) | Throws F |
| inclination | position (NaN, 0.0, 0.0), velocity (0.0, 0.0, 0.0) | Throws F |
| inclination | position (0.0, 0.0, 0.0), velocity (0.0, 7.5, 0.0) | Throws H |
| inclination | position (7000.0, 0.0, 0.0), velocity (0.0, 0.0, 0.0) | Throws H |
| inclination | position (7000.0, 0.0, 0.0), velocity (−0.0, 0.0, −0.0) | Throws H |
| inclination | position (7000.0, 0.0, 0.0), velocity (7.5, 0.0, 0.0) | Throws H |
| inclination | position (7000.0, 0.0, 0.0), velocity (−3.0, 0.0, 0.0) | Throws H |
| inclination | position (1·10⁻²⁰⁰, 0.0, 0.0), velocity (0.0, 1·10⁻²⁰⁰, 0.0) | Throws H |
| inclination | position (7000.0, 0.0, 0.0), velocity (0.0, 7.5, 0.0) | Accepted |
| inclination | position (7000.0, 0.0, 0.0), velocity (0.0, 1·10⁻³, 0.0) | Accepted |

### REQ-ORB-008.6 — Placement, public names and documented contract

The three functions live in the derived library file and are reachable through the public library file. The documentation states the model, the frame, the ranges, the units and the reference of each, so a reader of the package learns them without opening this spec. The file reuses the gravitational parameter of req-orb-005 and declares no constant of its own.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The derived library file exists.
- The public library file contains the line `export 'src/derived_values.dart';`.
- The derived library file contains the lines `import 'dart:math';`, `import 'perifocal.dart';` and `import 'state_vector.dart';`.
- **Reuse of μ.** No line of the derived library file whose text, with leading spaces removed, does not start with `//` contains the substring `398600`, and at least one such line contains the substring `wgs84MuKm3S2`. So the gravitational parameter is read from `wgs84MuKm3S2`, never copied (ADR-0003, Amendment 1, decision 5). The guard cannot prove that the value is used in the formula; the math test file proves the value (REQ-ORB-008.2, Circular).
- **Doc blocks.** The doc block of a declaration is the run of consecutive lines directly before its declaration line whose text, with leading and trailing spaces removed, starts with `///`. It contains each of the lines listed for it below, in any order.
  - Before the line `double visVivaSpeedKmS({`:
    - `/// Model: vis-viva, v = sqrt(mu (2 / r - 1 / a)), with mu = wgs84MuKm3S2 = 398600.4418 km^3/s^2.`
    - `/// Position: only its length r is used, so it may be in any frame.`
    - `/// Speed: relative to the inertial frame of the elements, not relative to the rotating Earth.`
    - `/// Semi-major axis: the one of the element set, from the Kozai mean motion, as semiMajorAxisKmFromMeanMotion gives it.`
    - `/// Units: km and km/s.`
    - `/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and semi-major axis), CelesTrak fundamentals-of-astrodynamics test suite.`
  - Before the line `double orbitalPeriodSFromMeanMotion(double meanMotionRadS) {`:
    - `/// Model: T = 2 pi / n, the time of one revolution at the mean motion n.`
    - `/// Mean motion: the Kozai mean motion of the element set, used as is.`
    - `/// Units: radians per second in, seconds out.`
    - `/// Reference: WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s (DMA TR8350.2); sidereal day, 86164.0905 s.`
  - Before the line `double inclinationRadFromState({required StateVector inertialState}) {`:
    - `/// Model: i = atan2(sqrt(hx^2 + hy^2), hz), with h = r x v the specific angular momentum.`
    - `/// Input frame: the inertial frame of the state vector, such as TEME; an Earth-fixed state gives no inclination.`
    - `/// Inclination: osculating, from 0 to pi; 0 for a prograde equatorial orbit and pi for a retrograde one.`
    - `/// Ignored: the mean inclination of the element set, which OrbitalElements.inclinationRad holds.`
    - `/// Units: km, km/s and radians.`
    - `/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and inclination), CelesTrak fundamentals-of-astrodynamics test suite.`
- **Public names.** The derived library file contains the lines `double visVivaSpeedKmS({`, `double orbitalPeriodSFromMeanMotion(double meanMotionRadS) {` and `double inclinationRadFromState({required StateVector inertialState}) {`, each compared after trimming. These names are the contract that later specs read. `dart format` splits the first declaration because it does not fit within 80 columns, and keeps the other two on one line.
- **Parameters of the speed.** The line directly after `double visVivaSpeedKmS({` is `required CartesianVector positionKm,`, the line after it is `required double semiMajorAxisKm,` and the line after that is `}) {`, each equal after trimming.
- **Top-level declarations.** Every line of the derived library file that has a character other than a space at its first column, compared with no spaces removed, starts with `//`, starts with `import '`, or is equal to one of the three public declaration lines above, `}) {` and `}`. Empty lines are allowed. `dart format` writes every top-level declaration at the first column and every line inside a declaration indented, so the file declares no other top-level name, public or private, and in particular no constant. Local variables inside the functions, `const` ones included, are indented and stay allowed.

**Acceptance (verified by command V11).** Compared with `main`, this pull request adds or changes exactly four files and no other: the public library file, the derived library file, the math test file and the guard test file. This enforces the file list of Out of Scope by machine.

### REQ-ORB-008.7 — Purity, citations and test hygiene

The new code adds no dependency, every published value is cited in the math test file, the tests do not borrow the constants they check, and the new files follow the hygiene rules of req-orb-006 and req-orb-007.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file does not contain the substring `wgs84`, compared case-sensitively as Dart identifiers are, so that its expected values use literal numbers for μ and for ω, and a wrong constant in the library fails its rows.
- The math test file contains each of these five citation lines, compared after trimming:
  - `// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.`
  - `// Vallado repository, twobody test_frame_conversions.py, test_rv2coe (Example 2-5) and test_coe2rv (Example 2-6): position, velocity, semi-major axis and inclination, computed with MU = 398600.4415 km^3/s^2.`
  - `// WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s: DMA Technical Report 8350.2 (1991), as quoted at https://en.wikipedia.org/wiki/World_Geodetic_System.`
  - `// Sidereal day, 86164.0905 s: https://en.wikipedia.org/wiki/Sidereal_time.`
  - `// Kelso, Basics of the Geostationary Orbit, Satellite Times, May 1998: https://celestrak.org/columns/v04n07/, one sidereal day is 23h56m04s.`
- The math test file contains, for each N from 1 to 5, a line equal to `// REQ-ORB-008.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
- The guard test file contains, for each N in {6, 7}, a line equal to `// REQ-ORB-008.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
- The guard test file builds the tag strings of the math test file (`// REQ-ORB-008.1` to `.5`) by interpolation, never as literals, so that V10 prints only its own tags.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the guard test file, the core library files and the spec file.
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser. `dart:io` never appears in `packages/orbital_core`, which the two regular expressions above enforce.
- Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, the derived library file, the public library file, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-008.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-008.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-008.7, which the guard test file checks (Constitution principle 6). The sources are:

- **Speed (REQ-ORB-008.1):** the position, velocity and semi-major axis of Vallado Examples 2-5 and 2-6, published by the CelesTrak repository.
- **Inclination (REQ-ORB-008.4):** the inclination of the same two examples.
- **Period (REQ-ORB-008.3):** the WGS-84 angular velocity of the Earth, the sidereal day and the sidereal day of Kelso, compared within the precision of their sources. Context records that this anchor is weak.
- **Identities and grids (REQ-ORB-008.2 to .4):** the circular speed, the vis-viva zero at r = 2a, Kepler's third law and the state vector of req-orb-005. They add no formula to the library.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `wc` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/derived_values_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-008.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-006 still pass |
| V4 | `flutter test test/orbital_core_derived_values_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-008.6, .7 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-008.7 |
| V6 | `flutter test` | exit 0 | REQ-ORB-008.6, .7; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-008\.[0-9]+" packages/orbital_core/test/derived_values_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-008.1,// REQ-ORB-008.2,// REQ-ORB-008.3,// REQ-ORB-008.4,// REQ-ORB-008.5` | REQ-ORB-008.7 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-008\.[0-9]+" test/orbital_core_derived_values_guard_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-008.6,// REQ-ORB-008.7` | REQ-ORB-008.7 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --name-only origin/main...HEAD \| sort \| paste -sd, -` | standard output `packages/orbital_core/lib/orbital_core.dart,packages/orbital_core/lib/src/derived_values.dart,packages/orbital_core/test/derived_values_test.dart,test/orbital_core_derived_values_guard_test.dart` | REQ-ORB-008.6 (only the four files of this spec change) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after every file of this pull request is committed on the feature branch, so that the revert below restores each of them. Before G0, `git status --porcelain` must print nothing; otherwise stop, because G22, G54, G55 and the revert would destroy uncommitted work.

The command is:

    flutter test test/orbital_core_derived_values_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-008.md"

**Control run (G0).** With no edit applied, run the command once with `<tag>` replaced by `[REQ-ORB-008.6]` and once with `[REQ-ORB-008.7]`, and confirm that each prints nothing. A line printed here means that the output of a passing run, such as a test name, already carries a tag and the spec path, so the rows below would prove nothing; fix the guard test file before continuing.

Then, for each row of the table:

1. Apply the edit.
2. Run the command and confirm that it prints at least one line. That line carries both the expected tag and the spec path.
3. Revert with `git checkout -- packages/orbital_core test specs` before the next row.

"Delete the line X" and "Replace the line X" act on every line that equals X after trimming. "Replace every occurrence" acts on every occurrence of the substring. Inside the table, `\|` is a single pipe. "The derived library file", "the math test file" and "the guard test file" are the files of Definitions.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the derived library file | `[REQ-ORB-008.7]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the derived library file | `[REQ-ORB-008.7]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the derived library file | `[REQ-ORB-008.7]` |
| G4 | Add `import 'dart:ffi';` as the first line of the derived library file | `[REQ-ORB-008.7]` |
| G5 | Delete the line `/// Model: vis-viva, v = sqrt(mu (2 / r - 1 / a)), with mu = wgs84MuKm3S2 = 398600.4418 km^3/s^2.` from the derived library file | `[REQ-ORB-008.6]` |
| G6 | Delete the line `/// Position: only its length r is used, so it may be in any frame.` from the derived library file | `[REQ-ORB-008.6]` |
| G7 | Delete the line `/// Speed: relative to the inertial frame of the elements, not relative to the rotating Earth.` from the derived library file | `[REQ-ORB-008.6]` |
| G8 | Delete the line `/// Semi-major axis: the one of the element set, from the Kozai mean motion, as semiMajorAxisKmFromMeanMotion gives it.` from the derived library file | `[REQ-ORB-008.6]` |
| G9 | Delete the line `/// Units: km and km/s.` from the derived library file | `[REQ-ORB-008.6]` |
| G10 | Delete the line `/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and semi-major axis), CelesTrak fundamentals-of-astrodynamics test suite.` from the derived library file | `[REQ-ORB-008.6]` |
| G11 | Delete the line `/// Model: T = 2 pi / n, the time of one revolution at the mean motion n.` from the derived library file | `[REQ-ORB-008.6]` |
| G12 | Delete the line `/// Mean motion: the Kozai mean motion of the element set, used as is.` from the derived library file | `[REQ-ORB-008.6]` |
| G13 | Delete the line `/// Units: radians per second in, seconds out.` from the derived library file | `[REQ-ORB-008.6]` |
| G14 | Delete the line `/// Reference: WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s (DMA TR8350.2); sidereal day, 86164.0905 s.` from the derived library file | `[REQ-ORB-008.6]` |
| G15 | Delete the line `/// Model: i = atan2(sqrt(hx^2 + hy^2), hz), with h = r x v the specific angular momentum.` from the derived library file | `[REQ-ORB-008.6]` |
| G16 | Delete the line `/// Input frame: the inertial frame of the state vector, such as TEME; an Earth-fixed state gives no inclination.` from the derived library file | `[REQ-ORB-008.6]` |
| G17 | Delete the line `/// Inclination: osculating, from 0 to pi; 0 for a prograde equatorial orbit and pi for a retrograde one.` from the derived library file | `[REQ-ORB-008.6]` |
| G18 | Delete the line `/// Ignored: the mean inclination of the element set, which OrbitalElements.inclinationRad holds.` from the derived library file | `[REQ-ORB-008.6]` |
| G19 | Delete the line `/// Units: km, km/s and radians.` from the derived library file | `[REQ-ORB-008.6]` |
| G20 | Delete the line `/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and inclination), CelesTrak fundamentals-of-astrodynamics test suite.` from the derived library file | `[REQ-ORB-008.6]` |
| G21 | Delete the line `export 'src/derived_values.dart';` from the public library file | `[REQ-ORB-008.6]` |
| G22 | Delete the file `packages/orbital_core/lib/src/derived_values.dart` | `[REQ-ORB-008.6]` |
| G23 | Replace every occurrence of `double visVivaSpeedKmS(` with `double speedKmS(` in the derived library file | `[REQ-ORB-008.6]` |
| G24 | Replace every occurrence of `double orbitalPeriodSFromMeanMotion(` with `double periodS(` in the derived library file | `[REQ-ORB-008.6]` |
| G25 | Replace every occurrence of `double inclinationRadFromState(` with `double inclinationRad(` in the derived library file | `[REQ-ORB-008.6]` |
| G26 | Replace the line `required CartesianVector positionKm,` with `required CartesianVector position,` in the derived library file | `[REQ-ORB-008.6]` |
| G27 | Replace the line `required double semiMajorAxisKm,` with `required double semiMajorAxis,` in the derived library file | `[REQ-ORB-008.6]` |
| G28 | Insert the line `required double extraKm,` directly after the line `required double semiMajorAxisKm,` in the derived library file | `[REQ-ORB-008.6]` |
| G29 | Replace the line `double orbitalPeriodSFromMeanMotion(double meanMotionRadS) {` with `double orbitalPeriodSFromMeanMotion(double meanMotion) {` in the derived library file | `[REQ-ORB-008.6]` |
| G30 | Replace the line `double inclinationRadFromState({required StateVector inertialState}) {` with `double inclinationRadFromState({required StateVector state}) {` in the derived library file | `[REQ-ORB-008.6]` |
| G31 | Append the line `double _extra() => 1.0;` to the derived library file | `[REQ-ORB-008.6]` |
| G32 | Append the line `const double _mu = 398600.4418;` to the derived library file | `[REQ-ORB-008.6]` |
| G33 | Append the line `  final double _m = 398600.4418;` (indented by two spaces) to the derived library file | `[REQ-ORB-008.6]` |
| G34 | Delete the line `import 'perifocal.dart';` from the derived library file | `[REQ-ORB-008.6]` |
| G35 | Delete the line `/// Units: km and km/s.` from the derived library file and insert it as the first line of the same file | `[REQ-ORB-008.6]` |
| G36 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-008.7]` |
| G37 | Add `import 'package:orbital_core/src/derived_values.dart';` to the math test file | `[REQ-ORB-008.7]` |
| G38 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-008.7]` |
| G39 | Replace the line `// REQ-ORB-008.2` with `// REQ-ORB-008.x`, keeping its indentation, in the math test file | `[REQ-ORB-008.7]` |
| G40 | Insert the line `// note` directly after the line `// REQ-ORB-008.1` in the math test file | `[REQ-ORB-008.7]` |
| G41 | Delete the citation line that starts with `// Vallado repository: https://` from the math test file | `[REQ-ORB-008.7]` |
| G42 | Delete the citation line that starts with `// Vallado repository, twobody` from the math test file | `[REQ-ORB-008.7]` |
| G43 | Delete the citation line that starts with `// WGS 84 angular velocity of the Earth` from the math test file | `[REQ-ORB-008.7]` |
| G44 | Delete the citation line that starts with `// Sidereal day, 86164.0905 s` from the math test file | `[REQ-ORB-008.7]` |
| G45 | Delete the citation line that starts with `// Kelso, Basics of the Geostationary Orbit` from the math test file | `[REQ-ORB-008.7]` |
| G46 | Append the line `// skip: true` to the math test file | `[REQ-ORB-008.7]` |
| G47 | Run `sed -i 's/$/\r/' packages/orbital_core/test/derived_values_test.dart` (CRLF) | `[REQ-ORB-008.7]` |
| G48 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/derived_values_test.dart > /tmp/g48 && mv /tmp/g48 packages/orbital_core/test/derived_values_test.dart` (BOM) | `[REQ-ORB-008.7]` |
| G49 | Run `sed -i 's/$/\r/' specs/req-orb-008.md` (CRLF in the spec file) | `[REQ-ORB-008.7]` |
| G50 | Run `printf '\xEF\xBB\xBF' \| cat - specs/req-orb-008.md > /tmp/g50 && mv /tmp/g50 specs/req-orb-008.md` (BOM in the spec file) | `[REQ-ORB-008.7]` |
| G51 | Run `sed -i 's/$/\r/' packages/orbital_core/lib/src/derived_values.dart` (CRLF in a core library file) | `[REQ-ORB-008.7]` |
| G52 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-008.7]` |
| G53 | Replace the line `// REQ-ORB-008.6` with `// REQ-ORB-008.x`, keeping its indentation, in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-ORB-008.7]` |
| G54 | Delete the file `packages/orbital_core/test/derived_values_test.dart` | `[REQ-ORB-008.7]` |
| G55 | Delete the file `packages/orbital_core/lib/orbital_core.dart` | `[REQ-ORB-008.6]` |
| G56 | Append the line `// wgs84MuKm3S2` to the math test file | `[REQ-ORB-008.7]` |
| G57 | Replace every occurrence of the substring `wgs84MuKm3S2` with `muKm3S2` on the lines of the derived library file that do not start with `//` after trimming | `[REQ-ORB-008.6]` |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V11 and G0–G57, each with its observed result. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **Speed is inertial.** The vis-viva speed is relative to the inertial frame of the elements. The speed of the same object relative to the rotating Earth differs by ω × r, which is about 0.465 km/s on the equator of the surface (ω from Definitions, 6378.137 km) and about 3.07 km/s at the radius of a geostationary orbit (42164 km), where it is almost the whole inertial speed. The card shows the inertial speed, as req-orb-006 records, so GEO-East shows about 3.07 km/s although it hardly moves over the ground; an Earth-relative speed is Out of Scope.
- **Mean elements and osculating positions.** The semi-major axis comes from the Kozai mean motion, and an SGP4 position is not a Kepler position of that axis. The vis-viva speed of the two is therefore an estimate of the SGP4 velocity, and this spec makes no claim about how close. The comparison belongs to req-orb-010, which wraps SGP4.
- **Two gravitational parameters.** The speed uses the WGS-84 value of req-orb-005 (ADR-0003, Amendment 1). SGP4 uses the WGS-72 value of its own gravity model, which differs slightly. This spec does not quantify the difference, which only matters when the speed of an SGP4 object is compared with SGP4's own velocity (req-orb-010).
- **Apoapsis of a very eccentric orbit.** 2 / r − 1 / a nearly cancels there, so the relative error of the speed grows as e approaches 1 (REQ-ORB-008.2). The largest TLE eccentricity is below 1, so r stays below 2a for any consistent element set and message R is never raised for one. Message R reports a position and an axis that do not belong to the same orbit.
- **Overflow and underflow of the position.** Squaring a component overflows above about 1.3·10¹⁵⁴ km and underflows below about 1·10⁻¹⁶² km. The first fails with message R and the second with message O (REQ-ORB-008.5). No tracked object is near either.
- **Overflow of the period.** For a mean motion below about 3.5·10⁻³⁰⁸ rad/s, 2π / n overflows to infinity. The smallest mean motion of a TLE is 7.27·10⁻¹³ rad/s, which gives a period of 8.6·10¹² s (REQ-ORB-008.3), so this spec does not check the overflow.
- **Zero angular momentum.** A zero velocity, a velocity along the position and a zero position give no orbital plane, so no inclination, and throw message H. An object falling straight to the centre is not a tracked object.
- **Error output of a propagator.** Some SGP4 implementations report a failure, such as a decayed object, by returning a zero or NaN state. Passed here, a zero position throws message O or H and a NaN throws message P or F on the frame path. This spec only records the risk and fixes nothing about it: how propagation failures are reported and who handles them belongs to ADR-0002, which chooses the library, and to req-orb-010, which wraps it.
- **Inclination of an Earth-fixed state.** The inclination of a state in rotating axes has no orbital meaning. The function cannot tell the frames apart, so the documentation states the frame (REQ-ORB-008.6) and the caller passes an inertial state.
- **Mean versus osculating inclination.** The inclination of a state differs from the mean inclination of the element set that produced it. For two-body states built by req-orb-005 they are equal (REQ-ORB-008.4). For SGP4 they differ slightly, and the card shows the osculating one.
- **Signed zeros.** −0.0 in a position or velocity component gives the same results as 0.0 (REQ-ORB-008.4 and .5). A zero speed at r = 2a is 0.0 (REQ-ORB-008.2).
- **Rounding of π.** The inclination of a polar orbit is `pi / 2` exactly for the listed state, because atan2 with a zero second argument returns it. Other polar states are compared with a tolerance, never with `==`.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-008.7). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Declarations split by the formatter.** The speed declaration does not fit within 80 columns, so `dart format` splits it, which the guard fixes. The other two fit on one line. The top-level rule of REQ-ORB-008.6 relies on the same formatter, which writes every top-level declaration at the first column. If a future formatter changes that layout, the guard reports `[REQ-ORB-008.6]`. The fix is a spec change, never a relaxed guard.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access at run time. V11 needs `git fetch` and is a local check; if the fetch fails, V11 counts as not run, never as a pass. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.

## Out of Scope

Nothing below is written in this pull request:

- The altitude, in any form. It is defined by req-orb-007 and is not computed again (Context).
- A function or type that joins speed, period and inclination, a function that takes an element set, an instant or a Julian date, the propagator interface and a propagated state (req-orb-009).
- A speed relative to the Earth, the rotation rate of the Earth as a constant, and any Earth-relative velocity.
- The mean inclination of the element set, and any change to `OrbitalElements`. The card may read `OrbitalElements.inclinationRad` directly; this spec neither forbids nor adds it.
- Any other classical element from a state vector (eccentricity, ascending node, argument of perigee, anomalies), the semi-major axis from a state vector, apoapsis, periapsis and the period from a semi-major axis.
- The conversion of the Kozai mean motion to the Brouwer one (ADR-0005, Out of scope) and any WGS-72 constant of SGP4 (req-orb-010).
- Degrees, revolutions per day, minutes, sexagesimal formatting, value formatting of any kind, or any UI string.
- Any top-level constant, public or private, in the derived library file. A `const` local variable inside a function is allowed (REQ-ORB-008.6). The gravitational parameter is the one of req-orb-005 (REQ-ORB-008.6).
- Any change to `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart`, `kepler.dart`, `perifocal.dart`, `state_vector.dart`, `earth_fixed.dart` or `geodetic.dart`, or to their tests and guards.
- Copying code from the Vallado repository; only its published values are cited.
- Any code in the application `lib/`, any provider or widget.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
