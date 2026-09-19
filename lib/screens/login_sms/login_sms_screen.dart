import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart';
import '../../services/services.dart';
import '../../widgets/common/flux_image.dart';
import '../../widgets/common/login_animation.dart';
import '../users/login/login_screen.dart';
import 'login_sms_viewmodel.dart';
import 'verify.dart';

class LoginSMSScreen extends StatefulWidget {
  const LoginSMSScreen({this.enableRegister = false});
  final bool enableRegister;

  @override
  LoginSMSScreenState createState() => LoginSMSScreenState();
}

class LoginSMSScreenState<T extends LoginSMSScreen> extends State<T>
    with TickerProviderStateMixin {
  late AnimationController _loginButtonController;
  final TextEditingController _controller = TextEditingController(text: '');
  String? _phoneError;

  LoginSmsViewModel get viewModel => context.read<LoginSmsViewModel>();

  void loginSMS(context) {
    if (!validateSaudiPhone()) return;
    Future autoRetrieve(String verId) {
      return stopAnimation();
    }

    Future smsCodeSent(String verId, [int? forceCodeResend]) {
      stopAnimation();
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyCode(
            verId: verId,
            phoneNumber: viewModel.phoneFullText,
            verifySuccessStream: viewModel.getStreamSuccess,
            resendToken: forceCodeResend,
          ),
        ),
      );
    }

    void verifyFailed(exception) {
      stopAnimation();
      failMessage(exception.toString(), context);
    }

    viewModel.verify(
      autoRetrieve: autoRetrieve,
      smsCodeSent: smsCodeSent,
      verifyFailed: verifyFailed,
      startVerify: playAnimation,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.updateCountryCode(
        code: LoginSMSConstants.countryCodeDefault,
        dialCode: LoginSMSConstants.dialCodeDefault,
        name: LoginSMSConstants.nameDefault,
      );
    });

    _loginButtonController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    viewModel.updatePhone(_controller.text);
    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }
  }

  @protected
  bool validateSaudiPhone() {
    if (viewModel.isValidPhoneNumber) return true;
    setState(() {
      _phoneError = 'أدخل رقم جوال سعودي صحيح بصيغة 5XXXXXXXX';
    });
    return false;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _loginButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context, listen: false);
    final themeConfig = appModel.themeConfig;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.0,
        actions: !Services().widget.isRequiredLogin &&
                !ModalRoute.of(context)!.canPop
            ? [
                IconButton(
                    onPressed: _onClose,
                    icon: const Icon(Icons.close, size: 25))
              ]
            : null,
      ),
      body: SafeArea(
        child: Consumer<LoginSmsViewModel>(
          builder: (context, viewmodel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 36.0),
                  SizedBox(
                    height: 115,
                    child: FluxImage(imageUrl: themeConfig.logo),
                  ),
                  const SizedBox(height: 34.0),
                  Text(
                    'تسجيل الدخول أو إنشاء حساب',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل رقم جوالك وسنحدد حسابك تلقائياً',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32.0),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('+966 🇸🇦'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const Key('loginPhoneField'),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'رقم الجوال',
                              hintText: '5XXXXXXXX',
                              errorText: _phoneError,
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            controller: _controller,
                            onSubmitted: (_) => loginSMS(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  StaggerAnimation(
                    titleButton: 'متابعة',
                    buttonController:
                        _loginButtonController.view as AnimationController,
                    onTap: () => loginSMS(context),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const Key('loginWithEmailButton'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(emailOnly: true),
                      ),
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('الدخول بالبريد الإلكتروني'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> playAnimation() async {
    try {
      viewModel.enableLoading();
      await _loginButtonController.forward();
      return true;
    } on TickerCanceled {
      printLog('[_playAnimation] error');
      return false;
    }
  }

  Future stopAnimation() async {
    try {
      await _loginButtonController.reverse();
      viewModel.enableLoading(false);
    } on TickerCanceled {
      printLog('[_stopAnimation] error');
    }
  }

  void failMessage(String message, BuildContext context) {
    /// Showing Error messageSnackBarDemo
    /// Ability so close message
    final snackBar = SnackBar(
      content: Text(message.clearExceptionKey()),
      duration: const Duration(seconds: 30),
      action: SnackBarAction(
        label: S.of(context).close,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future _onClose() async {
    await Navigator.of(App.fluxStoreNavigatorKey.currentContext!)
        .pushReplacementNamed(RouteList.dashboard);
  }
}
