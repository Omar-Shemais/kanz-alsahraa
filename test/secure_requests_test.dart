import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/secure_requests.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final path in [
    'lib/services/base_services.dart',
    'lib/models/app_model.dart',
    'lib/models/entities/blog.dart',
    'lib/models/entities/coupon.dart',
  ]) {
    test('shared store path uses guarded requests: $path', () {
      final source = File(path).readAsStringSync();
      expect(RegExp(r'\bhttp(Get|Post|Put|Patch|Delete)\(').hasMatch(source),
          false);
      expect(RegExp(r'\bhttp\.(get|post|put|patch|delete)\(').hasMatch(source),
          false);
      expect(
          source,
          contains(path.endsWith('app_model.dart')
              ? 'remote_home_config.dart'
              : 'secure_requests.dart'));
    });
  }
  test('store session header cannot redirect to another origin', () async {
    var calls = 0;
    await expectLater(
      secureGet(Uri.parse('https://store.example/account'),
          headers: {'User-Cookie': 'private'}, transport: MockClient((_) async {
        calls++;
        return http.Response('', 302,
            headers: {'location': 'https://external.example'});
      })),
      throwsA(isA<http.ClientException>()),
    );
    expect(calls, 1);
  });

  test('form writes preserve body encoding and actual error status', () async {
    final response = await securePost(Uri.parse('https://store.example/login'),
        body: {'name': 'a b', 'password': 'example'},
        transport: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.bodyFields, {'name': 'a b', 'password': 'example'});
      expect(request.headers['content-type'],
          contains('application/x-www-form-urlencoded'));
      return http.Response('rejected', 401);
    }));
    expect(response.statusCode, 401);
    expect(response.body, 'rejected');
  });

  test('fresh GET preserves query and requests refresh without SDK proxy',
      () async {
    await secureGet(Uri.parse('https://store.example/orders?page=2'),
        refreshCache: true, transport: MockClient((request) async {
      expect(request.url.host, 'store.example');
      expect(request.url.queryParameters['page'], '2');
      expect(request.url.queryParameters['refresh'], isNotEmpty);
      return http.Response('ok', 200);
    }));
  });

  test('Woo store and review no longer use unguarded SDK request helpers', () {
    for (final name in ['woo_commerce', 'woo_review_service']) {
      final source = File('lib/frameworks/woocommerce/services/$name.dart')
          .readAsStringSync();
      expect(RegExp(r'\bhttp(Get|Post|Put|Patch|Delete)\(').hasMatch(source),
          false,
          reason: name);
      expect(source, contains('secure_requests.dart'));
      expect(source, isNot(contains('enableDio: true')));
    }
  });
}
