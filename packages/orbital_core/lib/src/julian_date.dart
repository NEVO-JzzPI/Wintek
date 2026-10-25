const double _j2000JulianDate = 2451545.0;
const double _daysPerJulianCentury = 36525.0;
const int _microsecondsPerDay = 86400000000;

final DateTime _firstValidInstant = DateTime.utc(1900, 3, 1);
final DateTime _lastValidInstant = DateTime.utc(
  2100,
  2,
  28,
  23,
  59,
  59,
  999,
  999,
);

/// A Julian date held in two parts: the day part and the fraction of the day.
///
/// UTC is treated as UT1.
/// DUT1 and ΔT are ignored, so no IERS table or leap-second list is needed.
/// Valid range: 1900-03-01T00:00:00.000000Z through 2100-02-28T23:59:59.999999Z.
/// Reference: Vallado, Fundamentals of Astrodynamics and Applications, 4th ed., chapter 3.
///
/// The day part is the Julian date at 00:00:00 UTC of the instant's calendar
/// date, so it always ends in .5. The fraction part is the time elapsed since
/// that midnight divided by 86 400 s, in the range [0.0, 1.0).
final class JulianDate {
  JulianDate._(this.dayPart, this.fractionPart);

  /// Converts a UTC instant to a two-part Julian date.
  ///
  /// Throws an [ArgumentError] when [utc] is not flagged as UTC or lies
  /// outside the valid range.
  factory JulianDate.fromUtc(DateTime utc) {
    if (!utc.isUtc) {
      throw ArgumentError('Julian date conversion requires a UTC instant.');
    }
    if (utc.isBefore(_firstValidInstant) || utc.isAfter(_lastValidInstant)) {
      throw ArgumentError(
        'Julian date conversion supports 1900-03-01T00:00:00.000000Z '
        'through 2100-02-28T23:59:59.999999Z only.',
      );
    }
    final year = utc.year;
    final month = utc.month;
    final dayPart =
        367 * year -
        7 * (year + (month + 9) ~/ 12) ~/ 4 +
        275 * month ~/ 9 +
        utc.day +
        1721013.5;
    final microsecondsOfDay =
        utc.hour * 3600000000 +
        utc.minute * 60000000 +
        utc.second * 1000000 +
        utc.millisecond * 1000 +
        utc.microsecond;
    return JulianDate._(dayPart, microsecondsOfDay / _microsecondsPerDay);
  }

  /// Julian date at 00:00:00 UTC of the instant's calendar date, in days.
  final double dayPart;

  /// Fraction of the day elapsed since 00:00:00 UTC, in days.
  final double fractionPart;

  /// Julian centuries (36 525 days) since J2000.0 (JD 2451545.0).
  double get julianCenturies =>
      (dayPart - _j2000JulianDate + fractionPart) / _daysPerJulianCentury;
}
