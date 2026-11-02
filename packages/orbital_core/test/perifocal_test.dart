import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.
// Vallado repository, test_frame_conversions.py, test_coe2rv "Vallado, 2022, Ex. 2-6": p = 11067.790 km, e = 0.83285, i = 87.87 deg, raan = 227.89 deg, argp = 53.38 deg, nu = 92.335 deg.
// Vallado repository, test_frame_conversions.py, test_perifocal_transform "From Vallado Example 2-6, 2022": P, Q and W unit vectors.
// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005 and 28129; semi-major axes derived under ADR-0005.

const double _muKm3S2 = 398600.4418;

const String _messageN =
    'Semi-major axis requires a finite mean motion greater than 0.';
const String _messageA =
    'State vector requires a finite semi-major axis greater than 0.';
const String _messageE =
    'State vector requires an eccentricity from 0 inclusive to 1 exclusive.';
const String _messageG = 'State vector requires finite angles.';

const String _line1Set00005 =
    '1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753';
const String _line2Set00005 =
    '2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667';
const String _line1Set28129 =
    '1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459';
const String _line2Set28129 =
    '2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443';

// Vallado, 2022, Ex. 2-6, in the units of the published fixture.
const double _pKm = 11067.790;
const double _ex26Eccentricity = 0.83285;
const double _ex26InclinationDeg = 87.87;
const double _ex26RaanDeg = 227.89;
const double _ex26ArgpDeg = 53.38;
const double _ex26TrueAnomalyDeg = 92.335;

const double _deg = pi / 180;
const double _ex26InclinationRad = _ex26InclinationDeg * _deg;
const double _ex26RaanRad = _ex26RaanDeg * _deg;
const double _ex26ArgpRad = _ex26ArgpDeg * _deg;

Matcher _throwsArgumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

List<double> _components(CartesianVector v) => [v.x, v.y, v.z];

double _length(List<double> v) => sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);

List<double> _cross(List<double> a, List<double> b) => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];

/// The orbit normal W of the Definitions.
List<double> _normal(double inclinationRad, double raanRad) => [
  sin(raanRad) * sin(inclinationRad),
  -cos(raanRad) * sin(inclinationRad),
  cos(inclinationRad),
];

StateVector _state({
  double a = 7000.0,
  double e = 0.1,
  double i = 1.0,
  double raan = 2.0,
  double argp = 3.0,
  double anomaly = 4.0,
}) => inertialStateVector(
  semiMajorAxisKm: a,
  eccentricity: e,
  inclinationRad: i,
  raanRad: raan,
  argumentOfPerigeeRad: argp,
  eccentricAnomalyRad: anomaly,
);

void _expectClose(
  List<double> actual,
  List<double> expected,
  double tolerance,
) {
  for (var k = 0; k < 3; k++) {
    expect(
      actual[k],
      closeTo(expected[k], tolerance),
      reason: 'component $k: $actual vs $expected',
    );
  }
}

void _expectRelativelyClose(
  double actual,
  double expected,
  double tolerance,
  String reason,
) {
  expect(
    (actual - expected).abs(),
    lessThanOrEqualTo(tolerance * expected.abs()),
    reason: '$reason: $actual vs $expected',
  );
}

bool _allFinite(StateVector state) => [
  ..._components(state.positionKm),
  ..._components(state.velocityKmS),
].every((value) => value.isFinite);

void main() {
  // REQ-ORB-005.1
  group('semi-major axis from mean motion', () {
    final set00005 = OrbitalElements.fromTle(_line1Set00005, _line2Set00005);
    final set28129 = OrbitalElements.fromTle(_line1Set28129, _line2Set28129);

    // Derived: T = 86400 / 10.82419157 = 7982.120368181917 s;
    // a = (398600.4418 * T^2 / (4 pi^2))^(1/3).
    test('set 00005', () {
      expect(
        semiMajorAxisKmFromMeanMotion(set00005.meanMotionRadS),
        closeTo(8632.531955915649, 1e-8),
      );
    });

    // Derived: T = 86400 / 2.00562768 = 43078.78319668983 s;
    // a = (398600.4418 * T^2 / (4 pi^2))^(1/3).
    test('set 28129', () {
      expect(
        semiMajorAxisKmFromMeanMotion(set28129.meanMotionRadS),
        closeTo(26560.421624650135, 1e-8),
      );
    });

    test('the smallest mean motion of a TLE gives a finite axis', () {
      final result = semiMajorAxisKmFromMeanMotion(1e-8 * 2 * pi / 86400);
      expect(result.isFinite, isTrue);
      expect(result, greaterThan(0.0));
    });

    test('the gravitational parameter is the WGS-84 value', () {
      expect(wgs84MuKm3S2, equals(398600.4418));
    });
  });

  // REQ-ORB-005.2
  group('inertial state vector from Vallado Ex. 2-6', () {
    test('position and velocity', () {
      const e = _ex26Eccentricity;
      final nuRad = _ex26TrueAnomalyDeg * _deg;
      final a = _pKm / (1 - e * e);
      final eccentricAnomaly =
          2 * atan(sqrt((1 - e) / (1 + e)) * tan(nuRad / 2));

      final state = _state(
        a: a,
        e: e,
        i: _ex26InclinationRad,
        raan: _ex26RaanRad,
        argp: _ex26ArgpRad,
        anomaly: eccentricAnomaly,
      );

      _expectClose(_components(state.positionKm), [
        6525.368120986091,
        6861.531834896055,
        6449.118614160162,
      ], 1e-6);
      _expectClose(_components(state.velocityKmS), [
        4.902278644574153,
        5.533139566279278,
        -1.9757100987916154,
      ], 1e-8);
    });
  });

  // REQ-ORB-005.3
  group('rotation axes from Vallado Ex. 2-6', () {
    StateVector unitState(double anomaly) => _state(
      a: 1.0,
      e: 0.0,
      i: _ex26InclinationRad,
      raan: _ex26RaanRad,
      argp: _ex26ArgpRad,
      anomaly: anomaly,
    );

    test('perigee direction P', () {
      _expectClose(_components(unitState(0.0).positionKm), [
        -0.37786007180211706,
        -0.46252560096516104,
        0.8020547578498088,
      ], 1e-12);
    });

    test('direction of motion Q', () {
      _expectClose(_components(unitState(pi / 2).positionKm), [
        0.5546417852962037,
        0.580556376955298,
        0.596092931664164,
      ], 1e-12);
    });

    test('orbit normal W', () {
      final state = unitState(0.0);
      final h = _cross(
        _components(state.positionKm),
        _components(state.velocityKmS),
      );
      final length = _length(h);
      _expectClose(
        [h[0] / length, h[1] / length, h[2] / length],
        [-0.7413462457860962, 0.6700928007584878, 0.03716695078301055],
        1e-12,
      );
    });
  });

  // REQ-ORB-005.4
  group('two-body identities over a grid', () {
    test('radius, vis-viva, angular momentum and normal', () {
      const axesKm = [6778.0, 26560.0, 42164.0];
      const eccentricities = [0.0, 1e-7, 0.1, 0.5, 0.9, 0.9999999];
      final angleSets = [
        [_ex26InclinationRad, _ex26RaanRad, _ex26ArgpRad],
        [0.0, 0.0, 0.0],
        [pi, 1.0, 2.0],
        [pi / 2, 3.0, 5.0],
      ];

      for (final a in axesKm) {
        for (final e in eccentricities) {
          for (final angles in angleSets) {
            for (var k = 0; k < 36; k++) {
              final anomaly = k * 2 * pi / 36;
              final context = 'a=$a e=$e angles=$angles E=$anomaly';
              final state = _state(
                a: a,
                e: e,
                i: angles[0],
                raan: angles[1],
                argp: angles[2],
                anomaly: anomaly,
              );
              final position = _components(state.positionKm);
              final velocity = _components(state.velocityKmS);
              final radius = _length(position);
              final h = _cross(position, velocity);

              _expectRelativelyClose(
                radius,
                a * (1 - e * cos(anomaly)),
                1e-13,
                'radius $context',
              );
              _expectRelativelyClose(
                _length(velocity) * _length(velocity),
                _muKm3S2 * (2 / radius - 1 / a),
                1e-7,
                'vis-viva $context',
              );
              _expectRelativelyClose(
                _length(h),
                sqrt(_muKm3S2 * a * (1 - e * e)),
                1e-11,
                'angular momentum $context',
              );
              final normal = _normal(angles[0], angles[1]);
              final hLength = _length(h);
              for (var c = 0; c < 3; c++) {
                expect(
                  h[c] / hLength,
                  closeTo(normal[c], 1e-11),
                  reason: 'normal component $c $context',
                );
              }
            }
          }
        }
      }
    });

    test('the largest reachable axis gives a finite state', () {
      final a = semiMajorAxisKmFromMeanMotion(1e-8 * 2 * pi / 86400);
      final state = _state(
        a: a,
        e: 0.9999999,
        i: 1.0,
        raan: 2.0,
        argp: 3.0,
        anomaly: 0.5,
      );
      expect(_allFinite(state), isTrue);
    });
  });

  // REQ-ORB-005.5
  group('input validation', () {
    final meanMotionRows = <({String source, double n})>[
      (source: 'NaN', n: double.nan),
      (source: 'positive infinity', n: double.infinity),
      (source: 'negative infinity', n: double.negativeInfinity),
      (source: '0.0', n: 0.0),
      (source: '-0.0', n: -0.0),
      (source: '-1e-12', n: -1e-12),
    ];

    for (final row in meanMotionRows) {
      test('mean motion ${row.source} throws message N', () {
        expect(
          () => semiMajorAxisKmFromMeanMotion(row.n),
          _throwsArgumentError(_messageN),
        );
      });
    }

    final stateRows =
        <({String source, StateVector Function() call, String message})>[
          (
            source: 'a = NaN',
            call: () => _state(a: double.nan),
            message: _messageA,
          ),
          (
            source: 'a = positive infinity',
            call: () => _state(a: double.infinity),
            message: _messageA,
          ),
          (source: 'a = 0.0', call: () => _state(a: 0.0), message: _messageA),
          (source: 'a = -1.0', call: () => _state(a: -1.0), message: _messageA),
          (
            source: 'a = NaN and e = 2.0 (a is checked first)',
            call: () => _state(a: double.nan, e: 2.0),
            message: _messageA,
          ),
          (
            source: 'e = NaN',
            call: () => _state(e: double.nan),
            message: _messageE,
          ),
          (source: 'e = 1.0', call: () => _state(e: 1.0), message: _messageE),
          (source: 'e = 1.5', call: () => _state(e: 1.5), message: _messageE),
          (
            source: 'e = -1e-12',
            call: () => _state(e: -1e-12),
            message: _messageE,
          ),
          (
            source: 'e = NaN and i = NaN (e is checked before the angles)',
            call: () => _state(e: double.nan, i: double.nan),
            message: _messageE,
          ),
          (
            source: 'i = NaN',
            call: () => _state(i: double.nan),
            message: _messageG,
          ),
          (
            source: 'raan = positive infinity',
            call: () => _state(raan: double.infinity),
            message: _messageG,
          ),
          (
            source: 'argp = negative infinity',
            call: () => _state(argp: double.negativeInfinity),
            message: _messageG,
          ),
          (
            source: 'E = NaN',
            call: () => _state(anomaly: double.nan),
            message: _messageG,
          ),
        ];

    for (final row in stateRows) {
      test('state vector ${row.source} throws', () {
        expect(row.call, _throwsArgumentError(row.message));
      });
    }

    test('negative zero eccentricity gives the result of 0.0 exactly', () {
      final negative = _state(e: -0.0);
      final zero = _state(e: 0.0);
      expect(
        _components(negative.positionKm),
        equals(_components(zero.positionKm)),
      );
      expect(
        _components(negative.velocityKmS),
        equals(_components(zero.velocityKmS)),
      );
    });

    test('the largest eccentricity of a TLE is accepted', () {
      expect(_allFinite(_state(e: 0.9999999)), isTrue);
    });
  });
}
