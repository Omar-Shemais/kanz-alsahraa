import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/tools/navigate_tools.dart';
import '../../menu/maintab_delegate.dart';
import 'glass_shop_button.dart';

class InvestmentSection extends StatelessWidget {
  const InvestmentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      width: double.infinity,
      color: const Color(0xF2202020),
      padding: EdgeInsets.symmetric(
        vertical: 60,
        horizontal: isSmallScreen ? 16 : 24,
      ),
      child: Column(
        children: [
          Text(
            'استثمـــار آمــن على المدى الطويــل',
            textAlign: TextAlign.center,
            style: GoogleFonts.elMessiri(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تشكيلة من سبائك الذهب والفضة والجنيهات المصممة للادخار والاستثمار بثقة وأمان.',
            textAlign: TextAlign.center,
            style: GoogleFonts.elMessiri(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          GlassShopButton(
            onTap: () {
              NavigateTools.onTapNavigateOptions(
                context: context,
                config: {'category': 124},
              );
            },
          ),
          const SizedBox(height: 48),
          _buildInvestImage(),
        ],
      ),
    );
  }

  Widget _buildInvestImage() {
    return Stack(
      children: [
        // Main Image
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/invest.png',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        // Gold Indicator (L-shape bottom right)
        Positioned(
          bottom: -10,
          right: -10,
          child: Container(
            width: 140,
            height: 100,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE6CF8A), width: 10),
                right: BorderSide(color: Color(0xFFC7AC54), width: 10),
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
