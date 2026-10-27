import 'dart:math';

import 'julian_date.dart';

const double _twoPi = 2 * pi;
const double _secondsPerDay = 86400.0;

/// Greenwich Mean Sidereal Time, in radians, of a two-part Julian date.
///
/// GMST model: IAU-82, the model SGP4 uses for TEME.
/// Result range: 0 inclusive to 2π exclusive, in radians.
/// Input: the two-part Julian date of req-orb-001 only.
/// Reference: Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., eq. 3-45, p. 187.
double gmstRad(JulianDate julianDate) {
  final t = julianDate.julianCenturies;
  final seconds =
      67310.54841 +
      (876600.0 * 3600.0 + 8640184.812866) * t +
      0.093104 * t * t -
      6.2e-6 * t * t * t;
  final gmst = (seconds % _secondsPerDay) * _twoPi / _secondsPerDay;
  return gmst >= _twoPi ? 0.0 : gmst;
}
