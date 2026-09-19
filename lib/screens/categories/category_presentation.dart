import '../../common/constants.dart';
import '../../models/entities/category.dart';

const _hiddenCategoryNames = <String>{
  'uncategorized',
  'غير مصنف',
};

bool hasUsableCategoryImage(Category category) {
  final image = category.image?.trim();
  return image != null && image.isNotEmpty && image != kDefaultImage;
}

bool isHiddenStoreCategory(Category category) {
  final slug = category.slug?.trim().toLowerCase();
  final name = category.name?.trim().toLowerCase();
  return slug == 'uncategorized' || _hiddenCategoryNames.contains(name);
}

/// Returns customer-facing root categories while preserving the order supplied
/// by the remote app configuration.
///
/// A root remains visible when it contains products directly or through any
/// descendant. Empty legacy categories and WooCommerce's technical
/// "Uncategorized" categories are excluded from the storefront page.
List<Category> storefrontRootCategories(List<Category> categories) {
  final childrenByParent = <String, List<Category>>{};
  for (final category in categories) {
    final parent = category.parent;
    if (parent != null) {
      (childrenByParent[parent] ??= <Category>[]).add(category);
    }
  }

  bool hasProducts(Category category, Set<String> visited) {
    if ((category.totalProduct ?? 0) > 0) return true;
    final id = category.id;
    if (id == null || !visited.add(id)) return false;
    return (childrenByParent[id] ?? const <Category>[])
        .any((child) => hasProducts(child, visited));
  }

  return categories
      .where((category) => category.isRoot)
      .where((category) => !isHiddenStoreCategory(category))
      .where((category) => hasProducts(category, <String>{}))
      .toList(growable: false);
}
