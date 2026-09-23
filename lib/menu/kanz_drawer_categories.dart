import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/entities/category.dart';
import '../services/secure_http_client.dart';

/// Public Store API fallback for the menu; it never needs WooCommerce secrets.
Future<List<Category>> loadPublicDrawerCategories(
    {http.Client? transport}) async {
  final client = SecureHttpClient(transport);
  try {
    final response = await client
        .get(Uri.parse(
            'https://kanzalsahra.com/wp-json/wc/store/v1/products/categories?per_page=100'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const FormatException('Categories unavailable');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('Invalid categories');
    }
    return decoded
        .whereType<Map>()
        .where((item) => item['slug'] != 'uncategorized')
        .map(Category.fromJson)
        .where((item) => item.id != null && item.name != null)
        .toList();
  } finally {
    client.close();
  }
}
