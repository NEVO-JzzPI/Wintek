// Guard for the derived orbital values of specs/req-orb-008.md
// (REQ-ORB-008.6 and .7).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-008.md';
const String _derivedLibPath =
    'packages/orbital_core/lib/src/derived_values.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _mathTestPath =
    'packages/orbital_core/test/derived_values_test.dart';
const String _guardTestPath =
    'test/orbital_core_derived_values_guard_test.dart';
const String _libPath = 'packages/orbital_core/lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';
const String _wgs84Token =
    'wgs'
    '84';

const String _muDigits = '398600';
const String _muName = 'wgs84MuKm3S2';

const String _speedDeclaration = 'double visVivaSpeedKmS({';
const String _periodDeclaration =
    'double orbitalPeriodSFromMeanMotion(double meanMotionRadS) {';
const String _inclinationDeclaration =
    'double inclinationRadFromState({required StateVector inertialState}) {';

const String _exportLine = "export 'src/derived_values.dart';";

const List<String> _importLines = [
  "import 'dart:math';",
  "import 'perifocal.dart';",
  "import 'state_vector.dart';",
];

const Map<String, List<String>> _docBlocks = {
  _speedDeclaration: [
    '/// Model: vis-viva, v = sqrt(mu (2 / r - 1 / a)), with mu = wgs84MuKm3S2 = 398600.4418 km^3/s^2.',
    '/// Position: only its length r is used, so it may be in any frame.',
    '/// Speed: relative to the inertial frame of the elements, not relative to the rotating Earth.',
    '/// Semi-major axis: the one of the element set, from the Kozai mean motion, as semiMajorAxisKmFromMeanMotion gives it.',
    '/// Units: km and km/s.',
    '/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and semi-major axis), CelesTrak fundamentals-of-astrodynamics test suite.',
  ],
  _periodDeclaration: [
    '/// Model: T = 2 pi / n, the time of one revolution at the mean motion n.',
    '/// Mean motion: the Kozai mean motion of the element set, used as is.',
    '/// Units: radians per second in, seconds out.',
    '/// Reference: WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s (DMA TR8350.2); sidereal day, 86164.0905 s.',
  ],
  _inclinationDeclaration: [
    '/// Model: i = atan2(sqrt(hx^2 + hy^2), hz), with h = r x v the specific angular momentum.',
    '/// Input frame: the inertial frame of the state vector, such as TEME; an Earth-fixed state gives no inclination.',
    '/// Inclination: osculating, from 0 to pi; 0 for a prograde equatorial orbit and pi for a retrograde one.',
    '/// Ignored: the mean inclination of the element set, which OrbitalElements.inclinationRad holds.',
    '/// Units: km, km/s and radians.',
    '/// Reference: Vallado (2022), Example 2-5 and Example 2-6 (position, velocity and inclination), CelesTrak fundamentals-of-astrodynamics test suite.',
  ],
};

const List<String> _speedParameterLines = [
  'required CartesianVector positionKm,',
  'required double semiMajorAxisKm,',
  '}) {',
];

// The only lines allowed at the first column of the derived library file,
// besides empty lines, comments and imports.
const List<String> _allowedFirstColumnLines = [
  _speedDeclaration,
  _periodDeclaration,
  _inclinationDeclaration,
  '}) {',
  '}',
];

const List<String> _citationLines = [
  '// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.',
  '// Vallado repository, twobody test_frame_conversions.py, test_rv2coe (Example 2-5) and test_coe2rv (Example 2-6): position, velocity, semi-major axis and inclination, computed with MU = 398600.4415 km^3/s^2.',
  '// WGS 84 angular velocity of the Earth, 72.92115e-6 rad/s: DMA Technical Report 8350.2 (1991), as quoted at https://en.wikipedia.org/wiki/World_Geodetic_System.',
  '// Sidereal day, 86164.0905 s: https://en.wikipedia.org/wiki/Sidereal_time.',
  '// Kelso, Basics of the Geostationary Orbit, Satellite Times, May 1998: https://celestrak.org/columns/v04n07/, one sidereal day is 23h56m04s.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);

String _tag(int n) => '[REQ-ORB-008.$n]';

Never _failWith(int n, List<String> problems) {
  fail('${_tag(n)} ${problems.join(' ${_tag(n)} ')} See $_specPath.');
}

Directory _repoRoot(int n) => findRepoRoot(
  failurePrefix: '${_tag(n)} ',
  failureSuffix: 'See $_specPath.',
);

/// Reads [relativePath] as lines, or records a problem and returns null.
List<String>? _readLines(
  Directory root,
  String relativePath,
  List<String> problems,
) {
  final file = File('${root.path}/$relativePath');
  if (!file.existsSync()) {
    problems.add('Expected to find $relativePath, but it is missing.');
    return null;
  }
  return file.readAsStringSync().split('\n');
}

/// Every `.dart` file under the core library, or null when the directory is
/// missing (a problem is recorded).
List<File>? _coreLibraryFiles(Directory root, List<String> problems) {
  final dir = Directory('${root.path}/$_libPath');
  if (!dir.existsSync()) {
    problems.add('Expected to find $_libPath, but it is missing.');
    return null;
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

/// Records a problem for each of [required] that is not a line of [lines]
/// once trimmed.
void _checkLines(
  List<String> lines,
  List<String> required,
  String fileLabel,
  List<String> problems,
) {
  final trimmed = lines.map((line) => line.trim()).toSet();
  for (final line in required) {
    if (!trimmed.contains(line)) {
      problems.add('$fileLabel has no line equal to "$line".');
    }
  }
}

/// Checks the doc block directly above [declaration].
void _checkDocBlock(
  List<String> trimmed,
  String declaration,
  String fileLabel,
  List<String> problems,
) {
  final index = trimmed.indexOf(declaration);
  if (index < 0) {
    problems.add('$fileLabel has no line equal to "$declaration".');
    return;
  }
  final docBlock = <String>{};
  for (var k = index - 1; k >= 0 && trimmed[k].startsWith('///'); k--) {
    docBlock.add(trimmed[k]);
  }
  for (final line in _docBlocks[declaration]!) {
    if (!docBlock.contains(line)) {
      problems.add(
        '$fileLabel: the doc block directly above "$declaration" has no line equal to "$line".',
      );
    }
  }
}

/// Checks the lines directly below the speed declaration.
void _checkSpeedParameters(
  List<String> trimmed,
  String fileLabel,
  List<String> problems,
) {
  final index = trimmed.indexOf(_speedDeclaration);
  if (index < 0) return;
  final following = trimmed
      .skip(index + 1)
      .take(_speedParameterLines.length)
      .toList();
  for (var k = 0; k < _speedParameterLines.length; k++) {
    final actual = k < following.length ? following[k] : '';
    if (actual != _speedParameterLines[k]) {
      problems.add(
        '$fileLabel: line ${k + 1} after "$_speedDeclaration" '
        'must be "${_speedParameterLines[k]}".',
      );
    }
  }
}

/// Records a problem for each line of [lines] at the first column that is not
/// a comment, an import or one of [_allowedFirstColumnLines].
void _checkTopLevelDeclarations(
  List<String> lines,
  String fileLabel,
  List<String> problems,
) {
  for (final line in lines) {
    if (line.isEmpty || line.startsWith(' ')) continue;
    if (line.startsWith('//') ||
        line.startsWith("import '") ||
        _allowedFirstColumnLines.contains(line)) {
      continue;
    }
    problems.add('$fileLabel has an unexpected top-level line: "$line".');
  }
}

/// Checks that the gravitational parameter is read by name and never copied.
void _checkMuReuse(
  List<String> lines,
  String fileLabel,
  List<String> problems,
) {
  final code = lines.where((line) => !line.trimLeft().startsWith('//'));
  if (code.any((line) => line.contains(_muDigits))) {
    problems.add(
      '$fileLabel copies the gravitational parameter; read $_muName instead.',
    );
  }
  if (!code.any((line) => line.contains(_muName))) {
    problems.add('$fileLabel has no code line that reads $_muName.');
  }
}

/// Checks that line `// REQ-ORB-008.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-008.$n';
  final index = lines.indexWhere((line) => line.trim() == marker);
  if (index < 0) {
    problems.add('$fileLabel has no line equal to "$marker".');
    return;
  }
  final next = lines
      .skip(index + 1)
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  if (!openers.any(next.startsWith)) {
    problems.add(
      '$fileLabel: the line after "$marker" must start with ${openers.join(' or ')}.',
    );
  }
}

void _checkBytes(File file, String label, List<String> problems) {
  final bytes = file.readAsBytesSync();
  if (bytes.contains(0x0D)) {
    problems.add('$label contains a CR byte (0D); use LF line endings.');
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    problems.add('$label starts with a UTF-8 BOM.');
  }
}

void main() {
  // REQ-ORB-008.6
  test(
    'the derived values library file is placed, exported and documented',
    () {
      final root = _repoRoot(6);
      final problems = <String>[];

      final derivedLines = _readLines(root, _derivedLibPath, problems);
      if (derivedLines != null) {
        final trimmed = derivedLines.map((line) => line.trim()).toList();
        _checkLines(derivedLines, _importLines, _derivedLibPath, problems);
        for (final declaration in _docBlocks.keys) {
          _checkDocBlock(trimmed, declaration, _derivedLibPath, problems);
        }
        _checkSpeedParameters(trimmed, _derivedLibPath, problems);
        _checkTopLevelDeclarations(derivedLines, _derivedLibPath, problems);
        _checkMuReuse(derivedLines, _derivedLibPath, problems);
      }

      final publicLines = _readLines(root, _publicLibPath, problems);
      if (publicLines != null) {
        _checkLines(publicLines, [_exportLine], _publicLibPath, problems);
      }

      if (problems.isNotEmpty) _failWith(6, problems);
    },
  );

  // REQ-ORB-008.7
  test('the derived values are pure, cited and test-hygienic', () {
    final root = _repoRoot(7);
    final problems = <String>[];

    final libFiles = _coreLibraryFiles(root, problems);
    for (final file in libFiles ?? <File>[]) {
      final label = file.path;
      for (final line in file.readAsStringSync().split('\n')) {
        if (_forbiddenCoreImport.hasMatch(line.trimLeft())) {
          problems.add('$label has a forbidden import/export: "$line".');
        }
      }
      _checkBytes(file, label, problems);
    }

    final mathLines = _readLines(root, _mathTestPath, problems);
    if (mathLines != null) {
      if (!mathLines.any(
        (line) => line == "import 'package:orbital_core/orbital_core.dart';",
      )) {
        problems.add(
          '$_mathTestPath must contain the line '
          "\"import 'package:orbital_core/orbital_core.dart';\".",
        );
      }
      for (final line in mathLines) {
        if (_forbiddenTestImport.hasMatch(line.trimLeft())) {
          problems.add(
            '$_mathTestPath imports from lib/src, by relative path or from dart:io: "$line".',
          );
        }
      }
      final mathText = mathLines.join('\n');
      if (mathText.contains(_wgs84Token)) {
        problems.add(
          '$_mathTestPath must not contain "$_wgs84Token"; '
          'use literal numbers for mu and omega.',
        );
      }
      _checkLines(mathLines, _citationLines, _mathTestPath, problems);
      for (var n = 1; n <= 5; n++) {
        _checkMarker(
          mathLines,
          n,
          ['test(', 'group('],
          _mathTestPath,
          problems,
        );
      }
      if (mathText.contains(_skipToken)) {
        problems.add('$_mathTestPath contains a skipped test.');
      }
      _checkBytes(File('${root.path}/$_mathTestPath'), _mathTestPath, problems);
    }

    final guardLines = _readLines(root, _guardTestPath, problems);
    if (guardLines != null) {
      if (!guardLines.any(
        (line) => line == "import 'support/repo_root.dart';",
      )) {
        problems.add(
          '$_guardTestPath must contain the line '
          "\"import 'support/repo_root.dart';\".",
        );
      }
      final guardText = guardLines.join('\n');
      if (guardText.contains(_platformScriptToken)) {
        problems.add('$_guardTestPath must not use the script location API.');
      }
      for (var n = 6; n <= 7; n++) {
        _checkMarker(guardLines, n, ['test('], _guardTestPath, problems);
      }
      if (guardText.contains(_skipToken)) {
        problems.add('$_guardTestPath contains a skipped test.');
      }
      _checkBytes(
        File('${root.path}/$_guardTestPath'),
        _guardTestPath,
        problems,
      );
    }

    final specFile = File('${root.path}/$_specPath');
    if (specFile.existsSync()) {
      _checkBytes(specFile, _specPath, problems);
    } else {
      problems.add('Expected to find $_specPath, but it is missing.');
    }

    if (problems.isNotEmpty) _failWith(7, problems);
  });
}
