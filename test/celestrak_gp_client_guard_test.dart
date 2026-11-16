// Guard for the CelesTrak GP client of specs/req-dat-002.md (requirements 4 to 6).
//
// It reads files as plain text with the Dart core and dart:io libraries, so it
// introduces no dependency of its own, and every missing file is a failing
// test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-dat-002.md';
const String _clientPath = 'lib/data/celestrak_gp_client.dart';
const String _factoryPath = 'lib/data/element_repository_factory.dart';
const String _unitTestPath = 'test/data/celestrak_gp_client_test.dart';
const String _guardTestPath = 'test/celestrak_gp_client_guard_test.dart';
const String _snapshotPath = 'test/domain/celestrak_tle_snapshot.dart';
const String _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const String _appLibPath = 'lib';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';

const String _userAgent = 'Wintek/1.0 (+https://github.com/NEVO-JzzPI/Wintek)';
const List<String> _catalogNumbers = ['25544', '48274', '38011', '60133'];

const List<String> _clientImports = [
  'dart:async',
  'package:http/http.dart',
  'package:orbital_core/orbital_core.dart',
  'package:wintek/domain/satellite_catalog.dart',
];
const List<String> _clientRequiredImports = [
  'package:http/http.dart',
  'package:orbital_core/orbital_core.dart',
  'package:wintek/domain/satellite_catalog.dart',
];
const List<String> _clientDocLines = [
  '/// The only network boundary of Wintek: one CelesTrak GP request per tracked object (specs/req-dat-002.md).',
  '/// Request: GET https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, where <NORAD ID> is TrackedObject.noradId.',
  '/// One attempt per call, 20-second timeout, no retry and no timer; when to call is decided by req-dat-004 (Constitution principle 10).',
  '/// Success: the name line and both element lines, accepted by OrbitalElements.fromTle with the requested catalog number, and the UTC instant they arrived.',
  '/// Failures are returned, never thrown: network, timeout, HTTP status, no GP data and malformed payload.',
  '/// The HTTP client is injected and never closed here; whoever creates it owns it.',
];

const String _permissionLine =
    '<uses-permission android:name="android.permission.INTERNET"/>';

const List<String> _unitTestImports = [
  'dart:async',
  'package:flutter_test/flutter_test.dart',
  'package:http/http.dart',
  'package:http/testing.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/domain/satellite_catalog.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _unitTestRequiredImports = [
  'package:flutter_test/flutter_test.dart',
  'package:http/testing.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _guardImports = [
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'support/repo_root.dart',
];
const String _unitTestCitation =
    '// Responses rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test sends a request to CelesTrak (Constitution principle 10).';
const String _repoRootImport = "import 'support/repo_root.dart';";

final RegExp _privateWord = RegExp(r'(^|[^A-Za-z0-9_])_[A-Za-z0-9_]*');
final RegExp _publicClass = RegExp(
  r'^(?:class |final class |base class |sealed class )(\S+)',
);
final RegExp _httpImportLine = RegExp(
  r"^import 'package:http/http\.dart' show "
  r'(?:ClientException|Request|Response)'
  r'(?:, (?:ClientException|Request|Response))*;$',
);

String _tag(int n) => '[REQ-DAT-002.$n]';

String _marker(int n) => '// REQ-DAT-002.$n';

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
      line.startsWith(')'));
}

/// Checks that the marker of [n] is followed by a line that starts with one of
/// [openers].
void _checkGuardMarker(
  List<String> lines,
  int n,
  List<String> openers,
  List<String> problems,
) {
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
  if (!openers.any(next.startsWith)) {
    problems.add(
      '$_guardTestPath: the line after "$marker" must start with ${openers.join(' or ')}.',
    );
  }
}

/// Checks that the marker of the unit test file is followed by a group or test
/// whose name starts with the requirement ID, on the same line or on the line
/// after a bare `group(` or `test(`.
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
  final prefix = "'REQ-DAT-002.$n ";
  final sameLine =
      next.startsWith('group($prefix') || next.startsWith('test($prefix');
  final following = nextIndex + 1 < lines.length
      ? lines[nextIndex + 1].trim()
      : '';
  final splitLine =
      (next == 'group(' || next == 'test(') && following.startsWith(prefix);
  if (!sameLine && !splitLine) {
    problems.add(
      '$_unitTestPath: the test after "$marker" must have a name that starts with "REQ-DAT-002.$n ".',
    );
  }
}

void _checkClientSurface(List<String> lines, List<String> problems) {
  var publicClasses = 0;
  var sealedClasses = 0;
  for (final line in lines) {
    if (!_isDeclarationLine(line)) continue;
    final match = _publicClass.firstMatch(line);
    if (match != null && !match.group(1)!.startsWith('_')) {
      publicClasses++;
      if (line.startsWith('sealed class ')) sealedClasses++;
      continue;
    }
    if (_privateWord.hasMatch(_headOf(line))) continue;
    problems.add(
      '$_clientPath has a declaration that is neither a public class nor private: "$line".',
    );
  }
  if (publicClasses != 8) {
    problems.add(
      '$_clientPath must declare exactly 8 public classes, but declares $publicClasses.',
    );
  }
  if (sealedClasses != 1) {
    problems.add(
      '$_clientPath must declare exactly 1 sealed class, but declares $sealedClasses.',
    );
  }
}

void _checkClient(List<String> lines, List<String> problems) {
  for (final line in lines) {
    final text = line.trimLeft();
    if (text.startsWith('export') || text.startsWith('part')) {
      problems.add('$_clientPath has an export or part line: "$line".');
    }
  }
  _checkImports(
    lines,
    _clientPath,
    _clientImports,
    _clientRequiredImports,
    problems,
  );
  _checkClientSurface(lines, problems);

  final text = lines.join('\n');
  for (final forbidden in const ['Timer', 'periodic']) {
    if (text.contains(forbidden)) {
      problems.add('$_clientPath must not contain "$forbidden".');
    }
  }
  if (text.contains('.close(')) {
    problems.add('$_clientPath must not close an HTTP client (".close(").');
  }
  var index = text.indexOf('Client(');
  while (index >= 0) {
    final preceded = index > 0 && RegExp('[A-Za-z]').hasMatch(text[index - 1]);
    if (!preceded) {
      problems.add('$_clientPath constructs a Client at offset $index.');
    }
    index = text.indexOf('Client(', index + 1);
  }
  if (!lines.any(
    (line) => _isCodeLine(line) && line.contains("'$_userAgent'"),
  )) {
    problems.add(
      "$_clientPath has no code line with the literal '$_userAgent'.",
    );
  }
  for (final number in _catalogNumbers) {
    if (text.contains(number)) {
      problems.add(
        '$_clientPath contains the catalog number $number; read TrackedObject.noradId.',
      );
    }
  }
  for (final docLine in _clientDocLines) {
    if (!_hasLine(lines, docLine)) {
      problems.add('$_clientPath lacks the line "$docLine".');
    }
  }
}

void _checkNetworkBoundary(Directory root, List<String> problems) {
  final files = _dartFiles(root, _appLibPath, problems);
  if (files == null) return;
  for (final file in files) {
    final path = _normalize(file.path);
    if (path.endsWith('/$_clientPath')) continue;
    final text = file.readAsStringSync();
    if (path.endsWith('/$_factoryPath')) {
      for (final line in text.split('\n')) {
        if (line.contains('package:http/') &&
            (!line.trimLeft().startsWith('import ') ||
                _importUri(line) != 'package:http/http.dart')) {
          problems.add(
            '$path has the line "${line.trim()}", but only an import of package:http/http.dart may name package:http/ there.',
          );
        }
      }
    } else if (text.contains('package:http/')) {
      problems.add(
        '$path contains "package:http/", which only $_clientPath and $_factoryPath may.',
      );
    }
    for (final token in const ['HttpClient', 'Socket', 'InternetAddress']) {
      if (text.contains(token)) {
        problems.add('$path contains "$token", which only $_clientPath may.');
      }
    }
    if (text.toLowerCase().contains('celestrak.org')) {
      problems.add(
        '$path names the CelesTrak host, which only $_clientPath may.',
      );
    }
  }
}

void _checkManifest(List<String> lines, List<String> problems) {
  final trimmed = [for (final line in lines) line.trim()];
  final manifestIndex = trimmed.indexWhere(
    (line) => line.startsWith('<manifest'),
  );
  final applicationIndex = trimmed.indexWhere(
    (line) => line.startsWith('<application'),
  );
  final permissionIndex = trimmed.indexOf(_permissionLine);
  if (permissionIndex < 0) {
    problems.add('$_manifestPath has no line equal to "$_permissionLine".');
    return;
  }
  if (manifestIndex < 0 ||
      applicationIndex < 0 ||
      permissionIndex < manifestIndex ||
      permissionIndex > applicationIndex) {
    problems.add(
      '$_manifestPath: the permission must come after <manifest and before <application.',
    );
    return;
  }
  for (var i = manifestIndex; i < permissionIndex; i++) {
    if (trimmed[i].contains('<!--')) {
      problems.add(
        '$_manifestPath: the permission must not sit inside a comment.',
      );
      break;
    }
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
  for (final line in lines) {
    if (line.trimLeft().startsWith('export')) {
      problems.add('$_unitTestPath has an export line: "$line".');
    }
    if (_importUri(line) == 'package:http/http.dart' &&
        !_httpImportLine.hasMatch(line.trim())) {
      problems.add(
        '$_unitTestPath may import only ClientException, Request and Response from package:http/http.dart, but has "${line.trim()}".',
      );
    }
  }
  final text = lines.join('\n');
  if (text.contains('dart:io')) {
    problems.add('$_unitTestPath must not contain "dart:io".');
  }
  if (!_hasLine(lines, _unitTestCitation)) {
    problems.add('$_unitTestPath lacks the line "$_unitTestCitation".');
  }
  for (var n = 1; n <= 3; n++) {
    _checkUnitMarker(lines, n, problems);
  }
}

void _checkGuardTest(List<String> lines, List<String> problems) {
  for (var n = 4; n <= 6; n++) {
    _checkGuardMarker(lines, n, const ['test('], problems);
  }
  for (var n = 1; n <= 3; n++) {
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

void main() {
  // REQ-DAT-002.4
  test('REQ-DAT-002.4 the client is the only network boundary', () {
    final root = _repoRoot(4);
    final problems = <String>[];

    final client = _readLines(root, _clientPath, problems);
    if (client != null) _checkClient(client, problems);
    _checkNetworkBoundary(root, problems);

    if (problems.isNotEmpty) _failWith(4, problems);
  });

  // REQ-DAT-002.5
  test('REQ-DAT-002.5 the manifest declares the internet permission', () {
    final root = _repoRoot(5);
    final problems = <String>[];

    final manifest = _readLines(root, _manifestPath, problems);
    if (manifest != null) _checkManifest(manifest, problems);

    if (problems.isNotEmpty) _failWith(5, problems);
  });

  // REQ-DAT-002.6
  test('REQ-DAT-002.6 the new files follow the hygiene rules', () {
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
      _clientPath,
      _unitTestPath,
      _guardTestPath,
      _specPath,
      _manifestPath,
    ]) {
      _checkBytes(root, path, problems);
    }
    final guardText = guardTest?.join('\n') ?? '';
    if (guardText.contains(_skipToken)) {
      problems.add('$_guardTestPath must not contain "$_skipToken".');
    }
    final unitText = unitTest?.join('\n') ?? '';
    if (unitText.contains(_skipToken)) {
      problems.add('$_unitTestPath must not contain "$_skipToken".');
    }

    if (problems.isNotEmpty) _failWith(6, problems);
  });
}
