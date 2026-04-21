import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassShopButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const GlassShopButton({
    super.key,
    required this.onTap,
    this.text = 'تسوق الان',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.32,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          // Exact Figma Fill: #F0F0F0 30-35%
          color: const Color(0x59F0F0F0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D919191),
              offset: Offset(-2.42, 4.84),
              blurRadius: 12.11,
            ),
            BoxShadow(
              color: Color(0x0A919191),
              offset: Offset(-8.48, 20.58),
              blurRadius: 21.8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.21, sigmaY: 24.21),
            child: CustomPaint(
              painter: _FigmaAngularBorderPainter(),
              child: Center(
                child: Text(
                  text,
                  style: GoogleFonts.elMessiri(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaAngularBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = 15.0;
    const strokeWidth = 1.21;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      const Radius.circular(radius),
    );

    // EXACT Figma 8-stop Angular Gradient
    final gradient = SweepGradient(
      startAngle: -1.5708,
      endAngle: 4.7124,
      colors: const [
        Color(0x809C9C9C), // #9C9C9C 50%
        Color(0x599C9C9C), // #9C9C9C 35%
        Color(0x80FFFFFF), // #FFFFFF 50%
        Color(0x80FFFFFF), // #FFFFFF 50%
        Color(0x599C9C9C), // #9C9C9C 35%
        Color(0xFFF9F9F9), // #F9F9F9 100%
        Color(0x80FFFFFF), // #FFFFFF 50%
        Color(0x80F9F9F9), // #F9F9F9 50%
      ],
      stops: const [0.0, 0.14, 0.28, 0.42, 0.56, 0.70, 0.84, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
