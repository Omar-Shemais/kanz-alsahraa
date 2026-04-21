import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/brand_layout_model.dart';
import '../../../models/entities/brand.dart';
import '../../../models/entities/filter_product_params.dart';
import '../../../models/index.dart' show Product, ProductModel;
import '../../../widgets/common/background_color_widget.dart';
import '../../../widgets/common/flux_image.dart';
import '../config/product_config.dart';
import '../helper/header_view.dart';
import '../helper/helper.dart';
import 'future_builder.dart';
import 'product_grid.dart';
import 'product_list_default.dart';
import 'product_list_tile.dart';
import 'product_quilted_grid_tile.dart';
import 'product_staggered.dart';

class ProductList extends StatefulWidget {
  final ProductConfig config;
  final bool cleanCache;

  const ProductList({
    required this.config,
    required this.cleanCache,
    super.key,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool isShowCountDown() {
    final isSaleOffLayout = widget.config.layout == Layout.saleOff;
    return widget.config.showCountDown && isSaleOffLayout;
  }

  int getCountDownDuration(List<Product>? data,
      [bool isSaleOffLayout = false]) {
    if (isShowCountDown() &&
        data!.isNotEmpty &&
        (data.first.dateOnSaleTo?.isNotEmpty ?? false)) {
      final dateOnSaleTo = DateTime.tryParse(data.first.dateOnSaleTo!);

      return (dateOnSaleTo?.millisecondsSinceEpoch ?? 0) -
          (DateTime.now().millisecondsSinceEpoch);
    }
    return 0;
  }

  Widget getProductLayout({maxWidth, maxHeight, products}) {
    switch (widget.config.layout) {
      case Layout.listTile:
        return ProductListTitle(
          products: products,
          config: widget.config..showCountDown = isShowCountDown(),
        );
      case Layout.staggered:
        return ProductStaggered(
          products: products,
          width: maxWidth,
          config: widget.config..showCountDown = isShowCountDown(),
        );

      case Layout.quiltedGridTile:
        return ProductQuiltedGridTile(
          products: products,
          width: maxWidth,
          config: widget.config..showCountDown = isShowCountDown(),
        );

      default:
        return widget.config.rows > 1
            ? ProductGrid(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                products: products,
                config: widget.config..showCountDown = isShowCountDown(),
              )
            : ProductListDefault(
                maxWidth: maxWidth,
                products: products,
                config: widget.config..showCountDown = isShowCountDown(),
                scrollController: _scrollController,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecentLayout = widget.config.layout == Layout.recentView;
    final isSaleOffLayout = widget.config.layout == Layout.saleOff;
    Brand? brandByParams;
    var brandLayoutModel =
        Provider.of<BrandLayoutModel>(context, listen: false);
    var brandId = widget.config.advancedParams != null
        ? FilterProductParams.fromJson(widget.config.advancedParams!).brand
        : null;

    if (brandId?.isNotEmpty ?? false) {
      brandByParams = brandLayoutModel.getBrandById(brandId!);
    }

    return ProductFutureBuilder(
      config: widget.config,
      cleanCache: widget.cleanCache,
      child: ({maxWidth, maxHeight, products}) {
        final duration = getCountDownDuration(products, isSaleOffLayout);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.config.image != null && widget.config.image != '')
              BackgroundColorWidget(
                enable: widget.config.enableBackground,
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 8,
                ),
                child: FluxImage(
                  imageUrl: widget.config.image!,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.config.name?.isNotEmpty ?? false)
              HeaderView(
                headerText: widget.config.name ?? '',
                showSeeAll: isRecentLayout ? false : true,
                verticalMargin: 0.0,
                callback: () => ProductModel.showList(
                  brandByParams: brandByParams,
                  config: widget.config.jsonData,
                  products: products,
                  showCountdown: isShowCountDown() && duration > 0,
                  countdownDuration: Duration(milliseconds: duration),
                  context: context,
                ),
                showCountdown: isShowCountDown() && duration > 0,
                countdownDuration: Duration(milliseconds: duration),
                scrollController: _scrollController,
              ),
            getProductLayout(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              products: products,
            ),
          ],
        );
      },
    );
  }
}
