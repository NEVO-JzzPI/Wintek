# ADR-0006 — Validation of composed propagators by identity and invariants

- **Status:** Accepted (2026-11-08, by the developer, with revision 2 of `specs/req-orb-009.md`, before it was implemented)
- **Date:** 2026-11-08
- **Relates to:** Constitution principle 6 (math is proven, not trusted); `specs/req-orb-009.md`, REQ-ORB-009.1, REQ-ORB-009.2, REQ-ORB-009.5 and REQ-ORB-009.6; roadmap row 11 (req-orb-009); ADR-0004 and ADR-0005 (exceptions for single formulas, which do not generalize)

## Context

Constitution principle 6 requires every new or changed formula to ship with a test against a published reference value, cited in the test.

req-orb-009 adds the in-house Kepler propagator. It adds no formula: it composes `meanAnomalyAtRad` and `eccentricAnomalyRad` (req-orb-004), `semiMajorAxisKmFromMeanMotion` and `inertialStateVector` (req-orb-005), `JulianDate.fromUtc` (req-orb-001), `gmstRad` (req-orb-002) and `ecefPositionKm` (req-orb-006), each already validated against published values in its own spec. No published source gives a two-body propagation from a TLE to a position, so the composition as a whole has no published reference value.

ADR-0005 states that "any other formula that has no published reference value needs its own ADR; this exception does not generalize". Whether a composition with no arithmetic of its own counts as a formula is a matter of interpretation. This ADR removes the interpretation: it fixes how such a composition is validated.

## Decision

1. **Scope.** This decision covers code that only composes functions already validated against published values in their own specs, and adds no arithmetic, no literal number and no constant of its own. Today it covers the Kepler propagator of req-orb-009 and nothing else.
2. **Identity.** Each field of the composed result is compared exactly (`==`) with the result of the function it composes, called with the same inputs in the test, over a fixed grid of inputs from cited element sets.
3. **Invariants.** The composition is also checked by invariants that a wrong wiring breaks: the published mean anomaly at the epoch, the return to the same state after whole periods, and a geostationary orbit that hardly moves in Earth-fixed axes while it moves through tens of thousands of kilometres in inertial ones. Their bounds come from geometry and measurement, are written in the spec with the measured values, and are not reference values.
4. **Guard.** A guard test proves by text that the composing file imports no `dart:math` and no package, holds no digit, no arithmetic operator and no member beyond its input, and calls every composed function.
5. **Inputs.** Published element sets are cited in the test with their source. A synthetic element set may be used for an invariant only, and is cited as synthetic, not as a published object.

## Consequences

- req-orb-009 can be implemented without a published end-to-end value, with no other change to the Constitution.
- Identity proves the wiring and the invariants catch a wiring that identity shares with the test. Neither checks that two-body propagation of mean TLE elements matches a reference propagation; that weakness is accepted and recorded here. The Kepler versus SGP4 comparison of phase 2 (Project Brief) is where it would be measured.
- Any code that adds a formula, a literal constant or arithmetic of its own falls outside decision 1 and needs a published reference value or its own ADR.

## Out of scope

- The SGP4 adapter of req-orb-010, which must reproduce the official SGP4 test vectors (ADR-0001, Out of scope) and is not validated by this decision.
- Any change to the formulas of req-orb-001 to req-orb-008, or to ADR-0004 and ADR-0005.
