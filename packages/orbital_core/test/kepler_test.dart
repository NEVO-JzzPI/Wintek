import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_newton.py, commit e90b6f6584dd53330e71ee5496aea2eea3853f9b.
// Vallado repository, test_newton.py, newtonm row "Vallado Ex. 2-1": M = 235.4 deg, e = 0.4, E = 3.8486617450971616 rad.
// Vallado repository, kepler.py, commit c05278b458e806775c91d1fe74b5ff6e583c8d82, line 217: linear mean anomaly; rows derived under ADR-0004.
// Meeus, Astronomical Algorithms, 2nd ed., chapter 7: JD 2446822.5, 2447187.5, 2446966.0, 2447332.0, 2451179.5, 2451545.0; elapsed times derived under ADR-0004.
// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005 and 28129.

const double _twoPi = 2 * pi;

const String _messageU = 'Julian date conversion requires a UTC instant.';
const String _messageR =
    'Julian date conversion supports 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z only.';
const String _messageNM = 'Kepler solver requires a finite mean anomaly.';
const String _messageNE = 'Kepler solver requires a finite eccentricity.';
const String _messageRE =
    'Kepler solver supports eccentricity from 0 inclusive to 1 exclusive only.';

const String _line1Set00005 =
    '1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753';
const String _line2Set00005 =
    '2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667';
const String _line1Set28129 =
    '1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459';
const String _line2Set28129 =
    '2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443';

Matcher _throwsArgumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

/// The normalized angle of the spec's Definitions.
double _normalize(double angleRad) {
  final remainder = angleRad % _twoPi;
  return remainder == _twoPi ? 0.0 : remainder;
}

/// The residual of the spec's Definitions, in [-pi, pi).
double _residual(double eccentricAnomalyRad, double meanAnomalyRad, double e) {
  var residual = _normalize(
    eccentricAnomalyRad -
        e * sin(eccentricAnomalyRad) -
        _normalize(meanAnomalyRad),
  );
  if (residual >= pi) residual -= _twoPi;
  return residual;
}

double _elapsed(DateTime from, DateTime to) =>
    elapsedSeconds(JulianDate.fromUtc(from), JulianDate.fromUtc(to));

/// The three conditions shared by REQ-ORB-004.4 and the accepted rows of
/// REQ-ORB-004.5: it returns, it lies in [0, 2 pi) and it solves the equation.
void _expectSolves(double meanAnomalyRad, double e) {
  final result = eccentricAnomalyRad(meanAnomalyRad, e);
  final context = 'M = $meanAnomalyRad, e = $e, E = $result';
  expect(result, greaterThanOrEqualTo(0.0), reason: context);
  expect(result, lessThan(_twoPi), reason: context);
  expect(
    _residual(result, meanAnomalyRad, e).abs(),
    lessThanOrEqualTo(1e-12),
    reason: context,
  );
}

void main() {
  // REQ-ORB-004.1
  group('elapsed time between two-part Julian dates', () {
    final rows =
        <
          ({
            String source,
            DateTime from,
            DateTime to,
            double expected,
            double tolerance,
          })
        >[
          (
            // Derived: Meeus JD 2447187.5 - JD 2446822.5 = 365 days; 365 * 86400 s.
            source: 'Meeus 1987-01-27 to 1988-01-27',
            from: DateTime.utc(1987, 1, 27),
            to: DateTime.utc(1988, 1, 27),
            expected: 31536000.0,
            tolerance: 0.0,
          ),
          (
            // Derived: same pair, reversed; -365 * 86400 s.
            source: 'Meeus 1988-01-27 to 1987-01-27',
            from: DateTime.utc(1988, 1, 27),
            to: DateTime.utc(1987, 1, 27),
            expected: -31536000.0,
            tolerance: 0.0,
          ),
          (
            // Derived: Meeus JD 2447332.0 - JD 2446966.0 = 366 days; 366 * 86400 s.
            source: 'Meeus 1987-06-19T12 to 1988-06-19T12',
            from: DateTime.utc(1987, 6, 19, 12),
            to: DateTime.utc(1988, 6, 19, 12),
            expected: 31622400.0,
            tolerance: 0.0,
          ),
          (
            // Derived: Meeus JD 2451545.0 - JD 2451179.5 = 365 days plus 12 h;
            // 365.5 * 86400 s.
            source: 'Meeus 1999-01-01 to 2000-01-01T12',
            from: DateTime.utc(1999, 1, 1),
            to: DateTime.utc(2000, 1, 1, 12),
            expected: 31579200.0,
            tolerance: 0.0,
          ),
          (
            // Anchor row of ADR-0004, Amendment 1: equal dates.
            source: 'equal dates',
            from: DateTime.utc(2000, 1, 1, 12),
            to: DateTime.utc(2000, 1, 1, 12),
            expected: 0.0,
            tolerance: 0.0,
          ),
          (
            // Derived: 0 days plus a clock difference of 0.000001 s.
            source: 'one microsecond',
            from: DateTime.utc(2026, 3, 14),
            to: DateTime.utc(2026, 3, 14, 0, 0, 0, 0, 1),
            expected: 0.000001,
            tolerance: 1e-12,
          ),
          (
            // Derived: day parts 2488127.5 - 2415079.5 = 73048 days;
            // 73048 * 86400 s plus a clock difference of 86399.999999 s.
            source: 'whole valid range',
            from: DateTime.utc(1900, 3, 1),
            to: DateTime.utc(2100, 2, 28, 23, 59, 59, 999, 999),
            expected: 6311433599.999999,
            tolerance: 1e-5,
          ),
        ];

    for (final row in rows) {
      test(row.source, () {
        final actual = _elapsed(row.from, row.to);
        expect(
          actual,
          row.tolerance == 0.0
              ? equals(row.expected)
              : closeTo(row.expected, row.tolerance),
        );
      });
    }
  });

  // REQ-ORB-004.2
  group('mean anomaly at an instant', () {
    final set00005 = OrbitalElements.fromTle(_line1Set00005, _line2Set00005);
    final set28129 = OrbitalElements.fromTle(_line1Set28129, _line2Set28129);

    test('at the epoch the result is the element set mean anomaly exactly', () {
      final result = meanAnomalyAtRad(set00005, set00005.epoch);
      expect(result, equals(set00005.meanAnomalyRad));
      expect(result, equals(0.3373093125574321));
    });

    final rows =
        <({String source, OrbitalElements set, String utc, double expected})>[
          (
            // Derived: 19.3264 deg + 10.82419157 rev/day * 360 deg * 1 day, minus 10 revolutions.
            source: '00005 +1 day',
            set: set00005,
            utc: '2000-06-28T18:50:19.733568Z',
            expected: 5.515857675482708,
          ),
          (
            // Derived: 19.3264 deg - 10.82419157 * 360 deg * 1, plus 11 revolutions.
            source: '00005 -1 day',
            set: set00005,
            utc: '2000-06-26T18:50:19.733568Z',
            expected: 1.441946256811743,
          ),
          (
            // Derived: 19.3264 deg + 10.82419157 * 360 deg * 0.5, minus 5 revolutions.
            source: '00005 +12 hours',
            set: set00005,
            utc: '2000-06-28T06:50:19.733568Z',
            expected: 2.9265834940200697,
          ),
          (
            // Derived: 93.1663 deg + 2.00562768 * 360 deg * 30, minus 60 revolutions.
            source: '28129 +30 days',
            set: set28129,
            utc: '2006-07-24T13:41:49.461504Z',
            expected: 2.6868513755860453,
          ),
          (
            // Derived: 93.1663 deg - 2.00562768 * 360 deg * 30, plus 60 revolutions.
            source: '28129 -30 days',
            set: set28129,
            utc: '2006-05-25T13:41:49.461504Z',
            expected: 0.5652659982155406,
          ),
        ];

    for (final row in rows) {
      test(row.source, () {
        final result = meanAnomalyAtRad(row.set, DateTime.parse(row.utc));
        expect(result, closeTo(row.expected, 1e-10));
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThan(_twoPi));
      });
    }

    test('an instant that is not UTC throws message U', () {
      expect(
        () => meanAnomalyAtRad(set28129, DateTime(2006, 6, 24, 13, 41, 49)),
        _throwsArgumentError(_messageU),
      );
    });

    test('an instant outside the valid range throws message R', () {
      expect(
        () => meanAnomalyAtRad(set28129, DateTime.utc(2100, 3, 1)),
        _throwsArgumentError(_messageR),
      );
    });
  });

  // REQ-ORB-004.3
  group("Kepler's equation from published values", () {
    // Values in degrees are converted by multiplying by pi / 180.
    final rows = <({String source, double m, double e, double expected})>[
      (
        // test_newtonm, row labelled "Vallado Ex. 2-1".
        source: 'Vallado Ex. 2-1',
        m: 235.4 * pi / 180,
        e: 0.4,
        expected: 3.8486617450971616,
      ),
      (
        // test_newtone, elliptical row, read backwards.
        source: 'fourth quadrant',
        m: 6.011077700843401,
        e: 0.4,
        expected: 334.566986 * pi / 180,
      ),
      (
        // test_newtonnu, read backwards.
        source: 'low eccentricity',
        m: 37.31406335764441 * pi / 180,
        e: 0.1,
        expected: 41.078960346507934 * pi / 180,
      ),
      (
        // test_newtonm, circular row.
        source: 'circular',
        m: pi / 3,
        e: 0.0,
        expected: pi / 3,
      ),
      (
        // test_newtonm, near-parabolic row.
        source: 'near-parabolic at apoapsis',
        m: pi,
        e: 0.9999,
        expected: pi,
      ),
    ];

    for (final row in rows) {
      test(row.source, () {
        expect(eccentricAnomalyRad(row.m, row.e), closeTo(row.expected, 1e-11));
      });
    }
  });

  // REQ-ORB-004.4
  group('convergence, range and residual', () {
    const eccentricities = <double>[
      0.0,
      1e-7,
      0.001,
      0.1,
      0.4,
      0.7,
      0.9,
      0.99,
      0.999,
      0.9999,
      0.99999,
      0.999999,
      0.9999999,
    ];

    test('every eccentricity with every whole degree of mean anomaly', () {
      for (final e in eccentricities) {
        for (var k = 0; k < 360; k++) {
          _expectSolves(k * _twoPi / 360, e);
        }
      }
    });

    test('edge mean anomalies', () {
      const meanAnomalies = <double>[
        5e-324,
        1e-300,
        -1e-20,
        _twoPi - 1e-15,
        _twoPi,
        -_twoPi,
        pi,
        -pi,
        1e6,
        -1e6,
      ];
      for (final e in const [0.0, 1e-7, 0.5, 0.9999999]) {
        for (final m in meanAnomalies) {
          _expectSolves(m, e);
        }
      }
    });

    test('a circular orbit returns the normalized input exactly', () {
      for (var k = 0; k < 360; k++) {
        final m = k * _twoPi / 360;
        expect(eccentricAnomalyRad(m, 0.0), equals(_normalize(m)));
      }
      for (final m in const [
        5e-324,
        1e-300,
        -1e-20,
        _twoPi,
        -_twoPi,
        pi,
        1e6,
        -1e6,
      ]) {
        expect(eccentricAnomalyRad(m, 0.0), equals(_normalize(m)));
      }
    });

    test('the normalization of the Definitions', () {
      expect(_normalize(1e6), equals(5.925621140132833));
      expect(_normalize(-1e6), equals(0.3575641670467533));
    });
  });

  // REQ-ORB-004.5
  group('input validation', () {
    final rows = <({String source, double m, double e, String message})>[
      (source: 'NaN mean anomaly', m: double.nan, e: 0.4, message: _messageNM),
      (
        source: 'positive infinite mean anomaly',
        m: double.infinity,
        e: 0.4,
        message: _messageNM,
      ),
      (
        source: 'negative infinite mean anomaly',
        m: double.negativeInfinity,
        e: 0.4,
        message: _messageNM,
      ),
      (
        source: 'mean anomaly is checked first',
        m: double.nan,
        e: 2.0,
        message: _messageNM,
      ),
      (source: 'NaN eccentricity', m: 1.0, e: double.nan, message: _messageNE),
      (
        source: 'infinite eccentricity',
        m: 1.0,
        e: double.infinity,
        message: _messageNE,
      ),
      (source: 'eccentricity 1', m: 1.0, e: 1.0, message: _messageRE),
      (source: 'eccentricity 1.5', m: 1.0, e: 1.5, message: _messageRE),
      (source: 'negative eccentricity', m: 1.0, e: -1e-12, message: _messageRE),
    ];

    for (final row in rows) {
      test('${row.source} throws', () {
        expect(
          () => eccentricAnomalyRad(row.m, row.e),
          _throwsArgumentError(row.message),
        );
      });
    }

    test('negative zero eccentricity is accepted as 0.0', () {
      expect(eccentricAnomalyRad(1.0, -0.0), equals(1.0));
    });

    test('the largest eccentricity of a TLE is accepted', () {
      _expectSolves(1.0, 0.9999999);
    });
  });
}
