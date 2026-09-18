import 'package:http/http.dart' as http;

void requireHttps(Uri uri) {
  if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    throw http.ClientException(
        'An HTTPS endpoint without embedded user credentials is required.');
  }
}

/// Explicit redirects stop a trusted HTTPS request downgrading to HTTP.
/// Never replay writes, or forward authenticated requests to another origin.
class SecureHttpClient extends http.BaseClient {
  SecureHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();
  final http.Client _inner;

  bool _sensitive(http.BaseRequest request) =>
      request.headers.keys.any((key) =>
          RegExp(r'authorization|cookie|token|secret|session|key|password',
                  caseSensitive: false)
              .hasMatch(key) ||
          key.toLowerCase().startsWith('x-')) ||
      request.url.queryParameters.keys.any((key) => RegExp(
              r'consumer_|oauth_|token|secret|cookie|key|session|password|authorization',
              caseSensitive: false)
          .hasMatch(key));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requireHttps(request.url);
    final follow = request.followRedirects;
    final maximum = request.maxRedirects;
    var current = request;
    var redirects = 0;
    while (true) {
      current.followRedirects = false;
      http.StreamedResponse response;
      try {
        response = await _inner.send(current);
        response = http.StreamedResponse(
          response.stream.handleError((Object error, StackTrace stack) {
            throw http.ClientException(
                'The secure response could not be read.');
          }),
          response.statusCode,
          headers: response.headers,
          contentLength: response.contentLength,
          request: response.request,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      } catch (_) {
        // ClientException normally includes the full URI, possibly with keys.
        throw http.ClientException('The secure network request failed.');
      }
      if (!follow || ![301, 302, 303, 307, 308].contains(response.statusCode)) {
        return response;
      }
      final location = response.headers['location'];
      if (location == null) return response;
      await response.stream.drain<void>();
      if (!['GET', 'HEAD'].contains(current.method)) {
        throw http.ClientException(
            'Write requests cannot be replayed through redirects.');
      }
      if (++redirects > maximum) {
        throw http.ClientException('Too many secure redirects.');
      }
      Uri next;
      try {
        next = current.url.resolve(location);
      } catch (_) {
        throw http.ClientException('Invalid secure redirect.');
      }
      requireHttps(next);
      final crossOrigin = next.origin != current.url.origin;
      if (crossOrigin && _sensitive(current)) {
        throw http.ClientException(
            'Authenticated requests cannot redirect to another origin.');
      }
      final headers =
          crossOrigin ? <String, String>{} : Map.of(current.headers);
      current = http.Request(current.method, next)..headers.addAll(headers);
    }
  }

  @override
  void close() => _inner.close();
}
