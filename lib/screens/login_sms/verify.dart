import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart';
import '../../modules/digits_mobile_login/digits_login_failure.dart';
import '../../services/services.dart';
import '../../widgets/common/flux_image.dart';
import '../../widgets/common/login_animation.dart';

class VerifyCode extends StatefulWidget {
  final String? phoneNumber;
  final String? verId;
  final Stream<String?>? verifySuccessStream;
  final int? resendToken;
  final FutureOr<void> Function(String, User)? callback;

  const VerifyCode(
      {this.verId,
      this.phoneNumber,
      this.verifySuccessStream,
      this.resendToken,
      this.callback});

  @override
  State<VerifyCode> createState() => _VerifyCodeState();
}

class _VerifyCodeState extends State<VerifyCode>
    with TickerProviderStateMixin, CodeAutoFill {
  late AnimationController _loginButtonController;
  bool isLoading = false;

  final TextEditingController _pinCodeController = TextEditingController();

  String? _errorText;
  bool _isVerifying = false;
  int _resendSeconds = 30;
  Timer? _resendTimer;
  int? _resendToken;
  String? _verId;
  StreamSubscription<String?>? _verifySuccessSubscription;

  @override
  void codeUpdated() {
    if (mounted && code != null && code!.isNotEmpty) {
      _loginSMS(code, context);
      setState(() {});
      Tools.hideKeyboard(context);
    }
  }

  Future<void> _verifySuccessStreamListener(String? otp) async {
    _pinCodeController.text = otp ?? '';
    Tools.hideKeyboard(context);
  }

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
    _verId = widget.verId;
    _verifySuccessSubscription =
        widget.verifySuccessStream?.listen(_verifySuccessStreamListener);

    listenForCode();

    _loginButtonController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _startResendCountdown();
  }

  @override
  void dispose() {
    _verifySuccessSubscription?.cancel();
    _resendTimer?.cancel();
    _loginButtonController.dispose();
    _pinCodeController.dispose();
    cancel();
    super.dispose();
  }

  Future _playAnimation() async {
    try {
      setState(() {
        isLoading = true;
      });
      await _loginButtonController.forward();
    } on TickerCanceled {
      printLog('[_playAnimation] error');
    }
  }

  Future _stopAnimation() async {
    try {
      await _loginButtonController.reverse();
      setState(() {
        isLoading = false;
      });
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
    if (_resendSeconds > 0 || isLoading) return;
    await _playAnimation();
    try {
      await Services().firebase.verifyPhoneNumber(
            phoneNumber: widget.phoneNumber,
            codeAutoRetrievalTimeout: (_) => _stopAnimation(),
            codeSent: (verId, [forceCodeResend]) {
              _resendToken = forceCodeResend;
              _verId = verId;
              _startResendCountdown();
              return _stopAnimation();
            },
            verificationCompleted: (credential) {},
            forceResendingToken: _resendToken,
            verificationFailed: (exception) {
              _stopAnimation();
              _showError(exception);
            },
          );
    } catch (error) {
      await _stopAnimation();
      _showError(error);
    }
  }

  void _loginSMS(smsCode, context) async {
    if (_isVerifying || smsCode.toString().trim().length != 6) return;
    _isVerifying = true;
    if (mounted) setState(() => _errorText = null);
    await _playAnimation();
    try {
      final credential = Services().firebase.getFirebaseCredential(
            verificationId: _verId!,
            smsCode: smsCode,
          );
      await _signInWithCredential(credential);
    } catch (e) {
      await _stopAnimation();
      _showError(e);
    } finally {
      _isVerifying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context, listen: true);
    final themeConfig = appModel.themeConfig;
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
                      widget.phoneNumber ?? '',
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
                    if (value.length == 6) _loginSMS(value, context);
                  },
                  cursorColor: Theme.of(context).colorScheme.onSurface,
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
                    _loginSMS(_pinCodeController.text, context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithCredential(credential) async {
    final user = await Services()
        .firebase
        .loginFirebaseCredential(credential: credential);
    if (user != null) {
      if (widget.callback != null) {
        await _stopAnimation();
        await Future.sync(
          () => widget.callback!(_pinCodeController.text, user),
        );
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        await Provider.of<UserModel>(context, listen: false).loginFirebaseSMS(
          context: context,
          phoneNumber: user.phoneNumber!.replaceAll('+', ''),
          success: (user) {
            _stopAnimation();
            NavigateTools.navigateAfterLogin(user, context);
          },
          fail: (message) {
            _stopAnimation();
            _showError(message);
          },
        );
      }
    } else {
      await _stopAnimation();
      _showError(S.of(context).invalidSMSCode);
    }
  }
}
