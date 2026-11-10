// Guard for the satellite catalog of specs/req-dat-001.md (requirements 4 to 6).
//
// It reads files directly with File(...), so it introduces no dependency of
// its own, and every missing file is a failing test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-dat-001.md';
const String _catalogPath = 'lib/domain/satellite_catalog.dart';
const String _unitTestPath = 'test/domain/satellite_catalog_test.dart';
const String _snapshotPath = 'test/domain/celestrak_tle_snapshot.dart';
const String _guardTestPath = 'test/satellite_catalog_guard_test.dart';
const String _adrPath = 'docs/adr/ADR-0003-tle-element-sets-and-units.md';
const String _appLibPath = 'lib';
const String _coreLibPath = 'packages/orbital_core/lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const List<String> _displayNames = [
  'ISS',
  'Tiangong',
  'FASat-Charlie',
  'GOES-East',
];
const List<String> _noradIds = ['25544', '48274', '38011', '60133'];

const String _declaration = 'enum TrackedObject {';
const List<String> _docLines = [
  '/// The four objects that Wintek tracks, in display order (specs/req-dat-001.md).',
  '/// NORAD ID: the catalog number from 1 to 99999 that OrbitalElements.catalogNumber reads from a TLE, where it has five digits (ADR-0003, decision 1).',
  '/// Source: CelesTrak SATCAT, checked on 2026-11-10: ISS (ZARYA), CSS (TIANHE), SSOT and GOES 19.',
  '/// GOES-East is a role, filled by GOES 19 (2024-119A) since 2025-04-07; a change of satellite is a change of specs/req-dat-001.md, never a runtime lookup.',
];
const List<String> _fieldLines = [
  'final String displayName;',
  'final int noradId;',
];
const List<String> _memberPrefixes = [
  'iss(',
  'tiangong(',
  'fasatCharlie(',
  'goesEast(',
  'const TrackedObject(',
];

const String _adrNote =
    '- **Note (2026-11-10, req-dat-001):** GOES-East is GOES 19, catalog number 60133, which has five digits. Decision 1 holds and no superseding ADR is needed.';
const String _adrNoteSibling =
    '- Catalog numbers above 99999 (Alpha-5) are not supported.';

const String _snapshotHeader = 'Snapshot tokens, in file order:';
const String _fenceOpen = '```text';
const String _fenceClose = '```';
const int _snapshotTokenCount = 12;

const List<String> _snapshotCitations = [
  '// Source: CelesTrak GP data, https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, one request per object (specs/req-dat-001.md).',
  '// Fetched: 2026-11-10, once per object while drafting specs/req-dat-001.md; no test fetches it again.',
  '// Identity snapshot: its epochs and elements are not reference values for any formula (Constitution principle 6).',
];
const List<String> _unitTestCitations = [
  '// Catalog source: CelesTrak SATCAT, https://celestrak.org/satcat/records.php?CATNR=<NORAD ID>, checked on 2026-11-10.',
  '// GOES-East: GOES 19 since 2025-04-07, https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters',
];
const List<String> _unitTestImports = [
  "import 'package:flutter_test/flutter_test.dart';",
  "import 'package:orbital_core/orbital_core.dart';",
  "import 'package:wintek/domain/satellite_catalog.dart';",
  "import 'celestrak_tle_snapshot.dart';",
];

final RegExp _privateWord = RegExp(r'(^|[^A-Za-z0-9_])_[A-Za-z0-9_]*');

String _tag(int n) => '[REQ-DAT-001.$n]';

String _marker(int n) => '// REQ-DAT-001.$n';

Never _failWith(int n, List<String> problems) {
  fail('${_tag(n)} ${problems.join(' ${_tag(n)} ')} See $_specPath.');
}

Directory _repoRoot(int n) => findRepoRoot(
  failurePrefix: '${_tag(n)} ',
  failureSuffix: 'See $_specPath.',
);

String _normalize(String path) => path.replaceAll('\\', '/');

bool _hasLine(List<String> lines, String text) =>
    lines.any((line) => line.trim() == text);

bool _isCodeLine(String line) => !line.trimLeft().startsWith('//');

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

/// Every `.dart` file under [relativeDir], or null when the directory is
/// missing (a problem is recorded).
List<File>? _dartFiles(
  Directory root,
  String relativeDir,
  List<String> problems,
) {
  final dir = Directory('${root.path}/$relativeDir');
  if (!dir.existsSync()) {
    problems.add('Expected to find $relativeDir, but it is missing.');
    return null;
  }
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
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

/// Checks that the marker line is followed by a line that starts with one of
/// [openers].
void _checkMarker(
  List<String> lines,
  int n,
  List<String> openers,
  String fileLabel,
  List<String> problems,
) {
  final marker = _marker(n);
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

/// Checks that the marker line of the unit test file is followed by a group or
/// test whose name starts with the requirement ID, on the same line or on the
/// line after a bare `group(` or `test(`.
void _checkUnitMarker(List<String> lines, int n, List<String> problems) {
  final marker = _marker(n);
  final index = lines.indexWhere((line) => line.trim() == marker);
  if (index < 0) {
    problems.add('$_unitTestPath has no line equal to "$marker".');
    return;
  }
  var nextIndex = index + 1;
  while (nextIndex < lines.length && lines[nextIndex].trim().isEmpty) {
    nextIndex++;
  }
  final next = nextIndex < lines.length ? lines[nextIndex].trim() : '';
  final prefix = "'REQ-DAT-001.$n ";
  final sameLine =
      next.startsWith('group($prefix') || next.startsWith('test($prefix');
  final following = nextIndex + 1 < lines.length
      ? lines[nextIndex + 1].trim()
      : '';
  final splitLine =
      (next == 'group(' || next == 'test(') && following.startsWith(prefix);
  if (!sameLine && !splitLine) {
    problems.add(
      '$_unitTestPath: the test after "$marker" must have a name that starts with "REQ-DAT-001.$n ".',
    );
  }
}

/// The text before the earliest `(`, ` =` or `;` of [line], or all of it.
String _headOf(String line) {
  var end = line.length;
  for (final marker in const ['(', ' =', ';']) {
    final index = line.indexOf(marker);
    if (index >= 0 && index < end) end = index;
  }
  return line.substring(0, end);
}

void _checkCatalog(List<String> lines, List<String> problems) {
  for (final line in lines) {
    final text = line.trimLeft();
    if (text.startsWith('import') ||
        text.startsWith('export') ||
        text.startsWith('part')) {
      problems.add('$_catalogPath must import nothing, but has "$line".');
    }
  }

  for (final name in _displayNames) {
    if (!lines.any((line) => _isCodeLine(line) && line.contains("'$name'"))) {
      problems.add("$_catalogPath has no code line with the literal '$name'.");
    }
  }

  for (final line in lines) {
    if (line.isEmpty || line.startsWith(' ')) continue;
    if (line.startsWith('//') || line == '}' || line == _declaration) continue;
    problems.add('$_catalogPath has a top-level declaration: "$line".');
  }

  final declarationIndex = lines.indexWhere(
    (line) => line.trim() == _declaration,
  );
  if (declarationIndex < 0) {
    problems.add('$_catalogPath has no line equal to "$_declaration".');
    return;
  }

  final docBlock = <String>[];
  for (var i = declarationIndex - 1; i >= 0; i--) {
    if (!lines[i].trim().startsWith('///')) break;
    docBlock.add(lines[i]);
  }
  for (final docLine in _docLines) {
    if (!_hasLine(docBlock, docLine)) {
      problems.add('The doc block of $_declaration lacks "$docLine".');
    }
  }

  final body = <String>[];
  for (var i = declarationIndex + 1; i < lines.length; i++) {
    if (lines[i] == '}') break;
    body.add(lines[i]);
  }
  for (final field in _fieldLines) {
    if (!_hasLine(body, field)) {
      problems.add('The body of $_declaration lacks the line "$field".');
    }
  }
  for (final line in body) {
    if (!RegExp(r'^  [^ ]').hasMatch(line)) continue;
    final text = line.trimLeft();
    if (text.startsWith('//') || text.startsWith('@')) continue;
    final isField = _fieldLines.contains(line.trim());
    final isMember = _memberPrefixes.any(text.startsWith);
    final isPrivate = _privateWord.hasMatch(_headOf(line));
    if (!isField && !isMember && !isPrivate) {
      problems.add(
        '$_declaration has a public member besides the spec: "$line".',
      );
    }
  }
}

/// The 12 tokens of the snapshot block of the spec, or null when the block is
/// missing or malformed (a problem is recorded).
List<String>? _specSnapshotTokens(List<String> lines, List<String> problems) {
  final header = lines.indexOf(_snapshotHeader);
  if (header < 0) {
    problems.add('$_specPath has no line equal to "$_snapshotHeader".');
    return null;
  }
  final open = lines.indexOf(_fenceOpen, header + 1);
  if (open < 0) {
    problems.add('$_specPath has no "$_fenceOpen" line after the header.');
    return null;
  }
  final close = lines.indexOf(_fenceClose, open + 1);
  if (close < 0) {
    problems.add('$_specPath has an unclosed snapshot block.');
    return null;
  }
  final tokens = lines.sublist(open + 1, close);
  if (tokens.length != _snapshotTokenCount) {
    problems.add(
      '$_specPath has ${tokens.length} snapshot tokens, expected $_snapshotTokenCount.',
    );
    return null;
  }
  return tokens;
}

/// The token of every data line of the snapshot data file.
List<String> _dataTokens(List<String> lines) {
  final tokens = <String>[];
  for (final line in lines) {
    final text = line.trim();
    if (text.startsWith("'") &&
        text.endsWith("',") &&
        text.indexOf("'", 1) == text.length - 2) {
      tokens.add(text.substring(1, text.length - 2));
    }
  }
  return tokens;
}

void _checkSnapshotStructure(List<String> lines, List<String> problems) {
  var declarations = 0;
  var closings = 0;
  for (final line in lines) {
    if (line.isEmpty || line.startsWith(' ')) continue;
    if (line.startsWith('//')) continue;
    if (line == '];') {
      closings++;
      continue;
    }
    const opening = 'const List<String> ';
    const ending = ' = [';
    if (line.startsWith(opening) &&
        line.endsWith(ending) &&
        line.length > opening.length + ending.length &&
        !line
            .substring(opening.length, line.length - ending.length)
            .contains('_')) {
      declarations++;
      continue;
    }
    problems.add(
      '$_snapshotPath has a top-level line besides the list: "$line".',
    );
  }
  if (declarations != 1) {
    problems.add(
      '$_snapshotPath must have exactly one public list declaration, has $declarations.',
    );
  }
  if (closings != 1) {
    problems.add(
      '$_snapshotPath must have exactly one "];" line, has $closings.',
    );
  }
}

void main() {
  // REQ-DAT-001.4
  test('the catalog is in the domain layer, pure and documented', () {
    final root = _repoRoot(4);
    final problems = <String>[];

    final catalogLines = _readLines(root, _catalogPath, problems);
    if (catalogLines != null) _checkCatalog(catalogLines, problems);

    final catalogSuffix = '/$_catalogPath';
    for (final dir in [_appLibPath, _coreLibPath]) {
      for (final file in _dartFiles(root, dir, problems) ?? <File>[]) {
        final path = _normalize(file.path);
        if (path.endsWith(catalogSuffix)) continue;
        final text = file.readAsStringSync();
        for (final id in _noradIds) {
          if (text.contains(id)) {
            problems.add('$path must not contain the catalog number $id.');
          }
        }
      }
    }

    if (problems.isNotEmpty) _failWith(4, problems);
  });

  // REQ-DAT-001.5
  test('ADR-0003 records the GOES-East confirmation', () {
    final root = _repoRoot(5);
    final problems = <String>[];

    final adrLines = _readLines(root, _adrPath, problems);
    if (adrLines != null) {
      final noteIndexes = [
        for (var i = 0; i < adrLines.length; i++)
          if (adrLines[i].trim() == _adrNote) i,
      ];
      if (noteIndexes.isEmpty) {
        problems.add('$_adrPath has no line equal to "$_adrNote".');
      } else if (!noteIndexes.any(
        (i) => i > 0 && adrLines[i - 1].trimLeft().startsWith(_adrNoteSibling),
      )) {
        problems.add(
          '$_adrPath: the note must follow the line that starts with "$_adrNoteSibling".',
        );
      }
    }

    if (problems.isNotEmpty) _failWith(5, problems);
  });

  // REQ-DAT-001.6
  test('the snapshot equals the spec and the new files are hygienic', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final specLines = _readLines(root, _specPath, problems);
    final snapshotLines = _readLines(root, _snapshotPath, problems);
    final unitLines = _readLines(root, _unitTestPath, problems);
    final guardLines = _readLines(root, _guardTestPath, problems);

    if (specLines != null) {
      final expected = _specSnapshotTokens(specLines, problems);
      if (expected != null && snapshotLines != null) {
        final actual = _dataTokens(snapshotLines);
        if (actual.length != _snapshotTokenCount) {
          problems.add(
            '$_snapshotPath has ${actual.length} data lines, expected $_snapshotTokenCount.',
          );
        } else {
          for (var i = 0; i < expected.length; i++) {
            if (actual[i] != expected[i]) {
              problems.add(
                '$_snapshotPath token ${i + 1} differs from the spec: expected "${expected[i]}" but found "${actual[i]}".',
              );
            }
          }
        }
      }
    }

    if (snapshotLines != null) {
      _checkSnapshotStructure(snapshotLines, problems);
      for (final citation in _snapshotCitations) {
        if (!_hasLine(snapshotLines, citation)) {
          problems.add('$_snapshotPath lacks the line "$citation".');
        }
      }
      for (final line in snapshotLines) {
        final text = line.trimLeft();
        if (text.startsWith('import') || text.startsWith('export')) {
          problems.add('$_snapshotPath must not import or export: "$line".');
        }
      }
      if (snapshotLines.join('\n').contains('dart:io')) {
        problems.add('$_snapshotPath must not use dart:io.');
      }
    }

    if (unitLines != null) {
      for (final citation in _unitTestCitations) {
        if (!_hasLine(unitLines, citation)) {
          problems.add('$_unitTestPath lacks the line "$citation".');
        }
      }
      for (final required in _unitTestImports) {
        if (!_hasLine(unitLines, required)) {
          problems.add('$_unitTestPath lacks the line "$required".');
        }
      }
      for (final line in unitLines) {
        final text = line.trimLeft();
        if ((text.startsWith('import') || text.startsWith('export')) &&
            !_unitTestImports.contains(line.trim())) {
          problems.add(
            '$_unitTestPath has an import besides the spec: "$line".',
          );
        }
      }
      if (unitLines.join('\n').contains('dart:io')) {
        problems.add('$_unitTestPath must not use dart:io.');
      }
      for (var n = 1; n <= 3; n++) {
        _checkUnitMarker(unitLines, n, problems);
      }
      if (unitLines.join('\n').contains(_skipToken)) {
        problems.add('$_unitTestPath contains a skipped test.');
      }
    }

    if (guardLines != null) {
      if (!_hasLine(guardLines, "import 'support/repo_root.dart';")) {
        problems.add(
          '$_guardTestPath must contain the line '
          "\"import 'support/repo_root.dart';\".",
        );
      }
      final guardText = guardLines.join('\n');
      if (guardText.contains(_platformScriptToken)) {
        problems.add('$_guardTestPath must not use the script location API.');
      }
      for (var n = 4; n <= 6; n++) {
        _checkMarker(guardLines, n, ['test('], _guardTestPath, problems);
      }
      for (var n = 1; n <= 3; n++) {
        if (_hasLine(guardLines, _marker(n))) {
          problems.add(
            '$_guardTestPath must build the tag "${_marker(n)}" by interpolation, not as a line.',
          );
        }
      }
      if (guardText.contains(_skipToken)) {
        problems.add('$_guardTestPath contains a skipped test.');
      }
    }

    _readLines(root, _catalogPath, problems);
    _readLines(root, _adrPath, problems);
    for (final path in [
      _catalogPath,
      _unitTestPath,
      _snapshotPath,
      _guardTestPath,
      _specPath,
      _adrPath,
    ]) {
      final file = File('${root.path}/$path');
      if (file.existsSync()) _checkBytes(file, path, problems);
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });
}
