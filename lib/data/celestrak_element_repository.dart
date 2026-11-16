import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/data/celestrak_gp_client.dart';
import 'package:wintek/data/element_cache.dart';
import 'package:wintek/domain/element_repository.dart';
import 'package:wintek/domain/satellite_catalog.dart';

const Duration _refreshThreshold = Duration(hours: 6);

ServedElements _served(
  TrackedObject object,
  String line1,
  String line2,
  DateTime arrivedAtUtc,
) => ServedElements(
  object: object,
  elements: OrbitalElements.fromTle(line1, line2),
  arrivedAtUtc: arrivedAtUtc.toUtc(),
);

/// The element repository of Wintek: serves the last good element set of each tracked object and refreshes it from CelesTrak only when it is due (specs/req-dat-004.md).
///
/// Due: no element set, an arrival instant 6 hours old or older, or one in the future; never within 6 hours of the last attempt for that object.
/// Attempts are kept in memory only, never on disk (Constitution principles 10 and 11, ADR-0007); nothing here schedules, retries or polls.
/// A refresh sends one request at a time, in catalog order, and a refresh asked for while one runs joins it, so no object is ever written twice at once.
/// A lookup never reaches the network: it serves memory first, then the cache, so a cold start needs no network (Constitution principle 9).
/// Every success is written to the cache and served from memory even if the write fails; a failure keeps the element set already served.
/// A lookup keeps what it read from the cache only if memory still holds nothing for that object, so it never replaces a newer element set.
final class CelestrakElementRepository implements ElementRepository {
  CelestrakElementRepository(
    this._gpClient,
    this._cache, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final CelestrakGpClient _gpClient;
  final ElementCache _cache;
  final DateTime Function() _clock;
  final Map<TrackedObject, ServedElements> _servedByObject = {};
  final Map<TrackedObject, DateTime> _attempts = {};
  Future<Map<TrackedObject, RefreshOutcome>>? _running;

  @override
  Future<ServedElements?> lookup(TrackedObject object) async {
    final held = _servedByObject[object];
    if (held != null) return held;
    final entry = await _cache.read(object);
    final current = _servedByObject[object];
    if (current != null) return current;
    if (entry == null) return null;
    return _servedByObject[object] = _served(
      object,
      entry.line1,
      entry.line2,
      entry.arrivedAtUtc,
    );
  }

  @override
  Future<Map<TrackedObject, RefreshOutcome>> refresh() {
    final running = _running;
    if (running != null) return running;
    final started = _refreshAll();
    _running = started;
    started.whenComplete(() => _running = null).ignore();
    return started;
  }

  Future<Map<TrackedObject, RefreshOutcome>> _refreshAll() async {
    final outcomes = <TrackedObject, RefreshOutcome>{};
    for (final object in TrackedObject.values) {
      outcomes[object] = await _refreshOne(object);
    }
    return Map.unmodifiable(outcomes);
  }

  Future<RefreshOutcome> _refreshOne(TrackedObject object) async {
    final served = await lookup(object);
    final now = _clock();
    if (!_isDue(object, served, now)) return RefreshOutcome.notDue;
    _attempts[object] = now;
    final result = await _gpClient.fetch(object);
    if (result is! GpFetchSuccess) return RefreshOutcome.failed;
    await _cache.write(result);
    _servedByObject[object] = _served(
      object,
      result.line1,
      result.line2,
      result.arrivedAtUtc,
    );
    return RefreshOutcome.refreshed;
  }

  bool _isDue(TrackedObject object, ServedElements? served, DateTime now) {
    final attempt = _attempts[object];
    if (attempt != null &&
        !now.isBefore(attempt) &&
        now.isBefore(attempt.add(_refreshThreshold))) {
      return false;
    }
    if (served == null) return true;
    final age = now.difference(served.arrivedAtUtc);
    return age.isNegative || age >= _refreshThreshold;
  }
}
