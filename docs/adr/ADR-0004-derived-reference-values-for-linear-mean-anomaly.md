# ADR-0004 — Derived reference values for the linear mean anomaly

- **Status:** Accepted (2026-10-28, by the developer, before `specs/req-orb-004.md` was implemented)
- **Date:** 2026-10-28
- **Relates to:** Constitution principle 6 (math is proven, not trusted); `specs/req-orb-004.md`, REQ-ORB-004.2; roadmap row 6 (req-orb-004)

## Context

Constitution principle 6 requires every new or changed formula to ship with a test against a published reference value, cited in the test.

req-orb-004 adds the mean anomaly at an instant, M(t) = M₀ + n · (t − t₀): step 2 of the Project Brief's pipeline, linear and without perturbations. The QA audit of req-orb-004 found that no free published source gives a numeric value of this formula:

- The CelesTrak repository of Vallado's textbook code (`https://github.com/CelesTrak/fundamentals-of-astrodynamics`) uses the formula. In `software/python/src/valladopy/astro/twobody/kepler.py`, commit `c05278b458e806775c91d1fe74b5ff6e583c8d82`, line 217 reads `m += mdot * dtsec + ndot * dtsec**2 + nddot * dtsec**3`, which is the linear formula when the derivative terms are zero. But its tests only publish final positions and velocities, never the advanced mean anomaly.
- The printed textbooks (Vallado, Curtis) give worked examples, but they cannot be checked free of charge, which req-orb-004 forbids as a source.

Without an exception, principle 6 cannot be met for this formula. Yet it is a definition: it has no constant of its own, and its only inputs are published fields of published element sets. A row derived from those fields checks the implementation against an independent derivation, as long as the derivation does not follow the implementation's own path.

## Decision

1. **Bounded exception.** The test of the linear mean anomaly (REQ-ORB-004.2) may use reference values derived from published inputs instead of published outputs. The exception covers this one formula only.
2. **Conditions.** Each derived row must:
   - start from fields published in a cited source: the element sets 00005 and 28129 of Vallado's `SGP4-VER.TLE` (AIAA 2006-6753), as already cited by req-orb-003;
   - be derived in the spec through a different unit path from the implementation's: degrees and revolutions per day, written out in full in the row, while the implementation works in radians and radians per second;
   - be marked "Derived" in the spec.
3. **Formula source.** The math test file cites the pinned line of the Vallado repository above as the published source of the formula, together with this ADR.
4. **Anchor row.** At least one row is not derived: at the epoch, the result must equal the published mean anomaly of the element set exactly.

## Consequences

- req-orb-004 can be implemented once this ADR is accepted, with no other change to the Constitution.
- Any other formula that has no published reference value needs its own ADR; this exception does not generalize.
- If a free published numeric example of the linear mean anomaly is found later, the spec may add it as a row. Then this ADR can be superseded.
- Derived rows check the arithmetic and the unit conversions against an independent derivation. They do not check the model, which the Project Brief fixes.

## Out of scope

- The perturbed mean anomaly using ṅ/2 and n̈/6 (req-orb-010).
- Any reference value for the Kepler equation solver itself, which is published (req-orb-004, REQ-ORB-004.3).
