/// The four objects that Wintek tracks, in display order (specs/req-dat-001.md).
///
/// NORAD ID: the catalog number from 1 to 99999 that OrbitalElements.catalogNumber reads from a TLE, where it has five digits (ADR-0003, decision 1).
/// Source: CelesTrak SATCAT, checked on 2026-11-10: ISS (ZARYA), CSS (TIANHE), SSOT and GOES 19.
/// GOES-East is a role, filled by GOES 19 (2024-119A) since 2025-04-07; a change of satellite is a change of specs/req-dat-001.md, never a runtime lookup.
enum TrackedObject {
  iss('ISS', 25544),
  tiangong('Tiangong', 48274),
  fasatCharlie('FASat-Charlie', 38011),
  goesEast('GOES-East', 60133);

  const TrackedObject(this.displayName, this.noradId);

  final String displayName;
  final int noradId;
}
