// Guard for the local element cache of specs/req-dat-003.md (requirements 5 to 7).
//
// It reads files as plain text with the Dart core and dart:io libraries, so it
// introduces no dependency of its own, and every missing file is a failing
// test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-dat-003.md';
const String _adrPath = 'docs/adr/ADR-0001-baseline-packages.md';
const String _cachePath = 'lib/data/element_cache.dart';
const String _unitTestPath = 'test/data/element_cache_test.dart';
const String _guardTestPath = 'test/element_cache_guard_test.dart';
const String _snapshotPath = 'test/domain/celestrak_tle_snapshot.dart';
const String _appLibPath = 'lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const List<String> _catalogNumbers = ['25544', '48274', '38011', '60133'];
const List<String> _members = [
  'schemaVersion',
  'noradId',
  'nameLine',
  'line1',
  'line2',
  'fetchedAtUtc',
];

const List<String> _cacheImports = [
  'dart:async',
  'dart:convert',
  'dart:io',
  'package:orbital_core/orbital_core.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/domain/satellite_catalog.dart',
];
const List<String> _cacheRequiredImports = [
  'dart:convert',
  'dart:io',
  'package:orbital_core/orbital_core.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/domain/satellite_catalog.dart',
];
const List<String> _cacheDocLines = [
  '/// The local element cache of Wintek: the last good CelesTrak GP payload of each tracked object, one JSON file per object (specs/req-dat-003.md).',
  '/// File: gp_NORADID.json in the injected directory, where NORADID is TrackedObject.noradId; each write goes to gp_NORADID.json.tmp first, is flushed and is then renamed.',
  '/// Writes only a valid success of the GP client, with its arrival instant converted to UTC; the cache never reads a clock, so the data age of Constitution principle 9 is the age of the download.',
  '/// Reads validate the document again with OrbitalElements.fromTle and the requested catalog number; anything else is no entry, never an error.',
  '/// Asynchronous file access only, never on the frame path (Constitution principle 13); deleting any cache file or the directory is harmless (Constitution principle 11).',
  '/// The directory is injected and resolved by req-dat-004; this file never looks it up.',
  '/// A cache file longer than 65536 bytes is no entry; a read never loads more than 65537 bytes of it, and a write never stores a longer document.',
];
const List<String> _allowedCatchPrefixes = [
  '} on FileSystemException catch (',
  '} on FileSystemException {',
  '} on FormatException catch (',
  '} on FormatException {',
];

const List<String> _unitTestImports = [
  'dart:convert',
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/domain/satellite_catalog.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _unitTestRequiredImports = [
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/data/element_cache.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _guardImports = [
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'support/repo_root.dart',
];
const String _unitTestCitation =
    '// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; every test writes only inside a temporary directory it creates and deletes (Constitution principle 11).';
const String _repoRootImport = "import 'support/repo_root.dart';";

const String _noteLine =
    '- **Note (2026-11-14, req-dat-003):** The element cache keeps one JSON file per tracked object, and every write replaces its file whole, so no setting can ride in a cache file. Settings, when a spec needs them, get their own JSON file in the same directory. The approved packages are unchanged.';
const String _noteAnchor =
    'Settings ride in the same cached JSON until a spec proves that insufficient.';
const String _statusMention =
    'Qualified by req-dat-003 (2026-11-14): settings do not ride in a cache file; see the note under Out of scope.';

final RegExp _publicClass = RegExp(
  r'^(?:class |final class |base class |sealed class )(\S+)',
);
final RegExp _blankRun = RegExp(r'[ \t\r]+');

String _tag(int n) => '[REQ-DAT-003.$n]';

String _marker(int n) => '// REQ-DAT-003.$n';

Never _failWith(int n, List<String> problems) {
  fail('${_tag(n)} ${problems.join(' ${_tag(n)} ')} See $_specPath.');
}

Directory _repoRoot(int n) => findRepoRoot(
  failurePrefix: '${_tag(n)} ',
  failureSuffix: 'See $_specPath.',
);

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

void _checkBytes(Directory root, String path, List<String> problems) {
  final file = File('${root.path}/$path');
  if (!file.existsSync()) {
    problems.add('Expected to find $path, but it is missing.');
    return;
  }
  final bytes = file.readAsBytesSync();
  if (bytes.contains(0x0D)) {
    problems.add('$path contains a CR byte (0D); use LF line endings.');
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    problems.add('$path starts with a UTF-8 BOM.');
  }
}

/// The text between the first two single quotes of an `import ` or `export `
/// line, or null for any other line.
String? _importUri(String line) {
  final text = line.trimLeft();
  if (!text.startsWith('import ') && !text.startsWith('export ')) return null;
  final parts = text.split("'");
  return parts.length > 2 ? parts[1] : '';
}

/// Checks that every import line of [lines] names an allowed URI and that
/// every required URI is present.
void _checkImports(
  List<String> lines,
  String label,
  List<String> allowed,
  List<String> required,
  List<String> problems,
) {
  final seen = <String>{};
  for (final line in lines) {
    if (!line.trimLeft().startsWith('import ')) continue;
    final uri = _importUri(line)!;
    seen.add(uri);
    if (!allowed.contains(uri)) {
      problems.add('$label imports "$uri", which is not allowed.');
    }
  }
  for (final uri in required) {
    if (!seen.contains(uri)) {
      problems.add('$label does not import "$uri".');
    }
  }
}

/// The text before the earliest `(`, ` =`, `;` or `{` of [line], or all of it.
String _headOf(String line) {
  var end = line.length;
  for (final marker in const ['(', ' =', ';', '{']) {
    final index = line.indexOf(marker);
    if (index >= 0 && index < end) end = index;
  }
  return line.substring(0, end);
}

bool _isDeclarationLine(String line) {
  if (line.isEmpty) return false;
  final first = line[0];
  if (first == ' ' || first == '\t' || first == '\r') return false;
  return !(line.startsWith('//') ||
      line.startsWith('@') ||
      line.startsWith('import ') ||
      line.startsWith('}') ||
      line.startsWith(')') ||
      line.startsWith(']'));
}

/// The declared name of a declaration line: the word after the first
/// `class`, `enum`, `mixin`, `extension` or `typedef` of its head, otherwise
/// the last word of its head; null when the head has no such word.
String? _declaredName(String line) {
  final words = _headOf(line)
      .split(_blankRun)
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return null;
  const keywords = ['class', 'enum', 'mixin', 'extension', 'typedef'];
  final keyword = words.indexWhere(keywords.contains);
  if (keyword < 0) return words.last;
  return keyword + 1 < words.length ? words[keyword + 1] : null;
}

int _count(String text, String token) {
  var count = 0;
  var index = text.indexOf(token);
  while (index >= 0) {
    count++;
    index = text.indexOf(token, index + token.length);
  }
  return count;
}

bool _isCatchLine(String line) {
  if (!_isCodeLine(line)) return false;
  final text = line.trimLeft();
  if (text.contains('catch (') || text.startsWith('on ')) return true;
  if (!text.contains(' on ')) return false;
  final isHeader =
      (text.startsWith('extension ') || text.startsWith('mixin ')) &&
      _count(text, ' on ') == 1 &&
      !text.contains('catch (');
  return !isHeader;
}

void _checkCatchLines(List<String> lines, List<String> problems) {
  for (final line in lines.where(_isCatchLine)) {
    final text = line.trimLeft();
    final allowed = _allowedCatchPrefixes.any(text.startsWith);
    if (!allowed || _count(text, ' on ') != 1) {
      problems.add(
        '$_cachePath has a catch line that is not allowed: "${line.trim()}".',
      );
    }
  }
}

void _checkCacheSurface(List<String> lines, List<String> problems) {
  var publicClasses = 0;
  for (final line in lines) {
    if (!_isDeclarationLine(line)) continue;
    final match = _publicClass.firstMatch(line);
    if (match != null && !match.group(1)!.startsWith('_')) {
      publicClasses++;
      continue;
    }
    if (_declaredName(line)?.startsWith('_') ?? false) continue;
    problems.add(
      '$_cachePath has a declaration that is neither a public class nor private: "$line".',
    );
  }
  if (publicClasses != 2) {
    problems.add(
      '$_cachePath must declare exactly 2 public classes, but declares $publicClasses.',
    );
  }
}

void _checkCacheText(List<String> lines, List<String> problems) {
  final text = lines.join('\n');
  void forbid(String token, String reason) {
    if (text.contains(token)) {
      problems.add('$_cachePath must not contain "$token" ($reason).');
    }
  }

  if (text.contains('Sync(')) {
    problems.add('$_cachePath must not contain "Sync(" (asynchronous only).');
  }
  for (final token in const [
    'readAsString',
    'readAsBytes',
    'readAsLines',
    'openRead',
  ]) {
    forbid(token, 'no whole-file read');
  }
  for (final token in const [
    'readInto(',
    'readByte(',
    'while (',
    'for (',
    'do {',
  ]) {
    forbid(token, 'bounded read');
  }
  if (!_hasLine(lines, 'const int _sizeLimitBytes = 65536;')) {
    problems.add(
      '$_cachePath lacks the line "const int _sizeLimitBytes = 65536;".',
    );
  }
  final reads = _count(text, '.read(');
  if (reads != 1) {
    problems.add('$_cachePath must contain ".read(" exactly once, has $reads.');
  } else if (!text.contains('.read(_sizeLimitBytes + 1)')) {
    problems.add(
      '$_cachePath must follow ".read(" directly with "_sizeLimitBytes + 1)".',
    );
  }
  if (!_hasLine(lines, '} finally {') || !text.contains('.close()')) {
    problems.add('$_cachePath must close its file in a "} finally {" block.');
  }
  if (!text.contains('flush: true') && !text.contains('.flush(')) {
    problems.add('$_cachePath must flush before the rename.');
  }
  for (final token in const ['path_provider', 'getApplication']) {
    forbid(token, 'the directory is injected');
  }
  for (final token in const [
    'DateTime.now',
    'DateTime.timestamp',
    'Stopwatch',
  ]) {
    forbid(token, 'the cache never reads a clock');
  }
  for (final token in const ['.delete(', '.list(']) {
    forbid(token, 'nothing is deleted or listed');
  }
  for (final token in const ['on Object', 'on Error', 'on dynamic']) {
    forbid(token, 'no Dart Error is caught');
  }
  for (final token in const [
    'catchError',
    'onError',
    'handleError',
    'handleUncaughtError',
    'runZoned',
    'Zone.',
    'ZoneSpecification',
  ]) {
    forbid(token, 'no Dart Error is caught');
  }
  for (final member in _members) {
    if (!lines.any((line) => _isCodeLine(line) && line.contains("'$member'"))) {
      problems.add(
        "$_cachePath has no code line with the member name '$member'.",
      );
    }
  }
  for (final number in _catalogNumbers) {
    forbid(number, 'read TrackedObject.noradId');
  }
}

void _checkCache(List<String> lines, List<String> problems) {
  for (final line in lines) {
    final text = line.trimLeft();
    if (text.startsWith('export ') || text.startsWith('part ')) {
      problems.add('$_cachePath has an export or part line: "$line".');
    }
  }
  _checkImports(
    lines,
    _cachePath,
    _cacheImports,
    _cacheRequiredImports,
    problems,
  );
  _checkCacheSurface(lines, problems);
  _checkCacheText(lines, problems);
  _checkCatchLines(lines, problems);
  for (final docLine in _cacheDocLines) {
    if (!_hasLine(lines, docLine)) {
      problems.add('$_cachePath lacks the line "$docLine".');
    }
  }
}

/// Checks that the marker of [n] in the guard test file is followed by a line
/// that starts with `test(`.
void _checkGuardMarker(List<String> lines, int n, List<String> problems) {
  final marker = _marker(n);
  final index = lines.indexWhere((line) => line.trim() == marker);
  if (index < 0) {
    problems.add('$_guardTestPath has no line equal to "$marker".');
    return;
  }
  final next = lines
      .skip(index + 1)
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  if (!next.startsWith('test(')) {
    problems.add(
      '$_guardTestPath: the line after "$marker" must start with test(.',
    );
  }
}

/// True when the line at [index] opens a group or test of requirement [n]: on
/// the same line, or on the line after a bare `group(` or `test(`.
bool _opensRequirement(List<String> lines, int index, int n) {
  final text = lines[index].trim();
  final prefix = "'REQ-DAT-003.$n ";
  if (text.startsWith('group($prefix') || text.startsWith('test($prefix')) {
    return true;
  }
  if (text != 'group(' && text != 'test(') return false;
  return index + 1 < lines.length && lines[index + 1].trim().startsWith(prefix);
}

void _checkUnitMarker(List<String> lines, int n, List<String> problems) {
  final marker = _marker(n);
  final index = lines.indexWhere((line) => line.trim() == marker);
  if (index < 0) {
    problems.add('$_unitTestPath has no line equal to "$marker".');
    return;
  }
  var next = index + 1;
  while (next < lines.length && lines[next].trim().isEmpty) {
    next++;
  }
  if (next >= lines.length || !_opensRequirement(lines, next, n)) {
    problems.add(
      '$_unitTestPath: the test after "$marker" must have a name that starts with "REQ-DAT-003.$n ".',
    );
  }
}

void _checkUnitTest(List<String> lines, List<String> problems) {
  _checkImports(
    lines,
    _unitTestPath,
    _unitTestImports,
    _unitTestRequiredImports,
    problems,
  );
  final text = lines.join('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('export ')) {
      problems.add('$_unitTestPath has an export line: "$line".');
    }
  }
  if (!text.contains('createTemp(')) {
    problems.add(
      '$_unitTestPath must create its directories with createTemp(.',
    );
  }
  if (!text.contains('tearDown(') && !text.contains('addTearDown(')) {
    problems.add('$_unitTestPath must delete its directories in a teardown.');
  }
  var index = text.indexOf('systemTemp');
  while (index >= 0) {
    if (!text.startsWith('.createTemp(', index + 'systemTemp'.length)) {
      problems.add(
        '$_unitTestPath uses systemTemp without calling .createTemp( directly.',
      );
    }
    index = text.indexOf('systemTemp', index + 1);
  }
  for (final token in const [
    'Directory.current',
    'Platform.',
    '.parent',
    "'/",
    '"/',
  ]) {
    if (text.contains(token)) {
      problems.add('$_unitTestPath must not contain "$token".');
    }
  }
  if (!_hasLine(lines, _unitTestCitation)) {
    problems.add('$_unitTestPath lacks the line "$_unitTestCitation".');
  }
  for (var n = 1; n <= 4; n++) {
    _checkUnitMarker(lines, n, problems);
  }
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (!trimmed.startsWith('group(') && !trimmed.startsWith('test(')) continue;
    final tagged = [1, 2, 3, 4].any((n) => _opensRequirement(lines, i, n));
    if (!tagged) {
      problems.add('$_unitTestPath has an untagged group or test: "$trimmed".');
    }
  }
}

void _checkGuardTest(List<String> lines, List<String> problems) {
  for (var n = 5; n <= 7; n++) {
    _checkGuardMarker(lines, n, problems);
  }
  for (var n = 1; n <= 4; n++) {
    if (_hasLine(lines, _marker(n))) {
      problems.add(
        '$_guardTestPath must not contain the line "${_marker(n)}"; build it by interpolation.',
      );
    }
  }
  _checkImports(lines, _guardTestPath, _guardImports, const [], problems);
  if (!_hasLine(lines, _repoRootImport)) {
    problems.add('$_guardTestPath lacks the line "$_repoRootImport".');
  }
  final text = lines.join('\n');
  if (text.contains(_platformScriptToken)) {
    problems.add('$_guardTestPath must not contain "$_platformScriptToken".');
  }
}

void _checkAdr(List<String> lines, List<String> problems) {
  final noteIndex = lines.indexWhere((line) => line.trim() == _noteLine);
  if (noteIndex < 0) {
    problems.add('$_adrPath lacks the note line of req-dat-003.');
  }
  final anchorIndex = lines.indexWhere((line) => line.contains(_noteAnchor));
  if (anchorIndex < 0) {
    problems.add('$_adrPath lacks the sentence "$_noteAnchor".');
  } else if (noteIndex >= 0 && noteIndex < anchorIndex) {
    problems.add(
      '$_adrPath must put the note after the sentence it qualifies.',
    );
  }
  final mentioned = lines.any(
    (line) => line.startsWith('- **Status:**') && line.contains(_statusMention),
  );
  if (!mentioned) {
    problems.add('$_adrPath: the Status line must contain "$_statusMention".');
  }
}

void main() {
  // REQ-DAT-003.5
  test('REQ-DAT-003.5 the cache is a small, documented data-layer file', () {
    final root = _repoRoot(5);
    final problems = <String>[];

    final cache = _readLines(root, _cachePath, problems);
    if (cache != null) _checkCache(cache, problems);

    if (problems.isNotEmpty) _failWith(5, problems);
  });

  // REQ-DAT-003.6
  test('REQ-DAT-003.6 the new files follow the hygiene rules', () {
    final root = _repoRoot(6);
    final problems = <String>[];

    final unitTest = _readLines(root, _unitTestPath, problems);
    if (unitTest != null) _checkUnitTest(unitTest, problems);
    final guardTest = _readLines(root, _guardTestPath, problems);
    if (guardTest != null) _checkGuardTest(guardTest, problems);
    _readLines(root, _snapshotPath, problems);
    if (!Directory('${root.path}/$_appLibPath').existsSync()) {
      problems.add('Expected to find $_appLibPath, but it is missing.');
    }
    for (final path in const [
      _cachePath,
      _unitTestPath,
      _guardTestPath,
      _specPath,
      _adrPath,
    ]) {
      _checkBytes(root, path, problems);
    }
    for (final text in [guardTest, unitTest]) {
      if (text != null && text.join('\n').contains(_skipToken)) {
        problems.add('A new test file must not contain "$_skipToken".');
      }
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });

  // REQ-DAT-003.7
  test(
    'REQ-DAT-003.7 ADR-0001 records that settings do not ride in a cache',
    () {
      final root = _repoRoot(7);
      final problems = <String>[];

      final adr = _readLines(root, _adrPath, problems);
      if (adr != null) _checkAdr(adr, problems);

      if (problems.isNotEmpty) _failWith(7, problems);
    },
  );
}
