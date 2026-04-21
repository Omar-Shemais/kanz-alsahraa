import 'package:flutter/material.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/entities/product.dart';

class ProductTitle extends StatelessWidget {
  final Product product;
  final bool hide;
  final TextStyle? style;
  final int? maxLines;
  final bool textCenter;

  const ProductTitle({
    super.key,
    required this.product,
    this.style,
    required this.hide,
    this.textCenter = true,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (hide) {
      return const SizedBox();
    }

    var pinnedTag = '';
    if (kAdvanceConfig.pinnedProductTags.isNotEmpty) {
      for (var tag in product.tags) {
        if (kAdvanceConfig.pinnedProductTags.contains(tag.name) ||
            kAdvanceConfig.pinnedProductTags
                .contains(tag.name?.toLowerCase().trim()) ||
            kAdvanceConfig.pinnedProductTags.contains(tag.id)) {
          pinnedTag = tag.name ?? '';

          /// Only show first one tag.
          break;
        }
      }
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text.rich(
              textAlign: TextAlign.right,
              TextSpan(
                children: [
                  if (pinnedTag.isNotEmpty)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF1A1A1A),
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 2.0,
                          horizontal: 4.0,
                        ),
                        margin: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          pinnedTag.upperCaseFirstChar(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  TextSpan(
                    text: product.name,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0,
                    color: const Color(0xFF1A1A1A),
                  ) ??
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0,
                    color: Color(0xFF1A1A1A),
                  ),
            ),
          ),
          if (product.verified ?? false)
            Icon(
              Icons.verified_user,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
        ]);
  }
}
