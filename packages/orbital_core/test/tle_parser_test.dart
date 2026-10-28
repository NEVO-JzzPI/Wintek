import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// CelesTrak, NORAD Two-Line Element Set Format, https://celestrak.org/NORAD/documentation/tle-fmt.php: NOAA 14 (23455) example.
const _noaaLine1 =
    '1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621';
const _noaaLine2 =
    '2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148495';

// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005, 23599 and 28129.
const _set00005Line1 =
    '1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753';
const _set00005Line2 =
    '2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667';
const _set23599Line1 =
    '1 23599U 95029B   06171.76535463  .00085586  12891-6  12956-2 0  2905';
const _set23599Line2 =
    '2 23599   6.9327   0.2849 5782022 274.4436  25.2425  4.47796565123555';
const _set28129Line1 =
    '1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459';
const _set28129Line2 =
    '2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443';

// Vallado et al., AIAA 2006-6753, SGP4.cpp twoline2rv: deg2rad = pi / 180, xpdotp = 1440 / (2 pi), years below 57 are 2000 + yy.
// Vallado et al., AIAA 2006-6753, TestSGP4/00005.e, 23599.e, 28129.e: ScenarioEpoch of each set.

const _noaaChecksumLine1 =
    '1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2622';
const _noaaChecksumLine2 =
    '2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148496';

Matcher _close(double expected) =>
    expected == 0.0 ? equals(0.0) : closeTo(expected, expected.abs() * 1e-12);

Matcher _throwsFormat(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', message),
);

OrbitalElements _parse(String line1, String line2) =>
    OrbitalElements.fromTle(line1, line2);

void main() {
  // REQ-ORB-003.1
  group('parse published element sets', () {
    final rows =
        <
          ({
            String name,
            String line1,
            String line2,
            int catalogNumber,
            double inclinationRad,
            double raanRad,
            double eccentricity,
            double argumentOfPerigeeRad,
            double meanAnomalyRad,
            double meanMotionRadS,
            double ndotOver2RadS2,
            double nddotOver6RadS3,
            double bstar,
          })
        >[
          (
            name: 'NOAA 14',
            line1: _noaaLine1,
            line2: _noaaLine2,
            catalogNumber: 23455,
            inclinationRad: 1.7280330391070657,
            raanRad: 4.759067811229278,
            eccentricity: 0.0008546,
            argumentOfPerigeeRad: 3.895026857066217,
            meanAnomalyRad: 2.38903460539787,
            meanMotionRadS: 0.001026625753092966,
            ndotOver2RadS2: 1.178366586030122e-15,
            nddotOver6RadS3: 0.0,
            bstar: 1.0191e-4,
          ),
          (
            name: '00005',
            line1: _set00005Line1,
            line2: _set00005Line2,
            catalogNumber: 5,
            inclinationRad: 0.5980929187319208,
            raanRad: 6.08638547138321,
            eccentricity: 0.1859667,
            argumentOfPerigeeRad: 5.790416027488515,
            meanAnomalyRad: 0.3373093125574321,
            meanMotionRadS: 0.000787157424012976,
            ndotOver2RadS2: 1.935887962763772e-16,
            nddotOver6RadS3: 0.0,
            bstar: 2.8098e-5,
          ),
          (
            name: '23599',
            line1: _set23599Line1,
            line2: _set23599Line2,
            catalogNumber: 23599,
            inclinationRad: 0.12099844105301087,
            raanRad: 0.004972443038931845,
            eccentricity: 0.5782022,
            argumentOfPerigeeRad: 4.78994443102631,
            meanAnomalyRad: 0.44056473643466865,
            meanMotionRadS: 0.00032564685159878337,
            ndotOver2RadS2: 7.203691616569574e-13,
            nddotOver6RadS3: 1.2558137946853755e-21,
            bstar: 1.2956e-3,
          ),
          (
            name: '28129',
            line1: _set28129Line1,
            line2: _set28129Line2,
            catalogNumber: 28129,
            inclinationRad: 0.9552152089579925,
            raanRad: 5.669000452744278,
            eccentricity: 0.0048506,
            argumentOfPerigeeRad: 4.647183479530182,
            meanAnomalyRad: 1.6260586869007931,
            meanMotionRadS: 0.00014585336077139677,
            ndotOver2RadS2: -8.753580353366621e-16,
            nddotOver6RadS3: 0.0,
            bstar: 1.0e-4,
          ),
        ];

    for (final row in rows) {
      test(row.name, () {
        final elements = _parse(row.line1, row.line2);
        expect(elements.catalogNumber, row.catalogNumber);
        expect(elements.inclinationRad, _close(row.inclinationRad));
        expect(elements.raanRad, _close(row.raanRad));
        expect(elements.eccentricity, _close(row.eccentricity));
        expect(elements.argumentOfPerigeeRad, _close(row.argumentOfPerigeeRad));
        expect(elements.meanAnomalyRad, _close(row.meanAnomalyRad));
        expect(elements.meanMotionRadS, _close(row.meanMotionRadS));
        expect(elements.ndotOver2RadS2, _close(row.ndotOver2RadS2));
        expect(elements.nddotOver6RadS3, _close(row.nddotOver6RadS3));
        expect(elements.bstarInverseEarthRadii, _close(row.bstar));
      });
    }
  });

  // REQ-ORB-003.2
  group('epoch', () {
    final rows = <({String name, String line1, String line2, DateTime epoch})>[
      (
        name: 'NOAA 14, year 97 is 1997',
        line1: _noaaLine1,
        line2: _noaaLine2,
        epoch: DateTime.utc(1997, 11, 16, 21, 49, 37, 360, 416),
      ),
      (
        name: '00005, year 00 is 2000',
        line1: _set00005Line1,
        line2: _set00005Line2,
        epoch: DateTime.utc(2000, 6, 27, 18, 50, 19, 733, 568),
      ),
      (
        name: '23599, year 06 is 2006',
        line1: _set23599Line1,
        line2: _set23599Line2,
        epoch: DateTime.utc(2006, 6, 20, 18, 22, 6, 640, 32),
      ),
      (
        name: '28129, fraction resolved to the microsecond',
        line1: _set28129Line1,
        line2: _set28129Line2,
        epoch: DateTime.utc(2006, 6, 24, 13, 41, 49, 461, 504),
      ),
      (
        name: 'derived: year 57 is 1957',
        line1: '1 23455U 94089A   57320.90946019  .00000140  00000-0  10191-3 0  2627',
        line2: _noaaLine2,
        epoch: DateTime.utc(1957, 11, 16, 21, 49, 37, 360, 416),
      ),
      (
        name: 'derived: year 56 is 2056, day 320 of a leap year',
        line1: '1 23455U 94089A   56320.90946019  .00000140  00000-0  10191-3 0  2626',
        line2: _noaaLine2,
        epoch: DateTime.utc(2056, 11, 15, 21, 49, 37, 360, 416),
      ),
      (
        name: 'derived: day 366 of a leap year',
        line1: '1 00005U 58002B   00366.78495062  .00000023  00000-0  28098-4 0  4751',
        line2: _set00005Line2,
        epoch: DateTime.utc(2000, 12, 31, 18, 50, 19, 733, 568),
      ),
    ];

    for (final row in rows) {
      test(row.name, () {
        final elements = _parse(row.line1, row.line2);
        expect(elements.epoch, row.epoch);
        expect(() => JulianDate.fromUtc(elements.epoch), returnsNormally);
      });
    }
  });

  // REQ-ORB-003.3
  group('checksum', () {
    test('minus signs count 1: set 28129 is accepted', () {
      expect(() => _parse(_set28129Line1, _set28129Line2), returnsNormally);
    });

    test('line 1 with a wrong checksum', () {
      expect(
        () => _parse(_noaaChecksumLine1, _noaaLine2),
        _throwsFormat('TLE line 1 has an invalid checksum.'),
      );
    });

    test('line 2 with a wrong checksum', () {
      expect(
        () => _parse(_noaaLine1, _noaaChecksumLine2),
        _throwsFormat('TLE line 2 has an invalid checksum.'),
      );
    });

    test('a minus sign changed to a plus sign without fixing the checksum', () {
      expect(
        () => _parse(
          '1 28129U 03058A   06175.57071136 +.00000104  00000-0  10000-3 0   459',
          _set28129Line2,
        ),
        _throwsFormat('TLE line 1 has an invalid checksum.'),
      );
    });

    test('a plus sign with the checksum recomputed', () {
      final elements = _parse(
        '1 28129U 03058A   06175.57071136 +.00000104  00000-0  10000-3 0   458',
        _set28129Line2,
      );
      expect(elements.ndotOver2RadS2, _close(8.753580353366621e-16));
    });
  });

  // REQ-ORB-003.4
  group('structural validation', () {
    const asciiMessage1 =
        'TLE line 1 must contain printable ASCII characters only.';
    const asciiMessage2 =
        'TLE line 2 must contain printable ASCII characters only.';

    test('a byte order mark before line 1', () {
      expect(
        () => _parse('﻿$_noaaLine1', _noaaLine2),
        _throwsFormat(asciiMessage1),
      );
    });

    test('a tab inside line 1', () {
      expect(
        () => _parse(_noaaLine1.replaceRange(32, 33, '\t'), _noaaLine2),
        _throwsFormat(asciiMessage1),
      );
    });

    test('a degree sign inside line 2', () {
      expect(
        () => _parse(_noaaLine1, _noaaLine2.replaceRange(16, 17, '°')),
        _throwsFormat(asciiMessage2),
      );
    });

    test('line 1 of 68 characters', () {
      expect(
        () => _parse(_noaaLine1.substring(0, 68), _noaaLine2),
        _throwsFormat('TLE line 1 must be 69 characters long.'),
      );
    });

    test('line 1 of 70 characters', () {
      expect(
        () => _parse('${_noaaLine1}0', _noaaLine2),
        _throwsFormat('TLE line 1 must be 69 characters long.'),
      );
    });

    test('CR and trailing blanks are removed before the checks', () {
      final cleaned = _parse('$_noaaLine1\r', '$_noaaLine2  \r');
      expect(cleaned, _parse(_noaaLine1, _noaaLine2));
    });

    test('line 2 passed as line 1', () {
      expect(
        () => _parse(_noaaLine2, _noaaLine2),
        _throwsFormat('TLE line 1 must start with "1 ".'),
      );
    });

    test('line 1 passed as line 2', () {
      expect(
        () => _parse(_noaaLine1, _noaaLine1),
        _throwsFormat('TLE line 2 must start with "2 ".'),
      );
    });

    test('line 2 of 68 characters', () {
      expect(
        () => _parse(_noaaLine1, _noaaLine2.substring(0, 68)),
        _throwsFormat('TLE line 2 must be 69 characters long.'),
      );
    });

    test('different catalog numbers', () {
      expect(
        () => _parse(
          _noaaLine1,
          '2 23456  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148496',
        ),
        _throwsFormat('TLE lines 1 and 2 must have the same catalog number.'),
      );
    });

    test('line 1 is checked before line 2', () {
      expect(
        () => _parse(_noaaLine1.substring(0, 68), _noaaChecksumLine2),
        _throwsFormat('TLE line 1 must be 69 characters long.'),
      );
    });

    test('structure is checked before fields', () {
      expect(
        () => _parse(
          '1 23455U 94089A   97320.90946019  .00000140  00000-0  1019 -3 0  2620',
          _noaaChecksumLine2,
        ),
        _throwsFormat('TLE line 2 has an invalid checksum.'),
      );
    });

    test('both lines empty', () {
      expect(
        () => _parse('', ''),
        _throwsFormat('TLE line 1 must be 69 characters long.'),
      );
    });
  });

  // REQ-ORB-003.5
  group('field validation', () {
    const invalid1 = 'TLE line 1 has an invalid';
    const outOfRange1 = 'TLE line 1 has an out-of-range';
    const invalid2 = 'TLE line 2 has an invalid';
    const outOfRange2 = 'TLE line 2 has an out-of-range';

    final line1Rows = <({String line1, String prefix, String field})>[
      (
        line1: '1 2345AU 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2626',
        prefix: invalid1,
        field: 'catalog number',
      ),
      (
        line1: '1 23455U 94089A   9 320.90946019  .00000140  00000-0  10191-3 0  2624',
        prefix: invalid1,
        field: 'epoch year',
      ),
      (
        line1: '1 23455U 94089A   97000.90946019  .00000140  00000-0  10191-3 0  2626',
        prefix: outOfRange1,
        field: 'epoch day',
      ),
      (
        line1: '1 23455U 94089A   97366.90946019  .00000140  00000-0  10191-3 0  2621',
        prefix: outOfRange1,
        field: 'epoch day',
      ),
      (
        line1: '1 23455U 94089A   97320.90946019  .00000140  00000x0  10191-3 0  2620',
        prefix: invalid1,
        field: 'second derivative of mean motion',
      ),
      (
        line1: '1 23455U 94089A   97320.90946019  .00000140  00000-0  1019 -3 0  2620',
        prefix: invalid1,
        field: 'B*',
      ),
    ];

    for (final row in line1Rows) {
      test('line 1: ${row.prefix} ${row.field} field', () {
        expect(
          () => _parse(row.line1, _noaaLine2),
          _throwsFormat('${row.prefix} ${row.field} field.'),
        );
      });
    }

    final line2Rows = <({String line2, String prefix, String field})>[
      (
        line2: '2 23455 180.0001 272.6745 0008546 223.1686 136.8816 14.11711747148498',
        prefix: outOfRange2,
        field: 'inclination',
      ),
      (
        line2: '2 23455  99.0090 360.0000 0008546 223.1686 136.8816 14.11711747148491',
        prefix: outOfRange2,
        field: 'right ascension of the ascending node',
      ),
      (
        line2: '2 23455  99.0090 272.6745 0 08546 223.1686 136.8816 14.11711747148495',
        prefix: invalid2,
        field: 'eccentricity',
      ),
      (
        line2: '2 23455  99.0090 272.6745 0008546 223.1686 136.8816  0.00000000148491',
        prefix: outOfRange2,
        field: 'mean motion',
      ),
    ];

    for (final row in line2Rows) {
      test('line 2: ${row.prefix} ${row.field} field', () {
        expect(
          () => _parse(_noaaLine1, row.line2),
          _throwsFormat('${row.prefix} ${row.field} field.'),
        );
      });
    }

    test('inclination of exactly 180 degrees is accepted', () {
      final elements = _parse(
        _noaaLine1,
        '2 23455 180.0000 272.6745 0008546 223.1686 136.8816 14.11711747148497',
      );
      expect(elements.inclinationRad, _close(3.141592653589793));
    });
  });
}
