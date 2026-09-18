import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/app_telemetry.dart';

void main() {
  test('telemetry unavailable does not change successful operation', () async {
    expect(
        await AppTelemetry.measure('kanz_catalog_request', () async => 42), 42);
  });
  test('telemetry unavailable preserves operation error', () async {
    final failure = StateError('local test only');
    await expectLater(
        AppTelemetry.measure<void>(
            'kanz_catalog_request', () async => throw failure),
        throwsA(same(failure)));
  });
  test('reporting before Firebase readiness does not crash app', () {
    AppTelemetry.report(StateError('local test only'), StackTrace.current,
        fatal: false);
  });
}
