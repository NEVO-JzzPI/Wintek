# req-dat-002 — CelesTrak GP client

- **Status:** Draft (revision 2), after the first QA audit, pending a second audit.
  - **Approved before drafting (2026-11-12):**
    - one dataset is one tracked object: one GP request per object, by catalog number, in TLE format;
    - on success the client returns the validated text of the element set (name line, line 1, line 2), not a parsed element set, so req-dat-003 can persist the last good payload as served;
    - one attempt per call, a 20-second timeout, no retry, no timer and no memory between calls; when to call belongs to req-dat-004;
    - the Android `INTERNET` permission is added to the main manifest in this spec;
    - failures are returned as values of a closed (sealed) set of five kinds, never thrown;
    - the client stamps each success with the UTC instant it arrived, read from an injectable wall clock;
    - the client sends a fixed `User-Agent`;
    - the tests rebuild CelesTrak responses from the snapshot of req-dat-001, through the mock client of the approved `http` package, and never use the network.
  - **Beyond roadmap row 14, approved as extensions:** the `INTERNET` permission (row 14 names no platform change), and the arrival instant, which row 15 (req-dat-003) describes as "its fetch timestamp" and which this spec now produces. req-dat-003 persists it and does not stamp again.
  - **Roadmap wording, proposed and pending the developer's approval:** row 14 says "OMM/TLE", but ADR-0003 decision 1 allows TLE only; row 15 says "with its fetch timestamp", which this spec now produces. This spec does not edit `docs/roadmap.md`.
  - **Approved for revision 2 (2026-11-12):** all findings of the first QA audit, as follows.
    - Fixed in requirements and tests: 1 (public surface rule), 4 (blank characters), 5 (exceptions, errors and timeouts), 6 and 7 (import and manifest rules), 14 (arrival instant equals the injected clock, read after the response), 15 (exact no-data body), 16 (leading blanks), 18 (CRLF in the working tree, V0), 19 (no real HTTP client in tests), 20 (wider network boundary), 22 (HTTP client ownership), 24 and 25 (public surface; an extra public method inside the client type stays a review item, see Edge Cases).
    - Fixed in the text: 2 (no "well within"), 8 (V10 order), 9 (data imports the core), 10 to 12 (extensions and roadmap wording above), 13 (no constraint on req-ui-005 in Blocks), 21 (importers of the client are out of scope).
    - Removed: V12 of revision 1 (findings 17 and 23). A release build proves nothing about the permission that the guard of REQ-DAT-002.5 does not already prove, and it needs an Android toolchain and network access to Gradle repositories.
    - Accepted as is: 3. The M rows stay hand-applied mutants, because killing them mechanically would fix class names in this spec.
- **Roadmap row:** 14 of 33 (MVP)
- **Blocks:**
  - req-dat-003: persists the payload and the arrival instant of a success;
  - req-dat-004: decides when to call the client, creates and owns its HTTP client, and maps its failures to the data age and the stale-data warning. Creating the HTTP client outside the client library file needs an amendment of REQ-DAT-002.4 in that spec.
- **Depends on:**
  - req-dat-001: `TrackedObject`, its `noradId`, the GP request of an object and the snapshot data file `test/domain/celestrak_tle_snapshot.dart`;
  - req-orb-003: `OrbitalElements.fromTle`, its `catalogNumber` and the `FormatException` it throws;
  - req-inf-001 and req-inf-002: both suites, the CI gates, the `lib/data` directory of the scaffold and `test/support/repo_root.dart`;
  - ADR-0001: `http` is an approved runtime dependency of the app;
  - ADR-0003, decision 1 and its first Consequence: TLE only, and "req-dat-002 downloads CelesTrak GP data in TLE format and removes the name line before handing the two element lines to the parser".
- **ADR:** none new. The client uses only packages that ADR-0001 approves and the format that ADR-0003 fixes.
- **No new dependency and no formula.** `package:http/testing.dart` is part of the approved `http` package, so neither manifest changes. The client adds no mathematics, so Constitution principle 6 is not triggered.

## Context & Objective

Roadmap row 14 asks to "fetch OMM/TLE data with one request per dataset and typed failures, the app's only network boundary". ADR-0003 decision 1 has since narrowed the format to TLE, and this spec follows the ADR: the client never requests or reads OMM.

Every later data spec needs fresh element sets, and every one of them must reach CelesTrak in the same polite way. This spec puts the whole network contact of the app in one data-layer file: it knows the URL, the headers and the timeout, it validates what CelesTrak returns with the parser of the core, and it turns every way a request can go wrong into one of five typed failures. Later specs then decide when to call it (req-dat-004) and where to keep what it returns (req-dat-003), without touching HTTP.

### Decisions approved before drafting

- **One dataset per object.** A dataset is the GP data of one tracked object. The client requests it with the GP request of req-dat-001, built from `TrackedObject.noradId`, never from a literal (req-dat-001, one source of truth). CelesTrak groups such as `stations` were rejected: they return many objects that the app would have to filter, and two of the four objects are only in large groups.
- **Validated text, not parsed elements.** A success carries the tracked object, the name line, line 1, line 2 and the arrival instant. Before the client calls it a success, the two element lines must be accepted by `OrbitalElements.fromTle` and carry the requested catalog number. So a payload that the core would reject never reaches the cache, and req-dat-003 stores exactly the text that CelesTrak served, minus line-end characters and trailing blanks.
- **Name line kept, not checked.** ADR-0003 asks the data layer to remove the name line before parsing; the client does so and returns the name separately. It does not compare the name with the CelesTrak name of req-dat-001, because CelesTrak may rename an object (req-dat-001, Edge Cases) and that must not stop the app from tracking it.
- **One attempt, no memory.** Each call sends exactly one request, waits at most 20 seconds and returns. The client never retries, never schedules itself and remembers nothing between calls. Constitution principle 10 ("at most one fetch per dataset every few hours, never polling") is enforced by the refresh policy of req-dat-004, which is the only caller.
- **Failures are values.** The result of a call is either a success or one of five failures: network, timeout, HTTP status, no GP data and malformed payload. The set is closed, so a caller that handles the result must handle every kind, and the call itself never throws for any of them. A programming error (a Dart `Error`, such as a `StateError`) is not a failure of the network and is not caught.
- **Arrival instant from a wall clock.** The client reads an injectable wall clock after the response has arrived and returns that instant in UTC. It is not the simulation clock of req-tim-001, which can be paused or reversed. Tests inject the clock.
- **Fixed User-Agent.** Every request carries the header `User-Agent: Wintek/1.0 (+https://github.com/NEVO-JzzPI/Wintek)`, so CelesTrak can identify the app and its source if it ever needs to.
- **Internet permission.** A release build of a Flutter app for Android has no `INTERNET` permission unless the main manifest declares it; only the debug and profile manifests of the scaffold do. The client is the first code that needs the network, so its spec adds the permission.

### Decisions that follow from the Constitution

- **Data layer.** The client is an implementation detail of the data layer (Constitution principle 5). It imports the catalog of the domain layer and the core, never Flutter, Riverpod or `dart:io`. Principle 5 restricts what `domain` may depend on; it does not forbid `data` from using `orbital_core`, and ADR-0003 assigns the parsing of the downloaded lines to this layer.
- **Small public surface.** The client library file declares exactly one public client type, which offers one fetch per tracked object and a readable timeout, and one sealed result type with one success and five failure types. Everything else in the file is private (REQ-DAT-002.4).
- **Injected HTTP client, owned by its creator.** The client receives its HTTP client and never creates or closes one. Whoever creates the HTTP client owns it and closes it; in the app that is req-dat-004. Tests inject the mock client of `package:http/testing.dart`, so the tests cannot reach the network.
- **The only network boundary.** No other application library file imports `package:http`, uses `HttpClient`, a socket or an address lookup, or names the CelesTrak host (REQ-DAT-002.4). A later spec that needs one of these in another library file amends this rule in a revision of this spec.
- **Stores nothing.** The client writes no file and keeps no state (Constitution principle 11). Persistence is req-dat-003.
- **Off the frame path.** The client is asynchronous and is never called from a painter or a per-frame provider (Constitution principle 13). Wiring it to providers is req-dat-004 and req-sta-001.
- **No network in tests.** Every unit test answers through the mock client (Constitution principle 10). No test of this spec, and no command of its checklist, sends a request to CelesTrak.

## Definitions used by every requirement

These definitions are normative.

- **Blank characters:** space (U+0020), tab (U+0009) and carriage return (U+000D). Wherever this spec removes leading or trailing spaces, or compares a line "with spaces removed", it removes blank characters.
- **Client library file:** `lib/data/celestrak_gp_client.dart`.
- **Client:** the one public type of the client library file that performs a fetch. Its name, and the names of the result types, are the implementer's choice, within the public-surface rule of REQ-DAT-002.4.
- **Fetch:** one call of the client for one tracked object. Its result is a future that completes with one success or one failure.
- **Application library files:** every file whose name ends in `.dart` under `lib`, searched recursively.
- **Unit test file:** `test/data/celestrak_gp_client_test.dart`, in the application suite. It covers REQ-DAT-002.1 to .3.
- **Guard test file:** `test/celestrak_gp_client_guard_test.dart`, in the application suite. It covers REQ-DAT-002.4 to .6.
- **Snapshot data file:** `test/domain/celestrak_tle_snapshot.dart`, from req-dat-001. This spec reads it and never changes it.
- **Snapshot entry k:** as defined by `specs/req-dat-001.md`: the name token, line 1 and line 2 of the tracked object at position k, from 1 to 4.
- **Manifest file:** `android/app/src/main/AndroidManifest.xml`.
- **Spec file:** `specs/req-dat-002.md`.
- **GP request of an object:** `https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE`, as defined by req-dat-001, where `<NORAD ID>` is the decimal `noradId` of the object, with no leading zeros.
- **User-Agent value:** `Wintek/1.0 (+https://github.com/NEVO-JzzPI/Wintek)`.
- **Default timeout:** 20 seconds.
- **Raw response of position k:** status 200 and a body made of three lines, each followed by CR LF:
  1. the name token of snapshot entry k, padded on the right with spaces to 24 characters;
  2. line 1 of snapshot entry k;
  3. line 2 of snapshot entry k.

  This is the shape in which CelesTrak served the snapshot (req-dat-001, Edge Cases: "The GP response pads the name line to 24 characters and uses CRLF").
- **LF response of position k:** status 200 and the three lines of snapshot entry k, unpadded, each followed by LF.
- **Bare response of position k:** status 200 and the three lines of snapshot entry k, unpadded, joined by LF, with no line break after the last one.
- **Body lines:** the body split at every LF, each piece with its trailing blank characters removed. Leading characters are never removed.
- **Non-empty body lines:** the body lines that are not empty, in order.
- **No-data body:** a body that, with leading and trailing blank characters and LF removed, is exactly `No GP data found`, and nothing else. This is the text that CelesTrak GP returns, with status 200, for a catalog number that has no current element set.
- **Valid payload for an object:** a status-200 body that is not a no-data body, has exactly three non-empty body lines, and whose second and third non-empty body lines, as line 1 and line 2, are accepted by `OrbitalElements.fromTle` with a `catalogNumber` equal to the `noradId` of the object.
- **Line match:** a line matches a string when, with leading and trailing blank characters removed, it is equal to the string character for character.
- **Code line:** a line whose text, with leading blank characters removed, does not start with `//`.
- **Import URI:** for a line whose text, with leading blank characters removed, starts with `import ` or `export `, the text between its first two single quotes.
- **Declaration line:** a line of the client library file whose first character is not a blank character and that does not start with `//`, `@`, `import `, `}` or `)`. With `dart format`, these are the first lines of the top-level declarations.
- **Public class declaration:** a declaration line that starts with `class `, `final class `, `base class ` or `sealed class `, where the next word, the class name, does not start with `_`.
- **Private declaration:** a declaration line whose head contains a word that starts with `_`. The head is the text before the earliest occurrence of any of `(`, ` =`, `;` or `{`; the whole line if none occurs.

## Functional Requirements

### REQ-DAT-002.1 — The request

Each fetch sends exactly one GET request for the GP data of one tracked object, with the fixed User-Agent, and gives up after the timeout.

**Acceptance (verified by the unit test file).** The tests inject a mock client that records every request it receives.

- For each of the four tracked objects, a fetch sends exactly one request:
  - its method is `GET`;
  - its URL, as a string, is exactly the GP request of the object;
  - its `User-Agent` header is exactly the User-Agent value.
- A fetch that ends in a success, a network failure, a timeout or a status failure (503) sends exactly one request each. So the client never retries.
- Two consecutive fetches of the same object send exactly two requests. So the client keeps no memory and no rate limit of its own.
- A client created without a timeout uses the default timeout, and makes its timeout readable so the test can check it equals 20 seconds.

### REQ-DAT-002.2 — Success

A valid payload becomes a success that carries the object, the three lines without line-end characters or padding, and the UTC instant it arrived.

**Acceptance (verified by the unit test file).** The tests inject a wall clock that returns a fixed UTC instant T0 until the mock client has received the request, and a later fixed UTC instant T1 from then on. For each position k from 1 to 4, and for each of the raw, LF and bare responses of position k, a fetch of the object at position k completes with a success whose:

- tracked object is the object at position k;
- name line is exactly the name token of snapshot entry k, with no trailing blank characters;
- line 1 and line 2 are exactly line 1 and line 2 of snapshot entry k, with no CR;
- arrival instant is in UTC and equal to T1. So the clock is read after the response arrived, not before the request.

In addition, when T1 is a local (non-UTC) instant, the arrival instant of the success is in UTC and denotes the same moment as T1.

### REQ-DAT-002.3 — Typed failures

Every other outcome becomes exactly one of the five failures, and the fetch completes normally instead of throwing; a programming error is not caught.

**Acceptance (verified by the unit test file).** Each case below is a fetch of ISS (position 1) unless it says otherwise. Except in the last case, each completes with a value, not an error, and that value is the failure named in the case. Each failure carries the tracked object that was requested.

- **Network.** The mock client throws a `ClientException` of `package:http`; in a second case it throws a plain `Exception`. Both are a network failure.
- **Timeout.** The client is created with a timeout of 50 milliseconds, and the mock client returns a response that never completes. In a second case, with the default timeout, the mock client throws a `TimeoutException` of `dart:async`. Both are a timeout failure.
- **HTTP status.** Status 403, 404, 500 and 503, each with the raw response body of position 1, and status 204 with an empty body. Each is a status failure that carries the status code it received. The body is not inspected.
- **No GP data.** Status 200 with the body `No GP data found`, and again with that body followed by CR LF. Both are a no-data failure.
- **Malformed payload.** Status 200 and each of these bodies is a malformed-payload failure:
  - an empty body;
  - the body `No GP data found for this object`;
  - line 1 and line 2 of snapshot entry 1 only, with no name line;
  - the raw response of position 1 followed by the raw response of position 2;
  - the raw response of position 1 with the last character of line 2 replaced by a different digit (bad checksum);
  - the raw response of position 1 with one space inserted before line 1 (a shifted line);
  - the body `<html><body>Service unavailable</body></html>`;
  - for each position k from 1 to 4, the raw response of the next position (position 1 after position 4) for a fetch of the object at position k: a valid element set with the wrong catalog number.
- **Programming error.** The mock client throws a `StateError`. The fetch completes with that error, not with a failure value.

### REQ-DAT-002.4 — Placement, public surface, network boundary and documented contract

The client lives in the data layer, exposes only the client and its result types, is the only network code of the app, never creates or closes an HTTP client, and documents its contract in fixed lines.

**Acceptance (verified by the guard test file):**

- **Placement.** The client library file exists.
- **Imports.** No line of the client library file, with leading blank characters removed, starts with `export` or `part`. Every line that, with leading blank characters removed, starts with `import ` has one of these import URIs:
  - `dart:async`;
  - `package:http/http.dart`;
  - `package:orbital_core/orbital_core.dart`;
  - `package:wintek/domain/satellite_catalog.dart`.

  The last three are each present. So the client imports neither Flutter, nor Riverpod, nor `dart:io`, nor `path_provider`, nor another library of `package:http`.
- **Public surface.**
  - Every declaration line is a public class declaration or a private declaration.
  - There are exactly eight public class declarations: the client, the sealed result, one success and five failures.
  - Exactly one of them starts with `sealed class `.

  So the file declares no public function, constant, variable, enum, typedef, extension or mixin, and no second client.
- **The only network boundary.**
  - No application library file other than the client library file contains any of the substrings `package:http/`, `HttpClient`, `Socket` or `InternetAddress`.
  - No application library file other than the client library file contains `celestrak.org`, compared without regard to letter case.
- **No timer.** The client library file contains neither the substring `Timer` nor the substring `periodic`.
- **HTTP client injected, never created or closed.** The client library file does not contain the substring `.close(`, and every occurrence of `Client(` in it is directly preceded by an ASCII letter. So it never constructs `Client()` of `package:http`, with or without a prefix, while the name of its own client type may end in `Client`.
- **User-Agent.** At least one code line of the client library file contains the User-Agent value between single quotes.
- **No catalog number.** The client library file contains none of the substrings `25544`, `48274`, `38011` or `60133` (req-dat-001, one source of truth; also checked by the guard of req-dat-001).
- **Doc lines.** The client library file contains a line that matches each of:
  - `/// The only network boundary of Wintek: one CelesTrak GP request per tracked object (specs/req-dat-002.md).`
  - `/// Request: GET https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, where <NORAD ID> is TrackedObject.noradId.`
  - `/// One attempt per call, 20-second timeout, no retry and no timer; when to call is decided by req-dat-004 (Constitution principle 10).`
  - `/// Success: the name line and both element lines, accepted by OrbitalElements.fromTle with the requested catalog number, and the UTC instant they arrived.`
  - `/// Failures are returned, never thrown: network, timeout, HTTP status, no GP data and malformed payload.`
  - `/// The HTTP client is injected and never closed here; whoever creates it owns it.`

### REQ-DAT-002.5 — Internet permission

A release build of the app may open network connections.

**Acceptance (verified by the guard test file).** In the manifest file, with leading blank characters removed:

- a line matches `<uses-permission android:name="android.permission.INTERNET"/>`;
- that line comes after the first line that starts with `<manifest` and before the first line that starts with `<application`;
- no line between the first line that starts with `<manifest` and that line contains `<!--`.

So the permission is a direct child of the manifest element and is not inside a comment, even if the opening tag of the manifest spans several lines.

### REQ-DAT-002.6 — Test hygiene

The new test files follow the hygiene rules of req-dat-001, and the unit test file cannot construct a real HTTP client.

**Acceptance (verified by the guard test file):**

- **Unit test imports.**
  - Every line of the unit test file that, with leading blank characters removed, starts with `import ` has one of these import URIs:
    - `dart:async`;
    - `package:flutter_test/flutter_test.dart`;
    - `package:http/http.dart`;
    - `package:http/testing.dart`;
    - `package:wintek/data/celestrak_gp_client.dart`;
    - `package:wintek/domain/satellite_catalog.dart`;
    - `../domain/celestrak_tle_snapshot.dart`.
  - `package:flutter_test/flutter_test.dart`, `package:http/testing.dart`, `package:wintek/data/celestrak_gp_client.dart` and `../domain/celestrak_tle_snapshot.dart` are each present.
  - No line of the unit test file, with leading blank characters removed, starts with `export`. The unit test file does not contain the substring `dart:io`.
- **No real HTTP client in tests.** A line of the unit test file whose import URI is `package:http/http.dart`, with leading and trailing blank characters removed, is `import 'package:http/http.dart' show ` followed by one or more of the names `ClientException`, `Request` and `Response`, separated by `, `, and then `;`. So the unit test file can name neither `Client` nor the top-level request functions of `package:http`, and its only HTTP client is the mock client of `package:http/testing.dart`.
- **Unit test citation.** The unit test file contains a line that matches `// Responses rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test sends a request to CelesTrak (Constitution principle 10).`
- **Tags.**
  - For each N from 1 to 3, the unit test file contains a line that matches `// REQ-DAT-002.N`. Let L be the next non-empty line after it, with leading blank characters removed. L starts with `group('REQ-DAT-002.N ` or `test('REQ-DAT-002.N `. Alternatively, L is equal to `group(` or `test(`, and the next line after L, with leading blank characters removed, starts with `'REQ-DAT-002.N `. Either way, every failing unit test names its requirement.
  - For each N from 4 to 6, the guard test file contains a line that matches `// REQ-DAT-002.N`. The next non-empty line after it, with leading blank characters removed, starts with `test(`.
  - The guard test file contains no line that matches `// REQ-DAT-002.1`, `// REQ-DAT-002.2` or `// REQ-DAT-002.3`. It builds those tags and name prefixes by interpolation, never as literals, so that V6 prints only its own tags.
- **Self-matching tokens.** The guard test file builds the tokens `Platform.script` and `skip:` by concatenation of shorter string literals, never as one literal, because it checks its own text for them.
- **No skipped tests.** Neither the unit test file nor the guard test file contains the substring `skip:`.
- **Bytes.** None of these files contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the client library file, the unit test file, the guard test file, the spec file and the manifest file.
- **Repository root.** The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- **Plain text only.** The guard test file reads files as plain text with the Dart core and `dart:io` libraries of the application suite. It uses no YAML, XML, Markdown or other external parser.
- **Missing files fail.** Each of the following produces a failing test when missing, never a skipped or passing one: the client library file, the `lib` directory, the unit test file, the snapshot data file, the manifest file and the spec file. A missing guard test file is caught by V2.
- **Failure messages.** Every failure message of the guard test file starts with `[REQ-DAT-002.N]`, where N is the requirement whose check failed, and carries `specs/req-dat-002.md` on the same line as that tag.

**Acceptance (verified by command V10).** Compared with `main`, the pull request that implements this spec changes exactly the four files of V10. The one allowed exception is the spec file: when the implementation needs a behaviour change, the pull request may also change `specs/req-dat-002.md`, with the developer's approval linked in its description (Constitution principle 2). V10 is a local check: CI does not run it, and the pull request checklist reports its result.

## Mathematical Validation / Testing

This spec adds no formula, so there is nothing to check against Vallado or Curtis, and Constitution principle 6 is not triggered. Its evidence is behaviour against fixed responses:

- every response that a test serves is rebuilt from the snapshot of req-dat-001, whose provenance that spec records, or is written in this spec;
- REQ-DAT-002.2 proves that the client returns exactly the lines of that snapshot;
- REQ-DAT-002.3 proves that each failure kind is reached, that none of them throws, and that a programming error is not hidden;
- no test and no command of this section sends a request to CelesTrak. The first live request is made by the app once req-dat-004 calls the client.

All commands in this section run from a POSIX shell with GNU `sed`: Git Bash on Windows, or a shell on Linux.

### Local checks (run on the feature branch before opening the pull request)

| # | Command (from repository root) | Expected | Proves |
| --- | --- | --- | --- |
| V0 | `git ls-files --eol android/app/src/main/AndroidManifest.xml specs/req-dat-002.md \| grep -c "w/lf"` | standard output `2` | Precondition of the new files: the working tree holds LF |
| V1 | `flutter test test/data/celestrak_gp_client_test.dart --reporter expanded` | exit 0 | REQ-DAT-002.1 – .3 |
| V2 | `flutter test test/celestrak_gp_client_guard_test.dart --reporter expanded` | exit 0 | REQ-DAT-002.4 – .6 |
| V3 | `flutter test` | exit 0 | All of the above; the guards of req-dat-001 and `test/dependency_guard_test.dart` still pass |
| V4 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V5 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V6 | `grep -ohE "// REQ-DAT-002\.[0-9]+" test/celestrak_gp_client_guard_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-002.4,// REQ-DAT-002.5,// REQ-DAT-002.6` | REQ-DAT-002.6 (tags of the guard test file) |
| V7 | `grep -ohE "// REQ-DAT-002\.[0-9]+" test/data/celestrak_gp_client_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-002.1,// REQ-DAT-002.2,// REQ-DAT-002.3` | REQ-DAT-002.6 (tags of the unit test file) |
| V8 | `dart pub get && dart analyze --fatal-infos && dart test`, inside `packages/orbital_core` | exit 0 | The core is untouched and still passes on its own (Constitution principle 3) |
| V9 | `{ grep -rlE "package:http/\|HttpClient\|Socket\|InternetAddress" lib; grep -rli "celestrak\.org" lib; } \| LC_ALL=C sort -u \| paste -sd, -` | standard output `lib/data/celestrak_gp_client.dart` | REQ-DAT-002.4 (the only network boundary) |
| V10 | `git fetch origin main && git diff --name-only origin/main...HEAD \| LC_ALL=C sort \| paste -sd, -` | standard output `android/app/src/main/AndroidManifest.xml,lib/data/celestrak_gp_client.dart,test/celestrak_gp_client_guard_test.dart,test/data/celestrak_gp_client_test.dart`; or, only when the pull request links the developer's approval of a spec diff, the same list with `specs/req-dat-002.md` inserted after `lib/data/celestrak_gp_client.dart` | REQ-DAT-002.6 (only the files of this spec change) |
| V11 | `grep -rlE "25544\|48274\|38011\|60133" lib packages/orbital_core/lib \| paste -sd, -` | standard output `lib/domain/satellite_catalog.dart` | req-dat-001 one source of truth still holds |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V3 to V5 and V8 on every pull request. `lib/data/.gitkeep` stays, so V10 lists no deletion. V9 uses `grep -rli` with an escaped dot rather than `grep -rliF`: on the developer's Git Bash, `grep` aborts when `-i` and `-F` are combined.

**Precondition of V10.** The implementation branch is created from `main` after the pull request of this spec was merged into `main` with a merge commit. If the branch was created before that merge, or the spec pull request was squashed, the spec file appears in the diff. V10 then counts as not run, never as a pass or a failure, and the fix is to rebase the implementation branch onto `main`.

**Precondition of the new files.** `.gitattributes` (`* text=auto eol=lf`) normalizes only what enters the repository and what a checkout writes after it existed. A Windows working tree checked out earlier, or with `core.autocrlf=true`, can still hold CRLF in a tracked file: on the developer's machine the manifest file showed `i/lf w/crlf` while this spec was revised. Before the first edit:

1. Run V0. If it prints less than `2`, rewrite each file that `git ls-files --eol` shows with `w/crlf` from the index, for example `rm android/app/src/main/AndroidManifest.xml && git checkout -- android/app/src/main/AndroidManifest.xml`, and run V0 again. The content in the index is unchanged, so this produces no diff.
2. Save the new files and the edited manifest as UTF-8 without BOM and with LF, and keep the editor from converting the manifest back to CRLF.

### Local negative checks

These run after every file of the implementation pull request is committed on the feature branch. Before the first row, `git status --porcelain` must print nothing; otherwise stop, because the edits and the revert below would destroy uncommitted work.

After each row, revert with:

    git checkout -- lib test android specs

After the last row, `git status --porcelain` must print nothing again. If it prints a line, a row left a file behind, and the rows count as not run until the tree is clean.

Every row runs `flutter test` with `--no-pub`, so no row resolves dependencies, needs the network or rewrites `pubspec.lock`.

**Unit test rows (U and M).** The command is:

    flutter test --no-pub --reporter expanded test/data/celestrak_gp_client_test.dart 2>&1 | grep -F "[E]" | grep -F "<tag>"

For each row, apply the edit, run the command and confirm that it prints at least one line: a failing test whose name carries the requirement ID.

- U rows are mechanical edits, defined as in `specs/req-orb-010.md` (Local negative checks). "The client file" is the client library file.
- M rows are mutants that depend on how the client is written, so the implementer applies each one by hand, as the smallest change to the client file that has the stated effect. The pull request description shows the diff of each M row next to its result, so a reviewer can judge that the mutant does what its row says.

| # | Edit | Tag expected |
| --- | --- | --- |
| U1 | Replace every occurrence of `CATNR` with `CATNRX` in the client file | `REQ-DAT-002.1` |
| U2 | Replace every occurrence of `FORMAT` with `FMT` in the client file | `REQ-DAT-002.1` |
| U3 | Replace every occurrence of `Wintek/1.0` with `Wintek/0.9` in the client file | `REQ-DAT-002.1` |
| U4 | Replace every occurrence of `No GP data found` with `No GP data` in the client file | `REQ-DAT-002.3` |
| M1 | Send the request a second time after a network failure | `REQ-DAT-002.1` |
| M2 | Make the default timeout 21 seconds | `REQ-DAT-002.1` |
| M3 | Return the success without removing the trailing spaces of the name line | `REQ-DAT-002.2` |
| M4 | Return the clock value as read, without converting it to UTC | `REQ-DAT-002.2` |
| M5 | Read the clock before sending the request | `REQ-DAT-002.2` |
| M6 | Remove the comparison of the parsed catalog number with the requested `noradId` | `REQ-DAT-002.3` |
| M7 | Treat any status from 200 to 299 as 200 | `REQ-DAT-002.3` |
| M8 | Let the network exception propagate instead of returning a network failure | `REQ-DAT-002.3` |
| M9 | Accept a body with three or more non-empty body lines, using the first three | `REQ-DAT-002.3` |
| M10 | Remove the leading blank characters of each body line | `REQ-DAT-002.3` |
| M11 | Treat a `TimeoutException` thrown by the HTTP client as a network failure | `REQ-DAT-002.3` |
| M12 | Catch every thrown object, including a Dart `Error`, as a network failure | `REQ-DAT-002.3` |
| M13 | Recognize the no-data body when it starts with `No GP data found`, instead of when it equals it | `REQ-DAT-002.3` |

**Guard rows (G).** The command is:

    flutter test --no-pub test/celestrak_gp_client_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-dat-002.md"

**Control run (G0).** With no edit applied, run the G command once for each tag `[REQ-DAT-002.4]`, `[REQ-DAT-002.5]` and `[REQ-DAT-002.6]`, and confirm that each prints nothing. A printed line means the output of a passing run already carries a tag and the spec path, so the rows below would prove nothing. Fix the guard test file before continuing. Then, for each G row, apply the edit, run the G command and confirm that it prints at least one line.

The edits are defined as in `specs/req-orb-010.md` (Local negative checks). "The client file", "the unit test file", "the guard test file", "the manifest file" and "the spec file" are the files of Definitions.

| # | Edit | Tag expected |
| --- | --- | --- |
| G1 | Delete the file `lib/data/celestrak_gp_client.dart` | `[REQ-DAT-002.4]` |
| G2 | Add `import 'package:flutter/foundation.dart';` as the first line of the client file | `[REQ-DAT-002.4]` |
| G3 | Add `import 'dart:io';` as the first line of the client file | `[REQ-DAT-002.4]` |
| G4 | Add `export 'package:http/http.dart';` as the first line of the client file | `[REQ-DAT-002.4]` |
| G5 | Add `import 'package:http/io_client.dart';` as the first line of the client file | `[REQ-DAT-002.4]` |
| G6 | Append the line `Future<void> fetchAll() async {}` to the client file | `[REQ-DAT-002.4]` |
| G7 | Append the line `class ExtraClient {}` to the client file | `[REQ-DAT-002.4]` |
| G8 | Append the line `const Duration defaultTimeout = Duration(seconds: 20);` to the client file | `[REQ-DAT-002.4]` |
| G9 | Append the line `// Timer` to the client file | `[REQ-DAT-002.4]` |
| G10 | Append the line `// Stream.periodic` to the client file | `[REQ-DAT-002.4]` |
| G11 | Append the line `// ISS is 25544.` to the client file | `[REQ-DAT-002.4]` |
| G12 | Append the line `// httpClient.close();` to the client file | `[REQ-DAT-002.4]` |
| G13 | Append the line `// final real = http.Client();` to the client file | `[REQ-DAT-002.4]` |
| G14 | Replace every occurrence of `'Wintek/1.0 (+https://github.com/NEVO-JzzPI/Wintek)'` with `'Wintek'` in the client file | `[REQ-DAT-002.4]` |
| G15 | Delete the line `/// The only network boundary of Wintek: one CelesTrak GP request per tracked object (specs/req-dat-002.md).` from the client file | `[REQ-DAT-002.4]` |
| G16 | Delete the line `/// Request: GET https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, where <NORAD ID> is TrackedObject.noradId.` from the client file | `[REQ-DAT-002.4]` |
| G17 | Delete the line `/// One attempt per call, 20-second timeout, no retry and no timer; when to call is decided by req-dat-004 (Constitution principle 10).` from the client file | `[REQ-DAT-002.4]` |
| G18 | Delete the line `/// Success: the name line and both element lines, accepted by OrbitalElements.fromTle with the requested catalog number, and the UTC instant they arrived.` from the client file | `[REQ-DAT-002.4]` |
| G19 | Delete the line `/// Failures are returned, never thrown: network, timeout, HTTP status, no GP data and malformed payload.` from the client file | `[REQ-DAT-002.4]` |
| G20 | Delete the line `/// The HTTP client is injected and never closed here; whoever creates it owns it.` from the client file | `[REQ-DAT-002.4]` |
| G21 | Add `import 'package:http/http.dart' as http;` as the first line of `lib/main.dart` | `[REQ-DAT-002.4]` |
| G22 | Append the line `// Data: https://celestrak.org` to `lib/main.dart` | `[REQ-DAT-002.4]` |
| G23 | Append the line `// Data: CelesTrak.org` to `lib/main.dart` | `[REQ-DAT-002.4]` |
| G24 | Append the line `// Socket` to `lib/main.dart` | `[REQ-DAT-002.4]` |
| G25 | Append the line `// InternetAddress` to `lib/main.dart` | `[REQ-DAT-002.4]` |
| G26 | Append the line `// HttpClient` to `lib/domain/satellite_catalog.dart` | `[REQ-DAT-002.4]` |
| G27 | Run `rm -rf lib/data` | `[REQ-DAT-002.4]` |
| G28 | Delete the line `<uses-permission android:name="android.permission.INTERNET"/>` from the manifest file | `[REQ-DAT-002.5]` |
| G29 | Insert the line `    <!--` directly before the line `<uses-permission android:name="android.permission.INTERNET"/>` in the manifest file | `[REQ-DAT-002.5]` |
| G30 | Delete the line `<uses-permission android:name="android.permission.INTERNET"/>` from the manifest file, then insert the line `    <uses-permission android:name="android.permission.INTERNET"/>` directly after the line `</application>` | `[REQ-DAT-002.5]` |
| G31 | Delete the file `android/app/src/main/AndroidManifest.xml` | `[REQ-DAT-002.6]` |
| G32 | Add `import 'dart:io';` as the first line of the unit test file | `[REQ-DAT-002.6]` |
| G33 | Add `import 'package:orbital_core/orbital_core.dart';` as the first line of the unit test file | `[REQ-DAT-002.6]` |
| G34 | Replace every occurrence of `import 'package:http/http.dart' show ` with `import 'package:http/http.dart' show get, ` in the unit test file | `[REQ-DAT-002.6]` |
| G35 | Delete the line `// Responses rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test sends a request to CelesTrak (Constitution principle 10).` from the unit test file | `[REQ-DAT-002.6]` |
| G36 | Replace the line `// REQ-DAT-002.2` with `// REQ-DAT-002.x` in the unit test file | `[REQ-DAT-002.6]` |
| G37 | Replace every occurrence of `'REQ-DAT-002.1 ` with `'Request ` in the unit test file | `[REQ-DAT-002.6]` |
| G38 | Append the line `// skip: true` to the unit test file | `[REQ-DAT-002.6]` |
| G39 | Replace the line `// REQ-DAT-002.4` with `// REQ-DAT-002.x` in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-DAT-002.6]` |
| G40 | Append the line `// REQ-DAT-002.1` to the guard test file | `[REQ-DAT-002.6]` |
| G41 | Append the line `// Platform.script` to the guard test file | `[REQ-DAT-002.6]` |
| G42 | Run `sed -i 's/$/\r/' lib/data/celestrak_gp_client.dart` (CRLF in the client file) | `[REQ-DAT-002.6]` |
| G43 | Run `printf '\xEF\xBB\xBF' \| cat - lib/data/celestrak_gp_client.dart > /tmp/g43 && mv /tmp/g43 lib/data/celestrak_gp_client.dart` (BOM in the client file) | `[REQ-DAT-002.6]` |
| G44 | Run `sed -i 's/$/\r/' test/data/celestrak_gp_client_test.dart` (CRLF in the unit test file) | `[REQ-DAT-002.6]` |
| G45 | Run `sed -i 's/$/\r/' test/celestrak_gp_client_guard_test.dart` (CRLF in the guard test file) | `[REQ-DAT-002.6]` |
| G46 | Run `sed -i 's/$/\r/' specs/req-dat-002.md` (CRLF in the spec file) | `[REQ-DAT-002.6]` |
| G47 | Run `sed -i 's/$/\r/' android/app/src/main/AndroidManifest.xml` (CRLF in the manifest file) | `[REQ-DAT-002.6]` |
| G48 | Delete the file `test/data/celestrak_gp_client_test.dart` | `[REQ-DAT-002.6]` |
| G49 | Delete the file `test/domain/celestrak_tle_snapshot.dart` | `[REQ-DAT-002.6]` |
| G50 | Delete the file `specs/req-dat-002.md` | `[REQ-DAT-002.6]` |

Inside the table, `\|` is a single pipe.

- In rows U1 to U4 the unit test file still compiles, because only string contents change.
- In G2 to G8, G21, G32 to G34 a file may no longer compile or analyze cleanly. That does not affect the guard, which reads text and runs on its own.
- G26 also fails the guard of req-dat-001; only the tag of this spec is read here.
- G34 assumes the unit test file imports `package:http/http.dart` with a `show` clause, which the network case of REQ-DAT-002.3 needs for `ClientException`. If it does not, G34 counts as not run.
- G47 is expected to report `[REQ-DAT-002.6]`. The permission line of REQ-DAT-002.5 still matches, because a trailing CR is a blank character.

No row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V2 fails without printing any tag; the import line check is kept as a second line of defence.

**Pull request checklist.** The description of the pull request that implements this spec lists V0–V11, U1–U4, M1–M13 with their diffs, G0 and G1–G50, each with its observed result. A pull request without this list is incomplete regardless of its check status. This checklist is the one manual step of this spec: a reviewer reads it, and no command verifies it.

## Edge Cases & Errors

These cases are normative where a requirement above tests them, and informative where marked.

- **No connection, DNS failure, refused connection, TLS failure.** The HTTP client throws an exception; the fetch returns a network failure. On Android the `http` package reports socket errors as `ClientException`, and a TLS failure is a `HandshakeException`, which is also an `Exception`.
- **A programming error.** A Dart `Error`, such as a `StateError` from a closed HTTP client, is not a network failure. It propagates, so a bug is never reported as an unreachable CelesTrak (REQ-DAT-002.3).
- **A slow or stalled CelesTrak.** After the timeout the fetch returns a timeout failure. A `TimeoutException` raised inside the HTTP client is a timeout failure too.
- **A timed-out request is not aborted (informative).** The client stops waiting, but the underlying request may still complete and CelesTrak may count it. Aborting it is out of scope; the refresh policy of req-dat-004 keeps such requests rare.
- **CelesTrak blocks the client.** CelesTrak answers excessive traffic with status 403. The fetch returns a status failure with code 403; the client does not retry, and req-dat-004 must not call again before its refresh threshold.
- **Any other status.** A redirect is followed by the `http` package before the client sees a status. Any final status other than 200 is a status failure carrying that code, whatever the body says.
- **Object decayed or unknown.** CelesTrak returns status 200 and `No GP data found`. The fetch returns a no-data failure, and the cached element set, if any, stays the only source (req-dat-004). Replacing the object is a revision of req-dat-001.
- **CelesTrak changes the wording of the no-data body.** The body then fails the valid-payload rule and becomes a malformed-payload failure. The app still never stores it; only the kind reported changes. Updating the text is a revision of this spec.
- **Name line missing or extra element sets.** A body with other than three non-empty body lines, such as a two-line (2LE) answer or several objects, is a malformed-payload failure.
- **Element lines that the core rejects.** A wrong length, a bad checksum or an out-of-range field makes `OrbitalElements.fromTle` throw a `FormatException`; the fetch returns a malformed-payload failure and never throws it.
- **Another object's element set.** A valid element set whose catalog number differs from the requested `noradId` is a malformed-payload failure, so a wrong answer can never be filed under the wrong object.
- **Padding, CRLF and a missing final line break.** All three shapes are accepted, and the success carries the lines without CR and without trailing blank characters (REQ-DAT-002.2).
- **Leading blanks.** A line is never stripped on the left. TLE columns are positional, so a shifted line fails the parser and the payload is malformed (REQ-DAT-002.3).
- **A name line CelesTrak renamed.** It is returned as served. The display name of the app comes from the catalog, never from this line.
- **Clock in local time.** The arrival instant is always converted to UTC (Constitution principle 12).
- **HTTP client lifetime (informative).** The client never closes its HTTP client. req-dat-004 creates one HTTP client, keeps it for as long as it keeps the GP client, and closes it when it disposes of them. Creating it outside the client library file needs an amendment of REQ-DAT-002.4 in req-dat-004.
- **An extra public method on the client (informative).** The public-surface rule counts top-level declarations, so it catches a second client, a public function or a public constant, but not a public method added inside the client type, such as a fetch of all objects. That method is out of scope, and the reviewer checks the client type against the decision "Small public surface".
- **Concurrent fetches (informative).** The client keeps no state, so concurrent fetches of different objects are independent. Whether the app makes them is req-dat-004's decision.
- **The User-Agent version.** `Wintek/1.0` is fixed by this spec and does not follow the version in `pubspec.yaml`. Changing it is a revision of this spec.
- **A later library file that names the CelesTrak host.** A library file may write the name `CelesTrak` freely, but one that contains `celestrak.org`, in any letter case, breaks REQ-DAT-002.4. A spec that needs the URL in another library file, such as an attribution screen, amends that rule in a revision of this spec.
- **CRLF or BOM in a new, edited or checked-out file.** Rejected by REQ-DAT-002.6. The fix is to rewrite the file as UTF-8 without BOM and with LF, as the precondition of the new files describes, never to relax the test.
- **Network or CI failure while verifying.** No check of this spec uses CelesTrak or builds an APK. A failed `flutter pub get`, a timeout, a runner out of memory or a failed analysis is handled as req-inf-002 defines and never counts as a pass. V10 needs `git fetch`; if it fails, or its precondition does not hold, V10 counts as not run. A U, M or G row whose output shows a compilation or resolution error of the file it targets, instead of the expected tag, counts as not run, never as a pass.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Shell.** The commands need a POSIX shell with GNU `sed`. In PowerShell they fail with "command not found"; that is an environment error, never a pass. In Git Bash on Windows, set `MSYS_NO_PATHCONV=1` when scripting edits whose arguments start with `/`, and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in the implementation pull request:

- OMM, JSON or XML GP data, CelesTrak groups, SATCAT requests, supplemental GP data, or any data source other than the GP request of req-dat-001 (ADR-0003, Constitution principle 1).
- Any cache, file, `path_provider` call or persisted timestamp (req-dat-003).
- Any refresh threshold, rate limit, retry, backoff, scheduling, connectivity check or data-age logic (req-dat-004).
- Creating, holding or closing the production HTTP client (req-dat-004).
- Aborting a request after its timeout.
- Any rule on which library files may import the client library file. req-dat-004 introduces the domain interface that the rest of the app reads, and with it the rule that keeps `presentation` away from the client (Constitution principle 4).
- Any domain repository interface, Riverpod provider, widget or screen, and any change to `lib/main.dart` (req-dat-004, req-sta-001, req-ui-*).
- Fetching all four objects in one call, and any policy for partial failure across objects (req-dat-004).
- Parsing the payload into the elements that a propagator uses, beyond the validation of REQ-DAT-002.2 (req-dat-004, req-sta-001).
- Any lookup from a catalog number to a tracked object; the client always knows the object it asked for.
- Any release build check (req-rel-001).
- Any change to `lib/domain/satellite_catalog.dart`, the snapshot data file or the tests and guards of req-dat-001.
- Any change to `packages/orbital_core`, its tests or its guards.
- Any change to either `pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yml`, `test/support/repo_root.dart`, `test/dependency_guard_test.dart`, the debug or profile manifests, any ADR or the constitution.
- A new ADR.
- Any live request to CelesTrak from a test or from the checklist.
- Any change to `specs/req-dat-002.md` in the implementation pull request, except a behaviour change approved by the developer (REQ-DAT-002.6, V10).
- Any change to `docs/roadmap.md` in the implementation pull request, including the wording proposed in Status. Its checkbox for this row is updated by the spec workflow (QA validation), outside this pull request.

## Open Questions

None.
