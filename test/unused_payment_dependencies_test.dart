import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const removed = [
    'razorpay_flutter',
    'paytm_allinonesdk',
    'flutterwave_standard',
    'flutter_paystack',
    'pay_with_paystack',
    'http_auth',
  ];
  test('removed foreign payment SDKs are absent from dependency graph', () {
    final manifest = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();
    for (final name in removed) {
      expect(RegExp('^  $name:', multiLine: true).hasMatch(manifest), false);
      expect(RegExp('^  $name:', multiLine: true).hasMatch(lock), false);
    }
  });
  test('removed payment SDKs are not registered as native Flutter plugins', () {
    final metadata =
        jsonDecode(File('.flutter-plugins-dependencies').readAsStringSync())
            as Map;
    final plugins = metadata['plugins'] as Map;
    final names = plugins.values
        .expand((value) => value as List)
        .map((plugin) => (plugin as Map)['name']);
    for (final name in removed) {
      expect(names, isNot(contains(name)));
    }
  });
  test('application sources no longer import removed payment packages', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final source in sources) {
      final code = source.readAsStringSync();
      for (final name in removed) {
        expect(code.contains('package:$name/'), false, reason: source.path);
      }
    }
  });
  test('unused foreign payment modules and dispatch branches are removed', () {
    final checkout = File('lib/screens/checkout/mixins/checkout_mixin.dart')
        .readAsStringSync();
    for (final name in [
      'Razor',
      'PayTm',
      'PayStack',
      'Flutterwave',
      'MercadoPago'
    ]) {
      expect(checkout, isNot(contains(name)));
    }
    for (final path in [
      'razorpay/services.dart',
      'razorpay/index.dart',
      'paytm/services.dart',
      'flutterwave/services.dart',
      'paystack/services.dart',
      'mercado_pago/index.dart',
      'mercado_pago/services.dart',
      'paypal/index.dart',
      'paypal/services.dart',
      'credit_card/index.dart',
      'credit_card/credit_card_form.dart',
      'credit_card/credit_card_widget.dart',
      'credit_card/credit_card_payment.dart'
    ]) {
      expect(File('lib/modules/native_payment/$path').existsSync(), false);
    }
    expect(
        File('lib/models/entities/credit_card_new.dart').existsSync(), false);
  });
}
