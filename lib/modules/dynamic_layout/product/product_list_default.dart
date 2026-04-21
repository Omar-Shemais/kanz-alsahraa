import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools.dart';
import '../../../models/index.dart' show AppModel;
import '../../../services/index.dart';
import '../../../widgets/common/auto_silde_show.dart';
import '../../../widgets/common/background_color_widget.dart';
import '../../../widgets/common/flex_separated.dart';
import '../../../widgets/common/index.dart';
import '../../../widgets/common/parallax_image.dart';
import '../config/product_config.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import '../helper/custom_physic.dart';
import '../helper/helper.dart';

const _widthPercentForWebLayout = 0.32;

class ProductListDefault extends StatelessWidget {
  final maxWidth;
  final products;
  final int? row;
  final ProductConfig config;
  final Color? background;
  final ScrollController? scrollController;

  const ProductListDefault({
    super.key,
    this.maxWidth,
    this.products,
    this.row = 1,
    required this.config,
    this.background,
    this.scrollController,
  });

  List<Widget> renderProduct(BuildContext context,
      {bool enableBackground = false}) {
    final isDesktop = Layout.isDisplayDesktop(context);
    var ratioProductImage =
        Provider.of<AppModel>(context, listen: false).ratioProductImage;

    /// allow override imageRatio when there is single Row
    if (config.rows == 1) {
      ratioProductImage = config.imageRatio;
    }

    var layout = config.layout ?? Layout.threeColumn;

    var width = isDesktop
        ? maxWidth * _widthPercentForWebLayout
        : Layout.buildProductWidth(
            screenWidth: maxWidth,
            layout: layout,
          );

    if (isDesktop) {
      return [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Services().widget.renderProductCardView(
                  item: products[i],
                  width: width,
                  maxWidth: maxWidth,
                  ratioProductImage: ratioProductImage,
                  config: config..showHeart = true,
                  useDesktopStyle: true,
                ),
          )
      ];
    }

    return [
      if (enableBackground)
        SizedBox(
          width:
              config.spaceWidth != null ? config.spaceWidth?.toDouble() : width,
        ),
      for (var i = 0; i < products.length; i++)
        Services().widget.renderProductCardView(
              item: products[i],
              width: width,
              maxWidth: maxWidth,
              ratioProductImage: ratioProductImage,
              config: config,
            )
    ];
  }

  Widget renderHorizontal(BuildContext context,
      {bool enableBackground = false}) {
    final padding = enableBackground ||
            config.cardDesign.isSimpleCard ||
            config.cardDesign.isFlat
        ? 0.0
        : 12.0;
    var horizontalWidth = maxWidth - padding;
    var layout = config.layout ?? Layout.threeColumn;
    var controller = scrollController ?? ScrollController();
    final listProducts = products is List ? (products as List) : [];

    /// wrap the product for Desktop mode
    if (Layout.isDisplayDesktop(context)) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16,
        ),
        child: FlexSeparated.row(
          separationSize: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: renderProduct(context, enableBackground: enableBackground),
        ),
      );
    }

    final cardWidth = Layout.buildProductWidth(
        screenWidth: horizontalWidth, layout: layout);

    final body = Container(
      color: background ??
          Theme.of(context)
              .colorScheme
              .surface
              .withOpacity(enableBackground ? 0.0 : 1.0),
      padding: EdgeInsetsDirectional.only(start: padding),
      constraints: BoxConstraints(
        maxHeight: (config.productListItemHeight ?? 0) > 0 
            ? config.productListItemHeight! 
            : Layout.buildProductHeight(layout: layout, defaultHeight: 180),
        minHeight: (config.productListItemHeight ?? 0) > 0 
            ? config.productListItemHeight! 
            : Layout.buildProductHeight(layout: layout, defaultHeight: 180),
      ),
      child: (config.isSnapping ?? false) && listProducts.length > 1
          ? InfiniteCarousel.builder(
              itemCount: listProducts.length,
              itemExtent: cardWidth + 16,
              controller: InfiniteScrollController(),
              axisDirection: Axis.horizontal,
              itemBuilder: (context, itemIndex, realIndex) {
                final productWidgets =
                    renderProduct(context, enableBackground: enableBackground);
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: productWidgets[itemIndex],
                );
              },
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: controller,
              padding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 8,
              ),
              physics: config.isSnapping ?? false
                  ? CustomScrollPhysic(
                      width: Layout.buildProductWidth(
                          screenWidth: horizontalWidth, layout: layout))
                  : const ScrollPhysics(),
              child: FlexSeparated.row(
                separationSize: 16,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    renderProduct(context, enableBackground: enableBackground),
              ),
            ),
    );

    return HandleAutoSlide.list(
      enable: config.enableAutoSliding,
      durationAutoSliding: config.durationAutoSliding,
      numberOfItems: listProducts.length,
      controller: controller,
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (products == null) return const SizedBox();

    var haveCustomBackground =
        config.backgroundImage != null || config.backgroundColor != null;
    var backgroundHeight = config.backgroundHeight?.toDouble();
    var backgroundWidth = (config.backgroundWidthMode ?? false)
        ? maxWidth
        : config.backgroundWidth?.toDouble();

    var body =
        renderHorizontal(context, enableBackground: haveCustomBackground);

    if (haveCustomBackground) {
      body = Stack(
        children: [
          if (config.backgroundColor != null)
            Container(
              height: backgroundHeight ??
                  Layout.buildProductHeight(
                    layout: config.layout ?? Layout.threeColumn,
                    defaultHeight: maxWidth,
                  ),
              width: backgroundWidth,
              margin: config.marginBGP,
              decoration: BoxDecoration(
                color: config.backgroundColor,
                borderRadius: BorderRadius.circular(config.backgroundRadius),
              ),
            ),
          if (config.backgroundImage != null)
            Container(
              margin: config.marginBGP,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(config.backgroundRadius),
                child: config.enableParallax
                    ? ParallaxImage(
                        image: config.backgroundImage!,
                        fit: ImageTools.boxFit(config.backgroundBoxFit),
                        height: backgroundHeight,
                        ratio: config.parallaxImageRatio,
                        width: backgroundWidth,
                      )
                    : FluxImage(
                        imageUrl: config.backgroundImage!,
                        fit: ImageTools.boxFit(config.backgroundBoxFit),
                        height: backgroundHeight,
                        width: backgroundWidth,
                      ),
              ),
            ),
          Padding(
            padding: config.paddingBGP ?? EdgeInsets.zero,
            child: body,
          ),
        ],
      );
    }

    return BackgroundColorWidget(
      enable: config.enableBackground,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: body,
      ),
    );
  }
}
