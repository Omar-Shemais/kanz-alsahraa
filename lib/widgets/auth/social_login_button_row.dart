import 'package:flutter/material.dart';
import 'sms_sign_in_button.dart';

class SocialLoginButtonRow extends StatefulWidget {
  final VoidCallback? onApplePressed;
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onSmsPressed;

  const SocialLoginButtonRow({
    super.key,
    this.onApplePressed,
    this.onFacebookPressed,
    this.onGooglePressed,
    this.onSmsPressed,
  });

  @override
  State<SocialLoginButtonRow> createState() => _SocialLoginButtonRowState();
}

class _SocialLoginButtonRowState extends State<SocialLoginButtonRow> {
  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 16.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onSmsPressed != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding,
            ),
            child: SignInButtonSms(
              onPressed: () => widget.onSmsPressed!.call(),
            ),
          ),
      ],
    );
  }
}
