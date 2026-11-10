# req-dat-001 — Satellite catalog

- **Status:** Draft (revision 2), after the first QA audit, pending a second audit.
  - **Approved before drafting (2026-11-10):**
    - GOES-East as a role name with a fixed NORAD ID: 60133, the catalog number of GOES 19;
    - minimal identity per entry: a stable key, a display name and the NORAD ID, in a fixed order;
    - validation by the constants themselves and by one CelesTrak TLE snapshot per object, parsed by the parser of req-orb-003. This goes beyond the "domain constants" of roadmap row 13, and the developer approved it as an extension;
    - a dated note in ADR-0003 and the closure of the open GOES-East item of the Project Brief, both in the pull request of this spec.
  - **Approved for revision 2 (2026-11-10):**
    - the snapshot is captured while drafting this spec and fixed in it, token for token (audit findings 1, 2, 4, 9 and 17);
    - the Project Brief is not checked by the guard, so no test carries Spanish text (finding 8);
    - the display names are `ISS`, `Tiangong`, `FASat-Charlie` and `GOES-East` (finding 10);
    - following the audit recommendation (finding 12), the general domain boundary is left to req-dat-004.

    Findings 3, 5 to 7, 11, 13 to 16, 18, 21 and 22 are fixed in the text. Finding 19 no longer applies, and finding 20 needed no change.
- **Roadmap row:** 13 of 33 (MVP)
- **Blocks:**
  - req-dat-002: requests the element sets of exactly these four catalog numbers;
  - req-dat-004: tells which object a cached element set belongs to;
  - req-sta-001: builds one state per tracked object;
  - req-viz-005 and req-ui-003: draw one marker per object and show its name on the card.
- **Depends on:**
  - req-orb-003: `OrbitalElements.fromTle`, its `catalogNumber` and its five-digit catalog-number field;
  - req-inf-001 and req-inf-002: both suites, the CI gates, the `lib/domain` directory of the scaffold and `test/support/repo_root.dart`;
  - ADR-0003, decision 1: TLE only, five-digit catalog numbers, and the GOES-East number left to this spec.
- **ADR:** none new. This spec confirms decision 1 of ADR-0003 instead of superseding it, and records that confirmation as a dated note in ADR-0003 (REQ-DAT-001.5). The decisions of ADR-0003 are unchanged.
- **No new dependency and no formula.** The catalog adds no package to either manifest and no mathematics, so Constitution principle 6 is not triggered. The TLE snapshot is identity evidence, not a reference value (REQ-DAT-001.3).

## Context & Objective

Roadmap row 13 asks to "fix the four tracked objects and their NORAD IDs as domain constants, closing the open GOES-East question before any request is written". The Project Brief names the four objects. It gives three NORAD IDs and leaves the fourth "por confirmar en CelesTrak". ADR-0003 decision 1 makes the gap binding: the core reads only five-digit catalog numbers, and "the catalog number of GOES-East is fixed by req-dat-001, which must confirm that it has five digits or propose an ADR that supersedes this decision".

Every later layer needs the same four identities. req-dat-002 requests them, req-dat-004 files their element sets, req-sta-001 propagates them, and the globe and the card draw and name them. This spec puts the four identities in one place, the domain layer, so no other library file repeats a catalog number.

### The GOES-East question, closed

GOES-East is an operational role of NOAA at 75.2° W, not a satellite. GOES-19 (GOES-U, launched 2024-06-25) replaced GOES-16 in that role on 2025-04-07, and still held it when this spec was drafted (NOAA NESDIS, "NOAA's GOES-19 Now Operational as GOES East, Providing Critical New Data to Forecasters"). CelesTrak SATCAT lists it as `GOES 19`, international designator 2024-119A, NORAD catalog number **60133**, perigee 35783 km and apogee 35789 km.

60133 has five digits, so decision 1 of ADR-0003 holds and needs no superseding ADR. Its CelesTrak TLE, fixed in Definitions, has a mean motion of 1.00272638 revolutions per day, which is a geostationary orbit.

### Decisions approved before drafting

- **Role name, fixed ID.** The object is shown as `GOES-East`, and its NORAD ID is 60133. The app never resolves the role at run time. If NOAA moves another satellite into the role, changing the ID is a change of this spec, as is any other row of the catalog.
- **Minimal identity.** Each entry carries a stable key, the display name and the NORAD ID. The order of the entries is fixed and is the display order. Colours (req-ui-001), CelesTrak URLs and request policy (req-dat-002), orbit classes and international designators are not part of the catalog. The table in Definitions shows the designators and orbit classes for information only.
- **Short display names.** The brief lists `Tiangong (CSS)` and `FASat-Charlie (SSOT)`. The display names drop the aliases in parentheses so they fit on the card and on a marker label. The CelesTrak names stay in the CelesTrak name column and in the snapshot.
- **Identity proved by real data.** The constants are checked against themselves (REQ-DAT-001.1 and .2). They are also checked against one CelesTrak TLE per object, parsed by `OrbitalElements.fromTle` (REQ-DAT-001.3). This proves that each ID names an element set that CelesTrak served and the core accepts. It is also the first time that real CelesTrak data passes through the parser of req-orb-003.
- **Snapshot fixed in the spec.** The snapshot was captured while drafting this spec and is written in Definitions, token for token. The developer certifies its provenance by approving the spec. The guard then proves that the data file equals the spec (REQ-DAT-001.6), so the implementer needs no network and no reviewer has to trust a fetch made by hand.
- **Paper trail.** The confirmation is recorded in two places outside this spec. ADR-0003 gets a dated note under its Consequences, and the guard keeps it there (REQ-DAT-001.5). The Project Brief gets the ID in its table and its open item ticked. That edit is made once, in the pull request of this spec, and checked by command V11, not by a test. The brief is written in Spanish, which predates this spec and is a deviation from Constitution principle 12. A guard that fixed its lines would put Spanish text into a test and block its translation. Translating the brief is not part of this spec.

### Decisions that follow from the Constitution

- **Domain, with no imports.** The catalog is domain data (Constitution principle 5: `domain` depends only on `orbital_core`). It needs nothing at all, so its file imports nothing: not Flutter, not `orbital_core`, not even a `dart:` library. Domain, data and presentation can then all read it, and none of them pulls a dependency through it.
- **Layout.** `AGENTS.md` and the Project Brief speak of feature-first layers. The scaffold of req-inf-001 created the layer directories `lib/domain`, `lib/data` and `lib/presentation` at the top level, and this spec uses `lib/domain` as it exists. Reconciling the wording of `AGENTS.md` with the scaffold is a separate change.
- **One source of truth.** No application library file other than the catalog, and no file of the core library, contains any of the four catalog numbers (REQ-DAT-001.4). The core stays generic: it parses any five-digit TLE and knows no tracked object. The rule binds later specs: req-dat-002 builds its request URLs from the catalog, not from literals. A later spec that needs one of these literals in a library file must amend this rule in a revision of this spec.
- **Good CelesTrak citizen (principle 10).** Each of the four GP requests was made once, while drafting. No test fetches, and the implementation fetches nothing. Nothing in this spec runs on the network at app run time.

## Definitions used by every requirement

These definitions are normative.

- **Catalog library file:** `lib/domain/satellite_catalog.dart`.
- **Application library files:** every file whose name ends in `.dart` under `lib`, searched recursively.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.
- **Unit test file:** `test/domain/satellite_catalog_test.dart`, in the application suite. It covers REQ-DAT-001.1 to .3.
- **Snapshot data file:** `test/domain/celestrak_tle_snapshot.dart`.
- **Guard test file:** `test/satellite_catalog_guard_test.dart`, in the application suite. It covers REQ-DAT-001.4 to .6.
- **Spec file:** `specs/req-dat-001.md`.
- **ADR file:** `docs/adr/ADR-0003-tle-element-sets-and-units.md`.
- **Brief file:** `docs/Wintek— Project Brief.md`. The character after `Wintek` is U+2014 EM DASH, followed by one space. Only command V11 reads it.
- **Line match:** a line matches a string when, with leading and trailing spaces removed, it is equal to the string character for character.
- **Code line:** a line whose text, with leading spaces removed, does not start with `//`.
- **Tracked objects:** the four rows of this table, in this order. Position, key, display name, NORAD ID and CelesTrak name are normative. The last two columns are for information only and appear in no file of the implementation.

  | Position | Key | Display name | NORAD ID | CelesTrak name | Designator (info) | Orbit (info, Project Brief) |
  | --- | --- | --- | --- | --- | --- | --- |
  | 1 | `iss` | `ISS` | 25544 | `ISS (ZARYA)` | 1998-067A | LEO, ~51.6° |
  | 2 | `tiangong` | `Tiangong` | 48274 | `CSS (TIANHE)` | 2021-035A | LEO, ~41.5° |
  | 3 | `fasatCharlie` | `FASat-Charlie` | 38011 | `SSOT` | 2011-076E | LEO sun-synchronous, ~97.8° |
  | 4 | `goesEast` | `GOES-East` | 60133 | `GOES 19` | 2024-119A | Geostationary, 75.2° W |

  The CelesTrak name is the satellite name of the CelesTrak SATCAT record of the NORAD ID, as checked on 2026-11-10. It is also the name line that CelesTrak GP data returns, without its trailing spaces.
- **GP request of an object:** `https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE`.
- **SATCAT record of an object:** `https://celestrak.org/satcat/records.php?CATNR=<NORAD ID>`.
- **Snapshot block:** the lines strictly between the first line equal to ` ```text ` (three backticks followed by `text`, with no spaces) after the line `Snapshot tokens, in file order:` of the spec file, and the next line equal to three backticks. Each line of the block is one snapshot token, compared character for character with no spaces removed. The block holds 12 tokens.
- **Snapshot entry k**, for position k from 1 to 4: the tokens 3k−2, 3k−1 and 3k. They are the three lines of the response to the GP request of the object at position k:
  - the name line, with its trailing spaces removed;
  - line 1;
  - line 2.

  Lines 1 and 2 are written exactly as CelesTrak returned them, with no change of any character. The CR bytes of the response are not part of any token.

Snapshot tokens, in file order:

```text
ISS (ZARYA)
1 25544U 98067A   26314.17503267  .00009346  00000+0  17575-3 0  9996
2 25544  51.6322 297.6644 0007292   8.9462 351.1656 15.49289712594382
CSS (TIANHE)
1 48274U 21035A   26314.02396249  .00022456  00000+0  25655-3 0  9991
2 48274  41.4671 155.8173 0004612 284.6802  75.3526 15.61635786315941
SSOT
1 38011U 11076E   26314.33139071  .00001795  00000+0  22861-3 0  9994
2 38011  97.7897  11.1277 0001573  84.0255 343.7714 14.82749444806034
GOES 19
1 60133U 24119A   26314.28750544 -.00000239  00000+0  00000+0 0  9994
2 60133   0.0034  70.9232 0000669 225.8123 141.0578  1.00272638  8428
```

- **Provenance of the snapshot.** Each GP request was made once on 2026-11-10, while drafting this spec:
  - entries 1 to 3 at 2026-11-10T16:00:20Z, with `curl -fsS`;
  - entry 4 earlier the same day, through a web reader. It was not requested again, to respect Constitution principle 10.

  Before they were written here, all eight element lines were checked: each has 69 characters and a valid checksum, and `OrbitalElements.fromTle` of req-orb-003 parsed each pair with the expected catalog number. The epochs run from 2026-11-10T00:34:30Z (entry 2) to 2026-11-10T07:57:12Z (entry 3).
- **Data line:** a line of the snapshot data file whose text, with leading and trailing spaces removed, starts with `'`, ends with `',` and contains no other `'`. Its token is the text between the two quotes.
- **NESDIS source:** `https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters`.

## Functional Requirements

### REQ-DAT-001.1 — The four tracked objects

The catalog holds exactly the four tracked objects, in display order, with their display names and NORAD IDs.

**Acceptance (verified by the unit test file):**

- The catalog has exactly four entries.
- In catalog order, the keys of the entries are `iss`, `tiangong`, `fasatCharlie` and `goesEast`.
- The display name and the NORAD ID of each entry are exactly those of its row in the Definitions table.

### REQ-DAT-001.2 — Catalog invariants

The catalog keeps the properties that later specs rely on, even if a row is changed by a later revision of this spec.

**Acceptance (verified by the unit test file):**

- Every NORAD ID is from 1 to 99999 inclusive. This is the range that ADR-0003 decision 1 and the parser of req-orb-003 accept, written with five digits in a TLE. 0 names no object.
- The four NORAD IDs are distinct.
- The four display names are distinct and not empty, and each one is equal to itself with leading and trailing spaces removed.

So a replacement GOES-East with an Alpha-5 catalog number fails here, and the failure points at ADR-0003.

### REQ-DAT-001.3 — Each NORAD ID is the catalog number of its CelesTrak snapshot

Each ID is the catalog number of the element set that CelesTrak served for that object and that the core parses.

**Acceptance (verified by the unit test file).** The test reads the one public list of the snapshot data file (REQ-DAT-001.6), which holds exactly 12 strings. For each position k from 1 to 4:

- string 3k−2 is exactly the CelesTrak name of position k;
- `OrbitalElements.fromTle` of strings 3k−1 and 3k, as lines 1 and 2, does not throw;
- the `catalogNumber` of the result equals the NORAD ID of the catalog entry at position k.

The guard proves that these strings are the snapshot tokens of the spec (REQ-DAT-001.6). The snapshot proves identity only. Its epochs and elements are not reference values for any formula, and no test compares a position, a period or an orbit class derived from it.

### REQ-DAT-001.4 — Placement, purity and documented contract

The catalog lives in the domain layer, imports nothing, is the only library file that holds the four catalog numbers, and documents its source.

**Acceptance (verified by the guard test file):**

- **Placement.** The catalog library file exists.
- **No imports.** No line of the catalog library file, with leading spaces removed, starts with `import`, `export` or `part`.
- **One source of truth.**
  - No application library file other than the catalog library file contains any of the substrings `25544`, `48274`, `38011` or `60133`.
  - No core library file contains any of them.
- **Display names as literals.** For each display name D of the Definitions table, at least one code line of the catalog library file contains `'D'`, that is, D between single quotes.
- **Declaration.** The catalog library file contains the line `enum TrackedObject {`. The enum body is the lines after it, up to and not including the first line equal to `}`, compared with no spaces removed.
- **Doc block.** The doc block is the run of consecutive lines directly before the declaration line whose text, with leading and trailing spaces removed, starts with `///`. It contains each of these lines, in any order:
  - `/// The four objects that Wintek tracks, in display order (specs/req-dat-001.md).`
  - `/// NORAD ID: the catalog number from 1 to 99999 that OrbitalElements.catalogNumber reads from a TLE, where it has five digits (ADR-0003, decision 1).`
  - `/// Source: CelesTrak SATCAT, checked on 2026-11-10: ISS (ZARYA), CSS (TIANHE), SSOT and GOES 19.`
  - `/// GOES-East is a role, filled by GOES 19 (2024-119A) since 2025-04-07; a change of satellite is a change of specs/req-dat-001.md, never a runtime lookup.`
- **Members.**
  - The enum body contains the lines `final String displayName;` and `final int noradId;`, by line match.
  - Each line of the enum body that starts with exactly two spaces followed by a character other than a space meets one of these conditions. Lines whose text, with leading spaces removed, starts with `//` or `@` are exempt.
    - It matches one of the two field lines above.
    - With leading spaces removed, it starts with `iss(`, `tiangong(`, `fasatCharlie(`, `goesEast(` or `const TrackedObject(`.
    - Its head contains a word that starts with `_`. The head is the text before the earliest occurrence, at any position, of any of `(`, ` =` or `;`; the whole line if none occurs.

    So the public names are the four values, `displayName` and `noradId`; any other member is private.
- **Top-level declarations.** Every line of the catalog library file that has a character other than a space at its first column, compared with no spaces removed, meets one of these conditions:
  - it starts with `//`;
  - it is equal to `}`;
  - it is equal to the declaration line.

  Empty lines are allowed. So the file declares no other top-level name: no constant, no function and no lookup table.

### REQ-DAT-001.5 — The confirmation is recorded in ADR-0003

The confirmation is recorded in the ADR whose decision asked for it.

**Acceptance (verified by the guard test file).** The ADR file contains a line that matches `- **Note (2026-11-10, req-dat-001):** GOES-East is GOES 19, catalog number 60133, which has five digits. Decision 1 holds and no superseding ADR is needed.` The line directly before it, with leading spaces removed, starts with `- Catalog numbers above 99999 (Alpha-5) are not supported.`

The note lands in the pull request of this spec, together with the edit of the brief file that V11 checks. Both are already on `main` when the implementation branch is created, and the implementation pull request changes neither file (V10).

### REQ-DAT-001.6 — Snapshot fidelity and test hygiene

The snapshot data file is the snapshot of the spec, in the shape that REQ-DAT-001.3 reads. The new test files follow the hygiene rules of req-orb-006 to req-orb-010.

**Acceptance (verified by the guard test file):**

- **Snapshot fidelity.**
  - The spec file has a snapshot block of exactly 12 tokens.
  - The snapshot data file holds exactly 12 data lines.
  - Their tokens, in file order, are equal to the 12 snapshot tokens of the spec file, in order.
- **Snapshot structure.** Every line of the snapshot data file that has a character other than a space at its first column, compared with no spaces removed, meets one of these conditions:
  - it starts with `//`;
  - it is equal to `];`;
  - it is the one declaration line, which starts with `const List<String> `, ends with ` = [` and has no `_` between those two parts.

  Exactly one line is a declaration line, and exactly one line is equal to `];`. So the file declares one public list of strings and nothing else.
- **Snapshot citations.** The snapshot data file contains a line that matches each of:
  - `// Source: CelesTrak GP data, https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, one request per object (specs/req-dat-001.md).`, where `<NORAD ID>` is written literally;
  - `// Fetched: 2026-11-10, once per object while drafting specs/req-dat-001.md; no test fetches it again.`
  - `// Identity snapshot: its epochs and elements are not reference values for any formula (Constitution principle 6).`
- **Unit test citations.** The unit test file contains a line that matches each of:
  - `// Catalog source: CelesTrak SATCAT, https://celestrak.org/satcat/records.php?CATNR=<NORAD ID>, checked on 2026-11-10.`, where `<NORAD ID>` is written literally;
  - `// GOES-East: GOES 19 since 2025-04-07, https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters`
- **Imports.**
  - The unit test file contains the lines `import 'package:flutter_test/flutter_test.dart';`, `import 'package:orbital_core/orbital_core.dart';`, `import 'package:wintek/domain/satellite_catalog.dart';` and `import 'celestrak_tle_snapshot.dart';`, by line match. No other line of it, with leading spaces removed, starts with `import` or `export`.
  - No line of the snapshot data file, with leading spaces removed, starts with `import` or `export`.
  - Neither file contains the substring `dart:io`.
- **Tags.**
  - For each N from 1 to 3, the unit test file contains a line that matches `// REQ-DAT-001.N`. Let L be the next non-empty line after it, with leading spaces removed. L starts with `group('REQ-DAT-001.N ` or `test('REQ-DAT-001.N `. Alternatively, L is equal to `group(` or `test(`, and the next line after L, with leading spaces removed, starts with `'REQ-DAT-001.N `. The second form allows for `dart format` moving a long description to its own line. Either way, the requirement ID starts the name of every unit test under the tag, so every failing unit test names it (rows U1 to U9).
  - For each N from 4 to 6, the guard test file contains a line that matches `// REQ-DAT-001.N`. The next non-empty line after it, with leading spaces removed, starts with `test(`.
  - The guard test file contains no line that matches `// REQ-DAT-001.1`, `// REQ-DAT-001.2` or `// REQ-DAT-001.3`. It builds those tags and the name prefixes of the unit test file by interpolation, never as literals, so that V6 prints only its own tags.
- **Self-matching tokens.** The guard test file builds the tokens `Platform.script` and `skip:` by concatenation of shorter string literals, never as one literal.
- **No skipped tests.** Neither the unit test file nor the guard test file contains the substring `skip:`.
- **Bytes.** None of these files contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the catalog library file, the unit test file, the snapshot data file, the guard test file, the spec file and the ADR file.
- **Repository root.** The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- **Plain text only.** The guard test file reads files as plain text with the Dart core and `dart:io` libraries of the application suite. It uses no YAML, Markdown or other external parser.
- **Missing files fail.** Each of the following produces a failing test when missing, never a skipped or passing one: the catalog library file, the `lib` directory, the `packages/orbital_core/lib` directory, the unit test file, the snapshot data file, the spec file and the ADR file. A missing guard test file is caught by V2.
- **Failure messages.** Every failure message of the guard test file starts with `[REQ-DAT-001.N]`, where N is the requirement whose check failed, and carries `specs/req-dat-001.md` on the same line as that tag.

**Acceptance (verified by command V10).** Compared with `main`, the pull request that implements this spec changes exactly the four files of V10. The one allowed exception is the spec file: when the implementation needs a behaviour change, the pull request may also change `specs/req-dat-001.md`, with the developer's approval linked in its description (Constitution principle 2). V10 is a local check: CI does not run it, and the pull request checklist reports its result.

## Mathematical Validation / Testing

This spec adds no formula, so there is nothing to check against Vallado or Curtis, and Constitution principle 6 is not triggered. Its evidence is identity:

- The catalog numbers and names are those of the CelesTrak SATCAT records, and the GOES-East role is that of the NESDIS source, both cited in the unit test file.
- The snapshot of Definitions is what CelesTrak served, as its provenance records; the developer certifies it by approving this spec.
- REQ-DAT-001.6 proves that the data file equals that snapshot.
- REQ-DAT-001.3 proves that each number is the catalog number that the req-orb-003 parser reads from it.

All commands in this section run from a POSIX shell with GNU `sed`: Git Bash on Windows, or a shell on Linux. PowerShell lacks `grep`, `sed`, `sort`, `paste` and `printf` with byte escapes.

### Writing the snapshot data file

The implementer copies the 12 snapshot tokens of Definitions into the snapshot data file, one data line each, in order. The implementation makes no network request. A copy that changes a single character fails REQ-DAT-001.6 (rows G20 to G22).

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root) | Expected | Proves |
| --- | --- | --- | --- |
| V1 | `flutter test test/domain/satellite_catalog_test.dart --reporter expanded` | exit 0 | REQ-DAT-001.1 – .3 |
| V2 | `flutter test test/satellite_catalog_guard_test.dart --reporter expanded` | exit 0 | REQ-DAT-001.4 – .6 |
| V3 | `flutter test` | exit 0 | All of the above; earlier guards and `test/dependency_guard_test.dart` still pass |
| V4 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V5 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V6 | `grep -ohE "// REQ-DAT-001\.[0-9]+" test/satellite_catalog_guard_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-001.4,// REQ-DAT-001.5,// REQ-DAT-001.6` | REQ-DAT-001.6 (tags of the guard test file) |
| V7 | `grep -ohE "// REQ-DAT-001\.[0-9]+" test/domain/satellite_catalog_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-001.1,// REQ-DAT-001.2,// REQ-DAT-001.3` | REQ-DAT-001.6 (tags of the unit test file) |
| V8 | `dart pub get && dart analyze --fatal-infos && dart test`, inside `packages/orbital_core` | exit 0 | The core is untouched and still passes on its own (Constitution principle 3) |
| V9 | `grep -rlE "25544\|48274\|38011\|60133" lib packages/orbital_core/lib \| paste -sd, -` | standard output `lib/domain/satellite_catalog.dart` | REQ-DAT-001.4 (one source of truth) |
| V10 | `git fetch origin main && git diff --name-only origin/main...HEAD \| LC_ALL=C sort \| paste -sd, -` | standard output `lib/domain/satellite_catalog.dart,test/domain/celestrak_tle_snapshot.dart,test/domain/satellite_catalog_test.dart,test/satellite_catalog_guard_test.dart`; or, only when the pull request links the developer's approval of a spec diff, the same list with `specs/req-dat-001.md` inserted after `lib/domain/satellite_catalog.dart` | REQ-DAT-001.6 (only the files of this spec change) |
| V11 | command V11 below | standard output `1,1,0` | The brief edit of the pull request of this spec (REQ-DAT-001.5) |

```bash
# V11
B="docs/Wintek— Project Brief.md"; printf '%s,%s,%s\n' "$(grep -cF '| GOES-East | 60133 (GOES 19) |' "$B")" "$(grep -cE '^- \[x\] .*GOES-East' "$B")" "$(grep -cE '^- \[ \] .*GOES-East' "$B")"
```

V11 runs on the pull request of this spec, which makes the edit, and again on the implementation pull request. Its patterns are ASCII, so the check does not depend on the Spanish text of the brief. Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V3 to V5 and V8 on every pull request. `lib/domain/.gitkeep` stays, so V10 lists no deletion.

**Precondition of V10.** The implementation branch is created from `main` after the pull request of this spec was merged into `main` with a merge commit. That pull request carries the spec file, the note in the ADR file and the edit of the brief file. If the branch was created before that merge, or the spec pull request was squashed, those files appear in the diff. V10 then counts as not run, never as a pass or a failure, and the fix is to rebase the implementation branch onto `main`.

**Precondition of the new files.** `.gitattributes` (`* text=auto eol=lf`) normalizes only what enters the repository. A file that a Windows editor saved with CRLF keeps its CR bytes in the working tree until the next checkout, so the bytes check of REQ-DAT-001.6 fails locally before the first commit. Save the new files as UTF-8 without BOM and with LF from the start.

### Local negative checks

These run after every file of the implementation pull request is committed on the feature branch. Before U1, `git status --porcelain` must print nothing; otherwise stop, because the edits and the revert below would destroy uncommitted work.

After each row, revert with:

    git checkout -- lib test docs specs packages

After the last row, `git status --porcelain` must print nothing again. If it prints a line, a row left a file behind, and the rows count as not run until the tree is clean.

Every row runs `flutter test` with `--no-pub`, so no row resolves dependencies, needs the network or rewrites `pubspec.lock`.

**Unit test rows (U).** The command is:

    flutter test --no-pub --reporter expanded test/domain/satellite_catalog_test.dart 2>&1 | grep -F "[E]" | grep -F "<tag>"

For each U row, apply the edit, run the command and confirm that it prints at least one line. That line is a failing test whose name carries the requirement ID.

**Guard rows (G).** The command is:

    flutter test --no-pub test/satellite_catalog_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-dat-001.md"

**Control run (G0).** With no edit applied, run the G command once for each tag `[REQ-DAT-001.4]`, `[REQ-DAT-001.5]` and `[REQ-DAT-001.6]`, and confirm that each prints nothing. A printed line means the output of a passing run already carries a tag and the spec path, so the rows below would prove nothing. Fix the guard test file before continuing. Then, for each G row, apply the edit, run the G command and confirm that it prints at least one line.

The edits are defined as in `specs/req-orb-010.md` (Local negative checks): "Delete the line X", "Replace the line X with Y", "Replace every occurrence of X with Y", "Append the line X", "Add X as the first line", "Insert the line X directly after (before) the line Y", "Delete the file" and "Run". "The catalog file", "the unit test file", "the snapshot file", "the guard test file" and "the ADR file" are the files of Definitions.

| # | Edit | Tag expected |
| --- | --- | --- |
| U1 | Replace every occurrence of `60133` with `41866` in the catalog file (the catalog number of GOES-16, the previous GOES-East) | `REQ-DAT-001.1` |
| U2 | Replace every occurrence of `'Tiangong'` with `'Tiangong (CSS)'` in the catalog file | `REQ-DAT-001.1` |
| U3 | Replace every occurrence of `25544` with `100000` in the catalog file | `REQ-DAT-001.2` |
| U4 | Replace every occurrence of `38011` with `48274` in the catalog file | `REQ-DAT-001.2` |
| U5 | Replace every occurrence of `'FASat-Charlie'` with `'ISS'` in the catalog file (repeated display name) | `REQ-DAT-001.2` |
| U6 | Replace every occurrence of `'Tiangong'` with `''` in the catalog file (empty display name) | `REQ-DAT-001.2` |
| U7 | Replace every occurrence of `'GOES-East'` with `' GOES-East'` in the catalog file (leading space) | `REQ-DAT-001.2` |
| U8 | Replace every occurrence of `'SSOT',` with `'FASAT-C',` in the snapshot file | `REQ-DAT-001.3` |
| U9 | Replace every occurrence of `1 60133U` with `1 60134U` in the snapshot file | `REQ-DAT-001.3` |
| G1 | Delete the file `lib/domain/satellite_catalog.dart` | `[REQ-DAT-001.4]` |
| G2 | Add `import 'package:flutter/foundation.dart';` as the first line of the catalog file | `[REQ-DAT-001.4]` |
| G3 | Add `export 'package:orbital_core/orbital_core.dart';` as the first line of the catalog file | `[REQ-DAT-001.4]` |
| G4 | Append the line `// ISS is 25544.` to `lib/main.dart` | `[REQ-DAT-001.4]` |
| G5 | Append the line `// GOES 19 is 60133.` to `packages/orbital_core/lib/src/tle_parser.dart` | `[REQ-DAT-001.4]` |
| G6 | Replace every occurrence of `'ISS'` with `"ISS"` in the catalog file | `[REQ-DAT-001.4]` |
| G7 | Delete the line `/// The four objects that Wintek tracks, in display order (specs/req-dat-001.md).` from the catalog file | `[REQ-DAT-001.4]` |
| G8 | Delete the line `/// NORAD ID: the catalog number from 1 to 99999 that OrbitalElements.catalogNumber reads from a TLE, where it has five digits (ADR-0003, decision 1).` from the catalog file | `[REQ-DAT-001.4]` |
| G9 | Delete the line `/// Source: CelesTrak SATCAT, checked on 2026-11-10: ISS (ZARYA), CSS (TIANHE), SSOT and GOES 19.` from the catalog file | `[REQ-DAT-001.4]` |
| G10 | Delete the line `/// GOES-East is a role, filled by GOES 19 (2024-119A) since 2025-04-07; a change of satellite is a change of specs/req-dat-001.md, never a runtime lookup.` from the catalog file | `[REQ-DAT-001.4]` |
| G11 | Replace the line `enum TrackedObject {` with `enum SatelliteId {` in the catalog file | `[REQ-DAT-001.4]` |
| G12 | Replace the line `final int noradId;` with `final int catalogNumber;` in the catalog file | `[REQ-DAT-001.4]` |
| G13 | Insert the line `  static TrackedObject byNoradId(int id) => values.first;` directly after the line `final int noradId;` in the catalog file | `[REQ-DAT-001.4]` |
| G14 | Insert the line `  String get label => displayName;` directly after the line `final int noradId;` in the catalog file | `[REQ-DAT-001.4]` |
| G15 | Append the line `const int issNoradId = 25544;` to the catalog file | `[REQ-DAT-001.4]` |
| G16 | Insert an empty line directly before the line `enum TrackedObject {` in the catalog file | `[REQ-DAT-001.4]` |
| G17 | Run `rm -rf lib/domain` | `[REQ-DAT-001.4]` |
| G18 | Delete the line `- **Note (2026-11-10, req-dat-001):** GOES-East is GOES 19, catalog number 60133, which has five digits. Decision 1 holds and no superseding ADR is needed.` from the ADR file | `[REQ-DAT-001.5]` |
| G19 | Insert an empty line directly before the line `- **Note (2026-11-10, req-dat-001):** GOES-East is GOES 19, catalog number 60133, which has five digits. Decision 1 holds and no superseding ADR is needed.` in the ADR file | `[REQ-DAT-001.5]` |
| G20 | Replace every occurrence of `.00009346` with `.00009347` in the snapshot file | `[REQ-DAT-001.6]` |
| G21 | Replace every occurrence of `0  9996',` with `0 9996',` in the snapshot file (a 68-character line 1) | `[REQ-DAT-001.6]` |
| G22 | Replace every occurrence of `'GOES 19',` with `'GOES 19                 ',` in the snapshot file (name line with its trailing spaces) | `[REQ-DAT-001.6]` |
| G23 | Delete the line `'SSOT',` from the snapshot file | `[REQ-DAT-001.6]` |
| G24 | Replace every occurrence of `15.61635786315941` with `15.61635786315942` in the spec file (the spec no longer agrees with the data file) | `[REQ-DAT-001.6]` |
| G25 | Append the line `const String extra = '';` to the snapshot file | `[REQ-DAT-001.6]` |
| G26 | Delete the line `// Source: CelesTrak GP data, https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, one request per object (specs/req-dat-001.md).` from the snapshot file | `[REQ-DAT-001.6]` |
| G27 | Delete the line `// Fetched: 2026-11-10, once per object while drafting specs/req-dat-001.md; no test fetches it again.` from the snapshot file | `[REQ-DAT-001.6]` |
| G28 | Delete the line `// Identity snapshot: its epochs and elements are not reference values for any formula (Constitution principle 6).` from the snapshot file | `[REQ-DAT-001.6]` |
| G29 | Delete the line `// Catalog source: CelesTrak SATCAT, https://celestrak.org/satcat/records.php?CATNR=<NORAD ID>, checked on 2026-11-10.` from the unit test file | `[REQ-DAT-001.6]` |
| G30 | Delete the line `// GOES-East: GOES 19 since 2025-04-07, https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters` from the unit test file | `[REQ-DAT-001.6]` |
| G31 | Add `import 'dart:io';` as the first line of the unit test file | `[REQ-DAT-001.6]` |
| G32 | Add `import 'package:http/http.dart';` as the first line of the unit test file | `[REQ-DAT-001.6]` |
| G33 | Add `import 'dart:math';` as the first line of the snapshot file | `[REQ-DAT-001.6]` |
| G34 | Replace the line `import 'package:wintek/domain/satellite_catalog.dart';` with `import '../../lib/domain/satellite_catalog.dart';` in the unit test file | `[REQ-DAT-001.6]` |
| G35 | Replace the line `// REQ-DAT-001.2` with `// REQ-DAT-001.x` in the unit test file | `[REQ-DAT-001.6]` |
| G36 | Replace every occurrence of `'REQ-DAT-001.1 ` with `'Catalog ` in the unit test file | `[REQ-DAT-001.6]` |
| G37 | Append the line `// skip: true` to the unit test file | `[REQ-DAT-001.6]` |
| G38 | Run `sed -i 's/$/\r/' lib/domain/satellite_catalog.dart` (CRLF in the catalog file) | `[REQ-DAT-001.6]` |
| G39 | Run `printf '\xEF\xBB\xBF' \| cat - lib/domain/satellite_catalog.dart > /tmp/g39 && mv /tmp/g39 lib/domain/satellite_catalog.dart` (BOM in the catalog file) | `[REQ-DAT-001.6]` |
| G40 | Run `printf '\xEF\xBB\xBF' \| cat - test/domain/celestrak_tle_snapshot.dart > /tmp/g40 && mv /tmp/g40 test/domain/celestrak_tle_snapshot.dart` (BOM in the snapshot file) | `[REQ-DAT-001.6]` |
| G41 | Run `sed -i 's/$/\r/' test/domain/satellite_catalog_test.dart` (CRLF in the unit test file) | `[REQ-DAT-001.6]` |
| G42 | Run `sed -i 's/$/\r/' test/satellite_catalog_guard_test.dart` (CRLF in the guard test file) | `[REQ-DAT-001.6]` |
| G43 | Run `sed -i 's/$/\r/' specs/req-dat-001.md` (CRLF in the spec file) | `[REQ-DAT-001.6]` |
| G44 | Run `sed -i 's/$/\r/' docs/adr/ADR-0003-tle-element-sets-and-units.md` (CRLF in the ADR file) | `[REQ-DAT-001.6]` |
| G45 | Append the line `// Platform.script` to the guard test file | `[REQ-DAT-001.6]` |
| G46 | Replace the line `// REQ-DAT-001.4` with `// REQ-DAT-001.x` in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-DAT-001.6]` |
| G47 | Append the line `// REQ-DAT-001.1` to the guard test file | `[REQ-DAT-001.6]` |
| G48 | Delete the file `test/domain/satellite_catalog_test.dart` | `[REQ-DAT-001.6]` |
| G49 | Delete the file `test/domain/celestrak_tle_snapshot.dart` | `[REQ-DAT-001.6]` |
| G50 | Delete the file `specs/req-dat-001.md` | `[REQ-DAT-001.6]` |
| G51 | Delete the file `docs/adr/ADR-0003-tle-element-sets-and-units.md` | `[REQ-DAT-001.5]` |

Inside the table, `\|` is a single pipe.

- In rows U1 to U7 the unit test file still compiles, because only values change.
- In G11 to G15 the unit test file may no longer compile. That does not affect the guard, which reads text and runs on its own.
- G44 is expected to report `[REQ-DAT-001.6]`. The note of REQ-DAT-001.5 still matches, because a trailing CR is removed with the trailing spaces.

No row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V2 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that implements this spec lists V1–V11, U1–U9, G0 and G1–G51, each with its observed result. A pull request without this list is incomplete regardless of its check status. This checklist is the one manual step of this spec: a reviewer reads it, and no command verifies it.

## Edge Cases & Errors

- **NOAA moves another satellite into the GOES-East role.** The app keeps tracking 60133, GOES 19, until this spec changes. The change is a new revision of this spec:
  - a new row 4 and new doc lines;
  - a new SATCAT check date;
  - a new snapshot entry, captured once while drafting that revision.

  The ADR note keeps its date, as a record of what was confirmed when. If the new catalog number has more than five digits (Alpha-5), REQ-DAT-001.2 fails, and the remedy is a new ADR that supersedes ADR-0003 decision 1, never a relaxed test.
- **CelesTrak renames an object.** A new SATCAT name does not change the display name, which is the app's own. The snapshot of the spec keeps the name it was captured with, so the tests keep passing. Updating the name is a revision of this spec, made only together with a new snapshot.
- **A CelesTrak name with a quote.** The data-line rule cannot hold a token that contains `'`. None of the four names does. A revision that captures such a name must also change the data-line rule.
- **Object decayed or no GP data.** The tests read only the fixed snapshot, so a decayed object never breaks them. A decayed object at run time is a condition of req-dat-002 to req-dat-004 and req-sta-001, not of the catalog. Replacing a decayed object is a revision of this spec.
- **A copy error in the data file.** Any character that differs from the spec fails REQ-DAT-001.6 (G20 to G22), and the token count catches a missing or extra line (G23). The fix is to copy from the spec again, never to edit the spec to match.
- **The spec and the data file drift apart.** A change of the snapshot block without the data file, or the other way round, fails REQ-DAT-001.6 (G24). The snapshot changes only in a revision of this spec, and the implementation follows.
- **A snapshot TLE that the parser rejects.** Each pair was parsed while drafting. If a later change to req-orb-003 makes `OrbitalElements.fromTle` reject one, REQ-DAT-001.3 fails. That is a regression of the parser, never a reason to change a token.
- **Trailing spaces and CRLF from CelesTrak.** The GP response pads the name line to 24 characters and uses CRLF. The snapshot holds the name without trailing spaces and no CR, and the data file is LF. G22, G38 and G40 prove that the guard rejects the raw forms.
- **A stale snapshot.** The snapshot ages from 2026-11-10. That is expected: it proves identity, and catalog numbers do not age. No test compares its epochs with the current time. It is never used as live data, so the stale-data warning of req-ui-004 does not apply to it.
- **The same catalog number reused.** A NORAD catalog number is never reassigned, so the number alone identifies the object. The CelesTrak-name check of REQ-DAT-001.3 still catches a typo that lands on another real object (U8, U9).
- **Catalog numbers elsewhere in tests.** The one-source rule covers library files only. Test files of either suite may contain catalog numbers. For example, the parser tests of req-orb-003 and req-orb-009 use NOAA 14 (23455), and the official SGP4 vectors use many numbers.
- **CRLF or BOM in a new or edited file.** Rejected by REQ-DAT-001.6. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test. See the precondition of the new files.
- **Network or CI failure.** Nothing in this spec uses the network at run time, in the tests or in the implementation.
  - A failed `flutter pub get`, a timeout, a runner out of memory or a failed analysis is handled as req-inf-002 defines and never counts as a pass.
  - V10 needs `git fetch`. If it fails, or its precondition does not hold, V10 counts as not run.
  - A U or G row whose output shows a compilation or resolution error of the file it targets, instead of the expected tag, counts as not run, never as a pass.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Shell.** The commands need a POSIX shell with GNU `sed`. In PowerShell they fail with "command not found"; that is an environment error, never a pass. In Git Bash on Windows, an argument that starts with `/`, such as a `///` or `//` line, is rewritten as a path. Set `MSYS_NO_PATHCONV=1` when scripting the edits, and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in the implementation pull request:

- Any network request, CelesTrak client, URL builder or request policy (req-dat-002). The snapshot is copied from this spec.
- Any cache, repository, refresh threshold or data-age logic (req-dat-003, req-dat-004).
- A general import rule for every file under `lib/domain`. Constitution principle 5 is enforced for domain interfaces by req-dat-004, which adds the first of them. This spec checks only that the catalog file imports nothing.
- Any lookup from a catalog number to an object, any parsing of names from CelesTrak, or any mapping of OMM fields. req-dat-004 adds a lookup if it needs one, with its own revision of the members rule of REQ-DAT-001.4.
- Colours, icons or any theme token per object (req-ui-001, req-viz-005).
- Orbit classes, international designators, launch dates, operators or descriptions in code. They appear only as information in the Definitions table.
- Any provider, widget or screen, and any change to `lib/main.dart`, whose placeholder text already names the four objects.
- Any change to `packages/orbital_core`, its tests or its guards. The core keeps knowing no tracked object.
- Any change to either `pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yml`, `test/support/repo_root.dart`, `test/dependency_guard_test.dart` or the constitution.
- Any change to the ADR file or the brief file in the implementation pull request. Their edits belong to the pull request of this spec.
- Translating the Project Brief to English, or any other edit of the brief beyond the one V11 checks.
- Reconciling the "feature-first" wording of `AGENTS.md` with the layer directories of the scaffold.
- A new ADR. Decision 1 of ADR-0003 is confirmed, not superseded.
- Any change to `specs/req-dat-001.md` in the implementation pull request, except a behaviour change approved by the developer (REQ-DAT-001.6, V10).
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
