import 'earth_fixed.dart';
import 'gmst.dart';
import 'julian_date.dart';
import 'kepler.dart';
import 'orbital_elements.dart';
import 'perifocal.dart';
import 'propagator.dart';

/// Mean anomaly: meanAnomalyAtRad of the elements at the instant, from 0 inclusive to 2 pi exclusive, in radians.
/// Eccentric anomaly: eccentricAnomalyRad of that mean anomaly and the eccentricity, from 0 inclusive to 2 pi exclusive, in radians.
final class KeplerPropagatedState extends PropagatedState {
  const KeplerPropagatedState({
    required super.utc,
    required super.inertialState,
    required super.gmstRad,
    required super.ecefPositionKm,
    required this.meanAnomalyRad,
    required this.eccentricAnomalyRad,
  });

  final double meanAnomalyRad;
  final double eccentricAnomalyRad;
}

/// Model: two-body Kepler propagation, composed from the functions of req-orb-002 and req-orb-004 to req-orb-006, with no formula of its own.
/// Mean anomaly: linear, M = M0 + n (t - t0); ndot / 2, nddot / 6 and B* are ignored, so there is no drag and no J2.
/// Semi-major axis: semiMajorAxisKmFromMeanMotion of the Kozai mean motion, with mu = wgs84MuKm3S2.
/// Errors: the ArgumentError of JulianDate.fromUtc for an invalid instant, and the StateError of eccentricAnomalyRad if it does not converge; never PropagationException.
/// Reference: none of its own; each composed function is validated against published values in its own spec.
final class KeplerPropagator implements Propagator {
  KeplerPropagator(this.elements);

  @override
  final OrbitalElements elements;

  @override
  KeplerPropagatedState stateAt(DateTime utc) {
    final m = meanAnomalyAtRad(elements, utc);
    final e = eccentricAnomalyRad(m, elements.eccentricity);
    final inertial = inertialStateVector(
      semiMajorAxisKm: semiMajorAxisKmFromMeanMotion(elements.meanMotionRadS),
      eccentricity: elements.eccentricity,
      inclinationRad: elements.inclinationRad,
      raanRad: elements.raanRad,
      argumentOfPerigeeRad: elements.argumentOfPerigeeRad,
      eccentricAnomalyRad: e,
    );
    final gmst = gmstRad(JulianDate.fromUtc(utc));
    return KeplerPropagatedState(
      utc: utc,
      inertialState: inertial,
      gmstRad: gmst,
      ecefPositionKm: ecefPositionKm(
        inertialPositionKm: inertial.positionKm,
        gmstRad: gmst,
      ),
      meanAnomalyRad: m,
      eccentricAnomalyRad: e,
    );
  }
}
