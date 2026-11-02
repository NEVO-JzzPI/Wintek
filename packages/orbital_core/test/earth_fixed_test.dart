import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/time/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.
// Vallado repository, test_frame_conversions.py, fixtures rva_teme and rva_pef (opt 80): TEME and PEF positions of one state, jdut1 = 2453101.5.
// Vallado repository, test_frame_conversions.py, test_teme2ecef: TEME position to ECEF position with polar motion, jdut1 = 2453101.5.

const double _twoPi = 2 * pi;

const String _messageP = 'ECEF rotation requires a finite inertial position.';
const String _messageG = 'ECEF rotation requires a finite GMST.';

// Fixture rva_teme (test_eci2teme), km.
const CartesianVector _publishedTeme = CartesianVector(
  2994.454240128889,
  -7384.574761007484,
  6380.344532748868,
);

// Fixture rva_pef (test_eci2pef, opt 80), km.
const CartesianVector _publishedPef = CartesianVector(
  -1033.4750313057266,
  7901.305585585349,
  6380.344532748868,
);

// Fixture rva_ecef (test_teme2ecef), km.
const CartesianVector _publishedEcef = CartesianVector(
  -1033.4793830,
  7901.2952754,
  6380.3565958,
);

// jdut1 = 2453101.5 read as UTC (UTC ~ UT1, req-orb-001).
final double _referenceGmstRad = gmstRad(
  JulianDate.fromUtc(DateTime.utc(2004, 4, 6)),
);

Matcher _throwsArgumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

CartesianVector _rotate(CartesianVector r, double theta) =>
    ecefPositionKm(inertialPositionKm: r, gmstRad: theta);

double _length(CartesianVector v) => sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

void _expectClose(
  CartesianVector actual,
  CartesianVector expected,
  double tol,
) {
  expect(actual.x, closeTo(expected.x, tol));
  expect(actual.y, closeTo(expected.y, tol));
  expect(actual.z, closeTo(expected.z, tol));
}

void _expectExact(CartesianVector actual, CartesianVector expected) {
  expect(actual.x, expected.x);
  expect(actual.y, expected.y);
  expect(actual.z, expected.z);
}

void main() {
  // REQ-ORB-006.1
  group('published TEME position to the published PEF position', () {
    test('the reference GMST rotates TEME onto PEF', () {
      _expectClose(
        _rotate(_publishedTeme, _referenceGmstRad),
        _publishedPef,
        1e-4,
      );
    });
  });

  // REQ-ORB-006.2
  group('published TEME position to the published ECEF position', () {
    test('the reference GMST rotates TEME onto ECEF within polar motion', () {
      _expectClose(
        _rotate(_publishedTeme, _referenceGmstRad),
        _publishedEcef,
        2e-2,
      );
    });
  });

  // REQ-ORB-006.3
  group('fixed rotations', () {
    test('GMST = 0 leaves a position unchanged, exactly', () {
      _expectExact(
        _rotate(const CartesianVector(1.0, 2.0, 3.0), 0.0),
        const CartesianVector(1.0, 2.0, 3.0),
      );
      _expectExact(_rotate(_publishedPef, 0.0), _publishedPef);
    });

    test('quarter and half turns move the axes as R3(theta) requires', () {
      _expectClose(
        _rotate(const CartesianVector(1.0, 0.0, 0.0), pi / 2),
        const CartesianVector(0.0, -1.0, 0.0),
        1e-15,
      );
      _expectClose(
        _rotate(const CartesianVector(0.0, 1.0, 0.0), pi / 2),
        const CartesianVector(1.0, 0.0, 0.0),
        1e-15,
      );
      _expectClose(
        _rotate(const CartesianVector(1.0, 0.0, 0.0), pi),
        const CartesianVector(-1.0, 0.0, 0.0),
        1e-15,
      );
    });

    test('a position on the z axis is unchanged, exactly', () {
      _expectExact(
        _rotate(const CartesianVector(0.0, 0.0, 1.0), pi / 2),
        const CartesianVector(0.0, 0.0, 1.0),
      );
    });
  });

  // REQ-ORB-006.4
  group('rotation identities over a grid', () {
    const positions = <CartesianVector>[
      CartesianVector(6778.0, 0.0, 0.0),
      CartesianVector(4000.0, -5000.0, 3000.0),
      _publishedTeme,
      CartesianVector(-42164.0, 1e-3, -2.0),
      CartesianVector(0.0, 0.0, 6378.137),
      CartesianVector(9.1e9, -9.1e9, 9.1e9),
    ];
    final angles = <double>[
      for (var k = 0; k < 36; k++) k * _twoPi / 36,
      -10.0,
      100.0,
    ];

    test('length, z axis and full turn are kept', () {
      for (final r in positions) {
        final n = _length(r);
        for (final theta in angles) {
          final f = _rotate(r, theta);
          expect(_length(f), closeTo(n, 1e-14 * n));
          expect(f.z, r.z);
          _expectClose(_rotate(r, theta + _twoPi), f, 1e-13 * n);
        }
      }
    });

    test('two rotations compose into one', () {
      for (final r in positions) {
        final n = _length(r);
        for (final theta in angles) {
          for (final phi in angles) {
            _expectClose(
              _rotate(_rotate(r, theta), phi),
              _rotate(r, theta + phi),
              1e-13 * n,
            );
          }
        }
      }
    });

    test(
      'a position that turns with the Earth stays fixed over the ground',
      () {
        for (final rho in const [6778.0, 42164.0, 9.1e9]) {
          for (final theta in angles) {
            _expectClose(
              _rotate(
                CartesianVector(rho * cos(theta), rho * sin(theta), 0.0),
                theta,
              ),
              CartesianVector(rho, 0.0, 0.0),
              1e-14 * rho,
            );
          }
        }
      },
    );
  });

  // REQ-ORB-006.5
  group('input validation with exact messages', () {
    const base = CartesianVector(7000.0, -1000.0, 500.0);

    CartesianVector call({
      CartesianVector position = base,
      double gmst = 1.0,
    }) => ecefPositionKm(inertialPositionKm: position, gmstRad: gmst);

    test('a non-finite position component throws message P', () {
      expect(
        () => call(position: const CartesianVector(double.nan, -1000.0, 500.0)),
        _throwsArgumentError(_messageP),
      );
      expect(
        () => call(
          position: const CartesianVector(7000.0, double.infinity, 500.0),
        ),
        _throwsArgumentError(_messageP),
      );
      expect(
        () => call(
          position: const CartesianVector(
            7000.0,
            -1000.0,
            double.negativeInfinity,
          ),
        ),
        _throwsArgumentError(_messageP),
      );
    });

    test('a non-finite GMST throws message G', () {
      for (final bad in const [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(() => call(gmst: bad), _throwsArgumentError(_messageG));
      }
    });

    test('the position is checked before GMST', () {
      expect(
        () => call(
          position: const CartesianVector(double.nan, -1000.0, 500.0),
          gmst: double.nan,
        ),
        _throwsArgumentError(_messageP),
      );
    });

    test('negative zero GMST gives the same result as zero', () {
      _expectExact(call(gmst: -0.0), call(gmst: 0.0));
    });

    test('other finite angles are accepted', () {
      for (final theta in [_twoPi, -10.0]) {
        final f = call(gmst: theta);
        expect(f.x.isFinite && f.y.isFinite && f.z.isFinite, isTrue);
      }
    });

    test('the origin rotates to the origin, exactly', () {
      _expectExact(
        call(position: const CartesianVector(0.0, 0.0, 0.0)),
        const CartesianVector(0.0, 0.0, 0.0),
      );
    });
  });
}
