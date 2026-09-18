import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/kanz_link_policy.dart';
import 'package:fstore/common/config/models/dynamic_link_config.dart';

void main() {
  test('only Kanz public HTTPS product/category/tag routes are accepted', () {
    for (final path in [
      'product/gold',
      'product-category/gold',
      'product-tag/sale'
    ]) {
      expect(kanzAppLink(Uri.parse('https://kanzalsahra.com/$path'))?.path,
          '/$path');
    }
    for (final url in [
      'http://kanzalsahra.com/product/a',
      'https://evil.com/product/a',
      'https://kanzalsahra.com/wp-admin/',
      'https://user:password@kanzalsahra.com/product/a',
      'https://kanzalsahra.com:8443/product/a',
      'https://kanzalsahra.page.link/old'
    ]) {
      expect(kanzAppLink(Uri.parse(url)), isNull);
    }
  });
  test('product queries cannot select template screens or carry credentials',
      () {
    expect(
        kanzAppLink(Uri.parse(
                'https://kanzalsahra.com/product/gold?screen=login&token=private#secret'))
            ?.toString(),
        'https://kanzalsahra.com/product/gold');
  });
  test('typed notification data is preserved for the existing strict parser',
      () {
    final uri = Uri.parse(
        'https://kanzalsahra.com/app-notification?kanz_target=product&kanz_id=124');
    expect(kanzAppLink(uri), uri);
  });
  test('native links remain enabled without retired Firebase config', () {
    final config =
        DynamicLinkConfig.fromJson({'enable': true, 'type': 'native'});
    expect(config.type, DynamicLinkType.native);
    expect(config.enable, isTrue);
  });
}
