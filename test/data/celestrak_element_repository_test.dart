// Unit tests of the element repository of specs/req-dat-004.md (requirements 1 to 5).
//
// Payloads rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test reaches CelesTrak or a platform directory, and every test writes only inside a temporary directory it creates and deletes (Constitution principles 10 and 11).

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException, Response;
import 'package:http/testing.dart';
import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/data/celestrak_element_repository.dart';
import 'package:wintek/data/celestrak_gp_client.dart';
import 'package:wintek/data/element_cache.dart';
import 'package:wintek/domain/element_repository.dart';
import 'package:wintek/domain/satellite_catalog.dart';

import '../domain/celestrak_tle_snapshot.dart';

extension _InstantMath on DateTime {
  DateTime operator +(Duration duration) => add(duration);
  DateTime operator -(Duration duration) => subtract(duration);
}

final DateTime _n0 = DateTime.utc(2026, 1, 15, 12);
const Duration _h = Duration(hours: 6);
const Duration _microsecond = Duration(microseconds: 1);
const Duration _oneSecond = Duration(seconds: 1);

/// The tracked object at [position], from 1 to 4, is [TrackedObject.values] in
/// order, which is also the order of the snapshot.
TrackedObject _object(int position) => TrackedObject.values[position - 1];
String _name(int position) => celestrakTleSnapshot[(position - 1) * 3];
String _line1(int position) => celestrakTleSnapshot[(position - 1) * 3 + 1];
String _line2(int position) => celestrakTleSnapshot[(position - 1) * 3 + 2];

List<int> _ids([List<int> positions = const [1, 2, 3, 4]]) => [
  for (final position in positions) _object(position).noradId,
];

OrbitalElements _elements(int position) =>
    OrbitalElements.fromTle(_line1(position), _line2(position));

GpFetchSuccess _success(int position, DateTime at) => GpFetchSuccess(
  _object(position),
  nameLine: _name(position),
  line1: _line1(position),
  line2: _line2(position),
  arrivedAtUtc: at,
);

Response _successResponse(TrackedObject object) {
  final position = object.index + 1;
  return Response(
    '${_name(position)}\n${_line1(position)}\n${_line2(position)}\n',
    200,
  );
}

typedef _Answer = Future<Response> Function(TrackedObject object);

Future<Response> _everyoneSucceeds(TrackedObject object) async =>
    _successResponse(object);

_Answer _status(int code, [String body = '']) =>
    (object) async => Response(body, code);

Future<Response> _throwsClientException(TrackedObject object) async =>
    throw ClientException('no network');

/// A mock client that records the `CATNR` of every request, in order.
final class _Network {
  final List<int> requests = [];
  final Map<TrackedObject, _Answer> overrides = {};
  _Answer everyone = _everyoneSucceeds;
  Completer<void>? gate;

  late final MockClient client = MockClient((request) async {
    final id = int.parse(request.url.queryParameters['CATNR']!);
    final object = TrackedObject.values.firstWhere((o) => o.noradId == id);
    requests.add(id);
    final held = gate;
    if (held != null) await held.future;
    return (overrides[object] ?? everyone)(object);
  });
}

final class _Fixture {
  _Fixture(
    this.directory, {
    Directory? cacheDirectory,
    this.timeout = const Duration(seconds: 20),
  }) : _cacheDirectory = cacheDirectory ?? directory;

  final Directory directory;
  final Directory _cacheDirectory;
  final Duration timeout;
  final _Network network = _Network();
  DateTime now = _n0;

  late final ElementCache cache = ElementCache(_cacheDirectory);
  late final CelestrakGpClient gpClient = CelestrakGpClient(
    network.client,
    timeout: timeout,
    clock: () => now,
  );
  late final CelestrakElementRepository repository = CelestrakElementRepository(
    gpClient,
    cache,
    clock: () => now,
  );

  /// A second repository on the same mock client and directory, with new
  /// memory.
  CelestrakElementRepository newRepository() => CelestrakElementRepository(
    CelestrakGpClient(network.client, clock: () => now),
    ElementCache(directory),
    clock: () => now,
  );

  /// Cached at instant [at]: written by a cache before the repository is used.
  Future<void> cachedAt(int position, DateTime at) async {
    expect(await cache.write(_success(position, at)), isTrue);
  }

  /// Refreshes with the clock at [at], and checks that every object has an
  /// outcome.
  Future<Map<TrackedObject, RefreshOutcome>> refreshAt(
    DateTime at, [
    CelestrakElementRepository? other,
  ]) async {
    now = at;
    final outcomes = await (other ?? repository).refresh();
    expect(outcomes.keys.toSet(), TrackedObject.values.toSet());
    return outcomes;
  }
}

Future<_Fixture> _fixture({
  Duration timeout = const Duration(seconds: 20),
  bool cacheIsAFile = false,
}) async {
  final directory = await Directory.systemTemp.createTemp('wintek_repository_');
  addTearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });
  if (!cacheIsAFile) return _Fixture(directory, timeout: timeout);
  final blocker = File('${directory.path}/blocker');
  await blocker.writeAsString('not a directory');
  return _Fixture(directory, cacheDirectory: Directory(blocker.path));
}

Map<TrackedObject, RefreshOutcome> _all(RefreshOutcome outcome) => {
  for (final object in TrackedObject.values) object: outcome,
};

Map<TrackedObject, RefreshOutcome> _outcomes(
  Map<int, RefreshOutcome> byPosition,
) => {for (final entry in byPosition.entries) _object(entry.key): entry.value};

File _cacheFile(Directory directory, int position) =>
    File('${directory.path}/gp_${_object(position).noradId}.json');

Future<List<String>> _names(Directory directory) async {
  final names = [
    await for (final entity in directory.list())
      entity.path.substring(directory.path.length + 1),
  ];
  names.sort();
  return names;
}

List<String> _cacheNames(List<int> positions) =>
    [for (final p in positions) 'gp_${_object(p).noradId}.json']..sort();

Future<void> _letEventLoopRun(int times) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  for (var position = 1; position <= 4; position++) {
    // REQ-DAT-004.1
    test(
      'REQ-DAT-004.1 a cold start serves the cache of position $position',
      () async {
        final f = await _fixture();
        await f.cachedAt(position, _n0 - const Duration(hours: 1));

        final served = await f.repository.lookup(_object(position));

        expect(served, isNotNull);
        expect(served!.object, _object(position));
        expect(served.elements, _elements(position));
        expect(served.arrivedAtUtc.isUtc, isTrue);
        expect(served.arrivedAtUtc, _n0 - const Duration(hours: 1));
        expect(f.network.requests, isEmpty);
      },
    );
  }

  // REQ-DAT-004.1
  test(
    'REQ-DAT-004.1 a lookup with no element set completes with null',
    () async {
      final f = await _fixture();

      expect(await f.repository.lookup(TrackedObject.iss), isNull);

      expect(f.network.requests, isEmpty);
      expect(await _names(f.directory), isEmpty);
    },
  );

  // REQ-DAT-004.1
  test('REQ-DAT-004.1 an element set is kept in memory', () async {
    final f = await _fixture();
    final outcomes = await f.refreshAt(_n0);
    expect(outcomes[TrackedObject.iss], RefreshOutcome.refreshed);

    await f.directory.delete(recursive: true);
    final served = await f.repository.lookup(TrackedObject.iss);

    expect(served, isNotNull);
    expect(served!.arrivedAtUtc, _n0);
  });

  // REQ-DAT-004.1
  test('REQ-DAT-004.1 a refresh replaces what a lookup serves', () async {
    final f = await _fixture();
    await f.cachedAt(1, _n0 - const Duration(hours: 7));

    final before = await f.repository.lookup(TrackedObject.iss);
    expect(before!.arrivedAtUtc, _n0 - const Duration(hours: 7));
    final outcomes = await f.refreshAt(_n0);
    expect(outcomes[TrackedObject.iss], RefreshOutcome.refreshed);
    final after = await f.repository.lookup(TrackedObject.iss);

    expect(after!.arrivedAtUtc, _n0);
  });

  // REQ-DAT-004.1
  test('REQ-DAT-004.1 a lookup does not decide to fetch', () async {
    final f = await _fixture();
    await f.cachedAt(1, _n0 - const Duration(hours: 7));

    for (var i = 0; i < 10; i++) {
      final served = await f.repository.lookup(TrackedObject.iss);
      expect(served!.arrivedAtUtc, _n0 - const Duration(hours: 7));
    }

    expect(f.network.requests, isEmpty);
  });

  // REQ-DAT-004.2
  test('REQ-DAT-004.2 the outcome type has exactly three values', () {
    expect(RefreshOutcome.values, hasLength(3));
  });

  // REQ-DAT-004.2
  test(
    'REQ-DAT-004.2 every refresh has a key for every tracked object',
    () async {
      final f = await _fixture();

      final outcomes = await f.refreshAt(_n0);

      expect(outcomes.keys.toList(), TrackedObject.values);
    },
  );

  // REQ-DAT-004.2
  test(
    'REQ-DAT-004.2 an element set younger than the threshold is not due',
    () async {
      final f = await _fixture();
      for (var position = 1; position <= 4; position++) {
        await f.cachedAt(position, _n0 - (_h - _microsecond));
      }

      final outcomes = await f.refreshAt(_n0);

      expect(outcomes, _all(RefreshOutcome.notDue));
      expect(f.network.requests, isEmpty);
    },
  );

  // REQ-DAT-004.2
  test(
    'REQ-DAT-004.2 an element set exactly at the threshold is due',
    () async {
      final f = await _fixture();
      for (var position = 1; position <= 4; position++) {
        await f.cachedAt(position, _n0 - _h);
      }

      final outcomes = await f.refreshAt(_n0);

      expect(outcomes, _all(RefreshOutcome.refreshed));
      expect(f.network.requests, _ids());
      final second = ElementCache(f.directory);
      for (final object in TrackedObject.values) {
        final entry = await second.read(object);
        expect(entry!.arrivedAtUtc, _n0);
      }
    },
  );

  // REQ-DAT-004.2
  test('REQ-DAT-004.2 an object with no element set is due', () async {
    final f = await _fixture();

    final outcomes = await f.refreshAt(_n0);

    expect(outcomes, _all(RefreshOutcome.refreshed));
    expect(f.network.requests, _ids());
    expect(await _names(f.directory), _cacheNames([1, 2, 3, 4]));
  });

  // REQ-DAT-004.2
  test('REQ-DAT-004.2 a refresh requests only what is due', () async {
    final f = await _fixture();
    await f.cachedAt(1, _n0 - const Duration(hours: 1));

    final outcomes = await f.refreshAt(_n0);

    expect(
      outcomes,
      _outcomes({
        1: RefreshOutcome.notDue,
        2: RefreshOutcome.refreshed,
        3: RefreshOutcome.refreshed,
        4: RefreshOutcome.refreshed,
      }),
    );
    expect(f.network.requests, _ids([2, 3, 4]));
  });

  // REQ-DAT-004.2
  test('REQ-DAT-004.2 an arrival instant in the future is due', () async {
    final f = await _fixture();
    await f.cachedAt(1, _n0 + const Duration(minutes: 1));
    for (var position = 2; position <= 4; position++) {
      await f.cachedAt(position, _n0 - const Duration(hours: 1));
    }

    final outcomes = await f.refreshAt(_n0);

    expect(
      outcomes,
      _outcomes({
        1: RefreshOutcome.refreshed,
        2: RefreshOutcome.notDue,
        3: RefreshOutcome.notDue,
        4: RefreshOutcome.notDue,
      }),
    );
    expect(f.network.requests, _ids([1]));
    final served = await f.repository.lookup(TrackedObject.iss);
    expect(served!.arrivedAtUtc, _n0);
  });

  // REQ-DAT-004.2
  test('REQ-DAT-004.2 an object that is not due opens no window', () async {
    final f = await _fixture();
    for (var position = 1; position <= 4; position++) {
      await f.cachedAt(position, _n0 - const Duration(hours: 1));
    }

    expect(await f.refreshAt(_n0), _all(RefreshOutcome.notDue));
    final later = await f.refreshAt(_n0 + const Duration(hours: 5));

    expect(later, _all(RefreshOutcome.refreshed));
  });

  // REQ-DAT-004.3
  test('REQ-DAT-004.3 a failure keeps what memory serves', () async {
    final f = await _fixture();
    expect(await f.refreshAt(_n0), _all(RefreshOutcome.refreshed));
    await f.directory.delete(recursive: true);
    f.network.overrides[TrackedObject.iss] = _status(500);

    final outcomes = await f.refreshAt(_n0 + _h);

    expect(
      outcomes,
      _outcomes({
        1: RefreshOutcome.failed,
        2: RefreshOutcome.refreshed,
        3: RefreshOutcome.refreshed,
        4: RefreshOutcome.refreshed,
      }),
    );
    final served = await f.repository.lookup(TrackedObject.iss);
    expect(served!.elements, _elements(1));
    expect(served.arrivedAtUtc, _n0);
    expect(await _names(f.directory), _cacheNames([2, 3, 4]));
  });

  final failures = <String, _Answer>{
    'status 500': _status(500),
    'status 403': _status(403),
    'no GP data': _status(200, 'No GP data found'),
    'not a TLE': _status(200, 'not a TLE'),
    'a client exception': _throwsClientException,
  };
  for (final failure in failures.entries) {
    // REQ-DAT-004.3
    test('REQ-DAT-004.3 ${failure.key} is failed', () async {
      final f = await _fixture();
      await f.cachedAt(1, _n0 - const Duration(hours: 7));
      for (var position = 2; position <= 4; position++) {
        await f.cachedAt(position, _n0 - const Duration(hours: 1));
      }
      final before = await _cacheFile(f.directory, 1).readAsBytes();
      f.network.overrides[TrackedObject.iss] = failure.value;

      final outcomes = await f.refreshAt(_n0);

      expect(
        outcomes,
        _outcomes({
          1: RefreshOutcome.failed,
          2: RefreshOutcome.notDue,
          3: RefreshOutcome.notDue,
          4: RefreshOutcome.notDue,
        }),
      );
      expect(f.network.requests, _ids([1]));
      final served = await f.repository.lookup(TrackedObject.iss);
      expect(served!.arrivedAtUtc, _n0 - const Duration(hours: 7));
      expect(await _cacheFile(f.directory, 1).readAsBytes(), before);
    });
  }

  // REQ-DAT-004.3
  test('REQ-DAT-004.3 a timeout is failed', () async {
    final f = await _fixture(timeout: const Duration(milliseconds: 10));
    await f.cachedAt(1, _n0 - const Duration(hours: 7));
    for (var position = 2; position <= 4; position++) {
      await f.cachedAt(position, _n0 - const Duration(hours: 1));
    }
    final before = await _cacheFile(f.directory, 1).readAsBytes();
    f.network.overrides[TrackedObject.iss] = (object) =>
        Completer<Response>().future;

    final outcomes = await f.refreshAt(_n0);

    expect(
      outcomes,
      _outcomes({
        1: RefreshOutcome.failed,
        2: RefreshOutcome.notDue,
        3: RefreshOutcome.notDue,
        4: RefreshOutcome.notDue,
      }),
    );
    expect(f.network.requests, _ids([1]));
    final served = await f.repository.lookup(TrackedObject.iss);
    expect(served!.arrivedAtUtc, _n0 - const Duration(hours: 7));
    expect(await _cacheFile(f.directory, 1).readAsBytes(), before);
  });

  // REQ-DAT-004.3
  test('REQ-DAT-004.3 a failure without a cache serves nothing', () async {
    final f = await _fixture();
    f.network.overrides[TrackedObject.iss] = _status(500);

    final outcomes = await f.refreshAt(_n0);

    expect(
      outcomes,
      _outcomes({
        1: RefreshOutcome.failed,
        2: RefreshOutcome.refreshed,
        3: RefreshOutcome.refreshed,
        4: RefreshOutcome.refreshed,
      }),
    );
    expect(await f.repository.lookup(TrackedObject.iss), isNull);
  });

  // REQ-DAT-004.3
  test(
    'REQ-DAT-004.3 the window of a failure closes at the threshold',
    () async {
      final f = await _fixture();
      f.network.overrides[TrackedObject.iss] = _status(500);
      expect(
        (await f.refreshAt(_n0))[TrackedObject.iss],
        RefreshOutcome.failed,
      );
      f.network.overrides.clear();
      final sent = f.network.requests.length;

      final early = await f.refreshAt(_n0 + _h - _microsecond);
      expect(early[TrackedObject.iss], RefreshOutcome.notDue);
      expect(f.network.requests.length, sent);

      final due = await f.refreshAt(_n0 + _h);
      expect(due, _all(RefreshOutcome.refreshed));
      expect(f.network.requests.skip(sent), _ids());
    },
  );

  // REQ-DAT-004.3
  test('REQ-DAT-004.3 every object has its own window', () async {
    final f = await _fixture();
    await f.cachedAt(1, _n0 - const Duration(hours: 7));
    await f.cachedAt(2, _n0 - const Duration(hours: 5));
    await f.cachedAt(3, _n0);
    await f.cachedAt(4, _n0);
    f.network.overrides[TrackedObject.iss] = _status(500);

    expect(
      await f.refreshAt(_n0),
      _outcomes({
        1: RefreshOutcome.failed,
        2: RefreshOutcome.notDue,
        3: RefreshOutcome.notDue,
        4: RefreshOutcome.notDue,
      }),
    );
    final sent = f.network.requests.length;
    final later = await f.refreshAt(_n0 + const Duration(hours: 1));

    expect(
      later,
      _outcomes({
        1: RefreshOutcome.notDue,
        2: RefreshOutcome.refreshed,
        3: RefreshOutcome.notDue,
        4: RefreshOutcome.notDue,
      }),
    );
    expect(f.network.requests.skip(sent), _ids([2]));
  });

  // REQ-DAT-004.3
  test(
    'REQ-DAT-004.3 the window of a success closes at the threshold',
    () async {
      final f = await _fixture();
      expect(await f.refreshAt(_n0), _all(RefreshOutcome.refreshed));
      final sent = f.network.requests.length;

      expect(
        await f.refreshAt(_n0 + _h - _microsecond),
        _all(RefreshOutcome.notDue),
      );
      expect(f.network.requests.length, sent);
      expect(await f.refreshAt(_n0 + _h), _all(RefreshOutcome.refreshed));
    },
  );

  // REQ-DAT-004.3
  test(
    'REQ-DAT-004.3 the window of a success holds when the clock moves back',
    () async {
      final f = await _fixture();
      await f.cachedAt(1, _n0 - const Duration(hours: 7));
      for (var position = 2; position <= 4; position++) {
        await f.cachedAt(position, _n0 - const Duration(hours: 1));
      }
      var moved = false;
      f.network.overrides[TrackedObject.iss] = (object) async {
        if (!moved) {
          moved = true;
          f.now = _n0 - const Duration(hours: 1);
        }
        return _successResponse(object);
      };

      expect(
        await f.refreshAt(_n0),
        _outcomes({
          1: RefreshOutcome.refreshed,
          2: RefreshOutcome.notDue,
          3: RefreshOutcome.notDue,
          4: RefreshOutcome.notDue,
        }),
      );
      final sent = f.network.requests.length;

      final inside = await f.refreshAt(
        _n0 + const Duration(hours: 5, minutes: 1),
      );
      expect(
        inside,
        _outcomes({
          1: RefreshOutcome.notDue,
          2: RefreshOutcome.refreshed,
          3: RefreshOutcome.refreshed,
          4: RefreshOutcome.refreshed,
        }),
      );
      expect(f.network.requests.skip(sent), _ids([2, 3, 4]));
      final sentInside = f.network.requests.length;

      final closed = await f.refreshAt(_n0 + _h);
      expect(
        closed,
        _outcomes({
          1: RefreshOutcome.refreshed,
          2: RefreshOutcome.notDue,
          3: RefreshOutcome.notDue,
          4: RefreshOutcome.notDue,
        }),
      );
      expect(f.network.requests.skip(sentInside), _ids([1]));
    },
  );

  // REQ-DAT-004.3
  test('REQ-DAT-004.3 the window is kept in memory only', () async {
    final f = await _fixture();
    f.network.overrides[TrackedObject.iss] = _status(500);
    expect((await f.refreshAt(_n0))[TrackedObject.iss], RefreshOutcome.failed);
    expect(await _names(f.directory), _cacheNames([2, 3, 4]));
    final sent = f.network.requests.length;

    final second = f.newRepository();
    final outcomes = await f.refreshAt(
      _n0 + const Duration(minutes: 1),
      second,
    );

    expect(outcomes[TrackedObject.iss], RefreshOutcome.failed);
    expect(f.network.requests.skip(sent), _ids([1]));
  });

  // REQ-DAT-004.3
  test('REQ-DAT-004.3 a success whose write fails is still served', () async {
    final f = await _fixture(cacheIsAFile: true);
    final blocker = File('${f.directory.path}/blocker');
    final before = await blocker.readAsBytes();

    expect(await f.refreshAt(_n0), _all(RefreshOutcome.refreshed));

    final served = await f.repository.lookup(TrackedObject.iss);
    expect(served!.elements, _elements(1));
    expect(served.arrivedAtUtc, _n0);
    expect(await blocker.readAsBytes(), before);
    expect(
      await f.refreshAt(_n0 + const Duration(hours: 1)),
      _all(RefreshOutcome.notDue),
    );
  });

  // REQ-DAT-004.4
  test(
    'REQ-DAT-004.4 a refresh sends one request at a time, in catalog order',
    () async {
      final f = await _fixture();
      for (var position = 1; position <= 4; position++) {
        await f.cachedAt(position, _n0 - const Duration(hours: 7));
        await f.repository.lookup(_object(position));
      }
      var inFlight = 0;
      var mostInFlight = 0;
      f.network.everyone = (object) async {
        inFlight++;
        if (inFlight > mostInFlight) mostInFlight = inFlight;
        await Future<void>.delayed(Duration.zero);
        inFlight--;
        return _successResponse(object);
      };

      expect(await f.refreshAt(_n0), _all(RefreshOutcome.refreshed));

      expect(f.network.requests, _ids());
      expect(mostInFlight, 1);
    },
  );

  // REQ-DAT-004.4
  test('REQ-DAT-004.4 a failure does not stop the refresh', () async {
    final f = await _fixture();
    f.network.overrides[TrackedObject.iss] = _throwsClientException;

    final outcomes = await f.refreshAt(_n0);

    expect(
      outcomes,
      _outcomes({
        1: RefreshOutcome.failed,
        2: RefreshOutcome.refreshed,
        3: RefreshOutcome.refreshed,
        4: RefreshOutcome.refreshed,
      }),
    );
    expect(f.network.requests, _ids());
  });

  // REQ-DAT-004.4
  test('REQ-DAT-004.4 a refresh asked for during a refresh joins it', () async {
    final f = await _fixture();
    f.now = _n0;
    final gate = Completer<void>();
    f.network.gate = gate;

    final first = f.repository.refresh();
    await _letEventLoopRun(1);
    final second = f.repository.refresh();
    gate.complete();
    final firstOutcomes = await first;
    final secondOutcomes = await second;

    expect(firstOutcomes, _all(RefreshOutcome.refreshed));
    expect(secondOutcomes, _all(RefreshOutcome.refreshed));
    expect(secondOutcomes, firstOutcomes);
    expect(f.network.requests, _ids());
    for (final outcomes in [firstOutcomes, secondOutcomes]) {
      expect(
        () => outcomes[TrackedObject.iss] = RefreshOutcome.failed,
        throwsUnsupportedError,
      );
      expect(outcomes[TrackedObject.iss], RefreshOutcome.refreshed);
    }
    expect(await f.refreshAt(_n0), _all(RefreshOutcome.notDue));
    expect(f.network.requests, _ids());
  });

  // REQ-DAT-004.4
  test('REQ-DAT-004.4 nothing happens unless a refresh is asked for', () async {
    final f = await _fixture();
    f.network.overrides[TrackedObject.iss] = _status(500);
    await f.refreshAt(_n0);
    final sent = f.network.requests.length;

    f.now = _n0 + const Duration(hours: 7);
    await _letEventLoopRun(10);
    await Future<void>.delayed(_oneSecond);
    expect(f.network.requests.length, sent);

    await f.refreshAt(_n0 + const Duration(hours: 7));
    expect(f.network.requests.skip(sent), contains(_object(1).noradId));
  });

  // REQ-DAT-004.4
  test(
    'REQ-DAT-004.4 a refresh that ends with an error does not block the next',
    () async {
      final f = await _fixture();
      f.now = _n0;
      final gate = Completer<void>();
      f.network.gate = gate;
      var thrown = false;
      f.network.overrides[TrackedObject.iss] = (object) async {
        if (!thrown) {
          thrown = true;
          throw StateError('a programming error');
        }
        return _successResponse(object);
      };

      final first = f.repository.refresh();
      final firstCheck = expectLater(first, throwsStateError);
      await _letEventLoopRun(1);
      final second = f.repository.refresh();
      final secondCheck = expectLater(second, throwsStateError);
      gate.complete();
      await firstCheck;
      await secondCheck;
      final sent = f.network.requests.length;

      final third = await f.refreshAt(_n0);

      expect(
        third,
        _outcomes({
          1: RefreshOutcome.notDue,
          2: RefreshOutcome.refreshed,
          3: RefreshOutcome.refreshed,
          4: RefreshOutcome.refreshed,
        }),
      );
      expect(f.network.requests.skip(sent), _ids([2, 3, 4]));
    },
  );

  // REQ-DAT-004.5
  test(
    'REQ-DAT-004.5 the data age is the time since the arrival instant',
    () async {
      final f = await _fixture();
      await f.cachedAt(1, _n0 - const Duration(hours: 3));

      final served = await f.repository.lookup(TrackedObject.iss);

      expect(served, isNotNull);
      expect(served!.ageAt(_n0), const Duration(hours: 3));
      expect(served.ageAt(_n0 - const Duration(hours: 3)), Duration.zero);
      expect(served.ageAt(_n0 - const Duration(hours: 4)), isNull);
      expect(
        served.ageAt(_n0 - const Duration(hours: 3) - _microsecond),
        isNull,
      );
      expect(served.ageAt(_n0.toLocal()), const Duration(hours: 3));
    },
  );

  // REQ-DAT-004.5
  test('REQ-DAT-004.5 the data age keeps microseconds', () async {
    final f = await _fixture();
    await f.cachedAt(1, _n0 - _microsecond);

    final served = await f.repository.lookup(TrackedObject.iss);

    expect(served!.ageAt(_n0), _microsecond);
  });
}
