import 'package:flutter/material.dart';

import '../../../common/config.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show Product;
import '../../../modules/dynamic_layout/config/product_config.dart';

class StockStatus extends StatelessWidget {
  final Product product;
  final ProductConfig config;

  const StockStatus({
    super.key,
    required this.product,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
