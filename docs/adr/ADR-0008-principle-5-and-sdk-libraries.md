# ADR-0008 — Reading of Constitution principle 5 for Dart SDK libraries

- **Status:** Proposed (2026-11-16), with revision 4 of `specs/req-dat-004.md`. The developer accepts it before that spec merges into `main`; the guard of req-dat-004 then requires this line to start with `- **Status:** Accepted`.
- **Date:** 2026-11-16
- **Relates to:** Constitution principles 3 (the math core is pure Dart), 4 (the UI only renders) and 5 (dependencies point inward); ADR-0001 (baseline packages); `specs/req-dat-004.md`, REQ-DAT-004.8

## Context

Constitution principle 5 says that `domain` "depends only on `orbital_core`". Read word for word, a domain library file could not import `dart:math` or `dart:collection`, although those libraries do no I/O, need no platform and add no package to either manifest.

req-dat-004 writes the layer rules that req-dat-001 and req-dat-002 left to it. The developer decided that a domain library file may import the libraries of the Dart SDK that do no I/O and need no platform. The third QA audit of req-dat-004 found that this is a reading of principle 5 that the spec made with no ADR, while the same spec needed ADR-0007 for its reading of principle 10. The Constitution requires an ADR for that reading.

## Decision

1. **Principle 5 limits packages and layers.** "Depends only on `orbital_core`" means that the domain layer depends on no package other than `orbital_core` and on no other layer of the app. It does not limit the libraries of the Dart SDK, which are part of the one stack of principle 1 and of no manifest.
2. **SDK libraries without I/O or platform.** A domain library file may import every `dart:` library except `dart:ffi`, `dart:html`, `dart:io`, `dart:isolate` and `dart:ui`. Those five give access to native code, the browser, the file system and the network, isolates or the Flutter engine, which the domain must not reach.
3. **The domain still imports itself and the core only.** Besides those SDK libraries, a domain library file imports only `package:orbital_core/orbital_core.dart` and other domain library files (`package:wintek/domain/`).
4. **The presentation layer is read strictly.** Principle 4 forbids HTTP and JSON parsing in `presentation`, so a presentation library file imports none of `package:http/`, `package:path_provider/`, `dart:io` and `dart:convert`, and no library file of the data layer. This is stricter than the text of principle 4 and needs no exception; it is recorded here because req-dat-004 checks it together with decision 2.

## Consequences

- A domain value type can use `dart:math` or `dart:collection` without an ADR, and the guard of req-dat-004 accepts it.
- `dart:io` and the other four libraries stay out of the domain, so the domain remains free of I/O as principles 3 and 5 intend.
- The text of principles 4 and 5 stays as it is; this ADR is how they are read.

## Out of scope

- Any new package, in either manifest (ADR-0001).
- `packages/orbital_core`, whose rules are principle 3 and ADR-0001.
- Any change to the text of the Constitution.
