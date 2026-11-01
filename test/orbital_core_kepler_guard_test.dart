// Guard for the Kepler solver of specs/req-orb-004.md (REQ-ORB-004.5 to .7).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-004.md';
const String _elapsedLibPath =
    'packages/orbital_core/lib/src/elapsed_time.dart';
const String _keplerLibPath = 'packages/orbital_core/lib/src/kepler.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _mathTestPath = 'packages/orbital_core/test/kepler_test.dart';
const String _guardTestPath = 'test/orbital_core_kepler_guard_test.dart';
const String _libPath = 'packages/orbital_core/lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const String _nonConvergenceMessage =
    'Kepler solver did not converge in 50 iterations.';
const String _stateErrorToken = 'StateError(';

const List<String> _exportLines = [
  "export 'src/elapsed_time.dart';",
  "export 'src/kepler.dart';",
];

const List<String> _elapsedContractLines = [
  '/// Elapsed time: ((day B - day A) + (fraction B - fraction A)) * 86400, in seconds.',
  '/// Sign: positive when B is later than A, negative when earlier, 0 when equal.',
  '/// Input: the two-part Julian dates of req-orb-001 only.',
];

const List<String> _keplerContractLines = [
  "/// Kepler's equation: M = E - e sin E, solved by Newton-Raphson.",
  '/// Initial guess: E0 = M - e when M > pi, otherwise M + e.',
  '/// Convergence: |E(k+1) - E(k)| <= 1e-12 rad within 50 iterations.',
  '/// Mean anomaly: M = M0 + n (t - t0), linear; ndot / 2 and nddot / 6 are not used.',
  "/// Normalization: Dart's % by 2 * pi; a result equal to 2 * pi becomes 0.",
  '/// Result range: 0 inclusive to 2π exclusive, in radians.',
  '/// Reference: CelesTrak fundamentals-of-astrodynamics, newton.py, newtonm (Vallado: 2022, p. 65, Algorithm 2).',
];

const List<String> _elapsedDeclarations = [
  'double elapsedSeconds(JulianDate from, JulianDate to)',
];

const List<String> _keplerDeclarations = [
  'double meanAnomalyAtRad(OrbitalElements elements, DateTime utc)',
  'double eccentricAnomalyRad(double meanAnomalyRad, double eccentricity)',
];

const List<String> _citationLines = [
  '// Vallado repository: https://github.com/CelesTrak/fundamentals-of-astrodynamics, software/python/tests/astro/twobody/test_newton.py, commit e90b6f6584dd53330e71ee5496aea2eea3853f9b.',
  '// Vallado repository, test_newton.py, newtonm row "Vallado Ex. 2-1": M = 235.4 deg, e = 0.4, E = 3.8486617450971616 rad.',
  '// Vallado repository, kepler.py, commit c05278b458e806775c91d1fe74b5ff6e583c8d82, line 217: linear mean anomaly; rows derived under ADR-0004.',
  '// Meeus, Astronomical Algorithms, 2nd ed., chapter 7: JD 2446822.5, 2447187.5, 2446966.0, 2447332.0, 2451179.5, 2451545.0; elapsed times derived under ADR-0004.',
  '// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005 and 28129.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);

String _tag(int n) => '[REQ-ORB-004.$n]';

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

/// Checks that line `// REQ-ORB-004.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-004.$n';
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
  // REQ-ORB-004.5
  test('the non-convergence error is present in the solver source', () {
    final root = _repoRoot(5);
    final problems = <String>[];

    final lines = _readLines(root, _keplerLibPath, problems);
    if (lines != null) {
      final text = lines.join('\n');
      if (!text.contains(_nonConvergenceMessage)) {
        problems.add(
          '$_keplerLibPath must contain the message "$_nonConvergenceMessage".',
        );
      }
      if (!text.contains(_stateErrorToken)) {
        problems.add('$_keplerLibPath must throw a $_stateErrorToken.');
      }
    }

    if (problems.isNotEmpty) _failWith(5, problems);
  });

  // REQ-ORB-004.6
  test('the new library files are placed, exported and documented', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final elapsedLines = _readLines(root, _elapsedLibPath, problems);
    if (elapsedLines != null) {
      _checkLines(
        elapsedLines,
        _elapsedContractLines,
        _elapsedLibPath,
        problems,
      );
      _checkDeclarations(
        elapsedLines,
        _elapsedDeclarations,
        _elapsedLibPath,
        problems,
      );
    }

    final keplerLines = _readLines(root, _keplerLibPath, problems);
    if (keplerLines != null) {
      _checkLines(keplerLines, _keplerContractLines, _keplerLibPath, problems);
      _checkDeclarations(
        keplerLines,
        _keplerDeclarations,
        _keplerLibPath,
        problems,
      );
    }

    final publicLines = _readLines(root, _publicLibPath, problems);
    if (publicLines != null) {
      _checkLines(publicLines, _exportLines, _publicLibPath, problems);
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-ORB-004.7
  test('the solver is pure, cited and test-hygienic', () {
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
      for (var n = 5; n <= 7; n++) {
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
