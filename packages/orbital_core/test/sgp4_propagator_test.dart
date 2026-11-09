import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

import 'sgp4_verification_data.dart';

// Vallado, Crawford, Hujsak and Kelso, Revisiting Spacetrack Report #3, AIAA 2006-6753: SGP4-VER.TLE and tcppver.out.
// SGP4-VER.TLE: https://celestrak.org/publications/AIAA/2006-6753/AIAA-2006-6753.zip, sgp4/cpp/testsgp4/SGP4-VER.TLE, line endings converted to LF.
// tcppver.out: https://github.com/brandon-rhodes/python-sgp4, sgp4/tcppver.out at commit 0f06a9147333e5a82197b5c04f5e87b477deca9e.
// Synthetic 180-degree element set: NOAA 14 with inclination 180.0000, built for specs/req-orb-010.md with valid checksums; not a published object.

const double _positionToleranceKm = 1e-6;
const double _velocityToleranceKmS = 2e-9;

const String _messageU = 'Julian date conversion requires a UTC instant.';
const String _messageR =
    'Julian date conversion supports 1900-03-01T00:00:00.000000Z '
    'through 2100-02-28T23:59:59.999999Z only.';
const String _messageC = 'TLE line 1 has an invalid checksum.';
const String _messageI = 'SGP4 cannot initialize the element set.';
String _messageE(int code) =>
    'SGP4 cannot propagate the element set to the instant: error code $code.';

const String _noaa14Line1 =
    '1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621';
const String _noaa14Line2 =
    '2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148495';
const String _synthetic180Line2 =
    '2 23455 180.0000 272.6745 0008546 223.1686 136.8816 14.11711747148497';

// The three entries of SGP4-VER.TLE whose line 1 checksum is invalid.
const List<List<String>> _rejectedEntries = [
  [
    '1 33333U 05037B   05333.02012661  .25992681  00000-0  24476-3 0  1534',
    '2 33333  96.4736 157.9986 9950000 244.0492 110.6523  4.00004038 10708',
  ],
  [
    '1 33334U 78066F   06174.85818871  .00000620  00000-0  10000-3 0  6809',
    '2 33334  68.4714 236.1303 5602877 123.7484 302.5767  0.00001000 67521',
  ],
  [
    '1 33335U 05008A   06176.46683397 -.00000205  00000-0  10000-3 0  2190',
    '2 33335   0.0019 286.9433 0000004  13.7918  55.6504  1.00270176  4891',
  ],
];

/// One accepted set of the verification data: its elements and its rows.
final class _VerificationSet {
  _VerificationSet(List<String> lines)
    : elements = OrbitalElements.fromTle(lines[0], lines[1]),
      rows = [
        for (final row in lines.skip(2))
          row.split(' ').map(double.parse).toList(),
      ];

  final OrbitalElements elements;
  final List<List<double>> rows;

  DateTime instantAt(double tsinceMinutes) =>
      elements.epoch.add(Duration(microseconds: (tsinceMinutes * 6e7).round()));
}

List<_VerificationSet> _sets() => [
  for (final lines in sgp4VerificationSets) _VerificationSet(lines),
];

List<double> _tenNumbers(PropagatedState state) => [
  state.inertialState.positionKm.x,
  state.inertialState.positionKm.y,
  state.inertialState.positionKm.z,
  state.inertialState.velocityKmS.x,
  state.inertialState.velocityKmS.y,
  state.inertialState.velocityKmS.z,
  state.ecefPositionKm.x,
  state.ecefPositionKm.y,
  state.ecefPositionKm.z,
  state.gmstRad,
];

void _expectArgumentError(
  Propagator propagator,
  DateTime instant,
  String message,
) {
  Object? thrown;
  try {
    propagator.stateAt(instant);
  } catch (error) {
    thrown = error;
  }
  expect(thrown, isA<ArgumentError>());
  expect((thrown as ArgumentError).message, message);
}

void _expectFailure(Propagator propagator, DateTime instant, String message) {
  Object? thrown;
  try {
    propagator.stateAt(instant);
  } catch (error) {
    thrown = error;
  }
  expect(thrown, isA<PropagationException>());
  expect((thrown as PropagationException).message, message);
}

void main() {
  // REQ-ORB-010.1
  test('the adapter reproduces the official vectors of tcppver.out', () {
    var setCount = 0;
    var rowCount = 0;
    for (final set in _sets()) {
      final propagator = Sgp4Propagator(set.elements);
      for (final row in set.rows) {
        final state = propagator.stateAt(set.instantAt(row[0]));
        final r = state.inertialState.positionKm;
        final v = state.inertialState.velocityKmS;
        final where = 'catalog ${set.elements.catalogNumber}, tsince ${row[0]}';
        expect(r.x, closeTo(row[1], _positionToleranceKm), reason: where);
        expect(r.y, closeTo(row[2], _positionToleranceKm), reason: where);
        expect(r.z, closeTo(row[3], _positionToleranceKm), reason: where);
        expect(v.x, closeTo(row[4], _velocityToleranceKmS), reason: where);
        expect(v.y, closeTo(row[5], _velocityToleranceKmS), reason: where);
        expect(v.z, closeTo(row[6], _velocityToleranceKmS), reason: where);
        rowCount++;
      }
      setCount++;
    }
    expect(setCount, 30);
    expect(rowCount, 588);
  });

  // REQ-ORB-010.2
  test('SGP4 error codes become the PropagationException of the seam', () {
    final sets = _sets();
    const cases = <(int, double, int)>[
      (12, 494.2028672, 1),
      (23, 1560, 1),
      (26, 55, 6),
      (27, 440, 6),
      (30, 1844345, 6),
    ];
    for (final (position, tsince, code) in cases) {
      final set = sets[position - 1];
      _expectFailure(
        Sgp4Propagator(set.elements),
        set.instantAt(tsince),
        _messageE(code),
      );
    }
  });

  // REQ-ORB-010.3
  test('the entries with an invalid checksum are rejected by the parser', () {
    for (final entry in _rejectedEntries) {
      expect(
        () => OrbitalElements.fromTle(entry[0], entry[1]),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', _messageC),
        ),
      );
    }
  });

  // REQ-ORB-010.4
  group('conformance to the seam', () {
    test('every reference state keeps the fixed semantics of the seam', () {
      for (final set in _sets()) {
        final propagator = Sgp4Propagator(set.elements);
        final instants = [for (final row in set.rows) set.instantAt(row[0])];
        final forward = [for (final t in instants) propagator.stateAt(t)];
        final backward = [
          for (final t in instants.reversed) propagator.stateAt(t),
        ].reversed.toList();
        for (var k = 0; k < instants.length; k++) {
          final state = forward[k];
          final t = instants[k];
          expect(state.utc == t, isTrue, reason: 'instant $t');
          final gmst = gmstRad(JulianDate.fromUtc(t));
          expect(state.gmstRad == gmst, isTrue, reason: 'GMST at $t');
          final ecef = ecefPositionKm(
            inertialPositionKm: state.inertialState.positionKm,
            gmstRad: state.gmstRad,
          );
          expect(state.ecefPositionKm.x == ecef.x, isTrue);
          expect(state.ecefPositionKm.y == ecef.y, isTrue);
          expect(state.ecefPositionKm.z == ecef.z, isTrue);
          final numbers = _tenNumbers(state);
          for (final value in numbers) {
            expect(value.isFinite, isTrue, reason: 'finite at $t');
          }
          expect(state.gmstRad, greaterThanOrEqualTo(0.0));
          expect(state.gmstRad, lessThan(2 * pi));
          final again = _tenNumbers(backward[k]);
          for (var i = 0; i < numbers.length; i++) {
            expect(numbers[i] == again[i], isTrue, reason: 'number $i at $t');
          }
        }
      }
    });

    test('the adapter is a Propagator that returns common states', () {
      final elements = OrbitalElements.fromTle(_noaa14Line1, _noaa14Line2);
      final Propagator propagator = Sgp4Propagator(elements);
      final state = propagator.stateAt(elements.epoch);
      expect(state, isA<PropagatedState>());
      expect(state, isNot(isA<KeplerPropagatedState>()));
    });

    test('it exposes the element set it was built from', () {
      final elements = OrbitalElements.fromTle(_noaa14Line1, _noaa14Line2);
      expect(identical(Sgp4Propagator(elements).elements, elements), isTrue);
    });
  });

  // REQ-ORB-010.5
  group('invalid instants and element sets the library rejects', () {
    final noaa14 = Sgp4Propagator(
      OrbitalElements.fromTle(_noaa14Line1, _noaa14Line2),
    );
    final synthetic180Elements = OrbitalElements.fromTle(
      _noaa14Line1,
      _synthetic180Line2,
    );

    test('an instant not flagged as UTC is rejected', () {
      _expectArgumentError(noaa14, DateTime(2026, 11, 8), _messageU);
    });

    test('an instant before the valid range is rejected', () {
      _expectArgumentError(
        noaa14,
        DateTime.utc(1900, 2, 28, 23, 59, 59, 999, 999),
        _messageR,
      );
    });

    test('an instant after the valid range is rejected', () {
      _expectArgumentError(noaa14, DateTime.utc(2100, 3, 1), _messageR);
    });

    test('an element set the library rejects fails at stateAt', () {
      final propagator = Sgp4Propagator(synthetic180Elements);
      _expectFailure(propagator, synthetic180Elements.epoch, _messageI);
    });

    test('the instant is checked before the initialization failure', () {
      final propagator = Sgp4Propagator(synthetic180Elements);
      _expectArgumentError(propagator, DateTime(2026, 11, 8), _messageU);
      _expectArgumentError(propagator, DateTime.utc(2100, 3, 1), _messageR);
    });
  });
}
