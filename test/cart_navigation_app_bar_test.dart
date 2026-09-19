import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('corner cart opens the canonical root cart route', () {
    final source = File('lib/widgets/product/product_bottom_sheet.dart')
        .readAsStringSync();

    expect(source, contains('Future<void> _openCartRoute()'));
    expect(source, contains('RouteList.cart'));
    expect(source, contains('forceRootNavigator: true'));
    expect(source, contains('onTap: _openCartRoute'));
    expect(source, isNot(contains('hideNewAppBar: true')));
    expect(source, isNot(contains('const CartScreen(')));
  });

  test('half-size product cart does not nest the cart in another Scaffold', () {
    final source = File('lib/screens/detail/themes/half_size_image_type.dart')
        .readAsStringSync();

    expect(source, contains('RouteList.cart'));
    expect(source, contains('forceRootNavigator: true'));
    expect(source, isNot(contains('const CartScreen(isModal: true)')));
    expect(source,
        isNot(contains('builder: (BuildContext context) => Scaffold(')));
  });
}
