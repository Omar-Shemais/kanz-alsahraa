import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modules/dynamic_layout/config/app_config.dart';
import 'secure_http_client.dart';

Future<AppConfig> loadRemoteHomeConfig(String url,
    {http.Client? transport,
    Duration timeout = const Duration(seconds: 10)}) async {
  final client = SecureHttpClient(transport);
  try {
    final response = await client.get(Uri.parse(url),
        headers: {'Accept': 'application/json'}).timeout(timeout);
    if (response.statusCode != 200) {
      throw const FormatException('Remote home configuration is unavailable.');
    }
    return AppConfig.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  } catch (_) {
    throw const FormatException(
        'Remote home configuration could not be loaded.');
  } finally {
    client.close();
  }
}
