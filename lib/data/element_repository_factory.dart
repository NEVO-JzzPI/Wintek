import 'dart:io';

import 'package:http/http.dart' show Client;
import 'package:path_provider/path_provider.dart';
import 'package:wintek/data/celestrak_element_repository.dart';
import 'package:wintek/data/celestrak_gp_client.dart';
import 'package:wintek/data/element_cache.dart';
import 'package:wintek/domain/element_repository.dart';

/// Opens the element repository of the app on the application support directory of path_provider, which the operating system does not clear on its own (specs/req-dat-004.md).
///
/// Creates the one production HTTP client of the app and closes it once on close; whoever creates it owns it (specs/req-dat-002.md, amended by req-dat-004).
/// Opening resolves the directory first and sends no request; the resolver, the HTTP client creator and the clock are injectable for tests.
final class ElementRepositoryHandle {
  ElementRepositoryHandle._(this.repository, this._httpClient);

  final ElementRepository repository;
  final Client _httpClient;
  bool _closed = false;

  static Future<ElementRepositoryHandle> open({
    Future<Directory> Function()? resolveDirectory,
    Client Function()? createClient,
    DateTime Function()? clock,
  }) async {
    final resolve = resolveDirectory ?? getApplicationSupportDirectory;
    final directory = await resolve();
    final httpClient = (createClient ?? Client.new)();
    return ElementRepositoryHandle._(
      CelestrakElementRepository(
        CelestrakGpClient(httpClient, clock: clock),
        ElementCache(directory),
        clock: clock,
      ),
      httpClient,
    );
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }
}
