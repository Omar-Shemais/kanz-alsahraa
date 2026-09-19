import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/entities/product.dart';
import 'package:fstore/modules/dynamic_layout/product/product_layout_session_cache.dart';

void main() {
  setUp(ProductLayoutSessionCache.clear);

  test('reuses a completed product section during the app session', () async {
    var calls = 0;
    final key = ProductLayoutSessionCache.keyFor(
      config: {'category': 124, 'limit': 12},
      userId: null,
    );

    Future<List<Product>?> load() async {
      calls++;
      return <Product>[];
    }

    await ProductLayoutSessionCache.getOrLoad(key: key, loader: load);
    await ProductLayoutSessionCache.getOrLoad(key: key, loader: load);

    expect(calls, 1);
  });

  test('coalesces simultaneous requests for the same section', () async {
    var calls = 0;
    final completer = Completer<List<Product>?>();

    Future<List<Product>?> load() {
      calls++;
      return completer.future;
    }

    final first = ProductLayoutSessionCache.getOrLoad(
      key: 'same-section',
      loader: load,
    );
    final second = ProductLayoutSessionCache.getOrLoad(
      key: 'same-section',
      loader: load,
    );
    completer.complete(<Product>[]);

    await Future.wait([first, second]);
    expect(calls, 1);
  });

  test('refresh bypasses a completed session value', () async {
    var calls = 0;

    Future<List<Product>?> load() async {
      calls++;
      return <Product>[];
    }

    await ProductLayoutSessionCache.getOrLoad(key: 'refresh', loader: load);
    await ProductLayoutSessionCache.getOrLoad(
      key: 'refresh',
      loader: load,
      refresh: true,
    );

    expect(calls, 2);
  });

  test('failed requests are not retained', () async {
    var calls = 0;

    Future<List<Product>?> load() async {
      calls++;
      if (calls == 1) throw StateError('offline');
      return <Product>[];
    }

    await expectLater(
      ProductLayoutSessionCache.getOrLoad(key: 'failure', loader: load),
      throwsStateError,
    );
    await ProductLayoutSessionCache.getOrLoad(key: 'failure', loader: load);

    expect(calls, 2);
  });

  test('customer-specific product sections use separate keys', () {
    final config = {'category': 124};
    final guest =
        ProductLayoutSessionCache.keyFor(config: config, userId: null);
    final customer =
        ProductLayoutSessionCache.keyFor(config: config, userId: '42');

    expect(customer, isNot(guest));
  });

  test('many changing sections remain bounded without breaking recent cache',
      () async {
    var calls = 0;

    Future<List<Product>?> load() async {
      calls++;
      return <Product>[];
    }

    for (var index = 0; index < 45; index++) {
      await ProductLayoutSessionCache.getOrLoad(
        key: 'section-$index',
        loader: load,
      );
    }
    await ProductLayoutSessionCache.getOrLoad(
      key: 'section-44',
      loader: load,
    );
    expect(calls, 45);

    await ProductLayoutSessionCache.getOrLoad(
      key: 'section-0',
      loader: load,
    );
    expect(calls, 46);
  });
}
