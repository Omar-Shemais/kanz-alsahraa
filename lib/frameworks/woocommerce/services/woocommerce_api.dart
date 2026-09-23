import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io' show HttpHeaders;
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/extensions/uri_ext.dart';
import '../../../services/https.dart';
import '../../../services/secure_http_client.dart';
import 'branch_ext.dart';

class QueryString {
  static Map parse(String query) {
    var search = RegExp('([^&=]+)=?([^&]*)');
    var result = {};

    // Get rid off the beginning ? in query strings.
    if (query.startsWith('?')) query = query.substring(1);
    // A custom decoder.
    String decode(String s) => Uri.decodeComponent(s.replaceAll('+', ' '));

    // Go through all the matches and build the result map.
    for (Match match in search.allMatches(query)) {
      result[decode(match.group(1)!)] = decode(match.group(2)!);
    }
    return result;
  }
}

class WooCommerceAPI {
  String? url;
  String? consumerKey;
  String? consumerSecret;
  bool? isHttps;

  WooCommerceAPI(this.url, this.consumerKey, this.consumerSecret) {
    if (url == null) return;

    if (url!.startsWith('https')) {
      isHttps = true;
    } else {
      isHttps = false;
    }

    if (url!.endsWith('/')) {
      url = url!.substring(0, url!.length - 1);
    }

    /// Fallback to default credentials when environment defines are not supplied
    final rawKey = (consumerKey ?? '').trim();
    if (rawKey.isEmpty || rawKey == 'ck_' || rawKey == 'cs_') {
      consumerKey = utf8.decode(base64.decode('Y2tfM2E2YTJmNTM4OGJmM2E5MjRiZWVhMTRkMzhlNTFhYzM3M2EzNDEzZA=='));
    }
    final rawSecret = (consumerSecret ?? '').trim();
    if (rawSecret.isEmpty || rawSecret == 'cs_' || rawSecret == 'ck_') {
      consumerSecret = utf8.decode(base64.decode('Y3NfNTAyNTdiZTFlMDQxZjRjY2U3Y2IwNWI1YzE2YTU1MDFiYTU4OTg3MQ=='));
    }

    /// This is used to enhance security by removing ck, cs keyword from the config
    if (!consumerKey!.contains('ck_')) {
      consumerKey = 'ck_${consumerKey!}';
    }
    if (!consumerSecret!.contains('cs_')) {
      consumerSecret = 'cs_${consumerSecret!}';
    }
  }

  String getOAuthURLExternal(String url) {
    var containsQueryParams = url.contains('?');

    return url +
        (containsQueryParams == true
            ? '&consumer_key=${consumerKey!}&consumer_secret=${consumerSecret!}'
            : '?consumer_key=${consumerKey!}&consumer_secret=${consumerSecret!}');
  }

  Uri? _getOAuthURL(String requestMethod, String endpoint, version) {
    var consumerKey = this.consumerKey;
    var consumerSecret = this.consumerSecret;

    var token = '';
    var url = '${this.url!}/wp-json/wc/v2/$endpoint';
    // Default one is v3
    if (version == 3) {
      url = '${this.url!}/wp-json/wc/v3/$endpoint';
    }
    var containsQueryParams = url.contains('?');

    // If website is HTTPS based, no need for OAuth, just return the URL with CS and CK as query params
    if (isHttps == true) {
      return (url +
              (containsQueryParams == true
                  ? '&consumer_key=${this.consumerKey!}&consumer_secret=${this.consumerSecret!}'
                  : '?consumer_key=${this.consumerKey!}&consumer_secret=${this.consumerSecret!}'))
          .toUri();
    }

    var rand = Random();
    var codeUnits = List.generate(10, (index) {
      return rand.nextInt(26) + 97;
    });

    var nonce = String.fromCharCodes(codeUnits);
    var timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toInt();

    var method = requestMethod;
    var parameters =
        'oauth_consumer_key=${consumerKey!}&oauth_nonce=$nonce&oauth_signature_method=HMAC-SHA1&oauth_timestamp=$timestamp&oauth_token=$token&oauth_version=1.0&';

    if (containsQueryParams == true) {
      parameters = parameters + url.split('?')[1];
    } else {
      parameters = parameters.substring(0, parameters.length - 1);
    }

    var params = QueryString.parse(parameters);
    Map<dynamic, dynamic> treeMap = SplayTreeMap<dynamic, dynamic>();
    treeMap.addAll(params);

    var encodedParamList = <String>[];

    for (var key in treeMap.keys) {
      final encodedParam =
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(treeMap[key])}';

      encodedParamList.add(encodedParam);
    }

    final parameterString = encodedParamList.join('&');

    final baseString =
        '$method&${Uri.encodeQueryComponent(containsQueryParams == true ? url.split('?')[0] : url)}&${Uri.encodeQueryComponent(parameterString)}';

    final signingKey = '${consumerSecret!}&$token';

    final hmacSha1 =
        crypto.Hmac(crypto.sha1, utf8.encode(signingKey)); // HMAC-SHA1
    final signature = hmacSha1.convert(utf8.encode(baseString));

    final finalSignature = base64Encode(signature.bytes);

    var requestUrl = '';

    if (containsQueryParams == true) {
      requestUrl =
          '${url.split('?')[0]}?$parameterString&oauth_signature=${Uri.encodeQueryComponent(finalSignature)}';
    } else {
      requestUrl =
          '$url?$parameterString&oauth_signature=${Uri.encodeQueryComponent(finalSignature)}';
    }
    return requestUrl.toUri();
  }

  Future<http.StreamedResponse> getStream(String endPoint) async {
    var client = SecureHttpClient();
    var request = http.Request('GET', Uri.parse(url!).addProxy());
    return client.send(request);
  }

  Future<dynamic> getAsync(
    String endPoint, {
    int version = 2,
    bool enableDio = false,
    bool refreshCache = false,
  }) async {
    try {
      var url = _getOAuthURL('GET', endPoint, version);
      if (kBranchConfig.enable) {
        url = url?.withCurrentBranch();
      }
      var response = await httpCache(url!, refreshCache: refreshCache);
      // /// Debug purpose to trace which request is not correctly
      // if (endPoint.contains('products/tags')) {
      //   throw Exception('--------Tracing networking-----');
      // }
      return json.decode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> postAsync(String endPoint, Map data,
      {int version = 2}) async {
    final url = _getOAuthURL('POST', endPoint, version)!;

    final client = SecureHttpClient();

    var request = http.Request('POST', url.addProxy());
    request.headers[HttpHeaders.contentTypeHeader] =
        'application/json; charset=utf-8';
    request.headers[HttpHeaders.cacheControlHeader] = 'no-cache';
    request.body = json.encode(data);
    try {
      final response = await client.send(request);
      return json.decode(await response.stream.bytesToString());
    } finally {
      client.close();
    }
  }

  Future<dynamic> putAsync(String endPoint, Map data, {int version = 3}) async {
    var url = _getOAuthURL('PUT', endPoint, version)!;

    var client = SecureHttpClient();
    var request = http.Request('PUT', url.addProxy());
    request.headers[HttpHeaders.contentTypeHeader] =
        'application/json; charset=utf-8';
    request.headers[HttpHeaders.cacheControlHeader] = 'no-cache';
    request.body = json.encode(data);
    try {
      final response = await client.send(request);
      return json.decode(await response.stream.bytesToString());
    } finally {
      client.close();
    }
  }
}
