import 'dart:convert';

import '../../../models/entities/product.dart';

/// Keeps home product payloads available for the current app session.
///
/// The HTTP layer owns the durable/offline cache. This small memory cache
/// avoids parsing and requesting the same section again when Flutter rebuilds
/// the home layout, and coalesces simultaneous requests for the same section.
class ProductLayoutSessionCache {
  ProductLayoutSessionCache._();

  static const int _maximumSections = 40;
  static final Map<String, List<Product>> _values = {};
  static final Map<String, Future<List<Product>?>> _inFlight = {};

  static String keyFor({required Object? config, String? userId}) {
    String serializedConfig;
    try {
      serializedConfig = jsonEncode(config);
    } catch (_) {
      serializedConfig = config.toString();
    }
    return '${userId ?? 'guest'}|$serializedConfig';
  }

  static Future<List<Product>?> getOrLoad({
    required String key,
    required Future<List<Product>?> Function() loader,
    bool refresh = false,
  }) {
    if (refresh) {
      _values.remove(key);
    } else if (_values.containsKey(key)) {
      final products = _values.remove(key)!;
      _values[key] = products;
      return Future.value(List<Product>.of(products));
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;

    late final Future<List<Product>?> request;
    request = loader().then((products) {
      if (products != null) {
        _values.remove(key);
        _values[key] = List<Product>.of(products);
        while (_values.length > _maximumSections) {
          _values.remove(_values.keys.first);
        }
      }
      return products;
    }).whenComplete(() {
      if (identical(_inFlight[key], request)) {
        _inFlight.remove(key);
      }
    });
    _inFlight[key] = request;
    return request;
  }

  static void clear() {
    _values.clear();
    _inFlight.clear();
  }
}
