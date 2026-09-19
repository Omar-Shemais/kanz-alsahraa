import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/modules/digits_mobile_login/digits_login_failure.dart';

void main() {
  test('unregistered phone gets a clear registration action', () {
    final result =
        presentDigitsLoginFailure(Exception('يرجى الاشتراك قبل تسجيل الدخول.'));

    expect(result.text, 'رقم الجوال غير مسجل. يرجى إنشاء حساب جديد أولاً.');
    expect(result.action, DigitsLoginFailureAction.register);
  });

  test('technical server details are not exposed', () {
    final result = presentDigitsLoginFailure(
        Exception('HTTP 500 stack trace from digits plugin'));

    expect(
        result.text, 'تعذر إكمال تسجيل الدخول الآن. حاول مرة أخرى بعد قليل.');
    expect(result.text, isNot(contains('500')));
  });

  test('network and invalid number failures have distinct guidance', () {
    expect(
      presentDigitsLoginFailure(Exception('SocketException')).text,
      contains('تحقق من الإنترنت'),
    );
    expect(
      presentDigitsLoginFailure(Exception('invalid_mobile')).text,
      contains('رقم الجوال غير صحيح'),
    );
  });
}
