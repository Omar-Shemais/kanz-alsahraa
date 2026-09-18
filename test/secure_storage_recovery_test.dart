import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/data/secure_storage.dart';
import 'package:fstore/data/storage_recovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  var reads = 0;
  var failures = 0;
  var deletes = 0;
  var failWrite = false;
  var values = <String, String>{};

  setUp(() {
    reads = 0;
    failures = 0;
    deletes = 0;
    failWrite = false;
    values = {'key': 'saved-key'};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map;
      switch (call.method) {
        case 'readAll':
          reads++;
          if (reads <= failures) throw PlatformException(code: 'unavailable');
          return Map.of(values);
        case 'write':
          if (failWrite) throw PlatformException(code: 'unavailable');
          values[args['key'] as String] = args['value'] as String;
          return null;
        case 'deleteAll':
          deletes++;
          values.clear();
          return null;
      }
      throw StateError('Unexpected method ${call.method}');
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  SecureStorage storage(
          {Future<void> Function(Duration)? wait, bool disabled = false}) =>
      SecureStorage.withStorage(
        const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false)),
        wait: wait ?? (_) async {},
        disablePersistence: disabled,
      );

  test('three reads use backoff and preserve the existing key', () async {
    failures = 2;
    final waits = <Duration>[];
    final target = storage(wait: (d) async {
      waits.add(d);
    });
    await target.init();
    expect(reads, 3);
    expect(waits.map((d) => d.inMilliseconds), [300, 600]);
    expect(target.get('key'), 'saved-key');
    expect(deletes, 0);
  });
  test('persistent failure preserves data and allows a later retry', () async {
    failures = 3;
    final target = storage();
    await expectLater(target.init(), throwsA(isA<PlatformException>()));
    expect(() => target.get('key'), throwsStateError);
    expect(deletes, 0);
    expect(values['key'], 'saved-key');
    await target.init();
    expect(target.get('key'), 'saved-key');
  });
  test('concurrent initialization performs one read', () async {
    final target = storage();
    await Future.wait([target.init(), target.init()]);
    await target.init();
    expect(reads, 1);
  });
  test('failed write cannot replace the in-memory encryption key', () async {
    final target = storage();
    await target.init();
    failWrite = true;
    await expectLater(
        target.set('key', 'new'), throwsA(isA<PlatformException>()));
    expect(target.get('key'), 'saved-key');
    failWrite = false;
    await target.set('key', 'new');
    expect(target.get('key'), 'new');
    expect(values['key'], 'new');
  });
  test('disabled persistence avoids keystore access', () async {
    final target = storage(disabled: true);
    await target.init();
    await target.set('temporary', 'value');
    expect(target.get('temporary'), 'value');
    expect(reads, 0);
    expect(values.containsKey('temporary'), false);
  });
  testWidgets(
      'launch failure offers Arabic retry and recovers without deletion',
      (tester) async {
    var attempts = 0;
    final result = initializeStorageWithRecovery(() async {
      attempts++;
      if (attempts == 1) throw StateError('Unavailable');
    });
    await tester.pumpAndSettle();
    expect(find.text('تعذر فتح البيانات المحفوظة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    await result;
    expect(attempts, 2);
    expect(deletes, 0);
  });
}
