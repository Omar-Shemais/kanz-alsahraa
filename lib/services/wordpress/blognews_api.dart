import 'dart:convert';
import 'dart:io' show File, HttpHeaders;

import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '../secure_http_client.dart';
import '../secure_requests.dart';

class BlogNewsApi {
  final String url;
  final bool isRoot;
  final http.Client Function() _createTransport;

  BlogNewsApi(this.url,
      {this.isRoot = true, http.Client Function()? createTransport})
      : _createTransport = createTransport ?? http.Client.new;

  Uri _endpoint(String endpoint) => Uri.parse(
      '${url.replaceFirst(RegExp(r'/+$'), '')}/wp-json/wp/v2/$endpoint');

  /// The caller must consume or cancel the stream; both release its client.
  Future<http.StreamedResponse> getStream(String endPoint) async {
    final client = SecureHttpClient(_createTransport());
    try {
      final response =
          await client.send(http.Request('GET', _endpoint(endPoint)));
      Stream<List<int>> ownedStream() async* {
        try {
          yield* response.stream;
        } finally {
          client.close();
        }
      }

      return http.StreamedResponse(ownedStream(), response.statusCode,
          headers: response.headers,
          contentLength: response.contentLength,
          request: response.request,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase);
    } catch (_) {
      client.close();
      rethrow;
    }
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('The blog service rejected the request.');
    }
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> getAsync(String endPoint) async => _decode(
      await secureGet(_endpoint(endPoint), transport: _createTransport()));

  Future<dynamic> postAsync(String endPoint, Map? data,
          {String? token}) async =>
      _decode(await securePost(_endpoint(endPoint),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            HttpHeaders.cacheControlHeader: 'no-cache',
            if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
          body: json.encode(data),
          transport: _createTransport()));

  Future<dynamic> putAsync(String endPoint, Map data) async =>
      _decode(await securePut(_endpoint(endPoint),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            HttpHeaders.cacheControlHeader: 'no-cache',
          },
          body: json.encode(data),
          transport: _createTransport()));

  Future<dynamic> uploadBlogImage(File imageFile, String token) async {
    final client = SecureHttpClient(_createTransport());
    try {
      final request = http.MultipartRequest('POST', _endpoint('media'));
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      request.headers[HttpHeaders.cacheControlHeader] = 'no-cache';
      // MultipartRequest supplies the correct boundary, not JSON content-type.
      request.files.add(http.MultipartFile(
          'file', imageFile.openRead(), await imageFile.length(),
          filename: basename(imageFile.path)));
      final data =
          _decode(await http.Response.fromStream(await client.send(request)));
      if (data is Map && data['id'] != null) return data;
      throw http.ClientException(
          'The blog image upload could not be confirmed.');
    } finally {
      client.close();
    }
  }
}
