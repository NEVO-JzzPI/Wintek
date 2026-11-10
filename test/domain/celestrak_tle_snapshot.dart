// Identity snapshot of the four tracked objects, copied from specs/req-dat-001.md.
// Source: CelesTrak GP data, https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, one request per object (specs/req-dat-001.md).
// Fetched: 2026-11-10, once per object while drafting specs/req-dat-001.md; no test fetches it again.
// Identity snapshot: its epochs and elements are not reference values for any formula (Constitution principle 6).
// Each object has three strings, in catalog order: its name line without trailing spaces, then TLE lines 1 and 2.

const List<String> celestrakTleSnapshot = [
  'ISS (ZARYA)',
  '1 25544U 98067A   26314.17503267  .00009346  00000+0  17575-3 0  9996',
  '2 25544  51.6322 297.6644 0007292   8.9462 351.1656 15.49289712594382',
  'CSS (TIANHE)',
  '1 48274U 21035A   26314.02396249  .00022456  00000+0  25655-3 0  9991',
  '2 48274  41.4671 155.8173 0004612 284.6802  75.3526 15.61635786315941',
  'SSOT',
  '1 38011U 11076E   26314.33139071  .00001795  00000+0  22861-3 0  9994',
  '2 38011  97.7897  11.1277 0001573  84.0255 343.7714 14.82749444806034',
  'GOES 19',
  '1 60133U 24119A   26314.28750544 -.00000239  00000+0  00000+0 0  9994',
  '2 60133   0.0034  70.9232 0000669 225.8123 141.0578  1.00272638  8428',
];
