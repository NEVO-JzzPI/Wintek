import 'dart:math';

const double _twoPi = 2 * pi;
const double _secondsPerDay = 86400.0;
const int _lineLength = 69;
// 1e-8 of a day, exactly.
const int _microsecondsPerEpochDayUnit = 864;

final RegExp _catalogNumberPattern = RegExp(r'^[0-9]{5}$');
final RegExp _epochYearPattern = RegExp(r'^[0-9]{2}$');
final RegExp _epochDayPattern = RegExp(r'^[0-9]{3}\.[0-9]{8}$');
final RegExp _firstDerivativePattern = RegExp(r'^[ +-]\.[0-9]{8}$');
final RegExp _assumedDecimalPattern = RegExp(r'^[ +-][0-9]{5}[+-][0-9]$');
final RegExp _anglePattern = RegExp(r'^ *[0-9]+\.[0-9]{4}$');
final RegExp _eccentricityPattern = RegExp(r'^[0-9]{7}$');
final RegExp _meanMotionPattern = RegExp(r'^ *[0-9]+\.[0-9]{8}$');

/// The values read from the two lines of a TLE, converted to SI units.
///
/// Epoch years: 57 to 99 are 1957 to 1999; 00 to 56 are 2000 to 2056.
/// Checksum: digits count their value, minus signs count 1, all else 0, modulo 10.
/// Reference: CelesTrak, NORAD Two-Line Element Set Format.
typedef TleValues = ({
  int catalogNumber,
  DateTime epoch,
  double inclinationRad,
  double raanRad,
  double eccentricity,
  double argumentOfPerigeeRad,
  double meanAnomalyRad,
  double meanMotionRadS,
  double ndotOver2RadS2,
  double nddotOver6RadS3,
  double bstarInverseEarthRadii,
});

/// Parses the two lines of a TLE.
///
/// Throws a [FormatException] with an exact message when a line is not
/// printable ASCII, has the wrong length, number or checksum, when the lines
/// disagree on the catalog number, or when a field is malformed or out of range.
TleValues parseTleValues(String line1, String line2) {
  final first = _prepareLine(line1, 1);
  final second = _prepareLine(line2, 2);

  final catalogNumber = int.parse(
    _field(first, 1, 3, 7, 'catalog number', _catalogNumberPattern),
  );
  final yy = int.parse(
    _field(first, 1, 19, 20, 'epoch year', _epochYearPattern),
  );
  final year = yy < 57 ? 2000 + yy : 1900 + yy;
  final epochDay = _field(first, 1, 21, 32, 'epoch day', _epochDayPattern);
  final dayOfYear = int.parse(epochDay.substring(0, 3));
  if (dayOfYear < 1 || dayOfYear > (_isLeapYear(year) ? 366 : 365)) {
    throw _outOfRange(1, 'epoch day');
  }
  final epoch = DateTime.utc(year).add(
    Duration(
      days: dayOfYear - 1,
      microseconds:
          int.parse(epochDay.substring(4)) * _microsecondsPerEpochDayUnit,
    ),
  );
  final ndotOver2 = _signedFraction(
    _field(
      first,
      1,
      34,
      43,
      'first derivative of mean motion',
      _firstDerivativePattern,
    ),
  );
  final nddotOver6 = _assumedDecimal(
    _field(
      first,
      1,
      45,
      52,
      'second derivative of mean motion',
      _assumedDecimalPattern,
    ),
  );
  final bstar = _assumedDecimal(
    _field(first, 1, 54, 61, 'B*', _assumedDecimalPattern),
  );

  if (int.parse(
        _field(second, 2, 3, 7, 'catalog number', _catalogNumberPattern),
      ) !=
      catalogNumber) {
    throw const FormatException(
      'TLE lines 1 and 2 must have the same catalog number.',
    );
  }
  final inclinationDeg = _angleDeg(
    _field(second, 2, 9, 16, 'inclination', _anglePattern),
  );
  if (inclinationDeg > 180.0) throw _outOfRange(2, 'inclination');
  final raanDeg = _angleDeg(
    _field(
      second,
      2,
      18,
      25,
      'right ascension of the ascending node',
      _anglePattern,
    ),
  );
  if (raanDeg >= 360.0) {
    throw _outOfRange(2, 'right ascension of the ascending node');
  }
  final eccentricity = double.parse(
    '0.${_field(second, 2, 27, 33, 'eccentricity', _eccentricityPattern)}',
  );
  final argumentOfPerigeeDeg = _angleDeg(
    _field(second, 2, 35, 42, 'argument of perigee', _anglePattern),
  );
  if (argumentOfPerigeeDeg >= 360.0) {
    throw _outOfRange(2, 'argument of perigee');
  }
  final meanAnomalyDeg = _angleDeg(
    _field(second, 2, 44, 51, 'mean anomaly', _anglePattern),
  );
  if (meanAnomalyDeg >= 360.0) throw _outOfRange(2, 'mean anomaly');
  final revolutionsPerDay = double.parse(
    _field(second, 2, 53, 63, 'mean motion', _meanMotionPattern).trim(),
  );
  if (revolutionsPerDay <= 0.0) throw _outOfRange(2, 'mean motion');

  return (
    catalogNumber: catalogNumber,
    epoch: epoch,
    inclinationRad: inclinationDeg * pi / 180.0,
    raanRad: raanDeg * pi / 180.0,
    eccentricity: eccentricity,
    argumentOfPerigeeRad: argumentOfPerigeeDeg * pi / 180.0,
    meanAnomalyRad: meanAnomalyDeg * pi / 180.0,
    meanMotionRadS: revolutionsPerDay * _twoPi / _secondsPerDay,
    ndotOver2RadS2: ndotOver2 * _twoPi / (_secondsPerDay * _secondsPerDay),
    nddotOver6RadS3:
        nddotOver6 *
        _twoPi /
        (_secondsPerDay * _secondsPerDay * _secondsPerDay),
    bstarInverseEarthRadii: bstar,
  );
}

/// Removes trailing blanks, then checks characters, length, number and checksum.
String _prepareLine(String line, int lineNumber) {
  var end = line.length;
  while (end > 0 && _isTrailingBlank(line.codeUnitAt(end - 1))) {
    end--;
  }
  final prepared = line.substring(0, end);
  if (prepared.codeUnits.any((unit) => unit < 0x20 || unit > 0x7E)) {
    throw FormatException(
      'TLE line $lineNumber must contain printable ASCII characters only.',
    );
  }
  if (prepared.length != _lineLength) {
    throw FormatException('TLE line $lineNumber must be 69 characters long.');
  }
  if (prepared[0] != '$lineNumber' || prepared[1] != ' ') {
    throw FormatException(
      'TLE line $lineNumber must start with "$lineNumber ".',
    );
  }
  if (prepared.codeUnitAt(68) - 0x30 != _checksum(prepared)) {
    throw FormatException('TLE line $lineNumber has an invalid checksum.');
  }
  return prepared;
}

bool _isTrailingBlank(int unit) => unit == 0x20 || unit == 0x09 || unit == 0x0D;

int _checksum(String line) {
  var sum = 0;
  for (var i = 0; i < _lineLength - 1; i++) {
    final unit = line.codeUnitAt(i);
    if (unit >= 0x30 && unit <= 0x39) {
      sum += unit - 0x30;
    } else if (unit == 0x2D) {
      sum += 1;
    }
  }
  return sum % 10;
}

/// Columns [firstColumn] through [lastColumn] of [line], checked against [pattern].
String _field(
  String line,
  int lineNumber,
  int firstColumn,
  int lastColumn,
  String name,
  RegExp pattern,
) {
  final text = line.substring(firstColumn - 1, lastColumn);
  if (!pattern.hasMatch(text)) {
    throw FormatException('TLE line $lineNumber has an invalid $name field.');
  }
  return text;
}

FormatException _outOfRange(int lineNumber, String name) =>
    FormatException('TLE line $lineNumber has an out-of-range $name field.');

bool _isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

double _angleDeg(String text) => double.parse(text.trim());

/// A sign, a point and eight digits, such as ` .00000140`.
double _signedFraction(String text) {
  final magnitude = double.parse('0.${text.substring(2)}');
  return text[0] == '-' ? -magnitude : magnitude;
}

/// Five digits after an assumed decimal point and a signed power of ten, such
/// as ` 12891-6`.
double _assumedDecimal(String text) {
  final sign = text[0] == '-' ? '-' : '';
  return double.parse('${sign}0.${text.substring(1, 6)}e${text.substring(6)}');
}
