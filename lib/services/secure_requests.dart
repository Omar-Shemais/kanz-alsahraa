import 'package:http/http.dart' as http;

import 'secure_http_client.dart';

/// Store requests deliberately bypass SDK logging and proxy/certificate overrides.
/// Responses (including non-2xx responses) retain their actual status and body.
Future<http.Response> secureGet(Uri uri,
    {Map<String, String>? headers,
    bool refreshCache = false,
    http.Client? transport}) {
  if (refreshCache) {
    uri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'refresh': '${DateTime.now().millisecondsSinceEpoch}',
    });
  }
  return _request('GET', uri, headers: headers, transport: transport);
}

Future<http.Response> securePost(Uri uri,
        {Map<String, String>? headers, Object? body, http.Client? transport}) =>
    _request('POST', uri, headers: headers, body: body, transport: transport);

Future<http.Response> securePut(Uri uri,
        {Map<String, String>? headers, Object? body, http.Client? transport}) =>
    _request('PUT', uri, headers: headers, body: body, transport: transport);

Future<http.Response> securePatch(Uri uri,
        {Map<String, String>? headers, Object? body, http.Client? transport}) =>
    _request('PATCH', uri, headers: headers, body: body, transport: transport);

Future<http.Response> secureDelete(Uri uri,
        {Map<String, String>? headers, Object? body, http.Client? transport}) =>
    _request('DELETE', uri, headers: headers, body: body, transport: transport);

Future<http.Response> _request(String method, Uri uri,
    {Map<String, String>? headers,
    Object? body,
    http.Client? transport}) async {
  final client = SecureHttpClient(transport);
  try {
    return await switch (method) {
      'GET' => client.get(uri, headers: headers),
      'POST' => client.post(uri, headers: headers, body: body),
      'PUT' => client.put(uri, headers: headers, body: body),
      'PATCH' => client.patch(uri, headers: headers, body: body),
      'DELETE' => client.delete(uri, headers: headers, body: body),
      _ => throw ArgumentError('Unsupported store request method'),
    };
  } finally {
    client.close();
  }
}
