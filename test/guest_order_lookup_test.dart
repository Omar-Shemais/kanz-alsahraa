import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/entities/address.dart';
import 'package:fstore/models/order/order.dart';
import 'package:fstore/services/guest_order_verifier.dart';

void main() {
  group('Guest Order Lookup Security Verification (Problem 26 / T024)', () {
    test('normalizes various Saudi phone number formats consistently', () {
      expect(GuestOrderVerifier.normalizePhone('0512345678'), '512345678');
      expect(GuestOrderVerifier.normalizePhone('+966512345678'), '512345678');
      expect(GuestOrderVerifier.normalizePhone('00966512345678'), '512345678');
      expect(GuestOrderVerifier.normalizePhone('966512345678'), '512345678');
      expect(GuestOrderVerifier.normalizePhone('051-234-5678'), '512345678');
    });

    test('verifies order ownership via phone number across format variations',
        () {
      final order = Order()
        ..id = '1001'
        ..billing = Address(phoneNumber: '0512345678');

      // Matching queries
      expect(
          GuestOrderVerifier.verifyMatch(
            order: order,
            verificationInput: '0512345678',
          ),
          isTrue);

      expect(
          GuestOrderVerifier.verifyMatch(
            order: order,
            verificationInput: '+966512345678',
          ),
          isTrue);

      expect(
          GuestOrderVerifier.verifyMatch(
            order: order,
            verificationInput: '512345678',
          ),
          isTrue);

      // Mismatched query
      expect(
          GuestOrderVerifier.verifyMatch(
            order: order,
            verificationInput: '0599999999',
          ),
          isFalse);
    });

    test('verifies order ownership via billing email case-insensitively', () {
      final order = Order()
        ..id = '1002'
        ..billing = Address(email: 'Omar.Shemais@Kanzalsahra.com');

      expect(
          GuestOrderVerifier.verifyMatch(
            order: order,
            verificationInput: 'omar.shemais@kanzalsahra.com',
          ),
          isTrue);

      expect(
          GuestOrderVerifier.verifyMatch(
            order: order,
            verificationInput: 'other.user@kanzalsahra.com',
          ),
          isFalse);
    });

    test('rejects empty, null or invalid inputs securely', () {
      final orderWithBilling = Order()
        ..id = '1003'
        ..billing =
            Address(phoneNumber: '0512345678', email: 'test@domain.com');

      expect(
          GuestOrderVerifier.verifyMatch(
            order: orderWithBilling,
            verificationInput: '',
          ),
          isFalse);

      expect(
          GuestOrderVerifier.verifyMatch(
            order: orderWithBilling,
            verificationInput: '   ',
          ),
          isFalse);

      final orderWithoutBilling = Order()..id = '1004';
      expect(
          GuestOrderVerifier.verifyMatch(
            order: orderWithoutBilling,
            verificationInput: '0512345678',
          ),
          isFalse);
    });
  });
}
