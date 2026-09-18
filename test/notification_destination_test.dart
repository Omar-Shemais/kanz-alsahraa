import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/models/entities/fstore_notification_item.dart';
import 'package:fstore/services/notification_destination.dart';

void main() {
  test('typed product and category IDs', () {
    expect(
        notificationDestination({'kanz_target': 'category', 'kanz_id': '124'}),
        {'category': '124'});
    expect(notificationDestination({'kanz_target': 'product', 'kanz_id': '30'}),
        {'product': '30'});
    for (final id in ['', '0', '-1', '1<script>', 124, '99999999999']) {
      expect(notificationDestination({'kanz_target': 'product', 'kanz_id': id}),
          isNull);
    }
  });
  test('tabs are allowlisted; unknown actions are ignored', () {
    expect(
        notificationDestination({'kanz_target': 'cart'}), {'tab_number': '3'});
    expect(notificationDestination({'kanz_target': 'delete_account'}), isNull);
    expect(notificationDestination(null), isNull);
  });
  test('only HTTPS without embedded credentials', () {
    expect(
        notificationDestination({
          'kanz_target': 'url',
          'kanz_url': 'https://kanzalsahra.com/privacy-policy/'
        }),
        isNotNull);
    for (final url in [
      'javascript:alert(1)',
      'http://kanzalsahra.com/',
      'https://user:password@example.com/',
      '//example.com'
    ]) {
      expect(notificationDestination({'kanz_target': 'url', 'kanz_url': url}),
          isNull);
    }
  });
  test('notification history retains a typed destination', () {
    final item = FStoreNotificationItem(
        id: 'test',
        title: 'test',
        body: 'test',
        date: DateTime(2026),
        additionalData: {'kanz_target': 'category', 'kanz_id': '124'});
    final uri = Uri.parse(item.dynamicLink!);
    expect(uri.host, 'kanzalsahra.com');
    expect(notificationDestination(uri.queryParameters), {'category': '124'});
  });
}
