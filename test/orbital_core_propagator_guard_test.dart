// Guard for the propagator interface and the Kepler propagator of
// specs/req-orb-009.md (requirements 5 to 7).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-009.md';
const String _propagatorLibPath =
    'packages/orbital_core/lib/src/propagator.dart';
const String _keplerLibPath =
    'packages/orbital_core/lib/src/kepler_propagator.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _mathTestPath = 'packages/orbital_core/test/propagator_test.dart';
const String _guardTestPath = 'test/orbital_core_propagator_guard_test.dart';
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

const String _interfaceDeclaration = 'abstract interface class Propagator {';
const String _stateDeclaration = 'base class PropagatedState {';
const String _exceptionDeclaration =
    'final class PropagationException implements Exception {';
const String _keplerStateDeclaration =
    'final class KeplerPropagatedState extends PropagatedState {';
const String _keplerPropagatorDeclaration =
    'final class KeplerPropagator implements Propagator {';

const List<String> _publicExportLines = [
  "export 'src/kepler_propagator.dart';",
  "export 'src/propagator.dart';",
];

const List<String> _propagatorImportLines = [
  "import 'orbital_elements.dart';",
  "import 'state_vector.dart';",
];

const List<String> _keplerImportLines = [
  "import 'earth_fixed.dart';",
  "import 'gmst.dart';",
  "import 'julian_date.dart';",
  "import 'kepler.dart';",
  "import 'orbital_elements.dart';",
  "import 'perifocal.dart';",
  "import 'propagator.dart';",
];

const List<String> _outsideCodePrefixes = [
  "import 'package:",
  'import "package:',
  "import 'dart:math'",
  'import "dart:math"',
  'export',
];

const List<String> _composedCalls = [
  'meanAnomalyAtRad(',
  'eccentricAnomalyRad(',
  'semiMajorAxisKmFromMeanMotion(',
  'inertialStateVector(',
  'JulianDate.fromUtc(',
  'gmstRad(',
  'ecefPositionKm(',
];

const List<String> _forbiddenCalls = [
  'sin(',
  'cos(',
  'sqrt(',
  'pow(',
  'atan2(',
  'remainder(',
  '% ',
];

const List<String> _copiedConstants = ['398600', '6378', '86400'];

final RegExp _digitOrOperator = RegExp(r'[0-9+\-*/%]');

const Map<String, List<String>> _propagatorDocBlocks = {
  _interfaceDeclaration: [
    '/// Seam: every propagator is bound to one element set and returns its state at a UTC instant.',
    '/// Implementations: KeplerPropagator (two-body, in this package) and the SGP4 adapter (req-orb-010).',
    '/// Errors: ArgumentError for an instant that is not UTC or outside the range of JulianDate.fromUtc; PropagationException when the model cannot propagate the element set to the instant.',
    '/// Results: every number of a returned state is finite; a propagator throws instead of returning NaN or infinity.',
    '/// Calls: a state depends only on the element set and the instant, never on earlier calls or their order.',
  ],
  _stateDeclaration: [
    '/// Instant: the UTC instant passed to stateAt.',
    '/// Inertial state: position in km and velocity in km/s, in the inertial frame of the elements; TEME for elements read from a TLE.',
    '/// GMST: gmstRad of the Julian date of the instant (IAU-82), from 0 inclusive to 2 pi exclusive, in radians.',
    '/// ECEF: ecefPositionKm of the inertial position at that GMST, in km; Earth-fixed axes without polar motion (PEF).',
    '/// Not carried: geodetic coordinates, derived values and any Earth-relative velocity.',
  ],
  _exceptionDeclaration: [
    '/// Thrown by a propagator when its model cannot propagate the element set to the instant, such as a decayed object.',
    '/// Not thrown for an invalid instant, which is an ArgumentError, and never thrown by KeplerPropagator.',
  ],
};

const Map<String, List<String>> _keplerDocBlocks = {
  _keplerStateDeclaration: [
    '/// Mean anomaly: meanAnomalyAtRad of the elements at the instant, from 0 inclusive to 2 pi exclusive, in radians.',
    '/// Eccentric anomaly: eccentricAnomalyRad of that mean anomaly and the eccentricity, from 0 inclusive to 2 pi exclusive, in radians.',
  ],
  _keplerPropagatorDeclaration: [
    '/// Model: two-body Kepler propagation, composed from the functions of req-orb-002 and req-orb-004 to req-orb-006, with no formula of its own.',
    '/// Mean anomaly: linear, M = M0 + n (t - t0); ndot / 2, nddot / 6 and B* are ignored, so there is no drag and no J2.',
    '/// Semi-major axis: semiMajorAxisKmFromMeanMotion of the Kozai mean motion, with mu = wgs84MuKm3S2.',
    '/// Errors: the ArgumentError of JulianDate.fromUtc for an invalid instant, and the StateError of eccentricAnomalyRad if it does not converge; never PropagationException.',
    '/// Reference: none of its own; each composed function is validated against published values in its own spec.',
  ],
};

// The members of each class, trimmed, in order.
const Map<String, List<String>> _exactMembers = {
  _interfaceDeclaration: [
    'OrbitalElements get elements;',
    'PropagatedState stateAt(DateTime utc);',
  ],
  _stateDeclaration: [
    'const PropagatedState({',
    'required this.utc,',
    'required this.inertialState,',
    'required this.gmstRad,',
    'required this.ecefPositionKm,',
    '});',
    'final DateTime utc;',
    'final StateVector inertialState;',
    'final double gmstRad;',
    'final CartesianVector ecefPositionKm;',
  ],
  _exceptionDeclaration: [
    'const PropagationException(this.message);',
    'final String message;',
    '@override',
    "String toString() => 'PropagationException: \$message';",
  ],
  _keplerStateDeclaration: [
    'const KeplerPropagatedState({',
    'required super.utc,',
    'required super.inertialState,',
    'required super.gmstRad,',
    'required super.ecefPositionKm,',
    'required this.meanAnomalyRad,',
    'required this.eccentricAnomalyRad,',
    '});',
    'final double meanAnomalyRad;',
    'final double eccentricAnomalyRad;',
  ],
};

// The members of the Kepler propagator at exactly two spaces, untrimmed.
const List<String> _keplerPropagatorMembers = [
  '  KeplerPropagator(this.elements);',
  '  @override',
  '  final OrbitalElements elements;',
  '  @override',
  '  KeplerPropagatedState stateAt(DateTime utc) {',
  '  }',
];

const List<String> _propagatorTopLevel = [
  _interfaceDeclaration,
  _stateDeclaration,
  _exceptionDeclaration,
];

const List<String> _keplerTopLevel = [
  _keplerStateDeclaration,
  _keplerPropagatorDeclaration,
];

const List<String> _citationLines = [
  '// CelesTrak, NORAD Two-Line Element Set Format, https://celestrak.org/NORAD/documentation/tle-fmt.php: NOAA 14 (23455) example.',
  '// Vallado et al., Revisiting Spacetrack Report #3, AIAA 2006-6753, SGP4-VER.TLE: sets 00005, 23599 and 28129.',
  '// Synthetic GEO element set 99999, built for specs/req-orb-009.md with valid checksums; not a published object.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);

String _tag(int n) => '[REQ-ORB-009.$n]';

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

List<String> _codeLines(List<String> lines) =>
    lines.where((line) => !line.trimLeft().startsWith('//')).toList();

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

/// Checks the doc block directly above each declaration of [docBlocks].
void _checkDocBlocks(
  List<String> lines,
  Map<String, List<String>> docBlocks,
  String fileLabel,
  List<String> problems,
) {
  final trimmed = lines.map((line) => line.trim()).toList();
  for (final entry in docBlocks.entries) {
    final index = trimmed.indexOf(entry.key);
    if (index < 0) {
      problems.add('$fileLabel has no line equal to "${entry.key}".');
      continue;
    }
    final docBlock = <String>{};
    for (var k = index - 1; k >= 0 && trimmed[k].startsWith('///'); k--) {
      docBlock.add(trimmed[k]);
    }
    for (final line in entry.value) {
      if (!docBlock.contains(line)) {
        problems.add(
          '$fileLabel: the doc block directly above "${entry.key}" has no line equal to "$line".',
        );
      }
    }
  }
}

/// The lines of the class declared by [declaration], after that line and up
/// to, not including, the first line equal to `}`; null when it is missing.
List<String>? _classBody(List<String> lines, String declaration) {
  final index = lines.indexOf(declaration);
  if (index < 0) return null;
  final body = <String>[];
  for (final line in lines.skip(index + 1)) {
    if (line == '}') break;
    body.add(line);
  }
  return body;
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Checks that the members of each class of [expected] are exactly the
/// listed lines, once trimmed, leaving out empty and doc lines.
void _checkExactMembers(
  List<String> lines,
  Map<String, List<String>> expected,
  String fileLabel,
  List<String> problems,
) {
  for (final entry in expected.entries) {
    final body = _classBody(lines, entry.key);
    if (body == null) {
      problems.add('$fileLabel has no line equal to "${entry.key}".');
      continue;
    }
    final members = body
        .where(
          (line) =>
              line.trim().isNotEmpty && !line.trimLeft().startsWith('///'),
        )
        .map((line) => line.trim())
        .toList();
    if (!_sameList(members, entry.value)) {
      problems.add(
        '$fileLabel: the members of "${entry.key}" must be exactly '
        '${entry.value.join(' | ')}, but are ${members.join(' | ')}.',
      );
    }
  }
}

/// Checks the members of the Kepler propagator at exactly two spaces.
void _checkKeplerPropagatorMembers(
  List<String> lines,
  String fileLabel,
  List<String> problems,
) {
  final body = _classBody(lines, _keplerPropagatorDeclaration);
  if (body == null) {
    problems.add(
      '$fileLabel has no line equal to "$_keplerPropagatorDeclaration".',
    );
    return;
  }
  final members = body
      .where(
        (line) =>
            line.startsWith('  ') &&
            line.length > 2 &&
            line[2] != ' ' &&
            !line.trimLeft().startsWith('///'),
      )
      .toList();
  if (!_sameList(members, _keplerPropagatorMembers)) {
    problems.add(
      '$fileLabel: the members of "$_keplerPropagatorDeclaration" must be exactly '
      '${_keplerPropagatorMembers.join(' | ')}, but are ${members.join(' | ')}.',
    );
  }
}

/// Records a problem for each line of [lines] at the first column that is not
/// a comment, an import, `}` or one of [allowed].
void _checkTopLevelDeclarations(
  List<String> lines,
  List<String> allowed,
  String fileLabel,
  List<String> problems,
) {
  for (final line in lines) {
    if (line.isEmpty || line.startsWith(' ')) continue;
    if (line.startsWith('//') ||
        line.startsWith("import '") ||
        line == '}' ||
        allowed.contains(line)) {
      continue;
    }
    problems.add('$fileLabel has an unexpected top-level line: "$line".');
  }
}

/// Checks that line `// REQ-ORB-009.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-009.$n';
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
  // REQ-ORB-009.5
  test('the propagator files are placed, exported and compose only', () {
    final root = _repoRoot(5);
    final problems = <String>[];

    final propagatorLines = _readLines(root, _propagatorLibPath, problems);
    final keplerLines = _readLines(root, _keplerLibPath, problems);

    if (propagatorLines != null) {
      _checkLines(
        propagatorLines,
        _propagatorImportLines,
        _propagatorLibPath,
        problems,
      );
    }
    if (keplerLines != null) {
      _checkLines(keplerLines, _keplerImportLines, _keplerLibPath, problems);
    }

    final publicLines = _readLines(root, _publicLibPath, problems);
    if (publicLines != null) {
      _checkLines(publicLines, _publicExportLines, _publicLibPath, problems);
    }

    for (final entry in {
      _propagatorLibPath: propagatorLines,
      _keplerLibPath: keplerLines,
    }.entries) {
      final lines = entry.value;
      if (lines == null) continue;
      for (final line in lines) {
        final start = line.trimLeft();
        if (_outsideCodePrefixes.any(start.startsWith)) {
          problems.add(
            '${entry.key} has an outside import or export: "$line".',
          );
        }
      }
      for (final line in _codeLines(lines)) {
        for (final constant in _copiedConstants) {
          if (line.contains(constant)) {
            problems.add(
              '${entry.key} copies the constant $constant: "$line".',
            );
          }
        }
      }
    }

    if (keplerLines != null) {
      final code = _codeLines(keplerLines);
      for (final call in _composedCalls) {
        if (!code.any((line) => line.contains(call))) {
          problems.add('$_keplerLibPath has no code line that calls $call.');
        }
      }
      for (final line in code) {
        for (final call in _forbiddenCalls) {
          if (line.contains(call)) {
            problems.add('$_keplerLibPath has "$call" in "$line".');
          }
        }
        if (_digitOrOperator.hasMatch(line)) {
          problems.add(
            '$_keplerLibPath has a digit or an arithmetic operator in "$line".',
          );
        }
      }
    }

    if (problems.isNotEmpty) _failWith(5, problems);
  });

  // REQ-ORB-009.6
  test('the propagator names and documented contract are fixed', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final propagatorLines = _readLines(root, _propagatorLibPath, problems);
    if (propagatorLines != null) {
      _checkDocBlocks(
        propagatorLines,
        _propagatorDocBlocks,
        _propagatorLibPath,
        problems,
      );
      _checkExactMembers(
        propagatorLines,
        {
          for (final key in _propagatorTopLevel)
            if (_exactMembers.containsKey(key)) key: _exactMembers[key]!,
        },
        _propagatorLibPath,
        problems,
      );
      _checkTopLevelDeclarations(
        propagatorLines,
        _propagatorTopLevel,
        _propagatorLibPath,
        problems,
      );
    }

    final keplerLines = _readLines(root, _keplerLibPath, problems);
    if (keplerLines != null) {
      _checkDocBlocks(keplerLines, _keplerDocBlocks, _keplerLibPath, problems);
      _checkExactMembers(
        keplerLines,
        {
          for (final key in _keplerTopLevel)
            if (_exactMembers.containsKey(key)) key: _exactMembers[key]!,
        },
        _keplerLibPath,
        problems,
      );
      _checkKeplerPropagatorMembers(keplerLines, _keplerLibPath, problems);
      _checkTopLevelDeclarations(
        keplerLines,
        _keplerTopLevel,
        _keplerLibPath,
        problems,
      );
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-ORB-009.7
  test('the propagator code is pure, cited and test-hygienic', () {
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
          'expected values come from the public functions.',
        );
      }
      _checkLines(mathLines, _citationLines, _mathTestPath, problems);
      for (var n = 1; n <= 4; n++) {
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
