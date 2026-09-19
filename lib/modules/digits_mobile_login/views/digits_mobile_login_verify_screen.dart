import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../common/constants.dart';
import '../../../common/tools/navigate_tools.dart';
import '../../../common/tools/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/app_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/flux_image.dart';
import '../../../widgets/common/login_animation.dart';
import '../digits_login_failure.dart';
import '../services/index.dart';

class DigitsMobileVerifyArgs {
  const DigitsMobileVerifyArgs(
      {this.username,
      this.email,
      this.countryCode,
      this.mobile,
      this.firstName,
      this.lastName,
      this.password,
      required this.isRegister});

  final String? username;
  final String? email;
  final String? countryCode;
  final String? mobile;
  final String? firstName;
  final String? lastName;
  final String? password;
  final bool isRegister;
}

class DigitsMobileVerifyScreen extends StatefulWidget {
  final DigitsMobileVerifyArgs? args;

  const DigitsMobileVerifyScreen({this.args});

  @override
  State<DigitsMobileVerifyScreen> createState() =>
      _DigitsMobileVerifyScreenState();
}

class _DigitsMobileVerifyScreenState extends State<DigitsMobileVerifyScreen>
    with TickerProviderStateMixin, CodeAutoFill {
  late AnimationController _loginButtonController;

  final TextEditingController _pinCodeController = TextEditingController();

  final _services = DigitsMobileLoginServices();

  String? _errorText;
  bool _isVerifying = false;
  int _resendSeconds = 30;
  Timer? _resendTimer;

  @override
  void codeUpdated() {
    if (mounted && code != null && code!.isNotEmpty) {
      _verify(code!, context);
      setState(() {});
      Tools.hideKeyboard(context);
    }
  }

  @override
  void initState() {
    super.initState();
    listenForCode();

    _loginButtonController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _startResendCountdown();
  }

  @override
  void dispose() {
    _loginButtonController.dispose();
    _resendTimer?.cancel();
    _pinCodeController.dispose();
    cancel();
    super.dispose();
  }

  Future _playAnimation() async {
    try {
      await _loginButtonController.forward();
    } on TickerCanceled {
      printLog('[_playAnimation] error');
    }
  }

  Future _stopAnimation() async {
    try {
      await _loginButtonController.reverse();
    } on TickerCanceled {
      printLog('[_stopAnimation] error');
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() => _errorText = presentDigitsLoginFailure(error).text);
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _isVerifying) return;
    try {
      await _playAnimation();
      await _services.resendOTP(
        countryCode: widget.args?.countryCode,
        mobile: widget.args?.mobile,
        forRegister: widget.args?.isRegister ?? true,
      );
      _startResendCountdown();
      await _stopAnimation();
    } catch (error) {
      await _stopAnimation();
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context, listen: true);
    final themeConfig = appModel.themeConfig;
    final phoneNumber =
        ((widget.args?.countryCode ?? '') + (widget.args?.mobile ?? ''));
    final textStyle = Theme.of(context).primaryTextTheme.displaySmall?.copyWith(
          color: Theme.of(context).primaryColor,
        );
    final fontSize = textStyle?.fontSize;
    final fieldHeight = fontSize != null ? fontSize * 1.4 : null;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          S.of(context).verifySMSCode,
          style: TextStyle(
            fontSize: 16.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Tools.getBackIcon(context),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 32),
            Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                        height: 40.0,
                        child: FluxImage(imageUrl: themeConfig.logo)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                S.of(context).phoneNumberVerification,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8),
              child: Column(
                children: [
                  Text(S.of(context).enterSentCode),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      phoneNumber,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('تغيير الرقم'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: PinCodeTextField(
                  appContext: context,
                  controller: _pinCodeController,
                  keyboardType: TextInputType.number,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    borderWidth: 2,
                    activeFillColor: Theme.of(context).colorScheme.surface,
                    disabledColor: Theme.of(context).disabledColor,
                    fieldHeight: fieldHeight,
                  ),
                  length: 6,
                  cursorHeight: 30,
                  autoFocus: true,
                  obscuringCharacter: '*',
                  textStyle: textStyle,
                  animationType: AnimationType.scale,
                  hapticFeedbackTypes: HapticFeedbackTypes.light,
                  useHapticFeedback: true,
                  autoDisposeControllers: false,
                  animationDuration: const Duration(milliseconds: 300),
                  onChanged: (value) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                    if (value.length == 6) _verify(value, context);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              // error showing widget
              child: Text(
                _errorText ?? '',
                style: TextStyle(color: Colors.red.shade300, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _resendSeconds == 0 ? _resendCode : null,
              child: Text(
                _resendSeconds == 0
                    ? 'إعادة إرسال الرمز'
                    : 'إعادة الإرسال خلال $_resendSeconds ثانية',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 30,
              ),
              child: StaggerAnimation(
                titleButton: S.of(context).verifySMSCode,
                buttonController:
                    _loginButtonController.view as AnimationController,
                onTap: () {
                  if (_pinCodeController.text.trim().length == 6) {
                    _verify(_pinCodeController.text, context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify(String smsCode, BuildContext context) async {
    if (_isVerifying || smsCode.trim().length != 6) return;
    _isVerifying = true;
    if (mounted) setState(() => _errorText = null);
    try {
      await _playAnimation();
      final loggedInUser = widget.args?.isRegister == true
          ? await _services.signUp(
              username: widget.args?.username ?? '',
              email: widget.args?.email ?? '',
              countryCode: widget.args?.countryCode ?? '',
              mobile: widget.args?.mobile ?? '',
              firstName: widget.args?.firstName ?? '',
              lastName: widget.args?.lastName ?? '',
              password: widget.args?.password ?? '',
              otp: smsCode)
          : await _services.login(
              countryCode: widget.args?.countryCode ?? '',
              mobile: widget.args?.mobile ?? '',
              otp: smsCode);
      await Provider.of<UserModel>(context, listen: false)
          .setUser(loggedInUser);
      await _stopAnimation();
      if (widget.args?.isRegister == true) {
        TextInput.finishAutofillContext(shouldSave: true);
      }
      NavigateTools.navigateAfterLogin(loggedInUser, context);
    } catch (e) {
      await _stopAnimation();
      _showError(e);
    } finally {
      _isVerifying = false;
    }
  }
}
