# ADR-0008 — Reading of Constitution principle 5 for Dart SDK libraries

- **Status:** Accepted (2026-11-16, by the developer, with revision 6 of `specs/req-dat-004.md`, before it was implemented). Proposed with revision 4 of that spec and amended with revision 6; the guard of req-dat-004 requires this line to start with `- **Status:** Accepted`.
- **Date:** 2026-11-16
- **Relates to:** Constitution principles 3 (the math core is pure Dart), 4 (the UI only renders) and 5 (dependencies point inward); ADR-0001 (baseline packages); `specs/req-dat-004.md`, REQ-DAT-004.8

## Context

Constitution principle 5 says that `domain` "depends only on `orbital_core`". Read word for word, a domain library file could not import `dart:math` or `dart:collection`, although those libraries do no I/O, need no platform and add no package to either manifest.

req-dat-004 writes the layer rules that req-dat-001 and req-dat-002 left to it. The developer decided that a domain library file may import the libraries of the Dart SDK that do no I/O and need no platform. The third QA audit of req-dat-004 found that this is a reading of principle 5 that the spec made with no ADR, while the same spec needed ADR-0007 for its reading of principle 10. The Constitution requires an ADR for that reading.

## Decision

1. **Principle 5 limits packages and layers.** "Depends only on `orbital_core`" means that the domain layer depends on no package other than `orbital_core` and on no other layer of the app. It does not limit the libraries of the Dart SDK, which are part of the one stack of principle 1 and of no manifest.
2. **SDK libraries without I/O or platform.** A domain library file may import every `dart:` library except these, which do I/O, need a platform or are internal:
   - I/O: `dart:cli`, `dart:developer` (whose `Service` starts a web server) and `dart:io`;
   - native code and isolates: `dart:ffi` and `dart:isolate`;
   - the browser: `dart:html`, `dart:indexed_db`, `dart:js`, `dart:js_interop`, `dart:js_interop_unsafe`, `dart:js_util`, `dart:svg`, `dart:web_audio` and `dart:web_gl`;
   - reflection, which Flutter does not support: `dart:mirrors`;
   - the Flutter engine: `dart:ui` and `dart:ui_web`;
   - every internal library, whose URI starts with `dart:_`.

   In the current SDK this leaves `dart:async`, `dart:collection`, `dart:convert`, `dart:core`, `dart:math` and `dart:typed_data`. A library that a later SDK adds is reviewed against this criterion, and a revision of this ADR and of req-dat-004 adds it to the list above when it does I/O or needs a platform.
3. **The domain still imports itself and the core only.** Besides those SDK libraries, a domain library file imports only `package:orbital_core/orbital_core.dart` and other domain library files (`package:wintek/domain/`).
4. **The presentation layer is read strictly.** Principle 4 forbids HTTP and JSON parsing in `presentation`, so a presentation library file imports none of `package:http/`, `package:path_provider/`, `dart:io` and `dart:convert`, and no library file of the data layer. This is stricter than the text of principle 4 and needs no exception; it is recorded here because req-dat-004 checks it together with decision 2.

## Consequences

- A domain value type can use `dart:math` or `dart:collection` without an ADR, and the guard of req-dat-004 accepts it.
- `dart:io` and the other libraries of decision 2 stay out of the domain, so the domain remains free of I/O and of any platform as principles 3 and 5 intend.
- The text of principles 4 and 5 stays as it is; this ADR is how they are read.

## Out of scope

- Any new package, in either manifest (ADR-0001).
- `packages/orbital_core`, whose rules are principle 3 and ADR-0001.
- Any change to the text of the Constitution.
