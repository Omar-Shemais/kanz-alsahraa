import 'package:flutter/material.dart';
import '../../../generated/l10n.dart';
import '../../../models/entities/product.dart';

class AvailabilityBadge extends StatelessWidget {
  final Product product;
  const AvailabilityBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool outOfStock =
        product.inStock == false && (product.backordersAllowed == false);

    if (!outOfStock) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB18729), // Kanz Gold
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        S.of(context).outOfStock.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
