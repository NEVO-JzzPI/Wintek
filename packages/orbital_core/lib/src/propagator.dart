import 'orbital_elements.dart';
import 'state_vector.dart';

/// Seam: every propagator is bound to one element set and returns its state at a UTC instant.
/// Implementations: KeplerPropagator (two-body, in this package) and the SGP4 adapter (req-orb-010).
/// Errors: ArgumentError for an instant that is not UTC or outside the range of JulianDate.fromUtc; PropagationException when the model cannot propagate the element set to the instant.
/// Results: every number of a returned state is finite; a propagator throws instead of returning NaN or infinity.
/// Calls: a state depends only on the element set and the instant, never on earlier calls or their order.
abstract interface class Propagator {
  OrbitalElements get elements;
  PropagatedState stateAt(DateTime utc);
}

/// Instant: the UTC instant passed to stateAt.
/// Inertial state: position in km and velocity in km/s, in the inertial frame of the elements; TEME for elements read from a TLE.
/// GMST: gmstRad of the Julian date of the instant (IAU-82), from 0 inclusive to 2 pi exclusive, in radians.
/// ECEF: ecefPositionKm of the inertial position at that GMST, in km; Earth-fixed axes without polar motion (PEF).
/// Not carried: geodetic coordinates, derived values and any Earth-relative velocity.
base class PropagatedState {
  const PropagatedState({
    required this.utc,
    required this.inertialState,
    required this.gmstRad,
    required this.ecefPositionKm,
  });

  final DateTime utc;
  final StateVector inertialState;
  final double gmstRad;
  final CartesianVector ecefPositionKm;
}

/// Thrown by a propagator when its model cannot propagate the element set to the instant, such as a decayed object.
/// Not thrown for an invalid instant, which is an ArgumentError, and never thrown by KeplerPropagator.
final class PropagationException implements Exception {
  const PropagationException(this.message);

  final String message;

  @override
  String toString() => 'PropagationException: $message';
}
