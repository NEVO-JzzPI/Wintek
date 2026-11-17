import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/domain/satellite_catalog.dart';

/// The element repository contract of Wintek: the only way the rest of the app reads orbital elements (specs/req-dat-004.md).
///
/// Depends only on orbital_core and the domain layer (Constitution principle 5); lib/data implements it.
/// The data age is the age of the download, measured from the arrival instant; it is never negative, and it is null (unknown) before the arrival instant.
abstract interface class ElementRepository {
  /// The element set served for [object], or null when there is none. Never
  /// reaches the network.
  Future<ServedElements?> lookup(TrackedObject object);

  /// Refreshes every due object and completes with one outcome per tracked
  /// object, in a map that no caller can change.
  Future<Map<TrackedObject, RefreshOutcome>> refresh();
}

/// An element set of one tracked object and the instant it arrived, in UTC.
final class ServedElements {
  const ServedElements({
    required this.object,
    required this.elements,
    required this.arrivedAtUtc,
  });

  final TrackedObject object;
  final OrbitalElements elements;
  final DateTime arrivedAtUtc;

  /// The time between the arrival instant and [instant], or null when
  /// [instant] is before the arrival instant.
  Duration? ageAt(DateTime instant) {
    final age = instant.difference(arrivedAtUtc);
    return age.isNegative ? null : age;
  }
}

/// What a refresh did with one tracked object.
enum RefreshOutcome { refreshed, notDue, failed }
