import 'tle_parser.dart';

/// An immutable set of orbital elements at one epoch, read from a TLE.
///
/// Units: radians, seconds and radians per second; B* in inverse Earth radii.
/// Mean motion: the Kozai mean motion published in the TLE.
/// Mean motion terms: the TLE values of ndot / 2 and nddot / 6, in SI units.
final class OrbitalElements {
  OrbitalElements._(this._values);

  /// Parses the two lines of a TLE.
  ///
  /// Throws a [FormatException] when the lines are not a valid TLE.
  factory OrbitalElements.fromTle(String line1, String line2) =>
      OrbitalElements._(parseTleValues(line1, line2));

  final TleValues _values;

  int get catalogNumber => _values.catalogNumber;

  /// The epoch, as a UTC instant.
  DateTime get epoch => _values.epoch;

  double get inclinationRad => _values.inclinationRad;

  /// Right ascension of the ascending node.
  double get raanRad => _values.raanRad;

  double get eccentricity => _values.eccentricity;

  double get argumentOfPerigeeRad => _values.argumentOfPerigeeRad;

  double get meanAnomalyRad => _values.meanAnomalyRad;

  double get meanMotionRadS => _values.meanMotionRadS;

  /// The TLE value of ndot / 2, in radians per second squared.
  double get ndotOver2RadS2 => _values.ndotOver2RadS2;

  /// The TLE value of nddot / 6, in radians per second cubed.
  double get nddotOver6RadS3 => _values.nddotOver6RadS3;

  double get bstarInverseEarthRadii => _values.bstarInverseEarthRadii;

  @override
  bool operator ==(Object other) =>
      other is OrbitalElements && other._values == _values;

  @override
  int get hashCode => _values.hashCode;
}
