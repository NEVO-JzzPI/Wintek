# req-orb-007 — ECEF to WGS-84 geodetic

- **Status:** Ready for implementation (revision 3, after the first QA audit: findings 1.1 to 1.4, 2.1, 3.1 to 3.3, 4.2 and 5.1 to 5.3; and the second: findings 1.1 and 3.1, with finding 2.1 fixed in ADR-0003). The developer approved the model, the reference sources, the input domain and the form of the public contract on 2026-11-07, before drafting, and the revision 2 changes, Amendment 2 of ADR-0003 and the edit of roadmap row 10 (req-orb-008) on the same day. Every published value was checked against a freely available source while drafting (see Definitions), and every measured figure below was measured in Dart with a throwaway prototype of this contract, which is not part of the repository.
- **Roadmap row:** 9 of 33 (MVP)
- **Blocks:** req-orb-008 (reads the altitude defined here), req-ui-003 (the object card shows latitude, longitude and altitude)
- **Depends on:** req-orb-001 (UTC read as UT1, inherited through the Earth-fixed position), req-orb-003 (an element set has an eccentricity below 1), req-orb-005 (`CartesianVector`), req-orb-006 (the Earth-fixed position and its frame), req-inf-002 (CI quality gates), ADR-0001 (baseline packages), ADR-0003 Amendment 2 (the WGS-84 ellipsoid constants)
- **ADR:** ADR-0003 Amendment 2 (accepted by the developer on 2026-11-07, before implementation) assigns the two WGS-84 ellipsoid constants to this spec, under names that state their model, and makes later specs reuse them. No other ADR is needed. The work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`, so ADR-0001 is unchanged. Every formula is checked against a published value, so no exception to Constitution principle 6 is needed. The sources are read only while developing, so no data source is added at run time (Constitution principle 1). The Vallado repository is licensed under AGPL-3.0; this spec and its tests cite published numbers only, and copy no code from it.

## Context & Objective

req-orb-006 delivers the position of an object in Earth-fixed axes, in kilometres. The numbers that the globe and the object card display are a latitude, a longitude and an altitude, and nothing yet derives them. This spec delivers what roadmap row 9 names, as step 8 of the Project Brief's pipeline fixes it: the conversion of the Earth-fixed position to geodetic coordinates on the WGS-84 ellipsoid.

The decisions below are fixed so later specs inherit them. The developer approved the first four before drafting.

- **Latitude model.** Two fixed passes of the closed form published in IOGP 373-7-2, section 4.1.1, which the note offers to avoid iteration. The first pass starts from q = atan2(z·a, p·b). Each pass computes φ = atan2(z + ε·b·sin³q, p − e²·a·cos³q). The second pass starts from the reduced latitude of the first result, q = atan2((1 − f)·sin φ, cos φ). The number of passes is fixed: there is no iteration until a tolerance is met, so the cost of a call is constant on the frame path. Over the outer grid of REQ-ORB-007.4 with altitudes from 100 km up, the largest latitude errors measured were 5.7·10⁻⁹ rad after one pass, 1.1·10⁻¹⁶ rad after two and 2.2·10⁻¹⁶ rad after three. Two passes are the first that reach rounding.
- **Algorithm 12 of Vallado is not used.** The method behind the published `ecef2ll` computes the height as z / sin φ − ν(1 − e²) away from the poles. In Dart this measured NaN at (42164.0, 0.0, 0.0), the exact equator, and an altitude error of 43 m at a latitude of 1·10⁻⁶ degrees and an altitude of 35786 km. A geostationary object orbits in that region. Its published values remain a reference (REQ-ORB-007.2), because they describe the same geometry.
- **Reference sources.** Two published rows anchor the conversion. IOGP 373-7-2 publishes a WGS-84 example near the surface. The Vallado repository publishes an example at about 5085 km of altitude, on a radius that differs from WGS-84 by 0.7 m. Neither row alone is enough: the first does not reach orbital altitude, and the second would not notice a wrong radius.
- **Input domain.** Every finite position is accepted, except the origin, which has no latitude. A position below the ellipsoid gets a negative altitude. No element set propagated by Kepler reaches the origin, because the eccentricity of an element set is below 1 (req-orb-003); the error output of SGP4 is a separate case (Edge Cases).

The remaining decisions follow from the Constitution and the existing specs.

- **Altitude.** The altitude is the height above the ellipsoid, computed as h = p·cos φ + z·sin φ − a²/ν. This is an identity of the forward formulas of IOGP 373-7-2: with p = (ν + h)·cos φ and z = (ν(1 − e²) + h)·sin φ, the sum p·cos φ + z·sin φ equals h + ν(1 − e²·sin²φ), and ν²(1 − e²·sin²φ) = a². It has no branch and no division by a value that can vanish. The published alternative h = p / cos φ − ν measured −6399.59 km at the exact pole above (0.0, 0.0, 7000.0), where the true altitude is 643.25 km.
- **One altitude.** The altitude of the object card is the value defined here. Roadmap row 10 (req-orb-008) states that its altitude comes from req-orb-007, so that spec reads this value and does not define a second one.
- **Longitude range.** Longitude is greater than −π and at most π, so each meridian has one value. `atan2` can return exactly −π, for y = −0.0 or a very small negative y with a negative x, and that result is returned as π. On the z axis (x and y both zero) longitude is undefined and is 0.0 by convention, including when x is −0.0, where `atan2` alone would return π. Vallado's convention of ±π/2 on the axis is not copied.
- **Radians and km.** The output is in radians and kilometres (Constitution principle 12). Converting to degrees for display is a job of the UI specs.
- **Input frame.** The input is the Earth-fixed position of req-orb-006: axes without polar motion (PEF), used as ECEF. Its difference from the ITRF, and the reading of UTC as UT1, are inherited (Edge Cases).
- **New value type.** The output is a new immutable value type with exactly three fields. `CartesianVector` of req-orb-005 cannot hold angles and a length with their units stated.
- **Public constants.** The semi-major axis and the inverse flattening are public constants named after their model, because the globe specs will need the same radius (ADR-0003, Amendment 2). The semi-minor axis, the flattening and the eccentricity are derived inside the function and are not public.
- **Named parameter.** The input is a required named parameter, as in req-orb-006, so a call states that the position is Earth-fixed.
- **Input validation.** A non-finite position component and the origin are rejected, each with an exact message. The roadmap row does not name this. It is kept for the same reason as in req-orb-004 to req-orb-006: the function runs on the frame path, and an unchecked NaN would flow silently into the card.
- **Free sources only.** Every published reference value comes from a document or repository that can be read free of charge (Definitions).

## Definitions used by every requirement

These definitions are normative.

- **IOGP note:** International Association of Oil & Gas Producers, Publication 373-7-2, "Geomatics Guidance Note Number 7, part 2: Coordinate Conversions and Transformations including Formulas", revised September 2019, at `https://www.iogp.org/wp-content/uploads/2019/09/373-07-02.pdf`. The note says it is subject to revision, so this spec pins the copy read while drafting: 162 pages, 2611009 bytes, SHA-256 `8951d9641e6a65a071e865d1e6bb0611d0d7248772fa3054496fc14041183465`. A later revision is a different source, and citing it requires a spec change. Section 4.1.1 (EPSG method 9602) starts on page 95 with the forward and reverse formulas. Page 96 publishes this WGS-84 example:
  - **IOGP position:** X = 3771793.968 m, Y = 140253.342 m, Z = 5124304.349 m, which is (3771.793968, 140.253342, 5124.304349) km;
  - **IOGP coordinates:** latitude 53°48′33.820″N, longitude 2°07′46.380″E, ellipsoidal height 73.0 m;
  - **IOGP semi-minor axis:** b = 6356752.314 m, printed with the example.
- **Rounded flattening of the IOGP example.** The example prints 1/f = 298.2572236, a rounding of the WGS-84 value that page 67 of the same note prints as 298.257223563. Using the full value changes the latitude by 4.0·10⁻¹³ rad and the altitude by 1.7·10⁻⁹ km at the IOGP position, far below the tolerances of REQ-ORB-007.1.
- **Vallado repository:** CelesTrak, "fundamentals-of-astrodynamics", at `https://github.com/CelesTrak/fundamentals-of-astrodynamics`, licensed under AGPL-3.0, as described in `specs/req-orb-004.md`. Three of its files are cited, all at commit `49df0479c950917c0a2c5ac31f2db6477bba57f6`:
  - `software/python/tests/astro/twobody/test_frame_conversions.py`:
    - its fixture `recef` of class `TestGeodetic` (line 583, labelled "Example 3-3, Vallado, 2001") publishes the **Vallado position** (6524.834, 6862.875, 6448.296) km;
    - its test `test_ecef2ll` (line 587) publishes the **Vallado coordinates**: `latgd` = 0.5995641464668334 rad, `lon` = 0.8106428999047803 rad, `hellp` = 5085.219430346959 km;
  - `software/python/src/valladopy/astro/twobody/frame_conversions.py`, function `ecef2ll` (line 1446), which produced those values and cites "Vallado: 2022, p. 174, Algorithm 12";
  - `software/python/src/valladopy/constants.py`, which fixes `RE` = 6378.1363 km (line 58) and `FLAT` = 1 / 298.257223563 (line 59), the ellipsoid of those values.
- **WGS-84 constants:** a = 6378.137 km and 1/f = 298.257223563, as printed on page 67 of the IOGP note. The flattening is also the `FLAT` of the Vallado repository. The defining document of WGS-84, NGA TR8350.2, could not be retrieved while drafting, so it is not cited.
- **Derived values:** f = 1 / (1/f); b = a(1 − f); e² = 2f − f²; ε = e² / (1 − e²); p = (x² + y²)^(1/2), computed as the square root of the sum; ν = a / (1 − e²·sin²φ)^(1/2).
- **Geodetic latitude:** the result of the two passes of Context, Latitude model, for an Earth-fixed position (x, y, z).
- **Longitude:** atan2(y, x), except that it is 0.0 when x and y both equal 0.0 (−0.0 included), and that a result of exactly −π is returned as π.
- **Altitude:** p·cos φ + z·sin φ − a²/ν, with φ the geodetic latitude.
- **Forward formulas:** x = (ν + h)·cos φ·cos λ, y = (ν + h)·cos φ·sin λ, z = (ν(1 − e²) + h)·sin φ, as printed on page 95 of the IOGP note. The math test file writes them as a private helper, with the WGS-84 constants as literal numbers. They are never part of the library (Out of Scope).
- **Degrees to radians:** a value of d degrees is d · π / 180, with `pi` from `dart:math`. A sexagesimal value adds degrees, minutes / 60 and seconds / 3600 before converting.
- **2π:** `2 * pi` with `pi` from `dart:math`.
- **|r|:** the Euclidean length of a position r.
- **Wrapped difference:** for two longitudes, the absolute difference d if d ≤ π, otherwise 2π − d.
- **Close to within x:** the absolute difference from the expected value is at most x.
- **Exact:** compared with `==` on doubles, with no tolerance, so 0.0 and −0.0 compare equal.
- **In range:** the latitude is between −π/2 and π/2, both included, compared with `<=` against `pi / 2`, and the longitude is greater than −π and at most π, compared with `pi` directly.
- **Geodetic library file:** `packages/orbital_core/lib/src/geodetic.dart`.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/geodetic_test.dart`. It covers REQ-ORB-007.1 to .5.
- **Guard test file:** `test/orbital_core_geodetic_guard_test.dart`, in the application suite.
- **Spec file:** `specs/req-orb-007.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-007.1 — Published WGS-84 position to its published coordinates

The IOGP position yields the IOGP coordinates.

**Acceptance (verified by the math test file).**

- The input is the IOGP position, written in kilometres as literal numbers.
- The expected latitude and longitude are computed in the math test file from the published degrees, minutes and seconds.
- The latitude and the longitude are each close to within 2.5·10⁻⁹ rad of the expected value. This is half of the last published digit of 0.001″, which is 2.4·10⁻⁹ rad, and not a measure of the conversion.
- The altitude is close to within 5·10⁻⁵ km of 0.073 km. The note prints the height as 73.0 m, so this is half of its last published digit. A library on the radius of the Vallado repository is off by about 7·10⁻⁴ km here and still fails.

The errors measured while drafting were 7.8·10⁻¹¹ rad in latitude, 2.3·10⁻¹¹ rad in longitude and 6.9·10⁻⁸ km in altitude.

### REQ-ORB-007.2 — Published orbital-altitude position to its published coordinates

The Vallado position yields the Vallado coordinates, within the documented cost of their different Earth radius.

**Acceptance (verified by the math test file).**

- The input is the Vallado position, written as literal numbers.
- The latitude is close to within 3·10⁻¹⁰ rad of the published `latgd`.
- The longitude is close to within 1·10⁻¹⁵ rad of the published `lon`.
- The altitude is close to within 1·10⁻³ km of the published `hellp`.

The errors measured while drafting were 1.91·10⁻¹⁰ rad in latitude, 0.0 rad in longitude and 6.99·10⁻⁴ km in altitude. The altitude and latitude differences are the 0.7 m between `RE` of the Vallado repository and a of WGS-84. The tolerances bound that documented cost, which is why they are looser than in REQ-ORB-007.1: they are not a measure of the conversion, which REQ-ORB-007.1 and .4 measure. A library that uses the radius of the Vallado repository passes this row and fails REQ-ORB-007.1.

### REQ-ORB-007.3 — Fixed points

The equator, the poles, the antimeridian, a position below the ellipsoid and signed zeros give the values below.

**Acceptance (verified by the math test file).** "0.0" and the angles π / 2, −π / 2 and π are `0.0`, `pi / 2`, `-pi / 2` and `pi` compared exactly, unless the row gives a tolerance. "Polar" means close to within 1·10⁻¹⁵ rad of π / 2, or of −π / 2 for a negative z. The Altitude column gives its own tolerance.

| Earth-fixed position (km) | Latitude | Longitude | Altitude (km) |
| --- | --- | --- | --- |
| (6378.137, 0.0, 0.0) | 0.0 | 0.0 | 0.0, within 1·10⁻¹¹ |
| (42164.0, 0.0, 0.0) | 0.0 | 0.0 | 35785.863, within 1·10⁻⁹ |
| (0.0, 42164.0, 0.0) | 0.0 | π / 2 | 35785.863, within 1·10⁻⁹ |
| (0.0, −42164.0, 0.0) | 0.0 | −π / 2 | 35785.863, within 1·10⁻⁹ |
| (−42164.0, 0.0, 0.0) | 0.0 | π | 35785.863, within 1·10⁻⁹ |
| (−42164.0, −0.0, 0.0) | 0.0 | π | 35785.863, within 1·10⁻⁹ |
| (−42164.0, −1·10⁻³⁰⁰, 0.0) | 0.0 | π | 35785.863, within 1·10⁻⁹ |
| (6000.0, 0.0, 0.0) | 0.0 | 0.0 | −378.137, within 1·10⁻⁹ |
| (0.0, 0.0, 6356.752314) | Polar | 0.0 | 0.0, within 1·10⁻⁶ |
| (0.0, 0.0, −6356.752314) | Polar | 0.0 | 0.0, within 1·10⁻⁶ |
| (0.0, 0.0, 7000.0) | Polar | 0.0 | 643.247686, within 1·10⁻⁶ |
| (0.0, 0.0, −7000.0) | Polar | 0.0 | 643.247686, within 1·10⁻⁶ |
| (−0.0, 0.0, 7000.0) | Polar | 0.0 | 643.247686, within 1·10⁻⁶ |
| (−0.0, −0.0, 7000.0) | Polar | 0.0 | 643.247686, within 1·10⁻⁶ |
| (0.0, −0.0, −7000.0) | Polar | 0.0 | 643.247686, within 1·10⁻⁶ |

The polar rows take the IOGP semi-minor axis: 6356.752314 km is on the ellipsoid to the last published digit, and 643.247686 km is 7000.0 km minus that axis. The equatorial rows are the radius minus a of WGS-84. The largest errors measured while drafting were 9.1·10⁻¹³ km on the first row and 2.5·10⁻⁷ km on the polar rows; the other equatorial altitudes differ from their expected values by rounding only.

### REQ-ORB-007.4 — Round trip and symmetry over grids

A position built from a latitude, a longitude and an altitude by the forward formulas converts back to the same values, north and south mirror each other, and the result stays finite and in range even deep inside the Earth.

**Acceptance (verified by the math test file).**

- **Outer grid.** Every combination, 1280 in total, of:
  - the latitude in {−90.0, −89.9999, −89.99, −89.0, −60.0, −35.0, −1·10⁻⁶, 0.0, 1·10⁻⁶, 35.0, 51.6, 60.0, 89.0, 89.99, 89.9999, 90.0} degrees;
  - the longitude in {−179.9, −90.0, −1·10⁻⁶, 0.0, 45.0, 120.0, 179.9, 180.0} degrees;
  - the altitude in {−100.0, −10.0, 0.0, 0.1, 100.0, 408.0, 628.0, 35786.0, 1·10⁶, 9.1·10⁹} km.
- For each combination, with r the position that the forward formulas give and g its conversion:
  - **latitude:** the latitude of g is close to within 1·10⁻¹⁵ rad of the grid latitude;
  - **longitude:** unless the grid latitude is ±90.0 degrees, the wrapped difference of the longitude of g and the grid longitude is at most 1·10⁻¹⁵ rad;
  - **altitude:** the altitude of g is close to within 2·10⁻¹⁵ · |r| of the grid altitude;
  - **position:** the forward formulas applied to g give a position at a Euclidean distance of at most 2·10⁻¹⁵ · |r| from r;
  - **range:** g is in range;
  - **mirror:** the conversion of r with its z component negated has, exactly, the negated latitude, the same longitude and the same altitude as g.
- **Inner round trip.** For every radius ρ in {1000.0, 3000.0, 6000.0} km and every geocentric latitude d from −90 to 90 degrees in steps of 1, the position (ρ · cos d, 0.0, ρ · sin d) converts to a g whose forward position is at a Euclidean distance of at most 1·10⁻⁸ km from it.
- **Inner domain.** For every ρ in {1·10⁻³, 1.0, 10.0, 20.0, 30.0, 40.0, 42.0, 43.0, 44.0, 50.0, 100.0, 500.0} km, every geocentric latitude d from −90 to 90 degrees in steps of 1 and every θ in {0.0, 1.0, 3.0, −2.0} rad, 8688 positions in total, the position (ρ · cos d · cos θ, ρ · cos d · sin θ, ρ · sin d) converts to a g whose three fields are finite and which is in range.

The largest errors measured while drafting were, on the outer grid, 1.1·10⁻¹⁶ rad in latitude, 3.3·10⁻²⁴ rad in longitude and 5.7·10⁻¹⁶ · |r| in altitude and position, and the mirror check was exact; on the inner round trip, 3.5·10⁻⁹ km at 1000 km, 2.7·10⁻¹² km at 3000 km and 2.8·10⁻¹² km at 6000 km.

The range check of the inner domain is measured, not derived from the formulas: no proof is given that two passes keep the latitude within ±π/2 inside the evolute of the ellipsoid (Edge Cases). Besides the listed positions, a random scan of 2·10⁶ positions with radii from 1·10⁻⁶ km to 1·10¹⁰ km found no result out of range or non-finite. If a faithful implementation of the model fails this check, the model prevails: the fix is a spec change, never a clamp or another step added to the formulas.

### REQ-ORB-007.5 — Input validation with exact messages

The function accepts only the inputs below. Any other input throws Dart's `ArgumentError` and returns no value. No message contains an apostrophe, so each can be written in the geodetic library file as a plain single-quoted string. "Finite" means neither NaN nor positive or negative infinity.

Checks run in this order and the first failure wins:

1. the three components of the position are finite, otherwise message P;
2. at least one component differs from 0.0, otherwise message O.

The messages:

- **Message P:** `Geodetic conversion requires a finite ECEF position.`
- **Message O:** `Geodetic conversion requires a position away from the origin.`

**Acceptance (verified by the math test file).**

- "Throws X" means the thrown object is an `ArgumentError` whose message is equal to message X, character for character.
- "Accepted" means the function returns without throwing and every field of its result is finite.

| Position (km) | Expected |
| --- | --- |
| (NaN, 2000.0, 3000.0) | Throws P |
| (1000.0, positive infinity, 3000.0) | Throws P |
| (1000.0, 2000.0, negative infinity) | Throws P |
| (NaN, 0.0, 0.0) | Throws P |
| (0.0, 0.0, 0.0) | Throws O |
| (−0.0, 0.0, −0.0) | Throws O |
| (1·10⁻²⁰⁰, 0.0, 0.0) | Accepted |
| (0.0, 0.0, 1·10⁻³) | Accepted |
| (1.0, 0.0, 0.0) | Accepted |
| (9.1·10⁹, −9.1·10⁹, 9.1·10⁹) | Accepted |

### REQ-ORB-007.6 — Placement, public names and documented contract

The function, its result type and its constants live in the geodetic library file and are reachable through the public library file. The documentation states the model, the frame, the ranges, the units and the reference, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The geodetic library file exists.
- The public library file contains the line `export 'src/geodetic.dart';`.
- **Constants.** The geodetic library file contains the lines `const double wgs84SemiMajorAxisKm = 6378.137;` and `const double wgs84InverseFlattening = 298.257223563;`.
- **Doc block.** The doc block of the function is the run of consecutive lines directly before the line `GeodeticPosition geodeticPositionFromEcef({` whose text, with leading and trailing spaces removed, starts with `///`. It contains each of these eight lines, in any order:
  - `/// Model: WGS-84 ellipsoid, a = 6378.137 km and 1/f = 298.257223563.`
  - `/// Input frame: Earth-fixed axes without polar motion (PEF), used as ECEF.`
  - `/// Latitude: geodetic, two fixed passes of the closed form, from -pi/2 to pi/2.`
  - `/// Longitude: atan2(y, x), greater than -pi and up to pi; 0.0 on the z axis.`
  - `/// Altitude: height above the ellipsoid, h = p cos(lat) + z sin(lat) - a^2 / nu; negative below it.`
  - `/// Ignored: the geoid; altitude is not height above mean sea level.`
  - `/// Units: km and radians.`
  - `/// Reference: IOGP Publication 373-7-2 (September 2019), section 4.1.1, EPSG method 9602.`
- **Public name.** The line `GeodeticPosition geodeticPositionFromEcef({` must appear in the geodetic library file, compared after trimming. This name is the contract that later specs read.
- **Parameter.** The line directly after that line is `required CartesianVector ecefPositionKm,` and the line after it is `}) {`, each equal after trimming. `dart format` always splits this declaration, because it does not fit within 80 columns.
- **Result type.** The geodetic library file contains the line `final class GeodeticPosition {`. From the next line up to the first line that is equal to `}` with no spaces removed, ignoring empty lines and lines that start with `///` after trimming, the trimmed lines are exactly, in this order: `const GeodeticPosition({`, `required this.latitudeRad,`, `required this.longitudeRad,`, `required this.altitudeKm,`, `});`, `final double latitudeRad;`, `final double longitudeRad;`, `final double altitudeKm;`. So the type declares no other public or private member.
- **Top-level declarations.** Every line of the geodetic library file that has a character other than a space at its first column, compared with no spaces removed, starts with `//`, starts with `import '`, or is equal to one of `const double wgs84SemiMajorAxisKm = 6378.137;`, `const double wgs84InverseFlattening = 298.257223563;`, `final class GeodeticPosition {`, `GeodeticPosition geodeticPositionFromEcef({`, `}) {` and `}`. Empty lines are allowed. `dart format` writes every top-level declaration at the first column and every line inside a declaration indented, so the file declares no other top-level name, public or private. Local variables inside the function are indented and stay allowed.

**Acceptance (verified by command V11).** Compared with `main`, this pull request adds or changes exactly four files and no other: the public library file, the geodetic library file, the math test file and the guard test file. This enforces the file list of Out of Scope by machine.

### REQ-ORB-007.7 — Purity, citations and test hygiene

The new code adds no dependency, every published value is cited in the math test file, the tests do not borrow the constants they check, and the new files follow the hygiene rules of req-orb-006.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file does not contain the substring `wgs84`, compared case-sensitively as Dart identifiers are, so that its expected values and its forward formulas use literal numbers, and a wrong constant in the library fails its rows.
- The math test file contains each of these four citation lines, compared after trimming:
  - `// IOGP Publication 373-7-2, Geomatics Guidance Note 7-2, September 2019: https://www.iogp.org/wp-content/uploads/2019/09/373-07-02.pdf, section 4.1.1, EPSG method 9602.`
  - `// IOGP 373-7-2, page 96: WGS 84 geocentric coordinates of a North Sea point to latitude, longitude and ellipsoidal height.`
  - `// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.`
  - `// Vallado repository, twobody test_frame_conversions.py, test_ecef2ll (Example 3-3): computed with RE = 6378.1363 km, not the WGS-84 radius.`
- The math test file contains, for each N from 1 to 5, a line equal to `// REQ-ORB-007.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
- The guard test file contains, for each N in {6, 7}, a line equal to `// REQ-ORB-007.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
- The guard test file builds the tag strings of the math test file (`// REQ-ORB-007.1` to `.5`) by interpolation, never as literals, so that V10 prints only its own tags.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the guard test file, the core library files and the spec file.
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser. `dart:io` never appears in `packages/orbital_core`, which the two regular expressions above enforce.
- Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, the geodetic library file, the public library file, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-007.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-007.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-007.7, which the guard test file checks (Constitution principle 6). The sources are:

- **WGS-84 near the surface (REQ-ORB-007.1):** the example published by the IOGP note, compared within its printed precision.
- **Orbital altitude (REQ-ORB-007.2):** the example published by the Vallado repository, compared within the cost of its different radius.
- **Poles (REQ-ORB-007.3):** the semi-minor axis printed by the IOGP note.
- **Round trip (REQ-ORB-007.4):** the forward formulas printed by the IOGP note, written in the math test file with literal constants. They add no formula to the library.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `wc` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/geodetic_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-007.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-006 still pass |
| V4 | `flutter test test/orbital_core_geodetic_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-007.6, .7 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-007.7 |
| V6 | `flutter test` | exit 0 | REQ-ORB-007.6, .7; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-007\.[0-9]+" packages/orbital_core/test/geodetic_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-007.1,// REQ-ORB-007.2,// REQ-ORB-007.3,// REQ-ORB-007.4,// REQ-ORB-007.5` | REQ-ORB-007.7 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-007\.[0-9]+" test/orbital_core_geodetic_guard_test.dart \| sort -u \| paste -sd, -` | standard output `// REQ-ORB-007.6,// REQ-ORB-007.7` | REQ-ORB-007.7 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --name-only origin/main...HEAD \| sort \| paste -sd, -` | standard output `packages/orbital_core/lib/orbital_core.dart,packages/orbital_core/lib/src/geodetic.dart,packages/orbital_core/test/geodetic_test.dart,test/orbital_core_geodetic_guard_test.dart` | REQ-ORB-007.6 (only the four files of this spec change) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after every file of this pull request is committed on the feature branch, so that the revert below restores each of them. Before G0, `git status --porcelain` must print nothing; otherwise stop, because G14, G41, G42 and the revert would destroy uncommitted work.

The command is:

    flutter test test/orbital_core_geodetic_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-007.md"

**Control run (G0).** With no edit applied, run the command once with `<tag>` replaced by `[REQ-ORB-007.6]` and once with `[REQ-ORB-007.7]`, and confirm that each prints nothing. A line printed here means that the output of a passing run, such as a test name, already carries a tag and the spec path, so the rows below would prove nothing; fix the guard test file before continuing.

Then, for each row of the table:

1. Apply the edit.
2. Run the command and confirm that it prints at least one line. That line carries both the expected tag and the spec path.
3. Revert with `git checkout -- packages/orbital_core test specs` before the next row.

"Delete the line X" and "Replace the line X" act on every line that equals X after trimming. "Replace every occurrence" acts on every occurrence of the substring. Inside the table, `\|` is a single pipe.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the geodetic library file | `[REQ-ORB-007.7]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the geodetic library file | `[REQ-ORB-007.7]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the geodetic library file | `[REQ-ORB-007.7]` |
| G4 | Add `import 'dart:ffi';` as the first line of the geodetic library file | `[REQ-ORB-007.7]` |
| G5 | Delete the line `/// Model: WGS-84 ellipsoid, a = 6378.137 km and 1/f = 298.257223563.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G6 | Delete the line `/// Input frame: Earth-fixed axes without polar motion (PEF), used as ECEF.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G7 | Delete the line `/// Latitude: geodetic, two fixed passes of the closed form, from -pi/2 to pi/2.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G8 | Delete the line `/// Longitude: atan2(y, x), greater than -pi and up to pi; 0.0 on the z axis.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G9 | Delete the line `/// Altitude: height above the ellipsoid, h = p cos(lat) + z sin(lat) - a^2 / nu; negative below it.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G10 | Delete the line `/// Ignored: the geoid; altitude is not height above mean sea level.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G11 | Delete the line `/// Units: km and radians.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G12 | Delete the line `/// Reference: IOGP Publication 373-7-2 (September 2019), section 4.1.1, EPSG method 9602.` from the geodetic library file | `[REQ-ORB-007.6]` |
| G13 | Delete the line `export 'src/geodetic.dart';` from the public library file | `[REQ-ORB-007.6]` |
| G14 | Delete the file `packages/orbital_core/lib/src/geodetic.dart` | `[REQ-ORB-007.6]` |
| G15 | Replace every occurrence of `GeodeticPosition geodeticPositionFromEcef(` with `GeodeticPosition geodeticPosition(` in the geodetic library file | `[REQ-ORB-007.6]` |
| G16 | Replace the line `required CartesianVector ecefPositionKm,` with `required CartesianVector positionKm,` in the geodetic library file | `[REQ-ORB-007.6]` |
| G17 | Replace the line `const double wgs84SemiMajorAxisKm = 6378.137;` with `const double wgs84SemiMajorAxisKm = 6378.1363;` in the geodetic library file | `[REQ-ORB-007.6]` |
| G18 | Replace the line `const double wgs84InverseFlattening = 298.257223563;` with `const double wgs84InverseFlattening = 298.2572236;` in the geodetic library file | `[REQ-ORB-007.6]` |
| G19 | Replace the line `final double altitudeKm;` with `final double heightKm;` in the geodetic library file | `[REQ-ORB-007.6]` |
| G20 | Insert the line `final double extraRad = 0.0;` directly before the line `final double altitudeKm;` in the geodetic library file | `[REQ-ORB-007.6]` |
| G21 | Append the line `const double wgs84SemiMinorAxisKm = 6356.752314;` to the geodetic library file | `[REQ-ORB-007.6]` |
| G22 | Append the line `double _flattening = 1 / 298.257223563;` to the geodetic library file | `[REQ-ORB-007.6]` |
| G23 | Delete the line `/// Units: km and radians.` from the geodetic library file and insert it as the first line of the same file | `[REQ-ORB-007.6]` |
| G24 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-007.7]` |
| G25 | Add `import 'package:orbital_core/src/geodetic.dart';` to the math test file | `[REQ-ORB-007.7]` |
| G26 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-007.7]` |
| G27 | Replace the line `// REQ-ORB-007.2` with `// REQ-ORB-007.x`, keeping its indentation, in the math test file | `[REQ-ORB-007.7]` |
| G28 | Insert the line `// note` directly after the line `// REQ-ORB-007.1` in the math test file | `[REQ-ORB-007.7]` |
| G29 | Delete the citation line that starts with `// IOGP Publication 373-7-2, Geomatics` from the math test file | `[REQ-ORB-007.7]` |
| G30 | Delete the citation line that starts with `// IOGP 373-7-2, page 96` from the math test file | `[REQ-ORB-007.7]` |
| G31 | Delete the citation line that starts with `// Vallado repository: https://` from the math test file | `[REQ-ORB-007.7]` |
| G32 | Delete the citation line that starts with `// Vallado repository, twobody` from the math test file | `[REQ-ORB-007.7]` |
| G33 | Append the line `// skip: true` to the math test file | `[REQ-ORB-007.7]` |
| G34 | Run `sed -i 's/$/\r/' packages/orbital_core/test/geodetic_test.dart` (CRLF) | `[REQ-ORB-007.7]` |
| G35 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/geodetic_test.dart > /tmp/g35 && mv /tmp/g35 packages/orbital_core/test/geodetic_test.dart` (BOM) | `[REQ-ORB-007.7]` |
| G36 | Run `sed -i 's/$/\r/' specs/req-orb-007.md` (CRLF in the spec file) | `[REQ-ORB-007.7]` |
| G37 | Run `printf '\xEF\xBB\xBF' \| cat - specs/req-orb-007.md > /tmp/g37 && mv /tmp/g37 specs/req-orb-007.md` (BOM in the spec file) | `[REQ-ORB-007.7]` |
| G38 | Run `sed -i 's/$/\r/' packages/orbital_core/lib/src/geodetic.dart` (CRLF in a core library file) | `[REQ-ORB-007.7]` |
| G39 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-007.7]` |
| G40 | Replace the line `// REQ-ORB-007.6` with `// REQ-ORB-007.x`, keeping its indentation, in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-ORB-007.7]` |
| G41 | Delete the file `packages/orbital_core/test/geodetic_test.dart` | `[REQ-ORB-007.7]` |
| G42 | Delete the file `packages/orbital_core/lib/orbital_core.dart` | `[REQ-ORB-007.6]` |
| G43 | Append the line `// wgs84SemiMajorAxisKm` to the math test file | `[REQ-ORB-007.7]` |
| G44 | Insert the line `required double extraKm,` directly after the line `required CartesianVector ecefPositionKm,` in the geodetic library file | `[REQ-ORB-007.6]` |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V11 and G0–G44, each with its observed result. A pull request without this list is incomplete regardless of its check status.

## Edge Cases & Errors

- **Exact equator.** z = 0 gives a latitude of 0.0 and no division by sin φ, so a geostationary position never yields NaN (REQ-ORB-007.3). This is the reason Algorithm 12 is not used (Context).
- **Exact poles.** x = y = 0 gives a polar latitude, a longitude of 0.0 and an altitude of |z| − b (REQ-ORB-007.3).
- **Antimeridian.** A position with y = −0.0, or with y so small and negative that `atan2` rounds to −π, has a longitude of π, never −π (REQ-ORB-007.3). A longitude continuous across the antimeridian is not provided; a consumer that draws a line across it handles the jump.
- **Negative zero.** −0.0 in x or y on the z axis gives a longitude of 0.0, which excludes the π that `atan2(0.0, -0.0)` returns. −0.0 in z gives a latitude of −0.0, which compares equal to 0.0.
- **Origin.** All three components equal to 0.0, −0.0 included, throw message O (REQ-ORB-007.5). No element set propagated by Kepler reaches it (Context).
- **Error output of a propagator.** Some SGP4 implementations report a failure, such as a decayed object, by returning a zero or NaN position. Passed here, that output throws message O or P on the frame path. This spec only records the risk and fixes nothing about it: how propagation failures are reported and who handles them belongs to ADR-0002, which chooses the library, and to req-orb-010, which wraps it.
- **Below the ellipsoid.** Accepted, with a negative altitude (REQ-ORB-007.3, row 6000.0 km). A decayed object or a mean-element position with its perigee under the surface can reach this, and throwing would stop the frame. Showing that the data is stale or an object has decayed is not this function's job.
- **Deep inside the Earth.** Closer than about 43 km from the centre, a point lies inside the evolute of the ellipsoid (a·e² = 42.70 km on the equatorial plane and (a² − b²) / b = 42.84 km on the axis), so more than one latitude satisfies the geometry. Two passes also lose exactness gradually as the radius shrinks, starting well outside that region: the worst position errors measured by the forward formulas over geocentric latitudes from 0 to 90 degrees in steps of 0.025 degrees (the southern hemisphere mirrors them, REQ-ORB-007.4) were 3.2·10⁻⁷ km at a radius of 500 km, 8.5·10⁻³ km at 100 km, 1.4 km at 50 km and 20 km at 10 km. These figures are not checked by any test. The function returns finite values in range there (REQ-ORB-007.4, Inner domain) with no round-trip guarantee below 1000 km of radius. Real tracked objects never go there.
- **Very large positions.** The largest semi-major axis an element set can produce is about 9.1·10⁹ km (req-orb-005), and the outer grid of REQ-ORB-007.4 reaches an altitude of that size. Squaring a component overflows above about 1.3·10¹⁵⁴ km, which yields a non-finite result. This spec does not check inputs of that size, which no element set can reach.
- **Very small positions.** Squaring a component below about 1·10⁻¹⁶² km underflows, so p can be 0.0 although x or y is not. The result stays finite (REQ-ORB-007.5, row 1·10⁻²⁰⁰). The z-axis convention for longitude tests x and y themselves, so longitude stays atan2(y, x) there.
- **Rounding of π / 2.** `cos(pi / 2)` as a double is about 6.1·10⁻¹⁷, so the polar rows of REQ-ORB-007.3 use a tolerance for the latitude, never `==`.
- **Ellipsoid and SGP4.** SGP4 uses the WGS-72 gravity model (ADR-0003), and its position is read here on the WGS-84 ellipsoid, as step 8 of the Project Brief fixes. The ellipsoid only defines the coordinates of a position, so this mix moves nothing in space.
- **Geoid.** The altitude is above the ellipsoid, not above mean sea level. The IOGP note gives their difference as between about −100 m and +80 m (page 95). That is immaterial for an orbiting object and is not corrected.
- **Polar motion and UTC as UT1.** Inherited from the Earth-fixed position (req-orb-006). Ignoring polar motion moves a position by at most about 20 m in low orbit, which shifts both latitude and longitude. A DUT1 of up to 0.9 s turns the Earth by at most 6.6·10⁻⁵ rad about the z axis, which shifts the longitude only. Neither changes this conversion. No published row of this spec includes them, because each row starts from an Earth-fixed position.
- **Different radius in the Vallado row.** 0.7 m (Definitions), bounded by REQ-ORB-007.2 and documented there. It is not an error of the library; REQ-ORB-007.1 and the literal constants of REQ-ORB-007.6 fix the WGS-84 radius.
- **Declarations split by the formatter.** The public declaration and the constructor do not fit within 80 columns, so `dart format` splits them, which the guard fixes. The top-level rule of REQ-ORB-007.6 relies on the same formatter, which writes every top-level declaration at the first column. If a future formatter changes that layout, the guard reports `[REQ-ORB-007.6]`. The fix is a spec change, never a relaxed guard.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-007.7). `.gitattributes` (`* text=auto eol=lf`) keeps checkouts LF, so a CR byte means an editor saved the file with Windows line endings. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access at run time. V11 needs `git fetch` and is a local check; if the fetch fails, V11 counts as not run, never as a pass. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.

## Out of Scope

Nothing below is written in this pull request:

- A public conversion from geodetic coordinates to Earth-fixed axes. The forward formulas exist only as a private helper of the math test file. A globe spec that needs them adds them through its own requirement.
- Geocentric latitude, reduced latitude as an output, height above the geoid or mean sea level, and any geoid model.
- Degrees, sexagesimal formatting, value formatting of any kind, or any UI string.
- Any velocity, ground speed or sub-satellite track.
- A public semi-minor axis, flattening or eccentricity, and any top-level declaration other than those of REQ-ORB-007.6. Local variables inside the function, `const` ones included, are allowed.
- Value equality, hashing or arithmetic of the new type, and any change to `CartesianVector`.
- A function that takes an element set, an instant or a Julian date, the propagator interface, or a propagated state (req-orb-009).
- Speed, period, inclination and the rest of the derived values (req-orb-008).
- Polar motion, nutation, Earth orientation data or any change to the rotation of req-orb-006.
- Any change to `packages/orbital_core/lib/src/orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart`, `kepler.dart`, `perifocal.dart`, `state_vector.dart` or `earth_fixed.dart`, or to their tests and guards.
- Copying code from the Vallado repository; only its published values are cited.
- Any code in the application `lib/`, any provider or widget.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution or any ADR.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
