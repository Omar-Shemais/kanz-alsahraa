import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/app_update_policy.dart';
import 'package:fstore/widgets/common/app_update_gate.dart';

Map<String, dynamic> config(int minimum, {bool enabled = true}) => {
      'KanzControl': {
        'updates': {
          'android': {'enabled': enabled, 'minimumBuild': minimum}
        }
      }
    };

void main() {
  testWidgets('first config arriving after splash captures startup policy',
      (tester) async {
    Widget app(dynamic data) => MaterialApp(
            home: AppUpdateGate(
          config: data,
          platform: TargetPlatform.android,
          readBuild: () async => 22,
          child: const Scaffold(body: Text('app content')),
        ));
    await tester.pumpWidget(app(null));
    await tester.pumpWidget(app(config(23)));
    await tester.pumpAndSettle();
    expect(find.text('app content'), findsNothing);
    expect(find.text('فتح متجر التطبيقات'), findsOneWidget);
  });
  test('minimum build and store destination', () {
    final policy =
        AppUpdatePolicy.fromConfig(config(23), TargetPlatform.android)!;
    expect(policy.requiresUpdate(22), isTrue);
    expect(policy.requiresUpdate(23), isFalse);
    expect(policy.requiresUpdate(24), isFalse);
    expect(policy.storeUrl.queryParameters['id'], 'com.khtwah.kanzalsahra');
    expect(
        AppUpdatePolicy.fromConfig(
            config(23, enabled: false), TargetPlatform.android),
        isNull);
    expect(
        AppUpdatePolicy.fromConfig(config(0), TargetPlatform.android), isNull);
    expect(
        AppUpdatePolicy.fromConfig(config(23), TargetPlatform.windows), isNull);
  });
  testWidgets('older build is blocked and current build can use app',
      (tester) async {
    for (final build in [22, 23]) {
      await tester.pumpWidget(MaterialApp(
          home: AppUpdateGate(
        key: ValueKey(build),
        config: config(23),
        platform: TargetPlatform.android,
        readBuild: () async => build,
        child: const Scaffold(body: Text('app content')),
      )));
      await tester.pumpAndSettle();
      expect(find.text('app content'),
          build == 22 ? findsNothing : findsOneWidget);
      expect(find.text('فتح متجر التطبيقات'),
          build == 22 ? findsOneWidget : findsNothing);
    }
  });
  testWidgets('background config does not interrupt active session',
      (tester) async {
    Widget app(dynamic data) => MaterialApp(
            home: AppUpdateGate(
          config: data,
          platform: TargetPlatform.android,
          readBuild: () async => 22,
          child: const Scaffold(body: Text('payment in progress')),
        ));
    await tester.pumpWidget(app(config(0, enabled: false)));
    await tester.pumpWidget(app(config(23)));
    await tester.pumpAndSettle();
    expect(find.text('payment in progress'), findsOneWidget);
    expect(find.text('فتح متجر التطبيقات'), findsNothing);
  });
  testWidgets('unknown build shows retry without leaking exception',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: AppUpdateGate(
      config: config(23),
      platform: TargetPlatform.android,
      readBuild: () async => throw Exception('secret'),
      child: const Scaffold(body: Text('app content')),
    )));
    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text('app content'), findsNothing);
  });
}
