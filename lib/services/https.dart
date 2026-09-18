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
        if (cachedInfo != null &&
            cachedInfo.validTill.isAfter(DateTime.now()) &&
            cachedInfo.file.existsSync()) {
          var res = await cachedInfo.file.readAsString();
          var fileSize =
              (cachedInfo.file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
          printLog('📥 GET CACHE($fileSize mb)', startTime);
          return http.Response(res, 200);
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
      // printLog(trace);
      printLog('CACHE ISSUE: $e', startTime, Level.debug);
    }
  }
  final client = SecureHttpClient();
  try {
    return await client.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw http.ClientException('Network timeout for $uri'),
        );
  } finally {
    client.close();
  }
}
