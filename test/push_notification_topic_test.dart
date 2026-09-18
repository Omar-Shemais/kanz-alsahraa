import 'package:flutter_test/flutter_test.dart';
import 'package:flux_firebase/firebase_notification_service.dart';

void main() {
  group('Push Notification Topic Association (Problem 17 / T028)', () {
    test('formats standard numeric customer ID correctly', () {
      final topic = FirebaseNotificationService.formatCustomerTopic('12345');
      expect(topic, 'customer_12345');
    });

    test('sanitizes special characters and spaces to conform to FCM rules', () {
      final topic = FirebaseNotificationService.formatCustomerTopic(
          'user+test@domain.com');
      expect(topic, 'customer_user_test_domain.com');
      // FCM topic regex requirement: [a-zA-Z0-9-_.~%]+
      expect(RegExp(r'^[a-zA-Z0-9-_.~%]+$').hasMatch(topic), isTrue);
    });

    test('trims whitespace and handles edge-case IDs', () {
      final topic =
          FirebaseNotificationService.formatCustomerTopic('  cust 789  ');
      expect(topic, 'customer_cust_789');
      expect(RegExp(r'^[a-zA-Z0-9-_.~%]+$').hasMatch(topic), isTrue);
    });
  });
}
