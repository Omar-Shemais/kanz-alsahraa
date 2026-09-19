import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/tools.dart';
import '../../../models/index.dart';
import '../../../screens/login_sms/login_sms_screen.dart';
import '../../../screens/login_sms/verify.dart';
import '../digits_login_failure.dart';
import '../services/index.dart';
import 'digits_mobile_login_sign_up_screen.dart';
import 'digits_mobile_login_verify_screen.dart';

class DigitsMobileLoginScreen extends LoginSMSScreen {
  const DigitsMobileLoginScreen() : super(enableRegister: true);

  @override
  LoginSMSScreenState<DigitsMobileLoginScreen> createState() =>
      _LoginSMSState();
}

class _LoginSMSState extends LoginSMSScreenState<DigitsMobileLoginScreen> {
  final _services = DigitsMobileLoginServices();
  bool _openingRegistration = false;

  void _showLoginFailure(Object error) {
    if (!mounted) return;
    final failure = presentDigitsLoginFailure(error);
    if (failure.action == DigitsLoginFailureAction.register) {
      if (_openingRegistration) return;
      _openingRegistration = true;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      unawaited(
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => DigitsMobileLoginSignUpScreen(
                  initialMobile: viewModel.phoneNumber,
                ),
              ),
            )
            .whenComplete(() => _openingRegistration = false),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(failure.text, textDirection: TextDirection.rtl),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(label: 'إغلاق', onPressed: () {}),
        ),
      );
  }

  @override
  void loginSMS(context) {
    if (!validateSaudiPhone()) return;
    try {
      if (kAdvanceConfig.enableDigitsMobileFirebase &&
          !kAdvanceConfig.enableDigitsMobileWhatsApp) {
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
                callback: _submitLogin,
              ),
            ),
          );
        }

        void verifyFailed(exception) {
          stopAnimation();
          _showLoginFailure(exception);
        }

        viewModel.verify(
            autoRetrieve: autoRetrieve,
            smsCodeSent: smsCodeSent,
            verifyFailed: verifyFailed,
            startVerify: () async {
              await playAnimation();
              try {
                await _services.loginCheck(
                    countryCode: viewModel.countryDialCode,
                    mobile: viewModel.phoneNumber);
                return true;
              } catch (e) {
                await stopAnimation().then((value) => _showLoginFailure(e));
                return false;
              }
            });
      } else {
        _sendLoginOtp();
      }
    } catch (e) {
      stopAnimation().then((value) => _showLoginFailure(e));
    }
  }

  Future<void> _sendLoginOtp() async {
    try {
      await playAnimation();
      await _services.loginCheck(
        countryCode: viewModel.countryDialCode,
        mobile: viewModel.phoneNumber,
      );
      final sent = await _services.sendOTP(
          countryCode: viewModel.countryDialCode,
          mobile: viewModel.phoneNumber,
          forRegister: false);
      await stopAnimation();
      if (sent) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DigitsMobileVerifyScreen(
              args: DigitsMobileVerifyArgs(
                  countryCode: viewModel.countryDialCode,
                  mobile: viewModel.phoneNumber,
                  isRegister: false),
            ),
          ),
        );
      } else {
        _showLoginFailure(Exception('otp_not_sent'));
      }
    } catch (e) {
      await stopAnimation();
      _showLoginFailure(e);
    }
  }

  Future<void> _submitLogin(String smsCode, User user) async {
    try {
      await playAnimation();
      final fToken = await user.getIdToken();
      var loggedInUser = await _services.login(
          otp: smsCode,
          countryCode: viewModel.countryDialCode,
          mobile: viewModel.phoneNumber,
          fToken: fToken);
      await Provider.of<UserModel>(context, listen: false)
          .setUser(loggedInUser);
      await stopAnimation();
      NavigateTools.navigateAfterLogin(loggedInUser, context);
    } catch (e) {
      await stopAnimation();
      _showLoginFailure(e);
    }
  }
}
