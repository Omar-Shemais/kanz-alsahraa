import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/common/theme/dark_theme.dart';
import 'package:fstore/modules/dynamic_layout/config/app_setting.dart';
import 'package:fstore/modules/dynamic_layout/config/banner_config.dart';

void main() {
  double contrast(Color foreground, Color background) {
    final lighter =
        foreground.computeLuminance() > background.computeLuminance()
            ? foreground.computeLuminance()
            : background.computeLuminance();
    final darker = foreground.computeLuminance() > background.computeLuminance()
        ? background.computeLuminance()
        : foreground.computeLuminance();
    return (lighter + 0.05) / (darker + 0.05);
  }

  group('remote appearance configuration', () {
    test('supports dark and light defaults with legacy fallback', () {
      expect(
        AppSetting.fromJson({'DefaultTheme': 'dark'}).defaultDarkTheme,
        isTrue,
      );
      expect(
        AppSetting.fromJson({'DefaultTheme': 'light'}).defaultDarkTheme,
        isFalse,
      );
      expect(
        AppSetting.fromJson({'DefaultDarkTheme': true}).defaultDarkTheme,
        isTrue,
      );
      expect(AppSetting.fromJson({}).defaultDarkTheme, isNull);
    });

    test('dark theme keeps primary text and controls readable', () {
      final theme = buildDarkTheme(
        'ar',
        'KanzTestBodyFont',
        'KanzTestHeaderFont',
        false,
      );
      final textColor = theme.textTheme.bodyMedium!.color!;

      expect(theme.brightness, Brightness.dark);
      expect(
          contrast(textColor, theme.scaffoldBackgroundColor), greaterThan(4.5));
      expect(contrast(textColor, theme.cardColor), greaterThan(4.5));
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.dialogTheme.backgroundColor, theme.scaffoldBackgroundColor);
    });

    test('bundled home layout keeps banners and category carousel harmonious',
        () {
      final root =
          jsonDecode(File('lib/config/config_ar.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(root['Setting']['DefaultTheme'], 'light');

      final layouts = root['HorizonLayout'] as List<dynamic>;
      final firstBanner = layouts[1] as Map<String, dynamic>;
      final secondBanner = layouts[2] as Map<String, dynamic>;
      final categoryCarousel = layouts[3] as Map<String, dynamic>;

      for (final banner in [firstBanner, secondBanner]) {
        expect(banner['layout'], 'bannerImage');
        expect(banner['marginLeft'], 12);
        expect(banner['marginRight'], 12);
        expect(banner['radius'], 12);
        expect(banner['items'][0]['radius'], 12);
      }

      expect(categoryCarousel['layout'], 'bannerImage');
      expect(categoryCarousel['design'], 'swiper');
      expect(categoryCarousel['viewportFraction'], 0.72);
      expect(categoryCarousel['showIndicator'], isTrue);

      final parsed = BannerConfig.fromJson(categoryCarousel);
      expect(parsed.viewportFraction, 0.72);
      expect(parsed.showIndicator, isTrue);
    });
  });
}
