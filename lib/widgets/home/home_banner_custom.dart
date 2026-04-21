import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../menu/maintab_delegate.dart';
import 'glass_shop_button.dart';

class HomeBannerCustom extends StatelessWidget {
  const HomeBannerCustom({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bannerHeight = (size.width * 0.8).clamp(200.0, 450.0);

    return Container(
      width: size.width,
      height: bannerHeight,
      margin: const EdgeInsets.only(bottom: 0),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_banner.png',
              fit: BoxFit.fill,
            ),
          ),
          // Content Overlay
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'كل سبيـــــكة حكايـــة من كنز الصحراء',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.elMessiri(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تشكيلة من سبائك الذهب والفضة والجنيهات المصممة للادخار والاستثمار بثقة وأمان.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.elMessiri(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassShopButton(
                    onTap: () {
                      MainTabControlDelegate.getInstance().tabAnimateTo?.call(1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
