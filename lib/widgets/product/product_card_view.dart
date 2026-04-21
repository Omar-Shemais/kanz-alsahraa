import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../common/tools.dart';
import '../../models/index.dart' show CartModel, Product;
import '../../modules/dynamic_layout/config/product_config.dart';
import '../../modules/dynamic_layout/helper/helper.dart';
import '../../services/outside/index.dart';
import '../../services/services.dart';
import 'action_button_mixin.dart';
import 'index.dart'
    show
        CartButton,
        CartIcon,
        CartQuantity,
        HeartButton,
        ProductImage,
        ProductOnSale,
        ProductPricing,
        ProductRating,
        ProductTitle,
        SaleProgressBar,
        StockStatus,
        StoreName;
import 'widgets/availability_badge.dart';
import 'widgets/payment_icons_row.dart';
import 'widgets/cart_button_with_quantity.dart';

class ProductCard extends StatefulWidget {
  final Product item;
  final double? width;
  final double? maxWidth;
  final bool hideDetail;
  final offset;
  final ProductConfig config;
  final onTapDelete;

  const ProductCard({
    required this.item,
    this.width,
    this.maxWidth,
    this.offset,
    this.hideDetail = false,
    required this.config,
    this.onTapDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with ActionButtonMixin {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final width = (widget.maxWidth != null &&
            widget.width != null &&
            widget.width! > widget.maxWidth!)
        ? widget.maxWidth!
        : (widget.width ??
            Layout.buildProductMaxWidth(
                context: context, layout: widget.config.layout));

    /// use for Staged layout
    if (widget.hideDetail) {
      return ProductImage(
        width: width,
        product: widget.item,
        config: widget.config,
        ratioProductImage: widget.config.imageRatio,
        offset: widget.offset,
        onTapProduct: () =>
            onTapProduct(context, product: widget.item, config: widget.config),
      );
    }

    Widget productInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        ProductTitle(
          product: widget.item,
          hide: widget.config.hideTitle,
          maxLines: widget.config.titleLine,
        ),
        StoreName(product: widget.item, hide: widget.config.hideStore),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ProductPricing(
                          product: widget.item,
                          hide: widget.config.hidePrice,
                          color: widget.config.priceColor,
                        ),
                        const SizedBox(height: 8),
                        StockStatus(
                            product: widget.item, config: widget.config),
                        SaleProgressBar(
                          width: widget.width,
                          product: widget.item,
                          show: widget.config.showCountDown,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        CartQuantity(
          product: widget.item,
          config: widget.config,
          onChangeQuantity: (val) {
            setState(() {
              _quantity = val;
            });
          },
        ),
        if (widget.config.showCartButton &&
            Services().widget.enableShoppingCart(widget.item)) ...[
          const SizedBox(height: 4),
          CartButton(
            product: widget.item,
            hide: !widget.item.canBeAddedToCartFromList(
                enableBottomAddToCart: widget.config.enableBottomAddToCart),
            enableBottomAddToCart: widget.config.enableBottomAddToCart,
            quantity: _quantity,
          ),
        ],
        OutsideService.subProductCardInfoWidget(widget.item) ??
            const SizedBox(),
        const SizedBox(height: 6),
      ],
    );

    return GestureDetector(
      onTap: () =>
          onTapProduct(context, product: widget.item, config: widget.config),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(maxWidth: widget.maxWidth ?? width),
        width: widget.width!,
        margin: EdgeInsets.symmetric(
          horizontal: widget.config.hMargin /
              2, // Halved for tighter gaps between columns
          vertical: widget.config.vMargin,
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: const Color(0xFFB18729),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    offset: Offset(0, 2),
                    blurRadius: 8.0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(widget.config.borderRadius ?? 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(widget.config.borderRadius ?? 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              var ratio = widget.config.imageRatio ?? 1.2;
                              // Match the 1-column logic for dynamically assigned large widths
                              if ((widget.maxWidth ?? width) > 300 &&
                                  widget.config.layout != 'pinterest') {
                                ratio = widget.config.imageRatio ?? 0.8;
                              }
                              // Cap ratio for slider layouts to prevent excessive vertical height
                              if (widget.config.layout == 'oneAndHalfColumn' ||
                                  widget.config.layout == 'recent_view' ||
                                  widget.config.layout == 'saleOff') {
                                ratio = 0.8;
                              }
                              var imageHeight = width * ratio;

                              if (widget.config.layout == 'pinterest') {
                                imageHeight = 200.0;
                              }

                              return ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxHeight: imageHeight),
                                child: SizedBox(
                                  height: imageHeight,
                                  width: double.infinity,
                                  child: ProductImage(
                                    width: width,
                                    product: widget.item,
                                    fit: BoxFit.cover,
                                    config: widget.config,
                                    ratioProductImage: widget.config.imageRatio,
                                    offset: widget.offset,
                                    onTapProduct: () => onTapProduct(context,
                                        product: widget.item,
                                        config: widget.config),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: AvailabilityBadge(product: widget.item),
                          ),
                          const Positioned(
                            bottom: 8,
                            left: 8,
                            child: PaymentIconsRow(),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (widget.config.hPadding ?? 10.0) + 4.0,
                          vertical: widget.config.vPadding,
                        ),
                        child: Center(child: productInfo),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            ProductOnSale(
              product: widget.item,
              config: widget.config,
              margin: const EdgeInsets.all(0),
            ),
            if (widget.config.showHeart && !widget.item.isEmptyProduct())
              Positioned(
                right: context.isRtl ? null : widget.config.hMargin,
                left: context.isRtl ? widget.config.hMargin : null,
                child: HeartButton(
                  product: widget.item,
                  size: 18,
                ),
              ),
            if (widget.onTapDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: widget.onTapDelete,
                ),
              )
          ],
        ),
      ),
    );
  }
}
