// Catalog source: CelesTrak SATCAT, https://celestrak.org/satcat/records.php?CATNR=<NORAD ID>, checked on 2026-11-10.
// GOES-East: GOES 19 since 2025-04-07, https://www.nesdis.noaa.gov/news/noaas-goes-19-now-operational-goes-east-providing-critical-new-data-forecasters

import 'package:flutter_test/flutter_test.dart';
import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/domain/satellite_catalog.dart';

import 'celestrak_tle_snapshot.dart';

const List<String> _keys = ['iss', 'tiangong', 'fasatCharlie', 'goesEast'];
const List<String> _displayNames = [
  'ISS',
  'Tiangong',
  'FASat-Charlie',
  'GOES-East',
];
const List<int> _noradIds = [25544, 48274, 38011, 60133];
const List<String> _celestrakNames = [
  'ISS (ZARYA)',
  'CSS (TIANHE)',
  'SSOT',
  'GOES 19',
];

void main() {
  // REQ-DAT-001.1
  group('REQ-DAT-001.1 the four tracked objects', () {
    test('the catalog has exactly four entries', () {
      expect(TrackedObject.values, hasLength(4));
    });

    test('the keys are those of the spec, in display order', () {
      expect(TrackedObject.values.map((o) => o.name).toList(), _keys);
    });

    test('the display names are those of the spec', () {
      expect(
        TrackedObject.values.map((o) => o.displayName).toList(),
        _displayNames,
      );
    });

    test('the NORAD IDs are those of the spec', () {
      expect(TrackedObject.values.map((o) => o.noradId).toList(), _noradIds);
    });
  });

  // REQ-DAT-001.2
  group('REQ-DAT-001.2 catalog invariants', () {
    test('every NORAD ID is from 1 to 99999', () {
      for (final object in TrackedObject.values) {
        expect(object.noradId, inInclusiveRange(1, 99999), reason: object.name);
      }
    });

    test('the NORAD IDs are distinct', () {
      final ids = TrackedObject.values.map((o) => o.noradId).toSet();
      expect(ids, hasLength(TrackedObject.values.length));
    });

    test('the display names are distinct', () {
      final names = TrackedObject.values.map((o) => o.displayName).toSet();
      expect(names, hasLength(TrackedObject.values.length));
    });

    test('the display names are not empty and have no outer spaces', () {
      for (final object in TrackedObject.values) {
        expect(object.displayName, isNotEmpty, reason: object.name);
        expect(object.displayName, object.displayName.trim());
      }
    });
  });

  // REQ-DAT-001.3
  group('REQ-DAT-001.3 IDs match the CelesTrak snapshot', () {
    test('the snapshot holds three strings per object', () {
      expect(celestrakTleSnapshot, hasLength(12));
    });

    for (var k = 0; k < TrackedObject.values.length; k++) {
      final object = TrackedObject.values[k];

      test('${object.displayName}: the name line is its CelesTrak name', () {
        expect(celestrakTleSnapshot[3 * k], _celestrakNames[k]);
      });

      test('${object.displayName}: the TLE parses with its NORAD ID', () {
        final elements = OrbitalElements.fromTle(
          celestrakTleSnapshot[3 * k + 1],
          celestrakTleSnapshot[3 * k + 2],
        );
        expect(elements.catalogNumber, object.noradId);
      });
    }
  });
}
