// REQ-INF-001.8
//
// Enforces Constitution principle 3 ("the math core is pure Dart") and the
// baseline fixed by ADR-0001, by reading files directly with
// File(...).readAsStringSync(). No YAML parser or any other package is used,
// so this guard introduces no dependency of its own.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/repo_root.dart';

const String _principle3 =
    'Violates Constitution principle 3 (the math core is pure Dart) — see docs/adr/ADR-0001-baseline-packages.md.';

const Set<String> _allowedAppRuntimeDeps = {
  'flutter',
  'flutter_riverpod',
  'http',
  'path_provider',
  'orbital_core',
};

const Set<String> _allowedAppDevDeps = {'flutter_test', 'flutter_lints'};

const Set<String> _allowedCoreDevDeps = {'lints', 'test'};

/// Returns the set of top-level dependency names declared directly under
/// [sectionName] (a two-space-indented key, not a nested field).
Set<String> _topLevelKeysUnderSection(String yamlContent, String sectionName) {
  final lines = yamlContent.split('\n');
  final names = <String>{};
  var inSection = false;
  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    if (line == '$sectionName:') {
      inSection = true;
      continue;
    }
    if (!inSection) continue;
    if (line.isEmpty) continue;
    if (!line.startsWith(' ')) {
      // Back to column 0: the section ended.
      break;
    }
    final match = RegExp(r'^  ([A-Za-z0-9_]+):').firstMatch(line);
    if (match != null) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

void main() {
  final repoRoot = findRepoRoot(failureSuffix: _principle3);

  test('app manifest declares no dependency outside the ADR-0001 baseline', () {
    final manifestFile = File('${repoRoot.path}/pubspec.yaml');
    if (!manifestFile.existsSync()) {
      fail(
        'Expected to find ${manifestFile.path}, but it is missing. $_principle3',
      );
    }
    final content = manifestFile.readAsStringSync();

    final runtimeDeps = _topLevelKeysUnderSection(content, 'dependencies');
    final extraRuntime = runtimeDeps.difference(_allowedAppRuntimeDeps);
    expect(
      extraRuntime,
      isEmpty,
      reason:
          'Unapproved runtime dependency/ies $extraRuntime in pubspec.yaml. $_principle3',
    );

    final devDeps = _topLevelKeysUnderSection(content, 'dev_dependencies');
    final extraDev = devDeps.difference(_allowedAppDevDeps);
    expect(
      extraDev,
      isEmpty,
      reason:
          'Unapproved dev dependency/ies $extraDev in pubspec.yaml. $_principle3',
    );
  });

  test('orbital_core manifest declares zero runtime deps, no Flutter SDK and only the approved dev deps', () {
    final coreManifestFile = File(
      '${repoRoot.path}/packages/orbital_core/pubspec.yaml',
    );
    if (!coreManifestFile.existsSync()) {
      fail(
        'Expected to find ${coreManifestFile.path}, but it is missing. $_principle3',
      );
    }
    final content = coreManifestFile.readAsStringSync();

    final runtimeDeps = _topLevelKeysUnderSection(content, 'dependencies');
    expect(
      runtimeDeps,
      isEmpty,
      reason:
          'orbital_core must declare zero runtime dependencies, found $runtimeDeps. $_principle3',
    );

    expect(
      content.contains('sdk: flutter'),
      isFalse,
      reason: 'orbital_core must not depend on the Flutter SDK. $_principle3',
    );

    expect(
      content.contains('resolution: workspace') ||
          content.contains('\nworkspace:'),
      isFalse,
      reason:
          'orbital_core must resolve its dependencies independently, not via a shared workspace resolution. $_principle3',
    );

    final devDeps = _topLevelKeysUnderSection(content, 'dev_dependencies');
    final extraDev = devDeps.difference(_allowedCoreDevDeps);
    expect(
      extraDev,
      isEmpty,
      reason:
          'Unapproved dev dependency/ies $extraDev in packages/orbital_core/pubspec.yaml. $_principle3',
    );
  });

  test('orbital_core/lib never imports dart:io or dart:ffi', () {
    final libDir = Directory('${repoRoot.path}/packages/orbital_core/lib');
    if (!libDir.existsSync()) {
      fail('Expected to find ${libDir.path}, but it is missing. $_principle3');
    }

    final offendingFiles = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final text = entity.readAsStringSync();
      if (text.contains("import 'dart:io';") ||
          text.contains("import 'dart:ffi';")) {
        offendingFiles.add(entity.path);
      }
    }

    expect(
      offendingFiles,
      isEmpty,
      reason:
          'Found a forbidden dart:io/dart:ffi import in $offendingFiles. $_principle3',
    );
  });
}
