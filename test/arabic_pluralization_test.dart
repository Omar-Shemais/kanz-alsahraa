import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Arabic Localization & Pluralization (Problem 36)', () {
    String formatItemQuantity(int count) {
      return Intl.plural(
        count,
        locale: 'ar',
        zero: 'لا توجد منتجات',
        one: 'منتج واحد',
        two: 'منتجان',
        few: '$count منتجات',
        many: '$count منتجاً',
        other: '$count منتج',
      );
    }

    test('verifies zero items', () {
      expect(formatItemQuantity(0), 'لا توجد منتجات');
    });

    test('verifies singular (one) item', () {
      expect(formatItemQuantity(1), 'منتج واحد');
    });

    test('verifies dual (two) items', () {
      expect(formatItemQuantity(2), 'منتجان');
    });

    test('verifies few items (3 to 10)', () {
      expect(formatItemQuantity(3), '3 منتجات');
      expect(formatItemQuantity(5), '5 منتجات');
      expect(formatItemQuantity(10), '10 منتجات');
    });

    test('verifies many items (11 to 99)', () {
      expect(formatItemQuantity(11), '11 منتجاً');
      expect(formatItemQuantity(25), '25 منتجاً');
      expect(formatItemQuantity(99), '99 منتجاً');
    });

    test('verifies other items (100+)', () {
      expect(formatItemQuantity(100), '100 منتج');
    });
  });
}
