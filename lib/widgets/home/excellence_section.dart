import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExcellenceSection extends StatelessWidget {
  const ExcellenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 40,
        horizontal: isSmallScreen ? 12 : 24,
      ),
      child: Column(
        children: [
          // Header Section
          Text(
            'تميــز يليــق بنا',
            textAlign: TextAlign.center,
            style: GoogleFonts.elMessiri(
              fontSize: isSmallScreen ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB18729),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'كل ميزة في متجرنا تعكس حرصنا على تقديم فخامة وجودة وخدمة تفوق توقعاتك.',
              textAlign: TextAlign.center,
              style: GoogleFonts.elMessiri(
                fontSize: isSmallScreen ? 13 : 15,
                color: const Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Alternating Grid
          _buildRow(
            context,
            isSmallScreen: isSmallScreen,
            isImageLeft: false,
            imagePath: 'assets/images/dimoned.png',
            iconPath: 'assets/images/orignal_icon.png',
            title: 'منتجات أصلية وموثوقة',
            description: 'كل القطع مصنوعة من ذهب عيار عالي ومضمونة الجودة.',
          ),
          const SizedBox(height: 20),
          _buildRow(
            context,
            isSmallScreen: isSmallScreen,
            isImageLeft: true,
            imagePath: 'assets/images/bar.png',
            iconPath: 'assets/images/design_icon.png',
            title: 'تصاميم فاخرة ومتنوعة',
            description: 'سبائك، فضة، جنيهات، ومجوهرات تناسب كل الأذواق.',
          ),
          const SizedBox(height: 20),
          _buildRow(
            context,
            isSmallScreen: isSmallScreen,
            isImageLeft: false,
            imagePath: 'assets/images/coin.png',
            iconPath: 'assets/images/shipping_icon.png',
            title: 'تسليم آمن وسريع',
            description:
                'التغليف الفاخر بعناية فائقة ليحافظ على بريق وجودة منتجاتنا، مع خدمة توصيل مضمونة .',
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required bool isSmallScreen,
    required bool isImageLeft,
    required String imagePath,
    required String iconPath,
    required String title,
    required String description,
  }) {
    final imageWidget = ExcellenceImage(imagePath: imagePath);
    final cardWidget = ExcellenceCard(
      isSmallScreen: isSmallScreen,
      iconPath: iconPath,
      title: title,
      description: description,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: isImageLeft ? imageWidget : cardWidget),
          SizedBox(width: isSmallScreen ? 8 : 16),
          Expanded(child: isImageLeft ? cardWidget : imageWidget),
        ],
      ),
    );
  }
}

class ExcellenceCard extends StatelessWidget {
  final bool isSmallScreen;
  final String iconPath;
  final String title;
  final String description;

  const ExcellenceCard({
    super.key,
    required this.isSmallScreen,
    required this.iconPath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: isSmallScreen ? 30 : 40,
            height: isSmallScreen ? 30 : 40,
            fit: BoxFit.contain,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.elMessiri(
              fontSize: isSmallScreen ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.elMessiri(
              fontSize: isSmallScreen ? 10 : 11,
              color: const Color(0xFF666666),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ExcellenceImage extends StatelessWidget {
  final String imagePath;

  const ExcellenceImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gold side accents background
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: 30, // Protrudes from the sides at the bottom
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFD4AF37),
                  Color(0xFFFFD700),
                  Color(0xFFD4AF37),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // Main Image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
