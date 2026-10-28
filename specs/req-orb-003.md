# req-orb-003 — Orbital elements model and TLE parser

- **Status:** Draft (revision 2, after QA audit). Every published value was checked against a freely available primary source while drafting (see Definitions).
- **Roadmap row:** 5 of 33 (MVP)
- **Blocks:** req-orb-004 (Kepler equation solver), req-orb-005 (perifocal to inertial state vector), req-orb-009 (propagator interface), req-orb-010 (SGP4 adapter), req-dat-002 (CelesTrak GP client, which hands TLE text to this parser under ADR-0003)
- **Depends on:** req-orb-001 (UTC time base and Julian date), req-inf-002 (CI quality gates), ADR-0001 (baseline packages), ADR-0003 (TLE element sets and their units)
- **ADR:** ADR-0003 fixes the TLE input format and the bounded exception to Constitution principle 12 for B\*. It must be accepted by the developer before the implementation pull request merges. The work uses only the Dart core library inside `packages/orbital_core` and adds no dependency to either `pubspec.yaml`, so ADR-0001 is unchanged.

## Context & Objective

Every propagator in Wintek (the in-house Kepler propagator of req-orb-004 and req-orb-005, and the SGP4 adapter of req-orb-010) needs the same input: one set of orbital elements at one epoch. Until that set has a single agreed shape, each propagator would read CelesTrak text on its own and convert units on its own, and two propagators could disagree before either computes anything. This spec delivers what roadmap row 5 names: an immutable element set in radians and seconds, and a parser that builds it from the two lines of a NORAD Two-Line Element set (TLE) and rejects any line whose checksum does not match.

The decisions below are fixed so later specs inherit them. The first and the B\* part of the third come from ADR-0003; this spec does not decide them on its own.

- **Input format (ADR-0003).** The parser reads TLE text only: exactly two lines, line 1 and line 2. The name line that CelesTrak prepends (three-line format) is removed by the data layer (req-dat-002) before parsing. OMM in JSON or XML is not read by the core.
- **Content.** The element set holds the values SGP4 consumes: catalog number, epoch, inclination, right ascension of the ascending node, eccentricity, argument of perigee, mean anomaly, mean motion, the first and second mean-motion terms, and B\*. Classification, international designator, ephemeris type, element set number and revolution number are read past, not stored. The original text of the two lines is not stored either.
- **Units.** Constitution principle 12: angles in radians, time in seconds, mean motion in radians per second, the first mean-motion term in radians per second squared, the second in radians per second cubed. Eccentricity is dimensionless. B\* keeps the unit the TLE publishes, inverse Earth radii, under the bounded exception of ADR-0003.
- **Values as published (ADR-0003).** The mean motion is the Kozai mean motion published in the TLE, not the Brouwer mean motion SGP4 derives from it; req-orb-005 must know this when it derives the semi-major axis. The first and second mean-motion terms are the TLE values ṅ/2 and n̈/6, converted to SI units but not multiplied back to ṅ and n̈, which is how Vallado's SGP4 reader stores them.
- **Epoch.** The epoch is a UTC instant. The eight decimal digits of the TLE epoch day are a whole multiple of 10⁻⁸ day, which is exactly 864 µs, so the epoch is represented exactly at the microsecond resolution of req-orb-001 with no rounding. Two-digit epoch years follow Vallado's SGP4 reader: below 57 means 2000 plus the value, otherwise 1900 plus the value. Every epoch the format can express therefore lies from 1957 through 2056, inside the valid range of req-orb-001, so the epoch always converts to a two-part Julian date through REQ-ORB-001.1. No conversion from raw numbers to a Julian date is added.
- **Range validation (approved scope).** Roadmap row 5 names checksum validation. This spec also checks the pattern and the physical range of every stored field (REQ-ORB-003.5), because the checksum only proves that the text was transmitted intact, not that it makes sense: a correctly checksummed line can still carry day 366 of a common year or a mean motion of zero, and either would reach the epoch conversion or req-orb-005 unchecked. The developer approved this addition during the QA audit.

Parse failures throw Dart's `FormatException`, the standard type for malformed text, each with one exact message, in the same way REQ-ORB-001.4 fixes its `ArgumentError` messages.

## Definitions used by every requirement

These definitions are normative.

- **CelesTrak format:** T. S. Kelso, CelesTrak, "NORAD Two-Line Element Set Format", `https://celestrak.org/NORAD/documentation/tle-fmt.php`. It defines the columns, the assumed decimal points and the checksum rule, and publishes the NOAA 14 example.
- **Vallado SGP4:** D. A. Vallado, P. Crawford, R. Hujsak and T. S. Kelso, "Revisiting Spacetrack Report #3", AIAA 2006-6753, with its source code archive `AIAA-2006-6753.zip`, published free of charge at `https://celestrak.org/publications/AIAA/2006-6753/`. Within the archive:
  - `sgp4/cpp/testsgp4/SGP4-VER.TLE` holds the verification element sets;
  - `sgp4/cpp/testsgp4/TestSGP4/<set>.e` holds the reference ephemeris of each set, whose `ScenarioEpoch` line publishes the epoch of the set;
  - the function `twoline2rv` in `sgp4/cpp/SGP4/SGP4/SGP4.cpp` holds the reader: `deg2rad = pi / 180`, `xpdotp = 1440 / (2 pi)` (revolutions per day to radians per minute), and the epoch year rule "below 57 is 2000 plus the year, otherwise 1900 plus the year";
  - the element record in `sgp4/cpp/SGP4/SGP4/SGP4.h` and `twoline2rv` name the published mean motion `no_kozai`, which is the source of the statement that the TLE mean motion is the Kozai mean motion.
- **Character:** one UTF-16 code unit, which is how Dart strings are indexed and measured.
- **Digit:** one of the ASCII characters `0` to `9` (U+0030 to U+0039). No other Unicode digit counts.
- **Printable ASCII:** a character from U+0020 (space) to U+007E (`~`), both inclusive.
- **Column:** a 1-based character position in a line, as in the CelesTrak format. "Columns a–b" is the substring from column a through column b, both inclusive, taken without trimming.
- **Prepared line:** an input line with every trailing space (U+0020), tab (U+0009) and carriage return (CR, U+000D) removed. Leading characters are never removed. Every check below runs on prepared lines.
- **Checksum of a line:** the sum, over columns 1–68, of each digit's value, plus 1 for each minus sign (`-`); every other character counts 0. The result is taken modulo 10. It matches when it equals the digit in column 69.
- **Fields.** Each field occupies the columns below, must match its pattern (a regular expression applied to the untrimmed column substring), and is converted to the stored value as stated. "Assumed-decimal exponent" means: the first character is the sign (space or plus is positive, minus is negative), the next five characters are the digits after an assumed leading decimal point, and the last two characters are a signed power of ten; for example ` 12891-6` is +0.12891 · 10⁻⁶.

| Line | Columns | Field name (used in messages) | Pattern | Stored value |
| --- | --- | --- | --- | --- |
| 1 | 3–7 | `catalog number` | `^[0-9]{5}$` | Whole number |
| 1 | 19–20 | `epoch year` | `^[0-9]{2}$` | Calendar year by the epoch year rule of Context |
| 1 | 21–32 | `epoch day` | `^[0-9]{3}\.[0-9]{8}$` | Combined with the epoch year into the epoch (UTC instant): day 1.0 is 00:00:00Z on 1 January |
| 1 | 34–43 | `first derivative of mean motion` | `^[ +-]\.[0-9]{8}$` | ṅ/2 in revolutions per day squared, times 2π / 86400², in radians per second squared |
| 1 | 45–52 | `second derivative of mean motion` | `^[ +-][0-9]{5}[+-][0-9]$` | n̈/6 by assumed-decimal exponent, in revolutions per day cubed, times 2π / 86400³, in radians per second cubed |
| 1 | 54–61 | `B*` | `^[ +-][0-9]{5}[+-][0-9]$` | By assumed-decimal exponent, in inverse Earth radii, unchanged (ADR-0003) |
| 2 | 3–7 | `catalog number` | `^[0-9]{5}$` | Whole number |
| 2 | 9–16 | `inclination` | `^ *[0-9]+\.[0-9]{4}$` | Degrees times π / 180, in radians |
| 2 | 18–25 | `right ascension of the ascending node` | `^ *[0-9]+\.[0-9]{4}$` | Degrees times π / 180, in radians |
| 2 | 27–33 | `eccentricity` | `^[0-9]{7}$` | The digits after an assumed leading decimal point, dimensionless |
| 2 | 35–42 | `argument of perigee` | `^ *[0-9]+\.[0-9]{4}$` | Degrees times π / 180, in radians |
| 2 | 44–51 | `mean anomaly` | `^ *[0-9]+\.[0-9]{4}$` | Degrees times π / 180, in radians |
| 2 | 53–63 | `mean motion` | `^ *[0-9]+\.[0-9]{8}$` | Revolutions per day times 2π / 86400, in radians per second |

- **Field ranges (on the published value, before conversion):** epoch day from 1.0 inclusive to the number of days of the epoch year plus 1 exclusive (366 in a common year, 367 in a leap year); inclination from 0 through 180 degrees, both inclusive; right ascension of the ascending node, argument of perigee and mean anomaly from 0 inclusive to 360 degrees exclusive; mean motion strictly greater than 0. The other fields have no range beyond their pattern; eccentricity lies from 0 inclusive to 1 exclusive by its pattern alone.
- **Converted values:** the nine values of the field table that are neither the catalog number nor part of the epoch: first derivative of mean motion, second derivative of mean motion, B\*, inclination, right ascension of the ascending node, eccentricity, argument of perigee, mean anomaly and mean motion.
- **Element set:** the immutable value produced by the parser, holding the catalog number (once, since both lines must agree), the epoch and the nine converted values.
- **Equal element sets:** two element sets whose catalog numbers are the same whole number, whose epochs are the same UTC instant at microsecond resolution, and whose nine converted values are pairwise equal when compared with `==` on doubles, with no tolerance.
- **Close to:** for a converted value, equal to the expected value within a relative tolerance of 1·10⁻¹² (the absolute difference is at most 1·10⁻¹² times the absolute expected value), or equal with `==` when the expected value is 0.0.
- **Elements library file:** `packages/orbital_core/lib/src/orbital_elements.dart`.
- **Parser library file:** `packages/orbital_core/lib/src/tle_parser.dart`.
- **Public library file:** `packages/orbital_core/lib/orbital_core.dart`.
- **Math test file:** `packages/orbital_core/test/tle_parser_test.dart`.
- **Guard test file:** `test/orbital_core_elements_guard_test.dart`, in the application suite.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.

## Functional Requirements

### REQ-ORB-003.1 — Parse published element sets

Two valid TLE lines yield an element set whose values are the published fields converted as the Definitions state.

**Acceptance (verified by the math test file).** Each set is passed to the parser as two separate lines, written as string literals in the math test file; the test reads no file. For the Vallado sets, the lines are the first 69 characters of the corresponding lines of `SGP4-VER.TLE`, which appends run-control columns after column 69.

| Set | Line 1 | Line 2 | Source |
| --- | --- | --- | --- |
| NOAA 14 | `1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621` | `2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148495` | CelesTrak format, example |
| 00005 | `1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753` | `2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667` | Vallado SGP4, `SGP4-VER.TLE` |
| 23599 | `1 23599U 95029B   06171.76535463  .00085586  12891-6  12956-2 0  2905` | `2 23599   6.9327   0.2849 5782022 274.4436  25.2425  4.47796565123555` | Vallado SGP4, `SGP4-VER.TLE` |
| 28129 | `1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459` | `2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443` | Vallado SGP4, `SGP4-VER.TLE` |

For every set, the catalog number equals the published number exactly, and each converted value is close to the value below. The values are the published fields multiplied by the factors of Vallado's reader (Definitions); they introduce no new formula.

| Set | Inclination (rad) | RAAN (rad) | Eccentricity | Arg. of perigee (rad) | Mean anomaly (rad) | Mean motion (rad/s) | ṅ/2 (rad/s²) | n̈/6 (rad/s³) | B\* (1/Earth radii) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| NOAA 14 | 1.7280330391070657 | 4.759067811229278 | 0.0008546 | 3.895026857066217 | 2.38903460539787 | 0.001026625753092966 | 1.178366586030122·10⁻¹⁵ | 0.0 | 1.0191·10⁻⁴ |
| 00005 | 0.5980929187319208 | 6.08638547138321 | 0.1859667 | 5.790416027488515 | 0.3373093125574321 | 0.000787157424012976 | 1.935887962763772·10⁻¹⁶ | 0.0 | 2.8098·10⁻⁵ |
| 23599 | 0.12099844105301087 | 0.004972443038931845 | 0.5782022 | 4.78994443102631 | 0.44056473643466865 | 0.00032564685159878337 | 7.203691616569574·10⁻¹³ | 1.2558137946853755·10⁻²¹ | 1.2956·10⁻³ |
| 28129 | 0.9552152089579925 | 5.669000452744278 | 0.0048506 | 4.647183479530182 | 1.6260586869007931 | 0.00014585336077139677 | −8.753580353366621·10⁻¹⁶ | 0.0 | 1.0·10⁻⁴ |

### REQ-ORB-003.2 — Epoch

The epoch year and epoch day yield the exact UTC instant of the epoch, and that instant converts to a two-part Julian date through REQ-ORB-001.1.

**Acceptance (verified by the math test file).** "Exactly" means equal as UTC instants at microsecond resolution, with no tolerance. Each row is parsed together with the line 2 of the same set in REQ-ORB-003.1. Rows marked "derived" change only the columns named in a published line and recompute column 69 so the checksum matches; the full lines are given so the test needs no helper.

| Line 1 | Epoch (UTC, exactly) | Source | Proves |
| --- | --- | --- | --- |
| NOAA 14 line 1 of REQ-ORB-003.1 | 1997-11-16T21:49:37.360416Z | Derived from the CelesTrak day-of-year definition | Year 97 is 1997; day 320 of a common year is 16 November |
| 00005 line 1 of REQ-ORB-003.1 | 2000-06-27T18:50:19.733568Z | Vallado SGP4, `00005.e`: `27 Jun 2000 18:50:19.733567999` | Year 00 is 2000 |
| 23599 line 1 of REQ-ORB-003.1 | 2006-06-20T18:22:06.640032Z | Vallado SGP4, `23599.e`: `20 Jun 2006 18:22: 6.640031999` | Year 06 is 2006 |
| 28129 line 1 of REQ-ORB-003.1 | 2006-06-24T13:41:49.461504Z | Vallado SGP4, `28129.e`: `24 Jun 2006 13:41:49.461503999` | Fraction resolved to the microsecond |
| `1 23455U 94089A   57320.90946019  .00000140  00000-0  10191-3 0  2627` (derived: year 57) | 1957-11-16T21:49:37.360416Z | Derived from the CelesTrak day-of-year definition and Vallado's year rule | 57 is the first year of the 1900s |
| `1 23455U 94089A   56320.90946019  .00000140  00000-0  10191-3 0  2626` (derived: year 56) | 2056-11-15T21:49:37.360416Z | Derived from the CelesTrak day-of-year definition and Vallado's year rule | 56 is the last year of the 2000s; day 320 of a leap year is 15 November |
| `1 00005U 58002B   00366.78495062  .00000023  00000-0  28098-4 0  4751` (derived: day 366) | 2000-12-31T18:50:19.733568Z | Derived from the CelesTrak day-of-year definition | Day 366 exists in a leap year |

The published `ScenarioEpoch` values carry nanosecond digits printed from a double; rounded to the nearest microsecond they equal the expected epochs, which are exact by the 864 µs property of Context. For every row, the epoch converts through REQ-ORB-001.1 without throwing.

### REQ-ORB-003.3 — Checksum

A line is accepted only when its checksum matches column 69. Minus signs count 1 and plus signs count 0.

**Acceptance (verified by the math test file).**

- Every line of REQ-ORB-003.1 and REQ-ORB-003.2 is accepted, including 28129 line 1, whose three minus signs contribute 3 to its checksum.
- Each row below is rejected or accepted as stated. Line 2 is the line 2 of the same set in REQ-ORB-003.1, unless the row says otherwise.

| Input | Expected |
| --- | --- |
| Line 1 `1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2622` (NOAA 14, column 69 changed from 1 to 2) | Throws C-1 |
| Line 2 `2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148496` (NOAA 14, column 69 changed from 5 to 6) | Throws C-2 |
| Line 1 `1 28129U 03058A   06175.57071136 +.00000104  00000-0  10000-3 0   459` (28129, column 34 changed from minus to plus, checksum unchanged) | Throws C-1 |
| Line 1 `1 28129U 03058A   06175.57071136 +.00000104  00000-0  10000-3 0   458` (same change, checksum recomputed) | Accepted; ṅ/2 is close to +8.753580353366621·10⁻¹⁶ rad/s² |

### REQ-ORB-003.4 — Structural validation, order and exact messages

The parser rejects malformed input by throwing Dart's `FormatException` and returns no value. Checks run in this order and the first failure wins:

1. Line 1: printable ASCII, then length, then line number, then checksum.
2. Line 2: printable ASCII, then length, then line number, then checksum.
3. Line 1 fields, left to right (REQ-ORB-003.5).
4. Line 2 fields, left to right (REQ-ORB-003.5); the catalog number match runs right after the line 2 catalog number field passes.

Messages, where N is 1 or 2 and is the line that failed:

- **Message A-N:** `TLE line N must contain printable ASCII characters only.`
- **Message L-N:** `TLE line N must be 69 characters long.`
- **Message P-N:** `TLE line N must start with "N ".`
- **Message C-N:** `TLE line N has an invalid checksum.`
- **Message M:** `TLE lines 1 and 2 must have the same catalog number.`

The printable ASCII check fails when the prepared line contains any character that is not printable ASCII. Length is measured in characters on the prepared line. The line number check requires column 1 to be the digit N and column 2 to be a space.

**Acceptance (verified by the math test file).** "Throws X" means the thrown object is a `FormatException` whose `message` is equal to message X, character for character. Lines are those of NOAA 14 in REQ-ORB-003.1 unless stated. Characters outside printable ASCII are written in the math test file as escape sequences inside string literals, never as raw bytes.

| Input | Expected |
| --- | --- |
| Line 1 preceded by U+FEFF (byte order mark) | Throws A-1 |
| Line 1 with column 33 (a space) replaced by a tab (U+0009) | Throws A-1 |
| Line 2 with column 17 (a space) replaced by U+00B0 (°) | Throws A-2 |
| Line 1 with its last character removed (68 characters) | Throws L-1 |
| Line 1 with the character `0` appended (70 characters) | Throws L-1 |
| Line 1 followed by a CR, and line 2 followed by two spaces and a CR | Accepted; the element set is equal to the NOAA 14 element set parsed from the lines of REQ-ORB-003.1 |
| Line 2 passed as line 1, and line 2 as line 2 | Throws P-1 |
| Line 1 as line 1, and line 1 passed as line 2 | Throws P-2 |
| Line 2 with its last character removed | Throws L-2 |
| Line 2 `2 23456  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148496` (catalog 23456, checksum recomputed) | Throws M |
| Line 1 with its last character removed, and the line 2 of REQ-ORB-003.3 that throws C-2 | Throws L-1 (line 1 is checked first) |
| The line 1 of REQ-ORB-003.5 that throws F-1 for `B*`, and the line 2 of REQ-ORB-003.3 that throws C-2 | Throws C-2 (structure is checked before fields) |
| Both lines empty | Throws L-1 |

### REQ-ORB-003.5 — Field validation

Each field must match its pattern and lie in its range (Definitions). For each field, the pattern is checked before the range.

- **Message F-N:** `TLE line N has an invalid FIELD field.`
- **Message R-N:** `TLE line N has an out-of-range FIELD field.`

FIELD is the field name of the field table, written exactly as there.

**Acceptance (verified by the math test file).** All lines below are NOAA 14 lines with the change named and column 69 recomputed, so that every row reaches the field check; the other line is the NOAA 14 line of REQ-ORB-003.1.

| Input | Expected |
| --- | --- |
| Line 1 `1 2345AU 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2626` | Throws F-1 with FIELD `catalog number` |
| Line 1 `1 23455U 94089A   9 320.90946019  .00000140  00000-0  10191-3 0  2624` | Throws F-1 with FIELD `epoch year` |
| Line 1 `1 23455U 94089A   97000.90946019  .00000140  00000-0  10191-3 0  2626` | Throws R-1 with FIELD `epoch day` |
| Line 1 `1 23455U 94089A   97366.90946019  .00000140  00000-0  10191-3 0  2621` | Throws R-1 with FIELD `epoch day` (1997 is a common year) |
| Line 1 `1 23455U 94089A   97320.90946019  .00000140  00000x0  10191-3 0  2620` | Throws F-1 with FIELD `second derivative of mean motion` |
| Line 1 `1 23455U 94089A   97320.90946019  .00000140  00000-0  1019 -3 0  2620` | Throws F-1 with FIELD `B*` |
| Line 2 `2 23455 180.0000 272.6745 0008546 223.1686 136.8816 14.11711747148497` | Accepted; inclination is close to π |
| Line 2 `2 23455 180.0001 272.6745 0008546 223.1686 136.8816 14.11711747148498` | Throws R-2 with FIELD `inclination` |
| Line 2 `2 23455  99.0090 360.0000 0008546 223.1686 136.8816 14.11711747148491` | Throws R-2 with FIELD `right ascension of the ascending node` |
| Line 2 `2 23455  99.0090 272.6745 0 08546 223.1686 136.8816 14.11711747148495` | Throws F-2 with FIELD `eccentricity` |
| Line 2 `2 23455  99.0090 272.6745 0008546 223.1686 136.8816  0.00000000148491` | Throws R-2 with FIELD `mean motion` |

### REQ-ORB-003.6 — Immutability

An element set never changes after it is created: it has no setter and no field that can be reassigned. Methods that return a new element set with some values changed are allowed, because they leave the original untouched.

**Acceptance (verified by the guard test file).** No line of the elements library file, with leading and trailing spaces removed, starts with `set `, `var ` or `late `.

**Acceptance (verified by review, item R1 of the pull request checklist).** The reviewer confirms, by reading the elements library file, that every field of the element set is final and that no setter exists. The guard catches the common forms; the review catches the rest (for example, a non-final field declared with an explicit type).

### REQ-ORB-003.7 — Placement and documented contract

The element set lives in the elements library file and the parser in the parser library file. Both are reachable through the public library file, and their documentation states the units, the meaning of the published values, the epoch rule, the checksum rule and the reference, so a reader of the package learns them without opening this spec.

**Acceptance (verified by the guard test file).** A line matches when, with leading and trailing spaces removed, it is equal to the string character for character.

- The elements library file and the parser library file exist.
- The public library file contains the lines `export 'src/orbital_elements.dart';` and `export 'src/tle_parser.dart';`.
- The elements library file contains each of these three lines:
  - `/// Units: radians, seconds and radians per second; B* in inverse Earth radii.`
  - `/// Mean motion: the Kozai mean motion published in the TLE.`
  - `/// Mean motion terms: the TLE values of ndot / 2 and nddot / 6, in SI units.`
- The parser library file contains each of these three lines:
  - `/// Epoch years: 57 to 99 are 1957 to 1999; 00 to 56 are 2000 to 2056.`
  - `/// Checksum: digits count their value, minus signs count 1, all else 0, modulo 10.`
  - `/// Reference: CelesTrak, NORAD Two-Line Element Set Format.`

### REQ-ORB-003.8 — Purity, citations and test hygiene

The element set and the parser add no dependency, every published value is cited in the math test file, and the new test files follow the hygiene rules of req-orb-002.

**Acceptance (verified by the guard test file):**

- No line of any core library file, with leading spaces removed, matches the regular expression `^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]`.
- The math test file contains the line `import 'package:orbital_core/orbital_core.dart';`.
- No line of the math test file, with leading spaces removed, matches `^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]`.
- The math test file contains each of these four citation lines, compared after trimming:
  - `// CelesTrak, NORAD Two-Line Element Set Format, https://celestrak.org/NORAD/documentation/tle-fmt.php: NOAA 14 (23455) example.`
  - `// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005, 23599 and 28129.`
  - `// Vallado et al., AIAA 2006-6753, SGP4.cpp twoline2rv: deg2rad = pi / 180, xpdotp = 1440 / (2 pi), years below 57 are 2000 + yy.`
  - `// Vallado et al., AIAA 2006-6753, TestSGP4/00005.e, 23599.e, 28129.e: ScenarioEpoch of each set.`
- The math test file contains, for each N from 1 to 5, a line equal to `// REQ-ORB-003.N` after trimming, and the next non-empty line after it starts with `test(` or `group(`.
- The guard test file contains, for each N in {6, 7, 8}, a line equal to `// REQ-ORB-003.N` after trimming, and the next non-empty line after it starts with `test(`.
- Neither the math test file nor the guard test file contains the substring `skip:`.
- None of the math test file, the guard test file and the core library files contains the byte `0D` (CR), and none starts with the bytes `EF BB BF` (UTF-8 BOM).
- The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- A missing math test file, elements library file, parser library file, public library file or `packages/orbital_core/lib` directory produces a failing test, never a skipped or passing one. A missing guard test file is caught by V4, which then exits with a non-zero code.
- Every failure message of the guard test file is a single line that starts with `[REQ-ORB-003.N]`, where N is the requirement whose check failed, and contains `specs/req-orb-003.md`.

**Acceptance (verified by command):** `flutter test test/dependency_guard_test.dart` exits with code 0.

## Mathematical Validation / Testing

Every published value is cited next to its assertion in the math test file by the citation lines of REQ-ORB-003.8, which the guard test file checks (Constitution principle 6):

- The converted values of REQ-ORB-003.1 are the published fields multiplied by the factors of Vallado's reader (π / 180 for degrees; 2π / 86400 per day, which is `1 / xpdotp` per minute expressed per second).
- The epochs of the Vallado sets in REQ-ORB-003.2 are published in their `.e` files. The epochs of NOAA 14 and of the derived rows follow from the CelesTrak day-of-year definition and Vallado's year rule.
- The derived lines of REQ-ORB-003.2 to REQ-ORB-003.5 change only the named columns of a published line and recompute column 69 by the checksum rule.

None of these introduces a new formula.

All commands in this section run from a POSIX shell: Git Bash on Windows, or any shell on Linux or macOS.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root unless stated) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `dart test test/tle_parser_test.dart --reporter expanded`, inside `packages/orbital_core` | exit 0 | REQ-ORB-003.1 – .5 |
| V2 | `dart analyze --fatal-infos`, inside `packages/orbital_core` | exit 0 | Constitution principle 8 |
| V3 | `dart test`, inside `packages/orbital_core` | exit 0 | Constitution principle 3; req-orb-001 and req-orb-002 still pass |
| V4 | `flutter test test/orbital_core_elements_guard_test.dart --reporter expanded` | exit 0 | REQ-ORB-003.6 – .8 |
| V5 | `flutter test test/dependency_guard_test.dart` | exit 0 | REQ-ORB-003.8 |
| V6 | `flutter test` | exit 0 | REQ-ORB-003.6 – .8; earlier guards still pass |
| V7 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V8 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V9 | `grep -ohE "// REQ-ORB-003\.[0-9]+" packages/orbital_core/test/tle_parser_test.dart test/orbital_core_elements_guard_test.dart \| sort -u \| wc -l` (inside the table, `\|` is a single pipe) | standard output `8` | REQ-ORB-003.8 |

The CI workflow of req-inf-002 runs V2, V3 and V6–V8 on every pull request.

### Local negative checks (guard test only)

These run after both test files are committed on the feature branch. For each row, apply the edit, run the command below, and confirm that it prints at least one line. That line carries both the expected tag and the spec path. Then revert with `git checkout -- packages/orbital_core test` before the next row.

    flutter test test/orbital_core_elements_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-orb-003.md"

| # | Edit | Tag expected in output |
| --- | --- | --- |
| G1 | Add `import 'dart:io';` as the first line of the elements library file | `[REQ-ORB-003.8]` |
| G2 | Add `import "dart:io";` (double quotes) as the first line of the parser library file | `[REQ-ORB-003.8]` |
| G3 | Add `export 'package:flutter/foundation.dart';` as the first line of the parser library file | `[REQ-ORB-003.8]` |
| G4 | Delete the line `/// Units: radians, seconds and radians per second; B* in inverse Earth radii.` from the elements library file | `[REQ-ORB-003.7]` |
| G5 | Delete the line `/// Mean motion: the Kozai mean motion published in the TLE.` from the elements library file | `[REQ-ORB-003.7]` |
| G6 | Delete the line `/// Mean motion terms: the TLE values of ndot / 2 and nddot / 6, in SI units.` from the elements library file | `[REQ-ORB-003.7]` |
| G7 | Delete the line `/// Epoch years: 57 to 99 are 1957 to 1999; 00 to 56 are 2000 to 2056.` from the parser library file | `[REQ-ORB-003.7]` |
| G8 | Delete the line `/// Checksum: digits count their value, minus signs count 1, all else 0, modulo 10.` from the parser library file | `[REQ-ORB-003.7]` |
| G9 | Delete the line `/// Reference: CelesTrak, NORAD Two-Line Element Set Format.` from the parser library file | `[REQ-ORB-003.7]` |
| G10 | Delete the line `export 'src/orbital_elements.dart';` from the public library file | `[REQ-ORB-003.7]` |
| G11 | Delete the line `export 'src/tle_parser.dart';` from the public library file | `[REQ-ORB-003.7]` |
| G12 | Add `import '../lib/orbital_core.dart';` to the math test file | `[REQ-ORB-003.8]` |
| G13 | Add `import 'package:orbital_core/src/tle_parser.dart';` to the math test file | `[REQ-ORB-003.8]` |
| G14 | Add `import 'dart:io';` to the math test file | `[REQ-ORB-003.8]` |
| G15 | Replace `// REQ-ORB-003.3` with `// REQ-ORB-003.x` in the math test file | `[REQ-ORB-003.8]` |
| G16 | Insert the line `print(0);` right after the line `// REQ-ORB-003.1` in the math test file | `[REQ-ORB-003.8]` |
| G17 | Delete the CelesTrak citation line of REQ-ORB-003.8 from the math test file | `[REQ-ORB-003.8]` |
| G18 | Delete the `SGP4-VER.TLE` citation line of REQ-ORB-003.8 from the math test file | `[REQ-ORB-003.8]` |
| G19 | Delete the `twoline2rv` citation line of REQ-ORB-003.8 from the math test file | `[REQ-ORB-003.8]` |
| G20 | Delete the `ScenarioEpoch` citation line of REQ-ORB-003.8 from the math test file | `[REQ-ORB-003.8]` |
| G21 | Append the line `// skip: true` to the math test file | `[REQ-ORB-003.8]` |
| G22 | Run `sed -i 's/$/\r/' packages/orbital_core/test/tle_parser_test.dart` (CRLF) | `[REQ-ORB-003.8]` |
| G23 | Run `printf '\xEF\xBB\xBF' \| cat - packages/orbital_core/test/tle_parser_test.dart > /tmp/g23 && mv /tmp/g23 packages/orbital_core/test/tle_parser_test.dart` (BOM; inside the table, `\|` is a single pipe) | `[REQ-ORB-003.8]` |
| G24 | Append the line `// Platform.script` to the guard test file | `[REQ-ORB-003.8]` |
| G25 | Delete the file `packages/orbital_core/test/tle_parser_test.dart` | `[REQ-ORB-003.8]` |
| G26 | Delete the file `packages/orbital_core/lib/src/tle_parser.dart` | `[REQ-ORB-003.7]` |
| G27 | Delete the file `packages/orbital_core/lib/src/orbital_elements.dart` | `[REQ-ORB-003.7]` |
| G28 | Delete the file `packages/orbital_core/lib/orbital_core.dart` | `[REQ-ORB-003.7]` |
| G29 | Run `rm -r packages/orbital_core/lib` | `[REQ-ORB-003.8]` |
| G30 | Append the line `  var mutable = 0;` to the elements library file | `[REQ-ORB-003.6]` |
| G31 | Append the line `  set mutable(double value) {}` to the elements library file | `[REQ-ORB-003.6]` |
| G32 | Append the line `  late double mutable;` to the elements library file | `[REQ-ORB-003.6]` |

**Pull request checklist.** The description of the pull request that closes this spec lists V1–V9 and G1–G32, each with its observed result, and the review item below. A pull request without this list is incomplete regardless of its check status.

- **R1:** the reviewer confirms REQ-ORB-003.6 (review acceptance): every field of the element set is final and no setter exists. Methods that return a changed copy are allowed.

## Edge Cases & Errors

- **Name line.** A three-line set passed as two lines puts the name line where line 1 belongs. It fails the length check (L-1) or the line number check (P-1), never parses silently. Stripping the name line is req-dat-002's job (ADR-0003).
- **Windows line endings and trailing blanks.** Removed by line preparation (REQ-ORB-003.4, CR row), because a payload saved with CRLF must not fail as "wrong length". Leading blanks are not removed: they would shift every column.
- **Byte order mark, tabs and non-ASCII characters in the input.** A payload decoded with a leading BOM, a tab inside a line, or any character outside printable ASCII (for example a pasted `°`) fails with A-N before any other check, so the message names the real problem instead of a misleading length or checksum error. The BOM is never stripped silently, because that would hide a corrupted cache.
- **CR and non-ASCII characters in the math test file.** The rows of REQ-ORB-003.4 that need a CR, a tab, U+FEFF or U+00B0 write them as escape sequences inside string literals, never as raw characters, because the guard test file rejects the byte `0D` and a leading BOM in that file (REQ-ORB-003.8).
- **Extra columns after column 69.** Vallado's `SGP4-VER.TLE` appends run-control values to line 2. The parser rejects such a line (L-2); the test uses the first 69 characters.
- **Column separators.** Spaces between fields (columns 2, 8, 18, 33, 44, 53, 62, 64 of line 1 and 2, 8, 17, 26, 34, 43, 52 of line 2) are not validated beyond the printable ASCII check and the checksum, which counts them as 0. Classification, international designator, ephemeris type, element set number and revolution number are not validated either; they are not stored.
- **Alpha-5 catalog numbers.** A letter in the catalog number field (the Alpha-5 scheme for numbers above 99999) fails the pattern (F-1 or F-2). The four tracked objects have five-digit numbers; supporting Alpha-5 requires a new ADR (ADR-0003).
- **Epoch outside 1957–2056.** Not expressible in a two-digit TLE year. Every expressible epoch is inside the valid range of req-orb-001, so the conversion of REQ-ORB-001.1 never rejects a parsed epoch. If it ever does, the parser is defective and is the one to fix; req-orb-001 is not changed by this spec.
- **Day 366 of a common year, day 0.** Rejected as out of range (R-1, `epoch day`). Day 366 of a leap year is accepted (REQ-ORB-003.2).
- **Inclination of exactly 180 degrees.** Accepted (REQ-ORB-003.5). Angles of exactly 360 degrees are rejected: the format publishes them as 0.
- **Eccentricity near 1 or zero mean motion.** Eccentricity cannot reach 1 by its pattern. Zero mean motion is rejected (R-2). Whether a valid element set is propagable (for example, decayed or hyperbolic after perturbation) is the propagator's concern, not the parser's.
- **Negative zero.** A field published as `-.00000000` or `-00000-0` yields −0.0, which is equal to 0.0 under `==` and therefore close to an expected 0.0.
- **Stale element sets.** The epoch age is not checked here; age thresholds belong to req-dat-004 and req-ui-004.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Network or CI runner failure.** This spec adds no network access. A CI failure caused by the runner (timeout, out of memory, failed `dart pub get`) is handled as defined in req-inf-002 and never counts as a pass.
- **Shell.** The commands of Mathematical Validation / Testing need a POSIX shell. Run in PowerShell, they fail with "command not found"; that is an environment error, never a pass.

## Out of Scope

Nothing below is written in this pull request:

- OMM in JSON or XML, the three-line name line, the Alpha-5 catalog scheme, or any other input format (ADR-0003).
- Storing the original TLE text, the classification, the international designator, the ephemeris type, the element set number or the revolution number.
- A public way to build an element set from plain values rather than from TLE text. If req-orb-004 or req-orb-005 needs it (for example, for Curtis examples given as classical elements), that spec adds it together with its own validation.
- The Earth radius or any other gravity-model constant, and any conversion of B\* to inverse kilometres (req-orb-010, ADR-0003).
- The semi-major axis, the Brouwer mean motion, or any value derived from the elements (req-orb-005, req-orb-008, req-orb-010).
- Advancing the mean anomaly to a time t, or the elapsed time between two epochs (req-orb-004).
- Writing a TLE back out, or computing a checksum for output.
- Any data age threshold or staleness check (req-dat-004, req-ui-004).
- Any network, file or cache access (req-dat-002, req-dat-003).
- Any change to the Julian date conversion of req-orb-001, to GMST of req-orb-002, or to their tests and guards.
- Any code in the application `lib/`, any provider, widget or UI string.
- Any change to `pubspec.yaml`, `packages/orbital_core/pubspec.yaml`, `.github/workflows/ci.yml`, `test/dependency_guard_test.dart`, `test/support/repo_root.dart`, the constitution, ADR-0001 or ADR-0002. ADR-0003 is written alongside this spec, not in the implementation pull request.
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
