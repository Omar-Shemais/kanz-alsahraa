import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/entities/product.dart';
import 'package:fstore/models/entities/product_variation.dart';
import 'package:fstore/services/cart_validation.dart';

Product product({String price = '100', int stock = 5}) => Product.empty('1')
  ..name = 'خاتم'
  ..status = 'publish'
  ..type = 'simple'
  ..price = price
  ..inStock = stock > 0
  ..manageStock = true
  ..stockQuantity = stock;

void main() {
  Future<CartValidationResult> check(
          List<CartValidationLine> lines, Product? fresh,
          {ProductVariation? variant}) =>
      validateWooCart(
        lines: lines,
        loadProduct: (_) async => fresh,
        loadVariation: (_, __) async => variant,
      );
  CartValidationLine line(Product value,
          {String key = '1', int quantity = 1, ProductVariation? variant}) =>
      CartValidationLine(
          key: key, product: value, quantity: quantity, variation: variant);

  test('fresh unchanged product can proceed', () async {
    final result = await check([line(product())], product());
    expect(result.canProceed, true);
  });
  test('price changes require review with refreshed data', () async {
    final result = await check([line(product())], product(price: '110'));
    expect(result.canProceed, false);
    expect(result.priceChanged, true);
    expect(result.products['1']!.price, '110');
    expect(result.message, contains('راجع الإجمالي'));
    final next =
        await check([line(product(price: '110'))], product(price: '110'));
    expect(next.canProceed, true);
  });
  test('stock is combined across separately configured cart lines', () async {
    var calls = 0;
    final result = await validateWooCart(
      lines: [
        line(product(), quantity: 3),
        line(product(), key: '1+custom', quantity: 3)
      ],
      loadProduct: (_) async {
        calls++;
        return product();
      },
      loadVariation: (_, __) async => null,
    );
    expect(result.canProceed, false);
    expect(result.message, contains('أكبر من المتاح'));
    expect(calls, 1);
  });
  test('out of stock, removed and unpublished products are blocked', () async {
    expect(
        (await check([line(product())], product(stock: 0))).canProceed, false);
    expect((await check([line(product())], null)).canProceed, false);
    expect(
        (await check([line(product())], product()..status = 'draft'))
            .canProceed,
        false);
  });
  test('explicit backorders remain available without reducing quantities',
      () async {
    final result = await check([line(product(), quantity: 8)],
        product(stock: 0)..backordersAllowed = true);
    expect(result.canProceed, true);
  });
  test('unconfirmed or invalid prices never default to zero', () async {
    for (final price in ['', 'null', 'NaN', 'Infinity', '-1']) {
      final result = await check([line(product())], product(price: price));
      expect(result.canProceed, false, reason: price);
      expect(result.products, isEmpty);
    }
  });
  test('missing and inactive variation blocks checkout', () async {
    final parent = product()
      ..type = 'variable'
      ..variationIds = ['2'];
    final old = ProductVariation(id: '2', price: '100');
    expect(
        (await check([line(parent, variant: old)], parent)).canProceed, false);
    final inactive = ProductVariation(id: '2', price: '100', isActive: false);
    expect(
        (await check([line(parent, variant: old)], parent, variant: inactive))
            .canProceed,
        false);
    parent.variationIds = [];
    expect(
        (await check([line(parent, variant: old)], parent, variant: old))
            .canProceed,
        false);
  });
  test('parent-managed variations share parent stock rather than zero stock',
      () async {
    final parent = product()
      ..type = 'variable'
      ..variationIds = ['2', '3'];
    ProductVariation variant(String id) => ProductVariation.fromJson({
          'id': id,
          'price': '100',
          'stock_status': 'instock',
          'manage_stock': 'parent',
          'stock_quantity': null,
          'purchasable': true,
        });
    expect(variant('2').inStock, true);
    final success = await check([line(parent, variant: variant('2'))], parent,
        variant: variant('2'));
    expect(success.canProceed, true);
    final result = await validateWooCart(
      lines: [
        line(parent, variant: variant('2'), quantity: 3),
        line(parent, key: '1-3', variant: variant('3'), quantity: 3)
      ],
      loadProduct: (_) async => parent,
      loadVariation: (_, id) async => variant(id),
    );
    expect(result.canProceed, false);
    expect(result.message, contains('أكبر من المتاح'));
  });
  test('variation price and stock are checked independently of parent price',
      () async {
    final parent = product(price: '90')
      ..type = 'variable'
      ..variationIds = ['2'];
    final old = ProductVariation(id: '2', price: '100');
    final fresh = ProductVariation(
        id: '2',
        price: '110',
        inStock: true,
        manageStock: true,
        stockQuantity: 2);
    final result = await check(
        [line(parent, variant: old, quantity: 3)], parent,
        variant: fresh);
    expect(result.priceChanged, true);
    expect(result.canProceed, false);
    expect(result.variations['1']!.price, '110');
  });
  test('network failure propagates without changing saved products', () async {
    final saved = product();
    await expectLater(
        validateWooCart(
            lines: [line(saved)],
            loadProduct: (_) async => throw StateError('Offline'),
            loadVariation: (_, __) async => null),
        throwsStateError);
    expect(saved.price, '100');
  });
  test('variation copy preserves availability and parent stock policy', () {
    final original = ProductVariation(
        id: '2', inStock: true, stockManagedByParent: true, isActive: false);
    final copied = original.copyWith(price: '110');
    expect(copied.inStock, true);
    expect(copied.stockManagedByParent, true);
    expect(copied.isActive, false);
  });
  test('current purchase limits and quantity steps are respected', () async {
    final fresh = product()
      ..minQuantity = 2
      ..maxQuantity = 4
      ..quantityStep = 2;
    expect((await check([line(product())], fresh)).canProceed, false);
    expect(
        (await check([line(product(), quantity: 3)], fresh)).canProceed, false);
    expect(
        (await check([line(product(), quantity: 6)], fresh)).canProceed, false);
    expect(
        (await check([line(product(), quantity: 2)], fresh)).canProceed, true);
  });
  test('published product explicitly disabled for purchase is blocked',
      () async {
    expect(
        (await check([line(product())], product()..purchasable = false))
            .canProceed,
        false);
  });
}
