// Guard for the orbital elements of specs/req-orb-003.md (REQ-ORB-003.6 to .8).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-003.md';
const String _elementsLibPath =
    'packages/orbital_core/lib/src/orbital_elements.dart';
const String _parserLibPath = 'packages/orbital_core/lib/src/tle_parser.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _mathTestPath = 'packages/orbital_core/test/tle_parser_test.dart';
const String _guardTestPath = 'test/orbital_core_elements_guard_test.dart';
const String _libPath = 'packages/orbital_core/lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';
const String _copyWithToken =
    'copy'
    'With';

const List<String> _mutableLinePrefixes = ['set ', 'var ', 'late '];

const List<String> _exportLines = [
  "export 'src/orbital_elements.dart';",
  "export 'src/tle_parser.dart';",
];

const List<String> _elementsContractLines = [
  '/// Units: radians, seconds and radians per second; B* in inverse Earth radii.',
  '/// Mean motion: the Kozai mean motion published in the TLE.',
  '/// Mean motion terms: the TLE values of ndot / 2 and nddot / 6, in SI units.',
];

const List<String> _publicDeclarations = [
  'final class OrbitalElements',
  'factory OrbitalElements.fromTle(String line1, String line2)',
  'int get catalogNumber',
  'DateTime get epoch',
  'double get inclinationRad',
  'double get raanRad',
  'double get eccentricity',
  'double get argumentOfPerigeeRad',
  'double get meanAnomalyRad',
  'double get meanMotionRadS',
  'double get ndotOver2RadS2',
  'double get nddotOver6RadS3',
  'double get bstarInverseEarthRadii',
];

const List<String> _parserContractLines = [
  '/// Epoch years: 57 to 99 are 1957 to 1999; 00 to 56 are 2000 to 2056.',
  '/// Checksum: digits count their value, minus signs count 1, all else 0, modulo 10.',
  '/// Reference: CelesTrak, NORAD Two-Line Element Set Format.',
];

const List<String> _citationLines = [
  '// CelesTrak, NORAD Two-Line Element Set Format, https://celestrak.org/NORAD/documentation/tle-fmt.php: NOAA 14 (23455) example.',
  '// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005, 23599 and 28129.',
  '// Vallado et al., AIAA 2006-6753, SGP4.cpp twoline2rv: deg2rad = pi / 180, xpdotp = 1440 / (2 pi), years below 57 are 2000 + yy.',
  '// Vallado et al., AIAA 2006-6753, TestSGP4/00005.e, 23599.e, 28129.e: ScenarioEpoch of each set.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);

String _tag(int n) => '[REQ-ORB-003.$n]';

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

/// Checks that line `// REQ-ORB-003.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-003.$n';
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
  // REQ-ORB-003.6
  test('the element set is immutable', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final lines = _readLines(root, _elementsLibPath, problems);
    if (lines != null) {
      for (final line in lines) {
        final trimmed = line.trim();
        if (_mutableLinePrefixes.any(trimmed.startsWith)) {
          problems.add('$_elementsLibPath has a mutable declaration: "$line".');
        }
      }
      if (lines.join('\n').contains(_copyWithToken)) {
        problems.add('$_elementsLibPath must not offer a copy method.');
      }
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-ORB-003.7
  test('the element set and the parser are placed and documented', () {
    final root = _repoRoot(7);
    final problems = <String>[];

    final elementsLines = _readLines(root, _elementsLibPath, problems);
    if (elementsLines != null) {
      _checkLines(
        elementsLines,
        _elementsContractLines,
        _elementsLibPath,
        problems,
      );
      _checkDeclarations(
        elementsLines,
        _publicDeclarations,
        _elementsLibPath,
        problems,
      );
    }

    final parserLines = _readLines(root, _parserLibPath, problems);
    if (parserLines != null) {
      _checkLines(parserLines, _parserContractLines, _parserLibPath, problems);
    }

    final publicLines = _readLines(root, _publicLibPath, problems);
    if (publicLines != null) {
      _checkLines(publicLines, _exportLines, _publicLibPath, problems);
    }

    if (problems.isNotEmpty) _failWith(7, problems);
  });

  // REQ-ORB-003.8
  test('the element set is pure, cited and test-hygienic', () {
    final root = _repoRoot(8);
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
      for (var n = 6; n <= 8; n++) {
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

    if (problems.isNotEmpty) _failWith(8, problems);
  });
}
