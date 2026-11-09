# req-orb-010 — SGP4 adapter behind the interface

- **Status:** Draft (revision 1), pending the first QA audit. On 2026-11-08, before drafting, the developer approved:
  - the library: `satellite_observer`, accepted by ADR-0002 on condition that it passes the official vectors;
  - ADR-0002 drafted with this spec, in the same pull request;
  - an element set built from the fields of `OrbitalElements`, with no change to req-orb-003;
  - validation against `SGP4-VER.TLE`, limited to the 30 element sets that the parser of req-orb-003 accepts;
  - the verification data as a Dart data file checked against the vendored originals;
  - a throwaway prototype in a scratch directory outside the repository;
  - the amendments to req-inf-001 and req-inf-002;
  - an exact version pin.

  Every measured figure below was measured in Dart with that prototype, which is not part of the repository.
- **Roadmap row:** 12 of 33 (MVP)
- **Blocks:**
  - req-sta-001: builds one SGP4 propagator per tracked object and reads its state every frame;
  - req-viz-005: draws the SGP4 states;
  - req-viz-006: samples one period of the SGP4 state.
- **Depends on:**
  - req-orb-001: `JulianDate` and its UTC checks;
  - req-orb-002: `gmstRad`;
  - req-orb-003: `OrbitalElements` and the TLE parser;
  - req-orb-005: `CartesianVector` and `StateVector`;
  - req-orb-006: `ecefPositionKm`;
  - req-orb-009: `Propagator`, `PropagatedState` and `PropagationException`;
  - req-inf-001 and req-inf-002, as amended with this spec;
  - ADR-0001 (baseline packages), ADR-0002 (SGP4 library) and ADR-0003 (TLE element sets and the gravity-model constants of SGP4).
- **ADR:** ADR-0002, drafted and accepted with this spec. It chooses the library, pins its version, accepts its transitive dependency and amends REQ-INF-001.3, REQ-INF-001.8 and REQ-INF-002.9.

  This spec adds no formula of its own beyond unit conversions: degrees to and from radians, and revolutions per day to and from radians per second. REQ-ORB-010.1 tests those conversions end to end against the published vectors of Vallado et al., as Constitution principle 6 requires.

## Context & Objective

Roadmap row 12 asks to "wrap the library chosen in ADR-0002 and validate it against the official test vectors, delivering the realistic propagation the MVP renders". req-orb-009 fixed the seam: a propagator bound to one `OrbitalElements`, a `PropagatedState` with the instant, the inertial state, GMST and the Earth-fixed position, and a `PropagationException` for a model that cannot propagate. It left the SGP4 adapter, the mapping of the library's failures and the WGS-72 gravity model to this spec. This spec delivers that adapter and proves it against the verification data published with "Revisiting Spacetrack Report #3".

The developer approved these decisions before drafting.

- **Library (ADR-0002).** `satellite_observer` 1.0.1, a pure-Dart port of Vallado's reference code, MIT-licensed, whose library files import only `dart:math` and `package:meta`. It is a runtime dependency of `packages/orbital_core` only. The core manifest pins it to exactly `1.0.1`, because the core has no committed lockfile.
- **Element set from fields.** The library builds its element set either from TLE lines or from fields in degrees and revolutions per day. `OrbitalElements` keeps no TLE lines, so the adapter builds it from the fields of `OrbitalElements`:
  - inclination, ascending node, argument of perigee and mean anomaly, converted from radians to degrees;
  - mean motion, converted from radians per second to revolutions per day;
  - eccentricity and B\* (inverse Earth radii, ADR-0003 decision 2), passed as they are;
  - the two mean-motion terms, converted back to the published units.

  req-orb-003 is not changed. In the prototype, this path differed from the library's own TLE path by at most 2.6·10⁻⁷ km. That difference comes from the round trips of the unit conversions and stays inside the tolerance of REQ-ORB-010.1.
- **Official vectors, 30 sets.** `SGP4-VER.TLE` holds 33 element sets. Three of them, catalog numbers 33333, 33334 and 33335, carry an invalid line 1 checksum on purpose, and the parser of req-orb-003 rejects them. The adapter is proved against the other 30 sets and their 588 reference states in `tcppver.out` (REQ-ORB-010.1). Five of them stop early with SGP4 error codes 1, 1, 6, 6 and 6 (REQ-ORB-010.2). The three rejected sets are kept as a test of the parser boundary (REQ-ORB-010.3). They carry the two cases of error codes 4 and 3, which this adapter therefore cannot reach.
- **Verification data.** Constitution principle 3 and the hygiene rules of req-orb-006 to req-orb-009 keep `dart:io` out of the core and its math tests. The two original files are therefore vendored unchanged, except that the line endings of `SGP4-VER.TLE` are converted to LF. A Dart data file then carries their content as string literals, for the math test file to read. The guard test file, in the application suite, proves line by line that the data file equals the originals (REQ-ORB-010.6).
- **Amended scaffold specs.** REQ-INF-001.3 and REQ-INF-001.8 required zero runtime dependencies in the core, and REQ-INF-002.9 fixed the name of the test that enforces it. They are amended with this spec (ADR-0002, decision 7) so that the core may declare this one dependency, at exactly this version, and no other.

The remaining decisions follow from the Constitution, req-orb-009 and the prototype.

- **Fixed semantics of GMST and ECEF.** As req-orb-009 fixes for every propagator, GMST is `gmstRad` of the Julian date of the instant, and the Earth-fixed position is `ecefPositionKm` of the TEME position at that GMST. The GMST and the Earth-rotation code of the library are not used.
- **Instant checked first.** For an instant that is not UTC, the library converts it to UTC silently. The adapter therefore calls `JulianDate.fromUtc` before it calls the library, so an invalid instant throws the same `ArgumentError` as the Kepler propagator does (REQ-ORB-010.5).
- **Failure mapping.**
  - A propagation error of the library becomes the `PropagationException` of req-orb-009 with message E(N), where N is the library's error code: 1 to 6 as Vallado defines them, or 99 for a non-finite result.
  - An element set that the library rejects is reported by `stateAt`, never by the constructor, so building a propagator for parsed elements never throws. Every call of `stateAt` for that set throws the `PropagationException` with message I, after the instant check. The case is an inclination of exactly 180°: the parser accepts it, but the library rejects any inclination from π.

  The members of `PropagationException` stay those of req-orb-009 (Context, Exception, not error).
- **Gravity model (ADR-0003, decisions 4 and 6; ADR-0002, decision 6).** The adapter selects the library's WGS-72 model by name and declares no gravity-model constant. The operation mode is improved (`'i'`), fixed by the library. The official vectors confirm both choices: each is the mode they were generated with.
- **No state between calls.** The adapter holds its element set and the library's initialized engine, which is a function of the element set alone (req-orb-009, Context, No state between calls). The prototype asked the 588 instants forward and then backward on the same adapter: every number was equal.
- **Units.** Kilometres, kilometres per second, seconds and radians at the seam (Constitution principle 12). Degrees and revolutions per day exist only at the call into the library.
- **Cost.** The prototype measured 0.88 µs per state for NOAA 14 and 0.96 µs per state for a geostationary set, and 7.9 µs to build an adapter, on the development machine. That is far below the frame budget of Constitution principle 13. The figure is recorded, not tested; profiling belongs to req-sta-001.

## Definitions used by every requirement

These definitions are normative.

- **Adapter library file:** `packages/orbital_core/lib/src/sgp4_propagator.dart`.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Core manifest:** `packages/orbital_core/pubspec.yaml`.
- **Application lockfile:** `pubspec.lock`.
- **Dependency guard file:** `test/dependency_guard_test.dart`.
- **Math test file:** `packages/orbital_core/test/sgp4_propagator_test.dart`. It covers REQ-ORB-010.1 to .5.
- **Verification data file:** `packages/orbital_core/test/sgp4_verification_data.dart`.
- **Fixture TLE file:** `packages/orbital_core/test/fixtures/vallado/SGP4-VER.TLE`.
- **Fixture output file:** `packages/orbital_core/test/fixtures/vallado/tcppver.out`.
- **Guard test file:** `test/orbital_core_sgp4_guard_test.dart`, in the application suite. It covers REQ-ORB-010.6 to .9.
- **Spec file:** `specs/req-orb-010.md`.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.
- **Repository Dart files:** every file whose name ends in `.dart` under `lib`, `test`, `packages/orbital_core/lib` and `packages/orbital_core/test`, searched recursively.
- **Code line:** a line whose text, with leading spaces removed, does not start with `//`.
- **Library import line:** `import 'package:satellite_observer/satellite_observer.dart' as sgp4;`
- **Sources of the fixtures:**
  - **Fixture TLE file.** `sgp4/cpp/testsgp4/SGP4-VER.TLE` of the archive `https://celestrak.org/publications/AIAA/2006-6753/AIAA-2006-6753.zip`, with its CRLF line endings converted to LF and nothing else changed. The original has SHA-256 `d246d1d9d768ace445a38a965713fa9ba52d80fd8a41a0502ff83d7acffe2881`; the vendored copy has SHA-256 `1680b1d2c2eb323589d92e0870cc3bd69a637a91646b1e65d9e3c3ed6c2c825a` and 8506 bytes.
  - **Fixture output file.** `sgp4/tcppver.out` of python-sgp4 (Brandon Rhodes, MIT; `https://github.com/brandon-rhodes/python-sgp4`) at commit `0f06a9147333e5a82197b5c04f5e87b477deca9e`, the last commit that changed it. That file mirrors the C++ reference output of Vallado et al. and is copied unchanged: SHA-256 `687bf28dbe52df86e8e60ab5cb4a08d1aa3dbcaf4e63b1f7ab95f044fbe3833b`, 140162 bytes, LF line endings. The AIAA archive no longer contains `tcppver.out`.
- **Entry:** a line of the fixture TLE file that starts with `1 `, together with the next line, which starts with `2 `. The fixture TLE file holds 33 entries; catalog number 20413 appears in two of them.
- **Block:** a line of the fixture output file that contains ` xx`, together with the lines after it, up to the next such line, that have at least seven whitespace-separated fields. Block k belongs to entry k.
- **Accepted sets:** the entries whose catalog number, columns 3 to 7 of line 1, is not 33333, 33334 or 33335. There are 30 of them. Position p is the p-th accepted set in file order. The table gives the catalog number and the number of rows of each position:

  | p | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | Catalog | 5 | 4632 | 6251 | 8195 | 9880 | 9998 | 11801 | 14128 | 16925 | 20413 | 21897 | 22312 | 22674 | 23177 | 23333 |
  | Rows | 13 | 5 | 25 | 25 | 25 | 14 | 5 | 25 | 13 | 26 | 25 | 23 | 25 | 13 | 15 |

  | p | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | Catalog | 23599 | 24208 | 25954 | 26900 | 26975 | 28057 | 28129 | 28350 | 28623 | 28626 | 28872 | 29141 | 29238 | 88888 | 20413 |
  | Rows | 37 | 13 | 26 | 4 | 25 | 25 | 13 | 13 | 13 | 13 | 11 | 22 | 13 | 13 | 70 |

  The rows add up to 588.
- **Set lines:** the first 69 characters of each of the two lines of an entry. The text after column 69, which gives a start, stop and step in minutes, is not part of them.
- **Row text:** the first seven whitespace-separated fields of a line of a block, joined by one space each, with every field written exactly as in the fixture output file. The fields are tsince in minutes, then x, y and z of the TEME position in km, then x, y and z of the TEME velocity in km/s.
- **Row instant:** the epoch of the accepted set plus a `Duration` of tsince · 6·10⁷ microseconds, rounded to the nearest integer. Every tsince of the fixture output file is a whole number of microseconds, so the rounding changes no instant.
- **SGP4 adapter of a set:** the result of building the adapter of REQ-ORB-010.8 from `OrbitalElements.fromTle` of its two set lines.
- **NOAA 14:** lines `1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621` and `2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148495`, the CelesTrak example that req-orb-009 also uses.
- **Synthetic 180-degree set:** NOAA 14 with inclination 180.0000, built for this spec with valid checksums. It is not a published object. Lines: `1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621` and `2 23455 180.0000 272.6745 0008546 223.1686 136.8816 14.11711747148497`.
- **Exact:** compared with `==`, with no tolerance, so 0.0 and −0.0 compare equal.
- **Julian message U:** `Julian date conversion requires a UTC instant.`
- **Julian message R:** `Julian date conversion supports 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z only.`
- **Checksum message C:** `TLE line 1 has an invalid checksum.`
- **Initialization message I:** `SGP4 cannot initialize the element set.`
- **Error message E(N):** `SGP4 cannot propagate the element set to the instant: error code N.`, where N is the error code written in decimal with no leading zero.

## Functional Requirements

### REQ-ORB-010.1 — The adapter reproduces the official vectors

For every reference state of the 30 accepted sets, the TEME position and velocity of the adapter match `tcppver.out`.

**Acceptance (verified by the math test file).** The test reads the verification data file and builds the SGP4 adapter of each accepted set. For each row of the set's block, it asks the adapter for its state at the row instant. Each of the three position components is within 1·10⁻⁶ km of the row's value, and each of the three velocity components is within 2·10⁻⁹ km/s.

- The test counts 30 sets and 588 rows, and checks both counts.
- The largest differences measured were 2.62·10⁻⁷ km in position (position 30, catalog 20413, tsince 1844340) and 5.33·10⁻¹⁰ km/s in velocity.
- The reference prints velocity with 9 decimals, so its rounding alone reaches 5·10⁻¹⁰ km/s. The two bounds leave a margin of about 4 over the measurement.

### REQ-ORB-010.2 — SGP4 error codes become the failure type

When the library cannot propagate an accepted set to an instant, the adapter throws the `PropagationException` of req-orb-009 with message E(N).

**Acceptance (verified by the math test file).** For each row of the table, the SGP4 adapter of the set asked at the given instant throws an object that is a `PropagationException` of req-orb-009 and whose message is exactly the expected one. The instant is the epoch of the set plus a `Duration` of tsince · 6·10⁷ microseconds. Each tsince is one step after the last row of the set's block, the instant at which the reference output stops.

| Position | Catalog | tsince (min) | Expected message |
| --- | --- | --- | --- |
| 12 | 22312 | 494.2028672 | E(1) |
| 23 | 28350 | 1560 | E(1) |
| 26 | 28872 | 55 | E(6) |
| 27 | 29141 | 440 | E(6) |
| 30 | 20413 | 1844345 | E(6) |

All five measured as expected in the prototype.

### REQ-ORB-010.3 — The sets outside the parser stay outside

The three entries with an invalid checksum never reach the adapter.

**Acceptance (verified by the math test file).** For each of the entries with catalog numbers 33333, 33334 and 33335, `OrbitalElements.fromTle` of its set lines throws a `FormatException` whose message is exactly message C. This records why REQ-ORB-010.1 covers 30 entries and not 33. It changes nothing in req-orb-003.

### REQ-ORB-010.4 — Conformance to the seam

The adapter implements the interface of req-orb-009 and keeps its fixed semantics.

**Acceptance (verified by the math test file).** For each of the 588 states of REQ-ORB-010.1:

- **Instant.** The instant of the state equals the row instant (exact).
- **GMST.** GMST equals `gmstRad` of `JulianDate.fromUtc` of the row instant (exact).
- **ECEF.** Each component of the Earth-fixed position equals the same component of `ecefPositionKm` of the state's inertial position at the state's GMST (exact).
- **Finite.** All ten numbers of the state are finite: the three components of each of the position, the velocity and the Earth-fixed position, and GMST. GMST is from 0 inclusive to 2π exclusive.
- **No state between calls.** For each accepted set, one adapter is asked for every row instant in block order, and then again in reverse order. For every row, the ten numbers of the two states are exactly equal.

All 588 measured as listed in the prototype. Also:

- **Interface.** The SGP4 adapter of NOAA 14 is held in a variable whose static type is `Propagator`. At the epoch of NOAA 14 it returns an object that is a `PropagatedState`, and that is not a `KeplerPropagatedState`.
- **Elements.** The element set that the adapter exposes is identical (`identical`) to the one it was built from.

### REQ-ORB-010.5 — Invalid instants and element sets the library rejects

An instant that req-orb-001 rejects is rejected before the library is called. An element set that the library rejects is reported by `stateAt`, never by the constructor.

**Acceptance (verified by the math test file).** "Throws X" means the thrown object is an `ArgumentError` whose message is exactly X; "fails with X" means it is a `PropagationException` of req-orb-009 whose message is exactly X.

| Adapter built from | Instant | Expected |
| --- | --- | --- |
| NOAA 14 | 2026-11-08T00:00:00 as a local `DateTime`, not flagged as UTC | Throws message U |
| NOAA 14 | 1900-02-28T23:59:59.999999Z | Throws message R |
| NOAA 14 | 2100-03-01T00:00:00.000000Z | Throws message R |
| Synthetic 180-degree set | its epoch | Fails with message I |
| Synthetic 180-degree set | 2026-11-08T00:00:00 as a local `DateTime` | Throws message U |
| Synthetic 180-degree set | 2100-03-01T00:00:00.000000Z | Throws message R |

Building the adapter of the synthetic 180-degree set does not throw. The last two rows show that the instant is checked before the initialization failure is reported. In the prototype, the parser read that set's inclination as exactly π, and the library rejected it.

### REQ-ORB-010.6 — The verification data is the vendored originals

The data that the math test file reads is the content of the two vendored files, line for line.

**Acceptance (verified by the guard test file).**

- The fixture TLE file, the fixture output file and the verification data file exist.
- Neither fixture file contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM).
- The fixture TLE file holds 33 entries, and the fixture output file holds 33 blocks.
- The accepted sets are 30, their blocks hold 588 rows in total, and the catalog numbers and row counts are those of the Definitions table.
- A data line of the verification data file is a line whose text, with leading and trailing spaces removed, starts with `'`, ends with `',` and contains no other `'`. Its token is the text between the two quotes.
- The expected token sequence is built as follows. For each accepted set, in file order, it contains the two set lines, followed by the row text of every row of its block, in block order.
- The tokens of the data lines, in file order, equal the expected token sequence exactly: 648 tokens.

### REQ-ORB-010.7 — Placement and library boundary

The adapter lives in the core, is exported, is the only Dart file that imports the library, and composes GMST and ECEF as req-orb-009 fixes them.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- **Placement.**
  - The adapter library file exists.
  - The public library file contains the line `export 'src/sgp4_propagator.dart';`.
  - The adapter library file contains the library import line and the lines `import 'earth_fixed.dart';`, `import 'gmst.dart';`, `import 'julian_date.dart';`, `import 'orbital_elements.dart';`, `import 'propagator.dart';` and `import 'state_vector.dart';`.
- **Only the adapter imports the library.** No repository Dart file other than the adapter library file contains the substring `package:satellite_observer`. In the adapter library file:
  - the library import line is the only line that, with leading spaces removed, starts with `import 'package:`, `import "package:` or `export`;
  - no line contains `package:satellite_observer/src/`.
- **Composition at the seam.**
  - Each of the substrings `JulianDate.fromUtc(`, `gmstRad(`, `ecefPositionKm(`, `sgp4.GpElements.fromMeanElements(`, `sgp4.Sgp4Engine(`, `sgp4.GravityModel.wgs72`, `on sgp4.PropagationException` and `on sgp4.InvalidElementsException` appears on at least one code line of the adapter library file.
  - No code line of it contains any of the substrings `GpElements.fromTle(`, `GravityModel.wgs84`, `SatelliteObserver`, `Observer(`, `subPointAt`, `lookAngleAt` or `passes(`.
- **No copied gravity constants.** No code line of the adapter library file contains the substring `398600`, `6378` or `1082616`. The WGS-72 constants are the library's, selected by name (ADR-0002, decision 6).

The guard cannot prove that the conversions and the order of the calls are right. REQ-ORB-010.1, .4 and .5 prove the values.

### REQ-ORB-010.8 — Public names and documented contract

The documentation states the model, the gravity model, the elements, the output, the errors and the reference, so a reader learns them without opening this spec. The public names are fixed for req-sta-001.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- **Declaration.** The adapter library file contains the line `final class Sgp4Propagator implements Propagator {`. The class body is the lines after it, up to and not including the first line equal to `}`, compared with no spaces removed.
- **Doc block.** The doc block is the run of consecutive lines directly before the declaration line whose text, with leading and trailing spaces removed, starts with `///`. It contains each of these lines, in any order:
  - `/// Model: SGP4 and SDP4 of Vallado et al., Revisiting Spacetrack Report #3 (AIAA 2006-6753), as implemented by satellite_observer 1.0.1 (ADR-0002).`
  - `/// Gravity model: WGS-72, selected by name from the library; this adapter declares no gravity constant.`
  - `/// Operation mode: improved ('i'), fixed by the library and confirmed by the official vectors.`
  - `/// Elements: built from the fields of OrbitalElements, in degrees and revolutions per day; the TLE lines are not kept.`
  - `/// Output: TEME position in km and velocity in km/s; GMST and ECEF as Propagator defines them.`
  - `/// Errors: the ArgumentError of JulianDate.fromUtc, checked before the library is called; PropagationException when the library cannot initialize the element set or reports an SGP4 error code.`
  - `/// Reference: SGP4-VER.TLE and tcppver.out of Vallado et al., 30 element sets and 588 states (specs/req-orb-010.md).`
- **Members.**
  - The class body contains a line that, after trimming, starts with `Sgp4Propagator(this.elements)`.
  - It contains the lines `final OrbitalElements elements;` and `PropagatedState stateAt(DateTime utc) {`, and the line directly before each of them, after trimming, is `@override`.
  - Every line of the class body that starts with exactly two spaces followed by a character other than a space, other than a line whose text with leading spaces removed starts with `//` or `@` or is equal to `}`, satisfies one of three conditions:
    - it is one of the two lines above;
    - it starts, after trimming, with `Sgp4Propagator(this.elements)`;
    - its text before the first `(`, ` =` or `;` contains a word that starts with `_`.

    So every other member of the class has a private name, and the public names are the constructor, `elements` and `stateAt`.
- **Top-level declarations.** Every line of the adapter library file that has a character other than a space at its first column, compared with no spaces removed, meets one of these conditions:
  - it starts with `//`;
  - it starts with `import '`;
  - it is equal to `}`;
  - it is equal to the declaration line.

  Empty lines are allowed. So the file declares no other top-level name, and in particular no constant and no function.

### REQ-ORB-010.9 — Dependency pin, purity and test hygiene

The core declares exactly the one dependency of ADR-0002, at exactly its version and archive. The new code stays pure Dart, and the new test files follow the hygiene rules of req-orb-006 to req-orb-009.

**Acceptance (verified by the guard test file):**

- **Pin.**
  - Under `dependencies:`, the core manifest contains the line `  satellite_observer: 1.0.1`, compared with no spaces removed.
  - The application lockfile contains a package entry `satellite_observer:` whose block holds the line `sha256: "39c57843b8d92c6c9e63f362afb135973bd00956471ba50428801217661dca83"` and the line `version: "1.0.1"`, after trimming. The block is the lines after `  satellite_observer:`, up to the next line that starts with exactly two spaces followed by a character other than a space.
- **Purity.** No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- **Math test imports.** The math test file:
  - contains the lines `import 'package:orbital_core/orbital_core.dart';` and `import 'sgp4_verification_data.dart';`;
  - has no line, with leading spaces removed, that matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- **Data file has no import.** No line of the verification data file, with leading spaces removed, starts with `import` or `export`.
- **Citations.** The math test file and the verification data file each contain each of these four citation lines, compared after trimming:
  - `// Vallado, Crawford, Hujsak and Kelso, Revisiting Spacetrack Report #3, AIAA 2006-6753: SGP4-VER.TLE and tcppver.out.`
  - `// SGP4-VER.TLE: https://celestrak.org/publications/AIAA/2006-6753/AIAA-2006-6753.zip, sgp4/cpp/testsgp4/SGP4-VER.TLE, line endings converted to LF.`
  - `// tcppver.out: https://github.com/brandon-rhodes/python-sgp4, sgp4/tcppver.out at commit 0f06a9147333e5a82197b5c04f5e87b477deca9e.`
  - `// Synthetic 180-degree element set: NOAA 14 with inclination 180.0000, built for specs/req-orb-010.md with valid checksums; not a published object.`
- **Tags.**
  - For each N from 1 to 5, the math test file contains a line equal to `// REQ-ORB-010.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(` or `group(`.
  - For each N from 6 to 9, the guard test file contains a line equal to `// REQ-ORB-010.N` after trimming. The next non-empty line after it, with leading and trailing spaces removed, starts with `test(`.
  - The guard test file builds the tag strings of the math test file (`// REQ-ORB-010.1` to `.5`) by interpolation, never as literals, so that V10 prints only its own tags.
- **Self-matching tokens.** The guard test file builds the tokens `package:satellite_observer`, `Platform.script` and `skip:` by concatenation of shorter string literals, never as one literal. This keeps its checks from matching the guard itself.
- **No skipped tests.** Neither the math test file nor the guard test file contains the substring `skip:`.
- **Bytes.** None of the following contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the math test file, the verification data file, the guard test file, the core library files and the spec file.
- **Repository root.** The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- **Plain text only.** The guard test file reads files as plain text, using only the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser.
- **Missing files fail.** Each of the following produces a failing test when missing, never a skipped or passing one: the math test file, the verification data file, both fixture files, the adapter library file, the public library file, the core manifest, the application lockfile, the spec file and the `packages/orbital_core/lib` directory. A missing guard test file is caught by V4.
- **Failure messages.** Every failure message of the guard test file starts with `[REQ-ORB-010.N]`, where N is the requirement whose check failed, and carries `specs/req-orb-010.md` on the same line as that tag.

**Acceptance (verified by command V5).** The dependency guard file, as amended (REQ-INF-001.8 and REQ-INF-002.9, Amendment 1), passes. Its output contains the test name `orbital_core manifest declares only the ADR-0002 runtime dependency, no Flutter SDK and only the approved dev deps` verbatim. It allows exactly the runtime dependency `satellite_observer` at exactly `1.0.1` in the core manifest. Rows D1 to D3 below show that it fails otherwise.

**Acceptance (verified by command V11).** Compared with `main`, the pull request that implements this spec changes exactly the ten files of V11. The one allowed exception is the spec file: when the implementation needs a behaviour change, the pull request may also change `specs/req-orb-010.md`, with the developer's approval linked in its description (Constitution principle 2). V11 is a local check: CI does not run it, and the pull request checklist reports its result.

## Mathematical Validation / Testing

The adapter adds unit conversions and no other formula. REQ-ORB-010.1 checks the whole path against the published vectors of Vallado et al.: element set, conversions, library and state. That path runs from `OrbitalElements` to TEME, and it covers near-earth and deep-space sets, including resonant and geostationary orbits. REQ-ORB-010.4 checks GMST and ECEF by identity with the functions that req-orb-002 and req-orb-006 validated against published values. The inputs are cited by the citation lines of REQ-ORB-010.9:

- **Published:** `SGP4-VER.TLE` and `tcppver.out` of AIAA 2006-6753. REQ-ORB-010.6 proves that the data file equals the vendored copies, and V12 proves that the vendored copies equal the cited sources.
- **Synthetic 180-degree set:** a constructed input, not a reference value, used only for REQ-ORB-010.5.

All commands in this section run from a POSIX shell with GNU `sed`: Git Bash on Windows, or a shell on Linux. On macOS, the rows that use `sed -i` need GNU `sed` installed as `gsed` and called by that name. PowerShell lacks `grep`, `sed`, `sort`, `paste`, `sha256sum` and `printf` with byte escapes.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/sgp4_propagator_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-010.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 to req-orb-009 still pass |
| V4 | `flutter test test/orbital_core_sgp4_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-010.6 – .9 |
| V5 | `flutter test test/dependency_guard_test.dart --reporter expanded` | exit 0, and the output contains the test name of REQ-ORB-010.9 | REQ-ORB-010.9; REQ-INF-001.8 and REQ-INF-002.9 as amended |
| V6 | `flutter test` | exit 0 | REQ-ORB-010.6 – .9; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-010\.[0-9]+" packages/orbital_core/test/sgp4_propagator_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-ORB-010.1,// REQ-ORB-010.2,// REQ-ORB-010.3,// REQ-ORB-010.4,// REQ-ORB-010.5` | REQ-ORB-010.9 (tags of the math test file) |
| V10 | `grep -ohE "// REQ-ORB-010\.[0-9]+" test/orbital_core_sgp4_guard_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-ORB-010.6,// REQ-ORB-010.7,// REQ-ORB-010.8,// REQ-ORB-010.9` | REQ-ORB-010.9 (tags of the guard test file) |
| V11 | `git fetch origin main && git diff --name-only origin/main...HEAD \| LC_ALL=C sort \| paste -sd, -` | standard output `packages/orbital_core/lib/orbital_core.dart,packages/orbital_core/lib/src/sgp4_propagator.dart,packages/orbital_core/pubspec.yaml,packages/orbital_core/test/fixtures/vallado/SGP4-VER.TLE,packages/orbital_core/test/fixtures/vallado/tcppver.out,packages/orbital_core/test/sgp4_propagator_test.dart,packages/orbital_core/test/sgp4_verification_data.dart,pubspec.lock,test/dependency_guard_test.dart,test/orbital_core_sgp4_guard_test.dart`; or, only when the pull request links the developer's approval of a spec diff, the same list with `specs/req-orb-010.md` inserted after `pubspec.lock` | REQ-ORB-010.9 (only the files of this spec change) |
| V12 | `sha256sum packages/orbital_core/test/fixtures/vallado/SGP4-VER.TLE packages/orbital_core/test/fixtures/vallado/tcppver.out \| cut -c1-64 \| paste -sd, -` | standard output `1680b1d2c2eb323589d92e0870cc3bd69a637a91646b1e65d9e3c3ed6c2c825a,687bf28dbe52df86e8e60ab5cb4a08d1aa3dbcaf4e63b1f7ab95f044fbe3833b` | The vendored fixtures equal the cited sources (Definitions) |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

**Precondition of V11.** The implementation branch is created from `main` after the pull request of this spec was merged into `main` with a merge commit. That pull request carries the spec file, ADR-0002, the amendments of `specs/req-inf-001.md` and `specs/req-inf-002.md`, and the roadmap row. If the branch was created before that merge, or the spec pull request was squashed, those files appear in the diff. V11 then counts as not run, never as a pass or a failure, and the fix is to rebase the implementation branch onto `main`.

### Local negative checks

These run after every file of the implementation pull request is committed on the feature branch, so that the revert below restores each of them. Before G0, `git status --porcelain` must print nothing; otherwise stop, because the deletions and the revert would destroy uncommitted work.

The command of the G rows is:

    flutter test test/orbital_core_sgp4_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-010.md"

**Control run (G0).** With no edit applied, run the command once with `<tag>` replaced by each of `[REQ-ORB-010.6]`, `[REQ-ORB-010.7]`, `[REQ-ORB-010.8]` and `[REQ-ORB-010.9]`, and confirm that each prints nothing. A line printed here means that the output of a passing run, such as a test name, already carries a tag and the spec path, so the rows below would prove nothing; fix the guard test file before continuing.

Then, for each G row and each D row:

1. Apply the edit.
2. For a G row, run the command and confirm that it prints at least one line. For a D row, run `flutter test test/dependency_guard_test.dart` and confirm that it exits with a code other than 0.
3. Revert with `git checkout -- packages/orbital_core test specs pubspec.lock` before the next row.

The edits are defined as follows.

- "Delete the line X" and "Replace the line X with Y" act on every line that equals X after trimming. A replaced line keeps its indentation.
- "Replace every occurrence of X with Y" acts on every occurrence of the substring X, on the lines it names.
- "Append the line X" adds X as a new last line of the file.
- "Add X as the first line" inserts X before the first line of the file.
- "Insert the line X directly after (before) the line Y" inserts X after (before) every line that equals Y after trimming. X is inserted exactly as written, including any leading spaces it shows. "An empty line" is a line with no characters.
- "Delete the file" removes one tracked file.
- "Run" executes the command from the repository root.

Inside the table, `\|` is a single pipe. "The adapter file", "the public file", "the manifest", "the lockfile", "the data file", "the TLE fixture", "the output fixture", "the math test file" and "the guard test file" are the adapter library file, the public library file, the core manifest, the application lockfile, the verification data file, the fixture TLE file, the fixture output file, the math test file and the guard test file of Definitions.

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Delete the file `packages/orbital_core/test/fixtures/vallado/SGP4-VER.TLE` | `[REQ-ORB-010.6]` |
| G2 | Delete the file `packages/orbital_core/test/fixtures/vallado/tcppver.out` | `[REQ-ORB-010.6]` |
| G3 | Delete the file `packages/orbital_core/test/sgp4_verification_data.dart` | `[REQ-ORB-010.6]` |
| G4 | Replace every occurrence of `7022.46529266` with `7022.46529267` in the data file | `[REQ-ORB-010.6]` |
| G5 | Delete the line `'0.00000000 7022.46529266 -1400.08296755 0.03995155 1.893841015 6.405893759 4.534807250',` from the data file | `[REQ-ORB-010.6]` |
| G6 | Run `sed -i 's/$/\r/' packages/orbital_core/test/fixtures/vallado/SGP4-VER.TLE` (CRLF in the TLE fixture) | `[REQ-ORB-010.6]` |
| G7 | Append the line `99999 xx` to the output fixture | `[REQ-ORB-010.6]` |
| G8 | Add `import 'package:satellite_observer/satellite_observer.dart';` as the first line of the math test file | `[REQ-ORB-010.7]` |
| G9 | Add `import 'package:satellite_observer/satellite_observer.dart';` as the first line of `packages/orbital_core/lib/src/kepler_propagator.dart` | `[REQ-ORB-010.7]` |
| G10 | Replace the line `import 'package:satellite_observer/satellite_observer.dart' as sgp4;` with `import 'package:satellite_observer/satellite_observer.dart' as so;` in the adapter file | `[REQ-ORB-010.7]` |
| G11 | Add `import 'package:satellite_observer/src/propagation/sgp4/sgp4_engine.dart';` as the first line of the adapter file | `[REQ-ORB-010.7]` |
| G12 | Replace every occurrence of `sgp4.GravityModel.wgs72` with `sgp4.GravityModel.wgs84` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G13 | Append the line `  static const double _mu = 398600.8;` to the adapter file | `[REQ-ORB-010.7]` |
| G14 | Append the line `  static const double _re = 6378.135;` to the adapter file | `[REQ-ORB-010.7]` |
| G15 | Append the line `  static const double _j2 = 0.001082616;` to the adapter file | `[REQ-ORB-010.7]` |
| G16 | Replace every occurrence of `sgp4.GpElements.fromMeanElements(` with `sgp4.GpElements.fromTle(` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G17 | Replace every occurrence of `JulianDate.fromUtc(` with `JulianDate.fromLocal(` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G18 | Replace every occurrence of `gmstRad(` with `libraryGmst(` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G19 | Replace every occurrence of `ecefPositionKm(` with `temeToEcef(` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G20 | Replace every occurrence of `on sgp4.PropagationException` with `on Exception` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G21 | Replace every occurrence of `on sgp4.InvalidElementsException` with `on Object` on the code lines of the adapter file | `[REQ-ORB-010.7]` |
| G22 | Append the line `  final x = sgp4.SatelliteObserver;` to the adapter file | `[REQ-ORB-010.7]` |
| G23 | Delete the line `import 'state_vector.dart';` from the adapter file | `[REQ-ORB-010.7]` |
| G24 | Delete the line `export 'src/sgp4_propagator.dart';` from the public file | `[REQ-ORB-010.7]` |
| G25 | Delete the file `packages/orbital_core/lib/src/sgp4_propagator.dart` | `[REQ-ORB-010.7]` |
| G26 | Delete the line `/// Model: SGP4 and SDP4 of Vallado et al., Revisiting Spacetrack Report #3 (AIAA 2006-6753), as implemented by satellite_observer 1.0.1 (ADR-0002).` from the adapter file | `[REQ-ORB-010.8]` |
| G27 | Delete the line `/// Gravity model: WGS-72, selected by name from the library; this adapter declares no gravity constant.` from the adapter file | `[REQ-ORB-010.8]` |
| G28 | Delete the line `/// Operation mode: improved ('i'), fixed by the library and confirmed by the official vectors.` from the adapter file | `[REQ-ORB-010.8]` |
| G29 | Delete the line `/// Elements: built from the fields of OrbitalElements, in degrees and revolutions per day; the TLE lines are not kept.` from the adapter file | `[REQ-ORB-010.8]` |
| G30 | Delete the line `/// Output: TEME position in km and velocity in km/s; GMST and ECEF as Propagator defines them.` from the adapter file | `[REQ-ORB-010.8]` |
| G31 | Delete the line `/// Errors: the ArgumentError of JulianDate.fromUtc, checked before the library is called; PropagationException when the library cannot initialize the element set or reports an SGP4 error code.` from the adapter file | `[REQ-ORB-010.8]` |
| G32 | Delete the line `/// Reference: SGP4-VER.TLE and tcppver.out of Vallado et al., 30 element sets and 588 states (specs/req-orb-010.md).` from the adapter file | `[REQ-ORB-010.8]` |
| G33 | Replace the line `final class Sgp4Propagator implements Propagator {` with `final class Sgp4Adapter implements Propagator {` in the adapter file | `[REQ-ORB-010.8]` |
| G34 | Replace the line `PropagatedState stateAt(DateTime utc) {` with `PropagatedState stateAt(DateTime instant) {` in the adapter file | `[REQ-ORB-010.8]` |
| G35 | Replace the line `final OrbitalElements elements;` with `final OrbitalElements elementSet;` in the adapter file | `[REQ-ORB-010.8]` |
| G36 | Delete the line `@override` from the adapter file | `[REQ-ORB-010.8]` |
| G37 | Insert the line `  double speedKmS() => 0;` directly after the line `final OrbitalElements elements;` in the adapter file | `[REQ-ORB-010.8]` |
| G38 | Append the line `const double _degreesPerRadian = 57.29577951308232;` to the adapter file | `[REQ-ORB-010.8]` |
| G39 | Insert an empty line directly before the line `final class Sgp4Propagator implements Propagator {` in the adapter file | `[REQ-ORB-010.8]` |
| G40 | Replace the line `satellite_observer: 1.0.1` with `satellite_observer: ^1.0.1` in the manifest | `[REQ-ORB-010.9]` |
| G41 | Replace every occurrence of `39c57843b8d92c6c9e63f362afb135973bd00956471ba50428801217661dca83` with `0000000000000000000000000000000000000000000000000000000000000000` in the lockfile | `[REQ-ORB-010.9]` |
| G42 | Add `import 'dart:io';` as the first line of the adapter file | `[REQ-ORB-010.9]` |
| G43 | Add `import 'dart:io';` as the first line of the math test file | `[REQ-ORB-010.9]` |
| G44 | Add `import 'package:orbital_core/src/sgp4_propagator.dart';` as the first line of the math test file | `[REQ-ORB-010.9]` |
| G45 | Delete the line `import 'package:orbital_core/orbital_core.dart';` from the math test file | `[REQ-ORB-010.9]` |
| G46 | Delete the line `import 'sgp4_verification_data.dart';` from the math test file | `[REQ-ORB-010.9]` |
| G47 | Add `import 'dart:math';` as the first line of the data file | `[REQ-ORB-010.9]` |
| G48 | Delete the line `// Vallado, Crawford, Hujsak and Kelso, Revisiting Spacetrack Report #3, AIAA 2006-6753: SGP4-VER.TLE and tcppver.out.` from the math test file | `[REQ-ORB-010.9]` |
| G49 | Delete the line `// SGP4-VER.TLE: https://celestrak.org/publications/AIAA/2006-6753/AIAA-2006-6753.zip, sgp4/cpp/testsgp4/SGP4-VER.TLE, line endings converted to LF.` from the data file | `[REQ-ORB-010.9]` |
| G50 | Delete the line `// tcppver.out: https://github.com/brandon-rhodes/python-sgp4, sgp4/tcppver.out at commit 0f06a9147333e5a82197b5c04f5e87b477deca9e.` from the math test file | `[REQ-ORB-010.9]` |
| G51 | Delete the line `// Synthetic 180-degree element set: NOAA 14 with inclination 180.0000, built for specs/req-orb-010.md with valid checksums; not a published object.` from the math test file | `[REQ-ORB-010.9]` |
| G52 | Replace the line `// REQ-ORB-010.3` with `// REQ-ORB-010.x` in the math test file | `[REQ-ORB-010.9]` |
| G53 | Insert the line `// note` directly after the line `// REQ-ORB-010.1` in the math test file | `[REQ-ORB-010.9]` |
| G54 | Append the line `// skip: true` to the math test file | `[REQ-ORB-010.9]` |
| G55 | Run `sed -i 's/$/\r/' packages/orbital_core/test/sgp4_propagator_test.dart` (CRLF in the math test file) | `[REQ-ORB-010.9]` |
| G56 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/sgp4_verification_data.dart > /tmp/g56 && mv /tmp/g56 packages/orbital_core/test/sgp4_verification_data.dart` (BOM in the data file) | `[REQ-ORB-010.9]` |
| G57 | Run `sed -i 's/$/\r/' packages/orbital_core/lib/src/sgp4_propagator.dart` (CRLF in a core library file) | `[REQ-ORB-010.9]` |
| G58 | Run `sed -i 's/$/\r/' specs/req-orb-010.md` (CRLF in the spec file) | `[REQ-ORB-010.9]` |
| G59 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-010.9]` |
| G60 | Replace the line `// REQ-ORB-010.6` with `// REQ-ORB-010.x` in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-ORB-010.9]` |
| G61 | Insert the line `  // note` directly after the line `// REQ-ORB-010.7` in the guard test file | `[REQ-ORB-010.9]` |
| G62 | Delete the file `packages/orbital_core/test/sgp4_propagator_test.dart` | `[REQ-ORB-010.9]` |
| G63 | Delete the file `specs/req-orb-010.md` | `[REQ-ORB-010.9]` |
| G64 | Delete the file `pubspec.lock` | `[REQ-ORB-010.9]` |
| G65 | Run `rm -rf packages/orbital_core/lib` (delete the core library directory) | `[REQ-ORB-010.9]` |

| # | Edit (dependency guard, step 2 for D rows) |
| --- | --- |
| D1 | Insert the line `  meta: ^1.16.0` directly after the line `satellite_observer: 1.0.1` in the manifest |
| D2 | Replace the line `satellite_observer: 1.0.1` with `satellite_observer: ^1.0.1` in the manifest |
| D3 | Delete the line `satellite_observer: 1.0.1` from the manifest |

No G row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V4 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that implements this spec lists V1–V12, G0–G65 and D1–D3, each with its observed result. A pull request without this list is incomplete regardless of its check status. This checklist is the one manual step of this spec: a reviewer reads it, and no command verifies it.

## Edge Cases & Errors

- **Invalid instant.** A `DateTime` not flagged as UTC, or outside 1900-03-01T00:00:00.000000Z to 2100-02-28T23:59:59.999999Z, throws the `ArgumentError` of `JulianDate.fromUtc` with its message unchanged, before the library is called (REQ-ORB-010.5). Without that check, the library would silently convert a local time to UTC.
- **Element set the library rejects.** The parser accepts an inclination up to 180° inclusive; the library rejects an inclination from π. The adapter reports it at `stateAt` with message I, never at construction (REQ-ORB-010.5). The library's other element checks cover eccentricity outside 0 inclusive to 1 exclusive, a mean motion that is not positive and a non-finite value. A parsed set cannot fail them, but the same message covers them.
- **SGP4 error codes.** The library's codes 1 to 6, and its code 99 for a non-finite result, become message E(N) (REQ-ORB-010.2). Codes 1 and 6 are proved by the official vectors. Codes 3 and 4 appear only in the two entries that the parser rejects (REQ-ORB-010.3). Codes 2 and 99 appear in no published vector, so the mapping rule covers them without a test row. A decayed object (code 6) is a condition of the data. req-sta-001 decides how the globe shows it; this spec only reports it.
- **Sets outside the parser.** The three entries with an invalid checksum are rejected with message C by the parser of req-orb-003 (REQ-ORB-010.3), as for any TLE with a wrong checksum. This spec does not relax the parser.
- **Far from the epoch.** SGP4 accepts any valid instant until it reports an error code. Its accuracy decays with the age of the elements; the age warning of req-ui-004 guards against reading an old state as current, not this spec.
- **Deep space and resonance.** Sets with a period of 225 minutes or more use SDP4, including the resonant 12-hour and 24-hour orbits of the verification file. The prototype found no dependence on call order in any of the 30 sets (REQ-ORB-010.4). A future library version that keeps integrator state between calls must still meet that row.
- **Platform differences.** The tolerances of REQ-ORB-010.1 are about four times the largest measured difference. They allow for floating-point differences between the development machine, the CI runner and an Android device, and still reveal any real error of the model, which shows at the level of metres or more.
- **Mean elements.** SGP4 consumes the TLE mean elements and the Kozai mean motion, as the library converts them internally. The adapter passes them as they are, with no conversion of its own to Brouwer elements.
- **CRLF in the original fixture.** The CelesTrak original of `SGP4-VER.TLE` has CRLF line endings. The vendored copy is LF (V12, REQ-ORB-010.6), as `.gitattributes` (`* text=auto eol=lf`) also enforces on checkout. A CR byte means an editor saved the file with Windows line endings. The fix is to restore the LF copy, never to relax the test.
- **CRLF or BOM in the new files or the spec file.** Rejected by the guard test file (REQ-ORB-010.9). The fix is to rewrite the file as UTF-8 without BOM and with LF.
- **Network or CI runner failure.**
  - This spec adds no network access at run time.
  - `dart pub get` and `flutter pub get` now download `satellite_observer`. A failed download, a timeout, a runner out of memory or a failed analysis is handled as req-inf-002 defines and never counts as a pass.
  - V11 needs `git fetch`. If the fetch fails, or the precondition of V11 does not hold, V11 counts as not run.
  - If pub.dev withdrew the package, the exact pin and the archive hash of REQ-ORB-010.9 make the failure visible. ADR-0002 (Consequences) names the remedies, each of which needs a new ADR.
- **Library upgrade.** A new release of the library is never picked up silently, because of the exact pin and the archive hash. Moving to it changes the version in ADR-0002, in the doc line "Model" and in this spec, and the official vectors must pass again.
- **Large data file.** The verification data file holds 648 string literals. `dart format` keeps each literal on its own line, because every one exceeds the line width or ends a multi-line list, so the data-line rule of REQ-ORB-010.6 holds after formatting.
- **Missing guard test file.** The guard cannot report its own absence. V4 names the file explicitly, so `flutter test` exits with a non-zero code when it is missing, and V10 prints nothing.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell with GNU `sed`. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass. When the G edits are scripted in Git Bash on Windows, an argument that starts with `/`, such as a `///` or `//` line, is rewritten as a path before the program receives it, so the edit silently does nothing and the row reports a false failure. Disable that conversion (for example with `MSYS_NO_PATHCONV=1`) and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in the implementation pull request:

- An own SGP4 port, or any SGP4 arithmetic in `packages/orbital_core` (ADR-0002, Out of scope).
- Any part of the library other than the propagation layer: look angles, passes, visibility, geodesy, observers and its GMST (ADR-0002, decision 5).
- The Kepler versus SGP4 comparison, which is phase 2 of the Project Brief.
- Geodetic coordinates, the derived values of req-orb-008 and any Earth-relative velocity inside the state, as req-orb-009 excludes them.
- Any change to `packages/orbital_core/lib/src/propagator.dart`, `kepler_propagator.dart`, `orbital_elements.dart`, `tle_parser.dart`, `julian_date.dart`, `gmst.dart`, `elapsed_time.dart`, `kepler.dart`, `perifocal.dart`, `state_vector.dart`, `earth_fixed.dart`, `geodetic.dart` or `derived_values.dart`, or to their tests and guards. The parser keeps rejecting invalid checksums.
- OMM input, or a propagator that takes anything other than `OrbitalElements`.
- The catalog of tracked objects (req-dat-001), any provider (req-sta-001) and any code in the application `lib/`, provider or widget.
- Any change to the application `pubspec.yaml`, `.github/workflows/ci.yml`, `test/support/repo_root.dart`, the constitution or any ADR, ADR-0002 included. The only change to `test/dependency_guard_test.dart` is the one REQ-ORB-010.9 and the amended REQ-INF-001.8 and REQ-INF-002.9 require: allowing exactly `satellite_observer` at exactly `1.0.1`, and renaming its test.
- Any change to `specs/req-orb-010.md` in the implementation pull request, except a behaviour change approved by the developer (REQ-ORB-010.9, V11).
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
