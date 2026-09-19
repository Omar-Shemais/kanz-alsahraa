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

    final routes = File('lib/routes/route.dart').readAsStringSync();
    expect(routes, contains('Honor the phone-only policy'));
    expect(routes, contains('const DigitsMobileLoginScreen()'));
  });

  test('phone authentication uses one automatic login or registration entry',
      () {
    final entry = File(
            'lib/modules/digits_mobile_login/views/digits_mobile_login_screen.dart')
        .readAsStringSync();
    final phoneUi =
        File('lib/screens/login_sms/login_sms_screen.dart').readAsStringSync();
    final registration = File(
            'lib/modules/digits_mobile_login/views/digits_mobile_login_sign_up_screen.dart')
        .readAsStringSync();

    expect(
        entry, contains('failure.action == DigitsLoginFailureAction.register'));
    expect(entry, contains('DigitsMobileLoginSignUpScreen'));
    expect(phoneUi, contains("titleButton: 'متابعة'"));
    expect(phoneUi, contains('LoginScreen(emailOnly: true)'));
    expect(registration, contains("key: const Key('registerFullNameField')"));
    expect(registration, isNot(contains("Key('registerUsernameField')")));
    expect(registration, isNot(contains("Key('registerLastNameField')")));
  });
}
