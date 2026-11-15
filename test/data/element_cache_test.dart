// Unit tests of the local element cache of specs/req-dat-003.md (requirements 1 to 4).
//
// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; every test writes only inside a temporary directory it creates and deletes (Constitution principle 11).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wintek/data/celestrak_gp_client.dart';
import 'package:wintek/data/element_cache.dart';
import 'package:wintek/domain/satellite_catalog.dart';

import '../domain/celestrak_tle_snapshot.dart';

const int _sizeLimitBytes = 65536;
const List<String> _members = [
  'schemaVersion',
  'noradId',
  'nameLine',
  'line1',
  'line2',
  'fetchedAtUtc',
];

final DateTime _t1 = DateTime.utc(2026, 11, 14, 11);
final DateTime _t2 = DateTime.utc(2026, 11, 14, 15);
final DateTime _t3 = DateTime.utc(2026, 11, 14, 11, 0, 0, 123, 456);
final DateTime _l1 = DateTime(2026, 11, 14, 11);

/// The tracked object at [position], from 1 to 4, is [TrackedObject.values] in
/// order, which is also the order of the snapshot.
TrackedObject _object(int position) => TrackedObject.values[position - 1];
String _name(int position) => celestrakTleSnapshot[(position - 1) * 3];
String _line1(int position) => celestrakTleSnapshot[(position - 1) * 3 + 1];
String _line2(int position) => celestrakTleSnapshot[(position - 1) * 3 + 2];

GpFetchSuccess _success(
  int position,
  DateTime at, {
  TrackedObject? object,
  String? nameLine,
  String? line1,
  String? line2,
}) => GpFetchSuccess(
  object ?? _object(position),
  nameLine: nameLine ?? _name(position),
  line1: line1 ?? _line1(position),
  line2: line2 ?? _line2(position),
  arrivedAtUtc: at,
);

Map<String, Object?> _documentMap(GpFetchSuccess success) => {
  'schemaVersion': 1,
  'noradId': success.object.noradId,
  'nameLine': success.nameLine,
  'line1': success.line1,
  'line2': success.line2,
  'fetchedAtUtc': success.arrivedAtUtc.toUtc().toIso8601String(),
};

String _jsonText(GpFetchSuccess success) => jsonEncode(_documentMap(success));

List<int> _documentBytes(GpFetchSuccess success) =>
    utf8.encode(_jsonText(success));

String _validText(int position) => _jsonText(_success(position, _t1));

Map<String, Object?> _validMap(int position) =>
    _documentMap(_success(position, _t1));

List<int> _encode(Map<String, Object?> document) =>
    utf8.encode(jsonEncode(document));

File _cacheFile(Directory directory, int position) =>
    File('${directory.path}/gp_${_object(position).noradId}.json');

File _tempFile(Directory directory, int position) =>
    File('${_cacheFile(directory, position).path}.tmp');

Future<List<String>> _names(Directory directory) async {
  final entries = await directory.list().toList();
  return [for (final entry in entries) entry.path.split(RegExp(r'[\\/]')).last]
    ..sort();
}

String _cacheFileName(int position) => 'gp_${_object(position).noradId}.json';

/// The number n for which the stored document of the success of position 1 at
/// T1, with its name line replaced by n letters A, is exactly the size limit.
int _limitNameLength() {
  final base = utf8.encode(_jsonText(_success(1, _t1, nameLine: 'A'))).length;
  return _sizeLimitBytes - base + 1;
}

String _badChecksum(String line) {
  final last = int.parse(line.substring(line.length - 1));
  return '${line.substring(0, line.length - 1)}${(last + 1) % 10}';
}

List<int> _padded(List<int> bytes, int length) => [
  ...bytes,
  ...List.filled(length - bytes.length, 0x20),
];

Map<String, List<int>> _invalidDocuments() {
  final valid = _validText(1);
  final validBytes = utf8.encode(valid);
  Map<String, Object?> variant(String key, Object? value) => {
    ..._validMap(1),
    key: value,
  };
  final nameStart = valid.indexOf('"nameLine":"') + '"nameLine":"'.length;
  final nameValue = '"nameLine":"${_name(1)}"';
  final noradValue = '"noradId":${_object(1).noradId},';

  return {
    'an empty file': <int>[],
    'the text not json': utf8.encode('not json'),
    'the text []': utf8.encode('[]'),
    'the text null': utf8.encode('null'),
    'a truncated document': utf8.encode(valid.substring(0, valid.length - 1)),
    'bytes that are not UTF-8': [0xFF, 0xFE, 0x00],
    'a UTF-8 BOM before the document': [0xEF, 0xBB, 0xBF, ...validBytes],
    'a malformed byte inside nameLine': [
      ...utf8.encode(valid.substring(0, nameStart)),
      0xFF,
      ...utf8.encode(valid.substring(nameStart)),
    ],
    'a file of 65537 bytes': _padded(validBytes, _sizeLimitBytes + 1),
    'schemaVersion 2': _encode(variant('schemaVersion', 2)),
    'schemaVersion as a string': _encode(variant('schemaVersion', '1')),
    'schemaVersion 1.0': utf8.encode(
      valid.replaceFirst('"schemaVersion":1,', '"schemaVersion":1.0,'),
    ),
    for (final key in _members)
      'a document without $key': _encode({..._validMap(1)}..remove(key)),
    for (final key in _members)
      'a document with $key null': _encode(variant(key, null)),
    'noradId as a string': _encode(variant('noradId', '${_object(1).noradId}')),
    'noradId with a fraction': utf8.encode(
      valid.replaceFirst(noradValue, '"noradId":${_object(1).noradId}.0,'),
    ),
    'nameLine as a number': _encode(variant('nameLine', 1)),
    'line1 as a number': _encode(variant('line1', 1)),
    'line2 as a boolean': _encode(variant('line2', true)),
    'an empty nameLine': _encode(variant('nameLine', '')),
    'a nameLine with trailing blanks': _encode(
      variant('nameLine', '${_name(1)}   '),
    ),
    'a nameLine with an LF escape': utf8.encode(
      valid.replaceFirst(nameValue, r'"nameLine":"ISS\n (ZARYA)"'),
    ),
    'a nameLine with a surrogate escape': utf8.encode(
      valid.replaceFirst(nameValue, '"nameLine":"${_name(1)}\\ud800"'),
    ),
    'the document of position 2': utf8.encode(_validText(2)),
    'only noradId of another object': _encode(
      variant('noradId', _object(2).noradId),
    ),
    'the element lines of another object': _encode({
      ..._validMap(1),
      'line1': _line1(2),
      'line2': _line2(2),
    }),
    'a bad checksum in line2': _encode(
      variant('line2', _badChecksum(_line2(1))),
    ),
    'a shifted line1': _encode(variant('line1', ' ${_line1(1)}')),
    'a CR at the end of line1': _encode(variant('line1', '${_line1(1)}\r')),
    'blanks at the end of line2': _encode(variant('line2', '${_line2(1)}   ')),
    'fetchedAtUtc without Z': _encode(
      variant('fetchedAtUtc', '2026-11-14T11:00:00.000'),
    ),
    'fetchedAtUtc with an offset': _encode(
      variant('fetchedAtUtc', '2026-11-14T11:00:00.000+00:00'),
    ),
    'fetchedAtUtc that is not an instant': _encode(
      variant('fetchedAtUtc', 'yesterday'),
    ),
    'fetchedAtUtc as a number': _encode(variant('fetchedAtUtc', 0)),
  };
}

Map<String, GpFetchSuccess> _invalidSuccesses() {
  final limit = _limitNameLength();
  return {
    'a bad checksum': _success(1, _t1, line2: _badChecksum(_line2(1))),
    'the lines of another object': _success(
      1,
      _t1,
      nameLine: _name(2),
      line1: _line1(2),
      line2: _line2(2),
    ),
    'an empty name line': _success(1, _t1, nameLine: ''),
    'a name line with trailing blanks': _success(
      1,
      _t1,
      nameLine: '${_name(1)}   ',
    ),
    'a name line with an LF': _success(1, _t1, nameLine: 'ISS\n (ZARYA)'),
    'a name line with an unpaired surrogate': _success(
      1,
      _t1,
      nameLine: '${_name(1)}${String.fromCharCode(0xD800)}',
    ),
    'a CR at the end of line1': _success(1, _t1, line1: '${_line1(1)}\r'),
    'blanks at the end of line2': _success(1, _t1, line2: '${_line2(1)}   '),
    'a document of 65537 bytes': _success(1, _t1, nameLine: 'A' * (limit + 1)),
    'a name line of 70000 letters': _success(1, _t1, nameLine: 'A' * 70000),
  };
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('wintek_cache_');
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  // REQ-DAT-003.1
  group('REQ-DAT-003.1 write', () {
    for (var position = 1; position <= 4; position++) {
      test('REQ-DAT-003.1 stores the success of position $position', () async {
        final success = _success(position, _t1);

        expect(await ElementCache(temp).write(success), isTrue);

        expect(await _names(temp), [_cacheFileName(position)]);
        final bytes = await _cacheFile(temp, position).readAsBytes();
        expect(bytes, _documentBytes(success));
        final document = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        expect(document.keys, _members);
        final fetchedAtUtc = document['fetchedAtUtc'] as String;
        expect(fetchedAtUtc.endsWith('Z'), isTrue);
        expect(DateTime.parse(fetchedAtUtc), _t1);
      });
    }

    test('REQ-DAT-003.1 stores a local instant converted to UTC', () async {
      expect(await ElementCache(temp).write(_success(1, _l1)), isTrue);

      final text = utf8.decode(await _cacheFile(temp, 1).readAsBytes());
      final document = jsonDecode(text) as Map<String, dynamic>;
      final fetchedAtUtc = document['fetchedAtUtc'] as String;
      expect(fetchedAtUtc.endsWith('Z'), isTrue);
      final parsed = DateTime.parse(fetchedAtUtc);
      expect(parsed.isUtc, isTrue);
      expect(parsed.isAtSameMomentAs(_l1), isTrue);
    });

    test('REQ-DAT-003.1 replaces the previous document of an object', () async {
      final cache = ElementCache(temp);

      expect(await cache.write(_success(1, _t1)), isTrue);
      expect(await cache.write(_success(1, _t2)), isTrue);

      expect(await _names(temp), [_cacheFileName(1)]);
      final text = utf8.decode(await _cacheFile(temp, 1).readAsBytes());
      final document = jsonDecode(text) as Map<String, dynamic>;
      expect(DateTime.parse(document['fetchedAtUtc'] as String), _t2);
    });

    test('REQ-DAT-003.1 keeps one file per object', () async {
      final cache = ElementCache(temp);

      for (var position = 1; position <= 4; position++) {
        expect(await cache.write(_success(position, _t1)), isTrue);
      }

      expect(
        await _names(temp),
        [
          for (var position = 1; position <= 4; position++)
            _cacheFileName(position),
        ]..sort(),
      );
    });

    test('REQ-DAT-003.1 creates a missing cache directory', () async {
      final missing = Directory('${temp.path}/missing');

      expect(await ElementCache(missing).write(_success(1, _t1)), isTrue);

      expect(await _names(missing), [_cacheFileName(1)]);
    });

    test('REQ-DAT-003.1 creates the missing ancestors', () async {
      final nested = Directory('${temp.path}/a/b');

      expect(await ElementCache(nested).write(_success(1, _t1)), isTrue);

      expect(await _names(nested), [_cacheFileName(1)]);
    });

    test('REQ-DAT-003.1 stores a document of exactly the size limit', () async {
      final success = _success(1, _t1, nameLine: 'A' * _limitNameLength());

      expect(await ElementCache(temp).write(success), isTrue);

      final bytes = await _cacheFile(temp, 1).readAsBytes();
      expect(bytes, _documentBytes(success));
      expect(bytes.length, _sizeLimitBytes);
      final entry = await ElementCache(temp).read(_object(1));
      expect(entry?.nameLine, success.nameLine);
    });

    test('REQ-DAT-003.1 replaces a leftover temporary file', () async {
      await _tempFile(temp, 1).writeAsString('stale');

      expect(await ElementCache(temp).write(_success(1, _t1)), isTrue);

      expect(await _names(temp), [_cacheFileName(1)]);
      expect(
        await _cacheFile(temp, 1).readAsBytes(),
        _documentBytes(_success(1, _t1)),
      );
    });
  });

  // REQ-DAT-003.2
  group('REQ-DAT-003.2 write failures', () {
    test('REQ-DAT-003.2 fails when the cache directory is a file', () async {
      final blocker = File('${temp.path}/blocker');
      await blocker.writeAsString('not a directory');

      final cache = ElementCache(Directory(blocker.path));

      expect(await cache.write(_success(1, _t1)), isFalse);
    });

    test(
      'REQ-DAT-003.2 fails when the temporary file cannot be written',
      () async {
        final cache = ElementCache(temp);
        expect(await cache.write(_success(1, _t1)), isTrue);
        final before = await _cacheFile(temp, 1).readAsBytes();
        await Directory(_tempFile(temp, 1).path).create();

        expect(await cache.write(_success(1, _t2)), isFalse);

        expect(await _cacheFile(temp, 1).readAsBytes(), before);
        final entry = await ElementCache(temp).read(_object(1));
        expect(entry?.arrivedAtUtc, _t1);
      },
    );

    test(
      'REQ-DAT-003.2 fails when the cache file cannot be replaced',
      () async {
        await Directory(_cacheFile(temp, 1).path).create();

        expect(await ElementCache(temp).write(_success(1, _t1)), isFalse);
      },
    );

    final invalid = _invalidSuccesses();
    for (final label in invalid.keys) {
      test('REQ-DAT-003.2 refuses $label', () async {
        expect(await ElementCache(temp).write(invalid[label]!), isFalse);

        expect(await _names(temp), isEmpty);
      });
    }

    test('REQ-DAT-003.2 keeps the document after a refused write', () async {
      final cache = ElementCache(temp);
      expect(await cache.write(_success(1, _t1)), isTrue);
      final before = await _cacheFile(temp, 1).readAsBytes();

      final bad = _success(1, _t2, line2: _badChecksum(_line2(1)));
      expect(await cache.write(bad), isFalse);

      expect(await _cacheFile(temp, 1).readAsBytes(), before);
    });
  });

  // REQ-DAT-003.3
  group('REQ-DAT-003.3 read', () {
    for (var position = 1; position <= 4; position++) {
      test(
        'REQ-DAT-003.3 reads back the success of position $position',
        () async {
          final writer = ElementCache(temp);
          expect(await writer.write(_success(position, _t1)), isTrue);
          final before = await _cacheFile(temp, position).readAsBytes();

          final entry = await ElementCache(temp).read(_object(position));

          expect(entry, isNotNull);
          expect(entry!.object, _object(position));
          expect(entry.nameLine, _name(position));
          expect(entry.line1, _line1(position));
          expect(entry.line2, _line2(position));
          expect(entry.arrivedAtUtc.isUtc, isTrue);
          expect(entry.arrivedAtUtc, _t1);
          expect(await _names(temp), [_cacheFileName(position)]);
          expect(await _cacheFile(temp, position).readAsBytes(), before);
          expect(await writer.write(_success(position, _t2)), isTrue);
        },
      );
    }

    test('REQ-DAT-003.3 keeps the microseconds', () async {
      expect(await ElementCache(temp).write(_success(1, _t3)), isTrue);

      final entry = await ElementCache(temp).read(_object(1));

      expect(entry?.arrivedAtUtc, _t3);
    });

    test('REQ-DAT-003.3 ignores members it does not define', () async {
      final bytes = _encode({..._validMap(1), 'extra': true});
      await _cacheFile(temp, 1).writeAsBytes(bytes);

      final entry = await ElementCache(temp).read(_object(1));

      expect(entry?.arrivedAtUtc, _t1);
      expect(await _cacheFile(temp, 1).readAsBytes(), bytes);
    });

    test('REQ-DAT-003.3 reads a file of exactly the size limit', () async {
      final bytes = _padded(utf8.encode(_validText(1)), _sizeLimitBytes);
      await _cacheFile(temp, 1).writeAsBytes(bytes);

      final entry = await ElementCache(temp).read(_object(1));

      expect(entry?.nameLine, _name(1));
      expect(await _cacheFile(temp, 1).readAsBytes(), bytes);
    });

    test('REQ-DAT-003.3 reports no entry in an empty directory', () async {
      expect(await ElementCache(temp).read(_object(1)), isNull);

      expect(await _names(temp), isEmpty);
    });

    test('REQ-DAT-003.3 reports no entry without a directory', () async {
      final missing = Directory('${temp.path}/missing');

      expect(await ElementCache(missing).read(_object(1)), isNull);

      expect(await missing.exists(), isFalse);
    });

    test(
      'REQ-DAT-003.3 reports no entry when the directory is a file',
      () async {
        final blocker = File('${temp.path}/blocker');
        await blocker.writeAsString('not a directory');
        final before = await blocker.readAsBytes();

        final cache = ElementCache(Directory(blocker.path));

        expect(await cache.read(_object(1)), isNull);
        expect(await blocker.readAsBytes(), before);
      },
    );

    test('REQ-DAT-003.3 reports no entry for another object', () async {
      expect(await ElementCache(temp).write(_success(2, _t1)), isTrue);

      expect(await ElementCache(temp).read(_object(1)), isNull);
    });

    test('REQ-DAT-003.3 reports no entry after the file is deleted', () async {
      final cache = ElementCache(temp);
      expect(await cache.write(_success(1, _t1)), isTrue);
      await _cacheFile(temp, 1).delete();

      expect(await cache.read(_object(1)), isNull);
    });

    test(
      'REQ-DAT-003.3 reports no entry after the directory is deleted',
      () async {
        final directory = Directory('${temp.path}/cache');
        final cache = ElementCache(directory);
        expect(await cache.write(_success(1, _t1)), isTrue);
        await directory.delete(recursive: true);

        expect(await cache.read(_object(1)), isNull);
      },
    );

    test('REQ-DAT-003.3 recovers after the directory is deleted', () async {
      final directory = Directory('${temp.path}/cache');
      final cache = ElementCache(directory);
      expect(await cache.write(_success(1, _t1)), isTrue);
      await directory.delete(recursive: true);

      expect(await cache.write(_success(1, _t2)), isTrue);

      expect((await cache.read(_object(1)))?.arrivedAtUtc, _t2);
    });
  });

  // REQ-DAT-003.4
  group('REQ-DAT-003.4 invalid documents', () {
    final invalid = _invalidDocuments();
    for (final label in invalid.keys) {
      test('REQ-DAT-003.4 reads $label as no entry', () async {
        final bytes = invalid[label]!;
        await _cacheFile(temp, 1).writeAsBytes(bytes);

        expect(await ElementCache(temp).read(_object(1)), isNull);

        expect(await _cacheFile(temp, 1).readAsBytes(), bytes);
      });
    }

    test(
      'REQ-DAT-003.4 reads a directory at the cache path as no entry',
      () async {
        await Directory(_cacheFile(temp, 1).path).create();

        expect(await ElementCache(temp).read(_object(1)), isNull);
      },
    );
  });
}
