# req-dat-004 — Element repository and refresh policy

- **Status:** Draft (revision 3), after the second QA audit, pending a third audit. The first audit was made by a session that did not draft revision 1, and the second by a session that did not draft revision 2. Revision 3 was drafted by the session that made the second audit, so the third should be made by a session that did not draft revision 3.
  - **Approved before drafting (2026-11-15):**
    - the refresh threshold is 6 hours, measured from the arrival instant that the GP client stamped and the cache stored; an element set exactly 6 hours old is due;
    - every attempt, successful or failed, opens a window of 6 hours for its object, kept in memory only; within that window no request is sent for that object, and a new start of the app begins with no window (Constitution principles 10 and 11);
    - this spec delivers the domain contract, its implementation in the data layer and an opener that resolves the application support directory of `path_provider` and creates and closes the production HTTP client; no Riverpod provider, no widget and no change to `lib/main.dart`;
    - the age limit of stale data and the stale-data warning belong to req-ui-004; this spec exposes the arrival instant and the data age only;
    - REQ-DAT-002.4 is amended so that exactly one more application library file, the factory library file of this spec, may import `package:http/http.dart` to create and close the production HTTP client; the client library file stays the only file that names the CelesTrak host or uses `HttpClient`, a socket or an address lookup;
    - an arrival instant later than the current wall-clock instant counts as due, and the data age is never negative;
    - due objects are requested one at a time, in catalog order;
    - the contract exposes, per tracked object, its element set, its arrival instant and its data age at a given instant; a refresh reports one outcome per object: refreshed, not due or failed; no failure is kept for display and no name line is exposed.
  - **Proposed by the drafting session and approved by the developer before drafting (2026-11-15):**
    - a lookup never reaches the network: it serves the element set kept in memory, or else the one the cache holds, so a cold start needs no network;
    - a success whose cache write fails is still served from memory, with its own arrival instant;
    - a refresh asked for while another refresh runs joins it and completes with its outcomes, so no object is ever fetched or written twice at once (req-dat-003, edge case "Concurrent writes of the same object");
    - the layer rules that req-dat-001 and req-dat-002 left to this spec: every domain library file imports only the core and the domain layer, and no presentation library file imports the data layer, `package:http`, `path_provider` or `dart:io`;
    - doc lines fixed word for word, checked by the guard, as in the earlier specs of the data layer.
  - **Approved for revision 2 (2026-11-16):** all findings of the first QA audit, as follows.
    - Fixed in requirements and tests: 1.1 (the application support directory on a code line, and no temporary or current directory in the factory; G89 to G92), 1.2 (the domain library file names no failure, status code or name line; G93 to G96), 2.1 (the case "The window of a failure" expects the other three objects to be requested again at N0 + H), 2.3 (no presentation library file imports `dart:convert`; G100), 3.2 (no application library file outside `lib/data`, other than `lib/main.dart`, imports the data layer; G98 and G99), 5.1 (a lookup never replaces an element set already in memory; a doc line and G97), 5.2 (the case "A timeout is failed" and M36).
    - Fixed in the text: 1.3 and 1.4 (letting the event loop run and held answers are defined), 1.5 (the count of `Client(` and `Client.new` is one in total), 2.2 (the decision "The only source is CelesTrak"), 3.1 (the handle is listed beyond roadmap row 16), 5.3 (the declaration line of the repository fits on one line).
    - Left to the reviewer, as stated in the text: 1.6 (the GP client guard test file changes only its network-boundary check) and the race of 5.1, which no test can produce deterministically.
    - No change needed: 4.1, 5.4 and 6.1.
  - **Approved for revision 3 (2026-11-16):** all findings of the second QA audit, as follows.
    - Decided by the developer: 4 and 5 (ADR-0007 is proposed with this revision and records how Constitution principle 10 reads across runs of the app; REQ-DAT-004.9 requires it to be accepted; G139, G144 and G146); 7 (the domain layer may import `dart:` libraries other than `dart:ffi`, `dart:html`, `dart:io`, `dart:isolate` and `dart:ui`, the presentation layer may use relative imports with no `..` segment, and the rule "Outside the data layer" keeps its scope with its rationale written out); 11 (the data age is unknown, `null`, when the arrival instant is later than the instant asked for, and req-ui-004 treats an unknown data age as stale); 14 (req-sta-001 opens exactly one handle per run, as Blocks states, and the edge case "The handle opened twice" records why).
    - Fixed in requirements and tests: 2 (no tag of REQ-DAT-004.1 to .6 in the guard test file, in any form; G142), 3 (every map of outcomes is unmodifiable, and a joined refresh completes with a map equal to that of the earlier one; M38), 6 (the Blocks entry of req-dat-004 in `specs/req-dat-002.md` no longer says that this spec maps failures to the data age and the warning; REQ-DAT-004.9, G145 and G147), 8 (G101 to G113), 9 (G114 to G138, G140, G141 and G143, M39, and G43 to G45 name the functions without parentheses), 7 (P1 to P3 prove that the guard accepts what the relaxed rules allow), 10 (the substring `delayed` replaces `Future.delayed` in every "nothing scheduled" rule; G112, G116 and G121), 12 (the case "In catalog order, one at a time" starts with every element set in memory, so its requests wait on no file), 13 (V1 and M40 also run at a non-zero UTC offset, recorded in the checklist); and, for 11, M37 and the case of the last microsecond before the arrival instant.
    - Fixed in the text: 15 (the edge case "The spec merged without its implementation").
    - Left to the reviewer, as stated in the text: 1 (the diff of the GP client guard test file, the race of a lookup and a refresh, and extra public members of the contract, the repository or the handle; no text rule can see a member without parsing Dart).
  - **Beyond roadmap row 16:** the amendment of REQ-DAT-002.4 (REQ-DAT-004.9), which req-dat-002 assigned to this spec ("Creating the HTTP client outside the client library file needs an amendment of REQ-DAT-002.4 in that spec"); the handle that creates the production HTTP client and closes it once, which req-dat-002 also assigned to this spec ("whoever creates it owns it"); the layer rules of REQ-DAT-004.8, which req-dat-001 and req-dat-002 assigned to this spec; the correction of the Blocks entry of req-dat-004 in `specs/req-dat-002.md`; and ADR-0007, which the Constitution requires for the reading of principle 10 that the attempt window makes. Otherwise nothing.
- **Roadmap row:** 16 of 33 (MVP)
- **Blocks:**
  - req-sta-001: opens the repository through the opener in `lib/main.dart`, the only application library file outside `lib/data` that may import the data layer (REQ-DAT-004.8), opens exactly one handle per run of the app and never a second while one is open, keeps it for the lifetime of the app, closes it, decides when to ask for a refresh (for example at start and when the app returns to the foreground) and joins the served element sets with the simulation clock;
  - req-ui-003: shows the data age of the selected object, read from state that req-sta-001 derives from this contract, and shows an unknown data age as unknown, never as zero;
  - req-ui-004: fixes the age limit of stale data and shows the warning, from the arrival instant and the data age of this contract, and treats an unknown data age as stale.
- **Depends on:**
  - req-dat-001: `TrackedObject`, its values in catalog order, its `noradId` and the snapshot data file `test/domain/celestrak_tle_snapshot.dart`;
  - req-dat-002: the GP client, its success and five failure types, its injectable wall clock and its rule that whoever creates the HTTP client owns it; and REQ-DAT-002.4 and its Blocks entry of req-dat-004, which this spec amends (REQ-DAT-004.9);
  - req-dat-003: the cache, its write that completes with `true` or `false`, its read that completes with an entry or `null`, and the arrival instant that it stores unchanged; the cache directory that the cache receives and creates at its first write;
  - req-orb-003: `OrbitalElements.fromTle`, its `catalogNumber` and its equality;
  - req-inf-001 and req-inf-002: both suites, the CI gates, the `lib/domain`, `lib/data` and `lib/presentation` directories of the scaffold and `test/support/repo_root.dart`;
  - ADR-0001: `path_provider` is approved to resolve the directory of the cached JSON, and `http` for the one HTTP client of the app.
- **ADR:** ADR-0007 (`docs/adr/ADR-0007-principle-10-across-runs.md`), proposed with revision 3 and accepted by the developer before this spec merges into `main`. It records how Constitution principle 10 reads across runs of the app: the limit holds per run, a cached success bounds every later run, and memory may serve a response of the current run whose write failed. The text of the Constitution is unchanged, and every package used is approved by ADR-0001.
- **No new dependency and no formula.** Neither manifest changes. The data age is the difference of two UTC instants, not orbital mathematics, so Constitution principle 6 is not triggered.

## Context & Objective

Roadmap row 16 asks to "resolve the cache directory as the application support directory of `path_provider` and implement the domain interface that serves the cache, refreshes only past the age threshold and exposes data age — what makes offline a feature instead of an error".

req-dat-002 fetches one element set and returns a value; req-dat-003 keeps the last good one on disk. Neither decides anything: both say that when to fetch, when to write, how old is too old and who owns the HTTP client belong to this spec. Without it, the app has a network boundary and a cache but no policy, so it can neither honour Constitution principle 10 ("at most one fetch per dataset every few hours, never polling") nor principle 9 ("with cached elements and no network the app still propagates and draws, and the age of the data is always visible").

This spec adds the one domain contract through which the rest of the app reads orbital elements, its implementation in the data layer, and the opener that wires the implementation to the platform. With it, a cold start without network serves the cached element sets at once, a refresh asks CelesTrak only for what is due, a failure is an outcome and never an empty screen, and every element set carries the instant it arrived, from which its data age follows.

The repository is deliberately passive. It sends a request only when it is asked for a refresh, it never schedules one, and it remembers its attempts only while the app runs. Who asks, and when, is req-sta-001.

### Decisions approved before drafting

- **A 6-hour threshold.** An element set is due when its arrival instant is 6 hours old or older. The Project Brief asks for "at most one download every few hours", and req-dat-002 for at most one request per dataset in that time. Six hours keeps the app well inside that rule and still refreshes a low orbit several times a day.
- **The data age is the age of the download.** req-dat-003 fixes that the stored arrival instant is the one the GP client read after the response arrived ("the data age of Constitution principle 9 is the age of the download"). This spec measures both the threshold and the data age from it. The epoch of the element lines is not the data age; showing it is out of scope.
- **An attempt window, in memory only.** Every attempt to fetch an object, successful or failed, opens a window of 6 hours for that object. A refresh within the window sends no request for it. So a failure, including a status 403 with which CelesTrak answers excessive traffic, is never repeated within the threshold (req-dat-002, edge case "CelesTrak blocks the client"). The window lives in memory: Constitution principle 11 allows only CelesTrak payloads and settings on disk, and an attempt is neither. A new start of the app begins with no window, so it may send one request per due object; a start is the user's act, never polling. ADR-0007 records this reading of principle 10: the limit holds per run, and a cached success bounds every later run.
- **A future arrival instant is due.** A device clock that was wrong at download time can store an arrival instant later than the current one (req-dat-003, edge case "An arrival instant in the future"). Such an instant cannot be trusted, so the element set counts as due, and the data age at an earlier instant is unknown (`null`), never zero or negative. Zero would show data of unknown age as the freshest there is, and the stale-data warning of req-ui-004 would never fire while the device clock stays behind; req-ui-004 treats an unknown data age as stale.
- **One request at a time, in catalog order.** A refresh asks for the due objects one after the other, in the order of `TrackedObject`, and starts the next fetch only when the previous one has completed. A cold start is slower than with four parallel requests, but CelesTrak never sees more than one request from the app at once.
- **A small contract.** The domain contract offers two operations: a lookup of the served element set of one tracked object, and a refresh of every due object. A served element set carries the tracked object, its `OrbitalElements`, its arrival instant in UTC, and its data age at a given instant, which is unknown when the arrival instant is later. A refresh completes with one outcome per tracked object: refreshed, not due or failed, in a map that no caller can change. The contract keeps no failure for display and exposes no name line; the display name of an object comes from the catalog (req-dat-002, edge case "The name line").
- **An opener, not a provider.** The factory library file opens the repository: it resolves the application support directory with `path_provider`, creates the production HTTP client, and builds the GP client, the cache and the repository on them. It is the only place that knows the platform and the HTTP package, so the repository and the contract never do. Providers, the moment of the first refresh and `lib/main.dart` belong to req-sta-001.
- **The application support directory, as is.** The cache directory is the application support directory itself, not a directory inside it, as req-dat-003 states in its Blocks ("creates the cache with the application support directory"). Unlike the application cache directory, the operating system does not empty it when space runs low. A settings file of a later spec goes in the same directory (ADR-0001, note of req-dat-003).
- **One amendment of req-dat-002.** REQ-DAT-002.4 made the client library file the only one that may contain `package:http/`. req-dat-002 left the creation of the production HTTP client to this spec and required this spec to amend that rule. The amendment lets exactly one more file, the factory library file, import `package:http/http.dart`; every other part of the network boundary is unchanged (REQ-DAT-004.9).

### Decisions proposed by the drafting session and approved

- **A lookup never reaches the network.** A lookup serves the element set kept in memory for its object, or else reads the cache; it never calls the GP client. A cold start therefore serves the cached element sets at once, and no screen waits for CelesTrak.
- **Memory first, the cache as the store.** Once an element set is served, from the cache or from a success, the repository keeps it in memory and serves it from there. Deleting the cache while the app runs does not take it away, and the next success writes the cache again (Constitution principle 11).
- **A success is served even if its write fails.** Every success of the GP client is written to the cache. If the write completes with `false`, the success is still served from memory with its own arrival instant, and the outcome is still refreshed. The cache catches up at the next success; after a restart, the cached set is older, and it is due again.
- **A refresh asked for during a refresh joins it.** A refresh that is asked for while another is still running completes with the outcomes of the running one and sends no request of its own. So the repository never fetches, and never writes, the same object twice at once, as req-dat-003 requires of its caller. Every map of outcomes is unmodifiable, so two callers that share the outcomes of one refresh cannot change what the other reads.
- **No catch in the repository.** The GP client and the cache already turn every failure of the network, the file system and the payload into a value. The repository therefore handles no exception at all, so a programming error is never reported as an outcome.

### Decisions that follow from the Constitution

- **The only source is CelesTrak.** Principle 10 is read as ADR-0007 decision 3 records: every element set served comes from a CelesTrak response, and the cache is the only thing that survives a restart. Memory holds only CelesTrak responses already received, so serving a success whose write failed, or one whose cache file was deleted, adds no source; the cache catches up at the next success.
- **Dependencies point inward.** The domain library file imports only the core and the catalog (principle 5). Other domain library files may also import the libraries of the Dart SDK that do no I/O and need no platform, so every `dart:` library except `dart:ffi`, `dart:html`, `dart:io`, `dart:isolate` and `dart:ui`; principle 5 limits the packages that the domain depends on, not `dart:math` or `dart:collection`. The repository library file imports the domain, the GP client, the cache and the core, never Flutter, Riverpod, `dart:io`, `path_provider` or `package:http`. Only the factory library file imports `path_provider` and `package:http/http.dart`.
- **Only the composition root reaches the data layer.** No application library file outside `lib/data` imports the data layer, except `lib/main.dart`, the composition root, so a later directory such as `lib/state` cannot reach it either. The rule keeps HTTP and file I/O out of every provider (principle 4), makes every later layer depend on the contract and not on its implementation (principle 5), and lets the tests of req-sta-001 replace the repository with a fake that needs no directory and no HTTP client. The cost for req-sta-001 is that `lib/main.dart` opens the handle and hands the contract to the providers.
- **The UI only renders.** No presentation library file imports the data layer, `package:http`, `path_provider`, `dart:io` or `dart:convert` (principle 4: no HTTP and no JSON parsing). A presentation library file may import another one by a relative URI with no `..` segment, which cannot leave `lib/presentation`; any other import is a `package:` or `dart:` URI. The rule is checked now, while `lib/presentation` is still empty, so that the first widget already meets it.
- **Never polling.** Nothing in the repository, the opener or the contract starts a timer, a periodic stream or a delayed future (principle 10), in any form: the guard forbids the substring `delayed`, so `Future<void>.delayed` and a tear-off of `Future.delayed` are caught like `Future.delayed`. A refresh happens only when it is asked for.
- **Off the frame path.** A lookup and a refresh are asynchronous; the contract is never called from a painter (principle 13). The data age is computed from values already in memory, for an instant that the caller passes, so no clock is read on the frame path.
- **Offline is a feature.** With a cached element set and no network, a lookup serves the cached set, a refresh completes with failed for that object, and the arrival instant stays visible through the data age (principle 9).

## Definitions used by every requirement

These definitions are normative. Blank characters, application library files, line match, code line, import URI, declaration line, word, head, declared name, private declaration, class modifiers and directives, and snapshot entry k are taken from `specs/req-dat-003.md`, so that this spec does not change meaning when that one is revised. Two of them differ from their source: a declaration line is a line of any of the three library files of this spec, not only of the cache library file, and "class modifiers and directives" counts `abstract interface class` and `enum` as public type declarations, because the domain library file declares one of each. Public type declaration is defined here.

- **Blank characters:** space (U+0020), tab (U+0009) and carriage return (U+000D).
- **Application library files:** every file whose name ends in `.dart` under `lib`, searched recursively.
- **Domain library files:** every file whose name ends in `.dart` under `lib/domain`, searched recursively.
- **Presentation library files:** every file whose name ends in `.dart` under `lib/presentation`, searched recursively.
- **Library files outside the data layer:** every application library file that is not under `lib/data` and is not `lib/main.dart`.
- **Line match:** a line matches a string when, with leading and trailing blank characters removed, it is equal to the string character for character.
- **Code line:** a line whose text, with leading blank characters removed, does not start with `//`.
- **Import URI:** for a line whose text, with leading blank characters removed, starts with `import ` or `export `, the text between its first two single quotes.
- **Inner relative URI:** an import URI that contains no `:`, does not start with `/`, and has no segment equal to `..`, where the segments are the parts of the URI between `/` characters. From a presentation library file, it can only name a file under `lib/presentation`.
- **Forbidden SDK library:** the import URIs `dart:ffi`, `dart:html`, `dart:io`, `dart:isolate` and `dart:ui`.
- **Declaration line:** a line of a library file of this spec whose first character is not a blank character and that does not start with `//`, `@`, `import `, `}`, `)` or `]`.
- **Word:** a maximal run of characters none of which is a blank character.
- **Head:** of a declaration line, the text before the earliest occurrence of any of `(`, ` =`, `;` or `{`; the whole line if none occurs.
- **Declared name:** of a declaration line, the word that follows the first word of its head that is equal to `class`, `enum`, `mixin`, `extension` or `typedef`, when its head has such a word; otherwise the last word of its head.
- **Private declaration:** a declaration line whose declared name starts with `_`.
- **Public type declaration:** a declaration line that starts with `class `, `final class `, `base class `, `sealed class `, `abstract interface class ` or `enum `, and whose declared name does not start with `_`. Any other modifier, such as `abstract class` or `interface class`, and a `library` directive make a declaration line that is neither a public type declaration nor a private declaration, so it fails REQ-DAT-004.7.
- **Snapshot entry k:** as defined by `specs/req-dat-001.md`: the name token, line 1 and line 2 of the tracked object at position k, from 1 to 4.
- **Position k:** the position of a tracked object in the values of `TrackedObject`, from 1 (ISS) to 4 (GOES-East). Catalog order is the order of the positions.
- **Domain library file:** `lib/domain/element_repository.dart`.
- **Repository library file:** `lib/data/celestrak_element_repository.dart`.
- **Factory library file:** `lib/data/element_repository_factory.dart`.
- **Library files of this spec:** the domain library file, the repository library file and the factory library file.
- **Contract:** the one public type declaration of the domain library file that starts with `abstract interface class `. It offers a lookup and a refresh.
- **Served element set:** a value of the one public type declaration of the domain library file that starts with `final class `. It carries a tracked object, an `OrbitalElements` built by `OrbitalElements.fromTle` from the element lines of a success or of a cache entry of that object, an arrival instant in UTC, and an operation that gives its data age at an instant.
- **Outcome:** a value of the one public type declaration of the domain library file that starts with `enum `. It has exactly three values: refreshed, not due and failed.
- **Repository:** the one public type declaration of the repository library file. It implements the contract, and is created with a GP client, a cache and an optional wall clock that defaults to the system clock.
- **Handle:** the one public type declaration of the factory library file. A handle is obtained only from its asynchronous open operation, exposes the repository typed as the contract, and offers a close operation.
- **Open operation:** a static, asynchronous operation of the handle. It takes an optional directory resolver, an optional HTTP client creator and an optional wall clock, and completes with a handle.
- **Directory resolver:** a function that completes with a directory. Its default is `getApplicationSupportDirectory` of `path_provider`.
- **HTTP client creator:** a function that returns a new HTTP client of `package:http/http.dart`. Its default creates the production client of that package.
- **Wall clock:** a function that returns the current instant. The open operation passes the same wall clock to the GP client and to the repository; when none is given, each uses its own default, the system clock.
- **The names** of the contract, the served element set, the outcome, the repository, the handle and of all their members are the implementer's choice, within the public-surface rules of REQ-DAT-004.7. Those rules need the declaration line of the repository, with ` implements ` and the name of the contract, to fit on one line after `dart format`, so the two names together must be short enough for that.
- **GP client, success, failure, cache, entry, cache file of an object, write and read:** as defined by `specs/req-dat-002.md` and `specs/req-dat-003.md`.
- **Arrival instant:** of a success, the instant that the GP client stamped; of an entry, the instant that the cache read back; of a served element set, the arrival instant of the success or entry it was built from, in UTC.
- **Refresh threshold:** 6 hours.
- **Due:** a tracked object is due at instant N when no attempt window of it is open at N and one of these holds:
  - it has no served element set in memory, and the cache holds no entry of it;
  - N minus the arrival instant of its served element set is 6 hours or more;
  - the arrival instant of its served element set is later than N.
- **Attempt:** one fetch of the GP client for one object, made by a refresh. An attempt starts at the instant the repository reads from its wall clock when it decides that the object is due.
- **Attempt window:** the window of an attempt started at A is open at instant N when A ≤ N and N < A + 6 hours.
- **Lookup:** one call of the contract for one tracked object. It completes with the served element set of that object kept in memory, or else with a served element set built from the entry that the cache reads for it, or else with `null`. It never calls the GP client. When its cache read completes, the repository keeps the served element set built from that entry in memory only if memory still holds no served element set of that object; otherwise the lookup completes with the one in memory. So a lookup never replaces an element set that a refresh kept while the read was running.
- **Refresh:** one call of the contract with no argument. It completes with an unmodifiable map whose keys are exactly the four tracked objects and whose values are their outcomes; adding, changing or removing an entry throws `UnsupportedError`. For each tracked object, in catalog order, it finds the served element set as a lookup does, reads the wall clock once, and:
  - when the object is not due, records not due and sends no request;
  - when the object is due, starts an attempt, awaits the fetch of the GP client, and then:
    - on a success, writes it to the cache, awaits that write, keeps a served element set built from the success in memory whatever the write completed with, and records refreshed;
    - on a failure, keeps the served element set as it was, and records failed.
- **Joined refresh:** a refresh asked for while an earlier refresh of the same repository has not completed. It sends no request and completes with a map equal to the map of the earlier refresh, entry for entry.
- **Data age at instant N:** of a served element set, N minus its arrival instant when that difference is not negative, and unknown, `null`, otherwise. It is computed from the moments that the instants denote, so a local instant N gives the same age as the UTC instant of the same moment. It is never negative and never zero for an instant before the arrival instant.
- **Repository unit test file:** `test/data/celestrak_element_repository_test.dart`, in the application suite. It covers REQ-DAT-004.1 to .5.
- **Factory unit test file:** `test/data/element_repository_factory_test.dart`, in the application suite. It covers REQ-DAT-004.6.
- **Unit test files:** the repository unit test file and the factory unit test file.
- **Guard test file:** `test/element_repository_guard_test.dart`, in the application suite. It covers REQ-DAT-004.7 to .10.
- **GP client guard test file:** `test/celestrak_gp_client_guard_test.dart`, from req-dat-002. The implementation of this spec changes it only as REQ-DAT-004.9 requires.
- **Snapshot data file:** `test/domain/celestrak_tle_snapshot.dart`, from req-dat-001. This spec reads it and never changes it.
- **Spec file:** `specs/req-dat-004.md`.
- **Amended spec file:** `specs/req-dat-002.md`.
- **ADR file:** `docs/adr/ADR-0007-principle-10-across-runs.md`.
- **Non-zero offset:** a UTC offset at N0 other than zero, such as `-03:00` in Chile, on the machine that runs a command.
- **Instants used by the tests:** N0 is 2026-01-15 12:00:00 UTC. N0 lies months before the drafting of this spec, so a repository that read the system clock instead of its injected wall clock would find every arrival instant of the tests far older than 6 hours, and the tests below would catch it. H is 6 hours, and 1 µs is one microsecond.
- **Test clock:** a wall clock of a unit test that returns an instant the test sets and moves. The GP client and the repository of a test read the same test clock.
- **Mock client:** a `MockClient` of `package:http/testing.dart`. The mock client of a test records the `CATNR` query parameter of every request it receives, in order, and answers it as the test states. "Success response of an object" is status 200 with the body made of the name token, line 1 and line 2 of its snapshot entry, each followed by an LF. "Requests" are the recorded catalog numbers.
- **Let the event loop run once:** the test executes `await Future<void>.delayed(Duration.zero);`. Let it run ten times: the test executes that statement ten times in a row.
- **Held answers:** a mock client that holds its answers awaits one `Completer<void>` of the test before it answers any request. "Releasing the answers" completes that completer; from then on every pending and every later request is answered at once, without holding.
- **Cached at instant A:** for an object at position k, the state in which its cache file holds what a write of the success of position k at A (as defined by `specs/req-dat-003.md`) stores, written by a cache on the test's temporary directory before the repository of the test is created.

## Functional Requirements

### REQ-DAT-004.1 — Lookup

A lookup serves the element set kept in memory, or else the one the cache holds, and never reaches the network. A cold start with a cache therefore needs no network.

**Acceptance (verified by the repository unit test file).** Unless a case says otherwise, each test creates a new, empty temporary directory, a cache on it, a GP client on a mock client that answers every request with the success response of its object, and a repository on that GP client and cache, with the test clock at N0.

- **Cold start from the cache.** For each position k from 1 to 4, with the object at position k cached at N0 − 1 hour, a lookup of that object completes with a served element set whose:
  - tracked object is the object at position k;
  - `OrbitalElements` is equal to `OrbitalElements.fromTle` of line 1 and line 2 of snapshot entry k;
  - arrival instant is in UTC and equal to N0 − 1 hour.

  The mock client then has recorded no request.
- **No element set.** In an empty cache directory, a lookup of ISS completes with `null`. The mock client has recorded no request, and the cache directory still contains no item.
- **Kept in memory.** In an empty cache directory, after a refresh at N0 whose outcome for ISS is refreshed, the test deletes the whole cache directory. A lookup of ISS by the same repository then completes with a served element set whose arrival instant is N0.
- **A refresh replaces what a lookup serves.** With ISS cached at N0 − 7 hours, a lookup of ISS completes with arrival instant N0 − 7 hours. After a refresh at N0 whose outcome for ISS is refreshed, a lookup of ISS completes with arrival instant N0.
- **A lookup does not decide.** With ISS cached at N0 − 7 hours, ten lookups of ISS complete with arrival instant N0 − 7 hours, and the mock client has recorded no request.

### REQ-DAT-004.2 — Due objects and the refresh threshold

A refresh requests exactly the due objects: those with no element set, those whose arrival instant is 6 hours old or older, and those whose arrival instant is in the future.

**Acceptance (verified by the repository unit test file).** The set-up is that of REQ-DAT-004.1.

- **Three outcomes.** The outcome type has exactly three values.
- **Every key.** Every refresh of this requirement completes with a map whose keys are exactly the four tracked objects.
- **Fresh.** With all four objects cached at N0 − (H − 1 µs), a refresh at N0 completes with not due for all four, and the mock client has recorded no request.
- **At the threshold.** With all four objects cached at N0 − H, a refresh at N0 completes with refreshed for all four. The requests are the four catalog numbers, and afterwards a read of each object by a second cache on the same directory completes with an entry whose arrival instant is N0.
- **No element set.** In an empty cache directory, a refresh at N0 completes with refreshed for all four; the requests are the four catalog numbers, and the cache directory then contains exactly the four cache files.
- **Only what is due.** With ISS cached at N0 − 1 hour and no other object cached, a refresh at N0 completes with not due for ISS and refreshed for the other three, and the requests are the catalog numbers of positions 2 to 4.
- **An arrival instant in the future.** With ISS cached at N0 + 1 minute and the other three cached at N0 − 1 hour, a refresh at N0 completes with refreshed for ISS and not due for the other three. The only request is the catalog number of ISS, and a lookup of ISS then completes with arrival instant N0.
- **Not due opens no window.** With all four objects cached at N0 − 1 hour, a refresh at N0 completes with not due for all four. The test clock is then moved to N0 + 5 hours, where the arrival instants are 6 hours old, and a refresh completes with refreshed for all four.

### REQ-DAT-004.3 — Failures and the attempt window

A failed attempt keeps the element set already served, and no object is attempted again within 6 hours of its last attempt in the same repository. A success is served even when its cache write fails.

**Acceptance (verified by the repository unit test file).** The set-up is that of REQ-DAT-004.1, except that the mock client answers the requests for ISS as each case states.

- **Every failure is failed.** For each of these answers to the requests for ISS, with ISS cached at N0 − 7 hours and the other three cached at N0 − 1 hour, a refresh at N0 completes with failed for ISS and not due for the other three, the only request is the catalog number of ISS, a lookup of ISS then completes with arrival instant N0 − 7 hours, and the cache file of ISS holds exactly the bytes it held before the refresh:
  - status 500 with an empty body;
  - status 403 with an empty body;
  - status 200 with the body `No GP data found`;
  - status 200 with the body `not a TLE`;
  - the mock client throws a `ClientException`.
- **A timeout is failed.** The GP client of this case is created on the mock client with a timeout of 10 milliseconds and the test clock, and the mock client answers the requests for ISS with a future that never completes. With ISS cached at N0 − 7 hours and the other three cached at N0 − 1 hour, a refresh at N0 completes with failed for ISS and not due for the other three, the only request is the catalog number of ISS, a lookup of ISS then completes with arrival instant N0 − 7 hours, and the cache file of ISS holds exactly the bytes it held before the refresh.
- **A failure without a cache.** In an empty cache directory, with the requests for ISS answered with status 500, a refresh at N0 completes with failed for ISS and refreshed for the other three, and a lookup of ISS then completes with `null`.
- **The window of a failure.** In an empty cache directory, with the requests for ISS answered with status 500, a refresh at N0 completes with failed for ISS. Then the mock client answers every request with the success response of its object, and:
  - at N0 + H − 1 µs, a refresh completes with not due for ISS, and no new request for ISS is recorded;
  - at N0 + H, a refresh completes with refreshed for all four, and the new requests are the four catalog numbers in catalog order, so exactly one new request for ISS is recorded; the other three, 6 hours old at N0 + H, are requested again too.
- **One window per object.** With ISS cached at N0 − 7 hours and answered with status 500, Tiangong cached at N0 − 5 hours, and the other two cached at N0, a refresh at N0 completes with failed for ISS and not due for the other three. At N0 + 1 hour, where Tiangong is 6 hours old, a refresh completes with not due for ISS and refreshed for Tiangong, and the only new request is the catalog number of Tiangong.
- **The window of a success.** In an empty cache directory, a refresh at N0 completes with refreshed for all four. At N0 + H − 1 µs a refresh completes with not due for all four and no new request is recorded; at N0 + H a refresh completes with refreshed for all four.
- **The window is in memory only.** In an empty cache directory, with the requests for ISS answered with status 500, a refresh at N0 completes with failed for ISS. Afterwards the cache directory contains exactly the cache files of the other three objects and no other item. A second repository, created with a new GP client on the same mock client and a new cache on the same directory, then refreshes at N0 + 1 minute: its outcome for ISS is failed, and one new request, the catalog number of ISS, is recorded.
- **A success whose write fails.** The cache is created with the path of an existing file inside the temporary directory, so that every write completes with `false`. A refresh at N0 completes with refreshed for all four, and a lookup of ISS then completes with a served element set whose `OrbitalElements` is equal to `OrbitalElements.fromTle` of line 1 and line 2 of snapshot entry 1 and whose arrival instant is N0. The file holds exactly the bytes it held before the refresh. At N0 + 1 hour a refresh completes with not due for all four.

### REQ-DAT-004.4 — One request at a time and joined refreshes

A refresh sends its requests one after the other, in catalog order, and a refresh asked for during another joins it.

**Acceptance (verified by the repository unit test file).** The set-up is that of REQ-DAT-004.1, in an empty cache directory unless a case says otherwise.

- **In catalog order, one at a time.** With all four objects cached at N0 − 7 hours, the test first makes one lookup of each object, so that the refresh finds every served element set in memory and reads no file before its requests. The mock client counts the requests in flight: it adds one when a request arrives, lets the event loop run once (Definitions) before it answers, and subtracts one when it answers. A refresh at N0 completes with refreshed for all four; the requests are the four catalog numbers in catalog order, and at no time were two requests in flight. Because no file is read before a request, a refresh that fetches concurrently sends its next request without waiting on the file system, so the count of requests in flight does not depend on the timing of a disk.
- **A failure does not stop the refresh.** With the requests for ISS answered by throwing a `ClientException`, a refresh at N0 completes with failed for ISS and refreshed for the other three, and the requests are the four catalog numbers in catalog order.
- **A joined refresh.** The mock client holds its answers (Definitions, held answers). The test asks for a refresh at N0, lets the event loop run once, asks for a second refresh, and then releases the answers. Both refreshes complete with refreshed for all four, their maps are equal, and exactly four requests are recorded. For each of the two maps, setting the outcome of ISS to failed throws `UnsupportedError`, and the map still holds refreshed for ISS. A third refresh, asked for after both completed, completes with not due for all four, and no new request is recorded.
- **Nothing happens unless asked.** In an empty cache directory, with the requests for ISS answered with status 500, a refresh at N0 completes. The test clock is then moved to N0 + 7 hours and the event loop is let run ten times; no new request is recorded. Only a refresh asked for afterwards records a new request for ISS.

### REQ-DAT-004.5 — Data age

The data age of a served element set is the time since its arrival instant, never negative, and unknown before its arrival instant.

**Acceptance (verified by the repository unit test file).** With ISS cached at N0 − 3 hours, a lookup of ISS completes with a served element set S. Then:

- the data age of S at N0 is 3 hours, exactly;
- the data age of S at N0 − 3 hours is zero;
- the data age of S at N0 − 4 hours, an instant before its arrival, is `null`;
- the data age of S at N0 − 3 hours − 1 µs, the last microsecond before its arrival, is `null`;
- the data age of S at N0 converted to local time is 3 hours, exactly;
- with ISS cached at N0 − 1 µs instead, the data age at N0 of the served element set of a lookup of ISS is 1 µs.

V1 also runs at a non-zero offset (Local checks): on a machine at offset zero, such as the CI runner, N0 converted to local time denotes the same calendar fields as N0, so the case cannot tell an age computed from moments from one computed from calendar fields.

That the served element set reads no clock is verified by the guard test file (REQ-DAT-004.7, domain library file).

### REQ-DAT-004.6 — Opening: directory, HTTP client and clock

The open operation resolves the directory first, creates exactly one HTTP client, builds the repository on the resolved directory itself, sends no request and writes nothing, and the handle closes the client it created exactly once.

**Acceptance (verified by the factory unit test file).** Each test creates a new, empty temporary directory, a directory resolver that completes with it and counts its calls, and an HTTP client creator that counts its calls and returns a recording client. The recording client is a subclass of the `BaseClient` of `package:http/http.dart`, defined in the factory unit test file, that sends every request to a mock client answering with the success response of its object, and counts its calls of `close`. The test clock is at N0.

- **Opening sends and writes nothing.** The open operation, with the resolver, the creator and the test clock, completes with a handle. The resolver and the creator have each been called exactly once, the mock client has recorded no request, and the temporary directory contains no item.
- **The resolved directory itself.** After a refresh at N0 through the repository of the handle, which completes with refreshed for all four, the temporary directory contains exactly the four cache files and no other item, and a read of each object by a cache on the temporary directory completes with an entry whose arrival instant is N0. So the cache directory is the resolved directory, not a directory inside it, and the GP client reads the test clock.
- **The clock of the repository.** After that refresh, a refresh at N0 + 1 hour completes with not due for all four with no new request, and a refresh at N0 + 7 hours completes with refreshed for all four. So the repository reads the test clock.
- **The resolver first.** With a resolver that completes with a `StateError`, the open operation completes with that same error, and the creator has not been called.
- **Close once.** After the close operation of a handle completes, the recording client has been closed exactly once. After a second call of the close operation completes, it has still been closed exactly once.

### REQ-DAT-004.7 — Placement, public surface, boundaries and documented contract

The contract lives in the domain layer and reads no clock; the repository lives in the data layer, handles no exception, reads only its own wall clock and schedules nothing; the factory is the only file of this spec that knows the platform directory and the HTTP package; and each file documents its contract in fixed lines.

**Acceptance (verified by the guard test file).**

**Domain library file.**

- **Placement.** The domain library file exists.
- **Imports.** No line of the domain library file, with leading blank characters removed, starts with `export ` or `part `. Every line that, with leading blank characters removed, starts with `import ` has one of these import URIs, and both are present:
  - `package:orbital_core/orbital_core.dart`;
  - `package:wintek/domain/satellite_catalog.dart`.
- **Public surface.**
  - Every declaration line is a public type declaration or a private declaration.
  - There are exactly three public type declarations: exactly one starts with `abstract interface class `, exactly one starts with `final class `, and exactly one starts with `enum `.
- **No clock, no I/O, no timer.** The domain library file contains none of `DateTime.now`, `DateTime.timestamp`, `Stopwatch`, `Sync(`, `Timer`, `periodic` and `delayed`.
- **No catalog number.** The domain library file contains none of the substrings `25544`, `48274`, `38011` or `60133`.
- **A small contract.** The domain library file contains none of `nameLine`, `statusCode`, `GpFetch` and `Exception`, so the contract neither keeps a failure nor exposes the name line.
- **Doc lines.** The domain library file contains a line that matches each of:
  - `/// The element repository contract of Wintek: the only way the rest of the app reads orbital elements (specs/req-dat-004.md).`
  - `/// Depends only on orbital_core and the domain layer (Constitution principle 5); lib/data implements it.`
  - `/// The data age is the age of the download, measured from the arrival instant; it is never negative, and it is null (unknown) before the arrival instant.`

**Repository library file.**

- **Placement.** The repository library file exists.
- **Imports.** No line of the repository library file, with leading blank characters removed, starts with `export ` or `part `. Every line that, with leading blank characters removed, starts with `import ` has one of these import URIs:
  - `dart:async`;
  - `package:orbital_core/orbital_core.dart`;
  - `package:wintek/data/celestrak_gp_client.dart`;
  - `package:wintek/data/element_cache.dart`;
  - `package:wintek/domain/element_repository.dart`;
  - `package:wintek/domain/satellite_catalog.dart`.

  `package:wintek/data/celestrak_gp_client.dart`, `package:wintek/data/element_cache.dart` and `package:wintek/domain/element_repository.dart` are each present. So the repository imports neither Flutter, nor Riverpod, nor `dart:io`, nor `path_provider`, nor `package:http`.
- **Public surface.**
  - Every declaration line is a public type declaration or a private declaration.
  - There is exactly one public type declaration. It starts with `final class `, and it contains ` implements ` followed directly by the declared name of the contract (see Definitions, the names, for the length this needs).
- **No exception handled.** The repository library file contains none of `try {`, `catch`, `onError`, `handleError`, `runZoned` and `Zone.`, in code or in comments.
- **Its own clock only.** The repository library file contains `DateTime.now` exactly once, and none of `DateTime.timestamp` and `Stopwatch`.
- **Nothing scheduled.** The repository library file contains none of `Timer`, `periodic` and `delayed`.
- **No catalog number.** The repository library file contains none of the substrings `25544`, `48274`, `38011` or `60133`.
- **Doc lines.** The repository library file contains a line that matches each of:
  - `/// The element repository of Wintek: serves the last good element set of each tracked object and refreshes it from CelesTrak only when it is due (specs/req-dat-004.md).`
  - `/// Due: no element set, an arrival instant 6 hours old or older, or one in the future; never within 6 hours of the last attempt for that object.`
  - `/// Attempts are kept in memory only, never on disk (Constitution principles 10 and 11, ADR-0007); nothing here schedules, retries or polls.`
  - `/// A refresh sends one request at a time, in catalog order, and a refresh asked for while one runs joins it, so no object is ever written twice at once.`
  - `/// A lookup never reaches the network: it serves memory first, then the cache, so a cold start needs no network (Constitution principle 9).`
  - `/// Every success is written to the cache and served from memory even if the write fails; a failure keeps the element set already served.`
  - `/// A lookup keeps what it read from the cache only if memory still holds nothing for that object, so it never replaces a newer element set.`

**Factory library file.**

- **Placement.** The factory library file exists.
- **Imports.** No line of the factory library file, with leading blank characters removed, starts with `export ` or `part `. Every line that, with leading blank characters removed, starts with `import ` has one of these import URIs, and all but `dart:async` are each present:
  - `dart:async`;
  - `dart:io`;
  - `package:http/http.dart`;
  - `package:path_provider/path_provider.dart`;
  - `package:wintek/data/celestrak_element_repository.dart`;
  - `package:wintek/data/celestrak_gp_client.dart`;
  - `package:wintek/data/element_cache.dart`;
  - `package:wintek/domain/element_repository.dart`.

  So the factory imports neither Flutter nor Riverpod.
- **Public surface.**
  - Every declaration line is a public type declaration or a private declaration.
  - There is exactly one public type declaration, and it starts with `final class `.
- **The application support directory.** The factory library file contains a code line that contains `getApplicationSupportDirectory`; it contains none of `systemTemp`, `Directory.current` and `createTemp`; and it contains none of `getApplicationCacheDirectory`, `getTemporaryDirectory`, `getApplicationDocumentsDirectory`, `getExternal`, `getDownloadsDirectory` and `getLibraryDirectory`.
- **The directory as resolved.** Every occurrence of `Directory(` in the factory library file is part of an occurrence of `getApplicationSupportDirectory(`. The factory library file contains none of `File(`, `.path`, `.create(`, `.delete(`, `.list(` and `Sync(`. So the factory neither builds a directory of its own, nor touches the disk.
- **One HTTP client, created and closed here.** The factory library file contains exactly one occurrence in total, counting both substrings, of `Client(` and `Client.new` that is not directly preceded by an ASCII letter, and contains `.close(`. So it creates the production client in one place, while the names of the GP client type and of its own members may end in `Client`.
- **No clock, no exception handled, nothing scheduled.** The factory library file contains none of `DateTime.now`, `DateTime.timestamp`, `Stopwatch`, `try {`, `catch`, `onError`, `handleError`, `runZoned`, `Zone.`, `Timer`, `periodic` and `delayed`.
- **No catalog number.** The factory library file contains none of the substrings `25544`, `48274`, `38011` or `60133`.
- **Doc lines.** The factory library file contains a line that matches each of:
  - `/// Opens the element repository of the app on the application support directory of path_provider, which the operating system does not clear on its own (specs/req-dat-004.md).`
  - `/// Creates the one production HTTP client of the app and closes it once on close; whoever creates it owns it (specs/req-dat-002.md, amended by req-dat-004).`
  - `/// Opening resolves the directory first and sends no request; the resolver, the HTTP client creator and the clock are injectable for tests.`

The rules of REQ-DAT-002.4, as amended by REQ-DAT-004.9, apply to the three library files of this spec like to every application library file; the GP client guard test file checks them.

### REQ-DAT-004.8 — Layer rules

The domain layer depends only on the core, on itself and on the Dart SDK libraries that do no I/O, no library file outside the data layer reaches the data layer except the composition root, and the presentation layer never reaches the data layer, the network package, the platform directory, the file system or JSON parsing (Constitution principles 4 and 5).

**Acceptance (verified by the guard test file).**

- **Domain.** For every domain library file:
  - no line, with leading blank characters removed, starts with `export ` or `part `;
  - every line that, with leading blank characters removed, starts with `import ` has the import URI `package:orbital_core/orbital_core.dart`, an import URI that starts with `package:wintek/domain/`, or an import URI that starts with `dart:` and is not a forbidden SDK library (Definitions).
- **Presentation.** For every presentation library file, every line that, with leading blank characters removed, starts with `import ` or `export ` has an import URI that:
  - starts with `package:` or `dart:`, or is an inner relative URI (Definitions), so no relative import can reach another layer;
  - does not start with `package:wintek/data/`, `package:http/`, `package:path_provider/`, `dart:io` or `dart:convert`.
- **Outside the data layer.** For every library file outside the data layer, no line that, with leading blank characters removed, starts with `import ` or `export ` has an import URI that starts with `package:wintek/data/`, or that starts with neither `package:` nor `dart:` and either starts with `data/` or contains `/data/`.

A presentation layer with no library file meets the rule, as it does when this spec is implemented; that the directory exists is checked by REQ-DAT-004.10 (missing files fail). The domain library file of this spec keeps its own, narrower list of imports (REQ-DAT-004.7). Rows P1 to P3 prove that the guard accepts what this rule allows.

`lib/main.dart` is the composition root of the app and is neither a domain, a presentation library file nor a library file outside the data layer; it is the only application library file outside `lib/data` that may import the factory library file (req-sta-001). A later directory, such as one for Riverpod providers, is a library file outside the data layer and reaches the repository only through the contract.

### REQ-DAT-004.9 — The amendments of req-dat-002 and ADR-0007

REQ-DAT-002.4 lets the factory library file import `package:http/http.dart`, and nothing else changes in the network boundary; the Blocks entry of req-dat-004 in req-dat-002 matches this spec; and ADR-0007, which records the reading of Constitution principle 10 that the attempt window makes, is accepted.

**Acceptance (verified by the guard test file).** The pull request that brings this spec into `main` amends the amended spec file and adds the ADR file, which the developer accepts before that pull request merges; the guard of the implementation keeps both.

The lines below are written between double backticks, so that the single backticks they contain are part of the text to match.

- The amended spec file contains a line that matches `` - **Amended by req-dat-004 (2026-11-15):** REQ-DAT-002.4 lets exactly one more application library file, `lib/data/element_repository_factory.dart`, import `package:http/http.dart` to create and close the production HTTP client. The client library file stays the only file that uses `HttpClient`, a socket or an address lookup, or names the CelesTrak host. ``, and that line comes before the first line that starts with `- **Roadmap row:**`.
- The amended spec file contains a line that matches `` - **The only network boundary** (amended by req-dat-004 on 2026-11-15). ``, and the next line after it matches `` - No application library file other than the client library file and the factory library file of req-dat-004, `lib/data/element_repository_factory.dart`, contains the substring `package:http/`. ``.
- The amended spec file contains a line that matches `` - In the factory library file of req-dat-004, every line that contains `package:http/` is a line that, with leading blank characters removed, starts with `import ` and whose import URI is `package:http/http.dart`. ``.
- The amended spec file contains a line that matches `` - No application library file other than the client library file contains any of the substrings `HttpClient`, `Socket` or `InternetAddress`. ``.
- The amended spec file contains no line that matches `` - No application library file other than the client library file contains any of the substrings `package:http/`, `HttpClient`, `Socket` or `InternetAddress`. ``, the line of revision 2 of req-dat-002 that the amendment replaces.
- The amended spec file contains a line that matches `` - req-dat-004: decides when to call the client, creates and owns its HTTP client, and records each failure as the outcome failed while it keeps serving the element set it had; the data age and the stale-data warning follow from the arrival instant, not from the failure (amended by req-dat-004 on 2026-11-16). Creating the HTTP client outside the client library file needs an amendment of REQ-DAT-002.4 in that spec. ``, and no line that contains `maps its failures to the data age`.
- The ADR file contains a line that matches `# ADR-0007 — Reading of Constitution principle 10 across runs of the app`, and a line that, with leading blank characters removed, starts with `- **Status:** Accepted`.

**Acceptance (verified by the GP client guard test file and rows N1 to N7).** The implementation changes the check of the network boundary in the GP client guard test file, and only that check, so that it enforces REQ-DAT-002.4 as amended: the substring `package:http/` is allowed in the client library file and, only on import lines whose import URI is `package:http/http.dart`, in the factory library file; `HttpClient`, `Socket`, `InternetAddress` and `celestrak.org` stay allowed only in the client library file. Every other check of that file, and every failure message tag it prints, is unchanged. No command proves this: the pull request shows the diff of that file, and the reviewer confirms that only the network-boundary check changed.

### REQ-DAT-004.10 — Test hygiene

The new test files follow the hygiene rules of req-dat-003, the unit test files can construct neither a real HTTP client nor a platform directory, and every new file is saved with LF and without BOM.

**Acceptance (verified by the guard test file).**

- **Repository unit test imports.**
  - Every line of the repository unit test file that, with leading blank characters removed, starts with `import ` has one of these import URIs:
    - `dart:async`;
    - `dart:io`;
    - `package:flutter_test/flutter_test.dart`;
    - `package:http/http.dart`;
    - `package:http/testing.dart`;
    - `package:orbital_core/orbital_core.dart`;
    - `package:wintek/data/celestrak_element_repository.dart`;
    - `package:wintek/data/celestrak_gp_client.dart`;
    - `package:wintek/data/element_cache.dart`;
    - `package:wintek/domain/element_repository.dart`;
    - `package:wintek/domain/satellite_catalog.dart`;
    - `../domain/celestrak_tle_snapshot.dart`.
  - `dart:io`, `package:flutter_test/flutter_test.dart`, `package:http/testing.dart`, `package:wintek/data/celestrak_element_repository.dart`, `package:wintek/data/element_cache.dart` and `../domain/celestrak_tle_snapshot.dart` are each present.
- **Factory unit test imports.**
  - Every line of the factory unit test file that, with leading blank characters removed, starts with `import ` has one of these import URIs:
    - `dart:async`;
    - `dart:io`;
    - `package:flutter_test/flutter_test.dart`;
    - `package:http/http.dart`;
    - `package:http/testing.dart`;
    - `package:wintek/data/element_cache.dart`;
    - `package:wintek/data/element_repository_factory.dart`;
    - `package:wintek/domain/element_repository.dart`;
    - `package:wintek/domain/satellite_catalog.dart`;
    - `../domain/celestrak_tle_snapshot.dart`.
  - `dart:io`, `package:flutter_test/flutter_test.dart`, `package:http/http.dart`, `package:http/testing.dart`, `package:wintek/data/element_cache.dart`, `package:wintek/data/element_repository_factory.dart` and `../domain/celestrak_tle_snapshot.dart` are each present.
- **No export.** No line of either unit test file, with leading blank characters removed, starts with `export `.
- **No real HTTP client and no platform directory.** In each unit test file, every occurrence of `Client(` is directly preceded by an ASCII letter, and the file contains none of `Client.new`, `IOClient`, `HttpClient`, `path_provider/` and `getApplication`. So a test can build a `MockClient` or a recording client of its own, but never the production client, and never calls `path_provider`.
- **Temporary directories only.** For each unit test file:
  - it contains the substring `createTemp(`, and at least one of `tearDown(` and `addTearDown(`;
  - every occurrence of `systemTemp` in it is directly followed by `.createTemp(`;
  - it contains none of `Directory.current`, `Platform.`, `.parent`, `'/` and `"/`.
- **Unit test citation.** Each unit test file contains a line that matches `// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test reaches CelesTrak or a platform directory, and every test writes only inside a temporary directory it creates and deletes (Constitution principles 10 and 11).`
- **Tags.**
  - For each N from 1 to 5, the repository unit test file contains a line that matches `// REQ-DAT-004.N`, and the factory unit test file contains a line that matches `// REQ-DAT-004.6`. For each such line, let L be the next non-empty line after it, with leading blank characters removed. L starts with `group('REQ-DAT-004.N ` or `test('REQ-DAT-004.N `, with the N of that line. Alternatively, L is equal to `group(` or `test(`, and the next line after L, with leading blank characters removed, starts with `'REQ-DAT-004.N `.
  - Every line of a unit test file that, with leading blank characters removed, starts with `group(` or `test(` is tagged as above, with an N from 1 to 5 in the repository unit test file and with 6 in the factory unit test file.
  - For each N from 7 to 10, the guard test file contains a line that matches `// REQ-DAT-004.N`. The next non-empty line after it, with leading blank characters removed, starts with `test(`.
  - The guard test file contains no occurrence of `REQ-DAT-004.` that is directly followed by a digit from 1 to 6 which is not itself directly followed by a digit, in any line, comment or string literal. So it builds the tags and name prefixes of REQ-DAT-004.1 to .6 by interpolation, never as literals, while `REQ-DAT-004.10` stays allowed.
- **Self-matching tokens.** The guard test file builds the tokens `Platform.script` and `skip:` by concatenation of shorter string literals, never as one literal.
- **No skipped tests.** Neither unit test file nor the guard test file contains the substring `skip:`.
- **Bytes.** None of these files contains the byte `0D` (CR) or starts with the bytes `EF BB BF` (UTF-8 BOM): the three library files of this spec, both unit test files, the guard test file, the spec file, the amended spec file and the ADR file.
- **Repository root.** The guard test file contains the line `import 'support/repo_root.dart';` and does not contain the substring `Platform.script`.
- **Plain text only.** The guard test file reads files as plain text. Its import URIs are only `dart:io`, `package:flutter_test/flutter_test.dart` and `support/repo_root.dart`, so it uses no YAML, JSON, Markdown or other parser.
- **Missing files fail.** Each of the following produces a failing test when missing, never a skipped or passing one: the three library files of this spec, the `lib`, `lib/domain` and `lib/presentation` directories, both unit test files, the snapshot data file, the spec file, the amended spec file and the ADR file. A missing guard test file is caught by V3.
- **Failure messages.** Every failure message of the guard test file starts with `[REQ-DAT-004.N]`, where N is the requirement whose check failed, and carries `specs/req-dat-004.md` on the same line as that tag.

**Acceptance (verified by command V10).** Compared with the base of V10, the implementation changes exactly the seven files of V10. The one allowed exception is the spec file: when the implementation needs a behaviour change, it may also change `specs/req-dat-004.md`, with the developer's approval linked in the pull request description (Constitution principle 2). V10 is a local check: CI does not run it, and the pull request checklist reports its result.

## Mathematical Validation / Testing

This spec adds no formula: the data age is the difference of two UTC instants, or unknown when it would be negative, and the threshold is a comparison of durations. There is nothing to check against Vallado or Curtis, and Constitution principle 6 is not triggered. Its evidence is behaviour against fixed instants and fixed responses:

- every payload is rebuilt from the snapshot of req-dat-001, whose provenance that spec records, or is written in this spec;
- the instants of the tests are fixed, and the GP client and the repository read one test clock that the test moves, so every case of the threshold and of the attempt window is checked at its boundary, to the microsecond;
- REQ-DAT-004.1 and .3 prove that a cold start and every failure serve the cached element set, which is what makes offline a feature;
- no test reads or writes outside a temporary directory that it created, no test calls `path_provider`, and no test sends a request to CelesTrak.

All commands in this section run from a POSIX shell with GNU `sed`: Git Bash on Windows, or a shell on Linux.

### Local checks (run on the implementation branch before opening the pull request)

| # | Command (from repository root) | Expected | Proves |
| --- | --- | --- | --- |
| V0 | `git ls-files --eol specs/req-dat-004.md specs/req-dat-002.md docs/adr/ADR-0007-principle-10-across-runs.md \| grep -c "w/lf"` | standard output `3` | Precondition: the working tree holds both spec files and the ADR file with LF |
| V1 | `flutter test test/data/celestrak_element_repository_test.dart --reporter expanded` | exit 0 | REQ-DAT-004.1 – .5 |
| V2 | `flutter test test/data/element_repository_factory_test.dart --reporter expanded` | exit 0 | REQ-DAT-004.6 |
| V3 | `flutter test test/element_repository_guard_test.dart --reporter expanded` | exit 0 | REQ-DAT-004.7 – .10 |
| V4 | `flutter test test/celestrak_gp_client_guard_test.dart --reporter expanded` | exit 0 | REQ-DAT-002.4 as amended by REQ-DAT-004.9 |
| V5 | `flutter test` | exit 0 | All of the above; the guards of req-dat-001 to req-dat-003 and `test/dependency_guard_test.dart` still pass |
| V6 | `flutter analyze --fatal-infos --fatal-warnings` | exit 0 | Constitution principle 8 |
| V7 | `dart format --set-exit-if-changed .` | exit 0 | Constitution principle 8 |
| V8 | `dart pub get && dart analyze --fatal-infos && dart test`, inside `packages/orbital_core` | exit 0 | The core is untouched and still passes on its own (Constitution principle 3) |
| V9 | `{ grep -rlE "HttpClient\|Socket\|InternetAddress" lib; grep -rli "celestrak\.org" lib; } \| LC_ALL=C sort -u \| paste -sd, -` | standard output `lib/data/celestrak_gp_client.dart` | REQ-DAT-002.4 as amended: the client is still the only file that uses a socket API or names the host |
| V10 | `git diff --name-only origin/main...HEAD \| LC_ALL=C sort \| paste -sd, -`, after `git fetch origin main` and with the preconditions of the base of V10 below | standard output `lib/data/celestrak_element_repository.dart,lib/data/element_repository_factory.dart,lib/domain/element_repository.dart,test/celestrak_gp_client_guard_test.dart,test/data/celestrak_element_repository_test.dart,test/data/element_repository_factory_test.dart,test/element_repository_guard_test.dart`; or, only when the pull request links the developer's approval of a spec diff, the same list with `specs/req-dat-004.md` appended | REQ-DAT-004.10 (only the files of this spec change) |
| V11 | `grep -rl "package:http/" lib \| LC_ALL=C sort \| paste -sd, -` | standard output `lib/data/celestrak_gp_client.dart,lib/data/element_repository_factory.dart` | REQ-DAT-002.4 as amended: exactly one more file knows the HTTP package |
| V12 | `grep -rl "path_provider" lib \| paste -sd, -` | standard output `lib/data/element_repository_factory.dart` | REQ-DAT-004.7: only the factory resolves the directory |
| V13 | `grep -rlE "25544\|48274\|38011\|60133" lib packages/orbital_core/lib \| paste -sd, -` | standard output `lib/domain/satellite_catalog.dart` | req-dat-001 one source of truth still holds |
| V14 | `grep -ohE "// REQ-DAT-004\.[0-9]+" test/element_repository_guard_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-004.10,// REQ-DAT-004.7,// REQ-DAT-004.8,// REQ-DAT-004.9` | REQ-DAT-004.10 (tags of the guard test file) |
| V15 | `grep -ohE "// REQ-DAT-004\.[0-9]+" test/data/celestrak_element_repository_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-004.1,// REQ-DAT-004.2,// REQ-DAT-004.3,// REQ-DAT-004.4,// REQ-DAT-004.5` | REQ-DAT-004.10 (tags of the repository unit test file) |
| V16 | `grep -ohE "// REQ-DAT-004\.[0-9]+" test/data/element_repository_factory_test.dart \| LC_ALL=C sort -u \| paste -sd, -` | standard output `// REQ-DAT-004.6` | REQ-DAT-004.10 (tags of the factory unit test file) |
| V17 | `git status --porcelain --ignored > /tmp/v17_before && flutter test --no-pub test/data/celestrak_element_repository_test.dart test/data/element_repository_factory_test.dart > /dev/null && git status --porcelain --ignored \| diff /tmp/v17_before -` | exit 0 and empty standard output | REQ-DAT-004.10: no unit test writes into the repository, ignored paths included |

Inside the table, `\|` is a single pipe. The CI workflow of req-inf-002 runs V5 to V8 on every pull request.

- `lib/domain/.gitkeep`, `lib/data/.gitkeep` and `lib/presentation/.gitkeep` stay, so V10 lists no deletion. The ADR file and the amendments of the amended spec file land with this spec, before the base of V10, so V10 lists neither.
- V1 and row M40 below also run at a non-zero offset (Definitions), and the pull request checklist records that offset. On a machine at offset zero, such as the CI runner, the local-time case of REQ-DAT-004.5 cannot tell an age computed from moments from one computed from calendar fields; a run of V1 or M40 at offset zero counts as not run for that purpose. The developer's machine in Chile is at `-03:00` at N0; a machine at offset zero sets a non-zero time zone in its operating system for that run, and the checklist records the offset that the run printed, for example with `date +%z`.
- In V14, `LC_ALL=C` sorts `10` before `7`; the expected output is written in that order.
- V9 uses `grep -rli` with an escaped dot rather than `grep -rliF`, as in req-dat-002: on the developer's Git Bash, `grep` aborts when `-i` and `-F` are combined.
- V17 runs after every file of the implementation is committed, like the negative checks below, and after V1 and V2, so the files that `flutter test` itself creates already exist; `git status --porcelain` must print nothing before it, and with uncommitted work V17 proves nothing and counts as not run.

**Base of V10.** As in `specs/req-dat-003.md`: the base is the merge base of the implementation branch and `main`, and `git diff origin/main...HEAD` compares `HEAD` with it. Run `git fetch origin main` before every run of V10. Two preconditions come first; when either fails, V10 counts as not run, never as a pass or a failure:

- `git log --first-parent --format=%H -1 origin/main -- specs/req-dat-004.md` prints a hash S, so the spec has reached `main`;
- `git merge-base --is-ancestor S HEAD` exits with 0, so the implementation branch contains the spec, and with it the amendment of the amended spec file.

The pull request checklist records S and the output of `git merge-base origin/main HEAD` at the run that it reports.

**Precondition of the new files.** Save the new files as UTF-8 without BOM and with LF. `.gitattributes` (`* text=auto eol=lf`) normalizes what enters the repository, but a Windows editor can still write CRLF into the working tree, and REQ-DAT-004.10 reads the working tree. If V0 prints less than `3`, rewrite each file that `git ls-files --eol` shows with `w/crlf` from the index, for example `rm specs/req-dat-002.md && git checkout -- specs/req-dat-002.md`, and run V0 again.

### Local negative checks

These run after every file of the implementation is committed on the implementation branch. Before the first row, `git status --porcelain` must print nothing; otherwise stop, because the edits and the revert below would destroy uncommitted work.

After each row, revert with:

    git checkout -- lib test specs docs && git clean -fdq lib test

The `git clean` removes the files that rows G52 to G59, G98 to G100 and P1 to P3 create, and the directory `lib/state` of G98 and G99. After the last row, `git status --porcelain` must print nothing again. If it prints a line, a row left a file behind, and the rows count as not run until the tree is clean.

Every row runs `flutter test` with `--no-pub`, so no row resolves dependencies, needs the network or rewrites `pubspec.lock`.

**Mutant rows (M).** The command is:

    flutter test --no-pub --reporter expanded <unit test file> 2>&1 | grep -F "[E]" | grep -F "<tag>"

where the unit test file is the repository unit test file for the tags `REQ-DAT-004.1` to `REQ-DAT-004.5`, and the factory unit test file for `REQ-DAT-004.6`. For each row, apply the edit, run the command and confirm that it prints at least one line: a failing test whose name carries the requirement ID.

M rows are mutants that depend on how the repository and the factory are written, so the implementer applies each one by hand, as the smallest change to the repository library file or the factory library file that has the stated effect. The pull request description shows the diff of each M row next to its result. This spec has no U rows: neither file holds a literal that a mechanical edit could change without also failing the guard.

| # | Edit | Tag expected |
| --- | --- | --- |
| M1 | A lookup with no served element set in memory asks the GP client instead of reading the cache | `REQ-DAT-004.1` |
| M2 | A lookup ignores memory and always reads the cache | `REQ-DAT-004.1` |
| M3 | A lookup serves only memory and never reads the cache | `REQ-DAT-004.1` |
| M4 | A success updates the cache but not the served element set in memory | `REQ-DAT-004.1` |
| M5 | Treat an arrival instant exactly 6 hours old as fresh | `REQ-DAT-004.2` |
| M6 | Use a refresh threshold of 6 hours minus 1 second | `REQ-DAT-004.2` |
| M7 | Use a refresh threshold of 6 hours plus 1 second | `REQ-DAT-004.2` |
| M8 | Treat an arrival instant later than the current instant as fresh | `REQ-DAT-004.2` |
| M9 | Leave the objects that are not due out of the map of outcomes | `REQ-DAT-004.2` |
| M10 | Skip the cache write after a success | `REQ-DAT-004.2` |
| M11 | Open an attempt window also when an object is not due | `REQ-DAT-004.2` |
| M12 | Open no attempt window after a failure | `REQ-DAT-004.3` |
| M13 | Close the attempt window 1 second early | `REQ-DAT-004.3` |
| M14 | Keep the attempt window open at exactly 6 hours | `REQ-DAT-004.3` |
| M15 | Keep one attempt window for all objects instead of one per object | `REQ-DAT-004.3` |
| M16 | Clear the served element set of an object after a failure | `REQ-DAT-004.3` |
| M17 | Record a failure as not due | `REQ-DAT-004.3` |
| M18 | Write a file in the cache directory that records the instant of every attempt, and read it when the repository is created | `REQ-DAT-004.3` |
| M19 | Serve a success from memory only when its cache write completes with `true` | `REQ-DAT-004.3` |
| M20 | Fetch the due objects concurrently, for example with `Future.wait` | `REQ-DAT-004.4` |
| M21 | Fetch the due objects in reverse catalog order | `REQ-DAT-004.4` |
| M22 | Start a new refresh for a refresh asked for while one runs, instead of joining it | `REQ-DAT-004.4` |
| M23 | Stop a refresh at its first failure, recording failed for the objects not yet fetched | `REQ-DAT-004.4` |
| M24 | Remove the clamp, so that the data age before the arrival instant is negative | `REQ-DAT-004.5` |
| M25 | Measure the data age from the epoch of the element set instead of the arrival instant | `REQ-DAT-004.5` |
| M26 | Truncate the data age to whole seconds | `REQ-DAT-004.5` |
| M27 | Make the repository read the system clock instead of its injected wall clock | `REQ-DAT-004.2` |
| M28 | Pass the wall clock of the open operation to the GP client but not to the repository | `REQ-DAT-004.6` |
| M29 | Pass the wall clock of the open operation to the repository but not to the GP client | `REQ-DAT-004.6` |
| M30 | Create the cache on a directory named `elements` inside the resolved directory | `REQ-DAT-004.6` |
| M31 | Call the HTTP client creator before the directory resolver | `REQ-DAT-004.6` |
| M32 | Call the directory resolver twice | `REQ-DAT-004.6` |
| M33 | Ask for a refresh during the open operation | `REQ-DAT-004.6` |
| M34 | Close the HTTP client at every call of the close operation | `REQ-DAT-004.6` |
| M35 | Do not close the HTTP client in the close operation | `REQ-DAT-004.6` |
| M36 | Record a timeout failure of the GP client as not due | `REQ-DAT-004.3` |
| M37 | Return zero instead of `null` as the data age at an instant before the arrival instant | `REQ-DAT-004.5` |
| M38 | Complete a refresh with a modifiable map | `REQ-DAT-004.4` |
| M39 | Make the HTTP client creator be called twice by the open operation, keeping the second client | `REQ-DAT-004.6` |
| M40 | Compute the data age from the calendar fields of the instant asked for, read as UTC whatever its offset | `REQ-DAT-004.5` |

- M27 relies on N0 lying in the past of every run: with the system clock, every arrival instant of the tests is months old, so the case "Fresh" of REQ-DAT-004.2 finds all four objects due. If the run happens on a machine whose clock is set before N0 + 6 hours, M27 counts as not run.
- M20 is read in the case "In catalog order, one at a time", where every element set is already in memory, so the concurrent fetches send their requests without waiting on a file and two of them are in flight at once.
- M40 runs at a non-zero offset (Local checks); at offset zero it counts as not run.
- M18 changes only the repository; a file that it writes inside the cache directory also fails the case "The window is in memory only".
- M30 is caught because the temporary directory then contains a directory and no cache file. In M30, M33 and M34 the factory library file still meets the guard, apart from what the mutant changes.

**Guard rows (G).** The command is:

    flutter test --no-pub test/element_repository_guard_test.dart 2>&1 | grep -F "<tag>" | grep -F "specs/req-dat-004.md"

**Control run (G0).** With no edit applied, run the G command once for each tag `[REQ-DAT-004.7]`, `[REQ-DAT-004.8]`, `[REQ-DAT-004.9]` and `[REQ-DAT-004.10]`, and confirm that each prints nothing. A printed line means the output of a passing run already carries a tag and the spec path, so the rows below would prove nothing. Fix the guard test file before continuing. Then, for each G row, apply the edit, run the G command and confirm that it prints at least one line.

The edits are defined as in `specs/req-orb-010.md` (Local negative checks). "The domain file", "the repository file", "the factory file", "the repository unit test file", "the factory unit test file", "the guard test file", "the spec file" and "the amended spec file" are the files of Definitions. "Create the file F with the line X" creates F, and any missing directory on its path, with X as its only line.

| # | Edit | Tag expected |
| --- | --- | --- |
| G1 | Delete the file `lib/domain/element_repository.dart` | `[REQ-DAT-004.7]` |
| G2 | Add `import 'package:flutter/foundation.dart';` as the first line of the domain file | `[REQ-DAT-004.7]` |
| G3 | Add `export 'package:orbital_core/orbital_core.dart';` as the first line of the domain file | `[REQ-DAT-004.7]` |
| G4 | Append the line `class ExtraRepository {}` to the domain file | `[REQ-DAT-004.7]` |
| G5 | Append the line `const Duration refreshThreshold = Duration(hours: 6);` to the domain file | `[REQ-DAT-004.7]` |
| G6 | Append the line `abstract class ExtraContract {}` to the domain file | `[REQ-DAT-004.7]` |
| G7 | Append the line `// DateTime.now()` to the domain file | `[REQ-DAT-004.7]` |
| G8 | Append the line `// Timer` to the domain file | `[REQ-DAT-004.7]` |
| G9 | Append the line `// ISS is 25544.` to the domain file | `[REQ-DAT-004.7]` |
| G10 | Delete the line `/// The element repository contract of Wintek: the only way the rest of the app reads orbital elements (specs/req-dat-004.md).` from the domain file | `[REQ-DAT-004.7]` |
| G11 | Delete the line `/// Depends only on orbital_core and the domain layer (Constitution principle 5); lib/data implements it.` from the domain file | `[REQ-DAT-004.7]` |
| G12 | Delete the line `/// The data age is the age of the download, measured from the arrival instant; it is never negative, and it is null (unknown) before the arrival instant.` from the domain file | `[REQ-DAT-004.7]` |
| G13 | Delete the file `lib/data/celestrak_element_repository.dart` | `[REQ-DAT-004.7]` |
| G14 | Add `import 'dart:io';` as the first line of the repository file | `[REQ-DAT-004.7]` |
| G15 | Add `import 'package:path_provider/path_provider.dart';` as the first line of the repository file | `[REQ-DAT-004.7]` |
| G16 | Add `import 'package:flutter_riverpod/flutter_riverpod.dart';` as the first line of the repository file | `[REQ-DAT-004.7]` |
| G17 | Delete the line `import 'package:wintek/data/element_cache.dart';` from the repository file | `[REQ-DAT-004.7]` |
| G18 | Append the line `class SecondRepository {}` to the repository file | `[REQ-DAT-004.7]` |
| G19 | By hand, like an M row: remove the `implements` clause from the declaration line of the repository, and show the diff in the pull request | `[REQ-DAT-004.7]` |
| G20 | Append the line `// try {` to the repository file | `[REQ-DAT-004.7]` |
| G21 | Append the line `// catch (e)` to the repository file | `[REQ-DAT-004.7]` |
| G22 | Append the line `// future.catchError((_) => null);` to the repository file | `[REQ-DAT-004.7]` |
| G23 | Append the line `// stream.listen(print, onError: print);` to the repository file | `[REQ-DAT-004.7]` |
| G24 | Append the line `// runZonedGuarded(body, handler);` to the repository file | `[REQ-DAT-004.7]` |
| G25 | Append the line `// DateTime.now` to the repository file | `[REQ-DAT-004.7]` |
| G26 | Append the line `// DateTime.timestamp()` to the repository file | `[REQ-DAT-004.7]` |
| G27 | Append the line `// Stopwatch()` to the repository file | `[REQ-DAT-004.7]` |
| G28 | Append the line `// Timer` to the repository file | `[REQ-DAT-004.7]` |
| G29 | Append the line `// Stream.periodic` to the repository file | `[REQ-DAT-004.7]` |
| G30 | Append the line `// Future.delayed` to the repository file | `[REQ-DAT-004.7]` |
| G31 | Append the line `// Tiangong is 48274.` to the repository file | `[REQ-DAT-004.7]` |
| G32 | Delete the line `/// The element repository of Wintek: serves the last good element set of each tracked object and refreshes it from CelesTrak only when it is due (specs/req-dat-004.md).` from the repository file | `[REQ-DAT-004.7]` |
| G33 | Delete the line `/// Due: no element set, an arrival instant 6 hours old or older, or one in the future; never within 6 hours of the last attempt for that object.` from the repository file | `[REQ-DAT-004.7]` |
| G34 | Delete the line `/// Attempts are kept in memory only, never on disk (Constitution principles 10 and 11, ADR-0007); nothing here schedules, retries or polls.` from the repository file | `[REQ-DAT-004.7]` |
| G35 | Delete the line `/// A refresh sends one request at a time, in catalog order, and a refresh asked for while one runs joins it, so no object is ever written twice at once.` from the repository file | `[REQ-DAT-004.7]` |
| G36 | Delete the line `/// A lookup never reaches the network: it serves memory first, then the cache, so a cold start needs no network (Constitution principle 9).` from the repository file | `[REQ-DAT-004.7]` |
| G37 | Delete the line `/// Every success is written to the cache and served from memory even if the write fails; a failure keeps the element set already served.` from the repository file | `[REQ-DAT-004.7]` |
| G38 | Delete the file `lib/data/element_repository_factory.dart` | `[REQ-DAT-004.7]` |
| G39 | Add `import 'package:flutter/foundation.dart';` as the first line of the factory file | `[REQ-DAT-004.7]` |
| G40 | Delete the line `import 'package:path_provider/path_provider.dart';` from the factory file | `[REQ-DAT-004.7]` |
| G41 | Append the line `class SecondHandle {}` to the factory file | `[REQ-DAT-004.7]` |
| G42 | Replace every occurrence of `getApplicationSupportDirectory` with `getApplicationCacheDirectory` in the factory file | `[REQ-DAT-004.7]` |
| G43 | Append the line `// getTemporaryDirectory` to the factory file | `[REQ-DAT-004.7]` |
| G44 | Append the line `// getApplicationDocumentsDirectory` to the factory file | `[REQ-DAT-004.7]` |
| G45 | Append the line `// getExternalStorageDirectory` to the factory file | `[REQ-DAT-004.7]` |
| G46 | Append the line `// Directory('elements')` to the factory file | `[REQ-DAT-004.7]` |
| G47 | Append the line `// File('settings.json')` to the factory file | `[REQ-DAT-004.7]` |
| G48 | Append the line `// directory.path` to the factory file | `[REQ-DAT-004.7]` |
| G49 | Append the line `// directory.create(recursive: true);` to the factory file | `[REQ-DAT-004.7]` |
| G50 | Append the line `// final second = http.Client();` to the factory file | `[REQ-DAT-004.7]` |
| G51 | Replace every occurrence of `.close(` with `.closeX(` in the factory file | `[REQ-DAT-004.7]` |
| G52 | Create the file `lib/domain/extra.dart` with the line `import 'package:wintek/data/element_cache.dart';` | `[REQ-DAT-004.8]` |
| G53 | Create the file `lib/domain/extra.dart` with the line `import 'dart:io';` | `[REQ-DAT-004.8]` |
| G54 | Create the file `lib/domain/extra.dart` with the line `part 'extra.g.dart';` | `[REQ-DAT-004.8]` |
| G55 | Create the file `lib/presentation/extra.dart` with the line `import 'package:wintek/data/celestrak_element_repository.dart';` | `[REQ-DAT-004.8]` |
| G56 | Create the file `lib/presentation/extra.dart` with the line `import '../data/element_cache.dart';` | `[REQ-DAT-004.8]` |
| G57 | Create the file `lib/presentation/extra.dart` with the line `import 'package:path_provider/path_provider.dart';` | `[REQ-DAT-004.8]` |
| G58 | Create the file `lib/presentation/extra.dart` with the line `import 'dart:io';` | `[REQ-DAT-004.8]` |
| G59 | Create the file `lib/presentation/widgets/extra.dart` with the line `export 'package:wintek/data/element_cache.dart';` | `[REQ-DAT-004.8]` |
| G60 | Delete the line that starts with `- **Amended by req-dat-004 (2026-11-15):**` from the amended spec file | `[REQ-DAT-004.9]` |
| G61 | Replace every occurrence of `` and the factory library file of req-dat-004, `lib/data/element_repository_factory.dart`, `` with a single space in the amended spec file | `[REQ-DAT-004.9]` |
| G62 | Delete the line that starts with `  - In the factory library file of req-dat-004, every line` from the amended spec file | `[REQ-DAT-004.9]` |
| G63 | Insert the line `` - No application library file other than the client library file contains any of the substrings `package:http/`, `HttpClient`, `Socket` or `InternetAddress`. ``, with two leading spaces, directly after the line that starts with `- **The only network boundary**` in the amended spec file | `[REQ-DAT-004.9]` |
| G64 | Run `rm -rf lib` | `[REQ-DAT-004.10]` |
| G65 | Add `import 'package:path_provider/path_provider.dart';` as the first line of the repository unit test file | `[REQ-DAT-004.10]` |
| G66 | Add `import 'package:wintek/data/element_repository_factory.dart';` as the first line of the repository unit test file | `[REQ-DAT-004.10]` |
| G67 | Append the line `// final real = http.Client();` to the repository unit test file | `[REQ-DAT-004.10]` |
| G68 | Append the line `// IOClient` to the factory unit test file | `[REQ-DAT-004.10]` |
| G69 | Append the line `// getApplicationSupportDirectory()` to the factory unit test file | `[REQ-DAT-004.10]` |
| G70 | Replace every occurrence of `createTemp(` with `createTempX(` in the factory unit test file | `[REQ-DAT-004.10]` |
| G71 | Append the line `// Directory.current` to the repository unit test file | `[REQ-DAT-004.10]` |
| G72 | Delete the line `// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test reaches CelesTrak or a platform directory, and every test writes only inside a temporary directory it creates and deletes (Constitution principles 10 and 11).` from the repository unit test file | `[REQ-DAT-004.10]` |
| G73 | Delete the same line from the factory unit test file | `[REQ-DAT-004.10]` |
| G74 | Replace the line `// REQ-DAT-004.3` with `// REQ-DAT-004.x` in the repository unit test file | `[REQ-DAT-004.10]` |
| G75 | Append the line `test('untagged', () {});` to the factory unit test file | `[REQ-DAT-004.10]` |
| G76 | Append the line `// skip: true` to the repository unit test file | `[REQ-DAT-004.10]` |
| G77 | Replace the line `// REQ-DAT-004.7` with `// REQ-DAT-004.x` in the guard test file; any other text containing it, such as a string literal, is left unchanged | `[REQ-DAT-004.10]` |
| G78 | Append the line `// REQ-DAT-004.1` to the guard test file | `[REQ-DAT-004.10]` |
| G79 | Append the line `// Platform.script` to the guard test file | `[REQ-DAT-004.10]` |
| G80 | Add `import 'dart:convert';` as the first line of the guard test file | `[REQ-DAT-004.10]` |
| G81 | Run `sed -i 's/$/\r/' lib/data/celestrak_element_repository.dart` (CRLF in the repository file) | `[REQ-DAT-004.10]` |
| G82 | Run `printf '\xEF\xBB\xBF' \| cat - lib/data/element_repository_factory.dart > /tmp/g82 && mv /tmp/g82 lib/data/element_repository_factory.dart` (BOM in the factory file) | `[REQ-DAT-004.10]` |
| G83 | Run `sed -i 's/$/\r/' specs/req-dat-004.md` (CRLF in the spec file) | `[REQ-DAT-004.10]` |
| G84 | Run `sed -i 's/$/\r/' specs/req-dat-002.md` (CRLF in the amended spec file) | `[REQ-DAT-004.10]` |
| G85 | Delete the file `test/data/element_repository_factory_test.dart` | `[REQ-DAT-004.10]` |
| G86 | Delete the file `test/domain/celestrak_tle_snapshot.dart` | `[REQ-DAT-004.10]` |
| G87 | Delete the file `specs/req-dat-004.md` | `[REQ-DAT-004.10]` |
| G88 | Run `rm -rf lib/presentation` | `[REQ-DAT-004.10]` |
| G89 | Append the line `// Directory.systemTemp` to the factory file | `[REQ-DAT-004.7]` |
| G90 | Append the line `// Directory.current` to the factory file | `[REQ-DAT-004.7]` |
| G91 | Append the line `// createTemp('wintek')` to the factory file | `[REQ-DAT-004.7]` |
| G92 | Run `sed -i '/getApplicationSupportDirectory/{/^[[:blank:]]*\/\//!s/^/\/\/ /}' lib/data/element_repository_factory.dart` (every code line that names the function becomes a comment) | `[REQ-DAT-004.7]` |
| G93 | Append the line `// nameLine` to the domain file | `[REQ-DAT-004.7]` |
| G94 | Append the line `// statusCode` to the domain file | `[REQ-DAT-004.7]` |
| G95 | Append the line `// GpFetchSuccess` to the domain file | `[REQ-DAT-004.7]` |
| G96 | Append the line `// Exception` to the domain file | `[REQ-DAT-004.7]` |
| G97 | Delete the line `/// A lookup keeps what it read from the cache only if memory still holds nothing for that object, so it never replaces a newer element set.` from the repository file | `[REQ-DAT-004.7]` |
| G98 | Create the file `lib/state/extra.dart` with the line `import 'package:wintek/data/element_cache.dart';` | `[REQ-DAT-004.8]` |
| G99 | Create the file `lib/state/extra.dart` with the line `import '../data/element_cache.dart';` | `[REQ-DAT-004.8]` |
| G100 | Create the file `lib/presentation/extra.dart` with the line `import 'dart:convert';` | `[REQ-DAT-004.8]` |
| G101 | Append the line `// DateTime.now()` to the factory file | `[REQ-DAT-004.7]` |
| G102 | Append the line `// DateTime.timestamp()` to the factory file | `[REQ-DAT-004.7]` |
| G103 | Append the line `// Stopwatch()` to the factory file | `[REQ-DAT-004.7]` |
| G104 | Append the line `// try {` to the factory file | `[REQ-DAT-004.7]` |
| G105 | Append the line `// catch (e)` to the factory file | `[REQ-DAT-004.7]` |
| G106 | Append the line `// stream.listen(print, onError: print);` to the factory file | `[REQ-DAT-004.7]` |
| G107 | Append the line `// stream.handleError(print);` to the factory file | `[REQ-DAT-004.7]` |
| G108 | Append the line `// runZonedGuarded(body, handler);` to the factory file | `[REQ-DAT-004.7]` |
| G109 | Append the line `// Zone.current` to the factory file | `[REQ-DAT-004.7]` |
| G110 | Append the line `// Timer` to the factory file | `[REQ-DAT-004.7]` |
| G111 | Append the line `// Stream.periodic` to the factory file | `[REQ-DAT-004.7]` |
| G112 | Append the line `// Future<void>.delayed(const Duration(hours: 6), refresh);` to the factory file | `[REQ-DAT-004.7]` |
| G113 | Append the line `// FASat-Charlie is 38011.` to the factory file | `[REQ-DAT-004.7]` |
| G114 | Append the line `// stream.handleError(print);` to the repository file | `[REQ-DAT-004.7]` |
| G115 | Append the line `// Zone.current` to the repository file | `[REQ-DAT-004.7]` |
| G116 | Append the line `// Future<void>.delayed(const Duration(hours: 6), refresh);` to the repository file | `[REQ-DAT-004.7]` |
| G117 | Append the line `// DateTime.timestamp()` to the domain file | `[REQ-DAT-004.7]` |
| G118 | Append the line `// Stopwatch()` to the domain file | `[REQ-DAT-004.7]` |
| G119 | Append the line `// file.existsSync()` to the domain file | `[REQ-DAT-004.7]` |
| G120 | Append the line `// Stream.periodic` to the domain file | `[REQ-DAT-004.7]` |
| G121 | Append the line `// Future<void>.delayed(const Duration(hours: 6), refresh);` to the domain file | `[REQ-DAT-004.7]` |
| G122 | Delete the line `import 'package:wintek/domain/satellite_catalog.dart';` from the domain file | `[REQ-DAT-004.7]` |
| G123 | Delete the line `import 'package:orbital_core/orbital_core.dart';` from the domain file | `[REQ-DAT-004.7]` |
| G124 | Append the line `// directory.delete();` to the factory file | `[REQ-DAT-004.7]` |
| G125 | Append the line `// directory.list();` to the factory file | `[REQ-DAT-004.7]` |
| G126 | Append the line `// directory.existsSync()` to the factory file | `[REQ-DAT-004.7]` |
| G127 | Append the line `// getDownloadsDirectory` to the factory file | `[REQ-DAT-004.7]` |
| G128 | Append the line `// getLibraryDirectory` to the factory file | `[REQ-DAT-004.7]` |
| G129 | Append the line `// getApplicationCacheDirectory` to the factory file | `[REQ-DAT-004.7]` |
| G130 | Add `import 'package:wintek/data/celestrak_element_repository.dart';` as the first line of the factory unit test file | `[REQ-DAT-004.10]` |
| G131 | Append the line `export 'package:wintek/domain/satellite_catalog.dart';` to the repository unit test file | `[REQ-DAT-004.10]` |
| G132 | Replace every occurrence of `addTearDown(` with `addTearDownX(`, and then every occurrence of `tearDown(` with `tearDownX(`, in the repository unit test file | `[REQ-DAT-004.10]` |
| G133 | Append the line `// Directory.systemTemp.path` to the factory unit test file | `[REQ-DAT-004.10]` |
| G134 | Append the line `// tempDir.parent` to the repository unit test file | `[REQ-DAT-004.10]` |
| G135 | Append the line `// File('/etc/hosts')` to the factory unit test file | `[REQ-DAT-004.10]` |
| G136 | Run `sed -i 's/$/\r/' lib/domain/element_repository.dart` (CRLF in the domain file) | `[REQ-DAT-004.10]` |
| G137 | Run `sed -i 's/$/\r/' test/data/celestrak_element_repository_test.dart` (CRLF in the repository unit test file) | `[REQ-DAT-004.10]` |
| G138 | Run `printf '\xEF\xBB\xBF' \| cat - test/element_repository_guard_test.dart > /tmp/g138 && mv /tmp/g138 test/element_repository_guard_test.dart` (BOM in the guard test file) | `[REQ-DAT-004.10]` |
| G139 | Run `sed -i 's/$/\r/' docs/adr/ADR-0007-principle-10-across-runs.md` (CRLF in the ADR file) | `[REQ-DAT-004.10]` |
| G140 | Delete the file `test/data/celestrak_element_repository_test.dart` | `[REQ-DAT-004.10]` |
| G141 | Delete the file `specs/req-dat-002.md` | `[REQ-DAT-004.10]` |
| G142 | Append the line `// 'REQ-DAT-004.2 '` to the guard test file | `[REQ-DAT-004.10]` |
| G143 | Run `rm -rf lib/domain` | `[REQ-DAT-004.10]` |
| G144 | Replace every occurrence of `- **Status:** Accepted` with `- **Status:** Proposed` in the ADR file | `[REQ-DAT-004.9]` |
| G145 | Insert the line `  - req-dat-004: decides when to call the client, creates and owns its HTTP client, and maps its failures to the data age and the stale-data warning.` directly after the first line that starts with `  - req-dat-004: decides when to call the client` in the amended spec file | `[REQ-DAT-004.9]` |
| G146 | Delete the file `docs/adr/ADR-0007-principle-10-across-runs.md` | `[REQ-DAT-004.10]` |
| G147 | Delete the line that contains `(amended by req-dat-004 on 2026-11-16)` from the amended spec file | `[REQ-DAT-004.9]` |

Inside the table, `\|` is a single pipe. In G61 and G63 the text between double backticks is the text to replace or insert, single backticks included; in G61 the replaced text starts with one space, and the replacement is that one space.

- In G2 to G6, G14 to G19, G39 to G41, G51, G56, G59, G65, G66, G70, G75, G80, G92, G122, G123, G130 to G132 and G143 a file may no longer compile or analyze cleanly. The guard reads text and runs on its own.
- G101 to G113 isolate the tokens of the factory rules "No clock, no exception handled, nothing scheduled" and "No catalog number", and G114 to G121 the tokens that the rows of revision 2 left unisolated in the repository and the domain file. G106 and G107 contain neither `catch` nor `try`, so they isolate `onError` and `handleError`.
- G112, G116 and G121 write a delayed future in the form `Future<void>.delayed`, which contains `delayed` but not `Future.delayed`; they prove that the rule "nothing scheduled" catches it.
- G136 and G139 are expected to report `[REQ-DAT-004.10]`; the doc lines and the title line still match, because a trailing CR is a blank character. G138 leaves the guard test file compilable, because Dart ignores a leading BOM.
- G142 adds a tag of REQ-DAT-004.2 in a form that is not the line `// REQ-DAT-004.2`, which only the rule of REQ-DAT-004.10 on tags of REQ-DAT-004.1 to .6 in the guard test file catches.
- G144 and G147 change one line of a file that this spec only reads, and G141, G143 and G146 remove files; `git checkout -- lib test specs docs` restores them.
- G92 leaves every comment line as it is and turns each code line that contains `getApplicationSupportDirectory` into a comment, so the name survives only in comments; confirm with `git diff` that at least one line changed.
- G93 to G96 isolate the tokens of the rule "A small contract" one by one, and G89 to G91 those of the rule "The application support directory".
- G98 and G99 create a directory outside `lib/presentation`, so only the rule "Outside the data layer" can report them.
- G19 can leave `@override` on members that no longer override anything; that is a warning, not an error, so the guard still runs.
- G25 adds a second `DateTime.now` to the repository file; the rule "Its own clock only" counts exactly one.
- G42 also removes the one required occurrence of `getApplicationSupportDirectory`. G43 to G45 and G127 to G129 isolate the forbidden directory functions one by one; they name each function without parentheses, so the rule "The directory as resolved" (`Directory(`) does not also report them.
- G46 isolates the rule "The directory as resolved": the text `Directory(` there is not part of `getApplicationSupportDirectory(`.
- G63 restores the list of revision 2 of req-dat-002 next to the amendment, which the last rule of REQ-DAT-004.9 forbids.
- G64 also fails the guards of req-dat-001 to req-dat-003, and G86 those of req-dat-001 to req-dat-003; only the tag of this spec is read here. G84 is expected to report `[REQ-DAT-004.10]`: the lines of REQ-DAT-004.9 still match, because a trailing CR is a blank character.

**Positive rows (P).** These prove that the guard accepts what REQ-DAT-004.8 allows, so a guard that kept the stricter rules of revision 2 fails them. For each row, apply the edit, run the G command with the tag `[REQ-DAT-004.8]` and confirm that it prints nothing.

| # | Edit | Tag that must not appear |
| --- | --- | --- |
| P1 | Create the file `lib/domain/extra.dart` with the line `import 'dart:math';` | `[REQ-DAT-004.8]` |
| P2 | Create the file `lib/presentation/extra.dart` with the line `import 'widgets/marker.dart';` | `[REQ-DAT-004.8]` |
| P3 | Create the file `lib/presentation/widgets/extra.dart` with the line `export 'marker.dart';` | `[REQ-DAT-004.8]` |

- P1 to P3 name files that do not exist, so the app may not compile; the guard reads text. The revert command of the G rows also reverts them.

No row removes `import 'support/repo_root.dart';` from the guard test file. That edit stops the file from compiling, so V3 fails without printing any tag; the import line check is kept as a second line of defence.

**Network rows (N).** These check the amended guard of req-dat-002. The command is:

    flutter test --no-pub test/celestrak_gp_client_guard_test.dart 2>&1 | grep -F "[REQ-DAT-002.4]" | grep -F "specs/req-dat-002.md"

**Control run (N0).** With no edit applied, run the N command and confirm that it prints nothing. Then, for each N row, apply the edit, run the N command and confirm that it prints at least one line.

| # | Edit | Tag expected |
| --- | --- | --- |
| N1 | Append the line `// HttpClient` to the factory file | `[REQ-DAT-002.4]` |
| N2 | Append the line `// Data: https://celestrak.org` to the factory file | `[REQ-DAT-002.4]` |
| N3 | Append the line `// Socket` to the factory file | `[REQ-DAT-002.4]` |
| N4 | Append the line `// package:http/io_client.dart` to the factory file | `[REQ-DAT-002.4]` |
| N5 | Add `import 'package:http/io_client.dart';` as the first line of the factory file | `[REQ-DAT-002.4]` |
| N6 | Add `import 'package:http/http.dart';` as the first line of the repository file | `[REQ-DAT-002.4]` |
| N7 | Add `import 'package:http/http.dart' as http;` as the first line of the domain file | `[REQ-DAT-002.4]` |

- N4 and N5 prove that the factory file may contain `package:http/` only on import lines of `package:http/http.dart`. N6 and N7 prove that the amendment opens no other file. In N5 to N7 a file may no longer compile; the guard reads text.
- The G rows of req-dat-002 that edit `lib/main.dart` or the catalog file still report `[REQ-DAT-002.4]` with the amended guard; the pull request checklist records the result of G21 to G26 of req-dat-002, run once again.

**Pull request checklist.** The description of the pull request that implements this spec lists V0–V17, with the hash S and the merge base of V10 and the UTC offset of the machine that ran V1 and M40 at a non-zero offset, M1–M40 with their diffs, G0 and G1–G147 with the diff of G19, P1–P3, N0 and N1–N7, and G21 to G26 of req-dat-002, each with its observed result, and the diff of the GP client guard test file (REQ-DAT-004.9). A pull request without this list is incomplete regardless of its check status. This checklist is the one manual step of this spec: a reviewer reads it, and no command verifies it. The reviewer also confirms three rules that no test can prove: the diff of the GP client guard test file changes only its network-boundary check (REQ-DAT-004.9); a lookup keeps a cache entry only when memory holds nothing for its object (Definitions, lookup); and the contract offers only a lookup and a refresh, the served element set only its tracked object, its `OrbitalElements`, its arrival instant and its data age, and the handle only its repository and its close operation (decision "A small contract"; edge case "An extra public method"). A text guard sees top-level declarations, not members, so these three stay with the reviewer.

**Record of progress.** The checklist is also the record of progress of the implementation that AGENTS.md asks for ("mark its progress"): the implementation changes neither the spec file, except as V10 allows, nor the amended spec file, nor `docs/roadmap.md`. The roadmap checkbox of this row is set by the QA workflow, outside the implementation.

## Edge Cases & Errors

These cases are normative where a requirement above tests them, and informative where marked.

- **First start without network.** No cache file exists and every fetch fails. Every lookup completes with `null`, a refresh completes with failed for all four objects, and no object is attempted again for 6 hours in that run (REQ-DAT-004.3). The app has nothing to propagate until a later refresh succeeds; a new start of the app may try at once. How the screen shows this is req-sta-001 and req-ui-*.
- **Cold start with a cache and no network.** Every lookup serves the cached element set at once, and the refresh completes with failed for the due objects (REQ-DAT-004.1, .3). This is the offline feature of Constitution principle 9.
- **A slow cold start (informative).** With four due objects and a network that times out, a refresh can take up to four times the 20-second timeout of req-dat-002, because the fetches are sequential. A lookup never waits for it.
- **CelesTrak answers 403.** The object counts as failed and is not requested again within 6 hours in that run (REQ-DAT-004.3), as req-dat-002 requires ("req-dat-004 must not call again before its refresh threshold").
- **Many starts in a short time (informative).** The attempt window does not survive a restart, so a user who starts the app repeatedly can cause one request per due object at each start, even while CelesTrak answers 403 or the disk refuses every write. A success that is written ends this, because the cached element set is then fresh. A persistent record of attempts would be a payload that Constitution principle 11 does not allow; it is out of scope. ADR-0007 records this reading of principle 10 and accepts the consequence: every such request follows an act of the user.
- **A decayed or unknown object.** CelesTrak answers `No GP data found`. The outcome is failed, the cached element set, if any, stays the one served, and its data age grows until req-ui-004 warns (req-dat-002, edge case "Object decayed or unknown").
- **The device clock moved forward.** Every arrival instant looks old, so every object is due once; the attempt windows then hold for 6 hours of the new clock.
- **The device clock moved back (informative).** An arrival instant in the future counts as due (REQ-DAT-004.2), and its data age is unknown until the clock passes it (REQ-DAT-004.5), so req-ui-004 shows it as stale rather than as fresh. If the refresh that it triggers fails, the element set stays served with an unknown data age. An attempt window whose start is now in the future is closed, by the definition of an attempt window, so an object can be attempted again; the new attempt opens a window at the new clock. Neither case can make the repository poll, because only a refresh sends a request.
- **The cache deleted while the app runs.** Lookups keep serving memory (REQ-DAT-004.1, kept in memory), and the next success writes the cache again (Constitution principle 11).
- **A cache write that fails.** The success is served from memory and the outcome is refreshed (REQ-DAT-004.3). After a restart, the cache still holds the older element set, which is then due again.
- **A lookup and a refresh of the same object at once.** A refresh may write the cache file of an object while a lookup reads it. On Android the read keeps the old document; on Windows the write may complete with `false` (req-dat-003, edge case "A read and a write of the same object"), and the success is still served from memory. Neither changes an outcome. A lookup whose read completes after the refresh kept its success in memory does not replace it (Definitions, lookup); otherwise the older entry would be served, and the attempt window would keep it for 6 hours. The timing of this race depends on the file system, so no test produces it; the doc line of REQ-DAT-004.7 and the reviewer cover it.
- **A refresh asked for during a refresh.** It joins the running refresh and completes with its outcomes (REQ-DAT-004.4), so no object is ever fetched or written twice at once.
- **A refresh asked for after the handle was closed (informative).** The HTTP client is closed, so a fetch fails and the due objects complete with failed. req-sta-001 never refreshes through a closed handle.
- **A refresh still running when the handle is closed (informative).** The fetch in flight fails or completes, and the refresh completes with the outcomes it reached. No timer or callback outlives the refresh.
- **The handle opened twice (informative).** Two open handles give two repositories on the same directory. Their joins and attempt windows are separate, so they could fetch the same object twice and write its cache file twice at once, which req-dat-003 forbids ("Concurrent writes of the same object"). req-sta-001 therefore opens exactly one handle per run and never a second while one is open (Blocks); the opener keeps no global state to enforce it. A hot restart during development resets the state of the app and is not a second open in the same run.
- **The directory resolver fails.** On Android `getApplicationSupportDirectory` resolves the internal files directory and does not fail. If a resolver fails, its error propagates out of the open operation, and no HTTP client has been created (REQ-DAT-004.6), so nothing needs closing.
- **The application support directory does not exist yet (informative).** The cache creates its directory at the first write (req-dat-003), so the opener never creates it.
- **Other files in the application support directory (informative).** Other plugins or a later settings file may store files there. The cache ignores every file that is not its own (req-dat-003, edge case "Other files in the cache directory").
- **The same element lines again (informative).** CelesTrak may serve the same element set as before, with the same epoch. The success is still a success: it is written, its arrival instant is new, and the data age restarts. The data age is the age of the download, not of the element set (req-dat-003); showing the epoch is out of scope.
- **A programming error.** The repository handles no exception (REQ-DAT-004.7), so a Dart `Error` or an unexpected exception propagates out of a lookup or a refresh, and is never reported as an outcome. `OrbitalElements.fromTle` cannot throw on the lines of a success or an entry, because both were already accepted by it (req-dat-002, req-dat-003).
- **An extra public method (informative).** The public-surface rules count top-level declarations, not members. The rule "A small contract" of REQ-DAT-004.7 keeps failures, status codes and the name line out of the domain library file; any other public method added to the contract, the repository or the handle is not seen by the guard, and the reviewer checks the types against the decision "A small contract".
- **A presentation layer that does not exist yet.** `lib/presentation` holds only `.gitkeep` when this spec is implemented, so the presentation rule of REQ-DAT-004.8 holds with no file; rows G55 to G59 and G100 prove that it is checked. A missing directory fails the guard (REQ-DAT-004.10).
- **Time zone of the runner.** No instant of this spec is a local instant except N0 converted to local time in REQ-DAT-004.5, whose data age is the same at every offset, so the tests pass at every offset. At offset zero, such as on the CI runner, that case cannot catch an age computed from calendar fields, so V1 and M40 also run at a non-zero offset, recorded in the pull request checklist (Local checks).
- **The system clock of the runner (informative).** The tests never read it. M27 needs it to be later than N0 + 6 hours, which holds for every run after the drafting of this spec.
- **Network or CI failure while verifying.** No check of this spec uses CelesTrak, calls `path_provider` or builds an APK. A failed `flutter pub get`, a timeout, a runner out of memory or a failed analysis is handled as req-inf-002 defines and never counts as a pass. An M, G or N row whose output shows a compilation or resolution error of the file it targets, instead of the expected tag, counts as not run, never as a pass, except where the notes of a table allow it.
- **The spec merged without its implementation (informative).** From the merge of this spec until its implementation, `specs/req-dat-002.md` allows a factory library file that does not exist yet, and the guard of req-dat-002 still forbids `package:http/` in it. The guard is stricter than the amended text, so no file breaks either; V9 of req-dat-002 states when its output changes. If the implementation is abandoned, a revision of this spec removes the amendment and ADR-0007 is marked superseded.
- **Repository root not found.** The guard test file uses `findRepoRoot` from `test/support/repo_root.dart`, which fails with `Cannot resolve the repository root`. It never skips.
- **Shell.** The commands need a POSIX shell with GNU `sed`. In PowerShell they fail with "command not found"; that is an environment error, never a pass. In Git Bash on Windows, set `MSYS_NO_PATHCONV=1` when scripting edits whose arguments start with `/`, and confirm with `git diff` that each edit applied before reading its result.

## Out of Scope

Nothing below is written in the implementation:

- Any Riverpod provider, widget or screen, and any change to `lib/main.dart` (req-sta-001, req-ui-*). The app makes its first live request once req-sta-001 opens the handle and asks for a refresh.
- Deciding when to ask for a refresh: at start, on return to the foreground, on a user gesture or otherwise (req-sta-001).
- The age limit of stale data, any stale flag, and the stale-data warning (req-ui-004); showing the data age (req-ui-003).
- Any timer, periodic refresh, retry, backoff, connectivity check or listener of network changes.
- Any persistent record of attempts, failures or refreshes, and any file other than the cache files of req-dat-003.
- Keeping or exposing the last failure of an object, its kind or its status code, and exposing the name line.
- The epoch of an element set as an age, and any comparison of a new element set with the served one.
- Any lookup from a catalog number to a tracked object (req-dat-001, REQ-DAT-001.4).
- Propagation, the simulation clock and any per-frame state (req-tim-001, req-sta-001).
- Any change to `lib/data/celestrak_gp_client.dart`, `lib/data/element_cache.dart`, `lib/domain/satellite_catalog.dart`, the snapshot data file, or the tests and guards of req-dat-001 to req-dat-003, except the network-boundary check of the GP client guard test file that REQ-DAT-004.9 requires.
- Any change to `packages/orbital_core`, its tests or its guards.
- Any change to either `pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yml`, `test/support/repo_root.dart`, `test/dependency_guard_test.dart`, any Android manifest, any ADR or the constitution.
- A new ADR, or any change to ADR-0007, in the implementation. ADR-0007 lands with this spec.
- Any read or write outside a temporary directory from a test, any call of `path_provider` from a test, and any request to CelesTrak.
- Any change to `specs/req-dat-004.md` in the implementation, except a behaviour change approved by the developer (REQ-DAT-004.10, V10), and any change to `specs/req-dat-002.md` in the implementation. The amendments of REQ-DAT-004.9 and ADR-0007 are made by the pull request that brings this spec into `main`.
- Any change to `docs/roadmap.md`. Its checkbox for this row is updated by the spec workflow (QA validation), outside the implementation.

## Open Questions

None. Every decision of this revision was approved by the developer before drafting (Status). ADR-0007 is proposed with this revision; the developer accepts it before this spec merges into `main`, and REQ-DAT-004.9 then requires its Status line to start with `- **Status:** Accepted`.
