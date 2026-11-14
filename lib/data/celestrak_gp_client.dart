// ignore_for_file: unintended_html_in_doc_comment
import 'dart:async';

import 'package:http/http.dart' show Client, Response;
import 'package:orbital_core/orbital_core.dart';
import 'package:wintek/domain/satellite_catalog.dart';

const String _userAgent = 'Wintek/1.0 (+https://github.com/NEVO-JzzPI/Wintek)';
const String _noGpDataText = 'No GP data found';
final RegExp _trailingBlanks = RegExp(r'[ \t\r]+$');
final RegExp _edgeBlanksAndLf = RegExp(r'^[ \t\r\n]+|[ \t\r\n]+$');

/// The only network boundary of Wintek: one CelesTrak GP request per tracked object (specs/req-dat-002.md).
///
/// Request: GET https://celestrak.org/NORAD/elements/gp.php?CATNR=<NORAD ID>&FORMAT=TLE, where <NORAD ID> is TrackedObject.noradId.
/// One attempt per call, 20-second timeout, no retry and no timer; when to call is decided by req-dat-004 (Constitution principle 10).
/// Success: the name line and both element lines, accepted by OrbitalElements.fromTle with the requested catalog number, and the UTC instant they arrived.
/// Failures are returned, never thrown: network, timeout, HTTP status, no GP data and malformed payload.
/// The HTTP client is injected and never closed here; whoever creates it owns it.
final class CelestrakGpClient {
  CelestrakGpClient(
    this._httpClient, {
    this.timeout = const Duration(seconds: 20),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Client _httpClient;
  final DateTime Function() _clock;

  /// How long a fetch waits for the response before it gives up.
  final Duration timeout;

  /// Fetches the GP data of [object] with one request and never throws for a
  /// failure of the network or of the payload.
  Future<GpFetchResult> fetch(TrackedObject object) async {
    final Response response;
    try {
      response = await _httpClient
          .get(_gpRequestUri(object), headers: const {'User-Agent': _userAgent})
          .timeout(timeout);
    } on TimeoutException {
      return GpTimeoutFailure(object);
    } on Exception {
      return GpNetworkFailure(object);
    }

    if (response.statusCode != 200) {
      return GpStatusFailure(object, response.statusCode);
    }

    final String body;
    try {
      body = response.body;
    } on FormatException {
      return GpMalformedFailure(object);
    }
    if (_trimBlanksAndLf(body) == _noGpDataText) {
      return GpNoDataFailure(object);
    }

    final lines = [
      for (final line in body.split('\n')) _trimTrailingBlanks(line),
    ].where((line) => line.isNotEmpty).toList();
    if (lines.length != 3) return GpMalformedFailure(object);
    try {
      final elements = OrbitalElements.fromTle(lines[1], lines[2]);
      if (elements.catalogNumber != object.noradId) {
        return GpMalformedFailure(object);
      }
    } on FormatException {
      return GpMalformedFailure(object);
    }

    return GpFetchSuccess(
      object,
      nameLine: lines[0],
      line1: lines[1],
      line2: lines[2],
      arrivedAtUtc: _clock().toUtc(),
    );
  }
}

/// The result of one fetch: a [GpFetchSuccess] or one of five failures.
sealed class GpFetchResult {
  const GpFetchResult(this.object);

  /// The tracked object that was requested.
  final TrackedObject object;
}

/// A valid element set, as CelesTrak served it minus line ends and trailing blanks.
final class GpFetchSuccess extends GpFetchResult {
  const GpFetchSuccess(
    super.object, {
    required this.nameLine,
    required this.line1,
    required this.line2,
    required this.arrivedAtUtc,
  });

  final String nameLine;
  final String line1;
  final String line2;

  /// When the response arrived, read from the wall clock, in UTC.
  final DateTime arrivedAtUtc;
}

/// The request failed before a response arrived.
final class GpNetworkFailure extends GpFetchResult {
  const GpNetworkFailure(super.object);
}

/// No response arrived within the timeout.
final class GpTimeoutFailure extends GpFetchResult {
  const GpTimeoutFailure(super.object);
}

/// The response had a status other than 200.
final class GpStatusFailure extends GpFetchResult {
  const GpStatusFailure(super.object, this.statusCode);

  final int statusCode;
}

/// CelesTrak has no current element set for the object.
final class GpNoDataFailure extends GpFetchResult {
  const GpNoDataFailure(super.object);
}

/// The response is not a valid element set for the requested object.
final class GpMalformedFailure extends GpFetchResult {
  const GpMalformedFailure(super.object);
}

Uri _gpRequestUri(TrackedObject object) => Uri.https(
  'celestrak.org',
  '/NORAD/elements/gp.php',
  {'CATNR': '${object.noradId}', 'FORMAT': 'TLE'},
);

String _trimTrailingBlanks(String line) =>
    line.replaceFirst(_trailingBlanks, '');

String _trimBlanksAndLf(String text) => text.replaceAll(_edgeBlanksAndLf, '');
