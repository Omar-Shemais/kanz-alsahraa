import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/menu/kanz_drawer_categories.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('public drawer categories load without WooCommerce credentials',
      () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response.bytes(
        utf8.encode(
            '[{"id":124,"name":"سبائك ذهب","parent":0,"count":65,"slug":"gold-bars","image":null}]'),
        200,
      );
    });
    final categories = await loadPublicDrawerCategories(transport: client);
    expect(requested?.host, 'kanzalsahra.com');
    expect(requested?.path, '/wp-json/wc/store/v1/products/categories');
    expect(requested?.queryParameters.containsKey('consumer_key'), isFalse);
    expect(categories.single.id, '124');
    expect(categories.single.isRoot, isTrue);
  });

  test('public drawer category errors are reported', () async {
    final client = MockClient((_) async => http.Response('{}', 401));
    expect(
        loadPublicDrawerCategories(transport: client), throwsFormatException);
  });
}
