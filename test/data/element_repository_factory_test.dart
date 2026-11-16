// Unit tests of the opener of specs/req-dat-004.md (requirement 6).
//
// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test reaches CelesTrak or a platform directory, and every test writes only inside a temporary directory it creates and deletes (Constitution principles 10 and 11).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart'
    show BaseClient, BaseRequest, Response, StreamedResponse;
import 'package:http/testing.dart';
import 'package:wintek/data/element_cache.dart';
import 'package:wintek/data/element_repository_factory.dart';
import 'package:wintek/domain/element_repository.dart';
import 'package:wintek/domain/satellite_catalog.dart';

import '../domain/celestrak_tle_snapshot.dart';

extension _InstantMath on DateTime {
  DateTime operator +(Duration duration) => add(duration);
}

final DateTime _n0 = DateTime.utc(2026, 1, 15, 12);

String _name(int position) => celestrakTleSnapshot[(position - 1) * 3];
String _line1(int position) => celestrakTleSnapshot[(position - 1) * 3 + 1];
String _line2(int position) => celestrakTleSnapshot[(position - 1) * 3 + 2];

/// Sends every request to a mock client that answers with the success
/// response of its object, and counts its calls of `close`.
final class _RecordingClient extends BaseClient {
  _RecordingClient(this.requests);

  final List<int> requests;
  int closes = 0;

  late final MockClient _mock = MockClient((request) async {
    final id = int.parse(request.url.queryParameters['CATNR']!);
    requests.add(id);
    final position =
        TrackedObject.values.indexWhere((o) => o.noradId == id) + 1;
    return Response(
      '${_name(position)}\n${_line1(position)}\n${_line2(position)}\n',
      200,
    );
  });

  @override
  Future<StreamedResponse> send(BaseRequest request) => _mock.send(request);

  @override
  void close() {
    closes++;
  }
}

final class _Setup {
  _Setup(this.directory);

  final Directory directory;
  final List<int> requests = [];
  int resolverCalls = 0;
  int creatorCalls = 0;
  DateTime now = _n0;
  late final _RecordingClient client = _RecordingClient(requests);

  Future<Directory> resolve() async {
    resolverCalls++;
    return directory;
  }

  _RecordingClient create() {
    creatorCalls++;
    return client;
  }

  Future<ElementRepositoryHandle> open() => ElementRepositoryHandle.open(
    resolveDirectory: resolve,
    createClient: create,
    clock: () => now,
  );
}

Future<_Setup> _setup() async {
  final directory = await Directory.systemTemp.createTemp('wintek_factory_');
  addTearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });
  return _Setup(directory);
}

const Map<TrackedObject, RefreshOutcome> _allRefreshed = {
  TrackedObject.iss: RefreshOutcome.refreshed,
  TrackedObject.tiangong: RefreshOutcome.refreshed,
  TrackedObject.fasatCharlie: RefreshOutcome.refreshed,
  TrackedObject.goesEast: RefreshOutcome.refreshed,
};

const Map<TrackedObject, RefreshOutcome> _allNotDue = {
  TrackedObject.iss: RefreshOutcome.notDue,
  TrackedObject.tiangong: RefreshOutcome.notDue,
  TrackedObject.fasatCharlie: RefreshOutcome.notDue,
  TrackedObject.goesEast: RefreshOutcome.notDue,
};

void main() {
  // REQ-DAT-004.6
  test('REQ-DAT-004.6 opening sends and writes nothing', () async {
    final s = await _setup();

    await s.open();
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(s.resolverCalls, 1);
    expect(s.creatorCalls, 1);
    expect(s.requests, isEmpty);
    expect(await s.directory.list().toList(), isEmpty);
  });

  // REQ-DAT-004.6
  test('REQ-DAT-004.6 the cache is on the resolved directory itself', () async {
    final s = await _setup();
    final handle = await s.open();

    expect(await handle.repository.refresh(), _allRefreshed);

    final names = [
      await for (final entity in s.directory.list())
        entity.path.substring(s.directory.path.length + 1),
    ]..sort();
    expect(
      names,
      [for (final object in TrackedObject.values) 'gp_${object.noradId}.json']
        ..sort(),
    );
    final cache = ElementCache(s.directory);
    for (final object in TrackedObject.values) {
      final entry = await cache.read(object);
      expect(entry!.arrivedAtUtc, _n0);
    }
  });

  // REQ-DAT-004.6
  test(
    'REQ-DAT-004.6 the repository reads the clock that was passed',
    () async {
      final s = await _setup();
      final handle = await s.open();
      expect(await handle.repository.refresh(), _allRefreshed);
      final sent = s.requests.length;

      s.now = _n0 + const Duration(hours: 1);
      expect(await handle.repository.refresh(), _allNotDue);
      expect(s.requests.length, sent);

      s.now = _n0 + const Duration(hours: 7);
      expect(await handle.repository.refresh(), _allRefreshed);
    },
  );

  // REQ-DAT-004.6
  test(
    'REQ-DAT-004.6 the directory is resolved before the client is created',
    () async {
      final s = await _setup();
      final error = StateError('no directory');

      await expectLater(
        ElementRepositoryHandle.open(
          resolveDirectory: () async => throw error,
          createClient: s.create,
          clock: () => s.now,
        ),
        throwsA(same(error)),
      );

      expect(s.creatorCalls, 0);
    },
  );

  // REQ-DAT-004.6
  test('REQ-DAT-004.6 the handle closes its client exactly once', () async {
    final s = await _setup();
    final handle = await s.open();
    expect(s.client.closes, 0);

    handle.close();
    expect(s.client.closes, 1);

    handle.close();
    expect(s.client.closes, 1);
  });
}
