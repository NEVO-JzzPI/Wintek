// Unit tests of the CelesTrak GP client of specs/req-dat-002.md (requirements 1 to 3).
//
// Responses rebuilt from the CelesTrak snapshot of specs/req-dat-001.md; no test sends a request to CelesTrak (Constitution principle 10).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException, Request, Response;
import 'package:http/testing.dart';
import 'package:wintek/data/celestrak_gp_client.dart';
import 'package:wintek/domain/satellite_catalog.dart';

import '../domain/celestrak_tle_snapshot.dart';

const String _userAgent = 'Wintek/1.0 (+https://github.com/NEVO-JzzPI/Wintek)';
const String _noGpData = 'No GP data found';

/// The tracked object at [position], from 1 to 4, is [TrackedObject.values] in
/// order, which is also the order of the snapshot.
String _name(int position) => celestrakTleSnapshot[(position - 1) * 3];
String _line1(int position) => celestrakTleSnapshot[(position - 1) * 3 + 1];
String _line2(int position) => celestrakTleSnapshot[(position - 1) * 3 + 2];

/// The shape in which CelesTrak serves the snapshot: the name padded to 24
/// characters, every line followed by CR LF.
String _rawBody(int position, {String? line1, String? line2}) =>
    '${_name(position).padRight(24)}\r\n'
    '${line1 ?? _line1(position)}\r\n'
    '${line2 ?? _line2(position)}\r\n';

String _lfBody(int position) =>
    '${_name(position)}\n${_line1(position)}\n${_line2(position)}\n';

String _bareBody(int position) =>
    '${_name(position)}\n${_line1(position)}\n${_line2(position)}';

Future<Response> Function(Request) _respond(int status, String body) =>
    (request) async => Response(body, status);

typedef _Built = ({CelestrakGpClient client, List<Request> requests});

_Built _build(
  Future<Response> Function(Request request) handler, {
  Duration? timeout,
  DateTime Function()? clock,
}) {
  final requests = <Request>[];
  final mock = MockClient((request) {
    requests.add(request);
    return handler(request);
  });
  final client = timeout == null
      ? CelestrakGpClient(mock, clock: clock)
      : CelestrakGpClient(mock, timeout: timeout, clock: clock);
  return (client: client, requests: requests);
}

TypeMatcher<T> _failure<T extends GpFetchResult>(TrackedObject object) =>
    isA<T>().having((result) => result.object, 'object', object);

void main() {
  const iss = TrackedObject.iss;

  // REQ-DAT-002.1
  group('REQ-DAT-002.1 request', () {
    for (final object in TrackedObject.values) {
      test(
        'sends one GET with the GP URL and the User-Agent for $object',
        () async {
          final built = _build(_respond(200, _rawBody(object.index + 1)));

          await built.client.fetch(object);

          expect(built.requests, hasLength(1));
          final request = built.requests.single;
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://celestrak.org/NORAD/elements/gp.php'
            '?CATNR=${object.noradId}&FORMAT=TLE',
          );
          expect(request.headers['User-Agent'], _userAgent);
        },
      );
    }

    final outcomes = <String, Future<Response> Function(Request)>{
      'a success': _respond(200, _rawBody(1)),
      'a network failure': (request) => throw ClientException('refused'),
      'a timeout': (request) => throw TimeoutException('slow'),
      'a status failure': _respond(503, _rawBody(1)),
    };
    outcomes.forEach((label, handler) {
      test('sends exactly one request for $label', () async {
        final built = _build(handler);

        await built.client.fetch(iss);

        expect(built.requests, hasLength(1));
      });
    });

    test('keeps no memory between two fetches of the same object', () async {
      final built = _build(_respond(200, _rawBody(1)));

      await built.client.fetch(iss);
      await built.client.fetch(iss);

      expect(built.requests, hasLength(2));
    });

    test('uses a 20-second timeout when none is given', () {
      final built = _build(_respond(200, _rawBody(1)));

      expect(built.client.timeout, const Duration(seconds: 20));
    });
  });

  // REQ-DAT-002.2
  group('REQ-DAT-002.2 success', () {
    final t0 = DateTime.utc(2026, 11, 14, 10);
    final t1 = DateTime.utc(2026, 11, 14, 11);

    for (final object in TrackedObject.values) {
      final position = object.index + 1;
      final bodies = <String, String>{
        'raw': _rawBody(position),
        'LF': _lfBody(position),
        'bare': _bareBody(position),
      };
      bodies.forEach((shape, body) {
        test('returns the $shape response of $object as served', () async {
          var received = false;
          final built = _build((request) async {
            received = true;
            return Response(body, 200);
          }, clock: () => received ? t1 : t0);

          final result = await built.client.fetch(object);

          expect(result, isA<GpFetchSuccess>());
          final success = result as GpFetchSuccess;
          expect(success.object, object);
          expect(success.nameLine, _name(position));
          expect(success.line1, _line1(position));
          expect(success.line2, _line2(position));
          expect(success.arrivedAtUtc.isUtc, isTrue);
          expect(success.arrivedAtUtc, t1);
        });
      });
    }

    test(
      'returns the arrival instant in UTC when the clock is local',
      () async {
        final localT1 = DateTime(2026, 11, 14, 11);
        final built = _build(_respond(200, _rawBody(1)), clock: () => localT1);

        final result = await built.client.fetch(iss);

        final success = result as GpFetchSuccess;
        expect(success.arrivedAtUtc.isUtc, isTrue);
        expect(success.arrivedAtUtc.isAtSameMomentAs(localT1), isTrue);
      },
    );
  });

  // REQ-DAT-002.3
  group('REQ-DAT-002.3 failures', () {
    test('a ClientException is a network failure', () async {
      final built = _build((request) => throw ClientException('refused'));

      expect(await built.client.fetch(iss), _failure<GpNetworkFailure>(iss));
    });

    test('a plain Exception is a network failure', () async {
      final built = _build((request) => throw Exception('boom'));

      expect(await built.client.fetch(iss), _failure<GpNetworkFailure>(iss));
    });

    test('a response that never completes is a timeout failure', () async {
      final built = _build(
        (request) => Completer<Response>().future,
        timeout: const Duration(milliseconds: 50),
      );

      expect(await built.client.fetch(iss), _failure<GpTimeoutFailure>(iss));
    });

    test(
      'a TimeoutException of the HTTP client is a timeout failure',
      () async {
        final built = _build((request) => throw TimeoutException('slow'));

        expect(await built.client.fetch(iss), _failure<GpTimeoutFailure>(iss));
      },
    );

    final statuses = <int, String>{
      403: _rawBody(1),
      404: _rawBody(1),
      500: _rawBody(1),
      503: _rawBody(1),
      204: '',
    };
    statuses.forEach((status, body) {
      test('status $status is a status failure carrying the code', () async {
        final built = _build(_respond(status, body));

        final result = await built.client.fetch(iss);

        expect(
          result,
          _failure<GpStatusFailure>(iss)
              .having((failure) => failure.statusCode, 'statusCode', status),
        );
      });
    });

    final noData = <String, String>{
      'bare': _noGpData,
      'followed by CR LF': '$_noGpData\r\n',
    };
    noData.forEach((label, body) {
      test('the no-data body $label is a no-data failure', () async {
        final built = _build(_respond(200, body));

        expect(await built.client.fetch(iss), _failure<GpNoDataFailure>(iss));
      });
    });

    final badLine2 = _line2(1);
    final lastDigit = int.parse(badLine2[badLine2.length - 1]);
    final malformed = <String, String>{
      'an empty body': '',
      'a no-data text for this object': 'No GP data found for this object',
      'the element lines without a name line':
          '${_line1(1)}\r\n${_line2(1)}\r\n',
      'two element sets': _rawBody(1) + _rawBody(2),
      'a bad checksum': _rawBody(
        1,
        line2:
            '${badLine2.substring(0, badLine2.length - 1)}'
            '${(lastDigit + 1) % 10}',
      ),
      'a shifted line': _rawBody(1, line1: ' ${_line1(1)}'),
      'an HTML page': '<html><body>Service unavailable</body></html>',
    };
    malformed.forEach((label, body) {
      test('$label is a malformed-payload failure', () async {
        final built = _build(_respond(200, body));

        expect(
          await built.client.fetch(iss),
          _failure<GpMalformedFailure>(iss),
        );
      });
    });

    for (final object in TrackedObject.values) {
      final next = (object.index + 1) % TrackedObject.values.length + 1;
      test(
        'the element set of another object is malformed for $object',
        () async {
          final built = _build(_respond(200, _rawBody(next)));

          expect(
            await built.client.fetch(object),
            _failure<GpMalformedFailure>(object),
          );
        },
      );
    }

    test('a programming error is not caught', () async {
      final built = _build((request) => throw StateError('closed'));

      await expectLater(built.client.fetch(iss), throwsStateError);
    });
  });
}
