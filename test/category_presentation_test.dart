import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/common/constants.dart';
import 'package:fstore/models/entities/category.dart';
import 'package:fstore/screens/categories/category_presentation.dart';

Category category({
  required String id,
  required String name,
  String parent = '0',
  String? slug,
  int count = 0,
  String? image,
}) {
  return Category(
    id: id,
    name: name,
    parent: parent,
    slug: slug,
    totalProduct: count,
    image: image,
    subCategories: const [],
  );
}

void main() {
  test('storefront roots preserve configured order and remove empty roots', () {
    final categories = [
      category(id: '2', name: 'المجوهرات', count: 4),
      category(id: '1', name: 'سبائك ذهب', count: 20),
      category(id: '3', name: 'Legacy category'),
    ];

    expect(
      storefrontRootCategories(categories).map((item) => item.id),
      ['2', '1'],
    );
  });

  test('root with products in a descendant remains visible', () {
    final categories = [
      category(id: '10', name: 'الذهب'),
      category(id: '11', name: 'أوزان', parent: '10'),
      category(id: '12', name: '5 جرام', parent: '11', count: 3),
    ];

    expect(storefrontRootCategories(categories).single.id, '10');
  });

  test('WooCommerce technical categories are hidden even with products', () {
    final categories = [
      category(id: '1', name: 'غير مصنف', count: 1),
      category(
        id: '2',
        name: 'Uncategorized',
        slug: 'uncategorized',
        count: 2,
      ),
    ];

    expect(storefrontRootCategories(categories), isEmpty);
  });

  test('only real category images are considered usable', () {
    expect(hasUsableCategoryImage(category(id: '1', name: 'A')), isFalse);
    expect(
      hasUsableCategoryImage(
        category(id: '2', name: 'B', image: kDefaultImage),
      ),
      isFalse,
    );
    expect(
      hasUsableCategoryImage(
        category(id: '3', name: 'C', image: 'https://example.com/c.jpg'),
      ),
      isTrue,
    );
  });
}
