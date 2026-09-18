import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Never report raw exception messages, URLs, cookies, order/customer data.
/// Collection is explicit and there is no user-ID attribution here.
class AppTelemetry {
  static bool _ready = false;
  static Trace? _startup;

  static Future<void> initialize() async {
    if (_ready || kIsWeb) return;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    await FirebaseAnalytics.instance.setDefaultEventParameters({
      'kanz_source': 'mobile_app',
      'kanz_platform': defaultTargetPlatform.name,
    });
    _ready = true;
    _startup =
        FirebasePerformance.instance.newTrace('kanz_startup_after_firebase');
    await _startup!.start();
  }

  static Future<void> firstFrame() async {
    if (!_ready) return;
    final startup = _startup;
    _startup = null;
    await startup?.stop();
    await FirebaseAnalytics.instance.logEvent(name: 'kanz_app_ready');
    if (kDebugMode && const bool.fromEnvironment('KANZ_TELEMETRY_SMOKE')) {
      await FirebaseAnalytics.instance.logEvent(name: 'kanz_monitoring_check');
      await FirebaseCrashlytics.instance.recordError(
        StateError('Kanz monitoring smoke check — no customer data'),
        StackTrace.current,
        reason: 'kanz_monitoring_check',
        fatal: false,
        printDetails: false,
      );
      await measure('kanz_monitoring_check', () async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      debugPrint(
          '[Telemetry] Analytics, nonfatal and trace smoke check recorded.');
    }
  }

  /// A code-duration trace, not a claim to measure every native HTTP request.
  /// No URL, request headers, search terms or customer values are attached.
  static Future<T> measure<T>(
      String name, Future<T> Function() operation) async {
    Trace? trace;
    if (_ready &&
        const {'kanz_catalog_request', 'kanz_monitoring_check'}
            .contains(name)) {
      try {
        trace = FirebasePerformance.instance.newTrace(name);
        await trace.start();
      } catch (_) {
        trace = null;
      }
    }
    try {
      final result = await operation();
      trace?.incrementMetric('success', 1);
      return result;
    } finally {
      try {
        await trace?.stop();
      } catch (_) {}
    }
  }

  static void report(Object error, StackTrace stack, {required bool fatal}) {
    if (!_ready) return;
    unawaited(FirebaseCrashlytics.instance
        .recordError(
          // Type only: exception.toString() can leak authenticated URLs/PII.
          'Kanz ${error.runtimeType}', stack,
          fatal: fatal, printDetails: false,
        )
        .catchError((Object _) {}));
  }
}
