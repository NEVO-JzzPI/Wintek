# ADR-0007 — Reading of Constitution principle 10 across runs of the app

- **Status:** Proposed (2026-11-16), with revision 3 of `specs/req-dat-004.md`. The developer accepts it before that spec merges into `main`; the guard of req-dat-004 then requires this line to start with `- **Status:** Accepted`.
- **Date:** 2026-11-16
- **Relates to:** Constitution principles 10 (be a good CelesTrak citizen) and 11 (cached data is replaceable, not precious); `specs/req-dat-004.md`, REQ-DAT-004.1 to REQ-DAT-004.3; `specs/req-dat-002.md`, edge case "CelesTrak blocks the client"

## Context

Constitution principle 10 asks for "at most one fetch per dataset every few hours, never polling", and says that "the last good response is persisted locally and is the only source of orbital elements". Principle 11 allows on disk only CelesTrak payloads and user settings.

req-dat-004 opens a 6-hour attempt window per object after every attempt, successful or failed. A record of attempts is neither a CelesTrak payload nor a setting, so principle 11 keeps the window in memory, and a new start of the app begins with no window. Two consequences follow, and neither is settled by the text of the two principles:

- a user who starts the app again and again, while CelesTrak answers with a failure such as status 403 or while the disk refuses every write, causes one request per due dataset at each start;
- a success whose cache write fails is served from memory, although it is not the persisted last good response.

The second QA audit of req-dat-004 found that the spec resolved both by its own reading of principle 10, with no ADR. The Constitution requires an ADR for that reading.

## Decision

1. **Per run.** The limit of principle 10 holds within one run of the app: the repository of req-dat-004 sends at most one request per dataset in any 6 hours of the same run. A start of the app is the user's act, never polling, and may send one request per due dataset.
   - **Measured on the device clock.** Those 6 hours, like the refresh threshold and the data age, are hours of the wall clock that the repository reads, which is the clock of the device. A jump of that clock can shorten them once per jump: a clock moved forward makes every window and every element set look older, and a clock moved back closes every window whose start is now later than the clock. Each such request still follows a refresh that the app asked for, never a timer, so it is not polling. A monotonic clock is not used, because the attempt window must agree with the arrival instants, which are wall-clock instants.
2. **A success bounds every later run.** A success that is written to the cache makes its dataset not due for 6 hours from its arrival instant, in this run and in every later one. Only a dataset without a fresh cached element set (first start, a failure, or a failed write) can be requested again at a new start.
3. **Memory serves only what CelesTrak sent.** "The only source of orbital elements" means that every element set served comes from a CelesTrak response; the persisted last good response is the only source that survives a restart. A response received in the current run may be served from memory when its cache write fails.
4. **No persistent record of attempts.** No attempt, failure or refresh instant is written to disk. Principle 11 is unchanged.

## Consequences

- req-dat-004 keeps its attempt window in memory and needs no new file, no setting and no change to principle 11.
- Repeated starts while CelesTrak refuses the app, or while the disk refuses writes, can cause more than one request per dataset in a few hours. This is accepted: every such request follows an act of the user, and none is automatic. If it is observed in use, a later ADR may persist an attempt record, which would change principle 11.
- A jump of the device clock can let one more request per dataset through within 6 real hours, once per jump (decision 1). This is accepted for the same reason: the request follows a refresh that the app asked for.
- The text of principles 10 and 11 stays as it is; this ADR is how they are read.

## Out of scope

- A persistent record of attempts, failures or refreshes, and any file other than the cache files of req-dat-003.
- Any change to the text of the Constitution.
- When the app asks for a refresh (req-sta-001).
