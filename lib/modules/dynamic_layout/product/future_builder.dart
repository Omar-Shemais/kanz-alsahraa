import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../models/index.dart' show Product, RecentModel;
import '../../../models/user_model.dart';
import '../../../services/index.dart';
import '../config/product_config.dart';
import '../helper/helper.dart';
import 'product_empty.dart';
import 'product_layout_session_cache.dart';

/// Handle the product network request, caching and empty product
class ProductFutureBuilder extends StatefulWidget {
  final ProductConfig config;
  final Function child;
  final Widget? waiting;
  final bool cleanCache;

  const ProductFutureBuilder({
    required this.config,
    this.waiting,
    required this.child,
    this.cleanCache = false,
    super.key,
  });

  @override
  State<ProductFutureBuilder> createState() => _ProductListLayoutState();
}

class _ProductListLayoutState extends State<ProductFutureBuilder> {
  ValueNotifier<List<Product>?> productsNotifier = ValueNotifier(null);
  bool _loadFailed = false;

  @override
  void dispose() {
    productsNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (productsNotifier.value != null) {
      return;
    }
    if (widget.config.layout == Layout.recentView) {
      context.read<RecentModel>().getRecentProduct();
      return;
    }
    WidgetsBinding.instance.endOfFrame.then((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    try {
      final products = await getProductLayout(context);
      if (!mounted) return;
      _loadFailed = false;
      productsNotifier.value = products ?? <Product>[];
    } catch (_) {
      if (!mounted) return;
      _loadFailed = true;
      productsNotifier.value = <Product>[];
    }
  }

  Future<List<Product>?> getProductLayout(BuildContext context) async {
    // final startTime = DateTime.now();
    if (widget.config.layout == Layout.recentView) {
      return context.read<RecentModel>().getRecentProduct();
    }
    if (widget.config.layout == Layout.saleOff) {
      /// Fetch only onSale products for saleOff layout.
      widget.config.onSale = true;
    }
    final userId = Provider.of<UserModel>(context, listen: false).user?.id;
    var jsonData = widget.config.jsonData;
    List<Product>? products;
    if (jsonData is Map && jsonData['data'] != null) {
      products = Services().api.productsFromJsonData(jsonData['data']);
    }
    if (products == null) {
      final cacheKey = ProductLayoutSessionCache.keyFor(
        config: widget.config.jsonData,
        userId: userId,
      );
      products = await ProductLayoutSessionCache.getOrLoad(
        key: cacheKey,
        refresh: widget.cleanCache,
        loader: () => Services().api.fetchProductsLayout(
              config: widget.config.jsonData,
              userId: userId,
              refreshCache: widget.cleanCache,
            ),
      );
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final recentProduct = Provider.of<RecentModel>(context).products;
    final isRecentLayout = widget.config.layout == Layout.recentView;
    final isSaleOffLayout = widget.config.layout == Layout.saleOff;
    if (isRecentLayout) {
      productsNotifier.value =
          context.select((RecentModel recentModel) => recentModel.products);
    }
    if (isRecentLayout && recentProduct.length < 3) return const SizedBox();

    return ValueListenableBuilder<List<Product>?>(
        valueListenable: productsNotifier,
        builder: (context, products, child) {
          return LayoutBuilder(
            builder: (context, constraint) {
              var maxWidth = Layout.isDisplayDesktop(context)
                  ? constraint.maxWidth
                  : constraint.maxWidth;

              //Do not include HeaderView height
              var maxHeight = constraint.maxHeight - 50;

              if (products == null) {
                if (widget.waiting != null) return widget.waiting!;

                return widget.config.layout == Layout.listTile
                    ? EmptyProductTile(maxWidth: maxWidth)
                    : widget.config.rows > 1
                        ? EmptyProductGrid(
                            config: widget.config,
                            maxWidth: maxWidth,
                            maxHeight: maxHeight,
                          )
                        : widget.child(
                            maxWidth: maxWidth,
                            maxHeight: maxHeight,
                            products: List.generate(
                                3, (index) => Product.empty(index.toString())),
                          );
              }

              if (_loadFailed && products.isEmpty) {
                return _ProductLoadFailure(
                  title: widget.config.name,
                  onRetry: () {
                    _loadFailed = false;
                    productsNotifier.value = null;
                    _loadProducts();
                  },
                );
              }

              /// Hide sale off layout when product list is empty.
              if (products.isEmpty &&
                  isSaleOffLayout &&
                  kSaleOffProduct.hideEmptySaleOffLayout) {
                return const SizedBox();
              }

              /// Hide section if product list is empty.
              if (widget.config.hideEmptyProductLayout && products.isEmpty) {
                return const SizedBox();
              }

              return widget.child(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                products: products,
              );
            },
          );
        });
  }
}

class _ProductLoadFailure extends StatelessWidget {
  const _ProductLoadFailure({required this.onRetry, this.title});

  final String? title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title?.isNotEmpty ?? false)
            Text(
              title!,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('المنتجات غير متاحة دون اتصال حالياً'),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('إعادة')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
