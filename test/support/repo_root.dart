import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Finds the repository root by walking up from the running test file's own
/// location (via [Platform.script]) until a directory containing
/// `AGENTS.md` is found, so tests do not depend on the working
/// directory they are invoked from. `flutter test` does not always preserve
/// the `test/` segment of [Platform.script], so a fixed parent count is
/// not reliable; searching for the governance-document marker is.
///
/// On failure the message is `[failurePrefix]Cannot resolve the repository
/// root (...)` followed by [failureSuffix], so each caller can name the
/// constitution principle it enforces.
Directory findRepoRoot({
  String failurePrefix = '',
  required String failureSuffix,
}) {
  final scriptPath = Platform.script.toFilePath();
  var candidate = File(scriptPath).parent;
  for (var i = 0; i < 10; i++) {
    if (File('${candidate.path}/AGENTS.md').existsSync()) {
      return candidate;
    }
    final parent = candidate.parent;
    if (parent.path == candidate.path) break;
    candidate = parent;
  }
  fail(
    '${failurePrefix}Cannot resolve the repository root (no AGENTS.md found above $scriptPath). $failureSuffix',
  );
}
