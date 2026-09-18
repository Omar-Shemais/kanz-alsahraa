import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/category/category_model_impl.dart';
import 'package:fstore/models/entities/product.dart';
import 'package:fstore/models/product_model.dart';
import 'package:fstore/services/service_config.dart';
import 'package:fstore/widgets/common/catalog_load_error.dart';

void main() {
  setUp(() {
    ServerConfig().setConfig({'type': 'woo', 'url': 'https://example.com'});
  });
  test('empty product response is not a failed request', () async {
    final model = ProductModel(fetchProducts: () async => []);
    await model.getProductsList(page: 1);
    expect(model.errMsg, null);
    expect(model.productsList, isEmpty);
    expect(model.isEnd, true);
    expect(model.isFetching, false);
    model.dispose();
  });
  test('failure preserves products and allows recovery without raw error',
      () async {
    var fail = true;
    final model = ProductModel(fetchProducts: () async {
      if (fail) throw StateError('private technical details');
      return [];
    });
    final saved = Product.empty('saved');
    model.setProductsList([saved]);
    await model.getProductsList(page: 2);
    expect(model.errMsg, isNotNull);
    expect(model.errMsg, isNot(contains('private technical')));
    expect(model.productsList!.single, saved);
    expect(model.isEnd, false);
    expect(model.isFetching, false);
    fail = false;
    await model.getProductsList(page: 1);
    expect(model.errMsg, null);
    model.dispose();
  });
  test('late search result cannot replace a newer search', () async {
    final first = Completer<List<Product>?>();
    var calls = 0;
    final model = ProductModel(fetchProducts: () {
      calls++;
      return calls == 1 ? first.future : Future.value([Product.empty('new')]);
    });
    final old = model.getProductsList(page: 1, search: 'old');
    await model.getProductsList(page: 1, search: 'new');
    first.complete([Product.empty('old')]);
    await old;
    expect(model.productsList!.single.id, 'new');
    expect(model.errMsg, null);
    model.dispose();
  });
  test('pagination without an earlier list does not crash', () async {
    final model = ProductModel(fetchProducts: () async => [Product.empty('1')]);
    await model.getProductsList(page: 2);
    expect(model.productsList!.single.id, '1');
    expect(model.errMsg, null);
    model.dispose();
  });
  test('leaving a loading product screen cancels delivery safely', () async {
    final response = Completer<List<Product>?>();
    final model = ProductModel(fetchProducts: () => response.future);
    final pending = model.getProductsList(page: 1);
    model.dispose();
    response.complete([Product.empty('late')]);
    await pending;
    expect(model.productsList, null);
  });
  test(
      'category failure notifies listeners, then a real empty response recovers',
      () async {
    var fail = true;
    final model = CategoryModelImpl(loadCategories: () async {
      if (fail) throw StateError('Unavailable');
      return [];
    });
    var changes = 0;
    model.addListener(() {
      changes++;
    });
    await model.getCategories();
    expect(model.loadError, isNotNull);
    expect(model.isLoading, false);
    expect(changes, 2);
    fail = false;
    await model.getCategories();
    expect(model.loadError, null);
    expect(model.categories, isEmpty);
    model.dispose();
  });
  testWidgets(
      'Arabic catalog error has a retry action, not an empty-store message',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
        home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: CatalogLoadError(onRetry: () {
        retries++;
      })),
    )));
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
  });
}
