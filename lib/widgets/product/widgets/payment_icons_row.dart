import 'package:flutter/material.dart';
import '../../../widgets/common/flux_image.dart';

class PaymentIconsRow extends StatelessWidget {
  const PaymentIconsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon('assets/icons/payment/visa.png'),
        const SizedBox(width: 4),
        _buildIcon('assets/icons/payment/mastercard.png'),
        const SizedBox(width: 4),
        // _buildIcon('https://upload.wikimedia.org/wikipedia/commons/e/e0/Mada_Logo.svg'),
        _buildIcon('assets/icons/payment/visa.png'), // Placeholder or just remove
      ],
    );
  }

  Widget _buildIcon(String path) {
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
