enum DigitsLoginFailureAction { none, register }

class DigitsLoginFailureMessage {
  const DigitsLoginFailureMessage(this.text,
      {this.action = DigitsLoginFailureAction.none});

  final String text;
  final DigitsLoginFailureAction action;
}

/// Converts unstable WordPress/Digits/Firebase errors into safe Arabic copy.
/// Raw server responses must never be shown on the authentication screen.
DigitsLoginFailureMessage presentDigitsLoginFailure(Object error) {
  final message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  final normalized = message.toLowerCase();

  bool containsAny(Iterable<String> values) =>
      values.any((value) => normalized.contains(value));

  if (containsAny(const [
    'يرجى الاشتراك قبل تسجيل الدخول',
    'الاشتراك قبل تسجيل الدخول',
    'not registered',
    'not_register',
    'user_not_found',
    'account_not_found',
    'no account',
  ])) {
    return const DigitsLoginFailureMessage(
      'رقم الجوال غير مسجل. يرجى إنشاء حساب جديد أولاً.',
      action: DigitsLoginFailureAction.register,
    );
  }
  if (containsAny(const [
    'invalid_mobile',
    'invalid phone',
    'invalid number',
    'رقم الهاتف غير صحيح',
    'رقم الجوال غير صحيح',
  ])) {
    return const DigitsLoginFailureMessage(
        'رقم الجوال غير صحيح. تحقق من الرقم ومفتاح الدولة.');
  }
  if (containsAny(const [
    'invalid_otp',
    'incorrect otp',
    'wrong otp',
    'verification code',
    'رمز التحقق',
  ])) {
    return const DigitsLoginFailureMessage(
        'رمز التحقق غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً وحاول مرة أخرى.');
  }
  if (containsAny(const [
    'too many',
    'rate limit',
    'blocked',
    'محاولات كثيرة',
  ])) {
    return const DigitsLoginFailureMessage(
        'تم تجاوز عدد المحاولات المسموح. انتظر قليلاً ثم حاول مرة أخرى.');
  }
  if (containsAny(const [
    'socketexception',
    'clientexception',
    'network',
    'connection',
    'timed out',
    'timeout',
  ])) {
    return const DigitsLoginFailureMessage(
        'تعذر الاتصال بالخدمة. تحقق من الإنترنت ثم حاول مرة أخرى.');
  }

  return const DigitsLoginFailureMessage(
      'تعذر إكمال تسجيل الدخول الآن. حاول مرة أخرى بعد قليل.');
}
