# req-dat-001 — Satellite catalog

- **Status:** Draft (revision 1), pending the first QA audit. On 2026-11-10, before drafting, the developer approved:
  - GOES-East as a role name with a fixed NORAD ID: 60133, the catalog number of GOES 19;
  - minimal identity per entry: a stable key, a display name and the NORAD ID, in a fixed order;
  - validation by the constants themselves and by one vendored CelesTrak TLE snapshot per object, parsed by the parser of req-orb-003;
  - a dated note in ADR-0003 and the closure of the open GOES-East item of the Project Brief, both in the pull request of this spec.
- **Roadmap row:** 13 of 33 (MVP)
- **Blocks:**
  - req-dat-002: requests the element sets of exactly these four catalog numbers;
  - req-dat-004: tells which object a cached element set belongs to;
  - req-sta-001: builds one state per tracked object;
  - req-viz-005 and req-ui-003: draw one marker per object and show its name on the card.
- **Depends on:**
  - req-orb-003: `OrbitalElements.fromTle`, its `catalogNumber` and its five-digit catalog-number field;
  - req-inf-001 and req-inf-002: both suites, the CI gates and `test/support/repo_root.dart`;
  - ADR-0003, decision 1: TLE only, five-digit catalog numbers, and the GOES-East number left to this spec.
- **ADR:** none new. This spec confirms decision 1 of ADR-0003 instead of superseding it, and records that confirmation as a dated note in ADR-0003 (REQ-DAT-001.5). The decisions of ADR-0003 are unchanged.
- **No new dependency and no formula.** The catalog adds no package to either manifest and no mathematics, so Constitution principle 6 is not triggered. The TLE snapshot is identity evidence, not a reference value (REQ-DAT-001.3).

## Context & Objective

Roadmap row 13 asks to "fix the four tracked objects and their NORAD IDs as domain constants, closing the open GOES-East question before any request is written". The Project Brief names the four objects. It gives three NORAD IDs and leaves the fourth "por confirmar en CelesTrak". ADR-0003 decision 1 makes the gap binding: the core reads only five-digit catalog numbers, and "the catalog number of GOES-East is fixed by req-dat-001, which must confirm that it has five digits or propose an ADR that supersedes this decision".

Every later layer needs the same four identities. req-dat-002 requests them, req-dat-004 files their element sets, req-sta-001 propagates them, and the globe and the card draw and name them. This spec puts the four identities in one place, the domain layer, so no other file repeats a catalog number.

### The GOES-East question, closed

GOES-East is an operational role of NOAA at 75.2° W, not a satellite. GOES-19 (GOES-U, launched 2024-06-25) replaced GOES-16 in that role on 2025-04-07, and still held it when this spec was drafted (NOAA NESDIS, "NOAA's GOES-19 Now Operational as GOES East, Providing Critical New Data to Forecasters"). CelesTrak SATCAT lists it as `GOES 19`, international designator 2024-119A, NORAD catalog number **60133**, perigee 35783 km and apogee 35789 km.

60133 has five digits, so decision 1 of ADR-0003 holds and needs no superseding ADR. A one-off request for its CelesTrak GP data on 2026-11-10 returned a TLE whose line 1 starts `1 60133U 24119A` and whose mean motion is 1.00272638 revolutions per day, which is a geostationary orbit.

### Decisions approved before drafting

- **Role name, fixed ID.** The object is shown as `GOES-East`, and its NORAD ID is 60133. The app never resolves the role at run time. If NOAA moves another satellite into the role, changing the ID is a change of this spec, as is any other row of the catalog.
- **Minimal identity.** Each entry carries a stable key, the display name and the NORAD ID. The order of the entries is fixed and is the display order. Colours (req-ui-001), CelesTrak URLs and request policy (req-dat-002), orbit classes and international designators are not part of the catalog. The table in Definitions shows the designators and orbit classes for information only.
- **Identity proved by real data.** The constants are checked against themselves (REQ-DAT-001.1 and .2). They are also checked against one CelesTrak TLE per object, vendored once as a Dart data file and parsed by `OrbitalElements.fromTle` (REQ-DAT-001.3). This proves that each ID names an element set that CelesTrak serves and the core accepts. It is also the first time that real CelesTrak data passes through the parser of req-orb-003.
- **Paper trail.** The confirmation is recorded in two places outside this spec. ADR-0003 gets a dated note under its Consequences, and the Project Brief gets the ID in its table and its open item ticked. Both changes land in the pull request of this spec, and the guard keeps them there (REQ-DAT-001.5).

### Decisions that follow from the Constitution

- **Domain, with no imports.** The catalog is domain data (Constitution principle 5: `domain` depends only on `orbital_core`). It needs nothing at all, so its file imports nothing: not Flutter, not `orbital_core`, not even a `dart:` library. Domain, data and presentation can then all read it, and none of them pulls a dependency through it.
- **The domain boundary, made executable.** This is the first Dart file under `lib/domain`. The guard therefore also enforces principle 5 for every future domain file: a domain file may import only `orbital_core`, a few pure `dart:` libraries and other domain files (REQ-DAT-001.4).
- **One source of truth.** No application library file other than the catalog, and no file of the core library, contains any of the four catalog numbers (REQ-DAT-001.4). The core stays generic: it parses any five-digit TLE and knows no tracked object.
- **Good CelesTrak citizen (principle 10).** The snapshot is fetched once at implementation time, with four requests, one per object. No test ever fetches it. Nothing in this spec runs at app run time on the network.

## Definitions used by every requirement

These definitions are normative.

- **Catalog library file:** `lib/domain/satellite_catalog.dart`.
- **Domain library files:** every file whose name ends in `.dart` under `lib/domain`, searched recursively.
- **Application library files:** every file whose name ends in `.dart` under `lib`, searched recursively.
- **Core library files:** every file whose name ends in `.dart` under `packages/orbital_core/lib`, searched recursively.
- **Unit test file:** `test/domain/satellite_catalog_test.dart`, in the application suite. It covers REQ-DAT-001.1 to .3.
- **Snapshot data file:** `test/domain/celestrak_tle_snapshot.dart`.
- **Guard test file:** `test/satellite_catalog_guard_test.dart`, in the application suite. It covers REQ-DAT-001.4 to .6.
- **Spec file:** `specs/req-dat-001.md`.
- **ADR file:** `docs/adr/ADR-0003-tle-element-sets-and-units.md`.
- **Brief file:** `docs/Wintek— Project Brief.md`. The character after `Wintek` is U+2014 EM DASH, followed by one space.
- **Line match:** a line matches a string when, with leading and trailing spaces removed, it is equal to the string character for character.
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
- **Data line:** a line of the snapshot data file whose text, with leading and trailing spaces removed, starts with `'`, ends with `',` and contains no other `'`. Its token is the text between the two quotes.
- **Snapshot entry k**, for position k from 1 to 4: the tokens 3k−2, 3k−1 and 3k, in file order. They are the three lines of the response to the GP request of the object at position k:
  - the name line, with its trailing spaces removed;
  - line 1;
  - line 2.

  Lines 1 and 2 are written exactly as CelesTrak returned them, with no change of any character.
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

- Every NORAD ID is from 1 to 99999 inclusive. This is the five-digit range that ADR-0003 decision 1 and the parser of req-orb-003 accept. 0 names no object.
- The four NORAD IDs are distinct.
- The four display names are distinct and not empty, and each one is equal to itself with leading and trailing spaces removed.

So a replacement GOES-East with an Alpha-5 catalog number fails here, and the failure points at ADR-0003.

### REQ-DAT-001.3 — Each NORAD ID names a real CelesTrak element set

Each ID is the catalog number of an element set that CelesTrak serves and that the core parses.

**Acceptance (verified by the unit test file).** The test reads the snapshot data file, which holds exactly 12 tokens. For each position k from 1 to 4:

- the first token of snapshot entry k is exactly the CelesTrak name of position k;
- `OrbitalElements.fromTle` of the second and third tokens, as lines 1 and 2, does not throw;
- the `catalogNumber` of the result equals the NORAD ID of the catalog entry at position k.

The snapshot proves identity only. Its epochs and elements are not reference values for any formula, and no test compares a position, a period or an orbit class derived from it.

### REQ-DAT-001.4 — Placement, domain boundary and documented contract

The catalog lives in the domain layer, imports nothing, is the only place that holds the four catalog numbers, and documents its source.

**Acceptance (verified by the guard test file):**

- **Placement.** The catalog library file exists.
- **No imports.** No line of the catalog library file, with leading spaces removed, starts with `import`, `export` or `part`.
- **Domain boundary (Constitution principle 5).** In every domain library file, every line that, with leading spaces removed, starts with `import` or `export` matches the regular expression `^(import|export)\s+'(package:orbital_core/orbital_core\.dart|dart:(async|collection|core|math|typed_data)|[a-z0-9_]+(/[a-z0-9_]+)*\.dart)'`, applied to the line with leading spaces removed. So a domain file imports no Flutter, I/O, HTTP, state or storage package. It also imports no file outside `lib/domain`, because a relative path may not contain `..`.
- **One source of truth.**
  - No application library file other than the catalog library file contains any of the substrings `25544`, `48274`, `38011` or `60133`.
  - No core library file contains any of them.
- **Declaration.** The catalog library file contains the line `enum TrackedObject {`. The enum body is the lines after it, up to and not including the first line equal to `}`, compared with no spaces removed.
- **Doc block.** The doc block is the run of consecutive lines directly before the declaration line whose text, with leading and trailing spaces removed, starts with `///`. It contains each of these lines, in any order:
  - `/// The four objects that Wintek tracks, in display order (specs/req-dat-001.md).`
  - `/// NORAD ID: the five-digit catalog number that OrbitalElements.catalogNumber reads from a TLE (ADR-0003, decision 1).`
  - `/// Source: CelesTrak SATCAT, checked on 2026-11-10: ISS (ZARYA), CSS (TIANHE), SSOT and GOES 19.`
  - `/// GOES-East is a role, filled by GOES 19 (2024-119A) since 2025-04-07; a change of satellite is a change of specs/req-dat-001.md, never a runtime lookup.`
- **Members.**
  - The enum body contains the lines `final String displayName;` and `final int noradId;`, by line match.
  - Each line of the enum body that starts with exactly two spaces followed by a character other than a space meets one of these conditions. Lines whose text, with leading spaces removed, starts with `//` or `@` are exempt.
    - It matches one of the two field lines above.
    - With leading spaces removed, it starts with `iss(`, `tiangong(`, `fasatCharlie(`, `goesEast(` or `const TrackedObject(`.
    - Its text before the first `(`, ` =` or `;` contains a word that starts with `_`.

    So the public names are the four values, `displayName` and `noradId`; any other member is private.
- **Top-level declarations.** Every line of the catalog library file that has a character other than a space at its first column, compared with no spaces removed, meets one of these conditions:
  - it starts with `//`;
  - it is equal to `}`;
  - it is equal to the declaration line.

  Empty lines are allowed. So the file declares no other top-level name: no constant, no function and no lookup table.

### REQ-DAT-001.5 — The GOES-East question is closed in the docs

The confirmation is recorded where the question was asked.

**Acceptance (verified by the guard test file):**

- **ADR-0003.** The ADR file contains a line that matches `- **Note (2026-11-10, req-dat-001):** GOES-East is GOES 19, catalog number 60133, which has five digits. Decision 1 holds and no superseding ADR is needed.` The line directly before it, with leading spaces removed, starts with `- Catalog numbers above 99999 (Alpha-5) are not supported.`
- **Project Brief.**
  - The brief file contains a line that matches `| GOES-East | 60133 (GOES 19) | Geoestacionaria, \~35.786 km | Parece fijo sobre la Tierra: demuestra la rotación de marcos |`. The backslash is part of the line.
  - It contains a line that matches `- [x] Confirmar qué satélite es hoy GOES-East y su NORAD ID en CelesTrak`.
  - It contains neither the substring `por confirmar en CelesTrak` nor the substring `- [ ] Confirmar qué satélite es hoy GOES-East`.

The three edits land in the pull request of this spec, so they are already on `main` when the implementation branch is created. The implementation pull request does not change either file (REQ-DAT-001.6, V10).

### REQ-DAT-001.6 — Snapshot shape and test hygiene

The snapshot has the shape that REQ-DAT-001.3 reads. The new test files follow the hygiene rules of req-orb-006 to req-orb-010.

**Acceptance (verified by the guard test file):**

- **Snapshot shape.**
  - The snapshot data file holds exactly 12 data lines.
  - Tokens 1, 4, 7 and 10 are exactly the CelesTrak names of positions 1 to 4.
  - Tokens 2, 5, 8 and 11 each have exactly 69 characters and start with `1 `.
  - Tokens 3, 6, 9 and 12 each have exactly 69 characters and start with `2 `.
- **Snapshot citations.** The snapshot data file contains:
  - a line that matches `// Source: CelesTrak GP data, https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, one request per object (specs/req-dat-001.md).`, where `<NORAD ID>` is written literally;
  - a line which, with leading and trailing spaces removed, matches the regular expression `^// Fetched: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z, once per object; no test fetches it again\.$`;
  - a line that matches `// Identity snapshot: its epochs and elements are not reference values for any formula (Constitution principle 6).`
- **Unit test citations.** The unit test file contains a line that matches each of:
  - `// Catalog source: CelesTrak SATCAT, https://celestrak.org/satcat/records.php?CATNR=<NORAD ID>, checked on 2026-11-10.`, where `<NORAD ID>` is written literally;
  - `// GOES-East: GOES 19 since 2025-04-07, https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters`
- **Imports.**
  - The unit test file contains the lines `import 'package:flutter_test/flutter_test.dart';`, `import 'package:orbital_core/orbital_core.dart';`, `import 'package:wintek/domain/satellite_catalog.dart';` and `import 'celestrak_tle_snapshot.dart';`, by line match. No other line of it, with leading spaces removed, starts with `import` or `export`.
  - No line of the snapshot data file, with leading spaces removed, starts with `import` or `export`.
  - Neither file contains the substring `dart:io`.
- **Tags.**
  - For each N from 1 to 3, the unit test file contains a line that matches `// REQ-DAT-001.N`. The next non-empty line after it, with leading spaces removed, starts with `group('REQ-DAT-001.N ` or `test('REQ-DAT-001.N `. That puts the requirement ID into the name of every failing unit test (rows U1 to U6).
  - For each N from 4 to 6, the guard test file contains a line that matches `// REQ-DAT-001.N`. The next non-empty line after it, with leading spaces removed, starts with `test(`.
  - The guard test file builds the tags and test-name prefixes of the unit test file (`REQ-DAT-001.1` to `.3`) by interpolation, never as literals, so that V6 prints only its own tags.
- **Self-matching tokens.** The guard test file builds the tokens `Platform.script` and `skip:` by concatenation of shorter string literals, never as one literal.
- **No skipped tests.** Neither the unit test file nor the guard test file contains the substring `skip:`.
- **Bytes.** None of these files contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the catalog library file, the unit test file, the snapshot data file, the guard test file, the spec file, the ADR file and the brief file.
- **Repository root.** The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- **Plain text only.** The guard test file reads files as plain text with the Dart core and `dart:io` libraries of the application suite. It uses no YAML or other external parser, and it reads the brief file as UTF-8.
- **Missing files fail.** Each of the following produces a failing test when missing, never a skipped or passing one: the catalog library file, the `lib/domain` directory, the unit test file, the snapshot data file, the spec file, the ADR file and the brief file. A missing guard test file is caught by V4.
- **Failure messages.** Every failure message of the guard test file starts with `[REQ-DAT-001.N]`, where N is the requirement whose check failed, and carries `specs/req-dat-001.md` on the same line as that tag.

**Acceptance (verified by command V10).** Compared with `main`, the pull request that implements this spec changes exactly the four files of V10. The one allowed exception is the spec file: when the implementation needs a behaviour change, the pull request may also change `specs/req-dat-001.md`, with the developer's approval linked in its description (Constitution principle 2). V10 is a local check: CI does not run it, and the pull request checklist reports its result.

## Mathematical Validation / Testing

This spec adds no formula, so there is nothing to check against Vallado or Curtis, and Constitution principle 6 is not triggered. Its evidence is identity. The catalog numbers and names are those of the CelesTrak SATCAT records, and the GOES-East role is that of the NESDIS source, both cited in the unit test file. REQ-DAT-001.3 proves that each number is the catalog number that the req-orb-003 parser reads from a real CelesTrak TLE.

All commands in this section run from a POSIX shell with GNU `sed`: Git Bash on Windows, or a shell on Linux. PowerShell lacks `grep`, `sed`, `sort`, `paste` and `printf` with byte escapes.

### Snapshot capture (once, at implementation time, before the first commit)

1. For each tracked object, in position order, request its GP request URL once, for example with `curl -fsS "<URL>"`. That makes four requests in total, and no request is repeated (Constitution principle 10).
2. Copy the three lines of each response into the snapshot data file as snapshot entry k, as Definitions fixes. Remove the trailing spaces of the name line, and leave lines 1 and 2 unchanged. CelesTrak may answer with CRLF line endings: the CR bytes are not part of any token, and the file is saved with LF (REQ-DAT-001.6).
3. Write the `// Fetched:` line with the UTC time of the first of the four requests, to the second.

If a response is not three lines of a TLE, the snapshot is not written. Examples are an empty body, an HTML page, or a "No GP data found" message. The cases are in Edge Cases.

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

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V3 to V5 and V8 on every pull request. `lib/domain/.gitkeep` stays, so V10 lists no deletion.

**Precondition of V10.** The implementation branch is created from `main` after the pull request of this spec was merged into `main` with a merge commit. That pull request carries the spec file, the note in the ADR file and the two edits of the brief file. If the branch was created before that merge, or the spec pull request was squashed, those files appear in the diff. V10 then counts as not run, never as a pass or a failure, and the fix is to rebase the implementation branch onto `main`.

### Local negative checks

These run after every file of the implementation pull request is committed on the feature branch. Before U1, `git status --porcelain` must print nothing; otherwise stop, because the edits and the revert below would destroy uncommitted work.

After each row, revert with:

    git checkout -- lib test docs specs packages && git clean -fdq lib/domain

`git clean` removes only the untracked probe files that rows G3 and G4 create under `lib/domain`.

Every row runs `flutter test` with `--no-pub`, so no row resolves dependencies, needs the network or rewrites `pubspec.lock`.

**Unit test rows (U).** The command is:

    flutter test --no-pub --reporter expanded test/domain/satellite_catalog_test.dart 2>&1 | grep -F "[E]" | grep -F "<tag>"

For each U row, apply the edit, run the command and confirm that it prints at least one line. That line is a failing test whose name carries the requirement ID.

**Guard rows (G).** The command is:

    flutter test --no-pub test/satellite_catalog_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-dat-001.md"

**Control run (G0).** With no edit applied, run the G command once for each tag `[REQ-DAT-001.4]`, `[REQ-DAT-001.5]` and `[REQ-DAT-001.6]`, and confirm that each prints nothing. A printed line means the output of a passing run already carries a tag and the spec path, so the rows below would prove nothing. Fix the guard test file before continuing. Then, for each G row, apply the edit, run the G command and confirm that it prints at least one line.

The edits are defined as in `specs/req-orb-010.md` (Local negative checks): "Delete the line X", "Replace the line X with Y", "Replace every occurrence of X with Y", "Append the line X", "Add X as the first line", "Insert the line X directly after the line Y", "Delete the file", "Run" and "Create the file F with the single line X", the last of which writes a new untracked file. "The catalog file", "the unit test file", "the snapshot file", "the guard test file", "the ADR file" and "the brief file" are the files of Definitions.

| # | Edit | Tag expected |
| --- | --- | --- |
| U1 | Replace every occurrence of `60133` with `41866` in the catalog file (the catalog number of GOES-16, the previous GOES-East) | `REQ-DAT-001.1` |
| U2 | Replace every occurrence of `'Tiangong'` with `'Tiangong (CSS)'` in the catalog file | `REQ-DAT-001.1` |
| U3 | Replace every occurrence of `25544` with `100000` in the catalog file | `REQ-DAT-001.2` |
| U4 | Replace every occurrence of `38011` with `48274` in the catalog file | `REQ-DAT-001.2` |
| U5 | Replace every occurrence of `'SSOT',` with `'FASAT-C',` in the snapshot file | `REQ-DAT-001.3` |
| U6 | Replace every occurrence of `1 60133U` with `1 60134U` in the snapshot file | `REQ-DAT-001.3` |
| G1 | Delete the file `lib/domain/satellite_catalog.dart` | `[REQ-DAT-001.4]` |
| G2 | Add `import 'package:flutter/foundation.dart';` as the first line of the catalog file | `[REQ-DAT-001.4]` |
| G3 | Create the file `lib/domain/probe.dart` with the single line `import 'package:http/http.dart';` | `[REQ-DAT-001.4]` |
| G4 | Create the file `lib/domain/probe.dart` with the single line `import '../data/probe.dart';` | `[REQ-DAT-001.4]` |
| G5 | Append the line `// ISS is 25544.` to `lib/main.dart` | `[REQ-DAT-001.4]` |
| G6 | Append the line `// GOES 19 is 60133.` to `packages/orbital_core/lib/src/tle_parser.dart` | `[REQ-DAT-001.4]` |
| G7 | Delete the line `/// The four objects that Wintek tracks, in display order (specs/req-dat-001.md).` from the catalog file | `[REQ-DAT-001.4]` |
| G8 | Delete the line `/// NORAD ID: the five-digit catalog number that OrbitalElements.catalogNumber reads from a TLE (ADR-0003, decision 1).` from the catalog file | `[REQ-DAT-001.4]` |
| G9 | Delete the line `/// Source: CelesTrak SATCAT, checked on 2026-11-10: ISS (ZARYA), CSS (TIANHE), SSOT and GOES 19.` from the catalog file | `[REQ-DAT-001.4]` |
| G10 | Delete the line `/// GOES-East is a role, filled by GOES 19 (2024-119A) since 2025-04-07; a change of satellite is a change of specs/req-dat-001.md, never a runtime lookup.` from the catalog file | `[REQ-DAT-001.4]` |
| G11 | Replace the line `enum TrackedObject {` with `enum SatelliteId {` in the catalog file | `[REQ-DAT-001.4]` |
| G12 | Replace the line `final int noradId;` with `final int catalogNumber;` in the catalog file | `[REQ-DAT-001.4]` |
| G13 | Insert the line `  static TrackedObject byNoradId(int id) => values.first;` directly after the line `final int noradId;` in the catalog file | `[REQ-DAT-001.4]` |
| G14 | Append the line `const int issNoradId = 25544;` to the catalog file | `[REQ-DAT-001.4]` |
| G15 | Insert an empty line directly before the line `enum TrackedObject {` in the catalog file | `[REQ-DAT-001.4]` |
| G16 | Run `rm -rf lib/domain` | `[REQ-DAT-001.4]` |
| G17 | Delete the line `- **Note (2026-11-10, req-dat-001):** GOES-East is GOES 19, catalog number 60133, which has five digits. Decision 1 holds and no superseding ADR is needed.` from the ADR file | `[REQ-DAT-001.5]` |
| G18 | Replace every occurrence of `- [x] Confirmar qué satélite` with `- [ ] Confirmar qué satélite` in the brief file | `[REQ-DAT-001.5]` |
| G19 | Replace every occurrence of `60133 (GOES 19)` with `por confirmar en CelesTrak` in the brief file | `[REQ-DAT-001.5]` |
| G20 | Delete the file `docs/adr/ADR-0003-tle-element-sets-and-units.md` | `[REQ-DAT-001.5]` |
| G21 | Run `rm "docs/Wintek— Project Brief.md"` | `[REQ-DAT-001.5]` |
| G22 | Delete the file `test/domain/celestrak_tle_snapshot.dart` | `[REQ-DAT-001.6]` |
| G23 | Delete the line `'SSOT',` from the snapshot file | `[REQ-DAT-001.6]` |
| G24 | Replace every occurrence of `'GOES 19',` with `'GOES 19                 ',` in the snapshot file (name line with its trailing spaces) | `[REQ-DAT-001.6]` |
| G25 | Replace every occurrence of `// Fetched: ` with `// Fetched on: ` in the snapshot file | `[REQ-DAT-001.6]` |
| G26 | Delete the line `// Identity snapshot: its epochs and elements are not reference values for any formula (Constitution principle 6).` from the snapshot file | `[REQ-DAT-001.6]` |
| G27 | Delete the line `// GOES-East: GOES 19 since 2025-04-07, https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters` from the unit test file | `[REQ-DAT-001.6]` |
| G28 | Add `import 'dart:io';` as the first line of the unit test file | `[REQ-DAT-001.6]` |
| G29 | Add `import 'dart:math';` as the first line of the snapshot file | `[REQ-DAT-001.6]` |
| G30 | Replace the line `import 'package:wintek/domain/satellite_catalog.dart';` with `import '../../lib/domain/satellite_catalog.dart';` in the unit test file | `[REQ-DAT-001.6]` |
| G31 | Replace the line `// REQ-DAT-001.2` with `// REQ-DAT-001.x` in the unit test file | `[REQ-DAT-001.6]` |
| G32 | Append the line `// skip: true` to the unit test file | `[REQ-DAT-001.6]` |
| G33 | Run `sed -i 's/$/\r/' lib/domain/satellite_catalog.dart` (CRLF in the catalog file) | `[REQ-DAT-001.6]` |
| G34 | Run `printf '\xEF\xBB\xBF' \| cat - test/domain/celestrak_tle_snapshot.dart > /tmp/g34 && mv /tmp/g34 test/domain/celestrak_tle_snapshot.dart` (BOM in the snapshot file) | `[REQ-DAT-001.6]` |
| G35 | Run `sed -i 's/$/\r/' specs/req-dat-001.md` (CRLF in the spec file) | `[REQ-DAT-001.6]` |
| G36 | Run `sed -i 's/$/\r/' "docs/Wintek— Project Brief.md"` (CRLF in the brief file) | `[REQ-DAT-001.6]` |
| G37 | Append the line `// Platform.script` to the guard test file | `[REQ-DAT-001.6]` |
| G38 | Replace the line `// REQ-DAT-001.4` with `// REQ-DAT-001.x` in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-DAT-001.6]` |
| G39 | Delete the file `test/domain/satellite_catalog_test.dart` | `[REQ-DAT-001.6]` |
| G40 | Delete the file `specs/req-dat-001.md` | `[REQ-DAT-001.6]` |

Inside the table, `\|` is a single pipe. In rows U1 to U4 the unit test file still compiles, because only values change. In G11 and G12 the unit test file no longer compiles, which does not affect the guard: the guard reads text and runs on its own.

No row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V2 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that implements this spec lists the snapshot capture (the four URLs and the `// Fetched:` time), V1–V10, U1–U6, G0 and G1–G40, each with its observed result. A pull request without this list is incomplete regardless of its check status. This checklist is the one manual step of this spec: a reviewer reads it, and no command verifies it.

## Edge Cases & Errors

- **NOAA moves another satellite into the GOES-East role.** The app keeps tracking 60133, GOES 19, until this spec changes. The change is a new revision of this spec: a new row 4 and new doc lines, with a new SATCAT check date and a new snapshot entry. The ADR note keeps its date, as a record of what was confirmed when. If the new catalog number has more than five digits (Alpha-5), REQ-DAT-001.2 fails, and the remedy is a new ADR that supersedes ADR-0003 decision 1, never a relaxed test.
- **CelesTrak renames an object.** A new SATCAT name does not change the display name, which is the app's own. It changes only the CelesTrak name column and the snapshot. A snapshot taken after the rename fails REQ-DAT-001.3 and .6 until this spec is revised. The fix is the revision, never an edited token.
- **Object decayed or no GP data.** If the GP request of an object returns "No GP data found" or no TLE at implementation time, the snapshot is not written and implementation stops. The developer decides between a revision of this spec and waiting. A decayed object after implementation is a run-time condition of req-dat-002 to req-dat-004 and req-sta-001, not of the catalog.
- **CelesTrak unreachable or rate-limited at implementation time.** The capture waits and retries later, and never in a loop (Constitution principle 10). CelesTrak may answer an error page with status 200, so step 2 of the capture accepts only three lines of a TLE. Nothing is committed until the four responses are complete.
- **A snapshot TLE that the parser rejects.** If `OrbitalElements.fromTle` throws on a TLE copied unchanged from CelesTrak, REQ-DAT-001.3 fails. That is a defect of req-orb-003 or a format change at CelesTrak. Implementation stops and the developer decides; neither the token nor the parser is changed in this pull request.
- **Trailing spaces and CRLF from CelesTrak.** The name line is padded to 24 characters and the response may use CRLF. The snapshot holds the name without trailing spaces and the file is LF. G24, G33 and G34 prove that the guard rejects the raw forms.
- **A stale snapshot.** The snapshot ages from the day it is fetched. That is expected: it proves identity, and the catalog numbers do not age. No test compares its epoch with the current time. It is never used as live data, so the stale-data warning of req-ui-004 does not apply to it.
- **The same catalog number reused for another purpose.** A NORAD catalog number is never reassigned, so the number alone identifies the object. The CelesTrak-name check of REQ-DAT-001.3 still catches a typo that lands on another real object, such as U6.
- **Catalog numbers elsewhere in tests.** The one-source rule covers library files only. Test files of either suite may contain catalog numbers. For example, the parser tests of req-orb-003 and req-orb-009 use NOAA 14 (23455), and the official SGP4 vectors use many numbers.
- **Brief file name.** The path contains U+2014 and a space. Commands quote it, and the guard builds it from a string literal saved as UTF-8. A tool that rewrites the name in another normalization fails the missing-file check of REQ-DAT-001.6, never silently.
- **CRLF or BOM in a new or edited file.** Rejected by REQ-DAT-001.6. The fix is to rewrite the file as UTF-8 without BOM and with LF, never to relax the test.
- **Network or CI failure.** Nothing in this spec uses the network at run time or in CI. A failed `flutter pub get`, a timeout or a runner failure is handled as req-inf-002 defines and never counts as a pass. V10 needs `git fetch`; if it fails, or its precondition does not hold, V10 counts as not run. A U or G row whose output shows a compilation or resolution error of the file it targets, instead of the expected tag, counts as not run, never as a pass.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Shell.** The commands need a POSIX shell with GNU `sed`. In PowerShell they fail with "command not found"; that is an environment error, never a pass. In Git Bash on Windows, an argument that starts with `/`, such as a `///` or `//` line, is rewritten as a path. Set `MSYS_NO_PATHCONV=1` when scripting the edits, and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in the implementation pull request:

- Any network code, CelesTrak client, URL builder or request policy (req-dat-002). The GP request URL of Definitions is used once, by hand, to capture the snapshot.
- Any cache, repository, refresh threshold or data-age logic (req-dat-003, req-dat-004).
- Any lookup from a catalog number to an object, any parsing of names from CelesTrak, or any mapping of OMM fields. req-dat-004 adds a lookup if it needs one, with its own revision of the members rule of REQ-DAT-001.4.
- Colours, icons or any theme token per object (req-ui-001, req-viz-005).
- Orbit classes, international designators, launch dates, operators or descriptions in code. They appear only as information in the Definitions table.
- Any provider, widget or screen, and any change to `lib/main.dart`, whose placeholder text already names the four objects.
- Any change to `packages/orbital_core`, its tests or its guards. The core keeps knowing no tracked object.
- Any change to either `pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yml`, `test/support/repo_root.dart`, `test/dependency_guard_test.dart` or the constitution.
- Any change to the ADR file or the brief file in the implementation pull request. Their edits belong to the pull request of this spec (REQ-DAT-001.5).
- A new ADR. Decision 1 of ADR-0003 is confirmed, not superseded.
- Any change to `specs/req-dat-001.md` in the implementation pull request, except a behaviour change approved by the developer (REQ-DAT-001.6, V10).
- Any change to `docs/roadmap.md` in the implementation pull request. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
