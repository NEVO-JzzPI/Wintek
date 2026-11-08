import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// IOGP Publication 373-7-2, Geomatics Guidance Note 7-2, September 2019: https://www.iogp.org/wp-content/uploads/2019/09/373-07-02.pdf, section 4.1.1, EPSG method 9602.
// IOGP 373-7-2, page 96: WGS 84 geocentric coordinates of a North Sea point to latitude, longitude and ellipsoidal height.
// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.
// Vallado repository, twobody test_frame_conversions.py, test_ecef2ll (Example 3-3): computed with RE = 6378.1363 km, not the WGS-84 radius.

const String _messageP = 'Geodetic conversion requires a finite ECEF position.';
const String _messageO =
    'Geodetic conversion requires a position away from the origin.';

// Ellipsoid of IOGP 373-7-2, page 67, as literal numbers (km).
const double _semiMajorKm = 6378.137;
const double _inverseFlattening = 298.257223563;

double _rad(double degrees) => degrees * pi / 180;

double _sexagesimalRad(int degrees, int minutes, double seconds) =>
    _rad(degrees + minutes / 60 + seconds / 3600);

// Forward formulas of IOGP 373-7-2, page 95.
CartesianVector _forward(double latRad, double lonRad, double altKm) {
  const f = 1 / _inverseFlattening;
  const e2 = 2 * f - f * f;
  final s = sin(latRad);
  final nu = _semiMajorKm / sqrt(1 - e2 * s * s);
  return CartesianVector(
    (nu + altKm) * cos(latRad) * cos(lonRad),
    (nu + altKm) * cos(latRad) * sin(lonRad),
    (nu * (1 - e2) + altKm) * s,
  );
}

GeodeticPosition _convert(CartesianVector r) =>
    geodeticPositionFromEcef(ecefPositionKm: r);

double _length(CartesianVector v) => sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

double _distance(CartesianVector u, CartesianVector v) =>
    _length(CartesianVector(u.x - v.x, u.y - v.y, u.z - v.z));

double _wrappedDifference(double u, double v) {
  final d = (u - v).abs();
  return d <= pi ? d : 2 * pi - d;
}

bool _inRange(GeodeticPosition g) =>
    g.latitudeRad.abs() <= pi / 2 &&
    g.longitudeRad > -pi &&
    g.longitudeRad <= pi;

bool _finite(GeodeticPosition g) =>
    g.latitudeRad.isFinite && g.longitudeRad.isFinite && g.altitudeKm.isFinite;

Matcher _throwsArgumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

void _expectFixed(
  CartesianVector r, {
  required double lat,
  required double lon,
  required double altKm,
  required double tolKm,
  bool polar = false,
}) {
  final g = _convert(r);
  final why = 'position (${r.x}, ${r.y}, ${r.z})';
  if (polar) {
    expect(g.latitudeRad, closeTo(lat, 1e-15), reason: why);
  } else {
    expect(g.latitudeRad, lat, reason: why);
  }
  expect(g.longitudeRad, lon, reason: why);
  expect(g.altitudeKm, closeTo(altKm, tolKm), reason: why);
}

void main() {
  // REQ-ORB-007.1
  group('published WGS 84 position to its published coordinates', () {
    test('the IOGP example yields its latitude, longitude and height', () {
      final g = _convert(
        const CartesianVector(3771.793968, 140.253342, 5124.304349),
      );
      expect(g.latitudeRad, closeTo(_sexagesimalRad(53, 48, 33.820), 2.5e-9));
      expect(g.longitudeRad, closeTo(_sexagesimalRad(2, 7, 46.380), 2.5e-9));
      expect(g.altitudeKm, closeTo(0.073, 5e-5));
    });
  });

  // REQ-ORB-007.2
  group('published orbital-altitude position to its published coordinates', () {
    test(
      'the Vallado example yields its coordinates within the radius cost',
      () {
        final g = _convert(const CartesianVector(6524.834, 6862.875, 6448.296));
        expect(g.latitudeRad, closeTo(0.5995641464668334, 3e-10));
        expect(g.longitudeRad, closeTo(0.8106428999047803, 1e-15));
        expect(g.altitudeKm, closeTo(5085.219430346959, 1e-3));
      },
    );
  });

  // REQ-ORB-007.3
  group('fixed points', () {
    test('equator and geostationary radius', () {
      _expectFixed(
        const CartesianVector(6378.137, 0.0, 0.0),
        lat: 0.0,
        lon: 0.0,
        altKm: 0.0,
        tolKm: 1e-11,
      );
      _expectFixed(
        const CartesianVector(42164.0, 0.0, 0.0),
        lat: 0.0,
        lon: 0.0,
        altKm: 35785.863,
        tolKm: 1e-9,
      );
      _expectFixed(
        const CartesianVector(0.0, 42164.0, 0.0),
        lat: 0.0,
        lon: pi / 2,
        altKm: 35785.863,
        tolKm: 1e-9,
      );
      _expectFixed(
        const CartesianVector(0.0, -42164.0, 0.0),
        lat: 0.0,
        lon: -pi / 2,
        altKm: 35785.863,
        tolKm: 1e-9,
      );
    });

    test('the antimeridian is pi, never -pi', () {
      for (final y in const [0.0, -0.0, -1e-300]) {
        _expectFixed(
          CartesianVector(-42164.0, y, 0.0),
          lat: 0.0,
          lon: pi,
          altKm: 35785.863,
          tolKm: 1e-9,
        );
      }
    });

    test('a position below the ellipsoid has a negative altitude', () {
      _expectFixed(
        const CartesianVector(6000.0, 0.0, 0.0),
        lat: 0.0,
        lon: 0.0,
        altKm: -378.137,
        tolKm: 1e-9,
      );
    });

    test('the poles and signed zeros on the z axis', () {
      _expectFixed(
        const CartesianVector(0.0, 0.0, 6356.752314),
        lat: pi / 2,
        lon: 0.0,
        altKm: 0.0,
        tolKm: 1e-6,
        polar: true,
      );
      _expectFixed(
        const CartesianVector(0.0, 0.0, -6356.752314),
        lat: -pi / 2,
        lon: 0.0,
        altKm: 0.0,
        tolKm: 1e-6,
        polar: true,
      );
      _expectFixed(
        const CartesianVector(0.0, 0.0, 7000.0),
        lat: pi / 2,
        lon: 0.0,
        altKm: 643.247686,
        tolKm: 1e-6,
        polar: true,
      );
      _expectFixed(
        const CartesianVector(0.0, 0.0, -7000.0),
        lat: -pi / 2,
        lon: 0.0,
        altKm: 643.247686,
        tolKm: 1e-6,
        polar: true,
      );
      _expectFixed(
        const CartesianVector(-0.0, 0.0, 7000.0),
        lat: pi / 2,
        lon: 0.0,
        altKm: 643.247686,
        tolKm: 1e-6,
        polar: true,
      );
      _expectFixed(
        const CartesianVector(-0.0, -0.0, 7000.0),
        lat: pi / 2,
        lon: 0.0,
        altKm: 643.247686,
        tolKm: 1e-6,
        polar: true,
      );
      _expectFixed(
        const CartesianVector(0.0, -0.0, -7000.0),
        lat: -pi / 2,
        lon: 0.0,
        altKm: 643.247686,
        tolKm: 1e-6,
        polar: true,
      );
    });
  });

  // REQ-ORB-007.4
  group('round trip and symmetry over grids', () {
    const latitudesDeg = <double>[
      -90.0, -89.9999, -89.99, -89.0, -60.0, -35.0, -1e-6, 0.0, //
      1e-6, 35.0, 51.6, 60.0, 89.0, 89.99, 89.9999, 90.0,
    ];
    const longitudesDeg = <double>[
      -179.9, -90.0, -1e-6, 0.0, 45.0, 120.0, 179.9, 180.0, //
    ];
    const altitudesKm = <double>[
      -100.0, -10.0, 0.0, 0.1, 100.0, 408.0, 628.0, 35786.0, 1e6, 9.1e9, //
    ];

    test('the outer grid converts back and mirrors across the equator', () {
      var count = 0;
      for (final latDeg in latitudesDeg) {
        for (final lonDeg in longitudesDeg) {
          for (final altKm in altitudesKm) {
            count++;
            final lat = _rad(latDeg);
            final lon = _rad(lonDeg);
            final r = _forward(lat, lon, altKm);
            final n = _length(r);
            final g = _convert(r);
            final why = 'lat $latDeg deg, lon $lonDeg deg, altitude $altKm km';

            expect(g.latitudeRad, closeTo(lat, 1e-15), reason: why);
            if (latDeg.abs() != 90.0) {
              expect(
                _wrappedDifference(g.longitudeRad, lon),
                lessThanOrEqualTo(1e-15),
                reason: why,
              );
            }
            expect(g.altitudeKm, closeTo(altKm, 2e-15 * n), reason: why);
            expect(
              _distance(
                _forward(g.latitudeRad, g.longitudeRad, g.altitudeKm),
                r,
              ),
              lessThanOrEqualTo(2e-15 * n),
              reason: why,
            );
            expect(_inRange(g), isTrue, reason: why);

            final mirror = _convert(CartesianVector(r.x, r.y, -r.z));
            expect(mirror.latitudeRad, -g.latitudeRad, reason: why);
            expect(mirror.longitudeRad, g.longitudeRad, reason: why);
            expect(mirror.altitudeKm, g.altitudeKm, reason: why);
          }
        }
      }
      expect(count, 1280);
    });

    test('the inner rings convert back', () {
      for (final rho in const [1000.0, 3000.0, 6000.0]) {
        for (var d = -90; d <= 90; d++) {
          final phi = _rad(d.toDouble());
          final r = CartesianVector(rho * cos(phi), 0.0, rho * sin(phi));
          final g = _convert(r);
          expect(
            _distance(_forward(g.latitudeRad, g.longitudeRad, g.altitudeKm), r),
            lessThanOrEqualTo(1e-8),
            reason: 'radius $rho km, geocentric latitude $d deg',
          );
        }
      }
    });

    test('the inner domain stays finite and in range', () {
      var count = 0;
      for (final rho in const [
        1e-3, 1.0, 10.0, 20.0, 30.0, 40.0, 42.0, 43.0, 44.0, 50.0, 100.0, //
        500.0,
      ]) {
        for (var d = -90; d <= 90; d++) {
          final phi = _rad(d.toDouble());
          for (final theta in const [0.0, 1.0, 3.0, -2.0]) {
            count++;
            final g = _convert(
              CartesianVector(
                rho * cos(phi) * cos(theta),
                rho * cos(phi) * sin(theta),
                rho * sin(phi),
              ),
            );
            final why =
                'radius $rho km, geocentric latitude $d deg, angle $theta rad';
            expect(_finite(g), isTrue, reason: why);
            expect(_inRange(g), isTrue, reason: why);
          }
        }
      }
      expect(count, 8688);
    });
  });

  // REQ-ORB-007.5
  group('input validation with exact messages', () {
    CartesianVector at(double x, double y, double z) =>
        CartesianVector(x, y, z);

    test('a non-finite component throws message P', () {
      for (final r in [
        at(double.nan, 2000.0, 3000.0),
        at(1000.0, double.infinity, 3000.0),
        at(1000.0, 2000.0, double.negativeInfinity),
        at(double.nan, 0.0, 0.0),
      ]) {
        expect(() => _convert(r), _throwsArgumentError(_messageP));
      }
    });

    test('the origin throws message O, negative zeros included', () {
      for (final r in [at(0.0, 0.0, 0.0), at(-0.0, 0.0, -0.0)]) {
        expect(() => _convert(r), _throwsArgumentError(_messageO));
      }
    });

    test('every other finite position is accepted', () {
      for (final r in [
        at(1e-200, 0.0, 0.0),
        at(0.0, 0.0, 1e-3),
        at(1.0, 0.0, 0.0),
        at(9.1e9, -9.1e9, 9.1e9),
      ]) {
        expect(_finite(_convert(r)), isTrue);
      }
    });
  });
}
