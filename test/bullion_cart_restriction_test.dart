import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/cart/cart_model_woo.dart';
import 'package:fstore/models/cart/mixin/cart_mixin.dart';
import 'package:fstore/models/entities/brand.dart';
import 'package:fstore/models/entities/category.dart';
import 'package:fstore/models/entities/product.dart';
import 'package:fstore/models/entities/product_attribute.dart';
import 'package:fstore/models/entities/tag.dart';
import 'package:fstore/services/cart_validation.dart';

void main() {
  group('Cart Bullion & Promotional Restrictions (Problem 18 / T023)', () {
    test('detects bullion product by Arabic name', () {
      final bullion = Product.empty('1')..name = 'سبيكة ذهب سويسري 10 جرام';
      expect(CartMixin.isBullionOrRestrictedProduct(bullion), isTrue);
    });

    test('detects bullion product by English name', () {
      final bullion = Product.empty('2')..name = 'Gold Bullion Bar 50g';
      expect(CartMixin.isBullionOrRestrictedProduct(bullion), isTrue);
    });

    test('detects bullion product by category name', () {
      final product = Product.empty('3')
        ..name = 'منتج استثماري'
        ..categories = [
          Category.fromJson({'id': '10', 'name': 'سبائك ذهب'})
        ];
      expect(CartMixin.isBullionOrRestrictedProduct(product), isTrue);
    });

    test('detects bullion product by tag', () {
      final product = Product.empty('4')
        ..name = 'منتج فاخر'
        ..tags = [
          Tag.fromJson({'id': '20', 'name': 'bullion'})
        ];
      expect(CartMixin.isBullionOrRestrictedProduct(product), isTrue);
    });

    test('detects bullion product by pa_brand attribute', () {
      final product = Product.empty('7')
        ..name = 'منتج ذهبي خاص'
        ..attributes = [
          ProductAttribute(name: 'pa_brand', options: ['سبائك عيار 24']),
        ];
      expect(CartMixin.isBullionOrRestrictedProduct(product), isTrue);
    });

    test('detects bullion product by brand', () {
      final product = Product.empty('8')
        ..name = 'استثمار مميز'
        ..brands = [
          Brand(id: '3', name: 'سبائك عيار 24'),
        ];
      expect(CartMixin.isBullionOrRestrictedProduct(product), isTrue);
    });

    test('does not flag standard gold jewelry items as bullion', () {
      final ring = Product.empty('5')..name = 'خاتم سوليتير ذهب أصفر عيار 18';
      expect(CartMixin.isBullionOrRestrictedProduct(ring), isFalse);

      final necklace = Product.empty('6')
        ..name = 'عقد كنز الصحراء الملكي'
        ..categories = [
          Category.fromJson({'id': '11', 'name': 'أطقم ومجوهرات'})
        ];
      expect(CartMixin.isBullionOrRestrictedProduct(necklace), isFalse);
    });

    test('CartModel detects presence of bullion items', () {
      final cart = CartModelWoo();
      expect(cart.hasBullionOrRestrictedItems, isFalse);

      final bullion = Product.empty('100')
        ..name = 'سبيكة ذهب خالص 100 جرام'
        ..price = '35000';
      cart.item['100'] = bullion;
      cart.productsInCart['100'] = 1;

      expect(cart.hasBullionOrRestrictedItems, isTrue);
    });

    test('validateWooCart flags hasBullion when cart includes bullion item',
        () async {
      final bullion = Product.empty('200')
        ..name = 'سبيكة ذهب 5 جرام'
        ..price = '1800'
        ..status = 'publish'
        ..inStock = true
        ..purchasable = true;

      final lines = [
        CartValidationLine(
          key: '200',
          product: bullion,
          quantity: 1,
        ),
      ];

      final result = await validateWooCart(
        lines: lines,
        loadProduct: (id) async => bullion,
        loadVariation: (id, varId) async => null,
      );

      expect(result.canProceed, isTrue);
      expect(result.hasBullion, isTrue);
    });
  });
}
