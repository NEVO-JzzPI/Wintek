import 'dart:math';

import 'package:satellite_observer/satellite_observer.dart' as sgp4;

import 'earth_fixed.dart';
import 'gmst.dart';
import 'julian_date.dart';
import 'orbital_elements.dart';
import 'propagator.dart';
import 'state_vector.dart';

/// Model: SGP4 and SDP4 of Vallado et al., Revisiting Spacetrack Report #3 (AIAA 2006-6753), as implemented by satellite_observer 1.0.1 (ADR-0002).
/// Gravity model: WGS-72, selected by name from the library; this adapter declares no gravity constant.
/// Operation mode: improved ('i'), fixed by the library and confirmed by the official vectors.
/// Elements: built from the fields of OrbitalElements, in degrees and revolutions per day; the TLE lines are not kept.
/// Output: TEME position in km and velocity in km/s; GMST and ECEF as Propagator defines them.
/// Errors: the ArgumentError of JulianDate.fromUtc, checked before the library is called; PropagationException when the library cannot initialize the element set or reports an SGP4 error code.
/// Reference: SGP4-VER.TLE and tcppver.out of Vallado et al., 30 element sets and 588 states (specs/req-orb-010.md).
final class Sgp4Propagator implements Propagator {
  Sgp4Propagator(this.elements) : _engine = _initialize(elements);

  static const double _degreesPerRadian = 180 / pi;
  static const double _secondsPerDay = 86400;
  static const double _revolutionsPerDayPerRadianPerSecond =
      _secondsPerDay / (2 * pi);

  @override
  final OrbitalElements elements;

  // Null when the library rejects the element set; stateAt then fails.
  final sgp4.Sgp4Engine? _engine;

  static sgp4.Sgp4Engine? _initialize(OrbitalElements elements) {
    try {
      return sgp4.Sgp4Engine(
        sgp4.GpElements.fromMeanElements(
          epoch: elements.epoch,
          inclinationDeg: elements.inclinationRad * _degreesPerRadian,
          raanDeg: elements.raanRad * _degreesPerRadian,
          eccentricity: elements.eccentricity,
          argPerigeeDeg: elements.argumentOfPerigeeRad * _degreesPerRadian,
          meanAnomalyDeg: elements.meanAnomalyRad * _degreesPerRadian,
          meanMotionRevPerDay:
              elements.meanMotionRadS * _revolutionsPerDayPerRadianPerSecond,
          bStar: elements.bstarInverseEarthRadii,
          meanMotionDotRevPerDay2:
              elements.ndotOver2RadS2 *
              _revolutionsPerDayPerRadianPerSecond *
              _secondsPerDay,
          meanMotionDdotRevPerDay3:
              elements.nddotOver6RadS3 *
              _revolutionsPerDayPerRadianPerSecond *
              _secondsPerDay *
              _secondsPerDay,
        ),
        gravity: sgp4.GravityModel.wgs72,
      );
    } on sgp4.InvalidElementsException {
      return null;
    }
  }

  @override
  PropagatedState stateAt(DateTime utc) {
    final gmst = gmstRad(JulianDate.fromUtc(utc));
    final engine = _engine;
    if (engine == null) {
      throw const PropagationException(
        'SGP4 cannot initialize the element set.',
      );
    }
    final sgp4.EciState teme;
    try {
      teme = engine.propagate(utc);
    } on sgp4.PropagationException catch (error) {
      throw PropagationException(
        'SGP4 cannot propagate the element set to the instant: '
        'error code ${error.code}.',
      );
    }
    final positionKm = CartesianVector(
      teme.position.x,
      teme.position.y,
      teme.position.z,
    );
    return PropagatedState(
      utc: utc,
      inertialState: StateVector(
        positionKm: positionKm,
        velocityKmS: CartesianVector(
          teme.velocity.x,
          teme.velocity.y,
          teme.velocity.z,
        ),
      ),
      gmstRad: gmst,
      ecefPositionKm: ecefPositionKm(
        inertialPositionKm: positionKm,
        gmstRad: gmst,
      ),
    );
  }
}
