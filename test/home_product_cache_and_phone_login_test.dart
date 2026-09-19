import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home product sections remain alive after leaving the viewport', () {
    final source = File('lib/modules/dynamic_layout/product/product_list.dart')
        .readAsStringSync();

    expect(source, contains('with AutomaticKeepAliveClientMixin'));
    expect(source, contains('bool get wantKeepAlive => true'));
    expect(source, contains('super.build(context);'));
  });

  test('customer authentication opens phone verification only', () {
    final environment = File('lib/env.dart').readAsStringSync();

    expect(environment, contains('"showAppleLogin": false'));
    expect(environment, contains('"showGoogleLogin": false'));
    expect(environment, contains('"showSMSLogin": true'));
    expect(environment, contains('"smsLoginAsDefault": true'));
  });
}
