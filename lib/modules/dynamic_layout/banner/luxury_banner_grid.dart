import 'package:flutter/material.dart';
import '../config/banner_config.dart';
import 'banner_items.dart';

class LuxuryBannerGrid extends StatelessWidget {
  final BannerConfig config;
  final Function onTap;

  const LuxuryBannerGrid({
    super.key,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final items = config.items;
    final bannerHeight = config.height != null
        ? config.height! * screenSize.height
        : screenSize.width * 0.9;

    return Container(
      width: screenSize.width,
      height: bannerHeight,
      margin: EdgeInsets.only(
        left: config.marginLeft,
        right: config.marginRight,
        top: config.marginTop,
        bottom: config.marginBottom,
      ),
      decoration: BoxDecoration(
        image: config.imageBanner != null
            ? DecorationImage(
                image: config.imageBanner!.startsWith('http')
                    ? NetworkImage(config.imageBanner!) as ImageProvider
                    : AssetImage(config.imageBanner!),
                fit: BoxFit.cover, // ← was fitWidth; cover fills better
                alignment: Alignment.topCenter,
              )
            : null,
        color: config.imageBanner == null ? const Color(0xFF1A1209) : null,
      ),
      child: Column(
        children: [
          // ── Title ──────────────────────────────────────────────────
          if (config.title != null || config.text != null)
            Container(
              padding: const EdgeInsets.only(
                  top: 72, bottom: 12, left: 20, right: 20),
              alignment: Alignment.center,
              child: Text(
                config.title?.title ?? config.text ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal',
                  height: 1.3,
                ),
              ),
            ),

          // ── Grid ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: config.padding,
                vertical: 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Large right item (woman / hero image) ──────────
                  if (items.isNotEmpty)
                    Expanded(
                      flex: 5,
                      child: _buildLargeItem(items[0], context),
                    ),

                  const SizedBox(width: 6),

                  // ── Two small left items ───────────────────────────
                  if (items.length >= 3)
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildSmallItem(items[1], context),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: _buildSmallItem(items[2], context),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ─────────────────────────────────────────────
          // GestureDetector(
          //   onTap: () {
          //     if (items.isNotEmpty) onTap(items[0].toJson());
          //   },
          //   child: Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(vertical: 14),
          //     alignment: Alignment.center,
          //     child: const Text(
          //       'اكتشفي بريقك الخاص',
          //       style: TextStyle(
          //         color: Color(0xFFB18729),
          //         fontSize: 15,
          //         fontWeight: FontWeight.bold,
          //         fontFamily: 'Tajawal',
          //         letterSpacing: 0.3,
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  // Large item — no label, just image fills height
  Widget _buildLargeItem(BannerItemConfig itemConfig, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(config.radius),
      child: GestureDetector(
        onTap: () => onTap(itemConfig.toJson()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(itemConfig.image ?? '', BoxFit.cover),
          ],
        ),
      ),
    );
  }

  // Small items — image + category label at bottom
  Widget _buildSmallItem(BannerItemConfig itemConfig, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(config.radius),
      child: GestureDetector(
        onTap: () => onTap(itemConfig.toJson()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(itemConfig.image ?? '', BoxFit.cover),

            // Dark gradient at bottom for readability
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url, BoxFit fit) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: fit);
    }
    return Image.asset(url, fit: fit);
  }
}
