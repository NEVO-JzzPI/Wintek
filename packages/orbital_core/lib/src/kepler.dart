import 'dart:math';

import 'elapsed_time.dart';
import 'julian_date.dart';
import 'orbital_elements.dart';

const double _twoPi = 2 * pi;
const double _convergenceRad = 1e-12;
const int _maxIterations = 50;

/// Mean anomaly: M = M0 + n (t - t0), linear; ndot / 2 and nddot / 6 are not used.
///
/// M0 is the mean anomaly of [elements], n its Kozai mean motion and t0 its
/// epoch. The result is normalized to the range of [eccentricAnomalyRad].
///
/// Throws an [ArgumentError] when [utc] is not flagged as UTC or lies outside
/// the valid range of [JulianDate.fromUtc].
double meanAnomalyAtRad(OrbitalElements elements, DateTime utc) {
  final elapsed = elapsedSeconds(
    JulianDate.fromUtc(elements.epoch),
    JulianDate.fromUtc(utc),
  );
  return _normalize(
    elements.meanAnomalyRad + elements.meanMotionRadS * elapsed,
  );
}

/// Kepler's equation: M = E - e sin E, solved by Newton-Raphson.
/// Initial guess: E0 = M - e when M > pi, otherwise M + e.
/// Convergence: |E(k+1) - E(k)| <= 1e-12 rad within 50 iterations.
/// Normalization: Dart's % by 2 * pi; a result equal to 2 * pi becomes 0.
/// Result range: 0 inclusive to 2π exclusive, in radians.
/// Reference: CelesTrak fundamentals-of-astrodynamics, newton.py, newtonm (Vallado: 2022, p. 65, Algorithm 2).
///
/// [meanAnomalyRad] may be any finite angle; it is normalized before the
/// initial guess. [eccentricity] must lie from 0 inclusive to 1 exclusive.
///
/// Throws an [ArgumentError] for a non-finite input or an eccentricity out of
/// range, and a [StateError] if the iteration does not converge, which is a
/// defect of the solver and not of the input.
double eccentricAnomalyRad(double meanAnomalyRad, double eccentricity) {
  if (!meanAnomalyRad.isFinite) {
    throw ArgumentError('Kepler solver requires a finite mean anomaly.');
  }
  if (!eccentricity.isFinite) {
    throw ArgumentError('Kepler solver requires a finite eccentricity.');
  }
  if (eccentricity < 0 || eccentricity >= 1) {
    throw ArgumentError(
      'Kepler solver supports eccentricity from 0 inclusive to 1 exclusive only.',
    );
  }
  final m = _normalize(meanAnomalyRad);
  var e = m > pi ? m - eccentricity : m + eccentricity;
  for (var i = 0; i < _maxIterations; i++) {
    final next =
        e - (e - eccentricity * sin(e) - m) / (1 - eccentricity * cos(e));
    final change = (next - e).abs();
    e = next;
    if (change <= _convergenceRad) return _normalize(e);
  }
  throw StateError('Kepler solver did not converge in 50 iterations.');
}

double _normalize(double angleRad) {
  final remainder = angleRad % _twoPi;
  return remainder == _twoPi ? 0.0 : remainder;
}
