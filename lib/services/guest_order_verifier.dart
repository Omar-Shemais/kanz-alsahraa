import '../models/order/order.dart';

class GuestOrderVerifier {
  /// Normalizes phone number digits by stripping non-digit characters
  /// and common Saudi international/local prefixes (+966, 00966, 0).
  static String normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00966')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('966')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Compares contact strings only. This is NOT ownership authentication and
  /// must never authorize an order fetch or expose customer data to guests.
  static bool verifyMatch({
    required Order order,
    required String verificationInput,
  }) {
    final input = verificationInput.trim();
    if (input.isEmpty) return false;

    // 1. Case-insensitive email comparison
    final billingEmail = order.billing?.email?.trim().toLowerCase();
    if (billingEmail != null && billingEmail.isNotEmpty) {
      if (billingEmail == input.toLowerCase()) {
        return true;
      }
    }

    // 2. Normalized phone comparison
    final billingPhone = order.billing?.phoneNumber?.trim();
    if (billingPhone != null && billingPhone.isNotEmpty) {
      final normBilling = normalizePhone(billingPhone);
      final normInput = normalizePhone(input);
      if (normBilling.isNotEmpty && normInput.isNotEmpty) {
        if (normBilling == normInput) {
          return true;
        }
        // Compare last 9 digits for Saudi phone variants (e.g. 512345678)
        if (normBilling.length >= 9 && normInput.length >= 9) {
          final last9Billing = normBilling.substring(normBilling.length - 9);
          final last9Input = normInput.substring(normInput.length - 9);
          if (last9Billing == last9Input) {
            return true;
          }
        }
      }
    }

    return false;
  }
}
