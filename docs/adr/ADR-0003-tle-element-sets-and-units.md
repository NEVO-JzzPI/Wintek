# ADR-0003 — TLE element sets and their units

- **Status:** Accepted (2026-10-28, by the developer, after the implementation had landed in commit aab0c6b; see the Delivery record of `specs/req-orb-003.md`) for decisions 1 to 3. Amendment 1 (decisions 4 to 6): Accepted (2026-11-01, by the developer, before `specs/req-orb-005.md` was implemented). Amendment 2 (decisions 7 to 9): Accepted (2026-11-07, by the developer, before `specs/req-orb-007.md` was implemented).
- **Date:** 2026-10-26; Amendment 1 on 2026-11-01; Amendment 2 on 2026-11-07
- **Relates to:** Constitution principles 1 (one stack, no new data sources), 6 (math is proven), 12 (English and explicit units); `specs/req-orb-003.md`; `specs/req-orb-005.md` (Amendment 1); `specs/req-orb-007.md` (Amendment 2); roadmap rows 5 (req-orb-003), 7 (req-orb-005), 9 (req-orb-007), 12 (req-orb-010) and 14 (req-dat-002)

## Context

Every propagator in Wintek reads one element set per object. The Project Brief leaves the CelesTrak format open ("JSON (OMM) o TLE"), while roadmap row 5 names a TLE parser. Whatever the core reads, the data layer (req-dat-002) must download, so the choice has to be fixed once, before either spec is implemented.

Constitution principle 12 requires km, seconds and radians internally. Two values in a TLE do not fit that rule cleanly:

- **B\*** is published in inverse Earth radii. SGP4 consumes it in exactly that unit. Converting it to inverse kilometres requires an Earth radius, and the radius SGP4 uses (WGS-72, 6378.135 km in Vallado's reference code) is a gravity-model constant that belongs to the SGP4 adapter (req-orb-010), not to the element model. Converting here and back in the adapter would add a constant to the wrong spec and a round trip with no benefit.
- **ṅ/2 and n̈/6** are published as halved and sixth-divided derivatives of mean motion. Vallado's SGP4 reader (`twoline2rv`, AIAA 2006-6753) stores them in that form, converted to SGP4 units.

## Decision

1. **Input format.** `packages/orbital_core` reads NORAD Two-Line Element sets: exactly two lines, as defined by CelesTrak's "NORAD Two-Line Element Set Format". OMM in JSON or XML is not read by the core. ISS (25544), Tiangong (48274) and FASat-Charlie (38011) have five-digit catalog numbers, which TLE expresses without the Alpha-5 scheme. The catalog number of GOES-East is fixed by req-dat-001, which must confirm that it has five digits or propose an ADR that supersedes this decision.
2. **B\* unit exception.** B\* is stored as published, in inverse Earth radii. This is a bounded exception to principle 12 that covers this one value only. Its name must state the unit, as principle 12 requires when a unit is ambiguous.
3. **Mean-motion terms.** ṅ/2 and n̈/6 are stored as the published values, converted to radians per second squared and radians per second cubed. They are not multiplied back to ṅ and n̈.

Every other value of the element set follows principle 12 without exception: angles in radians, mean motion in radians per second, epoch as a UTC instant.

## Consequences

- req-dat-002 downloads CelesTrak GP data in TLE format and removes the name line before handing the two element lines to the parser.
- req-orb-010 owns the Earth radius and any other gravity-model constant of SGP4; the element model carries none. Amendment 1 places the gravitational parameter of the in-house Kepler propagator in req-orb-005.
- Catalog numbers above 99999 (Alpha-5) are not supported. Supporting them, or moving to OMM, requires a new ADR that supersedes decision 1.
- Any further unit exception requires its own ADR; this one does not generalize.
- `specs/req-orb-002.md` mentions a possible ADR-0003 for the GMST model. That number is now taken; a GMST ADR, if one is ever written, takes the next free number.

## Amendment 1 — Gravitational parameter of the Kepler propagator

### Context

The first QA audit of `specs/req-orb-005.md` (finding 2.1) found that the Consequences above, read literally, assign every gravity-model constant to req-orb-010. req-orb-005 needs one such constant before req-orb-010 exists: the gravitational parameter μ of the in-house Kepler propagator, which step 4 of the Project Brief fixes at 398600.4418 km³/s², the WGS-84 value. It is not a constant of SGP4, which uses its own WGS-72 gravity model, and the element model still carries no gravity constant.

### Decision

4. **Scope of the gravity-model rule.** The Consequence "req-orb-010 owns the Earth radius and any other gravity-model constant" covers the gravity model of SGP4 (WGS-72 in Vallado's reference code): its Earth radius, its gravitational parameter, its zonal harmonics and any other constant the SGP4 adapter consumes.
5. **Kepler propagator constant.** The gravitational parameter of the in-house Kepler propagator, 398600.4418 km³/s² as fixed by the Project Brief, is owned by req-orb-005 under a name that states its model (WGS-84). Later specs that need the same value, such as req-orb-008, reuse that constant instead of declaring their own.
6. **Model in the name.** Any gravity-model constant added to `packages/orbital_core` states its model in its name, so that the WGS-84 constant of req-orb-005 and the WGS-72 constants of req-orb-010 cannot be confused.

### Consequences

- req-orb-005 can declare its constant without contradicting this ADR, once Amendment 1 is accepted.
- The core will hold two gravitational parameters once req-orb-010 lands, one per model, each named after its model.
  - **Note (2026-11-08, ADR-0002, decision 6):** superseded. The WGS-72 constants of SGP4 are those of the library, selected by name, so the core holds one gravitational parameter, the WGS-84 one of req-orb-005. Decisions 4 to 6 are unchanged.
- The element model is unchanged: it still carries no gravity constant.

## Amendment 2 — Constants of the WGS-84 ellipsoid

### Context

The first QA audit of `specs/req-orb-007.md` (finding 2.1) found that no decision of this ADR covers the constants of an ellipsoid. req-orb-007 converts the Earth-fixed position to geodetic coordinates on the WGS-84 ellipsoid, as step 8 of the Project Brief fixes, and needs its semi-major axis, 6378.137 km, and its inverse flattening, 298.257223563. Decisions 4 to 6 speak only of gravity-model constants, and the Consequence "req-orb-010 owns the Earth radius", read without decision 4, could be taken to claim this radius for the SGP4 adapter. The globe specs (roadmap rows 21 to 25, req-viz-001 to req-viz-005) will need the same radius, so the owner and the reuse rule have to be fixed before req-orb-007 is implemented.

### Decision

7. **Owner.** The semi-major axis and the inverse flattening of the WGS-84 ellipsoid are owned by req-orb-007, as public constants of `packages/orbital_core`. They describe the shape used for geodetic coordinates. They are not constants of the SGP4 gravity model, so decision 4 does not assign them to req-orb-010. The Earth radius of that model (WGS-72, 6378.135 km in Vallado's reference code) stays with req-orb-010.
8. **Reuse.** A later spec that needs the WGS-84 Earth radius or the shape of the WGS-84 ellipsoid reuses these constants instead of declaring its own. This does not apply to the WGS-72 radius of SGP4 (decision 7). Values derived from them, such as the semi-minor axis, the flattening or the eccentricity, are computed where they are needed, until a spec proves that a public derived constant is needed.
9. **Model in the name.** Decision 6 applies to these constants as well: each states its model in its name, so that the WGS-84 radius and the WGS-72 radius of req-orb-010 cannot be confused.

### Consequences

- req-orb-007 can declare its two constants without contradicting this ADR.
- The core will hold two Earth radii once req-orb-010 lands, one per model, each named after its model.
  - **Note (2026-11-08, ADR-0002, decision 6):** superseded. The WGS-72 radius of SGP4 is that of the library, selected by name, so the core holds one Earth radius, the WGS-84 one of req-orb-007. Decisions 7 to 9 are unchanged.
- A globe spec that draws the Earth at a scale picks the WGS-84 radius by name; using a sphere of that radius instead of the ellipsoid is that spec's decision, not this one.

## Out of scope

- The choice of SGP4 library (ADR-0002).
- The download policy, cache layout and refresh threshold (req-dat-002 to req-dat-004).
