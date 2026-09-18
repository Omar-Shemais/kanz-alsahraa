import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/web_navigation_policy.dart';

void main() {
  test('HTTPS store and payment redirects remain embedded', () {
    expect(
        webUrlAction('https://kanzalsahra.com/checkout/'), WebUrlAction.embed);
    expect(webUrlAction('https://gateway.example/3ds?token=123'),
        WebUrlAction.embed);
    expect(webUrlAction('about:blank'), WebUrlAction.embed);
  });
  test('unsafe, ambiguous and arbitrary external schemes are blocked', () {
    for (final value in [
      'http://kanzalsahra.com',
      'httpstuff://bad',
      'javascript:alert(1)',
      'data:text/html,test',
      'file:///etc/passwd',
      'intent://bad#Intent;scheme=unknown;end',
      'unknown://app',
      'https://store.example@evil.example',
      'https://',
      '//example.com',
      ' https://example.com',
      'https://example.com\\@evil.example',
      'https://example.com/\npath',
      'about:config'
    ]) {
      expect(webUrlAction(value), WebUrlAction.block, reason: value);
    }
  });
  test('supported contact links are external, never embedded', () {
    for (final value in [
      'tel:+966123456789',
      'mailto:help@example.com',
      'whatsapp://send?phone=966123456789'
    ]) {
      expect(webUrlAction(value), WebUrlAction.external);
    }
    expect(webUrlAction('tel:'), WebUrlAction.block);
  });
  test('origins distinguish ports, schemes and deceptive hosts', () {
    expect(
        sameWebOrigin(
            'https://kanzalsahra.com/a', 'https://kanzalsahra.com:443/b'),
        true);
    for (final value in [
      'https://kanzalsahra.com.evil.example/a',
      'https://evil.example/kanzalsahra.com',
      'http://kanzalsahra.com/a',
      'https://kanzalsahra.com:444/a',
      'https://user@kanzalsahra.com/a'
    ]) {
      expect(sameWebOrigin(value, 'https://kanzalsahra.com/'), false);
    }
  });
  test('Woo return accepts candidate IDs only from the store', () {
    const store = 'https://kanzalsahra.com';
    expect(
        wooReturnOrderId(
            '$store/checkout/order-received/123/?key=secret', store),
        '123');
    expect(
        wooReturnOrderId(
            '$store/order-received/thank-you/?order_id=123', store),
        '123');
    for (final value in [
      'https://evil.example/checkout/order-received/123/',
      '$store/thank-you',
      '$store/checkout/success',
      '$store/?next=/order-received/123',
      '$store/checkout/order-received/0/',
      '$store/checkout/order-received/not-an-id/',
      '$store/checkout/order-received/123/extra',
      '$store/checkout/order-received/'
    ]) {
      expect(wooReturnOrderId(value, store), null, reason: value);
    }
  });
  test('injected script is bound to the initial HTTPS origin', () {
    final source = originBoundWebScript('document.title = "Store";',
        'https://kanzalsahra.com/checkout?token=secret');
    expect(source,
        contains('window.location.origin === "https://kanzalsahra.com"'));
    expect(source, isNot(contains('token=secret')));
    expect(originBoundWebScript('test', 'javascript:test'), isEmpty);
  });
}
