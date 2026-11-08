import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.
// Vallado repository, twobody test_frame_conversions.py, test_rv2coe (Example 2-5) and test_coe2rv (Example 2-6): position, velocity, semi-major axis and inclination, computed with MU = 398600.4415 km^3/s^2.
// WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s: DMA Technical Report 8350.2 (1991), as quoted at https://en.wikipedia.org/wiki/World_Geodetic_System.
// Sidereal day, 86164.0905 s: https://en.wikipedia.org/wiki/Sidereal_time.
// Kelso, Basics of the Geostationary Orbit, Satellite Times, May 1998: https://celestrak.org/columns/v04n07/, one sidereal day is 23h56m04s.

const String _messageP = 'Orbital speed requires a finite position.';
const String _messageA =
    'Orbital speed requires a finite semi-major axis greater than 0.';
const String _messageO =
    'Orbital speed requires a position away from the origin.';
const String _messageR =
    'Orbital speed requires a position within twice the semi-major axis.';
const String _messageN =
    'Orbital period requires a finite mean motion greater than 0.';
const String _messageF = 'Inclination requires a finite state vector.';
const String _messageH = 'Inclination requires a nonzero angular momentum.';

// Gravitational parameter and angular velocity as literal numbers.
const double _muKm3S2 = 398600.4418;
const double _earthOmegaRadS = 72.92115e-6;

// Vallado, Examples 2-5 and 2-6, as published by the CelesTrak repository.
const CartesianVector _v25Position = CartesianVector(
  6524.834,
  6862.875,
  6448.296,
);
const CartesianVector _v25Velocity = CartesianVector(
  4.901327,
  5.533756,
  -1.976341,
);
const double _v25SemiMajorAxisKm = 36127.337763974785;
const double _v25InclinationRad = 1.5336055626394494;
const CartesianVector _v26Position = CartesianVector(
  6525.368120986091,
  6861.531834896055,
  6449.118614160162,
);
const CartesianVector _v26Velocity = CartesianVector(
  4.902278644574153,
  5.533139566279278,
  -1.9757100987916154,
);

double _length(CartesianVector v) => sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

double _v26SemiMajorAxisKm() {
  const p = 11067.790;
  const ecc = 0.83285;
  return p / (1 - ecc * ecc);
}

double _v26InclinationRad() => 87.87 * pi / 180;

CartesianVector _rotateZ(CartesianVector v, double thetaRad) {
  final c = cos(thetaRad);
  final s = sin(thetaRad);
  return CartesianVector(v.x * c - v.y * s, v.x * s + v.y * c, v.z);
}

double _speed(CartesianVector position, double axisKm) =>
    visVivaSpeedKmS(positionKm: position, semiMajorAxisKm: axisKm);

double _inclination(CartesianVector position, CartesianVector velocity) =>
    inclinationRadFromState(
      inertialState: StateVector(positionKm: position, velocityKmS: velocity),
    );

Matcher _argumentError(String message) => throwsA(
  isA<ArgumentError>().having((e) => e.message, 'message', equals(message)),
);

void main() {
  // REQ-ORB-008.1
  group('speed against two published worked examples', () {
    test('Vallado Example 2-5', () {
      expect(
        _speed(_v25Position, _v25SemiMajorAxisKm),
        closeTo(_length(_v25Velocity), 1e-8),
      );
    });

    test('Vallado Example 2-6', () {
      expect(
        _speed(_v26Position, _v26SemiMajorAxisKm()),
        closeTo(_length(_v26Velocity), 1e-8),
      );
    });
  });

  // REQ-ORB-008.2
  group('speed identities and agreement with the state vector', () {
    test('circular speed at r = a', () {
      for (final a in [6778.137, 7000.0, 42164.17]) {
        final expected = sqrt(398600.4418 / a);
        final actual = _speed(CartesianVector(a, 0.0, 0.0), a);
        expect((actual - expected).abs(), lessThanOrEqualTo(expected * 1e-13));
      }
    });

    test('exactly 0.0 at r = 2a', () {
      expect(_speed(const CartesianVector(14000.0, 0.0, 0.0), 7000.0), 0.0);
      expect(_speed(const CartesianVector(0.0, -14000.0, 0.0), 7000.0), 0.0);
      expect(_speed(const CartesianVector(0.0, 0.0, 14000.0), 7000.0), 0.0);
    });

    test('grid against the velocity of inertialStateVector', () {
      var count = 0;
      for (final a in [6778.0, 26560.4, 42164.17, 1e6]) {
        for (final e in [0.0, 0.001, 0.1, 0.5, 0.9, 0.99]) {
          for (final ecc in [0.0, 1.0, pi / 2, 3.0, pi, 4.0, 6.0]) {
            final state = inertialStateVector(
              semiMajorAxisKm: a,
              eccentricity: e,
              inclinationRad: 0.5,
              raanRad: 1.0,
              argumentOfPerigeeRad: 2.0,
              eccentricAnomalyRad: ecc,
            );
            final expected = _length(state.velocityKmS);
            final actual = _speed(state.positionKm, a);
            expect(
              (actual - expected).abs(),
              lessThanOrEqualTo(expected * 1e-12),
              reason: 'a=$a e=$e E=$ecc',
            );
            count++;
          }
        }
      }
      expect(count, 168);
    });
  });

  // REQ-ORB-008.3
  group('period against the angular velocity and the sidereal day', () {
    test('published sidereal day', () {
      final period = orbitalPeriodSFromMeanMotion(_earthOmegaRadS);
      expect(period, closeTo(86164.0905, 0.02));
      expect(period, closeTo(86164.0, 0.5));
    });

    test('identities', () {
      expect(orbitalPeriodSFromMeanMotion(1.0), 2 * pi);
      expect(
        orbitalPeriodSFromMeanMotion(2 * pi / 86400),
        closeTo(86400, 1e-9),
      );
    });

    test('Kepler third law through the semi-major axis', () {
      for (final n in [7.2921159e-5, 1.1e-3, 1.65e-3, 9e-4, 7.27e-13]) {
        final a = semiMajorAxisKmFromMeanMotion(n);
        final t = orbitalPeriodSFromMeanMotion(n);
        final expected = 4 * pi * pi * a * a * a / _muKm3S2;
        expect((t * t - expected).abs(), lessThanOrEqualTo(expected * 1e-13));
      }
    });
  });

  // REQ-ORB-008.4
  group('inclination against published and fixed states', () {
    test('published states', () {
      expect(
        _inclination(_v25Position, _v25Velocity),
        closeTo(_v25InclinationRad, 1e-12),
      );
      expect(
        _inclination(_v26Position, _v26Velocity),
        closeTo(_v26InclinationRad(), 1e-12),
      );
    });

    test('fixed states', () {
      const p = CartesianVector(7000.0, 0.0, 0.0);
      expect(_inclination(p, const CartesianVector(0.0, 7.5, 0.0)), 0.0);
      expect(
        _inclination(
          const CartesianVector(7000.0, -0.0, 0.0),
          const CartesianVector(-0.0, 7.5, 0.0),
        ),
        0.0,
      );
      expect(_inclination(p, const CartesianVector(0.0, -7.5, 0.0)), pi);
      expect(_inclination(p, const CartesianVector(0.0, 0.0, 7.5)), pi / 2);
      expect(
        _inclination(p, const CartesianVector(0.0, 5.0, 5.0)),
        closeTo(pi / 4, 1e-15),
      );
    });

    test('rotation about the z axis', () {
      final rotated = _inclination(
        _rotateZ(_v25Position, 1.0),
        _rotateZ(_v25Velocity, 1.0),
      );
      expect(rotated, closeTo(_inclination(_v25Position, _v25Velocity), 1e-14));
    });

    test('round trip through inertialStateVector', () {
      var count = 0;
      for (final i in [0.0, 1e-6, 0.5, 0.9, pi / 2, 2.0, pi - 1e-6, pi]) {
        for (final raan in [0.0, 1.0, 4.0]) {
          for (final argp in [0.0, 2.0]) {
            for (final anomaly in [0.0, 1.0, 3.0]) {
              final state = inertialStateVector(
                semiMajorAxisKm: 7000.0,
                eccentricity: 0.01,
                inclinationRad: i,
                raanRad: raan,
                argumentOfPerigeeRad: argp,
                eccentricAnomalyRad: anomaly,
              );
              expect(
                _inclination(state.positionKm, state.velocityKmS),
                closeTo(i, 1e-14),
                reason: 'i=$i raan=$raan argp=$argp E=$anomaly',
              );
              count++;
            }
          }
        }
      }
      expect(count, 144);
    });
  });

  // REQ-ORB-008.5
  group('input validation with exact messages', () {
    const x7000 = CartesianVector(7000.0, 0.0, 0.0);
    const zero = CartesianVector(0.0, 0.0, 0.0);
    const nan = double.nan;
    const inf = double.infinity;

    test('speed throws P', () {
      for (final p in [
        const CartesianVector(nan, 2000.0, 3000.0),
        const CartesianVector(1000.0, inf, 3000.0),
        const CartesianVector(1000.0, 2000.0, -inf),
      ]) {
        expect(() => _speed(p, 7000.0), _argumentError(_messageP));
      }
      expect(
        () => _speed(const CartesianVector(nan, 0.0, 0.0), nan),
        _argumentError(_messageP),
      );
    });

    test('speed throws A', () {
      for (final a in [nan, inf, 0.0, -0.0, -7000.0]) {
        expect(() => _speed(x7000, a), _argumentError(_messageA));
      }
      expect(() => _speed(zero, 0.0), _argumentError(_messageA));
    });

    test('speed throws O', () {
      expect(() => _speed(zero, 7000.0), _argumentError(_messageO));
      expect(
        () => _speed(const CartesianVector(-0.0, 0.0, -0.0), 7000.0),
        _argumentError(_messageO),
      );
      expect(
        () => _speed(const CartesianVector(1e-200, 0.0, 0.0), 7000.0),
        _argumentError(_messageO),
      );
    });

    test('speed throws R', () {
      expect(
        () => _speed(const CartesianVector(14001.0, 0.0, 0.0), 7000.0),
        _argumentError(_messageR),
      );
      expect(
        () => _speed(const CartesianVector(1e200, 0.0, 0.0), 7000.0),
        _argumentError(_messageR),
      );
      expect(
        () => _speed(const CartesianVector(1e200, 0.0, 0.0), 1e308),
        _argumentError(_messageR),
      );
    });

    test('speed accepted', () {
      for (final p in [
        x7000,
        const CartesianVector(14000.0, 0.0, 0.0),
        const CartesianVector(1e-100, 0.0, 0.0),
      ]) {
        final speed = _speed(p, 7000.0);
        expect(speed.isFinite, isTrue);
        expect(speed, greaterThanOrEqualTo(0.0));
      }
    });

    test('period throws N', () {
      for (final n in [nan, inf, -inf, 0.0, -0.0, -1e-3]) {
        expect(
          () => orbitalPeriodSFromMeanMotion(n),
          _argumentError(_messageN),
        );
      }
    });

    test('period accepted', () {
      for (final n in [7.27e-13, 1e-3]) {
        final period = orbitalPeriodSFromMeanMotion(n);
        expect(period.isFinite, isTrue);
        expect(period, greaterThan(0.0));
      }
    });

    test('inclination throws F', () {
      const v75 = CartesianVector(0.0, 7.5, 0.0);
      expect(
        () => _inclination(const CartesianVector(nan, 0.0, 0.0), v75),
        _argumentError(_messageF),
      );
      expect(
        () => _inclination(const CartesianVector(7000.0, inf, 0.0), v75),
        _argumentError(_messageF),
      );
      expect(
        () => _inclination(x7000, const CartesianVector(0.0, nan, 0.0)),
        _argumentError(_messageF),
      );
      expect(
        () => _inclination(x7000, const CartesianVector(0.0, 0.0, -inf)),
        _argumentError(_messageF),
      );
      expect(
        () => _inclination(const CartesianVector(nan, 0.0, 0.0), zero),
        _argumentError(_messageF),
      );
    });

    test('inclination throws H', () {
      expect(
        () => _inclination(zero, const CartesianVector(0.0, 7.5, 0.0)),
        _argumentError(_messageH),
      );
      for (final v in [
        zero,
        const CartesianVector(-0.0, 0.0, -0.0),
        const CartesianVector(7.5, 0.0, 0.0),
        const CartesianVector(-3.0, 0.0, 0.0),
      ]) {
        expect(() => _inclination(x7000, v), _argumentError(_messageH));
      }
      expect(
        () => _inclination(
          const CartesianVector(1e-200, 0.0, 0.0),
          const CartesianVector(0.0, 1e-200, 0.0),
        ),
        _argumentError(_messageH),
      );
    });

    test('inclination accepted', () {
      for (final v in [
        const CartesianVector(0.0, 7.5, 0.0),
        const CartesianVector(0.0, 1e-3, 0.0),
      ]) {
        final inclination = _inclination(x7000, v);
        expect(inclination.isFinite, isTrue);
        expect(inclination, inInclusiveRange(0.0, pi));
      }
    });
  });
}
