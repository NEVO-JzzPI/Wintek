// Guard for the SGP4 adapter of specs/req-orb-010.md (requirements 6 to 9).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-orb-010.md';
const String _adapterLibPath =
    'packages/orbital_core/lib/src/sgp4_propagator.dart';
const String _publicLibPath = 'packages/orbital_core/lib/orbital_core.dart';
const String _coreManifestPath = 'packages/orbital_core/pubspec.yaml';
const String _lockfilePath = 'pubspec.lock';
const String _mathTestPath =
    'packages/orbital_core/test/sgp4_propagator_test.dart';
const String _dataPath =
    'packages/orbital_core/test/sgp4_verification_data.dart';
const String _tleFixturePath =
    'packages/orbital_core/test/fixtures/vallado/SGP4-VER.TLE';
const String _outputFixturePath =
    'packages/orbital_core/test/fixtures/vallado/tcppver.out';
const String _guardTestPath = 'test/orbital_core_sgp4_guard_test.dart';
const String _libPath = 'packages/orbital_core/lib';

const List<String> _dartRoots = [
  'lib',
  'test',
  'packages/orbital_core/lib',
  'packages/orbital_core/test',
];

// Split so that this file does not contain the forbidden substrings itself.
const String _libraryToken =
    'package:'
    'satellite_observer';
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const String _libraryImportLine =
    "import '$_libraryToken/satellite_observer.dart' as sgp4;";

const List<String> _adapterImportLines = [
  "import 'earth_fixed.dart';",
  "import 'gmst.dart';",
  "import 'julian_date.dart';",
  "import 'orbital_elements.dart';",
  "import 'propagator.dart';",
  "import 'state_vector.dart';",
];

const String _exportLine = "export 'src/sgp4_propagator.dart';";

const List<String> _outsidePrefixes = [
  "import 'package:",
  'import "package:',
  'export',
];

const List<String> _requiredCalls = [
  'JulianDate.fromUtc(',
  'gmstRad(',
  'ecefPositionKm(',
  'sgp4.GpElements.fromMeanElements(',
  'sgp4.Sgp4Engine(',
  'sgp4.GravityModel.wgs72',
  'on sgp4.PropagationException',
  'on sgp4.InvalidElementsException',
];

const List<String> _forbiddenCalls = [
  'GpElements.fromTle(',
  'GravityModel.wgs84',
  'SatelliteObserver',
  'Observer(',
  'subPointAt',
  'lookAngleAt',
  'passes(',
];

const List<String> _copiedConstants = ['398600', '6378', '1082616'];

const String _declaration =
    'final class Sgp4Propagator implements Propagator {';
const String _constructorPrefix = 'Sgp4Propagator(this.elements)';
const String _elementsLine = 'final OrbitalElements elements;';
const String _stateAtLine = 'PropagatedState stateAt(DateTime utc) {';

const List<String> _docLines = [
  '/// Model: SGP4 and SDP4 of Vallado et al., Revisiting Spacetrack Report #3 (AIAA 2006-6753), as implemented by satellite_observer 1.0.1 (ADR-0002).',
  '/// Gravity model: WGS-72, selected by name from the library; this adapter declares no gravity constant.',
  "/// Operation mode: improved ('i'), fixed by the library and confirmed by the official vectors.",
  '/// Elements: built from the fields of OrbitalElements, in degrees and revolutions per day; the TLE lines are not kept.',
  '/// Output: TEME position in km and velocity in km/s; GMST and ECEF as Propagator defines them.',
  '/// Errors: the ArgumentError of JulianDate.fromUtc, checked before the library is called; PropagationException when the library cannot initialize the element set or reports an SGP4 error code.',
  '/// Reference: SGP4-VER.TLE and tcppver.out of Vallado et al., 30 element sets and 588 states (specs/req-orb-010.md).',
];

const String _pinLine = '  satellite_observer: 1.0.1';
const String _lockEntryLine = '  satellite_observer:';
const String _lockHashLine =
    'sha256: "39c57843b8d92c6c9e63f362afb135973bd00956471ba50428801217661dca83"';
const String _lockVersionLine = 'version: "1.0.1"';

const Set<int> _rejectedCatalogs = {33333, 33334, 33335};

// Catalog number and row count of each accepted set, in file order.
const List<(int, int)> _acceptedSets = [
  (5, 13),
  (4632, 5),
  (6251, 25),
  (8195, 25),
  (9880, 25),
  (9998, 14),
  (11801, 5),
  (14128, 25),
  (16925, 13),
  (20413, 26),
  (21897, 25),
  (22312, 23),
  (22674, 25),
  (23177, 13),
  (23333, 15),
  (23599, 37),
  (24208, 13),
  (25954, 26),
  (26900, 4),
  (26975, 25),
  (28057, 25),
  (28129, 13),
  (28350, 13),
  (28623, 13),
  (28626, 13),
  (28872, 11),
  (29141, 22),
  (29238, 13),
  (88888, 13),
  (20413, 70),
];

const List<String> _citationLines = [
  '// Vallado, Crawford, Hujsak and Kelso, Revisiting Spacetrack Report #3, AIAA 2006-6753: SGP4-VER.TLE and tcppver.out.',
  '// SGP4-VER.TLE: https://celestrak.org/publications/AIAA/2006-6753/AIAA-2006-6753.zip, sgp4/cpp/testsgp4/SGP4-VER.TLE, line endings converted to LF.',
  '// tcppver.out: https://github.com/brandon-rhodes/python-sgp4, sgp4/tcppver.out at commit 0f06a9147333e5a82197b5c04f5e87b477deca9e.',
  '// Synthetic 180-degree element set: NOAA 14 with inclination 180.0000, built for specs/req-orb-010.md with valid checksums; not a published object.',
];

final RegExp _forbiddenCoreImport = RegExp(
  r'''^(import|export)\s+['"](dart:io|dart:ffi|package:flutter[^'"]*)['"]''',
);
final RegExp _forbiddenTestImport = RegExp(
  r'''^(import|export)\s+['"]([^'"]*/src/[^'"]*|\.\.?/[^'"]*|dart:io)['"]''',
);
final RegExp _privateWord = RegExp(r'(^|[^A-Za-z0-9_])_[A-Za-z0-9_]');
final RegExp _whitespace = RegExp(r'\s+');

String _tag(int n) => '[REQ-ORB-010.$n]';

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

/// Every `.dart` file under [relativeDir], or an empty list when it is
/// missing.
List<File> _dartFiles(Directory root, String relativeDir) {
  final dir = Directory('${root.path}/$relativeDir');
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

String _relative(Directory root, File file) => file.path
    .replaceAll('\\', '/')
    .substring(root.path.replaceAll('\\', '/').length + 1);

/// The entries of the fixture TLE file: pairs of lines 1 and 2.
List<List<String>> _entries(List<String> lines) {
  final entries = <List<String>>[];
  for (var i = 0; i + 1 < lines.length; i++) {
    if (lines[i].startsWith('1 ') && lines[i + 1].startsWith('2 ')) {
      entries.add([lines[i], lines[i + 1]]);
      i++;
    }
  }
  return entries;
}

/// The blocks of the fixture output file, each as its row texts.
List<List<String>> _blocks(List<String> lines) {
  final blocks = <List<String>>[];
  for (final line in lines) {
    if (line.contains(' xx')) {
      blocks.add([]);
      continue;
    }
    final fields = line.trim().split(_whitespace);
    if (fields.length >= 7 && blocks.isNotEmpty) {
      blocks.last.add(fields.take(7).join(' '));
    }
  }
  return blocks;
}

int? _catalog(String line1) =>
    line1.length >= 7 ? int.tryParse(line1.substring(2, 7).trim()) : null;

/// The tokens of the data lines of the verification data file.
List<String> _dataTokens(List<String> lines) {
  final tokens = <String>[];
  for (final line in lines) {
    final text = line.trim();
    if (text.length >= 3 && text.startsWith("'") && text.endsWith("',")) {
      final inner = text.substring(1, text.length - 2);
      if (!inner.contains("'")) tokens.add(inner);
    }
  }
  return tokens;
}

/// The lines of the class declared by [_declaration], after that line and up
/// to, not including, the first line equal to `}`; null when it is missing.
List<String>? _classBody(List<String> lines) {
  final index = lines.indexOf(_declaration);
  if (index < 0) return null;
  final body = <String>[];
  for (final line in lines.skip(index + 1)) {
    if (line == '}') break;
    body.add(line);
  }
  return body;
}

/// The text of [line] before its first `(`, ` =` or `;`.
String _declarationPrefix(String line) {
  var end = line.length;
  for (final stop in ['(', ' =', ';']) {
    final index = line.indexOf(stop);
    if (index >= 0 && index < end) end = index;
  }
  return line.substring(0, end);
}

/// Checks that line `// REQ-ORB-010.n` is followed by a line that starts with
/// one of [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = '// REQ-ORB-010.$n';
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

void main() {
  // REQ-ORB-010.6
  test('the verification data is the vendored originals', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final tleLines = _readLines(root, _tleFixturePath, problems);
    final outputLines = _readLines(root, _outputFixturePath, problems);
    final dataLines = _readLines(root, _dataPath, problems);

    for (final path in [_tleFixturePath, _outputFixturePath]) {
      final file = File('${root.path}/$path');
      if (file.existsSync()) _checkBytes(file, path, problems);
    }

    if (tleLines != null && outputLines != null) {
      final entries = _entries(tleLines);
      final blocks = _blocks(outputLines);
      if (entries.length != 33) {
        problems.add(
          '$_tleFixturePath holds ${entries.length} entries, not 33.',
        );
      }
      if (blocks.length != 33) {
        problems.add(
          '$_outputFixturePath holds ${blocks.length} blocks, not 33.',
        );
      }
      if (entries.length == blocks.length) {
        final expected = <String>[];
        final accepted = <(int, int)>[];
        for (var k = 0; k < entries.length; k++) {
          final catalog = _catalog(entries[k][0]);
          if (catalog == null || _rejectedCatalogs.contains(catalog)) continue;
          accepted.add((catalog, blocks[k].length));
          expected
            ..add(entries[k][0].substring(0, 69))
            ..add(entries[k][1].substring(0, 69))
            ..addAll(blocks[k]);
        }
        final rows = accepted.fold<int>(0, (sum, set) => sum + set.$2);
        if (accepted.length != 30 || rows != 588) {
          problems.add(
            'The accepted sets are ${accepted.length} with $rows rows, not 30 with 588.',
          );
        }
        for (var p = 0; p < accepted.length && p < _acceptedSets.length; p++) {
          if (accepted[p] != _acceptedSets[p]) {
            problems.add(
              'Accepted set ${p + 1} is catalog ${accepted[p].$1} with '
              '${accepted[p].$2} rows, not catalog ${_acceptedSets[p].$1} '
              'with ${_acceptedSets[p].$2} rows.',
            );
          }
        }
        if (dataLines != null) {
          final tokens = _dataTokens(dataLines);
          if (tokens.length != expected.length) {
            problems.add(
              '$_dataPath holds ${tokens.length} data lines, not ${expected.length}.',
            );
          }
          for (var i = 0; i < tokens.length && i < expected.length; i++) {
            if (tokens[i] != expected[i]) {
              problems.add(
                '$_dataPath: data line ${i + 1} is "${tokens[i]}", '
                'not "${expected[i]}".',
              );
              break;
            }
          }
        }
      }
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-ORB-010.7
  test('the adapter is placed, exported and the only user of the library', () {
    final root = _repoRoot(7);
    final problems = <String>[];

    final adapterLines = _readLines(root, _adapterLibPath, problems);
    final publicLines = _readLines(root, _publicLibPath, problems);
    if (publicLines != null) {
      _checkLines(publicLines, [_exportLine], _publicLibPath, problems);
    }

    for (final dir in _dartRoots) {
      for (final file in _dartFiles(root, dir)) {
        final label = _relative(root, file);
        if (label == _adapterLibPath) continue;
        if (file.readAsStringSync().contains(_libraryToken)) {
          problems.add('$label must not reference $_libraryToken.');
        }
      }
    }

    if (adapterLines != null) {
      _checkLines(
        adapterLines,
        [_libraryImportLine, ..._adapterImportLines],
        _adapterLibPath,
        problems,
      );
      for (final line in adapterLines) {
        final start = line.trimLeft();
        if (_outsidePrefixes.any(start.startsWith) &&
            line.trim() != _libraryImportLine) {
          problems.add(
            '$_adapterLibPath has an outside import or export: "$line".',
          );
        }
        if (line.contains('$_libraryToken/src/')) {
          problems.add(
            '$_adapterLibPath imports the library internals: "$line".',
          );
        }
      }
      final code = _codeLines(adapterLines);
      for (final call in _requiredCalls) {
        if (!code.any((line) => line.contains(call))) {
          problems.add('$_adapterLibPath has no code line with "$call".');
        }
      }
      for (final line in code) {
        for (final call in _forbiddenCalls) {
          if (line.contains(call)) {
            problems.add('$_adapterLibPath has "$call" in "$line".');
          }
        }
        for (final constant in _copiedConstants) {
          if (line.contains(constant)) {
            problems.add(
              '$_adapterLibPath copies the constant $constant: "$line".',
            );
          }
        }
      }
    }

    if (problems.isNotEmpty) _failWith(7, problems);
  });

  // REQ-ORB-010.8
  test('the adapter names and documented contract are fixed', () {
    final root = _repoRoot(8);
    final problems = <String>[];

    final lines = _readLines(root, _adapterLibPath, problems);
    if (lines != null) {
      final trimmed = lines.map((line) => line.trim()).toList();
      final index = trimmed.indexOf(_declaration);
      if (index < 0) {
        problems.add('$_adapterLibPath has no line equal to "$_declaration".');
      } else {
        final docBlock = <String>{};
        for (var k = index - 1; k >= 0 && trimmed[k].startsWith('///'); k--) {
          docBlock.add(trimmed[k]);
        }
        for (final line in _docLines) {
          if (!docBlock.contains(line)) {
            problems.add(
              '$_adapterLibPath: the doc block directly above "$_declaration" has no line equal to "$line".',
            );
          }
        }
      }

      final body = _classBody(lines);
      if (body == null) {
        problems.add('$_adapterLibPath has no class body for "$_declaration".');
      } else {
        final bodyTrimmed = body.map((line) => line.trim()).toList();
        if (!bodyTrimmed.any((line) => line.startsWith(_constructorPrefix))) {
          problems.add(
            '$_adapterLibPath has no constructor starting with "$_constructorPrefix".',
          );
        }
        for (final member in [_elementsLine, _stateAtLine]) {
          final at = bodyTrimmed.indexOf(member);
          if (at < 0) {
            problems.add('$_adapterLibPath has no line equal to "$member".');
          } else if (at == 0 || bodyTrimmed[at - 1] != '@override') {
            problems.add(
              '$_adapterLibPath: the line before "$member" must be "@override".',
            );
          }
        }
        for (final line in body) {
          if (!(line.startsWith('  ') && line.length > 2 && line[2] != ' ')) {
            continue;
          }
          final text = line.trim();
          if (text.startsWith('//') || text.startsWith('@') || text == '}') {
            continue;
          }
          if (text == _elementsLine ||
              text == _stateAtLine ||
              text.startsWith(_constructorPrefix)) {
            continue;
          }
          if (!_privateWord.hasMatch(_declarationPrefix(text))) {
            problems.add('$_adapterLibPath declares a public member: "$line".');
          }
        }
      }

      for (final line in lines) {
        if (line.isEmpty || line.startsWith(' ')) continue;
        if (line.startsWith('//') ||
            line.startsWith("import '") ||
            line == '}' ||
            line == _declaration) {
          continue;
        }
        problems.add(
          '$_adapterLibPath has an unexpected top-level line: "$line".',
        );
      }
    }

    if (problems.isNotEmpty) _failWith(8, problems);
  });

  // REQ-ORB-010.9
  test('the dependency is pinned and the new files are pure and hygienic', () {
    final root = _repoRoot(9);
    final problems = <String>[];

    for (final path in [
      _mathTestPath,
      _dataPath,
      _tleFixturePath,
      _outputFixturePath,
      _adapterLibPath,
      _publicLibPath,
      _specPath,
    ]) {
      if (!File('${root.path}/$path').existsSync()) {
        problems.add('Expected to find $path, but it is missing.');
      }
    }

    final manifestLines = _readLines(root, _coreManifestPath, problems);
    if (manifestLines != null) {
      final start = manifestLines.indexWhere(
        (line) => line.trimRight() == 'dependencies:',
      );
      final section = <String>[];
      if (start >= 0) {
        for (final line in manifestLines.skip(start + 1)) {
          if (line.isNotEmpty && !line.startsWith(' ')) break;
          section.add(line);
        }
      }
      if (!section.contains(_pinLine)) {
        problems.add(
          '$_coreManifestPath must declare "$_pinLine" under dependencies:.',
        );
      }
    }

    final lockLines = _readLines(root, _lockfilePath, problems);
    if (lockLines != null) {
      final start = lockLines.indexOf(_lockEntryLine);
      final block = <String>[];
      if (start >= 0) {
        for (final line in lockLines.skip(start + 1)) {
          if (line.startsWith('  ') && line.length > 2 && line[2] != ' ') {
            break;
          }
          block.add(line.trim());
        }
      }
      for (final line in [_lockHashLine, _lockVersionLine]) {
        if (!block.contains(line)) {
          problems.add(
            '$_lockfilePath: the entry "${_lockEntryLine.trim()}" has no line "$line".',
          );
        }
      }
    }

    final libDir = Directory('${root.path}/$_libPath');
    if (!libDir.existsSync()) {
      problems.add('Expected to find $_libPath, but it is missing.');
    }
    for (final file in _dartFiles(root, _libPath)) {
      final label = _relative(root, file);
      for (final line in file.readAsStringSync().split('\n')) {
        if (_forbiddenCoreImport.hasMatch(line.trimLeft())) {
          problems.add('$label has a forbidden import/export: "$line".');
        }
      }
      _checkBytes(file, label, problems);
    }

    final mathLines = _readLines(root, _mathTestPath, problems);
    if (mathLines != null) {
      _checkLines(
        mathLines,
        [
          "import 'package:orbital_core/orbital_core.dart';",
          "import 'sgp4_verification_data.dart';",
        ],
        _mathTestPath,
        problems,
      );
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

    final dataLines = _readLines(root, _dataPath, problems);
    if (dataLines != null) {
      for (final line in dataLines) {
        final start = line.trimLeft();
        if (start.startsWith('import') || start.startsWith('export')) {
          problems.add('$_dataPath must not import or export: "$line".');
        }
      }
      _checkLines(dataLines, _citationLines, _dataPath, problems);
      _checkBytes(File('${root.path}/$_dataPath'), _dataPath, problems);
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
      for (var n = 6; n <= 9; n++) {
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
    if (specFile.existsSync()) _checkBytes(specFile, _specPath, problems);

    if (problems.isNotEmpty) _failWith(9, problems);
  });
}
