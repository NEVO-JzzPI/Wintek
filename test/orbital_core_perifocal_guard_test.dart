// Guard for the perifocal state vector of specs/req-orb-005.md (REQ-ORB-005.6
// and .7).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-005.md';
const String _perifocalLibPath = 'packages/orbital_core/lib/src/perifocal.dart';
const String _stateVectorLibPath =
    'packages/orbital_core/lib/src/state_vector.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _mathTestPath = 'packages/orbital_core/test/perifocal_test.dart';
const String _guardTestPath = 'test/orbital_core_perifocal_guard_test.dart';
const String _libPath = 'packages/orbital_core/lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const String _factoryDeclaration = 'StateVector inertialStateVector({';

const List<String> _mutableLinePrefixes = ['var ', 'set ', 'late '];

const List<String> _exportLines = [
  "export 'src/perifocal.dart';",
  "export 'src/state_vector.dart';",
];

const List<String> _perifocalContractLines = [
  '/// Semi-major axis: a = (mu / n^2)^(1/3), with mu = 398600.4418 km^3/s^2 (WGS-84).',
  '/// Mean motion: the Kozai mean motion of the element set, used as is.',
  '/// Perifocal position: x = a (cos E - e), y = a sqrt(1 - e^2) sin E, z = 0.',
  '/// Perifocal velocity: sqrt(mu a) / r * (-sin E, sqrt(1 - e^2) cos E, 0), r = a (1 - e cos E).',
  '/// Rotation: R3(-raan) R1(-i) R3(-argp), from perifocal to inertial axes.',
  '/// Frame: the inertial frame of the elements; TEME for elements read from a TLE.',
  '/// Units: km, km/s and radians.',
  '/// Reference: CelesTrak fundamentals-of-astrodynamics, frame_conversions.py, coe2rv (Vallado: 2022, Ex. 2-6).',
  'const double wgs84MuKm3S2 = 398600.4418;',
];

const List<String> _stateVectorContractLines = [
  '/// Cartesian vector: components x, y and z along the axes of one frame.',
  '/// State vector: position in km and velocity in km/s, in the same frame.',
];

const List<String> _perifocalDeclarations = [
  'double semiMajorAxisKmFromMeanMotion(double meanMotionRadS)',
  _factoryDeclaration,
];

const List<String> _stateVectorDeclarations = [
  'final class CartesianVector',
  'const CartesianVector(this.x, this.y, this.z)',
  'final double x',
  'final double y',
  'final double z',
  'final class StateVector',
  'const StateVector({required this.positionKm, required this.velocityKmS})',
  'final CartesianVector positionKm',
  'final CartesianVector velocityKmS',
];

const List<String> _factoryParameterLines = [
  'required double semiMajorAxisKm,',
  'required double eccentricity,',
  'required double inclinationRad,',
  'required double raanRad,',
  'required double argumentOfPerigeeRad,',
  'required double eccentricAnomalyRad,',
];

const List<String> _citationLines = [
  '// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.',
  '// Vallado repository, test_frame_conversions.py, test_coe2rv "Vallado, 2022, Ex. 2-6": p = 11067.790 km, e = 0.83285, i = 87.87 deg, raan = 227.89 deg, argp = 53.38 deg, nu = 92.335 deg.',
  '// Vallado repository, test_frame_conversions.py, test_perifocal_transform "From Vallado Example 2-6, 2022": P, Q and W unit vectors.',
  '// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005 and 28129; semi-major axes derived under ADR-0005.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);

String _tag(int n) => '[REQ-ORB-005.$n]';

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

/// Records a problem for each of [declarations] that no trimmed line of
/// [lines] starts with, followed by a character that cannot continue a name.
void _checkDeclarations(
  List<String> lines,
  List<String> declarations,
  String fileLabel,
  List<String> problems,
) {
  final trimmed = lines.map((line) => line.trim()).toList();
  for (final declaration in declarations) {
    final pattern = RegExp('^${RegExp.escape(declaration)}(?![A-Za-z0-9_\$])');
    if (!trimmed.any(pattern.hasMatch)) {
      problems.add('$fileLabel has no declaration "$declaration".');
    }
  }
}

/// Checks that the lines directly after the line that starts with
/// [_factoryDeclaration] are [_factoryParameterLines], in order.
void _checkFactoryParameters(
  List<String> lines,
  String fileLabel,
  List<String> problems,
) {
  final trimmed = lines.map((line) => line.trim()).toList();
  final index = trimmed.indexWhere(
    (line) => line.startsWith(_factoryDeclaration),
  );
  if (index < 0) return; // _checkDeclarations already records it.
  final following = trimmed
      .skip(index + 1)
      .take(_factoryParameterLines.length)
      .toList();
  for (var k = 0; k < _factoryParameterLines.length; k++) {
    final actual = k < following.length ? following[k] : '';
    if (actual != _factoryParameterLines[k]) {
      problems.add(
        '$fileLabel: parameter line ${k + 1} after "$_factoryDeclaration" '
        'must be "${_factoryParameterLines[k]}".',
      );
    }
  }
}

/// Checks that line `// REQ-ORB-005.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-005.$n';
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
  // REQ-ORB-005.6
  test('the new library files are placed, exported and documented', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final perifocalLines = _readLines(root, _perifocalLibPath, problems);
    if (perifocalLines != null) {
      _checkLines(
        perifocalLines,
        _perifocalContractLines,
        _perifocalLibPath,
        problems,
      );
      _checkDeclarations(
        perifocalLines,
        _perifocalDeclarations,
        _perifocalLibPath,
        problems,
      );
      _checkFactoryParameters(perifocalLines, _perifocalLibPath, problems);
    }

    final stateVectorLines = _readLines(root, _stateVectorLibPath, problems);
    if (stateVectorLines != null) {
      _checkLines(
        stateVectorLines,
        _stateVectorContractLines,
        _stateVectorLibPath,
        problems,
      );
      _checkDeclarations(
        stateVectorLines,
        _stateVectorDeclarations,
        _stateVectorLibPath,
        problems,
      );
      for (final line in stateVectorLines) {
        final trimmed = line.trimLeft();
        if (_mutableLinePrefixes.any(trimmed.startsWith)) {
          problems.add(
            '$_stateVectorLibPath has a mutable declaration: "$line".',
          );
        }
      }
    }

    final publicLines = _readLines(root, _publicLibPath, problems);
    if (publicLines != null) {
      _checkLines(publicLines, _exportLines, _publicLibPath, problems);
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-ORB-005.7
  test('the perifocal module is pure, cited and test-hygienic', () {
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
      if (mathLines.join('\n').contains(_skipToken)) {
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
