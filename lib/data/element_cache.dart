import 'dart:convert';
import 'dart:io';

import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/data/celestrak_gp_client.dart';
import 'package:wintek/domain/satellite_catalog.dart';

const int _schemaVersion = 1;
const int _sizeLimitBytes = 65536;

/// The local element cache of Wintek: the last good CelesTrak GP payload of each tracked object, one JSON file per object (specs/req-dat-003.md).
///
/// File: gp_NORADID.json in the injected directory, where NORADID is TrackedObject.noradId; each write goes to gp_NORADID.json.tmp first, is flushed and is then renamed.
/// Writes only a valid success of the GP client, with its arrival instant converted to UTC; the cache never reads a clock, so the data age of Constitution principle 9 is the age of the download.
/// Reads validate the document again with OrbitalElements.fromTle and the requested catalog number; anything else is no entry, never an error.
/// Asynchronous file access only, never on the frame path (Constitution principle 13); deleting any cache file or the directory is harmless (Constitution principle 11).
/// The directory is injected and resolved by req-dat-004; this file never looks it up.
/// A cache file longer than 65536 bytes is no entry; a read never loads more than 65537 bytes of it, and a write never stores a longer document.
final class ElementCache {
  ElementCache(this._directory);

  final Directory _directory;

  /// Completes with true when the cache file of the success's object now holds
  /// its document, and with false otherwise.
  Future<bool> write(GpFetchSuccess success) async {
    final bytes = _documentBytes(success);
    if (bytes == null) return false;
    final file = _cacheFile(success.object);
    final temporary = File('${file.path}.tmp');
    try {
      await _directory.create(recursive: true);
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  /// Completes with the stored entry of [object], or with null when there is
  /// none. Changes nothing on disk.
  Future<CachedGpElements?> read(TrackedObject object) async {
    final bytes = await _readBounded(_cacheFile(object));
    return bytes == null ? null : _parse(bytes, object);
  }

  File _cacheFile(TrackedObject object) =>
      File('${_directory.path}/gp_${object.noradId}.json');
}

/// An element set read back from the cache, not a fresh download.
final class CachedGpElements {
  const CachedGpElements({
    required this.object,
    required this.nameLine,
    required this.line1,
    required this.line2,
    required this.arrivedAtUtc,
  });

  final TrackedObject object;
  final String nameLine;
  final String line1;
  final String line2;

  /// When the element set arrived from CelesTrak, in UTC.
  final DateTime arrivedAtUtc;
}

bool _endsWithBlank(String line) =>
    line.endsWith(' ') || line.endsWith('\t') || line.endsWith('\r');

bool _isValidNameLine(String line) =>
    line.isNotEmpty &&
    !line.contains('\n') &&
    !_endsWithBlank(line) &&
    utf8.decode(utf8.encode(line)) == line;

bool _hasValidLines(TrackedObject object, String line1, String line2) {
  if (_endsWithBlank(line1) || _endsWithBlank(line2)) return false;
  try {
    return OrbitalElements.fromTle(line1, line2).catalogNumber ==
        object.noradId;
  } on FormatException {
    return false;
  }
}

List<int>? _documentBytes(GpFetchSuccess success) {
  if (!_isValidNameLine(success.nameLine) ||
      !_hasValidLines(success.object, success.line1, success.line2)) {
    return null;
  }
  final bytes = utf8.encode(
    jsonEncode({
      'schemaVersion': _schemaVersion,
      'noradId': success.object.noradId,
      'nameLine': success.nameLine,
      'line1': success.line1,
      'line2': success.line2,
      'fetchedAtUtc': success.arrivedAtUtc.toUtc().toIso8601String(),
    }),
  );
  return bytes.length > _sizeLimitBytes ? null : bytes;
}

Future<List<int>?> _readBounded(File file) async {
  try {
    final handle = await file.open();
    try {
      return await handle.read(_sizeLimitBytes + 1);
    } finally {
      await handle.close();
    }
  } on FileSystemException {
    return null;
  }
}

CachedGpElements? _parse(List<int> bytes, TrackedObject object) {
  if (bytes.length > _sizeLimitBytes) return null;
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return null;
  }
  try {
    final document = jsonDecode(utf8.decode(bytes));
    if (document is! Map<String, dynamic>) return null;
    final version = document['schemaVersion'];
    final noradId = document['noradId'];
    final nameLine = document['nameLine'];
    final line1 = document['line1'];
    final line2 = document['line2'];
    final fetchedAtUtc = document['fetchedAtUtc'];
    if (version is! int || version != _schemaVersion) return null;
    if (noradId is! int || noradId != object.noradId) return null;
    if (nameLine is! String ||
        line1 is! String ||
        line2 is! String ||
        fetchedAtUtc is! String) {
      return null;
    }
    if (!_isValidNameLine(nameLine) ||
        !_hasValidLines(object, line1, line2) ||
        !fetchedAtUtc.endsWith('Z')) {
      return null;
    }
    return CachedGpElements(
      object: object,
      nameLine: nameLine,
      line1: line1,
      line2: line2,
      arrivedAtUtc: DateTime.parse(fetchedAtUtc),
    );
  } on FormatException {
    return null;
  }
}
