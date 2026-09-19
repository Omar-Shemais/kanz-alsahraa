import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../../../models/index.dart' show Category;
import 'container_filter.dart';

IconData categoryExpansionIcon(TextDirection direction, bool isExpanded) {
  if (isExpanded) return Icons.keyboard_arrow_down;
  return direction == TextDirection.rtl
      ? Icons.keyboard_arrow_left
      : Icons.keyboard_arrow_right;
}

EdgeInsets categoryHierarchyMargin(TextDirection direction, int level) {
  final isRtl = direction == TextDirection.rtl;
  return EdgeInsets.only(
    left: isRtl ? 15 : 15.0 * level,
    right: isRtl ? 15.0 * level : 15,
    top: 2,
    bottom: 2,
  );
}

class CategoryItem extends StatelessWidget {
  final Category category;
  final bool isParent;
  final bool isSelected;
  final bool isParentOfSelected;
  final bool hasChild;
  final bool isExpanded;
  final Function()? onTap;
  final VoidCallback? onExpand;
  final int level;
  final bool isBlog;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const CategoryItem(
    this.category, {
    this.isParent = false,
    this.isSelected = true,
    this.isParentOfSelected = false,
    this.hasChild = false,
    this.isExpanded = false,
    this.onTap,
    this.onExpand,
    this.padding,
    this.margin,
    this.level = 1,
    this.isBlog = false,
  });

  @override
  Widget build(BuildContext context) {
    var primaryText = Theme.of(context).primaryColor;
    var secondColor = Theme.of(context).colorScheme.secondary;
    final direction = Directionality.of(context);
    final defaultMargin = categoryHierarchyMargin(direction, level);

    return GestureDetector(
      onTap: onTap,
      child: ContainerFilter(
        isSelected: isSelected || isParentOfSelected,
        padding: padding ??
            const EdgeInsets.symmetric(vertical: 13, horizontal: 8.0),
        margin: margin ?? defaultMargin,
        isBlog: isBlog,
        child: Row(
          children: <Widget>[
            Icon(
              Icons.check,
              color: !hasChild && isSelected && !isParentOfSelected
                  ? primaryText
                  : Colors.transparent,
              size: 18,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '${isParent ? S.of(context).seeAll : category.name}  '
                '${category.totalProduct != null && !isParent ? '(${category.totalProduct})' : ''}',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: isSelected || isParentOfSelected
                          ? primaryText
                          : secondColor.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            if (hasChild)
              InkWell(
                onTap: onExpand,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    categoryExpansionIcon(direction, isExpanded),
                    color: isSelected || isParentOfSelected
                        ? primaryText
                        : Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                ),
              ),
            const SizedBox(width: 5)
          ],
        ),
      ),
    );
  }
}
