import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

const String _messageU = 'Julian date conversion requires a UTC instant.';
const String _messageR =
    'Julian date conversion supports 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z only.';

Matcher _throwsArgumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

double _dayPart(DateTime utc) => JulianDate.fromUtc(utc).dayPart;

void main() {
  // REQ-ORB-001.1
  group('UTC instant to two-part Julian date', () {
    final rows =
        <
          ({
            String source,
            DateTime utc,
            double dayPart,
            double fractionPart,
            double tolerance,
          })
        >[
          (
            // Vallado, 4th ed., ch. 3: 1996-10-26T14:20:00Z = JD 2450383.09722222.
            source: 'Vallado 1996-10-26T14:20:00Z',
            utc: DateTime.utc(1996, 10, 26, 14, 20),
            dayPart: 2450382.5,
            fractionPart: 0.59722222,
            tolerance: 1e-8,
          ),
          (
            // Vallado, 4th ed., ch. 3 (GMST example): 1992-08-20T12:14:00Z =
            // JD 2448855.009722.
            source: 'Vallado 1992-08-20T12:14:00Z',
            utc: DateTime.utc(1992, 8, 20, 12, 14),
            dayPart: 2448854.5,
            fractionPart: 0.509722,
            tolerance: 1e-6,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 1957 October 4.81 = JD 2436116.31.
            source: 'Meeus 1957-10-04T19:26:24Z',
            utc: DateTime.utc(1957, 10, 4, 19, 26, 24),
            dayPart: 2436115.5,
            fractionPart: 0.81,
            tolerance: 1e-12,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 1987 January 27.0 = JD 2446822.5.
            source: 'Meeus 1987-01-27T00:00:00Z',
            utc: DateTime.utc(1987, 1, 27),
            dayPart: 2446822.5,
            fractionPart: 0.0,
            tolerance: 0.0,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 1987 June 19.5 = JD 2446966.0.
            source: 'Meeus 1987-06-19T12:00:00Z',
            utc: DateTime.utc(1987, 6, 19, 12),
            dayPart: 2446965.5,
            fractionPart: 0.5,
            tolerance: 0.0,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 1988 January 27.0 = JD 2447187.5.
            source: 'Meeus 1988-01-27T00:00:00Z',
            utc: DateTime.utc(1988, 1, 27),
            dayPart: 2447187.5,
            fractionPart: 0.0,
            tolerance: 0.0,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 1988 June 19.5 = JD 2447332.0.
            source: 'Meeus 1988-06-19T12:00:00Z',
            utc: DateTime.utc(1988, 6, 19, 12),
            dayPart: 2447331.5,
            fractionPart: 0.5,
            tolerance: 0.0,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 1999 January 1.0 = JD 2451179.5.
            source: 'Meeus 1999-01-01T00:00:00Z',
            utc: DateTime.utc(1999, 1, 1),
            dayPart: 2451179.5,
            fractionPart: 0.0,
            tolerance: 0.0,
          ),
          (
            // Meeus, 2nd ed., ch. 7: 2000 January 1.5 = JD 2451545.0 (J2000.0).
            source: 'Meeus 2000-01-01T12:00:00Z',
            utc: DateTime.utc(2000, 1, 1, 12),
            dayPart: 2451544.5,
            fractionPart: 0.5,
            tolerance: 0.0,
          ),
          (
            // Definition of the fraction part: one microsecond / 86 400 s.
            source: 'one microsecond after 2026-03-14T00:00:00Z',
            utc: DateTime.utc(2026, 3, 14, 0, 0, 0, 0, 1),
            dayPart: 2461113.5,
            fractionPart: 0.000001 / 86400,
            tolerance: 1e-20,
          ),
        ];

    for (final row in rows) {
      test(row.source, () {
        final jd = JulianDate.fromUtc(row.utc);
        expect(jd.dayPart, row.dayPart);
        expect(jd.fractionPart, closeTo(row.fractionPart, row.tolerance));
        expect(
          jd.dayPart - 0.5,
          (jd.dayPart - 0.5).floorToDouble(),
          reason: 'day part must end in .5',
        );
        expect(jd.fractionPart, greaterThanOrEqualTo(0.0));
        expect(jd.fractionPart, lessThan(1.0));
      });
    }
  });

  // REQ-ORB-001.2
  group('calendar invariants', () {
    // Anchored to Meeus, 2nd ed., ch. 7 (1900 January 1.0 = JD 2415020.5) and
    // to J2000.0; no new formula.
    final rows =
        <({String proves, DateTime first, DateTime second, double diff})>[
          (
            proves: 'year rollover',
            first: DateTime.utc(1999, 12, 31),
            second: DateTime.utc(2000, 1, 1),
            diff: 1.0,
          ),
          (
            proves: '2000 is a leap year (divisible by 400)',
            first: DateTime.utc(2000, 2, 28),
            second: DateTime.utc(2000, 2, 29),
            diff: 1.0,
          ),
          (
            proves: 'leap day to March 2000',
            first: DateTime.utc(2000, 2, 29),
            second: DateTime.utc(2000, 3, 1),
            diff: 1.0,
          ),
          (
            proves: '2024 is a leap year',
            first: DateTime.utc(2024, 2, 28),
            second: DateTime.utc(2024, 2, 29),
            diff: 1.0,
          ),
          (
            proves: 'leap day to March 2024',
            first: DateTime.utc(2024, 2, 29),
            second: DateTime.utc(2024, 3, 1),
            diff: 1.0,
          ),
          (
            proves: '2023 is not a leap year',
            first: DateTime.utc(2023, 2, 28),
            second: DateTime.utc(2023, 3, 1),
            diff: 1.0,
          ),
          (
            proves: 'February 2000 has 29 days',
            first: DateTime.utc(2000, 2, 28),
            second: DateTime.utc(2000, 3, 1),
            diff: 2.0,
          ),
        ];

    for (final row in rows) {
      test(row.proves, () {
        expect(_dayPart(row.second) - _dayPart(row.first), row.diff);
      });
    }
  });

  // REQ-ORB-001.3
  group('Julian centuries since J2000.0', () {
    test('J2000.0 is exactly zero (definition of J2000.0)', () {
      expect(
        JulianDate.fromUtc(DateTime.utc(2000, 1, 1, 12)).julianCenturies,
        0.0,
      );
    });

    test('Vallado 4th ed., ch. 3 (GMST example): T_UT1 = -0.073647919', () {
      expect(
        JulianDate.fromUtc(DateTime.utc(1992, 8, 20, 12, 14)).julianCenturies,
        closeTo(-0.073647919, 1e-9),
      );
    });

    test('one Julian century (36 525 days) after J2000.0 is 1.0', () {
      expect(
        JulianDate.fromUtc(DateTime.utc(2100, 1, 1, 12)).julianCenturies,
        closeTo(1.0, 1e-12),
      );
    });

    test('instants before J2000.0 give negative T', () {
      expect(
        JulianDate.fromUtc(DateTime.utc(1900, 3, 1)).julianCenturies,
        lessThan(0.0),
      );
    });
  });

  // REQ-ORB-001.4
  group('input validation', () {
    test('non-UTC instant throws U', () {
      expect(
        () => JulianDate.fromUtc(DateTime(2026, 3, 14, 10)),
        _throwsArgumentError(_messageU),
      );
    });

    test('non-UTC and out of range throws U (UTC check runs first)', () {
      expect(
        () => JulianDate.fromUtc(DateTime(1850, 1, 1)),
        _throwsArgumentError(_messageU),
      );
    });

    test('one microsecond before the valid range throws R', () {
      expect(
        () =>
            JulianDate.fromUtc(DateTime.utc(1900, 2, 28, 23, 59, 59, 999, 999)),
        _throwsArgumentError(_messageR),
      );
    });

    test('1900-01-01 throws R', () {
      expect(
        () => JulianDate.fromUtc(DateTime.utc(1900, 1, 1)),
        _throwsArgumentError(_messageR),
      );
    });

    test('2100-03-01 throws R', () {
      expect(
        () => JulianDate.fromUtc(DateTime.utc(2100, 3, 1)),
        _throwsArgumentError(_messageR),
      );
    });

    test('lower bound is accepted', () {
      // Meeus, 2nd ed., ch. 7: 1900 January 1.0 = JD 2415020.5, plus 59 days
      // (31 of January and 28 of February; 1900 is not a leap year).
      final jd = JulianDate.fromUtc(DateTime.utc(1900, 3, 1));
      expect(jd.dayPart, 2415079.5);
      expect(jd.fractionPart, 0.0);
    });

    test('upper bound is accepted', () {
      // J2000.0 day part 2451544.5 + 36525.0 (one Julian century, to
      // 2100-01-01) + 58.0 (31 days of January and 27 of February).
      final jd = JulianDate.fromUtc(
        DateTime.utc(2100, 2, 28, 23, 59, 59, 999, 999),
      );
      expect(jd.dayPart, 2488127.5);
      expect(jd.fractionPart, closeTo(86399.999999 / 86400, 1e-15));
      expect(jd.fractionPart, lessThan(1.0));
    });
  });
}
