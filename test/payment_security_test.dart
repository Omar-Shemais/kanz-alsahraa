import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/env.dart';

void main() {
  group('Payment & Security Configuration (Problems 5, 7, 13, 30, 37)', () {
    test('verifies application package identifier is unified', () {
      final appRating = environment['appRatingConfig'] as Map<String, dynamic>;
      expect(appRating['android'], 'com.khtwah.kanzalsahra');
    });

    test('verifies foreign payment gateways are disabled', () {
      expect(environment['razorpayConfig']['enabled'], false);
      expect(environment['tapConfig']['enabled'], false);
      expect(environment['mercadoPagoConfig']['enabled'], false);
      expect(environment['payTmConfig']['enabled'], false);
      expect(environment['payStackConfig']['enabled'], false);
      expect(environment['flutterwaveConfig']['enabled'], false);
      expect(environment['myFatoorahConfig']['enabled'], false);
      expect(environment['midtransConfig']['enabled'], false);
      expect(environment['stripeConfig']['enabled'], false);
      expect(environment['paypalConfig']['enabled'], false);
      expect(environment['paypalExpressConfig']['enabled'], false);
      expect(environment['xenditConfig']['enabled'], false);
      expect(environment['thaiPromptPayConfig']['enabled'], false);
      expect(environment['thawaniConfig']['enabled'], false);
    });

    test('verifies test API keys are not exposed in foreign configs', () {
      expect(environment['razorpayConfig']['keyId'], isEmpty);
      expect(environment['razorpayConfig']['keySecret'], isEmpty);
      expect(environment['tapConfig']['SecretKey'], isEmpty);
      expect(environment['stripeConfig']['publishableKey'], isEmpty);
      expect(environment['paypalConfig']['clientId'], isEmpty);
      expect(environment['thawaniConfig']['secretKey'], isEmpty);
    });

    test('verifies in-app webview cache and cookie auto-clear on logout', () {
      final advanceConfig =
          environment['advanceConfig'] as Map<String, dynamic>;
      expect(advanceConfig['AlwaysClearWebViewCache'], true);
      expect(advanceConfig['AlwaysClearWebViewCookie'], true);
    });

    test('verifies store policy on orders and guest checkout', () {
      final paymentConfig =
          environment['paymentConfig'] as Map<String, dynamic>;
      expect(paymentConfig['GuestCheckout'], false);
      expect(paymentConfig['EnableRefundCancel'], false);
      expect(paymentConfig['EnableOnePageCheckout'], false);
    });
  });
}
