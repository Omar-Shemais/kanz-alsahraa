import 'package:flutter/material.dart';
import '../../../widgets/common/flux_image.dart';

class PaymentIconsRow extends StatelessWidget {
  const PaymentIconsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon('assets/icons/credit_cards/visa.png', label: 'Visa'),
        const SizedBox(width: 4),
        _buildIcon('assets/icons/credit_cards/mastercard.png', label: 'Mastercard'),
        const SizedBox(width: 4),
        _buildIcon('assets/icons/credit_cards/visa.png', label: 'Payment'), 
      ],
    );
  }

  Widget _buildIcon(String path, {String? label}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FluxImage(
        imageUrl: path,
        width: 24,
        fit: BoxFit.contain,
      ),
    );
  }
}
