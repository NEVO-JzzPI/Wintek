import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

const double _twoPi = 2 * pi;

double _gmst(DateTime utc) => gmstRad(JulianDate.fromUtc(utc));

void main() {
  // REQ-ORB-002.1
  group('GMST from a two-part Julian date', () {
    final rows = <({String source, DateTime utc, double gmstRad})>[
      (
        // SOFA/ERFA t_erfa_c.c, test t_gmst82: JD 2400000.5 + 53736.0 (2006-01-01T00:00:00 UT1) = 1.754174981860675096 rad.
        source: 'SOFA t_gmst82 2006-01-01T00:00:00Z',
        utc: DateTime.utc(2006, 1, 1),
        gmstRad: 1.754174981860675096,
      ),
      (
        // Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., eq. 3-45, p. 187: 67310.54841 s at T = 0.
        source: 'Vallado constant term at J2000.0',
        utc: DateTime.utc(2000, 1, 1, 12),
        gmstRad: 4.894961212823059,
      ),
    ];

    for (final row in rows) {
      test(row.source, () {
        expect(_gmst(row.utc), closeTo(row.gmstRad, 1e-10));
      });
    }
  });

  // REQ-ORB-002.2
  group('result range', () {
    final instants = <String, DateTime>{
      'first valid instant': DateTime.utc(1900, 3, 1),
      'last valid instant': DateTime.utc(2100, 2, 28, 23, 59, 59, 999, 999),
      'J2000.0': DateTime.utc(2000, 1, 1, 12),
      'negative T': DateTime.utc(1992, 8, 20, 12, 14),
      'SOFA instant': DateTime.utc(2006, 1, 1),
      'one microsecond after midnight': DateTime.utc(
        2026,
        3,
        14,
        0,
        0,
        0,
        0,
        1,
      ),
    };

    instants.forEach((name, utc) {
      test(name, () {
        final gmst = _gmst(utc);
        expect(gmst, greaterThanOrEqualTo(0.0));
        expect(gmst, lessThan(_twoPi));
      });
    });
  });

  // REQ-ORB-002.3
  group('sidereal advance per solar day', () {
    // Linear coefficient of the polynomial: 8640184.812866 s / 36525 days,
    // converted to radians (Vallado, 4th ed., eq. 3-45, p. 187).
    const dailyAdvanceRad = 0.017202791805307;

    final pairs = <({DateTime first, DateTime second})>[
      (first: DateTime.utc(1987, 4, 10), second: DateTime.utc(1987, 4, 11)),
      (first: DateTime.utc(1999, 12, 31), second: DateTime.utc(2000, 1, 1)),
      (first: DateTime.utc(2024, 2, 28), second: DateTime.utc(2024, 2, 29)),
      (first: DateTime.utc(2100, 2, 27), second: DateTime.utc(2100, 2, 28)),
    ];

    for (final pair in pairs) {
      test(
        '${pair.first.toIso8601String()} to ${pair.second.toIso8601String()}',
        () {
          final difference = (_gmst(pair.second) - _gmst(pair.first)) % _twoPi;
          expect(difference, closeTo(dailyAdvanceRad, 1.75e-9));
        },
      );
    }
  });
}
