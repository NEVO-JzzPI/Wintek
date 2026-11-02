// Guard for the inertial to ECEF rotation of specs/req-orb-006.md
// (REQ-ORB-006.6 and .7).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-006.md';
const String _earthFixedLibPath =
    'packages/orbital_core/lib/src/earth_fixed.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _mathTestPath = 'packages/orbital_core/test/earth_fixed_test.dart';
const String _guardTestPath = 'test/orbital_core_earth_fixed_guard_test.dart';
const String _libPath = 'packages/orbital_core/lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const String _declarationLine = 'CartesianVector ecefPositionKm({';

const String _exportLine = "export 'src/earth_fixed.dart';";

const List<String> _docBlockLines = [
  '/// Rotation: r_ecef = R3(gmst) r_inertial, a rotation about the z axis.',
  '/// Input frame: the inertial frame of the elements; TEME for elements read from a TLE.',
  '/// Output frame: Earth-fixed axes without polar motion (PEF), used as ECEF.',
  '/// Ignored: polar motion and the kinematic terms added to GMST.',
  '/// Units: km and radians.',
  '/// Reference: CelesTrak fundamentals-of-astrodynamics, time/frame_conversions.py, teme2ecef (Vallado: 2022, p. 232-234).',
];

const List<String> _parameterLines = [
  'required CartesianVector inertialPositionKm,',
  'required double gmstRad,',
];

// The only lines allowed at the first column of the Earth-fixed library file,
// besides empty lines, comments and imports.
const List<String> _allowedFirstColumnLines = [_declarationLine, '}) {', '}'];

const List<String> _citationLines = [
  '// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/time/test_frame_conversions.py, commit 49df0479c950917c0a2c5ac31f2db6477bba57f6.',
  '// Vallado repository, test_frame_conversions.py, fixtures rva_teme and rva_pef (opt 80): TEME and PEF positions of one state, jdut1 = 2453101.5.',
  '// Vallado repository, test_frame_conversions.py, test_teme2ecef: TEME position to ECEF position with polar motion, jdut1 = 2453101.5.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);

String _tag(int n) => '[REQ-ORB-006.$n]';

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

/// Checks the doc block directly above [_declarationLine] and the two
/// parameter lines directly below it.
void _checkDeclaration(
  List<String> lines,
  String fileLabel,
  List<String> problems,
) {
  final trimmed = lines.map((line) => line.trim()).toList();
  final index = trimmed.indexOf(_declarationLine);
  if (index < 0) {
    problems.add('$fileLabel has no line equal to "$_declarationLine".');
    return;
  }
  final docBlock = <String>{};
  for (var k = index - 1; k >= 0 && trimmed[k].startsWith('///'); k--) {
    docBlock.add(trimmed[k]);
  }
  for (final line in _docBlockLines) {
    if (!docBlock.contains(line)) {
      problems.add(
        '$fileLabel: the doc block directly above "$_declarationLine" has no line equal to "$line".',
      );
    }
  }
  final following = trimmed
      .skip(index + 1)
      .take(_parameterLines.length)
      .toList();
  for (var k = 0; k < _parameterLines.length; k++) {
    final actual = k < following.length ? following[k] : '';
    if (actual != _parameterLines[k]) {
      problems.add(
        '$fileLabel: parameter line ${k + 1} after "$_declarationLine" '
        'must be "${_parameterLines[k]}".',
      );
    }
  }
}

/// Records a problem for each line of [lines] at the first column that is not
/// a comment, an import or one of [_allowedFirstColumnLines].
void _checkSingleTopLevelDeclaration(
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

/// Checks that line `// REQ-ORB-006.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-006.$n';
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
  // REQ-ORB-006.6
  test('the Earth-fixed library file is placed, exported and documented', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final earthFixedLines = _readLines(root, _earthFixedLibPath, problems);
    if (earthFixedLines != null) {
      _checkDeclaration(earthFixedLines, _earthFixedLibPath, problems);
      _checkSingleTopLevelDeclaration(
        earthFixedLines,
        _earthFixedLibPath,
        problems,
      );
    }

    final publicLines = _readLines(root, _publicLibPath, problems);
    if (publicLines != null) {
      _checkLines(publicLines, [_exportLine], _publicLibPath, problems);
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-ORB-006.7
  test('the Earth-fixed module is pure, cited and test-hygienic', () {
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
