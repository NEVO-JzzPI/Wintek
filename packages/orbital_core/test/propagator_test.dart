import 'dart:math';

import 'package:orbital_core/orbital_core.dart';
import 'package:test/test.dart';

// CelesTrak, NORAD Two-Line Element Set Format, https://celestrak.org/NORAD/documentation/tle-fmt.php: NOAA 14 (23455) example.
// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005, 23599 and 28129.
// Synthetic GEO element set 99999, built for specs/req-orb-009.md with valid checksums; not a published object.

const String _julianMessageU = 'Julian date conversion requires a UTC instant.';
const String _julianMessageR =
    'Julian date conversion supports 1900-03-01T00:00:00.000000Z '
    'through 2100-02-28T23:59:59.999999Z only.';

const List<List<String>> _tleLines = [
  [
    '1 23455U 94089A   97320.90946019  .00000140  00000-0  10191-3 0  2621',
    '2 23455  99.0090 272.6745 0008546 223.1686 136.8816 14.11711747148495',
  ],
  [
    '1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753',
    '2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667',
  ],
  [
    '1 23599U 95029B   06171.76535463  .00085586  12891-6  12956-2 0  2905',
    '2 23599   6.9327   0.2849 5782022 274.4436  25.2425  4.47796565123555',
  ],
  [
    '1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459',
    '2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443',
  ],
  [
    '1 99999U 26001A   26310.50000000  .00000000  00000-0  00000-0 0  9991',
    '2 99999   0.0100 100.0000 0001000  90.0000 180.0000  1.00273791000019',
  ],
];

const int _geoIndex = 4;

OrbitalElements _elementsAt(int index) =>
    OrbitalElements.fromTle(_tleLines[index][0], _tleLines[index][1]);

List<OrbitalElements> _testElementSets() => [
  for (var i = 0; i < _tleLines.length; i++) _elementsAt(i),
];

List<DateTime> _gridInstants(DateTime epoch) => [
  epoch,
  epoch.add(const Duration(minutes: 90)),
  epoch.add(const Duration(days: 1)),
  epoch.subtract(const Duration(days: 1)),
  epoch.add(const Duration(days: 30)),
  DateTime.utc(2026, 11, 8),
  DateTime.utc(1900, 3, 1),
  DateTime.utc(2100, 2, 28, 23, 59, 59, 999, 999),
];

double _distanceKm(CartesianVector a, CartesianVector b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  final dz = a.z - b.z;
  return sqrt(dx * dx + dy * dy + dz * dz);
}

DateTime _periodsAfterEpoch(OrbitalElements elements, int k) {
  final periodS = 2 * pi / elements.meanMotionRadS;
  return elements.epoch.add(
    Duration(microseconds: (k * periodS * 1e6).round()),
  );
}

List<double> _twelveNumbers(KeplerPropagatedState state) => [
  state.meanAnomalyRad,
  state.eccentricAnomalyRad,
  state.gmstRad,
  state.inertialState.positionKm.x,
  state.inertialState.positionKm.y,
  state.inertialState.positionKm.z,
  state.inertialState.velocityKmS.x,
  state.inertialState.velocityKmS.y,
  state.inertialState.velocityKmS.z,
  state.ecefPositionKm.x,
  state.ecefPositionKm.y,
  state.ecefPositionKm.z,
];

void main() {
  // REQ-ORB-009.1
  test(
    'the Kepler state is the exact composition of the validated functions',
    () {
      var count = 0;
      for (final elements in _testElementSets()) {
        final propagator = KeplerPropagator(elements);
        for (final t in _gridInstants(elements.epoch)) {
          final m = meanAnomalyAtRad(elements, t);
          final e = eccentricAnomalyRad(m, elements.eccentricity);
          final a = semiMajorAxisKmFromMeanMotion(elements.meanMotionRadS);
          final inertial = inertialStateVector(
            semiMajorAxisKm: a,
            eccentricity: elements.eccentricity,
            inclinationRad: elements.inclinationRad,
            raanRad: elements.raanRad,
            argumentOfPerigeeRad: elements.argumentOfPerigeeRad,
            eccentricAnomalyRad: e,
          );
          final gmst = gmstRad(JulianDate.fromUtc(t));
          final ecef = ecefPositionKm(
            inertialPositionKm: inertial.positionKm,
            gmstRad: gmst,
          );

          final state = propagator.stateAt(t);

          expect(state.utc == t, isTrue, reason: 'instant');
          expect(state.meanAnomalyRad == m, isTrue, reason: 'M at $t');
          expect(state.eccentricAnomalyRad == e, isTrue, reason: 'E at $t');
          expect(
            state.inertialState.positionKm.x == inertial.positionKm.x,
            isTrue,
          );
          expect(
            state.inertialState.positionKm.y == inertial.positionKm.y,
            isTrue,
          );
          expect(
            state.inertialState.positionKm.z == inertial.positionKm.z,
            isTrue,
          );
          expect(
            state.inertialState.velocityKmS.x == inertial.velocityKmS.x,
            isTrue,
          );
          expect(
            state.inertialState.velocityKmS.y == inertial.velocityKmS.y,
            isTrue,
          );
          expect(
            state.inertialState.velocityKmS.z == inertial.velocityKmS.z,
            isTrue,
          );
          expect(state.gmstRad == gmst, isTrue, reason: 'GMST at $t');
          expect(state.ecefPositionKm.x == ecef.x, isTrue);
          expect(state.ecefPositionKm.y == ecef.y, isTrue);
          expect(state.ecefPositionKm.z == ecef.z, isTrue);
          count++;
        }
      }
      expect(count, 40);
    },
  );

  // REQ-ORB-009.2
  group('invariants of the composition', () {
    test('the mean anomaly at the epoch is the one of the element set', () {
      for (final elements in _testElementSets()) {
        final state = KeplerPropagator(elements).stateAt(elements.epoch);
        expect(
          state.meanAnomalyRad == elements.meanAnomalyRad,
          isTrue,
          reason: 'catalog ${elements.catalogNumber}',
        );
      }
    });

    test('the orbit closes after whole periods', () {
      for (final elements in _testElementSets()) {
        final propagator = KeplerPropagator(elements);
        final start = propagator.stateAt(elements.epoch).inertialState;
        for (var k = 1; k <= 10; k++) {
          final later = propagator
              .stateAt(_periodsAfterEpoch(elements, k))
              .inertialState;
          expect(
            _distanceKm(later.positionKm, start.positionKm),
            lessThanOrEqualTo(1e-4),
            reason: 'position, catalog ${elements.catalogNumber}, k=$k',
          );
          expect(
            _distanceKm(later.velocityKmS, start.velocityKmS),
            lessThanOrEqualTo(1e-7),
            reason: 'velocity, catalog ${elements.catalogNumber}, k=$k',
          );
        }
      }
    });

    test('a geostationary orbit hardly moves in Earth-fixed axes', () {
      final elements = _elementsAt(_geoIndex);
      final propagator = KeplerPropagator(elements);
      final start = propagator.stateAt(elements.epoch);
      for (var h = 1; h <= 24; h++) {
        final later = propagator.stateAt(
          elements.epoch.add(Duration(hours: h)),
        );
        expect(
          _distanceKm(later.ecefPositionKm, start.ecefPositionKm),
          lessThanOrEqualTo(30.0),
          reason: 'Earth-fixed drift at +$h h',
        );
      }
      final half = propagator.stateAt(
        elements.epoch.add(const Duration(hours: 12)),
      );
      expect(
        _distanceKm(
          half.inertialState.positionKm,
          start.inertialState.positionKm,
        ),
        greaterThanOrEqualTo(80000.0),
      );
    });
  });

  // REQ-ORB-009.3
  group('conformance to the seam', () {
    test('the Kepler propagator is a Propagator and returns common states', () {
      final elements = _elementsAt(0);
      final Propagator propagator = KeplerPropagator(elements);
      final state = propagator.stateAt(elements.epoch);
      expect(state, isA<PropagatedState>());
      expect(state, isA<KeplerPropagatedState>());
    });

    test('it exposes the element set it was built from', () {
      final elements = _elementsAt(0);
      expect(identical(KeplerPropagator(elements).elements, elements), isTrue);
    });

    test('its 40 grid states are finite and in range', () {
      var count = 0;
      for (final elements in _testElementSets()) {
        final propagator = KeplerPropagator(elements);
        for (final t in _gridInstants(elements.epoch)) {
          final state = propagator.stateAt(t);
          for (final value in _twelveNumbers(state)) {
            expect(value.isFinite, isTrue, reason: 'finite at $t');
          }
          for (final angle in [
            state.meanAnomalyRad,
            state.eccentricAnomalyRad,
            state.gmstRad,
          ]) {
            expect(angle, greaterThanOrEqualTo(0.0));
            expect(angle, lessThan(2 * pi));
          }
          count++;
        }
      }
      expect(count, 40);
    });

    test('it keeps no state between calls', () {
      final elements = _elementsAt(0);
      final propagator = KeplerPropagator(elements);
      final later = elements.epoch.add(const Duration(days: 30));
      final first = propagator.stateAt(later);
      propagator.stateAt(elements.epoch.subtract(const Duration(days: 1)));
      final second = propagator.stateAt(later);
      final a = _twelveNumbers(first);
      final b = _twelveNumbers(second);
      for (var i = 0; i < a.length; i++) {
        expect(a[i] == b[i], isTrue, reason: 'number $i');
      }
    });

    test('the failure type carries its message', () {
      const failure = PropagationException('Model failure.');
      expect(failure, isA<Exception>());
      expect(failure.message, 'Model failure.');
      expect(failure.toString(), 'PropagationException: Model failure.');
    });
  });

  // REQ-ORB-009.4
  group('invalid instants', () {
    final propagator = KeplerPropagator(_elementsAt(0));

    void expectArgumentError(DateTime instant, String message) {
      Object? thrown;
      try {
        propagator.stateAt(instant);
      } catch (error) {
        thrown = error;
      }
      expect(thrown, isA<ArgumentError>());
      expect(thrown, isNot(isA<PropagationException>()));
      expect((thrown as ArgumentError).message, message);
    }

    test('an instant not flagged as UTC is rejected', () {
      expectArgumentError(DateTime(2026, 11, 8), _julianMessageU);
    });

    test('an instant before the valid range is rejected', () {
      expectArgumentError(
        DateTime.utc(1900, 2, 28, 23, 59, 59, 999, 999),
        _julianMessageR,
      );
    });

    test('an instant after the valid range is rejected', () {
      expectArgumentError(DateTime.utc(2100, 3, 1), _julianMessageR);
    });
  });
}
