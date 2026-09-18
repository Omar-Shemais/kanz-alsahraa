import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/checkout_preparation.dart';

void main() {
  test('returns a checkout result before the preparation deadline', () async {
    expect(await prepareCheckout(() async => 'url'), 'url');
  });
  test('timeout prevents a late result from opening payment', () async {
    final request = Completer<String>();
    var opened = false;
    final transition = () async {
      final url =
          await prepareCheckout(() => request.future, timeout: Duration.zero);
      opened = url.isNotEmpty;
    }();
    await expectLater(transition, throwsA(isA<TimeoutException>()));
    request.complete('late-url');
    await Future<void>.delayed(Duration.zero);
    expect(opened, false);
    expect(await prepareCheckout(() async => 'retry-url'), 'retry-url');
  });
  test('request failure propagates without automatic order retry', () async {
    var calls = 0;
    await expectLater(prepareCheckout(() async {
      calls++;
      throw StateError('Unavailable');
    }), throwsStateError);
    expect(calls, 1);
  });
}
