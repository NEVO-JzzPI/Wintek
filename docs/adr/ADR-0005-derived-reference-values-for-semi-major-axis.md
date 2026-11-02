# ADR-0005 — Derived reference values for the semi-major axis from mean motion

- **Status:** Proposed (2026-11-01), pending acceptance by the developer before `specs/req-orb-005.md` is implemented
- **Date:** 2026-11-01
- **Relates to:** Constitution principle 6 (math is proven, not trusted); `specs/req-orb-005.md`, REQ-ORB-005.1; roadmap row 7 (req-orb-005); ADR-0004 (the same kind of exception for two other formulas)

## Context

Constitution principle 6 requires every new or changed formula to ship with a test against a published reference value, cited in the test.

req-orb-005 adds the semi-major axis derived from the mean motion, a = (μ / n²)^(1/3) with μ = 398600.4418 km³/s², exactly as step 4 of the Project Brief fixes it. While drafting req-orb-005, no free published source was found that gives a numeric value of this formula:

- The CelesTrak repository of Vallado's textbook code (`https://github.com/CelesTrak/fundamentals-of-astrodynamics`, commit `49df0479c950917c0a2c5ac31f2db6477bba57f6`) publishes semi-major axes only as outputs of `rv2coe`, computed from position and velocity, never from a mean motion.
- T.S. Kelso's column "Basics of the Geostationary Orbit" (CelesTrak, *Satellite Times*, May 1998) gives the sidereal period and an altitude of roughly 35 786 km, but neither μ nor a computed semi-major axis.
- The printed textbooks (Vallado, Curtis) give worked examples, but they cannot be checked free of charge, which req-orb-005 forbids as a source.

ADR-0004 solved the same gap for the linear mean anomaly and the elapsed time of req-orb-004, but states that its exception does not generalize to any other formula. This formula therefore needs its own ADR.

The formula is Kepler's third law solved for a. It has one constant, μ, which the Project Brief fixes, and its only input is the published mean motion of a published element set. A row derived from that input checks the implementation against an independent derivation, as long as the derivation does not follow the implementation's own path.

## Decision

1. **Bounded exception.** The test of the semi-major axis from mean motion (REQ-ORB-005.1) may use reference values derived from published inputs instead of published outputs. The exception covers this one formula only.
2. **Conditions.** Each derived row must:
   - start from the mean motion published in a cited source: the element sets 00005 and 28129 of Vallado's `SGP4-VER.TLE` (AIAA 2006-6753), as already cited by req-orb-003 and req-orb-004;
   - be derived in the spec through a different path from the implementation's: the orbital period T = 86400 / n in seconds, from n in revolutions per day, and a = (μ · T² / (4π²))^(1/3), written out in full in the row, while the implementation takes n in radians per second;
   - be marked "Derived" in the spec.
3. **Constant.** The math test file writes μ as the literal 398600.4418 for the derivation and never reads it from the implementation, so a wrong constant in the implementation fails the rows.
4. **No anchor row.** No published value of this formula exists, so no row can be anchored to a published output. The published state vector of REQ-ORB-005.2 does not take a mean motion as input and cannot serve as an anchor. This weakness is accepted and recorded here.

## Consequences

- req-orb-005 can be implemented once this ADR is accepted, with no other change to the Constitution.
- Any other formula that has no published reference value needs its own ADR; this exception does not generalize.
- If a free published numeric example of the semi-major axis from mean motion is found later, the spec may add it as a row. Then this ADR can be superseded.
- Derived rows check the arithmetic, the constant and the unit conversions against an independent derivation. They do not check the model, which the Project Brief fixes.
- The mean motion is the Kozai mean motion of the element set, used as is (`specs/req-orb-005.md`, Context). The derived rows inherit that choice and do not check it.

## Out of scope

- Converting the Kozai mean motion to the Brouwer mean motion, which needs the WGS-72 gravity constants that ADR-0003 assigns to req-orb-010.
- Any reference value for the perifocal position, the perifocal velocity or the rotation to inertial axes, which are published (req-orb-005, REQ-ORB-005.2 and REQ-ORB-005.3).
