// Contract test for the CI workflow (specs/req-inf-002.md).
//
// Enforces Constitution principle 8 ("green before merge") by reading
// .github/workflows/ci.yml and the manifests as plain text. No YAML parser or
// any other package is used, so this test introduces no dependency of its own.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _principle8 =
    'Violates Constitution principle 8 (green before merge) — see specs/req-inf-002.md.';

const String _workflowPath = '.github/workflows/ci.yml';
const String _helperPath = 'test/support/repo_root.dart';
const String _guardPath = 'test/dependency_guard_test.dart';
const String _selfPath = 'test/ci_workflow_test.dart';

const String _appMarker = '  app:';
const String _coreMarker = '  orbital_core:';

const String _runsOn = 'runs-on: ubuntu-24.04';
const String _coreWorkingDir = 'working-directory: packages/orbital_core';
const String _appPubGet = 'run: flutter pub get --enforce-lockfile';
const String _corePubGet = 'run: dart pub get';
const String _analyze = 'run: flutter analyze --fatal-infos --fatal-warnings';
const String _dartCheck =
    r'''test "$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)" = "$DART_VERSION"''';

// The needles below are assembled from two literals so that this file never
// contains them verbatim: the checks of the helper and of the test files read
// their own sources.
const String _platformScript =
    'Platform'
    '.script';
const String _skipKeyword =
    'ski'
    'p:';

final RegExp _flutterPin = RegExp(r'^FLUTTER_VERSION: (\d+)\.(\d+)\.(\d+)$');
final RegExp _dartPin = RegExp(r'^DART_VERSION: (\d+)\.(\d+)\.(\d+)$');
final RegExp _sdkLowerBound = RegExp(r'^  sdk: \^(\d+\.\d+\.\d+)$');
final RegExp _checkoutUses = RegExp(
  r'^(- )?uses: actions/checkout@([0-9a-f]{40})( # v\d+\.\d+\.\d+)?$',
);

String _trimSpaces(String line) => line.replaceAll(RegExp(r'^ +| +$'), '');

int _count(List<String> block, String line) =>
    block.where((l) => l == line).length;

int _occurrences(String text, String needle) => text.split(needle).length - 1;

/// One requirement's view of the repository: every failure it raises starts
/// with `[REQ-INF-002.N]` and names Constitution principle 8.
class _Req {
  _Req(this.n);

  final int n;

  String get tag => '[REQ-INF-002.$n]';

  void check(bool ok, String what) {
    if (!ok) fail('$tag $what. $_principle8');
  }

  Directory get root =>
      findRepoRoot(failurePrefix: '$tag ', failureSuffix: _principle8);

  File _file(String relativePath) {
    final file = File('${root.path}/$relativePath');
    if (!file.existsSync()) {
      fail(
        '$tag Expected to find ${file.path}, but it is missing. $_principle8',
      );
    }
    return file;
  }

  String text(String relativePath) => _file(relativePath).readAsStringSync();

  List<int> bytes(String relativePath) => _file(relativePath).readAsBytesSync();

  _Workflow workflow() => _Workflow(this, text(_workflowPath));

  String sdkLowerBound(String manifestPath) {
    final lines = text(manifestPath).split('\n').map((l) => l.trimRight());
    final matches = lines
        .map(_sdkLowerBound.firstMatch)
        .whereType<RegExpMatch>()
        .toList();
    check(
      matches.isNotEmpty,
      'No line matching ${_sdkLowerBound.pattern} in $manifestPath',
    );
    return matches.first.group(1)!;
  }
}

class _Workflow {
  _Workflow(this.req, this.text)
    : raw = text.split('\n'),
      lines = text.split('\n').map(_trimSpaces).toList();

  final _Req req;
  final String text;
  final List<String> raw;
  final List<String> lines;

  List<String> get appBlock {
    final start = raw.indexOf(_appMarker);
    final end = raw.indexOf(_coreMarker);
    req.check(start >= 0, 'Missing the line "$_appMarker"');
    req.check(end >= 0, 'Missing the line "$_coreMarker"');
    req.check(start < end, '"$_appMarker" must come before "$_coreMarker"');
    return lines.sublist(start + 1, end);
  }

  List<String> get coreBlock {
    final start = raw.indexOf(_coreMarker);
    req.check(start >= 0, 'Missing the line "$_coreMarker"');
    return lines.sublist(start + 1);
  }

  void expectPresent(List<String> block, String line, String where) {
    req.check(block.contains(line), 'Missing the line "$line" in $where');
  }

  void expectCount(List<String> block, String line, int n, String where) {
    final found = _count(block, line);
    req.check(
      found == n,
      'Expected the line "$line" exactly $n time(s) in $where, found $found',
    );
  }

  void expectAbsent(String haystack, List<String> needles, String where) {
    for (final needle in needles) {
      req.check(
        !haystack.contains(needle),
        'The substring "$needle" must not occur in $where',
      );
    }
  }

  void expectInOrder(List<String> block, List<String> items, String where) {
    var from = 0;
    for (final item in items) {
      final index = block.indexOf(item, from);
      req.check(
        index >= 0,
        'Missing the line "$item" in $where, or it is out of order',
      );
      from = index + 1;
    }
  }

  String pinnedVersion(RegExp pattern, String key) {
    final matches = lines.where(pattern.hasMatch).toList();
    req.check(
      matches.length == 1,
      'Expected exactly one line matching ${pattern.pattern}, found ${matches.length}',
    );
    final version = matches.single.substring('$key: '.length);
    final found = _occurrences(text, version);
    req.check(
      found == 1,
      '$key value $version must occur exactly once in the workflow, found $found',
    );
    return version;
  }
}

void main() {
  // REQ-INF-002.1
  test('workflow file exists with LF encoding, triggers, permissions and concurrency', () {
    final req = _Req(1);
    final fileBytes = req.bytes(_workflowPath);
    req.check(
      !(fileBytes.length >= 3 &&
          fileBytes[0] == 0xEF &&
          fileBytes[1] == 0xBB &&
          fileBytes[2] == 0xBF),
      '$_workflowPath must not start with a UTF-8 BOM',
    );
    req.check(
      !fileBytes.contains(0x0D),
      '$_workflowPath must use LF line endings only (found a CR byte)',
    );

    final w = req.workflow();
    for (final line in [
      'name: CI',
      'pull_request:',
      'push:',
      'permissions:',
      'contents: read',
      'concurrency:',
      r'group: ci-${{ github.event.pull_request.number || github.ref }}',
      'cancel-in-progress: true',
    ]) {
      w.expectPresent(w.lines, line, 'the workflow');
    }
    w.expectCount(w.lines, 'branches: [main]', 2, 'the workflow');
    w.expectAbsent(w.text, [
      'secrets.',
      'workflow_dispatch',
      'schedule:',
      'tags:',
      ': write',
    ], 'the workflow');
  });

  // REQ-INF-002.2
  test('toolchain and runner are pinned and agree with the manifests', () {
    final req = _Req(2);
    final w = req.workflow();

    w.pinnedVersion(_flutterPin, 'FLUTTER_VERSION');
    final dartVersion = w.pinnedVersion(_dartPin, 'DART_VERSION');
    final appSdk = req.sdkLowerBound('pubspec.yaml');
    final coreSdk = req.sdkLowerBound('packages/orbital_core/pubspec.yaml');
    req.check(
      dartVersion == appSdk,
      'DART_VERSION $dartVersion differs from the sdk lower bound $appSdk in pubspec.yaml',
    );
    req.check(
      dartVersion == coreSdk,
      'DART_VERSION $dartVersion differs from the sdk lower bound $coreSdk in packages/orbital_core/pubspec.yaml',
    );

    w.expectCount(w.lines, _runsOn, 2, 'the workflow');
    w.expectAbsent(w.text, ['ubuntu-latest'], 'the workflow');
    w.expectPresent(
      w.appBlock,
      r'flutter --version | head -n 1 | grep -F "Flutter $FLUTTER_VERSION "',
      'the app block',
    );
    w.expectCount(w.lines, _dartCheck, 2, 'the workflow');
    w.expectCount(w.appBlock, _dartCheck, 1, 'the app block');
    w.expectCount(w.coreBlock, _dartCheck, 1, 'the core block');
  });

  // REQ-INF-002.3
  test('only actions/checkout is used and the toolchains come from official sources', () {
    final req = _Req(3);
    final w = req.workflow();

    final uses = w.lines
        .where((l) => l.startsWith('uses:') || l.startsWith('- uses:'))
        .toList();
    req.check(
      uses.length == 2,
      'Expected exactly 2 "uses:" lines, found ${uses.length}',
    );
    final shas = <String>{};
    for (final line in uses) {
      final match = _checkoutUses.firstMatch(line);
      req.check(
        match != null,
        'The line "$line" does not match ${_checkoutUses.pattern}',
      );
      shas.add(match!.group(2)!);
    }
    req.check(
      shas.length == 1,
      'Both checkout steps must use the same SHA, found $shas',
    );
    w.expectCount(w.lines, 'persist-credentials: false', 2, 'the workflow');

    w.expectPresent(
      w.appBlock,
      r'git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$RUNNER_TEMP/flutter"',
      'the app block',
    );
    w.expectPresent(
      w.appBlock,
      r'echo "$RUNNER_TEMP/flutter/bin" >> "$GITHUB_PATH"',
      'the app block',
    );
    w.expectPresent(
      w.coreBlock,
      r'curl -fsSL --retry 3 -o "$RUNNER_TEMP/dartsdk.zip" "https://storage.googleapis.com/dart-archive/channels/stable/release/$DART_VERSION/sdk/dartsdk-linux-x64-release.zip"',
      'the core block',
    );
    w.expectPresent(
      w.coreBlock,
      r'unzip -q "$RUNNER_TEMP/dartsdk.zip" -d "$RUNNER_TEMP"',
      'the core block',
    );
    w.expectPresent(
      w.coreBlock,
      r'echo "$RUNNER_TEMP/dart-sdk/bin" >> "$GITHUB_PATH"',
      'the core block',
    );
  });

  // REQ-INF-002.4
  test('dependency resolution is deterministic', () {
    final req = _Req(4);
    final w = req.workflow();

    w.expectPresent(w.appBlock, _appPubGet, 'the app block');
    w.expectCount(w.lines, _corePubGet, 2, 'the workflow');
    w.expectCount(w.lines, _coreWorkingDir, 2, 'the workflow');
    w.expectInOrder(w.appBlock, [
      _appPubGet,
      _corePubGet,
      _analyze,
    ], 'the app block');
  });

  // REQ-INF-002.5
  test('app-gates job runs format, analyze and test in order', () {
    final req = _Req(5);
    final w = req.workflow();
    final block = w.appBlock;

    w.expectPresent(block, 'name: app-gates', 'the app block');
    w.expectPresent(block, _runsOn, 'the app block');
    w.expectPresent(block, 'timeout-minutes: 15', 'the app block');
    w.expectInOrder(block, [
      '- name: Checkout',
      '- name: Install Flutter',
      '- name: Verify toolchain versions',
      '- name: Resolve app dependencies',
      '- name: Resolve orbital_core dependencies',
      '- name: Format',
      'run: dart format --set-exit-if-changed .',
      '- name: Analyze',
      _analyze,
      '- name: Test',
      'run: flutter test',
    ], 'the app block');
  });

  // REQ-INF-002.6
  test(
    'orbital-core-gates job is Dart-only and runs analyze and test in order',
    () {
      final req = _Req(6);
      final w = req.workflow();
      final block = w.coreBlock;

      w.expectPresent(block, 'name: orbital-core-gates', 'the core block');
      w.expectPresent(block, _runsOn, 'the core block');
      w.expectPresent(block, 'timeout-minutes: 10', 'the core block');
      w.expectPresent(block, _coreWorkingDir, 'the core block');
      w.expectInOrder(block, [
        '- name: Checkout',
        '- name: Install Dart',
        '- name: Assert Flutter is absent',
        r'''if command -v flutter; then echo "Flutter is on PATH; the orbital_core job must be Dart-only (Constitution principle 3)." >&2; exit 1; fi''',
        '- name: Verify toolchain versions',
        '- name: Resolve dependencies',
        _corePubGet,
        '- name: Analyze',
        'run: dart analyze --fatal-infos',
        '- name: Test',
        'run: dart test',
      ], 'the core block');
      w.expectAbsent(block.join('\n'), [
        'flutter.git',
        'flutter pub',
        'flutter analyze',
        'flutter test',
        'FLUTTER_VERSION',
      ], 'the core block');
    },
  );

  // REQ-INF-002.7
  test('no soft failures and exactly two jobs', () {
    final req = _Req(7);
    final w = req.workflow();

    w.expectAbsent(w.text, [
      'continue-on-error',
      'if:',
      '|| true',
      'cache',
    ], 'the workflow');

    final jobsIndex = w.raw.indexOf('jobs:');
    req.check(
      jobsIndex >= 0,
      'Missing the line "jobs:" with no leading spaces',
    );
    final unindented = w.raw
        .skip(jobsIndex + 1)
        .where((l) => l.isNotEmpty && !l.startsWith(' '))
        .toList();
    req.check(
      unindented.isEmpty,
      'No line after "jobs:" may start with a non-space character, found $unindented',
    );

    w.expectCount(w.lines, 'app:', 1, 'the workflow');
    w.expectCount(w.lines, 'orbital_core:', 1, 'the workflow');
    req.check(
      w.raw.contains(_appMarker) &&
          w.raw.indexOf(_appMarker) < w.raw.indexOf(_coreMarker),
      '"$_appMarker" must come before "$_coreMarker"',
    );
  });

  // REQ-INF-002.8
  test('job names match the required status checks', () {
    final req = _Req(8);
    final w = req.workflow();

    w.expectCount(w.lines, 'name: app-gates', 1, 'the workflow');
    w.expectCount(w.lines, 'name: orbital-core-gates', 1, 'the workflow');
  });

  // REQ-INF-002.9
  test('the repository-root helper is shared by the guard and this test', () {
    final req = _Req(9);
    const importLine = "import 'support/repo_root.dart';";

    final helper = req.text(_helperPath);
    req.check(
      helper.contains(_platformScript),
      '$_helperPath must contain "$_platformScript"',
    );
    req.check(
      helper.contains('AGENTS.md'),
      '$_helperPath must contain "AGENTS.md"',
    );
    req.check(
      helper.contains('Cannot resolve the repository root'),
      '$_helperPath must fail with "Cannot resolve the repository root"',
    );

    final guard = req.text(_guardPath);
    req.check(
      guard.split('\n').map(_trimSpaces).contains(importLine),
      '$_guardPath must contain the line "$importLine"',
    );
    req.check(
      !guard.contains(_platformScript),
      '$_guardPath must not contain "$_platformScript"',
    );
    req.check(
      guard.contains('Constitution principle 3'),
      '$_guardPath must report "Constitution principle 3" when the root cannot be resolved',
    );

    final self = req.text(_selfPath);
    req.check(
      self.split('\n').map(_trimSpaces).contains(importLine),
      '$_selfPath must contain the line "$importLine"',
    );
    req.check(
      !self.contains(_platformScript),
      '$_selfPath must not contain "$_platformScript"',
    );
    req.check(
      self.contains('Constitution principle 8'),
      '$_selfPath must report "Constitution principle 8" when the root cannot be resolved',
    );
  });

  // REQ-INF-002.10
  test(
    'this test names every requirement, never skips and runs in flutter test',
    () {
      final req = _Req(10);
      final self = req.text(_selfPath);
      final lines = self.split('\n').map(_trimSpaces).toList();

      for (var n = 1; n <= 10; n++) {
        final index = lines.indexOf('// REQ-INF-002.$n');
        req.check(
          index >= 0,
          '$_selfPath is missing the line "// REQ-INF-002.$n"',
        );
        final next = lines
            .skip(index + 1)
            .firstWhere((l) => l.isNotEmpty, orElse: () => '');
        req.check(
          next.startsWith('test('),
          'The line after "// REQ-INF-002.$n" must open a test, found "$next"',
        );
      }
      req.check(
        !self.contains(_skipKeyword),
        '$_selfPath must not contain "$_skipKeyword"',
      );
      req.check(
        self.contains('[REQ-INF-002.\$n]') &&
            self.contains('Constitution principle 8'),
        'Every failure message must start with [REQ-INF-002.N] and name Constitution principle 8',
      );

      final w = req.workflow();
      w.expectPresent(w.appBlock, 'run: flutter test', 'the app block');
    },
  );
}
