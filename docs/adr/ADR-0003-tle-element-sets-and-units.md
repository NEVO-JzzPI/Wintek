# ADR-0003 — TLE element sets and their units

- **Status:** Proposed (accepted when the developer approves it, before the req-orb-003 implementation merges)
- **Date:** 2026-10-26
- **Relates to:** Constitution principles 1 (one stack, no new data sources), 6 (math is proven), 12 (English and explicit units); `specs/req-orb-003.md`; roadmap rows 5 (req-orb-003), 10 (req-orb-010) and 14 (req-dat-002)

## Context

Every propagator in Wintek reads one element set per object. The Project Brief leaves the CelesTrak format open ("JSON (OMM) o TLE"), while roadmap row 5 names a TLE parser. Whatever the core reads, the data layer (req-dat-002) must download, so the choice has to be fixed once, before either spec is implemented.

Constitution principle 12 requires km, seconds and radians internally. Two values in a TLE do not fit that rule cleanly:

- **B\*** is published in inverse Earth radii. SGP4 consumes it in exactly that unit. Converting it to inverse kilometres requires an Earth radius, and the radius SGP4 uses (WGS-72, 6378.135 km in Vallado's reference code) is a gravity-model constant that belongs to the SGP4 adapter (req-orb-010), not to the element model. Converting here and back in the adapter would add a constant to the wrong spec and a round trip with no benefit.
- **ṅ/2 and n̈/6** are published as halved and sixth-divided derivatives of mean motion. Vallado's SGP4 reader (`twoline2rv`, AIAA 2006-6753) stores them in that form, converted to SGP4 units.

## Decision

1. **Input format.** `packages/orbital_core` reads NORAD Two-Line Element sets: exactly two lines, as defined by CelesTrak's "NORAD Two-Line Element Set Format". OMM in JSON or XML is not read by the core. The four tracked objects (ISS 25544, Tiangong 48274, FASat-Charlie 38011 and GOES-East) have five-digit catalog numbers, which TLE expresses without the Alpha-5 scheme.
2. **B\* unit exception.** B\* is stored as published, in inverse Earth radii. This is a bounded exception to principle 12 that covers this one value only. Its name must state the unit, as principle 12 requires when a unit is ambiguous.
3. **Mean-motion terms.** ṅ/2 and n̈/6 are stored as the published values, converted to radians per second squared and radians per second cubed. They are not multiplied back to ṅ and n̈.

Every other value of the element set follows principle 12 without exception: angles in radians, mean motion in radians per second, epoch as a UTC instant.

## Consequences

- req-dat-002 downloads CelesTrak GP data in TLE format and removes the name line before handing the two element lines to the parser.
- req-orb-010 owns the Earth radius and any other gravity-model constant; the element model carries none.
- Catalog numbers above 99999 (Alpha-5) are not supported. Supporting them, or moving to OMM, requires a new ADR that supersedes decision 1.
- Any further unit exception requires its own ADR; this one does not generalize.
- `specs/req-orb-002.md` mentions a possible ADR-0003 for the GMST model. That number is now taken; a GMST ADR, if one is ever written, takes the next free number.

## Out of scope

- The choice of SGP4 library (ADR-0002).
- The download policy, cache layout and refresh threshold (req-dat-002 to req-dat-004).
