# Wintek — MVP Roadmap

Strict build order: every row is one future `specs/<id>.md` and one pull request. Numbers run per domain; the row order is the dependency order. MVP only — phase 2 (pass prediction, Kepler vs SGP4 comparison) is out of scope.

| Spec ID | Title | Objective |
| --- | --- | --- |
| req-inf-001 | Monorepo scaffold | Create the Flutter app and `packages/orbital_core` with the ADR-0001 dependencies, so both test suites run and principle 3 holds from the first commit. |
| req-inf-002 | CI quality gates | Run format, analyze and both suites on every PR, so every later spec is verified by machine instead of by hand. |
| req-orb-001 | Julian date and UTC time base | Convert UTC instants to Julian date and centuries, the time input every later formula depends on. |
| req-orb-002 | GMST from Julian date | Produce Earth's rotation angle, without which inertial coordinates can never become Earth-fixed ones. |
| req-orb-003 | Orbital elements model and TLE parser | Define the immutable element set in radians and seconds with checksum validation, the single input type of every propagator. |
| req-orb-004 | Kepler equation solver | Advance mean anomaly to time t and solve `M = E - e·sin E` by Newton-Raphson, the heart of the in-house propagator. |
| req-orb-005 | Perifocal to inertial state vector | Derive `a` from `n`, place the object in its orbital plane and rotate it by R₃(−Ω)·R₁(−i)·R₃(−ω) to obtain an inertial position and velocity. |
| req-orb-006 | Inertial to ECEF rotation | Apply GMST to the inertial vector, unblocking every ground-referenced coordinate. |
| req-orb-007 | ECEF to WGS-84 geodetic | Convert the Earth-fixed vector to latitude, longitude and altitude, the numbers the globe and the card display. |
| req-orb-008 | Derived orbital values | Compute altitude, speed by vis-viva, period and inclination, completing the data the object card needs. |
| req-orb-009 | Propagator interface and Kepler implementation | Freeze the one seam every propagator implements, returning a state that already carries M, E, GMST and ECEF so math mode later needs no refactor. |
| req-orb-010 | SGP4 adapter behind the interface | Wrap the library chosen in ADR-0002 and validate it against the official test vectors, delivering the realistic propagation the MVP renders. |
| req-dat-001 | Satellite catalog | Fix the four tracked objects and their NORAD IDs as domain constants, closing the open GOES-East question before any request is written. |
| req-dat-002 | CelesTrak GP client | Fetch OMM/TLE data with one request per dataset and typed failures, the app's only network boundary. |
| req-dat-003 | Local element cache | Persist the last good payload with its fetch timestamp under app storage, so a cold start needs no network and a deleted cache is harmless. |
| req-dat-004 | Element repository and refresh policy | Implement the domain interface that serves the cache, refreshes only past the age threshold and exposes data age — what makes offline a feature instead of an error. |
| req-tim-001 | Simulation clock | Advance a single UTC clock with a `Ticker`, the one time source every propagation reads. |
| req-tim-002 | Time controls | Add pause, ×10, ×100, reverse and back-to-now as a multiplier over that clock, with no change to any propagator. |
| req-sta-001 | Satellite state providers | Join repository elements with the clock into per-frame Riverpod states, the only data the UI is allowed to read. |
| req-ui-001 | Theme tokens | Define the palette and the sans/monospace pairing once, so no painter or widget hardcodes a colour. |
| req-viz-001 | Globe camera and 3D projection | Provide a pure, unit-testable class mapping ECEF to screen with rotation, zoom and back-face culling, the basis of every drawing spec. |
| req-viz-002 | Globe wireframe painter | Draw the precomputed meridian and parallel mesh through the camera, putting the first frame of Earth on screen. |
| req-viz-003 | Coastline overlay | Render simplified coastline geometry precomputed at load, making the wireframe readable as Earth; needs its own licence ADR first. |
| req-viz-004 | Rotate and zoom gestures | Feed drag and pinch into camera state across a zoom range that still reaches GEO at 6.6 Earth radii. |
| req-viz-005 | Satellite markers | Project the four live states with per-object colour and correct in-front/behind ordering — the MVP's core promise on screen. |
| req-ui-002 | Tap selection and hit testing | Resolve a touch to the nearest marker and store the selection, unblocking both the orbit path and the card. |
| req-viz-006 | Orbit path of the selected object | Sample one full period when the selection changes, never per frame, keeping the 8 ms frame budget intact. |
| req-ui-003 | Object card | Show altitude, speed, latitude/longitude, period, inclination and data age in a sliding sheet, widget-tested as the brief requires. |
| req-ui-004 | Stale data warning | Surface a visible banner when cached elements exceed the age limit, so a stale position is never read as current. |
| req-mth-001 | Math mode panel | Stream M, E, GMST and the ECEF vector from the Kepler propagator in UTC and monospace, the feature that proves the math is ours. |
| req-ui-005 | About / The math screen | Collect the formulas, the CelesTrak attribution and the Selk'nam origin of the name in one screen. |
| req-rel-001 | Tagged release pipeline | Build the release APK on tag and publish it to GitHub Releases, so the app is installable straight from the repo. |
| req-rel-002 | Portfolio README | Add the GIF, the install steps and the "The math behind it" section that make the repository legible to a reviewer. |
