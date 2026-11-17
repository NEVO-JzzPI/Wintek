// Guard for the element repository of specs/req-dat-004.md (requirements 7 to 10).
//
// It reads files as plain text with the Dart core and dart:io libraries, so it
// introduces no dependency of its own, and every missing file is a failing
// test, never a skipped one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _specPath = 'specs/req-dat-004.md';
const String _amendedSpecPath = 'specs/req-dat-002.md';
const String _adr7Path = 'docs/adr/ADR-0007-principle-10-across-runs.md';
const String _adr8Path = 'docs/adr/ADR-0008-principle-5-and-sdk-libraries.md';
const String _domainPath = 'lib/domain/element_repository.dart';
const String _repositoryPath = 'lib/data/celestrak_element_repository.dart';
const String _factoryPath = 'lib/data/element_repository_factory.dart';
const String _repositoryTestPath =
    'test/data/celestrak_element_repository_test.dart';
const String _factoryTestPath =
    'test/data/element_repository_factory_test.dart';
const String _guardPath = 'test/element_repository_guard_test.dart';
const String _snapshotPath = 'test/domain/celestrak_tle_snapshot.dart';
const String _mainPath = 'lib/main.dart';
const String _libPath = 'lib';
const String _domainDir = 'lib/domain';
const String _presentationDir = 'lib/presentation';
const String _dataPrefix = 'lib/data/';

// Split so that this file does not contain the forbidden substrings itself.
const String _skipToken =
    'ski'
    'p:';
const String _platformScriptToken =
    'Platform'
    '.script';
const String _tagPrefix = 'REQ-DAT-004.';

const List<String> _catalogNumbers = ['25544', '48274', '38011', '60133'];
const List<String> _forbiddenSdk = [
  'dart:cli',
  'dart:developer',
  'dart:ffi',
  'dart:html',
  'dart:indexed_db',
  'dart:io',
  'dart:isolate',
  'dart:js',
  'dart:js_interop',
  'dart:js_interop_unsafe',
  'dart:js_util',
  'dart:mirrors',
  'dart:svg',
  'dart:ui',
  'dart:ui_web',
  'dart:web_audio',
  'dart:web_gl',
];

const List<String> _domainImports = [
  'package:orbital_core/orbital_core.dart',
  'package:wintek/domain/satellite_catalog.dart',
];
const List<String> _domainDocLines = [
  '/// The element repository contract of Wintek: the only way the rest of the app reads orbital elements (specs/req-dat-004.md).',
  '/// Depends only on orbital_core and the domain layer (Constitution principle 5); lib/data implements it.',
  '/// The data age is the age of the download, measured from the arrival instant; it is never negative, and it is null (unknown) before the arrival instant.',
];

const List<String> _repositoryImports = [
  'dart:async',
  'package:orbital_core/orbital_core.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/domain/element_repository.dart',
  'package:wintek/domain/satellite_catalog.dart',
];
const List<String> _repositoryRequiredImports = [
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/domain/element_repository.dart',
];
const List<String> _repositoryDocLines = [
  '/// The element repository of Wintek: serves the last good element set of each tracked object and refreshes it from CelesTrak only when it is due (specs/req-dat-004.md).',
  '/// Due: no element set, an arrival instant 6 hours old or older, or one in the future; never within 6 hours of the last attempt for that object.',
  '/// Attempts are kept in memory only, never on disk (Constitution principles 10 and 11, ADR-0007); nothing here schedules, retries or polls.',
  '/// A refresh sends one request at a time, in catalog order, and a refresh asked for while one runs joins it, so no object is ever written twice at once.',
  '/// A lookup never reaches the network: it serves memory first, then the cache, so a cold start needs no network (Constitution principle 9).',
  '/// Every success is written to the cache and served from memory even if the write fails; a failure keeps the element set already served.',
  '/// A lookup keeps what it read from the cache only if memory still holds nothing for that object, so it never replaces a newer element set.',
];

const List<String> _factoryImports = [
  'dart:async',
  'dart:io',
  'package:http/http.dart',
  'package:path_provider/path_provider.dart',
  'package:wintek/data/celestrak_element_repository.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/domain/element_repository.dart',
];
const List<String> _factoryDocLines = [
  '/// Opens the element repository of the app on the application support directory of path_provider, which the operating system does not clear on its own (specs/req-dat-004.md).',
  '/// Creates the one production HTTP client of the app and closes it once on close; whoever creates it owns it (specs/req-dat-002.md, amended by req-dat-004).',
  '/// Opening resolves the directory first and sends no request; the resolver, the HTTP client creator and the clock are injectable for tests.',
];
const List<String> _forbiddenDirectoryFunctions = [
  'getApplicationCacheDirectory',
  'getTemporaryDirectory',
  'getApplicationDocumentsDirectory',
  'getExternal',
  'getDownloadsDirectory',
  'getLibraryDirectory',
];
const List<String> _noCatchTokens = [
  'try {',
  'catch',
  'onError',
  'handleError',
  'runZoned',
  'Zone.',
];

const String _amendedAnchor =
    '- **Amended by req-dat-004 (2026-11-15):** REQ-DAT-002.4 lets exactly one more application library file, `lib/data/element_repository_factory.dart`, import `package:http/http.dart` to create and close the production HTTP client. The client library file stays the only file that uses `HttpClient`, a socket or an address lookup, or names the CelesTrak host.';
const String _boundaryHeading =
    '- **The only network boundary** (amended by req-dat-004 on 2026-11-15).';
const String _boundaryPackageLine =
    '- No application library file other than the client library file and the factory library file of req-dat-004, `lib/data/element_repository_factory.dart`, contains the substring `package:http/`.';
const String _boundaryFactoryLine =
    '- In the factory library file of req-dat-004, every line that contains `package:http/` is a line that, with leading blank characters removed, starts with `import ` and whose import URI is `package:http/http.dart`.';
const String _boundarySocketLine =
    '- No application library file other than the client library file contains any of the substrings `HttpClient`, `Socket` or `InternetAddress`.';
const String _boundaryOldLine =
    '- No application library file other than the client library file contains any of the substrings `package:http/`, `HttpClient`, `Socket` or `InternetAddress`.';
const String _blocksLine =
    '- req-dat-004: decides when to call the client, creates and owns its HTTP client, and records each failure as the outcome failed while it keeps serving the element set it had; the data age and the stale-data warning follow from the arrival instant, not from the failure (amended by req-dat-004 on 2026-11-16). Creating the HTTP client outside the client library file needs an amendment of REQ-DAT-002.4 in that spec.';
const String _blocksOldText = 'maps its failures to the data age';
const String _adr7Title =
    '# ADR-0007 — Reading of Constitution principle 10 across runs of the app';
const String _adr8Title =
    '# ADR-0008 — Reading of Constitution principle 5 for Dart SDK libraries';
const String _acceptedStatus = '- **Status:** Accepted';

const List<String> _repositoryTestImports = [
  'dart:async',
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'package:http/http.dart',
  'package:http/testing.dart',
  'package:orbital_core/orbital_core.dart',
  'package:wintek/data/celestrak_element_repository.dart',
  'package:wintek/data/celestrak_gp_client.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/domain/element_repository.dart',
  'package:wintek/domain/satellite_catalog.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _repositoryTestRequiredImports = [
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'package:http/testing.dart',
  'package:wintek/data/celestrak_element_repository.dart',
  'package:wintek/data/element_cache.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _factoryTestImports = [
  'dart:async',
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'package:http/http.dart',
  'package:http/testing.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/data/element_repository_factory.dart',
  'package:wintek/domain/element_repository.dart',
  'package:wintek/domain/satellite_catalog.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _factoryTestRequiredImports = [
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'package:http/http.dart',
  'package:http/testing.dart',
  'package:wintek/data/element_cache.dart',
  'package:wintek/data/element_repository_factory.dart',
  '../domain/celestrak_tle_snapshot.dart',
];
const List<String> _guardImports = [
  'dart:io',
  'package:flutter_test/flutter_test.dart',
  'support/repo_root.dart',
];
const String _unitTestCitation =
    '// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test reaches CelesTrak or a platform directory, and every test writes only inside a temporary directory it creates and deletes (Constitution principles 10 and 11).';
const String _repoRootImport = "import 'support/repo_root.dart';";
const List<String> _forbiddenInUnitTests = [
  'Client.new',
  'IOClient',
  'HttpClient',
  'path_provider/',
  'getApplication',
  'Directory.current',
  'Platform.',
  '.parent',
  "'/",
  '"/',
];

final RegExp _blankRun = RegExp(r'[ \t\r]+');
final RegExp _markerPattern = RegExp('^// REQ-DAT-004\\.(\\d+)\$');

String _tag(int n) => '[REQ-DAT-004.$n]';

String _marker(int n) => '// REQ-DAT-004.$n';

Never _failWith(int n, List<String> problems) {
  fail('${_tag(n)} ${problems.join(' ${_tag(n)} ')} See $_specPath.');
}

Directory _repoRoot(int n) => findRepoRoot(
  failurePrefix: '${_tag(n)} ',
  failureSuffix: 'See $_specPath.',
);

String _normalize(String path) => path.replaceAll('\\', '/');

String _oneLine(String text) => text.replaceAll('\n', ' ');

bool _hasLine(List<String> lines, String text) =>
    lines.any((line) => line.trim() == text);

bool _isCodeLine(String line) => !line.trimLeft().startsWith('//');

bool _isAsciiLetter(int unit) =>
    (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A);

/// Reads [relativePath] as text, or records a problem and returns null.
String? _readText(Directory root, String relativePath, List<String> problems) {
  final file = File('${root.path}/$relativePath');
  if (!file.existsSync()) {
    problems.add('Expected to find $relativePath, but it is missing.');
    return null;
  }
  return file.readAsStringSync();
}

List<String>? _readLines(
  Directory root,
  String relativePath,
  List<String> problems,
) => _readText(root, relativePath, problems)?.split('\n');

void _requireDirectory(
  Directory root,
  String relativePath,
  List<String> problems,
) {
  if (!Directory('${root.path}/$relativePath').existsSync()) {
    problems.add('Expected to find $relativePath, but it is missing.');
  }
}

void _requireFile(Directory root, String relativePath, List<String> problems) {
  if (!File('${root.path}/$relativePath').existsSync()) {
    problems.add('Expected to find $relativePath, but it is missing.');
  }
}

/// The path of [file] from the repository root, with `/` separators.
String _relative(Directory root, FileSystemEntity file) {
  final base = _normalize(root.path);
  final path = _normalize(file.path);
  return path.startsWith('$base/') ? path.substring(base.length + 1) : path;
}

/// Every `.dart` file under [relativeDir], searched recursively without
/// following symbolic links, or null when the directory is missing (a problem
/// is recorded).
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
      .listSync(recursive: true, followLinks: false)
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

int _count(String text, String token) {
  var count = 0;
  var index = text.indexOf(token);
  while (index >= 0) {
    count++;
    index = text.indexOf(token, index + token.length);
  }
  return count;
}

/// How many occurrences of [token] in [text] are not directly preceded by an
/// ASCII letter.
int _countNotAfterLetter(String text, String token) {
  var count = 0;
  var index = text.indexOf(token);
  while (index >= 0) {
    if (index == 0 || !_isAsciiLetter(text.codeUnitAt(index - 1))) count++;
    index = text.indexOf(token, index + token.length);
  }
  return count;
}

void _forbid(
  String text,
  String label,
  List<String> tokens,
  String reason,
  List<String> problems,
) {
  for (final token in tokens) {
    if (text.contains(token)) {
      problems.add('$label must not contain "$token" ($reason).');
    }
  }
}

void _requireDocLines(
  List<String> lines,
  String label,
  List<String> docLines,
  List<String> problems,
) {
  for (final docLine in docLines) {
    if (!_hasLine(lines, docLine)) {
      problems.add('$label lacks the line "$docLine".');
    }
  }
}

void _checkNoExportOrPart(
  List<String> lines,
  String label,
  List<String> problems,
) {
  for (final line in lines) {
    final text = line.trimLeft();
    if (text.startsWith('export ') || text.startsWith('part ')) {
      problems.add('$label has an export or part line: "${line.trim()}".');
    }
  }
}

/// The text between the first two single quotes of an `import ` or `export `
/// line, or null for any other line. The rules on test files use it.
String? _importUri(String line) {
  final text = line.trimLeft();
  if (!text.startsWith('import ') && !text.startsWith('export ')) return null;
  final parts = text.split("'");
  return parts.length > 2 ? parts[1] : '';
}

/// An import or export statement, as Dart reads it.
final class _Statement {
  _Statement(this.isImport, this.text, this.tail, this.ended);

  final bool isImport;

  /// The statement without its line comments, with its lines joined by LF.
  final String text;

  /// The rest of the line after the `;` that ends the statement.
  final String tail;
  final bool ended;
}

/// Reads every import and export statement of [lines]: from a line that starts
/// with `import ` or `export `, up to the first `;` outside single quotes,
/// dropping the line comments outside single quotes.
List<_Statement> _statements(List<String> lines) {
  final result = <_Statement>[];
  var i = 0;
  while (i < lines.length) {
    final first = lines[i].trimLeft();
    final isImport = first.startsWith('import ');
    if (!isImport && !first.startsWith('export ')) {
      i++;
      continue;
    }
    final buffer = StringBuffer();
    var inQuotes = false;
    var ended = false;
    var tail = '';
    var j = i;
    while (j < lines.length && !ended) {
      final line = j == i ? first : lines[j];
      for (var k = 0; k < line.length; k++) {
        final char = line[k];
        if (char == "'") {
          inQuotes = !inQuotes;
        } else if (!inQuotes) {
          if (line.startsWith('//', k)) break;
          if (char == ';') {
            buffer.write(char);
            ended = true;
            tail = line.substring(k + 1);
            break;
          }
        }
        buffer.write(char);
      }
      if (!ended) buffer.write('\n');
      j++;
    }
    result.add(_Statement(isImport, buffer.toString(), tail, ended));
    i = j;
  }
  return result;
}

/// The texts between the first and second, third and fourth, and every later
/// pair of single quotes of a statement.
List<String> _uris(String statement) {
  final parts = statement.split("'");
  return [for (var i = 1; i < parts.length; i += 2) parts[i]];
}

/// Why [statement] is not well formed; empty when it is.
List<String> _formProblems(_Statement statement) {
  final problems = <String>[];
  final text = statement.text;
  if (!statement.ended) {
    problems.add('it has no ending ";"');
  } else {
    final tail = statement.tail.trim();
    if (tail.isNotEmpty && !tail.startsWith('//')) {
      problems.add('text follows its ";" on the same line');
    }
  }
  if (text.contains('/*')) problems.add('it has a block comment');
  for (final char in const ['"', '\\', '%']) {
    if (text.contains(char)) problems.add('it contains "$char"');
  }
  final quotes = _count(text, "'");
  if (quotes < 2 || quotes.isOdd) {
    problems.add('it has $quotes single quotes');
    return problems;
  }
  final parts = text.split("'");
  final uris = _uris(text);
  for (var k = 0; k + 1 < uris.length; k++) {
    final between = parts[2 * k + 2].replaceAll(RegExp(r'[ \t\r\n]'), '');
    if (!between.startsWith('if(')) {
      problems.add('two URIs are not joined by a condition');
    }
  }
  for (final uri in uris) {
    final hasScheme = uri.startsWith('package:') || uri.startsWith('dart:');
    if (!hasScheme && uri.contains(':')) {
      problems.add('"$uri" has a scheme other than package: and dart:');
    }
    if (uri.startsWith('/')) problems.add('"$uri" starts with "/"');
    if (uri.contains('//')) problems.add('"$uri" has an empty segment');
    if (hasScheme) {
      final segments = uri.substring(uri.indexOf(':') + 1).split('/');
      if (segments.contains('.') || segments.contains('..')) {
        problems.add('"$uri" has a "." or ".." segment');
      }
    }
  }
  return problems;
}

/// Checks that every import statement of [lines] is well formed, that every
/// URI of it is [allowed], and that every [required] URI is present.
void _checkImportStatements(
  List<String> lines,
  String label,
  List<String> allowed,
  List<String> required,
  List<String> problems,
) {
  final seen = <String>{};
  for (final statement in _statements(lines).where((s) => s.isImport)) {
    for (final why in _formProblems(statement)) {
      problems.add(
        '$label has an import statement that is not well formed ($why): "${_oneLine(statement.text)}".',
      );
    }
    for (final uri in _uris(statement.text)) {
      seen.add(uri);
      if (!allowed.contains(uri)) {
        problems.add('$label imports "$uri", which is not allowed.');
      }
    }
  }
  for (final uri in required) {
    if (!seen.contains(uri)) problems.add('$label does not import "$uri".');
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

const List<String> _typeStarts = [
  'class ',
  'final class ',
  'base class ',
  'sealed class ',
  'abstract interface class ',
  'enum ',
];

/// The public type declarations of [lines]; every other declaration line that
/// is not private is a problem.
List<String> _publicTypes(
  List<String> lines,
  String label,
  List<String> problems,
) {
  final publicTypes = <String>[];
  for (final line in lines) {
    if (!_isDeclarationLine(line)) continue;
    final name = _declaredName(line);
    if (name != null && name.startsWith('_')) continue;
    if (name != null && _typeStarts.any(line.startsWith)) {
      publicTypes.add(line);
      continue;
    }
    problems.add(
      '$label has a declaration that is neither a public type nor private: "${line.trim()}".',
    );
  }
  return publicTypes;
}

void _checkCatalogNumbers(String text, String label, List<String> problems) {
  for (final number in _catalogNumbers) {
    if (text.contains(number)) {
      problems.add(
        '$label contains the catalog number $number; read TrackedObject.noradId.',
      );
    }
  }
}

/// The declared name of the contract, or null.
String? _contractName(Directory root) {
  final file = File('${root.path}/$_domainPath');
  if (!file.existsSync()) return null;
  for (final line in file.readAsStringSync().split('\n')) {
    if (_isDeclarationLine(line) &&
        line.startsWith('abstract interface class ')) {
      return _declaredName(line);
    }
  }
  return null;
}

void _checkDomain(Directory root, List<String> problems) {
  final lines = _readLines(root, _domainPath, problems);
  if (lines == null) return;
  final text = lines.join('\n');
  _checkNoExportOrPart(lines, _domainPath, problems);
  _checkImportStatements(
    lines,
    _domainPath,
    _domainImports,
    _domainImports,
    problems,
  );
  final types = _publicTypes(lines, _domainPath, problems);
  final contracts = types.where(
    (t) => t.startsWith('abstract interface class '),
  );
  final finals = types.where((t) => t.startsWith('final class '));
  final enums = types.where((t) => t.startsWith('enum '));
  if (types.length != 3 ||
      contracts.length != 1 ||
      finals.length != 1 ||
      enums.length != 1) {
    problems.add(
      '$_domainPath must declare exactly one abstract interface class, one final class and one enum as public types, but declares ${types.length} public types.',
    );
  }
  _forbid(
    text,
    _domainPath,
    const [
      'DateTime.now',
      'DateTime.timestamp',
      'Stopwatch',
      'Sync(',
      'Timer',
      'periodic',
      'delayed',
    ],
    'no clock, no I/O, no timer',
    problems,
  );
  _checkCatalogNumbers(text, _domainPath, problems);
  _forbid(
    text,
    _domainPath,
    const ['nameLine', 'statusCode', 'GpFetch', 'Exception'],
    'a small contract',
    problems,
  );
  _requireDocLines(lines, _domainPath, _domainDocLines, problems);
}

void _checkRepository(Directory root, List<String> problems) {
  final lines = _readLines(root, _repositoryPath, problems);
  if (lines == null) return;
  final text = lines.join('\n');
  _checkNoExportOrPart(lines, _repositoryPath, problems);
  _checkImportStatements(
    lines,
    _repositoryPath,
    _repositoryImports,
    _repositoryRequiredImports,
    problems,
  );
  final types = _publicTypes(lines, _repositoryPath, problems);
  if (types.length != 1 || !types.single.startsWith('final class ')) {
    problems.add(
      '$_repositoryPath must declare exactly one public type, a final class, but declares ${types.length}.',
    );
  } else {
    final name = _contractName(root);
    final implementsContract =
        name != null &&
        RegExp(' implements ${RegExp.escape(name)}(?![A-Za-z0-9_])')
            .hasMatch(types.single);
    if (!implementsContract) {
      problems.add(
        '$_repositoryPath must declare its class on one line with " implements " and the contract name.',
      );
    }
  }
  _forbid(
    text,
    _repositoryPath,
    _noCatchTokens,
    'the repository handles no exception',
    problems,
  );
  if (_count(text, 'DateTime.now') != 1) {
    problems.add('$_repositoryPath must contain "DateTime.now" exactly once.');
  }
  _forbid(
    text,
    _repositoryPath,
    const ['DateTime.timestamp', 'Stopwatch'],
    'only its own wall clock',
    problems,
  );
  _forbid(
    text,
    _repositoryPath,
    const ['Timer', 'periodic', 'delayed'],
    'nothing is scheduled',
    problems,
  );
  _checkCatalogNumbers(text, _repositoryPath, problems);
  _requireDocLines(lines, _repositoryPath, _repositoryDocLines, problems);
}

void _checkFactory(Directory root, List<String> problems) {
  final lines = _readLines(root, _factoryPath, problems);
  if (lines == null) return;
  final text = lines.join('\n');
  _checkNoExportOrPart(lines, _factoryPath, problems);
  _checkImportStatements(lines, _factoryPath, _factoryImports, [
    for (final uri in _factoryImports)
      if (uri != 'dart:async') uri,
  ], problems);
  final types = _publicTypes(lines, _factoryPath, problems);
  if (types.length != 1 || !types.single.startsWith('final class ')) {
    problems.add(
      '$_factoryPath must declare exactly one public type, a final class, but declares ${types.length}.',
    );
  }
  if (!lines.any(
    (line) =>
        _isCodeLine(line) && line.contains('getApplicationSupportDirectory'),
  )) {
    problems.add(
      '$_factoryPath must name getApplicationSupportDirectory on a code line.',
    );
  }
  _forbid(
    text,
    _factoryPath,
    const ['systemTemp', 'Directory.current', 'createTemp'],
    'the directory is the application support directory',
    problems,
  );
  _forbid(
    text,
    _factoryPath,
    _forbiddenDirectoryFunctions,
    'only the application support directory',
    problems,
  );
  const resolved = 'getApplicationSupport';
  var index = text.indexOf('Directory(');
  while (index >= 0) {
    final partOfResolver =
        index >= resolved.length &&
        text.startsWith(resolved, index - resolved.length);
    if (!partOfResolver) {
      problems.add(
        '$_factoryPath builds a directory of its own with "Directory(".',
      );
    }
    index = text.indexOf('Directory(', index + 1);
  }
  _forbid(
    text,
    _factoryPath,
    const ['File(', '.path', '.create(', '.delete(', '.list(', 'Sync('],
    'the factory never touches the disk',
    problems,
  );
  final clients =
      _countNotAfterLetter(text, 'Client(') +
      _countNotAfterLetter(text, 'Client.new');
  if (clients != 1) {
    problems.add(
      '$_factoryPath must create the HTTP client in exactly one place, but has $clients.',
    );
  }
  if (!text.contains('.close(')) {
    problems.add('$_factoryPath must close the HTTP client with ".close(".');
  }
  _forbid(
    text,
    _factoryPath,
    const ['DateTime.now', 'DateTime.timestamp', 'Stopwatch'],
    'no clock',
    problems,
  );
  _forbid(
    text,
    _factoryPath,
    _noCatchTokens,
    'no exception is handled',
    problems,
  );
  _forbid(
    text,
    _factoryPath,
    const ['Timer', 'periodic', 'delayed'],
    'nothing is scheduled',
    problems,
  );
  _checkCatalogNumbers(text, _factoryPath, problems);
  _requireDocLines(lines, _factoryPath, _factoryDocLines, problems);
}

bool _isForbiddenSdk(String uri) {
  final lower = uri.toLowerCase();
  return lower.startsWith('dart:_') || _forbiddenSdk.contains(lower);
}

/// The path that relative [uri] names from the repository root, for the file
/// at [relativeFile].
String _resolve(String relativeFile, String uri) {
  final kept = relativeFile.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '.') continue;
    if (segment == '..') {
      if (kept.isNotEmpty) kept.removeLast();
      continue;
    }
    kept.add(segment);
  }
  return kept.join('/');
}

bool _isRelative(String uri) => !uri.contains(':') && !uri.startsWith('/');

bool _isInnerRelative(String uri) =>
    _isRelative(uri) && uri.isNotEmpty && !uri.split('/').contains('..');

void _checkWellFormed(List<String> lines, String label, List<String> problems) {
  for (final statement in _statements(lines)) {
    for (final why in _formProblems(statement)) {
      problems.add(
        '$label has an import statement that is not well formed ($why): "${_oneLine(statement.text)}".',
      );
    }
  }
}

void _checkLayers(Directory root, List<String> problems) {
  final domain = _dartFiles(root, _domainDir, problems);
  for (final file in domain ?? <File>[]) {
    final label = _relative(root, file);
    final lines = file.readAsStringSync().split('\n');
    _checkWellFormed(lines, label, problems);
    _checkNoExportOrPart(lines, label, problems);
    for (final statement in _statements(lines)) {
      for (final uri in _uris(statement.text)) {
        final allowed =
            uri == 'package:orbital_core/orbital_core.dart' ||
            uri.startsWith('package:wintek/domain/') ||
            (uri.startsWith('dart:') && !_isForbiddenSdk(uri));
        if (!allowed) {
          problems.add(
            '$label imports "$uri", which a domain library file may not.',
          );
        }
      }
    }
  }
  final presentation = _dartFiles(root, _presentationDir, problems);
  for (final file in presentation ?? <File>[]) {
    final label = _relative(root, file);
    final lines = file.readAsStringSync().split('\n');
    _checkWellFormed(lines, label, problems);
    for (final statement in _statements(lines)) {
      for (final uri in _uris(statement.text)) {
        final lower = uri.toLowerCase();
        final reachable =
            uri.startsWith('package:') ||
            uri.startsWith('dart:') ||
            _isInnerRelative(uri);
        if (!reachable) {
          problems.add('$label imports "$uri", which can reach another layer.');
        }
        for (final prefix in const [
          'package:wintek/data/',
          'package:http/',
          'package:path_provider/',
          'dart:io',
          'dart:convert',
        ]) {
          if (lower.startsWith(prefix)) {
            problems.add(
              '$label imports "$uri", which a presentation library file may not.',
            );
          }
        }
      }
    }
  }
  final all = _dartFiles(root, _libPath, problems);
  for (final file in all ?? <File>[]) {
    final relative = _relative(root, file);
    if (relative.startsWith(_dataPrefix) || relative == _mainPath) continue;
    final lines = file.readAsStringSync().split('\n');
    _checkWellFormed(lines, relative, problems);
    for (final statement in _statements(lines)) {
      for (final uri in _uris(statement.text)) {
        final lower = uri.toLowerCase();
        var reachesData =
            lower.startsWith('package:wintek/data/') ||
            lower == 'package:wintek/main.dart';
        if (_isRelative(uri)) {
          final resolved = _resolve(relative, uri).toLowerCase();
          reachesData =
              reachesData ||
              resolved.startsWith(_dataPrefix) ||
              resolved == _mainPath;
        }
        if (reachesData) {
          problems.add(
            '$relative imports "$uri", which reaches the data layer or the composition root.',
          );
        }
      }
    }
  }
  final main = _readLines(root, _mainPath, problems);
  if (main != null) _checkNoExportOrPart(main, _mainPath, problems);
  final lib = Directory('${root.path}/$_libPath');
  if (lib.existsSync()) {
    for (final entity in lib.listSync(recursive: true, followLinks: false)) {
      if (entity is Link) {
        problems.add('${_relative(root, entity)} is a symbolic link.');
      }
    }
  }
}

void _checkAmendments(Directory root, List<String> problems) {
  final amended = _readLines(root, _amendedSpecPath, problems);
  if (amended != null) {
    final anchor = amended.indexWhere((line) => line.trim() == _amendedAnchor);
    final roadmap = amended.indexWhere(
      (line) => line.trimLeft().startsWith('- **Roadmap row:**'),
    );
    if (anchor < 0) {
      problems.add(
        '$_amendedSpecPath lacks the amendment line of req-dat-004.',
      );
    } else if (roadmap >= 0 && anchor > roadmap) {
      problems.add(
        '$_amendedSpecPath has its amendment line after the roadmap row.',
      );
    }
    final heading = amended.indexWhere(
      (line) => line.trim() == _boundaryHeading,
    );
    if (heading < 0) {
      problems.add('$_amendedSpecPath lacks "$_boundaryHeading".');
    } else if (heading + 1 >= amended.length ||
        amended[heading + 1].trim() != _boundaryPackageLine) {
      problems.add(
        '$_amendedSpecPath must follow "$_boundaryHeading" with "$_boundaryPackageLine".',
      );
    }
    for (final line in const [
      _boundaryFactoryLine,
      _boundarySocketLine,
      _blocksLine,
    ]) {
      if (!_hasLine(amended, line)) {
        problems.add('$_amendedSpecPath lacks the line "$line".');
      }
    }
    if (_hasLine(amended, _boundaryOldLine)) {
      problems.add(
        '$_amendedSpecPath still has the line of revision 2 that the amendment replaces.',
      );
    }
    if (amended.any((line) => line.contains(_blocksOldText))) {
      problems.add('$_amendedSpecPath still says "$_blocksOldText".');
    }
  }
  for (final (path, title) in [
    (_adr7Path, _adr7Title),
    (_adr8Path, _adr8Title),
  ]) {
    final adr = _readLines(root, path, problems);
    if (adr == null) continue;
    if (!_hasLine(adr, title)) problems.add('$path lacks the line "$title".');
    if (!adr.any((line) => line.trimLeft().startsWith(_acceptedStatus))) {
      problems.add(
        '$path must have a Status line that starts with "$_acceptedStatus".',
      );
    }
  }
}

int _nextNonEmpty(List<String> lines, int from) {
  var index = from;
  while (index < lines.length && lines[index].trim().isEmpty) {
    index++;
  }
  return index < lines.length ? index : -1;
}

int _previousNonEmpty(List<String> lines, int from) {
  var index = from;
  while (index >= 0 && lines[index].trim().isEmpty) {
    index--;
  }
  return index;
}

/// True when the line at [index] opens a group or test of requirement [n]: on
/// the same line, or on the line after a bare `group(` or `test(`.
bool _opensRequirement(List<String> lines, int index, int n) {
  final text = lines[index].trim();
  final prefix = "'$_tagPrefix$n ";
  if (text.startsWith('group($prefix') || text.startsWith('test($prefix')) {
    return true;
  }
  if (text != 'group(' && text != 'test(') return false;
  return index + 1 < lines.length && lines[index + 1].trim().startsWith(prefix);
}

/// Checks the marker lines of [numbers] in the unit test file [label], and that
/// every group and test of it follows a marker with the number of its name.
void _checkUnitTags(
  List<String> lines,
  String label,
  List<int> numbers,
  List<String> problems,
) {
  for (final n in numbers) {
    final markers = [
      for (var i = 0; i < lines.length; i++)
        if (lines[i].trim() == _marker(n)) i,
    ];
    if (markers.isEmpty) {
      problems.add('$label has no line equal to "${_marker(n)}".');
    }
    for (final marker in markers) {
      final next = _nextNonEmpty(lines, marker + 1);
      if (next < 0 || !_opensRequirement(lines, next, n)) {
        problems.add(
          '$label: the test after "${_marker(n)}" must have a name that starts with "$_tagPrefix$n ".',
        );
      }
    }
  }
  for (var i = 0; i < lines.length; i++) {
    final text = lines[i].trim();
    if (!text.startsWith('group(') && !text.startsWith('test(')) continue;
    final previous = _previousNonEmpty(lines, i - 1);
    final match = previous < 0
        ? null
        : _markerPattern.firstMatch(lines[previous].trim());
    final n = match == null ? null : int.parse(match.group(1)!);
    if (n == null || !numbers.contains(n) || !_opensRequirement(lines, i, n)) {
      problems.add('$label has a group or test that is not tagged: "$text".');
    }
  }
}

void _checkUnitTest(
  List<String> lines,
  String label,
  List<String> allowed,
  List<String> required,
  List<int> numbers,
  List<String> problems,
) {
  final seen = <String>{};
  for (final line in lines) {
    final uri = line.trimLeft().startsWith('import ') ? _importUri(line) : null;
    if (uri == null) continue;
    seen.add(uri);
    if (!allowed.contains(uri)) {
      problems.add('$label imports "$uri", which is not allowed.');
    }
  }
  for (final uri in required) {
    if (!seen.contains(uri)) problems.add('$label does not import "$uri".');
  }
  final text = lines.join('\n');
  for (final line in lines) {
    if (line.trimLeft().startsWith('export ')) {
      problems.add('$label has an export line: "${line.trim()}".');
    }
  }
  if (_countNotAfterLetter(text, 'Client(') != 0) {
    problems.add('$label builds a client that is not named after a prefix.');
  }
  _forbid(
    text,
    label,
    _forbiddenInUnitTests,
    'no real client, no platform directory, temporary directories only',
    problems,
  );
  if (!text.contains('createTemp(')) {
    problems.add('$label must create its directories with createTemp(.');
  }
  if (!text.contains('tearDown(') && !text.contains('addTearDown(')) {
    problems.add('$label must delete its directories in a teardown.');
  }
  var index = text.indexOf('systemTemp');
  while (index >= 0) {
    if (!text.startsWith('.createTemp(', index + 'systemTemp'.length)) {
      problems.add(
        '$label uses systemTemp without calling .createTemp( directly.',
      );
    }
    index = text.indexOf('systemTemp', index + 1);
  }
  if (!_hasLine(lines, _unitTestCitation)) {
    problems.add('$label lacks the citation line "$_unitTestCitation".');
  }
  if (text.contains(_skipToken)) {
    problems.add('$label must not contain "$_skipToken".');
  }
  _checkUnitTags(lines, label, numbers, problems);
}

void _checkGuardTest(List<String> lines, List<String> problems) {
  final text = lines.join('\n');
  for (final n in const [7, 8, 9, 10]) {
    final marker = _marker(n);
    final index = lines.indexWhere((line) => line.trim() == marker);
    if (index < 0) {
      problems.add('$_guardPath has no line equal to "$marker".');
      continue;
    }
    final next = _nextNonEmpty(lines, index + 1);
    if (next < 0 || !lines[next].trim().startsWith('test(')) {
      problems.add(
        '$_guardPath: the line after "$marker" must start with test(.',
      );
    }
  }
  var index = text.indexOf(_tagPrefix);
  while (index >= 0) {
    final at = index + _tagPrefix.length;
    if (at < text.length) {
      final digit = text.codeUnitAt(at) - 0x30;
      final following = at + 1 < text.length
          ? text.codeUnitAt(at + 1) - 0x30
          : -1;
      final followedByDigit = following >= 0 && following <= 9;
      if (digit >= 1 && digit <= 6 && !followedByDigit) {
        problems.add(
          '$_guardPath names a tag of requirements 1 to 6 as a literal; build it by interpolation.',
        );
      }
    }
    index = text.indexOf(_tagPrefix, index + 1);
  }
  if (!_hasLine(lines, _repoRootImport)) {
    problems.add('$_guardPath must contain the line "$_repoRootImport".');
  }
  if (text.contains(_platformScriptToken)) {
    problems.add('$_guardPath must not contain "$_platformScriptToken".');
  }
  if (text.contains(_skipToken)) {
    problems.add('$_guardPath must not contain "$_skipToken".');
  }
  for (final line in lines) {
    final uri = line.trimLeft().startsWith('import ') ? _importUri(line) : null;
    if (uri != null && !_guardImports.contains(uri)) {
      problems.add('$_guardPath imports "$uri", which is not allowed.');
    }
  }
}

void main() {
  // REQ-DAT-004.7
  test('REQ-DAT-004.7 the contract, the repository and the opener are documented, placed and bounded', () {
    final root = _repoRoot(7);
    final problems = <String>[];

    _checkDomain(root, problems);
    _checkRepository(root, problems);
    _checkFactory(root, problems);

    if (problems.isNotEmpty) _failWith(7, problems);
  });

  // REQ-DAT-004.8
  test('REQ-DAT-004.8 the layers reach only what they may', () {
    final root = _repoRoot(8);
    final problems = <String>[];

    _checkLayers(root, problems);

    if (problems.isNotEmpty) _failWith(8, problems);
  });

  // REQ-DAT-004.9
  test('REQ-DAT-004.9 the amendments and the ADRs are in place', () {
    final root = _repoRoot(9);
    final problems = <String>[];

    _checkAmendments(root, problems);

    if (problems.isNotEmpty) _failWith(9, problems);
  });

  // REQ-DAT-004.10
  test('REQ-DAT-004.10 the new files follow the hygiene rules', () {
    final root = _repoRoot(10);
    final problems = <String>[];

    final repositoryTest = _readLines(root, _repositoryTestPath, problems);
    if (repositoryTest != null) {
      _checkUnitTest(
        repositoryTest,
        _repositoryTestPath,
        _repositoryTestImports,
        _repositoryTestRequiredImports,
        const [1, 2, 3, 4, 5],
        problems,
      );
    }
    final factoryTest = _readLines(root, _factoryTestPath, problems);
    if (factoryTest != null) {
      _checkUnitTest(
        factoryTest,
        _factoryTestPath,
        _factoryTestImports,
        _factoryTestRequiredImports,
        const [6],
        problems,
      );
    }
    final guardTest = _readLines(root, _guardPath, problems);
    if (guardTest != null) _checkGuardTest(guardTest, problems);
    for (final directory in const [_libPath, _domainDir, _presentationDir]) {
      _requireDirectory(root, directory, problems);
    }
    for (final path in const [
      _domainPath,
      _repositoryPath,
      _factoryPath,
      _snapshotPath,
      _specPath,
      _amendedSpecPath,
      _adr7Path,
      _adr8Path,
    ]) {
      _requireFile(root, path, problems);
    }
    for (final path in const [
      _domainPath,
      _repositoryPath,
      _factoryPath,
      _repositoryTestPath,
      _factoryTestPath,
      _guardPath,
      _specPath,
      _amendedSpecPath,
      _adr7Path,
      _adr8Path,
    ]) {
      _checkBytes(root, path, problems);
    }

    if (problems.isNotEmpty) _failWith(10, problems);
  });
}
