import 'dart:math';

import 'state_vector.dart';

/// Gravitational parameter of WGS-84, in km^3/s^2, as fixed by the Project Brief.
const double wgs84MuKm3S2 = 398600.4418;

/// Semi-major axis: a = (mu / n^2)^(1/3), with mu = 398600.4418 km^3/s^2 (WGS-84).
/// Mean motion: the Kozai mean motion of the element set, used as is.
///
/// [meanMotionRadS] is in radians per second; the result is in kilometres.
///
/// Throws an [ArgumentError] when [meanMotionRadS] is not finite or not
/// greater than 0.
double semiMajorAxisKmFromMeanMotion(double meanMotionRadS) {
  if (!(meanMotionRadS.isFinite && meanMotionRadS > 0)) {
    throw ArgumentError(
      'Semi-major axis requires a finite mean motion greater than 0.',
    );
  }
  return pow(
    wgs84MuKm3S2 / (meanMotionRadS * meanMotionRadS),
    1 / 3,
  ).toDouble();
}

/// Perifocal position: x = a (cos E - e), y = a sqrt(1 - e^2) sin E, z = 0.
/// Perifocal velocity: sqrt(mu a) / r * (-sin E, sqrt(1 - e^2) cos E, 0), r = a (1 - e cos E).
/// Rotation: R3(-raan) R1(-i) R3(-argp), from perifocal to inertial axes.
/// Frame: the inertial frame of the elements; TEME for elements read from a TLE.
/// Units: km, km/s and radians.
/// Reference: CelesTrak fundamentals-of-astrodynamics, frame_conversions.py, coe2rv (Vallado: 2022, Ex. 2-6).
///
/// Throws an [ArgumentError] when the semi-major axis is not finite or not
/// greater than 0, when the eccentricity is outside 0 inclusive to 1
/// exclusive, or when an angle is not finite. The checks run in that order.
StateVector inertialStateVector({
  required double semiMajorAxisKm,
  required double eccentricity,
  required double inclinationRad,
  required double raanRad,
  required double argumentOfPerigeeRad,
  required double eccentricAnomalyRad,
}) {
  if (!(semiMajorAxisKm.isFinite && semiMajorAxisKm > 0)) {
    throw ArgumentError(
      'State vector requires a finite semi-major axis greater than 0.',
    );
  }
  if (!(eccentricity >= 0 && eccentricity < 1)) {
    throw ArgumentError(
      'State vector requires an eccentricity from 0 inclusive to 1 exclusive.',
    );
  }
  if (!(inclinationRad.isFinite &&
      raanRad.isFinite &&
      argumentOfPerigeeRad.isFinite &&
      eccentricAnomalyRad.isFinite)) {
    throw ArgumentError('State vector requires finite angles.');
  }

  final cosE = cos(eccentricAnomalyRad);
  final sinE = sin(eccentricAnomalyRad);
  final minorFactor = sqrt(1 - eccentricity * eccentricity);
  final radiusKm = semiMajorAxisKm * (1 - eccentricity * cosE);
  final speedFactor = sqrt(wgs84MuKm3S2 * semiMajorAxisKm) / radiusKm;

  final xKm = semiMajorAxisKm * (cosE - eccentricity);
  final yKm = semiMajorAxisKm * minorFactor * sinE;
  final vxKmS = -speedFactor * sinE;
  final vyKmS = speedFactor * minorFactor * cosE;

  final cosRaan = cos(raanRad);
  final sinRaan = sin(raanRad);
  final cosArgp = cos(argumentOfPerigeeRad);
  final sinArgp = sin(argumentOfPerigeeRad);
  final cosI = cos(inclinationRad);
  final sinI = sin(inclinationRad);

  final px = cosRaan * cosArgp - sinRaan * sinArgp * cosI;
  final py = sinRaan * cosArgp + cosRaan * sinArgp * cosI;
  final pz = sinArgp * sinI;
  final qx = -cosRaan * sinArgp - sinRaan * cosArgp * cosI;
  final qy = -sinRaan * sinArgp + cosRaan * cosArgp * cosI;
  final qz = cosArgp * sinI;

  return StateVector(
    positionKm: CartesianVector(
      xKm * px + yKm * qx,
      xKm * py + yKm * qy,
      xKm * pz + yKm * qz,
    ),
    velocityKmS: CartesianVector(
      vxKmS * px + vyKmS * qx,
      vxKmS * py + vyKmS * qy,
      vxKmS * pz + vyKmS * qz,
    ),
  );
}
