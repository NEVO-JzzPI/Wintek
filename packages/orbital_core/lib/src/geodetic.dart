import 'dart:math';

import 'state_vector.dart';

/// Semi-major axis of the WGS-84 ellipsoid, in km.
const double wgs84SemiMajorAxisKm = 6378.137;

/// Inverse flattening of the WGS-84 ellipsoid.
const double wgs84InverseFlattening = 298.257223563;

/// Geodetic position: latitude and longitude in radians, altitude in km.
final class GeodeticPosition {
  const GeodeticPosition({
    required this.latitudeRad,
    required this.longitudeRad,
    required this.altitudeKm,
  });

  final double latitudeRad;
  final double longitudeRad;
  final double altitudeKm;
}

/// Model: WGS-84 ellipsoid, a = 6378.137 km and 1/f = 298.257223563.
/// Input frame: Earth-fixed axes without polar motion (PEF), used as ECEF.
/// Latitude: geodetic, two fixed passes of the closed form, from -pi/2 to pi/2.
/// Longitude: atan2(y, x), greater than -pi and up to pi; 0.0 on the z axis.
/// Altitude: height above the ellipsoid, h = p cos(lat) + z sin(lat) - a^2 / nu; negative below it.
/// Ignored: the geoid; altitude is not height above mean sea level.
/// Units: km and radians.
/// Reference: IOGP Publication 373-7-2 (September 2019), section 4.1.1, EPSG method 9602.
///
/// Throws an [ArgumentError] when a component of [ecefPositionKm] is not
/// finite, or when all three components are zero. The checks run in that order.
GeodeticPosition geodeticPositionFromEcef({
  required CartesianVector ecefPositionKm,
}) {
  final x = ecefPositionKm.x;
  final y = ecefPositionKm.y;
  final z = ecefPositionKm.z;
  if (!(x.isFinite && y.isFinite && z.isFinite)) {
    throw ArgumentError('Geodetic conversion requires a finite ECEF position.');
  }
  if (x == 0.0 && y == 0.0 && z == 0.0) {
    throw ArgumentError(
      'Geodetic conversion requires a position away from the origin.',
    );
  }
  const a = wgs84SemiMajorAxisKm;
  final f = 1 / wgs84InverseFlattening;
  final b = a * (1 - f);
  final e2 = 2 * f - f * f;
  final ep = e2 / (1 - e2);
  final p = sqrt(x * x + y * y);
  var q = atan2(z * a, p * b);
  var latitudeRad = 0.0;
  for (var pass = 0; pass < 2; pass++) {
    final sq = sin(q);
    final cq = cos(q);
    latitudeRad = atan2(z + ep * b * sq * sq * sq, p - e2 * a * cq * cq * cq);
    q = atan2((1 - f) * sin(latitudeRad), cos(latitudeRad));
  }
  final s = sin(latitudeRad);
  final nu = a / sqrt(1 - e2 * s * s);
  var longitudeRad = (x == 0.0 && y == 0.0) ? 0.0 : atan2(y, x);
  if (longitudeRad == -pi) longitudeRad = pi;
  return GeodeticPosition(
    latitudeRad: latitudeRad,
    longitudeRad: longitudeRad,
    altitudeKm: p * cos(latitudeRad) + z * s - a * a / nu,
  );
}
