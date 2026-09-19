import 'package:http/http.dart' as http;
import 'package:inspireui/inspireui.dart';
// ignore: depend_on_referenced_packages
import 'package:logger/logger.dart';

import '../common/config.dart';
import 'app_telemetry.dart';
import 'http_cache_manager.dart';
import 'secure_http_client.dart';

const isBuilder = false;

/// The default http GET that support Logging
Future<http.Response> httpCache(
  Uri uri, {
  Map<String, String>? headers,
  bool refreshCache = false,
}) =>
    AppTelemetry.measure(
        'kanz_catalog_request',
        () => _httpCache(
              uri,
              headers: headers,
              refreshCache: refreshCache,
            ));

Future<http.Response> _httpCache(
  Uri uri, {
  Map<String, String>? headers,
  bool refreshCache = false,
}) async {
  requireHttps(uri);
  final startTime = DateTime.now();
  http.Response? staleResponse;

  if (refreshCache) {
    await HttpCacheManager().removeFile(uri.toString());
    printLog('🔴 REMOVE CACHE', startTime);
  }

  // Enable default on FluxBuilder
  if (kAdvanceConfig.httpCache || isBuilder) {
    try {
      if (!refreshCache) {
        final cachedInfo =
            await HttpCacheManager().getFileFromCache(uri.toString());
        if (cachedInfo != null && cachedInfo.file.existsSync()) {
          var res = await cachedInfo.file.readAsString();
          var fileSize =
              (cachedInfo.file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
          if (cachedInfo.validTill.isAfter(DateTime.now())) {
            printLog('📥 GET CACHE($fileSize mb)', startTime);
            return http.Response(res, 200);
          }
          // Keep the last valid payload available while attempting a refresh.
          // Product images have their own disk cache; retaining the catalog
          // response makes the complete home screen usable without a network.
          staleResponse = http.Response(res, 200);
        }
      }

      var file = await HttpCacheManager().getSingleFile(
        uri.toString(),
        headers: headers,
      );

      if (await file.exists()) {
        var res = await file.readAsString();
        var fileSize = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

        printLog('📥 GET CACHE($fileSize mb)', startTime);
        return http.Response(res, 200);
      }
      return http.Response('', 404);
    } catch (e) {
      printLog('CACHE ISSUE: $e', startTime, Level.debug);
      if (staleResponse != null) {
        printLog('📥 GET STALE CACHE', startTime);
        return staleResponse;
      }
    }
  }
  final client = SecureHttpClient();
  try {
    try {
      return await client.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw http.ClientException('Network timeout for $uri'),
          );
    } catch (_) {
      if (staleResponse != null) return staleResponse;
      rethrow;
    }
  } finally {
    client.close();
  }
}
