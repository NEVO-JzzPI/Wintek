import 'dart:math';

import 'state_vector.dart';

/// Rotation: r_ecef = R3(gmst) r_inertial, a rotation about the z axis.
/// Input frame: the inertial frame of the elements; TEME for elements read from a TLE.
/// Output frame: Earth-fixed axes without polar motion (PEF), used as ECEF.
/// Ignored: polar motion and the kinematic terms added to GMST.
/// Units: km and radians.
/// Reference: CelesTrak fundamentals-of-astrodynamics, time/frame_conversions.py, teme2ecef (Vallado: 2022, p. 232-234).
///
/// [gmstRad] may be any finite angle; it is not normalized.
///
/// Throws an [ArgumentError] when a component of [inertialPositionKm] is not
/// finite, or when [gmstRad] is not finite. The checks run in that order.
CartesianVector ecefPositionKm({
  required CartesianVector inertialPositionKm,
  required double gmstRad,
}) {
  if (!(inertialPositionKm.x.isFinite &&
      inertialPositionKm.y.isFinite &&
      inertialPositionKm.z.isFinite)) {
    throw ArgumentError('ECEF rotation requires a finite inertial position.');
  }
  if (!gmstRad.isFinite) {
    throw ArgumentError('ECEF rotation requires a finite GMST.');
  }
  final c = cos(gmstRad);
  final s = sin(gmstRad);
  return CartesianVector(
    c * inertialPositionKm.x + s * inertialPositionKm.y,
    -s * inertialPositionKm.x + c * inertialPositionKm.y,
    inertialPositionKm.z,
  );
}
