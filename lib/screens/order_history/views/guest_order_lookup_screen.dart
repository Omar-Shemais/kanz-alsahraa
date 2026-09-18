import 'package:flutter/material.dart';

import '../../../common/tools.dart';

/// Do not fetch orders until the server authenticates ownership.
/// Comparing a known phone/email after downloading an order is not auth.
class GuestOrderLookupScreen extends StatelessWidget {
  const GuestOrderLookupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Tools.isRTL(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'متابعة الطلب' : 'Track order'),
        leading: IconButton(
          icon: Icon(Tools.getBackIcon(context)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            isRtl
                ? 'لحماية بياناتك، تابع طلباتك بعد تسجيل الدخول من صفحة حسابك. إذا اشتريت دون حساب، تواصل مع خدمة العملاء لمتابعة الطلب.'
                : 'To protect your information, sign in and view orders from your account. For a guest purchase, contact customer support.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
