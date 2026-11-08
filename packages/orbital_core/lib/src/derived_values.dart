import 'dart:math';

import 'perifocal.dart';
import 'state_vector.dart';

/// Model: vis-viva, v = sqrt(mu (2 / r - 1 / a)), with mu = wgs84MuKm3S2 = 398600.4418 km^3/s^2.
/// Position: only its length r is used, so it may be in any frame.
/// Speed: relative to the inertial frame of the elements, not relative to the rotating Earth.
/// Semi-major axis: the one of the element set, from the Kozai mean motion, as semiMajorAxisKmFromMeanMotion gives it.
/// Units: km and km/s.
/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and semi-major axis), CelesTrak fundamentals-of-astrodynamics test suite.
///
/// Throws an [ArgumentError] when the position is not finite, when the
/// semi-major axis is not finite or not greater than 0, when the position has
/// length 0, or when the position is farther than twice the semi-major axis.
/// The checks run in that order.
double visVivaSpeedKmS({
  required CartesianVector positionKm,
  required double semiMajorAxisKm,
}) {
  if (!(positionKm.x.isFinite &&
      positionKm.y.isFinite &&
      positionKm.z.isFinite)) {
    throw ArgumentError('Orbital speed requires a finite position.');
  }
  if (!(semiMajorAxisKm.isFinite && semiMajorAxisKm > 0)) {
    throw ArgumentError(
      'Orbital speed requires a finite semi-major axis greater than 0.',
    );
  }
  final radiusKm = sqrt(
    positionKm.x * positionKm.x +
        positionKm.y * positionKm.y +
        positionKm.z * positionKm.z,
  );
  if (radiusKm == 0.0) {
    throw ArgumentError(
      'Orbital speed requires a position away from the origin.',
    );
  }
  final energyFactor = 2 / radiusKm - 1 / semiMajorAxisKm;
  if (energyFactor < 0) {
    throw ArgumentError(
      'Orbital speed requires a position within twice the semi-major axis.',
    );
  }
  return sqrt(wgs84MuKm3S2 * energyFactor);
}

/// Model: T = 2 pi / n, the time of one revolution at the mean motion n.
/// Mean motion: the Kozai mean motion of the element set, used as is.
/// Units: radians per second in, seconds out.
/// Reference: WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s (DMA TR8350.2); sidereal day, 86164.0905 s.
///
/// Throws an [ArgumentError] when [meanMotionRadS] is not finite or not
/// greater than 0.
double orbitalPeriodSFromMeanMotion(double meanMotionRadS) {
  if (!(meanMotionRadS.isFinite && meanMotionRadS > 0)) {
    throw ArgumentError(
      'Orbital period requires a finite mean motion greater than 0.',
    );
  }
  return 2 * pi / meanMotionRadS;
}

/// Model: i = atan2(sqrt(hx^2 + hy^2), hz), with h = r x v the specific angular momentum.
/// Input frame: the inertial frame of the state vector, such as TEME; an Earth-fixed state gives no inclination.
/// Inclination: osculating, from 0 to pi; 0 for a prograde equatorial orbit and pi for a retrograde one.
/// Ignored: the mean inclination of the element set, which OrbitalElements.inclinationRad holds.
/// Units: km, km/s and radians.
/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and inclination), CelesTrak fundamentals-of-astrodynamics test suite.
///
/// Throws an [ArgumentError] when a component of the state is not finite or
/// when the angular momentum is zero. The checks run in that order.
double inclinationRadFromState({required StateVector inertialState}) {
  final r = inertialState.positionKm;
  final v = inertialState.velocityKmS;
  if (!(r.x.isFinite &&
      r.y.isFinite &&
      r.z.isFinite &&
      v.x.isFinite &&
      v.y.isFinite &&
      v.z.isFinite)) {
    throw ArgumentError('Inclination requires a finite state vector.');
  }
  final hx = r.y * v.z - r.z * v.y;
  final hy = r.z * v.x - r.x * v.z;
  final hz = r.x * v.y - r.y * v.x;
  if (hx == 0.0 && hy == 0.0 && hz == 0.0) {
    throw ArgumentError('Inclination requires a nonzero angular momentum.');
  }
  return atan2(sqrt(hx * hx + hy * hy), hz);
}
