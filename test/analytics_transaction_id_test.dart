import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/modules/analytics/transaction_id.dart';

void main() {
  test('full order uses its ID, WebView can use the returned number', () {
    expect(analyticsTransactionId('123', 'K-123'), '123');
    expect(analyticsTransactionId(null, ' K-123 '), 'K-123');
  });
  test('no invented transaction when order identification is missing', () {
    expect(analyticsTransactionId(null, null), isNull);
    expect(analyticsTransactionId('', ' '), isNull);
  });
  test('invalid references are rejected or fall back to the order number', () {
    expect(analyticsTransactionId('bad\nreference', '123'), '123');
    expect(analyticsTransactionId('x' * 129, null), isNull);
  });
}
