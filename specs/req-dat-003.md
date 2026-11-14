# req-dat-003 — Local element cache

- **Status:** Draft (revision 2), after the first QA audit, pending a second audit. The first audit was made by the author of the spec; the second should be made by someone else, or by a session that did not draft it.
  - **Approved before drafting (2026-11-14):**
    - one cache file per tracked object, named from its `noradId`, so a damaged file costs one object and never four;
    - the cache directory is injected; req-dat-004 resolves it as the application support directory of `path_provider`, which the operating system does not clear on its own, so the offline feature of Constitution principle 9 does not vanish unannounced;
    - the cache writes only a success of the GP client of req-dat-002, and it reads back an entry of its own type, so a value read from disk is never presented as a fresh download;
    - a stored document is a JSON object with a schema version, the catalog number, the three lines of the success and its arrival instant in UTC; the member names are fixed by this spec, because they are a contract on disk;
    - a write goes to a temporary file in the same directory first and is then renamed onto the cache file; a missing cache directory is created;
    - the arrival instant is stored as the GP client stamped it; the cache never reads a clock;
    - a read validates the document again, including `OrbitalElements.fromTle` and the requested catalog number; every problem is reported as no entry, never thrown, and the file is left as it is;
    - a failed write is reported as a value, never thrown; a Dart `Error` is never caught;
    - asynchronous file access only (Constitution principle 13);
    - no operation that deletes, clears or lists cache files; deleting them by hand is harmless and tested (Constitution principle 11);
    - the tests write only inside temporary directories that they create and delete, with `dart:io` in the application suite, never in `packages/orbital_core`, and they use no YAML parser.
  - **Approved for revision 2 (2026-11-14):** all findings of the first QA audit, as follows.
    - Fixed in requirements and tests: 1 (a shifted value, not a shifted key), 2 (JSON integers), 3 (name line without trailing blanks), 4 (deletion cases read with the cache that wrote), 7 (a write validates its success), 11 (a case for the `noradId` member alone, so M8 can fail), 12 (no listing), 13 (V13: no test writes into the repository), 14 (G rows for every guard rule), 16 (the temporary file is flushed before the rename, and the promise is narrowed), 17 (no `catchError`, `onError` or zone handler).
    - Fixed in the text: 5 (declaration lines defined here, with `]`), 8 (definitions copied from req-dat-002 instead of referenced), 9 (the public constructor of the success type is a stated dependency), 15 (G rows that do not compile are listed), 18 (Windows file locks), 19 (the base of V10 is recorded once).
    - Resolved by a dated note in ADR-0001: 6. The note is added by the pull request of this spec and checked by REQ-DAT-003.7.
    - Removed from this spec: 10. The rule for an implementation that reaches `main` without a pull request belongs to the commit workflow, not to a spec.
    - No change needed: 20 and 21.
  - **Beyond roadmap row 15:** the dated note in ADR-0001 (REQ-DAT-003.7). Otherwise nothing: the roadmap row asks for "the last good payload with its fetch timestamp under app storage"; req-dat-002 produces that timestamp, and this spec stores it.
- **Roadmap row:** 15 of 33 (MVP)
- **Blocks:**
  - req-dat-004: creates the cache with the application support directory, writes every success of the GP client, reads the cache at a cold start, decides when to refresh and computes the data age from the stored arrival instant. Resolving the directory needs `path_provider` in a library file other than the cache library file, which this spec does not forbid.
  - A future settings spec: stores settings in a JSON file of its own, never in a cache file (ADR-0001, note of REQ-DAT-003.7).
- **Depends on:**
  - req-dat-001: `TrackedObject`, its `noradId` and the snapshot data file `test/domain/celestrak_tle_snapshot.dart`;
  - req-dat-002: the success type of the GP client and the values it carries (tracked object, name line, line 1, line 2, arrival instant), and the rules of REQ-DAT-002.4, which apply to every application library file, this one included. The tests of this spec build successes with the public constructor of that type, as the implementation of req-dat-002 declares it; req-dat-002 does not fix that constructor, so a revision that removes it requires a revision of this spec;
  - req-orb-003: `OrbitalElements.fromTle`, its `catalogNumber` and the `FormatException` it throws;
  - req-inf-001 and req-inf-002: both suites, the CI gates, the `lib/data` directory of the scaffold and `test/support/repo_root.dart`;
  - ADR-0001: `path_provider` is approved for the directory of the cached JSON (used by req-dat-004), and hand-written JSON with `dart:convert` instead of code generation.
- **ADR:** none new. The pull request of this spec adds one dated note to ADR-0001 (REQ-DAT-003.7); the approved packages and the decisions of ADR-0001 are unchanged. The cache uses only the Dart core libraries `dart:convert` and `dart:io`, and the format that ADR-0003 fixes.
- **No new dependency and no formula.** Neither manifest changes. The cache adds no mathematics, so Constitution principle 6 is not triggered.

## Context & Objective

Roadmap row 15 asks to "persist the last good payload with its fetch timestamp under app storage, so a cold start needs no network and a deleted cache is harmless".

Constitution principle 10 makes the last good response "the only source of orbital elements", and principle 9 makes offline a feature: with cached elements and no network, the app still propagates and draws. Both need the element sets to survive a restart. req-dat-002 delivers each element set once, as text validated by the core, with the UTC instant it arrived. This spec keeps that text on the device, one file per tracked object, and gives it back after a restart exactly as it was served.

The cache is deliberately small. It knows one directory, one file name per object and one document shape. It does not decide when to write, when to read, or how old is too old: those belong to req-dat-004, which is the only caller. It never talks to the network, never reads a clock and never deletes anything.

### Decisions approved before drafting

- **One file per object.** A dataset of req-dat-002 is the GP data of one tracked object, so the cache keeps one file per object. A damaged or deleted file costs that object only; the other three are still served. The file name is built from `TrackedObject.noradId`, never from a literal (req-dat-001, one source of truth). If req-dat-001 ever replaces an object, its new catalog number gives a new file name, and the old file is simply never read again.
- **Settings get their own file.** ADR-0001 says that "settings ride in the same cached JSON until a spec proves that insufficient". With one file per object, each replaced whole at every write, a setting stored in a cache file would be lost at the next write. This spec therefore records, as a dated note in ADR-0001, that settings get a JSON file of their own in the same directory when a spec needs them (REQ-DAT-003.7). The approved packages are unchanged.
- **Injected directory, resolved by req-dat-004.** The cache receives its directory and never looks it up, just as the GP client receives its HTTP client. req-dat-004 resolves it as the application support directory. Unlike the application cache directory, the operating system does not empty it when space runs low, so the app does not lose its offline elements without notice. The tests inject temporary directories and need no platform plugin.
- **Writes take a valid success, reads give an entry.** A write accepts only a success of the GP client, and checks it again with the rules of a read before it writes anything. The success type has a public constructor, so the type alone cannot keep out a success built by hand with text that the core rejects; the check does. A read returns an entry of the cache's own type, with the same values, because an element set read from disk did not just arrive from CelesTrak.
- **A fixed document.** Each file holds one JSON object with a schema version, the catalog number, the name line, both element lines and the arrival instant. The member names and the meaning of each value are fixed in Definitions, because a file written by one version of the app is read by the next. A change of the document is a new schema version, in a revision of this spec.
- **Replacement by rename.** A write first writes the whole document to a temporary file in the cache directory, flushes it to storage, then renames it onto the cache file. A read therefore never sees part of a new document next to part of an old one. After a power loss, a file system may still keep the rename without the data; the cache file is then empty or damaged, a read reports no entry, and the next write repairs it. The previous document is lost in that case, which is the price of not keeping a second copy.
- **No clock.** The arrival instant is the one that the GP client read from its wall clock after the response arrived (req-dat-002). The cache stores it unchanged, converted to UTC if it is not, and never stamps again, so the data age of req-dat-004 measures the age of the download, not of the write.
- **Validated on read.** A document is accepted only if every member is present with the right type, the schema version is known, the catalog number is the one requested, the element lines are accepted by `OrbitalElements.fromTle` with that catalog number, and the arrival instant is a UTC instant. A file can be damaged, truncated, edited by hand or written by a future version; none of these may reach a propagator or crash the app.
- **Failures are values.** A read completes with an entry or with no entry. A write completes with a value that tells whether the cache file now holds the new document. Neither throws for a problem of the file system or of the document. A Dart `Error`, such as a `StateError`, is a programming error and is not caught, neither by a catch clause, nor by an error callback, nor by a zone.
- **Nothing is deleted or listed.** The cache has no operation that deletes, clears or lists files. A bad file stays until the next good write replaces it. Deleting a cache file, or the whole directory, by hand is harmless: the next read reports no entry and the next write creates both again (Constitution principle 11).
- **Doc lines without angle brackets.** The fixed doc lines of REQ-DAT-003.5 use `NORADID` as a placeholder instead of a bracketed one. In req-dat-002, the bracketed placeholder of a fixed doc line raised `unintended_html_in_doc_comment`, and the implementation had to disable that lint for the whole client file.

### Decisions that follow from the Constitution

- **Data layer.** The cache is an implementation detail of the data layer (Constitution principle 5). It imports the catalog of the domain layer, the GP client of the data layer, the core and the Dart core libraries `dart:convert` and `dart:io`; never Flutter, Riverpod, `path_provider` or `package:http`.
- **Small public surface.** The cache library file declares exactly two public types: the cache and its entry. Everything else in the file is private (REQ-DAT-003.5).
- **Plain JSON, payloads only.** The document holds the CelesTrak payload of one object and the values needed to file and date it, in plain JSON under app storage, with no account, key or user data (Constitution principle 11).
- **Off the frame path.** Every file access is asynchronous, and the cache is never called from a painter or a per-frame provider (Constitution principle 13). Wiring it to providers is req-dat-004 and req-sta-001.
- **Still not a network boundary.** The rules of REQ-DAT-002.4 apply to the cache library file like to any other application library file: it names no CelesTrak host and uses no HTTP or socket API. The guard of req-dat-002 already checks this, and V9 repeats it.

## Definitions used by every requirement

These definitions are normative. The first eight are copied from `specs/req-dat-002.md` so that this spec does not change meaning when that one is revised; the definition of a declaration line adds `]`.

- **Blank characters:** space (U+0020), tab (U+0009) and carriage return (U+000D).
- **Application library files:** every file whose name ends in `.dart` under `lib`, searched recursively.
- **Line match:** a line matches a string when, with leading and trailing blank characters removed, it is equal to the string character for character.
- **Code line:** a line whose text, with leading blank characters removed, does not start with `//`.
- **Import URI:** for a line whose text, with leading blank characters removed, starts with `import ` or `export `, the text between its first two single quotes.
- **Declaration line:** a line of the cache library file whose first character is not a blank character and that does not start with `//`, `@`, `import `, `}`, `)` or `]`. With `dart format`, these are the first lines of the top-level declarations; a line that starts with `]` closes a collection literal that spans several lines.
- **Public class declaration:** a declaration line that starts with `class `, `final class `, `base class ` or `sealed class `, where the next word, the class name, does not start with `_`.
- **Private declaration:** a declaration line whose head contains a word that starts with `_`. The head is the text before the earliest occurrence of any of `(`, ` =`, `;` or `{`; the whole line if none occurs.
- **Snapshot entry k:** as defined by `specs/req-dat-001.md`: the name token, line 1 and line 2 of the tracked object at position k, from 1 to 4.
- **Cache library file:** `lib/data/element_cache.dart`.
- **Cache:** the one public type of the cache library file that reads and writes cache files. Its name, the name of the entry type and the names of their members are the implementer's choice, within the public-surface rule of REQ-DAT-003.5.
- **Entry:** the value that a read returns when it finds a valid stored document. It carries the tracked object, the name line, line 1, line 2 and the arrival instant in UTC.
- **Success:** a value of the success type of the GP client of req-dat-002. It carries the tracked object, the name line, line 1, line 2 and the arrival instant.
- **Success of position k at instant T:** the success whose tracked object is the object at position k, whose name line, line 1 and line 2 are those of snapshot entry k, and whose arrival instant is T.
- **Valid name line:** a string that is not empty, contains no LF and does not end with a blank character.
- **Valid success:** a success whose name line is a valid name line, and whose line 1 and line 2 are accepted by `OrbitalElements.fromTle` with a `catalogNumber` equal to the `noradId` of its tracked object.
- **Cache directory:** the directory that the cache receives when it is created.
- **Cache file of an object:** the file named `gp_` followed by the decimal `noradId` of the object, with no leading zeros, followed by `.json`, directly inside the cache directory. For ISS, `gp_25544.json`.
- **Temporary file of an object:** the file named like its cache file followed by `.tmp`, directly inside the cache directory. For ISS, `gp_25544.json.tmp`.
- **Write:** one call of the cache that stores one success. Its result is a future that completes with `true` when the cache file of the success's object holds the stored document of that success, and with `false` otherwise.
- **Read:** one call of the cache for one tracked object. Its result is a future that completes with an entry, or with `null` when there is none.
- **Unit test file:** `test/data/element_cache_test.dart`, in the application suite. It covers REQ-DAT-003.1 to .4.
- **Guard test file:** `test/element_cache_guard_test.dart`, in the application suite. It covers REQ-DAT-003.5 to .7.
- **Snapshot data file:** `test/domain/celestrak_tle_snapshot.dart`, from req-dat-001. This spec reads it and never changes it.
- **Spec file:** `specs/req-dat-003.md`.
- **ADR file:** `docs/adr/ADR-0001-baseline-packages.md`.
- **Instants used by the tests:** T1 is 2026-11-14 11:00:00 UTC. T2 is 2026-11-14 15:00:00 UTC. T3 is 2026-11-14 11:00:00.123456 UTC, an instant with microseconds. L1 is 2026-11-14 11:00:00 in the local time of the machine that runs the tests, as a local (non-UTC) instant.
- **Arrival text of an instant:** a string that ends with `Z` and that `DateTime.parse` of the Dart core library turns into a UTC instant that denotes the same moment as the given one.
- **JSON integer:** a JSON number written with neither a fraction nor an exponent. `1` is a JSON integer; `1.0` and `1e0` are not.
- **Stored document of a success:** a JSON object with exactly these six members:
  - `schemaVersion`: the JSON integer `1`;
  - `noradId`: the `noradId` of the success's object, as a JSON integer;
  - `nameLine`, `line1` and `line2`: the name line, line 1 and line 2 of the success, as strings;
  - `fetchedAtUtc`: the arrival text of the success's arrival instant.
- **Valid stored document for an object:** a text that decodes as JSON to an object that has at least the six members above, where:
  - `schemaVersion` is the JSON integer `1`;
  - `noradId` is a JSON integer equal to the `noradId` of the object;
  - `nameLine` is a valid name line;
  - `line1` and `line2` are strings accepted by `OrbitalElements.fromTle` with a `catalogNumber` equal to the `noradId` of the object;
  - `fetchedAtUtc` is a string that ends with `Z` and that `DateTime.parse` accepts.

  Members other than these six are ignored.
- **Valid document of position k:** the stored document of the success of position k at T1, encoded as JSON text.
- **Catch line:** a code line of the cache library file that contains `catch (`.

## Functional Requirements

### REQ-DAT-003.1 — Write

A write of a valid success stores its document in the cache file of its object, through its temporary file, and completes with `true`.

**Acceptance (verified by the unit test file).** Each test creates the cache with a new, empty temporary directory.

- For each position k from 1 to 4, a write of the success of position k at T1 completes with `true`. Afterwards:
  - the cache directory contains exactly one item: the cache file of the object at position k, and no temporary file;
  - that file decodes as JSON to an object with exactly the six members of the stored document of that success, with those values;
  - its `fetchedAtUtc` ends with `Z`, and `DateTime.parse` turns it into an instant equal to T1.
- A write of the success of position 1 at L1 completes with `true`, and the `fetchedAtUtc` of the cache file of ISS ends with `Z` and turns into a UTC instant that denotes the same moment as L1.
- A write of the success of position 1 at T1, then of the success of position 1 at T2, completes with `true` both times. The cache directory then contains exactly one file, the cache file of ISS, and its `fetchedAtUtc` turns into T2. So a write replaces the previous document of its object.
- A write of the four successes of positions 1 to 4 at T1 leaves exactly four files in the cache directory: the four cache files, and no temporary file.
- A cache created with a directory that does not exist yet, inside the temporary directory, creates it at the first write, which completes with `true` and leaves the cache file of its object in it.

### REQ-DAT-003.2 — Write failures

A write that cannot store its document, or whose success is not a valid success, completes with `false` instead of throwing, and leaves the previous cache file of its object as it was.

**Acceptance (verified by the unit test file).** Each case completes with `false`, not with an error.

- **The cache directory is a file.** The cache is created with the path of an existing file inside the temporary directory, and a write of the success of position 1 at T1 completes with `false`.
- **The temporary file cannot be written.** A write of the success of position 1 at T1 completes with `true`. Then a directory is created at the path of the temporary file of ISS, and a write of the success of position 1 at T2 completes with `false`. Afterwards the cache file of ISS holds, byte for byte, what it held after the first write, and a read of ISS returns an entry whose arrival instant is T1.
- **The cache file cannot be replaced.** A directory is created at the path of the cache file of ISS, and a write of the success of position 1 at T1 completes with `false`.
- **Not a valid success.** In an empty cache directory, each of these writes completes with `false`, and afterwards the cache directory contains no item:
  - the success of position 1 at T1 with the last character of line 2 replaced by a different digit (bad checksum);
  - the success whose tracked object is ISS, with the name line, line 1 and line 2 of snapshot entry 2, at T1 (another object's lines);
  - the success of position 1 at T1 with an empty name line;
  - the success of position 1 at T1 with three spaces appended to the name line.
- **Not a valid success, after a good write.** A write of the success of position 1 at T1 completes with `true`. Then a write of the success of position 1 at T2 with a bad checksum, as above, completes with `false`, and the cache file of ISS holds, byte for byte, what it held after the first write.

That a Dart `Error` is not caught is verified by the guard test file (REQ-DAT-003.5, no Dart `Error` caught).

### REQ-DAT-003.3 — Read

A read returns the entry of a valid stored document as it was written, from any cache on the same directory, and no entry when there is no cache file.

**Acceptance (verified by the unit test file).**

- **Round trip.** For each position k from 1 to 4, after a write of the success of position k at T1, a read of the object at position k by a second cache, created with the same directory, completes with an entry whose:
  - tracked object is the object at position k;
  - name line, line 1 and line 2 are those of snapshot entry k;
  - arrival instant is in UTC and equal to T1.

  So the entry comes from the file, not from memory, as after a restart.
- **Microseconds.** After a write of the success of position 1 at T3, a read of ISS completes with an entry whose arrival instant is equal to T3.
- **Ignored members.** A cache file of ISS that holds the valid document of position 1 with one more member, `"extra": true`, is read as the entry of that document.
- **No cache file.** Each of these completes with `null`:
  - a read of ISS in an empty cache directory;
  - a read of ISS when the cache directory does not exist;
  - a read of ISS when only the cache file of Tiangong exists;
  - a read of ISS, by the same cache that wrote, after a write of the success of position 1 at T1 and the deletion of the cache file of ISS;
  - a read of ISS, by the same cache that wrote, after a write of the success of position 1 at T1 and the deletion of the whole cache directory.

  The last two use the cache that wrote, so an entry kept in memory would be caught.
- **Recovery.** After the deletion of the whole cache directory, a write of the success of position 1 at T2 by the same cache completes with `true`, and a read of ISS returns an entry whose arrival instant is T2.

### REQ-DAT-003.4 — Invalid documents

A cache file that does not hold a valid stored document for its object is read as no entry, never as an error, and is left unchanged.

**Acceptance (verified by the unit test file).** For each case below, the cache file of ISS is written by the test with the given content, then a read of ISS completes with `null`, not with an error, and afterwards the cache file of ISS holds exactly the bytes that the test wrote.

- **Not a JSON object:**
  - an empty file;
  - the text `not json`;
  - the text `[]`;
  - the text `null`;
  - the valid document of position 1 with its last character removed (a truncated write);
  - the bytes `FF FE 00`, which are not UTF-8.
- **Wrong schema version:** the valid document of position 1 with `schemaVersion` set to `2`; again set to the string `"1"`; and again set to `1.0`, which is not a JSON integer.
- **Missing member:** for each of the six members, the valid document of position 1 without that member.
- **Wrong type:** the valid document of position 1 with `noradId` set to the `noradId` of ISS as a string; again with `noradId` set to the `noradId` of ISS followed by `.0`, which is not a JSON integer; and again with `nameLine` set to the number `1`.
- **Invalid name line:** the valid document of position 1 with `nameLine` set to the empty string, and again with three spaces appended to `nameLine`.
- **Another object:**
  - the valid document of position 2, which is consistent but belongs to Tiangong;
  - the valid document of position 1 with only `noradId` set to the `noradId` of Tiangong: the lines are those of ISS, and the member is not the requested catalog number;
  - the valid document of position 1 with `line1` and `line2` replaced by those of snapshot entry 2: the catalog number of the lines differs from the requested one.
- **Rejected element lines:** the valid document of position 1 with the last character of the value of `line2` replaced by a different digit (bad checksum), and again with one space inserted at the start of the value of `line1` (a shifted line).
- **Arrival instant not in UTC or not an instant:** the valid document of position 1 with `fetchedAtUtc` set to `2026-11-14T11:00:00.000`, with no `Z`; again with `2026-11-14T11:00:00.000+00:00`; again with `yesterday`; and again with the number `0`.

In addition, when a directory exists at the path of the cache file of ISS, a read of ISS completes with `null`, not with an error.

### REQ-DAT-003.5 — Placement, public surface, boundaries and documented contract

The cache lives in the data layer, exposes only the cache and its entry, reaches the disk only asynchronously, flushes before it renames, never looks up its directory, never reads a clock, never deletes or lists files, never catches a Dart `Error`, and documents its contract in fixed lines.

**Acceptance (verified by the guard test file):**

- **Placement.** The cache library file exists.
- **Imports.** No line of the cache library file, with leading blank characters removed, starts with `export` or `part`. Every line that, with leading blank characters removed, starts with `import ` has one of these import URIs:
  - `dart:async`;
  - `dart:convert`;
  - `dart:io`;
  - `package:orbital_core/orbital_core.dart`;
  - `package:wintek/data/celestrak_gp_client.dart`;
  - `package:wintek/domain/satellite_catalog.dart`.

  All but `dart:async` are each present. So the cache imports neither Flutter, nor Riverpod, nor `path_provider`, nor `package:http`.
- **Public surface.**
  - Every declaration line is a public class declaration or a private declaration.
  - There are exactly two public class declarations: the cache and the entry.

  So the file declares no public function, constant, variable, enum, typedef, extension or mixin, and no second cache.
- **Asynchronous only.** The cache library file does not contain the substring `Sync(`.
- **Flushed before the rename.** The cache library file contains `flush: true` or `.flush(`.
- **No directory lookup.** The cache library file contains neither `path_provider` nor `getApplication`.
- **No clock.** The cache library file does not contain `DateTime.now`.
- **Nothing deleted or listed.** The cache library file contains none of `.delete(` and `.list(`. `Sync(` already excludes their synchronous forms.
- **No Dart `Error` caught.**
  - Every catch line contains ` on `.
  - The cache library file contains none of `on Object`, `on Error` and `on dynamic`.
  - The cache library file contains none of `catchError`, `onError` and `runZoned`.

  So every catch names the exceptions it handles, none of them is a Dart `Error`, and no error callback or zone handler catches what a catch clause may not.
- **Member names.** For each of `schemaVersion`, `noradId`, `nameLine`, `line1`, `line2` and `fetchedAtUtc`, at least one code line of the cache library file contains that name between single quotes.
- **No catalog number.** The cache library file contains none of the substrings `25544`, `48274`, `38011` or `60133` (req-dat-001, one source of truth; also checked by the guard of req-dat-001).
- **Doc lines.** The cache library file contains a line that matches each of:
  - `/// The local element cache of Wintek: the last good CelesTrak GP payload of each tracked object, one JSON file per object (specs/req-dat-003.md).`
  - `/// File: gp_NORADID.json in the injected directory, where NORADID is TrackedObject.noradId; each write goes to gp_NORADID.json.tmp first, is flushed and is then renamed.`
  - `/// Writes only a valid success of the GP client, with its arrival instant as served; the cache never reads a clock (Constitution principle 10).`
  - `/// Reads validate the document again with OrbitalElements.fromTle and the requested catalog number; anything else is no entry, never an error.`
  - `/// Asynchronous file access only, never on the frame path (Constitution principle 13); deleting any cache file or the directory is harmless (Constitution principle 11).`
  - `/// The directory is injected and resolved by req-dat-004; this file never looks it up.`

### REQ-DAT-003.6 — Test hygiene

The new test files follow the hygiene rules of req-dat-002, and the unit test file touches the disk only inside temporary directories that it creates and deletes.

**Acceptance (verified by the guard test file):**

- **Unit test imports.**
  - Every line of the unit test file that, with leading blank characters removed, starts with `import ` has one of these import URIs:
    - `dart:convert`;
    - `dart:io`;
    - `package:flutter_test/flutter_test.dart`;
    - `package:wintek/data/celestrak_gp_client.dart`;
    - `package:wintek/data/element_cache.dart`;
    - `package:wintek/domain/satellite_catalog.dart`;
    - `../domain/celestrak_tle_snapshot.dart`.
  - `dart:io`, `package:flutter_test/flutter_test.dart`, `package:wintek/data/celestrak_gp_client.dart`, `package:wintek/data/element_cache.dart` and `../domain/celestrak_tle_snapshot.dart` are each present.
  - No line of the unit test file, with leading blank characters removed, starts with `export`.

  So the unit test file uses neither `path_provider`, nor `package:http`, nor the core directly.
- **Temporary directories only.** The unit test file contains the substring `createTemp(`, and at least one of `tearDown(` and `addTearDown(`. It does not contain `Directory.current`. That no test writes into the repository is also checked by V13.
- **Unit test citation.** The unit test file contains a line that matches `// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; every test writes only inside a temporary directory it creates and deletes (Constitution principle 11).`
- **Tags.**
  - For each N from 1 to 4, the unit test file contains a line that matches `// REQ-DAT-003.N`. Let L be the next non-empty line after it, with leading blank characters removed. L starts with `group('REQ-DAT-003.N ` or `test('REQ-DAT-003.N `. Alternatively, L is equal to `group(` or `test(`, and the next line after L, with leading blank characters removed, starts with `'REQ-DAT-003.N `. Either way, every failing unit test names its requirement.
  - For each N from 5 to 7, the guard test file contains a line that matches `// REQ-DAT-003.N`. The next non-empty line after it, with leading blank characters removed, starts with `test(`.
  - The guard test file contains no line that matches `// REQ-DAT-003.1`, `// REQ-DAT-003.2`, `// REQ-DAT-003.3` or `// REQ-DAT-003.4`. It builds those tags and name prefixes by interpolation, never as literals, so that V6 prints only its own tags.
- **Self-matching tokens.** The guard test file builds the tokens `Platform.script` and `skip:` by concatenation of shorter string literals, never as one literal, because it checks its own text for them.
- **No skipped tests.** Neither the unit test file nor the guard test file contains the substring `skip:`.
- **Bytes.** None of these files contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the cache library file, the unit test file, the guard test file, the spec file and the ADR file.
- **Repository root.** The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- **Plain text only.** The guard test file reads files as plain text with the Dart core and `dart:io` libraries of the application suite. Its import URIs are only `dart:io`, `package:flutter_test/flutter_test.dart` and `support/repo_root.dart`, so it uses no YAML, JSON, Markdown or other parser.
- **Missing files fail.** Each of the following produces a failing test when missing, never a skipped or passing one: the cache library file, the `lib` directory, the unit test file, the snapshot data file, the spec file and the ADR file. A missing guard test file is caught by V2.
- **Failure messages.** Every failure message of the guard test file starts with `[REQ-DAT-003.N]`, where N is the requirement whose check failed, and carries `specs/req-dat-003.md` on the same line as that tag.

**Acceptance (verified by command V10).** Compared with the merge of this spec into `main`, the implementation changes exactly the three files of V10. The one allowed exception is the spec file: when the implementation needs a behaviour change, it may also change `specs/req-dat-003.md`, with the developer's approval linked in the pull request description (Constitution principle 2). V10 is a local check: CI does not run it, and the pull request checklist reports its result.

### REQ-DAT-003.7 — The settings note in ADR-0001

ADR-0001 records, as a dated note, that settings do not ride in a cache file.

**Acceptance (verified by the guard test file).** The pull request of this spec adds the note; the guard of the implementation keeps it.

- The ADR file contains a line that matches `- **Note (2026-11-14, req-dat-003):** The element cache keeps one JSON file per tracked object, and every write replaces its file whole, so no setting can ride in a cache file. Settings, when a spec needs them, get their own JSON file in the same directory. The approved packages are unchanged.`
- The ADR file contains a line that contains `Settings ride in the same cached JSON until a spec proves that insufficient.`, and the note line comes after the first such line. So the note sits under the sentence it qualifies, and that sentence is not removed.

## Mathematical Validation / Testing

This spec adds no formula, so there is nothing to check against Vallado or Curtis, and Constitution principle 6 is not triggered. Its evidence is behaviour against fixed files:

- every payload that a test writes is rebuilt from the snapshot of req-dat-001, whose provenance that spec records, or is written in this spec;
- REQ-DAT-003.1 and .3 prove that a document written by the cache is read back with exactly the values of the success, including microseconds of the arrival instant;
- REQ-DAT-003.2 and .4 prove that every failure of the file system, of the success or of the document is a value, and that no bad file is changed;
- no test reads or writes outside a temporary directory that it created, and no test sends a request to CelesTrak.

All commands in this section run from a POSIX shell with GNU `sed`: Git Bash on Windows, or a shell on Linux.

### Local checks (run on the implementation branch before opening the pull request)

| # | Command (from repository root) | Expected | Proves |
| --- | --- | --- | --- |
| V0 | `git ls-files --eol specs/req-dat-003.md docs/adr/ADR-0001-baseline-packages.md \| grep -c "w/lf"` | standard output `2` | Precondition: the working tree holds the spec and the ADR with LF |
| V1 | `flutter test test/data/element_cache_test.dart --reporter expanded` | exit 0 | REQ-DAT-003.1 – .4 |
| V2 | `flutter test test/element_cache_guard_test.dart --reporter expanded` | exit 0 | REQ-DAT-003.5 – .7 |
| V3 | `flutter test` | exit 0 | All of the above; the guards of req-dat-001 and req-dat-002 and `test/dependency_guard_test.dart` still pass |
| V4 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V5 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V6 | `grep -ohE "// REQ-DAT-003\.[0-9]+" test/element_cache_guard_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-003.5,// REQ-DAT-003.6,// REQ-DAT-003.7` | REQ-DAT-003.6 (tags of the guard test file) |
| V7 | `grep -ohE "// REQ-DAT-003\.[0-9]+" test/data/element_cache_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-003.1,// REQ-DAT-003.2,// REQ-DAT-003.3,// REQ-DAT-003.4` | REQ-DAT-003.6 (tags of the unit test file) |
| V8 | `dart pub get && dart analyze --fatal-infos && dart test`, inside `packages/orbital_core` | exit 0 | The core is untouched and still passes on its own (Constitution principle 3) |
| V9 | `{ grep -rlE "package:http/\|HttpClient\|Socket\|InternetAddress" lib; grep -rli "celestrak\.org" lib; } \| LC_ALL=C sort -u \| paste -sd, -` | standard output `lib/data/celestrak_gp_client.dart` | REQ-DAT-002.4 still holds: the cache is not a network boundary |
| V10 | `git diff --name-only <base>...HEAD \| LC_ALL=C sort \| paste -sd, -`, where `<base>` is the base of V10 below | standard output `lib/data/element_cache.dart,test/data/element_cache_test.dart,test/element_cache_guard_test.dart`; or, only when the pull request links the developer's approval of a spec diff, the same list with `specs/req-dat-003.md` appended | REQ-DAT-003.6 (only the files of this spec change) |
| V11 | `grep -rlE "25544\|48274\|38011\|60133" lib packages/orbital_core/lib \| paste -sd, -` | standard output `lib/domain/satellite_catalog.dart` | req-dat-001 one source of truth still holds |
| V12 | `grep -rl "path_provider" lib \| paste -sd, -` | empty standard output | REQ-DAT-003.5: no library file looks up the cache directory yet |
| V13 | `flutter test --no-pub test/data/element_cache_test.dart > /dev/null && git status --porcelain` | exit 0 and empty standard output | REQ-DAT-003.6: no unit test writes into the repository |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V3 to V5 and V8 on every pull request.

- `lib/data/.gitkeep` stays, so V10 lists no deletion.
- In V12, `grep` exits with 1 when nothing matches; the expected result is the empty output, not the exit status. V12 holds until req-dat-004, which resolves the directory with `path_provider` in another library file.
- V13 runs after every file of the implementation is committed, like the negative checks below; with uncommitted work it proves nothing and counts as not run.

**Base of V10.** V10 compares against the merge commit of the spec pull request, not against `origin/main`. On the first run, after `git fetch origin main`, find it with `git log --first-parent --merges --format=%H -1 origin/main -- specs/req-dat-003.md`, and record that hash in the pull request checklist. Every later run uses the recorded hash, so a later merge that touches the spec cannot move the base. If the spec pull request was squashed, that command finds no merge commit; V10 then counts as not run, never as a pass or a failure.

**Precondition of the new files.** Save the new files as UTF-8 without BOM and with LF. `.gitattributes` (`* text=auto eol=lf`) normalizes what enters the repository, but a Windows editor can still write CRLF into the working tree, and REQ-DAT-003.6 reads the working tree. If V0 prints less than `2`, rewrite each file that `git ls-files --eol` shows with `w/crlf` from the index, for example `rm docs/adr/ADR-0001-baseline-packages.md && git checkout -- docs/adr/ADR-0001-baseline-packages.md`, and run V0 again.

### Local negative checks

These run after every file of the implementation is committed on the implementation branch. Before the first row, `git status --porcelain` must print nothing; otherwise stop, because the edits and the revert below would destroy uncommitted work.

After each row, revert with:

    git checkout -- lib test specs docs

After the last row, `git status --porcelain` must print nothing again. If it prints a line, a row left a file behind, and the rows count as not run until the tree is clean.

Every row runs `flutter test` with `--no-pub`, so no row resolves dependencies, needs the network or rewrites `pubspec.lock`.

**Unit test rows (U and M).** The command is:

    flutter test --no-pub --reporter expanded test/data/element_cache_test.dart 2>&1 | grep -F "[E]" | grep -F "<tag>"

For each row, apply the edit, run the command and confirm that it prints at least one line: a failing test whose name carries the requirement ID.

- U rows are mechanical edits, defined as in `specs/req-orb-010.md` (Local negative checks). "The cache file" is the cache library file. U3 to U5 replace a quoted member name, which REQ-DAT-003.5 requires to be present; U1 and U2 replace parts of the file names, which the doc lines contain too.
- M rows are mutants that depend on how the cache is written, so the implementer applies each one by hand, as the smallest change to the cache file that has the stated effect. The pull request description shows the diff of each M row next to its result, so a reviewer can judge that the mutant does what its row says.

| # | Edit | Tag expected |
| --- | --- | --- |
| U1 | Replace every occurrence of `gp_` with `gpx_` in the cache file | `REQ-DAT-003.1` |
| U2 | Replace every occurrence of `.tmp` with `.temp` in the cache file | `REQ-DAT-003.2` |
| U3 | Replace every occurrence of `'schemaVersion'` with `'version'` in the cache file | `REQ-DAT-003.1` |
| U4 | Replace every occurrence of `'noradId'` with `'catalogNumber'` in the cache file | `REQ-DAT-003.1` |
| U5 | Replace every occurrence of `'fetchedAtUtc'` with `'fetchedAt'` in the cache file | `REQ-DAT-003.1` |
| M1 | Write the document straight to the cache file, without the temporary file and the rename | `REQ-DAT-003.2` |
| M2 | Store the arrival instant converted to local time | `REQ-DAT-003.1` |
| M3 | Store the arrival instant truncated to whole seconds | `REQ-DAT-003.3` |
| M4 | Complete a failed write with `true` | `REQ-DAT-003.2` |
| M5 | Let the exception of a failed write propagate instead of completing with `false` | `REQ-DAT-003.2` |
| M6 | Remove the call of `OrbitalElements.fromTle` from the validation of a read | `REQ-DAT-003.4` |
| M7 | Remove the comparison of the parsed catalog number with the requested `noradId` on a read | `REQ-DAT-003.4` |
| M8 | Remove the comparison of the `noradId` member with the requested `noradId` | `REQ-DAT-003.4` |
| M9 | Accept any JSON integer as `schemaVersion` | `REQ-DAT-003.4` |
| M10 | Accept a `fetchedAtUtc` that does not end with `Z` | `REQ-DAT-003.4` |
| M11 | Accept an empty `nameLine` on a read | `REQ-DAT-003.4` |
| M12 | Let a `FormatException` of the JSON decoding propagate instead of completing with `null` | `REQ-DAT-003.4` |
| M13 | Let a `FileSystemException` of a read propagate instead of completing with `null` | `REQ-DAT-003.4` |
| M14 | Reject a document that has a member other than the six | `REQ-DAT-003.3` |
| M15 | Return the entry of the last write from memory instead of reading the file | `REQ-DAT-003.3` |
| M16 | Remove the validation of the success before a write | `REQ-DAT-003.2` |
| M17 | Store the arrival instant as given, without converting it to UTC | `REQ-DAT-003.1` |
| M18 | Accept a `schemaVersion` written as `1.0` | `REQ-DAT-003.4` |

- In rows U1 to U5 the unit test file still compiles, because only the cache file changes, and only in string literals and comments. If a U row changes nothing in the cache file, it counts as not run.
- M6 and M7 may share a validation with the write. If they do, the mutant also changes the write, and the row still reads only its own tag.
- M13 assumes that some case of REQ-DAT-003.4 makes the read raise a `FileSystemException`, such as the directory at the path of the cache file or the bytes that are not UTF-8. If the implementation avoids every such exception, for example by checking the file first and decoding the bytes itself, M13 counts as not run, and the reviewer reads the read path instead.

**Guard rows (G).** The command is:

    flutter test --no-pub test/element_cache_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-dat-003.md"

**Control run (G0).** With no edit applied, run the G command once for each tag `[REQ-DAT-003.5]`, `[REQ-DAT-003.6]` and `[REQ-DAT-003.7]`, and confirm that each prints nothing. A printed line means the output of a passing run already carries a tag and the spec path, so the rows below would prove nothing. Fix the guard test file before continuing. Then, for each G row, apply the edit, run the G command and confirm that it prints at least one line.

The edits are defined as in `specs/req-orb-010.md` (Local negative checks). "The cache file", "the unit test file", "the guard test file", "the spec file" and "the ADR file" are the files of Definitions. "The note line" is the line of REQ-DAT-003.7 that starts with `- **Note (2026-11-14, req-dat-003):**`.

| # | Edit | Tag expected |
| --- | --- | --- |
| G1 | Delete the file `lib/data/element_cache.dart` | `[REQ-DAT-003.5]` |
| G2 | Add `import 'package:flutter/foundation.dart';` as the first line of the cache file | `[REQ-DAT-003.5]` |
| G3 | Add `import 'package:path_provider/path_provider.dart';` as the first line of the cache file | `[REQ-DAT-003.5]` |
| G4 | Add `import 'package:http/http.dart';` as the first line of the cache file | `[REQ-DAT-003.5]` |
| G5 | Add `export 'package:wintek/data/celestrak_gp_client.dart';` as the first line of the cache file | `[REQ-DAT-003.5]` |
| G6 | Append the line `Future<void> clearAll() async {}` to the cache file | `[REQ-DAT-003.5]` |
| G7 | Append the line `class ExtraCache {}` to the cache file | `[REQ-DAT-003.5]` |
| G8 | Append the line `const String cacheFileName = 'cache.json';` to the cache file | `[REQ-DAT-003.5]` |
| G9 | Append the line `// readAsStringSync()` to the cache file | `[REQ-DAT-003.5]` |
| G10 | Append the line `// getApplicationSupportDirectory()` to the cache file | `[REQ-DAT-003.5]` |
| G11 | Append the line `// DateTime.now()` to the cache file | `[REQ-DAT-003.5]` |
| G12 | Append the line `// file.delete();` to the cache file | `[REQ-DAT-003.5]` |
| G13 | Append the line `// directory.list();` to the cache file | `[REQ-DAT-003.5]` |
| G14 | Append the line `void _swallow() { try {} catch (_) {} }` to the cache file | `[REQ-DAT-003.5]` |
| G15 | Append the line `// on Error catch (e)` to the cache file | `[REQ-DAT-003.5]` |
| G16 | Append the line `// on Object catch (e)` to the cache file | `[REQ-DAT-003.5]` |
| G17 | Append the line `// on dynamic catch (e)` to the cache file | `[REQ-DAT-003.5]` |
| G18 | Append the line `// future.catchError((_) => null);` to the cache file | `[REQ-DAT-003.5]` |
| G19 | Append the line `// stream.listen(print, onError: print);` to the cache file | `[REQ-DAT-003.5]` |
| G20 | Append the line `// runZonedGuarded(body, handler);` to the cache file | `[REQ-DAT-003.5]` |
| G21 | Replace every occurrence of `flush` with `fsync` in the cache file | `[REQ-DAT-003.5]` |
| G22 | Replace every occurrence of `'fetchedAtUtc'` with `"fetchedAtUtc"` in the cache file | `[REQ-DAT-003.5]` |
| G23 | Replace every occurrence of `'noradId'` with `"noradId"` in the cache file | `[REQ-DAT-003.5]` |
| G24 | Append the line `// ISS is 25544.` to the cache file | `[REQ-DAT-003.5]` |
| G25 | Delete the line `/// The local element cache of Wintek: the last good CelesTrak GP payload of each tracked object, one JSON file per object (specs/req-dat-003.md).` from the cache file | `[REQ-DAT-003.5]` |
| G26 | Delete the line `/// File: gp_NORADID.json in the injected directory, where NORADID is TrackedObject.noradId; each write goes to gp_NORADID.json.tmp first, is flushed and is then renamed.` from the cache file | `[REQ-DAT-003.5]` |
| G27 | Delete the line `/// Writes only a valid success of the GP client, with its arrival instant as served; the cache never reads a clock (Constitution principle 10).` from the cache file | `[REQ-DAT-003.5]` |
| G28 | Delete the line `/// Reads validate the document again with OrbitalElements.fromTle and the requested catalog number; anything else is no entry, never an error.` from the cache file | `[REQ-DAT-003.5]` |
| G29 | Delete the line `/// Asynchronous file access only, never on the frame path (Constitution principle 13); deleting any cache file or the directory is harmless (Constitution principle 11).` from the cache file | `[REQ-DAT-003.5]` |
| G30 | Delete the line `/// The directory is injected and resolved by req-dat-004; this file never looks it up.` from the cache file | `[REQ-DAT-003.5]` |
| G31 | Run `rm -rf lib/data` | `[REQ-DAT-003.5]` |
| G32 | Run `rm -rf lib` | `[REQ-DAT-003.6]` |
| G33 | Add `import 'package:http/http.dart';` as the first line of the unit test file | `[REQ-DAT-003.6]` |
| G34 | Add `import 'package:path_provider/path_provider.dart';` as the first line of the unit test file | `[REQ-DAT-003.6]` |
| G35 | Add `import 'package:orbital_core/orbital_core.dart';` as the first line of the unit test file | `[REQ-DAT-003.6]` |
| G36 | Replace every occurrence of `createTemp(` with `createTempX(` in the unit test file | `[REQ-DAT-003.6]` |
| G37 | Replace every occurrence of `earDown(` with `earDownX(` in the unit test file | `[REQ-DAT-003.6]` |
| G38 | Append the line `// Directory.current` to the unit test file | `[REQ-DAT-003.6]` |
| G39 | Delete the line `// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; every test writes only inside a temporary directory it creates and deletes (Constitution principle 11).` from the unit test file | `[REQ-DAT-003.6]` |
| G40 | Replace the line `// REQ-DAT-003.3` with `// REQ-DAT-003.x` in the unit test file | `[REQ-DAT-003.6]` |
| G41 | Replace every occurrence of `'REQ-DAT-003.1 ` with `'Write ` in the unit test file | `[REQ-DAT-003.6]` |
| G42 | Append the line `// skip: true` to the unit test file | `[REQ-DAT-003.6]` |
| G43 | Replace the line `// REQ-DAT-003.5` with `// REQ-DAT-003.x` in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-DAT-003.6]` |
| G44 | Append the line `// REQ-DAT-003.1` to the guard test file | `[REQ-DAT-003.6]` |
| G45 | Append the line `// Platform.script` to the guard test file | `[REQ-DAT-003.6]` |
| G46 | Append the line `// skip: true` to the guard test file | `[REQ-DAT-003.6]` |
| G47 | Add `import 'dart:convert';` as the first line of the guard test file | `[REQ-DAT-003.6]` |
| G48 | Run `sed -i 's/$/\r/' lib/data/element_cache.dart` (CRLF in the cache file) | `[REQ-DAT-003.6]` |
| G49 | Run `printf '\xEF\xBB\xBF' \| cat - lib/data/element_cache.dart > /tmp/g49 && mv /tmp/g49 lib/data/element_cache.dart` (BOM in the cache file) | `[REQ-DAT-003.6]` |
| G50 | Run `sed -i 's/$/\r/' test/data/element_cache_test.dart` (CRLF in the unit test file) | `[REQ-DAT-003.6]` |
| G51 | Run `sed -i 's/$/\r/' test/element_cache_guard_test.dart` (CRLF in the guard test file) | `[REQ-DAT-003.6]` |
| G52 | Run `sed -i 's/$/\r/' specs/req-dat-003.md` (CRLF in the spec file) | `[REQ-DAT-003.6]` |
| G53 | Run `sed -i 's/$/\r/' docs/adr/ADR-0001-baseline-packages.md` (CRLF in the ADR file) | `[REQ-DAT-003.6]` |
| G54 | Delete the file `test/data/element_cache_test.dart` | `[REQ-DAT-003.6]` |
| G55 | Delete the file `test/domain/celestrak_tle_snapshot.dart` | `[REQ-DAT-003.6]` |
| G56 | Delete the file `specs/req-dat-003.md` | `[REQ-DAT-003.6]` |
| G57 | Delete the note line from the ADR file | `[REQ-DAT-003.7]` |
| G58 | Replace every occurrence of `Settings ride in the same cached JSON` with `Settings ride elsewhere` in the ADR file | `[REQ-DAT-003.7]` |
| G59 | Delete the note line from the ADR file, then insert it, with two leading spaces, directly after the line `## Out of scope` | `[REQ-DAT-003.7]` |
| G60 | Delete the file `docs/adr/ADR-0001-baseline-packages.md` | `[REQ-DAT-003.7]` |

Inside the table, `\|` is a single pipe.

- In G2 to G8, G14, G21 and G33 to G37 a file may no longer compile or analyze cleanly. That does not affect the guard, which reads text and runs on its own.
- In G47 the guard test file still compiles: an unused import is a warning, not an error.
- G31 also removes the GP client file, and G32 removes every application library file, so the guards of req-dat-001 and req-dat-002 fail too; only the tag of this spec is read here.
- G55 also fails the guards of req-dat-001 and req-dat-002; only the tag of this spec is read here.
- G53 is expected to report `[REQ-DAT-003.6]`. The note line of REQ-DAT-003.7 still matches, because a trailing CR is a blank character.

No row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V2 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that implements this spec lists V0–V13, with the base hash of V10, U1–U5, M1–M18 with their diffs, G0 and G1–G60, each with its observed result. A pull request without this list is incomplete regardless of its check status. This checklist is the one manual step of this spec: a reviewer reads it, and no command verifies it.

## Edge Cases & Errors

These cases are normative where a requirement above tests them, and informative where marked.

- **First start, no cache.** The cache directory, or the cache file of an object, does not exist yet. A read reports no entry (REQ-DAT-003.3); req-dat-004 then has nothing to propagate for that object until its first fetch succeeds.
- **The cache deleted by hand or by the user.** Deleting a cache file or the whole cache directory, while the app runs or between runs, is read as no entry, and the next write creates the directory and the file again (REQ-DAT-003.3, Constitution principle 11).
- **An interrupted write.** The app is killed between the write of the temporary file and the rename. The cache file still holds the previous document, or does not exist; a read is unaffected. The temporary file may remain, and the next write of that object replaces it.
- **A power loss after the rename (informative).** The temporary file is flushed before the rename, but the directory entry is not, and some file systems may keep the rename without the data. The cache file is then empty or damaged: a read reports no entry, the previous document is lost, and the next successful write of that object repairs the file. The cache keeps no second copy against this.
- **A write that fails.** A full disk, a missing permission or a path occupied by a directory makes the write complete with `false`, and the cache file keeps its previous document (REQ-DAT-003.2). Whether to try again is req-dat-004's decision.
- **A success built by hand.** A success whose lines the core rejects, whose lines belong to another object, or whose name line is empty or padded, completes the write with `false` and writes nothing (REQ-DAT-003.2). The GP client never produces such a success; the check protects the cache from a caller that builds one.
- **A success with a local instant.** It is stored converted to UTC, with `Z` (REQ-DAT-003.1). The GP client always stamps in UTC; the conversion protects the document from a caller that does not.
- **A damaged or truncated file.** Any content that is not a valid stored document for its object is read as no entry and left unchanged (REQ-DAT-003.4). It is replaced at the next successful write of that object, and never deleted by the cache.
- **A file of another object.** A cache file that holds a document of another object, or a document whose `noradId` member or element lines belong to another object, fails the catalog-number rules and is read as no entry, so an element set is never filed under the wrong object (REQ-DAT-003.4).
- **A document from another version of the app.** A schema version other than the JSON integer `1` is read as no entry (REQ-DAT-003.4). A later spec that changes the document raises the version in a revision of this spec, and decides then whether to read version `1` too.
- **Extra members.** A member that this spec does not define is ignored on read (REQ-DAT-003.3). A write never adds one.
- **An arrival instant in local time.** A `fetchedAtUtc` without the final `Z`, or with a numeric offset, is read as no entry (REQ-DAT-003.4).
- **An arrival instant in the future (informative).** A device clock that was wrong at download time can store an instant after the current one. The cache stores and returns it unchanged; how such an age is shown is req-dat-004's decision.
- **Microseconds.** The arrival instant keeps its full precision across a write and a read (REQ-DAT-003.3).
- **A replaced object (informative).** When req-dat-001 replaces an object, for example a new GOES-East satellite, the new catalog number has a new cache file. The old file is never read again and is not deleted; removing it is out of scope.
- **Other files in the cache directory (informative).** The cache reads and writes only cache files and temporary files of tracked objects, and ignores every other file. In particular, a settings file of a later spec in the same directory is never touched (REQ-DAT-003.7).
- **Concurrent writes of the same object (informative).** Two writes of the same object at the same time share one temporary file, and the result is undefined. The cache keeps no lock; req-dat-004 must not start a second write of an object before the first completes. Writes of different objects are independent.
- **Windows file locks (informative).** On Windows, a rename onto a file that another process holds open, such as an antivirus or an indexer, can fail; the write then completes with `false`, as REQ-DAT-003.2 requires. A test that leaves a file open can also make the deletion of its temporary directory fail at teardown; the unit tests close every file they open before their test ends. Android, the target of the app, has no such locks.
- **An extra public method on the cache (informative).** The public-surface rule counts top-level declarations, so it catches a second cache, a public function or a public constant, but not a public method added inside the cache type. A method that deletes or lists files is still caught by REQ-DAT-003.5; any other extra method is out of scope, and the reviewer checks the cache type against the decision "Small public surface".
- **A programming error.** A Dart `Error`, such as a `StateError` or a `TypeError` from a bug in the cache, is not caught, so a bug is never reported as an empty cache (REQ-DAT-003.5).
- **The name line.** It is stored and returned as the GP client served it. The display name of the app comes from the catalog, never from this line (req-dat-002).
- **Network or CI failure while verifying.** No check of this spec uses CelesTrak or builds an APK. A failed `flutter pub get`, a timeout, a runner out of memory or a failed analysis is handled as req-inf-002 defines and never counts as a pass. A U, M or G row whose output shows a compilation or resolution error of the file it targets, instead of the expected tag, counts as not run, never as a pass.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Shell.** The commands need a POSIX shell with GNU `sed`. In PowerShell they fail with "command not found"; that is an environment error, never a pass. In Git Bash on Windows, set `MSYS_NO_PATHCONV=1` when scripting edits whose arguments start with `/`, and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in the implementation:

- Resolving the cache directory, any call of `path_provider`, and any choice between platform directories (req-dat-004, which uses the application support directory).
- Deciding when to write or read, any refresh threshold, retry, scheduling, data age or stale-data logic (req-dat-004, req-ui-004).
- Any operation that deletes, clears, lists or migrates cache files, including the removal of orphaned files of replaced objects and of leftover temporary files.
- Any lock or queue against concurrent writes of the same object, and any second copy of a document against a power loss.
- Reading schema versions other than `1`.
- Parsing the stored lines into the elements that a propagator uses, beyond the validation of a write and a read (req-dat-004, req-sta-001).
- Storing user settings, the user's location or anything other than the documents of this spec (Constitution principle 11; ADR-0001, note of REQ-DAT-003.7).
- Any compression, encryption, checksum of the file or size limit.
- Any domain repository interface, Riverpod provider, widget or screen, and any change to `lib/main.dart` (req-dat-004, req-sta-001, req-ui-*).
- Any change to `lib/data/celestrak_gp_client.dart`, `lib/domain/satellite_catalog.dart`, the snapshot data file or the tests and guards of req-dat-001 and req-dat-002.
- Any change to `packages/orbital_core`, its tests or its guards.
- Any change to either `pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yml`, `test/support/repo_root.dart`, `test/dependency_guard_test.dart`, any Android manifest or the constitution.
- Any change to an ADR in the implementation. The note of REQ-DAT-003.7 is added by the pull request of this spec, not by the implementation.
- A new ADR.
- Any read or write outside a temporary directory from a test, and any request to CelesTrak.
- Any change to `specs/req-dat-003.md` in the implementation, except a behaviour change approved by the developer (REQ-DAT-003.6, V10).
- Any change to `docs/roadmap.md`. Its checkbox for this row is updated by the spec workflow (QA validation), outside the implementation.

## Open Questions

None.
