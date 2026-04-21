import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../models/entities/product.dart';
import '../action_button_mixin.dart';

class CartButton extends StatelessWidget with ActionButtonMixin {
  final Product product;
  final bool hide;
  final int quantity;
  final bool enableBottomAddToCart;

  const CartButton({
    super.key,
    required this.product,
    required this.hide,
    this.enableBottomAddToCart = false,
    this.quantity = 1,
  });

  @override
  Widget build(BuildContext context) {
    var inStock = product.inStock ?? true;

    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFB18729),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          // minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () => onTapProduct(
          context,
          product: product,
        ),
        child: Text(
          inStock ? S.of(context).addToCart : 'قراءة المزيد',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
