# ADR-0004 — Derived reference values for the linear mean anomaly and the elapsed time

- **Status:** Accepted (2026-10-28, by the developer, before `specs/req-orb-004.md` was implemented) for decisions 1 to 4. Amendment 1 (decisions 5 to 8): Accepted (2026-11-01, by the developer, before `specs/req-orb-004.md` was implemented).
- **Date:** 2026-10-28; Amendment 1 on 2026-11-01
- **Relates to:** Constitution principle 6 (math is proven, not trusted); `specs/req-orb-004.md`, REQ-ORB-004.1 and REQ-ORB-004.2; roadmap row 6 (req-orb-004)

## Context

Constitution principle 6 requires every new or changed formula to ship with a test against a published reference value, cited in the test.

req-orb-004 adds the mean anomaly at an instant, M(t) = M₀ + n · (t − t₀): step 2 of the Project Brief's pipeline, linear and without perturbations. The QA audit of req-orb-004 found that no free published source gives a numeric value of this formula:

- The CelesTrak repository of Vallado's textbook code (`https://github.com/CelesTrak/fundamentals-of-astrodynamics`) uses the formula. In `software/python/src/valladopy/astro/twobody/kepler.py`, commit `c05278b458e806775c91d1fe74b5ff6e583c8d82`, line 217 reads `m += mdot * dtsec + ndot * dtsec**2 + nddot * dtsec**3`, which is the linear formula when the derivative terms are zero. But its tests only publish final positions and velocities, never the advanced mean anomaly.
- The printed textbooks (Vallado, Curtis) give worked examples, but they cannot be checked free of charge, which req-orb-004 forbids as a source.

Without an exception, principle 6 cannot be met for this formula. Yet it is a definition: it has no constant of its own, and its only inputs are published fields of published element sets. A row derived from those fields checks the implementation against an independent derivation, as long as the derivation does not follow the implementation's own path.

## Decision

1. **Bounded exception.** The test of the linear mean anomaly (REQ-ORB-004.2) may use reference values derived from published inputs instead of published outputs. Decisions 1 to 4 cover this one formula; Amendment 1 adds the elapsed time of REQ-ORB-004.1 under its own conditions, and no other formula.
2. **Conditions.** Each derived row must:
   - start from fields published in a cited source: the element sets 00005 and 28129 of Vallado's `SGP4-VER.TLE` (AIAA 2006-6753), as already cited by req-orb-003;
   - be derived in the spec through a different unit path from the implementation's: degrees and revolutions per day, written out in full in the row, while the implementation works in radians and radians per second;
   - be marked "Derived" in the spec.
3. **Formula source.** The math test file cites the pinned line of the Vallado repository above as the published source of the formula, together with this ADR.
4. **Anchor row.** At least one row is not derived: at the epoch, the result must equal the published mean anomaly of the element set exactly.

## Amendment 1 — Elapsed time between two-part Julian dates

### Context

The second QA audit of req-orb-004 (finding 2.1) found the same gap in REQ-ORB-004.1. The elapsed time from A to B, ((day part of B − day part of A) + (fraction part of B − fraction part of A)) · 86400, is a new formula, and no free published source gives a numeric value of it in seconds:

- Meeus (*Astronomical Algorithms*, 2nd ed., chapter 7, as cited by req-orb-001) publishes Julian dates, not elapsed times in seconds between them.
- The day parts at the ends of the valid range are fixed by REQ-ORB-001.4 by calendar arithmetic, and the microsecond fraction comes from req-orb-001's definition of the fraction part; neither is a published output.

Decision 1 limited the exception to the mean anomaly, so without this amendment principle 6 cannot be met for the elapsed time. Like the mean anomaly, the elapsed time is a definition: its only constant is 86 400 s per day, which req-orb-001 already fixes in its definition of the fraction part, and the formula is that definition read backwards.

### Decision

5. **Extension.** The test of the elapsed time (REQ-ORB-004.1) may use reference values derived from published or already fixed inputs instead of published outputs.
6. **Conditions.** Each derived row must:
   - start from Julian dates published by Meeus, chapter 7, as already cited by req-orb-001, or from the day parts and the fraction-part definition that req-orb-001 fixes;
   - be derived in the spec through a different path from the implementation's: the whole days between the two dates and the difference of their clock times, written out in full in the row and multiplied by 86 400 s per day, while the implementation subtracts two-part Julian dates;
   - be marked "Derived" in the spec.
7. **Formula source.** The math test file cites the Meeus Julian dates it uses, together with this ADR, in the Meeus citation line of REQ-ORB-004.7.
8. **Anchor row.** No elapsed time is published, so the anchor is a row that depends on no derivation: two equal dates give exactly 0.0 s.

## Consequences

- req-orb-004 can be implemented once this ADR, including Amendment 1, is accepted, with no other change to the Constitution.
- Any other formula that has no published reference value needs its own ADR; this exception does not generalize beyond the linear mean anomaly and the elapsed time of req-orb-004.
- If a free published numeric example of the linear mean anomaly or of the elapsed time is found later, the spec may add it as a row. Then the matching part of this ADR can be superseded.
- Derived rows check the arithmetic and the unit conversions against an independent derivation. They do not check the model, which the Project Brief fixes.
- The file name keeps its original slug so that existing links stay valid; the title names both formulas.

## Out of scope

- The perturbed mean anomaly using ṅ/2 and n̈/6 (req-orb-010).
- Any reference value for the Kepler equation solver itself, which is published (req-orb-004, REQ-ORB-004.3).
- Any time-scale correction (DUT1, ΔT, leap seconds) in the elapsed time, which req-orb-001 excludes.
