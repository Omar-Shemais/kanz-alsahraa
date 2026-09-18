import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/common/tools/app_error_handler.dart';
import 'package:fstore/common/tools/tools.dart';
import 'package:fstore/env.dart';
import 'package:fstore/modules/dynamic_layout/helper/header_view.dart';
import 'package:fstore/services/home_config_sources.dart';

void main() {
  test('uploaded WordPress config is active with a packaged Arabic fallback',
      () {
    final source = environment['appConfig'] as String;
    expect(source,
        'https://kanzalsahra.com/wp-content/uploads/flutter_config_files/config_ar.json');
    expect(homeRemoteUrls(source: source, language: 'ar'), [source]);
    expect(homeBundlePaths(source: source, language: 'ar'),
        contains('lib/config/config_ar.json'));
    expect(homeRemoteUrls(source: source, language: 'en').last, source);
  });
  for (final direction in TextDirection.values) {
    testWidgets('navigation mirrors once in $direction', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Directionality(
        textDirection: direction,
        child: Builder(builder: (context) {
          expect(Tools.getBackIcon(context), Icons.arrow_back_ios);
          expect(Tools.getForwardIcon(context), Icons.arrow_forward_ios);
          expect(Tools.getBackIcon(context).matchTextDirection, isTrue);
          return const SizedBox();
        }),
      )));
    });
  }
  for (final brightness in Brightness.values) {
    testWidgets('home and fallback text follow $brightness', (tester) async {
      final theme = ThemeData(brightness: brightness);
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(children: [
              const HeaderView(headerText: 'QA heading'),
              KanzLuxuryErrorWidget(
                  details: FlutterErrorDetails(
                exception: Exception('private_key=secret_customer_phone'),
              )),
            ]),
          )));
      expect(tester.widget<Text>(find.text('QA heading')).style?.color,
          theme.colorScheme.onSurface);
      expect(tester.widget<Text>(find.text('تعذر عرض هذا القسم')).style?.color,
          theme.colorScheme.onSurface);
      expect(find.textContaining('secret_customer_phone'), findsNothing);
    });
  }
  test('guest screen cannot download orders before authentication', () {
    final source =
        File('lib/screens/order_history/views/guest_order_lookup_screen.dart')
            .readAsStringSync();
    expect(source, isNot(contains('getOrderByOrderId')));
    expect(source, isNot(contains('GuestOrderVerifier.verifyMatch')));
  });
  test('customer topic names are not private subscriptions', () {
    final source =
        File('packages/flux_firebase/lib/firebase_notification_service.dart')
            .readAsStringSync();
    final binding = source.substring(source.indexOf('void setExternalId'));
    expect(binding, isNot(contains('.subscribeToTopic(')));
  });
  test('Arabic startup fallback exists', () {
    expect(File('lib/config/config_ar.json').existsSync(), isTrue);
  });
}
