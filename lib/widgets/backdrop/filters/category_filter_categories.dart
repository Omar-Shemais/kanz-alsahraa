import '../../../models/entities/category.dart';

/// Applies the administrator's filter-specific order and visibility without
/// changing the WooCommerce taxonomy or the separate Categories tab order.
List<Category> arrangeFilterCategories(
  List<Category> categories,
  List<String>? configuredIds,
) {
  if (configuredIds == null) return List<Category>.from(categories);

  final byId = <String, Category>{
    for (final category in categories)
      if (category.id != null) category.id!: category,
  };
  final result = <Category>[];
  final seen = <String>{};
  for (final id in configuredIds) {
    final category = byId[id];
    if (category != null && seen.add(id)) result.add(category);
  }
  return result;
}

bool categoryContainsSelection(
  List<Category> categories,
  String? ancestorId,
  Set<String> selectedIds,
) {
  if (ancestorId == null || selectedIds.isEmpty) return false;
  final children = <String, List<String>>{};
  for (final category in categories) {
    final id = category.id;
    final parent = category.parent;
    if (id == null || parent == null) continue;
    children.putIfAbsent(parent, () => <String>[]).add(id);
  }
  final pending = <String>[ancestorId];
  final visited = <String>{};
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    if (!visited.add(current)) continue;
    for (final child in children[current] ?? const <String>[]) {
      if (selectedIds.contains(child)) return true;
      pending.add(child);
    }
  }
  return false;
}
