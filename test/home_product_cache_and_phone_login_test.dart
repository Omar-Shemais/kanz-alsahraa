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

  test('home product carousels size to cards without fixed vertical gaps', () {
    final source =
        File('lib/modules/dynamic_layout/product/product_list_default.dart')
            .readAsStringSync();

    expect(source, contains('CustomScrollPhysic'));
    expect(source, isNot(contains('InfiniteCarousel.builder')));
    expect(source, isNot(contains('minHeight:')));
    expect(source, isNot(contains('maxHeight:')));
  });

  test('expired catalog cache remains available when the device is offline',
      () {
    final transport = File('lib/services/https.dart').readAsStringSync();
    final products =
        File('lib/modules/dynamic_layout/product/future_builder.dart')
            .readAsStringSync();

    expect(transport, contains('staleResponse'));
    expect(transport, contains('GET STALE CACHE'));
    expect(products, contains('_ProductLoadFailure'));
    expect(products, contains('المنتجات غير متاحة دون اتصال حالياً'));
  });

  test('customer authentication keeps phone primary without social login', () {
    final environment = File('lib/env.dart').readAsStringSync();

    expect(environment, contains('"showAppleLogin": false'));
    expect(environment, contains('"showGoogleLogin": false'));
    expect(environment, contains('"showSMSLogin": true'));
    expect(environment, contains('"smsLoginAsDefault": true'));

    final routes = File('lib/routes/route.dart').readAsStringSync();
    expect(routes, contains('Honor the phone-only policy'));
    expect(routes, contains('const DigitsMobileLoginScreen()'));
  });

  test('phone entry exposes email/password login with native autofill', () {
    final phoneUi =
        File('lib/screens/login_sms/login_sms_screen.dart').readAsStringSync();
    final emailUi =
        File('lib/screens/users/login/login_screen.dart').readAsStringSync();
    final login = File('lib/screens/users/login/mixins/mixin_login.dart')
        .readAsStringSync();

    expect(phoneUi, contains("Key('loginWithEmailButton')"));
    expect(phoneUi, contains('OutlinedButton.icon'));
    expect(phoneUi, contains('pushReplacement('));
    expect(phoneUi, contains('LoginScreen(emailOnly: true)'));
    expect(emailUi, contains('AutofillHints.username'));
    expect(emailUi, contains('AutofillHints.email'));
    expect(emailUi, contains('AutofillHints.password'));
    expect(login, contains('finishAutofillContext(shouldSave: true)'));
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
