import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/entities/category.dart';

void main() {
  test('WordPress category without an image remains image-free', () {
    final category = Category.fromWordPress({
      'id': 125,
      'name': '1 جرام',
      'parent': 124,
      'count': 10,
      'image': null,
    });

    expect(category.image, isNull);
  });

  test('WordPress category uses a real WooCommerce image when supplied', () {
    final category = Category.fromWordPress({
      'id': 124,
      'name': 'سبائك ذهب',
      'parent': 0,
      'count': 50,
      'image': {'src': 'https://kanzalsahra.com/category/gold.jpg'},
    });

    expect(category.image, 'https://kanzalsahra.com/category/gold.jpg');
  });
}
