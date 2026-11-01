import 'julian_date.dart';

const double _secondsPerDay = 86400.0;

/// Elapsed time: ((day B - day A) + (fraction B - fraction A)) * 86400, in seconds.
/// Sign: positive when B is later than A, negative when earlier, 0 when equal.
/// Input: the two-part Julian dates of req-orb-001 only.
///
/// [from] is A and [to] is B. The day parts are subtracted first: they end in
/// .5 and are exact in a double, so the fraction digits are kept.
double elapsedSeconds(JulianDate from, JulianDate to) =>
    ((to.dayPart - from.dayPart) + (to.fractionPart - from.fractionPart)) *
    _secondsPerDay;
