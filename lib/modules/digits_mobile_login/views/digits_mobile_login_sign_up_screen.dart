import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/tools.dart';
import '../../../models/entities/user.dart';
import '../../../models/index.dart' show AppModel, UserModel;
import '../../../screens/home/privacy_term_screen.dart';
import '../../../screens/login_sms/verify.dart';
import '../../../services/services.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/flux_image.dart';
import '../digits_login_failure.dart';
import '../services/index.dart';
import 'digits_mobile_login_verify_screen.dart';

class DigitsMobileLoginSignUpScreen extends StatefulWidget {
  const DigitsMobileLoginSignUpScreen({super.key, this.initialMobile});

  final String? initialMobile;

  @override
  State<DigitsMobileLoginSignUpScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState extends State<DigitsMobileLoginSignUpScreen> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _services = DigitsMobileLoginServices();
  final _nameNode = FocusNode();
  final _emailNode = FocusNode();

  late final StreamController<String?>? _verifySuccessStream;
  late final String _mobile;
  late final String _dialCode;

  String _fullName = '';
  String _email = '';
  String? _nameError;
  String? _emailError;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  String get _username =>
      'kanz_${_dialCode.replaceAll(RegExp(r'\D'), '')}$_mobile';

  String get _firstName {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  String get _lastName {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    return parts.length <= 1 ? '' : parts.skip(1).join(' ');
  }

  @override
  void initState() {
    super.initState();
    var digits = (widget.initialMobile ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('966')) digits = digits.substring(3);
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    _mobile = digits;
    _dialCode = LoginSMSConstants.dialCodeDefault.isNotEmpty
        ? LoginSMSConstants.dialCodeDefault
        : '+966';
    _verifySuccessStream = Services().firebase.getFirebaseStream();
  }

  @override
  void dispose() {
    _nameNode.dispose();
    _emailNode.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    final raw = error.toString().toLowerCase();
    final failure = presentDigitsLoginFailure(error);
    final text = raw.contains('email') || raw.contains('البريد')
        ? 'البريد الإلكتروني مستخدم في حساب آخر. استخدم بريداً مختلفاً.'
        : failure.action == DigitsLoginFailureAction.none
            ? failure.text
            : 'تعذر إنشاء الحساب الآن. حاول مرة أخرى بعد قليل.';
    _scaffoldMessengerKey.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          duration: const Duration(seconds: 8),
        ),
      );
  }

  bool _validateInputs() {
    final validName = _fullName.trim().length >= 2;
    final validEmail = _email.trim().validateEmail();
    setState(() {
      _nameError = validName ? null : 'أدخل الاسم الكامل';
      _emailError = validEmail ? null : 'أدخل بريداً إلكترونياً صحيحاً';
    });

    if (!validName || !validEmail) return false;
    if (!_acceptedTerms) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('يجب الموافقة على الشروط والخصوصية')),
      );
      return false;
    }
    return true;
  }

  Future<void> _sendSms() async {
    if (!_validateInputs() || _isLoading) return;
    final phoneNumber = '$_dialCode$_mobile';
    setState(() => _isLoading = true);

    try {
      await _services.signUpCheck(
        username: _username,
        email: _email.trim(),
        countryCode: _dialCode,
        mobile: _mobile,
      );

      if (kAdvanceConfig.enableDigitsMobileFirebase &&
          !kAdvanceConfig.enableDigitsMobileWhatsApp) {
        Future<void> autoRetrieve(String verId) async {
          if (mounted) setState(() => _isLoading = false);
        }

        Future<void> smsCodeSent(String verId, [int? forceCodeResend]) async {
          if (mounted) setState(() => _isLoading = false);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyCode(
                verId: verId,
                phoneNumber: phoneNumber,
                verifySuccessStream: _verifySuccessStream?.stream,
                resendToken: forceCodeResend,
                callback: _submitRegister,
              ),
            ),
          );
        }

        void verifyFailed(Object exception) {
          if (mounted) setState(() => _isLoading = false);
          _showError(exception);
        }

        unawaited(
          Services().firebase.verifyPhoneNumber(
                phoneNumber: phoneNumber,
                codeAutoRetrievalTimeout: autoRetrieve,
                codeSent: smsCodeSent,
                verificationCompleted: (data) =>
                    _verifySuccessStream?.add(data),
                verificationFailed: verifyFailed,
              ),
        );
      } else {
        final sent = await _services.sendOTP(
          countryCode: _dialCode,
          mobile: _mobile,
          forRegister: true,
        );
        if (sent && mounted) {
          setState(() => _isLoading = false);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DigitsMobileVerifyScreen(
                args: DigitsMobileVerifyArgs(
                  username: _username,
                  email: _email.trim(),
                  countryCode: _dialCode,
                  mobile: _mobile,
                  firstName: _firstName,
                  lastName: _lastName,
                  isRegister: true,
                ),
              ),
            ),
          );
        } else if (!sent) {
          throw Exception('otp_not_sent');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      _showError(error);
    }
  }

  Future<void> _submitRegister(String smsCode, User user) async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final token = await user.getIdToken();
      final loggedInUser = await _services.signUp(
        username: _username,
        firstName: _firstName,
        lastName: _lastName,
        email: _email.trim(),
        countryCode: _dialCode,
        mobile: _mobile,
        fToken: token,
      );
      await Provider.of<UserModel>(context, listen: false)
          .setUser(loggedInUser);
      if (mounted) {
        setState(() => _isLoading = false);
        NavigateTools.navigateAfterLogin(loggedInUser, context);
      }
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<AppModel>(context).themeConfig;
    final colors = Theme.of(context).colorScheme;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          title: const Text('إنشاء الحساب'),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => Tools.hideKeyboard(context),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        height: 82,
                        child: FluxImage(imageUrl: themeConfig.logo),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'رقم جديد — أكمل بياناتك',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سنرسل رمز تحقق إلى رقم جوالك بعد المتابعة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.65),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      key: const Key('registerFullNameField'),
                      focusNode: _nameNode,
                      nextNode: _emailNode,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        _fullName = value;
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        hintText: 'مثال: محمد أحمد',
                        errorText: _nameError,
                      ),
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      key: const Key('registerEmailField'),
                      focusNode: _emailNode,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (value) {
                        _email = value;
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'name@example.com',
                        errorText: _emailError,
                      ),
                    ),
                    const SizedBox(height: 18),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'رقم الجوال',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '$_dialCode $_mobile',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _acceptedTerms = !_acceptedTerms),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              key: const Key('registerTermsCheckbox'),
                              value: _acceptedTerms,
                              onChanged: (value) => setState(
                                () => _acceptedTerms = value ?? false,
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'أوافق على ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'الشروط وسياسة الخصوصية',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PrivacyTermScreen(
                                                  showAgreeButton: false,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      key: const Key('registerSubmitButton'),
                      onPressed: _isLoading ? null : _sendSms,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(
                        _isLoading ? 'جارٍ الإرسال…' : 'إرسال رمز التحقق',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
